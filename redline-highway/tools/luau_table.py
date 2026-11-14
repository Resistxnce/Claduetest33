#!/usr/bin/env python3
"""Read Luau data tables (car configurations, sound sheets) into Python values.

Handles what the project's data modules use: nested tables, keyed and positional fields,
["key"] = value fields, numbers (including hex and negative), strings, true/false/nil, comments
(including --[[ block ]] comments) and constructor calls such as Color3.fromRGB(150, 12, 18), which
come back as {"call": "Color3.fromRGB", "args": [150, 12, 18]}. A bare name comes back as
{"ref": "name"}. Tables with only keyed fields become dicts, tables with only positional fields
become lists, and mixed tables become dicts with integer keys (1-based) for positional fields.

    from luau_table import load
    config = load("src/ReplicatedStorage/VehicleSystem/VehicleConfigurations/Prototype812.luau")
    audio = load(path, key="audio")   # just the table assigned to `audio = {...}`
"""
import pathlib
import re

_TOKEN = re.compile(
    r"""\s*(?:
        (?P<block>--\[(?P<eq>=*)\[.*?\](?P=eq)\])
      | (?P<comment>--[^\n]*)
      | (?P<string>"(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*')
      | (?P<number>-?(?:0[xX][0-9a-fA-F_]+|(?:\d[\d_]*(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?))
      | (?P<name>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)
      | (?P<sym>[{}()\[\]=,;])
    )""",
    re.S | re.X,
)
_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", '"': '"', "'": "'", "0": "\0"}


def _tokens(text):
    out, pos = [], 0
    while pos < len(text):
        m = _TOKEN.match(text, pos)
        if not m or m.end() == pos:
            if text[pos:].strip() == "":
                break
            line = text.count("\n", 0, pos) + 1
            raise ValueError(f"can't read Luau data at line {line}: {text[pos:pos + 40]!r}")
        pos = m.end()
        if m.group("block") or m.group("comment"):
            continue
        if m.group("string"):
            raw = m.group("string")[1:-1]
            out.append(("val", re.sub(r"\\(.)", lambda e: _ESCAPES.get(e.group(1), e.group(1)), raw)))
        elif m.group("number"):
            n = m.group("number").replace("_", "")
            value = int(n, 16) if n.lower().lstrip("-").startswith("0x") else float(n)
            if isinstance(value, float) and value.is_integer() and "." not in n and "e" not in n.lower():
                value = int(value)
            out.append(("val", value))
        elif m.group("name"):
            name = m.group("name")
            if name in ("true", "false"):
                out.append(("val", name == "true"))
            elif name == "nil":
                out.append(("val", None))
            else:
                out.append(("name", name))
        else:
            out.append(("sym", m.group("sym")))
    return out


class _Parser:
    def __init__(self, tokens):
        self.t = tokens
        self.i = 0

    def peek(self, k=0):
        return self.t[self.i + k] if self.i + k < len(self.t) else ("eof", None)

    def take(self, kind=None, value=None):
        tok = self.peek()
        if (kind and tok[0] != kind) or (value is not None and tok[1] != value):
            raise ValueError(f"expected {value or kind}, got {tok[1]!r}")
        self.i += 1
        return tok

    def value(self):
        kind, v = self.peek()
        if kind == "sym" and v == "{":
            return self.table()
        if kind == "val":
            self.i += 1
            return v
        if kind == "name":
            self.i += 1
            if self.peek() == ("sym", "("):
                self.i += 1
                args = []
                while self.peek() != ("sym", ")"):
                    args.append(self.value())
                    if self.peek() == ("sym", ","):
                        self.i += 1
                self.take("sym", ")")
                return {"call": v, "args": args}
            return {"ref": v}
        raise ValueError(f"unexpected {v!r}")

    def table(self):
        self.take("sym", "{")
        keyed, items = {}, []
        while self.peek() != ("sym", "}"):
            if self.peek() == ("sym", "["):
                self.i += 1
                key = self.value()
                self.take("sym", "]")
                self.take("sym", "=")
                keyed[key] = self.value()
            elif self.peek()[0] == "name" and self.peek(1) == ("sym", "=") and "." not in self.peek()[1]:
                key = self.take("name")[1]
                self.take("sym", "=")
                keyed[key] = self.value()
            else:
                items.append(self.value())
            if self.peek()[0] == "sym" and self.peek()[1] in ",;":
                self.i += 1
        self.take("sym", "}")
        if keyed and items:
            for n, item in enumerate(items, 1):
                keyed[n] = item
            return keyed
        return keyed if keyed else items


def parse(text):
    """Parse one Luau table constructor, e.g. '{ a = 1, { 2, 3 } }'."""
    return _Parser(_tokens(text)).table()


def load(path, key=None):
    """The table a data module returns, or (with key) the table assigned to `key = {...}` in it."""
    text = pathlib.Path(path).read_text()
    if key:
        m = re.search(rf"(?<![\w.]){re.escape(key)}\s*=\s*\{{", text)
    else:
        m = re.search(r"^return\s*\{", text, re.M)
    if not m:
        raise ValueError(f"no {'`' + key + ' = {`' if key else 'returned table'} in {path}")
    start = m.end() - 1
    # find the matching brace, skipping strings and comments
    tokens = _tokens(text[start:])
    depth = 0
    for n, tok in enumerate(tokens):
        if tok == ("sym", "{"):
            depth += 1
        elif tok == ("sym", "}"):
            depth -= 1
            if depth == 0:
                return _Parser(tokens[: n + 1]).table()
    raise ValueError(f"unbalanced braces in {path}")


if __name__ == "__main__":
    import json
    import sys
    print(json.dumps(load(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None), indent=1, default=str)[:3000])
