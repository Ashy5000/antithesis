const std = @import("std");
const libantithesis = @import("main.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const device = try libantithesis.AntithesisDevice.antithesisInit("/dev/antithesis", gpa.allocator());
    try device.antithesisWrite("Hello Antithesis!");
}
