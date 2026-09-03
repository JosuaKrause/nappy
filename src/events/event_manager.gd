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
## **A day's plan and a day's live events are different things.** The scheduler plans the whole
## city at dawn, which is what keeps every invariant that is stated over a day (one usable park, a
## walkable route to it, determinism); a plan becomes an `EventInstance` only when the player comes
## within `EVENT_STREAM_RADIUS` of it, and goes away again when she leaves.
##
## The gameplay half of that is bigger than the frames it saves. Loading the day upfront gives days
## in which **zero** events ever come within reach: a twenty-second event planted across the city
## fires and finishes at dawn, unobserved, and the budget bought nothing. An event that waits for
## her is an event she meets.

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
	# The corridor the city grew this morning, before it placed its closures off it. Passed rather
	# than grown again so that the walls, the friction and the picture are all stated against one
	# tree; `RouteTree.for_day` would give the same answer, and two places agreeing by arithmetic
	# is a thing that stops being true the first time one of them takes an argument. Kept as a local
	# rather than re-read from `_city` below, for the same reason — `SealPlanner` needs the same
	# tree the catalogue's own placements were just stated against.
	var tree := _city.route_tree() if _city else RouteTree.for_day(_map, day)
	_plans = EventScheduler.build_day(day, rng, _map, consumed_one_shots, GameState.scars,
			GameState.settled_this_act(), tree, GameState.resistance_progress)
	# Off the catalogue's own budget on purpose — see `SealPlanner`'s own doc. It seals everything
	# `EventScheduler` was not permitted to touch: every street off `tree`, hard or soft, plus the
	# mouths of any through-alley that never reaches it.
	_plans.append_array(SealPlanner.plan_day(_map, day, tree, GameState.day_rng(day, "seals")))
	_director.start_day(day, _plans, GameState.day_rng(day, "ahead"))
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
	plan.live = _create(plan.def, plan.position, plan.path, not plan.was_live, plan.facing)
	# **An event that has already run picks up where it left off.** Without this a streamed-out
	# event is rebuilt from `plan.position`, which is the tile the *day* chose at dawn — so a dog
	# walker that has covered three hundred pixels teleports back to the top of its street every
	# time the player leaves its radius and returns, and at 32px/s against her 92 that is most
	# times. From outside it reads as an event that never goes anywhere.
	#
	# It resumes rather than catching up on lost time, which is the whole design of streaming: the
	# day is planned across the whole city but an event **waits** for her. Ageing it in absentia
	# would put back exactly the thing streaming exists to fix — a twenty-second event that is over
	# before anybody could reach it.
	plan.live.resume(plan.age, plan.travelled)
	plan.was_live = true
	_instances.append(plan.live)
	_spend_the_rest_of_the_group(plan)

## A set piece is planned at **every** site of a covering set and happens at exactly one of them:
## the one she reaches.
##
## This is where "the one she reaches" is decided, and it has to be here rather than anywhere
## later. The moment an event enters the world it is real — `_create` records its scar and moves
## its block along its arc — so the alternatives have to stop being possible on the same frame,
## not when it finishes.
##
## It reads like a special case and it is the opposite: the day cannot know which route she will
## take, so it offers the fire engine on every route and lets *walking* choose. Nothing here has to
## predict her, which is the whole reason the covering set is a set.
func _spend_the_rest_of_the_group(chosen: EventScheduler.Planned) -> void:
	if chosen.set_piece_group == "":
		return
	for plan in _plans:
		if plan == chosen or plan.set_piece_group != chosen.set_piece_group:
			continue
		plan.spent = true
		# A sibling cannot already be live — the group is spent the first time any of them enters
		# the world, and `stream_around` skips a spent plan — but taking one out is the only safe
		# thing to do if that ever stops being true, because a second live one is a second scar.
		if plan.live:
			_stream_out(plan)

func _stream_out(plan: EventScheduler.Planned) -> void:
	plan.age = plan.live.age
	plan.travelled = plan.live.path_travelled()
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
func _create(def: EventDef, at: Vector2, path := PackedVector2Array(), record_scar := true,
		facing := Vector2.RIGHT) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path, facing, _map)
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

## How many events are in the world right now — *what is around the player* rather than what the
## day contains; see `planned_count()` for the other question.
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
		_tell_them_where_she_is()
		_warn_about_the_ground_she_is_on()
		_check_detentions()
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
# There are no rings around dangerous things. This is the half of what replaces them that is about
# the player rather than about the thing; `Crowd` does the same for the traffic, and the two
# compose because `Stroller.warn()` keeps the loudest level rather than the last caller's opinion.

## Raises the exclamation mark when the ground she is standing on is the problem.
##
## **The mark means: this will end your day.** Two levels, and nothing else raises either.
## `SOON` is a lethal event still telegraphing whose radius already covers her — the thing has
## not happened yet and walking out is the answer, which is exactly what the fairness contract
## promises her time to do. `NOW` is one of them live with her inside its reach: one step left
## between her and the end of the day.
##
## **Raising it for any telegraphing event whose radius reaches her is the mistake to avoid.** Most
## of the catalogue is not a `hard_fail`, and for those the mark would mean *a number is about to
## move faster*, which the meter already says continuously and proportionally — a mark a player can
## correctly ignore, *"I can just keep doing what I was doing"*. The caret over an entity follows
## the same rule — **a cue that marks everything says nothing** — except that this is the one cue in
## the game that cannot afford it, because it is the only one that gives an *instruction*.
##
## The cost of that narrowness is real and is the right cost: six rows in the whole catalogue are
## lethal, so the mark is rare, and it is rarest early. That is not the cue being broken, it is the
## cue being honest about a game whose first days are barely dangerous.
##
## **And `NOW` is about the pair of them, not about the disc.** Raised for any live lethal event
## whose **outer** radius covers her, it is up across more than thirty times the area that could
## hurt her — a cyclist ends the day inside 26px and reaches 145 — and it stays up while the bike
## rides away, which is *"the flashing exclamation marks after the fact"* on the events' side of a
## fix the traffic already has in `stand_down()`.
##
## So it is two conditions: she is within `LETHAL_MARK_LEAD` seconds of the radius that ends the
## day, **and** the gap is actually shrinking at the speeds in play.
##
## The closing rate is **relative** — her velocity is in it — and that is deliberately the opposite
## of the screen-edge badge, which measures the event's own approach with the player held still.
## The two cues say different sentences. A badge says *a thing exists and is coming*, so
## her walking towards it must not raise one; this mark says *the contract is now about you*, which
## is a statement about the pair of them and is false the moment she is opening the gap. It is also
## what makes the mark work for something that never moves: a reversing lorry cannot come to her, so
## the only way it becomes about her is that she is walking into it.
func _warn_about_the_ground_she_is_on() -> void:
	var here := _player.global_position
	var body := _player as Stroller
	if not body:
		return
	for instance in _instances:
		if instance.is_finished or instance.def.city_wide or not instance.def.hard_fail:
			continue
		var gap := instance.global_position.distance_to(here) - instance.def.inner_radius
		# `SOON` is anything that cannot kill her *yet* — a telegraph running, or a pursuer that has
		# not noticed her. Without the second half a man standing in an alley raises `NOW` — one
		# step from the end of the day — from two hundred pixels away, which is the marks-everything
		# mistake arriving at the one cue that cannot afford it.
		#
		# It keeps the whole outer radius, because that is exactly what the fairness contract
		# promises her time to walk out of. Only `NOW` is about a moment.
		if instance.is_telegraphing() or instance.is_waiting():
			if gap + instance.def.inner_radius <= instance.def.outer_radius:
				body.warn(Stroller.Alert.SOON, WARNING_HOLD, WARNING_SOURCE)
			continue
		var to_her := here - instance.global_position
		if to_her.length_squared() < 1.0:
			body.warn(Stroller.Alert.NOW, WARNING_HOLD, WARNING_SOURCE)
			continue
		var closing := (instance.travel_velocity() - body.velocity).dot(to_her.normalized())
		if closing > 0.0 and gap <= closing * Tuning.LETHAL_MARK_LEAD:
			body.warn(Stroller.Alert.NOW, WARNING_HOLD, WARNING_SOURCE)

## How long a raised warning stays up. A shade longer than a physics frame, so the mark does not
## strobe on the boundary of a radius she is walking along — which is short enough that this
## side of the vocabulary never needs `stand_down()`: it is re-raised every frame it is true and
## gone a frame after it stops being.
const WARNING_HOLD := 0.35
## Named so the traffic's hold and this one cannot take each other down. See `Stroller.warn`.
const WARNING_SOURCE := &"events"

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
	# The distance it was actually sited at rather than the constant. A pursuer is sited beyond its
	# own stand-off and a cat at `AHEAD_LEAD_DISTANCE`, so printing the constant makes every
	# `ahead` line for the one row a chase is about say the wrong number.
	var crossing_point: Vector2 = path[0] if path.size() < 2 \
			else (path[0] + path[path.size() - 1]) * 0.5
	var lead := crossing_point.distance_to(body.global_position)
	var verb := "comes at her from" \
			if def.pursues or def.spawn_mode == EventDef.SpawnMode.TOWARD_PLAYER else "crosses"
	Telemetry.note("ahead", "%s %s %.0fpx in front of her at %s" % [
		def.id, verb, lead,
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

## Hands every instance her position.
##
## Here rather than in the instance for the same reason `Crowd` writes `pedestrian_ahead` rather
## than letting each car look: the player is found once a frame in one place, and an
## `EventInstance` has never had to know she exists. It is handed a point, and everything it does
## with the point is a distance.
##
## Everything gets it, not only the pursuers: *"am I out of sight yet"* is the same question asked
## by anything that is **leaving** — see `EventInstance._be_done`.
##
## The second fact handed over is whether she is running, and **`_player` is deliberately a
## `Node2D`**: the cast is here rather than on the field so that "an instance is handed a point"
## stays true of everything except the one row that has to know. A `Node2D` has no
## `run_excess_ratio`, so reading it off the untyped field is a per-frame runtime error that aborts
## this whole callback and stops the day dead — and `check.sh` cannot see it, because nothing is
## wrong until it runs.
func _tell_them_where_she_is() -> void:
	var stroller := _player as Stroller
	var running: bool = stroller != null and stroller.run_excess_ratio() > 0.0
	var awake: bool = stroller == null or stroller.baby_is_awake()
	for instance in _instances:
		instance.player_at = _player.global_position
		instance.player_running = running
		instance.baby_awake = awake

## Entering `detain_radius` of an instance that has not yet chatted locks her controls for
## `detain_seconds` — the one mechanic in the catalogue that takes them away rather than costing a
## meter. This is the one place that can actually do it: `EventInstance` only ever gets handed a
## point (`player_at`), never a `Stroller`, and `Stroller.detain()` needs the real thing. See
## `EventDef.detain_seconds`, `EventInstance.start_chat()`.
func _check_detentions() -> void:
	var body := _player as Stroller
	if not body:
		return
	for instance in _instances:
		if instance.def.detain_seconds <= 0.0 or instance.is_finished or instance.is_leaving:
			continue
		if instance.has_chatted() or instance.is_chatting():
			continue
		if instance.global_position.distance_to(body.global_position) > instance.def.detain_radius:
			continue
		instance.start_chat()
		body.detain(instance.def.detain_seconds)
		Telemetry.note("chat", "%s at %s, %.1fs, baby %s, meter %s" % [
			instance.def.id, TelemetryLog.tile(_map.world_to_tile(instance.global_position)),
			instance.def.detain_seconds,
			"awake" if instance.baby_awake else "asleep",
			("+%.0f" % Tuning.CHAT_EXCITEMENT) if instance.baby_awake else "+0 (asleep)"])

func _check_hard_fails() -> void:
	if _hard_failed or not _find_player():
		return
	for instance in _instances:
		if instance.is_lethal_at(_player.global_position):
			_hard_failed = true
			EventBus.hard_fail_triggered.emit(instance.def.id)
			return
