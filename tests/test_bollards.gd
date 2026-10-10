extends RefCounted
## A precinct's posts stop her; the gaps between them and the pavements beside them do not.
##
## The player's words *(2026-10-07, azure-koala: "bollards on the pedestrian zone do not block the
## player"; 2026-10-10, leafy-puffin, asked whether each post stops her with the gaps and sidewalks
## passable or the row bars passage: "gaps still passable")*. Her real `CharacterBody2D` rig is
## swept through real `Prop` posts at the positions `City.bollard_positions()` gives for a
## generated map, with the same synchronous `move_and_collide()` sweep `tests/test_interior.gd`
## uses (the runner cannot advance `move_and_slide()`'s own delta).

const STEP := 8.0
const RUN_UP := 120.0

func run(t) -> void:
	_test_only_the_bollard_has_a_body(t)
	_test_the_post_body_is_its_drawn_ground_contact(t)
	_test_every_gap_holds_her_body(t)
	_test_a_post_stops_her_a_gap_and_a_pavement_do_not(t)

func _prop(t, kind: Prop.Kind, at := Vector2.ZERO) -> Prop:
	var prop := Prop.new()
	prop.kind = kind
	prop.position = at
	t.add_child(prop)
	return prop

func _test_only_the_bollard_has_a_body(t) -> void:
	for kind in [Prop.Kind.TREE, Prop.Kind.STREET_TREE, Prop.Kind.SACK, Prop.Kind.SACK_PILE]:
		var prop := _prop(t, kind)
		t.check(prop.get_node_or_null("BollardBody") == null,
				"Prop.Kind %d stays bodiless (no prop but the post has one)" % kind)
		prop.free()
	var post := _prop(t, Prop.Kind.BOLLARD)
	t.check(post.get_node_or_null("BollardBody") is StaticBody2D, "a bollard has a StaticBody2D")
	post.free()

func _test_the_post_body_is_its_drawn_ground_contact(t) -> void:
	var post := _prop(t, Prop.Kind.BOLLARD)
	var collision := post.get_node("BollardBody").get_child(0) as CollisionShape2D
	var circle := collision.shape as CircleShape2D
	t.check(circle != null and is_equal_approx(circle.radius, post.shape.radius),
			"the post's body is the circle its shadow is drawn from")
	t.check(is_equal_approx(post.shape.radius, 12.0 * 0.4), "and that circle is 4.8px")
	post.free()

## The rows of one map, as lists of cross-axis centres, plus the axis they run along.
func _rows(map: CityMap) -> Array:
	var rows := {}
	var out: Array = []
	var posts := City.bollard_positions(map)
	for span in map.precinct_spans:
		var vertical := span.x == 1
		for at in posts:
			var tile := map.world_to_tile(at)
			if CityMap.junction_index(tile.x if vertical else tile.y) != span.y:
				continue
			var along: float = at.y if vertical else at.x
			var key := "%d:%d:%d" % [span.y, int(vertical), int(along)]
			if not rows.has(key):
				rows[key] = {"vertical": vertical, "along": along, "across": [] as Array[float]}
				out.append(rows[key])
			rows[key].across.append(at.x if vertical else at.y)
	return out

func _test_every_gap_holds_her_body(t) -> void:
	var radius := Prop.new()
	radius.kind = Prop.Kind.BOLLARD
	t.add_child(radius)
	var post_radius: float = radius.shape.radius
	radius.free()
	var body := 2.0 * Tuning.PLAYER_BODY_RADIUS
	var narrowest := INF
	for i in 6:
		var map: CityMap = CityGenerator.generate(1000 + i * 7919)
		for row in _rows(map):
			var across: Array = row.across
			across.sort()
			t.check(across.size() >= 2, "a row has at least two posts, so it has a gap")
			for k in range(1, across.size()):
				narrowest = minf(narrowest, float(across[k]) - float(across[k - 1]) - 2.0 * post_radius)
	t.check(narrowest >= body,
			"the narrowest gap between two posts (%.1fpx) holds her body (%.1fpx)" % [narrowest, body])

## Sweeps a copy of her real rig from `from` along `heading` for `distance`, with the pram body on
## her circumference as `_physics_process()` puts it; returns how far she got.
func _walk(t, from: Vector2, heading: Vector2, distance: float) -> float:
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = from
	var pram := player.get_node("PramCollisionShape2D") as CollisionShape2D
	pram.position = heading * Tuning.PLAYER_BODY_RADIUS
	var walked := 0.0
	while walked < distance:
		var collision := player.move_and_collide(heading * STEP)
		if collision != null:
			break
		walked += STEP
	player.free()
	return walked

func _test_a_post_stops_her_a_gap_and_a_pavement_do_not(t) -> void:
	var map: CityMap = CityGenerator.generate(1000)
	var holder := Node2D.new()
	t.add_child(holder)
	for at in City.bollard_positions(map):
		var post := Prop.new()
		post.kind = Prop.Kind.BOLLARD
		post.position = at
		holder.add_child(post)
	var row: Dictionary = _rows(map)[0]
	var vertical: bool = row.vertical
	var across: Array = row.across
	across.sort()
	var heading := Vector2.DOWN if vertical else Vector2.RIGHT
	var along: float = row.along
	var run := RUN_UP * 2.0
	var through := (float(across[0]) + float(across[1])) * 0.5
	var at_post: float = across[0]
	var band_start := (float(across[0]) - 12.0)
	var on_pavement := band_start - float(Tuning.TILE_SIZE)
	for case in [["a post", at_post, false], ["the gap between two posts", through, true],
			["the pavement beside the row", on_pavement, true]]:
		var cross: float = case[1]
		var start := Vector2(cross, along - RUN_UP) if vertical else Vector2(along - RUN_UP, cross)
		var walked := _walk(t, start, heading, run)
		var passed := walked >= run
		t.check(passed == case[2],
				"walking at %s %s (%.0f of %.0fpx)"
				% [case[0], "passes the row" if passed else "stops at the row", walked, run])
	holder.free()
