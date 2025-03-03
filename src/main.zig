const std = @import("std");
const ab = @import("abelha.zig");

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
    const result = try ab.sequence.preceded(tag("#"), separated_list1(
        u8,
        tag(""),
        parseHex,
    ))(input);
    return result;
}

test {
    const text = "#1A2B3C";
    const result = try hexColor(text);
    const answer = [_]u8{ 0x1a, 0x2b, 0x3c };
    try std.testing.expectEqualSlices(u8, &answer, result.result);
}

// Example of parsing color codes using Abelha
pub fn main() !void {
    // const text = "#1A2B3C";
    const text = "aaaaccc";
    // const result = try hexColor(text);
    const result = try ab.branch.alt([]const u8, .{ hexColor, tag("aa") })(text);
    std.debug.print("{any}\n", .{result.result});
}
