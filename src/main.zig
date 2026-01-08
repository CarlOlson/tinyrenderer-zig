const std = @import("std");
const tga = @import("./tga.zig");
const Color = tga.Color;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var image = try tga.Image.alloc(allocator, 64, 64);
    defer image.deinit(allocator);

    image.clear(Color.Blue);
    image.set(7, 3, Color.White);
    image.set(12, 37, Color.Yellow);
    image.set(62, 53, Color.Red);

    try image.saveToFile("framebuffer.tga");
}
