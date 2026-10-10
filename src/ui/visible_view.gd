class_name VisibleView
extends RefCounted
## What the player can actually see: the camera's view of the world, less whatever the on-screen
## controls cover. *(feathery-lynx, inbox #581, the player: "when counting the 80% visibility for
## seen remove the area at the bottom left and right up to the top of the joystick circle and
## horizontal extent of the speed button -- use that everywhere where visibility is concerned -- for
## the other mode those rectangles *do* count"; asked whether the rest of the game follows: "yes,
## everything should follow this (and treat it depending on the input mode)".)*
##
## **The one answer to "can she see it"**, for everything that asks: the screen-edge badge, which is
## up for a thing until she can see it (`DangerEdge`); the fire's
## sighting, which summons the engine (`EventManager._summon_what_has_been_sighted()`); a chalk mark
## counting as noticed, the one "has she seen this" of the resistance's (`ResistanceDirector`, handed
## `sees()` by `main`); the poster crews' pasting (`PosterWalls._work_the_crews()`); and the
## page's counter (`EncounterWatch`, the pelican's `pelican-seen`). **What is drawn and loaded is not
## asked here**: the streaming of the ground, the scenery and the day's events keeps the whole view,
## since the corners are drawn under the controls rather than left undrawn.
##
## The covered corners exist only in joystick mode. Each focus carries either a steering ring
## or an equally sized Run disc, so the steering side the title chose does not change the covered
## footprint.
## Each rectangle runs from its screen edge to the disc's far edge, and from its top downward.
## In tap mode the whole view counts. A thing under a covered corner keeps its badge.
##
## **Placing a thing is not a "has she seen it" question.** A thing arriving from off screen is placed
## wholly outside the camera's whole view, corners included (`PendingWarning.seen_from()` asks
## `clear_of_sight()` of this view with no corners laid on it) *(amendment 6 of M226, the player: "I
## don't want any pop in")*: a thing placed under a corner would still be drawn there. The same goes
## for whatever the resistance places or takes away, which asks `EventManager.on_screen()`, a point
## anywhere in this view's whole rect, corners included *(olive-hedgehog, inbox #598: "off screen is
## not the same as visible -- the corners get removed for visible not for off screen")*.
##
## The corners are worked out from `TouchControls`' own constants in the 1280x720 design box and
## scaled onto the view, so moving a ring or a button moves what it covers.
##
## **The view is the world the camera shows**, `Tuning.VIEW_HALF_EXTENT` either side of where the
## camera is drawing from (`Stroller.camera_screen_center()`, which carries her look-ahead and the
## camera's smoothing), and its corners are the design box's own whether or not a portrait touch
## window presents the game rotated: `main._apply_orientation()` turns the world through the camera
## and every layer of screen furniture through the same quarter turn, so the controls stay over the
## same corner of the world the camera shows and the world box is the same 640x360 either way. That
## is the rotation `DangerEdge`'s own screen test used to undo point by point
## (`ScreenOrientation.to_design_space()`); a world box needs no undoing.
##
## Two ways to ask. `visible_share()` is the one-off question. A caller asking about many things in
## one frame keeps an instance, sets it once a frame — `look_through()` from the camera, or `look()`
## from a view a rig chose — which lays the two corners onto the view there and then, and asks
## `sees()`, `share_of()` or `clear_of_sight()` for each thing, so the corners are worked out once a
## frame rather than once a thing. `EventManager` keeps the day's one instance, set at the top of its
## physics frame (`EventManager.visible_view()`).

## The world the camera shows, as `look()` was last told. Empty until it has been told, and then
## nothing is in sight.
var view := Rect2()
## Whether the joystick scheme's controls cover the view's bottom corners, as `look()` was last told.
var joystick := false
## The two covered corners laid onto `view`, while `joystick` holds.
var _left := Rect2()
var _right := Rect2()
## The on-screen controls `look_through()` reads the scheme from, found once — `null` where nothing
## built them (a rig, a test), which is the tap scheme's whole view.
var _controls: TouchControls = null

## A view of `Tuning.VIEW_HALF_EXTENT` either side of `centre`, in the scheme `joystick_in_force`
## says — what a rig with no camera stands in for the camera's view with.
static func around(centre: Vector2, joystick_in_force := false) -> VisibleView:
	var made := VisibleView.new()
	made.look(Rect2(centre - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0),
			joystick_in_force)
	return made

## Sets the view and the scheme for this frame, and lays the covered corners onto it.
func look(at_view: Rect2, joystick_in_force: bool) -> void:
	view = at_view
	joystick = joystick_in_force
	if joystick:
		var scale := view.size / ScreenOrientation.DESIGN_SIZE
		_left = _onto(covered_left(), view, scale)
		_right = _onto(covered_right(), view, scale)

## Sets this frame's view from the camera on `player`: `Tuning.VIEW_HALF_EXTENT` about where it is
## drawing from — `Stroller.camera_screen_center()`, or the player's own position for a body with no
## camera (a rig) — and the scheme from the on-screen controls, found once in the player's tree
## (`HelpText.CONTROLS_GROUP`).
func look_through(player: Node2D) -> void:
	var stroller := player as Stroller
	var centre := stroller.camera_screen_center() if stroller else player.global_position
	if (_controls == null or not is_instance_valid(_controls)) and player.is_inside_tree():
		_controls = player.get_tree().get_first_node_in_group(HelpText.CONTROLS_GROUP) as TouchControls
	var in_force := _controls != null and is_instance_valid(_controls) \
			and _controls.controls_mode() == ControlsMode.Mode.JOYSTICK
	look(Rect2(centre - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0), in_force)

## `visible_share()` for `rect` against what `look()` was last told.
func share_of(rect: Rect2) -> float:
	return _share(rect, view, joystick, _left, _right)

## Whether a world point is in sight: inside the view, and not under a covered corner. `margin`
## world px count as in sight as well, past the view's edge and into a corner — the badge's
## hysteresis (`DangerEdge.SCREEN_MARGIN`), so a thing on the boundary does not trade places with its
## own badge every frame.
func sees(point: Vector2, margin := 0.0) -> bool:
	if not view.grow(margin).has_point(point):
		return false
	if not joystick:
		return true
	return not (_left.grow(-margin).has_point(point) or _right.grow(-margin).has_point(point))

## Whether any of `rect` (world space) is in sight.
func sees_any(rect: Rect2) -> bool:
	return share_of(rect) > 0.0

## **Just out of sight**: the least distance along `direction` (unit) from `from` at which a thing
## whose drawn box is `box` — relative to its feet — is wholly out of sight, never less than
## `at_least`. A covered corner counts as out of sight, so in the joystick scheme a way that crosses
## one ends at its edge rather than at the view's; asked of a view with no corners (what placement
## asks, `PendingWarning.seen_from()`), it is the edge of the camera's whole view.
##
## The view's own edge first, worked out per side; then, in the joystick scheme, the nearer
## distances are walked in `SIGHT_STEP` steps from `at_least`, for the one place a corner can make
## nearer than the view's edge (which is why placement asks a view with no corners). A thing with no
## box is a point.
func clear_of_sight(from: Vector2, direction: Vector2, box: Rect2, at_least := 0.0) -> float:
	var out := _leaves_the_view(from, direction, box, at_least)
	if not joystick or out <= at_least:
		return out
	var d := at_least
	while d < out:
		if not sees_any(_box_at(from + direction * d, box)):
			return minf(d + CLEAR_MARGIN, out)
		d += SIGHT_STEP
	return out

## How finely `clear_of_sight()` walks a way that may cross a covered corner, in world px.
const SIGHT_STEP := 2.0

## The least distance at least `at_least` along `direction` at which `box`, carried from `from`,
## is wholly outside `view` — the nearest of the sides the way leaves through.
func _leaves_the_view(from: Vector2, direction: Vector2, box: Rect2, at_least: float) -> float:
	var shape := box if box.has_area() else Rect2(Vector2.ZERO, Vector2.ZERO)
	var best := INF
	# Past the right side once its left edge is, past the left once its right edge is; the same down
	# and up.
	if direction.x > 0.0:
		best = minf(best, (view.end.x - shape.position.x - from.x) / direction.x)
	elif direction.x < 0.0:
		best = minf(best, (view.position.x - shape.end.x - from.x) / direction.x)
	if direction.y > 0.0:
		best = minf(best, (view.end.y - shape.position.y - from.y) / direction.y)
	elif direction.y < 0.0:
		best = minf(best, (view.position.y - shape.end.y - from.y) / direction.y)
	return maxf(best + CLEAR_MARGIN, at_least)

## How far past the edge "wholly out of sight" is, in world px: one, so a box whose edge would sit
## exactly on the view's edge is not shown by a rounding.
const CLEAR_MARGIN := 1.0

static func _box_at(feet: Vector2, box: Rect2) -> Rect2:
	if not box.has_area():
		return Rect2(feet - Vector2.ONE * 0.5, Vector2.ONE)
	return Rect2(feet + box.position, box.size)

## The left covered corner includes the painted ring or Run disc, never its invisible catch.
static func covered_left() -> Rect2:
	var top := TouchControls.FOCUS_LEFT.y - TouchControls.RUN_RADIUS
	var right := TouchControls.FOCUS_LEFT.x + TouchControls.RUN_RADIUS
	return Rect2(0.0, top, right, ScreenOrientation.DESIGN_SIZE.y - top)

## The right covered corner mirrors the same disc footprint.
static func covered_right() -> Rect2:
	var top := TouchControls.FOCUS_RIGHT.y - TouchControls.RUN_RADIUS
	var left := TouchControls.FOCUS_RIGHT.x - TouchControls.RUN_RADIUS
	return Rect2(left, top, ScreenOrientation.DESIGN_SIZE.x - left, ScreenOrientation.DESIGN_SIZE.y - top)

## The share, 0 to 1, of `rect` (world space) the player can see in `view` (the world the camera
## shows), leaving out the covered corners when `joystick` is the scheme in force. 0 for a rectangle
## with no area. The two corners never overlap each other, so what they cover of `rect` is a plain
## sum. Allocates nothing, so a caller may ask it for every live thing every frame.
static func visible_share(rect: Rect2, in_view: Rect2, joystick_in_force: bool) -> float:
	if not joystick_in_force:
		return _share(rect, in_view, false, Rect2(), Rect2())
	var scale := in_view.size / ScreenOrientation.DESIGN_SIZE
	return _share(rect, in_view, true, _onto(covered_left(), in_view, scale),
			_onto(covered_right(), in_view, scale))

static func _share(rect: Rect2, in_view: Rect2, covered: bool, left: Rect2, right: Rect2) -> float:
	var area := rect.get_area()
	if area <= 0.0:
		return 0.0
	var inside := rect.intersection(in_view).get_area()
	if covered and inside > 0.0:
		inside -= rect.intersection(left).get_area()
		inside -= rect.intersection(right).get_area()
	return maxf(0.0, inside) / area

## A design-box rectangle laid onto `view`, `scale` being the view's size over the design box's.
static func _onto(design: Rect2, onto: Rect2, scale: Vector2) -> Rect2:
	return Rect2(onto.position + design.position * scale, design.size * scale)
