# minty-quail — A method that replaces a field takes a new name unless every read of the field is one a function fails in (minty-quail, field reads) · 2026-11-10


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

**What was written.**

- **designing-classes, "Fields are not API"**: a method that replaces a field takes a new name on
  the object the field was read from, unless every read of the field is one a function fails in
  (arithmetic, a comparison with a number, an equality with an enum's value, a typed assignment
  or argument, a loop, a member read or a call on it). A read left behind then names nothing and
  fails. The events' interface design had the rule for a yes-or-no question and let a number keep
  its name (its third naming rule); that it holds for every conversion and for every field with a
  read that takes a function silently is the orchestrator's, and the skill's "Proposed, not asked
  for" says so.
- **`event-interface.md`'s third naming rule** says where a read left behind fails at the parse
  and where only when it runs, and that an accessor of its list is under the rule where its field
  has a read that takes a function silently (the row's `pursuit`, tested against null; its `look`,
  read in a `match`): the step that makes such a field private names the accessor anew, where the
  design's list has `pursuit()` and `look()`.
- **`field-reads.md`'s last bullet**, which had the method take the field's name in the files the
  placement rewrite and the third hand-ins pull request touch: the method takes the field's name
  there only where every read of the field is one a function fails in.
- **`method-without-parentheses.md`**, the item for the same mistake on a typed receiver: the
  naming rule was the first of its three ways and is built; the item lists what is left: the
  mistake made by hand, a read left behind where the new name fails only when the line runs, and
  the one method that took its field's name before the rule.

**One method already took its yes-or-no field's name**: `EventDef.investigates()` replaced the
field `investigates` in an earlier step of this entry, and the events' interface design keeps it.
No read of it without parentheses is left under `src/`, `tests/` or `tools/`, so it does no harm;
the skill names it as the one that predates the rule, and it is not renamed here. The review's
search found no other: `EventScheduler.Planned.is_door()` sits beside `_is_door`, a field that
came in private with its method.

**Measured in the review**, on Godot 4.7.2 in a scratch project with the three warnings at error,
for a method whose name is read without its parentheses:

- `if t.target:` and `if t.target != null:` parse and are always true, on a typed receiver and on
  an untyped array's element; `if t.target == null:` parses and is always false; `if t.count:` is
  always true; `"%s" % t.label` and `str(t.count)` print the function's name.
- `match t.kind:` runs no branch; `t.count in [0, 1]` is false; `d.has(t.key)` and `d.get(t.key)`
  miss the key; `is_instance_valid(t.target)` is false; an untyped argument, an array literal and
  `print` carry the function on.
- Arithmetic, a comparison with a number, a typed assignment or argument, an equality with an
  enum's value, a loop, a member read and a call on it fail: at the parse on a typed receiver,
  when the line runs on a Variant.
- So the boundary is how a field is read, not its declared type, and the reads that take a
  function silently are too many to list as the cases the rule covers. The rule is written from
  the safe side: a new name unless every read is one a function fails in. Two cases in the tree:
  the row's `pursuit`, a part or null, listed for 17 reader files, with 34 tests of a row's
  against null under `src/`; and the row's `look`, an enum listed for 13 reader files and read in
  a `match` 15 times.
- The rule is about the object the field was read from. `LaneMover.Lane.door_ahead()` has the
  name of the mover's field and is no breach: a read left behind on the mover is still a field
  read, since the mover has no such method.
- A name that no longer exists fails the parse on a typed receiver through `unsafe_property_access`
  alone. In a file whose opt-out line names that warning (42 files then, 14 of them under `src/`),
  and on a receiver typed too wide, it parses and fails only when the line runs.

**Rejected:** leaving the field's name everywhere outside the events, the plan as it stood. It
costs nothing to write and leaves every read a conversion misses true and unreported, on fields
such as whether a building is the home, whether a contact point is done and whether the run is a
rig.
