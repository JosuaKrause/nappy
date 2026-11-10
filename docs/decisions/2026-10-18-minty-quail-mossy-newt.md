# minty-quail — Which typing warnings a file still trips is a tool (minty-quail, tools) · 2026-11-10

**The ask.** Code is typed wherever the language can type it, the tests included (inbox #1280 in
olive-ferret), and a file not yet typed carries one first-line `@warning_ignore_start(...)` naming
the warnings it still trips (the godot skill, "Types"). Which warnings each file trips was taken by
hand for the pull request that made the engine fail an untyped access (the record
minty-quail-busy-heron); the scripted rewrite of the suites (`typed-everywhere.md`) and each module's
typing pass need it again. A manual sequence done a second time becomes a script (woolly-finch
23). The planning agent's proposal.

## What was built

- **`tools/typing_census.py`** loads every `.gd` under `src/`, `tests/` and `tools/` once in the
  engine and prints, per file, which of the three typing warnings (`untyped_declaration`,
  `unsafe_property_access`, `unsafe_method_access`) it trips; `--lines` adds the lines. `--check`
  fails a file whose opt-out line names a warning it does not trip, lacks one it trips, or is not in
  its one form; `--write` rewrites each line to what the file trips and deletes the line of a file
  that trips none, and never adds one. Any other warning's name is counted per folder (and per line
  with `--lines`), touching no file. A name the engine has no setting for is refused before the
  run.
- **How the run is made and undone**: the tool sets the three warnings to warn and every other to
  off in `project.godot`, strips the opt-out lines, runs `tools/typing_census.tscn` headless over
  the file list, and writes `project.godot` and every stripped file back byte for byte on every exit
  and on an interrupt; it refuses to start while `project.godot` has uncommitted changes. A message
  of none of the three warnings stops it with an error rather than a miscount; a file that fails to
  parse is named and left out.
- `tools/test_typing_census.py` (sixteen cases, run by `tools/pycheck.sh`), the entry point in
  `tools/test_cli_help.py`, the using-tools row, and the field-read check's blind-spots sentence:
  a stale name on an opt-out line is found by the census's `--check`.

## What it found on `main` at the time

`src/telemetry/telemetry_observer.gd` names `untyped_declaration`, which it does not trip; three
probes do not parse (`m159_contribution_cost`, `minty_quail_walk_field_parity`,
`lazy_scenery_city`), which no queue item owns yet; `standalone_expression` is tripped on no line
under `src/`, `tests/` or `tools/`.
