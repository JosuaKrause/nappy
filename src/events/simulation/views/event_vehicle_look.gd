class_name EventVehicleLook
extends EventLook
## A row drawn as a vehicle: the parked vans and trucks, the cars that drive (the patrol car and the
## fire engine, drawn over their own bodies on wheels that stay on the ground), the van that takes
## a victim, and the stationary wrecks and moving van.

## What it takes a victim by (`AbductionSpec`): how long its victim walks to it and where they stand to
## be taken, or null for a row that takes nobody. Handed when the look is made, as the abduction
## behaviour is its own.
var _abduction: AbductionSpec

## Handed, as its event is set up, what every look is handed and the abduction part of its row.
func _init(owner: EventInstance, look: LookSpec, body: BodySpec, abduction: AbductionSpec,
		drawer: EventDrawer, skip_draw: bool, drawn_view: DrawnView) -> void:
	super(owner, look, body, drawer, skip_draw, drawn_view)
	_abduction = abduction

## Overrides EventLook._draw_figure.
func _draw_figure(canvas: CanvasItem) -> void:
	match _look.picture():
		EventDef.Look.DELIVERY_VAN:
			# Always sited facing east — `AT_THE_KERB` never overrides `EventPlan.
			# facing`'s own default — and `delivery_van.svg` faces west, so `side_faces_west`
			# mirrors it (see `docs/evidence/svg-vehicles-2026-09-10/README.md`).
			_draw_eight_view(EventPictures.DELIVERY_VAN_BY_VIEW, event.facing_now(), canvas, true)
		EventDef.Look.FIRE_ENGINE:
			# Drawn over its own body like the patrol car (`body_anchor()`): the body is the
			# truck's `shape`, and the shadow, which is that shape, stays under the node.
			var engine_view := select_view(event.facing_now())
			_draw_body_shadow(canvas, Vector2(0.0, -current_bob()))
			_draw_eight_view(EventPictures.FIRE_ENGINE_BY_VIEW, event.facing_now(), canvas, true,
					{}, false,
					body_anchor(engine_view))
		EventDef.Look.ICE_CREAM_VAN:
			# East-authored: always sited facing east, same as `DELIVERY_VAN` above,
			# but `ice_cream_van.svg` is one of the sources that already faces east, so no
			# `side_faces_west` override and no change to the picture it draws.
			_draw_eight_view(EventPictures.ICE_CREAM_VAN_BY_VIEW, event.facing_now(), canvas)
		EventDef.Look.LORRY:
			# `reversing_lorry`'s own facing is always exactly east or west — `AGAINST_THE_BUILDING`
			# sets it to `-pavement_inward`, which `RowGround._wants_this_side()` already refuses unless it is
			# purely horizontal — so the diagonal and front/back views this table adds are never
			# actually reachable; the row draws its side view.
			_draw_eight_view(EventPictures.LORRY_BY_VIEW, event.facing_now(), canvas)
		EventDef.Look.POLICE_CAR:
			# East-authored — see `ICE_CREAM_VAN` above — and a real octant: `police_patrol` is
			# mobile and turns corners along its own patrol route, so its diagonal views are
			# ordinarily reachable. Drawn over its own body rather than standing on its node — see
			# `body_anchor()` — with the shadow, which is the body's shape, under the node on the
			# ground.
			var view := select_view(event.facing_now())
			_draw_body_shadow(canvas, Vector2(0.0, -current_bob()))
			_draw_eight_view(EventPictures.POLICE_CAR_BY_VIEW, event.facing_now(), canvas, false,
					{}, false,
					body_anchor(view))
		EventDef.Look.UNMARKED_VAN:
			_draw_abduction(canvas)
		EventDef.Look.RIOT_VAN:
			# West-authored, like `unmarked_van` and `army_truck` — see
			# `EventPictures.RIOT_VAN_BY_VIEW`'s own doc comment for why the side view needs the
			# `side_faces_west` override to match `facings.csv`.
			_draw_eight_view(EventPictures.RIOT_VAN_BY_VIEW, event.facing_now(), canvas, true)
		EventDef.Look.ARMY_TRUCK:
			_draw_eight_view(EventPictures.ARMY_TRUCK_BY_VIEW, event.facing_now(), canvas, true)
		EventDef.Look.MOVING_VAN:
			_draw_stationary_vehicle(EventDef.Look.MOVING_VAN, _body.drawn_width(),
					canvas)
		EventDef.Look.BURNT_OUT_CAR:
			_draw_stationary_vehicle(EventDef.Look.BURNT_OUT_CAR,
					_body.drawn_width(), canvas)

## A vehicle's shadow lies where its wheels meet the ground (minty-hedgehog 1; azure-koala 10): one
## oval per wheel pair of the body its wheels stand under (`_wheel_shape()`,
## `GroundShape.paired_shadow_outlines()`), laid along the way its picture faces
## (`_wheel_axis()`), the nearer pair on the picture's own ground line — the bottom of its body
## for a car drawn over its body (`_ground_line()`), its node for every other vehicle — so no
## shadow shows above a roof or behind a body with nothing under its tyres.
##
## Overrides EventLook.shadow_outlines.
func shadow_outlines(origin := Vector2.ZERO) -> Array[PackedVector2Array]:
	var shape := _wheel_shape()
	if not _look.casts_a_shadow() or shape == null or not shape.casts_a_shadow():
		var none: Array[PackedVector2Array] = []
		return none
	return shape.paired_shadow_outlines(origin, _wheel_axis(), _ground_line())

## The two vehicle looks whose ground shape is the scene round the vehicle rather than its own
## body, so it says nothing about where its wheels are: the night raid's riot van, whose 44px disc
## holds the officers round it, and the moving van, whose band runs along the street under its ramp
## and its boxes. Their wheels stand under a body of their own (`_wheel_shape()`), and the ground
## shape keeps what the scene needs it for.
const SCENE_SHAPED: Array[EventDef.Look] = [EventDef.Look.RIOT_VAN, EventDef.Look.MOVING_VAN]

## How far a scene-shaped vehicle's own body reaches from its centre, as a share of half the length
## its side picture is drawn: the share the other vehicles' bodies keep to their pictures (the
## delivery van's 22px under its 48px side picture, the lorry's 28 under 62, the army truck's 26
## under 60), so its wheel pairs stand `GroundShape.POINT_WHEEL_SHARE` of that from its centre, the
## riot van's 15px either side, round the tyres its 54px side picture draws 13px either side.
const SCENE_BODY_SHARE := 0.9

## The body a scene-shaped vehicle's wheels stand under, made the first time it is asked for
## (`_wheel_shape()`); null until then and for every other vehicle.
var _own_body: GroundShape = null

## The body its wheel pairs stand under: its own ground shape for every vehicle but the two whose
## ground shape is their scene (`SCENE_SHAPED`), and for those a point reaching
## `SCENE_BODY_SHARE` of half the length its side picture is drawn (`_side_length()`), the way
## the other vehicles' bodies reach, since where its wheels are is in the picture and not in the
## ground its scene takes.
func _wheel_shape() -> GroundShape:
	if _look.picture() not in SCENE_SHAPED:
		return event.ground_shape()
	if _own_body == null:
		_own_body = GroundShape.point(_side_length() * 0.5 * SCENE_BODY_SHARE)
	return _own_body

## How long a scene-shaped vehicle's side picture is drawn: a stationary vehicle's fitted to its
## body's drawn width (`_draw_stationary_vehicle()`), the riot van's at its own size
## (`_draw_eight_view()` stands every view at its native size).
func _side_length() -> float:
	var side := EventPictures.stationary_vehicle_texture(_look.picture(), true)
	if not side.is_empty():
		return EventPictures.stationary_vehicle_extent(side, true, _body.drawn_width()).x
	return EventPictures.native_size(EventPictures.RIOT_VAN_BY_VIEW["side"]).x

## The row of `moving_van_vertical.svg` (its 38 by 56 end-on picture) its rear tyres stand on: they
## fill rows 30 to 43, and the ramp runs on to the picture's bottom row 13px below them. The nearer
## pair's ovals lie on this row (`_ground_line()`), not on the picture's bottom row, which is the
## ramp's foot.
const MOVING_VAN_END_TYRE_FOOT_ROW := 43.0

## How far below its node the nearer wheel pair stands: the picture's bottom row for every vehicle
## (`EventLook._ground_line()`), except the moving van seen end on, whose bottom row is the ramp's
## foot and whose tyres stand `MOVING_VAN_END_TYRE_FOOT_ROW` down its picture, that many rows
## above the bottom row it is stood on.
##
## Overrides EventLook._ground_line.
func _ground_line() -> float:
	if _look.picture() == EventDef.Look.MOVING_VAN and not event.stands_side_on():
		var picture := EventPictures.stationary_vehicle_texture(_look.picture(), false)
		return MOVING_VAN_END_TYRE_FOOT_ROW - EventPictures.native_size(picture).y
	return super()

## The axis its wheel pairs lie along: the way its picture faces. A stationary vehicle — the
## burnt-out car, the moving van — shows its side along an east-west street and its end along a
## north-south one (`EventInstance.stands_side_on()`, `_draw_stationary_vehicle()`); every other
## vehicle is drawn facing `facing_now()`, the heading of one that drives and the side a parked one
## was sited showing.
func _wheel_axis() -> Vector2:
	if not EventPictures.stationary_vehicle_texture(_look.picture(), true).is_empty():
		return Vector2.RIGHT if event.stands_side_on() else Vector2.DOWN
	return event.facing_now()

## A stationary vehicle projected along the axis of the street it occupies. Its side silhouette
## may mirror with its facing; an end-on silhouette keeps its authored proportions and orientation.
## Its shadow is the ovals `shadow_outlines()` lays under its wheel pairs, along the street it
## occupies (`_wheel_axis()`).
func _draw_stationary_vehicle(look: EventDef.Look, side_width: float,
		canvas: CanvasItem) -> void:
	var picture := EventPictures.stationary_vehicle_texture(look, event.stands_side_on())
	var extent := EventPictures.stationary_vehicle_extent(picture, event.stands_side_on(),
			side_width)
	_draw_body_shadow(canvas)
	_drawer.stand(canvas, picture, Vector2.ZERO, extent,
			event.stands_side_on() and _heading_is_west())

## The van, and the bystander it is taking while there is one to draw.
##
## `FigureLook._draw_dog_walker` above is the precedent for a second figure with its own offset;
## here the second figure has a scene rather than a fixed span, sliding from its standing offset to
## the van's own position over the take's length — see `EventAbduction`, the one place that starts
## it. Drawn first so the van's own silhouette is what she is left looking at once the walk ends,
## the same order `RankLook._draw_cafe` draws its sitters before its tables.
##
## The van itself goes through `_draw_eight_view` rather than `_draw_simple`: a parked van never
## needed more than one side-on picture, but a hunting one steers straight at her and that is not
## always down a pavement, so it draws the full front/back/side/diagonal set the same way
## `police_car` does once it turns off its own axis. The victim and the van share one `_view_sector`
## field — safely, because both headings are always exactly east or west by construction while they
## can ever be drawn together. `is_taking_a_victim()` is only ever true while the van `is_waiting()`
## (`EventAbduction` abandons it the instant a `HUNTS`-heated copy starts hunting), and idling the
## van's own `EventInstance.facing_now()` is the plan's untouched facing (what `EventPlan.faces()` answers until `face()` sets it), always due east —
## so the van's own `select_view(event.facing_now())` call below, after the victim's, only ever
## asks for exactly the sector the victim's own call left it on (both facing the same way) or its
## exact opposite (180° apart, always past `EightDirection`'s hold), never anything a stale hold
## could get wrong.
func _draw_abduction(canvas: CanvasItem) -> void:
	if event.is_taking_a_victim():
		var through := _victim_walk_share()
		var offset := _abduction.standing_offset()
		var standing := Vector2(-offset if _heading_is_west() else offset, 0.0)
		var at := standing.lerp(Vector2.ZERO, through)
		_draw_shadow(canvas, at, 8.0)
		# She faces the van, which is the only place she is walking to — a pure east/west direction
		# by construction (`standing` never has a Y component), so this always resolves to the same
		# side view `_heading_is_west()` picked before, now read off the shared table.
		var view := select_view(-standing)
		var by_view := EventPictures.VAN_VICTIM_BY_VIEW_B if victim_gait_is_stepping() \
				else EventPictures.VAN_VICTIM_BY_VIEW
		_drawer.stand(canvas, by_view[view], at, Vector2.ZERO,
				is_mirrored())
	# West-authored, like `delivery_van` and `fire_engine` above — see `_draw_eight_view()`'s own
	# doc comment on `side_faces_west`.
	_draw_eight_view(EventPictures.UNMARKED_VAN_BY_VIEW, event.facing_now(), canvas, true)

## How far through its walk to the van the victim is, from 0 where the walk starts to 1 at the van:
## the time it has walked (`EventInstance.how_long_its_victim_has_walked()`) over the walk's length
## (`AbductionSpec.taken_over()`). The one place the two are divided.
func _victim_walk_share() -> float:
	return event.how_long_its_victim_has_walked() / _abduction.taken_over()

## The victim's own short scripted walk to the van (`EventAbduction`) is a straight-line lerp on
## `age` rather than anything that touches the ground travelled, so it gets its own derived stride
## instead of sharing `gait_phase()` — a persistent field would have nothing to reset between takes
## that the walk's own time restarting at zero does not already give it. The walk is at a constant
## speed by construction (linear interpolation over a fixed time), so the distance covered by
## moment `t` is exactly its share of the way (`_victim_walk_share()`) times
## `AbductionSpec.standing_offset()`, fed through the same `GAIT_RATE` and doubled-phase test
## `gait_is_stepping()` uses. `sin(0) == 0`, so the walk always starts on frame a rather than
## mid-stride.
## Overrides EventLook.victim_gait_is_stepping.
func victim_gait_is_stepping() -> bool:
	if not event.is_taking_a_victim():
		return false
	var covered := _victim_walk_share() * _abduction.standing_offset()
	return sin(covered * EventInstance.GAIT_RATE * 2.0) > 0.0
