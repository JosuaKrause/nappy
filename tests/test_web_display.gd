extends RefCounted
## Focused contracts for `WebDisplay`: the page's `?dpr=` cap is read out of the query the run's
## configuration read at boot, behind the release-safe bundle's gate, and asks nothing of a native
## build. Every check asks `dpr_cap()` for the cap of a configuration the game could have been
## started with, on a page or off one.

func run(t) -> void:
	_test_the_cap_is_read_from_the_query(t)
	_test_the_gate(t)

## The cap a release page opened on `query` is given, on a Web export.
func _cap_on_a_page(query: String) -> float:
	return WebDisplay.dpr_cap(RunConfig.parse(PackedStringArray(), query, false), true)

func _test_the_cap_is_read_from_the_query(t) -> void:
	t.check(is_equal_approx(_cap_on_a_page("?debug=1&dpr=1.5"), 1.5), "?dpr=1.5 caps at 1.5")
	t.check(is_equal_approx(_cap_on_a_page("debug=1&dpr=2"), 2.0), "the leading ? is optional")
	t.check(is_equal_approx(_cap_on_a_page("?debug=1&dpr=1&seed=4"), 1.0),
			"found among other parameters")
	t.check(is_equal_approx(_cap_on_a_page("?dpr=1&debug=1&seed=4"), 1.0),
			"found before the parameter that opens the bundle")
	t.check(_cap_on_a_page("?debug=1") == 0.0, "no parameter, no cap")
	t.check(_cap_on_a_page("?debug=1&dpr=abc") == 0.0, "a word is no cap")
	t.check(_cap_on_a_page("?debug=1&dpr=") == 0.0, "an empty value is no cap")
	t.check(_cap_on_a_page("?debug=1&dpr=0") == 0.0, "zero is no cap, not a blank canvas")
	t.check(_cap_on_a_page("?debug=1&dpr=-1") == 0.0, "a negative value is no cap")
	t.check(_cap_on_a_page("?debug=1&dpr=0.1") == 0.0, "a value below the smallest cap taken is a typo")
	t.check(WebDisplay.dpr_cap(RunConfig.parse(PackedStringArray(), "?debug=1&dpr=1.5", false))
			== 0.0, "no cap off a page, whatever the query")

func _test_the_gate(t) -> void:
	t.check(WebDisplay.dpr_cap(RunConfig.parse(PackedStringArray(), "?dpr=2", true), true) == 2.0,
		"an open bundle on a page reads the query")
	t.check(_cap_on_a_page("?dpr=2") == 0.0, "a release page without ?debug=1 reads nothing")
	t.check(WebDisplay.dpr_cap(RunConfig.parse(PackedStringArray(), "?dpr=2", true), false) == 0.0,
		"off a page there is no address bar")
