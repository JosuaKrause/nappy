# minty-quail — The engine fails an access it cannot type, file by file, and the field-read check skips nothing in a converted file (minty-quail, field reads) · 2026-11-09

**The ask.** Shown that the field-read check skips about two thirds of the reads because it cannot
tell the receiver's class, the player: "isn't that the point of a class hierarchy? it should be made
working" (inbox #1268 in olive-ferret). The design review's way to do it, written after the player had approved its
points: turn GDScript's own warnings for an access the engine cannot type into errors, with a
file-level opt-out for every file not yet converted, the files carrying it being the list that only
shrinks. The item is `docs/todo/2026-10-18-minty-quail/field-reads.md`.

## What the engine can and cannot see

Checked against the engine's documentation and by experiment on the project's Godot version:

- A warning's level is a project setting: ignore, warn, or error. At error the script fails to
  parse. The warnings are generated only in a debug build, so a release export and the Web build
  are not affected; the editor's binary, a debug build and a script loaded at run time are.
- **`untyped_declaration`** fails an untyped variable, parameter, return or loop variable.
  **`unsafe_property_access`** fails a property read off a type too wide to have it (a plain
  `Node`). **`unsafe_method_access`** fails a method call the same way, and also a call on a value
  the engine types as Variant.
- **The engine warns of nothing on a property read off a Variant**: an element of an untyped array
  or dictionary, what `back()` or `get()` returns, a name declared `: Variant`. The engine alone
  cannot make "the receiver's class is unknown" impossible; the guarantee holds only through the
  engine and the check together.
- `@warning_ignore_start(...)` as a file's first line silences exactly the warnings it names for
  the whole file, inner classes included, and takes only string literals.

## What was built

- **Three warnings are errors** in `project.godot`: `untyped_declaration`,
  `unsafe_property_access` and `unsafe_method_access`. Left out: `unsafe_cast`, which would forbid
  the cast that is the fix for an untyped element; `unsafe_call_argument`, which is about
  arguments and not receivers; `inferred_declaration`, since an inferred type is already a known
  class.
- **Every file not yet typed carries one first line**, `@warning_ignore_start(...)`, naming
  exactly the warnings it still trips: 438 files on the day it was built (71 of 302 under `src/`,
  365 of 414 under `tests/`, 2 of 3 under `tools/`). Two test suites write a script at run time and
  boot it in a child process; each such script opens with the line too.
- **`tools/check_field_reads.py`**: in a file under `src/` without the line, a read whose
  receiver's class it cannot tell fails, naming the file, the line and the expression; in a file
  with the line it is skipped and counted, as before. The line itself is checked wherever it
  stands (first line, only the three warnings, each once, literals only, no other ignore of the
  three anywhere in the file). `--summary` prints the files still carrying the line by folder and
  by warning and the uses still skipped; `--base` fails a file that gains the line or a warning on
  it.
- **The checker types far more receivers than it did**: engine and builtin types, typed arrays and
  dictionaries with indexing and loops, inner classes, preloaded constants, constructors, node
  paths, arithmetic, a ternary of a class and its subclass. The uses it skips fell from 2,320 to
  34, and it sees 290 reads it could not see before, which `tools/field_reads.txt` now lists (the
  list's own rule allows that when the checker changes). Nothing was converted.

## What it still cannot see

A chain through an engine property typed Variant (`JSON.data`); a read of another file's inner
class's field; `self` inside an inner class; and a line that names a warning its file no longer
trips, which nothing catches.

## Choices the builder made, open to the player's overturn

- The check fails an unknown receiver per file, from the day a file loses its line, where the
  design had it fail only once no file carried the line.
- The line names its warnings in one fixed order; a warning added to a line, and a new file
  carrying the line, fail `--base`.
- The scripts under `docs/evidence/` get no line and are not read: they are frozen and rerun from
  the revision they name.
- Three probes that already fail to parse on `main` are left as they were.

## Measured

The whole suite could not be completed on the builder's machine under load (its shards hit their
time limit with no failure among the suites that finished); CI's whole run on the same head is
green, the Web export included.
