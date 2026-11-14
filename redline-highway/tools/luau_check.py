#!/usr/bin/env python3
"""Static checker for this project's Luau code, using only Python's standard library.

What it checks:
  * syntax: a full Luau parser (types, compound assignment, if-expressions, string interpolation,
    continue, generics);
  * scope: reads of undefined variables, writes to globals, unused locals;
  * standard libraries: members of math, string, table, task, os, coroutine, utf8, bit32, debug
    and the constructors of Vector3, CFrame, Color3, UDim2 and the other data types;
  * Roblox API, against Roblox's own API dump: class names in Instance.new, service names in
    GetService, Enum.X.Y items, and properties, methods and events used on values whose class is
    known (from Instance.new, GetService, type annotations, casts and typed properties);
  * modules: every require() path is resolved in the place's instance tree, and members used on a
    required module (and on objects made by its .new constructor) must exist in that module.

Usage:
  python3 tools/luau_check.py --api-dump PATH/API-Dump.json [--verbose]

Get the API dump from Roblox's deployment server (version string first, then the dump):
  curl -s https://setup.rbxcdn.com/versionQTStudio            -> e.g. version-0123456789abcdef
  curl -o API-Dump.json https://setup.rbxcdn.com/<version>-API-Dump.json
Without --api-dump the Roblox API checks are skipped. Exit status is 1 if any error is found.

This does not replace Roblox's own type checker (Script Analysis in Studio); it catches the
mistakes that would otherwise only show up as errors on the first Play test.
"""
import argparse
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src"

KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in",
    "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while",
}

SYMBOLS = sorted([
    "...", "..=", "//=", "==", "~=", "<=", ">=", "+=", "-=", "*=", "/=", "%=", "^=", "//", "::",
    "->", "..", "+", "-", "*", "/", "%", "^", "#", "<", ">", "=", "(", ")", "{", "}", "[", "]",
    ";", ":", ",", ".", "?", "|", "&", "@",
], key=len, reverse=True)

COMPOUND_OPS = {"+=", "-=", "*=", "/=", "//=", "%=", "^=", "..="}

# Binary operator priorities (left, right), as in Luau's parser.
BINARY = {
    "+": (6, 6), "-": (6, 6), "*": (7, 7), "/": (7, 7), "//": (7, 7), "%": (7, 7),
    "^": (10, 9), "..": (5, 4), "==": (3, 3), "~=": (3, 3), "<": (3, 3), "<=": (3, 3),
    ">": (3, 3), ">=": (3, 3), "and": (2, 2), "or": (1, 1),
}
UNARY_PRIORITY = 8

GLOBALS = {
    # Luau
    "assert", "error", "getmetatable", "ipairs", "next", "newproxy", "pairs", "pcall", "print",
    "rawequal", "rawget", "rawlen", "rawset", "require", "select", "setmetatable", "tonumber",
    "tostring", "type", "typeof", "unpack", "xpcall", "gcinfo", "collectgarbage", "_G", "_VERSION",
    "math", "string", "table", "coroutine", "os", "debug", "utf8", "bit32", "buffer", "vector",
    # Roblox
    "game", "workspace", "script", "plugin", "shared", "task", "warn", "tick", "time",
    "elapsedTime", "settings", "UserSettings", "version", "wait", "delay", "spawn", "stats",
    "Enum", "Instance", "Vector3", "Vector2", "CFrame", "Color3", "ColorSequence",
    "ColorSequenceKeypoint", "NumberSequence", "NumberSequenceKeypoint", "NumberRange", "UDim",
    "UDim2", "Ray", "Region3", "Rect", "BrickColor", "TweenInfo", "RaycastParams",
    "OverlapParams", "PhysicalProperties", "Random", "DateTime", "Faces", "Axes", "Font",
    "PathWaypoint", "Vector3int16", "Vector2int16", "Region3int16", "SharedTable", "Content",
    "Path2DControlPoint", "RotationCurveKey", "FloatCurveKey", "CatalogSearchParams",
}
DEPRECATED_GLOBALS = {"wait", "delay", "spawn", "unpack"}

LIBRARIES = {
    "math": "abs acos asin atan atan2 ceil clamp cos cosh deg exp floor fmod frexp huge ldexp lerp "
            "log log10 map max min modf noise pi pow rad random randomseed round sign sin sinh sqrt "
            "tan tanh isnan isinf isfinite",
    "string": "byte char find format gmatch gsub len lower match pack packsize rep reverse split sub "
              "unpack upper",
    "table": "clear clone concat create find foreach foreachi freeze getn insert isfrozen maxn move "
             "pack remove sort unpack",
    "task": "cancel defer delay desynchronize spawn synchronize wait",
    "os": "clock date difftime time",
    "coroutine": "close create isyieldable resume running status wrap yield",
    "utf8": "char charpattern codepoint codes graphemes len nfcnormalize nfdnormalize offset",
    "bit32": "arshift band bnot bor btest bxor byteswap countlz countrz extract lrotate lshift "
             "replace rrotate rshift",
    "debug": "dumpcodesize info profilebegin profileend resetmemorycategory setmemorycategory "
             "traceback",
    "buffer": "copy create fill fromstring len readbits readf32 readf64 readi16 readi32 readi8 readstring "
              "readu16 readu32 readu8 tostring writebits writef32 writef64 writei16 writei32 writei8 "
              "writestring writeu16 writeu32 writeu8",
    "Vector3": "new zero one xAxis yAxis zAxis FromNormalId FromAxis",
    "Vector2": "new zero one xAxis yAxis",
    "CFrame": "new lookAt lookAlong fromMatrix fromAxisAngle fromEulerAngles fromEulerAnglesXYZ "
              "fromEulerAnglesYXZ Angles fromOrientation identity",
    "Color3": "new fromRGB fromHSV fromHex toHSV",
    "UDim": "new",
    "UDim2": "new fromScale fromOffset",
    "Instance": "new fromExisting",
    "ColorSequence": "new", "ColorSequenceKeypoint": "new", "NumberSequence": "new",
    "NumberSequenceKeypoint": "new", "NumberRange": "new", "TweenInfo": "new",
    "RaycastParams": "new", "OverlapParams": "new", "Random": "new", "Ray": "new",
    "Region3": "new", "Rect": "new", "PhysicalProperties": "new",
    "BrickColor": "new random palette White Gray DarkGray Black Red Yellow Green Blue",
    "DateTime": "now fromUnixTimestamp fromUnixTimestampMillis fromUniversalTime fromLocalTime "
                "fromIsoDate",
    "Font": "new fromEnum fromName fromId",
}
LIBRARIES = {k: set(v.split()) for k, v in LIBRARIES.items()}

BUILTIN_TYPES = {
    "any", "unknown", "never", "nil", "number", "string", "boolean", "thread", "buffer",
    "vector", "userdata", "table", "RBXScriptSignal", "RBXScriptConnection", "RaycastResult",
}


class LuauError(Exception):
    def __init__(self, line, message):
        super().__init__(message)
        self.line = line
        self.message = message


# ---------------------------------------------------------------------------------------------
# Lexer
# ---------------------------------------------------------------------------------------------

class Token:
    __slots__ = ("kind", "value", "line")

    def __init__(self, kind, value, line):
        self.kind = kind  # name, keyword, number, string, interp_begin, interp_mid, interp_end, symbol, eof
        self.value = value
        self.line = line

    def __repr__(self):
        return f"{self.kind}:{self.value!r}@{self.line}"


NUMBER_RE = re.compile(
    r"0[xX][0-9a-fA-F_]+|0[bB][01_]+|(?:[0-9][0-9_]*(?:\.[0-9_]*)?|\.[0-9][0-9_]*)(?:[eE][+-]?[0-9_]+)?")
NAME_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def long_bracket(src, i):
    """If src[i:] starts a long bracket [[ or [==[, return (level, index after it)."""
    m = re.compile(r"\[(=*)\[").match(src, i)
    if not m:
        return None
    return len(m.group(1)), m.end()


def tokenize(src):
    tokens = []
    i, line, n = 0, 1, len(src)
    brace_stack = []  # for string interpolation: True marks a brace that opened an interpolation

    def read_string_body(start, quote):
        nonlocal line
        j = start
        while j < n:
            c = src[j]
            if c == "\\":
                if j + 1 < n and src[j + 1] == "\n":
                    line += 1
                j += 2
                continue
            if c == "\n":
                raise LuauError(line, "unfinished string")
            if c == quote:
                return j + 1
            j += 1
        raise LuauError(line, "unfinished string")

    def read_interp(start):
        """Read interpolated string text from start until '{' or '`'. Returns (end, kind)."""
        nonlocal line
        j = start
        while j < n:
            c = src[j]
            if c == "\\":
                if j + 1 < n and src[j + 1] == "\n":
                    line += 1
                j += 2
                continue
            if c == "\n":
                raise LuauError(line, "unfinished interpolated string")
            if c == "`":
                return j + 1, "end"
            if c == "{":
                if j + 1 < n and src[j + 1] == "{":
                    raise LuauError(line, "double braces in an interpolated string; escape them with \\{")
                return j + 1, "brace"
            j += 1
        raise LuauError(line, "unfinished interpolated string")

    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if c in " \t\r\f\v":
            i += 1
            continue
        if src.startswith("--", i):
            lb = long_bracket(src, i + 2)
            if lb:
                level, j = lb
                close = "]" + "=" * level + "]"
                k = src.find(close, j)
                if k < 0:
                    raise LuauError(line, "unfinished long comment")
                line += src.count("\n", i, k)
                i = k + len(close)
            else:
                k = src.find("\n", i)
                i = n if k < 0 else k
            continue
        start_line = line
        if c.isalpha() or c == "_":
            m = NAME_RE.match(src, i)
            word = m.group(0)
            tokens.append(Token("keyword" if word in KEYWORDS else "name", word, start_line))
            i = m.end()
            continue
        if c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            m = NUMBER_RE.match(src, i)
            tokens.append(Token("number", m.group(0), start_line))
            i = m.end()
            if i < n and (src[i].isalnum() or src[i] == "_"):
                raise LuauError(line, f"malformed number near '{m.group(0)}{src[i]}'")
            continue
        if c in "\"'":
            j = read_string_body(i + 1, c)
            tokens.append(Token("string", src[i + 1:j - 1], start_line))
            i = j
            continue
        if c == "[":
            lb = long_bracket(src, i)
            if lb:
                level, j = lb
                close = "]" + "=" * level + "]"
                k = src.find(close, j)
                if k < 0:
                    raise LuauError(line, "unfinished long string")
                line += src.count("\n", i, k)
                tokens.append(Token("string", src[j:k], start_line))
                i = k + len(close)
                continue
        if c == "`":
            j, kind = read_interp(i + 1)
            if kind == "end":
                tokens.append(Token("string", src[i + 1:j - 1], start_line))
            else:
                tokens.append(Token("interp_begin", src[i + 1:j - 1], start_line))
                brace_stack.append(True)
            i = j
            continue
        if c == "{":
            brace_stack.append(False)
            tokens.append(Token("symbol", "{", start_line))
            i += 1
            continue
        if c == "}":
            if brace_stack and brace_stack[-1]:
                brace_stack.pop()
                j, kind = read_interp(i + 1)
                if kind == "end":
                    tokens.append(Token("interp_end", src[i + 1:j - 1], start_line))
                else:
                    tokens.append(Token("interp_mid", src[i + 1:j - 1], start_line))
                    brace_stack.append(True)
                i = j
                continue
            if brace_stack:
                brace_stack.pop()
            tokens.append(Token("symbol", "}", start_line))
            i += 1
            continue
        for sym in SYMBOLS:
            if src.startswith(sym, i):
                tokens.append(Token("symbol", sym, start_line))
                i += len(sym)
                break
        else:
            raise LuauError(line, f"unexpected character '{c}'")
    tokens.append(Token("eof", None, line))
    return tokens


# ---------------------------------------------------------------------------------------------
# Expression descriptors used by the checks
# ---------------------------------------------------------------------------------------------

class Expr:
    """A light description of an expression: enough for the API and module checks."""
    __slots__ = ("kind", "line", "name", "obj", "key", "args", "value", "vtype", "var")

    def __init__(self, kind, line, **kw):
        self.kind = kind  # name, index, call, method, string, number, table, function, other, ...
        self.line = line
        self.name = kw.get("name")
        self.obj = kw.get("obj")
        self.key = kw.get("key")
        self.args = kw.get("args")
        self.value = kw.get("value")
        self.vtype = kw.get("vtype")  # inferred type descriptor, see Checker.type_of
        self.var = kw.get("var")


class Var:
    __slots__ = ("name", "line", "used", "vtype", "kind", "fields")

    def __init__(self, name, line, kind="local"):
        self.name = name
        self.line = line
        self.used = False
        self.vtype = None
        self.kind = kind  # local, param, loop, function, self
        self.fields = None


class Scope:
    def __init__(self, parent, is_function=False, vararg=False):
        self.parent = parent
        self.vars = {}
        self.is_function = is_function
        self.vararg = vararg
        self.types = set()
        self.declared = []

    def lookup(self, name):
        s = self
        while s:
            if name in s.vars:
                return s.vars[name]
            s = s.parent
        return None

    def has_type(self, name):
        s = self
        while s:
            if name in s.types:
                return True
            s = s.parent
        return False

    def has_vararg(self):
        s = self
        while s:
            if s.is_function:
                return s.vararg
            s = s.parent
        return True  # main chunk


# ---------------------------------------------------------------------------------------------
# Parser with checks
# ---------------------------------------------------------------------------------------------

class Parser:
    def __init__(self, tokens, checker, path):
        self.t = tokens
        self.p = 0
        self.c = checker
        self.path = path
        self.scope = Scope(None, is_function=True, vararg=True)
        self.module_table = None  # name of the local the chunk returns
        self.returned = None
        self.loop_depth = 0
        self.self_fields = {}  # types of self.<field> values assigned in this file

    # -- token helpers --
    @property
    def tok(self):
        return self.t[self.p]

    def peek(self, k=1):
        return self.t[min(self.p + k, len(self.t) - 1)]

    def next(self):
        tok = self.t[self.p]
        self.p += 1
        return tok

    def check(self, value, kind=None):
        tok = self.tok
        if kind and tok.kind != kind:
            return False
        return tok.value == value and tok.kind in ("symbol", "keyword")

    def accept(self, value):
        if self.check(value):
            return self.next()
        return None

    def expect(self, value, opener=None):
        if self.check(value):
            return self.next()
        where = f" to close '{opener[0]}' at line {opener[1]}" if opener else ""
        raise LuauError(self.tok.line, f"expected '{value}'{where}, got {self.describe(self.tok)}")

    def expect_name(self):
        tok = self.tok
        if tok.kind != "name":
            raise LuauError(tok.line, f"expected a name, got {self.describe(tok)}")
        return self.next()

    @staticmethod
    def describe(tok):
        if tok.kind == "eof":
            return "end of file"
        return f"'{tok.value}'"

    def is_name(self, value=None):
        return self.tok.kind == "name" and (value is None or self.tok.value == value)

    # -- scopes --
    def push(self, is_function=False, vararg=False):
        self.scope = Scope(self.scope, is_function, vararg)
        return self.scope

    def pop(self):
        s = self.scope
        for var in s.declared:
            if not var.used and not var.name.startswith("_") and var.kind in ("local", "function"):
                self.c.report(self.path, var.line, "warning", f"unused local '{var.name}'")
        self.scope = s.parent

    def declare(self, name, line, kind="local"):
        var = Var(name, line, kind)
        self.scope.vars[name] = var
        self.scope.declared.append(var)
        return var

    def reference(self, name, line, write=False):
        var = self.scope.lookup(name)
        if var:
            if not write:
                var.used = True
            return var
        if name not in GLOBALS:
            if write:
                self.c.report(self.path, line, "error", f"assignment to undeclared global '{name}' (missing 'local'?)")
            else:
                self.c.report(self.path, line, "error", f"unknown global '{name}'")
        elif name in DEPRECATED_GLOBALS:
            self.c.report(self.path, line, "warning", f"'{name}' is deprecated; use the task library or table.unpack")
        return None

    # -- chunk --
    def parse_chunk(self):
        self.block()
        if self.tok.kind != "eof":
            raise LuauError(self.tok.line, f"unexpected {self.describe(self.tok)}")
        self.pop_main()

    def pop_main(self):
        s = self.scope
        for var in s.declared:
            if not var.used and not var.name.startswith("_") and var.kind in ("local", "function"):
                self.c.report(self.path, var.line, "warning", f"unused local '{var.name}'")

    def block_follow(self):
        tok = self.tok
        if tok.kind == "eof":
            return True
        return tok.kind == "keyword" and tok.value in ("end", "else", "elseif", "until")

    def block(self):
        while not self.block_follow():
            if self.check("return"):
                self.return_stat()
                break
            if self.is_name("continue") and self.continue_follows():
                line = self.next().line
                if self.loop_depth == 0:
                    raise LuauError(line, "'continue' outside a loop")
                self.accept(";")
                if not self.block_follow():
                    raise LuauError(self.tok.line, "'continue' must be the last statement in a block")
                break
            if self.check("break"):
                line = self.next().line
                if self.loop_depth == 0:
                    raise LuauError(line, "'break' outside a loop")
                self.accept(";")
                if not self.block_follow():
                    raise LuauError(self.tok.line, "'break' must be the last statement in a block")
                break
            self.statement()
            self.accept(";")

    def continue_follows(self):
        nxt = self.peek()
        if nxt.kind == "symbol" and nxt.value in {"(", ".", "[", ":", "{", ",", "="} | COMPOUND_OPS:
            return False
        if nxt.kind in ("string", "interp_begin"):
            return False
        return True

    def return_stat(self):
        line = self.next().line
        exprs = []
        if not self.block_follow() and not self.check(";"):
            exprs = self.explist()
        self.accept(";")
        if not self.block_follow():
            raise LuauError(self.tok.line, "'return' must be the last statement in a block")
        if self.scope.parent is None:
            self.returned = exprs[0] if exprs else None
        return line

    # -- statements --
    def statement(self):
        tok = self.tok
        line = tok.line
        if tok.kind == "keyword":
            v = tok.value
            if v == "if":
                self.next()
                self.expr()
                self.expect("then")
                self.scoped_block()
                while self.check("elseif"):
                    self.next()
                    self.expr()
                    self.expect("then")
                    self.scoped_block()
                if self.accept("else"):
                    self.scoped_block()
                self.expect("end", ("if", line))
                return
            if v == "while":
                self.next()
                self.expr()
                self.expect("do")
                self.loop_depth += 1
                self.scoped_block()
                self.loop_depth -= 1
                self.expect("end", ("while", line))
                return
            if v == "do":
                self.next()
                self.scoped_block()
                self.expect("end", ("do", line))
                return
            if v == "for":
                self.for_stat()
                return
            if v == "repeat":
                self.next()
                self.loop_depth += 1
                self.push()
                self.block()
                self.loop_depth -= 1
                self.expect("until", ("repeat", line))
                self.expr()  # evaluated inside the loop's scope
                self.pop()
                return
            if v == "function":
                self.function_stat()
                return
            if v == "local":
                self.local_stat()
                return
            raise LuauError(line, f"unexpected {self.describe(tok)}")
        if tok.kind == "symbol" and tok.value == "@":
            self.attributes()
            self.statement()
            return
        if tok.kind == "name":
            if tok.value == "type" and self.peek().kind == "name":
                self.type_alias()
                return
            if tok.value == "type" and self.peek().kind == "keyword" and self.peek().value == "function":
                self.next()
                self.function_stat()
                return
            if tok.value == "export" and self.peek().kind == "name" and self.peek().value == "type":
                self.next()
                self.type_alias()
                return
        self.expr_stat()

    def attributes(self):
        while self.accept("@"):
            self.expect_name()

    def scoped_block(self):
        self.push()
        self.block()
        self.pop()

    def for_stat(self):
        line = self.next().line
        first = self.expect_name()
        first_type = None
        if self.accept(":"):
            first_type = self.type_expr()
        if self.accept("="):
            self.expr()
            self.expect(",")
            self.expr()
            if self.accept(","):
                self.expr()
            self.expect("do")
            self.loop_depth += 1
            self.push()
            var = self.declare(first.value, first.line, "loop")
            var.vtype = first_type
            self.block()
            self.pop()
            self.loop_depth -= 1
            self.expect("end", ("for", line))
            return
        names = [(first, first_type)]
        while self.accept(","):
            name = self.expect_name()
            t = self.type_expr() if self.accept(":") else None
            names.append((name, t))
        self.expect("in")
        iters = self.explist()
        self.expect("do")
        self.loop_depth += 1
        self.push()
        for k, (name, t) in enumerate(names):
            var = self.declare(name.value, name.line, "loop")
            var.vtype = t
            if k == 1 and t is None and iters:
                var.vtype = self.c.element_type(iters[0])
        self.block()
        self.pop()
        self.loop_depth -= 1
        self.expect("end", ("for", line))

    def function_stat(self):
        line = self.next().line
        name = self.expect_name()
        var = self.scope.lookup(name.value)
        if var:
            var.used = True
        elif self.check(".") or self.check(":"):
            self.reference(name.value, name.line)
        target = Expr("name", name.line, name=name.value, var=var)
        is_method = False
        path = [name.value]
        while self.check(".") or self.check(":"):
            sep = self.next().value
            field = self.expect_name()
            path.append(field.value)
            if var and var.fields is not None:
                var.fields.add(field.value)
            target = Expr("index", field.line, obj=target, key=field.value)
            if sep == ":":
                is_method = True
                break
        if len(path) == 1:
            if var is None:
                self.c.report(self.path, name.line, "warning", f"global function '{name.value}' (use 'local function')")
        self.function_body(line, is_method, owner=var)

    def local_stat(self):
        self.next()
        if self.check("function"):
            line = self.next().line
            name = self.expect_name()
            var = self.declare(name.value, name.line, "function")
            var.vtype = ("function",)
            self.function_body(line, False)
            return
        if self.check("@"):
            self.attributes()
            return self.local_stat_function_after_attributes()
        names = []
        while True:
            name = self.expect_name()
            t = None
            if self.accept("<"):
                self.expect_name()  # <const> / <close> attribute
                self.expect(">")
            if self.accept(":"):
                t = self.type_expr()
            names.append((name, t))
            if not self.accept(","):
                break
        exprs = []
        if self.accept("="):
            exprs = self.explist()
        for k, (name, t) in enumerate(names):
            var = self.declare(name.value, name.line, "local")
            if t is not None:
                var.vtype = t
            elif k < len(exprs):
                var.vtype = exprs[k].vtype
                if exprs[k].kind == "table":
                    var.fields = set(exprs[k].value or ())
                    var.vtype = ("table", var.fields)

    def local_stat_function_after_attributes(self):
        self.expect("function")
        name = self.expect_name()
        self.declare(name.value, name.line, "function")
        self.function_body(name.line, False)

    def expr_stat(self):
        line = self.tok.line
        nxt = self.peek()
        if self.tok.kind == "name" and nxt.kind == "symbol" and nxt.value in ("=", ","):
            name = self.next()
            var = self.scope.lookup(name.value)
            if var is None:
                if name.value in GLOBALS:
                    self.c.report(self.path, name.line, "error", f"assignment to built-in global '{name.value}'")
                else:
                    self.c.report(self.path, name.line, "error",
                                  f"assignment to undeclared global '{name.value}' (missing 'local'?)")
            first = Expr("name", name.line, name=name.value, var=var or False)
        else:
            first = self.suffixed_expr()
        if self.check("=") or self.check(","):
            targets = [first]
            while self.accept(","):
                targets.append(self.suffixed_expr())
            self.expect("=")
            values = self.explist()
            for k, target in enumerate(targets):
                self.assign(target, values[k] if k < len(values) else None)
            return
        if self.tok.kind == "symbol" and self.tok.value in COMPOUND_OPS:
            self.next()
            self.expr()
            if first.kind not in ("name", "index"):
                raise LuauError(line, "the left side of a compound assignment must be a variable or field")
            if first.kind == "name" and first.var:
                first.var.used = True
            return
        if first.kind not in ("call", "method"):
            raise LuauError(line, "syntax error: expected an assignment or a function call")

    def assign(self, target, value):
        if target.kind == "name":
            return
        if target.kind == "index":
            obj = target.obj
            if obj.kind == "name" and obj.name == "self" and target.key and value is not None and value.vtype:
                self.self_fields.setdefault(target.key, value.vtype)
            self.c.check_write(self.path, target, value)
            return
        raise LuauError(target.line, "cannot assign to this expression")

    # -- function bodies --
    def function_body(self, line, is_method, owner=None):
        self.push(is_function=True)
        if is_method:
            var = self.declare("self", line, "self")
            var.used = True
            if owner is not None:
                var.vtype = ("instance_of", owner)
        if self.accept("<"):
            self.generic_list()
        self.expect("(")
        vararg = False
        if not self.check(")"):
            while True:
                if self.check("..."):
                    self.next()
                    vararg = True
                    if self.accept(":"):
                        self.return_type_or_pack()
                    break
                name = self.expect_name()
                t = self.type_expr() if self.accept(":") else None
                var = self.declare(name.value, name.line, "param")
                var.vtype = t
                if not self.accept(","):
                    break
        self.expect(")")
        self.scope.vararg = vararg
        if self.accept(":"):
            self.return_type_or_pack()
        saved_loop = self.loop_depth
        self.loop_depth = 0
        self.block()
        self.loop_depth = saved_loop
        self.expect("end", ("function", line))
        self.pop()

    def generic_list(self):
        while True:
            name = self.expect_name()
            self.scope.types.add(name.value)
            self.accept("...")
            if self.accept("="):
                self.type_expr()
            if not self.accept(","):
                break
        self.expect(">")

    # -- types --
    def type_alias(self):
        self.next()  # 'type'
        name = self.expect_name()
        self.scope.types.add(name.value)
        self.push()
        if self.accept("<"):
            self.generic_list()
        self.expect("=")
        self.type_expr()
        self.pop()

    def return_type_or_pack(self):
        if self.check("("):
            return self.type_expr()
        if self.check("..."):
            self.next()
            return self.type_expr()
        if self.tok.kind == "name" and self.peek().kind == "symbol" and self.peek().value == "...":
            self.next()
            self.next()
            return None
        return self.type_expr()

    def type_expr(self):
        self.accept("|") or self.accept("&")
        t = self.simple_type()
        while True:
            if self.accept("?"):
                t = ("optional", t)
                continue
            if self.accept("|") or self.accept("&"):
                self.simple_type()
                t = None
                continue
            break
        return t

    def simple_type(self):
        tok = self.tok
        if tok.kind == "keyword" and tok.value in ("nil", "true", "false"):
            self.next()
            return None
        if tok.kind == "string":
            self.next()
            return None
        if tok.kind == "name":
            if tok.value == "typeof" and self.peek().kind == "symbol" and self.peek().value == "(":
                self.next()
                self.next()
                self.expr()
                self.expect(")")
                return None
            self.next()
            name = tok.value
            if self.accept("."):
                member = self.expect_name()
                if name == "Enum":
                    self.c.check_enum(self.path, member.line, member.value, None)
                    name = None
                else:
                    var = self.scope.lookup(name)
                    if var:
                        var.used = True
                    name = None
            elif self.tok.kind == "symbol" and self.tok.value == "...":
                self.next()
                return None
            else:
                self.check_type_name(name, tok.line)
            if self.accept("<"):
                if not self.check(">"):
                    while True:
                        if self.check("("):
                            self.type_expr()
                        elif self.check("..."):
                            self.next()
                            self.type_expr()
                        else:
                            self.type_expr()
                        if not self.accept(","):
                            break
                self.expect(">")
            return ("class", name) if name else None
        if self.check("{"):
            open_line = self.next().line
            if self.check("}"):
                self.next()
                return None
            # array type {T} or table type with properties/indexer
            if not (self.check("[") or (self.tok.kind == "name" and self.peek().kind == "symbol"
                                         and self.peek().value == ":")
                    or (self.is_name("read") or self.is_name("write")) and self.peek().kind == "name"):
                self.type_expr()
                self.expect("}", ("{", open_line))
                return None
            while not self.check("}"):
                if self.is_name("read") or self.is_name("write"):
                    if self.peek().kind == "name" or (self.peek().kind == "symbol" and self.peek().value == "["):
                        self.next()
                if self.accept("["):
                    self.type_expr()
                    self.expect("]")
                    self.expect(":")
                    self.type_expr()
                else:
                    if self.tok.kind not in ("name", "keyword"):
                        raise LuauError(self.tok.line, f"expected a table type field, got {self.describe(self.tok)}")
                    self.next()
                    self.expect(":")
                    self.type_expr()
                if not (self.accept(",") or self.accept(";")):
                    break
            self.expect("}", ("{", open_line))
            return None
        if self.check("(") or self.check("<"):
            if self.accept("<"):
                self.push()
                self.generic_list()
            else:
                self.push()
            open_line = self.expect("(").line
            if not self.check(")"):
                while True:
                    if self.check("..."):
                        self.next()
                        self.type_expr()
                    elif self.tok.kind == "name" and self.peek().kind == "symbol" and self.peek().value == ":":
                        self.next()
                        self.next()
                        self.type_expr()
                    elif self.tok.kind == "name" and self.peek().kind == "symbol" and self.peek().value == "...":
                        self.next()
                        self.next()
                    else:
                        self.type_expr()
                    if not self.accept(","):
                        break
            self.expect(")", ("(", open_line))
            result = None
            if self.accept("->"):
                self.return_type_or_pack()
                result = ("function",)
            self.pop()
            return result
        raise LuauError(tok.line, f"expected a type, got {self.describe(tok)}")

    def check_type_name(self, name, line):
        if name in BUILTIN_TYPES or self.scope.has_type(name):
            return
        if self.c.api and (name in self.c.classes or name in self.c.datatypes):
            return
        if not self.c.api and name[:1].isupper():
            return
        if name in LIBRARIES or name in ("Instance", "Enum", "EnumItem"):
            return
        self.c.report(self.path, line, "warning", f"unknown type '{name}'")

    # -- expressions --
    def explist(self):
        exprs = [self.expr()]
        while self.accept(","):
            exprs.append(self.expr())
        return exprs

    def expr(self, limit=0):
        tok = self.tok
        if (tok.kind == "keyword" and tok.value == "not") or (tok.kind == "symbol" and tok.value in ("-", "#")):
            self.next()
            self.expr(UNARY_PRIORITY)
            left = Expr("other", tok.line, vtype=("number",) if tok.value == "#" else None)
        else:
            left = self.simple_expr()
        while True:
            op = self.tok
            key = op.value if op.kind in ("symbol", "keyword") else None
            if key not in BINARY or BINARY[key][0] <= limit:
                break
            self.next()
            right = self.expr(BINARY[key][1])
            vtype = None
            if key == "and":
                vtype = right.vtype  # 'a and b' is b whenever a is set
            elif key == "or":
                vtype = left.vtype or right.vtype
            left = Expr("other", op.line, vtype=vtype)
        return left

    def simple_expr(self):
        tok = self.tok
        e = None
        if tok.kind == "number":
            self.next()
            e = Expr("number", tok.line, value=tok.value, vtype=("number",))
        elif tok.kind == "string":
            self.next()
            e = Expr("string", tok.line, value=tok.value, vtype=("string",))
        elif tok.kind == "interp_begin":
            self.next()
            while True:
                self.expr()
                if self.tok.kind == "interp_mid":
                    self.next()
                    continue
                if self.tok.kind == "interp_end":
                    self.next()
                    break
                raise LuauError(self.tok.line, "malformed interpolated string")
            e = Expr("other", tok.line, vtype=("string",))
        elif tok.kind == "keyword" and tok.value in ("nil", "true", "false"):
            self.next()
            e = Expr("other", tok.line)
        elif tok.kind == "symbol" and tok.value == "...":
            self.next()
            if not self.scope.has_vararg():
                raise LuauError(tok.line, "'...' used in a function that doesn't take '...'")
            e = Expr("other", tok.line)
        elif tok.kind == "symbol" and tok.value == "{":
            e = self.table_constructor()
        elif tok.kind == "keyword" and tok.value == "function":
            line = self.next().line
            self.function_body(line, False)
            e = Expr("function", line, vtype=("function",))
        elif tok.kind == "symbol" and tok.value == "@":
            self.attributes()
            line = self.expect("function").line
            self.function_body(line, False)
            e = Expr("function", line, vtype=("function",))
        elif tok.kind == "keyword" and tok.value == "if":
            line = self.next().line
            self.expr()
            self.expect("then")
            a = self.expr()
            while self.accept("elseif"):
                self.expr()
                self.expect("then")
                self.expr()
            self.expect("else", ("if", line))
            b = self.expr()
            e = Expr("other", line, vtype=a.vtype or b.vtype)
        else:
            e = self.suffixed_expr()
        if self.accept("::"):
            t = self.type_expr()
            e = Expr("other", e.line, vtype=t)
        return e

    def table_constructor(self):
        open_line = self.expect("{").line
        keys = []
        while not self.check("}"):
            if self.check("["):
                self.next()
                self.expr()
                self.expect("]")
                self.expect("=")
                self.expr()
            elif self.tok.kind == "name" and self.peek().kind == "symbol" and self.peek().value == "=":
                keys.append((self.next().value, None))
                self.next()
                value = self.expr()
                keys[-1] = (keys[-1][0], value)
            else:
                self.expr()
            if not (self.accept(",") or self.accept(";")):
                break
        self.expect("}", ("{", open_line))
        e = Expr("table", open_line, value=[k for k, _ in keys])
        e.args = keys
        return e

    def primary_expr(self):
        tok = self.tok
        if tok.kind == "name":
            self.next()
            var = self.reference(tok.value, tok.line)
            vtype = var.vtype if var else self.c.global_type(tok.value, self.path)
            return Expr("name", tok.line, name=tok.value, var=var, vtype=vtype)
        if tok.kind == "symbol" and tok.value == "(":
            self.next()
            inner = self.expr()
            self.expect(")", ("(", tok.line))
            return Expr("paren", tok.line, obj=inner, vtype=inner.vtype)
        raise LuauError(tok.line, f"unexpected {self.describe(tok)}")

    def suffixed_expr(self):
        e = self.primary_expr()
        while True:
            tok = self.tok
            if tok.kind == "symbol" and tok.value == ".":
                self.next()
                name = self.expect_name()
                obj = e
                e = self.c.index(self.path, Expr("index", name.line, obj=e, key=name.value))
                if e.vtype is None and obj.kind == "name" and obj.name == "self":
                    e.vtype = self.self_fields.get(name.value)
            elif tok.kind == "symbol" and tok.value == "[":
                self.next()
                key = self.expr()
                self.expect("]", ("[", tok.line))
                e = Expr("index", tok.line, obj=e, key=key.value if key.kind == "string" else None)
                e.vtype = None
            elif tok.kind == "symbol" and tok.value == ":":
                self.next()
                name = self.expect_name()
                args = self.call_args(e.line)
                e = self.c.method_call(self.path, Expr("method", name.line, obj=e, key=name.value, args=args), self)
            elif (tok.kind == "symbol" and tok.value in ("(", "{")) or tok.kind in ("string", "interp_begin"):
                if tok.kind == "symbol" and tok.value == "(" and tok.line != self.t[self.p - 1].line:
                    raise LuauError(tok.line, "ambiguous syntax: a '(' at the start of a line continues the "
                                              "previous line as a function call; add ';' or join the lines")
                args = self.call_args(e.line)
                e = self.c.call(self.path, Expr("call", tok.line, obj=e, args=args), self)
            else:
                return e

    def call_args(self, line):
        tok = self.tok
        if tok.kind == "string":
            self.next()
            return [Expr("string", tok.line, value=tok.value, vtype=("string",))]
        if tok.kind == "interp_begin":
            return [self.simple_expr()]
        if tok.kind == "symbol" and tok.value == "{":
            return [self.table_constructor()]
        self.expect("(")
        args = []
        if not self.check(")"):
            args = self.explist()
        self.expect(")", ("(", tok.line))
        return args


# ---------------------------------------------------------------------------------------------
# Checker: Roblox API, instance tree and modules
# ---------------------------------------------------------------------------------------------

class Checker:
    def __init__(self, api_path):
        self.findings = []
        self.api = None
        self.classes = {}
        self.enums = {}
        self.datatypes = {
            "Vector3", "Vector2", "CFrame", "Color3", "UDim", "UDim2", "Ray", "Region3", "Rect",
            "BrickColor", "TweenInfo", "RaycastParams", "OverlapParams", "PhysicalProperties",
            "Random", "DateTime", "Font", "NumberRange", "NumberSequence", "ColorSequence",
            "NumberSequenceKeypoint", "ColorSequenceKeypoint", "Faces", "Axes", "EnumItem",
            "RBXScriptSignal", "RBXScriptConnection", "RaycastResult", "Content", "Vector3int16",
        }
        if api_path:
            self.api = json.loads(pathlib.Path(api_path).read_text())
            for c in self.api["Classes"]:
                self.classes[c["Name"]] = c
            for e in self.api["Enums"]:
                self.enums[e["Name"]] = {item["Name"] for item in e["Items"]}
        self.tree = {}      # instance path tuple -> {"class": ..., "file": path or None}
        self.modules = {}   # instance path tuple -> exported member names (None if unknown)
        self.module_objects = {}  # instance path tuple -> member names of objects from .new
        self.file_paths = {}  # file path -> instance path tuple
        self.current_instance = None
        self.stats = {}

    def count(self, what):
        self.stats[what] = self.stats.get(what, 0) + 1

    def report(self, path, line, level, message):
        self.findings.append((str(path.relative_to(ROOT)) if isinstance(path, pathlib.Path) else str(path),
                              line, level, message))

    # -- Roblox class model --
    def member(self, class_name, name):
        c = self.classes.get(class_name)
        while c:
            for m in c["Members"]:
                if m["Name"] == name:
                    return m
            c = self.classes.get(c["Superclass"])
        return None

    def is_a(self, class_name, base):
        c = self.classes.get(class_name)
        while c:
            if c["Name"] == base:
                return True
            c = self.classes.get(c["Superclass"])
        return False

    def class_type(self, vtype):
        """Class name if vtype names a concrete Roblox class we can check against."""
        if not self.api or not vtype:
            return None
        if vtype[0] == "optional":
            return self.class_type(vtype[1])
        if vtype[0] == "class" and vtype[1] in self.classes and vtype[1] != "Instance":
            return vtype[1]
        return None

    @staticmethod
    def value_type_to_vtype(value_type):
        if not value_type:
            return None
        if value_type.get("Category") == "Class":
            return ("class", value_type["Name"])
        if value_type.get("Category") == "Enum":
            return ("enum", value_type["Name"])
        if value_type.get("Category") == "DataType":
            return ("datatype", value_type["Name"])
        if value_type.get("Category") == "Primitive":
            return (value_type["Name"],)
        return None

    def global_type(self, name, path):
        if name == "workspace":
            return ("class", "Workspace")
        if name == "game":
            return ("class", "DataModel")
        if name == "script":
            return ("script",)
        if name == "Enum":
            return ("enum_root",)
        if name in LIBRARIES:
            return ("library", name)
        return None

    def check_enum(self, path, line, enum_name, item):
        if not self.api:
            return
        self.count("enum references")
        if enum_name not in self.enums:
            self.report(path, line, "error", f"Enum.{enum_name} doesn't exist")
            return
        if item is not None and item not in self.enums[enum_name]:
            self.report(path, line, "error", f"Enum.{enum_name}.{item} doesn't exist")

    def element_type(self, iter_expr):
        """Value type of a generic for loop over ipairs/pairs(x:GetChildren())."""
        return None

    # -- expressions --
    def index(self, path, e):
        obj = e.obj
        ot = obj.vtype
        if ot is None:
            return e
        kind = ot[0]
        if kind == "enum_root":
            self.check_enum(path, e.line, e.key, None)
            e.vtype = ("enum_type", e.key)
        elif kind == "enum_type":
            self.check_enum(path, e.line, ot[1], e.key)
            e.vtype = ("enum", ot[1])
        elif kind == "library":
            self.count("library members")
            members = LIBRARIES[ot[1]]
            if e.key not in members:
                self.report(path, e.line, "error", f"'{ot[1]}.{e.key}' doesn't exist")
        elif kind == "module":
            self.count("module members")
            exports = self.modules.get(ot[1])
            if exports is not None and e.key not in exports:
                self.report(path, e.line, "error", f"module '{'.'.join(ot[1])}' has no member '{e.key}'")
            if e.key in exports_with_objects(self, ot[1]):
                e.vtype = ("module_new", ot[1])
        elif kind == "module_object":
            self.count("object fields")
            members = self.module_objects.get(ot[1])
            if members is not None and e.key not in members:
                self.report(path, e.line, "error",
                            f"'{e.key}' is not a field or method of {'.'.join(ot[1][-1:])} objects")
        elif kind == "instance_path":
            node = self.tree.get(ot[1], {})
            child = ot[1] + (e.key,)
            if child in self.tree:
                e.vtype = ("instance_path", child)
            elif e.key == "Parent":
                e.vtype = ("instance_path", ot[1][:-1]) if len(ot[1]) > 1 else None
            else:
                cls = node.get("class")
                m = self.member(cls, e.key) if (self.api and cls) else None
                if m:
                    if m["MemberType"] == "Property":
                        e.vtype = self.value_type_to_vtype(m.get("ValueType"))
                    elif m["MemberType"] == "Event":
                        e.vtype = ("event", cls, e.key)
                elif self.api and cls in ("Folder", "ModuleScript", "Script", "LocalScript"):
                    self.report(path, e.line, "error", f"'{'.'.join(child)}' doesn't exist in the place")
        elif kind == "script":
            here = self.current_instance
            if e.key == "Parent":
                e.vtype = ("instance_path", here[:-1])
        else:
            cls = self.class_type(ot)
            if cls:
                self.count("Roblox property/event reads")
                m = self.member(cls, e.key)
                if m:
                    if "Deprecated" in (m.get("Tags") or []):
                        self.report(path, e.line, "warning", f"{cls}.{e.key} is deprecated")
                    security = m.get("Security") or {}
                    read = security.get("Read", "None") if isinstance(security, dict) else security
                    if read != "None" or "NotScriptable" in (m.get("Tags") or []):
                        self.report(path, e.line, "error", f"{cls}.{e.key} can't be used by game scripts")
                    if m["MemberType"] == "Property":
                        e.vtype = self.value_type_to_vtype(m.get("ValueType"))
                    elif m["MemberType"] == "Event":
                        e.vtype = ("event", cls, e.key)
                else:
                    e.vtype = ("child_of", cls, e.key)
        return e

    def check_write(self, path, target, value):
        obj = target.obj
        cls = self.class_type(obj.vtype)
        if not cls or target.key is None:
            if obj.vtype and obj.vtype[0] in ("module_object",) and target.key is not None:
                pass
            return
        self.count("Roblox property writes")
        m = self.member(cls, target.key)
        if m is None:
            self.report(path, target.line, "error", f"'{target.key}' is not a property of {cls}")
            return
        if m["MemberType"] != "Property":
            self.report(path, target.line, "error", f"{cls}.{target.key} is a {m['MemberType'].lower()}, not a property")
            return
        tags = m.get("Tags") or []
        security = m.get("Security") or {}
        if "ReadOnly" in tags:
            self.report(path, target.line, "error", f"{cls}.{target.key} is read-only")
        elif "NotScriptable" in tags:
            self.report(path, target.line, "error", f"{cls}.{target.key} can't be set by scripts")
        elif isinstance(security, dict) and security.get("Write", "None") != "None":
            self.report(path, target.line, "error",
                        f"{cls}.{target.key} can't be set by game scripts (needs {security['Write']})")
        if "Deprecated" in tags:
            self.report(path, target.line, "warning", f"{cls}.{target.key} is deprecated")
        self.check_value(path, target.line, cls, target.key, m, value)

    def check_value(self, path, line, cls, prop, member, value):
        if value is None or value.vtype is None:
            return
        want = member.get("ValueType") or {}
        got = value.vtype
        if want.get("Category") == "Enum" and got[0] == "enum" and got[1] != want["Name"]:
            self.report(path, line, "error", f"{cls}.{prop} takes Enum.{want['Name']}, got Enum.{got[1]}")

    def method_call(self, path, e, parser):
        obj = e.obj
        ot = obj.vtype
        e.vtype = None
        name = e.key
        args = e.args or []
        first = args[0] if args else None
        if ot and ot[0] == "event" and name in ("Connect", "Once", "Wait", "ConnectParallel"):
            return e
        if ot and ot[0] == "child_of" and name in ("Connect", "Once", "Wait", "ConnectParallel"):
            self.report(path, e.line, "error", f"{ot[1]}.{ot[2]} is not an event")
            return e
        if ot and ot[0] in ("instance_path", "script") and name in ("WaitForChild", "FindFirstChild"):
            base = ot[1] if ot[0] == "instance_path" else self.current_instance
            if first is not None and first.kind == "string":
                child = base + (first.value,)
                if child in self.tree:
                    e.vtype = ("instance_path", child)
                elif self.tree.get(base, {}).get("file") is not None or self.tree.get(base, {}).get("class") == "Folder":
                    self.report(path, e.line, "error", f"'{'.'.join(child)}' doesn't exist in the place")
            return e
        if ot and ot[0] == "class" and ot[1] == "DataModel" and name == "GetService":
            if first is not None and first.kind == "string":
                svc = first.value
                if self.api:
                    c = self.classes.get(svc)
                    if not c or "Service" not in (c.get("Tags") or []):
                        self.report(path, e.line, "error", f"'{svc}' is not a Roblox service")
                if (svc,) in self.tree:
                    e.vtype = ("instance_path", (svc,))
                    e.value = ("class", svc)
                else:
                    e.vtype = ("class", svc)
            return e
        if ot and ot[0] == "instance_path":
            cls = self.tree.get(ot[1], {}).get("class")
            if cls and self.api:
                m = self.member(cls, name)
                if m is None or m["MemberType"] not in ("Function", "Callback"):
                    self.report(path, e.line, "error", f"{cls} has no method '{name}'")
            return e
        if ot and ot[0] == "module_object":
            self.count("object methods")
            members = self.module_objects.get(ot[1])
            if members is not None and name not in members:
                self.report(path, e.line, "error", f"{ot[1][-1]} objects have no method '{name}'")
            return e
        if ot and ot[0] == "module":
            exports = self.modules.get(ot[1])
            if exports is not None and name not in exports:
                self.report(path, e.line, "error", f"module '{'.'.join(ot[1])}' has no member '{name}'")
            return e
        cls = self.class_type(ot)
        if cls:
            self.count("Roblox method calls")
            m = self.member(cls, name)
            if m is None:
                self.report(path, e.line, "error", f"{cls} has no method '{name}'")
            elif m["MemberType"] != "Function":
                self.report(path, e.line, "error", f"{cls}.{name} is a {m['MemberType'].lower()}, not a method")
            else:
                if "Deprecated" in (m.get("Tags") or []):
                    self.report(path, e.line, "warning", f"{cls}:{name}() is deprecated")
                if (m.get("Security") or "None") != "None":
                    self.report(path, e.line, "error", f"{cls}:{name}() can't be called by game scripts "
                                                       f"(needs {m['Security']})")
                rt = self.value_type_to_vtype(m.get("ReturnType"))
                if rt and rt[0] == "class" and rt[1] != "Instance":
                    e.vtype = rt
            if name in ("IsA", "FindFirstChildOfClass", "FindFirstChildWhichIsA", "FindFirstAncestorOfClass",
                        "FindFirstAncestorWhichIsA", "GetPropertyChangedSignal") and first is not None \
                    and first.kind == "string":
                if name == "GetPropertyChangedSignal":
                    pm = self.member(cls, first.value)
                    if pm is None or pm["MemberType"] != "Property":
                        self.report(path, e.line, "error", f"'{first.value}' is not a property of {cls}")
                    e.vtype = ("event", cls, first.value)
                elif first.value not in self.classes:
                    self.report(path, e.line, "error", f"'{first.value}' is not a Roblox class")
                elif name in ("FindFirstChildOfClass", "FindFirstChildWhichIsA", "FindFirstAncestorOfClass",
                              "FindFirstAncestorWhichIsA"):
                    e.vtype = ("optional", ("class", first.value))
        return e

    def call(self, path, e, parser):
        fn = e.obj
        args = e.args or []
        first = args[0] if args else None
        e.vtype = None
        if fn.kind == "index" and fn.obj.kind == "name" and fn.obj.name == "Instance" and fn.obj.var is None \
                and fn.key == "new":
            if first is not None and first.kind == "string":
                cls = first.value
                self.count("Instance.new classes")
                if self.api:
                    c = self.classes.get(cls)
                    if c is None:
                        self.report(path, e.line, "error", f"'{cls}' is not a Roblox class")
                    else:
                        tags = c.get("Tags") or []
                        if "NotCreatable" in tags or "Service" in tags:
                            self.report(path, e.line, "error", f"{cls} can't be created with Instance.new")
                        if "Deprecated" in tags:
                            self.report(path, e.line, "warning", f"{cls} is deprecated")
                e.vtype = ("class", cls)
            return e
        if fn.kind == "name" and fn.name == "require" and fn.var is None:
            target = first.vtype if first is not None else None
            if target and target[0] == "instance_path":
                self.count("require paths")
                node = self.tree.get(target[1])
                if node is None or node["class"] != "ModuleScript":
                    self.report(path, e.line, "error", f"require target '{'.'.join(target[1])}' is not a ModuleScript")
                else:
                    e.vtype = ("module", target[1])
            return e
        if fn.kind == "name" and fn.name == "make" and fn.var is not None and len(args) >= 2 \
                and args[0].kind == "string" and args[1].kind == "table" and self.api:
            cls = args[0].value
            if cls not in self.classes:
                self.report(path, e.line, "error", f"'{cls}' is not a Roblox class")
            else:
                for key, value in args[1].args or []:
                    target = Expr("index", e.line, obj=Expr("other", e.line, vtype=("class", cls)), key=key)
                    self.check_write(path, target, value)
                e.vtype = ("class", cls)
            return e
        if fn.vtype and fn.vtype[0] == "module_new":
            e.vtype = ("module_object", fn.vtype[1])
            return e
        if fn.kind == "name" and fn.name == "setmetatable" and fn.var is None:
            return e
        return e


def exports_with_objects(checker, module_path):
    """Constructor names of a module whose objects we track (only 'new')."""
    return {"new"} if checker.module_objects.get(module_path) is not None else set()


# ---------------------------------------------------------------------------------------------
# Place tree and module exports
# ---------------------------------------------------------------------------------------------

SERVICE_DIRS = {
    "ReplicatedStorage": ("ReplicatedStorage",),
    "ServerScriptService": ("ServerScriptService",),
    "StarterPlayer/StarterPlayerScripts": ("StarterPlayer", "StarterPlayerScripts"),
}


def class_for_file(name):
    if name.endswith(".server.luau"):
        return name[: -len(".server.luau")], "Script"
    if name.endswith(".client.luau"):
        return name[: -len(".client.luau")], "LocalScript"
    return name[: -len(".luau")], "ModuleScript"


def build_tree(checker):
    for svc in ("ReplicatedStorage", "ServerScriptService", "StarterPlayer"):
        checker.tree[(svc,)] = {"class": svc, "file": None}
    checker.tree[("StarterPlayer", "StarterPlayerScripts")] = {"class": "StarterPlayerScripts", "file": None}
    for rel, base in SERVICE_DIRS.items():
        root = SRC / rel
        for p in sorted(root.rglob("*")):
            parts = p.relative_to(root).parts
            if p.is_dir():
                checker.tree[base + parts] = {"class": "Folder", "file": None}
            elif p.suffix == ".luau":
                name, cls = class_for_file(parts[-1])
                inst = base + parts[:-1] + (name,)
                checker.tree[inst] = {"class": cls, "file": p}
                checker.file_paths[p] = inst


MODULE_FIELD_RE = re.compile(r"^function\s+([A-Za-z_]\w*)\s*[.:]\s*([A-Za-z_]\w*)", re.M)
MODULE_ASSIGN_RE = re.compile(r"^([A-Za-z_]\w*)\.([A-Za-z_]\w*)\s*=", re.M)
SELF_FIELD_RE = re.compile(r"\bself\.([A-Za-z_]\w*)\s*(?:=|\+=|-=|\*=|/=)")


def module_exports(path):
    """Member names of the table a module returns, and of objects its .new constructor makes."""
    src = path.read_text()
    m = re.search(r"^return\s+([A-Za-z_]\w*)\s*$", src, re.M)
    if not m:
        if re.search(r"^return\s*\{", src, re.M):
            body = src[re.search(r"^return\s*\{", src, re.M).end():]
            keys = set(re.findall(r"^\t([A-Za-z_]\w*)\s*=", body, re.M))
            return keys, None
        return None, None
    name = m.group(1)
    keys = {f for t, f in MODULE_FIELD_RE.findall(src) if t == name}
    keys |= {f for t, f in MODULE_ASSIGN_RE.findall(src) if t == name}
    table = re.search(rf"^local\s+{name}\s*=\s*\{{(.*?)^\}}", src, re.M | re.S)
    if table:
        keys |= set(re.findall(r"^\t([A-Za-z_]\w*)\s*=", table.group(1), re.M))
    objects = None
    if re.search(rf"^{name}\.__index\s*=\s*{name}\s*$", src, re.M):
        objects = set(keys) | set(SELF_FIELD_RE.findall(src))
    return keys, objects


# ---------------------------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--api-dump", help="path to Roblox's API-Dump.json")
    ap.add_argument("--verbose", action="store_true", help="also list warnings")
    ap.add_argument("files", nargs="*", help="files to check (default: every .luau file in src/)")
    args = ap.parse_args()

    checker = Checker(args.api_dump)
    build_tree(checker)
    for p, inst in checker.file_paths.items():
        if checker.tree[inst]["class"] == "ModuleScript":
            keys, objects = module_exports(p)
            checker.modules[inst] = keys
            if objects is not None:
                checker.module_objects[inst] = objects

    files = [pathlib.Path(f).resolve() for f in args.files] or sorted(SRC.rglob("*.luau"))
    parsed = 0
    for path in files:
        checker.current_instance = checker.file_paths.get(path, ("?",))
        try:
            tokens = tokenize(path.read_text())
            parser = Parser(tokens, checker, path)
            parser.parse_chunk()
            parsed += 1
            if checker.tree.get(checker.current_instance, {}).get("class") == "ModuleScript" and parser.returned is None:
                checker.report(path, tokens[-1].line, "error", "module doesn't return a value")
        except LuauError as err:
            checker.report(path, err.line, "error", f"syntax: {err.message}")

    errors = [f for f in checker.findings if f[2] == "error"]
    warnings = [f for f in checker.findings if f[2] == "warning"]
    shown = sorted(set(checker.findings if args.verbose else errors))
    for file, line, level, message in shown:
        print(f"{file}:{line}: {level}: {message}")
    if args.verbose:
        print("Checks run: " + ", ".join(f"{v} {k}" for k, v in sorted(checker.stats.items())))
    api = "with" if checker.api else "without"
    print(f"Checked {parsed}/{len(files)} files {api} the Roblox API dump: "
          f"{len(set(errors))} errors, {len(set(warnings))} warnings"
          + ("" if args.verbose else " (use --verbose to list warnings)"))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
