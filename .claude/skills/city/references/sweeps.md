# A sweep over the tile grid

Read this before writing a flood fill, a reach field or any loop that asks a question of every
tile.

## A per-tile predicate in a sweep is a lookup table

A `Tile.is_walkable()` call per tile becomes a `PackedByteArray` indexed by tile type
(`CityMap._lut`), built *from* `Tile.is_walkable`, which decides every tile type. It is not the whole answer: the
precinct bollards are posts standing on otherwise walkable tiles (`CityMap.post_tiles()`), so a sweep
over `_WALKABLE` that a body or a flood must obey also blocks those tiles, as `walk_field_from()`
does, or it walks straight through every row; a sweep that a figure walks lays the day's record
over it too (`CityMap.ground_for()`, the closures, the soft seals and the bodies its `Mover` names).
Only `wall_between()`'s sight walk (`_open()`) leaves the posts open, on purpose; `clear_line()`, the
pursuers' notice and lunge line, asks `passable()` for the mover it is handed and is blocked by a
post. The rest of flood-fill performance
(a `Vector2i`-keyed `Dictionary` against a flat array) is the **godot** skill's `references/rare-traps.md`, "Performance".
