const std = @import("std");
const ab = @import("parser.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

pub fn take(cnt: usize) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            if (input.len < cnt) {
                return ParseError.InvalidFormat;
            }
            return IResult{ .rest = input[cnt..], .result = input[0..cnt] };
        }
    }.parse;
}

pub fn char(character: u8) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
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
            return ParseError.NotFound;
        }
    }.parse;
}

test "parse character" {
    const target = "#hogehoge";
    const result = try char('#')(target);
    try std.testing.expectEqualStrings("#", result.result);
}

pub fn tag(needle: []const u8) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            if (input.len < needle.len) {
                std.log.warn("\ntarget string: {s}(len: {})\nneedle: {s}(len: {})\n", .{ input, input.len, needle, needle.len });
                return ParseError.NeedleTooShort;
            } else {
                if (std.mem.eql(u8, input[0..needle.len], needle)) {
                    std.log.warn("\ntarget string: {s}(len: {})\nneedle: {s}(len: {})\n", .{ input, input.len, needle, needle.len });
                    return IResult{ .rest = input[needle.len..], .result = needle };
                } else {
                    std.log.warn("\ntarget string: {s}\nneedle: {s}\n", .{ input, needle });
                    return ParseError.NotFound;
                }
            }
        }
    }.parse;
}

pub fn take_until(end: []const u8) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            const index = std.mem.indexOf(u8, input, end);
            if (index) |idx| {
                return IResult{ .rest = input[idx..], .result = input[0..idx] };
            } else {
                return ParseError.NotFound;
            }
        }
    }.parse;
}

pub fn is_not(needle: []const u8) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            if (input.len == 0) {
                return ParseError.InputTooShort;
            }

            for (input, 0..) |c, i| {
                for (needle) |n| {
                    if (c == n) {
                        return IResult{ .rest = input[i..], .result = input[0..i] };
                    }
                }
            }
            return IResult{ .rest = "", .result = input };

            // var min_pos: ?usize = null;
            // for (0..needle.len) |i| {
            //     if (std.mem.indexOf(u8, input, needle[i..i])) |_| {
            //         if (min_pos) |min| {
            //             if (i < min) {
            //                 min_pos = i;
            //             }
            //         } else {
            //             min_pos = i;
            //         }
            //     }
            // }
            //
            // if (min_pos) |min| {
            //     return IResult{ .rest = input[min..], .result = input[0..min] };
            // } else {
            //     return IResult{ .rest = "", .result = input };
            // }
        }
    }.parse;
}
