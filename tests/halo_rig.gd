extends RefCounted
## What the halo suites share for reading rims on real frames: a clock of the frame time the rims
## were handed, and the rim a body hands its source, wrapped so a test reads what `ExcitementHalo`
## told it. `tests/test_halo.gd`, `tests/test_prediction_reuse.gd`, `tests/test_checkpoints.gd` and
## `tests/test_wall_shield.gd` use it.

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

	## Overrides SourceRim.set_strength.
	func set_strength(to: float, tint: Color) -> void:
		strength = to
		colour = tint
		told += 1
		inner.set_strength(to, tint)

	## Overrides SourceRim.is_held.
	func is_held() -> bool:
		return inner.is_held()

	## Overrides SourceRim.release.
	func release() -> void:
		inner.release()

	## Overrides SourceRim.forget.
	func forget() -> void:
		inner.forget()

	## Overrides SourceRim.entity_halo.
	func entity_halo() -> EntityHalo:
		return inner.entity_halo()

	## Whether its rim is lit — held and told a nonzero target — rather than absent or fading.
	func is_lit() -> bool:
		return inner.is_held() and strength > 0.0

## Wraps the rim `instance` hands its source in a `ToldRim`, and answers it.
static func told(instance: EventInstance) -> ToldRim:
	var rim := ToldRim.new(instance.source().rim)
	instance.source().use_rim(rim)
	return rim

## A meter whose decay over the window is a number the test sets (none by default, so a source's
## net is what it landed): the one answer a halo takes from the baby it is handed (`setup()`) that
## the test sets, and the others, `decay_rate()` and `current_sensitivity()`, get a fresh `Baby`'s
## defaults. Never in the tree (`Baby._ready()` wants a stroller parent).
class DecayedBaby extends Baby:
	var decay := 0.0

	## Overrides Baby.decay_in_window.
	func decay_in_window() -> float:
		return decay

## The one set a halo is handed, over a list of sources a test edits: the stand-in for a world's
## own set (`EventManager.sources`, `Crowd.sources`), handed in where the game hands those.
class ListSet extends ExcitementSources:
	var sources: Array = []

	## Overrides ExcitementSources.every_source.
	func every_source(into: Array) -> void:
		into.append_array(sources)

## **Which of `sources` a real halo lights,** the sources being whatever the game has in its world
## (an event's, a crowd body's, each with its body) and her standing at `at`: the halo is built the
## way `main` builds it (`setup()` with a set of sources, her and the baby) and let pass real frames,
## and the sources whose rim it was told a nonzero strength are the ones it draws a rim on. Each
## source's rim is swapped for a `ToldRim` that draws nothing (a plain `EntityHalo` on its body), so
## the selection is read the way the halo suites read what a rim was told. Answers the lit sources;
## the caller frees the bodies.
static func lit_among(t: TestRunner, sources: Array, at: Vector2) -> Array:
	var set := ListSet.new()
	for source: ExcitementSource in sources:
		var body: Node = source.body
		source.use_rim(ToldRim.new(SourceRim.new(func() -> EntityHalo:
				var halo := EntityHalo.new(func(_canvas: CanvasItem) -> void: pass,
						func() -> float: return 0.0)
				body.add_child(halo)
				return halo)))
		set.sources.append(source)
	var player := Node2D.new()
	t.add_child(player)
	player.global_position = at
	var baby := DecayedBaby.new()
	var halo := ExcitementHalo.new()
	var sets: Array[ExcitementSources] = [set]
	halo.setup(sets, player, baby)
	t.add_child(halo)
	for _frame in 3:
		await t.get_tree().process_frame
	var lit: Array = []
	for source: ExcitementSource in sources:
		if (source.rim as ToldRim).strength > 0.0:
			lit.append(source)
	halo.free()
	player.free()
	baby.free()
	return lit
