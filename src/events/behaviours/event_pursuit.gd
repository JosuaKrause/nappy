class_name EventPursuit
extends EventBehaviour
## **Coming after her** (`EventDef.pursuit`): the notice along a clear line, the close to a
## stand-off and the lunge from it, the charge once a warning has run, giving up when she runs, and
## a walked route while it still waits. The one kind of thing running is the answer to; its
## contract in seconds is `Tuning.validate_pursuit()`, and in distances `PursuitSpec.standoff()`.
##
## **It comes through its own telegraph**, as a fire engine does: a telegraph spent standing still
## is a head start she simply walks away with, since a chase closes only about 56px a second on a
## walk. **But it closes to a stand-off and holds it** rather than arriving, since a pursuer that
## arrives early stands inside its own lethal radius for the rest of a telegraph and kills her from
## a standing start the moment it may. **A pursuer that waited for her and stands for its notice**
## (`PursuitSpec.stands`) closes nothing while it warns (woolly-penguin #748); what keeps it a
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
## **The lunge needs a clear line** (mossy-beaver #650), and a lunge merely deferred until the
## line clears is the events skill's trap: at an alley mouth the line clears with her already inside
## the stand-off, and it would lunge from a fraction of it. So a held pursuer holds its position
## while she is nearer than the stand-off, follows at the stand-off once she is further, and lunges
## the moment she is back at the full stand-off with the line clear; its notice does not run out
## while she is inside the stand-off (`pause_a_held_notice()`). Only a pursuer that comes for her
## through its notice holds a lunge — the day-3 dog and day 13's task guard set on her
## (`was_set_on_her()`); a charger that warns by radius charges on its warning's clock.
var _lunge_held := false
## How long the gap to her has been opening while she runs, in seconds; the chase ends at
## `Tuning.PURSUIT_SHAKEN_OFF`, and anything that is not her running puts it back to zero.
var outrun_for := 0.0
## The gap to her on the previous tick, `INF` before the first.
var last_range := INF

## Its row: how close she comes before it notices her, how its chase starts, what ends her day.
var _row: EventDef
## How it comes after her (`PursuitSpec`): its chase speed and its notice walk.
var _pursuit: PursuitSpec
## The ground it chases her over, and steps through, as what it walks as.
var _navigator: Navigator
var _mover: Mover
## Its route walk (`EventRouteWalk`), which it walks while it still waits; null for a row that does
## not move.
var _route: EventRouteWalk
## Its man on foot (`EventOfficer`), who may have stopped her: every pursuer has one.
var _on_foot: EventOfficer
## The barrier its guard walks out of (`EventBarrierPost`), which he is back at when she leaves his
## warning; null for any pursuer but a roadblock's guard.
var _barrier_post: EventBarrierPost

## Handed, as its event is set up, the figure it moves, where she is, its row, how it comes after
## her, the ground and how it moves over it, and the three behaviours beside it it works with.
func _init(figure: EventInstance.Figure, where: WhereSheIs, row: EventDef, pursuit: PursuitSpec,
		navigator: Navigator, mover: Mover, route: EventRouteWalk, on_foot: EventOfficer,
		barrier_post: EventBarrierPost) -> void:
	_figure = figure
	_where = where
	_row = row
	_pursuit = pursuit
	_navigator = navigator
	_mover = mover
	_route = route
	_on_foot = on_foot
	_barrier_post = barrier_post

## One tick: stand with her once its man has stopped her (`EventOfficer`), else walk its route while
## it still waits, then the chase.
##
## Overrides EventBehaviour.step.
func step(delta: float) -> void:
	if _on_foot.has_stopped_her():
		return
	if _figure.is_waiting() and _route != null and _figure.walks().size() > 1:
		_route.advance(delta)
	_chase(delta)

func _chase(delta: float) -> void:
	var her: Vector2 = _where.at()
	if her == Vector2.INF or _figure.is_telegraphing_still() or _figure.is_only_its_barrier():
		return
	var toward: Vector2 = her - _figure.place()
	var range_to_her := toward.length()
	if range_to_her < 1.0:
		return
	# From what ends her day (`EventDef.standoff_reach()`, its catch unless the row keeps its lunge
	# further out, the alley robber's `PursuitSpec.lunge_reach`), not from its field's core.
	var standoff: float = _figure.charge_radius()
	if _figure.is_waiting():
		_notice(toward, standoff)
		return
	# Out of its warning radius it stops warning and waits again where it stands, measured from where
	# it noticed her (`body_place()`, the band's centre for a roadblock's guard at his post).
	if _figure.is_telegraphing() and _figure.warns_by_radius() \
			and _figure.body_place().distance_to(her) > _row.notice_within():
		_stop_warning()
		return
	# A raised hand that is the indicator of a charge to come is a warning too: the man a vehicle
	# lets out, day 13's guard in her view.
	var warning: bool = _figure.notice_is_a_warning()
	if _figure.is_telegraphing() and warning:
		_figure.warning_went_up()
	# `VisitCounter`'s "-chased": actually coming for her (docs/TELEMETRY.md, "The page counts
	# visits"); a warning she can walk out of is not a chase. Said once, however often it is told.
	if not (warning and _figure.is_telegraphing()):
		_figure.charge_began()
	_figure.turn_to(toward.normalized())
	if _shaken_off(delta, range_to_her):
		_figure.give_up()
		return
	# Straight at her, and no faster than its own speed: the contract is the speed.
	var step := minf(_pursuit.speed * delta, range_to_her)
	if _figure.is_telegraphing():
		step = _close_through_the_telegraph(delta, step, range_to_her, standoff)
	# **Day 13's task guard walks round buildings toward her** (`Figure.way_round_to_her()`):
	# where no clear line runs to her he follows the walk instead. Only the direction changes.
	var way_round: ChaseWay = _figure.way_round_to_her()
	if way_round != null:
		way_round.keep_fresh(_where.at(), _figure.place())
		if step > 0.0:
			_figure.turn_to(way_round.toward(_figure.place(), _where.at(), _figure.heading()))
	# Through the navigator, the one place that gets to say no, so a chase stops where she would.
	var moved: Vector2 = _navigator.step(_figure.place(), _figure.heading() * step, _mover)
	_figure.step_by(moved)
	# Ground covered, not ground gained: sliding along a wall is still moving.
	_figure.walk_on(moved.length())

## **It stops warning and waits again, where it stands**: she has gone back out of its warning
## radius. Its notice is forgotten, so the next time she comes inside the radius it notices her and
## warns again from the start, and a lunge it held is forgotten with it. The robber stops where his
## warning walk had got him and waits there; the dog and the guards never moved. A roadblock's
## guard, who stepped out to his post on her side when he noticed her, is back at the band he was
## standing at, with the band's body under him again (`EventBarrierPost.back_at_the_band()`).
func _stop_warning() -> void:
	_figure.wait_for_her_again()
	_lunge_held = false
	if _barrier_post:
		_barrier_post.back_at_the_band()

## **It notices her only along a clear line** (leafy-puffin #648), within `EventDef.notice`,
## and a charger that waits for her only once his warning would stand in her view. It turns to face
## her on the frame it notices. Noticed already inside the stand-off, which only a wall can do since
## the notice is wider than the stand-off on every row, the wall held the lunge back too.
func _notice(toward: Vector2, standoff: float) -> void:
	var range_to_her := toward.length()
	if range_to_her > _row.notice_within() or not _figure.clear_line_to(_where.at()) \
			or not _figure.would_stand_in_her_view():
		return
	_figure.notice_her()
	# `VisitCounter`'s "-warned", once per instance (docs/TELEMETRY.md, "The page counts visits").
	if _figure.warns_by_radius():
		_figure.warning_went_up()
	_figure.turn_to(toward.normalized())
	if range_to_her <= standoff and not _figure.warns_by_radius():
		_lunge_held = true

## **It was set on her where she stands at `her`**, by what she did rather than by what it saw
## (`EventInstance.notice_her_at()`, day 13's waiting guard once she has done the roadblock's
## task): a lunge it held back gives way to this notice, and is held again where she is already
## inside its stand-off.
func was_set_on_her(her: Vector2) -> void:
	_lunge_held = (her - _figure.place()).length() <= _figure.charge_radius()

## **Holds a held lunge's notice still for this tick while she is inside its stand-off** — see
## `_lunge_held`. Asked by its event straight after its age advances, before its phase is settled
## (`EventInstance._hold_the_notice_clock()`), so the frame the notice would have run out is never
## seen as the chase starting. Only while the notice was still running at the start of this tick: a
## chase already under way is never turned back into a notice.
func pause_a_held_notice(delta: float) -> void:
	var her: Vector2 = _where.at()
	if not _lunge_held or _figure.notice_has_run() or _figure.is_waiting() or her == Vector2.INF:
		return
	if _figure.chase_age() - delta >= _figure.notice_time():
		return
	if _figure.place().distance_to(her) < _figure.charge_radius():
		_figure.hold_the_notice(delta)

## **She ran, so it backs off**: seconds of her running, not seconds of the gap opening, since a
## corner, a kerb or a body in the way resets a gap-based timer while she is plainly running. A
## charger that waits for her is shaken off only once he has charged: while he warns, running inside
## his radius counts for nothing (inbox #788 in minty-lemur). An ordinary pursuer keeps its approach
## notice (`Tuning.PURSUIT_MIN_NOTICE`) first; one sent at her already warned with its badge, so
## running counts while it is still off screen (tall-owl).
func _shaken_off(delta: float, range_to_her: float) -> bool:
	if _where.is_running() and not (_figure.warns_by_radius() and _figure.is_telegraphing()):
		outrun_for += delta
	else:
		outrun_for = 0.0
	last_range = range_to_her
	var may_give_up: bool = _row.starts_by(PursuitSpec.Start.ARRIVES_CHASING) \
			or _row.starts_by(PursuitSpec.Start.CHARGES_AT_ONCE) or _figure.warns_by_radius() \
			or _figure.chase_age() >= Tuning.PURSUIT_MIN_NOTICE
	return outrun_for >= Tuning.PURSUIT_SHAKEN_OFF and may_give_up

## **How far it closes this tick while its telegraph runs, and whether it lunges.** It closes to the
## stand-off, holds it, and lunges when she reaches it, whichever comes first of her and the clock:
## - one that set off beside her (`PursuitSpec.Start.SETS_OFF_BESIDE_HER`) was made inside its own
##   stand-off, so it neither lunges early nor backs off: it holds its ground while she is nearer and
##   follows at the stand-off once she is further, and its notice runs its whole length;
## - a held one (`_lunge_held`) holds the same ground and lunges once she is back at the full
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
	var beside_her := _row.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER)
	if _pursuit.walk_speed > 0.0 and not (beside_her or _lunge_held):
		step = minf(_pursuit.walk_speed * delta, range_to_her)
	var clear: bool = _figure.clear_line_to(_where.at())
	if beside_her or _lunge_held:
		step = clampf(range_to_her - standoff, 0.0, step)
		if _lunge_held and clear and range_to_her >= standoff:
			_figure.begin(EventInstance.Phase.ACTIVE)
	elif _figure.warns_by_radius():
		step = clampf(range_to_her - standoff, 0.0, step)
	elif range_to_her <= standoff:
		if clear:
			_figure.begin(EventInstance.Phase.ACTIVE)
		else:
			_lunge_held = true
			step = 0.0
	else:
		step = minf(step, range_to_her - standoff)
	if _figure.is_standing_for_its_notice():
		step = 0.0
	return step

## Overrides EventBehaviour.save.
func save() -> Dictionary:
	return {"lunge_held": _lunge_held, "outrun_for": outrun_for, "last_range": last_range}

## Overrides EventBehaviour.restore.
func restore(state: Dictionary) -> void:
	_lunge_held = bool(state.get("lunge_held", false))
	outrun_for = float(state.get("outrun_for", 0.0))
	last_range = float(state.get("last_range", INF))
