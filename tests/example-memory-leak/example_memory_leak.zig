const std = @import("std");
const mem = std.mem;

pub const Pair = struct { a: []u8, b: []u8 };

// Buggy: on failure of the second alloc, the first alloc is never freed.
pub fn makePair(allocator: mem.Allocator) !Pair {
    const first = try allocator.alloc(u8, 16);
    const second = try allocator.alloc(u8, 16);
    return .{ .a = first, .b = second };
}
