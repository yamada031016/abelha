const std = @import("std");
const ab = @import("abelha.zig");

const Result = ab.Result;
const tag = ab.bytes.tag;
const take = ab.bytes.take;
const separated_list1 = ab.multi.separated_list1;

fn parseHex(input: []const u8) !Result(u8) {
    const rest, const result = try take(2)(input);
    const hex = try std.fmt.parseInt(u8, result, 16);
    return .{ rest, hex };
}

fn hexColor(input: []const u8) !Result([]const u8) {
    return try ab.sequence.preceded(tag("#"), separated_list1(
        u8,
        tag(""),
        parseHex,
    ))(input);
}

test {
    const text = "#1A2B3C";
    _, const result = try hexColor(text);
    const answer = [_]u8{ 0x1a, 0x2b, 0x3c };
    try std.testing.expectEqualSlices(u8, &answer, result);
}

// Example of parsing color codes using Abelha
pub fn main() !void {
    const text = "#1A2B3C";
    _, const result = try hexColor(text);
    std.debug.print("{any}\n", .{result});
}
