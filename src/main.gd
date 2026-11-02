extends Node2D
## Boot scene: generate the city, drop the player on the doorstep, then the HUD.
##
## **The composition root.** The run's configuration (`config`, a `RunConfig`) is resolved once at
## boot and handed from here: to the observers (`Telemetry`, `GameSave`, `VisitCounter`) as the
## config itself, and to the world, the day and the baby as the plain values each needs out of it
## — a day's length, whether the clock stands still, how the ground is scheduled.
##
## The developer's furniture — the right-hand readout, the frame graph, the debug view's overlays,
## the routes and their keys — is `DebugReadout`'s (`src/dev/debug_readout.gd`), handed what it reads
## from here. A rig's lock-out is `RigLock`'s (`src/dev/rig_lock.gd`), and the half second of ignored
## input after the game gets focus back is `ReturnWindow`'s (`src/ui/return_window.gd`).

const CITY := preload("res://scenes/world/city.tscn")
const STROLLER := preload("res://scenes/player/stroller.tscn")
const HUD := preload("res://scenes/ui/hud.tscn")
const DAY_SUMMARY := preload("res://scenes/ui/day_summary.tscn")
const PAUSE_SCREEN := preload("res://scenes/ui/pause_screen.tscn")
const TITLE_SCREEN := preload("res://scenes/ui/title_screen.tscn")
const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")

## Every baked atlas page any day can draw, taken at boot and held for the life of the process.
##
## *(PLAYTEST-109: "we probably could preload everything. or at least load everything needed for a
## day during the day brief. and everything that might always be needed at startup" · "don't
## unload anything that might be needed in one day and in the next".)* Holding all of them from
## startup is the simpler of the two shapes the player allowed and it makes the second sentence
## true by construction: a consumer's own `release()` can only ever drop the count back to the
## residency underneath it, so a city torn down between two runs or a node re-entering the tree
## never costs a reload in a played frame.
##
## **The run's own parent is not in this list** — it is not the same page on every run — and is
## taken beside it in `_hold_every_page_a_day_draws()`. **Nor is `interior`**, which no ordinary
## day enters a building to draw; the escape's own boot takes that one.
##
## **`events` is the biggest page and is held like every other one.** It carries the whole
## catalogue, the checkpoint kit and the finale's crater, and a day can stream any row in it into
## reach at any moment — so there is no smaller set to hold and no later moment to hold it in.
const RESIDENT_GROUPS: Array[StringName] = [
	&"ui", &"stroller", &"buildings", &"street_kit", &"ground", &"decoration", &"crowd", &"events",
]
## What an ordinary day's boot holds on top of `RESIDENT_GROUPS`: nothing. Declared rather than
## written as a literal at the call site, because an untyped `[]` passed into an
## `Array[StringName]` parameter is coerced at the boundary and retains its arguments — see the
## **godot** skill, "Passing an untyped Array into an Array[T] parameter leaks at shutdown".
const NO_FURTHER_GROUPS: Array[StringName] = []
## And what a boot into the escape holds on top of them: the building's pictures, which no day
## enters a building to draw.
const ESCAPE_ONLY_GROUPS: Array[StringName] = [&"interior"]

@onready var _status: Label = $CanvasLayer/Status
@onready var _status_layer: CanvasLayer = $CanvasLayer

## This run's configuration, resolved once at boot — see `configure()`, which also sets the members
## below that are read from it.
var config: RunConfig

## `--start-escape`, kept in a member so a test can set it directly and check the release shape.
var _escape_scene_requested := false

## The run's way through its screens — which screen is up, what its continue leads to, how this
## boot came to the run, and the day being walked — see `RunFlow`. Its `authored` configuration is
## set in `_ready()` when a scene recipe is loaded.
##
## Whether this boot reached the escape as **a run's own ending** (`RunFlow.escape_from_a_run()`)
## rather than through the flag changes three things: the run is already there, so no
## `GameState.start_run()`; the save is live, so the symbol that announces a write is built; and
## getting out of the city settles the run (`GameState.calendar.finish_day()`) — the flag's run
## is a day-1 run that only jumped here, so its own way out settles nothing.
var _flow := RunFlow.new()

## `--no-focus-pause`, kept in a member so a test can set it directly and check the release shape.
var _no_focus_pause := false

## The developer's furniture over the run — see `DebugReadout`. Built in `_ready()`; null for a
## script-only `main` a test drives with no boot behind it.
var _readout: DebugReadout
## A rig's lock-out — see `RigLock`. Built first thing in `_ready()`.
var _rig_lock: RigLock
## The half second of ignored input after the game gets focus back — see `ReturnWindow`. Built in
## `_ready()`; its departures open the pause through `_pause_on_focus_lost()`.
var _return_window: ReturnWindow

var _city: City
## The run this boot plays, taken off the `GameState` autoload once, here: the autoload is where the
## run lives, since it outlives the scene reloads, and this is where it is reached — besides the
## events and the resistance, which still read it off the autoload. This file
## reads the run through `_run` and hands it, typed `RunState`, to `GameSave` and to every reader
## it builds.
var _run: RunState = GameState
## The parts of the run's state this node reads and writes most, taken off the run once and held.
var _spend: AttemptSpendState = _run.attempt_spend
var _facts: RunFacts = _run.facts
## The escape's building. In the escape it is built first and `_city` follows when she walks out of
## the service exit, so the two *are* both non-null for the whole of the city section — the
## building stays on its own map with nobody on it. On an ordinary run `_interior` is null and
## `_city` is the only world there is.
var _interior: InteriorScene
## The events inside the building — the fire, the masked man, the mouse, the steam and the
## explosions outside — run by the day's own `EventManager` on the building's map, from the
## building's own placements (`BuildingPlan`).
var _building_events: EventManager
## The seed the building's placements and its night are drawn from, once a boot
## (`GameState.calendar.day_rng(day, "finale-interior")`), so every attempt is the same building.
var _building_seed := 0
var _player: Stroller
var _baby: Baby
var _day: DayController
var _resistance: ResistanceDirector
## The run log's owner for this boot — see `RunSession`. Built first in `_ready()`; null for a
## script-only `main` a test drives with no boot behind it.
var _session: RunSession

## The trace this boot hands game logic: the session's, or a silent one for a script-only `main`.
func _the_trace() -> RunTrace:
	return _session.trace if _session else RunTrace.new()
var _hud: CanvasLayer
## Kept because the telemetry observer asks it what she is being warned about; the layer around it
## is kept only so the title screen can take it off the street.
var _edge: DangerEdge
var _edge_layer: CanvasLayer
## What is currently charging the meter, drawn under the world rather than over it — see
## `_add_excitement_halo()`.
var _halo: ExcitementHalo
## Every frame's time by system, under `--frame-record`/`?framerecord=1`, or `null`. The readout
## carries its line, the last slow frame's three largest costs, so a stutter caught on a phone shows
## as caught.
var _frame_recorder: FrameRecorder
## The pointer controls, on their own layer for the same reason the danger edge is: they have to
## sit above the world they are drawn over. Built in `_ready()`, alongside `_touch_layer`.
var _touch_controls: TouchControls
## Built in `_ready()` for `_touch_controls` to live on — `_apply_orientation()` needs somewhere to
## rotate, the same reason it exists before the controls question used to be answered.
var _touch_layer: CanvasLayer
var _summary: CanvasLayer
var _pause: PauseScreen
var _title: TitleScreen
## The small corner symbol a change in the save state shows — see `SaveIndicator`'s own doc. Raised
## by `_raise_save_indicator()`: in `_ready()`, ahead of the charge that can end a resumed run, and
## for the escape only when it is a run's own — the flag's escape touches the save not at all
## (`GameSave.uses_save()` refuses every one of them), so a symbol there could only ever stay dark.
## It may be the one a reloading `main` handed to the tree's root, not a child of this node.
var _save_indicator: SaveIndicator

## What `_reload_the_scene()` calls in place of reloading the scene, set only by `use_reload()`. An
## empty `Callable`, the default, reloads normally.
var _reload_override := Callable()
## What `_quit()` calls in place of quitting the tree, set only by `use_quit()`. An empty
## `Callable`, the default, quits normally.
var _quit_override := Callable()

## Owns the `--follow` camera and the event id it tracks between frames — the one piece of
## `DevRig` (`src/dev/dev_rig.gd`) that has to survive across calls, so it is the one piece kept
## on an instance rather than called as a `static`. The `--spawn`/`--overview`/`--meters` lookups
## against the live city need no instance and are called on `DevRig` itself.
var _dev_rig := DevRig.new()
## `--route`'s own walker, `null` outside a debug build or with no `--route` given — see
## `src/dev/route_rig.gd`. Unlike `_dev_rig`, this owns a whole target queue that has to survive
## across a day's frames, so it is a child node rather than a bag of static lookups.
var _route_rig: RouteRig
## `--route` in the escape's building: see `_add_the_building_walker()`.
var _building_walker: BuildingWalker
## Dev spawn and meter overrides apply to the opening day only; every later day starts on
## the doorstep with a fresh baby, like the game intends.
var _first_day := true
## `GameSave.try_resume()`'s own return: `{}` on a fresh run, or `{"day_under_way": bool}` once
## `GameState` already carries a resumed run's fields — set once in `_ready()` and read by
## `_on_title_start()`, which is the only place the title's own dismissal is not simply "start
## playing": with a save on disk, pressing start opens the day brief instead — or, when the load
## spent a hard run's last nerve, the ending. (A normal run's last nerve spent by the load opens the
## brief too, on its checkpoint's day.) Empty for every dev-flag or headless boot, since
## `GameSave.uses_save()` already refuses all of them — see that function's own doc — and for a
## boot that carries a run on from a checkpoint (`RunFlow.Opening.CARRIED_FROM_CHECKPOINT`).
var _resume := {}

## Set by `_carry_the_run_into_the_next_boot()` just before it reloads the scene, and read and
## cleared by the boot that follows. A `static var` because a scene reload frees this node but never
## unloads its script — the same reason `TitleScreen._restarted_at_msec` is one.
static var _carry_the_run_over := false

## Whether opening the save spent a normal run's last nerve and sent it back to its checkpoint —
## set once in `_ready()`, before the charge, and read by `_show_the_resume_gate()` for the line the
## day brief carries. A hard run's last nerve ends the run instead (`RunHeader.ending`).
var _resume_went_back := false

## Read once, in `configure()` — a run's touch hardware does not change, and `--touch` is the run's
## configuration — and handed to every screen that asks (`use_touch()`, `use_platform()`), so
## `_process()` can ask `ScreenOrientation.wants_rotation` every frame without asking the platform.
var _touch_available := TouchInput.available()
## The rotation `_apply_orientation()` last actually applied, so `_process()` can ask the same
## question every frame and reapply only on change — see that function's own doc for why a signal
## alone is not enough.
var _rotated := false
## The camera `_new_boot_camera()` made current while the boot's own player does not exist yet,
## until `_retire_the_boot_camera()` frees it — kept so `_apply_orientation()` can turn it with
## the window the same way it turns hers.
var _boot_camera: Camera2D

func _init() -> void:
	configure(RunConfig.at_boot())

## Hands this boot its run configuration and sets the members read from it. `_init()` hands it the
## process's own (`RunConfig.at_boot()`); a test hands it one of its own before the boot runs, and a
## recipe's boot hands it the same run with the recipe on top.
func configure(run_config: RunConfig) -> void:
	config = run_config
	_escape_scene_requested = config.start_escape
	_no_focus_pause = config.no_focus_pause
	_touch_available = TouchInput.available(config)

## Hands this boot what it calls instead of reloading the scene (a held restart, a continue that
## reloads, the escape's hand-over): a reload replaces the scene a test runner stands in. Set before
## the boot runs; a boot never handed one reloads normally.
func use_reload(reload: Callable) -> void:
	_reload_override = reload

## Hands this boot what it calls instead of quitting the game (the pause screen's quit). Set before
## the boot runs; a boot never handed one quits normally.
func use_quit(quit: Callable) -> void:
	_quit_override = quit

func _ready() -> void:
	# First, so every boot (the escape's and a recipe's too) deletes the save when its run ends.
	GameSave.clear_when_a_run_ends()
	if not config.recipe_path.is_empty() and not _author_the_scene():
		return
	# Before anything the observers watch can happen: the run log's header, the save's gate and
	# what the page counts all read this boot's configuration rather than the command line.
	Telemetry.configure(config)
	GameSave.configure(config)
	VisitCounter.configure(config, _run)
	# The run log's owner, listening on the bus from here on, and the trace everything this boot
	# builds writes its own account into.
	_session = RunSession.new()
	_session.name = "RunSession"
	add_child(_session)
	_session.setup(Telemetry, config, EventBus, _run)
	_run.use_trace(_session.trace)
	# Esc has to work even while the summary has the tree paused, so this node keeps running
	# through a pause. Everything under it that *is* the game is put back to pausable as it is
	# created — see `_pauses_with_the_game()`. A child left on the default INHERIT inherits
	# ALWAYS from here, and then the pause does nothing to it: the summary sets
	# `get_tree().paused` while the player walks, the crowd drives and the resistance deadline
	# runs out behind a screen saying the day is over.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# As early as this scene's own script can act — see `RigLock`'s own doc for why nothing earlier
	# is reachable from GDScript at all.
	_add_the_rig_lock()
	WebDisplay.apply(config)
	_add_the_return_window(get_viewport())
	# A recording's own real wall clock runs several times slower than its game clock (saving one
	# frame costs far longer than the 1/60s it represents) — see `RigLock._quit_game_seconds`'s doc.
	# Physics interpolation blends a rendered frame between two physics ticks by how far the
	# frame's own real presentation time sits between them, so under that mismatch the blend never
	# advances: every recorded frame reads as the same tick, and her camera, the crowd and the
	# clock all read as frozen even though the simulation underneath is running correctly (confirmed
	# against the run log while building this). Off only for a recording — real play keeps the
	# smoothing `--fixed-fps` never runs under.
	if config.recording:
		get_tree().physics_interpolation = false
	# The developer's furniture, on whichever day the boot opens — see `DebugReadout`. It starts in
	# the shape it should have on this build rather than trusting the scene file's own default.
	_add_the_readout()
	# Read before `try_resume()` touches it, so the check below can tell a save that already
	# carried a section on the autoload (a handover reload, `RunFlow.Opening.ESCAPE_HANDED_OVER`)
	# from one that only got there because the line just after this read it off the file
	# (`RunFlow.Opening.ESCAPE_RESUMED`).
	var escape_section_before_resume := _facts.escape_section
	if _escape_scene_requested:
		_start_the_flags_run()
	else:
		_settle_the_run()
	# **Whether a genuinely resumed escape is what this boot opens**: the game was closed inside a
	# section and opened again, as against the handover reload a won day 14 takes into the escape,
	# which reaches this boot with the same `GameState.facts.escape_section != NONE`, the same non-empty
	# `_resume` and no way to ask either one which of the two just happened. Still `NONE` before
	# `try_resume()` and something else after means the value just arrived from the file it read,
	# since a handover already wrote it to the autoload — which a scene reload does not clear —
	# before this boot's own `_ready()` ever ran. A resumed escape opens on the title first, the
	# way a resumed day does; a handover opens straight on the building's brief.
	if _flow.escape_from_a_run() and _escape_section_came_from_the_file(
			escape_section_before_resume, _facts.escape_section):
		_flow.opening = RunFlow.Opening.ESCAPE_RESUMED
	var first := _the_first_day()
	# After the run seed is settled and before anything is generated, so the log opens on the
	# seed it is a trace of. A run carried on from a checkpoint, or handed over to the escape, keeps
	# writing the log it already has — see `RunSession.open()`.
	_session.open(_run.header.run_seed, _somebody_is_playing(),
			_flow.opening == RunFlow.Opening.CARRIED_FROM_CHECKPOINT
					or first.section != DaySpec.Section.NONE)
	# Before the city, before the player, before the title: every page a day can draw is on disk
	# already and this is the last moment nobody is watching a frame. After the log is open, so
	# the run log carries a line per page with the moment it loaded in — see `AtlasLibrary`.
	#
	# **The escape's own pictures are held here too, at its boot rather than behind a section's
	# brief**, which is the screen PLAYTEST-109 asks for — "this is only needed in the escape day
	# brief" — because the brief is raised *over* a section that has already been assembled and she
	# has already been put down in: there is no frame between the two for a page to arrive in. The
	# rule the moment exists for is satisfied here instead, at the one point in the sequence where
	# nobody is watching a frame, and no ordinary day pays for those pictures.
	if first.section == DaySpec.Section.NONE:
		_hold_every_page_a_day_draws(AtlasLibrary.MOMENT_STARTUP, NO_FURTHER_GROUPS)
	else:
		_hold_every_page_a_day_draws(AtlasLibrary.MOMENT_ESCAPE, ESCAPE_ONLY_GROUPS)
	# A save whose day was under way when it was written loses that day, through the same code
	# path an ordinary lost day takes — one nerve, the resistance given back, the same day again,
	# and the last nerve doing exactly what it does there: a hard run ends, a normal one goes back
	# to its checkpoint. Applied before anything downstream (the HUD, the city's own act) ever reads
	# a nerve count or a resistance state that has not been charged yet. A hard run's last nerve
	# ends the run here (`RunHeader.ending`), and `_on_title_start()` shows that ending, or the
	# brief, once the title itself has been dismissed. An escape section is never saved as under way
	# (`DaySpec.saved_as_under_way`), so a resumed escape is never charged here.
	#
	# **The symbol exists before this charge**, because the charge can end the run and the run's
	# end deletes the save, a change the symbol shows (`GameSave.clear()` announces it on
	# `EventBus`, which only an indicator already built hears). The flag's escape touches the save
	# not at all, so it gets none.
	if first.section == DaySpec.Section.NONE or _flow.escape_from_a_run():
		_raise_save_indicator()
	if _resume.get("day_under_way", false):
		_resume_went_back = _run.calendar.a_loss_goes_back_to_the_checkpoint()
		_run.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	# **One boot, and the first day decides its world.** A day is walked in the city, built here
	# around her doorstep; the escape's sections build their own worlds when each begins
	# (`_start_section()`), after the section is announced, so whatever the building or the city
	# does as it is built is already that section's.
	var walks_a_day := first.section == DaySpec.Section.NONE
	var ground := Vector2.ZERO
	if walks_a_day:
		_city = _new_city()
		var elapsed := Time.get_ticks_msec()
		_city.build(_city_map())
		print("[Main] city generated in %d ms (seed %d)" % [
			Time.get_ticks_msec() - elapsed, _city.map.seed_used])
		ground = _city.map.doorstep_world_position()
	# On the doorstep before her own `Camera2D` exists, so the two frames `_warm_the_canvas_shaders()`
	# awaits below draw the ground the title screen and the day itself will, rather than the
	# world's default identity transform — see `_new_boot_camera()`'s own doc. Freed once she has
	# been put down for real. In the escape nothing of the world is built yet, so world origin is
	# as good as any other point.
	var boot_camera := _new_boot_camera(ground)
	if config.warms_the_canvas_shaders():
		await _warm_the_canvas_shaders(boot_camera.global_position)

	if walks_a_day:
		_player = _make_player()
		_city.add_entity(_player)
		_player.clear_camera_limits()
		_baby = _player.get_node("Baby")
		_put_her_in(_city.map)

	_build_the_screens()

	# After every layer `_apply_orientation()` touches exists — it reaches `_summary`, `_pause`
	# and `_title` too, not just the HUD and the two layers built just above. `_process()` is what
	# keeps it current from here on, not a `size_changed` connection — see that function's own doc.
	_apply_orientation()

	# No `ResistanceDirector` in the escape: it has no subquest to advance.
	if walks_a_day:
		_resistance = ResistanceDirector.new()
		_resistance.name = "Resistance"
		add_child(_resistance)
		_pauses_with_the_game(_resistance)
		_resistance.trace = _the_trace()
		_resistance.setup(_city, _city.map, _city.navigator, null, _city.spawn_siting)
		_resistance.use_player(_player)
		# The director's own question about her view — no camera of its own, so it asks the day's
		# one view (`VisibleView`) rather than growing a second one: "has she seen this" for a
		# mark's notice. Whether anything it places or removes is anywhere on screen, covered
		# corners included, is the city's siting's, over the same view.
		_resistance.set_sight(_city.events.sees)

	_day = DayController.new()
	_day.name = "Day"
	_day.invincible = config.invincible
	add_child(_day)
	_pauses_with_the_game(_day)
	_day.setup(_city.map if _city else null, _player, _run)
	_day.day_finished.connect(_on_day_finished)
	_session.watch_the_clock(_day)
	if _readout:
		_readout.watch(_player, _baby, _day)

	if walks_a_day:
		_session.watch_day(_city, _player, _baby, _day, _resistance, _edge)

	if walks_a_day and config.frame_trace_requested:
		var trace := FrameTrace.new()
		trace.name = "FrameTrace"
		add_child(trace)
		trace.setup(_flow.in_the_title, _readout.readout_on, _readout.graph_on, _city, _player, _day,
				Array(config.active_args), _run)

	if walks_a_day and config.frame_record_requested:
		_frame_recorder = FrameRecorder.new()
		add_child(_frame_recorder)
		_frame_recorder.setup(_flow.in_the_title, _city, _player, _day, _run)
		_readout.watch_frames(_frame_recorder)

	# Built before `_start_day()`, whose `day_planned` starts it once the day it is meant to walk
	# actually exists — see `src/dev/route_rig.gd`.
	if walks_a_day and not config.route_targets.is_empty():
		_add_the_route_rig(_resistance)

	if walks_a_day:
		if not _start_day():
			_retire_the_boot_camera()
			return
		_write_dawn_for_a_resumed_run()
	else:
		# `VisitCounter`'s own "the escape: begun" — the fresh handover from a won day 14 only,
		# never a resume of one already under way, which is not the sequence beginning.
		if _flow.opening == RunFlow.Opening.ESCAPE_HANDED_OVER:
			EventBus.escape_begun.emit()
		_start_section(first, false)
		# The world was built inside the call above, after the boot's own orientation pass.
		_apply_orientation()
	# `_player.reset_at()` above has just put her own camera exactly where the boot camera was
	# standing in for it, so freeing it now hands the viewport's current camera straight to hers —
	# see `_new_boot_camera()`'s own doc for why freeing is what does that.
	_retire_the_boot_camera()

	if config.overview_requested and _city:
		DevRig.make_overview_camera(self, _city, get_viewport_rect().size)
	if walks_a_day:
		_dev_rig.setup_follow_camera(self, config.follow_target, config.zoom_override)
	_add_trailer_rigs()
	if _flow.authored and not _begin_the_scene(walks_a_day):
		return

	_add_the_screenshot_rig()

	# Apart from the boot-order block above and below: `StillWatch` only reads `_city`, `_player`
	# and `_day`, which already exist by here, and does not affect what day starts or how.
	if walks_a_day and config.quit_when_still_requested:
		var still_watch := StillWatch.new()
		still_watch.name = "StillWatch"
		add_child(still_watch)
		still_watch.setup(_city, _player, _day, config.quit_when_still_seconds, config.recording)

	# The escape's first screen — see `_open_the_first_screen_of_the_escape()`. An authored scene
	# has already started playing above.
	if not walks_a_day:
		if _flow.authored:
			return
		_open_the_first_screen_of_the_escape(_flow.opening == RunFlow.Opening.ESCAPE_RESUMED)
		return
	# **Except under a rig.** A screenshot tool that opened onto the title screen would photograph
	# the title screen, which is every `tools/shot.sh` recipe quietly answering the wrong
	# question, and `--press` and `--walk` would hold keys against a game that has not begun.
	# A rig is driving, so it starts the day the way the player would. `--title` is how the screen
	# itself gets photographed. `_resume` is always empty here for every one of these branches —
	# `GameSave.uses_save()` already refuses a dev-flagged or headless run, so a rig boot and a
	# resumed boot can never both be true — but the title still comes up for an ordinary resumed
	# boot exactly as it does for a fresh one; see `_on_title_start()` for what pressing start on it
	# then leads to.
	# Through `config`, whose command-line flags answer nothing outside a debug build, so a release
	# export cannot be told to skip its own front door: `--no-title` is a rig's convenience like
	# every other flag here, and the title screen is the game's first screen.
	#
	# The continue that carried the run on here was the press that starts the checkpoint's day, so
	# no title and no brief stand in front of it: she is playing it from this frame, and the save
	# says so.
	if _flow.opening == RunFlow.Opening.CARRIED_FROM_CHECKPOINT:
		_engage_the_day()
		return
	if _show_an_ending_for_a_rig():
		return
	if config.skips_the_title():
		_flow.engage()
		_hand_the_crowd_her()
		return
	_open_the_title()

## **The escape opens on its section's brief**, the screen a day's continue would otherwise lead to
## — **unless it is a genuinely resumed escape** (`resumed_from_disk`, which `_ready()` reads off
## `_escape_section_came_from_the_file()`), which opens on the title first, exactly as a resumed day
## does, and the title's start then shows the brief (`_show_the_resume_gate()`). Either screen
## pauses the tree, so the section's clock, started by `_start_section()`, stands still behind it.
## A walker (`--route`) has the brief's continue pressed for it by the route rig (`RouteRig.press_the_brief()`),
## through the run flow's own `brief_opened`. Its own function so a test booting the real scene can
## drive every answer.
func _open_the_first_screen_of_the_escape(resumed_from_disk: bool) -> void:
	if resumed_from_disk:
		_open_the_title()
	else:
		_show_the_section_brief()

## The run this boot plays, when it plays a day or a run's own escape: carried on from a
## checkpoint, picked back up from the save, or begun fresh.
func _settle_the_run() -> void:
	# Tried before a fresh run is started, so a resumed run keeps the seed, the day and everything
	# else it held rather than being handed a new one. `GameSave.uses_save()` is the one gate every
	# read and write of the save goes through, so a dev flag, a headless boot or a release build
	# with nothing on disk yet all fall straight through to `_resume.is_empty()` and an ordinary
	# fresh run below — see `GameSave`'s own doc. Kept on the instance, not a local, so
	# `_on_title_start()` can still read it once the title's own start button is pressed.
	#
	# **A run carried on from a checkpoint reads no file**: `GameState` already holds it, and
	# `GameSave.load_in_memory()` puts it back through the same JSON and the same `_apply()` a load
	# does, so this boot builds on exactly what a load would give it, on any run.
	var carried := _carry_the_run_over
	_carry_the_run_over = false
	if carried:
		GameSave.load_in_memory(_run)
	else:
		_resume = GameSave.try_resume(_run)
	# **`GameState.facts.escape_section` is asked before a fresh run is started, not after.** It is set
	# two ways and both of them must survive this line: the save above restores it for a game closed
	# inside a section, and a handover from day 14 leaves it set on the autoload across the scene
	# reload that reaches this boot — a reload under a dev flag or in a headless rig, where
	# `GameSave.uses_save()` refuses every read, would otherwise start a brand new run over the one
	# that just earned its ending.
	if _resume.is_empty() and _facts.escape_section == DaySpec.Section.NONE \
			and not carried:
		_run.start_run(config.seed_override)
		_apply_the_parent_flag()
		_run.header.day = config.day_override
		_apply_the_mode_flags()
	# `VisitCounter`'s own "a run begun fresh, or resumed from the save" — fired once here for
	# every path through this function, ordinary or handed over to the escape, since GameState.header.day
	# is already settled for both by this line. `resumed` says only whether `GameSave.try_resume()`
	# found a file; it cannot also tell a file a real previous visit left from one a
	# `reload_current_scene()` earlier in this same page's life just wrote — a won day 14 handing
	# over to the escape is exactly that case. `VisitCounter` is where that distinction is made,
	# since only it can know whether *this page* has already reported a run beginning once before.
	#
	# Not for a run carried on from a checkpoint, which is the same run going on, not one beginning.
	if not carried:
		EventBus.run_begun.emit(_run.header.day, not _resume.is_empty())
	# The run's ending, played rather than announced: a won day 14 with every task complete hands
	# over to the escape, and a game closed inside a section opens on it again — which of the two
	# `_ready()` tells once it knows whether the section came from the file.
	if carried:
		_flow.opening = RunFlow.Opening.CARRIED_FROM_CHECKPOINT
	elif _facts.escape_section != DaySpec.Section.NONE:
		_flow.opening = RunFlow.Opening.ESCAPE_HANDED_OVER
	elif not _resume.is_empty():
		_flow.opening = RunFlow.Opening.RESUMED

## `--start-escape`: the escape with no run behind it, so a rig or a person can walk it on demand. A
## fresh run of its own, on day 1 — `--day` does not move it; an authored scene's own day does
## (`config.day_override`, the recipe's day once `RunConfig.with_recipe()` has laid it on) — and no
## `run_begun`, since nothing about it is a run the page should count.
func _start_the_flags_run() -> void:
	_flow.opening = RunFlow.Opening.ESCAPE_BY_FLAG
	_run.start_run(config.seed_override)
	_apply_the_parent_flag()
	if _flow.authored:
		_run.header.day = config.day_override
	_apply_the_mode_flags()

## The day this boot opens on: the run's own day, or one of the escape's two sections. **Which
## section is the run's own record where there is one** (`GameState.facts.escape_section`, which a save
## closed inside the city carries), and the flag's word where there is none — `city` boots the
## city section on its own, with no building built at all.
func _the_first_day() -> DaySpec:
	if _escape_scene_requested or _flow.escape_from_a_run():
		var start_at_the_city := _escape_start_part() == "city" \
				or (_flow.escape_from_a_run() and _facts.escape_section == DaySpec.Section.CITY)
		return escape_section_spec(DaySpec.Section.CITY if start_at_the_city
				else DaySpec.Section.BUILDING, config.escape_section_length())
	return day_spec(config, _run.header.day)

## One of the fourteen days as this boot walks it: `day`, its clock `config`'s length for it
## (`RunConfig.day_length_for()`, which `--day-length` compresses). The one spec a day is handed to
## its clock, its HUD and its events alike, an authored scene's day included. Static so a test builds
## the same spec the run walks.
static func day_spec(run_config: RunConfig, day: int) -> DaySpec:
	return DaySpec.for_day(day, run_config.day_length_for(day))

## One of the escape's two sections, `length` seconds long, with its own words — *"Escape the
## building"* and *"Escape the city"*, the player's names for the two screens — handed to the spec
## here, since the spec is data and names nothing of the UI's. `section` is a `DaySpec.Section` as
## an `int`. Static so a test builds the same spec the run walks.
static func escape_section_spec(section: int, length: float) -> DaySpec:
	return DaySpec.for_section(section, length, Texts.ESCAPE_BUILDING
			if section == DaySpec.Section.BUILDING else Texts.ESCAPE_CITY)

## The screens every boot stands around the walk, built the same way whichever day it opens on:
## the HUD; the screen-edge badge, the halo and the debug view when a world already stands (the
## escape's sections add theirs as each world is built); the touch controls; the summary, the pause
## and the title, with one set of handlers for all three.
func _build_the_screens() -> void:
	_hud = HUD.instantiate()
	_configure_the_hud()
	_hud.use_touch(_touch_available)
	add_child(_hud)
	_flow.day_started.connect(_hud.use_the_day)
	if _player:
		_add_danger_edge()
		_add_excitement_halo()
		_add_debug_layers()
		_add_route_lines()
	_add_touch_controls()
	_summary = DAY_SUMMARY.instantiate()
	_summary.use_touch(_touch_available)
	add_child(_summary)

	# Deliberately not `_pauses_with_the_game`: a pause screen that pauses with the game cannot
	# unpause it. It inherits ALWAYS from this node, which is what it wants.
	_pause = PAUSE_SCREEN.instantiate()
	_pause.use_platform(_touch_available, QuitOption.available(config))
	_pause.use_run(_run)
	add_child(_pause)
	# So `_pause.open()`/`close()` can stash and restore the heading she carried into an ordinary
	# Esc-pause — see `PauseScreen._touch_controls`'s own doc. `_add_touch_controls()` already ran
	# above, so `_touch_controls` exists by now.
	_pause.set_touch_controls(_touch_controls)

	_connect_summary_and_pause_signals()

	# Same reasoning, one screen further out. See `TitleScreen`.
	_title = TITLE_SCREEN.instantiate()
	_title.use_platform(_touch_available, QuitOption.available(config))
	_title.use_run(_run)
	add_child(_title)
	_title.start_requested.connect(_on_title_start)
	_title.quit_requested.connect(_quit)

## Whether `escape_section` arrived from a file `GameSave.try_resume()` just read, rather than
## surviving on the autoload from a handover reload earlier in this same process — see where
## `_ready()` sets `RunFlow.Opening.ESCAPE_RESUMED` for why the two need telling apart at all.
## Pulled out, the two live reads of `GameState.facts.escape_section` taken out of it, so a test
## can drive every combination directly rather than only through a real save on disk.
static func _escape_section_came_from_the_file(before_resume: int, after_resume: int) -> bool:
	return before_resume == DaySpec.Section.NONE and after_resume != DaySpec.Section.NONE

## `--screenshot` and the timed runs `AutoScreenshot` drives, on any day; nothing without one. An
## authored scene played by script times the capture off its own physics clock and prepares it.
func _add_the_screenshot_rig() -> void:
	var screenshot := AutoScreenshot.from_config(config)
	if not screenshot:
		return
	if _flow.authored and _flow.scene.plays_by_script():
		screenshot.simulation_clock = _flow.scene.elapsed
		screenshot.before_capture = _flow.scene.prepare_capture
	add_child(screenshot)

## `--parent mother|father` over the roll `GameState.start_run()` just made from the seed, so a
## trailer shot shows the parent its shot list names. Called straight after each of this file's
## two `start_run()` calls, before anything reads the choice — `_hold_every_page_a_day_draws()`
## holds that parent's atlas page and `_make_player()` binds the rig to it.
func _apply_the_parent_flag() -> void:
	var parent := config.parent_override
	if parent != "":
		_run.header.player_is_male = parent == "father"

## `--hard` and `--nerves N` over the fresh run `GameState.start_run()` just made, so a rig can reach
## what running out of nerves does in either mode without spending four nerves first. `--hard` is
## also what the title's checkbox opens on (`TitleScreen.open()` reads the `hard_mode` of the run it
## is handed), so `--title --hard` photographs it checked. Called straight after each of this file's
## two `start_run()` calls, beside `_apply_the_parent_flag()`.
func _apply_the_mode_flags() -> void:
	if config.hard_mode_requested:
		_run.calendar.choose_mode(true)
	var nerves := config.nerves_override
	if nerves > 0:
		_run.header.nerves = nerves

## What the HUD draws of the developer's furniture: its debug header on a debug build, the release
## shape under `--player-view`, and the invincible mark under `--invincible`; whether it teaches the
## control lessons, which an authored mid-game scene has already learned (`RunFlow.lessons_learned()`);
## and the run its header and resistance line read. Set before `add_child()` runs the HUD's own
## `_ready()`.
func _configure_the_hud() -> void:
	_hud.configure(config.debug_build and not config.player_view_requested, config.invincible,
			_flow.lessons_learned())
	_hud.use_run(_run)

## The trailer's two additions to a shot, on any day: `--zoom-out`'s camera move, started from
## whichever camera is current once her own has been placed, and `--caption`/`--title-card`'s text.
## Both add nothing unless their flag was given.
func _add_trailer_rigs() -> void:
	var seconds := config.zoom_out_seconds
	var bounds := Rect2()
	if _city:
		bounds = _city.camera_bounds()
	elif _interior:
		bounds = _interior.camera_bounds()
	if seconds > 0.0 and bounds.has_area():
		var zoom_out := ZoomOutCamera.new()
		zoom_out.name = "ZoomOut"
		add_child(zoom_out)
		_pauses_with_the_game(zoom_out)
		zoom_out.setup(get_viewport().get_camera_2d(), bounds, get_viewport_rect().size, seconds,
				config.zoom_out_delay)
	var text := TrailerText.build(config.caption_text, config.title_card_text)
	if text:
		add_child(text)

## All entry points bind the run's existing choice before the rig enters the tree or draws, and
## hand the baby whether `--invincible` stands her excitement meter still.
func _make_player() -> Stroller:
	var player: Stroller = STROLLER.instantiate()
	player.is_male = _run.header.player_is_male
	(player.get_node("Baby") as Baby).excitement_frozen = config.invincible
	return player

## A city node in the tree, handed the dev choices that decide how it draws and schedules itself
## before `build()` reads them — a day's city and the escape's are both built through here.
func _new_city() -> City:
	var city: City = CITY.instantiate()
	city.trace = _the_trace()
	city.run = _run
	city.ground_mode = config.ground_mode as SceneryGround.Mode
	city.scenery_frame_locked = config.recipe_scripted
	city.skip_shadows = config.skip_shadows
	city.skip_event_drawing = config.skip_events
	city.skip_crowd_drawing = config.skip_crowd
	city.skip_crowd_motion = config.skip_motion
	city.crowd_view = ScreenCrowdView.new(self)
	city.crowd_timing = FrameRecordTiming.new()
	city.blackout_forced = config.blackout_requested
	city.all_cyclists_pelicans = config.pelican
	city.forced_row = config.forced_row
	city.forced_interval = config.forced_interval
	add_child(city)
	_pauses_with_the_game(city)
	return city

## The map the city is built on: an authored scene's own (`RunFlow.authored_map()`), or the one the
## run's seed generates.
func _city_map() -> CityMap:
	var authored := _flow.authored_map()
	return authored if authored else CityGenerator.generate(_run.header.run_seed)

## The world a section of the escape is walked in, built the first time that section begins: the
## building for the first, and the city for the second — out of the building's service exit, or
## straight onto the street on a boot that opens there. A retried section walks the world it
## already has.
##
## **Walking out of the building, its wall blockers and its pictures go; its fade stays.** The
## building and the city share one physics space and one canvas, both laid out from the world
## origin, so its blockers would stand across the city's top rows as a wall nobody draws (inbox
## #777 in minty-lemur) — `InteriorScene.take_the_walls_out()` — and its walls and doors would be
## drawn on the city's top streets — `InteriorScene.put_the_pictures_away()`, once the city stands
## and she has been moved into it. The fade is not reversed here:
## `InteriorScene` holds the black at full opacity from the moment she reaches the door, and
## `_start_section()` clears it once she has been put down on the street, so nothing of the city is
## seen being assembled.
func _build_the_world_for(spec: DaySpec) -> void:
	if spec.world == DaySpec.World.BUILDING:
		if not _interior:
			_build_the_escape_building()
	elif not _city:
		if _interior:
			_interior.take_the_walls_out()
		_build_the_finale_city()
		if _interior:
			_interior.put_the_pictures_away()
	# The first world this boot stands is where the run log's observer starts watching the escape —
	# her, the baby, the day's clock and the badges, which exist from here on.
	if not _escape_watched and _session:
		_escape_watched = true
		_session.watch_escape(_player, _baby, _day, _edge)

## Whether the run log's session has been told what to watch the escape with — once a boot.
var _escape_watched := false

## Hands her and the baby the map of the world she now walks (`WorldMap`): the stroller asks it how
## the ground under her turns a press (`Stroller.set_map()`), and the baby asks its world how loud it
## is and what the ground does to her (`Baby.set_world()`); and a city's events are handed her
## (`EventManager.use_player()`), and each world's events are handed what the controls cover
## (`_hand_the_controls_cover_to_the_events()`). Called whenever she is put into
## a world, so neither ever asks a world she has left.
func _put_her_in(map: WorldMap) -> void:
	_player.set_map(map)
	_baby.set_world(map.world)
	if _city:
		_city.events.use_player(_player)
	_hand_the_controls_cover_to_the_events()
	if _readout:
		_readout.watch(_player, _baby, _day)

## Hands the city's crowd the player, **from the moment she is in the `player` group and the world
## is live**, which is when the crowd's old lookup by that group would first have found her: not
## behind the title (`Stroller.stand_aside()` takes her out of the group, so a crowd handed her
## then would step round and bump a pram nobody sees), but at `_engage_the_day()`, and where a day
## is walked with no title in front of it. Never taken back, as the lookup's result never was.
func _hand_the_crowd_her() -> void:
	if _city and _city.crowd and _player:
		_city.crowd.use_player(_player)

## Hands each world's events what the on-screen controls cover of the screen, for their view of what
## she can see (`VisibleView`, `EventManager.use_controls()`). Idempotent, and called wherever either
## side comes to exist: the controls are built after a boot's first world (`_add_touch_controls()`),
## and the building's events after the controls. Nothing to hand before the controls exist, which is
## the tap scheme's whole view.
func _hand_the_controls_cover_to_the_events() -> void:
	if not _touch_controls:
		return
	if _city:
		_city.events.use_controls(_touch_controls.covering)
	if _building_events:
		_building_events.use_controls(_touch_controls.covering)

## The map of the world the current spec is walked in — the building's in the escape's first
## section, the city's otherwise — the one the run flow hands down to her and asks each walking
## frame what its ground does to her.
func _world_map() -> WorldMap:
	if _flow.spec.world == DaySpec.World.BUILDING and _interior:
		return _interior.map
	return _city.map if _city else null

## Section one's world: the building, her in it, and the events inside it. Reaching its service
## exit is the section's goal, so the exit's own moment — once its fade has covered the screen —
## reaches the day's clock (`DayController.reach_the_exit()`).
func _build_the_escape_building() -> void:
	_interior = InteriorScene.new()
	_interior.name = "Interior"
	add_child(_interior)
	_pauses_with_the_game(_interior)
	_interior.build()
	_interior.exit_requested.connect(_day.reach_the_exit)

	_player = _make_player()
	_player.carrying = true
	_interior.add_entity(_player)
	_player.set_camera_limits(_interior.camera_bounds())
	_baby = _player.get_node("Baby")
	_put_her_in(_interior.map)

	# The building's events are the day's own manager, handed the building's map: no city, and the
	# whole plan in the world at once, since the building is walked part by part through doors.
	_building_events = EventManager.new()
	_building_events.name = "BuildingEvents"
	_building_events.skip_drawing = config.skip_events
	_building_events.trace = _the_trace()
	_building_events.stream_radius = INF
	add_child(_building_events)
	_pauses_with_the_game(_building_events)
	_building_events.setup_world(_interior.map, _run)
	_building_events.use_player(_player)
	_hand_the_controls_cover_to_the_events()
	_interior.excitement_sources = [_building_events.sources]
	_building_seed = _run.calendar.day_rng(_run.header.day, "finale-interior").randi()
	SteamGrates.lay(BuildingPlan.grates(_interior.map), _interior.map)
	# The building shows what the city shows: the same badge, halo and debug view, reading its
	# events as a day reads the city's — see `_event_source()`. The city's own build calls the same
	# three again when she walks out, which points them at the street.
	_add_danger_edge()
	_add_excitement_halo()
	_add_debug_layers()

## Section two's world: the city she knows with nobody in it, and the finale's own plan on it.
##
## The city is generated from the run seed exactly as an ordinary run's is, so the streets, the
## parks and the two exits are the ones she has walked for fourteen days. What is different is
## everything laid *on* it, and every difference is the section's `DaySpec`: `City.start_day()`
## dresses the blocks and grows no route tree, closures or region wall, since the walk is handed in
## once it is planned (`DaySpec.closes_streets`), and the posters only show (`pastes_posters`); the
## crowd is nobody (`crowd_density`, *"no regular cars or regular people on the street"*); and the
## plan is the escape's own (`_plan_the_finale_city()`). It is dark from its first frame and stays
## at night.
func _build_the_finale_city() -> void:
	_city = _new_city()
	_city.dark_from_the_start = _flow.spec.dark_from_the_start
	_city.build(_city_map())
	_spend.city_state.begin_day(_city.map.block_plans, _run.header.day)
	_city.start_day(_spend.city_state, _run.header.day,
			_run.calendar.day_rng(_run.header.day, "closures"), _flow.spec)
	_city.set_act(_run.calendar.current_act())
	# Night, and fixed there: the escape happens after the last day and the clock is the tension
	# rather than the light, so the sky does not run itself down over the sequence.
	if not _flow.spec.daylight_runs_down:
		_city.set_daylight(0.0)
	_new_director().start_the_crowd(Vector2.INF)

	if not _player:
		_player = _make_player()
		_player.carrying = true
		_city.add_entity(_player)
		_baby = _player.get_node("Baby")
	else:
		# Out of the building and onto the street: the same rig, reparented.
		_player.get_parent().remove_child(_player)
		_city.add_entity(_player)
	# Told, not discovered: she now walks the street's map and the baby asks the street, not the
	# building behind her.
	_put_her_in(_city.map)
	_player.clear_camera_limits()
	# Built here for a boot straight onto the street, and pointed at the street here when she has
	# walked out of the building, which built them first — see `_add_danger_edge()`.
	_add_danger_edge()
	_add_excitement_halo()
	_add_debug_layers()
	_add_route_lines()
	# Some of the layers above may be `CanvasLayer`s built after the boot's own orientation pass,
	# so the rotation is applied again rather than left for the next time the window changes shape
	# — see `_apply_orientation()`, which is idempotent and is asked the same question every frame.
	_apply_orientation()
	_plan_the_finale_city()

## The city's two ways out, for a `DaySpec.Goal.CITY_EDGE` day: the **tiles** the chains end on
## rather than the points `CityEdge` draws its pictures at. The portal's own face is anchored on
## the map edge, past the last ground she can stand on, so a reach measured from it would have to
## be wide enough to cover the difference and would then also cover the street before it.
## `FinalePlanner.exit_tile()` is the carriageway under the portal, which is where being out of the
## city actually happens.
func _the_city_exits() -> Dictionary:
	return {
		CityEdge.Kind.TUNNEL: _city.map.tile_to_world(
				FinalePlanner.exit_tile(_city.map, CityEdge.Kind.TUNNEL)),
		CityEdge.Kind.BRIDGE: _city.map.tile_to_world(
				FinalePlanner.exit_tile(_city.map, CityEdge.Kind.BRIDGE)),
	}

## Today's finale plan, rebuilt from the run seed every time section two begins — on the first
## walk out of the service door and on every restart after a loss. Deterministic, so a restarted
## section is the same city rather than a thinner one: a plan that had been half spent would
## quietly reward losing. Its encounters are counted under the section's own day number.
## An authored scene installs its own instead (`RunFlow.plans_the_finale()`).
func _plan_the_finale_city() -> void:
	if not _flow.plans_the_finale():
		return
	var elapsed := Time.get_ticks_msec()
	# The escape spends none of the run's one-shots: a list of its own, empty.
	var none: Array[String] = []
	_city.events.start_day(_flow.spec, _run.calendar.day_rng(_run.header.day, "finale"), none,
			_finale_start_position())
	var walk := _city.events.walk() as FinalePlanner.Plan
	# The streets the chains run through carry the route's kerb tint, as a day's corridor does.
	_city.tint_the_route(walk)
	# Printed as well as logged, for the same reason `_start_day()` prints the day it just built:
	# the shape of the walk is the one thing worth knowing before anything else in the log means
	# anything, and a run with telemetry off still has a console.
	var summary := walk.summary(_city.events.plans().size())
	print("[Main] finale planned in %d ms (seed %d): %s"
			% [Time.get_ticks_msec() - elapsed, _city.map.seed_used, summary])
	_the_trace().note("plan", "finale: %s" % summary)

## `--start-escape`'s raw word (`config.start_escape_at`), mapped onto the `InteriorMap.PARTS` waypoint to
## teleport to before the first frame — `"hallway_third"`, her own door, for every word this does
## not recognise, which covers both "not given" and a typo alike; `InteriorScene.part_world_
## position()` falls back the same way for a part name it does not recognise, so the two defaults
## agree without one calling the other. Kept here rather than in `DevFlags`, since mapping a word
## onto a part name only this file's own `InteriorScene` understands is not the parser's job.
##
## `"city"` is the one answer that is not a part of the building: it boots section two on its own,
## with no building built at all, so a rig or a person can look at the finale's streets without
## walking down three floors first. `_the_first_day()` is what reads it that way.
func _escape_start_part() -> String:
	return escape_part_for(config.start_escape_at)

## The mapping itself, with the configuration taken out of it, so a test can drive every word.
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

## A section of the escape begins — the first time, or again after a loss — the way `_start_day()`
## begins a day: announced (`day_started`, under the section's own day number), its world built if
## it is not standing yet, her put at its start, the baby asleep in her arms, its clock started, and
## its shape announced (`day_planned`). Whatever screen comes next is the caller's: a section's
## brief (`_show_the_section_brief()`), on its first walk and on every retry after the lost
## section's outcome screen alike.
##
## Where she goes is this file's answer because only this file holds both worlds. **The clock runs
## from here**, as a day's does from `_start_day()`: every screen that can stand in front of the
## walk pauses the tree, and the day's clock pauses with it.
##
## The baby starts every attempt asleep with sleepiness full — *"the player holding the sleeping
## baby (sleep bar is full)"* — which is also what makes a retry playable at all: the meter that
## just reached a hundred is what lost the section.
func _start_section(spec: DaySpec, restarted: bool) -> void:
	_use_the_day(spec)
	# The run's own record of where it is, which is what the save carries and what the next boot
	# reads: written here, the one place every section of every boot passes through.
	_facts.escape_section = spec.section
	_hud.visible = false
	# Announced before its world is built or anything is placed in it, as a day is, so whatever
	# the building or the city does as it is built is counted as this section's.
	EventBus.day_started.emit(spec.number)
	_build_the_world_for(spec)
	if spec.goal == DaySpec.Goal.CITY_EDGE:
		spec.exits = _the_city_exits()
	_day.setup(null, _player, _run)
	if spec.world == DaySpec.World.BUILDING:
		_add_the_building_walker()
		var start_at := _interior.start_world_position()
		if not restarted:
			start_at = _interior.part_world_position(_escape_start_part())
		_player.reset_at(start_at, Vector2.UP)
		# The same seed on every entry, so a retry is the same building.
		var building_rng := RandomNumberGenerator.new()
		building_rng.seed = _building_seed
		var none: Array[String] = []
		_building_events.start_day(spec, building_rng, none, start_at)
		_interior.start_the_night(_building_seed)
	else:
		# The building is behind her and nobody is in it, so its own events stop rather than
		# playing on to an empty map — the vents, the window flashes and the masked man who comes
		# up the shaft every few seconds would otherwise run for the rest of the sequence, unseen
		# and in the log. Starting the building's plan again is what brings them back, and section
		# one is never entered without it.
		if _building_events:
			_building_events.stand_down()
		if _interior:
			_interior.stop_the_night()
		# A restart of section two replans it: see `_plan_the_finale_city()`.
		if restarted:
			_plan_the_finale_city()
		_player.reset_at(_finale_start_position(), Vector2.DOWN)
		DayDirector.prepare_city_scenery(_city, _player)
		_city.events.stream_around(_player.global_position)
	_baby.reset()
	_baby.force_sleep()
	_day.start(spec.length)
	if spec.world == DaySpec.World.BUILDING:
		EventBus.escape_section_started.emit(spec.section, restarted, _interior, _building_events)
	else:
		EventBus.escape_section_started.emit(spec.section, restarted, _city, _city.events)
	EventBus.day_planned.emit(spec.number)
	if _interior:
		_interior.clear_fade()
	if spec.world == DaySpec.World.CITY:
		_add_the_route_rig_in_the_city()
	_flow.planned()

## `--route`'s walker (`RouteRig`, `src/dev/route_rig.gd`) on the city as it stands, started afresh
## by every `day_planned` from here on. `resistance` is null in the escape, which has no subquest.
func _add_the_route_rig(resistance: ResistanceDirector) -> void:
	_route_rig = RouteRig.new()
	_route_rig.name = "RouteRig"
	add_child(_route_rig)
	_pauses_with_the_game(_route_rig)
	_route_rig.setup(_city, _player, _baby, resistance, _day, config.route_targets, _run)
	_flow.day_planned.connect(_route_rig.start_day)
	_route_rig.use_continue(_on_summary_continued)
	_flow.brief_opened.connect(_route_rig.press_the_brief)

## `--route` in the escape's building: the game's own walker, built once, with the building (the
## city's rig, which needs the city, is built when the building is won). It presses the building's
## brief and walks her out (`BuildingWalker`, `src/dev/building_walker.gd`).
func _add_the_building_walker() -> void:
	if config.route_targets.is_empty() or _building_walker:
		return
	_building_walker = BuildingWalker.new()
	_building_walker.name = "BuildingWalker"
	add_child(_building_walker)
	_pauses_with_the_game(_building_walker)
	_building_walker.setup(_interior.map, _player, _day)
	_building_walker.use_continue(_on_summary_continued)
	_flow.day_planned.connect(_building_walker.start_section)
	_flow.brief_opened.connect(_building_walker.press_the_brief)

## `--route` in the escape's city: the game's own walker, built once the city stands — the first
## time a city section starts — and started on every attempt, with no `ResistanceDirector`. Its
## targets are the city's two ways out (`tunnel`, `bridge`) as much as anything a day offers. A rig
## the building section was booted with is built here, when the building has been won, and presses
## the city's brief's continue itself (`RouteRig.press_the_brief()`).
func _add_the_route_rig_in_the_city() -> void:
	if config.route_targets.is_empty() or not _city or _route_rig:
		return
	_add_the_route_rig(null)

## The screen a section opens on, over the world she is already standing in — *"each the apartment
## and escape city are treated as their own 'days' with brief and restart checkpoint"*: the day
## brief (`SummaryModel.brief_for()`), with the section's own words where "Day N of 14" stands.
## Its continue engages the section the way a resumed day's brief does (`_on_summary_continued()`).
##
## **It is also where the save is written.** A section's brief is the escape's only checkpoint, so
## it is the moment a closed game has to come back to, and the run's own record of which section
## that is (`GameState.facts.escape_section`) was set as the section began. `false` because a section is
## never saved as under way (`DaySpec.saved_as_under_way`): a resumed escape is not charged a nerve
## for it.
func _show_the_section_brief() -> void:
	_flow.open_brief()
	_save_now(false)
	_summary.show_summary(SummaryModel.brief_for(_run, "", _flow.spec.title), _flow.mode)

## Where section two starts and restarts: the service exit, on the street beside the home block.
func _finale_start_position() -> Vector2:
	return FinalePlanner.service_exit_world_position(_city.map)

## Both screens' own restart reaches the one thing that means it, and both screens' own way out
## reaches the same quit — pulled into its own function, called once `_summary` and `_pause` both
## exist, rather than left as four lines split across each screen's own instantiation.
##
## **This is the fix for the day summary's own restart button holding, filling its bar, firing its
## signal, and being heard by nobody** — `_summary.restart_requested` had no connection at all next
## to `_pause.restart_requested.connect(_restart_run)`, which is the shape
## `tests/test_main.gd`'s restart-signals test now holds so a screen added
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
## a real ending, and `space` restarts the run like any other finished one. `config.ending_override`
## is "" on a release page nobody asked `?debug=1` of, so this cannot fire for a player.
func _show_an_ending_for_a_rig() -> bool:
	var wanted_arg := config.ending_override
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
	_flow.show_ending()
	_summary.show_summary(SummaryModel.ending(_run, wanted[wanted_arg] as GameEnums.Ending),
			_flow.mode)
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
## The HUD, the screen-edge badge, the developer readout and the frame graph all come off, because
## every one of them is a statement about a player who is not there
## (`DebugReadout.open_the_title()`, which keeps the graph's ring).
##
## **Re-asks `_apply_orientation()` right here, as a safeguard.** In the running game it finds
## nothing to change: `_ready()` asked a moment earlier in the same uninterrupted stretch, with no
## frame between the two calls, and the web build re-reads the window's size only between frames.
## It keeps the title from depending on that: whatever reaches this screen, the title is turned to
## the window's current answer before it is drawn, rather than a frame later through `_process()`'s
## poll. Idempotent and cheap (see `_apply_orientation()`'s own doc).
##
## **Behind the escape's title nothing runs**: a resumed escape opens here over a section already
## built, and the section's world stays paused with her standing in it until its brief is
## dismissed — the city playing on with nobody in it is a day's front door, not a section's.
func _open_the_title() -> void:
	# The title says "again" over a run that ended on this boot.
	var again := _flow.mode == RunFlow.Mode.ENDING or _flow.mode == RunFlow.Mode.EPILOGUE
	_flow.open_title()
	# Guarded the same shape `_on_title_start()`'s own final line already is, and for the same
	# reason: a test may drive this function on a script-only `main` with no tree behind it. Never
	# false in the running game, where this only ever fires on a real `main` already in the tree.
	if is_inside_tree():
		get_tree().paused = true
	_apply_orientation()
	if _flow.spec.section == DaySpec.Section.NONE:
		_city.process_mode = Node.PROCESS_MODE_ALWAYS
		_player.process_mode = Node.PROCESS_MODE_PAUSABLE
		_player.stand_aside()
	_hud.visible = false
	_edge_layer.visible = false
	if _readout:
		_readout.open_the_title()
	_title.open(again, _resume.is_empty(), not _resume.is_empty())

## The title screen has been pressed, which is also the start: hand the city back to the day it
## belongs to.
##
## `mode` is the player's own answer to the controls question — a press on one of `TitleScreen`'s
## two `Symbol.JOYSTICK` buttons or its `Symbol.TAP` one, or `Mode.TAP` when a key began the run
## instead — and `side` is which half a joystick button chose to steer from. Both are handed
## straight to `_touch_controls.set_mode()`, which overrides whatever `_add_touch_controls()` set
## from `config.controls_word` at boot — see that function's own doc for why a rig that never
## reaches this screen keeps that earlier answer instead. `by_key` says a key began the run, which
## reaches the counter alone: the controls a key player gets are still `mode`'s.
##
## Guarded with `is_inside_tree()` the same way `_process()` already guards `get_window()`: false
## for a script-only instance a test drives straight through this function with no tree behind it
## at all — `get_tree()` itself logs an engine-level error when called off-tree,
## which `is_inside_tree()` never does, so this is the check to make rather than a null check on
## `get_tree()`'s own return. Never false in the running game, where this only ever fires on a real
## `main` already in the tree.
##
## **With no resume, this is also the moment she starts playing** — `_engage_the_day()` runs
## immediately. **With one, it is not**: `_show_the_resume_gate()` opens instead, and it is *that*
## screen's own continue that reaches `_engage_the_day()`, through `_on_summary_continued()` with
## the flow in `RunFlow.Mode.BRIEF`.
func _on_title_start(mode: ControlsMode.Mode, by_key := false,
		side := ControlsMode.Side.LEFT) -> void:
	# Which control scheme was picked, or that a key began the run: the HUD rewords its walking
	# lesson by it and the page counts it.
	EventBus.controls_chosen.emit(mode == ControlsMode.Mode.JOYSTICK, by_key)
	_touch_controls.set_mode(mode, side)
	ControlsMode.remember(mode, side)
	if _readout:
		_readout.close_the_title()
	# A new game's mode is the title's Hard Mode checkbox, read as the title is dismissed — the
	# checkbox shows only for a new game (`_open_the_title()`), and a resumed run keeps the mode
	# its save carries.
	if _resume.is_empty():
		_run.calendar.choose_mode(_title.hard_mode_checked())
		EventBus.run_mode_chosen.emit(_run.calendar.hard_mode, _run.header.day)
	_title.close()
	if not _resume.is_empty():
		_show_the_resume_gate()
		return
	_engage_the_day()

## What pressing start on the title leads to when a save was resumed — the day brief showing what
## the load already paid for, or the ending directly when the load itself spent the run's last
## nerve, the same screen and the same `_on_summary_continued()` path any other run-ending reaches.
## Split out of `_on_title_start()` so a test can drive the outcome directly against a bare
## `_summary`, without paying for the whole boot this is normally reached from.
##
## Writes nothing itself: `_ready()`'s own write right after `_start_day()` — `false`, made before
## the title was ever shown — already has the load's own charge on disk, for a resumed run, so a
## kill at any instant between here and the day brief's own continue finds exactly what this
## screen is showing, never a second charge and never a free one.
func _show_the_resume_gate() -> void:
	if _run.header.ending != GameEnums.Ending.NONE:
		# The last nerve the load itself spent, in hard mode — same ending, same screen, as a hard
		# run that reaches zero nerves any other way. `GameState.calendar.finish_day()` set the
		# ending in `_ready()`, so nothing downstream can write a save naming this run again.
		_flow.show_ending()
		_summary.show_summary(SummaryModel.ending(_run, _run.header.ending), _flow.mode)
		return
	_flow.open_brief()
	# The second of the two moments a page may load in, open for as long as the brief is up and
	# shut again by the continue that dismisses it (`_on_summary_continued()`). **Nothing loads
	# here today** — the boot above already holds every group a day draws — and it is opened
	# anyway because this is the screen a page the boot could not have known about belongs behind:
	# a group whose membership depends on the day would be acquired between these two lines.
	AtlasLibrary.open_loading_window(AtlasLibrary.MOMENT_DAY_BRIEF)
	_summary.show_summary(SummaryModel.brief_for(_run, _resume_gate_note(), _flow.spec.title),
			_flow.mode)

## The day brief's one line about what opening the save cost: nothing, a nerve and the same dawn,
## or — a normal run's last nerve — the checkpoint `GameState.calendar.finish_day()` already
## went back to, whose day `GameState.header.day` now holds.
func _resume_gate_note() -> String:
	if not _resume.get("day_under_way", false):
		return ""
	if _resume_went_back:
		return Texts.RESUMED_LAST_NERVE % _run.header.day
	return Texts.RESUMED_DAY_LOST

## Hands the day already built and paused behind a gate — the title, on a fresh or a resumed run
## the load left with nothing charged, or the day brief the load put on top of it — over to the
## player: the moment she is actually playing it, which is also the moment the save has to say so,
## immediately rather than leaving the next write to whichever of the day's own two other moments
## (a resumed run's own dawn write in `_ready()`, or the day's own end) happens to come next.
## Called from `_on_title_start()` directly (no resume) and from `_on_summary_continued()` on a
## brief (`RunFlow.Mode.BRIEF`, the day brief's continue, a section's brief included) — the two, and
## the only two, places a gate she has not yet dismissed stands between a built day and the day she
## is actually walking.
##
## **A section of the escape is said by name every time it is engaged**, a first entry, a retry and
## a resumed entry alike — the line its brief carries where "Day N" stands (`DaySpec.title`), said
## once she is walking it since the HUD runs through a pause and a line said behind the brief would
## spend its life there. *(2026-09-20, the player, on the escape generally: "the escape shouldn't
## behave any different than the rest of the game".)* And it is not saved as under way
## (`DaySpec.saved_as_under_way`): its brief was its save.
func _engage_the_day() -> void:
	_flow.engage()
	_player.step_back_in()
	_hand_the_crowd_her()
	if _city:
		_pauses_with_the_game(_city)
	_hud.visible = true
	_edge_layer.visible = true
	if _readout:
		_readout.show_for_the_walk()
	if is_inside_tree():
		get_tree().paused = false
	if _flow.spec.title != "":
		_hud.say_once(_flow.spec.title)
	if _flow.spec.saved_as_under_way:
		_save_now(true)

## The screen-edge half of the danger vocabulary, in its own layer.
##
## Built here rather than inside the HUD scene because it has to ask the world where things are
## every frame, and the HUD's rule is that it listens to `EventBus` and holds no reference to
## the world. Bending that for one indicator would cost more than the node does.
##
## **One badge for every world.** It reads `_event_source()`, which is the building's events in the
## escape's first section and a `City`'s everywhere else, so
## a second call — the escape walking out of the service door — points the same badge at the city
## rather than building a second layer over the first.
func _add_danger_edge() -> void:
	if _edge:
		_edge.setup(_event_source(), _player)
		return
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
	_edge.setup(_event_source(), _player)
	layer.add_child(_edge)
	add_child(layer)

## What is charging the meter right now, drawn in world space rather than in a `CanvasLayer` —
## unlike `DangerEdge`, this cue is a picture of the ground itself, not screen furniture laid over
## it, so it has to sit where the ground does and move with the same camera.
##
## It draws on the halo layer (`DrawLayer.Layer.HALO`): over the ground and under the entities, the
## y-sorted layer the player, the crowd and every event live on — under everything the cue is
## required to be under, none of which can ever read as lit from beneath. It is over the buildings
## rather than under them as well, which a glow can afford: a wall the field happens to reach warms
## slightly, the way it would under any coloured light near it, and nothing the cue exists to
## protect is a wall.
## `_pauses_with_the_game()` is the same reasoning `_city` gets: while the tree is paused nothing
## it reads is moving either, so freezing alongside the world it draws needs no case of its own.
##
## Called once per world the same way `_add_danger_edge()` is: in the escape's building it reads
## the building's events and no crowd, and walking out of the service door points it at the city.
func _add_excitement_halo() -> void:
	if _halo:
		_halo.setup(_excitement_now(), _player, _baby)
		return
	_halo = ExcitementHalo.new()
	_halo.name = "ExcitementHalo"
	DrawLayer.draw_on(_halo, DrawLayer.Layer.HALO)
	_halo.setup(_excitement_now(), _player, _baby)
	add_child(_halo)
	_pauses_with_the_game(_halo)

## What the badge, the halo, the debug view, the readout and the loss's cause read the world's events
## from: the building's while the escape's first section is the only world there is, and a `City`'s
## once there is a city — a day's, or the escape's second section, which the building never comes
## back after. Each is an `EventManager`.
func _event_source() -> EventManager:
	if _city:
		return _city.events
	return _building_events

## The crowd, or null in the escape's building, which has nobody in it but its events.
func _crowd_now() -> Crowd:
	return _city.crowd if _city else null

## What the halo reads the world's charges from (`WorldContext.excitement_sources`): a `City`'s
## events and crowd once there is a city, and the building's events alone before.
func _excitement_now() -> Array[ExcitementSources]:
	if _city:
		return _city.excitement_sources
	var sets: Array[ExcitementSources] = []
	if _building_events:
		sets.append(_building_events.sources)
	return sets

## The world whose subtree holds the bodies the debug view's bounding boxes trace.
func _world_now() -> Node2D:
	if _city:
		return _city
	return _interior

## A plain camera made current before the boot's own player exists, so the two frames
## `_warm_the_canvas_shaders()` awaits below draw `ground` — the doorstep, in `_ready()`'s case —
## rather than the world's default identity transform, whose origin sits at the top-left of
## whatever is in the tree under it.
##
## **Turned the way the window wants before it enters the tree**, through the same
## `_apply_orientation()` her own camera is later turned by, because the frames it shows are the
## ones a phone sees first. *(PLAYTEST-140: "when you lose with game over the title screen is
## sideways"; PLAYTEST-144's still after a held restart, "This is the screen when resetting".)*
## The root window outlives a scene reload, and with it the `content_scale_size` the previous
## boot left: after a restart on a portrait phone the new boot already presents in the rotated
## 720x1280 box, so an unturned camera here draws the city upright in it, filling the screen the
## wrong way up — and that frame stays on screen through the rest of `_ready()`, `_start_day()`
## included, until the title is drawn. On a first boot the window still has the project's
## 1280x720 box, which the same call swaps before the first frame.
##
## **Freeing it is what hands the viewport's current camera to the player's own.** A `Camera2D`
## that exits the tree while it is the viewport's current one looks for another enabled camera on
## the same canvas and makes that one current in its place, and the stroller's own `Camera2D`
## (`scenes/player/stroller.tscn`) — sitting dormant since it entered the tree while this one was
## already current — is the only other camera the boot ever has in the tree by then.
## `_retire_the_boot_camera()` is that free, and forgets it for `_apply_orientation()` too.
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
	_boot_camera = camera
	_apply_orientation()
	add_child(camera)
	_pauses_with_the_game(camera)
	camera.make_current()
	return camera

## Frees the boot camera once her own stands where it stood — see `_new_boot_camera()` for why
## freeing is what hands the view over — and forgets it, so `_apply_orientation()` stops turning a
## camera that is gone.
func _retire_the_boot_camera() -> void:
	_boot_camera.free()
	_boot_camera = null
	if _player:
		var camera: Camera2D = _player.get_node("Camera2D")
		# A dormant camera has no current target in movie mode. Read the placed transform
		# before resetting smoothing, then publish that center before the first drawn frame.
		camera.force_update_scroll()
		camera.reset_smoothing()
		camera.force_update_scroll()

## Takes every baked page this boot will ever need, inside a named loading window, and holds it
## for the life of the process. *(PLAYTEST-109: "we cannot start loading something in the frame we
## need it. UI elements should always be there.")*
##
## **A page loads here or in a day brief and nowhere else.** `AtlasLibrary.acquire()` is a
## blocking `load()` in whatever frame calls it, so the window is what turns "before the player
## can see a frame" from a convention into a rule: everything the consumers do afterwards is a
## reference count on a page that is already resident, and an `acquire()` that still has to read
## from disk names itself `OUTSIDE` in the run log and raises an engine error the test gate is red
## for.
##
## **The parent is known by now on every path**, which is why it is taken here rather than in a
## first day brief: `GameState.start_run()` rolls it (`_ready()`, a few lines above the call) and
## a resumed run reads it off the save in the same place, both before the city is built. The other
## parent's page is dropped rather than left held, because the held restart (`_restart_run()`)
## reloads the scene into the same process and rerolls the choice — without this, one process that
## restarted once would be holding both.
func _hold_every_page_a_day_draws(moment: StringName, also: Array[StringName]) -> void:
	var elapsed := Time.get_ticks_msec()
	AtlasLibrary.claim_the_loading_moments(moment)
	for group in RESIDENT_GROUPS:
		AtlasLibrary.hold_for_the_process(group)
	for group in also:
		AtlasLibrary.hold_for_the_process(group)
	AtlasLibrary.stop_holding(Stroller.parent_atlas(not _run.header.player_is_male))
	AtlasLibrary.hold_for_the_process(Stroller.parent_atlas(_run.header.player_is_male))
	AtlasLibrary.close_loading_window()
	# Beside "city generated in N ms" for the same reason that one is printed: a reader working
	# out where a boot went belongs next to the other numbers.
	print("[Main] %d atlas pages held from %s in %d ms"
			% [RESIDENT_GROUPS.size() + also.size() + 1, moment, Time.get_ticks_msec() - elapsed])

## Hands the loading moments back, so a scene reload — the held restart — boots into a fresh
## claim rather than into this instance's closed window. The residency itself is deliberately not
## given back: the reloaded boot wants exactly the same pages and giving them up here would be a
## reload of every one of them, which is the thing the residency exists to prevent.
func _exit_tree() -> void:
	AtlasLibrary.release_the_loading_moments()

## Gets the Compatibility renderer to compile the halo and shoreline shader programs before their
## first real drawings. **Godot 4.7 has no precompile call for this renderer** — `RenderingServer`'s own
## pipeline cache is a Forward+/Mobile (RenderingDevice) feature, and the engine's own proposal
## tracker still carries "Add shader precompilation to the Compatibility rendering method" as an
## open request — so the only lever left is a real draw call. Two throwaway `Node2D`s draw the
## halo material and the actual water atlas region through `SceneryWater.material_for()`, then are
## freed after the frame reaches the renderer. Their shader outputs are transparent, so the boot
## cannot flash either probe even though both sit inside the visible canvas.
##
## **At `ground`, not off in the distance.** A canvas item outside the camera's visible rect is
## culled before it reaches the renderer — see M139, "one atlas for the crowd", on why an
## off-screen `CrowdAgent` costs nothing per frame — and a culled draw would compile nothing,
## defeating the whole pass. `ground` is the boot camera's own `global_position` (see
## `_new_boot_camera()`, made current by both boot paths before this is ever called), so probes
## placed there sit exactly at that camera's own screen centre — on screen
## regardless of zoom or viewport size. Fully transparent (`halo_colour`'s instance uniform
## default, never set here) makes it imperceptible regardless: the GLSL program compiles from the
## material and the draw call alone, never from the pixels it happens to write.
##
## **Two awaits, not one.** `SceneTree.process_frame` fires *before* the frame it names is drawn —
## `DaySummary._acknowledge_and_continue()` confirms this directly against `RenderingServer`'s own
## `frame_pre_draw`/`frame_post_draw` — so a single await would free the probe before its queued
## draw ever reached the renderer, and the shader would still compile late, on the first real halo.
func _warm_the_canvas_shaders(ground: Vector2) -> void:
	var halo_probe := Node2D.new()
	halo_probe.name = "HaloWarm"
	halo_probe.global_position = ground
	halo_probe.material = EntityHalo.shared_material()
	halo_probe.draw.connect(func() -> void:
		halo_probe.draw_rect(Rect2(Vector2.ZERO, Vector2.ONE), Color.WHITE))
	add_child(halo_probe)
	_pauses_with_the_game(halo_probe)
	halo_probe.queue_redraw()

	var water_texture := AtlasLibrary.region(&"tiles/water") as AtlasTexture
	var water_probe := Node2D.new()
	water_probe.name = "WaterWarm"
	water_probe.global_position = ground
	water_probe.material = SceneryWater.material_for(water_texture)
	water_probe.draw.connect(func() -> void:
		water_probe.draw_texture_rect(water_texture,
				Rect2(Vector2.ZERO, water_texture.get_size()), false, Color.TRANSPARENT))
	add_child(water_probe)
	_pauses_with_the_game(water_probe)
	water_probe.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	halo_probe.queue_free()
	water_probe.queue_free()

## The developer's furniture over the run — see `DebugReadout`, which is handed the run's
## configuration, the readout's label and layer from this scene, the run, the session its snapshots
## go to and what screen is up. A child of this node, so it keeps running through a pause. It hears
## the day being walked and its plan from the flow (`RunFlow.day_started`, `day_planned`).
func _add_the_readout() -> void:
	_readout = DebugReadout.new()
	_readout.name = "DebugReadout"
	add_child(_readout)
	_readout.setup(config, _status, _status_layer, _run.header, _session, _screen_name)
	_flow.day_started.connect(_readout.use_the_day)
	_flow.day_planned.connect(_readout.use_the_plan)

## What screen is up, for a snapshot's line.
func _screen_name() -> String:
	if _title and _title.is_open():
		return "title"
	if _pause and _pause.is_open():
		return "paused"
	return "playing"

## Shows the debug furniture the world she is walking: its overlays are built the first time and
## pointed at the city when the escape walks out of the building, with whatever `1`–`3` had on
## still on. Called once per world, the way `_add_danger_edge()` is.
func _add_debug_layers() -> void:
	if not _readout:
		return
	_readout.show_the_world(_event_source(), _crowd_now(), _world_now(), _world_map(),
			_city)

## The day's planned routes over the city — see `DebugReadout.draw_routes()`.
func _add_route_lines() -> void:
	if _readout:
		_readout.draw_routes(_city.map)

## A rig's lock-out — see `RigLock` — as early as this scene's script can act.
func _add_the_rig_lock() -> void:
	_rig_lock = RigLock.new()
	_rig_lock.name = "RigLock"
	add_child(_rig_lock)
	_rig_lock.setup(config)

## The half second of ignored input after the game gets focus back — see `ReturnWindow`. Its
## departures open the pause (`_pause_on_focus_lost()`); a rig and `--no-focus-pause` are never
## slowed by it.
func _add_the_return_window(viewport: Viewport) -> void:
	_return_window = ReturnWindow.new()
	_return_window.name = "ReturnWindow"
	add_child(_return_window)
	_return_window.left_the_game.connect(_pause_on_focus_lost)
	_return_window.setup(viewport, _no_focus_pause,
			_rig_lock != null and _rig_lock.locked_out)

## The one control scheme, in its own layer for the same reason the danger edge gets one: it has to
## sit above the world it overlays. One node goes into the tree rather than a choice between two —
## `TouchControls` answers whether it is *shown* itself, off `TouchInput.available()` and
## `get_tree().paused`, which is what a title screen, the pause and the between-days summary all
## set. That is one fact main already produces for other reasons rather than a second wire main
## would have to remember to pull on every one of those screens.
##
## `set_mode()` with `config.controls_word`'s mode and steering side gives it what a rig gets if
## the title screen is never reached at all (`--no-title`, a screenshot rig) — `--controls`, then
## the page's own `?controls=` in the open bundle, then `TAP`. This is only ever the **pre-title**
## answer: `_title` does not exist yet at this point in `_ready()`, and `main._on_title_start()`
## overrides it the moment a player actually presses one of the title screen's own buttons.
##
## **Except on the two boots that open no title of their own** while the title's answer is still in
## this process: the day-14 hand-over to the escape (`RunFlow.escape_from_a_run()`) and a normal run
## carried on from its checkpoint (`RunFlow.Opening.CARRIED_FROM_CHECKPOINT`). Each keeps the mode and steering side the
## player chose on the run's title (`ControlsMode.remember()`) rather than falling back to the rig's
## default — the side is "permanently for the sitting" (2026-10-10). A game closed inside a section
## and opened again has no answer in memory, and its title asks.
func _add_touch_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TouchControls"
	_touch_layer = layer
	add_child(layer)
	_touch_controls = TOUCH_CONTROLS.instantiate()
	_touch_controls.use_touch(_touch_available)
	_touch_layer.add_child(_touch_controls)
	_touch_controls.rotated = _rotated
	if (_flow.escape_from_a_run() or _flow.opening == RunFlow.Opening.CARRIED_FROM_CHECKPOINT) \
			and ControlsMode.has_remembered():
		_touch_controls.set_mode(ControlsMode.remembered_mode(), ControlsMode.remembered_side())
	else:
		_touch_controls.set_mode(ControlsMode.from_word(config.controls_word),
				ControlsMode.side_from_word(config.controls_word))
	_hand_the_controls_cover_to_the_events()

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
## through a `CanvasLayer`, so it rotates separately, through whichever camera is current —
## `ScreenOrientation.apply_to_camera()`, on hers or on the boot camera standing in for hers.
##
## Called from `_new_boot_camera()`, again from `_ready()` once every layer exists, and from
## `_process()` whenever the answer changes — never only from a `size_changed` signal, which can
## arrive with a stale `get_window().size`, or not arrive at all if a phone is turned back to a
## shape that already reads as landscape without the browser ever resizing the canvas, latching
## the wrong `content_scale_size` until a reload. Asking the same question every frame instead
## means the decision cannot go stale between calls.
##
## **The window half is applied before anything else exists, because the window outlives a
## reload.** `content_scale_size` lives on the root window, not on this scene, so a held restart's
## `reload_current_scene()` boots into whatever box the previous boot left. The box, the boot
## camera and every layer already built are turned the moment the boot camera is made, ahead of
## the first frame `_warm_the_canvas_shaders()` draws; `_player`, `_touch_controls` and `_hud`,
## which are not built until after that await, are turned once they exist. `_rotated` is set only
## then, so `_process()` keeps asking until the whole presentation has been turned once. A
## script-only `main` in a test has none of them and gets the window half alone.
##
## Reads the window through `Engine.get_main_loop()` rather than `get_window()`, the same
## substitution `_tree_is_paused()` makes and for the same reason: `get_window()` needs `main`
## itself inside a tree, which is true for the running game but not for the script-only `main`
## a test drives straight through `_open_the_title()`. There is exactly one
## `SceneTree` for the whole process either way, so asking the engine for its root window answers
## the same question a parented `main`'s own `get_window()` would.
##
## **Both inputs are the current frame's on the Web export (Godot 4.7's own source).**
## `_touch_available` (`TouchInput.available()` → `DisplayServer.is_touchscreen_available()`)
## compiles on Web to `'ontouchstart' in window`, a static browser capability check rather than one
## learned from a touch, cached nowhere in this project. `window.size` is the canvas element's own
## `width`/`height`, which the page's `requestAnimationFrame` callback resyncs against the real
## viewport (`DisplayServerWeb::check_size_force_redraw()`) before each frame's processing runs. So
## `_process()`'s poll cannot stay wrong for more than a frame once this node is processing; what it
## cannot reach is a frame drawn before anything here has been asked, which is why the boot camera
## asks first.
func _apply_orientation() -> void:
	var loop := Engine.get_main_loop()
	if not loop is SceneTree:
		return
	var window := (loop as SceneTree).root
	var rotate := ScreenOrientation.wants_rotation(window.size, _touch_available)
	window.content_scale_size = ScreenOrientation.content_scale_size(rotate)
	if _boot_camera:
		ScreenOrientation.apply_to_camera(_boot_camera, rotate)
	# Every layer of screen furniture carries the same rotation, so the world (rotated by the
	# camera) and everything drawn over it agree — see `ScreenOrientation`'s class doc for why a
	# `CanvasLayer` transform is the mechanism and `apply_to_layer()` the one place that reads
	# `if rotate: ... else: IDENTITY`. A layer not built yet — the escape builds its world's
	# layers as each section begins — is skipped rather than assumed.
	for layer in _screen_furniture_layers():
		if layer:
			ScreenOrientation.apply_to_layer(layer, rotate)
	if not _player or not _touch_controls or not _hud:
		return
	_rotated = rotate
	_player.set_screen_rotation(rotate)
	_touch_controls.rotated = rotate
	# `_edge` (the screen-edge badge) is built with the first world the boot builds — see
	# `_add_danger_edge()` — so it is null only for a script-only `main` a test drives by hand.
	if _edge:
		_edge.rotated = rotate
	_hud.set_rotated(rotate)

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

## Builds and starts the day, through the flow (`RunFlow.start_day()`), which has the director
## start the game's own day or an authored scene's; writes nothing itself. Each caller decides what,
## if anything, the save should say about the day this just built — see `_ready()`'s own call
## (nothing for a fresh run, `false` for a resumed one) and `_on_summary_continued()`'s (`true`,
## since nothing gates an ordinary continue into the next day at all). False, with the game quitting,
## when an authored scene's setup did not stand.
func _start_day() -> bool:
	var errors := _flow.start_day(_new_director(), day_spec(config, _run.header.day))
	if not errors.is_empty():
		_scene_failed(errors)
		return false
	_first_day = false
	return true

## The director for the world as it stands now: the city (none in the escape's building), whichever
## world's events, and the parts every day shares. Cheap and stateless, so built when a day starts
## or ends rather than kept in step with a world that is rebuilt between sections.
func _new_director() -> DayDirector:
	var director := DayDirector.new(_run.calendar, _run.facts, _run.attempt_spend, config)
	director.use_the_world(_city, _event_source(), _resistance, _player, _baby, _day)
	director.first_day = _first_day
	director.escape_follows = _flow.escape_follows()
	director.spec = _flow.spec
	return director

## The day or section about to be walked, announced to the observers (`RunFlow.day_started`) and
## handed to the day's clock, which may be absent from a script-only `main` a test builds by hand.
func _use_the_day(spec: DaySpec) -> void:
	_flow.begin(spec)
	if _day:
		_new_director().use_the_day(spec)

## `--recipe`: loads the scene recipe, lays its seed, day, escape part and parent on the run's
## configuration (`RunConfig.with_recipe()`), builds its playback (`SceneRecipeRuntime`) and
## configures the flow with it (`RunFlow.author()`), which every place an authored scene differs
## then asks. False, with the game quitting, when the recipe does not load.
func _author_the_scene() -> bool:
	var result := SceneRecipeRuntime.load_recipe(config.recipe_path, config.active_args)
	if not result.errors.is_empty():
		_scene_failed(result.errors)
		return false
	configure(config.with_recipe(result.data))
	var scene := SceneRecipeRuntime.new()
	scene.configure(result, config, _run)
	add_child(scene)
	_flow.author(scene)
	return true

## The authored scene starts playing, once the boot's world stands and her own camera is current.
## **An escape scene plays from its first frame, with no brief in front of it**: its setup is
## installed over the section the boot started (`_the_first_day()`, the spec its clock runs), and
## she walks it at once. False, with the game quitting, when that setup does not stand.
func _begin_the_scene(walks_a_day: bool) -> bool:
	if not walks_a_day:
		var problems := _flow.scene.install(_city, _player, _baby, _flow.spec)
		if not problems.is_empty():
			_scene_failed(problems)
			return false
		DayDirector.prepare_city_scenery(_city, _player)
		get_tree().paused = false
		_day.start(_flow.spec.length)
		_hud.visible = true
	_flow.scene.begin()
	if not walks_a_day:
		_flow.engage()
		_hand_the_crowd_her()
	return true

## The authored scene could not be set up: its problems are printed and the game quits non-zero.
func _scene_failed(errors: Array) -> void:
	for problem: Variant in errors:
		print("[SceneRecipe] " + str(problem))
	get_tree().quit(1)

## Whatever `_start_day()`'s own dawn should say about the day it just built, said right after
## that call returns — pulled out of `_ready()` on its own so a test can drive the decision
## directly without paying for the world `_start_day()` builds around it.
##
## **A resumed run whose save had a day under way writes `false` here**, before the title — and, on
## the way to the day brief, that screen too — is ever shown, so the nerve `_ready()` just charged
## through `GameState.calendar.finish_day()` is on disk, with no day under way, the instant
## either gate appears rather than only once she presses past one. *(cozy-pelican, 2026-10-02,
## on what opening a saved game writes: "either it saves with one less nerve and a cleared
## "during active game" flag. or you defer saving to the actual day start".)* This is what the
## kill-at-any-instant argument in docs/MECHANICS.md, "Saving and resuming", rests on: nothing
## between this write and `_engage_the_day()`'s own `true` ever depends on a notification
## catching anything. When the charge ended the run, the `run_ended` subscriber
## (`GameSave.clear_when_a_run_ends()`) has already deleted the save and `GameSave.write()`
## refuses an ended run, so nothing is written there.
##
## **A resumed run whose save was written between days writes nothing**: it charged nothing, and
## the file on disk already says `day_under_way: false`, so a rewrite would change no fact it holds
## — only draw the symbol over a title nobody has played past. The next write is
## `_engage_the_day()`'s `true`, the instant she starts the day.
##
## **A fresh run (`_resume.is_empty()`) writes nothing at all.** Merely opening the game to look at
## the title is not playing it, and there is no earlier save to protect a charge on — the first
## write for a fresh run is `_engage_the_day()`'s own `true`, the instant she actually starts. The
## held restart reaches the same case: `GameSave.clear()` (`_restart_run()`) leaves
## `GameSave.try_resume()` nothing to find on the reload that follows, so `_resume` is empty there
## too and the reloaded boot writes nothing until its own title is dismissed.
func _write_dawn_for_a_resumed_run() -> void:
	if _resume.get("day_under_way", false):
		_save_now(false)

## **The one place a day ends, the escape's sections included**: `DayDirector.finish_day()` ends it
## — what ended it, the charges still running closed, `day_ended` with its cause, which the run log
## and the page's counter both hear — and this writes the save and raises the screen the day ends on,
## after what the day's `DaySpec` says the outcome costs and leads to.
## *(minty-lemur #785: "losing an escape should still state the reason like the rest of the game.
## nothing should be different.")*
func _on_day_finished(result: GameEnums.DayResult) -> void:
	var end := _new_director().finish_day(result)
	if end.is_section:
		_finish_the_section(end)
		return
	_flow.day_ended(end)
	if end.hands_over_to_the_escape:
		_facts.escape_section = DaySpec.Section.BUILDING
		_save_now(false)
		_summary.show_summary(SummaryModel.day_over(_run, end), _flow.mode)
		return
	# The end-of-day write — one of the two moments a run is saved. Skipped when the run just
	# ended: the `run_ended` subscriber (`GameSave.clear_when_a_run_ends()`, fired from inside
	# `finish_day()` above) already cleared the save, and writing here would resurrect a file
	# naming a run that is over. A normal run sent back to its checkpoint is written here like any
	# other loss, already standing at that dawn.
	if not end.run_over:
		_save_now(false)
	_summary.show_summary(SummaryModel.day_over(_run, end), _flow.mode)

## What a section of the escape ending leads to, once `_on_day_finished()` has ended it as it ends
## any day — the section's `DaySpec` says the rest.
##
## - **Lost:** the run spends what the section's rules say (`GameState.calendar.finish_day()`:  
## nothing in a
##   normal run, a Nerve in a hard one, whose last is the bad ending), the save is written, and the
##   day's outcome screen comes up with its reason and the section's own words where "Day N" stands.
##   Its continue is the retry, the same section from its own start behind its brief
##   (`_on_summary_continued()`), and a hard run's last nerve shows the ending after it, as a lost
##   day's does.
## - **Won, into the next section** — out of the building's service exit: the city is built behind
##   the black the exit left, and its brief comes up over it.
## - **Won, out of the city** — the tunnel mouth or the bridge deck: for a run, the run itself ends
## here (`GameState.calendar.finish_day()` on the last day picks the ending, writes the  
## `ending` entry and
##   clears the save, which is also what keeps the save alive for every attempt before this one).
##   The sequence ends on a summary screen with the way out behind her and nothing triumphant on
##   it (`SummaryModel.epilogue()`), and its continue goes back to the title.
##
## What the page counts of the escape under its own names (`nappy-escape-lost`, `-city`, `-out`)
## goes out here too, beside the day's own `day_ended`.
func _finish_the_section(end: DayEnd) -> void:
	var spec := _flow.spec
	var result := end.result
	var won := result == GameEnums.DayResult.WON
	if not won:
		EventBus.escape_lost.emit(spec.section, result)
	elif spec.a_win_leads_into != DaySpec.Section.NONE:
		EventBus.escape_city_entered.emit()
	else:
		# Before `finish_day()`, whose `ending` line closes the run: the way out is part of how it
		# ended. `EventBus.run_ended` fires a moment later, from
		# `GameState.calendar.finish_day()` below.
		EventBus.escape_out.emit(_day.exit_reached)
	# The flag's escape is a day-1 run that only jumped here, so getting out of it settles nothing;
	# a lost section costs what it costs either way.
	var run_over := false
	if not won or _flow.escape_from_a_run():
		run_over = not _run.calendar.finish_day(result, spec)
	if not won and _flow.section_lost(run_over) == RunFlow.Step.RETRY_AUTHORED:
		# A scripted recipe fails on a lost attempt; a free one reloads every authored actor and
		# progression field rather than taking the ordinary retry.
		if not _flow.scene.lose_the_attempt():
			_reload_the_scene()
		return
	if won and spec.a_win_leads_into != DaySpec.Section.NONE:
		_start_section(escape_section_spec(spec.a_win_leads_into, config.escape_section_length()),
				false)
		_show_the_section_brief()
		return
	if won:
		# The run is over either way: for a run, `finish_day()` has just ended it, and the flag's
		# walk has nothing after its epilogue but walking it again.
		_flow.escape_won()
		_hud.visible = false
		_summary.show_summary(SummaryModel.epilogue(end), _flow.mode)
		return
	# The end-of-section write, as a lost day's is, so closing the game on this screen cannot take a
	# hard run's spent nerve back. Skipped when the run just ended, whose save
	# the `run_ended` subscriber (`GameSave.clear_when_a_run_ends()`) has already cleared.
	if not run_over:
		_save_now(false)
	_summary.show_summary(SummaryModel.day_over(_run, end, spec.title), _flow.mode)

## The continue of every screen `_summary` shows, carried out as the flow's `RunFlow.continued()`
## says: the screen decides it by the mode it was raised in (`raised_in`, a `RunFlow.Mode` sent with
## the continue), not a flag read here. A tap and a key that reach one screen send one continue
## between them (`DaySummary._acknowledge_and_continue()`).
func _on_summary_continued(raised_in: int) -> void:
	match _flow.continued(raised_in as RunFlow.Mode):
		RunFlow.Step.RELOAD_SCENE:
			# An authored scene played again, or the last thing the fourteen days do: a scene reload
			# rather than tearing this boot's city, day, resistance and observer down by hand and
			# building a building over them — the same reasoning `_restart_run()` gives for the same
			# call. The next boot reads `GameState.facts.escape_section` off the autoload that
			# survived it and opens on the building. Day 14's own save, written as its summary
			# appeared, may still be waiting for the browser: `_reload_the_scene()` carries its symbol
			# over, so the escape's boot adopts it and the answer settles it there.
			_summary.dismiss()
			_reload_the_scene()
		RunFlow.Step.ENGAGE:
			# The brief's own loading window shuts with the brief: from here she is walking, and a
			# page read from disk in a walked frame is the stutter the window exists to refuse.
			AtlasLibrary.close_loading_window()
			_summary.dismiss()
			_engage_the_day()
		RunFlow.Step.CARRY_TO_CHECKPOINT:
			_summary.dismiss()
			_carry_the_run_into_the_next_boot()
		RunFlow.Step.RETRY_SECTION:
			# A lost section is tried again from its own start, behind its brief, as a lost day's
			# continue leads to the day's morning: the outcome screen states why it was lost
			# (minty-lemur #785), and the brief comes up before the retry for the building and the
			# city alike (PLAYTEST-94 10). The brief's continue is the walk.
			_summary.dismiss()
			_start_section(_flow.spec, true)
			_show_the_section_brief()
		RunFlow.Step.NEXT_DAY:
			_summary.dismiss()
			_start_day()
			# No gate stands between one day's own end-of-day message and the next day's dawn, so
			# this is already the moment she is playing the next day, and the write says so at once.
			_save_now(true)
		RunFlow.Step.SHOW_ENDING:
			_summary.show_summary(SummaryModel.ending(_run, _run.header.ending), _flow.mode)
		RunFlow.Step.RESTART_RUN:
			# A run that is over goes back to where a run begins, which is the title screen: an
			# ending is not a dead end the player has to quit out of.
			_restart_run()

## A normal run back at its checkpoint goes on in a freshly booted scene, never on this one.
## *(gentle-osprey, the player: "store the exact state at the checkpoint -- continuing should not
## have anything that happened after the checkpoint".)* `GameState` was put back at the checkpoint's
## dawn by `GameState.calendar.finish_day()`, but the world built on it remembers things the
## run's state does not — day 11's boarded window over the neighbor's flat is drawn by her own
## building "for the rest of the run" — and a world rebuilt from scratch remembers nothing. So
## the continue on the lost-day screen reloads the scene, as the held restart and the escape's
## handover do, and the next boot (`RunFlow.Opening.CARRIED_FROM_CHECKPOINT`) builds the
## checkpoint's day on the run exactly as a load would give it, then starts it. The save already
## says that dawn: `_on_day_finished()` wrote it as the lost-day screen came up.
func _carry_the_run_into_the_next_boot() -> void:
	_carry_the_run_over = true
	_reload_the_scene()

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
	# `VisitCounter`'s own "a held restart, and on which day" — only for a run abandoned mid-play.
	# `_on_summary_continued()` also reaches this function from the ending screen's own continue,
	# once `GameState.header.ending` is already set; that run already reported itself through
	# `EventBus.run_ended` and is not a held restart of anything.
	if _run.header.ending == GameEnums.Ending.NONE:
		EventBus.run_restarted.emit(_run.header.day)
	# The held restart clears the save — the pause screen's and the day summary's own button both
	# reach this one function, so no new control is drawn for it. A deletion is a change in the save
	# state, which the symbol shows (`GameSave.clear()` announces it on `EventBus`); a restart after
	# the `run_ended` subscriber (`GameSave.clear_when_a_run_ends()`) already deleted the save
	# finds none and changes nothing, so it shows nothing. **Before the session closes the run
	# log**: the "deleted the save" line, and the "deletion was not kept" line when a deletion
	# fails at once, belong to this run's log. A web deletion's later answer is logged only if a
	# log is open when it arrives, so it may land in the next run's log after the reload.
	GameSave.clear()
	if _session:
		_session.close()
	# And with it the run's record of being in the escape, which outlives the scene reload below
	# because it lives on an autoload. Left set, the fresh boot would skip its own `start_run()` and
	# open the escape again over a run that was just thrown away. A no-op for a restart from an
	# ordinary day and for a finished run, which the `run_ended` subscriber has already cleared.
	_facts.escape_section = DaySpec.Section.NONE
	TitleScreen.note_restart_requested()
	_reload_the_scene()

## **Every scene reload goes through here**: the held restart (`_restart_run()`), the day-14
## hand-over to the escape (`_on_summary_continued()`), a normal run carried on from its checkpoint
## (`_carry_the_run_into_the_next_boot()`) and a free recipe's lost escape section played again
## (`_finish_the_section()`). A reload frees this node and the symbol under it, and a change in
## the save state may still be waiting for the browser — the restart's deletion, the lost day's
## write a checkpoint reload follows, or day 14's own save at the hand-over — so the symbol is
## carried over first (`_carry_the_save_symbol_over()`) and the next boot adopts it. One place, so
## a reload added later cannot forget the symbol, nor leave the flow in any mode but RELOADING.
##
## The tree is unpaused first: `reload_current_scene` builds the new scene into the same tree, and
## a paused one would open the next screen over a game that could never start. Read through
## `Engine.get_main_loop()` rather than `get_tree()`, so a test can drive the paths that reach this
## with a `main` that is not parented, and the reload itself goes to what `use_reload()` was handed
## when a test has handed one: a real reload would throw away the test runner's own scene.
func _reload_the_scene() -> void:
	_flow.reload()
	_carry_the_save_symbol_over()
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false
	if _reload_override.is_valid():
		_reload_override.call()
		return
	tree.call_deferred("reload_current_scene")

## The scene tree's own pause flag, read through `Engine.get_main_loop()` rather than `get_tree()`
## so this can be asked whether or not `main` itself is parented. `get_tree()` logs an
## engine-level error off-tree — the same reason `_on_title_start()` guards it with
## `is_inside_tree()` — and a test may drive `_process()` on a script-only instance with no tree
## behind it at all. There is exactly one `SceneTree` for the whole process, whether a
## person is playing or the suite is driving this frame by hand, so asking the engine for it
## answers the same question either way.
func _tree_is_paused() -> bool:
	var loop := Engine.get_main_loop()
	return loop is SceneTree and (loop as SceneTree).paused

## **The walk's tick**: the run's play time (`RunHeader.play_ticks`), the day's countdown
## (`DayController.tick()`) and the resistance's clocks (`ResistanceDirector.tick()`), one physics
## tick at a time — the one tick source all three count. **Frame
## locked** (inbox #866 in minty-dolphin): it counts the ticks the engine stepped, never a drawn frame's length, so a
## frame drawn late adds only the ticks that ran in it, a lag spike past the engine's steps per frame
## slows the game instead of adding time, and a faster machine reads no lower time. **A tick counts
## only when the walk stepped on it** (inbox #866 in minty-dolphin): the flow says she is walking (`RunFlow.Mode.
## WALKING`, so nothing counts behind the title, a brief, a summary, the ending or a scene reload on
## its way), the day is `WALKING` or `RETURNING` (a day that has just ended has already left `phase`
## at `OVER`, since `DayController._end()` sets it before emitting the signal that shows the summary),
## and the tree is not paused (the pause screen, and every screen that stands in front of the walk).
## The catch-up ticks after a hitch did step the walk, and count. This node runs through a pause
## (Esc), so the pause is asked rather than inherited. `delta` is the tick's fixed length.
func _physics_process(delta: float) -> void:
	if not _player or not _baby or not _day:
		return
	if _flow.mode == RunFlow.Mode.WALKING \
			and _day.phase in [GameEnums.DayPhase.WALKING, GameEnums.DayPhase.RETURNING] \
			and not _tree_is_paused():
		_run.header.play_ticks += 1
		# The resistance first, as the tree order always had it (`Resistance` is added before `Day`):
		# the tick a day ends on does not tick the resistance once more after the end.
		if _resistance:
			_resistance.tick(delta)
		_day.tick(delta)

func _process(delta: float) -> void:
	_dev_rig.update_follow_camera(_city)
	# Re-asked every frame rather than only on `size_changed` — see `_apply_orientation()`'s own
	# doc for why a signal alone can latch the wrong answer. The cost is one vector comparison.
	# `get_window()` is null for a script-only instance a test drives straight through `_process()`
	# with no window behind it at all.
	var window := get_window()
	if window and ScreenOrientation.wants_rotation(window.size, _touch_available) != _rotated:
		_apply_orientation()
	if not _player or not _baby:
		return
	if _flow.in_the_title():
		# `EventManager` streams around the player and there is no player, so the street outside the
		# home would play out whatever was standing on it at dawn and then quietly empty. One call a
		# frame keeps it stocked. Only the *streaming* is stood in for: what the director owes ahead
		# of her is not placed, because it is placed in front of somebody walking somewhere. Only a
		# city left running behind the title needs it: an escape's stays paused there.
		if _city and _city.process_mode == Node.PROCESS_MODE_ALWAYS:
			_city.events.stream_around(_player.global_position)
		return
	# The world's ground is asked what it does to her while she is walking it — the building's doors
	# and its service exit; nothing in the city. Nothing of the walk is asked while a screen stands
	# in front of it: this node runs through a pause (it has to, or Esc would not answer), so without
	# this the door under her feet would keep being tested against a section that has not begun.
	var world_map := _world_map()
	if world_map and _player and not _tree_is_paused():
		world_map.process_player(_player, delta)
	if _city and _flow.spec.daylight_runs_down:
		_city.set_daylight(_day.fraction_remaining())
	_hud.set_home_guidance(_flow.spec.goal == DaySpec.Goal.HOME
			and _day.phase == GameEnums.DayPhase.RETURNING,
			_city.map.home_world_position() if _city else Vector2.ZERO)
	# The red arrow: `ResistanceDirector.red_arrow_target()` is the one place that decides
	# whether today's task is on offer with its mark already touched, and which of the places
	# that answer it the arrow points at, so this is only ever a read of it, never a placement
	# or a move of its own — and asking it is a read too: the director chooses in its own
	# `tick()`. `_resistance` can be null here: a test may drive
	# `_process()` with a script-only `main` that never builds one.
	var task_at := _resistance.red_arrow_target() if _resistance else Vector2.INF
	_hud.set_task_guidance(task_at != Vector2.INF, task_at)

## Whether a **person** is at the controls, which is what decides if this run's log is a playtest.
##
## Two ways it is not, and they are different in kind rather than in degree:
##
## - **There is no window.** `check.sh` and the test suite boot the game headless; nobody could be
##   playing whatever else is true.
## - **Something else is holding the keys.** `--screenshot` exists to take a picture and quit,
##   `--walk`, `--flee` and `--press` are rigs that supply the input themselves, and `--route`
##   (`src/dev/route_rig.gd`) walks a whole day's worth of it on its own. A run driven by one of
##   them can be long, busy and completely unplayed, which is exactly the case the size heuristic
##   in `tools/telemetry.sh` could never catch.
## - **Godot's movie writer is recording it**, frame-locked and several times slower than real
##   time, which nobody could play.
##
## **`--seed`, `--day`, `--spawn`, `--overview` and the rest are *not* here**, and that is the line:
## they change what she is looking at, not who is steering. A playtest of act III started with
## `--day 9` is a playtest.
##
## The second and third are `config.is_rig`, the one rig list (`DevFlags`' `RIG_FLAGS`), whose
## flags answer nothing on a release build, so an ordinary player is never misread for a rig.
func _somebody_is_playing() -> bool:
	return DisplayServer.get_name() != "headless" and not config.is_rig

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
##
## **The escape's brief and its epilogue are the one exception to "opens over the summary too".**
## Each stands between her and something that has not started yet — a section's walk, or the title
## behind the epilogue's own continue — so a second screen stacked over either reads as answering a
## question nobody asked, the same reason focus loss never opens over any `_summary` at all. A lost
## section's outcome screen is not among them: it is the day's own screen, and Esc opens over it as
## it does over a lost day's (minty-lemur #785, nothing should be different). Asked of the day being
## walked (`_flow.spec`), so the guard never reaches a day's own summary.
##
## A rig's run never reaches this with a real key: `RigLock` marks every real event handled in the
## `_input` phase, ahead of this one. The debug keys are `DebugReadout`'s own.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	# Defensive rather than load-bearing: every real boot builds one, but a bare script-only `main`
	# a test drives straight through this function without also calling `_ready()` may not have.
	if not _pause:
		return
	if _pause.is_open() or _title.is_open():
		return
	# The escape's own guard — see this function's own doc, "The escape's brief and its epilogue
	# are the one exception": a section's brief up, whichever way it came, or the epilogue.
	if _flow.escape_screen_waits() and _summary and _summary.is_showing():
		return
	get_viewport().set_input_as_handled()
	_pause.open()

## The window losing focus — Alt-Tabbing or clicking away from it, a browser tab going to the
## background — or a phone sending the app away opens the same screen `_pause.open()` above does,
## through the same call: one pause rather than a second kind of it. `ReturnWindow` is the caller:
## its `left_the_game`, on `NOTIFICATION_APPLICATION_FOCUS_OUT` and `NOTIFICATION_APPLICATION_PAUSED`,
## is connected here in `_add_the_return_window()`.
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
## `_no_focus_pause` (`--no-focus-pause`, which `--screenshot` implies) is the override, so a rig's
## window, which usually opens with no focus to lose in the first place, is never handed a picture
## of this screen instead of the day it was sent to look at.
func _pause_on_focus_lost() -> void:
	if _no_focus_pause:
		return
	# Defensive rather than load-bearing — see the same guard in `_unhandled_input()`'s own Esc
	# handler for why a real boot never leaves this null.
	if not _pause:
		return
	# `_summary.is_showing()` already excludes every screen the escape raises (a section's brief,
	# a lost section's outcome screen and the epilogue) on exactly the same terms it excludes a
	# day's own summary and ending — nothing escape-specific to add here, unlike Esc.
	if _pause.is_open() or _title.is_open() or (_summary and _summary.is_showing()):
		return
	_pause.open()

## A reload (`_reload_the_scene()`) frees this node and its children, including any symbol still
## parented here. A save change may still be waiting for IndexedDB: the held restart's deletion,
## or day 14's own save at the hand-over to the escape. Handed to the tree's root, the symbol shows
## across the reload and settles on whatever the reload builds, the title or the escape, with its
## minimums running the whole time — see `SaveIndicator`'s own doc. Only a symbol that is up needs
## moving; an idle child is freed with this node. A symbol already at the root stays there, even
## when idle, and the next boot adopts it again.
func _carry_the_save_symbol_over() -> void:
	if _save_indicator:
		_save_indicator.outlive_the_scene()

## Takes the symbol the reloading `main` handed to the tree's root, or builds one as this node's own
## child. Above every screen this boot goes on to build — see `SaveIndicator`'s own doc
## for why it is its own layer rather than a node on the pause screen, the day summary or the HUD.
func _raise_save_indicator() -> void:
	_save_indicator = SaveIndicator.carried(get_tree())
	if _save_indicator:
		return
	_save_indicator = SaveIndicator.new()
	add_child(_save_indicator)

## Every write goes through here. **It tells the symbol nothing**: `GameSave.write()` announces the
## save on `EventBus` and the `SaveIndicator` listens, so the symbol shows for exactly the saves that
## were meant to be kept (see `GameSave.write()`'s own doc for the runs and moments that draw
## nothing), and the browser's later answer reaches it even when a scene reload has freed this node
## first — a callback bound here would be dropped and leave the symbol shown for good.
func _save_now(day_under_way: bool) -> void:
	GameSave.write(_run, day_under_way)

func _quit() -> void:
	if _session:
		_session.close()
	if _quit_override.is_valid():
		_quit_override.call()
		return
	get_tree().quit()
