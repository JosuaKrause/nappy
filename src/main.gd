extends Node2D
## Boot scene: generate the city, drop the player on the doorstep, then the HUD.
##
## The right-hand overlay is a developer readout, not part of the game's UI, and it is gated by
## `_debug` (`DevFlags.enabled()`) the same as every other piece of developer furniture: outside
## a debug build the string is never assembled, not merely hidden behind an invisible label.

const CITY := preload("res://scenes/world/city.tscn")
const STROLLER := preload("res://scenes/player/stroller.tscn")
const HUD := preload("res://scenes/ui/hud.tscn")
const DAY_SUMMARY := preload("res://scenes/ui/day_summary.tscn")
const PAUSE_SCREEN := preload("res://scenes/ui/pause_screen.tscn")
const TITLE_SCREEN := preload("res://scenes/ui/title_screen.tscn")

@onready var _status: Label = $CanvasLayer/Status

## Whether the developer readout runs at all. Read once from `DevFlags.enabled()` into a member
## — rather than asked of `OS.is_debug_build()` inside `_process()` — so a test can set it and
## check the release shape, the way `hud._debug` already does for the HUD's own gate.
var _debug := DevFlags.enabled()

var _city: City
var _player: Stroller
var _baby: Baby
var _day: DayController
var _resistance: ResistanceDirector
## Null unless the run is being traced. See src/autoload/telemetry.gd.
var _observer: TelemetryObserver
var _hud: CanvasLayer
## Kept because the telemetry observer asks it what she is being warned about; the layer around it
## is kept only so the title screen can take it off the street.
var _edge: DangerEdge
var _edge_layer: CanvasLayer
var _summary: CanvasLayer
var _pause: PauseScreen
var _title: TitleScreen
var _follow_camera: Camera2D
var _follow_id := ""
## Dev spawn and meter overrides apply to the opening day only; every later day starts on
## the doorstep with a fresh baby, like the game intends.
var _first_day := true
var _run_over := false
var _ending_shown := false
## Whether the title screen is up, with the city running behind it and nobody in it.
var _in_the_title := false

func _ready() -> void:
	# Esc has to work even while the summary has the tree paused, so this node keeps running
	# through a pause. Everything under it that *is* the game is put back to pausable as it is
	# created — see `_pauses_with_the_game()`. A child left on the default INHERIT inherits
	# ALWAYS from here, and then the pause does nothing to it: the summary sets
	# `get_tree().paused` while the player walks, the crowd drives and the resistance deadline
	# runs out behind a screen saying the day is over.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Starts in the shape it should have on this build rather than trusting the scene file's own
	# default (`true`): every later flip of it is relative to whichever screen is up, and a boot
	# path that never reaches one of them should still open with the right answer.
	_status.visible = _debug
	GameState.start_run(DevFlags.seed_override())
	# After the run seed is settled and before anything is generated, so the log opens on the
	# seed it is a trace of. Off with `-- --no-telemetry`; on otherwise, because a trace
	# behind a flag is a trace the person playtesting has to remember to turn on. This is a
	# player-facing opt-out rather than developer furniture, so it is not gated by `DevFlags`.
	if not "--no-telemetry" in OS.get_cmdline_user_args():
		Telemetry.begin_run(GameState.run_seed, _somebody_is_playing())
	GameState.day = DevFlags.day_override()

	_city = CITY.instantiate()
	add_child(_city)
	_pauses_with_the_game(_city)
	var elapsed := Time.get_ticks_msec()
	_city.build(CityGenerator.generate(GameState.run_seed))
	print("[Main] city generated in %d ms (seed %d)" % [
		Time.get_ticks_msec() - elapsed, _city.map.seed_used])

	_player = STROLLER.instantiate()
	_city.add_entity(_player)
	_player.set_camera_limits(_city.camera_bounds())
	_baby = _player.get_node("Baby")

	_hud = HUD.instantiate()
	add_child(_hud)
	_add_danger_edge()
	_summary = DAY_SUMMARY.instantiate()
	add_child(_summary)
	_summary.continued.connect(_on_summary_continued)

	# Deliberately not `_pauses_with_the_game`: a pause screen that pauses with the game cannot
	# unpause it. It inherits ALWAYS from this node, which is what it wants.
	_pause = PAUSE_SCREEN.instantiate()
	add_child(_pause)
	_pause.quit_requested.connect(_quit)
	_pause.restart_requested.connect(_restart_run)

	# Same reasoning, one screen further out. See `TitleScreen`.
	_title = TITLE_SCREEN.instantiate()
	add_child(_title)
	_title.start_requested.connect(_on_title_start)
	_title.quit_requested.connect(_quit)

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
		_observer.setup(_city, _player, _baby, _day, _resistance, _edge)

	_start_day()

	if DevFlags.overview_requested():
		_make_overview_camera()
	_setup_follow_camera()

	var screenshot := AutoScreenshot.from_command_line()
	if screenshot:
		add_child(screenshot)

	# **Except under a rig.** A screenshot tool that opened onto the title screen would photograph
	# the title screen, which is every `tools/shot.sh` recipe quietly answering the wrong
	# question, and `--press` and `--walk` would hold keys against a game that has not begun.
	# A rig is driving, so it starts the day the way the player would. `--title` is how the screen
	# itself gets photographed.
	# Through `DevFlags`, which answers with nothing outside a debug build, so a release export
	# cannot be told to skip its own front door: `--no-title` is a rig's convenience like every
	# other flag here, and the title screen is the game's first screen.
	var args := DevFlags.active_args()
	if _show_an_ending_for_a_rig():
		return
	if (screenshot or "--no-title" in args) and not "--title" in args:
		return
	_open_the_title()

## Dev flag: `-- --ending bad|neutral|good` puts the last screen of a run on screen at boot.
##
## It exists for the same reason `--press` does: nothing in the suite or in a screenshot reaches
## this screen on its own. An ending is at the far end of fourteen days or five spent nerves, so
## looking at one otherwise means playing a run out — which is the `verify` skill's *"where a cue
## cannot be triggered on demand, relax its condition, look, and put it back"*, except that a flag
## is the honest version of relaxing it and does not have to be put back.
##
## It shows the screen and stops there: the day behind it is running, exactly as it would be under
## a real ending, and `space` restarts the run like any other finished one. `DevFlags` answers ""
## outside a debug build, so this can never fire in an exported release.
func _show_an_ending_for_a_rig() -> bool:
	var wanted_arg := DevFlags.ending_override()
	if wanted_arg == "":
		return false
	var wanted := {
		"bad": GameEnums.Ending.BAD,
		"neutral": GameEnums.Ending.NEUTRAL,
		"good": GameEnums.Ending.GOOD,
	}
	if not wanted.has(wanted_arg):
		push_warning("unknown --ending '%s'" % wanted_arg)
		return false
	_run_over = true
	_ending_shown = true
	_summary.show_ending(wanted[wanted_arg] as GameEnums.Ending)
	return true

# --------------------------------------------------------------- the title ---

## Puts the game behind the title screen and keeps the *city* running while it is there, so the
## screen is the home and the street in front of it with the act I events playing out on it.
##
## The day is planned and built either way, so what is behind the screen is a real first morning
## rather than a menu with nothing under it — and `space` then starts a day that already exists.
## What has to be split apart is **the city and the day**, which the pause deliberately does not
## distinguish:
##
## - `get_tree().paused` stops everything `_pauses_with_the_game()` reaches — the clock, the
##   resistance deadline, the telemetry observer. Nothing about the run may advance behind a screen
##   the player has not dismissed.
## - `_city` is put back to `ALWAYS`, so the traffic drives and the events play out. It is the one
##   thing on the pausable list that is scenery as well as gameplay.
## - `_player` is pinned back to `PAUSABLE` — she is a child of the city and would otherwise inherit
##   the exemption, and walk on behind the screen — and then **stands aside**, which takes
##   her out of the `player` group and with it every way the world can touch her. See
##   `Stroller.stand_aside()`.
##
## The HUD, the screen-edge badge and the developer readout all come off, because every one of them
## is a statement about a player who is not there.
func _open_the_title() -> void:
	_in_the_title = true
	get_tree().paused = true
	_city.process_mode = Node.PROCESS_MODE_ALWAYS
	_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	_player.stand_aside()
	_hud.visible = false
	_edge_layer.visible = false
	_status.visible = false
	_title.open(_ending_shown)

## The player has pressed space: hand the city back to the day it belongs to.
func _on_title_start() -> void:
	_in_the_title = false
	_title.close()
	_player.step_back_in()
	_pauses_with_the_game(_city)
	_hud.visible = true
	_edge_layer.visible = true
	# Not an unconditional `true`: this is the one place the readout was coming back regardless
	# of build, since `_open_the_title()` always turns it off and this was the only place that
	# turned it back on.
	_status.visible = _debug
	get_tree().paused = false

## The screen-edge half of the danger vocabulary, in its own layer.
##
## Built here rather than inside the HUD scene because it has to ask the world where things are
## every frame, and the HUD's rule is that it listens to `EventBus` and holds no reference to
## the world. Bending that for one indicator would cost more than the node does.
func _add_danger_edge() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DangerEdge"
	_edge_layer = layer
	_edge = DangerEdge.new()
	_edge.name = "Edge"
	_edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge.setup(_city.events, _player)
	layer.add_child(_edge)
	add_child(layer)

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
	# The day is planned around the doorstep first, because `--spawn event` needs a plan to
	# find an event in. The plan is the whole day and the *world* is only what is within
	# reach, so where she actually starts decides what exists on the first frame —
	# which is why the crowd is populated after the spawn position is settled rather than
	# before it, and why the events are streamed a second time once it is known.
	var doorstep := _city.map.doorstep_world_position()
	_city.events.start_day(GameState.day, GameState.day_rng(), GameState.consumed_one_shots,
			doorstep)
	var start_at := _spawn_position() if _first_day else doorstep
	_city.events.stream_around(start_at)
	_city.crowd.start_day(GameState.day, GameState.day_rng(GameState.day, "crowd"), start_at)
	_city.set_act(GameState.current_act())
	_resistance.start_day(GameState.day, GameState.day_rng(GameState.day, "resistance"),
			_day_length())
	_player.reset_at(start_at)
	_baby.reset()
	_day.start(_day_length())

	# After the day is running, not before: the override can put the baby straight to
	# sleep, and start() would have reset the phase that announcement just set.
	if _first_day:
		_apply_meter_override()
	_first_day = false

	print("[Main] day %d (act %d): %d events (%d live, %d ahead), %d crowd, %.0fs "
			% [GameState.day, GameState.current_act(), _city.events.planned_count(),
			_city.events.active_count(), _city.events.owed_ahead(),
			_city.crowd.agent_count(), _day.time_total]
			+ "| calm: %s | closed: %s" % [_calm_summary(), _closure_summary()])

	# The shape of the day, written down last because it is only true once everything has been
	# placed. Three lines rather than one: what is shut, where the calm is, and what is out —
	# the three things a reader needs before any of the entries below them mean anything.
	Telemetry.note("plan", "closed: %s" % _closure_summary())
	Telemetry.note("plan", "calm: %s" % _calm_summary())
	Telemetry.note("plan", "events: %s" % _event_summary())
	# And the same three lines as a picture. After them, because it is the same information and a
	# reader who has the log open should meet the words first; per day, because the closures and
	# what each block *is* both moved above. See `TelemetryMap`.
	Telemetry.write_map(_city.map, GameState.day, _city.closures(), _city.route_tree(),
			_city.events.plans())
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

## Today's events by id. Counted rather than listed one per line: which of the catalogue's kinds
## are out is what makes a day, and where each instance stands is only interesting for the ones
## the player actually walked into — which the `near` entries cover, at the moment it matters.
##
## The *plan*, not what is live. What is live is a fact about where the player is standing this
## frame, and the question this line answers is what the day contains.
func _event_summary() -> String:
	var counts := {}
	for plan in _city.events.plans():
		counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
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
	# The same picture again, now that the day has been walked: the marks she reached are opaque and
	# the rest are not, which is the one thing the dawn map cannot say. Before `end_day()`, so it
	# belongs to the day it is of. See `Telemetry.write_map`.
	Telemetry.write_map(_city.map, finished_day, _city.closures(), _city.route_tree(),
			_city.events.plans(), true)
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
		return
	# A run that is over goes back to where a run begins, which is the title screen: an ending is
	# not a dead end the player has to quit out of.
	_restart_run()

## Back to the title, with everything about the run thrown away.
##
## A scene reload rather than a `GameState.start_run()` and a rebuild, because the run is not the
## only thing that would have to be reset: the city, the crowd, the streamed events, the resistance
## deadline, the telemetry observer and every scar are all state hanging off nodes built in
## `_ready`. Re-entering `_ready` resets all of it by construction, and *"a fresh run gets a fresh
## city"* is what the player expects from a restart anyway.
##
## Deferred because it is called from inside input handling on a screen that is about to be freed,
## and the tree is unpaused first: `reload_current_scene` builds the new scene into the same tree,
## and a paused one would open the title screen over a game that could never start.
func _restart_run() -> void:
	Telemetry.end_run()
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")

func _process(_delta: float) -> void:
	_update_follow_camera()
	if not _player or not _baby:
		return
	if _in_the_title:
		# `EventManager` streams around the player and there is no player, so the street outside the
		# home would play out whatever was standing on it at dawn and then quietly empty. One call a
		# frame keeps it stocked. Only the *streaming* is stood in for: what the director owes ahead
		# of her is not placed, because it is placed in front of somebody walking somewhere.
		_city.events.stream_around(_player.global_position)
		return
	_city.set_daylight(_day.fraction_remaining())
	_hud.set_home_guidance(_day.phase == GameEnums.DayPhase.RETURNING,
			_city.map.home_world_position())
	# The developer readout, gated rather than merely hidden: it is a seed, a frame rate and a
	# meter breakdown, which a released build has no business assembling every frame even behind
	# a label nobody can see — and `_nearest_event_text()` below is a scan of every live event.
	if not _debug:
		return
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
		"events      %6d live of %d" % [
			_city.events.active_count(), _city.events.planned_count()],
		"ahead owed  %6d" % _city.events.owed_ahead(),
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
		"esc         pause  (r restart, q quit)",
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

## Whether a **person** is at the controls, which is what decides if this run's log is a playtest.
##
## Two ways it is not, and they are different in kind rather than in degree:
##
## - **There is no window.** `check.sh` and the test suite boot the game headless; nobody could be
##   playing whatever else is true.
## - **Something else is holding the keys.** `--screenshot` exists to take a picture and quit, and
##   `--walk`, `--flee` and `--press` are rigs that supply the input themselves. A run driven by one
##   of them can be long, busy and completely unplayed, which is exactly the case the size heuristic
##   in `tools/telemetry.sh` could never catch.
##
## **`--seed`, `--day`, `--spawn`, `--overview` and the rest are *not* here**, and that is the line:
## they change what she is looking at, not who is steering. A playtest of act III started with
## `--day 9` is a playtest.
##
## Reads `DevFlags.active_args()` rather than the command line directly, so a release export —
## where none of the four rig flags below can do anything anyway — never misreads an ordinary
## player for one.
func _somebody_is_playing() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	var args := DevFlags.active_args()
	for rig in ["--screenshot", "--walk", "--flee", "--press"]:
		if rig in args:
			return false
	return true

## Dev flag: `-- --follow <event id>` parks a camera on an event wherever it is. Needed for
## anything that does not exist when the day starts — a mobile event mid-route, or the fire
## a fire engine leaves behind when it stops.
func _setup_follow_camera() -> void:
	_follow_id = DevFlags.follow_target()
	if _follow_id == "":
		return
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
	var override := DevFlags.day_length_override()
	return override if override > 0.0 else Tuning.day_length(GameState.day)

## Dev flag: `-- --spawn park|alley|square|arterial|closure|event` drops the player onto a
## tile type or next to something live, so the WorldContext answers can be checked without
## walking across the city to find one.
func _spawn_position() -> Vector2:
	var target := DevFlags.spawn_target()
	if target == "":
		return _city.map.doorstep_world_position()

	# `event` takes the first non-ambient event; `event:<id>` targets a specific one.
	if target.begins_with("event"):
		return _first_event_position(target.get_slice(":", 1))
	# The busiest pavement in the city, for looking at the crowd's noise floor without
	# walking there. The arterial is where the floor is highest, so it is where the
	# question "can a day be won on an ordinary street" is actually answered.
	if target == "arterial":
		return _nearest_walkable(CrowdLanes.arterial_pavement(_city.map))
	# A closed street, from the junction outside its barrier — the place the closure is
	# supposed to be readable from, which is the thing worth looking at.
	# `closure:<n>` picks one of the day's closures, since only one of them is a street
	# running the way you wanted to look at.
	if target.begins_with("closure"):
		var closures := _city.closures()
		if closures.is_empty():
			push_warning("no streets are closed on day %d" % GameState.day)
			return _city.map.home_world_position()
		var which := clampi(int(target.get_slice(":", 1)), 0, closures.size() - 1)
		var mouth: Vector2 = closures[which].mouth_centres(_city.map)[0]
		var junction := closures[which].cause_centre(_city.map)
		return _nearest_walkable(mouth + (mouth - junction).normalized() * 64.0)
	# The north-west corner of a multi-block calm zone, a couple of tiles outside it, which puts
	# both of the things a zone has to get right in one frame: the T-junction where the absorbed
	# street stops, and the calm behind it.
	#
	# `zone:<n>` picks which one, the way `closure:<n>` does, and it is not a convenience. A zone
	# has a **shape** and the square is always placed first, so `keys()[0]` is always the square
	# and no other shape can be looked at without the index.
	if target.begins_with("zone"):
		if _city.map.zone_rects.is_empty():
			push_warning("this city has no multi-block calm zone")
			return _city.map.home_world_position()
		var keys := _city.map.zone_rects.keys()
		var which := clampi(int(target.get_slice(":", 1)), 0, keys.size() - 1)
		var anchor: Vector2i = keys[which]
		var corner := CityMap.blocks_tile_rect(_city.map.zone_rects[anchor]).position
		return _nearest_walkable(_city.map.tile_to_world(corner - Vector2i.ONE * 2))
	# A big building, stood on the street running along the joined side of it, level with the
	# street it was built over. The whole claim of a landmark is that it reads as **one mass**
	# rather than as two blocks with the road missing between them, and this flag is the only way
	# to point a camera at one.
	if target == "landmark":
		if _city.map.big_buildings.is_empty():
			push_warning("this city has no big building")
			return _city.map.home_world_position()
		var pair: Rect2i = _city.map.big_buildings[0]
		var mass := CityMap.blocks_tile_rect(pair)
		# Off the **long** side, which is the one the joined seam runs the width of: a mass two
		# blocks wide is looked at from the north, a mass two blocks deep from the west. Two tiles
		# out and not three, because a corridor is `sidewalk | road | sidewalk` and three tiles off
		# a frontage is the carriageway — `_nearest_walkable` will happily leave her standing on it,
		# and a shot taken from there is a shot of the day ending.
		# And a little off the middle of that side, because the middle of the mass is where the
		# built-over street was, so the tile facing it across the corridor is a junction — which is
		# somewhere a camera may stand and a pram should not.
		var beside := Vector2i(mass.get_center().x - Tuning.STREET_WIDTH, mass.position.y - 2) \
				if pair.size.x == 2 \
				else Vector2i(mass.position.x - 2, mass.get_center().y - Tuning.STREET_WIDTH)
		return _nearest_walkable(_city.map.tile_to_world(beside))
	# A signalled junction on the spine, stood a little back down the side street, so that the
	# main road, its lights and one of its zebras are all in the same frame. The lights
	# are the only cue in the game whose whole content is *when*, so they cannot be judged from a
	# still of one — take several seconds apart, or use `--walk` and watch the cycle.
	if target == "signal":
		var spine := _city.map.main_road
		var down := clampi(Tuning.CITY_BLOCKS.y / 2, 1, Tuning.CITY_BLOCKS.y - 1)
		# On the side street's own pavement, a couple of tiles east of the junction: the block
		# east of corridor `spine` is block `spine`, and offset 1 of a corridor is footway.
		var corner := Vector2i(CityMap.block_rect(Vector2i(spine, 0)).position.x + 2,
				down * CityMap.period() + 1)
		return _nearest_walkable(_city.map.tile_to_world(corner))
	# The mouth of the tunnel the main road leaves by, from a few tiles down the spine. `edge:s`
	# is the bridge at the other end and `edge:e` / `edge:w` the road simply running out.
	if target.begins_with("edge"):
		var side := target.get_slice(":", 1)
		var spine_x := _city.map.main_road * CityMap.period() + Tuning.STREET_WIDTH / 2
		var spine_y := CrowdLanes.arterial_index(Tuning.CITY_BLOCKS.y) * CityMap.period() \
				+ Tuning.STREET_WIDTH / 2
		# Beside the carriageway, not on it: the exits are lethal, which is the point of them.
		var at := Vector2i(spine_x - 2, 1)
		match side:
			"s": at = Vector2i(spine_x - 2, _city.map.size.y - 2)
			"e": at = Vector2i(_city.map.size.x - 2, spine_y - 2)
			"w": at = Vector2i(1, spine_y - 2)
		return _nearest_walkable(_city.map.tile_to_world(at))
	# The middle of a pedestrianised street, which is the other end of the same trade: paving
	# frontage to frontage, no kerb, no asphalt and nothing on it that can kill you.
	if target == "precinct":
		if _city.map.precinct_spans.is_empty():
			push_warning("this city has no precinct")
			return _city.map.home_world_position()
		var span: Vector4i = _city.map.precinct_spans[0]
		var across := span.y * CityMap.period() + Tuning.STREET_WIDTH / 2
		var along := (span.z + span.w) / 2 * CityMap.period() + Tuning.STREET_WIDTH
		return _nearest_walkable(_city.map.tile_to_world(
				Vector2i(across, along) if span.x == 1 else Vector2i(along, across)))
	# A corner of the map, stood a couple of tiles inside it, so that two of the border's four
	# bands and the join between them are in the same frame — the seam is where the mountain and
	# the sea have to go on being themselves rather than turning diagonal. `corner:nw` is the
	# default and `ne`, `sw`, `se` are the other three.
	#
	# It exists for the same reason `landmark` does: it is the only way to point a camera at the
	# place where two bands meet, and nothing in the suite looks there.
	if target.begins_with("corner"):
		var which := target.get_slice(":", 1)
		# The outermost pavement and not the outermost tile: the corridor is `sidewalk | road |
		# sidewalk`, so anything past `SIDEWALK_WIDTH` is the carriageway of the boundary street
		# and `_nearest_walkable` will happily leave her standing on it — a shot taken from there
		# is a shot of the day ending, which is the trap the `landmark` target has too.
		var near := Tuning.SIDEWALK_WIDTH - 1
		var far := _city.map.size - Vector2i.ONE * Tuning.SIDEWALK_WIDTH
		var at := Vector2i(near, near)
		match which:
			"ne": at = Vector2i(far.x, near)
			"sw": at = Vector2i(near, far.y)
			"se": at = far
		return _nearest_walkable(_city.map.tile_to_world(at))
	if target == "contact":
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
	}.get(target, -1)
	if wanted == -1:
		push_warning("unknown --spawn target '%s'" % target)
		return _city.map.home_world_position()

	for y in _city.map.size.y:
		for x in _city.map.size.x:
			if _city.map.tile_at(Vector2i(x, y)) == wanted:
				return _city.map.tile_to_world(Vector2i(x, y))
	push_warning("no %s tile in this city" % target)
	return _city.map.home_world_position()

## Just outside a planned event, on the nearest walkable tile — an offset straight down its
## radius lands inside a block as often as not.
##
## Reads the day's *plan* rather than what is live: nothing is live until the player is near it,
## so the whole point of this flag is to go and stand where one is going to be.
func _first_event_position(wanted_id: String = "") -> Vector2:
	for plan in _city.events.plans():
		if not plan.is_placed():
			continue
		if wanted_id != "" and wanted_id != "event":
			if plan.def.id != wanted_id:
				continue
		elif plan.def.kind == GameEnums.EventKind.AMBIENT:
			continue
		return _nearest_walkable(plan.position + Vector2(0.0, plan.def.outer_radius * 0.6))
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
	# The frontages outside the map are in frame too: the ring is what makes the boundary a
	# street with two sides, and an overview that framed the walkable tiles alone would be a
	# picture of a grid stopping at a wall rather than of a city.
	var bounds := _city.camera_bounds()
	var viewport := get_viewport_rect().size
	camera.position = bounds.get_center()
	camera.zoom = Vector2.ONE * minf(viewport.x / bounds.size.x, viewport.y / bounds.size.y)
	add_child(camera)
	camera.make_current()

## Dev flag: `-- --meters <sleepiness> <excitement>` seeds the bars, so a UI state can be
## screenshotted without having to play all the way to it. Applied before the HUD is
## created, which reads the starting values.
func _apply_meter_override() -> void:
	if not _baby:
		return
	var override := DevFlags.meters_override()
	if override.x < 0.0:
		return
	_baby.sleepiness = override.x
	_baby.excitement = override.y
	# A full meter means "show me the walk home". Left to settle on its own it never would:
	# a stationary player drains sleepiness faster than the state check can fire.
	if _baby.sleepiness >= Tuning.METER_MAX:
		_baby.force_sleep()

## `Esc` opens the pause. Quitting is a key one step further in: the pause screen owns `Q`.
##
## **Never guard this on a `CanvasLayer`'s `visible`.** `_summary` is a `CanvasLayer`, and its
## `visible` is `true` from the moment it is added to the tree — what the summary hides and shows is
## the `Control` *inside* it, which is what `is_showing()` answers. A guard on the layer is true on
## every frame of every day, so the pause screen never opens at all, and both a green suite and a
## screenshot pass it: nothing in either presses a key. `--press` is how a rig can.
##
## It opens **over** the summary too. Two things fighting over `get_tree().paused` is how a pause
## stops meaning anything, which is an argument for care rather than for refusing — `PauseScreen`
## puts back the paused state it found rather than setting `false`, so the two compose. Somebody who
## has just lost a day and wants out of the game should not have to find the one screen where the
## key works.
## It does **not** open over the title screen, which is the one screen with nothing behind it to
## pause: the game has not started, `Esc` would stop a stopped tree, and the way out of the title is
## the two keys it already offers. See `TitleScreen`.
func _unhandled_input(event: InputEvent) -> void:
	if DevFlags.enabled() and event.is_action_pressed("snapshot"):
		get_viewport().set_input_as_handled()
		_snapshot_now()
		return
	if not event.is_action_pressed("pause"):
		return
	if _pause.is_open() or _title.is_open():
		return
	get_viewport().set_input_as_handled()
	_pause.open()

## `P` (or `F9`) writes a screenshot into the telemetry folder and a line of trace beside it. It is
## a debugging aid rather than a game feature.
##
## **It works on every screen, including the pause and the title**, which is why it is answered
## before the pause guard rather than after it: the frames worth photographing by hand are
## disproportionately the ones where something looks wrong and the player has just stopped the game
## to look at it.
##
## The context is assembled here rather than in `Telemetry`, for the reason the whole of that file
## is written that way: the telemetry asks the world no questions, so it can never be the thing
## that changed one. It is the three things a picture cannot carry and a reader always wants —
## where she is in tiles, what the meters read, and which screen is up — and it takes nothing that
## is not already on screen.
## Every field is guarded, because the one screen this is most likely to be pressed on is the one
## where the world is least finished — a title screen, or a boot that went wrong.
func _snapshot_now() -> void:
	var where := Vector2i.ZERO
	if _city and _player:
		where = _city.map.world_to_tile(_player.global_position)
	var meters := "no baby yet"
	if _baby:
		meters = "exc %d, sleep %d" % [roundi(_baby.excitement), roundi(_baby.sleepiness)]
	var screen := "playing"
	if _title and _title.is_open():
		screen = "title"
	elif _pause and _pause.is_open():
		screen = "paused"
	Telemetry.snapshot_now("asked for a picture at (%d,%d) | %s | %s"
			% [where.x, where.y, meters, screen])

func _quit() -> void:
	Telemetry.end_run()
	get_tree().quit()

## Closing the window is the other way a run ends, and an abandoned run is worth reading —
## every line is already on disk, so this only closes the handle tidily.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Telemetry.end_run()
