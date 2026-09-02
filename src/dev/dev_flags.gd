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
static func enabled() -> bool:
	return OS.is_debug_build()

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
