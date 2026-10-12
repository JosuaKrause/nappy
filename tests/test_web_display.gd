extends RefCounted
## Focused contracts for `WebDisplay`: the frame goes straight to the screen on a page that asks
## for it, behind the same gate `?controls=` has, and never on a native build.

func run(t) -> void:
	_test_direct_to_screen_needs_a_page_and_a_request(t)
	_test_direct_is_read_from_the_query(t)
	_test_the_cap_is_read_from_the_query(t)
	_test_the_gate(t)
	_test_apply_does_nothing_off_a_page(t)

func _test_direct_to_screen_needs_a_page_and_a_request(t) -> void:
	t.check(WebDisplay.direct_to_screen_wanted(true, true), "a page that asks renders straight to the screen")
	t.check(not WebDisplay.direct_to_screen_wanted(true, false), "a page that does not ask keeps its texture")
	t.check(not WebDisplay.direct_to_screen_wanted(false, true),
			"a native build keeps the viewport's texture for screenshots and telemetry")

func _test_direct_is_read_from_the_query(t) -> void:
	t.check(WebDisplay._direct_from_query("?direct=1"), "?direct=1 asks")
	t.check(WebDisplay._direct_from_query("debug=1&direct=1&seed=4"), "found among other parameters")
	t.check(not WebDisplay._direct_from_query("?direct=0"), "direct=0 does not ask")
	t.check(not WebDisplay._direct_from_query(""), "no parameter, no request")

func _test_the_cap_is_read_from_the_query(t) -> void:
	t.check(is_equal_approx(WebDisplay._cap_from_query("?dpr=1.5"), 1.5), "?dpr=1.5 caps at 1.5")
	t.check(is_equal_approx(WebDisplay._cap_from_query("dpr=2"), 2.0), "the leading ? is optional")
	t.check(is_equal_approx(WebDisplay._cap_from_query("?debug=1&dpr=1&seed=4"), 1.0),
			"found among other parameters")
	t.check(WebDisplay._cap_from_query("") == 0.0, "no parameter, no cap")
	t.check(WebDisplay._cap_from_query("?dpr=abc") == 0.0, "a word is no cap")
	t.check(WebDisplay._cap_from_query("?dpr=") == 0.0, "an empty value is no cap")
	t.check(WebDisplay._cap_from_query("?dpr=0") == 0.0, "zero is no cap, not a blank canvas")
	t.check(WebDisplay._cap_from_query("?dpr=-1") == 0.0, "a negative value is no cap")
	t.check(WebDisplay.dpr_cap() == 0.0, "no cap off a page")

func _test_the_gate(t) -> void:
	t.check(WebDisplay._reads_the_url(true, true), "an open bundle on a page reads the query")
	t.check(not WebDisplay._reads_the_url(false, true), "a release page without ?debug=1 reads nothing")
	t.check(not WebDisplay._reads_the_url(true, false), "off a page there is no address bar")

func _test_apply_does_nothing_off_a_page(t) -> void:
	WebDisplay.apply(Engine.get_main_loop().root)
	t.check(true, "apply off a page returns without touching the renderer")
