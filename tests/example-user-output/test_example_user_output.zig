const std = @import("std");
const testing = std.testing;

const mod = @import("example_user_output.zig");

test "greet returns a five-letter greeting" {
    const result = try mod.greet();
    try testing.expect(result.len == 5);
}
