const std = @import("std");
const testing = std.testing;

/// Options for which counts to display
pub const Options = struct {
    show_lines: bool,
    show_words: bool,
    show_chars: bool,

    pub fn shouldShowAny(self: Options) bool {
        return self.show_lines or self.show_words or self.show_chars;
    }

    pub fn showAll() Options {
        return Options{
            .show_lines = true,
            .show_words = true,
            .show_chars = true,
        };
    }

    /// Parse options from a flag string like "-lwc"
    pub fn parseFlag(flag_str: []const u8) !Options {
        var opts = Options{
            .show_lines = false,
            .show_words = false,
            .show_chars = false,
        };

        if (flag_str.len == 0 or flag_str[0] != '-') {
            return error.InvalidFlag;
        }

        for (flag_str[1..]) |flag| {
            switch (flag) {
                'l' => opts.show_lines = true,
                'w' => opts.show_words = true,
                'c' => opts.show_chars = true,
                else => return error.InvalidOption,
            }
        }

        return opts;
    }
};

/// Print help information to stdout
pub fn printHelp() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(
        \\Usage: wc [OPTION]... [FILE]...
        \\Print newline, word, and byte counts for each FILE, and a total line if
        \\more than one FILE is specified. If no FILE is specified, read standard input.
        \\
        \\Options:
        \\  -c      print the byte counts
        \\  -l      print the newline counts
        \\  -w      print the word counts
        \\  -h, --help  display this help and exit
        \\
        \\With no options, print line, word, and byte counts.
        \\
    , .{});
}

test "Options.showAll returns all options enabled" {
    const options = Options.showAll();
    try testing.expect(options.show_lines);
    try testing.expect(options.show_words);
    try testing.expect(options.show_chars);
}

test "Options.shouldShowAny with all false returns false" {
    const options = Options{
        .show_lines = false,
        .show_words = false,
        .show_chars = false,
    };
    try testing.expect(!options.shouldShowAny());
}

test "Options.shouldShowAny with one true returns true" {
    {
        const options = Options{
            .show_lines = true,
            .show_words = false,
            .show_chars = false,
        };
        try testing.expect(options.shouldShowAny());
    }
    {
        const options = Options{
            .show_lines = false,
            .show_words = true,
            .show_chars = false,
        };
        try testing.expect(options.shouldShowAny());
    }
    {
        const options = Options{
            .show_lines = false,
            .show_words = false,
            .show_chars = true,
        };
        try testing.expect(options.shouldShowAny());
    }
}

test "Options.parseFlag handles invalid flag" {
    try testing.expectError(error.InvalidFlag, Options.parseFlag("lwc"));
}

test "Options.parseFlag parses valid flags" {
    {
        const options = try Options.parseFlag("-l");
        try testing.expect(options.show_lines);
        try testing.expect(!options.show_words);
        try testing.expect(!options.show_chars);
    }
    {
        const options = try Options.parseFlag("-w");
        try testing.expect(!options.show_lines);
        try testing.expect(options.show_words);
        try testing.expect(!options.show_chars);
    }
    {
        const options = try Options.parseFlag("-c");
        try testing.expect(!options.show_lines);
        try testing.expect(!options.show_words);
        try testing.expect(options.show_chars);
    }
}

test "Options.parseFlag parses combined flags" {
    {
        const options = try Options.parseFlag("-lw");
        try testing.expect(options.show_lines);
        try testing.expect(options.show_words);
        try testing.expect(!options.show_chars);
    }
    {
        const options = try Options.parseFlag("-lwc");
        try testing.expect(options.show_lines);
        try testing.expect(options.show_words);
        try testing.expect(options.show_chars);
    }
}

test "Options.parseFlag returns error for invalid options" {
    try testing.expectError(error.InvalidOption, Options.parseFlag("-lxc"));
}
