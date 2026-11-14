extends RefCounted
## `EventRouteLines`, the debug view's seventh layer: it draws the route each live event walks and
## nothing for an event that stands or is gone.
##
## The events are stand-ins: a manager that answers `instances()` with the instances it was given
## (`StandInEvents`), each an `EventInstance` set up in no world on the route the case asks for, so no
## city is built and no day planned. Whether the layer is built, starts on and answers its key is
## `tests/test_debug_layers.gd`'s, which builds the readout that owns it.

## A manager that answers the instances a case hands it, and nothing else of the real one.
class StandInEvents extends EventManager:
	var live: Array[EventInstance] = []

	## Overrides EventManager.instances.
	func instances() -> Array[EventInstance]:
		return live

func run(t: TestRunner) -> void:
	_test_a_live_event_with_a_route_is_drawn_start_to_end(t)
	_test_an_event_that_stands_has_no_route_to_draw(t)
	_test_a_gone_event_is_not_drawn(t)
	_test_no_events_draws_nothing(t)
	_test_the_layer_starts_on_only_when_named(t)

func _event(row: String, at: Vector2, route: PackedVector2Array) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id(row), at, route)
	return instance

func _test_a_live_event_with_a_route_is_drawn_start_to_end(t: TestRunner) -> void:
	var route := PackedVector2Array([Vector2(100.0, 100.0), Vector2(200.0, 100.0),
			Vector2(200.0, 300.0)])
	var events := StandInEvents.new()
	events.live = [_event("police_patrol", route[0], route)]
	var layer := EventRouteLines.new()
	layer.setup(events)
	var drawn := layer.routes()
	t.check(drawn.size() == 1 and drawn[0] == route,
			"the patrol's own route is drawn, every point from its start to its end")
	layer.free()
	events.live[0].free()
	events.free()

func _test_an_event_that_stands_has_no_route_to_draw(t: TestRunner) -> void:
	var route := PackedVector2Array([Vector2(0.0, 0.0), Vector2(50.0, 0.0)])
	var events := StandInEvents.new()
	events.live = [
		_event("alley_robbery", Vector2(400.0, 400.0), PackedVector2Array()),
		_event("police_patrol", route[0], route),
	]
	var layer := EventRouteLines.new()
	layer.setup(events)
	t.check(layer.routes() == [route],
			"a robbery that stands in an alley draws nothing, and the patrol beside it draws its own")
	layer.free()
	for instance in events.live:
		instance.free()
	events.free()

func _test_a_gone_event_is_not_drawn(t: TestRunner) -> void:
	var route := PackedVector2Array([Vector2(0.0, 0.0), Vector2(50.0, 0.0)])
	var instance := _event("police_patrol", route[0], route)
	instance.transition(EventInstance.Phase.DONE)
	var events := StandInEvents.new()
	events.live = [instance]
	var layer := EventRouteLines.new()
	layer.setup(events)
	t.check(layer.routes().is_empty(), "an event that is over and gone draws no route")
	layer.free()
	instance.free()
	events.free()

func _test_no_events_draws_nothing(t: TestRunner) -> void:
	var layer := EventRouteLines.new()
	t.check(layer.routes().is_empty(), "a layer handed no world draws nothing and does not fail")
	layer.free()

func _test_the_layer_starts_on_only_when_named(t: TestRunner) -> void:
	var layer := EventRouteLines.new()
	layer.apply_initial_state([5, 6])
	t.check(not layer.visible, "naming the other route layer and the frame graph does not start it")
	layer.apply_initial_state([7])
	t.check(layer.visible, "naming 7 does")
	layer.free()
