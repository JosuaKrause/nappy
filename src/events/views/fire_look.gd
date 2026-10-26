class_name FireLook
extends EventLook
## A burning building: the flames along its facade and the smoke over them, or the five flames of a
## fire that stands on its own ground.

func _draw_figure(canvas: CanvasItem) -> void:
	match event.def.look:
		EventDef.Look.BURNING_BUILDING:
			_draw_fire(canvas)

## How far apart the flames on a facade stand at most, how wide each is, and how tall the short
## and the tall one of each alternating pair reach before the flicker scales them — climbing a good
## part of an ordinary building's own wall (two to three tiles, `city.gd`'s own `_HEIGHT_TILES`)
## rather than sitting at ankle height. The implementer's own choice, open to overturn: no field
## here reads the actual building's height, so a one-tile sliver burns under flames taller than its
## own roofline.
const _FIRE_SPREAD := 14.0

const _FIRE_WIDTH := 22.0

const _FIRE_HEIGHT := 60.0

const _FIRE_HEIGHT_TALL := 26.0

## The smoke sits above the tallest flame reaches at rest, not above wherever the flicker happens
## to have it this frame — an anchor that rode the flicker would hop a couple of pixels every beat.
const _SMOKE_SIZE := Vector2(40.0, 60.0)

## One plume of smoke for about every this many pixels of burning facade — three tiles — so a wide
## front smokes along its length rather than from one point over the middle of it.
const _SMOKE_EVERY := 96.0

## The stretches of the burning facade the city draws, each as its west and east ends in this
## instance's local x — `_facade_runs_at()`'s answer for where it stands, worked out on the first
## draw (`_fire_facade_found`): a sited fire never moves.
var _fire_facade := PackedVector2Array()

var _fire_facade_found := false

## Two fires share one look. **A fire with a body burns where it stands**: the finale's stairwell
## fire (`EventCatalogue.building_fire()`), which is the hazard there. **A fire with none burns on
## the facade of the building its row stands against, along the whole of it**: the street fire,
## *"the fire goes on the building. the challenge is the fire truck not the fire"* (PLAYTEST-144,
## statement 12) and *"the fire should be on the whole building not only the door"*
## (sandy-egret), which has no body and no shadow to draw, only the picture.
func _draw_fire(canvas: CanvasItem) -> void:
	if event.def.obstructs_radius > 0.0:
		_draw_fire_where_it_stands(canvas)
		return
	var against_the_wall := _wall_offset()
	var flames := _flames_across(_fire_facade_runs())
	for i in flames.size():
		var flicker := 1.0 + 0.25 * sin(event.age * 9.0 + i * 1.7)
		var height := (_FIRE_HEIGHT + i % 2 * _FIRE_HEIGHT_TALL) * flicker
		Sprites.draw_standing(canvas, EventPictures.drawn(EventPictures.FLAME), against_the_wall + Vector2(flames[i].x, 0.0),
				Vector2(flames[i].y, height))
	# Neighboring plumes billow out of step, so a long front's smoke does not pulse as one.
	var billowing := _idle_stepping(EventPictures.STEAM_BILLOW_PERIOD)
	var plumes := _smoke_across(_fire_facade_runs())
	for i in plumes.size():
		var picture := EventPictures.STEAM_B if billowing != (i % 2 == 1) else EventPictures.STEAM
		Sprites.draw_standing(canvas, EventPictures.drawn(picture), against_the_wall
				+ Vector2(plumes[i].x, -(_FIRE_HEIGHT + _FIRE_HEIGHT_TALL)),
				Vector2(plumes[i].y, _SMOKE_SIZE.y))

## `_fire_facade`, worked out on its first ask.
func _fire_facade_runs() -> PackedVector2Array:
	if not _fire_facade_found:
		_fire_facade = _facade_runs_at(event.world_map(), event.global_position)
		_fire_facade_found = true
	return _fire_facade

## **Everything a street fire draws, in its own space, which is far more than its picture**: the
## whole burning front (`_fire_facade_runs()`), half a tile toward the wall (`_wall_offset()`), from
## the ground up to the top of the smoke over the tallest flame — the flames' own flicker never
## reaches past it. Empty for anything but a fire with no body, whose drawing is its picture. Read
## by `_drawn_reach()` and `drawn_rect_now()`; a sited fire never moves, so neither changes.
func _fire_front_box() -> Rect2:
	if event.def.look != EventDef.Look.BURNING_BUILDING or event.def.obstructs_radius > 0.0:
		return Rect2()
	var top := -(_FIRE_HEIGHT + _FIRE_HEIGHT_TALL) - _SMOKE_SIZE.y
	var box := Rect2()
	var any := false
	for run in _fire_facade_runs():
		var one := Rect2(run.x, top, run.y - run.x, -top)
		box = one if not any else box.merge(one)
		any = true
	return Rect2(box.position + _wall_offset(), box.size).grow(1.0) if any else Rect2()

## Flames scaled by what the event is currently emitting, so a fire visibly roars, over the body's
## own shadow: five flames 11px apart, spanning the ±31px the 30px body is half of.
func _draw_fire_where_it_stands(canvas: CanvasItem) -> void:
	var strength := 1.0
	if event.def.intensity > 0.0:
		strength = clampf(event.current_intensity() / event.def.intensity, 0.2, 1.0)
	_draw_body_shadow(canvas)
	for i in 5:
		var offset := (i - 2.0) * 11.0
		var flicker := 1.0 + 0.25 * sin(event.age * 9.0 + i * 1.7)
		var height := (34.0 + i % 2 * 14.0) * strength * flicker
		Sprites.draw_standing(canvas, EventPictures.drawn(EventPictures.FLAME), Vector2(offset, 0.0), Vector2(18.0, height))

## The facade a fire sited at `at` burns on, as the stretches of it the city draws, each as its
## west and east ends in local x measured from `at`: the lot (`CityMap.building_rects`, one per
## `Building`) holding the tile the sidewalk's `pavement_inward()` points at, less every column
## whose ground in front is not walkable — the column another building's roof reaches up to cover
## (`City._covered_ground_cols()`, the same lattice fact), whose facade is not drawn, so a flame
## there would burn on the other building's roof. Off a pavement or with no lot there (open ground,
## the building's stairwell), one stretch of the five flames' own width, drawn as they are.
static func _facade_runs_at(map: WorldMap, at: Vector2) -> PackedVector2Array:
	var reach := 2.0 * _FIRE_SPREAD + _FIRE_WIDTH * 0.5
	var unclamped := PackedVector2Array([Vector2(-reach, reach)])
	var tile := map.world_to_tile(at)
	var inward := map.pavement_inward(tile)
	if inward == Vector2i.ZERO:
		return unclamped
	var rect := map.lot_at(tile + inward)
	if rect.has_area():
		var runs := PackedVector2Array()
		var size := float(Tuning.TILE_SIZE)
		var west := map.tile_rect_to_world(rect).position.x - at.x
		var open_from := -1
		for col in rect.size.x + 1:
			var open := col < rect.size.x \
					and map.is_walkable(Vector2i(rect.position.x + col, rect.end.y))
			if open and open_from < 0:
				open_from = col
			elif not open and open_from >= 0:
				runs.append(Vector2(west + open_from * size, west + col * size))
				open_from = -1
		return runs if not runs.is_empty() else unclamped
	return unclamped

## The flames along `runs` (`_facade_runs_at()`'s answer), each as its centre's local x and its
## width: every stretch is filled edge to edge, no two flames further apart than `_FIRE_SPREAD`,
## so the whole facade burns. **Every flame stays inside the burning building's own facade**: the
## first and the last of a stretch touch its ends, never a tile of the neighbor's, and a stretch
## narrower than one flame squeezes it to fit.
static func _flames_across(runs: PackedVector2Array) -> PackedVector2Array:
	var flames := PackedVector2Array()
	for run in runs:
		var width := run.y - run.x
		var flame := minf(_FIRE_WIDTH, width)
		var count := maxi(1, ceili((width - flame) / _FIRE_SPREAD) + 1)
		if count == 1:
			flames.append(Vector2((run.x + run.y) * 0.5, flame))
			continue
		var step := (width - flame) / float(count - 1)
		for i in count:
			flames.append(Vector2(run.x + flame * 0.5 + i * step, flame))
	return flames

## The smoke over `runs`, each plume as its centre's local x and its width: one for about every
## `_SMOKE_EVERY` pixels of a stretch, spaced evenly along it and never wider than the stretch.
static func _smoke_across(runs: PackedVector2Array) -> PackedVector2Array:
	var plumes := PackedVector2Array()
	for run in runs:
		var width := run.y - run.x
		var count := maxi(1, roundi(width / _SMOKE_EVERY))
		for i in count:
			plumes.append(Vector2(run.x + width * (i + 0.5) / count, minf(_SMOKE_SIZE.x, width)))
	return plumes

## How far the fire's own drawing sits from where the row was sited, toward the wall it stands
## against — `CityMap.pavement_inward()` read the same way `_hut_doorway()` reads it, since these
## nodes' local axes never rotate. A row with no body is never moved off the centre of the tile it
## was sited on (`setup()` centres only a body on its pavement band), and the frontage lane's tile
## centre is half a tile from the wall, so this is that half tile, closing the gap onto the
## frontage. `Vector2.ZERO` off a pavement (open ground, the building's stairwell): the flames stay
## where they are drawn with no wall to reach for.
func _wall_offset() -> Vector2:
	var inward := event.world_map().pavement_inward(event.world_map().world_to_tile(event.global_position))
	return Vector2(inward) * (Tuning.TILE_SIZE * 0.5)

func _front_box() -> Rect2:
	return _fire_front_box()
