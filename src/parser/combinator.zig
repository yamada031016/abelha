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

pub fn many1(parser: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            var result: []u8 = "";
            var rest_input = input;
            while (true) {
                const r = parser(rest_input);
                if (r) |res| {
                    result = std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}", .{ result, res.result }) catch |err| {
                        return err;
                    };
                    rest_input = res.rest;
                } else |e| {
                    if (result.len == 0) {
                        return e;
                    } else {
                        return IResult{ .rest = rest_input, .result = result };
                    }
                }
            }
        }
    }.parse;
}

test "many1 char" {
    const target = "### hogehoge";
    const result = try many1(char('#'))(target);
    try std.testing.expectEqualStrings("###", result.result);
}
