class_name EventPlan
extends RefCounted
## What the manager needs to spawn one instance.
##
## An `AHEAD_OF_PLAYER` plan has **no position**: the day decides that one more cat is owed and
## the director decides where, later, out of where the player turns out to walk. `is_placed()`
## is the question everything that reasons about geometry has to ask first.

var _def: EventDef
var _position: Vector2
var _path := PackedVector2Array()
## Which way it is drawn facing, for a stationary event whose siting decided that. A mobile
## one gets its facing from the direction it is travelling and ignores this. A lorry backing
## into a yard has to have its back to the yard, and only the placement knows which side of the
## street the yard is on.
var _facing := Vector2.RIGHT

## The shared boom state a `checkpoint_gate` plan's instance draws raised or lowered from —
## `GateState`, built once per street door and carried here by
## `RegionPlanner._add_door_bodies`. `null` for every plan but a gate's own.
var _gate_state: GateState = null

## `MastSites.Site.id` for a mast's own plan (its ordinary broadcast and, on
## `DawnMasts.CURFEW_ANNOUNCE_DAY`, its curfew announcement too), `""` for everything else — the
## question `EventManager.silence_mast()` and the broadcast clock's own sync ask before
## touching a plan.
var _mast_id := ""
## Set by `EventManager.silence_mast()`/`silence_all_masts()` for the rest of the day. Carried
## on the plan, not only the live instance, so a mast silenced while out of reach is still
## silenced the next time she comes near it — see `EventStreaming.stream_in()`.
var _silenced := false

## **A plan that comes again** (`repeats()`): seconds from one of its instances coming to the
## next, and seconds from one being done to the next coming (`EventDef.repeat_every`,
## `repeat_after`, the row's unless a placement gives this plan its own, as each of the building's
## vents has its own period). Streaming keeps the clock they set (`EventStreaming`).
var _repeat_every := 0.0
var _repeat_after := 0.0
## Seconds from the start of the walk to its first instance coming (`come_first_in()`), so plans that
## come again on clocks of their own start out of step. 0 for a plan whose instance may be in the
## world at once, which is every plan that does not repeat.
var _first_comes_in := 0.0
## Whether this plan's instance is put where she stands each time it comes, rather than at
## `placed_at()` — the explosion outside, whose charge stands where she is wherever in the building
## she has got to. Its `placed_at()` is where it last came.
var _at_her := false
## The age each of its instances arrives at: 0 for one that comes and gives its notice, the
## row's `telegraph_time` for one whose notice is already over when it comes (the explosion
## outside: what the windows say is that it has already happened).
var _arrives_aged := 0.0

func _init(definition: EventDef, at: Vector2,
		route := PackedVector2Array()) -> void:
	_def = definition
	_position = at
	_path = route
	if definition:
		_repeat_every = definition.comes_again_every()
		_repeat_after = definition.comes_again_after()

## Whether this plan's instance comes again once it is done (`comes_again_every()`,
## `comes_again_after()`).
func repeats() -> bool:
	return _repeat_every > 0.0 or _repeat_after > 0.0

## Where its live event stands while this plan is streamed in, nowhere otherwise: the handle it was
## told when its event entered the world (`enter_the_world()`). A plan is the day's intention and
## the live event is the few seconds it exists for, and those are not the same span of time; the
## event itself is streaming's (`EventStreaming.event_of()`).
var _standing: WhereItStands = WhereItStands.nowhere()
## True once the event has run its course, so walking back past it does not start it again.
var _spent := false
## True for something the *run* left here rather than something today rolled — a burnt-out
## shell, a barricade. It is world history and the day may not tidy it away.
var _permanent := false
## True once something that rides this plan's instance asked for it to stay in the world for
## the rest of the day wherever she walks (`keep_in_the_world()`), so streaming never takes it
## away from under what rides it.
var _kept_in_the_world := false
## What the day placed this **for**, against today's corridor. See `GameEnums.BlockerRole` and
## `EventScheduler.role_for`.
##
## It is recorded rather than re-derived because it is not a function of the def: the same
## `cyclist` row is a wall on a day it is rolled and nothing at all when the director sites one
## in front of her, and the telemetry map has to be able to say which. The map and
## `keeps_its_field_clear()` read it, and `stand_where()` and `EventScheduler.owed_to_her_walk()`
## carry it from one plan to another: it decides where the plan went, it does not decide anything
## afterwards.
var _role := GameEnums.BlockerRole.NONE
## True once it has been in the world at least once (`has_been_in_the_world()`). What it is *for*
## is the bookkeeping that must happen exactly once however many times an event is streamed in and
## out: a burnt-out shell records the fire that made it the first time it is seen and never again.
var _has_been_in_the_world := false
## What its instance was in the middle of when it was last streamed out, so streaming it back in
## **restores** it rather than rewinding it (`EventStreaming.stream_in()`): its age, its distance,
## where it had noticed her (without it a row streamed out mid-chase comes back `is_waiting()`,
## having forgotten it) and each behaviour's state, such as a roadblock's spent guard and the post
## he left among it (`EventBarrierPost.save()`), so a re-streamed barrier is only the barrier.
## Empty before then and once a repeating plan starts over.
var _saved := EventSave.new()

## Whether this body is a region door's (`is_door()`). Private: set once, by
## `stand_as_a_door()`.
var _is_door := false
## Whether this body is the region wall's own (`is_in_the_wall()`). Private: set once, by
## `stand_in_the_wall()`.
var _in_the_wall := false
## Whether this body is one of the day's seals (`is_a_fixed_part()`). Private: set once, by
## `stand_as_a_seal()`.
var _is_a_seal := false

## False for an event the day has planned but not sited.
func is_placed() -> bool:
	return _position != Vector2.INF

## True once the event has run its course, so walking back past it does not start it again.
func is_spent() -> bool:
	return _spent

## Spends this plan for the rest of the day (`is_spent()`): it is not streamed in again.
func spend() -> void:
	_spent = true

## The id of the row this plan places (`EventDef.id`).
func row_id() -> String:
	return _def.id

## Whether `other` places the same row as this plan.
func is_the_same_row_as(other: EventPlan) -> bool:
	return _def.id == other._def.id

## Where the day placed this plan, `Vector2.INF` while it is unsited (`is_placed()`). Its instance
## may have moved since: `where_it_stands_now()` answers where it is.
func placed_at() -> Vector2:
	return _position

## **Where its body stands, as far as the lattice says**: `stands_without_a_map()` of where it was
## placed. Every reading of its geometry here asks it, and so do the day's disc readings of a body
## (`OneSidewalkOpenRule`, `RouteSidewalkRule`, `RouteGroundRule`, `DoorClearanceRule`,
## `EventScheduler.blocked_by()`, the roadblock phase, the day-13 swap), so a roadblock's band is
## read where it is drawn and solid, leaving the far sidewalk whole.
func body_at() -> Vector2:
	return stands_without_a_map(_def, _position)

## **Where a body of `row` built at `at` stands, as far as the lattice says without a map**: on the
## kerb beside its carriageway lane when the row stands at its kerb (`EventDef.stands_at_its_kerb()`,
## the roadblock, `CityMap.kerb_beside()`), otherwise `at`. The one place that decides the kerb:
## `BodyStance.stands_at()` asks it for the built body, which with a map also moves a sidewalk
## body onto its band's middle. **A plan's own reading stays without that move**: the move needs the
## pavement, which a plan holds no map to read, keeps a body on its own sidewalk, at most half a tile
## across it, and the day's rules have always read a sidewalk body where it was placed; the kerb
## changes what a band covers, the street's far sidewalk, and so is read here.
static func stands_without_a_map(row: EventDef, at: Vector2) -> Vector2:
	return CityMap.kerb_beside(at) if row.stands_at_its_kerb() else at

## **Whether this body is one of a region door's**: a `checkpoint_hut` or the `checkpoint_gate`
## at a street door's mouth, or a `checkpoint_post` at an alley door's. What makes a body a door
## is `RegionPlanner` standing it at one, not anything on its def, so the placement says it once
## and every reader asks it here: the zero-cost line (`counts_against_the_line()`), the
## director's clear ground round the doors (`EventDirector.start_day()`) and the resistance's
## reachability.
func is_door() -> bool:
	return _is_door

## Makes this body a region door's. Called by `RegionPlanner._add_door_bodies()` and
## `_add_alley_door_bodies()` as they make each one, and by nothing else.
func stand_as_a_door() -> void:
	_is_door = true

## **Whether this body is the region wall's own**: the hard seal `RegionPlanner` stands across a
## wall street or an alley mouth. Structure the boundary is made of, so day 13's task never takes
## one in place of a roadblock the day placed, nor replaces one (`ResistanceDirector.
## _place_the_roadblock_near()`).
func is_in_the_wall() -> bool:
	return _in_the_wall

## Makes this body the region wall's. Called by `DayPlanner._plan_a_day()` for each of the day's
## region plan's wall bodies, by `SceneRecipeRuntime` for each of a recipe's barriers, which stand
## in the wall a recipe selects, and by nothing else.
func stand_in_the_wall() -> void:
	_in_the_wall = true

## Whether this plan's instance is in the world now: its handle says there is a live event to ask
## (`WhereItStands.is_there()`).
func is_in_the_world() -> bool:
	return _standing.is_there()

## Whether this plan's instance has been in the world at least once, however long ago: what the
## director asks before it moves a plan, since a plan streamed in once has done what is done exactly
## once (a scar recorded, a block moved along its arc).
func has_been_in_the_world() -> bool:
	return _has_been_in_the_world

## **Tells the plan its instance has entered the world**, standing where `where` says: streaming
## says it as it puts the instance there (`EventStreaming.stream_in()`).
func enter_the_world(where: WhereItStands) -> void:
	_standing = where
	_has_been_in_the_world = true

## Keeps this plan's instance in the world for the rest of the day, wherever she walks: the
## streaming never takes it out (`is_kept_in_the_world()`).
func keep_in_the_world() -> void:
	_kept_in_the_world = true

## Whether something asked for this plan's instance to stay in the world for the rest of the day
## (`keep_in_the_world()`), which streaming asks before it takes the instance away.
func is_kept_in_the_world() -> bool:
	return _kept_in_the_world

## **Whether this plan is one of the city's fixed parts rather than one of the day's events**: the
## region wall's body (`is_in_the_wall()`), a door's (`is_door()`), a seal (`stand_as_a_seal()`), a
## loudspeaker mast (`mast_id()`) or an ambient row (a playground). The player's fixed parts: "the
## wall, doors, closures, seals, scars, masts and ambient rows" each "get phases during either dawn
## or beginning of the game" (inbox #1185 in gentle-owl); a closure is no plan, and the code's scar, the burnt
## shell a fire leaves, is a regular event ("your scars are just regular events", inbox #1185 in gentle-owl).
## Day 13's swap never takes the section of one (`ResistanceDirector._section_to_swap()`).
func is_a_fixed_part() -> bool:
	return _is_door or _in_the_wall or _is_a_seal or _mast_id != "" \
			or _def.is_ambient()

## Makes this body one of the day's seals. Called by `DayPlanner` for each seal it plans, and by
## nothing else.
func stand_as_a_seal() -> void:
	_is_a_seal = true

## Whether this plan stands at one point rather than moving along a route (`walks()`).
func stands_still() -> bool:
	return _path.size() < 2

## The row this plan places: what its pictures are, asked of her view before day 13's task takes
## its section (`ResistanceDirector._place_the_roadblock_near()`), and whether it spans the street
## (`DayLocations.assign()`).
func row() -> EventDef:
	return _def

## The route its body walks: a mover's beat or its run, empty for one that stands.
func walks() -> PackedVector2Array:
	return _path

## **Stands the plan where `sited` was judged**: takes its place, its route, its facing and its
## role. What her walk's siting tells a beat once a location takes it.
func stand_where(sited: EventPlan) -> void:
	_position = sited._position
	_path = sited._path
	_facing = sited._facing
	_role = sited._role

## Records where a plan that comes where she stands last came (`come_where_she_stands()`): the
## explosion outside's charge, which `EventStreaming` brings back on her spot each time.
func came_at(at: Vector2) -> void:
	_position = at

## Turns the plan to face `direction`: a crew faces the wall it pastes, the plan builder backs a
## van in, the region planner sets a door body's axis.
func face(direction: Vector2) -> void:
	_facing = direction

## Gives it the role a judge decided (`StreetInvalidation.room()`), which is where it went.
func give_role(given: GameEnums.BlockerRole) -> void:
	_role = given

## The role the day placed this for (`give_role()`; `GameEnums.BlockerRole.NONE` until one is
## given): the telemetry map colours a plan by it, `keeps_its_field_clear()` asks it, and
## `EventScheduler.owed_to_her_walk()` copies it onto the plan it makes.
func role() -> GameEnums.BlockerRole:
	return _role


## **How far from this event a point has to be to stand clear of it**, for a figure `her_reach`
## across: its body and her whole shape, the field it carries where it carries one (a car
## crash's, there to stop her walking past it), and a hard fail's lethal reach and her shape;
## 0 for an event that neither stands in the way nor ends the day. What the park cordon's last
## gap is kept clear of (`ParkCordon._clear_of_the_day()`).
func clearance(her_reach: float) -> float:
	if _def.obstructs_within() <= 0.0 and not _def.ends_the_day():
		return 0.0
	var reach := _def.obstructs_within() + her_reach
	if _def.has_a_field():
		reach = maxf(reach, _def.field_reach())
	if _def.ends_the_day():
		reach = maxf(reach, _def.lethal_reach() + her_reach)
	return reach

## Where this event stands now: its instance's position while it is in the world, where it stands
## as placed otherwise (`body_at()`).
func where_it_stands_now() -> Vector2:
	return _standing.at() if _standing.is_there() else body_at()

## Whether this event's field touches `rect` at all: grown by `field_reach()` rather than
## `outer_radius` alone, so a segment's own `half_length` is not dropped from the streaming
## question the way it would be from a disc's.
func reaches(rect: Rect2) -> bool:
	var grown := rect.grow(_def.field_reach())
	if grown.has_point(body_at()):
		return true
	for point in _path:
		if grown.has_point(point):
			return true
	return false

## **Whether this event spoils the calm `ground`** (world space): placed, and its field
## reaching it. The one statement of the spoil rule; `DayEvents` asks it once per row and
## calm area.
##
## **An `AMBIENT` row does not spoil.** A playground is a permanent feature of the map, not
## something that went wrong today: it makes a park *contested*, which is the point, and it
## leaves the far side of the block calm. Counting it would strip a playground out of one
## park every day.
##
## **Nor does a permanent body.** A scar is world history for the same reason: stripping it
## would make a burnt-out building that has stood on that corner since day 3 vanish for one
## day and come back the next.
func spoils(ground: Rect2) -> bool:
	if _def.is_ambient() or not is_placed() or _permanent:
		return false
	return reaches(ground)

## **Whether this event blocks the way**: placed, not a region door's body (`is_door()`), and
## either a body she cannot pass (`obstructs_radius`) or a hard fail. An abduction in progress is
## not something she walks through to reach the park behind it; a door is a crossing she walks
## through. What the day's reach (`DayReach`) stands as discs (`blocking_radius()`).
func obstructs() -> bool:
	return is_placed() and not _is_door and (_def.obstructs_within() > 0.0 or _def.ends_the_day())

## The disc this event blocks the way with: its body's radius, or a hard fail's inner radius
## when that is wider.
func blocking_radius() -> float:
	return maxf(_def.obstructs_within(), _def.core_within() if _def.ends_the_day() else 0.0)

## The points that bound this event — the corners of its route, or the one place it stands.
func ends() -> PackedVector2Array:
	return _path if _path.size() >= 2 else PackedVector2Array([body_at()])

## Distance from a point to the nearest part of this event — the point it stands at, or the
## nearest point of the route it will travel. A fire engine two streets away that is going
## to come down *this* one has to be in the world before it sets off, or its whole telegraph
## is spent somewhere nobody could see it.
func distance_from(at: Vector2) -> float:
	if not is_placed():
		return INF
	if _path.size() < 2:
		return body_at().distance_to(at)
	var best := INF
	for i in range(1, _path.size()):
		best = minf(best, at.distance_to(
				Geometry2D.get_closest_point_to_segment(at, _path[i - 1], _path[i])))
	return best

## **How far she is from this plan for the streaming's sake**, `INF` for a plan streaming does not look
## at: one that is spent or not placed. It measures from where the plan was placed (`placed_at()`) for a
## plan that stands at one point, and to the nearest point of its route for one that walks, the number
## `distance_from()` answers for a route. **It is not `distance_from()` for a point plan**, which
## measures from where its body stands (`body_at()`, the kerb for a row that stands at its kerb): a
## streaming radius is a reach round where the day put the row, not round its body. Asked as one call
## because streaming puts the question to every plan of the walk on every physics tick: it is the one
## question the loop puts to a plan (`EventStreaming.stream_around()`).
func streaming_distance_from(at: Vector2) -> float:
	if _spent or _position == Vector2.INF:
		return INF
	return _position.distance_to(at) if _path.size() < 2 else distance_from(at)

## The closest endpoint-to-route distance between two events.
##
## Two routes are measured from both sides so either route's closest endpoint can decide the gap.
## Crossing interiors are not detected; the answer is the nearest waypoint-to-route distance.
func gap_to(other: EventPlan) -> float:
	# A point's distance to the whole other route already includes its endpoints, so the symmetric
	# endpoint pass cannot make the answer smaller when either side is stationary.
	if _path.size() < 2:
		return other.distance_from(body_at())
	if other._path.size() < 2:
		return distance_from(other.body_at())
	var gap := INF
	for point in ends():
		gap = minf(gap, other.distance_from(point))
	for point in other.ends():
		gap = minf(gap, distance_from(point))
	return gap

## Whether a row is one the **zero-cost line** has to get past — the reading PLAYTEST-71 settled,
## stated once here and read by every rule in this section.
##
## A line along a route is a walk from the doorstep to the calm that never enters a placed row's
## reach. Five kinds of row are outside it, and each is outside for its own reason rather than for
## convenience:
##
## - **a mast** (a `loudspeaker` plan, whether `MastSites` planted it or it is queued or routed) is
##   a fixture of the street it stands on: the six fixed ones are planted once by `MastSites`, off
##   the corridor-aware placement every other row here goes through, and stand at the same sites all
##   fourteen days. The two day 11 adds, the one queued near the mark and the one a rigged bag puts
##   on her route, are exempt too (inbox #684 in coral-lark, "Exempt like fixed masts"), because a mast's field
##   reaches the junction box at the end of whatever street it stands on, so held to the line it
##   would have almost no place on a route tree. A mast is asked none of the rules that keep a line
##   along her routes (`RouteLineRule`, `RouteSidewalkRule._leaves_the_routes_sidewalk_open`,
##   `PacingOpeningRule._leaves_a_pacing_beats_opening` and the cost half of `RouteGroundRule`). What every mast keeps is its site check (`MastSites.is_eligible()`: off the home
##   street and a calm interior), door clearance, the unused calm, spacing and a way out.
## - **`Role.SCENERY`** (`pigeon_flock`) is free already — *"flocks are basically free already, don't
##   count it as block, just count is scenery"* — which is the same exemption `EventScheduler.role_for` makes.
## - **a pursuer** follows her rather than sitting on a tile, and pays the telegraph contract
##   instead; so does anything the director sites (`AHEAD_OF_PLAYER`, `TOWARD_PLAYER`), which
##   reaches here as a plan with no position at all.
## - **a region door** costs by design — *"it costs by design"* — so a door's bodies (`is_door()`:
##   its huts and gate, or an alley door's posts) are never a block. The region wall's own body is
##   not a door and still counts.
## - **a mobile row that does not pace** is passed by crossing, waiting and crossing back — *"the
##   player can cross the street, wait, then come back without ever getting excited by it"*. A row
##   that **paces** is not mobile in that sense: it comes back, so it is read over its beat.
##
## **A wall is not outside it**, and that is the player's own decision on the one thing the four
## rules left open: *"option 2 is valid only if the influence at a junction is low enough that it
## can be taken without having to worry or plan around it."* A wall bounds the corridor — `RowGround._times_for_role()`
## offers it zero copies of any ground a route runs along, so it never stands on a route — but its
## field reaches in from the far sidewalk or one street out, and being told to walk a corridor whose crossings are covered by what is
## bounding it is being told to pay for the guidance. So a wall's own charging disc is asked the
## same three questions every other row's is, and the condition the player set on that is exactly
## `EventDef.line_reach()`: what a wall may still put over a junction is the part of its field under the
## walking decay, which is a crossing the walk takes without planning around it.
##
## The lethal-clearance rule's wall exemption is a different rule about a different thing and is
## untouched — `EventPlan.keeps_its_field_clear()` is about keeping other events out of a lethal field, not
## about whether a line exists past one.
func counts_against_the_line() -> bool:
	return is_placed() and not _is_door and _mast_id == "" and not _def.is_a_mast() \
			and _def.has_a_line_to_avoid()

## Whether a row denies a point, under the beat-opening reading.
##
## **A pacing row denies only the ground its beat never leaves free** — *"time pass, don't route
## around them"* — so a point it is ever more than its reach away from can be walked past by
## waiting. The intersection over a whole beat is the intersection over its **corners**, and that
## is exact rather than a sample: a disc is convex, so a point within `reach` of both ends of a
## straight run is within `reach` of every point of it.
func denies(at: Vector2, reach: float) -> bool:
	if walks_a_beat():
		for point in _path:
			if at.distance_to(point) > reach:
				return false
		return true
	return at.distance_to(body_at()) <= reach

## **Whether this plan walks a beat**: its row paces (`EventDef.paces_a_beat()`) and a beat is laid, so what
## it denies is the ground the beat never leaves free (`denies()`), and the street it paces is one
## the line rule lets her pass him on by its far sidewalk (`RouteLineRule`).
func walks_a_beat() -> bool:
	return _def.paces_a_beat() and _path.size() >= 2

## Whether a row's own reach gets anywhere near a rect at all — the cheap filter before the tile
## work. Grown by the line reading's plain disc rather than `field_reach()`, and asked of every
## corner of a beat as well as of where the row stands, since a pacing row's denied ground is
## inside each of those discs.
func reach_touches(rect: Rect2, reach: float) -> bool:
	var grown := rect.grow(reach)
	if grown.has_point(body_at()):
		return true
	for point in _path:
		if grown.has_point(point):
			return true
	return false

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
## `RowGround._times_for_role()` offers a wall zero copies of any tile a route actually runs along, so a placement
## carrying this role is off the routes or it does not exist — including the far sidewalk of a
## route's own street, which is ground no route walks. What keeps its clearance is everything else: a
## set piece, which is sited on her way, and anything the day placed for a reason that is not about
## the corridor at all.
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
## name: `EventScheduler.role_for` gives any placed `hard_fail` row that is not a `ONE_SHOT` the `WALL` role
## before it ever asks whether the row pursues, so `alley_robbery` (placed, `hard_fail`, therefore
## always `WALL`) and `charging_dog` past `Tuning.RUN_TAUGHT_DAY` (`spawn_mode_on()` answers `MAP`
## from there, placed and `hard_fail` the same way) are both exempt without this line doing
## anything. On `RUN_TAUGHT_DAY` itself `charging_dog` is never placed at all — it is
## `AHEAD_OF_PLAYER`, sited by the director with no tile the scheduler ever reasons about — which is
## the other way a pursuer reaches this exemption. Stating it over `pursues()` (its row's `pursuit`) rather than
## leaving the exemption to follow from the `WALL` classification is what makes it survive a future
## pursuer the role logic does not happen to route through `WALL` — a lethal `SET_PIECE` pursuer,
## say, which `EventScheduler.role_for` would classify ahead of the `hard_fail` check.
func keeps_its_field_clear() -> bool:
	return _def.ends_the_day() and _role != GameEnums.BlockerRole.WALL and not _def.pursues()

# ----------------------------------------------------- what a caller asks ---
# The questions a caller outside the events asks a plan, answered for its row where the
# question is the row's, and what the building's plan tells one as it makes it.

## Whether its body holds a walker at its door (`EventDef.detains_her()`): the door bodies the
## crowd's walkers are held at (`Crowd`).
func detains_her() -> bool:
	return _def.detains_her()

## How far round where it stands its body stops her (`EventDef.obstructs_within()`), or 0: the
## discs a siting reads off the wall and the doors (`DayStreets.siting_region()`).
func obstructs_within() -> float:
	return _def.obstructs_within()

## Whether walking into its reach ends her day (`EventDef.ends_the_day()`).
func ends_the_day() -> bool:
	return _def.ends_the_day()

## Whether its field reaches `point`: its live event's own answer (`EventInstance.field_reaches()`,
## the field's real shape), and false while it is not in the world, where no field stands to reach
## anything. The only caller, the run log's met-events watch, asks of plans in the world alone.
func field_reaches(point: Vector2) -> bool:
	return _standing.is_there() and _standing.field_reaches(point)

## Whether it is a door's boom, solid only while lowered (`EventDef.is_a_boom()`): the door's
## line runs through it.
func is_a_boom() -> bool:
	return _def.is_a_boom()

## Whether it is a door's hut or post, armed again once she has walked away
## (`EventDef.detains_again()`): a gatehouse of its door.
func detains_again() -> bool:
	return _def.detains_again()

## Which way it is drawn facing, as its siting decided: along its street for a door's
## bodies, so a door's line is read off them.
func faces() -> Vector2:
	return _facing

## Which way it faces now: its live event's facing while it is in the world
## (`EventInstance.facing_now()`), the way its siting decided (`faces()`) otherwise.
func faces_now() -> Vector2:
	return _standing.facing() if _standing.is_there() else _facing

## Whether its live event is in the world and over (`EventInstance.is_gone()`), in the moment
## before streaming takes it off this plan; false while it is not in the world.
func its_event_is_gone() -> bool:
	return _standing.is_there() and _standing.is_gone()

## Whether its body is one the map records for the whole day (`EventDef.stands_as_a_fixed_body()`):
## standing, solid, and no door's.
func stands_as_a_fixed_body() -> bool:
	return _def.stands_as_a_fixed_body()

## The pieces its body is made of, in the scene's own frame (`EventDef.body_pieces()`).
func body_pieces() -> Array[EventDef.SolidPart]:
	return _def.body_pieces()

## Its row's ground shape (`EventDef.ground_shape()`), or null for a row with no picture.
func ground_shape() -> GroundShape:
	return _def.ground_shape()

## How far round its centre its body stops her (`EventDef.solid_reach()`).
func solid_reach() -> float:
	return _def.solid_reach()

## Whether its row is a permanent feature of a fixed map (`EventDef.is_ambient()`), which never
## appears: the dev rig's `--spawn event` passes over it.
func is_ambient() -> bool:
	return _def.is_ambient()

## Whether its row paces a beat (`EventDef.paces_a_beat()`), whether or not a beat is laid
## (`walks_a_beat()`).
func paces_a_beat() -> bool:
	return _def.paces_a_beat()

## Whether its row comes after her (`EventDef.pursues()`), however its chase starts.
func pursues() -> bool:
	return _def.pursues()

## How close she comes before it notices her (`EventDef.notice_within()`), or 0 for a row that does
## not wait for her.
func notice_within() -> float:
	return _def.notice_within()

## How far from its centre its row is heard (`EventDef.heard_within()`): its field's outer edge as a
## disc, the distance the dev rig stands her off it by.
func heard_within() -> float:
	return _def.heard_within()

## How far from its centre her own centre has to come for a hold of its to begin
## (`EventDef.detain_distance()`): a door's hut or post takes her in from there.
func detain_distance() -> float:
	return _def.detain_distance()

## Makes it the boom of a street door, drawn raised or lowered from `shared`, the state the region's
## doors are made with (`gate()`). Called by `RegionPlanner._add_door_bodies()` as it makes the
## door's boom, and by nothing else.
func stand_as_the_boom_of(shared: GateState) -> void:
	_gate_state = shared

## The boom's shared state for a street door's boom, which the region's doors are
## made with, or null for every other plan.
func gate() -> GateState:
	return _gate_state

## How long its row's telegraph lasts, in seconds (`EventDef.telegraphs_for()`).
func telegraphs_for() -> float:
	return _def.telegraphs_for()

## Makes it a loudspeaker mast's own plan, known by `id` (`mast_id()`): what the day's task, its red
## arrow and the blackout find a mast by. A scene recipe's runtime calls it for each mast it stands.
func stand_as_a_mast(id: String) -> void:
	_mast_id = id

## The id of the mast this is the plan of (`stand_as_a_mast()`), `""` for every other plan.
func mast_id() -> String:
	return _mast_id

## Which `EventDef.SpawnMode` its row is sited in on `day` (`EventDef.spawn_mode_on()`).
func spawn_mode_on(day: int) -> EventDef.SpawnMode:
	return _def.spawn_mode_on(day)

## Whether the director sends its row ahead of her on an ordinary day (`EventDef.is_sent_ahead()`).
func is_sent_ahead() -> bool:
	return _def.is_sent_ahead()

## Whether its row is a one-shot, a set piece a day owes once (`EventDef.is_a_one_shot()`).
func is_a_one_shot() -> bool:
	return _def.is_a_one_shot()

## The id of the row its live event calls in once it is first seen (`EventDef.calls_in()`), or ""
## for a row that calls none: the burning building's entering fire engine.
func calls_in() -> String:
	return _def.calls_in()

## How far round where it stands its field reaches, the stretch a siting keeps clear of the
## fields of others (`EventDef.field_reach()`).
func field_reach() -> float:
	return _def.field_reach()

## How far round where it stands a route's line is kept clear of it (`EventDef.line_reach()`).
func line_reach() -> float:
	return _def.line_reach()

## Whether it takes a whole section of its street when it is placed (`EventDef.spans_the_street()`).
func spans_the_street() -> bool:
	return _def.spans_the_street()

## Whether the dawn hands it to her walk, to be sited on her way with no position
## (`EventDef.is_handed_to_her_walk()`).
func is_handed_to_her_walk() -> bool:
	return _def.is_handed_to_her_walk()

## Whether her walk places it rather than the dawn or a unit's draw (`EventDef.is_sited_from_her_walk()`).
func is_sited_from_her_walk() -> bool:
	return _def.is_sited_from_her_walk()

## Whether it is a set piece sited on her way (`EventDef.is_a_set_piece_on_her_way()`).
func is_a_set_piece_on_her_way() -> bool:
	return _def.is_a_set_piece_on_her_way()

## Whether her walk stands it at a building's front (`EventDef.stands_at_a_front()`).
func stands_at_a_front() -> bool:
	return _def.stands_at_a_front()

## Whether its row is a loudspeaker mast (`EventDef.is_a_mast()`).
func is_a_mast() -> bool:
	return _def.is_a_mast()

## Whether it is a loudspeaker mast still speaking today: a mast's own plan (`mast_id()`, of a row
## that is a mast) that nothing has silenced (`silence()`).
func is_a_live_mast() -> bool:
	return _mast_id != "" and _def.is_a_mast() and not _silenced

## Silences it for the rest of the day, so a mast silenced while out of reach is still silent the
## next time she comes near it.
func silence() -> void:
	_silenced = true

## Whether something has silenced it today (`silence()`).
func is_silenced() -> bool:
	return _silenced

## Makes it a feature the run left here, which the day may not tidy away: a scar.
func make_permanent() -> void:
	_permanent = true

## Makes it come again `seconds` after each of its instances came, on its own clock
## (`comes_again_every()`), in place of its row's: each of the building's vents has its own period.
func come_again_every(seconds: float) -> void:
	_repeat_every = seconds

## Seconds from one of its instances coming to the next, on its own clock: its row's
## (`EventDef.comes_again_every()`) unless a placement gave it its own (`come_again_every()`). 0 for
## a plan that does not come again on a clock.
func comes_again_every() -> float:
	return _repeat_every

## Seconds from one of its instances being done to the next coming (`EventDef.comes_again_after()`),
## 0 for a plan that does not wait on its last instance.
func comes_again_after() -> float:
	return _repeat_after

## Makes its first instance come `seconds` from the start (`first_comes_in()`), so plans that come
## again on clocks of their own start out of step: the building's vents, its explosions.
func come_first_in(seconds: float) -> void:
	_first_comes_in = seconds

## Seconds from the start of the walk to its first instance coming (`come_first_in()`), 0 for a plan
## whose instance may be in the world at once.
func first_comes_in() -> float:
	return _first_comes_in

## Makes each of its instances come where she stands rather than where it was placed
## (`comes_where_she_stands()`): the explosion outside, whose charge is wherever in the building she
## has got to.
func come_where_she_stands() -> void:
	_at_her = true

## Whether each of its instances comes where she stands rather than where it was placed
## (`come_where_she_stands()`).
func comes_where_she_stands() -> bool:
	return _at_her

## Makes each of its instances arrive `seconds` into its life (`arrives_aged()`), its first
## included: the explosion outside, whose notice is already over when it comes.
func arrive_aged(seconds: float) -> void:
	_arrives_aged = seconds
	_saved = EventSave.aged(seconds)

## The age each of its instances arrives at (`arrive_aged()`): 0 for one that comes and gives its
## notice.
func arrives_aged() -> float:
	return _arrives_aged

## What its instance was in the middle of when it was last streamed out (`leave_the_world()`).
func saved() -> EventSave:
	return _saved

## **Tells the plan its instance has left the world** carrying `save`: back to nowhere, the save
## kept for when it comes back. Streaming says it as it takes the instance away, and as it lets go
## of a finished one (`EventStreaming`).
func leave_the_world(save: EventSave) -> void:
	_standing = WhereItStands.nowhere()
	_saved = save
