@warning_ignore_start("unsafe_property_access", "unsafe_method_access")
class_name RunSession
extends Node
## The run log's one owner for a boot: it opens the log for a run and closes it when the run is
## left, heads each walk — a day, an authored scene's day or a section of the escape — writes the run
## flow's own lines and pictures, and holds the `TelemetryObserver` that watches the walk.
##
## **It listens; the run flow does not call it.** A walk reaches it as the run flow announces it
## (`RunFlow.world_stood`, `day_planned`), each carrying the walk's spec and its world, and its end
## as the domain event on the bus it is handed (`day_ended`), which the page's counter
## (`VisitCounter`) hears too, so a day ended through the day's own finish path, an escape section
## included, is counted and logged without remembering either channel. **Every spec is watched the
## same way**: what it needs of a world it asks the world (`DayWorld`), and what differs between a
## day and a section of the escape is the spec's own words in the header and the lines. `main` only
## builds it, hands it what no world holds (`watch()`), opens it once per boot (`open()`) and closes
## it when the run is left (`close()`).
##
## **And it is where game logic's trace comes from.** `trace` writes into the run log; `main`
## hands it to everything it builds, so nothing that decides anything names the log itself.

## The run log (`Telemetry`), handed in by `setup()`: the one `main` keeps under the sitting, or a
## suite's own.
var _log: Telemetry
var _config: RunConfig
## The run this boot plays, handed in by `setup()`: whose seed each walk's header names, and what the
## observer is handed for the blocks a calm arrival names.
var _run: RunState
## The trace handed to game logic: every line it is given goes into the run log, or nowhere while
## no log is open.
var trace := RunTrace.new()

## Null until a world stands while a log is open — with telemetry off there is no observer in the
## tree at all, rather than one checking a flag sixty times a second.
var _observer: TelemetryObserver
## What every walk is watched with besides its world, handed in by `watch()`: the day's clock, the
## resistance (null where the run has none, as in the escape) and the screen-edge badges.
var _clock: DayController
var _resistance: ResistanceDirector
var _edge: DangerEdge
## The world the walk being walked stands in (`RunFlow.world_stood`), null before the first: what a
## day's header names its city seed by, and what its plan lines and dawn and dusk maps are drawn from
## where it is a city.
var _world: DayWorld
## Whether the walk being started is a retry (`RunFlow.world_stood`), for its `start` line.
var _restarted := false

## Hands the session the run log, the run's configuration, the bus whose day ends it writes down,
## the run flow whose walks it heads and watches, and the run it is the log of.
func setup(run_log: Telemetry, config: RunConfig, bus: Node, flow: RunFlow, run: RunState) -> void:
	_log = run_log
	_config = config
	_run = run
	trace = RunTrace.new(run_log.note)
	flow.world_stood.connect(_on_world_stood)
	flow.day_planned.connect(_on_day_planned)
	bus.day_ended.connect(_on_day_ended)

# ------------------------------------------------------------- open and close ---

## Opens the run log for the run this boot plays, after its seed is settled and before anything is
## generated, so the log opens on the seed it is a trace of. Off with `--no-telemetry`; on
## otherwise, because a trace behind a flag is a trace the person playtesting has to remember to
## turn on — a player-facing opt-out, answered on every build. `played` is whether a person is at
## the controls (`Telemetry.begin_run()`).
##
## **`keep_an_open_log` keeps a log already open**: the run is the same one going on, so it keeps
## writing the log it has — the escape's boot after day 14's hand-over, and a normal run carried on
## from its checkpoint. The log lives under the sitting and outlives the scene reload either came
## through, and opening again would close it and start a second folder for one run.
func open(run_seed: int, played: bool, keep_an_open_log: bool) -> void:
	if _config.no_telemetry:
		return
	if keep_an_open_log and _log.is_active():
		return
	_log.begin_run(run_seed, played)

## Closes the run log: the run is left, by the held restart, a quit or the window closing. Every
## line is already on disk; this closes the handle tidily.
func close() -> void:
	_log.end_run()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		close()

## A picture of this frame and a line saying where, asked for by a person (`P`).
func picture(context: String) -> void:
	_log.snapshot_now("asked for a picture at %s" % context)

## A short burst of frames, asked for by a person (`B`).
func burst(context: String) -> void:
	_log.start_burst("asked for an animation burst at %s" % context)

# -------------------------------------------------------------------- watching ---

## What every walk of the boot is watched with that no world holds: the day's clock, the resistance
## (null in the escape, which has no subquest) and the screen-edge badges. `main` hands them once, as
## its first world stands, before the walk is announced; the observer itself is built when the first
## world stands while a log is open, and handed each walk's world as it stands.
func watch(clock: DayController, resistance: ResistanceDirector, edge: DangerEdge) -> void:
	_clock = clock
	_resistance = resistance
	_edge = edge

## **Built after the world it watches, and processed after it too.** Siblings process in tree order,
## and the observer stamps each line with the day's clock and reads the resistance and the
## screen-edge badges, so it has to run after `DayController`, `ResistanceDirector` and
## `DangerEdge` have moved this frame — or every line carries the frame before's time and
## it watches one frame past a day's end. The session is built first, because its trace is handed to
## everything built after it; so the moment it starts watching — as the first world stands — it
## moves itself to the end of its parent, where the world it watches already stands and whatever is
## added later (the escape's city after its building) still comes after it.
func _new_observer() -> TelemetryObserver:
	if get_parent():
		get_parent().move_child(self, -1)
	var watcher := TelemetryObserver.new(_log)
	watcher.name = "Telemetry"
	# Part of the game, not the frame around it: it stops with the pause like the day it watches.
	watcher.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(watcher)
	watcher.setup(_run, _clock, _resistance, _config.spikes_requested, _edge)
	return watcher

# ---------------------------------------------------------------------- a walk ---

## A walk's world stands, before anything is dressed or placed in it: the walk's header — placing it
## is what writes the walk's `arc`, `roll` and `contact` lines, and they belong under today's header
## rather than yesterday's — and the observer pointed at the world. A day heads its section with its
## act and its city's seed, a section of the escape with its own words, each under its own day
## number.
func _on_world_stood(spec: DaySpec, world: DayWorld, restarted: bool) -> void:
	_world = world
	_restarted = restarted
	var day := spec.day_number()
	if _a_section(spec):
		_log.begin_section(day, spec.title, _run.header.run_seed, spec.seconds_on_the_clock())
	else:
		_log.begin_day(day, Tuning.act_for_day(day), _run.header.run_seed,
				world.city().map.city_seed(), _config.day_length_for(day))
	if not _log.is_active():
		return
	if not _observer:
		_observer = _new_observer()
	var city := world.city()
	if city:
		_observer.watch(world.map(), world.events(), world.player(), world.baby(), city.map,
				city.streets(), city.crowd.sources, _section_name(spec))
	else:
		_observer.watch(world.map(), world.events(), world.player(), world.baby(), null, null,
				null, _section_name(spec))

## Whether `spec` is one of the escape's sections, which the log heads and names by its own words.
static func _a_section(spec: DaySpec) -> bool:
	return spec.section_kind() != DaySpec.Section.NONE

## The words a section of the escape is named by in the observer's lines, "" on a day.
static func _section_name(spec: DaySpec) -> String:
	match spec.section_kind():
		DaySpec.Section.BUILDING:
			return "the building"
		DaySpec.Section.CITY:
			return "the city"
	return ""

## The shape of the walk, written once everything has been placed. On a day that grows its streets:
## what is shut, where the calm is, and what is out — the three things a reader needs before any line
## below them means anything; then in any city the same as a picture, the dawn map; then her `start`
## line. The escape's city writes its own `plan finale:` line as it is planned, and the building has
## no city map to draw.
func _on_day_planned(spec: DaySpec, world: DayWorld) -> void:
	var city := world.city()
	if city and spec.closes_the_streets():
		_log.note("plan", "closed: %s" % city.closure_summary())
		_log.note("plan", "calm: %s" % city.calm_summary())
		_log.note("plan", "events: %s" % city.event_summary())
	if city:
		_log.write_map(city.map, spec.day_number(), city.streets().closures(),
				city.streets().route_tree(), world.events().plans())
	if _observer:
		_observer.start(_restarted)

## The walk's end: the outcome above the nerve it cost, timestamped where it happened, and the dusk
## picture — the trail she left and the marks she reached against the corridor the day planned,
## the one thing the dawn map cannot say — before the section closes, so it belongs to the day it
## is of. The building has no city map to draw one on.
func _on_day_ended(day: int, result: GameEnums.DayResult, cause: String, _elapsed: float) -> void:
	if not _world:
		return
	if _observer:
		_observer.day_finished(result, cause)
	# **Not a ternary.** `_observer.trail() if _observer else []` assigned into a typed
	# `Array[Vector3]` throws at runtime when the `else` side runs, since a bare `[]` is untyped —
	# and that side is every build with telemetry off.
	var trail: Array[Vector3] = []
	var met: Dictionary = {}
	if _observer:
		trail = _observer.trail()
		met = _observer.met_events()
	var city := _world.city()
	if city:
		_log.write_map(city.map, day, city.streets().closures(), city.streets().route_tree(),
				_world.events().plans(), true, trail, met)
	_log.end_day()
