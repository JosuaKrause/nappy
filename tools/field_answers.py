#!/usr/bin/env python3
"""Lists the fields of classes under `src/` that the named files read or write, each with the method that answers it.

designing-classes' "Fields are not API": one object reaches another only through its methods. A pass that types or
converts a set of files owes the list of the other classes' fields those files still read or write, each with the
method the game calls that answers it, or "no method". This prints that list for the files named: one Markdown line
per class to paste into a pull request's description, or `--json`.

**A read** is `receiver.name` in one of the files, where the receiver's class is a class under `src/` (an inner
class included, named `Outer.Inner`) other than the file's own class, its inner classes, its ancestors and its
descendants, and `name` is a `var` that class or a class it extends declares; it is listed under the class that
declares it. An assignment or a compound assignment to it, or to an element of it (`thing.list[0] = x`), is listed
as written. A name with a call parenthesis after it is a method call and is not listed.

**The answer to a read** is a public method (no underscore) of the receiver's class or a class it extends that
returns that field and nothing else: its body is `return field`, or that behind a null guard (`return field if field
else 0`, or `if field == null:` returning a value that names no member of the class, then `return field`). Where the
field is a property whose getter is one `return`, a method returning the same expression answers it too (`is_gone()`
for `is_finished`, both `phase == Phase.DONE`). A method that returns a value worked out from the field, or from
another field, is not an answer. A yes-or-no method (`-> bool`, no parameters) whose one `return` names that field
and no other member of its class is printed after the answers as asking of it alone, with what it returns
(`is_in_the_world()` returns `live != null`), for the builder to hold against the read.

**A chain.** Where the read ends a chain of fields (`plan.def.id`) and a method of an earlier class in the chain
returns that chain (`row_id()`, whose body is `return def.id`), the read is listed once, under that earlier class,
as `def.id` with that method, and not under the last class. The longest chain a method answers wins, and the fields
before the last are listed as reads of their own as well. Two more shapes count as that chain: a method that returns
another method's answer is read through (`telegraphs_for()` returning `def.telegraphs_for()` answers
`def.telegraph_time`), and a read followed by a call the class hands on is listed as `map.start()` where the class's
own method returns `map.start()` with its parameters passed on in order.

**The answer to a write** is every public method of the class with a statement that assigns the field (`field =
value`, `field += value`, `field[key] = value`), printed with that statement.

**Call sites.** `(N calls)` after a method counts its calls under `src/` outside the file that declares it: through
a receiver of that class, through one of a class it extends that declares the method too (the call reaches the
override), or bare in a class that extends it. `+N own` counts those in its own file, and `+N untold` the calls of
that name under `src/` whose receiver's class cannot be told. A method named without its parentheses (a Callable
handed on) is not counted, so `(0 calls)` with nothing untold is a method no call under `src/` reaches.

**A receiver whose class cannot be told** is printed on a line of its own, with the file, the line and the
expression, where the name is a `var` some class under `src/` declares. Nothing is guessed for it.

**How the receiver's class is told.** By the reader of `tools/check_field_reads.py` (its `--help` says how), over
every `.gd` file outside `docs/`, and further where a test needs it and that check does not: a script with no
`class_name` is the class its file declares where a `const` preloads it or an `extends "res://..."` line names it;
an inner class is told through its outer class (`EventScheduler.Planned.new()`) and under a name that starts with an
underscore; `self` and `super` are told in a file with no `class_name`; a value awaited from a call is what the call
returns; the variable of a `for` whose head spans lines is typed from what it iterates; and a bare lowercase name
that nothing declares is unknown, not an engine property.

**Blind spots, stated.** That reader's, less the ones above: a chain through an engine property typed `Variant` is
told as an engine value, so a read behind it is not seen; `self` inside an inner class, an inherited member an inner
class reads by its bare name, and a parameter of a function whose parameter list closes at the margin are not told,
so a read through one is printed as not told. A field reached by `get()`, `set()` or a string is not seen. The
answer is read from the method's text: a method that returns the field through a local, or after any other
statement, is not an answer, and a method is not matched to a property's getter where either `return` holds a
string, whose contents are not read. Whether a method answers the read as the suite uses it (a copy where the suite
changes the field, a method that also does something else) is the builder's to read in the class.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections.abc import Mapping
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_field_reads as reads
import check_layers

ROOT = Path(__file__).resolve().parent.parent
SRC = "src/"
INNER = reads.INNER

PATH_EXTENDS = re.compile(r'^extends[ \t]+"res://([^"\n]+)"', re.MULTILINE)
FOR_HEAD = re.compile(r"^[ \t]*for[ \t]+([A-Za-z_]\w*)[ \t]+in[ \t]+", re.MULTILINE)
FUNC_HEAD = re.compile(r"^(?:static[ \t]+)?func[ \t]+([A-Za-z_]\w*)[ \t]*\(")
VAR_HEAD = re.compile(r"^(?:@\w+(?:\([^)]*\))?[ \t]+)*(?:static[ \t]+)?var[ \t]+([A-Za-z_]\w*)")
GETTER_NAMED = re.compile(r"\bget[ \t]*=[ \t]*([A-Za-z_]\w*)")
GETTER_HEAD = re.compile(r"get(?:\(\))?[ \t]*:")
ASSIGNMENT = re.compile(r"[ \t]*(=(?!=)|(?:\*\*|<<|>>|[-+*/%&|^])=)")
NEXT_CALL = re.compile(r"[ \t]*\.[ \t]*([A-Za-z_]\w*)[ \t]*\(")
CLAUSE = re.compile(r"^(?:if|elif|else|for|while)\b")
BRIEF_FILES = re.compile(r"\*\*Your files[^\n]*(?:\n(?!\s*\n)[^\n]*)*")
BRIEF_PATH = re.compile(r"`([^`\s]+\.gd)`")
RETURN = "return "
# The words a null guard may use beside the names of what it guards.
GUARD_WORDS = frozenset({"null", "not", "and", "is_instance_valid"})
DEPTH = 8

# What a method or a read comes down to: `(kind, class, name)` pieces. `field` pieces, then at most one `call` piece
# (a call handed on, named `method/arity`); or one `expr` piece alone (an expression, its spaces taken out).
Piece = tuple[str, str, str]
Value = tuple[Piece, ...]


class FieldAnswersError(Exception):
    """An input could not be read."""


class Scripts(reads.Tree):
    """Every script of the project, the tests and rigs included, and how a receiver's class is told in them: as the
    field-read check's `Tree` tells it, and further where a test needs it and the check does not (the module's
    docstring lists each)."""

    def parent_of(self, path: str) -> str | None:
        """Overrides `Tree.parent_of`: an `extends "res://..."` line names the script at that path."""
        named = super().parent_of(path)
        if named:
            return named
        by_path = PATH_EXTENDS.search(self.src[path])
        return by_path.group(1) if by_path and by_path.group(1) in self.src else None

    def script_kind(self, target: str) -> str:
        """Overrides `Tree.script_kind`: a preloaded script is the class its file declares, named or not."""
        return target if target in self.src else reads.UNTRACKED

    def first_class(self, word: str, own: str, declared: Mapping[str, str], inner: bool) -> str | None:
        """Overrides `Tree.first_class`: `self` and `super` in a file with no `class_name`, an inner class under any
        name, and a bare lowercase name nothing declares, which is unknown."""
        outer = own.split(INNER)[0]
        if word in ("self", "super") and not inner:
            return own if word == "self" else (self.files[own].parent or reads.UNTRACKED)
        if f"{outer}{INNER}{word}" in self.files and word not in declared:
            return f"{outer}{INNER}{word}"
        kind = super().first_class(word, own, declared, inner)
        known = (
            word in self.by_name
            or word in declared
            or self.member_field_type(own, word)[0]
            or word in self.preloads.get(outer, {})
        )
        return None if kind == reads.UNTRACKED and not known and not word[0].isupper() else kind

    def step(self, current: str | None, step: str, word: str) -> str | None:
        """Overrides `Tree.step`: an inner class named through its outer class."""
        if step == "field" and current is not None and f"{current}{INNER}{word}" in self.files:
            return f"{current}{INNER}{word}"
        return super().step(current, step, word)

    def infer(self, expr: str, own: str, declared: Mapping[str, str], inner: bool) -> str | None:
        """Overrides `Tree.infer`: a value awaited from a call is what the call returns; one awaited from a signal
        is unknown."""
        text = expr.strip()
        if text.startswith("await "):
            awaited = text[len("await ") :].strip()
            return super().infer(awaited, own, declared, inner) if awaited.endswith(")") else None
        return super().infer(expr, own, declared, inner)

    def collect_declared(self, path: str) -> None:
        """Overrides `Tree.collect_declared`: also the variable of an untyped `for` whose head spans lines, or is
        followed by its statement on the same line."""
        super().collect_declared(path)
        start = 0
        for index, block in enumerate(self.blocks[path]):
            inner = bool(reads.INNER_CLASS.match(block))
            for match in FOR_HEAD.finditer(block):
                if block[match.end() :].split("\n", 1)[0].rstrip().endswith(":"):
                    continue
                line = start + block.count("\n", 0, match.start())
                iterable = split_clause(reads.statement(block, match.end()))[0]
                scope = reads.Scope(self, path, index, line)
                kind = reads.iterated(self.infer(iterable, path, scope, inner))
                declared = reads.Decl(line, self.indents[path][line] or 0, kind or "", body_only=True)
                self.decls[path][index].setdefault(match.group(1), []).append(declared)
            start += block.count("\n") + 1

    def display(self, key: str) -> str:
        """The name a class is printed under: its `class_name` or autoload name, else its path; `Outer.Inner`."""
        path, _, inner = key.partition(INNER)
        outer = self.name_of.get(path, path)
        return f"{outer}.{inner}" if inner else outer

    def method_owner(self, key: str | None, name: str) -> str | None:
        """The class in `key`'s ancestry that declares method `name`."""
        if key is None or key not in self.files:
            return None
        return next((a for a in self.ancestors(key) if name in self.files[a].methods), None)

    def field_owner(self, key: str | None, name: str) -> str | None:
        """The class in `key`'s ancestry that declares var `name`."""
        return self.declaring(key, name) if key is not None and key in self.files else None


@dataclass(frozen=True)
class Method:
    """A method as its class's text declares it: its parameters' names, the return type its header declares (empty
    where it declares none), and its body as logical lines, each with its indent."""

    name: str
    params: tuple[str, ...]
    returns: str
    body: tuple[tuple[int, str], ...]


def logical_lines(text: str) -> list[tuple[int, str]]:
    """The non-blank logical lines of a block of blanked code, each with its indent: a line runs on past a line
    break while a bracket is open or it ends in a backslash."""
    out: list[tuple[int, str]] = []
    offset = 0
    while offset < len(text):
        end = offset
        depth = 0
        while end < len(text):
            char = text[end]
            if char in "([{":
                depth += 1
            elif char in ")]}":
                depth -= 1
            elif char == "\n" and depth <= 0 and not text[offset:end].rstrip(" \t").endswith("\\"):
                break
            end += 1
        raw = text[offset:end]
        joined = re.sub(r"\s+", " ", raw.replace("\\\n", " ")).strip()
        if joined:
            out.append((len(raw) - len(raw.lstrip(" \t")), joined))
        offset = end + 1
    return out


def header_end(block: str, start: int) -> int:
    """The index of the colon that ends a `func` header, from just past its parameter list, or -1."""
    depth = 0
    for index in range(start, len(block)):
        char = block[index]
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == ":" and depth == 0:
            return index
    return -1


def quoted(text: str) -> str:
    """A file's code with its comments and the contents of its strings blanked, the quotes kept, so that a string is
    still seen where it stood."""
    code = check_layers.blank(text)
    out = list(code.bare)
    for literal in code.literals:
        quote = text[literal.offset] * (3 if text.startswith(text[literal.offset] * 3, literal.offset) else 1)
        close = literal.offset + len(quote) + len(literal.text)
        for at in (literal.offset, close):
            if text.startswith(quote, at):
                out[at : at + len(quote)] = quote
    return "".join(out)


def sliced_like(bare: str, text: str) -> list[str]:
    """`text` cut into the blocks `bare`, its blanked twin, has at its margin: a string never opens a block."""
    lines = text.split("\n")
    out: list[str] = []
    at = 0
    for block in reads.blocks_of(bare):
        length = block.count("\n") + 1
        out.append("\n".join(lines[at : at + length]))
        at += length
    return out


def blocks_of_class(tree: Scripts, key: str) -> list[str]:
    """The margin blocks of a class's code, strings quoted (`quoted`): a file's, or an inner class's body with one
    indent taken off, as `Tree.text_of` gives it blanked."""
    path, _, inner = key.partition(INNER)
    blocks = sliced_like(tree.bare[path], quoted(tree.src[path]))
    if not inner:
        return blocks
    for block in blocks:
        head = reads.INNER_HEAD.match(block)
        if head and head.group(1) == inner:
            body = re.sub(r"(?m)^(?:\t|    )", "", block.partition("\n")[2])
            return sliced_like(tree.text_of(key), body)
    return []


def methods_in(blocks: list[str]) -> dict[str, Method]:
    """The methods a class's margin blocks declare."""
    out: dict[str, Method] = {}
    for block in blocks:
        head = FUNC_HEAD.match(block)
        if not head:
            continue
        close = reads.close_of(block, head.end() - 1)
        colon = header_end(block, close + 1) if close >= 0 else -1
        if colon < 0:
            continue
        params = [reads.IDENT.match(p.strip()) for p in reads.split_top(block[head.end() : close]) if p.strip()]
        first, _, rest = block[colon + 1 :].partition("\n")
        body = ([(1, first.strip())] if first.strip() else []) + logical_lines(rest)
        returns = block[close + 1 : colon].partition("->")[2].strip()
        out[head.group(1)] = Method(head.group(1), tuple(p.group() for p in params if p), returns, tuple(body))
    return out


def getters_in(blocks: list[str]) -> dict[str, str]:
    """For each property a class's margin blocks declare with a getter of one `return`, what the getter returns; a
    getter named `get = method` returns that method's call."""
    out: dict[str, str] = {}
    for block in blocks:
        head = VAR_HEAD.match(block)
        if not head:
            continue
        named = GETTER_NAMED.search(block)
        if named:
            out[head.group(1)] = f"{named.group(1)}()"
            continue
        lines = logical_lines(block.partition("\n")[2])
        for index, (indent, line) in enumerate(lines):
            if not GETTER_HEAD.match(line):
                continue
            tail = line.partition(":")[2].strip()
            inside = [tail] if tail else []
            for deeper, statement in lines[index + 1 :]:
                if deeper <= indent:
                    break
                inside.append(statement)
            if len(inside) == 1 and inside[0].startswith(RETURN):
                out[head.group(1)] = inside[0][len(RETURN) :].strip()
    return out


def names_in(text: str) -> set[str]:
    """Every identifier in a piece of blanked code, a member's name after a dot included."""
    return set(reads.IDENT.findall(text))


def split_clause(line: str) -> tuple[str, str]:
    """A line as what stands before its first colon outside brackets and what stands after it (`if cond: statement`,
    a `for`'s iterable and its colon); the whole line and nothing where it has no such colon."""
    colon = reads.top_level(line).find(":")
    return (line[:colon].strip(), line[colon + 1 :].strip()) if colon >= 0 else (line.strip(), "")


def call_arguments(chain: str) -> list[str]:
    """The text between the parentheses of each call at a postfix chain's own level, in order."""
    out: list[str] = []
    index = 0
    while index < len(chain):
        if chain[index] not in "([{":
            index += 1
            continue
        end = reads.close_of(chain, index)
        if end < 0:
            break
        if chain[index] == "(" and index > 0 and (chain[index - 1].isalnum() or chain[index - 1] == "_"):
            out.append(chain[index + 1 : end])
        index = end + 1
    return out


def passed_in(arguments: str) -> list[str]:
    """The arguments of a call, from the text between its parentheses."""
    return [a.strip() for a in reads.split_top(arguments) if a.strip()]


def assigned(rest: str) -> bool:
    """Whether the code after a name assigns it, or an element of it: subscripts, then an assignment operator."""
    index = 0
    while index < len(rest) and rest[index] in " \t[":
        if rest[index] == "[":
            index = reads.close_of(rest, index)
            if index < 0:
                return False
        index += 1
    return bool(ASSIGNMENT.match(rest, index))


def shown(code: str) -> str:
    """A piece of a class's code as it is printed: spaces collapsed, and a string, whose contents are blanked, as
    `"…"`."""
    return re.sub(r"""(["'])\s*\1""", '"…"', re.sub(r"\s+", " ", code).strip())


def is_path(value: Value | None) -> bool:
    """Whether a value is a chain of fields and nothing else, so that a longer chain can run on from it."""
    return bool(value) and all(piece[0] == "field" for piece in value or ())


class Answers:
    """What each method of a class comes down to, read from its text once: the field it returns, the chain of
    fields, the call it hands on, or the expression; and which methods assign a field. Two things that come down to
    the same value answer the same question."""

    def __init__(self, tree: Scripts) -> None:
        self.tree = tree
        self._blocks: dict[str, list[str]] = {}
        self._methods: dict[str, dict[str, Method]] = {}
        self._getters: dict[str, dict[str, str]] = {}
        self._values: dict[tuple[str, str], Value | None] = {}
        self._returning: dict[str, dict[Value, list[str]]] = {}

    def blocks(self, key: str) -> list[str]:
        if key not in self._blocks:
            self._blocks[key] = blocks_of_class(self.tree, key)
        return self._blocks[key]

    def methods(self, key: str) -> dict[str, Method]:
        if key not in self._methods:
            self._methods[key] = methods_in(self.blocks(key))
        return self._methods[key]

    def getter(self, key: str, name: str) -> str | None:
        """What the getter of property `name` of class `key` returns, where it is one `return`."""
        if key not in self._getters:
            self._getters[key] = getters_in(self.blocks(key))
        return self._getters[key].get(name)

    def members(self, key: str) -> set[str]:
        """Every var and method `key`'s class and the classes it extends declare."""
        files = self.tree.files
        return {name for a in self.tree.ancestors(key) for name in (*files[a].fields, *files[a].methods)}

    def returned(self, key: str, method: Method) -> str | None:
        """The expression a method's body returns, where the body is that `return` alone or behind a null guard: a
        guard names only what the returned expression names, and what it returns instead names no member."""
        lines = [(indent, line) for indent, line in method.body if line != "pass"]
        texts = [line for _, line in lines]
        value: str | None = None
        guards: list[tuple[str, str]] = []
        if len(texts) == 1 and texts[0].startswith(RETURN):
            value = texts[0][len(RETURN) :]
        elif len(texts) in (2, 3) and texts[0].startswith("if ") and texts[-1].startswith(RETURN):
            test, early = split_clause(texts[0])
            if len(texts) == 3:
                level = lines[0][0]
                if early or lines[1][0] <= level or lines[2][0] != level:
                    return None
                early = texts[1]
            if not early.startswith(RETURN):
                return None
            value = texts[-1][len(RETURN) :]
            guards.append((test[len("if ") :], early[len(RETURN) :]))
        if value is None:
            return None
        flat = reads.top_level(value)
        condition = re.search(r"\sif\s", flat)
        otherwise = re.search(r"\selse\s", flat)
        if condition and otherwise and condition.start() < otherwise.start():
            guards.append((value[condition.end() : otherwise.start()], value[otherwise.end() :]))
            value = value[: condition.start()]
        guarded = names_in(value) | GUARD_WORDS
        members = self.members(key)
        if any(not names_in(test) <= guarded or names_in(instead) & members for test, instead in guards):
            return None
        return value.strip()

    def method_value(self, key: str, name: str, depth: int = 0) -> Value | None:
        """What method `name`, declared by class `key`, comes down to; None where its body is more than a return."""
        memo = (key, name)
        if memo not in self._values:
            self._values[memo] = None
            method = self.methods(key).get(name)
            expression = self.returned(key, method) if method else None
            if method and expression:
                self._values[memo] = self.value(key, expression, method.params, depth)
        return self._values[memo]

    def field_value(self, key: str, name: str, depth: int = 0) -> Value | None:
        """What a read of field `name`, declared by class `key`, comes down to: the field, or its getter's value."""
        getter = self.getter(key, name)
        return self.value(key, getter, (), depth + 1) if getter is not None else (("field", key, name),)

    def value(self, key: str, expression: str, params: tuple[str, ...], depth: int) -> Value | None:
        """What an expression in class `key` comes down to: a chain of the class's fields where it is one, else the
        expression itself. An expression with a string in it has no value, since the string's contents are blanked
        and two that differ would read the same."""
        text = expression.strip()
        if depth > DEPTH or not text:
            return None
        chain = self.chain_value(key, text, params, depth)
        if chain is not None:
            return chain
        bare = re.sub(r"\s+", "", text)
        return None if '"' in bare or "'" in bare else (("expr", key, bare),)

    def chain_value(self, key: str, text: str, params: tuple[str, ...], depth: int) -> Value | None:
        """The value of a postfix chain that starts at a member of class `key` and walks fields, methods with no
        argument that come down to fields, and at its end a call handed the method's own parameters in order. A lone
        call of the class's own method with no argument comes down to what that method does."""
        parsed = reads.postfix(text)
        if parsed is None or parsed[0][0] not in ("name", "call"):
            return None
        (head, word), steps = parsed
        items = [("field" if head == "name" else "call", word), *steps]
        if items[0] == ("field", "self"):
            items = items[1:]
        arguments = call_arguments(text)
        out: list[Piece] = []
        current: str | None = key
        for index, (step, name) in enumerate(items):
            last = index == len(items) - 1
            piece: Value | None = None
            if step == "field":
                owner = self.tree.field_owner(current, name)
                piece = self.field_value(owner, name, depth) if owner else None
                if piece is None or (not is_path(piece) and not last):
                    return None
                out.extend(piece)
                current = self.tree.member_field_type(current or "", name)[1]
            elif step == "call" and arguments:
                owner = self.tree.method_owner(current, name)
                passed = passed_in(arguments.pop(0))
                if owner is None:
                    return None
                piece = self.method_value(owner, name, depth + 1) if not passed else None
                if is_path(piece):
                    out.extend(piece or ())
                    current = self.tree.method_return(current or "", name)[1]
                elif piece is not None and not out and last:
                    return piece
                elif last and out and passed == list(params):
                    out.append(("call", owner, f"{name}/{len(passed)}"))
                else:
                    return None
            else:
                return None
        return tuple(out) or None

    def returning(self, key: str, value: Value) -> list[tuple[str, str]]:
        """The public methods of class `key` and the classes it extends that come down to `value`, each with the
        class that declares it."""
        out: list[tuple[str, str]] = []
        for ancestor in self.tree.ancestors(key):
            if ancestor not in self._returning:
                found: dict[Value, list[str]] = {}
                for name in self.methods(ancestor):
                    came_to = None if name.startswith("_") else self.method_value(ancestor, name)
                    if came_to:
                        found.setdefault(came_to, []).append(name)
                self._returning[ancestor] = found
            out.extend((ancestor, name) for name in self._returning[ancestor].get(value, []))
        return out

    def asking(self, key: str, owner: str, name: str) -> list[tuple[str, str, str]]:
        """The public yes-or-no methods (`-> bool`, no parameters) of class `key` and the classes it extends whose
        one `return` is an expression naming field `name` and no other member, and reading no member of the field's
        own class through it: each with its class and the expression."""
        out: list[tuple[str, str, str]] = []
        direct = self.field_value(owner, name)
        through = (
            re.compile(rf"\b{re.escape(name)}[ \t]*\.")
            if self.tree.member_field_type(owner, name)[1] in self.tree.files
            else None
        )
        for ancestor in self.tree.ancestors(key):
            members = self.members(ancestor)
            for method in self.methods(ancestor).values():
                if method.name.startswith("_") or method.params or method.returns != "bool":
                    continue
                expression = self.returned(ancestor, method)
                if expression is None or names_in(expression) & members != {name}:
                    continue
                if (through and through.search(expression)) or self.method_value(ancestor, method.name) == direct:
                    continue
                out.append((ancestor, method.name, shown(expression)))
        return out

    def assigning(self, key: str, name: str) -> list[tuple[str, str, str]]:
        """The public methods of class `key` and the classes it extends with a statement that assigns field `name`,
        or an element of it: each with its class and the first such statement."""
        target = re.compile(rf"^(?:self[ \t]*\.[ \t]*)?{re.escape(name)}\b")
        out: list[tuple[str, str, str]] = []
        for ancestor in self.tree.ancestors(key):
            for method in self.methods(ancestor).values():
                if method.name.startswith("_"):
                    continue
                for _, line in method.body:
                    statement = (split_clause(line)[1] or line) if CLAUSE.match(line) else line
                    at = target.match(statement)
                    if at and assigned(statement[at.end() :]):
                        out.append((ancestor, method.name, shown(statement)))
                        break
        return out


@dataclass(frozen=True)
class Unknown:
    """A `.name` in one of the files whose receiver's class cannot be told, where `name` is a field's name."""

    file: str
    line: int
    expression: str


@dataclass(frozen=True)
class Calls:
    """A method's call sites under `src/`: outside the file that declares it, in that file, and the calls of its
    name whose receiver's class cannot be told."""

    elsewhere: int = 0
    own: int = 0
    untold: int = 0


@dataclass(frozen=True)
class Answer:
    """A method that answers a read or does a write: the class that declares it, its name, and what its body does
    where that is not returning the field itself (the expression it returns, or the statement that assigns)."""

    klass: str
    method: str
    does: str = ""


@dataclass
class Entry:
    """One field of a class, or one chain from it, read or written by the files: where, and what answers it."""

    klass: str
    label: str
    access: str
    declared_by: str
    name: str
    sites: list[tuple[str, int]] = field(default_factory=list)
    answers: list[Answer] = field(default_factory=list)
    asking: list[Answer] = field(default_factory=list)


@dataclass(frozen=True)
class Report:
    """What the files read and write, every entry answered and every answering method's calls counted."""

    files: list[str]
    entries: list[Entry]
    unknown: list[Unknown]
    calls: dict[tuple[str, str], Calls]


@dataclass(frozen=True)
class Link:
    """One step of a receiver that a longer chain may run through: the class it is read off, what it comes down
    to, and how it is written (`def`, `row()`)."""

    klass: str
    value: Value
    label: str


def links_of(
    tree: Scripts, answers: Answers, receiver: str, steps: list[reads.Step], kinds: list[str | None]
) -> list[Link]:
    """The steps at the end of a receiver that are fields of classes, or calls with no argument that come down to
    fields: the chain a read after them may be the end of. `kinds[i]` is the class step `i` is read off."""
    arguments = call_arguments(receiver)
    passed = arguments[len(arguments) - sum(1 for step, _ in steps if step == "call") :]
    links: list[Link] = []
    for (step, name), kind in zip(steps, kinds, strict=False):
        value: Value | None = None
        label = name
        if step == "call":
            given = passed.pop(0) if passed else "?"
            owner = tree.method_owner(kind, name) if not given.strip() else None
            value = answers.method_value(owner, name) if owner else None
            label = f"{name}()"
        elif step == "field":
            owner = tree.field_owner(kind, name)
            value = answers.field_value(owner, name) if owner else None
        if kind is not None and value is not None and is_path(value):
            links.append(Link(kind, value, label))
        else:
            links = []
    return links


class Collector:
    """Gathers the files' reads and writes into entries, one per class, label and access, each with its answers."""

    def __init__(self, tree: Scripts, answers: Answers) -> None:
        self.tree = tree
        self.answers = answers
        self.entries: dict[tuple[str, str, str], Entry] = {}
        self.unknown: dict[tuple[str, int, str], Unknown] = {}
        self.fields = {name for key, klass in tree.files.items() if key.startswith(SRC) for name in klass.fields}

    def entry(self, klass: str, label: str, access: str, declared_by: str, name: str) -> Entry:
        return self.entries.setdefault((klass, label, access), Entry(klass, label, access, declared_by, name))

    def read_file(self, path: str) -> None:
        tree = self.tree
        bare = tree.bare[path]
        blocks = reads.block_index(bare)
        inner = reads.inner_lines(bare)
        for index, line in enumerate(bare.split("\n")):
            if "." not in line:
                continue
            for match in reads.USE.finditer(line):
                name = match.group(1)
                if match.group(2) or name not in self.fields:
                    continue
                receiver = reads.receiver_text(line, match.start()) or ""
                parsed = reads.postfix(receiver)
                kinds: list[str | None] = [None]
                if parsed:
                    scope = reads.Scope(tree, path, blocks[index], index)
                    kinds = [tree.evaluate((parsed[0], []), path, scope, inner[index])]
                    for step, word in parsed[1]:
                        kinds.append(tree.step(kinds[-1], step, word))
                klass = kinds[-1]
                if klass is None:
                    expression = re.sub(r"\s+", " ", f"{receiver.strip() or '...'}.{name}")
                    self.unknown.setdefault((path, index + 1, expression), Unknown(path, index + 1, expression))
                    continue
                owner = tree.field_owner(klass, name)
                if owner is None or not owner.startswith(SRC):
                    continue
                if owner.split(INNER)[0] == path or tree.related(klass, path):
                    continue
                rest = line[match.end() :]
                if assigned(rest):
                    found = self.entry(owner, name, "written", owner, name)
                    merge(found.answers, [Answer(*setter) for setter in self.answers.assigning(klass, name)])
                else:
                    links = links_of(tree, self.answers, receiver, parsed[1] if parsed else [], kinds)
                    found = self.read(klass, owner, name, links, rest)
                if (path, index + 1) not in found.sites:
                    found.sites.append((path, index + 1))

    def read(self, klass: str, owner: str, name: str, links: list[Link], rest: str) -> Entry:
        """The entry a read belongs to: the longest chain a method answers, else the field itself."""
        answers = self.answers
        direct = answers.field_value(owner, name)
        tails: list[tuple[Value, str]] = []
        handed = self.handed_on(klass, name, direct, rest)
        if handed:
            tails.append(handed)
        if direct:
            tails.append((direct, ""))
        for tail, suffix in tails:
            for start in range(len(links) + (1 if suffix else 0)):
                value = tuple(piece for link in links[start:] for piece in link.value) + tail
                methods = answers.returning(links[start].klass if start < len(links) else klass, value)
                if methods:
                    label = ".".join([*(link.label for link in links[start:]), name]) + suffix
                    found = self.entry(value[0][1], label, "read", owner, name)
                    merge(found.answers, [Answer(*method) for method in methods])
                    return found
        found = self.entry(owner, name, "read", owner, name)
        if direct:
            merge(found.answers, [Answer(*method) for method in answers.returning(klass, direct)])
        merge(found.asking, [Answer(*method) for method in answers.asking(klass, owner, name)])
        return found

    def handed_on(self, klass: str, name: str, direct: Value | None, rest: str) -> tuple[Value, str] | None:
        """Where a call follows the read (`.map.start()`), what the two come down to together and how the call is
        written: the field's value and then the called method's fields, or the call itself with its arity."""
        call = NEXT_CALL.match(rest)
        close = reads.close_of(rest, call.end() - 1) if call else -1
        if call is None or close < 0 or not is_path(direct):
            return None
        called = self.tree.method_owner(self.tree.member_field_type(klass, name)[1], call.group(1))
        if called is None:
            return None
        passed = passed_in(rest[call.end() : close])
        through = self.answers.method_value(called, call.group(1)) if not passed else None
        tail: Value = through if through and is_path(through) else (("call", called, f"{call.group(1)}/{len(passed)}"),)
        return (*(direct or ()), *tail), f".{call.group(1)}()"


def merge(into: list[Answer], more: list[Answer]) -> None:
    into.extend(answer for answer in more if answer not in into)


def call_sites(tree: Scripts, wanted: set[tuple[str, str]]) -> dict[tuple[str, str], Calls]:
    """For each wanted method (the class that declares it, its name), its calls under `src/`: through a receiver of
    that class or of a class it extends that declares the method too (the call reaches the override), or bare in the
    class and the classes that extend it."""
    names = {name for _, name in wanted}
    elsewhere = dict.fromkeys(wanted, 0)
    own = dict.fromkeys(wanted, 0)
    untold = dict.fromkeys(names, 0)
    reached: dict[tuple[str, str], list[tuple[str, str]]] = {}
    for klass, name in wanted:
        for base in tree.ancestors(klass):
            if name in tree.files[base].methods:
                reached.setdefault((base, name), []).append((klass, name))

    def count(called: tuple[str, str], path: str, times: int = 1) -> None:
        for method in reached.get(called, []):
            (own if method[0].split(INNER)[0] == path else elsewhere)[method] += times

    for path in sorted(p for p in tree.bare if p.startswith(SRC)):
        bare = tree.bare[path]
        blocks = reads.block_index(bare)
        inner = reads.inner_lines(bare)
        for index, line in enumerate(bare.split("\n")):
            for match in reads.USE.finditer(line):
                name = match.group(1)
                if not match.group(2) or name not in names:
                    continue
                receiver = reads.receiver_text(line, match.start())
                scope = reads.Scope(tree, path, blocks[index], index)
                kind = tree.chain_class(receiver, path, scope, inner[index]) if receiver else None
                owner = tree.method_owner(kind, name)
                if kind is None:
                    untold[name] += 1
                elif owner:
                    count((owner, name), path)
    for key in sorted(k for k in tree.files if k.startswith(SRC)):
        text = "\n".join(b for b in reads.blocks_of(tree.text_of(key)) if not reads.INNER_CLASS.match(b))
        for name in names:
            owner = tree.method_owner(key, name)
            if owner is None or (owner, name) not in reached:
                continue
            called = len(re.findall(rf"(?<![\w.$%@]){re.escape(name)}[ \t]*\(", text))
            declared = len(re.findall(rf"\bfunc[ \t]+{re.escape(name)}[ \t]*\(", text))
            count((owner, name), key.split(INNER)[0], called - declared)
    return {method: Calls(elsewhere[method], own[method], untold[method[1]]) for method in wanted}


def report_of(tree: Scripts, files: list[str]) -> Report:
    collector = Collector(tree, Answers(tree))
    for path in files:
        collector.read_file(path)
    entries = sorted(collector.entries.values(), key=lambda e: (tree.display(e.klass), e.label, e.access != "read"))
    for entry in entries:
        entry.sites.sort()
    wanted = {(a.klass, a.method) for e in entries for a in (*e.answers, *e.asking)}
    unknown = sorted(collector.unknown.values(), key=lambda u: (u.file, u.line, u.expression))
    return Report(files, entries, unknown, call_sites(tree, wanted))


def sites_text(sites: list[tuple[str, int]], counts: bool) -> str:
    by_file: dict[str, list[int]] = {}
    for path, line in sites:
        by_file.setdefault(path, []).append(line)
    if counts:
        return ", ".join(
            f"`{path}` on {len(lines)} line{'' if len(lines) == 1 else 's'}" for path, lines in by_file.items()
        )
    return "; ".join(f"`{path}`:{','.join(str(n) for n in lines)}" for path, lines in by_file.items())


def calls_text(calls: Calls) -> str:
    parts = [f"{calls.elsewhere} call{'' if calls.elsewhere == 1 else 's'}"]
    if calls.own:
        parts.append(f"+{calls.own} own")
    if calls.untold:
        parts.append(f"+{calls.untold} untold")
    return f"({', '.join(parts)})"


def answers_text(tree: Scripts, entry: Entry, calls: dict[tuple[str, str], Calls]) -> str:
    def named(answer: Answer, verb: str) -> str:
        via = "" if answer.klass in tree.ancestors(entry.klass) else f"{tree.display(answer.klass)}."
        does = f" {verb} `{answer.does}`" if answer.does else ""
        return f"`{via}{answer.method}()`{does} {calls_text(calls[(answer.klass, answer.method)])}"

    text = ", ".join(named(answer, "does") for answer in entry.answers) or "no method"
    asking = ", ".join(named(answer, "returns") for answer in entry.asking)
    return text + (f"; of it alone, {asking}" if asking else "")


def markdown(tree: Scripts, report: Report, counts: bool = False) -> str:
    """The list as a builder pastes it: a line of what it is, one line per class, one per receiver not told."""
    named = ", ".join(f"`{path}`" for path in report.files)
    if not report.entries and not report.unknown:
        return f"No field of a class under `src/` is read or written through a receiver of that class in {named}.\n"
    out = [
        f"Fields of classes under `src/` that {named} read or write through a receiver of that class, each with the"
        " method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under"
        " `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose"
        " receiver's class cannot be told.",
        "",
    ]
    by_class: dict[str, list[Entry]] = {}
    for entry in report.entries:
        by_class.setdefault(entry.klass, []).append(entry)
    for klass, entries in by_class.items():
        parts = [
            f"`{e.label}` {e.access} ({sites_text(e.sites, counts)}): {answers_text(tree, e, report.calls)}"
            for e in entries
        ]
        out.append(f"- `{tree.display(klass)}`: {'; '.join(parts)}")
    out.extend(f"- Receiver's class not told: `{u.file}:{u.line}` `{u.expression}`" for u in report.unknown)
    return "\n".join(out) + "\n"


def as_json(tree: Scripts, report: Report) -> str:
    def method(answer: Answer) -> dict[str, object]:
        calls = report.calls[(answer.klass, answer.method)]
        return {
            "class": tree.display(answer.klass),
            "method": answer.method,
            "does": answer.does,
            "calls": calls.elsewhere,
            "own_file_calls": calls.own,
            "untold_calls": calls.untold,
        }

    classes: dict[str, tuple[dict[str, object], list[dict[str, object]]]] = {}
    for entry in report.entries:
        if entry.klass not in classes:
            fields: list[dict[str, object]] = []
            group: dict[str, object] = {
                "class": tree.display(entry.klass),
                "path": entry.klass.split(INNER)[0],
                "fields": fields,
            }
            classes[entry.klass] = (group, fields)
        classes[entry.klass][1].append(
            {
                "field": entry.label,
                "access": entry.access,
                "declared": f"{tree.display(entry.declared_by)}.{entry.name}",
                "sites": [{"file": path, "line": line} for path, line in entry.sites],
                "methods": [method(a) for a in entry.answers],
                "asking_of_it_alone": [method(a) for a in entry.asking],
            }
        )
    unknown = [{"file": u.file, "line": u.line, "expression": u.expression} for u in report.unknown]
    whole = {"files": report.files, "classes": [group for group, _ in classes.values()], "unknown": unknown}
    return json.dumps(whole, indent=2, ensure_ascii=False) + "\n"


def files_of_brief(text: str, known: list[str]) -> list[str]:
    """The `.gd` files a brief's `**Your files**` paragraph names in backticks: a path as it stands, a bare file
    name as the one script of that name."""
    paragraph = BRIEF_FILES.search(text)
    if paragraph is None:
        raise FieldAnswersError("the brief has no `**Your files**` paragraph")
    out: list[str] = []
    for name in BRIEF_PATH.findall(paragraph.group()):
        matches = [name] if name in known else [path for path in known if path.endswith(f"/{name}")]
        if len(matches) != 1:
            raise FieldAnswersError(f"the brief names `{name}`, which is {len(matches)} scripts, not one")
        if matches[0] not in out:
            out.append(matches[0])
    if not out:
        raise FieldAnswersError("the brief's `**Your files**` paragraph names no `.gd` file in backticks")
    return out


def read_tree(root: Path, rev: str | None) -> Scripts:
    """Every `.gd` file outside `docs/`, from the checkout at `root` or from commit `rev`, as one tree."""
    if rev:
        scripts = reads.read_scripts_rev(rev, root)
        project = check_layers.git("show", f"{rev}:project.godot", cwd=root).decode("utf-8", errors="replace")
    else:
        scripts = reads.read_scripts_checkout(root)
        project = (root / "project.godot").read_text(encoding="utf-8")
    return Scripts(scripts, reads.autoloads_of(project))


def named_file(name: str, root: Path) -> str:
    """A FILE argument as a path from the repository's root."""
    path = Path(name)
    if path.is_absolute():
        try:
            path = path.resolve().relative_to(root.resolve())
        except ValueError as error:
            raise FieldAnswersError(f"{name} is not under {root}") from error
    return path.as_posix()


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/field_answers.py",
        description=__doc__,
        epilog=(
            "Examples:\n  uv run python tools/field_answers.py tests/test_heat.gd tests/test_masts.gd\n"
            "  uv run python tools/field_answers.py --brief .claude/briefs/<name>.md --counts\n"
            "  uv run python tools/field_answers.py --rev origin/<branch> --json tests/finale_rig.gd"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "files", nargs="*", metavar="FILE", help="a `.gd` file to read, as a path from the repository's root"
    )
    parser.add_argument(
        "--brief",
        type=Path,
        default=None,
        metavar="FILE",
        help="also read the `.gd` files a brief's `**Your files**` paragraph names in backticks",
    )
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--rev", default=None, help="read the tree of this commit instead of the checkout")
    source.add_argument("--root", type=Path, default=None, help="read the checkout at this path instead of this one")
    shape = parser.add_mutually_exclusive_group()
    shape.add_argument("--json", action="store_true", help="print the list as JSON, every site with its line")
    shape.add_argument(
        "--counts", action="store_true", help="print how many lines of each file read a field, not which lines"
    )
    args = parser.parse_args(argv)
    if not args.files and args.brief is None:
        parser.error("name at least one FILE, or a --brief")
    for name in args.files:
        if not name.endswith(".gd"):
            parser.error(f"{name} is not a `.gd` file")
    return args


def main(argv: list[str]) -> int:
    args = parse(argv)
    root = args.root or ROOT
    try:
        files = [named_file(name, root) for name in args.files]
        brief = args.brief.read_text(encoding="utf-8") if args.brief is not None else None
        tree = read_tree(root, args.rev)
        if brief is not None:
            files.extend(path for path in files_of_brief(brief, sorted(tree.bare)) if path not in files)
        missing = [path for path in files if path not in tree.bare]
        if missing:
            where = f"commit {args.rev}" if args.rev else f"the checkout at {root}"
            raise FieldAnswersError(f"not a `.gd` file outside docs/ in {where}: {', '.join(missing)}")
        report = report_of(tree, files)
    except (check_layers.LayerError, FieldAnswersError, OSError) as error:
        print(f"tools/field_answers.py: {error}", file=sys.stderr)
        return 1
    sys.stdout.write(as_json(tree, report) if args.json else markdown(tree, report, args.counts))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
