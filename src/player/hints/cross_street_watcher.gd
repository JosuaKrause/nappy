class_name CrossStreetWatcher
extends HintWatcher
## **Cross the street**: a body closes her sidewalk ahead and the far one is open; the bubble
## points at the nearest zebra crossing (curly-moose #819, "a hint to cross the street"). She is on
## a street's sidewalk walking along it; the stretch looked at is the width of her sidewalk for
## `LOOK_AHEAD_TILES` ahead of her, and the far sidewalk's stretch beside it. Whether a body stands
## on a stretch is the events' answer (`EventManager.has_a_body_on()`); whether the far stretch can
## be walked is the map's. Armed again once the moment is over.

## How far ahead, in tiles, her sidewalk is looked along.
const LOOK_AHEAD_TILES := 4
## How closely her heading runs along the street: the cosine of the angle between the two.
const ALONG_COSINE := 0.7

var _map: CityMap
var _events: EventManager
var _crossings: NearestCrossing
var _armed := true

func _init(map: CityMap, events: EventManager, crossings: NearestCrossing) -> void:
	_map = map
	_events = events
	_crossings = crossings

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.CROSS_STREET

## Overrides HintWatcher.begin_walk.
func begin_walk(_route: TutorialRoute) -> void:
	_armed = true

## Overrides HintWatcher.asks.
func asks(frame: HintFrame) -> bool:
	var applies := _closed_ahead_and_open_across(frame)
	if not applies:
		_armed = true
	return applies and _armed

## Overrides HintWatcher.direction.
func direction(frame: HintFrame) -> Vector2:
	return _crossings.toward(_map.world_to_tile(frame.position()))

## Overrides HintWatcher.shown.
func shown() -> void:
	_armed = false

func _closed_ahead_and_open_across(frame: HintFrame) -> bool:
	var tile := _map.world_to_tile(frame.position())
	var inward := _map.pavement_inward(tile)
	if inward == Vector2i.ZERO:
		return false
	var across := Vector2i(absi(inward.x), absi(inward.y))
	var along := Vector2i(across.y, across.x)
	var lined := frame.heading().dot(Vector2(along))
	if absf(lined) < ALONG_COSINE:
		return false
	var offsets := _map.corridor_offsets(tile)
	var offset := offsets.x if across.x != 0 else offsets.y
	var start := (tile.x if across.x != 0 else tile.y) - offset
	var far_side := Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
	var hers := start if offset < Tuning.SIDEWALK_WIDTH else start + far_side
	var far := start + far_side if offset < Tuning.SIDEWALK_WIDTH else start
	var ahead := int(signf(lined))
	var her_stretch := _stretch(tile, along, across, ahead, hers)
	var far_stretch := _stretch(tile, along, across, ahead, far)
	if not _events.has_a_body_on(_map.tile_rect_to_world(her_stretch)):
		return false
	if _events.has_a_body_on(_map.tile_rect_to_world(far_stretch)):
		return false
	for x in range(far_stretch.position.x, far_stretch.end.x):
		for y in range(far_stretch.position.y, far_stretch.end.y):
			if not _map.is_open(Vector2i(x, y)):
				return false
	return true

## The tiles of one sidewalk band, `band` being its first coordinate across the street, for
## `LOOK_AHEAD_TILES` from the tile past `tile` along `along` in the direction `ahead` (1 or -1).
static func _stretch(tile: Vector2i, along: Vector2i, across: Vector2i, ahead: int,
		band: int) -> Rect2i:
	var here := tile.x if along.x != 0 else tile.y
	var first := here + 1 if ahead > 0 else here - LOOK_AHEAD_TILES
	var along_span := Vector2i(first, LOOK_AHEAD_TILES)
	var across_span := Vector2i(band, Tuning.SIDEWALK_WIDTH)
	if along.x != 0:
		return Rect2i(along_span.x, across_span.x, along_span.y, across_span.y)
	return Rect2i(across_span.x, along_span.x, across_span.y, along_span.y)
