class_name FinaleController
extends Node
## The escape, as a sequence: the building, then the city, on one clock.
##
## **It is not a day and it is not a second `DayController`.** Everything a day's clock already
## does is exactly what the finale wants — count down, emit `EventBus.day_time_changed` so the HUD
## draws the clock, end on the meter reaching 100, on a hard fail and at zero, and stand still
## under `--invincible` (`DayController._ignores_loss`). What the finale does *differently* is only
## what happens at the end: a day spends a Nerve and moves the calendar, and a lost section instead
## starts again where it began, with the clock back at full length and the Nerves untouched
## (*"sounds good at that point you earned it"*). So this owns a `DayController` and turns its
## `day_finished` into a restart, rather than teaching that class a second mode: a finale mode on it
## would have to disable the home win, the calendar and the Nerve, which is more of that file than
## this whole class is.
##
## **The clock is one clock for both sections.** Walking out of the service exit does not restart
## it; only a loss does. At zero the way out is gone — the bridge or the tunnel collapses, or
## something of that shape — and the section restarts like any other loss.
##
## **Where she is put is `main`'s**, not this class's: this says *which section is starting* and
## `main` answers with the hallway or the service exit, because only `main` holds the building and
## the city. `section_started` fires for a fresh section and for a restarted one alike, so the
## placement is written once.

## Which half of the escape is running. Passed across script boundaries as an `int` — a
## cross-script enum is not the same type as itself as a parameter — see the **godot** skill.
enum Section { NONE, BUILDING, CITY }

## A section has begun, fresh or restarted: `main` puts her at its own start and says its hint
## line. `restarted` is false the first time each section is entered and true for every retry.
signal section_started(section: int, restarted: bool)
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

## How long the whole sequence runs. `--day-length` compresses it exactly as it compresses a day,
## so a rig can reach the timeout without sitting through three minutes; there is no finale-only
## flag, because the question the flag answers is the same one.
static func length() -> float:
	var override := DevFlags.day_length_override()
	return override if override > 0.0 else Tuning.FINALE_LENGTH_SECONDS

## Starts the sequence at `at_section` — `BUILDING` for the ordinary run through the escape, `CITY`
## for a rig booted straight onto the street. Starts the clock; `enter_city()` below does not.
func begin(at_section: int) -> void:
	is_over = false
	section = at_section
	_clock.start(length())
	section_started.emit(section, false)

## The service exit, reached: the second section begins on the clock the first one has been
## spending. Deliberately not `begin()` — a sequence with one clock cannot restart it half way
## through, which is the whole of what "one clock counting through both sections" means.
func enter_city() -> void:
	section = Section.CITY
	section_started.emit(section, false)

## Capture, the meter at 100 and the clock at zero all arrive here, because all three are a day's
## own losing paths and `DayController` already tells them apart. Every one of them restarts the
## section she was in with a full clock; nothing spends a Nerve, and `GameState` is not touched at
## all, which is what "at no Nerve cost" is in code rather than in prose.
func _on_section_lost(_result: GameEnums.DayResult) -> void:
	if is_over:
		return
	_clock.start(length())
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

func is_running() -> bool:
	return _clock.is_running()
