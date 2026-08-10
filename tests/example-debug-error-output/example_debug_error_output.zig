const std = @import("std");

pub fn greet() []const u8 {
    std.debug.print("error: greet was called with no arguments\n", .{});
    return "hi";
}
