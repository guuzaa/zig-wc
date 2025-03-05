const std = @import("std");
const Allocator = std.mem.Allocator;
const cli = @import("cli");

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    return cli.run(allocator);
}
