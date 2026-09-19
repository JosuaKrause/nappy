extends Node2D
## Boot scene: generate the city, drop the player on the doorstep, then the HUD.
##
## The right-hand overlay is a developer readout, not part of the game's UI. It runs whenever
## `_debug` (`DevFlags.enabled()`) or `_readout_requested` (`DevFlags.readout_requested()`, the
## page's own `?debug=1`) holds — see `_readout_requested`'s own doc — and otherwise the string is
## never assembled, not merely hidden behind an invisible label. Every other piece of developer
## furniture (`_debug_layers`, `_route_lines`, the snapshot key, every dev flag) stays gated behind
## `_debug` alone.

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

## `DevFlags.no_focus_pause()`, read once for the same reason `_debug` is: so a test can set it
## directly and check the release shape. `_notification()` reads this member rather than calling
## the getter again on every focus change.
var _no_focus_pause := DevFlags.no_focus_pause()

## Whether the readout was asked for by the page's own `?debug=1` (or the command line's
## `--debug`) — `DevFlags.readout_requested()`, read once for the same reason `_debug` is: so a
## test can set it directly and check the release shape. `_status.visible` and the text assembly
## in `_process()` read `_debug or _readout_requested`; `_add_debug_layers()`, the snapshot key and
## the layer-toggle keys all keep reading `_debug` alone, so this flag reaches the readout and
## nothing else — see docs/TODO.md, M133, "the readout on the live page".
var _readout_requested := DevFlags.readout_requested()
## `DevFlags.skip_words()`, read once for the same reason `_readout_requested` is: so a test can
## set it directly, and so the readout's own `skip` line below is not re-splitting `--skip`'s
## comma list, or on the Web re-asking the address bar, every frame it is assembled. Empty
## whenever `_readout_requested` is false, since `skip_words()` carries that gate itself.
var _skip_words := DevFlags.skip_words()
## The readout's first line, `TitleScreen.build_text()` — `git describe`'s form and the commit —
## read on the first frame that assembles the readout and kept, since a working tree pays two
## `git` spawns for the answer and a release page with neither flag never pays them at all.
var _build_text := ""

var _city: City
## The escape scene's building. Under `--start-escape` it is built first and `_city` follows when
## she walks out of the service exit, so the two *are* both non-null for the whole of the finale's
## second section — the building stays on its own map with nobody on it. On an ordinary run
## `_interior` is null and `_city` is the only world there is.
var _interior: InteriorScene
## The escape sequence's own clock and section, or null on an ordinary run. See `FinaleController`.
var _finale: FinaleController
## The events inside the building — mice, the pursuers, the fire, the steam and the off-screen
## explosions — hosted on the interior map, since `InteriorScene` has no `EventManager`.
var _interior_events: InteriorEvents
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
## The day's planned routes, drawn as purple polylines — `null` outside a debug build, the same
## shape `_debug_layers` uses. See `_add_route_lines()`.
var _route_lines: RouteLines
## Set by `_add_debug_mode_note()`, or left `null` when `_readout_requested` is `false` — a test's
## own way to check the release shape without a live tree search for the node.
var _debug_mode_note: DebugModeNote
## The rolling bar graph of the last frames' own lengths, under `_status`. Set by
## `_add_frame_graph()`, or left `null` on the same "absent, not merely hidden" terms
## `_debug_mode_note` is — a release page nobody asked `?debug=1` of never builds it. **Built where
## the readout is, but shown independently of it**: the player asked the graph's own switch to be
## `6`, not `4`, which is a different question from whether the title screen is up — the title
## still hides everything about a player who is not there, this included. So `_frame_graph.visible`
## is `_layer_graph_on and not _in_the_title` in effect, kept true by three call sites rather than
## one: `_toggle_debug_layer()`'s own `6` case, and `_open_the_title()`/`_on_title_start()` setting
## it directly, since `_set_readout_visible()` does not touch it. `if _frame_graph:` at each site,
## since it is null on exactly the builds that never build one.
var _frame_graph: FrameGraph
## Whether the developer readout (`_status`) is showing, independent of `_debug`: the fourth
## layer `_toggle_debug_layer()` owns, on `_status`'s own pre-existing `CanvasLayer` rather than
## under `_debug_layers`, which is not a `CanvasLayer` this label could join. Starts `true`, so an
## unflagged debug run reads exactly as it did before this milestone.
var _layer_readout_on := true
## Whether the frame-time graph (`_frame_graph`) is showing — its own debug layer, key `6` in
## `_debug_layer_key()`/`_toggle_debug_layer()`, independent of `_layer_readout_on`'s own `4`:
## *(2026-09-15, the player: "spike view should be independent of debug layer 4 it should be its
## own debug layer and turned off by default unless --spikes is set".)* Starts `false` — unlike
## `_layer_readout_on`, which starts `true` — and `_add_frame_graph()` sets it `true` at boot
## instead when `DevFlags.spikes_requested()` holds or `--layers` names `6`, the same way `--layers`
## naming `5` starts `_route_lines` on. Toggling it off also empties `_frame_graph`'s own ring
## (`FrameGraph.clear()`), so a graph switched off and back on again starts from blank rather than
## picking up wherever the window it was not fed during happened to leave off.
var _layer_graph_on := false
## The pointer controls, on their own layer for the same reason the danger edge is: they have to
## sit above the world they are drawn over. Built in `_ready()`, alongside `_touch_layer`.
var _touch_controls: TouchControls
## Built in `_ready()` for `_touch_controls` to live on — `_apply_orientation()` needs somewhere to
## rotate, the same reason it exists before the controls question used to be answered.
var _touch_layer: CanvasLayer
var _summary: CanvasLayer
var _pause: PauseScreen
var _title: TitleScreen
## The small corner symbol a write flashes — see `SaveIndicator`'s own doc. Built once in
## `_ready()`, never under `--start-escape` (the finale never saves, being reachable only behind a
## dev flag today).
var _save_indicator: SaveIndicator
## Owns the `--follow` camera and the event id it tracks between frames — the one piece of
## `DevRig` (`src/dev/dev_rig.gd`) that has to survive across calls, so it is the one piece kept
## on an instance rather than called as a `static`. The `--spawn`/`--overview`/`--meters`/
## `--day-length` lookups against the live city need no instance and are called on `DevRig`
## itself.
var _dev_rig := DevRig.new()
## Dev spawn and meter overrides apply to the opening day only; every later day starts on
## the doorstep with a fresh baby, like the game intends.
var _first_day := true
var _run_over := false
var _ending_shown := false
## Whether the title screen is up, with the city running behind it and nobody in it.
var _in_the_title := false
## Whether the day currently in `_day` is one the player has actually started controlling, as
## opposed to one that exists but is waiting behind a screen she has not yet dismissed — the
## title, on a fresh day 1, or the pause this milestone opens a resumed run behind. Read by
## `_day_under_way_for_save()`; a save written before this flips can never cost the day it names
## anything on the *next* load, because nothing has happened in it yet. Flipped by
## `_engage_the_day()`, called from `_on_title_start()` and `_on_pause_resumed()` — that function,
## not a bare assignment, because the transition itself has to write the save (see its own doc) —
## and set explicitly `true` in `_on_summary_continued()`, which reaches no gating screen at all
## between one day and the next.
var _day_engaged := false

## The pause screen's own line for a game resumed from a save whose day was under way — drafted
## here rather than on `PauseScreen` itself, the same way every other screen's day-specific text is
## assembled in `main.gd` and only drawn by the screen it is handed to.
const _RESUMED_DAY_LOST_NOTE := \
		"Left before the day ended. That cost a nerve — it starts over from dawn."

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
	# Before either boot path — this is the one thing `?debug=1` adds on top of the readout, and
	# it has to reach the escape scene's own boot too. Gates itself on `_readout_requested` rather
	# than being gated at the call site, the same shape `_add_debug_layers()` gates itself on
	# `_debug`. See `_add_debug_mode_note()`'s own doc for why nothing afterwards may remove it.
	_add_debug_mode_note()
	# Same reason and the same gate as the note above — the graph has to exist before either boot
	# path so `_ready_escape()` finds it already built. See `_add_frame_graph()`'s own doc.
	_add_frame_graph()
	# `--start-escape` is a different boot entirely — no title, no city, no day — so it branches
	# before any of the ordinary run's own scaffolding exists. See `_ready_escape()`.
	if _escape_scene_requested:
		_ready_escape()
		return
	# Starts in the shape it should have on this build rather than trusting the scene file's own
	# default (`true`): every later flip of it is relative to whichever screen is up, and a boot
	# path that never reaches one of them should still open with the right answer.
	# `_layer_readout_on` defaults `true`, so this is `_debug or _readout_requested` alone on an
	# unflagged run — the fourth debug layer starts on, the same as it always has.
	_set_readout_visible((_debug or _readout_requested) and _layer_readout_on)
	# Tried before a fresh run is started, so a resumed run keeps the seed, the day and everything
	# else it held rather than being handed a new one. `GameSave.uses_save()` is the one gate every
	# read and write of the save goes through, so a dev flag, a headless boot or a release build
	# with nothing on disk yet all fall straight through to `resume.is_empty()` and an ordinary
	# fresh run below — see `GameSave`'s own doc.
	var resume := GameSave.try_resume()
	if resume.is_empty():
		GameState.start_run(DevFlags.seed_override())
		GameState.day = DevFlags.day_override()
	# After the run seed is settled and before anything is generated, so the log opens on the
	# seed it is a trace of. Off with `-- --no-telemetry`; on otherwise, because a trace
	# behind a flag is a trace the person playtesting has to remember to turn on. This is a
	# player-facing opt-out rather than developer furniture, so it is not gated by `DevFlags`.
	if not "--no-telemetry" in OS.get_cmdline_user_args():
		Telemetry.begin_run(GameState.run_seed, _somebody_is_playing())
	# A save whose day was under way when it was written loses that day, through the same code
	# path an ordinary lost day takes — one nerve, the resistance given back, the same day again,
	# the last nerve ending the run exactly as it does there. Applied before anything downstream
	# (the HUD, the city's own act) ever reads a nerve count or a resistance state that has not
	# been charged yet. `_run_over` mirrors `_on_day_finished()`'s own variable, so the tail of
	# this function shows the same ending screen a run that ends there does.
	if resume.get("day_under_way", false):
		_run_over = not GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)

	_city = CITY.instantiate()
	add_child(_city)
	_pauses_with_the_game(_city)
	var elapsed := Time.get_ticks_msec()
	_city.build(CityGenerator.generate(GameState.run_seed))
	print("[Main] city generated in %d ms (seed %d)" % [
		Time.get_ticks_msec() - elapsed, _city.map.seed_used])
	# On the doorstep before her own `Camera2D` exists, so the two frames `_warm_the_pictures()`
	# awaits below draw the ground the title screen and the day itself will, rather than the
	# world's default identity transform — see `_new_boot_camera()`'s own doc. Freed once
	# `_start_day()` has put her camera in the same place for real.
	var boot_camera := _new_boot_camera(_city.map.doorstep_world_position())
	await _warm_the_pictures(boot_camera.global_position)

	_player = _make_player()
	_city.add_entity(_player)
	_player.set_camera_limits(_city.camera_bounds())
	_baby = _player.get_node("Baby")

	_hud = HUD.instantiate()
	add_child(_hud)
	_add_danger_edge()
	_add_excitement_halo()
	_add_debug_layers()
	_add_route_lines()
	_add_touch_controls()
	# Above every screen this boot goes on to build — see `SaveIndicator`'s own doc for why it is
	# its own layer rather than a node on the pause screen, the day summary or the HUD.
	_save_indicator = SaveIndicator.new()
	_save_indicator.name = "SaveIndicator"
	add_child(_save_indicator)
	_summary = DAY_SUMMARY.instantiate()
	add_child(_summary)

	# Deliberately not `_pauses_with_the_game`: a pause screen that pauses with the game cannot
	# unpause it. It inherits ALWAYS from this node, which is what it wants.
	_pause = PAUSE_SCREEN.instantiate()
	add_child(_pause)
	# So `_pause.open()`/`close()` can stash and restore the heading she carried into an ordinary
	# Esc-pause — see `PauseScreen._touch_controls`'s own doc. `_add_touch_controls()` already ran
	# above, so `_touch_controls` exists by now.
	_pause.set_touch_controls(_touch_controls)

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
	# `_player.reset_at()` inside the call above has just put her own camera exactly where the
	# boot camera was standing in for it, so freeing it now hands the viewport's current camera
	# straight to hers — see `_new_boot_camera()`'s own doc for why freeing is what does that.
	boot_camera.free()

	if DevFlags.overview_requested():
		DevRig.make_overview_camera(self, _city, get_viewport_rect().size)
	_dev_rig.setup_follow_camera(self)

	var screenshot := AutoScreenshot.from_command_line()
	if screenshot:
		add_child(screenshot)

	# A run resumed from a save never reaches the title, and reaches at most one of the two screens
	# `_show_resume_outcome()` picks between instead. Mutually exclusive with every dev-flag branch
	# underneath it: `resume` is only ever non-empty when `GameSave.uses_save()` held, which is
	# `false` for every one of them (see that function's own doc), so a resumed boot and a rig boot
	# can never both be true here.
	if not resume.is_empty():
		_show_resume_outcome(resume)
		return

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

## Picks between the two screens a resumed boot can land on, and is the whole of what a load-time
## resume looks like once `GameState` already carries the save's own fields and, if the save's day
## was under way, has already paid for it through `GameState.finish_day()` — see `_ready()`'s own
## call to it, just above where this is reached. Pulled into its own function so a test can drive
## the outcome directly against a bare `_pause`/`_summary`, without paying for the whole boot this
## is normally reached from.
func _show_resume_outcome(resume: Dictionary) -> void:
	if _run_over:
		# The last nerve the load itself spent — same ending, same screen, as a run that reaches
		# zero nerves any other way.
		_ending_shown = true
		_summary.show_ending(GameState.ending)
		return
	# `_day_engaged` is still `false` here — see its own doc — so closing again from this screen
	# before pressing continue costs nothing more than the load already did (or nothing at all,
	# for a save written at a day's own summary).
	_pause.open(_RESUMED_DAY_LOST_NOTE if resume["day_under_way"] else "")

## `--start-escape`'s own boot: the whole escape sequence, which is the run's ending played behind
## a flag rather than reached from day 14's summary. Section one is the building — the third
## floor's hallway, her at the door with the baby asleep in her arms, and the way down past the
## barricaded entrance into the basement — and the service door hands over to section two, the
## city with nobody in it and one way out of it. `DevFlags.start_escape_at()`'s optional value
## teleports straight to any of the building's other six parts, or to `city` for section two on
## its own, so a rig or a person can look at one without walking there.
##
## No title and no `ResistanceDirector`: the run behind this is not played, so there is nothing to
## resume and no subquest to advance. What *is* built is the clock (`FinaleController`), the HUD
## it draws on, and the summary the epilogue needs.
func _ready_escape() -> void:
	# Guarded here too, not only at the call site in `_ready()` — the same shape
	# `_add_debug_layers()` reads `_debug` in, so a test can call this directly and check the
	# release shape without also driving the rest of `_ready()`.
	if not _escape_scene_requested:
		return
	_set_readout_visible((_debug or _readout_requested) and _layer_readout_on)
	GameState.start_run(DevFlags.seed_override())
	# Same opt-out and the same reasoning as the ordinary run: a trace behind a flag nobody
	# remembers to turn on is a trace nobody gets, and `P`/`B` (`_snapshot_now()`/`_start_burst()`)
	# both need an active log to write anything at all — see `Telemetry.start_burst()`'s own
	# "no drawable viewport" refusal, which is really "no active log", not a rendering question.
	if not "--no-telemetry" in OS.get_cmdline_user_args():
		Telemetry.begin_run(GameState.run_seed, _somebody_is_playing())
	# The second boot entry point `TextureResolver.warm()` has to reach — see `_warm_the_pictures()`
	# — since the epilogue draws its own pictures (the building's props, the city's events) and is
	# reached without ever passing through `_ready()`'s own call above. This path awaits the same
	# way `_ready()` does before anything of the world exists — neither `_interior` nor `_city` is
	# built yet, whichever section this run opens on — so it needs the same boot camera for
	# `_warm_the_halo_shader()`'s probe to have a screen to draw on; world origin is as good as any
	# other point, since nothing is in the tree yet to show a wrong corner of.
	var boot_camera := _new_boot_camera(Vector2.ZERO)
	await _warm_the_pictures(boot_camera.global_position)

	_hud = HUD.instantiate()
	add_child(_hud)
	# The one thing the escape changes about the HUD: the clock reads to the millisecond.
	_hud.set_finale(true)
	_add_touch_controls()
	_summary = DAY_SUMMARY.instantiate()
	add_child(_summary)
	_summary.continued.connect(_on_finale_summary_continued)
	_summary.restart_requested.connect(_restart_run)

	# Built but not opened — same reasoning `_ready()` builds `_title` up front for the ordinary
	# run: the epilogue's own continue button needs somewhere to send her rather than building a
	# screen the moment it is first asked for.
	_title = TITLE_SCREEN.instantiate()
	add_child(_title)
	_title.start_requested.connect(_on_escape_title_start)
	_title.quit_requested.connect(_quit)

	_finale = FinaleController.new()
	_finale.name = "Finale"
	add_child(_finale)
	_pauses_with_the_game(_finale)
	_finale.section_started.connect(_on_finale_section_started)
	_finale.escaped.connect(_on_finale_escaped)

	var start_at_the_city := _escape_start_part() == "city"
	if start_at_the_city:
		_build_the_finale_city()
	else:
		_build_the_escape_building()

	_apply_orientation()
	_finale.begin(FinaleController.Section.CITY if start_at_the_city
			else FinaleController.Section.BUILDING)
	# `begin()` just emitted `section_started` synchronously, which is what puts her (and her own
	# camera) at this section's own start position — see `_on_finale_section_started()`. Freeing
	# now hands the viewport's current camera straight to hers, the same moment `_ready()` frees
	# its own boot camera.
	boot_camera.free()

	if DevFlags.overview_requested() and _city:
		DevRig.make_overview_camera(self, _city, get_viewport_rect().size)

	var screenshot := AutoScreenshot.from_command_line()
	if screenshot:
		add_child(screenshot)

## All entry points bind the run's existing choice before the rig enters the tree or draws.
func _make_player() -> Stroller:
	var player: Stroller = STROLLER.instantiate()
	player.is_male = GameState.player_is_male
	return player

## Section one's world: the building, her in it, and the events inside it.
func _build_the_escape_building() -> void:
	_interior = InteriorScene.new()
	_interior.name = "Interior"
	add_child(_interior)
	_pauses_with_the_game(_interior)
	_interior.build()
	_interior.exit_requested.connect(_on_escape_exit_requested)

	_player = _make_player()
	_player.carrying = true
	_player.slope_dir_at = _interior.slope_dir_at
	_interior.add_entity(_player)
	_player.set_camera_limits(_interior.camera_bounds())
	_baby = _player.get_node("Baby")

	_interior_events = InteriorEvents.new()
	_interior_events.name = "InteriorEvents"
	add_child(_interior_events)
	_pauses_with_the_game(_interior_events)
	_interior_events.setup(_interior, GameState.day_rng(GameState.day, "finale-interior"))

## Section two's world: the city she knows with nobody in it, and the finale's own plan on it.
##
## The city is generated from the run seed exactly as an ordinary run's is, so the streets, the
## parks and the two exits are the ones she has walked for fourteen days. What is different is
## everything laid *on* it: `City.start_finale()` dresses the blocks without growing a day's route
## tree, closures or region wall; the crowd is cleared and never started, since *"no regular cars
## or regular people on the street"*; and `EventManager.start_finale()` takes this scene's own plan
## instead of the catalogue's day.
func _build_the_finale_city() -> void:
	_city = CITY.instantiate()
	add_child(_city)
	_pauses_with_the_game(_city)
	_city.build(CityGenerator.generate(GameState.run_seed))
	GameState.city_state.begin_day(_city.map.block_plans, GameState.day)
	_city.start_finale(GameState.city_state, GameState.day)
	_city.set_act(GameState.current_act())
	# Night, and fixed there: the escape happens after the last day and the clock is the tension
	# rather than the light, so the sky does not run itself down over the sequence.
	_city.set_daylight(0.0)
	# Never `Crowd.start_day()`: a cleared crowd is the whole of "nobody in it", and clearing is
	# the one call this file makes into `src/crowd/`.
	_city.crowd.clear()

	if not _player:
		_player = _make_player()
		_player.carrying = true
		_city.add_entity(_player)
		_baby = _player.get_node("Baby")
	else:
		# Out of the building and onto the street: the same rig, reparented, with the stairwell's
		# own slope redirection dropped — there are no flights outdoors, and a `Callable` left
		# pointing at the interior would answer for tiles on a map she is no longer standing on.
		_player.slope_dir_at = Callable()
		_player.get_parent().remove_child(_player)
		_city.add_entity(_player)
	_player.set_camera_limits(_city.camera_bounds())
	# The **tiles** the chains end on rather than the points `CityEdge` draws its pictures at: the
	# portal's own face is anchored on the map edge, past the last ground she can stand on, so a
	# reach measured from it would have to be wide enough to cover the difference and would then
	# also cover the street before it. `FinalePlanner.exit_tile()` is the carriageway under the
	# portal, which is where being out of the city actually happens.
	_finale.set_exits(
			_city.map.tile_to_world(FinalePlanner.exit_tile(_city.map, CityEdge.Kind.TUNNEL)),
			_city.map.tile_to_world(FinalePlanner.exit_tile(_city.map, CityEdge.Kind.BRIDGE)))
	_add_danger_edge()
	_add_excitement_halo()
	_add_debug_layers()
	_add_route_lines()
	# Three of the layers above are `CanvasLayer`s built after the boot's own orientation pass, so
	# the rotation is applied again rather than left for the next time the window changes shape —
	# see `_apply_orientation()`, which is idempotent and is asked the same question every frame.
	_apply_orientation()
	_plan_the_finale_city()

## Today's finale plan, rebuilt from the run seed every time section two begins — on the first
## walk out of the service door and on every restart after a loss. Deterministic, so a restarted
## section is the same city rather than a thinner one: a plan that had been half spent would
## quietly reward losing.
func _plan_the_finale_city() -> void:
	var elapsed := Time.get_ticks_msec()
	var plan := FinalePlanner.plan(_city.map, GameState.day_rng(GameState.day, "finale"))
	_city.events.start_finale(plan.placements, _finale_start_position())
	# Printed as well as logged, for the same reason `_start_day()` prints the day it just built:
	# the shape of the walk is the one thing worth knowing before anything else in the log means
	# anything, and a run with telemetry off still has a console.
	print("[Main] finale planned in %d ms (seed %d): %s"
			% [Time.get_ticks_msec() - elapsed, _city.map.seed_used, plan.summary()])
	Telemetry.note("plan", "finale: %s" % plan.summary())

## `DevFlags.start_escape_at()`'s raw word, mapped onto the `InteriorMap.PARTS` waypoint to
## teleport to before the first frame — `"hallway_third"`, her own door, for every word this does
## not recognise, which covers both "not given" and a typo alike; `InteriorScene.part_world_
## position()` falls back the same way for a part name it does not recognise, so the two defaults
## agree without one calling the other. Kept here rather than in `DevFlags`, the same split
## `ending_override()` leaves to its own caller, since mapping a word onto a part name only this
## file's own `InteriorScene` understands is not that class's job.
##
## `"city"` is the one answer that is not a part of the building: it boots section two on its own,
## with no building built at all, so a rig or a person can look at the finale's streets without
## walking down three floors first. `_ready_escape()` is what reads it that way.
func _escape_start_part() -> String:
	return escape_part_for(DevFlags.start_escape_at())

## The mapping itself, with the command line taken out of it — nothing in the suite can put a word
## on a real `OS.get_cmdline_user_args()`, so the word and what it means are separated here the
## same way `DevFlags.parse_layers()` separates `--layers`' own parsing from reading argv.
static func escape_part_for(raw: String) -> String:
	match raw:
		"city":
			return "city"
		"stairwell:left":
			return "stairwell_left"
		"stairwell:right":
			return "stairwell_right"
		"lobby":
			return "lobby"
		"basement":
			return "basement"
		"floor:2":
			return "hallway_second"
		"floor:1":
			return "hallway_first"
		_:
			return "hallway_third"

## `InteriorScene.exit_requested` fires once the emergency exit's own fade has covered the screen
## — see `InteriorScene._start_exit()`. The service door is the join between the two sections, so
## what is behind the black is the street beside the home block rather than a title screen: the
## city is built on this frame, the building is left standing on its own map with nobody on it,
## and `FinaleController.enter_city()` carries the same clock across.
##
## The fade is not reversed here. `InteriorScene` holds the black at full opacity from the moment
## it emits, and `_on_finale_section_started()` clears it once she has been put down on the street,
## so nothing of the city is seen being assembled.
func _on_escape_exit_requested() -> void:
	_build_the_finale_city()
	_finale.enter_city()

## A section has begun — the first time, or again after a loss. Where she goes is this file's
## answer because only this file holds both worlds; the hint line is said on the first entry only,
## *"like normal tutorial hints"*, so a retry is not lectured about what it is already doing.
func _on_finale_section_started(section: int, restarted: bool) -> void:
	_summary.dismiss()
	_hud.visible = true
	if section == FinaleController.Section.BUILDING:
		var start_at := _interior.start_world_position()
		if not restarted:
			start_at = _interior.part_world_position(_escape_start_part())
		_player.reset_at(start_at, Vector2.UP)
		if _interior_events:
			_interior_events.restart()
		if not restarted:
			_hud.say_once("Escape the apartment")
	else:
		# A restart of section two replans it: see `_plan_the_finale_city()`.
		if restarted:
			_plan_the_finale_city()
		_player.reset_at(_finale_start_position(), Vector2.DOWN)
		_city.events.stream_around(_player.global_position)
		if not restarted:
			_hud.say_once("Exit the city")
	# The baby starts every attempt asleep with sleepiness full — *"the player holding the sleeping
	# baby (sleep bar is full)"* — which is also what makes a restart playable at all: the meter
	# that just reached a hundred is what lost the section.
	_baby.reset()
	_baby.force_sleep()
	if _interior:
		_interior.clear_fade()

## Where section two starts and restarts: the service exit, on the street beside the home block.
func _finale_start_position() -> Vector2:
	return FinalePlanner.service_exit_world_position(_city.map)

## The tunnel mouth or the bridge deck, reached. The sequence ends on a summary screen with the
## way out behind her and nothing triumphant on it — see `DaySummary.show_finale()`.
func _on_finale_escaped(exit_kind: int) -> void:
	_hud.visible = false
	_summary.show_finale(exit_kind, FinaleController.length() - _finale.time_remaining())

## The epilogue's own continue button. Behind the flag there is no run for the escape to be the
## ending *of*, so continuing goes back to where a run begins — the title screen, which then
## reloads the scene and walks the whole sequence again. Opening the screen rather than reloading
## straight away is what `_on_escape_exit_requested()`'s own note used to say about this boot: a
## reload reads `--start-escape` off the same command line, so the screen would never be seen.
func _on_finale_summary_continued() -> void:
	_summary.dismiss()
	get_tree().paused = true
	_hud.visible = false
	_title.open(true)

## The title screen's own start button, reached after the epilogue — there is no larger run
## behind this debug entry to resume, so the only thing left worth doing with it is walking the
## escape sequence again from the top. `--start-escape` is read fresh on the reload, so this is
## also "run it again" for anybody testing the walk down.
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
	# `_day_engaged`'s own doc says what this is for: a day freshly loaded from a save sits behind
	# this screen unplayed, and closing again from there must not cost a second nerve for a day
	# nothing has yet been done in. An ordinary `Esc` pause reaches this too, harmlessly — the day
	# is already engaged by the time a player can even open it.
	_pause.resumed.connect(_on_pause_resumed)

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
## is a statement about a player who is not there. The frame graph comes off with them too — it is
## independent of `4` (see `_layer_graph_on`'s own doc), not of the title, so this hides it directly
## rather than through `_set_readout_visible()`, which no longer reaches it. **The ring itself is
## untouched**: only a `6` toggle-off clears it (`_toggle_debug_layer()`), so a graph that was
## recording keeps what it already has across the trip through this screen.
func _open_the_title() -> void:
	_in_the_title = true
	# Guarded the same shape `_on_title_start()`'s own final line already is, and for the same
	# reason: `tests/test_main.gd` drives this function on a script-only `main` with no tree behind
	# it, to reach the graph-hiding line below without the rest of this function's live-tree
	# dependencies. Never false in the running game, where this only ever fires on a real `main`
	# already in the tree.
	if is_inside_tree():
		get_tree().paused = true
	_city.process_mode = Node.PROCESS_MODE_ALWAYS
	_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	_player.stand_aside()
	_hud.visible = false
	_edge_layer.visible = false
	_set_readout_visible(false)
	if _frame_graph:
		_frame_graph.visible = false
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
	# The day behind this screen becomes the one she is actually playing — see `_engage_the_day()`'s
	# own doc for why this has to write a save immediately rather than only flip the flag.
	_engage_the_day()
	_title.close()
	_player.step_back_in()
	_pauses_with_the_game(_city)
	_hud.visible = true
	_edge_layer.visible = true
	# Not an unconditional `true`: this is the one place the readout was coming back regardless
	# of build, since `_open_the_title()` always turns it off and this was the only place that
	# turned it back on. `and _layer_readout_on` so a `4`-toggled-off readout stays off across a
	# trip through the title rather than snapping back on underneath it.
	_set_readout_visible((_debug or _readout_requested) and _layer_readout_on)
	# The graph's own answer to the same question, off `_layer_graph_on` rather than
	# `_layer_readout_on` — a `6`-toggled-on graph reappears here with whatever the ring already
	# held, since `_open_the_title()` only hid it and never cleared it.
	if _frame_graph:
		_frame_graph.visible = _layer_graph_on
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

## A plain camera made current before either boot path's own player exists, so the two frames
## `_warm_the_pictures()` awaits below draw `ground` — the doorstep, in `_ready()`'s case — rather
## than the world's default identity transform, whose origin sits at the top-left of whatever is
## in the tree under it.
##
## **Freeing it is what hands the viewport's current camera to the player's own.** A `Camera2D`
## that exits the tree while it is the viewport's current one looks for another enabled camera on
## the same canvas and makes that one current in its place, and the stroller's own `Camera2D`
## (`scenes/player/stroller.tscn`) — sitting dormant since it entered the tree while this one was
## already current — is the only other camera either boot path ever has in the tree by then.
func _new_boot_camera(ground: Vector2) -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "BootCamera"
	camera.global_position = ground
	# The stroller's own play zoom (`scenes/player/stroller.tscn`), so the warm-up frames read at
	# the scale the title screen and the day itself will.
	camera.zoom = Vector2(2, 2)
	# Matches the stroller's own `Camera2D` (`process_callback = 0` in the scene) rather than the
	# default idle callback — see the **godot** skill's "A paused `Camera2D` with smoothing on
	# never arrives": with physics interpolation on project-wide, the default leaves the engine to
	# override this itself and warn about it once a run.
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	_pauses_with_the_game(camera)
	camera.make_current()
	return camera

## M147, "every picture loaded before it is needed": loads every transfer PNG and gets the halo's
## shared shader compiled before either boot path's own `_start_day()`/`_finale.begin()`, so the
## first frame that actually needs a picture or a halo never pays for either. Printed beside
## "city generated in N ms" — the same shape `_plan_the_finale_city()` prints its own line beside
## — because a phone's longer first load belongs next to the other number that already tells a
## reader how long the boot took.
##
## `ground` is where the boot camera made current just before this call is standing — see
## `_new_boot_camera()` — and is handed straight through to `_warm_the_halo_shader()`, which needs
## a point it can be sure is on screen.
func _warm_the_pictures(ground: Vector2) -> void:
	var elapsed := Time.get_ticks_msec()
	var loaded := TextureResolver.warm()
	await _warm_the_halo_shader(ground)
	print("[Main] %d pictures warmed in %d ms" % [loaded, Time.get_ticks_msec() - elapsed])

## Gets the Compatibility renderer to compile the halo's shader program before a real halo ever
## draws with it. **Godot 4.7 has no precompile call for this renderer** — `RenderingServer`'s own
## pipeline cache is a Forward+/Mobile (RenderingDevice) feature, and the engine's own proposal
## tracker still carries "Add shader precompilation to the Compatibility rendering method" as an
## open request — so the only lever left is a real draw call: a throwaway `Node2D` draws one
## transparent pixel with `EntityHalo.shared_material()` and is freed the frame after.
##
## **At `ground`, not off in the distance.** A canvas item outside the camera's visible rect is
## culled before it reaches the renderer — see M139, "one atlas for the crowd", on why an
## off-screen `CrowdAgent` costs nothing per frame — and a culled draw would compile nothing,
## defeating the whole pass. `ground` is the boot camera's own `global_position` (see
## `_new_boot_camera()`, made current by both boot paths before `_warm_the_pictures()` is ever
## called), so a probe placed there sits exactly at that camera's own screen centre — on screen
## regardless of zoom or viewport size. Fully transparent (`halo_colour`'s instance uniform
## default, never set here) makes it imperceptible regardless: the GLSL program compiles from the
## material and the draw call alone, never from the pixels it happens to write.
##
## **Two awaits, not one.** `SceneTree.process_frame` fires *before* the frame it names is drawn —
## `DaySummary._acknowledge_and_continue()` confirms this directly against `RenderingServer`'s own
## `frame_pre_draw`/`frame_post_draw` — so a single await would free the probe before its queued
## draw ever reached the renderer, and the shader would still compile late, on the first real halo.
func _warm_the_halo_shader(ground: Vector2) -> void:
	var probe := Node2D.new()
	probe.name = "HaloWarm"
	probe.global_position = ground
	probe.material = EntityHalo.shared_material()
	probe.draw.connect(func() -> void: probe.draw_rect(Rect2(Vector2.ZERO, Vector2.ONE), Color.WHITE))
	add_child(probe)
	_pauses_with_the_game(probe)
	probe.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	probe.queue_free()

## The one thing `?debug=1` (or `--debug`) adds beyond the readout itself: a fixed note, for the
## whole session, that nothing removes — not the `4` key, not a press, not `_open_the_title()`
## hiding `_status` around it. **Absent from the tree when `_readout_requested` is `false`**, the
## same "gated rather than merely hidden" shape `_add_debug_layers()` uses for `_debug`: an
## ordinary debug build shows the readout without this note, since nobody running one needs
## telling it is one. `DebugModeNote` is its own small node (`src/dev/debug_mode_note.gd`) added
## here rather than through `scenes/ui/hud.tscn`/`src/ui/hud.gd`, which this milestone leaves
## untouched; nothing here ever sets its `visible` to `false` or frees it.
func _add_debug_mode_note() -> void:
	if not _readout_requested:
		return
	_debug_mode_note = DebugModeNote.new()
	_debug_mode_note.name = "DebugModeNote"
	add_child(_debug_mode_note)

## The rolling bar graph of the last frames' own lengths — see `FrameGraph`. **Absent from the tree
## when neither `_debug` nor `_readout_requested` holds**, the same "gated rather than merely
## hidden" shape `_add_debug_mode_note()` uses: a release page nobody asked `?debug=1` of never
## builds it, so it never pays for a ring nobody can see. Parented under `_status`'s own
## `CanvasLayer` rather than under `_debug_layers` — it lives beside the readout, on the readout's
## own key, not among the four `_debug_layers` keys `1`-`3` and `5` toggle.
##
## Left-aligned with `_status` (`offset_left`, 960px in the design box) and placed a fixed 600px
## below its own top (`offset_top`, 14px): the readout's block gains its 30th line only under
## `--skip`, and 30 lines at this label's own font size (17px tall, 3px between lines — measured
## off a headless `Label`, since neither number is exposed as a theme constant) reach about 597px
## from the block's own top, so a fixed offset clears both shapes with a few pixels to spare
## instead of re-measuring `_status`'s rendered height every frame for a difference that never
## exceeds one line. **Below the block, not above it**, because the joystick focus ring `docs/
## DECISIONS.md` (M139, "the phone reading") already finds under the readout's own lines — a 48px
## ring centred at y=480 in the same design box reaches no further down than y=528 — comfortably
## above this box's own top at y=614, so the graph clears the ring by placement rather than by
## being moved out of its way.
func _add_frame_graph() -> void:
	if not (_debug or _readout_requested):
		return
	_frame_graph = FrameGraph.new()
	_frame_graph.name = "FrameGraph"
	_frame_graph.text_colour = _status.get_theme_color("font_color")
	_frame_graph.position = Vector2(_status.offset_left, 614.0)
	_layer_graph_on = _graph_starts_on(DevFlags.spikes_requested(), DevFlags.layers_override())
	_frame_graph.visible = _layer_graph_on
	_status_layer.add_child(_frame_graph)

## Whether `_layer_graph_on` starts `true`, with the command line taken out of it — pulled out the
## same way `escape_part_for()` separates what `DevFlags.start_escape_at()`'s word means from the
## word itself, so a test can drive the policy without a real `--spikes` or `--layers 6` on this
## process's own command line. `--spikes` already means somebody is chasing a stutter, and
## `--layers` naming `6` is the same "reproducible without a keypress" request `5` already answers
## for `_route_lines` (`DevFlags.layers_override()`'s own doc).
static func _graph_starts_on(spikes_requested: bool, layers: Array[int]) -> bool:
	return spikes_requested or 6 in layers

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
	print("[DebugLayers] keys:  1 fields   2 shadows   3 bounding boxes   4 readout   5 routes")

## The day's planned routes — see `RouteLines`. **Absent from the tree outside a debug build**, the
## same "null, not merely invisible" shape `_add_debug_layers()` uses. A sibling of `_debug_layers`
## rather than a fourth case on it: that class queries the live geometry every frame it is asked to
## draw, and this one draws a fixed plan that only changes once a day, at `_start_day()`'s own call
## to `refresh()` — so it earns no `_process()` and no place inside a class built around one.
##
## Parented under `Main` directly rather than under `_debug_layers` — the two are independent
## layers with independent lifetimes, and nesting one inside the other would make "toggle routes
## off" and "toggle every geometry layer off" the same tree edit for no reason.
func _add_route_lines() -> void:
	if not _debug:
		return
	_route_lines = RouteLines.new()
	_route_lines.name = "RouteLines"
	_route_lines.z_index = 3
	_route_lines.setup(_city.map)
	_route_lines.apply_initial_state(DevFlags.layers_override())
	add_child(_route_lines)
	_pauses_with_the_game(_route_lines)

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
		_hud, _edge_layer, _touch_layer, _summary, _pause, _title, _status_layer, _save_indicator]
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
	# Before the announcement and before anything is placed: this is where the run photographs
	# what the resistance had done, and a lost day gives exactly that back — so the photograph has
	# to be taken while it is still true of the attempt about to be played. See
	# `GameState.begin_day()`.
	GameState.begin_day()
	# The day is announced first, so listeners clear yesterday's state before anything is
	# placed in today — announcing it afterwards wiped the contact the director had just
	# reported, and the HUD showed nothing.
	EventBus.day_started.emit(GameState.day)

	# Before anything is placed, because placing it is what writes the day's `arc`, `roll` and
	# `contact` entries and they belong under today's header rather than yesterday's.
	Telemetry.begin_day(GameState.day, GameState.current_act(), GameState.run_seed,
			_city.map.seed_used, DevRig.day_length(GameState.day))

	# Events and the contact are placed before the player, so --spawn has something to find
	# and so nothing spawns on top of her.
	# The city becomes today's city before anything is placed in it: the scheduler has to
	# see the parks that are still parks, not yesterday's.
	GameState.city_state.begin_day(_city.map.block_plans, GameState.day)
	_city.start_day(GameState.city_state, GameState.day,
			GameState.day_rng(GameState.day, "closures"))
	# The tree `_city.start_day()` just grew is today's whole plan, so the picture only has to be
	# rebuilt here — once a day — rather than read fresh every frame the way `_debug_layers` reads
	# the live geometry state. See `RouteLines.refresh()`.
	if _route_lines:
		_route_lines.refresh(_city.route_tree())
	# The day is planned around the doorstep first, because `--spawn event` needs a plan to
	# find an event in. The plan is the whole day and the *world* is only what is within
	# reach, so where she actually starts decides what exists on the first frame —
	# which is why the crowd is populated after the spawn position is settled rather than
	# before it, and why the events are streamed a second time once it is known.
	var doorstep := _city.map.doorstep_world_position()
	_city.events.start_day(GameState.day, GameState.day_rng(), GameState.consumed_one_shots,
			doorstep)
	# The day's seals are planned inside the call above, and a `fallen_tree_seal` takes a street
	# tree's own pit. `City.start_day` already emptied the pits its own closures took, so this is
	# the second half of one refresh rather than a repair of it — see `City.refresh_street_trees`.
	_city.refresh_street_trees()
	var start_at := DevRig.spawn_position(_city, _resistance) if _first_day else doorstep
	_city.events.stream_around(start_at)
	_city.crowd.start_day(GameState.day, GameState.day_rng(GameState.day, "crowd"), start_at)
	# The smallest wiring for the checkpoint gates: `City.region_plan()` is already valid by here
	# (`_city.start_day()` built it above), so the crowd just needs to be told where today's gates
	# are — empty before `Tuning.REGION_WALL_FIRST_DAY`, which is a harmless no-op day for `Crowd`.
	_city.crowd.set_gates(_city.region_plan().gates)
	_city.set_act(GameState.current_act())
	_resistance.start_day(GameState.day, GameState.day_rng(GameState.day, "resistance"),
			DevRig.day_length(GameState.day))
	_player.reset_at(start_at)
	_baby.reset()
	_day.start(DevRig.day_length(GameState.day))

	# After the day is running, not before: the override can put the baby straight to
	# sleep, and start() would have reset the phase that announcement just set.
	if _first_day:
		DevRig.apply_meter_override(_baby)
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

	# The dawn write — one of the four moments a run is saved (see docs/MECHANICS.md, "Saving and
	# resuming"). `_day_engaged` says whether this dawn is one the player has actually started
	# controlling yet (see its own doc); the value is exactly what the save should carry, since
	# closing behind a title or a resume-pause that has not been dismissed must not cost anything
	# more than a load already has.
	_save_now(_day_engaged)

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
	# Captured here, before anything below touches `_day`, so the summary's clock reads the
	# instant the day actually ended rather than whatever `_day.time_remaining` holds by the time
	# `show_day()` is called several lines down. Clamped because `_process()` can call `_end()`
	# one frame after `time_remaining` has gone slightly negative (a timeout checks `<= 0.0` after
	# subtracting `delta`, not the instant it crosses zero), which would otherwise read a few
	# milliseconds past the day's own length.
	var elapsed_seconds := clampf(_day.time_total - _day.time_remaining, 0.0, _day.time_total)
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
	# The day's-end write — one of the four moments a run is saved. Skipped when the run just
	# ended: `GameState._end_run()` (called from inside `finish_day()` above) already cleared the
	# save, and writing here would resurrect a file naming a run that is over.
	if not _run_over:
		_save_now(false)
	_summary.show_day(finished_day, result, _day.failure_reason, GameState.nerves, elapsed_seconds)

func _on_summary_continued() -> void:
	if not _run_over:
		_summary.dismiss()
		# No gate stands between one day's summary and the next day's dawn, unlike the title on a
		# fresh day 1 or the pause a resumed run opens behind — see `_day_engaged`'s own doc.
		_day_engaged = true
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
	# The held restart clears the save — the pause screen's and the day summary's own button both
	# reach this one function, so nothing new has to be drawn for it. A no-op when a finished run
	# already cleared it in `GameState._end_run()`.
	GameSave.clear()
	TitleScreen.note_restart_requested()
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")

## The scene tree's own pause flag, read through `Engine.get_main_loop()` rather than `get_tree()`
## so this can be asked whether or not `main` itself is parented. `get_tree()` logs an
## engine-level error off-tree — the same reason `_on_title_start()` guards it with
## `is_inside_tree()` — and `tests/test_main.gd` drives `_process()` on a script-only instance with
## no tree behind it at all. There is exactly one `SceneTree` for the whole process, whether a
## person is playing or the suite is driving this frame by hand, so asking the engine for it
## answers the same question either way.
func _tree_is_paused() -> bool:
	var loop := Engine.get_main_loop()
	return loop is SceneTree and (loop as SceneTree).paused

func _process(delta: float) -> void:
	# The one place in the running game that finishes a `TextureAtlas` request. It sits above
	# every early return below on purpose: a group is asked for while the city is built or while
	# an event is placed off screen, and the title screen, the interior and the finale all return
	# from this function before reaching the day, so a pump further down would leave an atlas
	# packed and never collected for as long as one of those is on screen.
	TextureAtlas.collect_ready()
	_dev_rig.update_follow_camera(_city)
	# Re-asked every frame rather than only on `size_changed` — see `_apply_orientation()`'s own
	# doc for why a signal alone can latch the wrong answer. The cost is one vector comparison.
	# `get_window()` is null for the script-only instance `tests/test_main.gd` drives straight
	# through `_process()` with no window behind it at all.
	var window := get_window()
	if window and ScreenOrientation.wants_rotation(window.size, _touch_available) != _rotated:
		_apply_orientation()
	if not _player or not _baby:
		return
	if _finale:
		_process_the_finale(delta)
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
	# `GameState.play_seconds` has exactly one owner: this branch, which already knows the phase
	# and (through `_tree_is_paused()`) the pause state. It runs while a day is `WALKING` or
	# `RETURNING` and the tree is not paused — the pause screen and the day summary both leave
	# `phase` here but pause the tree, and a day that has just ended has already left `phase` at
	# `OVER` by the time either one opens, since `DayController._end()` sets it before emitting
	# the signal that shows the summary. The title screen and the interior both `return` above
	# this line, so neither ever reaches it either.
	if _day.phase in [GameEnums.DayPhase.WALKING, GameEnums.DayPhase.RETURNING] \
			and not _tree_is_paused():
		GameState.play_seconds += delta
	_city.set_daylight(_day.fraction_remaining())
	_hud.set_home_guidance(_day.phase == GameEnums.DayPhase.RETURNING,
			_city.map.home_world_position())
	# The bar graph's own ring, fed `delta` itself — `FrameCost` below already discards which frame
	# in a second was the long one, and the graph exists to answer exactly that. Answered here,
	# ahead of the readout's own early return below, because `_layer_graph_on` is this layer's own
	# `6` key and must keep feeding (or stay silent) whatever `4` did to the readout — a
	# `4`-toggled-off readout must not also silence a `6`-toggled-on graph. `push()` itself is a
	# no-op unless `_frame_graph.visible` holds, which `_toggle_debug_layer()` keeps in step with
	# `_layer_graph_on`, so nothing further needs asking here. `if _frame_graph:` because it is
	# `null` under the same release-page terms `_add_frame_graph()` documents, and because a test
	# that drives `_process()` directly (`tests/test_main.gd`) without also calling `_ready()` has
	# never built one either.
	if _frame_graph:
		_frame_graph.push(delta)
	# The developer readout, gated rather than merely hidden: it is a seed, a meter breakdown and
	# what the frame cost (`FrameCost.readout_lines()` — fps, draw calls, objects, primitives and
	# the two loop times, the same six quantities the run log's own `frame` entry carries), which a
	# released build with neither `_debug` nor `_readout_requested` has no business assembling
	# every frame even behind a label nobody can see — and `_nearest_event_text()` below is a scan
	# of every live event.
	# `_layer_readout_on` is this layer's own `4` key: off, the string is not assembled either,
	# the same "gated rather than merely hidden" rule holds.
	if not (_debug or _readout_requested) or not _layer_readout_on:
		return
	# Feeds the process/physics lines' one-second `mean`/`max` window — a readout-only cost, so it
	# is fed only while the readout itself is on, right where the rest of this block is gated the
	# same way. `Time.get_ticks_msec()` rather than `_day.time_remaining` or `GameState.play_seconds`,
	# since the window is about wall-clock stutter and must keep moving through a pause, a
	# compressed `--day-length` and `--invincible`'s own frozen day clock alike.
	FrameCost.sample(Time.get_ticks_msec() / 1000.0)
	var tile := _city.map.world_to_tile(_player.global_position)
	if _build_text == "":
		_build_text = TitleScreen.build_text()
	# The `skip` line names what `_skip_words` is off, directly beneath the seed line, so a
	# screenshot taken under `--skip` says what it measured — absent when nothing is skipped, the
	# ordinary case, so an unflagged readout carries no empty line where this one would go.
	var header := [
		"build %s" % _build_text,
		"seed  %d   day %d" % [GameState.run_seed, GameState.day],
	]
	if not _skip_words.is_empty():
		header.append("skip  %s" % ", ".join(_skip_words))
	_status.text = "\n".join(header + [
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
		"nearest     %s" % _nearest_event_text(),
		"",
	] + FrameCost.readout_lines() + [
		"",
		"incoming    %6.2f /s" % _baby.last_incoming,
		"decay       %6.2f /s" % _baby.last_decay,
		"net         %6.2f /s" % (_baby.last_incoming - _baby.last_decay),
		"",
		"arrows/WASD walk",
		"shift       run",
		"esc         pause  (r restart, q quit)",
	])

## The escape's own per-frame work, in place of the day loop: the doors and the service exit while
## she is in the building, and the two ways out of the city once she is on the street. The
## `EventManager` streams itself around her (`EventManager._physics_process`), so section two needs
## nothing here to keep its own events stocked.
func _process_the_finale(delta: float) -> void:
	if _finale.section == FinaleController.Section.BUILDING:
		if _interior:
			_interior.process_player(_player, delta)
		return
	if _city:
		_finale.check_exit(_player.global_position)

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

## The window losing focus — Alt-Tabbing or clicking away from it, a browser tab going to the
## background — or a phone sending the app away opens the same screen `_pause.open()` above does,
## through the same call: one pause rather than a second kind of it. `_notification()` is the
## caller, on `NOTIFICATION_APPLICATION_FOCUS_OUT` and `NOTIFICATION_APPLICATION_PAUSED`.
##
## **Unlike Esc, this does not open over the day summary or the ending.** Both live behind
## `_summary.is_showing()`, which `_unhandled_input()`'s own Esc guard above does not even ask —
## Esc is a choice the player made to open a second screen over the one already up, and focus loss
## is not a choice at all, so opening over a screen already asking for the player's attention would
## read as the game answering a question nobody asked. The title screen and an already-open pause
## are excluded for the same reason `_unhandled_input()` excludes them.
##
## **Getting focus back does not resume the day.** The pause screen stays up until the player
## continues, the way it does after Esc: somebody coming back to the window has not yet looked at
## the street, and a day that restarts the instant the window is clicked spends their first second
## for them.
##
## `_no_focus_pause` is the override — see `DevFlags.no_focus_pause()` — so a rig's window, which
## usually opens with no focus to lose in the first place, is never handed a picture of this screen
## instead of the day it was sent to look at.
func _pause_on_focus_lost() -> void:
	if _no_focus_pause:
		return
	# `_pause` is never built under `--start-escape` — see `_ready_escape()` — so losing focus does
	# nothing there rather than opening a screen with no ordinary run behind it to pause, the same
	# guard `_unhandled_input()`'s own Esc handler makes.
	if not _pause:
		return
	if _pause.is_open() or _title.is_open() or (_summary and _summary.is_showing()):
		return
	_pause.open()

## `PauseScreen.resumed` — Esc, space or a tap closing an ordinary pause, as well as the moment a
## resumed run's own gating pause is dismissed for the first time. See `_engage_the_day()`'s own
## doc: an ordinary pause reaches this harmlessly (the day was already engaged before it could
## open at all, so `_engage_the_day()` writes nothing the second time), and a resumed run's pause
## is the one case where this is the actual, load-bearing transition.
func _on_pause_resumed() -> void:
	_engage_the_day()

## The one place `_day_engaged` is ever set `true`, called from `_on_title_start()` (day 1's title
## dismissed) and `_on_pause_resumed()` (a resumed run's own gating pause dismissed, or an
## ordinary mid-day pause closing).
##
## **Writes the save immediately, on the transition, rather than leaving the next write to
## whichever of the four ordinary triggers happens next.** The dawn write already on disk for a
## day sitting behind either gate says `day_under_way: false`, since nothing had been played in it
## yet — correct at the time, but wrong the instant the gate opens and stays wrong until a focus
## loss or a quit notification updates it. Those notifications are not guaranteed to ever arrive:
## a crash, a force-kill, or — the ordinary case on mobile web — a backgrounded tab whose page is
## discarded outright all skip them, and the dawn write exists in the first place because exactly
## this class of event cannot be relied on to notify anybody. Left unfixed, the day between the
## gate opening and the next notification would read as "not under way" to a load that catches a
## silent kill in that window, so closing there would cost nothing — every second escape free:
## quit mid-day (pay), resume, dismiss the gate, kill the tab (free).
##
## One function rather than two call sites each writing their own line, so the flip and the write
## cannot drift apart the way they did when this milestone first shipped without this function at
## all — see the commit that added it. No-ops past the first call (`if _day_engaged: return`), so
## an ordinary pause closing on an already-engaged day writes nothing and flashes nothing every
## time Esc is pressed.
func _engage_the_day() -> void:
	if _day_engaged:
		return
	_day_engaged = true
	_save_now(true)

## Whether the day currently in `_day` should be saved as "under way" right now — read by
## `_notification()`'s own focus-loss and quit writes, never by the dawn write, which passes
## `_day_engaged` directly since nothing about `_day.phase` says anything useful before
## `_day.start()` has even run for the attempt in question. `false` before `_day` exists at all
## (the earliest sliver of boot) and once a day has actually ended (`GameEnums.DayPhase.OVER`,
## which `_on_day_finished()` sets before either summary screen comes up) — the phase this is
## really asking about is *whether closing right now would lose anything*, and a day that has
## already resolved into a summary or an ending has nothing left in it to lose.
func _day_under_way_for_save() -> bool:
	return _day_engaged and _day != null and _day.phase != GameEnums.DayPhase.OVER

## Every write goes through here so the symbol only ever flashes for one that actually happened —
## see `GameSave.write()`'s own doc for the runs and moments that draw nothing.
func _save_now(day_under_way: bool) -> void:
	if GameSave.write(day_under_way) and _save_indicator:
		_save_indicator.flash()

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

## `1` fields, `2` shadows, `3` bounding boxes, `4` the readout, `5` the day's routes, `6` the
## frame-time graph — or `0` for anything else. The same echo guard `_debug_snapshot_action()`
## carries, for the same reason: a held key is one request, not a flood of toggles for as long as
## it stays down.
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

## `4` is the readout's own key, answered here rather than on `_debug_layers` because the readout
## lives on `_status`'s pre-existing `CanvasLayer` rather than under that node — see
## `_layer_readout_on`'s own doc. `5` is `_route_lines`' own key, forwarded the same way `1`-`3`
## reach `_debug_layers` — a plain `visible` flip rather than a `set_layer` call, since that node
## draws one thing rather than three. `6` is `_frame_graph`'s own key, on the same terms as `5` but
## answered without going through `_set_readout_visible()` — see `_layer_graph_on`'s own doc for why
## it no longer shares `4`'s switch. Turning it off also empties the ring
## (`FrameGraph.clear()`), so `6` twice leaves a blank graph that only fills again from that moment
## — *(2026-09-15, the player: "spike recording should only be on while the layer is on. that means
## toggling the layer twice will lead to a blank frame array".)*
func _toggle_debug_layer(layer: int) -> void:
	if layer == 4:
		_layer_readout_on = not _layer_readout_on
		_set_readout_visible((_debug or _readout_requested) and _layer_readout_on)
		return
	if layer == 5:
		if _route_lines:
			_route_lines.visible = not _route_lines.visible
		return
	if layer == 6:
		_layer_graph_on = not _layer_graph_on
		if _frame_graph:
			# `and not _in_the_title` so pressing `6` while the title is open (`_unhandled_input()`
			# still reaches this — `main` stays `PROCESS_MODE_ALWAYS` for Esc's own sake) never draws
			# the graph over it; `_on_title_start()` reads `_layer_graph_on` on the way out and shows
			# it then if this left it `true`.
			_frame_graph.visible = _layer_graph_on and not _in_the_title
			if not _layer_graph_on:
				_frame_graph.clear()
		return
	if _debug_layers:
		_debug_layers.set_layer(layer, not _debug_layers.layer_on(layer))

## The one place `_status.visible` is actually assigned — every other spot in this file calls this
## instead, so the readout's own visibility can never fall out of step between the boot, the escape
## boot, the title screen hiding it and `_on_title_start()` bringing it back. **Does not touch
## `_frame_graph`** — the player asked the graph's own switch to be `6`, not `4`, so toggling `4`
## alone leaves it exactly where `_layer_graph_on` already had it. The title screen is a different
## question from `4` (it hides everything about a player who is not there) and still reaches the
## graph, just through its own two call sites (`_open_the_title()`/`_on_title_start()`) rather than
## through this setter, since a title trip must hide it without clearing the ring the way a `6`
## toggle-off does.
func _set_readout_visible(shown: bool) -> void:
	_status.visible = shown

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
## where the world is least finished — a title screen, or a boot that went wrong. Shared by
## `_snapshot_now()` and `_start_burst()` (`B`), which differ only in which `Telemetry` call and
## which noun the trace line names.
func _capture_context() -> String:
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
	return "(%d,%d) | %s | %s" % [where.x, where.y, meters, screen]

func _snapshot_now() -> void:
	Telemetry.snapshot_now("asked for a picture at %s" % _capture_context())

func _start_burst() -> void:
	Telemetry.start_burst("asked for an animation burst at %s" % _capture_context())

func _quit() -> void:
	# Before `Telemetry.end_run()` closes the log, so a `save` entry lands inside the run it is
	# about rather than after the header that closes it.
	_save_now(_day_under_way_for_save())
	Telemetry.end_run()
	get_tree().quit()

## Closing the window is the other way a run ends, and an abandoned run is worth reading —
## every line is already on disk, so this only closes the handle tidily.
##
## `NOTIFICATION_APPLICATION_FOCUS_OUT` is the one this game has exactly one window to lose: it
## fires whenever the OS gives focus to a different application, which is the whole of "Alt-Tabbing
## away" on a single-window desktop app, a browser tab going to the background, or a click on
## another window on the same machine. `NOTIFICATION_WM_WINDOW_FOCUS_OUT` is a **per-`Window`**
## signal instead — the one a game with more than one of its own windows would need to tell which
## of them lost focus, including to another window of the *same* game — and this project never
## builds a second one, so it is not read here.
## `NOTIFICATION_APPLICATION_PAUSED` is a phone sending the whole app to the background. Getting
## focus back (`NOTIFICATION_APPLICATION_FOCUS_IN`/`NOTIFICATION_APPLICATION_RESUMED`) is not
## answered at all — see `_pause_on_focus_lost()`'s own doc for why coming back does not resume.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_now(_day_under_way_for_save())
		Telemetry.end_run()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		# Saved unconditionally, even where `_pause_on_focus_lost()` below is about to return early
		# because the day summary or the title is already up — saving and pausing are separate
		# decisions, and a write here is what lets a browser tab backgrounded on a day summary come
		# back to the next day's dawn for free rather than to whatever the day before it left.
		_save_now(_day_under_way_for_save())
		_pause_on_focus_lost()
