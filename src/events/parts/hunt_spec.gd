class_name HuntSpec
extends Resource
## **How a row hunts her once the resistance has heated it past its rung's threshold**: the
## behaviour `EventDef.at_heat()` attaches to its copy (`EventDef.hunting`), authored on the cold row
## (`EventDef.hunts`). One of two shapes, never both:
##
## - **A vehicle that lets men out** (`lets_out()`): once it notices her it stops and lets that many
##   men out on foot, who pursue her (`EventInvestigation`); the vehicle itself never chases. The
##   patrol car on the `PRESSES` rung lets one out, the two vans on the `HUNTS` rung two.
## - **A man who pursues her himself** (`pursuit()`): the roadblock's guard, whose hunting copy takes
##   this `PursuitSpec` at the ladder's own speed and notice.
##
## **It carries its rung**: a row answers to heat exactly when it holds one. `pressing()` is the `PRESSES` rung, the patrol that
## investigates and never hunts; `letting_out()` and `pursuing()` are the `HUNTS` rung. A value: built
## once by a factory, never changed, held by the cold row and by its heated copy alike.
##
## Its numbers are the row's; when it starts and how far off it notices her are the rung's
## (`EventDef.HEAT_INVESTIGATES_LEVEL` and `EventDef.HEAT_INVESTIGATE_WITHIN` for `PRESSES`,
## `EventDef.HEAT_HUNTS_LEVEL` and `EventDef.HEAT_HUNTS_WITHIN` for `HUNTS`).

## Which rung of the resistance's ladder it answers on.
enum Rung {
	## **More of them, and more expensive to stand near, and past a threshold it investigates**: it
	## never gains `hard_fail`, and the man it lets out costs her when he reaches her rather than
	## ending the day (`PursuitSpec.stop_excitement()`).
	PRESSES,
	## **It stops being a place and starts being a hunter**: the lethal rung, whose catch ends the day.
	HUNTS,
}

var _rung := Rung.HUNTS

## How many men the vehicle lets out once it stops for her, or 0 for a hunt that pursues.
## *(Inbox #669 in coral-lark: "Van stops, men get out" — men, so more than one; two for a van is
## chosen while building, open to overturn.)*
var _lets_out := 0

## How the hunting copy pursues her, or null for a vehicle that lets men out.
var _pursuit: PursuitSpec = null

## **Whether the hunting copy's own catch ends the day**, which the copy takes as its
## `EventDef.hard_fail`: the roadblock's guard, a man whose catch is a pursuer's. A vehicle that lets
## men out keeps its cold row's lethality; its men's catch is their own row's
## (`EventCatalogue.out_of_the_car()`).
var _ends_the_day := false

## **The patrol rung's hunt**: the vehicle stops for her and lets one man out, whose catch is a stop
## and not the end of the day.
static func pressing() -> HuntSpec:
	var spec := HuntSpec.new()
	spec._rung = Rung.PRESSES
	spec._lets_out = 1
	return spec

## A vehicle's hunt on the lethal rung: it stops for her and lets `men` out, at least one.
static func letting_out(men: int) -> HuntSpec:
	assert(men > 0, "a vehicle's hunt lets at least one man out")
	var spec := HuntSpec.new()
	spec._lets_out = men
	return spec

## A man's hunt on the lethal rung: he pursues her as `chase` says, and his catch ends the day.
static func pursuing(chase: PursuitSpec) -> HuntSpec:
	assert(chase != null, "a man's hunt pursues her as a pursuit says")
	var spec := HuntSpec.new()
	spec._pursuit = chase
	spec._ends_the_day = true
	return spec

## Whether it is the patrol rung's hunt, which investigates and never hunts.
func presses() -> bool:
	return _rung == Rung.PRESSES

## How many men the vehicle lets out once it stops for her, or 0 for a hunt that pursues.
func lets_out() -> int:
	return _lets_out

## How the hunting copy pursues her, or null for a vehicle that lets men out.
func pursuit() -> PursuitSpec:
	return _pursuit

## Whether the hunting copy's own catch ends the day.
func ends_the_day() -> bool:
	return _ends_the_day
