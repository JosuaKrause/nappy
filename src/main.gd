extends Node2D
## Boot scene: generate the city, drop the player on the doorstep, then the HUD.
##
## The right-hand overlay is a developer readout, not part of the game's UI.

const CITY := preload("res://scenes/world/city.tscn")
const STROLLER := preload("res://scenes/player/stroller.tscn")
const HUD := preload("res://scenes/ui/hud.tscn")
const DAY_SUMMARY := preload("res://scenes/ui/day_summary.tscn")

@onready var _status: Label = $CanvasLayer/Status

var _city: City
var _player: Stroller
var _baby: Baby
var _day: DayController
var _resistance: ResistanceDirector
## Null unless the run is being traced. See src/autoload/telemetry.gd.
var _observer: TelemetryObserver
var _hud: CanvasLayer
var _summary: CanvasLayer
var _follow_camera: Camera2D
var _follow_id := ""
## Dev spawn and meter overrides apply to the opening day only; every later day starts on
## the doorstep with a fresh baby, like the game intends.
var _first_day := true
var _run_over := false
var _ending_shown := false

func _ready() -> void:
	# Esc has to work even while the summary has the tree paused, so this node keeps running
	# through a pause. Everything under it that *is* the game is put back to pausable as it is
	# created — see `_pauses_with_the_game()`. A child left on the default INHERIT would
	# inherit ALWAYS from here, which is exactly how the pause stopped working: the summary set
	# `get_tree().paused`, and the player kept walking, the crowd kept driving and the
	# resistance deadline kept running out behind the screen saying the day was over.
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.start_run(_seed_override())
	# After the run seed is settled and before anything is generated, so the log opens on the
	# seed it is a trace of. Off with `-- --no-telemetry`; on otherwise, because a trace
	# behind a flag is a trace the person playtesting has to remember to turn on.
	if not "--no-telemetry" in OS.get_cmdline_user_args():
		Telemetry.begin_run(GameState.run_seed)
	GameState.day = _day_override()

	_city = CITY.instantiate()
	add_child(_city)
	_pauses_with_the_game(_city)
	var elapsed := Time.get_ticks_msec()
	_city.build(CityGenerator.generate(GameState.run_seed))
	print("[Main] city generated in %d ms (seed %d)" % [
		Time.get_ticks_msec() - elapsed, _city.map.seed_used])

	_player = STROLLER.instantiate()
	_city.add_entity(_player)
	_player.set_camera_limits(Rect2(Vector2.ZERO, _city.map.world_size()))
	_baby = _player.get_node("Baby")

	_hud = HUD.instantiate()
	add_child(_hud)
	_summary = DAY_SUMMARY.instantiate()
	add_child(_summary)
	_summary.continued.connect(_on_summary_continued)

	_resistance = ResistanceDirector.new()
	_resistance.name = "Resistance"
	add_child(_resistance)
	_pauses_with_the_game(_resistance)
	_resistance.setup(_city, _city.map)

	_day = DayController.new()
	_day.name = "Day"
	add_child(_day)
	_pauses_with_the_game(_day)
	_day.setup(_city.map, _player)
	_day.day_finished.connect(_on_day_finished)

	# Only when a run is actually being traced: with telemetry off there is no observer in the
	# tree at all, rather than one checking a flag sixty times a second.
	if Telemetry.is_active():
		_observer = TelemetryObserver.new()
		_observer.name = "Telemetry"
		add_child(_observer)
		_pauses_with_the_game(_observer)
		_observer.setup(_city, _player, _baby, _day, _resistance)

	_start_day()

	if "--overview" in OS.get_cmdline_user_args():
		_make_overview_camera()
	_setup_follow_camera()

	var screenshot := AutoScreenshot.from_command_line()
	if screenshot:
		add_child(screenshot)

## Marks a node as part of the game rather than part of the frame around it, so the summary
## screen actually stops it.
##
## Needed only because `main` itself has to keep running through a pause for Esc, and process
## mode is inherited: without this every child of a node that must survive a pause survives it
## too. The frame — the HUD, the summary, the screenshot helper — is what is left on ALWAYS.
func _pauses_with_the_game(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_PAUSABLE

# --------------------------------------------------------------- the day loop ---

func _start_day() -> void:
	# The day is announced first, so listeners clear yesterday's state before anything is
	# placed in today — announcing it afterwards wiped the contact the director had just
	# reported, and the HUD showed nothing.
	EventBus.day_started.emit(GameState.day)

	# Before anything is placed, because placing it is what writes the day's `arc`, `roll` and
	# `contact` entries and they belong under today's header rather than yesterday's.
	Telemetry.begin_day(GameState.day, GameState.current_act(), GameState.run_seed,
			_city.map.seed_used, _day_length())

	# Events and the contact are placed before the player, so --spawn has something to find
	# and so nothing spawns on top of her.
	# The city becomes today's city before anything is placed in it: the scheduler has to
	# see the parks that are still parks, not yesterday's.
	GameState.city_state.begin_day(_city.map.block_plans, GameState.day)
	_city.start_day(GameState.city_state, GameState.day,
			GameState.day_rng(GameState.day, "closures"))
	_city.events.start_day(GameState.day, GameState.day_rng(), GameState.consumed_one_shots)
	_city.crowd.start_day(GameState.day, GameState.day_rng(GameState.day, "crowd"))
	_city.set_act(GameState.current_act())
	_resistance.start_day(GameState.day, GameState.day_rng(GameState.day, "resistance"),
			_day_length())
	_player.reset_at(_spawn_position() if _first_day else _city.map.doorstep_world_position())
	_baby.reset()
	_day.start(_day_length())

	# After the day is running, not before: the override can put the baby straight to
	# sleep, and start() would have reset the phase that announcement just set.
	if _first_day:
		_apply_meter_override()
	_first_day = false

	print("[Main] day %d (act %d): %d events, %d crowd, %.0fs | calm: %s | closed: %s" % [
		GameState.day, GameState.current_act(), _city.events.active_count(),
		_city.crowd.agent_count(), _day.time_total,
		_calm_summary(), _closure_summary()])

	# The shape of the day, written down last because it is only true once everything has been
	# placed. Three lines rather than one: what is shut, where the calm is, and what is out —
	# the three things a reader needs before any of the entries below them mean anything.
	Telemetry.note("plan", "closed: %s" % _closure_summary())
	Telemetry.note("plan", "calm: %s" % _calm_summary())
	Telemetry.note("plan", "events: %s" % _event_summary())
	if _observer:
		_observer.start_day()

## What calm ground today has, by kind. Cheap, and the thing most worth knowing about a day
## now that a day can only be won on calm ground.
func _calm_summary() -> String:
	var counts := {}
	for block in _city.map.calm_blocks:
		var name: String = GameEnums.BlockPurpose.keys()[
			GameState.city_state.purpose_of(_city.map.block_plans, block)].to_lower()
		counts[name] = counts.get(name, 0) + 1
	var parts: Array[String] = []
	for name: String in counts:
		parts.append("%d %s" % [counts[name], name])
	parts.sort()
	return ", ".join(parts) if not parts.is_empty() else "none"

## Which streets are shut today and what shut them. Worth printing rather than counting,
## because "the route was awful today" and "the closure landed on the one street that
## mattered" look identical from a count.
func _closure_summary() -> String:
	var parts: Array[String] = []
	for closure in _city.closures():
		parts.append("%s %s%s" % [
			RoadClosure.display_name(closure.kind).to_lower(),
			"h" if closure.segment.horizontal else "v",
			TelemetryLog.tile(closure.segment.a)])
	return ", ".join(parts) if not parts.is_empty() else "none"

## Today's events by id. Counted rather than listed one per line: which of eighteen kinds are
## out is what makes a day, and where each instance stands is only interesting for the ones
## the player actually walked into — which the `near` entries cover, at the moment it matters.
func _event_summary() -> String:
	var counts := {}
	for instance in _city.events.instances():
		counts[instance.def.id] = int(counts.get(instance.def.id, 0)) + 1
	var parts: Array[String] = []
	for id: String in counts:
		parts.append("%s x%d" % [id, counts[id]] if counts[id] > 1 else id)
	parts.sort()
	return ", ".join(parts) if not parts.is_empty() else "none"

func _on_day_finished(result: GameEnums.DayResult) -> void:
	var finished_day := GameState.day
	# Before the calendar moves, so the outcome is written above the nerve it cost — and
	# before `end_day()` stops the clock, so it is timestamped where it happened.
	if _observer:
		_observer.day_finished(result)
	Telemetry.end_day()
	_run_over = not GameState.finish_day(result)
	_summary.show_day(finished_day, result, _day.failure_reason, GameState.nerves)

func _on_summary_continued() -> void:
	if not _run_over:
		_summary.dismiss()
		_start_day()
		return
	if not _ending_shown:
		_ending_shown = true
		_summary.show_ending(GameState.ending)

func _process(_delta: float) -> void:
	_update_follow_camera()
	if not _player or not _baby:
		return
	_city.set_daylight(_day.fraction_remaining())
	_hud.set_home_guidance(_day.phase == GameEnums.DayPhase.RETURNING,
			_city.map.home_world_position())
	var tile := _city.map.world_to_tile(_player.global_position)
	_status.text = "\n".join([
		"seed  %d   day %d" % [GameState.run_seed, GameState.day],
		"phase %s  %.0fs left" % [
			GameEnums.DayPhase.keys()[_day.phase].to_lower(), _day.time_remaining],
		"tile  %d, %d  (%s)" % [tile.x, tile.y, _tile_name(_city.map.tile_at(tile))],
		"calm  %s    alley  %s" % [
			"yes" if _city.is_calm_zone(_player.global_position) else "no",
			"yes" if _city.is_alley(_player.global_position) else "no"],
		"",
		"speed       %6.1f" % _player.current_speed(),
		"run excess  %6.2f" % _player.run_excess_ratio(),
		"",
		"events      %6d" % _city.events.active_count(),
		"crowd       %6d" % _city.crowd.agent_count(),
		"fps         %6d" % Engine.get_frames_per_second(),
		"nearest     %s" % _nearest_event_text(),
		"",
		"incoming    %6.2f /s" % _baby.last_incoming,
		"decay       %6.2f /s" % _baby.last_decay,
		"net         %6.2f /s" % (_baby.last_incoming - _baby.last_decay),
		"",
		"arrows/WASD walk",
		"shift       run",
		"esc         quit",
	])

## The closest live event and what it is currently doing — the readout that says whether a
## telegraph actually ended when it should have.
func _nearest_event_text() -> String:
	var nearest: EventInstance = null
	var best := INF
	for instance in _city.events.instances():
		var distance := instance.global_position.distance_to(_player.global_position)
		if distance < best:
			best = distance
			nearest = instance
	if not nearest:
		return "none"
	return "%s %s age=%.1f/%.1f %.0fpx i=%.1f" % [
		nearest.def.id,
		"telegraph" if nearest.is_telegraphing() else "active",
		nearest.age, nearest.def.telegraph_time,
		best, nearest.current_intensity()]

func _tile_name(type: GameEnums.TileType) -> String:
	return GameEnums.TileType.keys()[type].to_lower()

## Dev flag: `-- --follow <event id>` parks a camera on an event wherever it is. Needed for
## anything that does not exist when the day starts — a mobile event mid-route, or the fire
## a fire engine leaves behind when it stops.
func _setup_follow_camera() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--follow")
	if index == -1 or index + 1 >= args.size():
		return
	_follow_id = args[index + 1]
	_follow_camera = Camera2D.new()
	add_child(_follow_camera)
	_follow_camera.make_current()

func _update_follow_camera() -> void:
	if not _follow_camera:
		return
	for instance in _city.events.instances():
		if instance.def.id == _follow_id:
			_follow_camera.position = instance.global_position
			return

## Dev flag: `-- --day-length N` compresses the day, so dusk and the timeout loss can be
## looked at without sitting through the whole three minutes.
func _day_length() -> float:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--day-length")
	if index == -1 or index + 1 >= args.size():
		return Tuning.day_length(GameState.day)
	return maxf(1.0, float(args[index + 1]))

## Dev flag: `-- --day N` starts on a later day, so an act's events can be looked at
## without playing up to them.
func _day_override() -> int:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--day")
	if index == -1 or index + 1 >= args.size():
		return 1
	return clampi(int(args[index + 1]), 1, Tuning.RUN_LENGTH_DAYS)

## Dev flag: `-- --spawn park|alley|square|arterial|closure|event` drops the player onto a
## tile type or next to something live, so the WorldContext answers can be checked without
## walking across the city to find one.
func _spawn_position() -> Vector2:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--spawn")
	if index == -1 or index + 1 >= args.size():
		return _city.map.doorstep_world_position()

	# `event` takes the first non-ambient event; `event:<id>` targets a specific one.
	if args[index + 1].begins_with("event"):
		return _first_event_position(args[index + 1].get_slice(":", 1))
	# The busiest pavement in the city, for looking at the crowd's noise floor without
	# walking there. The arterial is where the floor is highest, so it is where the
	# question "can a day be won on an ordinary street" is actually answered.
	if args[index + 1] == "arterial":
		return _nearest_walkable(CrowdLanes.arterial_pavement(_city.map))
	# A closed street, from the junction outside its barrier — the place the closure is
	# supposed to be readable from, which is the thing worth looking at.
	# `closure:<n>` picks one of the day's closures, since only one of them is a street
	# running the way you wanted to look at.
	if args[index + 1].begins_with("closure"):
		var closures := _city.closures()
		if closures.is_empty():
			push_warning("no streets are closed on day %d" % GameState.day)
			return _city.map.home_world_position()
		var which := clampi(int(args[index + 1].get_slice(":", 1)), 0, closures.size() - 1)
		var mouth: Vector2 = closures[which].mouth_centres(_city.map)[0]
		var junction := closures[which].cause_centre(_city.map)
		return _nearest_walkable(mouth + (mouth - junction).normalized() * 64.0)
	if args[index + 1] == "contact":
		var contact := _resistance.contact_position()
		if contact == Vector2.INF:
			push_warning("no resistance contact on day %d" % GameState.day)
			return _city.map.home_world_position()
		# Off to one side, so the chalk mark is not hidden under the pram.
		return contact + Vector2(70.0, 30.0)

	var wanted: int = {
		"park": GameEnums.TileType.PARK,
		"alley": GameEnums.TileType.ALLEY,
		"square": GameEnums.TileType.SQUARE,
		"playground": GameEnums.TileType.PLAYGROUND,
	}.get(args[index + 1], -1)
	if wanted == -1:
		push_warning("unknown --spawn target '%s'" % args[index + 1])
		return _city.map.home_world_position()

	for y in _city.map.size.y:
		for x in _city.map.size.x:
			if _city.map.tile_at(Vector2i(x, y)) == wanted:
				return _city.map.tile_to_world(Vector2i(x, y))
	push_warning("no %s tile in this city" % args[index + 1])
	return _city.map.home_world_position()

## Just outside a live event, on the nearest walkable tile — an offset straight down its
## radius lands inside a block as often as not.
func _first_event_position(wanted_id: String = "") -> Vector2:
	for instance in _city.events.instances():
		if wanted_id != "" and wanted_id != "event":
			if instance.def.id != wanted_id:
				continue
		elif instance.def.kind == GameEnums.EventKind.AMBIENT:
			continue
		var wanted := instance.global_position \
				+ Vector2(0.0, instance.def.outer_radius * 0.6)
		return _nearest_walkable(wanted)
	push_warning("no non-ambient events planned today")
	return _city.map.home_world_position()

func _nearest_walkable(near: Vector2) -> Vector2:
	var start := _city.map.world_to_tile(near)
	for radius in 12:
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var tile := start + Vector2i(dx, dy)
				if _city.map.is_walkable(tile):
					return _city.map.tile_to_world(tile)
	return _city.map.home_world_position()

## Dev flag: `-- --overview` frames the whole city at once, so a generation bug that only
## shows up at map scale (a walled-off quarter, parks bunched together) is visible.
func _make_overview_camera() -> void:
	var camera := Camera2D.new()
	var extent := _city.map.world_size()
	var viewport := get_viewport_rect().size
	camera.position = extent * 0.5
	camera.zoom = Vector2.ONE * minf(viewport.x / extent.x, viewport.y / extent.y)
	add_child(camera)
	camera.make_current()

## Dev flag: `-- --seed N` regenerates a specific city, so a layout bug can be looked at
## twice. Without it every run gets a fresh city, which is the game's actual behaviour.
func _seed_override() -> int:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--seed")
	if index == -1 or index + 1 >= args.size():
		return 0
	return int(args[index + 1])

## Dev flag: `-- --meters <sleepiness> <excitement>` seeds the bars, so a UI state can be
## screenshotted without having to play all the way to it. Applied before the HUD is
## created, which reads the starting values.
func _apply_meter_override() -> void:
	if not _baby:
		return
	var args := OS.get_cmdline_user_args()
	var index := args.find("--meters")
	if index == -1 or index + 2 >= args.size():
		return
	_baby.sleepiness = clampf(float(args[index + 1]), 0.0, Tuning.METER_MAX)
	_baby.excitement = clampf(float(args[index + 2]), 0.0, Tuning.METER_MAX)
	# A full meter means "show me the walk home". Left to settle on its own it never would:
	# a stationary player drains sleepiness faster than the state check can fire.
	if _baby.sleepiness >= Tuning.METER_MAX:
		_baby.force_sleep()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Telemetry.end_run()
		get_tree().quit()

## Closing the window is the other way a run ends, and an abandoned run is worth reading —
## every line is already on disk, so this only closes the handle tidily.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Telemetry.end_run()
