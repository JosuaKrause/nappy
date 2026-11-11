class_name EventPlan
extends RefCounted
## What the manager needs to spawn one instance.
##
## An `AHEAD_OF_PLAYER` plan has **no position**: the day decides that one more cat is owed and
## the director decides where, later, out of where the player turns out to walk. `is_placed()`
## is the question everything that reasons about geometry has to ask first.

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

## `MastSites.Site.id` for a mast's own plan (its ordinary broadcast and, on
## `EventScheduler.CURFEW_ANNOUNCE_DAY`, its curfew announcement too), `""` for everything else — the
## question `EventManager.silence_mast()` and the broadcast clock's own sync ask before
## touching a plan.
var mast_id := ""
## Set by `EventManager.silence_mast()`/`silence_all_masts()` for the rest of the day. Carried
## on the plan, not only the live instance, so a mast silenced while out of reach is still
## silenced the next time she comes near it — see `EventStreaming.stream_in()`.
var silenced := false

## **A plan that comes again** (`repeats()`): seconds from one of its instances coming to the
## next, kept on its own clock, and seconds from one being done to the next coming
## (`EventDef.repeat_every`, `repeat_after`, the row's unless a placement gives this plan its own,
## as each of the building's vents has its own period). `EventManager` keeps the clock.
var repeat_every := 0.0
var repeat_after := 0.0
## Seconds until this plan's instance next comes; nothing streams it in before then. 0 for a plan
## whose instance may be in the world now, which is every plan that does not repeat.
var comes_in := 0.0
## Whether this plan's instance is put where she stands each time it comes, rather than at
## `position` — the explosion outside, whose charge stands where she is wherever in the building
## she has got to. Its `position` is where it last came.
var at_her := false
## The age each of its instances arrives at: 0 for one that comes and gives its notice, the
## row's `telegraph_time` for one whose notice is already over when it comes (the explosion
## outside: what the windows say is that it has already happened).
var arrives_aged := 0.0
## Set the frame a wait on its last instance begins, so that frame is not counted off the wait.
var wait_began := false

func _init(definition: EventDef, at: Vector2,
		route := PackedVector2Array()) -> void:
	def = definition
	position = at
	path = route
	if definition:
		repeat_every = definition.repeat_every
		repeat_after = definition.repeat_after

## Whether this plan's instance comes again once it is done (`repeat_every`, `repeat_after`).
func repeats() -> bool:
	return repeat_every > 0.0 or repeat_after > 0.0

## The live instance, while this plan is streamed in. Owned by `EventManager`: a plan is the
## day's intention and the instance is the few seconds it exists for, and those are not the
## same span of time.
var live: EventInstance = null
## True once the event has run its course, so walking back past it does not start it again.
var spent := false
## True for something the *run* left here rather than something today rolled — a burnt-out
## shell, a barricade. It is world history and the day may not tidy it away.
var permanent := false
## True once something that rides this plan's instance asked for it to stay in the world for
## the rest of the day wherever she walks (`EventManager.keep_live()`), so streaming never takes
## it away from under what rides it.
var kept_live := false
## What the day placed this **for**, against today's corridor. See `GameEnums.BlockerRole` and
## `EventScheduler.role_for`.
##
## It is recorded rather than re-derived because it is not a function of the def: the same
## `cyclist` row is a wall on a day it is rolled and nothing at all when the director sites one
## in front of her, and the telemetry map has to be able to say which. Nothing in the game reads
## it — it decides where the plan went, it does not decide anything afterwards.
var role := GameEnums.BlockerRole.NONE
## True once it has been in the world at least once. What it is *for* is the bookkeeping
## that must happen exactly once however many times an event is streamed in and out: a
## burnt-out shell records the fire that made it the first time it is seen and never again.
var was_live := false
## How far the instance had got when it was last streamed out, so streaming it back in
## **resumes** it rather than rewinding it. See `EventStreaming.stream_in`.
var age := 0.0
var travelled := 0.0
## Where on its clock an instance with an `EventDef.notice` had noticed her when it was last
## streamed out (`EventInstance.noticed_at()`), or `INF` if it had not yet noticed her — the
## third thing a stream-out has to carry beside `age` and `travelled`, or a row streamed out
## mid-chase comes back `is_waiting()`, having forgotten it. See
## `EventStreaming.stream_out()` and `stream_in()`, and `EventInstance.resume()`.
var noticed_at := INF
## Each behaviour's own state when it was last streamed out (`EventInstance.save_behaviours()`),
## empty before then and once a repeating plan starts over: a roadblock's spent guard and the post
## he left among it (`EventBarrierPost.save()`), so a re-streamed barrier is only the barrier.
var behaviours := {}

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
	return position != Vector2.INF

## True once the event has run its course (`spent`), so walking back past it does not start it
## again.
func is_spent() -> bool:
	return spent

## Spends this plan for the rest of the day (`is_spent()`): it is not streamed in again.
func spend() -> void:
	spent = true

## The id of the row this plan places (`EventDef.id`).
func row_id() -> String:
	return def.id

## Where the day placed this plan, `Vector2.INF` while it is unsited (`is_placed()`). Its instance
## may have moved since: `where_it_stands_now()` answers where it is.
func placed_at() -> Vector2:
	return position

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

## Whether this plan's instance is in the world now (`live`).
func is_in_the_world() -> bool:
	return live != null

## This plan's instance while it is in the world, null otherwise: the node the streaming made of it
## (`EventStreaming.stream_in()`), which knows it as the live event it is.
func instance() -> Node2D:
	return live

## Keeps this plan's instance in the world for the rest of the day, wherever she walks: the
## streaming never takes it out (`kept_live`).
func keep_in_the_world() -> void:
	kept_live = true

## **Whether this plan is one of the city's fixed parts rather than one of the day's events**: the
## region wall's body (`is_in_the_wall()`), a door's (`is_door()`), a seal (`stand_as_a_seal()`), a
## loudspeaker mast (`mast_id`) or an ambient row (a playground). The player's fixed parts: "the
## wall, doors, closures, seals, scars, masts and ambient rows" each "get phases during either dawn
## or beginning of the game" (inbox #1185 in gentle-owl); a closure is no plan, and the code's scar, the burnt
## shell a fire leaves, is a regular event ("your scars are just regular events", inbox #1185 in gentle-owl).
## Day 13's swap never takes the section of one (`ResistanceDirector._section_to_swap()`).
func is_a_fixed_part() -> bool:
	return _is_door or _in_the_wall or _is_a_seal or mast_id != "" \
			or def.kind == GameEnums.EventKind.AMBIENT

## Makes this body one of the day's seals. Called by `DayPlanner` for each seal it plans, and by
## nothing else.
func stand_as_a_seal() -> void:
	_is_a_seal = true

## Whether this plan stands at one point rather than moving along a route (`path`).
func stands_still() -> bool:
	return path.size() < 2

## The row this plan places: what its pictures are, asked of her view before day 13's task takes
## its section (`ResistanceDirector._place_the_roadblock_near()`), and whether it spans the street
## (`DayLocations.assign()`).
func row() -> EventDef:
	return def

## The route its body walks (`path`): a mover's beat or its run, empty for one that stands.
func walks() -> PackedVector2Array:
	return path

## Gives it the role a judge decided (`StreetInvalidation.room()`), which is where it went.
func give_role(given: GameEnums.BlockerRole) -> void:
	role = given


## **How far from this event a point has to be to stand clear of it**, for a figure `her_reach`
## across: its body and her whole shape, the field it carries where it carries one (a car
## crash's, there to stop her walking past it), and a hard fail's lethal reach and her shape;
## 0 for an event that neither stands in the way nor ends the day. What the park cordon's last
## gap is kept clear of (`ParkCordon._clear_of_the_day()`).
func clearance(her_reach: float) -> float:
	if def.obstructs_radius <= 0.0 and not def.hard_fail:
		return 0.0
	var reach := def.obstructs_radius + her_reach
	if def.has_a_field():
		reach = maxf(reach, def.field_reach())
	if def.hard_fail:
		reach = maxf(reach, def.lethal_reach() + her_reach)
	return reach

## Where this event stands now: its instance's position while it is in the world, the plan's
## own otherwise.
func where_it_stands_now() -> Vector2:
	return live.global_position if live and is_instance_valid(live) else position

## Whether this event's field touches `rect` at all: grown by `field_reach()` rather than
## `outer_radius` alone, so a segment's own `half_length` is not dropped from the streaming
## question the way it would be from a disc's.
func reaches(rect: Rect2) -> bool:
	var grown := rect.grow(def.field_reach())
	if grown.has_point(position):
		return true
	for point in path:
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
	if def.kind == GameEnums.EventKind.AMBIENT or not is_placed() or permanent:
		return false
	return reaches(ground)

## **Whether this event blocks the way**: placed, not a region door's body (`is_door()`), and
## either a body she cannot pass (`obstructs_radius`) or a hard fail. An abduction in progress is
## not something she walks through to reach the park behind it; a door is a crossing she walks
## through. What the day's reach (`DayReach`) stands as discs (`blocking_radius()`).
func obstructs() -> bool:
	return is_placed() and not _is_door and (def.obstructs_radius > 0.0 or def.hard_fail)

## The disc this event blocks the way with: its body's radius, or a hard fail's inner radius
## when that is wider.
func blocking_radius() -> float:
	return maxf(def.obstructs_radius, def.inner_radius if def.hard_fail else 0.0)

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

## The closest endpoint-to-route distance between two events.
##
## Two routes are measured from both sides so either route's closest endpoint can decide the gap.
## Crossing interiors are not detected; the answer is the nearest waypoint-to-route distance.
func gap_to(other: EventPlan) -> float:
	# A point's distance to the whole other route already includes its endpoints, so the symmetric
	# endpoint pass cannot make the answer smaller when either side is stationary.
	if path.size() < 2:
		return other.distance_from(position)
	if other.path.size() < 2:
		return distance_from(other.position)
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
##   would have almost no place on a route tree. A mast is asked none of the three rules that keep
##   a line along her routes (`RouteJunctionsRule._leaves_the_route_junctions_open`, `RouteSidewalkRule._leaves_the_routes_sidewalk_open`
##   and `PacingOpeningRule._leaves_a_pacing_beats_opening`). What every mast keeps is its site check (`MastSites.is_eligible()`: off the home
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
## can be taken without having to worry or plan around it."* A wall bounds the corridor — `EventScheduler._copies_of`
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
	return is_placed() and not _is_door and mast_id == "" and def.role != EventDef.Role.MAST \
			and def.has_a_line_to_avoid()

## Whether a row denies a point, under the beat-opening reading.
##
## **A pacing row denies only the ground its beat never leaves free** — *"time pass, don't route
## around them"* — so a point it is ever more than its reach away from can be walked past by
## waiting. The intersection over a whole beat is the intersection over its **corners**, and that
## is exact rather than a sample: a disc is convex, so a point within `reach` of both ends of a
## straight run is within `reach` of every point of it.
func denies(at: Vector2, reach: float) -> bool:
	if def.paces and path.size() >= 2:
		for point in path:
			if at.distance_to(point) > reach:
				return false
		return true
	return at.distance_to(position) <= reach

## Whether a row's own reach gets anywhere near a rect at all — the cheap filter before the tile
## work. Grown by the line reading's plain disc rather than `field_reach()`, and asked of every
## corner of a beat as well as of where the row stands, since a pacing row's denied ground is
## inside each of those discs.
func reach_touches(rect: Rect2, reach: float) -> bool:
	var grown := rect.grow(reach)
	if grown.has_point(position):
		return true
	for point in path:
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
## `EventScheduler._copies_of` offers a wall zero copies of any tile a route actually runs along, so a placement
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
## the other way a pursuer reaches this exemption. Stating it over `plan.def.pursuit` rather than
## leaving the exemption to follow from the `WALL` classification is what makes it survive a future
## pursuer the role logic does not happen to route through `WALL` — a lethal `SET_PIECE` pursuer,
## say, which `EventScheduler.role_for` would classify ahead of the `hard_fail` check.
func keeps_its_field_clear() -> bool:
	return def.hard_fail and role != GameEnums.BlockerRole.WALL and def.pursuit == null

# ----------------------------------------------------- what a caller asks ---
# The questions a caller outside the events asks a plan, answered for its row where the
# question is the row's, and what the building's plan tells one as it makes it.

## Whether its body holds a walker at its door (`EventDef.detains_her()`): the door bodies the
## crowd's walkers are held at (`Crowd`).
func detains_her() -> bool:
	return def.detains_her()

## How far round where it stands its body stops her (`EventDef.obstructs_within()`), or 0: the
## discs a siting reads off the wall and the doors (`DayStreets.siting_region()`).
func obstructs_within() -> float:
	return def.obstructs_within()

## Whether walking into its reach ends her day (`EventDef.ends_the_day()`).
func ends_the_day() -> bool:
	return def.ends_the_day()

## Whether its field reaches `point`: from where it stands now (`where_it_stands_now()`)
## against how far its row is heard (`EventDef.heard_within()`), measured from the centre as
## every caller has measured it.
func field_reaches(point: Vector2) -> bool:
	return where_it_stands_now().distance_to(point) <= def.heard_within()

## Makes it come again `seconds` after each of its instances came, on its own clock
## (`repeat_every`), in place of its row's: each of the building's vents has its own period.
func come_again_every(seconds: float) -> void:
	repeat_every = seconds

## Makes its first instance come `seconds` from the start (`comes_in`), so plans that come
## again on clocks of their own start out of step: the building's vents, its explosions.
func come_first_in(seconds: float) -> void:
	comes_in = seconds

## Makes each of its instances come where she stands rather than where it was placed
## (`at_her`): the explosion outside, whose charge is wherever in the building she has got to.
func come_where_she_stands() -> void:
	at_her = true

## Makes each of its instances arrive `seconds` into its life (`arrives_aged`), its first
## included (`age`): the explosion outside, whose notice is already over when it comes.
func arrive_aged(seconds: float) -> void:
	arrives_aged = seconds
	age = seconds
