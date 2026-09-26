class_name DevFlags
extends RefCounted
## Parses every developer-only command-line flag and is the one place all of them are gated
## behind `OS.is_debug_build()`.
##
## Moved out of `main.gd`, which carried this parsing inline, mixed into the boot sequence and
## the day loop it sits beside. `OS.is_debug_build()` is `false` for an exported release
## template — which is what `tools/export-web.sh` produces — so every getter here answers "not
## given" no matter what is on the command line: a public build cannot be made to jump to a day
## or write a screenshot by passing it flags nobody documented for a player. A seed is the one
## exception — `seed_override()`'s own `?seed=` reaches a positive integer on a page already
## carrying the DEBUG MODE note, through `readout_requested()`'s gate rather than this one; the
## command line's own `--seed` still answers only to this gate, unbounded and arbitrary, as it
## always has.
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
##   --route         1
##   --force         1?
##   --overview      0
##   --zoom          1
##   --start-escape  0w?
##   --blackout      0
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
##   --quit-when-still 0?
## END_DEV_FLAG_TABLE
##
## Which of the flags above mark a run as a **rig** rather than a person at the keyboard — the
## same set `main._somebody_is_playing()` already lists as "something else is holding the keys"
## (`--screenshot`, `--walk`, `--flee`, `--press`, `--route`), plus `--tap`, which drives a
## synthetic touch the same way. `is_rig()` below is the live read; `tools/lib_dev_flags.sh`'s own
## `rig_flag_present()` reads this exact block, so shot.sh/run.sh's decision to strip a window's
## focus, disable vsync, gate input and enforce the wall-clock limit can never name a different set
## of flags than the game itself locks real input out for. A plain `tools/run.sh` session — no
## flag on this list — is a person's, and is untouched by any of it.
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
## The three numbers `rig_quit_seconds_from()` below turns into a rig's own wall-clock deadline,
## read by the same shell helper so its external kill (`RIG_KILL_GRACE_SECONDS` past the deadline)
## can never compute a shorter wait than the deadline the game itself is timing against. See
## `rig_quit_seconds_from()`'s own doc for what each name means.
##
## RIG_QUIT_SECONDS
##   margin 15.0
##   ceiling 240.0
##   kill_grace 15.0
## END_RIG_QUIT_SECONDS

## Whether dev flags are readable at all. `main.gd` also reads this directly for the two gated
## things that are not a flag value — the snapshot key, and whether to even ask `AutoScreenshot`
## for a rig.
##
## **Deliberately has no override of its own — the one gate the input-driving, picture-taking and
## file-writing half of the surface still funnels through unconditionally.** *(2026-09-06, the
## player: "for dev you need it to be controllable from the getgo -- for release there should be
## no modifiers".)* That still holds without exception for an arbitrary, unbounded seed from the
## command line, `--spawn`, `--follow`, `--route`, `--force`, `--overview`, `--zoom`, `--touch`,
## `--web`, `--title`/`--no-title`, `--no-focus-pause`, `--no-save`, `--spikes`, `--frame-trace`,
## `--quit-when-still`, and (through `AutoScreenshot.from_command_line()`'s own copy of this gate)
## `--screenshot`, `--after`, `--walk`, `--flee`, `--press` and `--tap` — a release build answers
## none of it, from any address a visitor could type.
##
## **The smaller half — the flags that choose where a run starts or how it is drawn, never one
## that drives input, takes a picture or writes a file — answers to a release page too, behind
## `?debug=1`.** *(2026-09-25, docs/playtests/PLAYTEST-130.md: "on the published site behind
## debug=1 we'd want some of the debug flags (like day, invincible, etc.) so debugging the live
## build is easier", overturning the 2026-09-06 rule above for that half alone — see docs/DECISIONS.md,
## M193, "the live page's ?debug=1 reaches the debug flags".)* `live_debug_requested()` below is
## that gate: `day_override()`, `invincible()`, `layers_override()`, `ControlsMode.resolve()`,
## `start_escape()`, `meters_override()`, `day_length_override()`, `ending_override()` and
## `blackout_requested()` each read the command line under `enabled()` as they always have and,
## failing that, the page's own query under `live_debug_requested()`.
##
## A debug build carries every flag on this whole page immediately, with nothing further to
## unlock; the entry point for the larger half stays what it already is: run a debug build.
static func enabled() -> bool:
	return OS.is_debug_build()

## Whether the developer readout was explicitly asked for on a release build — `?debug=1` (or the
## command line's own `--debug`), parsed straight off the command line or the page's query string
## and not gated behind `enabled()`. Reaches the readout `main.gd` draws in the top-right corner,
## and gates every other release-safe query flag in turn: `--skip`/`?skip=` (`skip_words()`),
## `?seed=`'s own positive integer (`seed_override()`), and, through `live_debug_requested()`
## below, the smaller bundle M193 opens on top of those two — `?day=`, `?invincible=1`,
## `?layers=`, `?controls=`, `?escape=1`, `?meters=`, `?daylength=` and `?ending=`/`?blackout=1`.
## `Telemetry`'s own `?telemetry=1` is not part of any of this: it stays behind `enabled()` alone
## (docs/TELEMETRY.md, "`--spikes` is off by default"), since a stranger's browser collecting a
## trace is a different question from a stranger's browser reading a day number back. See
## docs/DECISIONS.md, M133, "the readout on the live page", and docs/DECISIONS.md, M193, "the live
## page's ?debug=1 reaches the debug flags".
static func readout_requested() -> bool:
	return _readout_from_args(OS.get_cmdline_user_args()) or _readout_from_query(_web_query())

static func _readout_from_args(args: PackedStringArray) -> bool:
	return "--debug" in args

static func _readout_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "debug" and pair[1] == "1":
			return true
	return false

## The gate for the smaller, release-safe bundle M193 opens beside the readout: the flags that
## choose where a run starts or how it is drawn (`day_override()`, `invincible()`,
## `layers_override()`, `ControlsMode.resolve()`, `start_escape()`, `meters_override()`,
## `day_length_override()`, `ending_override()`, `blackout_requested()`) — never the input-driving,
## picture-taking or file-writing half `enabled()` alone still gates (see `enabled()`'s own doc for
## that list). True on a debug build with or without `?debug=1` in the page, since a debug build
## already answers the whole of `enabled()`'s own bundle regardless of any query string; true on a
## release page only once `readout_requested()` holds, so a release page nobody asked `?debug=1`
## of reads exactly as before. *(2026-09-25, docs/playtests/PLAYTEST-130.md: "on the published site
## behind debug=1 we'd want some of the debug flags (like day, invincible, etc.) so debugging the
## live build is easier".)*
static func live_debug_requested() -> bool:
	return _live_debug_requested(enabled(), readout_requested())

## The decision behind `live_debug_requested()`'s own gate, pulled out to a pure function of its
## two inputs the same shape `ControlsMode._reads_the_url()` and `Telemetry._reads_the_url()`
## already are, so the promise is a truth table a test can check rather than two live reads
## nothing in a test process can fake at once.
static func _live_debug_requested(is_debug: bool, readout: bool) -> bool:
	return is_debug or readout

## The query parameter names `live_debug_requested()`'s own bundle answers to — every one of the
## getters named in that gate's own doc but `layers`/`controls`/`escape`, which were already
## partly reachable before M193 and are folded in here too since a run built with any of them is
## exactly as much a debugging run as one built with `?day=`. `GameSave.uses_save()` reads
## `web_debug_flag_used()` below against this list so a release page's visitor who actually typed
## one of these never touches the save the page might otherwise share with a real player — as
## against `?debug=1` alone, which opens the bundle without yet having used any of it.
const _LIVE_DEBUG_QUERY_KEYS := [
	"day", "invincible", "layers", "controls", "escape", "meters", "daylength", "ending",
	"blackout",
]

## Whether the page's query string actually named one of `live_debug_requested()`'s own
## parameters, as against merely being allowed to — on a release page carrying `?debug=1` and on a
## debug web build alike, since a web page has no command line for `active_args()` to see and
## `?day=` there is as much a debugging run as `--day` is on the desktop. `false` on a release page
## nobody asked `?debug=1` of, the ordinary case this must not disturb, and off the web.
static func web_debug_flag_used() -> bool:
	if not live_debug_requested():
		return false
	return _web_debug_flag_used_in_query(_web_query())

static func _web_debug_flag_used_in_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() >= 1 and pair[0] in _LIVE_DEBUG_QUERY_KEYS:
			return true
	return false

## The words `--skip`/`?skip=` may name, one per desktop probe M124's own measurement turned into
## something a live page can ask for (docs/DECISIONS.md, M124, "the desktop half", rows (e), (d)
## and (c)), plus `motion` (docs/DECISIONS.md, M139, "the phone reading", the probe that asks what
## the crowd's own ticks cost once its drawing is ruled out). Kept in one place so
## `_validate_skip_words()` and the four getters below cannot each spell the set differently.
const _SKIP_KNOWN_WORDS := ["events", "crowd", "shadows", "motion"]

## Whether `--skip`/`?skip=` named `events` — every `EventInstance._draw` returns before drawing
## anything, the desktop's own row (e). Parsed the same shape as
## `readout_requested()` above (a bare command-line value or a `?skip=` query parameter, read
## without `enabled()`'s own gate) but **honoured only while `readout_requested()` holds**: a
## release page without the DEBUG MODE note never skips anything, so this cannot become a second
## way to reach what `enabled()` gates — a page nobody asked `?debug=1` of still draws everything.
## `skip_crowd()` (row (d), `CrowdAgent._draw`), `skip_shadows()` (row (c),
## `BuildingShadows._draw_chunk`) and `skip_motion()` (the crowd's own ticks: every agent's
## `_process` and `Crowd._physics_process`) are the other three words. Nothing else moves: the
## fields, the costs and the halo run as normal, so a frame reading differs from an ordinary run
## by drawing and motion alone, and only whichever of the two this flag named.
static func skip_events() -> bool:
	return "events" in skip_words()

## See `skip_events()`.
static func skip_crowd() -> bool:
	return "crowd" in skip_words()

## See `skip_events()`.
static func skip_shadows() -> bool:
	return "shadows" in skip_words()

## See `skip_events()`. Parks every agent where the day placed it: the street stands full of
## standing people and parked cars, drawn as normal — the crowd's own drawing, the events and the
## baby's excitement read of the crowd are unchanged, since that scan is the baby's and not the
## crowd's.
static func skip_motion() -> bool:
	return "motion" in skip_words()

## The full, validated set behind the four getters above — also what the readout's own `skip`
## line names, through `main.gd`'s cached copy. Empty whenever `readout_requested()` does not
## hold, so the gate is paid once here rather than four times at each caller.
static func skip_words() -> Array[String]:
	if not readout_requested():
		return []
	var raw := _skip_from_args(OS.get_cmdline_user_args())
	if raw == "":
		raw = _skip_from_query(_web_query())
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

## The bare parsing of a `--skip`/`?skip=` value into its words, pulled out so a test can drive it
## directly the same way `parse_layers()` is for `--layers`. An empty value is simply nothing to
## skip, the same as the flag being absent — `parse_layers()`'s own precedent for an empty value.
## Any word this flag does not know refuses the **whole** value rather than the one bad word or
## the words that did parse: a skip that silently dropped an unrecognised word would measure a
## different frame than the one asked for and say nothing about it, the reasoning
## `_show_an_ending_for_a_rig()` in `main.gd` already gives an unknown `--ending` word.
## `push_warning` so a typo is visible rather than a silently smaller skip than the one asked for.
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

## `--seed N` regenerates a specific city, so a layout bug can be looked at twice; the command
## line keeps its own `enabled()` gate and takes precedence when present, unbounded and
## unvalidated as it always has been. Failing that, the page's own `?seed=N` fills in wherever
## `readout_requested()` holds — a release page without the DEBUG MODE note never takes a seed —
## and only for a positive integer: `0`, a negative number, an empty value and anything that is
## not a positive integer are refused with `push_warning` and treated the same as "not given",
## the way `_validate_skip_words()` refuses an unknown `--skip` word. `0` is both that sentinel
## and the game's own behaviour of a fresh seed per run, so nothing is lost by sharing it.
static func seed_override() -> int:
	var args := _args()
	var index := args.find("--seed")
	if index != -1 and index + 1 < args.size():
		return int(args[index + 1])
	return _seed_from_query(_web_query())

## The bare parsing of `?seed=` against a query string, pulled out so a test can drive the whole
## thing without a debug build or a `JavaScriptBridge` — the gate and the validation stay together
## here, unlike `_skip_from_query()`/`_validate_skip_words()`, because the gate itself (`?debug=1`
## in the *same* query) is part of what a release-shaped test case has to drive: `?seed=12345`
## with no `?debug=1` in the same string must answer the same "not given" sentinel as any other
## flag `readout_requested()` does not hold for. An absent `seed` parameter says nothing; a
## present one that is not a positive integer is refused with `push_warning` — an ordinary
## `?debug=1` page that never mentions `seed` must not warn on every load.
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

## `--day N` (or the page's own `?day=N`, under `live_debug_requested()`) starts on a later day,
## clamped into the run the same way either source is read. **One of the two required flags M193
## opens on a release page** (docs/DECISIONS.md, M193, "the live page's ?debug=1 reaches the debug
## flags"). `?day=N` with no `?debug=1` in the same query answers the ordinary "not given" default
## of `1` on a release page, the way every other flag in this bundle does.
static func day_override() -> int:
	var args := _args()
	var index := args.find("--day")
	if index != -1 and index + 1 < args.size():
		return clampi(int(args[index + 1]), 1, Tuning.RUN_LENGTH_DAYS)
	if live_debug_requested():
		var from_query := _day_from_query(_web_query())
		if from_query != -1:
			return from_query
	return 1

## The bare parsing of `?day=` against a query string, pulled out so a test can drive it without a
## web query — the same split `_seed_from_query()` makes for `?seed=`, clamped the same way
## `--day` itself already is rather than refused outright, since an out-of-range or non-numeric
## day is exactly as harmless here as `--day` already makes it on the command line. `-1` is "not
## given"; `1` is both a valid day and this flag's own default, so it cannot double as the
## sentinel the way `0` does for `?seed=`.
static func _day_from_query(query: String) -> int:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "day":
			return clampi(int(pair[1]), 1, Tuning.RUN_LENGTH_DAYS)
	return -1

## `--spawn <target>` — the raw target string, or "" if none was given. What each target means
## reads the live `City`, so that lookup stays in `src/dev/dev_rig.gd`'s `DevRig.spawn_position()`;
## this only extracts the word.
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

## `--route mark,task,calm,home` — an ordered list of target words `src/dev/route_rig.gd`'s
## `RouteRig` walks to in turn, split on commas with nothing else validated: a word `RouteRig`
## does not recognise is its own `push_warning`, the same split `spawn_target()` above leaves to
## `DevRig.for_spawn_target()`, since it is the live `City` that decides what a word means and not
## the raw argv. `[]` for an absent flag or an empty value, which `main.gd` reads as "no rig".
static func route_targets() -> Array[String]:
	var args := _args()
	var index := args.find("--route")
	if index == -1 or index + 1 >= args.size():
		return []
	var result: Array[String] = []
	for word in args[index + 1].split(","):
		if word != "":
			result.append(word)
	return result

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
## is warned for his 2.13s `telegraph_time`, then created just off screen, reaches her about a
## second later closing at 257px/s and is out of sight a second or so after that, so 6s leaves the
## last one gone before the next is even created.
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

## `--meters <sleepiness> <excitement>` (or the page's own `?meters=sleepiness,excitement`, under
## `live_debug_requested()`), clamped into range — or `(-1, -1)` if the flag is absent or
## malformed. Negative is not a valid meter reading, so it costs nothing extra to reuse as the
## "not given" sentinel. One of the M193 flags cheap to mirror on a release page (docs/DECISIONS.md,
## M193, "the live page's ?debug=1 reaches the debug flags"): it only seeds `Baby`'s own starting
## numbers, the same as the command line already does.
static func meters_override() -> Vector2:
	var args := _args()
	var index := args.find("--meters")
	if index != -1 and index + 2 < args.size():
		return Vector2(
				clampf(float(args[index + 1]), 0.0, Tuning.METER_MAX),
				clampf(float(args[index + 2]), 0.0, Tuning.METER_MAX))
	if live_debug_requested():
		return _meters_from_query(_web_query())
	return Vector2(-1.0, -1.0)

## The bare parsing of `?meters=` against a query string, pulled out so a test can drive it
## without a web query. `sleepiness,excitement`, both clamped the same way the command line's own
## two arguments already are; anything that is not exactly two comma-separated numbers refuses the
## whole value with `push_warning`, the reasoning `_validate_skip_words()` gives for an unknown
## `--skip` word.
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
static func overview_requested() -> bool:
	return "--overview" in _args()

## `--blackout` (or the page's own `?blackout=1`, under `live_debug_requested()`) stands in for
## the last night's sabotage, for the blackout alone: `Blackout` treats the city as sabotaged, so
## it goes dark in one frame the moment she is `Tuning.BLACKOUT_DISTANCE` from the power station —
## at once, from a spawn that far away — on whatever day `--day`/`?day=` names. Nothing else reads
## it: no task, ending or save sees a sabotage, which is what keeps it a way to photograph the
## moment rather than a way to reach the good ending — trivial to mirror on a release page the
## same way `--day`/`--invincible` are (docs/DECISIONS.md, M193, "the live page's ?debug=1 reaches the
## debug flags").
static func blackout_requested() -> bool:
	if "--blackout" in _args():
		return true
	if not live_debug_requested():
		return false
	return _blackout_from_query(_web_query())

static func _blackout_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "blackout" and pair[1] == "1":
			return true
	return false

## `--start-escape` (or the page's own `?escape=1`) skips the title and the city and starts
## `main` straight in the escape scene's interior — see docs/TODO.md, "M112 — The escape scene,
## walkable". The command line stays behind `enabled()` alone, so the one way to reach a *chosen*
## interior part (`start_escape_at()`) is still a debug build; the bare boolean is read under
## `live_debug_requested()` instead, one of the flags M193 opens on a release page (docs/DECISIONS.md,
## M193, "the live page's ?debug=1 reaches the debug flags") — a visitor's `?debug=1&escape=1`
## reaches the scene's third-floor default start the same way a debug build's `--start-escape`
## bare does, with no events, no crowd and no day clock either way.
static func start_escape() -> bool:
	if "--start-escape" in _args():
		return true
	if not live_debug_requested():
		return false
	return _escape_from_query(_web_query())

## The bare parsing of `?escape=1` against a query string, pulled out so a test can drive it
## without a web query.
static func _escape_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "escape" and pair[1] == "1":
			return true
	return false

## `--start-escape`'s own optional value — `stairwell:left`, `stairwell:right`, `lobby`, `basement`,
## `floor:N` or `city` — so a rig or a person can start anywhere in the escape sequence instead of
## always walking there from her door. The building is one map (see `InteriorMapPlan`'s own doc),
## so the six part words choose where on it she starts rather than which map loads; `city` is the
## one word that is not a part of the building at all and boots the escape's **second** section,
## the streets with one way out of them, with no building built. `""` when the flag was given bare
## (the default: the third floor at her door) or not given at all; mapping the word onto an
## `InteriorMap.PARTS` name stays with `main.gd`, the only caller, the same split
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

## `--day-length N` (or the page's own `?daylength=N`, under `live_debug_requested()`) compresses
## the day, so dusk and the timeout loss can be looked at without sitting through the whole three
## minutes. `-1.0` is "not given"; the fallback to `Tuning.day_length()` stays with the caller,
## since that also needs to know which day it is. Trivial to mirror on a release page the same way
## as the rest of the M193 bundle (docs/DECISIONS.md, M193, "the live page's ?debug=1 reaches the debug
## flags"): both `DevRig.day_length()` and `FinaleController.length()` read it unconditionally, so
## a visitor's own `?daylength=` reaches an ordinary day exactly as `--day-length` already does.
static func day_length_override() -> float:
	var args := _args()
	var index := args.find("--day-length")
	if index != -1 and index + 1 < args.size():
		return maxf(1.0, float(args[index + 1]))
	if live_debug_requested():
		var from_query := _day_length_from_query(_web_query())
		if from_query > 0.0:
			return from_query
	return -1.0

## The bare parsing of `?daylength=` against a query string, pulled out so a test can drive it
## without a web query. Anything that is not a positive number refuses the whole value with
## `push_warning`, the same as `parse_zoom()` refuses a malformed `--zoom`.
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

## `--zoom <factor>` — the gameplay camera's zoom relative to its normal one, so `0.5` shows twice
## as much of the world each way with everything else — lighting, entities, HUD — exactly as a
## player sees it. For a capture of something bigger than the normal view, where `--overview` is the
## whole city at a scale nothing is played at. `1.0` is "not given". See `parse_zoom()` for what it
## refuses.
static func zoom_override() -> float:
	var args := _args()
	var index := args.find("--zoom")
	if index == -1 or index + 1 >= args.size():
		return 1.0
	return parse_zoom(args[index + 1])

## The bare parsing of a `--zoom` value, pulled out so a test can drive it without a command line.
## Anything that is not a positive number refuses the whole flag — a warning and the normal zoom —
## rather than being clamped into one: a capture at a zoom nobody asked for is a picture of the wrong
## thing that says nothing about it, the reasoning `_validate_skip_words()` gives for `--skip`.
static func parse_zoom(raw: String) -> float:
	if not raw.is_valid_float() or float(raw) <= 0.0:
		push_warning("--zoom: '%s' is not a positive number, ignoring the flag" % raw)
		return 1.0
	return float(raw)

## `--ending bad|neutral|good` (or the page's own `?ending=`, under `live_debug_requested()`) —
## the raw word, or "" if none was given. Mapping it onto `GameEnums.Ending` and warning on an
## unknown word stays in `main.gd`, the only caller, the same for either source. Trivial to mirror
## on a release page the same way as the rest of the M193 bundle (docs/DECISIONS.md, M193, "the live
## page's ?debug=1 reaches the debug flags"): the screen it puts up is drawn over a day already
## running, not a way to end or save a run.
static func ending_override() -> String:
	var args := _args()
	var index := args.find("--ending")
	if index != -1 and index + 1 < args.size():
		return args[index + 1]
	if live_debug_requested():
		return _ending_from_query(_web_query())
	return ""

## The bare parsing of `?ending=` against a query string, pulled out so a test can drive it
## without a web query.
static func _ending_from_query(query: String) -> String:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "ending":
			return pair[1]
	return ""

## `--controls joystick|tap` — the raw word, or "" if none was given. Mapping it onto
## `ControlsMode.Mode` stays in `ControlsMode.resolve()`, the only caller, alongside the page's own
## `?controls=` query — this is only ever the command-line half of that same question.
static func controls_override() -> String:
	var args := _args()
	var index := args.find("--controls")
	if index == -1 or index + 1 >= args.size():
		return ""
	return args[index + 1]

## `--layers 1,3` (or the page's own `?layers=1,3`, under `live_debug_requested()`) sets which of
## `DebugLayers`' three geometry layers start on, so a rig screenshot of a particular disagreement
## is reproducible without a keypress; `5` (`RouteLines`, the day's routes) and `6` (`FrameGraph`,
## the spike view) are the two other layers in the list, on the same terms — `main._add_frame_graph()`
## reads `6 in layers_override()` the same way `_add_route_lines()` reads `5`. `4` (the readout) is
## not part of this list: it defaults on already, and this flag exists for a clean *geometry* shot.
## One of the flags M193 opens on a release page (docs/DECISIONS.md, M193, "the live page's ?debug=1
## reaches the debug flags"): the command line stays behind `enabled()` through `_args()`, and the
## query read falls back to `live_debug_requested()` the same shape `ControlsMode._url_word()`
## gates its own query read.
static func layers_override() -> Array[int]:
	var args := _args()
	var index := args.find("--layers")
	if index != -1 and index + 1 < args.size():
		return parse_layers(args[index + 1])
	if not live_debug_requested():
		return []
	return parse_layers(_layers_from_query(_web_query()))

## The bare parsing of a `--layers`/`?layers=` value into layer indices, pulled out so a test can
## drive it directly — the same split `ControlsMode.from_word()` makes for `--controls`, since
## nothing here can fake a real command line. A malformed entry (not a number, or one outside the
## six valid indices, `4` included even though it can never be *set* this way) is dropped with a
## printed note rather than failing the whole flag: a rig's one typo should not fall back to every
## layer off instead of the two it actually asked for.
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

## Set by a test to force `invincible()`'s own answer, bypassing the real command line.
## `OS.get_cmdline_user_args()` is what `run_tests.gd` itself reads to pick which suites run, so a
## test cannot drive this flag through actual argv the way a player would — this is the smallest
## seam that lets one exercise `DayController`'s three loss paths under the flag anyway. `null`
## (the default) means "answer normally"; a test sets this to `true` or `false` before exercising
## the flag and clears it back to `null` when done, or the override leaks into every suite that
## runs after it.
static var _invincible_override: Variant = null

## `--invincible` (or the page's own `?invincible=1`, under `live_debug_requested()`) makes nothing
## end the day: `DayController._ignores_loss()` is the one predicate every losing path consults, and
## this is the flag it reads. **It also stands the day clock and the excitement meter still** —
## `DayController._process()` skips the countdown outright rather than letting it run to dusk, and
## `Baby._update_excitement()` never adds to the meter, though decay may still run it down — so a
## capture waiting for a moment gets quiet held time rather than a flashing alarm and a darkening
## day. *(2026-09-11, overturning the flag's own first build the same evening: "when invincible the
## timer should never go down and excitement should never go up. this is just noisy flashing of
## alarms and the day gets dark.")* The record is in docs/DECISIONS.md under M100, "an invincible
## mode for playtesting" and "invincible freezes the clock and the meter".
##
## **One of the two required flags M193 opens on a release page** (docs/DECISIONS.md, M193, "the live
## page's ?debug=1 reaches the debug flags") — a visitor's own `?invincible=1` reaches this whole
## predicate the same way a debug build's `--invincible` already does, gated behind
## `live_debug_requested()` rather than `enabled()` alone.
static func invincible() -> bool:
	if _invincible_override != null:
		return bool(_invincible_override)
	if _invincible_from_args(_args()):
		return true
	if not live_debug_requested():
		return false
	return _invincible_from_query(_web_query())

static func _invincible_from_args(args: PackedStringArray) -> bool:
	return "--invincible" in args

static func _invincible_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "invincible" and pair[1] == "1":
			return true
	return false

## `--no-focus-pause` (or the page's own `?nofocuspause=1`, a debug web build only) turns off the
## pause `main._notification()` opens when the window loses focus — see that function's own doc.
## **`--screenshot` implies it without being told to**: a screenshot rig's window usually opens
## behind whatever the operator is doing, so it never has focus to lose, or loses it the instant it
## opens — either way a game that pauses on that would hand the rig a picture of the pause screen
## rather than the day it was asked to capture. The flag by itself is what a `tools/run.sh` session
## with no screenshot needs, since that rig has the same unfocused window and nothing else here
## would cover it.
##
## Gated behind `enabled()` explicitly, the same as `invincible()` gates its own query read: this
## reaches whether the game can be walked away from behind another window, which stays a developer
## question rather than one an exported release answers to a visitor's address bar.
static func no_focus_pause() -> bool:
	if not enabled():
		return false
	return _no_focus_pause_from_args(_args()) or _no_focus_pause_from_query(_web_query())

static func _no_focus_pause_from_args(args: PackedStringArray) -> bool:
	return "--no-focus-pause" in args or "--screenshot" in args

static func _no_focus_pause_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "nofocuspause" and pair[1] == "1":
			return true
	return false

## `--no-save` (or the page's own `?nosave=1`, a debug web build only) says the same thing a
## flagless `tools/run.sh` session cannot say on its own — see `GameSave.uses_save()`, the one
## function every read and write of the player's save goes through. Every *other* dev flag already
## keeps a run off the save by being a dev flag at all (`GameSave.uses_save()` refuses the moment
## `active_args()` is not empty); this is the one flag whose entire job is to be *a* flag when no
## other one is wanted, so a plain playtest session run from a shared checkout never touches
## `user://`'s real save file by accident.
##
## Gated behind `enabled()` explicitly, the same as `no_focus_pause()` gates its own query read.
static func no_save() -> bool:
	if not enabled():
		return false
	return "--no-save" in _args() or _no_save_from_query(_web_query())

static func _no_save_from_query(query: String) -> bool:
	for parameter in query.trim_prefix("?").split("&"):
		var pair := parameter.split("=", true, 1)
		if pair.size() == 2 and pair[0] == "nosave" and pair[1] == "1":
			return true
	return false

## `--spikes` turns on the run log's own `spike` line — see `TelemetryObserver._watch_the_frame`.
## Off by default: *(2026-09-14, the player, asked whether the line should always be on: "make
## that toggleable separately though since it can be quite noisy")*. Gated behind `enabled()`,
## the same as every other flag on this table but `--no-telemetry`, and reaches nothing on its
## own even so — `main.gd` only builds a `TelemetryObserver` while `Telemetry.is_active()` holds,
## so the flag is honoured only while a run is already being traced.
static func spikes_requested() -> bool:
	return "--spikes" in _args()

## Buffered post-draw measurements remain available with the ordered telemetry log disabled.
static func frame_trace_requested() -> bool:
	return "--frame-trace" in _args()

## `--quit-when-still` is present at all — `StillWatch` (`src/dev/still_watch.gd`) reads this to
## decide whether to add itself to the tree, the same shape `route_targets().is_empty()` gates
## `RouteRig` on. See `quit_when_still_seconds()` for the flag's own optional value.
static func quit_when_still_requested() -> bool:
	return "--quit-when-still" in _args()

## `--quit-when-still [seconds]` — how long she must stay within a few pixels of one spot, once
## armed, before `StillWatch` saves a picture and quits. About a second by default, the player's
## own phrase for it (asked for 2026-09-23: "if the player doesn't move for a second or so"); the
## optional value is read the same way `--flee`'s own delay is (`_dither`, above) — present and
## numeric only, so `--quit-when-still --seed 4242` does not swallow the next flag as a duration.
static func quit_when_still_seconds() -> float:
	var args := _args()
	var index := args.find("--quit-when-still")
	if index == -1:
		return _QUIT_WHEN_STILL_DEFAULT
	if index + 1 < args.size() and args[index + 1].is_valid_float():
		return maxf(0.1, float(args[index + 1]))
	return _QUIT_WHEN_STILL_DEFAULT

const _QUIT_WHEN_STILL_DEFAULT := 1.0

# ---------------------------------------------------------------------- a rig's own lockdown ---
## PLAYTEST-133: "since those are godot apps that launch in my view it could be that accidentally
## pressed a button maybe? since it takes the focus away from what I'm doing every time" — and,
## on the same fix, "will it also prevent godot windows from staying open indefinitely?" `main.gd`
## reads `is_rig()` once, at boot, to strip its own window's focus, gate out real input and start
## the wall-clock quit timer below; `tools/shot.sh` and `tools/run.sh` read the identical
## `RIG_FLAGS` list (see the marker block above `enabled()`) to decide the same three things on
## the shell side — whether to launch with `--disable-vsync`, whether to wrap the launch in an
## external kill, and what deadline to give it.

## The exact `RIG_FLAGS` list above, spelled out for GDScript rather than parsed from the doc
## comment the way the shell side reads it — there is no GDScript reader for its own file's doc
## comments, so this is kept in step with that block by hand, the same promise `DEV_FLAG_TABLE`'s
## own doc already asks of `AutoScreenshot.from_command_line()`.
const _RIG_FLAGS := ["--screenshot", "--walk", "--flee", "--press", "--tap", "--route"]

## Whether this run is a rig rather than a person at the keyboard — `main._somebody_is_playing()`
## asks the same question for telemetry's sake and must never disagree with this: both read
## `active_args()`/`_args()` against the identical set of flags (this file's one list, above).
static func is_rig() -> bool:
	return _is_rig_from_args(_args())

static func _is_rig_from_args(args: PackedStringArray) -> bool:
	for flag in _RIG_FLAGS:
		if flag in args:
			return true
	return false

## The margin added to a rig's own known script length, and the hard ceiling neither that length
## nor the margin may push the deadline past — a full day (`Tuning.DAY_LENGTH_SECONDS`, 210s) plus
## this margin is 225s, so 240s leaves headroom without extending a short rig's own wait
## needlessly. Read by `tools/lib_dev_flags.sh` out of the `RIG_QUIT_SECONDS` marker block above,
## rather than copied there by hand.
const RIG_QUIT_MARGIN_SECONDS := 15.0
const RIG_QUIT_CEILING_SECONDS := 240.0
## How long `tools/shot.sh`'s (and a rig-flagged `tools/run.sh`'s) own external kill waits past the
## deadline it computes with the same formula, before it decides the in-game timer itself did not
## fire and kills the process from outside — generous enough that a slow atlas rebuild or a slow
## machine's own boot never races it, short enough that a genuinely wedged rig does not tie up
## whoever is waiting on the command to return.
const RIG_KILL_GRACE_SECONDS := 15.0

## Pure: seconds until a rig quits itself, from the two numbers that decide it. `after` is
## `--after`'s own value if the flag was given (a screenshot or timed-trace rig's own wait, the
## common case — see `AutoScreenshot._seconds_to_wait`) or `-1.0` for "not given"; `day_length` is
## what a rig with no such bound (`--route`, or `--walk`/`--flee`/`--press`/`--tap` on their own,
## none of which stop anything by themselves without `--screenshot` or `--frame-trace` beside them)
## can run for at the very most — the day it is playing, since nothing else ends it sooner. Pulled
## out as a pure function of both so a test can drive every combination without a command line —
## the same seam `_no_focus_pause_from_args()` already is for its own flag.
static func rig_quit_seconds_from(after: float, day_length: float) -> float:
	var script := after if after >= 0.0 else day_length
	return clampf(script + RIG_QUIT_MARGIN_SECONDS, RIG_QUIT_MARGIN_SECONDS, RIG_QUIT_CEILING_SECONDS)

## The live answer `main.gd` times its own quit timer against: `--after`'s value if given, else
## whatever day this rig is playing's own length (`--day-length`'s override, or the ordinary
## `Tuning.day_length(day)` for `--day`'s own day — 210s for every day but the curfew ones, 180s
## for those, see `Tuning.day_length()`'s own doc). Not asked when `is_rig()` is false — a plain
## `tools/run.sh` session has no deadline at all.
static func rig_quit_seconds() -> float:
	var after := _rig_after_value()
	var day_length := day_length_override()
	if day_length <= 0.0:
		day_length = Tuning.day_length(day_override())
	return rig_quit_seconds_from(after, day_length)

## The bare parsing of `--after`'s own value, pulled out because `rig_quit_seconds()` needs it and
## `AutoScreenshot` (where `--after` is otherwise read) is not a place `DevFlags` reaches into —
## `-1.0` for "not given or not a number", the same sentinel `rig_quit_seconds_from()` reads as
## "fall back to the day's own length".
static func _rig_after_value() -> float:
	var args := _args()
	var index := args.find("--after")
	if index != -1 and index + 1 < args.size() and args[index + 1].is_valid_float():
		return float(args[index + 1])
	return -1.0
