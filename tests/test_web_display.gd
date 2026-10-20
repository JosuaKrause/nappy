extends RefCounted
## Focused contracts for `WebDisplay`: the page's `?dpr=` cap is read out of the query the run's
## configuration read at boot, behind the release-safe bundle's gate, and asks nothing of a native
## build.

func run(t) -> void:
	_test_the_cap_is_read_from_the_query(t)
	_test_the_gate(t)
	_test_apply_asks_nothing_off_a_page(t)

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
	t.check(WebDisplay.dpr_cap(RunConfig.parse(PackedStringArray(), "?debug=1&dpr=1.5", false))
			== 0.0, "no cap off a page, whatever the query")

func _test_the_gate(t) -> void:
	t.check(WebDisplay._reads_the_url(true, true), "an open bundle on a page reads the query")
	t.check(not WebDisplay._reads_the_url(false, true), "a release page without ?debug=1 reads nothing")
	t.check(not WebDisplay._reads_the_url(true, false), "off a page there is no address bar")

func _test_apply_asks_nothing_off_a_page(t) -> void:
	var config := RunConfig.parse(PackedStringArray(), "", true)
	WebDisplay.apply(config)
	t.check(WebDisplay.dpr_cap(config) == 0.0, "a native build is capped by nothing")
