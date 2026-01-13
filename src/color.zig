const std = @import("std");

pub const Color = struct {
    b: u8 = 0x00,
    g: u8 = 0x00,
    r: u8 = 0x00,
    a: u8 = 0xFF,

    pub const Transparent: @This() = .{ .b = 0, .g = 0, .r = 0, .a = 0 };
    pub const Black: @This() = .{ .b = 0, .g = 0, .r = 0 };
    pub const White: @This() = .{ .b = 255, .g = 255, .r = 255, .a = 255 };
    pub const Green: @This() = .{ .b = 0, .g = 255, .r = 0, .a = 255 };
    pub const Red: @This() = .{ .b = 0, .g = 0, .r = 255, .a = 255 };
    pub const Blue: @This() = .{ .b = 255, .g = 128, .r = 64, .a = 255 };
    pub const Yellow: @This() = .{ .b = 0, .g = 200, .r = 255, .a = 255 };

    pub fn equal(a: @This(), b: @This()) bool {
        return a.b == b.b and a.g == b.g and a.r == b.r and a.a == b.a;
    }

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

    /// Convert an sRGB component to linear RGB
    fn decode(n: u8) f32 {
        const nf: f32 = @floatFromInt(n);
        if (nf <= 0.04045) {
            return nf / 12.92;
        } else {
            return std.math.pow(f32, (nf + 0.055) / 1.055, 2.4);
        }
    }

    /// Convert a linear RGB component to sRGB
    fn encode(nf: f32) u8 {
        if (nf <= 0.0031308) {
            return @intFromFloat(@round(nf * 12.92));
        } else {
            return @intFromFloat(@round(1.055 * std.math.pow(f32, nf, 1.0 / 2.4) - 0.055));
        }
    }

    pub fn lerp(a: @This(), b: @This(), t: f32) @This() {
        return .{
            .b = encode(t * decode(a.b) + (1 - t) * decode(b.b)),
            .g = encode(t * decode(a.g) + (1 - t) * decode(b.g)),
            .r = encode(t * decode(a.r) + (1 - t) * decode(b.r)),
            .a = @intFromFloat(t * @as(f32, @floatFromInt(a.a)) + (1 - t) * @as(f32, @floatFromInt(b.a))),
        };
    }
};
