extends RefCounted
## Throwaway: for a small (single-block) courtyard, finds a real seamless-extended column (M216)
## and a walk script to a vantage tile inside the courtyard's own open interior
## (`BlockLayout.open_rect`, walkable `COURTYARD` ground) that looks at the inner corner where two
## of the block's own cut rectangles meet — the corner the street-facing vantage the other M216
## probes compute never shows, since the seam is on the *inside* of the block, not its street
## front. Not a suite: `tools/test.sh probes/m216_corner_evidence.gd`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const _SAFE_RUN_TILES := 6
## A few tiles in from the corner, so the shot frames both pieces of roof rather than standing
## right against the wall.
const _VANTAGE_INSET := 3

func run(t) -> void:
	var best: Dictionary = {}
	var best_tiles := 999999
	for seed_value in range(1, 300):
		var map := CityGenerator.generate(seed_value)
		for block in map.block_layouts.keys():
			if map.starting_purpose(block) != GameEnums.BlockPurpose.COURTYARD:
				continue
			if map.zone_rects.has(block):
				continue  # an apartment complex, not a small courtyard
			if block == CityGenerator.home_block():
				continue
			var layout = map.block_layouts[block]
			if not BlockLayout.has(layout.open_rect):
				continue
			var city: City = CITY_SCENE.instantiate()
			t.add_child(city)
			city.build(map)
			var lot := map.lot_rect(block)
			var found := _find_seamless_corner(city, lot, layout.open_rect)
			if not found.is_empty():
				var vantage: Vector2i = found["vantage"]
				var walk := M216Walk.walk_to(map, vantage, _SAFE_RUN_TILES)
				if not walk.is_empty() and walk["safe"] and walk["tiles"] < best_tiles:
					best_tiles = walk["tiles"]
					best = {"seed": seed_value, "block": block, "found": found, "walk": walk}
			city.free()
		if not best.is_empty() and best_tiles <= 20:
			break  # close enough to the doorstep that a real capture stays inside the rig's own budget
	if best.is_empty():
		t.check(false, "no seamless courtyard corner found reachable from the doorstep in 300 seeds")
		return
	print("\n== corner, seed %d: courtyard block %s, corner col %s, covering lot %s, covered lot %s =="
			% [best["seed"], best["block"], best["found"]["col"], best["found"]["front_lot"],
			best["found"]["back_lot"]])
	M216Walk.print_walk(best["walk"], "corner")
	t.check(true, "m216 corner-evidence probe found a seed")

## Every building cut from `block`'s own lot, looking for a covered column whose extension is
## seamless (M216) — the covering building and the covered one are two pieces of the same
## courtyard, so their meeting point is an inner corner around `open_rect`. Returns
## `{"col", "front_lot", "back_lot", "vantage"}` for the first one found, or `{}`.
func _find_seamless_corner(city: City, lot: Rect2i, open_rect: Rect2i) -> Dictionary:
	var buildings := city.buildings()
	for back: Building in buildings:
		if not lot.encloses(back.lot):
			continue
		for col in back.roof_extension_seamless.size():
			if not back.roof_extension_seamless[col]:
				continue
			var south := Vector2i(back.lot.position.x + col, back.lot.end.y)
			var front_lot := Rect2i()
			for candidate: Building in buildings:
				if candidate.lot.has_point(south):
					front_lot = candidate.lot
					break
			if front_lot == Rect2i():
				continue
			# Stand a few tiles inside the courtyard's own open interior, south of the seam --
			# open_rect is real walkable COURTYARD ground, not a spatial guess.
			var vantage := Vector2i(south.x, open_rect.position.y + _VANTAGE_INSET)
			if not open_rect.has_point(vantage):
				vantage = Vector2i(open_rect.position.x + open_rect.size.x / 2,
						open_rect.position.y + open_rect.size.y / 2)
			return {"col": col, "front_lot": front_lot, "back_lot": back.lot, "vantage": vantage}
	return {}
