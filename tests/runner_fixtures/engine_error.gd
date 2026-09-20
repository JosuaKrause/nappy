extends RefCounted
## A real Godot diagnostic, held outside suite discovery on purpose, that proves the shell
## boundary refuses an engine error even when the runner's own `check()` array stays empty.
## `run_tests.gd`'s `_discover` only walks the top of `tests/`, so this fixture runs only when
## named explicitly:
##
##     tools/test.sh runner_fixtures/engine_error.gd
##
## It is not a probe (`tests/probes/` prints measurements) and not a suite: its one job is to
## emit a `push_error()` sentinel that a passing assertion count would otherwise hide, and to keep
## passing its own check() regardless, so a run that only looked at `checks`/`failures` would
## report this run clean.

const SENTINEL := "M164 sentinel: intentional engine_error.gd push_error(), not a real defect"

func run(t) -> void:
	push_error(SENTINEL)
	t.check(true, "the fixture's own assertion still passes despite the sentinel above")
