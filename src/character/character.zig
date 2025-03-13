//! This module provides combinators for characters.
const std = @import("std");
const ab = @import("../abelha.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;
const ParseResult = ab.ParseResult;

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

    return .{ input[pos..], input[0..pos] };
}

test alpha0 {
    const target = "abc123";
    const rest, var result = try alpha0(target);
    try std.testing.expectEqualStrings("abc", result);

    _, result = try alpha0(rest); // rest=123
    try std.testing.expectEqualStrings("", result);
}

/// Recognizes ASCII alphabetic characters regardless of Case
pub fn alpha1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("alpha1", alpha0, input);
}

test alpha1 {
    const target = "abc123";
    const rest, const result = try alpha1(target);
    try std.testing.expectEqualStrings("abc", result);

    const failed = alpha1(rest); // rest=123
    try std.testing.expectError(error.EmptyMatched, failed);
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

    return .{ input[pos..], input[0..pos] };
}

test alphanumeric0 {
    const target = "123abc";
    _, const result = try alphanumeric0(target);
    try std.testing.expectEqualStrings("123abc", result);
}

/// Recognizes ASCII alphanumeric characters regardless of Case
pub fn alphanumeric1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("alphanumeric1", alphanumeric0, input);
}

test alphanumeric1 {
    const target = "123abc";
    const rest, const result = try alphanumeric1(target);
    try std.testing.expectEqualStrings("123abc", result);

    const failed = alphanumeric1(rest); // rest=""
    try std.testing.expectError(error.InputTooShort, failed);
}

/// Recognizes one any character
pub fn anychar(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    switch (input.len) {
        0 => return error.InputTooShort,
        1 => return .{ "", input[0..1] },
        else => return .{ input[1..], input[0..1] },
    }
}

test anychar {
    const target = "hoge";
    _, const result = try anychar(target);
    try std.testing.expectEqualStrings("h", result);
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

    return .{ input[pos..], input[0..pos] };
}

test bin_digit0 {
    const target = "010101*101";
    _, const result = try bin_digit0(target);
    try std.testing.expectEqualStrings("010101", result);
}

/// Recognizes binary characters: 0-1.
pub fn bin_digit1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("bin_digit1", bin_digit0, input);
}

test bin_digit1 {
    const target = "010101*101";
    _, const result = try bin_digit1(target);
    try std.testing.expectEqualStrings("010101", result);
}

/// Recognizes specified characters
pub fn char(character: u8) ParserFunc {
    return struct {
        pub fn char(input: []const u8) !IResult {
            errdefer |e| ab.report(e, .{ @src().fn_name, &[_]u8{character}, input });

            switch (input.len) {
                0 => {},
                1 => {
                    if (input[0] == character) {
                        return .{ "", input };
                    }
                },
                else => {
                    if (input[0] == character) {
                        return .{ input[1..], input[0..1] };
                    }
                },
            }
            return error.NotFound;
        }
    }.char;
}

test char {
    const target = "#hogehoge";
    _, const result = try char('#')(target);
    try std.testing.expectEqualStrings("#", result);
}

/// Recognizes one or more specified hexadecimal numbers
pub fn crlf(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    return try tag("\r\n")(input);
}

test crlf {
    const target = "\r\nnewline";
    const rest, const result = try crlf(target);
    try std.testing.expectEqualStrings("\r\n", result);

    const failed = crlf(rest); // rest=newline
    try std.testing.expectError(error.NotFound, failed);
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

    return .{ input[pos..], input[0..pos] };
}

test digit0 {
    const target = "123abc";
    const rest, var result = try digit0(target);
    try std.testing.expectEqualStrings("123", result);

    _, result = try digit0(rest); // rest=abc
    try std.testing.expectEqualStrings("", result);
}

/// Recognizes ASCII numerical characters.
pub fn digit1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("digit1", digit0, input);
}

test digit1 {
    const target = "123abc";
    const rest, const result = try digit1(target);
    try std.testing.expectEqualStrings("123", result);

    const failed = digit1(rest); // rest=abc
    try std.testing.expectError(error.EmptyMatched, failed);
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

    return .{ input[pos..], input[0..pos] };
}

test hexDigit0 {
    const target = "123aBcG";
    const rest, var result = try hexDigit0(target);
    try std.testing.expectEqualStrings("123aBc", result);

    _, result = try hexDigit0(rest); // rest=G
    try std.testing.expectEqualStrings("", result);
}

/// Recognizes zero or more specified hexadecimal numbers
pub fn hexDigit1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("hexDigit1", hexDigit0, input);
}

test hexDigit1 {
    const target = "123aBcG";
    const rest, const result = try hexDigit1(target);
    try std.testing.expectEqualStrings("123aBc", result);

    const failed_result = hexDigit1(rest); // rest=G
    try std.testing.expectError(error.EmptyMatched, failed_result);
}

/// Recognizes zero or more specified oxtal numbers
pub fn octDigit0(input: []const u8) !IResult {
    errdefer |e| ab.report(e, .{ @src().fn_name, .{}, input });

    var pos: usize = 0;
    for (0..input.len) |i| {
        const isOct = switch (input[i]) {
            '0'...'7' => true,
            else => false,
        };
        if (!isOct) {
            pos = i;
            break;
        }
    } else {
        // All inputs accepted.
        pos = input.len;
    }

    return .{ input[pos..], input[0..pos] };
}

test octDigit0 {
    const target = "12345678";
    const rest, var result = try octDigit0(target);
    try std.testing.expectEqualStrings("1234567", result);

    _, result = try octDigit0(rest); // rest=8
    try std.testing.expectEqualStrings("", result);
}

/// Recognizes zero or more specified oxtal numbers
pub fn octDigit1(input: []const u8) !IResult {
    return try ab.prohibitEmptyResult("octDigit1", octDigit0, input);
}

test octDigit1 {
    const target = "12345678";
    const rest, const result = try octDigit1(target);
    try std.testing.expectEqualStrings("1234567", result);

    const failed_result = octDigit1(rest); // rest=8
    try std.testing.expectError(error.EmptyMatched, failed_result);
}

fn parseNumber(comptime T: type, input: []const u8) !ab.Result(T) {
    errdefer |e| ab.report(e, .{ @src().fn_name, T, input });

    if (input.len == 0) return error.InputTooShort;

    var i: usize = 0;
    var result: T = 0;
    var base: u8 = 10;
    var is_negative = false;

    switch (input[i]) {
        '-' => {
            if (std.math.minInt(T) == 0) {
                // T is unsigned integar type.
                return error.InvalidArgument;
            }
            is_negative = true;
            i += 1;
        },
        '+' => i += 1,
        else => {},
    }

    if (i >= input.len) return error.InvalidFormat; // input only has `+` or `-`,  throw error.

    // check prefix
    if (i + 1 < input.len and input[i] == '0') {
        switch (input[i + 1]) {
            'x', 'X' => {
                base = 16;
                i += 2;
            },
            'b', 'B' => {
                base = 2;
                i += 2;
            },
            'o', 'O' => {
                base = 8;
                i += 2;
            },
            else => {},
        }
    }

    if (i >= input.len) return error.InvalidFormat; // input only has prefix, such as "0x",  throw error.

    var found = false;
    while (i < input.len) : (i += 1) {
        const c: u8 = input[i];

        const digit: u8 = switch (c) {
            '0'...'9' => c - '0',
            'a'...'f' => if (base > 10) c - 'a' + 10 else break,
            'A'...'F' => if (base > 10) c - 'A' + 10 else break,
            else => break,
        };

        if (digit >= base) break;

        result = checkOverflow: {
            // result = result * base + digit
            var new_result, var overflow = @mulWithOverflow(result, base);
            if (overflow == 1) return error.IntegerOverflow;

            if (is_negative) {
                new_result, overflow = @subWithOverflow(new_result, digit);
            } else {
                new_result, overflow = @addWithOverflow(new_result, digit);
            }
            if (overflow == 1) return error.IntegerOverflow;

            break :checkOverflow new_result;
        };
        found = true;
    }

    if (!found) return error.NotFound;
    return .{ input[i..], result };
}

test parseNumber {
    const testing = std.testing;
    const TestCase = ab.TestCase;

    const cases = [_]TestCase(i64){
        .{ .input = "1234", .expected_value = 1234, .expected_rest = "" },
        .{ .input = "-5678", .expected_value = -5678, .expected_rest = "" },
        .{ .input = "+42", .expected_value = 42, .expected_rest = "" },
        .{ .input = "0x1F3A", .expected_value = 0x1F3A, .expected_rest = "" },
        .{ .input = "-0b1101", .expected_value = -0b1101, .expected_rest = "" },
        .{ .input = "0o754", .expected_value = 0o754, .expected_rest = "" },
        .{ .input = "1000000000000000000", .expected_value = 1000000000000000000, .expected_rest = "" },
        .{ .input = "xyz123", .expected_value = error.NotFound, .expected_rest = "xyz123" },
        .{ .input = "+", .expected_value = error.InvalidFormat, .expected_rest = "+" },
        .{ .input = "-", .expected_value = error.InvalidFormat, .expected_rest = "-" },
        .{ .input = "0x", .expected_value = error.InvalidFormat, .expected_rest = "0x" },
        .{ .input = "0b", .expected_value = error.InvalidFormat, .expected_rest = "0b" },
        .{ .input = "0o", .expected_value = error.InvalidFormat, .expected_rest = "0o" },
        .{ .input = "42abc", .expected_value = 42, .expected_rest = "abc" },
        .{ .input = "-0xABCdef", .expected_value = -0xABCDEF, .expected_rest = "" },
        .{ .input = "0b101010xyz", .expected_value = 42, .expected_rest = "xyz" },
    };

    for (cases) |case| {
        const res = parseNumber(i64, case.input);
        if (case.expected_value) |expected| {
            const rest, const result = res catch unreachable;
            try testing.expectEqual(expected, result);
            try testing.expectEqualSlices(u8, case.expected_rest, rest);
        } else |expect_error| {
            try testing.expectError(expect_error, res);
        }
    }
}

/// Recognizes `\n`.
pub fn newline(input: []const u8) !IResult {
    if (char('\n')(input)) |result| {
        return .{ result.rest, result.result };
    } else |e| {
        return e;
    }
}

/// Recognizes both `\n` and `\r\n`.
pub fn line_ending(input: []const u8) !IResult {
    if (char('\n')(input)) |value| {
        const rest, const result = value;
        return .{ rest, result };
    } else |e| {
        switch (e) {
            error.NotFound => {
                const rest, const result = try tag("\r\n")(input);
                return .{ rest, result };
            },
            else => return e,
        }
    }
}

/// Recognizes any characters except `\n` or `\r\n`.
pub fn not_line_ending(input: []const u8) !IResult {
    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            '\n' => return .{ input[i..], input[0..i] },
            '\r' => {
                if (i + 1 < input.len and input[i + 1] == '\n') {
                    return .{ input[i..], input[0..i] };
                } else {
                    return error.InvalidCharacter;
                }
            },
            else => {},
        }
    }
    return .{ "", input };
}

test not_line_ending {
    const testing = std.testing;
    const TestCase = ab.TestCase;

    const cases = [_]TestCase([]const u8){
        .{ .input = "text\n", .expected_value = "text", .expected_rest = "\n" },
        .{ .input = "text\r\n", .expected_value = "text", .expected_rest = "\r\n" },
        .{ .input = "", .expected_value = "", .expected_rest = "" },
        .{ .input = "\r\n", .expected_value = "", .expected_rest = "\r\n" },
        .{ .input = "\r", .expected_value = error.InvalidCharacter, .expected_rest = "\r" },
    };

    for (cases) |case| {
        const res = not_line_ending(case.input);
        if (case.expected_value) |expected| {
            const rest, const result = res catch unreachable;
            try testing.expectEqualStrings(expected, result);
            try testing.expectEqualStrings(case.expected_rest, rest);
        } else |expect_error| {
            try testing.expectError(expect_error, res);
        }
    }
}

// Recognizes zero or more spaces, tabs, carriage returns and line endings.
// pub fn multispace0(input: []const u8) !IResult {
// const result = try many0(ab.bytes.is_a(" \t\r\n"))(input);
// return IResult{ .rest = result.rest, .result = try std.mem.concat(std.heap.page_allocator, u8, result.result) };
// }

// Recognizes spaces, tabs, carriage returns and line endings.
pub fn multispace1(input: []const u8) !IResult {
    const rest, const result = try many1(ab.bytes.is_a(" \t\r\n"))(input);
    return .{ rest, try std.mem.concat(std.heap.page_allocator, u8, result) };
}

// Recognizes zero or more spaces and tabs.
// pub fn space0(input: []const u8) !IResult {
//     const result = try many0(char(' '))(input);
//     return IResult{ .rest = result.rest, .result = try std.mem.concat(std.heap.page_allocator, u8, result.result) };
// }

// Recognizes spaces and tabs.
pub fn space1(input: []const u8) !IResult {
    const rest, const result = try many1(ab.bytes.is_a(" \t"))(input);
    return .{ rest, try std.mem.concat(std.heap.page_allocator, u8, result) };
}

// Recognizes tabs.
pub fn tab(input: []const u8) !IResult {
    const rest, const result = try char('\t')(input);
    return .{ rest, result };
}

// pub fn none_of(prohibit_str: []const u8) ParserFunc {
//     return struct {
//         fn none_of(input: []const u8) !IResult {
//             if (input.len == 0) {
//                 return error.InputTooShort;
//             }
//
//             var bitmask: [256]bool = [_]bool{true} ** 256;
//             for (prohibit_str) |p| {
//                 bitmask[p] = false;
//             }
//
//             var i: usize = 0;
//             while (bitmask[input[i]]) : (i += 1) {}
//
//             if (i == 0) {
//                 return error.InvalidCharacter;
//             } else {
//                 return IResult{ .rest = input[i..], .result = input[0..i] };
//             }
//         }
//     }.none_of;
// }

/// Recognizes one of provided pattern character.
pub fn one_of(pattern: []const u8) fn ([]const u8) anyerror!ab.Result(u8) {
    return struct {
        fn one_of(input: []const u8) !ab.Result(u8) {
            errdefer |e| ab.report(e, .{ @src().fn_name, pattern, input });

            if (input.len == 0) {
                return error.InputTooShort;
            }

            var bitmask: [256]bool = [_]bool{false} ** 256;
            for (pattern) |p| {
                bitmask[p] = true;
            }

            if (bitmask[input[0]]) {
                return .{ input[1..], input[0] };
            } else {
                return error.NotFound;
            }
        }
    }.one_of;
}

test one_of {
    const testing = std.testing;

    const cases = [_]ab.TestCase(u8){
        .{ .input = "abc", .expected_value = 'a', .expected_rest = "bc" },
        .{ .input = "", .expected_value = error.InputTooShort, .expected_rest = "" },
        .{ .input = "efg", .expected_value = error.NotFound, .expected_rest = "efg" },
    };

    for (cases) |case| {
        const res = one_of("abc")(case.input);
        if (case.expected_value) |expected| {
            const rest, const result = res catch unreachable;
            try testing.expectEqual(expected, result);
            try testing.expectEqualSlices(u8, case.expected_rest, rest);
        } else |expect_error| {
            try testing.expectError(expect_error, res);
        }
    }
}
