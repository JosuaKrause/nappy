extends RefCounted
## A precinct's posts shut the carriageway band to her; the pavements beside the row stay open.
##
## The player's words *(2026-10-10, azure-puffin: "let's add the bollards back. it will make the
## middle of the road impassable when going from street to pedestrian road. that's okay. this is
## intended")*. Her real `CharacterBody2D` rig is swept through real `Prop` posts, with the same
## synchronous `move_and_collide()` sweep `tests/test_interior.gd` uses (one displacement per step,
## not `move_and_slide()`'s own).
##
## **No city is built here, and no map is generated.** The posts stand where a generated map puts
## them, read off once (seed 1000's first row: `ROW_ALONG`, `ROW_ACROSS_FIRST` and the five posts
## `CityMap.BOLLARD_SPACING` apart), and the committed test holds only that row. Where `CityMap`
## puts the posts, and that everything that steps or floods for her sees their tiles as blocked, is
## `tests/test_precinct_posts.gd`'s.
##
## **Why her real body is here**: a post is a `Prop` with a `StaticBody2D`, and what the design
## promises (the row stops her, the pavement beside it does not) is a promise between that body and
## hers, which only the physics engine can answer, so the two are combined and a fake of either would
## answer nothing. The `Prop`'s own members a check reads (`shape`, its `BollardBody` child) have no
## method to read them through, and `src/city/prop.gd` is not this change's to add one to.

const STEP := 8.0
const RUN_UP := 120.0
## The first row of the posts seed 1000's generated map has, as `CityMap.post_positions()` gave
## them: a row along the east-west street, its posts stacked across it five apart.
const ROW_ALONG := 1488.0
const ROW_ACROSS_FIRST := 4996.0
const ROW_POSTS := 5

func run(t) -> void:
	_test_only_the_bollard_has_a_body(t)
	_test_the_post_body_is_its_drawn_ground_contact(t)
	_test_every_gap_is_narrower_than_her_body(t)
	_test_the_row_stops_her_and_the_pavement_does_not(t)
	_test_the_row_stops_her_at_a_diagonal_from_every_offset(t)
	_test_holding_a_diagonal_never_gets_her_past_the_row(t)

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
	post.free()

## The posts of the row, as cross-axis centres, and the axis they run along: a horizontal row (it runs
## along x, its posts stacked across it in y), which is what seed 1000's first row is.
func _row() -> Dictionary:
	var across: Array[float] = []
	for i in ROW_POSTS:
		across.append(ROW_ACROSS_FIRST + float(i) * CityMap.BOLLARD_SPACING)
	return {"vertical": false, "along": ROW_ALONG, "across": across}

## A gap between two posts is narrower than her body, which is the guarantee between the post's size,
## its spacing and her body that makes a row a wall: nothing is asked of a map.
func _test_every_gap_is_narrower_than_her_body(t) -> void:
	var post := _prop(t, Prop.Kind.BOLLARD)
	var post_radius: float = post.shape.radius
	post.free()
	# Her body alone, whatever way she faces, is 2 x 14 across; a gap that holds it lets her by.
	var body := 2.0 * Tuning.PLAYER_BODY_RADIUS
	var widest := CityMap.BOLLARD_SPACING - 2.0 * post_radius
	t.check(widest < body,
			"the widest gap between two posts (%.1fpx) is narrower than her body (%.1fpx)" % [widest, body])

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

func _test_the_row_stops_her_and_the_pavement_does_not(t) -> void:
	var made := _row_with_posts(t)
	var holder: Node2D = made[0]
	var row: Dictionary = made[1]
	var vertical: bool = row.vertical
	var across: Array = row.across
	across.sort()
	var heading := Vector2.DOWN if vertical else Vector2.RIGHT
	var along: float = row.along
	var run := RUN_UP * 2.0
	var band_px := float(Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH * 2) * Tuning.TILE_SIZE
	var margin := (band_px - float(across.size() - 1) * CityMap.BOLLARD_SPACING) * 0.5
	var band_start := float(across[0]) - margin
	var on_pavement := band_start - float(Tuning.TILE_SIZE)
	var on_far_pavement := band_start + band_px + float(Tuning.TILE_SIZE)
	for case in [["a post", float(across[0]), false],
			["the gap between two posts", (float(across[0]) + float(across[1])) * 0.5, false],
			["the pavement beside the row", on_pavement, true],
			["the pavement on the other side", on_far_pavement, true]]:
		var cross: float = case[1]
		var start := Vector2(cross, along - RUN_UP) if vertical else Vector2(along - RUN_UP, cross)
		var walked := _walk(t, start, heading, run)
		var passed := walked >= run
		t.check(passed == case[2],
				"walking at %s %s (%.0f of %.0fpx)"
				% [case[0], "passes the row" if passed else "stops at the row", walked, run])
	holder.free()

## The posts of the row, `holder` holding them, and the row.
func _row_with_posts(t) -> Array:
	var row := _row()
	var holder := Node2D.new()
	t.add_child(holder)
	for cross in row.across:
		var post := Prop.new()
		post.kind = Prop.Kind.BOLLARD
		post.position = Vector2(ROW_ALONG, cross)
		holder.add_child(post)
	return [holder, row]

## Her facing follows the input, not her velocity, so the pram circle can sit 45 degrees off the
## way she moves. From every offset across the band, straight at the row or at 30 or 45 degrees
## either side of it, she is stopped before the row.
func _test_the_row_stops_her_at_a_diagonal_from_every_offset(t) -> void:
	var made := _row_with_posts(t)
	var holder: Node2D = made[0]
	var row: Dictionary = made[1]
	var vertical: bool = row.vertical
	var across: Array = row.across
	across.sort()
	var heading := Vector2.DOWN if vertical else Vector2.RIGHT
	var along: float = row.along
	var first: float = across[0]
	var last: float = across[across.size() - 1]
	var run := RUN_UP * 2.0
	for degrees in [0.0, 30.0, 45.0]:
		for sign in [-1.0, 1.0]:
			var facing := heading.rotated(deg_to_rad(degrees) * sign)
			for step in 9:
				var cross := lerpf(first, last, float(step) / 8.0)
				var start := Vector2(cross, along - RUN_UP) if vertical else Vector2(along - RUN_UP, cross)
				var walked := _walk(t, start, heading, run, facing)
				t.check(walked < RUN_UP,
						"the row stops her at offset %d with her facing %.0f degrees off her way (%.0f of %.0fpx)"
						% [step, degrees * sign, walked, run])
	holder.free()

## Holding a diagonal, a slide loop like `move_and_slide()`'s from many offsets across the band:
## she gets past the row only by sliding along it and round its end onto the pavement, never
## through it. Her facing is the held diagonal.
func _test_holding_a_diagonal_never_gets_her_past_the_row(t) -> void:
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
			var through_the_row := false
			var crossed := false
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
				# Where she is across the band the frame her centre first crosses the row's line.
				if not crossed and progress > 60.0:
					crossed = true
					var lateral := player.global_position.x if vertical else player.global_position.y
					through_the_row = lateral > first and lateral < last
				if progress > 60.0 + 2.0 * Tuning.PLAYER_BODY_RADIUS + 20.0:
					past = true
					break
			t.check(past and not through_the_row,
					"holding a diagonal (%+.0f) from offset %d, she gets past the row only round its end"
					% [side, step])
			player.free()
	holder.free()
