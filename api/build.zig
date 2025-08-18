const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const example = b.addExecutable(.{
        .name = "antithesis_example",
        .root_source_file = b.path("src/example.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (b.option(bool, "examples", "install API usage examples") orelse false) {
        const install = b.addInstallArtifact(example, .{ .dest_dir = .{ .override = .{ .custom = "../../../deps/initramfs/usr/sbin/" } } });
        b.default_step.dependOn(&install.step);
    }
}
