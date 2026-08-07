const std = @import("std");
const testing = std.testing;

const mod = @import("example_memory_leak.zig");

fn pairTest(allocator: std.mem.Allocator) anyerror!void {
    const p = try mod.makePair(allocator);
    defer allocator.free(p.a);
    defer allocator.free(p.b);
}

test "makePair cleans up on allocation failure" {
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        pairTest,
        .{},
    );
}

test "sanity pass" {
    try std.testing.expect(1 + 1 == 2);
}
