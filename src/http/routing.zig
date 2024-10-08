/// Handles url parssing and validation
const std = @import("std");
const ascii = std.ascii;
const http = std.http;

// ---
const testing = std.testing;
const logging = @import("../logging.zig");
// ---

const std_options = .{
    // Default log level info
    .log_level = .debug,
    .logFn = logging.logger,
};

const testing_log = std.log.scoped(.testing);

pub const HttpHandler = *const fn (req: *http.Server.Request) anyerror!void;
pub const RoutingTuple = struct { r: []const u8, h: HttpHandler };

pub fn Router() type {
    return struct {
        routesMap: std.StringArrayHashMap(HttpHandler),

        const Self = @This();

        pub fn init(
            alloc: std.mem.Allocator,
            comptime rts: []const RoutingTuple,
        ) !Self {
            testing_log.debug("Initializing router", .{});
            var self = Self{
                .routesMap = std.StringArrayHashMap(HttpHandler).init(alloc),
            };
            try self.populateRotes(rts);
            return self;
        }

        fn populateRotes(
            self: *Self,
            comptime rts: []const RoutingTuple,
        ) !void {
            testing_log.debug("Populatting router...", .{});
            inline for (rts) |route| {
                try self.routesMap.put(route.r, route.h);
                testing_log.info("Route Added -> {s}", .{route.r});
            }
        }

        pub fn deinit(self: *Self) void {
            testing_log.debug("Cleaning up routes", .{});
            self.routesMap.deinit();
        }
    };
}

const UrlMappingError = error{
    Invalid,
};

// --- TESTING

fn handle(_: *http.Server.Request) anyerror!void {
    return;
}

test "Create routting thing" {
    const routes = [_]RoutingTuple{.{ .route = "/", .handler = &handle }};
    var router = try Router().init(std.testing.allocator, &routes);
    defer router.deinit();

    const entrie = router.routesMap.get("/");
    try testing.expect(entrie != null);
}
