extends Node2D
## Boot scene: generate the city, drop the player on the doorstep, then the HUD.
##
## **The composition root.** The run's configuration (`config`, a `RunConfig`) is resolved once at
## boot and handed from here: to the observers (`Telemetry`, `GameSave`, `VisitCounter`) as the
## config itself, and to the world, the day and the baby as the plain values each needs out of it
## — a day's length, whether the clock stands still, how the ground is scheduled.
##
## The right-hand overlay is a developer readout, not part of the game's UI. It runs whenever
## `_debug` (a debug build) or `_readout_requested` (the page's own `?debug=1`) holds — see
## `_readout_requested`'s own doc. `_debug_layers` and `_route_lines` are built under that same
## `_debug or _readout_requested` gate, so a release page's own `?debug=1&layers=1,3,5` can ask
## for a picture; every other piece of developer furniture (the snapshot key, every other dev
## flag) stays gated behind `_debug` alone, except the release-safe bundle `config.live_debug`
## opens.

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

## Whether the developer readout runs at all: a debug build. A member rather than a read of
## `config` inside `_process()`, so a test can set it and check the release shape, the way
## `hud._debug` does for the HUD's own gate.
var _debug := false

## `--start-escape`, kept in a member for the same reason `_debug` is: so a test can set it
## directly and check the release shape.
var _escape_scene_requested := false

## Whether this boot reached the escape as **a run's own ending** rather than through the flag —
## a won day 14 with every task complete handing over, or a game closed inside a section and opened
## again. Set in `_ready()` off `GameState.escape_section`, which is the run's own record of it.
##
## What it changes: the run is already there, so no `GameState.start_run()`; the save is live, so
## the symbol that announces a write is built; and getting out of the city settles the run
## (`GameState.finish_day()`) — the flag's run is a day-1 run that only jumped here, so its own way
## out settles nothing.
var _escape_from_a_run := false

## `--no-focus-pause`, kept in a member for the same reason `_debug` is: so a test can set it
## directly and check the release shape.
var _no_focus_pause := false

## How long every input is ignored after the game gets focus back (`NOTIFICATION_APPLICATION_
## FOCUS_IN` or `_RESUMED`). *(2026-10-04, inbox #534: "When returning to the game all inputs should
## be ignored for 500ms this is to prevent the game from immediately starting when returning to the
## page. The player should see the day brief or pause screen".)* The tap or click that brings the
## page back is also an event the game reads, and without this it resumes the pause screen or
## starts the day from its brief before the player has seen either.
const RETURN_INPUT_IGNORED_MSEC := 500
## The `Time.get_ticks_msec()` reading at which the window ends, or `0` for no window; `_process()`
## ends it (`_end_the_return_window()`) the first frame it has passed. Real OS time rather than
## accumulated `delta`, and `_process()` rather than a timer: this node is `PROCESS_MODE_ALWAYS`, so
## it runs behind the pause screen too, and a `SceneTreeTimer` can fire before its time (its first
## frame's delta includes the time before it was made), which left input off for good. Never armed
## for a rig (`_rig_locked_out`) or under `_no_focus_pause`, which must never be slowed by this.
var _input_ignored_until_msec := 0

## Whether `_lock_out_a_rig()` found `config.is_rig` true for this run — a member for the same
## reason `_no_focus_pause` is, so a test can set it directly.
var _rig_locked_out := false
## The `Time.get_ticks_msec()` reading a rig quits itself at, or `0` for "no deadline" — a person's
## own `tools/run.sh` session, or a test that never calls `_lock_out_a_rig()` at all. `0` is safe
## as the sentinel because `Time.get_ticks_msec()` only grows from the process's own start, so it
## can never legitimately equal the deadline of a rig that armed one.
##
## **Real OS time, not accumulated frame `delta`, and that is load-bearing.** The stall a covered,
## unfocused window can fall into (`--disable-vsync` in `tools/shot.sh`/`tools/run.sh` is the fix —
## see docs/DECISIONS.md, M195) collapses how *often* `_process()` runs without necessarily
## collapsing what each call reports as its own `delta`, so a deadline kept by summing `delta` can
## lag the wall clock by exactly the amount the stall itself hides. Reading `Time.get_ticks_msec()`
## fresh every `_process()` call instead means the very next call to actually happen — however late
## it is — reads the true time and quits right then, rather than trusting a running total that the
## same stall could already have thrown off.
var _rig_quit_deadline_msec := 0
## **Under Godot's movie writer (`config.recording`), the same deadline in game seconds
## instead**, or `0.0` for none. A recording runs frame-locked and saves every frame before drawing
## the next, so its wall clock runs several times slower than its game clock, and a wall-clock
## deadline would end a legitimate recording partway; `delta` is exact there by construction, the
## one case the doc above does not have to distrust it. What stops a recording that has stopped
## running at all is the recording script's own outside kill (`tools/lib_dev_flags.sh`,
## `rig_kill_after_movie_seconds`).
var _rig_quit_game_seconds := 0.0

## How often the readout's text is re-set, in seconds. Re-setting some thirty lines of text every
## frame adds draw calls and drawing work to every phone record taken under `?debug=1`, so the
## text is built a few times a second instead. Nothing the readout shows is lost by it: `FrameCost`
## hands its numbers over once a second, the frame record keeps every slow frame and the readout
## names the latest one at each refresh, and the spike view (`_frame_graph`) is fed every frame.
const READOUT_INTERVAL := 0.25
## Seconds until the readout's text is next rebuilt; 0 or less means the next frame rebuilds it.
var _readout_wait := 0.0

## Whether the readout was asked for by the page's own `?debug=1` (or the command line's
## `--debug`), kept in a member for the same reason `_debug` is. `_status.visible` and the text
## assembly in `_process()` read `_debug or _readout_requested`, and so do `_add_debug_layers()`
## and `_add_route_lines()` (M133, the readout on the live page; M193, the live page's ?debug=1
## reaches the debug flags). The snapshot key and the layer-toggle keys read `_debug` alone: a
## release page can ask `?layers=` for a picture already drawn a particular way, never toggle one
## by hand with no keyboard event the page itself sent.
var _readout_requested := false
## The validated `--skip` words, for the readout's own `skip` line; empty whenever
## `_readout_requested` is false.
var _skip_words: Array[String] = []
## The readout's first line, `BuildInfo.build_text()` — `git describe`'s form and the commit —
## read on the first frame that assembles the readout and kept, since a working tree pays two
## `git` spawns for the answer and a release page with neither flag never pays them at all.
var _build_text := ""

var _city: City
## The escape's building. In the escape it is built first and `_city` follows when she walks out of
## the service exit, so the two *are* both non-null for the whole of the city section — the
## building stays on its own map with nobody on it. On an ordinary run `_interior` is null and
## `_city` is the only world there is.
var _interior: InteriorScene
## The day being walked: one of the fourteen, or one of the escape's two sections — see `DaySpec`.
## Handed to `_day` as each one starts, and what everything here that differs between a day and a
## section reads, rather than a global "are we in the escape". An ordinary day until one starts.
var _spec := DaySpec.new()
## The events inside the building — mice, the pursuers, the fire, the steam and the off-screen
## explosions — hosted on the interior map, since `InteriorScene` has no `EventManager`.
var _interior_events: InteriorEvents
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
## The fields, shadows and bounding-box overlays — `null` unless `_debug or _readout_requested`
## holds, so "is a layer node in the tree" is a release-page test's own question rather than one
## this class has to remember to ask of either flag separately. See `_add_debug_layers()`.
var _debug_layers: DebugLayers
## The day's planned routes, drawn as purple polylines — `null` on the same "absent, not merely
## hidden" terms `_debug_layers` uses. See `_add_route_lines()`.
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
## unflagged debug run shows it — and `false` under `--player-view` unless `--debug` asks for it,
## since that frame is the one a player sees.
var _layer_readout_on := true
## Whether the frame-time graph (`_frame_graph`) is showing — its own debug layer, key `6` in
## `_debug_layer_key()`/`_toggle_debug_layer()`, independent of `_layer_readout_on`'s own `4`:
## *(2026-09-15, the player: "spike view should be independent of debug layer 4 it should be its
## own debug layer and turned off by default unless --spikes is set".)* Starts `false` — unlike
## `_layer_readout_on`, which starts `true` — and `_add_frame_graph()` sets it `true` at boot
## instead when `--spikes` was given or `--layers` names `6`, the same way `--layers`
## naming `5` starts `_route_lines` on. Toggling it off also empties `_frame_graph`'s own ring
## (`FrameGraph.clear()`), so a graph switched off and back on again starts from blank rather than
## picking up wherever the window it was not fed during happened to leave off.
var _layer_graph_on := false
## Every frame's time by system, under `--frame-record`/`?framerecord=1`, or `null`. The readout
## carries its line, the last slow frame's
## three largest costs, so a stutter caught on a phone shows as caught.
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

## The seam `_reload_the_scene()` calls instead of reloading, set only by a test — see there. An
## empty `Callable`, the default, reloads normally.
var _reload_override := Callable()

## Owns the `--follow` camera and the event id it tracks between frames — the one piece of
## `DevRig` (`src/dev/dev_rig.gd`) that has to survive across calls, so it is the one piece kept
## on an instance rather than called as a `static`. The `--spawn`/`--overview`/`--meters` lookups
## against the live city need no instance and are called on `DevRig` itself.
var _dev_rig := DevRig.new()
## The authored scene `--recipe` loaded, or `null`. Its seed, day, escape part and parent reach the
## run through `config` (`RunConfig.with_recipe()`); this is the playback and the manifest.
var _recipe: SceneRecipeRuntime
## `--route`'s own walker, `null` outside a debug build or with no `--route` given — see
## `src/dev/route_rig.gd`. Unlike `_dev_rig`, this owns a whole target queue that has to survive
## across a day's frames, so it is a child node rather than a bag of static lookups.
var _route_rig: RouteRig
## Dev spawn and meter overrides apply to the opening day only; every later day starts on
## the doorstep with a fresh baby, like the game intends.
var _first_day := true
var _run_over := false
var _ending_shown := false
## Whether the title screen is up, with the city running behind it and nobody in it.
var _in_the_title := false

## The same, asked: what the frame trace and the frame record are handed, so they stop sampling
## behind the title without reading this node's fields.
func in_the_title() -> bool:
	return _in_the_title
## `GameSave.try_resume()`'s own return: `{}` on a fresh run, or `{"day_under_way": bool}` once
## `GameState` already carries a resumed run's fields — set once in `_ready()` and read by
## `_on_title_start()`, which is the only place the title's own dismissal is not simply "start
## playing": with a save on disk, pressing start opens the day brief instead — or, when the load
## spent a hard run's last nerve, the ending. (A normal run's last nerve spent by the load opens the
## brief too, on its checkpoint's day.) Empty for every dev-flag or headless boot, since
## `GameSave.uses_save()` already refuses all of them — see that function's own doc — and for a
## boot that carries a run on from a checkpoint (`_carried_from_a_checkpoint`).
var _resume := {}

## Set by `_carry_the_run_into_the_next_boot()` just before it reloads the scene, and read and
## cleared by the boot that follows. A `static var` because a scene reload frees this node but never
## unloads its script — the same reason `TitleScreen._restarted_at_msec` is one.
static var _carry_the_run_over := false

## Whether this boot carries a normal run on from its checkpoint, rather than starting or resuming
## one: `GameState` already holds the run, back at the checkpoint's dawn, and this boot opens
## straight on that day, the way the continue that asked for it would have.
var _carried_from_a_checkpoint := false

## Whether the loss `_on_day_finished()` just showed spent a normal run's last nerve, so the
## summary's continue reloads into the checkpoint's day rather than starting it on this world.
var _went_back := false
## Whether a day brief is the screen currently up, in front of a day already built — a resumed
## run's, opened by `_on_title_start()`, or the brief an escape section opens on — so
## `_on_summary_continued()` knows a "continue" from `_summary` means *engage the day just built*
## rather than *start the next one*: the two are the same signal (`DaySummary.continued`) on two
## different screens this class draws with it, and this is the one member that tells them apart.
## Cleared the instant that continue is read.
var _resume_gate_open := false

## Whether opening the save spent a normal run's last nerve and sent it back to its checkpoint —
## set once in `_ready()`, before the charge, and read by `_show_the_resume_gate()` for the line the
## day brief carries. A hard run's last nerve is `_run_over` instead.
var _resume_went_back := false

## Read once — a run's own touch hardware does not change — the same pattern `TouchControls._touch`
## and `hud._touch` already follow, and what lets `_process()` ask `ScreenOrientation.wants_rotation`
## every frame without also repeating `TouchInput.available()`'s own `OS.get_cmdline_user_args()`
## call sixty times a second.
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
	_debug = config.debug_build
	_readout_requested = config.readout_requested
	_escape_scene_requested = config.start_escape
	_no_focus_pause = config.no_focus_pause
	_skip_words = config.skip_words
	_layer_readout_on = not config.player_view_requested or config.readout_requested

func _ready() -> void:
	if not config.recipe_path.is_empty():
		var result := SceneRecipeRuntime.load_recipe(config.recipe_path, config.active_args)
		if not result.errors.is_empty():
			_recipe_failed(result.errors)
			return
		configure(config.with_recipe(result.data))
		_recipe = SceneRecipeRuntime.new()
		_recipe.configure(result, config)
		add_child(_recipe)
	# Before anything the observers watch can happen: the run log's header, the save's gate and
	# what the page counts all read this boot's configuration rather than the command line.
	Telemetry.configure(config)
	GameSave.configure(config)
	VisitCounter.configure(config)
	# The run log's owner, listening on the bus from here on, and the trace everything this boot
	# builds writes its own account into.
	_session = RunSession.new()
	_session.name = "RunSession"
	add_child(_session)
	_session.setup(Telemetry, config, EventBus)
	GameState.use_trace(_session.trace)
	# Esc has to work even while the summary has the tree paused, so this node keeps running
	# through a pause. Everything under it that *is* the game is put back to pausable as it is
	# created — see `_pauses_with_the_game()`. A child left on the default INHERIT inherits
	# ALWAYS from here, and then the pause does nothing to it: the summary sets
	# `get_tree().paused` while the player walks, the crowd drives and the resistance deadline
	# runs out behind a screen saying the day is over.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# As early as this scene's own script can act — see `_lock_out_a_rig()`'s own doc for why
	# nothing earlier is reachable from GDScript at all.
	_lock_out_a_rig()
	WebDisplay.apply(config)
	_return_viewport = get_viewport()
	_end_the_return_window(true)
	_return_viewport.set_disable_input(false)
	_listen_for_a_web_return()
	# A recording's own real wall clock runs several times slower than its game clock (saving one
	# frame costs far longer than the 1/60s it represents) — see `_rig_quit_game_seconds`'s own doc.
	# Physics interpolation blends a rendered frame between two physics ticks by how far the
	# frame's own real presentation time sits between them, so under that mismatch the blend never
	# advances: every recorded frame reads as the same tick, and her camera, the crowd and the
	# clock all read as frozen even though the simulation underneath is running correctly (confirmed
	# against the run log while building this). Off only for a recording — real play keeps the
	# smoothing `--fixed-fps` never runs under.
	if config.recording:
		get_tree().physics_interpolation = false
	# This is the one thing `?debug=1` adds on top of the readout, on whichever day the boot opens.
	# Gates itself on `_readout_requested` rather than being gated at the call site, the same shape
	# `_add_debug_layers()` gates itself on `_debug`. See `_add_debug_mode_note()`'s own doc for why
	# nothing afterwards may remove it.
	_add_debug_mode_note()
	# Same reason and the same gate as the note above. See `_add_frame_graph()`'s own doc.
	_add_frame_graph()
	# Starts in the shape it should have on this build rather than trusting the scene file's own
	# default (`true`): every later flip of it is relative to whichever screen is up, and a boot
	# path that never reaches one of them should still open with the right answer.
	# `_layer_readout_on` defaults `true`, so this is `_debug or _readout_requested` alone on an
	# unflagged run — the fourth debug layer starts on, the same as it always has.
	_set_readout_visible((_debug or _readout_requested) and _layer_readout_on)
	# Read before `try_resume()` touches it, so `escape_resumed_from_disk` below can tell a save
	# that already carried a section on the autoload (a handover reload) from one that only got
	# there because the line just after this read it off the file.
	var escape_section_before_resume := GameState.escape_section
	if _escape_scene_requested:
		_start_the_flags_run()
	else:
		_settle_the_run()
	# **Whether a genuinely resumed escape is what this boot opens**: the game was closed inside a
	# section and opened again, as against the handover reload a won day 14 takes into the escape,
	# which reaches this boot with the same `GameState.escape_section != NONE`, the same non-empty
	# `_resume` and no way to ask either one which of the two just happened. Still `NONE` before
	# `try_resume()` and something else after means the value just arrived from the file it read,
	# since a handover already wrote it to the autoload — which a scene reload does not clear —
	# before this boot's own `_ready()` ever ran. A resumed escape opens on the title first, the
	# way a resumed day does; a handover opens straight on the building's brief.
	var escape_resumed_from_disk := _escape_from_a_run and _escape_section_came_from_the_file(
			escape_section_before_resume, GameState.escape_section)
	var first := _the_first_day()
	# After the run seed is settled and before anything is generated, so the log opens on the
	# seed it is a trace of. A run carried on from a checkpoint, or handed over to the escape, keeps
	# writing the log it already has — see `RunSession.open()`.
	_session.open(GameState.run_seed, _somebody_is_playing(),
			_carried_from_a_checkpoint or first.section != DaySpec.Section.NONE)
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
	# a nerve count or a resistance state that has not been charged yet. `_run_over` mirrors
	# `_on_day_finished()`'s own variable, so the tail of this function shows the same ending screen
	# a hard run that ends there does; `_on_title_start()` is what actually shows either screen,
	# once the title itself has been dismissed. An escape section is never saved as under way
	# (`DaySpec.saved_as_under_way`), so a resumed escape is never charged here.
	#
	# **The symbol exists before this charge**, because the charge can end the run and the run's
	# end deletes the save, a change the symbol shows (`GameSave.clear()` announces it on
	# `EventBus`, which only an indicator already built hears). The flag's escape touches the save
	# not at all, so it gets none.
	if first.section == DaySpec.Section.NONE or _escape_from_a_run:
		_raise_save_indicator()
	if _resume.get("day_under_way", false):
		_resume_went_back = GameState.a_loss_goes_back_to_the_checkpoint()
		_run_over = not GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
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
		_baby.set_world(_city)

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
		_resistance.setup(_city, _city.map, _city.navigator)
		# The director's two questions about her view — no camera of its own, so it asks the day's
		# one view (`VisibleView`) rather than growing a second one: "has she seen this" for a
		# mark's notice, and "is it anywhere on screen", covered corners included, for whatever it
		# places or removes.
		_resistance.set_sight(_city.events.sees, _city.events.on_screen)

	_day = DayController.new()
	_day.name = "Day"
	_day.invincible = config.invincible
	add_child(_day)
	_pauses_with_the_game(_day)
	_day.setup(_city.map if _city else null, _player)
	_day.day_finished.connect(_on_day_finished)
	_session.watch_the_clock(_day)

	if walks_a_day:
		_session.watch_day(_city, _player, _baby, _day, _resistance, _edge)

	if walks_a_day and config.frame_trace_requested:
		var trace := FrameTrace.new()
		trace.name = "FrameTrace"
		add_child(trace)
		trace.setup(in_the_title, func() -> bool: return _layer_readout_on,
				func() -> bool: return _layer_graph_on, _city, _player, _day,
				Array(config.active_args))

	if walks_a_day and config.frame_record_requested:
		_frame_recorder = FrameRecorder.new()
		add_child(_frame_recorder)
		_frame_recorder.setup(in_the_title, _city, _player, _day)

	# Built before `_start_day()`, which calls `_route_rig.start_day()` once the day it is meant
	# to walk actually exists — see `src/dev/route_rig.gd`.
	if walks_a_day and not config.route_targets.is_empty():
		_route_rig = RouteRig.new()
		_route_rig.name = "RouteRig"
		add_child(_route_rig)
		_pauses_with_the_game(_route_rig)
		_route_rig.setup(_city, _player, _baby, _resistance, _day, config.route_targets)

	if walks_a_day:
		_start_day()
		if _recipe and _recipe.manifest.get("setup_failed", false):
			_retire_the_boot_camera()
			return
		_write_dawn_for_a_resumed_run()
	else:
		# `VisitCounter`'s own "the escape: begun" — the fresh handover from a won day 14 only,
		# never a resume of one already under way, which is not the sequence beginning.
		if _escape_from_a_run and not escape_resumed_from_disk:
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
	if _recipe and walks_a_day:
		_recipe.begin()
	elif _recipe:
		# An escape recipe plays from its first frame, with no brief in front of it.
		var problems := _recipe.install(_city, _player, _baby)
		if not problems.is_empty():
			_recipe_failed(problems)
			return
		_prepare_city_scenery()
		_apply_recipe_teaching()
		get_tree().paused = false
		_day.start(_spec.length)
		_hud.visible = true
		_recipe.begin()

	_add_the_screenshot_rig()

	# Apart from the boot-order block above and below: `StillWatch` only reads `_city`, `_player`
	# and `_day`, which already exist by here, and does not affect what day starts or how.
	if walks_a_day and config.quit_when_still_requested:
		var still_watch := StillWatch.new()
		still_watch.name = "StillWatch"
		add_child(still_watch)
		still_watch.setup(_city, _player, _day, config.quit_when_still_seconds, config.recording)

	# The escape's first screen — see `_open_the_first_screen_of_the_escape()`. A recipe has
	# already started playing above.
	if not walks_a_day:
		if _recipe:
			return
		_open_the_first_screen_of_the_escape(escape_resumed_from_disk)
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
	if _carried_from_a_checkpoint:
		_engage_the_day()
		return
	if _show_an_ending_for_a_rig():
		return
	if config.skips_the_title():
		return
	_open_the_title()

## **The escape opens on its section's brief**, the screen a day's continue would otherwise lead to
## — **unless it is a genuinely resumed escape** (`resumed_from_disk`, which `_ready()` reads off
## `_escape_section_came_from_the_file()`), which opens on the title first, exactly as a resumed day
## does, and the title's start then shows the brief (`_show_the_resume_gate()`). Either screen
## pauses the tree, so the section's clock, started by `_start_section()`, stands still behind it.
## Its own function so a test booting the real scene can drive both answers.
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
	_carried_from_a_checkpoint = _carry_the_run_over
	_carry_the_run_over = false
	if _carried_from_a_checkpoint:
		GameSave.load_in_memory()
	else:
		_resume = GameSave.try_resume()
	# **`GameState.escape_section` is asked before a fresh run is started, not after.** It is set
	# two ways and both of them must survive this line: the save above restores it for a game closed
	# inside a section, and a handover from day 14 leaves it set on the autoload across the scene
	# reload that reaches this boot — a reload under a dev flag or in a headless rig, where
	# `GameSave.uses_save()` refuses every read, would otherwise start a brand new run over the one
	# that just earned its ending.
	if _resume.is_empty() and GameState.escape_section == DaySpec.Section.NONE \
			and not _carried_from_a_checkpoint:
		GameState.start_run(config.seed_override)
		_apply_the_parent_flag()
		GameState.day = config.day_override
		_apply_the_mode_flags()
	# `VisitCounter`'s own "a run begun fresh, or resumed from the save" — fired once here for
	# every path through this function, ordinary or handed over to the escape, since GameState.day
	# is already settled for both by this line. `resumed` says only whether `GameSave.try_resume()`
	# found a file; it cannot also tell a file a real previous visit left from one a
	# `reload_current_scene()` earlier in this same page's life just wrote — a won day 14 handing
	# over to the escape is exactly that case. `VisitCounter` is where that distinction is made,
	# since only it can know whether *this page* has already reported a run beginning once before.
	#
	# Not for a run carried on from a checkpoint, which is the same run going on, not one beginning.
	if not _carried_from_a_checkpoint:
		EventBus.run_begun.emit(GameState.day, not _resume.is_empty())
	# The run's ending, played rather than announced: a won day 14 with every task complete hands
	# over to the escape, and a game closed inside a section opens on it again.
	_escape_from_a_run = GameState.escape_section != DaySpec.Section.NONE

## `--start-escape`: the escape with no run behind it, so a rig or a person can walk it on demand. A
## fresh run of its own, on day 1 — `--day` does not move it; a recipe's own day does — and no
## `run_begun`, since nothing about it is a run the page should count.
func _start_the_flags_run() -> void:
	GameState.start_run(config.seed_override)
	_apply_the_parent_flag()
	if config.has_recipe:
		GameState.day = config.day_override
	_apply_the_mode_flags()

## The day this boot opens on: the run's own day, or one of the escape's two sections. **Which
## section is the run's own record where there is one** (`GameState.escape_section`, which a save
## closed inside the city carries), and the flag's word where there is none — `city` boots the
## city section on its own, with no building built at all.
func _the_first_day() -> DaySpec:
	if _escape_scene_requested or _escape_from_a_run:
		var start_at_the_city := _escape_start_part() == "city" \
				or (_escape_from_a_run and GameState.escape_section == DaySpec.Section.CITY)
		return escape_section_spec(DaySpec.Section.CITY if start_at_the_city
				else DaySpec.Section.BUILDING, config.escape_section_length())
	return DaySpec.for_day(GameState.day, config.day_length_for(GameState.day))

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
	add_child(_hud)
	if _player:
		_add_danger_edge()
		_add_excitement_halo()
		_add_debug_layers()
		_add_route_lines()
	_add_touch_controls()
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

## Whether `escape_section` arrived from a file `GameSave.try_resume()` just read, rather than
## surviving on the autoload from a handover reload earlier in this same process — see `_ready()`'s
## `escape_resumed_from_disk` for why the two need telling apart at all. Pulled out, the
## two live reads of `GameState.escape_section` taken out of it, the same split `_graph_starts_on()`
## makes for its own two flags: a test can drive every combination directly rather than only
## through a real save on disk.
static func _escape_section_came_from_the_file(before_resume: int, after_resume: int) -> bool:
	return before_resume == DaySpec.Section.NONE and after_resume != DaySpec.Section.NONE

## `--screenshot` and the timed runs `AutoScreenshot` drives, on any day; nothing without one. A
## scripted recipe's capture is timed off its own physics clock and prepared by it.
func _add_the_screenshot_rig() -> void:
	var screenshot := AutoScreenshot.from_config(config)
	if not screenshot:
		return
	if _recipe and _recipe.scripted:
		screenshot.simulation_clock = _recipe.elapsed
		screenshot.before_capture = _recipe.prepare_capture
	add_child(screenshot)

## `--parent mother|father` over the roll `GameState.start_run()` just made from the seed, so a
## trailer shot shows the parent its shot list names. Called straight after each of this file's
## two `start_run()` calls, before anything reads the choice — `_hold_every_page_a_day_draws()`
## holds that parent's atlas page and `_make_player()` binds the rig to it.
func _apply_the_parent_flag() -> void:
	var parent := config.parent_override
	if parent != "":
		GameState.player_is_male = parent == "father"

## `--hard` and `--nerves N` over the fresh run `GameState.start_run()` just made, so a rig can reach
## what running out of nerves does in either mode without spending four nerves first. `--hard` is
## also what the title's checkbox opens on (`TitleScreen.open()` reads `GameState.hard_mode`), so
## `--title --hard` photographs it checked. Called straight after each of this file's two
## `start_run()` calls, beside `_apply_the_parent_flag()`.
func _apply_the_mode_flags() -> void:
	if config.hard_mode_requested:
		GameState.choose_mode(true)
	var nerves := config.nerves_override
	if nerves > 0:
		GameState.nerves = nerves

## What the HUD draws of the developer's furniture: its debug header on a debug build, the release
## shape under `--player-view`, and the invincible mark under `--invincible`. Set before
## `add_child()` runs the HUD's own `_ready()`.
func _configure_the_hud() -> void:
	_hud.configure(config.debug_build and not config.player_view_requested, config.invincible)

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
	player.is_male = GameState.player_is_male
	(player.get_node("Baby") as Baby).excitement_frozen = config.invincible
	return player

## A city node in the tree, handed the dev choices that decide how it draws and schedules itself
## before `build()` reads them — a day's city and the escape's are both built through here.
func _new_city() -> City:
	var city: City = CITY.instantiate()
	city.trace = _the_trace()
	city.ground_mode = config.ground_mode as SceneryGround.Mode
	city.scenery_frame_locked = config.recipe_scripted
	city.skip_shadows = config.skip_shadows
	city.skip_event_drawing = config.skip_events
	city.skip_crowd_drawing = config.skip_crowd
	city.skip_crowd_motion = config.skip_motion
	city.blackout_forced = config.blackout_requested
	city.all_cyclists_pelicans = config.pelican
	city.forced_row = config.forced_row
	city.forced_interval = config.forced_interval
	add_child(city)
	_pauses_with_the_game(city)
	return city

## The map the city is built on: a recipe's own, or the one the run's seed generates.
func _city_map() -> CityMap:
	return _recipe.built.map if _recipe else CityGenerator.generate(GameState.run_seed)

## The world a section of the escape is walked in, built the first time that section begins: the
## building for the first, and the city for the second — out of the building's service exit, or
## straight onto the street on a boot that opens there. A retried section walks the world it
## already has.
##
## **Walking out of the building, its wall blockers go; its pictures and its fade stay.** The
## building and the city share one physics space and both are laid out from the world origin, so
## its blockers would stand across the city's top rows as a wall nobody draws (inbox #777 in
## minty-lemur) — `InteriorScene.take_the_walls_out()`. The fade is not reversed here:
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
	# The first world this boot stands is where the run log's observer starts watching the escape —
	# her, the baby, the day's clock and the badges, which exist from here on.
	if not _escape_watched and _session:
		_escape_watched = true
		_session.watch_escape(_player, _baby, _day, _edge)

## Whether the run log's session has been told what to watch the escape with — once a boot.
var _escape_watched := false

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
	_player.slope_dir_at = _interior.slope_dir_at
	_interior.add_entity(_player)
	_player.set_camera_limits(_interior.camera_bounds())
	_baby = _player.get_node("Baby")
	_baby.set_world(_interior)

	_interior_events = InteriorEvents.new()
	_interior_events.name = "InteriorEvents"
	_interior_events.skip_drawing = config.skip_events
	_interior_events.trace = _the_trace()
	add_child(_interior_events)
	_pauses_with_the_game(_interior_events)
	_interior_events.setup(_interior, GameState.day_rng(GameState.day, "finale-interior"))
	# The building shows what the city shows: the same badge, halo and debug view, reading
	# `InteriorEvents` where a day reads `EventManager` — see `_event_source()`. The city's own
	# build calls the same three again when she walks out, which points them at the street.
	_add_danger_edge()
	_add_excitement_halo()
	_add_debug_layers()

## Section two's world: the city she knows with nobody in it, and the finale's own plan on it.
##
## The city is generated from the run seed exactly as an ordinary run's is, so the streets, the
## parks and the two exits are the ones she has walked for fourteen days. What is different is
## everything laid *on* it: `City.start_finale()` dresses the blocks without growing a day's route
## tree, closures or region wall; the crowd is cleared and never started, since *"no regular cars
## or regular people on the street"*; and `EventManager.start_finale()` takes this scene's own plan
## instead of the catalogue's day. It is dark from its first frame and stays at night, as the
## section's `DaySpec` says.
func _build_the_finale_city() -> void:
	_city = _new_city()
	_city.dark_from_the_start = _spec.dark_from_the_start
	_city.build(_city_map())
	GameState.city_state.begin_day(_city.map.block_plans, GameState.day)
	_city.start_finale(GameState.city_state, GameState.day)
	_city.set_act(GameState.current_act())
	# Night, and fixed there: the escape happens after the last day and the clock is the tension
	# rather than the light, so the sky does not run itself down over the sequence.
	if not _spec.daylight_runs_down:
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
	# Told, not discovered: the same baby now asks the street, not the building behind her.
	_baby.set_world(_city)
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
func _plan_the_finale_city() -> void:
	if _recipe:
		return
	var elapsed := Time.get_ticks_msec()
	var plan := FinalePlanner.plan(_city.map, GameState.day_rng(GameState.day, "finale"))
	_city.events.start_finale(plan.placements, _finale_start_position(), _spec.number)
	# The streets the chains run through carry the route's kerb tint, as a day's corridor does.
	_city.tint_the_escape_route(plan.open_streets)
	# Printed as well as logged, for the same reason `_start_day()` prints the day it just built:
	# the shape of the walk is the one thing worth knowing before anything else in the log means
	# anything, and a run with telemetry off still has a console.
	print("[Main] finale planned in %d ms (seed %d): %s"
			% [Time.get_ticks_msec() - elapsed, _city.map.seed_used, plan.summary()])
	_the_trace().note("plan", "finale: %s" % plan.summary())

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
	GameState.escape_section = spec.section
	_hud.visible = false
	# Announced before its world is built or anything is placed in it, as a day is, so whatever
	# the building or the city does as it is built is counted as this section's.
	EventBus.day_started.emit(spec.number)
	_build_the_world_for(spec)
	if spec.goal == DaySpec.Goal.CITY_EDGE:
		spec.exits = _the_city_exits()
	_day.setup(null, _player)
	if spec.world == DaySpec.World.BUILDING:
		var start_at := _interior.start_world_position()
		if not restarted:
			start_at = _interior.part_world_position(_escape_start_part())
		_player.reset_at(start_at, Vector2.UP)
		if _interior_events:
			_interior_events.restart()
	else:
		# The building is behind her and nobody is in it, so its own events stop rather than
		# playing on to an empty map — the vents, the window flashes and the masked man who comes
		# up the shaft every few seconds would otherwise run for the rest of the sequence, unseen
		# and in the log. `InteriorEvents.restart()` is what starts them again, and section one is
		# never entered without it.
		if _interior_events:
			_interior_events.stand_down()
		# A restart of section two replans it: see `_plan_the_finale_city()`.
		if restarted:
			_plan_the_finale_city()
		_player.reset_at(_finale_start_position(), Vector2.DOWN)
		_prepare_city_scenery()
		_city.events.stream_around(_player.global_position)
	_baby.reset()
	_baby.force_sleep()
	_day.start(spec.length)
	if spec.world == DaySpec.World.BUILDING:
		EventBus.escape_section_started.emit(spec.section, restarted, _interior, _interior_events)
	else:
		EventBus.escape_section_started.emit(spec.section, restarted, _city, _city.events)
	EventBus.day_planned.emit(spec.number)
	if _interior:
		_interior.clear_fade()

## The screen a section opens on, over the world she is already standing in — *"each the apartment
## and escape city are treated as their own 'days' with brief and restart checkpoint"*: the day
## brief (`DaySummary.show_day_brief()`), with the section's own words where "Day N of 14" stands.
## Its continue engages the section the way a resumed day's brief does (`_on_summary_continued()`).
##
## **It is also where the save is written.** A section's brief is the escape's only checkpoint, so
## it is the moment a closed game has to come back to, and the run's own record of which section
## that is (`GameState.escape_section`) was set as the section began. `false` because a section is
## never saved as under way (`DaySpec.saved_as_under_way`): a resumed escape is not charged a nerve
## for it.
func _show_the_section_brief() -> void:
	_resume_gate_open = true
	_save_now(false)
	_summary.show_day_brief(GameState.day, GameState.nerves, "", _spec.title)

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
	_run_over = true
	_ending_shown = true
	_summary.show_ending(wanted[wanted_arg] as GameEnums.Ending, GameState.day)
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
	_in_the_title = true
	# Guarded the same shape `_on_title_start()`'s own final line already is, and for the same
	# reason: `tests/test_main.gd` drives this function on a script-only `main` with no tree behind
	# it, to reach the graph-hiding line below without the rest of this function's live-tree
	# dependencies. Never false in the running game, where this only ever fires on a real `main`
	# already in the tree.
	if is_inside_tree():
		get_tree().paused = true
	_apply_orientation()
	if _spec.section == DaySpec.Section.NONE:
		_city.process_mode = Node.PROCESS_MODE_ALWAYS
		_player.process_mode = Node.PROCESS_MODE_PAUSABLE
		_player.stand_aside()
	_hud.visible = false
	_edge_layer.visible = false
	_set_readout_visible(false)
	if _frame_graph:
		_frame_graph.visible = false
	_title.open(_ending_shown, _resume.is_empty(), not _resume.is_empty())

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
## for the script-only instance `tests/test_main.gd` drives straight through this function with no
## tree behind it at all — `get_tree()` itself logs an engine-level error when called off-tree,
## which `is_inside_tree()` never does, so this is the check to make rather than a null check on
## `get_tree()`'s own return. Never false in the running game, where this only ever fires on a real
## `main` already in the tree.
##
## **With no resume, this is also the moment she starts playing** — `_engage_the_day()` runs
## immediately. **With one, it is not**: `_show_the_resume_gate()` opens instead, and it is *that*
## screen's own continue that reaches `_engage_the_day()`, through `_on_summary_continued()`'s own
## `_resume_gate_open` branch — see that function's own doc for why the same signal reaches two
## different places depending on which screen raised it.
func _on_title_start(mode: ControlsMode.Mode, by_key := false,
		side := ControlsMode.Side.LEFT) -> void:
	# Which control scheme was picked, or that a key began the run: the HUD rewords its walking
	# lesson by it and the page counts it.
	EventBus.controls_chosen.emit(mode == ControlsMode.Mode.JOYSTICK, by_key)
	_touch_controls.set_mode(mode, side)
	ControlsMode.remember(mode, side)
	_in_the_title = false
	# A new game's mode is the title's Hard Mode checkbox, read as the title is dismissed — the
	# checkbox shows only for a new game (`_open_the_title()`), and a resumed run keeps the mode
	# its save carries.
	if _resume.is_empty():
		GameState.choose_mode(_title.hard_mode_checked())
		EventBus.run_mode_chosen.emit(GameState.hard_mode, GameState.day)
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
	if _run_over:
		# The last nerve the load itself spent, in hard mode — same ending, same screen, as a hard
		# run that reaches zero nerves any other way. `GameState.ending` is already set
		# (`GameState.finish_day()` set it in `_ready()`), so nothing downstream can write a save
		# naming this run again.
		_ending_shown = true
		_summary.show_ending(GameState.ending, GameState.day)
		return
	_resume_gate_open = true
	# The second of the two moments a page may load in, open for as long as the brief is up and
	# shut again by the continue that dismisses it (`_on_summary_continued()`). **Nothing loads
	# here today** — the boot above already holds every group a day draws — and it is opened
	# anyway because this is the screen a page the boot could not have known about belongs behind:
	# a group whose membership depends on the day would be acquired between these two lines.
	AtlasLibrary.open_loading_window(AtlasLibrary.MOMENT_DAY_BRIEF)
	_summary.show_day_brief(GameState.day, GameState.nerves, _resume_gate_note(), _spec.title)

## The day brief's one line about what opening the save cost: nothing, a nerve and the same dawn,
## or — a normal run's last nerve — the checkpoint `GameState.finish_day()` already went back to,
## whose day `GameState.day` now holds.
func _resume_gate_note() -> String:
	if not _resume.get("day_under_way", false):
		return ""
	if _resume_went_back:
		return Texts.RESUMED_LAST_NERVE % GameState.day
	return Texts.RESUMED_DAY_LOST

## Hands the day already built and paused behind a gate — the title, on a fresh or a resumed run
## the load left with nothing charged, or the day brief the load put on top of it — over to the
## player: the moment she is actually playing it, which is also the moment the save has to say so,
## immediately rather than leaving the next write to whichever of the day's own two other moments
## (a resumed run's own dawn write in `_ready()`, or the day's own end) happens to come next.
## Called from `_on_title_start()` directly (no resume) and from `_on_summary_continued()`'s own
## `_resume_gate_open` branch (the day brief's continue, a section's brief included) — the two, and
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
	_player.step_back_in()
	if _city:
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
	if _spec.title != "":
		_hud.say_once(_spec.title)
	if _spec.saved_as_under_way:
		_save_now(true)

## The screen-edge half of the danger vocabulary, in its own layer.
##
## Built here rather than inside the HUD scene because it has to ask the world where things are
## every frame, and the HUD's rule is that it listens to `EventBus` and holds no reference to
## the world. Bending that for one indicator would cost more than the node does.
##
## **One badge for every world.** It reads `_event_source()`, which is the building's
## `InteriorEvents` in the escape's first section and a `City`'s `EventManager` everywhere else, so
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
## `z_index = 1` puts it above `City`'s `Ground` (default 0) and below its `Entities` (2, the
## y-sorted layer the player, the crowd and every event live on) — under everything the cue is
## required to be under: the entities, the crowd and the player, none of which can ever read as
## lit from beneath. It ties `Buildings` (also 1) rather than sitting under it as well, which a
## glow can afford to: a wall the field happens to reach warms slightly, the way it would under
## any coloured light near it, and nothing the cue exists to protect is a wall.
## `_pauses_with_the_game()` is the same reasoning `_city` gets: while the tree is paused nothing
## it reads is moving either, so freezing alongside the world it draws needs no case of its own.
##
## Called once per world the same way `_add_danger_edge()` is: in the escape's building it reads
## `InteriorEvents` and no crowd, and walking out of the service door points it at the city.
func _add_excitement_halo() -> void:
	if _halo:
		_halo.setup(_event_source(), _crowd_now(), _player, _baby)
		return
	_halo = ExcitementHalo.new()
	_halo.name = "ExcitementHalo"
	_halo.z_index = 1
	_halo.setup(_event_source(), _crowd_now(), _player, _baby)
	add_child(_halo)
	_pauses_with_the_game(_halo)

## What the badge, the halo, the debug view and the readout read the world's events from: the
## building's `InteriorEvents` while the escape's first section is the only world there is, and a
## `City`'s own `EventManager` once there is a city — a day's, or the escape's second section,
## which the building never comes back after. Both answer `instances()`, which is all any of the
## readers asks.
func _event_source() -> Node:
	if _city:
		return _city.events
	return _interior_events

## The crowd, or null in the escape's building, which has nobody in it but its events.
func _crowd_now() -> Crowd:
	return _city.crowd if _city else null

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
	AtlasLibrary.stop_holding(Stroller.parent_atlas(not GameState.player_is_male))
	AtlasLibrary.hold_for_the_process(Stroller.parent_atlas(GameState.player_is_male))
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
	_end_the_return_window(true)
	_stop_listening_for_a_web_return()
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
## Left-aligned with `_status` (`offset_left`, 960px in the design box) and placed a fixed 646px
## below its own top (`offset_top`, 14px): the readout's block gains its 32nd line only under
## `--skip`, and 32 lines at this label's own font size (17px tall, 3px between lines — measured
## off a headless `Label`, since neither number is exposed as a theme constant) reach about 637px
## from the block's own top, so a fixed offset clears both shapes with a few pixels to spare
## instead of re-measuring `_status`'s rendered height every frame for a difference that never
## exceeds one line. **Below the block, not above it**, because the joystick focus ring `docs/
## DECISIONS.md` (M139, "the phone reading") already finds under the readout's own lines — a 48px
## ring centred at y=480 in the same design box reaches no further down than y=528 — comfortably
## above this box's own top at y=660, so the graph clears the ring by placement rather than by
## being moved out of its way.
func _add_frame_graph() -> void:
	if not (_debug or _readout_requested):
		return
	_frame_graph = FrameGraph.new()
	_frame_graph.name = "FrameGraph"
	_frame_graph.text_colour = _status.get_theme_color("font_color")
	_frame_graph.position = Vector2(_status.offset_left, 660.0)
	_layer_graph_on = _graph_starts_on(config.spikes_requested, config.layers_override)
	_frame_graph.visible = _layer_graph_on
	_status_layer.add_child(_frame_graph)

## Whether `_layer_graph_on` starts `true`, pure in the two flags so a test can drive the policy.
## `--spikes` already means somebody is chasing a stutter, and `--layers` naming `6` is the same
## "reproducible without a keypress" request `5` answers for `_route_lines`.
static func _graph_starts_on(spikes_requested: bool, layers: Array[int]) -> bool:
	return spikes_requested or 6 in layers

## The fields, shadows and bounding-box overlays — see `DebugLayers`. **Absent from the tree
## unless `_debug or _readout_requested` holds**, not merely built and left invisible:
## `_debug_layers` stays `null`, so nothing here is queried, nothing is drawn and an ordinary
## release page pays for none of it.
##
## `z_index = 3` puts it above `Entities` (2, the y-sorted layer everything on the ground lives on)
## — above everything else in the world, unlike the halo's own `z_index = 1`, because a bounding
## box drawn under the thing it outlines would be the one cue in the game nobody could read.
## Every layer starts off, unless `-- --layers 1,3` (or the page's own `?layers=1,3`, which also
## reaches a release page behind `?debug=1` — docs/DECISIONS.md, M193, "the live page's ?debug=1
## reaches the debug flags") says otherwise — see `_toggle_debug_layer()` for the number key that
## turns one on by hand, a debug build only.
##
## Called once per world, the way `_add_danger_edge()` is, so the escape's building gets the
## same three layers and walking out of the service door points them at the city with whatever
## `1`–`3` had switched on still on.
func _add_debug_layers() -> void:
	if not (_debug or _readout_requested):
		return
	if _debug_layers:
		_debug_layers.setup(_event_source(), _crowd_now(), _world_now(), _player)
		return
	_debug_layers = DebugLayers.new()
	_debug_layers.name = "DebugLayers"
	_debug_layers.z_index = 3
	_debug_layers.setup(_event_source(), _crowd_now(), _world_now(), _player)
	_debug_layers.apply_initial_state(config.layers_override)
	add_child(_debug_layers)
	_pauses_with_the_game(_debug_layers)
	print("[DebugLayers] keys:  1 fields   2 shadows   3 bounding boxes   4 readout   5 routes")

## The day's planned routes — see `RouteLines`. **Absent from the tree unless `_debug or
## _readout_requested` holds**, the same "null, not merely invisible" shape `_add_debug_layers()`
## uses. A sibling of `_debug_layers` rather than a fourth case on it: that class queries the live
## geometry every frame it is asked to draw, and this one draws a fixed plan that only changes once
## a day, at `_start_day()`'s own call to `refresh()` — so it earns no `_process()` and no place
## inside a class built around one.
##
## Parented under `Main` directly rather than under `_debug_layers` — the two are independent
## layers with independent lifetimes, and nesting one inside the other would make "toggle routes
## off" and "toggle every geometry layer off" the same tree edit for no reason.
func _add_route_lines() -> void:
	if not (_debug or _readout_requested):
		return
	_route_lines = RouteLines.new()
	_route_lines.name = "RouteLines"
	_route_lines.z_index = 3
	_route_lines.setup(_city.map)
	_route_lines.apply_initial_state(config.layers_override)
	add_child(_route_lines)
	_pauses_with_the_game(_route_lines)

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
## this process: the day-14 hand-over to the escape (`_escape_from_a_run`) and a normal run carried
## on from its checkpoint (`_carried_from_a_checkpoint`). Each keeps the mode and steering side the
## player chose on the run's title (`ControlsMode.remember()`) rather than falling back to the rig's
## default — the side is "permanently for the sitting" (2026-10-10). A game closed inside a section
## and opened again has no answer in memory, and its title asks.
func _add_touch_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TouchControls"
	_touch_layer = layer
	add_child(layer)
	_touch_controls = TOUCH_CONTROLS.instantiate()
	_touch_layer.add_child(_touch_controls)
	_touch_controls.rotated = _rotated
	if (_escape_from_a_run or _carried_from_a_checkpoint) and ControlsMode.has_remembered():
		_touch_controls.set_mode(ControlsMode.remembered_mode(), ControlsMode.remembered_side())
	else:
		_touch_controls.set_mode(ControlsMode.from_word(config.controls_word),
				ControlsMode.side_from_word(config.controls_word))

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
## `tests/test_main.gd` drives straight through `_open_the_title()` — see that test's own
## `_test_opening_the_title_reasserts_the_orientation_it_finds_stale`. There is exactly one
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

## Builds and starts the day; writes nothing itself. Each caller decides what, if anything, the
## save should say about the day this just built — see `_ready()`'s own call (nothing for a fresh
## run, `false` for a resumed one) and `_on_summary_continued()`'s (`true`, since nothing gates an
## ordinary continue into the next day at all).
func _start_day() -> void:
	if _recipe:
		_start_recipe_day()
		return
	# Timed for the same reason `_ready()` times `CityGenerator.generate()`: playtest 27 named
	# this path — planning the day's closures, placing every event, streaming the world around
	# the doorstep — as one of the candidates for the wait after a summary's continue button,
	# and nothing about it had ever been measured.
	var elapsed := Time.get_ticks_msec()
	# Decided once, here, and handed to everything that runs on the day's clock as a number.
	var day_length := config.day_length_for(GameState.day)
	_use_the_day(DaySpec.for_day(GameState.day, day_length))
	# Before the announcement and before anything is placed: this is where the run photographs
	# what the resistance had done, and a lost day gives exactly that back — so the photograph has
	# to be taken while it is still true of the attempt about to be played. See
	# `GameState.begin_day()`.
	GameState.begin_day()
	# The day is announced first, so listeners clear yesterday's state before anything is
	# placed in today — announcing it afterwards wiped the contact the director had just
	# reported, and the HUD showed nothing.
	EventBus.day_started.emit(GameState.day)


	# Events and the contact are placed before the player, so --spawn has something to find
	# and so nothing spawns on top of her.
	# The city becomes today's city before anything is placed in it: the scheduler has to
	# see the parks that are still parks, not yesterday's.
	GameState.city_state.begin_day(_city.map.block_plans, GameState.day)
	# The calm areas she has used this act, handed to the repaint `_city.start_day()` opens with, so
	# the ones that can be shut are shut before the day's route tree is grown around them. See
	# `CityMap.set_spent_calm()`.
	_city.map.set_spent_calm(GameState.settled_this_act())
	# What `GameState` already remembers about the one park barriers ever stand around this run,
	# handed over the same way, so a fence chosen on an earlier day of this act stands again today
	# rather than being re-decided. See `CityMap.set_fenced_park_state()`.
	_city.map.set_fenced_park_state(GameState.fenced_park, GameState.fenced_park_act,
			GameState.current_act())
	_city.start_day(GameState.city_state, GameState.day,
			GameState.day_rng(GameState.day, "closures"))
	# Remember the first choice for the run. Today's physical fence disappears after its act,
	# but that must not erase the history and allow tomorrow to choose another one.
	GameState.remember_fenced_park(_city.map.fenced_park, _city.map.fenced_park_act)
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
	# Before `start_at` is read, not merely before the player is placed: `--spawn contact` reads
	# `resistance.contact_position()` directly, and on the first day — the only day `--spawn`
	# decides where she starts — the mark has to already be on offer when this line runs, not
	# merely by the time the day is shown to her.
	_resistance.start_day(GameState.day, GameState.day_rng(GameState.day, "resistance"), day_length)
	var start_at := DevRig.for_spawn_target(config.spawn_target, _city, _resistance) \
			if _first_day else doorstep
	_city.events.stream_around(start_at)
	_city.crowd.start_day(GameState.day, GameState.day_rng(GameState.day, "crowd"), start_at)
	# The smallest wiring for the checkpoint gates: `City.region_plan()` is already valid by here
	# (`_city.start_day()` built it above), so the crowd just needs to be told where today's gates
	# are — empty before `Tuning.REGION_WALL_FIRST_DAY`, which is a harmless no-op day for `Crowd`.
	_city.crowd.set_gates(_city.region_plan().gates)
	_city.set_act(GameState.current_act())
	_player.reset_at(start_at)
	_prepare_city_scenery()
	_baby.reset()
	_day.start(day_length)

	# After the day is running, not before: the override can put the baby straight to
	# sleep, and start() would have reset the phase that announcement just set.
	if _first_day:
		DevRig.apply_meter_override(_baby, config.meters_override)
	_first_day = false

	print("[Main] day %d started in %d ms (act %d): %d events (%d live, %d ahead), %d crowd, %.0fs "
			% [GameState.day, Time.get_ticks_msec() - elapsed, GameState.current_act(),
			_city.events.planned_count(), _city.events.active_count(), _city.events.owed_ahead(),
			_city.crowd.agent_count(), _day.time_total]
			+ "| calm: %s | closed: %s" % [_city.calm_summary(), _city.closure_summary()])

	# Last, because the day's shape is only true once everything has been placed: the run log
	# writes its plan lines, its dawn picture and her `start` line here.
	EventBus.day_planned.emit(GameState.day)
	if _route_rig:
		_route_rig.start_day()

## The day about to be walked, handed to the day's clock and to the HUD's. Either may be absent
## from a script-only `main` a test builds by hand.
func _use_the_day(spec: DaySpec) -> void:
	_spec = spec
	if _day:
		_day.spec = spec
	if _hud:
		_hud.set_clock_hundredths(spec.clock_hundredths)

## The ordinary game's components start from the authored setup before any actor is allowed to
## tick. The recipe selects every event; the random scheduler does not fill authored scenes.
func _start_recipe_day() -> void:
	_use_the_day(DaySpec.for_day(GameState.day, config.day_length_for(GameState.day)))
	GameState.begin_day()
	EventBus.day_started.emit(GameState.day)
	GameState.city_state.begin_day(_city.map.block_plans, GameState.day)
	_city.start_recipe_day(GameState.city_state, GameState.day,
			GameState.day_rng(GameState.day, "closures"))
	_city.set_act(GameState.current_act())
	_day.start(config.day_length_for(GameState.day))
	var errors := _recipe.install(_city, _player, _baby, _resistance)
	if not errors.is_empty():
		_recipe.manifest["setup_failed"] = true
		_recipe_failed(errors)
		return
	_prepare_city_scenery()
	_apply_recipe_teaching()
	_first_day = false

## Authored mid-game scenes may start after the ordinary control lessons have been learned.
## Danger warnings and the rest of the normal HUD remain active.
func _apply_recipe_teaching() -> void:
	if not _recipe.data.get("setup", {}).get("tutorial_complete", false):
		return
	_hud._teach_left = 0
	_hud._teach.show_line("")
	_hud._taught_pause = true
	_hud._taught_run = true

func _recipe_failed(errors: Array) -> void:
	for problem: Variant in errors:
		print("[SceneRecipe] " + str(problem))
	get_tree().quit(1)

## Whatever `_start_day()`'s own dawn should say about the day it just built, said right after
## that call returns — pulled out of `_ready()` on its own so a test can drive the decision
## directly without paying for the world `_start_day()` builds around it.
##
## **A resumed run whose save had a day under way writes `false` here**, before the title — and, on
## the way to the day brief, that screen too — is ever shown, so the nerve `_ready()` just charged
## through `GameState.finish_day()` is on disk, with no day under way, the instant either gate
## appears rather than only once she presses past one. *(cozy-pelican, 2026-10-02, on what opening
## a saved game writes: "either it saves with one less nerve and a cleared "during active game"
## flag. or you defer saving to the actual day start".)* This is what the kill-at-any-instant
## argument in docs/MECHANICS.md, "Saving and resuming", rests on: nothing between this write and
## `_engage_the_day()`'s own `true` ever depends on a notification catching anything. When the
## charge ended the run, `GameState._end_run()` has already deleted the save and `GameSave.write()`
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

## Lifecycle relocations prepare the destination before play/brief reveal, including dev spawns
## and the escape's camera handoff from the interior. Nothing to prepare for a script-only `main`
## a test drives with no tree behind it, which has no viewport to measure — never the case in the
## running game.
func _prepare_city_scenery() -> void:
	if not _city or not _city.scenery or not _player or not is_inside_tree():
		return
	var camera: Camera2D = _player.get_node("Camera2D")
	camera.force_update_scroll()
	var size := get_viewport_rect().size / camera.zoom
	var angle := camera.global_rotation
	var world_size := Vector2(absf(cos(angle)) * size.x + absf(sin(angle)) * size.y,
			absf(sin(angle)) * size.x + absf(cos(angle)) * size.y)
	_city.scenery.update(Rect2(camera.get_screen_center_position() - world_size * 0.5,
			world_size), true)

## What ended a hard-fail day, as `EventBus.day_ended` carries it: `car` for the one
## hard fail that is not a catalogue row (`EventBus.hard_fail_triggered("car_strike")`,
## `Crowd._strike()`), otherwise the id off whatever row actually struck her
## (`EventBus.hard_fail_triggered(instance.def.id)`, `EventManager._check_hard_fails()`) —
## hyphenated the same way every other cause name is, so a new hard-fail row (`roadblock`'s guard
## once it hunts, and everything already in the catalogue) is covered without a
## second list naming it here. Pure, and tested directly — `tests/test_day_lost_to.gd`.
##
## `struck_by` is `EventManager.what_struck_her()` — the name the logs give the instance whose reach
## ended the day — and names it in place of `reason` when there is one, so a day lost to the
## pelican is `pelican` rather than its row's `cyclist` *(inbox #527 in azure-tapir)*. `reason` stays the row's id
## for `DayController`'s own sentence, which is the cyclist's either way.
static func _hard_fail_cause_suffix(reason: String, struck_by := "") -> String:
	if reason == "car_strike":
		return "car"
	return (struck_by if struck_by != "" else reason).replace("_", "-")

## What ended a crying day, as `EventBus.day_ended` carries it: whichever group in
## `landed_by_group` (see
## `_crying_landed_by_group()` below) landed the most on her over the crying window — a catalogue id
## (hyphenated), `crowd` for walkers, `traffic` for cars, or `self` for her own running and standing
## in an alley.
##
## **Ties, and the window reading entirely empty, pick the alphabetically first key that is
## present** — deterministic without inventing a second "who landed first" rule, and stated here
## rather than left to whatever order a `Dictionary` happens to iterate in. An empty dictionary
## (nothing landed anything inside the window at all) falls back to `self`, the one group that
## always exists whether or not anything else ever did.
static func _crying_cause_suffix(landed_by_group: Dictionary) -> String:
	var names := landed_by_group.keys()
	names.sort()
	var best := ""
	var best_points := -1.0
	for name: String in names:
		var points: float = landed_by_group[name]
		if points > best_points:
			best = name
			best_points = points
	if best == "":
		best = "self"
	return String(best).replace("_", "-")

## The impure half `_crying_cause_suffix()` above is named for: every live event's own `landed()`
## grouped by its catalogue id, or `pelican` for a pelican (`_group_what_events_landed()`), every
## live crowd agent's grouped by `crowd` (a walker) or `traffic` (a car), and the baby's own
## running/alley share under `self` (`Baby.self_landed()`) — all over
## the same `ExcitementHalo.WINDOW` the halo itself reads. Only positive shares are kept, so an
## empty result means nothing landed anything in the window at all.
##
## Read once, from `_on_day_finished()`, in the same physics frame `Baby._update_state()` decided
## she was crying — `EventBus.baby_state_changed` -> `DayController._on_baby_state_changed()` ->
## `_end()` -> `day_finished` all run synchronously in that one call, so nothing below has aged out
## of the window between the two. **Not itself unit-tested** beyond its events half
## (`_group_what_events_landed()`): the rest asks a live `City` and a live `Baby` for their own
## current numbers rather than computing anything, so there is nothing pure left to pin without a
## scene — see `tests/test_day_loop.gd` for the integration coverage a day's
## own ending already gets.
func _crying_landed_by_group() -> Dictionary:
	var by_group := {}
	# The events of whichever world she is in: the city's, or the escape's building's.
	var source := _event_source()
	if source:
		_group_what_events_landed(source.instances(), by_group)
	if _city and _city.crowd:
		for agent: CrowdAgent in _city.crowd.agents():
			var points := agent.landed()
			if points <= 0.0:
				continue
			var key := "traffic" if agent.kind == CrowdAgent.Kind.CAR else "crowd"
			by_group[key] = float(by_group.get(key, 0.0)) + points
	if _baby:
		var self_points := _baby.self_landed()
		if self_points > 0.0:
			by_group["self"] = float(by_group.get("self", 0.0)) + self_points
	return by_group

## `_crying_landed_by_group()`'s events half, folded into `by_group`: each live event's own
## `landed()` under the name the logs give it (`EventInstance.logged_name()`), so a pelican's
## share is `pelican`'s rather than added to the cyclists' *(inbox #527 in azure-tapir)*. Pure over what it is
## handed, and tested directly — `tests/test_day_lost_to.gd`.
static func _group_what_events_landed(instances: Array[EventInstance], by_group: Dictionary) -> void:
	for instance in instances:
		var points := instance.landed()
		if points > 0.0:
			var name := instance.logged_name()
			by_group[name] = float(by_group.get(name, 0.0)) + points

## What ended a crying or hard-fail day, as `EventBus.day_ended` carries it, or "" for a win or a
## timeout, whose results already say everything. See `_hard_fail_cause_suffix()` and
## `_crying_cause_suffix()`.
func _loss_cause(result: GameEnums.DayResult) -> String:
	match result:
		GameEnums.DayResult.LOST_HARD_FAIL:
			var struck_by := _city.events.what_struck_her() if _city and _city.events else ""
			return _hard_fail_cause_suffix(_day.hard_fail_reason, struck_by)
		GameEnums.DayResult.LOST_CRYING:
			return _crying_cause_suffix(_crying_landed_by_group())
	return ""

## **The one place a day ends, the escape's sections included**: what ended it, the charges still
## running closed, `day_ended` with its cause — which the run log and the page's counter both hear —
## then what the day's `DaySpec` says the outcome costs and leads to, and the screen it ends on.
## *(minty-lemur #785: "losing an escape should still state the reason like the rest of the game.
## nothing should be different.")*
func _on_day_finished(result: GameEnums.DayResult) -> void:
	# A day's number is the calendar's; a section's is its own, after the last day.
	var finished_day := GameState.day if _spec.section == DaySpec.Section.NONE else _spec.number
	# Captured here, before anything below touches `_day`, so the summary's clock reads the
	# instant the day actually ended rather than whatever `_day.time_remaining` holds by the time
	# `show_day()` is called several lines down. Clamped because `_process()` can call `_end()`
	# one frame after `time_remaining` has gone slightly negative (a timeout checks `<= 0.0` after
	# subtracting `delta`, not the instant it crosses zero), which would otherwise read a few
	# milliseconds past the day's own length.
	var elapsed_seconds := clampf(_day.time_total - _day.time_remaining, 0.0, _day.time_total)
	# **A day she wins with day 3's fire never met still burns.** The row's only day is day 3 and it
	# is spent when it enters the world, so a won day on which every siting was refused would leave
	# the run with no fire, no scar and no shell for day 4 to come out to. Lit here, off her path,
	# on a site the dawn rules accept — before the day's end below, since it happened in the day
	# rather than after it, and before `GameState.finish_day()`, which is what commits a won
	# day's spending. A lost day gives everything back, so it is asked of a win only. See
	# `EventManager.light_what_she_never_met()`. Only a day walked home has one.
	if result == GameEnums.DayResult.WON and _player and _spec.goal == DaySpec.Goal.HOME:
		_city.events.light_what_she_never_met(_player.global_position)
	# What ended the day, read once in the frame it ended (see `_crying_landed_by_group()`).
	var cause := _loss_cause(result)
	# Every charge still running ends for the page's charging counter, cut short by the day
	# (`end_the_charges_still_running()`, the city's events' or the building's), on the day it was
	# charged — a section she walks out of or loses as much as a day.
	var source := _event_source()
	if source:
		source.end_the_charges_still_running()
	# The one place a day's attempt ends, with everything about it: the run log writes the outcome
	# and the dusk picture and closes the day's section, and the page counts it — `finished_day`
	# rather than `GameState.day`, since a won final day hands over to the escape before the
	# calendar would otherwise move past it. Before the calendar moves, so the outcome is written
	# above the nerve it cost.
	EventBus.day_ended.emit(finished_day, result, cause, elapsed_seconds)
	if _spec.section != DaySpec.Section.NONE:
		_finish_the_section(result, elapsed_seconds)
		return
	# **The last night hands over rather than ending.** *(PLAYTEST-113: "the escape the building
	# starts when the player has completed all tasks by the end of day 14".)* A won day 14 with
	# every task complete is the good ending, and the good ending is now a walk rather than a
	# screen — so `GameState.finish_day()` is deliberately *not* called here: it would end the run
	# on the spot, set `ending`, and clear the save the escape's own checkpoints need. The run ends
	# when she is out of the city (`_finish_the_section()`), and only then.
	if _hands_over_to_the_escape(result):
		# Day 14 is still an ordinary won day, so it still gives a normal run a nerve back — the
		# same gain `GameState.finish_day()` grants every other won day, called here directly because this
		# branch is the one day whose win never reaches that function at all (see the comment
		# above). Before `show_day()` reads `GameState.nerves` a few lines down, so the summary
		# shows the count after the gain.
		GameState.regain_a_nerve_for_a_won_day()
		GameState.escape_section = DaySpec.Section.BUILDING
		_save_now(false)
		_summary.show_day(result, _day.failure_reason, GameState.nerves, elapsed_seconds)
		return
	# Asked before `finish_day()`, which is what goes back: whether this loss spends a normal run's
	# last nerve, so the summary says where she is going rather than that she tries the day again.
	var goes_back := result != GameEnums.DayResult.WON \
			and GameState.a_loss_goes_back_to_the_checkpoint()
	_went_back = goes_back
	_run_over = not GameState.finish_day(result)
	# The end-of-day write — one of the two moments a run is saved. Skipped when the run just
	# ended: `GameState._end_run()` (called from inside `finish_day()` above) already cleared the
	# save, and writing here would resurrect a file naming a run that is over. A normal run sent
	# back to its checkpoint is written here like any other loss, already standing at that dawn.
	if not _run_over:
		_save_now(false)
	_summary.show_day(result, _day.failure_reason, GameState.nerves, elapsed_seconds, goes_back)

## What a section of the escape ending leads to, once `_on_day_finished()` has ended it as it ends
## any day — the section's `DaySpec` says the rest.
##
## - **Lost:** the run spends what the section's rules say (`GameState.finish_day()`: nothing in a
##   normal run, a Nerve in a hard one, whose last is the bad ending), the save is written, and the
##   day's outcome screen comes up with its reason and the section's own words where "Day N" stands.
##   Its continue is the retry, the same section from its own start behind its brief
##   (`_on_summary_continued()`), and a hard run's last nerve shows the ending after it, as a lost
##   day's does.
## - **Won, into the next section** — out of the building's service exit: the city is built behind
##   the black the exit left, and its brief comes up over it.
## - **Won, out of the city** — the tunnel mouth or the bridge deck: for a run, the run itself ends
##   here (`GameState.finish_day()` on the last day picks the ending, writes the `ending` entry and
##   clears the save, which is also what keeps the save alive for every attempt before this one).
##   The sequence ends on a summary screen with the way out behind her and nothing triumphant on
##   it (`DaySummary.show_finale()`), and its continue goes back to the title.
##
## What the page counts of the escape under its own names (`nappy-escape-lost`, `-city`, `-out`)
## goes out here too, beside the day's own `day_ended`.
func _finish_the_section(result: GameEnums.DayResult, elapsed_seconds: float) -> void:
	var spec := _spec
	var won := result == GameEnums.DayResult.WON
	if not won:
		EventBus.escape_lost.emit(spec.section, result)
	elif spec.a_win_leads_into != DaySpec.Section.NONE:
		EventBus.escape_city_entered.emit()
	else:
		# Before `finish_day()`, whose `ending` line closes the run: the way out is part of how it
		# ended. `EventBus.run_ended` fires a moment later, from `GameState.finish_day()` below.
		EventBus.escape_out.emit(_day.exit_reached)
	# The flag's escape is a day-1 run that only jumped here, so getting out of it settles nothing;
	# a lost section costs what it costs either way.
	if not won or _escape_from_a_run:
		_run_over = not GameState.finish_day(result, spec)
	if not won and _recipe:
		# A scripted recipe fails on a lost attempt; a free one reloads every authored actor and
		# progression field rather than taking the ordinary retry.
		if not _recipe.lose_the_attempt():
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
		_run_over = true
		_ending_shown = true
		_hud.visible = false
		_summary.show_finale(_day.exit_reached, elapsed_seconds)
		return
	# The end-of-section write, as a lost day's is, so closing the game on this screen cannot take a
	# hard run's spent nerve back. Skipped when the run just ended, whose save `GameState._end_run()`
	# has already cleared.
	if not _run_over:
		_save_now(false)
	_summary.show_day(result, _day.failure_reason, GameState.nerves, elapsed_seconds, false,
			spec.title)

## Whether the day that just ended is the one the escape follows: **won, the last day, and every
## task complete**. *"After completing all tasks"*, and what that already means in this game is
## `GameState.earned_good_ending()` — `Tuning.RESISTANCE_GOAL` errands run *and* the day-14 step
## performed, the pair that has always decided the good ending — so the escape is reached by
## exactly the runs the good ending was reached by, and nothing new decides who sees it.
##
## A won day 14 without them keeps the ending it has today: the neutral screen, from
## `_on_summary_continued()`'s own `_run_over` branch.
func _hands_over_to_the_escape(result: GameEnums.DayResult) -> bool:
	# A recipe boot never takes the escape over: its won day reloads the authored scene, and the
	# reload would boot the escape with no director for the scene's task to run on.
	if _recipe:
		return false
	return result == GameEnums.DayResult.WON and GameState.is_final_day() \
			and GameState.earned_good_ending()

## The same `DaySummary.continued` signal reaches this from every screen `_summary` can be showing,
## told apart by `_resume_gate_open`, by the run's own escape section and by what the run has
## come to: a day brief in front of a day already built (a resumed run's, or the brief an escape
## section opens on), day 14's own summary on a run that has just earned the escape, the ordinary
## end-of-day message — a lost section's included, whose continue raises the retry's brief — or an
## ending.
## Only the first of those is *engaging* an already-built day rather than starting a new one.
func _on_summary_continued() -> void:
	if _recipe:
		# A recipe describes one authored day. Keep its normal result, then start that
		# exact setup again instead of interpreting its pins under the next day's rules.
		_summary.dismiss()
		_reload_the_scene()
		return
	# The last thing the fourteen days do. A scene reload rather than tearing this boot's city,
	# day, resistance and observer down by hand and building a building over them — the same
	# reasoning `_restart_run()` gives for the same call, and the next boot then reads
	# `GameState.escape_section` off the autoload that survived it and opens on the building.
	# Day 14's own save, written as its summary appeared, may still be waiting for the browser:
	# `_reload_the_scene()` carries its symbol over, so the escape's boot adopts it and the answer
	# settles it there.
	if _spec.section == DaySpec.Section.NONE \
			and GameState.escape_section != DaySpec.Section.NONE:
		_summary.dismiss()
		_reload_the_scene()
		return
	if _resume_gate_open:
		_resume_gate_open = false
		# The brief's own loading window shuts with the brief: from here she is walking, and a
		# page read from disk in a walked frame is the stutter the window exists to refuse.
		AtlasLibrary.close_loading_window()
		_summary.dismiss()
		_engage_the_day()
		return
	if not _run_over:
		_summary.dismiss()
		if _went_back:
			_went_back = false
			_carry_the_run_into_the_next_boot()
			return
		# A lost section is tried again from its own start, behind its brief, as a lost day's
		# continue leads to the day's morning: the outcome screen states why it was lost
		# (minty-lemur #785), and the brief comes up before the retry for the building and the
		# city alike, nerves unchanged or not (PLAYTEST-94 10). The brief's continue is the walk.
		if _spec.section != DaySpec.Section.NONE:
			_start_section(_spec, true)
			_show_the_section_brief()
			return
		_start_day()
		# No gate stands between one day's own end-of-day message and the next day's dawn, unlike
		# the title (and, on a resumed run, the day brief behind it) a fresh day 1 opens behind —
		# so this is already the moment she is playing the next day, and the write says so at once.
		_save_now(true)
		return
	if not _ending_shown:
		_ending_shown = true
		_summary.show_ending(GameState.ending, GameState.day)
		return
	# A run that is over goes back to where a run begins, which is the title screen: an ending is
	# not a dead end the player has to quit out of.
	_restart_run()

## A normal run back at its checkpoint goes on in a freshly booted scene, never on this one.
## *(gentle-osprey, the player: "store the exact state at the checkpoint -- continuing should not
## have anything that happened after the checkpoint".)* `GameState` was put back at the checkpoint's
## dawn by `GameState.finish_day()`, but the world built on it remembers things the run's state
## does not — day 11's boarded window over the neighbor's flat is drawn by her own building "for the
## rest of the run" — and a world rebuilt from scratch remembers nothing. So the continue on the
## lost-day screen reloads the scene, as the held restart and the escape's handover do, and the next
## boot (`_carried_from_a_checkpoint`) builds the checkpoint's day on the run exactly as a load would
## give it, then starts it. The save already says that dawn: `_on_day_finished()` wrote it as the
## lost-day screen came up.
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
	# once `GameState.ending` is already set; that run already reported itself through
	# `EventBus.run_ended` and is not a held restart of anything.
	if GameState.ending == GameEnums.Ending.NONE:
		EventBus.run_restarted.emit(GameState.day)
	# The held restart clears the save — the pause screen's and the day summary's own button both
	# reach this one function, so no new control is drawn for it. A deletion is a change in the save
	# state, which the symbol shows (`GameSave.clear()` announces it on `EventBus`); a restart after
	# `GameState._end_run()` already deleted the save finds none and changes nothing, so it shows
	# nothing. **Before the session closes the run log**: the "deleted the save"
	# line, and the "deletion was not kept" line when a deletion fails at once, belong to this run's
	# log. A web deletion's later answer is logged only if a log is open when it arrives, so it
	# may land in the next run's log after the reload.
	GameSave.clear()
	if _session:
		_session.close()
	# And with it the run's record of being in the escape, which outlives the scene reload below
	# because it lives on an autoload. Left set, the fresh boot would skip its own `start_run()` and
	# open the escape again over a run that was just thrown away. A no-op for a restart from an
	# ordinary day and for a finished run, which `GameState._end_run()` has already cleared.
	GameState.escape_section = DaySpec.Section.NONE
	TitleScreen.note_restart_requested()
	_reload_the_scene()

## **Every scene reload goes through here**: the held restart (`_restart_run()`), the day-14
## hand-over to the escape (`_on_summary_continued()`), a normal run carried on from its checkpoint
## (`_carry_the_run_into_the_next_boot()`) and a free recipe's lost escape section played again
## (`_finish_the_section()`). A reload frees this node and the symbol under it, and a change in
## the save state may still be waiting for the browser — the restart's deletion, the lost day's
## write a checkpoint reload follows, or day 14's own save at the hand-over — so the symbol is
## carried over first (`_carry_the_save_symbol_over()`) and the next boot adopts it. One place, so a reload added later cannot forget the symbol.
##
## The tree is unpaused first: `reload_current_scene` builds the new scene into the same tree, and
## a paused one would open the next screen over a game that could never start. Read through
## `Engine.get_main_loop()` rather than `get_tree()`, so a test can drive the paths that reach this
## with a `main` that is not parented, and the reload itself goes to `_reload_override` when a test
## has set one: a real reload would throw away the test runner's own scene.
func _reload_the_scene() -> void:
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
## `is_inside_tree()` — and `tests/test_main.gd` drives `_process()` on a script-only instance with
## no tree behind it at all. There is exactly one `SceneTree` for the whole process, whether a
## person is playing or the suite is driving this frame by hand, so asking the engine for it
## answers the same question either way.
func _tree_is_paused() -> bool:
	var loop := Engine.get_main_loop()
	return loop is SceneTree and (loop as SceneTree).paused

func _process(delta: float) -> void:
	_end_the_return_window()
	# M195, always closes: the outer half of the guarantee `_lock_out_a_rig()` starts — see
	# `_rig_quit_deadline_msec`'s own doc for why this reads `Time.get_ticks_msec()` fresh rather
	# than trusting `delta` to have summed correctly. Ahead of every other line in this function on
	# purpose: whatever screen is up when the deadline passes, a rig still quits from here.
	# `tools/shot.sh` (and a rig-flagged `tools/run.sh`) is the outside backstop for the case this
	# line itself never runs again.
	if _rig_quit_deadline_msec != 0 and Time.get_ticks_msec() >= _rig_quit_deadline_msec:
		printerr("[Main] a rig's own wall-clock limit (%.1fs) passed with the run still going; quitting"
				% config.rig_quit_seconds())
		get_tree().quit(1)
		return
	if _rig_quit_game_seconds > 0.0:
		_rig_quit_game_seconds -= delta
		if _rig_quit_game_seconds <= 0.0:
			printerr("[Main] a recorded rig's own limit (%.1f game seconds) passed with the run still "
					% config.rig_quit_seconds() + "going; quitting")
			get_tree().quit(1)
			return
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
	if _in_the_title:
		# `EventManager` streams around the player and there is no player, so the street outside the
		# home would play out whatever was standing on it at dawn and then quietly empty. One call a
		# frame keeps it stocked. Only the *streaming* is stood in for: what the director owes ahead
		# of her is not placed, because it is placed in front of somebody walking somewhere. Only a
		# city left running behind the title needs it: an escape's stays paused there.
		if _city and _city.process_mode == Node.PROCESS_MODE_ALWAYS:
			_city.events.stream_around(_player.global_position)
		return
	# `GameState.play_seconds` has exactly one owner: this branch, which already knows the phase
	# and (through `_tree_is_paused()`) the pause state. It runs while a day — an escape section
	# included — is `WALKING` or `RETURNING` and the tree is not paused: the pause screen and the
	# day summary both leave `phase` here but pause the tree, and a day that has just ended has
	# already left `phase` at `OVER` by the time either one opens, since `DayController._end()` sets
	# it before emitting the signal that shows the summary. The title screen `return`s above this
	# line, so it never reaches it either.
	var walking := _day.phase in [GameEnums.DayPhase.WALKING, GameEnums.DayPhase.RETURNING] \
			and not _tree_is_paused()
	if walking:
		GameState.play_seconds += delta
	# The building's doors and its service exit are asked about the ground under her while she is
	# walking it. Nothing of the walk is asked while a screen stands in front of it: this node runs
	# through a pause (it has to, or Esc would not answer), so without this the door under her feet
	# would keep being tested against a section that has not begun.
	if _spec.world == DaySpec.World.BUILDING and _interior and not _tree_is_paused():
		_interior.process_player(_player, delta)
	if _city and _spec.daylight_runs_down:
		_city.set_daylight(_day.fraction_remaining())
	_hud.set_home_guidance(_spec.goal == DaySpec.Goal.HOME
			and _day.phase == GameEnums.DayPhase.RETURNING,
			_city.map.home_world_position() if _city else Vector2.ZERO)
	# The red arrow: `ResistanceDirector.red_arrow_target()` is the one place that decides
	# whether today's task is on offer with its mark already touched, and which of the places
	# that answer it the arrow points at, so this is only ever a read of it, never a placement
	# or a move of its own — and asking it is a read too: the director chooses in its own
	# `_process()`. `_resistance` can be null here —
	# several `tests/test_main.gd` rigs drive `_process()` with a script-only `main` that never
	# builds one, the same reason `_dev_rig` and `_frame_graph` are checked below rather than
	# assumed.
	var task_at := _resistance.red_arrow_target() if _resistance else Vector2.INF
	_hud.set_task_guidance(task_at != Vector2.INF, task_at)
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
		_readout_wait = 0.0
		return
	if not _readout_due(delta):
		return
	if _build_text == "":
		_build_text = BuildInfo.build_text()
	# The `skip` line names what `_skip_words` is off, directly beneath the seed line, so a
	# screenshot taken under `--skip` says what it measured — absent when nothing is skipped, the
	# ordinary case, so an unflagged readout carries no empty line where this one would go.
	var header := [
		"build %s" % _build_text,
		"seed  %d   day %d%s" % [GameState.run_seed,
			GameState.day if _spec.section == DaySpec.Section.NONE else _spec.number,
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

## The readout's ground under her: the city's tile and whether it is calm or an alley, or the
## escape building's own tile, which has neither.
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
	if _interior:
		var tile := _interior.world_to_tile(here)
		return ["tile  %d, %d  (building)" % [tile.x, tile.y]]
	return []

## The readout's count of what is out: the city's events, live against planned, what the director
## still owes ahead of her and the crowd — or, in the escape's building, its events alone.
func _what_is_out_lines() -> Array:
	if _city:
		return [
			"events      %6d live of %d" % [
				_city.events.active_count(), _city.events.planned_count()],
			"ahead owed  %6d" % _city.events.owed_ahead(),
			"crowd       %6d" % _city.crowd.agent_count(),
		]
	var source := _event_source()
	return ["events      %6d live" % (source.instances().size() if source else 0)]

## Whether this frame rebuilds the readout's text: the first frame after it is switched on, and then
## every `READOUT_INTERVAL`. Counts the frames' own `delta`, so a slow frame does not shorten the wait.
func _readout_due(delta: float) -> bool:
	_readout_wait -= delta
	if _readout_wait > 0.0:
		return false
	_readout_wait = READOUT_INTERVAL
	return true

## The frame record's readout line, beneath the frame block, or nothing when no record runs.
func _frame_record_lines() -> Array[String]:
	if _frame_recorder == null:
		return []
	return [_frame_recorder.readout_line()]

## The closest live event and what it is currently doing — the readout that says whether a
## telegraph actually ended when it should have. Asked of `_event_source()`, so the escape's
## building answers it too.
func _nearest_event_text() -> String:
	var nearest: EventInstance = null
	var best := INF
	var source := _event_source()
	if not source:
		return "none"
	for instance: EventInstance in source.instances():
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
## walked (`_spec`), so the guard never reaches a day's own summary.
##
## **Runs in the `_input` phase, ahead of this one.** Godot finishes calling every node's `_input()`
## before it starts the `_unhandled_input` phase at all, so marking a real event handled here keeps
## it from ever reaching this function's own guards below, the pause and title screens' `KEY_R`/
## `KEY_Q` (read as raw keycodes rather than actions, so `InputMap` cannot gate them — see
## `_erase_real_input_for_a_rig()`'s own doc for what does), and `_debug_snapshot_action()`/
## `_debug_layer_key()` just above. **Does not reach `TouchControls`' own `_input()`** — a sibling
## handler in the same phase, which nothing can pre-empt, since `set_input_as_handled()` only
## silences the phases *after* `_input`. A real mouse drag against the on-screen joystick is
## outside this fix's reach; the realistic threat the playtest actually named — a stray key typed
## into a window that has taken the focus while the operator works elsewhere — is a keyboard one,
## and `WINDOW_FLAG_NO_FOCUS` (`_lock_out_a_rig()`) is what stops the window from taking that focus
## in the first place, so a pointer event over it is already the unlikelier half of the risk.
##
## **A rig's own `--press` gets through by a tag on the event, not by its class.** `AutoScreenshot.
## _tap()` sets `event.device = InputEvent.DEVICE_ID_EMULATION` (Godot's own constant, `-1`, distinct
## from `DEVICE_ID_KEYBOARD` (`16`) and `DEVICE_ID_MOUSE` (`32`)) before handing each event to
## `Input.parse_input_event()`, and `_is_the_rigs_own_press()` below is the one check that reads it
## rather than marking handled. Gating on the event's class instead would open the exact hole this
## function exists to close: `key:` presses are `InputEventKey`, the same class a real key already
## is, and a real `InputEventAction` can reach a window too — an on-screen back button delivers one
## — so "let every `InputEventAction` through" would let that through as well. The device tag is
## what `Input.parse_input_event()` itself leaves untouched between the script that built the event
## and every handler downstream, so it is the one thing on the event a rig controls and nothing
## external does.
func _input(event: InputEvent) -> void:
	if _rig_locked_out and not _is_the_rigs_own_press(event):
		get_viewport().set_input_as_handled()

## Whether the half second after getting focus back (`_arm_the_return_window()`) is still running.
func _ignoring_input_after_a_return() -> bool:
	return Time.get_ticks_msec() < _input_ignored_until_msec

## Whether the game has lost focus or been hidden since the window last opened. **A return needs a
## departure:** the page's own first focus at load is not a return, and a player's first tap in the
## half second after the page loads must reach the game (the browser check's Space does). Set by
## `_note_leaving_the_game()`, cleared by `_arm_the_return_window()` when it opens the window.
var _has_left_the_game := false

## Marks that the game has been left (focus out, paused, the page hidden or blurred).
func _note_leaving_the_game() -> void:
	_has_left_the_game = true

## The viewport whose input is switched off for the window; `_ready()` sets it, a test sets its own.
var _return_viewport: Viewport = null

## Getting focus back starts the window, and **`Viewport.set_disable_input(true)` is how it is
## enforced**, not a mark in `_input()`: a disabled viewport delivers nothing to any `_input()`,
## the GUI or `_unhandled_input()`, so `TouchControls._input()` (a sibling that no handler here can
## pre-empt) and the pause and day-brief screens are all deaf together. A gate in `main._input()`
## cannot promise that, since `_input()` runs on children before their parents.
## It stops *events* only: `Input`'s own held state still follows the keyboard, so a key held
## through the return is still pressed for polling afterwards, and one released inside the window is
## released. **Nothing can leave input off:** the end is read off the wall clock by `_process()`
## (`_end_the_return_window()`), which runs under a pause, and `_exit_tree()` and `_ready()` clear
## it too, because the root viewport outlives a scene reload. A no-op without a departure first
## (`_has_left_the_game`), which the arming spends, so a second trigger inside the window does
## nothing unless the game was left again in between. A no-op for a rig (`_rig_locked_out`: any of
## `--screenshot`, `--walk`, `--flee`, `--press`, `--tap`, `--route`, a recording or a scripted
## recipe — `config.is_rig`) and under `_no_focus_pause` (`--no-focus-pause`), so a rig is
## never slowed.
func _arm_the_return_window() -> void:
	if not _has_left_the_game or _no_focus_pause or _rig_locked_out or _return_viewport == null:
		return
	_has_left_the_game = false
	_input_ignored_until_msec = Time.get_ticks_msec() + RETURN_INPUT_IGNORED_MSEC
	_return_viewport.set_disable_input(true)

## Called every frame, and by `_exit_tree()`/`_ready()` with `force`: puts input back once the
## window has passed.
func _end_the_return_window(force := false) -> void:
	if _input_ignored_until_msec == 0 or (not force and _ignoring_input_after_a_return()):
		return
	_input_ignored_until_msec = 0
	if _return_viewport != null and is_instance_valid(_return_viewport):
		_return_viewport.set_disable_input(false)

## The web page is where "returning" was seen, and the engine's FOCUS_IN on a tab return is not
## confirmed there, so a second trigger comes straight from the browser: the page becoming visible
## again (`visibilitychange`) and the window getting focus (`focus`); the departures are the page
## going hidden and the window losing focus (`blur`). Whichever return arrives first opens the
## window; later ones inside it find the departure already spent. Web builds only.
var _web_return_callback: JavaScriptObject = null
func _listen_for_a_web_return() -> void:
	if not OS.has_feature("web"):
		return
	_web_return_callback = JavaScriptBridge.create_callback(_on_web_return)
	var document := JavaScriptBridge.get_interface("document")
	var window := JavaScriptBridge.get_interface("window")
	document.addEventListener("visibilitychange", _web_return_callback)
	window.addEventListener("focus", _web_return_callback)
	window.addEventListener("blur", _web_return_callback)

## Removes what `_listen_for_a_web_return()` added, so a scene reload does not pile up listeners.
func _stop_listening_for_a_web_return() -> void:
	if _web_return_callback == null:
		return
	JavaScriptBridge.get_interface("document").removeEventListener("visibilitychange", _web_return_callback)
	JavaScriptBridge.get_interface("window").removeEventListener("focus", _web_return_callback)
	JavaScriptBridge.get_interface("window").removeEventListener("blur", _web_return_callback)
	_web_return_callback = null

func _on_web_return(args: Array) -> void:
	var event: JavaScriptObject = args[0] if args.size() > 0 else null
	var kind := str(event.type) if event != null else ""
	_on_web_event(kind, str(JavaScriptBridge.get_interface("document").visibilityState))

## The decision half of the web callback, with the browser's answers passed in so a test can drive
## it: a `blur`, or a `visibilitychange` to anything but "visible", is a departure; a `focus`, or a
## `visibilitychange` to "visible", is a return.
func _on_web_event(kind: String, visibility: String) -> void:
	if kind == "blur" or (kind == "visibilitychange" and visibility != "visible"):
		_note_leaving_the_game()
	elif kind == "focus" or kind == "visibilitychange":
		_arm_the_return_window()

## A static, pure predicate for the same reason `_debug_snapshot_action()` and `_debug_layer_key()`
## are static — a test can ask it directly without booting a `main` (`_ready()` starts a whole run),
## the seam `tests/test_main.gd`'s own class doc explains for every other case here.
static func _is_the_rigs_own_press(event: InputEvent) -> bool:
	return event.device == InputEvent.DEVICE_ID_EMULATION

## PLAYTEST-133, M195: a rig's window takes no OS focus, hears no real key or pointer press, and
## quits itself on a wall-clock deadline — three defences for the one thing the player named
## ("it takes the focus away from what I'm doing every time" · "if I click somewhere else they
## stay open"). Called once, first thing in `_ready()`, ahead of the escape's own boot branch so
## either path gets all three; a no-op the instant `config.is_rig` is false, which is every
## plain `tools/run.sh` session a person is actually playing.
##
## **The window flag is applied as early as this scene's own script can run, not "before the
## window shows."** Godot creates the OS window as part of engine start-up, well before any scene
## script exists to ask it anything — there is no earlier hook this file can reach without an
## autoload, which is outside this milestone's own scope fence — so this is the earliest a rig's
## own boot can still strip it.
##
## **Two defences, not one, because a real key reaches the game two different ways.** `_input()`
## above closes the event-dispatch half (the pause action, the title's Space, the pause/title
## screens' raw `KEY_R`/`KEY_Q`, this file's own debug snapshot and layer keys). Erasing every
## action's own `InputMap` bindings closes the *polled* half instead — `Stroller._physics_process()`
## reads `Input.get_vector()` every tick, never an event, so a real WASD press would still move her
## even with every event marked handled. `Input.action_press()`/`action_release()` (what
## `AutoScreenshot`'s own `_walk`/`_flee`/`_press` drive her through) do not go through `InputMap`
## matching at all, so erasing these bindings leaves the rig's own synthetic presses working exactly
## as before while a real key with nothing left to map it to can no longer move, run or pause
## anything.
func _lock_out_a_rig() -> void:
	if not config.is_rig:
		return
	_rig_locked_out = true
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	_erase_real_input_for_a_rig()
	if config.recording:
		_rig_quit_game_seconds = config.rig_quit_seconds()
	else:
		_rig_quit_deadline_msec = Time.get_ticks_msec() + int(config.rig_quit_seconds() * 1000.0)

## Every action `project.godot`'s own `[input]` table defines — read live off `InputMap` rather
## than spelled out by hand, so a binding added there is covered without a second list to keep in
## step — but Godot's own built-in `ui_*` actions (`ui_accept`, `ui_cancel` and the rest), which
## nothing in this game reads and which stripping would cost the engine's own debugging shortcuts
## for nothing this milestone asked for.
func _erase_real_input_for_a_rig() -> void:
	for action in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			InputMap.action_erase_events(action)

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
	# Defensive rather than load-bearing: every real boot builds one, but a bare script-only `main`
	# a test drives straight through this function without also calling `_ready()` may not have.
	if not _pause:
		return
	if _pause.is_open() or _title.is_open():
		return
	# The escape's own guard — see this function's own doc, "The escape's brief and its epilogue
	# are the one exception". `_resume_gate_open` is a section's brief up, whichever way it came.
	if _spec.section != DaySpec.Section.NONE and _summary and _summary.is_showing() \
			and (_resume_gate_open or _summary.is_showing_the_epilogue()):
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
	if _save_indicator and _save_indicator.is_showing():
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
	GameSave.write(day_under_way)

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
	if _session:
		_session.picture(_capture_context())

func _start_burst() -> void:
	if _session:
		_session.burst(_capture_context())

func _quit() -> void:
	if _session:
		_session.close()
	get_tree().quit()

## Closing the window is the other way a run ends, and the run session closes the log for it
## (`RunSession._notification()`).
##
## `NOTIFICATION_APPLICATION_FOCUS_OUT` is the one this game has exactly one window to lose: it
## fires whenever the OS gives focus to a different application, which is the whole of "Alt-Tabbing
## away" on a single-window desktop app, a browser tab going to the background, or a click on
## another window on the same machine. `NOTIFICATION_WM_WINDOW_FOCUS_OUT` is a **per-`Window`**
## signal instead — the one a game with more than one of its own windows would need to tell which
## of them lost focus, including to another window of the *same* game — and this project never
## builds a second one, so it is not read here.
## `NOTIFICATION_APPLICATION_PAUSED` is a phone sending the whole app to the background. Getting
## focus back (`NOTIFICATION_APPLICATION_FOCUS_IN`/`NOTIFICATION_APPLICATION_RESUMED`) does not
## resume (see `_pause_on_focus_lost()`'s own doc) and starts the 500ms during which the viewport
## delivers no input at all (`RETURN_INPUT_IGNORED_MSEC`, `_arm_the_return_window()`).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_note_leaving_the_game()
		_pause_on_focus_lost()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_arm_the_return_window()
