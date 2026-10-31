class_name DevFlags
extends RefCounted
## The parser behind `RunConfig`: every developer flag, read from a command line and a page query
## handed in, never from the process itself. `RunConfig.at_boot()` builds one of these once, from
## the real command line and the one read of the page's query (`page_query()`), and keeps the
## answers; nothing else in the game constructs one or asks the process for a flag.
##
## **The command-line half answers only on a debug build.** `debug_build` is false for an exported
## release template, which is what `tools/export-web.sh` produces, so every getter here answers
## "not given" there whatever the command line says: a public build cannot be made to jump to a
## day or write a screenshot by flags nobody documented for a player. Two smaller sets answer to a
## release page too, behind its own `?debug=1` (`readout_requested()`): the readout itself with
## `?skip=` and `?seed=`, and the bundle `live_debug_requested()` opens, the flags that choose where
## a run starts or how it is drawn and never one that drives input or takes a picture (M193, the
## live page's ?debug=1 reaches the debug flags).
##
## **`--no-telemetry` answers on every build.** It is a documented player-facing opt-out (see
## docs/TELEMETRY.md), not developer furniture, so `no_telemetry()` reads the ungated command line.
## `AutoScreenshot.from_config()` parses `--screenshot`, `--after`, `--walk`, `--smooth-walk`,
## `--flee`, `--press` and `--tap` itself, from the gated words this hands it.
##
## **The table below is the one manifest of the whole surface, even the half parsed elsewhere.**
## `tools/run.sh` and `tools/shot.sh` forward whatever a caller gives them straight to the game
## as a dev flag (see the **cli-tools** skill), so they reject a typo before spending a Godot
## launch on it, reading this table out of this file the way `tools/lib_dev_flags.sh` does. Each
## row is `<flag> <arity>`: arity is the exact count of words the flag always consumes, `?` marks
## one more consumed only when it looks like a number, `w?` marks one more consumed only when it
## does not itself start with `--` (`--start-escape`'s own target word), and `*` marks a flag that
## may repeat (`--press` only, two words each time). A flag the game reads without a row here is
## invisible to the shell tools and rejected by them as unknown.
##
## DEV_FLAG_TABLE
##   --seed          1
##   --day           1
##   --day-length    1
##   --meters        2
##   --spawn         1
##   --follow        1
##   --route         1
##   --force         1?
##   --pelican       0
##   --overview      0
##   --zoom          1
##   --start-escape  0w?
##   --blackout      0
##   --ground-mode   1
##   --ending        1
##   --controls      1
##   --layers        1
##   --debug         0
##   --skip          1
##   --invincible    0
##   --no-focus-pause 0
##   --no-save       0
##   --spikes        0
##   --frame-trace   0
##   --frame-record  0
##   --no-telemetry  0
##   --screenshot    1
##   --after         1
##   --walk          1
##   --smooth-walk   0
##   --flee          0?
##   --press         2*
##   --tap           2
##   --touch         0
##   --web           0
##   --title         0
##   --no-title      0
##   --quit-when-still 0?
##   --player-view   0
##   --parent        1
##   --hard          0
##   --nerves        1
##   --zoom-out      1?
##   --caption       1
##   --title-card    1
##   --recipe        1
##   --recipe-mode   1
##   --recipe-validate 0
##   --recipe-manifest 1
##   --recipe-draft  1
## END_DEV_FLAG_TABLE
##
## Which of the flags above mark a run as a **rig** rather than a person at the keyboard: the ones
## that supply the input themselves. A run Godot's own movie writer records (`--write-movie`, which
## `tools/record.sh` and `tools/trailer.sh` launch with) and a scripted scene recipe are rigs too,
## whatever their flags — see `is_rig()`. `tools/lib_dev_flags.sh`'s own `rig_flag_present()` reads
## this exact block, so the shell's decision to strip a window's focus, disable vsync, gate input
## and enforce the wall-clock limit names the same set of flags the game locks real input out for;
## `_RIG_FLAGS` below is the GDScript spelling of it. A plain `tools/run.sh` session, with no flag
## on this list, is a person's and is untouched by any of it.
##
## RIG_FLAGS
##   --screenshot
##   --walk
##   --flee
##   --press
##   --tap
##   --route
## END_RIG_FLAGS
##
## The numbers `rig_quit_seconds_from()` below turns into a rig's own deadline, read by the same
## shell helper (`tools/lib_dev_flags.sh`) so an external kill (`RIG_KILL_GRACE_SECONDS` past the
## deadline) can never compute a shorter wait than the deadline the game itself is timing against.
## See `rig_quit_seconds_from()`'s own doc for what each name means, and `RIG_MOVIE_SLOWDOWN` for
## `movie_slowdown`.
##
## RIG_QUIT_SECONDS
##   margin 15.0
##   ceiling 240.0
##   kill_grace 15.0
##   movie_slowdown 10.0
## END_RIG_QUIT_SECONDS

## The command line as given, every word, gated or not — read directly only for the flags that
## answer on a release build (`--debug`, `--skip`, `--no-telemetry`).
var _given := PackedStringArray()
## The page's query string (`window.location.search`), or "" off the web.
var _query := ""
## Whether this is a debug build, the gate on the command-line half.
var _debug_build := false
## Whether Godot's own movie writer is recording this run (`OS.has_feature("movie")`).
var _movie := false
## A loaded scene recipe's data, or `{}`. Its seed, day, escape part and parent stand in for the
## flags' own, since a recipe is a whole authored setup rather than a set of overrides.
var _recipe := {}

func _init(args: PackedStringArray, query: String, debug_build: bool, movie := false,
		recipe: Dictionary = {}) -> void:
	_given = args.duplicate()
	_query = query
	_debug_build = debug_build
	_movie = movie
	_recipe = recipe if debug_build else {}

## The page's own query string, read through `JavaScriptBridge` — the one read of the address bar
## the game makes, at boot, by `RunConfig.at_boot()`. "" outside a Web export.
static func page_query() -> String:
	if OS.get_name() != "Web":
		return ""
	var search: Variant = JavaScriptBridge.eval("window.location.search")
	return search as String if search is String else ""

## Whether the command-line half is readable at all: a debug build. A release build answers no
## flag of that half from anywhere, so the entry point to it stays what it is: run a debug build
## (2026-09-06, the player: "for dev you need it to be controllable from the getgo -- for release
## there should be no modifiers").
func enabled() -> bool:
	return _debug_build

## The command line, or nothing at all outside a debug build — the one choke point every gated
## getter below reads through, and what `RunConfig.active_args` keeps.
func active_args() -> PackedStringArray:
	return _given if _debug_build else PackedStringArray()

## Whether the developer readout was asked for — `?debug=1` or `--debug`, read without `enabled()`'s
## gate. It shows the readout on a release page and gates every other release-safe query flag in
## turn: `?skip=` (`skip_words()`), `?seed=`'s positive integer (`seed_override()`), and the bundle
## `live_debug_requested()` opens. `Telemetry`'s own `?telemetry=1` is not part of any of this: it
## stays behind the debug build alone (docs/TELEMETRY.md), since a stranger's browser collecting a
## trace is a different question from a stranger's browser reading a day number back.
func readout_requested() -> bool:
	return _readout_from_args(_given) or _readout_from_query(_query)

static func _readout_from_args(args: PackedStringArray) -> bool:
	return "--debug" in args

static func _readout_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "debug" and pair[1] == "1":
			return true
	return false

## The gate for the release-safe bundle: the flags that choose where a run starts or how it is
## drawn (`day_override()`, `invincible()`, `layers_override()`, `controls_word()`,
## `start_escape()`, `meters_override()`, `day_length_override()`, `ending_override()`,
## `blackout_requested()`, `ground_mode()`, `frame_record_requested()`, and `WebDisplay`'s `?dpr=`)
## — never the input-driving or picture-taking half, and no file but the frame record's, which
## leaves only through the browser's download when the player taps its page button. Open on a
## debug build whatever the page says, and on a release page once `readout_requested()` holds,
## so a release page nobody asked `?debug=1` of reads exactly as an ordinary one.
func live_debug_requested() -> bool:
	return _live_debug_requested(enabled(), readout_requested())

## The decision behind `live_debug_requested()`, pure in its two inputs so the promise is a truth
## table a test can check.
static func _live_debug_requested(is_debug: bool, readout: bool) -> bool:
	return is_debug or readout

## The query parameter names `live_debug_requested()`'s bundle answers to. `GameSave.uses_save()`
## reads `web_debug_flag_used()` against this list, so a release page's visitor who typed one of
## these never touches the save a real player's page shares, as against `?debug=1` alone, which
## opens the bundle without using any of it.
const _LIVE_DEBUG_QUERY_KEYS := [
	"day", "invincible", "layers", "controls", "escape", "meters", "daylength", "ending",
	"blackout", "groundmode", "framerecord",
]

## Whether the page's query named one of `live_debug_requested()`'s parameters while the bundle is
## open, as against merely being allowed to. `false` on a release page nobody asked `?debug=1` of,
## and off the web.
func web_debug_flag_used() -> bool:
	if not live_debug_requested():
		return false
	return _web_debug_flag_used_in_query(_query)

static func _web_debug_flag_used_in_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() >= 1 and pair[0] in _LIVE_DEBUG_QUERY_KEYS:
			return true
	return false

## `--no-telemetry`, the player-facing opt-out: read on every build. See the class doc.
func no_telemetry() -> bool:
	return "--no-telemetry" in _given

## The words `--skip`/`?skip=` may name: one per measured cost a phone frame reading can rule out
## (M124's desktop rows and M139's crowd motion). One place, so `_validate_skip_words()` and
## `RunConfig`'s four booleans cannot spell the set differently.
const _SKIP_KNOWN_WORDS := ["events", "crowd", "shadows", "motion"]

## The validated `--skip`/`?skip=` words, read without `enabled()`'s gate but **honoured only while
## `readout_requested()` holds**, so a release page without the DEBUG MODE note never skips
## anything. `events` stops every `EventInstance` drawing, `crowd` every `CrowdAgent`, `shadows`
## the building shadows, and `motion` the crowd's own ticks; nothing else moves, so a frame reading
## differs from an ordinary run by the drawing and motion named and nothing more.
func skip_words() -> Array[String]:
	if not readout_requested():
		return []
	var raw := _skip_from_args(_given)
	if raw == "":
		raw = _skip_from_query(_query)
	return _validate_skip_words(raw)

static func _skip_from_args(args: PackedStringArray) -> String:
	var index := args.find("--skip")
	if index == -1 or index + 1 >= args.size():
		return ""
	return args[index + 1]

static func _skip_from_query(query: String) -> String:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "skip":
			return pair[1]
	return ""

## The bare parsing of a `--skip`/`?skip=` value into its words. An empty value is nothing to skip.
## Any word this flag does not know refuses the **whole** value with `push_warning`: a skip that
## silently dropped an unrecognised word would measure a different frame than the one asked for
## and say nothing about it.
static func _validate_skip_words(raw: String) -> Array[String]:
	if raw == "":
		return []
	var words: Array[String] = []
	for word in raw.split(","):
		if not word in _SKIP_KNOWN_WORDS:
			push_warning("--skip: unknown word '%s', ignoring the whole flag" % word)
			return []
		if not word in words:
			words.append(word)
	return words

## `--seed N` regenerates a specific city, so a layout bug can be looked at twice: the command line
## is unbounded and unvalidated, and wins when present. Failing that, the page's own `?seed=N`
## fills in wherever `readout_requested()` holds, and only for a positive integer. `0` is "not
## given", which is also the game's own fresh seed per run. A recipe's seed wins over both.
func seed_override() -> int:
	if not _recipe.is_empty():
		return int(_recipe.get("seed", 1))
	var args := active_args()
	var index := args.find("--seed")
	if index != -1 and index + 1 < args.size():
		return int(args[index + 1])
	return _seed_from_query(_query)

## The bare parsing of `?seed=`, with its `?debug=1` gate read from the same query: a present seed
## that is not a positive integer is refused with `push_warning`; an absent one says nothing, so an
## ordinary `?debug=1` page does not warn on every load.
static func _seed_from_query(query: String) -> int:
	if not _readout_from_query(query):
		return 0
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() != 2 or pair[0] != "seed":
			continue
		if pair[1].is_valid_int() and int(pair[1]) > 0:
			return int(pair[1])
		push_warning("?seed: '%s' is not a positive integer, ignoring" % pair[1])
		return 0
	return 0

## `--day N` (or `?day=N` in the open bundle) starts on a later day, clamped into the run. `1` is
## the default. A recipe's own day wins.
func day_override() -> int:
	if not _recipe.is_empty():
		return int(_recipe.get("setup", {}).get("day", 1))
	var args := active_args()
	var index := args.find("--day")
	if index != -1 and index + 1 < args.size():
		return clampi(int(args[index + 1]), 1, Tuning.RUN_LENGTH_DAYS)
	if live_debug_requested():
		var from_query := _day_from_query(_query)
		if from_query != -1:
			return from_query
	return 1

## The bare parsing of `?day=`, clamped the way `--day` is. `-1` is "not given", since `1` is both a
## valid day and the default.
static func _day_from_query(query: String) -> int:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "day":
			return clampi(int(pair[1]), 1, Tuning.RUN_LENGTH_DAYS)
	return -1

## `--spawn <target>`, the raw word, or "". What a target means reads the live `City`, so that
## lookup is `DevRig.for_spawn_target()`'s.
func spawn_target() -> String:
	return _word_after("--spawn")

## `--follow <event id>`, the raw id, or "".
func follow_target() -> String:
	return _word_after("--follow")

## `--route mark,task,calm,home`, the ordered target words `RouteRig` walks to in turn, split on
## commas with nothing else validated: the live `City` decides what a word means, so an unknown one
## is `RouteRig`'s own warning. `[]` for an absent flag or an empty value: no rig.
func route_targets() -> Array[String]:
	var result: Array[String] = []
	for word in _word_after("--route").split(","):
		if word != "":
			result.append(word)
	return result

## `--force <event id> [seconds]`, the raw id, or "". **The flag for checking one row rather than one
## city**: the director hands out that row and nothing else, refilled as fast as it is spent, every
## `forced_interval()` seconds. It bypasses `first_day` and the day's budget on purpose: the
## question is what the row does when it reaches her. `--seed` and `--day` still decide the city and
## the act, so everything around the row is the ordinary game.
func forced_row() -> String:
	return _word_after("--force")

## Seconds between two forced rows — `--force`'s optional second word when it is a number, else
## `_FORCED_INTERVAL_DEFAULT`, never below half a second.
func forced_interval() -> float:
	var args := active_args()
	var index := args.find("--force")
	if index == -1 or index + 2 >= args.size():
		return _FORCED_INTERVAL_DEFAULT
	var word := args[index + 2]
	if not word.is_valid_float():
		return _FORCED_INTERVAL_DEFAULT
	return maxf(float(word), 0.5)

## Short, so the same encounter is seen several times without walking a day for each, and long
## enough that two are never on screen together: a `cyclist` is warned for a second, reaches her
## under a second later at 257px/s and is out of sight a second or so after that.
const _FORCED_INTERVAL_DEFAULT := 6.0

## `--pelican`: every cyclist the day sends is drawn as the pelican, so the drawing can be looked at
## on demand. A picture only: the riders, their warnings and their fields are the run's own.
func pelican() -> bool:
	return "--pelican" in active_args()

## `--meters <sleepiness> <excitement>` (or `?meters=sleepiness,excitement` in the open bundle),
## clamped into range, or `(-1, -1)` for "not given". It only seeds `Baby`'s starting numbers.
func meters_override() -> Vector2:
	var args := active_args()
	var index := args.find("--meters")
	if index != -1 and index + 2 < args.size():
		return Vector2(
				clampf(float(args[index + 1]), 0.0, Tuning.METER_MAX),
				clampf(float(args[index + 2]), 0.0, Tuning.METER_MAX))
	if live_debug_requested():
		return _meters_from_query(_query)
	return Vector2(-1.0, -1.0)

## The bare parsing of `?meters=`: anything but two comma-separated numbers refuses the whole value
## with `push_warning`.
static func _meters_from_query(query: String) -> Vector2:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() != 2 or pair[0] != "meters":
			continue
		var words := pair[1].split(",")
		if words.size() == 2 and words[0].is_valid_float() and words[1].is_valid_float():
			return Vector2(
					clampf(float(words[0]), 0.0, Tuning.METER_MAX),
					clampf(float(words[1]), 0.0, Tuning.METER_MAX))
		push_warning("?meters: '%s' is not two comma-separated numbers, ignoring" % pair[1])
		return Vector2(-1.0, -1.0)
	return Vector2(-1.0, -1.0)

## `--overview` frames the whole city at once.
func overview_requested() -> bool:
	return "--overview" in active_args()

## `--blackout` (or `?blackout=1` in the open bundle) stands in for the last night's sabotage, for
## the blackout alone: `Blackout` goes dark the moment she is `Tuning.BLACKOUT_DISTANCE` from the
## power station, on whatever day is running. No task, ending or save sees a sabotage, which keeps
## it a way to photograph the moment rather than a way to reach the good ending.
func blackout_requested() -> bool:
	if "--blackout" in active_args():
		return true
	if not live_debug_requested():
		return false
	return _blackout_from_query(_query)

static func _blackout_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "blackout" and pair[1] == "1":
			return true
	return false

## `--ground-mode 1|2|3` (or `?groundmode=` in the open bundle): how a needed nearby ground region
## is scheduled, as `SceneryGround.Mode` numbers it — `1` every needed region whole in its frame
## under the soft budget, `2` (the default) at most one whole region a frame, `3` one region spread
## across frames (2026-10-03, tawny-stork; mode 2 the default after a phone test, inbox #510 in
## quiet-yak: "mode 2 felt to have the fewest stutters"). It chooses how the ground is drawn, not
## what is drawn.
func ground_mode() -> int:
	return _ground_mode_for(active_args(), _query, live_debug_requested())

## `ground_mode()`'s own decision, pure in its three inputs: the command line wins, the page is
## read only while the bundle is open, and `2` answers everything else.
static func _ground_mode_for(args: PackedStringArray, query: String, flags_open: bool) -> int:
	var index := args.find("--ground-mode")
	if index != -1 and index + 1 < args.size():
		return parse_ground_mode(args[index + 1])
	if not flags_open:
		return GROUND_MODE_DEFAULT
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "groundmode":
			return parse_ground_mode(pair[1])
	return GROUND_MODE_DEFAULT

const GROUND_MODE_DEFAULT := 2

## The bare parsing of a `--ground-mode`/`?groundmode=` value. Anything but `1`, `2` or `3` refuses
## the whole flag with `push_warning` and answers the default: a measurement of a mode nobody asked
## for that said nothing about it would compare the wrong thing.
static func parse_ground_mode(raw: String) -> int:
	if raw in ["1", "2", "3"]:
		return int(raw)
	push_warning("--ground-mode: '%s' is not 1, 2 or 3, ignoring the flag" % raw)
	return GROUND_MODE_DEFAULT

## `--start-escape` (or `?escape=1` in the open bundle) skips the title and a day's city and starts
## `main` straight in the escape, whose two sections are days of their own: none of an ordinary
## day's events and no crowd. A recipe of kind `escape` does the same.
func start_escape() -> bool:
	if not _recipe.is_empty():
		return _recipe.get("kind", "city") == "escape"
	if "--start-escape" in active_args():
		return true
	if not live_debug_requested():
		return false
	return _escape_from_query(_query)

static func _escape_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "escape" and pair[1] == "1":
			return true
	return false

## `--start-escape`'s own optional word — `stairwell:left`, `stairwell:right`, `lobby`, `basement`,
## `floor:N` or `city` — so a rig or a person can start anywhere in the escape: the six part words
## choose where in the building she starts, and `city` boots the escape's second section with no
## building built. "" for a bare flag (her own door on the third floor) or none; mapping the word
## onto an `InteriorMap.PARTS` name is `main.escape_part_for()`'s. Read only right after
## `--start-escape`, and never a word that starts with `--`, so the next flag is not swallowed.
func start_escape_at() -> String:
	if not _recipe.is_empty():
		return str(_recipe.get("setup", {}).get("progression", {}).get("escape_part", "city"))
	var word := _word_after("--start-escape")
	return "" if word.begins_with("--") else word

## `--day-length N` (or `?daylength=N` in the open bundle) compresses every day and every escape
## section to `N` seconds, so dusk and the timeout loss can be looked at without the whole three
## minutes. `-1.0` is "not given"; `RunConfig.day_length_for()` falls back to the day's own.
func day_length_override() -> float:
	var args := active_args()
	var index := args.find("--day-length")
	if index != -1 and index + 1 < args.size():
		return maxf(1.0, float(args[index + 1]))
	if live_debug_requested():
		var from_query := _day_length_from_query(_query)
		if from_query > 0.0:
			return from_query
	return -1.0

## The bare parsing of `?daylength=`: anything that is not a positive number refuses the whole value
## with `push_warning`.
static func _day_length_from_query(query: String) -> float:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() != 2 or pair[0] != "daylength":
			continue
		if pair[1].is_valid_float() and float(pair[1]) > 0.0:
			return maxf(1.0, float(pair[1]))
		push_warning("?daylength: '%s' is not a positive number, ignoring" % pair[1])
		return -1.0
	return -1.0

## `--zoom <factor>`: the gameplay camera's zoom relative to its normal one, so `0.5` shows twice as
## much of the world each way with everything else exactly as a player sees it. `1.0` is "not
## given".
func zoom_override() -> float:
	var args := active_args()
	var index := args.find("--zoom")
	if index == -1 or index + 1 >= args.size():
		return 1.0
	return parse_zoom(args[index + 1])

## The bare parsing of a `--zoom` value. Anything that is not a positive number refuses the whole
## flag, a warning and the normal zoom, rather than being clamped into one: a capture at a zoom
## nobody asked for is a picture of the wrong thing that says nothing about it.
static func parse_zoom(raw: String) -> float:
	if not raw.is_valid_float() or float(raw) <= 0.0:
		push_warning("--zoom: '%s' is not a positive number, ignoring the flag" % raw)
		return 1.0
	return float(raw)

## `--ending bad|neutral|good` (or `?ending=` in the open bundle), the raw word, or "". Mapping it
## onto `GameEnums.Ending` is `main._show_an_ending_for_a_rig()`'s. The screen is drawn over a day
## already running: it neither ends nor saves a run.
func ending_override() -> String:
	var args := active_args()
	var index := args.find("--ending")
	if index != -1 and index + 1 < args.size():
		return args[index + 1]
	if live_debug_requested():
		return _ending_from_query(_query)
	return ""

static func _ending_from_query(query: String) -> String:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "ending":
			return pair[1]
	return ""

## `--controls joystick|joystick-left|joystick-right|tap` (or `?controls=` in the open bundle), the
## raw word, or "". `ControlsMode.from_word()` and `side_from_word()` say what it means.
func controls_word() -> String:
	var args := active_args()
	var index := args.find("--controls")
	if index != -1 and index + 1 < args.size():
		return args[index + 1]
	if not live_debug_requested():
		return ""
	return _controls_from_query(_query)

static func _controls_from_query(query: String) -> String:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "controls":
			return pair[1]
	return ""

## `--layers 1,3` (or `?layers=1,3` in the open bundle): which of the debug layers start on, so a
## rig screenshot of a particular disagreement is reproducible without a keypress — `1`-`3` are
## `DebugLayers`' geometry, `5` the day's routes (`RouteLines`) and `6` the spike view
## (`FrameGraph`). `4`, the readout, defaults on already and is not part of this list.
func layers_override() -> Array[int]:
	var args := active_args()
	var index := args.find("--layers")
	if index != -1 and index + 1 < args.size():
		return parse_layers(args[index + 1])
	if not live_debug_requested():
		return []
	return parse_layers(_layers_from_query(_query))

## The bare parsing of a `--layers`/`?layers=` value into layer indices. A malformed entry (not a
## number, or outside the valid indices, `4` included) is dropped with a warning rather than
## failing the whole flag: a rig's one typo should not turn off the layers it did ask for.
static func parse_layers(raw: String) -> Array[int]:
	var result: Array[int] = []
	if raw == "":
		return result
	for word in raw.split(","):
		if not word.is_valid_int():
			push_warning("--layers: ignoring non-numeric entry '%s'" % word)
			continue
		var n := int(word)
		if n < 1 or n > 6 or n == 4:
			push_warning("--layers: ignoring out-of-range entry '%d'" % n)
			continue
		if not n in result:
			result.append(n)
	return result

static func _layers_from_query(query: String) -> String:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "layers":
			return pair[1]
	return ""

## `--invincible` (or `?invincible=1` in the open bundle): nothing ends the day but a win, the day
## clock stands still and nothing adds to the excitement meter, though decay may still run it down
## — so a capture waiting for a moment gets quiet held time rather than a flashing alarm and a
## darkening day (2026-09-11, the player: "when invincible the timer should never go down and
## excitement should never go up"). `DayController.invincible` and `Baby.excitement_frozen` are the
## two values the run hands it to.
func invincible() -> bool:
	if _invincible_from_args(active_args()):
		return true
	if not live_debug_requested():
		return false
	return _invincible_from_query(_query)

static func _invincible_from_args(args: PackedStringArray) -> bool:
	return "--invincible" in args

static func _invincible_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "invincible" and pair[1] == "1":
			return true
	return false

## `--no-focus-pause` (or `?nofocuspause=1`, a debug web build only) turns off the pause the window
## losing focus opens — see `ReturnWindow` and `main._pause_on_focus_lost()`. **`--screenshot` implies it**: a screenshot
## rig's window opens behind whatever the operator is doing, so a game that paused on that would
## photograph the pause screen rather than the day it was asked to capture. Whether the game can be
## walked away from behind another window stays a developer question, so this is the debug build's
## alone, query included.
func no_focus_pause() -> bool:
	if not enabled():
		return false
	return _no_focus_pause_from_args(active_args()) or _no_focus_pause_from_query(_query)

static func _no_focus_pause_from_args(args: PackedStringArray) -> bool:
	return "--no-focus-pause" in args or "--screenshot" in args

static func _no_focus_pause_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "nofocuspause" and pair[1] == "1":
			return true
	return false

## `--no-save` (or `?nosave=1`, a debug web build only): the flag whose whole job is to be *a* flag
## when no other is wanted, so a plain playtest session run from a shared checkout never touches
## `user://`'s real save. Every other dev flag already keeps a run off the save by being one — see
## `GameSave.uses_save()`.
func no_save() -> bool:
	if not enabled():
		return false
	return "--no-save" in active_args() or _no_save_from_query(_query)

static func _no_save_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "nosave" and pair[1] == "1":
			return true
	return false

## `--spikes` turns on the run log's own `spike` line — see `TelemetryObserver`. Off by default,
## since the line can be noisy (2026-09-14, the player: "make that toggleable separately though
## since it can be quite noisy"); honoured only while a run is being traced.
func spikes_requested() -> bool:
	return "--spikes" in active_args()

## `--frame-trace`: buffered post-draw measurements, available with the ordered run log disabled.
func frame_trace_requested() -> bool:
	return "--frame-trace" in active_args()

## `--frame-record` (or `?framerecord=1` in the open bundle): every frame's time by system for the
## last few minutes of play, slow frames marked, with a readout line naming the last slow frame's
## three largest costs; on the page a button saves the record through the browser's download, and
## on the desktop it is written on scene exit (see `FrameRecorder`).
func frame_record_requested() -> bool:
	return _frame_record_for(active_args(), _query, live_debug_requested())

## `frame_record_requested()`'s own decision, pure in its three inputs the way `_ground_mode_for()`
## is: the command line, or the page while the bundle is open, and only the value `1` there.
static func _frame_record_for(args: PackedStringArray, query: String, flags_open: bool) -> bool:
	if "--frame-record" in args:
		return true
	if not flags_open:
		return false
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "framerecord" and pair[1] == "1":
			return true
	return false

## `--quit-when-still` is present at all — whether `StillWatch` is built.
func quit_when_still_requested() -> bool:
	return "--quit-when-still" in active_args()

## `--quit-when-still [seconds]`: how long she must stay within a few pixels of one spot, once
## armed, before `StillWatch` saves a picture and quits. About a second by default, the player's
## own phrase for it (2026-09-23: "if the player doesn't move for a second or so"); the optional
## value is read only when it is a number, so `--quit-when-still --seed 4242` does not swallow the
## next flag as a duration.
func quit_when_still_seconds() -> float:
	var args := active_args()
	var index := args.find("--quit-when-still")
	if index == -1:
		return _QUIT_WHEN_STILL_DEFAULT
	if index + 1 < args.size() and args[index + 1].is_valid_float():
		return maxf(0.1, float(args[index + 1]))
	return _QUIT_WHEN_STILL_DEFAULT

const _QUIT_WHEN_STILL_DEFAULT := 1.0

## `--touch` answers the touch hardware question yes on a debug build (`TouchInput.available()`),
## so a touch-only screen can be photographed on a machine with no touchscreen.
func touch_forced() -> bool:
	return "--touch" in active_args()

## `--web` answers the quit question as the web export does (`QuitOption.available()`) on a debug
## build, so the hidden-`Q` shape can be looked at without exporting. It changes what a screen
## shows, never what quitting does.
func web_preview() -> bool:
	return "--web" in active_args()

## `--title` photographs the title screen; `--no-title` skips it for a run that drives nothing.
func title_requested() -> bool:
	return "--title" in active_args()

func no_title_requested() -> bool:
	return "--no-title" in active_args()

## `--screenshot <path>`'s path, or "" — read by `RunConfig.screenshot_rig()` and
## `AutoScreenshot`, which owns the capture.
func screenshot_path() -> String:
	return _word_after("--screenshot")

# ------------------------------------------------------- recording, and a trailer shot ---
## PLAYTEST-139: "the trailer will be a set of paths in pre determined seeds with fixed events so
## we can reproduce it easily" · "we shouldn't show something that will never be visible".
## `tools/record.sh` records any rig run through Godot's own movie writer, and `tools/trailer.sh`
## records every shot in `tools/trailer/shots.json` the same way, with the flags below beside the
## ones that already choose a seed, a day, a spawn and a walk.

## Whether Godot's own movie writer is recording this run (`--write-movie`, an engine flag rather
## than one of this table's): the game then advances exactly `1 / --fixed-fps` a frame however long
## a frame takes to save, so nobody can be playing it. A debug build's only, like every flag here.
func recording() -> bool:
	return enabled() and _movie

## `--player-view` draws the frame a player sees: the release build's own HUD, and the developer
## readout off unless `--debug` asks for it.
func player_view_requested() -> bool:
	return "--player-view" in active_args()

## `--parent mother|father`: which presentation the run shows, instead of the roll
## `GameState.start_run()` makes from the seed. `""` for "not given"; an unknown word is refused
## with `push_warning` and treated the same, since a shot of the wrong parent that said nothing
## would be the one failure the shot list exists to rule out. A recipe's own parent wins.
func parent_override() -> String:
	if not _recipe.is_empty():
		return str(_recipe.get("setup", {}).get("parent", "mother"))
	var args := active_args()
	var index := args.find("--parent")
	if index == -1 or index + 1 >= args.size():
		return ""
	return parse_parent(args[index + 1])

## `--hard`: the fresh run begins in hard mode, and the title's Hard Mode checkbox opens checked.
func hard_mode_requested() -> bool:
	return "--hard" in active_args()

## `--nerves N`: the fresh run begins with `N` nerves instead of `Tuning.STARTING_NERVES`, so a rig
## reaches what the last nerve does on the first loss. `0` for "not given".
func nerves_override() -> int:
	var args := active_args()
	var index := args.find("--nerves")
	if index == -1 or index + 1 >= args.size():
		return 0
	return parse_nerves(args[index + 1])

## The bare parsing of a `--nerves` value: anything but a whole number from 1 to
## `Tuning.STARTING_NERVES` is refused with `push_warning` and treated as "not given".
static func parse_nerves(raw: String) -> int:
	if raw.is_valid_int() and int(raw) >= 1 and int(raw) <= Tuning.STARTING_NERVES:
		return int(raw)
	push_warning("--nerves: '%s' is not a whole number from 1 to %d, ignoring the flag"
			% [raw, Tuning.STARTING_NERVES])
	return 0

## The bare parsing of a `--parent` value.
static func parse_parent(raw: String) -> String:
	if raw in ["mother", "father"]:
		return raw
	push_warning("--parent: '%s' is neither mother nor father, ignoring the flag" % raw)
	return ""

## `--zoom-out <seconds> [delay]` pulls the camera back from her to the whole city over `seconds`,
## after holding on her for `delay` — the trailer's last shot. `-1.0` for "not given"; a value that
## is not a positive number refuses the whole flag the way `parse_zoom()` refuses a malformed
## `--zoom`. `ZoomOutCamera` is what moves.
func zoom_out_seconds() -> float:
	var args := active_args()
	var index := args.find("--zoom-out")
	if index == -1 or index + 1 >= args.size():
		return -1.0
	var raw := args[index + 1]
	if not raw.is_valid_float() or float(raw) <= 0.0:
		push_warning("--zoom-out: '%s' is not a positive number of seconds, ignoring" % raw)
		return -1.0
	return float(raw)

## `--zoom-out`'s optional second value: seconds held on her before the camera moves, read only
## when it is a number, so `--zoom-out 4 --seed 1` does not swallow the next flag.
func zoom_out_delay() -> float:
	var args := active_args()
	var index := args.find("--zoom-out")
	if index == -1 or index + 2 >= args.size() or not args[index + 2].is_valid_float():
		return 0.0
	return maxf(0.0, float(args[index + 2]))

## `--caption <text>`: one line of on-screen text for a trailer shot, or "". See `TrailerText`.
func caption_text() -> String:
	return _word_after("--caption")

## `--title-card <text>`: the game's name, large and centred over the shot, or "".
func title_card_text() -> String:
	return _word_after("--title-card")

## The word after `flag` on the gated command line, or "" when the flag or its word is missing.
func _word_after(flag: String) -> String:
	var args := active_args()
	var index := args.find(flag)
	if index == -1 or index + 1 >= args.size():
		return ""
	return args[index + 1]

# ---------------------------------------------------------------------- scene recipes ---

## `--recipe <path>`: the authored scene to boot, or "".
func recipe_path() -> String:
	return _word_after("--recipe")

## `--recipe-mode free|scripted`, `free` by default: a free-play recipe keeps real controls and no
## recording deadline; a scripted one plays itself and is a rig.
func recipe_mode() -> String:
	var mode := _word_after("--recipe-mode")
	return "free" if mode.is_empty() else mode

func recipe_scripted() -> bool:
	return not recipe_path().is_empty() and recipe_mode() == "scripted"

## `--recipe-validate`: quit once the recipe has been installed and its manifest written.
func recipe_validate() -> bool:
	return "--recipe-validate" in active_args()

## `--recipe-manifest <path>`, where the recipe's manifest is written, or "".
func recipe_manifest_path() -> String:
	return _word_after("--recipe-manifest")

## `--recipe-draft <path>`, where a drafted recipe is written, or "".
func recipe_draft_path() -> String:
	return _word_after("--recipe-draft")

# ---------------------------------------------------------------------- a rig's own lockdown ---
## PLAYTEST-133: "since those are godot apps that launch in my view it could be that accidentally
## pressed a button maybe? since it takes the focus away from what I'm doing every time" — and,
## on the same fix, "will it also prevent godot windows from staying open indefinitely?" `main.gd`
## reads `RunConfig.is_rig` once, at boot, to strip its own window's focus, gate out real input and
## start the wall-clock quit timer below; `tools/shot.sh` and `tools/run.sh` read the identical
## `RIG_FLAGS` list (the marker block above) to decide the same three things on the shell side.

## The `RIG_FLAGS` list above, spelled out for GDScript, which has no reader for its own file's doc
## comments; kept in step with that block by hand.
const _RIG_FLAGS := ["--screenshot", "--walk", "--flee", "--press", "--tap", "--route"]

## Whether this run is a rig rather than a person at the keyboard: a flag on `_RIG_FLAGS`, a movie
## recording, or a scripted recipe.
func is_rig() -> bool:
	return _is_rig_from_args(active_args()) or recording() or recipe_scripted()

static func _is_rig_from_args(args: PackedStringArray) -> bool:
	for flag in _RIG_FLAGS:
		if flag in args:
			return true
	return false

## The margin added to a rig's own known script length, and the hard ceiling neither may push the
## deadline past — a full day (`Tuning.DAY_LENGTH_SECONDS`, 210s) plus this margin is 225s, so 240s
## leaves headroom without extending a short rig's wait needlessly. Read by `tools/lib_dev_flags.sh`
## out of the `RIG_QUIT_SECONDS` marker block above.
const RIG_QUIT_MARGIN_SECONDS := 15.0
const RIG_QUIT_CEILING_SECONDS := 240.0
## How long `tools/shot.sh`'s (and a rig-flagged `tools/run.sh`'s) external kill waits past the
## deadline it computes with the same formula, before it decides the in-game timer did not fire —
## generous enough that a slow atlas rebuild or a slow machine's boot never races it.
const RIG_KILL_GRACE_SECONDS := 15.0
## How many wall-clock seconds a recorded game second may take before `tools/record.sh` and
## `tools/trailer.sh` kill Godot from outside. Under the movie writer the game counts its own
## deadline in game seconds (`RigLock._process()`), so a wall-clock limit is only the outside backstop
## for a process that stopped running; this factor stretches the game-second deadline into one,
## generous against the slowest measured recording (a frame-by-frame PNG at 60fps records a game
## second in about four).
const RIG_MOVIE_SLOWDOWN := 10.0

## Pure: seconds until a rig quits itself. `after` is `--after`'s own value (a screenshot or
## timed-trace rig's wait, the common case) or `-1.0` for "not given"; `day_length` is the longest
## a rig with no such bound can run, the day it plays, since nothing else ends it sooner.
static func rig_quit_seconds_from(after: float, day_length: float) -> float:
	var script := after if after >= 0.0 else day_length
	return clampf(script + RIG_QUIT_MARGIN_SECONDS, RIG_QUIT_MARGIN_SECONDS, RIG_QUIT_CEILING_SECONDS)

## `--after`'s own value, or `-1.0` for "not given or not a number" — the sentinel
## `rig_quit_seconds_from()` reads as "fall back to the day's own length". `AutoScreenshot` reads
## the same flag for its own wait.
func rig_after() -> float:
	var args := active_args()
	var index := args.find("--after")
	if index != -1 and index + 1 < args.size() and args[index + 1].is_valid_float():
		return float(args[index + 1])
	return -1.0
