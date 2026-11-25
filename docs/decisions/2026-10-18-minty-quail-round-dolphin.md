# minty-quail — A statement that does nothing fails the parse · 2026-11-10

**The ask.** None: the item `method-without-parentheses.md` is the orchestrator's proposal, not the
player's. The player asked that the field-read check be made to work (inbox #1268 in
olive-ferret) and said nothing of a method named without its parentheses. This builds the second
of the item's ways, the engine's own warning raised to an error.

## What was built

- `project.godot`'s `[debug]` block sets `gdscript/warnings/standalone_expression=2`, beside the
  three typing warnings, with a comment saying what it catches: a method's name alone on a line
  (`crowd.clear` written for `crowd.clear()`) fails the parse. A name inside a condition, an
  argument or an assignment still parses, as the record minty-quail-busy-heron measured.
- `tools/typing_census.py --lines standalone_expression` on `main` at the time reported no line
  under `src/`, `tests/` or `tools/` that trips it, so no line of code changes and nothing in play
  changes.
- The **godot** skill's "Types" says the warning is an error and what it does not reach; the item
  says the engine now reports the case and drops the built way from its list.

## Open to the player's overturn

- **The whole step**, as the item's proposal: the plainer alternative was to leave the warning at
  the engine's default, where no headless run prints it.
