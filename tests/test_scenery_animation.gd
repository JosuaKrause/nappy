extends RefCounted
## Scenery phases update their own retained layers without changing static layout or bodies.

const RecordingRoofDrawer := preload("res://tests/recording_roof_drawer.gd")
const RecordingSceneryDrawer := preload("res://tests/recording_scenery_drawer.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")
const EastWestStreet := preload("res://tests/east_west_street.gd")
const PageLog := preload("res://tests/atlas_page_log.gd")

func run(t: TestRunner) -> void:
	await _test_roof_rotors(t)
	_test_both_rotor_phases_share_one_registration(t)
	await _test_event_parts(t)
	await _test_figure_parts(t)

## A roof that is told what to stand through a recording drawer (`tests/recording_roof_drawer.gd`,
## standing each unit for real so a vent has its rotor), handed in as the city hands its own
## (`Building.equip()`), and whose own process frames run in the tree. Its rotors are read off the
## units it was told to stand (`RoofObject.rotor`), never off what the building holds, and the
## phase each rotor shows is the picture it stands, read off the scenery drawer the real roof drawer
## hands every rotor (`tests/recording_scenery_drawer.gd`), as the city hands its own. Its body is
## the collision shape it stands, which the physics engine reads. Time is the engine's
## `time_scale`, which scales the delta the building's process frame is given: a frame at a
## hundredth of its length cannot reach the interval, and one at a hundred thousand times its length
## always crosses it, so no check depends on how long a frame takes.
func _test_roof_rotors(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var drawer := RecordingRoofDrawer.new()
	var scenery := RecordingSceneryDrawer.new()
	drawer.real = RoofDrawer.new(atlas, scenery)
	var building := Building.new()
	building.equip(atlas, drawer, FrontDrawer.new(atlas))
	building.stand_on(Rect2i(), Vector2(256, 256), building.look_variant(),
			GameEnums.BlockPurpose.INDUSTRIAL, 64)
	t.add_child(building)
	# Equipped as the city equips it, the building waits for the residency, which stands a building
	# in view up.
	building.residence().set_resident(true)
	for variant in 200:
		if not _rotors(drawer).is_empty():
			break
		building.draw_as(building.district(), variant + 1, building.height())
	t.check(not _rotors(drawer).is_empty(), "the roof fixture actually has moving vents")
	var body := _collision_shape(building)
	var drawn := drawer.draws.size()
	var objects: Array[Building.RoofObject] = []
	for entry in drawer.standing():
		objects.append(entry.object)
	var rotors := _rotors(drawer)
	t.check(building.is_processing(), "a roof with a vent takes its process frames")
	var clock := Engine.time_scale
	Engine.time_scale = 0.01
	# The rotors are drawn on the frame they were stood up in.
	await t.get_tree().process_frame
	var first_phase := _picture_on(scenery, rotors[0]) == _rotor_picture(atlas, true)
	for frame in 3:
		if frame > 0:
			await t.get_tree().process_frame
		for rotor in _rotors(drawer):
			t.check(_picture_on(scenery, rotor) == _rotor_picture(atlas, first_phase),
					"a rotor stands the picture of its first phase until the existing interval")
	Engine.time_scale = clock
	# The frame after this one is given a delta a hundred thousand times its length, so it crosses
	# the interval once; the scale is back before the frame after that.
	Engine.time_scale = 100000.0
	await t.get_tree().process_frame
	Engine.time_scale = clock
	await t.get_tree().process_frame
	var turned := _rotors(drawer)
	t.check(_picture_on(scenery, turned[0]) == _rotor_picture(atlas, not first_phase),
			"the building's own process frames turn its rotors once the interval has passed")
	var phase := not first_phase
	for rotor in turned:
		# One of the two phases is the alternate frame, so between this and the first phase's check
		# every rotor has stood both its pictures.
		t.check(_picture_on(scenery, rotor) == _rotor_picture(atlas, phase),
				"the small rotors advance together, each drawn again on the turn with its new picture")
	for object in objects:
		if object.texture_key != Building.VENT_HOUSING:
			t.check(object.get_child_count() == 0,
					"stationary roof objects own no independently redrawn child")
	t.check(drawer.draws.size() == drawn, "animation does not redraw or reroll the roof's furniture")
	t.check(_collision_shape(building) == body, "animation does not rebuild collision")
	# A rebuild from the facts the city hands a building: the lot, the size, the look and the height.
	building.stand_on(building.lot_rect(), Vector2(256, 256), building.look_variant(), building.district(),
			building.height())
	for object in objects:
		t.check(not is_instance_valid(object), "rebuild releases every superseded roof object")
	t.check(drawer.standing().size() == objects.size()
			and drawer.draws.size() == drawn + objects.size(),
			"rebuild draws the roof again, once")
	for entry in drawer.standing():
		if entry.texture == Building.VENT_HOUSING:
			t.check(entry.rotor_frame_b == phase, "the rebuilt roof is told the current phase")
	await _a_still_frame(t)
	for rotor in _rotors(drawer):
		t.check(_picture_on(scenery, rotor) == _rotor_picture(atlas, phase),
				"rebuilding the roof preserves the current phase")
	var old_rotor: WeakRef = weakref(atlas.region(Building.VENT_ROTOR))
	t.remove_child(building)
	t.check(drawer.standing().is_empty(),
			"tree exit releases every roof object and moving child")
	if not pages.held(&"buildings"):
		t.check(old_rotor.get_ref() == null, "the last building retains no atlas texture after exit")
	t.add_child(building)
	var reentered := _rotors(drawer)
	await _a_still_frame(t)
	t.check(not reentered.is_empty()
			and _picture_on(scenery, reentered[0]) == _rotor_picture(atlas, phase),
			"reentry acquires fresh regions and preserves the animation phase")
	building.stand_on(building.lot_rect(), Vector2(32, 32), building.look_variant(), building.district(),
			building.height())
	t.check(_rotors(drawer).is_empty() and not building.is_processing(),
			"a roof without vents releases them and stops its animation callback")
	building.free()
	pages.stop()

## One process frame at a hundredth of its length, which no rotor's interval fits in, so what was
## stood up before it is drawn and nothing turns while it passes.
func _a_still_frame(t: TestRunner) -> void:
	var clock := Engine.time_scale
	Engine.time_scale = 0.01
	await t.get_tree().process_frame
	Engine.time_scale = clock

## The shape of `building`'s body as the physics engine reads it, its collision child's.
func _collision_shape(building: Building) -> Shape2D:
	for child in building.get_children():
		if child is CollisionShape2D:
			return (child as CollisionShape2D).shape
	return null

## The turning rotor of every vent the drawer was told to stand and the building has not released.
func _rotors(drawer: RecordingRoofDrawer) -> Array[SceneryLayer]:
	var rotors: Array[SceneryLayer] = []
	for entry in drawer.standing():
		var object: Building.RoofObject = entry.object
		if object.rotor != null:
			rotors.append(object.rotor)
	return rotors

## The one picture `layer` stood the last time it was drawn through `scenery`, or null for none or
## more than one.
func _picture_on(scenery: RecordingSceneryDrawer, layer: SceneryLayer) -> Texture2D:
	var shown := scenery.shown_on(layer)
	return shown[0].texture if shown.size() == 1 else null

## The rotor's picture at `frame_b`: the alternate frame when it is set.
func _rotor_picture(atlas: AtlasLibrary, frame_b: bool) -> Texture2D:
	return atlas.region(Building.VENT_ROTOR_B if frame_b else Building.VENT_ROTOR)

## Both rotor frames are cropped out of the housing canvas from their editable vector sources, whose
## viewBoxes must agree, or the second frame would jump when the rotor turns.
func _test_both_rotor_phases_share_one_registration(t: TestRunner) -> void:
	var authored: Array[Rect2] = []
	for path: String in ["res://art/props/industrial_vent_rotor.svg",
			"res://art/props/industrial_vent_rotor_b.svg"]:
		var source := FileAccess.get_file_as_string(path)
		var regex := RegEx.new()
		t.check(regex.compile('viewBox="([0-9.]+) ([0-9.]+) ([0-9.]+) ([0-9.]+)"') == OK,
				"the rotor crop viewBox pattern compiles")
		var found := regex.search(source)
		t.check(found != null, "%s carries a registered viewBox" % path.get_file())
		if found != null:
			authored.append(Rect2(float(found.get_string(1)), float(found.get_string(2)),
					float(found.get_string(3)), float(found.get_string(4))))
	t.check(authored.size() == 2 and authored[0] == authored[1],
			"both rotor phases share one registration in the housing canvas")

## A crash and a burst main are drawn in slices, each holding its part's scenery
## (`SpreadLook.Slice`, `EventScenery`), so what is asked here is asked of every slice's. The
## axis it spreads on is the street it stands on (`EastWestStreet` is one running east-west), the
## way the game hands `setup()` a map. What each layer of the scenery stands is read off a recording
## scenery drawer, handed to the scenery by the event's drawer (`EventSurroundings.drawer()`, as its
## manager's spawner hands the real one) the way the real one hands its own.
func _test_event_parts(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	for id: String in ["car_accident", "burst_water_main"]:
		for vertical: bool in [false, true]:
			var instance := EventInstance.new()
			var laid := RecordingSceneryDrawer.new()
			var pictures := RecordingEventDrawer.new(atlas)
			pictures.scenery_drawer = laid
			instance.setup(Shipped.rows().by_id(id), Vector2.ZERO,
					PackedVector2Array(), Vector2.RIGHT,
					EventSurroundings.new().reading(Shipped.rows()) \
					.on(EastWestStreet.new() if vertical else WorldMap.open_ground()) \
						.drawn_from(atlas) \
						.drawing_through(pictures))
			t.add_child(instance)
			t.check(instance.runs_vertically() == vertical, "%s stands on the axis asked for" % id)
			# The slices go into the world on the idle frame after the instance is made.
			await t.get_tree().process_frame
			instance.step(instance.telegraphs_for() + 0.01)
			var sceneries := _sceneries_of(pictures)
			# The redraw gate is asked of a look made round a fake event of the same row on the
			# same axis, so that animation leaving the static key alone is asked of the gate on
			# its own: its first ask after nothing was drawn is a draw.
			var gated := FakeEvent.new()
			gated.vertical = vertical
			var gate := gated.look_for(Shipped.rows().by_id(id))
			var first_ask := gate.redraw_if_the_picture_changed()
			# The layers are drawn on the frame after they are made.
			await t.get_tree().process_frame
			var moving: Array[SceneryLayer] = []
			var still: Array[SceneryLayer] = []
			# The instance's own process frame shows its clock's frame on every scenery, so it is
			# held while each frame is shown in turn.
			instance.set_process(false)
			for scenery: EventScenery in sceneries:
				var split: Array = await _split_by_animation(t, scenery, laid)
				moving.append_array(split[0])
				still.append_array(split[1])
			instance.set_process(true)
			t.check(sceneries.size() > 1 and not moving.is_empty(),
					"%s/%s has independently moving detail across its slices" % [id, vertical])
			var body := _body_of(instance)
			var centers := _centres_of(instance)
			t.check(body != null and instance.is_solid(), "%s/%s stands a solid body" % [id, vertical])
			t.check(first_ask,
					"the event's first drawn frame asks for its draw, so the gate is live for the check below")
			var period := EventPictures.CAR_ACCIDENT_SMOKE_PERIOD if id == "car_accident" \
					else EventPictures.BURST_MAIN_SPLASH_PERIOD
			var before := {}
			for layer: SceneryLayer in moving + still:
				before[layer] = _pictures_on(laid, layer)
			instance.step(period * 0.5)
			gated.tick(period * 0.5, 0.0)
			var asked := gate.redraw_if_the_picture_changed()
			gated.free()
			await t.get_tree().process_frame
			for layer in moving:
				var turned := _pictures_on(laid, layer)
				var earlier: Array[Texture2D] = before[layer]
				t.check(not turned.is_empty() and turned.size() == earlier.size()
						and _all_differ(turned, earlier),
						"the existing event clock advances each detail: every moving detail stands"
						+ " its alternate picture once its frame flips")
			# Nothing flips a stationary layer's frame, so each shows its first; turned to its
			# alternate here through the call its scenery turns a moving one's with, it is drawn
			# again with the same pictures.
			var passes := {}
			for layer in still:
				passes[layer] = laid.passes_of(layer)
				layer.show_frame_b(true)
			await t.get_tree().process_frame
			for layer in still:
				var earlier: Array[Texture2D] = before[layer]
				t.check(laid.passes_of(layer) > passes[layer]
						and not earlier.is_empty()
						and _pictures_on(laid, layer) == earlier,
						"stationary surroundings have no alternate picture")
				layer.show_frame_b(false)
			t.check(not asked, "animation leaves the static event key alone")
			t.check(_body_of(instance) == body and _centres_of(instance) == centers,
					"animation preserves both collision resource and placement")
			# Detached, it takes its slices and their scenery with it; back in the tree, it builds
			# them again once it has settled.
			t.remove_child(instance)
			await t.get_tree().process_frame
			t.check(sceneries.all(func(scenery: Variant) -> bool:
					return not is_instance_valid(scenery)),
					"detaching the event releases its scenery and its retained atlas regions")
			t.add_child(instance)
			await t.get_tree().process_frame
			var rebound := false
			instance.set_process(false)
			for scenery in _sceneries_of(pictures):
				# The look's frame is held, so its layers are drawn and their pictures read.
				var split: Array = await _split_by_animation(t, scenery, laid)
				var animated: Array = split[0]
				rebound = rebound or not animated.is_empty()
			instance.set_process(true)
			t.check(rebound, "reentry rebinds event scenery regions")
			var again := _sceneries_of(pictures)
			instance.free()
			await t.get_tree().process_frame
			t.check(again.all(func(scenery: Variant) -> bool:
					return not is_instance_valid(scenery)),
					"removing an event releases its scenery")
	atlas.release(&"events")

## A figure whose idle frame moves only part of it (the busker's strumming arm, a poster crew's
## brush pasting at the wall it faces, a café sitter's lean) stands as layers of its own
## (`EventScenery`) on its event, or on its table's slice for a café, in its view's mirror. What is
## held is the player's guarantee (sunny-lynx): the frame swaps the moving layers' pictures, and
## the stationary layers, the event's own canvas and a café's slice and table are not drawn again
## for it. Counted off each canvas's `draw` signal, which a headless run emits like any other.
func _test_figure_parts(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	# The row, the heading it is sited along, the street it stands on, the period it swaps on and
	# whether its view is the mirrored one: 1 for mirrored, 0 for not, -1 for a café, whose sitters
	# each face their own table (`tests/test_event_views.gd` holds which way).
	var cases: Array = [
		["busker", Vector2.RIGHT, false, EventPictures.BUSKER_STRUM_PERIOD, 0],
		["busker", Vector2.LEFT, false, EventPictures.BUSKER_STRUM_PERIOD, 1],
		["busker", Vector2.DOWN, false, EventPictures.BUSKER_STRUM_PERIOD, 0],
		["poster_crew", Vector2.UP, false, EventPictures.POSTER_CREW_PASTE_PERIOD, 0],
		["cafe_tables", Vector2.RIGHT, false, EventPictures.SITTER_IDLE_PERIOD, -1],
		["cafe_tables", Vector2.RIGHT, true, EventPictures.SITTER_IDLE_PERIOD, -1],
	]
	for case: Array in cases:
		var id: String = case[0]
		var heading: Vector2 = case[1]
		var vertical: bool = case[2]
		var period: float = case[3]
		var what := "%s sited %s%s" % [id, heading, " on a north-south street" if vertical else ""]
		var instance := EventInstance.new()
		var laid := RecordingSceneryDrawer.new()
		var pictures := RecordingEventDrawer.new(atlas)
		pictures.scenery_drawer = laid
		instance.setup(Shipped.rows().by_id(id), Vector2.ZERO, PackedVector2Array(),
				heading,
				EventSurroundings.new().reading(Shipped.rows()) \
				.on(EastWestStreet.new() if vertical else WorldMap.open_ground()) \
					.drawn_from(atlas) \
					.drawing_through(pictures))
		t.add_child(instance)
		# A café's slices go into the world on the idle frame after it is made; every layer is drawn
		# on the frame after that.
		for i in 3:
			await t.get_tree().process_frame
		# Past its telegraph, whose end is a change of its picture.
		instance.step(instance.telegraphs_for() + 0.01)
		await t.get_tree().process_frame
		var sceneries := _sceneries_of(pictures)
		# The busker and a crew stand one figure; a café one sitter per table.
		t.check(not sceneries.is_empty(), "%s stands its figures as layers of their own (%d)"
				% [what, sceneries.size()])
		var owners: Array[CanvasItem] = [instance]
		var moving: Array[SceneryLayer] = []
		var still: Array[SceneryLayer] = []
		var mirrored_as_its_view := true
		var inside := true
		for figure in sceneries:
			var entry: Dictionary = {}
			for drawn in pictures.draws:
				if drawn.canvas == figure:
					entry = drawn
			var holder := figure.get_parent() as CanvasItem
			if holder != instance:
				owners.append(holder)
				for child in holder.get_children():
					if child is CanvasItem and child != figure:
						owners.append(child)
			var mirror: int = case[4]
			mirrored_as_its_view = mirrored_as_its_view and (mirror < 0 or entry.mirrored == (mirror == 1))
			instance.set_process(false)
			var split: Array = await _split_by_animation(t, figure, laid)
			instance.set_process(true)
			var turning: Array[SceneryLayer] = []
			turning.assign(split[0])
			var standing: Array[SceneryLayer] = []
			standing.assign(split[1])
			t.check(not turning.is_empty() and not standing.is_empty(),
					"%s keeps a stationary layer and a moving one (%d, %d)"
							% [what, standing.size(), turning.size()])
			moving.append_array(turning)
			still.append_array(standing)
			# Every part is registered inside the figure's own canvas at its feet.
			var whole := Rect2(-entry.size.x * 0.5, -entry.size.y, entry.size.x, entry.size.y)
			for layer in turning + standing:
				for part in laid.shown_on(layer):
					var rect: Rect2 = part.rect
					if not entry.mirrored:
						rect.position -= entry.foot
					inside = inside and whole.grow(0.01).encloses(rect)
		t.check(mirrored_as_its_view, "%s mirrors its figures as their view does" % what)
		t.check(inside, "%s registers every part inside its own canvas" % what)
		var redraws := {}
		for canvas: CanvasItem in owners + still:
			redraws[canvas] = 0
			canvas.draw.connect(func() -> void: redraws[canvas] += 1)
		var before := {}
		for layer in moving:
			before[layer] = _pictures_on(laid, layer)
		instance.step(period * 0.5)
		await t.get_tree().process_frame
		var turned := not moving.is_empty()
		for layer in moving:
			var earlier: Array[Texture2D] = before[layer]
			turned = turned and _all_differ(_pictures_on(laid, layer), earlier)
		t.check(turned, "%s's clock swaps every moving layer's picture" % what)
		instance.step(period * 0.5)
		await t.get_tree().process_frame
		var still_drawn := 0
		for canvas: CanvasItem in owners + still:
			still_drawn += int(redraws[canvas])
		t.check(still_drawn == 0,
				"%s's two swaps draw none of its stationary layers, its event or its slice again (%d)"
						% [what, still_drawn])
		instance.free()
		await t.get_tree().process_frame
		t.check(sceneries.all(func(figure: Variant) -> bool: return not is_instance_valid(figure)),
				"%s's figures go with their event" % what)
	atlas.release(&"events")

## The pictures `layer` stood the last time it was drawn through `scenery`, in order.
func _pictures_on(scenery: RecordingSceneryDrawer, layer: SceneryLayer) -> Array[Texture2D]:
	var pictures: Array[Texture2D] = []
	for entry in scenery.shown_on(layer):
		pictures.append(entry.texture)
	return pictures

## Whether every picture of `a` differs from the one at its place in `b`, the two the same length.
func _all_differ(a: Array[Texture2D], b: Array[Texture2D]) -> bool:
	for i in a.size():
		if a[i] == b[i]:
			return false
	return true

## The layers `scenery` holds as `[moving, still]`: the moving ones are the layers whose pictures
## its `set_frame()` turns to their alternate, read off what each stands through `laid`; the still
## ones the rest (its contact shadow and its static spans). Each frame is shown and drawn in turn,
## and the frame it showed is put back and drawn; the event's own process frame, which shows its
## clock's frame, is held by the caller meanwhile.
func _split_by_animation(t: TestRunner, scenery: EventScenery, laid: RecordingSceneryDrawer) -> Array:
	var layers: Array[SceneryLayer] = []
	for child in scenery.get_children():
		if child is SceneryLayer:
			layers.append(child)
	var had := {}
	for layer in layers:
		had[layer] = _pictures_on(laid, layer)
	scenery.set_frame(true)
	await t.get_tree().process_frame
	var on := {}
	for layer in layers:
		on[layer] = _pictures_on(laid, layer)
	scenery.set_frame(false)
	await t.get_tree().process_frame
	var moving: Array[SceneryLayer] = []
	moving.assign(layers.filter(func(l: SceneryLayer) -> bool: return _pictures_on(laid, l) != on[l]))
	var still: Array[SceneryLayer] = []
	still.assign(layers.filter(func(l: SceneryLayer) -> bool: return not moving.has(l)))
	scenery.set_frame(not moving.is_empty() and had[moving[0]] == on[moving[0]])
	await t.get_tree().process_frame
	return [moving, still]

## The scenery behind each slice, in the slices' order, that `pictures` was handed to build and that
## still stands: the layers of a slice it was drawn behind.
func _sceneries_of(pictures: RecordingEventDrawer) -> Array[EventScenery]:
	var found: Array[EventScenery] = []
	for entry in pictures.draws:
		if entry.kind == &"scenery" and is_instance_valid(entry.canvas):
			found.append(entry.canvas as EventScenery)
	return found

## Where each of an instance's solid pieces stands, in world space.
func _centres_of(instance: EventInstance) -> PackedVector2Array:
	var centres := PackedVector2Array()
	for piece in instance.standing_pieces():
		centres.append(piece.center())
	return centres

## The one solid body the instance stands, or null.
func _body_of(instance: EventInstance) -> StaticBody2D:
	for child in instance.get_children():
		if child is StaticBody2D:
			return child
	return null
