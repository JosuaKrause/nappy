# minty-quail — The field-list tool tells what it cannot answer · 2026-11-11

**The ask.** The last review of `tools/field_answers.py` (#1366), the tool that builds a typing
pass's list of other modules' fields, found three places where it says less than it should, none
changing a line it prints on today's tree (`field-answers-gaps.md`). Not the player's request: a
review's findings, filed by the orchestrator, built as tooling first (inbox #1305 in grassy-trout).

## What was built

- **A class nested inside an inner class, named through its outer class**, in a call, a cast or a
  type, from its own file or another, gets the tool's "not told" line instead of being taken for an
  engine value. The tool reads which classes each inner class declares inside itself, so a field or
  enum of the same name is not mistaken for one.
- **A number's truthiness is no longer a null test**: a guard that tests the whole returned chain by
  its truth alone counts as a null guard only when the other value is `null`; with any other value
  the method is printed apart, behind its guard, with its whole return, as a stand-in already is. A
  guard on a prefix of the chain still counts, since a field is read off that prefix.
- **The four rules of the guards and views that no case held** each have one: every part of a guard
  joined by `and` tests the returned chain; a view is looked for only where the class has no answer
  of its own; a private method hands no view out; a guarded chain is not looked for where a method
  answers the field itself.
- **`--help` says each of these.**

## Choices open to overturn

- **Printing behind the guard rather than a sentence in `--help`** for the truthiness case, which
  the item allowed either way: the line shows what the method returns for the builder to judge,
  where a sentence alone would leave the wrong credit printed (the builder's).
- **Every stand-in other than `null` is printed behind the guard, a falsy literal included**, so
  `return count if count else 0` is printed apart though it returns the same value for an `int`: the
  tool cannot tell a number field from an object field, and this is the smaller rule to state (the
  builder's).

## Verified

The tool's `--json` over every tracked `.gd` file under `src/`, `tests/` and `tools/` is byte for
byte the same before and after. Each rule, removed on a scratch copy, fails its named case; the
table is in pull request #1369's description. `./tools/pycheck.sh` and `./tools/lint.sh` pass, and
`tools/field_reads.txt` is unchanged.
