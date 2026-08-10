const std = @import("std");
const testing = std.testing;

const lasagna = @import("example_concept_tasks.zig");

test "a test declared before any marker is not linked to a task" {
    try testing.expectEqual(40, lasagna.expected_minutes_in_oven);
}

// task 1
test "expected minutes in oven" {
    try testing.expectEqual(40, lasagna.expected_minutes_in_oven);
}

test "remaining minutes in oven" {
    try testing.expectEqual(15, lasagna.remainingMinutesInOven(25));
}

// task 2
test "preparation time for one layer" {
    try testing.expectEqual(2, lasagna.preparationTimeInMinutes(1));
}

test "preparation time for four layers" {
    try testing.expectEqual(8, lasagna.preparationTimeInMinutes(4));
}
