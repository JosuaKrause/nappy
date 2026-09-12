class_name DevRig
extends RefCounted
## Everything that acts on a developer flag by reading the live city — see docs/TODO.md, M100,
## "Small, real, and nobody's": "`DevFlags` took the flag parsing out; what stayed is the code
## that acts on it". `DevFlags` still does every flag's own parsing; this is where the half of
## that surface which needs the live `City`, `ResistanceDirector` or `Baby` — rather than just
## the raw argv — turns a flag's value into camera positions, meters and a compressed clock.
##
## A `RefCounted`, not a `Node`. The only state that has to survive between calls is the follow
## camera and the event id it tracks, and neither needs this object to have a place of its own in
## the tree: the camera is a real `Camera2D`, parented on whichever node the caller passes in (`main`
## for an ordinary run, a test's own rig node for a suite), and this object just keeps the
## reference. Every other method is `static`, since it has nothing to remember between calls and
## nothing to gain from an instance — a lookup against a `City` built on a fixed seed answers the
## same way whoever asks it, which is what makes it headless-testable without booting `main`.

## The follow camera, once `setup_follow_camera()` has built one — `null` until `--follow` asks
## for one, and for the rest of a run that never does.
var _follow_camera: Camera2D
## The event id `--follow` named, so `update_follow_camera()` knows which live instance to chase
## without re-reading the command line every frame.
var _follow_id := ""

## `--follow <event id>` parks a camera on an event wherever it is. Needed for anything that does
## not exist when the day starts — a mobile event mid-route, or the fire a fire engine leaves
## behind when it stops. `parent` is whatever node the camera should live under — `main` for an
## ordinary run.
func setup_follow_camera(parent: Node) -> void:
	_follow_id = DevFlags.follow_target()
	if _follow_id == "":
		return
	_follow_camera = Camera2D.new()
	parent.add_child(_follow_camera)
	_follow_camera.make_current()

## Called once a frame; a no-op until `setup_follow_camera()` has actually built a camera.
func update_follow_camera(city: City) -> void:
	if not _follow_camera:
		return
	for instance in city.events.instances():
		if instance.def.id == _follow_id:
			_follow_camera.position = instance.global_position
			return

## `--day-length N` compresses the day, so dusk and the timeout loss can be looked at without
## sitting through the whole three minutes.
static func day_length(day: int) -> float:
	var override := DevFlags.day_length_override()
	return override if override > 0.0 else Tuning.day_length(day)

## `--spawn park|alley|square|arterial|closure|event` drops the player onto a tile type or next
## to something live, so the WorldContext answers can be checked without walking across the city
## to find one.
static func spawn_position(city: City, resistance: ResistanceDirector) -> Vector2:
	return for_spawn_target(DevFlags.spawn_target(), city, resistance)

## The lookup half of `spawn_position()`, split out so a test can drive every named target
## directly against a real `City` without a command line to read `--spawn` off — the same reason
## `first_event_position()` below already takes its id as a plain argument rather than asking
## `DevFlags` a second time.
static func for_spawn_target(target: String, city: City, resistance: ResistanceDirector) -> Vector2:
	if target == "":
		return city.map.doorstep_world_position()

	# `event` takes the first non-ambient event; `event:<id>` targets a specific one.
	if target.begins_with("event"):
		return first_event_position(city, target.get_slice(":", 1))
	# The busiest pavement in the city, for looking at the crowd's noise floor without
	# walking there. The arterial is where the floor is highest, so it is where the
	# question "can a day be won on an ordinary street" is actually answered.
	if target == "arterial":
		return nearest_walkable(city.map, CrowdLanes.arterial_pavement(city.map))
	# A closed street, from the junction outside its barrier — the place the closure is
	# supposed to be readable from, which is the thing worth looking at.
	# `closure:<n>` picks one of the day's closures, since only one of them is a street
	# running the way you wanted to look at.
	if target.begins_with("closure"):
		var closures := city.closures()
		if closures.is_empty():
			push_warning("no streets are closed on day %d" % GameState.day)
			return city.map.home_world_position()
		var which := clampi(int(target.get_slice(":", 1)), 0, closures.size() - 1)
		var mouth: Vector2 = closures[which].mouth_centres(city.map)[0]
		var junction := closures[which].cause_centre(city.map)
		return nearest_walkable(city.map, mouth + (mouth - junction).normalized() * 64.0)
	# The north-west corner of a multi-block calm zone, a couple of tiles outside it, which puts
	# both of the things a zone has to get right in one frame: the T-junction where the absorbed
	# street stops, and the calm behind it.
	#
	# `zone:<n>` picks which one, the way `closure:<n>` does, and it is not a convenience. A zone
	# has a **shape** and the square is always placed first, so `keys()[0]` is always the square
	# and no other shape can be looked at without the index.
	if target.begins_with("zone"):
		if city.map.zone_rects.is_empty():
			push_warning("this city has no multi-block calm zone")
			return city.map.home_world_position()
		var keys := city.map.zone_rects.keys()
		var which := clampi(int(target.get_slice(":", 1)), 0, keys.size() - 1)
		var anchor: Vector2i = keys[which]
		var corner := CityMap.blocks_tile_rect(city.map.zone_rects[anchor]).position
		return nearest_walkable(city.map, city.map.tile_to_world(corner - Vector2i.ONE * 2))
	# A big building, stood on the street running along the joined side of it, level with the
	# street it was built over. The whole claim of a landmark is that it reads as **one mass**
	# rather than as two blocks with the road missing between them, and this flag is the only way
	# to point a camera at one.
	if target == "landmark":
		if city.map.big_buildings.is_empty():
			push_warning("this city has no big building")
			return city.map.home_world_position()
		var pair: Rect2i = city.map.big_buildings[0]
		var mass := CityMap.blocks_tile_rect(pair)
		# Off the **long** side, which is the one the joined seam runs the width of: a mass two
		# blocks wide is looked at from the north, a mass two blocks deep from the west. Two tiles
		# out and not three, because a corridor is `sidewalk | road | sidewalk` and three tiles off
		# a frontage is the carriageway — `nearest_walkable` will happily leave her standing on it,
		# and a shot taken from there is a shot of the day ending.
		# And a little off the middle of that side, because the middle of the mass is where the
		# built-over street was, so the tile facing it across the corridor is a junction — which is
		# somewhere a camera may stand and a pram should not.
		var beside := Vector2i(mass.get_center().x - Tuning.STREET_WIDTH, mass.position.y - 2) \
				if pair.size.x == 2 \
				else Vector2i(mass.position.x - 2, mass.get_center().y - Tuning.STREET_WIDTH)
		return nearest_walkable(city.map, city.map.tile_to_world(beside))
	# A signalled junction on the spine, stood a little back down the side street, so that the
	# main road, its lights and one of its zebras are all in the same frame. The lights
	# are the only cue in the game whose whole content is *when*, so they cannot be judged from a
	# still of one — take several seconds apart, or use `--walk` and watch the cycle.
	if target == "signal":
		var spine := city.map.main_road
		var down := clampi(Tuning.CITY_BLOCKS.y / 2, 1, Tuning.CITY_BLOCKS.y - 1)
		# On the side street's own pavement, a couple of tiles east of the junction: the block
		# east of corridor `spine` is block `spine`, and offset 1 of a corridor is footway.
		var corner := Vector2i(CityMap.block_rect(Vector2i(spine, 0)).position.x + 2,
				down * CityMap.period() + 1)
		return nearest_walkable(city.map, city.map.tile_to_world(corner))
	# The mouth of the tunnel the main road leaves by, from a few tiles down the spine. `edge:s`
	# is the bridge at the other end and `edge:e` / `edge:w` the road simply running out.
	if target.begins_with("edge"):
		var side := target.get_slice(":", 1)
		var spine_x := city.map.main_road * CityMap.period() + Tuning.STREET_WIDTH / 2
		var spine_y := CrowdLanes.arterial_index(Tuning.CITY_BLOCKS.y) * CityMap.period() \
				+ Tuning.STREET_WIDTH / 2
		# Beside the carriageway, not on it: the exits are lethal, which is the point of them.
		var at := Vector2i(spine_x - 2, 1)
		match side:
			"s": at = Vector2i(spine_x - 2, city.map.size.y - 2)
			"e": at = Vector2i(city.map.size.x - 2, spine_y - 2)
			"w": at = Vector2i(1, spine_y - 2)
		return nearest_walkable(city.map, city.map.tile_to_world(at))
	# The middle of a pedestrianised street, which is the other end of the same trade: paving
	# frontage to frontage, no kerb, no asphalt and nothing on it that can kill you.
	if target == "precinct":
		if city.map.precinct_spans.is_empty():
			push_warning("this city has no precinct")
			return city.map.home_world_position()
		var span: Vector4i = city.map.precinct_spans[0]
		var across := span.y * CityMap.period() + Tuning.STREET_WIDTH / 2
		var along := (span.z + span.w) / 2 * CityMap.period() + Tuning.STREET_WIDTH
		return nearest_walkable(city.map, city.map.tile_to_world(
				Vector2i(across, along) if span.x == 1 else Vector2i(along, across)))
	# A corner of the map, stood a couple of tiles inside it, so that two of the border's four
	# bands and the join between them are in the same frame — the seam is where the mountain and
	# the sea have to go on being themselves rather than turning diagonal. `corner:nw` is the
	# default and `ne`, `sw`, `se` are the other three.
	#
	# It exists for the same reason `landmark` does: it is the only way to point a camera at the
	# place where two bands meet, and nothing in the suite looks there.
	if target.begins_with("corner"):
		var which := target.get_slice(":", 1)
		# The outermost pavement and not the outermost tile: the corridor is `sidewalk | road |
		# sidewalk`, so anything past `SIDEWALK_WIDTH` is the carriageway of the boundary street
		# and `nearest_walkable` will happily leave her standing on it — a shot taken from there
		# is a shot of the day ending, which is the trap the `landmark` target has too.
		var near := Tuning.SIDEWALK_WIDTH - 1
		var far := city.map.size - Vector2i.ONE * Tuning.SIDEWALK_WIDTH
		var at := Vector2i(near, near)
		match which:
			"ne": at = Vector2i(far.x, near)
			"sw": at = Vector2i(near, far.y)
			"se": at = far
		return nearest_walkable(city.map, city.map.tile_to_world(at))
	if target == "contact":
		# A pickup's mark may not stay where this puts the camera: if she then walks away from
		# it without it ever being seen, the re-placement rule in `ResistanceDirector` moves it
		# to the next alley she comes near. Reading `contact_position()` again after the spawn
		# answers wherever it currently is, not wherever this call found it.
		var contact := resistance.contact_position()
		if contact == Vector2.INF:
			push_warning("no resistance contact on day %d" % GameState.day)
			return city.map.home_world_position()
		# Off to one side, so the chalk mark is not hidden under the pram.
		return contact + Vector2(70.0, 30.0)

	var wanted: int = {
		"park": GameEnums.TileType.PARK,
		"alley": GameEnums.TileType.ALLEY,
		"square": GameEnums.TileType.SQUARE,
		"playground": GameEnums.TileType.PLAYGROUND,
	}.get(target, -1)
	if wanted == -1:
		push_warning("unknown --spawn target '%s'" % target)
		return city.map.home_world_position()

	for y in city.map.size.y:
		for x in city.map.size.x:
			if city.map.tile_at(Vector2i(x, y)) == wanted:
				return city.map.tile_to_world(Vector2i(x, y))
	push_warning("no %s tile in this city" % target)
	return city.map.home_world_position()

## Just outside a planned event, on the nearest walkable tile — an offset straight down its
## radius lands inside a block as often as not.
##
## Reads the day's *plan* rather than what is live: nothing is live until the player is near it,
## so the whole point of this flag is to go and stand where one is going to be.
static func first_event_position(city: City, wanted_id: String = "") -> Vector2:
	for plan in city.events.plans():
		if not plan.is_placed():
			continue
		if wanted_id != "" and wanted_id != "event":
			if plan.def.id != wanted_id:
				continue
		elif plan.def.kind == GameEnums.EventKind.AMBIENT:
			continue
		var offset := pavement_offset(city.map, plan.position, plan.def.outer_radius)
		return nearest_walkable(city.map, plan.position + offset)
	push_warning("no non-ambient events planned today")
	return city.map.home_world_position()

## The step from a found event's position to somewhere just off it, **across the street it stands
## on** rather than along local Y unconditionally. A fixed `Vector2(0.0, radius * 0.6)` is a step
## along the street's own length on a north-south street — which never leaves the carriageway a
## north-south corridor's width is measured across (`CityMap.corridor_offset(tile.x)`) — and only
## happens to clear the road on an east-west one, whose width runs the other way. `_spread_is_vertical`
## is the one place that already answers which axis a street's *width* is on — it is the same
## question `EventInstance._spread_at()` asks to lay an obstruction across the carriageway it blocks
## — so reusing it here is the same answer applied to the opposite side of the same obstruction,
## rather than a second guess about the street's orientation.
static func pavement_offset(map: CityMap, at: Vector2, radius: float) -> Vector2:
	var vertical := EventInstance._spread_is_vertical(map, at)
	return Vector2(0.0, radius * 0.6) if vertical else Vector2(radius * 0.6, 0.0)

static func nearest_walkable(map: CityMap, near: Vector2) -> Vector2:
	var start := map.world_to_tile(near)
	for radius in 12:
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var tile := start + Vector2i(dx, dy)
				if map.is_walkable(tile):
					return map.tile_to_world(tile)
	return map.home_world_position()

## `--overview` frames the whole city at once, so a generation bug that only shows up at map
## scale (a walled-off quarter, parks bunched together) is visible. `parent` is whatever node the
## camera should live under, and `viewport_size` is `get_viewport_rect().size` — passed in rather
## than read here so this stays callable from a rig with no viewport of its own.
static func make_overview_camera(parent: Node, city: City, viewport_size: Vector2) -> void:
	var camera := Camera2D.new()
	# The frontages outside the map are in frame too: the ring is what makes the boundary a
	# street with two sides, and an overview that framed the walkable tiles alone would be a
	# picture of a grid stopping at a wall rather than of a city.
	var bounds := city.camera_bounds()
	camera.position = bounds.get_center()
	camera.zoom = Vector2.ONE * minf(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y)
	parent.add_child(camera)
	camera.make_current()

## `--meters <sleepiness> <excitement>` seeds the bars, so a UI state can be screenshotted
## without having to play all the way to it. Applied before the HUD is created, which reads the
## starting values.
static func apply_meter_override(baby: Baby) -> void:
	if not baby:
		return
	var override := DevFlags.meters_override()
	if override.x < 0.0:
		return
	baby.sleepiness = override.x
	baby.excitement = override.y
	# A full meter means "show me the walk home". Left to settle on its own it never would:
	# a stationary player drains sleepiness faster than the state check can fire.
	if baby.sleepiness >= Tuning.METER_MAX:
		baby.force_sleep()
