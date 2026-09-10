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
