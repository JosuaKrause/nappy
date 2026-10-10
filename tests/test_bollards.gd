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
	_test_a_diagonal_facing_still_passes_the_gap(t)
	_test_holding_a_diagonal_never_wedges_her_in_front_of_the_row(t)

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
	# Her body plus the pram circle on her edge, which can point along the row (her facing follows
	# the input, not her velocity): 2 x 14 + 8.
	var body := 2.0 * Tuning.PLAYER_BODY_RADIUS + Stroller.PRAM_BODY_RADIUS
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
func _walk(t, from: Vector2, heading: Vector2, distance: float, facing := Vector2.ZERO) -> float:
	if facing == Vector2.ZERO:
		facing = heading
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = from
	var pram := player.get_node("PramCollisionShape2D") as CollisionShape2D
	pram.position = facing * Tuning.PLAYER_BODY_RADIUS
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
	var band_px := float(Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH * 2) * Tuning.TILE_SIZE
	var margin := (band_px - float(across.size() - 1) * City.BOLLARD_SPACING) * 0.5
	var band_start := float(across[0]) - margin
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

## The posts of the first row of seed 1000's first span, `holder` holding them, and the row.
func _row_with_posts(t) -> Array:
	var map := CityGenerator.generate(1000)
	var holder := Node2D.new()
	t.add_child(holder)
	for at in City.bollard_positions(map):
		var post := Prop.new()
		post.kind = Prop.Kind.BOLLARD
		post.position = at
		holder.add_child(post)
	return [holder, _rows(map)[0]]

## The pram circle sits 14px out along her *facing*, which follows the input: a keyboard diagonal
## turns it 45 degrees off the way she moves. Straight through the gap's centre a facing up to
## about 47 degrees fits (14 sin 47 + 8 = 18.2, the gap's half width); a sharper one is slid off
## centre by the sweep a real frame makes, which the wedging test below holds.
func _test_a_diagonal_facing_still_passes_the_gap(t) -> void:
	var made := _row_with_posts(t)
	var holder: Node2D = made[0]
	var row: Dictionary = made[1]
	var vertical: bool = row.vertical
	var across: Array = row.across
	across.sort()
	var heading := Vector2.DOWN if vertical else Vector2.RIGHT
	var along: float = row.along
	var cross := (float(across[0]) + float(across[1])) * 0.5
	var run := RUN_UP * 2.0
	var start := Vector2(cross, along - RUN_UP) if vertical else Vector2(along - RUN_UP, cross)
	for degrees in [0.0, 30.0, 45.0]:
		for sign in [-1.0, 1.0]:
			var facing := heading.rotated(deg_to_rad(degrees) * sign)
			var walked := _walk(t, start, heading, run, facing)
			t.check(walked >= run,
					"through the gap with her facing %.0f degrees off her way (%.0f of %.0fpx)"
					% [degrees * sign, walked, run])
	holder.free()

## Holding a diagonal, a slide loop like `move_and_slide()`'s from many offsets along the row: she
## must end up past it, never stuck in front. Her facing is the held diagonal.
func _test_holding_a_diagonal_never_wedges_her_in_front_of_the_row(t) -> void:
	var made := _row_with_posts(t)
	var holder: Node2D = made[0]
	var row: Dictionary = made[1]
	var vertical: bool = row.vertical
	var across: Array = row.across
	across.sort()
	var forward := Vector2.DOWN if vertical else Vector2.RIGHT
	var sideways := Vector2.RIGHT if vertical else Vector2.DOWN
	var along: float = row.along
	var first: float = across[0]
	var last: float = across[across.size() - 1]
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	for side in [-1.0, 1.0]:
		var held: Vector2 = (forward + sideways * side).normalized()
		for step in 7:
			var cross := lerpf(first - 30.0, last + 30.0, float(step) / 6.0)
			var player: Stroller = packed.instantiate()
			t.add_child(player)
			player.set_physics_process(false)
			var start := Vector2(cross, along - 60.0) if vertical else Vector2(along - 60.0, cross)
			player.global_position = start
			(player.get_node("PramCollisionShape2D") as CollisionShape2D).position = \
					held * Tuning.PLAYER_BODY_RADIUS
			var past := false
			for frame in 240:
				var motion: Vector2 = held * STEP
				var collision: KinematicCollision2D = player.move_and_collide(motion)
				var slides := 0
				while collision != null and slides < player.max_slides:
					motion = collision.get_remainder().slide(collision.get_normal())
					if motion.is_zero_approx():
						break
					collision = player.move_and_collide(motion)
					slides += 1
				var progress := (player.global_position - start).dot(forward)
				if progress > 60.0 + 2.0 * Tuning.PLAYER_BODY_RADIUS + 20.0:
					past = true
					break
			t.check(past, "holding a diagonal (%+.0f) from offset %d along the row, she gets past it"
					% [side, step])
			player.free()
	holder.free()
