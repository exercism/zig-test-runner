// The slug ends in "test", so the module zig reports here is
// "test_example_solution_own_test" — which keeps us honest about finding
// the ".test." that separates the module from the test name.
const std = @import("std");
const testing = std.testing;

const mod = @import("example_solution_own_test.zig");

// task 1
test "a test from the exercise" {
    try testing.expectEqual(1, mod.value());
}
