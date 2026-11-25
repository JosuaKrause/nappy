class_name PhysicsTicks
extends RefCounted
## Lets real physics ticks pass for a suite, one tick a rendered frame. After a slow frame the
## engine would catch up by running several ticks in one (up to `Engine.max_physics_steps_per_frame`),
## so a check made between two awaits would miss what happened on the ticks inside it, and a check
## that depends on which node ticks first would read a different order. Held to one tick a frame,
## the simulation slows down under load rather than catching up, and the frame timeline is the tick
## timeline, however long a frame takes (`Godot --headless --frame-delay`). The engine's value is put
## back before this returns.

## Lets `ticks` physics ticks pass, every node in the tree taking its `_physics_process()` once on
## each, and returns after the last one has run. `each`, when valid, is called after every tick with
## the number of ticks passed so far. **`scale` runs them at that many times real time**
## (`Engine.time_scale`): every tick the engine takes is then `scale` times as long as a tick is, so a
## long wait takes fewer of them, and a check made over such a stretch is stated in the seconds it
## covers (`ticks_for()` with the same `scale`) and holds at any step. Both engine values are put back.
## **`each` ends the wait early by returning `true`**: no further tick is let pass, so a walk that
## stops at an event is not stepped on past it.
static func pass_ticks(t: Node, ticks: int, each := Callable(), scale := 1.0) -> void:
	var steps := Engine.max_physics_steps_per_frame
	var clock := Engine.time_scale
	Engine.max_physics_steps_per_frame = 1
	Engine.time_scale = scale
	var ran := 0
	while ran < ticks:
		var before := Engine.get_physics_frames()
		await t.get_tree().physics_frame
		await t.get_tree().process_frame
		var passed := Engine.get_physics_frames() - before
		ran += passed
		if passed > 0 and each.is_valid() and each.call(ran) == true:
			break
	Engine.max_physics_steps_per_frame = steps
	Engine.time_scale = clock

## The factor the suites whose waits are not CPU-bound pass to `pass_ticks_faster()`.
const FASTER := 8

## Lets `ticks` physics ticks pass as `pass_ticks()` does, at `factor` times the engine's rate:
## `Engine.physics_ticks_per_second` and `Engine.time_scale` both multiplied by `factor`, so every
## tick still steps the game by the same `1 / physics_ticks_per_second` seconds (a tick's delta is
## `time_scale / physics_ticks_per_second`) and a walk of `ticks` ticks covers the same game time
## and the same positions, the engine only taking the ticks `factor` times as often in real time.
## `scale` is the game-time speed of each tick as in `pass_ticks()`, kept per tick whatever `factor` is.
## Both settings are put back, and the runner's shared-state check compares both.
static func pass_ticks_faster(t: Node, ticks: int, factor: int, each := Callable(), scale := 1.0) -> void:
	var rate := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = rate * factor
	await pass_ticks(t, ticks, each, Engine.time_scale * scale * factor)
	Engine.physics_ticks_per_second = rate

## **First, in a suite's `run()`**: lets the frame the runner started the suite in end. That frame
## may run a backlog of ticks (up to the engine's own limit, planned before any suite set it to one)
## in a single go, which would land inside the first `pass_ticks()`, so that it passes more ticks
## than it was asked for.
static func settle(t: Node) -> void:
	var steps := Engine.max_physics_steps_per_frame
	Engine.max_physics_steps_per_frame = 1
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	Engine.max_physics_steps_per_frame = steps

## The ticks `seconds` of game time take at `scale` times real time: counted in ticks, never in
## wall-clock time.
static func ticks_for(seconds: float, scale := 1.0) -> int:
	return ceili(seconds * Engine.physics_ticks_per_second / scale - 0.001)
