class_name EventScheduler
extends RefCounted
## Builds one day's event set from the run seed and the day index. See docs/EVENTS.md.
##
## Deterministic: the same seed and day always produce the same plan, which is what lets a
## player learn a run. Nothing here touches the global RNG.

## The rate a source has to beat before it is counted as denying the calm ground near it —
## `EventScheduler._denial_radius`, and `EventCatalogue`'s own reasoning for the one ambient row
## that stands in a park.
##
## **Its own number rather than the calm ground's live decay, and the decoupling is the point.**
## Read off the decay, every rise in the walking rate would quietly admit louder rows beside parks:
## the pram settling faster is a statement about the pram, and *which events may stand next to a
## park* is a statement about the parks. Tying the two put the second decision inside the first,
## where nobody making it would see it.
const CALM_ZONE_DENIAL_RATE := 7.7
## The day the masts carry the curfew announcement instead of their ordinary broadcast — the day
## `_curfew_announce()` used to be `scripted_day` for, kept as a named day rather than re-read off
## the def so the two rows do not have to agree about which field means "when" any more.
const CURFEW_ANNOUNCE_DAY := 6
## How many times over a tile on the day's routes is offered to a **friction** placement.
##
## *"Benign blockers go on the route… to make it more challenging / force the player to think their
## route through better."* About a quarter of the lattice is on the tree, so at 4 rather better
## than half of the costly rows land on the corridor and the rest of the city keeps a scatter — a
## city where every street off the route is empty would read as a set rather than as a place, and
## nothing in the design asks for that.
const EVENT_CORRIDOR_WEIGHT := 4
## Candidate tiles tried per placement before taking the roomiest one that was offered. A
## fallback rather than a failure: a scripted event has to happen, and on a full map the honest
## answer is the best spot left, not no event.
const EVENT_PLACEMENT_TRIES := 24
## How many times over a precinct tile is offered to the event scheduler against an ordinary
## pavement tile. Weighting the candidates rather than adding a rule: a precinct is where the cafés
## and the market stalls and the buskers are, and the way to say that is to make the ground more
## likely rather than to give the catalogue a new field.
const EVENT_PRECINCT_WEIGHT := 4
## And nothing of any kind lands inside this of anything else, which is about two tiles: close
## enough that a café and a shouting man can share a corner, far enough that neither is drawn
## inside the other.
const EVENT_SPACING_ANY := 64.0
## Two events of the same kind never land closer than this. A block is 256px across, so this
## is "not on the same stretch of pavement" — the objection was never to seeing a second dog
## walker, it is to seeing it thirty pixels from the first, which reads as a duplicate rather
## than as a second incident.
const EVENT_SPACING_SAME := 256.0
## How many times over the street **between two adjacent strands of the day's corridor** is offered
## to a wall, against the rest of the band it is in.
##
## Two strands running down neighbouring streets with a free step between them are one wide region
## rather than two routes. `RouteTree.gaps()` is what a gap is; the placement is
## `EventScheduler._copies_of`, where this multiplies the band weight rather than replacing it.
##
## **Set to leave about half of them open, which is the instruction rather than a compromise.** What
## is asked for is *variety in what a gap is worth*, so a number that closed every gap would be as
## wrong as one that closed none: it would turn the corridor into a set of separate corridors, which
## is the star shape `RouteTree` deliberately does not grow.
##
## It is also the reason this is a weight and not the per-gap roll that reads more directly. A roll
## needs a phase, a stream, a count of its own and a share of the caps; a weight rides on the day's
## bags, spacing and per-row caps unchanged (a location's weight, `RuledLocationGround.scale()`), and
## *cannot place more than the view's empty marbles let it*.
const EVENT_WALL_GAP_WEIGHT := 6
## How many times over the **rim** is offered to a **wall** placement, against ground further out.
##
## A wall bounds the corridor, so it has to be somewhere the corridor can see; a lethal thing four
## streets away bounds nothing. That is the preference. What is not a preference is the exclusion
## beside it — the same reasoning as `ClosurePlanner.CLOSURE_WALL_BIAS`, which is this number's twin one system
## over and deliberately the same value.
##
## **The rim is two kinds of ground, not one.** A turning off the corridor is the first: one street
## out, seen from the junction where the wrong choice is made. The **far side of a route's own
## street** is the second, and it is the nearer of the two — she reads it without leaving her line,
## and a café or a stall standing there is what a street with a route down one side looks like.
## *(2026-09-19: asked whether a wall across the street should be rare or common, "often".)*
##
## **It applies to the *costly* half of the wall band only.** A very costly row is what the rim is
## for — she has strayed one turning and it is expensive — and a lethal row wants the ground beyond
## it. See `EventScheduler._copies_of` and `WALL_DEEP_WEIGHT`.
const EVENT_WALL_RIM_WEIGHT := 4
## The widest body an event may have and still be allowed to stand on calm ground.
##
## A spoiler has to make the park loud rather than take the ground away. **Refusing *anything* with
## a body is the reading to avoid**: once every stationary row is solid, a person is 18px across and
## that rule empties the pool, so nothing can be put in a park at all.
##
## So it is stated as what it means. A body you can walk around does not close a 704px lot; one you
## have to route around does. Sized to sit above a person and well under `construction`, which is
## exactly the thing it is there to keep out.
const OBSTRUCTION_A_PARK_CAN_HOLD := 16.0
## The most things the day will put in the park she used yesterday.
##
## **One spoiler is three percent of a four-block calm zone** — see `EventScheduler._denial_radius`
## for the arithmetic — so a single event does not spoil a park, it stands in one. A cap rather than
## a target: the grid asks for as many as it takes to cover the ground and this is where it stops
## asking, because the events come from the day's own pool and a park with a dozen things in it is
## not a spoiled park, it is a different kind of city.
##
## Nine is a 3x3 grid, and it is measured: over twenty lots and five seeds it denies **99%** of a
## four-block calm zone and 91% of a one-block courtyard, against 8-12% for the same lot on an
## ordinary day. A 3x2 grid leaves 15% of the biggest zones standing, which is a hundred tiles of
## usable park — enough to settle in, so the spoiling would not have happened.
##
## A small lot never asks for nine: the grid is sized from what one of them actually denies, so a
## 46-tile courtyard takes one or two and this cap is never reached. What it costs is a day with
## nine more events in it, all of them inside the one lot she is being asked not to use.
const SPOILERS_TO_DENY_A_PARK := 9
## How many times over ground two or more turnings off the corridor is offered to a **lethal** wall,
## against the rim.
##
## The ground off the paths *"ranges from very costly to deadly"*, and the range is over distance
## from the routes — so its two ends pull in opposite directions and this is the far one.
## Deliberately the same strength as the rim weight it mirrors: the design is a gradient
## rather than a preference for one band, and giving deadly a stronger pull than very costly would
## make the rim the quiet part of the off-corridor city, which inverts the sentence.
const WALL_DEEP_WEIGHT := 4
## Where the line between *friction* and a *very costly* wall falls, in points of the meter it costs
## to walk through the middle of a row.
##
## Below it a row is friction and is weighted **onto** the routes; at or above it the row is what
## closes the ground **off** them. Stated over `EventDef.walk_through_cost()` — the same integral
## the caret is ordered by — rather than over a field somebody sets per row, because a second answer
## to *how expensive is this* is how two tables of the same fact drift apart.
##
## **Setting it to a row's own `walk_through_cost()` line for the caret is the mistake with the
## good argument.** The caret's own threshold, `Tuning.EXPECTED_IMPACT_POINTS`, is a near neighbour of
## this one and is not the same question: the caret is read off a **projected position** and this
## is read off a row's own **static integral**, so the two move independently and have. It is where
## the game raises a caret — *this is worth going round* — so sharing the
## question, not merely the value, would make the cue and the placement say one sentence. What
## sharing the question did instead was empty the routes: at 25 points, the caret's line before
## this milestone raised it, **two thirds of every day becomes a wall**, and day 1's corridor drops
## from 69.6 placements to 27.8 of 113. The ground off the paths is what was asked to be closed;
## nobody asked for the paths to be cleared.
##
## The line is set by two rows instead, and by the right two. **`dog_walker` costs 42.7 and has to
## stay friction**: the dog-walker decision arriving twice on day one is the route decision this
## game is made of, and a dog walker that is never on her route is that decision deleted. **And
## `leaf_blower` at 52.9 has to stay a wall**, because without it the non-lethal half of the range
## is act III and later rows only, and *"very costly to deadly"* stops being a range anybody meets
## — `tests/test_events.gd` samples five days and counts both kinds. The line goes between them,
## same as it always has — what moved is where the two rows themselves sit.
##
## **It is in points of the meter, so it moves when the meter's own arithmetic does, and it moved
## again for a different reason than the walking decay this time.** *(2026-09-20: "restore fully
## now, raising leaf_blower by what the decay took from it and moving the line to sit between the
## two again".)* `homeless_yeller` and `dog_walker` both lost the net gain a real pass past them
## used to land once M117 raised the walking decay from 3.5 to 6.0/s, and restoring either of them
## fully pushes its own `walk_through_cost()` past where the line used to sit — the intensity a
## full restoration needs costs more than a dog walker used to, on its own numbers, before this
## row is even touched. Raising the two rows without moving the line would have made one of them a
## wall; raising the line without also raising `leaf_blower` would have let the non-lethal half of
## the range go empty again. Both moved together, `leaf_blower`'s own core answering the same
## walking-decay loss the other two rows answer, at `Tuning.EXCITEMENT_DECAY_WALKING`'s current
## rate — this reading is not itself a re-derivation for the decay's own sake, only for the two
## rows either side of it.
##
## **Raising the walking decay still lowers every row's cost unevenly**, the netting-off-over-time
## effect this line's own history already carries: that is why `protest` (269px of 15/s) fell from
## 42.3 to 27.6 and crossed under `dog_walker`'s **old** number (105px of 26/s), which no threshold
## can undo — a protest now genuinely costs less to walk through than a dog walker's old field did,
## so it is on the routes with the rest of the ordinary expensive city regardless of where this
## line sits.
##
## What that leaves on the corridor is `cafe_tables`, `market_stall`, `homeless_yeller`,
## `delivery_van`, `protest` and the dog walker, and what it puts off it is `leaf_blower`,
## `burning_building`, `pigeon_flock`, `loose_dog`, `military_convoy`, `night_raid`, `fire_truck`
## and every lethal row — the same two lists as before this line moved, checked catalogue-wide
## rather than assumed: nothing else crosses it either way. Re-measure with
## `tests/probes/m117_decay.gd` if the cost table moves; do not re-derive it.
const WALL_WORTH_OF_COST := Tuning.METER_MAX * 0.48

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

	## `MastSites.Site.id` for a mast's own plan (its ordinary broadcast and, on
	## `CURFEW_ANNOUNCE_DAY`, its curfew announcement too), `""` for everything else — the
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

	## Whether this is something the run left here rather than something today rolled
	## (`permanent`): a scar, which the day may not tidy away.
	func is_permanent() -> bool:
		return permanent

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
	func gap_to(other: Planned) -> float:
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
	##   count it as block, just count is scenery"* — which is the same exemption `role_for` makes.
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
	## can be taken without having to worry or plan around it."* A wall bounds the corridor — `_copies_of`
	## offers it zero copies of any ground a route runs along, so it never stands on a route — but its
	## field reaches in from the far sidewalk or one street out, and being told to walk a corridor whose crossings are covered by what is
	## bounding it is being told to pay for the guidance. So a wall's own charging disc is asked the
	## same three questions every other row's is, and the condition the player set on that is exactly
	## `EventDef.line_reach()`: what a wall may still put over a junction is the part of its field under the
	## walking decay, which is a crossing the walk takes without planning around it.
	##
	## The lethal-clearance rule's wall exemption is a different rule about a different thing and is
	## untouched — `Planned.keeps_its_field_clear()` is about keeping other events out of a lethal field, not
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
	## `_copies_of` offers a wall zero copies of any tile a route actually runs along, so a placement
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
	## name: `role_for` gives any placed `hard_fail` row that is not a `ONE_SHOT` the `WALL` role
	## before it ever asks whether the row pursues, so `alley_robbery` (placed, `hard_fail`, therefore
	## always `WALL`) and `charging_dog` past `Tuning.RUN_TAUGHT_DAY` (`spawn_mode_on()` answers `MAP`
	## from there, placed and `hard_fail` the same way) are both exempt without this line doing
	## anything. On `RUN_TAUGHT_DAY` itself `charging_dog` is never placed at all — it is
	## `AHEAD_OF_PLAYER`, sited by the director with no tile the scheduler ever reasons about — which is
	## the other way a pursuer reaches this exemption. Stating it over `plan.def.pursuit` rather than
	## leaving the exemption to follow from the `WALL` classification is what makes it survive a future
	## pursuer the role logic does not happen to route through `WALL` — a lethal `SET_PIECE` pursuer,
	## say, which `role_for` would classify ahead of the `hard_fail` check.
	func keeps_its_field_clear() -> bool:
		return def.hard_fail and role != GameEnums.BlockerRole.WALL and def.pursuit == null

## A line of the day's planning for the run log, written when the caller handed a trace in: the
## manager hands its own, and a test or a probe that plans a day by hand may hand none.
static func _note(trace: RunTrace, kind: String, text: String) -> void:
	if trace:
		trace.note(kind, text)

## **Plans what stands on the walk `spec` describes**: which rows, how they are drawn, and which
## placement rules apply are all the spec's (`DaySpec`, "how its events are placed"), so a day and
## the escape's city are one entry point and one judge (`_best_of()`). A day draws the catalogue
## (`DaySpec.Draw.CATALOGUE`, below); the escape's city fills each street of its walk from its marble
## bag (`DaySpec.Draw.BAG_PER_STREET`, `_draw_the_walk()`). Nothing here asks which day
## it is beyond `spec.number`, the day the catalogue's rows are read for.
##
## `consumed_one_shots` is read and appended to, so a one-shot fires once per run.
##
## `calm` is the day's calm areas (`CalmAreas`), made by the caller once the map is repainted:
## which she has settled in so far this act, most recent first (see `_spoil_the_parks_she_used`,
## and `RunCalendar.settled_this_act` for why it is an act rather than a night), and the one
## that does not count today. It is handed to every pass below and to the `DayEvents` the day is
## planned into. `route` is the walk every placement below is stated against (`RouteSource`): a
## day's tree, whose corridor (`RouteSource.corridor()`) prices and places the catalogue's rows,
## or the escape's chains, whose streets the bag fills. The caller passes the tree the closures
## were placed off; a rig with none to hand on a day grows the same tree, since
## `RouteTree.for_day` is a pure function of the city's seed and the day number and touches no
## gameplay stream.
##
## `heat` is `RunState.resistance.progress`, and it is threaded through rather than read off the
## run so that a day is a pure function of its arguments: a rig that plans day 9 twice gets the
## same day twice whatever a run happens to have done. Every def below arrives already in the shape
## that heat puts it in — see `EventCatalogue.heated()` — so nothing in this file tests for it.
## `doors` is where today's region-door bodies stand — `RegionPlanner.RegionPlan.door_bodies`'
## positions, read out by `EventManager.start_day()` before this runs. Nothing this places may put
## a field or a beat inside `Tuning.CHECKPOINT_EVENT_GAP` of one; see `DoorClearanceRule.clear_of_the_doors()`.
##
## `standing` is what obstructs the day whatever this plans: the seals and the region wall's own
## bodies, both planned before this runs, which the day's rules read with what it places
## (`StreetInvalidation`).
##
## `trace` is where the planning writes its own account for the run log — a one-shot owed to her
## walk, a lesson added, a park spoiled — and no trace writes nowhere. It changes nothing the plan holds.
##
## `beside_the_routes` is the row the roadblock phase places beside the day's routes before the dawn draw,
## so that one is close by wherever she reads the task's mark: day 13's roadblock
## (`_place_the_roadblocks()`). Null on every other day, which is then planned exactly as it would be
## without it.
##
## **Answers the plan as a `DayEvents`**, made here and written only here: every pass below is
## handed it, and the caller reads the rows (`DayEvents.placements()`) and the facts derived
## from them through it.
static func build_day(spec: DaySpec, rng: RandomNumberGenerator, map: CityMap, calm: CalmAreas,
		mast_sites: Array[MastSites.Site],
		consumed_one_shots: Array[String] = [], scars: Array[Dictionary] = [],
		route: RouteSource = null, heat: int = 0, doors := PackedVector2Array(),
		standing: Array[Planned] = [], trace: RunTrace = null,
		beside_the_routes: EventDef = null) -> DayEvents:
	var events := DayEvents.over(calm, standing)
	if spec.draw == DaySpec.Draw.BAG_PER_STREET:
		_draw_the_walk(spec, rng, map, route, _street_bag(spec.bag, street_bag_seed(rng)), events,
				calm, doors, trace)
		return events
	var day := spec.number
	# Captured before anything draws from it. Every phase below gets its own stream off this, which
	# is what makes a retried day the same day — see `_stream`.
	var base := rng.seed
	_plan_the_dawn(day, base, map, consumed_one_shots, scars, calm, route, heat, doors,
			events, mast_sites, trace, spec, beside_the_routes)
	_ensure_the_run_is_taught(day, events, heat, trace)

	# **A day whose target stands in a calm area owes her a second one** — day 12's swing, in
	# the park that is taken once she has reached it (PLAYTEST-122: "the day guarantees a second
	# open park she can reach from the swing"). Dawn keeps it by construction: the calm other than
	# `calm.besides()` is the ground the calm rule and `_calm_kept_clean()` keep clean, and the
	# day's routes, which `RouteReachRule` keeps reached, run to it.
	_count_what_is_left_uncovered(beside_the_routes, map, events, route, trace)
	return events

## `build_day` up to and including the dawn draw, added to `events`: the day's locations laid out
## (`DayLocations`, handed on with the plan, `DayEvents.use_locations()`), the ambient rows, the
## scars, the masts, the roadblock phase (`beside_the_routes`, day 13's roadblock), the scripted
## rows, the one-shots, the spoilers in a park she used, the moments she is owed and the draw of
## every location from its view's bag (`_draw_the_locations()`), each phase on its own stream off
## `base` (`_stream`). Answers the draw's own placements, in the order drawn. `spec` is the day's
## placement settings, a day's own (`DaySpec.for_day()`) where none is handed in.
static func _plan_the_dawn(day: int, base: int, map: CityMap,
		consumed_one_shots: Array[String], scars: Array[Dictionary], calm: CalmAreas,
		route: RouteSource, heat: int, doors: PackedVector2Array, events: DayEvents,
		mast_sites: Array[MastSites.Site], trace: RunTrace = null, spec: DaySpec = null,
		beside_the_routes: EventDef = null) -> Array[Planned]:
	if spec == null:
		spec = DaySpec.for_day(day)
	# Which tiles each kind of event may stand on, worked out at most once per day. See
	# `ground_for`; it is threaded through rather than kept on the map because its lifetime is
	# exactly one day and a cache with a shorter life than its invalidation rule is a bug waiting.
	var ground := {}
	# Where the day's routes run, as a question about a tile. This is what turns *wall* and
	# *friction* from words into placements — see `role_for` and `ground_for`.
	var corridor := route.corridor() if route else Corridor.of(RouteTree.for_day(map, day))

	# The calm she has not used yet, which nothing today may be placed near, where the spec
	# keeps the calm rule. See `CalmAreas.unused_ground()`.
	var leave_alone: Array[Rect2] = []
	if spec.keeps_unused_calm_clear:
		leave_alone = calm.unused_ground()
	var locations := DayLocations.lay_out(map, corridor)
	events.use_locations(locations)
	# Where home reaches among the day's bodies, worked out once and kept in step for every judge
	# below (`RouteReachRule`). The run's scars and the spoilers are asked it alone: their ground
	# is not the bags', and they keep the spacing and the line rules they always stood without,
	# but a body that cuts the routes off from home is not stood.
	var reach := RouteReachRule.new(map, corridor)

	# **The fixed parts' phases** (the design's "the city's fixed parts have phases of their own"):
	# the ambient rows and the masts stand where their planners put them, and each is recorded on
	# the location holding it, so the draw passes over it; so is each of the region wall's bodies
	# (standing, planned before the day: "a wall makes its location unavailable throughout"). A
	# seal's bodies stand at dawn as standing and the day's rules keep rows off them, but hold no
	# location: a soft seal is not held, its carriageway still walkable and a row standing on it the
	# price of that route (`docs/EVENTS.md`, the held streets), and a hard seal's street is held
	# already. The region doors' bodies are not standing: a street door's street is held, and an
	# alley door is kept clear by the doors' rule (`CHECKPOINT_EVENT_GAP`). A mast's
	# location on a day before the masts holds nothing and is drawn like any other.
	var fixed := _place_ambient(day, map, heat)
	events.add_all(fixed)
	_place_scars(day, scars, map, events, reach, heat)
	var masts := _place_masts(day, map, mast_sites, heat, doors, scars)
	events.add_all(masts)
	fixed.append_array(masts)
	for part in events.standing():
		if part.is_in_the_wall() and part.is_placed():
			fixed.append(part)
	for part in fixed:
		var tile := map.world_to_tile(part.placed_at())
		locations.hold_fixed_part(part, tile, map.tile_at(tile))
	# **One calm area stays clean by construction**: where she has settled in every area this act,
	# the one the spoilers leave alone joins the calm ground nothing may reach. See
	# `_calm_kept_clean()`.
	var kept_clean := _calm_kept_clean(calm, events) if spec.keeps_unused_calm_clear \
			else CalmAreas.NONE
	if kept_clean != CalmAreas.NONE:
		leave_alone.append(calm.ground_of(kept_clean))
	_place_the_roadblocks(beside_the_routes, day, base, map, events, ground, leave_alone,
			corridor, doors, spec, locations, trace, reach)
	# **The scripted rows' dawn phase**: each draws one of the day's open locations its ground
	# takes and is assigned it (`ScriptedPhase`), offered through the dawn draw's own path and
	# judged by the day's rules, so the draw after passes over it. The one-shots are owed to her
	# walk (`_place_one_shots()`).
	var phase_ground := RuledLocationGround.new(day, base, map, events, corridor,
			LocationFit.new(day, map, ground, corridor, spec.holds_the_home_streets),
			StreetInvalidation.new(map, corridor, ground, leave_alone, doors, false, null, reach))
	var weigh := func(def: EventDef, location: Location) -> float:
		return _weight_in(def, location, day, map, ground, corridor, spec.holds_the_home_streets)
	var phase := ScriptedPhase.new(locations, phase_ground, weigh)
	_place_scripted(day, _stream(base, 1), events, phase, heat)
	_place_one_shots(day, consumed_one_shots, events, heat, trace)
	_spoil_the_parks_she_used(day, _stream(base, 3), map, events, calm, kept_clean,
			reach, heat, trace)
	_owe_the_moments(day, _stream(base, MOMENTS_SALT), events, heat, spec.caps_per_day)
	return _draw_the_locations(day, base, map, events, ground, leave_alone, corridor, doors, spec,
			locations, heat, beside_the_routes, reach)

## **The roadblock phase at dawn** (inbox #1185 in gentle-owl: the day's routes first, then roadblocks next to
## them, then the ordinary placement): day 13's roadblocks, placed by `RoadblockPhase` in the day's
## route-adjacent sections, spread by a bias toward the section farthest from those already placed,
## until every route tile has one close by, no section still offered could bring one close by a
## route tile that has none, or `RoadblockPhase.MOST` stand (the orchestrator's reading, open to
## correction). `def` is the task's
## row, null on every other day, which this leaves exactly as it was.
##
## **The phase places into the day's locations** (`locations`, laid out by `_plan_the_dawn()`
## off `corridor` every day), before the dawn draw fills the rest (`_draw_the_locations()`).
##
## **What a section is offered, and what close by is, are the day's**: `RuledRoadblockGround`
## stands the roadblock where it fits in the section and asks today's placement rules of it
## (`StreetInvalidation`), never on the main road (inbox #1186 in gentle-owl); close by is the walk her paths take from
## the ground she touches it from without leaving the circle of `TASK_ROW_CLOSE_BY` round it
## (`DayReach.paths_over()`), the widest the task searches (`ResistanceDirector.ROADBLOCK_WIDER_REACH`).
##
## **What it does not promise.** Close by is measured over the ground as it stands when this runs:
## the scripted rows, the one-shots, the spoilers and the dawn draw after it shut more.
## `_count_what_is_left_uncovered()` writes to the run log how many route tiles have
## none as the day finally stands.
##
## **Outside the bags and on a stream of its own** (`RoadblockPhase.SALT`): the dawn draw after it
## draws the day's other rows, the roadblock holding no marble in it, spaced against these as against
## anything already down, and never over one.
static func _place_the_roadblocks(def: EventDef, day: int, base: int, map: CityMap,
		events: DayEvents, ground: Dictionary, leave_alone: Array[Rect2], corridor: Corridor,
		doors: PackedVector2Array, spec: DaySpec, locations: DayLocations, trace: RunTrace,
		reach: RouteReachRule = null) -> void:
	if def == null:
		return
	def = def.for_day(day)
	var judged := RuledRoadblockGround.new(def, day, map, events, ground, corridor,
			StreetInvalidation.new(map, corridor, ground, leave_alone, doors,
					spec.one_notice_at_a_time, null, reach),
			spec.holds_the_home_streets)
	var phase := RoadblockPhase.new(locations, judged)
	var placed: Array[String] = []
	for plan in phase.place(_stream(base, RoadblockPhase.SALT)):
		placed.append(RunTrace.tile(map.world_to_tile(plan.placed_at())))
	_note(trace, "plan", ("%d %s placed beside the day's routes, at %s; %d route tiles left with " +
			"none close by, the phase done")
			% [placed.size(), def.id, " ".join(placed) if not placed.is_empty() else "none",
			phase.left_uncovered()])

## **Whether `section` is on the main road**, where nothing that closes a street stands outside the
## escape (inbox #1186 in gentle-owl): neither a roadblock the phase places nor one day 13's task swaps in.
static func _is_on_the_main_road(map: CityMap, section: Location) -> bool:
	var segment := section.segment()
	return map.is_main_road(not segment.horizontal, segment.a.x)

## **`def`, an event that spans the street, standing across `section`**: on the carriageway tile of
## the section nearest its middle, built as any placement is (`build_placement()`), or null where the
## section is on the main road (`_is_on_the_main_road()`) or has no carriageway. Nothing is judged:
## day 13's task replaces the section's whole content with it, a route-adjacent section being valid
## ground under the route-adjacent rules already (inbox #1185 in gentle-owl); what the section held is spent by
## the caller (`EventStreaming.swap_section()`).
static func across_the_section(def: EventDef, map: CityMap, section: Location,
		rng: RandomNumberGenerator) -> Planned:
	if _is_on_the_main_road(map, section):
		return null
	var tiles := section.tiles()
	var middle := map.world_to_tile(section.centre())
	var best := Vector2i(-1, -1)
	for y in range(tiles.position.y, tiles.end.y):
		for x in range(tiles.position.x, tiles.end.x):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.ROAD:
				continue
			if best == Vector2i(-1, -1) \
					or (tile - middle).length_squared() < (best - middle).length_squared():
				best = tile
	if best == Vector2i(-1, -1):
		return null
	return build_placement(def, map, best, rng)

## **The day's ground as the roadblock phase asks it** (`RoadblockGround`): the route tiles, a
## section's roadblock left out where the day's rules invalidate it, and close by along her paths.
##
## - **The route tiles** are every walkable tile a route runs along (`Corridor.carries_a_route()`)
##   that nothing already standing shuts (`DayReach.shut_by()`).
## - **A section's roadblock** stands where it fits inside the section: on the tile of the row's own
##   ground for its role (`ground_for()`: off every tile a route runs along, off a held or closed
##   street, the home block, a tree) nearest the section's middle that the day's rules
##   (`StreetInvalidation`) refuse nothing, asked against the day's plans and what stands
##   (`DayEvents.standing()`). A section with no such tile is offered none, and none is ever offered
##   on the main road (inbox #1186 in gentle-owl). **Every rule invalidates here, the spacing between two of a row
##   included**: a tile with
##   another roadblock within `EVENT_SPACING_SAME` (256px), the one rule that bends elsewhere, is
##   not offered, so construction keeps the day's roadblocks apart and the phase's bias ranks what is
##   left. *Read as, the orchestrator's and open to correction:* which events make others invalid is
##   "what your current rules accomplish. the same applies still" (inbox #1185 in gentle-owl), and the spacing is
##   one of those rules.
## - **Close by** is the walk her paths take, without leaving the circle of `TASK_ROW_CLOSE_BY` round
##   it, from the ground she touches it from (`_touched_from()`), with its own body standing.
class RuledRoadblockGround extends RoadblockGround:
	var _def: EventDef
	var _role := GameEnums.BlockerRole.NONE
	var _map: CityMap
	var _events: DayEvents
	var _corridor: Corridor
	var _rules: StreetInvalidation
	var _own := {}
	var _shut := {}

	func _init(def: EventDef, day: int, map: CityMap, events: DayEvents, ground: Dictionary,
			corridor: Corridor, rules: StreetInvalidation, holds_the_home_streets: bool) -> void:
		_def = def
		_role = EventScheduler.role_for(def, day)
		_map = map
		_events = events
		_corridor = corridor
		_rules = rules
		for tile in EventScheduler.ground_for(def, map, ground, corridor, _role,
				holds_the_home_streets):
			_own[tile] = true
		var down := events.placements().duplicate()
		down.append_array(events.standing())
		_shut = DayReach.shut_by(map, down)

	## Two of the row's fields and a street: the farthest a rule asks of two rows together reaches.
	##
	## Overrides RoadblockGround.reoffer_within.
	func reoffer_within() -> float:
		return 2.0 * maxf(_def.field_reach(), EventScheduler.EVENT_SPACING_ANY) \
				+ (Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH) * Tuning.TILE_SIZE

	## Overrides RoadblockGround.route_tiles.
	func route_tiles() -> Array[Vector2i]:
		var found: Array[Vector2i] = []
		for y in _map.size.y:
			for x in _map.size.x:
				var tile := Vector2i(x, y)
				if _corridor.carries_a_route(tile) and _map.is_walkable(tile) \
						and not _shut.has(tile):
					found.append(tile)
		return found

	## Overrides RoadblockGround.offer.
	func offer(section: Location) -> EventScheduler.Planned:
		if EventScheduler._is_on_the_main_road(_map, section):
			return null
		var tiles := section.tiles()
		var middle := _map.world_to_tile(section.centre())
		var fits: Array[Vector2i] = []
		for y in range(tiles.position.y, tiles.end.y):
			for x in range(tiles.position.x, tiles.end.x):
				if _own.has(Vector2i(x, y)):
					fits.append(Vector2i(x, y))
		fits.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var da := (a - middle).length_squared()
			var db := (b - middle).length_squared()
			return da < db or (da == db and (a.y < b.y or (a.y == b.y and a.x < b.x))))
		var already := _events.placements()
		var reach_context := already.duplicate()
		reach_context.append_array(_events.standing())
		for tile in fits:
			var candidate := EventScheduler.build_placement(_def, _map, tile,
					RandomNumberGenerator.new())
			# `INF` alone: room all round, so the spacing between two of a row
			# (`EVENT_SPACING_SAME`) leaves a tile invalid rather than merely cramped.
			if candidate and _rules.room(candidate, _role, tile, already, reach_context) == INF:
				return candidate
		return null

	## Overrides RoadblockGround.covers.
	func covers(plan: EventScheduler.Planned) -> Array[Vector2i]:
		var shut := _shut.duplicate()
		EventScheduler.block_a_disc(_map, shut, plan.placed_at(), plan.blocking_radius())
		var found: Array[Vector2i] = []
		for tile: Vector2i in DayReach.paths_over(_map, shut,
				EventScheduler._touched_from(_map, shut, plan), plan.placed_at(),
				EventScheduler.TASK_ROW_CLOSE_BY):
			found.append(tile)
		return found

	## Overrides RoadblockGround.stand.
	func stand(plan: EventScheduler.Planned) -> void:
		_events.add(plan)
		EventScheduler.block_a_disc(_map, _shut, plan.placed_at(), plan.blocking_radius())

## **How many of the day's route tiles have none of `def`'s rows close by as the day stands**,
## written to the run log: once every pass is done, each placed `def` the day stands
## (not a region door's body or the wall's own) is read as close by every route tile its paths
## reach within `TASK_ROW_CLOSE_BY` over the day's whole obstruction (`DayReach.shut_by()`), and the
## route tiles it leaves are counted. The roadblock phase (`_place_the_roadblocks()`) aims at none,
## but a route tile no section within reach took one for and ground the later passes shut both
## leave some. A
## count and nothing more: nothing is placed or moved here. Nothing on a day with no `def`.
static func _count_what_is_left_uncovered(def: EventDef, map: CityMap, events: DayEvents,
		route: RouteSource, trace: RunTrace) -> void:
	if def == null or trace == null or route == null:
		return
	var corridor := route.corridor()
	var down := events.placements().duplicate()
	down.append_array(events.standing())
	var shut := DayReach.shut_by(map, down)
	var covered := {}
	for plan in down:
		if plan.row_id() != def.id or not plan.is_placed() or plan.is_door() \
				or plan.is_in_the_wall():
			continue
		for reached: Vector2i in DayReach.paths_over(map, shut, _touched_from(map, shut, plan),
				plan.placed_at(), TASK_ROW_CLOSE_BY):
			covered[reached] = true
	var tiles := 0
	var left := 0
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if not corridor.carries_a_route(tile) or not map.is_walkable(tile) or shut.has(tile):
				continue
			tiles += 1
			if not covered.has(tile):
				left += 1
	_note(trace, "plan", "%d of %d route tiles have no %s within %.0fpx along her paths as the day stands"
			% [left, tiles, def.id, TASK_ROW_CLOSE_BY])

## The widest a task's row is searched for round where she read its mark: a block and a street past
## the 576px circle round it (`ResistanceDirector.ROADBLOCK_WIDER_REACH`'s last ring), 1,024px. What
## the roadblock phase aims to stand day 13's roadblocks within of every stretch of her routes
## (`_place_the_roadblocks()`).
const TASK_ROW_CLOSE_BY := (Tuning.BLOCK_SIZE * 2.5 + Tuning.STREET_WIDTH * 2.0) * Tuning.TILE_SIZE

## The walkable ground left open within a tile and a half of `plan`'s body: where she touches it
## from.
static func _touched_from(map: CityMap, shut: Dictionary, plan: Planned) -> Array[Vector2i]:
	var reach := plan.blocking_radius() + Tuning.TILE_SIZE * 1.5
	var centre := map.world_to_tile(plan.placed_at())
	var span := ceili(reach / Tuning.TILE_SIZE)
	var found: Array[Vector2i] = []
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var tile := centre + Vector2i(dx, dy)
			if map.in_bounds(tile) and map.is_walkable(tile) and not shut.has(tile) \
					and map.tile_to_world(tile).distance_to(plan.placed_at()) <= reach:
				found.append(tile)
	return found

## **`plan`'s row, unplaced, for her walk to site** (`EventDirector.site_what_is_on_her_way()`):
## what a recurring row handed to her walk (`EventDef.is_handed_to_her_walk()`, the poster crew)
## becomes as a location draws it (`LocationDraw`), so no row drawn after it is spaced from a place
## it never stands at. A one-shot owed to her walk is planned unplaced by `_place_one_shots`.
static func owed_to_her_walk(plan: Planned) -> Planned:
	var owed := Planned.new(plan.def, Vector2.INF)
	owed.role = plan.role
	return owed

# ------------------------------------------------------ the walk's streets from a bag ---

## **One draw per street of the walk, from one marble bag** — `DaySpec.Draw.BAG_PER_STREET`, the
## escape city's draw. The walk knows exactly which streets she can take — everything else is sealed —
## so it draws them before she sets off rather than siting things round her as a day does; and which
## row a street gets, or whether it gets one at all, is a draw. *(Inbox #785 in minty-lemur: "nobody
## ever asked for all four events on *every* street. that doesn't make any sense and cannot feasibly
## work at all. that is why the density is so high that it's impossible to get anywhere. yes, a
## marble bag is absolutely needed with empty events (nothing happening) as well. we need a fair
## mix". Of how many a street holds, inbox #1185 in gentle-owl's board answer: "one per street. fill empty in if
## any segment or location in the street has an event".)*
##
## Each street of the walk (`RouteSource.streets_on_the_walk()`, in its own order) draws one marble
## from `bag`, one bag for the whole walk. A marble with a row (`DaySpec.bag_rows`) is offered at the
## street's locations in the street's own order (`StreetLocations.drawing_order()`), on the ground the
## row fits (`LocationFit`, never the ground she starts on) and left out where the walk's rules
## invalidate it (`StreetInvalidation`: every day's rules but the calm the spec does not keep, one
## waiting guard's notice at a time, and the walk kept open past everything standing on it,
## `WalkGround`); the first location it stands at takes it, and **the rest of the street stays
## empty**. A marble with no row leaves the street empty, and **a row's marble no location of the
## street takes is spent unmet**, so a refused row never moves its danger onto the next street (the
## builder's reading, open to correction: the escape's bag keeps the player's counts, and a refused
## row stays the empty street it is today rather than staying in the bag). A row past its
## `max_per_day` is spent unmet the same way where the spec keeps the caps. Every row is added to
## `events`, the walk's plan, whose `standing()` the seals are.
##
## `bag` is drawn on its own stream (`street_bag_seed()`, off `rng`'s seed), so drawing it takes
## nothing from the stream the placements roll on, and a replan from the same seed — the escape's
## restart after a loss — draws the same walk again. `trace` is told how many marbles the walk drew
## (`bag.drawn`), the plan's own account and the one count a reader of the plan cannot recompute.
static func _draw_the_walk(spec: DaySpec, rng: RandomNumberGenerator, map: CityMap,
		route: RouteSource, bag: MarbleBag, events: DayEvents, calm: CalmAreas,
		doors := PackedVector2Array(), trace: RunTrace = null) -> void:
	if not route:
		return
	# **A tree and an event never share ground** — `docs/CITY.md`, "Street trees".
	var ground := {TREE_TILES_KEY: StreetTrees.footprint_tiles(map)}
	var leave_alone: Array[Rect2] = []
	if spec.keeps_unused_calm_clear:
		leave_alone = calm.unused_ground()
	var corridor := route.corridor()
	var walk := WalkGround.new(map, events.standing(), route) if spec.keeps_the_walk_open else null
	var rules := StreetInvalidation.new(map, corridor, ground, leave_alone, doors,
			spec.one_notice_at_a_time, walk)
	var fit := LocationFit.new(spec.number, map, ground, corridor, spec.holds_the_home_streets,
			route.start())
	var offered := RuledLocationGround.new(spec.number, rng.seed, map, events, corridor, fit, rules)
	var placed := {}
	for segment in route.streets_on_the_walk():
		var def: EventDef = spec.bag_rows.get(bag.draw())
		if def == null:
			continue
		if spec.caps_per_day and int(placed.get(def.id, 0)) >= def.max_per_day:
			continue
		var street := StreetLocations.of(map, segment, PlacementView.View.ON_THE_ROUTE)
		var order_rng := RandomNumberGenerator.new()
		order_rng.seed = hash("%d:%s:walk-street" % [rng.seed, segment.key()])
		for location in street.drawing_order(order_rng):
			var placement := offered.offer(def, location)
			if placement:
				offered.stand(placement)
				placed[def.id] = int(placed.get(def.id, 0)) + 1
				break
	_note(trace, "plan", "the escape's bag drew %d marbles for %d rows"
			% [bag.drawn, events.size()])

## **A marble bag of `counts`**: `counts` marbles of each key, a row's marble or
## `DaySpec.EMPTY_MARBLE`, on its own stream off `seed_value`, filled again whenever it runs empty —
## one bag for the whole walk, so the mix is exact over each fill of it rather than over each street.
## See `_draw_the_walk()`.
static func _street_bag(counts: Dictionary, seed_value: int) -> MarbleBag:
	var marbles: Array = []
	for marble: String in counts:
		for _i in int(counts[marble]):
			marbles.append(marble)
	return MarbleBag.new([], marbles, seed_value)

## The street bag's own stream, off the seed the plan's `rng` was made with rather than off a draw
## from it, so drawing the bag takes nothing from the stream the placements roll on — the shape
## `EventDirector` seeds its route bag in.
static func street_bag_seed(rng: RandomNumberGenerator) -> int:
	return hash("%d:escape-bag" % rng.seed)

## The tiles of one street of the walk a given row may stand on: **the day's own ground for the row**
## (`open_ground_for()`, every refusal a day makes of a tile — a closed tile, a held street, the
## home block, a standing street tree's footprint, the side of the sidewalk the row wants, a corner
## for a row with a spread, the power station's front — and its precinct weight), on the street's
## own rect. *(Inbox #785 in minty-lemur, 2026-10-18: "does the escape use the same placement rules
## as the regular game? it doesn't seem like it does. it should, though.")* The walk names the
## streets that exist for it, so the rect takes the place of a day's corridor weighting.
## `from_the_door` is the spec's home-street rule (`DaySpec.holds_the_home_streets`): the escape
## keeps it off, since she never sets off from that door there.
##
## `trees` is `StreetTrees.footprint_tiles()`, the trees the day's ground refuses, *(2026-09-12, the
## player: "trees read like obstacles (they add noise) so it makes detecting actual obstacles
## harder")*. `open` is the cache `open_ground_for()` keeps its answers in for the whole plan, as a
## day's `ground` is kept for the whole day; a caller with none gets the trees put in a new one.
##
## `standing_at` is where she starts the walk (`RouteSource.start()`), and ground within a body's
## reach of it is refused the same way a tree's is. *(2026-09-19: "the spawning shouldn't be a
## check. the pathing should start from the position. then obstacles can never happen".)* **Refused
## here rather than cleared up afterwards**, which is the whole difference the player is drawing: a
## pass that placed a van on her and a later one that moved it would leave the guarantee resting on
## the repair, and a check that moved *her* instead is the option they named and rejected. Ground she
## is standing on is not ground this is ever offered.
static func street_ground(map: CityMap, segment: StreetNetwork.Segment, def: EventDef,
		trees: Dictionary, standing_at: Vector2, open: Dictionary,
		from_the_door: bool) -> Array[Vector2i]:
	if not open.has(TREE_TILES_KEY):
		open[TREE_TILES_KEY] = trees
	var copies := _open_ground_counts(def, map, open, from_the_door)
	var found: Array[Vector2i] = []
	var rect := segment.tile_rect()
	var clear_of_her := clearance_around_her(def)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if not copies.has(tile):
				continue
			if map.tile_to_world(tile).distance_to(standing_at) <= clear_of_her:
				continue
			for _copy in int(copies[tile]):
				found.append(tile)
	return found

## `open_ground_for()`'s answer for `def` as a count of copies per tile, kept beside it in `open`,
## so a street's tiles are looked up rather than the whole city's list walked once per street.
static func _open_ground_counts(def: EventDef, map: CityMap, open: Dictionary,
		from_the_door: bool) -> Dictionary:
	var key := "street counts|%s|%d|%s|%s|%s" % [def.placement, def.pavement_side,
			_burns_its_front(def), def.has_a_spread, from_the_door]
	if not open.has(key):
		var counts := {}
		for tile in open_ground_for(def, map, open, -1, from_the_door):
			counts[tile] = int(counts.get(tile, 0)) + 1
		open[key] = counts
	return open[key]

## How far from the tile she is put down on a row of this kind may not be offered ground — the
## wider of the two things she can arrive *inside* of: a body, and a lethal field.
##
## **A body is her body plus its body.** The half tile on top of it is not a margin of taste: a
## stationary, unpinned body is moved from the lane tile the scheduler chose to the middle of the
## pavement band by `EventFootprints._centred_on_the_pavement_band()` when the instance is built, and
## the two lane centres sit `TILE_SIZE * 0.5` either side of that middle — so the ground a
## placement finally stands on is up to half a tile from the tile this loop is looking at, and the
## exclusion has to cover where it *ends up* rather than where it is rolled.
##
## **A lethal field is its whole `outer_radius`**, which is a different and much wider question.
## *(2026-09-19: "I still spawn with flashing !!! in the city.")* The doubled exclamation mark over
## her head means *this will end your day*, and `WarningBoard.warn_about_the_ground_she_is_on()`
## raises it for any `hard_fail` row still telegraphing — or still waiting to notice her — whose
## **outer** radius covers her, because that radius is exactly what the fairness contract promises
## her time to walk out of. A row placed inside it has therefore already spent her notice before
## she has taken a step, which is the same defect as a body on her spawn read one field wider: on
## the seed the player walked, an `abduction` van stood 143px away with a 250px field.
##
## So the ground she is put down on is not ground a lethal row is ever offered either. Refused here
## rather than cleared up afterwards, for the reason `street_ground()` gives: a pass that placed a
## van on her and a later one that moved it would leave the guarantee resting on the repair. The
## half tile is carried for a lethal row too, since the same recentring moves it.
##
## A row with neither a body nor a lethal field needs none of this: nothing about it can be stood
## inside, and nothing about it raises the mark.
static func clearance_around_her(def: EventDef) -> float:
	var reach := 0.0
	if def.obstructs_radius > 0.0:
		reach = def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS
	if def.hard_fail:
		reach = maxf(reach, def.outer_radius)
	if reach <= 0.0:
		return 0.0
	return reach + Tuning.TILE_SIZE * 0.5

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
## like the cat — and `WALL` every day after, once it is `EventDef.from_day_after`'s `MAP`
## placement and the scheduler has chosen it a tile like any other lethal row.
##
## **A wall is not only the lethal rows.** The ground off the routes *ranges from very costly to
## deadly*, so an expensive row is a wall too and `WALL_WORTH_OF_COST` is where the line
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
## **`EventDef.Role.SCENERY` is checked before the cost is, and it answers `NONE` rather than a fifth
## role.** *"Flocks are basically free already — don't count it as block, just count is
## scenery."* `pigeon_flock`'s 42-over-168px field crosses `WALL_WORTH_OF_COST` on the plain
## reading, so without the exemption it would be a wall pulled off every route the way any other
## expensive row is — which is exactly the placement the player overturned. `NONE` already means
## "placed for a reason that is not about the corridor at all," which is the flock's own case: it
## is still sited on a tile like everything else, just never weighted toward or away from one.
static func role_for(def: EventDef, day: int = 0) -> GameEnums.BlockerRole:
	if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP or def.kind == GameEnums.EventKind.AMBIENT:
		return GameEnums.BlockerRole.NONE
	if def.role == EventDef.Role.SCENERY:
		return GameEnums.BlockerRole.NONE
	if def.kind == GameEnums.EventKind.ONE_SHOT:
		return GameEnums.BlockerRole.SET_PIECE
	if def.hard_fail or def.walk_through_cost() >= WALL_WORTH_OF_COST \
			or _takes_a_whole_sidewalk(def):
		return GameEnums.BlockerRole.WALL
	return GameEnums.BlockerRole.FRICTION

## **Whether a `WALL` earns the pull toward junction rims, as opposed to keeping only the one
## consequence every wall gets** (zero copies on a route-carrying cell, `_copies_of` below).
## *(2026-09-19, the player, asked whether `delivery_van` should also be weighted toward junctions
## once it became a wall: "A. No (my recommendation). -- do that")* `EVENT_WALL_RIM_WEIGHT`
## is for the rows meant to be seen from a distance before she commits to a street — lethal, or
## costly enough to cross `WALL_WORTH_OF_COST` — and `delivery_van` is neither: silent, and a wall
## only because its own body leaves no lane (`_closes_the_band_by_its_own_placement`), which the
## cost clause (`EventDef.reaches_the_far_lane()`) never sees. A row that is a wall by fit alone is
## spread along streets the way friction is instead: `_copies_of` reads this before deciding which
## weight a `WALL` gets.
static func _is_a_wall_by_cost(def: EventDef) -> bool:
	return def.hard_fail or def.walk_through_cost() >= WALL_WORTH_OF_COST \
			or def.reaches_the_far_lane()

## A private RNG for one phase of the day, derived from the day's seed and a salt.
##
## **A retried day has to be the same day, and one shared stream cannot deliver that.** Run the
## phases off a single sequence and anything that changes how much an earlier phase draws moves
## everything after it — and two things change between attempts by design:
##
## - `_place_one_shots` skips a one-shot the run has already spent. Skipping it *before* drawing its
##   `randf()` would start every later phase's draws one value earlier on the second attempt and
##   produce a different city's worth of events.
## - `_place_scars` prepends what the run has burnt down, and every scar is one more plan for
##   `StreetInvalidation.room_around` to reject a placement against — and a rejection is a re-roll.
##
## Separate streams close the first completely and most of the second (each phase's salt, the dawn
## draw's `LOCATIONS_SALT` among them).
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
## and if the day happened to owe none there is nothing to teach. `charging_dog` is weight 1.4 of
## a day-3 pool, so whole day 3s with none of them exist — and a player can reach act II never
## having been shown the one control the game will later require.
##
## It is added **outside** the day's draws rather than competing in them, and that is the exception
## being made honestly: everywhere else in this file the density is the bags', and a lesson that only
## happens when the dice agree is not a lesson. One event on one day of fourteen.
static func _ensure_the_run_is_taught(day: int, events: DayEvents, heat: int = 0,
		trace: RunTrace = null) -> void:
	if day != Tuning.RUN_TAUGHT_DAY or events.has_a_pursuit():
		return
	for def in EventCatalogue.available_on(day, heat):
		if def.pursuit == null or def.spawn_mode != EventDef.SpawnMode.AHEAD_OF_PLAYER:
			continue
		events.add(Planned.new(def, Vector2.INF))
		_note(trace, "plan", "day %d owes no pursuit, so the run lesson is added: %s"
				% [day, def.id])
		return

# ------------------------------------------------------- the city remembers ---

## Puts something on a calm area she has already settled in this act.
##
## Not because repetition is boring, but because **the game's only verb stops being a decision on
## day two**: a player who finds a good park on day 1 has no question left to answer, and route
## planning is the whole game. It is the same problem as a calm area being a lap rather than a
## route, one scale up: that one is about the destination, this is about *which* destination.
##
## **And the day's route tree plans around the same area** (`ClosurePlanner.calm_to_shut()`, checked
## before it is accepted the way a street closure is): the tree neither grows a branch to a used area
## it can spare nor routes through it, so a spoiler standing here is never somewhere the tree was
## going to send her regardless. *(PLAYTEST-140, statement 8: "a used park is shut by the events
## placed in it, as before... and no route of the day goes through it".)*
##
## **One used area, at most once a run, is fenced instead** — `CityMap.fenced_park`, the first used
## area whose exclusion the guarantees allow on a day in act III or later (`Tuning.ACT_START_DAYS`),
## fenced for the rest of that act and never chosen again. *(PLAYTEST-140: "doing it for one park,
## sure, more towards the later stages of the game once but not for regular".)* It is never in
## `map.calm_blocks`, so it is skipped here by the same test that skips anywhere no longer calm —
## its fence is the whole of what it shows, and a spoiler behind it would be noise on the pavement
## beside a park nobody can enter.
##
## Three things keep it from being a punishment for playing well, and all three are load-bearing:
##
## - **It spoils with events, not by taking the ground away.** The park is still there, still
##   calm ground, still walkable. Things are standing in it, and she can see that from
##   the street and decide. An event that could seal or end the day is never chosen for this.
## - **One area is kept clean by construction** (`_calm_kept_clean()`): the spoilers pass over it and
##   its ground joins what nothing may reach, so the day it creates is still winnable and the
##   alternative is still real rather than nominal.
## - **They are ordinary events, placed like any other.** They have no count of their own
##   and are drawn from the same day's pool, so day 2 is not "day 1 plus a punishment", it is a day
##   whose noise happens to be somewhere she was counting on.
##
## **It has to cover the ground, not stand in it**, and one event does not.
##
## What denies calm ground is holding the meter above `EXCITEMENT_CALM_THRESHOLD` against
## `CALM_ZONE_DENIAL_RATE`, 7.7/s — so a busker at intensity 19.3 has a *useful* radius of
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
## exactly what the spacing rule at `StreetInvalidation.room_around` prevents everywhere else.
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
## Silent for anywhere she did not settle, that is no longer calm, or that is `CityMap.fenced_park`
## today — the last because it is left out of `map.calm_blocks`, and said again here so the reason
## is next to the loop. A merely-`shut_calm` area is not skipped: it is still calm ground, and this
## is exactly what stands in it.
static func _spoil_the_parks_she_used(day: int, rng: RandomNumberGenerator, map: CityMap,
		events: DayEvents, calm: CalmAreas, kept_clean: Vector2i, reach: RouteReachRule,
		heat: int = 0, trace: RunTrace = null) -> void:
	var blocks := calm.blocks()
	var spoilable := blocks.size() - 1
	for block in calm.used():
		if spoilable <= 0:
			return
		if block.x >= 0 and block in blocks and block != kept_clean:
			spoilable -= 1
			_spoil_one_park(day, rng, map, events, calm, block, reach, heat, trace)

## **The calm area the day keeps clean, where only construction can keep one**: `NONE` while an area
## counted today (any but `calm.besides()`, day 12's swing park) is one she has not used this act,
## since the calm rule keeps every unused area clear (`CalmAreas.unused_ground()`); otherwise the
## counted area she used longest ago that nothing standing spoils yet, else the least spoiled. The
## spoilers pass over it and its ground joins what nothing may reach, so the day has clean calm
## ground by construction (`docs/CITY.md`, "Guarantees").
static func _calm_kept_clean(calm: CalmAreas, events: DayEvents) -> Vector2i:
	var used := calm.used()
	var counted: Array[Vector2i] = []
	for block in calm.blocks():
		if block == calm.besides():
			continue
		if not used.has(block):
			return CalmAreas.NONE
		counted.append(block)
	var oldest_first: Array[Vector2i] = []
	for i in range(used.size() - 1, -1, -1):
		if counted.has(used[i]):
			oldest_first.append(used[i])
	var least := CalmAreas.NONE
	for block in oldest_first:
		if not events.is_spoiled(block):
			return block
		if least == CalmAreas.NONE \
				or events.spoilers_of(block).size() < events.spoilers_of(least).size():
			least = block
	return least

static func _spoil_one_park(day: int, rng: RandomNumberGenerator, map: CityMap,
		events: DayEvents, calm: CalmAreas, block: Vector2i, reach: RouteReachRule,
		heat: int = 0, trace: RunTrace = null) -> void:

	var lot := calm.rect_of(block)
	var open: Array[Vector2i] = []
	for tile in map.rect_tiles(lot):
		if not map.is_closed(tile):
			open.append(tile)
	if open.is_empty():
		return

	var ground := calm.ground_of(block)
	var pool := _things_to_put_in_a_park(day, ground, heat)
	if pool.is_empty():
		return

	var placed: Array[String] = []
	for cell in _spoiling_grid(ground, pool):
		var def := _pick_by_what_it_denies(pool, rng)
		# Snapped to the nearest open tile of the lot, so nothing lands on a closed street or
		# outside the calm ground the cell was measured from.
		var at := map.tile_to_world(_nearest_of(open, map.world_to_tile(cell)))
		var plan := Planned.new(def, at)
		# A body that would cut the routes off from home is not stood: the park stays busy
		# without it.
		if not _keeps_the_routes(plan, map, events, reach):
			continue
		events.add(plan)
		placed.append(def.id)
	if placed.is_empty():
		return
	_note(trace, "roll", "%s in the park she used yesterday, %s"
			% [", ".join(placed), RunTrace.tile(block)])

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
	while columns * rows > SPOILERS_TO_DENY_A_PARK:
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
## than `CALM_ZONE_DENIAL_RATE` (7.7/s) is somewhere she can still settle — and for every
## act I row that is most of its own field. Getting this wrong is how one busker was ever thought
## to spoil a park.
##
## **The rate is its own constant rather than the calm ground's live decay**, because *which rows
## may stand beside a park* is a decision about the parks and not about how fast the pram settles.
## Read off the decay, every rise in the walking rate would admit louder rows here as a side
## effect of a change nobody made about parks.
##
## **The zero case is not the line rules' zero case.** `EventDef.reach_above()` answers nothing at all for a
## row quieter than the rate it is asked about, which is right there — ground a walk nets the meter
## down in is not denied — and wrong here: a source she is standing on top of keeps her awake
## whatever its rate does further out, so the floor is its own `inner_radius`.
static func _denial_radius(def: EventDef) -> float:
	return maxf(def.inner_radius, def.reach_above(CALM_ZONE_DENIAL_RATE))

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
##
## **And it has to stay where it was put.** A row handed to her walk (`EventDef.is_handed_to_her_walk()`,
## the sidewalk `poster_crew`) stands where her walk sites it, never where the dawn would put it, so a
## park it was meant to spoil would stand empty, against PLAYTEST-140 8 (a used park is shut by the
## events placed in it). None is offered.
static func _things_to_put_in_a_park(day: int, ground: Rect2, heat: int = 0) -> Array[EventDef]:
	var allowed := maxf(OBSTRUCTION_A_PARK_CAN_HOLD,
			minf(ground.size.x, ground.size.y) / 16.0)
	var suitable: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, heat):
		if def.hard_fail or def.mobile:
			continue
		if def.obstructs_radius > allowed:
			continue
		if def.spawn_mode != EventDef.SpawnMode.MAP:
			continue
		if def.is_handed_to_her_walk():
			continue
		suitable.append(def)
	return suitable

## The masts: the run's sites (`mast_sites`, worked out once on the city as built,
## `EventWorld.mast_sites()`), planted from `Tuning.MAST_FIRST_DAY` and standing at the same places
## every day of the run. Bypasses the scripted rows' dawn phase (`_place_scripted`) entirely — a mast is not a
## tile the day's own roll chose, it is a fixture the city already carries, the same way
## `_place_ambient()` beside this hands out one plan per playground rather than rolling for one.
##
## **Except a day whose own closures, region wall or checkpoints need that exact tile.** `map`
## already carries today's holds and closures by the time `build_day` runs them — `EventManager.
## start_day()` populates both before calling this — so a site is skipped for the day rather than
## planted on top of a barricade or a hut: `tests/test_events.gd`,
## `_test_nothing_the_catalogue_places_stands_on_held_ground`, holds this for every row the
## catalogue places and a mast is no longer an exception to it. `MastSites` already keeps every
## site a full block off the home street and its own field off a calm interior, so this is rare —
## a closure or a wall is one street's own width, not the whole city — and it costs a day's worth
## of one mast rather than a guarantee.
##
## **And a day whose own doors it would reach.** `MastSites._reaches_a_possible_door()` already
## refuses a site near *any* boundary segment's own door position — the boundary and the wall's
## own end are fixed at generation (`RegionPlanner.assign()`), so that exclusion is as
## day-independent as the sites themselves, and it is `MastSites`' own count that shows how few
## sites it actually costs. `doors` is only today's *open* doors, narrower than every boundary
## segment could ever be, so this second check is a safety net for whatever the siting-time
## exclusion cannot see (an alley door among them) rather than the rule's main work — see
## `DoorClearanceRule.clear_of_the_doors()`, the same guarantee `tests/test_checkpoints.gd` holds for every row.
##
## On `CURFEW_ANNOUNCE_DAY` every standing site also gets a `curfew_announce` plan
## alongside its ordinary `loudspeaker` one — see that row's own doc for why a second, invisible
## plan is what "the masts carry the announcement" means rather than a second mast.
##
## **A mast she silenced on an earlier day stands silenced**: `scars` carries a `SILENCED_MAST`
## entry at its foot (`ResistanceDirector._silence_the_mast()`), and its plans are made with
## `Planned.silenced` already set — the pole and horns are there, the lamp is out and there is no
## field, for the rest of the run.
##
## **So does a mast queued for day 11's task** (`EventManager.queue_a_mast()`): a `SILENCED_MAST` scar
## no site's foot is within a tile of is that mast, and it is planned again at its own foot, silenced,
## under `added_mast_id()`, on every later day whose holds, closures and doors leave the tile alone
## — the same refusals a site is planned under. One that was never silenced left no scar and is not
## planned again (*"Only if silenced"*).
static func _place_masts(day: int, map: CityMap, mast_sites: Array[MastSites.Site],
		heat: int = 0, doors := PackedVector2Array(), scars: Array[Dictionary] = []) -> Array[Planned]:
	var planned: Array[Planned] = []
	if day < Tuning.MAST_FIRST_DAY:
		return planned
	var loudspeaker := EventCatalogue.heated(EventCatalogue.mast(), heat)
	var curfew := EventCatalogue.heated(EventCatalogue.by_id("curfew_announce"), heat) \
			if day == CURFEW_ANNOUNCE_DAY else null
	var sites := mast_sites
	for scar in scars:
		if String(scar["id"]) != SILENCED_MAST or int(scar["since_day"]) >= day:
			continue
		var foot: Vector2 = scar["position"]
		var at_a_site := false
		for site in sites:
			if site.foot.distance_to(foot) < Tuning.TILE_SIZE:
				at_a_site = true
				break
		var tile := map.world_to_tile(foot)
		if at_a_site or map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
			continue
		if not DoorClearanceRule.clear_of_the_doors(foot, PackedVector2Array(), doors, loudspeaker.field_reach()):
			continue
		var added := Planned.new(loudspeaker, foot)
		added.mast_id = added_mast_id(foot)
		added.silenced = true
		planned.append(added)
	for site in sites:
		var tile := map.world_to_tile(site.foot)
		if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
			continue
		if not DoorClearanceRule.clear_of_the_doors(site.foot, PackedVector2Array(), doors,
				loudspeaker.field_reach()):
			continue
		var quiet := _was_silenced(site.foot, day, scars)
		var mast := Planned.new(loudspeaker, site.foot)
		mast.mast_id = site.id
		mast.silenced = quiet
		planned.append(mast)
		if curfew:
			var announcement := Planned.new(curfew, site.foot)
			announcement.mast_id = site.id
			announcement.silenced = quiet
			planned.append(announcement)
	return planned

## The id of a mast queued for day 11's task at `foot` (`EventManager.queue_a_mast()`), the same
## every day it is planned again from its scar, and never a `MastSites` site's own id.
static func added_mast_id(foot: Vector2) -> String:
	return "added-%d-%d" % [roundi(foot.x), roundi(foot.y)]

## The scar id a mast she silenced leaves at its foot. No catalogue row answers it, so
## `_place_scars` places nothing for it; `_place_masts` is its only reader.
const SILENCED_MAST := "silenced_mast"

## Whether a `SILENCED_MAST` scar from an earlier day stands at `foot` — within a tile, since the
## foot a scar records and the foot a site computes are the same point read twice.
static func _was_silenced(foot: Vector2, day: int, scars: Array[Dictionary]) -> bool:
	for scar in scars:
		if String(scar["id"]) == SILENCED_MAST and int(scar["since_day"]) < day \
				and (scar["position"] as Vector2).distance_to(foot) < Tuning.TILE_SIZE:
			return true
	return false

## Permanent marks left by earlier days, placed again exactly where they happened, each into
## `events`, unless a body of one would cut a route tile off from home (`reach`): then it is not
## stood today, which is the day's routes kept open by construction rather than a repair taking it
## away afterwards.
static func _place_scars(day: int, scars: Array[Dictionary], map: CityMap, events: DayEvents,
		reach: RouteReachRule, heat: int = 0) -> void:
	for scar in scars:
		if int(scar["since_day"]) >= day or String(scar["id"]) == SILENCED_MAST:
			continue
		var def := EventCatalogue.by_id(String(scar["id"]))
		if def:
			var plan := Planned.new(EventCatalogue.heated(def, heat), scar["position"])
			plan.permanent = true
			if _keeps_the_routes(plan, map, events, reach):
				events.add(plan)

## Whether `plan`, stood where it is, leaves every route tile home reaches reached (`reach`), asked
## against what the day holds and what stands. Only the reach: a scar or a spoiler is not spaced and not given a role, and stands on a route's
## line as it always did.
static func _keeps_the_routes(plan: Planned, map: CityMap, events: DayEvents,
		reach: RouteReachRule) -> bool:
	var placed := events.placements()
	var around := placed.duplicate()
	around.append_array(events.standing())
	return reach.allows(plan, map.world_to_tile(plan.position), placed, around)

## Where a placement's body stands once it is built: the first point of its path when it has one,
## recentred on the pavement band unless `pavement_side` pins it — the reading
## `EventInstance.setup()` makes of a stationary body, which is where a waiting guard's band stands
## and where he notices her from (`OneNoticeRule`).
static func body_stands_at(map: CityMap, plan: Planned) -> Vector2:
	return EventFootprints.stands_at(map, plan.def,
			plan.path[0] if plan.path.size() > 0 else plan.position)

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

static func _place_scripted(day: int, rng: RandomNumberGenerator, events: DayEvents,
		phase: ScriptedPhase, heat: int = 0) -> void:
	for def in EventCatalogue.of_kind(GameEnums.EventKind.SCRIPTED, day, heat):
		# A row sited while she walks is owed here with no position, as every such row is.
		if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
			events.add(Planned.new(def, Vector2.INF))
			continue
		phase.place(def.for_day(day), rng)

## How strongly `def`'s dawn phase draws `location`: the copies its role gives each tile of the
## location it may stand on (`ground_for()`'s pool, whose role weights keep a wall off the route and
## draw friction onto it), summed; 0 where it may stand on none. The pool is the day's, worked out
## once a row (`ground`).
static func _weight_in(def: EventDef, location: Location, day: int, map: CityMap,
		ground: Dictionary, corridor: Corridor, holds_the_home_streets: bool) -> float:
	var key := "phase copies:%d" % def.get_instance_id()
	if not ground.has(key):
		var copies := {}
		for tile in ground_for(def, map, ground, corridor, role_for(def, day),
				holds_the_home_streets):
			copies[tile] = int(copies.get(tile, 0)) + 1
		ground[key] = copies
	var by_tile: Dictionary = ground[key]
	var weight := 0
	var rect := location.tiles()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if by_tile.has(tile) and location.takes(map.tile_at(tile)):
				weight += int(by_tile[tile])
	return float(weight)

static func _place_one_shots(day: int, consumed: Array[String], events: DayEvents, heat: int = 0,
		trace: RunTrace = null) -> void:
	# **A one-shot is owed to her walk, never rolled for.** Every one-shot is sited from her walk
	# (`EventDef.validate()` refuses one that is not): it is the day's authored beat and has to
	# happen whichever way she goes, so the plan is made here, at dawn, and only its *position* is
	# left for `EventDirector.site_what_is_on_her_way()` to choose, the same split an
	# `AHEAD_OF_PLAYER` row is owed and sited under.
	for def in EventCatalogue.of_kind(GameEnums.EventKind.ONE_SHOT, day, heat):
		if def.id in consumed:
			continue
		var owed := Planned.new(def, Vector2.INF)
		owed.role = role_for(def, day)
		events.add(owed)
		# **And it is not consumed here.** It has no position yet, so planning it promises nothing.
		# It is spent where it becomes real instead — `EventStreaming.stream_in()`. What that buys is
		# the retry: *"what the run has spent stays spent ... a fire that burnt a block down did
		# happen"* (`RunCalendar.finish_day`), and a fire that was never lit did not, so a lost day 3
		# is offered it again.
		_note(trace, "roll", "one-shot %s: owed to her walk, sited when her heading is clear"
				% def.id)

# ------------------------------------------------- a placement made after dawn ---

## The day's own placement context, kept past dawn so that a row the day left for her walk to site
## is placed against exactly the ground, corridor, doors and protected calm every other placement
## was stated against.
##
## **Why a placement can be made after dawn at all.** Every guarantee in this file is stated over a
## *day* and decided in `build_day` — and that is untouched here: the row is planned at dawn, its
## role is decided at dawn, and what it may stand on was decided at dawn. Only *which* of those
## tiles it takes waits, because on day 3 the fire has to be on the way she actually goes and
## nothing at dawn knows which way that is. See `EventDef.on_her_way`.
##
## **Nothing placed while she walks is asked whether she can still get away.** The day's safe routes
## are fixed before the day starts, and nothing placed during the walk may close one, so there is
## nothing to check live (inbox #1173: "there should be no live reachability check. that's a hard
## no"). What is sited here is what the day's own placement rules (`EventScheduler._best_of()`)
## accept and no more: the fire, which has no body (PLAYTEST-144 12), the poster crews, the places
## her route's bag hands her walk, and day 11's mast. Day 13's task roadblock is one the day placed
## (`ResistanceDirector._place_the_roadblock_near()`), never one sited here.
class WalkSiting extends RefCounted:
	var _day: int
	var _map: CityMap
	## The day's routes themselves, not only the corridor made of them: a siting on the branch she
	## is walking needs the ordered chain of cells. See `_the_way_she_is_going()`.
	var _tree: RouteTree
	var _corridor: Corridor
	var _leave_alone: Array[Rect2]
	## The walk's events: its plans, its doors and its calm areas (`WalkEvents`).
	var _walk: WalkEvents
	## The same per-day cache of "which tiles may this kind of row stand on" `build_day` threads
	## through its own placements, kept here for the day so the city is not rescanned per attempt.
	var _ground := {}

	## Why attempts placed nothing, as `reason -> how many attempts ended that way`. Nothing in the
	## game reads it: it is what lets `tests/probes/m179_fire_on_her_way.gd` report *what* a long wait
	## was made of, which is the difference between a branch with no frontage on it and a day whose
	## every site breaks a placement rule.
	var waits := {}
	## How many sitings had to widen past the band to the end of her branch, for the same probe.
	var widened := 0
	## The sidewalk tiles in front of a blank ground-floor cell, as a set — `PosterWalls.fronts()`,
	## handed over by `EventManager` from the city it belongs to. What a row whose `OnHerWay.at_a_front` is set
	## may stand on; empty, and so nowhere, for a rig with no city.
	var fronts := {}
	## **Whether the home's streets are the walk's** (`DaySpec.holds_the_home_streets`): nothing
	## sited after dawn stands on the street her front door opens onto, as nothing at dawn does
	## (`EventScheduler.open_ground_for()`'s `from_the_door`). Handed over by `EventsAhead` from the
	## spec the walk was started with; a day's rule until then.
	var holds_the_home_streets := true

	## `tree` is the day's corridor tree and `walk` the walk's events (`WalkEvents`): its plans, which
	## every placement is spaced and checked against, where today's doors stand and the day's calm
	## areas, whose unused ground is the calm nothing is placed near (`CalmAreas.unused_ground()`).
	## The tree is taken rather than the finished `Corridor` so this stays the one place that turns
	## it into the other. **The tree itself is kept as well as the corridor it makes**: the corridor
	## answers *how far off the routes is this tile*, and what a siting on her own branch needs is the
	## ordered chain of cells a route actually runs along.
	##
	## `verdicts` is where its placements keep the verdicts of the candidates they judge
	## (`EventScheduler.Verdicts`), handed in by whoever builds the siting. Every owner in the game
	## hands each siting a store of its own: verdicts are kept under a candidate's key and judged
	## against one siting's plans and route tree, so a siting asked while another is in a look would
	## read verdicts judged for the other's plans and place wrongly, not only lose a cache.
	func _init(for_day: int, map: CityMap, tree: RouteTree, walk: WalkEvents,
			verdicts: EventScheduler.Verdicts) -> void:
		_day = for_day
		_map = map
		_tree = tree if tree else RouteTree.for_day(map, for_day)
		_corridor = Corridor.of(_tree)
		_walk = walk
		_leave_alone = walk.calm().unused_ground() if walk.calm() else ([] as Array[Rect2])
		_verdicts = verdicts

	## A placement for `def` on a tile of its own ground **on the branch of the day's route tree she
	## is walking** — whatever `_ground_as_a_set()` offers the row: a building face for day 3's fire
	## and the poster crews, a sidewalk for a man shouting, a mast's site for a mast — between
	## `near` and `far` pixels ahead of her measured *along that route*, or `null` when there is
	## nothing legal there — which is a retry as she walks and never a placement made anyway.
	##
	## **The path is the day's route tree, and a place off it is never a site.** *(PLAYTEST-119:
	## "the fire needs to spawn on the current path the player is on — moving it around works but
	## valid spawn locations are only on the path".)* A straight line from her is the wrong measure
	## twice over: it offers tiles on streets her route never reaches, and it prices a tile round
	## the corner as nearer than it is to walk to. So the window is walked cell by cell down the
	## route, through its corners and its junctions, and only the tiles of the row's ground on those
	## cells are offered. A wall by its fit alone (day 7's route van) and a man shouting a bag hands
	## her (day 6's rigged one) are sited on the street she is walking instead, just out of her sight
	## (`ahead_on_her_street()`).
	##
	## **The far end is read along the route and the near end is a straight line**, and they are two
	## different questions rather than one measured twice. Far is how much more walking there is
	## before she sees it, which is what the route says. Near is whether it is in the world at all,
	## which is the streaming radius and therefore a distance across the block: a site 1200px along a
	## route that doubles back can be 500px from her, streamed in — and so real, and unmovable — on
	## the frame it was placed. A straight line is never longer than the route to the same place, so
	## clearing the streaming band clears the near end of the band along the route as well.
	##
	## **At a fork, either way out is a site.** Every route through the cell she is standing on is
	## walked, so before she commits both are on offer; once she has taken one, her own cell carries
	## only that one and `EventDirector._is_no_longer_on_her_way()` moves an unseen fire off the other.
	##
	## **A window with none of the row's ground in it widens along the same branch before anything
	## else is considered** — to the end of the route rather than off the tree — because "further
	## along the way she is going" is still the way she is going, and the alternative on a short
	## branch is a fire that waits all day. Nothing else about the candidate bends.
	##
	## `besides` is the plan being sited, if it is one of the walk's: everything else the walk has
	## planned is what the site is spaced and checked against (`WalkEvents.everything_but()`). **The
	## plan being sited is never among them** — a row being moved off a position it has not yet been
	## seen at must not be spaced against its own old body, or the second siting is refused the
	## street the first one was standing in.
	func ahead_of(def: EventDef, rng: RandomNumberGenerator, besides: Planned,
			at: Vector2, heading: Vector2, near: float, far: float) -> Planned:
		var role := EventScheduler.role_for(def, _day)
		# A wall by its fit alone is never put on a sidewalk a route runs along, so it is put on the
		# street she is walking instead, just out of her sight (`ahead_on_her_street()`).
		if (role == GameEnums.BlockerRole.WALL and not EventScheduler._is_a_wall_by_cost(def)) \
				or def.id == _MET_ON_HER_STREET:
			return ahead_on_her_street(def, rng, besides, at, heading)
		var offer := _offer_ahead(def, at, heading, near, far)
		match offer[0]:
			_OFF_THE_ROUTES:
				return _waited("she is off the day's routes")
			_NONE_ON_THE_BRANCH:
				return _waited("no tile of its ground on the branch ahead of her")
			_WIDENED:
				widened += 1
		var offered: Array[Vector2i] = offer[1]
		var already := _walk.everything_but(besides)
		var candidate := EventScheduler._best_of(def, rng, _map, offered, role, already, _ground,
				_leave_alone, _corridor, _walk.doors(), [], _verdicts_for_an_ask())
		if not candidate:
			return _waited("every tile of its ground on her branch broke a placement rule")
		# A crew faces the wall it pastes, its back to the street. `build_placement` turned it by
		# the dawn's own side, out of a wall it was never going to stand at.
		if def.on_her_way != null and def.on_her_way.at_a_front:
			candidate.facing = Vector2.UP
		return candidate

	## **Starts a look: from here every `ahead_of()` keeps its verdicts for the rest of the look**,
	## so a candidate judged for one copy is not judged again for the next. The director asks about
	## every copy still owed, from one place, against the same plans, and the day's rules
	## (`StreetInvalidation`) read only what of those plans is standing — every rule passes over
	## a plan that is not placed — so the same row, role, tile and path get the same verdict for
	## every copy, and every roll still happens. **The caller drops the verdicts the moment that
	## stops being true** (`forget_the_verdicts()`): when it places or moves a plan, and around asking
	## about a plan that is already placed, which is judged without its own body where every other
	## ask counts it. `end_look()` drops them too, so nothing is carried into the next look, by when
	## the world has moved on.
	func begin_look() -> void:
		_verdicts.forget()
		_in_a_look = true

	## The kept verdicts are no longer what a fresh judgement would say. See `begin_look()`.
	func forget_the_verdicts() -> void:
		if _in_a_look:
			_verdicts.forget()

	## Ends a look; `ahead_of()` keeps nothing past its own call again.
	func end_look() -> void:
		_verdicts.forget()
		_in_a_look = false

	## Where every placement this siting makes keeps its verdicts, handed in when it was built. See
	## `_init()`.
	var _verdicts: EventScheduler.Verdicts
	## Whether a look is under way, and so whether `ahead_of()` keeps its verdicts for the next ask.
	var _in_a_look := false

	## The verdicts an ask hands `EventScheduler._best_of()`: inside a look, the look's for an ask of
	## the look (`ahead_of()`); otherwise none kept from an earlier ask, as if the call kept its own.
	func _verdicts_for_an_ask(of_the_look := true) -> EventScheduler.Verdicts:
		if not (of_the_look and _in_a_look):
			_verdicts.forget()
		return _verdicts

	## What `ahead_of()` is offered, as `[how it was found, the tiles]`: the row's ground in the band
	## ahead of her on her branch, or, with none there, widened along the same branch — twice the
	## band first, then the whole of the route she is on. Stepped rather than straight to the end,
	## because the widening is for "a little further along the way she is going" and `_best_of`
	## takes the roomiest of what it is offered — handed the whole branch it picks the emptiest
	## street on it, which is the far end of a walk she has not decided to take yet.
	##
	## **Worked out once per look, not once per copy.** It draws nothing from any stream and reads
	## only the day's tree and the row's ground, so the answer for the same ground, the same place,
	## heading and band is the same answer: the director asks it of every crew still owed in one look,
	## from one place, and the last question asked is kept and given back.
	func _offer_ahead(def: EventDef, at: Vector2, heading: Vector2, near: float,
			far: float) -> Array:
		var at_a_front := def.on_her_way != null and def.on_her_way.at_a_front
		var side := EventDef.Pavement.AT_THE_FRONT if at_a_front else def.pavement_side
		var question := [def.placement, side, def.role == EventDef.Role.MAST, at, heading, near, far]
		if question == _last_offer_question:
			return _last_offer
		offers_worked_out += 1
		var nothing: Array[Vector2i] = []
		var answer := [_OFF_THE_ROUTES, nothing]
		var ahead := _the_way_she_is_going(at, heading, far)
		if not ahead.is_empty():
			var offered := _its_ground_on(def, ahead, at, near, far)
			answer = [_IN_THE_BAND, offered]
			if offered.is_empty():
				answer = [_NONE_ON_THE_BRANCH, offered]
				for wider in [far * 2.0, INF]:
					ahead = _the_way_she_is_going(at, heading, wider)
					offered = _its_ground_on(def, ahead, at, near, wider)
					if not offered.is_empty():
						answer = [_WIDENED, offered]
						break
		_last_offer_question = question
		_last_offer = answer
		return answer

	## How `_offer_ahead()` found what it offers.
	const _IN_THE_BAND := 0
	const _WIDENED := 1
	const _NONE_ON_THE_BRANCH := 2
	const _OFF_THE_ROUTES := 3
	## The last question `_offer_ahead()` answered, and its answer.
	var _last_offer_question := []
	var _last_offer := []
	## How many times `_offer_ahead()` has worked an offer out rather than given the last one back.
	## For `tests/test_siting_judges_once.gd`; nothing in the game reads it.
	var offers_worked_out := 0

	## **`ahead_of()` for a wall by its fit alone** — a row whose body leaves no line past it on the
	## sidewalk it stands on: day 7's second van (`ResistanceDirector._rig_her_route_for()`). Its
	## marble is drawn so she meets it *(olive-koala, statement 2: "that way we can control what the
	## player sees on their route")*, and a van is never put on a sidewalk a route runs along
	## (`RouteSidewalkRule._leaves_the_routes_sidewalk_open()`: "the far side of a street answers a van, and nothing
	## answers a van on the side the route is drawn down"), so the branch-and-band siting the other
	## places take would put it where her walk does not go: across a route she has often left, and a
	## band she rarely walks to the end of.
	##
	## **So it is put on the street she is walking, just out of her sight ahead of her**: the ground
	## it may stand on within `_STREET_HALF_WIDTH` either side of her line of travel, ahead of her
	## with the whole of what it draws past the edge of the camera's view, its lead included
	## (`could_be_in_her_view()`), and within `Tuning.EVENT_STREAM_RADIUS`, nearest first, under
	## every acceptance rule `ahead_of()` applies. Inside the streaming radius it is in the world at once, where she will see
	## it in a few seconds if she keeps walking that way, and like anything in the world it is not
	## moved again. `near` and `far`, the director's band for a place it may still move, are not read.
	## *(Proposed, not asked for: "on her route" read as the street she is walking.)*
	func ahead_on_her_street(def: EventDef, rng: RandomNumberGenerator, besides: Planned,
			at: Vector2, heading: Vector2) -> Planned:
		var role := EventScheduler.role_for(def, _day)
		if heading.length_squared() < 0.5:
			return _waited("she is not walking anywhere")
		var pool := _ground_as_a_set(def)
		var by_distance := {}
		var centre := _map.world_to_tile(at)
		var reach := ceili(Tuning.EVENT_STREAM_RADIUS / Tuning.TILE_SIZE)
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var tile := centre + Vector2i(dx, dy)
				if not pool.has(tile):
					continue
				var offset := _map.tile_to_world(tile) - at
				var along := offset.dot(heading)
				if along <= 0.0 or offset.length() > Tuning.EVENT_STREAM_RADIUS \
						or absf(offset.cross(heading)) > _STREET_HALF_WIDTH:
					continue
				# Out of her view, the whole of what it draws: a thing created at once is placed past
				# the view's own edge (`Offscreen.boundary()`'s rule).
				if could_be_in_her_view(def, _map.tile_to_world(tile), at):
					continue
				var band := int(along / Tuning.TILE_SIZE)
				if not by_distance.has(band):
					by_distance[band] = []
				(by_distance[band] as Array).append(tile)
		if by_distance.is_empty():
			return _waited("no ground ahead of her on the street she is walking")
		var bands := by_distance.keys()
		bands.sort()
		var already := _walk.everything_but(besides)
		# Nearest first: a few tiles of the street at a time, so she meets it as soon as she can.
		var offered: Array[Vector2i] = []
		for band: int in bands:
			offered.append_array(by_distance[band])
			if offered.size() < _NEAREST_FIRST:
				continue
			var candidate := _accepted(def, rng, already, offered, role)
			if candidate:
				return candidate
			offered.clear()
		if not offered.is_empty():
			var candidate := _accepted(def, rng, already, offered, role)
			if candidate:
				return candidate
		return _waited("every site ahead of her on her street broke a placement rule")

	## Whether any of what `def` draws, standing at `feet`, could be in the camera's view while she
	## stands at `her`: its footprint where it is drawn (`EventFootprints.footprint_of()`, a van's
	## reaching 56.5px up from its feet and 28.5px down) against the 640x360 view round her
	## (`Tuning.VIEW_HALF_EXTENT`), grown on every side by the camera's lead
	## (`Stroller.CAMERA_LOOK_AHEAD` along her facing, `Stroller.OBLIQUE_Y` of it up or down), since
	## the lead eases toward a new facing over a turn, and by a tile to spare.
	static func could_be_in_her_view(def: EventDef, feet: Vector2, her: Vector2) -> bool:
		var box := EventFootprints.footprint_of(def)
		var drawn := Rect2(feet + box.position, box.size) if box.has_area() \
				else Rect2(feet, Vector2.ZERO)
		var lead := Vector2(Stroller.CAMERA_LOOK_AHEAD,
				Stroller.CAMERA_LOOK_AHEAD * Stroller.OBLIQUE_Y) + Vector2.ONE * Tuning.TILE_SIZE
		var view := Rect2(her - Tuning.VIEW_HALF_EXTENT - lead,
				(Tuning.VIEW_HALF_EXTENT + lead) * 2.0)
		return view.intersects(drawn, true)

	## **Day 6's man shouting is sited the same way**, though he is no wall: the rigged bag draws his
	## marble so she meets him (olive-koala, statement 2: "guaranteed to encounter a yeller in the
	## next three events"), and the route band of the branch she is walking lies past her walk — a
	## branch she leaves, or 1,300px and more ahead — where the street she is on offers him within the
	## streaming radius, in the world at once.
	const _MET_ON_HER_STREET := "homeless_yeller"
	## How far either side of her line of travel `ahead_on_her_street()` looks: the street she is on,
	## from her sidewalk to the far kerb, and no further — a block's frontage is past it.
	const _STREET_HALF_WIDTH := 5.0 * Tuning.TILE_SIZE
	## How many tiles of ground `ahead_on_her_street()` offers `_best_of()` at a time, nearest first.
	const _NEAREST_FIRST := 8

	## `_best_of()` over `offered` with the day's own ground, corridor, protected calm and doors: the
	## acceptance `ahead_of()` gives a site.
	func _accepted(def: EventDef, rng: RandomNumberGenerator, already: Array[Planned],
			offered: Array[Vector2i], role: GameEnums.BlockerRole) -> Planned:
		return EventScheduler._best_of(def, rng, _map, offered, role, already, _ground,
				_leave_alone, _corridor, _walk.doors(), [], _verdicts_for_an_ask())

	## A placement for `def` among `offered`, by `EventScheduler._best_of()` against the walk's plans
	## with the day's own ground, corridor, protected calm and doors — the acceptance every row the day plans
	## gets, over a pool the caller chose: day 11's mast queued near her
	## (`EventManager.queue_a_mast()`). Null when nothing offered passes. `null` rather than the
	## roomiest of a refused pool: `_best_of()` already answers with nothing for a pool where every
	## tile is illegal, and with the roomiest only among legal ones.
	func among(def: EventDef, rng: RandomNumberGenerator, offered: Array[Vector2i]) -> Planned:
		if offered.is_empty():
			return null
		return EventScheduler._best_of(def, rng, _map, offered, EventScheduler.role_for(def, _day),
				_walk.everything_but(), _ground, _leave_alone, _corridor, _walk.doors(), [],
				_verdicts_for_an_ask(false))

	## How far from where she finished the day a dusk placement has to be: the streaming radius, so
	## the site is ground she was never near enough to have it exist in front of her.
	const DUSK_CLEAR_OF_HER := Tuning.EVENT_STREAM_RADIUS

	## A placement for `def` **away from her and off the day's routes**, for the one case a walk can
	## end without the guarantee having been met: a day 3 she wins on which every siting was refused.
	##
	## *"I agree with the fire fix"* (PLAYTEST-121). The row's only day is day 3 and it is spent when
	## it enters the world, so a day she wins while it waited would leave the run with no fire, no
	## scar and no burnt shell — and the shell is what day 8's task goes to, and what the city
	## remembering day 3 is made of. So the day lights it at dusk instead.
	##
	## **The same acceptance rules, chosen once, nothing repaired.** It is `_best_of` over the day's
	## own ground with the day's own corridor, doors and protected calm. It is lit and taken out of
	## the world again at once, so nothing it leaves stands in anybody's way.
	##
	## **Off her path** means both halves of what that can mean: not within `DUSK_CLEAR_OF_HER` of
	## where she finished, so nothing is lit where she could have seen it, and not on ground the
	## day's routes run along, so the street she actually walked is not the one that burns. The
	## second bends and the first does not — the fallback is a site merely away from her: a run that
	## owes a fire and has nowhere ideal to put it should still have its fire.
	func off_her_path(def: EventDef, rng: RandomNumberGenerator, besides: Planned,
			away_from: Vector2) -> Planned:
		var role := EventScheduler.role_for(def, _day)
		var clear_of_the_routes: Array[Vector2i] = []
		var merely_away: Array[Vector2i] = []
		for tile in EventScheduler.open_ground_for(def, _map, _ground, -1,
				holds_the_home_streets):
			if _map.tile_to_world(tile).distance_to(away_from) < DUSK_CLEAR_OF_HER:
				continue
			merely_away.append(tile)
			if not _corridor.carries_a_route(tile):
				clear_of_the_routes.append(tile)
		var already := _walk.everything_but(besides)
		for offered in [clear_of_the_routes, merely_away]:
			if offered.is_empty():
				continue
			var candidate := EventScheduler._best_of(def, rng, _map, offered, role, already,
					_ground, _leave_alone, _corridor, _walk.doors(), [], _verdicts_for_an_ask(false))
			if candidate:
				return candidate
		return null

	## Every cell of the day's route tree ahead of her along the branch she is walking, as
	## `cell -> how far she walks down the route to reach it`, out to `limit` pixels —
	## `_the_way_she_is_going()`, for a caller that sites something other than a catalogue row on her
	## way: day 11's market, gone before she gets there (`ResistanceHappenings`). `cell_centre()`
	## says where a cell is.
	func cells_ahead(at: Vector2, heading: Vector2, limit: float) -> Dictionary:
		return _the_way_she_is_going(at, heading, limit)

	## The world centre of a route cell `cells_ahead()` names.
	func cell_centre(cell: Vector2i) -> Vector2:
		return _cell_centre(_map, cell)

	## Records why an attempt placed nothing and answers with the nothing. See `waits`.
	func _waited(reason: String) -> Planned:
		waits[reason] = int(waits.get(reason, 0)) + 1
		return null

	## Whether `position` is still somewhere ahead of her along the branch she is walking — the
	## question `EventDirector._is_no_longer_on_her_way()` asks of a placement already made, once a
	## second, to find the fire she left behind on a fork she did not take.
	##
	## **Ahead by any distance, not inside the siting band.** She is walking toward it, so the
	## distance shrinks with every step; asking the band again would move a fire she is about to
	## reach.
	##
	## **True when the answer cannot be had.** Off the tree — a park cut, an alley, a thinned seal —
	## there is no branch to be ahead on, and the honest answer there is to leave the placement alone
	## rather than to re-site it for a corner she is cutting.
	func still_ahead_of(at: Vector2, heading: Vector2, position: Vector2) -> bool:
		var ahead := _the_way_she_is_going(at, heading, INF)
		if ahead.is_empty():
			return true
		return ahead.has(_cell_of(position))

	## Every cell of the day's route tree that lies ahead of `at` along the branch she is walking, as
	## `cell -> how far she walks down the route to reach it`, out to `limit` pixels.
	##
	## Empty when she is not standing on the tree at all, which is a real answer rather than a
	## failure: a route is the ground she is offered, and she is allowed to be off it.
	##
	## **Which way is "ahead" is read off her heading against the route itself**, not assumed to be
	## outbound. A route runs from the calm area to the doorstep (`RouteTree.Branch.routes`), so the
	## walk out is toward the head of the array and the walk home is toward its tail, and the one that
	## agrees with the direction she is actually travelling is the one taken. At a corner both
	## neighbours can be off her heading; the better of the two is still the way the route goes, which
	## is what puts the site round the corner she is about to turn.
	func _the_way_she_is_going(at: Vector2, heading: Vector2, limit: float) -> Dictionary:
		var found := {}
		if not _tree or not _tree.grid:
			return found
		var her_tile := _map.world_to_tile(at)
		if _tree.branches_on(her_tile).is_empty():
			return found
		var her_cell := _tree.grid.cell_of(_tree.grid.node_at(her_tile))
		for branch in _tree.branches:
			for route: Array in branch.routes:
				var index := route.find(her_cell)
				if index < 0:
					continue
				var step := _onward_from(route, index, heading)
				if step == 0:
					continue
				var travelled := 0.0
				var from := at
				var i := index + step
				while i >= 0 and i < route.size():
					var cell: Vector2i = route[i]
					var centre := _cell_centre(_map, cell)
					travelled += from.distance_to(centre)
					if travelled > limit:
						break
					from = centre
					if not found.has(cell) or travelled < float(found[cell]):
						found[cell] = travelled
					i += step
		return found

	## Which way along `route` from `index` agrees with the direction she is travelling: `-1` toward
	## the calm area, `+1` toward the doorstep, or `0` where the route has no neighbour to go to at
	## all (a route one cell long, which is a calm area on the doorstep's own street).
	##
	## **Asked over `_ONWARD_LOOKAHEAD` cells rather than the next one**, because a route is a
	## loop-erased walk and its next step is as often sideways as onward: a single-cell tangent flips
	## from one direction to the other at every wiggle, so a placement would read as ahead of her on
	## one frame and behind her on the next. Looking a block down each way asks the question the
	## walk is actually about — which end of this route is she heading for.
	const _ONWARD_LOOKAHEAD := 8

	func _onward_from(route: Array, index: int, heading: Vector2) -> int:
		var here := _cell_centre(_map, route[index])
		var step := 0
		var best := -INF
		for candidate in [-1, 1]:
			var i: int = clampi(index + candidate * _ONWARD_LOOKAHEAD, 0, route.size() - 1)
			if i == index or (i - index) * candidate < 0:
				continue
			var toward: Vector2 = _cell_centre(_map, route[i]) - here
			if toward.length_squared() < 1.0:
				continue
			var score := toward.normalized().dot(heading)
			if score > best:
				best = score
				step = candidate
		return step

	## The tiles `def` may stand on that are on one of `ahead`'s cells, no more than `far` down the
	## route from her and no less than `near` away across the block — see `ahead_of()` for why the
	## two ends of the band are measured differently.
	##
	## The cells are asked for their tiles rather than the ground pool being scanned for its cells,
	## which is what keeps a refused attempt off the frame budget: a window is a few dozen cells and
	## the pool is every sidewalk in the city.
	func _its_ground_on(def: EventDef, ahead: Dictionary, at: Vector2, near: float,
			far: float) -> Array[Vector2i]:
		var pool := _ground_as_a_set(def)
		var a_mast := def.role == EventDef.Role.MAST
		var offered: Array[Vector2i] = []
		for cell: Vector2i in ahead:
			if float(ahead[cell]) > far:
				continue
			for dy in ReachabilityGrid.CELL:
				for dx in ReachabilityGrid.CELL:
					var tile: Vector2i = cell * ReachabilityGrid.CELL + Vector2i(dx, dy)
					if not pool.has(tile):
						continue
					# **A cell is not always one piece.** `ReachabilityGrid` splits a cell into a
					# node per connected component of it, and a route carries nodes — so a cell the
					# route runs through can hold a second node, on the other side of a wall, that
					# the route never touches. The tree's own answer for the tile is what decides.
					if _tree.branches_on(tile).is_empty():
						continue
					if _map.tile_to_world(tile).distance_to(at) < near:
						continue
					if a_mast and not _a_mast_may_stand(tile):
						continue
					offered.append(tile)
		return offered

	## **A mast is offered only ground a mast site would be** (`MastSites.is_eligible()`: off the
	## home street, its field off a calm interior and off every place a region door could stand),
	## the same refusal day 11's mast near the mark is under — a mast is never on the home street
	## (M180, the masts), whichever way it is put down. Asked only of the tiles `_its_ground_on()`
	## offers, never of the whole ground: over every sidewalk and square in the city it is seconds
	## of work on the frame she reads day 11's mark. Each tile's answer is kept, and the door points
	## it measures against are computed once (`MastSites.possible_door_points()`).
	func _a_mast_may_stand(tile: Vector2i) -> bool:
		if not _mast_may_stand.has(tile):
			if _door_points.is_empty():
				_door_points = MastSites.possible_door_points(_map)
			mast_checks += 1
			_mast_may_stand[tile] = MastSites.is_eligible(_map.tile_to_world(tile), _map,
					_door_points)
		return _mast_may_stand[tile]

	## Tile -> whether a mast may stand there, for `_a_mast_may_stand()`.
	var _mast_may_stand := {}
	## Where a region door could ever stand, for `_a_mast_may_stand()`; empty until first asked.
	var _door_points := PackedVector2Array()
	## How many tiles `_a_mast_may_stand()` has asked `MastSites` about. For the test that holds the
	## cost of siting a mast on her route to the tiles it was offered.
	var mast_checks := 0

	## `open_ground_for`'s list as a set, so a cell can ask whether one of its four tiles is in it.
	##
	## **The precinct weighting is dropped here and that is correct rather than a shortcut.** The
	## weighting offers a retail tile several times so the day's own roll lands there more often;
	## this roll is over the handful of tiles on one branch inside one window, where which street
	## she is walking has already decided everything the weight was for.
	##
	## **A row that pastes a front is offered the fronts, not its own side.** Its ground is the
	## `AT_THE_FRONT` lane with every rule `open_ground_for` asks of any other row, narrowed to the
	## tiles in `fronts` — in front of a blank ground-floor cell, which only the city's buildings
	## know — and nothing at all where no city handed any over.
	func _ground_as_a_set(def: EventDef) -> Dictionary:
		var at_a_front := def.on_her_way != null and def.on_her_way.at_a_front
		var side := EventDef.Pavement.AT_THE_FRONT if at_a_front else def.pavement_side
		var key := "set|%s|%d" % [def.placement, side]
		if not _ground.has(key):
			var found := {}
			for tile in EventScheduler.open_ground_for(def, _map, _ground, side,
					holds_the_home_streets):
				if not at_a_front or fronts.has(tile):
					found[tile] = true
			_ground[key] = found
		return _ground[key]

	func _cell_of(position: Vector2) -> Vector2i:
		if not _tree or not _tree.grid:
			return Vector2i(-1, -1)
		var node := _tree.grid.node_at(_map.world_to_tile(position))
		if node < 0:
			return Vector2i(-1, -1)
		return _tree.grid.cell_of(node)

	## The centre of a `ReachabilityGrid` cell in world space. A cell is two tiles square and
	## `CityMap.tile_to_world` answers the centre of a tile, so the cell's centre is half a tile
	## further along both axes than its first tile's.
	static func _cell_centre(map: CityMap, cell: Vector2i) -> Vector2:
		return map.tile_to_world(cell * ReachabilityGrid.CELL) \
				+ Vector2.ONE * (Tuning.TILE_SIZE * 0.5)

	## Does at dawn the work the first `ahead_of()` would otherwise do in the middle of a walk: the
	## scan for ground `def` may stand on and the set a cell asks about. It is a scan of the whole
	## city, which at dawn is part of a load and mid-walk is a hitch on the one beat of the day she is
	## meant to be watching. Nothing here rolls, so the day is the same day whether or not this ran.
	func prepare(def: EventDef) -> void:
		_ground_as_a_set(def)

# ------------------------------------------------- the day's locations, from the bags ---

## **Every open location of the day drawn from its view's bag** (`LocationDraw`, inbox #1185 in gentle-owl): the
## bags (`_view_bags()`) hold every recurring row the catalogue places on the map today, each as many
## times as its weight in the view (`view_weight()`), and the empty event; the day's ground answers
## which row is valid where and how much each location weighs it (`RuledLocationGround`). The rows
## other phases place have no marble: the moments she is owed (`_owe_the_moments()`), and on the day
## of the roadblock phase its row (`beside_the_routes`), the phase's alone. Answers what the draw
## placed, in the order drawn.
static func _draw_the_locations(day: int, base: int, map: CityMap, events: DayEvents,
		ground: Dictionary, leave_alone: Array[Rect2], corridor: Corridor,
		doors: PackedVector2Array, spec: DaySpec, locations: DayLocations,
		heat: int, beside_the_routes: EventDef, reach: RouteReachRule = null) -> Array[Planned]:
	var rows := {}
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, heat):
		if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
			continue
		if beside_the_routes != null and def.id == beside_the_routes.id:
			continue
		rows[def.id] = def.for_day(day)
	var bags := _view_bags(rows, day, spec, base)
	var judged := RuledLocationGround.new(day, base, map, events, corridor,
			LocationFit.new(day, map, ground, corridor, spec.holds_the_home_streets),
			StreetInvalidation.new(map, corridor, ground, leave_alone, doors,
					spec.one_notice_at_a_time, null, reach))
	var caps := _caps_of(rows, day, spec, _stream(base, CAPS_SALT)) if spec.caps_per_day else {}
	return LocationDraw.new(locations, bags, rows, judged, caps).draw_all(
			_stream(base, LOCATIONS_SALT))

## **How many of each row the day's draw may stand** (`id -> count`): its `EventDef.max_per_day`,
## and a wall-role row's times `DaySpec.wall_row_share`, so the gatehouse day holds that share of a
## wall whose cap binds as well as of one whose weight does (`view_weight()` scales the weight). A
## share of a cap that is not whole is rounded up or down on `rng`, by its fraction, so the day
## holds the share on average.
static func _caps_of(rows: Dictionary, day: int, spec: DaySpec,
		rng: RandomNumberGenerator) -> Dictionary:
	var caps := {}
	var ids := rows.keys()
	ids.sort()
	for id: String in ids:
		var def: EventDef = rows[id]
		var most := float(def.most_in_a_day())
		if role_for(def, day) == GameEnums.BlockerRole.WALL:
			most *= spec.wall_row_share
		caps[id] = floori(most) + (1 if rng.randf() < most - floorf(most) else 0)
	return caps

## The phase salt the dawn draw shuffles each street's locations on, and the bags' streams start
## from: apart from every other phase's.
const LOCATIONS_SALT := 6
## The phase salt the moments she is owed are drawn on.
const MOMENTS_SALT := 7
## The phase salt a share of a wall's cap is rounded on (`_caps_of()`).
const CAPS_SALT := 8

## **A row's weight in a view's bag**: its own `EventDef.weight` times what the view is to its role,
## the offers today's placement made per tile of the view's ground (`_copies_of()`'s gradient),
## stated per view (inbox #1185 in gentle-owl: "all possible events for that view multiplied by their
## probability/weight"):
##
## - **friction** is aimed at the routes: four times over on the route, once elsewhere
##   (`EVENT_CORRIDOR_WEIGHT`);
## - **a wall by cost, not lethal**, is pulled to the rim, four times over route-adjacent and on the
##   route, where it stands only on the sidewalk across from the route (its own ground refuses the
##   route's cells), once off the route (`EVENT_WALL_RIM_WEIGHT`);
## - **a lethal wall** is pulled past the rim: four times over off the route, once nearer
##   (`WALL_DEEP_WEIGHT`);
## - **a wall by its fit alone** reads like friction;
## - **anything else** (scenery) once everywhere;
## - a row refused an alley the routes run down (`_refuses_required_alleys()`) has no marble on the
##   route.
##
## **Every wall-role row's weight is scaled by `wall_share`** (`DaySpec.wall_row_share`), so there
## are fewer of them once the region wall stands (azure-puffin 4: "let's loosen the density of the
## hard blocking events in that case", and "fewer of all three" to a question that listed the
## wall-type events; the record bouncy-egret). `_view_bags()` counts the empty marbles against every
## wall weighed in full, so the share takes walls away rather than giving their place to the other
## rows.
##
## **Then each role is weighed per view and act**: a wall by `WALL_VIEW_SCALES`, friction by
## `FRICTION_VIEW_SCALES`, fitted so each view holds today's walls and friction.
static func view_weight(def: EventDef, view: int, day: int, wall_share: float) -> float:
	var on := view == PlacementView.View.ON_THE_ROUTE
	var off := view == PlacementView.View.OFF_THE_ROUTE
	if on and _refuses_required_alleys(def):
		return 0.0
	var times := 1.0
	var act := Tuning.act_for_day(day) - 1
	match role_for(def, day):
		GameEnums.BlockerRole.FRICTION:
			times = float(EVENT_CORRIDOR_WEIGHT) if on else 1.0
			times *= float(FRICTION_VIEW_SCALES[view][act])
		GameEnums.BlockerRole.WALL:
			if not _is_a_wall_by_cost(def):
				times = float(EVENT_CORRIDOR_WEIGHT) if on else 1.0
			elif def.hard_fail:
				times = float(WALL_DEEP_WEIGHT) if off else 1.0
			else:
				times = 1.0 if off else float(EVENT_WALL_RIM_WEIGHT)
			times *= wall_share * float(WALL_VIEW_SCALES[view][act])
		_:
			times = 1.0
	return def.drawn_as_often() * times

## **How each role weighs in each view, act by act** (`[view][act - 1]`), on top of the role's offers
## above: fitted so the walls and the friction each view holds on each act are today's
## (`tests/probes/placement_rows.gd` against main, each placed plan counted under its row's role).
## One location draws one marble, and today's rules refuse a wall on her route more often than they
## refused today's per-tile offers, so without it the walls leave her route for the ground off it:
## what her route holds is what the route decision faces. Measured, not derived, and fitted again with
## the view scales and `GROUND_WEIGHTS` whenever the draw's rules change.
const WALL_VIEW_SCALES := [
	[1.07, 1.08, 1.15, 1.14],
	[1.04, 1.01, 1.01, 1.01],
	[0.96, 0.95, 0.88, 0.89],
]
const FRICTION_VIEW_SCALES := [
	[0.96, 0.98, 1.02, 1.02],
	[1.15, 1.07, 1.11, 1.04],
	[1.03, 1.06, 1.03, 1.03],
]

## **The day's three bags** (`view -> ViewBag`): each view's rows as many times as their weight in it
## (`view_weight()`, `BAG_MARBLES_PER_WEIGHT` marbles per unit, at least one of a row the view holds),
## and empty marbles enough that the view's share of locations holding an event is the share today's
## placement gave it (`VIEW_SHARES`, measured, times `VIEW_SHARE_SCALES`, fitted; the orchestrator's
## reading of fork 5(a), open to correction). The empty marbles are counted against every wall
## weighed in full, so a spec weighing its walls by a share (`DaySpec.wall_row_share`) draws that
## share of them and the rest of the day as it was; the scales are fitted on the days as they are
## played, the gatehouse day's share included. Each on its own stream off `base`.
static func _view_bags(rows: Dictionary, day: int, spec: DaySpec, base: int) -> Dictionary:
	var bags := {}
	for view: int in [PlacementView.View.ON_THE_ROUTE, PlacementView.View.ROUTE_ADJACENT,
			PlacementView.View.OFF_THE_ROUTE]:
		var fill := {}
		var weight := 0.0
		var whole := 0.0
		for id: String in rows:
			var w := view_weight(rows[id], view, day, spec.wall_row_share)
			whole += view_weight(rows[id], view, day, 1.0)
			if w <= 0.0:
				continue
			fill[id] = maxi(1, roundi(w * BAG_MARBLES_PER_WEIGHT))
			weight += w
		var share := clampf(float(VIEW_SHARES[view][clampi(day, 1, 14) - 1])
				* float(VIEW_SHARE_SCALES[view][clampi(day, 1, 14) - 1]), 0.001, 0.95)
		fill[ViewBag.EMPTY] = maxi(1, roundi((whole / share - weight) * BAG_MARBLES_PER_WEIGHT))
		bags[view] = ViewBag.new(fill, hash("%d:%d:view-bag:%d" % [base, LOCATIONS_SALT, view]))
	return bags

## Marbles per unit of a row's weight in a view's bag: ten, so the lightest row (the square's poster
## crew, 0.03) comes in at a marble where the others keep their proportions.
const BAG_MARBLES_PER_WEIGHT := 10.0

## **Each view's share of locations holding an event, per day** (`[view][day - 1]`), as today's
## placement gave it before the bags: `tests/probes/placement_view_mix.gd`'s per-view lines on its
## eighteen cities, main's events per view over the locations the probe counts (the orchestrator's
## reading of fork 5(a): the empty marble's weight is set from today's measured count).
const ON_SHARES: Array[float] = [0.0334, 0.0313, 0.0298, 0.0353, 0.0382, 0.0387, 0.0452, 0.0464, 0.0375, 0.0417, 0.0437, 0.0422, 0.0461, 0.0461]
const ADJACENT_SHARES: Array[float] = [0.0512, 0.0537, 0.0517, 0.0566, 0.0583, 0.0631, 0.0642, 0.0618, 0.0433, 0.0420, 0.0451, 0.0463, 0.0707, 0.0485]
const OFF_SHARES: Array[float] = [0.0373, 0.0393, 0.0425, 0.0486, 0.0594, 0.0677, 0.0610, 0.0694, 0.0563, 0.0578, 0.0568, 0.0628, 0.0626, 0.0636]
const VIEW_SHARES := [
	ON_SHARES,
	ADJACENT_SHARES,
	OFF_SHARES,
]
## What each view's bag's empty marbles are set for against `VIEW_SHARES` (`[view][day - 1]`): above
## one by how many draws the view's ground or the day's rules leave without the row drawn, so the
## share placed comes out as today's. Highest on the route, where the rules keeping a route open
## refuse the most. **Per day**, since how much the rules refuse changes with the day's rows and its
## routes, and one scale for every day left the later days' routes light; what is on her route is
## what the route decision is about, so it is held at today's on each day. Fitted, not derived:
## each day's scale stepped toward today's share by `tests/probes/placement_rows.gd`, with
## `GROUND_WEIGHTS` and the walls' and friction's scales.
const ON_SHARE_SCALES: Array[float] = [4.64, 5.07, 4.91, 5.07, 5.33, 5.70, 5.12, 4.95, 6.21, 6.37, 6.54, 6.59, 7.20, 7.22]
const ADJACENT_SHARE_SCALES: Array[float] = [2.12, 2.10, 2.06, 2.07, 2.08, 2.21, 2.27, 2.26, 3.36, 3.73, 3.91, 4.03, 3.03, 4.60]
const OFF_SHARE_SCALES: Array[float] = [1.77, 1.66, 1.78, 2.06, 1.76, 1.71, 1.87, 2.08, 2.85, 2.90, 3.05, 2.91, 3.18, 3.25]
const VIEW_SHARE_SCALES := [
	ON_SHARE_SCALES,
	ADJACENT_SHARE_SCALES,
	OFF_SHARE_SCALES,
]

## **How often a row is drawn on each kind of ground** (`row id -> {Location.Kind -> weight}`),
## a weight a location of that kind scales the row's share of its view's bag by
## (`RuledLocationGround.scale()`; the player's "yes" to a group of locations per kind of ground
## and a weight per location scaling its view's bag, inbox #1185 in gentle-owl). **Why it is needed:** each
## location draws one marble, so a row whose own ground is rare (a square's few cells, an alley's
## three locations, the junction boxes) would be drawn only as often as its share of the bag times
## the few locations that take it, where today's placement picked the row by weight against the
## whole day and then found it any tile of its ground. So each row's weight on each kind of ground
## is fitted until its daily count there is today's (`tests/probes/placement_rows.gd` against main,
## eighteen seeds), the way the view scales are; a row or a kind not listed weighs one. Measured, not
## derived, and fitted again with the view scales whenever the draw's rules change.
const GROUND_WEIGHTS := {
	"abduction": {Location.Kind.SIDEWALK: 0.14, Location.Kind.JUNCTION: 91.19},
	"alley_mouse": {Location.Kind.ALLEY: 14.67},
	"alley_robbery": {Location.Kind.ALLEY: 4.46},
	"busker": {Location.Kind.OPEN: 150},
	"cafe_tables": {Location.Kind.SIDEWALK: 0.43},
	"charging_dog": {Location.Kind.SIDEWALK: 0.21, Location.Kind.OPEN: 0.78, Location.Kind.JUNCTION: 319},
	"chatting_mother": {Location.Kind.SIDEWALK: 0.25, Location.Kind.JUNCTION: 400},
	"construction": {Location.Kind.SIDEWALK: 0.49},
	"delivery_van": {Location.Kind.SIDEWALK: 1.48},
	"dog_walker": {Location.Kind.SIDEWALK: 0.82, Location.Kind.JUNCTION: 2.27},
	"homeless_yeller": {Location.Kind.SIDEWALK: 0.87, Location.Kind.OPEN: 0.57, Location.Kind.JUNCTION: 2.27},
	"ice_cream_van": {Location.Kind.SIDEWALK: 0.83},
	"leaf_blower": {Location.Kind.SIDEWALK: 0.59, Location.Kind.OPEN: 0.38, Location.Kind.JUNCTION: 1.21},
	"market_stall": {Location.Kind.SIDEWALK: 0.44, Location.Kind.OPEN: 0.34},
	"military_convoy": {Location.Kind.SECTION: 0.77, Location.Kind.JUNCTION: 1.43},
	"pigeon_flock": {Location.Kind.SIDEWALK: 0.7, Location.Kind.OPEN: 1.56, Location.Kind.JUNCTION: 6.95},
	"police_patrol": {Location.Kind.SECTION: 1.33, Location.Kind.JUNCTION: 5.54},
	"poster_crew_square": {Location.Kind.OPEN: 27.86},
	"protest": {Location.Kind.OPEN: 8.88, Location.Kind.JUNCTION: 16.89},
	"reversing_lorry": {Location.Kind.SIDEWALK: 1.46},
	"roadblock": {Location.Kind.SECTION: 2.69},
}

## A row's weight on a location of `kind` (`Location.Kind`): `GROUND_WEIGHTS`', one where it lists
## none.
static func _ground_weight(def: EventDef, kind: int) -> float:
	var weights: Dictionary = GROUND_WEIGHTS.get(def.id, {})
	return float(weights.get(kind, 1.0))

## **The moments the day owes her** (`AHEAD_OF_PLAYER` and `TOWARD_PLAYER` rows, the cat that bolts
## across, the cyclist, the loose dog): sited in front of her by the director, on its own clock and
## from its own bag (`EventDirector`; the orchestrator's reading of fork 9: a moment is not a place),
## so the day only says how many. `MOMENTS_PER_DAY` of them, as today's placement bought on that day,
## each a row drawn by weight among today's, at most its `max_per_day` where the spec keeps the caps.
static func _owe_the_moments(day: int, rng: RandomNumberGenerator, events: DayEvents, heat: int,
		caps: bool) -> void:
	var rows: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, heat):
		var mode := def.spawn_mode_on(day)
		if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
			rows.append(def)
	var owed := {}
	for _i in int(MOMENTS_PER_DAY[clampi(day, 1, 14) - 1]):
		var open: Array[EventDef] = []
		var total := 0.0
		for def in rows:
			if not caps or int(owed.get(def.id, 0)) < def.most_in_a_day():
				open.append(def)
				total += def.drawn_as_often()
		if open.is_empty():
			return
		var roll := rng.randf() * total
		var chosen: EventDef = open.back()
		for def in open:
			roll -= def.drawn_as_often()
			if roll <= 0.0:
				chosen = def
				break
		owed[chosen.id] = int(owed.get(chosen.id, 0)) + 1
		events.add(Planned.new(chosen, Vector2.INF))

## How many moments she is owed on each day (`[day - 1]`), as today's placement bought them before the
## bags (`tests/probes/placement_rows.gd` on main, eighteen seeds, rounded). Measured, not derived: a
## fixed count each day, where the fill's rolls made it vary from one city to the next.
const MOMENTS_PER_DAY: Array[int] = [23, 26, 29, 25, 26, 28, 29, 28, 28, 30, 31, 32, 32, 32]

## **The day's ground as the dawn draw asks it** (`LocationGround`): a row's event at a location,
## left out where the day's rules invalidate it, and the location's own weight.
##
## - **The event** stands on a tile of the location the row fits (`LocationFit`), tried in an order
##   of the location's own stream, and is asked of the day's rules (`StreetInvalidation`) against
##   the day's plans and what stands: the first tile with room all round, else the roomiest a rule
##   leaves valid, else none.
## - **The weight** (the player's "yes" to a weight per location, inbox #1185 in gentle-owl): four times over on a
##   precinct street (`EVENT_PRECINCT_WEIGHT`), six times over for a costly wall on the street between
##   two strands of the routes (`EVENT_WALL_GAP_WEIGHT`), and five times over for the mouse in an
##   alley beside a sack pile (`_MOUSE_PILE_EXTRA_COPIES` and one). And the mouse a location draws
##   is offered the location's tiles beside a pile first (`_beside_a_pile_first()`), so it stands by
##   the sacks where the location reaches them.
class RuledLocationGround extends LocationGround:
	var _day := 0
	var _base := 0
	var _map: CityMap
	var _events: DayEvents
	var _corridor: Corridor
	var _fit: LocationFit
	var _rules: StreetInvalidation
	var _piles := {}

	func _init(day: int, base: int, map: CityMap, events: DayEvents, corridor: Corridor,
			fit: LocationFit, rules: StreetInvalidation) -> void:
		_day = day
		_base = base
		_map = map
		_events = events
		_corridor = corridor
		_fit = fit
		_rules = rules
		for tile in GarbageSacks.alley_pile_tiles(map, day):
			_piles[tile] = true

	## Overrides LocationGround.offer.
	func offer(def: EventDef, location: Location) -> Planned:
		var fits := _fit.tiles(def, location)
		if fits.is_empty():
			return null
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%s:%s" % [_base, location.tiles(), def.id])
		for i in range(fits.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var kept := fits[i]
			fits[i] = fits[j]
			fits[j] = kept
		if def.id == EventScheduler._MOUSE_ID:
			fits = _beside_a_pile_first(fits)
		var role := EventScheduler.role_for(def, _day)
		var already := _events.placements()
		var reach_context := already.duplicate()
		reach_context.append_array(_events.standing())
		var best: Planned = null
		var best_room := -INF
		for tile in fits:
			var candidate := _fit.build(def, tile, rng)
			if not candidate:
				continue
			var room := _rules.room(candidate, role, tile, already, reach_context)
			if room == INF:
				return candidate
			if room > best_room:
				best_room = room
				best = candidate
		return best

	## Overrides LocationGround.scale.
	func scale(def: EventDef, location: Location) -> float:
		var times := 1.0
		var segment := location.segment()
		var middle := _map.world_to_tile(location.centre())
		if segment and (_map.street_kind_at(true, middle) == GameEnums.StreetKind.PEDESTRIAN
				or _map.street_kind_at(false, middle) == GameEnums.StreetKind.PEDESTRIAN):
			times *= float(EventScheduler.EVENT_PRECINCT_WEIGHT)
		if segment and EventScheduler._is_a_wall_by_cost(def) and not def.hard_fail \
				and EventScheduler.role_for(def, _day) == GameEnums.BlockerRole.WALL \
				and _corridor.is_in_a_gap(middle):
			times *= float(EventScheduler.EVENT_WALL_GAP_WEIGHT)
		if def.id == EventScheduler._MOUSE_ID and _beside_a_pile(location.tiles()):
			times *= float(EventScheduler._MOUSE_PILE_EXTRA_COPIES + 1)
		return times * EventScheduler._ground_weight(def, location.kind())

	## Overrides LocationGround.stand.
	func stand(plan: Planned) -> void:
		_events.add(plan)

	## `tiles` with those within `_MOUSE_PILE_ADJACENCY` of a sack pile first, each half in the order
	## it was handed.
	func _beside_a_pile_first(tiles: Array[Vector2i]) -> Array[Vector2i]:
		var beside: Array[Vector2i] = []
		var rest: Array[Vector2i] = []
		for tile in tiles:
			if _beside_a_pile(Rect2i(tile, Vector2i.ONE)):
				beside.append(tile)
			else:
				rest.append(tile)
		beside.append_array(rest)
		return beside

	func _beside_a_pile(tiles: Rect2i) -> bool:
		for y in range(tiles.position.y - EventScheduler._MOUSE_PILE_ADJACENCY,
				tiles.end.y + EventScheduler._MOUSE_PILE_ADJACENCY):
			for x in range(tiles.position.x - EventScheduler._MOUSE_PILE_ADJACENCY,
					tiles.end.x + EventScheduler._MOUSE_PILE_ADJACENCY):
				if _piles.has(Vector2i(x, y)):
					return true
		return false

## **An authored scene's row at the location its tile names**, or null with the reason appended to
## `why`. A recipe keeps its data: `at` names the tile, and so the location holding it
## (`DayLocations.holding()`, of the ground under it), which is asked once, as a dawn phase asks a
## location: the tile is one the location takes for the row (`LocationFit`), the candidate built
## there on a private stream (`route_seed`, so unrelated actors cannot move a required path), and the
## day's rules allow it (`StreetInvalidation`, the calm `calm` says she has not used left alone). No
## tries and no fallback: a location that does not take the row fails the recipe loudly, with the
## reason, rather than placing it somewhere else (the orchestrator's reading, open to the player's
## overturn). `locations` is the day's, laid out once for the whole recipe; laid out here for a
## caller that hands none.
static func recipe_placement(def: EventDef, day: int, map: CityMap, at: Vector2,
		route_seed: int, already: Array[Planned], corridor: Corridor,
		doors: PackedVector2Array, calm: CalmAreas, standing: Array[Planned] = [],
		locations: DayLocations = null, why: Array[String] = []) -> Planned:
	if not def.available_on(day) or def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
		why.append("%s is not placed on the map on day %d" % [def.id, day])
		return null
	def = def.for_day(day)
	var tile := map.world_to_tile(at)
	if not map.tile_to_world(tile).is_equal_approx(at):
		why.append("%s is not at the middle of a tile" % def.id)
		return null
	if locations == null:
		locations = DayLocations.lay_out(map, corridor if corridor else Corridor.of(null))
	var location := locations.holding(tile, map.tile_at(tile))
	if location == null:
		why.append("no location holds tile %s" % tile)
		return null
	var ground := {}
	var fit := LocationFit.new(day, map, ground, corridor, true)
	if not tile in fit.tiles(def, location):
		why.append("the location holding tile %s does not take %s there" % [tile, def.id])
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = route_seed
	var candidate := fit.build(def, tile, rng)
	if not candidate:
		why.append("%s cannot be built on tile %s" % [def.id, tile])
		return null
	var around := already.duplicate()
	around.append_array(standing)
	var rules := StreetInvalidation.new(map, corridor, ground, calm.unused_ground(), doors, false)
	if rules.room(candidate, role_for(def, day), tile, already, around) == -INF:
		why.append("the day's rules refuse %s on tile %s" % [def.id, tile])
		return null
	return candidate

## The acceptance half of a placement: roll `EVENT_PLACEMENT_TRIES` candidates out of
## `open_candidates`, refuse the ones that break a rule that cannot bend, and answer with the first
## perfect one or the roomiest of the rest.
##
## Its one caller is the walk's sitings (`WalkSiting`): a placement made **after** dawn asks the
## dawn's questions of a narrower pool — `WalkSiting.ahead_of()` offers only the tiles of the row's own
## ground on the branch of the day's route tree she is walking — and a second copy of this list of
## rules is a second copy that would agree with it right up to the first time one of them gained a
## rule.
##
## **`standing` is what the seals and the region wall's own bodies stand as, asked only by the
## three questions below and never by the spacing.** `SealPlanner.plan_day` and `RegionPlanner.
## plan_day` both run before `build_day`, so their bodies are never in `already` — the day's own
## catalogue accumulator — and the three placement rules were therefore refusing a *second*
## catalogue row that would close a crossing, a sidewalk or a pacing beat's opening only against
## *other catalogue rows*, blind to a seal or a wall already reaching in from one street out or
## the far pavement (`docs/DECISIONS.md`, M129, "the four rules": *"the seals `SealPlanner`
## places before the scheduler runs reach crossings the rules never see, the same question one
## step out"*). This does not change what a seal or the wall stands as — neither is in
## `standing` for any reason but these three checks — so a street already sealed by design is
## unmoved; what changes is that the catalogue now declines to stack a second body onto ground a
## seal or the wall has already spent. `StreetInvalidation.room_around`'s own spacing stays asked of `already`
## alone: density is a question about today's catalogue rows, not about the day's fixed
## furniture. **A `WalkSiting` passes none** — it is spaced and checked against the walk's whole plan
## (`WalkEvents.everything_but()`), seals and the wall included, as its own `already`, so it
## already asks every question `standing` exists to add here.
##
## **Each candidate is asked of the day's rules** (`StreetInvalidation`), the same ones the dawn draw
## asks, so they are stated once; the tries and the roomiest fallback are this function's own, kept
## for its one caller, the walk's sitings (`WalkSiting`), until the walk's draws move it to the
## locations (the orchestrator's choice in placement step 3b).
static func _best_of(def: EventDef, rng: RandomNumberGenerator, map: CityMap,
		open_candidates: Array[Vector2i], role: GameEnums.BlockerRole,
		already: Array[Planned], ground: Dictionary, leave_alone: Array[Rect2],
		corridor: Corridor, doors: PackedVector2Array,
		standing: Array[Planned] = [], kept: Verdicts = null,
		reach: RouteReachRule = null) -> Planned:
	var best: Planned = null
	var best_room := -INF
	# Built once per call rather than per try: neither `already` nor `standing` changes across the
	# tries below, only which tile and which candidate is asked about.
	var reach_context: Array[Planned] = already
	if not standing.is_empty():
		reach_context = already.duplicate()
		reach_context.append_array(standing)
	# **Each candidate is judged once per call, and every try still rolls.** A pool of a few tiles
	# — `WalkSiting.ahead_of()` often offers one — is rolled `EVENT_PLACEMENT_TRIES` times, and the
	# rule chain against every plan of the day is the same question each time the same tile and
	# path come up, so its verdict is kept here, keyed by both. The roll and `build_placement`'s
	# own draws still happen on every try, in the same order, so the stream, and with it every
	# placement, is what it would be if each try asked again.
	#
	# `kept`, when a caller hands one in, is where the verdicts are kept, and it may outlive the
	# call: `WalkSiting`'s keeps them for one look, shared by every copy the look asks about. It is
	# that caller's to drop whenever what a verdict reads changes — see `WalkSiting.begin_look()`.
	var verdicts: Verdicts = kept if kept else Verdicts.new()
	# The day's rules, the same ones the dawn draw asks (`StreetInvalidation`), so they are stated once.
	var judge := StreetInvalidation.new(map, corridor, ground, leave_alone, doors, false, null,
			reach)
	for _attempt in EVENT_PLACEMENT_TRIES:
		var tile: Vector2i = open_candidates[rng.randi_range(0, open_candidates.size() - 1)]
		var candidate := build_placement(def, map, tile, rng)
		if not candidate:
			continue
		# The row, its role, the tile and the path built on it are the whole of what a candidate
		# is: its position and facing are the tile's own.
		var key := [def.get_instance_id(), role, tile, candidate.path]
		var verdict := verdicts.of(key)
		if verdict.is_empty():
			var room := judge.room(candidate, role, tile, already, reach_context)
			verdict = [candidate.role, room]
			verdicts.keep(key, verdict)
		candidate.role = verdict[0]
		var judged: float = verdict[1]
		if judged == INF:
			return candidate
		if judged > best_room:
			best_room = judged
			best = candidate
	# Nothing comes back when every candidate broke a rule that does not bend — a lethal event
	# with no clear ground, or a full pavement. The caller re-rolls; a scripted event that
	# cannot be placed simply does not happen, which is the right failure direction.
	return best

## **Where `_best_of()` keeps the verdicts of the candidates it judges**: for each, what the day's
## rules (`StreetInvalidation.room()`) answered, as `[the role it set, the room it answered]`, under the key
## `_best_of()` asks by (the row, its role, the tile and the path built on it). `_best_of()` asks
## it for a candidate's verdict before judging the candidate, and gives it each verdict it judges.
## A call keeps its own unless it is handed one; a `WalkSiting` hands every call it makes the store
## it was built with, which keeps verdicts for one ask, or for one look (`WalkSiting.begin_look()`).
## A kept verdict is the answer only while what it read stands, so whoever holds the store drops
## them (`forget()`) the moment that stops being true.
class Verdicts extends RefCounted:
	var _kept := {}

	## The verdict kept for `key`, or an empty array when there is none and the candidate is to
	## be judged.
	func of(key: Array) -> Array:
		return _kept.get(key, [])

	## Keeps `verdict`, just judged, for `key`.
	func keep(key: Array, verdict: Array) -> void:
		_kept[key] = verdict

	## Drops every verdict kept.
	func forget() -> void:
		_kept.clear()

## The tiles an event of this kind may stand on today, worked out once and kept for the rest of
## the day's planning.
##
## The answer is two passes over every tile of the right type, and a sidewalk is five thousand of
## them — while the dawn draw asks the question for every row a location weighs, hundreds of times on
## a day. Nothing it depends on can move inside one `build_day`: the grid was
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
static func ground_for(def: EventDef, map: CityMap, ground: Dictionary,
		corridor: Corridor = null, role := GameEnums.BlockerRole.NONE,
		from_the_door := true) -> Array[Vector2i]:
	var base := open_ground_for(def, map, ground, -1, from_the_door)
	if not corridor or role == GameEnums.BlockerRole.NONE:
		return base
	# The key is the *question*, and `hard_fail` is part of it since the wall band gained a
	# gradient: two lethal rows share an answer and a lethal row and a costly one no longer do.
	# `has_a_spread` joined it for the same reason M64 added it to `open_ground_for`'s own key: a
	# corner is off the question for two rows sharing every other answer only when one of them
	# actually has an orientation to be wrong about on it. Without this a plain silhouette processed
	# first quietly hands its unfiltered `base` to a spread row asking the identical other four
	# questions, and the corner refusal never runs at all. `_is_a_wall_by_cost` joined for the same
	# reason: two rows sharing every other answer can still disagree about the rim pull, and a
	# cached list keyed without it would hand a fit-only wall's ground to a cost wall sharing its
	# placement, pavement side and spread shape, or the reverse.
	var by_cost := _is_a_wall_by_cost(def)
	var key := "%s|%d|%d|%s|%s|%s%s" % [def.placement, def.pavement_side, role,
			def.hard_fail, def.has_a_spread, by_cost, "" if from_the_door else "|no door"]
	if ground.has(key):
		return ground[key]
	var aimed: Array[Vector2i] = []
	var refuses_required_alleys := _refuses_required_alleys(def)
	for tile in base:
		# **No robber stands in an alley she has to walk down.** An alley the day's corridor runs
		# through — `corridor.depth(tile) == 0`, the `INSIDE` band — is ground she has no way
		# around, and `alley_robbery`'s own design note is that "a robbery has no telegraph you
		# could see coming, and it never did": a risk with no warning is only fair on ground she
		# chose to enter. See `docs/DECISIONS.md`, M64, "and no robber stands in an alley she has to
		# walk down."
		if refuses_required_alleys and corridor.depth(tile) == 0:
			continue
		for _copy in _copies_of(tile, corridor, role, def.hard_fail, by_cost):
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

## `alley_mouse`'s own preference: an alley location beside a garbage-sack pile
## (`GarbageSacks.alley_pile_tiles()`, within `_MOUSE_PILE_ADJACENCY` tiles) weighs the mouse
## `_MOUSE_PILE_EXTRA_COPIES` and one times over (`RuledLocationGround.scale()`), and the mouse it
## draws is offered its tiles beside the pile first.
const _MOUSE_ID := "alley_mouse"
const _MOUSE_PILE_ADJACENCY := 1
const _MOUSE_PILE_EXTRA_COPIES := 4

## The day's copy of `StreetTrees.footprint_tiles()`, kept in the same `ground` dictionary every
## other answer in this file is cached in and under a key no `"%s|%d"` placement question can
## collide with. One scan of the city's pits per day rather than one per candidate row: the trees
## are fixed for the run, so nothing inside one `build_day` can move them.
const TREE_TILES_KEY := "street tree footprints"

static func _street_tree_tiles(map: CityMap, ground: Dictionary) -> Dictionary:
	if not ground.has(TREE_TILES_KEY):
		ground[TREE_TILES_KEY] = StreetTrees.footprint_tiles(map)
	return ground[TREE_TILES_KEY]

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
## **Anything `EventDef.has_a_spread` is refused a corner outright**, cached under its own
## key so the un-narrowed list stays shared with everything that has no orientation to get wrong on
## one — a yeller or a busker keeps every tile a plain sidewalk scan already found. This is an
## exclusion from the candidate pool rather than a repair after the fact, the same shape a barrier
## beside a calm area's access street is refused in rather than moved out of afterwards.
##
## **A row that burns its front is refused the power station's** (`_burns_its_front()`): the
## station's facade is drawn whole whatever its `Building.condition` says, its transformer yard
## has no wall at all for the burnt building's red arrow to end on, and it is the last night's
## building. Cached under its own key, so a poster crew asking for the same `AT_THE_FRONT` lane
## keeps the station's front.
##
## `from_the_door` is the spec's home-street rule (`DaySpec.holds_the_home_streets`): whether she
## sets off from the home's front door, whose street nothing stands on
## (`_the_street_she_starts_on()`). Every day does; the escape comes out of the service exit on the
## side of the block and never uses that door, the reason its seals spare the street she stands in
## rather than the home street (`RouteSource.street_it_starts_in()`, `docs/CITY.md`, "The escape").
static func open_ground_for(def: EventDef, map: CityMap, ground: Dictionary,
		side: int = -1, from_the_door := true) -> Array[Vector2i]:
	var wanted_side := def.pavement_side if side < 0 else side
	var burns := _burns_its_front(def)
	var key := "%s|%d%s%s" % [def.placement, wanted_side, "|burns" if burns else "",
			"" if from_the_door else "|no door"]
	if not ground.has(key):
		var doorstep := _the_street_she_starts_on(map) if from_the_door else Rect2i()
		var trees := _street_tree_tiles(map, ground)
		# In tiles: `CityMap.power_station` names the station's two blocks.
		var station := CityMap.blocks_tile_rect(map.power_station) \
				if burns and map.has_power_station() else Rect2i()
		var open: Array[Vector2i] = []
		for type in def.placement:
			for candidate in map.tiles_of_type(type as GameEnums.TileType):
				# A closed street is not somewhere anyone can get to, so it is not somewhere an event
				# can usefully happen: the player would never see it and the day would hold an
				# event for nothing. `is_held_at` refuses the same ground for a street that is
				# not closed but is still spoken for — a hard seal's segment, a region wall or door,
				# or a segment bordering the home block (`CityMap.held`) — and
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
						or station.has_point(candidate + Vector2i.UP) \
						or not _wants_this_side(def, map, candidate, wanted_side):
					continue
				open.append(candidate)
				if map.street_kind_at(true, candidate) == GameEnums.StreetKind.PEDESTRIAN \
						or map.street_kind_at(false, candidate) == GameEnums.StreetKind.PEDESTRIAN:
					for _extra in EVENT_PRECINCT_WEIGHT - 1:
						open.append(candidate)
		ground[key] = open
	if not def.has_a_spread:
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
## `RouteSidewalkRule._leaves_the_routes_sidewalk_open`.
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
##
## **A wall by fit alone skips the gradient entirely and reads like friction beyond the one
## refusal every wall keeps** — see `_is_a_wall_by_cost`'s own doc for the player's own answer on
## this. `by_cost` is that question, asked once by the caller rather than re-derived per tile: a
## silent, narrow body earns no distance-before-she-commits pull, so it is weighted onto an
## on-corridor tile exactly as `FRICTION` is, and left at one copy everywhere else — never pulled
## to the rim, never pushed past it. The zero-copies refusal above still applies to it first, since
## that is the one consequence of being a wall this decision does not touch.
static func _copies_of(tile: Vector2i, corridor: Corridor, role: GameEnums.BlockerRole,
		lethal := false, by_cost := true) -> int:
	var away := corridor.depth(tile)
	match role:
		GameEnums.BlockerRole.WALL:
			if corridor.carries_a_route(tile):
				return 0
			if not by_cost:
				return EVENT_CORRIDOR_WEIGHT if away == 0 else 1
			if lethal:
				return WALL_DEEP_WEIGHT if away >= 2 else 1
			if away > 1:
				return 1
			return EVENT_WALL_RIM_WEIGHT \
					* (EVENT_WALL_GAP_WEIGHT if corridor.is_in_a_gap(tile) else 1)
		GameEnums.BlockerRole.FRICTION:
			return EVENT_CORRIDOR_WEIGHT if away == 0 else 1
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

## Whether `def` leaves the building it stands against burnt (its scar is the one `City` draws as
## a burnt frontage), so the front it catches on has to be one that can be drawn burnt.
static func _burns_its_front(def: EventDef) -> bool:
	return def.aftermath.scar == City.BURNT_FRONTAGE_SCAR

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
##
## `AT_THE_FRONT` is the south face's own lane, the one side a front is drawn on: `burning_building`'s
## own `pavement_side`, since the building it catches on is drawn burnt afterwards, and what
## `WalkSiting` asks, through `side`, for a row whose `OnHerWay.at_a_front` is set. **The tile behind has to be
## on the map as well as read `BUILDING`**, because `CityMap.tile_at()` reads anything off the map
## as `BUILDING`: without the bounds check the north sidewalk of the map's northmost street, with
## nothing behind it but the edge of the world, passes as a front. `side` is typed `int` for the
## cross-script enum reason the **godot** skill names; `-1` means the row's own.
static func _wants_this_side(def: EventDef, map: CityMap, tile: Vector2i, side: int = -1) -> bool:
	var wanted := def.pavement_side if side < 0 else side
	if wanted == EventDef.Pavement.ANY:
		return true
	var inward := map.pavement_inward(tile)
	if inward == Vector2i.ZERO:
		return false
	if wanted == EventDef.Pavement.AT_THE_FRONT:
		return inward == Vector2i.UP and map.in_bounds(tile + inward) \
				and map.tile_at(tile + inward) == GameEnums.TileType.BUILDING
	if wanted == EventDef.Pavement.AT_THE_KERB:
		# The kerb lane is the one whose *road* side is actually road: on a two-tile pavement
		# that is the inner of the two, and asking the tiles rather than the offset keeps it true
		# of a crossing, a closed carriageway, or whatever a later milestone paints there.
		return map.is_street(tile - inward) \
				and map.tile_at(tile - inward) != GameEnums.TileType.SIDEWALK
	return inward.y == 0 \
			and map.tile_at(tile + inward) == GameEnums.TileType.BUILDING

## One candidate placement on a given tile, with its route built if it moves.
static func build_placement(def: EventDef, map: CityMap, tile: Vector2i,
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
			var crossing := _cross_street_path(map, tile)
			return null if crossing.is_empty() else Planned.new(def, at, crossing)
		EventDef.PathMode.ALONG_STREET:
			var route := _along_street_path(map, tile, def, rng)
			# Nowhere to go from here; a "mobile" event that stands still is worse than
			# another roll of the dice.
			return null if route.is_empty() else Planned.new(def, at, route)
		_:
			return Planned.new(def, at)

## The placement a recipe or a planner puts at one site, or null: the candidate `build_placement()`
## sites on `tile` that `StreetInvalidation.room_around()` leaves room for among `already`. The one entry point a
## planner and `SceneRecipeRuntime` share: an authored scene's row keeps the day's spacing. The
## scheduler's own loop (`_best_of()`) does not call it: a day asks the day's rules
## (`StreetInvalidation`), which ask `StreetInvalidation.room_around()` among many more rules and set the candidate's
## role, so routing the loop through this would change what the day places.
static func place_at(def: EventDef, map: CityMap, tile: Vector2i, rng: RandomNumberGenerator,
		already: Array[Planned]) -> Planned:
	var candidate := build_placement(def, map, tile, rng)
	if not candidate or StreetInvalidation.room_around(candidate, already) == -INF:
		return null
	return candidate

# ------------------------------------------------- a path never has to cost (M129) ---

## **Whether a row's own numbers leave no way past it along a sidewalk it may stand on** — the
## passability reading of a wall, beside the cost one. *(PLAYTEST-77: "how is market stall a
## friction? you can't walk through it"; "a wall is also when you physically cannot walk through".)*
##
## A sidewalk is two lanes of tile, and a row stands in one of them, so the only line past it is the
## other lane — one tile across, which `Planned.denies()` reads as free while the row's reach is under it.
## What the reach is, is the whole point: **the body plus the ground it charges for**
## (`EventDef.line_reach()`), not the body alone. A café whose tables are 24px across but which bills
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
## mobile row that does not pace — are outside this too, by asking `EventDef.has_a_line_to_avoid()` rather
## than repeating the list.
static func leaves_no_line_along_a_sidewalk(def: EventDef) -> bool:
	if not def.placement.has(GameEnums.TileType.SIDEWALK):
		return false
	if not def.has_a_line_to_avoid():
		return false
	if def.reaches_the_far_lane():
		return true
	return _closes_the_band_by_its_own_placement(def)

## **Whether the row's own body, stood exactly where `pavement_side` puts it, leaves no edge-to-edge
## gap of `RouteSidewalkRule.HER_LANE_CLEARANCE` anywhere across the sidewalk band** — a second, physical reading of
## "leaves no way past it" beside `EventDef.line_reach()`'s cost-based one above. *(PLAYTEST-94, 2026-09-19:
## "I still get hard walls on the side of the sidewalk that is on the path -- how can this be so hard
## to do correctly?")* The cost clause asks what a row bills a passer-by for being near it; this asks
## whether a passer-by has anywhere left to stand at all, and the two can disagree: `delivery_van`
## is silent and its 22px `obstructs_radius` stays under the far-lane distance (`EventDef._THE_FAR_LANE`, one tile, 32px), so the cost clause
## reads it as friction — but pinned `AT_THE_KERB`, 16px in from the kerb edge, it leaves only
## `(SIDEWALK_WIDTH * TILE_SIZE - TILE_SIZE * 0.5) - 22 = 26px` to the frontage, narrower than the
## 28px she needs, which `tests/test_events.gd`'s `_test_a_kerbed_body_still_pins_the_frontage`
## already measures by hand for this one row. Read off `obstructs_radius` and `pavement_side` rather
## than off an id, so the next row this narrow is caught the same way without anybody adding it to a
## list — and a row whose reach already clears the far-lane distance (`EventDef.reaches_the_far_lane()`) never reaches this, so nothing already a wall
## is asked twice.
static func _closes_the_band_by_its_own_placement(def: EventDef) -> bool:
	var reach := def.obstructs_radius
	if reach <= 0.0:
		return false
	var band := float(Tuning.SIDEWALK_WIDTH) * Tuning.TILE_SIZE
	var pos := _band_offset_of(def.pavement_side, band)
	var near_gap := pos - reach
	var far_gap := band - (pos + reach)
	return maxf(near_gap, far_gap) < RouteSidewalkRule.HER_LANE_CLEARANCE

## Where `pavement_side` stands a body across a sidewalk band, as an offset from the kerb edge —
## the same geometry `EventFootprints._centred_on_the_pavement_band()` and its kerb/frontage
## exemptions produce, read here off the def alone because a role is decided before any tile exists
## to ask the map about. `pavement_side` is typed `int` rather than `EventDef.Pavement`: a
## cross-script enum parameter does not always match the type Godot infers for a value read off
## another script's property, so the wider type is the one that always parses.
static func _band_offset_of(pavement_side: int, band: float) -> float:
	match pavement_side:
		EventDef.Pavement.AT_THE_KERB:
			return Tuning.TILE_SIZE * 0.5
		EventDef.Pavement.AGAINST_THE_BUILDING:
			return band - Tuning.TILE_SIZE * 0.5
		_:
			return band * 0.5

## The clause as the **role** asks it, which is of a def with no tile yet — so a pacing row is not
## answered here at all.
##
## *(PLAYTEST-77, 2026-09-19: "yeller is something you can time. it stays on the route"; "if the
## yeller paces across a crosswalk then there is a way to avoid them. if they stay on the segment
## for the whole time with no side route then there is no way to avoid them. distinguish those
## cases when deciding whether the yeller is a wall".)* Whether a man walking a beat can be got
## past is a fact about **where his beat runs**, not about his field: the same numbers are a wall in
## the middle of a segment and a thing to time at a junction. `StreetInvalidation._a_pacing_beat_walls_a_sidewalk`
## asks it of the candidate, as a placement judges it, where the beat actually exists.
static func _takes_a_whole_sidewalk(def: EventDef) -> bool:
	return not def.paces and leaves_no_line_along_a_sidewalk(def)

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
	# Stop short of anything that stops the row (`CityMap.passable()`, as it moves: a closure's
	# barrier, a seal, a body standing today) rather than walking or driving through it — and short
	# of a calm zone's absorbed corridor as well. A corridor that ends in a park is not a corridor a
	# delivery van can drive down, and unlike a closure there is nothing there to hit: the route
	# would simply cross the grass.
	var from_a_street := map.is_street(tile)
	var mover := EventInstance.mover_for(def)
	for step in range(1, length + 1):
		var next := tile + along * step
		if not map.passable(next, mover) or (from_a_street and not map.is_street(next)):
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
## path is perpendicular to the road it starts from: out from the tile each way, at most a street's
## width, as far as a figure on foot may stand (`CityMap.passable()`), so it comes out of one kerb
## and goes into the other and never starts or ends inside a lot. Empty, so the candidate is
## refused, where the tile is not one a figure on foot may stand on or nothing either side of it is.
static func _cross_street_path(map: CityMap, tile: Vector2i) -> PackedVector2Array:
	var vertical_road := CityMap.corridor_offset(tile.x) >= 0
	var across := Vector2i.RIGHT if vertical_road else Vector2i.DOWN
	var reach := Tuning.STREET_WIDTH
	var mover := Mover.on_foot()
	var ends: Array[Vector2i] = []
	for way: Vector2i in [-across, across]:
		var end := tile
		for step in range(1, reach + 1):
			if not map.passable(tile + way * step, mover):
				break
			end = tile + way * step
		ends.append(end)
	if ends[0] == ends[1] or not map.passable(tile, mover):
		return PackedVector2Array()
	return PackedVector2Array([map.tile_to_world(ends[0]), map.tile_to_world(ends[1])])

# ---------------------------------------------------------------- park rules ---

## The rect of a calm block's actual calm ground, falling back to the whole lot. The same question
## `ClosurePlanner.CalmArea.rect` answers, and the same function now — a courtyard's calm is its
## court alone, and there is exactly one place that says so.
static func _calm_rect(map: CityMap, block: Vector2i) -> Rect2i:
	return ClosurePlanner.calm_area_rect(map, block)

## Today's closures plus every blocker's own obstruction circle, as the `blocked` set
## `ReachabilityGrid.flood()` takes. Public because `WalkSiting` builds the same set and then adds
## two fields to it, and a second copy of this loop would be a second answer to the same question.
static func blocked_by(map: CityMap, blockers: Array[Planned]) -> Dictionary:
	var blocked := map.closed_tiles.duplicate()
	for plan in blockers:
		block_a_disc(map, blocked, plan.position, plan.blocking_radius())
	return blocked

## Paints one disc of ground into a `blocked` set — a body's obstruction, or a field treated as
## ground she will not walk through.
static func block_a_disc(map: CityMap, blocked: Dictionary, at: Vector2, radius: float) -> void:
	if radius <= 0.0:
		return
	var reach := ceili(radius / float(Tuning.TILE_SIZE))
	var centre := map.world_to_tile(at)
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if map.tile_to_world(tile).distance_to(at) <= radius:
				blocked[tile] = true
