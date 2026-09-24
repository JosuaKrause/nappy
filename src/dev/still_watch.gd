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
## **And not while she cannot presently choose to walk somewhere.** Position-only tracking cannot
## tell a mother who has stopped moving from one who has had the choice taken off her, so `_held()`
## answers that separately for three cases, the player's own words: *"in general is_detained
## shouldn't trigger it -- same with stroller lady"* and *"yes also red light (a human player would
## like pace back and forth with a red light to minimize excitement)"* (2026-09-23), sharpened on
## 2026-09-24 (PLAYTEST-128, statements 13-14) to *"just deactivating the watch when the light is
## red and the intersection is visible. If she's stuck she will be stuck when it turns green
## still"* — a mother who is really stuck is still stuck once the light turns green, and the watch
## catches her then.
##
## - **`Stroller.is_detained()`** — the one gate every `EventDef.detain_seconds` row goes through,
##   so this alone covers `chatting_mother` ("Another mother" and her pram, 5s) and all three
##   checkpoint rows (`checkpoint_hut`, `checkpoint_gate`, `checkpoint_post`) for the whole of the
##   controls-locked part of their hold. It is the single call site (`EventManager._check_detentions()`
##   → `body.detain()`) every input-taking mechanic in the catalogue runs through, so nothing else in
##   the game needs a query of its own.
## - **`EventManager.door_holding_her_at()`** — only a `redetains` row (the three checkpoint ones)
##   ever needs this on top of `is_detained()`, because a checkpoint's own hold is a clock on the
##   instance (`EventInstance.is_chatting()`, ticked in a drawn `_process()`) and the input lock is a
##   separate clock on `Stroller` (ticked in `_physics_process()`); see that function's own note on
##   why a hold can still be running a frame after the input lock has already cleared. Read at her
##   own position, which is what the function already answers for the excitement meter.
## - **`facing_a_red_light()`** — the signalled junction nearest her among those visible on screen
##   shows her red on the main road's own light, wherever on screen she herself is standing. See
##   that function for why the nearest one decides and why her own tile no longer matters.
##
## **The hold restarts rather than resumes the instant any of these ends.** `_feed()`'s `held`
## argument re-anchors her at wherever she actually is on every frame it is true, so a mother
## released from a hut, waved off a chat or let off a curb needs the whole of `_seconds` again
## rather than being caught the instant she can move — see `_feed()`'s own note.
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
	if _feed(_player.global_position, delta, _watching(), _held()):
		_trigger()

func _watching() -> bool:
	return _day.is_running() and not get_tree().paused

## Whether she cannot presently choose to walk somewhere — see the class doc for the three cases
## and why each is needed. Touches `_city` and `_player`, so unlike `_feed()` this has no pure test
## of its own; the geometry and signal half of it (`facing_a_red_light()`) does.
func _held() -> bool:
	if _player.is_detained():
		return true
	if _city.events and _city.events.door_holding_her_at(_player.global_position):
		return true
	return facing_a_red_light(_city.map, _city.signals, _player.global_position, _visible_world_rect())

## The world-space rect the screen currently shows, computed the same way `DangerEdge.is_on_screen()`
## and `TouchControls`'s own screen-to-world reads do: `get_viewport().get_canvas_transform()` maps a
## world position to a screen one, so its inverse maps the screen's own corners back to world space.
## Kept out of `facing_a_red_light()` itself, which takes the rect as a plain argument, so that
## function stays pure and a test can hand it any rect without a viewport anywhere in reach.
func _visible_world_rect() -> Rect2:
	var inverse := get_viewport().get_canvas_transform().affine_inverse()
	var screen := get_viewport().get_visible_rect()
	var corners: Array[Vector2] = [
		inverse * screen.position,
		inverse * Vector2(screen.end.x, screen.position.y),
		inverse * Vector2(screen.position.x, screen.end.y),
		inverse * screen.end,
	]
	var rect := Rect2(corners[0], Vector2.ZERO)
	for i in range(1, corners.size()):
		rect = rect.expand(corners[i])
	return rect

## The pure heuristic behind the flag: an anchor at wherever she last effectively stopped, armed
## only once she has moved away from wherever she started, and a hold that restarts every time she
## moves past `STILL_RADIUS` from the anchor. `active` false — the day is not running, or the tree
## is paused — neither advances the hold nor resets it, so a hold interrupted by a pause picks back
## up where it left off rather than starting over, or (worse) firing the instant the game resumes
## on a mother who has not actually been still that long.
##
## **`held` is a different kind of interruption and gets a different answer.** A detention, a
## checkpoint's hold or a wait at a red light can run for several seconds with her position not
## moving at all, which is exactly what the flag is watching for — so freezing the count the way
## `active` does would let whatever had already accumulated survive the hold and fire the instant
## it ends, catching a mother the moment she is released rather than giving her a fresh `_seconds`
## to actually stand still in. So a `held` frame re-anchors at wherever she currently is and zeroes
## the count, every frame it is true, the same reset a real move past `STILL_RADIUS` gets — the
## first frame after `held` goes false starts counting from zero at that spot.
##
## Touches no scene tree, `City` or `Stroller`, so a test drives it with synthetic positions,
## deltas, an `active` flag and a `held` flag alone.
func _feed(position: Vector2, delta: float, active: bool, held: bool = false) -> bool:
	if not active:
		return false
	if held:
		_anchor = position
		_elapsed = 0.0
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

## Whether the signalled junction nearest her among those visible on screen shows her red on the
## main road's own light — the same wait a driver gets from `TrafficLight`, read for her instead of
## for a car (PLAYTEST-128.md statements 13-14: "How about just deactivating the watch when the
## light is red and the intersection is visible. If she's stuck she will be stuck when it turns
## green still").
##
## **Her own tile no longer matters, and stepping onto `ROAD` or `CROSSING` no longer ends it.**
## Earlier this held only while she stood on the junction's own sidewalk band; the player asked for
## the watch off whenever a red light is on screen at all, wherever she stands within it — a mother
## paced back and forth at the kerb, or genuinely stuck mid-crossing, reads the same light either
## way, and a truly stuck mother is still stuck once it turns green, which is when the watch catches
## her.
##
## **`view` is a world-space rect, passed in rather than read here** — see `_visible_world_rect()`,
## the one caller, for how it is built from the camera. Keeping the viewport out of this function is
## what lets a test hand it any rect directly.
##
## **Which junction, when more than one is on screen: the nearest to her, by its box centre.**
## `TrafficSignals` runs a green wave with a different offset per junction
## (`TrafficSignals._offset()`), so two junctions on screen can disagree, and "the intersection" in
## the player's own sentence is singular.
##
## **"Visible" means the junction's `Tuning.STREET_WIDTH` (6) tile box — both corridors' full width
## where they overlap, the same box `route_tree.gd` and `CityMap.junction_at()` already treat as one
## piece of ground — intersects `view`.**
##
## **Which arm is asked is fixed, not read off her heading.** The only signalled junctions are on
## the main road (`TrafficSignals.is_signalled()`), and its own light is `arm_is_vertical` true in
## `TrafficLight` — see `TrafficSignals.main_arm_is_vertical()`'s own note that a second spine would
## change this and nothing else. Green or amber on that arm is traffic moving or clearing on the
## road she would be crossing, the same red-means-go reading `TrafficLight._lamp()` draws for her.
static func facing_a_red_light(map: CityMap, signals: TrafficSignals, position: Vector2,
		view: Rect2) -> bool:
	var junction := _nearest_visible_signalled_junction(map, signals, position, view)
	if junction == Vector2i(-1, -1):
		return false
	return signals.green_for(junction, true) or signals.amber_for(junction, true)

## The signalled junction whose `Tuning.STREET_WIDTH` tile box intersects `view` and sits closest —
## by the box's own centre — to `position`, or `(-1, -1)` when no signalled junction is visible at
## all. The candidate range is `view`'s own tile footprint widened by one junction period on every
## side, so a box that starts just outside the tile range `world_to_tile` rounds `view` down to is
## never missed, clamped to `Tuning.CITY_BLOCKS` since no junction exists beyond it.
static func _nearest_visible_signalled_junction(map: CityMap, signals: TrafficSignals,
		position: Vector2, view: Rect2) -> Vector2i:
	var top_left := map.world_to_tile(view.position)
	var bottom_right := map.world_to_tile(view.end)
	var period := CityMap.period()
	var min_junction := Vector2i(CityMap.junction_index(top_left.x) - 1,
			CityMap.junction_index(top_left.y) - 1)
	var max_junction := Vector2i(CityMap.junction_index(bottom_right.x) + 1,
			CityMap.junction_index(bottom_right.y) + 1)
	var nearest := Vector2i(-1, -1)
	var nearest_distance := INF
	for jx in range(maxi(min_junction.x, 0), mini(max_junction.x, Tuning.CITY_BLOCKS.x) + 1):
		for jy in range(maxi(min_junction.y, 0), mini(max_junction.y, Tuning.CITY_BLOCKS.y) + 1):
			var junction := Vector2i(jx, jy)
			if not signals.is_signalled(junction):
				continue
			var box := map.tile_rect_to_world(
					Rect2i(junction * period, Vector2i.ONE * Tuning.STREET_WIDTH))
			if not view.intersects(box):
				continue
			var distance := position.distance_to(box.get_center())
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = junction
	return nearest

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
