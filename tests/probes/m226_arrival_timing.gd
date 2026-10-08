extends RefCounted
## M226's missing non-pursuer measurement. Run through tools/test.sh by this file's path.
## The identical collector runs on f494956e and the PR. It uses that revision's encounter
## factory, PendingWarning, EventInstance and real DangerEdge consumer. No placement bound
## participates in entry detection: drawing_parts() reads the selected sprite frame, wheel,
## shadow polygon, loose leash and live caret separately. See the retained evidence README.

const STEP := 1.0 / 60.0
const LIMIT := 30.0
const IDS := ["cyclist", "loose_dog", "fire_truck", "military_convoy"]

class Source extends Node:
	var live: Array[EventInstance] = []
	var warnings: Array[PendingWarning] = []
	func instances() -> Array[EventInstance]:
		return live
	func pending_warnings() -> Array[PendingWarning]:
		return warnings

func run(t) -> void:
	var factory: Object = load("res://tests/probes/m207_warning_lead.gd").new()
	var encounters: Array[Dictionary] = factory.encounters()
	# The engine can use either road axis; the column's actual main-road lane is vertical.
	for encounter: Dictionary in encounters.duplicate():
		var row: EventDef = encounter["def"]
		if row.id != "fire_truck":
			continue
		encounter["how"] += ", vertical"
		# Rotate the factory's (-48,150) kerb and southbound travel through a quarter turn.
		var kerb := Vector2(-150.0, -Tuning.TILE_SIZE * 1.5)
		var where := func(her: Vector2) -> Vector2:
			return PendingWarning.on_its_route(row, her, kerb, Vector2.LEFT, 4000.0)
		var route := func(place: Vector2, _her: Vector2) -> PackedVector2Array:
			return PackedVector2Array([place, kerb])
		encounters.append(factory._warned(row, "warned, on its road to the fire, horizontal",
				where, route, Vector2.RIGHT))
	print("| row | geometry | answer | badge start | created | drawn entry | badge removed | entry minus creation |")
	print("|---|---|---|---|---|---|---|---|")
	var count := 0
	for encounter: Dictionary in encounters:
		var def: EventDef = encounter["def"]
		if def.id not in IDS or (def.id == "military_convoy" and not encounter.get("warned", false)):
			continue
		var variants := [false, true] if def.id == "cyclist" else [false]
		for pelican: bool in variants:
			for answer in 3:
				var row := collect(t, encounter, answer, pelican)
				print("| %s | %s | %s | %s | %s | %s | %s | %s |" % [
						"pelican" if pelican else def.id, encounter["how"],
						["toward", "standing", "away"][answer], seconds(row.badge_start),
						seconds(row.created), seconds(row.entry), seconds(row.badge_removed),
						seconds(float(row.entry) - float(row.created)) if row.entry != INF else "never"])
				t.check(row.created != INF, "arrival collector actually creates %s" % def.id)
				count += 1
	t.check(count == 27, "both variants, both road axes and the vertical column cover 27 encounters")

static func seconds(value: float) -> String:
	return "—" if not is_finite(value) else "%.3f" % value

static func collect(t: Node, encounter: Dictionary, answer: int, pelican: bool) -> Dictionary:
	var def: EventDef = encounter["def"]
	var her: Vector2 = encounter["her"]
	var heading: Vector2 = encounter["heading"]
	var velocity: Vector2 = heading * Tuning.WALK_SPEED * [1.0, 0.0, -1.0][answer]
	var source := Source.new()
	t.add_child(source)
	var player := Node2D.new()
	t.add_child(player)
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.size = Vector2(1280.0, 720.0)
	edge.setup(source, player)
	var viewport := t.get_viewport()
	var saved_transform := viewport.canvas_transform
	var result := {"badge_start": INF, "created": INF, "entry": INF, "badge_removed": INF}
	var clock := 0.0
	var arrive := func(place: Vector2, at: Vector2) -> bool:
		var route: PackedVector2Array = encounter["route"].call(place, at)
		var instance := EventInstance.new()
		instance.setup(def, place, route)
		instance.came_under_a_warning = true
		instance.is_pelican = pelican
		# f494956e spends telegraph_time; the current game preserves a pulsing row's beat.
		var manager: GDScript = load("res://src/events/event_manager.gd")
		var age: float = manager.age_when_warned(def) if manager.has_method("age_when_warned") \
				else def.telegraph_time
		instance.resume(age, 0.0)
		source.add_child(instance)
		source.live.append(instance)
		return true
	if encounter.get("warned", false):
		var warning := PendingWarning.new(def, encounter["where"], arrive)
		warning.is_pelican = pelican
		var accepted: bool = warning.call("put_up" if warning.has_method("put_up") else "follow", her)
		if accepted:
			source.warnings.append(warning)
	else:
		var route: PackedVector2Array = encounter["path"]
		var instance := EventInstance.new()
		instance.setup(def, route[0], route)
		instance.resume(float(encounter.get("age", 0.0)), 0.0)
		source.add_child(instance)
		source.live.append(instance)
		result.created = 0.0
	var had_badge := false
	while clock <= LIMIT:
		player.position = her
		viewport.canvas_transform = Transform2D(Vector2(2.0, 0.0), Vector2(0.0, 2.0),
				Vector2(640.0, 360.0) - her * 2.0)
		for instance in source.live:
			instance.player_at = her
			if result.created == INF:
				result.created = clock
			if result.entry == INF:
				var view := Rect2(her - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
				for part in drawing_parts(instance):
					if view.intersects(Rect2(instance.position + part.position, part.size)):
						result.entry = clock
		edge._measure(STEP)
		var badged := not edge.announcing().is_empty()
		if badged and result.badge_start == INF:
			result.badge_start = clock
		if had_badge and not badged and result.badge_removed == INF:
			result.badge_removed = clock
		had_badge = badged
		if result.entry != INF and (result.badge_removed != INF or result.badge_start == INF):
			break
		her += velocity * STEP
		clock += STEP
		# Existing instances move first; a callback creates the new one for this frame's observation.
		for instance in source.live:
			instance.player_at = her
			instance._process(STEP)
		for warning in source.warnings.duplicate():
			if warning.tick(STEP, her):
				source.warnings.erase(warning)
	viewport.canvas_transform = saved_transform
	edge.free()
	player.free()
	source.free()
	return result

## Drawing geometry for precisely this probe's four looks. Reads the same selected frame and
## native texture size as _draw_eight_view/_draw_loose_dog, never footprint_of/drawn_box.
## Texture quads include transparent padding; this is geometric entry, not pixel-alpha sampling.
## No halo is enabled in the isolated encounter. Each primitive is tested separately, so empty
## space between a tall caret and a body cannot count as an entry.
static func drawing_parts(instance: EventInstance) -> Array[Rect2]:
	var parts: Array[Rect2] = []
	var def := instance.def
	var view: String = instance._select_view(instance._heading)
	var bob: float = instance._current_bob()
	var picture := ""
	match def.look:
		EventDef.Look.CYCLIST:
			var rider := instance.rider_pictures()
			picture = rider[1 if instance._gait_stepping() else 0][view]
		EventDef.Look.LOOSE_DOG:
			picture = instance.dog_picture(view, instance._gait_stepping(), instance._gait_second_half())
			# Both revisions' _draw_loose_dog draws this 26px trailing, 2px-wide line.
			var behind := 26.0 if instance._heading_is_west() else -26.0
			parts.append(Rect2(minf(behind, 0.0) - 1.0, -9.0 + bob, absf(behind) + 2.0, 8.0))
		EventDef.Look.FIRE_ENGINE:
			picture = instance.FIRE_ENGINE_BY_VIEW[view]
		EventDef.Look.ARMY_TRUCK:
			picture = instance.ARMY_TRUCK_BY_VIEW[view]
		EventDef.Look.CHARGING_DOG:
			picture = (instance.CHARGING_DOG_BY_VIEW_B if instance._gait_stepping()
					else instance.CHARGING_DOG_BY_VIEW)[view]
		_:
			assert(false, "arrival collector has no drawing observer for this look")
	parts.append(_picture_rect(instance, picture, bob))
	var wheels: Dictionary = instance.WHEELS_BY_LOOK.get(def.look, {})
	if not wheels.is_empty():
		parts.append(_picture_rect(instance, wheels[view], 0.0))
	if def.draws_body_shadow:
		for piece in def.parts():
			var points: PackedVector2Array = piece.shape.shadow_outline(Vector2.ZERO)
			var shadow := Rect2(points[0], Vector2.ZERO)
			for point in points:
				shadow = shadow.expand(point)
			shadow.position.y += 0.0 if not wheels.is_empty() else bob
			parts.append(shadow)
	if instance.wants_a_mark() and not (instance.is_telegraphing() \
			and fmod(instance.age * instance.MARK_FLASHES_PER_SECOND, 1.0) > 0.55):
		var swell: float = instance.mark_swell()
		var width: float = instance.MARK_WIDTH * (0.55 + 0.45 * swell)
		var at: float = -(instance.MARK_HEIGHT + 10.0 * swell)
		for mark in (2 if instance._caret_strength() == 2 else 1):
			parts.append(Rect2(-width - 1.0, at - width * 0.8 - 1.0,
					width * 2.0 + 2.0, width * 1.3 + 2.0))
			at -= width * 0.85
	return parts

static func _picture_rect(instance: EventInstance, picture: String, bob: float) -> Rect2:
	var size: Vector2 = instance._native_size(picture)
	return Rect2(-size.x * 0.5, -size.y + bob, size.x, size.y)
