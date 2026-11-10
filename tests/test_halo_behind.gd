@warning_ignore_start("untyped_declaration", "unsafe_property_access", "unsafe_method_access")
extends RefCounted
## A rim sits behind the pictures it outlines.
##
## The crash's visible scene is `EventScenery` layers, one behind each of its slices, and its rim
## is an `EntityHalo` behind the first slice; both draw behind their parent, and siblings that do
## are painted in tree order. A rim
## built after the scenery -- the only order a pick can produce, since the scenery is built when the
## instance is -- painted over the cars it was meant to sit behind. Whether the pair *reads* is
## a screenshot's question; what is held here is the order, which nothing else would notice
## changing.

const EastWestStreet = preload("res://tests/east_west_street.gd")

func run(t) -> void:
	await _test_the_rim_is_painted_before_the_scene(t)
	await _test_the_rim_is_given_back_when_the_slices_go(t)

func _test_the_rim_is_painted_before_the_scene(t) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	for vertical: bool in [false, true]:
		# Down the screen on an east-west street, across it on open ground, as the street it
		# stands on decides.
		var ground: WorldMap = EastWestStreet.new() if vertical else WorldMap.open_ground()
		var instance := EventInstance.new()
		instance.atlas = atlas
		instance.setup(EventCatalogue.by_id("car_accident"), Vector2.ZERO, PackedVector2Array(),
				Vector2.RIGHT, ground)
		t.add_child(instance)
		await t.get_tree().process_frame
		instance.step(instance.def.telegraph_time + 0.01)
		t.check(instance.runs_vertically() == vertical,
				"the crash runs %s the screen on its street" % ("down" if vertical else "across"))
		var first := _first_slice(instance)
		var sceneries := _sceneries_on(first)
		t.check(not sceneries.is_empty(), "the crash has its scenery (vertical %s)" % vertical)
		(instance.excitement.rim as SourceRim).set_strength(EntityHalo.MAX_ALPHA,
				Palette.HALO_STRONG)
		var rim := instance.rim()
		t.check(rim != null, "a pick builds the crash's rim (vertical %s)" % vertical)
		var scenery: EventScenery = sceneries[0]
		t.check(rim.get_parent() == scenery.get_parent(),
				"the rim and the first slice's scenery stand on the same slice")
		t.check(rim.show_behind_parent and scenery.show_behind_parent,
				"both are drawn behind the slice, so tree order is their painter order")
		t.check(rim.get_index() < scenery.get_index(),
				"the rim is painted before the cars, so it is behind them (vertical %s)" % vertical)
		t.remove_child(instance)
		instance.free()
	atlas.release(&"events")

## The rim stands behind the first slice, so when the look lets go of its slices the instance gives
## the rim back on the spot (`SpreadLook.letting_go_of_the_slices`) rather than leaving it to be
## freed with its slice while the instance still holds it.
func _test_the_rim_is_given_back_when_the_slices_go(t) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	var instance := EventInstance.new()
	instance.atlas = atlas
	instance.setup(EventCatalogue.by_id("car_accident"), Vector2.ZERO)
	t.add_child(instance)
	await t.get_tree().process_frame
	instance.step(instance.def.telegraph_time + 0.01)
	(instance.excitement.rim as SourceRim).set_strength(EntityHalo.MAX_ALPHA, Palette.HALO_STRONG)
	var rim := instance.rim()
	t.check(rim != null and rim.get_parent() is SpreadLook.Slice,
			"a pick builds the crash's rim behind its first slice")
	instance.look.release_nodes()
	t.check(instance.rim() == null and not is_instance_valid(rim),
			"letting go of the slices gives the rim back, and the instance holds none")
	t.remove_child(instance)
	instance.free()
	atlas.release(&"events")

## The first slice `instance`'s picture is drawn in, found where the look stood it: beside the
## instance in its parent (`EventInstance.add_beside_it()`), the one whose index is 0.
static func _first_slice(instance: EventInstance) -> SpreadLook.Slice:
	for child in instance.get_parent().get_children():
		if child is SpreadLook.Slice and child.instance == instance and child.index == 0:
			return child
	return null

## The visible scene's layers standing on `slice` (`EventScenery`), in tree order.
static func _sceneries_on(slice: SpreadLook.Slice) -> Array[EventScenery]:
	var found: Array[EventScenery] = []
	if slice == null:
		return found
	for child in slice.get_children():
		if child is EventScenery:
			found.append(child)
	return found
