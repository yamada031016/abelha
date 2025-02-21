const std = @import("std");
const ab = @import("parser.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

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
