extends RefCounted
## Does a **solid body** ever close the walked sidewalk of a route street? Printed rather than
## asserted. Not a suite: it lives under `tests/probes/`, where the runner never discovers it, and
## runs only by name:
##
##     tools/test.sh probes/m129_walked_sidewalk_walls.gd
##
## The player, PLAYTEST-94: *"I still get hard walls on the side of the sidewalk that is on the
## path -- how can this be so hard to do correctly?"* `docs/TODO.md`, M129, asks this measured
## rather than guessed: over the probe's seeds, every solid body on a walked sidewalk that leaves
## her no lane on that sidewalk, by row and by the path that placed it.
##
## # What this measures
##
## `EventScheduler._leaves_no_line_along_a_sidewalk` asks two questions of a row's own numbers now:
## a **cost** one (`_line_reach_of` against `_THE_FAR_LANE`, "what does this row bill a passer-by")
## and a **physical** one (`_closes_the_band_by_its_own_placement`, "does a passer-by have anywhere
## left to stand"), and either is enough to make the row a wall — refused a route cell entirely by
## `_copies_of`. Both are asked once, from the def alone, before a tile is ever chosen, and only in
## `_place_one`'s candidate loop. This probe checks the result of that decision against the day as
## it is actually planned and placed: does any body, from any placing path, still end up standing
## where it leaves no lane on a walked sidewalk — a genuine gap in what the rule covers, or, if one
## the rule itself is supposed to refuse turns up anyway, a bug in the rule rather than a gap in it.
##
## # Reused rather than re-derived
##
## - **The walked sidewalk.** `EventScheduler._route_sidewalks()` is the rule's own reading of
##   which band is "on the path": every on-corridor street (`Corridor.depth() == 0`), reduced to
##   the one sidewalk band of the two that `Corridor.carries_a_route()` says the tree actually
##   runs along, or the whole street where neither does. Asked here exactly as the rule asks it,
##   because a probe reading a different band could not tell whether the rule (or a gap in it) had
##   fired on the ground the player actually meant.
## - **The closing test.** `EventScheduler.closes_a_walked_sidewalk_band()` is the one place the
##   tile-grained physical reading lives — the suite (`tests/test_events.gd`) asks the same
##   function of the same kind of sample, so the probe's printed number and the suite's asserted
##   one can never quietly disagree about what "closed" means. See its own doc for why the walk
##   only has to connect the band's genuinely open ends rather than its raw tile-rect corners.
## - **The day, planned the way the game plans it.** `RouteTree.for_day` grows the corridor,
##   `RegionPlanner.plan_day` decides the wall and doors, `ClosurePlanner.plan_day` closes streets,
##   `SealPlanner.plan_day` seals the tree, `EventScheduler.build_day`'s own phases fill the city —
##   the same assembly `tests/probes/m129_zero_cost_line.gd` uses, with the same private phase
##   functions called by hand so each one's own output can be tagged with the pass that made it
##   (`build_day` merges them into one list and throws that fact away).
##
## # The clearance figure
##
## **28px, twice `Tuning.PLAYER_BODY_RADIUS` (14px), not 46.** `Tuning.PLAYER_BODY_RADIUS` is the
## one collision radius the whole rig moves as (`src/player/stroller.gd`, the note beside
## `pram_shape`: *"the `CircleShape2D` on `scenes/player/stroller.tscn`'s `CollisionShape2D` is one
## combined physics radius for the whole rig"*), and the pram's own body
## (`Stroller.PRAM_BODY_RADIUS`, 8px) sits ahead of her **on the circumference of that circle, in
## the direction of travel** — never beside it — so nothing about pushing it widens her sideways.
## `EventScheduler._THE_FAR_LANE`'s own doc comment states the width a lane needs in those terms: *"a
## free tile is a line because a tile is wider than the 28px stroller (2 * PLAYER_BODY_RADIUS)"*, and
## `tests/test_events.gd`'s `_walkable_lane_beside(...) >= 2.0 * Tuning.PLAYER_BODY_RADIUS` is the
## same figure checked directly against a placed body. 46px is a different, narrower fact:
## `CHECKPOINT_DETAIN_REACH`'s doc (`src/autoload/tuning.gd`) derives it as
## `obstructs_radius + PLAYER_BODY_RADIUS` for one specific door's 32px body (`32 + 14 = 46`), which
## does not generalise — a body's own `obstructs_radius` varies per row. The general form of that
## same formula, *"her centre is stopped `obstructs_radius + PLAYER_BODY_RADIUS` from a body's
## centre"* (`EventDef.detain_distance()`'s doc; the **events** skill, "A lethal radius and a solid
## body are the same mechanism"), is what `closes_a_walked_sidewalk_band()` uses per tile: a tile's
## own centre point is free of a body when it is further than that sum away.
##
## # What counts as a solid body
##
## Every placed row with `obstructs_radius > 0.0`, minus the two exemptions the production rule
## and its own probe already make and for the same reasons: `scenery` (`pigeon_flock` —
## *"basically free already"*), and a `checkpoint_hut`/
## `checkpoint_gate` door body (*"a region door is never a block... it costs by design"*,
## `docs/DECISIONS.md`; the region **wall**'s own body is not a door and still counts). A pacing
## row's body is read at its dawn position, the same simplification
## `tests/probes/m129_zero_cost_line.gd` states for every row it measures ("nothing is simulated
## in time"); almost none carry a body at all (`homeless_yeller` is excluded from the seal pool
## for exactly that reason, `src/routes/seal_planner.gd`).
##
## # What "closes" means
##
## Per walked-sidewalk band, `EventScheduler.closes_a_walked_sidewalk_band()` — a tile-grained
## 4-connected walk between the band's own genuinely open ends. **Cumulative with everything else
## down that day**, the same reading the production rule and `docs/DECISIONS.md` both state it in:
## a body on each of the two lanes closes a band neither could close alone. Where a band is closed,
## the minimal culprit set is found the way `tests/probes/m129_zero_cost_line.gd`'s `_barrier_of`
## finds one — one body, then a pair, then the whole touching set — and each member of that set is
## counted once as a closing body, tagged with the pass that placed it.
##
## # Exemptions this probe does *not* make
##
## **The home doorstep and a route's destination are not exempted**, because `_route_sidewalks`
## does not exempt them: it reads every on-corridor street identically, home street included, and
## a destination calm area has no street band of its own to ask about (the band's ground stops at
## the calm tiles, the same edge `tests/probes/m129_zero_cost_line.gd`'s flood fill arrives on).
## `CLAUDE.md`'s "the home's doorstep is exempt from the route-redundancy guarantee" is a different
## guarantee — whether a second calm area stays reachable — and has no bearing on whether a body
## may stand on the doorstep's own sidewalk.
##
## # Sizing
##
## `SEEDS` seeds x one day per act (`DAYS`), day 1 included in every seed's own run — the same
## coverage `tests/probes/m129_zero_cost_line.gd` uses, so the two probes' numbers are read off the
## same sample.

const SEEDS := 6
const BASE_SEED := 129129
const DAYS: Array[int] = [1, 5, 9, 13]

## The lane width her own collision circle needs — see the class doc, "The clearance figure". Not
## read directly by the closing test (which asks the per-tile radius-sum question instead), but
## printed so the report states the figure it is equivalent to.
const HER_CLEARANCE := 2.0 * Tuning.PLAYER_BODY_RADIUS

## A region door costs by design and is exempt from being a wall the same way the production rule
## and `tests/probes/m129_zero_cost_line.gd` both exempt it; the wall body beside it is not a door
## and is not matched by this prefix.
const _DOOR_ID_PREFIX := "checkpoint"

## Which pass of the morning put a solid body down.
enum Source {
	CANDIDATE_LOOP,   ## `_place_one`, reached by scripted, one-shot and recurring rows alike.
	SEAL,             ## `SealPlanner.plan_day`, before the scheduler ever runs.
	CALM_GROUND,      ## `_spoil_the_parks_she_used` — appended to `planned` directly, no rule asked.
	CLOSURE,          ## `ClosurePlanner.plan_day` / `map.closed_tiles` — a tile barrier, not a row.
	REGION,           ## `RegionPlanner.plan_day`'s wall and door bodies.
	OTHER,            ## ambient, scars, the taught-run pursuer — everything else `build_day` adds.
}

const _SOURCE_NAMES := {
	Source.CANDIDATE_LOOP: "scheduler candidate loop (_place_one)",
	Source.SEAL: "seals (SealPlanner)",
	Source.CALM_GROUND: "calm-ground pass (_spoil_the_parks_she_used)",
	Source.CLOSURE: "closures (ClosurePlanner)",
	Source.REGION: "region walls/doors (RegionPlanner)",
	Source.OTHER: "other (ambient, scars, taught-run pursuer)",
}

## One physical body, reduced to what the closing test needs.
class Body extends RefCounted:
	var id := ""
	var radius := 0.0
	var position := Vector2.ZERO
	var source := Source.OTHER
	var paces := false

## One closed band, kept for the worst-case report.
class ClosedBand extends RefCounted:
	var seed_used := 0
	var day := 0
	var act := 0
	var segment_key := Vector3i.ZERO
	var horizontal := true
	var band := Rect2i()
	var culprits: Array = []   # Array[Body]
	var ground_only := false   # closed by a closure tile / the ground alone, no body responsible

func run(t) -> void:
	_measure()
	t.check(true, "m129 walked-sidewalk-walls probe ran")

# ------------------------------------------------------------------ the measurement ---

func _measure() -> void:
	var started := Time.get_ticks_msec()
	print("\n== M129: bodies that close the walked sidewalk, %d seeds x one day per act %s =="
			% [SEEDS, DAYS])
	print("   her clearance: %.0fpx (2 * Tuning.PLAYER_BODY_RADIUS, %.0fpx)"
			% [HER_CLEARANCE, Tuning.PLAYER_BODY_RADIUS])

	var tally := {}   # act -> [bands closed, bands measured]
	for act in [1, 2, 3, 4]:
		tally[act] = [0, 0]
	var by_row := {}   # id -> {source -> count}
	var closed_examples: Array = []   # Array[ClosedBand]
	var days_measured := 0
	var ground_only_bands := 0
	var rule_scope_singles := 0
	var single_culprit_bands := 0
	var van_placed := 0
	var van_far_sidewalk := 0

	for i in SEEDS:
		var seed_used := BASE_SEED + i * 97
		var map := CityGenerator.generate(seed_used)
		for day in DAYS:
			var act: int = Tuning.act_for_day(day)
			var tree := _plan_the_day(map, day)
			var gathered := _gather_bodies(map, day, tree)
			var bodies: Array = gathered["bodies"]
			var closed_tiles: Dictionary = gathered["closed_tiles"]
			var corridor: Corridor = gathered["corridor"]
			days_measured += 1

			var ground := {}
			for entry: Array in EventScheduler._route_sidewalks(map, ground, corridor):
				var segment: StreetNetwork.Segment = entry[0]
				var band: Rect2i = entry[1]
				var world: Rect2 = entry[2]
				var per_act: Array = tally[act]
				per_act[1] += 1

				var ground_alone := EventScheduler.closes_a_walked_sidewalk_band(
						map, band, segment.horizontal, [], closed_tiles)
				var candidates := _bodies_touching(world, bodies)
				var full := EventScheduler.closes_a_walked_sidewalk_band(
						map, band, segment.horizontal, _as_vectors(candidates), closed_tiles)
				if not full:
					continue
				per_act[0] += 1

				var record := ClosedBand.new()
				record.seed_used = seed_used
				record.day = day
				record.act = act
				record.segment_key = segment.key()
				record.horizontal = segment.horizontal
				record.band = band

				if ground_alone:
					record.ground_only = true
					ground_only_bands += 1
					if closed_examples.size() < 40:
						closed_examples.append(record)
					continue

				var culprits := _culprits_of(map, band, segment.horizontal, candidates, closed_tiles)
				if culprits.is_empty():
					# Closed with a touching candidate list that could not reproduce it alone,
					# together or as the ground: the proximity filter under-reached. Recorded as
					# ground-only so the count is honest rather than silently dropped.
					record.ground_only = true
					ground_only_bands += 1
					if closed_examples.size() < 40:
						closed_examples.append(record)
					continue

				record.culprits = culprits
				closed_examples.append(record)
				if culprits.size() == 1:
					single_culprit_bands += 1
					var solo: Body = culprits[0]
					if solo.source == Source.CANDIDATE_LOOP:
						var def := EventCatalogue.by_id(solo.id)
						if def and EventScheduler._leaves_no_line_along_a_sidewalk(def):
							rule_scope_singles += 1
				for culprit: Body in culprits:
					if not by_row.has(culprit.id):
						by_row[culprit.id] = {}
					var per_source: Dictionary = by_row[culprit.id]
					per_source[culprit.source] = int(per_source.get(culprit.source, 0)) + 1

			for body: Body in bodies:
				if body.id != "delivery_van":
					continue
				van_placed += 1
				if _stands_on_a_route_streets_far_sidewalk(map, corridor, body.position):
					van_far_sidewalk += 1

	_report(tally, by_row, closed_examples, days_measured, ground_only_bands,
			single_culprit_bands, rule_scope_singles, van_placed, van_far_sidewalk,
			Time.get_ticks_msec() - started)

# ----------------------------------------------------------------- planning a day ---

## The corridor, exactly as `tests/probes/m129_zero_cost_line.gd` plans it.
func _plan_the_day(map: CityMap, day: int) -> RouteTree:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)
	return RouteTree.for_day(map, day)

func _rng(map: CityMap, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("m129w:%s:%d:%d" % [stream, map.seed_used, day])
	return rng

## Every solid body the day stands, tagged with the pass that placed it. Reimplements
## `EventScheduler.build_day`'s own phase order by calling its private phase functions directly —
## the same access `tests/probes/m129_zero_cost_line.gd` already relies on for `_line_reach_of`,
## `_role_for` and the rest — so each phase's own output can be told apart, which `build_day`'s
## single merged return cannot.
func _gather_bodies(map: CityMap, day: int, tree: RouteTree) -> Dictionary:
	var region_plan := RegionPlanner.plan_day(map, day, tree)
	var closures := ClosurePlanner.plan_day(map, day, _rng(map, day, "closures"), tree, region_plan)
	map.close_streets(closures)

	map.clear_day_holds()
	for closure: RoadClosure in closures:
		map.hold_segment(closure.segment.key())
	for segment: StreetNetwork.Segment in region_plan.walls:
		map.hold_segment(segment.key())
	for segment: StreetNetwork.Segment in region_plan.doors:
		map.hold_segment(segment.key())
	for segment: StreetNetwork.Segment in StreetNetwork.around_blocks(
			Rect2i(map.home_block, Vector2i.ONE)):
		map.hold_segment(segment.key())

	var boundary := {}
	for segment: StreetNetwork.Segment in region_plan.walls:
		boundary[segment.key()] = true
	for segment: StreetNetwork.Segment in region_plan.doors:
		boundary[segment.key()] = true
	for rect: Rect2i in region_plan.alley_walls:
		boundary[rect.position] = true
	for rect: Rect2i in region_plan.alley_doors:
		boundary[rect.position] = true

	var seals := SealPlanner.plan_day(map, day, tree, _rng(map, day, "seals"), boundary,
			map.held_segments)

	var corridor := Corridor.of(tree)
	var ground := {}
	var no_calm: Array[Vector2i] = []
	var leave_alone := EventScheduler._calm_to_leave_alone(map, no_calm)
	var rng := _rng(map, day, "events")
	var base: int = rng.seed

	var planned: Array[EventScheduler.Planned] = []
	var provenance := {}   # Planned instance id -> Source

	var ambient := EventScheduler._place_ambient(day, map, 0)
	planned.append_array(ambient)
	for plan: EventScheduler.Planned in ambient:
		provenance[plan.get_instance_id()] = Source.OTHER

	var no_scars: Array[Dictionary] = []
	var scars := EventScheduler._place_scars(day, no_scars, 0)
	planned.append_array(scars)
	for plan: EventScheduler.Planned in scars:
		provenance[plan.get_instance_id()] = Source.OTHER

	var before := planned.size()
	EventScheduler._place_scripted(day, EventScheduler._stream(base, 1), map, planned, ground,
			leave_alone, corridor, 0)
	_tag_new(planned, provenance, before, Source.CANDIDATE_LOOP)

	before = planned.size()
	var consumed: Array[String] = []
	EventScheduler._place_one_shots(day, EventScheduler._stream(base, 2), map, consumed, planned,
			ground, leave_alone, corridor, 0)
	_tag_new(planned, provenance, before, Source.CANDIDATE_LOOP)

	before = planned.size()
	EventScheduler._spoil_the_parks_she_used(day, EventScheduler._stream(base, 3), map, planned,
			no_calm, 0)
	_tag_new(planned, provenance, before, Source.CALM_GROUND)

	before = planned.size()
	EventScheduler._fill_with_recurring(day, base, map, planned, ground, leave_alone, corridor, 0)
	_tag_new(planned, provenance, before, Source.CANDIDATE_LOOP)

	before = planned.size()
	EventScheduler._ensure_the_run_is_taught(day, planned, 0)
	_tag_new(planned, provenance, before, Source.OTHER)

	# Removal-only passes: monotonic, never add a body, so tagging is complete before they run.
	EventScheduler._ensure_one_usable_park(map, planned, no_calm)
	EventScheduler._ensure_the_city_is_still_walkable(map, planned)

	for plan: EventScheduler.Planned in seals:
		provenance[plan.get_instance_id()] = Source.SEAL
	planned.append_array(seals)
	for plan: EventScheduler.Planned in region_plan.wall_bodies:
		provenance[plan.get_instance_id()] = Source.REGION
	planned.append_array(region_plan.wall_bodies)
	for plan: EventScheduler.Planned in region_plan.door_bodies:
		provenance[plan.get_instance_id()] = Source.REGION
	planned.append_array(region_plan.door_bodies)

	var bodies: Array = []   # Array[Body]
	for plan: EventScheduler.Planned in planned:
		if not plan.is_placed():
			continue
		var def := plan.def
		if def.obstructs_radius <= 0.0 or def.scenery:
			continue
		if def.id.begins_with(_DOOR_ID_PREFIX):
			continue
		var body := Body.new()
		body.id = def.id
		body.radius = def.obstructs_radius
		body.position = plan.position
		body.source = int(provenance.get(plan.get_instance_id(), Source.OTHER))
		body.paces = def.paces
		bodies.append(body)

	return {"bodies": bodies, "corridor": corridor, "closed_tiles": map.closed_tiles.duplicate()}

## Tags every `Planned` appended to `planned` since index `before` with `source`.
func _tag_new(planned: Array[EventScheduler.Planned], provenance: Dictionary, before: int,
		source: int) -> void:
	for i in range(before, planned.size()):
		provenance[planned[i].get_instance_id()] = source

# ------------------------------------------------------------------- the closing test ---

## Whether `position` stands on an on-corridor street's sidewalk band that is *not* the one the
## tree actually walks — legal ground for a wall (`EventScheduler._copies_of`), and what
## `docs/DECISIONS.md`'s "walls on a route street's far sidewalk" measures for `cafe_tables` and
## `construction`. `false` off a street entirely, or on a street the tree does not use at all.
func _stands_on_a_route_streets_far_sidewalk(map: CityMap, corridor: Corridor,
		position: Vector2) -> bool:
	var tile := map.world_to_tile(position)
	var segment := StreetNetwork.segment_containing(tile)
	if not segment or corridor.depth(segment.tile_rect().position) != 0:
		return false
	for band: Rect2i in EventScheduler._sidewalk_bands(segment.tile_rect(), segment.horizontal):
		if not band.has_point(tile):
			continue
		return not EventScheduler._a_route_walks(corridor, band)
	return false

## Every body whose physical reach could plausibly cover part of this band — the cheap filter
## before the tile work, the same shape as `EventScheduler._reach_touches`.
func _bodies_touching(world: Rect2, bodies: Array) -> Array:
	var found: Array = []   # Array[Body]
	for body: Body in bodies:
		if world.grow(body.radius + Tuning.PLAYER_BODY_RADIUS).has_point(body.position):
			found.append(body)
	return found

## `Body` instances as `[position.x, position.y, radius]`, the shape
## `EventScheduler.closes_a_walked_sidewalk_band()` asks for.
func _as_vectors(bodies: Array) -> Array:
	var found: Array = []
	for body: Body in bodies:
		found.append(Vector3(body.position.x, body.position.y, body.radius))
	return found

## The fewest of `candidates` that close this band on their own — one body first, then a pair, then
## the whole touching set. The same order `tests/probes/m129_zero_cost_line.gd`'s `_barrier_of`
## tries in, and for the same reason: a body on each of two lanes closes the band between them
## while neither closes it alone, and the smallest-removal answer would blame only one of the pair.
func _culprits_of(map: CityMap, band: Rect2i, horizontal: bool, candidates: Array,
		closed_tiles: Dictionary) -> Array:
	for body: Body in candidates:
		if EventScheduler.closes_a_walked_sidewalk_band(
				map, band, horizontal, _as_vectors([body]), closed_tiles):
			return [body]
	for i in candidates.size():
		for j in range(i + 1, candidates.size()):
			var pair: Array = [candidates[i], candidates[j]]
			if EventScheduler.closes_a_walked_sidewalk_band(
					map, band, horizontal, _as_vectors(pair), closed_tiles):
				return pair
	if candidates.size() > 2 and EventScheduler.closes_a_walked_sidewalk_band(
			map, band, horizontal, _as_vectors(candidates), closed_tiles):
		return candidates
	return []

# ---------------------------------------------------------------------- the report ---

func _report(tally: Dictionary, by_row: Dictionary, closed_examples: Array, days: int,
		ground_only_bands: int, single_culprit_bands: int, rule_scope_singles: int,
		van_placed: int, van_far_sidewalk: int, elapsed: int) -> void:
	print("\n-- walked-sidewalk bands with a lane she fits through --")
	var closed_total := 0
	var measured_total := 0
	for act in [1, 2, 3, 4]:
		var counts: Array = tally[act]
		var closed: int = counts[0]
		var measured: int = counts[1]
		closed_total += closed
		measured_total += measured
		print("   act %d  closed %3d of %3d  %5.1f%%"
				% [act, closed, measured, 100.0 * _share(closed, measured)])
	print("   all    closed %3d of %3d  %5.1f%%"
			% [closed_total, measured_total, 100.0 * _share(closed_total, measured_total)])
	print("   (%d bands closed by a closure tile / the ground alone, no body to blame)"
			% ground_only_bands)

	print("\n-- closing bodies per day, %d days measured --" % days)
	var per_day := float(closed_total - ground_only_bands) / maxf(1.0, float(days))
	print("   %.2f closing-body findings per day (a pair on the same band counts as two)"
			% per_day)

	print("\n-- by row and by the path that placed it --")
	print("   %6s  %-20s  %s" % ["count", "row id", "placing path(s)"])
	var ranked: Array = by_row.keys()
	ranked.sort_custom(func(a: String, b: String) -> bool:
		return _row_total(by_row[a]) > _row_total(by_row[b]))
	for id: String in ranked:
		var per_source: Dictionary = by_row[id]
		var total := _row_total(per_source)
		var parts: Array[String] = []
		for source in per_source:
			parts.append("%s: %d" % [_SOURCE_NAMES[source], int(per_source[source])])
		print("   %6d  %-20s  %s" % [total, id, ", ".join(parts)])
	if ranked.is_empty():
		print("   none: no row closed a walked sidewalk in the sample")

	print("\n-- the physical clause's own scope --")
	print("   single-culprit closures: %d" % single_culprit_bands)
	print("   of those, a row the candidate loop's own rule (cost or physical) already reads as a")
	print("   wall: %d" % rule_scope_singles)
	if rule_scope_singles > 0:
		print("   -- a bug in the rule, not a gap in what it covers: the rule is asked of exactly")
		print("      this row's own numbers and should have refused this placement by itself")
	else:
		print("   -- none: every closure a wall-by-the-rule's-own-reading row causes is one the")
		print("      rule already refuses; what remains, if anything, is ground the rule was never")
		print("      asked about at all")

	print("\n-- delivery_van, density and where it stands --")
	print("   placed: %d over %d days (%.1f/day)"
			% [van_placed, days, float(van_placed) / maxf(1.0, float(days))])
	print("   on a route street's far sidewalk (legal ground for a wall): %d" % van_far_sidewalk)

	print("\n-- the ten worst concrete cases --")
	closed_examples.sort_custom(func(a: ClosedBand, b: ClosedBand) -> bool:
		var a_key := 0 if a.ground_only else a.culprits.size()
		var b_key := 0 if b.ground_only else b.culprits.size()
		return a_key < b_key)
	for i in mini(10, closed_examples.size()):
		var record: ClosedBand = closed_examples[i]
		if record.ground_only:
			print("   seed %d day %d: street %s, band %s -- closed by the ground/a closure alone"
					% [record.seed_used, record.day, record.segment_key, record.band])
			print("      tools/run.sh --seed %d --day %d" % [record.seed_used, record.day])
			continue
		var names: Array[String] = []
		var at := record.band.position
		for culprit: Body in record.culprits:
			names.append("%s (%s)" % [culprit.id, _SOURCE_NAMES[culprit.source]])
			at = Vector2i(int(culprit.position.x / float(Tuning.TILE_SIZE)),
					int(culprit.position.y / float(Tuning.TILE_SIZE)))
		print("   seed %d day %d (act %d): street %s, band %s closed by [%s]"
				% [record.seed_used, record.day, record.act, record.segment_key, record.band,
				", ".join(names)])
		print("      stand at tile %s -- tools/run.sh --seed %d --day %d"
				% [at, record.seed_used, record.day])
	if closed_examples.is_empty():
		print("   none: every walked-sidewalk band in the sample kept a lane")

	print("\n-- %.1fs --" % (float(elapsed) / 1000.0))

func _row_total(per_source: Dictionary) -> int:
	var total := 0
	for source in per_source:
		total += int(per_source[source])
	return total

func _share(part: int, whole: int) -> float:
	return 0.0 if whole == 0 else float(part) / float(whole)
