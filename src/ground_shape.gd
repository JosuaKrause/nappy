class_name GroundShape
extends RefCounted
## One ground-plane shape for an object, independent of its picture — the datum the shadow and
## the collision body are both derived from. See docs/TODO.md, M61, "one shape per object", and
## docs/EVENTS.md, "Solid things are solid".
##
## A shape is a **spine** plus a **radius**: the spine is either a point or a segment of
## `half_length` along local +X, and `radius` is the rounding around it. The two kinds this file
## knows are therefore a disc (point spine) and a capsule (segment spine) — there is deliberately
## no rectangle and no polygon here, because nothing in the game needs one yet. The general
## Minkowski-sum case (a shape offset outward by a kernel, which is what the excitement field
## becomes) is composition over this datum for a later slice, not a reason to widen this one now.

## The spine's half-length along local +X. Zero for a point shape.
var half_length := 0.0
## The rounding around the spine — the shape's half-thickness perpendicular to it.
var radius := 0.0

func _init(half_length_in: float, radius_in: float) -> void:
	half_length = half_length_in
	radius = radius_in

## A point shape: the disc every stationary point object in the game already draws and collides
## as.
static func point(radius_in: float) -> GroundShape:
	return GroundShape.new(0.0, radius_in)

## A segment shape: a spine of `half_length_in` along local +X, rounded by `radius_in` — the
## capsule a spread-drawn row or a wide vehicle reduces to.
static func segment(half_length_in: float, radius_in: float) -> GroundShape:
	return GroundShape.new(half_length_in, radius_in)

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
## radius, a park's obstruction allowance) is stated over.
func reach() -> float:
	return half_length + radius

## The half-thickness perpendicular to the spine — the shape's narrow axis, and the one a spread
## body is measured against when it has to fit a pavement band rather than merely reach across it.
func across() -> float:
	return radius

## Distance from a local point to the spine: zero on the spine itself, the perpendicular distance
## beside a segment's middle, and the Euclidean distance to the nearer end once `local` is past
## it. Zero for a point shape, whose spine is the origin. Not read by anything in this slice — the
## field the next slice adds is stated over exactly this function, so it is written and tested now
## rather than invented alongside the field.
func distance_to_spine(local: Vector2) -> float:
	if half_length <= 0.0:
		return local.length()
	var clamped_x := clampf(local.x, -half_length, half_length)
	return local.distance_to(Vector2(clamped_x, 0.0))

## This shape's own collision resource: a `CircleShape2D` for a point spine, a `CapsuleShape2D`
## (`radius`, `height = 2 * reach()`) for a segment one.
##
## **Godot's capsule stands along local Y.** A caller that wants this shape's segment lying along
## its own local X — the axis every other method here treats as "along the spine" — has to rotate
## the `CollisionShape2D` it hangs this off by `+90°`, or more generally by the spine's own axis
## angle minus 90° when that axis is not X itself.
func collision_shape() -> Shape2D:
	if half_length <= 0.0:
		var circle := CircleShape2D.new()
		circle.radius = radius
		return circle
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
## For a point spine this is exactly the contact-shadow ellipse every point object in the game
## already casts, so every point shadow is visually unchanged by this shape existing. For a
## segment spine, the spine is rotated by `axis` **on the ground plane, unsquashed** — the ground
## itself is drawn 1:1, tiles are square, so there is no foreshortening to apply to a direction
## lying flat on it — an ellipse is placed at each end, and the convex hull of the two ellipses'
## outlines is filled: a north-south band therefore gets a tall thin shadow spanning its whole
## length, rather than the single oval every shape stood on before this.
func draw_shadow(canvas: CanvasItem, at: Vector2, axis: Vector2 = Vector2.RIGHT) -> void:
	if half_length <= 0.0:
		canvas.draw_set_transform(at, 0.0, Vector2(1.0, SHADOW_SQUASH))
		canvas.draw_circle(Vector2.ZERO, radius, Palette.SHADOW, true, -1.0, true)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
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
