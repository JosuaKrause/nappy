## M164 — Engine errors make the test gate red · built 2026-09-20

> "create a todo for the bug report with enough detail to pick it up without additional
> investigative work" · on its place in the order: "M164 is a bug? also important."
> ([PLAYTEST-108](../playtests/PLAYTEST-108.md))

`tests/run_tests.gd` counts failed assertions only, so an engine `ERROR:`, a `push_error()` or
a script error printed while the process exited 0, and `tools/test.sh` trusted that status; its
local sharded reporter printed only timings and `FAIL` lines, so the error text was dropped as
well. M163's eight errors hid behind exactly that.

**Built.** `run_one_process()` tees the combined output and returns non-zero when Godot did or
when the output matches `SCRIPT ERROR|Parse Error|ERROR:`, `check.sh`'s own vocabulary, for
every caller; the sharded reporter greps each shard's log for the same words, prints the
offending lines and fails the aggregate. `--record-costs` leaves the cost table alone after
any failed run, a failed assertion included — wider than the engine-error case the entry
named, and open to overturn. `tests/runner_fixtures/engine_error.gd` raises a sentinel
`push_error()` and passes its one check; discovery still finds only top-level `test_*.gd`, so
it runs only by name, and a step in CI's `gates` job requires the non-zero exit, the sentinel
and the runner's summary line together.

**What the gate found on its first full run.** `tests/test_save.gd` hands `GameSave` a garbled
save on purpose. The save was dropped correctly and every check passed, and the static
`JSON.parse_string()` printed `ERROR: Parse JSON failed` each time, so the suite exited 1 on
1113966 passing checks. A garbled save is expected input, so the fix is in the game:
`GameSave._read_now()` parses with `JSON.new().parse()`, which reports by return value and
prints nothing — verified in this engine version with a throwaway script — the same shape
`GroundLayers._load_manifest()` already had. The one other `parse_string` site round-trips
the test's own data. Whitelisting the line was the rejected option.

**Verified.** The fixture exits 1 with sentinel and summary; a clean suite exits 0; a planted
failed check exits 1; `--serial` and `--shard 1/8` classify the same way; a local sharded run
with a planted error flags the right shards; a failed `--record-costs` leaves
`tests/suite_costs.txt` byte-identical; the unfiltered suite exits 0 with no engine error in
the combined log. `WARNING:` lines are outside the vocabulary and do not trip it; warning
policy and import-pass failures were out of scope.
