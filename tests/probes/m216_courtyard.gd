extends RefCounted
## Throwaway: prints, for a small (single-block) courtyard on several seeds, the rects the block
## was cut into and each resulting Building's own wall_tiles()/roof_tiles()/covered_ground_cols/
## roof_extension_rows, so the M216 fix can be checked against real generated data rather than a
## hand-drawn fixture. Not a suite: `tools/test.sh probes/m216_courtyard.gd`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")

func run(t) -> void:
	for seed_value in [15]:
		var map := CityGenerator.generate(seed_value)
		var found := false
		for block in map.block_layouts.keys():
			if map.starting_purpose(block) != GameEnums.BlockPurpose.COURTYARD:
				continue
			if map.zone_rects.has(block):
				continue  # an apartment complex, not a small courtyard
			if block != Vector2i(5, 8):
				continue
			found = true
			print("\n== seed %d, courtyard block %s ==" % [seed_value, block])
			var lot := map.lot_rect(block)
			print("lot: %s" % lot)
			var layout = map.block_layouts[block]
			print("open_rect: %s  passage: %s" % [layout.open_rect, layout.passage])
			var city: City = CITY_SCENE.instantiate()
			t.add_child(city)
			city.build(map)
			var buildings := city.buildings()
			for building: Building in buildings:
				if not lot.encloses(building.lot):
					continue
				print("  rect=%s cols=%d wall=%d roof=%d variant=%d covered=%s ext=%s"
						% [building.lot, building.columns(), building.wall_tiles(),
						building.roof_tiles(), building.variant, building.covered_ground_cols,
						building.roof_extension_rows])
			city.free()
			break
		if found:
			break
	t.check(true, "m216 courtyard probe ran")
