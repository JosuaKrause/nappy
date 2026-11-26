extends RefCounted
## Counts the redraw work a figure whose idle frame moves part of it asks for over ten seconds of its
## own clock (brisk-koala, the evidence in docs/evidence/brisk-koala-figure-parts-2026-11-25/): the
## busker strumming, a poster crew pasting at the wall it faces and in a view with no second frame,
## a café frontage on either street, and the three pictures whose motion is drawn rather than
## authored: a firefight's muzzle flashes, a burning building's flames and smoke (on open ground, so
## the five flames of a fire with no facade to burn along) and a loudspeaker mast's lamp, the mast
## over one whole broadcast cycle of its own (`pulses_every()`) rather than ten seconds, since its
## lamp changes twice a cycle. Per case it prints one `IDLE_REDRAWS` line of JSON: the
## `_draw()` calls of every canvas the event stands (the event, its slices and their fronts, the
## layers of its partly animated picture), counted off each canvas's `draw` signal, and the
## pictures and textures those calls laid, counted by the drawers the event is handed. Written to
## run on any revision of the event drawing with the same seams, so the same file measures a base
## and a branch; the counts follow the event's own clock, which the probe steps a sixtieth of a
## second a frame with its physics off, so they are the same on every run.
##
##     tools/test.sh probes/brisk_koala_idle_redraws.gd

const EastWestStreet := preload("res://tests/east_west_street.gd")

const SECONDS := 10.0
const STEP := 1.0 / 60.0

## An event drawer that counts the pictures a look lays through it, and hands the scenery it builds
## a scenery drawer that counts the textures a layer lays.
class CountingDrawer extends EventDrawer:
	var pictures := 0
	var layered := CountingSceneryDrawer.new()

	## Overrides EventDrawer.stand.
	func stand(canvas: CanvasItem, picture: String, foot: Vector2, size := Vector2.ZERO,
			mirrored := false, colour := Color.WHITE) -> void:
		pictures += 1
		super(canvas, picture, foot, size, mirrored, colour)

	## Overrides EventDrawer.paint.
	func paint(canvas: CanvasItem, picture: String, rect: Rect2, colour := Color.WHITE) -> void:
		pictures += 1
		super(canvas, picture, rect, colour)

	## Overrides EventDrawer.paint_band.
	func paint_band(canvas: CanvasItem, picture: String, whole: Rect2, band: Rect2) -> void:
		pictures += 1
		super(canvas, picture, whole, band)

	## Overrides EventDrawer._scenery_drawer.
	func _scenery_drawer() -> SceneryDrawer:
		return layered

## A scenery drawer that counts the textures a layer lays.
class CountingSceneryDrawer extends SceneryDrawer:
	var textures := 0

	## Overrides SceneryDrawer.draw.
	func draw(canvas: CanvasItem, texture: Texture2D, rect: Rect2, source: Rect2) -> void:
		textures += 1
		super(canvas, texture, rect, source)

func run(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	var cases: Array = [
		["busker", Vector2.RIGHT, false],
		["busker", Vector2.UP, false],
		["poster_crew", Vector2.UP, false],
		["poster_crew", Vector2.DOWN, false],
		["cafe_tables", Vector2.RIGHT, false],
		["cafe_tables", Vector2.RIGHT, true],
		["firefight", Vector2.RIGHT, false],
		["burning_building", Vector2.RIGHT, false],
		["loudspeaker", Vector2.RIGHT, false],
	]
	for case: Array in cases:
		var id: String = case[0]
		var heading: Vector2 = case[1]
		var vertical: bool = case[2]
		var holder := Node2D.new()
		holder.name = "Holder"
		t.add_child(holder)
		var drawer := CountingDrawer.new(atlas)
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.shipped().by_id(id), Vector2.ZERO, PackedVector2Array(), heading,
				EventSurroundings.new().reading(EventCatalogue.shipped()).on(EastWestStreet.new() if vertical else WorldMap.open_ground()) \
					.drawn_from(atlas) \
					.drawing_through(drawer))
		instance.set_physics_process(false)
		holder.add_child(instance)
		var seconds := instance.pulses_every() if id == "loudspeaker" else SECONDS
		var frames := roundi(seconds / STEP)
		for i in 3:
			await t.get_tree().process_frame
		instance.step(instance.telegraphs_for() + 0.01)
		for i in 2:
			await t.get_tree().process_frame
		var calls := {}
		for node in _canvases(holder):
			var kind := _kind(node)
			if not calls.has(kind):
				calls[kind] = {"canvases": 0, "draws": 0}
			calls[kind].canvases += 1
			node.draw.connect(func() -> void: calls[kind].draws += 1)
		drawer.pictures = 0
		drawer.layered.textures = 0
		for i in frames:
			instance.step(STEP)
			await t.get_tree().process_frame
		var line := {"id": id, "heading": [heading.x, heading.y], "vertical": vertical,
			"seconds": frames * STEP, "calls": calls, "pictures": drawer.pictures,
			"layer_textures": drawer.layered.textures}
		print("IDLE_REDRAWS " + JSON.stringify(line))
		t.check(not calls.is_empty(), "%s stood canvases to count" % id)
		instance.free()
		holder.free()
		await t.get_tree().process_frame
	atlas.release(&"events")

## Every canvas under `root`: the event, the slices it stood beside itself, and what they hold.
func _canvases(root: Node) -> Array[CanvasItem]:
	var found: Array[CanvasItem] = []
	for child in root.get_children():
		if child is CanvasItem:
			found.append(child as CanvasItem)
		found.append_array(_canvases(child))
	return found

## What a canvas is, for the count: the event, a slice, a slice's front, a layer of a partly
## animated picture, or another drawing node.
func _kind(node: CanvasItem) -> String:
	if node is EventInstance:
		return "event"
	if node is SceneryLayer:
		return "layer"
	if node.name.begins_with("Slice"):
		return "slice"
	if node.name == "Front":
		return "front"
	return "other"
