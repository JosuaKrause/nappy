class_name EventPursuit
extends EventBehaviour
## **Coming after her** (`EventDef.pursuit`): the notice along a clear line, the close to a
## stand-off and the lunge from it, the charge once a warning has run, giving up when she runs, and
## a walked route while it still waits. The one kind of thing running is the answer to; its
## contract in seconds is `Tuning.validate_pursuit()`, and in distances `Tuning.pursuit_standoff()`.
##
## **It comes through its own telegraph**, as a fire engine does: a telegraph spent standing still
## is a head start she simply walks away with, since a chase closes only about 56px a second on a
## walk. **But it closes to a stand-off and holds it** rather than arriving, since a pursuer that
## arrives early stands inside its own lethal radius for the rest of a telegraph and kills her from
## a standing start the moment it may. **A pursuer that waited for her and stands for its notice**
## (`PursuitSpec.stands`) closes nothing while it warns (inbox #748 in minty-lemur); what keeps it a
## chase is the charge once its warning has run with her still inside its radius.
##
## **A pursuer that waited for her warns inside its one radius, on a clock** (`warns_by_radius()`,
## inbox #788 in minty-lemur): from the frame it notices her inside `EventDef.notice` it warns for
## its `notice_time()`; her back outside the radius stops the warning and it waits again from where
## it stands; still inside once the warning has run, it charges, along a clear line. Walking away
## from the warning is safe; standing in it is not.
##
## **And it gives up when it is being outrun**, not when a gap has reached a size: it is faster than
## a walk and slower than a run by construction, so sustained running for
## `Tuning.PURSUIT_SHAKEN_OFF` seconds ends a chase and walking away never does.

## **True once a wall has held its lunge back**: she came inside its stand-off with no clear line
## between them, or it first noticed her already inside it, which only a wall between them can do.
## **The lunge needs a clear line** (mossy-beaver, inbox #650), and a lunge merely deferred until the
## line clears is the events skill's trap: at an alley mouth the line clears with her already inside
## the stand-off, and it would lunge from a fraction of it. So a held pursuer holds its position
## while she is nearer than the stand-off, follows at the stand-off once she is further, and lunges
## the moment she is back at the full stand-off with the line clear; its notice does not run out
## while she is inside the stand-off (`EventInstance._pause_a_held_notice()`). Only a pursuer that
## comes for her through its notice holds a lunge — the day-3 dog and day 13's task guard set on her
## (`EventInstance.notice_her_at()`); a charger that warns by radius charges on its warning's clock.
var lunge_held := false
## How long the gap to her has been opening while she runs, in seconds; the chase ends at
## `Tuning.PURSUIT_SHAKEN_OFF`, and anything that is not her running puts it back to zero.
var outrun_for := 0.0
## The gap to her on the previous tick, `INF` before the first.
var last_range := INF

## One tick: stand with her once its man has stopped her (`EventOfficer`), else walk its route while
## it still waits, then the chase.
func step(delta: float) -> void:
	if event.has_stopped_her():
		return
	if event.is_waiting() and event.route != null and event.path.size() > 1:
		event.route.advance(delta)
	_chase(delta)

func _chase(delta: float) -> void:
	var her: Vector2 = event.player_at
	if her == Vector2.INF or event.is_telegraphing_still() or event._guard_spent:
		return
	var def: EventDef = event.def
	var toward: Vector2 = her - event.global_position
	var range_to_her := toward.length()
	if range_to_her < 1.0:
		return
	# From what ends her day (`EventDef.standoff_reach()`, its catch unless the row keeps its lunge
	# further out, the alley robber's `PursuitSpec.lunge_reach`), not from its field's core.
	var standoff: float = event.charge_radius()
	if event.is_waiting():
		_notice(toward, standoff)
		return
	# Out of its warning radius it stops warning and waits again where it stands, measured from where
	# it noticed her (`body_position()`, the band's centre for a roadblock's guard at his post).
	if event.is_telegraphing() and event.warns_by_radius() \
			and event.body_position().distance_to(her) > def.notice_within():
		event._stop_warning()
		return
	# A raised hand that is the indicator of a charge to come is a warning too: the man a vehicle
	# lets out, day 13's guard in her view.
	var warning: bool = event._its_notice_is_a_warning()
	if event.is_telegraphing() and warning:
		event._report_the_warning()
	# `VisitCounter`'s "-chased": actually coming for her (docs/TELEMETRY.md, "The page counts
	# visits"); a warning she can walk out of is not a chase.
	if not event._charge.began and not (warning and event.is_telegraphing()):
		event._charge.begin()
	event._heading = toward.normalized()
	if _shaken_off(delta, range_to_her):
		event.gave_up = true
		event._be_done()
		return
	# Straight at her, and no faster than its own speed: the contract is the speed.
	var step := minf(def.pursuit.speed * delta, range_to_her)
	if event.is_telegraphing():
		step = _close_through_the_telegraph(delta, step, range_to_her, standoff)
	# **Day 13's task guard walks round buildings toward her** (`EventInstance._paths_to_her`):
	# where no clear line runs to her he follows the walk instead. Only the direction changes.
	if event._paths_to_her:
		event._keep_the_way_to_her_fresh()
		if step > 0.0:
			event._heading = event._way_toward_her(event._heading)
	var moved: Vector2 = event._step(event._heading * step)
	event.position += moved
	# Ground covered, not ground gained: sliding along a wall is still moving.
	event._path_travelled += moved.length()

## **It notices her only along a clear line** (leafy-puffin, inbox #648), within `EventDef.notice`,
## and a charger that waits for her only once his warning would stand in her view. It turns to face
## her on the frame it notices. Noticed already inside the stand-off, which only a wall can do since
## the notice is wider than the stand-off on every row, the wall held the lunge back too.
func _notice(toward: Vector2, standoff: float) -> void:
	var range_to_her := toward.length()
	if range_to_her > event.def.notice_within() or not event._clear_line_to(event.player_at) \
			or not event._would_stand_in_her_view():
		return
	event._notice_her()
	# `VisitCounter`'s "-warned", once per instance (docs/TELEMETRY.md, "The page counts visits").
	if event.warns_by_radius():
		event._report_the_warning()
	event._heading = toward.normalized()
	if range_to_her <= standoff and not event.warns_by_radius():
		lunge_held = true

## **She ran, so it backs off**: seconds of her running, not seconds of the gap opening, since a
## corner, a kerb or a body in the way resets a gap-based timer while she is plainly running. A
## charger that waits for her is shaken off only once he has charged: while he warns, running inside
## his radius counts for nothing (inbox #788 in minty-lemur). An ordinary pursuer keeps its approach
## notice (`Tuning.PURSUIT_MIN_NOTICE`) first; one sent at her already warned with its badge, so
## running counts while it is still off screen (tall-owl).
func _shaken_off(delta: float, range_to_her: float) -> bool:
	var def: EventDef = event.def
	if event.player_running and not (event.warns_by_radius() and event.is_telegraphing()):
		outrun_for += delta
	else:
		outrun_for = 0.0
	last_range = range_to_her
	var may_give_up: bool = def.starts_by(PursuitSpec.Start.ARRIVES_CHASING) \
			or def.starts_by(PursuitSpec.Start.CHARGES_AT_ONCE) or event.warns_by_radius() \
			or event.chase_age() >= Tuning.PURSUIT_MIN_NOTICE
	return outrun_for >= Tuning.PURSUIT_SHAKEN_OFF and may_give_up

## **How far it closes this tick while its telegraph runs, and whether it lunges.** It closes to the
## stand-off, holds it, and lunges when she reaches it, whichever comes first of her and the clock:
## - one that set off beside her (`PursuitSpec.Start.SETS_OFF_BESIDE_HER`) was made inside its own
##   stand-off, so it neither lunges early nor backs off: it holds its ground while she is nearer and
##   follows at the stand-off once she is further, and its notice runs its whole length;
## - a held one (`lunge_held`) holds the same ground and lunges once she is back at the full
##   stand-off with the line clear, at its chase speed rather than any notice walk, since a robber
##   left trailing out of an alley mouth at a walk starts his chase from deep in the alley;
## - one with a notice walk (`PursuitSpec.walk_speed`, the alley robber's, inbox #761 in
##   minty-lemur) closes at it, so his alert walk is seen;
## - a charger that warns by radius charges on its warning's clock, not on a distance, and holds at
##   the stand-off;
## - one that stands for its notice (`PursuitSpec.stands`) closes nothing, and every lunge above
##   still fires, so she is never the one who walks the last of the gap into a catch.
func _close_through_the_telegraph(delta: float, step: float, range_to_her: float,
		standoff: float) -> float:
	var def: EventDef = event.def
	var beside_her := def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER)
	if def.pursuit.walk_speed > 0.0 and not (beside_her or lunge_held):
		step = minf(def.pursuit.walk_speed * delta, range_to_her)
	var clear: bool = event._clear_line_to(event.player_at)
	if beside_her or lunge_held:
		step = clampf(range_to_her - standoff, 0.0, step)
		if lunge_held and clear and range_to_her >= standoff:
			event.transition(EventInstance.Phase.ACTIVE)
	elif event.warns_by_radius():
		step = clampf(range_to_her - standoff, 0.0, step)
	elif range_to_her <= standoff:
		if clear:
			event.transition(EventInstance.Phase.ACTIVE)
		else:
			lunge_held = true
			step = 0.0
	else:
		step = minf(step, range_to_her - standoff)
	if event.is_standing_for_its_notice():
		step = 0.0
	return step

func save() -> Dictionary:
	return {"lunge_held": lunge_held, "outrun_for": outrun_for, "last_range": last_range}

func restore(state: Dictionary) -> void:
	lunge_held = bool(state.get("lunge_held", false))
	outrun_for = float(state.get("outrun_for", 0.0))
	last_range = float(state.get("last_range", INF))
