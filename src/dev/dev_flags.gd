class_name DevFlags
extends RefCounted
## Parses every developer-only command-line flag and is the one place all of them are gated
## behind `OS.is_debug_build()`.
##
## Moved out of `main.gd`, which carried this parsing inline, mixed into the boot sequence and
## the day loop it sits beside. `OS.is_debug_build()` is `false` for an exported release
## template — which is what `tools/export-web.sh` produces — so every getter here answers "not
## given" no matter what is on the command line: a public build cannot be made to reveal a seed,
## jump to a day, or write a screenshot by passing it flags nobody documented for a player.
##
## **`--no-telemetry` is not here.** It is a documented player-facing opt-out (see
## docs/TELEMETRY.md), not developer furniture, and stays live in every build.
## **`AutoScreenshot.from_command_line()` gates itself the same way independently**, since
## `--screenshot`, `--after`, `--walk`, `--flee` and `--press` are parsed there rather than in
## `main.gd`, and are gated in place rather than moved here.
##
## **The table below is the one manifest of the whole surface, even the half parsed elsewhere.**
## `tools/run.sh` and `tools/shot.sh` forward whatever a caller gives them straight to the game
## as a dev flag (see the **cli-tools** skill), so they need to reject a typo before spending a
## Godot launch on it — and the only way that check cannot drift from what the game actually
## reads is to read it from the same file the game does. A flag's own parsing stays where it
## already lives (here, `AutoScreenshot`, `TouchInput`, `QuitOption`, `main.gd`); this table adds
## nothing to that and changes no behaviour — it is a manifest for the shell side, not a second
## parser. Each row is `<flag> <arity>`: arity is the exact count of words the flag always
## consumes, `?` marks one more consumed only when it looks like a number, `w?` marks one more
## consumed only when it does not itself start with `--` (`--start-escape`'s own target word),
## and `*` marks a flag that may repeat (`--press` only, two words each time). Keep this in step
## with the getters below and with
## `AutoScreenshot.from_command_line()` — a flag added to either without a row here is invisible
## to the shell tools and gets rejected as unknown.
##
## DEV_FLAG_TABLE
##   --seed          1
##   --day           1
##   --day-length    1
##   --meters        2
##   --spawn         1
##   --follow        1
##   --force         1?
##   --overview      0
##   --start-escape  0w?
##   --ending        1
##   --controls      1
##   --layers        1
##   --svg           0
##   --no-telemetry  0
##   --screenshot    1
##   --after         1
##   --walk          1
##   --flee          0?
##   --press         2*
##   --tap           2
##   --touch         0
##   --web           0
##   --title         0
##   --no-title      0
## END_DEV_FLAG_TABLE

## Whether dev flags are readable at all. `main.gd` also reads this directly for the two gated
## things that are not a flag value — the snapshot key, and whether to even ask `AutoScreenshot`
## for a rig.
##
## **Deliberately has no override of its own — the one gate everything else now funnels through,
## including `Telemetry`'s own `?telemetry=1`.** *(2026-09-06, the player: "for dev you need it to
## be controllable from the getgo -- for release there should be no modifiers".)* A release build
## carries no modifiers of any kind; a debug build carries every one of them immediately, with
## nothing further to unlock. This class gates a batch of capabilities at once — an arbitrary seed,
## a chosen day, a spawn point beside any event, forced meters, a compressed day, a forced ending,
## a forced control scheme, and (through `AutoScreenshot.from_command_line()`'s own copy of this
## same gate) scripted input and a screenshot written to disk — where `?telemetry=1` reaches exactly
## one bounded, already-shipped choice. An override here would reach all of the above at once from any
## visitor's address bar, which is precisely "reveal a seed, jump to a day... nobody documented for
## a player" — the exact outcome this class exists to prevent. The entry point stays what it
## already is: run a debug build.
static func enabled() -> bool:
	return OS.is_debug_build()

## Whether SVG presentation was explicitly requested. PNG transfers are the default whenever a
## matching asset exists; this remains a user-facing override so release web builds can select SVG
## with `?svg=1` even though developer flags are unavailable there.
static func svg_requested() -> bool:
	return _svg_from_args(OS.get_cmdline_user_args()) or _svg_from_query(_web_query())

static func _svg_from_args(args: PackedStringArray) -> bool:
	return "--svg" in args

static func _svg_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "svg" and pair[1] == "1":
			return true
	return false

static func _web_query() -> String:
	if OS.get_name() != "Web":
		return ""
	var search: Variant = JavaScriptBridge.eval("window.location.search")
	return search as String if search is String else ""

## The command line, or nothing at all outside a debug build — the one choke point every getter
## below reads through.
static func _args() -> PackedStringArray:
	return OS.get_cmdline_user_args() if enabled() else PackedStringArray()

## The same, for a caller that needs to test for a flag's bare presence rather than a value —
## `main._somebody_is_playing()` is the one case, and it must see no rig flags at all outside a
## debug build, since none of them can do anything there.
static func active_args() -> PackedStringArray:
	return _args()

## `--seed N` regenerates a specific city, so a layout bug can be looked at twice. `0` is both
## the sentinel for "not given" and the game's own behaviour of a fresh seed per run, so nothing
## is lost by sharing it.
static func seed_override() -> int:
	var args := _args()
	var index := args.find("--seed")
	if index == -1 or index + 1 >= args.size():
		return 0
	return int(args[index + 1])

## `--day N` starts on a later day, clamped into the run.
static func day_override() -> int:
	var args := _args()
	var index := args.find("--day")
	if index == -1 or index + 1 >= args.size():
		return 1
	return clampi(int(args[index + 1]), 1, Tuning.RUN_LENGTH_DAYS)

## `--spawn <target>` — the raw target string, or "" if none was given. What each target means
## reads `_city.map`, so that lookup stays in `main.gd`; this only extracts the word.
static func spawn_target() -> String:
	var args := _args()
	var index := args.find("--spawn")
	if index == -1 or index + 1 >= args.size():
		return ""
	return args[index + 1]

## `--follow <event id>` — the raw id, or "" if none was given.
static func follow_target() -> String:
	var args := _args()
	var index := args.find("--follow")
	if index == -1 or index + 1 >= args.size():
		return ""
	return args[index + 1]

## `--force <event id> [seconds]` — the raw id, or "" if none was given.
##
## **The flag for checking one row rather than one city.** `EventDirector` hands out the day's own
## `AHEAD_OF_PLAYER` and `TOWARD_PLAYER` plans on an 11–26s interval while she walks, so a row you
## want to look at — a `cyclist`'s lethal radius, a `charging_dog`'s lead time — arrives when it
## arrives, mixed into everything else, and a day may not have bought one at all. Under this flag
## the director hands out **that row and nothing else**, refilled as fast as it is spent, at
## `forced_interval()` rather than the ordinary band.
##
## It bypasses `first_day` and the day's budget on purpose: the question it exists for is *what
## does this row do when it reaches her*, which is a question about the row and not about whether
## today's plan contains one. `--seed` and `--day` still decide the city and the act, so everything
## around the row is the ordinary game.
static func forced_row() -> String:
	var args := _args()
	var index := args.find("--force")
	if index == -1 or index + 1 >= args.size():
		return ""
	return args[index + 1]

## Seconds between two forced rows — the optional second argument to `--force`, or
## `_FORCED_INTERVAL_DEFAULT` when it is absent or is the next flag rather than a number.
##
## Short, because the point of the flag is to see the same encounter several times in a row without
## walking a day for each one, and long enough that two are never on screen together: a `cyclist`
## sited 565px out and closing at 257px/s takes about 2.2s to arrive, so 6s leaves the last one
## finished and gone before the next is placed.
static func forced_interval() -> float:
	var args := _args()
	var index := args.find("--force")
	if index == -1 or index + 2 >= args.size():
		return _FORCED_INTERVAL_DEFAULT
	var word := args[index + 2]
	if not word.is_valid_float():
		return _FORCED_INTERVAL_DEFAULT
	return maxf(float(word), 0.5)

const _FORCED_INTERVAL_DEFAULT := 6.0

## `--meters <sleepiness> <excitement>`, clamped into range — or `(-1, -1)` if the flag is
## absent, malformed, or unreadable outside a debug build. Negative is not a valid meter reading,
## so it costs nothing extra to reuse as the "not given" sentinel.
static func meters_override() -> Vector2:
	var args := _args()
	var index := args.find("--meters")
	if index == -1 or index + 2 >= args.size():
		return Vector2(-1.0, -1.0)
	return Vector2(
			clampf(float(args[index + 1]), 0.0, Tuning.METER_MAX),
			clampf(float(args[index + 2]), 0.0, Tuning.METER_MAX))

## `--overview` frames the whole city at once.
static func overview_requested() -> bool:
	return "--overview" in _args()

## `--start-escape` (or the page's own `?escape=1`) skips the title and the city and starts
## `main` straight in the escape scene's interior — see docs/TODO.md, "M112 — The escape scene,
## walkable". Gated the same as every other flag here: `false` outside a debug build, so the one
## way into a scene with no events, no crowd and no day clock is a debug build, never a URL a
## release build's own visitor could type.
##
## The query form is cheap to answer alongside the command-line one — `_web_query()` already
## exists for `layers_override()` — and a release web build's own gate is `enabled()`, read here
## the same way `layers_override()` reads it explicitly rather than through `_args()`, since a
## bare `_web_query()` carries no gate of its own.
static func start_escape() -> bool:
	if "--start-escape" in _args():
		return true
	if not enabled():
		return false
	for parameter in _web_query().trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "escape" and pair[1] == "1":
			return true
	return false

## `--start-escape`'s own optional value — `stairwell:left`, `stairwell:right`, `lobby`, `basement`
## or `floor:N` — so a rig or a person can teleport straight to any of the building's seven parts
## instead of always walking there from her door; the building is one map (see `InteriorMapPlan`'s
## own doc), so this chooses where on it she starts rather than which map loads. `""` when the flag
## was given bare (the default: the third floor at her door) or not given at all; mapping the word
## onto an `InteriorMap.PARTS` name stays with `main.gd`, the only caller, the same split
## `ending_override()` leaves to its own caller.
##
## Read only when `--start-escape` is itself present, so a bare next word that happens to start
## with neither `--` nor a recognised target is not silently swallowed as some other flag's own
## value — there is no other flag this could be confused with, since every value here is a fixed
## word rather than a number.
static func start_escape_at() -> String:
	var args := _args()
	var index := args.find("--start-escape")
	if index == -1 or index + 1 >= args.size():
		return ""
	var word: String = args[index + 1]
	return "" if word.begins_with("--") else word

## `--day-length N` compresses the day, so dusk and the timeout loss can be looked at without
## sitting through the whole three minutes. `-1.0` is "not given"; the fallback to
## `Tuning.day_length()` stays with the caller, since that also needs to know which day it is.
static func day_length_override() -> float:
	var args := _args()
	var index := args.find("--day-length")
	if index == -1 or index + 1 >= args.size():
		return -1.0
	return maxf(1.0, float(args[index + 1]))

## `--ending bad|neutral|good` — the raw word, or "" if none was given. Mapping it onto
## `GameEnums.Ending` and warning on an unknown word stays in `main.gd`, the only caller.
static func ending_override() -> String:
	var args := _args()
	var index := args.find("--ending")
	if index == -1 or index + 1 >= args.size():
		return ""
	return args[index + 1]

## `--controls joystick|tap` — the raw word, or "" if none was given. Mapping it onto
## `ControlsMode.Mode` stays in `ControlsMode.resolve()`, the only caller, alongside the page's own
## `?controls=` query — this is only ever the command-line half of that same question.
static func controls_override() -> String:
	var args := _args()
	var index := args.find("--controls")
	if index == -1 or index + 1 >= args.size():
		return ""
	return args[index + 1]

## `--layers 1,3` (or the page's own `?layers=1,3`) sets which of `DebugLayers`' three geometry
## layers start on, so a rig screenshot of a particular disagreement is reproducible without a
## keypress. `4` (the readout) is not part of this list: it defaults on already, and this flag
## exists for a clean *geometry* shot. Gated behind `enabled()` explicitly, the same as
## `ControlsMode._url_word()` gates its own query read, since `_web_query()` itself carries no gate
## — `svg_requested()` above is the one caller that wants it to stay live in a release web build.
static func layers_override() -> Array[int]:
	if not enabled():
		return []
	var args := _args()
	var index := args.find("--layers")
	if index != -1 and index + 1 < args.size():
		return parse_layers(args[index + 1])
	return parse_layers(_layers_from_query(_web_query()))

## The bare parsing of a `--layers`/`?layers=` value into layer indices, pulled out so a test can
## drive it directly — the same split `ControlsMode.from_word()` makes for `--controls`, since
## nothing here can fake a real command line. A malformed entry (not a number, or outside `1..3`)
## is dropped with a printed note rather than failing the whole flag: a rig's one typo should not
## fall back to every layer off instead of the two it actually asked for.
static func parse_layers(raw: String) -> Array[int]:
	var result: Array[int] = []
	if raw == "":
		return result
	for word in raw.split(","):
		if not word.is_valid_int():
			push_warning("--layers: ignoring non-numeric entry '%s'" % word)
			continue
		var n := int(word)
		if n < 1 or n > 3:
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
