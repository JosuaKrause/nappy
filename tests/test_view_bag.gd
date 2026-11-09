@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `ViewBag`, one view's bag (inbox #1185 in gentle-owl: "each of the views has their own bag to draw from"): every
## marble drawn without putting back and the bag filled again once empty, a marble the location does
## not accept never drawn and left in the bag for the next, and each marble's share scaled by the
## location's weight. Bags of a handful of marbles built by hand.

func run(t) -> void:
	_test_a_fill_is_drawn_whole_before_it_is_filled_again(t)
	_test_a_marble_not_accepted_is_never_drawn_and_stays(t)
	_test_the_empty_event_is_drawn_when_nothing_else_is_accepted(t)
	_test_a_second_fill_keeps_what_was_refused(t)
	_test_a_locations_weight_scales_a_marbles_share(t)
	_test_the_same_seed_draws_the_same(t)


static func _yes(_id: String) -> bool:
	return true

static func _one(_id: String) -> float:
	return 1.0

func _test_a_fill_is_drawn_whole_before_it_is_filled_again(t) -> void:
	var bag := ViewBag.new({"cafe": 2, "yeller": 1, ViewBag.EMPTY: 3}, 7)
	var counts := {}
	for _i in 6:
		var drawn := bag.draw(_yes, _one)
		counts[drawn] = int(counts.get(drawn, 0)) + 1
	t.check(counts == {"cafe": 2, "yeller": 1, ViewBag.EMPTY: 3},
			"six draws from a fill of six take each marble once (%s)" % counts)
	var again := bag.draw(_yes, _one)
	t.check(again in ["cafe", "yeller", ViewBag.EMPTY], "and the seventh draws from a fresh fill")

func _test_a_marble_not_accepted_is_never_drawn_and_stays(t) -> void:
	var bag := ViewBag.new({"cafe": 1, "yeller": 3, ViewBag.EMPTY: 1}, 11)
	var no_yeller := func(id: String) -> bool: return id != "yeller"
	var drawn: Array[String] = []
	for _i in 2:
		drawn.append(bag.draw(no_yeller, _one))
	t.check(not drawn.has("yeller") and drawn.has("cafe") and drawn.has(ViewBag.EMPTY),
			"a location that does not accept the yeller never draws him (%s)" % [drawn])
	var next: Array[String] = []
	for _i in 3:
		next.append(bag.draw(_yes, _one))
	t.check(next == (["yeller", "yeller", "yeller"] as Array[String]),
			"and his marbles stay in the bag for the next location that accepts him (%s)" % [next])

func _test_the_empty_event_is_drawn_when_nothing_else_is_accepted(t) -> void:
	var bag := ViewBag.new({"cafe": 4, ViewBag.EMPTY: 1}, 3)
	var nothing := func(_id: String) -> bool: return false
	t.check(bag.draw(nothing, _one) == ViewBag.EMPTY, "a location that accepts no row draws empty")
	t.check(bag.draw(nothing, _one) == ViewBag.EMPTY,
			"and once the bag's empty marbles are gone, a fresh fill still gives it empty")

## A location that accepts nothing, at a bag whose empty marbles are gone, is given a second fill
## beside what is left: the three cafes it refused stay, and three more come with the fill, so six
## draws that accept the cafe draw six cafes.
func _test_a_second_fill_keeps_what_was_refused(t) -> void:
	var bag := ViewBag.new({"cafe": 3, ViewBag.EMPTY: 1}, 5)
	var nothing := func(_id: String) -> bool: return false
	t.check(bag.draw(nothing, _one) == ViewBag.EMPTY and bag.draw(nothing, _one) == ViewBag.EMPTY,
			"a location that accepts nothing draws empty, the second from a second fill")
	var drawn: Array[String] = []
	for _i in 6:
		drawn.append(bag.draw(_yes, _one))
	t.check(drawn == (["cafe", "cafe", "cafe", "cafe", "cafe", "cafe"] as Array[String]),
			"and the cafes it refused are still there beside the second fill's (%s)" % [drawn])

## A cafe and an empty marble, one each: drawn without weight, the cafe comes first about half the
## time; weighed nine times over by the location, about nine times in ten.
func _test_a_locations_weight_scales_a_marbles_share(t) -> void:
	var plain := 0
	var weighed := 0
	var nine := func(id: String) -> float: return 9.0 if id == "cafe" else 1.0
	for seed_value in 400:
		if ViewBag.new({"cafe": 1, ViewBag.EMPTY: 1}, seed_value).draw(_yes, _one) == "cafe":
			plain += 1
		if ViewBag.new({"cafe": 1, ViewBag.EMPTY: 1}, seed_value).draw(_yes, nine) == "cafe":
			weighed += 1
	t.check(plain > 150 and plain < 250, "drawn plainly, the cafe comes first about half the time (%d of 400)"
			% plain)
	t.check(weighed > 330, "weighed nine times over, about nine times in ten (%d of 400)" % weighed)

func _test_the_same_seed_draws_the_same(t) -> void:
	var first: Array[String] = []
	var second: Array[String] = []
	var a := ViewBag.new({"cafe": 2, "yeller": 2, ViewBag.EMPTY: 5}, 99)
	var b := ViewBag.new({"cafe": 2, "yeller": 2, ViewBag.EMPTY: 5}, 99)
	for _i in 9:
		first.append(a.draw(_yes, _one))
		second.append(b.draw(_yes, _one))
	t.check(first == second, "the same fill on the same seed draws the same marbles")
