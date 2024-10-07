const std = @import("std");
const c = @cImport({
    @cInclude("stdint.h");
    @cInclude("mini-rv32ima.h");
});

var state: c.MiniRV32IMAState = undefined;
var totalcycles: u32 = undefined;
var stdout: std.fs.File.Writer = undefined;

export fn mmio_store(addr: u32, val: u32) void {
    switch (addr) {
        0x10000000 => {
            // std.debug.print("{} @ {} UART: {c}\n", .{totalcycles, state.pc, @as(u8, @truncate(val))});
            stdout.writeByte(@truncate(val)) catch @panic("write failed");
            if (val == '\n') {
                std.log.debug("write @ cycle {}", .{ totalcycles });
            }
        },
        0x11004004 => {
            state.timermatchh = val;
        },
        0x11004000 => {
            state.timermatchl = val;
        },
        0x11100000 => {
            std.debug.print("SYSCON: {}\n", .{val});
        },
        else => {
            // std.log.warn("invalid mmio write @ 0x{x:0>8} = {}", .{addr, val});
        },
    }
}

export fn mmio_load(addr: u32) u32 {
    return switch (addr) {
        0x10000005 => 0x60,
        0x1100bffc => state.timerh,
        0x1100bff8 => state.timerl,
        else => 0,
    };
}

fn save(mem: []const u8) !void {
    std.log.debug("saving machine state @ {}", .{totalcycles});
    {
        var file = try std.fs.cwd().createFile("state/machine.state", .{});
        defer file.close();
        var bw = std.io.bufferedWriter(file.writer());
        var writer = bw.writer();

        inline for (std.meta.fields(c.MiniRV32IMAState)) |field| {
            const fname = field.name;
            if (comptime (!std.mem.eql(u8, fname, "regs") and !std.mem.eql(u8, fname, "extraflags"))) {
                try writer.print("{s} {}\n", .{fname, @field(state, fname)});
            }
        }

        try writer.print("privilege {}\n", .{state.extraflags & 3});
        try writer.print("wfi {}\n", .{ (state.extraflags & 4) >> 2});
        try writer.print("reserved {}\n", .{state.extraflags >> 3});
        try writer.print("totalcycles {}\n", .{totalcycles});

        for (0..32) |i| {
            try writer.print("x{} {}\n", .{i, state.regs[i]});
        }

        try bw.flush();
    }

    {
        var file = try std.fs.cwd().createFile("state/memory.dump", .{});
        defer file.close();
        var writer = file.writer();
        try writer.writeAll(mem);
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    stdout = std.io.getStdOut().writer();

    const mem = try std.heap.page_allocator.alloc(u8, (1 << 24) * 4);
    defer std.heap.page_allocator.free(mem);
    @memset(mem, 0);

    var args = std.process.args();
    _ = args.next();
    const image_path = args.next() orelse return error.MissingArg;
    const dtb_path = args.next() orelse return error.MissingArg;

    const cwd = std.fs.cwd();
    const image = try cwd.readFileAlloc(allocator, image_path, std.math.maxInt(usize));
    const dtb = try cwd.readFileAlloc(allocator, dtb_path, std.math.maxInt(usize));

    // Place linux at the beginning of the address space
    @memcpy(mem[0..image.len], image);

    // Place the dtb at 0x3000000 physical (0x83000000 virtual)
    const dtb_offset = 0x3000000;
    @memcpy(mem[dtb_offset..][0..dtb.len], dtb);

    state = std.mem.zeroes(c.MiniRV32IMAState);
    state.pc = c.MINIRV32_RAM_IMAGE_OFFSET;
    state.extraflags |= 3; // privilege level
    state.regs[10] = 0x00;
    state.regs[11] = dtb_offset + c.MINIRV32_RAM_IMAGE_OFFSET;
    totalcycles = 0;

    while (true) {
        // if (totalcycles % 0x1000 == 0) {
        //     std.debug.print("executing {} cycle {}\n", .{ @as(i32, @bitCast(state.pc)), totalcycles });
        // }
        // if (totalcycles > 500_000) {
        //     std.process.exit(0);
        // }
        switch (c.MiniRV32IMAStep(&state, mem.ptr, 0, 1, 1)) {
            0 => {
                if (state.mcause == 3) {
                    std.log.debug("ebreak", .{});
                }
            },
            else => |e| {
                if (state.extraflags & 0x4 != 0) {
                    // WFI, ignore
                } else {
                    std.log.err("mini-rv32ima error: {}", .{e});
                    std.process.exit(1);
                }
            }
        }
        totalcycles +%= 1;
        // if (totalcycles == 294749) {
        //     try save(mem);
        // }
    }
}
