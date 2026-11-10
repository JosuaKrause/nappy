# minty-quail — A method never takes its field's name where the field is read as a truth test, in every conversion (minty-quail, field reads) · 2026-11-10


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

- **designing-classes, "Fields are not API"**: a method never takes its field's name where a read
  of the field can stand as a truth test: a yes-or-no field, and a value its readers test for
  truth or against null (a part that may be missing, a count). A read left behind then names
  nothing and fails. A value read only in arithmetic, a comparison with a number or a typed
  assignment may keep its name. The events' interface design had the rule for a yes-or-no question
  and let a number keep its name (its third naming rule); that it holds for every conversion and
  for a value tested for truth or against null is the orchestrator's, and the skill's "Proposed,
  not asked for" says so.
- **`event-interface.md`'s third naming rule** says where a read left behind fails at the parse
  and where only when it runs, and that a part's accessor is under the rule where readers test its
  field against null today, as they do the row's `pursuit`: the step that makes such a field
  private names the accessor anew, where the design's list has `pursuit()`.
- **`field-reads.md`'s last bullet**, which had the method take the field's name in the files the
  placement rewrite and the third hand-ins pull request touch: a yes-or-no field's method takes a
  new name there too.
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
  always true; `"%s" % t.label` and `str(t.count)` print the function's name. Arithmetic, a
  comparison with a number and a typed assignment fail the parse. So the boundary is how a field
  is read, not its declared type, and the rule is written on that. The row's `pursuit` is the
  case in the tree: a part or null, listed for 17 reader files and tested against null 39 times
  under `src/`.
- A name that no longer exists fails the parse on a typed receiver through `unsafe_property_access`
  alone. In a file whose opt-out line names that warning (42 files then, 14 of them under `src/`),
  and on a receiver typed too wide, it parses and fails only when the line runs.

**Rejected:** leaving the field's name everywhere outside the events, the plan as it stood. It
costs nothing to write and leaves every read a conversion misses true and unreported, on fields
such as whether a building is the home, whether a contact point is done and whether the run is a
rig.
