extends RefCounted
## A signal head: lit, it shows its face with one lamp on it; with the power out it is drawn again with
## no lamp at all (what the last night's blackout does to it, `tests/test_blackout.gd`).
##
## The head is handed the signals and a drawer that records what it draws, as the city hands it both;
## the signals are a stand-in that answers green while it has power, since which lamp the clock picks is
## `TrafficSignals`' (`tests/test_traffic_signals.gd`) and no city or map is built.

const RecordingTrafficLightDrawer := preload("res://tests/recording_traffic_light_drawer.gd")
const UI := preload("res://tests/ui_screens.gd")

## Signals that are green for every arm while they have power: the head reads `powered` first, so
## what it shows with the power out is the real class's answer.
class GreenSignals extends TrafficSignals:
	func _init() -> void:
		super(null)

	## Overrides TrafficSignals.green_for.
	func green_for(_junction: Vector2i, _vertical: bool) -> bool:
		return true

func run(t: TestRunner) -> void:
	await _test_a_head_shows_its_lamp_and_loses_it_when_the_power_goes(t)

func _test_a_head_shows_its_lamp_and_loses_it_when_the_power_goes(t: TestRunner) -> void:
	var signals := GreenSignals.new()
	var light := TrafficLight.new()
	var head := RecordingTrafficLightDrawer.new()
	light.mount(null, head, Vector2i.ZERO, signals)
	light.faces(Vector2.UP)
	t.add_child(light)
	await UI.frames(t, 2)
	var lit_head := head.shown()
	var lit_lamps: Array = lit_head.get("lamps", [])
	t.check(lit_head.get("picture") == TrafficLight.HEAD and lit_lamps.size() == 1,
			"a lit signal head shows its face with one lamp on it (%s)" % [lit_head])
	signals.powered = false
	await UI.frames(t, 2)
	var dark_head := head.shown()
	var dark_lamps: Array = dark_head.get("lamps", [0])
	t.check(dark_head.get("frame", -1) > lit_head.get("frame", -1)
			and dark_head.get("picture") == TrafficLight.HEAD and dark_lamps.is_empty(),
			"a signal head is drawn again with no lamp at all (%s)" % [dark_head])
	light.free()
