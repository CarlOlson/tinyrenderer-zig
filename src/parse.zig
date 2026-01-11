const std = @import("std");

pub const ParseError = error{
    NoMatch,
};

pub fn unsigned(comptime T: type, buf: []const u8) !struct { T, []const u8 } {
    const t = switch (@typeInfo(T)) {
        .optional => |*t| t.*.child,
        else => T,
    };

    for (buf, 0..) |char, i| {
        if (char >= '0' and char <= '9') continue;
        if (i == 0) break;
        return .{
            try std.fmt.parseUnsigned(t, buf[0..i], 10),
            buf[i..],
        };
    }

    return switch (@typeInfo(T)) {
        .optional => |_| .{ null, buf },
        else => ParseError.NoMatch,
    };
}

pub fn float(comptime T: type, buf: []const u8) !struct { T, []const u8 } {
    const t = switch (@typeInfo(T)) {
        .optional => |*t| t.*.child,
        else => T,
    };

    var decimal = false;
    var j: usize = 0;
    for (buf) |char| {
        if (!decimal and char == '.') {
            decimal = true;
            j += 1;
        } else if ((char >= '0' and char <= '9') or (j == 0 and char == '-')) {
            j += 1;
        } else {
            break;
        }
    }

    if (j == 0) {
        return switch (@typeInfo(T)) {
            .optional => |_| .{ null, buf },
            else => ParseError.NoMatch,
        };
    } else {
        return .{
            try std.fmt.parseFloat(t, buf[0..j]),
            buf[j..],
        };
    }
}

const empty = [0]u8{};

pub fn word(buf: []const u8) struct { []const u8, []const u8 } {
    if (std.mem.indexOfScalar(u8, buf, ' ')) |i| {
        return .{ buf[0..i], buf[i..] };
    } else {
        return .{ buf, empty[0..] };
    }
}

pub fn skipTo(comptime T: type, buf: []const T, value: T) []const T {
    if (std.mem.indexOfScalar(T, buf, value)) |i| {
        return buf[i..];
    } else {
        return empty[0..];
    }
}

pub fn skip(comptime T: type, buf: []const T, value: T) []const T {
    for (buf, 0..) |x, i| {
        if (x != value) return buf[i..];
    }
    return empty[0..];
}

pub fn eof(buf: []const u8) ParseError!void {
    if (buf.len != 0) return ParseError.NoMatch;
}
