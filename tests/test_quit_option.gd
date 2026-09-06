extends RefCounted
## `QuitOption._web_override()`, the pure check `available()` runs through — pulled out so this can
## be driven with a synthetic command line and a chosen build kind rather than a real debug build
## carrying `--web` on its own, the same split `tests/test_telemetry.gd` takes on
## `Telemetry._reads_the_url()`.

func run(t) -> void:
	_test_web_override_needs_both_a_debug_build_and_the_flag(t)
	_test_available_matches_the_platform_when_nothing_overrides_it(t)

func _test_web_override_needs_both_a_debug_build_and_the_flag(t) -> void:
	t.check(QuitOption._web_override(true, PackedStringArray(["--web"])),
			"a debug build carrying --web asks for the web shape")
	t.check(not QuitOption._web_override(true, PackedStringArray()),
			"a debug build with no flag at all does not")
	t.check(not QuitOption._web_override(false, PackedStringArray(["--web"])),
			"a release build cannot reach it even with the flag on its own command line — "
			+ "there is no command line to reach it with")
	t.check(not QuitOption._web_override(true, PackedStringArray(["--seed", "--web-nothing"])),
			"an unrelated flag, or a word that merely contains '--web', does not match")

## Nothing in this test process is ever a web export, so `available()` — with no override in
## play — must answer exactly what a desktop platform always does: quitting works.
func _test_available_matches_the_platform_when_nothing_overrides_it(t) -> void:
	t.check(QuitOption.available(), "this test process is never a Web export, so quitting is on")
