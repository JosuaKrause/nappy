class_name EventWorld
extends RefCounted
## **What every part of a day's events works over, as the manager was handed it**: the world they
## stand in, the run they belong to, the player and what she can see, and the live instances. One
## object, shared by `EventManager` and the parts it hands its work to (`EventStreaming`,
## `EventSpawner`, `WarningBoard`, `EventsAhead`, `CheckpointController`), so a world handed over
## once — a city's day, the escape's building, a rig's open ground — is the world every part sees.
## Nothing here is fetched: the manager writes each field as it is handed it.

## The live instances, in the order they came into the world. Shared by reference — the danger
## edge and the halo hold it across frames — so it is changed in place, never reassigned.
var instances: Array[EventInstance] = []
## The map of the world these events stand in (`WorldMap`): every instance is made on it, added to
## its world through it and stopped by its walls, and its blocked record holds their bodies. Open
## ground until a world is handed over, for a rig that never hands one.
var map: WorldMap = WorldMap.open_ground()
## The city's own map, for planning a day over it — its holds, its route tree, its blocks — or null
## where the world is not the city (`EventManager.setup_world()`).
var city_map: CityMap
## The city these events stand in, or null where the world is not the city.
var city: City
## The lights a car that drives stops at, the crowd's own (`EventInstance.signals`): handed over by
## the city; none in a world with no streets.
var signals: TrafficSignals
## Where the manager, the day's planning and every instance it creates write their own account for
## the run log — the city's, set before `EventManager.setup()`; silent until then.
var trace := RunTrace.new()
## The run these events belong to (`RunState`): its seed and day streams, its scars, its heat, the
## calm she has used this act and the pelican bag's draws. Handed in with the city
## (`City.run`), or by `EventManager.use_run()` for a world that is not the city.
var run: RunState
## The player, handed in by `EventManager.use_player()`, or null for none in the world.
var player: Node2D
## Today's own day number, kept for the streams drawn while the day runs (a summoned row's entry, a
## pursuer's start, the dusk fire) and for the rows a day sends (`EventCatalogue.on_foot_on()`).
var day := 0
## `--skip events`: every instance made here skips its own drawing.
var skip_drawing := false
## What a protest points at, answering a world point or `Vector2.INF` for nothing: handed in by the
## resistance (`ResistanceDirector.setup()`, its `pointable_objective()`). Unset where there is no
## resistance, and a protest then points at nothing.
var points_at := Callable()
## What she can see this frame — the one answer to "can she see it" for everything on a day
## (`VisibleView`): the screen-edge badge, the placing of what arrives from off screen, the fire's
## sighting, a chalk mark's notice (`ResistanceDirector.set_sight()`, wired to
## `EventManager.sees()` by `main`), the poster crews and the page's counter. What the resistance
## places and removes asks the siting's `DRAWING_OFF_THE_VIEW` of the same view instead. One instance for
## the day, never replaced, so a caller may keep it. Set at the top of each physics tick by
## `EventManager._look_through_the_camera()`.
var visible := VisibleView.new()

## How every figure made here moves over `map` (`Navigator`): the one handed in by
## `EventManager.setup()`, or the map's own (`WorldMap.navigator()`) where none was handed for it —
## a rig that sets the map itself.
var _navigator: Navigator

func use_navigator(navigator: Navigator) -> void:
	_navigator = navigator

func navigator() -> Navigator:
	if _navigator == null or _navigator.map() != map:
		_navigator = map.navigator()
	return _navigator

## Whether she is in the world: handed in, not freed since, and not stood aside for the title
## screen. `Stroller.stand_aside()` takes her out of the `player` group, which is the whole of
## "nobody is playing": the city plays on behind the title, and nothing streams around her, notices
## her, warns her or strikes her there, so a lethal thing on the doorstep cannot end a day nobody is
## playing. A rig's stand-in that is not a `Stroller` has no title to stand aside for.
func has_player() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	return not (player is Stroller) or player.is_in_group("player")

## `points_at` asked now, so an instance made before the resistance handed it in points too.
func where_protests_point() -> Vector2:
	return points_at.call() if points_at.is_valid() else Vector2.INF
