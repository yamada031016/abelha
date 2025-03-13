//! This module provides general purpose combinators.
const std = @import("std");
const ab = @import("../abelha.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;
const ParseResult = ab.ParseResult;

/// Recognizes that the input has reached the end of the line.
pub fn eof(input: []const u8) !IResult {
    if (input.len == 0) {
        return .{ "", "" };
    } else {
        return ParseError.NotFound;
    }
}

/// Reads ahead without consuming input whether the specified parser will succeed or not.
pub fn peek(parser: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            _, const result = try parser(input);
            return .{ input, result };
        }
    }.parse;
}

/// Succeeds if the child parser returns an error.
pub fn not(expect_fail_parser: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            if (expect_fail_parser(input)) |_| {
                return ParseError.NotFound;
            } else |e| {
                switch (e) {
                    else => return .{ input, "" },
                }
            }
        }
    }.parse;
}

/// Optional parser, returns the result of a successful parse or the input if it fails.
pub fn opt(opt_parser: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            if (opt_parser(input)) |res| {
                const rest, const result = res;
                return .{ rest, result };
            } else |e| {
                switch (e) {
                    else => return .{ input, "" },
                }
            }
        }
    }.parse;
}
