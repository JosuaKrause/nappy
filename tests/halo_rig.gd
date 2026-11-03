extends RefCounted
## What the halo suites share for reading rims on real frames: a clock of the frame time the rims
## were handed, and the rim a body hands its source, wrapped so a test reads what `ExcitementHalo`
## told it. `tests/test_halo.gd` and `tests/test_prediction_reuse.gd` use it.

## The frame time every node in the tree has been handed since this one entered it: the engine
## processes it beside the rims, so at any point between frames `elapsed` is the time each rim in
## the tree since then has eased by, and `longest` the longest single frame.
class FrameClock extends Node:
	var elapsed := 0.0
	var frames := 0
	var longest := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		frames += 1
		longest = maxf(longest, delta)

## **The rim a body hands its source, wrapped** so a test reads what `ExcitementHalo` told it: the
## body's own rim (`inner`) does everything, and this keeps the last strength and colour it was
## told. Handed to the source the way a body hands its own (`ExcitementSource.rim`), so the halo
## asks this one and nothing else changes.
class ToldRim extends SourceRim:
	var inner: SourceRim
	var strength := 0.0
	var colour := Color(0.0, 0.0, 0.0, 0.0)
	var told := 0

	func _init(rim: SourceRim) -> void:
		super(Callable())
		inner = rim

	func set_strength(to: float, tint: Color) -> void:
		strength = to
		colour = tint
		told += 1
		inner.set_strength(to, tint)

	func is_held() -> bool:
		return inner.is_held()

	func release() -> void:
		inner.release()

	func forget() -> void:
		inner.forget()

	func entity_halo() -> EntityHalo:
		return inner.entity_halo()

	## Whether its rim is lit — held and told a nonzero target — rather than absent or fading.
	func is_lit() -> bool:
		return inner.is_held() and strength > 0.0

## Wraps the rim `instance` hands its source in a `ToldRim`, and answers it.
static func told(instance: EventInstance) -> ToldRim:
	var rim := ToldRim.new(instance.excitement.rim as SourceRim)
	instance.excitement.rim = rim
	return rim
