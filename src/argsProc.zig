const std = @import("std");
const changePath = @import("changePath.zig");
const Arguments = enum {
    generate,
    validate,
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
        .generate => std.debug.print("Generating...\n", .{}),
        .validate => std.debug.print("Validating...\n", .{}),
        .changePath => try changePath.changePath(allocator, args[2], args[3], io),
    }
}

fn printReference() void {
    std.debug.print("Use:\n", .{});
    std.debug.print("1. AV-tools generate -option1, -option2...\n", .{});
    std.debug.print("2. AV-tools validate -option1, -option2...\n\n", .{});
    std.debug.print("3. AV-tools changePath -option1, -option2...\n\n", .{});
    std.debug.print("For more information use:\n   AV-tools <function> -help\n", .{});
}
