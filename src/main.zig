const std = @import("std");
const tga = @import("./tga.zig");
const wavefront = @import("./wavefront.zig");
const Color = @import("./color.zig").Color;
const math = @import("./math.zig");

const size = 1024;
var framebuffer: tga.Image = undefined;

var prng: std.Random.DefaultPrng = .init(0);
const rand = prng.random();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // var obj = try wavefront.readFile("./diablo3_pose.obj", allocator);
    var obj = try wavefront.readFile("./african_head.obj", allocator);
    defer obj.deinit(allocator);

    framebuffer = try tga.Image.alloc(allocator, size, size);
    defer framebuffer.deinit(allocator);
    framebuffer.clear(Color.Black);
    framebuffer.checker(32, Color.White);

    var iter = obj.faceIterator();
    while (iter.next()) |m| {
        const af, const bf, const cf = m.points().*;
        const a = af.scaleToScreenSpace(size);
        const b = bf.scaleToScreenSpace(size);
        const c = cf.scaleToScreenSpace(size);
        const color = Color.hsv(rand.float(f32) * 360, ((af.z + bf.z + cf.z) + 3) / 6, ((af.z + bf.z + cf.z) + 3) / 6);
        framebuffer.triangle(a.x, a.y, b.x, b.y, c.x, c.y, color);
    }

    try framebuffer.saveToFile("framebuffer.tga");
}

test "Matrix3.points()" {
    const m = math.Matrix3{
        .value = [_]f32{
            1,   2,   3,
            10,  20,  30,
            100, 200, 300,
        },
    };
    const a, const b, const c = m.points().*;
    std.debug.assert(a.equal(&math.Vector3{ .x = 1, .y = 2, .z = 3 }));
    std.debug.assert(b.equal(&math.Vector3{ .x = 10, .y = 20, .z = 30 }));
    std.debug.assert(c.equal(&math.Vector3{ .x = 100, .y = 200, .z = 300 }));
}
