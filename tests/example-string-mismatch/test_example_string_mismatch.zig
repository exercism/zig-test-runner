const std = @import("std");
const testing = std.testing;

const mod = @import("example_string_mismatch.zig");

test "sanity pass" {
    try testing.expect(1 + 1 == 2);
}

test "greeting is exactly Hello, World!" {
    try testing.expectEqualStrings("Hello, World!", mod.greeting());
}
