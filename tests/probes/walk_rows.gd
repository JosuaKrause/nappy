extends RefCounted
## Measurement probe for the walk's mix (`docs/EVENTS.md`, "The density, and why it is a declared
## table"): **what each day puts in the world as she walks, row by row, by view and by kind of
## ground.** Not a suite: it prints rather than asserting, so it lives here under `tests/probes/`,
## where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/walk_rows.gd
##
## Each day's dawn is planned as `placement_rows.gd` plans it, its units left undrawn
## (`GameDawn.undrawn()`), and then walked: the day's longest route out from the doorstep and home
## again, at walking speed, a tick a thirtieth of a second. **The units draw as she walks, as
## `EventsAhead.draw_what_comes_near()` draws them**: asked again on a tick she stands on another
## tile or a unit was still wanted, every undrawn unit within the stream radius of her
## (`Tuning.EVENT_STREAM_RADIUS`) drawn whole, with every unit it waits for, else one unit towards
## the nearest unit within `Tuning.EVENT_DRAW_AHEAD` beyond it; what a draw places joins her walk,
## a row handed to her walk owed to the director (`EventDirector.owe_on_her_way()`). Every tick
## the director sites what it sites on her way (`EventDirector.due()`,
## `site_what_is_on_her_way()`), a beat taking a location of the nearest unit on her way that has
## not drawn where there is one, and that unit drawing round it (`WalkSiting`, `UnitDraw`). After the
## walk every unit left is drawn. A placed row counts once it comes within the stream
## radius of her, the moment it would stream in, under its row, its view and its kind of ground:
## a row the director sites on her way among them, once sited (day 3's fire), but not a place her
## route's bag hands it. Prints `WH day row count`, what the director hands out on her walk
## (`EventDirector.due()`) row by row, summed over the seeds; `WD day seeds streamed`,
## `WV day row view count`, `WK day row kind count` and `WM day met at-the-door late-out`, where the capped rows are met (`CAPPED`: within
## the stream radius of her door, and in the second half of the walk out), summed over the seeds,
## and per seed and day `WT day seed siting ticks median p99 worst total`, the director's siting's
## tick costs in microseconds, and `WP day seed microseconds`, the dawn's planning of each
## (`EventScheduler.build_day()`, which draws no unit). **And where the beats her walk laid stand**:
## per day, summed over the seeds, `WS day laid in-undrawn in-empty nearest`, the beats the
## director laid or moved on her way, how many took a location of a unit that had not drawn, how
## many one a drawn unit left empty, and the smallest gap, in px, between a beat and a row a unit
## drew, measured with every unit drawn (`EventPlan.gap_to()`; expected no less than
## `EventScheduler.EVENT_SPACING_ANY`); `WS all` sums the days. **And which units drew by her path**:
## per day, summed over the seeds, `WR day units differ beside-a-beat carried unexplained`, the
## units, how many drew other rows or other places than on the same dawn drawn whole with no walk
## (the city made again and the day planned again, every unit drawn), how many of those a beat
## stands or stood in, or touch a unit one does or did (a beat moved off a unit leaves what the unit
## drew round it as drawn), how many of the rest touch a unit that differs (a unit is judged among
## the draws of the touching units drawn before it, so a difference can carry), and how many are
## none of those (expected none: a difference out of nowhere is a defect); `WR all` sums the days.
## **What it lays is day 3's fire**: a sidewalk poster crew pastes a building's blank wall, which
## only the built city knows (`SitingMaker.make()` hands the siting the day's fronts), so a crew a
## unit hands to her walk stays unplaced here; a crew laid in a unit before it draws is
## `tests/test_event_manager_units.gd`'s, against the game's own manager. Each day is planned
## as the game plans it: its closures, holds, region wall and seals first, the seals and the wall's
## bodies handed in as standing.
##
## **What drawing as she walks costs, at two reaches of the touching relation** (`REACHES`):
## the item's relation, which the game uses (none), and the widest lethal field a rule keeps clear
## (270px, the alley robbery's), at which two units whose ground lies within it of each other touch
## as well (`DayUnits.of()`'s `reach`). Per reach, day and seed: `WU reach day seed drawn-on-the-walk
## drawn-after longest-pull longest-chain`, the units drawn while she walks and after it, the most
## units one unit she came near drew before it drew itself (its pull: one `UnitDraw.draw()` of a
## unit within the stream radius, or the units drawn towards one beyond it until it drew), and the
## longest chain of touching units each ranked below the last, worked out from `draws_before()`
## and `touching()` before the walk; and `WQ reach day seed median p99 worst`, one unit's draw in
## microseconds. `WU all reach ...` and `WQ all reach ...` sum and pool every day and seed. The
## game draws with the item's relation alone, so everything else printed here is that walk's;
## the wider reach is a second dawn planned on a fresh city and walked the same way, measured for
## its pull and its cost only.
##
## **And how the units drew, marble by marble** (`MarbleDraw`): per day, summed over the seeds,
## `WZ day sections locations marbles empty`, the rows every unit placed by what each took
## of its unit (`EventDef.takes_of_a_street()` in a street, one location elsewhere, the rule
## `MarbleDraw` keeps private; a row handed to her walk counted), the marbles the units drew and
## how many of them were empty. A unit's marbles are worked out from its room before it draws
## (`UnitRoom`, counted in small marbles: a section speaks for two), since every marble takes its share of it and a unit draws until it is spoken for;
## `WZ all` sums the days.
##
## **And whether the day's routes stay open, which no rule floods the city to keep** (`RouteGroundRule`
## and the line rules of `StreetInvalidation` keep them by construction): per day, summed over the
## seeds, `WC day dawn walk`, the route tiles (`Corridor.carries_a_route()`) home reached among the
## day's closures that it no longer reaches among the day's obstructing bodies (`EventPlan.obstructs()`)
## and that no body's disc covers, counted once after the dawn's plan (its rows, the seals and the
## region wall's bodies) and once at the end of her walk with every unit drawn (everything the walk
## then holds, what it sited included), so a tile cut off names which half placed the body;
## `WC all dawn walk` sums the days. Each such tile prints `WX day seed half tile kind rows`, the
## rows being the bodies whose taking away alone gives it back (`jointly` where none does). The
## expected count is none.
##
## **And what the street rules refuse, and whether a street ends with both sidewalks closed**: per
## day, summed over the seeds, `WL day rule refusals`, how many times each of the day's rules
## refused a candidate of the dawn's judge, which every unit's draw asks
## (`StreetInvalidation.refusals()`: the first rule to refuse a candidate counts it), and per day
## and view (`Corridor.view_of()`: 0 on the route, 1 route-adjacent, 2 off the route) `WB day view
## streets both-closed`, the streets of the city and how many of them have neither sidewalk
## walkable junction to junction past the obstructing bodies (`EventPlan.obstructs()`, at
## `EventPlan.blocking_radius()`, `RouteSidewalkRule.closes_a_walked_sidewalk_band()`) once every
## unit has drawn, leaving out the streets a closure, a seal, the region wall or a roadblock closes
## by itself; `WB all view ...` sums the days. The one-sidewalk rule (`OneSidewalkOpenRule`) keeps
## that count at none on the route.

const SEEDS := 18
const BASE := 90210
const STEP := 31
const KINDS := ["sidewalk", "carriageway", "alley", "open", "junction", "other"]
## A tick of her walk, in seconds.
const TICK := 1.0 / 30.0
## The rows whose caps bound what she meets, the dawn drawing the whole city, for the `WM` lines.
const CAPPED := ["abduction", "alley_mouse", "charging_dog", "chatting_mother", "pigeon_flock",
		"roadblock"]
## The touching relation's reaches measured, in px: the item's relation (the game's), and the
## widest lethal field a rule keeps clear.
const REACHES: Array[float] = [0.0, 270.0]

## **The units drawn as she walks**, as `EventsAhead.draw_what_comes_near()` draws them, with what
## the `WU` and `WQ` lines count.
class _Drawing extends RefCounted:
	var draw: UnitDraw
	var on_the_walk := 0
	var after := 0
	var longest_pull := 0
	var longest_chain := 0
	## One unit's draw, in microseconds, each.
	var costs: Array[int] = []
	## Unit name -> the units drawn towards it while it was the nearest wanted one.
	var _pull_of := {}
	var _asked_at := Vector2i(-1, -1)
	## Every unit drawn so far.
	var _drawn := 0
	var _wanted := false
	## The walk what is drawn joins, the director a row handed to her walk is owed to and the
	## siting it is sited by (`walked_by()`).
	var _walk: WalkEvents
	var _director: EventDirector
	var _siting: WalkSiting
	## Every row a unit drew with a place, so far.
	var rows: Array[EventPlan] = []
	## Every unit of the day, and each one's room before it drew, in small marbles (unit name ->
	## count).
	var _units: Array[PlacementUnit] = []
	var _room := {}

	func _init(the_draw: UnitDraw) -> void:
		draw = the_draw
		longest_chain = _longest_chain(draw.units())
		_units = draw.units().undrawn_within(Vector2.ZERO, INF)
		for unit in _units:
			var room := UnitRoom.of(unit)
			var count := 0
			while room.is_open():
				room.take(EventDef.StreetShare.A_LOCATION)
				count += 1
			_room[unit.name()] = count

	## **What the day's units placed, by share, and the marbles they drew**, every unit drawn:
	## `[sections, locations, marbles, empty]`.
	func marbles() -> Array[int]:
		var counts: Array[int] = [0, 0, 0, 0]
		for unit in _units:
			var room := int(_room[unit.name()])
			var spoken := 0
			for plan in unit.drawn():
				var share := plan.row().takes_of_a_street() \
						if unit.kind() == PlacementGround.Kind.STREET \
						else EventDef.StreetShare.A_LOCATION
				if share == EventDef.StreetShare.A_SECTION:
					counts[0] += 1
					spoken += 2
				else:
					counts[1] += 1
					spoken += 1
			var empty := room - spoken
			counts[2] += unit.drawn().size() + empty
			counts[3] += empty
		return counts

	## Takes the walk what is drawn joins, as `EventsAhead` has it: a placed row added to the
	## walk, a row handed to her walk added unplaced and owed to `director`, to site on her way
	## with `siting`.
	func walked_by(walk: WalkEvents, director: EventDirector,
			siting: WalkSiting) -> void:
		_walk = walk
		_director = director
		_siting = siting

	## What a draw placed joins the walk (`walked_by()`).
	func join(placed: Array[EventPlan]) -> void:
		for plan in placed:
			_walk.add(plan)
			if plan.is_placed():
				rows.append(plan)
			elif plan.row().is_handed_to_her_walk():
				_director.owe_on_her_way(plan, _siting)

	## Draws what her place at `at` (on `tile`) asks for. Answers what was placed.
	func near(at: Vector2, tile: Vector2i) -> Array[EventPlan]:
		var placed: Array[EventPlan] = []
		if tile == _asked_at and not _wanted:
			return placed
		_asked_at = tile
		var units := draw.units()
		var inside := units.undrawn_within(at, Tuning.EVENT_STREAM_RADIUS)
		if not inside.is_empty():
			for unit in inside:
				var pull := 0
				while not unit.is_drawn():
					placed.append_array(_one_towards(unit))
					pull += 1
				longest_pull = maxi(longest_pull, pull)
		else:
			var wanted := units.undrawn_within(at,
					Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_DRAW_AHEAD)
			if not wanted.is_empty():
				var nearest := wanted[0]
				placed.append_array(_one_towards(nearest))
				var pull := int(_pull_of.get(nearest.name(), 0)) + 1
				_pull_of[nearest.name()] = pull
				if nearest.is_drawn():
					longest_pull = maxi(longest_pull, pull)
		_wanted = not units.undrawn_within(at,
				Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_DRAW_AHEAD).is_empty()
		return placed

	## Draws every unit left, after the walk.
	func the_rest() -> Array[EventPlan]:
		var placed: Array[EventPlan] = []
		on_the_walk = _drawn
		for unit in draw.units().undrawn_within(Vector2.ZERO, INF):
			while not unit.is_drawn():
				placed.append_array(_one_towards(unit))
		after = _drawn - on_the_walk
		return placed

	func _one_towards(unit: PlacementUnit) -> Array[EventPlan]:
		var started := Time.get_ticks_usec()
		var placed := draw.draw_one_towards(unit)
		costs.append(Time.get_ticks_usec() - started)
		_drawn += 1
		return placed

	## The longest chain of touching units each ranked below the one before it, over the day's
	## units, none drawn yet.
	static func _longest_chain(units: DayUnits) -> int:
		var all := units.undrawn_within(Vector2.ZERO, INF)
		all.sort_custom(func(a: PlacementUnit, b: PlacementUnit) -> bool:
			return a.draws_before(b))
		var chain := {}
		var longest := 0
		for unit in all:
			var length := 1
			for other in units.touching(unit):
				if other.draws_before(unit):
					length = maxi(length, int(chain.get(other.name(), 1)) + 1)
			chain[unit.name()] = length
			longest = maxi(longest, length)
		return longest

## **One day of one city, planned as the game plans it** (`_Day.planned()`): what a walk and the
## same day drawn whole with no walk are each started from, the city made again each time, so a
## second plan of it is the first plan exactly.
class _Day extends RefCounted:
	var map: CityMap
	var tree: RouteTree
	var region_plan: RegionPlanner.RegionPlan
	var seals: Array[EventPlan] = []
	var doors := PackedVector2Array()
	var corridor: Corridor
	var dawn: DawnContext
	## When the dawn's own planning began, in microseconds, for the `WP` line.
	var planned_at := 0

	## Day `day` of the `i`th city: its closures, holds, region wall and seals first, the seals and
	## the wall's bodies handed in as standing, then its dawn, its units left undrawn.
	static func planned(day: int, i: int) -> _Day:
		var the_day := _Day.new()
		var map := CityGenerator.generate(BASE + i * STEP)
		# The run's mast sites, worked out once on the city as built, as the game does.
		var sites := MastSites.compute(map)
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var spec := DaySpec.for_day(day)
		# The day's own closures, holds, region wall and seals, planned as the game plans them
		# (`City.start_day()`, `DayPlanner._plan_a_day()`), so the seals and the wall's bodies
		# stand as the day's standing and hold their locations.
		var region_plan := RegionPlanner.plan_day(map, spec, tree)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("placement_rows closures:%d:%d" % [i, day])
		var closures := ClosurePlanner.plan_day(map, spec, closure_rng, tree, region_plan)
		map.close_streets(closures)
		map.clear_day_holds()
		for closure: RoadClosure in closures:
			map.hold_segment(closure.segment.key(), HeldStreets.Why.CLOSURE)
		for segment: StreetNetwork.Segment in region_plan.walls:
			map.hold_segment(segment.key(), HeldStreets.Why.WALL)
		for segment: StreetNetwork.Segment in region_plan.doors:
			map.hold_segment(segment.key(), HeldStreets.Why.DOOR)
		for segment: StreetNetwork.Segment in map.network.around_blocks(
				Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
			map.hold_segment(segment.key(), HeldStreets.Why.HOME)
		var boundary := {}
		for segment in region_plan.walls:
			boundary[segment.key()] = true
		for segment in region_plan.doors:
			boundary[segment.key()] = true
		for rect in region_plan.alley_walls:
			boundary[rect.position] = true
		for rect in region_plan.alley_doors:
			boundary[rect.position] = true
		var seal_rng := RandomNumberGenerator.new()
		seal_rng.seed = hash("placement_rows seals:%d:%d" % [i, day])
		var seals := SealPlanner.plan_day(map, spec, tree, seal_rng, boundary,
				map.held_streets())
		for seal in seals:
			seal.stand_as_a_seal()
		var doors := PackedVector2Array()
		for body in region_plan.door_bodies:
			doors.append(body.position)
		var standing: Array[EventPlan] = []
		standing.append_array(seals)
		standing.append_array(region_plan.wall_bodies)
		for body in region_plan.wall_bodies:
			body.stand_in_the_wall()
		var corridor := Corridor.of(tree)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
		var guarded := ResistanceSteps.guarded_row_on(day)
		var consumed: Array[String] = []
		the_day.planned_at = Time.get_ticks_usec()
		var dawn: DawnContext = GameDawn.of(spec, rng, map).masts(sites).spent(consumed) \
				.on(tree).doors(doors).standing(standing) \
				.roadblock(EventCatalogue.by_id(guarded) if guarded != "" else null) \
				.undrawn().planned()
		the_day.map = map
		the_day.tree = tree
		the_day.region_plan = region_plan
		the_day.seals = seals
		the_day.doors = doors
		the_day.corridor = corridor
		the_day.dawn = dawn
		return the_day

func run(t: TestRunner) -> void:
	for reach in REACHES:
		_walk_every_day(reach)
	t.check(true, "walk probe ran")

## Every day of `SEEDS` cities walked with the touching relation's `reach`: everything printed
## for the item's relation (none), the `WU` and `WQ` lines alone for a wider one.
func _walk_every_day(reach: float) -> void:
	var the_games := reach <= 0.0
	var all_cut_at_dawn := 0
	var all_cut_after_walk := 0
	var all_on_the_walk := 0
	var all_after := 0
	var all_pull := 0
	var all_chain := 0
	var all_costs: Array[int] = []
	var all_sitings := 0
	var all_in_undrawn := 0
	var all_in_empty := 0
	var all_nearest := INF
	var all_by_her_path: Array[int] = [0, 0, 0, 0, 0]
	var all_marbles: Array[int] = [0, 0, 0, 0]
	var all_both_closed: Array[int] = [0, 0, 0, 0, 0, 0]
	for day in range(1, 15):
		var by_view := {}
		var by_kind := {}
		# What the director hands out on her walk (`EventDirector.due()`), by row.
		var handed := {}
		var placed := 0
		# Where on her walk the capped rows are met: within the stream radius of her door at the
		# start, and in the second half of the walk out.
		var capped_met := 0
		var capped_at_the_door := 0
		var capped_late_out := 0
		# Route tiles cut off from home, after the dawn's plan and at the end of her walk.
		var cut_at_dawn := 0
		var cut_after_walk := 0
		# What her walk laid: how many beats, how many in a unit that had not drawn, how many on a
		# location a drawn unit left empty, and the smallest gap to a row a unit drew.
		var sitings := 0
		var in_undrawn := 0
		var in_empty := 0
		var nearest := INF
		# The units, and which drew by her path (`_drew_by_her_path()`).
		var by_her_path: Array[int] = [0, 0, 0, 0, 0]
		# What the units placed by share, the marbles they drew and the empty ones.
		var marbles: Array[int] = [0, 0, 0, 0]
		# What each of the day's rules refused, and the streets by view: counted, both closed.
		var refused := {}
		var both_closed: Array[int] = [0, 0, 0, 0, 0, 0]
		for i in SEEDS:
			var the_day := _Day.planned(day, i)
			var planned_from := the_day.planned_at
			var map := the_day.map
			var tree := the_day.tree
			var region_plan := the_day.region_plan
			var seals := the_day.seals
			var doors := the_day.doors
			var corridor := the_day.corridor
			var dawn := the_day.dawn
			if the_games:
				print("WP %d %d %d" % [day, i, Time.get_ticks_usec() - planned_from])
			var drawing := _Drawing.new(dawn.unit_draw() if the_games
					else _unit_draw_reaching(dawn, reach))
			var plans: Array[EventPlan] = dawn.events().placements()
			plans.append_array(seals)
			plans.append_array(region_plan.wall_bodies)
			var grid := ReachabilityGrid.build(map)
			var routes: Array[Vector2i] = []
			for y in map.size.y:
				for x in map.size.x:
					if corridor.carries_a_route(Vector2i(x, y)):
						routes.append(Vector2i(x, y))
			var reached_bare := grid.flood([map.home_tile()], map.closed_tiles)
			if the_games:
				cut_at_dawn += _report_cut_off(map, grid, routes, reached_bare, plans, day, i,
						"dawn")
			var walk := WalkEvents.new()
			# The walk carries the draw its units draw with, as a day's walk does, so a beat the
			# siting lays is rigged in a unit this walk draws.
			walk.take(plans, CalmAreas.of(map), doors, null, dawn.locations(), null,
					drawing.draw)
			# The walk's sitings are judged against the walk itself, as the game's are, and lay a
			# beat on the locations the units draw into: made by the game's maker, over a world
			# that holds this probe's city and a run of its own.
			var world := EventWorld.new()
			world.city_map = map
			world.run = RunState.new()
			world.use_plan_builder(GamePlanBuilder.over(map))
			var siting := SitingMaker.new(world, walk).make(day, tree, EventScheduler.row_ground(map))
			var director := EventDirector.new(map)
			var director_rng := RandomNumberGenerator.new()
			director_rng.seed = hash("walk_rows director:%d:%d" % [i, day])
			director.start_day(day, plans, director_rng, siting)
			drawing.walked_by(walk, director, siting)
			var sited := {}
			# The units a beat was laid in, moved off later or not, by name.
			var held_a_beat := {}
			var route := _longest_route(tree)
			if route.size() < 2:
				continue
			var path := route.duplicate()
			var back := route.duplicate()
			back.reverse()
			path.append_array(back)
			var at: Vector2 = path[0]
			var door: Vector2 = path[0]
			var out_length := 0.0
			for k in range(1, route.size()):
				out_length += (route[k] as Vector2).distance_to(route[k - 1])
			var walked := 0.0
			var counted := {}
			var siting_ticks: Array[int] = []
			var tick := 0
			drawing.join(drawing.near(at, map.world_to_tile(at)))
			for k in range(1, path.size()):
				var toward: Vector2 = path[k] - at
				while toward.length() > Tuning.WALK_SPEED * TICK:
					var heading := toward.normalized()
					var velocity := heading * Tuning.WALK_SPEED
					at += velocity * TICK
					walked += Tuning.WALK_SPEED * TICK
					tick += 1
					drawing.join(drawing.near(at, map.world_to_tile(at)))
					toward = path[k] - at
					if not the_games:
						continue
					var t1 := Time.get_ticks_usec()
					var due := director.due(TICK, at, velocity)
					if not due.is_empty():
						var handed_id := (due[0] as EventDef).id
						handed[handed_id] = int(handed.get(handed_id, 0)) + 1
					var moved := director.site_what_is_on_her_way(TICK, at, velocity)
					siting_ticks.append(Time.get_ticks_usec() - t1)
					for plan in moved:
						sited[plan] = true
						sitings += 1
						# The units draw before the director sites, so a unit still undrawn now
						# was undrawn when the beat was laid.
						var holding := _holding(drawing.draw.units(), plan)
						if holding:
							held_a_beat[holding.name()] = true
						if holding and not holding.is_drawn():
							in_undrawn += 1
						elif holding:
							in_empty += 1
					if tick % 10 == 0:
						for plan in walk.plans():
							if counted.has(plan) or not plan.is_placed() or plan.is_a_fixed_part():
								continue
							if plan.placed_at().distance_to(at) <= Tuning.EVENT_STREAM_RADIUS:
								counted[plan] = true
								if CAPPED.has(plan.row_id()):
									capped_met += 1
									if plan.placed_at().distance_to(door) \
											<= Tuning.EVENT_STREAM_RADIUS:
										capped_at_the_door += 1
									if walked > out_length * 0.5 and walked <= out_length:
										capped_late_out += 1
			drawing.join(drawing.the_rest())
			if the_games:
				var counted_marbles := drawing.marbles()
				for k in marbles.size():
					marbles[k] += counted_marbles[k]
			for plan: EventPlan in sited:
				if not plan.is_placed():
					continue
				for row in drawing.rows:
					if row != plan:
						nearest = minf(nearest, plan.gap_to(row))
			print("WU %d %d %d %d %d %d %d" % [reach, day, i, drawing.on_the_walk, drawing.after,
					drawing.longest_pull, drawing.longest_chain])
			print("WQ %d %d %d %s" % [reach, day, i, _quantiles(drawing.costs)])
			all_on_the_walk += drawing.on_the_walk
			all_after += drawing.after
			all_pull = maxi(all_pull, drawing.longest_pull)
			all_chain = maxi(all_chain, drawing.longest_chain)
			all_costs.append_array(drawing.costs)
			if not the_games:
				continue
			for plan: EventPlan in counted:
				placed += 1
				var tile := map.world_to_tile(plan.placed_at())
				var segment := map.network.segment_containing(tile)
				var view := 0
				if segment:
					view = corridor.view_of(segment)
				else:
					var d := corridor.depth(tile)
					view = 0 if d == 0 else (1 if d == 1 else 2)
				var kv := "%s %d" % [plan.row_id(), view]
				by_view[kv] = int(by_view.get(kv, 0)) + 1
				var kk := "%s %s" % [plan.row_id(), _kind_of(map, tile)]
				by_kind[kk] = int(by_kind.get(kk, 0)) + 1
			cut_after_walk += _report_cut_off(map, grid, routes, reached_bare, walk.plans(), day, i,
					"walk")
			var by_rule := dawn.rules().refusals()
			for name: String in by_rule:
				refused[name] = int(refused.get(name, 0)) + int(by_rule[name])
			_count_both_closed(map, corridor, walk.plans(), both_closed)
			var drew_by_her_path := _drew_by_her_path(drawing.draw.units(), map, day, i, held_a_beat)
			for k in by_her_path.size():
				by_her_path[k] += drew_by_her_path[k]
			print("WT %d %d siting %s" % [day, i, _costs(siting_ticks)])
		if not the_games:
			continue
		print("WD %d %d %d" % [day, SEEDS, placed])
		print("WC %d %d %d" % [day, cut_at_dawn, cut_after_walk])
		print("WZ %d %d %d %d %d" % [day, marbles[0], marbles[1], marbles[2], marbles[3]])
		for k in marbles.size():
			all_marbles[k] += marbles[k]
		all_cut_at_dawn += cut_at_dawn
		all_cut_after_walk += cut_after_walk
		print("WM %d %d %d %d" % [day, capped_met, capped_at_the_door, capped_late_out])
		for name: String in refused:
			print("WL %d %s %d" % [day, name, refused[name]])
		for view in 3:
			print("WB %d %d %d %d" % [day, view, both_closed[view * 2], both_closed[view * 2 + 1]])
			all_both_closed[view * 2] += both_closed[view * 2]
			all_both_closed[view * 2 + 1] += both_closed[view * 2 + 1]
		print("WS %d %d %d %d %.0f" % [day, sitings, in_undrawn, in_empty, nearest])
		all_sitings += sitings
		all_in_undrawn += in_undrawn
		all_in_empty += in_empty
		all_nearest = minf(all_nearest, nearest)
		print("WR %d %d %d %d %d %d" % [day, by_her_path[0], by_her_path[1], by_her_path[2],
				by_her_path[3], by_her_path[4]])
		for k in by_her_path.size():
			all_by_her_path[k] += by_her_path[k]
		for key: String in by_view:
			print("WV %d %s %d" % [day, key, by_view[key]])
		for key: String in by_kind:
			print("WK %d %s %d" % [day, key, by_kind[key]])
		for key: String in handed:
			print("WH %d %s %d" % [day, key, handed[key]])
	print("WU all %d %d %d %d %d" % [reach, all_on_the_walk, all_after, all_pull, all_chain])
	print("WQ all %d %s" % [reach, _quantiles(all_costs)])
	if the_games:
		print("WC all %d %d" % [all_cut_at_dawn, all_cut_after_walk])
		print("WZ all %d %d %d %d" % [all_marbles[0], all_marbles[1], all_marbles[2],
				all_marbles[3]])
		print("WS all %d %d %d %.0f" % [all_sitings, all_in_undrawn, all_in_empty, all_nearest])
		print("WR all %d %d %d %d %d" % [all_by_her_path[0], all_by_her_path[1],
				all_by_her_path[2], all_by_her_path[3], all_by_her_path[4]])
		for view in 3:
			print("WB all %d %d %d" % [view, all_both_closed[view * 2],
					all_both_closed[view * 2 + 1]])

## The unit of `units` `plan`, a beat her walk laid, is rigged in (`PlacementUnit.rigged()`), or null.
static func _holding(units: DayUnits, plan: EventPlan) -> PlacementUnit:
	for unit in units.all():
		if unit.rigged().has(plan):
			return unit
	return null

## **Which of `units`, the walked day's every one drawn, drew by her path**, as `[units, differ,
## beside-a-beat, carried, unexplained]`: against the same day of the same city planned again
## (`_Day.planned()`, the city made again) and drawn whole with no walk, the units that drew other
## rows or other places; of those, the ones a beat was laid in (`held_a_beat`, by name, moved off
## later or not) or touching one; of the rest, the ones touching a unit that differs, since a unit is
## judged among the draws of the touching units drawn before it; and those that are none of these.
static func _drew_by_her_path(units: DayUnits, map: CityMap, day: int, i: int,
		held_a_beat: Dictionary) -> Array[int]:
	var whole := _Day.planned(day, i)
	var whole_draw := whole.dawn.unit_draw()
	var drawn_whole := {}
	for unit in whole_draw.units().all():
		whole_draw.draw(unit)
		drawn_whole[unit.name()] = _what_it_drew(whole.map, unit)
	var beside := {}
	for unit in units.all():
		if unit.rigged().is_empty() and not held_a_beat.has(unit.name()):
			continue
		beside[unit.name()] = true
		for other in units.touching(unit):
			beside[other.name()] = true
	var differ := {}
	for unit in units.all():
		if _what_it_drew(map, unit) != str(drawn_whole.get(unit.name(), "")):
			differ[unit.name()] = unit
	var counts: Array[int] = [units.all().size(), differ.size(), 0, 0, 0]
	for name: String in differ:
		if beside.has(name):
			counts[2] += 1
			continue
		var carried := false
		for other in units.touching(differ[name] as PlacementUnit):
			carried = carried or differ.has(other.name())
		counts[3 if carried else 4] += 1
	return counts

## What `unit` drew, as its rows and the tiles they stand on, a row handed to her walk as `walk`.
static func _what_it_drew(map: CityMap, unit: PlacementUnit) -> String:
	var parts: Array[String] = []
	for plan in unit.drawn():
		parts.append("%s@%s" % [plan.row_id(), "walk" if plan.row().is_handed_to_her_walk()
				else str(map.world_to_tile(plan.placed_at()))])
	return ", ".join(parts)

## Adds, per view of `corridor` (`counts[view * 2]` the streets counted, `counts[view * 2 + 1]` those
## both closed), the streets of `map` with neither sidewalk walkable past the obstructing bodies of
## `plans`, each where its body stands (`EventPlan.body_at()`: a roadblock's band on the kerb
## beside its lane), leaving out a street a closure, a seal, the region wall or a roadblock closes by
## itself.
static func _count_both_closed(map: CityMap, corridor: Corridor, plans: Array[EventPlan],
		counts: Array[int]) -> void:
	var bodies: Array = []
	var fixed: Array = []
	for plan in plans:
		if not plan.obstructs():
			continue
		var at := plan.body_at()
		var body := Vector3(at.x, at.y, plan.blocking_radius())
		bodies.append(body)
		if plan.is_a_fixed_part() or plan.row().spans_the_street():
			fixed.append(body)
	for segment in map.street_segments():
		var bands := Corridor.sidewalk_bands(segment.tile_rect(), segment.horizontal)
		if _closes_both(map, bands, segment.horizontal, fixed):
			continue
		var view := corridor.view_of(segment)
		counts[view * 2] += 1
		if _closes_both(map, bands, segment.horizontal, bodies):
			counts[view * 2 + 1] += 1

## Whether `bodies` leave neither of `bands` walkable junction to junction.
static func _closes_both(map: CityMap, bands: Array[Rect2i], horizontal: bool,
		bodies: Array) -> bool:
	for band in bands:
		if not RouteSidewalkRule.closes_a_walked_sidewalk_band(map, band, horizontal, bodies):
			return false
	return true

## **The dawn's unit draw with the touching relation widened to `reach`**: the draw `DawnDraw.run()`
## prepares, its parts made as it makes them, over units grouped with `reach` (`DayUnits.of()`).
## The game passes no reach, so only this probe makes one; `dawn` was planned undrawn, so its
## locations have recorded no draw.
static func _unit_draw_reaching(dawn: DawnContext, reach: float) -> UnitDraw:
	var day := dawn.day()
	var map := dawn.map()
	var beside_the_routes := dawn.roadblock_row()
	var beside_id := beside_the_routes.id if beside_the_routes != null else ""
	var rows := {}
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, dawn.heat()):
		if def.is_drawn_by_units(day, beside_id):
			rows[def.id] = def.for_day(day)
	var ground := dawn.ground()
	var events := dawn.events()
	var judged := RuledLocationGround.new(day, dawn.day_seed(), map, events.standing(),
			dawn.corridor(),
			LocationFit.new(day, map, dawn.builder().without_todays_bodies(), ground),
			dawn.rules(), ground, false, DawnDraw.ROUTES_STAY_ON_THE_RUN)
	return UnitDraw.new(DayUnits.of(dawn.locations().all(), dawn.day_seed(), reach),
			MarbleDraw.new(dawn.locations(), rows, judged),
			UnitFills.new(rows, day, dawn.spec().share_of_walls_drawn(), ground.weights(),
					ground.is_a_wall_by_cost), events.placements())

## How many of `routes` home reached among the day's closures (`reached_bare`) that it no longer
## reaches among the bodies of `plans` and that no body's disc covers, each printed as a `WX` line
## with the kind of ground it is and the rows whose taking away alone gives it back.
static func _report_cut_off(map: CityMap, grid: ReachabilityGrid, routes: Array[Vector2i],
		reached_bare: Dictionary, plans: Array[EventPlan], day: int, seed_index: int,
		half: String) -> int:
	var bodies: Array[EventPlan] = []
	for plan in plans:
		if plan.obstructs():
			bodies.append(plan)
	var cut := _cut_off(map, grid, routes, reached_bare, bodies)
	if cut.is_empty():
		return 0
	var restores := {}
	for body in bodies:
		var others: Array[EventPlan] = bodies.duplicate()
		others.erase(body)
		var still := _cut_off(map, grid, cut, reached_bare, others)
		for tile in cut:
			if not still.has(tile):
				var names: Array = restores.get(tile, [])
				names.append("%s@%s" % [body.row_id(), map.world_to_tile(body.placed_at())])
				restores[tile] = names
	for tile in cut:
		var names: Array = restores.get(tile, ["jointly"])
		print("WX %d %d %s %s %s %s" % [day, seed_index, half, tile, _kind_of(map, tile),
				" ".join(names)])
	return cut.size()

## The tiles of `routes` home reached among the day's closures (`reached_bare`) that it does not
## reach among `bodies` and that no body's disc covers.
static func _cut_off(map: CityMap, grid: ReachabilityGrid, routes: Array[Vector2i],
		reached_bare: Dictionary, bodies: Array[EventPlan]) -> Array[Vector2i]:
	var blocked := EventScheduler.blocked_by(map, bodies)
	var reached := grid.flood([map.home_tile()], blocked)
	var cut: Array[Vector2i] = []
	for tile in routes:
		if not blocked.has(tile) and grid.reaches(tile, map.closed_tiles, reached_bare) \
				and not grid.reaches(tile, blocked, reached):
			cut.append(tile)
	return cut

## The day's longest route as the line she walks, out from the doorstep: a route is grown from the
## area to the doorstep, so the walk out is the route reversed.
static func _longest_route(tree: RouteTree) -> PackedVector2Array:
	var best: Array = []
	for branch in tree.branches():
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var points := PackedVector2Array()
	for k in best.size():
		points.append(tree.cell_centre(best[best.size() - 1 - k]))
	return points

## `ticks median p99 worst total` of `ticks`, in microseconds; zeros for none.
static func _costs(ticks: Array[int]) -> String:
	if ticks.is_empty():
		return "0 0 0 0 0"
	var sorted := ticks.duplicate()
	sorted.sort()
	var total := 0
	for value: int in sorted:
		total += value
	return "%d %d %d %d %d" % [sorted.size(), sorted[sorted.size() / 2],
			sorted[mini(sorted.size() - 1, int(sorted.size() * 0.99))], sorted[-1], total]

static func _kind_of(map: CityMap, tile: Vector2i) -> String:
	if CityMap.junction_at(tile) != Vector2i(-1, -1):
		return "junction"
	match map.tile_at(tile):
		GameEnums.TileType.ALLEY:
			return "alley"
		GameEnums.TileType.PARK, GameEnums.TileType.SQUARE:
			return "open"
		GameEnums.TileType.ROAD:
			return "carriageway"
		GameEnums.TileType.SIDEWALK:
			return "sidewalk"
	return "other"

## `median p99 worst` of `costs`, in microseconds; zeros for none.
static func _quantiles(costs: Array[int]) -> String:
	if costs.is_empty():
		return "0 0 0"
	var sorted := costs.duplicate()
	sorted.sort()
	return "%d %d %d" % [sorted[sorted.size() / 2],
			sorted[mini(sorted.size() - 1, int(sorted.size() * 0.99))], sorted[-1]]
