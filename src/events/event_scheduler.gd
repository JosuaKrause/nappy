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
	## one gets its facing from the direction it is travelling and ignores this. *(M34: a lorry
	## backing into a yard has to have its back to the yard, and only the placement knows which
	## side of the street the yard is on.)*
	var facing := Vector2.RIGHT

	func _init(definition: EventDef, at: Vector2,
			route := PackedVector2Array()) -> void:
		def = definition
		position = at
		path = route

	## The live instance, while this plan is streamed in. Owned by `EventManager`: a plan is the
	## day's intention and the instance is the few seconds it exists for, and since M27 those
	## are no longer the same span of time.
	var live: EventInstance = null
	## True once the event has run its course, so walking back past it does not start it again.
	var spent := false
	## True for something the *run* left here rather than something today rolled — a burnt-out
	## shell, a barricade. It is world history and the day may not tidy it away.
	var permanent := false
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

## Budget grows with the day, so late days are denser as well as nastier.
##
## Playtest 03, finding 1: the old `3 + day * 1.4` gave day 1 **four** events for a 7x7-block
## city — one per twelve blocks — and the traced day contains zero `near` entries. The player
## crossed the city, sat in a courtyard, came home, and was never within reach of anything.
##
## The number was deliberately not moved on its own. Eleven of eighteen events cost under
## fifteen points of a hundred-point meter to walk straight through, and three were *negative*,
## so quadrupling the budget before M19 would have bought four times as much scenery. The
## consequences land in the same milestone as the density (playtest 03, decision 1): bodies are
## solid, the carriageway is lethal, and a café or a dog owns the pavement it is on.
##
## The shape is kept — the escalation is still roughly linear in the day — and the floor is
## raised, which is what "the beginning is challenging too" (playtest 02, decision 9) asks for.
##
## The budget is not the count and the difference is not small: a part of it is spent on events
## the day then throws away, because `_ensure_one_usable_park` strips whatever reaches the
## calmest block and `_ensure_the_city_is_still_walkable` drops obstructions that would seal the
## city. So the number is set by *measuring what a day places* over several seeds rather than by
## arithmetic. Re-measure it, do not re-derive it, if the catalogue's costs move.
##
## **M28 moved it to playtest 05's stated target: one event per block.** *"I want one event per
## block. The dog walker decision should happen meaningfully — I want to have to make that
## decision at least twice on day one."* The city is 7x7 blocks, so that is **49 placed on day
## 1**, against the 13 the old 18 bought. The budget alone could never have got there — the
## day-1 pool's `max_per_day` values summed to 18, so a budget of 100 placed the same 13 events
## — which is what `CLAUDE.md`'s *"a budget the catalogue cannot spend is not density"* is
## about. The caps moved first; this followed, measured.
##
## The escalation is still linear in the day and is now steep enough to be felt as one: day 14
## carries about half again as many events as day 1, and a larger share of them are act III and
## IV rows rather than more dog walkers, because those caps rose too.
static func budget_for(day: int) -> int:
	return 69 + floori(day * 6.2)

## Plans a day. `consumed_one_shots` is read and appended to, so a one-shot fires once
## per run.
##
## `settled_yesterday` is the calm block the baby actually went to sleep in on the previous day,
## or `(-1, -1)` for none. See `_spoil_the_park_she_used`.
static func build_day(day: int, rng: RandomNumberGenerator, map: CityMap,
		consumed_one_shots: Array[String], scars: Array[Dictionary] = [],
		settled_yesterday := Vector2i(-1, -1)) -> Array[Planned]:
	var planned: Array[Planned] = []
	# Captured before anything draws from it. Every phase below gets its own stream off this, which
	# is what makes a retried day the same day — see `_stream`.
	var base := rng.seed

	planned.append_array(_place_ambient(day, map))
	planned.append_array(_place_scars(day, scars))
	_place_scripted(day, _stream(base, 1), map, planned)
	_place_one_shots(day, _stream(base, 2), map, consumed_one_shots, planned)
	_spoil_the_park_she_used(day, _stream(base, 3), map, planned, settled_yesterday)
	_fill_with_recurring(day, base, map, planned)
	_ensure_the_run_is_taught(day, planned)

	_ensure_one_usable_park(map, planned, settled_yesterday)
	_ensure_the_city_is_still_walkable(map, planned)
	return planned

## A private RNG for one phase of the day, derived from the day's seed and a salt.
##
## **A retried day has to be the same day, and it was not.** *(M39, playtest 10 finding 5: "the
## tutorial dog on day 3 only appeared once (I died) then it didn't appear again".)* `docs/TODO.md`
## has claimed since M32 that *"the retry is the same day — everything about one is deterministic
## from the seed and the day number"*, and five seeds out of five disprove it. The six phases above
## ran off **one** stream in sequence, so anything that changed how much an earlier phase drew moved
## everything after it, and two things change between attempts by design:
##
## - `_place_one_shots` skips a one-shot the run has already spent, and it skipped it with a
##   `continue` **before** drawing its `randf()`. So the second attempt at day 3 — the day the fire
##   engine runs — started `_fill_with_recurring` one value earlier and produced a different city's
##   worth of events. In the trace, `homeless_yeller` goes from two to eight and `cyclist` from none
##   to three between two consecutive attempts at the same day.
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
## *(M39, playtest 10 finding 5.)* `EventDirector._teach_the_run` moves a pursuit to the head of the
## owed list on `RUN_TAUGHT_DAY` and says outright what happens otherwise: *"if the day happened not
## to buy one, there is nothing to teach and nothing happens."* `charging_dog` is weight 1.4 of a
## day-3 pool, so whole day 3s with none of them exist — the probe finds them — and a player can
## therefore reach act II never having been shown the one control the game will later require.
##
## It is added **outside** the budget rather than competing for it, and that is the exception being
## made honestly: everywhere else in this file the density is the budget, and a lesson that only
## happens when the dice agree is not a lesson. One event on one day of fourteen.
static func _ensure_the_run_is_taught(day: int, planned: Array[Planned]) -> void:
	if day != Tuning.RUN_TAUGHT_DAY:
		return
	for plan in planned:
		if plan.def.pursues:
			return
	for def in EventCatalogue.available_on(day):
		if not def.pursues or def.spawn_mode != EventDef.SpawnMode.AHEAD_OF_PLAYER:
			continue
		planned.append(Planned.new(def, Vector2.INF))
		Telemetry.note("plan", "day %d bought no pursuit, so the run lesson is added: %s"
				% [day, def.id])
		return

# ------------------------------------------------------- the city remembers ---

## Puts something on the calm block she settled in yesterday. *(M24, playtest 05 finding 4:
## "I was able to go to the same park on day one and two — this shouldn't be possible.")*
##
## The finding is not that repetition is boring. It is that **the game's only verb stopped
## being a decision on day two**: a player who found a good park on day 1 has no question left
## to answer, and route planning is the whole game. Playtest 03 found the calm area was a lap
## rather than a route (M21); this is the same complaint one scale up, about *which* calm area.
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
## **It has to cover the ground, not stand in it.** *(M35, playtest 08 finding 1: "the robber in the
## park is still ineffective — I can use the same park every day — and there is only one robber".
## Playtest 07 asked for the same thing first: "blocking a park etc should have multiple robbers so
## the entire area is dangerous or a full block party or other things that completely block out the
## space.")*
##
## M24 placed exactly one event and the arithmetic was never done. A busker is intensity 9 over a
## 190px reach, and what actually denies calm ground is holding the meter above
## `EXCITEMENT_CALM_THRESHOLD` against a decay the calm multiplier has already raised to 7.7/s — so
## his *useful* radius is 100px, not 190, in a lot that is 704px across. He denied about three
## percent of a four-block calm zone. The trace says exactly that: day 2 rolls a spoiler for the
## block she used, and she settles in that same block at 36.1s.
##
## So the spoiler is a **crowd** now: one thing per cell of a grid laid over the calm ground, sized
## from what each of them can actually deny, capped by `SPOILERS_TO_DENY_A_PARK`. Each cell rolls
## its own def rather than repeating one, which is both the fiction — a park that is busy today is
## busy with several different things — and the honest way round the art gap `CLAUDE.md` has carried
## since M22: nine copies of the same `person.svg` standing in a field would read as a duplicated
## sprite, which is exactly what the spacing rule at `_room_around` exists to prevent everywhere
## else.
##
## Silent if she did not settle anywhere yesterday, or settled somewhere that is no longer calm.
static func _spoil_the_park_she_used(day: int, rng: RandomNumberGenerator, map: CityMap,
		planned: Array[Planned], block: Vector2i) -> void:
	if block.x < 0 or not (block in map.calm_blocks):
		return
	# One calm area cannot be spoiled: it is the only one there is, and the guarantee that a day
	# is winnable outranks the guarantee that it is a fresh decision.
	if map.calm_blocks.size() < 2:
		return

	var lot := _calm_rect(map, block)
	var open: Array[Vector2i] = []
	for tile in map.rect_tiles(lot):
		if not map.is_closed(tile):
			open.append(tile)
	if open.is_empty():
		return

	var ground := map.tile_rect_to_world(lot)
	var pool := _things_to_put_in_a_park(day, ground)
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
## *(M34.)* The middle test used to be `obstructs_radius > 0`, which meant the same thing right up
## until everything that stands still acquired a body. A busker is 18px across and a lot is 704px:
## he is loud and he is walked around, which is the whole job. `OBSTRUCTION_A_PARK_CAN_HOLD` is
## where that stops being true, and it is the rule this always was rather than a relaxation of it.
##
## *(M35 made that allowance depend on the ground, which is what it always meant.)* A body that is
## nothing in a four-block calm zone is a wall across a four-tile courtyard, and a fixed number
## cannot be both — so it is a sixteenth of the shortest side of the calm ground, floored at the old
## constant. That is what lets a market take over a whole park and keeps it out of a back yard.
static func _things_to_put_in_a_park(day: int, ground: Rect2) -> Array[EventDef]:
	var allowed := maxf(Tuning.OBSTRUCTION_A_PARK_CAN_HOLD,
			minf(ground.size.x, ground.size.y) / 16.0)
	var suitable: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day):
		if def.hard_fail or def.mobile:
			continue
		if def.obstructs_radius > allowed:
			continue
		if def.spawn_mode != EventDef.SpawnMode.MAP:
			continue
		suitable.append(def)
	return suitable

## Permanent marks left by earlier days, placed again exactly where they happened.
static func _place_scars(day: int, scars: Array[Dictionary]) -> Array[Planned]:
	var planned: Array[Planned] = []
	for scar in scars:
		if int(scar["since_day"]) >= day:
			continue
		var def := EventCatalogue.by_id(String(scar["id"]))
		if def:
			var plan := Planned.new(def, scar["position"])
			plan.permanent = true
			planned.append(plan)
	return planned

# ----------------------------------------------------------------- placement ---

static func _place_ambient(day: int, map: CityMap) -> Array[Planned]:
	var planned: Array[Planned] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.AMBIENT, day):
		match def.ambient_source:
			EventDef.AmbientSource.PLAYGROUND:
				for rect in map.playgrounds:
					planned.append(Planned.new(def, map.tile_rect_to_world(rect).get_center()))
			_:
				pass
	return planned

static func _place_scripted(day: int, rng: RandomNumberGenerator, map: CityMap,
		planned: Array[Planned]) -> void:
	for def in EventCatalogue.of_kind(GameEnums.EventKind.SCRIPTED, day):
		var placement := _place_one(def, rng, map, planned)
		if placement:
			planned.append(placement)

static func _place_one_shots(day: int, rng: RandomNumberGenerator, map: CityMap,
		consumed: Array[String], planned: Array[Planned]) -> void:
	for def in EventCatalogue.of_kind(GameEnums.EventKind.ONE_SHOT, day):
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
		var placement := _place_one(def, rng, map, planned)
		if not placement:
			# The roll passed and the city had nowhere to put it, so the one-shot is *not*
			# consumed and will be rolled for again tomorrow. Worth a line of its own: from
			# the outside this looks identical to a roll that failed.
			Telemetry.note("roll", "one-shot %s: %.2f <= %.2f but nowhere to place it"
					% [def.id, roll, threshold])
			continue
		planned.append(placement)
		consumed.append(def.id)
		Telemetry.note("roll", "one-shot %s: %.2f <= %.2f — fires at %s"
				% [def.id, roll, threshold,
				TelemetryLog.tile(map.world_to_tile(placement.position))])

## Fills the day's budget, **one stream per attempt**.
##
## *(M39, finding 5.)* The stream is derived from the attempt number rather than shared across the
## whole fill, so how much any one placement draws — `_place_one` re-rolls up to
## `EVENT_PLACEMENT_TRIES` times and returns early when a candidate is perfect — cannot move the
## placements after it. That is what makes a retried day recognisably the same day even when the
## run's own history has changed the ground: a scar still displaces the events it actually stands
## on, and every other event is where it was yesterday.
static func _fill_with_recurring(day: int, base: int, map: CityMap,
		planned: Array[Planned]) -> void:
	var eligible := EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day)
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
		var placement := _place_one(def, rng, map, planned)
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
## `already` is what the day has planned so far, and since M28 it is what keeps the density
## legible. Placement is a uniform random tile, and until the caps were raised the cap of three
## was the only reason two dog walkers never landed on the same stretch of pavement. It is a
## rule of its own now: several candidates are offered and the first that clears
## `EVENT_SPACING_SAME` from its own kind and `EVENT_SPACING_ANY` from everything else wins.
##
## The fallback is the roomiest candidate offered rather than nothing, because a scripted event
## has to happen: on a map with fifty events on it the honest answer is the best spot left.
static func _place_one(def: EventDef, rng: RandomNumberGenerator, map: CityMap,
		already: Array[Planned] = []) -> Planned:
	# An `AHEAD_OF_PLAYER` event is budgeted here and sited by `EventDirector` while the player
	# walks. Costing it here rather than giving the director its own allowance is deliberate:
	# the cat competes with the café tables and the roadworks for the same day, so making the
	# cat matter cannot quietly make the day denser as well.
	if def.spawn_mode == EventDef.SpawnMode.AHEAD_OF_PLAYER:
		return Planned.new(def, Vector2.INF)

	var candidates: Array[Vector2i] = []
	for type in def.placement:
		candidates.append_array(map.tiles_of_type(type as GameEnums.TileType))
	if candidates.is_empty():
		return null

	# A closed street is not somewhere anyone can get to, so it is not somewhere an event
	# can usefully happen: the player would never see it and the scheduler would have spent
	# budget on nothing.
	var open_candidates: Array[Vector2i] = []
	for candidate in candidates:
		if map.is_closed(candidate) or not _wants_this_side(def, map, candidate):
			continue
		open_candidates.append(candidate)
	if open_candidates.is_empty():
		return null

	var best: Planned = null
	var best_room := -INF
	for _try in Tuning.EVENT_PLACEMENT_TRIES:
		var tile: Vector2i = open_candidates[rng.randi_range(0, open_candidates.size() - 1)]
		var candidate := _build_placement(def, map, tile, rng)
		if not candidate:
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

## Whether a tile is the lane of the pavement this event wants. *(M34, playtest 07 findings 7
## and 15.)*
##
## Almost everything says `ANY` and this is a free `true`. The two rows that do not were both
## reported as standing somewhere that made no sense of them, and neither is a balance question:
## a parked van belongs at the kerb rather than in a traffic lane the crowd will drive straight
## through, and a lorry reversing into a yard belongs with its back to a wall.
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
## - **Nothing else happens inside a lethal event's field.** This is playtest 05's first named
##   risk: `Tuning.validate_event()` states the telegraph contract *per event* and the player
##   experiences the sum, so at one event per block "walk out of this radius" can quietly mean
##   "walk into the next one". For fifteen of the eighteen rows that is a cost and it is what
##   the density is *for*; for the three that end the day it is a death arriving out of a field
##   she was already reading. A `hard_fail` event that cannot find room is not placed at all.
## - `EVENT_SPACING_SAME` — a second dog walker a few pixels from the first reads as a
##   duplicated sprite rather than a second incident. This one bends, because on a full map the
##   honest answer is the roomiest spot left rather than no event.
static func _room_around(candidate: Planned, already: Array[Planned]) -> float:
	var room_same := INF
	for plan in already:
		if not plan.is_placed():
			continue
		var gap := _gap_between(candidate, plan)
		if gap < Tuning.EVENT_SPACING_ANY:
			return -INF
		if candidate.def.hard_fail and gap < candidate.def.outer_radius:
			return -INF
		if plan.def.hard_fail and gap < plan.def.outer_radius:
			return -INF
		if plan.def.id == candidate.def.id:
			room_same = minf(room_same, gap)
	return INF if room_same >= Tuning.EVENT_SPACING_SAME else room_same

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
	# Stop short of a closed street rather than driving through the barrier at the end of it —
	# and, since M21, short of a four-block calm zone as well. A corridor that ends in a park is
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

## docs/CITY.md: at least one calm zone stays usable every day, or the day has no safe
## ground and the player has no move. Whichever one is least disturbed keeps its quiet.
##
## Since M14 this is the difference between a hard day and an impossible one, and since M15
## the set of calm zones is whatever the arcs have left — a requisitioned park is not a
## candidate, because it is not calm any more.
##
## Ambient events do not count as spoiling. A playground is a permanent feature of the map,
## not something that went wrong today — it makes a park *contested*, which is the point,
## and it leaves the far side of the block calm. Counting it here would mean stripping a
## playground out of one park every single day.
## Since M24 it also takes the block she settled in yesterday, and protects a **different** one
## where it can. Without that the two halves fight: the day deliberately puts something in her
## park, and then this rule, looking for the least disturbed calm ground, finds the block with
## exactly one spoiler on it and strips the very event that was the point.
static func _ensure_one_usable_park(map: CityMap, planned: Array[Planned],
		settled_yesterday := Vector2i(-1, -1)) -> void:
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
			# **A scar is not today's noise.** *(M36.)* It is exempt for exactly the reason the
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

	# Yesterday's park is the last one considered, not an excluded one: if it is the only calm
	# block left standing, a winnable day still outranks a fresh decision.
	var choosable: Array[Vector2i] = []
	for block in map.calm_blocks:
		if block != settled_yesterday:
			choosable.append(block)
	if choosable.is_empty():
		choosable = map.calm_blocks

	var least: Vector2i = choosable[0]
	for block in choosable:
		if spoilers[block].size() < spoilers[least].size():
			least = block
	for plan in spoilers[least]:
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

	var reachable := map.walk_distances(map.home_rect.position, blocked)
	if reachable.is_empty():
		return false
	for tile in map.calm_tiles():
		if reachable.has(tile):
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
