const std = @import("std");

const AntithesisError = error { IO };

const AntithesisArgType = enum { data8, data32, datan };

const AntithesisArg = union(AntithesisArgType) {
    data8: u8,
    data32: u32,
    datan: []u8,
};

const AntithesisCommand = struct {
    prefix: u8,
    args: []AntithesisArg,

    fn sep32(word: u32, allocator: std.mem.Allocator) ![]u8 {
        const a: u8 = @as(u8, @intCast(word & 0b11111111));
        const b: u8 = @as(u8, @intCast((word >> 8) & 0b11111111));
        const c: u8 = @as(u8, @intCast((word >> 16) & 0b11111111));
        const d: u8 = @as(u8, @intCast((word >> 24) & 0b11111111));
        var res = try allocator.alloc(u8, 4);
        res[0] = a;
        res[1] = b;
        res[2] = c;
        res[3] = d;
        return res;
    }

    fn encode(command: AntithesisCommand, allocator: std.mem.Allocator) ![]const u8 {
        var data = std.ArrayList(u8).init(allocator);
        defer data.deinit();
        try data.append(command.prefix);
        for (command.args) |arg| {
            switch (arg) {
                .data8 => |val| try data.append(val),
                .data32 => |val| try data.appendSlice(try sep32(val, allocator)),
                .datan => |val| try data.appendSlice(val),
            }
        }
        return try data.toOwnedSlice();
    }
};

const AntithesisObject = struct {
    id: u32,
    size: u32,
};

pub const AntithesisDevice = struct {
    file: std.fs.File,

    pub fn init(path: []const u8) !AntithesisDevice {
        const file = try std.fs.openFileAbsolute(path, .{ .mode = std.fs.File.OpenMode.read_write });

        const device = AntithesisDevice {
            .file = file,
        };

        return device;
    }

    fn execute(device: AntithesisDevice, command: AntithesisCommand, buf: []u8, allocator: std.mem.Allocator) !void {
        if (try device.file.write(try command.encode(allocator)) == 0) {
            return AntithesisError.IO;
        }
        _ = try device.file.read(buf) < buf.len;
    }

    pub fn alloc(device: AntithesisDevice, size: u32, allocator: std.mem.Allocator) !AntithesisObject {
        const arg_size = AntithesisArg { .data32 = size };
        var args = try allocator.alloc(AntithesisArg, 1);
        defer allocator.free(args);
        args[0] = arg_size;
        const command = AntithesisCommand {
            .prefix = 0,
            .args = args,
        };
        const buf = try allocator.alloc(u8, 4);
        defer allocator.free(buf);
        try device.execute(command, buf, allocator);
        const id = (@as(u32, buf[3]) << 24) | (@as(u32, buf[2]) << 16) | (@as(u32, buf[1]) << 8) | @as(u32, buf[0]);
        return AntithesisObject { .id = id, .size = size };
    }

    pub fn write(device: AntithesisDevice, object: AntithesisObject, buf: []u8, allocator: std.mem.Allocator) !void {
        const arg_id = AntithesisArg { .data32 = object.id };
        const arg_data = AntithesisArg { .datan = buf };
        var args = try allocator.alloc(AntithesisArg, 2);
        defer allocator.free(args);
        args[0] = arg_id;
        args[1] = arg_data;
        const command = AntithesisCommand {
            .prefix = 1,
            .args = args,
        };
        const buf_ret = try allocator.alloc(u8, 0);
        defer allocator.free(buf_ret);
        try device.execute(command, buf, allocator);
    }

    pub fn modeset(device: AntithesisDevice, object: AntithesisObject, width: u32, height: u32, allocator: std.mem.Allocator) !void {
        const arg_addr = AntithesisArg { .data32 = object.id };
        const arg_width = AntithesisArg { .data32 = width };
        const arg_height = AntithesisArg { .data32 = height };
        var args = try allocator.alloc(AntithesisArg, 3);
        defer allocator.free(args);
        args[0] = arg_addr;
        args[1] = arg_width;
        args[2] = arg_height;
        const command = AntithesisCommand {
            .prefix = 2,
            .args = args,
        };
        const buf = try allocator.alloc(u8, 0);
        defer allocator.free(buf);
        try device.execute(command, buf, allocator);
    }
};
