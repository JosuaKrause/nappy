class_name CityDecals
extends Node2D
## Loose litter and street-tree beds, drawn flat: no body, no field, no y-sort. Placed between
## `Ground` and `Buildings` in `city.tscn`, so a decal always lies under a building or an entity
## and never sorts against either the way a `Prop` does. The beds remain on this layer even though
## their standing trees belong to the y-sorted `Entities` layer.
##
## `City` calls `set_placed(Litter.placed(map, day))` once a day, the same as `_dress_blocks()`
## rebuilds `_props`; nothing here rolls its own placement.

var _placed: Array[Litter.Placed] = []
var _street_tree_pits: Array[StreetTrees.Planted] = []
var _map: CityMap = null
var streamed := false
var _resident: Dictionary = {}
var _view := Rect2()
var _retained := Rect2()
var _litter_chunks: Dictionary = {}
var _pit_chunks: Dictionary = {}

const TREE_PIT := &"props/tree_pit"

## The atlas group the street's decoration is drawn from — the five litter decals and
## the tree bed here, and the trees, the bollard, the swing frame, the garbage sack and its pile
## that `Prop` draws. One group rather than two, because they are placed and dressed together
## and a street shows them together: a sack on the kerb beside a tree over a bed of litter is
## exactly the run of sprites the composite was asked to stop breaking between. The group's
## lifetime is the city's: `City.build()` acquires it before the first day is drawn and
## `City._exit_tree()` releases it.
const DECORATION_ATLAS := &"decoration"

## The city's library (`AtlasLibrary`), handed by the city before it builds: the city holds the
## decoration group on it, and the decals draw their regions from it.
var atlas: AtlasLibrary
## What every decal is laid through (`SceneryDrawer`), handed by the city before it builds: on this
## node's own canvas when it is not streamed, and handed on to each chunk's layer when it is.
var drawer: SceneryDrawer

## Hands the decals the library they draw from (see `atlas`).
func use_atlas(library: AtlasLibrary) -> void:
	atlas = library

## Hands the decals what they are laid through (see `drawer`).
func draw_through(through: SceneryDrawer) -> void:
	drawer = through

## Has the decals stream in chunks as they come into view (see `streamed`).
func stream_in_chunks() -> void:
	streamed = true

func set_placed(placed: Array[Litter.Placed]) -> void:
	_placed = placed
	_refresh_chunks()
	queue_redraw()

## Street-tree beds are flat ground marks, so they belong to this layer rather than to the
## y-sorted `Entities` layer that owns the standing tree. The planted positions remain fixed for
## the run; `CityMap` supplies which pits today's fallen-tree closures have emptied.
func set_street_tree_pits(placed: Array[StreetTrees.Planted], city_map: CityMap) -> void:
	_street_tree_pits = placed
	_map = city_map
	_refresh_chunks()
	queue_redraw()

## Repaint after closures or seals choose an emptied pit for the day.
func refresh_street_tree_pits() -> void:
	_refresh_chunks()
	queue_redraw()

func _refresh_chunks() -> void:
	_litter_chunks.clear()
	_pit_chunks.clear()
	for entry in _placed:
		var key := SceneryGround.key_for(Vector2i((entry.position / Tuning.TILE_SIZE).floor()))
		if not _litter_chunks.has(key):
			_litter_chunks[key] = []
		_litter_chunks[key].append(entry)
	for entry in _street_tree_pits:
		var key := SceneryGround.key_for(entry.tile)
		if not _pit_chunks.has(key):
			_pit_chunks[key] = []
		_pit_chunks[key].append(entry)
	for layer: SceneryLayer in _resident.values():
		layer.free()
	_resident.clear()
	if streamed and _view.has_area():
		update_view(_view, _retained)

func update_view(load_view: Rect2, retained: Rect2, enqueue := Callable()) -> void:
	_view = load_view
	_retained = retained
	for key: Vector2i in _resident.keys():
		if not retained.intersects(SceneryGround.bounds(key).grow(Tuning.TILE_SIZE)):
			(_resident[key] as SceneryLayer).free()
			_resident.erase(key)
	var candidates := _litter_chunks.duplicate()
	candidates.merge(_pit_chunks)
	for key: Vector2i in candidates:
		if _resident.has(key) or not load_view.intersects(
				SceneryGround.bounds(key).grow(Tuning.TILE_SIZE)):
			continue
		if enqueue.is_valid():
			enqueue.call(SceneryGround.bounds(key).grow(Tuning.TILE_SIZE), _prepare_chunk.bind(key))
		else:
			_prepare_chunk(key)

func _prepare_chunk(key: Vector2i) -> void:
	var layer := SceneryLayer.new()
	layer.draw_through(drawer)
	add_child(layer)
	_resident[key] = layer
	for entry: Litter.Placed in _litter_chunks.get(key, []):
		var texture := atlas.region(Litter.TEXTURES[entry.texture_index])
		layer.append(texture, Rect2(entry.position - texture.get_size() * 0.5, texture.get_size()))
	for entry: StreetTrees.Planted in _pit_chunks.get(key, []):
		if not _map.is_tree_pit_emptied(entry.tile):
			var texture := atlas.region(TREE_PIT)
			layer.append(texture, Rect2(entry.position - texture.get_size() * 0.5, texture.get_size()))

func _draw() -> void:
	if streamed:
		return
	for entry in _placed:
		var texture := atlas.region(Litter.TEXTURES[entry.texture_index])
		drawer.draw(self, texture, Rect2(entry.position - texture.get_size() * 0.5,
				texture.get_size()), Rect2())
	var pit := atlas.region(TREE_PIT)
	for entry in _street_tree_pits:
		if _map and _map.is_tree_pit_emptied(entry.tile):
			continue
		drawer.draw(self, pit, Rect2(entry.position - pit.get_size() * 0.5, pit.get_size()),
				Rect2())
