extends RefCounted
## Does a **zero-cost line** exist along every route the day plans? Printed rather than asserted.
## Not a suite: it lives under `tests/probes/`, where the runner never discovers it, and runs only
## by name:
##
##     tools/test.sh probes/m129_zero_cost_line.gd
##
## The question is the player's: *"a path through the city must never hit excitement — so all
## obstacles should be routable around by eg crossing to the other side of the street which in turn
## means the other side of the street must be open enough so we can walk on it unimpeded … also, the
## routing should only cross the street at intersections. in block crossings are possible in game
## but shouldn't be counted on by the routing algorithm."* Nothing in the game checks that today:
## every guarantee that exists is about *reaching* (`ClosurePlanner`'s two-distinct-calm-areas rule,
## `EventScheduler._ensure_the_city_is_still_walkable`, which drops obstructing bodies until a park
## is reachable again), and a route that reaches through three friction fields in a row is as legal
## as an empty one.
##
## So this measures the thing before a rule is written against it: for each planned day, for every
## route in that day's `RouteTree` from the doorstep to its calm area, is there a line of tiles that
##
## - stays **out of the disc every placed row charges for** (and out of any body's
##   `obstructs_radius`),
## - moves between the two pavements of a street **only at a junction**, never mid-block,
## - and treats the corridor's own park-and-alley cuts as ground like any other.
##
## **The day is planned the way the game plans it**, so the measurement is of what is really placed:
## `RouteTree.for_day` grows the corridor, `RegionPlanner.plan_day` decides today's wall and doors,
## `ClosurePlanner.plan_day` closes streets off the tree, `SealPlanner.plan_day` seals every street
## off it, `EventScheduler.build_day` fills the city, and the wall's and doors' own bodies are
## appended — exactly `EventManager.start_day`'s assembly, in its order. Nothing is simulated in
## time: every row measured here has its geometry at dawn.
##
## # Where the design is silent, the smallest reading, and every one of them is listed here
##
## - **The ground a line may use is the route's own streets, both pavements, plus the junction at
##   each end of each of them.** A street is walkable frontage to frontage and *the answer to a van
##   is the other side of the street*, so the far pavement is in; the junctions at both ends of an
##   on-route street are in because crossing is only legal at one, and checkbox two of the milestone
##   states the far pavement's reachability as *"an intersection crossing at each end"*. Nothing
##   beyond those junctions is in: a line that wandered off the route would be measuring some other
##   route.
## - **A route cell that is on no street contributes its own four tiles** — a park cut, an alley, a
##   square. There is no "other side" of an alley, so the line gets the ground the corridor actually
##   took and no more.
## - **Mid-block carriageway tiles are not ground.** That is the *"in-block crossings … shouldn't be
##   counted on"* half, stated as geometry: inside a street's own rect the two road tiles are out,
##   and a junction box is in whole, which is exactly where a zebra or a signalled line stands. **A
##   precinct is exempt** — it is paved frontage to frontage with no carriageway at all
##   (`CityMap.is_driveable`), so there is nothing there to cross.
## - **Both ends are exempt from being charged for their own doorway**, the same exemption the
##   closure invariant already makes: the line starts anywhere in `CityMap.home_rect` (with the home
##   street, which is never closed and never sealed, as ground) and arrives the moment it reaches
##   any calm tile of the area's own rect.
## - **A row blocks where it costs or where it stands**, and *where it costs* is the disc inside
##   which it out-emits `Tuning.EXCITEMENT_DECAY_WALKING` rather than its whole `outer_radius`:
##   past that crossing a walk through the field nets the meter down, which is ground taken without
##   planning around it — *"the influence at a junction is low enough that it can be taken without
##   having to worry or plan around it"*, PLAYTEST-76. A lethal row keeps its whole radius, a body
##   its `obstructs_radius`, and the larger applies where both do. A row that neither charges nor
##   obstructs — the `playground` ambient, at intensity 0 — is not something a line has to avoid and
##   is skipped. `EventScheduler._line_reach_of()` is the one place that arithmetic lives, and this
##   probe asks it rather than keeping a second copy: the placement rules refuse what this measures,
##   so a probe reading a different disc could not tell whether they had worked.
## - **A mast is excluded**: planted once by `MastSites`, off the corridor-aware placement this
##   guarantee is stated over — see `EventScheduler._a_line_has_to_avoid()`'s own doc.
## - **Rows with no tile are excluded**: `AHEAD_OF_PLAYER` and `TOWARD_PLAYER` queue rows are sited
##   by `EventDirector` out of where the player turns out to walk, so they have no position at plan
##   time (`Planned.is_placed()` is false) and no route can be measured against them. They are
##   outside this guarantee by construction, and the milestone says so.
## - **The top of the beat is the full disc.** A pulse is an intensity envelope
##   (`intensity × (0.25 + 0.75 × pulse(t))`, `docs/EVENTS.md`) and moves no radius, so the top of a
##   pulsing row's beat is what its catalogued numbers give, which is what is used.
## - **A row's field is read as a plain disc**, not the forward-stretched ellipse
##   `EventDef.field_reach()` gives a moving one. The milestone's own wording is a radius; the two
##   differ only for the handful of mobile rows and only ahead of them.
## - **A pacing row is passed by timing, not routed around.** The primary reading is the
##   **intersection** over its beat — only the ground it never leaves free counts as blocked, so a
##   line free at *some* phase of the loop can simply wait for it (`Reading.BEAT_OPENING`, *"time
##   pass -- don't route around them"*, PLAYTEST-71). The **union** over the beat — the ground the
##   yeller ever denies — is printed beside it for comparison (`Reading.BEAT_UNION`). The failing
##   shapes are classified under the primary reading.
## - **A mobile row that does not pace is never a block.** She can cross the street, wait for it to
##   pass and cross back without ever standing in its field, so it is left out of every reading
##   rather than read at its dawn position or over its whole route (PLAYTEST-71, *"the player can
##   cross the street, wait, then come back without ever getting excited by it"*).
## - **A pursuer (`EventDef.pursues`) is never a block.** It follows her rather than sitting on a
##   tile and pays the telegraph contract instead of the placement rules'
##   (`EventScheduler._a_line_has_to_avoid()`'s own doc: *"a pursuer follows her rather than
##   sitting on a tile, and pays the telegraph contract instead"*), so `alley_robbery` and
##   `charging_dog` are left out here the same way a door is — no placement rule ever refuses
##   ground on their account, so a line reading their dawn position as something to route around
##   was blaming rows the rules were never asked about.
## - **A region door is never a block.** It costs by design (PLAYTEST-71, *"it costs by design"*),
##   so `checkpoint_hut` and `checkpoint_gate` are left out of every reading; the region wall's own
##   body is not a door and still counts.
## - **`pigeon_flock` is scenery, not a block.** A row with `EventDef.scenery` set is left out of
##   every reading the same way a door is (PLAYTEST-71, *"flocks are basically free already --
##   don't count it as block"*), matching `EventScheduler._role_for`, where `scenery` answers
##   `NONE` before the wall/friction cost test ever runs.
##
## # What a broken route is reported as
##
## **Every cut, not only the first.** A route the line cannot walk is flooded, the rows standing
## where it stopped are taken out, and it is flooded again, up to `_CUTS_CAP` times — so the report
## carries both *what a walk out of the door actually runs into first* and *every stretch that
## would have to be answered*, which are different questions and have very different answers.
##
## **The shape of a cut is read off the barrier, not off what has to be removed to open it.** With
## a van on one pavement and a café on the other, taking either one away opens the street — so the
## smallest-removal answer calls each of them the whole cause and never finds the pair the rule is
## about. `_closes_the_street` asks the other question instead: do these rows, by themselves, leave
## no walk from one end of this street to the other? One row first, then a pair, then the lot.
##
## # Sizing
##
## `SEEDS` × one day per act. Every day is a whole city's planning — a tree, a region plan,
## closures, seals and a full `EventScheduler.build_day` — and the measurement itself is a flood
## fill per route per reading, so the cost is the planning. Six seeds is enough for the shapes to
## repeat and for a bad seed not to be the whole finding, and it runs in about a minute; the line
## at the end of the report says what it actually cost.

const SEEDS := 6
const BASE_SEED := 129129
## One day in each act (`Tuning.ACT_START_DAYS` is `[1, 4, 8, 12]`). Day 1 because the guarantee has
## to hold on the emptiest day too, and 9 and 13 because the region wall and its doors only exist
## from day 7.
const DAYS: Array[int] = [1, 5, 9, 13]

## Spacing between samples along a row's own route, in px. Half a tile: fine enough that a swept
## beat has no gaps in it at any radius in the catalogue.
const BEAT_SAMPLE_PX := 16.0

## How a row that moves is read, and which rows are read at all. See the class doc.
enum Reading {
	## Pacing rows over the intersection of their beat — only the ground the beat never leaves
	## free counts as blocked, since a pacing row is passed by timing rather than routed around.
	## The primary reading.
	BEAT_OPENING,
	## Pacing rows over the union of their beat — the ground the yeller ever denies, so the line
	## is free whenever she happens to arrive. Printed beside the primary reading for comparison.
	BEAT_UNION,
	## `BEAT_OPENING` restricted to the day's own catalogue rows: no seals, no region wall body.
	## What is left is the friction the corridor was given on purpose, and the spill from the rows
	## placed off it.
	CATALOGUE_ONLY,
}

## Which pass of the morning put a row down. The line does not care, but the report does: a seal
## stands off the tree by construction and only ever spills onto it.
enum Source { CATALOGUE, SEAL, REGION }

## The shapes a broken line is sorted into. The first three are the ones M129 names.
enum Shape {
	BODY_AND_FAR_SIDE,
	TWO_FIELDS,
	PACING,
	SINGLE_ROW_SPANS,
	MANY_ROWS,
	JUNCTION_TAKEN,
	DOORSTEP,
	NOT_A_BAND,
	MID_BLOCK_ONLY,
	GROUND,
	OTHER,
}

const SHAPE_NAMES := {
	Shape.BODY_AND_FAR_SIDE: "a body on one pavement, the far pavement also taken",
	Shape.TWO_FIELDS: "two fields on facing pavements",
	Shape.PACING: "a pacing row whose beat never leaves an opening",
	Shape.SINGLE_ROW_SPANS: "one row covering the street's whole width by itself",
	Shape.MANY_ROWS: "three or more rows covering the width between them",
	Shape.JUNCTION_TAKEN: "the junction itself is taken",
	Shape.DOORSTEP: "the doorstep itself is inside a field",
	Shape.NOT_A_BAND: "the cut is not a straight band across one street",
	Shape.MID_BLOCK_ONLY: "the corridor's own ground only connects across a carriageway mid-block",
	Shape.GROUND: "the route's own ground does not connect at all",
	Shape.OTHER: "other",
}

## One row of the day's plan, reduced to what a line has to keep out of.
class Row extends RefCounted:
	var id := ""
	var radius := 0.0
	var position := Vector2.ZERO
	## Points along its own route, or the one place it stands.
	var beat := PackedVector2Array()
	var paces := false
	var emits := false
	var obstructs := false
	var source := Source.CATALOGUE
	## The tiles it denies under the primary reading, as flat indices. See `_blocked_counts`.
	var tiles := PackedInt32Array()

## One route's verdict, kept so the summary and the examples are read off the same pass.
class Verdict extends RefCounted:
	var shape := Shape.OTHER
	var detail := ""
	## Every row that stands in one of this route's cuts, by id.
	var blamed: Array[String] = []
	## How many separate stretches have to be cleared before a line exists.
	var cuts := 0
	## The shape of each of them, in the order the line meets them. `shape` above is the first.
	var shapes: Array[int] = []

func run(t) -> void:
	_measure()
	t.check(true, "m129 zero-cost-line probe ran")

# ------------------------------------------------------------------ the measurement ---

func _measure() -> void:
	var started := Time.get_ticks_msec()
	print("\n== M129: the zero-cost line, %d seeds x one day per act %s ==" % [SEEDS, DAYS])

	var readings := [Reading.BEAT_OPENING, Reading.BEAT_UNION, Reading.CATALOGUE_ONLY]
	# reading -> act -> [clear, total]
	var tally := {}
	for reading in readings:
		tally[reading] = {}
		for act in [1, 2, 3, 4]:
			tally[reading][act] = [0, 0]
	# The first cut of each broken route, and every cut of every broken route: the first says what
	# a walk actually runs into, the second what a rule would have to cover.
	var shapes := {}
	var cut_shapes := {}
	var examples := {}
	for shape in SHAPE_NAMES:
		shapes[shape] = 0
		cut_shapes[shape] = 0
		examples[shape] = []
	## Row id -> how many routes it stands in a cut of.
	var blame := {}
	var cuts_total := 0
	var cuts_worst := 0
	var broken := 0

	# The mid-block finding, which is about the grower rather than about the line.
	var routes_with_road_cells := 0
	var mid_block_crossings := 0
	var crossings_by_kind := {GameEnums.StreetKind.ORDINARY: 0, GameEnums.StreetKind.MAIN: 0,
			GameEnums.StreetKind.PEDESTRIAN: 0}
	var routes_on_the_spine := 0
	var days_measured := 0
	var rows_per_day := 0

	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 97)
		for day in DAYS:
			var act := Tuning.act_for_day(day)
			var tree := _plan_the_day(map, day)
			var plans := _place_the_day(map, day, tree)
			var rows := _rows_of(plans)
			days_measured += 1
			rows_per_day += rows.size()

			# The primary reading first, because it is the one whose per-row tile lists the
			# diagnosis takes apart again.
			var counts := _blocked_counts(map, rows, Reading.BEAT_OPENING)
			var owners := _owners_of(map, rows)
			var denied := {Reading.BEAT_OPENING: counts}
			for reading in readings:
				if reading != Reading.BEAT_OPENING:
					denied[reading] = _blocked_counts(map, rows, reading)

			for branch: RouteTree.Branch in tree.branches:
				var area_rect := ClosurePlanner.calm_area_rect(map, branch.area)
				for leg in branch.routes.size():
					var route: Array = branch.routes[leg]
					if route.is_empty():
						continue
					var ground := _allowed_mask(map, route, area_rect, false)
					for reading in readings:
						var clear := _line_exists(map, ground, denied[reading], area_rect)
						var per_act: Array = tally[reading][act]
						per_act[1] += 1
						if clear:
							per_act[0] += 1
					if not _line_exists(map, ground, counts, area_rect):
						broken += 1
						var verdict := _diagnose(map, route, area_rect, ground, counts, owners)
						shapes[verdict.shape] += 1
						for shape in verdict.shapes:
							cut_shapes[shape] += 1
						cuts_total += verdict.cuts
						cuts_worst = maxi(cuts_worst, verdict.cuts)
						for id in verdict.blamed:
							blame[id] = int(blame.get(id, 0)) + 1
						var kept: Array = examples[verdict.shape]
						if kept.size() < 3:
							kept.append("seed %d day %d area %s route %d: %s"
									% [map.seed_used, day, branch.area, leg, verdict.detail])

					var road_cells := _road_cells_of(map, route)
					if road_cells > 0:
						routes_with_road_cells += 1
					if _touches_the_spine(map, route):
						routes_on_the_spine += 1
					for kind in _mid_block_crossings_of(map, route):
						mid_block_crossings += 1
						crossings_by_kind[kind] = int(crossings_by_kind[kind]) + 1

	_report(tally, shapes, cut_shapes, examples, blame, broken, cuts_total, cuts_worst,
			routes_with_road_cells, routes_on_the_spine, mid_block_crossings, crossings_by_kind,
			days_measured, rows_per_day, Time.get_ticks_msec() - started)

# ----------------------------------------------------------------- planning a day ---

## The corridor, the regions and the closures, in `City._close_streets`'s own order — the tree
## first, because everything else is placed off it.
func _plan_the_day(map: CityMap, day: int) -> RouteTree:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)
	return RouteTree.for_day(map, day)

## Everything the day stands on the streets, assembled exactly as `EventManager.start_day` does:
## the region's wall and doors, the closures, the held ground, the seals, the catalogue's own fill,
## and the wall's and doors' bodies.
func _place_the_day(map: CityMap, day: int, tree: RouteTree) -> Array[EventScheduler.Planned]:
	var region_plan := RegionPlanner.plan_day(map, day, tree)
	var closures := ClosurePlanner.plan_day(map, day, _rng(map, day, "closures"), tree, region_plan)
	map.close_streets(closures)

	map.clear_day_holds()
	for closure in closures:
		map.hold_segment(closure.segment.key())
	for segment in region_plan.walls:
		map.hold_segment(segment.key())
	for segment in region_plan.doors:
		map.hold_segment(segment.key())
	for segment in StreetNetwork.around_blocks(Rect2i(map.home_block, Vector2i.ONE)):
		map.hold_segment(segment.key())

	var boundary := {}
	for segment in region_plan.walls:
		boundary[segment.key()] = true
	for segment in region_plan.doors:
		boundary[segment.key()] = true
	for rect in region_plan.alley_walls:
		boundary[rect.position] = true
	for rect in region_plan.alley_doors:
		boundary[rect.position] = true

	var seals := SealPlanner.plan_day(map, day, tree, _rng(map, day, "seals"), boundary,
			map.held_segments)
	var no_one_shots: Array[String] = []
	var no_scars: Array[Dictionary] = []
	var no_calm: Array[Vector2i] = []
	# `EventManager.start_day`'s own `doors` and `standing`: where today's door structure stands
	# (kept clear of by `_clear_of_the_doors`, a pre-existing rule this probe simply never
	# exercised before) and what the seals and the region wall's own bodies already stand as
	# (`standing`, newly threaded into the three placement rules — `EventScheduler._best_of`'s own
	# doc). Missing both was itself a probe/rule disagreement — see `DECISIONS.md`, M129, "which
	# placements the three rules never see" — and each moves the headline on its own: isolated
	# against `main`'s own scheduler (`standing` accepted but not yet asked of the three rules),
	# `doors` alone accounts for most of the gain this measurement shows and `standing` alone for
	# a small remainder; the `standing`-in-the-three-rules fix this branch adds is a further, on
	# its own smaller, gain on top of both — see `tests/test_seals.gd`,
	# `_test_the_catalogue_sees_a_seal_at_a_route_junction`; the PR description carries the full
	# isolation table.
	var doors := PackedVector2Array()
	for body in region_plan.door_bodies:
		doors.append(body.position)
	var standing: Array[EventScheduler.Planned] = []
	standing.append_array(seals)
	standing.append_array(region_plan.wall_bodies)
	var plans := EventScheduler.build_day(day, _rng(map, day, "events"), map, no_one_shots,
			no_scars, no_calm, tree, 0, doors, [], standing)
	# Which pass placed a row is not on the plan, so it is recorded as the lists are joined — the
	# one place that still knows. See `Source`.
	_sources.clear()
	for plan in plans:
		_sources[plan.get_instance_id()] = Source.CATALOGUE
	for plan in seals:
		_sources[plan.get_instance_id()] = Source.SEAL
	for plan in region_plan.wall_bodies:
		_sources[plan.get_instance_id()] = Source.REGION
	for plan in region_plan.door_bodies:
		_sources[plan.get_instance_id()] = Source.REGION
	plans.append_array(seals)
	plans.append_array(region_plan.wall_bodies)
	plans.append_array(region_plan.door_bodies)
	return plans

## Plan instance id -> `Source`, for the day being measured. See `_place_the_day`.
var _sources := {}

func _rng(map: CityMap, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("m129:%s:%d:%d" % [stream, map.seed_used, day])
	return rng

# ------------------------------------------------------------------------- the rows ---

## A row is skipped rather than read where PLAYTEST-71 says it is never a block: a mast
## (`plan.mast_id != ""`) is planted once, off the corridor-aware placement this guarantee is
## stated over — see `EventScheduler._a_line_has_to_avoid()`'s own doc; `scenery` rows
## (`pigeon_flock`) are exempt the way `EventScheduler._role_for` exempts them from the
## wall/friction cost test; a region door (`checkpoint_hut`, `checkpoint_gate`) costs by design;
## a pursuer (`alley_robbery`, `charging_dog`, `door_guard`) follows her rather than sitting on a
## tile; and a mobile row that does not pace is passed by crossing, waiting and crossing back,
## never by routing around it.
func _rows_of(plans: Array[EventScheduler.Planned]) -> Array:
	var rows: Array = []
	for plan: EventScheduler.Planned in plans:
		if not plan.is_placed() or plan.mast_id != "":
			continue
		var def := plan.def
		if def.scenery or def.pursues or def.id.begins_with("checkpoint") \
				or (def.mobile and not def.paces):
			continue
		var emits := def.intensity > 0.0
		var radius := EventScheduler._line_reach_of(def)
		if radius <= 0.0:
			continue
		var row := Row.new()
		row.id = def.id
		row.radius = radius
		row.position = plan.position
		row.paces = def.paces
		row.emits = emits
		row.obstructs = def.obstructs_radius > 0.0
		row.source = int(_sources.get(plan.get_instance_id(), Source.CATALOGUE))
		row.beat = _samples_along(plan)
		rows.append(row)
	return rows

## The points a moving row occupies over its own route, at `BEAT_SAMPLE_PX` spacing. One point for
## anything that stands still.
func _samples_along(plan: EventScheduler.Planned) -> PackedVector2Array:
	var points := PackedVector2Array([plan.position])
	if plan.path.size() < 2:
		return points
	points = PackedVector2Array()
	for i in range(1, plan.path.size()):
		var from := plan.path[i - 1]
		var to := plan.path[i]
		var span := from.distance_to(to)
		var steps := maxi(1, ceili(span / BEAT_SAMPLE_PX))
		for step in steps:
			points.append(from.lerp(to, float(step) / float(steps)))
	points.append(plan.path[plan.path.size() - 1])
	return points

## Every tile a line may not stand on, under one reading: today's closures, plus each row's own
## disc wherever that reading says it is.
##
## **How many rows cover a tile, not merely whether one does.** The diagnosis has to be able to
## take one row away and ask whether the line opens, and subtracting its disc from a flat mask
## would take its neighbours' overlapping ground with it — which on a street where three fields
## overlap reports one row as the whole cause of a cut that needed two.
func _blocked_counts(map: CityMap, rows: Array, reading: int) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(map.size.x * map.size.y)
	counts.fill(0)
	# Closures are counted in and never taken out again: a barrier is not a row anything can lift.
	for tile: Vector2i in map.closed_tiles:
		if map.in_bounds(tile):
			counts[tile.y * map.size.x + tile.x] += 1
	for row: Row in rows:
		if reading == Reading.CATALOGUE_ONLY and row.source != Source.CATALOGUE:
			continue
		var tiles := _row_tiles(map, row, reading)
		if reading == Reading.BEAT_OPENING:
			row.tiles = tiles
		for index in tiles:
			counts[index] += 1
	return counts

## Tile -> the rows whose own ground covers it, under the primary reading. Built once a day, so
## that asking *what is standing in this cut* is a lookup rather than a sweep over every row in
## the city — which is the difference between a probe that runs in minutes and one that does not.
func _owners_of(map: CityMap, rows: Array) -> Array:
	var owners: Array = []
	owners.resize(map.size.x * map.size.y)
	for row: Row in rows:
		for index in row.tiles:
			var here: Variant = owners[index]
			if here == null:
				owners[index] = [row]
			else:
				(here as Array).append(row)
	return owners

## The tiles one row denies under one reading, each named once. Every row still here paces or
## stands still — a mobile row that does not pace never reaches `_rows_of`'s result at all.
func _row_tiles(map: CityMap, row: Row, reading: int) -> PackedInt32Array:
	if _scratch.size() != map.size.x * map.size.y:
		_scratch.resize(map.size.x * map.size.y)
		_scratch.fill(0)
	var found := PackedInt32Array()
	var opening := reading == Reading.BEAT_OPENING or reading == Reading.CATALOGUE_ONLY
	if row.paces and opening:
		_collect_always(map, row, found)
	elif row.paces:
		for point in row.beat:
			_collect_disc(map, point, row.radius, found)
	else:
		_collect_disc(map, row.position, row.radius, found)
	for index in found:
		_scratch[index] = 0
	return found

## A scratch tile map, so a row's own overlapping samples are collected once. Left zeroed by every
## caller of `_row_tiles`.
var _scratch := PackedByteArray()

func _collect_disc(map: CityMap, at: Vector2, radius: float, found: PackedInt32Array) -> void:
	var reach := ceili(radius / float(Tuning.TILE_SIZE))
	var centre := map.world_to_tile(at)
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if not map.in_bounds(tile):
				continue
			var index := tile.y * map.size.x + tile.x
			if _scratch[index] == 1:
				continue
			if map.tile_to_world(tile).distance_to(at) <= radius:
				_scratch[index] = 1
				found.append(index)

## The ground a pacing row denies at **every** phase of its beat — the intersection rather than the
## union, which is the "there is an opening at some phase" reading.
func _collect_always(map: CityMap, row: Row, found: PackedInt32Array) -> void:
	var reach := ceili(row.radius / float(Tuning.TILE_SIZE))
	var centre := map.world_to_tile(row.beat[0])
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if not map.in_bounds(tile):
				continue
			var at := map.tile_to_world(tile)
			var always := true
			for point in row.beat:
				if at.distance_to(point) > row.radius:
					always = false
					break
			if always:
				var index := tile.y * map.size.x + tile.x
				_scratch[index] = 1
				found.append(index)

# -------------------------------------------------------------- the ground of a route ---

## Every tile a line along this route may stand on. See the class doc for what is in and what is
## not; `with_carriageway` true is the relaxation the diagnosis uses to tell a mid-block crossing
## apart from a blocked one.
func _allowed_mask(map: CityMap, route: Array, area_rect: Rect2i,
		with_carriageway: bool) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(map.size.x * map.size.y)
	mask.fill(0)
	for cell: Vector2i in route:
		var origin: Vector2i = cell * ReachabilityGrid.CELL
		var segment := StreetNetwork.segment_containing(origin)
		if segment:
			_add_street(mask, map, segment, with_carriageway)
			continue
		if CityMap.junction_at(origin) != Vector2i(-1, -1):
			_add_junction(mask, map, CityMap.junction_at(origin))
			continue
		for slot in ReachabilityGrid.CELL * ReachabilityGrid.CELL:
			_add_tile(mask, map, origin + Vector2i(slot % ReachabilityGrid.CELL,
					slot / ReachabilityGrid.CELL))

	# Both ends, exempt from being charged for their own doorway.
	var home := ClosurePlanner.home_street(map)
	if home:
		_add_street(mask, map, home, with_carriageway)
	for y in range(map.home_rect.position.y, map.home_rect.end.y):
		for x in range(map.home_rect.position.x, map.home_rect.end.x):
			_add_tile(mask, map, Vector2i(x, y))
	for y in range(area_rect.position.y, area_rect.end.y):
		for x in range(area_rect.position.x, area_rect.end.x):
			var tile := Vector2i(x, y)
			if Tile.is_calm(map.tile_at(tile)):
				_add_tile(mask, map, tile)
	return mask

## One street, both pavements, plus the junction at each of its ends — the only places the line may
## change pavement. The carriageway between the two kerbs is left out unless the street is a
## precinct, which has none.
func _add_street(mask: PackedByteArray, map: CityMap, segment: StreetNetwork.Segment,
		with_carriageway: bool) -> void:
	var rect := segment.tile_rect()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if not with_carriageway and _is_a_carriageway_tile(map, tile, segment.horizontal):
				continue
			_add_tile(mask, map, tile)
	_add_junction(mask, map, segment.a)
	_add_junction(mask, map, segment.b)

## Whether a tile between two junctions is carriageway a line may not cross there.
##
## **The tile's own type decides, not its offset across the corridor.** A four-block calm zone is
## painted over the streets between its blocks, so those tiles sit at a road offset and are grass
## somebody walks on — *"an absorbed street is calm ground, not a closure"*. A precinct is paving
## frontage to frontage with no carriageway at all (`CityMap.is_driveable`), and its middle tiles
## are not `ROAD` either, so the same test covers it without naming it.
func _is_a_carriageway_tile(map: CityMap, tile: Vector2i, horizontal: bool) -> bool:
	if not CityMap.is_road_offset(CityMap.corridor_offset(tile.y if horizontal else tile.x)):
		return false
	var type := map.tile_at(tile)
	return type == GameEnums.TileType.ROAD or type == GameEnums.TileType.CROSSING

func _add_junction(mask: PackedByteArray, map: CityMap, junction: Vector2i) -> void:
	var origin := junction * CityMap.period()
	for y in range(origin.y, origin.y + Tuning.STREET_WIDTH):
		for x in range(origin.x, origin.x + Tuning.STREET_WIDTH):
			_add_tile(mask, map, Vector2i(x, y))

func _add_tile(mask: PackedByteArray, map: CityMap, tile: Vector2i) -> void:
	if map.in_bounds(tile) and map.is_walkable(tile):
		mask[tile.y * map.size.x + tile.x] = 1

# ---------------------------------------------------------------------- the flood fill ---

## Every tile of `ground` a line reaches from the doorstep without entering `blocked`.
##
## The line starts anywhere on the home's own tiles **or on the street they open onto** — the
## street a closure may never close and a seal may never stand on, because the home is a notch with
## one exit. `CityMap.doorstep_world_position()` is the same reading: *"the pavement outside the
## front door, not the doorway itself"*.
func _reach_from_home(map: CityMap, ground: PackedByteArray,
		blocked: PackedInt32Array) -> PackedByteArray:
	var reached := PackedByteArray()
	reached.resize(map.size.x * map.size.y)
	reached.fill(0)
	var queue: Array[Vector2i] = []
	for tile in _home_tiles(map):
		var index := tile.y * map.size.x + tile.x
		if ground[index] == 1 and blocked[index] <= 0 and reached[index] == 0:
			reached[index] = 1
			queue.append(tile)
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if not map.in_bounds(next):
				continue
			var index := next.y * map.size.x + next.x
			if reached[index] == 1 or ground[index] == 0 or blocked[index] > 0:
				continue
			reached[index] = 1
			queue.append(next)
	return reached

## The doorstep, as the tiles a line may start on: the home notch and the street outside it.
func _home_tiles(map: CityMap) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(map.home_rect.position.y, map.home_rect.end.y):
		for x in range(map.home_rect.position.x, map.home_rect.end.x):
			found.append(Vector2i(x, y))
	var home := ClosurePlanner.home_street(map)
	if home:
		var rect := home.tile_rect()
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				found.append(Vector2i(x, y))
	return found

func _line_exists(map: CityMap, ground: PackedByteArray, blocked: PackedInt32Array,
		area_rect: Rect2i) -> bool:
	return _arrives(map, _reach_from_home(map, ground, blocked), area_rect)

func _arrives(map: CityMap, reached: PackedByteArray, area_rect: Rect2i) -> bool:
	for y in range(area_rect.position.y, area_rect.end.y):
		for x in range(area_rect.position.x, area_rect.end.x):
			var tile := Vector2i(x, y)
			if not map.in_bounds(tile) or not Tile.is_calm(map.tile_at(tile)):
				continue
			if reached[tile.y * map.size.x + tile.x] == 1:
				return true
	return false

# ------------------------------------------------------------------- what broke it ---

## Which row and which stretch broke the line, sorted into the shapes M129 names.
##
## The order is deliberate: a route that only needs the carriageway rule relaxed is a fact about
## the **grower** rather than about a row, and a route that does not connect even with nothing
## placed is a fact about the ground, so both are settled before any row is blamed.
func _diagnose(map: CityMap, route: Array, area_rect: Rect2i, ground: PackedByteArray,
		counts: PackedInt32Array, owners: Array) -> Verdict:
	var verdict := Verdict.new()

	# What the ground alone does, before a single row is blamed for it.
	var bare := PackedInt32Array()
	bare.resize(map.size.x * map.size.y)
	bare.fill(0)
	for tile: Vector2i in map.closed_tiles:
		if map.in_bounds(tile):
			bare[tile.y * map.size.x + tile.x] = 1
	var relaxed := _allowed_mask(map, route, area_rect, true)
	if not _line_exists(map, relaxed, bare, area_rect):
		verdict.shape = Shape.GROUND
		verdict.detail = "no line even with every row removed and the carriageway allowed"
		return verdict
	if not _line_exists(map, ground, bare, area_rect):
		verdict.shape = Shape.MID_BLOCK_ONLY
		verdict.detail = "an empty city still needs one, at %s" % _road_stretches_of(map, route)
		return verdict

	# **Every cut is classified, not only the first.** A route that is blocked in six places is
	# six findings; reporting the first one and stopping would say the corridor's first junction
	# is the whole problem, which is a fact about where the walk starts rather than about what a
	# rule would have to cover.
	var here := _ground_tiles(map, ground)
	var still := counts.duplicate()
	# A row already taken out still covers the tiles it used to, so it comes back as a culprit of
	# the next cut along; taking it out twice would drive the count below zero and open ground
	# nothing ever cleared.
	var gone := {}
	while verdict.cuts < _CUTS_CAP:
		var reached := _reach_from_home(map, ground, still)
		if _arrives(map, reached, area_rect):
			break
		var frontier := _frontier(map, here, still, reached)
		var culprits: Array = []
		for row: Row in _rows_covering(owners, frontier, map.size.x):
			if not gone.has(row.get_instance_id()):
				culprits.append(row)
		var cut := _shape_of_a_cut(map, frontier, culprits, owners)
		verdict.cuts += 1
		verdict.shapes.append(cut.shape)
		if verdict.cuts == 1:
			verdict.shape = cut.shape
			verdict.detail = cut.detail
		if culprits.is_empty():
			break
		for row: Row in culprits:
			gone[row.get_instance_id()] = true
			if not verdict.blamed.has(row.id):
				verdict.blamed.append(row.id)
			for index in row.tiles:
				still[index] -= 1
	return verdict

## Past this the answer is "the whole route", and counting further buys nothing.
const _CUTS_CAP := 12

## One cut, named. `culprits` is every row standing in it that has not already been cleared.
##
## **The shape is read off the barrier itself — the narrowest place the street is blocked right
## across — rather than off everything standing near the cut.** Which rows *have to go* is the
## wrong question for the shapes M129 names: with a van on one pavement and a café on the other,
## taking either away opens the street, so a minimal-removal answer calls each of them the whole
## cause and never finds the pair the rule is about.
func _shape_of_a_cut(map: CityMap, frontier: Array[Vector2i], culprits: Array,
		owners: Array) -> Verdict:
	var cut := Verdict.new()
	var ids := {}
	for row: Row in culprits:
		ids[row.id] = true
	var where := _stretch_of(map, frontier)
	var named := ", ".join(PackedStringArray(ids.keys()))

	if culprits.is_empty():
		# Nothing clearable stands one step past where the line stopped. With an empty frontier it
		# never left at all: the doorstep itself is inside something's field.
		if frontier.is_empty():
			cut.shape = Shape.DOORSTEP
			cut.detail = "the home and its own street are covered by [%s]" \
					% ", ".join(PackedStringArray(_ids_over_the_home(map, owners)))
		else:
			cut.shape = Shape.OTHER
			cut.detail = "%s, and no row covers the frontier" % where
		return cut

	var junction_tiles := 0
	for tile: Vector2i in frontier:
		if CityMap.junction_at(tile) != Vector2i(-1, -1):
			junction_tiles += 1
	# A junction cut is not about pavements at all — the line has nowhere to turn rather than
	# nowhere to walk — so it is named before the pavement shapes are looked for.
	if junction_tiles * 2 > frontier.size():
		cut.shape = Shape.JUNCTION_TAKEN
		var alone := _covers_the_crossing(map, frontier, culprits, owners)
		cut.detail = "%s: the crossing is covered by [%s]" % [where, named] if alone.is_empty() \
				else "%s: [%s] covers the whole crossing on its own" % [where, alone]
		return cut

	var segment := _segment_of(map, frontier)
	var barrier := _barrier_of(map, segment, culprits, owners) if segment else []
	if barrier.is_empty():
		cut.shape = Shape.NOT_A_BAND
		cut.detail = "%s, held by [%s], none of which closes that street on its own" % [where, named]
		return cut

	var wall := {}
	var paces := false
	var bodies := false
	for row: Row in barrier:
		wall[row.id] = true
		paces = paces or row.paces
		bodies = bodies or row.obstructs
	cut.detail = "%s closed end to end by [%s]" \
			% [where, ", ".join(PackedStringArray(wall.keys()))]

	if paces:
		cut.shape = Shape.PACING
	elif barrier.size() == 1:
		cut.shape = Shape.SINGLE_ROW_SPANS
	elif barrier.size() == 2 and _on_facing_pavements(map, barrier, segment):
		cut.shape = Shape.BODY_AND_FAR_SIDE if bodies else Shape.TWO_FIELDS
	elif barrier.size() == 2:
		cut.shape = Shape.OTHER
		cut.detail += " (both on the same pavement)"
	else:
		cut.shape = Shape.MANY_ROWS
	return cut

## The row that covers a whole junction box by itself, or "" — the reach that closes a crossing
## rather than a pavement, which is the number the pacing rule has to be chosen against.
func _covers_the_crossing(map: CityMap, frontier: Array[Vector2i], culprits: Array,
		owners: Array) -> String:
	var junction := Vector2i(-1, -1)
	for tile in frontier:
		junction = CityMap.junction_at(tile)
		if junction != Vector2i(-1, -1):
			break
	if junction == Vector2i(-1, -1):
		return ""
	var origin := junction * CityMap.period()
	for row: Row in culprits:
		var whole := true
		for y in range(origin.y, origin.y + Tuning.STREET_WIDTH):
			for x in range(origin.x, origin.x + Tuning.STREET_WIDTH):
				var tile := Vector2i(x, y)
				if not map.is_walkable(tile):
					continue
				var owning: Variant = owners[tile.y * map.size.x + tile.x]
				var held := false
				if owning != null:
					for other: Row in (owning as Array):
						if other == row:
							held = true
							break
				if not held:
					whole = false
					break
			if not whole:
				break
		if whole:
			return row.id
	return ""

## The rows that make up the barrier: the fewest of the ones standing in the cut that close this
## street on their own, end to end.
##
## **One row first, then a pair, then the lot**, because that is the question the milestone's
## shapes are asked in: *is this one thing reaching across the street, or one thing on each side of
## it?* Empty when even all of them together do not close that street — the cut is then somewhere
## the street's own two ends are not the geometry, which `NOT_A_BAND` records.
func _barrier_of(map: CityMap, segment: StreetNetwork.Segment, culprits: Array,
		owners: Array) -> Array:
	for row: Row in culprits:
		if _closes_the_street(map, segment, [row], owners):
			return [row]
	for i in culprits.size():
		for j in range(i + 1, culprits.size()):
			var pair: Array = [culprits[i], culprits[j]]
			if _closes_the_street(map, segment, pair, owners):
				return pair
	return culprits if _closes_the_street(map, segment, culprits, owners) else []

## Whether these rows alone leave no walk from one end of a street to the other.
##
## Stated over the street's own ground — both pavements, the carriageway left out because a line
## may not cross there anyway — and over a 4-connected walk, so a barrier laid diagonally counts
## as closing it exactly as a straight band does.
func _closes_the_street(map: CityMap, segment: StreetNetwork.Segment, rows: Array,
		owners: Array) -> bool:
	var wall := {}
	for row: Row in rows:
		wall[row.get_instance_id()] = true
	var rect := segment.tile_rect()
	var free := {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if not map.is_walkable(tile) or _is_a_carriageway_tile(map, tile, segment.horizontal):
				continue
			var owning: Variant = owners[tile.y * map.size.x + tile.x]
			if owning != null:
				var taken := false
				for row: Row in (owning as Array):
					if wall.has(row.get_instance_id()):
						taken = true
						break
				if taken:
					continue
			free[tile] = true

	var last := (rect.end.x - 1) if segment.horizontal else (rect.end.y - 1)
	var queue: Array[Vector2i] = []
	var seen := {}
	for tile: Vector2i in free:
		var at_the_start := tile.x == rect.position.x if segment.horizontal \
				else tile.y == rect.position.y
		if at_the_start:
			seen[tile] = true
			queue.append(tile)
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		if (at.x if segment.horizontal else at.y) == last:
			return false
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if free.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return true

## Which rows cover the doorstep — the answer when the line never leaves it.
func _ids_over_the_home(map: CityMap, owners: Array) -> Array:
	var found := {}
	for tile in _home_tiles(map):
		var here: Variant = owners[tile.y * map.size.x + tile.x]
		if here == null:
			continue
		for row: Row in (here as Array):
			found[row.id] = true
	return found.keys()

## The route's own ground, as flat tile indices — the only tiles anything below has to look at.
func _ground_tiles(map: CityMap, ground: PackedByteArray) -> PackedInt32Array:
	var found := PackedInt32Array()
	for index in ground.size():
		if ground[index] == 1:
			found.append(index)
	return found

## The ground of the route that the line could not get into, one step past where it stopped.
func _frontier(map: CityMap, here: PackedInt32Array, blocked: PackedInt32Array,
		reached: PackedByteArray) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for index in here:
		if reached[index] == 1 or blocked[index] <= 0:
			continue
		var tile := Vector2i(index % map.size.x, index / map.size.x)
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var beside: Vector2i = tile + step
			if not map.in_bounds(beside):
				continue
			if reached[beside.y * map.size.x + beside.x] == 1:
				found.append(tile)
				break
	return found

## Every row standing in a cut, read off the per-tile owner list rather than re-measured.
func _rows_covering(owners: Array, frontier: Array[Vector2i], width: int) -> Array:
	var seen := {}
	var found: Array = []
	for tile in frontier:
		var here: Variant = owners[tile.y * width + tile.x]
		if here == null:
			continue
		for row: Row in (here as Array):
			if seen.has(row.get_instance_id()):
				continue
			seen[row.get_instance_id()] = true
			found.append(row)
	return found

## The street the blockage sits on, or null where it is a junction or a block interior.
func _segment_of(map: CityMap, frontier: Array[Vector2i]) -> StreetNetwork.Segment:
	var counts := {}
	for tile in frontier:
		var segment := StreetNetwork.segment_containing(tile)
		if segment:
			counts[segment.key()] = int(counts.get(segment.key(), 0)) + 1
	var best := Vector3i.ZERO
	var most := 0
	for key: Vector3i in counts:
		if int(counts[key]) > most:
			most = int(counts[key])
			best = key
	return StreetNetwork.by_key(best) if most > 0 else null

func _stretch_of(map: CityMap, frontier: Array[Vector2i]) -> String:
	var segment := _segment_of(map, frontier)
	if segment:
		return "street %s (%s)" % [segment.key(),
				"east-west" if segment.horizontal else "north-south"]
	if frontier.is_empty():
		return "nowhere (the line stops with nothing beside it)"
	return "off-street ground at %s" % frontier[0]

## Whether the rows of a barrier stand on opposite pavements of the street they close — the
## difference between *one thing across the street* and *one thing on each side of it*.
func _on_facing_pavements(map: CityMap, culprits: Array,
		segment: StreetNetwork.Segment) -> bool:
	var sides := {}
	for row: Row in culprits:
		var band := _pavement_band(map.world_to_tile(row.position), segment)
		if band >= 0:
			sides[band] = true
	return sides.size() >= 2

## Which of a street's two pavements a tile is on — 0 for the low side (north or west), 1 for the
## high one, -1 for the carriageway or for anywhere off this street.
func _pavement_band(tile: Vector2i, segment: StreetNetwork.Segment) -> int:
	if not segment.tile_rect().has_point(tile):
		return -1
	var across := CityMap.corridor_offset(tile.y if segment.horizontal else tile.x)
	if across < 0 or CityMap.is_road_offset(across):
		return -1
	return 0 if across < Tuning.SIDEWALK_WIDTH else 1

# ------------------------------------------------- what the grower does mid-block ---

## Route cells that stand on a carriageway between two junctions. The corridor is grown on
## `ReachabilityGrid` cells, which know nothing about kerbs, so it may put one there.
func _road_cells_of(map: CityMap, route: Array) -> int:
	var found := 0
	for cell: Vector2i in route:
		if _is_a_mid_block_road_cell(map, cell):
			found += 1
	return found

## Every place the route steps pavement → carriageway → far pavement inside one street, as the
## kind of street it happened on. This is the finding M129's fourth item asks to be named.
func _mid_block_crossings_of(map: CityMap, route: Array) -> Array:
	var found: Array = []
	for i in range(1, route.size() - 1):
		var before: Vector2i = route[i - 1]
		var middle: Vector2i = route[i]
		var after: Vector2i = route[i + 1]
		if not _is_a_mid_block_road_cell(map, middle):
			continue
		var segment := StreetNetwork.segment_containing(middle * ReachabilityGrid.CELL)
		if not segment:
			continue
		var one := _pavement_band(before * ReachabilityGrid.CELL, segment)
		var other := _pavement_band(after * ReachabilityGrid.CELL, segment)
		if one >= 0 and other >= 0 and one != other:
			found.append(map.street_kind_at(not segment.horizontal,
					middle * ReachabilityGrid.CELL))
	return found

## Whether a route stands on the spine's own corridor anywhere — the context the mid-block count
## needs, since *no mid-block crossing of the main road* means two different things depending on
## whether the tree ever goes near it. `RouteTree` refuses to grow **along** the spine and lets a
## route cross it freely.
func _touches_the_spine(map: CityMap, route: Array) -> bool:
	if map.main_road < 0:
		return false
	for cell: Vector2i in route:
		var origin: Vector2i = cell * ReachabilityGrid.CELL
		if map.street_kind_at(true, origin) == GameEnums.StreetKind.MAIN:
			return true
	return false

## The streets a route puts cells on the carriageway of, for the line that names a finding.
func _road_stretches_of(map: CityMap, route: Array) -> String:
	var found := {}
	for cell: Vector2i in route:
		if not _is_a_mid_block_road_cell(map, cell):
			continue
		var segment := StreetNetwork.segment_containing(cell * ReachabilityGrid.CELL)
		if segment:
			found["%s %s" % [segment.key(), GameEnums.StreetKind.keys()[
					map.street_kind_at(not segment.horizontal, cell * ReachabilityGrid.CELL)]]] = true
	if found.is_empty():
		return "no carriageway cell on the route at all"
	var named: Array = found.keys()
	return "%s (%d street%s in all)" % [", ".join(PackedStringArray(named.slice(0, 4))),
			named.size(), "" if named.size() == 1 else "s"]

func _is_a_mid_block_road_cell(map: CityMap, cell: Vector2i) -> bool:
	var origin: Vector2i = cell * ReachabilityGrid.CELL
	var segment := StreetNetwork.segment_containing(origin)
	return segment != null and _is_a_carriageway_tile(map, origin, segment.horizontal)

# ---------------------------------------------------------------------- the report ---

func _report(tally: Dictionary, shapes: Dictionary, cut_shapes: Dictionary, examples: Dictionary,
		blame: Dictionary, broken: int, cuts_total: int, cuts_worst: int,
		routes_with_road_cells: int, routes_on_the_spine: int, mid_block_crossings: int,
		crossings_by_kind: Dictionary, days: int, rows_per_day: int, elapsed: int) -> void:
	print("\n-- %d days planned, %.1f placed rows a day that a line has to avoid --"
			% [days, float(rows_per_day) / maxf(1.0, float(days))])

	var labels := {
		Reading.BEAT_OPENING: "pacing rows only where their beat never opens (the primary reading)",
		Reading.BEAT_UNION: "pacing rows over their whole beat",
		Reading.CATALOGUE_ONLY: "primary, the day's own catalogue rows only (no seals or region wall)",
	}
	for reading in [Reading.BEAT_OPENING, Reading.BEAT_UNION, Reading.CATALOGUE_ONLY]:
		print("\n-- routes with a zero-cost line: %s --" % labels[reading])
		var clear := 0
		var total := 0
		for act in [1, 2, 3, 4]:
			var counts: Array = tally[reading][act]
			clear += int(counts[0])
			total += int(counts[1])
			print("   act %d  %3d of %3d  %5.1f%%"
					% [act, counts[0], counts[1], 100.0 * _share(counts[0], counts[1])])
		print("   all    %3d of %3d  %5.1f%%" % [clear, total, 100.0 * _share(clear, total)])

	print("\n-- what broke the line (primary reading) --")
	print("   routes = the first cut a walk out of the door runs into; cuts = every stretch on")
	print("   every broken route, which is what a rule would have to cover.")
	print("   %6s %6s  %s" % ["routes", "cuts", "shape"])
	for shape in SHAPE_NAMES:
		if int(shapes[shape]) == 0 and int(cut_shapes[shape]) == 0:
			continue
		print("   %6d %6d  %s" % [shapes[shape], cut_shapes[shape], SHAPE_NAMES[shape]])
		for line in examples[shape]:
			print("        e.g. %s" % line)

	print("\n-- how much of a route is blocked (primary reading, %d broken routes) --" % broken)
	print("   separate stretches to clear before a line exists: %.1f on average, %d at worst"
			% [float(cuts_total) / maxf(1.0, float(broken)), cuts_worst])
	print("   the rows standing in those stretches, by how many routes they break:")
	var ranked: Array = blame.keys()
	ranked.sort_custom(func(a: String, b: String) -> bool:
		return int(blame[a]) > int(blame[b]))
	for i in mini(12, ranked.size()):
		var id: String = ranked[i]
		var def := EventCatalogue.by_id(id)
		var reach := "" if not def else \
				" (intensity %.1f over %.0fpx, denies %.0fpx, body %.0fpx%s)" \
				% [def.intensity, def.outer_radius, EventScheduler._line_reach_of(def),
				def.obstructs_radius, ", paces" if def.paces else ""]
		print("      %-4d %s%s" % [blame[id], id, reach])

	print("\n-- the grower's own mid-block crossings --")
	print("   routes with at least one cell on a carriageway between junctions: %d"
			% routes_with_road_cells)
	print("   complete mid-block crossings (pavement -> road -> far pavement): %d"
			% mid_block_crossings)
	for kind in crossings_by_kind:
		print("      on %s streets: %d"
				% [GameEnums.StreetKind.keys()[kind], crossings_by_kind[kind]])
	print("   routes with any cell on the spine at all: %d" % routes_on_the_spine)

	print("\n-- %.1fs --" % (float(elapsed) / 1000.0))

func _share(part: int, whole: int) -> float:
	return 0.0 if whole == 0 else float(part) / float(whole)
