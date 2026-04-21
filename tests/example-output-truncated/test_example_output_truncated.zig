const std = @import("std");
const testing = std.testing;

const detectAnagrams = @import("example_output_truncated.zig").detectAnagrams;

fn testAnagrams(
    allocator: std.mem.Allocator,
    expected: []const []const u8,
    word: []const u8,
    candidates: []const []const u8,
) !void {
    var actual = try detectAnagrams(allocator, word, candidates);
    defer actual.deinit();
    try testing.expectEqual(expected.len, actual.count());
    for (expected) |e| {
        try testing.expect(actual.contains(e));
    }
}

test "no matches" {
    const expected = [_][]const u8{};
    const word = "diaper";
    const candidates = [_][]const u8{ "hello", "world", "zombies", "pants" };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testAnagrams,
        .{ &expected, word, &candidates },
    );
}

test "detects two anagrams" {
    const expected = [_][]const u8{ "lemons", "melons" };
    const word = "solemn";
    const candidates = [_][]const u8{ "lemons", "cherry", "melons" };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testAnagrams,
        .{ &expected, word, &candidates },
    );
}

test "detects three anagrams" {
    const expected = [_][]const u8{ "gallery", "regally", "largely" };
    const word = "allergy";
    const candidates = [_][]const u8{ "gallery", "ballerina", "regally", "clergy", "largely", "leading" };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testAnagrams,
        .{ &expected, word, &candidates },
    );
}

test "detects anagrams case-insensitively" {
    const expected = [_][]const u8{"Carthorse"};
    const word = "Orchestra";
    const candidates = [_][]const u8{ "cashregister", "Carthorse", "radishes" };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testAnagrams,
        .{ &expected, word, &candidates },
    );
}

test "words are not anagrams of themselves" {
    const expected = [_][]const u8{};
    const word = "BANANA";
    const candidates = [_][]const u8{"BANANA"};
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testAnagrams,
        .{ &expected, word, &candidates },
    );
}

test "detects many anagrams of 26-letter words" {
    const expected = [_][]const u8{
        "ZYXWVUTSRQPONMLKJIHGFEDCBA",
        "MNOPQRSTUVWXYZABCDEFGHIJKL",
        "BADCFEHGJILKNMPORQTSVUXWZY",
        "QWERTYUIOPASDFGHJKLZXCVBNM",
        "GHIJKLMNOPQRSTUVWXYZABCDEF",
        "STUVWXYZABCDEFGHIJKLMNOPQR",
        "DCBAEFGHIJKLMNOPQRSTUVWXYZ",
        "AZBYCXDWEVFUGTHSIRJQKPLOMN",
        "ZAYXBWCVDUESFTGRHQIPJOKLNM",
        "NMLKJIHGFEDCBAZYXWVUTSRQPO",
        "BDFHJLNPRTVXZACEGIKMOQSUWY",
        "YWUSQOMKIGECAXZVTRPNLJHFDB",
        "JKLMNOPQRSTUVWXYZABCDEFGHI",
        "PONMLKJIHGFEDCBAZYXWVUTSRQ",
        "LKJIHGFEDCBAZYXWVUTSRQPONM",
        "CDEFGHIJKLMNOPQRSTUVWXYZAB",
        "EFGHIJKLMNOPQRSTUVWXYZABCD",
        "IJKLMNOPQRSTUVWXYZABCDEFGH",
        "OPQRSTUVWXYZABCDEFGHIJKLMN",
        "UVWXYZABCDEFGHIJKLMNOPQRST",
    };
    const word = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        testAnagrams,
        .{ &expected, word, &expected },
    );
}
