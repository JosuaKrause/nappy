@warning_ignore_start("untyped_declaration", "unsafe_property_access", "unsafe_method_access")
extends RefCounted
## The one draw-layer list (`DrawLayer`): nothing else writes a `z_index`, the layers keep the order
## each one's reason gives, a world adds a node on the layer it is asked for, and a long footprint is
## drawn as slices standing at their own feet.

## The one file that may write a `z_index` or a `z_as_relative`.
const MODULE := "res://src/world/draw_layer.gd"
const EastWestStreet = preload("res://tests/east_west_street.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")

func run(t) -> void:
	_test_no_z_index_is_written_outside_the_module(t)
	_test_the_scan_finds_a_write(t)
	_test_the_layers_keep_their_reasons(t)
	_test_a_world_adds_a_node_on_its_layer(t)
	_test_slices_stand_at_their_own_feet(t)
	await _test_a_spread_is_drawn_in_slices_ahead_of_its_instance(t)
	await _test_every_long_picture_is_drawn_in_slices(t)
	await _test_the_slices_go_with_their_event(t)

# ------------------------------------------------------------------ the module ---

func _test_no_z_index_is_written_outside_the_module(t) -> void:
	var files := _files_under("res://src", ".gd")
	files.append_array(_files_under("res://scenes", ".tscn"))
	t.check(files.size() > 100, "there were scripts and scenes to read (%d)" % files.size())
	var outside := PackedStringArray()
	for path in files:
		if path == MODULE:
			continue
		for line in _z_writes(FileAccess.get_file_as_string(path), path.ends_with(".tscn")):
			outside.append("%s: %s" % [path, line])
	t.check(outside.is_empty(), "no z_index is written outside DrawLayer:\n%s"
			% "\n".join(outside))
	t.check(_z_writes(FileAccess.get_file_as_string(MODULE), false).size() > 0,
			"and DrawLayer itself writes one, so the scan reads the form a write takes")

func _test_the_scan_finds_a_write(t) -> void:
	t.check(_z_writes("func f() -> void:\n\tnode.z_index = 3\n", false).size() == 1,
			"the scan finds a script that writes a z_index")
	t.check(_z_writes("\tz_as_relative = false\n", false).size() == 1,
			"and one that writes z_as_relative")
	t.check(_z_writes("[node name=\"A\" type=\"Node2D\"]\nz_index = 2\n", true).size() == 1,
			"and a scene that sets one")
	for form: String in ["node.z_index += 1", "set_z_index(-1)", "node.set_z_as_relative(false)",
			"set(\"z_index\", -1)", "node.set_deferred(&\"z_as_relative\", false)",
			"tween.tween_property(node, ^\"z_index\", 2, 0.1)", "z_as_relative=true"]:
		t.check(_z_writes("\t%s\n" % form, false).size() == 1, "the scan finds `%s`" % form)
	t.check(_z_writes("\t## `z_index = 1` puts it above\n\tif a.z_index == b.z_index:\n", false)
			.is_empty(), "a comment naming one, or a comparison, is not a write")

## The lines of `text` that write a `z_index` or a `z_as_relative`, outside a comment: in a script
## an assignment, a call to the setter, or the property named in a string (`set()`,
## `set_deferred()`, a tween); in a scene, the property set.
static func _z_writes(text: String, scene: bool) -> PackedStringArray:
	var found := PackedStringArray()
	var write := RegEx.create_from_string("\\bz_(index|as_relative)\\s*[-+*/]?=(?!=)"
			+ "|\\bset_z_(index|as_relative)\\s*\\(|[&^]?[\"']z_(index|as_relative)[\"']")
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		if scene:
			if line.begins_with("z_index") or line.begins_with("z_as_relative"):
				found.append(line)
			continue
		if line.begins_with("#"):
			continue
		var code := line.split("#")[0]
		if write.search(code) != null:
			found.append(line)
	return found

static func _files_under(directory: String, suffix: String) -> PackedStringArray:
	var files := PackedStringArray()
	var dir := DirAccess.open(directory)
	if dir == null:
		return files
	for file in dir.get_files():
		if file.ends_with(suffix):
			files.append(directory.path_join(file))
	for child in dir.get_directories():
		files.append_array(_files_under(directory.path_join(child), suffix))
	return files

# ------------------------------------------------------------------ the order ---

## Each ordering is a reason the list states, not its numbers.
func _test_the_layers_keep_their_reasons(t) -> void:
	var z := func(layer: int) -> int: return _z_asked_onto(layer)
	t.check(z.call(DrawLayer.Layer.GROUND) == 0,
			"the ground draws at the engine's default z, where a world's own ground nodes draw")
	t.check(z.call(DrawLayer.Layer.BACKDROP) < z.call(DrawLayer.Layer.GROUND),
			"the stairwell's walls are behind the floor")
	t.check(z.call(DrawLayer.Layer.BUILDINGS) < z.call(DrawLayer.Layer.ENTITIES),
			"nothing on the ground sorts against a building, which is drawn under it")
	t.check(z.call(DrawLayer.Layer.BUILDINGS) < z.call(DrawLayer.Layer.DOORS)
			and z.call(DrawLayer.Layer.DOORS) < z.call(DrawLayer.Layer.ENTITIES),
			"a door is drawn on its wall and always under her")
	t.check(z.call(DrawLayer.Layer.GROUND_MARKS) < z.call(DrawLayer.Layer.ENTITIES)
			and z.call(DrawLayer.Layer.HALO) < z.call(DrawLayer.Layer.ENTITIES),
			"a mark on the ground and the halo's glow are under everything standing on them")
	t.check(z.call(DrawLayer.Layer.ENTITIES) < z.call(DrawLayer.Layer.WARNING)
			and z.call(DrawLayer.Layer.WARNING) < z.call(DrawLayer.Layer.OVERHEAD),
			"a warning figure is over the street's figures and under the tunnel's dark")
	for layer: int in DrawLayer.Layer.values():
		t.check(layer == DrawLayer.Layer.DEBUG
				or z.call(layer) < z.call(DrawLayer.Layer.DEBUG),
				"the debug view is over %s" % DrawLayer.Layer.keys()[layer])

## The `z_index` a node asked onto `layer` draws at (`DrawLayer.draw_on()`, which the game calls).
func _z_asked_onto(layer: int) -> int:
	var node := Node2D.new()
	DrawLayer.draw_on(node, layer)
	var z := node.z_index
	node.free()
	return z

func _test_a_world_adds_a_node_on_its_layer(t) -> void:
	var world := WorldContext.new()
	t.add_child(world)
	var standing := Node2D.new()
	var overhead := Node2D.new()
	world.add_entity(standing)
	world.add_entity(overhead, DrawLayer.Layer.OVERHEAD)
	t.check(standing.get_parent() == world.layers().node(DrawLayer.Layer.ENTITIES)
			and (standing.get_parent() as Node2D).y_sort_enabled,
			"a node added with no layer named stands in the y-sorted entity layer")
	t.check(overhead.get_parent() == world.layers().node(DrawLayer.Layer.OVERHEAD)
			and not (overhead.get_parent() as Node2D).y_sort_enabled,
			"and one added on another layer is drawn on it")
	var raised := Node2D.new()
	world.add_entity(raised)
	DrawLayer.draw_on(raised, DrawLayer.Layer.WARNING)
	t.check(raised.z_index == _z_asked_onto(DrawLayer.Layer.WARNING) and not raised.z_as_relative,
			"a node asked onto another layer where it stands is drawn on that one")
	DrawLayer.draw_on(raised, DrawLayer.Layer.ENTITIES)
	t.check(raised.z_index == _z_asked_onto(DrawLayer.Layer.ENTITIES) and not raised.z_as_relative,
			"and put back, it is drawn with the rest of its layer again")
	world.free()

# ------------------------------------------------------------------- slices ---

func _test_slices_stand_at_their_own_feet(t) -> void:
	var across := DrawLayer.slice_feet(Vector2(-30.0, 5.0), Vector2(30.0, 5.0), 3)
	t.check(across.size() == 3 and across[0] == Vector2(-20.0, 5.0)
			and across[1] == Vector2(0.0, 5.0) and across[2] == Vector2(20.0, 5.0),
			"broadside, each slice stands at the middle of its share (%s)" % across)
	var down := DrawLayer.slice_feet(Vector2(4.0, 30.0), Vector2(4.0, -30.0), 3)
	t.check(down[0] == Vector2(4.0, -10.0) and down[1] == Vector2(4.0, 10.0)
			and down[2] == Vector2(4.0, 30.0),
			"end-on, far end first, each slice stands at the near end of its share (%s)" % down)
	# A length whose shares do not sum back to it exactly in floats: the last feet are the end
	# itself, so a piece standing there shares them.
	var near := Vector2(0.0, 0.1 + 0.2 + 1234.567)
	var odd := DrawLayer.slice_feet(Vector2(0.0, 0.3), near, 7)
	t.check(odd[6] == near, "the last end-on slice stands exactly on the run's near end")
	var footprint := Footprint.of(GroundShape.rect(Vector2(12.0, 96.0)))
	var run := DrawLayer.run_of(footprint, Vector2(100.0, 100.0))
	t.check(run[0] == Vector2(100.0, 4.0) and run[1] == Vector2(100.0, 196.0),
			"a footprint's run is its long piece end to end, far end first (%s)" % run)

## A spread-drawn row stood in a world draws its picture in slices: each a node of its own in the
## world's entity layer at its own feet, covering the body's run, ahead of the instance in the tree
## so the instance's caret is drawn over them at a tie; the rim stands behind the first.
func _test_a_spread_is_drawn_in_slices_ahead_of_its_instance(t) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	var def := EventCatalogue.by_id("construction")
	for vertical: bool in [false, true]:
		var what := "end-on" if vertical else "broadside"
		var world := WorldContext.new()
		t.add_child(world)
		var instance := EventInstance.new()
		instance.atlas = atlas
		instance.setup(def, Vector2(200.0, 200.0), PackedVector2Array(), Vector2.RIGHT,
				_ground_in(world, vertical))
		world.add_entity(instance)
		await t.get_tree().process_frame
		var slices := _slices_of(instance)
		t.check(slices.size() > 1, "%s: the spread is drawn in slices (%d)" % [what, slices.size()])
		var ahead := true
		var on_its_layer := true
		for slice in slices:
			ahead = ahead and slice.get_parent() == instance.get_parent() \
					and slice.get_index() < instance.get_index()
			on_its_layer = on_its_layer \
					and slice.get_parent() == world.layers().node(DrawLayer.Layer.ENTITIES)
		t.check(ahead and on_its_layer,
				"%s: every slice stands in the entity layer ahead of its instance" % what)
		var last := slices[slices.size() - 1].global_position
		var reach := def.obstructs_radius
		var end := instance.global_position + (Vector2(0.0, reach) if vertical
				else Vector2(reach - reach / slices.size(), 0.0))
		t.check(last.is_equal_approx(end),
				"%s: the last slice stands at the body's own end of the run (%s, %s)"
				% [what, last, end])
		if vertical:
			var rising := true
			for i in range(1, slices.size()):
				rising = rising and slices[i].global_position.y > slices[i - 1].global_position.y
			t.check(rising, "end-on, each slice stands nearer the camera than the one before")
		var rim_of := instance.excitement.rim as SourceRim
		rim_of.set_strength(ExcitementHalo.MAX_ALPHA, Palette.HALO_STRONG)
		var rim := instance.rim()
		t.check(rim != null and rim.get_parent() == slices[0]
				and (rim.global_position - instance.global_position).is_zero_approx(),
				"%s: the rim stands behind the first slice, at the instance's own origin" % what)
		rim_of.release()
		world.free()
	atlas.release(&"events")

## **An event's slices go with it** while the world it stood in stays: freed with the instance on
## its own, a frame later no slice of it is left in the world's entity layer. Freeing the world
## would take every slice with it whatever the instance does, so the world is kept.
func _test_the_slices_go_with_their_event(t) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	var world := WorldContext.new()
	t.add_child(world)
	var instance := EventInstance.new()
	instance.atlas = atlas
	instance.setup(EventCatalogue.by_id("construction"), Vector2(200.0, 200.0),
			PackedVector2Array(), Vector2.RIGHT, _open_ground_in(world))
	world.add_entity(instance)
	await t.get_tree().process_frame
	var layer := world.layers().node(DrawLayer.Layer.ENTITIES)
	t.check(_slices_in(layer) > 1, "the event stands in its world in slices (%d)" % _slices_in(layer))
	instance.free()
	await t.get_tree().process_frame
	t.check(_slices_in(layer) == 0, "and a frame after it is freed none of them is left (%d)"
			% _slices_in(layer))
	world.free()
	atlas.release(&"events")

## Open ground drawn in `world`: the map an instance stood in that world is handed, so what it adds
## beside itself goes into the world (`WorldMap.add_entity()`).
static func _open_ground_in(world: WorldContext) -> WorldMap:
	var ground := WorldMap.open_ground()
	ground.world = world
	return ground

## The ground an instance stands on in `world`: an east-west street where it is to run down the
## screen (`vertical`), which it reads its axis off as it does in a city, and open ground otherwise.
static func _ground_in(world: WorldContext, vertical: bool) -> WorldMap:
	if not vertical:
		return _open_ground_in(world)
	var ground: WorldMap = EastWestStreet.new()
	ground.world = world
	return ground

## The slices `instance`'s picture is drawn in, found where the look stood them, beside it in the
## world's entity layer, in their own order (`SpreadLook.Slice.index`, far end first).
static func _slices_of(instance: EventInstance) -> Array[SpreadLook.Slice]:
	var found: Array[SpreadLook.Slice] = []
	for child in instance.get_parent().get_children():
		if child is SpreadLook.Slice and child.instance == instance:
			found.append(child)
	found.sort_custom(func(a: SpreadLook.Slice, b: SpreadLook.Slice) -> bool:
		return a.index < b.index)
	return found

static func _slices_in(layer: Node) -> int:
	var count := 0
	for child in layer.get_children():
		if child is SpreadLook.Slice:
			count += 1
	return count

## **Every long picture the item names is drawn in slices**, not only the spreads: the café, one
## slice a table and its sitter, the protest's rank and the firefight, one slice a figure, and the
## three wide scenes, one a tile of their run.
## Each stands in a world in more than one slice, every slice ahead of its instance in the entity
## layer; a protest's back rank stands up the screen of its front rank; a wide scene's bands
## together cover its picture's run exactly, and end-on its slices rise toward the camera. The bands
## are read off a recording drawer handed in (`tests/recording_event_drawer.gd`), over the same
## atlas, so a crash's and a burst main's scenery is still built behind each slice: the part of
## the picture each slice of a fallen tree was drawn with, and the band each slice's scenery was
## cut to.
func _test_every_long_picture_is_drawn_in_slices(t) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	for id: String in ["cafe_tables", "protest", "firefight", "fallen_tree", "car_accident",
			"burst_water_main"]:
		for vertical: bool in [false, true]:
			var what := "%s %s" % [id, "end-on" if vertical else "broadside"]
			var world := WorldContext.new()
			t.add_child(world)
			var instance := EventInstance.new()
			instance.atlas = atlas
			var drawer := RecordingEventDrawer.new(atlas)
			instance.drawer = drawer
			instance.setup(EventCatalogue.by_id(id), Vector2(300.0, 300.0), PackedVector2Array(),
					Vector2.RIGHT, _ground_in(world, vertical))
			world.add_entity(instance)
			await t.get_tree().process_frame
			var slices := _slices_of(instance)
			var ahead := slices.size() > 1
			for slice in slices:
				ahead = ahead and slice.get_parent() == instance.get_parent() \
						and slice.get_index() < instance.get_index()
			t.check(ahead, "%s: drawn in %d slices ahead of its instance" % [what, slices.size()])
			if id == "protest" and slices.size() > 2:
				t.check(slices[0].global_position.y < slices[slices.size() - 1].global_position.y,
						"%s: the back rank stands up the screen of the front rank" % what)
			if id in ["fallen_tree", "car_accident", "burst_water_main"]:
				# Two frames, so every slice has been drawn.
				await t.get_tree().process_frame
				await t.get_tree().process_frame
				var covered := 0.0
				var bands := 0
				for slice in slices:
					for entry in drawer.shown_on(slice):
						if entry.kind == &"band":
							covered += entry.band.size.y if vertical else entry.band.size.x
							bands += 1
				for entry in drawer.draws:
					if entry.kind == &"scenery":
						covered += entry.band.size.y if vertical else entry.band.size.x
						bands += 1
				t.check(bands == slices.size()
						and is_equal_approx(covered, instance.def.obstructs_radius * 2.0),
						"%s: its %d bands, one a slice, cover its run, %.1f of %.1f"
						% [what, bands, covered, instance.def.obstructs_radius * 2.0])
				if vertical:
					var rising := true
					for i in range(1, slices.size()):
						rising = rising and slices[i].global_position.y \
								> slices[i - 1].global_position.y
					t.check(rising, "%s: each slice stands nearer the camera than the one before"
							% what)
			world.free()
	atlas.release(&"events")
