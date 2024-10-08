const std = @import("std");
const net = std.net;
const http = std.http;

const logging = @import("./logging.zig");
const routing = @import("./http/routing.zig");

pub const std_options = .{
    // Default log level info
    .log_level = .debug,
    .logFn = logging.logger,
};

pub fn main() !void {
    const app_log = std.log.scoped(.app);
    const cons_log = std.log.scoped(.connections);

    app_log.info("Zig HTTP/Server v1", .{});
    app_log.info("Starting...", .{});

    app_log.debug("Creating a GP Allocator", .{});
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_allocator.allocator();

    // Start listening
    app_log.info("Listening on address: \x1b[34;49;1m0.0.0.0:8080\x1b[0m", .{});
    var tcp_server = try net.Address.listen(net.Address{
        .in = try net.Ip4Address.parse("0.0.0.0", 8080),
    }, .{
        .reuse_address = true,
        .reuse_port = true,
    });
    defer tcp_server.deinit();

    const routes = [_]routing.RoutingTuple{
        .{ .r = "/", .h = &handle },
        .{ .r = "/some/stuff", .h = &handle },
    };
    var router = try routing.Router().init(gpa, &routes);
    defer router.deinit();

    while (true) {
        const con = try tcp_server.accept();
        cons_log.info("Accepted a new connection", .{});

        cons_log.debug("Created a [2098]u8 connection buff", .{});
        const buf = try gpa.alloc(u8, 2098);
        defer {
            cons_log.debug("Dropped a [2098]u8 connection buff", .{});
            gpa.free(buf);
        }

        var http_server = http.Server.init(con, buf);

        var req = try http_server.receiveHead();
        cons_log.info("Received request from {}, target is: {s}", .{ con.address, req.head.target });

        if (router.routesMap.get(req.head.target)) |h| {
            try h(&req);
        } else {
            cons_log.info("No route matches: {s}", .{req.head.target});
            req.respond("Not Found", .{
                .keep_alive = false,
                .status = http.Status.not_found,
                .version = .@"HTTP/1.1",
            }) catch |err| {
                cons_log.info("An error occurred: {}", .{err});
            };
        }
    }
}

fn handle(req: *http.Server.Request) anyerror!void {
    const log = std.log.scoped(.handle_request_v1);

    log.info("Handling request with handler {}", .{@This()});
    log.info("I'M ALIVE ({s})", .{req.head.target});

    try req.respond("Hello", .{
        .keep_alive = true,
        .status = http.Status.ok,
        .version = .@"HTTP/1.1",
    });

    log.info("Sent response", .{});
    try req.respond("Hello", .{
        .keep_alive = true,
        .status = http.Status.ok,
        .version = .@"HTTP/1.1",
    });

    log.debug("Exiting handler {}", .{@This()});
    return;
}
