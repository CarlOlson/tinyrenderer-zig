const std = @import("std");

pub const Color = struct {
    b: u8 = 0x00,
    g: u8 = 0x00,
    r: u8 = 0x00,
    a: u8 = 0xFF,

    pub const Black: @This() = .{ .b = 0, .g = 0, .r = 0 };
    pub const White: @This() = .{ .b = 255, .g = 255, .r = 255, .a = 255 };
    pub const Green: @This() = .{ .b = 0, .g = 255, .r = 0, .a = 255 };
    pub const Red: @This() = .{ .b = 0, .g = 0, .r = 255, .a = 255 };
    pub const Blue: @This() = .{ .b = 255, .g = 128, .r = 64, .a = 255 };
    pub const Yellow: @This() = .{ .b = 0, .g = 200, .r = 255, .a = 255 };

    /// Adaptation of https://stackoverflow.com/a/64090995
    pub fn hsl(h: f32, s: f32, l: f32) @This() {
        var color = [4]u8{ 0, 0, 0, 255 };
        const a = s * @min(l, 1 - l);
        for ([3]f32{ 4, 8, 0 }, 0..) |n, i| {
            const k = @mod(n + h / 30, 12);
            const f = l - a * @max(-1, @min(k - 3, 9 - k, 1));
            color[i] = @intFromFloat(@round(std.math.lerp(0, 255, f)));
        }
        return std.mem.bytesToValue(@This(), &color);
    }

    pub fn hsv(h: f32, s: f32, v: f32) @This() {
        var color = [4]u8{ 0, 0, 0, 255 };
        for ([3]f32{ 1, 3, 5 }, 0..) |n, i| {
            const k = @mod(n + h / 60, 6);
            const f = v - v * s * @max(0, @min(k, 4 - k, 1));
            color[i] = @intFromFloat(@round(std.math.lerp(0, 255, f)));
        }
        return std.mem.bytesToValue(@This(), &color);
    }

    // pub fn lerp(a: *const @This(), b: *const @This(), t: f32) @This() {}
};
