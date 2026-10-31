class_name SpawnSiting
extends RefCounted
## **Where something sent at her may start**: the rules a start is held to, each by its name
## (`Rule`), and the searches that answer a start by them. One instance per city, built with the
## city's map, its navigator, the day's view and the day's region (`City.spawn_siting`), and handed
## to whatever sends something at her — the events' director half (`EventsAhead`) and the
## resistance (`ResistanceDirector`) — rather than fetched; a rig builds its own over its own map.
##
## **The rules** (`allows()`):
##
## - `LEGAL_GROUND`: ground the day leaves to her and to whatever is sent at her
##   (`is_legal_ground()`): walkable, not behind a closure, not held, not the home block's own lot,
##   not inside a walled-off crossing alley;
## - `OUT_OF_SIGHT`: everything the thing can draw, standing there, wholly outside the camera's
##   whole view and at least `least_distance()` from her (`is_out_of_sight()`);
## - `OFF_THE_VIEW`: the point itself nowhere in the camera's whole view right now, the covered
##   corners included (`on_the_view()`) *(olive-hedgehog, inbox #598, the player: "off screen is not
##   the same as visible -- the corners get removed for visible not for off screen")*;
## - `CLEAR_OF_THE_BOUNDARY`: the straight line from there to her passes through no body of the
##   day's region wall or of a district door (`runs_through()`) — a man walking through the
##   checkpoint she was inspected at is no run at her;
## - `CLEAR_RUN`: the straight line from there to her crosses only ground the thing may enter
##   (`Navigator.clear_line()`), since a pursuer chases in a straight line;
## - `REACHES_HER`: the chase the thing takes from there reaches her within the ground a start
##   beside her would take, never through the boundary (`Navigator.reaches()`).
##
## **The sight geometry is here too**, static, for every caller that places out of her sight
## without a siting of its own (`PendingWarning`'s places): just out of sight along a bearing
## (`just_out_of_sight()`), the camera's whole view placement is measured against (`seen_from()`),
## and the least distance anything arriving from off screen is created at (`least_distance()`).
## A thing's drawing is its box about its feet (`EventFootprints.footprint_of()`), handed in as a
## `Rect2`, so nothing here names a row.

## A rule a start is held to, by name: see the class doc.
enum Rule {
	LEGAL_GROUND,
	OUT_OF_SIGHT,
	OFF_THE_VIEW,
	CLEAR_OF_THE_BOUNDARY,
	CLEAR_RUN,
	REACHES_HER,
}

## The rules a start a pursuer is sent from passes to be one at all, in the order they are asked:
## a start that passes them and has a clear run at her decides a search, and the first that passes
## them without one stands in where none has (`start_out_of_sight()`).
const STANDS: Array[Rule] = [Rule.LEGAL_GROUND, Rule.OFF_THE_VIEW, Rule.CLEAR_OF_THE_BOUNDARY]

## **What the day's region shuts**, as the city hands it (`City.siting_region()`): the crossing
## alleys a wall closes, and each body of the wall and of the district doors as a disc, kerb to kerb
## across a street (`RegionPlanner._add_door_bodies()`, `SealPlanner.place_hard_on()`), so a line
## through a door or the wall passes through one of them wherever it crosses.
class Region:
	extends RefCounted
	## The walled-off crossing alleys (`RegionPlanner.RegionPlan.alley_walls`).
	var walled_alleys: Array[Rect2i] = []
	## Where each body of the wall and the doors stands, in world px.
	var centres := PackedVector2Array()
	## How far each body's disc reaches from its centre (`EventDef.obstructs_radius`), paired with
	## `centres` index for index.
	var radii := PackedFloat64Array()

## **What one placement asks**, worked out once for her standing where she is: the camera's whole
## view placed against, what the thing draws and how it walks, how far a start beside her is, and
## the region bodies that could stand in a run at her from there (`ask()`).
class Ask:
	extends RefCounted
	## Where she stands.
	var her := Vector2.ZERO
	## What the thing draws, about its feet (`EventFootprints.footprint_of()`); no area for a point.
	var box := Rect2()
	## How the thing walks (`Mover`): what its run at her and its chase are asked of.
	var mover: Mover
	## The camera's whole view, no corners laid on it (`seen_from()`).
	var view: VisibleView
	## How far to her side a start just out of sight is, on whichever side is further
	## (`beside_distance()`): what a chase from a start elsewhere may walk at most (`REACHES_HER`).
	var beside := 0.0
	## The region's bodies whose disc could stand in a run at her from `beside` away, as centres and
	## radii index for index.
	var centres := PackedVector2Array()
	var radii := PackedFloat64Array()
	## The crossing alleys today's region walls off (`LEGAL_GROUND`).
	var walled_alleys: Array[Rect2i] = []

## **A start a search answered**: where, `Vector2.INF` for none, and what kind of start it is.
class Start:
	extends RefCounted
	## Where the thing starts, or `Vector2.INF` when nothing qualified.
	var at := Vector2.INF
	## Whether the straight line from there to her is walkable (`CLEAR_RUN`).
	var clear := false
	## Whether it starts to her side, along her street, rather than above or below her.
	var beside := false
	## Whether it comes from across the street at a front door (`across_the_street()`).
	var across := false

	func _init(where := Vector2.INF, has_a_clear_run := false, to_her_side := false,
			from_across := false) -> void:
		at = where
		clear = has_a_clear_run
		beside = to_her_side
		across = from_across

var _map: CityMap
var _navigator: Navigator
## `func() -> VisibleView`: the day's one view, as this frame looked through it, or null where there
## is none (a rig with no camera), and then nothing is on the view.
var _view: Callable
## `func() -> SpawnSiting.Region`: today's region, or null where nothing is walled (before the
## wall's first day, a rig with no city).
var _region: Callable

## A siting over `map`, its starts walked by `navigator`, against the day's view `view` and region
## `region` (see the fields); either left empty for a rig that has neither.
func _init(map: CityMap, navigator: Navigator, view := Callable(), region := Callable()) -> void:
	_map = map
	_navigator = navigator
	_view = view
	_region = region

## The map this siting places on.
func map() -> CityMap:
	return _map

## Today's region as the city hands it, or null.
func region() -> Region:
	return _region.call() if _region.is_valid() else null

## What a placement of something drawing `box` and walking as `mover` asks with her standing at
## `her` (`Ask`).
func ask(box: Rect2, mover: Mover, her: Vector2) -> Ask:
	var asked := Ask.new()
	asked.her = her
	asked.box = box
	asked.mover = mover
	asked.view = seen_from(_view.call() if _view.is_valid() else null, her)
	asked.beside = beside_distance(asked.view, box, her)
	var today := region()
	if today != null:
		asked.walled_alleys = today.walled_alleys
		for i in today.centres.size():
			if today.centres[i].distance_to(her) <= asked.beside + today.radii[i]:
				asked.centres.append(today.centres[i])
				asked.radii.append(today.radii[i])
	return asked

# ---------------------------------------------------------------------- the rules ---

## Whether `at` passes `rule` for `asked` — see the class doc for each rule.
func allows(rule: Rule, asked: Ask, at: Vector2) -> bool:
	match rule:
		Rule.LEGAL_GROUND:
			return is_legal_ground(_map, _map.world_to_tile(at), asked.walled_alleys)
		Rule.OUT_OF_SIGHT:
			return is_out_of_sight(asked.view, asked.box, asked.her, at)
		Rule.OFF_THE_VIEW:
			return not on_the_view(at)
		Rule.CLEAR_OF_THE_BOUNDARY:
			return not runs_through(at, asked.her, asked.centres, asked.radii)
		Rule.CLEAR_RUN:
			return _navigator.clear_line(at, asked.her, asked.mover)
		Rule.REACHES_HER:
			return _navigator.reaches(at, asked.her, asked.mover, asked.beside,
					func(from: Vector2, to: Vector2) -> bool:
						return runs_through(from, to, asked.centres, asked.radii))
	return false

## Whether `at` passes every rule of `rules` for `asked`, asked in order.
func allows_every(rules: Array[Rule], asked: Ask, at: Vector2) -> bool:
	for rule in rules:
		if not allows(rule, asked, at):
			return false
	return true

## Whether a world point is anywhere in the camera's whole view right now, the covered corners
## included: a thing under a covered corner is still drawn there, so appearing or vanishing there is
## pop-in *(the same note: "I don't want any pop in")*. `false` where there is no view, or it has
## not been looked through.
func on_the_view(at: Vector2) -> bool:
	var view: VisibleView = _view.call() if _view.is_valid() else null
	return view != null and view.view.has_point(at)

## **Ground the day leaves to her and to whatever is sent at her**: walkable, not behind a closure
## (`CityMap.passable()` for the city as built and today's closures), not on held ground unless
## `allow_held`, not on the home block's own lot, not in a walled-off crossing alley. Static, so the
## tiles the day's planning protects (`ResistanceDirector.target_ground()`) are exactly the ones a
## draw may land on.
##
## **Never on the home block's own ground.** *(Playtest 11: "events/hazards should not spawn on the
## home block".)* `is_held_at` refuses a segment bordering the block, `is_on_home_block` anything
## inside it.
##
## **Never inside a walled-off crossing alley.** *(PLAYTEST-57: "a blocked off alley must not have a
## chalk mark.")* An alley never sits on a street segment, so `is_held_at` cannot see one however
## its mouths stand, and a region wall is not a road closure, so `is_closed` cannot either:
## `CityMap.is_in_walled_alley` is the refusal built for exactly this ground.
##
## The bodies standing today and the soft seals are not asked here: a caller asks those after its
## draw, so a pool with nothing obstructed in it draws exactly what it would.
static func is_legal_ground(map: CityMap, tile: Vector2i, walled_alleys: Array[Rect2i],
		allow_held := false) -> bool:
	return map.passable(tile, Mover.of(Mover.GROUND | Mover.POSTS | Mover.CLOSED)) \
			and (allow_held or not map.is_held_at(tile)) \
			and not map.is_on_home_block(tile) and not map.is_in_walled_alley(tile, walled_alleys)

## Whether the straight line from `from` to `to` passes through one of the discs at `centres`, each
## within its own radius of `radii`.
static func runs_through(from: Vector2, to: Vector2, centres: PackedVector2Array,
		radii: PackedFloat64Array) -> bool:
	for i in centres.size():
		var nearest := Geometry2D.get_closest_point_to_segment(centres[i], from, to)
		if nearest.distance_to(centres[i]) <= radii[i]:
			return true
	return false

# --------------------------------------------------------------------- the queries ---

## **A start just out of sight of her, tried along `bearings` in order**: the first whose start
## (`just_out_of_sight()` along it) passes `STANDS` and has a clear run at her (`CLEAR_RUN`), since
## a pursuer chases in a straight line, sliding along whatever wall is in the way, and a start
## behind a building is a man stuck against its back wall while the badge says he is coming; where
## none has one, the first that passes `STANDS` stands in, and he may never reach her. `beside` is
## set for a clear start along a bearing straight along her street. The bearings are the caller's —
## drawn from its own stream, or a hash — so nothing here draws.
func start_out_of_sight(asked: Ask, bearings: Array[Vector2]) -> Start:
	var fallback := Vector2.INF
	for bearing in bearings:
		var candidate := just_out_of_sight(asked.view, asked.box, asked.her, bearing)
		if not allows_every(STANDS, asked, candidate):
			continue
		if allows(Rule.CLEAR_RUN, asked, candidate):
			return Start.new(candidate, true, is_zero_approx(bearing.y))
		if fallback == Vector2.INF:
			fallback = candidate
	return Start.new(fallback)

## **Across the street at a front door**: on the far side of her street, below her, out of view,
## with a walk at her — he comes out of the block opposite and crosses at her. The nearest tile
## centre that is below her and passes `OUT_OF_SIGHT`, `LEGAL_GROUND`, `OFF_THE_VIEW` and
## `REACHES_HER` (his own chase walks to her in no more ground than the start beside her, so he is
## never later than the start along her street he replaces, and never through the boundary).
## Every front in this city faces south, the way the oblique view looks at it, so the far side of
## her street is always straight below her.
##
## The walk is his chase's, not a path: straight at her, sliding along whatever wall is in the way
## (`Navigator.reaches()`), so a start in an alley or a courtyard of the block opposite counts when
## sliding up it brings him out onto her street. Nearest first, ties broken by being nearer straight
## below her, so nothing is drawn. `Vector2.INF` when no tile qualifies.
func across_the_street(asked: Ask) -> Vector2:
	var her := asked.her
	var furthest := asked.beside
	var reach := ceili(furthest / Tuning.TILE_SIZE) + 1
	var at := _map.world_to_tile(her)
	var candidates: Array[Vector2] = []
	for dy in range(1, reach + 1):
		for dx in range(-reach, reach + 1):
			var centre := _map.tile_to_world(at + Vector2i(dx, dy))
			var offset := centre - her
			if offset.y <= 0.0 or offset.length() > furthest:
				continue
			if not allows(Rule.OUT_OF_SIGHT, asked, centre):
				continue
			candidates.append(centre)
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var da := a.distance_squared_to(her)
		var db := b.distance_squared_to(her)
		if not is_equal_approx(da, db):
			return da < db
		return absf(a.x - her.x) < absf(b.x - her.x))
	for candidate in candidates:
		if allows_every(ACROSS, asked, candidate):
			return candidate
	return Vector2.INF

## The rules a start across the street passes once it is out of sight (`across_the_street()`).
const ACROSS: Array[Rule] = [Rule.LEGAL_GROUND, Rule.OFF_THE_VIEW, Rule.REACHES_HER]

# ------------------------------------------------------------------ sight geometry ---

## The least distance from her anything arriving from off screen is created at:
## `Tuning.min_offscreen_boundary()`, the view's half height — the worst case `EventDef.validate()`
## checks a row's field against.
static func least_distance() -> float:
	return Tuning.min_offscreen_boundary()

## **Just off screen** along `direction` (unit) from `her`: the nearest point at which a drawing of
## `box` about its feet is wholly outside the camera's view, never nearer than `least_distance()`.
## *(Amendment 6 of M226, the player: "objects don't spawn \"at the edge of the screen\" they spawn
## *offscreen*" · "I don't want any pop in".)* `view` is the camera's whole view (`seen_from()`),
## whatever the input scheme: a corner the joystick's controls cover is out of sight for the badge
## and every "has she seen it", but a thing placed under it is drawn there, so placement never
## counts it.
static func just_out_of_sight(view: VisibleView, box: Rect2, her: Vector2,
		direction: Vector2) -> Vector2:
	return her + direction * view.clear_of_sight(her, direction, box, least_distance())

## The camera's whole view placement is measured against: `view`'s own rect with no covered
## corners, or, where there is none or it has never been looked through — a caller that only asks
## whether there is ground at all, such as `EventDirector`'s siting, or a rig with no camera — the
## view about her.
static func seen_from(view: VisibleView, her: Vector2) -> VisibleView:
	if view and view.view.has_area():
		var whole := VisibleView.new()
		whole.look(view.view, false)
		return whole
	return VisibleView.around(her)

## Whether a drawing of `box` about its feet, standing at `at`, is wholly outside `view` (the
## camera's whole view, `seen_from()`), and at least `least_distance()` from her.
static func is_out_of_sight(view: VisibleView, box: Rect2, her: Vector2, at: Vector2) -> bool:
	if at.distance_to(her) + 0.5 < least_distance():
		return false
	var drawn := Rect2(at + box.position, box.size) if box.has_area() \
			else Rect2(at - Vector2.ONE * 0.5, Vector2.ONE)
	return not view.sees_any(drawn)

## How far to her side a thing drawing `box` starts when it comes along her own street: just out of
## sight sideways (`just_out_of_sight()`), on whichever side is further, so a start either side is
## covered. About 340px with the camera on her.
static func beside_distance(view: VisibleView, box: Rect2, her: Vector2) -> float:
	var right := just_out_of_sight(view, box, her, Vector2.RIGHT).distance_to(her)
	var left := just_out_of_sight(view, box, her, Vector2.LEFT).distance_to(her)
	return ceilf(maxf(right, left))
