class_name SealPlanner
extends RefCounted
## Seals every street off the day's route tree — the placement M64 exists for.
##
## The design is `docs/TODO.md`, M64, "Nothing off the path". The corridor
## (`RouteTree.for_day`) is the day's only free way through; everything else in the lattice is
## closed, not merely dearer. This is where "closed" becomes an actual placement rather than a
## sentence.
##
## **A seal is a fact about where she may walk, so it is planned beside `ClosurePlanner`** — the
## other pass that decides what a day's streets do — **and counted apart from the catalogue's
## event budget**, which exists to decide variety rather than to price the city's walls. It is
## hooked in at `EventManager.start_day`, after `EventScheduler.build_day` has spent that budget,
## so the two never compete for it.
##
## **Two strengths.** A **hard** seal stands several bodies across the whole street width —
## sidewalk, road and sidewalk — so nothing gets past it at all. A **soft** seal takes both
## pavements and leaves the carriageway open: "since a street is sidewalk|road|sidewalk, the road
## is always still there, so it costs time and exposure, never the day" (`construction`'s own
## docstring). Both read as *closed*; only the price differs.
##
## **The candidates are data, and the placement is generic over them.** *(2026-09-03: "code should
## be that updating the list of candidates is enough and no other code changes need to happen to go
## to 8 seal pictures".)* A `Candidate` names what to place, whether it seals hard or soft, and
## nothing about *where* — `plan_day` works out every site from the street lattice and the day's
## tree, the same way for any def a candidate names. Adding the eight drawn seals of the next
## milestone is adding eight entries to `_build_candidates()`; nothing below reads a def's `id`.
##
## **Today's list is the catalogue's own furniture**, named in the TODO entry this class builds:
## `barricade` for hard (its own docstring already calls it "placed as a seal rather than rolled
## as an event"), and `construction`, `cafe_tables`, `market_stall` and `delivery_van` for soft.
## `homeless_yeller` is in the milestone's own list of "available from day 1" rows and is left out
## here on purpose — it carries no `obstructs_radius`, so it obstructs nothing and a pavement with
## only that on it is not sealed, soft or otherwise.
##
## **A sealed street's def is never the catalogue's own row.** `_sealed_variant` duplicates it and
## strips `scar_id`: the catalogue's `barricade` leaves a permanent scar and moves a block's arc
## (`EventManager._mark_the_block`) because *that* barricade is the aftermath of something that
## happened. A seal is a fact about *today's* tree — tomorrow's may run straight down this same
## street — so a seal that scarred the city would seal it for the rest of the run, which is a
## closure no `RouteTree` decided on. The same duplication also disables `EventInstance`'s
## pavement auto-centring for the hard band, which places its own bodies precisely; see
## `_hard_positions`.
##
## **The doorstep is exempt.** `ClosurePlanner.home_street(map)` is never sealed, for the same
## reason it is never closed: the home is a notch with one exit, so sealing it seals her in.
##
## **The winnability guarantee is not re-proved here, it is true by construction.** A seal never
## stands on tree ground or on the home street — the two things `RouteTree`/`ClosurePlanner`
## already guarantee a route through — so nothing here can cut the corridor. `tests/test_seals.gd`
## measures this over many seeds and days rather than asserting it at runtime, which is
## `docs/TODO.md`'s own reading of what changes here: `EventScheduler._ensure_the_city_is_still_
## walkable` stays the *accidental* guarantee for the catalogue's own placements; this placement
## needs no repair pass because nothing it does can break the thing it is measured against.
##
## **Alleys are not streets, and that is why they stay open by construction** — `StreetNetwork.
## segments()` never contains one, so the loop above never seals one. What is sealed here instead
## is a through-alley's *mouth*, and only when neither street it connects to is on today's tree:
## an alley that touches the corridor at either end is the way round a wall the design asks for,
## and one that touches it at neither end would only ever bridge two sealed streets — a second
## city behind the walls rather than a door through them. See `_seal_alley_mouths`.

enum Strength { HARD, SOFT }

## One thing the day may place as a seal. `def_ids` is one entry for `HARD` — spans the whole
## street, see `_hard_positions` — and two for `SOFT`, one per pavement; the two may name the same
## row twice or two different ones, both are "two obstacles facing each other" per the design.
class Candidate extends RefCounted:
	var id := ""
	var strength := Strength.SOFT
	var def_ids: Array[String] = []

static var _candidates: Array[Candidate] = []

static func candidates() -> Array[Candidate]:
	if _candidates.is_empty():
		_candidates = _build_candidates()
	return _candidates

## The only place a new picture is added. See the class doc.
static func _build_candidates() -> Array[Candidate]:
	return [
		_candidate("barricade_seal", Strength.HARD, ["barricade"]),
		_candidate("construction_pair", Strength.SOFT, ["construction", "construction"]),
		_candidate("cafe_pair", Strength.SOFT, ["cafe_tables", "cafe_tables"]),
		_candidate("market_pair", Strength.SOFT, ["market_stall", "market_stall"]),
		_candidate("delivery_pair", Strength.SOFT, ["delivery_van", "delivery_van"]),
	]

static func _candidate(id: String, strength: int, def_ids: Array[String]) -> Candidate:
	var found := Candidate.new()
	found.id = id
	found.strength = strength
	found.def_ids = def_ids
	return found

# ------------------------------------------------------------------- planning ---

## Every seal for the day: one per off-tree, real, non-home street, plus the mouths of any
## through-alley that rejoins the corridor at neither end. Returned as `EventScheduler.Planned`
## so the caller (`EventManager.start_day`) can simply append them to the day's plan.
static func plan_day(map: CityMap, day: int, tree: RouteTree,
		rng: RandomNumberGenerator) -> Array[EventScheduler.Planned]:
	var planned: Array[EventScheduler.Planned] = []
	if not tree:
		return planned
	var home := ClosurePlanner.home_street(map)
	for segment in StreetNetwork.segments():
		var key := segment.key()
		if not map.has_street(key) or tree.is_on_the_tree(key):
			continue
		if home and key == home.key():
			continue
		var candidate := _pick_candidate(day, rng)
		if not candidate:
			continue
		planned.append_array(_place(map, segment, candidate))
	planned.append_array(_seal_alley_mouths(map, tree, day))
	return planned

static func _pick_candidate(day: int, rng: RandomNumberGenerator) -> Candidate:
	var eligible: Array[Candidate] = []
	for candidate in candidates():
		if _eligible(candidate, day):
			eligible.append(candidate)
	if eligible.is_empty():
		return null
	return eligible[rng.randi_range(0, eligible.size() - 1)]

static func _eligible(candidate: Candidate, day: int) -> bool:
	for id in candidate.def_ids:
		var def := EventCatalogue.by_id(id)
		if not def or day < _effective_first_day(def):
			return false
	return true

## When a row may be used as a seal. Ordinary availability (`EventDef.available_on`) is stated
## over `scripted_day` for a `SCRIPTED` row, which is a day nobody plays — `barricade`'s own is 0,
## so it is never rolled by the ordinary scheduler at all, on purpose (see the class doc). A seal
## bypasses that gate and asks a question `available_on` cannot answer for a `SCRIPTED` row: which
## day is this row's own, narratively. `act_tag` is that answer — "act_tag against the act its
## first_day falls in" (`EventDef`'s own docstring) is the rule for every other row, so reading it
## the other way round for a `SCRIPTED` one is the smallest way to give it a day at all.
static func _effective_first_day(def: EventDef) -> int:
	if def.kind == GameEnums.EventKind.SCRIPTED:
		var index := clampi(def.act_tag - 1, 0, Tuning.ACT_START_DAYS.size() - 1)
		return Tuning.ACT_START_DAYS[index]
	return def.first_day

static func _place(map: CityMap, segment: StreetNetwork.Segment,
		candidate: Candidate) -> Array[EventScheduler.Planned]:
	if candidate.strength == Strength.HARD:
		return _place_hard(map, segment, candidate.def_ids[0])
	return _place_soft(map, segment, candidate.def_ids)

## A hard seal: the named row, repeated across the street's whole width so nothing can slip past
## on either side of it. See `_hard_positions` for how many copies that takes and why the count
## is a function of the row's own `obstructs_radius` rather than a fixed number.
static func _place_hard(map: CityMap, segment: StreetNetwork.Segment,
		def_id: String) -> Array[EventScheduler.Planned]:
	var def := _sealed_variant(EventCatalogue.by_id(def_id), true)
	var planned: Array[EventScheduler.Planned] = []
	for at in _hard_positions(map, segment, def):
		planned.append(EventScheduler.Planned.new(def, at))
	return planned

## A soft seal: one body per pavement, at the lane nearest the kerb — which is where a kerbed row
## like `delivery_van` already wants to be, and where any other row's own auto-centring
## (`EventInstance._centred_on_the_pavement_band`) puts it regardless of which of the pavement's
## two lanes this names.
static func _place_soft(map: CityMap, segment: StreetNetwork.Segment,
		def_ids: Array[String]) -> Array[EventScheduler.Planned]:
	var tiles := _cross_section_tiles(segment)
	var side_a := tiles[Tuning.SIDEWALK_WIDTH - 1]
	var side_b := tiles[Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH]
	var def_a := _sealed_variant(EventCatalogue.by_id(def_ids[0]), false)
	var def_b := _sealed_variant(EventCatalogue.by_id(def_ids[1]), false)
	var planned: Array[EventScheduler.Planned] = []
	planned.append(EventScheduler.Planned.new(def_a, map.tile_to_world(side_a)))
	planned.append(EventScheduler.Planned.new(def_b, map.tile_to_world(side_b)))
	return planned

## A candidate's def, made safe to place as a seal rather than roll as an event. See the class
## doc for why the scar and the finish-spawn are stripped unconditionally, on every candidate,
## rather than only on the ones known to carry one today — a ninth candidate gets the same
## protection without anybody having to remember to ask for it.
static func _sealed_variant(def: EventDef, suppress_recenter: bool) -> EventDef:
	var variant: EventDef = def.duplicate()
	variant.scar_id = ""
	variant.spawns_on_finish = ""
	if suppress_recenter and variant.pavement_side == EventDef.Pavement.ANY:
		variant.pavement_side = EventDef.Pavement.AT_THE_KERB
	return variant

## The street's own cross-section, one tile per lane, at the middle of the block: sidewalk,
## sidewalk, road, road, sidewalk, sidewalk in lattice order, whichever axis the street runs on.
static func _cross_section_tiles(segment: StreetNetwork.Segment) -> Array[Vector2i]:
	var rect := segment.tile_rect()
	var tiles: Array[Vector2i] = []
	if segment.horizontal:
		var mid_x := rect.position.x + rect.size.x / 2
		for row in Tuning.STREET_WIDTH:
			tiles.append(Vector2i(mid_x, rect.position.y + row))
	else:
		var mid_y := rect.position.y + rect.size.y / 2
		for column in Tuning.STREET_WIDTH:
			tiles.append(Vector2i(rect.position.x + column, mid_y))
	return tiles

## Where a hard seal's bodies stand, spaced so their circles cover the street edge to edge with
## no gap between them — the geometry a single `obstructs_radius` cannot promise on its own (a
## `barricade` at 62px reaches 124 of the street's 192, which is most of it and not all of it).
##
## **The count is a function of the row's own radius, not a constant.** `copies` is the fewest
## bodies whose circles still touch their neighbours across the whole width, so a wider or
## narrower future hard candidate gets exactly the coverage its own `obstructs_radius` calls for —
## the count is derived, never chosen per row, which is the whole of what "generic over the
## candidate list" asks for here.
##
## Positioned in world space directly rather than snapped to a tile, and paired with
## `_sealed_variant`'s pavement-side override: `EventInstance`'s own auto-centring would otherwise
## collapse two of these onto the same pavement-band midpoint and reopen the gap this exists to
## close.
static func _hard_positions(map: CityMap, segment: StreetNetwork.Segment,
		def: EventDef) -> Array[Vector2]:
	var world := map.tile_rect_to_world(segment.tile_rect())
	var width: float = world.size.y if segment.horizontal else world.size.x
	var radius := maxf(1.0, def.obstructs_radius)
	var copies := 1 if 2.0 * radius >= width else ceili(width / (2.0 * radius))
	var spacing := width / float(copies)
	var positions: Array[Vector2] = []
	if segment.horizontal:
		var along := world.position.x + world.size.x * 0.5
		for i in copies:
			positions.append(Vector2(along, world.position.y + spacing * (i + 0.5)))
	else:
		var along := world.position.y + world.size.y * 0.5
		for i in copies:
			positions.append(Vector2(world.position.x + spacing * (i + 0.5), along))
	return positions

# ----------------------------------------------------------------------- alleys ---

## Seals the mouths of every through-alley that touches the tree at neither end. See the class
## doc, "What alleys are for" — the smallest reading of a detail the design leaves open, taken
## rather than guessed at: an alley that touches the corridor at either end is kept open outright
## (the way round a wall), and one that touches it at neither is walled at both ends rather than
## left as a shortcut between two sealed streets.
static func _seal_alley_mouths(map: CityMap, tree: RouteTree,
		day: int) -> Array[EventScheduler.Planned]:
	var planned: Array[EventScheduler.Planned] = []
	var def_id := _best_alley_mouth_def(day)
	if def_id == "":
		return planned
	var mouth_def := _sealed_variant(EventCatalogue.by_id(def_id), true)
	for rect in map.alley_rects:
		# A through-alley can be built over by a later generation pass (`CityGenerator.
		# _make_the_pair_solid`), which does not retract it from `alley_rects` — so the ground is
		# checked rather than trusted.
		if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
			continue
		var vertical := rect.size.x < rect.size.y
		var block := map.block_at(map.tile_rect_to_world(rect).get_center())
		var side_a: int = StreetNetwork.Side.NORTH if vertical else StreetNetwork.Side.WEST
		var side_b: int = StreetNetwork.Side.SOUTH if vertical else StreetNetwork.Side.EAST
		var segment_a := StreetNetwork.beside_block(block, side_a)
		var segment_b := StreetNetwork.beside_block(block, side_b)
		var a_rejoins := segment_a != null and tree.is_on_the_tree(segment_a.key())
		var b_rejoins := segment_b != null and tree.is_on_the_tree(segment_b.key())
		if a_rejoins or b_rejoins:
			continue
		planned.append(_alley_mouth_plan(map, rect, vertical, true, mouth_def))
		planned.append(_alley_mouth_plan(map, rect, vertical, false, mouth_def))
	return planned

static func _alley_mouth_plan(map: CityMap, rect: Rect2i, vertical: bool, at_start: bool,
		def: EventDef) -> EventScheduler.Planned:
	var mouth: Rect2i
	if vertical:
		var y := rect.position.y if at_start else rect.end.y - 1
		mouth = Rect2i(Vector2i(rect.position.x, y), Vector2i(rect.size.x, 1))
	else:
		var x := rect.position.x if at_start else rect.end.x - 1
		mouth = Rect2i(Vector2i(x, rect.position.y), Vector2i(1, rect.size.y))
	return EventScheduler.Planned.new(def, map.tile_rect_to_world(mouth).get_center())

## The soft candidate whose single row best fills a two-tile alley mouth today — the widest
## `obstructs_radius` among today's eligible soft rows, since a wider body leaves less of the
## mouth's own 64px open beside it. Generic over the candidate list for the same reason `_place`
## is: a future candidate with a wider row simply wins this pick on the days it is eligible.
static func _best_alley_mouth_def(day: int) -> String:
	var best_id := ""
	var best_radius := 0.0
	for candidate in candidates():
		if candidate.strength != Strength.SOFT:
			continue
		for id in candidate.def_ids:
			var def := EventCatalogue.by_id(id)
			if not def or day < _effective_first_day(def):
				continue
			if def.obstructs_radius > best_radius:
				best_radius = def.obstructs_radius
				best_id = id
	return best_id
