// A run cut off mid-report: the first test passes, the second ends the
// process, and the third never runs. The aborted test must still be
// reported as failed rather than dropped, and the tests that did run must
// keep their results.
const std = @import("std");
const testing = std.testing;

const mod = @import("example_cut_off.zig");

test "first test passes" {
    try testing.expectEqual(1, mod.value());
}

test "second test ends the process" {
    mod.bail();
}

test "third test never runs" {
    try testing.expect(true);
}
