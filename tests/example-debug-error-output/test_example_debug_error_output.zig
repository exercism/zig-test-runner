// Output that looks like a compiler diagnostic, from the two places it can
// come from: what the solution prints, and the source line a stack trace
// echoes back. Neither is a compile error, so the individual test results
// must survive rather than being replaced by one top-level message.
const std = @import("std");
const testing = std.testing;

const mod = @import("example_debug_error_output.zig");

test "passing test alongside error-like debug output" {
    try testing.expect(mod.greet().len == 2);
}

test "failing test alongside error-like debug output" {
    try testing.expect(mod.greet().len == 99);
}

test "failing line carries an error-like comment" {
    try testing.expect(mod.greet().len == 99); // error: expected a longer greeting
}
