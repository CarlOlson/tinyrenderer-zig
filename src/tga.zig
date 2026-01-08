const std = @import("std");
const assert = @import("./assert.zig");

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

pub const Color = struct {
    b: u8,
    g: u8,
    r: u8,
    a: u8 = 0xFF,

    pub const Black: @This() = .{ .b = 0, .g = 0, .r = 0 };
    pub const White: @This() = .{ .b = 255, .g = 255, .r = 255, .a = 255 };
    pub const Green: @This() = .{ .b = 0, .g = 255, .r = 0, .a = 255 };
    pub const Red: @This() = .{ .b = 0, .g = 0, .r = 255, .a = 255 };
    pub const Blue: @This() = .{ .b = 255, .g = 128, .r = 64, .a = 255 };
    pub const Yellow: @This() = .{ .b = 0, .g = 200, .r = 255, .a = 255 };
};

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
        const buffer = try allocator.alloc(u8, width * height * 4);
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

    pub fn set(self: *@This(), x: u16, y: u16, color: Color) void {
        self.pixels()[y * self.width + x] = color;
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
