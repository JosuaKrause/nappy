# What a suite owes the runner, and what the runner does about it

Part of **verify**. Read it when a run fails in a way the one-line rules in `SKILL.md` do not
explain (a `LEAK` line, a `QUIT` line, a run with no closing line, a `SCRIPT ERROR` under a green
count, a file `check.sh` says it reverted), and before changing the runner or its fixtures.

## A suite leaves nothing changed

**After every suite the runner compares the shared state with what it was before, and fails the
suite that changed it** (`tests/shared_state.gd`): the tree's `paused`, `Engine.time_scale`,
`Engine.max_physics_steps_per_frame`, `Engine.physics_ticks_per_second`, `Input.mouse_mode`, the
nodes under the root and the runner, each `InputMap` action's events and deadzone, which actions
`Input` holds pressed, every autoload's variables, those of each `RefCounted` an autoload holds (one level deep, named
`<autoload>.<field>.<its field>`), the connections on its signals, and every `static var` under
`src/`, found by reading the sources. The failure line names
the field and its value before and after (`LEAK` is printed the moment it is found). A suite fixes a
leak by giving back what it took (a released action, a disconnected signal, a freed node, a fake
injected instead of a static patched); it is never retried and the runner does not clear it.
Exceptions are fields, never owners: `EXEMPT` in that file names each with its reason (memoised
statics); no owner is skipped, and no autoload is the run or an observer of it: each test is
handed a fresh run, and the run log and the visit counter are nodes `main` keeps under the boot's
sitting, freed with it, so a suite that reads what a boot logs hands it a recording fake
(`tests/recording_log.gd`, through `main.use_run_log()`). A new exemption needs a reason of that kind, not a convenience.

## When a suite errors

**An error inside a suite's own `run()` ends that suite and nothing else.** A runtime bug in the
suite's own test logic (a null call, say) prints `SCRIPT ERROR`, in a plain `run()` or in a
coroutine one after an `await`. The suite stops at the error and its remaining checks are skipped;
the runner goes on to the next suite and reports no failure for it. Only
`tools/test.sh`'s scan for `SCRIPT ERROR`, `Parse Error` and `ERROR:` makes the exit non-zero, so
a run read without that script's verdict can look green. Nothing hangs. The loader guard below
covers a suite that fails to load, not this path.

**A suite that quits the tree ends the whole process at the runner's next frame.** The exit is 0
and the runner's closing "N checks, M failures" line never prints, so every later suite of the
shard is dropped. The runner prints a `QUIT` line naming the suite that was running, and
`tools/test.sh` fails any run without the closing line (or with a look-alike before the last
timing line). `tests/runner_fixtures/quits_the_tree.gd` proves it, and a suite that drives code
which quits (as `RouteRig` does) uses a stand-in that does not (`tests/route_rig_no_quit.gd`).

**A suite that fails to parse is a named `FAIL` line and a normal exit, not a hang.** `_discover`
loads every suite before running any, but `load()` on a broken suite returns a `GDScript`
that `can_instantiate()` refuses, and `_ready()` checks that before calling `.new()`. A suite that
cannot load is recorded as a failure by name, the suites that did load still run, and the runner
reaches `quit()` non-zero either way. `tests/runner_fixtures/unparseable_suite.gd.src` is the
fixture that proves it — kept off its real `.gd` name because an unparseable `.gd` anywhere in
the tree can break the atlas bake's own engine boot when `.godot/`'s class-name cache is cold; see
that file's own header and the record `tools/decisions.sh M172` prints (a suite that fails to
parse fails the test run).

**A new suite that fails to load with "Warning treated as error" on its `run(t)` line is missing
the typed runner header**: **writing-tests**, "A suite is typed, and opens with the typed runner
header", gives the two lines.

**The way to see a genuine hang is to stop piping the run into `tail`** — `tail` prints nothing
until EOF, so a hung run and a silent one look identical. Redirect to a file and read it; the
message is usually on line four.

**`tools/test.sh runner_fixtures/unparseable_suite.gd` stages that fixture as a real `.gd` for the
one process and removes it on exit**, and CI requires that run to fail within seconds, so a
runner that hangs on a broken suite is a red check rather than a stuck job.

## An engine error is a failed run, whatever the checks say

**`tools/test.sh` exits non-zero when Godot's output carries `ERROR:`, `SCRIPT ERROR` or `Parse
Error`** — the words `check.sh` already fails a boot on — in a filtered, serial, single-shard or
locally sharded run alike, and shows the offending lines. Godot prints those and still exits 0,
and the runner counts only failed `check()` calls, so the exit code alone would pass them. So a
test that feeds the game bad input on purpose has to reach a code path that reports it by return
value: `JSON.new().parse()` rather than the static `JSON.parse_string()`, which prints.
`tests/runner_fixtures/engine_error.gd` raises one on purpose, runs only when named, and CI
requires it to go red.

## `check.sh` puts back what its import pass rewrites

**The import pass rewrites two files that have nothing to do with the check.** It turns runs of
spaces into tabs in `docs/ARCHITECTURE.md`'s file tree, and it makes the editor rewrite
`project.godot`, which loses more than whitespace: every `;` comment is stripped and a setting can
go outright, `window/stretch/aspect="keep"` among them, which is load-bearing for the presentation.
`check.sh` records whether each was clean before it ran and reverts it afterwards if it was,
printing which file it reverted; the revert runs from an `EXIT` trap, so it also happens when the
check fails. **A file you had already edited is left alone and named**, since reverting it would
delete real work to fix a whitespace bug; read it with `git diff`. `tools/export-web.sh` stamps
`project.godot` with the build's version and commit for the export's duration and puts it back
from a copy on every exit, so the editor's rewrite never survives an export either.
