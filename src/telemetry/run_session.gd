class_name RunSession
extends Node
## The run log's one owner for a boot: it opens the log for a run and closes it when the run is
## left, opens each day's and the escape's section, writes the run flow's own lines and pictures,
## and holds the `TelemetryObserver` that watches the walk.
##
## **It listens; the run flow does not call it.** What happens to a day reaches it as a domain
## event on the bus it is handed — `day_started`, `day_planned`, `day_ended`, and
## `escape_section_started` for the world an escape section is walked in — and the page's counter
## (`VisitCounter`) hears the same events, so a day ended through the day's own finish path, an
## escape section included, is counted and logged without remembering either channel. `main` only
## builds it and hands it what it is to watch (`watch_day()`, `watch_escape()`), opens it once per
## boot (`open()`) and closes it when the run is left (`close()`).
##
## **And it is where game logic's trace comes from.** `trace` writes into the run log; `main`
## hands it to everything it builds, so nothing that decides anything names the log itself.

## The run log: the `Telemetry` autoload, handed in by `setup()`. Untyped because an autoload's
## script has no `class_name` of its own.
var _log
var _config: RunConfig
## The trace handed to game logic: every line it is given goes into the run log, or nowhere while
## no log is open.
var trace := RunTrace.new()

## Null until a world is watched while a log is open — with telemetry off there is no observer in
## the tree at all, rather than one checking a flag sixty times a second.
var _observer: TelemetryObserver
## The day's city, once `watch_day()` has been handed it: what a day's section names its seed by
## and its plan lines, dawn map and dusk map are drawn from. Null in the escape.
var _city: City
## The day's clock, handed in by `watch_the_clock()` (and `watch_day()`): the day being walked is
## its `spec`, which is what a section's header is written from — its own words and length.
var _clock: DayController
## What the escape's observer is built from at its first section, once `watch_escape()` has been
## handed them; empty on a day.
var _escape_world: Dictionary = {}
## The escape's city while its section is walked — what the section's dawn and dusk maps are drawn
## from, with no corridor, since its walk is two chains and not a day's tree. Null in the building.
var _escape_city: City

## Hands the session the run log, the run's configuration and the bus whose events it writes down.
func setup(run_log: Node, config: RunConfig, bus: Node) -> void:
	_log = run_log
	_config = config
	trace = RunTrace.new(run_log.note)
	bus.day_started.connect(_on_day_started)
	bus.day_planned.connect(_on_day_planned)
	bus.day_ended.connect(_on_day_ended)
	bus.escape_section_started.connect(_on_escape_section_started)

## The observer watching this boot's walk, or null while nothing is traced.
func observer() -> TelemetryObserver:
	return _observer

# ------------------------------------------------------------- open and close ---

## Opens the run log for the run this boot plays, after its seed is settled and before anything is
## generated, so the log opens on the seed it is a trace of. Off with `--no-telemetry`; on
## otherwise, because a trace behind a flag is a trace the person playtesting has to remember to
## turn on — a player-facing opt-out, answered on every build. `played` is whether a person is at
## the controls (`Telemetry.begin_run()`).
##
## **`keep_an_open_log` keeps a log already open**: the run is the same one going on, so it keeps
## writing the log it has — the escape's boot after day 14's hand-over, and a normal run carried on
## from its checkpoint. `Telemetry` is an autoload and outlives the scene reload either came
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

## A day's world: the city, her, the baby, the day's clock, the resistance and the screen-edge
## badges. Builds the observer only when a log is open.
func watch_day(city: City, player: Stroller, baby: Baby, day: DayController,
		resistance: ResistanceDirector, edge: DangerEdge) -> void:
	_clock = day
	_city = city
	if not _log.is_active():
		return
	_observer = _new_observer()
	_observer.setup(city, player, baby, day, resistance, _config.spikes_requested, edge)

## The day's clock, whose `spec` says what each day is, before the first one starts — the escape's
## boot hands it in ahead of `watch_escape()`, whose world is built only as its first section
## begins.
func watch_the_clock(clock: DayController) -> void:
	_clock = clock

## Whether the day being walked is one of the escape's sections, by its spec.
func _walking_a_section() -> bool:
	return _clock != null and _clock.spec.section != DaySpec.Section.NONE

## The escape's walk: her, the baby, the day's clock and the badges. The observer is built at the
## first section, because that is when the log is known to be open for it; each section names its
## own world on `escape_section_started`.
func watch_escape(player: Stroller, baby: Baby, clock: DayController, edge: DangerEdge) -> void:
	_escape_world = {"player": player, "baby": baby, "clock": clock, "edge": edge}

## **Built after the world it watches, and processed after it too.** Siblings process in tree order,
## and the observer stamps each line with the day's clock and reads the resistance and the
## screen-edge badges, so it has to run after `DayController`, `ResistanceDirector` and
## `DangerEdge` have moved this frame — or every line carries the frame before's time and
## it watches one frame past a day's end. The session is built first, because its trace is handed to
## everything built after it; so the moment it starts watching it moves itself to the end of its
## parent, where the world it watches already stands and whatever is added later (the dev rigs, the
## escape's city) still comes after it.
func _new_observer() -> TelemetryObserver:
	if get_parent():
		get_parent().move_child(self, -1)
	var watcher := TelemetryObserver.new()
	watcher.name = "Telemetry"
	# Part of the game, not the frame around it: it stops with the pause like the day it watches.
	watcher.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(watcher)
	return watcher

# ----------------------------------------------------------------------- a day ---

## The day's header, before anything is placed in it: placing it is what writes the day's `arc`,
## `roll` and `contact` lines, and they belong under today's header rather than yesterday's. One of
## the escape's sections heads its own day, under its own day number and its own words.
func _on_day_started(day: int) -> void:
	if _walking_a_section():
		_escape_city = null
		_log.begin_section(day, _clock.spec.title, GameState.header.run_seed, _clock.spec.length)
		return
	if not _city:
		return
	_log.begin_day(day, Tuning.act_for_day(day), GameState.header.run_seed, _city.map.seed_used,
			_config.day_length_for(day))

## The shape of the day, written once everything has been placed: what is shut, where the calm is,
## and what is out — the three things a reader needs before any line below them means anything —
## and then the same three as a picture, then the `start` line.
func _on_day_planned(day: int) -> void:
	if _escape_city:
		# Typed, for `Telemetry.write_map()`: an untyped `[]` handed to a typed parameter fails at
		# the call. The escape's walls are events, not closures, and at dawn there is no trail.
		var no_closures: Array[RoadClosure] = []
		var no_trail: Array[Vector3] = []
		_log.write_map(_escape_city.map, day, no_closures, null, _escape_city.events.plans(), false,
				no_trail, {}, false)
		return
	if not _city:
		return
	_log.note("plan", "closed: %s" % _city.closure_summary())
	_log.note("plan", "calm: %s" % _city.calm_summary())
	_log.note("plan", "events: %s" % _city.event_summary())
	_log.write_map(_city.map, day, _city.closures(), _city.route_tree(), _city.events.plans())
	if _observer:
		_observer.start_day()

## The day's end: the outcome above the nerve it cost, timestamped where it happened, and the dusk
## picture — the trail she left and the marks she reached against the corridor the day planned,
## the one thing the dawn map cannot say — before the section closes, so it belongs to the day it
## is of.
##
## An escape section ends the same way: its outcome line, and its dusk picture when it was walked in
## the city — the building has no city map to draw one on.
func _on_day_ended(day: int, result: GameEnums.DayResult, cause: String, _elapsed: float) -> void:
	if not _city and not _walking_a_section():
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
	if _city:
		_log.write_map(_city.map, day, _city.closures(), _city.route_tree(), _city.events.plans(),
				true, trail, met)
	elif _escape_city:
		var no_closures: Array[RoadClosure] = []
		_log.write_map(_escape_city.map, day, no_closures, null, _escape_city.events.plans(), true,
				trail, met, false)
	_log.end_day()

# ------------------------------------------------------------------ the escape ---

## A section about to be walked, the first time or again after a loss, under the header its
## `day_started` opened: the observer is pointed at the world it is walked in — `world` is the
## building or the city, `events` the events walked among — and writes the `start` line, which on a
## retry says so.
func _on_escape_section_started(section: int, restarted: bool, world: Node, events: Node) -> void:
	if section == DaySpec.Section.CITY:
		_escape_city = world as City
	if _escape_world.is_empty() or not _log.is_active():
		return
	if not _observer:
		_observer = _new_observer()
		_observer.setup_escape(_escape_world["player"], _escape_world["baby"],
				_escape_world["clock"], _config.spikes_requested, _escape_world["edge"])
	if section == DaySpec.Section.BUILDING:
		_observer.watch_building((world as InteriorScene).map, events)
	else:
		_observer.watch_city(world as City)
	_observer.start_section(restarted)
