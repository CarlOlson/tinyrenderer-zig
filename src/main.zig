const std = @import("std");
const zbench = @import("zbench");
const tga = @import("./tga.zig");
const wavefront = @import("./wavefront.zig");
const Color = @import("./color.zig").Color;

const size = 1024;
var framebuffer: tga.Image = undefined;

var prng: std.Random.DefaultPrng = .init(0);
const rand = prng.random();

inline fn scale(n: f32) f32 {
    return @round((n + 1) * (size - 1) / 2);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var obj = try wavefront.readFile("./diablo3_pose.obj", allocator);
    defer obj.deinit(allocator);

    framebuffer = try tga.Image.alloc(allocator, size, size);
    defer framebuffer.deinit(allocator);

    framebuffer.clear(Color.Black);

    var iter = obj.faceIterator();
    while (iter.next()) |m| {
        const a, const b, const c = m.points().*;
        const color = Color.hsl(rand.float(f32) * 60, ((a.z + b.z + c.z) + 3) / 6, ((a.z + b.z + c.z) + 3) / 6);
        framebuffer.triangle(scale(a.x), scale(a.y), scale(b.x), scale(b.y), scale(c.x), scale(c.y), color);
    }

    // framebuffer = try tga.Image.alloc(allocator, size, size);
    // defer framebuffer.deinit(allocator);

    // framebuffer.clear(Color.Black);

    // framebuffer.triangle(7, 45, 35, 100, 45, 60, Color.Red);
    // framebuffer.triangle(120, 35, 90, 5, 45, 110, Color.White);
    // framebuffer.triangle(115, 83, 80, 90, 85, 120, Color.Green);

    try framebuffer.saveToFile("framebuffer.tga");
}

const LineBenchmark = struct {
    loops: usize,

    fn init(loops: usize) @This() {
        return .{
            .loops = loops,
        };
    }

    pub fn run(self: *@This(), _: std.mem.Allocator) void {
        for (0..self.loops) |_| {
            framebuffer.line(7, 3, 12, 37, Color.Blue);
            framebuffer.line(62, 63, 12, 37, Color.Green);
            framebuffer.line(62, 63, 7, 3, Color.Yellow);
            framebuffer.line(7, 3, 62, 63, Color.Red);
        }
    }
};

const TriangleBenchmark = struct {
    loops: usize,

    fn init(loops: usize) @This() {
        return .{
            .loops = loops,
        };
    }

    pub fn run(self: *@This(), _: std.mem.Allocator) void {
        for (0..self.loops) |_| {
            framebuffer.triangle(7, 45, 35, 100, 45, 60, Color.Red);
            framebuffer.triangle(120, 35, 90, 5, 45, 110, Color.White);
            framebuffer.triangle(115, 83, 80, 90, 85, 120, Color.Green);
        }
    }
};

test "benchmark" {
    var buf: [1024]u8 = undefined;
    const bw = std.debug.lockStderrWriter(&buf);
    defer std.debug.unlockStderrWriter();

    const allocator = std.testing.allocator;

    var bench = zbench.Benchmark.init(allocator, .{});
    defer bench.deinit();

    framebuffer = try tga.Image.alloc(allocator, 64, 64);
    defer framebuffer.deinit(allocator);
    framebuffer.clear(Color.Black);

    // ~9ms debug, ~170us fast
    try bench.addParam("Line Benchmark 4k", &LineBenchmark.init(1000), .{});

    // ~42ms fast
    // try bench.addParam("Line Benchmark 1m", &LineBenchmark.init(250_000), .{});

    // This was 1.7ms/200ms (fast/debug) when using `self.set`, and
    // 1.4ms/19.4ms after switching to `@memset`.
    try bench.addParam("Triangle Benchmark 3k", &TriangleBenchmark.init(1000), .{});

    try bench.run(bw);
}
