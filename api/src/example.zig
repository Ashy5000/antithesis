const std = @import("std");
const libantithesis = @import("main.zig");

const width = 50;
const height = 50;
const bytes_per_pix = 4;
const fb_size = width * height * bytes_per_pix;

pub fn main() !void {
    var debugallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var gpa = debugallocator.allocator();
    const device = try libantithesis.AntithesisDevice.init("/dev/antithesis");
    std.debug.print("Antithesis (zig): Device initialized.\n", .{});
    const object = try device.alloc(fb_size, gpa);
    std.debug.print("Antithesis (zig): Object allocated. ID: {d}\n", . { object.id });
    try device.modeset(object, width, height, gpa);
    std.debug.print("Antithesis (zig): Modeset executed.\n", .{});
    const data = try gpa.alloc(u8, fb_size);
    var y: u32 = 0;
    var x: u32 = 0;
    var z: u32 = 0;
    while (y < height) : (y += 1) {
        while (x < width) : (x += 1) {
            while (z < bytes_per_pix) : (z += 1) {
                if (z == 2) {
                    // Red = x
                    data[y * width * bytes_per_pix + x * bytes_per_pix + z] = @as(u8, @intCast(x * 255 / width));
                } else if (z == 1) {
                    // Green = y
                    data[y * width * bytes_per_pix + x * bytes_per_pix + z] = @as(u8, @intCast(y * 255 / height));
                } else {
                    data[y * width * bytes_per_pix + x * bytes_per_pix + z] = 0;
                }
            }
            z = 0;
        }
        x = 0;
    }
    defer gpa.free(data);
    try device.write(object, data, gpa);
    
    std.debug.print("Antithesis (zig): Data written.\n", .{});
}
