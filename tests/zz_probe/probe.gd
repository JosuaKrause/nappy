extends Node
## Throwaway: boots the real game, stands her beside the nearest homeless_yeller every physics
## frame, and prints the meter and the halo once a second.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
var _main: Node
var _t := 0.0
var _next := 1.0
var _offset := Vector2(0, 30)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	if OS.get_environment("PROBE_OFFSET") != "":
		_offset = Vector2(0, float(OS.get_environment("PROBE_OFFSET")))

func _nearest_yeller() -> EventInstance:
	var player: Stroller = _main._player
	if not player or not _main._city:
		return null
	var best_plan: EventScheduler.Planned = null
	var best_d := INF
	for plan in _main._city.events.plans():
		if plan.def.id != "homeless_yeller" or not plan.is_placed():
			continue
		var d: float = plan.position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best_plan = plan
	if best_plan == null:
		return null
	if best_plan.live == null:
		# Walk her there; the game streams it in on its own.
		player.global_position = best_plan.position
	return best_plan.live

func _physics_process(delta: float) -> void:
	if not _main._player:
		return
	_t += delta
	if _main._in_the_title and _t > 0.5:
		print("pressing the title disc at t=%.1f" % _t)
		_main._on_title_start(ControlsMode.Mode.TAP)
	if _t < 1.0:
		return
	var player: Stroller = _main._player
	var baby: Baby = _main._baby
	var yeller := _nearest_yeller()
	if yeller == null:
		if _t >= _next:
			_next += 1.0
			print("t=%.1f no yeller live" % _t)
		return
	player.global_position = yeller.global_position + _offset
	var walk := OS.get_environment("PROBE_WALK") != "" or (OS.has_feature("web") and "walk=1" in DevFlags._web_query())
	player.velocity = Vector2(Tuning.WALK_SPEED, 0.0) if walk else Vector2.ZERO
	if _t >= _next and _t < 15.0:
		_next += 1.0
		var contribution := yeller.contribution_at(player.global_position)
		var in_sources := false
		for pair in _main._city.excitement_sources_at(player.global_position):
			if pair[0] == yeller:
				in_sources = true
		print("  id=%d processing=%s in_tree=%s mode=%d" % [yeller.get_instance_id(), yeller.is_processing(), yeller.is_inside_tree(), yeller.process_mode])
		print("  hist=%d clock=%.2f first=%s" % [yeller._landed_history.size(), yeller._clock, str(yeller._landed_history.front()) if not yeller._landed_history.is_empty() else "-"])
		print("t=%.1f day=%d exc=%.1f in=%.2f decay=%.2f state=%d | yeller contrib=%.2f in_sources=%s landed=%.2f leaving=%s finished=%s telegraph=%s age=%.1f int=%.2f | halo target=%.2f alpha=%.2f"
				% [_t, GameState.day, baby.excitement, baby.last_incoming, baby.last_decay, baby.state,
				contribution, in_sources, yeller.landed(), yeller.is_leaving, yeller.is_finished,
				yeller.is_telegraphing(), yeller.age, yeller.current_intensity(),
				yeller._halo._target_alpha, yeller._halo._alpha])
