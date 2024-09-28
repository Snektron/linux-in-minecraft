const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mini_rv32ima = b.dependency("mini_rv32ima", .{});

    const exe = b.addExecutable(.{
        .name = "riscv-validator",
        .root_source_file = b.path("validator.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe.addIncludePath(mini_rv32ima.path("mini-rv32ima"));
    exe.addIncludePath(b.path("."));
    exe.addCSourceFile(.{
        .file = b.path("validator.c"),
    });
    exe.root_module.sanitize_c = false; // sanitizer triggers on misaligned access in mini-rv32ima, even though that should be fine...
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
