extends "res://tests/resistance_rig.gd"
## **Wherever the resistance sends her, a way stands over ground that has drawn**: the outcome
## asked of the contact that stands, whichever search placed it. A unit of the day's locations
## draws as she comes near it, so a place fixed ahead of her walk has to lie inside the ground
## already drawn round her, her own paths reaching it there, or have no undrawn unit within
## `Tuning.EVENT_DRAW_AHEAD` of it and a way from home whose ground has drawn; otherwise a unit
## drawn later can stand a body on it or shut the way it was found reachable by
## (`ResistanceDirector._she_can_be_sent_to()`, `WayConfirmation`).
##
## One sweep over the rig's three cities. Every task of days 6 to 13 is asked as its mark is
## read, and day 8 again with a scar recorded at fronts across the city, the place a run that
## played day 3 sends her to. Then the three writes a tick makes: a mark moved near her before she
## has seen it, day 11's contact moved to another mast with the red arrow, and day 6's contact
## riding onto another man shouting she stands beside. For those she is put down far from her
## door, where nothing has drawn: a played day keeps the ground round her drawn, so there the
## answer is her own way; put down like this it costs a search, which shows the question is asked
## at the write and does not hold only because the distances fit. The sweep asks nothing of how a
## place was found, so a search added later is held by it too. The mark as the day starts is
## `test_resistance_reach_marks`'s.
##
## **A real city, and the day's real order**: the outcome is a property of the director, the walk's
## reach and the units' draw together over ground a generator made, which no stand-in holds.

const ResistanceReads := preload("res://tests/resistance_reads.gd")

## The cities swept: the three `test_resistance_reach_narrow` places its tasks on.
const CITIES: Array[int] = [SEED, 90210, 1234567]
const DAYS: Array[int] = [6, 7, 8, 9, 10, 11, 12, 13]
## How many fronts across each city day 8's scar is recorded at, one a day.
const SCARS_A_CITY := 4
## The day a mark is moved on: any day with a mark.
const MOVED_MARK_DAY := 7
## The day the contact rides onto a look-alike: day 6's, any man shouting.
const LOOK_ALIKE_DAY := 6
## How many of the mark tiles farthest from her door a move is tried at.
const MOVES_TRIED := 40

## How a way stands to a contact: her own, inside the ground drawn round her; one from home; none
## asked for, since no ground she can stand on and reach touches the contact; or none.
const INSIDE := "inside the ground drawn round her"
const FROM_HOME := "over a way from home"
const OUT_OF_REACH := "out of her reach"
const NO_WAY := "no way over drawn ground"

## How far from a way that stands the nearest undrawn unit lies, at least, worked out here from
## what a confirmation draws: `Tuning.EVENT_DRAW_AHEAD` round every `WayConfirmation.STEP`th tile,
## each tile of the way within half a step of one. What her own paths keep from an undrawn unit.
const CLEAR := Tuning.EVENT_DRAW_AHEAD - WayConfirmation.STEP * Tuning.TILE_SIZE / 2.0

## How many tiles round a contact the ground she touches it from is looked for in, and round a
## door she crosses, whose pool is the middle of its street.
const TOUCH_TILES := 3
const CROSSING_TILES := 8

func run(t: TestRunner) -> void:
	_test_wherever_she_is_sent_a_way_stands_over_drawn_ground(t)
	_free_city()

func _test_wherever_she_is_sent_a_way_stands_over_drawn_ground(t: TestRunner) -> void:
	var held := _no_counts()
	var scars := _no_counts()
	var moved := _no_counts()
	var arrows := _no_counts()
	var look_alikes := _no_counts()
	for seed_value in CITIES:
		# One city of a run of its own per seed; each case sets the steps done, the alleys used
		# and the scars on that run, so no case leans on the one before.
		_build_city_in_a_new_run(t, seed_value)
		for day in DAYS:
			_ask_the_task(t, day, seed_value, Vector2.INF, held)
		for front in _fronts_across_the_city():
			_ask_the_task(t, 8, seed_value, _city.map().tile_to_world(front), scars)
		_ask_a_moved_mark(t, seed_value, moved)
		_ask_the_arrows_mast(t, seed_value, arrows)
		_ask_a_look_alike(t, seed_value, look_alikes)
	_free_city()
	t.check(held[INSIDE] > 0 and held[FROM_HOME] > 0 and held[NO_WAY] == 0,
			"tasks stood inside the ground drawn round her (%d) and beyond it, over a way from home (%d)"
			% [held[INSIDE], held[FROM_HOME]])
	t.check(scars[FROM_HOME] > 0 and scars[NO_WAY] == 0,
			("day 8's burnt building stood at a recorded scar beyond the ground drawn round her " +
			"(%d), near her (%d), or out of her reach that day (%d)")
			% [scars[FROM_HOME], scars[INSIDE], scars[OUT_OF_REACH]])
	t.check(moved[FROM_HOME] + moved[INSIDE] > 0 and moved[NO_WAY] == 0,
			"a mark was moved near her (%d)" % (moved[FROM_HOME] + moved[INSIDE]))
	t.check(arrows[FROM_HOME] + arrows[INSIDE] > 0 and arrows[NO_WAY] == 0,
			"day 11's contact was moved to another mast (%d)" % (arrows[FROM_HOME] + arrows[INSIDE]))
	t.check(look_alikes[FROM_HOME] + look_alikes[INSIDE] > 0 and look_alikes[NO_WAY] == 0,
			"day 6's contact rode onto another man shouting (%d)"
			% (look_alikes[FROM_HOME] + look_alikes[INSIDE]))

## A count of contacts for each way one can stand, all at none.
static func _no_counts() -> Dictionary:
	return {INSIDE: 0, FROM_HOME: 0, OUT_OF_REACH: 0, NO_WAY: 0}

## Day `day`'s task on the test city, its mark read standing on it with her screen the view, and
## the contact that stands asked how a way stands to it (`_how_a_way_stands()`), counted into
## `held`. `scar_at` is where the run recorded day 3's fire, `Vector2.INF` for a run with none.
func _ask_the_task(t: TestRunner, day: int, seed_value: int, scar_at: Vector2,
		held: Dictionary) -> void:
	var scars: Array[Dictionary] = []
	if scar_at != Vector2.INF:
		scars.append({"id": "burnt_shell", "position": scar_at, "since_day": 3})
	GivenRun.scars(_city.run, scars)
	var read := _read_the_mark_on(t, day, seed_value)
	var director: ResistanceDirector = read[0]
	var mark: Vector2 = read[1]
	var player: Stroller = read[2]
	var label := "seed %d day %d%s" % [seed_value, day,
			"" if scar_at == Vector2.INF else ", a scar at %s" % _city.map().world_to_tile(scar_at)]
	var step := director.current_step()
	t.check(step != null and not step.is_pickup,
			"%s: reading the mark puts its task on offer" % label)
	if step != null and not step.is_pickup:
		var how := _how_a_way_stands(director, mark)
		held[how] += 1
		t.check(how != NO_WAY,
				("%s: the contact, %.0fpx from where she read the mark, lies inside the ground " +
				"drawn round her, or has no undrawn unit within %.0fpx and a way from home over " +
				"drawn ground") % [label, director.contact_position().distance_to(mark),
				Tuning.EVENT_DRAW_AHEAD])
		# Only a burnt building where the fire burned may stand where she cannot be sent: its
		# place is the run's record, not a pick.
		t.check(how != OUT_OF_REACH or scar_at != Vector2.INF,
				"%s: the contact can be touched from ground she can stand on and reach" % label)
	player.free()
	director.free()

## A mark moved near her before she has seen it (`ResistanceDirector._move_the_mark()`): the day
## started, she is put down outside the mouth of a mark tile far from her door, where the walk has
## drawn nothing, and one tick moves the mark there. The moved mark is asked how a way stands to
## it, counted into `held`. The tiles farthest from her door are tried in turn until one takes it.
func _ask_a_moved_mark(t: TestRunner, seed_value: int, held: Dictionary) -> void:
	var no_scars: Array[Dictionary] = []
	GivenRun.scars(_city.run, no_scars)
	var director := _start_the_day_on(t, MOVED_MARK_DAY, seed_value)
	_look_at(Rect2())
	var map := _city.map()
	var door := map.doorstep_world_position()
	var tiles := _mark_tiles()
	tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return map.tile_to_world(a).distance_squared_to(door) \
				> map.tile_to_world(b).distance_squared_to(door))
	var before := director.contact_position()
	var player := _rig_player(t, before)
	director.use_player(player)
	for index in mini(MOVES_TRIED, tiles.size()):
		var her := _outside_its_mouth(map, tiles[index])
		if her.distance_to(before) <= ResistanceDirector.NOTICE_RADIUS:
			continue
		player.global_position = her
		director.tick(STEP)
		if director.contact_position().distance_to(before) <= 0.5:
			continue
		var how := _how_a_way_stands(director, her)
		held[how] += 1
		t.check(how == INSIDE or how == FROM_HOME,
				("seed %d day %d: the mark moved to %s, %.0fpx from her door, lies inside the " +
				"ground drawn round her or has a way from home over drawn ground (%s)")
				% [seed_value, MOVED_MARK_DAY, map.world_to_tile(director.contact_position()),
				director.contact_position().distance_to(door), how])
		break
	player.free()
	director.free()

## Day 11's contact moved to another mast (`ResistanceDirector._point_the_arrow_at()`): its mark
## read, she is put down beside the foot of the live mast farthest from it, within its touch, and
## one tick moves the contact and the arrow there (`_follow_her_between_masts()`). The contact is
## asked how a way stands to it, counted into `held`.
func _ask_the_arrows_mast(t: TestRunner, seed_value: int, held: Dictionary) -> void:
	var no_scars: Array[Dictionary] = []
	GivenRun.scars(_city.run, no_scars)
	var read := _read_the_mark_on(t, 11, seed_value)
	var director: ResistanceDirector = read[0]
	var mark: Vector2 = read[1]
	var player: Stroller = read[2]
	var map := _city.map()
	var first := director.contact_position()
	var reach := ResistanceReads.day_reachability(_city)
	var far_foot := Vector2.INF
	var beside := Vector2i(-1, -1)
	for plan in RunCity.events(_city).plans():
		if plan.row_id() != "loudspeaker" or plan.is_silenced() or not plan.is_placed() \
				or plan.placed_at().distance_to(first) < 0.5:
			continue
		if far_foot != Vector2.INF \
				and plan.placed_at().distance_to(mark) <= far_foot.distance_to(mark):
			continue
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var tile := map.world_to_tile(plan.placed_at()) + side
			if SpawnSiting.is_legal_ground(map, tile, _walled_alleys()) \
					and not map.is_obstructed(tile) and ResistanceReads.reaches_home(reach, tile):
				far_foot = plan.placed_at()
				beside = tile
				break
	if far_foot != Vector2.INF and director.current_step() != null:
		var her := map.tile_to_world(beside)
		player.global_position = her
		director.tick(STEP)
		if director.contact_position().distance_to(far_foot) < 0.5:
			var how := _how_a_way_stands(director, her)
			held[how] += 1
			t.check(how == INSIDE or how == FROM_HOME,
					("seed %d day 11: the mast the contact moved to, %.0fpx from the mark, lies " +
					"inside the ground drawn round her or has a way from home over drawn ground (%s)")
					% [seed_value, far_foot.distance_to(mark), how])
	player.free()
	director.free()

## Day 6's contact riding onto another man shouting
## (`ResistanceDirector._follow_her_between_look_alikes()`): its mark read, a second man shouting
## is stood on the sidewalk farthest from her door a contact may stand on, as the day's own draw
## could have stood one, she is put down on that tile, and one tick moves the contact onto him.
## The contact is asked how a way stands to it, counted into `held`.
func _ask_a_look_alike(t: TestRunner, seed_value: int, held: Dictionary) -> void:
	var no_scars: Array[Dictionary] = []
	GivenRun.scars(_city.run, no_scars)
	var read := _read_the_mark_on(t, LOOK_ALIKE_DAY, seed_value)
	var director: ResistanceDirector = read[0]
	var player: Stroller = read[2]
	var map := _city.map()
	var door := map.doorstep_world_position()
	var reach := ResistanceReads.day_reachability(_city)
	var far := Vector2.INF
	for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		var at := map.tile_to_world(tile)
		if far != Vector2.INF and at.distance_squared_to(door) <= far.distance_squared_to(door):
			continue
		if SpawnSiting.is_legal_ground(map, tile, _walled_alleys()) \
				and not map.is_obstructed(tile) and ResistanceReads.reaches_home(reach, tile):
			far = at
	var step := director.current_step()
	if far != Vector2.INF and step != null and not step.is_pickup:
		var decoy := RunCity.events(_city).spawn_extra(EventCatalogue.by_id(step.task_event_id), far)
		player.global_position = far
		director.tick(STEP)
		if director.rider() == decoy:
			var how := _how_a_way_stands(director, far)
			held[how] += 1
			t.check(how == INSIDE or how == FROM_HOME,
					("seed %d day %d: the man shouting the contact rode onto, %.0fpx from her " +
					"door, stands inside the ground drawn round her or has a way from home over " +
					"drawn ground (%s)") % [seed_value, LOOK_ALIKE_DAY, far.distance_to(door), how])
	player.free()
	director.free()

## `SCARS_A_CITY` of the fronts day 3's fire can catch on in the test city, spread through the
## list, which runs over the city row by row.
func _fronts_across_the_city() -> Array[Vector2i]:
	var fronts := EventScheduler.row_ground(_city.map()).tiles_for(
			EventCatalogue.by_id("burning_building"))
	var found: Array[Vector2i] = []
	for k in SCARS_A_CITY:
		if not fronts.is_empty():
			found.append(fronts[(2 * k + 1) * fronts.size() / (2 * SCARS_A_CITY)])
	return found

## **How a way stands to the contact `director` has standing, with her at `her`**, worked out
## from the city and the day's units by walks the director does not run. **Clear ground** is
## ground more than `CLEAR` from every undrawn unit: nothing drawn later is judged against it,
## stands on it or reaches it with its field. `INSIDE` where a walk from her own tile over clear
## ground, no further from her than the ground round her has drawn (`_drawn_round()`), reaches
## ground she touches the contact from; `FROM_HOME` where a walk from home over clear ground
## reaches such ground with no undrawn unit within `Tuning.EVENT_DRAW_AHEAD` of it;
## `OUT_OF_REACH` where no ground she can stand on and reach touches it at all; `NO_WAY`
## otherwise.
func _how_a_way_stands(director: ResistanceDirector, her: Vector2) -> String:
	var map := _city.map()
	var items: Array[Vector2] = [director.contact_position()]
	if director.rider() != null:
		items.append(director.rider().global_position)
	var reach := ResistanceReads.day_reachability(_city, _the_tasks_own_bodies(director))
	var grounds := _the_ground_she_touches_it_from(director, items, reach)
	if grounds.is_empty():
		return OUT_OF_REACH
	var blocked: Dictionary = reach[1]
	var unclear := _the_ground_near_an_undrawn_unit()
	var from_her := _walked_over_clear_ground(map.world_to_tile(her), blocked, unclear, her,
			_drawn_round(her))
	for ground in grounds:
		if from_her.has(ground):
			return INSIDE
	var from_home := _walked_over_clear_ground(map.home_tile(), blocked, unclear, Vector2.ZERO, INF)
	var units := RunCity.events(_city).walk_events().unit_draw().units()
	for ground in grounds:
		if from_home.has(ground) and units.undrawn_within(map.tile_to_world(ground),
				Tuning.EVENT_DRAW_AHEAD).is_empty():
			return FROM_HOME
	return NO_WAY

## Where the task's own bodies stand, which the day's reach is built without: the body its contact
## rides (a van, a roadblock) and day 11's pole under the contact. A body put down for the task
## must not shut the ground the task is touched from; any other body there does.
func _the_tasks_own_bodies(director: ResistanceDirector) -> Array[Vector2]:
	var bodies: Array[Vector2] = []
	if director.rider() != null and ContactPoint.has_a_body(director.rider()):
		bodies.append(director.rider().global_position)
	var step := director.current_step()
	if step != null and step.target_kind == ResistanceSteps.TargetKind.MAST:
		bodies.append(director.contact_position())
	return bodies

## How far round `at` the day's ground has drawn: the distance to the nearest undrawn unit, `INF`
## with none left.
func _drawn_round(at: Vector2) -> float:
	var undrawn := RunCity.events(_city).walk_events().unit_draw().units().undrawn_within(at, INF)
	if undrawn.is_empty():
		return INF
	var bounds := undrawn[0].bounds()
	return at.distance_to(Vector2(clampf(at.x, bounds.position.x, bounds.end.x),
			clampf(at.y, bounds.position.y, bounds.end.y)))

## **The ground within `CLEAR` of an undrawn unit**, a byte a tile in rows (`y * width + x`), 1
## where the tile's centre is that near the bounds of a unit that has not drawn.
func _the_ground_near_an_undrawn_unit() -> PackedByteArray:
	var size := _city.map().size_in_tiles()
	var near := PackedByteArray()
	near.resize(size.x * size.y)
	var tile_size := float(Tuning.TILE_SIZE)
	for unit in RunCity.events(_city).walk_events().unit_draw().units().undrawn_within(Vector2.ZERO, INF):
		var bounds := unit.bounds()
		var low := Vector2i(((bounds.position - Vector2(CLEAR, CLEAR)) / tile_size).floor())
		var high := Vector2i(((bounds.end + Vector2(CLEAR, CLEAR)) / tile_size).floor())
		for y in range(maxi(low.y, 0), mini(high.y, size.y - 1) + 1):
			for x in range(maxi(low.x, 0), mini(high.x, size.x - 1) + 1):
				var centre := (Vector2(x, y) + Vector2(0.5, 0.5)) * tile_size
				var nearest := Vector2(clampf(centre.x, bounds.position.x, bounds.end.x),
						clampf(centre.y, bounds.position.y, bounds.end.y))
				if centre.distance_to(nearest) <= CLEAR:
					near[y * size.x + x] = 1
	return near

## **The tiles a walk from `start` reaches over clear ground** (`tile -> true`): tile by tile over
## walkable ground the day's obstruction leaves open (`blocked`) and no undrawn unit lies near
## (`unclear`, `_the_ground_near_an_undrawn_unit()`), no further than `within` from `centre`.
## `start` is walked from even where it is blocked, since she may stand inside a body's disc and
## home is walked from wherever it is, but not where it is unclear: then the walk reaches nothing.
func _walked_over_clear_ground(start: Vector2i, blocked: Dictionary, unclear: PackedByteArray,
		centre: Vector2, within: float) -> Dictionary:
	var map := _city.map()
	var size := map.size_in_tiles()
	var found := {}
	if not Rect2i(Vector2i.ZERO, size).has_point(start) or unclear[start.y * size.x + start.x] == 1:
		return found
	found[start] = true
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + step
			if found.has(next) or not map.is_walkable(next) or blocked.has(next) \
					or unclear[next.y * size.x + next.x] == 1 \
					or map.tile_to_world(next).distance_to(centre) >= within:
				continue
			found[next] = true
			queue.append(next)
	return found

## **The ground she touches the contact from**: every tile within `TOUCH_TILES` of the contact, or
## of what it rides (`items`), that is legal ground reachable from home today (`reach`, the day's
## without the task's own bodies, `ResistanceReads.day_reachability()`) and from whose centre a
## touch completes it (`ContactTouches`), the tile the contact or its rider stands on among them
## whatever the task's own body covers; for day 9's door, which is crossed and not touched, the
## legal, reachable ground within `CROSSING_TILES` of the gatehouse the contact stands on.
func _the_ground_she_touches_it_from(director: ResistanceDirector, items: Array[Vector2],
		reach: Array) -> Array[Vector2i]:
	var map := _city.map()
	var step := director.current_step()
	var crossed := step != null and step.target_kind == ResistanceSteps.TargetKind.DOOR
	var span := CROSSING_TILES if crossed else TOUCH_TILES
	var found: Array[Vector2i] = []
	for item in items:
		var centre := map.world_to_tile(item)
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var tile := centre + Vector2i(dx, dy)
				if found.has(tile) \
						or not SpawnSiting.is_legal_ground(map, tile, _walled_alleys(), true) \
						or not ResistanceReads.reaches_home(reach, tile):
					continue
				var its_own := tile == centre
				if map.is_obstructed(tile) and not its_own:
					continue
				if crossed or its_own \
						or ContactTouches.touches_from_one(director, map.tile_to_world(tile)):
					found.append(tile)
	return found
