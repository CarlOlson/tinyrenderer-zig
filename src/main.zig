const std = @import("std");
const zbench = @import("zbench");
const tga = @import("./tga.zig");
const wavefront = @import("./wavefront.zig");
const Color = @import("./color.zig").Color;

var framebuffer: tga.Image = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var obj = try wavefront.readFile("./diablo3_pose.obj", allocator);
    defer obj.deinit(allocator);

    framebuffer = try tga.Image.alloc(allocator, 1024, 1024);
    defer framebuffer.deinit(allocator);

    framebuffer.clear(Color.Black);

    for (obj.vertices.items) |v| {
        const x: u16 = @intFromFloat(@round((v.x + 1) * (1024 - 1) / 2));
        const y: u16 = @intFromFloat(@round((v.y + 1) * (1024 - 1) / 2));
        framebuffer.set(x, y, Color.hsl(0, (v.z + 1) / 2, 0.5));
    }

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
        const ax = 7;
        const ay = 3;
        const bx = 12;
        const by = 37;
        const cx = 62;
        const cy = 53;

        for (0..self.loops) |_| {
            framebuffer.line(ax, ay, bx, by, Color.Blue);
            framebuffer.line(cx, cy, bx, by, Color.Green);
            framebuffer.line(cx, cy, ax, ay, Color.Yellow);
            framebuffer.line(ax, ay, cx, cy, Color.Red);
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
    try bench.run(bw);
}
