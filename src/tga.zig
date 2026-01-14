const std = @import("std");
const assert = @import("./assert.zig");
const math = @import("./math.zig");
const Color = @import("./color.zig").Color;

const debug = @import("builtin").mode == .Debug;

pub const Header = packed struct {
    idLength: u8 = 0,
    colorMapType: u8 = 0,
    datatypeCode: ImageType = .UncompressedTrueColor,
    colorMapOrigin: u16 = 0,
    colorMapLength: u16 = 0,
    colorMapDepth: u8 = 0,
    xOrigin: u16 = 0,
    yOrigin: u16 = 0,
    width: u16 = 0,
    height: u16 = 0,
    bitsPerPixel: u8 = 32,
    imageDescriptor: u8 = 40,

    pub fn imageSize(self: *const @This()) usize {
        return @as(usize, self.width) * self.height * (self.bitsPerPixel / 8);
    }

    pub const size = @bitSizeOf(@This()) / 8;
};

pub const ImageType = enum(u8) {
    Empty = 0,
    UncompressedColorMapped = 1,
    UncompressedTrueColor = 2,
    UncompressedGrapscale = 3,
    RunLengthEncodedColorMapped = 9,
    RunLengthEncodedTrueColor = 10,
    RunLengthEncodedGrayscale = 11,
};

// TODO track overdraw
pub const Image = struct {
    width: u16,
    height: u16,
    buffer: []u8,

    pub fn imageSize(self: *const @This()) usize {
        return @as(usize, self.width) * self.height * 4;
    }

    pub fn saveToFile(self: *@This(), filename: []const u8) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();

        const header = Header{
            .width = self.width,
            .height = self.height,
        };

        // Need to adjust size due to alignment
        try file.writeAll(
            std.mem.asBytes(&header)[0..Header.size],
        );

        try file.writeAll(
            self.buffer[0..self.imageSize()],
        );
    }

    pub fn alloc(allocator: std.mem.Allocator, width: u16, height: u16) !@This() {
        const buffer = try allocator.alloc(u8, @as(usize, width) * height * 4);
        @memset(buffer, 0);

        return .{
            .width = width,
            .height = height,
            .buffer = buffer,
        };
    }

    pub fn pixels(self: *@This()) []Color {
        return @ptrCast(self.buffer);
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.free(self.buffer);
    }

    pub fn clear(self: *@This(), color: Color) void {
        @memset(self.pixels(), color);
    }

    pub fn checker(self: *@This(), size: usize, color: Color) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const ym = (y % (2 * size)) < size;
                const xm = (x % (2 * size)) < size;
                if (ym != xm) continue;
                self.set(u16, @intCast(x), @intCast(y), color);
            }
        }
    }

    inline fn setXY(comptime T: type, buffer: []T, x: anytype, y: anytype, width: anytype, height: anytype, value: T) void {
        // Invert y since we save as top-to-bottom
        buffer[@as(usize, height - 1 - y) * width + x] = value;
    }

    pub fn set(self: *@This(), comptime T: type, x: T, y: T, color: Color) void {
        setXY(Color, self.pixels(), x, y, self.width, self.height, color);
    }

    pub fn line(self: *@This(), ax: u16, ay: u16, bx: u16, by: u16, color: Color) void {
        @setRuntimeSafety(false);
        const steep: bool = math.absDistance(ay, by) > math.absDistance(ax, bx);

        var axf = @as(f32, @floatFromInt(ax));
        var ayf = @as(f32, @floatFromInt(ay));
        var bxf = @as(f32, @floatFromInt(bx));
        var byf = @as(f32, @floatFromInt(by));

        // transpose if steep
        if (steep) {
            std.mem.swap(f32, &axf, &ayf);
            std.mem.swap(f32, &bxf, &byf);
        }

        // make it left-to-right
        if (axf > bxf) {
            std.mem.swap(f32, &axf, &bxf);
            std.mem.swap(f32, &ayf, &byf);
        }

        const mf = (byf - ayf) / (bxf - axf);

        var x: f32 = axf;
        var y: f32 = ayf;
        while (x <= bxf) : (x += 1) {
            // de-transpose if steep, u16 is about twice as fast as usize
            if (steep) {
                self.set(u16, @intFromFloat(@round(y)), @intFromFloat(@round(x)), color);
            } else {
                self.set(u16, @intFromFloat(@round(x)), @intFromFloat(@round(y)), color);
            }

            y += mf;
        }
    }

    fn round(x: anytype) usize {
        return @intFromFloat(@round(x));
    }

    /// Draw a triangle using bounding boxes and barycentric
    /// coordinates.  This seems to be slower than `triangle` due to
    /// hard-to-optimize inner loops.
    pub fn triangleBC(self: *@This(), ax: f32, ay: f32, bx: f32, by: f32, cx: f32, cy: f32, color: Color) void {
        @setRuntimeSafety(false);

        if (math.signedTriangleArea(ax, ay, bx, by, cx, cy) < 1) return;

        const axi: u32 = @intFromFloat(ax);
        const ayi: u32 = @intFromFloat(ay);
        const bxi: u32 = @intFromFloat(bx);
        const byi: u32 = @intFromFloat(by);
        const cxi: u32 = @intFromFloat(cx);
        const cyi: u32 = @intFromFloat(cy);

        const ymin = @min(ayi, byi, cyi);
        const ymax = @max(ayi, byi, cyi);
        const xmin = @min(axi, bxi, cxi);
        const xmax = @max(axi, bxi, cxi);

        const totalAreaSign = math.triangleAreaSign(usize, axi, ayi, bxi, byi, cxi, cyi);

        // It might be slightly faster to merge these to a single
        // iterator, but the current bottleneck seems to be writing
        // the pixels.
        var aIter = math.BCIterator.init(xmin, ymin, bxi, byi, cxi, cyi);
        var bIter = math.BCIterator.init(xmin, ymin, cxi, cyi, axi, ayi);
        var gIter = math.BCIterator.init(xmin, ymin, axi, ayi, bxi, byi);

        for (ymin..ymax) |yi| {
            for (xmin..xmax) |xi| {
                const alpha = aIter.next() == totalAreaSign;
                const beta = bIter.next() == totalAreaSign;
                const gamma = gIter.next() == totalAreaSign;

                if (comptime debug) {
                    const alpha0 = math.triangleAreaSign(usize, xi, yi, bxi, byi, cxi, cyi) == totalAreaSign;
                    const beta0 = math.triangleAreaSign(usize, xi, yi, cxi, cyi, axi, ayi) == totalAreaSign;
                    const gamma0 = math.triangleAreaSign(usize, xi, yi, axi, ayi, bxi, byi) == totalAreaSign;
                    assert.equal(alpha0, alpha);
                    assert.equal(beta0, beta);
                    assert.equal(gamma0, gamma);
                }

                if (!alpha or !beta or !gamma) continue;

                // For some reason this is faster than operating on chunks with @memset
                self.set(usize, xi, yi, color);
            }

            aIter.nextRow();
            bIter.nextRow();
            gIter.nextRow();
        }
    }

    /// Draw a triangle on the screen.  Fast, but not accurate.
    pub fn triangle(self: *@This(), ax0: f32, ay0: f32, bx0: f32, by0: f32, cx0: f32, cy0: f32, color: Color) void {
        @setRuntimeSafety(false);

        if (math.signedTriangleArea(ax0, ay0, bx0, by0, cx0, cy0) < 1) return;

        var ax, var ay, var bx, var by, var cx, var cy = .{ ax0, ay0, bx0, by0, cx0, cy0 };

        if (ay > by) {
            std.mem.swap(f32, &ax, &bx);
            std.mem.swap(f32, &ay, &by);
        }
        if (by > cy) {
            std.mem.swap(f32, &bx, &cx);
            std.mem.swap(f32, &by, &cy);
        }
        if (ay > by) {
            std.mem.swap(f32, &ax, &bx);
            std.mem.swap(f32, &ay, &by);
        }

        const buf = self.pixels();
        const m0 = if (by == ay) 0 else (bx - ax) / (by - ay);
        const m1 = if (cy == ay) 0 else (cx - ax) / (cy - ay);
        const m2 = if (cy == by) 0 else (cx - bx) / (cy - by);
        var x0 = ax;
        var x1 = ax;
        var y = round(ay);
        while (y <= round(by)) : (y += 1) {
            x0 += m0;
            x1 += m1;
            const idx0 = (self.height - y - 1) * self.width + round(@min(x0, x1));
            const idx1 = (self.height - y - 1) * self.width + round(@max(x0, x1));
            @memset(buf[idx0..idx1], color);
        }
        while (y < round(cy)) : (y += 1) {
            x0 += m2;
            x1 += m1;
            const idx0 = (self.height - y - 1) * self.width + round(@min(x0, x1));
            const idx1 = (self.height - y - 1) * self.width + round(@max(x0, x1));
            @memset(buf[idx0..idx1], color);
        }
    }
};

pub fn allocFromFile(allocator: std.mem.Allocator, filename: []const u8) !Image {
    const buffer = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    const header = std.mem.bytesToValue(Header, buffer);

    // This only implements what is necessary, assert to detect incompatible images
    assert.equal(header.xOrigin, 0);
    assert.equal(header.yOrigin, 0);
    assert.equal(header.bitsPerPixel, 32);
    assert.equal(header.imageDescriptor, 40); // top-to-bottom, 8 bit alpha
    assert.equal(header.colorMapType, 0); // no color map
    assert.equal(header.datatypeCode, ImageType.UncompressedTrueColor);

    // Ensure file is expected size
    assert.equal(buffer.len - Header.size, header.imageSize());

    // Reuse existing buffer
    @memmove(buffer[0 .. buffer.len - Header.size], buffer[Header.size..]);

    return .{
        .width = header.width,
        .height = header.height,
        .buffer = buffer,
    };
}
