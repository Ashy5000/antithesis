const std = @import("std");

const AntithesisError = error { IO };

pub const AntithesisDevice = struct {
    file: std.fs.File,

    pub fn antithesisInit(path: []const u8, allocator: std.mem.Allocator) !AntithesisDevice {
        var exists = true;
        _ = std.fs.cwd().openFile(path, .{ .mode = std.fs.File.OpenMode.write_only }) catch {
            exists = false;
        };

        if (!exists) {
            _ = try std.process.Child.run(.{
                .allocator = allocator,
                .argv = &[_][]const u8 {
                    "mknod",
                    path,
                    "c",
                    "250",
                    "0",
                },
            });
        }

        const file = try std.fs.cwd().openFile(path, .{ .mode = std.fs.File.OpenMode.write_only });

        const device = AntithesisDevice {
            .file = file,
        };

        return device;
    }

    pub fn antithesisWrite(device: AntithesisDevice, data: []const u8) !void {
        const written = try device.file.write(data);

        if (written != data.len) {
            return AntithesisError.IO;
        }
    }
};

