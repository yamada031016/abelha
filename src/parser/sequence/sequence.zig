const std = @import("std");
const ab = @import("../parser.zig");
const ParseResult = ab.ParseResult;
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

const tag = ab.bytes.tag;
const take_until = ab.bytes.take_until;

/// Discard elements recognized by the parser `start`, then get elements recognized by the parser `content`, and finally discard elements recognized by the parser `end`.
/// - `start` The first parser to apply and discard.
/// - `content` The second parser to apply.
/// - `end` The third parser to apply and discard.
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

test delimited {
    const target = "<h1>";
    const result = try delimited(tag("<"), take_until(">"), tag(">"))(target);
    try std.testing.expectEqualStrings("h1", result.result);
}

/// Discard elements recognized by the parser `first` and return the next element recognized by the parser `second` as the result.
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
