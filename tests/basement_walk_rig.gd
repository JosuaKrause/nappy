extends RefCounted
## A rig that walks the escape's basement corridor, entry to exit, past its three real vents, and
## answers what the walk did to the meter. Shared by `tests/test_interior.gd`, which pins what the
## basement costs, and `tests/probes/basement_meter.gd`, which prints the table.
##
## **What is real and what is stood in for.** The vents, their clocks, the blows and the field each
## blow charges her with are `InteriorEvents` and `EventInstance` themselves, ticked the way the
## game ticks them; the corridor is `InteriorScene.basement_walk()`; the decay is the baby's own
## rule (`Baby.decay_rate()`: `Tuning.EXCITEMENT_DECAY_WALKING` times the scene's
## `decay_multiplier()` while she walks, `EXCITEMENT_DECAY_IDLE` while she waits) and the
## sensitivity is `Tuning.SLEEPING_SENSITIVITY` asleep. Her body is a point moving at
## `Tuning.WALK_SPEED` and held `HELD_OUT` from a vent whose body is down, which is what the
## physics does to her at a one-tile gate. **Steam alone**: the basement's mouse, the fire and the
## bangs are not ticked, so the figures are what the vents cost.
##
## **Timing is not a policy here.** A walk is an arrival phase and a start delay, and what decides
## it is which vents held her: `held` lists the vents (in the order she meets them) whose body was
## down in front of her at some point. A walk never held is a timed one; one held at the second
## vent only has mistimed that vent.

const STEP := 1.0 / 60.0
## Where a vent holds her centre: its own body (`EventCatalogue.STEAM_VENT_BODY`) plus hers.
const HELD_OUT := 30.0
const GIVE_UP_SECONDS := 240.0

var _scene: InteriorScene
var _events: InteriorEvents
var _points := PackedVector2Array()

func _init(t: Node) -> void:
	_scene = InteriorScene.new()
	t.add_child(_scene)
	_events = InteriorEvents.new()
	t.add_child(_events)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	_events.setup(_scene, rng)
	for tile in _scene.map.basement_walk():
		_points.append(_scene.map.tile_to_world(tile))

func free_rig() -> void:
	_events.free()
	_scene.free()

## One walk. `arrival` is how many seconds of the section's own clock have run before she reaches
## the corridor, `delay` how long she then stands at its entry before walking, `asleep` whether the
## baby is asleep. From an empty meter. Answers `peak` (the most the meter reached), `lost` (it
## reached `Tuning.METER_MAX`, so the section is lost), `held` (the vents that stopped her, in the
## order she meets them), `seconds` and `finished` (she reached the exit).
func walk(arrival: float, delay: float, asleep: bool) -> Dictionary:
	_events.restart()
	var far := Vector2(1.0e6, 1.0e6)
	var time := 0.0
	while time < arrival:
		_tick(far, true)
		time += STEP
	var sensitivity := Tuning.SLEEPING_SENSITIVITY if asleep else 1.0
	var pos := _points[0]
	var next := 1
	var meter := 0.0
	var peak := 0.0
	var seconds := 0.0
	var held: Array[int] = []
	while next < _points.size() and seconds < GIVE_UP_SECONDS and meter < Tuning.METER_MAX:
		var candidate := pos
		var stopped := seconds < delay
		if not stopped:
			candidate = pos.move_toward(_points[next], Tuning.WALK_SPEED * STEP)
			var by := _held_by(pos, candidate)
			if by >= 0:
				stopped = true
				candidate = pos
				if not held.has(by):
					held.append(by)
		var incoming := _tick(candidate, not asleep)
		var rate := Tuning.EXCITEMENT_DECAY_IDLE if stopped else Tuning.EXCITEMENT_DECAY_WALKING
		var decay := rate * _scene.decay_multiplier(candidate)
		meter = clampf(meter + (incoming * sensitivity - decay) * STEP, 0.0, Tuning.METER_MAX)
		peak = maxf(peak, meter)
		pos = candidate
		if pos == _points[next]:
			next += 1
		seconds += STEP
	held.sort()
	return {"peak": peak, "lost": meter >= Tuning.METER_MAX, "held": held, "seconds": seconds,
			"finished": next >= _points.size()}

## The vent whose body is down within `HELD_OUT` of where this step would put her, and nearer than
## she is now, or -1.
func _held_by(pos: Vector2, candidate: Vector2) -> int:
	var vents := _events.vents()
	for i in vents.size():
		var vent: InteriorEvents.Vent = vents[i]
		var there := candidate.distance_to(vent.at)
		if there >= HELD_OUT or there >= pos.distance_to(vent.at):
			continue
		var blow := _blow_at(vent)
		if blow != null and blow.is_solid():
			return i
	return -1

## The blow standing at a vent right now, or null between blows.
func _blow_at(vent: InteriorEvents.Vent) -> EventInstance:
	for instance in _events.instances():
		if instance.def.id == "basement_steam" and not instance.is_finished \
				and instance.global_position.distance_to(vent.at) < 1.0:
			return instance
	return null

## One frame of the vents alone (the fire, the bangs and the masked man are not ticked); what the
## blows charge at `at`, per second.
func _tick(at: Vector2, awake: bool) -> float:
	_events._retire_finished()
	_events._blow_the_vents(STEP)
	var incoming := 0.0
	for instance in _events.instances():
		if instance.def.id != "basement_steam":
			continue
		instance.player_at = at
		instance.baby_awake = awake
		instance._process(STEP)
		incoming += instance.contribution_at(at)
	return incoming
