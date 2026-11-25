class_name EventSetOffRun
extends EventBehaviour
## **A row a place set off, running its line at her** (`EventDef.is_set_off_by_a_place()`, a row
## that moves): the masked man on the escape's stairs. It is created where its warning pointed, with its telegraph
## spent (`SetOffWatch`), so from its first tick it runs its route. Its warning was its badge and
## its run is its charge, each said once for its counter (`EventBus.pursuit_warned`,
## `pursuit_began`) on its first tick.

## Its route walk (`EventRouteWalk`), which it runs from its first tick.
var _route: EventRouteWalk

## Handed, as its event is set up, the figure it moves and the route walk it runs.
func _init(figure: EventInstance.Figure, route: EventRouteWalk) -> void:
	_figure = figure
	_route = route

## One tick: its warning and its charge said (once each, however often told), and its route run.
##
## Overrides EventBehaviour.step.
func step(delta: float) -> void:
	_figure.warning_went_up()
	_figure.charge_began()
	_route.advance(delta)
