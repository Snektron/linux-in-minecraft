const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mini_rv32ima = b.dependency("mini_rv32ima", .{});

    const validator = b.addExecutable(.{
        .name = "riscv-validator",
        .root_source_file = b.path("validator.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    validator.addIncludePath(mini_rv32ima.path("mini-rv32ima"));
    validator.addIncludePath(b.path("."));
    validator.addCSourceFile(.{
        .file = b.path("validator.c"),
    });
    validator.root_module.sanitize_c = false; // sanitizer triggers on misaligned access in mini-rv32ima, even though that should be fine...
    b.installArtifact(validator);

    const linux_emu = b.addExecutable(.{
        .name = "riscv-linux-emu",
        .root_source_file = b.path("linux_emu.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    linux_emu.addIncludePath(mini_rv32ima.path("mini-rv32ima"));
    linux_emu.addIncludePath(b.path("."));
    linux_emu.addCSourceFile(.{
        .file = b.path("validator.c"),
    });
    linux_emu.root_module.sanitize_c = false; // sanitizer triggers on misaligned access in mini-rv32ima, even though that should be fine...
    b.installArtifact(linux_emu);

    const validate_cmd = b.addRunArtifact(validator);
    validate_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        validate_cmd.addArgs(args);
    }

    const validate_step = b.step("validate", "Create golden status for riscv selftest");
    validate_step.dependOn(&validate_cmd.step);

    const linux_emu_cmd = b.addRunArtifact(validator);
    linux_emu_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        linux_emu_cmd.addArgs(args);
    }

    const linux_emu_step = b.step("linux", "Emulate linux");
    linux_emu_step.dependOn(&linux_emu_cmd.step);

}
