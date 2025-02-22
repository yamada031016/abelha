const std = @import("std");
const ab = @import("../parser.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;
const ParseResult = ab.ParseResult;

pub fn eof(input: []const u8) !IResult {
    if (input.len == 0) {
        return IResult{ .rest = "", .result = "" };
    } else {
        return ParseError.NotFound;
    }
}

pub fn peek(parser: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            const result = try parser(input);
            return IResult{ .rest = input, .result = result.result };
        }
    }.parse;
}

pub fn not(expect_fail_parser: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            const result = expect_fail_parser(input);
            if (result) |_| {
                return ParseError.NotFound;
            } else |e| {
                switch (e) {
                    else => return IResult{ .rest = input, .result = "" },
                }
            }
        }
    }.parse;
}

pub fn opt(opt_parser: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            const result = opt_parser(input);
            if (result) |res| {
                return IResult{ .rest = res.rest, .result = res.result };
            } else |e| {
                switch (e) {
                    else => return IResult{ .rest = input, .result = "" },
                }
            }
        }
    }.parse;
}
