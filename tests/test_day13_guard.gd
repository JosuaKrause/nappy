extends RefCounted
## Day 13's waiting guard follows her to the roadblock she approaches *(inbox #650 in mossy-beaver:
## "move the task's waiting guard to the roadblock the player approaches"; inbox #651 in
## lilac-marmot: "We can move the guard around offscreen as much as we want. If we need to move
## multiple times so be it")*, and never while he or where he goes is in her view.
##
## Holds, on a real city through the real day order: the guard placed with the task stands over the
## roadblock the task rides, in its band with a clear line to its body; walked up to another live
## roadblock, so the red arrow points there, he stays where he is while he is in her view, and while
## all the ground he may stand on round the roadblock she approaches is; while only its band is in
## her view he is re-placed on the ring past the band, with a clear line to it; once the band is out
## of her view he is re-placed in it, out of her reach, and each guard he was is gone; and he follows
## her again to the next one she approaches.
##
## **He stands on the far side of the roadblock from the way she comes** (inbox #1185), and the way
## she comes is decided once, the first frame the roadblock she approaches is on screen: walked round
## to its other side after that, he stays where he stood; before it, the side follows where she
## stands. Nothing floods for a way past him.
##
## Whichever roadblock she touches, the guard comes after her the moment she has done it *(the
## player: "as long as he starts pursuing when you hit the task it's fine")*: parked at another
## roadblock, kept there by her view, he is chasing her the moment she touches the one she
## approached, and, with her standing there, comes all the way to her, walking round the buildings
## between them; set on her with a building across his straight line, where a chase straight at her
## stalls, he walks round it to her while she stands; and a guard who already noticed her is left on her exactly as he was.
##
## And day 13's own roadblock is one the day placed, close by *(inbox #650 in mossy-beaver: "let's
## place one properly and guide to that -- just make sure it's closeby"; inbox #1185)*: on several
## cities, reading the mark takes a roadblock the day placed, or swaps one in for one of the day's
## events wholly out of her view, within the widest ring it is looked for in
## (`ResistanceDirector.ROADBLOCK_WIDER_REACH`), and with it standing she can still walk home and to
## a calm area from where she read the mark.
##
## **Each test builds its city in a run of its own** (`_build_city()`) and plays day 13 on it through
## the real day order, so none leans on the steps, alleys or scars another left. What the director
## has put in the street is read from the street: the contact (`ResistanceDirector.contact()`), the
## roadblock the task rides (`rider()`), the task's guard among the city's live instances
## (`_task_guard()`), and what the red arrow points at from where its tip stands
## (`red_arrow_target()`) and the live roadblocks there (`ResistanceReads`). The mark and the task are
## completed as an action completes them (`ContactPoint.complete_now()`), and the arrow's choices
## and the guard's moves are the director's own ticks (`tick()`), the step `main` runs on every
## physics tick: a choice is a tick as long as the arrow's clock (`_choose_again()`), and the arrow
## is run to rest a physics tick at a time (`_settle_the_arrow()`).

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const ResistanceReads := preload("res://tests/resistance_reads.gd")
const SEED := 4242
const DAY := 13
## The cities day 13's own roadblock is placed on, each under the day's rules
## (`tests/probes/calm_pelican_day13_roadblock.gd` measures the share over more).
const PLACEMENT_SEEDS: Array[int] = [4242, 90210, 555, 271828]
## The seed of the run each test's city stands in (`_build_city()`): the one the runner starts the
## live run on between suites, so the posters and everything else the run decides are what they
## were when these cities stood in that run. Nothing the director places reads it: each day's
## stream is handed in (`_rng()`).
const RUN_SEED := 2

## What the test's camera shows: a `Rect2` of world ground, or an empty one for nothing at all.
## The camera's view as a test sets it: the city's one view (`_seen_through`) is looked at it, so the
## director's `set_sight()` and the siting's `DRAWING_OFF_THE_VIEW` both read it.
var _view := Rect2():
	set(value):
		_view = value
		if _seen_through:
			_seen_through.look(value, null)
var _seen_through: VisibleView
## The city the test in progress built (`_build_city()`), in a run of its own.
var _city: City
## What each day's streams are named after: this suite's own, or, empty, the day-13 probes' own
## (`tests/probes/calm_pelican_day13_guard_walk.gd`), so a day the probes measured is built again.
var _streams := "day13-guard:"

func run(t) -> void:
	_test_the_guard_follows_her_to_the_roadblock_she_approaches(t)
	_test_set_on_her_inside_his_stand_off_he_holds(t)
	_test_the_guards_side_is_decided_once_from_her_approach(t, true)
	_test_the_guards_side_is_decided_once_from_her_approach(t, false)
	_test_a_roadblock_streamed_out_and_in_keeps_its_side(t)
	# The probes' days on which a guard once stood on her only way.
	_streams = ""
	for seed_value in [1234567, 314159]:
		_test_the_guard_stands_on_the_far_side_from_her(t, seed_value)
	_streams = "day13-guard:"
	_test_the_done_task_sets_the_guard_on_her_wherever_he_stands(t, true)
	_test_the_done_task_sets_the_guard_on_her_wherever_he_stands(t, false)
	_test_out_of_her_view_the_done_task_sends_him_under_a_badge(t)
	_test_a_guard_warning_her_when_the_task_is_done_still_charges(t)
	_test_the_guard_walks_round_a_building_to_her(t)
	for seed_value in PLACEMENT_SEEDS:
		_test_the_roadblock_is_placed_under_the_rules_close_by(t, seed_value)
	_test_with_none_close_by_a_section_is_taken(t)

func _test_the_guard_follows_her_to_the_roadblock_she_approaches(t) -> void:
	var city := _build_city(t, SEED)
	var director := _start_the_day(t, city, SEED)
	var player := _rig_player(t, director, director.contact_position())
	_view = Rect2(player.global_position - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
	var mark := director.current_step()
	t.check(mark != null and mark.is_pickup and mark.day == DAY, "day %d opens on its mark" % DAY)
	if mark:
		director.contact().complete_now()
	var step := director.current_step()
	t.check(step != null and step.task_event_id == "roadblock", "reading it offers the roadblock")
	var first: EventInstance = _task_guard()
	t.check(first != null and director.rider() != null,
			"the task's guard stands in the street with the roadblock the task rides")
	if first != null and director.rider() != null:
		_check_he_guards(t, director, director.rider(), player, null, "the task's own roadblock")
	if step == null or first == null:
		_tear_down(player, director, city)
		return
	var where := first.global_position
	# Her view on him while she looks for another roadblock, so the arrow's own choices on the way
	# (`tick()`) cannot move him before the test asks.
	_view = Rect2(where - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
	_settle_the_arrow(director)

	# The case needs a roadblock whose ground all round, out to where its guard may stand, lies
	# clear of the guard where he stands now (the square the view below is set to): one that close
	# to the task's own would put him in that view before he moved.
	var everywhere := Vector2.ONE * (ResistanceDirector.TASK_GUARD_FARTHEST + 64.0)
	var clear_of_him := func(roadblock: EventInstance) -> bool:
		var square := Rect2(roadblock.body_position() - everywhere, everywhere * 2.0)
		return not square.intersects(Rect2(where + Vector2(-14.0, -48.0), Vector2(28.0, 52.0)))
	var other := _her_way_to_another_roadblock(director, player, director.rider(), clear_of_him)
	t.check(other != null, ("there is another live roadblock she can walk up to whose ground round " +
			"it is clear of where the guard stands (%d live)")
			% ResistanceReads.answering(city.events, step).size())
	if other == null:
		_tear_down(player, director, city)
		return

	# He is in her view: he stays, choice after choice.
	_choose_again(director)
	t.check(_task_guard() == first and first.global_position == where
			and not first.is_finished,
			"the guard does not move while he is in her view")

	# Everywhere he may stand round the roadblock she approaches is in her view: he stays.
	var around := other.body_position()
	# He stands out of that view himself: the premise the other roadblock was chosen by
	# (`clear_of_him` above, the same square and his same rect) holds it.
	_view = Rect2(around - everywhere, everywhere * 2.0)
	_choose_again(director)
	t.check(_task_guard() == first and first.global_position == where,
			"the guard does not move while all the ground round the roadblock she approaches is in view")

	# Only its band is in her view: he goes to the ring just past it, out of her view. The view
	# changes here with her neither moving nor turning, as the camera does easing on after she stops
	# or the joystick scheme's corners switching, so the search the choice before found nothing for
	# stands until `TASK_GUARD_RETRY_SECONDS` have passed, and is then made again: counted in the
	# director's own ticks, one `ARROW_RETARGET_SECONDS` choice at a time.
	var robbery := EventCatalogue.by_id("alley_robbery")
	var band_edge := robbery.notice_within() + ContactPoint.body_reach(other)
	var band_seen := Vector2.ONE * (band_edge + 48.0)
	_view = Rect2(around - band_seen, band_seen * 2.0)
	t.check(not _guard_in_view(where), "he stands out of the band's view himself")
	_choose_again(director)
	t.check(_task_guard() == first and first.global_position == where,
			"the search that found him nowhere better is remembered: not searched again at once")
	var waited := ResistanceDirector.ARROW_RETARGET_SECONDS
	while first.global_position == where and waited < ResistanceDirector.TASK_GUARD_RETRY_SECONDS * 2.0:
		_choose_again(director)
		waited += ResistanceDirector.ARROW_RETARGET_SECONDS
	t.check(waited >= ResistanceDirector.TASK_GUARD_RETRY_SECONDS - 0.001
			and first.global_position != where,
			"it is searched again once %.1fs have passed since it found nothing (moved after %.1fs)"
			% [ResistanceDirector.TASK_GUARD_RETRY_SECONDS, waited])
	var ringed: EventInstance = _task_guard()
	var ring_at := ringed.global_position if ringed else Vector2.INF
	t.check(ringed != null and ringed == first and not first.is_finished
			and ring_at.distance_to(around) > band_edge
			and ring_at.distance_to(around) <= ResistanceDirector.TASK_GUARD_FARTHEST
			and not _guard_in_view(ring_at) and _a_clear_line(city.map, ring_at, around),
			("while its band is in her view he goes past it, %.0fpx from its body, out of her view, " +
			"with a clear line to it") % ring_at.distance_to(around))
	# The band out of her view: on the arrow's next choice he is in it, which he is only if the
	# director knows he stands over it outside its band.
	_view = Rect2()
	_choose_again(director)
	_check_he_guards(t, director, other, player, ringed, "the roadblock she approaches")

	# And again, however often she changes target: here she walks up to the next one with nothing in
	# her view, and the arrow's own choices on the way (`tick()`) take him there.
	var second: EventInstance = _task_guard()
	var next := _her_way_to_another_roadblock(director, player, other)
	if next != null:
		_check_he_guards(t, director, next, player, second, "the next roadblock she approaches")

	_tear_down(player, director, city)

## That the task's guard guards `roadblock`: in its band, with a clear line to its body, out of his
## trigger range of her, and left there on the arrow's next choice, since he guards the roadblock it
## points at. With `before` given, he is `before` himself, moved with everything he was in the middle
## of (`EventManager.move_extra()`).
func _check_he_guards(t, director: ResistanceDirector, roadblock: EventInstance, player: Stroller,
		before: EventInstance, what: String) -> void:
	var guard: EventInstance = _task_guard()
	if before != null:
		t.check(guard != null and guard == before and not before.is_finished,
				"the guard is moved to %s, the same man rather than a new one" % what)
	if guard == null:
		return
	var robbery := EventCatalogue.by_id("alley_robbery")
	var reach := ContactPoint.body_reach(roadblock)
	var from_body := guard.global_position.distance_to(roadblock.body_position())
	t.check(from_body >= robbery.inner_radius + reach - 0.5
			and from_body <= robbery.notice_within() + reach + 0.5,
			"at %s he stands in its band, %.0fpx from its body (%.0f-%.0fpx)"
			% [what, from_body, robbery.inner_radius + reach, robbery.notice_within() + reach])
	t.check(_a_clear_line(_city.map, guard.global_position, roadblock.body_position()),
			"at %s he has a clear line to its body, so he can notice her there" % what)
	t.check(guard.global_position.distance_to(player.global_position) > robbery.notice_within(),
			"and out of his own trigger range of her (%.0fpx)"
			% guard.global_position.distance_to(player.global_position))
	var stood := guard.global_position
	_choose_again(director)
	t.check(ResistanceReads.pointed_at(director, ResistanceReads.answering(_city.events, director.current_step())) == roadblock
			and _task_guard() == guard and guard.global_position == stood,
			"at %s the arrow still points at it and the next choice leaves him there" % what)
	t.check(_on_the_far_side(guard.global_position, roadblock.body_position(),
			player.global_position),
			"at %s he stands on the far side of it from her" % what)

## Whether `guard` stands on the far side of the roadblock at `body` from `her`: not toward her
## across the body.
static func _on_the_far_side(guard: Vector2, body: Vector2, her: Vector2) -> bool:
	return (guard - body).dot(her - body) <= 0.0

## Whether every point of the straight line from `from` to `to`, a pixel apart, is on walkable
## ground: the line a waiting guard notices her along, asked here by sampling rather than through
## the director's own tile walk.
static func _a_clear_line(map: CityMap, from: Vector2, to: Vector2) -> bool:
	var steps := ceili(from.distance_to(to))
	for i in steps + 1:
		var point := from.lerp(to, float(i) / float(maxi(steps, 1)))
		if not map.is_walkable(map.world_to_tile(point)):
			return false
	return true

func robbery_edge_of(roadblock: EventInstance) -> float:
	return EventCatalogue.by_id("alley_robbery").notice_within() + ContactPoint.body_reach(roadblock)

## Whether any part of a waiting robber standing at `feet` (22 by 44px above his feet, a few px to
## spare) is in the test's view.
func _guard_in_view(feet: Vector2) -> bool:
	return _view.has_area() and _view.intersects(Rect2(feet + Vector2(-14.0, -48.0),
			Vector2(28.0, 52.0)))

## **The guard stands on the far side of the roadblock from her** (inbox #1185): wherever she
## approaches a live roadblock of the day from, open ground 8 to 14 tiles out from it in each of four
## directions, the spot the task's guard is moved to when the arrow turns to it (`tick()`, as
## `_move_the_task_guard_to_her_target()` moves him, read off the street) is on the far side of it
## from her, and so is the spot he is placed on with the task, from where she read the mark. Her view
## is empty, so no roadblock comes on screen and the side follows where she stands. The places are
## taken roadblock by roadblock in turn, so each is approached while he stands over another and the
## arrow's turn moves him; a place whose arrow turns to a roadblock he already guards moves nobody.
## No reachability is asked, by the director or here: the side is the rule.
func _test_the_guard_stands_on_the_far_side_from_her(t, seed_value: int) -> void:
	var city := _build_city(t, seed_value)
	var director := _start_the_day(t, city, seed_value)
	var player := _rig_player(t, director, director.contact_position())
	_view = Rect2()
	var mark := director.current_step()
	if mark:
		director.contact().complete_now()
	var map := city.map
	var moved := 0
	var near_side: Array[String] = []
	var first := _task_guard()
	var roadblocks := ResistanceReads.answering(city.events, director.current_step())
	if first != null and director.rider() != null:
		var rider := director.rider()
		if not _on_the_far_side(first.global_position, rider.body_position(), player.global_position):
			near_side.append("%s from where she read the mark" % map.world_to_tile(rider.body_position()))
	# Her view on him while the arrow settles, so its choices on the way leave him where he stands.
	if first != null:
		_view = Rect2(first.global_position - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
	_settle_the_arrow(director)
	_view = Rect2()
	for out: int in [8, 11, 14]:
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			for roadblock in roadblocks:
				var tile: Vector2i = map.world_to_tile(roadblock.body_position()) + direction * out
				if not map.in_bounds(tile) or not map.is_walkable(tile) or map.is_obstructed(tile) \
						or map.is_closed(tile):
					continue
				var guard := _task_guard()
				if guard == null:
					continue
				player.global_position = map.tile_to_world(tile)
				if not _follows_the_arrow(director, guard):
					continue
				var to := ResistanceReads.pointed_at(director, roadblocks)
				if to == null:
					continue
				moved += 1
				if not _on_the_far_side(guard.global_position, to.body_position(),
						player.global_position):
					near_side.append("%s from %s" % [map.world_to_tile(to.body_position()), tile])
	t.check(moved > 20 and near_side.is_empty(),
			"seed %d: wherever he is put, he stands on the far side of the roadblock from her (%d moves, on her side %s)"
			% [seed_value, moved, near_side.slice(0, 4)])
	_tear_down(player, director, city)

## **The guard's side is decided once, the first frame the roadblock is on screen, from her
## approach** (inbox #1185): with the day's other roadblocks finished, so the arrow keeps to the
## task's own, she stands on one side of it, out along a street, and the guard is moved to its far
## side. With `seen`, the roadblock then comes into her view as she stands there, which decides its
## side, and she walks round to the opposite side, the roadblock out of view again: through the
## arrow's choices he stays where he stood, on the side away from where she first came. Without it
## the roadblock never came on screen, so the side was never decided: the same walk round moves him
## to the far side from where she stands now, which is the move the decided side holds back. Seen,
## the roadblock then comes into her view again from the second side, and he still stays: the side
## is decided once, not each time she sees it.
func _test_the_guards_side_is_decided_once_from_her_approach(t, seen: bool) -> void:
	var city := _build_city(t, SEED)
	var director := _start_the_day(t, city, SEED)
	var player := _rig_player(t, director, director.contact_position())
	_view = Rect2()
	if director.contact():
		director.contact().complete_now()
	var roadblock := director.rider()
	var guard := _task_guard()
	var what := "seen" if seen else "never seen"
	t.check(roadblock != null and guard != null, "(%s) the task rides a roadblock, guarded" % what)
	if roadblock == null or guard == null:
		_tear_down(player, director, city)
		return
	for live in ResistanceReads.answering(city.events, director.current_step()):
		if live != roadblock:
			city.events.retire(live)
	var body := roadblock.body_position()
	var sides := _either_side_of(city.map, body)
	t.check(not sides.is_empty(), "(%s) there is open ground on either side of it" % what)
	if sides.is_empty():
		_tear_down(player, director, city)
		return
	var first: Vector2 = sides[0]
	var second: Vector2 = sides[1]
	player.global_position = first
	for i in 4:
		_choose_again(director)
	t.check(_on_the_far_side(guard.global_position, body, first),
			"(%s) she out on one side of it, he stands on its far side" % what)
	if seen:
		_view = Rect2(first - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
		_choose_again(director)
		_view = Rect2()
	var stood := guard.global_position
	player.global_position = second
	for i in 8:
		_choose_again(director)
	if seen:
		t.check(_task_guard() == guard and guard.global_position == stood
				and _on_the_far_side(guard.global_position, body, first),
				"seen from one side, its side is kept: she walks round to the other and he stays")
		# Seen again from the other side: the side stays the one decided first.
		_view = Rect2(second - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
		_choose_again(director)
		_view = Rect2()
		for i in 8:
			_choose_again(director)
		t.check(_task_guard() == guard and guard.global_position == stood,
				"seen again from the other side, the side is not decided again: he stays")
	else:
		t.check(_task_guard() == guard and _on_the_far_side(guard.global_position, body, second),
				"never seen, the side follows her: walked round, he is moved to the far side from her")
	_tear_down(player, director, city)

## **A roadblock that streams out and back in keeps its side**: its side is the plan's, not the
## instance's. She walks up to another live roadblock of the day than the task's own (which the task
## keeps in the world), and the guard follows her there; the day's others are finished, so the arrow
## chooses between those two. She stands on one side of it, it comes into her view, which decides
## its side, and the view goes. She walks back to the task's own, and the other is streamed out of
## the world and back in
## (`EventManager.stream_around()`), a new instance of the same plan, and she stands on its other
## side: through the arrow's choices the guard stays on the side away from where she first came (he
## may still be moved within it, from the ring past the band into the band).
func _test_a_roadblock_streamed_out_and_in_keeps_its_side(t) -> void:
	var city := _build_city(t, SEED)
	var director := _start_the_day(t, city, SEED)
	var player := _rig_player(t, director, director.contact_position())
	_view = Rect2()
	if director.contact():
		director.contact().complete_now()
	var rider := director.rider()
	var guard := _task_guard()
	# One other roadblock is kept, the first with open ground on either side of it away from the
	# task's own, off the task's own street line (from out along one line, one stands behind the
	# other) and with somewhere she may walk up to it from (`_spots_to_walk_up_from()`); the day's
	# others are finished first, so the contact, which follows her between look-alikes, never rides
	# one taken away under it.
	var kept: EventInstance = null
	for live in ResistanceReads.answering(city.events, director.current_step()):
		if rider and live != rider and kept == null \
				and not _either_side_of(city.map, live.body_position(), rider.body_position()).is_empty() \
				and not _on_one_street_line(city.map, live.body_position(), rider.body_position()) \
				and not _spots_to_walk_up_from(city.map, live).is_empty():
			kept = live
	for live in ResistanceReads.answering(city.events, director.current_step()):
		if live != rider and live != kept:
			city.events.retire(live)
	var other := _her_way_to_another_roadblock(director, player, rider) if rider else null
	t.check(other != null and guard != null, "(streamed) she walks up to another live roadblock")
	if other == null or guard == null:
		_tear_down(player, director, city)
		return
	var body := other.body_position()
	var sides := _either_side_of(city.map, body, rider.body_position())
	t.check(not sides.is_empty(), "(streamed) there is open ground on either side of it")
	if sides.is_empty():
		_tear_down(player, director, city)
		return
	var first: Vector2 = sides[0]
	var second: Vector2 = sides[1]
	player.global_position = first
	for i in 4:
		_choose_again(director)
	_view = Rect2(first - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
	_choose_again(director)
	_view = Rect2()
	var stood := guard.global_position
	t.check(_on_the_far_side(stood, body, first),
			"(streamed) seen from one side, he stands on its far side")
	# She walks back to the task's own roadblock, so the contact, which follows her between
	# look-alikes, rides it again rather than the one about to stream out under it.
	var by_the_rider := _either_side_of(city.map, rider.body_position(), body)
	if not by_the_rider.is_empty():
		player.global_position = by_the_rider[0]
		_settle_the_arrow(director)
	t.check(not by_the_rider.is_empty()
			and ResistanceReads.pointed_at(director, [rider] as Array[EventInstance]) != null,
			"(streamed) she walks back to the task's own roadblock")
	var away := body + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0)
	city.events.stream_around(away)
	city.events.stream_around(second)
	var again: EventInstance = null
	for live in ResistanceReads.answering(city.events, director.current_step()):
		if live != rider and live.body_position().distance_to(body) < 1.0:
			again = live
	t.check(again != null and again != other,
			"it streams out and back in as a new instance of the same roadblock")
	player.global_position = second
	# The new instance's walk is swept a slice a tick before the arrow can turn back to it, so the
	# arrow's choices run until it does, and a few after.
	for i in ARROW_TURN_CHOICES:
		_choose_again(director)
	t.check(again != null
			and ResistanceReads.pointed_at(director, [again] as Array[EventInstance]) != null,
			"(streamed) the arrow turns back to it")
	t.check(_task_guard() == guard and (guard.global_position - body).dot(first - body) < 0.0,
			"walked round to its other side, the side decided before it streamed out is kept: he stays on the side away from where she first came")
	_tear_down(player, director, city)

## Two open places on opposite sides of the roadblock at `body`, out along one axis 9 to 12 tiles
## from it — near enough that, standing at the first, the roadblock is in a view round her
## (`Tuning.VIEW_HALF_EXTENT`) — or empty when no axis has both. With `away_from`, neither is within
## `AWAY_FROM_THE_OTHER` of it: another roadblock of the day, so standing there touches neither
## that roadblock nor its band, which would complete the task.
static func _either_side_of(map: CityMap, body: Vector2,
		away_from := Vector2.INF) -> Array[Vector2]:
	var centre := map.world_to_tile(body)
	for axis: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
		var reach := 9 if axis == Vector2i.RIGHT else 5
		for out in range(reach, reach + 4):
			var a := centre + axis * out
			var b := centre - axis * out
			if away_from != Vector2.INF and (map.tile_to_world(a).distance_to(away_from)
					< AWAY_FROM_THE_OTHER or map.tile_to_world(b).distance_to(away_from)
					< AWAY_FROM_THE_OTHER):
				continue
			if _open(map, a) and _open(map, b):
				return [map.tile_to_world(a), map.tile_to_world(b)] as Array[Vector2]
	return [] as Array[Vector2]

## How far from another roadblock the places `_either_side_of()` picks stand: past any touch of it and
## past its guard's band (`notice_within()` + 110px touch reach), with a tile to spare.
const AWAY_FROM_THE_OTHER := 448.0

## Whether `tile` is ground she can stand on: in the city, walkable, open and unobstructed.
static func _open(map: CityMap, tile: Vector2i) -> bool:
	return map.in_bounds(tile) and map.is_walkable(tile) and not map.is_obstructed(tile) \
			and not map.is_closed(tile)

## **Set on her already inside his stand-off, he holds it** (`EventInstance.notice_her_at()`; the
## events skill: "the chase starts at the stand-off however she came"). A waiting robber with her
## 60px off along a clear line — inside his stand-off, outside his catch — is set on her: while she
## stands there he neither lunges nor can end her day, however long; when she walks away he lunges
## only once she is back at the full stand-off. Without the hold he would lunge from 60px on his
## first tick.
func _test_set_on_her_inside_his_stand_off_he_holds(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var guard := EventInstance.new()
	guard.setup(robbery, Vector2.ZERO, PackedVector2Array())
	t.add_child(guard)
	guard.set_process(false)
	var standoff := PursuitSpec.standoff(robbery.chase_speed(), robbery.standoff_reach())
	var her := Vector2(60.0, 0.0)
	t.check(her.length() < standoff and her.length() > robbery.lethal_reach(),
			"she stands inside his %.0fpx stand-off and outside his catch" % standoff)
	guard.notice_her_at(her)
	t.check(not guard.is_waiting(), "set on her, he has noticed her")
	var lunged_standing := false
	var lethal_standing := false
	for i in 60:
		guard.player_at = her
		guard.step(0.1)
		lunged_standing = lunged_standing or guard.phase == EventInstance.Phase.ACTIVE
		lethal_standing = lethal_standing or guard.is_lethal_at(her)
	t.check(not lunged_standing and not lethal_standing,
			"while she stands 60px off for 6s he holds: no lunge, and he cannot end her day")
	var lunged_at := -1.0
	for i in 60:
		her += Vector2(Tuning.WALK_SPEED * 0.1, 0.0)
		guard.player_at = her
		guard.step(0.1)
		if guard.phase == EventInstance.Phase.ACTIVE:
			lunged_at = guard.global_position.distance_to(her)
			break
	t.check(lunged_at >= standoff - Tuning.WALK_SPEED * 0.1,
			"walking away, he lunges only once she is back at his stand-off (%.0fpx, stand-off %.0fpx)"
			% [lunged_at, standoff])
	guard.free()

## The arrow's choices, as `main`'s ticks make them (`_choose_again()`), until `guard` is moved or
## `ARROW_TURN_CHOICES` have been made: whether he was. The arrow turns to another roadblock only
## once the walk to the one it points at is swept, a slice a tick, so a turn takes several choices;
## the move follows the turn on the same tick.
static func _follows_the_arrow(director: ResistanceDirector, guard: EventInstance) -> bool:
	var was := guard.global_position
	for i in ARROW_TURN_CHOICES:
		_choose_again(director)
		if guard.global_position != was:
			return true
	return false

## How many of the arrow's choices `_follows_the_arrow()` waits through for a move: more than the
## slices the walk to a roadblock is swept in on a test city.
const ARROW_TURN_CHOICES := 24

## **The done task sets the guard on her, wherever he stands.** With `parked`, she touches another
## live roadblock while the guard is held at the task's own by her view on him; without, he has
## already noticed her at the task's own before she touches it, and is warning her by sight in her
## view: the task's own second of warning replaces his.
func _test_the_done_task_sets_the_guard_on_her_wherever_he_stands(t, parked: bool) -> void:
	var city := _build_city(t, SEED)
	var director := _start_the_day(t, city, SEED)
	var player := _rig_player(t, director, director.contact_position())
	_view = Rect2()
	var mark := director.current_step()
	if mark:
		director.contact().complete_now()
	var step := director.current_step()
	var guard: EventInstance = _task_guard()
	var what := "parked at another roadblock" if parked else "already after her"
	t.check(step != null and guard != null and guard.is_waiting(),
			"(%s) the task offers a roadblock, guarded by a waiting guard" % what)
	if step == null or guard == null:
		_tear_down(player, director, city)
		return
	var map := city.map
	var touched: EventInstance = director.rider()
	if parked:
		# Her view on him from here on, so he cannot be moved to the one she approaches.
		var held := guard.global_position
		_view = Rect2(held - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
		_settle_the_arrow(director)
		touched = _her_way_to_another_roadblock(director, player, director.rider())
		t.check(touched != null, "(%s) there is another live roadblock to touch" % what)
		if touched == null:
			_tear_down(player, director, city)
			return
		_choose_again(director)
		t.check(_task_guard() == guard and guard.global_position == held
				and guard.is_waiting()
				and guard.global_position.distance_to(touched.body_position())
				> EventCatalogue.by_id("alley_robbery").notice_within()
				+ ContactPoint.body_reach(touched),
				"(%s) the guard is still at the task's own roadblock, out of the band of the one she touches (%.0fpx from it)"
				% [what, guard.global_position.distance_to(touched.body_position())])
	var at := _beside(map, touched.body_position(), ContactPoint.body_reach(touched))
	t.check(at != Vector2.INF, "(%s) there is ground to touch the roadblock from" % what)
	player.global_position = at
	if not parked:
		# He notices her the ordinary way: she comes within his reach along a clear line, here a
		# step from him on his own tile.
		guard.player_at = guard.global_position + Vector2(4.0, 0.0)
		guard.step(0.1)
		t.check(not guard.is_waiting(), "(%s) he noticed her the ordinary way" % what)
		_view = Rect2(guard.global_position - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
	director.contact().complete_now()
	t.check(not guard.is_finished and not guard.is_waiting(),
			"(%s) the moment she has done the task, he is after her" % what)
	if parked:
		# In her view his warning is a second, standing with it up *(inbox #764 in minty-lemur, the player: "yes,
		# we can do a 1s on screen and 1s off-screen warning if they were not visible")*.
		t.check(guard.is_standing_for_its_notice()
				and is_equal_approx(guard.notice_time(), Tuning.WARNING_ALONE_MAX),
				"(%s) in her view he stands with his warning up for %.1fs" % [what, guard.notice_time()])
		var held_at := guard.global_position
		guard.player_at = at
		guard.step(Tuning.WARNING_ALONE_MAX - 0.1)
		t.check(guard.is_telegraphing() and guard.global_position == held_at,
				"(%s) still standing just short of that second" % what)
		guard.step(0.2)
		t.check(not guard.is_telegraphing(), "(%s) and then he charges" % what)
	if not parked:
		t.check(guard.is_standing_for_its_notice()
				and is_equal_approx(guard.notice_time(), Tuning.WARNING_ALONE_MAX),
				"(%s) a guard already warning her by sight is set on her with the task's second (standing %s, %.1fs)"
				% [what, guard.is_standing_for_its_notice(), guard.notice_time()])
		_tear_down(player, director, city)
		return
	var start := guard.global_position.distance_to(at)
	var standoff := PursuitSpec.standoff(guard.def.chase_speed(), guard.def.standoff_reach())
	var nearest := start
	var walked := 0.0
	var lethal := false
	while walked < 30.0 and not lethal and not guard.is_finished:
		guard.player_at = at
		guard.step(0.1)
		walked += 0.1
		nearest = minf(nearest, guard.global_position.distance_to(at))
		lethal = guard.is_lethal_at(at)
	# He walks round the buildings between them (`EventInstance._chase_way`), so he comes all
	# the way to her stand-off however many blocks stood between them.
	t.check(lethal or nearest <= standoff + 1.0,
			"(%s) he comes from %.0fpx away to her (nearest %.0fpx, stand-off %.0fpx, caught %s, %.1fs)"
			% [what, start, nearest, standoff, lethal, walked])
	_tear_down(player, director, city)

## **Out of her view, the done task sends him at her under a badge** *(inbox #764 in minty-lemur, the player: "yes,
## we can do a 1s on screen and 1s off-screen warning if they were not visible")*: the waiting guard
## is taken out of the world unseen and sent as a task's robber is
## (`ResistanceDirector._send_at_her()`): the screen-edge badge alone for `Tuning.WARNING_ALONE_MAX`,
## then he arrives charging (`EventCatalogue.task_guard_sent()`).
func _test_out_of_her_view_the_done_task_sends_him_under_a_badge(t) -> void:
	var city := _build_city(t, SEED)
	var director := _start_the_day(t, city, SEED)
	var player := _rig_player(t, director, director.contact_position())
	_view = Rect2()
	var mark := director.current_step()
	if mark:
		director.contact().complete_now()
	var step := director.current_step()
	var guard: EventInstance = _task_guard()
	t.check(step != null and guard != null and guard.is_waiting(),
			"the task offers a roadblock, guarded by a waiting guard")
	if step == null or guard == null:
		_tear_down(player, director, city)
		return
	var touched: EventInstance = director.rider()
	var at := _beside(city.map, touched.body_position(), ContactPoint.body_reach(touched))
	player.global_position = at
	director.contact().complete_now()
	t.check(_task_guard() == null and guard.is_finished,
			"out of her view the waiting guard is taken out of the world")
	var warning: PendingWarning = null
	for pending in city.events.pending_warnings():
		if pending.def == EventCatalogue.task_guard_sent():
			warning = pending
	t.check(warning != null and is_equal_approx(warning.def.warned_for(), Tuning.WARNING_ALONE_MAX)
			and warning.def.starts_by(PursuitSpec.Start.ARRIVES_CHASING),
			"and sent at her under a %.1fs badge, to arrive charging"
			% (warning.def.warned_for() if warning else -1.0))
	_tear_down(player, director, city)

## **A guard already warning her when she finishes the task is set on her too** — left to his own
## warning by radius, she could walk out of it and he would never come *(inbox #651 follow-up, the
## player: "as long as he starts pursuing when you hit the task it's fine")*. She comes inside his
## radius and outside his stand-off along a clear line, so he warns; the task is done; she walks
## straight away from him, and he still charges.
func _test_a_guard_warning_her_when_the_task_is_done_still_charges(t) -> void:
	var city := _build_city(t, SEED)
	var director := _start_the_day(t, city, SEED)
	var player := _rig_player(t, director, director.contact_position())
	var mark := director.current_step()
	if mark:
		director.contact().complete_now()
	var step := director.current_step()
	var guard: EventInstance = _task_guard()
	t.check(step != null and guard != null and guard.is_waiting(), "a waiting guard at the roadblock")
	if step == null or guard == null:
		_tear_down(player, director, city)
		return
	var map := city.map
	var standoff := PursuitSpec.standoff(guard.def.chase_speed(), guard.def.standoff_reach())
	var away := Vector2.ZERO
	var her := Vector2.INF
	for i in 16:
		var dir := Vector2.RIGHT.rotated(TAU * i / 16.0)
		var at := guard.global_position + dir * 150.0
		var far := guard.global_position + dir * 1200.0
		# Clear as he sees it (`EventInstance.clear_line_to()`, what his notice asks), the band and
		# the bodies round it in the way included, which the map's own line does not know of.
		if map.is_walkable(map.world_to_tile(at)) and guard.clear_line_to(at):
			her = at
			away = dir
			break
	t.check(her != Vector2.INF, "there is open ground 150px from him to warn her on")
	if her == Vector2.INF:
		_tear_down(player, director, city)
		return
	_view = Rect2(guard.global_position - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
	guard.player_at = her
	guard.step(0.1)
	t.check(guard.is_telegraphing() and guard.warns_by_radius(),
			"150px from him, outside his %.0fpx stand-off, he warns her" % standoff)
	player.global_position = her
	director.contact().complete_now()
	var charged := false
	var walked := 0.0
	while walked < 10.0 and not charged and not guard.is_finished:
		her += away * Tuning.WALK_SPEED * 0.05
		guard.player_at = her
		guard.step(0.05)
		walked += 0.05
		charged = not guard.is_waiting() and not guard.is_telegraphing()
	t.check(charged, "the task done, he charges her even as she walks away (after %.1fs)" % walked)
	_tear_down(player, director, city)

## **With a building between them, he walks round it to her.** On seed 4242's day 13, the task's
## own guard is set on her where she stands a few blocks off with a building across his straight
## line — a spot from which a chase straight at her, sliding along walls (`Navigator.step()`, as a
## man on foot), never comes within his stand-off of her, and which she
## could walk to from him — and he reaches her stand-off within the time his walk to her takes
## at his speed, his notice and a margin on top.
func _test_the_guard_walks_round_a_building_to_her(t) -> void:
	var city := _build_city(t, SEED)
	var director := _start_the_day(t, city, SEED)
	var player := _rig_player(t, director, director.contact_position())
	_view = Rect2()
	var mark := director.current_step()
	if mark:
		director.contact().complete_now()
	var guard: EventInstance = _task_guard()
	t.check(guard != null and guard.is_waiting(), "(round a building) the task's guard is waiting")
	if guard == null:
		_tear_down(player, director, city)
		return
	var map := city.map
	# Her view is on him while the arrow settles, so its choices leave him where he stands.
	_view = Rect2(guard.global_position - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
	_settle_the_arrow(director)
	_view = Rect2()
	var standoff := PursuitSpec.standoff(guard.def.chase_speed(), guard.def.standoff_reach())
	var from := guard.global_position
	# His walk to her goes round what stops a figure on foot today, as his sweep does.
	var walk := map.walk_field(map.world_to_tile(from), map.blocked.tiles_of(Mover.TODAY))
	var at := Vector2.INF
	var tiles_to_her := -1
	for radius in range(5, 16):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if at != Vector2.INF or maxi(absi(dx), absi(dy)) != radius:
					continue
				var tile := map.world_to_tile(from) + Vector2i(dx, dy)
				if not map.is_walkable(tile) or map.is_closed(tile) or map.is_obstructed(tile) \
						or map.soft_sealed_tiles.has(tile) or not map.reaches(walk, tile):
					continue
				var spot := map.tile_to_world(tile)
				if map.clear_line(from, spot) \
						or _a_straight_chase_reaches(map, from, spot, standoff,
								guard.def.chase_speed()):
					continue
				at = spot
				tiles_to_her = map.distance_at(walk, tile)
	t.check(at != Vector2.INF,
			"(round a building) there is a spot she can walk to with a building across his straight line, where a straight chase stalls")
	if at == Vector2.INF:
		_tear_down(player, director, city)
		return
	player.global_position = at
	guard.notice_her_at(at)
	var allowed := guard.def.telegraph_time + tiles_to_her * Tuning.TILE_SIZE \
			/ guard.def.chase_speed() * 1.5 + 2.0
	var start := from.distance_to(at)
	var nearest := start
	var walked := 0.0
	var lethal := false
	while walked < allowed and not lethal and not guard.is_finished:
		guard.player_at = at
		guard.step(0.1)
		walked += 0.1
		nearest = minf(nearest, guard.global_position.distance_to(at))
		lethal = guard.is_lethal_at(at)
	t.check(lethal or nearest <= standoff + 1.0,
			("(round a building) he walks round it from %.0fpx away to her stand-off within %.1fs " +
			"(a walk of %d tiles; nearest %.0fpx, stand-off %.0fpx, caught %s, %.1fs)")
			% [start, allowed, tiles_to_her, nearest, standoff, lethal, walked])
	_tear_down(player, director, city)

## Whether a chase straight at `to` from `from`, sliding along walls as every pursuer's step does
## (`Navigator.step()`, a man on foot), ever comes within `standoff` of it in 30s at `speed`, in
## steps of a tenth of a second.
static func _a_straight_chase_reaches(map: CityMap, from: Vector2, to: Vector2,
		standoff: float, speed: float) -> bool:
	var at := from
	var navigator := Navigator.new(map)
	var chaser := Mover.on_foot(EventInstance.FIGURE_RADIUS)
	for i in 300:
		var toward := to - at
		if toward.length() <= standoff:
			return true
		var step := toward.normalized() * minf(speed * 0.1, toward.length())
		at += navigator.step(at, step, chaser)
	return false

## Walkable, open, unobstructed ground within `reach` of `body`, nearest the reach's edge first —
## where she stands to touch it — or `Vector2.INF`.
static func _beside(map: CityMap, body: Vector2, reach: float) -> Vector2:
	var centre := map.world_to_tile(body)
	var best := Vector2.INF
	var best_distance := -1.0
	for dy in range(-5, 6):
		for dx in range(-5, 6):
			var tile := centre + Vector2i(dx, dy)
			var spot := map.tile_to_world(tile)
			var distance := spot.distance_to(body)
			if distance > reach - 4.0 or distance <= best_distance or not map.is_walkable(tile) \
					or map.is_closed(tile) or map.is_obstructed(tile):
				continue
			best = spot
			best_distance = distance
	return best

## **Day 13's own roadblock is one the day placed, close by** (inbox #1185), or one of the day's
## events swapped for one out of her sight. She reads the mark where it stands, with the 640x360
## view round her answering what is on screen.
func _test_the_roadblock_is_placed_under_the_rules_close_by(t, seed_value: int) -> void:
	var city := _build_city(t, seed_value)
	var director := _start_the_day(t, city, seed_value)
	var player := _rig_player(t, director, director.contact_position())
	var her := player.global_position
	_view = Rect2(her - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
	var map := city.map
	var mark := director.current_step()
	var plans_before := city.events.plans().size()
	var spent_before := _spent(city)
	if mark:
		director.contact().complete_now()
	var roadblock: EventInstance = director.rider()
	t.check(roadblock != null and roadblock.def.id == "roadblock",
			"seed %d: reading the mark offers a roadblock" % seed_value)
	if roadblock == null:
		_tear_down(player, director, city)
		return
	var plans := city.events.plans()
	# Found: one of the day's own roadblocks, placed and unspent and not the wall's or a door's, is
	# what the task rides. Swapped: one plan more, it the roadblock, across a section whose content,
	# if it held any, is spent. Neither holds for a roadblock added outside the day's plan, which is
	# no plan at all.
	var found := false
	for index in plans_before:
		var plan := plans[index]
		found = found or (plan.is_placed() and not plan.is_spent() and not plan.is_in_the_wall()
				and not plan.is_door() and plan.instance() == roadblock)
	var swapped: bool = plans.size() == plans_before + 1 \
			and plans.back().instance() == roadblock and _spent(city) >= spent_before
	t.check(found or swapped,
			"seed %d: it is a roadblock the day placed, or one put across a section in place of what it held"
			% seed_value)
	var away := roadblock.global_position.distance_to(her)
	# A found one she touches from ground her paths reach within the widest ring, a tile and a half
	# from its body at most; a section the swap takes is the nearest along her paths, however far.
	var widest: float = ResistanceDirector.ROADBLOCK_WIDER_REACH.back()
	var touch := EventScheduler.Planned.new(roadblock.def, Vector2.ZERO).blocking_radius() \
			+ Tuning.TILE_SIZE * 2.0
	t.check(swapped or away <= widest + touch,
			"seed %d: a found one is close by, %.0fpx from where she read the mark (within %.0fpx)"
			% [seed_value, away, widest + touch])
	if swapped:
		var box := EventFootprints.footprint_of(roadblock.def)
		t.check(not _view.intersects(Rect2(roadblock.global_position + box.position, box.size)),
				"seed %d: no part of a swapped one is in her view when it is put there"
				% seed_value)
	var guard := _task_guard()
	t.check(guard != null and not _guard_in_view(guard.global_position),
			"seed %d: nor any part of the guard set with it" % seed_value)
	t.check(map.is_obstructed(map.world_to_tile(roadblock.body_position())),
			"seed %d: its body stands in the way of a walker" % seed_value)
	var reached := _walkable_from(map, her)
	t.check(reached.has(map.world_to_tile(map.doorstep_world_position())),
			"seed %d: with it standing she can still walk home from where she read the mark"
			% seed_value)
	var calm_reached := false
	for tile in map.calm_tiles():
		if reached.has(tile):
			calm_reached = true
			break
	t.check(calm_reached, "seed %d: and to a calm area" % seed_value)
	_tear_down(player, director, city)

## **With no roadblock close by, the nearest off-screen route-adjacent section takes one, its whole
## content replaced** (inbox #1185: "if we don't find one closeby we swap one off screen route
## adjacent event with a roadblock", "it replaces the content of the section with the roadblock"):
## every roadblock the day placed is spent before she reads the mark, so the task can only swap. The
## roadblock stands across a route-adjacent section of the day's locations, out of her view, the
## section is taken, and nothing the section held stands unspent but the roadblock. The view is
## `SWAP_VIEW_HALF_EXTENT` each way, so the nearest sections along her paths are in it.
const SWAP_VIEW_HALF_EXTENT := Vector2(900.0, 900.0)

func _test_with_none_close_by_a_section_is_taken(t) -> void:
	var city := _build_city(t, SEED)
	var director := _start_the_day(t, city, SEED)
	var player := _rig_player(t, director, director.contact_position())
	var her := player.global_position
	# A view wider than the screen, so the sections nearest her are in it and the one taken has to
	# be found past them.
	_view = Rect2(her - SWAP_VIEW_HALF_EXTENT, SWAP_VIEW_HALF_EXTENT * 2.0)
	var map := city.map
	for plan in city.events.plans():
		if plan.row_id() == "roadblock" and not plan.is_door() and not plan.is_in_the_wall():
			plan.spend()
	var locations := city.events.walk_events().locations()
	t.check(locations != null, "(swap) the walk has the day's locations")
	if locations == null:
		_tear_down(player, director, city)
		return
	var open_before := locations.sections_in(PlacementView.View.ROUTE_ADJACENT)
	if director.current_step():
		director.contact().complete_now()
	var roadblock: EventInstance = director.rider()
	t.check(roadblock != null and roadblock.def.id == "roadblock",
			"(swap) with none close by, reading the mark still offers a roadblock")
	if roadblock == null:
		_tear_down(player, director, city)
		return
	var taken: Location = null
	for section in open_before:
		if section.is_taken() and section.tiles().has_point(map.world_to_tile(roadblock.body_position())):
			taken = section
	t.check(taken != null, "(swap) it stands across a route-adjacent section, which is taken for the day")
	var box := EventFootprints.footprint_of(roadblock.def)
	t.check(not _view.intersects(Rect2(roadblock.global_position + box.position, box.size)),
			"(swap) no part of it is in her view when it is put there")
	if taken:
		var left := city.events.walk_events().placed_within(map.tile_rect_to_world(taken.tiles()))
		t.check(left.size() == 1 and left[0].instance() == roadblock,
				"(swap) of what the section held nothing stands but the roadblock (%d standing)"
				% left.size())
	_tear_down(player, director, city)

## How many of the day's plans are spent.
static func _spent(city: City) -> int:
	var count := 0
	for plan in city.events.plans():
		if plan.is_spent():
			count += 1
	return count

## Every tile she can walk to from `from` today, around every closure, sealed way and standing body.
static func _walkable_from(map: CityMap, from: Vector2) -> Dictionary:
	var start := map.world_to_tile(from)
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + side
			if reached.has(next) or not map.in_bounds(next) or not map.is_walkable(next) \
					or map.is_closed(next) or map.soft_sealed_tiles.has(next) \
					or map.is_obstructed(next):
				continue
			reached[next] = true
			queue.append(next)
	return reached

## Stands her beside a live roadblock other than `guarded`, the one the guard stands over, where
## the red arrow points at it once it has settled from there, and answers it; null when no live
## roadblock has such a spot. Only where the street runs on past the roadblock on its far side from
## her (`_a_street_beyond()`), where its guard stands. Each try settles the arrow the way `main`'s ticks do
## (`_settle_the_arrow()`), so whatever the arrow's choices do to the guard on the way, they do here.
## `accept`, when given, is the premise the caller's case needs of the roadblock (it is handed the
## roadblock and answers whether it will do): a roadblock it refuses is passed over.
func _her_way_to_another_roadblock(director: ResistanceDirector, player: Stroller,
		guarded: EventInstance, accept := Callable()) -> EventInstance:
	var map := _city.map
	for roadblock in ResistanceReads.answering(_city.events, director.current_step()):
		if roadblock == guarded or (accept.is_valid() and not accept.call(roadblock)):
			continue
		for tile in _spots_to_walk_up_from(map, roadblock):
			player.global_position = map.tile_to_world(tile)
			_settle_the_arrow(director)
			if ResistanceReads.pointed_at(director, [roadblock] as Array[EventInstance]) == roadblock:
				return roadblock
	return null

## Where she may stand to walk up to `roadblock`, nearest the try order first: open ground out along
## the streets from it, far enough out that the band round it is mostly out of his trigger range of
## her, so a spot for him is found at once when nothing is in view, and only where the street runs on
## past it on its far side from her (`_a_street_beyond()`), where its guard stands.
func _spots_to_walk_up_from(map: CityMap, roadblock: EventInstance) -> Array[Vector2i]:
	var centre := map.world_to_tile(roadblock.body_position())
	var spots: Array[Vector2i] = []
	for radius in [12, 10, 14, 8, 16, 6]:
		for offset: Vector2i in [Vector2i(radius, 0), Vector2i(-radius, 0), Vector2i(0, radius),
				Vector2i(0, -radius)]:
			var tile := centre + offset
			if not map.is_walkable(tile) or map.is_obstructed(tile) or map.is_closed(tile) \
					or not _a_street_beyond(map, centre, -offset / radius):
				continue
			spots.append(tile)
	return spots

## Whether two roadblocks stand on one street line: their streets run the same way along the same
## line of the lattice, so from out along it one stands behind the other.
static func _on_one_street_line(map: CityMap, a: Vector2, b: Vector2) -> bool:
	var first := map.network.segment_containing(map.world_to_tile(a))
	var second := map.network.segment_containing(map.world_to_tile(b))
	if first == null or second == null or first.horizontal != second.horizontal:
		return false
	return first.a.y == second.a.y if first.horizontal else first.a.x == second.a.x

## Whether the street through a roadblock at `centre` runs on in `direction` to ground a guard may
## stand on past its band, out to `ResistanceDirector.TASK_GUARD_FARTHEST`, with a clear line back to
## it: a far side with room for him on the ring a move takes while the band is in her view. Asked of
## the city's siting (`SpawnSiting.CONTACT_GROUND`), the ground a guard's spot is asked of, and of
## the line his notice takes (`CityMap.clear_line()`, which anything standing between hides).
func _a_street_beyond(map: CityMap, centre: Vector2i, direction: Vector2i) -> bool:
	var siting: SpawnSiting = _city.spawn_siting
	var ground := siting.ask_of_ground(ResistanceDirector.GUARD_BOX)
	var body := map.tile_to_world(centre)
	var across := Vector2i(direction.y, direction.x)
	# Past the view a move's band test sets (the band's edge and 48px) and the guard's own half-width.
	var nearest := ceili((EventCatalogue.by_id("alley_robbery").notice_within()
			+ ContactPoint.REACH + 110.0 + 48.0 + 14.0) / Tuning.TILE_SIZE) + 1
	var farthest := floori(ResistanceDirector.TASK_GUARD_FARTHEST / Tuning.TILE_SIZE)
	for k in range(nearest, farthest + 1):
		for side in range(-3, 4):
			var tile := centre + direction * k + across * side
			var spot := map.tile_to_world(tile)
			if map.in_bounds(tile) and spot.distance_to(body) <= ResistanceDirector.TASK_GUARD_FARTHEST \
					and siting.allows_every(SpawnSiting.CONTACT_GROUND, ground, spot) \
					and map.clear_line(body, spot, Mover.on_foot()):
				return true
	return false

## Runs the arrow to rest the way the game does: the
## physics ticks `main` runs (`ResistanceDirector.tick()`) sweep the walking fields a slice at a time,
## choosing again as each finishes (`ResistanceReads.settle()`).
func _settle_the_arrow(director: ResistanceDirector) -> void:
	ResistanceReads.settle(director, 1.0 / Engine.physics_ticks_per_second)

## One of the arrow's choices, as `main`'s ticks make them: a tick of the director as long as the
## arrow's clock (`ResistanceDirector.ARROW_RETARGET_SECONDS`), which chooses again and asks the
## task's guard to follow it (`tick()`), and sweeps a slice of any field under way.
static func _choose_again(director: ResistanceDirector) -> void:
	director.tick(ResistanceDirector.ARROW_RETARGET_SECONDS)

## The task's guard as the street has him: the live `task_guard` among the city's instances
## (`EventManager.instances()`), or null once he is gone.
func _task_guard() -> EventInstance:
	for instance in _city.events.instances():
		if instance.def.id == EventCatalogue.task_guard().id and not instance.is_finished:
			return instance
	return null

## The city of `seed_value` in a run of its own (`RunCity.with_own_run()`, held by the city), so
## the steps done and the alleys used are this test's and gone with it.
func _build_city(t, seed_value: int) -> City:
	_city = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(_city)
	_city.build(CityGenerator.generate(seed_value))
	return _city

func _start_the_day(t, city: City, seed_value: int) -> ResistanceDirector:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	var run: RunState = city.run
	run.resistance.completed_steps = done
	var state := CityState.new()
	run.attempt_spend.city_state = state
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	city.events.start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), [], city.map.doorstep_world_position())
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city.map, city.run, city.events, city.streets(), city.fronts(), city, null,
			city.spawn_siting)
	_seen_through = city.events.visible_view()
	_seen_through.look(_view, null)
	director.set_sight(city.events.sees)
	director.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
	return director

## A Stroller at `at`, in the tree, its physics stepped by nobody, handed to `director` and the
## test city's events as `main` hands her (`ResistanceDirector.use_player()`,
## `EventManager.use_player()`).
func _rig_player(t, director: ResistanceDirector, at: Vector2) -> Stroller:
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = at
	director.use_player(player)
	_city.events.use_player(player)
	return player

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s%d:%d:%s" % [_streams, seed_value, DAY, stream])
	return rng

func _tear_down(player: Stroller, director: ResistanceDirector, city: City) -> void:
	player.free()
	director.free()
	city.free()
	_city = null
	_seen_through = null
