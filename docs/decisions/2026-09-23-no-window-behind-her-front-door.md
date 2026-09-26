## No window behind her front door · 2026-09-23

*([PLAYTEST-124](../playtests/PLAYTEST-124.md), statement 11: "The home has windows behind the door.
Let's remove them.")* Her home block is the one front that keeps its ground-floor windows (M185),
so the building behind her door drew a window on each side of it, half hidden. Now the column or
columns the door's 26px footprint overlaps draw plain wall, and every other ground-floor window on
the block stays.

**How the building learns where the door is:** the door's world x-span, not a list of columns.
`City._door_world_x_range()` computes it once from the centre of `map.home_rect` and the door
texture's width; `_spawn_home()` places the sprite from it and `_spawn_buildings()` hands it to
every home-block building as `Building.door_world_x_range` (unset is `Vector2.INF`, so no other
building ever matches), so the sprite and the blanked cells cannot disagree. Handing columns over
was the alternative; it would have repeated the door's placement arithmetic in a second place. No
RNG stream moves, since this is geometry, not a roll. `tests/test_ground_floor.gd` pins a door
straddling a column boundary and checks, over the seed sweep, that exactly the door's columns lose
their window and the home block keeps windows elsewhere.
