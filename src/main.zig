const std = @import("std");
const tga = @import("./tga.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var image = try tga.Image.allocFromFile(allocator, "./test.tga");
    defer image.deinit(allocator);

    try image.saveToFile("./copy.tga");
}
