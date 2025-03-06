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
        pub fn take(input: []const u8) !IResult {
            errdefer |e| ab.report(e, .{ @src().fn_name, cnt, input });

            if (input.len < cnt) {
                return error.InputTooShort;
            }
            return IResult{ .rest = input[cnt..], .result = input[0..cnt] };
        }
    }.take;
}

test take {
    const target = "abcdefg";
    const result = try take(3)(target);
    try std.testing.expectEqualStrings("abc", result.result);
}

pub fn take_till(comptime predicate: fn (val: u8) bool) ParserFunc {
    return struct {
        pub fn take_till(input: []const u8) !IResult {
            // errdefer |e| ab.report(e, .{ @src().fn_name, predicate, input });

            for (0..input.len) |i| {
                if (predicate(input[i])) {
                    return IResult{ .rest = input[i..], .result = input[0..i] };
                }
            }

            return IResult{ .rest = "", .result = input };
        }
    }.take_till;
}

test take_till {
    const target = "01-1111-1111";
    const result = try take_till(struct {
        fn lambda(val: u8) bool {
            return val == '-';
        }
    }.lambda)(target);
    try std.testing.expectEqualStrings("01", result.result);
}

pub fn take_till1(comptime predicate: fn (val: u8) bool) ParserFunc {
    return struct {
        pub fn take_till1(input: []const u8) !IResult {
            // errdefer |e| ab.report(e, .{ @src().fn_name, predicate, input });

            const result = try take_till(predicate)(input);

            if (result.result.len == 0) {
                return error.EmptyMatched;
            }

            return result;
        }
    }.take_till1;
}

test take_till1 {
    const target = "01-1111-1111";
    const result = try take_till1(struct {
        fn lambda(val: u8) bool {
            return val == '-';
        }
    }.lambda)(target);
    try std.testing.expectEqualStrings("01", result.result);

    const failed_result = take_till1(struct {
        fn lambda(val: u8) bool {
            return val == '-';
        }
    }.lambda)(result.rest);
    try std.testing.expectError(error.EmptyMatched, failed_result);
}

/// Returns a sequence of bytes as slices until the specified pattern is found.
pub fn take_until(end: []const u8) ParserFunc {
    return struct {
        pub fn take_until(input: []const u8) !IResult {
            errdefer |e| ab.report(e, .{ @src().fn_name, end, input });

            const index = std.mem.indexOf(u8, input, end);
            if (index) |idx| {
                return IResult{ .rest = input[idx..], .result = input[0..idx] };
            } else {
                return error.NotFound;
            }
        }
    }.take_until;
}

test take_until {
    const target = "hogehoge\n";
    const result = try take_until("\n")(target);
    try std.testing.expectEqualStrings("hogehoge", result.result);

    const invalid_target = "hogehoge";
    const failed_result = take_until("\n")(invalid_target);
    try std.testing.expectError(error.NotFound, failed_result);
}

/// Returns a sequence of bytes as slices until the specified pattern is found.
/// 'error.EmptyMatched' is returned when nothing is matched
pub fn take_until1(end: []const u8) ParserFunc {
    return struct {
        pub fn take_until1(input: []const u8) !IResult {
            errdefer |e| ab.report(e, .{ @src().fn_name, end, input });

            const result = try take_until(end)(input);

            if (result.result.len == 0) {
                return error.EmptyMatched;
            }

            return result;
        }
    }.take_until1;
}

test take_until1 {
    const target = "hogehoge\nhogehoge";
    const result = try take_until1("\n")(target);
    try std.testing.expectEqualStrings("hogehoge", result.result);

    const failed_result = take_until1("\n")(result.rest);
    try std.testing.expectError(error.EmptyMatched, failed_result);
}

/// Recognizes the pattern specified by the `needle` argument
/// The input is compared to see if it matches the pattern and the matching portion is returned.
/// If the size of the input is less than the size of the pattern, `error.NeedleTooShort` is returned.
/// `error.NotFound` is returned when no pattern is found.
pub export fn tag(needle: []const u8) ParserFunc {
    return struct {
        fn tag(input: []const u8) !IResult {
            errdefer |e| ab.report(e, .{ @src().fn_name, needle, input });

            if (input.len < needle.len) {
                return error.NeedleTooLong;
            }

            if (std.mem.eql(u8, input[0..needle.len], needle)) {
                return IResult{ .rest = input[needle.len..], .result = needle };
            } else {
                return error.NotFound;
            }
        }
    }.tag;
}

test tag {
    const target = "abcdefg";
    const result = try tag("abc")(target);
    try std.testing.expectEqualStrings("abc", result.result);
}

pub fn tag_ignore_case(needle: []const u8) ParserFunc {
    return struct {
        pub fn tag_ignore_case(input: []const u8) !IResult {
            errdefer |e| ab.report(e, .{ @src().fn_name, needle, input });

            if (input.len < needle.len) {
                return error.NeedleTooLong;
            }

            if (std.ascii.eqlIgnoreCase(input[0..needle.len], needle)) {
                return IResult{ .rest = input[needle.len..], .result = input[0..needle.len] };
            } else {
                return error.NotFound;
            }
        }
    }.tag_ignore_case;
}

test tag_ignore_case {
    const target = "AbCdEfG";
    const result = try tag_ignore_case("abc")(target);
    try std.testing.expectEqualStrings("AbC", result.result);
}

/// Matches a byte string with escaped characters.
pub fn escaped(normal: ParserFunc, escapable: ParserFunc) ParserFunc {
    return struct {
        pub fn escaped(input: []const u8) !IResult {
            // errdefer |e| ab.report(e, .{ @src().fn_name, .{ normal, escapable }, input });

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

/// Returns the longest slice of the matches the pattern.
pub fn is_a(pattern: []const u8) ParserFunc {
    return struct {
        pub fn is_a(input: []const u8) !IResult {
            errdefer |e| ab.report(e, .{ @src().fn_name, pattern, input });

            if (input.len == 0) {
                return error.InputTooShort;
            }

            var bitmask: [256]bool = [_]bool{false} ** 256;
            for (pattern) |p| {
                bitmask[p] = true;
            }

            var i: usize = 0;
            while (bitmask[input[i]]) : (i += 1) {}

            if (i == 0) {
                return error.NotFound;
            } else {
                return IResult{ .rest = input[i..], .result = input[0..i] };
            }
        }
    }.is_a;
}

test is_a {
    const target = "123 and 321";
    const result = try is_a("1234567890ABCDEF")(target);
    try std.testing.expectEqualStrings("123", result.result);

    const target2 = "DEBACFG";
    const result2 = try is_a("1234567890ABCDEF")(target2);
    try std.testing.expectEqualStrings("DEBACF", result2.result);
}

/// Returns a sequence of bytes as a slice until the specified character is found
pub fn is_not(needle: []const u8) ParserFunc {
    return struct {
        pub fn is_not(input: []const u8) !IResult {
            errdefer |e| ab.report(e, .{ @src().fn_name, needle, input });

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

test is_not {
    const target = "123 and 321";
    const result = try is_not(" \n\t\r")(target);
    try std.testing.expectEqualStrings("123", result.result);

    const target2 = "DEBACF";
    const result2 = try is_not(" \n\t\r")(target2);
    try std.testing.expectEqualStrings("DEBACF", result2.result);
}
