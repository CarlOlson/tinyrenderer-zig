const assert = @import("./assert.zig");

pub fn absDistance(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return @max(a, b) - @min(a, b);
}

pub const Vector2u = struct {
    x: u32,
    y: u32,
};

pub const Vector3u = struct {
    x: u32,
    y: u32,
    z: u32,
};

pub const Vector2 = struct {
    x: f32,
    y: f32,

    pub fn dot(a: *const @This(), b: *const @This()) f32 {
        return a.x * b.x + a.y * b.y;
    }
};

pub const Vector3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn dot(a: *const @This(), b: *const @This()) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    pub fn cross(a: *const @This(), b: *const @This()) @This() {
        return .{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    }

    pub fn add(a: *const @This(), b: *const @This()) @This() {
        return .{
            .x = a.x + b.x,
            .y = a.y + b.y,
            .z = a.z + b.z,
        };
    }

    pub fn negate(a: *const @This()) @This() {
        return .{
            .x = -a.x,
            .y = -a.y,
            .z = -a.z,
        };
    }

    pub fn scale(a: *const @This(), n: f32) @This() {
        return .{
            .x = a.x * n,
            .y = a.y * n,
            .z = a.z * n,
        };
    }
};

pub const Matrix3 = struct {
    /// Layout:
    ///   0 3 6
    ///   1 4 7
    ///   2 5 8
    value: [9]f32,

    pub fn col(self: *@This(), i: anytype) Vector3 {
        return .{
            .x = self.value[i * 3 + 0],
            .y = self.value[i * 3 + 1],
            .z = self.value[i * 3 + 2],
        };
    }

    pub fn row(self: *@This(), i: anytype) Vector3 {
        return .{
            .x = self.value[0 + i],
            .y = self.value[3 + i],
            .z = self.value[6 + i],
        };
    }

    pub fn transpose(self: *@This()) Matrix3 {
        return .{
            .value = .{
                self.value[0], self.value[3], self.value[6],
                self.value[1], self.value[4], self.value[7],
                self.value[2], self.value[5], self.value[8],
            },
        };
    }

    pub fn points(self: *const @This()) *const [3]Vector3 {
        return @ptrCast(&self.value);
    }
};

pub fn signedTriangleArea(ax: f32, ay: f32, bx: f32, by: f32, cx: f32, cy: f32) f32 {
    return 0.5 * ((by - ay) * (bx + ax) + (cy - by) * (cx + bx) + (ay - cy) * (ax + cx));
}

pub fn triangleAreaSign(comptime T: type, ax: T, ay: T, bx: T, by: T, cx: T, cy: T) bool {
    @setFloatMode(.optimized);
    @setRuntimeSafety(false);
    const fasterSign = by * ax + cy * bx + ay * cx >= ay * bx + by * cx + cy * ax;
    return fasterSign;
}

pub const BCIterator = struct {
    value: isize,
    lastRowValue: isize,
    xincr: isize,
    yincr: isize,

    pub fn init(ax: usize, ay: usize, bx: usize, by: usize, cx: usize, cy: usize) @This() {
        @setRuntimeSafety(false);
        const left: isize = @intCast(by * ax + cy * bx + ay * cx);
        const right: isize = @intCast(ay * bx + by * cx + cy * ax);
        return .{
            .value = left - right,
            .lastRowValue = left - right,
            .xincr = @as(isize, @intCast(by)) - @as(isize, @intCast(cy)),
            .yincr = @as(isize, @intCast(cx)) - @as(isize, @intCast(bx)),
        };
    }

    pub fn next(self: *@This()) bool {
        @setRuntimeSafety(false);
        const value = self.value >= 0;
        self.value += self.xincr;
        return value;
    }

    pub fn nextRow(self: *@This()) void {
        @setRuntimeSafety(false);
        self.lastRowValue += self.yincr;
        self.value = self.lastRowValue;
    }
};
