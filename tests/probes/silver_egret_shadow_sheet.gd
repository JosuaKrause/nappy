extends RefCounted
## Evidence rig for silver-egret, a shadow is where the object meets the ground: draws every car
## and vehicle the change reaches at all eight `EightDirection` sectors, each twice, over the shadow
## it cast before (its ground shape's own `GroundShape.shadow_outline()`, the one oval or capsule)
## and over the one it casts now (`EventLook.shadow_outlines()`, `AgentLook.shadow_outlines()`, one
## oval per wheel pair). The riot van and the moving van keep their shadow
## (`EventVehicleLook.SCENE_SHAPED`) and are left out. The shadows come from the game's own calls: a fake event's look and a crowd
## car the game placed are asked for them, the same calls the draw and the debug view's shadow layer
## make. The pictures are re-rasterised from their authored SVGs, as
## `tests/probes/m108_event_vehicles_sheet.gd` does, and stood where the game stands them: on the
## node, or over the body for the cars that drive (`EventLook.body_anchor()`,
## `CarLook.body_anchor()`). The police car is drawn a third time with its body riding up by
## `WheelBob.HEIGHT` over the wheels and shadow that stay on the ground, its second ride frame.
##
## Not a suite: it saves one PNG per row and prints their names, so it lives under `tests/probes/`,
## where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/silver_egret_shadow_sheet.gd
##
## Output goes to `OUT_DIR`, one `<row>.png` per row, eight cells of `CELL` world pixels at
## `SCALE`, the node a little below each cell's middle.

const ViewRig := preload("res://tests/view_rig.gd")

const OUT_DIR := "user://silver-egret-shadow-sheet"
const CELL := 84
const SCALE := 3.0
const GROUND := Color("c9c3b3")
## Where the node stands in a cell, in world pixels from its top-left corner.
const NODE := Vector2(42.0, 52.0)

func run(t: TestRunner) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var rig := ViewRig.new()
	_crowd_car_rows(rig)
	rig.release_atlas()
	_event_rows("police", "police_patrol", EventPictures.POLICE_CAR_BY_VIEW, false, true)
	_event_rows("fire-engine", "fire_truck", EventPictures.FIRE_ENGINE_BY_VIEW, true)
	_event_rows("delivery-van", "delivery_van", EventPictures.DELIVERY_VAN_BY_VIEW, true)
	_event_rows("army-truck", "military_convoy", EventPictures.ARMY_TRUCK_BY_VIEW, true)
	_event_rows("ice-cream-van", "ice_cream_van", EventPictures.ICE_CREAM_VAN_BY_VIEW, false)
	_event_rows("lorry", "reversing_lorry", EventPictures.LORRY_BY_VIEW, false)
	_event_rows("unmarked-van", "abduction", EventPictures.UNMARKED_VAN_BY_VIEW, true)
	_stationary_rows("burnt-out-car", "burnt_out_car", EventDef.Look.BURNT_OUT_CAR)
	print("silver_egret_shadow_sheet: rows written under %s"
			% ProjectSettings.globalize_path(OUT_DIR))
	t.check(true, "silver_egret_shadow_sheet probe ran")

# --------------------------------------------------------------------- the rows ---

func _sector_heading(sector: int) -> Vector2:
	return Vector2.from_angle(deg_to_rad(sector * 45.0))

## A turn whose tangent is exactly `sector`'s diagonal, halfway round a quarter turn from an
## east-west lane — `tests/test_car_views.gd`'s own `_turn_facing()`.
func _turn_facing(sector: int) -> CarTurn:
	var direction := 1.0 if sector in [1, 7] else -1.0
	var turning := 1.0 if sector in [1, 3] else -1.0
	var lane := CrowdLanes.road_lane(false, direction)
	var turn := CarTurn.into_an_arm(false, direction, 0, CrowdLanes.lane_centre(0, lane), 0,
			CrowdLanes.ROAD_OFFSETS[0], turning, Vector2i.ZERO)
	turn.travel_on(turn.length() * 0.5)
	return turn

func _crowd_car_rows(rig: ViewRig) -> void:
	var before: Array[Image] = []
	var after: Array[Image] = []
	for sector in range(8):
		var agent: CrowdAgent
		if sector % 2 == 0:
			agent = rig.place(CrowdAgent.Kind.CAR, _sector_heading(sector).round())
		else:
			agent = rig.place(CrowdAgent.Kind.CAR, Vector2.RIGHT)
			agent.take_the_turn(_turn_facing(sector), 0.0)
		var look := ViewRig.car_look(agent)
		var heading := agent.heading()
		var view: String = CarLook.VIEW_BY_SECTOR[look.picture(agent.velocity()).x]
		var mirror := look.flipped()
		var picture := _crowd_car_picture(view, mirror)
		var anchor := CarLook.body_anchor(view, heading)
		var old: Array[PackedVector2Array] = [agent.shape().shadow_outline(Vector2.ZERO, heading)]
		before.append(_cell(old, picture, anchor))
		after.append(_cell(look.shadow_outlines(Vector2.ZERO), picture, anchor))
		agent.free()
	_save_row("crowd-car-before", before)
	_save_row("crowd-car-after", after)

## The crowd car's three layers composed at rest, the body tinted with the first paint the palette
## rolls (`Palette.CAR_PAINT`), as `CarLook.draw_body()` tints it.
func _crowd_car_picture(view: String, mirror: bool) -> Image:
	var body := _svg(CarLook.BODY_BY_VIEW[view])
	var paint: Color = Palette.CAR_PAINT[0]
	for y in body.get_height():
		for x in body.get_width():
			body.set_pixel(x, y, body.get_pixel(x, y) * paint)
	body.blend_rect(_svg(CarLook.TRIM_BY_VIEW[view]), Rect2i(Vector2i.ZERO, body.get_size()),
			Vector2i.ZERO)
	body.blend_rect(_svg(CarLook.WHEELS_BY_VIEW[view]), Rect2i(Vector2i.ZERO, body.get_size()),
			Vector2i.ZERO)
	if mirror:
		body.flip_x()
	return body

## The event vehicle `def_id` at every sector, as `EventLook._draw_eight_view()` selects its view
## and mirror (`side_faces_west` included), before and after; `riding` adds the row with its body
## up by `WheelBob.HEIGHT`.
func _event_rows(name: String, def_id: String, by_view: Dictionary, side_faces_west: bool,
		riding := false) -> void:
	var def := EventCatalogue.by_id(def_id)
	var before: Array[Image] = []
	var after: Array[Image] = []
	var ridden: Array[Image] = []
	for sector in range(8):
		var instance := FakeEvent.new()
		instance.heading = _sector_heading(sector)
		instance.solid_direction = instance.heading if def.drives() else Vector2.RIGHT
		instance.shape = def.ground_shape()
		var look := instance.look_for(def)
		var view := look.select_view(instance.heading)
		var mirror := look.is_mirrored()
		if view == "side" and side_faces_west:
			mirror = not mirror
		var picture: String = by_view[view]
		var anchor := look.body_anchor(view) \
				if EventPictures.is_anchored_over_its_body(def.look().picture()) else Vector2.ZERO
		var old: Array[PackedVector2Array] = [
				def.ground_shape().shadow_outline(Vector2.ZERO, instance.solid_axis())]
		before.append(_cell(old, _vehicle_picture(picture, mirror, 0), anchor))
		var now := look.shadow_outlines(Vector2.ZERO)
		after.append(_cell(now, _vehicle_picture(picture, mirror, 0), anchor))
		if riding:
			var lift := roundi(WheelBob.HEIGHT * SCALE)
			ridden.append(_cell(now, _vehicle_picture(picture, mirror, lift), anchor))
		instance.free()
	_save_row(name + "-before", before)
	_save_row(name + "-after", after)
	if riding:
		_save_row(name + "-after-riding", ridden)

## A stationary wreck, standing side on and end on, before and after.
func _stationary_rows(name: String, def_id: String, look_id: EventDef.Look) -> void:
	var def := EventCatalogue.by_id(def_id)
	var before: Array[Image] = []
	var after: Array[Image] = []
	for side_on: bool in [true, false]:
		var instance := FakeEvent.new()
		instance.side_on = side_on
		instance.heading = Vector2.RIGHT
		instance.solid_direction = Vector2.RIGHT if side_on else Vector2.DOWN
		instance.shape = def.ground_shape()
		var look := instance.look_for(def)
		var region := EventPictures.stationary_vehicle_texture(look_id, side_on)
		var extent := EventPictures.stationary_vehicle_extent(region, side_on,
				def.body().drawn_width())
		var picture := _svg(region)
		if extent != Vector2.ZERO:
			picture.resize(roundi(extent.x * SCALE), roundi(extent.y * SCALE),
					Image.INTERPOLATE_NEAREST)
		var old: Array[PackedVector2Array] = [
				def.ground_shape().shadow_outline(Vector2.ZERO, instance.solid_axis())]
		before.append(_cell(old, picture, Vector2.ZERO))
		after.append(_cell(look.shadow_outlines(Vector2.ZERO), picture, Vector2.ZERO))
		instance.free()
	_save_row(name + "-before", before)
	_save_row(name + "-after", after)

# ------------------------------------------------------------------ rendering ---

## The authoring SVG behind a region name, rasterised at `SCALE`: the sources live under `art/`,
## which the engine imports nothing from, so the bytes are read with `FileAccess`.
func _svg(region_name: String) -> Image:
	var image := Image.new()
	image.load_svg_from_string(
			FileAccess.get_file_as_string("res://art/%s.svg" % region_name), SCALE)
	image.convert(Image.FORMAT_RGBA8)
	return image

## A vehicle picture with its wheels composed in, under or over the body as
## `EventLook._draw_eight_view()` draws them, the body lifted `lift` pixels above them.
func _vehicle_picture(region_name: String, mirror: bool, lift: int) -> Image:
	var body := _svg(region_name)
	var wheels_name := region_name + "_wheels"
	if FileAccess.file_exists("res://art/%s.svg" % wheels_name):
		var wheels := _svg(wheels_name)
		var whole := Image.create(body.get_width(), body.get_height(), false, Image.FORMAT_RGBA8)
		var size := Rect2i(Vector2i.ZERO, body.get_size())
		if wheels_name in EventPictures.WHEELS_BEHIND_THE_BODY:
			whole.blend_rect(wheels, size, Vector2i.ZERO)
			whole.blend_rect(body, size, Vector2i(0, -lift))
		else:
			whole.blend_rect(body, size, Vector2i(0, -lift))
			whole.blend_rect(wheels, size, Vector2i.ZERO)
		body = whole
	if mirror:
		body.flip_x()
	return body

## One cell: the ground, `outlines` filled in `Palette.SHADOW` round the node, and `picture` stood
## bottom-centred at the node plus `anchor`, as `Sprites.draw_standing()` stands it.
func _cell(outlines: Array[PackedVector2Array], picture: Image, anchor: Vector2) -> Image:
	var side := roundi(CELL * SCALE)
	var cell := Image.create(side, side, false, Image.FORMAT_RGBA8)
	cell.fill(GROUND)
	for y in side:
		for x in side:
			var world := Vector2(float(x) + 0.5, float(y) + 0.5) / SCALE - NODE
			for outline in outlines:
				if Geometry2D.is_point_in_polygon(world, outline):
					cell.set_pixel(x, y, cell.get_pixel(x, y).blend(Palette.SHADOW))
	var foot := (NODE + anchor) * SCALE
	var at := Vector2i(roundi(foot.x - picture.get_width() * 0.5),
			roundi(foot.y - picture.get_height()))
	cell.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)
	return cell

func _save_row(name: String, cells: Array[Image]) -> void:
	var side := roundi(CELL * SCALE)
	var row := Image.create(side * cells.size(), side, false, Image.FORMAT_RGBA8)
	for i in cells.size():
		row.blit_rect(cells[i], Rect2i(0, 0, side, side), Vector2i(i * side, 0))
	row.save_png(ProjectSettings.globalize_path(OUT_DIR.path_join(name + ".png")))
