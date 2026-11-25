# minty-quail — The field-read check reports a typed receiver's method named without parentheses · 2026-11-12

**The ask.** The field-read check is made to work (inbox #1268 in olive-ferret); the queue's proposal, not asked for,
adds a rule to it for a method named without its parentheses on a typed receiver, a reference to the function that is
always true in a condition and does nothing as a statement (`method-without-parentheses.md`). A first build was taken
out (the record 2026-10-18-minty-quail-busy-heron): its list of accepted forms was restated in six texts that drifted,
and it missed 58 method names.

## What was built

- **The rule**: `tools/check_field_reads.py` fails a method named without its parentheses when the receiver's class is
  under `src/` and that class or an ancestor declares it, in files with or without the opt-out line, unless the
  reference hands the `Callable` on.
- **The forms that hand it on have one text, the checker's docstring** (which `--help` prints), six of them, each with a
  unit case that also fails when the hand-on test is mocked away. Every other text points at `--help`.
- **Why the first build missed names**: it asked a typed receiver only about names in the unknown-receiver rule's set,
  which drops a method name any other class also declares as a field or the engine has as a property (`crowd.clear` was
  dropped because an inner class had a var `clear`). The rule now starts from every declared method name and asks the
  receiver's own class.
- **On today's tree** it checks fifty such references and fails none; nothing under `src/` changes, and
  `tools/field_reads.txt` is unaffected.
- **Out of reach**: an engine value's method (the check knows only that it is no class under `src/`), a method a class
  under `src/` inherits from the engine, a receiver broken over lines, a bare name of the file's own class, and
  tests. The godot and designing-classes skills and the using-tools row say what the check now
  reports, and the godot skill proposes, open to the player, the rule's reach into files with the opt-out line.
- **The queue item says what reports the mistake now and what does not**, and loses the bullet that queued the rule.

## Verified

`tools/pycheck.sh` (the checker's unit cases), `tools/check.sh`, the field-read check against main, the test-only
member, layer and typing checks and lint pass; CI is green.
