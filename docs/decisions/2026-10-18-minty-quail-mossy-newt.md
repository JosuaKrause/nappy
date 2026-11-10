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
- **How the run is made and undone**: the tool refuses to start without the import cache (it names
  `./tools/check.sh`) or while `project.godot` has uncommitted changes; it sets the three warnings to
  warn and every other to off in `project.godot`, blanks each opt-out line (so line numbers stay
  put), runs `tools/typing_census.tscn` headless over the file list, and puts back, byte for byte
  and only in the files it changed, `project.godot` and each first line, on every exit, an
  interrupt or a timeout; a file whose first line changed meanwhile is named and left as found.
- **A census counts only from a run that finished**: the engine exits 0, its scene prints
  `CENSUS_DONE` with the count handed, and every path is answered once; otherwise every mode stops
  and changes no file. A file that fails to load fails `--check`; `--write` refuses while a failed
  file is under `src/`, is an autoload, or is named by another listed file, since its dependents'
  counts cannot be trusted. A message of none of the three warnings stops the tool rather than
  miscount. It cannot see an opt-out line inside a string a suite writes at run time.
- `tools/test_typing_census.py` (34 cases, each naming the mutation it fails, run by `tools/pycheck.sh`), the entry point in
  `tools/test_cli_help.py`, the using-tools row, and the field-read check's blind-spots sentence:
  a stale name on an opt-out line is found by the census's `--check`.

## What it found on `main` at the time

`src/telemetry/telemetry_observer.gd` names `untyped_declaration`, which it does not trip (the
telemetry typing pull request owns that file); three probes do not parse (`m159_contribution_cost`,
`minty_quail_walk_field_parity`, `lazy_scenery_city`), which no queue item owns yet, so `--check`
fails on `main` until they do and `--write` refuses while `lazy_scenery_measure.gd` preloads the
third; `standalone_expression` is tripped on no line
under `src/`, `tests/` or `tools/`.
