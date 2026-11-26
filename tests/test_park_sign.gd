extends RefCounted
## A park sign shows the picture for the way it points. The sign is handed a drawer that records
## what it draws, as the city hands it the real one; where each sign stands and which way it points
## is `ParkSigns`' (`tests/test_park_signs.gd`), and no city or map is built.

const RecordingParkSignDrawer := preload("res://tests/recording_park_sign_drawer.gd")
const UI := preload("res://tests/ui_screens.gd")

func run(t: TestRunner) -> void:
	var wanted := {Vector2i.UP: ParkSign.UP, Vector2i.DOWN: ParkSign.DOWN,
		Vector2i.LEFT: ParkSign.LEFT, Vector2i.RIGHT: ParkSign.RIGHT}
	var shown := {}
	for way: Vector2i in wanted:
		var sign := ParkSign.new()
		var drawer := RecordingParkSignDrawer.new()
		sign.mount(null, drawer, way)
		t.add_child(sign)
		await UI.frames(t, 2)
		shown[way] = drawer.shown()
		sign.free()
	for way: Vector2i in wanted:
		t.check(shown[way] == wanted[way],
				"a sign pointing %s shows %s (%s)" % [way, wanted[way], shown[way]])
	var pictures := {}
	for way: Vector2i in shown:
		pictures[shown[way]] = true
	t.check(pictures.size() == wanted.size(), "every way a sign points has a picture of its own")
