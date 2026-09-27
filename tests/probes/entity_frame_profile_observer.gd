extends Node
## Records population and motion in late _process, matched by engine process-frame ID.
## Visibility means an entity's origin is inside the viewport, not occlusion-tested pixels.

var main: Node
var rows: Array = []
var started := -1
var previous_cars: Dictionary = {}
var output := OS.get_environment("ENTITY_PROFILE_OUTPUT")
var metadata: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100000
	var scene: PackedScene = load("res://scenes/main.tscn")
	main = scene.instantiate()
	add_child(main)
	metadata = {"engine": Engine.get_version_info(), "processor": OS.get_processor_name(),
		"display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"render_on_main_thread": RenderingServer.is_on_render_thread(),
		"readout": main.get("_layer_readout_on"), "graph": main.get("_layer_graph_on"),
		"telemetry": Telemetry.is_active(), "physics_hz": Engine.physics_ticks_per_second,
		"profiler_max_functions": ProjectSettings.get_setting("debug/settings/profiler/max_functions"),
		"viewport": [get_viewport().get_visible_rect().size.x,
			get_viewport().get_visible_rect().size.y],
		"warmup_usec": 5000000, "window_usec": 6000000,
		"columns": ["frame", "physics_frame", "drawn_frame", "stamp_usec", "elapsed_usec",
			"running", "paused", "player_x", "player_y", "counts", "moved_cars", "observer_usec",
			"north_input", "player_velocity_x", "player_velocity_y"],
		"count_columns": ["walkers", "cars", "visible_walkers", "visible_cars",
			"events", "visible_events"]}

func _process(_delta: float) -> void:
	_sample()

func _sample() -> void:
	var stamp := Time.get_ticks_usec()
	var day: DayController = main.get("_day")
	if day == null:
		return
	if started < 0:
		if not day.is_running() or get_tree().paused:
			return
		started = stamp
	var city: City = main.get("_city")
	var player: Stroller = main.get("_player")
	var counts := [0, 0, 0, 0, 0, 0]
	var moved_cars := 0
	var viewport := get_viewport().get_visible_rect()
	var transform := get_viewport().get_canvas_transform()
	for agent: CrowdAgent in city.crowd.agents():
		var k := int(agent.kind)
		counts[k] += 1
		if agent.is_visible_in_tree() and viewport.has_point(transform * agent.global_position):
			counts[2 + k] += 1
		if agent.kind == CrowdAgent.Kind.CAR:
			var id := agent.get_instance_id()
			if previous_cars.has(id) and previous_cars[id] != agent.global_position:
				moved_cars += 1
			previous_cars[id] = agent.global_position
	for event: Node2D in city.events.instances():
		counts[4] += 1
		if event.is_visible_in_tree() and viewport.has_point(transform * event.global_position):
			counts[5] += 1
	rows.append([Engine.get_process_frames(), Engine.get_physics_frames(),
		Engine.get_frames_drawn(), stamp, stamp - started, day.is_running(), get_tree().paused,
		player.global_position.x, player.global_position.y, counts, moved_cars,
		Time.get_ticks_usec() - stamp, Input.is_action_pressed("move_up"),
		player.velocity.x, player.velocity.y])
	if stamp - started >= 11000000:
		get_tree().quit()

func _exit_tree() -> void:
	metadata["rows"] = rows
	var file := FileAccess.open(output + "-scene.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata))
	file.close()
