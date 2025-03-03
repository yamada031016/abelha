//! Abelha

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

pub fn ResultType(T: anytype) type {
    return struct {
        []const u8,
        T,
    };
}

pub fn Result(T: anytype) type {
    return union(enum) {
        Ok: ResultType(T),
        Err: struct {
            pos: usize,
            message: []const u8,
        },
    };
}

/// Errors that occur during parsing
pub const ParseError = error{
    UnexpectedEndOfInput,
    InvalidFormat,
    InvalidCharacter,
    NotFound,
    InputTooShort,
    NeedleTooLong,
    UnknownKeyword,
};

// args[0]: parse function name
// args[1]: parse function arguments
// args[2]: parse function input
// args[3..]: optional infomation
pub inline fn panic(err: anyerror, args: anytype) void {
    if (@import("builtin").mode == .Debug or @import("builtin").mode == .ReleaseSafe) {
        switch (err) {
            error.InputTooShort => std.debug.print(
                \\{s}({}) {s}
                \\found: {s}
                \\       ^ -- Expected at least {}, but found only {}.
            , .{ args[0], args[1], @errorName(err), args[2], args[1], args[2].len }),
            error.NeedleTooLong => std.debug.print(
                \\
                \\[error] {s}("{s}") {s}
                \\found: {s}
                \\       ^ -- Expected at most {}, but needle requires {}.
            , .{ args[0], args[1], @errorName(err), args[2], args[2].len, args[1].len }),
            error.NotFound => {
                switch (@typeInfo(@TypeOf(args[1]))) {
                    .Pointer => |pointer| {
                        const str = args[1];
                        switch (@typeInfo(pointer.child)) {
                            .Array => |arr| {
                                if (@typeInfo(arr.child) == .Int) {
                                    // []const u8
                                    std.debug.print(
                                        \\
                                        \\[error] {s}("{s}") {s}
                                        \\┌─
                                        \\│ {s}
                                        \\  ^ -- Expected "{s}", but found "{s}".
                                    , .{ args[0], str, @errorName(err), args[2], str, args[2] });
                                }
                            },
                            .Int => std.debug.print(
                                \\
                                \\[error] {s}("{s}") {s}
                                \\┌─
                                \\│ {s}
                                \\  ^ -- Expected "{s}", but found "{s}".
                            , .{ args[0], str, @errorName(err), args[2], str, args[2] }),
                            else => @panic("parser function arguments have unsupported type of pointer."),
                        }
                    },
                    .Struct => |s| {
                        if (s.is_tuple) {
                            const parse_args = args[1];
                            if (parse_args.len == 0) {
                                std.debug.print(
                                    \\
                                    \\[error] {s} {s}
                                    \\┌─
                                    \\│ {s}
                                    \\  ^
                                , .{ args[0], @errorName(err), args[2] });
                            }
                        }
                        std.debug.print(
                            \\
                            \\[error] {s}({any}) {s}
                            \\┌─
                            \\│ {s}
                            \\  ^
                        , .{ args[0], args[1], @errorName(err), args[2] });
                    },
                    else => {
                        std.debug.print(
                            \\
                            \\[error] {s}({}) {s}
                            \\┌─
                            \\│ {s}
                            \\  ^ -- Expected "{s}", but found "{s}".
                        , .{ args[0], args[1], @errorName(err), args[2], args[1], args[2] });
                    },
                }
            },
            else => {
                switch (args.len) {
                    0 => std.debug.print(
                        \\ parse failed.
                    , .{}),
                    3 => std.debug.print(
                        \\{s}({}) {s}
                        \\found: {s}
                    , .{ args[0], args[1], @errorName(err), args[2] }),
                    else => std.debug.print("much panic arguement: {any}", .{args}),
                }
            },
        }
    }
}

/// Basic Result type of parser
pub const IResult = ParseResult([]const u8);

/// Basic function signature of parser
pub const ParserFunc = fn ([]const u8) anyerror!IResult;

test {
    std.testing.refAllDecls(@This());
}
