extends RefCounted
## A park sign shows the picture for the way it points. The sign is handed a drawer that records
## what it draws, as the city hands it the real one; where each sign stands and which way it points
## is `ParkSigns`' (`tests/test_park_signs.gd`), and no city or map is built. The atlas is a fake that
## only counts what the sign acquires and releases, so no page is read.

const RecordingParkSignDrawer := preload("res://tests/recording_park_sign_drawer.gd")
const UI := preload("res://tests/ui_screens.gd")

## An atlas that counts the groups acquired and released instead of loading them.
class CountingAtlas extends AtlasLibrary:
	var acquired: Array[StringName] = []
	var released: Array[StringName] = []

	## Overrides AtlasLibrary.acquire.
	func acquire(group: StringName) -> void:
		acquired.append(group)

	## Overrides AtlasLibrary.release.
	func release(group: StringName) -> void:
		released.append(group)

func run(t: TestRunner) -> void:
	var wanted := {Vector2i.UP: ParkSign.UP, Vector2i.DOWN: ParkSign.DOWN,
		Vector2i.LEFT: ParkSign.LEFT, Vector2i.RIGHT: ParkSign.RIGHT}
	var shown := {}
	for way: Vector2i in wanted:
		var sign := ParkSign.new()
		var drawer := RecordingParkSignDrawer.new()
		var atlas := CountingAtlas.new()
		sign.mount(atlas, drawer, way)
		t.add_child(sign)
		await UI.frames(t, 2)
		shown[way] = drawer.shown()
		t.check(atlas.acquired == [&"street_kit"] and atlas.released.is_empty(),
				"a sign pointing %s acquires street_kit once on entering the tree" % way)
		t.remove_child(sign)
		t.check(atlas.released == [&"street_kit"],
				"a sign pointing %s releases street_kit on leaving the tree" % way)
		sign.free()
	for way: Vector2i in wanted:
		t.check(shown[way] == wanted[way],
				"a sign pointing %s shows %s (%s)" % [way, wanted[way], shown[way]])
	var pictures := {}
	for way: Vector2i in shown:
		pictures[shown[way]] = true
	t.check(pictures.size() == wanted.size(), "every way a sign points has a picture of its own")
