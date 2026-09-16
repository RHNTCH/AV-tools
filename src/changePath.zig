const std = @import("std");
const ascii = std.ascii;

pub fn changePath(
    allocator: std.mem.Allocator,
    config_path: []const u8,
    dest_path: []const u8,
    io: std.Io,
) !void {
    const libs = try parseLibraryNames(allocator, config_path, io);
    for (libs) |lib| {
        std.debug.print("LIB: [{s}]\n", .{lib});

        const new_path = try findLibrary(
            allocator,
            dest_path,
            lib,
            io,
        );

        std.debug.print("new_path: {?s}\n", .{new_path});
    }
}

fn parseLibraryNames(allocator: std.mem.Allocator, config_path: []const u8, io: std.Io) ![][]const u8 {
    var dir = try std.Io.Dir.cwd().openDir(io, config_path, .{});
    defer dir.close(io);

    const file = try dir.openFile(io, "config", .{});
    defer file.close(io);

    var reader_buffer: [4096]u8 = undefined;
    var reader = file.reader(io, &reader_buffer);
    var lib_list = try std.ArrayList([]const u8).initCapacity(allocator, 4096);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (!std.mem.startsWith(u8, line, "proj_path")) continue;
        if (line.len > 0 and line[0] == '#') continue;

        var trimmed_line = std.mem.trim(u8, line, " =\t\"");

        const pos = std.mem.findLastAny(u8, trimmed_line, "\\/") orelse continue;
        const lib_name = try allocator.dupe(u8, trimmed_line[pos + 1 ..]);
        try lib_list.append(allocator, lib_name);
    }
    const lib_names = try lib_list.toOwnedSlice(allocator);
    return lib_names;
}

fn findLibrary(
    allocator: std.mem.Allocator,
    dest_path: []const u8,
    lib_name: []const u8,
    io: std.Io,
) !?[]u8 {
    var dir = try std.Io.Dir.cwd().openDir(io, dest_path, .{
        .iterate = true,
    });
    defer dir.close(io);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next(io)) |entry| {
        std.debug.print(
            "ENTRY: kind={any}, basename=[{s}], path=[{s}]\n",
            .{
                entry.kind,
                entry.basename,
                entry.path,
            },
        );

        if (entry.kind != .directory)
            continue;
        std.debug.print("lib_name bytes: {any}\n", .{lib_name});
        std.debug.print("basename bytes: {any}\n", .{entry.basename});
        if (std.mem.eql(u8, entry.basename, lib_name)) {
            return try allocator.dupe(u8, entry.path);
        }
    }

    return null;
}
