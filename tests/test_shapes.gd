extends RefCounted
## `GroundShape`: the datum a shadow and a solid body are both derived from — M61, "one shape per
## object". `reach()`, `across()` and `distance_to_spine()` over a point and a segment;
## `collision_shape()`'s two resource types; and the invariant every obstructing catalogue row now
## carries, `shape.reach() == obstructs_radius`, checked over the whole catalogue, every heated
## copy of every row, and every seal candidate's `sealed_variant()`.

func run(t) -> void:
	_test_reach_and_across(t)
	_test_distance_to_spine_of_a_point(t)
	_test_distance_to_spine_of_a_segment(t)
	_test_collision_shape_types_and_sizes(t)
	_test_band_reduces_to_a_point_under_its_own_radius(t)
	_test_every_catalogue_row_agrees_with_its_shape(t)
	_test_every_heated_copy_agrees_with_its_shape(t)
	_test_every_seal_candidate_agrees_with_its_shape(t)
	_test_every_spread_row_still_fills_the_pavement_it_blocked(t)
	_test_a_hard_seal_capsule_spans_the_street_not_the_kerb(t)

# ------------------------------------------------------------------ the datum ---

func _test_reach_and_across(t) -> void:
	var point := GroundShape.point(9.0)
	t.check(is_equal_approx(point.reach(), 9.0), "a point's reach is its own radius")
	t.check(is_equal_approx(point.across(), 9.0), "a point's across is its own radius too")

	var segment := GroundShape.segment(12.0, 5.0)
	t.check(is_equal_approx(segment.reach(), 17.0),
			"a segment's reach is half_length + radius (12 + 5)")
	t.check(is_equal_approx(segment.across(), 5.0),
			"a segment's across is its radius alone, not its half_length")

func _test_distance_to_spine_of_a_point(t) -> void:
	var shape := GroundShape.point(6.0)
	t.check(is_equal_approx(shape.distance_to_spine(Vector2.ZERO), 0.0),
			"on a point's own spine (the origin) is zero")
	t.check(is_equal_approx(shape.distance_to_spine(Vector2(3.0, 4.0)), 5.0),
			"off it is the plain Euclidean distance, whatever the shape's own radius is")

func _test_distance_to_spine_of_a_segment(t) -> void:
	var shape := GroundShape.segment(10.0, 3.0)
	t.check(is_equal_approx(shape.distance_to_spine(Vector2(5.0, 0.0)), 0.0),
			"on the spine, between its ends, is zero")
	t.check(is_equal_approx(shape.distance_to_spine(Vector2(-10.0, 0.0)), 0.0),
			"on the spine, at an end, is zero too")
	t.check(is_equal_approx(shape.distance_to_spine(Vector2(0.0, 7.0)), 7.0),
			"beside the middle is the perpendicular distance to the spine")
	t.check(is_equal_approx(shape.distance_to_spine(Vector2(15.0, 4.0)), Vector2(15.0, 4.0)
					.distance_to(Vector2(10.0, 0.0))),
			"past an end is the Euclidean distance to that end, not to the line through the spine")

func _test_collision_shape_types_and_sizes(t) -> void:
	var point_shape := GroundShape.point(8.0).collision_shape()
	t.check(point_shape is CircleShape2D, "a point shape's collision resource is a CircleShape2D")
	t.check(is_equal_approx((point_shape as CircleShape2D).radius, 8.0),
			"and its radius is the shape's own radius")

	var segment_shape := GroundShape.segment(9.0, 4.0).collision_shape()
	t.check(segment_shape is CapsuleShape2D, "a segment shape's collision resource is a CapsuleShape2D")
	var capsule := segment_shape as CapsuleShape2D
	t.check(is_equal_approx(capsule.radius, 4.0), "the capsule's radius is the shape's own radius")
	t.check(is_equal_approx(capsule.height, 26.0),
			"and its height is 2 * reach() (2 * 13), the full length end to end")

func _test_band_reduces_to_a_point_under_its_own_radius(t) -> void:
	var wide := GroundShape.band(60.0)
	t.check(wide.half_length > 0.0, "a band wider than BAND_RADIUS is a real segment")
	t.check(is_equal_approx(wide.reach(), 60.0), "and its reach is exactly what it was asked for")

	var narrow := GroundShape.band(20.0)
	t.check(narrow.half_length <= 0.0,
			"a band at or under BAND_RADIUS has no spine to be a capsule about — a point instead")
	t.check(is_equal_approx(narrow.reach(), 20.0), "still reaching exactly what it was asked for")

	var boundary := GroundShape.band(GroundShape.BAND_RADIUS)
	t.check(boundary.half_length <= 0.0,
			"exactly BAND_RADIUS is the boundary case and reduces to a point too")

# ------------------------------------------------------- the catalogue invariant ---
# `EventDef.validate()` already checks this on load and `EventCatalogue.all()` calls it over every
# heated shape of every row — so a broken invariant fails `check.sh`, not only this suite. These
# tests hold the same rule directly, over the shapes themselves, so a failure here says which row
# and which copy rather than only that validation failed somewhere.

func _shape_agrees(def: EventDef) -> bool:
	if def.obstructs_radius <= 0.0:
		return true
	return def.shape != null and is_equal_approx(def.shape.reach(), def.obstructs_radius)

func _test_every_catalogue_row_agrees_with_its_shape(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.look != EventDef.Look.NONE:
			t.check(def.shape != null, "'%s' has a look and carries a shape" % def.id)
		if def.obstructs_radius > 0.0:
			checked += 1
			t.check(_shape_agrees(def),
					"'%s' obstructs %.1fpx and its shape reaches %.1fpx: they agree"
					% [def.id, def.obstructs_radius,
							def.shape.reach() if def.shape else -1.0])
	t.check(checked >= 20, "and most of the catalogue actually obstructs (%d rows)" % checked)

func _test_every_heated_copy_agrees_with_its_shape(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		for level in EventCatalogue.heat_levels():
			var hot := EventCatalogue.heated(def, level)
			checked += 1
			if hot.look != EventDef.Look.NONE:
				t.check(hot.shape != null,
						"'%s' at heat %d has a look and carries a shape" % [def.id, level])
			t.check(_shape_agrees(hot),
					"'%s' at heat %d: obstructs %.1fpx, shape reaches %.1fpx"
					% [def.id, level, hot.obstructs_radius,
							hot.shape.reach() if hot.shape else -1.0])
	t.check(checked > EventCatalogue.all().size(), "every row was checked at every heat level")

func _test_every_seal_candidate_agrees_with_its_shape(t) -> void:
	var checked := 0
	for candidate in SealPlanner.candidates():
		for id in candidate.def_ids:
			var def := EventCatalogue.by_id(id)
			t.check(def != null, "seal candidate '%s' names a real catalogue row" % id)
			var sealed := SealPlanner.sealed_variant(def, candidate.strength == SealPlanner.Strength.HARD)
			checked += 1
			t.check(sealed.shape != null, "'%s' sealed for '%s' carries a shape" % [id, candidate.id])
			t.check(_shape_agrees(sealed),
					"'%s' sealed for '%s': obstructs %.1fpx, shape reaches %.1fpx"
					% [id, candidate.id, sealed.obstructs_radius,
							sealed.shape.reach() if sealed.shape else -1.0])
	t.check(checked >= 6, "and the seal candidate list was actually walked (%d checks)" % checked)

# --------------------------------------------------------- the pavement guarantee ---
# The same rows `tests/test_events.gd`'s `_test_a_spread_body_fits_the_ground_it_stands_on` checks
# against a whole tile, checked here against the narrower question this slice changes: a capsule's
# `across()` is its own half-thickness, which is what a pavement actually has to clear now that the
# body is not a disc.

const _SPREAD_LOOKS: Array[EventDef.Look] = [
	EventDef.Look.ROADWORKS, EventDef.Look.STALL, EventDef.Look.ROADBLOCK,
	EventDef.Look.BARRICADE, EventDef.Look.BURNT_SHELL, EventDef.Look.CAFE,
	EventDef.Look.PROTEST, EventDef.Look.FIREFIGHT,
	EventDef.Look.FALLEN_TREE, EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN,
	EventDef.Look.SCAFFOLDING, EventDef.Look.COLLAPSED_FRONTAGE,
]

func _test_every_spread_row_still_fills_the_pavement_it_blocked(t) -> void:
	var half_band := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 0.5
	var checked := 0
	for def in EventCatalogue.all():
		if not _SPREAD_LOOKS.has(def.look):
			continue
		var blocked_before := def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS > half_band
		if not blocked_before:
			continue
		checked += 1
		t.check(def.shape.across() + Tuning.PLAYER_BODY_RADIUS > half_band,
				("'%s' blocked the whole %.0fpx pavement band as a disc (%.0fpx + her %.0fpx); "
						% [def.id, half_band * 2.0, def.obstructs_radius, Tuning.PLAYER_BODY_RADIUS])
				+ ("its capsule (%.0fpx across + her %.0fpx) still does" % [def.shape.across(),
						Tuning.PLAYER_BODY_RADIUS]))
	t.check(checked >= 6, "and some spread row actually blocked a pavement to check (%d)" % checked)

# ------------------------------------------------------------- the hard-seal axis ---
# `SealPlanner._hard_positions` spaces a hard seal's bodies to cover a street's whole width with no
# gap, treating each body's own reach as the distance it covers *across* the street — `positions_
# across()`'s own `width` is the street's kerb-to-kerb measurement, not its length. That packing
# arithmetic is only true of a capsule if the capsule's own spine (the long axis, `reach()`) lies
# across the street too: a capsule laid the other way round reaches `across()` (24px,
# `GroundShape.BAND_RADIUS`) toward each kerb rather than `reach()`, and a hard seal stops being
# hard at exactly the kerbs nothing here would have caught. So this is the one fact the whole
# hard-seal guarantee rests on, checked directly against a real `EventInstance` on a real street of
# each orientation, rather than trusted from `_spread_is_vertical`'s own reasoning.

const _HARD_SEAL_SEED := 424242

func _real_segment(map: CityMap, horizontal: bool) -> StreetNetwork.Segment:
	for segment in StreetNetwork.segments():
		if segment.horizontal == horizontal and map.has_street(segment.key()):
			return segment
	return null

## The street's own along-axis in world space: local X for a horizontal (east-west) street, local
## Y for a north-south one — `StreetNetwork.Segment.horizontal`'s own meaning, read off
## `tile_rect()`'s shape in `street_network.gd` (wide in X for horizontal, wide in Y otherwise).
func _along_axis(segment: StreetNetwork.Segment) -> Vector2:
	return Vector2.RIGHT if segment.horizontal else Vector2.DOWN

func _test_a_hard_seal_capsule_spans_the_street_not_the_kerb(t) -> void:
	var map := CityGenerator.generate(_HARD_SEAL_SEED)
	var def := EventCatalogue.by_id("barricade")
	t.check(def != null and def.shape != null and def.shape.half_length > 0.0,
			"'barricade' is a hard seal row whose shape is a real segment, not a point")
	for horizontal in [true, false]:
		var segment := _real_segment(map, horizontal)
		t.check(segment != null,
				"the map has a real %s street to check" % ("horizontal" if horizontal else "vertical"))
		if not segment:
			continue
		var positions := SealPlanner._hard_positions(map, segment, def)
		t.check(positions.size() > 0, "the seal places at least one body on this street")
		if positions.is_empty():
			continue
		var instance := EventInstance.new()
		instance.setup(def, positions[0], PackedVector2Array(), Vector2.RIGHT, map)
		t.add_child(instance)
		instance.set_process(false)

		var along := _along_axis(segment)
		var axis := instance._solid_axis()
		var street_kind := "horizontal" if horizontal else "vertical"
		t.check(absf(axis.dot(along)) < 0.05,
				("on a %s street, _solid_axis() (%s) is perpendicular to the street's own "
						% [street_kind, axis])
				+ ("direction (%s), not parallel to it — dot %.3f" % [along, axis.dot(along)]))

		t.check(instance.is_solid(), "the hard seal placement actually builds a body")
		var collision := instance._obstruction.get_child(0) as CollisionShape2D
		t.check(collision != null and collision.shape is CapsuleShape2D,
				"'barricade's built body is a CapsuleShape2D, not a CircleShape2D")
		if collision and collision.shape is CapsuleShape2D:
			# A capsule's own long axis stands along local Y before any rotation is applied —
			# `GroundShape.collision_shape()`'s own docstring — so rotating `Vector2.DOWN` by the
			# body's `rotation` gives the capsule's actual spine direction in world space; it must
			# line up with `_solid_axis()` (parallel or anti-parallel, since a capsule is symmetric
			# end to end), not merely be perpendicular to it.
			var spine := Vector2.DOWN.rotated(collision.rotation)
			t.check(absf(spine.dot(axis)) > 0.95,
					("on a %s street, the built capsule's own spine (%s) matches _solid_axis() (%s)"
							% [street_kind, spine, axis]))
		instance.free()
