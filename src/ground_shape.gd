class_name GroundShape
extends RefCounted
## One ground-plane shape for an object, independent of its picture — the datum the shadow and
## the collision body are both derived from. See docs/TODO.md, M61, "one shape per object", and
## docs/EVENTS.md, "Solid things are solid".
##
## A shape is a **spine** plus a **radius**: the spine is either a point or a segment of
## `half_length` along local +X, and `radius` is the rounding around it. That gives a disc (point
## spine) and a capsule (segment spine). **A third kind, a rectangle, exists only because a
## building's footprint is one** — `half_extents`, an axis-aligned box in the object's own frame —
## and nothing else in the game uses it: every other obstructing thing reduces to a point or a
## band, which is why `band()` below still hands out only those two. There is still no polygon.
##
## **The excitement field is the Minkowski sum of this datum and a kernel** — `field_distance()`
## and `field_outline()` below, read by `EventInstance.contribution_at()`,
## `CrowdAgent.contribution_at()` and the debug view's fields layer. A disc kernel for a stationary
## body (`distance_to_spine()`, the ordinary case) and an ellipse for a moving one
## (`eccentric_distance()`, eccentricity from speed) are the only two kernels built: nobody
## computes the general capsule-and-ellipse sum, because every emitting segment row in the
## catalogue is stationary and everything that moves is small enough to be a point. See
## docs/EVENTS.md, "The emission model".

## Which of the three kinds this shape is. A point and a segment could still be told apart by
## `half_length` being positive, the way this file did before the rectangle existed, but a
## rectangle needs its own tag — nothing about `half_extents` alone says "this is the field in use"
## the way a positive `half_length` does for a segment.
enum Kind { POINT, SEGMENT, RECT }

var kind := Kind.POINT
## The spine's half-length along local +X. Zero for a point or a rectangle.
var half_length := 0.0
## The rounding around the spine — the shape's half-thickness perpendicular to it. Zero for a
## rectangle, whose own half-thickness is the smaller of `half_extents`.
var radius := 0.0
## Half-width and half-depth of a rectangle, in the object's own frame, local X by local Y. Zero
## for a point or a segment.
var half_extents := Vector2.ZERO

func _init(half_length_in: float, radius_in: float) -> void:
	half_length = half_length_in
	radius = radius_in

## A point shape: the disc every stationary point object in the game already draws and collides
## as.
static func point(radius_in: float) -> GroundShape:
	var shape := GroundShape.new(0.0, radius_in)
	shape.kind = Kind.POINT
	return shape

## A segment shape: a spine of `half_length_in` along local +X, rounded by `radius_in` — the
## capsule a spread-drawn row or a wide vehicle reduces to.
static func segment(half_length_in: float, radius_in: float) -> GroundShape:
	var shape := GroundShape.new(half_length_in, radius_in)
	shape.kind = Kind.SEGMENT
	return shape

## A rectangle shape: `half_extents_in` in the object's own frame — a building's footprint, halved.
## The only caller today is `Building`; nothing else in the game has a footprint that is not
## already a point or a band.
static func rect(half_extents_in: Vector2) -> GroundShape:
	var shape := GroundShape.new(0.0, 0.0)
	shape.kind = Kind.RECT
	shape.half_extents = half_extents_in
	return shape

## The fixed rounding a spread-drawn or stationary-vehicle row's segment carries, whatever its own
## reach — see `band()`. **Both halves of why 24, together**: a 48px-thick band on a 64px
## pavement band leaves 8px a side, under her 14px `Tuning.PLAYER_BODY_RADIUS`, so every pavement
## a band blocks today stays blocked; and a capsule of a given reach lies entirely inside the disc
## of the same reach it replaces (a capsule's every point is within `reach()` of its own centre,
## same as a circle's), so every reachability guarantee stated over `obstructs_radius` as a disc
## radius holds for the capsule by inclusion.
const BAND_RADIUS := 24.0

## The shape a row whose silhouette's total reach along its own long axis is `reach` reduces to:
## a segment of `BAND_RADIUS` rounding once there is enough of it to have a spine at all, and
## otherwise simply a point of `reach` — "nothing changes" for a row too narrow to be a band in
## the first place. See `BAND_RADIUS` for why 24 is the fixed rounding rather than a per-row
## number.
static func band(reach: float) -> GroundShape:
	if reach > BAND_RADIUS:
		return GroundShape.segment(reach - BAND_RADIUS, BAND_RADIUS)
	return GroundShape.point(reach)

## The furthest any point of the shape lies from its own origin — the worst axis a planner has to
## clear, and the number every disc-shaped guarantee in the game (`obstructs_radius`, a lethal
## radius, a park's obstruction allowance) is stated over. A rectangle's is its half-diagonal, the
## corner rather than an edge.
func reach() -> float:
	if kind == Kind.RECT:
		return half_extents.length()
	return half_length + radius

## The half-thickness perpendicular to the spine — the shape's narrow axis, and the one a spread
## body is measured against when it has to fit a pavement band rather than merely reach across it.
## A rectangle's is its smaller half-extent.
func across() -> float:
	if kind == Kind.RECT:
		return minf(half_extents.x, half_extents.y)
	return radius

## Distance from a local point to the spine: zero on the spine itself, the perpendicular distance
## beside a segment's middle, and the Euclidean distance to the nearer end once `local` is past
## it. Zero for a point shape, whose spine is the origin. Zero anywhere inside a rectangle, and the
## ordinary point-to-box distance outside it. What `field_distance()` below prices a stationary
## emitter's field over — a point body's field is exactly the circle this always gave, and a
## segment's is the capsule it always gave, `inner_radius`/`outer_radius` now meaning distance from
## the spine rather than from the centre.
func distance_to_spine(local: Vector2) -> float:
	match kind:
		Kind.RECT:
			var dx := maxf(absf(local.x) - half_extents.x, 0.0)
			var dy := maxf(absf(local.y) - half_extents.y, 0.0)
			return Vector2(dx, dy).length()
		Kind.SEGMENT:
			var clamped_x := clampf(local.x, -half_length, half_length)
			return local.distance_to(Vector2(clamped_x, 0.0))
		_:
			return local.length()

# ---------------------------------------------------------------------- the field ---
# The excitement field is `body ⊕ kernel` — this shape (the body) offset outward by a disc
# standing still or an ellipse moving, eccentricity from speed. See docs/EVENTS.md, "The emission
# model", and docs/MECHANICS.md, "Excitement falloff".

## The distance `Tuning.falloff()` prices this shape's field at, from `at` (its own centre, in
## world space) to `point`, given the emitter's current `velocity` — zero for a stationary body, in
## which case this is `distance_to_spine()` in the shape's own frame (rotated by `axis`, the same
## one the shadow and the collision body use): a point body's field is the circle it always was,
## and a segment's is a capsule about the spine. Nonzero, and the body is set aside — **moving
## objects are points** (see the class doc) — and this is `eccentric_distance()` instead, the
## emitter itself at one focus of an ellipse rather than at its centre.
func field_distance(at: Vector2, axis: Vector2, velocity: Vector2, point: Vector2) -> float:
	if velocity.is_zero_approx():
		return distance_to_spine((point - at).rotated(-axis.angle()))
	return eccentric_distance(at, velocity, point)

## The effective distance under a moving emitter's own field: a conic with its **focus at `from`**
## — *"the entity itself lives in one of the focus points"* — rather than its centre, so the field
## reaches further ahead of the emitter than behind it. `e` is `Tuning.field_eccentricity()` of
## `velocity`'s own speed; `θ` is the angle between `velocity` and the vector to `point`.
##
## **The resting disc's own width is what the ellipse keeps** — *"the stretching should retain
## the area so an unstretched car field should be the same width with shorter height", "if anything
## the moving size should be bigger than the rest size"* — so the boundary at level `R` is
## `r(θ) = R / (1 − e·cosθ)`: exactly `R` abeam (`θ = π/2`) whatever the speed, `R · Tuning.
## field_scale(e)` (`R/(1−e)`) dead ahead, `R/(1+e)` behind. Inverting that for the level a given
## `r` sits on: `d_eff = r · (1 − e·cosθ)`, with no `field_scale()` term of its own — the growth
## `field_scale()` gives the boundary is exactly what cancels out of its own inverse, which is why
## only `_eccentric_field_outline()` below calls it directly. Zero `velocity` (or a `point` sitting
## on `from`) falls back to the plain Euclidean distance a disc always used.
static func eccentric_distance(from: Vector2, velocity: Vector2, point: Vector2) -> float:
	if velocity.is_zero_approx():
		return from.distance_to(point)
	var to_point := point - from
	var r := to_point.length()
	if is_zero_approx(r):
		return 0.0
	var e := Tuning.field_eccentricity(velocity.length())
	var cos_theta := velocity.normalized().dot(to_point) / r
	return r * (1.0 - e * cos_theta)

## The level set `field_distance()` reaches `level` at — the actual boundary `Tuning.falloff()`
## draws for this shape, read by the debug view's fields layer (`DebugLayers`, see
## docs/TELEMETRY.md, "The debug view") so a screenshot cannot disagree with the arithmetic. Same
## split as `field_distance()`: stationary is this shape's own boundary (a circle for a point, a
## stadium for a segment, both at radius `level`); moving sets the shape aside and traces the polar
## ellipse `eccentric_distance()` inverts, focus at `at`, abeam reach `level` and forward reach
## `level · Tuning.field_scale(e)` along `velocity`.
func field_outline(at: Vector2, axis: Vector2, velocity: Vector2, level: float,
		samples: int = _ELLIPSE_SAMPLES) -> PackedVector2Array:
	if not velocity.is_zero_approx():
		return _eccentric_field_outline(at, velocity, level, samples)
	if kind == Kind.SEGMENT:
		return _stadium_field_outline(at, axis, level, samples)
	return _circle_field_outline(at, level, samples)

## The field boundary for a point or a moving emitter at `at`, without a body of its own to be
## offset by — the shape `DebugLayers` reads for a crowd agent (always a point in field terms) and
## for one bird of a flock (its own position, its own velocity), neither of which owns a
## `GroundShape` worth asking.
static func field_outline_at(at: Vector2, velocity: Vector2, level: float,
		samples: int = _ELLIPSE_SAMPLES) -> PackedVector2Array:
	return GroundShape.point(0.0).field_outline(at, Vector2.RIGHT, velocity, level, samples)

func _circle_field_outline(centre: Vector2, level: float, samples: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in samples:
		var angle := TAU * float(i) / float(samples)
		points.append(centre + Vector2(cos(angle), sin(angle)) * level)
	return points

## A stadium at radius `level` about this shape's own spine — the same two-cap-and-two-sides
## construction `DebugLayers._capsule_outline` draws for a body, at the field's `level` instead of
## the body's own `radius`.
func _stadium_field_outline(at: Vector2, axis: Vector2, level: float, samples: int
		) -> PackedVector2Array:
	var along := axis.normalized()
	var base := along.angle()
	var lead := at + along * half_length
	var trail := at - along * half_length
	var half_samples := maxi(2, samples / 2)
	var points := PackedVector2Array()
	for i in half_samples + 1:
		var a := base - PI * 0.5 + PI * float(i) / float(half_samples)
		points.append(lead + Vector2(cos(a), sin(a)) * level)
	for i in half_samples + 1:
		var a := base + PI * 0.5 + PI * float(i) / float(half_samples)
		points.append(trail + Vector2(cos(a), sin(a)) * level)
	return points

## The polar ellipse `eccentric_distance()` inverts: `r(θ) = level / (1 − e·cosθ)`, sampled at
## `samples` angles `θ` around `velocity`'s own heading, so the drawn boundary is the exact level
## set the falloff prices rather than a circle standing in for it. `level · Tuning.field_scale(e)`
## is the conic's own scale `L(e) = R/(1−e)` — see that function's docstring — so the boundary holds
## `level` exactly abeam at every speed and reaches `level · field_scale(e)` dead ahead.
func _eccentric_field_outline(at: Vector2, velocity: Vector2, level: float, samples: int
		) -> PackedVector2Array:
	var e := Tuning.field_eccentricity(velocity.length())
	var l := level * Tuning.field_scale(e)
	var heading_angle := velocity.angle()
	var points := PackedVector2Array()
	for i in samples:
		var theta := TAU * float(i) / float(samples)
		var r := l * (1.0 - e) / (1.0 - e * cos(theta))
		var world_angle := heading_angle + theta
		points.append(at + Vector2(cos(world_angle), sin(world_angle)) * r)
	return points

## This shape's own collision resource: a `CircleShape2D` for a point, a `CapsuleShape2D`
## (`radius`, `height = 2 * reach()`) for a segment, a `RectangleShape2D` (`size = 2 *
## half_extents`) for a rectangle.
##
## **Godot's capsule stands along local Y.** A caller that wants this shape's segment lying along
## its own local X — the axis every other method here treats as "along the spine" — has to rotate
## the `CollisionShape2D` it hangs this off by `+90°`, or more generally by the spine's own axis
## angle minus 90° when that axis is not X itself. A rectangle's own X/Y are already the frame it
## was built in, so nothing analogous applies to it — `Building` never rotates its own body.
func collision_shape() -> Shape2D:
	match kind:
		Kind.POINT:
			var circle := CircleShape2D.new()
			circle.radius = radius
			return circle
		Kind.RECT:
			var rectangle := RectangleShape2D.new()
			rectangle.size = half_extents * 2.0
			return rectangle
		_:
			var capsule := CapsuleShape2D.new()
			capsule.radius = radius
			capsule.height = 2.0 * reach()
			return capsule

## The ground-plane squash every point contact shadow in the game already draws with: the oblique
## view's own foreshortening of a shadow lying flat on the ground, not a per-object choice —
## `Sprites.draw_shadow`'s point ellipse (`radius` wide, `radius * SHADOW_SQUASH` tall) is this
## same number, unchanged from before this shape existed.
const SHADOW_SQUASH := 0.4

const _ELLIPSE_SAMPLES := 28

## The polygon `draw_shadow()` fills, at `at` in `canvas`'s own coordinates — pulled out so the
## debug view's shadow layer (`DebugLayers`, see docs/TODO.md, M104) can trace exactly the ground
## extent a shadow is drawn over, from the same call `draw_shadow()` itself now makes, rather than
## a second copy of this geometry the two could drift apart from.
##
## For a point this is exactly the contact-shadow ellipse every point object in the game already
## casts, so every point shadow is visually unchanged by this shape existing. For a segment, the
## spine is rotated by `axis` **on the ground plane, unsquashed** — the ground itself is drawn
## 1:1, tiles are square, so there is no foreshortening to apply to a direction lying flat on it —
## an ellipse is placed at each end, and the convex hull of the two ellipses' outlines is the
## result: a north-south band therefore gets a tall thin shadow spanning its whole length, rather
## than the single oval every shape stood on before this. For a rectangle, the four corners are
## rotated by `axis` the same way the segment's spine is, and **then** squashed on Y by
## `SHADOW_SQUASH` — the point case's own foreshortening, applied after the rotation rather than to
## the rectangle's own local frame, so a rectangle turned to face `axis` still reads as lying flat
## in the same oblique view every other shadow does.
func shadow_outline(at: Vector2, axis: Vector2 = Vector2.RIGHT) -> PackedVector2Array:
	match kind:
		Kind.POINT:
			return _squashed_ellipse_points(at)
		Kind.RECT:
			return _rect_points(at, axis)
		_:
			var along := axis.normalized()
			var points := PackedVector2Array()
			points.append_array(_ellipse_points(at + along * half_length))
			points.append_array(_ellipse_points(at - along * half_length))
			return Geometry2D.convex_hull(points)

## Draws this shape's shadow at `at`, in `canvas`'s own coordinates — the filled polygon
## `shadow_outline()` traces, so the layer and the shadow cannot disagree about what shape it is.
##
## A shadow narrower than a pixel is not drawn at all. A radius that has shrunk toward zero — a
## bird's contact shadow fading as it climbs to `BIRD_SHADOW_CEILING`, anything else that scales a
## shadow away — collapses every sample of the outline onto one point, and the renderer refuses
## the polygon with "Invalid polygon data, triangulation failed" once a frame for as long as it
## lasts. Nothing is lost by skipping it: it would have covered no pixel.
func draw_shadow(canvas: CanvasItem, at: Vector2, axis: Vector2 = Vector2.RIGHT) -> void:
	if radius < MIN_DRAWN_SHADOW_RADIUS:
		return
	canvas.draw_colored_polygon(shadow_outline(at, axis), Palette.SHADOW)

## Half a pixel: below this every sample of the outline rounds onto the same point.
const MIN_DRAWN_SHADOW_RADIUS := 0.5

func _ellipse_points(centre: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in _ELLIPSE_SAMPLES:
		var angle := TAU * float(i) / float(_ELLIPSE_SAMPLES)
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	return points

## The same circle, squashed on Y by `SHADOW_SQUASH` around `centre` — the point case's own
## foreshortening, folded into the points themselves (`shadow_outline()` used to apply it as a
## canvas transform around a plain `draw_circle`) so it can hand back world-space points instead of
## making a draw call.
func _squashed_ellipse_points(centre: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in _ELLIPSE_SAMPLES:
		var angle := TAU * float(i) / float(_ELLIPSE_SAMPLES)
		points.append(centre + Vector2(cos(angle) * radius, sin(angle) * radius * SHADOW_SQUASH))
	return points

## The rectangle's four corners, rotated by `axis` about `at` and then squashed on Y — see
## `draw_shadow()`'s own docstring for why the squash comes after the rotation rather than before
## it. Wound consistently (not by nested sign loops, which would cross the two diagonals into a
## bowtie) so `draw_colored_polygon` fills the quad rather than half of it twice.
func _rect_points(at: Vector2, axis: Vector2) -> PackedVector2Array:
	var along := axis.normalized()
	var across_axis := Vector2(-along.y, along.x)
	var corners: Array[Vector2] = [
		Vector2(-half_extents.x, -half_extents.y),
		Vector2(half_extents.x, -half_extents.y),
		Vector2(half_extents.x, half_extents.y),
		Vector2(-half_extents.x, half_extents.y),
	]
	var points := PackedVector2Array()
	for corner in corners:
		var rotated := along * corner.x + across_axis * corner.y
		points.append(at + Vector2(rotated.x, rotated.y * SHADOW_SQUASH))
	return points
