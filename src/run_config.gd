class_name RunConfig
extends RefCounted
## The run's configuration: every developer flag and the page's query, resolved once at boot and
## never changed afterwards. Layer one, data and configuration: `main` resolves it
## (`at_boot()`), hands it to the observers (`Telemetry`, `GameSave`, `VisitCounter`) and to the
## dev rigs, and hands the simulation the plain values it needs out of it — a day's length, whether
## the clock stands still, whether a crowd is drawn — so nothing below `main` reads a flag, the
## command line or the address bar.
##
## **Immutable.** Every field is written once by `parse()` and then frozen: a later write is
## refused with a warning and leaves the value as it was, and the arrays are read-only. A test hands
## a component a config of its own by parsing the words it wants
## (`RunConfig.parse(PackedStringArray(["--invincible"]), "", true)`), never by changing one.
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

## What a refused write says. A warning rather than an error: a test can watch for it through a
## `Logger` without the engine's error line failing the run it is in.
const REFUSED := "RunConfig is resolved once at boot and never changes; a write was refused"

## Whether the fields may still be written. Declared first, so every setter below can read it.
var _open := true:
	set(value):
		if _open:
			_open = value
		elif value:
			push_warning(REFUSED)

## The words and the query this was parsed from, kept so `with_recipe()` can parse the same run
## again with a recipe on top, without asking the process or the page a second time.
var _given := PackedStringArray():
	set(value): _given = _write(_given, value)
var _movie := false:
	set(value): _movie = _write(_movie, value)

# ------------------------------------------------------------------ the gates ---

## The null display server a headless run boots against: no window, so no player, and the
## run never touches the player's save (`GameSave.uses_save()`). Read from the process once, at
## boot (`at_boot()`); a test that wants the saving of a windowed run parses `false`.
var headless := true:
	set(value): headless = _write(headless, value)
## A debug build: the gate on every command-line flag.
var debug_build := false:
	set(value): debug_build = _write(debug_build, value)
## `?debug=1` or `--debug`: the readout, and the gate on every release-safe query flag.
var readout_requested := false:
	set(value): readout_requested = _write(readout_requested, value)
## The release-safe bundle is open: a debug build, or a page that asked `?debug=1`.
var live_debug := false:
	set(value): live_debug = _write(live_debug, value)
## The page's query named one of the bundle's parameters while the bundle was open.
var web_debug_flag_used := false:
	set(value): web_debug_flag_used = _write(web_debug_flag_used, value)
## The page's query string as the browser gave it at boot, or "" off the web — for the few readers
## that parse a parameter of their own (`Telemetry`'s `?telemetry=1`, `WebDisplay`'s `?dpr=`).
var page_query := "":
	set(value): page_query = _write(page_query, value)
## The command line on a debug build, or nothing: every dev flag given, as words. Every read is a
## copy, since a packed array is shared by reference and a reader's edit would otherwise reach
## every other reader.
var active_args := PackedStringArray():
	get: return active_args.duplicate()
	set(value): active_args = _write(active_args, value)
## `--no-telemetry`, the player-facing opt-out, read on every build.
var no_telemetry := false:
	set(value): no_telemetry = _write(no_telemetry, value)

# ------------------------------------------------------------------ the run ---

var seed_override := 0:
	set(value): seed_override = _write(seed_override, value)
var day_override := 1:
	set(value): day_override = _write(day_override, value)
## `-1.0` for "not given"; see `day_length_for()`.
var day_length_override := -1.0:
	set(value): day_length_override = _write(day_length_override, value)
var parent_override := "":
	set(value): parent_override = _write(parent_override, value)
var hard_mode_requested := false:
	set(value): hard_mode_requested = _write(hard_mode_requested, value)
var nerves_override := 0:
	set(value): nerves_override = _write(nerves_override, value)
var invincible := false:
	set(value): invincible = _write(invincible, value)
var start_escape := false:
	set(value): start_escape = _write(start_escape, value)
var start_escape_at := "":
	set(value): start_escape_at = _write(start_escape_at, value)
var ending_override := "":
	set(value): ending_override = _write(ending_override, value)
var controls_word := "":
	set(value): controls_word = _write(controls_word, value)
var no_save := false:
	set(value): no_save = _write(no_save, value)
var no_focus_pause := false:
	set(value): no_focus_pause = _write(no_focus_pause, value)
var title_requested := false:
	set(value): title_requested = _write(title_requested, value)
var no_title_requested := false:
	set(value): no_title_requested = _write(no_title_requested, value)
## `--touch`: the touch hardware question answers yes (`TouchInput.available()`).
var touch_forced := false:
	set(value): touch_forced = _write(touch_forced, value)
## `--web`: the quit question answers as the web export does (`QuitOption.available()`).
var web_preview := false:
	set(value): web_preview = _write(web_preview, value)

# ------------------------------------------------------------- what is placed ---

var spawn_target := "":
	set(value): spawn_target = _write(spawn_target, value)
var meters_override := Vector2(-1.0, -1.0):
	set(value): meters_override = _write(meters_override, value)
var forced_row := "":
	set(value): forced_row = _write(forced_row, value)
var forced_interval := 0.0:
	set(value): forced_interval = _write(forced_interval, value)
var pelican := false:
	set(value): pelican = _write(pelican, value)
var blackout_requested := false:
	set(value): blackout_requested = _write(blackout_requested, value)

# ------------------------------------------------------------ how it is drawn ---

## The validated `--skip` words; the four booleans below are the same set, read once.
var skip_words: Array[String] = []:
	set(value): skip_words = _write(skip_words, value)
var skip_events := false:
	set(value): skip_events = _write(skip_events, value)
var skip_crowd := false:
	set(value): skip_crowd = _write(skip_crowd, value)
var skip_shadows := false:
	set(value): skip_shadows = _write(skip_shadows, value)
var skip_motion := false:
	set(value): skip_motion = _write(skip_motion, value)
var ground_mode := DevFlags.GROUND_MODE_DEFAULT:
	set(value): ground_mode = _write(ground_mode, value)
var layers_override: Array[int] = []:
	set(value): layers_override = _write(layers_override, value)
var player_view_requested := false:
	set(value): player_view_requested = _write(player_view_requested, value)
var overview_requested := false:
	set(value): overview_requested = _write(overview_requested, value)
var zoom_override := 1.0:
	set(value): zoom_override = _write(zoom_override, value)
var follow_target := "":
	set(value): follow_target = _write(follow_target, value)

# --------------------------------------------------------------- measurement ---

var spikes_requested := false:
	set(value): spikes_requested = _write(spikes_requested, value)
var frame_trace_requested := false:
	set(value): frame_trace_requested = _write(frame_trace_requested, value)
var frame_record_requested := false:
	set(value): frame_record_requested = _write(frame_record_requested, value)

# ---------------------------------------------------------------------- rigs ---

## A rig rather than a person: a rig flag, a movie recording, or a scripted recipe.
var is_rig := false:
	set(value): is_rig = _write(is_rig, value)
## Godot's own movie writer is recording this run.
var recording := false:
	set(value): recording = _write(recording, value)
var route_targets: Array[String] = []:
	set(value): route_targets = _write(route_targets, value)
var screenshot_path := "":
	set(value): screenshot_path = _write(screenshot_path, value)
## `--after`'s value, or `-1.0`.
var rig_after := -1.0:
	set(value): rig_after = _write(rig_after, value)
var quit_when_still_requested := false:
	set(value): quit_when_still_requested = _write(quit_when_still_requested, value)
var quit_when_still_seconds := 1.0:
	set(value): quit_when_still_seconds = _write(quit_when_still_seconds, value)
var zoom_out_seconds := -1.0:
	set(value): zoom_out_seconds = _write(zoom_out_seconds, value)
var zoom_out_delay := 0.0:
	set(value): zoom_out_delay = _write(zoom_out_delay, value)
var caption_text := "":
	set(value): caption_text = _write(caption_text, value)
var title_card_text := "":
	set(value): title_card_text = _write(title_card_text, value)

# ------------------------------------------------------------- scene recipes ---

var recipe_path := "":
	set(value): recipe_path = _write(recipe_path, value)
var recipe_scripted := false:
	set(value): recipe_scripted = _write(recipe_scripted, value)
var recipe_validate := false:
	set(value): recipe_validate = _write(recipe_validate, value)
var recipe_manifest_path := "":
	set(value): recipe_manifest_path = _write(recipe_manifest_path, value)
var recipe_draft_path := "":
	set(value): recipe_draft_path = _write(recipe_draft_path, value)

# ------------------------------------------------------------------- resolving ---

## The process's own configuration, resolved on the first call from the real command line and the
## one read of the page's query, and the same object on every call after: a scene reload is not a
## second boot.
static var _at_boot: RunConfig

static func at_boot() -> RunConfig:
	if _at_boot == null:
		_at_boot = parse(OS.get_cmdline_user_args(), DevFlags.page_query(), OS.is_debug_build(),
				OS.has_feature("movie"), {}, DisplayServer.get_name() == "headless")
	return _at_boot

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
	config.debug_build = debug_build
	config.headless = headless_display
	config.readout_requested = flags.readout_requested()
	config.live_debug = flags.live_debug_requested()
	config.web_debug_flag_used = flags.web_debug_flag_used()
	config.page_query = query
	config.active_args = flags.active_args()
	config.no_telemetry = flags.no_telemetry()

	config.seed_override = flags.seed_override()
	config.day_override = flags.day_override()
	config.day_length_override = flags.day_length_override()
	config.parent_override = flags.parent_override()
	config.hard_mode_requested = flags.hard_mode_requested()
	config.nerves_override = flags.nerves_override()
	config.invincible = flags.invincible()
	config.start_escape = flags.start_escape()
	config.start_escape_at = flags.start_escape_at()
	config.ending_override = flags.ending_override()
	config.controls_word = flags.controls_word()
	config.no_save = flags.no_save()
	config.no_focus_pause = flags.no_focus_pause()
	config.title_requested = flags.title_requested()
	config.no_title_requested = flags.no_title_requested()
	config.touch_forced = flags.touch_forced()
	config.web_preview = flags.web_preview()

	config.spawn_target = flags.spawn_target()
	config.meters_override = flags.meters_override()
	config.forced_row = flags.forced_row()
	config.forced_interval = flags.forced_interval()
	config.pelican = flags.pelican()
	config.blackout_requested = flags.blackout_requested()

	var skip := flags.skip_words()
	config.skip_words = skip
	config.skip_events = "events" in skip
	config.skip_crowd = "crowd" in skip
	config.skip_shadows = "shadows" in skip
	config.skip_motion = "motion" in skip
	config.ground_mode = flags.ground_mode()
	config.layers_override = flags.layers_override()
	config.player_view_requested = flags.player_view_requested()
	config.overview_requested = flags.overview_requested()
	config.zoom_override = flags.zoom_override()
	config.follow_target = flags.follow_target()

	config.spikes_requested = flags.spikes_requested()
	config.frame_trace_requested = flags.frame_trace_requested()
	config.frame_record_requested = flags.frame_record_requested()

	config.is_rig = flags.is_rig()
	config.recording = flags.recording()
	config.route_targets = flags.route_targets()
	config.screenshot_path = flags.screenshot_path()
	config.rig_after = flags.rig_after()
	config.quit_when_still_requested = flags.quit_when_still_requested()
	config.quit_when_still_seconds = flags.quit_when_still_seconds()
	config.zoom_out_seconds = flags.zoom_out_seconds()
	config.zoom_out_delay = flags.zoom_out_delay()
	config.caption_text = flags.caption_text()
	config.title_card_text = flags.title_card_text()

	config.recipe_path = flags.recipe_path()
	config.recipe_scripted = flags.recipe_scripted()
	config.recipe_validate = flags.recipe_validate()
	config.recipe_manifest_path = flags.recipe_manifest_path()
	config.recipe_draft_path = flags.recipe_draft_path()
	config._freeze()
	return config

## This run with a loaded recipe's data on top: the recipe's seed, day, escape part and parent in
## place of the flags' own. Parsed again from the same words and query, never from the process.
func with_recipe(recipe_data: Dictionary) -> RunConfig:
	return parse(_given, page_query, debug_build, _movie, recipe_data, headless)

# --------------------------------------------------------------- what follows ---

## How long day `day` runs: `--day-length` when given, else the day's own (`Tuning.day_length()`).
## The one place a day's length is decided, handed to the day as a plain number.
func day_length_for(day: int) -> float:
	return day_length_override if day_length_override > 0.0 else Tuning.day_length(day)

## How long one escape section runs: a day's own clock, compressed by `--day-length` exactly as a
## day is, since each section is a day.
func escape_section_length() -> float:
	return day_length_override if day_length_override > 0.0 else FINALE_LENGTH_SECONDS

## Seconds until a rig quits itself: `--after` when given, else the length of the day it plays.
func rig_quit_seconds() -> float:
	return DevFlags.rig_quit_seconds_from(rig_after, day_length_for(day_override))

## Whether `AutoScreenshot` has a capture or a timed run to drive: a `--screenshot` path, or a
## frame trace, a frame record or a movie recording bounded by `--after`.
func screenshot_rig() -> bool:
	return screenshot_path != "" \
			or ((frame_trace_requested or frame_record_requested or recording)
				and "--after" in active_args)

## Whether the boot goes straight into the day rather than opening the title: a recipe, which is
## one authored day, or a rig photographing or driving that day, unless `--title` asks for the
## title itself.
func skips_the_title() -> bool:
	if recipe_path != "":
		return true
	return (screenshot_rig() or no_title_requested) and not title_requested

## Whether the boot warms the canvas shaders before the first frame. A recipe does not: its scene
## is installed and begun in the boot's own frame, with no awaited frame before it.
func warms_the_canvas_shaders() -> bool:
	return recipe_path == ""

# ------------------------------------------------------------------- immutability ---

## What a setter stores: `value` while `parse()` is filling the fields in, and `current` once it
## has finished, with the refusal said loudly.
func _write(current: Variant, value: Variant) -> Variant:
	if _open:
		return value
	push_warning(REFUSED)
	return current

func _freeze() -> void:
	skip_words.make_read_only()
	layers_override.make_read_only()
	route_targets.make_read_only()
	_open = false
