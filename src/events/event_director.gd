class_name EventDirector
extends RefCounted
## Places the events whose content is *the moment they happen to you* rather than *where they
## are*: the ones the day budgets and the player's own walk sites.
##
## A cat that happens where it spawns is a cat nobody meets; it has to arrive in front of her
## while she walks, every time.
##
## That is a real distinction and not just a placement trick. A café spilling across a pavement
## is a *place*: it is worth putting on a map because knowing it is there changes the route you
## pick, and walking a street to find out is the game. A cat bolting is worth nothing at all as
## a place — you cannot plan around a thing that lasts three seconds, and a cat that ran across
## an empty road two blocks away was, for six milestones, an event the player had no way of ever
## meeting. It only exists as an interruption, so it is authored as one.
##
## **What is deliberately kept.** The day's budget still buys it, in `EventScheduler`, at the
## same cost as everything else — so making the cat land cannot quietly make the day denser
## too. And the spawn is far enough ahead to be a *reaction window*: `AHEAD_LEAD_DISTANCE` is
## two seconds of walking, and the cat starts a street's width off to one side, so she is
## outside its outer radius the whole time it is crouching. That is the telegraph fairness
## contract holding for an event that arrives without warning, which is the only way one is
## allowed to.
##
## Determinism is the day's RNG on its own stream, as everything else is. The *timing* depends
## on where the player walked, so no seed reproduces it from outside — which is exactly what
## `Telemetry`'s `roll` entries exist to write down.

## How far to either side of the crossing point the run reaches. A street's width, so the cat
## comes out of one kerb and is gone into the other.
const CROSSING_REACH_TILES := Tuning.STREET_WIDTH

var _map: CityMap
var _rng := RandomNumberGenerator.new()
## The events the day has budgeted and not yet spent, in the order the scheduler asked for.
var _owed: Array[EventDef] = []
var _next_in := 0.0
## Whether `owe_the_return()` has already handed today its return-phase patrols. Set once and
## never cleared until `start_day()`, so a baby that wakes and settles again does not owe a
## second batch — see that function's own doc.
var _return_owed := false
## Whether the queue is rolling `Tuning.RETURN_PATROL_INTERVAL` instead of `Tuning.AHEAD_INTERVAL`
## for the rest of the day. Set by `owe_the_return()` and never cleared until `start_day()`: once
## the return owes its pressure, the pacing stays tight even if the phase drops back to walking.
var _return_pacing := false

func _init(map: CityMap) -> void:
	_map = map

## Takes over the day's `AHEAD_OF_PLAYER` and `TOWARD_PLAYER` plans — everything the scheduler
## budgeted but left for the director to site while she walks. Called with the same plan list the
## manager streams the sited events from, so the two halves of a day cannot disagree about what is
## owed.
##
## Asked over `plan.def.spawn_mode_on(day)` rather than `spawn_mode` alone, so a row whose siting
## changes after its own `first_day` — `charging_dog` past `Tuning.RUN_TAUGHT_DAY` — is owed to the
## director only on the days it actually answers `AHEAD_OF_PLAYER` or `TOWARD_PLAYER`. Without this
## the scheduler's own `EventScheduler._place_one()` would place the row on a tile *and* the
## director would separately site a second one in front of her, from the one `EventDef` both read.
func start_day(day: int, plans: Array[EventScheduler.Planned],
		rng: RandomNumberGenerator) -> void:
	_owed.clear()
	_rng = rng
	_return_owed = false
	_return_pacing = false
	for plan in plans:
		var mode := plan.def.spawn_mode_on(day)
		if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
			_owed.append(plan.def)
	_take_the_forced_row()
	# The first one is not free: a cat on the doorstep before she has taken a step reads as the
	# game starting badly rather than as something happening.
	_next_in = _roll_interval()
	if _forced:
		return
	_teach_the_run(day)

## The row `--force <id>` names, or `null` when the flag is absent — see `DevFlags.forced_row()`
## for what the flag is for. Debug builds only, like every other dev flag.
var _forced: EventDef
## Seconds between two forced rows, from `--force <id> [seconds]`.
var _forced_interval := 0.0

## Throws away the day's own owed list and replaces it with the one row `--force` names, so the
## director hands out that row and nothing else for the whole day.
##
## **The day-3 run lesson is skipped while this is on**, in `start_day()` above: `_teach_the_run()`
## exists to put `charging_dog` at the head of a real day's queue, and under this flag there is no
## real queue to put it at the head of — every entry is already the forced row, so moving one to the
## front would only mean the first encounter arrives at `LESSON_DELAY` instead of the interval that
## was asked for.
##
## An unknown id is a loud failure rather than a silent no-op: `--force cylist` would otherwise look
## exactly like a day that happened not to schedule one.
func _take_the_forced_row() -> void:
	_forced = null
	if not DevFlags.enabled():
		return
	var id := DevFlags.forced_row()
	if id == "":
		return
	var def := EventCatalogue.by_id(id)
	if not def:
		push_error("--force names no event in the catalogue: '%s'" % id)
		return
	_forced = def
	_forced_interval = DevFlags.forced_interval()
	_owed.clear()
	_owed.append(def)

## Puts the day-3 lesson at the front of the queue: the day running becomes the answer opens with
## an incident that requires it.
##
## Running is a trap against every other row in the catalogue and is meant to be — so the day the
## exception arrives, the game cannot leave finding it to chance. `charging_dog` is `weight 1.4`
## of a day-3 pool and it would otherwise land whenever it landed, which for the one event that
## teaches a control is not good enough.
##
## Two things, and only on that day: the pursuit is moved to the head of the owed list, and the
## first interval is cut to a lesson rather than an ambush. `LESSON_DELAY` is far enough in that
## she is walking and off the doorstep — the director will not site anything while she is standing
## still — and early enough that it is the first thing that happens to her.
##
## It is *not* a scripted event, and that is deliberate: it is one of the day's own budgeted
## `AHEAD_OF_PLAYER` plans, so teaching the run cannot quietly make day 3 denser than the budget
## says. If the day happened not to buy one, there is nothing to teach and nothing happens.
func _teach_the_run(day: int) -> void:
	if day != Tuning.RUN_TAUGHT_DAY:
		return
	for i in _owed.size():
		if not _owed[i].pursues:
			continue
		_owed.push_front(_owed.pop_at(i))
		_next_in = LESSON_DELAY
		return

## How far into day 3 the lesson lands. A few seconds of ordinary walking first, so that what
## happens reads as the day changing rather than as the day starting.
const LESSON_DELAY := 6.0

func owed() -> int:
	return _owed.size()

## Hands the day's return leg its own pressure — `docs/TODO.md`'s M98, pressure in the empty acts
## — the moment `EventManager` hears `EventBus.return_phase_started`. `Tuning.RETURN_PATROLS_PER_
## ACT[act - 1]` copies of `police_patrol`, at the day's own heat, are appended to the owed queue
## sited `TOWARD_PLAYER` down her own carriageway rather than crossed — see
## `_toward_her_on_the_road()` — and the interval the queue rolls for the rest of the day switches
## from `Tuning.AHEAD_INTERVAL` to the tighter `Tuning.RETURN_PATROL_INTERVAL`, so the extra rows
## land inside the leg rather than after she is home.
##
## Acts I and II are untouched: the array's first two entries are 0, so the teaching days and the
## return she learns the mechanic on stay exactly as they were measured.
##
## **Idempotent for the day.** `return_phase_started` can fire more than once — the baby wakes and
## is walked back down before settling again — and the return is owed exactly once; `_return_owed`
## is what remembers that past the phase dropping back to `WALKING` and the rows already owed stay
## owed regardless. **`--force` leaves the forced queue alone**: under it `_owed` holds only the
## forced row and there is no ordinary queue for this to add to or re-pace.
func owe_the_return(day: int, heat: int) -> void:
	if _return_owed or _forced:
		return
	_return_owed = true
	var act := Tuning.act_for_day(day)
	if act < 3:
		return
	var count: int = Tuning.RETURN_PATROLS_PER_ACT[act - 1]
	if count <= 0:
		return
	var cold := EventCatalogue.by_id("police_patrol")
	if not cold:
		push_error("owe_the_return: no 'police_patrol' row in the catalogue")
		return
	# The day's own heated copy — the same call `EventScheduler.build_day()` makes for every other
	# placement of the row today — duplicated once more rather than mutated, because `heated()`
	# caches its answer and shares it with every ordinary `MAP` placement of the row for the rest
	# of the run: setting `spawn_mode` on that shared copy would turn every later patrol into a
	# director-sited one, not just this day's return-owed rows. See `EventCatalogue._hot` and
	# `EventDef.at_heat()`'s own note on why a heated row is a derived copy in the first place.
	var heated := EventCatalogue.heated(cold, heat)
	var for_return := heated.duplicate() as EventDef
	for_return.shape = heated.shape
	for_return.spawn_mode = EventDef.SpawnMode.TOWARD_PLAYER
	for i in count:
		_owed.append(for_return)
	_return_pacing = true
	# Shortened immediately rather than left for the next ordinary roll to expire — `AHEAD_INTERVAL`
	# can still be waiting out up to 26s when the phase turns, and a 33s return leg cannot afford
	# to spend most of itself on a wait rolled under the pacing this call just replaced — but only
	# ever shortened, never lengthened: a `minf` against whatever is already ticking down means the
	# return can land its first row sooner than the ordinary pacing would have, never later.
	_next_in = minf(_next_in, _roll_interval())

## Advances the clock and returns the event to place plus the path to place it on, or null when
## nothing is due. `heading` is the direction she is actually travelling, not the way she is
## facing: something that crosses in front of a player standing still is not in front of
## anything.
##
## Returns `[EventDef, PackedVector2Array]`, or an empty array.
func due(delta: float, at: Vector2, velocity: Vector2) -> Array:
	if _owed.is_empty():
		return []
	var speed := velocity.length()
	# The clock only runs while she is going somewhere. A player who stops to let the meter
	# recover is not owed a cat for waiting, and one who spends the day in a park should not
	# come back to the pavement and be handed four of them at once.
	if speed < Tuning.AHEAD_MIN_SPEED:
		return []
	_next_in -= delta
	if _next_in > 0.0:
		return []

	# Peeked rather than popped, because what it wants sited depends on what it is: a pursuer is
	# put *in her way* rather than across it, a `TOWARD_PLAYER` row is put *down* her own line, and
	# a placement that fails must not spend the event.
	var next := _owed[0] as EventDef
	var heading := velocity / speed
	# A `TOWARD_PLAYER` row whose `placement` names `ROAD` is a car, not a bike — `police_patrol`
	# is the one row `owe_the_return()` ever adds this way — and a car belongs on the carriageway
	# lane that drives toward her rather than on her own pavement. `_toward_her()` is still what
	# every `TOWARD_PLAYER` row on foot (`cyclist`, `loose_dog`) gets; only the road-placed ones
	# take the road-aware sibling.
	var path: PackedVector2Array
	if next.spawn_mode == EventDef.SpawnMode.TOWARD_PLAYER:
		path = _toward_her_on_the_road(at, heading, next) \
				if next.placement.has(GameEnums.TileType.ROAD) \
				else _toward_her(at, heading, next)
	else:
		path = _crossing_ahead_of(at, heading, next)
	if path.is_empty():
		# Nowhere to put it — she is in the middle of a park, or against the map edge. Try
		# again shortly rather than burning the allowance on a place that would not read.
		_next_in = 1.0
		return []
	_next_in = _roll_interval()
	var handed := _owed.pop_front() as EventDef
	# Refilled rather than seeded with a hundred copies, so the queue length stays honest and
	# `owed()` — which the HUD reads — says "one more coming" rather than a number that means
	# nothing under this flag.
	if _forced and _owed.is_empty():
		_owed.append(_forced)
	return [handed, path]

func _roll_interval() -> float:
	# Fixed rather than rolled under `--force`, and it does not touch `_rng`: the flag is for
	# looking at one row several times, and a rolled 11-26s wait between looks is the thing it
	# exists to remove. Leaving the stream alone also means a `--seed` city is bit-identical with
	# the flag on and off, so what she walks past is the same city either way.
	if _forced:
		return _forced_interval
	if _return_pacing:
		return _rng.randf_range(Tuning.RETURN_PATROL_INTERVAL.x, Tuning.RETURN_PATROL_INTERVAL.y)
	return _rng.randf_range(Tuning.AHEAD_INTERVAL.x, Tuning.AHEAD_INTERVAL.y)

## A run straight across her line, `AHEAD_LEAD_DISTANCE` in front of her.
##
## Perpendicular to *her* heading rather than to the street, which is the difference between a
## cat that crosses the road and a cat that crosses her path. On a pavement those are the same
## thing; walking across a square they are not, and the second one is what was asked for.
##
## Empty when the crossing point is not somewhere anybody could walk — the lead lands inside a
## building, or outside the map. The caller waits and asks again.
##
## **A pursuer is sited at the lead point itself and given no route.** It does not cross her line,
## it comes down it, so a path is the wrong shape for it entirely — and building one anyway puts
## the day-3 dog a street's width off to one side of the place this function has just checked,
## 266px away and diagonal, which on a 640x360 view is at the corner of the screen or past it. What
## she is owed is the sight of it coming, and it has to be sited where that can be seen — but the
## seeing is now a screen-edge badge's job for as long as the dog is off screen, not the dog's own
## silhouette, which is the overturn below.
##
## **And a pursuer is sited at least `def.offscreen_notice` seconds outside the view along the
## heading in play, not against a flat number sized for one axis.** *(2026-09-07: "bikers /
## unleashed dogs all pop in in front of the player instead of starting off screen", "events that go
## towards the player (biker / pursuing dog) should at least be 200ms off screen with a warning",
## and, of the day-3 dog specifically, "the run tutorial spawns inside the visible area making the
## headsup way too short now".)* A flat 200px sits inside the 320px horizontal boundary, so a dog
## sited while she walked east or west had no offscreen phase at all — it appeared already on
## screen. `Tuning.offscreen_lead(heading, closing_speed, def.offscreen_notice)` asks the real
## question instead: how far to the edge of the view *this* heading actually reaches, plus how far
## it and she together cover in the row's own notice — for `charging_dog` at 130px/s pursuing,
## closing at 130 + `WALK_SPEED` (92) = 222px/s, `EventDef.offscreen_notice` of 0.5s buys 111px, sized
## against playtest 20's own measurement of how much closing an evasion needed. See that field's own
## reasoning for why the dog carries a different notice than the rest of the catalogue, and its own
## `telegraph_time` for what pays for the longer approach.
##
## **Unavoidable, on purpose, was the day-3 dog's whole point** — a dog starting further away is a
## dog with more room to be walked around, which is exactly what siting it close was for.
## *(2026-09-07: asked for a close, unavoidable teaching dog · overturned to a further one, because
## the tap-controlled heads-up was too short at the old distance.)* So the dog moves out with
## everything else, and whatever keeps the lesson forceful now has to come from somewhere other than
## siting it too close to see coming — an open question, not one this function answers.
##
## The arithmetic that used to cap the siting no longer applies: the lunge is still fired by
## **proximity** (see `EventInstance._lunged`), but the notice a player gets is no longer "how much
## ground lies between the siting and the stand-off while both are on screen" — the screen-edge
## badge (`DangerEdge`) now carries the notice for the whole of the offscreen approach, and the
## on-screen closing to the stand-off is what it always was.
##
## **This function only ever sites `charging_dog` on `Tuning.RUN_TAUGHT_DAY`.** Every day after,
## `EventDef.spawn_mode_on()` answers `MAP` instead of `AHEAD_OF_PLAYER` for that row, so
## `EventScheduler` places it on a tile like `alley_robbery` and `start_day()` above never adds it
## to `_owed` at all — it is not sited off her heading by this function, it is not sited by this
## function. A pursuer arriving here is always the teaching day's own dog, dead ahead on purpose,
## because the lesson depends on being unavoidable.
func _crossing_ahead_of(at: Vector2, heading: Vector2,
		def: EventDef = null) -> PackedVector2Array:
	var lead := Tuning.offscreen_lead(heading, def.pursue_speed + Tuning.WALK_SPEED,
				def.offscreen_notice) \
			if def and def.pursues \
			else (def.ahead_of_player_lead() if def else Tuning.AHEAD_LEAD_DISTANCE)
	var centre := at + heading * lead
	if not _map.is_walkable(_map.world_to_tile(centre)):
		return PackedVector2Array()
	if def and def.pursues:
		return PackedVector2Array([centre])
	var across := Vector2(-heading.y, heading.x) * float(CROSSING_REACH_TILES * Tuning.TILE_SIZE)
	# The side it comes from is a coin flip, so a player cannot learn to watch one shoulder.
	if _rng.randf() < 0.5:
		across = -across
	var from := centre - across
	var to := centre + across
	if not _map.in_bounds(_map.world_to_tile(from)) or not _map.in_bounds(_map.world_to_tile(to)):
		return PackedVector2Array()
	return PackedVector2Array([from, to])

## A run straight *down* her own line rather than across it: `TOWARD_PLAYER`'s whole point. Sited at
## least `def.offscreen_notice` seconds outside the view along her heading —
## `Tuning.offscreen_lead(heading, def.speed + Tuning.WALK_SPEED, def.offscreen_notice)`, since she
## is usually walking into it — and travelling back down the same line she is walking, so a rig that
## keeps going meets it on a genuine collision course rather than a near miss that depends on nobody
## moving. *(2026-09-07: "bikers / unleashed dogs all pop in in front of the player instead of
## starting off screen", and "events that go towards the player (biker / pursuing dog) should at
## least be 200ms off screen with a warning".)* A row sited at a flat 200px was already on screen on
## the horizontal axis; this is not, on either axis — for `cyclist` at 165px/s the closing speed is
## 165 + 92 = 257px/s, 51px of margin past the boundary at the default notice.
##
## **A `hard_fail` row is sited further still, so its own telegraph is over before it arrives.**
## *(2026-09-07: "also a biker hit should be lethal.")* `Tuning.outlasting_telegraph_lead()` takes
## whichever is further: the ordinary offscreen margin, or the distance that takes
## `telegraph_time + def.offscreen_notice` to close. `cyclist`'s telegraph is the binding term on
## every heading. A row this far out is well past `EVENT_STREAM_RADIUS`'s own concerns; it exists
## for exactly this one moment and is created only when it is due, so there is no cost to sitting it
## further than a `MAP` row ever would be.
##
## **The line is straightened onto the pavement she is standing on, when she is standing on one.**
## *(2026-09-07: "also biker should be on the same side of the road not the other side".)* Sited
## along her literal heading, a hundreds-of-pixels lead drifts across the carriageway from a heading
## only a little off the corridor's own axis — a diagonal drag on the touch controls crosses a
## six-tile street well before a `hard_fail` row's own lead reaches it, landing the row on the far
## sidewalk, where it reads as scenery rather than as a lane she has to answer for. `_onto_her_side()`
## below is the preference, not a requirement: where there is no pavement edge to prefer — the
## carriageway, a junction, open ground — or the heading has no along-corridor component to send it
## down, the literal heading is used exactly as before.
##
## The far end of the route runs the same distance **behind** her rather than stopping where she
## is standing: it has to still be going somewhere when it reaches her, or `EventInstance` reads
## the end of its path as *arrived* and leaves right where it met her, which is exactly the
## "flickers past and is gone" complaint the badge already answers for a fast mover the other way.
##
## Empty when either end is not somewhere anybody could stand — the map's edge, or the geometry of
## a bend putting the far point inside a building. The caller waits and asks again; it does not
## retry the near point only, because a route that starts on the pavement and ends in a wall is not
## a route either.
func _toward_her(at: Vector2, heading: Vector2, def: EventDef) -> PackedVector2Array:
	var site_heading := _onto_her_side(at, heading)
	var closing := def.speed + Tuning.WALK_SPEED
	var lead := Tuning.outlasting_telegraph_lead(site_heading, closing, def.telegraph_time,
				def.offscreen_notice) \
			if def.hard_fail else Tuning.offscreen_lead(site_heading, closing, def.offscreen_notice)
	var far := at + site_heading * lead
	if not _map.is_walkable(_map.world_to_tile(far)):
		return PackedVector2Array()
	var behind := at - site_heading * lead
	if not _map.in_bounds(_map.world_to_tile(behind)):
		return PackedVector2Array()
	return PackedVector2Array([far, behind])

## The road-aware sibling of `_toward_her()`, for a `TOWARD_PLAYER` row whose `placement` names
## `ROAD` — `owe_the_return()`'s own `police_patrol` copies, a car rather than a bike.
## `_toward_her()` straightens the line onto *her* pavement; a car has no business on a pavement
## at all, so this runs it down the **carriageway lane that drives toward her** instead, using
## `CrowdLanes` for the lane geometry the same way `Crowd` sites one.
##
## Built the same way `_onto_her_side()` reads a corridor's own axis, then handed to
## `CrowdLanes`: `pavement_inward()` says which axis the corridor she is beside runs on and which
## way is into it, `corridor_at()` says which corridor that is, and `road_lane()` picks the lane
## that legally runs the direction the car is coming from — **opposite her own heading**, since it
## is meeting her rather than following her.
##
## Empty wherever there is nothing to run a car down: she is not beside a plain sidewalk edge at
## all (`pavement_inward()` answers `Vector2i.ZERO` for a park, a square, a junction, or the
## carriageway itself), her heading has no along-corridor component to pick a direction from, or
## the corridor there has no carriageway to drive on — a precinct is paved kerb to kerb, so its
## "road" tiles fail `is_driveable_at()` and this returns empty exactly where the brief asks it
## to: a park, a square, a precinct.
##
## **No `hard_fail` branch.** `_toward_her()` sites a lethal row further out so its telegraph
## outlasts the approach; `police_patrol` never gains `hard_fail` at any heat (`EventDef.at_heat()`
## states it explicitly for the `PRESSES` rung), so the ordinary `Tuning.offscreen_lead()` margin
## is all this owes today. A future lethal road row would need the same
## `Tuning.outlasting_telegraph_lead()` branch `_toward_her()` carries.
func _toward_her_on_the_road(at: Vector2, heading: Vector2, def: EventDef) -> PackedVector2Array:
	var inward := _map.pavement_inward(_map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return PackedVector2Array()
	var vertical := inward.x != 0
	var along := Vector2(inward.y, inward.x)
	var component := heading.dot(along)
	if is_zero_approx(component):
		return PackedVector2Array()
	var site_heading := along * signf(component)
	var index := CrowdLanes.corridor_at(at.x if vertical else at.y)
	if index < 0:
		return PackedVector2Array()
	# The car drives opposite her own along-corridor heading — coming down the street as she
	# walks up it — so its lane is the one `CrowdLanes.road_direction()` says legally runs that
	# way, not merely a point somewhere in the road band.
	var direction := -(site_heading.y if vertical else site_heading.x)
	var lane_coordinate := CrowdLanes.lane_centre(index, CrowdLanes.road_lane(vertical, direction))
	var closing := def.speed + Tuning.WALK_SPEED
	var lead := Tuning.offscreen_lead(site_heading, closing, def.offscreen_notice)
	var far := at + site_heading * lead
	var behind := at - site_heading * lead
	if vertical:
		far.x = lane_coordinate
		behind.x = lane_coordinate
	else:
		far.y = lane_coordinate
		behind.y = lane_coordinate
	if not _map.is_driveable_at(vertical, _map.world_to_tile(far)) \
			or not _map.is_driveable_at(vertical, _map.world_to_tile(behind)):
		return PackedVector2Array()
	return PackedVector2Array([far, behind])

## Swaps a heading with a lateral drift for the corridor's own axis, when she is standing on a plain
## pavement edge — `CityMap.pavement_inward()` names which side of a corridor a sidewalk tile is on,
## and its own axis (`RIGHT`/`LEFT` for a corridor running north-south, `DOWN`/`UP` for one running
## east-west) is the only one a `TOWARD_PLAYER` row's approach has to answer to. Zeroing the
## heading's component on that axis and keeping only the along-corridor part sends the row straight
## down *her* pavement instead of wherever her literal heading happens to point, so it approaches
## from ahead along the street rather than drifting across it — which is what a bike riding down a
## street already does, whatever diagonal she happens to be walking at.
##
## Returns `heading` unchanged in the two cases where there is nothing to prefer: she is not on a
## plain sidewalk edge (the carriageway, a junction, open ground — `pavement_inward()` answers
## `Vector2i.ZERO`), or her heading has no along-corridor component at all, which is walking straight
## across the street and leaves no corridor line to send the row down.
func _onto_her_side(at: Vector2, heading: Vector2) -> Vector2:
	var inward := _map.pavement_inward(_map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return heading
	var along := Vector2(inward.y, inward.x)
	var component := heading.dot(along)
	if is_zero_approx(component):
		return heading
	return along * signf(component)
