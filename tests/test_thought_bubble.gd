extends RefCounted
## `ThoughtBubble`: every picture of the hint it is told to show is laid, through a drawer that
## records what it is told (`SceneryDrawer`, the seam the game hands it through), and nothing once
## it is down. The pictures are the baked `ui` page's (`AtlasLibrary`), read by their regions.

## A drawer that records the textures it is told to lay.
class _Recorder extends SceneryDrawer:
	var _laid: Array[Texture2D] = []

	func laid() -> Array[Texture2D]:
		return _laid

	func forget() -> void:
		_laid.clear()

	## Overrides SceneryDrawer.draw.
	func draw(_canvas: CanvasItem, texture: Texture2D, _rect: Rect2, _source: Rect2) -> void:
		_laid.append(texture)

func run(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	var recorder := _Recorder.new()
	var bubble := ThoughtBubble.new()
	bubble.name = "ThoughtBubble"
	bubble.use_atlas(atlas)
	bubble.draw_through(recorder)
	t.add_child(bubble)
	var frame := atlas.region(ThoughtBubble.FRAME)
	var arrow := atlas.region(ThoughtBubble.ARROW)
	for kind: HintKind.Kind in HintKind.Kind.values():
		recorder.forget()
		bubble.put_up(kind, Vector2.RIGHT)
		await t.get_tree().process_frame
		var icon := atlas.region(HintKind.region_of(kind))
		var wanted: Array[Texture2D] = [frame, icon]
		if HintKind.points(kind):
			wanted.append(arrow)
		t.check(recorder.laid() == wanted, "%s lays the frame, its icon%s (%s)" % [HintKind.id_of(kind),
				" and the arrow" if HintKind.points(kind) else "", recorder.laid()])
		bubble.take_down()
	recorder.forget()
	bubble.put_up(HintKind.Kind.WAY_TO_PARK, Vector2.ZERO)
	await t.get_tree().process_frame
	t.check(recorder.laid().size() == 2, "a pointing hint with no way to point lays no arrow")
	bubble.take_down()
	recorder.forget()
	await t.get_tree().process_frame
	t.check(recorder.laid().is_empty(), "a bubble taken down lays nothing")
	bubble.free()
