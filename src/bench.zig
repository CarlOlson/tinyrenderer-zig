const std = @import("std");
const zbench = @import("zbench");
const tga = @import("./tga.zig");
const Color = @import("./color.zig").Color;

const debug = @import("builtin").mode == .Debug;
const size = 128;
var framebuffer: tga.Image = undefined;

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
            framebuffer.triangle(35, 100, 7, 45, 45, 60, Color.Red);
            framebuffer.triangle(90, 5, 120, 35, 45, 110, Color.Blue);
            framebuffer.triangle(80, 90, 115, 83, 85, 120, Color.Green);
        }
    }
};

const TriangleBCBenchmark = struct {
    loops: usize,

    fn init(loops: usize) @This() {
        return .{
            .loops = loops,
        };
    }

    pub fn run(self: *@This(), _: std.mem.Allocator) void {
        for (0..self.loops) |_| {
            framebuffer.triangleBC(35, 100, 7, 45, 45, 60, Color.Red);
            framebuffer.triangleBC(90, 5, 120, 35, 45, 110, Color.White);
            framebuffer.triangleBC(80, 90, 115, 83, 85, 120, Color.Green);
        }
    }
};

pub fn main() !void {
    var buf: [1024]u8 = undefined;
    const bw = std.debug.lockStderrWriter(&buf);
    defer std.debug.unlockStderrWriter();

    const allocator = std.heap.page_allocator;

    var bench = zbench.Benchmark.init(allocator, .{
        .max_iterations = if (debug) 1 else 1024,
    });
    defer bench.deinit();

    framebuffer = try tga.Image.alloc(allocator, size, size);
    defer framebuffer.deinit(allocator);
    framebuffer.clear(Color.Transparent);

    // ~9ms debug, ~180us fast
    try bench.addParam("Line 4k", &LineBenchmark.init(1000), .{});

    // ~42ms fast
    // try bench.addParam("Line 1m", &LineBenchmark.init(250_000), .{});

    // This was 1.7ms/200ms (fast/debug) when using `self.set`, and
    // 1.4ms/19.4ms after switching to `@memset`.  1.3ms/16ms after
    // moving `self.pixel()` out of loop.
    try bench.addParam("Triangle 3k", &TriangleBenchmark.init(1000), .{});

    // 4.5ms/450ms
    try bench.addParam("TriangleBC 3k", &TriangleBCBenchmark.init(1000), .{});

    try bench.run(bw);
}
