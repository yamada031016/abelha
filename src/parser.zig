const std = @import("std");

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
                return ParseError.NeedleTooShort;
            } else {
                if (std.mem.eql(u8, input[0..needle.len], needle)) {
                    return IResult{ .rest = input[needle.len..], .result = needle };
                } else {
                    return ParseError.NotFound;
                }
            }
        }
    }.parse;
}

pub fn many1(parser: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            var result: []u8 = "";
            var rest_input = input;
            while (true) {
                const r = parser(rest_input);
                if (r) |res| {
                    result = std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}", .{ result, res.result }) catch |err| {
                        return err;
                    };
                    rest_input = res.rest;
                } else |e| {
                    if (result.len == 0) {
                        return e;
                    } else {
                        return IResult{ .rest = rest_input, .result = result };
                    }
                }
            }
        }
    }.parse;
}

test "many1 char" {
    const target = "### hogehoge";
    const result = try many1(char('#'))(target);
    try std.testing.expectEqualStrings("###", result.result);
}

pub fn delimited(start: ParserFunc, content: ParserFunc, end: ParserFunc) ParserFunc {
    return struct {
        fn parse(input: []const u8) !IResult {
            var result = try start(input);
            result = try content(result.rest);
            const text = result.result;
            result = try end(result.rest);
            return IResult{ .rest = result.rest, .result = text };
        }
    }.parse;
}

test "delimited" {
    const target = "<h1>";
    const result = try delimited(tag("<"), take_until(">"), tag(">"))(target);
    try std.testing.expectEqualStrings("h1", result.result);
}

pub fn pair(T: type, first: ParserFunc, second: ParserFunc) fn ([]const u8) anyerror!ParseResult(T) {
    return struct {
        fn parse(input: []const u8) !IResult {
            var result = try first(input);
            result = try second(result.rest);
            return ParseResult(T){ .rest = result.rest, .result = result.result };
        }
    }.parse;
}

pub fn space1(input: []const u8) !IResult {
    return many1(char(' '))(input);
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
        switch (e) {
            ParseError.NotFound => {
                const result = try tag("\r\n")(input);
                return IResult{ .rest = result.rest, .result = result.result };
            },
            else => return e,
        }
    }
}

pub fn separated_list1(T: type, seq: anytype, parser: anytype) fn ([]const u8) anyerror!ParseResult([]const T) {
    return struct {
        fn parse(input: []const u8) !ParseResult([]const T) {
            var results = std.ArrayList(T).init(std.heap.page_allocator);
            var rest_input = input;
            while (parser(rest_input)) |result| {
                try results.append(result.result);
                const res = seq(result.rest) catch {
                    return ParseResult([]const T){ .rest = result.rest, .result = results.items };
                };
                rest_input = res.rest;
            } else |e| {
                if (results.items.len == 0) {
                    return e;
                } else {
                    return ParseResult([]const T){ .rest = rest_input, .result = results.items };
                }
            }
        }
    }.parse;
}

test "separated_list1" {
    const text = "abc|abc|abc";
    const result = try separated_list1(tag("|"), tag("abc"))(text);
    const answer = [_][]const u8{ "abc", "abc", "abc" };
    try std.testing.expectEqualSlices([]const u8, &answer, result.result.items);
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

pub fn alt(T: type, parser_tupple: anytype) fn ([]const u8) anyerror!ParseResult(T) {
    return struct {
        fn parse(input: []const u8) !ParseResult(T) {
            inline for (parser_tupple) |parser| {
                const result = parser(input);
                if (result) |res| {
                    return ParseResult(T){ .rest = res.rest, .result = res.result };
                } else |e| {
                    // ignore error
                    switch (e) {
                        else => {},
                    }
                }
            } else {
                return ParseError.NotFound;
            }
        }
    }.parse;
}

test "alt" {
    const target = "*italic*\n";
    const result = try alt([]const u8, .{ char('\n'), tag("**"), take_until("</p>"), take_until("\n"), char('#') })(target);
    try std.testing.expectEqualStrings("*italic*", result.result);
}
