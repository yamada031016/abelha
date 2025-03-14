//! This module provides combinators applying their child parser multiple times.
const std = @import("std");
const ab = @import("../abelha.zig");
const ParserFunc = ab.ParserFunc;
const IResult = ab.IResult;
const ParseError = ab.ParseError;
const ParseResult = ab.ParseResult;

const char = ab.character.char;
const tag = ab.bytes.tag;
const take_until = ab.bytes.take_until;

/// Runs as long as the specified parser succeeds and returns the result in slices when it fails.
pub fn many0(parser: ParserFunc) fn ([]const u8) anyerror!ab.Result([]const []const u8) {
    return struct {
        fn many0(input: []const u8) !ab.Result([]const []const u8) {
            errdefer |e| ab.report(e, .{ @src().fn_name, parser, input });

            var array = std.ArrayList([]const u8).init(std.heap.page_allocator);
            var rest = input;
            while (true) {
                rest, const result = parser(rest) catch {
                    if (array.getLastOrNull()) |_| {
                        return .{ rest, try array.toOwnedSlice() };
                    }
                    return error.NotFound;
                };

                try array.append(result);
                if (rest.len == 0) {
                    return .{ rest, try array.toOwnedSlice() };
                }
            }
        }
    }.many0;
}

test many0 {
    const target = "### hogehoge";
    _, const result = try many0(char('#'))(target);
    try std.testing.expectEqual(3, result.len);
    try std.testing.expectEqualStrings("###", try std.mem.concat(std.heap.page_allocator, u8, result));
}

/// Runs as long as the specified parser succeeds and returns the result in slices when it fails.
pub fn many1(parser: ParserFunc) fn ([]const u8) anyerror!ab.Result([]const []const u8) {
    return struct {
        fn many1(input: []const u8) !ab.Result([]const []const u8) {
            errdefer |e| ab.report(e, .{ @src().fn_name, parser, input });

            return try ab.prohibitEmptyResult([]const []const u8, "many0", many0(parser), input);
        }
    }.many1;
}

test many1 {
    const target = "### hogehoge";
    _, const result = try many1(char('#'))(target);
    try std.testing.expectEqual(3, result.len);
    try std.testing.expectEqualStrings("###", try std.mem.concat(std.heap.page_allocator, u8, result));
}

/// Run the parser `parser` until the parser `end` succeeds.
/// If the parser `end` succeeds, return the results of the `parser` so far as a slice
pub fn many_till(parser: ParserFunc, end: ParserFunc) fn ([]const u8) ParseError!ab.Result([]const []const u8) {
    return struct {
        fn many_till(input: []const u8) ParseError!ab.Result([]const []const u8) {
            errdefer |e| ab.report(e, .{ @src().fn_name, .{ parser, end }, input });

            var array = std.ArrayList([]const u8).init(std.heap.page_allocator);
            var rest = input;
            while (true) {
                const r = parser(rest);
                if (r) |res| {
                    rest, var result = res;
                    array.append(result) catch {
                        return error.OutOfMemory;
                    };
                    if (rest.len == 0) {
                        return .{ rest, try array.toOwnedSlice() };
                    }
                    const facedEnd = end(rest);
                    if (facedEnd) |endResult| {
                        rest, result = endResult;
                        return .{ rest, try array.toOwnedSlice() };
                    } else |e| {
                        switch (e) {
                            else => {},
                        }
                    }
                } else |_| {
                    if (array.getLastOrNull()) |_| {
                        return .{ rest, try array.toOwnedSlice() };
                    } else {
                        // return e;
                    }
                }
            }
        }
    }.many_till;
}

/// The input is split in a sequence of bytes that is recognized by the parser `sep`, and the split elements are recognized by the parser `parser`.
/// If `parser` fails, it returns an error, and if `sep` fails, it returns the result of `parser` so far in slices.
pub fn separated_list1(T: type, sep: anytype, parser: anytype) fn ([]const u8) anyerror!ab.Result([]const T) {
    return struct {
        fn separated_list1(input: []const u8) !ab.Result([]const T) {
            // errdefer |e| ab.report(e, .{ @src().fn_name, .{T, sep, parser}, input });

            var array = std.ArrayList(T).init(std.heap.page_allocator);
            var rest = input;
            while (parser(rest)) |value| {
                rest, const result = value;
                try array.append(result);
                rest, _ = sep(rest) catch {
                    return ab.Result([]const T){ rest, array.items };
                };
                if (rest.len == 0) {
                    return ab.Result([]const T){ rest, try array.toOwnedSlice() };
                }
            } else |e| {
                if (array.getLastOrNull()) |_| {
                    return ab.Result([]const T){ rest, try array.toOwnedSlice() };
                } else {
                    return e;
                }
            }
        }
    }.separated_list1;
}

test separated_list1 {
    const text = "abc|abc|abc";
    _, const result = try separated_list1([]const u8, tag("|"), tag("abc"))(text);
    const answer = [_][]const u8{ "abc", "abc", "abc" };
    try std.testing.expectEqualSlices([]const u8, &answer, result);
}
