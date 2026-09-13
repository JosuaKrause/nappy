class_name InteriorEvents
extends Node
## The escape's first section, inside the building: a mouse, a masked man on one stairwell, a fire
## on the other, steam in the basement, and the explosions going off outside.
##
## **The smallest thing that can host an `EventInstance`**, and deliberately not an `EventManager`.
## That class is a day: a plan streamed around a walking player, a director owing rows ahead of
## her, one-shots, scars, successors, detentions and city-wide announcements, all of it stated over
## a `CityMap` this building does not have. What is wanted here is *"relatively minimal"* — at most
## one of each — so what this does is the four things an instance actually needs from whatever owns
## it: put it in the world, tell it where she is, sum what it contributes, and fire the hard fail
## when one of them reaches her. Everything else about an event — the telegraph, the field, the
## path, the pursuit, the drawing — is `EventInstance`'s own and works unchanged indoors.
##
## **The pressure is the same two meters.** `InteriorScene` is a `WorldContext` and asks this for
## its excitement, so the baby is woken by a mouse in the basement in exactly the way she is woken
## by a dog on a pavement.
##
## **The explosions have no position at all.** Outdoors they are placed on streets and leave
## craters where they land; indoors there is no street to land on and nothing to see, so what an
## explosion *is* in here is a beat: every `Tuning.FINALE_EXPLOSION_INTERVAL` the windows flash and
## the meter takes a hit, wherever in the building she is standing. That is the same row's field
## reduced to the only part of it that reaches through a wall.

## How much an explosion outside costs her, as points on the meter, one bang at a time. Taken from
## the row's own field rather than invented: `finale_explosion` emits its `intensity` for its
## `duration`, and a building is not a place she can walk out of the blast's way in, so what lands
## indoors is that whole product — one charge, at the moment of the bang.
##
## **Applied through a source rather than written at the baby.** Excitement is a pure query
## (`docs/EVENTS.md`, "Excitement is a pure query") and nothing may write to `Baby.excitement` from
## outside, so the bang is a live `EventInstance` of the same row, standing where she is, for as
## long as the row says it lasts.
const _EXPLOSION_ID := "finale_explosion"
const _MOUSE_ID := "alley_mouse"
const _PURSUER_ID := "masked_pursuer"
const _STEAM_ID := "basement_steam"
const _FIRE_ID := "burning_building"
## How far either side of where it is placed the steam drifts, in tiles. Two, so its beat stays
## inside one straight band of the basement rather than turning one of the corridor's corners —
## a paced route is a line and the corridor is not one for its whole length.
const _STEAM_DRIFT_TILES := 2

var _interior: InteriorScene
var _instances: Array[EventInstance] = []
var _player: Node2D
var _hard_failed := false
var _seed := 0
var _until_the_next_explosion := 0.0
## Which stairwell the fire closes — "left" or "right". Drawn from the run seed, so a run is the
## same run twice; the masked man takes the other one, which is the whole of why the fire is worth
## having: the way past a fire is the other egress, and the other egress has somebody on it.
var _burning_side := "left"

func setup(interior: InteriorScene, rng: RandomNumberGenerator) -> void:
	_interior = interior
	_interior.events = self
	_seed = rng.randi()
	restart()

## Clears whatever is standing and places the section again — called once at setup and again every
## time the section is lost. Deterministic from the run seed, so a retry is the same building
## rather than an easier one; `_seed` is drawn once in `setup()` and reused, not redrawn here.
func restart() -> void:
	for instance in _instances:
		instance.queue_free()
	_instances.clear()
	_hard_failed = false
	_until_the_next_explosion = Tuning.FINALE_EXPLOSION_INTERVAL
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	_burning_side = "left" if rng.randf() < 0.5 else "right"
	_place_the_fire(rng)
	_place_the_masked_man()
	_place_the_basement(rng)

## Which stairwell is shut. Read by `tests/test_interior.gd`, which asserts the other one is still
## walkable — *"there might be a fire on one staircase forcing us to use the other staircase (all
## buildings have two egresses)"* is a statement about both of them, not only the burning one.
func burning_side() -> String:
	return _burning_side

func instances() -> Array[EventInstance]:
	return _instances

# ----------------------------------------------------------------- placement ---

## The fire, on a **turn** landing rather than a floor landing.
##
## A floor landing has that floor's own door one tile beside it, and the fire's body is wider than
## that — so a fire there would close the way out of the stairwell as well as the way down it, and
## the answer to it would be walking back up rather than stepping through a door. On the
## half-landing between two floors it closes exactly one flight: both floor landings above and
## below it keep their doors, so the way past is into the hallway and along to the other shaft,
## which is the reason the two stairwells are at opposite ends of the hallway in the first place.
func _place_the_fire(rng: RandomNumberGenerator) -> void:
	var landings := _turn_landings(_burning_side)
	if landings.is_empty():
		return
	var at: Vector2i = landings[rng.randi_range(0, landings.size() - 1)]
	_spawn(_without_its_aftermath(EventCatalogue.by_id(_FIRE_ID)), _interior.tile_to_world(at))

## The masked man, at the foot of the stairwell the fire did not take, running its whole height.
## Two points is the whole path: every landing in a shaft sits on one column, so a line up that
## column is the shaft, and the flights swing either side of it — which is what makes stepping off
## a landing and onto a flight a way of not being on his line as well as a way of going down.
func _place_the_masked_man() -> void:
	var side := "right" if _burning_side == "left" else "left"
	var bottom: Vector2i = _interior.waypoint("stairwell_%s:landing_lobby" % side)
	var top: Vector2i = _interior.waypoint("stairwell_%s" % side)
	if bottom == InteriorScene.NOWHERE or top == InteriorScene.NOWHERE:
		return
	var from := _interior.tile_to_world(bottom)
	var path := PackedVector2Array([from, _interior.tile_to_world(top)])
	_spawn(EventCatalogue.by_id(_PURSUER_ID), from, path)

## The mouse and the steam, a third and two thirds of the way along the basement's own corridor.
##
## Measured as a walk from the entry rather than written as tile offsets, so neither depends on the
## basement's three bands staying where they are: the corridor is one route with no branches, so
## "a third of the way along it" is a well-defined place however it is laid out, and both stand
## somewhere she has to pass rather than somewhere she might.
func _place_the_basement(rng: RandomNumberGenerator) -> void:
	var walk := _interior.basement_walk()
	if walk.size() < 4:
		return
	var mouse_at: Vector2i = walk[walk.size() / 3]
	var steam_at: int = walk.size() * 2 / 3
	_spawn(EventCatalogue.by_id(_MOUSE_ID), _interior.tile_to_world(mouse_at))
	# The steam paces a stretch of the corridor rather than standing in it — see the row's own
	# docstring for why a vent with a body would leave no line to walk down here. Its beat is a
	# couple of tiles either side of where it is placed, which is inside one band of the basement
	# rather than round one of its corners, so it drifts along the passage rather than across it.
	var from: Vector2i = walk[maxi(0, steam_at - _STEAM_DRIFT_TILES)]
	var to: Vector2i = walk[mini(walk.size() - 1, steam_at + _STEAM_DRIFT_TILES)]
	_spawn(EventCatalogue.by_id(_STEAM_ID), _interior.tile_to_world(walk[steam_at]),
			PackedVector2Array([_interior.tile_to_world(from), _interior.tile_to_world(to)]))
	# The mouse's dash is built from the alley it stands in when there is a map to ask; indoors
	# there is none, so `EventInstance` gives it its own short crossing and the roll is spent here
	# only to keep this function's own stream advancing with the rest of the section.
	rng.randf()

## Every half-landing in one shaft: a `LANDING` tile that is not one of the four named floor
## landings. Asked of the plan rather than recomputed from the switchback's own arithmetic, so a
## change to the flight length moves the fire with it.
func _turn_landings(side: String) -> Array[Vector2i]:
	return _interior.turn_landings("stairwell_%s" % side)

# -------------------------------------------------------------- the instances ---

func _spawn(def: EventDef, at: Vector2, path := PackedVector2Array()) -> EventInstance:
	if not def:
		return null
	var instance := EventInstance.new()
	# No `CityMap`: every question `setup()` asks one of it — which pavement band to centre on,
	# which way a spread lies, which alley a mouse crosses — is about a lattice this building does
	# not sit on, and `EventInstance` already answers all three for a caller with no map.
	instance.setup(def, at, path)
	_interior.add_entity(instance)
	_instances.append(instance)
	return instance

## A row with the marks it leaves on a *run* taken off it — the scar it records and the row it
## calls in when it is first seen. The fire is the caller: outdoors a burning building leaves a
## shell on that corner for the rest of the run and summons a fire engine down the street, and
## neither means anything in a stairwell on the last night. A derived copy, never a mutation, for
## the reason `EventDef.at_heat()` gives; `shape` is carried by hand because it is a plain
## `RefCounted` field that `Resource.duplicate()` does not copy.
static func _without_its_aftermath(def: EventDef) -> EventDef:
	var variant: EventDef = def.duplicate()
	variant.shape = def.shape
	variant.scar_id = ""
	variant.spawns_on_sight = ""
	return variant

func _physics_process(delta: float) -> void:
	_retire_finished()
	_explode_every_so_often(delta)
	if not _find_player():
		return
	_tell_them_where_she_is()
	_check_hard_fails()

## The bang outside, on the shared clock. Section one has no street for an explosion to stand on,
## so what happens is the two halves of one that reach through a wall: every window in the building
## goes white for a frame or two, and a live instance of the same row stands where she is for as
## long as its own `duration` — so the meter is charged by an ordinary excitement source rather
## than by anything writing at the baby.
func _explode_every_so_often(delta: float) -> void:
	_until_the_next_explosion -= delta
	if _until_the_next_explosion > 0.0:
		return
	_until_the_next_explosion = Tuning.FINALE_EXPLOSION_INTERVAL
	_interior.flash_windows()
	if not _find_player():
		return
	# Its telegraph is spent before the flash rather than after it: what the windows say is *it has
	# already happened*, so the row is handed to the world with its notice already over.
	var burst := _spawn(EventCatalogue.by_id(_EXPLOSION_ID), _player.global_position)
	if burst:
		burst.resume(burst.def.telegraph_time, 0.0, INF)

func _retire_finished() -> void:
	var survivors: Array[EventInstance] = []
	for instance in _instances:
		if instance.is_finished:
			instance.queue_free()
		else:
			survivors.append(instance)
	if survivors.size() != _instances.size():
		_instances.assign(survivors)

func _find_player() -> bool:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player != null

## Hands every instance her position, the same way `EventManager` does and for the same reason: she
## is found once a frame in one place, and an `EventInstance` has never had to know she exists.
func _tell_them_where_she_is() -> void:
	var stroller := _player as Stroller
	var running: bool = stroller != null and stroller.run_excess_ratio() > 0.0
	var awake: bool = stroller == null or stroller.baby_is_awake()
	for instance in _instances:
		instance.player_at = _player.global_position
		instance.player_running = running
		instance.baby_awake = awake

## Being caught on the stairs ends the section. `EventBus.hard_fail_triggered` is the same signal a
## day's own lethal rows fire, so `FinaleController`'s clock hears it through `DayController`
## exactly as it hears an abduction outdoors — nothing here has to know what a section is.
func _check_hard_fails() -> void:
	if _hard_failed:
		return
	for instance in _instances:
		if instance.is_lethal_at(_player.global_position):
			_hard_failed = true
			EventBus.hard_fail_triggered.emit(instance.def.id)
			return

# ------------------------------------------------------------ WorldContext ---

func excitement_sources_at(world_position: Vector2) -> Array:
	var sources: Array = []
	for instance in _instances:
		var contribution := instance.contribution_at(world_position)
		if contribution > 0.0:
			sources.append([instance, contribution])
	return sources

func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for pair in excitement_sources_at(world_position):
		total += pair[1]
	return total
