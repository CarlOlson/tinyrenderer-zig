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

pub const T = struct {
    vertices: ArrayList(math.Vector3),
    faces: ArrayList(math.Vector3u),

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.vertices.deinit(allocator);
        self.faces.deinit(allocator);
    }
};

pub fn readFile(filename: []const u8, allocator: std.mem.Allocator) !T {
    var obj = T{
        .vertices = .empty,
        .faces = .empty,
    };

    const file = try std.fs.cwd().readFileAlloc(allocator, filename, std.math.maxInt(usize));
    defer allocator.free(file);

    var lineIterator = std.mem.splitScalar(u8, file, '\n');
    while (lineIterator.next()) |line| {
        var chunks = std.mem.splitScalar(u8, line, ' ');
        const kind = chunks.next() orelse continue;

        if (std.mem.eql(u8, kind, "v")) {
            const x = try std.fmt.parseFloat(f32, chunks.next() orelse unreachable);
            const y = try std.fmt.parseFloat(f32, chunks.next() orelse unreachable);
            const z = try std.fmt.parseFloat(f32, chunks.next() orelse unreachable);
            try obj.vertices.append(allocator, math.Vector3{ .x = x, .y = y, .z = z });
        } else if (std.mem.eql(u8, kind, "f")) {}
    }

    return obj;
}
