# A method named without its parentheses on a typed receiver is reported

**Proposed, not asked for:** the whole item is the orchestrator's proposal. The player's words on the
field-read check ask that it be made to work (inbox #1268 in olive-ferret) and say nothing of a
method read without its parentheses. The plainer alternative is to leave it: the events' interface
already keeps conversion from creating the case (below), and nothing else is built.

**The trap.** `thing.is_ready`, where `is_ready` is a method, is a reference to the function: always
true in a condition, and a statement that does nothing where a call was meant (`crowd.clear` for
`crowd.clear()`). The engine reports neither (godot, "Types").

**What reports it today.**

- `tools/check_field_reads.py` fails a method's name read through a receiver whose class it cannot
  tell, in a file under `src/` without the opt-out line. Its `--help` says which names count.
- The events' interface's naming rule (`event-interface.md`, point 3): a yes-or-no question never
  takes the name of the field it replaces, so a read left behind after a conversion names
  something that no longer exists and stops parsing.

**What nothing reports:** the same mistake on a receiver the check can type (a class under `src/` or
an engine value), in a test, or as a bare name of the file's own class with no receiver
(`if is_ready:`).

**Ways to build it, none chosen.** The first step of the work is to find which of these the engine
and the code allow, by experiment:

- **The engine's own warning for a statement that does nothing**, raised to an error like the three
  warnings of the typed-access step. Whether it fires on a method's name standing alone is the
  experiment; it cannot see the name in a condition.
- **The naming rule beyond the events**: a method that replaces a field never takes the field's
  name, written into designing-classes for every conversion. It covers what conversion creates and
  nothing typed wrong by hand.
- **A rule in the field-read check**: a typed receiver's method named with no `(` after it fails
  unless the reference hands the `Callable` on. The record minty-quail-busy-heron
  (`tools/decisions.sh busy-heron`) says what a first build of this was, why it left its pull
  request, and where its code is. Built again, the list of forms that hand a `Callable` on has one
  owner, the checker's docstring, with a unit case per form, and no other text restates it.
