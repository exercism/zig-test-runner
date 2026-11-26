//! Keeps the image's cached ZIR valid on the machine that runs the image.
//!
//! The image ships a Zig cache warmed at build time. Its `z/` folder holds the
//! ZIR (Zig's parsed form of a source file) for each standard library file.
//! Zig trusts a ZIR file only if the size, modification time and inode stored
//! in its header match the source file. Size and modification time come from
//! the image, but the inode is set by the filesystem of the machine that
//! unpacks the image, so it never matches after `docker pull`. Zig then parses
//! the whole standard library again on every run (about 0.8 s).
//!
//! `record` runs at image build. It lists each ZIR file with the source file
//! it was made from, found by the inode in its header.
//!
//! `refresh` runs at the start of each run, on the run's copy of the cache.
//! For each listed file whose size and modification time still match, it
//! writes the source file's current inode into the ZIR header.
//!
//! Usage:
//!   zir-cache record <cache dir> <zig lib dir> <list file>
//!   zir-cache refresh <cache dir> <list file>

const std = @import("std");
const Io = std.Io;

// The start of `std.zig.Zir.Header` (and `Zoir.Header`): four u32 lengths,
// then the source file's inode (u64), size (u64) and mtime (i128, in ns).
const inode_offset = 16;
const header_len = 48;

const Header = struct {
    inode: u64,
    size: u64,
    mtime: i128,

    fn read(io: Io, file: Io.File) !?Header {
        var buf: [header_len]u8 = undefined;
        const n = try file.readPositional(io, &.{&buf}, 0);
        if (n < header_len) return null;
        return .{
            .inode = std.mem.readInt(u64, buf[16..24], .little),
            .size = std.mem.readInt(u64, buf[24..32], .little),
            .mtime = std.mem.readInt(i128, buf[32..48], .little),
        };
    }

    fn matches(h: Header, stat: Io.File.Stat) bool {
        return h.size == stat.size and h.mtime == stat.mtime.nanoseconds;
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    if (args.len == 5 and std.mem.eql(u8, args[1], "record")) {
        try record(io, arena, args[2], args[3], args[4]);
    } else if (args.len == 4 and std.mem.eql(u8, args[1], "refresh")) {
        try refresh(io, arena, args[2], args[3]);
    } else {
        std.process.fatal("usage: zir-cache record <cache dir> <zig lib dir> <list file> | refresh <cache dir> <list file>", .{});
    }
}

fn record(io: Io, arena: std.mem.Allocator, cache_path: []const u8, lib_path: []const u8, list_path: []const u8) !void {
    const cwd = Io.Dir.cwd();

    // Map each library file's inode to its path.
    var by_inode: std.AutoHashMapUnmanaged(u64, []const u8) = .empty;
    var lib = try cwd.openDir(io, lib_path, .{ .iterate = true });
    defer lib.close(io);
    var walker = try lib.walk(arena);
    defer walker.deinit();
    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        const stat = try entry.dir.statFile(io, entry.basename, .{});
        const path = try std.fs.path.join(arena, &.{ lib_path, entry.path });
        try by_inode.put(arena, stat.inode, path);
    }

    var list: std.ArrayList(u8) = .empty;
    var zir = try cwd.openDir(io, try std.fs.path.join(arena, &.{ cache_path, "z" }), .{ .iterate = true });
    defer zir.close(io);
    var it = zir.iterate();
    while (try it.next(io)) |entry| {
        if (entry.kind != .file) continue;
        const file = try zir.openFile(io, entry.name, .{});
        defer file.close(io);
        const header = try Header.read(io, file) orelse continue;
        const source = by_inode.get(header.inode) orelse continue;
        const stat = try cwd.statFile(io, source, .{});
        if (!header.matches(stat)) continue;
        try list.print(arena, "{s}\t{s}\n", .{ entry.name, source });
    }
    try cwd.writeFile(io, .{ .sub_path = list_path, .data = list.items });
}

fn refresh(io: Io, arena: std.mem.Allocator, cache_path: []const u8, list_path: []const u8) !void {
    const cwd = Io.Dir.cwd();
    const list = try cwd.readFileAlloc(io, list_path, arena, .unlimited);
    var zir = try cwd.openDir(io, try std.fs.path.join(arena, &.{ cache_path, "z" }), .{});
    defer zir.close(io);

    var lines = std.mem.tokenizeScalar(u8, list, '\n');
    while (lines.next()) |line| {
        var fields = std.mem.splitScalar(u8, line, '\t');
        const name = fields.next() orelse continue;
        const source = fields.next() orelse continue;
        // Any file that has gone or changed is left for Zig to rebuild.
        const stat = cwd.statFile(io, source, .{}) catch continue;
        const file = zir.openFile(io, name, .{ .mode = .read_write }) catch continue;
        defer file.close(io);
        const header = try Header.read(io, file) orelse continue;
        if (!header.matches(stat) or header.inode == stat.inode) continue;
        var inode: [8]u8 = undefined;
        std.mem.writeInt(u64, &inode, stat.inode, .little);
        _ = try file.writePositional(io, &.{&inode}, inode_offset);
    }
}
