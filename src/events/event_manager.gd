class_name EventManager
extends Node
## Owns the live events for one day: spawns them from the scheduler's plan, sums their
## excitement, retires them when they finish, and fires hard fails.
##
## Lookup is a linear scan. The architecture sketch called for a spatial hash, but the
## budget formula tops out around 32 concurrent events on the last day — 32 distance
## checks per physics frame is nothing, and a hash would be more code with more ways to be
## subtly wrong. Revisit if an act ever wants hundreds of sources at once.

var _instances: Array[EventInstance] = []
var _aura: EventAuraLayer
var _city: City
var _map: CityMap
var _player: Node2D
var _hard_failed := false

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map
	_aura = EventAuraLayer.new()
	_aura.name = "Auras"
	_aura.track(_instances)
	city.add_aura_layer(_aura)

## Clears yesterday and spawns today. `consumed_one_shots` is appended to in place.
func start_day(day: int, rng: RandomNumberGenerator, consumed_one_shots: Array[String]) -> void:
	clear()
	_hard_failed = false
	for plan in EventScheduler.build_day(day, rng, _map, consumed_one_shots, GameState.scars):
		_spawn(plan)

func clear() -> void:
	for instance in _instances:
		instance.queue_free()
	_instances.clear()

func _spawn(plan: EventScheduler.Planned) -> void:
	_instances.append(_create(plan.def, plan.position, plan.path))

## Builds an instance, puts it in the world, and records any permanent mark it leaves.
## Everything that puts an event on the map goes through here, so a scar can never be
## missed by whichever path created the event.
func _create(def: EventDef, at: Vector2,
		path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	_city.add_entity(instance)
	if def.scar_id != "":
		# A scar is where the city stopped being recomputable: it exists because of what
		# happened on an earlier day, so from day 4 onwards the map depends on run history.
		Telemetry.note("scar", "%s left at %s by %s" % [
			def.scar_id, TelemetryLog.tile(_map.world_to_tile(instance.global_position)),
			def.id])
		GameState.add_scar(def.scar_id, instance.global_position)
		_mark_the_block(def.scar_id, instance.global_position)
	return instance

## An event that leaves a scar may also move the block it happened to along its arc — if the
## arc was waiting for exactly that cause. A fire in a block whose plan has no fire in it
## leaves the shell and changes nothing else, which is what keeps the city coherent.
##
## The block presents its new purpose *the next morning*, not immediately: `CityMap.repaint`
## runs at the start of a day, so the fire burns today and the street is ashes tomorrow.
func _mark_the_block(scar_id: String, at: Vector2) -> void:
	var cause: int = _CAUSES.get(scar_id, -1)
	if cause < 0:
		return
	GameState.city_state.apply_cause(_map.block_plans, _map.block_at(at),
			cause as GameEnums.BlockCause, GameState.day)

## Which scars move a block along its arc. Keyed by scar id rather than by event id, because
## what matters to a block is what was left behind, not which siren left it.
const _CAUSES := {
	"burnt_shell": GameEnums.BlockCause.FIRE,
	"barricade": GameEnums.BlockCause.MILITARY,
}

## Adds an event outside the day's plan. Used by the resistance director to plant the
## robbery that may be waiting where a contact is.
func spawn_extra(def: EventDef, at: Vector2) -> EventInstance:
	var instance := _create(def, at)
	_instances.append(instance)
	return instance

## Retires every city-wide source. The loudspeakers cut out mid-sentence, and for the
## first time since the masts went up on day 5 there is no floor under the meter — the
## good ending's reward is that the last walk home is the easiest in the game.
## Returns how many were silenced.
func silence_city_wide() -> int:
	var silenced := 0
	for instance in _instances:
		if instance.def.city_wide and not instance.is_finished:
			instance._finish()
			silenced += 1
	return silenced

func active_count() -> int:
	return _instances.size()

func instances() -> Array[EventInstance]:
	return _instances

# ------------------------------------------------------------ WorldContext ---

func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for instance in _instances:
		total += instance.contribution_at(world_position)
	return total

# ------------------------------------------------------------------ ticking ---

func _physics_process(_delta: float) -> void:
	_retire_finished()
	_check_hard_fails()

func _retire_finished() -> void:
	var survivors: Array[EventInstance] = []
	var successors: Array[EventInstance] = []
	for instance in _instances:
		if instance.is_finished:
			var successor := _successor_of(instance)
			if successor:
				successors.append(successor)
			instance.queue_free()
		else:
			survivors.append(instance)
	if successors.is_empty() and survivors.size() == _instances.size():
		return
	survivors.append_array(successors)
	# The aura layer holds this same array by reference, so it must be updated in place
	# rather than reassigned.
	_instances.assign(survivors)

## An event that leaves something behind where it stopped — how a fire engine ends its run
## at a fire. The successor is placed at the finishing position, not at a planned tile, so
## the two are always consistent.
func _successor_of(instance: EventInstance) -> EventInstance:
	if instance.def.spawns_on_finish == "":
		return null
	var def := EventCatalogue.by_id(instance.def.spawns_on_finish)
	if not def:
		push_error("event '%s' spawns unknown '%s'"
				% [instance.def.id, instance.def.spawns_on_finish])
		return null
	return _create(def, instance.global_position)

func _check_hard_fails() -> void:
	if _hard_failed:
		return
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if not _player:
			return
	for instance in _instances:
		if instance.is_lethal_at(_player.global_position):
			_hard_failed = true
			EventBus.hard_fail_triggered.emit(instance.def.id)
			return
