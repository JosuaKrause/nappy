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
## band, which is why `band()` below still hands out only those two. There is still no polygon: the
## general Minkowski-sum case (a shape offset outward by a kernel, which is what the excitement
## field becomes) is composition over this datum for a later slice, not a reason to widen this one.

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
## ordinary point-to-box distance outside it. Not read by anything in this slice — the field a
## later slice adds is stated over exactly this function, so it is written and tested now rather
## than invented alongside the field.
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

## Draws this shape's shadow at `at`, in `canvas`'s own coordinates.
##
## For a point this is exactly the contact-shadow ellipse every point object in the game already
## casts, so every point shadow is visually unchanged by this shape existing. For a segment, the
## spine is rotated by `axis` **on the ground plane, unsquashed** — the ground itself is drawn
## 1:1, tiles are square, so there is no foreshortening to apply to a direction lying flat on it —
## an ellipse is placed at each end, and the convex hull of the two ellipses' outlines is filled: a
## north-south band therefore gets a tall thin shadow spanning its whole length, rather than the
## single oval every shape stood on before this. For a rectangle, the four corners are rotated by
## `axis` the same way the segment's spine is, and **then** squashed on Y by `SHADOW_SQUASH` — the
## point case's own foreshortening, applied after the rotation rather than to the rectangle's own
## local frame, so a rectangle turned to face `axis` still reads as lying flat in the same oblique
## view every other shadow does.
func draw_shadow(canvas: CanvasItem, at: Vector2, axis: Vector2 = Vector2.RIGHT) -> void:
	match kind:
		Kind.POINT:
			canvas.draw_set_transform(at, 0.0, Vector2(1.0, SHADOW_SQUASH))
			canvas.draw_circle(Vector2.ZERO, radius, Palette.SHADOW, true, -1.0, true)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Kind.RECT:
			canvas.draw_colored_polygon(_rect_points(at, axis), Palette.SHADOW)
		_:
			var along := axis.normalized()
			var points := PackedVector2Array()
			points.append_array(_ellipse_points(at + along * half_length))
			points.append_array(_ellipse_points(at - along * half_length))
			canvas.draw_colored_polygon(Geometry2D.convex_hull(points), Palette.SHADOW)

func _ellipse_points(centre: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in _ELLIPSE_SAMPLES:
		var angle := TAU * float(i) / float(_ELLIPSE_SAMPLES)
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
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
