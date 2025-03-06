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
pub fn many1(parser: ParserFunc) fn ([]const u8) anyerror!ParseResult([]const []const u8) {
    return struct {
        fn many1(input: []const u8) !ParseResult([]const []const u8) {
            errdefer |e| ab.report(e, .{ @src().fn_name, parser, input });

            var array = std.ArrayList([]const u8).init(std.heap.page_allocator);
            var rest_input = input;
            while (true) {
                const result = parser(rest_input) catch {
                    if (array.getLastOrNull()) |_| {
                        return ParseResult([]const []const u8){ .rest = rest_input, .result = try array.toOwnedSlice() };
                    }
                    return error.NotFound;
                };

                try array.append(result.result);
                if (result.rest.len == 0) {
                    return ParseResult([]const []const u8){ .rest = result.rest, .result = try array.toOwnedSlice() };
                } else {
                    rest_input = result.rest;
                }
            }
        }
    }.many1;
}

test many1 {
    const target = "### hogehoge";
    const result = try many1(char('#'))(target);
    try std.testing.expectEqual(3, result.result.len);
    try std.testing.expectEqualStrings("###", try std.mem.concat(std.heap.page_allocator, u8, result.result));
}

/// Run the parser `parser` until the parser `end` succeeds.
/// If the parser `end` succeeds, return the results of the `parser` so far as a slice
pub fn many_till(parser: fn ([]const u8) ParseError!IResult, end: fn ([]const u8) ParseError!IResult) fn ([]const u8) ParseError!ParseResult([]const []const u8) {
    return struct {
        fn many_till(input: []const u8) ParseError!ParseResult([]const []const u8) {
            errdefer |e| ab.report(e, .{ @src().fn_name, .{ parser, end }, input });

            var array = std.ArrayList([]const u8).init(std.heap.page_allocator);
            var rest_input = input;
            while (true) {
                const r = parser(rest_input);
                if (r) |res| {
                    array.append(res.result) catch {
                        return error.OutOfMemory;
                    };
                    if (res.rest.len == 0) {
                        return ParseResult([]const []const u8){ .rest = res.rest, .result = try array.toOwnedSlice() };
                    } else {
                        rest_input = res.rest;
                    }

                    const facedEnd = end(rest_input);
                    if (facedEnd) |endResult| {
                        return ParseResult([]const []const u8){ .rest = endResult.rest, .result = try array.toOwnedSlice() };
                    } else |e| {
                        switch (e) {
                            else => {},
                        }
                    }
                } else |e| {
                    if (array.getLastOrNull()) |_| {
                        return ParseResult([]const []const u8){ .rest = rest_input, .result = try array.toOwnedSlice() };
                    } else {
                        return e;
                    }
                }
            }
        }
    }.many_till;
}

/// The input is split in a sequence of bytes that is recognized by the parser `sep`, and the split elements are recognized by the parser `parser`.
/// If `parser` fails, it returns an error, and if `sep` fails, it returns the result of `parser` so far in slices.
pub fn separated_list1(T: type, sep: anytype, parser: anytype) fn ([]const u8) anyerror!ParseResult([]const T) {
    return struct {
        fn separated_list1(input: []const u8) !ParseResult([]const T) {
            // errdefer |e| ab.report(e, .{ @src().fn_name, .{T, sep, parser}, input });

            var array = std.ArrayList(T).init(std.heap.page_allocator);
            var rest_input = input;
            while (parser(rest_input)) |result| {
                try array.append(result.result);
                const res = sep(result.rest) catch {
                    std.log.debug("separater at {s} failed.\n", .{result.rest});
                    return ParseResult([]const T){ .rest = result.rest, .result = array.items };
                };
                if (res.rest.len == 0) {
                    std.log.debug("input is fully consumed.\n", .{});
                    return ParseResult([]const T){ .rest = rest_input, .result = try array.toOwnedSlice() };
                } else {
                    rest_input = res.rest;
                }
            } else |e| {
                if (array.getLastOrNull()) |_| {
                    return ParseResult([]const T){ .rest = rest_input, .result = try array.toOwnedSlice() };
                } else {
                    return e;
                }
            }
        }
    }.separated_list1;
}

test separated_list1 {
    const text = "abc|abc|abc";
    const result = try separated_list1([]const u8, tag("|"), tag("abc"))(text);
    const answer = [_][]const u8{ "abc", "abc", "abc" };
    try std.testing.expectEqualSlices([]const u8, &answer, result.result);
}
