extends RefCounted
## Scenery phases update their own retained layers without changing static layout or bodies.

func run(t) -> void:
	_test_roof_rotors(t)

func _test_roof_rotors(t) -> void:
	var building := Building.new()
	building.footprint = Vector2(256, 256)
	building.height = 64
	building.district = GameEnums.BlockPurpose.INDUSTRIAL
	t.add_child(building)
	t.check(not building._rotor_layers.is_empty(), "the roof fixture actually has moving vents")
	var furniture := building._roof_furniture.duplicate(true)
	var collision: Shape2D = building._collision.shape
	var layers := building._roof_layers.duplicate()
	building._process(Building.VENT_FRAME_INTERVAL - 0.01)
	for rotor in building._rotor_layers:
		t.check(not rotor.frame_b, "rotor holds its first phase until the existing interval")
	building._process(0.02)
	for layer: SceneryLayer in layers:
		if building._rotor_layers.has(layer):
			t.check(layer.frame_b, "the small rotor advances independently")
			t.check(layer._rects[0].size == Vector2(6, 6), "only the cropped rotor is animated")
		else:
			t.check(not layer.frame_b, "a stationary furniture batch keeps its frame")
	t.check(building._roof_furniture == furniture, "animation does not reroll furniture")
	t.check(building._collision.shape == collision, "animation does not rebuild collision")
	building._rebuild()
	for layer in layers:
		t.check(not is_instance_valid(layer), "rebuild releases every superseded roof layer")
	for rotor in building._rotor_layers:
		t.check(rotor.frame_b, "rebuilding the roof preserves the current phase")
	building.footprint = Vector2(32, 32)
	t.check(building._rotor_layers.is_empty() and not building.is_processing(),
			"a roof without vents releases them and stops its animation callback")
	building.free()
