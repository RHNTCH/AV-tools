const std = @import("std");
const changePath = @import("changePath.zig");
const Arguments = enum {
    changePath,
    help,
    opc,
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
        .help => printReference(),
        .changePath => try changePath.run(allocator, io, args[2..]),
        .opc => std.debug.print("In development...\n", .{}),
    }
}

fn printReference() void {
    std.debug.print("Usage:\n", .{});
    std.debug.print("AV-tools help\n", .{});
    std.debug.print("AV-tools changePath -option1, -option2...\n\n", .{});
    std.debug.print("For additional information on specific function usage type:\n  AV-tools <function> help\n", .{});
}
