extends RefCounted
## Inbox #777 in minty-lemur: once she has walked out of the escape building, nothing of the building stands in
## the city's street.
##
## **What would.** The escape building (`InteriorScene`) puts one `StaticBody2D` on every cell of
## its footprint grown by a cell that is not floor (`InteriorScene._rebuild_collision()`), at its
## own tile coordinates from the world origin. The footprint is tiles (0,0) to (390,25), so the
## blockers cover city rows -1 to 26 wherever the building has no floor, and row 26, the margin, is
## blocked along the city's whole width: the strip from y 832 to 864. The city is built beside the
## building in the same viewport and the same physics space, and none of the blockers has a
## picture, so left in place they are a wall across the city that nobody can see — the player met
## it at tile 74,27. `main._build_the_world_for()` takes them out
## (`InteriorScene.take_the_walls_out()`) before it builds the city.
##
## **Driven through the real `main.tscn`**, booted on the building the way a run's own ending is
## and walked out of through the service door's `exit_requested`, so what it reads is the handover
## itself rather than a copy of it. A boot straight onto the street (`--start-escape city`) never builds the
## building, which is why nothing that starts there meets the wall.
##
## The seed, the day and the tile are the player's run: seed 4216201080 booted by
## `--start-escape`, so day 1, standing at tile 74,27 on the east sidewalk of the tunnel chain's
## street (`docs/evidence/escape-invisible-wall-2026-10-17/`).

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SEED := 4216201080
const DAY := 1
## Where the player stood, a tile below the strip.
const WHERE_SHE_STOOD := Vector2i(74, 27)

func run(t) -> void:
	var saved_section := GameState.facts.escape_section
	GameState.start_run(SEED)
	GameState.header.day = DAY
	GameState.facts.escape_section = DaySpec.Section.BUILDING
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(main._interior != null, "the boot stands in the building")
	main._on_summary_continued(main._flow.mode)
	var before := _her_page_counts(main._player)
	main._interior.exit_requested.emit()
	main._on_summary_continued(main._flow.mode)
	var after := _her_page_counts(main._player)
	t.check(after == before,
			"walking her out into the city leaves her pages' counts as they were (%s, then %s)"
			% [before, after])
	t.check(main._city != null and main._flow.spec.section == DaySpec.Section.CITY,
			"and the service door has put her in the city")
	if main._city != null:
		_test_she_can_walk_north_from_where_the_player_stood(t, main)
		_test_nothing_but_the_city_stands_on_the_escape_streets(t, main)
		_test_nothing_of_the_building_is_drawn_in_the_city(t, main)
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
	GameState.facts.escape_section = saved_section

## The player's own moment: on the sidewalk at 74,27, with the street open ahead of her, a step
## north is not stopped.
func _test_she_can_walk_north_from_where_the_player_stood(t, main: Node2D) -> void:
	var player: Stroller = main._player
	var city: City = main._city
	player.global_position = city.map.tile_to_world(WHERE_SHE_STOOD)
	t.check(city.map.is_walkable(WHERE_SHE_STOOD + Vector2i.UP)
			and city.map.is_walkable(WHERE_SHE_STOOD + Vector2i.UP * 2),
			"the two tiles north of %s are walkable city ground" % WHERE_SHE_STOOD)
	var hit := KinematicCollision2D.new()
	var blocked := player.test_move(player.global_transform, Vector2.UP * Tuning.TILE_SIZE, hit)
	t.check(not blocked, "a tile's step north from %s is not stopped (stopped by %s at %s)"
			% [WHERE_SHE_STOOD, _owner_path(main, hit.get_collider()) if blocked else "nothing",
			hit.get_position() if blocked else Vector2.INF])

## The same thing asked of the whole walk: on every walkable tile of the two chains' open cells, her
## body overlaps no collision body that is not the city's own — the city's buildings, its boundary
## and every event's body all live under `City`, so anything else there is a wall nobody drew.
func _test_nothing_but_the_city_stands_on_the_escape_streets(t, main: Node2D) -> void:
	var city: City = main._city
	var player: Stroller = main._player
	var plan := FinalePlanner.route(city.map)
	var space := city.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = Tuning.PLAYER_BODY_RADIUS
	query.shape = circle
	query.exclude = [player.get_rid()]
	var asked := 0
	var foreign := 0
	var first := ""
	var owners := {}
	for cell: Vector2i in plan.open_cells:
		for dy in ReachabilityGrid.CELL:
			for dx in ReachabilityGrid.CELL:
				var tile := cell * ReachabilityGrid.CELL + Vector2i(dx, dy)
				if not city.map.is_walkable(tile):
					continue
				asked += 1
				query.transform = Transform2D(0.0, city.map.tile_to_world(tile))
				for found in space.intersect_shape(query, 8):
					var body := found["collider"] as Node
					if body == null or city.is_ancestor_of(body):
						continue
					foreign += 1
					var path := _owner_path(main, body)
					owners[path.get_slice("/", 0)] = true
					if first == "":
						first = "%s at tile %s" % [path, tile]
					break
	t.check(asked > 0, "there were walkable tiles on the escape's open cells to ask (%d)" % asked)
	t.check(foreign == 0,
			"no body outside the city stands on them (%d of %d tiles, under %s; first %s)"
			% [foreign, asked, owners.keys(), first])

## **Nothing of the building is drawn once she is in the city.** The building shares the city's
## canvas from the world origin, so its walls and doors stand on the city's top streets: drawn,
## they would show over the city's ground and buildings there. Every picture under the building
## but its fade, which `InteriorScene.clear_fade()` still lifts over the street, is hidden.
func _test_nothing_of_the_building_is_drawn_in_the_city(t, main: Node2D) -> void:
	var interior: InteriorScene = main._interior
	var fade := interior.get_node("FadeLayer")
	var asked := 0
	var drawn := 0
	var shown: Array[String] = []
	var stack: Array[Node] = [interior]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node == fade:
			continue
		stack.append_array(node.get_children())
		var item := node as CanvasItem
		if item == null or not (item is Sprite2D or item is TileMapLayer):
			continue
		asked += 1
		if item.is_visible_in_tree():
			drawn += 1
			if shown.size() < 5:
				shown.append(str(interior.get_path_to(item)))
	t.check(asked > 0, "the building has pictures to ask about (%d)" % asked)
	t.check(drawn == 0, "none of them is drawn in the city (%d of %d drawn, first %s)"
			% [drawn, asked, ", ".join(shown)])

## Her three pages' reference counts — the parent's, the stroller's and the `ui` page — in that
## order. **The walk-out moves her from the building to the city**, out of the tree and back in,
## and a page taken once but given back on every exit leaves the next boot in the same process
## reading it from disk outside the loading window.
static func _her_page_counts(player: Stroller) -> Array[int]:
	return [AtlasLibrary.reference_count(Stroller.parent_atlas(player.is_male)),
			AtlasLibrary.reference_count(Stroller.STROLLER_ATLAS),
			AtlasLibrary.reference_count(Stroller.INDICATOR_ATLAS)]

## `body`'s path below `main`, so a failure names the subtree the body belongs to.
static func _owner_path(main: Node, body: Object) -> String:
	var node := body as Node
	if node == null:
		return str(body)
	return str(main.get_path_to(node))

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
