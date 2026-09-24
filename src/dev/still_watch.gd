class_name StillWatch
extends Node
## Dev tool: `--quit-when-still [seconds]` ends the run, picture in hand, the moment she has moved
## once and then gone nowhere for a while — the player's own request (asked for 2026-09-23: "can we
## have a flag for automatically taking a screenshot and terminating the game if the player doesn't
## move for a second or so?"), and it also "turns every place the rig wedges into a picture" under
## `--route` (`src/dev/route_rig.gd`), since a leg the rig cannot get past is exactly a mother who
## has stopped moving.
##
##     godot --path . -- --quit-when-still [seconds]
##
## **It counts her position, not her input or her `velocity`.** A mother pushing into something she
## cannot pass is held by `move_and_slide()` at (or near) zero velocity the same way a released key
## is, and `Stroller.is_idle()` — built for the baby's own sleepiness read — cannot tell the two
## apart; reading `global_position` instead is what makes the flag answer "did she actually get
## anywhere" rather than "is a key down", and it is what lets a human's hands (`tools/run.sh`) and
## `RouteRig`'s scripted input (`--route`, which presses the same `TouchControls._set_axis()` a
## human's held key does) trigger it on exactly the same terms.
##
## **Watched only while the day is running, not paused, and not on a brief, summary or death
## screen** — three separate-sounding conditions answered by two reads. `DayController.is_running()`
## is false before a day exists and stays false once a lost or won day has set `phase` to `OVER`
## (`day_controller.gd`'s own `_end()`), which is exactly the death screen's own gate; the day brief
## and the day summary both pause the tree to show themselves (`DaySummary._present()`), so
## `get_tree().paused` is what excludes both of those without a third flag naming either by name.
##
## **Reuses `AutoScreenshot`'s own `_capture()`** — the headless guard, the wait for
## `RenderingServer.frame_post_draw`, the save, the stdout line and the quit — through
## `AutoScreenshot.immediate()`, rather than a second writer of the same picture. This file owns
## only the stillness heuristic and where the picture goes.
##
## Not put through `main._pauses_with_the_game()`: unlike a node that *is* the game and must stop
## outright when the tree pauses, this one wants to keep receiving `_process()` calls through a
## pause so it can read `get_tree().paused` itself and freeze the hold rather than losing track of
## it — the same reasoning `TelemetryObserver._process()` follows for `DayController.is_running()`.

## How far she may drift from wherever she last effectively stopped and still count as standing
## there. Smaller than the route rig's own `_STUCK_DISTANCE` (8px, `src/dev/route_rig.gd`), whose
## check samples once every half second — a radius that loose would tolerate proportionally more
## drift here, since this accumulates every frame rather than sampling one snapshot at a time.
const STILL_RADIUS := 4.0

## "About a second" — the player's own phrase for the hold; see `DevFlags.quit_when_still_seconds()`,
## which this constant duplicates for the sole caller (`tests/test_still_watch.gd`) that wants the
## default without going through the command line at all.
const DEFAULT_SECONDS := 1.0

var _city: City
var _player: Stroller
var _day: DayController
var _seconds := DEFAULT_SECONDS

## Whether she has moved past `STILL_RADIUS` from wherever `_anchor` currently sits — before this
## is true, standing at the doorstep for the opening seconds of a day must never trigger anything.
var _armed := false
## Wherever she last effectively stopped, or `Vector2.INF` before the first sample has ever arrived.
var _anchor := Vector2.INF
## Seconds accumulated at `_anchor` since it was last set, only while `_feed()` was called `active`.
var _elapsed := 0.0
## Set the moment the picture is asked for, so a still-running instance (the capture itself takes
## a frame or two to land) never asks twice.
var _done := false

func setup(city: City, player: Stroller, day: DayController, hold_seconds: float) -> void:
	_city = city
	_player = player
	_day = day
	_seconds = hold_seconds

func _process(delta: float) -> void:
	if _done:
		return
	if _feed(_player.global_position, delta, _watching()):
		_trigger()

func _watching() -> bool:
	return _day.is_running() and not get_tree().paused

## The pure heuristic behind the flag: an anchor at wherever she last effectively stopped, armed
## only once she has moved away from wherever she started, and a hold that restarts every time she
## moves past `STILL_RADIUS` from the anchor. `active` false — the day is not running, or the tree
## is paused — neither advances the hold nor resets it, so a hold interrupted by a pause picks back
## up where it left off rather than starting over, or (worse) firing the instant the game resumes
## on a mother who has not actually been still that long. Touches no scene tree, `City` or
## `Stroller`, so a test drives it with synthetic positions, deltas and an `active` flag alone.
func _feed(position: Vector2, delta: float, active: bool) -> bool:
	if not active:
		return false
	if _anchor == Vector2.INF:
		_anchor = position
		return false
	if position.distance_to(_anchor) > STILL_RADIUS:
		_armed = true
		_anchor = position
		_elapsed = 0.0
		return false
	if not _armed:
		return false
	_elapsed += delta
	return _elapsed >= _seconds

## Notes the moment, then hands off to `AutoScreenshot` for the picture and the quit.
func _trigger() -> void:
	_done = true
	set_process(false)
	Telemetry.note("still", "quit-when-still, %.1fs held | %s | near: %s" % [
		_seconds, TelemetryLog.tile(_city.map.world_to_tile(_player.global_position)), _nearest()])
	add_child(AutoScreenshot.immediate(_picture_path()))

## Where the picture goes: a `still/` folder beside the run's other picture kinds (`auto/`,
## `asked/`, `maps/` — see docs/TELEMETRY.md) under the run's own directory, read off
## `Telemetry.current_log().path` — the one public handle onto where a run writes anything, rather
## than a second copy of `Telemetry`'s own folder-naming. A fixed filename is enough: the flag
## quits the game the instant it fires, so a run can never write this file twice. Falls back to
## `Telemetry.DIRECTORY` itself when telemetry is off (`--no-telemetry` alongside this flag) — an
## edge case the flag was not asked to solve, but one a picture dropped into the working directory
## would answer worse than a shared, findable folder.
func _picture_path() -> String:
	var log := Telemetry.current_log()
	var dir: String = (log.path.get_base_dir() + "/still") if log and log.path != "" \
			else (Telemetry.DIRECTORY + "/still")
	DirAccess.make_dir_recursive_absolute(dir)
	return dir + "/quit-when-still.png"

## The closest live event or vehicle — the same "how far, never 'in reach'" shape
## `TelemetryObserver._nearest()` reports a chase against — cheap to ask once, at the moment the
## game is about to quit anyway, and it is what turns "she stopped here" into "she stopped here
## because of that".
func _nearest() -> String:
	var best := INF
	var describe := "nothing live"
	if _city.events:
		for instance: EventInstance in _city.events.instances():
			if instance.is_finished:
				continue
			var distance: float = instance.global_position.distance_to(_player.global_position)
			if distance < best:
				best = distance
				describe = "%s %.0fpx" % [instance.def.id, distance]
	if _city.crowd:
		for agent: CrowdAgent in _city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR:
				continue
			var distance: float = agent.global_position.distance_to(_player.global_position)
			if distance < best:
				best = distance
				describe = "vehicle %.0fpx" % distance
	return describe
