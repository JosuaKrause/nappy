extends RefCounted
## **Whether a touch from a place completes a contact, asked the way the game asks it**: by standing
## her there for a physics frame. A helper, not a suite: the runner loads only `test_*.gd`.
##
## A contact completes on the first physics frame she is in reach of it (`ContactPoint`), and completing
## is once and for all, so a suite that asks the same contact about many places cannot stand her at
## each in turn. `touches_from()` stands a twin of the contact the director offers at every place it
## is asked about, each with a stroller of its own on that place, and lets one frame pass: the twin
## has the director's contact's step, place, reach, touch ellipse and rider, so a place completes it
## exactly where it completes the director's.

## For each of `points`, whether standing there for a physics frame completes `director`'s contact
## (the one `director.contact()` answers): `[true, false, ...]` in the order of `points`. The
## director's own contact, and the day, are left as they were. `t` is the suite's test node, which the
## twins and their strollers are added to for the frame and freed from after it.
static func touches_from(t, director: ResistanceDirector, points: Array[Vector2]) -> Array[bool]:
	var live := director.contact()
	var twins: Array[ContactPoint] = []
	var players: Array[Stroller] = []
	for point in points:
		var player := Stroller.new()
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		player.add_child(camera)
		t.add_child(player)
		player.set_physics_process(false)
		player.global_position = point
		var twin := ContactPoint.new()
		if director.rider() != null:
			twin.ride(live.task_step(), director.rider(), live.global_position - director.rider().global_position)
		else:
			twin.setup(live.task_step(), live.global_position)
		director._shape_the_touch(twin, live.task_step())
		twin.complete_within(live.touch_reach())
		twin.use_player(player)
		t.add_child(twin)
		if director.rider() == null:
			twin.global_position = live.global_position
		twins.append(twin)
		players.append(player)
	await t.get_tree().physics_frame
	await t.get_tree().process_frame
	var touched: Array[bool] = []
	for twin in twins:
		touched.append(twin.is_done)
	for twin in twins:
		twin.free()
	for player in players:
		player.free()
	return touched

## The same for one place.
static func touches_from_one(t, director: ResistanceDirector, point: Vector2) -> bool:
	var answers: Array[bool] = await touches_from(t, director, [point] as Array[Vector2])
	return answers[0]
