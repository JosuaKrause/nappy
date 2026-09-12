class_name SealPlanner
extends RefCounted
## Seals every street off the day's route tree — the placement M64 exists for.
##
## The design is `docs/DECISIONS.md`, "Nothing off the path". The corridor
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
## tree, the same way for any def a candidate names.
##
## **The list carries eight distinct seal pictures** (`docs/DECISIONS.md`, "Eight seal pictures"),
## so no single barrier is the city's signature. `barricade_seal` uses the catalogue's own
## furniture; `construction_pair`, `cafe_pair`, `market_pair` and `delivery_pair` provide the
## supporting soft-furniture variants. `fallen_tree_seal`, `car_accident_seal`,
## `skip_scaffolding_pair`, `burst_main_seal`, `moving_van_pair`, `burnt_out_car_seal` and
## `collapsed_frontage_seal` are dedicated seal drawings, each backed by its own `SCRIPTED`,
## `scripted_day = 0`, `intensity = 0.0` row in `EventCatalogue` — see the class doc there, "seal
## pictures". `homeless_yeller` is excluded because it carries no `obstructs_radius`, so it
## obstructs nothing and a pavement with only that on it is not sealed, soft or otherwise.
##
## **A sealed street's def is never the catalogue's own row.** `sealed_variant` duplicates it and
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
## **The main road is exempt too, and that is a decision rather than an oversight.** *(2026-09-03,
## playtest 22: "a path should never go alongside the main road — main road by itself can be
## considered a blocker — paths can only cross the main road".)* `RouteTree` now refuses to route
## a strand along it (see its own class doc, "The main road"), so the spine is off the tree on
## every day by construction — which would make the loop below seal every segment of it, sidewalk
## to sidewalk, on every day of the run. It is already the worst ground in the game to stand on
## (`Tuning.EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER`, 0.6 against an ordinary street's 1.0), so making
## it *not a route* is enough — sealing it on top would be the harm playtest 22 reported rather than
## the fix, and `docs/CITY.md`'s constraint that she may cross it wherever she likes stands unmoved.
##
## **The winnability guarantee is not re-proved here, it is true by construction.** A seal never
## stands on tree ground or on the home street — the two things `RouteTree`/`ClosurePlanner`
## already guarantee a route through — so nothing here can cut the corridor. `tests/test_seals.gd`
## measures this over many seeds and days rather than asserting it at runtime, which is
## `docs/TODO.md`'s own reading of what changes here: `EventScheduler._ensure_the_city_is_still_
## walkable` stays the *accidental* guarantee for the catalogue's own placements; this placement
## needs no repair pass because nothing it does can break the thing it is measured against.
##
## **"Tree ground" includes the join, now.** `RouteTree._grow_the_trunk()` guarantees a coloured
## path from the home street outward to the rest of the tree even where every branch's own random
## walk happened to reach home a different way, so the sentence above did not have to grow a second
## clause for it — a seal never standing on tree ground already covers the ground between the
## doorstep and the corridor, because that ground is now tree ground like any other.
##
## **A final pass thins the seals**, after every street off the tree has one: a small fraction of
## the day's soft pairs drop one body, so a wrong turn stays open long enough to be taken rather
## than reading as a wall on sight. See `_thin_soft_pairs` for why this is not the repair pass
## `CLAUDE.md` warns against.
##
## **Alleys are not streets, and that is why they stay open by construction** — `StreetNetwork.
## segments()` never contains one, so the loop above never seals one. What is sealed here instead
## is a through-alley's *mouth*, and only when neither street it connects to is on today's tree:
## an alley that touches the corridor at either end is the way round a wall the design asks for,
## and one that touches it at neither end would only ever bridge two sealed streets — a second
## city behind the walls rather than a door through them. **And even then, only sometimes** —
## `Tuning.ALLEY_MOUTH_SEAL_CHANCE` rolls each qualifying alley rather than sealing every one of
## them every day, so the alley reads as an occasional exception rather than a wall of its own. See
## `_seal_alley_mouths`.
##
## **A crossing alley — one whose two mouths open onto two different regions' ground — is never one
## of these candidates**, whichever way the tree runs. `RegionPlanner` already decides it as a door
## or a wall of its own, from `Tuning.REGION_WALL_FIRST_DAY` on, and hands its rect's `position` to
## `skip` so this pass never rolls for it too. See `docs/CITY.md`, "Regions and the wall".

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
##
## **Eight seal pictures** (`docs/DECISIONS.md`, "Eight seal pictures"): reusable catalogue
## furniture and dedicated seal drawings share this one candidate list. The placement stays
## generic because adding or replacing a picture changes only an entry here. `barricade_seal`
## supplies the named stacked-barricade picture without a duplicate candidate.
static func _build_candidates() -> Array[Candidate]:
	return [
		_candidate("barricade_seal", Strength.HARD, ["barricade"]),
		_candidate("construction_pair", Strength.SOFT, ["construction", "construction"]),
		_candidate("cafe_pair", Strength.SOFT, ["cafe_tables", "cafe_tables"]),
		_candidate("market_pair", Strength.SOFT, ["market_stall", "market_stall"]),
		_candidate("delivery_pair", Strength.SOFT, ["delivery_van", "delivery_van"]),
		_candidate("fallen_tree_seal", Strength.HARD, ["fallen_tree"]),
		_candidate("car_accident_seal", Strength.HARD, ["car_accident"]),
		_candidate("skip_scaffolding_pair", Strength.SOFT, ["skip", "scaffolding"]),
		_candidate("burst_main_seal", Strength.HARD, ["burst_water_main"]),
		_candidate("moving_van_pair", Strength.SOFT, ["moving_van", "moving_van"]),
		_candidate("burnt_out_car_seal", Strength.HARD, ["burnt_out_car"]),
		_candidate("collapsed_frontage_seal", Strength.HARD, ["collapsed_frontage"]),
	]

static func _candidate(id: String, strength: int, def_ids: Array[String]) -> Candidate:
	var found := Candidate.new()
	found.id = id
	found.strength = strength
	found.def_ids = def_ids
	return found

# ------------------------------------------------------------------- planning ---

## Every seal for the day: one per off-tree, real, non-home, non-spine, non-boundary street,
## thinned by a small fraction, plus the mouths of any through-alley that rejoins the corridor at
## neither end. Returned as `EventScheduler.Planned` so the caller (`EventManager.start_day`) can
## simply append them to the day's plan.
##
## `skip` is a set of keys to leave alone on top of the ordinary exclusions — today's region
## boundary, both wall and door, from `Tuning.REGION_WALL_FIRST_DAY` on. It carries two kinds of
## key in one `Dictionary`, never colliding since they are different `Variant` types: a
## `StreetNetwork.Segment.key()` (`Vector3i`) for a boundary segment, checked in the loop below, and
## an alley rect's own `position` (`Vector2i`) for a **crossing alley**, checked by
## `_seal_alley_mouths`. **The wall is already the seal**, placed as its own hard band or alley-
## mouth pair by `RegionPlanner.plan_day` from the checkpoint row rather than from this candidate
## list, and a door is meant to stay a fully open crossing for the structure the milestone's second
## half places there — either would be two things standing in the same spot if this pass also
## sealed it. A `Dictionary` parameter rather than a reach into `_city` from here: `SealPlanner`
## stays a pure function of what it is handed, the same as every other call in this file.
##
## `held`, if given, gets every **hard** seal's segment key marked in it as it is placed —
## `CityMap.held_segments` itself, in the ordinary caller (`EventManager.start_day`), which passes
## it in and then plans `EventScheduler.build_day` against it so a hard seal's ground is never
## also offered to a catalogue row. A soft seal is not marked: its carriageway is still walkable,
## and a café on it is the price of that route (`docs/TODO.md`, "Events spawn inside a fully
## blocked street"). Left `{}` for a caller — a test, a rig — that only wants the placements.
static func plan_day(map: CityMap, day: int, tree: RouteTree,
		rng: RandomNumberGenerator, skip: Dictionary = {},
		held: Dictionary = {}) -> Array[EventScheduler.Planned]:
	# The walker-facing half of a soft seal — see `CityMap.soft_sealed_tiles` — is this function's
	# own output and nobody else's, so it is cleared and rebuilt here exactly the way `planned`
	# itself is, rather than trusting a caller to clear it first.
	map.clear_day_soft_seals()
	var planned: Array[EventScheduler.Planned] = []
	if not tree:
		return planned
	var home := ClosurePlanner.home_street(map)
	# Soft pairs are collected as `[segment, placed]` rather than `placed` alone, because the
	# thinning pass below needs the segment back to mark the surviving side's own pavement tiles in
	# `CityMap.soft_sealed_tiles` as well as to drop one body of the pair — see `_thin_soft_pairs`.
	var soft_pairs: Array = []
	for segment in StreetNetwork.segments():
		var key := segment.key()
		if not map.has_street(key) or tree.is_on_the_tree(key) or skip.has(key):
			continue
		if home and key == home.key():
			continue
		if _is_the_main_road(map, segment):
			continue
		var candidate := _pick_candidate(day, rng)
		if not candidate:
			continue
		var placed := _place(map, segment, candidate)
		if candidate.strength == Strength.SOFT:
			soft_pairs.append([segment, placed])
		else:
			planned.append_array(placed)
			held[key] = true
	planned.append_array(_thin_soft_pairs(map, soft_pairs, rng))
	planned.append_array(_seal_alley_mouths(map, tree, day, rng, skip))
	return planned

# -------------------------------------------------------------- the finale ---

## The escape's own seals: every street the two chains do not run through, plus both mouths of
## every alley they do not run through, all of them **hard**.
##
## **It takes a set of open cells rather than a `RouteTree`, and that is the whole difference.**
## A day grows a tree to several calm areas and counts two distinct routes to each; the finale has
## one ordered chain to each edge and *"no overlapping routes"*, so there is no tree to ask and the
## caller (`FinalePlanner`) hands over the cells its chains actually cover — `ReachabilityGrid`
## cells, `Vector2i`, the same two-tile cells the chains were grown on. Everything below is
## `plan_day`'s own placement code, unchanged, asked a different question about which streets are
## spared.
##
## Three things `plan_day` does that this does not, each for a reason the finale changes:
##
## - **No soft seals and no thinning.** A soft seal leaves the carriageway open, which is exactly
##   the wrong answer when the brief is *"a single path through the city"* — and the thinning pass
##   exists to let a wrong turn be taken and discovered, which is a day's lesson rather than the
##   climax's.
## - **The main road is sealed like anything else.** The day's exemption is that `RouteTree`
##   refuses to route along the spine and sealing it as well would wall the one street she is meant
##   to be free to cross. The finale's chains *end* on the spine — the tunnel is at its north end
##   and the bridge at its south — so the spine is chain ground where they run on it and ordinary
##   closed ground everywhere else, and leaving the rest of it open would join the two chains at
##   the one street that touches both exits.
## - **Every alley mouth off the chains is sealed, rather than a fraction of the qualifying ones.**
##   `Tuning.ALLEY_MOUTH_SEAL_CHANCE` exists so an alley reads as an occasional exception on an
##   ordinary day; one open alley in the finale is a second way through.
##
## The doorstep stays exempt for the reason it always is: the home is a notch with one exit.
static func plan_finale(map: CityMap, open_cells: Dictionary,
		rng: RandomNumberGenerator) -> Array[EventScheduler.Planned]:
	map.clear_day_soft_seals()
	var planned: Array[EventScheduler.Planned] = []
	var home := ClosurePlanner.home_street(map)
	for segment in StreetNetwork.segments():
		var key := segment.key()
		if not map.has_street(key) or runs_through(segment, open_cells):
			continue
		if home and key == home.key():
			continue
		planned.append_array(_place_hard(map, segment, _finale_candidate(rng).def_ids[0]))
	for rect in map.alley_rects:
		# A through-alley can be built over by a later generation pass, which does not retract it
		# from `alley_rects` — so the ground is checked rather than trusted, the same as
		# `_seal_alley_mouths` does.
		if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
			continue
		if _covers_any_cell(rect, open_cells):
			continue
		var vertical := rect.size.x < rect.size.y
		planned.append(alley_mouth_wall(map, rect, vertical, true, _FINALE_ALLEY_DEF))
		planned.append(alley_mouth_wall(map, rect, vertical, false, _FINALE_ALLEY_DEF))
	return planned

## Whether a chain actually **walks** this street, as opposed to clipping a corner of it.
##
## **Stated over the midpoint, because that is where a hard seal stands.** `_hard_positions` puts
## its bodies across the segment's own along-axis midpoint, so a street the chain only touches at
## one junction can be sealed there without closing anything the chain uses — and asking the looser
## question instead (does the chain touch this street at all) spares every street at every junction
## the walk turns at, which on a real city is three times as much open ground as the chain itself.
## *"No overlapping routes"* and *"nothing else open"* are the same requirement read twice, and
## this is where both of them are decided.
##
## Public because `FinalePlanner` asks the same question to decide where the finale's own events
## stand: the streets she can walk are the streets worth putting an army truck on, and two answers
## to that would put trucks on streets she cannot reach.
static func runs_through(segment: StreetNetwork.Segment, open_cells: Dictionary) -> bool:
	for tile in _cross_section_tiles(segment):
		if open_cells.has(tile / ReachabilityGrid.CELL):
			return true
	return false

## Whether any `ReachabilityGrid` cell inside `rect` is one of the chains' own. A cell is two tiles
## square and every cell is wholly street or wholly block (see `ReachabilityGrid`), so a street's
## own tile rect divides into whole cells and this is an exact question rather than an overlap
## test. Used for an alley, which is two tiles wide and has no midpoint worth distinguishing: a
## chain that is in it at all is through it.
static func _covers_any_cell(rect: Rect2i, open_cells: Dictionary) -> bool:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if open_cells.has(Vector2i(x, y) / ReachabilityGrid.CELL):
				return true
	return false

## The finale's own seal pictures, in the brief's own words: *"burnt cars, blockades, craters,
## etc. block paths through the city."* All four are `intensity = 0.0` rows, which is the same
## rule the day's candidates keep — *"static blockages in general shouldn't increase excitement"* —
## and it matters more here than on a day, because a loud wall either side of a 192px chain street
## would price the one route through the city as if she were walking through the walls.
##
## `roadblock`, whose own badge picture is `checkpoint_block.svg`, is deliberately not one of them
## for exactly that reason: it emits 13 over a 179px field and is manned, so a street lined with
## them would be the loudest thing on the map and none of it is ground she is meant to reach.
## Its guards appear in the finale anyway, on foot and hunting, which is what that row is here for.
static func _build_finale_candidates() -> Array[Candidate]:
	return [
		_candidate("finale_burnt_cars", Strength.HARD, ["burnt_out_car"]),
		_candidate("finale_barricade", Strength.HARD, ["barricade"]),
		_candidate("finale_rubble", Strength.HARD, ["collapsed_frontage"]),
		_candidate("finale_craters", Strength.HARD, ["impact_crater"]),
	]

static var _finale_candidates: Array[Candidate] = []

static func finale_candidates() -> Array[Candidate]:
	if _finale_candidates.is_empty():
		_finale_candidates = _build_finale_candidates()
	return _finale_candidates

## **No day gate.** `_eligible`/`_effective_first_day` answer *which act does this picture belong
## to*, which is a question about a fourteen-day calendar; the escape is the night after the last
## of those days, so every picture in the list above is available to it.
static func _finale_candidate(rng: RandomNumberGenerator) -> Candidate:
	var eligible := finale_candidates()
	return eligible[rng.randi_range(0, eligible.size() - 1)]

## What stands in an alley mouth off the chains. The widest silhouette in the finale's own list, so
## it leaves the least of the mouth's 64px open beside it — the same reason `_best_alley_mouth_def`
## picks by width on an ordinary day, decided once here rather than rolled, since the finale's list
## does not change with the day.
const _FINALE_ALLEY_DEF := "collapsed_frontage"

## Whether `segment` is the main road. See the class doc: never a seal candidate on a day, because
## `RouteTree` already refuses to route a strand along it, and sealing it too would wall the one
## street the design deliberately leaves open to cross. `plan_finale` above does not ask.
static func _is_the_main_road(map: CityMap, segment: StreetNetwork.Segment) -> bool:
	return not segment.horizontal and segment.a.x == map.main_road

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
	var def := sealed_variant(EventCatalogue.by_id(def_id), true)
	var planned: Array[EventScheduler.Planned] = []
	for at in _hard_positions(map, segment, def):
		planned.append(EventScheduler.Planned.new(def, at))
	return planned

## The public entry point to a **mouth** placement, for a caller outside the candidate list above.
## `RegionPlanner` uses this to build the region wall's own bodies from the `roadblock` row, which
## is not one of this file's eight seal pictures — the wall is a fact about where a region's
## perimeter runs, not a candidate this pass ever rolls for itself.
##
## **One tile deep, at `at_a`'s end, not the segment's midpoint** — the region wall's own geometry,
## different from `_place_hard`'s: a region boundary is not met the way an ordinary seal is, it
## bounds two regions from one end, and the whole of the segment's ground on the far side of the
## wall stays walkable right up to the one-tile band the wall itself occupies. The row's own shape
## is overridden to a point of `Tuning.TILE_SIZE` (32px) for the same reason — the catalogue row's
## own 60px reaches roughly two tiles along the street each way, which reaches clean over a through-
## alley's mouth at the next street along if the wall's body sits at the row's own width. The copy
## count across the street's `STREET_WIDTH` is still derived from the radius (`positions_across`)
## rather than chosen by hand; at 32px it comes out at three — the same three positions the
## checkpoint's own door structure stands its hut/gate/hut on, see `RegionPlanner`.
static func place_hard_on(map: CityMap, segment: StreetNetwork.Segment, def_id: String,
		at_a: bool) -> Array[EventScheduler.Planned]:
	var def := sealed_variant(EventCatalogue.by_id(def_id), true)
	# Overrides the row's own shape too, not only its `obstructs_radius`: `EventDef.validate()`
	# requires the two to agree, and a point of `Tuning.TILE_SIZE` is what a body this narrow
	# actually is here, whatever shape the row carries as a catalogue candidate.
	def.solid(GroundShape.point(Tuning.TILE_SIZE))
	var planned: Array[EventScheduler.Planned] = []
	var world := map.tile_rect_to_world(segment.mouth_rect(at_a))
	for at in positions_across(world, segment.horizontal, def.obstructs_radius):
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
	var def_a := sealed_variant(EventCatalogue.by_id(def_ids[0]), false)
	var def_b := sealed_variant(EventCatalogue.by_id(def_ids[1]), false)
	var planned: Array[EventScheduler.Planned] = []
	planned.append(EventScheduler.Planned.new(def_a, map.tile_to_world(side_a)))
	planned.append(EventScheduler.Planned.new(def_b, map.tile_to_world(side_b)))
	return planned

## The final pass: drop one body of `Tuning.SEAL_THINNING_FRACTION` of the day's soft pairs, so a
## wrong turn stays open long enough to be taken and discovered. *(Playtest 22, finding 6: "removing
## some obstacles randomly might lead the player down a bad path until they return to the actual
## path because they get stuck otherwise. this makes the actual path the player takes feel more
## organic, self-chosen, and earned.")*
##
## **Soft pairs only, by construction — never a hard seal or an alley mouth**, because neither is
## ever collected into `pairs`: `plan_day` only appends a `Strength.SOFT` placement here, and the
## hard and alley-mouth ones go straight into the day's plan untouched.
##
## **Drops one body of the pair, not the pair** — the smaller of the two readings `docs/TODO.md`
## names, taken because it is the one where the street still *looks* obstructed from the near side:
## an ordinary street with something on it, rather than a gate somebody visibly opened. The other
## body is never touched, so the pavement it stands on reads exactly as it did before. The
## alternative — drop the whole pair — is named there as cheap to pick instead if this reads as too
## subtle against a played day.
##
## **This is a removal pass and does not rediscover `CLAUDE.md`'s rule against repairing
## placements.** That rule guards against a later pass invalidating an earlier one's guarantee —
## the failure mode is a repair a reader cannot see was needed, resting a guarantee on code nothing
## checks. Removal cannot do that here: every guarantee the sealing carries
## (`tests/test_seals.gd`) is about *reaching* somewhere, and dropping a barrier only adds reachable
## ground, never takes it away. A pass that only ever removes obstruction is the one case `CLAUDE.md`
## names as safe.
static func _thin_soft_pairs(map: CityMap, pairs: Array, rng: RandomNumberGenerator) \
		-> Array[EventScheduler.Planned]:
	var kept: Array[EventScheduler.Planned] = []
	for entry: Array in pairs:
		var segment: StreetNetwork.Segment = entry[0]
		var pair: Array = entry[1]
		var bands := [_sidewalk_band_tiles(segment, true), _sidewalk_band_tiles(segment, false)]
		if pair.size() == 2 and rng.randf() < Tuning.SEAL_THINNING_FRACTION:
			var side := rng.randi_range(0, 1)
			kept.append(pair[side])
			_mark_soft_sealed(map, bands[side])
		else:
			kept.append_array(pair)
			_mark_soft_sealed(map, bands[0])
			_mark_soft_sealed(map, bands[1])
	return kept

## Both walker-lane tiles of one pavement side of `segment` — `Tuning.SIDEWALK_WIDTH` of them, not
## only the one a soft seal's own body stands on, so a walker on either lane of that pavement is
## shut out of it rather than only the one nearest the kerb. `near` is `side_a` in `_place_soft`'s
## own naming — the lower end of `_cross_section_tiles`' lattice order — and `false` is `side_b`.
static func _sidewalk_band_tiles(segment: StreetNetwork.Segment, near: bool) -> Array[Vector2i]:
	var tiles := _cross_section_tiles(segment)
	if near:
		return tiles.slice(0, Tuning.SIDEWALK_WIDTH)
	return tiles.slice(Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH, Tuning.STREET_WIDTH)

static func _mark_soft_sealed(map: CityMap, tiles: Array[Vector2i]) -> void:
	for tile in tiles:
		map.seal_soft_tile(tile)

## A candidate's def, made safe to place as a seal rather than roll as an event. See the class
## doc for why the scar and the finish-spawn are stripped unconditionally, on every candidate,
## rather than only on the ones known to carry one today — a ninth candidate gets the same
## protection without anybody having to remember to ask for it.
##
## **Public rather than the file-private helper it started as**, because `RegionPlanner` needs the
## same protection for the region door's own hut/gate/post bodies, which are not one of this
## file's own candidates — see `place_hard_on` and `alley_mouth_wall` for the precedent, and
## `RegionPlanner._add_door_bodies`/`_add_alley_door_bodies` for the new callers.
static func sealed_variant(def: EventDef, suppress_recenter: bool) -> EventDef:
	var variant: EventDef = def.duplicate()
	# `shape` is a plain `var` typed as a `RefCounted`, not a `Resource`, so it carries no storage
	# usage and `Resource.duplicate()` does not copy it — carried across by hand instead. Safe to
	# share the reference: `shape` is never mutated in place. See `EventDef.at_heat()` for the same
	# note against the other caller of `duplicate()`.
	variant.shape = def.shape
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
## `sealed_variant`'s pavement-side override: `EventInstance`'s own auto-centring would otherwise
## collapse two of these onto the same pavement-band midpoint and reopen the gap this exists to
## close.
static func _hard_positions(map: CityMap, segment: StreetNetwork.Segment,
		def: EventDef) -> Array[Vector2]:
	return positions_across(map.tile_rect_to_world(segment.tile_rect()), segment.horizontal,
			def.obstructs_radius)

## The same spacing arithmetic as `_hard_positions`, generalised to any world rect rather than a
## segment's own whole `tile_rect()`, and to a radius alone rather than one def's own
## `obstructs_radius` — `place_hard_on` hands it a one-tile-deep mouth rect, and `RegionPlanner`'s
## door structure hands it the same rect again to place three *different* defs (two huts and a
## gate) at the wall's own three-body spacing, which a def-typed signature could not do without a
## dummy def to carry the radius. Otherwise identical geometry either way: cover `world`'s
## cross-axis edge to edge with the fewest bodies whose circles still touch, centred on `world`'s
## own along-axis midpoint.
static func positions_across(world: Rect2, horizontal: bool, radius_in: float) -> Array[Vector2]:
	var width: float = world.size.y if horizontal else world.size.x
	var radius := maxf(1.0, radius_in)
	var copies := 1 if 2.0 * radius >= width else ceili(width / (2.0 * radius))
	var spacing := width / float(copies)
	var positions: Array[Vector2] = []
	if horizontal:
		var along := world.position.x + world.size.x * 0.5
		for i in copies:
			positions.append(Vector2(along, world.position.y + spacing * (i + 0.5)))
	else:
		var along := world.position.y + world.size.y * 0.5
		for i in copies:
			positions.append(Vector2(world.position.x + spacing * (i + 0.5), along))
	return positions

# ----------------------------------------------------------------------- alleys ---

## Seals the mouths of every through-alley that touches the tree at neither end — and only a
## `Tuning.ALLEY_MOUTH_SEAL_CHANCE` fraction of those, rolled once per qualifying alley. See the
## class doc, "What alleys are for" — the smallest reading of a detail the design leaves open, taken
## rather than guessed at: an alley that touches the corridor at either end is kept open outright
## (the way round a wall), and one that touches it at neither is a *candidate* to be walled at both
## ends rather than left as a shortcut between two sealed streets. **A candidate, not a certainty**
## — *(playtest 25, finding 5: "the probability of blocking off alleys should be way lower")* — since
## walling every one of them, every day, is what made an alley read as closed off wholesale rather
## than as the occasional exception the design wants.
static func _seal_alley_mouths(map: CityMap, tree: RouteTree,
		day: int, rng: RandomNumberGenerator, skip: Dictionary = {}) -> Array[EventScheduler.Planned]:
	var planned: Array[EventScheduler.Planned] = []
	var def_id := _best_alley_mouth_def(day)
	if def_id == "":
		return planned
	var mouth_def := sealed_variant(EventCatalogue.by_id(def_id), true)
	for rect in map.alley_rects:
		# A through-alley can be built over by a later generation pass (`CityGenerator.
		# _make_the_pair_solid`), which does not retract it from `alley_rects` — so the ground is
		# checked rather than trusted.
		if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
			continue
		# A crossing alley — one whose two mouths open onto two different regions' ground — is
		# `RegionPlanner`'s and nobody else's: it is already a door or a wall in today's region
		# plan, and `skip` is how the caller says so. See `SealPlanner.plan_day`'s own doc on the
		# two kinds of key `skip` carries.
		if skip.has(rect.position):
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
		# The roll is per qualifying alley, after the tree-connectivity rule already decided which
		# alleys are candidates at all — so the fraction is of "alleys that would have been sealed",
		# not of every alley in the city.
		if rng.randf() >= Tuning.ALLEY_MOUTH_SEAL_CHANCE:
			continue
		planned.append(_alley_mouth_plan(map, rect, vertical, true, mouth_def))
		planned.append(_alley_mouth_plan(map, rect, vertical, false, mouth_def))
	return planned

## The one-tile-deep rect at one end of a through-alley — the mouth a barrier, hard or soft, always
## stands at. Public because `RegionPlanner`'s own crossing-alley wall and `tests/test_regions.gd`'s
## flood check both need the rect itself rather than only the `Planned` `_alley_mouth_plan` builds
## from it.
static func alley_mouth_rect(rect: Rect2i, vertical: bool, at_start: bool) -> Rect2i:
	if vertical:
		var y := rect.position.y if at_start else rect.end.y - 1
		return Rect2i(Vector2i(rect.position.x, y), Vector2i(rect.size.x, 1))
	var x := rect.position.x if at_start else rect.end.x - 1
	return Rect2i(Vector2i(x, rect.position.y), Vector2i(1, rect.size.y))

static func _alley_mouth_plan(map: CityMap, rect: Rect2i, vertical: bool, at_start: bool,
		def: EventDef) -> EventScheduler.Planned:
	var mouth := alley_mouth_rect(rect, vertical, at_start)
	return EventScheduler.Planned.new(def, map.tile_rect_to_world(mouth).get_center())

## The public entry point to the same alley-mouth placement, for `RegionPlanner`'s own crossing-
## alley wall — one body per mouth, from the roadblock row rather than from this file's own
## candidate list, the same relationship `place_hard_on` has to `_place_hard`.
static func alley_mouth_wall(map: CityMap, rect: Rect2i, vertical: bool, at_start: bool,
		def_id: String) -> EventScheduler.Planned:
	var def := sealed_variant(EventCatalogue.by_id(def_id), true)
	return _alley_mouth_plan(map, rect, vertical, at_start, def)

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
