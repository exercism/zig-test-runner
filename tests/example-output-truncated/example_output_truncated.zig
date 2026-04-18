const std = @import("std");
const mem = std.mem;

pub fn detectAnagrams(
    allocator: mem.Allocator,
    word: []const u8,
    candidates: []const []const u8,
) !std.BufSet {
    for (candidates) |c| std.debug.print("{s}\n", .{c});
    const probe = try allocator.dupe(u8, word);
    allocator.free(probe);
    return std.BufSet.init(allocator);
}
