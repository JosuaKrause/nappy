class_name EventInstance
extends Node2D
## One live event in the world: its lifetime, its telegraph phase and its excitement field. What
## it does is its behaviours' (`src/events/behaviours/`); how it looks is its look's
## (`src/events/views/`), which reads its public state and draws it.
##
## The excitement model is entirely a *query* — `contribution_at()`. Nothing pushes a value
## at the baby, so there is no ordering to get wrong, events compose by simple addition, and
## the whole thing is testable without a scene.

## The gap between a posted roadblock guard's picture and the barrier's, so the two never touch —
## see `guard_post_offset()`.
const _GUARD_POST_CLEARANCE := 2.0

## Whether a def's instance draws itself as a **spread** — segments or a whole scene fitted across
## `def.obstructs_radius`, laid along whichever axis `_spread_is_vertical` picks for the street it
## stands on. That is `SpreadLook._draw_spread`, `RankLook._draw_cafe` or
## `SpreadLook._draw_wide_scene`, nothing else in `EventLook.draw_body`'s dispatch: `ROADWORKS`,
## `BURNT_SHELL`, `STALL`, `ROADBLOCK`, `BARRICADE`, `SCAFFOLDING` and `COLLAPSED_FRONTAGE` go to
## the first, `CAFE` to the second. The three seal pictures wide enough to span the whole street
## (`FALLEN_TREE`, `CAR_ACCIDENT`, `BURST_MAIN`) use `SpreadLook._draw_wide_scene`, which fits one
## scene to the obstruction and anchors vertical scenes at the far end so their centre sits on the
## ground point. Each has an authored east-west asset selected by
## `EventPictures.wide_scene_texture`. `PROTEST` and `FIREFIGHT` also fill `obstructs_radius`-worth
## of ground but draw it with their own functions that never call `_spread_is_vertical` or
## `spread_at` — a protest rank and a firefight's cover are laid along local X unconditionally, so a
## corner costs them nothing and they are rightly outside this test.
##
## **This is the test `EventScheduler._open_ground_for` asks before it will offer a corner as a
## site.** See that function and `docs/DECISIONS.md`, "a spread on a corner is placed as if the
## corner were nothing" — a junction has no single street for `_spread_is_vertical` or
## `_centred_on_the_pavement_band` to answer about, so only a row that actually asks either
## question has anything to lose by standing on one.
static func has_a_spread(def: EventDef) -> bool:
	return def.has_a_spread

var def: EventDef
## Waypoints for a mobile event, in world space. Empty for a stationary one.
var path: PackedVector2Array = PackedVector2Array()

## How long it has existed, in seconds: its own clock. A set from outside (a resume, a rig) settles
## the phase against the new age; its own tick advances `_age` and settles once its notice clock has
## been held.
var age: float:
	get:
		return _age
	set(value):
		_age = value
		_settle_the_notice()
var _age := 0.0
## Whether this was created where a warning pointed, once that warning was over
## (`EventManager.spawn_warned()`), rather than simply appearing. `DangerEdge` reads it to carry
## the warning's badge on to the thing itself until it comes into view, and `resume()` reads it to
## tell a fresh instance from one streamed back in.
var came_under_a_warning := false

## **What this event does**, composed per catalogue row (`EventBehaviours.compose()`): each an
## `EventBehaviour` owning its own state, ticked in this order. The typed fields below are the same
## objects, null for a behaviour the row is not composed of.
var _behaviours: Array[EventBehaviour] = []
## A conversation or a door's hold (`EventDef.detain_seconds`).
var hold: EventHold
## The unmarked van's take of a bystander.
var abduction: EventAbduction
## Going away once it is over (`Phase.LEAVING`); every event has one.
var departure: EventDeparture
## Following its route or pacing its beat (`EventDef.mobile`).
var route: EventRouteWalk
## A car's driving: its proposed frame, its standing for her, its give-way and its strike
## (`EventCarDriving`). Null for anything that does not drive.
var car: EventCarDriving
## A barrier its guards stand at and walk out of (`EventBarrierPost`): the roadblock's. Null for
## anything else.
var barrier_post: EventBarrierPost
## A vehicle that stops for her and lets men out (`EventDef.investigates`).
var investigation: EventInvestigation
## Coming after her: the notice, the stand-off and lunge, the charge, the give-up
## (`EventDef.pursuit`).
var pursuit: EventPursuit
## A man on foot who may stop her and walk back to the vehicle that let him out (every pursuer).
var on_foot: EventOfficer
## A row that waits for her and then runs its own event without chasing her (the mouse, the
## flock, the masked man).
var notice_run: EventNoticeRun
## A flock's birds (`EventDef.flock_size`).
var flock: EventFlock
## A row sent down her line that is retired once it cannot reach her (the loose dog).
var unreachable: EventUnreachable

## **Where this event is in its life, stored and changed in one place** (`transition()`), so every
## question about it — is it waiting, warning, done — reads one value rather than re-deriving the
## phase from a dozen flags each frame. Every row has one, a pursuer or not.
enum Phase {
	## A row that waits for her (`EventDef.notice`) has not noticed her: standing there, at full
	## strength unless its notice is quiet, not lethal, not moving.
	WAITING,
	## Its telegraph or notice is running: a row's own telegraph from the frame it exists, or for a
	## row that waits, its warning from the frame it noticed her (`chase_age() < notice_time()`).
	WARNING,
	## Happening at full strength: a pursuer charging her, a crossing cat running, a flock up.
	ACTIVE,
	## The man a vehicle let out has reached her and stands with her through his stop
	## (`PursuitSpec.stop_excitement`).
	STOPPED,
	## Over and getting out of shot: it emits nothing, cannot end the day and carries no cue.
	LEAVING,
	## A row that stops where it arrives has stopped there (`EventDef.stops_where_it_arrives`):
	## still the same event, standing still, for the rest of the day.
	PARKED,
	## Its guard has gone for good and only his barrier stands, solid and silent
	## (`PursuitSpec.leaves_its_body`). It waits for nothing.
	SPENT,
	## Gone: finished where it stood, or out of sight at the end of its departure.
	DONE,
}

## Where it is in its life — see `Phase`. Changed only by `transition()`.
var phase := Phase.WARNING
## Whether its telegraph or notice ended into `Phase.ACTIVE` — run out, or cut short by a lunge, a
## flush or the masked man's run. A row that left, parked or stopped before that is still within
## its telegraph's clock (`is_telegraphing()`).
var _telegraph_ended := false

## Whether it is over and gone (`Phase.DONE`).
var is_finished: bool:
	get:
		return phase == Phase.DONE

## **The one place its phase changes**, and with it what every phase change owes: the field it
## answers is a function of the phase, so the contribution cache is let go. A row that is done stops
## showing its scenery on the next drawn frame, when its look reads `is_finished`.
func transition(to: Phase) -> void:
	if phase == to:
		return
	if phase == Phase.WARNING and to == Phase.ACTIVE:
		_telegraph_ended = true
	phase = to
	_invalidate_contribution_cache()

## **A telegraph or notice that has run its time is over**: asked wherever the notice clock or
## the age moves, so the stored phase is never behind the clock.
func _settle_the_notice() -> void:
	if phase == Phase.WARNING and chase_age() >= notice_time():
		transition(Phase.ACTIVE)

## Whether this cyclist is drawn as the pelican (`EventPictures.PELICAN_BY_VIEW`) rather than the
## kid. Set once, by `EventManager` as it creates the rider, and never changed afterwards, so a
## rider is one or the other for its whole ride. **The picture is all it changes**: the def, the
## field, the lethal radius, the speed and the cost are the row's own either way, and nothing reads
## it but the drawing and the telemetry (`logged_name()` and the pelican's own `EventBus` signals).
## Meaningless on any look but `CYCLIST`. See `FigureLook.rider_pictures()`.
var is_pelican := false

## What every run log line and every GoatCounter event calls a pelican, in place of its row's own
## `cyclist`. *(Inbox #527 in azure-tapir, the player: "logs should be correctly identifying it from the
## beginning".)*
const PELICAN_NAME := "pelican"

## Whether `EventBus.pelican_excited_her` has gone out for this pelican: once per pelican, on the
## first share of the meter it lands (`accumulate_landed()`).
var _reported_excitement := false

## Every point this instance has ever landed on her meter, never pruned — the running total
## `EncounterWatch` measures an encounter's share against, since `landed()` keeps only the halo's
## `ExcitementHalo.WINDOW` and an encounter can be longer. Telemetry only: nothing that decides
## anything reads it.
var landed_ever := 0.0

## `EncounterWatch`'s own record of this instance's encounters with her, made the first time it is
## on screen or lands on her, or `null` until then. Telemetry only, like `landed_ever`.
var encounter: EncounterWatch.Record = null

## The box, in this node's own space, that what this instance draws roughly fills: its row's own
## picture (`EventPictures.icon_for()`) standing on its feet at the origin, stretched along the run
## a spread, a protest or a firefight covers, and grown by the wheel of a flock. An empty box for a
## row that draws nothing of its own (`Look.NONE`). Not pixel-exact — no halo, no badge, no bob, the
## view a mover is drawn in this frame aside — and it does not need to be: `EncounterWatch` asks
## only whether most of it is in view. Worked out once, on first asking, from what `setup()`
## decided.
func drawn_box() -> Rect2:
	if _drawn_box_known:
		return _drawn_box
	_drawn_box_known = true
	var box := box_of(def)
	if not box.has_area():
		_drawn_box = Rect2()
		return _drawn_box
	var size := box.size
	box = _with_the_drop(def, box)
	var half := maxf(11.0, def.obstructs_radius)
	if def.has_a_spread and _spread_vertical:
		box = box.merge(Rect2(-size.x * 0.5, -half, size.x, half * 2.0))
	elif def.has_a_spread or def.look == EventDef.Look.PROTEST \
			or def.look == EventDef.Look.FIREFIGHT:
		box = box.merge(Rect2(-half, -size.y, half * 2.0, size.y))
	if def.flock_size > 0:
		box = box.grow(def.flock_spread)
	_drawn_box = box
	return _drawn_box

## The box a row's own picture fills standing on its feet at the origin — `drawn_box()` before an
## instance exists, and without the run a spread covers, which only an instance's own street decides.
## Empty for a row that draws nothing of its own.
static func box_of(row: EventDef) -> Rect2:
	var icon := EventPictures.icon_for(row.look)
	if icon.is_empty():
		return Rect2()
	var size := EventPictures.native_size(icon)
	return Rect2(-size.x * 0.5, -size.y, size.x, size.y)

## **Everything a row can put on the screen**, standing on its feet at the origin, whichever way it
## faces: the union of every picture its look can draw (`EventPictures.family_sources()` — a cyclist
## coming down the screen draws its front view, not the side view its badge shows) wherever it can
## stand (the picture of a car that drives is lowered over its body, `_picture_drop_of()`), its body
## shadow (a disc of its shape's radius at its feet), the loose dog's trailing lead, the bob and the
## excitement halo's rim (`EntityHalo.HALO_MARGIN`). What a thing arriving from off screen is placed
## wholly outside the camera's view by (`PendingWarning.just_out_of_sight()`), so nothing of it
## shows on the frame it exists *(amendment 6 of M226, the player: "I don't want any pop in")*. And
## for a row that can be marked — anything with a field or a lethal reach — the danger caret above
## its feet at its tallest (`EventPictures.largest_mark_rect()`), which stands well above the
## picture. Empty for a row that draws nothing of its own.
static func footprint_of(row: EventDef) -> Rect2:
	var box := Rect2()
	var any := false
	for picture in EventPictures.family_sources(row.look):
		var size := EventPictures.native_size(picture)
		if size.x <= 0.0 or size.y <= 0.0:
			continue
		var one := Rect2(-size.x * 0.5, -size.y, size.x, size.y)
		box = one if not any else box.merge(one)
		any = true
	if not any:
		return box_of(row)
	box = _with_the_drop(row, box)
	if row.draws_body_shadow and row.shape != null:
		var r := row.obstructs_radius if row.obstructs_radius > 0.0 else row.shape.radius
		box = box.merge(Rect2(-r, -r, r * 2.0, r * 2.0))
	if row.look == EventDef.Look.LOOSE_DOG:
		box = box.merge(Rect2(-LOOSE_LEAD_REACH, -8.0, LOOSE_LEAD_REACH * 2.0, 8.0))
	box = box.grow(EventPictures.BOB_HEIGHT + EntityHalo.HALO_MARGIN)
	if row.intensity > 0.0 or row.hard_fail:
		box = box.merge(_with_the_drop(row,
				EventPictures.largest_mark_rect().grow_individual(0.0, EventPictures.BOB_HEIGHT,
						0.0, 0.0)))
	return box

## How far the loose dog's slack lead trails behind it, in px — `FigureLook._draw_loose_dog()`'s own
## reach.
const LOOSE_LEAD_REACH := 26.0

var _drawn_box := Rect2()
var _drawn_box_known := false

## Whether this pursuer is coming for her right now: its chase has begun (`EventBus.pursuit_began`'s
## own moment) and it has neither given up nor left. Telemetry only — `EncounterWatch` counts a
## chase as an influence.
func is_chasing() -> bool:
	return def.pursuit != null and _charge.began and not is_finished and not is_leaving \
			and not is_waiting()

## Whether this charger's charge has begun and is still running: `EventBus.pursuit_began` sent for
## it (a pursuer's charge, the masked man's run up his shaft) and it has neither left, finished nor
## had its charge end; true for the whole charge. Read by `DangerEdge` and handed to `BadgeModel` as
## `Subject.charging`; on a charger's first moving frame the model meets the charge at its true
## approach rather than its smoothed one and raises its badge from outside the view proper, so it is
## up from the frame he runs.
func has_charged() -> bool:
	return _charge.began and not _charge.ended and not is_finished and not is_leaving \
			and not is_waiting()

## The name the run log and the page's counter call this instance by: `PELICAN_NAME` for a pelican,
## otherwise the row's own `def.id`. Telemetry only — nothing that decides anything reads it.
func logged_name() -> String:
	return named_for_the_log(def.id, is_pelican)

## `logged_name()` for a row id and a pelican choice that may not have an instance yet — a warning
## still up (`PendingWarning.logged_name()`).
static func named_for_the_log(id: String, pelican: bool) -> String:
	return PELICAN_NAME if pelican else id

## A mast that has been reached and silenced — `EventManager.silence_mast()`/`silence_all_masts()`
## set this rather than calling `_finish()`, since a silenced mast still stands, with no arcs and
## no field, and `is_finished` means *this has left*. Harmless on every row but a mast: nothing
## else ever sets it. See `current_intensity()` and `FigureLook._draw_mast()`.
var silenced := false

## `--skip events`, handed in by the manager that makes this instance: nothing of it is drawn.
var skip_draw := false

## Where the player is, in world space, or `INF` for nowhere.
##
## Written once per frame by `EventManager`, which is the one place that already knows. An instance
## looking her up itself would be thirty lookups a frame for one answer, and — more to the point —
## `EventInstance` has never had to know the player exists, and this keeps that true: it is handed
## a point, and everything it does with the point is a distance.
##
## Two things want it, and neither is a reference to her: a pursuer walks toward it, and anything
## that is *leaving* uses it to know when it is out of sight. `ExcitementHalo` writes the same
## value again every frame through `set_player_at()`, part of the duck type it reads back for the
## caret — the two writers agree because both read `_player.global_position` the same frame.
var player_at := Vector2.INF

## Where her pram's own body is (`Stroller.PRAM_BODY_RADIUS`, on her circumference along her
## facing), told beside `player_at` by `EventManager`, or `Vector2.INF` with no pram (a rig, or the
## escape's carrying). Only a car that drives asks it (`EventDef.vehicle`): the pram is the part of
## her that meets a car first when she faces it, so a car that stopped only for her own body would
## shove the pram, and a strike stated over her body alone would be stopped short by the pram.
var pram_at := Vector2.INF

## Her current velocity, her current decay rate (`Baby.decay_rate()`, her locomotion times the
## ground she is on) and the baby's current sensitivity (`Baby.current_sensitivity()`) —
## everything `expected_impact_at()` needs to answer "if she keeps doing what she is doing." All
## three default to the values that make it answer exactly as it always did (held still, nothing
## given back, nothing damped) for any caller — a data-level test among them — that has not told
## this instance otherwise.
var player_velocity := Vector2.ZERO
var player_decay_rate := 0.0
var player_sensitivity := 1.0

## The sum of `expected_gross_at()` over every source `ExcitementHalo` is running this frame, told
## once a frame through `set_expected_total_gross()` — `-1.0` (the default) means nobody has, so
## `expected_impact_at()` nets the whole projected decay against this instance alone, exactly as it
## always did.
var player_expected_total_gross := -1.0

## Part of `ExcitementHalo`'s duck type — see that class's doc. `EventManager` already keeps
## `player_at` current for the chase and the leaving check; this is the same field, told from the
## other direction, plus the three above `expected_impact_at()` needs and nothing else in this
## file reads.
func set_player_at(at: Vector2, velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
		sensitivity: float = 1.0) -> void:
	player_at = at
	player_velocity = velocity
	player_decay_rate = decay_rate
	player_sensitivity = sensitivity

## Told once a frame by `ExcitementHalo`, after every live candidate's own `expected_gross_at()`
## has been asked at the same position — see `expected_impact_at()`'s own doc for why the total has
## to be gathered before any one source's share of the decay can be known.
func set_expected_total_gross(total: float) -> void:
	player_expected_total_gross = total

## The camera's whole view this frame (`VisibleView.view`), written beside `player_at` by
## `EventManager._tell_them_where_she_is()`: what a waiting charger's notice is held to
## (`_would_stand_in_her_view()`). Empty where nothing has looked through a camera.
var player_view := Rect2()

## Whether she is running right now. Written beside `player_at` and by the same pass, because the
## one thing that reads it asks both together: a pursuer gives up because **she ran**, which is a
## fact about her and not about the gap. See `EventPursuit`.
var player_running := false

## Whether another structure of the same region boundary is charging her harder than this one is,
## at `player_at`. Written once a frame by `EventManager._tell_them_where_she_is()`, `false` for
## every row that is not a `EventDef.barrier_structure` and for the one of them that is the
## maximum.
##
## **It exists so the two cues that say "this will cost you" agree with the meter, which keeps only
## that maximum.** `expected_impact_at()` returns nothing for an outranked structure and
## `ExcitementHalo.select_sources()` leaves it out, so a corner where a wall meets a door draws one
## rim on the barrier that is actually charging her rather than five rims sharing one barrier's
## worth of cost — and `MAX_SOURCES` is not spent on four bodies that land nothing.
##
## **Told from outside rather than asked here**, for the same reason `player_at` is: an instance
## has no view of the others, and the answer is a property of where she is standing this frame.
## `false` until somebody says otherwise, which is the ordinary behaviour a data-level test gets.
var outranked_by_a_stronger_barrier := false

## Whether the baby is awake right now. Written once a frame by `EventManager` alongside
## `player_at`, and read by exactly one row: `chatting_mother`'s conversation is the only thing in
## the catalogue whose contribution differs by the baby's own state, and this is how it can without
## ever writing to `Baby.excitement` — the read happens here, in `current_intensity()`, so
## excitement stays a pure query. `true` with nobody to ask, which is the harmless default a
## data-level test gets.
var baby_awake := true

## The shared boom state a `checkpoint_gate` draws raised or lowered from — `RegionPlanner.
## GateState`, set by `EventStreaming.stream_in` from `Planned.gate_state`. `null` for every look
## but `CHECKPOINT_GATE`, and read as lowered while it is: a gate that has not been wired to
## `Crowd` yet (or a data-level rig with no crowd at all) draws exactly the safe default.
var gate_state: RegionPlanner.GateState = null

## Facing, for art with a front and a back. Only a mobile event ever changes it.
var _heading := Vector2.RIGHT

var _path_travelled := 0.0
var _telegraph_announced := false
var _activation_announced := false

## One gait phase per instance, advanced by the distance actually covered this frame — the
## mother's and the walker's own 0.09-per-px rate (`GAIT_RATE`), pinned again here rather than
## shared because neither exposes it as a constant reachable from this file. Reset in `setup()`
## and `resume()` so a stride never starts mid-cycle — see `_advance_gait()`.
var _gait_phase := 0.0
## Whether this instance actually covered ground on its most recent step (`step()`) — the gate that
## makes a stopped figure (a queue, a give-way, a waiting robber, a chatting mother, a stationary
## yeller, the dog walker's own stop) hold frame a rather than whatever `_gait_phase` last landed
## on. See `_advance_gait()` and `EventLook._gait_stepping()`.
var _gait_moving := false
## A deterministic 0..1 drawn once, in `setup()`, from this instance's own siting position — the
## same position-hash approach `EventFlock._roll()` uses, since the day's own RNG is not reachable
## from here and streaming an instance out and back in must not draw twice from it. Offsets the café
## sitters' and the busker's own idle timer (`EventLook._idle_stepping()`) so two of either kind
## placed on the same day do not lean or strum in lockstep.
var _idle_phase_offset := 0.0

## **The map of the world this instance stands in** (`WorldMap`), handed in by the manager that makes
## it: the questions about the ground that are not about moving over it — where a body stands on a
## pavement, which way a spread lies, which alley a mouse crosses, whether a wall keeps this field
## from her — and the world it adds what it draws beside itself to (`WorldMap.add_entity()`: its
## band, the far guard walking off, the slices of a long picture). The city's map outdoors, the
## building's indoors, and open ground (`WorldMap.open_ground()`) for a data rig that names none,
## where every street question answers "no street" and nothing is walled.
var _map: WorldMap
## **How this figure moves, and what it sees along**: every step, walk, way round and way out, and
## every notice, lunge and catch line, go through it (`Navigator`), asked as `_mover`. Handed in by
## `setup()` — `EventManager` hands every figure its world's own — or, for a rig that hands none, one
## over `_map`: on open ground a rig that walks a straight line on purpose gets exactly the
## unclamped movement it asks for.
var _navigator: Navigator
## What this figure walks as (`mover_for()`): a figure on foot or a car, at its body's radius.
var _mover: Mover
## What this figure sees along: the layers `_mover` names, less street ground, which is where a car
## may drive and not what it can see. A car that investigates notices her in an alley mouth or on
## a square as a figure would.
var _sight: Mover
## The solid body `_build_obstruction()` made, or `null` before it exists and after
## its step has dropped it. See `is_solid()`.
var _obstruction: StaticBody2D

## The child that re-draws this event's own body in a ring of offsets — see `EntityHalo`, the
## class shared with `CrowdAgent` that owns the ring, the shared shader material and the drawing.
## Built on this instance's first nonzero glow and freed on the spot once it has faded back out,
## or by `ExcitementHalo` through `release_halo()` once this instance is queued for deletion, so it
## is `null` whenever nothing is drawn — see `set_halo_strength()`, and `EntityHalo`'s class doc
## for why a rim held by every live event leaves most of them dark on the web.
var _halo: EntityHalo

## `[when, points]` entries landed on her from this event, `when` stamped from `_clock` in
## seconds, for whatever is still inside `ExcitementHalo.WINDOW` — a true sliding sum rather than
## a decayed average, so a burst reads as itself for the whole window and then drops. Lazily
## grown: an event that has never landed anything keeps this empty. Duck-typed with `CrowdAgent`'s
## own copy — see `ExcitementHalo`'s class doc for the whole shape. See `accumulate_landed()` and
## `landed()`.
var _landed_history: Array = []

## This event's own simulation clock, in seconds, advanced by `delta` in `step()` while the
## event is still live. `landed()` is measured against this rather than `Time.get_ticks_msec()` so
## that a paused game does not empty the halo, and so a rig can measure the window on simulated
## time by advancing this directly instead of waiting on the wall clock. Frozen once `is_finished`
## — see `step()` — so a spent instance's history simply stops moving rather than continuing
## to drain toward zero after nothing more can land on it.
var _clock := 0.0

## Whether `SpreadLook._draw_spread` and `RankLook._draw_cafe` lay their segments along local Y
## rather than local X. Decided once, in `setup()`, from the street the instance stands on — see
## `_spread_is_vertical`. Never a per-row field: two rows on the same street face the same way for
## the same reason, and a row that had to say so itself could disagree with the street it was
## actually placed on.
var _spread_vertical := false
## Whether a stationary vehicle shows its side. The moving van sits along the street while the
## burnt car lies across it; a junction, off-street ground or data-level rig follows its facing.
var _stationary_vehicle_side := true

## `face` is where a *stationary* event was sited looking. A mobile one overwrites it from the
## direction it is travelling on its first step, which is why the default is harmless.
func setup(definition: EventDef, at: Vector2, route: PackedVector2Array = PackedVector2Array(),
		face := Vector2.RIGHT, map: WorldMap = null, navigator: Navigator = null) -> void:
	def = definition
	path = route
	_behaviours = EventBehaviours.compose(self, definition)
	_map = map if map else WorldMap.open_ground()
	_navigator = navigator if navigator else _map.navigator()
	_mover = mover_for(definition)
	_sight = Mover.of(_mover.blocked_by & ~Mover.STREETS)
	var start := route[0] if route.size() > 0 else at
	if not definition.mobile and definition.obstructs_radius > 0.0 \
			and definition.pavement_side == EventDef.Pavement.ANY:
		start = _centred_on_the_pavement_band(_map, start)
	position = start
	_heading = face
	look = EventLooks.for_row(self)
	look.face(face)
	if look is SpreadLook:
		(look as SpreadLook).letting_go_of_the_slices.connect(_release_rims_on_slices)
	_spread_vertical = _spread_is_vertical(_map, position)
	_stationary_vehicle_side = _stationary_vehicle_uses_side(definition.look, _map, position, face)
	# A stride never starts mid-cycle — the mother's own `reset_at()` precedent.
	_gait_phase = 0.0
	_gait_moving = false
	_idle_phase_offset = _position_roll(101)
	# A row that waits has not noticed her yet; any other is in its telegraph from now, or past a
	# telegraph of no length.
	if definition.notice != null:
		_notice.stop()
		phase = Phase.WAITING
	else:
		_notice.start(0.0)
		phase = Phase.WARNING
		_settle_the_notice()
	if definition.path_mode == EventDef.PathMode.ACROSS_ITS_ALLEY:
		# Placed on the map with no route at all, so its own dash is built here, from the alley it
		# actually landed in rather than a flat offset, and cut to the ground it fits on.
		path = _navigator.trim(_alley_crossing_path(_map, position), _mover)

## **A pavement is one piece of walkable ground, not two lanes a body has to fit inside one of.**
## `EventScheduler` places a stationary body at `map.tile_to_world(tile)` — the centre of whichever
## of the pavement's two lanes the scheduler happened to choose, 16px from that lane's own edge and
## 48px from the far one — so a body sized against the *pavement* rather than the *lane* overhangs
## by exactly the asymmetry between those two numbers. Playtest 19's own words are about the offset,
## not the width: *"they're all placed with an offset that makes them clip into other things."*
##
## The fix is the position, not a smaller radius: this shifts a stationary, unpinned body from the
## lane tile the scheduler chose to the middle of the two-lane band it belongs to, so a body may be
## up to the full `SIDEWALK_WIDTH * TILE_SIZE` (64px) wide and exactly fill the pavement, the way
## `construction`'s own docstring always said it did.
##
## **Exempt: anything `pavement_side` pins to an edge on purpose.** `delivery_van` belongs at the
## kerb and `reversing_lorry` belongs against the building — re-centring either would undo the one
## thing `pavement_side` exists to do. Both stay exactly where `EventScheduler._build_placement`
## put them, still measured against the same 64px band: a kerbed `VEHICLE_BODY` (44px) leaves a
## 26px gap to the frontage, narrower than the 28px pram, which is how `docs/EVENTS.md`'s
## `delivery_van` row reads that placement — a **wall** by physical fit, so a van at the kerb is
## *also* "no line to walk," on purpose.
static func _centred_on_the_pavement_band(map: WorldMap, at: Vector2) -> Vector2:
	var tile := map.world_to_tile(at)
	if map.pavement_inward(tile) == Vector2i.ZERO:
		# Not a pavement tile at all, or a junction belonging to both corridors at once — nothing
		# here has one band to be centred on.
		return at
	var offsets := map.corridor_offsets(tile)
	var x_offset := offsets.x
	var offset := x_offset if x_offset >= 0 else offsets.y
	var band_offset := Tuning.SIDEWALK_WIDTH * 0.5 if offset < Tuning.SIDEWALK_WIDTH \
			else float(Tuning.STREET_WIDTH) - Tuning.SIDEWALK_WIDTH * 0.5
	var shift := (band_offset - offset - 0.5) * Tuning.TILE_SIZE
	return at + (Vector2.RIGHT if x_offset >= 0 else Vector2.DOWN) * shift

## **A spread's rotation is a property of the street it stands on**, not a field on the row: a
## barrier that lies correctly across a north-south street lies along the kerb — parallel to the
## traffic, blocking nothing — on an east-west one, unless the direction it spreads in changes with
## the street. `CityMap.corridor_offset` answers which axis a tile's corridor runs on without
## caring what the tile's *type* is, so a `ROAD` tile (`checkpoint`, the barricade a stopped convoy
## leaves) is asked exactly the way a `SIDEWALK` tile is, with no second lookup for either
## (`WorldMap.corridor_offsets()`).
##
## A tile whose two coordinates are **both** inside a corridor band is a junction — belonging to
## two streets at once, with no single direction to be wrong about — and a tile whose coordinates
## are **neither** is off any corridor at all: a square, a park, a courtyard. Both keep the spread's
## long-standing lay along local X, which is what every row drew before this rule existed and is the
## smallest answer for ground that was never a street to lie across in the first place.
static func _spread_is_vertical(map: WorldMap, at: Vector2) -> bool:
	var tile := map.world_to_tile(at)
	var alley := map.alley_at(tile)
	if alley.has_area():
		# An alley's barrier closes its short mouth, so a horizontal alley gets a vertical
		# spread and a vertical alley keeps the default horizontal spread.
		return alley.size.x > alley.size.y
	var offsets := map.corridor_offsets(tile)
	var on_a_north_south_street := offsets.x >= 0
	var on_an_east_west_street := offsets.y >= 0
	return on_an_east_west_street and not on_a_north_south_street

## The alley (`WorldMap.alley_at()`) that `at` falls inside, in **world** space, or an empty
## `Rect2` when it is not inside any — open ground, the building, or a placement that has fallen
## off the lattice. `corridor_offset` cannot answer this the way `_spread_is_vertical`
## does above: an alley is cut into the middle of a block rather than laid on the periodic street
## pattern that function reads, so its own tiles are never on a corridor at all.
static func _alley_rect_at(map: WorldMap, at: Vector2) -> Rect2:
	var rect := map.alley_at(map.world_to_tile(at))
	return map.tile_rect_to_world(rect) if rect.has_area() else Rect2()

## A two-point dash across the **short** side of the alley `at` sits in, for `alley_mouse` — see
## `EventCatalogue._alley_mouse()`. `_alley_rect_at` gives the alley's own rect rather than a
## direction guessed from the street lattice, so the choice of axis is exact: `ALLEY_WIDTH_TILES`
## (2) is always the narrower side of a real alley, and she can only be walking the longer one, so
## crossing the narrower side is crossing her path by construction rather than by luck.
##
## Falls back to a short fixed dash along local X where no alley holds it — `_alley_rect_at`
## returning empty — which a city's `MAP` placement never lets happen: on open ground, and in the
## building, whose basement mouse crosses its corridor this way.
static func _alley_crossing_path(map: WorldMap, at: Vector2) -> PackedVector2Array:
	var rect := _alley_rect_at(map, at)
	if rect.size == Vector2.ZERO:
		return PackedVector2Array([at - Vector2(32.0, 0.0), at + Vector2(32.0, 0.0)])
	if rect.size.y > rect.size.x:
		# Narrower in X: a vertical alley, walked along Y, crossed along X.
		return PackedVector2Array([Vector2(rect.position.x, at.y),
				Vector2(rect.position.x + rect.size.x, at.y)])
	# Narrower in Y, or square (never happens at `ALLEY_WIDTH_TILES` 2 against a block-length
	# alley, but ties go the same way `_spread_is_vertical` ties do): a horizontal alley, walked
	# along X, crossed along Y.
	return PackedVector2Array([Vector2(at.x, rect.position.y),
			Vector2(at.x, rect.position.y + rect.size.y)])

## Whether a stationary vehicle is seen side-on at this point. The moving van faces along the
## street and the burnt car lies perpendicular to it. A junction or ground outside the lattice has
## no single street axis, so the vehicle's own facing supplies the coherent default.
static func _stationary_vehicle_uses_side(row_look: EventDef.Look, map: WorldMap, at: Vector2,
		face: Vector2) -> bool:
	var offsets := map.corridor_offsets(map.world_to_tile(at))
	var on_a_north_south_street := offsets.x >= 0
	var on_an_east_west_street := offsets.y >= 0
	if on_a_north_south_street != on_an_east_west_street:
		var parallel_side := on_an_east_west_street
		return not parallel_side if row_look == EventDef.Look.BURNT_OUT_CAR else parallel_side
	return absf(face.x) >= absf(face.y)

func _ready() -> void:
	# Stepped on the physics tick (`EventManager` steps it), so it is drawn interpolated between two
	# ticks as she is, and moves as smoothly as she does. Placed here, so drawn from where it stands
	# rather than gliding in from the origin.
	reset_physics_interpolation()
	EventBus.event_telegraphed.emit(self)
	_telegraph_announced = true
	# `EventDef.SolidWhen.ONCE_IT_STARTS` is the one row shape that does not put its body down here
	# — see its own doc, and `_become_solid_once_it_starts()` below, which is where it goes down.
	if def.obstructs_radius > 0.0 and def.solid_when != EventDef.SolidWhen.ONCE_IT_STARTS:
		_build_obstruction()
	# A car's body is its `shape` (`EventDef.vehicle`), put down here like any other unless she is
	# already where it would stand, in which case `_become_solid_once_it_starts()` puts it down the
	# first frame she is not — a body never goes down around her.
	if car and car.gap_to_her(position, _heading) >= 0.0:
		_build_obstruction()
	if flock:
		flock.build()
	look.build_nodes()

## `+1` or `-1`: which side of a band laid along `vertical`'s axis the offset `toward` falls on,
## across it. Level with the band's own line counts as `+1`.
static func _guard_side_toward(vertical: bool, toward: Vector2) -> int:
	var across := toward.x if vertical else toward.y
	return -1 if across < 0.0 else 1

## **Where a posted roadblock guard's feet stand relative to the band's centre: beside it, never
## over it.** *(2026-09-25: "also the guards are on top of the barrier?")* The whole of his standing
## picture is kept clear of the whole of the barrier's, `_GUARD_POST_CLEARANCE` apart, on `side`:
##
## - **End-on** (`vertical`), the column is as wide as `roadblock_segment_vertical.svg`, so he stands
##   level with the band's centre, half the column's width and half his own out to the east or west.
## - **Broadside**, the barrier stands as tall as `roadblock_segment.svg` on the band's line, so to
##   the north his feet stand that far behind it and to the south his own height in front of it —
##   his head clear of the barrier's foot rather than over it.
##
## Measured off the pictures themselves, so a redrawn barrier or guard moves the post with it.
static func guard_post_offset(vertical: bool, side: int) -> Vector2:
	var guard := EventPictures.native_size(EventPictures.GUARD_STANDING_BY_VIEW["front"])
	if vertical:
		var column := EventPictures.native_size(EventPictures.ROADBLOCK_SEGMENT_VERTICAL)
		return Vector2(signf(side) * (column.x * 0.5 + guard.x * 0.5 + _GUARD_POST_CLEARANCE), 0.0)
	if side < 0:
		return Vector2(0.0,
				-(EventPictures.native_size(EventPictures.ROADBLOCK_SEGMENT).y
				+ _GUARD_POST_CLEARANCE))
	return Vector2(0.0, guard.y + _GUARD_POST_CLEARANCE)

## Which way a posted guard faces: straight out from the barrier on his own side, towards where she
## would come from — so the turn to face her the frame the near one notices her is still a turn.
static func guard_post_heading(vertical: bool, side: int) -> Vector2:
	var outward := Vector2.RIGHT if vertical else Vector2.DOWN
	return outward * (-1.0 if side < 0 else 1.0)

## Where its body stands, which is where the street is still shut: `global_position`, or where a
## barrier's guard left it (`EventBarrierPost.body_position()`), so a caller never has to ask which
## case it is holding.
func body_position() -> Vector2:
	return barrier_post.body_position() if barrier_post else global_position

## **Whether a waiting charger would raise his warning in her view**: the whole of his warning
## picture (`warning_rect()`) inside the camera's view this frame (`player_view`). *(Inbox #788 in minty-lemur, the
## player: the warning should be visible on screen.)* Every charger that waits for her and pursues
## notices her only then, on a day as in the escape, so his warning never starts off the screen, and
## his warning's clock starts from there. The view is the camera's own, look-ahead and trailing
## included. Always true for any other row, and for an instance nobody has handed a view
## (`player_view` empty, a rig that steps it directly), where the notice is the radius alone.
func _would_stand_in_her_view() -> bool:
	if def.pursuit == null or not warns_by_radius() or not player_view.has_area():
		return true
	return player_view.encloses(warning_rect())

## The world rect his warning picture fills, at the widest and tallest of its views, standing on his
## feet: a roadblock's guard at the post on her side of the band (`warning_guard_rect()`), anyone
## else where he stands.
func warning_rect() -> Rect2:
	if barrier_post:
		return warning_guard_rect(_spread_vertical, body_position(), player_at)
	var size := _warning_picture_size(def.look)
	return Rect2(global_position - Vector2(size.x * 0.5, size.y), size)

## The largest of a look's warning pictures: the dog's alert, the robber's two alert frames, and the
## guard's raised hand for anyone else drawn standing in a warning.
static func _warning_picture_size(row_look: EventDef.Look) -> Vector2:
	if _warning_sizes.has(row_look):
		return _warning_sizes[row_look]
	var families: Array[Dictionary] = [EventPictures.GUARD_ALERT_BY_VIEW]
	if row_look == EventDef.Look.CHARGING_DOG:
		families = [EventPictures.CHARGING_DOG_ALERT_BY_VIEW]
	elif row_look == EventDef.Look.ROBBER:
		families = [EventPictures.ROBBER_ALERT_BY_VIEW, EventPictures.ROBBER_ALERT_BY_VIEW_B]
	var size := Vector2.ZERO
	for family in families:
		for view: String in family:
			size = size.max(EventPictures.native_size(family[view]))
	_warning_sizes[row_look] = size
	return size

static var _warning_sizes := {}

## The world rect a roadblock's guard fills with his hand raised, standing at the post on `her` side
## of a band at `band_at` laid along `vertical` — what his warning draws
## (`RoadblockLook.chaser_pictures()`), at the widest and tallest of its views, standing on his
## feet.
static func warning_guard_rect(vertical: bool, band_at: Vector2, her: Vector2) -> Rect2:
	var feet := band_at + guard_post_offset(vertical, _guard_side_toward(vertical, her - band_at))
	if _warning_guard == Vector2.ZERO:
		for view: String in EventPictures.GUARD_ALERT_BY_VIEW:
			_warning_guard = _warning_guard.max(
					EventPictures.native_size(EventPictures.GUARD_ALERT_BY_VIEW[view]))
	return Rect2(feet - Vector2(_warning_guard.x * 0.5, _warning_guard.y), _warning_guard)

static var _warning_guard := Vector2.ZERO

## Some events are physically in the way. The body is a child so it travels with a mobile
## event and disappears with the instance.
##
## **Built from the row's solid footprint** (`solid_footprint_of()`), the one the day's blocked
## record is written from too (`EventSpawner.obstructed_footprint()`), so the body that stops her and
## the tiles that stop every other mover are one solid read twice. One `StaticBody2D` holds every
## piece, so nothing downstream — the debug view's bounding-box layer, which walks the physics
## tree, or `is_solid()` — has to learn that a row may have more than one.
func _build_obstruction() -> void:
	var body := solid_footprint_of(def, _solid_axis(), _spread_vertical).body()
	add_child(body)
	_obstruction = body

## **A row's solid footprint**, its origin at the row's own: one piece per `EventDef.parts()`
## entry — one at the origin carrying `shape` for every row that declares none, a car per piece
## for the crash — each offset along the spread axis (`spread_vertical`, `spread_at()`) by the
## piece's own reading of whichever picture is in use, its spine along `axis` (`_solid_axis()`).
## The physics body (`_build_obstruction()`) and the blocked record
## (`EventSpawner.obstructed_footprint()`) both come from here.
static func solid_footprint_of(row: EventDef, axis: Vector2, spread_vertical: bool) -> Footprint:
	var footprint := Footprint.new()
	for piece in row.parts():
		var offset := piece.offset_for(spread_vertical)
		footprint.add(piece.shape,
				Vector2(0.0, offset) if spread_vertical else Vector2(offset, 0.0), axis)
	return footprint

## How far a figure's body reaches round its feet when the row's own shape is the solid it stands
## at rather than the figure — a guard at his band — in px: the alley robber's own, a man on foot.
const FIGURE_RADIUS := 9.0

## **What a row walks as** (`Mover`): a car that drives as a vehicle, kept to the street and passing
## a soft seal's pavement; anything else as a figure on foot, stopped by everything that stops her.
## Its radius is the row's own shape where that shape is the thing that moves — a dog, a bike, a
## car — and a man's (`FIGURE_RADIUS`) where the shape is a solid he stands at.
static func mover_for(row: EventDef) -> Mover:
	var radius := FIGURE_RADIUS
	if row.shape != null and (row.obstructs_radius <= 0.0 or row.vehicle != null):
		radius = row.shape.reach()
	return Mover.vehicle(radius) if row.vehicle != null else Mover.on_foot(radius)

## Where each of this instance's solid pieces stands, in world space — paired index for index with
## `solid_part_shapes()` below, the same two-parallel-arrays shape `flock_offsets()` and
## `flock_velocities()` already hand `DebugLayers`.
##
## **A per-tile solid record reads the same pieces, index for index.**
## `EventSpawner.obstructed_footprint()` steps `def.parts()` on its own rather than calling this
## pair, but it is the same data: one disc of `obstructs_radius` for every row but the crash, which
## records tiles under each car and leaves the ground between them open — the whole reason the crowd
## steps round the cars and walks the debris.
func solid_part_centres() -> PackedVector2Array:
	var centres := PackedVector2Array()
	for piece in def.parts():
		centres.append(global_position + spread_at(piece.offset_for(_spread_vertical)))
	return centres

## The `GroundShape` of each solid piece, index for index with `solid_part_centres()`. Each lies
## along `solid_axis()`, the same axis its collision shape and its shadow are rotated by.
func solid_part_shapes() -> Array[GroundShape]:
	var shapes: Array[GroundShape] = []
	for piece in def.parts():
		shapes.append(piece.shape)
	return shapes

## Built by `set_halo_strength()` the first time `ExcitementHalo` picks this instance, never in
## `_ready()`: a day has dozens of events live at once, and a rim each would take every block the
## web's renderer can read — see `EntityHalo`'s class doc. `EntityHalo` gets the look's own
## `EventLook.draw_body` and `EventLook.current_bob` so its ring rides the same lift
## `EventLook.draw()` gives the body.
func _build_halo() -> void:
	_halo = EntityHalo.new(look.draw_body, look.current_bob)
	var holder := _rim_holder()
	holder.add_child(_halo)
	_halo.position = global_position - holder.global_position
	# **First child, so first of the behind-parent drawers.** The rim and the visible scene's layers
	# (`EventScenery`) both opt into `show_behind_parent`, and siblings that do are painted in
	# tree order, so a rim after the scenery, which `_ready()` builds long before any pick, would
	# paint over the pictures it is meant to outline.
	holder.move_child(_halo, 0)

## What the rim stands behind: this node, or what the look names instead (`EventLook.rim_holder()`,
## the first slice of a long picture drawn in slices, so the rim is behind the whole picture as it
## is behind a picture drawn on this node).
func _rim_holder() -> Node2D:
	var holder := look.rim_holder()
	return holder if holder != null else self

## Whether this instance is solid right now. True from `_ready()` for anything with
## `obstructs_radius`, false once a pursuer that had a body stops waiting — see `_tick()` —
## false through the notice of a `SolidWhen.ONCE_IT_STARTS` row, which is what that setting is for, and
## false while a boom (`EventDef.SolidWhen.WHILE_LOWERED`) stands raised.
func is_solid() -> bool:
	return _obstruction != null \
			and not (def.solid_when == EventDef.SolidWhen.WHILE_LOWERED and is_raised())

## Whether this boom's arm is up right now — `RegionPlanner.GateState.raised`, which only `Crowd`
## writes. `false` with no `gate_state`, the same safe default the drawing reads: a gate that has
## not been wired to the cars is a lowered one.
func is_raised() -> bool:
	return gate_state != null and gate_state.raised

## A boom's body follows its arm: solid while it is down, not while it is up. *(2026-09-24, the
## player: "I didn't say it should stay solid when it's open".)* Called once a step from
## `_tick()`; the shapes are switched rather than the body freed and rebuilt, so nothing that
## holds the body — the debug view's bounding-box layer — ever sees it vanish.
##
## **It never comes down on her, and that is `Crowd`'s half, not this one's.** The arm is the one
## fact both halves read, and `Crowd._stop_for_gates()` does not lower it while she is under it, so
## the body cannot go down around her: following the arm is enough. Deferred, because the switch
## can land while the physics server is mid-query.
func _let_the_body_follow_the_arm() -> void:
	if def.solid_when != EventDef.SolidWhen.WHILE_LOWERED or _obstruction == null:
		return
	var open := is_raised()
	if open == _arm_was_open:
		return
	_arm_was_open = open
	for child in _obstruction.get_children():
		var collision := child as CollisionShape2D
		if collision:
			collision.set_deferred("disabled", open)

## What `_let_the_body_follow_the_arm()` last set the shapes to, so a boom standing still in either
## position costs a comparison rather than a deferred call a frame.
var _arm_was_open := false

## The body of a `SolidWhen.ONCE_IT_STARTS` row, put down the frame its notice ends — **unless she is
## standing in it**, in which case the vent goes on emitting at full rate and stays passable until
## she is out of the footprint.
##
## Her centre comes to rest `obstructs_radius + PLAYER_BODY_RADIUS` from the middle of a body, so
## that distance is exactly "inside it": closing at any point nearer would put a wall around her
## rather than in front of her, and the only ways out of one are teleporting her or deleting the
## body again, which are a repair and an admission respectively. Deferring costs nothing and can
## only leave ground reachable that would otherwise have been closed.
##
## `player_at` is `Vector2.INF` until something tells the instance where she is — every world that
## has her does, once a frame — and an infinite distance is outside every footprint, so a rig with
## no player in it gets the body immediately rather than never.
func _become_solid_once_it_starts() -> void:
	if car and _obstruction == null and car.gap_to_her(position, _heading) >= 0.0:
		_build_obstruction()
		return
	if def.solid_when != EventDef.SolidWhen.ONCE_IT_STARTS or _obstruction != null:
		return
	if is_finished or is_leaving or is_waiting() or is_telegraphing():
		return
	if global_position.distance_to(player_at) <= def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS:
		return
	_build_obstruction()

# -------------------------------------------------------------------- a car ---
# `EventDef.vehicle`: a body that moves and never into her, and a strike ahead of its nose while it
# drives — `EventCarDriving`, which answers for the car below.

## The lights the crowd's cars stop at, told by `EventManager` when the instance is made, so a car
## that drives stops where they stop (`EventCarDriving.room_to_its_line()`). Null in a rig with no
## city, which then has no red light to stop at.
var signals: TrafficSignals = null

## **The end of its route, reached or cut short** (`EventRouteWalk`): it is done there, unless a
## car's frame is open, which acts on it only once the pose that reached it is kept
## (`EventCarDriving.end_its_route()`).
func _end_its_route(may_park := true) -> void:
	if car != null and car.end_its_route(may_park):
		return
	_be_done(may_park)

## Whether the frame record (`FrameRecord`) was running when this event was made, read once here
## so that, with the record off, `_process()` pays one member read rather than a static read and a
## call into a second function: with the crowd's agents beside the live events, that difference
## made every player's frame measurably longer on a desktop
## (docs/evidence/m159-frame-record-2026-10-04/). An event is made per day, after the recorder has
## started, so every one made under a record is timed.
var _timed := FrameRecord.on

## **A drawn frame only redraws.** What the event does is stepped on the physics tick by its manager
## (`step()`); here its look asks for a redraw if the picture changed, moves its drawing nodes and
## hides what a finished event leaves (`EventLook.redraw_if_the_picture_changed()`), from the state
## the last tick left. Timed under the record's events, as the step is.
func _process(_delta: float) -> void:
	if look == null:
		return
	if _timed and FrameRecord.on:
		var outer := FrameRecord.enter(FrameRecord.EVENTS)
		look.redraw_if_the_picture_changed()
		FrameRecord.leave(outer)
		return
	look.redraw_if_the_picture_changed()

## Whether a hand holds it still, so its manager does not step it: a scene recipe that walks it
## itself (`SceneRecipeRuntime`). Its drawing goes on.
var held_by_hand := false

## **One physics tick of the event**, which its manager runs in a fixed order
## (`EventManager._step_them()`): the tick, inside a car's proposed frame for a car that drives
## (`EventCarDriving`), which commits the pose the tick ends on or takes it back. Nothing once it is
## finished.
func step(delta: float) -> void:
	if is_finished:
		return
	if car == null:
		_tick(delta)
		return
	car.begin_frame()
	_tick(delta)
	car.end_frame()

## What it does in one tick, run by `step()`.
func _tick(delta: float) -> void:
	_clock += delta
	_age += delta
	_hold_the_notice_clock(delta)
	_settle_the_notice()
	if barrier_post:
		barrier_post.far.walk_off(delta)
	# The gait phase advances by whatever this tick actually adds to `_path_travelled` below,
	# whichever behaviour does the adding or none of them — see `_advance_gait()`, called once at
	# every exit from this function.
	var _travelled_before := _path_travelled

	if not _activation_announced and not is_telegraphing():
		_activation_announced = true
		EventBus.event_activated.emit(self)

	if is_leaving:
		departure.leave(delta)
		for behaviour in _behaviours:
			behaviour.step_leaving(delta)
		_advance_gait(_path_travelled - _travelled_before)
		if barrier_post and barrier_post.has_left_its_body() and not is_finished:
			# He walks off and the barrier does not go with him: its body stays where it was built
			# through the departure as through the chase (its picture is its own node).
			barrier_post.keep_the_body()
		return

	if is_chatting():
		# The one thing that runs while she is otherwise frozen (`EventHold.step()`): her own controls
		# are locked by `Stroller.detain()`, and here only the hold's clock runs.
		hold.step(delta)
		# Frozen, so no distance is covered — `_advance_gait(0.0)` marks the frame stopped rather
		# than leaving `_gait_moving` at whatever it read the tick before the conversation started.
		_advance_gait(0.0)
		return

	# What it does, in the order it was composed (`EventBehaviours.compose()`): each behaviour
	# decides for itself whether this tick is one it acts on.
	for behaviour in _behaviours:
		if behaviour.steps_each_tick:
			behaviour.step(delta)

	# A car that drives keeps its body through a chase (`EventDef.vehicle`): cars that drive are the
	# only bodies that move, and `EventCarDriving` is what keeps them off her.
	if _obstruction and def.pursuit != null and def.vehicle == null and not is_waiting():
		# **Anything that stands still is solid at the width it is drawn, and nothing else is.**
		# `_step`'s own note says why a moving pursuer may not keep a body: "giving a
		# pursuer one would let a moving wall pin her against a building on a two-tile pavement."
		# A hunting `abduction` or raid never gets here: it hunts on foot (`EventDef.hunts_on_foot`)
		# and stays parked, solid, while its men come after her.
		#
		# **`PursuitSpec.leaves_its_body` is the other case, and it is not an exception to that rule.** The
		# body still stops moving with the pursuer; it stops moving at all. A barrier built across
		# a road is not the bulk of the man who was standing at it, so he walks out of it and it
		# stays where it was built — the street he abandoned stays shut. Nothing is pinned, because
		# nothing follows her.
		if barrier_post:
			barrier_post.leave_the_body()
		else:
			_obstruction.queue_free()
			_obstruction = null

	_become_solid_once_it_starts()
	_let_the_body_follow_the_arm()

	_advance_gait(_path_travelled - _travelled_before)
	if _has_expired():
		_be_done()
	if barrier_post and barrier_post.has_left_its_body() and not _guard_spent:
		# The body is a child of a node that is walking away, so it is re-pinned on every frame he
		# moves. The band's picture is its own node (`RoadblockLook.RoadblockBand`), which stands at
		# the body and needs no redraw for it. A spent guard moves nothing, so there is nothing to
		# re-pin.
		barrier_post.keep_the_body()
	_take_the_layer_it_warns_on()

## **A pursuer that warns over the street is drawn on the warning layer for the whole of its
## warning** (`PursuitSpec.warns_over_the_street`, `DrawLayer.Layer.WARNING`): the roadblock's guard,
## from the frame he steps out to his post with his hand raised until he charges, over every figure
## on the street, under the city's overhead layer. Once he charges he sorts with the street again,
## on the entity layer at his own feet.
func _take_the_layer_it_warns_on() -> void:
	if def.pursuit == null or not def.pursuit.warns_over_the_street:
		return
	DrawLayer.draw_on(self, DrawLayer.Layer.WARNING if is_standing_for_its_notice()
			else DrawLayer.Layer.ENTITIES)

# ------------------------------------------------------------------- the hold ---

## Whether a conversation or a door's hold is running right now (`EventHold`). Freezes pacing (see
## `_tick()`) and switches a mother's posture from strolling to talking
## (`FigureLook._draw_chatting_mother`).
func is_chatting() -> bool:
	return hold != null and hold.is_running()

## Whether the guard this instance draws is inside with her for its own hold right now — he is the
## one taking her in, so he is not also standing in the street, see
## `Stroller.hide_for_inspection()`. `def.redetains` is the flag only `checkpoint_hut` and
## `checkpoint_post` carry — the boom, `checkpoint_gate`, blocks rather than inspects — so
## `chatting_mother` — same mechanism, no `redetains` — keeps her ordinary talking posture for the
## whole of her own conversation instead.
func is_its_guard_inside() -> bool:
	return def.redetains and is_chatting()

## Whether a checkpoint's own hold suppresses *every* drawing of this instance, halo included.
##
## **True only where the guard is the whole of what this row draws.** `checkpoint_post` is one
## man at an alley mouth and nothing else, so when he goes in there is nothing left to draw; a hut
## is a building and a gate is a boom across a road, and *(PLAYTEST-57: "the checkpoint house
## disappears ... all this is incorrect".)* A structure that blinks out while she is inside it
## reads as the door having been removed rather than as her having gone through it, which is the
## opposite of what the hold is for.
##
## Read by `EventLook.draw()`, by `EventLook.draw_body()` (the halo's own re-draw entry point — see
## that function's doc for why the halo needs its own guard rather than inheriting
## `EventLook.draw()`'s), and by a test, so the three can never drift apart from each other.
func is_suppressed_by_its_own_hold() -> bool:
	return is_its_guard_inside() and def.look == EventDef.Look.CHECKPOINT_POST

## Whether this instance has ever held her (`EventHold.has_held()`). A row that does not redetain
## never holds her twice.
func has_chatted() -> bool:
	return hold != null and hold.has_held()

## Starts a hold, the frame `CheckpointController.check_detentions()` decides she has come within
## `def.detain_distance()` of an instance that may take her (`EventHold.start()`).
func start_chat() -> void:
	if hold:
		hold.start()

## Whether the chase ended because she shook it off rather than because the clock ran out. Read by
## the telemetry, which is the only thing that can tell the two apart from outside.
var gave_up := false
## **Its notice's clock** (`Warning`, read against `age`): started when it exists for a row with no
## wait, and when it notices her for one that waits (`EventDef.notice`); stopped while it waits.
## `chase_age()` is its elapsed time, and a stream-out carries its start (`noticed_at()`).
var _notice := Warning.new()
## Its charge as it is counted — its warning, its start and the one way it ended — and the one
## owner of the rule that a charge that began ends in exactly one way (`ChargeRecord`). A row with
## no wait (`is_waiting()` never true) starts chasing on its very first `EventPursuit` call rather than
## on a notice, so whether it has begun is the record's `began`.
var _charge := ChargeRecord.new(Callable(self, &"charger_name"), EventBus)
## **A checkpoint hut's guard raising his hand**: true while a crossing of this hut's door is
## warning her and this hut is the one across the road from her, or this alley post's
## (`CheckpointController.warn_at_the_doors()`, which sets it every frame); once the crossing's
## warning has run with her still across, this hut's guard comes out and charges at once
## (`PursuitSpec.Start.CHARGES_AT_ONCE`). Drawn with `guard_alert_front` beside the hut instead of
## `guard_standing` (`CheckpointLook._draw_checkpoint_hut()`).
var guard_warns_her := false

## **Whether this instance has a charging counter**: every pursuer, and a row that waits for her
## and runs its own line at her once she is near (`NoticeSpec.runs_within`, the masked man in the
## escape's stairwell). Telemetry only.
func counts_a_charge() -> bool:
	return def.pursuit != null or (def.notice != null and def.notice.runs_within > 0.0)

## The name a charge is counted under (`EventBus.pursuit_warned`, `pursuit_began`, `pursuit_caught`,
## `pursuit_ended`): the row's `EventDef.counts_charges_as` where it sets one (the task guard sent
## from out of her view counts as `task_guard`), otherwise the row's own `def.id` — the day-3
## lesson's dog is `charging_dog_tutorial` by its own row. Telemetry only.
func charger_name() -> String:
	return def.counts_charges_as if def.counts_charges_as != "" else def.id

## **Its charge caught her**, said once: by `EventManager._check_hard_fails()` when its catch ends
## the day, ahead of `hard_fail_triggered`, and by a patrol car's man the frame he stops her
## (`EventOfficer`), whose catch does not. Telemetry only: it sends
## `EventBus.pursuit_caught` and keeps `_be_done()` from also sending `pursuit_ended`, so a charge
## ends in exactly one of caught, shaken off, outlasted and cut short, whatever the day does
## *(inbox #764 in minty-lemur, the player: "Charging is independent of an ended day")*. Nothing for
## a row with no charging counter
## (`counts_a_charge()`) or a charge that has not begun.
func report_the_catch() -> void:
	if counts_a_charge():
		_charge.catch()

## **Its charge was cut short**: the day, or the escape's section, ended some other way while it
## was still charging — the meter reached its cap, another thing caught her, she reached home.
## Sends `EventBus.pursuit_cut_short` once, so that charge too ends in exactly one counted way.
## Asked by `EventManager.end_the_charges_still_running()` as a walk ends.
## Telemetry only.
func report_the_charge_cut_short() -> void:
	if counts_a_charge() and not is_finished:
		_charge.cut_short()

## Sends `EventBus.pursuit_warned` once for this instance: its warning has gone up. Never for one
## that charges at once (the checkpoint guard): his warning was the hut's or the post's guard's
## raised hand, counted where it went up (`CheckpointController`), so a crossing counts one warning
## at an alley's door as at a boom.
func _report_the_warning() -> void:
	if counts_a_charge() and not def.starts_by(PursuitSpec.Start.CHARGES_AT_ONCE):
		_charge.warn()

## **Whether its notice is a warning she is shown, standing**, rather than its approach: one that
## warns by radius, the man a vehicle lets out (`PursuitSpec.Start.SETS_OFF_BESIDE_HER`), day 13's
## guard raising his warning in her view. Its charge, and so its `-chased`, comes only when that
## ends; a pursuer whose telegraph is its approach (the day-3 dog) has come for her from its first
## frame.
func _its_notice_is_a_warning() -> bool:
	return warns_by_radius() or def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) \
			or _stands_for_this_notice

# ------------------------------------------------------------ the investigation ---

## A car that stood for its man is quiet until it has left her (`EventInvestigation`).
func is_quiet_for_its_man() -> bool:
	return investigation != null and investigation.is_quiet_for_its_man()

## How many men this vehicle has stopped for and still owes (`EventInvestigation`). Read by
## `EventsAhead.let_the_officers_out()`.
func officers_owed() -> int:
	return investigation.officers_owed() if investigation else 0

## Hands the vehicle one man `EventManager` put down at its door, so it stands until he is back and
## he walks back to that door (`EventInvestigation.let_out()`).
func let_out(officer: EventInstance) -> void:
	if investigation:
		investigation.let_out(officer)

## The first man this vehicle let out who is still in the world, or null.
func its_officer() -> EventInstance:
	var out := its_officers()
	return out[0] if not out.is_empty() else null

## Every man this vehicle let out who is still in the world.
func its_officers() -> Array[EventInstance]:
	if investigation == null:
		return [] as Array[EventInstance]
	return investigation.its_officers()

## Where a man gets out: beside the body's flank on her side, clear of it by his own reach, `along`
## px from its middle along its length — `side` 1 for her side, -1 for the other.
func door_for_its_officer(row: EventDef, side := 1.0, along := 0.0) -> Vector2:
	var across := _heading.orthogonal()
	if player_at != Vector2.INF and (player_at - global_position).dot(across) < 0.0:
		across = -across
	var reach := def.shape.radius + (row.shape.reach() if row.shape else 0.0) + 1.0
	return global_position + across * side * reach + _heading * along

# ------------------------------------------------------------------- the stop ---

## Whether she is inside a district door's hold this frame, told by
## `EventManager._tell_them_where_she_is()`: a man who would stop her waits outside for her
## (`EventOfficer`).
var she_is_held := false

## Whether this man has reached her and stopped her (`EventOfficer`, `PursuitSpec.stop_excitement`).
func has_stopped_her() -> bool:
	return on_foot != null and on_foot.has_stopped_her()

## **Ends this chase from outside it**, in the state `EventPursuit` leaves a pursuer she has outrun:
## `gave_up` set and `_be_done()` called, so the same departure, drawing and "gave up" line as an
## ordinary shake-off. A checkpoint hut's hold has done what the chase was for, whatever the chase
## was doing, a telegraph still running included (`CheckpointController.
## _end_the_guard_for_a_hold()`, 2026-09-24). A second call, or one on anything finished or
## leaving, is a no-op.
func give_up_the_chase() -> void:
	if is_finished or is_leaving:
		return
	gave_up = true
	_be_done()

## **Notices her now, wherever she is**: a waiting pursuer set on her by what she did rather than
## by what it saw — day 13's waiting guard the moment she has done the roadblock's task
## (`ResistanceDirector._set_the_task_guard_on_her()`, curly-gecko). It is
## `EventPursuit`'s notice without its range and its clear line: the clock starts, he turns to her,
## and from then on he is an ordinary pursuer, closing only to his stand-off while his notice runs
## and lunging only along a clear line; noticed inside his stand-off, his lunge is held
## (`EventPursuit.lunge_held`). A guard already warning her by sight is set on her the same way,
## since she could walk out of his warning and he would never come. Nothing for a row that does
## not pursue, a pursuer already charging, leaving or done, or a `her` of `Vector2.INF`. **A row
## that left before it ever noticed her still answers `is_waiting()`**, and the task guard is moved
## with his state rather than made again (`EventManager.move_extra()`), so the leaving guard is
## refused here: a man walking off is never turned back into a warning.
##
## `notice` replaces the row's `telegraph_time` for this notice when it is not negative, and `stand`
## has him stand still in his warning for it (`is_standing_for_its_notice()`): in her view, day
## 13's guard raises his warning for a second and then charges (inbox #764 in minty-lemur). From
## here he walks round buildings toward her (`_paths_to_her`), since he may start a city away.
func notice_her_at(her: Vector2, notice := -1.0, stand := false) -> void:
	if pursuit == null:
		return
	if not (is_waiting() or (is_telegraphing() and warns_by_radius())) or her == Vector2.INF \
			or is_finished or is_leaving:
		return
	# A warning of his own already under way gives way to the one the task sets: the lunge it held
	# back and the notice it held still start again from here.
	pursuit.lunge_held = false
	if stand:
		_charge.warned = false
	player_at = her
	_paths_to_her = true
	_notice_time = notice
	_stands_for_this_notice = stand
	_notice_her()
	var toward := her - global_position
	if toward.length() >= 1.0:
		_heading = toward.normalized()
	if toward.length() <= charge_radius():
		pursuit.lunge_held = true

## **The part of the step `delta_pos` this figure takes** (`Navigator.step()`): the whole of it where
## the swept step is open to it, else a slide along whichever single axis is, else none. Everything
## that moves this figure decides *how far and which way*; this is the one place that gets to say
## no, so a chase, a walk back and a departure all stop where she would.
##
## **Swept, and with its body's reach**: the tiles the whole step crosses are asked, so a long frame
## cannot carry a chaser through a wall a tile thick, and the ground its radius reaches past the
## landing point in the way it is going has to be open too. **Not a body**: `obstructs_radius` is
## for something that stands still — see "Solid things are solid" in docs/EVENTS.md — and giving a
## pursuer one would let a moving wall pin her against a building on a two-tile pavement, exactly
## what `dog_walker`'s own exemption exists to avoid.
##
## **Slides along whichever single axis is still open** rather than stopping dead the instant it
## grazes a corner, because a chase that gives up meters before the wall does is not one that was
## ever really following her round it. Tried larger component first, so a pursuer coming at a wall
## nearly square-on slides along it rather than snagging on whichever axis happens to be smaller.
func _step(delta_pos: Vector2) -> Vector2:
	return _navigator.step(global_position, delta_pos, _mover)

# ------------------------------------------------------ the task guard's way to her ---
# *(curly-gecko, the player: "as long as he starts pursuing when you hit the task it's fine".)*

## Whether this pursuer walks the way to her round buildings rather than straight at her: set by
## `notice_her_at()`, which only day 13's done task calls, for the waiting guard it sets on her
## from wherever he stands — at another roadblock, a city away, with blocks between them. Every
## other pursuer starts within sight of her or just off screen with a straight run at her, so it
## keeps the straight line `_step()` slides along walls. *Proposed, not asked for:* the way
## round is for this guard alone.
##
## **Where he has a clear line to her he goes straight at her**, exactly as before; only where a
## building stands between them does he follow the walk instead. The walk is a sweep out from her
## over the ground she can walk (`ArrowField`, the red arrow's own sweep, a slice a frame), and he
## steps down it toward her, aiming at the farthest of the next few tiles he can see.
var _paths_to_her := false
## The notice `notice_her_at()` was given, in seconds, or negative for the row's own
## `telegraph_time` (`notice_time()`).
var _notice_time := -1.0
## Whether `notice_her_at()` asked it to stand still with its warning up for that notice
## (`is_standing_for_its_notice()`), as day 13's task guard does in her view.
var _stands_for_this_notice := false
## The sweep he follows (`ArrowField`, out from where she stood when it began), or null before the
## first one has reached him.
var _her_way: ArrowField
## The ground `_her_way` was swept over, which is what the walk down it is asked against.
var _her_way_ground := PackedInt32Array()
## The sweep under way that will replace `_her_way`, its ground, and her tile it began from.
var _her_way_next: ArrowField
var _her_way_next_ground := PackedInt32Array()
var _her_way_next_from := Vector2i(-1, -1)
## Her tile `_her_way` was swept from.
var _her_way_from := Vector2i(-1, -1)
## The ground laid out for the sweeps, and the state of what blocks her it was laid out for
## (`WorldMap.day_record_version`, `WorldMap.obstruction_version`).
var _her_way_ground_laid := PackedInt32Array()
var _her_way_ground_versions := Vector2i(-1, -1)
## The tiles down `_her_way` from the tile he stood on when it was walked
## (`_her_way_chain_from`), as world points, nearest first; walked again when he is on another tile
## or the sweep changes.
var _her_way_chain := PackedVector2Array()
var _her_way_chain_from := Vector2i(-1, -1)
var _her_way_chain_field: ArrowField

## How many tiles of a sweep one frame of his chase runs: under half a millisecond, half the red
## arrow's slice (`ResistanceDirector.ARROW_SWEEP_TILES_PER_FRAME`), since his runs whenever she
## has moved on rather than only when the targets change. A sweep is adopted as soon as it has
## reached his tile, so from close by it takes a frame or two.
const WAY_SWEEP_TILES_PER_FRAME := 500
## How far, in tiles either way, she walks from where his sweep began before another is begun,
## at the least: close to her a sweep is a frame or two, and a walk two tiles stale is a corner cut
## wrong.
const WAY_REFRESH_TILES := 2
## **And while he is far, a sweep is begun only once she has walked a quarter of his walk to her**
## from where the last began. Far off, every sweep is many frames, and one begun every two tiles of
## her walk kept a sweep under way on most frames of a chase she walked away from; a walk that is
## a quarter stale still takes him the right way round the buildings, and it is refreshed more
## often the nearer he comes.
const WAY_REFRESH_SHARE := 4
## How many tiles down the sweep he looks for the farthest he can see to aim at, so his walk
## cuts the corners the four-way tile walk takes rather than zig-zagging along it.
const WAY_LOOKAHEAD_TILES := 6

## Begins a fresh sweep out from her when she has walked on from where the last began or what
## blocks her has changed, runs a slice of the one under way, and adopts it the moment it has
## reached his tile. A sweep runs the walk out from her in rings, so every tile at most as far as
## his is final once his is reached, and the walk down from his tile never asks one further out.
func _keep_the_way_to_her_fresh() -> void:
	if player_at == Vector2.INF or not _map.has_ground():
		return
	var versions := Vector2i(_map.day_record_version, _map.obstruction_version)
	if _her_way_next == null:
		var her := _map.world_to_tile(player_at)
		var stale := WAY_REFRESH_TILES
		if _her_way != null:
			var his := _her_way.length_at(_map.world_to_tile(global_position))
			stale = maxi(stale, floori(float(his) / WAY_REFRESH_SHARE))
		var moved := absi(her.x - _her_way_from.x) >= stale \
				or absi(her.y - _her_way_from.y) >= stale
		if _her_way != null and not moved and _her_way.versions == versions:
			return
		var target: Array[Dictionary] = [{"key": 0, "at": player_at, "reach": 0.0,
				"beat": PackedVector2Array()}]
		_her_way_next = ArrowField.start(_map, target, versions)
		_her_way_next_ground = _ground_for_the_way(versions)
		_her_way_next_from = her
		# Laying out the ground is a frame's work of its own, like the sweep's own layout.
		return
	_her_way_next.advance(_map, _her_way_next_ground, WAY_SWEEP_TILES_PER_FRAME)
	if _her_way_next.done or _her_way_next.length_at(_map.world_to_tile(global_position)) >= 0:
		_her_way = _her_way_next
		_her_way_ground = _her_way_next_ground
		_her_way_from = _her_way_next_from
		_her_way_next = null
		_her_way_next_ground = PackedInt32Array()

## The ground his sweeps run over, his own as a figure on foot and the red arrow's
## (`Navigator.ground()`, `ArrowField.ground_for()`): what she cannot walk right now is blocked —
## today's closures, the soft seals, the tile under every stationary body standing and a precinct's
## posts. So where no clear line runs to her he walks round what she has to walk round, and a line
## through any of it is no clear line (`clear_line_to()`). Laid out once for each state of what
## blocks her.
func _ground_for_the_way(versions: Vector2i) -> PackedInt32Array:
	if versions == _her_way_ground_versions and not _her_way_ground_laid.is_empty():
		return _her_way_ground_laid
	_her_way_ground_laid = _navigator.ground(_mover)
	_her_way_ground_versions = versions
	return _her_way_ground_laid

## Which way he walks toward her: `straight` where he has a clear line to her or no sweep has
## reached him yet, else toward the farthest of the next `WAY_LOOKAHEAD_TILES` tiles down the walk
## that he can see along open ground (`_way_is_open()`), or the next one where he sees none.
func _way_toward_her(straight: Vector2) -> Vector2:
	if _her_way == null or clear_line_to(player_at):
		return straight
	var here := _map.world_to_tile(global_position)
	if here != _her_way_chain_from or _her_way != _her_way_chain_field:
		_her_way_chain = _down_the_way(here)
		_her_way_chain_from = here
		_her_way_chain_field = _her_way
	if _her_way_chain.is_empty():
		return straight
	var aim := _her_way_chain[0]
	for i in range(_her_way_chain.size() - 1, 0, -1):
		if _way_is_open(global_position, _her_way_chain[i]):
			aim = _her_way_chain[i]
			break
	var toward := aim - global_position
	return toward.normalized() if toward.length() >= 1.0 else straight

## Up to `WAY_LOOKAHEAD_TILES` tiles down `_her_way` from `from`, each the open neighbour one step
## nearer her, as tile centres: empty where `from` is no part of the walk or is already where the
## sweep began.
func _down_the_way(from: Vector2i) -> PackedVector2Array:
	var chain := PackedVector2Array()
	var tile := from
	var length := _her_way.length_at(tile)
	if length < 0:
		return chain
	for i in WAY_LOOKAHEAD_TILES:
		var best := tile
		var best_length := length
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + offset
			if not _open_for_the_way(next):
				continue
			var next_length := _her_way.length_at(next)
			if next_length >= 0 and next_length < best_length:
				best = next
				best_length = next_length
		if best == tile:
			break
		tile = best
		length = best_length
		chain.append(_map.tile_to_world(tile))
	return chain

## Whether `tile` is ground his walk may step onto: walkable, and not blocked in the ground
## `_her_way` was swept over. Asked before `ArrowField.length_at()`, which answers a blocked tile
## through its neighbours and would otherwise lead him onto it.
func _open_for_the_way(tile: Vector2i) -> bool:
	if not _map.in_bounds(tile) or not _map.is_walkable(tile):
		return false
	return _her_way_ground[tile.y * _map.size.x + tile.x] != ArrowField.BLOCKED

## Whether he can walk straight from `from` to `to`: a clear line for him (`Navigator.clear_line()`),
## which crosses nothing his sweep's ground blocks either, since both read the one record.
func _way_is_open(from: Vector2, to: Vector2) -> bool:
	return _navigator.clear_line(from, to, _mover)

## How far along its route this instance has got, so streaming it out and back in can resume it
## instead of rewinding it. See `EventStreaming.stream_in`.
func path_travelled() -> float:
	return _path_travelled

## How fast and which way this thing is actually travelling, in px/s.
##
## Asked by `WarningBoard.warn_about_the_ground_she_is_on`, which has to know whether a lethal
## thing is coming *at her* rather than merely near her — walking orthogonally away from a cyclist
## must take the mark down, because there is no way it can reach her.
##
## Zero while a pursuer is telegraphing, and that is the interesting case rather than an omission:
## it is holding its stand-off, so it is not closing, and a mark that said otherwise would be
## warning her about a thing that is deliberately waiting.
func travel_velocity() -> Vector2:
	if is_finished or is_leaving:
		return Vector2.ZERO
	# **A parked row is not travelling, whatever its speed says.** The screen-edge badge reads this
	# as a closing speed, and an engine standing at a kerb is not closing on anybody.
	if is_parked:
		return Vector2.ZERO
	if def.pursuit != null:
		if is_waiting() or is_telegraphing():
			return Vector2.ZERO
		return _heading * def.chase_speed()
	if def.mobile and def.speed > 0.0 and path.size() > 1 and not is_telegraphing_still():
		return _heading * def.speed
	return Vector2.ZERO

## `travel_velocity()`'s own answer, except for a pursuer that has been noticed and is holding
## its telegraph's stand-off: the caret's projection asks where this is *going*, which is
## `PursuitSpec.speed` toward her the instant it has decided to come, not the moment its lunge is
## allowed to fire. `travel_velocity()` itself has to stay zero there — the exclamation mark's
## "it is not closing" reads that answer literally, and a mark that said otherwise would warn her
## about a thing that is deliberately holding still — so this is a second query for the caret
## alone rather than a change to the first one.
##
## **A waiting pursuer still has no course.** `is_waiting()` means nobody has been noticed yet, so
## there is nothing here to project toward; only the moment it decides changes the answer, exactly
## as `travel_velocity()` already has it.
func _caret_velocity() -> Vector2:
	if is_finished or is_leaving:
		return Vector2.ZERO
	if def.pursuit != null:
		if is_waiting():
			return Vector2.ZERO
		return _heading * def.chase_speed()
	return travel_velocity()

## Which way this instance was sited facing (`setup()`'s own `face`), unmoved for anything
## stationary that never turns. A door body's own facing is the street's along-axis rather than
## the direction it is drawn — `RegionPlanner` sites every `checkpoint_hut`/`checkpoint_gate`/
## `checkpoint_post` at a crossing facing the same way — so `EventManager`'s detention teleport can
## read this back as which side of the crossing she is on, whichever of the three bodies actually
## detained her.
func facing_now() -> Vector2:
	return _heading

## Where on its own clock it noticed her, held time counted back in, or `INF` for a row that waits
## and has not noticed her (and for a row with no wait) — what a stream-out carries
## (`EventStreaming.stream_out()`) and `resume()` gives back.
func noticed_at() -> float:
	return _notice.started_at() if def.notice != null else INF

## Noticing her: its notice's clock starts now and it is warning (`Phase.WARNING`), or already past
## a notice of no length.
func _notice_her() -> void:
	_notice.start(age)
	transition(Phase.WARNING)
	_settle_the_notice()

## Puts an instance back where a previous incarnation of the same plan had got to. Restores the
## age as well as the distance, so the telegraph, the pulse phase and the duration all continue
## rather than starting again — an event that streams in and out must not become immortal by
## being visited twice. `from_noticed_at` restores a notice it had made (`noticed_at()`), so a row
## streamed out after it had noticed her does not come back standing where the day planted it.
func resume(from_age: float, from_travelled: float, from_noticed_at := INF) -> void:
	if from_age <= 0.0:
		return
	age = from_age
	_path_travelled = from_travelled
	if def.notice != null and from_noticed_at != INF:
		_notice.start(from_noticed_at)
		transition(Phase.WARNING)
		_settle_the_notice()
	# A pursuer streamed back in still waiting is the one case that has not begun chasing yet; every
	# other, a row with no wait included, was chasing before it streamed out. **A row created where
	# its warning pointed is not streamed back in**: `EventManager.spawn_warned()` sets
	# `came_under_a_warning` before calling this only to spend a telegraph the warning already ran.
	_charge.began = not came_under_a_warning and not is_waiting()
	# A warning it had already given before it streamed out is not reported again.
	_charge.warned = from_noticed_at != INF
	# A stride never starts mid-cycle, the same reason `setup()` resets it — a resumed instance is
	# a fresh object (see this function's own doc), so this is normally already true, but the rule
	# is stated at both entry points rather than left to rely on that.
	_gait_phase = 0.0
	_gait_moving = false
	if def.mobile and path.size() > 1:
		route.advance(0.0)
	# Put back where it was, not slid there from wherever it was made.
	reset_physics_interpolation()

## **Stands it at `at`, keeping everything it is in the middle of**: its phase, its notice, every
## behaviour's state. What setup reads off the ground it stands on is read again for the new ground
## (the axis of a spread, which side a parked vehicle shows, its idle phase), and its field is asked
## afresh. `EventManager.move_extra()` is the caller, which records its body again.
func move_to(at: Vector2) -> void:
	global_position = at
	_spread_vertical = _spread_is_vertical(_map, at)
	_stationary_vehicle_side = _stationary_vehicle_uses_side(def.look, _map, at, _heading)
	_idle_phase_offset = _position_roll(101)
	_invalidate_contribution_cache()
	reset_physics_interpolation()
	queue_redraw()

## **Every behaviour's own state**, keyed by its class, as plain values a plan carries while this
## event is out of the world (`EventStreaming.stream_out()`, `EventScheduler.Planned.behaviours`).
func save_behaviours() -> Dictionary:
	var out := {}
	for behaviour in _behaviours:
		var state := behaviour.save()
		if not state.is_empty():
			out[behaviour.get_script().get_global_name()] = state
	return out

## Puts back what `save_behaviours()` gave, after `resume()` has put back the age, the distance and
## the notice. A row composed of a behaviour the state does not name keeps it fresh.
func restore_behaviours(state: Dictionary) -> void:
	for behaviour in _behaviours:
		var key: StringName = behaviour.get_script().get_global_name()
		if state.has(key):
			behaviour.restore(state[key])

# ------------------------------------------------------------------- the take ---

## Where the instance writes its own account for the run log, handed in by the manager that
## creates it; silent otherwise.
var trace := RunTrace.new()

## Whether the van's take of a bystander is running right now (`EventAbduction`), for
## `EventVehicleLook._draw_abduction` and for a test to drive by hand.
func is_taking_a_victim() -> bool:
	return abduction != null and abduction.is_taking()

# ------------------------------------------------------------------ the flock ---

## The radius one bird emits over (`EventFlock.bird_outer()`), read by `DebugLayers` so a flock's
## own fields layer draws the exact radius `_flock_contribution_at()` sums over.
func flock_outer_radius() -> float:
	return flock.bird_outer() if flock else 0.0

## Each live bird's own ground-plane offset from this instance's origin — empty for anything
## without a flock. What `DebugLayers` draws one pair of radii per bird from.
func flock_offsets() -> Array[Vector2]:
	if flock == null:
		return [] as Array[Vector2]
	return flock.offsets()

## Each live bird's own `heading * speed`, parallel to `flock_offsets()`.
func flock_velocities() -> Array[Vector2]:
	if flock == null:
		return [] as Array[Vector2]
	return flock.velocities()

## Its birds (`EventFlock.birds`), or none for a row that is one body.
func birds() -> Array[EventFlock.Bird]:
	return flock.birds if flock else _NO_BIRDS

static var _NO_BIRDS: Array[EventFlock.Bird] = []

# --------------------------------------------------------------- going away ---
# **Nothing vanishes while you are looking at it.** An event that ends by `_finish()` wherever it
# happens to be standing ends, for the two shortest-lived rows in the game, directly in front of
# her: the cat's route is one street wide and ends in the open, and the pigeons hang in the air for
# a fifth of a second. The end of an event is a **departure**, not a deletion.
#
# What is deliberately *not* here: a fade. A thing that fades out is still a thing that disappears,
# and it disappears in a way nothing in the world could explain. The cat runs on, the flock climbs
# away, the dog that lost interest trots off — and each of them is gone because it left.

## True once it has stopped being an event and is only getting out of shot (`Phase.LEAVING`). It
## emits nothing, it cannot end the day, and it carries no cue: whatever it was, it is over. **The
## one exception is a guard walking away from his barrier** (`PursuitSpec.leaves_its_body`): the walk
## ends with the instance still there as the barrier (`EventBarrierPost.stand_as_the_barrier()`, `Phase.SPENT`). The
## barrier costs nothing while he goes, as a roadblock's band never costs anything
## (`EventCatalogue._roadblock()`'s `intensity` 0).
var is_leaving: bool:
	get:
		return phase == Phase.LEAVING

## True once a row that `EventDef.stops_where_it_arrives` has reached the end of its route and
## stopped there (`Phase.PARKED`). Unlike `is_leaving` this is not an ending: it is still the same
## event, standing still, for the rest of the day. See `_be_done()`.
var is_parked: bool:
	get:
		return phase == Phase.PARKED
## The end of an event: it leaves if it has anywhere to go, and stops existing if it has not.
##
## Three things never leave, and each would break something that reads the finishing position. An
## event with an `aftermath.on_finish` stops **where the thing it leaves belongs** — a convoy's
## barricade is across the street it shut, not two streets past it. Anything with no departure
## speed has no way to go anywhere; a café that closes has always simply been over. And a row with
## `EventDef.stops_where_it_arrives` **parks**: the fire engine is sent to the near kerb across from
## the building (`EventSpawner.where_the_summoned_row_stops()`) and stays there for the rest of the
## day, because a standing field beside a fire she was led to is the cost that makes the pair a
## street to turn round on rather than one to hurry past.
##
## **Parking is not being over.** It still emits, it still carries its cue, and it can still end a
## day that has a way to be ended by it — `is_leaving` would take all three away, which is why this
## is a third branch rather than a flag on the departure.
##
## Everything else that runs out of route drives on and is gone.
func _be_done(may_park := true) -> void:
	if phase == Phase.DONE or phase == Phase.LEAVING or phase == Phase.PARKED \
			or phase == Phase.SPENT:
		return
	if counts_a_charge():
		# `VisitCounter`'s own "-shaken"/"-outlasted" — a charge that had begun is over without
		# catching her, `gave_up` telling which of the two ways. A charge that caught or was cut
		# short already ended, so the record says nothing (`ChargeRecord`).
		_charge.end(gave_up)
	if def.stops_where_it_arrives and may_park:
		transition(Phase.PARKED)
		# The gait is driven by distance covered, so the distance has to stop here or a parked
		# engine bobs for ever at the kerb. Clamped to the route's own length rather than left
		# where the last step put it, so `path_travelled()` still answers "the whole route" for a
		# streaming resume.
		_path_travelled = route.length()
		queue_redraw()
		return
	if (departure.speed() <= 0.0 or def.aftermath.on_finish != ""):
		_finish()
		return
	transition(Phase.LEAVING)
	departure.begin()

## Ends this instance early because a resistance step's contact rode on it and she has just
## completed the step — called by `ResistanceDirector._on_contact_completed()` on the instance
## the step was actually reached through (`_rider` after retargeting), never on the seeded one if
## she reached a look-alike first. It is the same departure everything else in the game leaves
## by: no field while leaving, walking away, gone once out of sight — so a finished task reads as
## the world answering rather than as text on the HUD.
##
## **Unlike a departure `_be_done()` reaches on its own** — a route run out, a duration expired —
## this one has no route left to finish, so the heading is always turned away from her, overriding
## `_be_done()`'s "something on a route carries on the way it was going": a paced fixture stopped
## mid-beat is heading in whichever direction its beat happened to be walking, which is toward her
## exactly as often as away.
##
## **And she is standing right next to him when it starts**, unlike everything else that leaves —
## so the departure is held to her sight: its six-second backstop does not pop him out of
## existence mid-screen while she is still nearby (`EventDeparture`).
##
## **A row that parks where its route runs out leaves anyway when asked** — the warned neighbor,
## whose ordinary end is standing at the door (`EventDef.stops_where_it_arrives`) and who runs
## instead: this departure is the task's answer, not the route's.
func leave_for_a_completed_task() -> void:
	if is_finished or is_leaving or is_parked:
		return
	_be_done(false)
	if not is_leaving:
		return
	departure.for_a_completed_task()

## **Leaves down a way chosen for it** (`EventDeparture.along()`): day 12's park people, walked out
## through the cordon's last gap rather than through the tape. Answers whether it is now leaving
## along the way.
func leave_along(way: PackedVector2Array, speed := 0.0, avoid := Rect2i()) -> bool:
	return departure.along(way, speed, avoid)

## What is left of the way `leave_along()` set, in order (`EventDeparture.way_left()`).
func way_left() -> PackedVector2Array:
	return departure.way_left()

## True once the guard who set off from a barrier is gone for good, and this instance is only the
## barrier: solid and silent, for as long as the roadblock would have stood
## had he never set off. He does not come back for her, and **the guard who stayed at the other
## post walks off with him** (`RoadblockFarGuard`), so the band stands unmanned: nothing
## notices or chases from this instance again. (A choice open to overturn; the alternative is that
## the one who chased walks back to his post and the barrier is armed again.)
var _guard_spent: bool:
	get:
		return phase == Phase.SPENT

func _has_expired() -> bool:
	if is_waiting():
		# It has not happened yet, and it is not going to until she walks up to it.
		return false
	# **A vehicle waits for its men**: a hunting van's `duration` runs from its notice, and a van
	# gone from the kerb would leave a man walking back to nothing. It may leave only once every
	# man it let out is back in.
	if investigation and not investigation.all_back():
		return false
	return def.duration > 0.0 and chase_age() >= notice_time() + def.duration

func _finish() -> void:
	transition(Phase.DONE)

# ------------------------------------------------------------------ emission ---

## True while the event is visible but has not yet reached full strength: `Phase.WARNING`, ended
## when its clock has run (`_settle_the_notice()`) or, for a pursuer that comes for her through its
## telegraph (the day-3 dog), when she walks up to its stand-off first (`EventPursuit`). **A
## telegraph is a promise about the encounter's clock, not its phase**: a row that leaves,
## parks, stops or is done before that answers true until the clock runs out — the day-3 dog
## shaken off at 2s into its 4.5s telegraph is still telegraphing as it trots away, to the mark,
## the alert and its pictures.
func is_telegraphing() -> bool:
	if phase == Phase.WARNING:
		return true
	if phase == Phase.ACTIVE or phase == Phase.WAITING or _telegraph_ended or is_waiting():
		return false
	return chase_age() < notice_time()

## True while a pursuer that noticed her stands for its notice in its alert pose rather than closing
## on her (`PursuitSpec.stands`): the dog that waited, the hunting roadblock's guard, the
## man a vehicle lets out, and day 13's guard set on her in her view (`notice_her_at()`). **Asked of the def the instance was handed**, so the day-3 dog — the same row, sent
## down her heading with no trigger to have waited behind — is false here and spends its telegraph
## coming, which is the lesson; and false for anything that has not noticed her yet or has lunged.
func is_standing_for_its_notice() -> bool:
	var stands := def.pursuit != null and def.pursuit.stands
	return (stands or _stands_for_this_notice) and is_telegraphing() \
			and (def.notice != null or def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER))

## **Holds a row that crouches before its run `seconds` longer** — a crossing whose run a solid cut
## short (`EventDef.crouch_for_a_run()`), so it still reaches the middle when she does. Its telegraph
## only grows, so the fairness contract it was validated under still holds.
func hold_still_longer(seconds: float) -> void:
	if seconds > 0.0 and def.still_while_telegraphing:
		_notice_time = notice_time() + seconds

## How long this instance's notice runs once it has noticed her: a charger that warns by radius
## warns for its row's `PursuitSpec.warns_for` (`warns_by_radius()`); anything else for its row's
## `telegraph_time`, the notice a task gave it when it set it on her (`notice_her_at()`), or a
## crossing's crouch held longer (`hold_still_longer()`).
func notice_time() -> float:
	if _notice_time >= 0.0:
		return _notice_time
	if warns_by_radius() and def.pursuit and def.pursuit.warns_for > 0.0:
		return def.pursuit.warns_for
	return def.telegraph_time

## True for a row that waits (`EventDef.notice`) and has not noticed her: its notice's clock is not
## running. That is `Phase.WAITING`, and it stays true of such a row that leaves or is gone without
## ever having noticed her, and of a barrier whose guard has gone for good (`Phase.SPENT`), which
## waits for nothing. Waiting, it emits at full strength unless its notice is quiet, it is not
## lethal, and it does not move.
func is_waiting() -> bool:
	return def.notice != null and not _notice.is_running()

## How long this has been *happening*, which is not always how long it has existed.
##
## For everything in the catalogue but one it is the age. For a pursuer that waits, the clock starts
## when it notices her — a telegraph spent at dawn, four streets away, is not a notice, and
## `telegraph_time` and `duration` are both promises about the encounter rather than about the day.
##
## It is the notice's own clock (`_notice`, a `Warning` read against `age`), less whatever held it:
## a held lunge with her inside its stand-off, a waiting charger behind a wall at its warning's last
## moment, the masked man's wait. Zero for a row that waits and has not noticed her.
func chase_age() -> float:
	return _notice.elapsed(age)

## **Whether this pursuer warns by radius rather than by a clock**: one that waited for her and
## noticed her by sight (`EventDef.notice` on the def it was handed) — the dog that waited, the
## alley robber and every guard drawn from his row, the hunting roadblock's guard. *(Inbox #764
## in minty-lemur, the player: a warning happens when she comes close; she can turn around; if
## she keeps getting closer the charge starts; inbox #788 in minty-lemur: "We should do one
## radius and warn inside it for 2s. If the player leaves the radius nothing happens and the
## warning stops. If they stay within the charge starts.")* **One radius, and a warning on a
## clock inside it**: from the frame it notices her inside `EventDef.notice` it warns for its
## row's `PursuitSpec.warns_for` (`notice_time()`); back outside the radius before that, the
## warning stops and it waits again (`_stop_warning()`), its clock reset; still inside when it
## runs out, it charges.
##
## **Not one set on her by what she did** (`notice_her_at()`, day 13's task guard, `_paths_to_her`):
## he is sent after her from wherever he stands, often a city away, so a radius he has to be inside
## would leave him nothing to do; he keeps his timed notice. Nor one with no trigger — the day-3 dog
## and everything sent at her from off screen, whose approach or badge is the warning — nor one that
## sets off beside her, whose notice is a clock by construction.
func warns_by_radius() -> bool:
	return def.notice != null and (def.pursuit != null or def.notice.runs_within > 0.0) \
			and not def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) and not _paths_to_her

## **The stand-off a pursuer closes to and holds**, `Tuning.pursuit_standoff()` over
## `EventDef.standoff_reach()`: the distance a pursuer that comes for her through its telegraph
## lunges from (the day-3 dog's gold timing is spent at it), and where one that walks at her through
## its warning (the robber) stops. A charger that waits for her charges on its warning's clock, not
## on this distance (`warns_by_radius()`).
func charge_radius() -> float:
	return Tuning.pursuit_standoff(def.chase_speed(), def.standoff_reach())

## **It stops warning and waits again, where it stands**: she has gone back out of its warning
## radius. Its notice is forgotten, so the next time she comes inside the radius it notices her and
## warns again from the start. The robber stops where his warning walk had got him and waits there
## *(inbox #764 in minty-lemur, the player: the robber walking slowly stops if she gets out of the radius)*; the
## dog and the guards never moved. A roadblock's guard, who stepped out to his post on her side when
## he noticed her, is back at the band he was standing at, with the band's body under him again.
func _stop_warning() -> void:
	_notice.stop()
	transition(Phase.WAITING)
	if pursuit:
		pursuit.lunge_held = false
	if barrier_post:
		barrier_post.back_at_the_band()
	_invalidate_contribution_cache()

## **Holds the notice clock for this tick** (`_notice.hold()`), run straight after `age`
## advances and before the phase is settled, so a frame whose notice is held is never seen as
## the charge starting. Every notice runs, a waiting charger's warning included
## (`notice_time()`), held only: while a held lunge has her inside its stand-off
## (`_pause_a_held_notice()`); at a waiting charger's last moment while a wall stands between
## them, since **his charge needs a clear line** (mossy-beaver, inbox #650), so he goes on
## warning until the line clears or she leaves his radius; and for every tick of a row that runs
## its own line (`EventNoticeRun`, the masked man), whose run comes only from her coming
## within `NoticeSpec.runs_within`. A held clock is what a stream-out carries (`noticed_at()`),
## so it comes back exactly as far run.
func _hold_the_notice_clock(delta: float) -> void:
	if _telegraph_ended or is_waiting():
		return
	if def.notice and def.notice.runs_within > 0.0 and chase_age() - delta < def.telegraph_time:
		_notice.hold(delta)
		return
	if warns_by_radius() and def.pursuit and player_at != Vector2.INF \
			and chase_age() >= notice_time() and chase_age() - delta < notice_time() \
			and not clear_line_to(player_at):
		_notice.hold(delta)
		return
	_pause_a_held_notice(delta)

## Holds a held lunge's notice clock still for this tick while she is inside its stand-off — see
## `pursuit.lunge_held`. Run straight after `age` advances, before the phase is settled, so the frame
## the notice would have run out is never seen as the chase starting. Only while the notice was
## still running at the start of this tick: a chase already under way is never turned back into
## a notice.
func _pause_a_held_notice(delta: float) -> void:
	if pursuit == null or not pursuit.lunge_held or _telegraph_ended or is_waiting() \
			or player_at == Vector2.INF:
		return
	if chase_age() - delta >= notice_time():
		return
	if global_position.distance_to(player_at) < charge_radius():
		_notice.hold(delta)

## Current peak intensity at the centre, after the telegraph damping and the pulse envelope.
##
## `pulse_multiplier_override` (`< 0.0` means "not given") replaces the instant's own
## `0.25 + 0.75 × pulse(age)` reading — the only caller that ever passes one is
## `_caret_intensity_over_horizon()`, asking for the pulse's own mean over
## `Tuning.EXPECTED_IMPACT_HORIZON` instead of the beat this instant happens to be on.
func current_intensity(pulse_multiplier_override := -1.0) -> float:
	if is_finished or is_leaving:
		# On the way out it is scenery. Emitting while it goes would mean the excitement of an
		# event trailing after her for as long as it took the thing to get off screen.
		return 0.0
	if silenced:
		# A silenced mast still stands, but its field is gone — unlike `is_finished`, which means
		# the thing itself has left. See the field's own doc.
		return 0.0
	if is_quiet_for_its_man():
		return 0.0
	if has_stopped_her():
		# **The stop** (`PursuitSpec.stop_excitement`): from twice its mean rate to nothing over
		# `Tuning.OFFICER_STOP_SECONDS`, so its whole lands that many points on her standing
		# beside him — at the centre of his own field, which is where his catch puts her. A short sharp
		# spike rather than a field she strolls out of, and his field, so walking away takes some
		# of it off. Nothing after it: he is walking back by then (`_tick()`).
		var into := clampf(on_foot.stopped_for() / Tuning.OFFICER_STOP_SECONDS, 0.0, 1.0)
		return 2.0 * def.pursuit.stop_excitement / Tuning.OFFICER_STOP_SECONDS * (1.0 - into)
	if is_chatting():
		# A flat rate for the whole conversation rather than a falloff: she is inside `inner_radius`
		# by construction (`detain_distance() < inner_radius`), so there is no distance to shape.
		# Gated on `baby_awake`, read and never written — see the field's own comment — which is
		# what makes "asleep, it is a pure time loss" true of the meter and not only of the words:
		# nothing here scales through `Tuning.SLEEPING_SENSITIVITY`, it emits exactly zero.
		return (Tuning.CHAT_EXCITEMENT / def.detain_seconds) if baby_awake else 0.0
	var value := def.intensity
	if not is_equal_approx(def.intensity_ramp, 1.0) and def.duration > 0.0:
		# `chase_age()` rather than `age`, so a ramp measures the burst rather than the wait in
		# front of it: for everything without a trigger the two are the same number, and for a row
		# that stood on a pavement half the morning before she came near, `age` would hand the
		# first instant of the burst the multiplier the *end* of it is meant to have.
		var through := clampf((chase_age() - notice_time()) / def.duration, 0.0, 1.0)
		value *= lerpf(1.0, def.intensity_ramp, through)
	if def.pulse_period > 0.0:
		# 0.25..1.0, so a pulsing event is never entirely silent between beats. On `age` rather
		# than `chase_age()` on purpose: a pulse is the thing's own rhythm, which is running
		# whether or not anybody has walked up to it.
		if pulse_multiplier_override >= 0.0:
			value *= pulse_multiplier_override
		else:
			var phase := TAU * age / def.pulse_period
			value *= 0.25 + 0.75 * (0.5 - 0.5 * cos(phase))
	return value * _notice_damping()

## The pulse envelope's own mean over `[age, age + Tuning.EXPECTED_IMPACT_HORIZON]`, closed-form
## rather than stepped: the projection wants one scalar to hold across its whole sampling loop, not
## a second loop just to average a cosine.
##
## **Mean rather than instant, and from this instant's own phase.** `homeless_yeller`'s pulse (5s)
## and `busker`'s (7s) both turn over inside the horizon (5s), so freezing "as it stands now" could
## read anywhere from a quarter to the full peak depending on which beat the caret happens to be
## asked on, while the halo afterwards reads back whatever the walk actually crossed — a caret
## opened at a quiet trough undersold what was coming and one opened at a loud peak oversold it.
## The mean is the one number that answers "if this keeps pulsing the way it always does, what does
## the *whole* of the next five seconds average to" — which is what "if I keep doing what I'm doing"
## means for a source whose rate is not the thing standing still.
##
## **Exactly `0.625` (the envelope's own mean) whenever the horizon is an exact multiple of the
## period, whatever the phase** — `homeless_yeller`'s 5s pulse against the 5s horizon is exactly
## this case, since a cosine integrated over any whole number of its own periods is exactly zero
## however it is entered. `busker`'s 7s pulse against the same 5s horizon is the case that genuinely
## depends on phase, which is the one the closed form below has to get right rather than the one a
## quick sanity check would be tempted to hard-code.
static func _pulse_mean_multiplier(age: float, horizon: float, period: float) -> float:
	var w := TAU / period
	var mean_cos := (sin(w * (age + horizon)) - sin(w * age)) / (w * horizon)
	return 0.625 - 0.375 * mean_cos

## The multiplier the phase this instance is in puts on `def.intensity`, and the one place the
## three answers live — `_caret_intensity_over_horizon()` divides by exactly this rather than
## repeating the conditions, so the caret's projection and the meter can never disagree about which
## phase damps.
##
## **The damping says *this has not started yet*, and for a waiting row that is a claim about the
## thing rather than about its clock.** A pursuer that waits has been standing there since she came
## round the corner — what has not started is the lunge, not the man — so its notice is the one
## telegraph in the game that does not quieten what it is warning about. A quiet notice
## (`NoticeSpec.quiet`) is the opposite case and it is a real one: birds pecking on a pavement are
## nearly nothing until they go up, so both their wait and their notice damp like an ordinary
## telegraph.
func _notice_damping() -> float:
	if is_waiting():
		return Tuning.TELEGRAPH_INTENSITY_FRACTION if def.notice.quiet else 1.0
	if is_telegraphing() and (def.notice == null or def.notice.quiet):
		return Tuning.TELEGRAPH_INTENSITY_FRACTION
	return 1.0

## `current_intensity()` with the telegraph's own damping undone — the rate this row will
## actually carry once it is live, which is what the caret's own projection has to sum rather
## than the fraction a telegraph is reading right now. Everything else `current_intensity()`
## accounts for — the ramp, the pulse, chatting — still applies; only the final multiplier is
## skipped, by dividing it back out of the same call rather than a second copy of the ramp and
## pulse logic above it.
##
## Only `expected_gross_at()`'s own projection reads this. Every other caller of
## `contribution_at()` — the halo, the exclamation mark, the meter itself — wants what a source is
## actually doing right now, damped or not, because it is asking about the present rather than
## about the course this thing is on. Without this, a `cyclist` ridden straight at a standing
## player through its own 2s telegraph reads at `TELEGRAPH_INTENSITY_FRACTION` (15%) the whole
## time, and `expected_gross_at()` under-counts the approach by the same fraction.
##
## **And a pulse is projected at its own mean over the horizon, not at this instant's beat** — see
## `_pulse_mean_multiplier()`'s own doc for why a frozen instant could read anywhere from a quarter
## to the full peak of a row whose pulse turns over inside `Tuning.EXPECTED_IMPACT_HORIZON`.
func _caret_intensity_over_horizon() -> float:
	var pulse_override := -1.0
	if def.pulse_period > 0.0:
		pulse_override = _pulse_mean_multiplier(age, Tuning.EXPECTED_IMPACT_HORIZON,
				def.pulse_period)
	return current_intensity(pulse_override) / _notice_damping()

## Duck-typed with `CrowdAgent`'s own copy — see `ExcitementHalo`'s class doc. `points` is not
## recomputed here: `Baby._update_excitement()` traces it back from the meter's own sum as this
## event's exact share of what landed this frame — `contribution × sensitivity × delta` — so the
## halo can never disagree with what the bar actually did. *(2026-09-08, the player: "don't derive
## it from the source numbers but trace an increase in excitement back to its constituents".)*
## Stamped with `_clock`, this event's own simulation clock, rather than the wall clock, so a
## paused game does not empty the halo and a rig can measure the window on simulated time.
func accumulate_landed(points: float) -> void:
	_prune_landed_history()
	if points > 0.0:
		_landed_history.append([_clock, points])
		landed_ever += points
		# A pelican's first share of the meter, for `VisitCounter` and the run log — told once, and
		# never read back by anything here.
		if is_pelican and not _reported_excitement:
			_reported_excitement = true
			EventBus.pelican_excited_her.emit(self)

## The sum of every entry still inside `ExcitementHalo.WINDOW`. Pruned here too, not only on
## write, so a source nobody has visited in a while reports honestly the moment it is asked rather
## than waiting for its next landing.
func landed() -> float:
	_prune_landed_history()
	var total := 0.0
	for entry in _landed_history:
		total += entry[1]
	return total

func _prune_landed_history() -> void:
	var cutoff := _clock - ExcitementHalo.WINDOW
	while not _landed_history.is_empty() and _landed_history[0][0] < cutoff:
		_landed_history.pop_front()

## Excitement per second this event contributes at a point.
##
## `intensity_override` replaces `current_intensity()` for this one call when given (`< 0.0`
## means "not given" — every intensity this def can carry is positive). The only caller that ever
## passes one is `expected_gross_at()`'s own projection, asking for `_caret_intensity_over_horizon()`
## — the row's live rate, its pulse projected at the horizon's own mean rather than frozen at this
## instant's beat — in place of whatever a telegraph has this one currently damped to; every other
## caller gets the answer it always got.
##
## `velocity_override` replaces `travel_velocity()` for the field's own kernel, the same way, when
## given (`Vector2.INF` means "not given"). The only caller is `expected_gross_at()` too, and for
## the same reason: its projection translates the *sample point* by `_caret_velocity()` rather than
## moving the source, and the ellipse the translated point is measured against has to be oriented by
## that same velocity or the two disagree about which way this thing is going. A pursuer holding its
## telegraph stand-off is the case that matters — `travel_velocity()` is zero there (it is holding
## still) while `_caret_velocity()` is the lunge it is about to make.
## The cache `contribution_at()` below keeps for its plain query (no override given) — see that
## function's own doc.
var _contribution_age := -1.0
var _contribution_at := Vector2.INF
var _contribution_cache := 0.0

## Forces the next `contribution_at()` call to recompute rather than trust the cache, which is keyed
## on `(age, world_position)`. The field also changes with things that move without the age moving —
## a phase change made from outside its own tick (`EventManager.retire()` finishing it) or a mast
## silenced — so `transition()` and the silencing call this, and the very next call recomputes.
func _invalidate_contribution_cache() -> void:
	_contribution_age = -1.0

## **The plain query — no override given — is cached once per frame per position**, the same
## `age`-keyed shape `EventLook._caret_strength()` documents below: `Baby._update_excitement()`
## (physics rate) and `ExcitementHalo.select_sources()` (frame rate) both ask every live instance
## for its contribution at the same point most frames, so a repeat this tick answers from the cache
## instead of re-running the field. `expected_impact_at()`'s own projection passes an override or a
## translated `world_position` for every sample but its first, so those calls never match the cache
## key and always recompute, which is correct — the cache is only ever for the single point every
## ordinary caller actually asks about.
func contribution_at(world_position: Vector2, intensity_override := -1.0,
		velocity_override := Vector2.INF) -> float:
	var cacheable := intensity_override < 0.0 and velocity_override == Vector2.INF
	if cacheable and _contribution_age == age and _contribution_at == world_position:
		return _contribution_cache
	var result := _contribution_at_uncached(world_position, intensity_override, velocity_override)
	if cacheable:
		_contribution_age = age
		_contribution_at = world_position
		_contribution_cache = result
	return result

## **Nothing reaches her through a building**: a field is zero wherever `_walled_off()` says a
## building stands between this node and the point. Asked only once the field is positive, so a
## source out of reach costs no line at all.
##
## **A source beyond `EventDef.silent_beyond()` of the point answers zero before anything else is
## asked** — its intensity, its velocity, its shape — since that field is zero there by
## construction and the wall is only asked of a positive one. Not for a flock or anything leaving:
## a flock's birds and a guard's band stand away from this node.
func _contribution_at_uncached(world_position: Vector2, intensity_override: float,
		velocity_override: Vector2) -> float:
	if not is_leaving and birds().is_empty():
		var reach := def.silent_beyond()
		if global_position.distance_squared_to(world_position) > reach * reach:
			return 0.0
	var field := _field_at(world_position, intensity_override, velocity_override)
	if field > 0.0 and _walled_off_now(global_position, world_position):
		return 0.0
	return field

## Whether a wall stands between a source standing at `source_at` and her at `her_at`, deep enough
## to keep its excitement from her — `WorldMap.wall_between()`, measured from this node (a flock's
## centre, a shaped row's middle) to her centre. *(plaid-wombat, inbox #554: "Excitement should not
## go through any wall".)* The map's own walls answer it, the city's buildings outdoors and the
## building's walls indoors; nothing is walled on open ground, and nothing for a row whose field no
## wall stops (`EventDef.from_outside`).
func _walled_off(source_at: Vector2, her_at: Vector2) -> bool:
	return not def.from_outside and _map.wall_between(source_at, her_at)

## The map `_walled_off()` asks — open ground for a row no wall stops (`EventDef.from_outside`), so
## the debug view's fields layer, which cuts this source's outline from its own node along the same
## lines (`DebugLayers.open_runs()`), cuts it exactly where the meter does.
func wall_grid() -> WorldMap:
	return _NO_WALLS if def.from_outside else _map

## Open ground, the walls a field from outside meets.
static var _NO_WALLS := WorldMap.open_ground()

## The last line `contribution_at()` asked about and its answer, kept by value. The meter's sum,
## the halo's pick and the caret's present rate ask the same pair in a frame, and the answer
## depends on nothing but the two points and the map — a body moved from outside is a new key, so
## nothing here can answer stale the way a clock-keyed cache of the field would.
var _wall_from := Vector2.INF
var _wall_to := Vector2.INF
var _wall_answer := false

## `_walled_off()` through that one-line cache, for `contribution_at()` alone: the caret's
## projection asks a different pair at every step and would only push the frame's own pair out.
func _walled_off_now(source_at: Vector2, her_at: Vector2) -> bool:
	if source_at != _wall_from or her_at != _wall_to:
		_wall_from = source_at
		_wall_to = her_at
		_wall_answer = _walled_off(source_at, her_at)
	return _wall_answer

## The field alone, with no question about what stands between — what `contribution_at()` charges
## on open ground, and what the caret's projection asks before it asks about walls at the two
## bodies' own projected places.
func _field_at(world_position: Vector2, intensity_override: float,
		velocity_override: Vector2) -> float:
	if is_finished:
		return 0.0
	if is_leaving:
		# A leaving event emits nothing, a guard walking away from his barrier included: a
		# roadblock's band has no field strength of its own (`EventCatalogue._roadblock()`).
		return 0.0
	var intensity := intensity_override if intensity_override >= 0.0 else current_intensity()
	if not birds().is_empty():
		return _flock_contribution_at(world_position, intensity)
	var velocity := velocity_override if velocity_override != Vector2.INF else travel_velocity()
	# `EventDef.emission_at_distance()` rather than `Tuning.falloff` direct, so the one row with a
	# two-part field is charged for both parts here and not only in the cost table — and so that a
	# row shaping its own drop-off (`EventDef.falloff_power`) is felt as the shape it is priced at.
	# The peak handed over is this phase's, so the telegraph and the pulse damp the core and the
	# field together; an uncored row comes back bit for bit what it always did.
	return def.emission_at_distance(_field_distance(world_position, velocity), intensity)

## The distance `contribution_at()` prices this row's field at — `GroundShape.field_distance()`
## over this row's own shape (D1's `body ⊕ disc` stationary, D2's `point ⊕ ellipse` moving), or the
## same kernel with no body at all for the handful of emitting rows with no shape (`playground`,
## whose look is drawn by the park itself rather than by `EventInstance`).
func _field_distance(world_position: Vector2, velocity: Vector2) -> float:
	return _field_distance_at(global_position, world_position, velocity)

## `_field_distance()` for a field centred somewhere other than this node: the band a guard has
## walked away from.
func _field_distance_at(centre: Vector2, world_position: Vector2, velocity: Vector2) -> float:
	var shape := field_shape()
	if shape != null:
		return shape.field_distance(centre, _solid_axis(), velocity, world_position)
	return GroundShape.eccentric_distance(centre, velocity, world_position)

## The datum this row's field is priced from (`_field_distance_at()`) and drawn from (`DebugLayers`):
## its `shape`, or none — a point at its centre — for a row whose field is priced from its centre
## (`VehicleSpec.field_from_its_centre`, the fire engine) or that has no shape.
func field_shape() -> GroundShape:
	return null if def.vehicle and def.vehicle.field_from_its_centre else def.shape

## A flock is its birds, summed.
##
## The same shape as `City.total_excitement_at` one level down: nothing is pushed anywhere, the
## sources compose by plain addition, and there is no ordering to get wrong. Each bird carries an
## equal share of the event's intensity over a radius that leaves room for the wheel, so the middle
## of the flock — where four or five fields overlap — comes out at about what the event says it is
## and the edge of it at a fraction. That gradient is the whole reason to do it this way: the price
## of a flock should depend on whether you walked through it or round it, and one disc centred on
## nothing in particular cannot say that.
##
## **Each bird is its own point kernel**, eccentric by its own `heading * speed` rather than the
## instance's own `travel_velocity()` (always zero for a flock — it is not itself `mobile` or
## `EventDef.pursuit`) — a cheap read off `Bird`, already carried for the wheel, so a bird
## diving toward her costs more than one peeling away exactly as any other moving point in the
## game does. The bodies stay points either way: a flock's own field was never a capsule, and
## eleven of them is not where the general capsule-and-ellipse sum earns its cost.
func _flock_contribution_at(world_position: Vector2, intensity := -1.0) -> float:
	var total_intensity := intensity if intensity >= 0.0 else current_intensity()
	var share := total_intensity / float(birds().size())
	var outer := flock.bird_outer()
	var total := 0.0
	for bird in birds():
		var d := GroundShape.eccentric_distance(global_position + bird.at,
				bird.heading * bird.speed,
				world_position)
		total += Tuning.falloff(d, share, def.inner_radius, outer, def.falloff_power)
	return total

## True when a point is inside the radius that ends the day, for a hard-fail event that is
## no longer merely telegraphing.
##
## **Measured from this node, at `def.lethal_reach()`** — which is the field's own core for almost
## every row and a separate, smaller number for one whose killer is not what the field is drawn
## around. A roadblock is that row: the node is the man once he leaves the post, and what he
## reaches with is a pair of arms rather than the width of the barrier he left standing.
##
## **A pursuer catches her only by touching her**, so its catch also needs `clear_line_to()` her:
## within reach across a building's corner is not a catch. *(freckled-goose, #544: "Even then the
## distance would not physically connect so counting it as caught would be unfair. Only if the
## Robert touches the player should it end instantly".)* The reach is unchanged; what is added is
## that nothing stands between them. Every other `hard_fail` row keeps the straight-line distance.
##
## **Cars that drive are the only rows lethal without `hard_fail`** (`EventDef.vehicle`): one strikes
## her in front of its nose while it drives its route and she is on the carriageway, and nowhere
## else — not behind it, not beside it, not while it stands (`EventCarDriving.is_driving()`). A body touching her is
## not enough, and not needed: the strike reaches `Tuning.PATROL_STRIKE_LEAD` of its travel past the
## touch, so a car driving its nose into her strikes her rather than standing for her (`EventCarDriving`).
## Its telegraph is not asked: its warning is a car's, `EventCarDriving.closes_on()`, not a field coming up to
## strength.
func is_lethal_at(world_position: Vector2) -> bool:
	if car:
		return car.strikes(world_position)
	# The row's own flag first: it is the one most rows fail, and the two calls after it are pure.
	if not def.hard_fail or is_finished or is_leaving or is_waiting() or is_telegraphing():
		return false
	if global_position.distance_to(world_position) > def.lethal_reach():
		return false
	return def.pursuit == null or clear_line_to(world_position)

## Whether the straight line from this node to `world_position` crosses only ground this figure
## may enter, street ground or not (`Navigator.clear_line()`, as `_sight`) — the question a pursuer's catch asks, since a
## catch across a wall, a barrier or a café is a man reaching through it, and the one its notice
## and its lunge ask in `EventPursuit`, since he can neither see nor go for her through one.
## `WorldMap.clear_line()` walks it, the one walk every caller asks, so a line that clips a
## building's corner by a pixel is blocked however short it is; a guard sees out of the band he
## stands in, and her own tile never hides her. True on open ground, which is every data-level rig
## built without a map, exactly as `_step()` is.
func clear_line_to(world_position: Vector2) -> bool:
	return _navigator.clear_line(global_position, world_position, _sight)

## One bounded integral cache per source, with a by-value key rather than a clock or identity.
var _expected_landed_key: Array = []
var _expected_landed_cache := 0.0

## The gross points this event is anticipated to land over `Tuning.EXPECTED_IMPACT_HORIZON` **if
## she and it both carry on exactly as they are**, before her own decay is netted against it —
## `expected_impact_at()` is the net; this is the half of it every source projects for itself, and
## `ExcitementHalo` reads it too, once a frame, to learn what the horizon's decay has to be shared
## between. Duck-typed with `CrowdAgent`'s own copy.
##
## *(2026-09-20, overturning 2026-09-08's "I don't want a caret when walking into a car from the
## side": "caret communicates anticipated net gain. basically if I keep doing what I'm doing I
## very likely get that amount in net gain".)* Her own current `player_velocity` now moves her
## through the projection exactly as `velocity` moves the source — a café she is walking toward
## now does expect something, because she is not going to stay held still against it. What she
## already answered stays true of the *source's* own half: a car passing wide of a **stationary**
## her still expects nothing from that car, because nothing about the car's course crosses her
## line — the overturn is that her line is no longer flattened to a point.
##
## **Projected at `_caret_velocity()` and `_caret_intensity_over_horizon()`, not
## `travel_velocity()` and `current_intensity()`.** The row's *live* course and rate, because the
## caret is asking what this thing is on its way to doing rather than what a telegraph currently
## has it doing: a telegraphing `cyclist` is already moving at its route speed (`travel_velocity()`
## already answers that), but reads at 15% of its own field the whole time it telegraphs —
## projecting the damped rate would keep the sum under the line until the telegraph is nearly over,
## the same gap a pursuer holding its stand-off would have if the caret read its own zeroed
## `travel_velocity()`. `current_rate` below is deliberately still the real, possibly-damped
## `contribution_at()` — what she is actually being charged right now — so the subtraction is the
## live approach minus the honest present, not the live approach minus itself. A pulsing row's own
## rate is the horizon's own **mean** of the pulse rather than this instant's beat — see
## `_caret_intensity_over_horizon()`'s own doc.
##
## **Skipped without sampling once neither body is moving, or the reach cannot close inside the
## horizon.** Two bodies both held still is the one case where nothing about the answer can
## change, and the reach the early-out compares against is now the pair's own closing speed
## (`player_velocity - velocity`), not the source's alone — a fast source she is outrunning no
## longer over-reaches its true closing distance the way comparing only its own speed would.
##
## **Floored at zero, and scaled by `player_sensitivity` here rather than left to the caller** —
## `Baby.current_sensitivity()`, read the same way the backward-looking halo bakes it into
## `landed()` — so the total `ExcitementHalo` sums across every live source is already in the units
## the shared decay is taken out of.
func expected_gross_at(player_position: Vector2) -> float:
	if is_finished or is_leaving:
		return 0.0
	# A barrier the meter is not charging her for has no impact to project: the strongest structure
	# of a boundary is the whole of what lands, and the others would each promise the same cost
	# over again. See `outranked_by_a_stronger_barrier`.
	if outranked_by_a_stronger_barrier:
		return 0.0
	var velocity := _caret_velocity()
	var closing := player_velocity - velocity
	var reach := closing.length() * Tuning.EXPECTED_IMPACT_HORIZON + def.field_reach()
	if global_position.distance_to(player_position) > reach:
		return 0.0
	if velocity.is_zero_approx() and player_velocity.is_zero_approx():
		return 0.0
	var current_rate := contribution_at(player_position)
	var live_intensity := _caret_intensity_over_horizon()
	var future_integral: float
	# Compare the effective sample inputs by value, including mutable definition/shape fields.
	# Age alone cannot cover a retirement, silence, external movement or changed player state.
	# Flocks retain their ordinary path: every bird has independently mutable geometry.
	if birds().is_empty():
		var key := [global_position, player_position, player_velocity, velocity,
			live_intensity, def.intensity, def.inner_radius, def.outer_radius,
			def.falloff_power, def.core_intensity, def.core_radius, _solid_axis(),
			def.shape.kind if def.shape else -1,
			def.shape.half_length if def.shape else 0.0,
			def.shape.half_extents if def.shape else Vector2.ZERO]
		if key != _expected_landed_key:
			_expected_landed_cache = _sample_expected_landed(player_position, velocity,
					live_intensity)
			_expected_landed_key = key
		future_integral = _expected_landed_cache
	else:
		future_integral = _sample_expected_landed(player_position, velocity, live_intensity)
	# Present contribution, sensitivity and shared netting remain live on every request.
	var gross := future_integral - current_rate * Tuning.EXPECTED_IMPACT_HORIZON
	return maxf(gross * player_sensitivity, 0.0)

## Only the future integral is reusable. The key above covers every input these samples read;
## shape radius is read by neither the reach guard (`EventDef.field_reach()`) nor field distance,
## which measures from the spine.
func _sample_expected_landed(player_position: Vector2, velocity: Vector2,
		live_intensity: float) -> float:
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var integral := 0.0
	for i in steps:
		# Projecting the *source* forward by `velocity * t` and querying its field at her own
		# projected position, `player_position + player_velocity * t`, is the same number as
		# holding the source still and asking for its field at the pair's relative offset instead
		# — `_field_at` is the field every caller of `contribution_at` is charged, translated, so
		# nothing here recomputes a falloff or a flock sum of its own. `velocity` (the source's
		# own) is passed a second time, as the override, so the ellipse the translated point is
		# measured against is oriented the way the source is actually travelling, not the pair's
		# relative heading — see `contribution_at()`'s own doc for why the two must agree.
		# The field translates; a wall does not. So the wall is asked between the two bodies'
		# own projected places, where a building actually stands, never at the translated point.
		var t := float(i + 1) * dt
		var sample := player_position + player_velocity * t - velocity * t
		var rate := _field_at(sample, live_intensity, velocity)
		if rate > 0.0 and _walled_off(global_position + velocity * t,
				player_position + player_velocity * t):
			rate = 0.0
		integral += rate * dt
	return integral

## The net points this event is anticipated to add to the bar over `Tuning.EXPECTED_IMPACT_HORIZON`
## **if she and it both carry on exactly as they are** — the caret's own answer to *"if I keep doing
## what I'm doing, how much will I get"*, which is `ExcitementHalo.net_landed()`'s question asked
## forward instead of back: `expected_gross_at()` less her own decay over the same horizon. See
## `EventLook.wants_a_mark()` for what a result at or above `Tuning.EXPECTED_IMPACT_POINTS` does
## with the answer.
##
## **`player_decay_rate` (`Baby.decay_rate()`) defaults to `0.0`, which answers exactly as this
## function always did — held still, nothing given back — for any caller that has not told this
## instance her actual state, a data-level test among them.**
##
## **Shared between every source worth a mark when `ExcitementHalo` is driving the frame, charged
## against this source alone otherwise.** *(2026-09-20, on the un-shared version this replaces:
## "with two sources near her every caret reads low".)* `player_expected_total_gross` is `-1.0` —
## "not given" — for any caller that has not told this instance the frame's total, which keeps the
## old, pessimistic-but-independent answer for a data-level test or a single source read alone.
## `ExcitementHalo` sums `expected_gross_at()` over every live event and crowd body once a frame,
## the same once-a-frame pass it already runs for the halo's own `total_landed`, and hands the sum
## back through `set_expected_total_gross()` before anything asks for a net — the *sources that
## earn a caret* are exactly the ones whose own `expected_gross_at()` is positive, since a source
## contributing nothing to the total also draws nothing from it, so summing over every live
## candidate rather than only the ones already worth a mark changes nothing about the answer and
## needs no second, smaller pass to find them.
##
## **`ExcitementHalo.net_landed()`'s own arithmetic, forward instead of back.** Every source's
## share of the horizon's decay scales by the identical factor
## `player_decay_rate * Tuning.EXPECTED_IMPACT_HORIZON / player_expected_total_gross`, so summing
## every source's own `expected_impact_at()` back up reproduces `player_expected_total_gross` less
## the whole decay exactly — the bar's own projected rise — rather than approximately, the same
## exactness `net_landed()`'s own doc proves for the backward-looking halo.
func expected_impact_at(player_position: Vector2) -> float:
	var gross := expected_gross_at(player_position)
	if gross <= 0.0:
		return 0.0
	var decay := player_decay_rate * Tuning.EXPECTED_IMPACT_HORIZON
	if player_expected_total_gross >= 0.0:
		return ExcitementHalo.net_landed(gross, player_expected_total_gross, decay)
	return maxf(gross - decay, 0.0)

## Whether this event's own current course puts her inside the radius that ends the day at some
## point before `Tuning.EXPECTED_IMPACT_HORIZON`, her position held fixed — `is_lethal_at()`'s
## straight-line reach, `def.lethal_reach()`, asked at every step of the same projection
## `expected_impact_at()` takes, rather than only at the position she is standing at now. The
## doubled caret's own question.
##
## **The straight-line reach without the clear-line test.** A pursuer's real catch also needs
## `clear_line_to()` her, and the caret does not ask it: it projects the pursuer straight at her,
## so it can read red while a building still stands between them, before he has come round the
## corner. Whether it should ask is open to overturn (the polite-rabbit record says why it does
## not).
##
## **`is_lethal_at()`'s guards, minus its own telegraph gate.** A telegraphing `hard_fail` row
## cannot fire *yet* — that gate is exactly right for `is_lethal_at()`'s own callers, which ask
## whether it is lethal **right now** — but the caret is asking whether its course, once the
## telegraph clears, puts her inside the radius that ends the day, which a telegraphing row can
## answer just as truly as a live one: a `cyclist` ridden straight at her through its whole
## telegraph has to read red, or the doubled caret only ever appears in the last fraction of a
## second. `is_waiting()`, `is_finished` and `is_leaving` still refuse it — a waiting pursuer has
## not decided anything about her yet, so there is no course to be lethal on.
##
## **A car that drives asks its own strike along its own course** (`EventDef.vehicle`): driving now,
## and her in front of its nose on the carriageway from some point of its next
## `EXPECTED_IMPACT_HORIZON` straight ahead — so the doubled caret is over a patrol car exactly when
## staying where she is in its lane would end the day.
func will_be_lethal(player_position: Vector2) -> bool:
	if car:
		return car.will_strike(player_position)
	if is_finished or is_leaving or is_waiting() or not def.hard_fail:
		return false
	var velocity := _caret_velocity()
	var reach := def.lethal_reach()
	if velocity.is_zero_approx():
		return global_position.distance_to(player_position) <= reach
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	for i in steps + 1:
		var future_at := global_position + velocity * (float(i) * dt)
		if future_at.distance_to(player_position) <= reach:
			return true
	return false

## Whether it is holding still through its telegraph — a crouching cat is not walking.
func is_telegraphing_still() -> bool:
	return def.still_while_telegraphing and is_telegraphing()

# ------------------------------------------------------------------- the gait ---
# The event half of "every living thing that moves has a stride" — the walker's own two-frame
# alternation (`WalkerLook.advance()`/`gait_frame()`): the stride is kept here, by the ground the
# event covers, and read by whichever look draws a second frame (`EventLook._gait_stepping()`).

## The mother's and the walker's own rate, in radians of gait phase per pixel walked. Pinned again
## here rather than shared: neither `Stroller` nor `CrowdAgent` exposes it as a constant reachable
## from this file, and a cross-file literal agreement is worth restating rather than importing.
const GAIT_RATE := 0.09

## Advances `_gait_phase` by `moved` (px covered this tick, positive or exactly zero — `_tick()`
## passes `_path_travelled`'s own delta, which is never negative) and records whether anything moved
## at all, which is the "stopped" gate `EventLook._gait_stepping()` reads. Called once per tick, at
## every exit from `_tick()`, the same "add the distance once, however the caller reached this
## point" shape `WalkerLook.advance()` has — asking `EventLook.draw_body()` to do it would double
## the addition once per halo ring, exactly the trap that function's own doc names.
func _advance_gait(moved: float) -> void:
	_gait_moving = moved > 0.0
	_gait_phase = wrapf(_gait_phase + moved * GAIT_RATE, 0.0, TAU)

## A deterministic 0..1 from this instance's own siting position, an index and a salt — the same
## hash `EventFlock._roll()` already uses for a flock's own scatter, generalised to one index (0) since
## nothing outside a flock needs more than one draw. No global RNG is reachable from here, and
## streaming an instance out and back in must not draw from one twice; a hash of where the day
## placed it answers the same way every time the same plan places the same instance.
func _position_roll(salt: int) -> float:
	var mixed := int(position.x) * 73856093 + int(position.y) * 19349663 + salt * 2971215073
	return float(absi(mixed) % 4096) / 4096.0

# ------------------------------------------------------------------ the halo ---
# The ring itself is `EntityHalo`'s job now, shared with `CrowdAgent` — see that class for the
# offsets, the shared material, and why a `canvas_item` shader on this entity's own sprite could
# not have bloomed outward on its own.

## The ground-plane direction a spread-shaped shadow sweeps along — local Y when the street this
## instance stands on is east-west (`_spread_vertical`), local X otherwise. The same axis
## `spread_at()` already lays the drawn body along.
func spread_axis() -> Vector2:
	return Vector2.DOWN if _spread_vertical else Vector2.RIGHT

## The ground-plane direction this instance's own solid body's spine lies along, for whichever of
## the three families ever has a segment shape: a car that drives (`EventDef.vehicle`), along its
## own heading; a spread-drawn row (`spread_axis()`, above); or the one stationary-vehicle row wide
## enough to be a segment (`moving_van` — see `GroundShape.band()` on that row), which lies along
## whichever of the street's axes `_stationary_vehicle_side` already draws it on. Never asked of a
## point shape, where an axis means nothing.
func _solid_axis() -> Vector2:
	# A car's body lies along the way it is driving, and turns with it (`EventCarDriving.turn_the_body()`).
	if def.vehicle != null:
		return _heading.normalized() if not _heading.is_zero_approx() else Vector2.RIGHT
	if def.has_a_spread or def.look == EventDef.Look.PROTEST or def.look == EventDef.Look.FIREFIGHT:
		return spread_axis()
	return Vector2.RIGHT if _stationary_vehicle_side else Vector2.DOWN

## `_solid_axis()`, read by `DebugLayers` so its shadow and bounding-box layers rotate a segment the
## same way `EventLook._draw_shape_shadow()` and `_build_obstruction()` already do, rather than
## guessing an axis of their own.
func solid_axis() -> Vector2:
	return _solid_axis()

## Forwards to `_halo`'s own `set_glow()` — see `EntityHalo`'s class doc for the duck-typed shape
## `CrowdAgent` shares. Called by `ExcitementHalo` once a frame for every live instance — above
## zero for the handful `select_sources()` picked, zero for everything else. Refuses a nonzero
## glow once the event is finished, because a finished event still sits in
## `EventManager.instances()` for one more frame than its `contribution_at()` (already zero) would
## otherwise buy it.
##
## **The rim is built on the first nonzero glow and given back once it has faded all the way out**
## — not the frame the target first reaches zero, or a source that just left `MAX_SOURCES` would be
## cut off mid-fade instead of draining over `EntityHalo.FADE_OUT_SECONDS`. The same lifetime
## `CrowdAgent.set_halo_strength()` gives its own rim; `release_halo()` is how it is given back.
func set_halo_strength(strength: float, colour: Color) -> void:
	# **While a guard walks away from his barrier any rim is the barrier's**, on the band
	# (`RoadblockLook.RoadblockBand`'s own) and not on the man, who is costing her nothing. **An
	# instance never holds two rims at once** (`ExcitementHalo` counts one block per instance
	# against `EntityHalo.RIM_BUDGET`): the man's is given back on the spot as the band's is built,
	# and the band's on the spot as the instance's own is wanted again once the barrier stands
	# alone.
	if is_leaving and barrier_post and barrier_post.has_left_its_body() \
			and look.band_node() != null \
			and not is_finished:
		if _halo:
			EntityHalo.release(_halo)
			_halo = null
		_glow_the_band(strength, colour)
		return
	if _band_halo and strength > 0.0 and not is_finished:
		_release_the_band_halo()
	else:
		_glow_the_band(0.0, colour)
	if strength <= 0.0 or is_finished:
		if _halo:
			_halo.set_glow(0.0, colour)
			if _halo.is_faded_out():
				EntityHalo.release(_halo)
				_halo = null
		return
	if not _halo:
		_build_halo()
	_halo.set_glow(strength, colour)

## The band's own rim, built when a departing guard's barrier becomes the thing costing her and
## given back once it has faded.
func _glow_the_band(strength: float, colour: Color) -> void:
	if strength <= 0.0:
		if _band_halo:
			_band_halo.set_glow(0.0, colour)
			if _band_halo.is_faded_out():
				_release_the_band_halo()
		return
	if _band_halo == null:
		_band_halo = EntityHalo.new(_draw_the_band_for_the_halo, func() -> float: return 0.0)
		# Behind the band's first slice, drawn before every other part of the band, as a rim is
		# behind the picture it outlines (`_rim_holder()`).
		var holder := (look as RoadblockLook).band_rim_holder()
		holder.add_child(_band_halo)
		_band_halo.position = look.band_node().global_position - holder.global_position
	_band_halo.set_glow(strength, colour)

var _band_halo: EntityHalo

func _draw_the_band_for_the_halo(canvas: CanvasItem) -> void:
	look.draw_the_band(canvas, Vector2.ZERO)

func _release_the_band_halo() -> void:
	if _band_halo:
		EntityHalo.release(_band_halo)
		_band_halo = null

## Gives back the rims that stand behind a slice of the look (`SpreadLook.Slice`), on the spot,
## when the look is about to let go of its slices (`SpreadLook.letting_go_of_the_slices`).
func _release_rims_on_slices() -> void:
	if _halo != null and _halo.get_parent() is SpreadLook.Slice:
		EntityHalo.release(_halo)
		_halo = null
	if _band_halo != null and _band_halo.get_parent() is SpreadLook.Slice:
		EntityHalo.release(_band_halo)
		_band_halo = null

## The rim lit around this instance's own picture, or null: the canvas a look draws no shadow on.
func rim() -> EntityHalo:
	return _halo

## Whether this instance holds a rim right now, lit or still fading — what `ExcitementHalo` counts
## against `EntityHalo.RIM_BUDGET`.
func holds_a_halo() -> bool:
	return _halo != null or _band_halo != null

## Frees the rim on the spot, never through `queue_free()`: a rim keeps its block in the web
## renderer's instance buffer until the engine frees it, and a queued free lands at the end of the
## frame, after any rim built in the meantime has already been handed a block — see
## `EntityHalo.release()`. Called by `set_halo_strength()` once a fade is over, and by
## `ExcitementHalo` for an instance queued for deletion, whose body goes before the next frame is
## drawn anyway.
func release_halo() -> void:
	if _halo:
		EntityHalo.release(_halo)
		_halo = null
	_release_the_band_halo()

# ------------------------------------------------------------------ the look ---

## How this instance looks (`EventLooks.for_row()`): it draws the instance from its public state,
## decides when it is drawn again, and holds the drawing nodes a long picture is drawn in.
var look: EventLook

## What a protest points its placards at, handed in by whoever knows (`EventManager.points_at`,
## from the resistance's `pointable_objective()`); unset, it points at nothing.
var points_at := Callable()

func _draw() -> void:
	if FrameRecord.on:
		FrameRecord.drew(FrameLedger.DRAWS_EVENTS)
	look.draw()

## Builds the drawing nodes again when the instance comes back into the tree after leaving it,
## which took them with it.
func _enter_tree() -> void:
	if look:
		look.enter_tree()

func _exit_tree() -> void:
	_band_halo = null
	if look:
		look.release_nodes()

## Adds `node` to the world this instance stands in, on the entity layer (`WorldMap.add_entity()`),
## or beside it in its own parent on a map no world draws — a rig that stands it under a bare node.
func add_beside_it(node: Node2D) -> void:
	if _map.has_world():
		_map.add_entity(node)
	else:
		get_parent().add_child(node)

## A point `offset` along whichever axis `_spread_vertical` says this instance spreads on — local X
## by default, local Y on an east-west street. See `_spread_is_vertical`.
func spread_at(offset: float) -> Vector2:
	return Vector2(0.0, offset) if _spread_vertical else Vector2(offset, 0.0)

## The furthest below its own node a row's picture is ever drawn: a car's body reach, pointed
## straight down the screen, and its look's largest canvas margin (`EventLook._body_anchor()`); zero
## for every other row, whose pictures stand on the node. `footprint_of()` and `drawn_box()` add it.
static func _picture_drop_of(row: EventDef) -> float:
	if not EventPictures.is_anchored_over_its_body(row.look) or row.shape == null:
		return 0.0
	var margins := EventPictures.canvas_margins(row.look)
	var margin := 0.0
	for view: String in margins:
		margin = maxf(margin, float(margins[view]))
	return row.shape.reach() + margin

## `box` and the same box lowered by `_picture_drop_of(row)`, together: every place between the
## two a picture can stand as its heading turns.
static func _with_the_drop(row: EventDef, box: Rect2) -> Rect2:
	var drop := _picture_drop_of(row)
	if drop <= 0.0:
		return box
	return box.merge(Rect2(box.position + Vector2(0.0, drop), box.size))

## Whether its spread runs down the screen rather than across it (`_spread_is_vertical()`).
func runs_vertically() -> bool:
	return _spread_vertical

## Whether a stationary vehicle shows its side rather than its end (`_stationary_vehicle_uses_side()`).
func stands_side_on() -> bool:
	return _stationary_vehicle_side

## The stride's phase, in radians of `GAIT_RATE` per pixel walked (`_advance_gait()`).
func gait_phase() -> float:
	return _gait_phase

## Whether the last tick covered any ground.
func gait_is_moving() -> bool:
	return _gait_moving

## Seconds this instance has been stepped, the idle animations' clock.
func clock() -> float:
	return _clock

## This instance's own offset into an idle animation's period, 0..1, so two of a kind do not swap
## in lockstep.
func idle_offset() -> float:
	return _idle_phase_offset

## The map it stands on.
func world_map() -> WorldMap:
	return _map
