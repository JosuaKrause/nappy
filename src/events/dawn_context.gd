class_name DawnContext
extends RefCounted
## **One dawn in one object, handed to every phase of it**: what the day's planner hands the dawn
## (the walk's spec, the day's seed, the map, the walk, its calm areas, the plan builder, what the
## run has done, the doors, what stands, the mast sites, the trace, the roadblock phase's row) and
## what the dawn builds from them once (the walk's corridor, the day's events, its locations, its
## ground for a row, its rules). `EventScheduler.build_day()` takes one and plans into it.
##
## *(inbox #1156 in gray-dolphin: "have an object that contains the derived information -- don't
## rederive over and over again -- then pass that object around".)*
##
## **It is handed everything it asks**, by whoever makes it: the day's planner (`DayPlanner`), or
## `tests/game_dawn.gd` for a suite. What every dawn has comes with the constructor. What a walk
## may be without is handed in after it (`use_the_run()`, `use_the_doors()`, `use_what_stands()`,
## `use_mast_sites()`, `use_trace()`, `use_the_roadblock_row()`), all before the dawn is planned:
## no phase calls one.
##
## **The constructor derives nothing.** Each built thing is made the first time it is asked for
## and kept, so every phase asks the same one, and a test hands whatever takes a context a
## stand-in that overrides the questions it sets, with no city built.
##
## **A context lives exactly one dawn.** Nothing it reads moves inside one: the grid is repainted
## and the day's closures and holds are on the map before it is made. Model: no node.

var _spec: DaySpec
var _seed := 0
var _map: CityMap
var _walk: RouteSource
var _calm: CalmAreas
var _builder: PlanBuilder
## `(map: CityMap, corridor: Corridor, from_the_door: bool) -> RowGround`: makes the walk's ground.
var _ground_of: Callable
var _spent_one_shots: Array[String] = []
var _scars: Array[Dictionary] = []
var _heat := 0
var _doors := PackedVector2Array()
var _standing: Array[EventPlan] = []
var _mast_sites: Array[MastSites.Site] = []
var _trace: RunTrace = null
var _roadblock_row: EventDef = null

var _corridor: Corridor = null
## Whether `_corridor` was asked of the walk yet: a walk that is not a tree answers null.
var _corridor_is_known := false
var _events: DayEvents = null
var _ground: RowGround = null
var _locations: DayLocations = null
var _kept_clean := CalmAreas.NONE
var _rules: StreetInvalidation = null
var _route_ground: RouteGroundRule = null

## The dawn of the walk `spec` describes, on `map`, placed against `walk` and `calm`:
## `seed_value` is the day's seed, `builder` builds every plan the dawn sites at a tile, and
## `ground_of` makes the walk's ground for a row from the map, the walk's corridor and the spec's
## home-street rule (the game's is `EventScheduler.row_ground`, whose weights and whose reading of
## a wall are the scheduler's own, so this file names neither).
func _init(spec: DaySpec, seed_value: int, map: CityMap, walk: RouteSource, calm: CalmAreas,
		builder: PlanBuilder, ground_of: Callable) -> void:
	_spec = spec
	_seed = seed_value
	_map = map
	_walk = walk
	_calm = calm
	_builder = builder
	_ground_of = ground_of

# ----------------------------------------------------------------- handed in ---

## Hands the dawn what the run has done so far: the one-shots it has spent, the scars it left and
## its heat (`spent_one_shots()`, `scars()`, `heat()`).
func use_the_run(spent_one_shots: Array[String], scars: Array[Dictionary], heat: int) -> void:
	_spent_one_shots = spent_one_shots
	_scars = scars
	_heat = heat

## Hands the dawn where today's region-door bodies stand (`doors()`).
func use_the_doors(doors: PackedVector2Array) -> void:
	_doors = doors

## Hands the dawn what obstructs the day whatever it plans: the seals and the region wall's own
## bodies, both planned before it, which the day's rules read with what the dawn places
## (`DayEvents.standing()`).
func use_what_stands(standing: Array[EventPlan]) -> void:
	_standing = standing

## Hands the dawn the run's mast sites (`mast_sites()`).
func use_mast_sites(sites: Array[MastSites.Site]) -> void:
	_mast_sites = sites

## Hands the dawn where its planning writes its own account (`note()`).
func use_trace(trace: RunTrace) -> void:
	_trace = trace

## Hands the dawn the row its roadblock phase stands beside the day's routes (`roadblock_row()`).
func use_the_roadblock_row(row: EventDef) -> void:
	_roadblock_row = row

# ------------------------------------------------------------ what it was handed ---

## The walk's spec: which rows, how they are drawn, and which placement rules apply
## (`DaySpec`, "how its events are placed").
func spec() -> DaySpec:
	return _spec

## The day the catalogue's rows are read for (`DaySpec.day_number()`).
func day() -> int:
	return _spec.day_number()

## The day's seed, which every stream of the dawn starts from.
func day_seed() -> int:
	return _seed

## A private stream for one phase of the dawn, off the day's seed and the phase's `salt`.
##
## **A retried day has to be the same day, and one shared stream cannot deliver that.** Run the
## phases off a single sequence and anything that changes how much an earlier phase draws moves
## everything after it — and two things change between attempts by design:
##
## - `DawnOneShots` skips a one-shot the run has already spent. Skipping it
##   *before* drawing its `randf()` would start every later phase's draws one value earlier on the
##   second attempt and produce a different city's worth of events.
## - `DawnScars` prepends what the run has burnt down, and every scar is one
##   more plan for `StreetInvalidation.room_around` to reject a placement against — and a
##   rejection is a re-roll.
##
## Separate streams close the first completely and most of the second (each phase's salt, the dawn
## draw's `LOCATIONS_SALT` among them).
## What is deliberately *not* closed: a scar that genuinely occupies the ground an event wanted
## still moves that event. That is the right answer — a fire that burnt a block down did happen,
## and the day should acknowledge it — and it is a handful of placements rather than the whole
## day.
func stream(salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [_seed, salt])
	return rng

func map() -> CityMap:
	return _map

## The walk every placement is stated against (`RouteSource`): a day's tree, or the escape's
## chains, whose streets its bag fills. Never null: a rig with no route hands a `RouteSource`
## itself, which is no walk at all.
func walk() -> RouteSource:
	return _walk

## The walk's corridor (`RouteSource.corridor()`), asked once: where the day's routes run, as a
## question about a tile, which is what turns *wall* and *friction* from words into placements.
## Null for a walk that is not a tree.
func corridor() -> Corridor:
	if not _corridor_is_known:
		_corridor = _walk.corridor()
		_corridor_is_known = true
	return _corridor

## The day's calm areas (`CalmAreas`): which she has settled in so far this act, and the one that
## does not count today.
func calm() -> CalmAreas:
	return _calm

## Where today's region-door bodies stand. Nothing the dawn places may put a field or a beat
## inside `Tuning.CHECKPOINT_EVENT_GAP` of one (`DoorClearanceRule.clear_of_the_doors()`).
func doors() -> PackedVector2Array:
	return _doors

## The run's heat (`RunState.resistance.progress`). **Handed in rather than read off the run**, so
## that a day is a function of what its context holds: a rig that plans day 9 twice gets the same
## day twice whatever a run happens to have done.
func heat() -> int:
	return _heat

## The permanent marks earlier days left (`DawnScars`, `DawnMasts`).
func scars() -> Array[Dictionary]:
	return _scars

## The one-shots the run has spent, which the dawn owes her walk no second time. Read, never
## written here: a one-shot is spent where it becomes real (`EventStreaming.stream_in()`).
func spent_one_shots() -> Array[String]:
	return _spent_one_shots

## The run's mast sites, worked out once on the city as built (`EventWorld.mast_sites()`).
func mast_sites() -> Array[MastSites.Site]:
	return _mast_sites

## Builds every plan the dawn sites at a tile.
func builder() -> PlanBuilder:
	return _builder

## The row the roadblock phase stands beside the day's routes before the dawn draw, so that one
## is close by wherever she reads the task's mark: day 13's roadblock. Null on every other day,
## which is then planned exactly as it would be without it.
func roadblock_row() -> EventDef:
	return _roadblock_row

## Writes a line of the planning's own account for the run log (a one-shot owed to her walk, a
## lesson added, a park spoiled) where a trace was handed in; with none it writes nowhere. It
## changes nothing the plan holds.
func note(kind: String, text: String) -> void:
	if _trace:
		_trace.note(kind, text)

## Whether the planning's account is written anywhere: what a pass asks before work whose only
## result is a line of it.
func is_traced() -> bool:
	return _trace != null

# ------------------------------------------------------------ what the dawn builds ---

## **The day's plan** (`DayEvents`), over the day's calm areas and what stands: made here on the
## first ask, written by the dawn's passes and nothing else.
func events() -> DayEvents:
	if _events == null:
		_events = DayEvents.over(_calm, _standing)
	return _events

## **The walk's ground for a row** (`RowGround`): which tiles each row may stand on, worked out
## at most once a day. Made on the first ask over the walk's corridor and the spec's home-street
## rule (`DaySpec.holds_the_home_streets`), asked by every pass, and handed on by the day's
## planner to what is sited while she walks (`DayPlanner.Plan.ground()`), so nothing scans the
## city for it again.
func ground() -> RowGround:
	if _ground == null:
		var made: RowGround = _ground_of.call(_map, corridor(), _spec.holds_the_home_streets)
		_ground = made
	return _ground

## **The day's locations** (`DayLocations`), laid out once on the map as the day's holds leave it
## and each told its view by the walk's corridor.
func locations() -> DayLocations:
	if _locations == null:
		_locations = DayLocations.lay_out(_map, corridor())
	return _locations

## **Tells the dawn which calm area it keeps clean** besides the ones she has not used
## (`DawnCalmKeptClean`), `CalmAreas.NONE` for none: its ground joins what nothing may reach.
## Said once, after the fixed parts and the scars stand and before the first judge asks the rules,
## which are built over that ground once.
func keep_clean(block: Vector2i) -> void:
	assert(_rules == null, "the calm area kept clean is said before the day's rules are built")
	_kept_clean = block

## The calm area the dawn keeps clean by construction, `CalmAreas.NONE` for none: the spoilers
## pass over it.
func kept_clean() -> Vector2i:
	return _kept_clean

## **The day's placement rules** (`StreetInvalidation`), built once on the first ask and asked by
## every judge of the dawn: the calm ground to leave alone, the doors' clear ground and the route
## rules of the walk's corridor; one waiting guard's notice at a time where the spec keeps it
## (`DaySpec.one_notice_at_a_time`), and the walk kept open past what stands on it where the spec
## keeps that (`DaySpec.keeps_the_walk_open`, `WalkGround`).
func rules() -> StreetInvalidation:
	if _rules == null:
		var walk_ground: WalkGround = null
		if _spec.keeps_the_walk_open:
			walk_ground = WalkGround.new(_map, events().standing(), _walk)
		_rules = StreetInvalidation.new(_map, corridor(), _leave_alone(), _doors,
				_builder if _spec.one_notice_at_a_time else null, walk_ground)
	return _rules

## **Records a fixed part on the location holding where it stands**
## (`DayLocations.hold_fixed_part()`), so no draw happens there: an ambient row, a mast, one of
## the region wall's bodies. A part standing where no location is records nothing.
func hold_fixed_part(part: EventPlan) -> void:
	var tile := _map.world_to_tile(part.placed_at())
	locations().hold_fixed_part(part, tile, _map.tile_at(tile))

## **Whether `plan`, stood where it is, leaves the day's routes their ground**: what the run's
## scars and the park spoilers are asked (`RouteGroundRule`, counting the streets). Their ground
## is not the bags', and they keep the spacing and the line rules they stand without, so only
## this is asked of them: no body of theirs covers a tile a route runs along, the streets'
## included, nor the street she starts on. A field of one stands on a route's line as it always
## did; the question asks nothing of what the day holds or what stands.
##
## The street the front door opens onto, which nothing is placed on: the day's ground refuses it
## to every row (`RowGround.tiles_for()`), and the route's ground rule is handed it.
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
## something already happened (and its body is kept off this street by `RouteGroundRule`, which
## `keeps_the_routes()` counts this street as the routes' first stretch), and an ambient event
## has no tile.
func keeps_the_routes(plan: EventPlan) -> bool:
	var none: Array[EventPlan] = []
	return _route_ground_rule().allows(plan, _map.world_to_tile(plan.placed_at()), none, none)

## The rule `keeps_the_routes()` asks, made on the first ask.
func _route_ground_rule() -> RouteGroundRule:
	if _route_ground == null:
		var home := ClosurePlanner.home_street(_map)
		_route_ground = RouteGroundRule.new(_map, corridor(), true,
				home.tile_rect() if home else Rect2i())
	return _route_ground

## The calm ground nothing may be placed near today: the areas she has not used, where the spec
## keeps the calm rule (`CalmAreas.unused_ground()`), and the one the dawn keeps clean.
func _leave_alone() -> Array[Rect2]:
	var left: Array[Rect2] = []
	if _spec.keeps_unused_calm_clear:
		left = _calm.unused_ground()
	if _kept_clean != CalmAreas.NONE:
		left.append(_calm.ground_of(_kept_clean))
	return left
