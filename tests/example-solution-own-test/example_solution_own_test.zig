const std = @import("std");

pub fn value() u32 {
    return 1;
}

// Students may keep their own tests in the solution file. Zig runs them
// alongside ours, and they carry no test_code or task_id of their own.
test "a test the student wrote" {
    try std.testing.expect(value() == 1);
}
