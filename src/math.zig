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
};
