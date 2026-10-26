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

func run(t) -> void:
	_test_the_rim_is_painted_before_the_scene(t)
	_test_the_rim_is_given_back_when_the_slices_go(t)

func _test_the_rim_is_painted_before_the_scene(t) -> void:
	AtlasLibrary.acquire(&"events")
	for vertical: bool in [false, true]:
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id("car_accident"), Vector2.ZERO)
		instance._spread_vertical = vertical
		t.add_child(instance)
		instance.look.attach_nodes()
		instance._process(instance.def.telegraph_time + 0.01)
		t.check(not (instance.look as SpreadLook)._sceneries.is_empty(),
				"the crash has its scenery (vertical %s)" % vertical)
		instance.set_halo_strength(ExcitementHalo.MAX_ALPHA, Palette.HALO_STRONG)
		t.check(instance._halo != null, "a pick builds the crash's rim (vertical %s)" % vertical)
		var scenery := (instance.look as SpreadLook)._sceneries[0]
		t.check(instance._halo.get_parent() == scenery.get_parent(),
				"the rim and the first slice's scenery stand on the same slice")
		t.check(instance._halo.show_behind_parent and scenery.show_behind_parent,
				"both are drawn behind the slice, so tree order is their painter order")
		t.check(instance._halo.get_index() < scenery.get_index(),
				"the rim is painted before the cars, so it is behind them (vertical %s)" % vertical)
		t.remove_child(instance)
		instance.free()
	AtlasLibrary.release(&"events")

## The rim stands behind the first slice, so when the look lets go of its slices the instance gives
## the rim back on the spot (`SpreadLook.letting_go_of_the_slices`) rather than leaving it to be
## freed with its slice while the instance still holds it.
func _test_the_rim_is_given_back_when_the_slices_go(t) -> void:
	AtlasLibrary.acquire(&"events")
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("car_accident"), Vector2.ZERO)
	t.add_child(instance)
	instance.look.attach_nodes()
	instance._process(instance.def.telegraph_time + 0.01)
	instance.set_halo_strength(ExcitementHalo.MAX_ALPHA, Palette.HALO_STRONG)
	var rim := instance.rim()
	t.check(rim != null and rim.get_parent() is SpreadLook.Slice,
			"a pick builds the crash's rim behind its first slice")
	instance.look.release_nodes()
	t.check(instance.rim() == null and not is_instance_valid(rim),
			"letting go of the slices gives the rim back, and the instance holds none")
	t.remove_child(instance)
	instance.free()
	AtlasLibrary.release(&"events")
