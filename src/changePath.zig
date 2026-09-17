const std = @import("std");

const changePathErrors = error{
    TooManyOrNotEnoughArguments,
    InvalidArgumentSequence,
    InvalidArgument,
    InvalidParameters,
};

pub fn run(allocator: std.mem.Allocator, io: std.Io, args: []const []const u8) !void {
    if (args.len != 4) {
        printHelp();
        return changePathErrors.TooManyOrNotEnoughArguments;
    }

    var conf_path: ?[]const u8 = null;
    var libs_path: ?[]const u8 = null;

    var i: usize = 0;

    while (i < args.len) {
        const arg = args[i];

        if (i + 1 >= args.len) {
            printHelp();
            return changePathErrors.InvalidArgumentSequence;
        }

        const value = args[i + 1];

        if (std.mem.eql(u8, arg, "-conf_path")) {
            conf_path = value;
        } else if (std.mem.eql(u8, arg, "-libs_path")) {
            libs_path = value;
        } else {
            printHelp();
            return changePathErrors.InvalidArgumentSequence;
        }

        i += 2;
    }

    if (conf_path == null or libs_path == null) {
        printHelp();
        return changePathErrors.InvalidParameters;
    }

    try changePath(allocator, conf_path.?, libs_path.?, io);
}

pub fn changePath(
    allocator: std.mem.Allocator,
    config_path: []const u8,
    dest_path: []const u8,
    io: std.Io,
) !void {
    const libs = try parseLibraryNames(
        allocator,
        config_path,
        io,
    );

    var dir = try std.Io.Dir.cwd().openDir(io, config_path, .{
        .iterate = true,
    });
    defer dir.close(io);

    var file = try dir.createFile(io, "new_paths", .{});
    defer file.close(io);

    std.debug.print("Created file: \"new_paths\" in config's directory ({s})\n", .{config_path});

    var buffer: [4096]u8 = undefined;
    var file_writer = file.writer(io, &buffer);
    var writer = &file_writer.interface;

    for (libs) |lib| {
        const new_path = try findLibrary(
            allocator,
            dest_path,
            lib,
            io,
        );

        if (new_path) |path| {
            try writer.print("proj_path = \"{s}\"\n", .{path});

            std.debug.print("Added path for {s}.\n", .{lib});
        } else {
            std.debug.print("Path for {s} not found. Skipping.\n", .{lib});
        }
    }
    try writer.flush();
}

fn parseLibraryNames(
    allocator: std.mem.Allocator,
    config_path: []const u8,
    io: std.Io,
) ![][]const u8 {
    var dir = try std.Io.Dir.cwd().openDir(io, config_path, .{});
    defer dir.close(io);

    const file = try dir.openFile(io, "config", .{});
    defer file.close(io);

    var reader_buffer: [4096]u8 = undefined;
    var reader = file.reader(io, &reader_buffer);
    var lib_list = try std.ArrayList([]const u8).initCapacity(allocator, 4096);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (!std.mem.startsWith(u8, line, "proj_path")) {
            continue;
        }

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
        if (entry.kind != .directory)
            continue;

        if (std.mem.eql(u8, entry.basename, lib_name)) {
            return try dir.realPathFileAlloc(
                io,
                entry.path,
                allocator,
            );
        }
    }

    return null;
}

fn printHelp() void {
    std.debug.print("Usage:\n", .{});
    std.debug.print(".\\AV_tools.exe changePath -conf_path <relative path to config directory> -lib_path <relative path to libs directory>\n", .{});
    std.debug.print("Important: all paths have to be relative to the directory, where program starts.\n", .{});
    std.debug.print("Also, program recoursivly visits all childish directories in libs_path\n", .{});
}
