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
const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")

@onready var _status: Label = $CanvasLayer/Status
@onready var _status_layer: CanvasLayer = $CanvasLayer

## Whether the developer readout runs at all. Read once from `DevFlags.enabled()` into a member
## — rather than asked of `OS.is_debug_build()` inside `_process()` — so a test can set it and
## check the release shape, the way `hud._debug` already does for the HUD's own gate.
var _debug := DevFlags.enabled()

## Read once into a member for the same reason `_debug` is: so a test can set it directly and
## check the release shape, rather than only being able to exercise the flag from an actual debug
## build's own command line. `_ready_escape()` reads this member rather than calling
## `DevFlags.start_escape()` again, the same shape `_add_debug_layers()` reads `_debug`.
var _escape_scene_requested := DevFlags.start_escape()

var _city: City
## Set instead of `_city` under `--start-escape`; the two are never both non-null. See
## `_ready_escape()`.
var _interior: InteriorScene
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
## What is currently charging the meter, drawn under the world rather than over it — see
## `_add_excitement_halo()`.
var _halo: ExcitementHalo
## The fields, shadows and bounding-box overlays — `null` outside a debug build, so "is a layer
## node in the tree" is a release-build test's own question rather than one this class has to
## remember to ask of `_debug` separately. See `_add_debug_layers()`.
var _debug_layers: DebugLayers
## Whether the developer readout (`_status`) is showing, independent of `_debug`: the fourth
## layer `_toggle_debug_layer()` owns, on `_status`'s own pre-existing `CanvasLayer` rather than
## under `_debug_layers`, which is not a `CanvasLayer` this label could join. Starts `true`, so an
## unflagged debug run reads exactly as it did before this milestone.
var _layer_readout_on := true
## The pointer controls, on their own layer for the same reason the danger edge is: they have to
## sit above the world they are drawn over. Built in `_ready()`, alongside `_touch_layer`.
var _touch_controls: TouchControls
## Built in `_ready()` for `_touch_controls` to live on — `_apply_orientation()` needs somewhere to
## rotate, the same reason it exists before the controls question used to be answered.
var _touch_layer: CanvasLayer
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

## Read once — a run's own touch hardware does not change — the same pattern `TouchControls._touch`
## and `hud._touch` already follow, and what lets `_process()` ask `ScreenOrientation.wants_rotation`
## every frame without also repeating `TouchInput.available()`'s own `OS.get_cmdline_user_args()`
## call sixty times a second.
var _touch_available := TouchInput.available()
## The rotation `_apply_orientation()` last actually applied, so `_process()` can ask the same
## question every frame and reapply only on change — see that function's own doc for why a signal
## alone is not enough.
var _rotated := false
func _ready() -> void:
	# Esc has to work even while the summary has the tree paused, so this node keeps running
	# through a pause. Everything under it that *is* the game is put back to pausable as it is
	# created — see `_pauses_with_the_game()`. A child left on the default INHERIT inherits
	# ALWAYS from here, and then the pause does nothing to it: the summary sets
	# `get_tree().paused` while the player walks, the crowd drives and the resistance deadline
	# runs out behind a screen saying the day is over.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# `--start-escape` is a different boot entirely — no title, no city, no day — so it branches
	# before any of the ordinary run's own scaffolding exists. See `_ready_escape()`.
	if _escape_scene_requested:
		_ready_escape()
		return
	# Starts in the shape it should have on this build rather than trusting the scene file's own
	# default (`true`): every later flip of it is relative to whichever screen is up, and a boot
	# path that never reaches one of them should still open with the right answer.
	# `_layer_readout_on` defaults `true`, so this is `_debug` alone on an unflagged run — the
	# fourth debug layer starts on, the same as it always has.
	_status.visible = _debug and _layer_readout_on
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
	_add_excitement_halo()
	_add_debug_layers()
	_add_touch_controls()
	_summary = DAY_SUMMARY.instantiate()
	add_child(_summary)

	# Deliberately not `_pauses_with_the_game`: a pause screen that pauses with the game cannot
	# unpause it. It inherits ALWAYS from this node, which is what it wants.
	_pause = PAUSE_SCREEN.instantiate()
	add_child(_pause)

	_connect_summary_and_pause_signals()

	# Same reasoning, one screen further out. See `TitleScreen`.
	_title = TITLE_SCREEN.instantiate()
	add_child(_title)
	_title.start_requested.connect(_on_title_start)
	_title.quit_requested.connect(_quit)

	# After every layer `_apply_orientation()` touches exists — it reaches `_summary`, `_pause`
	# and `_title` too, not just the HUD and the two layers built just above. `_process()` is what
	# keeps it current from here on, not a `size_changed` connection — see that function's own doc.
	_apply_orientation()

	_resistance = ResistanceDirector.new()
	_resistance.name = "Resistance"
	add_child(_resistance)
	_pauses_with_the_game(_resistance)
	_resistance.setup(_city, _city.map)
	# The director's own "has she seen this" test — no viewport of its own, so it borrows the
	# one rotation-aware on-screen check the game already has rather than growing a second one.
	_resistance.set_sight(_edge.is_on_screen)

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

## `--start-escape`'s own boot: the third floor's hallway, her at the door with the baby in her
## arms, and the way down. No title, no `City`, no events, no crowd, no `DayController` and no
## `ResistanceDirector` — the milestone this exists for is judging the walking, the floor
## transitions and the stair tiles on their own, before the finale puts any pressure on top of
## them, so nothing here builds a clock or an ending. The HUD still comes up: its two meters
## idle exactly as `WorldContext`'s own defaults leave them (1.0 recovery everywhere, nothing
## charging excitement), which is "meters idle" for free rather than a case this has to build.
func _ready_escape() -> void:
	# Guarded here too, not only at the call site in `_ready()` — the same shape
	# `_add_debug_layers()` reads `_debug` in, so a test can call this directly and check the
	# release shape without also driving the rest of `_ready()`.
	if not _escape_scene_requested:
		return
	_status.visible = false
	GameState.start_run(DevFlags.seed_override())

	_interior = InteriorScene.new()
	_interior.name = "Interior"
	add_child(_interior)
	_pauses_with_the_game(_interior)
	_interior.build(InteriorMap.FloorKind.THIRD)
	_interior.exit_requested.connect(_on_escape_exit_requested)

	_player = STROLLER.instantiate()
	_player.carrying = true
	_interior.add_entity(_player)
	_player.set_camera_limits(_interior.camera_bounds())
	_baby = _player.get_node("Baby")

	_hud = HUD.instantiate()
	add_child(_hud)
	_add_touch_controls()

	# Built but not opened — same reasoning `_ready()` builds `_title` up front for the ordinary
	# run: `_on_escape_exit_requested()` needs somewhere to send the emergency exit rather than
	# building a screen the moment it is first asked for.
	_title = TITLE_SCREEN.instantiate()
	add_child(_title)
	_title.start_requested.connect(_on_escape_title_start)
	_title.quit_requested.connect(_quit)

	_apply_orientation()
	_player.reset_at(_interior.start_world_position(), Vector2.UP)

	var screenshot := AutoScreenshot.from_command_line()
	if screenshot:
		add_child(screenshot)

## `InteriorScene.exit_requested` fires once the emergency exit's own fade has covered the screen
## — see `InteriorScene._start_exit()`. Pausing and opening `_title` is what "returns to the title
## screen" actually has to mean here: a scene reload would read `--start-escape` off the same
## command line and boot straight back into this function, so the screen the spec names would
## never actually appear on screen.
func _on_escape_exit_requested() -> void:
	get_tree().paused = true
	_hud.visible = false
	_title.open(false)

## The title screen's own start button, reached after the emergency exit — there is no larger run
## behind this debug entry to resume, so the only thing left worth doing with it is walking the
## escape scene again from the top. `--start-escape` is read fresh on the reload, so this is also
## "run it again" for anybody testing the walk down.
func _on_escape_title_start(mode: ControlsMode.Mode) -> void:
	_touch_controls.set_mode(mode)
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")

## Both screens' own restart reaches the one thing that means it, and both screens' own way out
## reaches the same quit — pulled into its own function, called once `_summary` and `_pause` both
## exist, rather than left as four lines split across each screen's own instantiation.
##
## **This is the fix for the day summary's own restart button holding, filling its bar, firing its
## signal, and being heard by nobody** — `_summary.restart_requested` had no connection at all next
## to `_pause.restart_requested.connect(_restart_run)`, which is the shape
## `_test_the_summary_and_pause_restart_signals_are_both_connected` now holds so a screen added
## later cannot repeat it silently: a green `check.sh` and a green suite both passed with the day
## summary's restart doing nothing, because nothing before this ever asked whether the signal was
## connected rather than only whether pressing the button emitted it.
func _connect_summary_and_pause_signals() -> void:
	_summary.continued.connect(_on_summary_continued)
	_summary.restart_requested.connect(_restart_run)
	_pause.quit_requested.connect(_quit)
	_pause.restart_requested.connect(_restart_run)

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

## The title screen has been pressed, which is also the start: hand the city back to the day it
## belongs to.
##
## `mode` is the player's own answer to the controls question — a press on `TitleScreen`'s
## `Symbol.JOYSTICK`/`Symbol.TAP` button, or `Mode.TAP` when a key began the run instead. Handed
## straight to `_touch_controls.set_mode()`, which overrides whatever `_add_touch_controls()` set
## from `ControlsMode.resolve()` at boot — see that function's own doc for why a rig that never
## reaches this screen keeps that earlier answer instead.
##
## Guarded with `is_inside_tree()` the same way `_process()` already guards `get_window()`: false
## for the script-only instance `tests/test_main.gd` drives straight through this function with no
## tree behind it at all — `get_tree()` itself logs an engine-level error when called off-tree,
## which `is_inside_tree()` never does, so this is the check to make rather than a null check on
## `get_tree()`'s own return. Never false in the running game, where this only ever fires on a real
## `main` already in the tree.
func _on_title_start(mode: ControlsMode.Mode) -> void:
	_touch_controls.set_mode(mode)
	_in_the_title = false
	_title.close()
	_player.step_back_in()
	_pauses_with_the_game(_city)
	_hud.visible = true
	_edge_layer.visible = true
	# Not an unconditional `true`: this is the one place the readout was coming back regardless
	# of build, since `_open_the_title()` always turns it off and this was the only place that
	# turned it back on. `and _layer_readout_on` so a `4`-toggled-off readout stays off across a
	# trip through the title rather than snapping back on underneath it.
	_status.visible = _debug and _layer_readout_on
	if is_inside_tree():
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
	# Pinned to the fixed design box rather than full-rect, so this layer's own rotation (applied
	# in `_apply_orientation()`) has a stationary 1280x720 footprint to rotate — see
	# `ScreenOrientation.pin_to_design_box()`.
	ScreenOrientation.pin_to_design_box(_edge)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge.setup(_city.events, _player)
	layer.add_child(_edge)
	add_child(layer)

## What is charging the meter right now, drawn in world space rather than in a `CanvasLayer` —
## unlike `DangerEdge`, this cue is a picture of the ground itself, not screen furniture laid over
## it, so it has to sit where the ground does and move with the same camera.
##
## `z_index = 1` puts it above `City`'s `Ground` (default 0) and below its `Entities` (2, the
## y-sorted layer the player, the crowd and every event live on) — under everything the cue is
## required to be under: the entities, the crowd and the player, none of which can ever read as
## lit from beneath. It ties `Buildings` (also 1) rather than sitting under it as well, which a
## glow can afford to: a wall the field happens to reach warms slightly, the way it would under
## any coloured light near it, and nothing the cue exists to protect is a wall.
## `_pauses_with_the_game()` is the same reasoning `_city` gets: while the tree is paused nothing
## it reads is moving either, so freezing alongside the world it draws needs no case of its own.
func _add_excitement_halo() -> void:
	_halo = ExcitementHalo.new()
	_halo.name = "ExcitementHalo"
	_halo.z_index = 1
	_halo.setup(_city.events, _city.crowd, _player)
	add_child(_halo)
	_pauses_with_the_game(_halo)

## The fields, shadows and bounding-box overlays — see `DebugLayers`. **Absent from the tree
## outside a debug build**, not merely built and left invisible: `_debug_layers` stays `null`, so
## nothing here is queried, nothing is drawn and a release build pays for none of it.
##
## `z_index = 3` puts it above `Entities` (2, the y-sorted layer everything on the ground lives on)
## — above everything else in the world, unlike the halo's own `z_index = 1`, because a bounding
## box drawn under the thing it outlines would be the one cue in the game nobody could read.
## Every layer starts off, unless `-- --layers 1,3` (or the page's own `?layers=1,3`) says
## otherwise — see `_toggle_debug_layer()` for the number key that turns one on by hand.
func _add_debug_layers() -> void:
	if not _debug:
		return
	_debug_layers = DebugLayers.new()
	_debug_layers.name = "DebugLayers"
	_debug_layers.z_index = 3
	_debug_layers.setup(_city.events, _city.crowd, _city, _player)
	_debug_layers.apply_initial_state(DevFlags.layers_override())
	add_child(_debug_layers)
	_pauses_with_the_game(_debug_layers)
	print("[DebugLayers] keys:  1 fields   2 shadows   3 bounding boxes   4 readout")

## The one control scheme, in its own layer for the same reason the danger edge gets one: it has to
## sit above the world it overlays. One node goes into the tree rather than a choice between two —
## `TouchControls` answers whether it is *shown* itself, off `TouchInput.available()` and
## `get_tree().paused`, which is what a title screen, the pause and the between-days summary all
## set. That is one fact main already produces for other reasons rather than a second wire main
## would have to remember to pull on every one of those screens.
##
## `set_mode(ControlsMode.resolve())` gives it the mode a rig gets if the title screen is never
## reached at all (`--no-title`, a screenshot rig) — the command line, then the page's own URL,
## then `TAP`. This is only ever the **pre-title** answer: `_title` does not exist yet at this
## point in `_ready()`, and `main._on_title_start()` overrides it the moment a player actually
## presses one of the title screen's own two buttons.
func _add_touch_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TouchControls"
	_touch_layer = layer
	add_child(layer)
	_touch_controls = TOUCH_CONTROLS.instantiate()
	_touch_layer.add_child(_touch_controls)
	_touch_controls.rotated = _rotated
	_touch_controls.set_mode(ControlsMode.resolve())

## Adds the final pass before raising the root render target. The engine's final root blit is a
## nearest sample, so a larger target alone would discard three quarters of its pixels. The shader
## writes one 2x2 average into each pixel in its block, which keeps the selected final sample from
## depending on the driver's decimation phase.
## Presents the game rotated 90° when the real window is a portrait touch screen, so a phone
## with auto-rotate off shows a full-size landscape game rather than a thin letterboxed strip of
## one — see `ScreenOrientation` for the mechanism and why it needs no CSS and no orientation API.
## Nothing here asks the device itself to rotate.
##
## Every `CanvasLayer` of screen furniture gets the same `ScreenOrientation.rotation_transform()`,
## so the HUD, the pause screen, the day summary, the title screen, the debug status line, the
## danger edge and the touch controls all turn together; the world is the one thing not drawn
## through a `CanvasLayer`, so it rotates separately, through the camera — see
## `Stroller.set_screen_rotation()`.
##
## Called once from `_ready()` and again from `_process()` whenever the answer changes — never
## only from a `size_changed` signal, which can arrive with a stale `get_window().size`, or not
## arrive at all if a phone is turned back to a shape that already reads as landscape without the
## browser ever resizing the canvas, latching the wrong `content_scale_size` until a reload. Asking
## the same question every frame instead means the decision cannot go stale between calls.
func _apply_orientation() -> void:
	var rotate := ScreenOrientation.wants_rotation(get_window().size, _touch_available)
	_rotated = rotate
	get_window().content_scale_size = ScreenOrientation.content_scale_size(rotate)
	_player.set_screen_rotation(deg_to_rad(90.0) if rotate else 0.0)
	_touch_controls.rotated = rotate
	# `_edge` (the screen-edge badge) does not exist under `--start-escape` — there are no events
	# to warn about — see `_ready_escape()`.
	if _edge:
		_edge.rotated = rotate
	_hud.set_rotated(rotate)
	# Every layer of screen furniture carries the same rotation, so the world (rotated by the
	# camera above) and everything drawn over it agree — see `ScreenOrientation`'s class doc for
	# why a `CanvasLayer` transform is the mechanism and `apply_to_layer()` the one place that
	# reads `if rotate: ... else: IDENTITY`. Some layers are absent under `--start-escape` (see
	# `_ready_escape()`), so the list is filtered rather than assumed complete.
	for layer in _screen_furniture_layers():
		if layer:
			ScreenOrientation.apply_to_layer(layer, rotate)

func _screen_furniture_layers() -> Array[CanvasLayer]:
	var layers: Array[CanvasLayer] = [
		_hud, _edge_layer, _touch_layer, _summary, _pause, _title, _status_layer]
	return layers

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
	# Timed for the same reason `_ready()` times `CityGenerator.generate()`: playtest 27 named
	# this path — planning the day's closures, placing every event, streaming the world around
	# the doorstep — as one of the candidates for the wait after a summary's continue button,
	# and nothing about it had ever been measured.
	var elapsed := Time.get_ticks_msec()
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
	# The smallest wiring for the checkpoint gates: `City.region_plan()` is already valid by here
	# (`_city.start_day()` built it above), so the crowd just needs to be told where today's gates
	# are — empty before `Tuning.REGION_WALL_FIRST_DAY`, which is a harmless no-op day for `Crowd`.
	_city.crowd.set_gates(_city.region_plan().gates)
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

	print("[Main] day %d started in %d ms (act %d): %d events (%d live, %d ahead), %d crowd, %.0fs "
			% [GameState.day, Time.get_ticks_msec() - elapsed, GameState.current_act(),
			_city.events.planned_count(), _city.events.active_count(), _city.events.owed_ahead(),
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
	# The same picture again, now that the day has been walked: the marks she reached carry a pip
	# and the rest do not, and the trail she actually left is drawn against the corridor the day
	# planned for her — which is the one thing the dawn map cannot say. `_observer` is only in the
	# tree while a run is being traced, so both are empty rather than missing when it is not — see
	# `Telemetry.write_map`. Before `end_day()`, so it belongs to the day it is of.
	#
	# **Not a ternary.** `_observer.trail() if _observer else []` assigned straight into a typed
	# `Array[Vector3]` throws at runtime — the `else` branch is a bare untyped `Array`, which is not
	# the declared type, and Godot only catches the mismatch when the line actually runs rather than
	# at parse time. `_observer` is null on every build with telemetry off (`--no-telemetry`, and
	# every Web export, since `Telemetry` disables itself there), which is exactly the ordinary
	# shape nothing in the suite ran this line under — an untraced day ending threw here, before
	# `_summary.show_day()` below ever ran, which is the whole of "the meter reached 100 and the day
	# would not end": the day had already ended and silently stopped telling anything downstream.
	var trail: Array[Vector3] = []
	if _observer:
		trail = _observer.trail()
	# `met` is a plain, untyped `Dictionary` (no `[K, V]`), so `{}` on either side of the ternary is
	# the same type either way and this one was never the trap the trail line was.
	var met: Dictionary = _observer.met_events() if _observer else {}
	Telemetry.write_map(_city.map, finished_day, _city.closures(), _city.route_tree(),
			_city.events.plans(), true, trail, met)
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
##
## `TitleScreen.note_restart_requested()` is called here, before the deferred reload, so the fresh
## title screen the reload builds knows the frame or two after its own `_ready()` is exactly the
## window a stray press crossing the reload could land in — see that function's own doc, and
## `TitleScreen._unhandled_input()`'s for what it guards against. *(2026-09-07: "tapping on the
## game over screen often goes directly back to the game skipping the title screen".)*
func _restart_run() -> void:
	Telemetry.end_run()
	TitleScreen.note_restart_requested()
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")

func _process(delta: float) -> void:
	_update_follow_camera()
	# Re-asked every frame rather than only on `size_changed` — see `_apply_orientation()`'s own
	# doc for why a signal alone can latch the wrong answer. The cost is one vector comparison.
	# `get_window()` is null for the script-only instance `tests/test_main.gd` drives straight
	# through `_process()` with no window behind it at all.
	var window := get_window()
	if window and ScreenOrientation.wants_rotation(window.size, _touch_available) != _rotated:
		_apply_orientation()
	if not _player or not _baby:
		return
	if _interior:
		_interior.process_player(_player, delta)
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
	# `_layer_readout_on` is this layer's own `4` key: off, the string is not assembled either,
	# the same "gated rather than merely hidden" rule `_debug` already gets.
	if not _debug or not _layer_readout_on:
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
		# A pickup's mark may not stay where this puts the camera: if she then walks away from
		# it without it ever being seen, the re-placement rule in `ResistanceDirector` moves it
		# to the next alley she comes near. Reading `contact_position()` again after the spawn
		# answers wherever it currently is, not wherever this call found it.
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
	var snapshot_action := _debug_snapshot_action(event) if _debug else &""
	if snapshot_action == &"snapshot_burst":
		get_viewport().set_input_as_handled()
		_start_burst()
		return
	if snapshot_action == &"snapshot":
		get_viewport().set_input_as_handled()
		_snapshot_now()
		return
	# `1`..`4` toggle the debug view's own four layers — raw keycodes rather than input-map
	# actions, the same choice `KEY_R`/`KEY_Q` make on the pause and title screens, so
	# `project.godot` carries no binding a release build could ever reach anyway.
	var layer_key := _debug_layer_key(event) if _debug else 0
	if layer_key > 0:
		get_viewport().set_input_as_handled()
		_toggle_debug_layer(layer_key)
		return
	if not event.is_action_pressed("pause"):
		return
	# `_pause` is never built under `--start-escape` — see `_ready_escape()` — so Esc does nothing
	# there rather than opening a screen with no ordinary run behind it to pause.
	if not _pause:
		return
	if _pause.is_open() or _title.is_open():
		return
	get_viewport().set_input_as_handled()
	_pause.open()

## Resolves the two developer capture controls before input dispatch. Key echoes do not make a
## second capture: a held shortcut is one request, not a sequence of separate user decisions.
static func _debug_snapshot_action(event: InputEvent) -> StringName:
	if event is InputEventKey and (event as InputEventKey).echo:
		return &""
	if event.is_action_pressed("snapshot_burst"):
		return &"snapshot_burst"
	if event.is_action_pressed("snapshot"):
		return &"snapshot"
	return &""

## `1` fields, `2` shadows, `3` bounding boxes, `4` the readout — or `0` for anything else. The
## same echo guard `_debug_snapshot_action()` carries, for the same reason: a held key is one
## request, not a flood of toggles for as long as it stays down.
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
		_: return 0

## `4` is the readout's own key, answered here rather than on `_debug_layers` because the readout
## lives on `_status`'s pre-existing `CanvasLayer` rather than under that node — see
## `_layer_readout_on`'s own doc. `1`-`3` forward straight to it.
func _toggle_debug_layer(layer: int) -> void:
	if layer == 4:
		_layer_readout_on = not _layer_readout_on
		_status.visible = _debug and _layer_readout_on
		return
	if _debug_layers:
		_debug_layers.set_layer(layer, not _debug_layers.layer_on(layer))

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

func _start_burst() -> void:
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
	Telemetry.start_burst("asked for an animation burst at (%d,%d) | %s | %s"
			% [where.x, where.y, meters, screen])

func _quit() -> void:
	Telemetry.end_run()
	get_tree().quit()

## Closing the window is the other way a run ends, and an abandoned run is worth reading —
## every line is already on disk, so this only closes the handle tidily.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Telemetry.end_run()
