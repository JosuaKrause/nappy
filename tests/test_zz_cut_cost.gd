extends RefCounted

func run(t) -> void:
	var map := CityGenerator.generate(4242)
	var def := EventCatalogue.by_id("busker")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	instance._map = map
	for kind in [GameEnums.TileType.SIDEWALK, GameEnums.TileType.ROAD]:
		var ground := map.tiles_of_type(kind)
		for level in [30.0, 104.0, 190.0]:
			var rng := RandomNumberGenerator.new()
			rng.seed = 1
			var elapsed := 0
			var calls := 0
			var cut := 0
			var counted := func(p: Vector2) -> bool:
				calls += 1
				return instance.walled_off_to(p)
			for i in 300:
				var tile: Vector2i = ground[rng.randi_range(0, ground.size() - 1)]
				instance.position = map.tile_to_world(tile)
				var outline := GroundShape.field_outline_at(instance.position, Vector2.ZERO, level)
				var started := Time.get_ticks_usec()
				var runs := DebugLayers.open_runs(outline, counted)
				elapsed += Time.get_ticks_usec() - started
				if runs.size() != 1 or runs[0].size() != outline.size() + 1:
					cut += 1
			print("CUTCOST %s r=%.0f: %.1f us per outline, %.1f calls, %d/300 cut"
					% [kind, level, float(elapsed) / 300.0, float(calls) / 300.0, cut])
	instance.free()
