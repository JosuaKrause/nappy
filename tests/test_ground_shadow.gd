extends RefCounted
## `GroundShadow`, one object's contact shadow drawn from its picture: it is drawn on the shadow
## layer whatever its parent's, it holds the shadow page while it is in the tree and gives it back
## when it leaves, and it redraws when it is cast a new shape, place or axis and not otherwise.
## Built with a library of its own (`AtlasLibrary`) watched through the run log (`PageLog`); its
## shape is a plain value, built as it is.

const PageLog := preload("res://tests/atlas_page_log.gd")

func run(t) -> void:
	_test_it_is_drawn_on_the_shadow_layer(t)
	_test_it_holds_the_shadow_page_while_in_the_tree(t)
	await _test_it_redraws_only_when_its_cast_changes(t)

func _test_it_is_drawn_on_the_shadow_layer(t) -> void:
	var standing := Node2D.new()
	DrawLayer.draw_on(standing, DrawLayer.Layer.ENTITIES)
	var shadow := GroundShadow.new(AtlasLibrary.new())
	standing.add_child(shadow)
	t.add_child(standing)
	var reference := Node2D.new()
	DrawLayer.draw_on(reference, DrawLayer.Layer.SHADOWS)
	t.check(shadow.z_index == reference.z_index and not shadow.z_as_relative,
			"a shadow is drawn on the shadow layer, not on its standing parent's")
	t.check(shadow.z_index < standing.z_index, "which is under the standing thing it belongs to")
	reference.free()
	standing.free()

func _test_it_holds_the_shadow_page_while_in_the_tree(t) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var shadow := GroundShadow.new(atlas)
	t.check(pages.loads(GroundShape.SHADOW_GROUP) == 0, "a shadow out of the tree holds nothing")
	t.add_child(shadow)
	t.check(pages.held(GroundShape.SHADOW_GROUP), "in the tree it holds the shadow page")
	t.check(atlas.region(GroundShape.point(7.0).shadow_picture_name()) != null,
			"so the picture its shape names is there to draw")
	t.remove_child(shadow)
	t.check(pages.releases(GroundShape.SHADOW_GROUP) == 1, "and out of it again it gives the page back")
	shadow.free()
	pages.stop()

func _test_it_redraws_only_when_its_cast_changes(t) -> void:
	var shadow := GroundShadow.new(AtlasLibrary.new())
	var drawn := [0]
	shadow.draw.connect(func() -> void: drawn[0] += 1)
	t.add_child(shadow)
	var car := GroundShape.segment(11.0, 15.0)
	shadow.cast(car, Vector2.ZERO, Vector2.RIGHT)
	await t.get_tree().process_frame
	var first := drawn[0]
	t.check(first >= 1, "a cast shadow is drawn")
	shadow.cast(car, Vector2.ZERO, Vector2.RIGHT)
	await t.get_tree().process_frame
	t.check(drawn[0] == first, "the same cast again draws nothing")
	shadow.cast(car, Vector2.ZERO, Vector2.DOWN)
	await t.get_tree().process_frame
	t.check(drawn[0] == first + 1, "a turned axis draws it again")
	shadow.cast(GroundShape.point(7.0), Vector2(0.0, 4.0))
	await t.get_tree().process_frame
	t.check(drawn[0] == first + 2, "and so does a new shape or place")
	shadow.free()
