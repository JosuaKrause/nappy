# A method named without its parentheses on a typed receiver is reported

**Proposed, not asked for:** the whole item is the orchestrator's proposal. The player's words on the
field-read check ask that it be made to work (inbox #1268 in olive-ferret) and say nothing of a
method read without its parentheses. The plainer alternative is to leave it: the naming rule keeps
the conversion of a yes-or-no field from creating the case (below), and what is left is listed
under "What is left".

**The trap.** `thing.is_ready`, where `is_ready` is a method, is a reference to the function: always
true in a condition, and a statement that does nothing where a call was meant (`crowd.clear` for
`crowd.clear()`). A name in a condition trips no warning of the engine's. A name alone on a line
trips the engine's warning for a statement that does nothing (`standalone_expression`), which
`project.godot` makes an error, so that case fails the parse.

**What reports it today.**

- The engine, for a method's name alone on a line: `project.godot` makes `standalone_expression`
  an error, and no line of the tree trips it (minty-quail-round-dolphin).
- `tools/check_field_reads.py` fails a method's name read through a receiver whose class it cannot
  tell, in a file under `src/` without the opt-out line. Its `--help` says which names count.
- The naming rule of designing-classes ("Fields are not API"), for every conversion of a yes-or-no
  field: its method takes a name the field did not have, so a read left behind after a conversion
  names something that no longer exists. It stops parsing on a typed receiver in a file that does
  not silence `unsafe_property_access`; everywhere else it fails when the line runs.

**What nothing reports:** the same mistake on a receiver the check can type (a class under `src/` or
an engine value), in a file under `src/` that still carries the opt-out line, in a test, or as a
bare name of the file's own class with no receiver (`if is_ready:`).

**What is left.**

- A method's name written without its parentheses by hand, in new code or an edit, where no field
  of that name ever was.
- A read a conversion leaves behind where the new name fails only when the line runs: in a file
  whose opt-out line names `unsafe_property_access` (`tools/check_field_reads.py --summary` counts
  them; `src/main.gd` and `src/dev/scene_recipe_runtime.gd` are among the heaviest readers), on a
  receiver typed too wide, and on a Variant. A clean boot does not show that none is left there.
- `EventDef.investigates()`, which took its yes-or-no field's name before the rule; no read of it
  without parentheses is left, and a rename is a change of its own.
- **A field that is not yes-or-no and goes behind a method of its own name**, where a read left
  behind is one that takes a function silently. The record minty-quail-coral-trout
  (`tools/decisions.sh coral-trout`) holds what was measured: a test for truth or against null, a
  `match`, `in`, `has()` and `get()`, a format string, an untyped argument, an inferred `:=` and an
  equality between two reads of the field all take one silently; arithmetic, an ordering
  comparison and a typed argument fail. Cases in the tree: the row's `pursuit`, a part or null
  tested against null; its `look`, an enum read in a `match`; `Run.index`, compared between two
  runs. The events' design names accessors after such fields (`pursuit()`, `look()`).

**How the rest is handled.**

- **The new name stops at yes-or-no fields**: shown that a wider rule (every converted field's
  method a new name, or every one but a number's) renames accessors across the events' design,
  the player answered "A", stop at yes-or-no fields (inbox #1349). A third way, the name kept
  wherever every read of the field fails, is ruled out: it needs a list of such reads, and the
  same record says how three wordings of one were each wrong. Asked on the board whether each
  conversion's pull request also shows a search for the old name read without its parentheses
  coming back empty, which finds the read the conversion missed and not one a branch merged later
  brings: open, and no rule holds it until the player answers.
- **A rule in the field-read check**: a typed receiver's method named with no `(` after it fails
  unless the reference hands the `Callable` on. The same record says what a first build of this
  was, why it left its pull request, and where its code is. Built again, the list of forms that
  hand a `Callable` on has one owner, the checker's docstring, with a unit case per form, and no
  other text restates it.
