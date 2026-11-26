class_name RunConfig
extends RefCounted
## The run's configuration: every developer flag and the page's query, resolved at boot and
## never changed afterwards. Layer one, data and configuration: `main` resolves it
## (`at_boot()`), hands it to the observers (`Telemetry`, `GameSave`, `VisitCounter`) and to the
## dev rigs, and hands the simulation the plain values it needs out of it — a day's length, whether
## the clock stands still, whether a crowd is drawn — so nothing below `main` reads a flag, the
## command line or the address bar.
##
## **Immutable.** Every field is private and written once, by `parse()`, and nothing else writes
## one: no other class may (`tools/check_field_reads.py` fails a write of another class's field
## under `src/`, an underscore name included), and this one never does after `parse()`. What it
## hands out cannot reach it either: its arrays are read-only and its words a copy. A test hands a
## component a config of its own by parsing the words it wants
## (`RunConfig.parse(PackedStringArray(["--invincible"]), "", true)`), never by changing one.
##
## **Read through its methods** (designing-classes, "Fields are not API"): one method a field,
## which keeps the field's name when it holds a value and takes a new one when it answers yes or
## no, so a stored answer can become a computed one with no reader changing. Every reader, `main`
## included, asks the methods under "What it says" below. The class is the one value every reader
## is handed whole, rather than cut into a part
## per reader, since the readers' needs overlap (a screenshot's path is the screenshot rig's and
## the scene recipe's, a movie recording the rig lock's and the screenshot rig's) and several of
## its answers are derived from more than one flag (`day_length_for()`, `rig_quit_seconds()`,
## `screenshot_rig()`), which a reader handed plain values would derive again.
##
## `DevFlags` is the parser and the flag manifest the shell tools read; what each flag means is
## its getter's doc there.

## How long one section of the escape runs, on top of a real `DayController`'s own clock — each
## section is its own day with a brief and a restart checkpoint of its own, and the player's
## answer was *"180s per section"*. Stated on its own rather than reused from the ordinary day's
## length: the player asked that *"the escape shouldn't be easy!"* (`docs/playtests/PLAYTEST-121.md`),
## so the escape does not grow when the ordinary day does. Asked alongside the ordinary day's
## length and not yet answered whether it should grow too — open to overturn.
const FINALE_LENGTH_SECONDS := 180.0

## The words and the query this was parsed from, kept so `with_recipe()` can parse the same run
## again with a recipe on top, without asking the process or the page a second time.
var _given := PackedStringArray()
var _movie := false

# ------------------------------------------------------------------ the gates ---

## The null display server a headless run boots against: no window, so no player, and the
## run never touches the player's save (`GameSave._uses_save()`). Read from the process at
## boot (`at_boot()`); a test that wants the saving of a windowed run parses `false`.
var _headless := true
## A debug build: the gate on every command-line flag.
var _debug_build := false
## `?debug=1` or `--debug`: the readout, and the gate on every release-safe query flag.
var _readout_requested := false
## The release-safe bundle is open: a debug build, or a page that asked `?debug=1`.
var _live_debug := false
## The page's query named one of the bundle's parameters while the bundle was open.
var _web_debug_flag_used := false
## The page's query string as the browser gave it at boot, or "" off the web — for the few readers
## that parse a parameter of their own (`Telemetry`'s `?telemetry=1`, `WebDisplay`'s `?dpr=`).
var _page_query := ""
## The command line on a debug build, or nothing: every dev flag given, as words. Every read is a
## copy, since a packed array is shared by reference and a reader's edit would otherwise reach
## every other reader.
var _active_args := PackedStringArray()
## `--no-telemetry`, the player-facing opt-out, read on every build.
var _no_telemetry := false

# ------------------------------------------------------------------ the run ---

var _seed_override := 0
var _day_override := 1
## `-1.0` for "not given"; see `day_length_for()`.
var _day_length_override := -1.0
var _parent_override := ""
var _hard_mode_requested := false
var _nerves_override := 0
var _invincible := false
var _start_escape := false
var _start_escape_at := ""
var _ending_override := ""
var _controls_word := ""
var _no_save := false
var _no_focus_pause := false
var _title_requested := false
var _no_title_requested := false
## `--touch`: the touch hardware question answers yes (`TouchInput.available()`).
var _touch_forced := false
## `--web`: the quit question answers as the web export does (`QuitOption.available()`).
var _web_preview := false

# ------------------------------------------------------------- what is placed ---

var _spawn_target := ""
var _meters_override := Vector2(-1.0, -1.0)
## `--chargers`' warning and radius factor, or `(-1, -1)`; see `charger_timing()`.
var _charger_timing_override := Vector2(-1.0, -1.0)
var _forced_row := ""
var _forced_interval := 0.0
var _pelican := false
var _blackout_requested := false
## `--escape-bag`: the bag the escape's city is drawn from (`DaySpec.ESCAPE_BAGS`).
var _escape_bag := DaySpec.DEFAULT_ESCAPE_BAG
## `--building-flash-gap`: the least seconds between two flashes of the escape building's windows.
var _building_flash_gap := 0.0

# ------------------------------------------------------------ how it is drawn ---

## The validated `--skip` words; the four booleans below are the same set, read once.
var _skip_words: Array[String] = []
var _skip_events := false
var _skip_crowd := false
var _skip_shadows := false
var _skip_motion := false
var _ground_mode := DevFlags.GROUND_MODE_DEFAULT
var _layers_override: Array[int] = []
var _player_view_requested := false
var _overview_requested := false
var _zoom_override := 1.0
var _follow_target := ""

# --------------------------------------------------------------- measurement ---

var _spikes_requested := false
var _frame_trace_requested := false
var _frame_record_requested := false

# ---------------------------------------------------------------------- rigs ---

## A rig rather than a person: a rig flag, a movie recording, or a scripted recipe.
var _is_rig := false
## Godot's own movie writer is recording this run.
var _recording := false
var _route_targets: Array[String] = []
var _screenshot_path := ""
## `--after`'s value, or `-1.0`.
var _rig_after := -1.0
var _quit_when_still_requested := false
var _quit_when_still_seconds := 1.0
var _zoom_out_seconds := -1.0
var _zoom_out_delay := 0.0
var _caption_text := ""
var _title_card_text := ""

# ------------------------------------------------------------- scene recipes ---

var _recipe_path := ""
var _recipe_scripted := false
var _recipe_validate := false
var _recipe_manifest_path := ""
var _recipe_draft_path := ""

# ------------------------------------------------------------------- resolving ---

## The process's own configuration, resolved from the real command line and the page's query on
## every call and held by the caller: `main` takes it at each boot (a scene reload is a new `main`
## and parses the same words again, which is the same configuration, since the command line and the
## page's query do not change under a running page and a `RunConfig` is immutable). No static
## holds it.
static func at_boot() -> RunConfig:
	return parse(OS.get_cmdline_user_args(), DevFlags.page_query(), OS.is_debug_build(),
			OS.has_feature("movie"), {}, DisplayServer.get_name() == "headless")

## The configuration `args` and `query` describe on a build that is (`debug_build`) or is not a
## debug one, recorded by the movie writer or not, with a loaded recipe's data on top or `{}`, on a
## headless display server (the default: a test's run has no window) or a windowed one.
## Pure in its inputs: a test builds the run it wants by passing the words it would type.
static func parse(args: PackedStringArray, query: String, debug_build: bool,
		recording_movie := false, recipe_data: Dictionary = {}, headless_display := true) -> RunConfig:
	var flags := DevFlags.new(args, query, debug_build, recording_movie, recipe_data)
	var config := RunConfig.new()
	config._given = args.duplicate()
	config._movie = recording_movie
	config._debug_build = debug_build
	config._headless = headless_display
	config._readout_requested = flags.readout_requested()
	config._live_debug = flags.live_debug_requested()
	config._web_debug_flag_used = flags.web_debug_flag_used()
	config._page_query = query
	config._active_args = flags.active_args()
	config._no_telemetry = flags.no_telemetry()

	config._seed_override = flags.seed_override()
	config._day_override = flags.day_override()
	config._day_length_override = flags.day_length_override()
	config._parent_override = flags.parent_override()
	config._hard_mode_requested = flags.hard_mode_requested()
	config._nerves_override = flags.nerves_override()
	config._invincible = flags.invincible()
	config._start_escape = flags.start_escape()
	config._start_escape_at = flags.start_escape_at()
	config._ending_override = flags.ending_override()
	config._controls_word = flags.controls_word()
	config._no_save = flags.no_save()
	config._no_focus_pause = flags.no_focus_pause()
	config._title_requested = flags.title_requested()
	config._no_title_requested = flags.no_title_requested()
	config._touch_forced = flags.touch_forced()
	config._web_preview = flags.web_preview()

	config._spawn_target = flags.spawn_target()
	config._meters_override = flags.meters_override()
	config._charger_timing_override = flags.charger_timing_override()
	config._forced_row = flags.forced_row()
	config._forced_interval = flags.forced_interval()
	config._pelican = flags.pelican()
	config._blackout_requested = flags.blackout_requested()
	config._escape_bag = flags.escape_bag()
	config._building_flash_gap = flags.building_flash_gap()

	var skip := flags.skip_words()
	config._skip_words = skip
	config._skip_events = "events" in skip
	config._skip_crowd = "crowd" in skip
	config._skip_shadows = "shadows" in skip
	config._skip_motion = "motion" in skip
	config._ground_mode = flags.ground_mode()
	config._layers_override = flags.layers_override()
	config._player_view_requested = flags.player_view_requested()
	config._overview_requested = flags.overview_requested()
	config._zoom_override = flags.zoom_override()
	config._follow_target = flags.follow_target()

	config._spikes_requested = flags.spikes_requested()
	config._frame_trace_requested = flags.frame_trace_requested()
	config._frame_record_requested = flags.frame_record_requested()

	config._is_rig = flags.is_rig()
	config._recording = flags.recording()
	config._route_targets = flags.route_targets()
	config._screenshot_path = flags.screenshot_path()
	config._rig_after = flags.rig_after()
	config._quit_when_still_requested = flags.quit_when_still_requested()
	config._quit_when_still_seconds = flags.quit_when_still_seconds()
	config._zoom_out_seconds = flags.zoom_out_seconds()
	config._zoom_out_delay = flags.zoom_out_delay()
	config._caption_text = flags.caption_text()
	config._title_card_text = flags.title_card_text()

	config._recipe_path = flags.recipe_path()
	config._recipe_scripted = flags.recipe_scripted()
	config._recipe_validate = flags.recipe_validate()
	config._recipe_manifest_path = flags.recipe_manifest_path()
	config._recipe_draft_path = flags.recipe_draft_path()
	config._freeze()
	return config

## This run with a loaded recipe's data on top: the recipe's seed, day, escape part and parent in
## place of the flags' own. Parsed again from the same words and query, never from the process.
func with_recipe(recipe_data: Dictionary) -> RunConfig:
	return parse(_given, _page_query, _debug_build, _movie, recipe_data, _headless)

# ------------------------------------------------------------------ what it says ---

## Whether this is a headless run: the null display server, so no player and no save.
func is_headless() -> bool:
	return _headless

## Whether this is a debug build, the gate on every command-line flag.
func is_debug_build() -> bool:
	return _debug_build

## Whether `?debug=1` or `--debug` asked for the readout.
func asks_for_the_readout() -> bool:
	return _readout_requested

## Whether the release-safe bundle of query flags is open.
func is_live_debug() -> bool:
	return _live_debug

## Whether the page's query named one of the open bundle's parameters.
func used_a_web_debug_flag() -> bool:
	return _web_debug_flag_used

## The page's query string as the browser gave it at boot, `""` off the web.
func page_query_string() -> String:
	return _page_query

## Every dev flag given on a debug build, as words (a copy, so a reader's edit reaches no other
## reader), or nothing.
func dev_flag_words() -> PackedStringArray:
	return _active_args.duplicate()

## Whether `--no-telemetry` was given: the player's own opt-out of the run log, on every build.
func refuses_telemetry() -> bool:
	return _no_telemetry

# ----------------------------------------------------------------- the run ---

## `--seed`'s value, or `0` for the run's own seed.
func seed_override() -> int:
	return _seed_override

## The day `--day` starts on, clamped into the run, or `1`.
func day_override() -> int:
	return _day_override

## `--parent`'s word, or `""`.
func parent_override() -> String:
	return _parent_override

## Whether `--hard` begins the fresh run in hard mode.
func asks_for_hard_mode() -> bool:
	return _hard_mode_requested

## The nerves `--nerves` starts the run with, or `0` for the run's own.
func nerves_override() -> int:
	return _nerves_override

## Whether `--invincible` was given.
func is_invincible() -> bool:
	return _invincible

## Whether `--start-escape` (or a recipe of kind `escape`) starts the boot in the escape.
func starts_in_the_escape() -> bool:
	return _start_escape

## `--start-escape`'s raw word, the building part it starts at, or `""`.
func start_escape_at() -> String:
	return _start_escape_at

## `--ending`'s raw word, or `""`.
func ending_override() -> String:
	return _ending_override

## `--controls`'s raw word, or `""`.
func controls_word() -> String:
	return _controls_word

## Whether `--no-save` was given.
func refuses_saving() -> bool:
	return _no_save

## Whether `--no-focus-pause` (or `--screenshot`, which implies it) turns off the pause the window
## losing focus opens.
func skips_the_focus_pause() -> bool:
	return _no_focus_pause

## Whether `--touch` forces the touch controls.
func forces_touch() -> bool:
	return _touch_forced

## Whether `--web` previews the web shape from a desktop debug build.
func previews_the_web() -> bool:
	return _web_preview

# ------------------------------------------------------------- what is placed ---

## `--spawn`'s raw target word, where she starts on the boot's first walk from her doorstep, or
## `""`.
func spawn_target() -> String:
	return _spawn_target

## The baby's bars `--meters` sets once the day runs (sleepiness, excitement), or `(-1, -1)`.
func meters_override() -> Vector2:
	return _meters_override

## **How this run plays every charger's warning and notice**: `--chargers`' (or `?chargers=`'s), or
## the shipped timing (`EventCatalogue.shipped_charger_timing()`). `main` builds the run's catalogue
## from it at boot (`EventCatalogue.for_run()`) and hands that down.
func charger_timing() -> ChargerTiming:
	if _charger_timing_override.x < 0.0:
		return EventCatalogue.shipped_charger_timing()
	return ChargerTiming.of(_charger_timing_override.x, _charger_timing_override.y)

## The row `--force` sends, or `""`.
func forced_row() -> String:
	return _forced_row

## The seconds `--force` waits between two forced rows.
func forced_interval() -> float:
	return _forced_interval

## Whether `--pelican` draws every cyclist the day sends as the pelican.
func draws_cyclists_as_the_pelican() -> bool:
	return _pelican

## Whether `--blackout` stands in for the last night's sabotage, for the blackout alone.
func asks_for_the_blackout() -> bool:
	return _blackout_requested

# ------------------------------------------------------------ how it is drawn ---

## The validated `--skip` words, read-only.
func skip_words() -> Array[String]:
	return _skip_words

## Whether `--skip events` leaves the events out.
func leaves_out_the_events() -> bool:
	return _skip_events

## Whether `--skip crowd` leaves the crowd out.
func leaves_out_the_crowd() -> bool:
	return _skip_crowd

## Whether `--skip shadows` leaves the buildings' shadows out.
func leaves_out_the_shadows() -> bool:
	return _skip_shadows

## Whether `--skip motion` leaves the crowd standing still.
func leaves_out_the_motion() -> bool:
	return _skip_motion

## The bag `--escape-bag` names for the escape's city, `DaySpec.DEFAULT_ESCAPE_BAG` when none is
## given: a name `DaySpec.for_section()` takes.
func escape_bag() -> String:
	return _escape_bag

## The least gap `--building-flash-gap` asks between two flashes of the escape building's windows,
## in seconds, `0` for none when it is not given.
func building_flash_gap() -> float:
	return _building_flash_gap

## The city's ground mode `--ground-mode` names (`DevFlags.GROUND_MODE_DEFAULT` when none is given),
## as the number `SceneryGround.Mode` takes.
func ground_mode() -> int:
	return _ground_mode

## The overlays `--layers` starts on, read-only; empty when none was given.
func layers_override() -> Array[int]:
	return _layers_override

## Whether `--player-view` asked for the frame a player sees.
func asks_for_the_player_view() -> bool:
	return _player_view_requested

## Whether `--overview` frames the whole city at once.
func asks_for_the_overview() -> bool:
	return _overview_requested

## The camera's zoom `--zoom` asks for, or `1.0`.
func zoom_override() -> float:
	return _zoom_override

## The event id `--follow` has the camera follow, or `""`.
func follow_target() -> String:
	return _follow_target

# --------------------------------------------------------------- measurement ---

## Whether `--spikes` asked for the run log's `spike` line and the frame graph.
func asks_for_spikes() -> bool:
	return _spikes_requested

## Whether `--frame-trace` asked for the frame trace.
func asks_for_a_frame_trace() -> bool:
	return _frame_trace_requested

## Whether `--frame-record` asked for the per-system frame record.
func asks_for_a_frame_record() -> bool:
	return _frame_record_requested

# ---------------------------------------------------------------------- rigs ---

## Whether this run is a rig rather than a person at the keyboard: a rig flag, a movie recording
## or a scripted recipe.
func runs_as_a_rig() -> bool:
	return _is_rig

## Whether Godot's own movie writer is recording this run.
func records_a_movie() -> bool:
	return _recording

## The `--route` targets the route rig walks, read-only; empty when none was given.
func route_targets() -> Array[String]:
	return _route_targets

## Where `--screenshot` saves its picture, or `""`.
func screenshot_path() -> String:
	return _screenshot_path

## `--after`'s value in seconds, or `-1.0` when not given.
func rig_after() -> float:
	return _rig_after

## Whether `--quit-when-still` is given at all, which is whether the still watch is built.
func quits_when_still() -> bool:
	return _quit_when_still_requested

## How long she stands still before `--quit-when-still` quits, in seconds.
func quit_when_still_seconds() -> float:
	return _quit_when_still_seconds

## How long `--zoom-out` takes to pull the camera out, in seconds, or `-1.0` for no zoom-out.
func zoom_out_seconds() -> float:
	return _zoom_out_seconds

## How long the zoom-out waits before it starts, in seconds.
func zoom_out_delay() -> float:
	return _zoom_out_delay

## `--caption`'s text, or `""`.
func caption_text() -> String:
	return _caption_text

## `--title-card`'s text, or `""`.
func title_card_text() -> String:
	return _title_card_text

# ------------------------------------------------------------- scene recipes ---

## `--recipe`'s path, or `""` for none.
func recipe_path() -> String:
	return _recipe_path

## Whether `--recipe-mode scripted` has the recipe play itself, as a rig.
func plays_the_recipe_scripted() -> bool:
	return _recipe_scripted

## Whether `--recipe-validate` quits once the recipe is installed and its manifest written.
func validates_the_recipe() -> bool:
	return _recipe_validate

## Where `--recipe-manifest` writes the recipe's manifest, or `""`.
func recipe_manifest_path() -> String:
	return _recipe_manifest_path

## Where `--recipe-draft` writes a drafted recipe, or `""` for none.
func recipe_draft_path() -> String:
	return _recipe_draft_path

# ------------------------------------------------------------- what it works out ---

## How long day `day` runs: `--day-length` when given, else the day's own (`Tuning.day_length()`).
## The one place a day's length is decided, handed to the day as a plain number.
func day_length_for(day: int) -> float:
	return _day_length_override if _day_length_override > 0.0 else Tuning.day_length(day)

## How long one escape section runs: a day's own clock, compressed by `--day-length` exactly as a
## day is, since each section is a day.
func escape_section_length() -> float:
	return _day_length_override if _day_length_override > 0.0 else FINALE_LENGTH_SECONDS

## Seconds until a rig quits itself: `--after` when given, else the length of the day it plays.
func rig_quit_seconds() -> float:
	return DevFlags.rig_quit_seconds_from(_rig_after, day_length_for(_day_override))

## Whether `AutoScreenshot` has a capture or a timed run to drive: a `--screenshot` path, or a
## frame trace, a frame record or a movie recording bounded by `--after`.
func screenshot_rig() -> bool:
	return _screenshot_path != "" \
			or ((_frame_trace_requested or _frame_record_requested or _recording)
				and "--after" in _active_args)

## Whether the boot goes straight into the day rather than opening the title: a recipe, which is
## one authored day, or a rig photographing or driving that day, unless `--title` asks for the
## title itself.
func skips_the_title() -> bool:
	if _recipe_path != "":
		return true
	return (screenshot_rig() or _no_title_requested) and not _title_requested

## Whether the boot warms the canvas shaders before the first frame. A recipe does not: its scene
## is installed and begun in the boot's own frame, with no awaited frame before it.
func warms_the_canvas_shaders() -> bool:
	return _recipe_path == ""

# ------------------------------------------------------------------- immutability ---

## Makes the arrays it hands out read-only once `parse()` has filled them, so no reader's edit of
## one reaches another reader.
func _freeze() -> void:
	_skip_words.make_read_only()
	_layers_override.make_read_only()
	_route_targets.make_read_only()
