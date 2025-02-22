const std = @import("std");

pub const branch = @import("branch/branch.zig");
pub const character = @import("character/character.zig");
pub const bytes = @import("bytes/bytes.zig");
pub const multi = @import("multi/multi.zig");
pub const combinator = @import("combinator/combinator.zig");
pub const sequence = @import("sequence/sequence.zig");

/// Generic Result type.
pub fn ParseResult(T: anytype) type {
    return struct {
        rest: []const u8,
        result: T,
    };
}

/// Errors that occur during parsing
pub const ParseError = error{
    UnexpectedEndOfInput,
    InvalidFormat,
    NotFound,
    InputTooShort,
    NeedleTooShort,
};

/// Basic Result type of parser
pub const IResult = ParseResult([]const u8);

/// Basic function signature of parser
pub const ParserFunc = fn ([]const u8) anyerror!IResult;

test {
    std.testing.refAllDecls(@This());
}
