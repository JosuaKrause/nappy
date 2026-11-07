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
	_test_the_move_reads_the_soft_seals_and_bodies_round_her(t)
	# The probes' days on which a guard drawn with no way asked stood on her only way.
	_streams = ""
	for seed_value in [1234567, 314159]:
		_test_the_guard_never_stands_on_her_only_way(t, seed_value)
	_streams = "day13-guard:"
	_test_the_done_task_sets_the_guard_on_her_wherever_he_stands(t, true)
	_test_the_done_task_sets_the_guard_on_her_wherever_he_stands(t, false)
	_test_out_of_her_view_the_done_task_sends_him_under_a_badge(t)
	_test_a_guard_warning_her_when_the_task_is_done_still_charges(t)
	_test_the_guard_walks_round_a_building_to_her(t)
	for seed_value in PLACEMENT_SEEDS:
		_test_the_roadblock_is_placed_under_the_rules_close_by(t, seed_value)

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

	var other := _her_way_to_another_roadblock(director, player, director.rider())
	t.check(other != null, "there is another live roadblock she can walk up to (%d live)"
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
	var everywhere := Vector2.ONE * (ResistanceDirector.TASK_GUARD_FARTHEST + 64.0)
	_view = Rect2(around - everywhere, everywhere * 2.0)
	t.check(not _guard_in_view(where), "he stands out of that view himself")
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
	t.check(_a_way_past(_city.map, guard.global_position, roadblock.body_position(),
			ContactPoint.body_reach(roadblock), player.global_position),
			"at %s she can still walk to it without coming within his notice" % what)

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

## Whether some walk from `from` reaches ground within `reach` of `body` without her centre coming
## within a guard at `guard`'s `EventDef.notice` along a clear line: a flood fill of the test's
## own over open, unobstructed walkable tiles, tile centres, never onto a tile his notice reaches.
static func _a_way_past(map: CityMap, guard: Vector2, body: Vector2, reach: float,
		from: Vector2) -> bool:
	var notice := EventCatalogue.by_id("alley_robbery").notice_within()
	var start := map.world_to_tile(from)
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if map.tile_to_world(tile).distance_to(body) <= reach:
			return true
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + side
			if seen.has(next):
				continue
			seen[next] = true
			if not map.in_bounds(next) or not map.is_walkable(next) or map.is_closed(next) \
					or map.is_obstructed(next):
				continue
			var at := map.tile_to_world(next)
			if at.distance_to(guard) <= notice and _a_clear_line(map, guard, at):
				continue
			queue.append(next)
	return false

func robbery_edge_of(roadblock: EventInstance) -> float:
	return EventCatalogue.by_id("alley_robbery").notice_within() + ContactPoint.body_reach(roadblock)

## Whether any part of a waiting robber standing at `feet` (22 by 44px above his feet, a few px to
## spare) is in the test's view.
func _guard_in_view(feet: Vector2) -> bool:
	return _view.has_area() and _view.intersects(Rect2(feet + Vector2(-14.0, -48.0),
			Vector2(28.0, 52.0)))

## **The guard is never put on her only way to the roadblock**: wherever she approaches a live
## roadblock of the day from, open ground 8 to 14 tiles out from it in each of four directions, the
## spot the task's guard is moved to when the arrow turns to it (`tick()`, as
## `_move_the_task_guard_to_her_target()` moves him, read off the street) leaves her a walk to touch
## range without coming within his notice — asked by the test's own flood fill — and he stands on the
## far side of the roadblock from her far more often than on hers. So does the spot he is placed on
## with the task, from where she read the mark. The places are taken roadblock by roadblock in turn,
## so each is approached while he stands over another and the arrow's turn moves him; a place whose
## arrow turns to a roadblock he already guards moves nobody and asks nothing.
func _test_the_guard_never_stands_on_her_only_way(t, seed_value: int) -> void:
	var city := _build_city(t, seed_value)
	var director := _start_the_day(t, city, seed_value)
	var player := _rig_player(t, director, director.contact_position())
	_view = Rect2()
	var mark := director.current_step()
	if mark:
		director.contact().complete_now()
	var map := city.map
	var asked := 0
	var blocked: Array[String] = []
	var near_side := 0
	var first := _task_guard()
	var roadblocks := ResistanceReads.answering(city.events, director.current_step())
	if first != null and director.rider() != null:
		var rider := director.rider()
		if not _a_way_past(map, first.global_position, rider.body_position(),
				ContactPoint.body_reach(rider), player.global_position):
			blocked.append("%s from where she read the mark" % map.world_to_tile(rider.body_position()))
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
				asked += 1
				var her := player.global_position
				var body := to.body_position()
				if not _a_way_past(map, guard.global_position, body, ContactPoint.body_reach(to), her):
					blocked.append("%s from %s" % [map.world_to_tile(body), tile])
				if (guard.global_position - body).dot(her - body) > 0.0:
					near_side += 1
	t.check(asked > 20 and blocked.is_empty(),
			"seed %d: wherever he is put, she keeps a way to the roadblock past his notice (%d asked, blocked %s)"
			% [seed_value, asked, blocked.slice(0, 4)])
	t.check(near_side * 3 < asked,
			"seed %d: and he stands on the far side of it from her far more often than on hers (%d of %d on her side)"
			% [seed_value, near_side, asked])
	_tear_down(player, director, city)

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

## **The ground she walks on shuts what `SpawnSiting.is_open_to()` shuts**: a move of the guard to the
## roadblock the arrow turns to (`_move_the_task_guard_to_her_target()`, read off the street) is
## refused when the soft-sealed tiles or the bodies round her leave her no way to it but through
## them, as they leave the fill none. She stands far past the detour the director's own fill follows
## round a roadblock (`GUARD_WAY_DETOUR`), so only her side of the roadblock (`HerSide`, the ground
## she reaches without coming near it) can give a spot a way past him. With the guard sent to another
## roadblock first, and the day's others finished (`EventManager.retire()`) so the arrow chooses
## between those two, she stands beyond the task's own on the side away from the other, where the
## arrow turns to it: open, he moves to it;
## with her ringed in by seals or by bodies, the arrow still on it, he stays where he is through the
## arrow's choices; with the ring taken away he moves to it again.
func _test_the_move_reads_the_soft_seals_and_bodies_round_her(t) -> void:
	var city := _build_city(t, SEED)
	var director := _start_the_day(t, city, SEED)
	var player := _rig_player(t, director, director.contact_position())
	_view = Rect2()
	if director.contact():
		director.contact().complete_now()
	var roadblock := director.rider()
	var first := _task_guard()
	t.check(roadblock != null and first != null, "the task rides a roadblock, guarded, to move a guard round")
	if roadblock == null or first == null:
		_tear_down(player, director, city)
		return
	_view = Rect2(first.global_position - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
	_settle_the_arrow(director)
	_view = Rect2()
	var other := _her_way_to_another_roadblock(director, player, roadblock)
	var near_other := player.global_position
	t.check(other != null and not _guards_one(first, roadblock),
			"the guard is sent to another live roadblock first")
	if other == null:
		_tear_down(player, director, city)
		return
	var map := city.map
	var body := roadblock.body_position()
	# The day's other roadblocks finish, so the arrow chooses between these two alone.
	for live in ResistanceReads.answering(city.events, director.current_step()):
		if live != roadblock and live != other:
			city.events.retire(live)
	# Past the farthest ground any guard round the roadblock notices her from and the detour the
	# director's fill follows (its `_guard_notice_reach()` and `GUARD_WAY_DETOUR`), and with room
	# for a ring of tiles about her.
	var far := ResistanceDirector.TASK_GUARD_FARTHEST + EventCatalogue.task_guard().notice_within() \
			+ Tuning.TILE_SIZE + ResistanceDirector.GUARD_WAY_DETOUR + 4.0 * Tuning.TILE_SIZE
	# Looked for beyond the task's roadblock on the side away from the other, where the arrow turns
	# to the task's own.
	var outward := (body - other.body_position()).normalized()
	var across := outward.orthogonal()
	var her := Vector2.INF
	var her_tile := Vector2i.ZERO
	for k in 24:
		for side: int in [0, 2, -2, 4, -4]:
			var cand := map.world_to_tile(body + outward * (far + k * Tuning.TILE_SIZE)
					+ across * side * Tuning.TILE_SIZE)
			if not _open_about(map, cand, 2) or map.tile_to_world(cand).distance_to(body) < far:
				continue
			player.global_position = map.tile_to_world(cand)
			_follows_the_arrow(director, first)
			if _guards_one(first, roadblock) \
					and ResistanceReads.pointed_at(director, [roadblock] as Array[EventInstance]) != null:
				her_tile = cand
				her = map.tile_to_world(cand)
				break
		if her != Vector2.INF:
			break
	t.check(her != Vector2.INF,
			"there is open ground far past the roadblock to stand on, from which he is moved to it")
	if her == Vector2.INF:
		_tear_down(player, director, city)
		return
	var send_him_away := func() -> bool:
		player.global_position = near_other
		_settle_the_arrow(director)
		return not _guards_one(first, roadblock)
	var ring_body := 1
	var ring: Array[Vector2i] = []
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if maxi(absi(dx), absi(dy)) == 2:
				ring.append(her_tile + Vector2i(dx, dy))
	var day_seals := map.soft_sealed_tiles.duplicate()
	t.check(send_him_away.call(), "sent back to the other roadblock")
	for tile in ring:
		map.seal_soft_tile(tile)
	player.global_position = her
	var was := first.global_position
	_settle_the_arrow(director)
	t.check(ResistanceReads.pointed_at(director, [roadblock] as Array[EventInstance]) != null
			and first.global_position == was,
			"soft-sealed all round her, the arrow on the roadblock, no spot leaves her a way past him: he stays")
	# Taking the ring's seals off is the map's own clear, then the day's seals back.
	map.clear_day_soft_seals()
	for tile: Vector2i in day_seals:
		map.seal_soft_tile(tile)
	t.check(send_him_away.call(), "sent back to the other roadblock again")
	map.obstruct_tiles(ring_body, ring)
	player.global_position = her
	was = first.global_position
	_settle_the_arrow(director)
	t.check(ResistanceReads.pointed_at(director, [roadblock] as Array[EventInstance]) != null
			and first.global_position == was,
			"bodies standing all round her, the arrow on the roadblock, he stays")
	map.release_obstruction(ring_body)
	_follows_the_arrow(director, first)
	t.check(_guards_one(first, roadblock), "with the ring taken away he is moved to it again")
	_tear_down(player, director, city)

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

## Whether `guard` stands in `roadblock`'s band (`inner_radius + reach` to `notice_within() +
## reach` from its body).
static func _guards_one(guard: EventInstance, roadblock: EventInstance) -> bool:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var reach := ContactPoint.body_reach(roadblock)
	var away := guard.global_position.distance_to(roadblock.body_position())
	return away >= robbery.inner_radius + reach - 0.5 and away <= robbery.notice_within() + reach + 0.5

## Whether every tile within `radius` of `tile` is open ground on foot (`SpawnSiting.is_open_to()`).
static func _open_about(map: CityMap, tile: Vector2i, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var at := tile + Vector2i(dx, dy)
			if not map.in_bounds(at) or not SpawnSiting.is_open_to(map, at, Mover.on_foot()):
				return false
	return true

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
		if map.is_walkable(map.world_to_tile(at)) and map.clear_line(guard.global_position, at):
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
	var found := plans.size() == plans_before
	var swapped: bool = plans.size() == plans_before + 1 and plans.back().live == roadblock \
			and _spent(city) == spent_before + 1
	t.check(found or swapped,
			"seed %d: it is a roadblock the day placed, or one swapped in for a day's event"
			% seed_value)
	var away := roadblock.global_position.distance_to(her)
	# She touches it from ground her paths reach within the widest ring, a tile and a half from its
	# body at most.
	var widest: float = ResistanceDirector.ROADBLOCK_WIDER_REACH.back()
	var touch := EventScheduler.Planned.new(roadblock.def, Vector2.ZERO).blocking_radius() \
			+ Tuning.TILE_SIZE * 2.0
	t.check(away <= widest + touch,
			"seed %d: close by, %.0fpx from where she read the mark (within %.0fpx)"
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
## roadblock has such a spot. Each try settles the arrow the way `main`'s ticks do
## (`_settle_the_arrow()`), so whatever the arrow's choices do to the guard on the way, they do here.
func _her_way_to_another_roadblock(director: ResistanceDirector, player: Stroller,
		guarded: EventInstance) -> EventInstance:
	var map := _city.map
	for roadblock in ResistanceReads.answering(_city.events, director.current_step()):
		if roadblock == guarded:
			continue
		var centre := map.world_to_tile(roadblock.body_position())
		# Far enough out that the band round it is mostly out of his trigger range of her, so a spot
		# for him is found at once when nothing is in view.
		for radius in [12, 10, 14, 8, 16, 6]:
			for offset: Vector2i in [Vector2i(radius, 0), Vector2i(-radius, 0), Vector2i(0, radius),
					Vector2i(0, -radius)]:
				var tile := centre + offset
				if not map.is_walkable(tile) or map.is_obstructed(tile) or map.is_closed(tile):
					continue
				player.global_position = map.tile_to_world(tile)
				_settle_the_arrow(director)
				if ResistanceReads.pointed_at(director, [roadblock] as Array[EventInstance]) == roadblock:
					return roadblock
	return null

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
