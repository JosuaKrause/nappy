extends RefCounted
## `ControlsMode.from_word()`, the bare mapping a real command line or URL query parameter's own
## raw word goes through — the part of `resolve()` a test can ask without a real command line or a
## Web export behind it.

func run(t) -> void:
	_test_from_word_only_tap_reads_as_tap(t)

func _test_from_word_only_tap_reads_as_tap(t) -> void:
	t.check(ControlsMode.from_word("tap") == ControlsMode.Mode.TAP,
			"the word 'tap' resolves to tap mode")
	t.check(ControlsMode.from_word("stick") == ControlsMode.Mode.STICK,
			"the word 'stick' resolves to the stick")
	t.check(ControlsMode.from_word("") == ControlsMode.Mode.STICK,
			"nothing given falls back to the stick")
	t.check(ControlsMode.from_word("TAP") == ControlsMode.Mode.STICK,
			"an unrecognised spelling falls back to the stick rather than guessing")
