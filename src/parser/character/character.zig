const std = @import("std");
const ab = @import("../parser.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

const tag = ab.bytes.tag;
const many1 = ab.multi.many1;

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

pub fn hexDigit1(input: []const u8) !IResult {
    if (input.len < 1) {
        return ParseError.InputTooShort;
    }
    const hex = input[0];
    if (std.ascii.isHex(hex)) {
        return IResult{ .rest = input[1..], .result = input[0..1] };
    } else {
        return ParseError.InvalidFormat;
    }
}

pub fn newline(input: []const u8) !IResult {
    if (char('\n')(input)) |result| {
        return IResult{ .rest = result.rest, .result = result.result };
    } else |e| {
        return e;
    }
}

pub fn line_ending(input: []const u8) !IResult {
    if (char('\n')(input)) |result| {
        return IResult{ .rest = result.rest, .result = result.result };
    } else |e| {
        switch (e) {
            ParseError.NotFound => {
                const result = try tag("\r\n")(input);
                return IResult{ .rest = result.rest, .result = result.result };
            },
            else => return e,
        }
    }
}

pub fn space1(input: []const u8) !IResult {
    const result = try many1(char(' '))(input);
    return IResult{ .rest = result.rest, .result = try std.mem.concat(std.heap.page_allocator, u8, result.result) };
}
