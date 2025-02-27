const std = @import("std");
const testing = std.testing;

/// Struct to keep track of counts for lines, words, and characters
pub const Counter = struct {
    lines: usize,
    words: usize,
    chars: usize,

    pub fn init() Counter {
        return Counter{
            .lines = 0,
            .words = 0,
            .chars = 0,
        };
    }

    pub fn add(self: *Counter, other: Counter) void {
        self.lines += other.lines;
        self.words += other.words;
        self.chars += other.chars;
    }

    /// Count lines, words, and chars from a stream
    pub fn countFromStream(
        reader: anytype,
    ) !Counter {
        var counts = Counter.init();
        var in_word = false;

        // Buffer for reading
        var buf: [8192]u8 = undefined;

        while (true) {
            const bytes_read = try reader.read(&buf);
            if (bytes_read == 0) break;

            counts.chars += bytes_read;

            for (buf[0..bytes_read]) |c| {
                if (c == '\n') {
                    counts.lines += 1;
                }

                if (std.ascii.isWhitespace(c)) {
                    if (in_word) {
                        in_word = false;
                    }
                } else {
                    if (!in_word) {
                        in_word = true;
                        counts.words += 1;
                    }
                }
            }
        }

        return counts;
    }
};

test "Counter.init creates zeroed counter" {
    const counter = Counter.init();
    try testing.expectEqual(@as(usize, 0), counter.lines);
    try testing.expectEqual(@as(usize, 0), counter.words);
    try testing.expectEqual(@as(usize, 0), counter.chars);
}

test "Counter.add combines counters" {
    var counter1 = Counter{ .lines = 5, .words = 20, .chars = 100 };
    const counter2 = Counter{ .lines = 3, .words = 15, .chars = 75 };

    counter1.add(counter2);

    try testing.expectEqual(@as(usize, 8), counter1.lines);
    try testing.expectEqual(@as(usize, 35), counter1.words);
    try testing.expectEqual(@as(usize, 175), counter1.chars);
}

test "countFromStream counts empty string" {
    var buffer = [_]u8{};
    var fbs = std.io.fixedBufferStream(&buffer);

    const counter = try Counter.countFromStream(fbs.reader());

    try testing.expectEqual(@as(usize, 0), counter.lines);
    try testing.expectEqual(@as(usize, 0), counter.words);
    try testing.expectEqual(@as(usize, 0), counter.chars);
}

test "countFromStream counts single word" {
    var buffer = "hello".*;
    var fbs = std.io.fixedBufferStream(&buffer);

    const counter = try Counter.countFromStream(fbs.reader());

    try testing.expectEqual(@as(usize, 0), counter.lines);
    try testing.expectEqual(@as(usize, 1), counter.words);
    try testing.expectEqual(@as(usize, 5), counter.chars);
}

test "countFromStream counts multiple words" {
    var buffer = "hello world".*;
    var fbs = std.io.fixedBufferStream(&buffer);

    const counter = try Counter.countFromStream(fbs.reader());

    try testing.expectEqual(@as(usize, 0), counter.lines);
    try testing.expectEqual(@as(usize, 2), counter.words);
    try testing.expectEqual(@as(usize, 11), counter.chars);
}

test "countFromStream counts lines" {
    var buffer = "hello\nworld\n".*;
    var fbs = std.io.fixedBufferStream(&buffer);

    const counter = try Counter.countFromStream(fbs.reader());

    try testing.expectEqual(@as(usize, 2), counter.lines);
    try testing.expectEqual(@as(usize, 2), counter.words);
    try testing.expectEqual(@as(usize, 12), counter.chars);
}

test "countFromStream handles multiple whitespace" {
    var buffer = "  hello   world  \n".*;
    var fbs = std.io.fixedBufferStream(&buffer);

    const counter = try Counter.countFromStream(fbs.reader());

    try testing.expectEqual(@as(usize, 1), counter.lines);
    try testing.expectEqual(@as(usize, 2), counter.words);
    try testing.expectEqual(@as(usize, 18), counter.chars);
}
