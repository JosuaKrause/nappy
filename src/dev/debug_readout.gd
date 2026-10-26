class_name DebugReadout
extends Node2D
## The developer's furniture over a run, none of it part of the game's UI: the right-hand readout
## (seed, day, phase, her ground, what is out, the frame's cost, the meter's flows), the frame-time
## graph, the `?debug=1` note, the debug view's world overlays (`DebugLayers`) and the day's planned
## routes (`RouteLines`), their number keys, and the snapshot keys.
##
## **Gated, not merely hidden.** The readout runs only on a debug build (`_debug`) or under the
## page's own `?debug=1` or `--debug` (`_readout_requested`); the graph, the overlays and the routes
## are built under that same gate, so a release page's `?debug=1&layers=1,3,5` can ask for a
## picture, and every piece is absent from the tree, not built and left invisible, on a release
## page that asked for nothing. The number keys and the snapshot keys answer a debug build alone: a
## release page can ask for a picture already drawn a particular way, never toggle one by hand.
##
## **It is handed everything it reads**, by `main`: the run's configuration, the readout's label
## and layer from `main`'s scene, the run (its seed and calendar day), the session the snapshots go
## to and what screen is up (`setup()`); her, the baby and the day's clock (`watch()`); the world
## being walked (`show_the_world()`, again when the escape walks out of the building); the day's spec
## (`use_the_day()`); the frame record (`watch_frames()`). It asks nothing of `main`.
##
## A `Node2D` at the origin, so the overlays under it draw in world space exactly as they would
## under `main`, on the debug layer (`DrawLayer.Layer.DEBUG`). It runs through a pause, inheriting
## `main`'s `PROCESS_MODE_ALWAYS`, so the readout keeps up behind a summary; the overlays pause with
## the game.

## How often the readout's text is re-set, in seconds. Re-setting some thirty lines of text every
## frame adds draw calls and drawing work to every phone record taken under `?debug=1`, so the text
## is built a few times a second instead. Nothing the readout shows is lost by it: `FrameCost` hands
## its numbers over once a second, the frame record keeps every slow frame and the readout names the
## latest one at each refresh, and the graph is fed every frame.
const READOUT_INTERVAL := 0.25

## The frame graph's offset below the readout's top in the design box. The readout's block gains its
## 32nd line only under `--skip`, and 32 lines at the label's font size (17px tall, 3px between
## lines, measured off a headless `Label`) reach about 637px from the block's top, so a fixed offset
## clears both shapes rather than re-measuring the label every frame. Below the block, not above
## it, because the joystick focus ring (48px, centred at y=480 in the same box) reaches no further
## than y=528.
const GRAPH_TOP := 660.0

## A debug build. A member rather than a read of `config` in `_process()`, so a test can set it and
## check the release shape.
var _debug := false
## `?debug=1` or `--debug`, read independently of `_debug` so a release page can ask for the readout.
var _readout_requested := false
## The validated `--skip` words, for the readout's own `skip` line beneath the seed, so a picture
## taken under `--skip` says what it measured.
var _skip_words: Array[String] = []
## `--layers`, which starts overlays on without a keypress.
var _layers_override: Array[int] = []
## `--spikes`, which starts the graph on.
var _spikes_requested := false
## `BuildInfo.build_text()`, read on the first frame that assembles the readout and kept, since a
## working tree pays two `git` spawns for it and a release page with neither flag never pays them.
var _build_text := ""
## Seconds until the readout's text is next rebuilt; 0 or less rebuilds it on the next frame.
var _readout_wait := 0.0

## The readout's label and the layer it stands on, from `main`'s scene.
var _status: Label
var _status_layer: CanvasLayer
## Whether the readout is showing — key `4`. Starts `true`, so an unflagged debug run shows it, and
## `false` under `--player-view` unless `--debug` asks for it, since that frame is the one a player
## sees.
var _layer_readout_on := true
## Whether the frame-time graph is showing — key `6`, independent of `4`, off unless `--spikes` is
## set or `--layers` names `6` (2026-09-15, the player: "spike view should be independent of debug
## layer 4 it should be its own debug layer and turned off by default unless --spikes is set").
## Turning it off empties the graph's ring, so a graph switched back on starts blank.
var _layer_graph_on := false
## Whether the title screen is up: the readout is neither drawn nor fed behind it, and `6` pressed
## there does not draw the graph over it.
var _in_the_title := false

## The rolling bar graph of the last frames' lengths, under the readout's label — null unless the
## gate holds.
var _frame_graph: FrameGraph
## The fixed note `?debug=1` adds for the whole session, which nothing removes — null unless the
## readout was asked for. An ordinary debug build shows the readout without it.
var _debug_mode_note: DebugModeNote
## The fields, shadows and bounding-box overlays, keys `1`–`3` — null unless the gate holds.
var _debug_layers: DebugLayers
## The day's planned routes, key `5` — null unless the gate holds, and until a city stands.
var _route_lines: RouteLines

## What the readout reads.
var _run: RunHeader
var _session: RunSession
var _screen_name: Callable
var _player: Stroller
var _baby: Baby
var _day: DayController
var _spec := DaySpec.new()
var _city: City
var _map: WorldMap
var _events: EventManager
var _crowd: Crowd
var _frame_recorder: FrameRecorder

## Hands the readout the run's configuration, and sets the members read from it.
func configure(config: RunConfig) -> void:
	_debug = config.debug_build
	_readout_requested = config.readout_requested
	_skip_words = config.skip_words
	_layers_override = config.layers_override
	_layer_readout_on = not config.player_view_requested or config.readout_requested
	_spikes_requested = config.spikes_requested

## Builds what the gate allows on the readout's label and layer, and shows the readout in the shape
## this build should have. `run` is the run whose seed and calendar day it names (`GameState.header`),
## `session` where the snapshot keys send their pictures, and `screen_name` what screen is up, for
## the snapshot's line ("title", "paused" or "playing").
func setup(config: RunConfig, status: Label, status_layer: CanvasLayer, run: RunHeader,
		session: RunSession, screen_name: Callable) -> void:
	configure(config)
	_status = status
	_status_layer = status_layer
	_run = run
	_session = session
	_screen_name = screen_name
	_add_debug_mode_note()
	_add_frame_graph()
	_set_readout_visible(_gate() and _layer_readout_on)

## Her, the baby and the day's clock, once they exist.
func watch(player: Stroller, baby: Baby, day: DayController) -> void:
	_player = player
	_baby = baby
	_day = day

## The world she is walking: its events, its crowd (null in the escape's building), the node whose
## subtree holds the bodies the bounding boxes trace, its map, and the city when it is one. Called
## once per world, so walking out of the service door points the overlays at the city with whatever
## `1`–`3` had switched on still on.
func show_the_world(events: EventManager, crowd: Crowd, world: Node2D, map: WorldMap,
		city: City) -> void:
	_events = events
	_crowd = crowd
	_map = map
	_city = city
	if not _gate():
		return
	if _debug_layers:
		_debug_layers.setup(events, crowd, world, _player)
		return
	_debug_layers = DebugLayers.new()
	_debug_layers.name = "DebugLayers"
	DrawLayer.draw_on(_debug_layers, DrawLayer.Layer.DEBUG)
	_debug_layers.setup(events, crowd, world, _player)
	_debug_layers.apply_initial_state(_layers_override)
	add_child(_debug_layers)
	_debug_layers.process_mode = Node.PROCESS_MODE_PAUSABLE
	print("[DebugLayers] keys:  1 fields   2 shadows   3 bounding boxes   4 readout   5 routes")

## The day's planned routes over `map`, drawn as purple polylines. A sibling of the overlays rather
## than a fourth case on them: those query the live geometry every frame, and this draws a fixed
## plan that changes once a day (`refresh_routes()`).
func draw_routes(map: CityMap) -> void:
	if not _gate():
		return
	_route_lines = RouteLines.new()
	_route_lines.name = "RouteLines"
	DrawLayer.draw_on(_route_lines, DrawLayer.Layer.DEBUG)
	_route_lines.setup(map)
	_route_lines.apply_initial_state(_layers_override)
	add_child(_route_lines)
	_route_lines.process_mode = Node.PROCESS_MODE_PAUSABLE

## Today's routes, once the day's tree is grown.
func refresh_routes(tree: RouteTree) -> void:
	if _route_lines:
		_route_lines.refresh(tree)

## The day being walked: its number and its words name the readout's day line.
func use_the_day(spec: DaySpec) -> void:
	_spec = spec

## The frame record, whose line the readout carries beneath the frame block.
func watch_frames(recorder: FrameRecorder) -> void:
	_frame_recorder = recorder

## Whether the readout and the graph are showing — what the frame trace asks.
func readout_on() -> bool:
	return _layer_readout_on

func graph_on() -> bool:
	return _layer_graph_on

## The title screen opens: the readout and the graph come off, since each is a statement about a
## player who is not there. The graph's ring is kept; only a `6` toggle-off clears it.
func open_the_title() -> void:
	_in_the_title = true
	hide_for_a_screen()

## The title is dismissed: the readout is fed again, though it stays hidden behind whatever screen
## comes next until `show_for_the_walk()`.
func close_the_title() -> void:
	_in_the_title = false

## Takes the readout and the graph off the screen without changing either one's own switch.
func hide_for_a_screen() -> void:
	_set_readout_visible(false)
	if _frame_graph:
		_frame_graph.visible = false

## She is walking: the readout and the graph come back as their own switches have them, so a
## `4`-toggled-off readout stays off across a trip through the title and a `6`-toggled-on graph
## reappears with whatever its ring held.
func show_for_the_walk() -> void:
	_set_readout_visible(_gate() and _layer_readout_on)
	if _frame_graph:
		_frame_graph.visible = _layer_graph_on

func _gate() -> bool:
	return _debug or _readout_requested

func _add_debug_mode_note() -> void:
	if not _readout_requested:
		return
	_debug_mode_note = DebugModeNote.new()
	_debug_mode_note.name = "DebugModeNote"
	add_child(_debug_mode_note)

## The graph lives beside the readout on the readout's own layer, on its own key, not among the
## overlays' keys, left-aligned with the label.
func _add_frame_graph() -> void:
	if not _gate():
		return
	_frame_graph = FrameGraph.new()
	_frame_graph.name = "FrameGraph"
	_frame_graph.text_colour = _status.get_theme_color("font_color")
	_frame_graph.position = Vector2(_status.offset_left, GRAPH_TOP)
	_layer_graph_on = _graph_starts_on(_spikes_requested, _layers_override)
	_frame_graph.visible = _layer_graph_on
	_status_layer.add_child(_frame_graph)

## Whether the graph starts on, pure in the two flags so a test can drive the policy: `--spikes`
## means somebody is chasing a stutter, and `--layers` naming `6` is the same keypress-free request
## `5` answers for the routes.
static func _graph_starts_on(spikes_requested: bool, layers: Array[int]) -> bool:
	return spikes_requested or 6 in layers

## The one place the label's visibility is set. It does not touch the graph: the graph's switch is
## `6`, not `4`.
func _set_readout_visible(shown: bool) -> void:
	_status.visible = shown

# ----------------------------------------------------------------- the readout ---

func _process(delta: float) -> void:
	if not _player or not _baby or not _day or _in_the_title:
		return
	# The graph is fed ahead of the readout's own switch, since `6` keeps feeding whatever `4` did;
	# `push()` is a no-op while the graph is hidden.
	if _frame_graph:
		_frame_graph.push(delta)
	# Gated rather than merely hidden: the readout is a scan of every live event and a dozen
	# formatted lines, which a build with neither flag, or with `4` off, never assembles.
	if not _gate() or not _layer_readout_on:
		_readout_wait = 0.0
		return
	if not _readout_due(delta):
		return
	if _build_text == "":
		_build_text = BuildInfo.build_text()
	var header := [
		"build %s" % _build_text,
		"seed  %d   day %d%s" % [_run.run_seed,
			_run.day if _spec.section == DaySpec.Section.NONE else _spec.number,
			"" if _spec.title == "" else "   " + _spec.title.to_lower()],
	]
	if not _skip_words.is_empty():
		header.append("skip  %s" % ", ".join(_skip_words))
	_status.text = "\n".join(header + [
		"phase %s  %.0fs left" % [
			GameEnums.DayPhase.keys()[_day.phase].to_lower(), _day.time_remaining],
	] + _where_she_is_lines() + [
		"",
		"speed       %6.1f" % _player.current_speed(),
		"run excess  %6.2f" % _player.run_excess_ratio(),
		"",
	] + _what_is_out_lines() + [
		"nearest     %s" % _nearest_event_text(),
		"",
	] + FrameCost.readout_lines() + FrameRecorder.view_lines() + _frame_record_lines() + [
		"",
		"incoming    %6.2f /s" % _baby.last_incoming,
		"decay       %6.2f /s" % _baby.last_decay,
		"net         %6.2f /s" % (_baby.last_incoming - _baby.last_decay),
		"",
		"arrows/WASD walk",
		"shift       run",
		"esc         pause  (r restart, q quit)",
	])

## Whether this frame rebuilds the readout's text: the first frame after it is switched on, then
## every `READOUT_INTERVAL`, counted in the frames' own `delta` so a slow frame does not shorten it.
func _readout_due(delta: float) -> bool:
	_readout_wait -= delta
	if _readout_wait > 0.0:
		return false
	_readout_wait = READOUT_INTERVAL
	return true

## Her ground: the city's tile and whether it is calm or an alley, or the building's tile, which has
## neither.
func _where_she_is_lines() -> Array:
	var here := _player.global_position
	if _city:
		var tile := _city.map.world_to_tile(here)
		return [
			"tile  %d, %d  (%s)" % [tile.x, tile.y, _tile_name(_city.map.tile_at(tile))],
			"calm  %s    alley  %s" % [
				"yes" if _city.is_calm_zone(here) else "no",
				"yes" if _city.is_alley(here) else "no"],
		]
	if _map:
		var tile := _map.world_to_tile(here)
		return ["tile  %d, %d  (building)" % [tile.x, tile.y]]
	return []

## What is out: the city's events, live against planned, what the director still owes ahead of her
## and the crowd — or, in the escape's building, its events alone.
func _what_is_out_lines() -> Array:
	if _city:
		return [
			"events      %6d live of %d" % [
				_city.events.active_count(), _city.events.planned_count()],
			"ahead owed  %6d" % _city.events.owed_ahead(),
			"crowd       %6d" % _city.crowd.agent_count(),
		]
	return ["events      %6d live" % (_events.instances().size() if _events else 0)]

func _frame_record_lines() -> Array[String]:
	if _frame_recorder == null:
		return []
	return [_frame_recorder.readout_line()]

## The closest live event and what it is doing — the line that says whether a telegraph ended when
## it should have.
func _nearest_event_text() -> String:
	if not _events:
		return "none"
	var nearest: EventInstance = null
	var best := INF
	for instance: EventInstance in _events.instances():
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

# ------------------------------------------------------------------- the keys ---

## The snapshot keys first, then the layer keys, a debug build only. They work on every screen,
## the pause and the title included: the frames worth photographing by hand are disproportionately
## the ones where something looks wrong and the player has stopped the game to look.
func _unhandled_input(event: InputEvent) -> void:
	if not _debug:
		return
	var snapshot_action := _debug_snapshot_action(event)
	if snapshot_action == &"snapshot_burst":
		get_viewport().set_input_as_handled()
		_start_burst()
		return
	if snapshot_action == &"snapshot":
		get_viewport().set_input_as_handled()
		_snapshot_now()
		return
	# Raw keycodes rather than input-map actions, so `project.godot` carries no binding a release
	# build could reach.
	var layer_key := _debug_layer_key(event)
	if layer_key > 0:
		get_viewport().set_input_as_handled()
		_toggle_debug_layer(layer_key)

## The two capture keys, resolved before input dispatch. A key echo is not a second capture: a held
## shortcut is one request.
static func _debug_snapshot_action(event: InputEvent) -> StringName:
	if event is InputEventKey and (event as InputEventKey).echo:
		return &""
	if event.is_action_pressed("snapshot_burst"):
		return &"snapshot_burst"
	if event.is_action_pressed("snapshot"):
		return &"snapshot"
	return &""

## `1` fields, `2` shadows, `3` bounding boxes, `4` the readout, `5` the day's routes, `6` the
## frame-time graph — or `0` for anything else, an echo included.
static func _debug_layer_key(event: InputEvent) -> int:
	if not (event is InputEventKey and (event as InputEventKey).pressed):
		return 0
	if (event as InputEventKey).echo:
		return 0
	match (event as InputEventKey).keycode:
		KEY_1: return 1
		KEY_2: return 2
		KEY_3: return 3
		KEY_4: return 4
		KEY_5: return 5
		KEY_6: return 6
		_: return 0

## `4` and `6` are this node's own switches, `5` the routes' visibility, and `1`–`3` the overlays'.
## Turning the graph off also empties its ring, so `6` twice leaves a blank graph that fills from
## that moment (2026-09-15, the player: "toggling the layer twice will lead to a blank frame
## array").
func _toggle_debug_layer(layer: int) -> void:
	if layer == 4:
		_layer_readout_on = not _layer_readout_on
		_set_readout_visible(_gate() and _layer_readout_on)
		return
	if layer == 5:
		if _route_lines:
			_route_lines.visible = not _route_lines.visible
		return
	if layer == 6:
		_layer_graph_on = not _layer_graph_on
		if _frame_graph:
			_frame_graph.visible = _layer_graph_on and not _in_the_title
			if not _layer_graph_on:
				_frame_graph.clear()
		return
	if _debug_layers:
		_debug_layers.set_layer(layer, not _debug_layers.layer_on(layer))

## `P` (or `F9`) writes a screenshot into the run log's folder with a line of context; `B` a burst.
## The context is the three things a picture cannot carry — where she is in tiles, what the meters
## read and which screen is up — and every field is guarded, because the screen this is most likely
## pressed on is the one where the world is least finished.
func _capture_context() -> String:
	var where := Vector2i.ZERO
	if _city and _player:
		where = _city.map.world_to_tile(_player.global_position)
	var meters := "no baby yet"
	if _baby:
		meters = "exc %d, sleep %d" % [roundi(_baby.excitement), roundi(_baby.sleepiness)]
	var screen: String = _screen_name.call() if _screen_name.is_valid() else "playing"
	return "(%d,%d) | %s | %s" % [where.x, where.y, meters, screen]

func _snapshot_now() -> void:
	if _session:
		_session.picture(_capture_context())

func _start_burst() -> void:
	if _session:
		_session.burst(_capture_context())
