@warning_ignore_start("untyped_declaration")
extends RefCounted
## Roof art that can reach a street lives in the city's y-sorted entity layer at its feet.
##
## Three things are tested apart. Where a roof's units stand is decided by its random draws, so the
## roof drawn is checked on its own as a function of the seed and the lot. The roof that holds the
## units is checked with a drawer that records what it is told to draw
## (`tests/recording_roof_drawer.gd`), handed in through `Building.roof_drawer` as the city hands the
## real one: every unit is drawn once, at its foot, in the layer the city gave it, at the rotor
## phase of the clock the city gave it. And the real drawer (`RoofDrawer`) is checked on
## its own, handed chosen units and a bare layer, with no building and no roll.

const RecordingRoofDrawer := preload("res://tests/recording_roof_drawer.gd")
const RoofReads := preload("res://tests/roof_reads.gd")

func run(t: TestRunner) -> void:
	_test_every_placed_unit_is_drawn_at_its_foot_in_entities(t)
	_test_the_real_drawer_draws_each_unit_as_told(t)
	_test_the_layout_is_a_function_of_the_seed_and_the_lot(t)
	_test_reserved_cells_hold_native_base_widths(t)
	_test_narrow_and_fragmented_roofs_keep_their_unit_count(t)
	_test_industrial_networks_fit_and_connect(t)
	_test_networks_on_narrow_and_shallow_roofs(t)
	_test_rebuild_releases_external_roof_objects(t)

## A building standing at the same place on the same lot as the city builds one, its roof drawn
## into an `Entities` layer through `drawer` (a recording one, or the real one over its own atlas
## when null) on `clock` when one is given, both handed in before it enters the tree as
## `City._spawn_buildings()` hands them. A recording drawer stands each unit through the real one
## too when `stand` is set, so the objects are in the layer.
func _new_fixture(t: TestRunner, district: int, drawer: RoofDrawer = null,
		clock: SceneryGround = null, stand := false) -> Dictionary:
	var root := Node2D.new()
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	root.add_child(entities)
	t.add_child(root)
	var building := Building.new()
	building.name = "Building"
	building.atlas = AtlasLibrary.new()
	building.roof_drawer = drawer if drawer != null else RoofDrawer.new(building.atlas)
	if stand:
		(drawer as RecordingRoofDrawer).real = RoofDrawer.new(building.atlas)
	building.position = Vector2(320.0, 320.0)
	building.footprint = Vector2(256.0, 256.0)
	building.height = 64.0
	building.district = district
	building.roof_object_parent = entities
	building.scenery_clock = clock
	root.add_child(building)
	return {"root": root, "entities": entities, "building": building}

func _free(fixture: Dictionary) -> void:
	(fixture["building"] as Building).free()
	(fixture["root"] as Node).free()

## The roof units standing in `entities`, in the order they were added.
func _roof_objects_in(entities: Node) -> Array[Building.RoofObject]:
	var objects: Array[Building.RoofObject] = []
	for child in entities.get_children():
		if child is Building.RoofObject:
			objects.append(child)
	return objects

## The draw `drawer` recorded for the unit `entry` of its layout.
func _draw_of(drawer: RecordingRoofDrawer, entry: Dictionary) -> Dictionary:
	for draw in drawer.standing():
		if draw.cell == entry.cell and draw.texture == entry.texture:
			return draw
	return {}

## How many cells a roof offers units with no extension: the interior columns by the interior rows.
func _interior_cells(building: Building) -> int:
	return maxi(building.columns() - 2, 0) * maxi(building.roof_tiles() - 2, 0)

# ------------------------------------------------------------------ the holder ---

## The city's clock alternates a rotor's two frames once every `Building.VENT_FRAME_INTERVAL`, so
## half way through the second interval a rotor shows its second frame and half way through the
## third its first again: the phase the building hands the drawer, so a rebuilt roof's rotors turn
## in step with the ones that were never rebuilt.
func _test_every_placed_unit_is_drawn_at_its_foot_in_entities(t: TestRunner) -> void:
	var drawer := RecordingRoofDrawer.new()
	var clock := SceneryGround.new()
	clock.elapsed = Building.VENT_FRAME_INTERVAL * 1.5
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.RESIDENTIAL, drawer, clock)
	var entities: Node2D = fixture["entities"]
	var building: Building = fixture["building"]
	var layout := drawer.layout()
	t.check(not layout.is_empty(), "a full residential roof places roof units")
	var standing := drawer.standing()
	t.check(standing.size() == layout.size() and drawer.draws.size() == layout.size(),
			"every unit is drawn once, and nothing else is (%d standing, %d drawn)"
			% [standing.size(), drawer.draws.size()])
	for i in layout.size():
		t.check(i == 0 or (layout[i - 1].cell as Vector2i).y >= (layout[i].cell as Vector2i).y,
				"units are drawn farthest first, so they paint back to front")
	for i in mini(layout.size(), standing.size()):
		var unit := layout[i]
		var drawn := standing[i]
		t.check(drawn.layer == entities, "roof art is drawn into Entities")
		var at: Vector2 = drawn.at
		t.check(at.is_equal_approx(building.position + RecordingRoofDrawer.foot_of(building, unit)),
				"roof art uses the furniture foot anchor")
	for drawn in standing:
		t.check(drawn.rotor_frame_b, "a roof drawn in the clock's second interval turns its rotors"
				+ " on their second frame")
	clock.elapsed = Building.VENT_FRAME_INTERVAL * 2.5
	building.variant += 1
	var rebuilt := drawer.standing()
	t.check(not rebuilt.is_empty(), "the rebuilt roof has units to draw")
	for drawn in rebuilt:
		t.check(not drawn.rotor_frame_b, "a roof rebuilt in the clock's third interval turns its"
				+ " rotors on their first frame")
	_free(fixture)
	clock.free()

# ------------------------------------------------------------- the real drawer ---

## The real drawer on its own: chosen units into a bare layer, one of each kind of thing a roof
## unit can be (a vent housing on either rotor frame, a joined duct section, an ordinary picture).
func _test_the_real_drawer_draws_each_unit_as_told(t: TestRunner) -> void:
	var layer := Node2D.new()
	t.add_child(layer)
	var drawer := RoofDrawer.new(AtlasLibrary.new())
	var units := [
		{"cell": Vector2i(2, 3), "texture": Building.VENT_HOUSING, "at": Vector2(48, -96),
			"links": -1, "frame_b": true},
		{"cell": Vector2i(4, 3), "texture": Building.VENT_HOUSING, "at": Vector2(112, -96),
			"links": -1, "frame_b": false},
		{"cell": Vector2i(1, 2), "texture": Building.DUCT_RUN, "at": Vector2(16, -64),
			"links": 9, "frame_b": true},
		{"cell": Vector2i(5, 1), "texture": Building.HVAC_A, "at": Vector2(176, -32),
			"links": -1, "frame_b": true}]
	var objects: Array[Building.RoofObject] = []
	for unit: Dictionary in units:
		objects.append(drawer.draw(layer, unit.cell, unit.texture, unit.at, unit.links, unit.frame_b))
	t.check(layer.get_children() == objects, "each unit stands in the layer it was handed, in the"
			+ " order it was drawn")
	for i in units.size():
		var unit: Dictionary = units[i]
		var object := objects[i]
		var cell: Vector2i = unit.cell
		t.check(object.name == "RoofObject_%d_%d" % [cell.x, cell.y]
				and object.texture_key == unit.texture and object.duct_links == unit.links,
				"a roof object is named after its cell and shows its picture, joined as told")
		t.check(object.position == unit.at, "a roof object stands its foot where it was told")
		for child in object.get_children():
			t.check(not child is CollisionObject2D and not child is CollisionShape2D,
					"roof art has no collision child")
		t.check(not object.is_processing(), "stationary roof housing has no per-frame callback")
		if unit.texture == Building.VENT_HOUSING:
			t.check(object.rotor != null and object.rotor.get_parent() == object
					and object.rotor.frame_b == unit.frame_b,
					"a vent housing stands with its turning rotor on the frame it was handed")
		else:
			t.check(object.rotor == null and object.get_child_count() == 0,
					"only a vent housing carries a rotor")
	layer.free()

# ------------------------------------------------------------------ the layout ---

func _test_the_layout_is_a_function_of_the_seed_and_the_lot(t: TestRunner) -> void:
	var drawer := RecordingRoofDrawer.new()
	var twin_drawer := RecordingRoofDrawer.new()
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL, drawer)
	var twin := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL, twin_drawer)
	var building: Building = fixture["building"]
	var other: Building = twin["building"]
	var differs := false
	for variant in 8:
		building.variant = variant
		other.variant = variant
		var roof := drawer.drawn()
		t.check(not roof.is_empty(), "an industrial roof of seed %d has units" % variant)
		t.check(twin_drawer.drawn() == roof,
				"the same seed on the same lot lays the same roof on another building")
		building.variant = variant + 100
		differs = differs or drawer.drawn() != roof
		building.variant = variant
		t.check(drawer.drawn() == roof, "laying a seed again gives the same roof")
	t.check(differs, "another seed lays another roof on the same lot")
	_free(fixture)
	_free(twin)

func _test_industrial_networks_fit_and_connect(t: TestRunner) -> void:
	var drawer := RecordingRoofDrawer.new()
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL, drawer)
	var building: Building = fixture["building"]
	var signatures := {}
	var branched := false
	for variant in 40:
		building.variant = variant
		building.roof_extension_rows = [0, 0, 1, 3, 3, 1, 0, 0]
		var layout := drawer.layout()
		var network := {}
		var used := {}
		var signature := ""
		for entry: Dictionary in layout:
			for cell: Vector2i in entry["cells"]:
				t.check(RoofReads.on_the_interior(building, cell) and not used.has(cell),
						"every duct and equipment foot fits free interior roof, extensions included")
				used[cell] = true
			if entry.has("links"):
				network[entry["cell"]] = entry["links"]
				signature += str(entry["links"]) + ","
		t.check(not network.is_empty(), "the industrial fixture has a connected network")
		if network.is_empty():
			continue
		signatures[signature] = true
		var reached := {network.keys()[0]: true}
		var pending: Array = reached.keys()
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			var degree := 0
			for index in 4:
				var direction: Vector2i = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN][index]
				var neighbor := cell + direction
				var linked: bool = (network[cell] & (1 << index)) != 0
				t.check(linked == network.has(neighbor), "rendered duct links match actual adjacent cells")
				if linked:
					degree += 1
					if not reached.has(neighbor):
						reached[neighbor] = true
						pending.append(neighbor)
			branched = branched or degree >= 3
		t.check(reached.size() == network.size(), "all duct cells belong to one traversable network")
		t.check(layout.size() > network.size(),
				"the network leaves room for ordinary roof equipment")
	t.check(signatures.size() > 2 and branched, "roof layouts vary in topology and include junctions")
	_free(fixture)

func _test_reserved_cells_hold_native_base_widths(t: TestRunner) -> void:
	var drawer := RecordingRoofDrawer.new()
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL, drawer)
	var building: Building = fixture["building"]
	var used := {}
	for entry: Dictionary in drawer.layout():
		var cells: Array = entry["cells"]
		for cell: Vector2i in cells:
			t.check(not used.has(cell), "roof equipment reservations never share a cell")
			used[cell] = true
		var key: StringName = entry["texture"]
		var width := 32.0 if entry.has("links") else AtlasTable.baked().native_size(key).x \
				* RoofReads.equipment_scale(key)
		# The columns the foot is centred across, read off where it was put.
		var foot: Vector2 = _draw_of(drawer, entry).at - building.position
		var horizontal_cells := roundi(2.0 * ((foot.x + building.columns() * Building.TILE * 0.5)
				/ Building.TILE - (entry["cell"] as Vector2i).x))
		t.check(cells.size() >= horizontal_cells,
				"a roof object's foot is centered in every reserved horizontal cell")
		t.check(width <= horizontal_cells * Building.TILE,
				"a roof object's %dpx base fits its reserved %dpx horizontal footprint"
				% [width, horizontal_cells * Building.TILE])
	_free(fixture)

func _test_networks_on_narrow_and_shallow_roofs(t: TestRunner) -> void:
	var drawer := RecordingRoofDrawer.new()
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.INDUSTRIAL, drawer)
	var building: Building = fixture["building"]
	var vertical := false
	for size: Vector2 in [Vector2(96, 448), Vector2(128, 128), Vector2(160, 192),
			Vector2(288, 160), Vector2(192, 320)]:
		building.footprint = size
		for variant in 12:
			building.variant = variant
			var layout := drawer.layout()
			var occupied := {}
			var network := {}
			for entry: Dictionary in layout:
				for cell: Vector2i in entry["cells"]:
					t.check(RoofReads.on_the_interior(building, cell) and not occupied.has(cell),
							"narrow and shallow roofs never reserve a lip, absent cell or occupied base")
					occupied[cell] = true
				if entry.has("links"):
					network[entry["cell"]] = entry["links"]
			if size.x == 96 and not network.is_empty():
				vertical = true
				for links: int in network.values():
					t.check((links & 3) == 0, "a one-column network uses only north/south links")
			if building.columns() >= 3 and RoofReads.tallest_of(building) >= 3:
				t.check(layout.size() > network.size(),
						"narrow and shallow roof layouts retain ordinary compact equipment")
	t.check(vertical, "the narrow fixture exercises a generated purely vertical network")
	_free(fixture)

## A broad unit that finds no free east cell falls back to a compact one rather than being dropped,
## so a roof keeps the count its cells rolled however few broad units fit on it. Checked by what
## that means from outside: a three-column roof, where no broad unit fits, lays out as many units
## as a wide roof with as many interior cells, in every district and on every seed.
func _test_narrow_and_fragmented_roofs_keep_their_unit_count(t: TestRunner) -> void:
	for district in [GameEnums.BlockPurpose.INDUSTRIAL, GameEnums.BlockPurpose.CIVIC,
			GameEnums.BlockPurpose.RESIDENTIAL, GameEnums.BlockPurpose.COMMERCIAL]:
		# Three columns by seven and by thirteen tiles, with a two-tile wall, leave one interior
		# column three and nine cells deep; five columns by five and by seven leave three columns
		# one and three rows deep.
		for pair: Array in [[Vector2(3, 7), Vector2(5, 5)], [Vector2(3, 13), Vector2(5, 7)]]:
			var narrow_drawer := RecordingRoofDrawer.new()
			var wide_drawer := RecordingRoofDrawer.new()
			var narrow_fixture := _new_fixture(t, district, narrow_drawer)
			var wide_fixture := _new_fixture(t, district, wide_drawer)
			var narrow: Building = narrow_fixture["building"]
			var wide: Building = wide_fixture["building"]
			narrow.footprint = pair[0] * Building.TILE
			wide.footprint = pair[1] * Building.TILE
			var cells := _interior_cells(narrow)
			t.check(cells > 0 and cells == _interior_cells(wide),
					"the two roofs offer as many interior cells (%d)" % cells)
			for variant in 24:
				narrow.variant = variant
				wide.variant = variant
				var layout := narrow_drawer.layout()
				var wide_layout := wide_drawer.layout()
				t.check(layout.size() == wide_layout.size(),
						"a three-column roof keeps every roll a wide roof of as many cells lays out"
						+ " (district %d, variant %d: %d against %d)"
						% [district, variant, layout.size(), wide_layout.size()])
				for entry: Dictionary in layout:
					t.check(entry["span"] == 1,
							"a one-interior-column roof uses a compact one-cell unit")
			_free(narrow_fixture)
			_free(wide_fixture)

# ------------------------------------------------------- the holder, drawn for real ---

func _test_rebuild_releases_external_roof_objects(t: TestRunner) -> void:
	var drawer := RecordingRoofDrawer.new()
	var fixture := _new_fixture(t, GameEnums.BlockPurpose.RESIDENTIAL, drawer, null, true)
	var entities: Node2D = fixture["entities"]
	var building: Building = fixture["building"]
	var old_objects: Array[WeakRef] = []
	for object in _roof_objects_in(entities):
		old_objects.append(weakref(object))
	t.check(not old_objects.is_empty(), "the roof had objects to release")
	building.variant += 1
	for object: WeakRef in old_objects:
		t.check(object.get_ref() == null, "rebuild frees superseded entity roof art")
	var replacements := _roof_objects_in(entities)
	t.check(not replacements.is_empty() and replacements.size() == entities.get_child_count()
			and replacements.size() == drawer.standing().size(),
			"rebuild keeps replacement roof art in Entities")
	_free(fixture)
