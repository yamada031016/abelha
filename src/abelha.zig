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

pub fn Result(T: anytype) type {
    return struct {
        []const u8,
        T,
    };
}

/// Errors that occur during parsing
pub const ParseError = error{
    UnexpectedEndOfInput,
    InvalidFormat,
    InvalidCharacter,
    InvalidArgument,
    NotFound,
    EmptyMatched,
    InputTooShort,
    NeedleTooLong,
    UnknownKeyword,
    IntegerOverflow,
} || std.mem.Allocator.Error;

const ParserArgType = union(enum) {
    Unit: void,
    String: []const u8,
    ParserFunc: ParserFunc,
    Tuple: void,
    Type: type,
    Other: void,
};
fn examineArgType(arg: anytype) ParserArgType {
    switch (@typeInfo(@TypeOf(arg))) {
        .pointer => |pointer| {
            switch (@typeInfo(pointer.child)) {
                .array => |arr| {
                    // []const u8
                    if (@typeInfo(arr.child) == .int) {
                        return ParserArgType{ .String = arg };
                    }
                },
                .int => return ParserArgType{ .String = arg },
                else => @panic("parser function arguments have unsupported type of pointer."),
            }
        },
        .@"struct" => |s| {
            if (s.is_tuple and arg.len == 0) {
                if (arg.len == 0) {
                    return ParserArgType{ .Unit = void{} };
                }
            }
            return ParserArgType{ .Tuple = void{} };
        },
        .@"fn" => return ParserArgType{ .ParserFunc = arg },
        .type => return ParserArgType{ .Type = arg },
        else => return ParserArgType{ .Other = void{} },
    }
}

// args[0]: parse function name
// args[1]: parse function arguments
// args[2]: parse function input
// args[3..]: optional infomation
pub fn report(err: anyerror, args: anytype) void {
    if (@import("config").enableLogger or comptime (@import("builtin").mode == .Debug or @import("builtin").mode == .ReleaseSafe)) {
        const argType = examineArgType(args[1]);
        switch (err) {
            error.InputTooShort => {
                switch (argType) {
                    ParserArgType.String => |str| std.debug.print(
                        \\{s}({s}) {s}
                        \\found: {s}
                        \\       ^ -- Expected at least {}, but found only {}.
                    , .{ args[0], str, @errorName(err), args[2], str.len, args[2].len }),
                    ParserArgType.Tuple => {
                        std.debug.print(
                            \\{s}({any}) {s}
                            \\found: {s}
                            \\       ^ -- Expected at least {}, but found only {}.
                        , .{ args[0], args[1], @errorName(err), args[2], args[1].len, args[2].len });
                    },
                    ParserArgType.Unit => std.debug.print(
                        \\
                        \\{s}() {s}
                        \\found: {s}
                        \\       ^
                    , .{ args[0], @errorName(err), args[2] }),
                    ParserArgType.ParserFunc => {
                        std.debug.print(
                            \\
                            \\[error] {s}({s}) {s}
                            \\found: {s}
                            \\       ^
                        , .{ args[0], @typeName(@TypeOf(args[1])), @errorName(err), args[2] });
                    },
                    else => {
                        std.debug.print(
                            \\{s}({any}) {s}
                            \\found: {s}
                            \\       ^
                        , .{ args[0], args[1], @errorName(err), args[2] });
                    },
                }
            },
            error.NeedleTooLong => {
                switch (argType) {
                    ParserArgType.String => |str| {
                        std.debug.print(
                            \\
                            \\[error] {s}("{s}") {s}
                            \\found: {s}
                            \\       ^ -- Expected at most {}, but needle requires {}.
                        , .{ args[0], str, @errorName(err), args[2], args[2].len, str.len });
                    },
                    ParserArgType.Tuple => std.debug.print(
                        \\
                        \\[error] {s}({any}) {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], args[1], @errorName(err), args[2] }),
                    ParserArgType.Unit => std.debug.print(
                        \\
                        \\[error] {s} {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], @errorName(err), args[2] }),
                    ParserArgType.ParserFunc => std.debug.print(
                        \\
                        \\[error] {s}({s}) {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], @typeName(@TypeOf(args[1])), @errorName(err), args[2] }),
                    else => std.debug.print(
                        \\
                        \\[error] {s}({any}) {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], args[1], @errorName(err), args[2] }),
                }
            },
            error.NotFound => {
                switch (argType) {
                    ParserArgType.String => {
                        std.debug.print(
                            \\
                            \\[error] {s}("{s}") {s}
                            \\┌─
                            \\│ {s}
                            \\  ^ -- Expected "{s}", but found "{s}".
                        , .{ args[0], args[1], @errorName(err), args[2], args[1], args[2] });
                    },
                    ParserArgType.Tuple => std.debug.print(
                        \\
                        \\[error] {s}({any}) {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], args[1], @errorName(err), args[2] }),
                    ParserArgType.Unit => std.debug.print(
                        \\
                        \\[error] {s} {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], @errorName(err), args[2] }),
                    ParserArgType.ParserFunc => std.debug.print(
                        \\
                        \\[error] {s}({s}) {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], @typeName(@TypeOf(args[1])), @errorName(err), args[2] }),
                    else => std.debug.print(
                        \\
                        \\[error] {s}({any}) {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], args[1], @errorName(err), args[2] }),
                }
            },
            error.InvalidFormat, error.EmptyMatched => {
                switch (argType) {
                    .String => std.debug.print(
                        \\
                        \\[error] {s}("{s}") {s}
                        \\┌─
                        \\│ {s}
                        \\  ^ -- Expected "{s}", but found "{s}".
                    , .{ args[0], args[1], @errorName(err), args[2], args[1], args[2] }),
                    .Tuple => std.debug.print(
                        \\
                        \\[error] {s}({any}) {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], args[1], @errorName(err), args[2] }),
                    .Unit => std.debug.print(
                        \\
                        \\[error] {s} {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], @errorName(err), args[2] }),
                    .ParserFunc => std.debug.print(
                        \\
                        \\[error] {s}({s}) {s}
                        \\┌─
                        \\│ {s}
                        \\  ^
                    , .{ args[0], @typeName(@TypeOf(args[1])), @errorName(err), args[2] }),
                    else => {
                        std.debug.print(
                            \\
                            \\[error] {s}({any}) {s}
                            \\┌─
                            \\│ {s}
                            \\  ^
                        , .{ args[0], args[1], @errorName(err), args[2] });
                    },
                }
            },
            error.IntegerOverflow => {
                switch (argType) {
                    .Type => |t| std.debug.print(
                        \\
                        \\[error] {s}("{s}") {s}
                        \\┌─
                        \\│ {s}
                        \\  ^ -- Integer too {s}.
                    , .{
                        args[0],
                        @typeName(t),
                        @errorName(err),
                        args[2],
                        if (args[2][0] == '-') "small" else "large",
                    }),
                    else => unreachable,
                }
            },
            else => {
                unreachable;
                // switch (args.len) {
                //     0 => std.debug.print(
                //         \\ parse failed.
                //     , .{}),
                //     3 => std.debug.print(
                //         \\{s}({s}) {s}
                //         \\found: {s}
                //     , .{ args[0], args[1], @errorName(err), args[2] }),
                //     else => std.debug.print("much panic arguement: {any}", .{args}),
                // }
            },
        }
    }
}

// pub const IResult = ParseResult([]const u8);
pub const IResult = Result([]const u8);
/// Basic function signature of parser
pub const ParserFunc = ParserFnType([]const u8);
pub fn ParserFnType(comptime T: type) type {
    return fn ([]const u8) anyerror!Result(T);
}

// helper function to generate **1() parser, such as alpha1.
pub fn prohibitEmptyResult(comptime T: type, name: []const u8, parser: ParserFnType(T), input: []const u8) !Result(T) {
    errdefer |e| report(e, .{ name, .{}, input });

    if (input.len == 0) {
        return error.InputTooShort;
    }

    const rest, const result = try parser(input);
    if (result.len == 0) {
        return error.EmptyMatched;
    }

    return .{ rest, result };
}

pub fn TestCase(comptime T: type) type {
    return struct {
        input: []const u8,
        expected_value: anyerror!T,
        expected_rest: []const u8,
    };
}

test {
    std.testing.refAllDecls(@This());
}
