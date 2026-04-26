const std = @import("std");

pub fn greet() ![]const u8 {
    std.debug.print("debug: computed bad greeting\n", .{});
    return "Goodbye";
}
