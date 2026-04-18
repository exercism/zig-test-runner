const std = @import("std");
const testing = std.testing;

const collatz = @import("example_error_exercise.zig");
const ComputationError = collatz.ComputationError;

test "zero steps for one" {
    const expected: usize = 0;
    const actual = try collatz.steps(1);
    try testing.expectEqual(expected, actual);
}

test "divide if even" {
    const expected: usize = 4;
    const actual = try collatz.steps(16);
    try testing.expectEqual(expected, actual);
}

test "even and odd steps" {
    const expected: usize = 9;
    const actual = try collatz.steps(12);
    try testing.expectEqual(expected, actual);
}

test "large number of even and odd steps" {
    const expected: usize = 152;
    const actual = try collatz.steps(1_000_000);
    try testing.expectEqual(expected, actual);
}

test "zero is an error" {
    const expected = ComputationError.IllegalArgument;
    const actual = collatz.steps(0);
    try testing.expectError(expected, actual);
}
