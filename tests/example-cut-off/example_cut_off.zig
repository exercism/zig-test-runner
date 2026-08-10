const std = @import("std");

pub fn value() u32 {
    return 1;
}

// A solution that ends the process takes the test runner down with it, so
// zig never prints a status line for the test that was running, nor the
// summary that normally closes its report.
pub fn bail() void {
    std.process.exit(1);
}
