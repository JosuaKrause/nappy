class_name EventSources
extends ExcitementSources
## **A day's live events, as one set of things that charge the baby** (`ExcitementSources`), made
## by the `EventManager` that owns them and handed to the world the events stand in. Two rules are
## the events' own and live here:
##
## - **Inside a door, the door's toll is the only thing that charges.** While a region door's hold
##   is running and she is inside its trigger circle (`CheckpointController.door_holding_her_at()`),
##   the hold's flat `Tuning.CHAT_EXCITEMENT` rate is the whole answer and every other field in the
##   world is off (`holds_her_alone()`).
## - **A region boundary's structures charge as one source rather than as their sum** — *"since two
##   gates can be adjacent to each other their influence shouldn't add up"*. Every instance whose def
##   carries `EventDef.barrier_structure` is a piece of a street being held, and the strongest of
##   them at her lands; the rest are not in the pairs at all, so the meter attributes what reaches
##   the bar to the structure that was the maximum and the halo's colour follows it. Everything else
##   in the catalogue sums, which is the contract the density is built on.

## The world the events stand in, whose live instances this set answers for.
var _world: EventWorld
## The doors, asked whether one holds her.
var _checkpoints: CheckpointController

func _init(world: EventWorld, checkpoints: CheckpointController) -> void:
	_world = world
	_checkpoints = checkpoints

## Ties keep the first of the live instances, the order the day streamed them in — a stable,
## seed-determined answer rather than one that depends on floating-point luck.
func sources_at(at: Vector2) -> Array:
	var inside := _checkpoints.door_holding_her_at(at)
	if inside:
		return [[inside.excitement, inside.excitement.contribution_at(at)]]
	var sources: Array = []
	var strongest: EventExcitement = null
	var strongest_rate := 0.0
	for instance in _world.instances:
		var source := instance.excitement
		var contribution := source.contribution_at(at)
		if contribution <= 0.0:
			continue
		if instance.def.barrier_structure:
			if contribution > strongest_rate:
				strongest_rate = contribution
				strongest = source
			continue
		sources.append([source, contribution])
	if strongest:
		sources.append([strongest, strongest_rate])
	return sources

func every_source(into: Array) -> void:
	for instance in _world.instances:
		into.append(instance.excitement)

func holds_her_alone(at: Vector2) -> bool:
	return _checkpoints.door_holding_her_at(at) != null

## The one barrier structure that lands at `at` — the strongest, the same answer `sources_at()`
## keeps — or `null` when none reaches. `EventManager` tells the others they are outranked once a
## frame (`ExcitementSource.outranked`), so the caret and the halo agree with the meter about which
## body is charging her.
func strongest_barrier_at(at: Vector2) -> EventInstance:
	var strongest: EventInstance = null
	var strongest_rate := 0.0
	for instance in _world.instances:
		if not instance.def.barrier_structure:
			continue
		var contribution := instance.excitement.contribution_at(at)
		if contribution > strongest_rate:
			strongest_rate = contribution
			strongest = instance
	return strongest
