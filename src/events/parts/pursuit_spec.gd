class_name PursuitSpec
extends RefCounted
## **How a row comes after her**: faster than her walk and slower than her run, so walking away
## loses and running away wins. `Tuning.validate_pursuit()` is its fairness contract, stated over
## the numbers here and the row's notice (`NoticeSpec`); `standoff()` is that contract in distance.
##
## A row has a `PursuitSpec` only when it pursues; one that only pursues once it hunts (the
## roadblock, `EventDef.answers_to_heat()`) carries the spec its hunting copy takes, and `EventDef.at_heat()`
## gives that copy its speed (`at_speed()`) and its notice.
##
## A value: built by `at()`, refined by methods that each return a new pursuit, never changed, so a row and
## its heated copy share one.

## How long she is allowed to take to answer the lunge, at the speed the gap is actually closing.
##
## **A notice stated as a duration is not a notice**, because it says nothing about where the
## pursuer spends it. Buying telegraph time alone gives a dog sited a couple of hundred pixels
## across her line that closes the gap in three quarters of a second and then stands inside its own
## lethal radius for the rest of a telegraph it is not allowed to kill her during. The instant it
## ends, it does — from a standing start, with nothing she could have done after the first second.
##
## So the telegraph is spent **closing to a stand-off and holding there**, which is
## `PursuitSpec.standoff()`, and this is the number that sets it: far enough out that the lunge
## itself can be answered rather than merely watched.
##
## **This number is the one thing about the day-3 dog a player has said is right** — *"it was enough
## time to react properly"* — so it is the wrong lever to reach for. The arithmetic that says the
## real window is two tenths of a second once her walking speed and the about-turn are counted is
## correct and answers a different complaint: *the dog kept following for too long* is the
## **break-off**. See `Tuning.PURSUIT_SHAKEN_OFF`.
##
## What boxes it in, in both directions: **walking must still lose** and **running must still win**
## inside `Tuning.PURSUIT_TIME`, both at 38px/s of authority against the day-3 dog, and the stand-off has to
## be **on screen** — the visible world is 640x360 at zoom 2, so a dog standing much past 180px in
## front of her telegraphs off the top of the screen when she walks north or south, and the sight of
## it is the whole cue.
const PURSUIT_REACTION := 0.6

## How a pursuer's chase begins.
enum Start {
	## **It notices her first.** One that waits for her (`EventDef.waits_for_her()`) warns inside its one
	## radius for `warns_for` and charges if she is still inside once that has run; one with no
	## notice closes on her through its telegraph and lunges at its stand-off (the day-3 dog).
	NOTICES,
	## **It is put down beside her, inside its own stand-off, to charge her** — the men a vehicle
	## lets out (`EventCatalogue.out_of_the_car()`). Its notice is the ground it holds: it never
	## lunges early and never backs off, and it charges when its notice has run its whole length.
	SETS_OFF_BESIDE_HER,
	## **It charges from its first frame, because its warning came before it was set on her** — the
	## checkpoint guard, whose warning is the hut guard's raised hand for `CheckpointController.CROSSING_WARNING`
	## after she crossed the door's line. It owes no notice of its own (inbox #788 in minty-lemur).
	CHARGES_AT_ONCE,
	## **It is warned of by its badge alone and created already chasing her** — the robber and the
	## guard a done task sends. Running while it is still off screen counts toward shaking it off
	## (tall-owl).
	ARRIVES_CHASING,
}

## How fast it comes, in px/s: strictly between `Tuning.WALK_SPEED` and `Tuning.RUN_SPEED`.
var _speed := 0.0

var _start := Start.NOTICES

## **How long a pursuer that waited for her warns before it charges**, in seconds, from the frame it
## notices her inside its one radius (inbox #788 in minty-lemur). `validate()` holds a pursuer that
## waits to at least `Tuning.OFFSCREEN_WARNING_MIN`.
var _warns_for := 0.0

## Whether it **stands still in its alert pose for its notice** rather than closing on her
## (woolly-penguin #748): the waiting dog, the roadblock's guard, the men a vehicle lets out. Only
## the closing stops; every lunge and charge is decided as for one that closes. The alley robber
## does not stand: he walks at her through his notice.
var _stands := false

## How fast it **walks at her through its notice**, in px/s, when that is slower than its chase,
## or 0 to close at `speed` (the alley robber's slow alert walk, so it can be seen).
var _walk_speed := 0.0

## Where its lunge is measured from when that is not its catch, in px, or 0 for its catch: the
## alley robber catches at 26px and lunges from 38px. `EventDef.standoff_reach()` reads it.
var _lunge_reach := 0.0

## **A catch that is a stop rather than the end of the day**, in points of the excitement meter, or
## 0 for a catch that is what the row's `LethalSpec` says. When he reaches her he stops, his own field
## lands this much on her standing beside him over `Tuning.OFFICER_STOP_SECONDS`, and he walks back to
## the vehicle that let him out (inbox #669 in coral-lark). Only the man an investigating patrol car
## lets out sets it (`EventCatalogue.out_of_the_car()`); `EventDef.validate()` holds it under the
## whole meter and refuses it on a row that ends the day.
var _stop_excitement := 0.0

## Whether the row's body is **a fixture of the street the man leaves standing** when he sets off,
## rather than his own bulk: the roadblock, whose barrier stays shut behind its guard. The body is
## pinned where it was left (`EventBarrierPost`) and drawn there, so the picture and the street agree.
## A moving pursuer otherwise drops its body the frame it stops waiting, since a moving wall pins her.
var _leaves_its_body := false

## Whether the man is **drawn over the street's other figures while he stands for his notice**
## (`DrawLayer.Layer.WARNING`), and sorts with them again once he charges: the roadblock's guard at
## his post, whom a van parked in front of the post would otherwise hide while his raised hand is the
## warning (inbox #771 in minty-lemur).
var _warns_over_the_street := false

## Whether the man **walks round buildings toward her once he is after her**: where no clear line
## runs to her he follows the walk to her over the ground she can walk (`ChaseWay`, made by
## `Navigator.way_to()`), refreshed as she moves, rather than the straight line every other chase
## slides along walls. The roadblock's posted guard, so a walker who goes straight past his post and
## turns the next corner is caught as a straight walker is *(inbox #1534 in velvet-alpaca: asked
## whether he follows her round the corner or she may get away, "sure, your pick", the pick being
## that he follows her)*. Only the way he heads changes: his notice, his warning, his speed and when
## he gives up are the row's. Day 13's task guard has a way too, given when she is set on him from
## wherever he stands (`EventInstance.notice_her_at()`), not by his row.
var _paths_round_buildings := false

## A pursuer at `chase_speed` that notices her first, the shape most rows start from.
static func at(chase_speed: float) -> PursuitSpec:
	var spec := PursuitSpec.new()
	spec._speed = chase_speed
	return spec

## The same pursuer at another speed: the heated copy's, at the ladder's own.
func at_speed(chase_speed: float) -> PursuitSpec:
	var spec := _copy()
	spec._speed = chase_speed
	return spec

## The same pursuer whose chase begins as `how` says.
func starting_by(how: Start) -> PursuitSpec:
	var spec := _copy()
	spec._start = how
	return spec

## The same pursuer warning for `seconds` before it charges.
func warning_for(seconds: float) -> PursuitSpec:
	var spec := _copy()
	spec._warns_for = seconds
	return spec

## The same pursuer standing still in its alert pose for its notice rather than closing on her.
func standing() -> PursuitSpec:
	var spec := _copy()
	spec._stands = true
	return spec

## The same pursuer walking at her through its notice at `pace`, in px/s.
func walking_at(pace: float) -> PursuitSpec:
	var spec := _copy()
	spec._walk_speed = pace
	return spec

## The same pursuer lunging from `reach`, in px, where that is not its catch.
func lunging_from(reach: float) -> PursuitSpec:
	var spec := _copy()
	spec._lunge_reach = reach
	return spec

## The same pursuer whose catch is a stop costing her `points` of the excitement meter.
func stopping_her_for(points: float) -> PursuitSpec:
	var spec := _copy()
	spec._stop_excitement = points
	return spec

## The same pursuer leaving its body standing as a fixture of the street when it sets off.
func leaving_its_body() -> PursuitSpec:
	var spec := _copy()
	spec._leaves_its_body = true
	return spec

## The same pursuer drawn over the street's other figures while it stands for its notice.
func over_the_street() -> PursuitSpec:
	var spec := _copy()
	spec._warns_over_the_street = true
	return spec

## The same pursuer walking round buildings toward her once it is after her.
func round_buildings() -> PursuitSpec:
	var spec := _copy()
	spec._paths_round_buildings = true
	return spec

## How fast it comes, in px/s: strictly between `Tuning.WALK_SPEED` and `Tuning.RUN_SPEED`.
func speed() -> float:
	return _speed

## How its chase begins.
func start() -> Start:
	return _start

## How long a pursuer that waited for her warns before it charges, in seconds.
func warns_for() -> float:
	return _warns_for

## Whether it stands still in its alert pose for its notice rather than closing on her.
func stands_for_its_notice() -> bool:
	return _stands

## How fast it walks at her through its notice, in px/s, or 0 to close at `speed()`.
func walk_speed() -> float:
	return _walk_speed

## Where its lunge is measured from when that is not its catch, in px, or 0 for its catch.
func lunge_reach() -> float:
	return _lunge_reach

## What its catch costs her when it is a stop rather than the end of the day, in points of the
## excitement meter, or 0 for a catch that is what the row's `LethalSpec` says.
func stop_excitement() -> float:
	return _stop_excitement

## Whether the row's body is a fixture of the street the man leaves standing when he sets off.
func leaves_its_body_standing() -> bool:
	return _leaves_its_body

## Whether the man is drawn over the street's other figures while he stands for his notice.
func is_drawn_over_the_street() -> bool:
	return _warns_over_the_street

## Whether the man walks round buildings toward her once he is after her.
func walks_round_buildings() -> bool:
	return _paths_round_buildings

func _copy() -> PursuitSpec:
	var spec := PursuitSpec.new()
	spec._speed = _speed
	spec._start = _start
	spec._warns_for = _warns_for
	spec._stands = _stands
	spec._walk_speed = _walk_speed
	spec._lunge_reach = _lunge_reach
	spec._stop_excitement = _stop_excitement
	spec._leaves_its_body = _leaves_its_body
	spec._warns_over_the_street = _warns_over_the_street
	spec._paths_round_buildings = _paths_round_buildings
	return spec

## How close a pursuer comes while it is still only telegraphing.
##
## Derived rather than authored, because it is the fairness contract in geometric form: between the
## moment it is allowed to end her day and the moment it can, she is owed
## `PURSUIT_REACTION` seconds of the thing's own approach. Anything nearer and the telegraph is a formality; anything much
## further and it is off the screen, which is worse — the sight of it closing is the whole cue.
##
## **The edge case it does not price, and it is a known gap.** At the instant of the lunge she is
## usually walking *into* it — a pursuer is sited in front of her, forward is where she was going,
## and it is her walking into the stand-off that fires the lunge rather than her stopping — so the gap closes
## at `pursue_speed + WALK_SPEED` and the notice is worth about a third of what this buys. Reversing
## a walk into a run costs another `(WALK_SPEED + RUN_SPEED) / ACCELERATION` seconds on top, during
## which the thing keeps coming. Measured against the day-3 dog the real window is about **two tenths
## of a second**.
##
## **Both terms belong outside this function**, and folding them in is the tempting fix. The
## stand-off they produce is 70px wider, and the extra ground is spent *reversing away from her*
## through the telegraph, which reads as a dog that has changed its mind — a wider window bought on
## the one part of the encounter a player has said was already right. What the answer costs is
## priced by `Tuning.PURSUIT_SHAKEN_OFF` instead.
static func standoff(pursue_speed: float, inner: float) -> float:
	return inner + pursue_speed * PURSUIT_REACTION
