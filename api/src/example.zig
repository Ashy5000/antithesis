const std = @import("std");
const libantithesis = @import("main.zig");

pub fn main() !void {
    var debugallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var gpa = debugallocator.allocator();
    const device = try libantithesis.AntithesisDevice.init("/dev/antithesis");
    std.debug.print("Antithesis (zig): Device initialized.\n", .{});
    const object = try device.alloc(100, gpa);
    std.debug.print("Antithesis (zig): Object allocated. ID: {d}\n", . { object.id });
    try device.modeset(object, 5, 5, gpa);
    std.debug.print("Antithesis (zig): Modeset executed.\n", .{});
    const data = try gpa.alloc(u8, 100);
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        // const offset = i % 4;
        // if (offset == 0 or offset == 1 or offset == 3) {
        //     data[i] = 0;
        // } else {
        //     data[i] = 255;
        // }
        data[i] = 255;
    }
    defer gpa.free(data);
    try device.write(object, data, gpa);
    std.debug.print("Antithesis (zig): Data written.\n", .{});
}
