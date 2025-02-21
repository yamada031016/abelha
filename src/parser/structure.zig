const std = @import("std");
const ab = @import("parser.zig");
const ParserFunc = ab.ParserFunc;
const ParseResult = ab.ParseResult;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

const tag = ab.basic.tag;
const take_until = ab.basic.take_until;

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

// pub fn pair(T: type, first: ParserFunc, second: ParserFunc) fn ([]const u8) anyerror!ParseResult(T) {
//     return struct {
//         fn parse(input: []const u8) !IResult {
//             var result = try first(input);
//             result = try second(result.rest);
//             return ParseResult(T){ .rest = result.rest, .result = result.result };
//         }
//     }.parse;
// }

pub fn preceded(first: ParserFunc, second: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            var result = try first(input);
            result = try second(result.rest);
            return IResult{ .rest = result.rest, .result = result.result };
        }
    }.parse;
}

pub fn separated_list1(T: type, seq: anytype, parser: anytype) fn ([]const u8) anyerror!ParseResult([]const T) {
    return struct {
        fn parse(input: []const u8) !ParseResult([]const T) {
            var results = std.ArrayList(T).init(std.heap.page_allocator);
            var rest_input = input;
            while (parser(rest_input)) |result| {
                try results.append(result.result);
                const res = seq(result.rest) catch {
                    return ParseResult([]const T){ .rest = result.rest, .result = results.items };
                };
                rest_input = res.rest;
            } else |e| {
                if (results.items.len == 0) {
                    return e;
                } else {
                    return ParseResult([]const T){ .rest = rest_input, .result = results.items };
                }
            }
        }
    }.parse;
}

test "separated_list1" {
    const text = "abc|abc|abc";
    const result = try separated_list1(tag("|"), tag("abc"))(text);
    const answer = [_][]const u8{ "abc", "abc", "abc" };
    try std.testing.expectEqualSlices([]const u8, &answer, result.result.items);
}
