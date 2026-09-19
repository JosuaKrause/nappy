class_name EventScheduler
extends RefCounted
## Builds one day's event set from the run seed and the day index. See docs/EVENTS.md.
##
## Deterministic: the same seed and day always produce the same plan, which is what lets a
## player learn a run. Nothing here touches the global RNG.

## What the manager needs to spawn one instance.
##
## An `AHEAD_OF_PLAYER` plan has **no position**: the day decides that one more cat is owed and
## the director decides where, later, out of where the player turns out to walk. `is_placed()`
## is the question everything that reasons about geometry has to ask first.
class Planned extends RefCounted:
	var def: EventDef
	var position: Vector2
	var path := PackedVector2Array()
	## Which way it is drawn facing, for a stationary event whose siting decided that. A mobile
	## one gets its facing from the direction it is travelling and ignores this. A lorry backing
	## into a yard has to have its back to the yard, and only the placement knows which side of the
	## street the yard is on.
	var facing := Vector2.RIGHT

	## The shared boom state a `checkpoint_gate` plan's instance draws raised or lowered from —
	## `RegionPlanner.GateState`, built once per street door and carried here by
	## `RegionPlanner._add_door_bodies`. `null` for every plan but a gate's own.
	var gate_state: RegionPlanner.GateState = null

	func _init(definition: EventDef, at: Vector2,
			route := PackedVector2Array()) -> void:
		def = definition
		position = at
		path = route

	## The live instance, while this plan is streamed in. Owned by `EventManager`: a plan is the
	## day's intention and the instance is the few seconds it exists for, and those are not the
	## same span of time.
	var live: EventInstance = null
	## True once the event has run its course, so walking back past it does not start it again.
	var spent := false
	## True for something the *run* left here rather than something today rolled — a burnt-out
	## shell, a barricade. It is world history and the day may not tidy it away.
	var permanent := false
	## What the day placed this **for**, against today's corridor. See `GameEnums.BlockerRole` and
	## `EventScheduler._role_for`.
	##
	## It is recorded rather than re-derived because it is not a function of the def: the same
	## `cyclist` row is a wall on a day it is rolled and nothing at all when the director sites one
	## in front of her, and the telemetry map has to be able to say which. Nothing in the game reads
	## it — it decides where the plan went, it does not decide anything afterwards.
	var role := GameEnums.BlockerRole.NONE
	## Which set of mutually exclusive placements this one belongs to, or "" for anything that is
	## simply itself. A set piece is planned at **every** site of a covering set and the first one
	## she reaches is the one that happens; `EventManager._stream_in` spends the rest of the group
	## at that moment. See `EventScheduler._place_a_set_piece`.
	var set_piece_group := ""
	## True once it has been in the world at least once. What it is *for* is the bookkeeping
	## that must happen exactly once however many times an event is streamed in and out: a
	## burnt-out shell records the fire that made it the first time it is seen and never again.
	var was_live := false
	## How far the instance had got when it was last streamed out, so streaming it back in
	## **resumes** it rather than rewinding it. See `EventManager._stream_in`.
	var age := 0.0
	var travelled := 0.0
	## The `_noticed_at` a `pursues_within` instance held when it was last streamed out, or `INF` if
	## it had not yet noticed her — the third thing a stream-out has to carry beside `age` and
	## `travelled`, or a row streamed out mid-chase comes back `is_waiting()`, having forgotten it.
	## See `EventManager._stream_out()` and `_stream_in()`, and `EventInstance.resume()`.
	var noticed_at := INF

	## False for an event the day has budgeted but not sited.
	func is_placed() -> bool:
		return position != Vector2.INF

	## The points that bound this event — the corners of its route, or the one place it stands.
	func ends() -> PackedVector2Array:
		return path if path.size() >= 2 else PackedVector2Array([position])

	## Distance from a point to the nearest part of this event — the point it stands at, or the
	## nearest point of the route it will travel. A fire engine two streets away that is going
	## to come down *this* one has to be in the world before it sets off, or its whole telegraph
	## is spent somewhere nobody could see it.
	func distance_from(at: Vector2) -> float:
		if not is_placed():
			return INF
		if path.size() < 2:
			return position.distance_to(at)
		var best := INF
		for i in range(1, path.size()):
			best = minf(best, at.distance_to(
					Geometry2D.get_closest_point_to_segment(at, path[i - 1], path[i])))
		return best

## Budget grows with the day, so late days are denser as well as nastier. The target is **one event
## per block**, and the escalation is linear in the day: day 14 carries about half again as many
## events as day 1, with a larger share of them act III and IV rows rather than more dog walkers.
##
## **It is stated per block, because the target it encodes is per block.** A flat budget is a
## statement about one lattice size and nothing else: grow the city and the same events spread
## thinner, which is the density silently falling while every number in this file still reads as
## correct.
##
## **The budget is not the count**, and the difference is not small: part of it is spent on events
## the day then throws away, because `_ensure_one_usable_park` strips whatever reaches the calm she
## has not used and `_ensure_the_city_is_still_walkable` drops obstructions that would seal the
## city. So the number is set by *measuring what a day places* over several seeds. Re-measure it, do
## not re-derive it, if the catalogue's costs move.
##
## **And raising it alone does nothing** when the day's pool cannot spend it: the caps are what bind
## on an early day, which is *a budget the catalogue cannot spend is not density*. The caps move
## first and this follows, measured.
static func budget_for(day: int) -> int:
	var blocks := Tuning.CITY_BLOCKS.x * Tuning.CITY_BLOCKS.y
	return floori(blocks * (BUDGET_PER_BLOCK + day * BUDGET_PER_BLOCK_PER_DAY))

## Measured, not derived — see the note above. The floor is what day 1 costs and the slope is the
## escalation; both are per block of lattice, written as a measured whole-city figure over the
## 49-block lattice it was measured on so the arithmetic stays exact.
##
## **The floor accounts for the strip, which is the part that is easy to miss.**
## `_ensure_one_usable_park` removes the spoilers of every calm area she has not used, *after* the
## fill has already spent its budget — on a seed where no calm area comes out clean that is twenty
## events gone — so a floor set to the target plans to target and then falls short of it.
##
## As set, a typical day 1 places 121–125 against a target of one per block on an 11x11 lattice, and
## the worst seed measured 102. The floor moves days 1–7 and leaves day 14 alone, because **day 14
## is bound by the catalogue's caps rather than by the budget** — raising a budget only moves the
## days the budget is actually binding on.
const BUDGET_PER_BLOCK := 76.0 / 49.0
const BUDGET_PER_BLOCK_PER_DAY := 6.2 / 49.0

## Plans a day. `consumed_one_shots` is read and appended to, so a one-shot fires once
## per run.
##
## `used_calm` is every calm area she has settled in so far this act, most recent first. See
## `_spoil_the_park_she_used`, and `GameState.settled_this_act` for why it is an act rather than a
## night.
## `tree` is the day's corridor and it is what every placement below is stated against. The caller
## passes the one the closures were placed off; a rig with none to hand grows the same tree, since
## `RouteTree.for_day` is a pure function of the city's seed and the day number and touches no
## gameplay stream.
##
## `heat` is `GameState.resistance_progress`, and it is threaded through rather than read off the
## autoload so that a day is a pure function of its arguments: a rig that plans day 9 twice gets the
## same day twice whatever a run happens to have done. Every def below arrives already in the shape
## that heat puts it in — see `EventCatalogue.heated()` — so nothing in this file tests for it.
static func build_day(day: int, rng: RandomNumberGenerator, map: CityMap,
		consumed_one_shots: Array[String], scars: Array[Dictionary] = [],
		used_calm: Array[Vector2i] = [], tree: RouteTree = null,
		heat: int = 0) -> Array[Planned]:
	var planned: Array[Planned] = []
	# Captured before anything draws from it. Every phase below gets its own stream off this, which
	# is what makes a retried day the same day — see `_stream`.
	var base := rng.seed
	# Which tiles each kind of event may stand on, worked out at most once per day. See
	# `_ground_for`; it is threaded through rather than kept on the map because its lifetime is
	# exactly one day and a cache with a shorter life than its invalidation rule is a bug waiting.
	var ground := {}
	# Where the day's routes run, as a question about a tile. This is what turns *wall* and
	# *friction* from words into placements — see `_role_for` and `_ground_for`.
	var corridor := Corridor.of(tree if tree else RouteTree.for_day(map, day))

	# The calm she has not used yet, which nothing today may be placed near. See `_calm_to_leave_alone`.
	var leave_alone := _calm_to_leave_alone(map, used_calm)

	planned.append_array(_place_ambient(day, map, heat))
	planned.append_array(_place_scars(day, scars, heat))
	_place_scripted(day, _stream(base, 1), map, planned, ground, leave_alone, corridor, heat)
	_place_one_shots(day, _stream(base, 2), map, consumed_one_shots, planned, ground,
			leave_alone, corridor, heat)
	_spoil_the_parks_she_used(day, _stream(base, 3), map, planned, used_calm, heat)
	_fill_with_recurring(day, base, map, planned, ground, leave_alone, corridor, heat)
	_ensure_the_run_is_taught(day, planned, heat)

	_ensure_one_usable_park(map, planned, used_calm)
	_ensure_the_city_is_still_walkable(map, planned)
	return planned

# --------------------------------------------------------------- the finale ---

## The escape's own event set: what stands on the streets the two chains run through.
##
## **A budget is the wrong shape for this and that is why it is a separate entry.** `build_day`
## spends a per-block allowance over the whole city on a weighted roll, because a day is about
## variety and about not knowing which street she will take. The finale knows exactly which
## streets she can take — everything else is sealed — and it is the climax, so what it wants is a
## fixed count of a fixed handful of rows *per open street*: army trucks on the carriageways,
## masked men on foot and in vans, and the bursts that leave craters.
##
## **Four rows, three of which already exist and are not changed.** `military_convoy` is the truck,
## with the barricade it ordinarily leaves stripped — on an ordinary day that aftermath is the
## point of the row, and here a convoy is traffic rather than the thing that closed a street.
## `abduction` is the masked men in a van. `roadblock` at full heat is the masked men on foot: at
## `Tuning.RESISTANCE_GOAL` its guards leave the post, so it stands as a band across the road until
## she comes within `Tuning.HEAT_HUNTS_WITHIN` and then comes at her on foot as
## `guard_standing.svg` and `guard_lunging.svg` — see `EventInstance._draw_roadblock()`. Only the
## explosion is new.
##
## **Every density rule a day keeps is kept here.** `_build_placement` sites each one, `_room_around`
## refuses anything drawn inside something else, and the telegraph contract is the def's own and
## was checked at boot. The off-corridor exemption is untouched: these are on the corridor, and
## nothing here bypasses `_keeps_its_field_clear` — the two lethal rows in the list are a pursuer
## and a `WALL`, which is how they were already exempt on an ordinary day.
static func build_finale(map: CityMap, rng: RandomNumberGenerator,
		streets: Array[StreetNetwork.Segment]) -> Array[Planned]:
	var planned: Array[Planned] = []
	var trucks := _without_its_aftermath(EventCatalogue.by_id("military_convoy"))
	var vans := EventCatalogue.by_id("abduction")
	var masked := EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.RESISTANCE_GOAL)
	var bursts := EventCatalogue.by_id("finale_explosion")
	# **A tree and an event never share ground**, the finale's streets included — `docs/CITY.md`,
	# "Street trees". Scanned once for the whole plan rather than once per street per row: a city
	# plants its trees in `City.build()` and nothing in a walk moves them.
	var trees := StreetTrees.footprint_tiles(map)
	for segment in streets:
		_fill_a_finale_street(map, rng, segment, trucks, Tuning.FINALE_TRUCKS_PER_STREET, trees,
				planned)
		_fill_a_finale_street(map, rng, segment, vans, Tuning.FINALE_VANS_PER_STREET, trees,
				planned)
		_fill_a_finale_street(map, rng, segment, masked, Tuning.FINALE_GUARDS_PER_STREET, trees,
				planned)
		_fill_a_finale_street(map, rng, segment, bursts, Tuning.FINALE_EXPLOSIONS_PER_STREET,
				trees, planned)
	return planned

## `count` copies of one row on one street, sited the same way `_place_one` sites a day's: roll a
## tile of the right kind, build the placement, take the first that satisfies every rule and
## otherwise the roomiest one the tries found. A street with no ground of the right kind simply
## gets none of that row, which is the same failure direction a day's own placement has.
static func _fill_a_finale_street(map: CityMap, rng: RandomNumberGenerator,
		segment: StreetNetwork.Segment, def: EventDef, count: int, trees: Dictionary,
		planned: Array[Planned]) -> void:
	var candidates := _finale_ground(map, segment, def, trees)
	if candidates.is_empty():
		return
	for _copy in count:
		var best: Planned = null
		var best_room := -INF
		for _try in Tuning.EVENT_PLACEMENT_TRIES:
			var tile: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
			var candidate := _build_placement(def, map, tile, rng)
			if not candidate:
				continue
			candidate.role = _role_for(def)
			var room := _room_around(candidate, planned)
			if room == INF:
				best = candidate
				break
			if room > best_room:
				best_room = room
				best = candidate
		if best:
			planned.append(best)

## The tiles of one street a given row may stand on. Stated over the street's own rect rather than
## over the whole city the way `_open_ground_for` is, because the finale already knows which
## streets exist for it — there is no corridor weighting to apply and no closure to avoid, since
## the finale plans no closures at all.
##
## `trees` is `StreetTrees.footprint_tiles()`, refused here for the same reason
## `_open_ground_for` refuses it on a day: *(2026-09-12, the player: "trees read like obstacles
## (they add noise) so it makes detecting actual obstacles harder")*, and the climax is the one
## walk where telling an obstacle from scenery matters most. The footprint rather than the trunk
## tile, because the ground the canopy reaches over is ground a van would be standing in.
static func _finale_ground(map: CityMap, segment: StreetNetwork.Segment, def: EventDef,
		trees: Dictionary) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var rect := segment.tile_rect()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if trees.has(tile):
				continue
			if def.placement.has(map.tile_at(tile)) and map.is_open(tile):
				found.append(tile)
	return found

## A row with whatever it ordinarily leaves behind taken off it — the scar it records against the
## run and the successor it spawns when it finishes. The convoy is the only caller: what it leaves
## on an ordinary day is a barricade that closes that street for the rest of the run, which is a
## statement about a city that has thirteen more mornings in it.
##
## A **derived copy, never a mutation**, for the reason `EventDef.at_heat()` gives: the catalogue's
## rows are shared by every day of the run and validated once at boot. `shape` is carried across by
## hand because it is a plain `RefCounted` field with no storage usage, so `Resource.duplicate()`
## does not copy it; sharing the reference is safe, since a shape is never mutated in place.
static func _without_its_aftermath(def: EventDef) -> EventDef:
	var variant: EventDef = def.duplicate()
	variant.shape = def.shape
	variant.scar_id = ""
	variant.spawns_on_finish = ""
	return variant

## A `MAP` placement's own answer to `EventDef.pursues_within_on(day)` — a derived copy for the same
## reason `at_heat()`'s is one: the catalogue's rows are shared by every day of the run and validated
## once at boot, so a placement past `spawn_mode_switches_after_day` cannot set `pursues_within` on
## the shared resource itself without changing what every other day's placement of the row sees.
##
## Almost every row's `pursues_within_on(day)` agrees with its own `pursues_within` — the check
## below is `def` unchanged for all of them — because almost nothing sets
## `spawn_mode_switches_after_day` at all. `charging_dog` past `Tuning.RUN_TAUGHT_DAY` is the row
## that does not: `EventInstance.is_waiting()` and `_chase()` read `pursues_within` off whichever
## `EventDef` an instance was actually handed, so the day answer has to arrive as a different def
## rather than as a fact this function keeps to itself.
static func _for_day(def: EventDef, day: int) -> EventDef:
	var within := def.pursues_within_on(day)
	if is_equal_approx(within, def.pursues_within):
		return def
	var variant: EventDef = def.duplicate()
	variant.shape = def.shape
	variant.solid_parts = def.solid_parts
	variant.pursues_within = within
	return variant

## What the day is placing a row **for**, which is the only thing that makes *wall* and *friction*
## mean anything. See `docs/CITY.md`, "The words for it".
##
## Three of the four answers come straight off the design: lethal and expensive rows are the
## **walls** that bound the corridor, benign rows are **friction** on the route, and a one-shot is a
## **set piece** placed so that she actually meets it. The fourth is the interesting one.
##
## **`NONE` is not a leftover bin, it is the honest answer for anything the day did not site
## against the corridor at all.** An `AHEAD_OF_PLAYER` row is the case that proves it: `cat_dash` is
## sited by `EventDirector` in front of wherever she turns out to be walking, and the scheduler
## never chooses a tile for it. Calling it a wall would put a mark on the telemetry map claiming a
## placement that nothing made — which is the exact failure the picture exists to catch, arriving
## through the legend. `TOWARD_PLAYER` is sited by the same director for the same reason and gets
## the same answer. `spawn_mode_on(day)` is what this asks rather than `spawn_mode` alone, since a
## row like `charging_dog` answers `NONE` on `Tuning.RUN_TAUGHT_DAY` — a director moment, exactly
## like the cat — and `WALL` every day after, once it is `spawn_mode_after_first_day`'s `MAP`
## placement and the scheduler has chosen it a tile like any other lethal row.
##
## **A wall is not only the lethal rows.** The ground off the routes *ranges from very costly to
## deadly*, so an expensive row is a wall too and `Tuning.WALL_WORTH_OF_COST` is where the line
## falls. Cheap rows stay friction and stay on the corridor, which is what keeps the routes worth
## walking rather than merely survivable.
##
## It is stated over `walk_through_cost()` — the same integral `tests/test_danger.gd` orders the
## caret by — rather than over a new field, because *how expensive a row is* is a question the
## catalogue already answers, and a second answer to it is how two tables of one fact drift apart.
##
## **And a wall is also what cannot be walked past.** *(PLAYTEST-77: "a wall is also when you
## physically cannot walk through".)* Cost and passability are different questions and the cheap
## answer to the second one is not the first: a market stall costs 8.5 points to walk through, well
## under `WALL_WORTH_OF_COST`, and denies 58px of a 64px sidewalk, so there is no line past it on
## the sidewalk it stands on at any price. `_takes_a_whole_sidewalk` is that reading, taken from the
## row's own numbers exactly as the cost one is. What it buys is the placement: friction is aimed at
## the route, and a row aimed at the route she is meant to walk has to be one she can get past
## there.
##
## **`EventDef.scenery` is checked before the cost is, and it answers `NONE` rather than a fifth
## role.** *"Flocks are basically free already — don't count it as block, just count is
## scenery."* `pigeon_flock`'s 42-over-168px field crosses `WALL_WORTH_OF_COST` on the plain
## reading, so without the exemption it would be a wall pulled off every route the way any other
## expensive row is — which is exactly the placement the player overturned. `NONE` already means
## "placed for a reason that is not about the corridor at all," which is the flock's own case: it
## is still sited on a tile like everything else, just never weighted toward or away from one.
static func _role_for(def: EventDef, day: int = 0) -> GameEnums.BlockerRole:
	if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP or def.kind == GameEnums.EventKind.AMBIENT:
		return GameEnums.BlockerRole.NONE
	if def.scenery:
		return GameEnums.BlockerRole.NONE
	if def.kind == GameEnums.EventKind.ONE_SHOT:
		return GameEnums.BlockerRole.SET_PIECE
	if def.hard_fail or def.walk_through_cost() >= Tuning.WALL_WORTH_OF_COST \
			or _takes_a_whole_sidewalk(def):
		return GameEnums.BlockerRole.WALL
	return GameEnums.BlockerRole.FRICTION

## A private RNG for one phase of the day, derived from the day's seed and a salt.
##
## **A retried day has to be the same day, and one shared stream cannot deliver that.** Run the
## phases off a single sequence and anything that changes how much an earlier phase draws moves
## everything after it — and two things change between attempts by design:
##
## - `_place_one_shots` skips a one-shot the run has already spent. Skipping it *before* drawing its
##   `randf()` starts `_fill_with_recurring` one value earlier on the second attempt and produces a
##   different city's worth of events: measured on the day the fire engine runs, `homeless_yeller`
##   goes from two to eight and `cyclist` from none to three between two attempts at the same day.
## - `_place_scars` prepends what the run has burnt down, and every scar is one more plan for
##   `_room_around` to reject a placement against — and a rejection is a re-roll.
##
## Separate streams close the first completely and most of the second (see `_fill_with_recurring`).
## What is deliberately *not* closed: a scar that genuinely occupies the ground an event wanted still
## moves that event. That is the right answer — a fire that burnt a block down did happen, and the
## day should acknowledge it — and it is a handful of placements rather than the whole day.
static func _stream(base: int, salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [base, salt])
	return rng

## The day the run is taught cannot leave the lesson to a weighted roll.
##
## `EventDirector._teach_the_run` moves a pursuit to the head of the owed list on `RUN_TAUGHT_DAY`,
## and if the day happened not to buy one there is nothing to teach. `charging_dog` is weight 1.4 of
## a day-3 pool, so whole day 3s with none of them exist — and a player can reach act II never
## having been shown the one control the game will later require.
##
## It is added **outside** the budget rather than competing for it, and that is the exception being
## made honestly: everywhere else in this file the density is the budget, and a lesson that only
## happens when the dice agree is not a lesson. One event on one day of fourteen.
static func _ensure_the_run_is_taught(day: int, planned: Array[Planned], heat: int = 0) -> void:
	if day != Tuning.RUN_TAUGHT_DAY:
		return
	for plan in planned:
		if plan.def.pursues:
			return
	for def in EventCatalogue.available_on(day, heat):
		if not def.pursues or def.spawn_mode != EventDef.SpawnMode.AHEAD_OF_PLAYER:
			continue
		planned.append(Planned.new(def, Vector2.INF))
		Telemetry.note("plan", "day %d bought no pursuit, so the run lesson is added: %s"
				% [day, def.id])
		return

# ------------------------------------------------------- the city remembers ---

## Puts something on the calm block she settled in yesterday.
##
## Not because repetition is boring, but because **the game's only verb stops being a decision on
## day two**: a player who finds a good park on day 1 has no question left to answer, and route
## planning is the whole game. It is the same problem as a calm area being a lap rather than a
## route, one scale up: that one is about the destination, this is about *which* destination.
##
## Three things keep it from being a punishment for playing well, and all three are load-bearing:
##
## - **It spoils with events, not by taking the ground away.** The park is still there, still
##   calm ground, still walkable. Things are standing in it, and she can see that from
##   the street and decide. An event that could seal or end the day is never chosen for this.
## - **`_ensure_one_usable_park` is told to protect a different one**, so the day it creates is
##   still winnable and the alternative is still real rather than nominal.
## - **They are ordinary events, placed like any other.** They compete for no budget of their own
##   and are drawn from the same day's pool, so day 2 is not "day 1 plus a punishment", it is a day
##   whose noise happens to be somewhere she was counting on.
##
## **It has to cover the ground, not stand in it**, and one event does not.
##
## What denies calm ground is holding the meter above `EXCITEMENT_CALM_THRESHOLD` against
## `Tuning.CALM_ZONE_DENIAL_RATE`, 7.7/s — so a busker at intensity 19.3 has a *useful* radius of
## 157px whatever his 190px reach says, in a lot 704px across. That is a small share of one, and a
## day that rolls one spoiler for the block she used is still a day she settles in that same block.
## **The rate is fixed and the intensity is not**, so raising a row's intensity is the one thing
## that widens this: the busker's own reach grew by half when it was raised to clear the ground it
## stands on.
##
## So a spoiler is a **crowd**: one thing per cell of a grid laid over the calm ground, sized from
## what each of them can actually deny, capped by `SPOILERS_TO_DENY_A_PARK`. Each cell rolls its own
## def rather than repeating one — the fiction is that a park which is busy today is busy with
## several different things, and nine copies of one sprite in a field read as a duplicate, which is
## exactly what the spacing rule at `_room_around` prevents everywhere else.
##
## **Every area she has used this act, not just last night.** One night's memory makes day 2 a fresh
## decision and day 3 the same decision as day 1; an act's memory is what turns *find a different
## park* into *find your way around the city*. The city forgets at the act boundary, which is the
## only good news a run ever gets.
##
## One is always left alone whatever the memory says: the guarantee that a day is winnable outranks
## the guarantee that it is a fresh decision, and `MIN_CALM_BLOCKS` is sized so that the two do not
## have to fight — an act's worth of days plus one in reserve.
##
## Silent for anywhere she did not settle, or that is no longer calm.
static func _spoil_the_parks_she_used(day: int, rng: RandomNumberGenerator, map: CityMap,
		planned: Array[Planned], used: Array[Vector2i], heat: int = 0) -> void:
	var spoilable := map.calm_blocks.size() - 1
	for block in used:
		if spoilable <= 0:
			return
		if block.x >= 0 and block in map.calm_blocks:
			spoilable -= 1
			_spoil_one_park(day, rng, map, planned, block, heat)

static func _spoil_one_park(day: int, rng: RandomNumberGenerator, map: CityMap,
		planned: Array[Planned], block: Vector2i, heat: int = 0) -> void:

	var lot := _calm_rect(map, block)
	var open: Array[Vector2i] = []
	for tile in map.rect_tiles(lot):
		if not map.is_closed(tile):
			open.append(tile)
	if open.is_empty():
		return

	var ground := map.tile_rect_to_world(lot)
	var pool := _things_to_put_in_a_park(day, ground, heat)
	if pool.is_empty():
		return

	var placed: Array[String] = []
	for cell in _spoiling_grid(ground, pool):
		var def := _pick_by_what_it_denies(pool, rng)
		# Snapped to the nearest open tile of the lot, so nothing lands on a closed street or
		# outside the calm ground the cell was measured from.
		var at := map.tile_to_world(_nearest_of(open, map.world_to_tile(cell)))
		planned.append(Planned.new(def, at))
		placed.append(def.id)
	if placed.is_empty():
		return
	Telemetry.note("roll", "%s in the park she used yesterday, %s"
			% [", ".join(placed), TelemetryLog.tile(block)])

## Rolls one of the pool, weighted by how much ground it can actually take.
##
## Everywhere else in the scheduler a def's `weight` is how *common* it is, which is a statement
## about a city. Here the job is covering a lot, and what a row denies goes as the square of its
## reach — a busker covers several times the ground a market stall does — so the roll is by area
## as well as by weight, and the quiet rows become the garnish on a spoiled park rather than half
## of it. It stays a roll rather than becoming "always the
## loudest" for the reason the mix exists at all: a park that is busy today is busy with several
## different things, and one repeated sprite reads as a duplicated sprite.
static func _pick_by_what_it_denies(defs: Array[EventDef], rng: RandomNumberGenerator) -> EventDef:
	var weights: Array[float] = []
	var total := 0.0
	for def in defs:
		var reach := _denial_radius(def)
		var weight := def.weight * reach * reach
		weights.append(weight)
		total += weight
	var roll := rng.randf() * total
	for i in defs.size():
		roll -= weights[i]
		if roll <= 0.0:
			return defs[i]
	return defs[defs.size() - 1]

## The points a spoiler goes at: a grid over the calm ground, spaced by what one of them denies.
##
## The spacing is the **average** denial radius of the pool rather than any one row's, because which
## def lands in which cell is a roll and the grid has to be laid out before the rolls happen.
static func _spoiling_grid(ground: Rect2, pool: Array[EventDef]) -> Array[Vector2]:
	var reach := 0.0
	for def in pool:
		reach += _denial_radius(def)
	reach = maxf(reach / float(pool.size()), float(Tuning.TILE_SIZE))

	# Cells wide enough that two neighbours' fields just meet, then thinned until the cap is met:
	# a lot too big to be covered by `SPOILERS_TO_DENY_A_PARK` things is covered as evenly as that
	# many can manage rather than densely in one corner.
	var columns := maxi(1, ceili(ground.size.x / (reach * 2.0)))
	var rows := maxi(1, ceili(ground.size.y / (reach * 2.0)))
	while columns * rows > Tuning.SPOILERS_TO_DENY_A_PARK:
		if columns >= rows:
			columns -= 1
		else:
			rows -= 1

	var points: Array[Vector2] = []
	for row in rows:
		for column in columns:
			points.append(ground.position + Vector2(
					ground.size.x * (column + 0.5) / float(columns),
					ground.size.y * (row + 0.5) / float(rows)))
	return points

## How far from a source calm ground stops being usable.
##
## **Not the outer radius**, which is where it stops reaching at all. Anywhere a source emits less
## than `Tuning.CALM_ZONE_DENIAL_RATE` (7.7/s) is somewhere she can still settle — and for every
## act I row that is most of its own field. Getting this wrong is how one busker was ever thought
## to spoil a park.
##
## **The rate is its own constant rather than the calm ground's live decay**, because *which rows
## may stand beside a park* is a decision about the parks and not about how fast the pram settles.
## Read off the decay, every rise in the walking rate would admit louder rows here as a side
## effect of a change nobody made about parks.
##
## **The zero case is not the line rules' zero case.** `_reach_above` answers nothing at all for a
## row quieter than the rate it is asked about, which is right there — ground a walk nets the meter
## down in is not denied — and wrong here: a source she is standing on top of keeps her awake
## whatever its rate does further out, so the floor is its own `inner_radius`.
static func _denial_radius(def: EventDef) -> float:
	return maxf(def.inner_radius, _reach_above(def, Tuning.CALM_ZONE_DENIAL_RATE))

static func _nearest_of(tiles: Array[Vector2i], to: Vector2i) -> Vector2i:
	var best := tiles[0]
	var best_distance := INF
	for tile in tiles:
		var distance := Vector2(tile - to).length_squared()
		if distance < best_distance:
			best_distance = distance
			best = tile
	return best

## The things that may be put in the park she used yesterday.
##
## Deliberately narrow: nothing lethal, nothing that closes the ground, nothing mobile. A spoiled
## park has to be a park she can *see* is spoiled and walk away from — an abduction sitting in it
## would be a punishment for having settled there, and a barricade would be the ground taken
## away rather than made noisy, which is the thing this rule promises not to do.
##
## **The body test is a width, not `obstructs_radius > 0`.** Once everything that stands still has a
## body the two stop meaning the same thing: a busker is 18px across in a lot 704px wide, so he is
## loud and he is walked around, which is the whole job. `OBSTRUCTION_A_PARK_CAN_HOLD` is where that
## stops being true.
##
## **And the allowance depends on the ground.** A body that is nothing in a four-block calm zone is
## a wall across a four-tile courtyard, and a fixed number cannot be both — so it is a sixteenth of
## the shortest side of the calm ground, floored at that constant. That is what lets a market take
## over a whole park and keeps it out of a back yard.
static func _things_to_put_in_a_park(day: int, ground: Rect2, heat: int = 0) -> Array[EventDef]:
	var allowed := maxf(Tuning.OBSTRUCTION_A_PARK_CAN_HOLD,
			minf(ground.size.x, ground.size.y) / 16.0)
	var suitable: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, heat):
		if def.hard_fail or def.mobile:
			continue
		if def.obstructs_radius > allowed:
			continue
		if def.spawn_mode != EventDef.SpawnMode.MAP:
			continue
		suitable.append(def)
	return suitable

## Permanent marks left by earlier days, placed again exactly where they happened.
static func _place_scars(day: int, scars: Array[Dictionary], heat: int = 0) -> Array[Planned]:
	var planned: Array[Planned] = []
	for scar in scars:
		if int(scar["since_day"]) >= day:
			continue
		var def := EventCatalogue.by_id(String(scar["id"]))
		if def:
			var plan := Planned.new(EventCatalogue.heated(def, heat), scar["position"])
			plan.permanent = true
			planned.append(plan)
	return planned

# ----------------------------------------------------------------- placement ---

static func _place_ambient(day: int, map: CityMap, heat: int = 0) -> Array[Planned]:
	var planned: Array[Planned] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.AMBIENT, day, heat):
		match def.ambient_source:
			EventDef.AmbientSource.PLAYGROUND:
				for rect in map.playgrounds:
					planned.append(Planned.new(def, map.tile_rect_to_world(rect).get_center()))
			_:
				pass
	return planned

static func _place_scripted(day: int, rng: RandomNumberGenerator, map: CityMap,
		planned: Array[Planned], ground := {}, leave_alone: Array[Rect2] = [],
		corridor: Corridor = null, heat: int = 0) -> void:
	for def in EventCatalogue.of_kind(GameEnums.EventKind.SCRIPTED, day, heat):
		var placement := _place_one(def, day, rng, map, planned, ground, leave_alone, corridor)
		if placement:
			planned.append(placement)

static func _place_one_shots(day: int, rng: RandomNumberGenerator, map: CityMap,
		consumed: Array[String], planned: Array[Planned], ground := {},
		leave_alone: Array[Rect2] = [], corridor: Corridor = null, heat: int = 0) -> void:
	for def in EventCatalogue.of_kind(GameEnums.EventKind.ONE_SHOT, day, heat):
		if def.id in consumed:
			continue
		# Spread a one-shot over the days it is eligible for rather than always firing it
		# on the first: 1/n chance per remaining day makes it feel like an accident.
		var remaining := maxi(1, (def.last_day if def.last_day > 0 else def.first_day + 2) - day + 1)
		# Hoisted out of the comparison purely so it can be written down. A one-shot depends
		# on which days the run has already spent, so no seed reproduces it from the outside:
		# this roll is part of the story of the run and nothing else records it.
		var roll := rng.randf()
		var threshold := 1.0 / float(remaining)
		if roll > threshold:
			Telemetry.note("roll", "one-shot %s: %.2f > %.2f — not today"
					% [def.id, roll, threshold])
			continue
		var sited := _place_a_set_piece(day, def, rng, map, planned, ground, leave_alone, corridor)
		if sited.is_empty():
			# The roll passed and the city had nowhere to put it, so the one-shot is *not*
			# consumed and will be rolled for again tomorrow. Worth a line of its own: from
			# the outside this looks identical to a roll that failed.
			Telemetry.note("roll", "one-shot %s: %.2f <= %.2f but nowhere to place it"
					% [def.id, roll, threshold])
			continue
		planned.append_array(sited)
		consumed.append(def.id)
		var where: Array[String] = []
		for placement in sited:
			where.append(TelemetryLog.tile(map.world_to_tile(placement.position)))
		Telemetry.note("roll", "one-shot %s: %.2f <= %.2f — waiting at %s"
				% [def.id, roll, threshold, ", ".join(where)])

## A set piece, planned at **every** site of a covering set.
##
## An authored one-shot has to be *met*, and the important half of how is what this does **not** do:
## it does not choose a site on the route she took, because that would need to know which route she
## took. It chooses a set that **every** route touches, and the one she reaches is the one that
## fires. The guarantee is structural, so nothing has to predict her.
##
## **A bundle is not a guarantee, and this is the caller where that bites.** Two distinct routes to
## one area share no street by construction, so no single site can ever cover both — the covering
## set is two to six streets, and code here that expects one is looking for a *tile she must cross*,
## which the city is built not to have. `RouteTree.covering_sites` carries the arithmetic and the
## warning.
##
## The placements are mutually exclusive rather than several fire engines: they share a
## `set_piece_group`, and `EventManager._stream_in` spends the rest of the group the moment one of
## them enters the world. That is also where a scar is recorded, so a run gets exactly one fire
## however many streets were offered.
##
## **The fallback is a placement anywhere**, and it is the honest failure direction: a day with no
## corridor to speak of — no reachable calm, or a covering set whose streets carry none of this
## row's ground — should still fire the one authored thing it has. A one-shot that never fires is a
## fairness contract and a silhouette spent on nothing, which is the complaint this whole item
## exists to answer.
static func _place_a_set_piece(day: int, def: EventDef, rng: RandomNumberGenerator, map: CityMap,
		already: Array[Planned], ground: Dictionary, leave_alone: Array[Rect2],
		corridor: Corridor) -> Array[Planned]:
	var made: Array[Planned] = []
	var sites := corridor.sites() if corridor else ([] as Array[Vector3i])
	for site in sites:
		# The ones already made count for spacing like anything else: two of the same row a few
		# pixels apart is what `EVENT_SPACING_SAME` is for, and two candidate sites can be adjacent.
		var beside: Array[Planned] = already.duplicate()
		beside.append_array(made)
		var placement := _place_one(def, day, rng, map, beside, ground, leave_alone, corridor, site)
		if placement:
			placement.set_piece_group = "%s@%d" % [def.id, day]
			made.append(placement)
	if made.is_empty():
		var anywhere := _place_one(def, day, rng, map, already, ground, leave_alone, corridor)
		if anywhere:
			# **The fallback carries the group too, and it is a group of one.** Every other
			# one-shot placement is tagged, and `EventManager._stream_in` spends the rest of a
			# group the moment one of it fires — so an untagged placement is a one-shot that can
			# never be spent that way, silently exempt from the machinery the row is written
			# against. A group of one spends nothing and costs nothing; being outside the group
			# system is what costs.
			anywhere.set_piece_group = "%s@%d" % [def.id, day]
			made.append(anywhere)
	return made

## Fills the day's budget, **one stream per attempt**.
##
## The stream is derived from the attempt number rather than shared across the
## whole fill, so how much any one placement draws — `_place_one` re-rolls up to
## `EVENT_PLACEMENT_TRIES` times and returns early when a candidate is perfect — cannot move the
## placements after it. That is what makes a retried day recognisably the same day even when the
## run's own history has changed the ground: a scar still displaces the events it actually stands
## on, and every other event is where it was yesterday.
static func _fill_with_recurring(day: int, base: int, map: CityMap,
		planned: Array[Planned], ground := {}, leave_alone: Array[Rect2] = [],
		corridor: Corridor = null, heat: int = 0) -> void:
	var eligible := EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, heat)
	if eligible.is_empty():
		return

	var budget := budget_for(day)
	var counts := {}
	# Bounded rather than while-true: a catalogue where nothing affordable remains would
	# otherwise spin forever.
	for attempt in budget * 4:
		if budget <= 0:
			break
		var affordable: Array[EventDef] = []
		for def in eligible:
			if def.cost <= budget and int(counts.get(def.id, 0)) < def.max_per_day:
				affordable.append(def)
		if affordable.is_empty():
			break
		var rng := _stream(base, FILL_SALT + attempt)
		var def := _pick_weighted(affordable, rng)
		var placement := _place_one(def, day, rng, map, planned, ground, leave_alone, corridor)
		if not placement:
			continue
		planned.append(placement)
		counts[def.id] = int(counts.get(def.id, 0)) + 1
		budget -= def.cost

## Where the per-attempt streams start, far enough above the phase salts in `build_day` that the
## two sets can never collide however many phases are added.
const FILL_SALT := 1000

static func _pick_weighted(defs: Array[EventDef], rng: RandomNumberGenerator) -> EventDef:
	var total := 0.0
	for def in defs:
		total += def.weight
	var roll := rng.randf() * total
	for def in defs:
		roll -= def.weight
		if roll <= 0.0:
			return def
	return defs[defs.size() - 1]

## Picks a tile of an allowed type and builds the path, if the event moves.
##
## `already` is what the day has planned so far, and it is what keeps the density legible.
## Placement is a uniform random tile, so without a spacing rule the only thing keeping two dog
## walkers off one stretch of pavement is a low cap — which is a coincidence rather than a rule.
## Several candidates are offered and the first that clears `EVENT_SPACING_SAME` from its own kind
## and `EVENT_SPACING_ANY` from everything else wins.
##
## The fallback is the roomiest candidate offered rather than nothing, because a scripted event
## has to happen: on a map with fifty events on it the honest answer is the best spot left.
static func _place_one(def: EventDef, day: int, rng: RandomNumberGenerator, map: CityMap,
		already: Array[Planned] = [], ground := {}, leave_alone: Array[Rect2] = [],
		corridor: Corridor = null, site := NO_SITE) -> Planned:
	var role := _role_for(def, day)
	# An `AHEAD_OF_PLAYER` or `TOWARD_PLAYER` event is budgeted here and sited by `EventDirector`
	# while the player walks. Costing it here rather than giving the director its own allowance is
	# deliberate: the cat competes with the café tables and the roadworks for the same day, so
	# making the cat matter cannot quietly make the day denser as well. Asked over `spawn_mode_on
	# (day)` rather than `spawn_mode` alone, so a row like `charging_dog` — director-sited on the
	# day it teaches the run, map-placed every day after — is sited the way that day actually asks
	# for.
	if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
		return Planned.new(def, Vector2.INF)
	def = _for_day(def, day)

	var open_candidates := _ground_for(def, map, ground, corridor, role, site)
	if open_candidates.is_empty():
		return null
	# A local reweight rather than a change to `_ground_for`'s own cache: `alley_robbery` shares
	# every field that cache is keyed on, so biasing the cached array would bias the robber's
	# ground too. Only the mouse asks the question at all.
	if def.id == _MOUSE_ID:
		open_candidates = _prefer_beside_a_sack_pile(open_candidates, map, day)

	var best: Planned = null
	var best_room := -INF
	for _try in Tuning.EVENT_PLACEMENT_TRIES:
		var tile: Vector2i = open_candidates[rng.randi_range(0, open_candidates.size() - 1)]
		var candidate := _build_placement(def, map, tile, rng)
		if not candidate:
			continue
		candidate.role = role
		# **A pacing row's role is decided here rather than in `_role_for`**, because what makes a
		# man walking a beat passable is where the beat runs and not what he emits: one that reaches
		# a junction can be left at the crossing there while he is at the far end of his loop, and
		# one that stays between two junctions cannot be left at all. The first is friction and
		# belongs on the route like any other timing problem; the second is a wall and takes a
		# wall's one rule with it — never on ground a route runs along. See
		# `_a_pacing_beat_walls_a_sidewalk`.
		if _a_pacing_beat_walls_a_sidewalk(candidate, map):
			candidate.role = GameEnums.BlockerRole.WALL
			if corridor and corridor.carries_a_route(tile):
				continue
		# Before the spacing, because this one is about the *ground* rather than about what is
		# already on it, and because it can never bend.
		if _reaches_any(candidate, leave_alone):
			continue
		# And before the spacing for the same reason: a crossing a route has no way around is
		# ground the row may not have, not a preference that bends. See
		# `_leaves_the_route_junctions_open`.
		if not _leaves_the_route_junctions_open(candidate, map, corridor, ground, already):
			continue
		# And the same for the stretch between two junctions, asked of the sidewalk the tree is
		# actually walked along rather than of the street: the far side of a street answers a van,
		# and nothing answers a van on the side the route is drawn down. See
		# `_leaves_the_routes_sidewalk_open`.
		if not _leaves_the_routes_sidewalk_open(candidate, map, corridor, ground, already):
			continue
		# And the opening a pacing row's beat leaves is ground in its own right: the rows reaching
		# one route street are asked together whether a walk along it survives, so nothing stands in
		# the one end the yeller is away from. See `_leaves_a_pacing_beats_opening`.
		if not _leaves_a_pacing_beats_opening(candidate, map, corridor, already):
			continue
		var room := _room_around(candidate, already)
		if room == INF:
			return candidate
		if room > best_room:
			best_room = room
			best = candidate
	# Nothing comes back when every candidate broke a rule that does not bend — a lethal event
	# with no clear ground, or a full pavement. The caller re-rolls; a scripted event that
	# cannot be placed simply does not happen, which is the right failure direction.
	return best

## The tiles an event of this kind may stand on today, worked out once and kept for the rest of
## the day's planning.
##
## The answer is two passes over every tile of the right type, and a sidewalk is five thousand of
## them — while `_fill_with_recurring` asks the question once per attempt, which on a fourteenth day
## is over four hundred times. Nothing it depends on can move inside one `build_day`: the grid was
## repainted at dawn and the day's closures are already on the map.
##
## The key is the *question* rather than the event, because almost every row in the catalogue asks
## the same one — a pavement, either side, for this role — so one list serves most of the day. The
## order matters: the placement roll is an index into this array and a day has to be reproducible
## from its seed.
##
## **The role is part of the question, and it is answered the way the precinct weight is**: by how
## many times a tile is *offered*, rather than by a rule downstream. Everything that reads this
## array — the roll, the spacing, the room measurement — keeps working unchanged, which is why this
## is worth copying rather than inventing a second mechanism beside it.
##
## **The role's list is built out of the roleless one rather than beside it**, and that is a cost
## decision with a number behind it. The scan is the expensive half — two passes over every sidewalk
## in the city, with a closure test, a doorstep test and a kerb test on each — and doing it once per
## role doubles the suite's time on its own. The role only ever *re-weights* tiles the scan already
## accepted, so it is a second pass over a list that is already in memory.
static func _ground_for(def: EventDef, map: CityMap, ground: Dictionary,
		corridor: Corridor = null, role := GameEnums.BlockerRole.NONE,
		site := NO_SITE) -> Array[Vector2i]:
	var base := _open_ground_for(def, map, ground)
	if not corridor or role == GameEnums.BlockerRole.NONE:
		return base
	# The key is the *question*, and `hard_fail` is part of it since the wall band gained a
	# gradient: two lethal rows share an answer and a lethal row and a costly one no longer do.
	# `has_a_spread` joined it for the same reason M64 added it to `_open_ground_for`'s own key: a
	# corner is off the question for two rows sharing every other answer only when one of them
	# actually has an orientation to be wrong about on it. Without this a plain silhouette processed
	# first quietly hands its unfiltered `base` to a spread row asking the identical other four
	# questions, and the corner refusal never runs at all.
	var key := "%s|%d|%d|%s|%s|%s" % [def.placement, def.pavement_side, role, site, def.hard_fail,
			EventInstance.has_a_spread(def)]
	if ground.has(key):
		return ground[key]
	var aimed: Array[Vector2i] = []
	# **A set piece is placed on one named street**, so this half is containment rather than a
	# weight. The rect is the street itself and not a radius round it: a street is the unit every
	# other placement decision in this milestone is stated in, and a set piece has to be something
	# she walks past on the way through rather than something near where she walked.
	var named := StreetNetwork.by_key(site) if site != NO_SITE else null
	var only := named.tile_rect() if named else Rect2i()
	var refuses_required_alleys := _refuses_required_alleys(def)
	for tile in base:
		if site != NO_SITE:
			if only.has_point(tile):
				aimed.append(tile)
			continue
		# **No robber stands in an alley she has to walk down.** An alley the day's corridor runs
		# through — `corridor.depth(tile) == 0`, the `INSIDE` band — is ground she has no way
		# around, and `alley_robbery`'s own design note is that "a robbery has no telegraph you
		# could see coming, and it never did": a risk with no warning is only fair on ground she
		# chose to enter. See `docs/DECISIONS.md`, M64, "and no robber stands in an alley she has to
		# walk down."
		if refuses_required_alleys and corridor.depth(tile) == 0:
			continue
		for _copy in _copies_of(tile, corridor, role, def.hard_fail):
			aimed.append(tile)
	ground[key] = aimed
	return aimed

## Whether `def` is refused a required alley outright — an alley the day's corridor runs down,
## rather than one she may choose to detour into. **Two rows today**, `alley_robbery` and
## `alley_mouse`, both `def.placement == [ALLEY]` and neither one anything else can ever reach an
## alley through — `charging_dog` arrives `AHEAD_OF_PLAYER` and never asks this pool at all, and a
## heated patrol reaches an alley by a different path than a map placement. Stated over the
## placement shape rather than `def.id` so a future row sharing it inherits the same refusal
## without this function changing, which is the same reason `has_a_spread` is a test on the def
## rather than a name.
static func _refuses_required_alleys(def: EventDef) -> bool:
	return def.placement.size() == 1 and def.placement[0] == GameEnums.TileType.ALLEY

## `alley_mouse`'s own preference, once a garbage-sack pile stands in the alley too: extra copies
## of a tile beside one (`GarbageSacks.alley_pile_tiles`), appended to the roll rather than
## excluding anything else, so every guarantee already checked against `candidates` — spacing,
## room, the required-alley refusal above — still runs against the result unchanged. A day with no
## pile yet returns `candidates` untouched, which is every day before sacks reach the alleys at
## all.
const _MOUSE_ID := "alley_mouse"
const _MOUSE_PILE_ADJACENCY := 1
const _MOUSE_PILE_EXTRA_COPIES := 4

static func _prefer_beside_a_sack_pile(candidates: Array[Vector2i], map: CityMap,
		day: int) -> Array[Vector2i]:
	var piles := GarbageSacks.alley_pile_tiles(map, day)
	if piles.is_empty():
		return candidates
	var weighted := candidates.duplicate()
	for tile in candidates:
		for pile in piles:
			if maxi(absi(tile.x - pile.x), absi(tile.y - pile.y)) <= _MOUSE_PILE_ADJACENCY:
				for _copy in _MOUSE_PILE_EXTRA_COPIES:
					weighted.append(tile)
				break
	return weighted

## The day's copy of `StreetTrees.footprint_tiles()`, kept in the same `ground` dictionary every
## other answer in this file is cached in and under a key no `"%s|%d"` placement question can
## collide with. One scan of the city's pits per day rather than one per candidate row: the trees
## are fixed for the run, so nothing inside one `build_day` can move them.
const _TREE_TILES_KEY := "street tree footprints"

static func _street_tree_tiles(map: CityMap, ground: Dictionary) -> Dictionary:
	if not ground.has(_TREE_TILES_KEY):
		ground[_TREE_TILES_KEY] = StreetTrees.footprint_tiles(map)
	return ground[_TREE_TILES_KEY]

## A placement with no particular street asked for. Not `Vector3i.ZERO`, which is the key of a real
## street — the one running east out of the north-west corner.
const NO_SITE := Vector3i(-1, -1, -1)

## A tile whose two coordinates are **both** inside a corridor band — a junction, belonging to two
## streets at once. `EventInstance._spread_is_vertical` and `_centred_on_the_pavement_band` both
## give up here, for the reason each states in its own docstring: there is no single street left for
## a spread to lie across or be centred on. See `docs/DECISIONS.md`, M64, "a spread on a corner is placed
## as if the corner were nothing."
static func _is_a_corner(tile: Vector2i) -> bool:
	return CityMap.corridor_offset(tile.x) >= 0 and CityMap.corridor_offset(tile.y) >= 0

## Every tile of the right kind that anything may stand on today, precinct weighting included.
##
## **A precinct is a retail street**, so it carries more of the day than a length of ordinary
## pavement does: it is where the cafés and the market stalls and the buskers are.
##
## **Anything `EventInstance.has_a_spread()` is refused a corner outright**, cached under its own
## key so the un-narrowed list stays shared with everything that has no orientation to get wrong on
## one — a yeller or a busker keeps every tile a plain sidewalk scan already found. This is an
## exclusion from the candidate pool rather than a repair after the fact, the same shape a barrier
## beside a calm area's access street is refused in rather than moved out of afterwards.
static func _open_ground_for(def: EventDef, map: CityMap, ground: Dictionary) -> Array[Vector2i]:
	var key := "%s|%d" % [def.placement, def.pavement_side]
	if not ground.has(key):
		var doorstep := _the_street_she_starts_on(map)
		var trees := _street_tree_tiles(map, ground)
		var open: Array[Vector2i] = []
		for type in def.placement:
			for candidate in map.tiles_of_type(type as GameEnums.TileType):
				# A closed street is not somewhere anyone can get to, so it is not somewhere an event
				# can usefully happen: the player would never see it and the scheduler would have
				# spent budget on nothing. `is_held_at` refuses the same ground for a street that is
				# not closed but is still spoken for — a hard seal's segment, a region wall or door,
				# or a segment bordering the home block (`CityMap.held_segments`) — and
				# `is_on_home_block` refuses the block's own interior on top of that, both by
				# construction rather than as a repair once something has landed there. See
				# `docs/DECISIONS.md`, M100, "Events spawn inside a fully blocked street" and "Nothing on the
				# home block".
				#
				# **And a standing street tree's own ground.** The trees are the city's and fixed
				# for the run while the events are the day's, so the day is what yields — refused
				# here, where the candidate is offered, never moved afterwards. *(2026-09-12, the
				# player: "events can only be placed where no trees are (except for the fallen tree
				# which must empty out one tree lot)".)* The footprint rather than the trunk tile,
				# because the ground a tree's shadow reaches over is ground a van would be standing
				# in. The fallen tree is the exception and needs none here: it arrives as a closure
				# or a hard seal, and both hold their whole street against the catalogue already.
				if map.is_closed(candidate) or doorstep.has_point(candidate) \
						or map.is_held_at(candidate) or map.is_on_home_block(candidate) \
						or trees.has(candidate) \
						or not _wants_this_side(def, map, candidate):
					continue
				open.append(candidate)
				if map.street_kind_at(true, candidate) == GameEnums.StreetKind.PEDESTRIAN \
						or map.street_kind_at(false, candidate) == GameEnums.StreetKind.PEDESTRIAN:
					for _extra in Tuning.EVENT_PRECINCT_WEIGHT - 1:
						open.append(candidate)
		ground[key] = open
	if not EventInstance.has_a_spread(def):
		return ground[key]
	var corner_free_key := key + "|no corner"
	if not ground.has(corner_free_key):
		var without_corners: Array[Vector2i] = []
		for tile in ground[key]:
			if not _is_a_corner(tile):
				without_corners.append(tile)
		ground[corner_free_key] = without_corners
	return ground[corner_free_key]

## How many more times a tile is offered to the roll because of what the day is placing there.
##
## Zero means the tile is not offered at all, and there is exactly one case of it — **a wall never
## stands on ground a route runs along.** Every other preference here is a weight, because a weight
## cannot starve a row of ground and a filter can. What makes this one safe to state absolutely is
## that the rest of the city stays available to it: a wall wants its own band, it settles for
## anywhere else off the routes, and only the routes themselves are refused.
##
## **The refusal is per sidewalk and the rest of the band is per street**, which is the one place
## those two grains differ on purpose. `corridor.depth()` answers a street tile for its whole
## street, because what a *price* is stated over is ground the player may be anywhere across; where
## a thing may **stand** is the narrower question, and a branch runs along one sidewalk of a street
## rather than down the middle of it. So `carries_a_route()` is what closes the ground, and the
## sidewalk **across the street from a route** is where a very costly wall **wants** to be —
## *"the market stall should appear on the other side of the street where for some reason no event
## was chosen"* (PLAYTEST-77). What keeps a wide row off it is the width rule: a wall across the
## street whose reach covers the route's own sidewalk is refused that ground by
## `_leaves_the_routes_sidewalk_open`.
##
## **The wall band has a gradient in it, and the gradient is the instruction**: the ground off the
## paths ranges from *very costly* to *deadly*. Stray one turning and it is expensive; stray further
## and it ends the day. So a **very costly** wall is pulled to the rim and a **lethal** one is
## pulled past it. Both keep the whole off-corridor city as a weight rather than a filter, so
## neither can be starved of ground on a day whose corridor happens to be most of the map.
##
## **The rim has two members and they are the same thing seen from the two grains.** One is a
## turning she might wrongly take, one street out (`depth() == 1`); the other is the far side of the
## street she is already on (`depth() == 0` with no route along it), which is the nearest ground to
## the route there is and the one she can read without leaving her own line. A wall is what bounds
## the corridor, and both of those bound it from somewhere she can see. That is why the costly
## weight is `away <= 1` rather than a turning exactly: the far sidewalk carries
## `EVENT_WALL_RIM_WEIGHT` like a turning does.
##
## The **lethal** half keeps its own gradient rather than joining that: it is pulled past the rim by
## `WALL_DEEP_WEIGHT`, and the far sidewalk is inside the rim, so a lethal row is no likelier there
## than at any other single turning.
##
## **And one street inside the rim is worth more than the rest of it.** A gap is the single street
## two adjacent strands of today's corridor are joined by, so it is the one piece of rim that is
## *inside* the day's own plan rather than beside it: with nothing on it the two strands are one
## wide easy region and choosing between them is not a choice.
##
## It is a **weight on top of the rim weight** rather than a rule that closes every gap: a gap is
## likelier than an ordinary turning to carry something and never certain to, which is the variety
## the design asks for.
##
## **It applies to the costly half of the wall band and not to the lethal half**, which is a
## measured correction rather than a nicety. A gap is on the rim by construction, so a lethal row's
## weight there is 1 against `WALL_DEEP_WEIGHT` further out — and multiplying *that* by the gap
## weight makes a gap the best lethal ground in the city, which pulls the deep band's teeth straight
## out: measured over eight seeds of day 9, the deep band goes from the dearest ground in the city to
## level with the corridor. The gradient's own sentence is the fix — *stray one turning and it is
## expensive, stray further and it ends the day* — so what stands in a gap is very expensive, and
## the deadly end stays where it was put.
static func _copies_of(tile: Vector2i, corridor: Corridor, role: GameEnums.BlockerRole,
		lethal := false) -> int:
	var away := corridor.depth(tile)
	match role:
		GameEnums.BlockerRole.WALL:
			if corridor.carries_a_route(tile):
				return 0
			if lethal:
				return Tuning.WALL_DEEP_WEIGHT if away >= 2 else 1
			if away > 1:
				return 1
			return Tuning.EVENT_WALL_RIM_WEIGHT \
					* (Tuning.EVENT_WALL_GAP_WEIGHT if corridor.is_in_a_gap(tile) else 1)
		GameEnums.BlockerRole.FRICTION:
			return Tuning.EVENT_CORRIDOR_WEIGHT if away == 0 else 1
		_:
			return 1

## The street the front door opens onto, which nothing is placed on.
##
## The home is a notch with one exit, so the walk from the doorstep to the first junction is the
## one stretch of a day she does not choose to be on — and a thing standing on it is not a route
## decision, it is a tax. `ClosurePlanner.home_street` refuses to close this same segment for the
## same reason; this is that exemption applied to the other thing in the game that occupies ground.
##
## **It is the segment rather than a radius**, which is the part worth keeping. A radius is a
## number somebody has to tune and it stops at an arbitrary distance down a street; a segment is
## the unit the player can see the shape of, ending at the junction where the choice is made — the
## same argument that made a segment the unit a closure works in.
##
## Nothing else needs the exemption: the spoiler grid places on calm ground, a scar is where
## something already burnt, and an ambient event has no tile.
static func _the_street_she_starts_on(map: CityMap) -> Rect2i:
	var segment := ClosurePlanner.home_street(map)
	return segment.tile_rect() if segment else Rect2i()

## Whether a tile is the lane of the pavement this event wants.
##
## Almost everything says `ANY` and this is a free `true`. The two rows that do not are placement
## questions rather than balance ones: a parked van belongs at the kerb rather than in a traffic
## lane the crowd will drive straight through, and a lorry reversing into a yard belongs with its
## back to a wall.
##
## `AGAINST_THE_BUILDING` asks for two things and the second is about the *art*: there has to be
## a real building on the far side, and it has to be **east or west**, because the silhouettes
## that back into things are drawn side-on and a sprite cannot face north. A frontage the lorry
## would have to reverse into sideways is not one it can be drawn reversing into, and half the
## pavements in the city are still eligible.
static func _wants_this_side(def: EventDef, map: CityMap, tile: Vector2i) -> bool:
	if def.pavement_side == EventDef.Pavement.ANY:
		return true
	var inward := map.pavement_inward(tile)
	if inward == Vector2i.ZERO:
		return false
	if def.pavement_side == EventDef.Pavement.AT_THE_KERB:
		# The kerb lane is the one whose *road* side is actually road: on a two-tile pavement
		# that is the inner of the two, and asking the tiles rather than the offset keeps it true
		# of a crossing, a closed carriageway, or whatever a later milestone paints there.
		return map.is_street(tile - inward) \
				and map.tile_at(tile - inward) != GameEnums.TileType.SIDEWALK
	return inward.y == 0 \
			and map.tile_at(tile + inward) == GameEnums.TileType.BUILDING

## One candidate placement on a given tile, with its route built if it moves.
static func _build_placement(def: EventDef, map: CityMap, tile: Vector2i,
		rng: RandomNumberGenerator) -> Planned:
	var at := map.tile_to_world(tile)
	if not def.mobile:
		var placed := Planned.new(def, at)
		if def.pavement_side == EventDef.Pavement.AGAINST_THE_BUILDING:
			# Backing in, so it faces *out* of the wall it is against: the box is the end that is
			# coming towards you and it has to be the end that is in the yard.
			placed.facing = -Vector2(map.pavement_inward(tile))
		return placed
	match def.path_mode:
		EventDef.PathMode.CROSS_STREET:
			return Planned.new(def, at, _cross_street_path(map, tile))
		EventDef.PathMode.ALONG_STREET:
			var route := _along_street_path(map, tile, def, rng)
			# Nowhere to go from here; a "mobile" event that stands still is worse than
			# another roll of the dice.
			return null if route.is_empty() else Planned.new(def, at, route)
		_:
			return Planned.new(def, at)

## How much room a candidate has. `INF` means it satisfies every rule and can be taken at once;
## `-INF` means it is illegal at any price; anything between is how far it got towards
## `EVENT_SPACING_SAME`, which is the only rule that bends.
##
## "Room" is measured against the whole of an event rather than the tile it starts on: a dog
## walker's route is thirty tiles long, and a start point with room around it can still walk the
## length of somebody else's field.
##
## **Two of the rules are absolute and one is a preference**, and the split is what each one is
## protecting:
##
## - `EVENT_SPACING_ANY` — nothing is ever drawn inside anything else. Two tiles, thousands of
##   candidates, so refusing costs a re-roll and nothing else.
## - **Nothing else happens inside a lethal event's field.** `Tuning.validate_event()` states the
##   telegraph contract *per event* and the player experiences the sum, so at one event per block
##   "walk out of this radius" can quietly mean "walk into the next one". For a row that only costs
##   points that is what the density is *for*; for one that ends the day it is a death arriving out
##   of a field she was already reading. A `hard_fail` event that cannot find room is not placed.
## - `EVENT_SPACING_SAME` — a second dog walker a few pixels from the first reads as a
##   duplicated sprite rather than a second incident. This one bends, because on a full map the
##   honest answer is the roomiest spot left rather than no event.
static func _room_around(candidate: Planned, already: Array[Planned]) -> float:
	var room_same := INF
	for plan in already:
		if not plan.is_placed():
			continue
		var gap := _gap_between(candidate, plan)
		# **An offer is not in the world yet, so it takes up no room.** A set piece is planned at
		# every site of a covering set and exactly one of them ever happens, so spacing the whole day
		# around all of them reserves ground for events that will not exist — and it breaks *a
		# retried day is the same day* outright, because the day *after* it fires then has two to six
		# long routes' worth of ground freed rather than one. Measured on seed 4242 with offers
		# spaced against: `leaf_blower` seven to five and eight kinds moving between two attempts at
		# the same day.
		#
		# The exception is the lethal clause below, and it is the one thing that cannot be deferred:
		# if the offer does resolve there, she meets a lethal field and a fire engine at once, which
		# is exactly the sum the clearance rule refuses. Siblings still space against each other —
		# the group is compared normally against its own — because two offers on top of one another
		# would be a real overlap on whichever of them fires.
		var elsewhere := plan.set_piece_group != "" \
				and plan.set_piece_group != candidate.set_piece_group
		if not elsewhere:
			if gap < Tuning.EVENT_SPACING_ANY:
				return -INF
			if _keeps_its_field_clear(plan) and gap < plan.def.field_reach():
				return -INF
			if plan.def.id == candidate.def.id:
				room_same = minf(room_same, gap)
		if _keeps_its_field_clear(candidate) and gap < candidate.def.field_reach():
			return -INF
	return INF if room_same >= Tuning.EVENT_SPACING_SAME else room_same

## Whether the clearance rule is about this placement: a lethal event with nothing else inside
## its whole field — `EventDef.field_reach()`, not `outer_radius` alone, since a segment's field
## reaches `half_length` further along its own spine than a disc's would.
##
## **The rule is now stated over the ground she is being guided along, and off it there is an
## exemption**, which was the player's own call when the two collided.
##
## Read the rule's own reason and the exemption falls out of it. The rule exists because *the
## contract is stated per event and the player experiences the sum* — walking out of one field can
## mean walking into another, and where that second field ends the day it is a death arriving out of
## something she was already reading. That is an argument about **a route she is meant to take**.
## Off the corridor there is no route she is meant to take; the whole point of the ground is that
## she should not be on it, and a lethal field overlapping another one is the city saying so rather
## than a fairness failure. With the rule applied out there, *deadly all over* is not merely hard to
## achieve — it is arithmetically impossible: six lethal rows capped in single figures, at radii of
## 145 to 380px, cannot tile anything.
##
## **A `WALL` is exactly the off-route set and that is by construction, not by coincidence.**
## `_copies_of` offers a wall zero copies of any tile a route actually runs along, so a placement
## carrying this role is off the routes or it does not exist — including the far sidewalk of a
## route's own street, which is ground no route walks. What keeps its clearance is everything else: a
## set piece, which is sited where every route passes, and anything the day placed for a reason that
## is not about the corridor at all.
##
## The telegraph contract is untouched by this and must not be "fixed" alongside it. That one is
## stated over a single event's own geometry, `Tuning.validate_event()` checks it on load, and
## nothing here changes what any event owes the player who sees it coming.
##
## **A pursuer is the third exemption, and the reason is the same one the `WALL` case is stated
## over: the rule is about a *place* being kept clear, and a pursuer has no place.** It goes
## wherever she goes, so placement can never keep anything clear of it — the argument the `WALL`
## case makes about the corridor does not even apply, because there is no ground to be off of in
## the first place.
##
## This was already true for every lethal pursuer in the catalogue, but by accident rather than by
## name: `_role_for` gives any placed `hard_fail` row that is not a `ONE_SHOT` the `WALL` role
## before it ever asks whether the row pursues, so `alley_robbery` (placed, `hard_fail`, therefore
## always `WALL`) and `charging_dog` past `Tuning.RUN_TAUGHT_DAY` (`spawn_mode_on()` answers `MAP`
## from there, placed and `hard_fail` the same way) are both exempt without this line doing
## anything. On `RUN_TAUGHT_DAY` itself `charging_dog` is never placed at all — it is
## `AHEAD_OF_PLAYER`, sited by the director with no tile the scheduler ever reasons about — which is
## the other way a pursuer reaches this exemption. Stating it over `plan.def.pursues` rather than
## leaving the exemption to follow from the `WALL` classification is what makes it survive a future
## pursuer the role logic does not happen to route through `WALL` — a lethal `SET_PIECE` pursuer,
## say, which `_role_for` would classify ahead of the `hard_fail` check.
static func _keeps_its_field_clear(plan: Planned) -> bool:
	return plan.def.hard_fail and plan.role != GameEnums.BlockerRole.WALL and not plan.def.pursues

## The closest endpoint-to-route distance between two events.
##
## Two routes are measured from both sides so either route's closest endpoint can decide the gap.
## Crossing interiors are not detected; the answer is the nearest waypoint-to-route distance.
static func _gap_between(a: Planned, b: Planned) -> float:
	# A point's distance to the whole other route already includes its endpoints, so the symmetric
	# endpoint pass cannot make the answer smaller when either side is stationary.
	if a.path.size() < 2:
		return b.distance_from(a.position)
	if b.path.size() < 2:
		return a.distance_from(b.position)
	var gap := INF
	for point in a.ends():
		gap = minf(gap, b.distance_from(point))
	for point in b.ends():
		gap = minf(gap, a.distance_from(point))
	return gap

# ------------------------------------------------- a path never has to cost (M129) ---

## Whether a row is one the **zero-cost line** has to get past — the reading PLAYTEST-71 settled,
## stated once here and read by every rule in this section.
##
## A line along a route is a walk from the doorstep to the calm that never enters a placed row's
## reach. Five kinds of row are outside it, and each is outside for its own reason rather than for
## convenience:
##
## - **`city_wide`** has no place, so there is no other side of the street to walk on.
## - **`scenery`** (`pigeon_flock`) is free already — *"flocks are basically free already, don't
##   count it as block, just count is scenery"* — which is the same exemption `_role_for` makes.
## - **a pursuer** follows her rather than sitting on a tile, and pays the telegraph contract
##   instead; so does anything the director sites (`AHEAD_OF_PLAYER`, `TOWARD_PLAYER`), which
##   reaches here as a plan with no position at all.
## - **a region door** costs by design — *"it costs by design"* — so `checkpoint_hut` and
##   `checkpoint_gate` are never a block. The region wall's own body is not a door and still counts.
## - **a mobile row that does not pace** is passed by crossing, waiting and crossing back — *"the
##   player can cross the street, wait, then come back without ever getting excited by it"*. A row
##   that **paces** is not mobile in that sense: it comes back, so it is read over its beat.
##
## **A wall is not outside it**, and that is the player's own decision on the one thing the four
## rules left open: *"option 2 is valid only if the influence at a junction is low enough that it
## can be taken without having to worry or plan around it."* A wall bounds the corridor — `_copies_of`
## offers it zero copies of any ground a route runs along, so it never stands on a route — but its
## field reaches in from the far sidewalk or one street out, and being told to walk a corridor whose crossings are covered by what is
## bounding it is being told to pay for the guidance. So a wall's own charging disc is asked the
## same three questions every other row's is, and the condition the player set on that is exactly
## `_line_reach_of()`: what a wall may still put over a junction is the part of its field under the
## walking decay, which is a crossing the walk takes without planning around it.
##
## The lethal-clearance rule's wall exemption is a different rule about a different thing and is
## untouched — `_keeps_its_field_clear` is about keeping other events out of a lethal field, not
## about whether a line exists past one.
static func _counts_against_the_line(plan: Planned) -> bool:
	return plan.is_placed() and _a_line_has_to_avoid(plan.def)

## The same five exemptions asked of the **def** alone, for the one caller that has no placement to
## ask about: `_role_for` decides a role before any tile is chosen. Everything a placement adds —
## *is it actually standing anywhere* — is the caller's own question above.
static func _a_line_has_to_avoid(def: EventDef) -> bool:
	if def.city_wide or def.scenery or def.pursues or def.id.begins_with(_DOOR_ID_PREFIX):
		return false
	if def.mobile and not def.paces:
		return false
	return _line_reach_of(def) > 0.0

## The line a stroller needs across a sidewalk, measured between the two lanes of one:
## `SIDEWALK_WIDTH` (2) tiles of sidewalk means the far lane's centre is one tile (32px) from the
## near one, and a free tile is a line because a tile is wider than the 28px stroller
## (`2 * PLAYER_BODY_RADIUS`). It is the same tile-grained reading every other rule in this section
## measures a line in.
const _THE_FAR_LANE := float((Tuning.SIDEWALK_WIDTH - 1) * Tuning.TILE_SIZE)

## **Whether a row's own numbers leave no way past it along a sidewalk it may stand on** — the
## passability reading of a wall, beside the cost one. *(PLAYTEST-77: "how is market stall a
## friction? you can't walk through it"; "a wall is also when you physically cannot walk through".)*
##
## A sidewalk is two lanes of tile, and a row stands in one of them, so the only line past it is the
## other lane — one tile across, which `_denies` reads as free while the row's reach is under it.
## What the reach is, is the whole point: **the body plus the ground it charges for**
## (`_line_reach_of`), not the body alone. A café whose tables are 24px across but which bills
## anybody within 56px of them is a café nobody walks past on that sidewalk for free, and *free* is
## what the guarantee is about.
##
## **It is asked of the def and nothing else**, because a role is decided before a tile is chosen —
## so the question is *a* sidewalk rather than *this* sidewalk, and a row that may stand on one is
## judged on the narrowest ground it may be rolled onto. A row the placement rolls onto a square or
## a park instead is still the same row with the same field, and being a wall costs it nothing
## there: the role only ever decides which ground it is offered.
##
## The five rows outside the line reading entirely — a pursuer, a door, a city-wide row, scenery, a
## mobile row that does not pace — are outside this too, by asking `_a_line_has_to_avoid` rather
## than repeating the list.
static func _leaves_no_line_along_a_sidewalk(def: EventDef) -> bool:
	if not def.placement.has(GameEnums.TileType.SIDEWALK):
		return false
	if not _a_line_has_to_avoid(def):
		return false
	return _line_reach_of(def) >= _THE_FAR_LANE

## The clause as the **role** asks it, which is of a def with no tile yet — so a pacing row is not
## answered here at all.
##
## *(PLAYTEST-77, 2026-09-19: "yeller is something you can time. it stays on the route"; "if the
## yeller paces across a crosswalk then there is a way to avoid them. if they stay on the segment
## for the whole time with no side route then there is no way to avoid them. distinguish those
## cases when deciding whether the yeller is a wall".)* Whether a man walking a beat can be got
## past is a fact about **where his beat runs**, not about his field: the same numbers are a wall in
## the middle of a segment and a thing to time at a junction. `_a_pacing_beat_walls_a_sidewalk`
## asks it of the candidate, inside `_place_one`'s loop, where the beat actually exists.
static func _takes_a_whole_sidewalk(def: EventDef) -> bool:
	return not def.paces and _leaves_no_line_along_a_sidewalk(def)

## **Whether *this* pacing placement is a wall**: its field leaves no line along a sidewalk, and its
## beat reaches nowhere she can leave that sidewalk.
##
## The arithmetic of the first half is the plain clause above — a beat runs *along* a sidewalk and
## moves the row nowhere across it, so the width of the line past a yeller is the same at every
## phase of his loop and waiting does not widen a sidewalk. What the second half adds is the way out
## that is not a wider sidewalk: **a crossing**. A beat that reaches a junction box is a beat she
## can step off, on the zebra there, while he is at the other end of it; a beat that stays between
## two junctions with nothing to cross leaves her the choice of walking through him or turning
## round.
##
## **A junction box is where every crosswalk in the city is**, so *his beat crosses a crosswalk* and
## *his beat reaches a junction* are one question — `CityGenerator._street_tile` paints `CROSSING`
## only where both corridor offsets are inside a street and exactly one of them is a carriageway
## offset, which is a junction box by definition. It is also the crossing this whole milestone
## counts on: a mid-block crossing exists in play and is not planned around.
static func _a_pacing_beat_walls_a_sidewalk(plan: Planned, map: CityMap) -> bool:
	if not plan.def.paces or not _leaves_no_line_along_a_sidewalk(plan.def):
		return false
	return not _a_beat_reaches_a_crossing(plan, map)

## Whether a beat's own run touches a junction box. Two waypoints and a straight run between them
## (`_along_street_path`), so the tiles are a step along one axis; a row with no beat laid at all
## answers no, which is the conservative side of a rule that only ever refuses ground.
static func _a_beat_reaches_a_crossing(plan: Planned, map: CityMap) -> bool:
	if plan.path.size() < 2:
		return false
	var from := map.world_to_tile(plan.path[0])
	var to := map.world_to_tile(plan.path[plan.path.size() - 1])
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var at := from
	while true:
		if CityMap.junction_at(at) != Vector2i(-1, -1):
			return true
		if at == to or step == Vector2i.ZERO:
			return false
		at += step
	return false

## `checkpoint_hut` and `checkpoint_gate`, the two rows that **are** a region's door. Matched on the
## id the way `tests/probes/m129_zero_cost_line.gd` matches them, since what makes a door a door is
## `RegionPlanner` choosing it rather than any field on the def.
const _DOOR_ID_PREFIX := "checkpoint"

## How far a row denies ground: **the disc it charges for**, `obstructs_radius` wherever it has a
## body, the larger of the two where both apply. A row that neither charges nor obstructs — the
## `playground` ambient, at intensity 0 — is not something a line has to avoid.
##
## **Charging for is not the same as being heard on**, and the difference is the player's own
## condition on any of this being checked at all: *"option 2 is valid only if the influence at a
## junction is low enough that it can be taken without having to worry or plan around it."* A walk
## through ground where a row emits less than `Tuning.EXCITEMENT_DECAY_WALKING` nets the meter
## *down*, so it is ground a route does not have to be planned around and the rules in this section
## have no business refusing a placement over it. The disc is therefore where the emission crosses
## that rate, not `outer_radius`, which is where it stops reaching at all — the same distinction
## `_denial_radius()` makes about calm ground, at a different rate and with a different zero: a row
## quieter than the rate everywhere denies **nothing** here, where it still denies its own inner
## disc to a pram trying to settle.
##
## **A lethal row keeps its whole `outer_radius`.** Its price is not a rate and nothing about being
## quiet at the rim makes walking into it survivable, so the arithmetic below says nothing about it.
##
## The plain disc rather than `field_reach()`'s forward-stretched ellipse, because the milestone's
## own wording is a radius and the two differ only for a mobile row and only ahead of it. A flock
## would need its own answer — its intensity is shared between bodies, so the closed form below
## reads it far too wide — and does not have one: `pigeon_flock` is `scenery` and
## `_counts_against_the_line` is done with it before this is ever asked.
static func _line_reach_of(def: EventDef) -> float:
	if def.hard_fail:
		return maxf(def.outer_radius, def.obstructs_radius)
	return maxf(_reach_above(def, Tuning.EXCITEMENT_DECAY_WALKING), def.obstructs_radius)

## How far from the centre a row still emits more than `rate`, over both parts of its field: the
## field itself, and the core where it has one (a cored row's loud part can outlive its quiet one,
## which is the whole point of having it).
static func _reach_above(def: EventDef, rate: float) -> float:
	return maxf(_band_crossing(def.intensity, def.inner_radius, def.outer_radius, rate,
			def.falloff_power),
			_band_crossing(def.core_intensity, def.inner_radius, def.core_radius, rate,
			def.falloff_power))

## Where one falloff band crosses `rate`, or zero if it is never above it — `Tuning.falloff`'s
## `1 − t^power` inverted for the `t` at which it equals `rate`. The row's own `falloff_power`
## rather than a squared constant, so a row that ever shapes its own drop-off is denied the ground
## it actually charges for rather than the ground a quadratic row of the same numbers would.
static func _band_crossing(intensity: float, inner: float, outer: float, rate: float,
		power: float) -> float:
	if intensity <= rate or outer <= inner:
		return 0.0
	var left := 1.0 - rate / intensity
	# `sqrt` at the default rather than `pow(x, 0.5)`, for the reason `Tuning.falloff` writes its
	# own default out: the two may differ in the last bit, and every radius the catalogue was
	# measured at came from this one.
	var t := sqrt(left) if is_equal_approx(power, 2.0) else pow(left, 1.0 / power)
	return inner + t * (outer - inner)

## Whether a row denies a point, under the beat-opening reading.
##
## **A pacing row denies only the ground its beat never leaves free** — *"time pass, don't route
## around them"* — so a point it is ever more than its reach away from can be walked past by
## waiting. The intersection over a whole beat is the intersection over its **corners**, and that
## is exact rather than a sample: a disc is convex, so a point within `reach` of both ends of a
## straight run is within `reach` of every point of it.
static func _denies(plan: Planned, at: Vector2, reach: float) -> bool:
	if plan.def.paces and plan.path.size() >= 2:
		for point in plan.path:
			if at.distance_to(point) > reach:
				return false
		return true
	return at.distance_to(plan.position) <= reach

## The day's route junctions with the geometry the rule asks about, worked out once per day and
## kept in the same `ground` dictionary every other day-lifetime answer in this file lives in.
## Each entry is `[junction, the box's world centre, the box's own reach from that centre]`.
const _ROUTE_JUNCTIONS_KEY := "route junctions"

static func _route_junctions(map: CityMap, ground: Dictionary, corridor: Corridor) -> Array:
	if not ground.has(_ROUTE_JUNCTIONS_KEY):
		var found: Array = []
		for junction in corridor.route_junctions():
			var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
			var world := map.tile_rect_to_world(box)
			found.append([junction, world.get_center(), world.size.length() * 0.5])
		ground[_ROUTE_JUNCTIONS_KEY] = found
	return ground[_ROUTE_JUNCTIONS_KEY]

## **A route's junctions stay clear**, checked before a row is accepted and never repaired after.
##
## A junction is the only place a line may change pavement, so a crossing the day's rows have
## closed between them is a cut nothing on either side can answer — the shape
## `tests/probes/m129_zero_cost_line.gd` measured breaking more routes than every other shape put
## together. The refusal is *this ground*, not *this row*: `_place_one` simply rolls again, and the
## row lands somewhere it leaves the crossing open.
##
## **It is stated over the candidate together with what is already down**, which is what makes it
## the rule the measurement asked for rather than a weaker one: the crossing the probe names most
## often is covered by a pair (`cafe_tables` and `homeless_yeller` at one junction), and a rule that
## only ever asked *does this row alone take the box* would accept both of them. Stating it
## cumulatively is still *checked before accepted*: each row in turn is asked whether the day it is
## joining still has a line through every crossing, so a closed one never exists even briefly.
static func _leaves_the_route_junctions_open(candidate: Planned, map: CityMap,
		corridor: Corridor, ground: Dictionary, already: Array[Planned]) -> bool:
	if not corridor or not _counts_against_the_line(candidate):
		return true
	var reach := _line_reach_of(candidate.def)
	for entry: Array in _route_junctions(map, ground, corridor):
		var centre: Vector2 = entry[1]
		var box_reach: float = entry[2]
		if candidate.distance_from(centre) > reach + box_reach:
			continue
		if not _a_crossing_stays_open(map, corridor, entry, candidate, already):
			return false
	return true

## Whether one junction box still carries a walk between every route street that meets it, with the
## candidate standing and everything already down standing too.
##
## **The arms are the on-corridor streets and nothing else.** A junction where three route streets
## meet has to connect all three, because a line may arrive down any of them; a turning off the
## corridor is not ground the guarantee is about. Where the tree crosses a junction without using a
## street at either side — a park cut, an alley mouth — there are no arms and the box only has to
## have somewhere free left in it.
static func _a_crossing_stays_open(map: CityMap, corridor: Corridor, entry: Array,
		candidate: Planned, already: Array[Planned]) -> bool:
	var junction: Vector2i = entry[0]
	var centre: Vector2 = entry[1]
	var box_reach: float = entry[2]
	var standing: Array[Planned] = [candidate]
	for plan in already:
		if plan == candidate or not _counts_against_the_line(plan):
			continue
		if plan.distance_from(centre) <= _line_reach_of(plan.def) + box_reach:
			standing.append(plan)

	var origin := junction * CityMap.period()
	var free := {}
	for y in Tuning.STREET_WIDTH:
		for x in Tuning.STREET_WIDTH:
			var tile := origin + Vector2i(x, y)
			if not map.is_open(tile):
				continue
			var at := map.tile_to_world(tile)
			var taken := false
			for plan in standing:
				if _denies(plan, at, _line_reach_of(plan.def)):
					taken = true
					break
			if not taken:
				free[tile] = true
	if free.is_empty():
		return false

	var arms: Array = []
	for segment in StreetNetwork.at_junction(junction):
		if corridor.depth(segment.tile_rect().position) != 0:
			continue
		var open_here: Array[Vector2i] = []
		for tile in _arm_tiles(origin, junction, segment):
			if free.has(tile):
				open_here.append(tile)
		if open_here.is_empty():
			return false
		arms.append(open_here)
	if arms.size() < 2:
		return true

	var reached := {}
	var queue: Array[Vector2i] = []
	for tile: Vector2i in arms[0]:
		reached[tile] = true
		queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for step in _NEIGHBOUR_STEPS:
			var next: Vector2i = at + step
			if free.has(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	for i in range(1, arms.size()):
		var joined := false
		for tile: Vector2i in arms[i]:
			if reached.has(tile):
				joined = true
				break
		if not joined:
			return false
	return true

## The one-tile strip of a junction box that a street opens onto — where a line enters the box from
## that street and where it leaves it for that street.
static func _arm_tiles(origin: Vector2i, junction: Vector2i,
		segment: StreetNetwork.Segment) -> Array[Vector2i]:
	var step := segment.other_end(junction) - junction
	var found: Array[Vector2i] = []
	for i in Tuning.STREET_WIDTH:
		if step.x > 0:
			found.append(origin + Vector2i(Tuning.STREET_WIDTH - 1, i))
		elif step.x < 0:
			found.append(origin + Vector2i(0, i))
		elif step.y > 0:
			found.append(origin + Vector2i(i, Tuning.STREET_WIDTH - 1))
		else:
			found.append(origin + Vector2i(i, 0))
	return found

const _NEIGHBOUR_STEPS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

## The sidewalks the day's routes are actually walked along, with the geometry the width rule asks
## about: `[segment, the band's tile rect, the same rect in world space]`. Worked out once per day
## and kept in the `ground` dictionary every other day-lifetime answer in this file lives in.
const _ROUTE_SIDEWALKS_KEY := "route sidewalks"

static func _route_sidewalks(map: CityMap, ground: Dictionary, corridor: Corridor) -> Array:
	if not ground.has(_ROUTE_SIDEWALKS_KEY):
		var found: Array = []
		for segment in StreetNetwork.segments():
			var rect := segment.tile_rect()
			if corridor.depth(rect.position) != 0:
				continue
			var walked := 0
			for band in _sidewalk_bands(rect, segment.horizontal):
				if not _a_route_walks(corridor, band):
					continue
				walked += 1
				found.append([segment, band, map.tile_rect_to_world(band)])
			# A street on the corridor whose tree cells are neither of its sidewalks: the whole
			# street is the honest question there, and it is the question the rule asked before.
			# The growth graph has no mid-block carriageway cell in it, so this is unreachable
			# today rather than merely rare — it is here so the guarantee cannot quietly lapse if
			# that ever changes.
			if walked == 0:
				found.append([segment, rect, map.tile_rect_to_world(rect)])
		ground[_ROUTE_SIDEWALKS_KEY] = found
	return ground[_ROUTE_SIDEWALKS_KEY]

## The two sidewalk bands of a street's own tile rect, in the order the corridor runs across it.
static func _sidewalk_bands(rect: Rect2i, horizontal: bool) -> Array[Rect2i]:
	var across := Vector2i.DOWN if horizontal else Vector2i.RIGHT
	var size := Vector2i(rect.size.x, Tuning.SIDEWALK_WIDTH) if horizontal \
			else Vector2i(Tuning.SIDEWALK_WIDTH, rect.size.y)
	var far := across * (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH)
	return [Rect2i(rect.position, size), Rect2i(rect.position + far, size)]

static func _a_route_walks(corridor: Corridor, band: Rect2i) -> bool:
	for y in range(band.position.y, band.end.y):
		for x in range(band.position.x, band.end.x):
			if corridor.carries_a_route(Vector2i(x, y)):
				return true
	return false

## **Nothing takes the sidewalk a route is walked along.** *"All obstacles should be routable around
## by eg crossing to the other side of the street, which in turn means the other side of the street
## must be open enough so we can walk on it unimpeded"* (PLAYTEST-69), and *"on the side of the
## street where the path was chosen only obstacles that can be bypassed should be possible"*
## (PLAYTEST-77).
##
## **It reads the route's own sidewalk rather than the street.** A street is walkable frontage to
## frontage, so *some* pavement staying open is what a walk needs in general — but the route is
## drawn along one of the two, the kerb tint marks that one, and a row that closes it has taken the
## line the day was pointing at even though the street as a whole is still walkable. So the walk
## this asks for is from one junction to the other **along the band the tree runs down**, over that
## band's own tiles and no others.
##
## **Cumulatively with everything already down**, the way the junction rule reads and for the same
## reason: the street the probe names most often is closed by a pair rather than by one row, and a
## rule that only asked *does this row alone take the band* would accept both of them. Checked
## before the row is accepted and never repaired after — each row in turn is asked whether the day
## it is joining still has a line along every walked sidewalk.
##
## **Only a street has sidewalks.** Where a route's cells stand on an alley, a park cut or a square
## there is no band to walk along and no two ends to walk between, so the rule says nothing about
## that ground rather than inventing an answer for it — a row there is answered by the junction rule
## and by the walkability guarantee. A **precinct** is paved frontage to frontage with no
## carriageway, so a band of it is walkable like any other and the arithmetic is unchanged.
##
## **It subsumes the whole-street question it replaces**: the two bands of a street are not
## four-connected to each other (the carriageway between them is out), so *some pavement is open*
## was already *one band is open* — and this asks it of the band that matters, of every row rather
## than of one, which is strictly the stronger claim.
##
## **A pacing row is not one of the rows it asks about**, and that is the line between this rule and
## the two that govern a beat. This one is about a **width**: ground a standing body takes and
## leaves taken. A beat takes its ground in **time** — *"yeller is something you can time. it stays
## on the route"* — so what governs it is whether the loop leaves an opening
## (`_leaves_a_pacing_beats_opening`) and whether it reaches a crossing she can leave by
## (`_a_pacing_beat_walls_a_sidewalk`, in `_place_one`'s loop). Counting his lens here as a width
## would refuse a man on the route's own sidewalk for the one reason the player has ruled out, and
## counting it against *another* row's placement would refuse a café a band a walk can already pass
## by waiting.
static func _leaves_the_routes_sidewalk_open(candidate: Planned, map: CityMap, corridor: Corridor,
		ground: Dictionary, already: Array[Planned]) -> bool:
	if not corridor or candidate.def.paces or not _counts_against_the_line(candidate):
		return true
	var reach := _line_reach_of(candidate.def)
	for entry: Array in _route_sidewalks(map, ground, corridor):
		var world: Rect2 = entry[2]
		if not _reach_touches(candidate, world, reach):
			continue
		var standing: Array[Planned] = [candidate]
		for plan in already:
			if plan == candidate or plan.def.paces or not _counts_against_the_line(plan):
				continue
			if _reach_touches(plan, world, _line_reach_of(plan.def)):
				standing.append(plan)
		var segment: StreetNetwork.Segment = entry[0]
		if _closes_the_run(map, entry[1], segment.horizontal, standing):
			return false
	return true

## Whether these rows between them leave no walk from one end of a street to the other.
##
## Stated over the street's own ground — both pavements, the carriageway between the kerbs left out
## because a line may not cross there anyway (*"in-block crossings are possible in game but
## shouldn't be counted on by the routing algorithm"*) — and over a four-connected walk, so a
## barrier laid diagonally counts as closing a street exactly as a straight band does. This is
## `tests/probes/m129_zero_cost_line.gd`'s own question, asked at placement time instead of after
## the fact, which is what makes the probe's number the measurement of the rule rather than a
## second opinion about it.
static func _closes_the_street(map: CityMap, segment: StreetNetwork.Segment,
		rows: Array[Planned]) -> bool:
	return _closes_the_run(map, segment.tile_rect(), segment.horizontal, rows)

## The same question over an arbitrary run of a street's ground, which is what lets the width rule
## ask it of one sidewalk band and the pacing rule of the whole street. `horizontal` is the
## direction the walk has to get from one end of `rect` to the other along.
static func _closes_the_run(map: CityMap, rect: Rect2i, horizontal: bool,
		rows: Array[Planned]) -> bool:
	var free := {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if not map.is_open(tile) or _is_a_carriageway_tile(map, tile, horizontal):
				continue
			var at := map.tile_to_world(tile)
			var taken := false
			for plan in rows:
				if _denies(plan, at, _line_reach_of(plan.def)):
					taken = true
					break
			if not taken:
				free[tile] = true

	var last := (rect.end.x - 1) if horizontal else (rect.end.y - 1)
	var queue: Array[Vector2i] = []
	var seen := {}
	for tile: Vector2i in free:
		var at_the_start := tile.x == rect.position.x if horizontal \
				else tile.y == rect.position.y
		if at_the_start:
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

## **A pacing row leaves the line open for part of its beat.** *"Time pass — don't route around
## them"* (PLAYTEST-71): a man walking two hundred and fifty pixels of footway and back is a timing
## problem rather than a routing one, so the ground he denies is the ground his beat **never** leaves
## free, and a line that is clear at some phase of the loop can simply wait for him.
##
## That reading is what makes the beat's opening worth protecting, and it is the whole of what the
## probe finds broken: not a beat that closes a street by itself — the intersection over a walk is
## far smaller than the disc — but a beat whose one open end has something else standing in it.
## *"No other row's reach covers that open end."*
##
## So on a route street carrying a pacing row, the rows reaching it are asked **together** whether a
## walk from one junction to the other survives. Both directions of the collision are the same
## question and this is asked in both: a pacing row is refused ground where the rows already there
## would close its opening, and a standing row is refused the opening a pacing row already leaves.
##
## **It is scoped to the streets a pacing row actually stands on**, which is what keeps it from
## being a second, wider copy of the width rule. Two standing rows closing a street between them is
## a different shape with a different answer, and the milestone does not write a rule for it.
static func _leaves_a_pacing_beats_opening(candidate: Planned, map: CityMap, corridor: Corridor,
		already: Array[Planned]) -> bool:
	if not corridor or not _counts_against_the_line(candidate):
		return true
	var reach := _line_reach_of(candidate.def)
	var streets := {}
	var here := StreetNetwork.segment_containing(map.world_to_tile(candidate.position))
	if candidate.def.paces and here and corridor.depth(here.tile_rect().position) == 0:
		streets[here.key()] = here
	for plan in already:
		if plan == candidate or not plan.def.paces or not _counts_against_the_line(plan):
			continue
		var theirs := StreetNetwork.segment_containing(map.world_to_tile(plan.position))
		if not theirs or corridor.depth(theirs.tile_rect().position) != 0:
			continue
		if _reach_touches(candidate, map.tile_rect_to_world(theirs.tile_rect()), reach):
			streets[theirs.key()] = theirs

	for key: Vector3i in streets:
		var segment: StreetNetwork.Segment = streets[key]
		var rect := map.tile_rect_to_world(segment.tile_rect())
		var standing: Array[Planned] = [candidate]
		for plan in already:
			if plan == candidate or not _counts_against_the_line(plan):
				continue
			if _reach_touches(plan, rect, _line_reach_of(plan.def)):
				standing.append(plan)
		if _closes_the_street(map, segment, standing):
			return false
	return true

## Whether a row's own reach gets anywhere near a rect at all — the cheap filter before the tile
## work. Grown by the line reading's plain disc rather than `field_reach()`, and asked of every
## corner of a beat as well as of where the row stands, since a pacing row's denied ground is
## inside each of those discs.
static func _reach_touches(plan: Planned, rect: Rect2, reach: float) -> bool:
	var grown := rect.grow(reach)
	if grown.has_point(plan.position):
		return true
	for point in plan.path:
		if grown.has_point(point):
			return true
	return false

## Whether a tile between two junctions is carriageway a line may not cross there.
##
## **The tile's own type decides, not its offset across the corridor.** A four-block calm zone is
## painted over the streets between its blocks, so those tiles sit at a road offset and are grass
## somebody walks on — *"an absorbed street is calm ground, not a closure"*. A precinct is paving
## frontage to frontage with no carriageway at all, and its middle tiles are not `ROAD` either, so
## the same test covers it without naming it.
static func _is_a_carriageway_tile(map: CityMap, tile: Vector2i, horizontal: bool) -> bool:
	if not CityMap.is_road_offset(CityMap.corridor_offset(tile.y if horizontal else tile.x)):
		return false
	var type := map.tile_at(tile)
	return type == GameEnums.TileType.ROAD or type == GameEnums.TileType.CROSSING

## Distance in tiles from a tile to the edge of the map along a direction, less a
## one-block margin so a route always ends inside the city rather than against the wall.
static func _room_along(map: CityMap, tile: Vector2i, direction: Vector2i) -> int:
	var margin := CityMap.period()
	var room := 0
	if direction.x > 0:
		room = map.size.x - 1 - tile.x
	elif direction.x < 0:
		room = tile.x
	elif direction.y > 0:
		room = map.size.y - 1 - tile.y
	else:
		room = tile.y
	return maxi(0, room - margin)

## A route down the corridor the tile sits on, for traffic and for anyone walking a dog.
##
## Direction is a coin flip *between the directions that have room*, and the length is
## clamped to what actually fits. Clamping the endpoint to the map bounds instead — the
## first version — parked every long route hard against the city wall, which put the fire
## the engine leaves behind out on the boundary every single time.
static func _along_street_path(map: CityMap, tile: Vector2i, def: EventDef,
		rng: RandomNumberGenerator) -> PackedVector2Array:
	var vertical_corridor := CityMap.corridor_offset(tile.x) >= 0
	var forward := Vector2i.DOWN if vertical_corridor else Vector2i.RIGHT
	var backward := -forward

	var forward_room := _room_along(map, tile, forward)
	var backward_room := _room_along(map, tile, backward)
	var along := forward
	var room := forward_room
	# Prefer whichever way fits the whole route; if both do, or neither, flip a coin.
	if backward_room > forward_room and backward_room >= def.path_length_tiles:
		along = backward
		room = backward_room
	elif forward_room >= def.path_length_tiles and backward_room >= def.path_length_tiles:
		if rng.randf() < 0.5:
			along = backward
			room = backward_room
	elif backward_room > forward_room:
		along = backward
		room = backward_room

	var length := mini(def.path_length_tiles, room)
	# Stop short of a closed street rather than driving through the barrier at the end of it — and
	# short of a calm zone's absorbed corridor as well. A corridor that ends in a park is
	# not a corridor a delivery van can drive down, and unlike a closure there is nothing there
	# to hit: the route would simply cross the grass.
	var from_a_street := map.is_street(tile)
	for step in range(1, length + 1):
		var next := tile + along * step
		if map.is_closed(next) or (from_a_street and not map.is_street(next)):
			length = step - 1
			break
	if length <= 0:
		return PackedVector2Array()

	# And never *finish* jammed against the city wall. `_room_along` keeps a period's margin from
	# the boundary, which is enough on its own — but the truncation above can cut a route down to
	# almost nothing, and a route that starts near the edge and is cut short finishes there. What
	# that costs is stated on the loop below: a fire engine leaves its fire wherever it stops, and
	# a fire on the boundary was the bug that put this margin here in the first place. Refusing is
	# a re-roll; `tests/test_events.gd` checks it over all fourteen days.
	var finish := tile + along * length
	var edge := CityMap.period()
	var at_end: int = finish.x if along.x != 0 else finish.y
	var limit: int = map.size.x if along.x != 0 else map.size.y
	if at_end < edge or at_end > limit - edge:
		return PackedVector2Array()

	return PackedVector2Array([map.tile_to_world(tile), map.tile_to_world(finish)])

## A route straight across the street the tile sits on. A cat runs *across* traffic, so the
## path is perpendicular to the road it starts from.
static func _cross_street_path(map: CityMap, tile: Vector2i) -> PackedVector2Array:
	var vertical_road := CityMap.corridor_offset(tile.x) >= 0
	var across := Vector2i.RIGHT if vertical_road else Vector2i.DOWN
	var reach := Tuning.STREET_WIDTH
	var from := map.tile_to_world(tile - across * reach)
	var to := map.tile_to_world(tile + across * reach)
	return PackedVector2Array([from, to])

# ---------------------------------------------------------------- park rules ---

## The calm ground nothing may be placed near today: every calm area she has not settled in this
## act. *(2026-08-31: "why are 7-9 unvisited calm areas spoiled? Just don't place events there!")*
##
## **This is a placement rule, and it used to be a repair.** `_ensure_one_usable_park` below plans
## the whole day and then deletes whatever landed on the calm — which spends budget on events the
## player never sees, makes the day's density depend on how many happened to land badly, and only
## ran at all on the days its own early return did not fire. Measured over 64 planned days before
## this existed: **6.4 to 7.6 of the seven-to-nine unvisited calm areas were spoiled on a raw day**,
## and the strip was throwing away twelve to eighteen events to fix it. Refusing the ground costs
## nothing and the events go somewhere else instead, which is the same argument `CLAUDE.md` makes
## about closures — *checked before they are accepted, not repaired afterwards.*
##
## The two exemptions are the ones `_ensure_one_usable_park` already had, and they are what keeps a
## park **contested** rather than sterile: an `AMBIENT` event is a permanent feature of the map (a
## playground makes a park contested and leaves the far side calm), and a scar is something that
## already burnt. Neither is placed through `_place_one`, so neither is affected by this at all —
## which is the reason it goes here rather than in `_ground_for`.
##
## And the areas she *has* used are deliberately not in the list: `_spoil_the_parks_she_used` is
## aimed at exactly those, and this rule would otherwise cancel it.
static func _calm_to_leave_alone(map: CityMap, used_calm: Array[Vector2i]) -> Array[Rect2]:
	var leave_alone: Array[Rect2] = []
	for block in map.calm_blocks:
		if not used_calm.has(block):
			leave_alone.append(map.tile_rect_to_world(_calm_rect(map, block)))
	return leave_alone

## Whether a candidate's field would reach any of them.
static func _reaches_any(candidate: Planned, rects: Array[Rect2]) -> bool:
	for rect in rects:
		if _reaches_rect(candidate, rect):
			return true
	return false

## docs/CITY.md: at least one calm zone stays usable every day, or the day has no safe
## ground and the player has no move. Whichever one is least disturbed keeps its quiet.
##
## **It is the last line rather than the rule, and since 2026-08-31 it usually finds nothing to
## do.** What keeps an *unvisited* area clean is `_calm_to_leave_alone`, at placement; this runs
## afterwards and asks the one question placement cannot answer — has the day ended up with no
## clean calm ground anywhere, which can only happen once she has settled in every area there is.
## Two independent mechanisms rather than one, for the same reason a reachability check is kept
## under the corridor: the day a placement rule stops holding is the day a run becomes unwinnable,
## and nothing else would say so.
##
## A day can only be won on calm ground, so this is the difference between a hard day and an
## impossible one. The set of calm zones is whatever the arcs have left — a requisitioned park is
## not a candidate, because it is not calm any more.
##
## Ambient events do not count as spoiling. A playground is a permanent feature of the map,
## not something that went wrong today — it makes a park *contested*, which is the point,
## and it leaves the far side of the block calm. Counting it here would mean stripping a
## playground out of one park every single day.
## It also takes the block she settled in yesterday, and protects a **different** one where it
## can. Without that the two halves fight: the day deliberately puts something in her
## park, and then this rule, looking for the least disturbed calm ground, finds the block with
## exactly one spoiler on it and strips the very event that was the point.
static func _ensure_one_usable_park(map: CityMap, planned: Array[Planned],
		used_calm: Array[Vector2i] = []) -> void:
	if map.calm_blocks.is_empty():
		return

	var spoilers := {}   # calm block -> Array[Planned]
	var clean := false
	for block in map.calm_blocks:
		# The calm *ground*, not the whole block. A courtyard's calm is a four-tile court
		# inside a residential block; protecting the block would strip every event off a
		# street the player was never going to settle on anyway.
		var lot := map.tile_rect_to_world(_calm_rect(map, block))
		var found: Array[Planned] = []
		for plan in planned:
			if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed():
				continue
			# **A scar is not today's noise.** It is exempt for exactly the reason the
			# playground above is: it is a permanent feature of the map, and stripping it would
			# make a burnt-out building that has been on that corner since day 3 vanish for one
			# day and come back the next. It was strippable until a day-9 plan happened to make
			# its block the least disturbed one, and `tests/test_acts.gd` caught it by luck rather
			# than by design — the assertion it broke is "the shell is still there on day 9".
			if plan.permanent:
				continue
			if _reaches_rect(plan, lot):
				found.append(plan)
		if found.is_empty():
			clean = true
		spoilers[block] = found
	if clean:
		return

	# **Every calm area she has not used this act stays clean, not just one of them.**
	# `MIN_CALM_BLOCKS` is derived as an act's worth of days **plus one** on the assumption that the
	# only thing which burns an area is *going* to it — so an area spoiled before she has ever been
	# there brings the run's hard stop a day closer.
	#
	# That rule is enforced at **placement** (see `_calm_to_leave_alone`), so by the time this runs
	# there is normally nothing to strip. What is left here is the case placement cannot answer:
	# **she has been to all of them**, so nothing was protected and the day could have no clean
	# ground on it at all. A winnable day outranks a fresh decision, so the least disturbed area is
	# cleared and the rest stand.
	var untouched: Array[Vector2i] = []
	for block in map.calm_blocks:
		if not used_calm.has(block):
			untouched.append(block)

	if untouched.is_empty():
		var least: Vector2i = map.calm_blocks[0]
		for block in map.calm_blocks:
			if spoilers[block].size() < spoilers[least].size():
				least = block
		untouched = [least] as Array[Vector2i]

	for block in untouched:
		for plan in spoilers[block]:
			planned.erase(plan)

## The rect of a calm block's actual calm ground, falling back to the whole lot. The same question
## `ClosurePlanner.CalmArea.rect` answers, and the same function now — a courtyard's calm is its
## court alone, and there is exactly one place that says so.
static func _calm_rect(map: CityMap, block: Vector2i) -> Rect2i:
	return ClosurePlanner.calm_area_rect(map, block)

## Checkpoints, barricades and roadblocks physically close streets, and from Act IV several
## can land on the same day. Any combination that seals the home off from every park makes
## the day unwinnable in a way the player cannot see coming, so obstructions are dropped —
## widest first — until a route exists again.
##
## Hard-fail events count as walls here too: an abduction in progress is not something you
## walk through to reach the park behind it.
static func _ensure_the_city_is_still_walkable(map: CityMap, planned: Array[Planned]) -> void:
	var blockers: Array[Planned] = []
	for plan in planned:
		if not plan.is_placed():
			continue
		if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
			blockers.append(plan)
	if blockers.is_empty():
		return

	blockers.sort_custom(func(a: Planned, b: Planned) -> bool:
		return _blocking_radius(a) > _blocking_radius(b))

	# Built once and asked once per blocker dropped, which is a handful of iterations at most —
	# the grid is the day's tiles, which none of this loop changes.
	var grid := ReachabilityGrid.build(map)
	while not blockers.is_empty() and not _park_is_reachable(map, grid, blockers):
		planned.erase(blockers.pop_front())

static func _blocking_radius(plan: Planned) -> float:
	return maxf(plan.def.obstructs_radius, plan.def.inner_radius if plan.def.hard_fail else 0.0)

## Whether the grid still finds a way from the home to some calm tile, with `map.closed_tiles` —
## today's closures, at the precision `RoadClosure.tiles()` now gives them — plus every blocker's
## own obstruction circle added on top.
##
## **This asks the same grid `ClosurePlanner._invariant_holds` does**, so the two reachability
## answers this milestone existed to unify are one function apart rather than two implementations
## that could drift: both are `ReachabilityGrid.flood()`/`reaches()` under a `blocked` set, and the
## grid does not care whether the tiles in it came from a candidate's barrier or an event's circle.
static func _park_is_reachable(map: CityMap, grid: ReachabilityGrid, blockers: Array[Planned]) -> bool:
	var blocked := map.closed_tiles.duplicate()
	for plan in blockers:
		var radius := _blocking_radius(plan)
		var reach := ceili(radius / float(Tuning.TILE_SIZE))
		var centre := map.world_to_tile(plan.position)
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var tile := centre + Vector2i(dx, dy)
				if map.tile_to_world(tile).distance_to(plan.position) <= radius:
					blocked[tile] = true

	var reached := grid.flood([map.home_rect.position], blocked)
	for tile in map.calm_tiles():
		if grid.reaches(tile, blocked, reached):
			return true
	return false

## Whether an event's field touches a rect at all — grown by `field_reach()` rather than
## `outer_radius` alone, so a segment's own `half_length` is not dropped from the streaming
## question the way it would be from a disc's.
static func _reaches_rect(plan: Planned, rect: Rect2) -> bool:
	var grown := rect.grow(plan.def.field_reach())
	if grown.has_point(plan.position):
		return true
	for point in plan.path:
		if grown.has_point(point):
			return true
	return false
