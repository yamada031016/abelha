# 🐝 Abelha – A Fast and Lightweight Parser Combinator for Zig

**Abelha** (Portuguese for "bee") is a high-performance, lightweight parser combinator library for **Zig**, inspired by Rust's [`nom`](https://github.com/rust-bakery/nom). Designed for **efficiency, composability, and ease of use**, Abelha helps you build powerful parsers with minimal effort.

## 🚀 Features

- ✅ **Combinator-Based Parsing** – Compose small parsers into complex ones seamlessly.
<!--- ✅ **Zero Allocation (Where Possible)** – Designed for performance and memory efficiency.-->
<!--- ✅ **Streaming & Incremental Parsing** – Handles large inputs efficiently.-->
<!--- ✅ **Flexible Error Handling** – Customizable error types for better debugging.-->
<!--- ✅ **Works with Raw Buffers** – Optimized for low-level parsing use cases.-->
- ✅ **Extensible & Ergonomic** – Define your own combinators for maximum flexibility.

---

## 📦 Installation

To use Abelha in your Zig project, add the following to your `build.zig`:
```sh
zig fetch --save=abelha https://github.com/yamada031016/abelha/archive/refs/heads/master.tar.gz
```

```zig
const abelha = b.dependency("abelha", .{});
exe.addModule("abelha", abelha.module("abelha"));
```

Or clone it directly:

```sh
git clone https://github.com/your-repo/abelha.git
```

---

## 🔥 Quick Start

Here’s a simple example of parsing color code using Abelha.

```zig
const std = @import("std");
const ab = @import("parser/parser.zig");

const ParseResult = ab.ParseResult;
const tag = ab.bytes.tag;
const take = ab.bytes.take;
const separated_list1 = ab.multi.separated_list1;

fn parseHex(input: []const u8) !ParseResult(u8) {
    const res = try take(2)(input);
    const hex = try std.fmt.parseInt(u8, res.result, 16);
    return ParseResult(u8){ .rest = res.rest, .result = hex };
}

fn hexColor(input: []const u8) !ParseResult([]const u8) {
    const result = try tag("#")(input);
    const res = try separated_list1(
        u8,
        tag(""),
        parseHex,
    )(result.rest);
    return res;
}

pub fn main() !void {
    const text = "#1A2B3C";
    const result = try hexColor(text);
    std.debug.print("{x}\n", .{result.result});
}
```

---

## 🏗️ Built-in Combinators

Abelha provides a rich set of combinators:

### **Basic Parsers**
- `tag("xyz")` – Matches an exact string.
- `take_until("end")` – Takes input until a specific sequence is found.
- `is_a("abc")` – Matches any character in the set.
- `is_not("xyz")` – Matches until any of the given characters appear.

### **Combinators**
- `many1(p)` – Applies a parser one or more times.
- `separated_list1(sep, p)` – Parses a list with a separator.
- `delimited(open, p, close)` – Parses content between delimiters.
- `alt(p1, p2, …)` – Attempts multiple parsers and picks the first successful one.
If you want to know about other combinators, see the API reference!

---

## 📚 Documentation

- **[API Reference]()**

---

## 🤝 Contributing

We welcome contributions! Feel free to:

- Submit bug reports and feature requests.
- Improve documentation and examples.
- Implement new combinators.

To get started, clone the repo and run:

```sh
zig build test
```

<!------->
<!---->
<!--## 💜 License-->
<!---->
<!--**MIT License** – Free to use, modify, and distribute.-->

---

🚀 **Ready to parse smarter?** Try Abelha today and build efficient parsers in Zig! 🐝✨
