class_name HuntSpec
extends Resource
## **How a row hunts her once the resistance has heated it past its rung's threshold**: the
## behaviour `EventDef.at_heat()` attaches to its copy (`EventDef.hunting`), authored on the cold row
## (`EventDef.hunts`). One of two shapes, never both:
##
## - **A vehicle that lets men out** (`lets_out`): once it notices her it stops and lets that many
##   men out on foot, who pursue her (`EventInvestigation`); the vehicle itself never chases. The
##   patrol car on the `PRESSES` rung lets one out, the two vans on the `HUNTS` rung two.
## - **A man who pursues her himself** (`pursuit`): the roadblock's guard, whose hunting copy takes
##   this `PursuitSpec` at the ladder's own speed and notice.
##
## Its numbers are the row's; when it starts and how far off it notices her are the rung's
## (`EventDef.HEAT_INVESTIGATES_LEVEL` and `EventDef.HEAT_INVESTIGATE_WITHIN` for `PRESSES`,
## `EventDef.HEAT_HUNTS_LEVEL` and `EventDef.HEAT_HUNTS_WITHIN` for `HUNTS`).

## How many men the vehicle lets out once it stops for her, or 0 for a hunt that pursues.
## *(Inbox #669 in coral-lark: "Van stops, men get out" — men, so more than one; two for a van is
## chosen while building, open to overturn.)*
@export var lets_out := 0

## How the hunting copy pursues her, or null for a vehicle that lets men out.
@export var pursuit: PursuitSpec = null

## **Whether the hunting copy's own catch ends the day**, which the copy takes as its
## `EventDef.hard_fail`: the roadblock's guard, a man whose catch is a pursuer's. A vehicle that lets
## men out keeps its cold row's lethality; its men's catch is their own row's
## (`EventCatalogue.out_of_the_car()`).
@export var ends_the_day := false

## A vehicle's hunt: it stops for her and lets `men` out.
static func letting_out(men: int) -> HuntSpec:
	var spec := HuntSpec.new()
	spec.lets_out = men
	return spec

## A man's hunt: he pursues her as `chase` says, and his catch ends the day.
static func pursuing(chase: PursuitSpec) -> HuntSpec:
	var spec := HuntSpec.new()
	spec.pursuit = chase
	spec.ends_the_day = true
	return spec
