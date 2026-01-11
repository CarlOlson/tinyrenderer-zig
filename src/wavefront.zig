// v - vertices
// vt - texture
// vn - normals
// f - faces
// g - ?
// s - ?
// # - comment

const std = @import("std");
const ArrayList = std.ArrayList;
const math = @import("./math.zig");
const parse = @import("./parse.zig");

pub const Object = struct {
    vertices: ArrayList(math.Vector3),
    faces: ArrayList(math.Vector3u),

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.vertices.deinit(allocator);
        self.faces.deinit(allocator);
    }
};

pub fn readFile(filename: []const u8, allocator: std.mem.Allocator) !Object {
    var obj = Object{
        .vertices = .empty,
        .faces = .empty,
    };

    const file = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(file);

    var lineIterator = std.mem.splitScalar(u8, file, '\n');
    while (lineIterator.next()) |line| {
        const kind, var buf = parse.word(line);
        buf = parse.skip(u8, buf, ' ');

        if (std.mem.eql(u8, kind, "v")) {
            const x, buf = try parse.float(f32, buf);
            buf = parse.skip(u8, buf, ' ');
            const y, buf = try parse.float(f32, buf);
            buf = parse.skip(u8, buf, ' ');
            const z, buf = try parse.float(f32, buf);
            try parse.eof(buf);
            try obj.vertices.append(allocator, math.Vector3{ .x = x, .y = y, .z = z });
        } else if (std.mem.eql(u8, kind, "f")) {
            const x, buf = try parse.unsigned(u32, buf);
            buf = parse.skipTo(u8, buf, ' ');
            buf = parse.skip(u8, buf, ' ');
            const y, buf = try parse.unsigned(u32, buf);
            buf = parse.skipTo(u8, buf, ' ');
            buf = parse.skip(u8, buf, ' ');
            const z, buf = try parse.unsigned(u32, buf);
            try obj.faces.append(allocator, math.Vector3u{ .x = x, .y = y, .z = z });
        }
    }

    return obj;
}
