class_name StreetLayout
extends RefCounted
## **The street lattice painted onto a map's tiles**: every corridor laid as sidewalk, road and
## sidewalk across, a crossing where a road meets the other corridor's sidewalk band, a precinct
## paved all the way across, and the junctions on the map's border kept to the arms that are
## streets. Pure tile arithmetic over the map's own street kinds and main road, so it is the same
## for a generated city and for a test's own street map (`tests/fixtures/street_map.gd`).
##
## `CityGenerator._attempt()` lays every city's streets through it, after the street kinds are
## assigned and before anything is built on the blocks between them.

## Paints `map`'s streets: every tile on a corridor the way its two offsets and kinds say, every
## tile between them `BUILDING`, then the border's stubs sealed. Reads `map.main_road` and the
## street kinds (`CityMap.street_kind_at()`), so both are set first.
static func lay(map: CityMap) -> void:
	_lay_streets(map)
	_seal_border_stubs(map)

static func _lay_streets(map: CityMap) -> void:
	# The offsets are a modulo and the kinds are a short scan of the precinct list, so both are
	# hoisted per row and per column rather than asked once per tile of a lattice this size.
	var x_offsets := PackedInt32Array()
	x_offsets.resize(map.size_in_tiles().x)
	for x in map.size_in_tiles().x:
		x_offsets[x] = CityMap.corridor_offset(x)
	for y in map.size_in_tiles().y:
		var y_offset := CityMap.corridor_offset(y)
		# The kind of each corridor *at this row*: a precinct is three blocks of a street, so a
		# vertical corridor's kind changes as the row moves down it.
		var x_kinds := PackedByteArray()
		x_kinds.resize(map.size_in_tiles().x)
		for x in map.size_in_tiles().x:
			x_kinds[x] = map.street_kind_at(true, Vector2i(x, y))
		for x in map.size_in_tiles().x:
			var x_offset := x_offsets[x]
			if x_offset < 0 and y_offset < 0:
				map.set_tile(Vector2i(x, y), GameEnums.TileType.BUILDING)
			else:
				map.set_tile(Vector2i(x, y), _street_tile(x_offset,
						x_kinds[x] as GameEnums.StreetKind, y_offset,
						map.street_kind_at(false, Vector2i(x, y))))

## Sidewalk | road | sidewalk across a corridor. Where a road crosses the *other*
## corridor's sidewalk band you get a pedestrian crossing, which is exactly where a
## crossing belongs.
##
## Two kinds change what that produces, and both changes are the kind saying what the street is
## rather than a new rule about geometry:
##
## - **A pedestrianised corridor has no carriageway anywhere on it, box included.** A precinct's own
##   band is paving all the way across, and a street crossing it gets no zebra either — the whole
##   junction box is paving, not only the crossing street's own road band, because the box is ground
##   the precinct owns and nothing there is asphalt. What a driveable street meets is the precinct's
##   edge rather than a crossing: the box reads as a T, its third arm the precinct's pavement
##   continuing past it, and the road resumes wherever the precinct's own band ends. **Which
##   corridor asked does not matter** — the pedestrian flag below is true whenever *either* side of
##   the box is a precinct, so a main road stops at one exactly as an ordinary street does.
## - **A main road's crossing is signalled rather than negotiated, and it is not a zebra** — it is
##   two dotted lines marking the pedestrian safe zone. Traffic on a main road does not give way to
##   somebody at the kerb, it obeys the light, so the crossing is a *timing* problem where an
##   ordinary one is a gap-hunting problem. A zebra there is paint promising the wrong one of those
##   at every junction of the one street where getting it wrong ends the day. See
##   `CarStrategy._give_way` and `TrafficSignals`.
##
##   **The tile type does not change and that is the point.** Painting the crossing away entirely is
##   worse — a walker crossing a side street would then be standing on open carriageway, and the one
##   thing a crossing is for is saying where a person on a road is meant to be — so what differs is
##   the picture and nothing else. Every rule that reads `CROSSING`, from the traffic's give-way scan
##   to where an event may stand, means what it means on both.
##   `GroundTiles._crossing_variant` is where the two dotted lines are drawn.
static func _street_tile(x_offset: int, x_kind: GameEnums.StreetKind,
		y_offset: int, y_kind: GameEnums.StreetKind) -> GameEnums.TileType:
	# Either corridor being a precinct removes the carriageway from the **whole** box, not only
	# from its own band — a junction belongs to both corridors at once, and a precinct is ground
	# with no asphalt on it whichever axis you ask from.
	var pedestrian := (x_offset >= 0 and x_kind == GameEnums.StreetKind.PEDESTRIAN) \
			or (y_offset >= 0 and y_kind == GameEnums.StreetKind.PEDESTRIAN)
	var x_road := x_offset >= 0 and not pedestrian and CityMap.is_road_offset(x_offset)
	var y_road := y_offset >= 0 and not pedestrian and CityMap.is_road_offset(y_offset)

	if x_offset >= 0 and y_offset >= 0:
		if x_road and y_road:
			return GameEnums.TileType.ROAD
		if x_road or y_road:
			return GameEnums.TileType.CROSSING
		return GameEnums.TileType.SIDEWALK

	return GameEnums.TileType.ROAD if (x_road or y_road) else GameEnums.TileType.SIDEWALK

## Every junction on the map's own border keeps only the arms that are actually streets. The map
## simply stops at `map.size`, so a street meeting the border has nothing beyond it the same way a
## dead end or an absorbed corridor does — `_street_tile` cannot see that, since it only ever
## looks at one tile's own two offsets, so the border comes out painted as an ordinary four-way
## with a zebra running off the edge of the world.
##
## Stated over **a side of the map**, not four rects written out by hand: the first pass to touch
## this wrote one border at a time, which is one bug per side waiting to happen. Every tile within
## `SIDEWALK_WIDTH` of any edge that came out `CROSSING` becomes pavement instead, the same repair
## `CityGenerator._seal_stub_crossings` makes over a specific rect of ground that stopped being a street.
##
## **Except the spine's own two exits.** The tunnel to the north and the bridge to the south are
## real road — a car genuinely goes on there, see `City._spawn_spine_exits` — so their crossing and
## the carriageway under it are left alone, over the main road's own `STREET_WIDTH` band at those
## two edges only. There is no third or fourth exit: an east-west spine sits on a corridor that is
## an arterial nowhere else in the game, so no such exception exists on the west or east border.
##
## Turning a `CROSSING` to `SIDEWALK` moves no walkable tile — both are walkable — so this cannot
## touch the guarantee `tests/test_blocks.gd` holds across a block's whole arc.
static func _seal_border_stubs(map: CityMap) -> void:
	var band := Tuning.SIDEWALK_WIDTH
	var spine_lo := map.main_road * CityMap.period()
	var spine_hi := spine_lo + Tuning.STREET_WIDTH
	var strips := [
		Rect2i(0, 0, map.size_in_tiles().x, band),
		Rect2i(0, map.size_in_tiles().y - band, map.size_in_tiles().x, band),
		Rect2i(0, 0, band, map.size_in_tiles().y),
		Rect2i(map.size_in_tiles().x - band, 0, band, map.size_in_tiles().y),
	]
	for i in strips.size():
		var north_or_south := i < 2
		for tile in map.rect_tiles(strips[i]):
			if north_or_south and tile.x >= spine_lo and tile.x < spine_hi:
				continue
			if map.tile_at(tile) == GameEnums.TileType.CROSSING:
				map.set_tile(tile, GameEnums.TileType.SIDEWALK)
