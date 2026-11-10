# minty-quail — A method that replaces a yes-or-no field takes a name the field did not have, in every conversion (minty-quail, field reads) · 2026-11-10

**Nobody asked for it.** The rule is the orchestrator's proposal, put to the player on the board as
the question naming-rule-everywhere and built on the orchestrator's pick while it is open. The
player's words on fields, "never read fields directly. always read through a method" (inbox #1173
in gray-dolphin), say nothing of what the method is called.

**The trap it closes.** Once a method has a yes-or-no field's old name, a read left behind without
its parentheses (`contact.is_done` after `is_done()` replaced the field) is a reference to the
function: it parses, is always true in a condition, and nothing reports it on a receiver whose
class is known. The field-read check sees such a name only through a receiver it cannot type, and
the rule that would have seen it on a typed receiver was built and taken out of the typed-access
pull request (the record minty-quail-busy-heron, "Built and taken out").

## What was written

- **designing-classes, "Fields are not API"**: a method that replaces a yes-or-no field takes a
  name the field did not have, on the object the field was read from, so a read left behind names
  nothing and fails. The skill says where it fails (below), that the rule stops at yes-or-no
  fields, and which method predates it. The events' interface design had the rule for its own
  conversion (its third naming rule); that it holds for every conversion is the orchestrator's,
  and the skill's "Proposed, not asked for" says so.
- **`field-reads.md`'s last bullet**, which had the method take the field's name in the files the
  placement rewrite and the third hand-ins pull request touch: the method takes the field's name
  there unless the field is a yes-or-no one.
- **`event-interface.md`'s third naming rule** names itself as designing-classes' rule, says where
  a read left behind fails at the parse and where only when it runs (it had said "fails loudly
  everywhere"), and says the rule stops at yes-or-no questions, with the two accessors of its own
  list that the open case reaches.
- **`method-without-parentheses.md`**, the item for the same mistake on a typed receiver: the
  naming rule for yes-or-no fields was the first of its ways and is built; the item lists what is
  left, the field that is not yes-or-no among it, and the question that goes to the player.

## What already stood against it

`EventDef.investigates()` replaced the yes-or-no field `investigates` in an earlier step of this
entry, and the events' interface design keeps it. No read of it without parentheses is left under
`src/`, `tests/` or `tools/`; the skill names it as the one that predates the rule, and it is not
renamed here. The review scanned every commit on `main` since v0.29.0 for a field removed with a
method of its name added on the same object and found two more, neither a yes-or-no field:
`EventDef.lets_out()`, every read of which was one a function fails in, and
`RunHeader.play_seconds()`, two of whose rewritten reads were not (an element of a format string's
list, an inferred assignment, both in a suite); no bare read of either is left.
`EventScheduler.Planned.is_door()` sits beside `_is_door`, a field that came in private with its
method. A method on another object that has a field's name (`LaneMover.Lane.door_ahead()`) is
outside the rule: a read left behind on the old object is still a field read.

## Measured in the reviews

On Godot 4.7.2, in a scratch project with the three typing warnings at error, for a method whose
name is read without its parentheses:

- **Taken silently:** `if t.target:` and `if t.target != null:` are always true and
  `if t.target == null:` always false, on a typed receiver and on an untyped array's element;
  `if t.count:` is always true; `"%s" % t.label` and `str(t.count)` print the function's name;
  `match t.kind:` runs no branch but a `_:` one; `t.count in [0, 1]` is false; `d.has(t.key)` and
  `d.get(t.key)` miss the key; `is_instance_valid(t.target)` is false; an untyped argument, an
  array literal and `print` carry the function on; `var v := t.speed` parses and `v` is then the
  function; `t.count == u.count` between two reads of the field is false and `!=` true.
- **Failing:** arithmetic, an ordering comparison, a comparison with a written number, an equality
  with an enum's value, a typed assignment or argument, a loop, a member read and a call on it, at
  the parse on a typed receiver and when the line runs on a Variant; a subscript `d[t.key]` when
  the line runs.
- **A name that no longer exists** fails the parse on a typed receiver through
  `unsafe_property_access` alone. In a file whose opt-out line names that warning (42 files then,
  14 of them under `src/`), and on a receiver typed too wide, it parses and fails only when the
  line runs.
- **Cases in the tree:** the row's `pursuit`, a part or null, listed for 17 reader files, with 34
  tests of a row's against null under `src/`; the row's `look`, an enum listed for 13 reader files
  and read in a `match` 15 times; `Run.index`, compared between two runs in
  `src/city/street_trees.gd`.

## Tried and replaced

Three wordings of when a method may keep its field's name, each written into the skill and each
found wrong by the next review, after which the orchestrator's rethink (in the pull request's
conversation) took the exception out of the skill:

- **"A number or any other value may keep its name"**: a part tested against null is caught like a
  yes-or-no field.
- **The field's name forbidden only where the field is read as a truth test**: a `match`, `in`, a
  lookup and a format string were placed nowhere, and three texts answered differently for them.
- **A new name unless every read is one of a list of reads a function fails in**: two entries of
  the list take a function silently (an equality between two reads of the field, an inferred
  assignment).

Each round measured more forms and found one more that is silent, so a list of the engine's
behaviours is not a rule a skill can hold or a builder can apply. How far the new name goes beyond
yes-or-no fields is put to the player instead, since either wider answer (every method takes a new
name; only a number keeps its name) renames accessors across the events' design.

## Rejected

Leaving the field's name everywhere outside the events, the plan as it stood. It costs nothing to
write and leaves every read of a yes-or-no field a conversion misses true and unreported, on fields
such as whether a building is the home, whether a contact point is done and whether the run is a
rig.
