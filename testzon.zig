const std = @import("std");
const DuckDb = @import("duck");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};

    {
        var allocator = gpa.allocator();

        // setup database
        var duck = try DuckDb.init(null);
        defer duck.deinit();

        var result = try duck.queryResult("select * from pragma_version();");
        defer duck.freeResult(&result);
        var version = try duck.value(allocator, &result, 0, 0);
        defer allocator.free(version);

        std.debug.print("Database version is {s}\n", .{version});
    }

    // all defers should have run by now
    std.debug.print("\n\nSTOPPED!\n\n", .{});
    // we'll arrive here after zap.stop()
    const leaked = gpa.detectLeaks();
    std.debug.print("Leaks detected: {}\n", .{leaked});
}
