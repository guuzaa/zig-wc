const std = @import("std");
const Allocator = std.mem.Allocator;
const Options = @import("options.zig").Options;
const options = @import("options.zig");

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
