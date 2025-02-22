const std = @import("std");
const ab = @import("parser/parser.zig");

const ParseResult = ab.ParseResult;
const tag = ab.bytes.tag;
const take = ab.bytes.take;
const separated_list1 = ab.multi.separated_list1;

fn parseHex(input: []const u8) !ParseResult(u8) {
    const res = try take(2)(input);
    const hex = try std.fmt.parseInt(u8, res.result, 16);
    return ParseResult(u8){ .rest = res.rest, .result = hex };
}

fn hexColor(input: []const u8) !ParseResult([]const u8) {
    const result = try tag("#")(input);
    const res = try separated_list1(
        u8,
        tag(""),
        parseHex,
    )(result.rest);
    return res;
}

pub fn main() !void {
    const text = "#1A2B3C";
    const result = try hexColor(text);
    std.debug.print("{x}\n", .{result.result});
}
