#!/usr/bin/env python3
"""Fails when code under `src/` reads or writes a `var` that another class under `src/` declares.

designing-classes' "Fields are not API" (inbox #1173 in gray-dolphin): one object never reads or writes another
object's fields, every interaction goes through the other's methods. This finds the places that still do, and
`tools/field_reads.txt` lists today's, grouped by the class whose field is read, one `<reader file> <field>`
line per reader file and field. The list only shrinks, bar a read that only moved (below; minty-quail's
`field-reads.md`, the board's field-read-check, inbox #1182 in gray-dolphin).

**A read** is `receiver.name` (a plain read, an assignment, a compound assignment) where

- the receiver's class is known from the code (below) and is a class under `src/` other than the reader's own
  class, its ancestors and its descendants,
- `name` is a `var` (also `static var`, `@export var`, `@onready var`) declared at the top level of that class's
  file or of a class it extends, an underscore name included (an underscore is a convention, not a fence), where
  the class is one a receiver can name: a file with a `class_name` or an autoload name. A var only an inner class
  or a file with no `class_name` declares is not a var here (`var_names_of`),
- and no call parenthesis follows (`.name(` is a method call, or a Callable called, and is the API).

What is no breach: a method, a signal, a constant or an enum (`Tuning.X`); an engine object's property
(`position`, `visible`: the receiver is not a class under `src/`); a class reading its own fields, `self.field`
included; an inner class reading its outer class's fields, or the file reading its own inner classes' (the file
is one class); a class reading a related class's field (an ancestor or a descendant: GDScript has no protected,
and the subclass and its base are one design).

**How the receiver's class is told.** By static reading: a chain `a.b().c[i].d` resolved from its head, which is
`self` (the file's class; inside an inner class an engine value, a blind spot below), an inner class of the file
named bare (`In.new()`), a `class_name` (a static use or `Foo.new()`), an autoload from `project.godot`, a script a
`const` preloads, an engine class or a constant (`Vector2.ZERO`), a node path (`$Camera`), a parenthesised
expression, a call of the file's own method or of an engine or global function (`Array(...)` and `Dictionary(...)`
give an untyped one), or a name the file declares. A name's class comes from its declaration: its type (`var x:
Foo`, a parameter, `for x: Foo in`, `Array[Foo]`, `Dictionary[K, V]`), or what `:=` infers from (`Foo.new()`, `as
Foo`, a chain, a literal, a constructor such as `Vector2(...)`, an arithmetic or logical expression, which GDScript
never overloads, so its value is never a class under `src/`), or what an untyped `for` iterates (a typed array's
element, a typed dictionary's key); one type for the name in its top-level block (a func, a var, an inner class), a
name typed two ways there taking the declaration in scope on the line (by line and indent) and being unknown where
none or two disagree. A name the block never declares is a field of the file's own class or an ancestor, and so is
one that shadows such a field on a line no declaration of it reaches (after a `for` over it, before a later `var`).
Each step after the head is a field's declared type (an inner class's field included), a method's declared
`-> Type`, an array or dictionary element, or for a receiver that is not a class under `src/` an engine property
(an engine class) or an engine call (an engine class, unless it is one that returns a Variant: `get()`, `call()`,
`back()` and the like, the element type on a typed array or dictionary). A type that names no class under `src/` and
is not `Variant` is told as not one: the receiver is known, and no read.

**The opt-out line, and a converted file.** `project.godot` makes the engine fail an access it cannot type
(`untyped_declaration`, `unsafe_property_access`, `unsafe_method_access` are errors), and a `.gd` file not yet
typed opts out with one line at its top naming the warnings it still trips. The files carrying that line are the
list of files not yet converted, which only shrinks; nothing else records it. The engine cannot see two kinds of
access. A property read on a value it types as `Variant` (an element of an untyped array or dictionary, a call that
returns a Variant, a name declared `: Variant`) warns of nothing, and neither does a method named without its
parentheses, on any receiver: `thing.hard_fail` is a reference to the function, always true. So in a file under
`src/` **without** the line this check fails, naming the file, the line and the expression:

- a `.name` use with no `(` after it, whose receiver's class it cannot tell, whether or not the use hands a Callable
  on, where the name is a var as above, or a method a file or an inner class under `src/` declares
  (`method_names_of`). A method's name is not taken for one where it is also such a var (the use fails as the
  var's), a constant or an enum any file or inner class declares, or a name in `ENGINE_PROPERTIES`. That is a fixed
  list, the engine's names among the method names nothing else excuses, read from the engine when it was last made:
  a name an engine class has as a property or a signal, or a builtin type as a member, which on a receiver nothing
  types is as likely the engine's member as the project's method. A method added later with another engine name is
  taken for a method until the list gains it. A name only an inner class or a file with no `class_name` declares as
  a var, or one declared as a signal, does not excuse a method's name. The fix is a typed name to read through, or,
  for a dictionary's key, a subscript.

In a file **with** the line such a use is skipped, never listed and never failed, and `--summary` counts the
skipped uses of a var's name.

**The line has one form**, the file's whole first line, `@warning_ignore_start("untyped_declaration",
"unsafe_method_access")`: double-quoted names separated by `, `, only those three warnings, each once, in that
order, nothing after it. The engine honours other forms (a trailing comment, a space or a backslash line
continuation before the parenthesis, a line break or a comment inside it, single quotes, the annotation lower in the
file), so every `@warning_ignore`, `@warning_ignore_start` and `@warning_ignore_restore` in a file's code is read
whole, and any but that line that names one of the three, or has an argument the check cannot read (a constant),
fails with the line in its one form: an ignore the check cannot see would let the list grow unnoticed, and a
converted file would hide an untyped access behind it. A failure for a file that would need the line says what to
write instead: a suite the typed runner header, `func run(t: TestRunner) -> void:`, anything else a typed
declaration or a typed name. Every `.gd` file outside `docs/` is read for the line (`src/`, `tests/`, `tools/`: the
setting reaches every script the engine parses in this project); only `src/` is read for reads.

**Blind spots, stated.** A chain through an engine property typed `Variant` (`JSON.data`), or from `self` inside an
inner class, is told as an engine value, so a read behind it is not seen; a read of another file's inner class's
field is not listed; a var only an inner class or a file with no `class_name` declares is not a var here, so a
receiver whose class cannot be told read with such a name fails only where some file or inner class declares the
name as a method; a bare name nothing declares is taken for an engine property of the file's own class; a
parameter of a function whose parameter list closes at the margin (a line starting with `)`, which opens a new
block) has no type here, so a read through it is neither a read nor an unknown. A method named without its
parentheses is seen only on a receiver whose class the check cannot tell: not on one it can type, a class under
`src/` or an engine value (`if thing.is_ready:` with `thing: Thing`), nor on a bare name of the file's own class
with no receiver (`if is_ready:`). A second read of a field a file already reads is not a new
line, so a change that adds one to a listed reader file and field passes `--base`: review reads the diff for it.
Tests are not read for reads (that is `tests-one-module.md`'s item). Whether a line still names only warnings its
file trips is the engine's to show, not this check's: deleting a name the file still trips fails the boot, and a
stale name left on an opt-out line is found by `tools/typing_census.py --check`.

**The list.** A header comment `# [ClassName] path` opens a class's group; a line under it is `<reader file> <field>`.
A read not listed **fails**. A listed line with no read now **fails** as a `REMOVE` line, so the pull request that
converts a read deletes its line. The list is generated: `--write` rewrites it from the tree, sorted, so a merge
of `main` that conflicts in it is resolved by taking either side and running `--write` (no merge tool of its own is
needed, since the lines carry no reasons to replay). With `--base REV`, a line `REV`'s list did not hold fails unless
its read only moved, and so does a file that gains the opt-out line, or a warning on it, since `REV` (a file new
since `REV` that carries it included; one git reports as renamed keeps its base's line): both lists only shrink,
unless the same diff changes this checker (a better checker sees reads the old one could not).

**A read that only moved passes, in three cases and no other.** An added line passes when

1. a line of the same class and field is removed in the same diff and git reports the reader file as renamed from the
   removed line's file to the added line's; or
2. its reader file is new since `REV` and the uses of that class's field did not grow: over the files that differ
   between `REV` and the tree, the tree's uses of the class's field are no more than `REV`'s, counted one total per
   class and field, so code moved into a new file, or a file split into several, passes and one more use fails; or
3. its class is a file new since `REV` (not a git rename of one) that declares every var of one inner class `REV`
   declared and the tree no longer declares, and that inner class declared the field (an inner class lifted into a
   file of its own). A lift that drops a var fails. Nothing is counted there: `REV` could not see the reads of an
   inner class's field, so a file the lifting diff adds that reads the lifted class passes too, and review reads
   that diff for a new reader. A new class that declares every var of an inner class leaving the same diff is taken
   for that class lifted, whatever else it is (with an inner class of one var a single shared name is enough), and
   one such inner class vouches for each new class that declares its vars: review reads a diff that removes an inner
   class and adds a class for those lines.

The count in 2 is a net over the files that differ: a use removed from one changed file offsets one added in a new
file.

Any other added line fails: a new file reading a field no changed file read, a move that also adds a use, a new
class with a public var read from outside. A `REV` without the list yet compares nothing. `--rev` and `--root` read
the tree of that commit or checkout, and the list of that same tree.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from collections.abc import Callable, Iterable, Iterator, Mapping
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_layers
from check_test_only_members import read_renames

ROOT = Path(__file__).resolve().parent.parent
LIST_NAME = "field_reads.txt"
LIST_PATH = f"tools/{LIST_NAME}"
SRC = "src"
SELF_NAME = Path(__file__).name

LIST_HEADER = """\
# The reads of another class's field under src/, which tools/check_field_reads.py lets stand: designing-classes'
# "Fields are not API" says one object never reads or writes another's fields. Generated by
# `uv run python tools/check_field_reads.py --write`, grouped by the class whose field is read, one
# "<reader file> <field>" per reader file and field. The list only shrinks: the check fails a line added against the
# pull request's base, unless its read only moved (its reader file renamed; code moved into a new file with no more
# uses of that class's field; an inner class lifted into a file of its own), and a line whose read is gone fails as a
# REMOVE line, so the pull request that moves a read behind a method deletes its line. A merge of main that
# conflicts here takes either side and runs --write.
"""

# The warnings project.godot makes errors, which the opt-out line may name, in the order the line names them.
WARNINGS = ("untyped_declaration", "unsafe_property_access", "unsafe_method_access")
# The opt-out line's one form: the whole first line, double-quoted names separated by ", ", nothing after it.
OPT_OUT = re.compile(r'^@warning_ignore_start\(((?:"\w+")(?:, "\w+")*)?\)$')
# Every warning annotation the engine reads, found in code with its comments and strings blanked.
ANY_IGNORE = re.compile(r"@warning_ignore(?:_start|_restore)?\b")
# A string literal as an annotation's argument: double or single quotes, a StringName's `&` or a raw string's `r`.
NAME_LITERAL = re.compile(r"""^[&r]?(?:"([^"\\\n]*)"|'([^'\\\n]*)')$""")
EXAMPLE_LINE = '@warning_ignore_start("untyped_declaration", "unsafe_method_access")'
# What a builder writes instead of the opt-out line: a suite's typed header, or a typed name.
SUITE_HEADER = "func run(t: TestRunner) -> void:"
SUITE_SECTION = 'writing-tests, "A suite is typed, and opens with the typed runner header"'
TYPED_NAME = "`var x: Class = ...`, `for x: Class in`, `as Class`"
# Folders not read for the line: the frozen evidence under docs/ is rerun from the revision it names.
LINE_SKIPPED = ("docs",)

# A receiver's kind: a class file under src/ (its path), an inner class (its file's path, INNER, its name), UNTRACKED
# (told, and not a class whose vars this check tracks: an engine class, a builtin, an enum), ARRAY + element kind,
# DICT + key kind + SEP + value kind (an empty part being unknown), or None (unknown).
UNTRACKED = "@untracked"
ARRAY = "@array:"
DICT = "@dict:"
SEP = "\x1f"

TYPE = r"(?:[A-Z]\w*(?:\.[A-Z]\w*)*(?:\[[^\]\n]*\])?|int|float|bool|void)"
# A top-level var: at the margin, after annotations, `static`.
VAR = re.compile(r"^(?:@\w+(?:\([^)]*\))?[ \t]+)*(?:static[ \t]+)?var[ \t]+([A-Za-z_]\w*)(.*)$", re.MULTILINE)
FUNC = re.compile(r"^(?:static[ \t]+)?func[ \t]+([A-Za-z_]\w*)[ \t]*\(", re.MULTILINE)
FUNC_RETURN = re.compile(
    rf"^(?:static[ \t]+)?func[ \t]+([A-Za-z_]\w*)[ \t]*\((?:[^()]|\([^()]*\))*\)[ \t]*->[ \t]*({TYPE})(?![\w.(])",
    re.MULTILINE,
)
FUNC_PARAMS = re.compile(r"\bfunc\b[ \t]*\w*[ \t]*\(((?:[^()]|\([^()]*\))*)\)")
EXTENDS = re.compile(r"^extends[ \t]+([A-Z]\w*)[ \t]*$", re.MULTILINE)
NAME_TYPED = re.compile(rf"\b([A-Za-z_]\w*)[ \t]*:[ \t]*({TYPE})(?![\w.(])")
NAME_INFERRED = re.compile(r"\b([A-Za-z_]\w*)[ \t]*:=[ \t]*([^\n]*?)[ \t]*$", re.MULTILINE)
NAME_UNTYPED = re.compile(r"\bvar[ \t]+([A-Za-z_]\w*)\b(?![ \t]*:)")
FOR_UNTYPED = re.compile(r"^[ \t]*for[ \t]+([A-Za-z_]\w*)[ \t]+in[ \t]+([^\n]*?):[ \t]*$", re.MULTILINE)
PRELOAD = re.compile(
    r'^const[ \t]+(\w+)[ \t]*(?::[ \t]*\w+[ \t]*)?:?=[ \t]*preload\([ \t]*"res://([^"]+)"', re.MULTILINE
)
USE = re.compile(r"\.[ \t]*([A-Za-z_]\w*)([ \t]*\()?")
IDENT = re.compile(r"[A-Za-z_]\w*")
GROUP_TAG = re.compile(r"^#\s*\[(\w+)\]")
INNER_CLASS = re.compile(r"^class[ \t]+\w+")
INNER_HEAD = re.compile(r"^class[ \t]+([A-Za-z_]\w*)(?:[ \t]+extends[ \t]+([A-Za-z_][\w.]*))?[ \t]*:")
INNER = "::"
CAST_TAIL = re.compile(rf"\bas[ \t]+({TYPE})[ \t]*$")
WORD_OPERATOR = re.compile(r"(?:^|[^\w.])(?:and|or|not|in|is)(?![\w])")
ROUNDS = 3

# The calls whose return the engine types as Variant, so it cannot type a property read on what they return:
# every engine class method with that return in Godot 4.7.2 (ClassDB.class_get_method_list, a nil return carrying
# PROPERTY_USAGE_NIL_IS_VARIANT), less the virtual `_` methods and `new`, which is told apart above, and the global,
# Array, Dictionary and Callable functions its class reference gives a Variant return. A call not here on a value
# that is not a class under src/ returns an engine type.
VARIANT_CALLS = frozenset(
    {
        "abs",
        "accessibility_element_get_meta",
        "area_get_param",
        "back",
        "base64_to_variant",
        "body_get_param",
        "body_get_state",
        "bytes_to_var",
        "bytes_to_var_with_objects",
        "call",
        "call_deferred",
        "call_deferred_thread_group",
        "call_thread_safe",
        "callv",
        "canvas_item_get_instance_shader_parameter",
        "canvas_item_get_instance_shader_parameter_default_value",
        "ceil",
        "clamp",
        "class_call_static",
        "class_get_property",
        "class_get_property_default_value",
        "convert",
        "create_object",
        "declaration",
        "element_get_meta",
        "eval",
        "execute",
        "find_key",
        "floor",
        "from_native",
        "front",
        "get",
        "get_additional_data",
        "get_bone_meta",
        "get_custom_data",
        "get_custom_data_by_layer_id",
        "get_custom_monitor",
        "get_data",
        "get_edge_meta",
        "get_face_meta",
        "get_global_variable_value",
        "get_indexed",
        "get_input",
        "get_input_port_default_value",
        "get_instance_shader_parameter",
        "get_item_metadata",
        "get_item_tag",
        "get_line_gutter_metadata",
        "get_local_variable_value",
        "get_marker_data",
        "get_member_variable_value",
        "get_meta",
        "get_metadata",
        "get_node_property_value",
        "get_node_rpc_config",
        "get_option",
        "get_option_value",
        "get_or_add",
        "get_or_env",
        "get_parameter",
        "get_project_metadata",
        "get_project_setting",
        "get_property_default_value",
        "get_ref",
        "get_result_value",
        "get_rpc_config",
        "get_script",
        "get_selected_metadata",
        "get_setting",
        "get_setting_with_override",
        "get_setting_with_override_and_custom_features",
        "get_shader_parameter",
        "get_slot_metadata_left",
        "get_slot_metadata_right",
        "get_tab_metadata",
        "get_theme_item",
        "get_typed_key_script",
        "get_typed_script",
        "get_typed_value_script",
        "get_value",
        "get_var",
        "get_vertex_meta",
        "global_menu_get_item_tag",
        "global_shader_parameter_get",
        "gui_get_drag_data",
        "hover",
        "initialize",
        "instance_geometry_get_shader_parameter",
        "instance_geometry_get_shader_parameter_default_value",
        "instantiate",
        "interpolate_value",
        "lerp",
        "line_intersects_line",
        "material_get_param",
        "max",
        "min",
        "nativeSymbol",
        "parse_string",
        "pick_random",
        "pop_at",
        "pop_back",
        "pop_front",
        "prepareRename",
        "process_action",
        "property_get_revert",
        "ray_intersects_triangle",
        "reduce",
        "resume",
        "round",
        "segment_intersects_segment",
        "segment_intersects_triangle",
        "shader_get_parameter_default",
        "shape_get_data",
        "shaped_get_run_object",
        "shaped_get_span_embedded_object",
        "shaped_get_span_meta",
        "shaped_get_span_object",
        "sign",
        "signatureHelp",
        "snapped",
        "soft_body_get_state",
        "str_to_var",
        "to_native",
        "track_get_key_value",
        "type_convert",
        "value_track_interpolate",
        "wait_to_finish",
        "weakref",
        "wrap",
    }
)
# On a typed array these return its element; on a typed dictionary, `get` and `get_or_add` its value.
ELEMENT_CALLS = frozenset({"back", "front", "pick_random", "pop_back", "pop_front", "pop_at", "get", "min", "max"})
# The engine's names among the method names nothing else excuses (`method_names_of` without this list): a name an
# engine class declares as a property or a signal in Godot 4.7.2 (ClassDB.class_get_property_list and
# class_get_signal_list), or a builtin type declares as a member (`Rect2.end`: the `members` of the `builtin_classes`
# that `godot --headless --dump-extension-api` writes, which ClassDB does not list). An engine name that is also a
# var of a class with a `class_name` (`size`, `path`) needs no entry: the use fails as the var's. On a receiver
# whose class cannot be told such a name is as likely the engine's property as the project's method, so it is not
# taken for a method read without its parentheses. A method added under src/ with another such name is taken for
# one until the list gains it, and the fix, a typed name to read through, is right either way.
ENGINE_PROPERTIES = frozenset(
    {
        "_source",
        "columns",
        "content_scale_size",
        "continued",
        "depth",
        "direction",
        "enabled",
        "end",
        "environment",
        "frames",
        "grow",
        "layers",
        "nodes",
        "offsets",
        "pose",
        "rect",
        "region",
        "region_rect",
        "release",
        "reset",
        "scale",
        "sections",
        "segments",
        "start_position",
        "velocity",
    }
)
CONSTANT = re.compile(r"^(?:static[ \t]+)?(?:const|enum)[ \t]+([A-Za-z_]\w*)", re.MULTILINE)


class FieldReadsError(Exception):
    """An input could not be read."""


@dataclass(frozen=True)
class Klass:
    """A class under `src/`: its file, its name (`class_name`, else the autoload's), what it extends, the kind of
    each var it declares at the top level (None where the declaration does not say), the methods it declares, and
    the kind each returns (None where it declares no return type, or Variant)."""

    path: str
    name: str
    parent: str | None = None
    fields: dict[str, str | None] = field(default_factory=dict)
    methods: set[str] = field(default_factory=set)
    returns: dict[str, str | None] = field(default_factory=dict)


@dataclass(frozen=True)
class Read:
    reader: str
    line: int
    klass: str
    name: str
    count: int = 1


UNKNOWN_VAR = "var"
UNKNOWN_METHOD = "method"


@dataclass(frozen=True)
class Unknown:
    """A `.name` use in a file without the opt-out line that fails: a receiver whose class cannot be told, where
    `name` is a var (UNKNOWN_VAR) or a method (UNKNOWN_METHOD) as `reads_of` counts them."""

    reader: str
    line: int
    expression: str
    kind: str = UNKNOWN_VAR


@dataclass(frozen=True)
class Found:
    reads: list[Read]
    skipped: int
    unknown: list[Unknown] = field(default_factory=list)


@dataclass(frozen=True)
class Entry:
    """One `<reader file> <field>` line of the list under the class group it is in."""

    klass: str
    path: str
    name: str
    number: int

    @property
    def key(self) -> tuple[str, str, str]:
        return (self.klass, self.path, self.name)


@dataclass(frozen=True)
class OptOut:
    """A file's opt-out line: the warnings it names, or the reason it is malformed."""

    warnings: tuple[str, ...]
    problem: str = ""


def opt_out_of(text: str) -> OptOut | None:
    """The opt-out line at the top of a file, or None where its first line is not one in the line's one form."""
    first = text.split("\n", 1)[0].rstrip("\r")
    match = OPT_OUT.match(first)
    if not match:
        return None
    names: list[str] = []
    body = match.group(1)
    for word in body.split(", ") if body else []:
        name = word[1:-1]
        if name not in WARNINGS:
            return OptOut(tuple(names), f'"{name}" is not one of {", ".join(WARNINGS)}')
        if name in names:
            return OptOut(tuple(names), f'"{name}" is named twice')
        names.append(name)
    if names != sorted(names, key=WARNINGS.index):
        return OptOut(tuple(names), f"it names its warnings out of the order {', '.join(WARNINGS)}")
    return OptOut(tuple(names))


def canonical_line(names: Iterable[str]) -> str:
    """The opt-out line naming `names`, in its one form; the example line where it names none of the three."""
    wanted = set(names)
    ordered = [w for w in WARNINGS if w in wanted]
    return "@warning_ignore_start(" + ", ".join(f'"{w}"' for w in ordered) + ")" if ordered else EXAMPLE_LINE


@dataclass(frozen=True)
class Ignore:
    """A warning annotation in a file: its line, its offset, the warnings it names in literals, and whether an
    argument is something other than a literal (a name the check cannot read, so possibly one of the three)."""

    line: int
    offset: int
    names: tuple[str, ...]
    unreadable: bool


def annotation_arguments(text: str) -> tuple[tuple[str, ...], bool]:
    """The names an annotation's argument list (the text inside its parentheses) gives as string literals, and
    whether any argument is not one. A comment inside the list is skipped, as the engine skips it."""
    parts: list[str] = []
    current: list[str] = []
    index = 0
    while index < len(text):
        char = text[index]
        if char == "#":
            while index < len(text) and text[index] != "\n":
                index += 1
            continue
        if char in "\"'":
            end = index + 1
            while end < len(text) and text[end] not in (char, "\n"):
                end += 2 if text[end] == "\\" else 1
            current.append(text[index : end + 1])
            index = end + 1
            continue
        if char == ",":
            parts.append("".join(current))
            current = []
        else:
            current.append(char)
        index += 1
    parts.append("".join(current))
    names: list[str] = []
    unreadable = False
    for part in parts:
        word = re.sub(r"\s+", "", part)
        if not word:
            continue
        literal = NAME_LITERAL.match(word)
        if literal:
            names.append(literal.group(1) if literal.group(1) is not None else literal.group(2))
        else:
            unreadable = True
    return tuple(names), unreadable


def ignores_of(text: str) -> list[Ignore]:
    """Every `@warning_ignore`, `@warning_ignore_start` and `@warning_ignore_restore` in the file's code (not in a
    comment or a string), read whole: a space or a backslash line continuation before the parenthesis, line breaks
    and comments inside it, either quote style. An annotation whose parenthesis never closes is unreadable."""
    bare = check_layers.blank(text).bare
    out: list[Ignore] = []
    for match in ANY_IGNORE.finditer(bare):
        at = match.end()
        while at < len(bare):
            if bare[at] in " \t":
                at += 1
            elif bare.startswith(("\\\n", "\\\r\n"), at):
                at = bare.index("\n", at) + 1
            else:
                break
        names: tuple[str, ...] = ()
        unreadable = False
        if at < len(bare) and bare[at] == "(":
            close = close_of(bare, at)
            if close < 0:
                unreadable = True
            else:
                names, unreadable = annotation_arguments(text[at + 1 : close])
        out.append(Ignore(bare.count("\n", 0, match.start()) + 1, match.start(), names, unreadable))
    return out


def statement(text: str, start: int) -> str:
    """The rest of the logical line from `start`: on past a line break while a bracket is open or the line ends in a
    backslash."""
    depth = 0
    index = start
    while index < len(text):
        char = text[index]
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "\n" and depth <= 0 and not text[start:index].rstrip(" \t").endswith("\\"):
            break
        index += 1
    return re.sub(r"\\?\n[ \t]*", " ", text[start:index]).strip()


def split_top(text: str, separator: str = ",") -> list[str]:
    """`text` split at each `separator` outside brackets."""
    parts: list[str] = []
    depth = 0
    start = 0
    for index, char in enumerate(text):
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == separator and depth == 0:
            parts.append(text[start:index])
            start = index + 1
    parts.append(text[start:])
    return parts


def close_of(text: str, start: int) -> int:
    """The index of the bracket closing the one at `start`, or -1."""
    depth = 0
    for index in range(start, len(text)):
        if text[index] in "([{":
            depth += 1
        elif text[index] in ")]}":
            depth -= 1
            if depth == 0:
                return index
    return -1


def open_of(text: str, end: int) -> int:
    """The index of the bracket opening the one at `end`, or -1."""
    depth = 0
    for index in range(end, -1, -1):
        if text[index] in ")]}":
            depth += 1
        elif text[index] in "([{":
            depth -= 1
            if depth == 0:
                return index
    return -1


def top_level(text: str) -> str:
    """`text` with every bracketed part blanked, so an operator found in it is at the top level."""
    out: list[str] = []
    depth = 0
    for char in text:
        if char in "([{":
            depth += 1
            out.append(" ")
        elif char in ")]}":
            depth -= 1
            out.append(" ")
        else:
            out.append(char if depth == 0 else " ")
    return "".join(out)


Step = tuple[str, str]


def postfix(text: str) -> tuple[Step, list[Step]] | None:
    """`text` as a head and the steps after it, or None where it is not one postfix chain. A head is ("name", w),
    ("call", w), ("node", "") or ("paren", inside); a step ("field", w), ("call", w) or ("index", "")."""
    s = text.strip()
    if not s:
        return None
    n = len(s)
    head: Step
    if s[0] in "$%":
        at = 1
        while at < n and (s[at].isalnum() or s[at] in "_/ "):
            at += 1
        head, i = ("node", ""), at
    elif s[0] == "(":
        end = close_of(s, 0)
        if end < 0:
            return None
        head, i = ("paren", s[1:end]), end + 1
    else:
        match = IDENT.match(s)
        if not match:
            return None
        i = match.end()
        if i < n and s[i] == "(":
            end = close_of(s, i)
            if end < 0:
                return None
            head, i = ("call", match.group()), end + 1
        else:
            head = ("name", match.group())
    steps: list[Step] = []
    while i < n:
        while i < n and s[i] in " \t":
            i += 1
        if i >= n:
            break
        if s[i] == "[":
            end = close_of(s, i)
            if end < 0:
                return None
            steps.append(("index", ""))
            i = end + 1
        elif s[i] == ".":
            i += 1
            while i < n and s[i] in " \t":
                i += 1
            match = IDENT.match(s, i)
            if not match:
                return None
            i = match.end()
            if i < n and s[i] == "(":
                end = close_of(s, i)
                if end < 0:
                    return None
                steps.append(("call", match.group()))
                i = end + 1
            else:
                steps.append(("field", match.group()))
        else:
            return None
    return head, steps


def receiver_text(line: str, end: int) -> str | None:
    """The receiver of the `.name` whose dot is at `end`: the postfix chain ending just before it."""
    stop = end
    while stop > 0 and line[stop - 1] in " \t":
        stop -= 1
    start = stop
    while True:
        if start > 0 and line[start - 1] in ")]":
            opening = open_of(line, start - 1)
            if opening < 0:
                return None
            start = opening
            word = start
            while word > 0 and (line[word - 1].isalnum() or line[word - 1] == "_"):
                word -= 1
            if word < start:
                start = word
            elif start > 0 and line[start - 1] in ")]":
                continue
            else:
                break
        else:
            word = start
            while word > 0 and (line[word - 1].isalnum() or line[word - 1] == "_"):
                word -= 1
            if word == start:
                return None
            start = word
        before = start
        while before > 0 and line[before - 1] in " \t":
            before -= 1
        if before > 0 and line[before - 1] == ".":
            start = before - 1
            while start > 0 and line[start - 1] in " \t":
                start -= 1
            continue
        break
    if start > 0 and line[start - 1] in "$%" and (start < 2 or line[start - 2] in " \t(["):
        start -= 1
    return line[start:stop]


def element(kind: str | None) -> str | None:
    """The kind of an element of `kind`, indexed: an array's element, a dictionary's value."""
    if kind is None:
        return None
    if kind.startswith(ARRAY):
        return kind[len(ARRAY) :] or None
    if kind.startswith(DICT):
        return kind[len(DICT) :].partition(SEP)[2] or None
    return UNTRACKED if kind == UNTRACKED else None


def iterated(kind: str | None) -> str | None:
    """The kind an untyped `for` variable takes over `kind`: an array's element, a dictionary's key."""
    if kind is not None and kind.startswith(DICT):
        return kind[len(DICT) :].partition(SEP)[0] or None
    return element(kind)


@dataclass(frozen=True)
class Decl:
    """One declaration of a name in a block: its file line, its indent, the kind it says (empty where untyped or
    unknown), and how far it reaches (`Tree.visible`)."""

    line: int
    indent: int
    kind: str
    body_only: bool = False
    whole: bool = False


class Scope(Mapping[str, str]):
    """The names a block declares, as seen from one line of it: a name's kind, empty where it is not known there. A
    name that shadows a member of the file's class, on a line no declaration of it reaches (after a `for` over it,
    before a later `var`), is not in the scope there, so the member is read."""

    def __init__(self, tree: Tree, path: str, index: int, line: int) -> None:
        self.tree, self.path, self.index, self.line = tree, path, index, line

    def __getitem__(self, name: str) -> str:
        decls = self.tree.decls[self.path][self.index].get(name)
        if not decls:
            raise KeyError(name)
        if self.tree.member_field_type(self.path, name)[0] and not any(
            self.tree.visible(self.path, d, self.line) for d in decls
        ):
            raise KeyError(name)
        return self.tree.kind_at(self.path, self.index, name, self.line)

    def __iter__(self) -> Iterator[str]:
        return iter(self.tree.decls[self.path][self.index])

    def __len__(self) -> int:
        return len(self.tree.decls[self.path][self.index])


class Tree:
    """The classes under `src/` and how a receiver's class is told."""

    def __init__(self, src: dict[str, str], autoloads: dict[str, str]) -> None:
        self.src = src
        self.bare = {path: check_layers.blank(text).bare for path, text in src.items()}
        self.autoloads = autoloads
        self.opted_out = {path for path, text in src.items() if opt_out_of(text) is not None}
        self.by_name: dict[str, str] = {}
        for path, bare in self.bare.items():
            named = check_layers.CLASS_NAME.search(bare)
            if named:
                self.by_name[named.group(1)] = path
        for name, path in autoloads.items():
            if path in src:
                self.by_name.setdefault(name, path)
        self.name_of = {path: name for name, path in self.by_name.items()}
        # Every file under src/, a class or not, with its members; `classes` are those a receiver can name.
        self.files: dict[str, Klass] = {}
        for path, bare in self.bare.items():
            parent = EXTENDS.search(bare)
            self.files[path] = Klass(
                path, self.name_of.get(path, ""), self.by_name.get(parent.group(1)) if parent else None
            )
        self.classes = {path: klass for path, klass in self.files.items() if path in self.name_of}
        self.preloads: dict[str, dict[str, str]] = {
            path: {name: (target if target in self.classes else UNTRACKED) for name, target in PRELOAD.findall(text)}
            for path, text in src.items()
        }
        # Each inner class, under its file's path, INNER and its name, read from its block with one indent taken off.
        self.inner_bare: dict[str, str] = {}
        bases: dict[str, str] = {}
        for path, bare in self.bare.items():
            for block in blocks_of(bare):
                head = INNER_HEAD.match(block)
                if head:
                    key = f"{path}{INNER}{head.group(1)}"
                    body = block.split("\n", 1)[1] if "\n" in block else ""
                    self.inner_bare[key] = re.sub(r"(?m)^(?:\t|    )", "", body)
                    self.files[key] = Klass(key, "", None)
                    if head.group(2):
                        bases[key] = head.group(2)
        for key, base in bases.items():
            kind = self.annotation(base, key)
            self.files[key] = Klass(key, "", kind if kind in self.files else None)
        self.blocks: dict[str, list[str]] = {path: blocks_of(bare) for path, bare in self.bare.items()}
        self.indents: dict[str, list[int | None]] = {
            path: [len(line) - len(line.lstrip(" \t")) if line.strip() else None for line in bare.split("\n")]
            for path, bare in self.bare.items()
        }
        self.decls: dict[str, list[dict[str, list[Decl]]]] = {
            path: [{} for _ in self.blocks[path]] for path in self.bare
        }
        for path in self.files:
            self.collect_members(path)
        for _ in range(ROUNDS):
            for path in self.bare:
                self.collect_declared(path)
            for path in self.files:
                self.collect_field_types(path)

    def ancestors(self, path: str) -> list[str]:
        """The file of `path`'s class and of every class it extends, nearest first."""
        chain: list[str] = []
        current: str | None = path
        while current and current not in chain and current in self.files:
            chain.append(current)
            current = self.files[current].parent
        return chain

    def related(self, a: str, b: str) -> bool:
        return a == b or a in self.ancestors(b) or b in self.ancestors(a)

    def annotation(self, text: str, path: str) -> str | None:
        """The kind a type annotation names in `path`'s file."""
        t = text.strip()
        if not t or t == "Variant":
            return None
        container = re.fullmatch(r"(Array|Dictionary)[ \t]*\[(.*)\]", t)
        if container:
            if container.group(1) == "Array":
                return ARRAY + (self.annotation(container.group(2), path) or "")
            parts = [*split_top(container.group(2)), ""]
            return DICT + (self.annotation(parts[0], path) or "") + SEP + (self.annotation(parts[1], path) or "")
        if t == "Array":
            return ARRAY
        if t == "Dictionary":
            return DICT + SEP
        outer = path.split(INNER)[0]
        if "." in t:
            first, _, rest = t.partition(".")
            owner = self.by_name.get(first) or self.preloads.get(outer, {}).get(first)
            inner = f"{owner}{INNER}{rest}"
            return inner if owner and inner in self.files else UNTRACKED
        if f"{outer}{INNER}{t}" in self.files:
            return f"{outer}{INNER}{t}"
        if t in self.by_name:
            return self.by_name[t]
        return self.preloads.get(outer, {}).get(t, UNTRACKED)

    def text_of(self, path: str) -> str:
        """A file's blanked code, or an inner class's body with one indent taken off."""
        return self.inner_bare[path] if INNER in path else self.bare[path]

    def collect_members(self, path: str) -> None:
        bare = self.text_of(path)
        klass = self.files[path]
        for match in VAR.finditer(bare):
            klass.fields.setdefault(match.group(1), None)
        for match in FUNC.finditer(bare):
            klass.methods.add(match.group(1))
        for match in FUNC_RETURN.finditer(bare):
            klass.returns[match.group(1)] = self.annotation(match.group(2), path)

    def collect_declared(self, path: str) -> None:
        """For each top-level block (a func, a var, an inner class), every declaration of a name in it, with the kind
        it says (empty where untyped or unknown), its line and its indent, for `kind_at` to scope."""
        start = 0
        lines = self.bare[path].split("\n")
        for index, block in enumerate(self.blocks[path]):
            inner = bool(INNER_CLASS.match(block))
            found: dict[str, list[Decl]] = {}
            headers = [(m.start(), m.end()) for m in FUNC_PARAMS.finditer(block)]

            def line_of(offset: int, block: str = block, start: int = start) -> int:
                return start + block.count("\n", 0, offset)

            def add(
                name: str,
                kind: str | None,
                offset: int,
                body_only: bool = False,
                found: dict[str, list[Decl]] = found,
                headers: list[tuple[int, int]] = headers,
                inner: bool = inner,
                line_of: Callable[[int], int] = line_of,
            ) -> None:
                line = line_of(offset)
                header = next((h for h in headers if h[0] <= offset < h[1]), None)
                if header is not None:
                    line, body_only = line_of(header[0]), True
                indent = self.indents[path][line] or 0
                text = lines[line].lstrip()
                if text.startswith("for "):
                    body_only = True
                whole = inner and indent == 1 and bool(VAR.match(text))
                found.setdefault(name, []).append(Decl(line, indent, kind or "", body_only, whole))

            for header in FUNC_PARAMS.finditer(block):
                offset = header.start(1)
                for param in split_top(header.group(1)):
                    word = IDENT.match(param.strip())
                    if word and ((":" not in param and "=" not in param) or re.match(r"\s*\w+\s*=", param)):
                        add(word.group(), None, offset)
                    offset += len(param) + 1
            for match in NAME_TYPED.finditer(block):
                add(match.group(1), self.annotation(match.group(2), path), match.start())
            for match in NAME_INFERRED.finditer(block):
                scope = Scope(self, path, index, line_of(match.start()))
                add(match.group(1), self.infer(statement(block, match.start(2)), path, scope, inner), match.start())
            for match in NAME_UNTYPED.finditer(block):
                add(match.group(1), None, match.start())
            for match in FOR_UNTYPED.finditer(block):
                scope = Scope(self, path, index, line_of(match.start()))
                add(match.group(1), iterated(self.infer(match.group(2), path, scope, inner)), match.start(), True)
            self.decls[path][index] = found
            start += block.count("\n") + 1

    def kind_at(self, path: str, index: int, name: str, line: int) -> str:
        """The kind of `name` on `line` of block `index`: the kind every declaration agrees on, or else the one the
        declarations in scope there agree on; empty where they do not."""
        decls = self.decls[path][index].get(name, [])
        kinds = {d.kind for d in decls}
        if len(kinds) == 1:
            return kinds.pop()
        kinds = {d.kind for d in decls if self.visible(path, d, line)}
        return kinds.pop() if len(kinds) == 1 else ""

    def visible(self, path: str, decl: Decl, line: int) -> bool:
        """Whether a declaration is in scope on `line`: a var from the next line on while no line is indented less, a
        for variable or a parameter on its own line and the lines indented deeper, an inner class's member everywhere
        in it."""
        if decl.whole:
            return True
        if line < decl.line or (line == decl.line and not decl.body_only):
            return False
        indents = self.indents[path]
        for number in range(decl.line + 1, line + 1):
            indent = indents[number]
            if indent is not None and (indent < decl.indent or (decl.body_only and indent <= decl.indent)):
                return False
        return True

    def collect_field_types(self, path: str) -> None:
        """The kind of each top-level var of a class, where its declaration says."""
        klass = self.files[path]
        bare = self.text_of(path)
        for match in VAR.finditer(bare):
            name, rest = match.group(1), match.group(2)
            typed = re.match(rf"[ \t]*:[ \t]*({TYPE})(?![\w.(])", rest)
            inferred = re.match(r"[ \t]*:=[ \t]*", rest)
            built = re.match(r"[ \t]*=[ \t]*([A-Z]\w*)[ \t]*\.[ \t]*new[ \t]*\(", rest)
            target: str | None = None
            if typed:
                target = self.annotation(typed.group(1), path)
            elif inferred:
                rhs = statement(bare, match.start(2) + inferred.end())
                target = self.infer(re.sub(r"[ \t]*:$", "", rhs), path, {}, False)
            elif built:
                target = self.annotation(built.group(1), path)
            klass.fields[name] = target

    def member_field_type(self, path: str, name: str) -> tuple[bool, str | None]:
        """Whether `path`'s class or an ancestor declares var `name`, and its kind."""
        for ancestor in self.ancestors(path):
            fields = self.files[ancestor].fields
            if name in fields:
                return True, fields[name]
        return False, None

    def declaring(self, path: str, name: str) -> str | None:
        """The file of the class in `path`'s ancestry that declares var `name`."""
        return next((a for a in self.ancestors(path) if name in self.files[a].fields), None)

    def method_return(self, path: str, word: str) -> tuple[bool, str | None]:
        """Whether `path`'s class or an ancestor declares method `word`, and the kind it returns."""
        for ancestor in self.ancestors(path):
            klass = self.files[ancestor]
            if word in klass.methods:
                return True, klass.returns.get(word)
        return False, None

    def infer(self, expr: str, own: str, declared: Mapping[str, str], inner: bool) -> str | None:
        """The kind of an expression, as far as static reading tells it."""
        text = expr.strip().rstrip("\\").strip()
        if not text:
            return UNTRACKED
        flat = top_level(text)
        cast = CAST_TAIL.search(flat)
        if cast:
            return self.annotation(cast.group(1), own)
        if re.search(r"(?:^|\s)if\s", flat) and re.search(r"\selse\s", flat):
            parts = re.split(r"\s+if\s+", text, maxsplit=1)
            other = re.split(r"\s+else\s+", text, maxsplit=1)
            if len(parts) == 2 and len(other) == 2:
                yes = self.infer(parts[0], own, declared, inner)
                no = self.infer(other[1], own, declared, inner)
                if yes == no:
                    return yes
                # Two classes, one extending the other: the value is the base.
                if yes in self.files and no in self.files:
                    if yes in self.ancestors(no):
                        return yes
                    if no in self.ancestors(yes):
                        return no
                return None
            return None
        if re.search(r"[-+*/%<>=!&|^~]", flat.strip()) or WORD_OPERATOR.search(flat):
            return UNTRACKED
        first = text[0]
        if first.isdigit() or text in ("true", "false") or re.match(r"func\b", text):
            return UNTRACKED
        if first == "[":
            return ARRAY if close_of(text, 0) == len(text) - 1 else None
        if first == "{":
            return DICT + SEP if close_of(text, 0) == len(text) - 1 else None
        if text == "null":
            return None
        chain = postfix(text)
        if chain is None:
            return None
        return self.evaluate(chain, own, declared, inner)

    def evaluate(
        self, chain: tuple[Step, list[Step]], own: str, declared: Mapping[str, str], inner: bool
    ) -> str | None:
        (kind_of_head, word), steps = chain
        current: str | None
        if kind_of_head == "node":
            current = UNTRACKED
        elif kind_of_head == "paren":
            current = self.infer(word, own, declared, inner)
        elif kind_of_head == "call":
            if word in ("preload", "load"):
                current = UNTRACKED
            elif word == "Array":
                # The constructor gives an untyped array: its element is a Variant.
                current = ARRAY
            elif word == "Dictionary":
                current = DICT + SEP
            else:
                has, returned = self.method_return(own, word)
                if has:
                    current = returned
                elif word in self.by_name or word[0].isupper():
                    current = UNTRACKED
                else:
                    current = None if word in VARIANT_CALLS else UNTRACKED
        else:
            current = self.first_class(word, own, declared, inner)
        for step, name in steps:
            current = self.step(current, step, name)
        return current

    def first_class(self, word: str, own: str, declared: Mapping[str, str], inner: bool) -> str | None:
        if word == "self":
            return UNTRACKED if inner else (own if own in self.classes else UNTRACKED)
        # An inner class of the file, named bare (`In.new()`), as `annotation` resolves it, ahead of a global class.
        if word[0].isupper() and f"{own.split(INNER)[0]}{INNER}{word}" in self.files:
            return f"{own.split(INNER)[0]}{INNER}{word}"
        if word in self.by_name:
            return self.by_name[word]
        if word in declared:
            return declared[word] or None
        has, typed = self.member_field_type(own, word)
        if has:
            return typed
        preloads = self.preloads.get(own.split(INNER)[0], {})
        if word in preloads:
            return preloads[word]
        # Anything else is an engine class, an enum or a constant, or an engine property of the file's own class:
        # every name the file declares was found above.
        return UNTRACKED

    def chain_class(self, chain: str, own: str, declared: Mapping[str, str], inner: bool) -> str | None:
        """The kind a chain such as `a.b().c` evaluates to, where every step is known."""
        parsed = postfix(chain)
        return self.evaluate(parsed, own, declared, inner) if parsed else None

    def step(self, current: str | None, step: str, word: str) -> str | None:
        if current is None:
            return None
        if step == "index":
            return element(current)
        if current.startswith((ARRAY, DICT)):
            if step == "field":
                return None if current.startswith(DICT) else UNTRACKED
            if word == "duplicate":
                return current
            if current.startswith(ARRAY):
                if word in ELEMENT_CALLS:
                    return element(current)
                if word in ("slice", "filter", "map"):
                    return ARRAY
            else:
                key, _, value = current[len(DICT) :].partition(SEP)
                if word in ("get", "get_or_add"):
                    return value or None
                if word == "find_key":
                    return key or None
                if word == "keys":
                    return ARRAY + key
                if word == "values":
                    return ARRAY + value
            return None if word in VARIANT_CALLS else UNTRACKED
        if current == UNTRACKED:
            if step == "field":
                return UNTRACKED
            return None if word in VARIANT_CALLS else UNTRACKED
        if step == "call":
            if word == "new":
                return current
            has, returned = self.method_return(current, word)
            if has:
                return returned
            return None if word in VARIANT_CALLS else UNTRACKED
        has, typed = self.member_field_type(current, word)
        return typed if has else UNTRACKED


def blocks_of(bare: str) -> list[str]:
    """The file split at its margin lines: each block is a margin line and the lines under it, up to the next margin
    line (a func with its parameters and body, a var, an inner class). Line breaks are kept, so `block_lines` can
    map a line to its block."""
    blocks: list[str] = []
    current: list[str] = []
    for line in bare.split("\n"):
        if line.strip() and not line[0].isspace() and current:
            blocks.append("\n".join(current))
            current = []
        current.append(line)
    blocks.append("\n".join(current))
    return blocks


def block_index(bare: str) -> list[int]:
    """For each line, the index of its block in `blocks_of`."""
    index = 0
    count = 0
    out: list[int] = []
    for line in bare.split("\n"):
        if line.strip() and not line[0].isspace() and count:
            index += 1
            count = 0
        count += 1
        out.append(index)
    return out


def inner_lines(bare: str) -> list[bool]:
    """For each line, whether it is inside an inner class (a `class X:` at the margin and the indented lines after)."""
    inside = False
    flags: list[bool] = []
    for line in bare.split("\n"):
        if line.strip() and not line[0].isspace():
            inside = bool(INNER_CLASS.match(line))
        flags.append(inside)
    return flags


def var_names_of(tree: Tree) -> set[str]:
    """The names a class a receiver can name declares as a var (a file with a `class_name` or an autoload name): the
    vars this check lists reads of. A var only an inner class or a file with no `class_name` declares is not among
    them."""
    return {name for klass in tree.classes.values() for name in klass.fields}


def method_names_of(tree: Tree) -> set[str]:
    """The names some file or inner class under `src/` declares as a method, less the names `var_names_of` gives
    (such a use fails as a var's), the names any of them declares as a constant or an enum, and ENGINE_PROPERTIES: on
    a receiver whose class cannot be told, such a name read without its parentheses is taken for that method, a
    reference to the function. A name only an inner class or a file with no `class_name` declares as a var, or one
    declared as a signal, is still taken for the method."""
    methods = {name for klass in tree.files.values() for name in klass.methods}
    constants = {name for bare in [*tree.bare.values(), *tree.inner_bare.values()] for name in CONSTANT.findall(bare)}
    return methods - var_names_of(tree) - constants - ENGINE_PROPERTIES


def reads_of(tree: Tree) -> Found:
    reads: dict[tuple[str, str, str, str], Read] = {}
    unknown: list[Unknown] = []
    skipped = 0
    declared_names = var_names_of(tree)
    method_names = method_names_of(tree)
    for path in sorted(tree.bare):
        own = path
        lines = tree.bare[path].split("\n")
        owner_block = block_index(tree.bare[path])
        inner = inner_lines(tree.bare[path])
        converted = path not in tree.opted_out
        for index, line in enumerate(lines):
            if "." not in line:
                continue
            for match in USE.finditer(line):
                name, call = match.group(1), match.group(2)
                is_var = name in declared_names
                if call or not (is_var or (converted and name in method_names)):
                    continue
                declared = Scope(tree, path, owner_block[index], index)
                receiver = receiver_text(line, match.start())
                klass = tree.chain_class(receiver, own, declared, inner[index]) if receiver else None
                expression = re.sub(r"\s+", " ", f"{(receiver or '').strip() or '...'}.{name}")
                if klass is None:
                    if not converted:
                        skipped += 1
                    else:
                        unknown.append(Unknown(path, index + 1, expression, UNKNOWN_VAR if is_var else UNKNOWN_METHOD))
                    continue
                if not is_var or klass not in tree.classes:
                    continue
                owner = tree.declaring(klass, name)
                if owner is None or tree.related(klass, own) or owner == own or owner in tree.ancestors(own):
                    continue
                key = (path, tree.classes[owner].name, name, owner)
                found = reads.get(key)
                reads[key] = Read(
                    path,
                    found.line if found else index + 1,
                    tree.classes[owner].name,
                    name,
                    (found.count if found else 0) + 1,
                )
    return Found(sorted(reads.values(), key=lambda r: (r.klass, r.reader, r.name)), skipped, unknown)


def render(tree: Tree, found: Found) -> str:
    """The list as `--write` writes it: a header, then each class's group, its reader lines sorted."""
    out = [LIST_HEADER]
    klasses: dict[str, list[Read]] = {}
    for read in found.reads:
        klasses.setdefault(read.klass, []).append(read)
    for klass in sorted(klasses):
        out.append(f"# [{klass}] {tree.by_name.get(klass, '')}")
        seen: set[tuple[str, str]] = set()
        for read in sorted(klasses[klass], key=lambda r: (r.reader, r.name)):
            if (read.reader, read.name) not in seen:
                seen.add((read.reader, read.name))
                out.append(f"{read.reader} {read.name}")
        out.append("")
    return "\n".join(out).rstrip("\n") + "\n"


def entries_of(text: str) -> list[Entry]:
    entries: list[Entry] = []
    seen: set[tuple[str, str, str]] = set()
    klass = ""
    for number, raw in enumerate(text.splitlines(), start=1):
        tag = GROUP_TAG.match(raw.strip())
        if tag:
            klass = tag.group(1)
            continue
        body = raw.partition("#")[0]
        if not body.strip():
            continue
        parts = body.split()
        if len(parts) != 2:
            raise FieldReadsError(f"{LIST_NAME}:{number}: expected '<reader file> <field>', got {raw!r}")
        if not klass:
            raise FieldReadsError(f"{LIST_NAME}:{number}: {raw.strip()} is above the first '# [Class]' header")
        entry = Entry(klass, parts[0], parts[1], number)
        if entry.key in seen:
            raise FieldReadsError(f"{LIST_NAME}:{number}: {parts[0]} {parts[1]} is listed twice under {klass}")
        seen.add(entry.key)
        entries.append(entry)
    return entries


def failures_of(found: Found, entries: list[Entry]) -> list[str]:
    """A read not listed fails; a listed line with no read is a REMOVE line; an unknown receiver in a file without
    the opt-out line fails."""
    listed = {e.key for e in entries}
    present = {(r.klass, r.reader, r.name) for r in found.reads}
    failures = [
        f"{r.reader}:{r.line}: reads {r.klass}.{r.name}, a field of another class ({r.count} line(s) in this file); "
        f"ask {r.klass} through a method instead"
        for r in found.reads
        if (r.klass, r.reader, r.name) not in listed
    ]
    failures.extend(unknown_failure(u) for u in found.unknown)
    failures.extend(
        f"REMOVE from {LIST_PATH}: {e.path} {e.name} (no longer reads {e.klass}.{e.name})"
        for e in entries
        if e.key not in present
    )
    return failures


def unknown_failure(u: Unknown) -> str:
    """The failure line for a use `reads_of` could not let stand in a file without the opt-out line."""
    where = f"{u.reader}:{u.line}"
    if u.kind == UNKNOWN_METHOD:
        return (
            f"{where}: cannot tell the class of the receiver in `{u.expression}`, in a file without the opt-out line,"
            " and a class under src/ declares that name as a method: a method read without its parentheses is a"
            " reference to the function, always true; call it with `()`, or read the receiver through a typed name"
            f' ({TYPED_NAME}); where the name is a dictionary\'s key, subscript it (`station["blocks"]`), or read'
            " the dictionary that holds it through a typed name (`var station: Dictionary = ...`), a nested one"
            " included"
        )
    return (
        f"{where}: cannot tell the class of the receiver in `{u.expression}`, in a file without the opt-out line;"
        f" type the declaration, or read the value through a typed name ({TYPED_NAME})"
    )


def line_failures(files: dict[str, str]) -> list[str]:
    """A malformed opt-out line, and any other warning annotation that names, or may name, one of its warnings: the
    line has one form, so every ignore the engine honours is one the check reads."""
    out: list[str] = []
    for path in sorted(files):
        text = files[path]
        opt_out = opt_out_of(text)
        if opt_out is not None and opt_out.problem:
            out.append(
                f"{path}:1: the opt-out line is malformed: {opt_out.problem}; its one form is"
                f" `{canonical_line(opt_out.warnings)}`"
            )
        elif opt_out is not None and not opt_out.warnings:
            out.append(f"{path}:1: the opt-out line names no warning; delete it")
        for ignore in ignores_of(text):
            if ignore.offset == 0 and opt_out is not None:
                continue
            named = [w for w in WARNINGS if w in ignore.names]
            if not named and not ignore.unreadable:
                continue
            what = ", ".join(named) if named else f"an argument the check cannot read (possibly {WARNINGS[0]}, ...)"
            if ignore.line == 1:
                out.append(
                    f"{path}:1: ignores {what} in a form other than the opt-out line's one form; write the whole"
                    f" first line as `{canonical_line(named)}`, in double quotes with nothing after it"
                )
            else:
                out.append(
                    f"{path}:{ignore.line}: ignores {what} below the first line; the only ignore of"
                    f" {', '.join(WARNINGS)} is the opt-out line, a file's whole first line in one form"
                    f" (`{canonical_line(named)}`), on a file not yet typed"
                )
    return out


def lines_of(files: dict[str, str]) -> dict[str, tuple[str, ...]]:
    """The files carrying the opt-out line, each with the warnings it names."""
    out: dict[str, tuple[str, ...]] = {}
    for path, text in files.items():
        opt_out = opt_out_of(text)
        if opt_out is not None:
            out[path] = opt_out.warnings
    return out


def base_line_failures(
    now: dict[str, tuple[str, ...]], base: dict[str, tuple[str, ...]], renames: dict[str, str], checker_changed: bool
) -> list[str]:
    """Against the base, a file that gains the opt-out line, or a warning on it, fails: that list only shrinks."""
    if checker_changed:
        return []
    moved_from = {new: old for old, new in renames.items()}
    out: list[str] = []
    for path in sorted(now):
        before = base.get(moved_from.get(path, path))
        if before is None:
            out.append(
                f"{path}:1: gains the opt-out line, and the files carrying it only shrink; {what_to_write(path)}"
            )
            continue
        added = [w for w in now[path] if w not in before]
        if added:
            out.append(
                f"{path}:1: the opt-out line gains {', '.join(added)}, and it only shrinks; {what_to_write(path)}"
            )
    return out


def what_to_write(path: str) -> str:
    """What a file that would need the opt-out line is given instead: a suite its typed header, anything else a
    typed declaration or a typed name to read through."""
    typed = f"type the declaration, or read the value through a typed name ({TYPED_NAME})"
    if path.startswith("tests/"):
        return (
            f"a suite takes the runner typed, `{SUITE_HEADER}`, as does every function it hands the runner to"
            f" ({SUITE_SECTION}); otherwise {typed}"
        )
    return typed


def uses_in(tree: Tree, paths: set[str]) -> Counter[tuple[str, str]]:
    """The uses of each class's field (class name, field) by the reader files in `paths`, counted as `reads_of` does."""
    uses: Counter[tuple[str, str]] = Counter()
    for read in reads_of(tree).reads:
        if read.reader in paths:
            uses[(read.klass, read.name)] += read.count
    return uses


def lifted_from_inner(e: Entry, head: Tree, before: Tree, renames: dict[str, str]) -> bool:
    """Whether `e`'s class is an inner class of `before` lifted into a file of its own: the class's file is new since
    `before` (not a file git reports renamed from one), `before` declared the field in an inner class `head` no
    longer declares, and the new class declares every var of that inner class. A class that declares only some of the
    vars of a deleted or renamed inner class is a new class and fails. One that declares them all is taken for that
    class lifted, whatever else it is (an inner class of one var: a single shared name is enough), and one inner
    class vouches for each new class that declares its vars; every such line is an added line review reads."""
    path = head.by_name.get(e.klass)
    if path is None or path in before.src or path in renames.values():
        return False
    declared = set(head.files[path].fields)
    for key, body in before.inner_bare.items():
        file, _, inner = key.partition(INNER)
        if f"{renames.get(file, file)}{INNER}{inner}" in head.inner_bare:
            continue
        names = {match.group(1) for match in VAR.finditer(body)}
        if e.name in names and names <= declared:
            return True
    return False


def base_failures(
    entries: list[Entry],
    base: list[Entry] | None,
    renames: dict[str, str],
    checker_changed: bool,
    head: Tree,
    before_tree: Callable[[], Tree],
) -> list[str]:
    """Against the base's list, a line added fails (the list only shrinks) unless its read moved:

    1. its reader file moved: git reports it renamed from the file of a removed line of the same class and field;
    2. its reader file is new since the base and the field's uses did not grow: over the files that differ between
       the base and the head, the head's uses of that class's field are no more than the base's (one count per class
       and field, so a file split into several passes);
    3. its class is an inner class of the base lifted into a file of its own, which `lifted_from_inner()` states
       (a new file, not a git rename, declaring every var of an inner class the head no longer declares). Nothing is
       counted there: the base could not see a read of an inner class's field.

    `head` is the head's tree; `before_tree` reads the base's, called only when an added line is neither listed nor
    paired by a rename, since building it costs seconds."""
    if base is None or checker_changed:
        return []
    listed = {e.key for e in base}
    now = {e.key for e in entries}
    gone = [e for e in base if e.key not in now]
    paired: set[tuple[str, str, str]] = set()
    counts: list[Counter[tuple[str, str]]] = []
    trees: list[Tree] = []

    def base_tree() -> Tree:
        if not trees:
            trees.append(before_tree())
        return trees[0]

    def moved(e: Entry) -> bool:
        for g in gone:
            if g.key not in paired and g.klass == e.klass and g.name == e.name and renames.get(g.path) == e.path:
                paired.add(g.key)
                return True
        return False

    def not_grown(e: Entry) -> bool:
        before = base_tree()
        if e.path in before.src:
            return False
        if not counts:
            differing = {p for p in {*head.src, *before.src} if head.src.get(p) != before.src.get(p)}
            counts.extend([uses_in(head, differing), uses_in(before, differing)])
        return counts[0][(e.klass, e.name)] <= counts[1][(e.klass, e.name)]

    return [
        f"{LIST_NAME}:{e.number}: {e.path} {e.name} is added under [{e.klass}], and the list only shrinks; "
        f"read {e.klass}.{e.name} through a method of {e.klass} instead"
        for e in entries
        if e.key not in listed
        and not moved(e)
        and not not_grown(e)
        and not lifted_from_inner(e, head, base_tree(), renames)
    ]


def summary(found: Found, carrying: dict[str, tuple[str, ...]] | None = None) -> list[str]:
    """Lines per reader layer and per class read, over the list's lines (one per reader file and field), then the
    files still carrying the opt-out line, per top-level folder, and the uses skipped in them."""
    lines_of_list = {(r.klass, r.reader, r.name) for r in found.reads}
    per_layer = Counter(check_layers.layer_of(reader) or "no layer" for _, reader, _ in lines_of_list)
    per_class = Counter(klass for klass, _, _ in lines_of_list)
    out = [f"{len(lines_of_list)} line(s) in {len(per_class)} class(es)"]
    out.append("by the layer of the reader:")
    out.extend(f"  {layer:10} {count}" for layer, count in per_layer.most_common())
    out.append("the ten classes whose fields are read most:")
    out.extend(f"  {klass:28} {count}" for klass, count in per_class.most_common(10))
    if carrying is not None:
        per_folder = Counter(path.split("/", 1)[0] for path in carrying)
        out.append(f"{len(carrying)} file(s) still carry the opt-out line:")
        out.extend(f"  {folder:10} {count}" for folder, count in sorted(per_folder.items()))
        per_warning = Counter(w for names in carrying.values() for w in names)
        out.extend(f"  naming {warning:24} {per_warning[warning]}" for warning in WARNINGS)
    out.append(
        f"{found.skipped} use(s) skipped for an unknown receiver of a name some class declares as a var, in files"
        " carrying the opt-out line"
    )
    if found.unknown:
        out.append(f"{len(found.unknown)} such use(s) in files without it, each a failure")
    return out


def autoloads_of(project: str) -> dict[str, str]:
    return dict(check_layers.autoloads_of(project))


def line_scope(path: str) -> bool:
    """Whether `path` is read for the opt-out line: a `.gd` file outside docs/ and outside any hidden folder."""
    parts = path.split("/")
    return path.endswith(".gd") and parts[0] not in LINE_SKIPPED and not any(p.startswith(".") for p in parts)


def read_checkout(root: Path) -> tuple[dict[str, str], dict[str, str], str]:
    src = {p.relative_to(root).as_posix(): p.read_text(encoding="utf-8") for p in sorted((root / SRC).rglob("*.gd"))}
    project = root / "project.godot"
    listing = root / LIST_PATH
    return (
        src,
        autoloads_of(project.read_text(encoding="utf-8")) if project.exists() else {},
        listing.read_text(encoding="utf-8") if listing.exists() else "",
    )


def read_scripts_checkout(root: Path) -> dict[str, str]:
    """Every `.gd` file the opt-out line is read in, from the checkout."""
    out: dict[str, str] = {}
    for top in sorted(root.iterdir()):
        if not top.is_dir() or not line_scope(f"{top.name}/x.gd"):
            if top.is_file() and line_scope(top.name):
                out[top.name] = top.read_text(encoding="utf-8")
            continue
        for path in sorted(top.rglob("*.gd")):
            relative = path.relative_to(root).as_posix()
            if line_scope(relative):
                out[relative] = path.read_text(encoding="utf-8")
    return out


def read_scripts_rev(rev: str, root: Path) -> dict[str, str]:
    """Every `.gd` file the opt-out line is read in, from the tree of `rev`."""
    listing = check_layers.git("ls-tree", "-r", "-z", rev, cwd=root).decode()
    blobs: dict[str, str] = {}
    for record in listing.split("\0"):
        meta, _, path = record.partition("\t")
        if path and line_scope(path) and meta.split()[1] == "blob":
            blobs[path] = meta.split()[2]
    if not blobs:
        return {}
    batch = check_layers.git("cat-file", "--batch", cwd=root, data="".join(f"{b}\n" for b in blobs.values()).encode())
    texts: dict[str, str] = {}
    position = 0
    for path in blobs:
        header_end = batch.index(b"\n", position)
        size = int(batch[position:header_end].split()[2])
        start = header_end + 1
        texts[path] = batch[start : start + size].decode("utf-8", errors="replace")
        position = start + size + 1
    return texts


def read_rev(rev: str, root: Path) -> tuple[dict[str, str], dict[str, str], str]:
    tree = check_layers.read_rev(rev, root)
    listing = ""
    if check_layers.git("ls-tree", "--name-only", rev, "--", LIST_PATH, cwd=root).strip():
        listing = check_layers.git("show", f"{rev}:{LIST_PATH}", cwd=root).decode("utf-8")
    return dict(tree.files), dict(tree.autoloads), listing


def read_base(rev: str, cwd: Path) -> list[Entry] | None:
    """The list as `rev` held it, or None when `rev` has no list yet."""
    check_layers.git("rev-parse", "--verify", "--quiet", f"{rev}^{{commit}}", cwd=cwd)
    if not check_layers.git("ls-tree", "--name-only", rev, "--", LIST_PATH, cwd=cwd).strip():
        return None
    return entries_of(check_layers.git("show", f"{rev}:{LIST_PATH}", cwd=cwd).decode("utf-8"))


def read_checker_changed(base: str, cwd: Path, rev: str | None = None) -> bool:
    args = ["diff", "--name-only", base] + ([rev] if rev else []) + ["--", f"tools/{SELF_NAME}"]
    return bool(check_layers.git(*args, cwd=cwd).strip())


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/check_field_reads.py",
        description=__doc__,
        epilog=(
            "Examples:\n  uv run python tools/check_field_reads.py\n"
            "  uv run python tools/check_field_reads.py --base origin/main\n"
            "  uv run python tools/check_field_reads.py --write\n  uv run python tools/check_field_reads.py --summary"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    source = parser.add_mutually_exclusive_group()
    source.add_argument(
        "--rev", default=None, help="read the tree of this commit, and its list, instead of the checkout"
    )
    source.add_argument(
        "--root", type=Path, default=None, help="read the checkout at this path, and its list, instead of this one"
    )
    parser.add_argument(
        "--base",
        default=None,
        metavar="REV",
        help=(
            "also fail a line added since REV's list unless its read only moved (see the rule above), and a .gd file"
            " that gains the opt-out line or a warning on it"
            " since REV (one new since REV included, one git reports as renamed keeping its base's line); CI passes"
            " the pull request's base commit, and on main the previous one; neither fails when the diff also"
            " changes this checker; a REV with no list yet compares no list lines"
        ),
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--list",
        action="store_true",
        help="print every read found, listed or not, and every unknown receiver in a converted file, without failing",
    )
    mode.add_argument(
        "--summary",
        action="store_true",
        help=(
            "print the lines per reader layer and per class read, how many files still carry the opt-out line"
            " (per top-level folder and per warning), and how many uses are still skipped in them"
        ),
    )
    mode.add_argument(
        "--write",
        action="store_true",
        help="rewrite tools/field_reads.txt from the tree, sorted; resolves a merge conflict in it",
    )
    args = parser.parse_args(argv)
    if args.write and (args.rev or args.base):
        parser.error("--write rewrites the checkout's list: it takes no --rev and no --base")
    return args


def main(argv: list[str]) -> int:
    args = parse(argv)
    root = args.root or ROOT
    try:
        src, autoloads, text = read_rev(args.rev, root) if args.rev else read_checkout(root)
        scripts = read_scripts_rev(args.rev, root) if args.rev else read_scripts_checkout(root)
        tree = Tree(src, autoloads)
        found = reads_of(tree)
        if args.write:
            (root / LIST_PATH).write_text(render(tree, found), encoding="utf-8")
            print(f"wrote {LIST_PATH}: {len({(r.klass, r.reader, r.name) for r in found.reads})} line(s)")
            return 0
        entries = entries_of(text)
        failures = failures_of(found, entries) + line_failures(scripts)
        if args.base:
            base = read_base(args.base, root)
            renames = read_renames(args.base, root, args.rev)
            changed = read_checker_changed(args.base, root, args.rev)
            if base is not None:

                def before_tree() -> Tree:
                    base_src, base_autoloads, _ = read_rev(args.base, root)
                    return Tree(base_src, base_autoloads)

                failures.extend(base_failures(entries, base, renames, changed, tree, before_tree))
            failures.extend(
                base_line_failures(lines_of(scripts), lines_of(read_scripts_rev(args.base, root)), renames, changed)
            )
    except (check_layers.LayerError, FieldReadsError, OSError) as error:
        print(f"tools/check_field_reads.py: {error}", file=sys.stderr)
        return 1
    if args.summary:
        print("\n".join(summary(found, lines_of(scripts))))
        return 0
    if args.list:
        listed = {e.key for e in entries}
        for r in found.reads:
            mark = "listed" if (r.klass, r.reader, r.name) in listed else "NEW"
            print(f"{mark:6} {r.reader}:{r.line}: {r.klass}.{r.name} ({r.count})")
        for u in found.unknown:
            print(f"UNKNOWN {u.reader}:{u.line}: {u.expression}")
        for line in failures:
            if line.startswith(("REMOVE", LIST_NAME)):
                print(line)
        print(f"{len(found.reads)} reader file/field pair(s), {len(failures)} failure(s)")
        return 0
    for failure in failures:
        print(failure if failure.startswith("REMOVE") else f"FAILED: {failure}")
    if failures:
        print(f"tools/check_field_reads.py: {len(failures)} failure(s)")
        return 1
    carrying = lines_of(scripts)
    print(
        f"OK: no new read of another class's field; {len(entries)} listed line(s) still stand;"
        f" {len(carrying)} file(s) still carry the opt-out line"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
