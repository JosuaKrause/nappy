extends RefCounted
## A rim sits behind the pictures it outlines.
##
## The crash's visible scene is `EventScenery` layers and its rim is an `EntityHalo`; both are
## children that draw behind their parent, and siblings that do are painted in tree order. A rim
## built after the scenery -- the only order a pick can produce, since the scenery is built when the
## instance is -- painted over the cars it was meant to sit behind. Whether the pair *reads* is
## a screenshot's question; what is held here is the order, which nothing else would notice
## changing.

func run(t) -> void:
	_test_the_rim_is_painted_before_the_scene(t)

func _test_the_rim_is_painted_before_the_scene(t) -> void:
	AtlasLibrary.acquire(&"events")
	for vertical: bool in [false, true]:
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id("car_accident"), Vector2.ZERO)
		instance._spread_vertical = vertical
		t.add_child(instance)
		instance._process(instance.def.telegraph_time + 0.01)
		t.check(instance._scenery != null, "the crash has its scenery (vertical %s)" % vertical)
		instance.set_halo_strength(ExcitementHalo.MAX_ALPHA, Palette.HALO_STRONG)
		t.check(instance._halo != null, "a pick builds the crash's rim (vertical %s)" % vertical)
		t.check(instance._halo.show_behind_parent and instance._scenery.show_behind_parent,
				"both are drawn behind the instance, so tree order is their painter order")
		t.check(instance._halo.get_index() < instance._scenery.get_index(),
				"the rim is painted before the cars, so it is behind them (vertical %s)" % vertical)
		t.remove_child(instance)
		instance.free()
	AtlasLibrary.release(&"events")
