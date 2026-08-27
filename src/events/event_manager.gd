class_name EventManager
extends Node
## Owns the live events for one day: spawns them from the scheduler's plan, sums their
## excitement, retires them when they finish, and fires hard fails.
##
## Lookup is a linear scan. The architecture sketch called for a spatial hash, but the
## budget formula tops out around 32 concurrent events on the last day — 32 distance
## checks per physics frame is nothing, and a hash would be more code with more ways to be
## subtly wrong. Revisit if an act ever wants hundreds of sources at once.
##
## **Since M27 a day's plan and a day's live events are different things.** Playtest 04:
## *"don't load everything upfront — only load / spawn things in the surrounding few blocks of
## the player when needed."* The scheduler still plans the whole city at dawn, which is what
## keeps every invariant that is stated over a day (one usable park, a walkable route to it,
## determinism); what changed is that a plan becomes an `EventInstance` when the player comes
## within `EVENT_STREAM_RADIUS` of it, and goes away again when she leaves.
##
## The gameplay half of that is bigger than the frames it saves. Playtest 03 traced a whole day
## with **zero** events ever coming within reach: a twenty-second event planted across the city
## fires and finishes at dawn, unobserved, and the budget bought nothing. An event that waits
## for her is an event she meets.

var _instances: Array[EventInstance] = []
## Today's whole plan, sited and unsited, spent and unspent. See `EventScheduler.Planned`.
var _plans: Array[EventScheduler.Planned] = []
var _director: EventDirector
var _city: City
var _map: CityMap
var _player: Node2D
var _hard_failed := false

## How close the player has to be for a planned event to exist. `INF` turns streaming off and
## puts the whole day in the world at once, which is what a test rig with no player wants —
## `tests/test_event_manager.gd` and `tests/test_full_run.gd` are about a day's whole event set
## rather than about what one player walked past.
var stream_radius := Tuning.EVENT_STREAM_RADIUS

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map
	_director = EventDirector.new(map)

## Clears yesterday and plans today. `consumed_one_shots` is appended to in place.
##
## `focus` is where the player will be standing when the day starts, so the events already
## around the doorstep are in the world on the first frame rather than appearing during it.
func start_day(day: int, rng: RandomNumberGenerator, consumed_one_shots: Array[String],
		focus := Vector2.ZERO) -> void:
	clear()
	_hard_failed = false
	_plans = EventScheduler.build_day(day, rng, _map, consumed_one_shots, GameState.scars)
	_director.start_day(_plans, GameState.day_rng(day, "ahead"))
	stream_around(focus)

func clear() -> void:
	for instance in _instances:
		instance.queue_free()
	_instances.clear()
	for plan in _plans:
		plan.live = null
	_plans.clear()

## Brings into the world everything within reach of a point, and takes away what has gone out
## of it. Idempotent, and cheap: one distance check per planned event.
##
## The hysteresis is not a nicety. Without it a player pacing on the boundary of an event's
## reach rebuilds it every other frame, and since a rebuilt instance starts its telegraph again
## that is an event permanently crouching at her and never arriving.
func stream_around(at: Vector2) -> void:
	for plan in _plans:
		if plan.spent or not plan.is_placed():
			continue
		# A city-wide source is everywhere by definition, so there is no "near" to wait for.
		var distance := 0.0 if plan.def.city_wide else plan.distance_from(at)
		if plan.live == null:
			if distance <= stream_radius:
				_stream_in(plan)
		elif distance > stream_radius + Tuning.EVENT_STREAM_HYSTERESIS:
			_stream_out(plan)

func _stream_in(plan: EventScheduler.Planned) -> void:
	# The scar is recorded the first time the event is put in the world and never again: walking
	# back past a burnt-out shell must not re-report the fire that made it.
	plan.live = _create(plan.def, plan.position, plan.path, not plan.was_live)
	plan.was_live = true
	_instances.append(plan.live)

func _stream_out(plan: EventScheduler.Planned) -> void:
	_instances.erase(plan.live)
	plan.live.queue_free()
	plan.live = null

## Adds an event outside the day's plan and outside the streaming, at a path the caller chose.
## The director's cats arrive this way, and so does the resistance's robbery.
func _spawn_unplanned(def: EventDef, at: Vector2,
		path := PackedVector2Array()) -> EventInstance:
	var instance := _create(def, at, path)
	_instances.append(instance)
	return instance

## Builds an instance, puts it in the world, and records any permanent mark it leaves.
## Everything that puts an event on the map goes through here, so a scar can never be
## missed by whichever path created the event.
func _create(def: EventDef, at: Vector2,
		path := PackedVector2Array(), record_scar := true) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	_city.add_entity(instance)
	if def.scar_id != "" and record_scar:
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
	return _spawn_unplanned(def, at)

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

## How many events are in the world right now. Since M27 this is *what is around the player*
## rather than what the day contains — see `planned_count()` for the other question.
func active_count() -> int:
	return _instances.size()

## How many sited events the day is carrying, live or waiting to be walked past. This is the
## number that answers "is thirteen events on day one a city or a gauntlet"; `active_count()`
## answers "what is she standing in".
func planned_count() -> int:
	var total := 0
	for plan in _plans:
		if plan.is_placed() and not plan.spent:
			total += 1
	return total

## The day's plan, for the readouts and the telemetry. Not for anything that acts on it.
func plans() -> Array[EventScheduler.Planned]:
	return _plans

## Events the day has budgeted for the director to put in front of the player and has not
## spent yet.
func owed_ahead() -> int:
	return _director.owed()

func instances() -> Array[EventInstance]:
	return _instances

# ------------------------------------------------------------ WorldContext ---

func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for instance in _instances:
		total += instance.contribution_at(world_position)
	return total

# ------------------------------------------------------------------ ticking ---

func _physics_process(delta: float) -> void:
	_retire_finished()
	if _find_player():
		stream_around(_player.global_position)
		_place_what_is_owed_ahead(delta)
		_warn_about_the_ground_she_is_on()
	_check_hard_fails()
	_announce_the_city_wide_sources()

## The one kind of source that cannot be drawn over, told to the HUD instead.
##
## Announced only when it *changes*, so the HUD is not re-rendering a string sixty times a
## second for something that is true for nine days running.
func _announce_the_city_wide_sources() -> void:
	var what := ""
	for instance in _instances:
		if instance.def.city_wide and not instance.is_finished and not instance.is_telegraphing():
			what = instance.def.display_name
			break
	if what == _announced_city_wide:
		return
	_announced_city_wide = what
	EventBus.city_wide_changed.emit(what)

var _announced_city_wide := ""

# ------------------------------------------------------- the mark over her head ---
# M22. The rings are gone, and this is the half of what replaces them that is about the player
# rather than about the thing. `Crowd` has done the same for traffic since M19; the two compose
# because `Stroller.warn()` keeps the loudest level rather than the last caller's opinion.

## Raises the exclamation mark when the ground she is standing on is the problem.
##
## Two cases, and the distinction is the whole vocabulary. A telegraph whose radius **already
## covers her** is `SOON`: the thing has not happened yet and walking out is the answer, which
## is exactly what the fairness contract promises her time to do. Something lethal that is
## **live and she is inside its reach** is `NOW`: there is one step left between her and the end
## of the day.
##
## What is deliberately not warned about: a loud event she is merely near. The meter says that,
## it says it continuously and proportionally, and a mark that fires for ordinary noise is a
## mark nobody reads by day three.
func _warn_about_the_ground_she_is_on() -> void:
	var here := _player.global_position
	var body := _player as Stroller
	if not body:
		return
	for instance in _instances:
		if instance.is_finished or instance.def.city_wide:
			continue
		var distance := instance.global_position.distance_to(here)
		if instance.def.hard_fail and not instance.is_telegraphing():
			if distance <= instance.def.outer_radius:
				body.warn(Stroller.Alert.NOW, WARNING_HOLD)
		elif instance.is_telegraphing() and distance <= instance.def.outer_radius:
			body.warn(Stroller.Alert.SOON, WARNING_HOLD)

## How long a raised warning stays up. A shade longer than a physics frame, so the mark does not
## strobe on the boundary of a radius she is walking along.
const WARNING_HOLD := 0.35

## The director's half of the day: something that happens *to* her, in front of her, while she
## is walking. See `EventDirector` for why a cat is authored as a moment rather than a place.
func _place_what_is_owed_ahead(delta: float) -> void:
	var body := _player as CharacterBody2D
	if not body:
		return
	var due := _director.due(delta, body.global_position, body.velocity)
	if due.is_empty():
		return
	var def := due[0] as EventDef
	var path := due[1] as PackedVector2Array
	_spawn_unplanned(def, path[0], path)
	Telemetry.note("ahead", "%s crosses %.0fpx in front of her at %s" % [
		def.id, Tuning.AHEAD_LEAD_DISTANCE,
		TelemetryLog.tile(_map.world_to_tile(body.global_position))])

func _find_player() -> bool:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player != null

func _retire_finished() -> void:
	var survivors: Array[EventInstance] = []
	var successors: Array[EventInstance] = []
	for instance in _instances:
		if instance.is_finished:
			var successor := _successor_of(instance)
			if successor:
				successors.append(successor)
			_mark_plan_spent(instance)
			instance.queue_free()
		else:
			survivors.append(instance)
	if successors.is_empty() and survivors.size() == _instances.size():
		return
	survivors.append_array(successors)
	# Assigned in place rather than reassigned: `instances()` hands this array out by reference,
	# and the danger-edge indicator holds it across frames.
	_instances.assign(survivors)

## An event that has finished has finished for the day: its plan is spent, so walking back past
## the place it happened does not start it over. This is the half of streaming that a rebuilt
## instance would otherwise get wrong — an event is allowed to come and go while it is running,
## and is not allowed to come back once it is over.
func _mark_plan_spent(instance: EventInstance) -> void:
	for plan in _plans:
		if plan.live == instance:
			plan.live = null
			plan.spent = true
			return

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
	if _hard_failed or not _find_player():
		return
	for instance in _instances:
		if instance.is_lethal_at(_player.global_position):
			_hard_failed = true
			EventBus.hard_fail_triggered.emit(instance.def.id)
			return
