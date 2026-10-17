extends RefCounted
## Inbox #777: an invisible wall on the escape's city street stops her where she stands. Fails on
## `main` as it is and is meant to; it is the reproduction a fix makes pass.
##
## **What the wall is.** The escape building (`InteriorScene`) puts one `StaticBody2D` on every cell
## of its footprint grown by a cell that is not floor (`InteriorScene._rebuild_collision()`), at its
## own tile coordinates from the world origin. The footprint is tiles (0,0) to (390,25), so the
## blockers cover city rows -1 to 26 wherever the building has no floor, and row 26, the margin, is
## blocked along the city's whole width: the strip from y 832 to 864.
## `main._on_escape_exit_requested()` builds the city beside the building in the same viewport and
## nothing takes the building's bodies out of the physics space, so on the street she walks into
## them. None has a picture: they stand for the building's walls and the empty ground round its
## parts.
##
## **Driven through the real `main.tscn`**, booted on the building the way a run's own ending is
## and walked out of through the service door's `exit_requested`, so a fix anywhere in that path
## is what this reads. A boot straight onto the street (`--start-escape city`) never builds the
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
	var saved_section := GameState.escape_section
	GameState.start_run(SEED)
	GameState.day = DAY
	GameState.escape_section = FinaleController.Section.BUILDING
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(main._interior != null, "the boot stands in the building")
	main._on_finale_summary_continued()
	main._interior.exit_requested.emit()
	main._on_finale_summary_continued()
	t.check(main._city != null and main._finale.section == FinaleController.Section.CITY,
			"and the service door has put her in the city")
	if main._city != null:
		_test_she_can_walk_north_from_where_the_player_stood(t, main)
		_test_nothing_but_the_city_stands_on_the_escape_streets(t, main)
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
	GameState.escape_section = saved_section

## The player's own moment: on the sidewalk at 74,27 with the street open ahead of her, a step north
## goes nowhere.
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
	var plan := FinalePlanner.plan(city.map, GameState.day_rng(GameState.day, "finale"), false)
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

## `body`'s path below `main`, so a failure names the subtree the body belongs to.
static func _owner_path(main: Node, body: Object) -> String:
	var node := body as Node
	if node == null:
		return str(body)
	return str(main.get_path_to(node))
