extends RefCounted
## The baby is handed the world she stands in, and is handed it again when the world changes.
##
## **What this pins.** `Baby` answers every meter question from a `WorldContext` it holds
## (`Baby._world`): the excitement bodies at her feet, the calm ground's sleepiness gain, the
## alley trickle and the ground's decay. The escape builds the escape building first and the city
## when she walks out of the service door, with the same stroller rig (and so the same `Baby`)
## reparented between them, so a baby that found her world once, when she first entered the tree,
## would go on asking the building about a street it knows nothing of. So she is told her world
## (`Baby.set_world()`) and answers from the one she was last told, and from none as neutral.
##
## **Two stand-in worlds** (`FakeWorld`, answering as the building and as a street would, each with an
## answer the other does not give) are handed to a baby on a rig, the way `main` hands her the real
## ones; no city, building or boot is built. The rig is a bare `Stroller`, which `Baby` requires as its
## parent and reads her speed from. **That `main` calls `Baby.set_world()` at every place it puts
## her in a world is `tests/test_main.gd`'s** (`_test_main_hands_the_baby_the_world_it_puts_her_in`),
## since it is a claim about what `main` wires; what a real city answers for its ground and its bodies is
## `tests/test_city_world.gd`'s, and what the meter does with an answer is `tests/test_meters.gd`'s.

## The decay multiplier the street gives her on calm ground, the highest the city gives, over the
## building's 1.0.
const STREET_DECAY := City.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER
## What the street's one noise source charges her per second.
const STREET_NOISE := 6.0

## Answers as the escape's building does (no decay beyond the base, nothing charging her) or, handed
## `decay` and `noise`, as a street does. The rig for the two questions the suite asks of her
## (`decay_rate()` and `last_incoming`), the same questions `main`'s wiring changes the answer to.
class FakeWorld extends WorldContext:
	var decay := 1.0
	var noise := 0.0
	## A source of no field of its own standing on itself: no check here reads a colour, only the
	## amount `noise` feeds the meter.
	var _noise := ExcitementSource.new(self)

	## Overrides WorldContext.decay_multiplier.
	func decay_multiplier(_world_position: Vector2) -> float:
		return decay

	## Overrides WorldContext.excitement_sources_at.
	func excitement_sources_at(_world_position: Vector2) -> Array:
		return [[_noise, noise]] if noise > 0.0 else []

func run(t) -> void:
	_test_a_baby_with_no_world_is_neutral(t)
	await _test_a_baby_answers_from_the_world_she_was_last_handed(t)

func _test_a_baby_with_no_world_is_neutral(t) -> void:
	var baby := Baby.new()
	t.check(baby.world() == null, "a baby never placed in a world holds none")
	t.check(baby.decay_rate() == 0.0, "a baby never placed in a world has no decay rate")
	baby.free()

## Handed the building, she reads the building; handed the street, the same baby reads the street
## and no longer the building; handed none, she is neutral again. Each answer is the one the
## world handed her gives: the decay of the ground under her, and what the bodies there charge her.
func _test_a_baby_answers_from_the_world_she_was_last_handed(t) -> void:
	var building := FakeWorld.new()
	var street := FakeWorld.new()
	street.decay = STREET_DECAY
	street.noise = STREET_NOISE
	var rig := Stroller.new()
	var camera := Camera2D.new()
	# The name matters: Stroller's @onready looks the camera up by path.
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(building)
	t.add_child(street)
	t.add_child(rig)
	# The test sets her velocity, and only the baby runs.
	rig.set_physics_process(false)
	rig.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	var baby := Baby.new()
	rig.add_child(baby)

	baby.set_world(building)
	var walking := Tuning.EXCITEMENT_DECAY_WALKING
	t.close_to(baby.decay_rate(), walking * building.decay,
			"in the building her decay is the building's ground's")
	await _let_her_tick(t, baby)
	t.check(baby.last_incoming == 0.0, "and nothing in the building charges her")

	baby.set_world(street)
	t.close_to(baby.decay_rate(), walking * STREET_DECAY,
			"on the street her decay is the street's ground's")
	await _let_her_tick(t, baby)
	t.check(baby.last_incoming > 0.0,
			"and what charges her there reaches her meter (%.2f/s, the street's %.2f/s)"
			% [baby.last_incoming, STREET_NOISE])

	baby.set_world(null)
	t.check(baby.world() == null and baby.decay_rate() == 0.0,
			"handed no world again, she has no decay rate")
	rig.free()
	building.free()
	street.free()

## One physics tick, on which the baby's own frame runs her meter and writes what it was fed.
func _let_her_tick(t, baby: Baby) -> void:
	baby.excitement = 0.0
	# What the meter was fed is written by her own tick, so a tick that did not run reads nothing.
	baby.last_incoming = -1.0
	await PhysicsTicks.pass_ticks(t, 1)
