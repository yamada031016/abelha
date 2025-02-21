const std = @import("std");

pub const basic = @import("basic.zig");
pub const number = @import("number.zig");
pub const structure = @import("structure.zig");
pub const combinator = @import("combinator.zig");
pub const whitespace = @import("whitespace.zig");

pub fn ParseResult(T: anytype) type {
    return struct {
        rest: []const u8,
        result: T,
    };
}

pub const ParseError = error{
    UnexpectedEndOfInput,
    InvalidFormat,
    NotFound,
    InputTooShort,
    NeedleTooShort,
};

pub const IResult = ParseResult([]const u8);
pub const ParserFunc = fn ([]const u8) anyerror!IResult;
