class_name RouteRigPlanner
extends RefCounted
## **Where a `--route` target is, and the walk there**: the half of `RouteRig` (`src/dev/route_rig.gd`)
## that reads the city rather than steering her — what each target word names now (`resolve()`), the
## cheapest walk to it (`plan()`), its waypoints in world space (`to_world()`), and the ground the
## walk keeps off (`body_clear_tiles()`, `door_tiles()`, `is_hazardous()`) or goes round once
## something caught her (`ground_round_body()`, `ground_round_point()`). The rig builds one in its
## `setup()` and asks it at every leg, re-plan and stall; a test builds one with the same constructor
## over a city of its own and asks it what the rig asks.
##
## A `RefCounted`, not a `Node`: it presses nothing and ticks nothing. What it remembers is a day's
## worth of answers that do not change within the day (the planned bodies' clearance, the boom's
## ground, the walkable grid), the door bodies that have just let her out, the live instance an
## any-instance task is walking to, and which tiles of the clearance the last plan chose to cross;
## `start_day()` forgets them for the day just built.
##
## **Hugs the kerb by pricing the carriageway, not by hand-drawn geometry.** `plan()` asks for the
## cheapest walk with every live hazard's own kill reach removed (`_hazard_tiles()`), keeping off a
## guard's own reach the way a player backs off once the meter spikes, and with a plain `ROAD` tile
## costing `_ROAD_STEP_COST` tiles more than a step of sidewalk — so a route keeps to the pavement,
## crosses at a `CROSSING` (a zebra) a few tiles along rather than straight over, and takes the
## carriageway only where the pavement is a long way round or no way at all (the day 13
## roadblock's own band is `ROAD`/`CROSSING` ground, so its own last step always does; see
## `_HAZARD_MARGIN`'s own doc for why a guarded mark's own contact point never needs this). A
## hazard the plan cannot get around at all — an unlikely last resort, not the ordinary case — is
## walked through with hazards ignored entirely, rather than the target being reported unreachable
## for a margin that merely made it look that way. `_simplify()` then collapses a straight run
## along one row or column into its two ends, dropping the redundant waypoints in between — see
## `_line_of_sight()`'s own doc for why a true diagonal cut is refused outright rather than
## sampled: it can cross a 2x2 corner the raw 4-connected walk never actually crossed.
##
## **Every plan folds in what moves while the day is live.** `_blocked_for_phase()` folds
## `CityMap.obstructed_tiles` into every plan: a plan that never looked at it would recompute the
## identical route onto the same obstruction, and the rig's re-plan check (`RouteRig._maybe_replan()`)
## would catch the same thing again next check, forever.
##
## **Keeps clear of a solid body by the body's own outline, not by the tile it stands on.**
## `CityMap.obstructed_tiles` records a tile only where a body covers the tile's centre — right for
## the crowd, which walks a lane's centre line, and not enough for her: a kerbed `delivery_van`
## (22px) covers only its own kerb tile, yet leaves the frontage tile beside it a 26px gap to the
## wall for her 28px body, so a plan that read only the record walked her flush into the van.
## `body_clear_tiles()` adds every tile whose centre lies within `Tuning.PLAYER_BODY_RADIUS` of a
## stationary body's own surface, measured against the body's real shape, and every plan crosses
## those only where going round is dearer (see `plan()` for the price of each). **Every body and
## every door the day has sited counts, not only the ones streamed in near her** — see
## `body_clear_tiles()` and `door_tiles()`.

## World-space arrival radius for a waypoint — comfortably inside `ContactPoint.REACH` (36px), so a
## mark or a task's own contact always completes on the way in, and small enough (under a third of
## `Tuning.TILE_SIZE`, 32px) that switching to the next waypoint never visibly overshoots the line
## `_simplify()` drew. The rig arrives at a waypoint by it (`RouteRig._follow()`), and a door's reach
## here is widened by it for the corner she cuts at one.
const ARRIVE_RADIUS := 10.0

const _STEPS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

## World px sampled along a candidate straight-line cut in `_line_of_sight()` — a quarter of
## `Tuning.TILE_SIZE`, fine enough that a cut cannot skip clean over a one-tile obstruction.
const _LINE_OF_SIGHT_STEP := 8.0

var _city: City
var _player: Stroller
var _resistance: ResistanceDirector
var _day: DayController
## The run whose header `spawn:<name>` hands `DevRig.for_spawn_target()`.
var _run: RunState

## Every `ROAD` tile in the map, built once — the lattice itself never changes within a run, only
## which blocks are calm and which streets are closed today, neither of which moves a `ROAD` tile.
## Kept out of `_blocked_for_phase()`'s own per-call cost, which only has `closed_tiles` (small,
## and genuinely different every day) left to copy.
var _road_tiles: Dictionary = {}

## The rig's planner over `city`, for her (`player`), today's resistance (`resistance`, null in the
## escape, which has no subquest), the day's clock (`day`, whose spec names the escape city's exits)
## and the run (`run`).
func _init(city: City, player: Stroller, resistance: ResistanceDirector, day: DayController,
		run: RunState) -> void:
	_city = city
	_player = player
	_resistance = resistance
	_day = day
	_run = run
	for y in _city.map.size.y:
		for x in _city.map.size.x:
			var tile := Vector2i(x, y)
			if _city.map.tile_at(tile) == GameEnums.TileType.ROAD:
				_road_tiles[tile] = true

## Forgets every answer worked out for the day before, for the day just built — the rig asks it
## from its own `start_day()`.
func start_day() -> void:
	_task_instance = null
	_planned_clear = {}
	_latched_doors = {}
	_plan_accepted = {}
	_walkable = PackedByteArray()
	_steps = PackedInt32Array()
	_gate_ground_ready = false

# --------------------------------------------------------------- resolving ---

## Where `word` names, or `Vector2.INF` when it names nothing right now — see `RouteRig`'s class
## doc for the list of targets, what each one means and why it can be unresolved.
func resolve(word: String) -> Vector2:
	match word:
		"mark":
			if not _resistance:
				return Vector2.INF
			var step := _resistance.current_step()
			return _resistance.contact_position() if step != null and step.is_pickup else Vector2.INF
		"task":
			return _task_target()
		"calm":
			return _nearest_calm()
		"calm:home":
			return _nearest_calm(true)
		"home":
			return _city.map.home_world_position()
		"tunnel":
			return _day.spec.exits.get(CityEdge.Kind.TUNNEL, Vector2.INF)
		"bridge":
			return _day.spec.exits.get(CityEdge.Kind.BRIDGE, Vector2.INF)
		_:
			if word.begins_with("spawn:"):
				return DevRig.for_spawn_target(word.get_slice(":", 1), _city, _resistance,
						_run.header)
			push_warning("--route: unknown target '%s'" % word)
			return Vector2.INF

## `task`'s own resolution: the step the mark just unlocked, which is null until the mark is
## actually touched (see `ResistanceDirector._on_contact_completed()`) — so this answers `INF`
## for exactly as long as `mark` itself would have, on a day with a task still to walk to. **A
## contact on a wall or on a body is walked to from the open ground nearest it**
## (`_reachable_point_near()`): every contact stands on its item, so day 8's and the last night's
## stand on a door on a facade, a building tile no plan can end on, which `DOOR_REACH` (about
## 50.6px) completes from the tile straight below (32px); the van's and a mast's stand on their own
## body's tile, which a plan cannot end on either and which their body reach completes from beside.
func _task_target() -> Vector2:
	if not _resistance:
		return Vector2.INF
	var step := _resistance.current_step()
	if step == null or step.is_pickup:
		return Vector2.INF
	if step.is_one_place:
		var at := _resistance.contact_position()
		var tile := _city.map.world_to_tile(at) if at != Vector2.INF else Vector2i.ZERO
		if at != Vector2.INF and (not _city.map.is_walkable(tile) or _city.map.is_obstructed(tile)):
			return _reachable_point_near(at)
		return at
	return _nearest_live_instance(step.task_event_id)

## The live instance an any-instance `task` is walking to, kept for as long as it lasts — see
## `_nearest_live_instance()`. Cleared in `start_day()`.
var _task_instance: EventInstance = null

## The nearest live instance of `event_id` when the task is first resolved, and **that same one
## after**, for as long as it is live and unfinished. Asking afresh at every check handed a leg
## walking between two roadblocks the nearer of the two each time she drew level with the middle,
## so the target swapped back and forth for the rest of the day. An instance that has finished or
## streamed out (freed) is let go, and the nearest live one answers again.
func _nearest_live_instance(event_id: String) -> Vector2:
	if _task_instance != null and (not is_instance_valid(_task_instance)
			or _task_instance.is_finished or _task_instance.def.id != event_id):
		_task_instance = null
	if _task_instance == null:
		var best_distance := INF
		for instance: EventInstance in _city.events.instances():
			if instance.def.id != event_id or instance.is_finished:
				continue
			var distance := _player.global_position.distance_squared_to(instance.global_position)
			if distance < best_distance:
				best_distance = distance
				_task_instance = instance
	if _task_instance == null:
		return Vector2.INF
	return _reachable_point_near(_task_instance.global_position)

## How far outward `_reachable_point_near()` searches, in tiles, before giving up and handing back
## `centre` unchanged — past `roadblock`'s own solid reach (`obstructs_radius` 60px, under two
## tiles) with room to spare, so a body this catalogue actually places is always found well inside
## the budget and only a malformed future row would ever exhaust it.
const _NEAREST_OPEN_SEARCH_RADIUS := 6

## The walkable, unobstructed ground nearest `centre`, or `centre` itself when it already qualifies
## — every any-instance task but `roadblock` has no body at all (`homeless_yeller`'s own
## `obstructs_radius` is 0), so this is a no-op for them and changes nothing about how they resolve.
##
## **A solid row's own centre is exactly the ground `plan()` refuses.** `roadblock` carries
## `def.solid(GroundShape.band(60.0))`, so `EventManager` rasterises its footprint into
## `CityMap.obstructed_tiles` the same way any parked body is (`_blocked_for_phase()`'s own doc),
## and unlike a hazard's own margin — which `_cheapest()` explicitly drops for the tile a leg is
## walking to — an obstructed tile is never exempted for either end of a plan, because a body is
## really standing there. Handing the rig a target sitting inside one is a target no path can ever
## end on, which is the day 13 "no path to 'task'" this function exists to fix (a `--route`
## measurement found a live `roadblock` instance whose centre was its own solid band).
##
## **Walking to the nearest open ground next to the body reaches the row exactly as reliably as
## the real game's own random-bearing offset does, without reproducing its RNG draw.**
## `ResistanceDirector.touch_reach()` completes an any-instance task from `obstructs_radius +
## Tuning.PLAYER_BODY_RADIUS + ContactPoint.REACH` of the instance's centre (110px for `roadblock`,
## 60 + 14 + 36) — comfortably past where the solid edge itself sits (60px) — so standing on the
## closest ground the body actually leaves open is always well inside that reach, whichever side
## of it she approaches from.
##
## **Clear of the body's own outline too, not only off its recorded tiles**, since a tile beside a
## body can be one she cannot stand in the middle of (`body_clear_tiles()`): a leg aimed there
## would press her against the body for its last few pixels. Where the clearance leaves nothing
## inside `_NEAREST_OPEN_SEARCH_RADIUS`, the nearest open, unrecorded tile answers instead.
func _reachable_point_near(centre: Vector2) -> Vector2:
	var centre_tile := _city.map.world_to_tile(centre)
	var clear := body_clear_tiles()
	if _stands_open(centre_tile, clear):
		return centre
	for keep_clear: Dictionary in [clear, {}]:
		for radius in range(1, _NEAREST_OPEN_SEARCH_RADIUS + 1):
			for offset in _ring_nearest_first(radius):
				var tile := centre_tile + offset
				if _stands_open(tile, keep_clear):
					return _city.map.tile_to_world(tile)
	return centre

## The tiles of the square ring `radius` out from a tile, as offsets, **nearest first**: the four
## straight across before anything diagonal. Scanned row by row instead, the ring's first open tile
## below a door was its diagonal (45px from the door's point) rather than the tile straight below it
## (32px), and arriving within `ARRIVE_RADIUS` of that could leave her past day 8's `DOOR_REACH`
## (50.6px), so the leg ended without the touch. Ties keep the row-by-row order, so the search is the
## same every time.
static func _ring_nearest_first(radius: int) -> Array[Vector2i]:
	var ring: Array[Vector2i] = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if maxi(absi(dx), absi(dy)) == radius:
				ring.append(Vector2i(dx, dy))
	var nearest_first: Array[Vector2i] = []
	var lengths: Array[int] = []
	for offset in ring:
		var length := offset.length_squared()
		var at := nearest_first.size()
		for i in nearest_first.size():
			if lengths[i] > length:
				at = i
				break
		nearest_first.insert(at, offset)
		lengths.insert(at, length)
	return nearest_first

func _stands_open(tile: Vector2i, keep_clear: Dictionary) -> bool:
	return _city.map.is_open(tile) and not _city.map.is_obstructed(tile) and not keep_clear.has(tile)

## The nearest calm tile by walking distance, sidewalks, hazard-free ground and ground clear of
## every body preferred exactly as `plan()` prefers them — see `_blocked_for_phase()` and
## `body_clear_tiles()`, the second of which also keeps the calm tile itself off ground beside a
## body. The pool is `_calm_tiles_left()`, read live, so ground the day has spoiled or is taking
## (day 12's park, once the swing is reached) is never offered. Her own tile is never blocked, for
## the reason `_cheapest()` gives: a sweep seeded on blocked ground reaches nothing at all.
##
## **`toward_home`, the `calm:home` target word** — docs/TODO.md, M181, "the late days are timed",
## item 3: day 9 on seed 90210 does not fit its clock (`tests/probes/m184_route_timing.gd`), and one
## of the two readings the queue names is that the plain nearest-to-her calm area can sit off the
## way home rather than on it. With this set, the pool is scored by her walk to the tile *plus* the
## tile's own walk home (`_nearest_in_field_toward_home()`), so the leg still settles the baby
## without adding a detour the walk home would otherwise have to undo. **The default stays plain
## `calm`** — nearest to her — since nothing in the calendar but this one day and seed needed the
## other reading; `calm:home` is here for a caller (a probe, a future measurement) that wants it.
func _nearest_calm(toward_home: bool = false) -> Vector2:
	var here := _city.map.world_to_tile(_player.global_position)
	var home := _city.map.world_to_tile(_city.map.home_world_position())
	var hazards := _hazard_tiles()
	var guarded := hazards.duplicate()
	guarded.merge(body_clear_tiles())
	var phases: Array[Dictionary] = [_blocked_for_phase(true, {}, guarded),
			_blocked_for_phase(false, {}, guarded), _blocked_for_phase(false, {}, hazards),
			_blocked_for_phase(false)]
	for blocked in phases:
		blocked.erase(here)
		var field := _city.map.walk_field(here, blocked)
		var best: Vector2i
		if toward_home:
			var home_blocked: Dictionary = blocked.duplicate()
			home_blocked.erase(home)
			best = _nearest_in_field_toward_home(field, _city.map.walk_field(home, home_blocked))
		else:
			best = _nearest_in_field(field)
		if best != Vector2i(-1, -1):
			return _city.map.tile_to_world(best)
	return Vector2.INF

## `CityMap.calm_tiles()` less the ground of any lot the day has stopped counting as calm, which is
## the ground of a lot being taken while she watches. Day 12's park, once she has reached its swing,
## leaves `CityMap.calm_blocks` that instant (`Happenings.take_the_park()`), but its grass stays
## grass while the police cordon it off (`ParkCordon`), so its tiles still read calm one by one: a
## calm area chosen from the tiles alone is the swing's own park, which is taped shut round her
## seconds later (`ParkCordon.deadline`), and being shut in ends the day. So the calm leg goes to
## the day's second calm area, which the day keeps reachable for exactly this. On every other day
## no lot's calm ground outlives its purpose, so this is the tiles unchanged.
func _calm_tiles_left() -> Array[Vector2i]:
	var map := _city.map
	var calm := {}
	for block: Vector2i in map.calm_blocks:
		calm[block] = true
	var going := {}
	for block: Vector2i in map.block_plans:
		if calm.has(block):
			continue
		for tile in map.rect_tiles(map.lot_rect(block)):
			if Tile.is_calm(map.tile_at(tile)):
				going[tile] = true
	var left: Array[Vector2i] = []
	for tile in map.calm_tiles():
		if not going.has(tile):
			left.append(tile)
	return left

func _nearest_in_field(field: PackedInt32Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := -1
	for tile in _calm_tiles_left():
		var distance := _city.map.distance_at(field, tile)
		if distance < 0:
			continue
		if best_distance == -1 or distance < best_distance:
			best_distance = distance
			best = tile
	return best

## `_nearest_in_field()`'s own pool, scored by her own walk to the tile plus that tile's walk home
## (`home_field`, `CityMap.walk_field()` from the doorstep over the same blocked ground) rather than
## by her own walk alone — see `_nearest_calm()`'s doc on `toward_home`. A tile either field cannot
## reach is skipped, the same as a negative `distance_at()` already means for the plain reading.
func _nearest_in_field_toward_home(field: PackedInt32Array, home_field: PackedInt32Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_total := -1
	for tile in _calm_tiles_left():
		var distance := _city.map.distance_at(field, tile)
		if distance < 0:
			continue
		var home_distance := _city.map.distance_at(home_field, tile)
		if home_distance < 0:
			continue
		var total := distance + home_distance
		if best_total == -1 or total < best_total:
			best_total = total
			best = tile
	return best

# ----------------------------------------------------------------- planning ---

## Today's `closed_tiles`, `CityMap.obstructed_tiles`, today's soft-sealed pavement
## (`CityMap.soft_sealed_tiles`), the ground a street door's boom would take her on
## (`_gate_ground()`), the ground under a door body that has just let her out
## (`_latched_door_bodies()`) and the ground round a precinct's posts (`_post_tiles()`), which block
## a plan whatever else it asks, plus `_road_tiles` while `sidewalk_only`; `hazards` (see
## `_hazard_tiles()`) and `avoid` (ground the tile grid calls open but she cannot stand in the
## middle of or should keep off, see `plan()`) are added on top of all of that. Built fresh every
## call since `closed_tiles`, every live obstruction's own footprint and every live hazard's own
## position genuinely change day to day and frame to frame, and a stale copy would let a plan walk
## through today's own barrier, a body parked since the last check, or yesterday's guard.
## `CityMap.obstructed_tiles` (`src/city/ city_map.gd`) is what the rig's re-plan check reads —
## folding it in here too is what makes a replan actually route around the thing it just detected,
## rather than recomputing the identical path onto the same obstruction and re-detecting it
## forever; a plan that never looked at `obstructed_tiles` at all was the shape of that bug.
## `hazards` is taken as a dictionary rather than computed here so a caller can drop the one tile
## it is actually trying to reach from it first — see `_cheapest()`.
##
## **A soft seal (`skip`/`scaffolding`, `moving_van`) shuts its pavement to a walker in every plan,
## not only while `sidewalk_only`.** `WalkerStrategy.cannot_go_on()` refuses
## `CityMap.is_soft_sealed(tile)` — "a soft seal takes both pavements and leaves
## the carriageway to the cars" — and the ground either side of a soft seal's own body reads as
## open, unobstructed ground (the seal shuts the whole *pavement*, not only the body's own
## footprint), so a plan that did not ask would aim her down a lane the day has closed to her
## rather than crossing to the carriageway where the seal means her to go.
func _blocked_for_phase(sidewalk_only: bool, avoid: Dictionary = {},
		hazards: Dictionary = {}) -> Dictionary:
	var blocked := {}
	if sidewalk_only:
		for tile: Vector2i in _road_tiles:
			blocked[tile] = true
	for tile: Vector2i in _city.map.closed_tiles:
		blocked[tile] = true
	for tile: Vector2i in _city.map.soft_sealed_tiles:
		blocked[tile] = true
	for tile: Vector2i in _city.map.obstructed_tiles:
		blocked[tile] = true
	for tile: Vector2i in _gate_ground():
		blocked[tile] = true
	for tile: Vector2i in _latched_door_bodies():
		blocked[tile] = true
	for tile: Vector2i in _post_tiles():
		blocked[tile] = true
	for tile: Vector2i in hazards:
		blocked[tile] = true
	for tile: Vector2i in avoid:
		blocked[tile] = true
	return blocked

## Margin added past a live hard_fail event's own `lethal_reach()` when deciding what ground to
## keep off — `Tuning.PLAYER_BODY_RADIUS` (14px), the width of the body actually walking the
## boundary `_hazard_tiles()` draws. `_hazard_tiles()` tests each tile's own **nearest point**
## against the reach, not its centre, so this margin does not also have to cover a tile's own
## half-diagonal the way a centre-distance test would — a nearest-point test already sees a tile's
## corner for what it is. A bigger margin here (an earlier build used the half-diagonal-plus-body
## sum, 38px, over a centre-distance test) blocks a wider ring than the true kill radius needs,
## and on a two-tile-wide alley — the guard's own placement, `alley_robbery.placement = [ALLEY]`,
## and *"a robber who never moves is avoidable by walking two tiles wide of him"* — a wide enough
## ring can span the whole width and leave no tile within one hop of wherever she is already
## standing that is not itself still "blocked", which is a plan that can never get out from
## wherever it started rather than one that avoids the guard. See `_hazard_tiles()`'s own doc.
const _HAZARD_MARGIN := Tuning.PLAYER_BODY_RADIUS

## Whether `instance` is a hard_fail row worth planning a route around at all — live, and
## `not def.mobile`. A stationary kill (the guard `alley_robbery` places over every mark, an
## idling `abduction` van, `reversing_lorry`, `car_accident`) is exactly the shape a route can
## detour once and stay clear of for the whole leg, the same as a parked obstruction. A `mobile`
## one (`cyclist`, `masked_pursuer`) is somewhere else by the time a replan's own path would get
## there — blocking around its instantaneous position chases a moving point with a stale detour,
## which is what turned day 6 seed 4242's 'task' leg (homeless_yeller's own pacing crossing a
## cyclist's route) into a replan every `RouteRig._REPLAN_INTERVAL` for the rest of the run rather
## than a leg that ever finished. A moving hard_fail hazard is exactly what the excitement meter and
## the screen-edge badge already warn a player to react to as it closes, not something a route is
## planned around from a distance; the rig has no reactive dodge, so it leaves a mobile hazard to
## its ordinary stuck/obstruction handling instead of a dedicated avoidance.
func _is_stationary_hazard(instance: EventInstance) -> bool:
	return not instance.is_finished and instance.def.hard_fail and not instance.def.mobile

## Whether `point` sits within a live stationary hard_fail event's own kill reach plus
## `_HAZARD_MARGIN` — every mark is guarded (`docs/DECISIONS.md`, "every mark is guarded"), and the
## guard carries no body for `is_obstructed()` to see, only a radius that ends the day. A player
## backs off the instant the excitement meter spikes; this is what the same caution reads as for a
## rig with no meter to watch. The rig asks it of every waypoint still ahead at each re-plan check.
func is_hazardous(point: Vector2) -> bool:
	for instance: EventInstance in _city.events.instances():
		if not _is_stationary_hazard(instance):
			continue
		if point.distance_to(instance.global_position) <= instance.def.lethal_reach() + _HAZARD_MARGIN:
			return true
	return false

## Every tile within a live stationary hard_fail event's own kill reach plus `_HAZARD_MARGIN`,
## tested against each candidate tile's own **nearest point** to the hazard rather than its
## centre — see `_HAZARD_MARGIN`'s own doc for why a centre-distance test blocks a wider ring than
## the true kill radius needs. Cheap: a handful of hard_fail instances are ever live at once, each
## with a two-or-three-tile reach.
func _hazard_tiles() -> Dictionary:
	var blocked := {}
	for instance: EventInstance in _city.events.instances():
		if not _is_stationary_hazard(instance):
			continue
		var reach := instance.def.lethal_reach() + _HAZARD_MARGIN
		var centre := _city.map.world_to_tile(instance.global_position)
		var radius_tiles := ceili(reach / Tuning.TILE_SIZE) + 1
		for dy in range(-radius_tiles, radius_tiles + 1):
			for dx in range(-radius_tiles, radius_tiles + 1):
				var tile := centre + Vector2i(dx, dy)
				if _tile_nearest_distance(tile, instance.global_position) <= reach:
					blocked[tile] = true
	return blocked

## The shortest distance from `point` to any point inside `tile`'s own square — `0.0` when `point`
## is over the tile at all, otherwise the distance to whichever edge or corner is nearest. The test
## `_hazard_tiles()` needs: not whether the tile's *centre* is far enough from a hazard, but
## whether *any ground on the tile* is close enough to end the day.
func _tile_nearest_distance(tile: Vector2i, point: Vector2) -> float:
	var centre := _city.map.tile_to_world(tile)
	var half := Tuning.TILE_SIZE / 2.0
	var dx := maxf(absf(point.x - centre.x) - half, 0.0)
	var dy := maxf(absf(point.y - centre.y) - half, 0.0)
	return Vector2(dx, dy).length()

## How near a tile's centre may come to a solid body's own surface and still be planned through —
## her own `Tuning.PLAYER_BODY_RADIUS` (14px). A plan walks her down tile centres, so a centre
## nearer a body than her radius is a step she can only take by pressing into it: the frontage tile
## beside a kerbed `delivery_van` is 10px from the van's side, and so is the first lane of road
## beside it. Her pram (`Stroller.PRAM_BODY_RADIUS`, 8px, on her circumference ahead of her) adds
## nothing sideways, and ahead of her `ARRIVE_RADIUS` (10px) already turns her toward the next
## waypoint before it could touch.
const _BODY_CLEARANCE := Tuning.PLAYER_BODY_RADIUS

## How far round the body that caught her a leg keeps off afterwards, measured the same way — her
## radius plus half a tile (30px). Wider than `_BODY_CLEARANCE` because a stall proves the ordinary
## clearance was not enough here, and narrow enough to leave a street's second lane open past a
## kerbed van: that lane's centre is 42px from the van's side.
const _CAUGHT_CLEARANCE := Tuning.PLAYER_BODY_RADIUS + Tuning.TILE_SIZE * 0.5

## Every tile whose centre lies within `_BODY_CLEARANCE` of a standing body's own surface — see that
## constant for why `CityMap.obstructed_tiles` alone is not enough for her. The rig asks it at each
## re-plan check, for a body now lying over a waypoint still ahead.
##
## **Every body the day has, not only the ones streamed in near her.** `EventManager` builds an
## instance only once she is within `EventManager.stream_radius` of its plan and takes it away
## again once she leaves, but it records every planned body in `obstructed_tiles` at dawn, because
## "a body is a body whether or not the player has come near enough to stream it in". A plan that
## knew only the live ones kept meeting a van streaming in over a waypoint a few tiles ahead, and
## re-planned onto a street whose own van streamed in next. So each placed, unspent plan answers
## from where its instance will stand (`_planned_body_tiles()`), and a live instance from where it
## does stand, which also covers a body the director sites from her walk and has no plan position
## at dawn.
func body_clear_tiles() -> Dictionary:
	var near := {}
	for plan: EventScheduler.Planned in _city.events.plans():
		if plan.live == null and plan.is_placed() and not plan.spent and _is_planned_body(plan.def):
			near.merge(_planned_body_tiles(plan))
	for instance: EventInstance in _city.events.instances():
		if _is_standing_body(instance):
			near.merge(_tiles_near_body(instance, _BODY_CLEARANCE))
	return near

## `body_clear_tiles()`'s answer for one plan, worked out once a day — a planned body never moves.
## Cleared in `start_day()`.
var _planned_clear := {}

func _planned_body_tiles(plan: EventScheduler.Planned) -> Dictionary:
	if _planned_clear.has(plan):
		return _planned_clear[plan]
	var parts := _planned_parts(plan)
	var tiles := _tiles_near_pieces(parts[0], parts[1], parts[2], _BODY_CLEARANCE)
	_planned_clear[plan] = tiles
	return tiles

## A placed plan's solid pieces as its instance will stand — `[centres, shapes, axis]`, the
## `EventInstance.solid_part_centres()`, `solid_part_shapes()` and `solid_axis()` it will have.
func _planned_parts(plan: EventScheduler.Planned) -> Array:
	var at := _planned_position(plan)
	var vertical := EventInstance._spread_is_vertical(_city.map, at)
	var centres := PackedVector2Array()
	var shapes: Array[GroundShape] = []
	for piece in plan.def.parts():
		var offset := piece.offset_for(vertical)
		centres.append(at + (Vector2(0.0, offset) if vertical else Vector2(offset, 0.0)))
		shapes.append(piece.shape)
	return [centres, shapes, EventFootprints.body_axis(_city.map, plan.def, at, plan.facing)]

## Where a plan's instance will stand once it is built — `EventInstance.setup()`'s own reading: the
## first point of its path or its position, moved to the middle of the sidewalk band for a
## stationary solid row that `pavement_side` does not pin to an edge.
func _planned_position(plan: EventScheduler.Planned) -> Vector2:
	var at := plan.path[0] if plan.path.size() > 0 else plan.position
	if not plan.def.mobile and plan.def.obstructs_radius > 0.0 \
			and plan.def.pavement_side == EventDef.Pavement.ANY:
		at = EventInstance._centred_on_the_pavement_band(_city.map, at)
	return at

## The planned rows `CityMap.obstructed_tiles` records a body for
## (`EventSpawner.obstructed_footprint()`): solid, and neither `mobile` — somewhere else by the time
## a plan gets there, the reason `_is_stationary_hazard()` gives — nor a door body, which is a
## crossing the day keeps open: a hut or a post (`detain_seconds`) or the boom
## (`EventDef.SolidWhen.WHILE_LOWERED`), whose ground `_gate_ground()` keeps off instead.
func _is_planned_body(def: EventDef) -> bool:
	return def.shape != null and def.obstructs_radius > 0.0 and not def.mobile \
			and def.detain_seconds <= 0.0 and def.solid_when != EventDef.SolidWhen.WHILE_LOWERED

## Every tile whose centre lies within a door's reach — `EventDef.detain_distance()` from a
## `checkpoint_hut` or `checkpoint_post` (the `redetains` rows, the two that inspect her), plus
## `ARRIVE_RADIUS` for the corner she cuts at a waypoint — except the tiles on any door body's own
## crossing line, the row or column through it along its facing, which is the axis the door sets her
## down across. Every door of the day, for the streaming reason `body_clear_tiles()` gives: a door
## is planned at dawn with the region wall it stands in. The rig asks it at each re-plan check, for
## a door's reach now lying over a waypoint still ahead.
##
## **A door takes her in whether or not she meant to cross it**, and sets her down on its far side:
## a plan down the next column of tiles past a door, crossing the street two tiles from it, was
## taken in by one hut and set down on the wrong side of the wall, crossed back through the door,
## and taken in again by the hut on the far sidewalk, until the leg gave up. **And the crossing
## line stays open** because a door is the only way through its wall: keeping out of the whole
## reach sent a plan across the city to a door it had not seen yet, where it met that door's reach
## and set off for the next one. Doors can stand close together — two meeting at a corner — so one
## body's crossing line can lie inside another body's reach: the lines are taken out of every door
## body's reach, not only out of their own body's.
##
## **Two exceptions, both about where she already stands.** A door body that has just let her out
## cannot take her again until she has walked out of its circle (`_latched_doors`), so its reach is
## hers to walk away through. And standing in the `ARRIVE_RADIUS` margin of a door she is not
## inside — a park beside a door — keeps only the true reach off for that door, since every step
## out of the margin would otherwise read as blocked and the plan would give up the doors' reach
## altogether. `chatting_mother` detains too but walks, so she is left to the hold handling, the
## way `_is_stationary_hazard()` leaves a mobile hazard. **A street door's boom (`checkpoint_gate`)
## is not a door body here**: it inspects nobody, so it has no reach and opens no line, and the
## ground under it is never planned at all (`_gate_ground()`).
func door_tiles() -> Dictionary:
	var here := _player.global_position
	var near := {}
	var lines := {}
	for plan: EventScheduler.Planned in _city.events.plans():
		if not plan.is_placed() or plan.spent or not plan.def.redetains:
			continue
		var door := _planned_position(plan)
		var facing := plan.facing
		if plan.live != null:
			if plan.live.is_finished:
				continue
			door = plan.live.global_position
			facing = plan.live.facing_now()
		var trigger := plan.def.detain_distance()
		var distance := here.distance_to(door)
		if _latched_doors.has(plan):
			if distance <= trigger:
				continue
			_latched_doors.erase(plan)
		var reach := trigger if distance <= trigger + ARRIVE_RADIUS else trigger + ARRIVE_RADIUS
		_add_door_reach(door, facing, reach, near, lines)
	for tile: Vector2i in lines:
		near.erase(tile)
	return near

## The door bodies that have just let her out and cannot take her again until she walks out of
## their circle — the rig's copy of
## `CheckpointController._latch_everything_she_was_let_out_into()`, which latches **every** door
## body whose trigger holds the point she is set down at. Filled by
## `latch_the_doors_round_her()`, keyed by plan; a body is let go by `door_tiles()` the first
## time it finds her outside its circle, which is when the game's own latch lets go too.
var _latched_doors := {}

## Notes which door bodies are latched round where she stands now — the rig asks it as a door lets
## her go (`RouteRig._held_at_a_door()`), before it plans from the far side, so the plan walks her
## away through their reach rather than giving up every door's reach because every step out of this
## one read as blocked.
func latch_the_doors_round_her() -> void:
	_latched_doors = {}
	var here := _player.global_position
	for plan: EventScheduler.Planned in _city.events.plans():
		if not plan.is_placed() or plan.spent or not plan.def.redetains:
			continue
		var door := plan.live.global_position if plan.live != null else _planned_position(plan)
		if here.distance_to(door) <= plan.def.detain_distance():
			_latched_doors[plan] = true

## The ground under every door body that has just let her out (`_latched_doors`): the tiles whose
## centre lies within the body's `solid_reach()` plus `Tuning.PLAYER_BODY_RADIUS` of it. Blocked in
## every plan (`_blocked_for_phase()`), because **a latched door does not take her in, and its
## crossing line runs through its body**: a plan back across the door she has just come out of
## walks her down the line into the hut, where she stands pressed against it — the latch holds
## until she has walked out of its circle, which pressing against it never does. So a plan back
## across goes by another of the door's bodies, or out of the circle and back once the latch has
## let go.
func _latched_door_bodies() -> Dictionary:
	var under := {}
	for plan: EventScheduler.Planned in _latched_doors:
		var door := plan.live.global_position if plan.live != null else _planned_position(plan)
		under.merge(_tiles_near_point(door, plan.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS))
	return under

## Every tile under a street door's boom (`checkpoint_gate`, the plan carrying a
## `RegionPlanner.GateState`): within reach of her body touching the boom's — its own
## `solid_reach()` plus `Tuning.PLAYER_BODY_RADIUS`, plus `ARRIVE_RADIUS` for the corner she cuts
## at a waypoint — and nearer the boom than any other door body. Always blocked, in every plan
## (`_blocked_for_phase()`), because **the rig never goes through the boom**, raised or
## lowered *(2026-09-24, the player: "The bot shouldn't route through the boom either way.")*: a
## raised boom is ground she may walk under, and the walk sets a guard on her
## (`CheckpointController.watch_the_door_lines()`), so a door is crossed at a hut or an alley
## post. Stated over the bodies rather than over a trigger, since the boom inspects nobody. A
## hut stands on each sidewalk a lane's width from the road, so both of its crossing lanes are
## nearer the hut than the boom and stay open. Worked out once a day, since doors do not move.
func _gate_ground() -> Dictionary:
	if _gate_ground_ready:
		return _gate_ground_tiles
	_gate_ground_ready = true
	_gate_ground_tiles = {}
	var doors: Array[EventScheduler.Planned] = []
	# Every door body — the huts and posts by `redetains`, the boom by its `GateState` — since the
	# ground kept off is the ground nearer the boom than any of the others.
	for plan: EventScheduler.Planned in _city.events.plans():
		if plan.is_placed() and not plan.spent and (plan.def.redetains or plan.gate_state != null):
			doors.append(plan)
	for gate in doors:
		if gate.gate_state == null:
			continue
		var at := _planned_position(gate)
		var reach := gate.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS + ARRIVE_RADIUS
		var centre_tile := _city.map.world_to_tile(at)
		var span := ceili(reach / Tuning.TILE_SIZE) + 1
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var tile := centre_tile + Vector2i(dx, dy)
				var point := _city.map.tile_to_world(tile)
				var distance := point.distance_to(at)
				if distance > reach:
					continue
				var nearest_is_gate := true
				for other in doors:
					if other != gate and point.distance_to(_planned_position(other)) < distance:
						nearest_is_gate = false
						break
				if nearest_is_gate:
					_gate_ground_tiles[tile] = true
	return _gate_ground_tiles

## `_gate_ground()`'s answer for the day, and whether it has been worked out yet — cleared in
## `start_day()`.
var _gate_ground_tiles := {}
var _gate_ground_ready := false

func _add_door_reach(door: Vector2, facing: Vector2, reach: float, near: Dictionary,
		lines: Dictionary) -> void:
	var axis := facing.normalized()
	var centre_tile := _city.map.world_to_tile(door)
	var span := ceili(reach / Tuning.TILE_SIZE) + 1
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var tile := centre_tile + Vector2i(dx, dy)
			var offset := _city.map.tile_to_world(tile) - door
			if offset.length() > reach:
				continue
			# At most half a tile, not under it: a door body stands in the middle of its two-lane
			# sidewalk or its carriageway, on the line between two lanes, so both lanes' centres
			# are exactly half a tile off it and both are the crossing.
			if axis != Vector2.ZERO and absf(offset.cross(axis)) <= Tuning.TILE_SIZE * 0.5 + 0.01:
				lines[tile] = true
			else:
				near[tile] = true

## A live instance `body_clear_tiles()` keeps clear of — the same rows `_is_planned_body()` names,
## while the instance is solid (`EventInstance.is_solid()`: a pursuer that has stopped waiting, or
## a `SolidWhen.ONCE_IT_STARTS` row still in its notice, is not).
func _is_standing_body(instance: EventInstance) -> bool:
	return not instance.is_finished and instance.is_solid() and _is_planned_body(instance.def)

## The ground a leg keeps off once `instance`'s solid body has caught her: the tiles whose centre
## lies within `_CAUGHT_CLEARANCE` of its pieces. The rig asks it when a stall finds her pressed
## against a body (`RouteRig._note_what_caught_her()`) and keeps the answer off for the rest of the
## leg.
func ground_round_body(instance: EventInstance) -> Dictionary:
	return _tiles_near_body(instance, _CAUGHT_CLEARANCE)

## The same for a spot on a wall or a barrier she was pressed against, which has no outline to ask
## for: the tiles whose centre lies within `_CAUGHT_CLEARANCE` of `point`.
func ground_round_point(point: Vector2) -> Dictionary:
	return _tiles_near_point(point, _CAUGHT_CLEARANCE)

## The tiles whose centre lies within `margin` of `instance`'s own solid pieces — its
## `EventInstance.solid_part_centres()` and `solid_part_shapes()`, the same pieces its collision is
## built from, along `solid_axis()`.
func _tiles_near_body(instance: EventInstance, margin: float) -> Dictionary:
	return _tiles_near_pieces(instance.solid_part_centres(), instance.solid_part_shapes(),
			instance.solid_axis(), margin)

## The tiles whose centre lies within `margin` of any of a body's pieces, each measured against its
## real shape: a segment turned along `axis` the way `EventInstance._build_obstruction()` turns its
## capsule, and a rectangle left square.
func _tiles_near_pieces(centres: PackedVector2Array, shapes: Array[GroundShape], axis: Vector2,
		margin: float) -> Dictionary:
	var near := {}
	for k in centres.size():
		var shape := shapes[k]
		var angle := axis.angle() if shape.half_length > 0.0 else 0.0
		var centre_tile := _city.map.world_to_tile(centres[k])
		var span := ceili((shape.reach() + margin) / Tuning.TILE_SIZE) + 1
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var tile := centre_tile + Vector2i(dx, dy)
				var local := (_city.map.tile_to_world(tile) - centres[k]).rotated(-angle)
				if shape.distance_to_spine(local) - shape.radius < margin:
					near[tile] = true
	return near

## The tiles whose centre lies within `margin` of `point`.
func _tiles_near_point(point: Vector2, margin: float) -> Dictionary:
	var near := {}
	var centre_tile := _city.map.world_to_tile(point)
	var span := ceili(margin / Tuning.TILE_SIZE) + 1
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var tile := centre_tile + Vector2i(dx, dy)
			if _city.map.tile_to_world(tile).distance_to(point) < margin:
				near[tile] = true
	return near

## The cheapest walk (`_cheapest()`) from `from_tile` to `to_tile`: along the sidewalk and across
## at a zebra where it can (see the class doc, "Hugs the kerb"), off every live hazard, clear of
## every body (`body_clear_tiles()`), out of every door's reach (`door_tiles()`, which leaves each
## door's own crossing line open) and off `avoid` — the ground round what has already caught her
## this leg, which the rig hands every re-plan (`RouteRig._leg_avoid`), `{}` for a first plan.
## Simplified by `_simplify()`, as tiles; `to_world()` turns them into the rig's waypoints, and
## `crossed()` says which tiles of the clearance and the doors' reach it chose to cross.
##
## **Each preference is a price per tile, not a rule for the whole leg**: a plain `ROAD` tile costs
## `_ROAD_STEP_COST` tiles of walking on top of the step, a tile of a body's clearance
## `_CLEARANCE_STEP_COST` and a tile of a door's reach `_DOOR_STEP_COST`, so a plan crosses one only
## where going round it is longer still, and only that one. A preference given up for a whole leg
## is given up everywhere on it: for one pinch — the only way into a mark's alley passing a body's
## side — the plan runs her down the outline of every body on the way, a roadblock's beside a door
## included, where she stalls; the doors' reach given up the same way walks her into doors she never
## meant to cross; and a sidewalk kept at any price sends her hundreds of tiles round a door's wall
## rather than down a stretch of carriageway.
##
## Tried in order: `avoid` kept off outright, since a re-plan goes round what caught her; then
## `avoid` priced at `_AVOID_STEP_COST`, where nothing else gets past it; and only then with the
## hazards ignored, so a guard that has boxed in the only way through skips the target rather than
## reporting one unreachable that a wider margin merely made look that way.
##
## **A target on ground no plan may end on is aimed beside** (`_standable_near()`): the neighbor day
## 10 sends her after walks along pavement a van has sealed, and a mark or a task is reached from
## `ContactPoint.REACH` (36px), more than a tile, so the tile beside it reaches it as well.
func plan(from_tile: Vector2i, to_tile: Vector2i, avoid: Dictionary = {}) -> Array[Vector2i]:
	to_tile = _standable_near(to_tile)
	var clear := body_clear_tiles()
	var doors := door_tiles()
	var costs := {}
	for tile: Vector2i in clear:
		costs[tile] = _CLEARANCE_STEP_COST
	for tile: Vector2i in doors:
		costs[tile] = _DOOR_STEP_COST
	var soft_avoid := costs.duplicate()
	for tile: Vector2i in avoid:
		soft_avoid[tile] = maxi(soft_avoid.get(tile, 0), _AVOID_STEP_COST)
	_plan_accepted = {}
	# Each tier: what it keeps off outright, what it charges for, and whether it keeps off hazards.
	var tiers: Array = []
	if not avoid.is_empty():
		tiers.append([avoid, costs, true])
	tiers.append([{}, soft_avoid, true])
	tiers.append([{}, soft_avoid, false])
	for tier: Array in tiers:
		var path := _cheapest(from_tile, to_tile, tier[0], tier[1], tier[2])
		if not path.is_empty():
			for tile in path:
				if clear.has(tile) or doors.has(tile):
					_plan_accepted[tile] = true
			return _simplify(path)
	return []

## `tile`, or where every plan blocks it outright (`_blocked_for_phase()`'s own ground, and ground
## that is not walkable at all) the nearest walkable tile beside it that is not, a ring at a time out
## to two tiles; `tile` unchanged where none is. Asked of the very ground every plan keeps off, so a
## target on it is aimed beside for exactly the reasons a plan would never step on it.
func _standable_near(tile: Vector2i) -> Vector2i:
	var blocked := _blocked_for_phase(false)
	if _city.map.is_walkable(tile) and not blocked.has(tile):
		return tile
	for radius in range(1, 3):
		var best := Vector2i(-1, -1)
		var best_distance := INF
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var near := tile + Vector2i(dx, dy)
				var distance := Vector2(dx, dy).length()
				if _city.map.is_walkable(near) and not blocked.has(near) and distance < best_distance:
					best = near
					best_distance = distance
		if best != Vector2i(-1, -1):
			return best
	return tile

## Every tile whose centre lies within her body's reach of a precinct's post (`CityMap.post_positions()`).
## The posts close the carriageway band at each precinct mouth *(2026-10-10, the player: "it will
## make the middle of the road impassable when going from street to pedestrian road")*, so the rig
## never plans through the row and goes round by the pavement either side, which a post's 4.8px
## radius plus her `_BODY_CLEARANCE` leaves open: the pavement tile beside the end post is 20px from
## it. The posts are a fact about the lattice, so this is worked out once per map.
var _post_cache := {}
var _post_cache_map: CityMap

func _post_tiles() -> Dictionary:
	if _post_cache_map == _city.map:
		return _post_cache
	_post_cache_map = _city.map
	_post_cache = {}
	var reach := _BODY_CLEARANCE + Prop.bollard_shape().radius
	for at in _city.map.post_positions():
		_post_cache.merge(_tiles_near_point(at, reach))
	return _post_cache

## What `_cheapest()` charges for stepping onto a tile `plan()` would rather keep off, in tiles of
## ordinary walking on top of the step itself. **A door's reach costs most**, since walking into it
## is a crossing she did not mean to make: a hold, a far side to plan from and a way back. **A
## body's clearance next**, since a step there presses her against the body, and it has to cost more
## than going round the body on the carriageway — past a kerbed van, the far lane and the steps out
## to it and back are about five tiles of road. **The carriageway least**, and enough that a street
## is crossed at a zebra up to `_ROAD_STEP_COST` tiles along rather than straight over its two lanes.
## `_AVOID_STEP_COST`, the ground round what already caught her, sits between the road and the
## clearance: a detour of choice, but one the stall ladder has already paid for once.
const _DOOR_STEP_COST := 128
const _CLEARANCE_STEP_COST := 64
const _AVOID_STEP_COST := 16
const _ROAD_STEP_COST := 8

## The tiles of the clearance and the doors' reach the last plan chose to cross (`plan()`).
var _plan_accepted := {}

## The tiles of a body's clearance and a door's reach the last `plan()` chose to cross. The rig
## re-plans when a body the director sites from her walk, or a door's reach, comes to lie over a
## waypoint, but not over these: a plan that had to cross them would only be made again onto the
## same ground, every check.
func crossed() -> Dictionary:
	return _plan_accepted

## The cheapest walk from `from_tile` to `to_tile` over `_blocked_for_phase()`'s ground, the live
## hazards (while `avoid_hazards`) and `keep_off` kept off outright, and `costs` — `tile -> extra`
## tiles of walking — plus `_ROAD_STEP_COST` on every plain `ROAD` tile charged for. Empty when
## nothing reaches it.
##
## `to_tile` is dropped from the hazards, `keep_off` and `costs` before they count — the fairness
## contract that guards a mark (`docs/DECISIONS.md`, "The guard robber is placed inside a
## building": the least a guarded mark's own contact point is ever placed from its guard is
## `alley_robbery.inner_radius + ContactPoint.REACH`, 62px) already keeps the exact point she is
## walking to outside the true kill radius; `_HAZARD_MARGIN`'s own slack can still read the
## target's own tile as blocked without this, which would report a guarded mark unreachable rather
## than merely guarded, and a mark beside a parked van is still a mark, since
## `ContactPoint.REACH` (36px) completes it before she is near enough to press against the van.
## `from_tile` is dropped from the **whole** blocked set, hazard and obstruction and closure alike,
## because a sweep reads a blocked seed as nothing to sweep from at all, so anything that merely
## brushes wherever she already legally is (a hazard's own margin close by but outside the true
## kill radius, since she is walking and not dead; a fresh obstruction that has just closed in
## around her) would report *every* tile unreached rather than a detour away from it, and the leg
## would re-plan every check for the rest of the run rather than ever getting past it. The ground
## *around* either tile keeps its ordinary rules — only the one tile she is actually standing on,
## or the one she is actually trying to reach, is ever exempted.
func _cheapest(from_tile: Vector2i, to_tile: Vector2i, keep_off: Dictionary = {},
		costs: Dictionary = {}, avoid_hazards: bool = true) -> Array[Vector2i]:
	var hazards := _hazard_tiles() if avoid_hazards else {}
	hazards.merge(keep_off)
	hazards.erase(to_tile)
	var blocked := _blocked_for_phase(false, {}, hazards)
	blocked.erase(from_tile)
	var extra := costs.duplicate()
	extra.erase(to_tile)
	var field := _weighted_field(from_tile, blocked, extra)
	if _city.map.distance_at(field, to_tile) < 0:
		return []
	var reversed: Array[Vector2i] = [to_tile]
	var current := to_tile
	while current != from_tile:
		var next := _smaller_neighbour(field, current)
		if next == current:
			return []
		reversed.append(next)
		current = next
	reversed.reverse()
	return reversed

## `CityMap.walk_field()` with a cost per step: `_base_steps()`, plus `extra[tile]` for stepping
## onto a tile it names. The same flat grid and the same `UNREACHED`/`BLOCKED` values, so
## `distance_at()` and `_smaller_neighbour()` read it unchanged — the smallest neighbour of any
## reached tile is a cheapest way back toward `from`, since no neighbour can be cheaper than the
## tile's own cost less the step onto it. A bucket queue rather than a heap: every step costs at
## least 1 and at most the dearest road tile inside a door's reach, so a ring of one more bucket
## than that holds every distance still to be settled. The four neighbour steps are written out,
## as `walk_field()`'s are, for its reason.
func _weighted_field(from: Vector2i, blocked: Dictionary, extra: Dictionary) -> PackedInt32Array:
	var map := _city.map
	var width := map.size.x
	var cells := width * map.size.y
	var field := PackedInt32Array()
	field.resize(cells)
	field.fill(CityMap.UNREACHED)
	for tile: Vector2i in blocked:
		if map.in_bounds(tile):
			field[tile.y * width + tile.x] = CityMap.BLOCKED
	var walkable := _walkable_cells()
	if not map.in_bounds(from) or walkable[from.y * width + from.x] == 0:
		return field
	var step := _base_steps().duplicate()
	for tile: Vector2i in extra:
		if map.in_bounds(tile):
			step[tile.y * width + tile.x] += int(extra[tile])
	var ring := _DOOR_STEP_COST + _ROAD_STEP_COST + 2
	var buckets: Array[Array] = []
	for slot in ring:
		buckets.append([])
	var start := from.y * width + from.x
	field[start] = 0
	buckets[0].append(start)
	var pending := 1
	var distance := 0
	while pending > 0:
		var slot := distance % ring
		var bucket: Array = buckets[slot]
		buckets[slot] = []
		pending -= bucket.size()
		for index: int in bucket:
			if field[index] != distance:
				continue
			var x := index % width
			if x > 0:
				pending += _relax(field, buckets, walkable, step, index - 1, distance, ring)
			if x < width - 1:
				pending += _relax(field, buckets, walkable, step, index + 1, distance, ring)
			if index >= width:
				pending += _relax(field, buckets, walkable, step, index - width, distance, ring)
			if index + width < cells:
				pending += _relax(field, buckets, walkable, step, index + width, distance, ring)
		distance += 1
	return field

## One step of `_weighted_field()` onto `to`: answers 1 when it queued `to` at a new cost, else 0.
func _relax(field: PackedInt32Array, buckets: Array[Array], walkable: PackedByteArray,
		step: PackedInt32Array, to: int, distance: int, ring: int) -> int:
	if walkable[to] == 0:
		return 0
	var known := field[to]
	if known == CityMap.BLOCKED:
		return 0
	var reach := distance + step[to]
	if known != CityMap.UNREACHED and reach >= known:
		return 0
	field[to] = reach
	buckets[reach % ring].append(to)
	return 1

## Which cells are walkable ground at all, by `CityMap.is_walkable()`, and what a step onto each
## costs before anything the day has put there — 1, and `_ROAD_STEP_COST` more on a plain `ROAD`
## tile — as flat grids worked out once a day. Cleared in `start_day()`.
var _walkable := PackedByteArray()
var _steps := PackedInt32Array()

func _walkable_cells() -> PackedByteArray:
	if _walkable.is_empty():
		var map := _city.map
		_walkable.resize(map.size.x * map.size.y)
		for y in map.size.y:
			for x in map.size.x:
				_walkable[y * map.size.x + x] = 1 if map.is_walkable(Vector2i(x, y)) else 0
	return _walkable

func _base_steps() -> PackedInt32Array:
	if _steps.is_empty():
		var map := _city.map
		_steps.resize(map.size.x * map.size.y)
		_steps.fill(1)
		for tile: Vector2i in _road_tiles:
			_steps[tile.y * map.size.x + tile.x] = 1 + _ROAD_STEP_COST
	return _steps

func _smaller_neighbour(field: PackedInt32Array, tile: Vector2i) -> Vector2i:
	var best := tile
	var best_distance := _city.map.distance_at(field, tile)
	for step in _STEPS:
		var neighbour := tile + step
		var distance := _city.map.distance_at(field, neighbour)
		if distance >= 0 and distance < best_distance:
			best = neighbour
			best_distance = distance
	return best

## String-pulling: a straight line from `path[anchor]` to `path[probe]` replaces every tile between
## them wherever `_line_of_sight()` allows it, so a corner is cut the way a person walks it rather
## than traced stair-step tile by tile.
func _simplify(path: Array[Vector2i]) -> Array[Vector2i]:
	if path.size() <= 2:
		return path
	var simplified: Array[Vector2i] = [path[0]]
	var anchor := 0
	var probe := 2
	while probe < path.size():
		# A tile of a body's clearance the plan chose to cross stays a waypoint of its own, so
		# `to_world()` can move it to the roomiest point of the tile.
		if not _plan_accepted.has(path[probe - 1]) and _line_of_sight(path[anchor], path[probe]):
			probe += 1
		else:
			simplified.append(path[probe - 1])
			anchor = probe - 1
			probe += 1
	simplified.append(path[path.size() - 1])
	return simplified

## A straight cut's own clearance either side of its centre line — comfortably past
## `Tuning.PLAYER_BODY_RADIUS` (14px), which is what a bare centreline sample cannot see: a line
## that only ever grazes a building's corner reads as clear tile by tile while her own collision
## shape still catches on the corner and stalls dead, pressing a heading that goes nowhere. Checked
## either side of the line rather than only widened at each sample point, so a cut still refuses a
## building that sits square against the line without ever being the line's own nearest tile.
const _LINE_OF_SIGHT_CLEARANCE := 24.0

## Whether the straight world-space line between two tile centres, with `_LINE_OF_SIGHT_CLEARANCE`
## either side of it, stays on open, unobstructed, non-`ROAD`, non-hazardous ground the whole way —
## `CROSSING` (a zebra) is fine, since crossing there is legal; a bare `ROAD` tile is refused even
## if the raw walk touched one nearby, so smoothing can never introduce a fresh stretch of
## carriageway the kerb-preferring plan did not already decide it needed. Checked against
## `is_hazardous()` too — the raw walk already kept off a live guard's own reach (`_hazard_tiles()`
## in `_blocked_for_phase()`); a straight cut refusing the same ground is what keeps a corner-cut
## from putting that ground back.
##
## **Refuses a true diagonal outright, before sampling anything.** `a` and `b` differing on both
## axes means the cut would cross a 2x2 corner the raw 4-connected walk never actually crossed —
## `ReachabilityGrid`'s own doc calls the case out by name: a cell can split into two components
## that do not connect to each other across exactly that corner, so open ground on both of the
## corner's *other* two tiles proves nothing about whether the fifth point, the corner itself, is
## walkable at all. A straight run along one row or one column carries no such gap — every tile it
## passes through was already a single 4-connected step somewhere in the raw walk — so smoothing
## only ever removes a redundant waypoint from a corridor already proven walkable tile by tile.
func _line_of_sight(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x and a.y != b.y:
		return false
	var start := _city.map.tile_to_world(a)
	var stop := _city.map.tile_to_world(b)
	var offset := stop - start
	if offset.length() < 0.001:
		return true
	var perpendicular := Vector2(-offset.y, offset.x).normalized() * _LINE_OF_SIGHT_CLEARANCE
	var steps := maxi(1, ceili(offset.length() / _LINE_OF_SIGHT_STEP))
	for i in steps + 1:
		var centre := start.lerp(stop, float(i) / float(steps))
		for point in [centre, centre + perpendicular, centre - perpendicular]:
			var tile := _city.map.world_to_tile(point)
			if not _city.map.is_open(tile) or _city.map.is_obstructed(tile):
				return false
			if _city.map.tile_at(tile) == GameEnums.TileType.ROAD:
				return false
			if is_hazardous(point):
				return false
	return true

## The tile a plan starts from: the one she stands on, or — where that is not open ground at all —
## the nearest open tile to her. A door can set her down on a tile that is not ground
## (`CheckpointController._release_finished_holds()` mirrors her through the door without
## asking what is there), and a sweep seeded on a building reaches nothing, which read as every
## target unreachable from there. The rig plans every leg and re-plan from it.
##
## **Outside a door's reach where there is such a tile near her.** The door that set her down there
## let her out beside its own body, and the nearest open tile can lie back inside its trigger: a
## plan starting there walked her straight back in, and the door took her across again.
func standing_tile() -> Vector2i:
	var here := _player.global_position
	var tile := _city.map.world_to_tile(here)
	if _city.map.is_open(tile):
		return tile
	var doors := door_tiles()
	var best := tile
	var best_distance := INF
	for keep_off: Dictionary in [doors, {}]:
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var near := tile + Vector2i(dx, dy)
				var distance := _city.map.tile_to_world(near).distance_to(here)
				if _city.map.is_open(near) and not keep_off.has(near) and distance < best_distance:
					best = near
					best_distance = distance
		if best_distance < INF:
			return best
	return best

## The waypoints of `path` in world space, which the rig walks: each tile's centre, except a tile of
## a body's clearance the plan chose to cross (`crossed()`), which is its roomiest point
## (`_roomiest_point()`).
func to_world(path: Array[Vector2i]) -> Array[Vector2]:
	var world: Array[Vector2] = []
	for k in path.size():
		var tile := path[k]
		# Not the tile she stands on: she is already on it, and walking to another point of it
		# first takes her back and forth across a pinch the stall checks then never see her stuck in.
		world.append(_roomiest_point(tile) if k > 0 and _plan_accepted.has(tile)
				else _city.map.tile_to_world(tile))
	return world

## How far off a tile's centre `_roomiest_point()` looks, in each axis — short of half a tile, so
## the point stays on the tile the plan chose — and the step it looks in.
const _NUDGE_REACH := 15.0
const _NUDGE_STEP := 2.5

## The point of `tile` farthest from every standing body's surface and every wall beside it, or
## its centre where nothing is near. **A plan walks tile centres, and a gap can fit her only off
## them**: two vans at the kerb either side of a two-lane road leave 48px between their sides, 10px
## either side of her 28px body if she walks the line between the lanes, and 8px short of her
## radius on either lane's centre, so walking a lane she scrapes one van and stalls against it.
## Asked only of a tile the plan crosses in a body's clearance; everywhere else a tile's centre is
## already at least `_BODY_CLEARANCE` from every body.
func _roomiest_point(tile: Vector2i) -> Vector2:
	var centre := _city.map.tile_to_world(tile)
	var pieces := _body_pieces_near(centre, Tuning.TILE_SIZE * 3.0)
	if pieces.is_empty():
		return centre
	var walls: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var near := tile + Vector2i(dx, dy)
			if near != tile and not _city.map.is_open(near):
				walls.append(near)
	var best := centre
	var best_room := _room_at(centre, pieces, walls)
	var steps := roundi(_NUDGE_REACH / _NUDGE_STEP)
	for sy in range(-steps, steps + 1):
		for sx in range(-steps, steps + 1):
			var point := centre + Vector2(sx, sy) * _NUDGE_STEP
			var room := _room_at(point, pieces, walls)
			if room > best_room + 0.01:
				best = point
				best_room = room
	return best

## How far `point` is from the nearest of `pieces`' surfaces and `walls`' squares.
func _room_at(point: Vector2, pieces: Array, walls: Array[Vector2i]) -> float:
	var room := INF
	for piece: Array in pieces:
		var shape: GroundShape = piece[1]
		var local := (point - (piece[0] as Vector2)).rotated(-float(piece[2]))
		room = minf(room, shape.distance_to_spine(local) - shape.radius)
	for wall in walls:
		room = minf(room, _tile_nearest_distance(wall, point))
	return room

## Every solid piece of a standing body within `radius` of `point`, as `[centre, shape, angle]` —
## the live instances `body_clear_tiles()` keeps clear of, and the placed plans not yet built,
## measured the same way.
func _body_pieces_near(point: Vector2, radius: float) -> Array:
	var pieces: Array = []
	for instance: EventInstance in _city.events.instances():
		if _is_standing_body(instance):
			_add_pieces_near(pieces, instance.solid_part_centres(), instance.solid_part_shapes(),
					instance.solid_axis(), point, radius)
	for planned: EventScheduler.Planned in _city.events.plans():
		if planned.live != null or not planned.is_placed() or planned.spent \
				or not _is_planned_body(planned.def):
			continue
		if _planned_position(planned).distance_to(point) > radius + planned.def.shape.reach() * 2.0:
			continue
		var parts := _planned_parts(planned)
		_add_pieces_near(pieces, parts[0], parts[1], parts[2], point, radius)
	return pieces

func _add_pieces_near(pieces: Array, centres: PackedVector2Array, shapes: Array[GroundShape],
		axis: Vector2, point: Vector2, radius: float) -> void:
	for k in centres.size():
		var shape := shapes[k]
		if centres[k].distance_to(point) - shape.reach() > radius:
			continue
		var angle := axis.angle() if shape.half_length > 0.0 else 0.0
		pieces.append([centres[k], shape, angle])

# ----------------------------------------------------------------- unsticking ---

## The eight compass points — an escape direction is found by trying one, not by reasoning about
## the obstruction's own shape, which nothing here can ask about; `unstick_order()` only decides
## which is tried first. The diagonals are `sqrt(0.5)` a side rather than `.normalized()` at the
## call site, since a `const` initialiser has to be a constant expression and cannot call a method
## — `Input.get_vector` clamps to unit length regardless, so the two are the same press either way.
const _UNSTICK_DIRECTIONS: Array[Vector2] = [
	Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
	Vector2(0.7071067811865476, -0.7071067811865476), Vector2(-0.7071067811865476, -0.7071067811865476),
	Vector2(0.7071067811865476, 0.7071067811865476), Vector2(-0.7071067811865476, 0.7071067811865476),
]

## The eight compass points in the order the rig's maneuver tries them when a stall has outlasted a
## re-plan and a wait (`RouteRig._begin_unstick()`): sorted so the one pointing most directly away
## from what caught her (`away`, the sum of her slide collisions' normals) is tried first, or in
## `_UNSTICK_DIRECTIONS`' own order when nothing solid was touching her (`Vector2.ZERO`). Pressing
## into the body first spends a whole try on the one direction that cannot work. **A direction that
## would carry her `reach` into a door's circle is tried last** (`_into_a_door()`): the door would
## take her across, and a stall beside a door is usually just past it, where the plan she stalled on
## is carrying her away from it.
func unstick_order(away: Vector2, reach: float) -> Array[Vector2]:
	var order := _UNSTICK_DIRECTIONS.duplicate()
	if away != Vector2.ZERO:
		order.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			return a.dot(away) > b.dot(away))
	var clear_of_doors: Array[Vector2] = []
	var into_doors: Array[Vector2] = []
	for direction in order:
		if _into_a_door(_player.global_position + direction * reach):
			into_doors.append(direction)
		else:
			clear_of_doors.append(direction)
	clear_of_doors.append_array(into_doors)
	return clear_of_doors

## Whether `point` lies inside the circle a door body takes her in from
## (`EventDef.detain_distance()` of a hut or a post, the `redetains` rows).
func _into_a_door(point: Vector2) -> bool:
	for planned: EventScheduler.Planned in _city.events.plans():
		if not planned.is_placed() or planned.spent or not planned.def.redetains:
			continue
		var door := planned.live.global_position if planned.live != null \
				else _planned_position(planned)
		if point.distance_to(door) <= planned.def.detain_distance():
			return true
	return false
