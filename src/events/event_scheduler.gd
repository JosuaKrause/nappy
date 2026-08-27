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

	planned.append_array(_place_ambient(day, map))
	planned.append_array(_place_scars(day, scars))
	_place_scripted(day, rng, map, planned)
	_place_one_shots(day, rng, map, consumed_one_shots, planned)
	_spoil_the_park_she_used(day, rng, map, planned, settled_yesterday)
	_fill_with_recurring(day, rng, map, planned)

	_ensure_one_usable_park(map, planned, settled_yesterday)
	_ensure_the_city_is_still_walkable(map, planned)
	return planned

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
## - **It spoils with an event, not by taking the ground away.** The park is still there, still
##   calm ground, still walkable. Something loud is standing in it, and she can see that from
##   the street and decide. An event that could seal or end the day is never chosen for this.
## - **`_ensure_one_usable_park` is told to protect a different one**, so the day it creates is
##   still winnable and the alternative is still real rather than nominal.
## - **It is one event, placed like any other.** It competes for no budget of its own and it is
##   drawn from the same day's pool, so day 2 is not "day 1 plus a punishment", it is a day
##   whose noise happens to be somewhere she was counting on.
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
	var candidates: Array[Vector2i] = []
	for tile in map.rect_tiles(lot):
		if not map.is_closed(tile):
			candidates.append(tile)
	if candidates.is_empty():
		return

	var def := _something_to_put_in_a_park(day, rng)
	if not def:
		return
	var at := map.tile_to_world(candidates[rng.randi_range(0, candidates.size() - 1)])
	planned.append(Planned.new(def, at))
	Telemetry.note("roll", "%s in the park she used yesterday, %s"
			% [def.id, TelemetryLog.tile(block)])

## Something loud, harmless and visible from the street, for the park she used yesterday.
##
## Deliberately narrow: nothing lethal, nothing that obstructs, nothing mobile. A spoiled park
## has to be a park she can *see* is spoiled and walk away from — an abduction sitting in it
## would be a punishment for having settled there, and a barricade would be the ground taken
## away rather than made noisy, which is the thing this rule promises not to do.
static func _something_to_put_in_a_park(day: int,
		rng: RandomNumberGenerator) -> EventDef:
	var suitable: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day):
		if def.hard_fail or def.obstructs_radius > 0.0 or def.mobile:
			continue
		if def.spawn_mode != EventDef.SpawnMode.MAP:
			continue
		suitable.append(def)
	if suitable.is_empty():
		return null
	return _pick_weighted(suitable, rng)

## Permanent marks left by earlier days, placed again exactly where they happened.
static func _place_scars(day: int, scars: Array[Dictionary]) -> Array[Planned]:
	var planned: Array[Planned] = []
	for scar in scars:
		if int(scar["since_day"]) >= day:
			continue
		var def := EventCatalogue.by_id(String(scar["id"]))
		if def:
			planned.append(Planned.new(def, scar["position"]))
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

static func _fill_with_recurring(day: int, rng: RandomNumberGenerator, map: CityMap,
		planned: Array[Planned]) -> void:
	var eligible := EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day)
	if eligible.is_empty():
		return

	var budget := budget_for(day)
	var counts := {}
	# Bounded rather than while-true: a catalogue where nothing affordable remains would
	# otherwise spin forever.
	for _attempt in budget * 4:
		if budget <= 0:
			break
		var affordable: Array[EventDef] = []
		for def in eligible:
			if def.cost <= budget and int(counts.get(def.id, 0)) < def.max_per_day:
				affordable.append(def)
		if affordable.is_empty():
			break
		var def := _pick_weighted(affordable, rng)
		var placement := _place_one(def, rng, map, planned)
		if not placement:
			continue
		planned.append(placement)
		counts[def.id] = int(counts.get(def.id, 0)) + 1
		budget -= def.cost

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
		if not map.is_closed(candidate):
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

## One candidate placement on a given tile, with its route built if it moves.
static func _build_placement(def: EventDef, map: CityMap, tile: Vector2i,
		rng: RandomNumberGenerator) -> Planned:
	var at := map.tile_to_world(tile)
	if not def.mobile:
		return Planned.new(def, at)
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
	# Stop short of a closed street rather than driving through the barrier at the end of it.
	for step in range(1, length + 1):
		if map.is_closed(tile + along * step):
			length = step - 1
			break
	if length <= 0:
		return PackedVector2Array()
	return PackedVector2Array([
		map.tile_to_world(tile), map.tile_to_world(tile + along * length)])

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
