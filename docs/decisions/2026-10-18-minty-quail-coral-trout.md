# minty-quail — A method that replaces a yes-or-no field takes a new name, in every conversion (minty-quail, field reads) · 2026-11-10


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

- **designing-classes, "Fields are not API"**: a method that replaces a yes-or-no field never takes
  the field's name, so a read left behind names nothing and fails; a number or another value may
  keep its name, since a function used as a number fails at once. The rule was the events'
  interface design's alone (its third naming rule); it now holds for every conversion, and the
  skill's "Proposed, not asked for" names it as the orchestrator's.
- **`field-reads.md`'s last bullet**, which had the method take the field's name in the files the
  placement rewrite and the third hand-ins pull request touch: a yes-or-no field's method takes a
  new name there too.
- **`method-without-parentheses.md`**, the item for the same mistake on a typed receiver: the
  naming rule was the first of its three ways and is built; what is left is the mistake made by
  hand, which no conversion creates.

**Checked before writing:** no method under `src/` named `is_`, `has_`, `can_`, `was_` or `should_`
with no parameters sits beside an underscore field of its own name, so no conversion already
merged took a yes-or-no field's name and none is revisited.

**Rejected:** leaving the field's name everywhere outside the events, the plan as it stood. It
costs nothing to write and leaves every read a conversion misses true and unreported, on fields
such as whether a building is the home, whether a contact point is done and whether the run is a
rig.
