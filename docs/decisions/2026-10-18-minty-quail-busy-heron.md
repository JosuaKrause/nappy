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
  parse. The warnings are generated only in a debug build, so the release Web export is not
  affected; the editor's binary, a debug build and a script loaded at run time are.
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
  365 of 414 under `tests/`, 2 of 3 under `tools/`). A probe a merge of `main` brought,
  `tests/probes/walk_rows.gd`, gained the line after that, naming the two warnings it trips. Two
  test suites write a script at run time and boot it in a child process; each such script opens
  with the line too.
- **`tools/check_field_reads.py`**: in a file under `src/` without the line, a read whose
  receiver's class it cannot tell fails, naming the file, the line and the expression; in a file
  with the line it is skipped and counted, as before. The line itself is checked wherever it
  stands (first line, only the three warnings, each once, literals only, no other ignore of the
  three anywhere in the file); the line has one form (the whole first line, double quotes, the
  three warnings in a fixed order, nothing after), and any other `@warning_ignore`, `_start` or
  `_restore` naming one of the three, or whose argument it cannot read, fails. In a file under
  `src/` without the line, a method's name read through a receiver it cannot tell fails too,
  whether or not it is handed on: a name some file or inner class under `src/` declares as a
  method, unless a class a receiver can name (a file with a `class_name` or an autoload name)
  declares it as a var (the use then fails as the var's), it is a constant or an enum, or it is in
  the fixed list `ENGINE_PROPERTIES`. A method named without its parentheses on a receiver the
  check can type is not seen ("Built and taken out", below). `--summary` prints the files still
  carrying the line by folder and by warning and the uses still skipped; `--base` fails a file that
  gains the line or a warning on it.
- **The checker's docstring is the one text of what the check sees**, printed by `--help`, with a
  unit case per stated form; the skills and the using-tools row say what the check is for and
  point at it.
- **The checker types far more receivers than it did**: engine and builtin types, typed arrays and
  dictionaries with indexing and loops, inner classes, preloaded constants, constructors, node
  paths, arithmetic, a ternary of a class and its subclass. The uses it skips fell from 2,320 to
  34, and on the day it was built it saw 290 reads it could not see before, which
  `tools/field_reads.txt` gained (the list's own rule allows that when the checker changes);
  conversions merged from `main` since have taken some of them out again. Nothing was converted
  here.

## What it still cannot see

- a chain through an engine property typed Variant (`JSON.data`);
- a read of another file's inner class's field;
- a chain from `self` inside an inner class;
- a bare name nothing declares, taken for an engine property;
- a method named without its parentheses on a receiver the check can type (a class under `src/` or
  an engine value), or as a bare name of its own class with no receiver;
- a parameter of a function whose parameter list closes at the margin (a line starting with `)`),
  which has no type for the check;
- a var only an inner class or a file with no `class_name` declares, which is not a var for the
  check: a receiver it cannot tell read with such a name fails only where some file or inner class
  declares the name as a method;
- a further read of a field its reader file is already listed for;
- a name left on an opt-out line that its file no longer trips.

## Choices the builder made, open to the player's overturn

- The check fails an unknown receiver per file, from the day a file loses its line, where the
  design had it fail only once no file carried the line.
- The line names its warnings in one fixed order; a warning added to a line, and a new file
  carrying the line, fail `--base`.
- The scripts under `docs/evidence/` get no line and are not read: they are frozen and rerun from
  the revision they name.
- Three probes that already fail to parse on `main` are left as they were.
- The engine's own names are not taken for methods: `ENGINE_PROPERTIES` lists the engine's names
  among the method names nothing else excuses (an engine class's property or signal, a builtin
  type's member), read from the engine (its class list and `--dump-extension-api`). An engine name
  that is also a named class's var needs no entry, since the use fails as the var's. It is a fixed
  list: a method added later with another engine name is taken for a method until the list gains
  it, and a change to what excuses a name means reading the list from the engine again, as the
  rethink's build showed: it exposed three names (`rect`, `nodes`, `continued`) the list then
  gained.
- The method failure applies only in a file without the opt-out line and only on a receiver the
  check cannot tell; a name only an inner class or a file with no `class_name` declares as a var,
  or one declared as a signal, does not excuse it. The player's words ask that the field-read
  check be made to work (inbox #1268 in olive-ferret) and say nothing of a method read without its
  parentheses, so the whole method failure is the builder's choice.

## Built and taken out: a typed receiver's method named without its parentheses

The orchestrator's ruling on the first review added a second half to the method rule: on a
receiver the check can type, the receiver's own method named without its parentheses failed unless
the reference handed the Callable on (a step following it, `.bind(` or `.call(`; a call's argument;
an array literal's element; an assignment's right side; a returned value; a ternary's branch). It
was built, and it left the pull request in the orchestrator's rethink after the third *not ready*
verdict (the pull request's conversation holds the rethink), a choice open to the player's
overturn:

- the list of accepted forms was restated in six texts (the checker's docstring, `--help`'s own
  description, the godot skill, the using-tools row, this record and the description), and one of
  them had drifted in each review round;
- the rule did not reach 58 method names, `crowd.clear` among them, the example four of those
  texts gave;
- the findings that came back round after round were in this half and in the texts restating its
  forms, a half no words of the player ask for; the half that stays had findings too, each fixed
  where it was found.

Measured in the reviews, for the item that holds this as open work: with the engine's warning for
a statement that does nothing (`standalone_expression`) raised to an error, a method's name alone
on a line fails the parse, and a name in a condition still parses. How many lines of the tree trip
that warning is not measured.

Its code (`hands_on`, `list_bracket`, `enclosing`, the `HANDED_*` patterns and their unit cases in
`tools/check_field_reads.py` and its test) is at the branch's commit `acd6704d2`, which stays
reachable through the pull request. What it costs: a stale read of a method on a typed receiver
(`thing.is_finished` after `is_finished()` replaced the field) is reported by nothing. The events'
interface's renaming rule (a yes-or-no question never takes the name of the field it replaces)
covers the reads the events' conversion creates, and only those: for the other areas the queue
has the method take the field's name (`field-reads.md`'s last bullet), so a yes-or-no field
converted there (`Building.is_home_building`, `ContactPoint.is_done`, `RunConfig.is_rig`) leaves
every missed read on a typed receiver parsing and always true. Whether the naming rule is widened
to every conversion is put to the player. The queue item
`docs/todo/2026-10-18-minty-quail/method-without-parentheses.md` holds it as open work, proposed
and not asked for.

## Measured

The whole suite could not be completed on the builder's machine under load (its shards hit their
time limit with no failure among the suites that finished); CI's whole run on the same head is
green, the Web export included.
