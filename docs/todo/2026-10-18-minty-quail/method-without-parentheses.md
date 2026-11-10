# A method named without its parentheses on a typed receiver is reported

**Proposed, not asked for:** the whole item is the orchestrator's proposal. The player's words on the
field-read check ask that it be made to work (inbox #1268 in olive-ferret) and say nothing of a
method read without its parentheses. The plainer alternative is to leave it: the events' naming rule
keeps the events' conversion from creating the case. The other areas' conversions can still create
it, since `field-reads.md`'s last bullet has the method take the field's name; whether the naming
rule is widened to every conversion is a question put to the player.

**The trap.** `thing.is_ready`, where `is_ready` is a method, is a reference to the function: always
true in a condition, and a statement that does nothing where a call was meant (`crowd.clear` for
`crowd.clear()`). A name in a condition trips no warning of the engine's. A name alone on a line
trips its warning for a statement that does nothing (`standalone_expression`), which stands at the
engine's default level, a warning, and no headless run prints a warning.

**What reports it today.**

- `tools/check_field_reads.py` fails a method's name read through a receiver whose class it cannot
  tell, in a file under `src/` without the opt-out line. Its `--help` says which names count.
- The events' interface's naming rule (`event-interface.md`, point 3), for the events only: a
  yes-or-no question never takes the name of the field it replaces, so a read left behind after a
  conversion names something that no longer exists. On a typed receiver it stops parsing; on a
  value the engine types as Variant it fails when the line runs.

**What nothing reports:** the same mistake on a receiver the check can type (a class under `src/` or
an engine value), in a file under `src/` that still carries the opt-out line, in a test, or as a
bare name of the file's own class with no receiver (`if is_ready:`).

**Where it bites first:** the yes-or-no fields outside the events that `tools/field_reads.txt`
lists, such as `Building.is_home_building`, `ContactPoint.is_done`, `DayEnd.is_section`,
`RunConfig.is_rig` and `Stroller.is_male`. When one becomes a method of the same name, a read left
behind on a typed receiver parses, is always true and passes the check; the list does not catch it
either, since the name is no longer a var.

**Ways to build it, none chosen.**

- **The naming rule beyond the events**: a method that replaces a yes-or-no field never takes the
  field's name, as one sentence in designing-classes for every conversion, with `field-reads.md`'s
  last bullet changed to match. It covers what conversion creates and nothing typed wrong by hand,
  and it helps only the conversions that come after it, so it is the one way with a deadline: before
  the passes outside the events convert such fields.
- **The engine's own warning for a statement that does nothing**, raised to an error like the three
  warnings of the typed-access step. Measured (the record minty-quail-busy-heron,
  `tools/decisions.sh busy-heron`): a method's name alone on a line then fails the parse, and a name
  in a condition still parses. Not measured: how many lines of the tree trip it today.
- **A rule in the field-read check**: a typed receiver's method named with no `(` after it fails
  unless the reference hands the `Callable` on. The same record says what a first build of this
  was, why it left its pull request, and where its code is. Built again, the list of forms that
  hand a `Callable` on has one owner, the checker's docstring, with a unit case per form, and no
  other text restates it.
