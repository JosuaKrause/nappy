extends Node
## Observe a normal main scene driven only by existing dev flags. No gameplay state is changed.
## The same scene may be run headlessly for preflight or with --screenshot for the evidence burst.

const DRAWING = preload("res://tests/probes/m226_arrival_timing.gd")
var main: Node
var elapsed := 0.0
var states := {}
var covered := false
var emerged := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)

func _exit_tree() -> void:
	print("CORNER_RESULT covered=%s emerged=%s" % [covered, emerged])

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 12.0 and DisplayServer.get_name() == "headless":
		print("CORNER_RESULT covered=%s emerged=%s" % [covered, emerged])
		get_tree().quit(0 if covered and emerged else 1)
	var player: Stroller = main.get("_player")
	var city: City = main.get("_city")
	var edge: DangerEdge = main.get("_edge")
	if player == null or city == null or edge == null:
		return
	var view := city.events.visible_view()
	for instance in city.events.instances():
		if instance.def.id != "charging_dog":
			continue
		var on_camera := false
		var in_visible_area := false
		for part in DRAWING.drawing_parts(instance):
			var world := Rect2(instance.global_position + part.position, part.size)
			on_camera = on_camera or view.view.intersects(world)
			in_visible_area = in_visible_area or view.sees_any(world)
		var badge := false
		for announcement in edge.announcing():
			badge = badge or announcement.id == "charging_dog"
		var state := "%s/%s/%s" % [on_camera, in_visible_area, badge]
		var id := instance.get_instance_id()
		if states.get(id, "") != state:
			print("CORNER %.3f camera=%s visible=%s badge=%s joystick=%s relative=%s age=%.3f" % [
					elapsed, on_camera, in_visible_area, badge, view.joystick,
					instance.global_position - view.view.get_center(), instance.age])
			states[id] = state
		if on_camera and not in_visible_area and badge and view.joystick:
			covered = true
		if covered and in_visible_area and not badge:
			emerged = true
