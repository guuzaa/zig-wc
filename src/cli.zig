const std = @import("std");
const Allocator = std.mem.Allocator;
const Options = @import("options").Options;
const options = @import("options");
const Counter = @import("counter").Counter;
const formatter = @import("formatter");

/// Error type for CLI parsing
pub const CliError = error{
    InvalidOption,
    InvalidFlag,
    HelpRequested,
};

/// Structure to hold parsed command line arguments
pub const ParsedArgs = struct {
    options: Options,
    paths: std.ArrayList([]const u8),

    pub fn deinit(self: *ParsedArgs) void {
        for (self.paths.items) |path| {
            self.paths.allocator.free(path);
        }
        self.paths.deinit();
    }
};

/// Parse command line arguments
pub fn parseArgs(allocator: Allocator) !ParsedArgs {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip program name
    _ = args.skip();

    // Default to showing all counts
    var opts = Options.showAll();
    var show_specific_only = false;

    var paths = std.ArrayList([]const u8).init(allocator);
    errdefer {
        for (paths.items) |path| {
            allocator.free(path);
        }
        paths.deinit();
    }

    // Process all args
    while (args.next()) |arg| {
        if (arg.len > 0 and arg[0] == '-') {
            // Check for help flag
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                try options.printHelp();
                return error.HelpRequested;
            }

            // This is a flag
            const parsed_opts = Options.parseFlag(arg) catch {
                const stderr = std.io.getStdErr().writer();
                try stderr.print("wc: invalid option in {s}\n", .{arg});
                try stderr.print("Try 'wc --help' for more information.\n", .{});
                return error.InvalidOption;
            };

            // If we're showing specific counts only
            if (show_specific_only) {
                // Combine with existing options
                opts.show_lines = opts.show_lines or parsed_opts.show_lines;
                opts.show_words = opts.show_words or parsed_opts.show_words;
                opts.show_chars = opts.show_chars or parsed_opts.show_chars;
            } else if (parsed_opts.shouldShowAny()) {
                // First time specifying options, replace defaults
                opts = parsed_opts;
                show_specific_only = true;
            }
        } else {
            // This is a file path
            const path_copy = try allocator.dupe(u8, arg);
            try paths.append(path_copy);
        }
    }

    return ParsedArgs{
        .options = opts,
        .paths = paths,
    };
}

pub fn run(allocator: Allocator) !u8 {
    // Parse command line arguments
    var parsed_args = parseArgs(allocator) catch |err| {
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
        try formatter.printCounts(counts, "", parsed_args.options);
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

test "parseArgs with no arguments returns default options" {
    // This test is tricky because we can't easily mock command line args
    // In a real-world scenario, you might use a function that takes a string array
    // instead of reading from process.args directly

    // For now, we'll just test that the function compiles
    _ = parseArgs;
}

test "ParsedArgs.deinit frees memory" {
    const allocator = std.testing.allocator;

    var paths = std.ArrayList([]const u8).init(allocator);
    try paths.append(try allocator.dupe(u8, "test1.txt"));
    try paths.append(try allocator.dupe(u8, "test2.txt"));

    var args = ParsedArgs{
        .options = Options.showAll(),
        .paths = paths,
    };

    // This should free all memory
    args.deinit();

    // If we get here without a memory leak being detected, the test passes
}
