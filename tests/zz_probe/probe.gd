extends Node
## Throwaway: boots the real game, stands her beside the nearest homeless_yeller every physics
## frame, and prints the meter and the halo once a second.
##
## `PROBE_RIDER=1` drives the resistance's own note-task instead: walks her onto day 6's chalk
## mark to complete step 1, then follows `ResistanceDirector._rider` — the look-alike that now
## carries the contact, spawned through `EventManager.spawn_extra()` rather than the day's
## ordinary `EventScheduler` placement — the one path `_nearest_yeller()` below (which only reads
## `events.plans()`) never reaches, since an unplanned instance has no `Planned` entry at all.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
var _main: Node
var _t := 0.0
var _next := 1.0
var _offset := Vector2(0, 30)
var _rider_mode := false
var _mark_touched := false
## A real walk-in once the rider is found, rather than a teleport: distance left to close, along
## a fixed bearing, closed at `Tuning.WALK_SPEED` — a straight-line stand-in for the crowd lane a
## real approach would take, since nothing here needs to route round anything to make the point.
var _approach := -1.0
const _APPROACH_START := 260.0
const _APPROACH_DIR := Vector2(0.0, -1.0)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	if OS.get_environment("PROBE_OFFSET") != "":
		_offset = Vector2(0, float(OS.get_environment("PROBE_OFFSET")))
	_rider_mode = OS.get_environment("PROBE_RIDER") != ""

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

## Drives `_main._resistance` directly: stands on today's mark until step 1 completes, then
## stands on the rider `_begin_step()` seeded for step 2. Returns null until the rider exists.
func _rider_yeller() -> EventInstance:
	var player: Stroller = _main._player
	var resistance = _main._resistance
	if not player or not resistance:
		return null
	var step = resistance.current_step()
	if step == null:
		return null
	if step.index == 1 and not _mark_touched:
		var at: Vector2 = resistance.contact_position()
		if at != Vector2.INF:
			player.global_position = at
		return null
	if step.index != 2:
		# Step 1 touched but step 2 not yet active the same frame, or a different step entirely.
		_mark_touched = true
		return null
	_mark_touched = true
	var rider: EventInstance = resistance._rider
	if rider == null or not is_instance_valid(rider):
		return null
	if _approach < 0.0:
		_approach = _APPROACH_START
	if not rider.is_leaving and not rider.is_finished:
		_approach = maxf(0.0, _approach - Tuning.WALK_SPEED * get_physics_process_delta_time())
	player.global_position = rider.global_position + _APPROACH_DIR * _approach
	return rider

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
	var yeller := _rider_yeller() if _rider_mode else _nearest_yeller()
	if yeller == null:
		if _t >= _next:
			_next += 1.0
			var step_note := ""
			if _rider_mode and _main._resistance:
				var step = _main._resistance.current_step()
				step_note = " step=%d" % step.index if step else " step=none"
			print("t=%.1f no yeller live%s" % [_t, step_note])
		return
	if not _rider_mode:
		player.global_position = yeller.global_position + _offset
	var walk := OS.get_environment("PROBE_WALK") != "" or (OS.has_feature("web") and "walk=1" in DevFlags._web_query())
	player.velocity = Vector2(Tuning.WALK_SPEED, 0.0) if walk else Vector2.ZERO
	if _t >= _next and _t < (30.0 if _rider_mode else 15.0):
		_next += 1.0
		var contribution := yeller.contribution_at(player.global_position)
		var in_sources := false
		for pair in _main._city.excitement_sources_at(player.global_position):
			if pair[0] == yeller:
				in_sources = true
		print("  id=%d processing=%s in_tree=%s mode=%d" % [yeller.get_instance_id(), yeller.is_processing(), yeller.is_inside_tree(), yeller.process_mode])
		print("  hist=%d clock=%.2f first=%s" % [yeller._landed_history.size(), yeller._clock, str(yeller._landed_history.front()) if not yeller._landed_history.is_empty() else "-"])
		print("t=%.1f day=%d exc=%.1f in=%.2f decay=%.2f state=%d | dist=%.0f yeller contrib=%.2f in_sources=%s landed=%.2f leaving=%s finished=%s telegraph=%s age=%.1f int=%.2f | halo target=%.2f alpha=%.2f"
				% [_t, GameState.day, baby.excitement, baby.last_incoming, baby.last_decay, baby.state,
				_approach if _rider_mode else -1.0,
				contribution, in_sources, yeller.landed(), yeller.is_leaving, yeller.is_finished,
				yeller.is_telegraphing(), yeller.age, yeller.current_intensity(),
				yeller._halo._target_alpha, yeller._halo._alpha])
