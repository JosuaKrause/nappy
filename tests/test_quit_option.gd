extends RefCounted
## `QuitOption.available()` with the run's configuration handed in: `--web` (`RunConfig.web_preview`)
## asks for the web shape on a debug build, and nothing else does.

func run(t) -> void:
	_test_web_preview_needs_both_a_debug_build_and_the_flag(t)
	_test_available_matches_the_platform_when_nothing_overrides_it(t)

func _test_web_preview_needs_both_a_debug_build_and_the_flag(t) -> void:
	t.check(not QuitOption.available(RunConfig.parse(PackedStringArray(["--web"]), "", true)),
			"a debug build carrying --web asks for the web shape")
	t.check(QuitOption.available(RunConfig.parse(PackedStringArray(), "", true)),
			"a debug build with no flag at all does not")
	t.check(QuitOption.available(RunConfig.parse(PackedStringArray(["--web"]), "", false)),
			"a release build cannot reach it even with the flag on its own command line — "
			+ "there is no command line to reach it with")
	t.check(QuitOption.available(
			RunConfig.parse(PackedStringArray(["--seed", "1", "--web-nothing"]), "", true)),
			"an unrelated flag, or a word that merely contains '--web', does not match")

## Nothing in this test process is ever a web export, so `available()` — with no override in
## play — must answer exactly what a desktop platform always does: quitting works.
func _test_available_matches_the_platform_when_nothing_overrides_it(t) -> void:
	t.check(QuitOption.available(), "this test process is never a Web export, so quitting is on")
