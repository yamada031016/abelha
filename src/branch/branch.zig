//! This module provides Choice combinators.
const std = @import("std");
const ab = @import("../abelha.zig");
const ParseResult = ab.ParseResult;

const char = ab.character.char;
const tag = ab.bytes.tag;
const take_until = ab.bytes.take_until;

/// Try the parsers given in Tuple one by one in turn until success.
/// Returns the first successful parse result, or `ParseError.NotFound` if all fail
pub fn alt(T: type, parser_tuple: anytype) fn ([]const u8) anyerror!ab.Result(T) {
    return struct {
        fn alt(input: []const u8) !ab.Result(T) {
            inline for (parser_tuple) |parser| {
                if (parser(input)) |value| {
                    const rest, const result = value;
                    return ab.Result(T){ rest, result };
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
    _, const result = try alt([]const u8, .{ char('\n'), tag("**"), take_until("</p>"), take_until("\n"), char('#') })(target);
    try std.testing.expectEqualStrings("*italic*", result);
}

/// The parser groups of arguments are applied in order, and if all do not result in success, an error is returned.
pub fn permutation(T: type, parser_tupple: anytype) fn ([]const u8) anyerror!ab.Result([]const T) {
    return struct {
        fn permutation(input: []const u8) !ab.Result([]const T) {
            // errdefer |e| ab.report(e, .{ @src().fn_name, parser_tupple, input });

            var array = std.ArrayList([]const u8).init(std.heap.page_allocator);
            var rest = input;
            inline for (parser_tupple) |parser| {
                rest, const result = try parser(rest);
                try array.append(result);
            }

            const result = try array.toOwnedSlice();
            if (result.len == 0) {
                return error.NotFound;
            }

            return ab.Result([]const T){ rest, result };
        }
    }.permutation;
}

test permutation {
    const target = "*italic*\n";
    _, const result = try permutation([]const u8, .{ tag("*"), take_until("*"), char('*') })(target);
    try std.testing.expectEqualStrings("*italic*", try std.mem.concat(std.heap.page_allocator, u8, result));
}
