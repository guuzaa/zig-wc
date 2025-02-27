const std = @import("std");
const Allocator = std.mem.Allocator;
const Counter = @import("counter.zig").Counter;
const Options = @import("options.zig").Options;
const formatter = @import("formatter.zig");
const cli = @import("cli.zig");

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    var parsed_args = cli.parseArgs(allocator) catch |err| {
        // If help was requested, exit successfully
        if (err == error.HelpRequested) {
            return 0;
        }
        // For expected errors, exit with error code but don't show stack trace
        if (err == error.InvalidOption or err == error.InvalidFlag) {
            return 1;
        }
        // For unexpected errors, propagate them
        return err;
    };
    defer parsed_args.deinit();

    // Process files or stdin
    var total = Counter.init();
    var file_processed = false;

    // If no files provided, read from stdin
    if (parsed_args.paths.items.len == 0) {
        const counts = try Counter.countFromStream(std.io.getStdIn().reader());
        try formatter.printCounts(counts, "stdin", parsed_args.options);
        total.add(counts);
        file_processed = true;
    } else {
        // Process each file
        for (parsed_args.paths.items) |path| {
            const file = std.fs.cwd().openFile(path, .{}) catch |err| {
                const stderr = std.io.getStdErr().writer();
                try stderr.print("wc: {s}: {s}\n", .{ path, @errorName(err) });
                continue;
            };
            defer file.close();

            const counts = try Counter.countFromStream(file.reader());
            try formatter.printCounts(counts, path, parsed_args.options);
            total.add(counts);
            file_processed = true;
        }
    }

    // Print totals if more than one file was processed
    if (parsed_args.paths.items.len > 1 and file_processed) {
        try formatter.printCounts(total, "total", parsed_args.options);
    }

    return 0;
}
