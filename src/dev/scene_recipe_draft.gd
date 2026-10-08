class_name SceneRecipeDraft
extends RefCounted
## **The first draft of a task scene's stretch**: a recipe's seed and route turned into a recipe
## that lists every placed thing explicitly. *(polite-dolphin, inbox #555: "the whole point of those
## scenes is that they are not seeded but handcrafted -- you can use a seed to create it. but then
## everything should be placed manually".)* `tools/scene-draft.sh` runs it: the recipe is played
## once on its whole construction witness, with its own walk, and what she walked is cut out of the
## city — the tiles, the buildings fronting them, the street trees, props, litter and cracks on
## them, the day's posters on those walls, a starting crowd and the day's route bag — and written as
## a `stretch` recipe the author then edits. Drafting a stretch recipe again writes all of that
## afresh but its route bag, which is the author's rigging rather than a fact about where the
## stretch runs.
##
## The saved context holds the off-camera topology the daily rules need. Loading a stretch
## restores it directly and overlays the authored visible placements; no generation runs and no
## tile, lot or tree is compared with a generated witness.
##
## **The stretch is the streets she walks** *(asked how wide "the path" is, the player chose "The
## streets she walks": every tile of the street segments along her route from start to mark to
## target, both sidewalks and the carriageway, crossings and corners; everything else void)*: every
## street segment she sets foot on, whole and both sidewalks wide, with the junction box at each of
## its ends; a junction box she crosses; and, off the streets — an alley, a park, a square — the
## ground she walks over and the tiles beside it, with the whole of an alley she walks into.
##
## **Only her walk decides it.** The task's target is placed while she walks, by the director's own
## rule, on the streets the scene has — which need not be where the whole city would put it — so
## the draft is walked on the whole city, the scene is played on the stretch, and the author makes
## the walk reach the target the scene puts out (`docs/SCENE_RECIPES.md`, "The task scenes"). A
## draft therefore plays its walk to the end whatever the recipe's observations say. Three more
## things are the scene's whatever the stretch, and their ground is added too: the places
## `setup.task` pins (the mark she reads from beside it, day 10's neighbor's start); whatever stands
## in the world as the scene starts, which the day plans over the whole city at dawn, with the whole
## of an alley it stands in (the guard waiting up the mark's alley), so that nothing the scene is
## about stands in the void; the way day 10's neighbor
## walks home, which the recipe pins and the whole city routes, the same in the scene as in the
## draft; and every tile `draft.include` names, which is how the author — and the tool, for a guard
## the scene put to wait on ground the stretch cut off (the manifest's `in_the_void`) — asks for a
## street.

## Where she was, tile by tile, over the run.
var _walked := {}
## The tiles as the day began, before anything the walk set off repainted them — day 12's park
## closing behind the swing — since the stretch lists the ground the scene starts on.
var _dawn_tiles := PackedByteArray()
var _context := {}

## A recipe as the draft plays it: the whole witness, with nothing the draft writes. Its stretch,
## starting population, posters and route bag are what the draft is about to write again.
static func base_of(recipe: Dictionary) -> Dictionary:
	var base := recipe.duplicate(true)
	base.erase("stretch")
	base.erase("context")
	base["extent"] = {"scope": "full"}
	var setup: Dictionary = base.get("setup", {})
	for drafted in ["actors", "posters", "route_bag"]:
		setup.erase(drafted)
	return base

## What stood in the world as the scene started, by tile.
var _at_the_start := {}

## One tick of the walk: her tile, and the tile of a neighbor walking home (`neighbor`, or null).
## The first tick also takes the dawn's tiles and what stands in the world.
func record(player: Node2D, city: City, neighbor: Node2D) -> void:
	if _dawn_tiles.is_empty():
		_dawn_tiles = city.map.tiles.duplicate()
		_context = RecipeCityContext.capture(city.map)
		for instance in city.events.instances():
			_at_the_start[city.map.world_to_tile(instance.global_position)] = true
	_walked[city.map.world_to_tile(player.global_position)] = true
	if neighbor:
		_walked[city.map.world_to_tile(neighbor.global_position)] = true

## The drafted recipe, built from `recipe` (the file as written, not `base_of()`'s copy) and the
## world the run has left behind, `pinned` the places `setup.task` names. Fills `problems` with
## anything the draft could not place.
func compose(recipe: Dictionary, city: City, start: Vector2, pinned: Array[Vector2],
		problems: Array[String]) -> Dictionary:
	var map := city.map
	var day := GameState.day
	var ground := {}
	for tile: Vector2i in _walked:
		_add_the_ground_of(map, tile, ground)
	for at in pinned:
		_add_the_ground_of(map, map.world_to_tile(at), ground, false)
	for tile: Vector2i in _at_the_start:
		_add_the_ground_of(map, tile, ground)
	for tile: Array in recipe.get("draft", {}).get("include", []):
		_add_the_ground_of(map, Vector2i(int(tile[0]), int(tile[1])), ground, false)
	var stretch := {"tiles": _tile_runs(map, ground, _dawn_tiles)}
	var buildings: Array = []
	for building in city.buildings():
		if _fronts(map, building.lot, ground):
			buildings.append({"lot": [building.lot.position.x, building.lot.position.y,
					building.lot.size.x, building.lot.size.y],
					"district": str(GameEnums.BlockPurpose.keys()[building.district]).to_lower(),
					"variant": building.variant,
					"height": roundi(building.height / Tuning.TILE_SIZE),
					"condition": str(Building.Condition.keys()[building.condition]).to_lower()})
	buildings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return Vector2i(a.lot[1], a.lot[0]) < Vector2i(b.lot[1], b.lot[0]))
	stretch["buildings"] = buildings
	var trees: Array = []
	for planted in StreetTrees.planted(map):
		if ground.has(planted.tile):
			trees.append([planted.tile.x, planted.tile.y])
	trees.sort()
	stretch["trees"] = trees
	var props: Array = []
	for node in city.props():
		var prop := node as Prop
		if not prop or prop.kind == Prop.Kind.STREET_TREE \
				or not ground.has(map.world_to_tile(prop.position)):
			continue
		props.append({"kind": str(Prop.Kind.keys()[prop.kind]).to_lower(),
				"at": [snappedf(prop.position.x, 0.01), snappedf(prop.position.y, 0.01)],
				"variant": prop.variant, "scale": snappedf(prop.scale_factor, 0.0001)})
	stretch["props"] = props
	var litter: Array = []
	for placed in Litter.placed(map, day):
		if ground.has(map.world_to_tile(placed.position)):
			litter.append({"kind": SceneRecipe.litter_names()[placed.texture_index],
					"at": [snappedf(placed.position.x, 0.01), snappedf(placed.position.y, 0.01)]})
	stretch["litter"] = litter
	var cracks: Array = []
	for tile: Vector2i in _sorted(ground):
		var crack := GroundTiles.crack_at(map, tile, day)
		if crack.x >= 0:
			cracks.append([tile.x, tile.y, crack.x, crack.y])
	stretch["cracks"] = cracks
	var drafted := recipe.duplicate(true)
	drafted["extent"] = {"scope": "stretch"}
	drafted["stretch"] = stretch
	drafted["context"] = _context
	var setup: Dictionary = drafted.get("setup", {})
	setup["posters"] = _posters(map, ground)
	setup["actors"] = _starting_crowd(city, ground, start, problems)
	# A route bag the author has already rigged is theirs: it is about what she meets, not about
	# where the stretch runs, so drafting the stretch again keeps it.
	if not setup.has("route_bag"):
		var marbles := EventDirector.ordinary_route_marbles(day, GameState.resistance_progress)
		setup["route_bag"] = {"marbles": marbles, "owed": marbles.size()}
	var background: Dictionary = setup.get("background", {})
	background.erase("crowd")
	if background.is_empty():
		setup.erase("background")
	drafted["setup"] = setup
	return drafted

## Adds the ground `tile` stands on to `ground`, by the rule in the class doc. `walked` is false for
## a place the task pins, which adds its street but not the whole of an alley it stands at the mouth
## of: she reads a mark from beside it, and never walks up the alley behind.
static func _add_the_ground_of(map: CityMap, tile: Vector2i, ground: Dictionary,
		walked := true) -> void:
	var on_x := CityMap.corridor_offset(tile.x) >= 0
	var on_y := CityMap.corridor_offset(tile.y) >= 0
	if on_x and on_y:
		_add_walkable(map, _junction_box(CityMap.junction_at(tile)), ground)
		return
	var segment := StreetNetwork.segment_containing(tile)
	if segment and map.has_street(segment.key()):
		_add_walkable(map, segment.tile_rect(), ground)
		_add_walkable(map, _junction_box(segment.a), ground)
		_add_walkable(map, _junction_box(segment.b), ground)
		return
	_add_walkable(map, Rect2i(tile - Vector2i.ONE, Vector2i(3, 3)), ground)
	for alley in map.alley_rects:
		if walked and alley.has_point(tile):
			_add_walkable(map, alley, ground)

static func _junction_box(junction: Vector2i) -> Rect2i:
	return Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)

static func _add_walkable(map: CityMap, rect: Rect2i, ground: Dictionary) -> void:
	for tile in map.rect_tiles(rect):
		if map.in_bounds(tile) and map.is_walkable(tile):
			ground[tile] = true

## `ground` as the recipe lists it: tile type name -> `[y, x_from, x_to]` runs, row by row.
static func _tile_runs(map: CityMap, ground: Dictionary, dawn: PackedByteArray) -> Dictionary:
	var runs := {}
	for tile: Vector2i in _sorted(ground):
		var type := str(GameEnums.TileType.keys()[dawn[tile.y * map.size.x + tile.x]]).to_lower()
		if not runs.has(type):
			runs[type] = []
		var list: Array = runs[type]
		var last: Array = list.back() if not list.is_empty() else []
		if not last.is_empty() and int(last[0]) == tile.y and int(last[2]) == tile.x - 1:
			last[2] = tile.x
		else:
			list.append([tile.y, tile.x, tile.x])
	return runs

## Tiles in reading order, row by row.
static func _sorted(tiles: Dictionary) -> Array[Vector2i]:
	var sorted: Array[Vector2i] = []
	for tile: Vector2i in tiles:
		sorted.append(tile)
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y < b.y or (a.y == b.y and a.x < b.x))
	return sorted

static func _fronts(map: CityMap, lot: Rect2i, ground: Dictionary) -> bool:
	for tile in map.rect_tiles(lot.grow(1)):
		if ground.has(tile):
			return true
	return false

## The day's posters on the walls fronting the stretch: every sheet pasted at a front tile the
## stretch holds, as `setup.posters` names it.
static func _posters(map: CityMap, ground: Dictionary) -> Array:
	var posters: Array = []
	var cells: Dictionary = GameState.posters.cells
	for tile: Vector2i in _sorted(ground):
		if not cells.has(tile):
			continue
		var at := map.tile_to_world(tile)
		posters.append({"at": [at.x, at.y],
				"kind": str(PosterArt.Kind.keys()[int(cells[tile]["kind"])]).to_lower()})
	return posters

## A morning's crowd round the stretch, the day's own numbers placed the day's own way, and of them
## the walkers and cars standing on it — each then placed again as the scene places it, on the
## stretch alone, so one the scene would refuse (a lane that is void on one side, a car in another's
## queue) is left out rather than written. **No car starts in her view**
## (`Tuning.VIEW_HALF_EXTENT` round `start`): a scene's first frame is not a car already bearing
## down on a pram that has not taken a step — the start of a played day is her doorstep, on a street
## no car is in yet.
static func _starting_crowd(city: City, ground: Dictionary, start: Vector2,
		problems: Array[String]) -> Array:
	var map := city.map
	var day := GameState.day
	var box := Rect2i()
	for tile: Vector2i in ground:
		box = Rect2i(tile, Vector2i.ONE) if not box.has_area() else box.expand(tile).expand(tile + Vector2i.ONE)
	var centre := map.tile_rect_to_world(box).get_center()
	city.crowd.start_day(day, GameState.day_rng(day, "crowd"), centre, true)
	var found: Array[Dictionary] = []
	for agent in city.crowd.agents():
		if not ground.has(map.world_to_tile(agent.position)):
			continue
		var vertical: bool = agent.get("_vertical")
		var direction: float = agent.get("_direction")
		# The along coordinate rounded to a hundredth of a pixel, for a recipe a person reads; the
		# cross coordinate is the lane's centre and stays exact, since a placement must stand on it.
		var at := agent.position
		if vertical:
			at.y = snappedf(at.y, 0.01)
		else:
			at.x = snappedf(at.x, 0.01)
		var heading := "south" if vertical and direction > 0.0 else ("north" if vertical
				else ("east" if direction > 0.0 else "west"))
		found.append({"kind": "car" if agent.kind == CrowdAgent.Kind.CAR else "walker",
				"at": at, "direction": heading, "speed": snappedf(float(agent.get("_speed")), 0.0001)})
	city.crowd.clear()
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return a.kind < b.kind or (a.kind == b.kind and (a.at.y < b.at.y
			or (a.at.y == b.at.y and a.at.x < b.at.x))))
	# Placed again on the stretch, the way the scene will place them.
	var mask := PackedByteArray()
	mask.resize(map.size.x * map.size.y)
	for tile: Vector2i in ground:
		mask[tile.y * map.size.x + tile.x] = 1
	map.stretch = mask
	map.stretch_active = true
	var counts := {"walker": 0, "car": 0}
	var actors: Array = []
	var view := Rect2(start - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
	for entry in found:
		var label := "%s_%d" % [entry.kind, int(counts[entry.kind]) + 1]
		var at: Vector2 = entry.at
		if entry.kind == "car" and view.has_point(at):
			problems.append("left out a car at %s: it would start in her view" % at)
			continue
		var placed := city.crowd.add_recipe_actor(label,
				CrowdAgent.Kind.CAR if entry.kind == "car" else CrowdAgent.Kind.WALKER, at,
				SceneRecipeRuntime.DIRECTIONS[entry.direction], float(entry.speed),
				hash("actor:%s" % label))
		if not str(placed.error).is_empty():
			problems.append("left out a %s at %s: %s" % [entry.kind, at, placed.error])
			continue
		counts[entry.kind] = int(counts[entry.kind]) + 1
		actors.append({"name": label, "kind": entry.kind,
				"at": [snappedf(at.x, 0.01), snappedf(at.y, 0.01)],
				"direction": entry.direction, "speed": snappedf(float(entry.speed), 0.0001)})
	map.stretch_active = false
	map.stretch = PackedByteArray()
	return actors

# ------------------------------------------------------------------ writing ---

## The recipe as JSON laid out the way the checked-in recipes are read: an object's fields one to a
## line, a list of small things on one line, and a list of objects or lists one entry to a line.
static func to_json(value: Variant, indent := "") -> String:
	if value is Dictionary:
		var dictionary: Dictionary = value
		if dictionary.is_empty():
			return "{}"
		if _is_small(dictionary):
			return JSON.stringify(_whole(dictionary), "", false)
		var lines: Array[String] = []
		for key: Variant in dictionary:
			lines.append("%s  %s: %s" % [indent, JSON.stringify(str(key)),
					to_json(dictionary[key], indent + "  ")])
		return "{\n%s\n%s}" % [",\n".join(lines), indent]
	if value is Array:
		var array: Array = value
		if array.is_empty():
			return "[]"
		if _is_small(array):
			return JSON.stringify(_whole(array), "", false)
		var lines: Array[String] = []
		for item: Variant in array:
			lines.append("%s  %s" % [indent, to_json(item, indent + "  ")])
		return "[\n%s\n%s]" % [",\n".join(lines), indent]
	return JSON.stringify(_whole(value), "", false)

## A number JSON read back as a float is written as the integer it is, the way the checked-in
## recipes write a seed, a day or a tile.
static func _whole(value: Variant) -> Variant:
	if value is float and is_finite(value) and value == floorf(value) and absf(value) < 1e15:
		return int(value)
	if value is Array:
		return (value as Array).map(_whole)
	if value is Dictionary:
		var copy := {}
		for key: Variant in value:
			copy[key] = _whole(value[key])
		return copy
	return value

## Whether a value reads best on one line: a list of scalars however long, or a short list or
## small object of scalars and pairs.
static func _is_small(value: Variant) -> bool:
	var items: Array = value.values() if value is Dictionary else value
	if value is Array and items.all(func(item: Variant) -> bool:
			return not (item is Array or item is Dictionary)):
		return true
	for item: Variant in items:
		if item is Dictionary:
			return false
		if item is Array and (item.size() > 4 or not (item as Array).all(
				func(inner: Variant) -> bool: return not (inner is Array or inner is Dictionary))):
			return false
	return JSON.stringify(value, "", false).length() <= 120
