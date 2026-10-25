class_name PursuitSpec
extends Resource
## **How a row comes after her**: faster than her walk and slower than her run, so walking away
## loses and running away wins. `Tuning.validate_pursuit()` is its fairness contract, stated over
## the numbers here and the row's notice (`NoticeSpec`).
##
## A row has a `PursuitSpec` only when it pursues; one that only pursues once it hunts (the
## roadblock, `EventDef.hunts_as`) carries the spec its hunting copy takes, and `EventDef.at_heat()`
## gives that copy its speed and its notice.

## How a pursuer's chase begins.
enum Start {
	## **It notices her first.** One that waits for her (`EventDef.notice`) warns inside its one
	## radius for `warns_for` and charges if she is still inside once that has run; one with no
	## notice closes on her through its telegraph and lunges at its stand-off (the day-3 dog).
	NOTICES,
	## **It is put down beside her, inside its own stand-off, to charge her** — the men a vehicle
	## lets out (`EventCatalogue.out_of_the_car()`). Its notice is the ground it holds: it never
	## lunges early and never backs off, and it charges when its notice has run its whole length.
	SETS_OFF_BESIDE_HER,
	## **It charges from its first frame, because its warning came before it was set on her** — the
	## checkpoint guard, whose warning is the hut guard's raised hand for `Tuning.CROSSING_WARNING`
	## after she crossed the door's line. It owes no notice of its own (inbox #788 in minty-lemur).
	CHARGES_AT_ONCE,
	## **It is warned of by its badge alone and created already chasing her** — the robber and the
	## guard a done task sends. Running while it is still off screen counts toward shaking it off
	## (tall-owl).
	ARRIVES_CHASING,
}

## How fast it comes, in px/s: strictly between `Tuning.WALK_SPEED` and `Tuning.RUN_SPEED`.
@export var speed := 0.0

@export var start := Start.NOTICES

## **How long a pursuer that waited for her warns before it charges**, in seconds, from the frame it
## notices her inside its one radius (inbox #788 in minty-lemur). `validate()` holds a pursuer that
## waits to at least `Tuning.OFFSCREEN_WARNING_MIN`.
@export var warns_for := 0.0

## Whether it **stands still in its alert pose for its notice** rather than closing on her
## (woolly-penguin #748): the waiting dog, the roadblock's guard, the men a vehicle lets out. Only
## the closing stops; every lunge and charge is decided as for one that closes. The alley robber
## does not stand: he walks at her through his notice.
@export var stands := false

## How fast it **walks at her through its notice**, in px/s, when that is slower than its chase,
## or 0 to close at `speed` (the alley robber's slow alert walk, so it can be seen).
@export var walk_speed := 0.0

## Where its lunge is measured from when that is not its catch, in px, or 0 for its catch: the
## alley robber catches at 26px and lunges from 38px. `EventDef.standoff_reach()` reads it.
@export var lunge_reach := 0.0

## How close the man has to get to catch her when that is not the field's own core, in px, or 0
## for the row's `inner_radius`: the roadblock's guard catches at a man's reach, not at his band's
## core. `EventDef.lethal_reach()` reads it.
@export var catch_reach := 0.0

## **A catch that is a stop rather than the end of the day**, in points of the excitement meter, or
## 0 for a catch that is what the row's `hard_fail` says. When he reaches her he stops, his own field
## lands this much on her standing beside him over `Tuning.OFFICER_STOP_SECONDS`, and he walks back to
## the vehicle that let him out (inbox #669 in coral-lark). Only the man an investigating patrol car
## lets out sets it (`EventCatalogue.out_of_the_car()`); `EventDef.validate()` holds it under the
## whole meter and refuses it on a `hard_fail` row.
@export var stop_excitement := 0.0

## Whether the row's body is **a fixture of the street the man leaves standing** when he sets off,
## rather than his own bulk: the roadblock, whose barrier stays shut behind its guard. The body is
## pinned where it was left (`BarrierPost`) and drawn there, so the picture and the street agree.
## A moving pursuer otherwise drops its body the frame it stops waiting, since a moving wall pins her.
@export var leaves_its_body := false

## Whether the man is **drawn over the street's other figures while he stands for his notice**
## (`DrawLayer.Layer.WARNING`), and sorts with them again once he charges: the roadblock's guard at
## his post, whom a van parked in front of the post would otherwise hide while his raised hand is the
## warning (inbox #771 in minty-lemur).
@export var warns_over_the_street := false

## A pursuer at `speed` that notices her first, the shape most rows start from.
static func at(chase_speed: float) -> PursuitSpec:
	var spec := PursuitSpec.new()
	spec.speed = chase_speed
	return spec
