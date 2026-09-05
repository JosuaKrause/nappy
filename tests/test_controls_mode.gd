extends RefCounted
## `ControlsMode.from_word()` and `_word_from_query()`, the bare parsing and mapping a real command
## line or a real `window.location.search` goes through — the parts of `resolve()` a test can ask
## without a real command line or a Web export behind either.

func run(t) -> void:
	_test_from_word_only_tap_reads_as_tap(t)
	_test_word_from_query_finds_the_controls_key_among_others(t)

func _test_from_word_only_tap_reads_as_tap(t) -> void:
	t.check(ControlsMode.from_word("tap") == ControlsMode.Mode.TAP,
			"the word 'tap' resolves to tap mode")
	t.check(ControlsMode.from_word("stick") == ControlsMode.Mode.STICK,
			"the word 'stick' resolves to the stick")
	t.check(ControlsMode.from_word("") == ControlsMode.Mode.STICK,
			"nothing given falls back to the stick")
	t.check(ControlsMode.from_word("TAP") == ControlsMode.Mode.STICK,
			"an unrecognised spelling falls back to the stick rather than guessing")

## `window.location.search` carries the whole query string, `?` included and every other parameter
## alongside `controls` -- the parsing has to find the one key among them, with or without the
## leading `?` a real browser gives it.
func _test_word_from_query_finds_the_controls_key_among_others(t) -> void:
	t.check(ControlsMode._word_from_query("?controls=tap") == "tap",
			"the leading '?' a real address bar gives is not part of the key")
	t.check(ControlsMode._word_from_query("controls=tap") == "tap",
			"and it parses just as well without one")
	t.check(ControlsMode._word_from_query("?seed=4242&controls=tap&day=3") == "tap",
			"controls is found among other query parameters, wherever it sits")
	t.check(ControlsMode._word_from_query("?seed=4242") == "",
			"a query with no controls key answers empty rather than guessing")
	t.check(ControlsMode._word_from_query("") == "", "no query at all is also empty")
