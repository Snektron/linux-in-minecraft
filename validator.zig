const std = @import("std");
const c = @cImport({
    @cInclude("stdint.h");
    @cInclude("mini-rv32ima.h");
});

pub fn main() !void {
    const mem = try std.heap.page_allocator.alloc(u8, (1 << 24) * 4);
    defer std.heap.page_allocator.free(mem);
    @memset(mem, 0);

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    const code = std.mem.bytesAsSlice(i32, mem);
    var len: usize = 0;
    for (code) |*word| {
        var buf: [32]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        stdin.streamUntilDelimiter(fbs.writer(), '\n', fbs.buffer.len) catch |err| switch (err) {
            error.EndOfStream => break,
            error.StreamTooLong => {
                std.log.err("input line too long :(", .{});
                std.process.exit(1);
            },
            else => |e| return e,
        };
        const line = fbs.getWritten();
        // End when 'end' is called because python's subprocess doesn't close the handle for some stupid reason
        if (line.len == 0 or std.mem.eql(u8, line, "end")) {
            break;
        }

        word.* = std.fmt.parseInt(i32, line, 10) catch {
            std.log.err("failed to parse line to i32: {s}", .{line});
            std.process.exit(1);
        };
        len += 1;
    }

    var state = std.mem.zeroes(c.MiniRV32IMAState);

    while (state.pc < len * 4) {
        const state_copy = state;
        switch (c.MiniRV32IMAStep(&state, mem.ptr, 0, 0, 1)) {
            0 => {
                if (state.mcause == 3) {
                    // ebreak, reset state and skip over it.
                    state = state_copy;
                    state.pc += 4;
                }
            },
            else => |e| {
                std.log.err("mini-rv32ima error: {}", .{e});
                std.process.exit(1);
            }
        }
    }

    for (state.regs) |reg| {
        try stdout.print("{}\n", .{reg});
    }
    try stdout.print("{}\n", .{state.pc});
}
