const std = @import("std");
const tga = @import("./tga.zig");
const Color = tga.Color;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var image = try tga.Image.alloc(allocator, 64, 64);
    defer image.deinit(allocator);

    const ax = 7;
    const ay = 3;
    const bx = 12;
    const by = 37;
    const cx = 62;
    const cy = 53;

    image.clear(Color.Black);

    image.line(ax, ay, bx, by, Color.Blue);
    image.line(cx, cy, bx, by, Color.Green);
    image.line(cx, cy, ax, ay, Color.Yellow);
    image.line(ax, ay, cx, cy, Color.Red);

    try image.saveToFile("framebuffer.tga");
}
