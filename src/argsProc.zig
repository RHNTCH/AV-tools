const std = @import("std");
const changePath = @import("changePath.zig");
const Arguments = enum {
    changePath,
};

const ProcError = error{
    MissingArgument,
    InvalidArgument,
};

pub fn procArgs(allocator: std.mem.Allocator, args: []const []const u8, io: std.Io) !void {
    if (args.len < 2) {
        printReference();
        return ProcError.MissingArgument;
    }

    const first_arg = args[1];

    const action = std.meta.stringToEnum(Arguments, first_arg) orelse {
        printReference();
        return ProcError.InvalidArgument;
    };

    switch (action) {
        .changePath => try changePath.run(allocator, io, args[2..]),
    }
}

fn printReference() void {
    std.debug.print("Usage:\n", .{});
    std.debug.print("1. AV-tools changePath -option1, -option2...\n\n", .{});
    std.debug.print("For additional information on specific function usage type:\n  AV-tools <function> help\n", .{});
}
