//! This module provides combinators for bytes strings.
const std = @import("std");
const ab = @import("../abelha.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

/// Return `input[0..N]`, a slice of N bytes from the beginning of the input.
/// Return `ParseError.InvalidFormat` when the size of input is less than N.
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
/// If the size of the input is less than the size of the pattern, `ParseError.NeedleTooShort` is returned.
/// `ParseError.NotFound` is returned when no pattern is found.
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
        fn parse(input: []const u8) !IResult {
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
    }.parse;
}
