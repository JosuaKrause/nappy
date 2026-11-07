extends WorldMap
## Open ground that answers, for every tile, that it lies on an east-west street and on no
## north-south one: what an event set up on it reads off the street it stands on, as it does in a
## city (`EventInstance._spread_is_vertical()`, `EventFootprints.stands_side_on()`), so a spread or a
## wide scene runs down the screen. Everything else is open ground's. `tests/test_halo_behind.gd`
## and `tests/test_draw_layers.gd` hand it to `EventInstance.setup()`.

## Overrides WorldMap.corridor_offsets.
func corridor_offsets(_tile: Vector2i) -> Vector2i:
	return Vector2i(-1, 0)
