const std = @import("std");
const ab = @import("parser.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;

const char = ab.basic.char;
const tag = ab.basic.tag;
const many1 = ab.combinator.many1;

pub fn newline(input: []const u8) !IResult {
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
    return many1(char(' '))(input);
}
