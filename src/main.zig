const std = @import("std");
const Io = std.Io;

const AV_tools = @import("AV_tools");
const argsProc = @import("argsProc.zig");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(arena);
    argsProc.procArgs(arena, args, io) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        std.process.exit(1);
    };
}
