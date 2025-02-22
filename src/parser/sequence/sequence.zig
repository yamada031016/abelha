const std = @import("std");
const ab = @import("../parser.zig");
const ParseResult = ab.ParseResult;
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

const tag = ab.bytes.tag;
const take_until = ab.bytes.take_until;

pub fn delimited(start: ParserFunc, content: ParserFunc, end: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            var result = try start(input);
            result = try content(result.rest);
            const text = result.result;
            result = try end(result.rest);
            return IResult{ .rest = result.rest, .result = text };
        }
    }.parse;
}

test "delimited" {
    const target = "<h1>";
    const result = try delimited(tag("<"), take_until(">"), tag(">"))(target);
    try std.testing.expectEqualStrings("h1", result.result);
}

pub fn preceded(first: ParserFunc, second: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            var result = try first(input);
            result = try second(result.rest);
            return IResult{ .rest = result.rest, .result = result.result };
        }
    }.parse;
}

// pub fn pair(T: type, first: ParserFunc, second: ParserFunc) fn ([]const u8) anyerror!ParseResult(T) {
//     return struct {
//         fn parse(input: []const u8) !IResult {
//             var result = try first(input);
//             result = try second(result.rest);
//             return ParseResult(T){ .rest = result.rest, .result = result.result };
//         }
//     }.parse;
// }
