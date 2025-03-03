//! This module provides combinators for bytes strings.
const std = @import("std");
const ab = @import("../abelha.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

/// Return `input[0..N]`, a slice of N bytes from the beginning of the input.
/// Return `error.InvalidFormat` when the size of input is less than N.
pub fn take(cnt: usize) ParserFunc {
    return struct {
        fn take(input: []const u8) !IResult {
            errdefer |e| ab.panic(e, .{ @src().fn_name, cnt, input });

            if (input.len < cnt) {
                return error.InputTooShort;
            }
            return IResult{ .rest = input[cnt..], .result = input[0..cnt] };
        }
    }.take;
}

/// Recognizes the pattern specified by the `needle` argument
/// The input is compared to see if it matches the pattern and the matching portion is returned.
/// If the size of the input is less than the size of the pattern, `error.NeedleTooShort` is returned.
/// `error.NotFound` is returned when no pattern is found.
pub fn tag(needle: []const u8) ParserFunc {
    return struct {
        fn tag(input: []const u8) !IResult {
            errdefer |e| ab.panic(e, .{ @src().fn_name, needle, input });

            if (input.len < needle.len) {
                std.log.debug("\ntarget string: {s}(len: {})\nneedle: {s}(len: {})\n", .{ input, input.len, needle, needle.len });
                return error.NeedleTooLong;
            } else {
                if (std.mem.eql(u8, input[0..needle.len], needle)) {
                    std.log.debug("successed.\ntarget string: {s}(len: {})\nneedle: {s}(len: {})\n", .{ input, input.len, needle, needle.len });
                    return IResult{ .rest = input[needle.len..], .result = needle };
                } else {
                    std.log.debug("\ntarget string: {s}\nneedle: {s}\n", .{ input, needle });
                    return error.NotFound;
                }
            }
        }
    }.tag;
}

/// Returns a sequence of bytes as slices until the specified pattern is found.
pub fn take_until(end: []const u8) ParserFunc {
    return struct {
        fn take_until(input: []const u8) !IResult {
            errdefer |e| ab.panic(e, .{ @src().fn_name, end, input });

            const index = std.mem.indexOf(u8, input, end);
            if (index) |idx| {
                return IResult{ .rest = input[idx..], .result = input[0..idx] };
            } else {
                return error.NotFound;
            }
        }
    }.take_until;
}

/// Returns a sequence of bytes as a slice until the specified character is found
pub fn is_not(needle: []const u8) ParserFunc {
    return struct {
        fn is_not(input: []const u8) !IResult {
            errdefer |e| ab.panic(e, .{ @src().fn_name, needle, input });

            if (input.len == 0) {
                return error.InputTooShort;
            }

            for (input, 0..) |c, i| {
                for (needle) |n| {
                    if (c == n) {
                        return IResult{ .rest = input[i..], .result = input[0..i] };
                    }
                }
            }
            return IResult{ .rest = "", .result = input };
        }
    }.is_not;
}

/// Returns a sequence of bytes as a slice until the specified character is found
pub fn escaped(normal: ParserFunc, escapable: ParserFunc) ParserFunc {
    return struct {
        fn escaped(input: []const u8) !IResult {
            // errdefer |e| ab.panic(e, .{ @src().fn_name, .{ normal, escapable }, input });

            const result = try normal(input);

            var escaped_str = std.ArrayList(u8).init(std.heap.page_allocator);
            try escaped_str.appendSlice(result.result);
            var rest = result.rest;

            while (escapable(rest)) |_result| {
                try escaped_str.appendSlice(_result.result);
                const res = try normal(_result.rest);
                try escaped_str.appendSlice(res.result);
                rest = res.rest;
            } else |_| {}

            return IResult{ .rest = rest, .result = try escaped_str.toOwnedSlice() };
        }
    }.escaped;
}

test escaped {
    const target = "ab\nab";
    var result = try escaped(tag("ab"), ab.character.char('\n'))(target);
    try std.testing.expectEqualStrings("ab\nab", result.result);

    const target2 = "abab";
    result = try escaped(tag("ab"), ab.character.char('\n'))(target2);
    try std.testing.expectEqualStrings("ab", result.result);
}
