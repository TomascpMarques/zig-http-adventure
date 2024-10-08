const std = @import("std");

pub fn logger(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const scope_prefix = " \x1b[37;49;3m(" ++ switch (scope) {
        else => @tagName(scope),
    } ++ ")\x1b[0m ";

    const prefix = switch (level) {
        .debug => "▶ \x1b[36;49;3m",
        .err => "\x1b[31;49;1m",
        .info => "\x1b[34;49m",
        .warn => "\x1b[35;49;1m",
    } ++ "[" ++ comptime level.asText() ++ "]\x1b[0m" ++ scope_prefix;

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
}
