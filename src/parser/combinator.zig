const std = @import("std");
const ab = @import("parser.zig");
const ParseResult = ab.ParseResult;
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

const char = ab.basic.char;
const tag = ab.basic.tag;
const take_until = ab.basic.take_until;

pub fn alt(T: type, parser_tupple: anytype) fn ([]const u8) anyerror!ParseResult(T) {
    return struct {
        fn parse(input: []const u8) !ParseResult(T) {
            inline for (parser_tupple) |parser| {
                const result = parser(input);
                if (result) |res| {
                    return ParseResult(T){ .rest = res.rest, .result = res.result };
                } else |e| {
                    // ignore error
                    switch (e) {
                        else => {},
                    }
                }
            } else {
                return ParseError.NotFound;
            }
        }
    }.parse;
}

test "alt" {
    const target = "*italic*\n";
    const result = try alt([]const u8, .{ char('\n'), tag("**"), take_until("</p>"), take_until("\n"), char('#') })(target);
    try std.testing.expectEqualStrings("*italic*", result.result);
}

pub fn many1(parser: ParserFunc) fn ([]const u8) anyerror!ParseResult([]const []const u8) {
    return struct {
        fn parse(input: []const u8) !ParseResult([]const []const u8) {
            var array = std.ArrayList([]const u8).init(std.heap.page_allocator);
            var rest_input = input;
            while (true) {
                const r = parser(rest_input);
                if (r) |res| {
                    array.append(res.result) catch |err| {
                        return err;
                    };
                    if (res.rest.len == 0) {
                        return ParseResult([]const []const u8){ .rest = res.rest, .result = try array.toOwnedSlice() };
                    } else {
                        rest_input = res.rest;
                    }
                } else |e| {
                    // if (array.getLastOrNull()) |_| {
                    //     return ParseResult([]const []const u8){ .rest = rest_input, .result = try array.toOwnedSlice() };
                    // } else {
                    return e;
                    // }
                }
            }
        }
    }.parse;
}

test "many1 char" {
    const target = "### hogehoge";
    const result = try many1(char('#'))(target);
    try std.testing.expectEqual(3, result.result.len);
    try std.testing.expectEqualStrings("###", try std.mem.concat(std.heap.page_allocator, u8, result.result));
}
