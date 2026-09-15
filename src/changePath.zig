const std = @import("std");
const ascii = std.ascii;

const ChangePathError = error{
    PathNotFound,
};

pub fn changePath(config_path: []const u8, dest_path: []const u8, io: std.Io) !void {
    var dir = std.Io.Dir.cwd().openDir(io, config_path, .{}) catch |err| {
        return switch (err) {
            error.FileNotFound => ChangePathError.PathNotFound,
            else => err,
        };
    };
    defer dir.close(io);

    const file = dir.openFile(io, "config", .{}) catch |err| {
        return switch (err) {
            error.FileNotFound => ChangePathError.PathNotFound,
            else => err,
        };
    };
    defer file.close(io);

    var reader_buffer: [4096]u8 = undefined;
    var reader = file.reader(io, &reader_buffer);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        if (std.mem.eql(u8, line[0], "#")) continue;

        var line_len = line.len - 1;
        var lib = undefined;
        while (line_len != 0) : (line_len -= 1) {
            if (line[line_len] == '/') {
                lib = line[line_len + 1 .. line.len - 1];
                break;
            }
        }
    }
}
