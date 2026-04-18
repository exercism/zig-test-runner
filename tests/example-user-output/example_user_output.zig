const std = @import("std");

pub fn greet() ![]const u8 {
    var buf: [64]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    try w.interface.writeAll("debug: computed bad greeting\n");
    try w.interface.flush();
    return "Goodbye";
}
