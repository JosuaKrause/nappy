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

## What the day is placing a row **for**, which is the only thing that makes *wall* and *friction*
## mean anything. See `docs/CITY.md`, "The words for it".
##
## Three of the four answers come straight off the design: lethal and expensive rows are the
## **walls** that bound the corridor, benign rows are **friction** on the route, and a one-shot is a
## **set piece** placed so that she actually meets it. The fourth is the interesting one.
##
## **`NONE` is not a leftover bin, it is the honest answer for anything the day did not site
## against the corridor at all.** An `AHEAD_OF_PLAYER` row is the case that proves it: a charging
## dog is lethal and is not a wall, because `EventDirector` puts it in front of wherever she turns
## out to be walking and the scheduler never chooses a tile for it. Calling it a wall would put a
## mark on the telemetry map claiming a placement that nothing made — which is the exact failure
## the picture exists to catch, arriving through the legend. `TOWARD_PLAYER` is sited by the same
## director for the same reason and gets the same answer.
##
## **A wall is not only the lethal rows.** The ground off the routes *ranges from very costly to
## deadly*, so an expensive row is a wall too and `Tuning.WALL_WORTH_OF_COST` is where the line
## falls. Cheap rows stay friction and stay on the corridor, which is what keeps the routes worth
## walking rather than merely survivable.
##
## It is stated over `walk_through_cost()` — the same integral `tests/test_danger.gd` orders the
## caret by — rather than over a new field, because *how expensive a row is* is a question the
## catalogue already answers, and a second answer to it is how two tables of one fact drift apart.
static func _role_for(def: EventDef) -> GameEnums.BlockerRole:
	if def.spawn_mode != EventDef.SpawnMode.MAP or def.kind == GameEnums.EventKind.AMBIENT:
		return GameEnums.BlockerRole.NONE
	if def.kind == GameEnums.EventKind.ONE_SHOT:
		return GameEnums.BlockerRole.SET_PIECE
	if def.hard_fail or def.walk_through_cost() >= Tuning.WALL_WORTH_OF_COST:
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
## What denies calm ground is holding the meter above `EXCITEMENT_CALM_THRESHOLD` against a decay
## the calm multiplier has raised to 7.7/s — so a busker at intensity 9 has a *useful* radius of
## 100px whatever his 190px reach says, in a lot 704px across, and denies about three percent of a
## four-block calm zone. A day that rolls one spoiler for the block she used is a day she settles in
## that same block.
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
## about a city. Here the job is covering a lot, and a leaf blower covers four times the ground a
## busker does — so the roll is by area as well as by weight, and the quiet rows become the garnish
## on a spoiled park rather than half of it. It stays a roll rather than becoming "always the
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
## **Not the outer radius**, which is where it stops reaching at all. Calm ground fills the meter at
## `EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` times the walking decay, so anywhere a source emits less
## than that is somewhere she can still settle — and for every act I row that is most of its own
## field. Getting this wrong is how one busker was ever thought to spoil a park.
static func _denial_radius(def: EventDef) -> float:
	var decay := Tuning.EXCITEMENT_DECAY_WALKING * Tuning.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER
	if def.intensity <= decay:
		return def.inner_radius
	# `Tuning.falloff` is `1 - t²`, inverted for the t at which it equals the decay.
	var t := sqrt(1.0 - decay / def.intensity)
	return def.inner_radius + t * (def.outer_radius - def.inner_radius)

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
		var placement := _place_one(def, rng, map, planned, ground, leave_alone, corridor)
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
		var placement := _place_one(def, rng, map, beside, ground, leave_alone, corridor, site)
		if placement:
			placement.set_piece_group = "%s@%d" % [def.id, day]
			made.append(placement)
	if made.is_empty():
		var anywhere := _place_one(def, rng, map, already, ground, leave_alone, corridor)
		if anywhere:
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
		var placement := _place_one(def, rng, map, planned, ground, leave_alone, corridor)
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
static func _place_one(def: EventDef, rng: RandomNumberGenerator, map: CityMap,
		already: Array[Planned] = [], ground := {}, leave_alone: Array[Rect2] = [],
		corridor: Corridor = null, site := NO_SITE) -> Planned:
	var role := _role_for(def)
	# An `AHEAD_OF_PLAYER` or `TOWARD_PLAYER` event is budgeted here and sited by `EventDirector`
	# while the player walks. Costing it here rather than giving the director its own allowance is
	# deliberate: the cat competes with the café tables and the roadworks for the same day, so
	# making the cat matter cannot quietly make the day denser as well.
	if def.spawn_mode != EventDef.SpawnMode.MAP:
		return Planned.new(def, Vector2.INF)

	var open_candidates := _ground_for(def, map, ground, corridor, role, site)
	if open_candidates.is_empty():
		return null

	var best: Planned = null
	var best_room := -INF
	for _try in Tuning.EVENT_PLACEMENT_TRIES:
		var tile: Vector2i = open_candidates[rng.randi_range(0, open_candidates.size() - 1)]
		var candidate := _build_placement(def, map, tile, rng)
		if not candidate:
			continue
		candidate.role = role
		# Before the spacing, because this one is about the *ground* rather than about what is
		# already on it, and because it can never bend.
		if _reaches_any(candidate, leave_alone):
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
	var key := "%s|%d|%d|%s|%s" % [def.placement, def.pavement_side, role, site, def.hard_fail]
	if ground.has(key):
		return ground[key]
	var aimed: Array[Vector2i] = []
	# **A set piece is placed on one named street**, so this half is containment rather than a
	# weight. The rect is the street itself and not a radius round it: a street is the unit every
	# other placement decision in this milestone is stated in, and a set piece has to be something
	# she walks past on the way through rather than something near where she walked.
	var named := StreetNetwork.by_key(site) if site != NO_SITE else null
	var only := named.tile_rect() if named else Rect2i()
	for tile in base:
		if site != NO_SITE:
			if only.has_point(tile):
				aimed.append(tile)
			continue
		for _copy in _copies_of(tile, corridor, role, def.hard_fail):
			aimed.append(tile)
	ground[key] = aimed
	return aimed

## A placement with no particular street asked for. Not `Vector3i.ZERO`, which is the key of a real
## street — the one running east out of the north-west corner.
const NO_SITE := Vector3i(-1, -1, -1)

## Every tile of the right kind that anything may stand on today, precinct weighting included.
##
## **A precinct is a retail street**, so it carries more of the day than a length of ordinary
## pavement does: it is where the cafés and the market stalls and the buskers are.
static func _open_ground_for(def: EventDef, map: CityMap, ground: Dictionary) -> Array[Vector2i]:
	var key := "%s|%d" % [def.placement, def.pavement_side]
	if ground.has(key):
		return ground[key]
	var doorstep := _the_street_she_starts_on(map)
	var open: Array[Vector2i] = []
	for type in def.placement:
		for candidate in map.tiles_of_type(type as GameEnums.TileType):
			# A closed street is not somewhere anyone can get to, so it is not somewhere an event
			# can usefully happen: the player would never see it and the scheduler would have
			# spent budget on nothing.
			if map.is_closed(candidate) or doorstep.has_point(candidate) \
					or not _wants_this_side(def, map, candidate):
				continue
			open.append(candidate)
			if map.street_kind_at(true, candidate) == GameEnums.StreetKind.PEDESTRIAN \
					or map.street_kind_at(false, candidate) == GameEnums.StreetKind.PEDESTRIAN:
				for _extra in Tuning.EVENT_PRECINCT_WEIGHT - 1:
					open.append(candidate)
	ground[key] = open
	return open

## How many more times a tile is offered to the roll because of what the day is placing there.
##
## Zero means the tile is not offered at all, and there is exactly one case of it — **a wall is
## never inside the corridor.** Every other preference here is a weight, because a weight cannot
## starve a row of ground and a filter can. What makes this one safe to state absolutely is that
## the rest of the city stays available to it: a wall wants its own band, it settles for anywhere
## else off the routes, and only the routes themselves are refused.
##
## **The wall band has a gradient in it, and the gradient is the instruction**: the ground off the
## paths ranges from *very costly* to *deadly*. Stray one turning and it is expensive; stray further
## and it ends the day. So a **very costly** wall is pulled to the rim,
## which is the turning she can see from the junction she is standing at, and a **lethal** one is
## pulled past it. Both keep the whole off-corridor city as a weight rather than a filter, so
## neither can be starved of ground on a day whose corridor happens to be most of the map.
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
			if away == 0:
				return 0
			if lethal:
				return Tuning.WALL_DEEP_WEIGHT if away >= 2 else 1
			if away != 1:
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
			if _keeps_its_field_clear(plan) and gap < plan.def.outer_radius:
				return -INF
			if plan.def.id == candidate.def.id:
				room_same = minf(room_same, gap)
		if _keeps_its_field_clear(candidate) and gap < candidate.def.outer_radius:
			return -INF
	return INF if room_same >= Tuning.EVENT_SPACING_SAME else room_same

## Whether the clearance rule is about this placement: a lethal event with nothing else inside
## its whole `outer_radius`.
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
## **A `WALL` is exactly the off-corridor set and that is by construction, not by coincidence.**
## `_copies_of` offers a wall zero copies of any tile inside the corridor, so a placement carrying
## this role is off the routes or it does not exist. What keeps its clearance is everything else: a
## set piece, which is sited where every route passes, and anything the day placed for a reason that
## is not about the corridor at all.
##
## The telegraph contract is untouched by this and must not be "fixed" alongside it. That one is
## stated over a single event's own geometry, `Tuning.validate_event()` checks it on load, and
## nothing here changes what any event owes the player who sees it coming.
static func _keeps_its_field_clear(plan: Planned) -> bool:
	return plan.def.hard_fail and plan.role != GameEnums.BlockerRole.WALL

## The closest two events come to each other, counting the whole of a route at both ends.
##
## Measured from both sides on purpose: the closest point of two segments is an endpoint of at
## least one of them, so checking one event's ends against the other's route and not the other
## way round misses the case where it is the *other* one's end that is close.
static func _gap_between(a: Planned, b: Planned) -> float:
	var gap := INF
	for point in a.ends():
		gap = minf(gap, b.distance_from(point))
	for point in b.ends():
		gap = minf(gap, a.distance_from(point))
	return gap

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

## The rect of a calm block's actual calm ground, falling back to the whole lot.
static func _calm_rect(map: CityMap, block: Vector2i) -> Rect2i:
	var layout: BlockLayout = map.block_layouts.get(block)
	if layout and BlockLayout.has(layout.open_rect):
		return layout.open_rect
	return CityMap.block_rect(block)

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

	while not blockers.is_empty() and not _park_is_reachable(map, blockers):
		planned.erase(blockers.pop_front())

static func _blocking_radius(plan: Planned) -> float:
	return maxf(plan.def.obstructs_radius, plan.def.inner_radius if plan.def.hard_fail else 0.0)

static func _park_is_reachable(map: CityMap, blockers: Array[Planned]) -> bool:
	# Today's closures are part of what is in the way. The closure planner has already left
	# two routes to two calm areas standing, so this can only ever be tightened by the
	# events on top of them — but it has to count both or it will happily approve a
	# checkpoint on the one street the closures left open.
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

	var reached := map.walk_field(map.home_rect.position, blocked)
	for tile in map.calm_tiles():
		if map.reaches(reached, tile):
			return true
	return false

## Whether an event's outer radius touches a rect at all.
static func _reaches_rect(plan: Planned, rect: Rect2) -> bool:
	var grown := rect.grow(plan.def.outer_radius)
	if grown.has_point(plan.position):
		return true
	for point in plan.path:
		if grown.has_point(point):
			return true
	return false
