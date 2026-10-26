class_name EventVehicleLook
extends EventLook
## A row drawn as a vehicle: the parked vans and trucks, the cars that drive (the patrol car and the
## fire engine, drawn over their own bodies on wheels that stay on the ground), the van that takes
## a victim, and the stationary wrecks and moving van.

func _draw_figure(canvas: CanvasItem) -> void:
	match event.def.look:
		EventDef.Look.DELIVERY_VAN:
			# Always sited facing east — `AT_THE_KERB` never overrides `EventScheduler.Planned.
			# facing`'s own default — and `delivery_van.svg` faces west, so `side_faces_west`
			# mirrors it (see `docs/evidence/svg-vehicles-2026-09-10/README.md`).
			_draw_eight_view(EventPictures.DELIVERY_VAN_BY_VIEW, event.facing_now(), canvas, true)
		EventDef.Look.FIRE_ENGINE:
			# Drawn over its own body like the patrol car (`_body_anchor()`): the body is the
			# truck's `shape`, and the shadow, which is that shape, stays under the node.
			var engine_view := _select_view(event.facing_now())
			_draw_body_shadow(canvas, Vector2(0.0, -current_bob()))
			_draw_eight_view(EventPictures.FIRE_ENGINE_BY_VIEW, event.facing_now(), canvas, true,
					{}, false,
					_body_anchor(engine_view))
		EventDef.Look.ICE_CREAM_VAN:
			# East-authored: always sited facing east, same as `DELIVERY_VAN` above,
			# but `ice_cream_van.svg` is one of the sources that already faces east, so no
			# `side_faces_west` override and no change to the picture it draws.
			_draw_eight_view(EventPictures.ICE_CREAM_VAN_BY_VIEW, event.facing_now(), canvas)
		EventDef.Look.LORRY:
			# `reversing_lorry`'s own facing is always exactly east or west — `AGAINST_THE_BUILDING`
			# sets it to `-pavement_inward`, which `_wants_this_side` already refuses unless it is
			# purely horizontal — so the diagonal and front/back views this table adds are never
			# actually reachable; the row draws its side view.
			_draw_eight_view(EventPictures.LORRY_BY_VIEW, event.facing_now(), canvas)
		EventDef.Look.POLICE_CAR:
			# East-authored — see `ICE_CREAM_VAN` above — and a real octant: `police_patrol` is
			# mobile and turns corners along its own patrol route, so its diagonal views are
			# ordinarily reachable. Drawn over its own body rather than standing on its node — see
			# `_body_anchor()` — with the shadow, which is the body's shape, under the node on the
			# ground.
			var view := _select_view(event.facing_now())
			_draw_body_shadow(canvas, Vector2(0.0, -current_bob()))
			_draw_eight_view(EventPictures.POLICE_CAR_BY_VIEW, event.facing_now(), canvas, false,
					{}, false,
					_body_anchor(view))
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
			_draw_stationary_vehicle(EventDef.Look.MOVING_VAN, event.def.obstructs_radius * 2.0,
					canvas)
		EventDef.Look.BURNT_OUT_CAR:
			_draw_stationary_vehicle(EventDef.Look.BURNT_OUT_CAR,
					event.def.obstructs_radius * 2.0, canvas)

## A stationary vehicle projected along the axis of the street it occupies. Its side silhouette
## may mirror with its facing; an end-on silhouette keeps its authored proportions and orientation.
## Its shadow is `def.shape` — a point for `burnt_out_car`, a capsule along the street for
## `moving_van`, whose `obstructs_radius` clears `GroundShape.BAND_RADIUS` — rather than a
## hand-picked radius of its own.
func _draw_stationary_vehicle(look: EventDef.Look, side_width: float,
		canvas: CanvasItem) -> void:
	var picture := EventPictures.stationary_vehicle_texture(look, event.stands_side_on())
	var extent := EventPictures.stationary_vehicle_extent(picture, event.stands_side_on(),
			side_width)
	_draw_body_shadow(canvas)
	Sprites.draw_standing(canvas, EventPictures.drawn(picture), Vector2.ZERO, extent,
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
## van's own `EventInstance.facing_now()` is `Planned.facing`'s untouched default, always due east —
## so the van's own `_select_view(event.facing_now())` call below, after the victim's, only ever
## asks for exactly the sector the victim's own call left it on (both facing the same way) or its
## exact opposite (180° apart, always past `EightDirection`'s hold), never anything a stale hold
## could get wrong.
func _draw_abduction(canvas: CanvasItem) -> void:
	if event.is_taking_a_victim():
		var through := event.abduction.walked_for() / event.def.abduction.taken_over
		var offset := event.def.abduction.standing_offset
		var standing := Vector2(-offset if _heading_is_west() else offset, 0.0)
		var at := standing.lerp(Vector2.ZERO, through)
		_draw_shadow(canvas, at, 8.0)
		# She faces the van, which is the only place she is walking to — a pure east/west direction
		# by construction (`standing` never has a Y component), so this always resolves to the same
		# side view `_heading_is_west()` picked before, now read off the shared table.
		var view := _select_view(-standing)
		var by_view := EventPictures.VAN_VICTIM_BY_VIEW_B if _victim_gait_stepping() \
				else EventPictures.VAN_VICTIM_BY_VIEW
		Sprites.draw_standing(canvas, EventPictures.drawn(by_view[view]), at, Vector2.ZERO,
				EightDirection.is_mirrored(_view_sector))
	# West-authored, like `delivery_van` and `fire_engine` above — see `_draw_eight_view()`'s own
	# doc comment on `side_faces_west`.
	_draw_eight_view(EventPictures.UNMARKED_VAN_BY_VIEW, event.facing_now(), canvas, true)
