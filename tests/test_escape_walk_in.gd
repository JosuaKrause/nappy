extends RefCounted
## `EscapeWalkIn`: the game walking her into the tunnel's dark or across the bridge once the section
## is won. She is a `FakeStroller` that records how she is led and carries herself on each tick she
## is asked to; the way outs' geometry is `CityEdge`'s own constants.

func run(t: TestRunner) -> void:
	await _test_she_is_led_on_until_she_is_in_and_only_then_it_arrives(t)

func _walk_in(t: TestRunner) -> EscapeWalkIn:
	var walk := EscapeWalkIn.new()
	walk.name = "WalkIn"
	t.add_child(walk)
	return walk

func _test_she_is_led_on_until_she_is_in_and_only_then_it_arrives(t: TestRunner) -> void:
	for exit_kind: int in [CityExit.Kind.TUNNEL, CityExit.Kind.BRIDGE]:
		var tunnel := exit_kind == CityExit.Kind.TUNNEL
		var name := "tunnel" if tunnel else "bridge"
		var walk := _walk_in(t)
		var her := FakeStroller.new()
		var threshold := Vector2(300.0, 16.0 if tunnel else 5000.0)
		her.global_position = threshold + Vector2(10.0, 0.0)
		var arrivals := [0]
		walk.arrived.connect(func() -> void: arrivals[0] += 1)
		walk.begin(her, exit_kind, threshold)
		# Walked from the map's edge, half a row past the threshold: the tunnel's opening's depth
		# north, the bridge deck's whole length south, as `CityEdge` draws them.
		var edge_y := threshold.y + (-1.0 if tunnel else 1.0) * Tuning.TILE_SIZE * 0.5
		var target := Vector2(threshold.x, edge_y - CityEdge.TUNNEL_DEPTH_TILES * float(Tuning.TILE_SIZE)
				if tunnel else edge_y + CityEdge.BRIDGE_DECK_PX)
		t.check(walk.is_walking() and her.is_led(), "the %s walk takes her by the hand" % name)
		for _frame in 10:
			await t.get_tree().physics_frame
		t.check(arrivals[0] == 0 and her.is_led(), "ten ticks in, the %s walk is still going" % name)
		var speed := Tuning.WALK_SPEED if tunnel else Tuning.RUN_SPEED
		t.check(is_equal_approx(her.led_speed(), speed),
				"and she is led at %s (%s)" % ["a walk" if tunnel else "a run", her.led_speed()])
		var frames := 0
		while arrivals[0] == 0 and frames < 3000:
			await t.get_tree().physics_frame
			frames += 1
		t.check(arrivals[0] == 1, "the %s walk arrives, once (%d)" % [name, arrivals[0]])
		var step := speed / float(Engine.physics_ticks_per_second)
		t.check(absf(her.global_position.y - target.y) <= step * 2.0,
				"and only when she is %s (%s, wanted %s)"
				% ["inside" if tunnel else "across", her.global_position, target])
		t.check(not her.is_led() and her.releases() == 1 and not walk.is_walking(),
				"she is handed back at the end")
		for _frame in 5:
			await t.get_tree().physics_frame
		t.check(arrivals[0] == 1, "and a finished walk says nothing more")
		her.free()
		walk.free()
