class_name WarningBoard
extends RefCounted
## **The warnings a day's events put up**: a screen-edge badge up alone for something not in the
## world yet (`warn_first()`, `PendingWarning`), which `DangerEdge`'s badge handler reads
## (`pending_warnings()`), and the exclamation mark over her head when the ground she stands on is
## the danger (`warn_about_the_ground_she_is_on()`). What a warning creates when its time is up is
## its caller's (`EventSpawner.spawn_warned()`, through the warning's `arrive`), so the board
## creates nothing itself.
##
## Handed the world the events stand in (`EventWorld`): the live instances, the player, the map the
## run-log lines name tiles on and the trace they go to.

## How near the end of the day, in seconds, the doubled mark means *now*.
##
## The mark over her head is the one cue in the game that gives an **instruction**, and its second
## level says *it is bad now and you are in it: one step left*. That is a claim about a moment, so it
## needs a clock rather than a radius: raised anywhere inside a lethal event's **outer** radius it
## covers about seven times the area that can end the day for a cyclist (a 90px outer radius against
## a 33px lethal reach), and stays up while the bike rides away.
##
## Read it as the step: at `Tuning.WALK_SPEED` it is 64px, which is two tiles, which is the width of the
## pavement she would have to leave. Long enough to be an instruction she can still obey and short
## enough that it is never up while the answer is "carry on walking".
const LETHAL_MARK_LEAD := 0.7

## The world the events stand in, the player and the live instances.
var world: EventWorld

func _init(the_world: EventWorld) -> void:
	world = the_world

## Takes every warning down: a day's end, or a section's.
func clear() -> void:
	_pending.clear()

## Warnings that are up for something not yet in the world — see `PendingWarning` and
## `warn_first()`. Each is dropped the frame the thing it warns about is created.
var _pending: Array[PendingWarning] = []
## The warnings that are up for something not in the world yet — what `DangerEdge` draws a badge
## for alongside `EventManager.instances()`. See `PendingWarning`.
func pending_warnings() -> Array[PendingWarning]:
	return _pending

# ------------------------------------------------------- the warning comes first ---
# *(PLAYTEST-145: "how offscreen warnings and placements should work is that the warning appears by
# itself with a reasonable position and when the time is right the object is spawned in at that
# location just offscreen."; calm-kestrel, inbox #559: "it should *always* show the warning for x
# seconds (never longer than 2s) without placing anything then place the object immediately off
# screen so it will immediately start coming on the screen turning off the warning"; busy-quail,
# inbox #569: "1s warning should be enough".)* Everything that arrives from off screen under the
# screen-edge badge comes through here: `cyclist` from the director, and
# `charging_dog` when the director sends it down her heading; the fire engine from the fire it was
# called to; day 13's column from `ResistanceHappenings`; and, sent from out of her sight
# (`send_from_out_of_sight()`), the resistance's own pursuers from `ResistanceDirector`, the moment
# she has done a task, and the pursuer on foot a torn poster sends.

## Puts up a warning for `def` with nothing in the world yet, pointing where `where` gives for her
## standing at `her`, and once its badge has been up alone for the row's own `warned_for()` — at
## most `Tuning.WARNING_ALONE_MAX` — asks `where` again and hands `arrive` the place — see
## `PendingWarning` for both callables. Returns the warning, or null when `where` has no place for
## it on the thing's own ground right now, in which case nothing is up and the caller asks again
## later.
##
## **Whatever comes through here is a row warned of before it exists** (`EventSpawner.as_warned()`), so the
## fairness contract holds it to the flat `Tuning.OFFSCREEN_WARNING_MIN` whichever caller sent it.
func warn_first(def: EventDef, her: Vector2, where: Callable,
		arrive: Callable) -> PendingWarning:
	var warning := PendingWarning.new(EventSpawner.as_warned(def), where, arrive)
	if not warning.put_up(her):
		return null
	_pending.append(warning)
	return warning

## **Sends `def` at her from out of her sight, warned first**: the one way a pursuer that is set on
## her by what she did arrives — a task's trap and day 13's task guard (`ResistanceDirector`), the
## pursuer on foot a torn poster sends (`EventsAhead.send_a_pursuer()`). `search` is
## `func(standing: Vector2, prefer: Vector2) -> SpawnSiting.Start`, where he would start for her
## standing at `standing`, trying `prefer` first where it is not zero; `arrive` is
## `func(place: Vector2, standing: Vector2, start: SpawnSiting.Start) -> void`, which creates him at
## `place` with her at `standing`, `start` being the search's answer that placed him.
##
## The badge goes up alone at once, pointing where the first search put him, along a bearing fixed
## now; when its time is up the search is asked again from wherever she is then, along that bearing
## first, and he is created where it answers, so he comes from where the badge said wherever that
## still serves. Only putting the badge up reuses the first answer: the camera can settle while she
## stands still, so the start he is created at is asked against the view of the moment he exists.
## Returns the warning, or null when the first search found no start, in which case nothing is up
## and nobody is sent; the caller says so in the run log.
func send_from_out_of_sight(def: EventDef, her: Vector2, search: Callable,
		arrive: Callable) -> PendingWarning:
	var first: SpawnSiting.Start = search.call(her, Vector2.ZERO)
	if first.at == Vector2.INF:
		return null
	var bearing := (first.at - her).normalized()
	var drawn: Array[SpawnSiting.Start] = [first]
	var putting_up := [true]
	var where := func(standing: Vector2) -> Vector2:
		if putting_up[0]:
			putting_up[0] = false
			return first.at
		drawn[0] = search.call(standing, bearing)
		return drawn[0].at
	var on_arrival := func(place: Vector2, standing: Vector2) -> bool:
		arrive.call(place, standing, drawn[0])
		return true
	return warn_first(def, her, where, on_arrival)

## Moves every warning's place with her, standing at `here`, and creates what is due. Run every
## frame there is a player. A warning withdrawn — its ground had no place for the thing when its
## time was up — says so in the run log and hands its caller the chance to ask again.
func run(delta: float, here: Vector2) -> void:
	if _pending.is_empty():
		return
	var still_up: Array[PendingWarning] = []
	for warning in _pending:
		if not warning.tick(delta, here):
			still_up.append(warning)
		elif warning.withdrawn:
			world.trace.note("ahead", "%s's warning is withdrawn after %.2fs: nowhere out of sight to "
					% [warning.logged_name(), warning.shown] + "put it at %s"
					% RunTrace.tile(world.map.world_to_tile(here)))
			if warning.on_withdrawn.is_valid():
				warning.on_withdrawn.call()
	_pending = still_up

# ------------------------------------------------------- the mark over her head ---
# There are no rings around dangerous things. This is the half of what replaces them that is about
# the player rather than about the thing; `Crowd` does the same for the traffic, and the two
# compose because `Stroller.warn()` keeps the loudest level rather than the last caller's opinion.

## Raises the exclamation mark when the ground she is standing on is the problem.
##
## **The mark means: this will end your day.** Two levels, and nothing else raises either.
## `SOON` is a lethal event still telegraphing whose radius already covers her — the thing has
## not happened yet and walking out is the answer, which is exactly what the fairness contract
## promises her time to do. `NOW` is one of them live with her inside its reach: one step left
## between her and the end of the day. A patrol car that drives (`EventDef.vehicle`) raises `SOON`
## the way a crowd car's horn does, while it is closing on her in its lane.
##
## **Raising it for any telegraphing event whose radius reaches her is the mistake to avoid.** Most
## of the catalogue is not a `hard_fail`, and for those the mark would mean *a number is about to
## move faster*, which the meter already says continuously and proportionally — a mark a player can
## correctly ignore, *"I can just keep doing what I was doing"*. The caret over an entity follows
## the same rule — **a cue that marks everything says nothing** — except that this is the one cue in
## the game that cannot afford it, because it is the only one that gives an *instruction*.
##
## The cost of that narrowness is real and is the right cost: few rows in the whole catalogue are
## lethal, so the mark is rare, and it is rarest early. That is not the cue being broken, it is the
## cue being honest about a game whose first days are barely dangerous.
##
## **And `NOW` is about the pair of them, not about the disc.** Raised for any live lethal event
## whose **outer** radius covers her, it is up across about seven times the area that could hurt
## her — a cyclist ends the day inside 33px and its outer radius reaches 90 — and it stays up while
## the bike rides away, which is *"the flashing exclamation marks after the fact"* on the events'
## side of a fix the traffic already has in `stand_down()`.
##
## So it is two conditions: she is within `LETHAL_MARK_LEAD` seconds of the radius that ends the
## day, **and** the gap is actually shrinking at the speeds in play.
##
## The closing rate is **relative** — her velocity is in it — and that is deliberately the opposite
## of the screen-edge badge, which measures the event's own approach with the player held still.
## The two cues say different sentences. A badge says *a thing exists and is coming*, so
## her walking towards it must not raise one; this mark says *the contract is now about you*, which
## is a statement about the pair of them and is false the moment she is opening the gap. It is also
## what makes the mark work for something that never moves: a reversing lorry cannot come to her, so
## the only way it becomes about her is that she is walking into it.
func warn_about_the_ground_she_is_on() -> void:
	var here := world.player.global_position
	var body := world.player as Stroller
	if not body:
		return
	for instance in world.instances:
		# A car that drives warns the way a crowd car's horn does: `SOON`, while it is closing on her
		# in its lane on the carriageway (`EventCarDriving.closes_on()`), which is the car's own
		# contract — `Tuning.CAR_HORN_TIME` before its strike.
		if instance.def.vehicle != null:
			if instance.car and instance.car.closes_on(here):
				body.warn(Stroller.Alert.SOON, WARNING_HOLD, WARNING_SOURCE)
			continue
		if instance.is_finished or not instance.def.hard_fail:
			continue
		# A barrier whose guard has left his post for good is waiting for nobody: he never notices
		# her or charges again (`EventBarrierPost.is_spent()`), so it has nothing to warn of.
		if instance.barrier_post and instance.barrier_post.is_spent():
			continue
		var gap := instance.global_position.distance_to(here) - instance.def.inner_radius
		# `SOON` is anything that cannot kill her *yet* — a telegraph running, or a pursuer that has
		# not noticed her. Without the second half a man standing in an alley raises `NOW` — one
		# step from the end of the day — from two hundred pixels away, which is the marks-everything
		# mistake arriving at the one cue that cannot afford it.
		#
		# It keeps the whole outer radius, because that is exactly what the fairness contract
		# promises her time to walk out of. Only `NOW` is about a moment.
		if instance.is_telegraphing() or instance.is_waiting():
			if gap + instance.def.inner_radius <= instance.def.outer_radius:
				body.warn(Stroller.Alert.SOON, WARNING_HOLD, WARNING_SOURCE)
			continue
		var to_her := here - instance.global_position
		if to_her.length_squared() < 1.0:
			body.warn(Stroller.Alert.NOW, WARNING_HOLD, WARNING_SOURCE)
			continue
		var closing := (instance.travel_velocity() - body.velocity).dot(to_her.normalized())
		if closing > 0.0 and gap <= closing * LETHAL_MARK_LEAD:
			body.warn(Stroller.Alert.NOW, WARNING_HOLD, WARNING_SOURCE)

## How long a raised warning stays up. A shade longer than a physics frame, so the mark does not
## strobe on the boundary of a radius she is walking along — which is short enough that this
## side of the vocabulary never needs `stand_down()`: it is re-raised every frame it is true and
## gone a frame after it stops being.
const WARNING_HOLD := 0.35
## Named so the traffic's hold and this one cannot take each other down. See `Stroller.warn`.
const WARNING_SOURCE := &"events"
