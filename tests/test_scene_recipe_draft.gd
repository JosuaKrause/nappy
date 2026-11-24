extends RefCounted
## `SceneRecipeDraft`: the stretch a draft cuts out of the whole city it walked
## (`tools/scene-draft.sh`), asked as a draft run asks it. A scene's recipe is turned into the
## witness map its drafting inputs make (`SceneRecipeDraft.base_of()`), the tiles she walked are
## recorded (`record()`), the stretch is composed (`compose()`) and `stretch.tiles` read back:
## a step on a street takes the whole street and the junction at each end, a mark she reads from
## beside it brings its own corner and not the alley behind it, and walking into an alley takes the
## whole of it. The drafted recipe's JSON reads back as written.
##
## **One module, on a world of stand-ins** (`tests/scene_world.gd`): the draft is handed the world a
## draft run is handed (`DayWorld`), whose dressing, crowd, events, poster walls, her and the baby
## are stand-ins that answer none of what a scene stands in the street: the dressing no buildings
## and no props, the crowd and the events nobody. What the checks read is the map and the day's own
## planners (a real map built by `RecipeCityBuilder.build()` and begun for the day by
## `SceneWorld.over()`), which are model data, so the draft's tiles are the only part asked of it;
## its buildings, props, litter, cracks, posters and starting crowd are not.

## The scene the draft is asked over: day 7's package task.
const SCENE := "res://scene-recipes/task-07-package.json"
## The day it is walked on.
const DAY := 7
## A mark she reads from beside it, at an alley's mouth of the context city, and the alley behind it.
const MOUTH := Vector2i(92, 69)

## The diagnostics a builder's answer carries.
func _errors(result: Dictionary) -> Array[String]:
	return result.errors

func run(t: TestRunner) -> void:
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	_test_the_json_reads_back_as_written(t, data)
	var built := RecipeCityBuilder.build(SceneRecipeDraft.base_of(data))
	t.check(_errors(built).is_empty(), "the draft's witness builds: %s" % [built.errors])
	if not _errors(built).is_empty():
		return
	var witness: CityMap = built.map
	var made := SceneWorld.over(witness, DAY)
	_test_the_draft_takes_whole_streets(t, made, data)
	made.free_all()

## **A drafted recipe's JSON** (`SceneRecipeDraft.to_json()`, laid out the way the checked-in
## recipes are read) parses, and parses to the ground it was written from.
func _test_the_json_reads_back_as_written(t: TestRunner, data: Dictionary) -> void:
	var parser := JSON.new()
	t.check(parser.parse(SceneRecipeDraft.to_json(data)) == OK, "a drafted recipe serializes")
	var back: Dictionary = parser.data
	t.check(not _listed(data).is_empty() and _listed(back) == _listed(data),
			"and reads back with the same ground")

## **A draft takes whole streets**: a step on a street takes the whole street and the junction at
## each end, a mark she reads from beside it, pinned by the task, brings its own corner and not the
## alley behind it (`SceneRecipeDraft.compose()` adds a pin as unwalked), and walking in at the same
## mouth takes the whole alley behind it.
func _test_the_draft_takes_whole_streets(t: TestRunner, made: SceneWorld, data: Dictionary) -> void:
	var witness := made.map
	var segment := witness.street_network().by_key(Vector3i(5, 5, 1))
	var drafted := _drafted(made, data, [Vector2i(segment.tile_rect().get_center())], [])
	var ground := _listed(drafted)
	var whole := true
	for tile in witness.rect_tiles(segment.tile_rect()):
		whole = whole and (ground.has(tile) or not witness.is_walkable(tile))
	for end: Vector2i in [segment.a, segment.b]:
		var box := Rect2i(end * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
		for tile in witness.rect_tiles(box):
			whole = whole and (ground.has(tile) or not witness.is_walkable(tile))
	t.check(whole and not ground.is_empty(),
			"a step on a street takes the whole street and the junction at each end")
	var behind := MOUTH + Vector2i.UP * 4
	var home := witness.world_to_tile(witness.doorstep_world_position())
	var pinned := _listed(_drafted(made, data, [home], [witness.tile_to_world(MOUTH)]))
	t.check(pinned.has(MOUTH) and not pinned.has(behind),
			"a pinned mark brings its own corner, not the alley behind it")
	var walked := _listed(_drafted(made, data, [home, MOUTH], []))
	t.check(walked.has(behind), "walking in at the same mouth takes the whole alley behind it")

## The stretch a draft that walked `walked` (tiles, in order) and was pinned `pinned` (world
## points) composes for `data`'s recipe over `made`'s world, in a run of its own on `DAY`.
func _drafted(made: SceneWorld, data: Dictionary, walked: Array[Vector2i],
		pinned: Array[Vector2]) -> Dictionary:
	var draft := SceneRecipeDraft.new()
	var walker := Node2D.new()
	for tile in walked:
		walker.position = made.map.tile_to_world(tile)
		draft.record(walker, made.world, null)
	walker.free()
	var own_run := RunState.new()
	own_run.start_run(DAY)
	own_run.header().set_day(DAY)
	var problems: Array[String] = []
	return draft.compose(data, own_run, made.world, made.map.tile_to_world(walked[0]), pinned,
			problems)

## The tiles a drafted recipe's `stretch.tiles` lists, as a set.
func _listed(drafted: Dictionary) -> Dictionary:
	var listed := {}
	for type_name: String in drafted.stretch.tiles:
		for run: Array in drafted.stretch.tiles[type_name]:
			for x in range(int(run[1]), int(run[2]) + 1):
				listed[Vector2i(x, int(run[0]))] = true
	return listed
