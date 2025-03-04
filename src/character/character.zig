//! This module provides combinators for characters.
const std = @import("std");
const ab = @import("../abelha.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

const tag = ab.bytes.tag;
const many1 = ab.multi.many1;

/// Recognizes zero or more ASCII alphabetic characters regardless of Case
pub fn alpha0(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    var pos: usize = 0;
    for (0..input.len) |i| {
        if (!std.ascii.isAlphabetic(input[i])) {
            pos = i;
            break;
        }
    } else {
        // All inputs accepted.
        pos = input.len;
    }

    return IResult{ .rest = input[pos..], .result = input[0..pos] };
}

test alpha0 {
    const target = "abc123";
    const result = try alpha0(target);
    try std.testing.expectEqualStrings("abc", result.result);

    const empty_result = try alpha0(result.rest); // rest=123
    try std.testing.expectEqualStrings("", empty_result.result);
}

/// Recognizes ASCII alphabetic characters regardless of Case
pub fn alpha1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("alpha1", alpha0, input);
}

test alpha1 {
    const target = "abc123";
    const result = try alpha1(target);
    try std.testing.expectEqualStrings("abc", result.result);

    const failed_result = alpha1(result.rest); // rest=123
    try std.testing.expectError(error.EmptyMatched, failed_result);
}

/// Recognizes zero or more ASCII alphanumeric characters regardless of Case
pub fn alphanumeric0(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    var pos: usize = 0;
    for (0..input.len) |i| {
        if (!std.ascii.isAlphanumeric(input[i])) {
            pos = i;
            break;
        }
    } else {
        // All inputs accepted.
        pos = input.len;
    }

    return IResult{ .rest = input[pos..], .result = input[0..pos] };
}

test alphanumeric0 {
    const target = "123abc";
    const result = try alphanumeric0(target);
    try std.testing.expectEqualStrings("123abc", result.result);
}

/// Recognizes ASCII alphanumeric characters regardless of Case
pub fn alphanumeric1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("alphanumeric1", alphanumeric0, input);
}

test alphanumeric1 {
    const target = "123abc";
    const result = try alphanumeric1(target);
    try std.testing.expectEqualStrings("123abc", result.result);

    const failed_result = alphanumeric1(result.rest); // rest=""
    try std.testing.expectError(error.InputTooShort, failed_result);
}

/// Recognizes one any character
pub fn anychar(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    switch (input.len) {
        0 => return error.InputTooShort,
        1 => return IResult{ .rest = "", .result = input[0..1] },
        else => return IResult{ .rest = input[1..], .result = input[0..1] },
    }
}

test anychar {
    const target = "hoge";
    const result = try anychar(target);
    try std.testing.expectEqualStrings("h", result.result);
}

/// Recognizes zero or more binary characters: 0-1.
pub fn bin_digit0(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    var pos: usize = 0;
    for (0..input.len) |i| {
        switch (input[i]) {
            '0', '1' => {},
            else => {
                pos = i;
                break;
            },
        }
    } else {
        // All inputs accepted.
        pos = input.len;
    }

    return IResult{ .rest = input[pos..], .result = input[0..pos] };
}

test bin_digit0 {
    const target = "010101*101";
    const result = try bin_digit0(target);
    try std.testing.expectEqualStrings("010101", result.result);
}

/// Recognizes binary characters: 0-1.
pub fn bin_digit1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("bin_digit1", bin_digit0, input);
}

test bin_digit1 {
    const target = "010101*101";
    const result = try bin_digit1(target);
    try std.testing.expectEqualStrings("010101", result.result);
}

/// Recognizes specified characters
pub fn char(character: u8) ParserFunc {
    return struct {
        fn char(input: []const u8) !IResult {
            errdefer |e| ab.report(e, .{ @src().fn_name, &[_]u8{character}, input });

            switch (input.len) {
                0 => {},
                1 => {
                    if (input[0] == character) {
                        return IResult{ .rest = "", .result = input };
                    }
                },
                else => {
                    if (input[0] == character) {
                        return IResult{ .rest = input[1..], .result = input[0..1] };
                    }
                },
            }
            return error.NotFound;
        }
    }.char;
}

test char {
    const target = "#hogehoge";
    const result = try char('#')(target);
    try std.testing.expectEqualStrings("#", result.result);
}

/// Recognizes one or more specified hexadecimal numbers
pub fn crlf(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    return try tag("\r\n")(input);
}

test crlf {
    const target = "\r\nnewline";
    const result = try crlf(target);
    try std.testing.expectEqualStrings("\r\n", result.result);

    const failed_result = crlf(result.rest); // rest=newline
    try std.testing.expectError(error.NotFound, failed_result);
}

/// Recognizes zero or more ASCII numerical characters.
pub fn digit0(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    var pos: usize = 0;
    for (0..input.len) |i| {
        if (!std.ascii.isDigit(input[i])) {
            pos = i;
            break;
        }
    } else {
        // All inputs accepted.
        pos = input.len;
    }

    return IResult{ .rest = input[pos..], .result = input[0..pos] };
}

test digit0 {
    const target = "123abc";
    const result = try digit0(target);
    try std.testing.expectEqualStrings("123", result.result);

    const empty_result = try digit0(result.rest); // rest=abc
    try std.testing.expectEqualStrings("", empty_result.result);
}

/// Recognizes ASCII numerical characters.
pub fn digit1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("digit1", digit0, input);
}

test digit1 {
    const target = "123abc";
    const result = try digit1(target);
    try std.testing.expectEqualStrings("123", result.result);

    const failed_result = digit1(result.rest); // rest=abc
    try std.testing.expectError(error.EmptyMatched, failed_result);
}

/// Recognizes zero or more specified hexadecimal numbers
pub fn hexDigit0(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    var pos: usize = 0;
    for (0..input.len) |i| {
        if (!std.ascii.isHex(input[i])) {
            pos = i;
            break;
        }
    } else {
        // All inputs accepted.
        pos = input.len;
    }

    return IResult{ .rest = input[pos..], .result = input[0..pos] };
}

test hexDigit0 {
    const target = "123aBcG";
    const result = try hexDigit0(target);
    try std.testing.expectEqualStrings("123aBc", result.result);

    const empty_result = try hexDigit0(result.rest); // rest=G
    try std.testing.expectEqualStrings("", empty_result.result);
}

/// Recognizes zero or more specified hexadecimal numbers
pub fn hexDigit1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("hexDigit1", hexDigit0, input);
}

test hexDigit1 {
    const target = "123aBcG";
    const result = try hexDigit1(target);
    try std.testing.expectEqualStrings("123aBc", result.result);

    const failed_result = hexDigit1(result.rest); // rest=G
    try std.testing.expectError(error.EmptyMatched, failed_result);
}

/// Recognizes `\n`.
pub fn newline(input: []const u8) !IResult {
    if (char('\n')(input)) |result| {
        return IResult{ .rest = result.rest, .result = result.result };
    } else |e| {
        return e;
    }
}

/// Recognizes both `\n` and `\r\n`.
pub fn line_ending(input: []const u8) !IResult {
    if (char('\n')(input)) |result| {
        return IResult{ .rest = result.rest, .result = result.result };
    } else |e| {
        switch (e) {
            error.NotFound => {
                const result = try tag("\r\n")(input);
                return IResult{ .rest = result.rest, .result = result.result };
            },
            else => return e,
        }
    }
}

// Recognizes one or more spaces and tabs.
pub fn space1(input: []const u8) !IResult {
    const result = try many1(char(' '))(input);
    return IResult{ .rest = result.rest, .result = try std.mem.concat(std.heap.page_allocator, u8, result.result) };
}
