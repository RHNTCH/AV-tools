const std = @import("std");

// Импортируем заголовочный файл
const c = @cImport({
    @cInclude("sqlite3.h"); // Имя заголовочного файла
});

pub fn main() !void {
    // Теперь вы можете использовать C-функции и типы через префикс `c.`
    const db: ?*c.sqlite3 = null;
    _ = c.sqlite3_open_v2("test.db", @ptrCast(@constCast(&db)), 0, null);
    
    std.debug.print("SQLite version: {s}\n", .{c.sqlite3_libversion()});
}