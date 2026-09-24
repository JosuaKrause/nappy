class_name FinaleController
extends Node
## The escape, as a sequence: the building, then the city, each of them a day of its own.
##
## **It is not a day and it is not a second `DayController`.** Everything a day's clock already
## does is exactly what the finale wants — count down, emit `EventBus.day_time_changed` so the HUD
## draws the clock, end on the meter reaching 100, on a hard fail and at zero, and stand still
## under `--invincible` (`DayController._ignores_loss`). What the finale does *differently* is only
## what happens at the end: a day spends a Nerve and moves the calendar, and a lost section instead
## comes up on the brief screen and starts again where it began, with the clock back at full length
## and the Nerves untouched (*"sounds good at that point you earned it"*). So this owns a
## `DayController` and turns its `day_finished` into a loss and a restart, rather than teaching
## that class a second mode: a finale mode on it
## would have to disable the home win, the calendar and the Nerve, which is more of that file than
## this whole class is.
##
## **Each section gets a full clock of its own, because each section is a day.** *"180s per
## section"*: the building and the city each start `length()` on the screen the section opens on,
## so the time spent walking down three floors is not time the city has lost. At zero the way out
## is gone — the bridge or the tunnel collapses, or something of that shape — and the section
## starts again from its own brief.
##
## **The clock is started by the brief, never by entering a section.** `begin()`, `enter_city()`
## and `restart_section()` all say only *this section is about to be walked*; `start_section()` is
## what the continue on the brief screen reaches, so the countdown cannot spend itself behind a
## screen the player has not dismissed yet.
##
## **Where she is put is `main`'s**, not this class's: this says *which section is starting* and
## `main` answers with the hallway or the service exit, because only `main` holds the building and
## the city. `section_started` fires for a fresh section and for a restarted one alike, so the
## placement is written once.

## Which half of the escape is running. Passed across script boundaries as an `int` — a
## cross-script enum is not the same type as itself as a parameter — see the **godot** skill.
enum Section { NONE, BUILDING, CITY }

## A section is about to be walked, fresh or restarted: `main` puts her at its own start and raises
## the section's brief over it. `restarted` is false the first time each section is entered and
## true for every retry. **The clock is not running yet** — `start_section()` is what the brief's
## own continue reaches.
signal section_started(section: int, restarted: bool)
## A section has been lost — taken, the meter at 100, or the clock at zero. *(2026-09-19:
## "restarting should still have the day brief for both the apartment escape and the city escape
## even if the nerves don't go down.")* `main` records what happened and then calls
## `restart_section()`, which raises that section's brief again with a fresh clock behind it.
## `result` is the `GameEnums.DayResult` the clock ended on, passed as an `int` for the same
## cross-script reason `section` is — the run log's `lost` line names it the way a day's does.
signal section_lost(section: int, result: int)
## She has reached the tunnel mouth or the bridge deck. `exit_kind` is a `CityEdge.Kind`.
signal escaped(exit_kind: int)

var section := Section.NONE
## Set once the tunnel or the bridge has been reached, so the exit check cannot fire twice while
## the epilogue's own screen is coming up.
var is_over := false

## The clock and the three losing paths, unchanged from a day. `setup(null, null)` on purpose:
## with no map and no player `DayController._is_home()` is always false, so the one thing a day
## ends *well* on — walking home asleep — can never fire here. The finale's own ending is
## `escaped`, which this class decides.
var _clock := DayController.new()
## Where the two ways out stand, in world space, or `Vector2.INF` while section one is running.
## `CityEdge.Kind` -> position.
var _exits := {}

func _ready() -> void:
	_clock.name = "Clock"
	add_child(_clock)
	_clock.setup(null, null)
	_clock.day_finished.connect(_on_section_lost)

## How long **one section** runs — a day's own length, since each section is a day.
## `--day-length` compresses it exactly as it compresses a day, so a rig can reach the timeout
## without sitting through three minutes; there is no finale-only flag, because the question the
## flag answers is the same one.
static func length() -> float:
	var override := DevFlags.day_length_override()
	return override if override > 0.0 else Tuning.FINALE_LENGTH_SECONDS

## Starts the sequence at `at_section` — `BUILDING` for a run that has handed over to the escape,
## `CITY` for a rig booted straight onto the street, or for a game closed on the street and opened
## again. The clock is not started here: the brief this raises is what starts it.
func begin(at_section: int) -> void:
	is_over = false
	section = at_section
	section_started.emit(section, false)

## The service exit, reached: the second section begins, and it begins the way the first one did —
## on its own brief, with its own full clock once that brief is dismissed. The building's clock
## stops at the door because `start_section()` is the only thing that ever sets one running, and
## the city's brief is what reaches it next.
func enter_city() -> void:
	section = Section.CITY
	section_started.emit(section, false)

## The section actually begins: a full clock, from the continue on its own brief. Called for a
## first walk through a section and for a retry alike — *"180s per section"*, so nothing a previous
## section or a previous attempt spent is carried in.
func start_section() -> void:
	_clock.start(length())

## Capture, the meter at 100 and the clock at zero all arrive here, because all three are a day's
## own losing paths and `DayController` already tells them apart. Every one of them ends the
## section she was in; nothing spends a Nerve, and `GameState` is not touched at all, which is what
## "at no Nerve cost" is in code rather than in prose.
##
## **It does not start the section again.** A lost day shows the screen between days before the
## next one begins, and a lost section owes the same pause — so this only says what happened, and
## `main` answers by writing the loss down and calling `restart_section()` below, which raises that
## section's brief. The clock stays stopped where the loss left it until that brief is dismissed:
## `DayController` has already put its phase at `OVER`.
func _on_section_lost(result: GameEnums.DayResult) -> void:
	if is_over:
		return
	section_lost.emit(section, result)

## The same section again, from its own start — what a loss leads to. `section_started` fires with
## `restarted` true, so `main` puts her back at the start and raises the brief without repeating
## the hint line she was already given on the way in. The clock is put back to full by
## `start_section()`, from that brief's own continue, so a retry cannot begin behind the screen
## announcing it.
func restart_section() -> void:
	if is_over:
		return
	section_started.emit(section, true)

## Where the two ways out of the city stand — the last walkable tile of the spine at each end of
## the map, not the point the portal's own picture is anchored at. Told rather than looked up, so
## this class holds no reference to the world — the same reason the HUD listens to `EventBus`
## instead of reading it.
func set_exits(tunnel: Vector2, bridge: Vector2) -> void:
	_exits = {CityEdge.Kind.TUNNEL: tunnel, CityEdge.Kind.BRIDGE: bridge}

## Whether `at` has reached one of the two exits, and fires `escaped` the first time it has. Asked
## once a frame by `main` while section two runs, the same way `InteriorScene.process_player()` is
## asked whether she is standing on a door.
func check_exit(at: Vector2) -> void:
	if is_over or section != Section.CITY:
		return
	for kind: int in _exits:
		if at.distance_to(_exits[kind]) <= Tuning.FINALE_EXIT_REACH:
			is_over = true
			_stop()
			escaped.emit(kind)
			return

## Stops the clock without ending anything: the sequence is over on its own terms, and a countdown
## still running behind the epilogue would eventually announce a loss over it.
func _stop() -> void:
	_clock.phase = GameEnums.DayPhase.OVER

func time_remaining() -> float:
	return _clock.time_remaining

## The section's own clock, for `TelemetryObserver` — the escape's run log is timed and gated off
## it exactly as a day's is off the day's `DayController`, which is the whole reason the observer
## can watch a section without knowing it is not a day. Read, never started or stopped, from
## outside: `start_section()` and `_stop()` are the only two things that move its phase.
func clock() -> DayController:
	return _clock

func is_running() -> bool:
	return _clock.is_running()
