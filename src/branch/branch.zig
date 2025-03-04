//! This module provides Choice combinators.
const std = @import("std");
const ab = @import("../abelha.zig");
const ParseResult = ab.ParseResult;

const char = ab.character.char;
const tag = ab.bytes.tag;
const take_until = ab.bytes.take_until;

/// Try the parsers given in Tuple one by one in turn until success.
/// Returns the first successful parse result, or `ParseError.NotFound` if all fail
pub fn alt(T: type, parser_tuple: anytype) fn ([]const u8) anyerror!ParseResult(T) {
    return struct {
        fn alt(input: []const u8) !ParseResult(T) {
            inline for (parser_tuple) |parser| {
                if (parser(input)) |result| {
                    return ParseResult(T){ .rest = result.rest, .result = result.result };
                } else |e| {
                    // ignore error
                    switch (e) {
                        else => {},
                    }
                }
            } else {
                return error.NotFound;
            }
        }
    }.alt;
}

test alt {
    const target = "*italic*\n";
    // take_until("\n") succeeds.
    const result = try alt([]const u8, .{ char('\n'), tag("**"), take_until("</p>"), take_until("\n"), char('#') })(target);
    try std.testing.expectEqualStrings("*italic*", result.result);
}

/// The parser groups of arguments are applied in order, and if all do not result in success, an error is returned.
pub fn permutation(T: type, parser_tupple: anytype) fn ([]const u8) anyerror!ParseResult([]const T) {
    return struct {
        fn permutation(input: []const u8) !ParseResult([]const T) {
            errdefer |e| ab.panic(e, .{ @src().fn_name, "", input });

            var array = std.ArrayList([]const u8).init(std.heap.page_allocator);
            var rest = input;
            inline for (parser_tupple) |parser| {
                const _result = try parser(rest);
                try array.append(_result.result);
                rest = _result.rest;
            }

            const result = try array.toOwnedSlice();
            if (result.len == 0) {
                return error.NotFound;
            }

            return ParseResult([]const T){ .rest = rest, .result = result };
        }
    }.permutation;
}

test permutation {
    const target = "*italic*\n";
    const result = try permutation([]const u8, .{ tag("*"), take_until("*"), char('*') })(target);
    try std.testing.expectEqualStrings("*italic*", try std.mem.concat(std.heap.page_allocator, u8, result.result));
}
