## M172 — A suite that fails to parse fails the test run · built 2026-09-20

Pull request #250. Found the same day: the decoration's first push broke
`tests/test_texture_atlas.gd`'s parse, and the shard that owned it never reported — it ran
until another shard's failure cancelled it.

**What hung.** `load()` on a script with a parse error does not return null; it returns a
`GDScript` that `can_instantiate()` answers false for. `run_tests.gd` called `.new()` on it
unconditionally, the call raised, `_ready()` stopped before `quit()`, and a headless engine
with nothing to do idles forever. M164's check of the engine's output reads it after the
process ends, so it never spoke.

**Built.** The runner checks `script == null or not script.can_instantiate()` before
`.new()`, records the suite by name, prints `LOAD FAIL`, runs the suites that did load and
quits non-zero. CI's `gates` job runs the fixture under `timeout 30` and requires a non-zero
exit that is not the timeout's own, the fixture's name and the normal summary line.

**The fixture is not a `.gd` file, and why.** Committed as one, it broke every engine start
with no import cache — a fresh clone's first `check.sh` or `test.sh`: the global class scan
met a script that does not parse and every `class_name` lookup in that process failed, the
autoloads with it, while the bake still finished and its wrapper still exited zero. So the
source is `tests/runner_fixtures/unparseable_suite.gd.src`, and `tools/test.sh` copies it to
its `.gd` path only for the process that names it, after the bake and the import pass, and
removes it and its `.uid` on every exit path; `.gitignore` covers the staged names as well.

**Rejected.** A process-wide time limit in `tools/test.sh`: the modes differ in cost by orders
of magnitude, and macOS has no `timeout`, so it would be a bash watcher — a larger piece of
work than the defect.

**Open.** A suite whose own `run()` raises at runtime still stops the runner before `quit()`.
A staged fixture left behind by a killed process makes the next staging refuse and says so;
until it is deleted it is an unparseable `.gd` in the tree, with the effect described above.
One message covers a missing suite and a broken one.
