const std = @import("std");
const abelha = @import("parser.zig");

fn parseHex(input: []const u8) !abelha.ParseResult(u8) {
    const res = try abelha.take(2)(input);
    const hex = try std.fmt.parseInt(u8, res.result, 16);
    return abelha.ParseResult(u8){ .rest = res.rest, .result = hex };
}

fn hexColor(input: []const u8) !abelha.ParseResult([]const u8) {
    const result = try abelha.tag("#")(input);
    const res = try abelha.separated_list1(
        u8,
        abelha.tag(""),
        parseHex,
    )(result.rest);
    return res;
}

pub fn main() !void {
    const text = "#1A2B3C";
    const result = try hexColor(text);
    std.debug.print("{x}\n", .{result.result});
}
