const std = @import("std");

pub fn equal(a: anytype, b: anytype) void {
    if (a != b) {
        std.debug.print("{} != {}", .{ a, b });
        unreachable;
    }
}
