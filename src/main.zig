const std = @import("std");
const zbench = @import("zbench");
const tga = @import("./tga.zig");
const wavefront = @import("./wavefront.zig");
const Color = @import("./color.zig").Color;

const size = 512;
var framebuffer: tga.Image = undefined;

inline fn scale(n: f32) u16 {
    return @intFromFloat(@round((n + 1) * (size - 1) / 2));
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

    for (obj.faces.items) |f| {
        const a = obj.vertices.items[f.x - 1];
        const b = obj.vertices.items[f.y - 1];
        const c = obj.vertices.items[f.z - 1];

        framebuffer.line(scale(a.x), scale(a.y), scale(b.x), scale(b.y), Color.Red);
        framebuffer.line(scale(b.x), scale(b.y), scale(c.x), scale(c.y), Color.Red);
        framebuffer.line(scale(c.x), scale(c.y), scale(a.x), scale(a.y), Color.Red);
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
