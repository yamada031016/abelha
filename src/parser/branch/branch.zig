//! This module provides Choice combinators.
const std = @import("std");
const ab = @import("../parser.zig");
const ParseResult = ab.ParseResult;
const ParseError = ab.ParseError;

const char = ab.character.char;
const tag = ab.bytes.tag;
const take_until = ab.bytes.take_until;

/// Try the parsers given in Tuple one by one in turn until success.
/// Returns the first successful parse result, or `ParseError.NotFound` if all fail
pub fn alt(T: type, parser_tuple: anytype) fn ([]const u8) anyerror!ParseResult(T) {
    return struct {
        fn parse(input: []const u8) !ParseResult(T) {
            inline for (parser_tuple) |parser| {
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

test alt {
    const target = "*italic*\n";
    // take_until("\n") succeeds.
    const result = try alt([]const u8, .{ char('\n'), tag("**"), take_until("</p>"), take_until("\n"), char('#') })(target);
    try std.testing.expectEqualStrings("*italic*", result.result);
}

// pub fn permutation(T: type, parser_tupple: anytype) fn ([]const u8) anyerror!ParseResult(T) {
//     return struct {
//         fn parse(input: []const u8) !ParseResult(T) {
//             inline for (parser_tupple) |parser| {
//                 const result = parser(input);
//                 if (result) |res| {
//                     return ParseResult(T){ .rest = res.rest, .result = res.result };
//                 } else |e| {
//                     // ignore error
//                     switch (e) {
//                         else => {},
//                     }
//                 }
//             } else {
//                 return ParseError.NotFound;
//             }
//         }
//     }.parse;
// }
//
// test "permutation" {
//     const target = "*italic*\n";
//     const result = try alt([]const u8, .{ char('\n'), tag("**"), take_until("</p>"), take_until("\n"), char('#') })(target);
//     try std.testing.expectEqualStrings("*italic*", result.result);
// }
