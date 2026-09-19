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
## # What is built today, and what this measures instead
##
## `EventScheduler._leaves_the_routes_sidewalk_open` (`src/events/event_scheduler.gd`) is the one
## rule that already exists for this, and it runs in exactly one place: `_place_one`'s candidate
## loop, which `_place_scripted`, `_place_one_shots` and `_fill_with_recurring` all funnel through.
## Everything else that can put a solid body on a street — the seals a `SealPlanner` places before
## the scheduler runs, the calm-ground pass (`_spoil_the_parks_she_used`, which drops rows straight
## onto `planned` with no rule asked of them), the region wall and door bodies, and a closure
## barrier — never asks it. `docs/DECISIONS.md`'s own record of the rule (the three changes, M129)
## says the same about the width clause specifically: it is asked of `EventDef.obstructs_radius`
## and `_line_reach_of()`, a **cost** reading that denies more ground than a body's own edge for a
## row that "bills anybody within reach" — right for pricing a route, but not the question a
## *hard* wall asks. This probe asks the narrower, physical one instead: with only the body's own
## `obstructs_radius` in the way, is there still a lane she fits through?
##
## # Reused rather than re-derived
##
## - **The walked sidewalk.** `EventScheduler._route_sidewalks()` is the rule's own reading of
##   which band is "on the path": every on-corridor street (`Corridor.depth() == 0`), reduced to
##   the one sidewalk band of the two that `Corridor.carries_a_route()` says the tree actually
##   runs along, or the whole street where neither does. Asked here exactly as the rule asks it,
##   because a probe reading a different band could not tell whether the rule (or a gap in it) had
##   fired on the ground the player actually meant.
## - **A carriageway tile inside a fallback whole-street band.** `EventScheduler._is_a_carriageway_tile`,
##   the same test `_closes_the_run` uses, so a body parked on the road between two kerbs is never
##   read as taking a pavement it was never on.
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
## body are the same mechanism"), is what this probe uses per tile: a tile's own centre point is
## free of a body when it is further than that sum away, which is the tile-grained reading
## `_closes_the_run` already measures a lane in, substituting the body's physical
## `obstructs_radius` for the rule's cost-based `_line_reach_of()`.
##
## # What counts as a solid body
##
## Every placed row with `obstructs_radius > 0.0`, minus the three exemptions the production rule
## and its own probe already make and for the same reasons: `city_wide` (no place to keep clear
## of), `scenery` (`pigeon_flock` — *"basically free already"*), and a `checkpoint_hut`/
## `checkpoint_gate` door body (*"a region door is never a block... it costs by design"*,
## `docs/DECISIONS.md`; the region **wall**'s own body is not a door and still counts). A pacing
## row's body is read at its dawn position, the same simplification
## `tests/probes/m129_zero_cost_line.gd` states for every row it measures ("nothing is simulated
## in time"); almost none carry a body at all (`homeless_yeller` is excluded from the seal pool
## for exactly that reason, `src/routes/seal_planner.gd`).
##
## # What "closes" means
##
## Per walked-sidewalk band, a tile-grained 4-connected walk from one end to the other over the
## band's own tiles, exactly as `EventScheduler._closes_the_run` asks it of a street — a tile is
## free unless a body's own physical reach (`obstructs_radius + PLAYER_BODY_RADIUS`) covers its
## centre. **Cumulative with everything else down that day**, the same reading the production rule
## and `docs/DECISIONS.md` both state it in: a body on each of the two lanes closes a band neither
## could close alone. Where a band is closed, the minimal culprit set is found the way
## `tests/probes/m129_zero_cost_line.gd`'s `_barrier_of` finds one — one body, then a pair, then
## the whole touching set — and each member of that set is counted once as a closing body, tagged
## with the pass that placed it.
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
## read directly by the closing test below (which asks the per-tile radius-sum question instead),
## but printed so the report states the figure it is equivalent to.
const HER_CLEARANCE := 2.0 * Tuning.PLAYER_BODY_RADIUS

## The four rows the production width rule already refuses the route's own sidewalk to
## (`docs/DECISIONS.md`, M129, "the three changes"). A single-culprit closure whose row is one of
## these, placed by the candidate loop, is the shape that would mean the rule itself has a bug
## rather than a gap in what it covers.
const _RULE_COVERS: Array[String] = ["cafe_tables", "market_stall", "construction", "ice_cream_van"]

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

				var ground_alone := _band_is_closed(map, band, segment.horizontal, [], closed_tiles)
				var candidates := _bodies_touching(world, bodies)
				var full := _band_is_closed(map, band, segment.horizontal, candidates, closed_tiles)
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
					if solo.source == Source.CANDIDATE_LOOP and _RULE_COVERS.has(solo.id):
						rule_scope_singles += 1
				for culprit: Body in culprits:
					if not by_row.has(culprit.id):
						by_row[culprit.id] = {}
					var per_source: Dictionary = by_row[culprit.id]
					per_source[culprit.source] = int(per_source.get(culprit.source, 0)) + 1

	_report(tally, by_row, closed_examples, days_measured, ground_only_bands,
			single_culprit_bands, rule_scope_singles, Time.get_ticks_msec() - started)

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
		if def.obstructs_radius <= 0.0 or def.city_wide or def.scenery:
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

## Every body whose physical reach could plausibly cover part of this band — the cheap filter
## before the tile work, the same shape as `EventScheduler._reach_touches`.
func _bodies_touching(world: Rect2, bodies: Array) -> Array:
	var found: Array = []   # Array[Body]
	for body: Body in bodies:
		if world.grow(body.radius + Tuning.PLAYER_BODY_RADIUS).has_point(body.position):
			found.append(body)
	return found

const _NEIGHBOUR_STEPS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

## Whether these bodies, together with the day's closures, leave no walk from one end of the band
## to the other — the physical reading of `EventScheduler._closes_the_run`, substituting each
## body's own `obstructs_radius + PLAYER_BODY_RADIUS` for the rule's cost-based `_line_reach_of()`.
func _band_is_closed(map: CityMap, band: Rect2i, horizontal: bool, bodies: Array,
		closed_tiles: Dictionary) -> bool:
	var free := {}
	for y in range(band.position.y, band.end.y):
		for x in range(band.position.x, band.end.x):
			var tile := Vector2i(x, y)
			if not map.is_open(tile) or closed_tiles.has(tile):
				continue
			if EventScheduler._is_a_carriageway_tile(map, tile, horizontal):
				continue
			var at := map.tile_to_world(tile)
			var taken := false
			for body: Body in bodies:
				if at.distance_to(body.position) <= body.radius + Tuning.PLAYER_BODY_RADIUS:
					taken = true
					break
			if not taken:
				free[tile] = true

	var last := (band.end.x - 1) if horizontal else (band.end.y - 1)
	var queue: Array[Vector2i] = []
	var seen := {}
	for tile: Vector2i in free:
		var at_start := tile.x == band.position.x if horizontal else tile.y == band.position.y
		if at_start:
			seen[tile] = true
			queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		if (at.x if horizontal else at.y) == last:
			return false
		for step in _NEIGHBOUR_STEPS:
			var next: Vector2i = at + step
			if free.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return true

## The fewest of `candidates` that close this band on their own — one body first, then a pair, then
## the whole touching set. The same order `tests/probes/m129_zero_cost_line.gd`'s `_barrier_of`
## tries in, and for the same reason: a body on each of two lanes closes the band between them
## while neither closes it alone, and the smallest-removal answer would blame only one of the pair.
func _culprits_of(map: CityMap, band: Rect2i, horizontal: bool, candidates: Array,
		closed_tiles: Dictionary) -> Array:
	for body: Body in candidates:
		if _band_is_closed(map, band, horizontal, [body], closed_tiles):
			return [body]
	for i in candidates.size():
		for j in range(i + 1, candidates.size()):
			var pair: Array = [candidates[i], candidates[j]]
			if _band_is_closed(map, band, horizontal, pair, closed_tiles):
				return pair
	if candidates.size() > 2 and _band_is_closed(map, band, horizontal, candidates, closed_tiles):
		return candidates
	return []

# ---------------------------------------------------------------------- the report ---

func _report(tally: Dictionary, by_row: Dictionary, closed_examples: Array, days: int,
		ground_only_bands: int, single_culprit_bands: int, rule_scope_singles: int,
		elapsed: int) -> void:
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

	print("\n-- the existing four-row rule's own scope --")
	print("   single-culprit closures: %d" % single_culprit_bands)
	print("   of those, closed by one of the four rows (%s), placed by the candidate loop: %d"
			% [", ".join(_RULE_COVERS), rule_scope_singles])
	if rule_scope_singles > 0:
		print("   -- a bug in the rule, not a gap in what it covers: the rule is asked of exactly")
		print("      this row's own numbers and should have refused this placement by itself")
	else:
		print("   -- none: every closure the rule's own four rows cause is one the rule already")
		print("      refuses; what remains is ground the rule was never asked about")

	print("\n-- the ten worst concrete cases --")
	closed_examples.sort_custom(func(a: ClosedBand, b: ClosedBand) -> bool:
		var a_key := 0 if a.ground_only else a.culprits.size()
		var b_key := 0 if b.ground_only else b.culprits.size()
		return a_key < b_key)
	for i in mini(10, closed_examples.size()):
		var record: ClosedBand = closed_examples[i]
		var world := Rect2(Vector2(record.band.position) * float(Tuning.TILE_SIZE),
				Vector2(record.band.size) * float(Tuning.TILE_SIZE))
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
