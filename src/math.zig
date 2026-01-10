pub fn absDistance(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return @max(a, b) - @min(a, b);
}

pub const Vector2 = struct {
    x: f32,
    y: f32,
};
