class_name ParkCordon
extends RefCounted
## **Day 12's park, closed by a police cordon** once she has reached its swing *(azure-puffin, inbox
## #666: "the park "closing down" is not diegetic -- the material changes in front of the player";
## asked which effect, "(B) for the park with the added danger that you can get trapped inside
## (which would end the day). the policemen must come from offscreen", and asked how it closes,
## "Cordon closes round the edge")*. Owned and ticked by `ResistanceHappenings`, which starts it
## from `take_the_park()`.
##
## - **Officers come from beyond the camera's view.** Two are placed just out of sight on the
##   sidewalk along the side of the park opposite the last gap (`_spawn_out_of_sight()`: everything
##   the policeman's figure draws wholly outside the camera's whole view, the test
##   `ResistanceDirector._drawing_shows()` answers, so nothing is seen to appear) and walk in to
##   the park's edge. Their arrival is the warning: nothing about them telegraphs under the cue
##   rules, since they walk and come toward nobody (`docs/EVENTS.md`, "What telegraphs"), so no
##   screen-edge badge goes up for them.
## - **They tape the edge one stretch at a time, working round it from where they arrived**, one
##   each way, so the open part of the edge shrinks to a last gap. A stretch is one tile of a
##   side's edge, more or less; the tape stands on the park's own edge row, half a barrier's depth
##   in (`ParkClosure`'s fence line, the late park's fence, which it matches), and **a taped
##   stretch is solid** (`CordonTape`'s static body), so the last gap is the only way out.
## - **The last gap is checked before it is accepted** (the city skill, "Check before accepting"):
##   the cordon turns the park from a passage into a wall, so the gap is the edge whose outside
##   ground still reaches home with the park's ground blocked, under the day's own obstruction
##   (`EventScheduler.blocked_by()`'s set, which the director hands in), and stands clear of every
##   body and every seal's or hazard's field (`_clear_of_the_day()`); of those, the one nearest
##   her. When no edge qualifies the best one is used and the run log says so (`_choose_the_gap()`).
## - **Nothing is taped through her or anyone walking out.** The officer about to tape a stretch
##   waits beside it while any part of her collision shape is within reach of it (`HER_REACH`, the
##   pram's circle whichever way she faces), or one of the park's people or their escorts is; and
##   the last gap waits until everyone being walked out is through it.
## - **Other officers walk the park's people out**: up to `Tuning.PARK_CLOSING_ESCORTS`, one to
##   each event standing in the park when it starts, who comes in from out of her sight along the
##   way out (`_exit`: through the last gap and along the ground outside it to where she cannot
##   see), sends them off down that same way (`EventInstance.leave_along()`, which walks on past
##   its end until she could not be watching), walks out behind them, and is gone once out of her
##   sight. Anyone in the park already leaving on their own is turned onto the way too. What the
##   day planned in the park that has not streamed in yet is taken out of the day. The crowd never
##   walks a park, so it has no part in this.
## - **If the last gap is taped while she is inside the tape, the day ends**: she is shut in the
##   park, a hard fail of its own (`TRAPPED`, `DayController`'s sentence for it). Nothing else about
##   the cordon costs her anything: the officers are not pursuers, catch nobody and carry no field.
## - **The ground stays grass.** What took the park's calm is `CityMap.recompute_calm()` at the
##   touch; the tape is what keeps her from settling the baby in it afterwards.
##
## **Timing: she sees them in time on every park** (`_time_the_close()`). The last gap closes no
## sooner than `Tuning.PARK_CLOSING_SECONDS` after the touch, and no sooner than the walk from where
## she stood to the gap plus `Tuning.PARK_CLOSING_WARNING` after the first officer comes into the
## camera's view of where she stood — on a park larger than the view they come into it late, so it
## closes later — and never faster than `Tuning.PARK_CLOSING_STRETCH_MIN` a stretch. Each taper
## paces himself to that moment. `tests/test_park_cordon_seeds.gd` holds both the gap and the
## warning on every seed of a sweep, and `tests/probes/plush_marten_cordon.gd` measures them.
##
## **Deterministic from the moment she touched the swing**: nothing here draws a random number.

## The row whose drawing an officer is — the policeman on foot's (`art/events/policeman_*`) — asked
## of `shows` for where an officer may be placed, so nothing of him is seen to appear.
const OFFICER_ROW := "policeman_giving_chase"
## The hard fail being shut in the park sends, and the name the day's end and the page's counter
## give it (`Texts.HARD_FAIL_TEXT`, `main._hard_fail_cause_suffix()`).
const TRAPPED := "park_cordon"
## How far outside the tape the officers walk round it, off the park's own ground and on the
## sidewalk's edge, so they finish outside the cordon they made.
const OFFICER_OUTSIDE := 16.0
## How far apart the two tapers walk in, one behind the other, and how far apart in time the
## escorts set off, at their own pace.
const TAPER_SPACING := 18.0
## How near an escort comes to the person he walks out before sending them off.
const ESCORT_REACH := 20.0
## How far behind the person an escort walks once they are leaving.
const ESCORT_BEHIND := 16.0
## The steps a search for an out-of-sight place along a sidewalk takes, and how many it takes at
## most each way.
const SEARCH_STEP := Tuning.TILE_SIZE * 0.5
const SEARCH_STEPS := 80
## How far her collision shape reaches from her centre, and so how near a stretch's line her centre
## may be before its officer waits: the pram's circle (`Stroller.PRAM_BODY_RADIUS`, 8px) centred
## `Tuning.PLAYER_BODY_RADIUS` (14px) out along her facing, 22px in all, taken whichever way she
## faces, since the facing follows the input and turns the pram into a line the moment she steers;
## plus half the tape's depth and a margin. Narrower and the tape's static body goes down through
## the pram and the slide pushes her off it, inward as often as not.
const HER_REACH := Tuning.PLAYER_BODY_RADIUS + Stroller.PRAM_BODY_RADIUS \
		+ CordonTape.DEPTH * 0.5 + 2.0
## The same for one of the park's people or an officer walking them out: a walker's body, half the
## tape's depth and a margin.
const WALKER_REACH := Tuning.PLAYER_BODY_RADIUS + CordonTape.DEPTH * 0.5 + 2.0
## How far in from the last gap the park's people and their escorts aim before crossing it, so they
## walk out square through it.
const GAP_INSIDE := Tuning.TILE_SIZE * 0.75
## The step along a planned walk at which `_time_the_close()` asks whether an officer is in view.
const SIGHT_STEP := 4.0
## The most tiles a search for the way out of her sight visits.
const ROUTE_SEARCH_LIMIT := 6000

## One stretch of the edge: a straight piece of one side of the tape's line, from `a` to `b` in the
## loop's clockwise order, and whether it needs tape at all (a side with a wall behind it has no
## way in to close).
class Stretch extends RefCounted:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	## Which side of the park it is on, as the way out from it.
	var outward := Vector2i.ZERO
	var needed := true
	var taped := false
	## The edge tiles it stands on, recorded as obstructed once it is taped.
	var tiles: Array[Vector2i] = []
	var node: CordonTape = null

	func length() -> float:
		return a.distance_to(b)

	func across() -> bool:
		return outward.y != 0

## One officer: where he is, what he is walking, and his figure when there is a city to draw in.
class Officer extends RefCounted:
	enum Job { TAPE, ESCORT }
	enum Phase { WAITING, APPROACH, TAPING, ESCORTING, LEAVING, GONE }
	var job := Job.TAPE
	var phase := Phase.WAITING
	var at := Vector2.ZERO
	var heading := Vector2.DOWN
	var path := PackedVector2Array()
	var speed := 0.0
	## How long a waiting escort stands before he sets off.
	var wait := 0.0
	## A taper's stretches, in the order he tapes them, and which way he walks each.
	var stretches: Array[Stretch] = []
	var forward := true
	var next := 0
	## Whether he is standing beside a stretch, waiting for her or the park's people to be clear.
	var holding := false
	## A taper's pace along the edge, set when he reaches it.
	var tape_speed := 0.0
	## An escort's person.
	var person: EventInstance = null
	var node: CordonOfficer = null

var _map: CityMap
var _city: City
## What an officer's way out is searched over: ground a figure on foot may stand on
## (`Mover.on_foot()`).
var _officer_walks := Mover.on_foot()
## The day's obstruction as the director's reachability answer has it (`EventScheduler.
## blocked_by()`: today's closures plus every body's disc), which the last gap is checked under.
var _blocked: Dictionary
## The park, as its block, and its calm ground in world space.
var park := Vector2i(-1, -1)
var area := Rect2()
var _rect := Rect2i()
## The rectangle the tape stands on: the park's ground, half a barrier's depth in. She is shut in
## when she is inside it as the last gap is taped.
var line := Rect2()
var stretches: Array[Stretch] = []
var officers: Array[Officer] = []
## Seconds since she touched the swing.
var elapsed := 0.0
## When the last gap is to close, seconds after the touch (`_time_the_close()`).
var deadline := Tuning.PARK_CLOSING_SECONDS
## When the first officer is due to come into the camera's view of where she stood at the touch,
## and the walk from there to the last gap, in seconds: what `deadline` was solved from.
## `tests/test_park_cordon_seeds.gd` holds the first against when one is first seen, and the probe
## prints both.
var first_in_view := INF
var walk_to_the_gap := 0.0
## The moment the last gap was taped, and whether she was inside it then. Kept for the tests.
var closed_at := -1.0
var trapped := false
## Where the last gap closes, on the line, and the stretches it is (the one chosen and, when it
## continues it on the same side, the one before).
var last_gap := Vector2.INF
var gap: Array[Stretch] = []
## Whether the chosen gap's outside reaches home with the park blocked, whether it stands clear of
## every body and field, and whether the day's other calm ground is reached from home then. Kept
## for the tests and the probe.
var gap_reaches_home := false
var gap_clear := false
var other_calm_reached := false
## The way out for the park's people and their escorts: from inside the last gap, through it and
## along the ground outside to a place out of her sight, in world points.
var _exit := PackedVector2Array()
## The park's people sent off down `_exit`, still walking out.
var _leaving: Array[EventInstance] = []
var _started := false
## Where the cordon writes its own account for the run log; the happenings' trace, handed on as it is
## built.
var trace := RunTrace.new()

## Starts closing `block`'s park: the line, its stretches and which of them need tape. Nothing is
## placed until the first `tick()`, which knows where she is and what the camera sees. `blocked` is
## the day's obstruction the last gap is checked under (`ResistanceDirector`'s `_reach_blocked`).
func _init(map: CityMap, city: City, block: Vector2i, blocked: Dictionary = {}) -> void:
	_map = map
	_city = city
	_blocked = blocked
	park = block
	_rect = ClosurePlanner.calm_area_rect(map, block)
	area = map.tile_rect_to_world(_rect)
	var inset := Tuning.CLOSURE_BARRIER_DEPTH * 0.5
	line = area.grow(-inset)
	_cut_the_stretches(_rect)

## Whether the last gap has been taped.
func is_closed() -> bool:
	return closed_at >= 0.0

## Frees everything the cordon put in the world and gives its tiles back — the next morning, or a
## retried day.
func clear() -> void:
	for stretch in stretches:
		if stretch.node and is_instance_valid(stretch.node):
			stretch.node.queue_free()
		stretch.node = null
		if _map:
			_map.release_obstruction(stretch.get_instance_id())
	for officer in officers:
		_free_figure(officer)
	officers.clear()
	_leaving.clear()
	for post in _posts:
		if is_instance_valid(post):
			post.queue_free()
	_posts.clear()

## Once a frame, from `ResistanceHappenings.tick()`. `her` is her position (`Vector2.INF` with no
## player), `shows(row, feet)` whether any of `row`'s drawing standing at `feet` is in the camera's
## whole view (unset in a rig with no camera, where `Tuning.OUT_OF_SIGHT` from her stands in).
func tick(delta: float, her: Vector2, shows: Callable) -> void:
	elapsed += delta
	if not _started:
		_started = true
		_set_out(her, shows)
	for officer in officers:
		_move(officer, delta, her, shows)
	if not is_closed() and _every_stretch_taped():
		_close(her, shows)

# ------------------------------------------------------------------- the line ---

## The line's four sides in clockwise order from the north-west corner, each cut into stretches of
## about a tile; a stretch needs tape where the park's edge under it opens onto walkable ground
## (`ParkClosure.fence()`'s runs, the late park's own entrances).
func _cut_the_stretches(rect: Rect2i) -> void:
	var runs: Array[ParkClosure] = ParkClosure.fence(_map, park)
	var corners: Array[Vector2] = [line.position, Vector2(line.end.x, line.position.y), line.end,
			Vector2(line.position.x, line.end.y)]
	var outs: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for side in 4:
		var from: Vector2 = corners[side]
		var to: Vector2 = corners[(side + 1) % 4]
		var pieces := maxi(1, roundi(from.distance_to(to) / Tuning.TILE_SIZE))
		for i in pieces:
			var stretch := Stretch.new()
			stretch.a = from.lerp(to, float(i) / pieces)
			stretch.b = from.lerp(to, float(i + 1) / pieces)
			stretch.outward = outs[side]
			stretch.tiles = _edge_tiles(rect, stretch)
			stretch.needed = _opens_out(runs, stretch)
			stretches.append(stretch)

## The tiles of the park's edge row a stretch stands over.
func _edge_tiles(rect: Rect2i, stretch: Stretch) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var steps := maxi(1, ceili(stretch.length() / (Tuning.TILE_SIZE * 0.5)))
	for i in steps + 1:
		var tile := _map.world_to_tile(stretch.a.lerp(stretch.b, float(i) / steps))
		tile.x = clampi(tile.x, rect.position.x, rect.end.x - 1)
		tile.y = clampi(tile.y, rect.position.y, rect.end.y - 1)
		if not found.has(tile):
			found.append(tile)
	return found

func _opens_out(runs: Array[ParkClosure], stretch: Stretch) -> bool:
	for run in runs:
		if run.outward != stretch.outward:
			continue
		for tile in stretch.tiles:
			if run.segment.tile_rect().has_point(tile):
				return true
	return false

func _every_stretch_taped() -> bool:
	for stretch in stretches:
		if stretch.needed and not stretch.taped:
			return false
	return true

## The loop parameter of the point of the line nearest `point`: its distance clockwise round the
## line from the north-west corner.
func _along(point: Vector2) -> float:
	var best := 0.0
	var nearest := INF
	var walked := 0.0
	for stretch in stretches:
		var on := Geometry2D.get_closest_point_to_segment(point, stretch.a, stretch.b)
		var distance := on.distance_to(point)
		if distance < nearest:
			nearest = distance
			best = walked + stretch.a.distance_to(on)
		walked += stretch.length()
	return best

## The index of the stretch boundary (a stretch's `a`) nearest the loop parameter `s`.
func _boundary_at(s: float) -> int:
	var perimeter := _perimeter()
	var best := 0
	var nearest := INF
	var walked := 0.0
	for i in stretches.size():
		var difference := absf(fposmod(walked - s + perimeter * 0.5, perimeter) - perimeter * 0.5)
		if difference < nearest:
			nearest = difference
			best = i
		walked += stretches[i].length()
	return best

func _perimeter() -> float:
	var total := 0.0
	for stretch in stretches:
		total += stretch.length()
	return total

## Where an officer stands beside a point of the line: `OFFICER_OUTSIDE` out from it, off the park.
func _outside(point: Vector2, outward: Vector2i) -> Vector2:
	return point + Vector2(outward) * OFFICER_OUTSIDE

# ------------------------------------------------------------------ the gap ---

## **Which stretch the last gap is**, checked before it is accepted. A candidate is a stretch that
## needs tape, with the stretch before it when that one continues it on the same side, since the
## two tapers finish on those two together. It qualifies when the ground outside every stretch of
## it reaches home with the park's own ground blocked under the day's obstruction (`_blocked`) and
## the point outside it stands clear of every body and field (`_clear_of_the_day()`); of those the
## nearest `her` (the park's middle with no player) wins. When none qualifies, the candidate that
## reaches home is preferred to the one that only stands clear, and the run log says what was given
## up.
func _choose_the_gap(her: Vector2) -> int:
	var ground := _ground_outside()
	var best := -1
	var best_rank := 3
	var best_distance := INF
	for k in stretches.size():
		if not stretches[k].needed:
			continue
		var reaches := true
		var clear := true
		for stretch in _gap_of(k):
			reaches = reaches and _outside_reaches(stretch, ground)
			clear = clear and _clear_of_the_day(_point_outside(stretch))
		var rank := (0 if reaches else 2) + (0 if clear else 1)
		var distance := her.distance_to(_gap_point(k))
		if rank < best_rank or (rank == best_rank and distance < best_distance):
			best = k
			best_rank = rank
			best_distance = distance
	if best < 0:
		return 0
	gap_reaches_home = best_rank < 2
	gap_clear = best_rank % 2 == 0
	for tile in _map.calm_tiles():
		if not _rect.has_point(tile) and _map.reaches(ground, tile):
			other_calm_reached = true
			break
	if best_rank > 0:
		trace.note("contact", "no stretch of the park's edge opens onto ground that reaches "
				+ "home clear of the day's events: the last gap is the best of them (reaches home: "
				+ "%s, clear of bodies and fields: %s)" % [gap_reaches_home, gap_clear])
	if not other_calm_reached:
		trace.note("contact", "with the park cordoned off, no other calm ground is reached "
				+ "from home")
	return best

## The stretches a gap at stretch `k` is: `k`, and the stretch before it when that one needs tape
## on the same side.
func _gap_of(k: int) -> Array[Stretch]:
	var found: Array[Stretch] = [stretches[k]]
	var before := stretches[posmod(k - 1, stretches.size())]
	if before.needed and before.outward == stretches[k].outward and before != stretches[k]:
		found.append(before)
	return found

## Where the gap at stretch `k` is, on the line: the boundary between its two stretches, or the
## middle of its one.
func _gap_point(k: int) -> Vector2:
	var stretch := stretches[k]
	if _gap_of(k).size() > 1:
		return stretch.a
	return (stretch.a + stretch.b) * 0.5

## The point a tile out from the middle of a stretch, on the ground outside the park.
func _point_outside(stretch: Stretch) -> Vector2:
	return (stretch.a + stretch.b) * 0.5 + Vector2(stretch.outward) * Tuning.TILE_SIZE

## Walking distance from home over the day's obstruction with the park's own ground blocked, as the
## cordon leaves it.
func _ground_outside() -> PackedInt32Array:
	var blocked := _blocked.duplicate()
	for tile in _map.rect_tiles(_rect):
		blocked[tile] = true
	return _map.walk_field(_map.home_rect.position, blocked)

## Whether the ground outside a stretch — the tile beyond each of its edge tiles — reaches home.
func _outside_reaches(stretch: Stretch, ground: PackedInt32Array) -> bool:
	for tile in stretch.tiles:
		var out := tile + stretch.outward
		if _map.in_bounds(out) and _map.reaches(ground, out):
			return true
	return false

## Whether `point` stands clear of everything the day put down that bounds or bites: farther from
## each body than its obstruction and her whole shape (`HER_REACH`), and outside the field of any
## body that carries one (a car crash's, which is there to stop her walking past it) and the
## lethal reach of anything that ends the day. The park's own people are not asked: they are being
## walked out.
func _clear_of_the_day(point: Vector2) -> bool:
	if not _city or not _city.events:
		return true
	for plan in _city.events.plans():
		if plan.spent or not plan.is_placed() or area.has_point(plan.position):
			continue
		var def := plan.def
		if def.obstructs_radius <= 0.0 and not def.hard_fail:
			continue
		var reach := def.obstructs_radius + HER_REACH
		if def.intensity > 0.0:
			reach = maxf(reach, def.field_reach())
		if def.hard_fail:
			reach = maxf(reach, def.lethal_reach() + HER_REACH)
		var at := plan.live.global_position if plan.live and is_instance_valid(plan.live) \
				else plan.position
		if point.distance_to(at) < reach:
			return false
	return true

# -------------------------------------------------------------- setting out ---

## The first frame: the last gap, which way round each taper works to it from the side opposite,
## every officer placed just out of sight, and when the gap is to close.
func _set_out(her: Vector2, shows: Callable) -> void:
	var from := her if her != Vector2.INF else area.get_center()
	var perimeter := _perimeter()
	var meeting := _choose_the_gap(from)
	gap = _gap_of(meeting)
	last_gap = _gap_point(meeting)
	var arrival := _boundary_at(fposmod(_along(last_gap) + perimeter * 0.5, perimeter))
	var count := stretches.size()
	var clockwise := posmod(meeting - arrival, count)
	if clockwise == 0:
		clockwise = count / 2
	var first := Officer.new()
	var second := Officer.new()
	for i in clockwise:
		first.stretches.append(stretches[(arrival + i) % count])
	for i in count - clockwise:
		second.stretches.append(stretches[posmod(arrival - 1 - i, count)])
	second.forward = false
	var start: Stretch = stretches[arrival]
	var door := _outside(start.a, start.outward)
	var spawn := _spawn_out_of_sight(door, start.outward, from, shows)
	var spawn_at: Vector2 = spawn[0]
	var away: Vector2 = spawn[1]
	var kerb: Vector2 = spawn[2]
	for officer: Officer in [first, second]:
		officer.job = Officer.Job.TAPE
		officer.phase = Officer.Phase.APPROACH
		officer.speed = Tuning.PARK_CLOSING_OFFICER_SPEED
		var behind := TAPER_SPACING if officer == second else 0.0
		officer.at = spawn_at + away * behind
		officer.path = PackedVector2Array([kerb, door])
		officers.append(officer)
		_make_figure(officer)
	_exit = _way_out_through_the_gap(her, shows)
	_send_escorts()
	_time_the_close(her, shows)
	trace.note("contact", "the police set out to cordon the park at block %s: %d stretches, "
			% [park, _needed_count()] + "the last gap at %s, closing %.1fs after the swing"
			% [last_gap, deadline])

func _needed_count() -> int:
	var count := 0
	for stretch in stretches:
		if stretch.needed:
			count += 1
	return count

## The point of the line `s` clockwise from the north-west corner.
func _point_at(s: float) -> Vector2:
	var left := s
	for stretch in stretches:
		var length := stretch.length()
		if left <= length:
			return stretch.a.lerp(stretch.b, left / maxf(length, 0.001))
		left -= length
	return stretches[0].a

## **Where an officer comes from**: out from `door` across the sidewalk by a tile, then along that
## sidewalk one way or the other, half a tile at a time, to the first place none of his figure
## would be in the camera's whole view and his feet are on walkable ground — the nearer of the two
## ways. Answers `[spawn, direction from the sidewalk point to it, the sidewalk point]`.
func _spawn_out_of_sight(door: Vector2, outward: Vector2i, her: Vector2,
		shows: Callable) -> Array:
	var kerb := door + Vector2(outward) * Tuning.TILE_SIZE
	var along := Vector2(absf(float(outward.y)), absf(float(outward.x)))
	var best := Vector2.INF
	var best_steps := SEARCH_STEPS + 1
	var best_way := along
	for way: Vector2 in [along, -along]:
		for step in range(1, SEARCH_STEPS + 1):
			var at := kerb + way * SEARCH_STEP * step
			if not _map.is_walkable(_map.world_to_tile(at)) or _seen(at, her, shows):
				continue
			if step < best_steps:
				best_steps = step
				best = at
				best_way = way
			break
	if best == Vector2.INF:
		best = kerb + along * SEARCH_STEP * SEARCH_STEPS
	return [best, best_way, kerb]

## Whether any of an officer's figure standing at `feet` would be seen: `shows` where there is a
## camera, otherwise within `Tuning.OUT_OF_SIGHT` of her.
func _seen(feet: Vector2, her: Vector2, shows: Callable) -> bool:
	if shows.is_valid():
		return bool(shows.call(EventCatalogue.by_id(OFFICER_ROW), feet))
	return her != Vector2.INF and feet.distance_to(her) < Tuning.OUT_OF_SIGHT

# ---------------------------------------------------------------- the timing ---

## **When the last gap closes**: `Tuning.PARK_CLOSING_SECONDS` after the touch, or later where the
## first officer would come into the camera's view of where she stood too late for her to walk from
## there to the gap with `Tuning.PARK_CLOSING_WARNING` to spare. Each taper's whole walk is known
## here — the walk in, then round the edge at the pace that ends it at the deadline — so the point
## of it where he first comes into view is a fraction of it, and the deadline is solved for rather
## than searched: walking in, he is seen at a fixed time; going round, at `t_edge + f·(T − t_edge)`,
## so `T − t_seen ≥ W` needs `T ≥ t_edge + W / (1 − f)`. The earlier of the two tapers sets it.
## A park neither of them comes into view of from where she stood closes on the plain clock, and
## the run log says so. **And never faster than `Tuning.PARK_CLOSING_STRETCH_MIN` a stretch**, the
## floor `_reach_the_edge()` paces to, folded in here so that `deadline` is when the gap closes and
## `first_in_view` is read off that, not off a close the floor then pushes later.
func _time_the_close(her: Vector2, shows: Callable) -> void:
	walk_to_the_gap = her.distance_to(last_gap) / Tuning.WALK_SPEED if her != Vector2.INF \
			else 0.0
	var wanted := walk_to_the_gap + Tuning.PARK_CLOSING_WARNING
	var soonest := INF
	var paced := Tuning.PARK_CLOSING_SECONDS
	# Per taper, `[seen walking in at, reaches the edge at, share of the round walked when seen]`,
	# so when he is first in view can be read off the deadline once it is set.
	var sightings: Array[PackedFloat32Array] = []
	for officer in officers:
		if officer.job != Officer.Job.TAPE:
			continue
		var walk_in := PackedVector2Array([officer.at])
		walk_in.append_array(officer.path)
		var t_edge := _length_of(walk_in) / officer.speed
		paced = maxf(paced, t_edge + Tuning.PARK_CLOSING_STRETCH_MIN * officer.stretches.size())
		var seen := _first_seen_along(walk_in, her, shows)
		if seen >= 0.0:
			sightings.append(PackedFloat32Array([seen / officer.speed, t_edge, 0.0]))
			soonest = minf(soonest, seen / officer.speed + wanted)
			continue
		var round := _round_path(officer)
		var length := _length_of(round)
		seen = _first_seen_along(round, her, shows)
		if seen < 0.0 or length <= 0.0 or seen >= length:
			continue
		var share := seen / length
		sightings.append(PackedFloat32Array([-1.0, t_edge, share]))
		soonest = minf(soonest, t_edge + wanted / (1.0 - share))
	deadline = paced
	first_in_view = INF
	if soonest == INF:
		if her != Vector2.INF:
			trace.note("contact", "no officer of the park's cordon comes into her view from "
					+ "where she stood: it closes on the plain clock")
		return
	deadline = maxf(deadline, soonest)
	for sighting in sightings:
		var at := sighting[0] if sighting[0] >= 0.0 \
				else sighting[1] + sighting[2] * (deadline - sighting[1])
		first_in_view = minf(first_in_view, at)

## The distance along `points` at which an officer standing there would first be seen, or -1.
func _first_seen_along(points: PackedVector2Array, her: Vector2, shows: Callable) -> float:
	var walked := 0.0
	for i in range(1, points.size()):
		var from := points[i - 1]
		var length := from.distance_to(points[i])
		var steps := maxi(1, ceili(length / SIGHT_STEP))
		for j in steps + 1:
			var at := from.lerp(points[i], float(j) / steps)
			if _seen(at, her, shows):
				return walked + length * float(j) / steps
		walked += length
	if points.size() == 1 and _seen(points[0], her, shows):
		return 0.0
	return -1.0

static func _length_of(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total

## A taper's whole walk round the edge, from where he reaches it: beside each of his stretches in
## turn, and round the outside of every corner between two of them — the walk `_begin_stretch()`
## lays a stretch at a time.
func _round_path(officer: Officer) -> PackedVector2Array:
	var at := officer.path[officer.path.size() - 1] if not officer.path.is_empty() else officer.at
	var points := PackedVector2Array([at])
	for stretch in officer.stretches:
		var on_the_line := _start_of(officer, stretch)
		var start := _outside(on_the_line, stretch.outward)
		if at.distance_to(start) > 1.0:
			points.append(at + (start - on_the_line))
			points.append(start)
		at = _outside(_end_of(officer, stretch), stretch.outward)
		points.append(at)
	return points

# ------------------------------------------------------------ the way out ---

## **The way out through the last gap**: from inside it, across the line square to it, then over
## the ground outside — never the park's own, never anything the day has blocked — to the nearest
## place neither out of her sight nor nearer her than `Tuning.OUT_OF_SIGHT` would be, by sidewalk
## where the sidewalk gets there and across the road where it does not. What the park's people
## leave by and their escorts come in by.
func _way_out_through_the_gap(her: Vector2, shows: Callable) -> PackedVector2Array:
	var outward := Vector2(gap[0].outward)
	var points := PackedVector2Array([last_gap - outward * GAP_INSIDE,
			last_gap + outward * OFFICER_OUTSIDE])
	var edge := _map.world_to_tile(last_gap)
	edge.x = clampi(edge.x, _rect.position.x, _rect.end.x - 1)
	edge.y = clampi(edge.y, _rect.position.y, _rect.end.y - 1)
	points.append_array(_route_away(edge + gap[0].outward, her, shows))
	return points

## Tile centres from `start` to the nearest tile out of her sight, as `_way_out_through_the_gap()`
## says, with the straight runs between corners dropped. Just `start` when it already is.
func _route_away(start: Vector2i, her: Vector2, shows: Callable) -> PackedVector2Array:
	var found := _search_away(start, her, shows, false)
	if found.is_empty():
		found = _search_away(start, her, shows, true)
	if found.is_empty():
		return PackedVector2Array([_map.tile_to_world(start)])
	var points := PackedVector2Array()
	for i in found.size():
		var keep := i == 0 or i == found.size() - 1 \
				or found[i] - found[i - 1] != found[i + 1] - found[i]
		if keep:
			points.append(_map.tile_to_world(found[i]))
	return points

## A breadth-first search from `start` over ground an officer may stand on (`CityMap.passable()`)
## outside the park and clear of the day's obstruction, roads only when `roads`, to the first tile
## out of her sight. The tiles of the way
## there, or empty when none is found within `ROUTE_SEARCH_LIMIT`.
func _search_away(start: Vector2i, her: Vector2, shows: Callable,
		roads: bool) -> Array[Vector2i]:
	var came_from := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size() and head < ROUTE_SEARCH_LIMIT:
		var tile := queue[head]
		head += 1
		var centre := _map.tile_to_world(tile)
		var far := her == Vector2.INF or centre.distance_to(her) >= Tuning.OUT_OF_SIGHT
		if far and not _seen(centre, her, shows):
			var route: Array[Vector2i] = [tile]
			while route[0] != start:
				route.push_front(came_from[route[0]])
			return route
		for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next := tile + step
			if came_from.has(next) or not _may_walk(next, roads):
				continue
			came_from[next] = tile
			queue.append(next)
	return []

func _may_walk(tile: Vector2i, roads: bool) -> bool:
	if not _map.in_bounds(tile) or not _map.passable(tile, _officer_walks) \
			or _rect.has_point(tile) or _blocked.has(tile):
		return false
	return roads or _map.tile_at(tile) != GameEnums.TileType.ROAD

## The way out from `from`, in order: all of `_exit` from inside the park, by way of the gap, or
## from its point nearest `from` for someone already outside it, who is not walked back in.
func _way_out_from(from: Vector2) -> PackedVector2Array:
	if line.grow(WALKER_REACH).has_point(from) or _exit.is_empty():
		return PackedVector2Array(_exit)
	var nearest := INF
	var start := 0
	for i in _exit.size():
		if _exit[i].distance_to(from) < nearest:
			nearest = _exit[i].distance_to(from)
			start = i
	return _exit.slice(start)

## `_exit` walked the other way, from its far end in through the gap: an escort's way in.
func _way_in() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(_exit.size() - 1, -1, -1):
		points.append(_exit[i])
	return points

# ------------------------------------------------------------- the park's people ---

## One escort to each person standing in the park, up to `Tuning.PARK_CLOSING_ESCORTS`, the rest
## sent off at once; what the day planned in the park that has not streamed in is taken out of it.
## A person is anything live in the park that stands or strolls there: not the playground (an
## ambient row with no figure), and not anything that came for her or drives (a pursuer, a car).
## Each escort comes in along the way out, from its far end, which is out of her sight.
func _send_escorts() -> void:
	if not _city or not _city.events:
		return
	for plan in _city.events.plans():
		if plan.spent or plan.live or not plan.is_placed() or not area.has_point(plan.position):
			continue
		if plan.def.kind == GameEnums.EventKind.AMBIENT:
			continue
		# Not in the world yet, and out of her sight by construction (it would be streamed in
		# otherwise): the same removal `EventManager.take_away_within()` makes of a plan.
		plan.spent = true
		_map.release_obstruction(plan.get_instance_id())
	var sent := 0
	for live in _city.events.instances():
		if not _walks_out(live):
			continue
		if live.is_leaving or sent >= Tuning.PARK_CLOSING_ESCORTS:
			_send_off(live)
			continue
		var escort := Officer.new()
		escort.job = Officer.Job.ESCORT
		escort.phase = Officer.Phase.WAITING
		escort.wait = sent * TAPER_SPACING / Tuning.PARK_CLOSING_OFFICER_SPEED
		escort.speed = Tuning.PARK_CLOSING_OFFICER_SPEED
		escort.person = live
		escort.at = _exit[_exit.size() - 1]
		escort.path = _way_in()
		escort.path.append(live.global_position)
		officers.append(escort)
		_make_figure(escort)
		sent += 1
	if sent > 0 or not _leaving.is_empty():
		trace.note("contact", "%d officers come to walk the park's people out, %d more sent off "
				% [sent, _leaving.size()] + "on their own, through the last gap")

## Whether a live event is one of the park's people, to be walked out.
func _walks_out(live: EventInstance) -> bool:
	if not live or not is_instance_valid(live) or live.is_finished:
		return false
	if not area.has_point(live.global_position):
		return false
	var def := live.def
	return def.kind != GameEnums.EventKind.AMBIENT and not def.pursues and not def.drives \
			and not def.warned_first and not def.arrives_chasing

## Sends one person in the park off on foot, out through the last gap and down the way out
## (`EventInstance.leave_along()`: no field and no cue, and gone only once she could not be
## watching, never at the way's end), or the manager's own retirement for one that cannot leave. One
## already leaving on their own is turned onto the way rather than left to walk straight away from
## her, through the tape. A row that stands where it was placed has no departure of its own, so it
## walks out at `Tuning.PARK_CLOSING_LEAVE_SPEED`.
func _send_off(person: EventInstance) -> void:
	if not person or not is_instance_valid(person) or person.is_finished or _leaving.has(person):
		return
	var speed := Tuning.PARK_CLOSING_LEAVE_SPEED if person.def.departure_speed() <= 0.0 else 0.0
	if not person.leave_along(_way_out_from(person.global_position), speed, _rect):
		if _city and _city.events:
			_city.events.retire(person)
		return
	_leaving.append(person)

# ----------------------------------------------------------------- walking ---

func _move(officer: Officer, delta: float, her: Vector2, shows: Callable) -> void:
	match officer.phase:
		Officer.Phase.WAITING:
			officer.wait -= delta
			if officer.wait <= 0.0:
				officer.phase = Officer.Phase.APPROACH
		Officer.Phase.APPROACH:
			if officer.job == Officer.Job.ESCORT:
				_approach_the_person(officer, delta, her)
			elif _walk_path(officer, officer.speed * delta):
				_reach_the_edge(officer)
		Officer.Phase.TAPING:
			_tape(officer, delta, her)
		Officer.Phase.ESCORTING:
			_escort(officer, delta, her, shows)
		Officer.Phase.LEAVING:
			_walk_path(officer, officer.speed * delta)
			_maybe_gone(officer, her, shows)
	_show(officer)

## Walks `step` pixels down the officer's path, dropping each point he reaches. True once the path
## is walked.
func _walk_path(officer: Officer, step: float) -> bool:
	return _walk_path_for(officer, step) >= 0.0

## `_walk_path()`, answering what is left of `step` once the path is walked, or -1 while it is not,
## so a taper goes on into his next stretch in the same frame rather than losing the rest of it at
## every stretch's end, which over a large park's forty-odd stretches makes the close late.
##
## **Not through the navigator**: an officer's walk in and a taper's walk round the park's edge are
## laid straight, at a fixed offset outside it, through whatever the day stands there — a band on
## the park's sidewalk, a figure in the park — and the close is timed and its pace set over those
## straight walks (`_round_path()`, the cordon's own timing). Stopped by what stops her, an officer
## stalls at such a body, or goes round it and the last gap closes late, so the walks have to be
## planned round the bodies before they can be walked round them. His way out and an escort's are
## searched over ground he may stand on (`_may_walk()`).
func _walk_path_for(officer: Officer, step: float) -> float:
	var left := step
	while left > 0.0 and not officer.path.is_empty():
		var to := officer.path[0]
		var gap_left := officer.at.distance_to(to)
		if gap_left > 0.001:
			officer.heading = (to - officer.at) / gap_left
		if gap_left <= left:
			officer.at = to
			left -= gap_left
			officer.path.remove_at(0)
		else:
			officer.at += officer.heading * left
			left = 0.0
	return left if officer.path.is_empty() else -1.0

## A taper at the edge: his pace round it is set so his last stretch is taped at `deadline`,
## counting the corners he walks round — so the two finish together and the last gap closes then —
## never faster than `Tuning.PARK_CLOSING_STRETCH_MIN` a stretch.
func _reach_the_edge(officer: Officer) -> void:
	officer.phase = Officer.Phase.TAPING
	if officer.stretches.is_empty():
		return
	var left := maxf(deadline - elapsed,
			Tuning.PARK_CLOSING_STRETCH_MIN * officer.stretches.size())
	officer.tape_speed = _length_of(_round_path(officer)) / left
	_plant_a_post(_start_of(officer, officer.stretches[0]))
	_begin_stretch(officer)

func _start_of(officer: Officer, stretch: Stretch) -> Vector2:
	return stretch.a if officer.forward else stretch.b

func _end_of(officer: Officer, stretch: Stretch) -> Vector2:
	return stretch.b if officer.forward else stretch.a

## Lays the walk along the officer's next stretch, by the outside of the corner when it turns one.
func _begin_stretch(officer: Officer) -> void:
	var stretch := officer.stretches[officer.next]
	var on_the_line := _start_of(officer, stretch)
	var start := _outside(on_the_line, stretch.outward)
	officer.path = PackedVector2Array()
	if officer.at.distance_to(start) > 1.0:
		# He is beside the corner on the side he has just finished: round it by its outside, out
		# from the corner by both sides' offsets at once.
		officer.path.append(officer.at + (start - on_the_line))
		officer.path.append(start)
	officer.path.append(_outside(_end_of(officer, stretch), stretch.outward))

func _tape(officer: Officer, delta: float, her: Vector2) -> void:
	var left := officer.tape_speed * delta
	while officer.next < officer.stretches.size():
		left = _walk_path_for(officer, left)
		if left < 0.0:
			return
		var stretch := officer.stretches[officer.next]
		if stretch.needed and not stretch.taped:
			officer.holding = _in_the_way(stretch, her) \
					or (gap.has(stretch) and _still_to_come_out())
			if officer.holding:
				return
			_tape_up(stretch)
		_plant_a_post(_end_of(officer, stretch))
		officer.next += 1
		if officer.next < officer.stretches.size():
			_begin_stretch(officer)

## Whether a body centred at `at` reaching `reach` from its centre overlaps where a stretch's tape
## would stand.
static func _body_on(stretch: Stretch, at: Vector2, reach: float = HER_REACH) -> bool:
	if at == Vector2.INF:
		return false
	var on := Geometry2D.get_closest_point_to_segment(at, stretch.a, stretch.b)
	return on.distance_to(at) < reach

## Whether taping `stretch` now would put it through her, one of the park's people walking out, or
## an officer walking them.
func _in_the_way(stretch: Stretch, her: Vector2) -> bool:
	if _body_on(stretch, her):
		return true
	for walker in _walkers():
		if _body_on(stretch, walker, WALKER_REACH):
			return true
	return false

## Where everyone walking out through the gap is: the park's people still leaving and every escort
## not yet gone.
func _walkers() -> PackedVector2Array:
	var found := PackedVector2Array()
	for person in _leaving:
		if is_instance_valid(person) and not person.is_finished \
				and not person.is_queued_for_deletion():
			found.append(person.global_position)
	for officer in officers:
		if officer.job == Officer.Job.ESCORT and officer.phase != Officer.Phase.GONE:
			found.append(officer.at)
	return found

## Whether anyone the cordon is walking out has still to come out through the last gap: an escort
## not yet in, or one inside or at the line — walking someone out, or sent back out alone because
## his person went before he reached them — or one of the park's people there.
func _still_to_come_out() -> bool:
	var at_the_line := line.grow(WALKER_REACH)
	for officer in officers:
		if officer.job != Officer.Job.ESCORT:
			continue
		match officer.phase:
			Officer.Phase.WAITING, Officer.Phase.APPROACH:
				return true
			Officer.Phase.ESCORTING, Officer.Phase.LEAVING:
				if at_the_line.has_point(officer.at):
					return true
	for person in _leaving:
		if is_instance_valid(person) and not person.is_finished \
				and not person.is_queued_for_deletion() \
				and at_the_line.has_point(person.global_position):
			return true
	return false

func _tape_up(stretch: Stretch) -> void:
	stretch.taped = true
	_map.obstruct_tiles(stretch.get_instance_id(), stretch.tiles)
	if not _city:
		return
	var tape := CordonTape.new()
	tape.piece = CordonTape.Piece.TAPE
	tape.across = stretch.across()
	tape.length = stretch.length()
	tape.position = (stretch.a + stretch.b) * 0.5 if tape.across \
			else Vector2(stretch.a.x, maxf(stretch.a.y, stretch.b.y))
	stretch.node = tape
	_city.add_entity(tape)

## The posts the tape is strung on, one at every stretch end an officer reaches, never two at one.
var _posts: Array[CordonTape] = []
var _post_points: Array[Vector2] = []

func _plant_a_post(at: Vector2) -> void:
	for point in _post_points:
		if point.distance_to(at) < 1.0:
			return
	_post_points.append(at)
	if not _city:
		return
	var post := CordonTape.new()
	post.piece = CordonTape.Piece.POST
	post.position = at
	_posts.append(post)
	_city.add_entity(post)

## An escort on his way in, along the way out from its far end and through the gap, then to his
## person, whom he sends off once he reaches them.
func _approach_the_person(officer: Officer, delta: float, her: Vector2) -> void:
	var person := officer.person
	if not person or not is_instance_valid(person) or person.is_finished:
		_leave(officer)
		return
	# Someone who set off on their own before he reached them is turned onto the way out at once,
	# and he walks out behind them from where he is.
	var already := person.is_leaving and not _leaving.has(person)
	if not officer.path.is_empty():
		officer.path[officer.path.size() - 1] = person.global_position
	if not already:
		_walk_path(officer, officer.speed * delta)
	if already or officer.at.distance_to(person.global_position) <= ESCORT_REACH:
		_send_off(person)
		officer.phase = Officer.Phase.ESCORTING
		officer.path = _way_out_from(officer.at)

## Walks out behind the person he sent off, down the same way, never nearer them along it than
## `ESCORT_BEHIND` — measured along the way rather than straight, so he stays behind them rather
## than passing them, he being the faster; once they are gone he walks on and is gone once out of
## her sight.
func _escort(officer: Officer, delta: float, her: Vector2, shows: Callable) -> void:
	var person := officer.person
	if not person or not is_instance_valid(person) or person.is_finished \
			or person.is_queued_for_deletion():
		officer.phase = Officer.Phase.LEAVING
		_maybe_gone(officer, her, shows)
		return
	var points := PackedVector2Array([officer.at])
	points.append_array(officer.path)
	var theirs := PackedVector2Array([person.global_position])
	theirs.append_array(person.way_left())
	var room := _length_of(points) - _length_of(theirs) - ESCORT_BEHIND
	if room > 0.0:
		_walk_path(officer, minf(officer.speed * delta, room))

## The last gap is taped: she is shut in if she is inside the line. Every officer then walks off.
func _close(her: Vector2, shows: Callable) -> void:
	closed_at = elapsed
	trapped = her != Vector2.INF and line.has_point(her)
	if _city and _city.events:
		_city.events.take_away_within(area, ["playground"] as Array[String])
	for officer in officers:
		if officer.job == Officer.Job.TAPE:
			officer.phase = Officer.Phase.LEAVING
			var from := _map.world_to_tile(officer.at)
			officer.path = _route_away(from, her, shows) if not _rect.has_point(from) \
					else PackedVector2Array()
	if trapped:
		trace.note("contact", "the last gap of the park's cordon is taped %.1fs after the "
				% elapsed + "swing, with her inside: she is shut in")
		EventBus.hard_fail_triggered.emit(TRAPPED)
	else:
		trace.note("contact", "the park at block %s is cordoned off %.1fs after the swing, "
				% [park, elapsed] + "with her outside")

## Sends an escort whose person has gone before he reached them back down the way out, past
## where she can see: from inside the gap if he is in the park, else from its point nearest him.
func _leave(officer: Officer) -> void:
	officer.phase = Officer.Phase.LEAVING
	officer.path = _way_out_from(officer.at)

## An officer on his way is gone once none of him could be seen.
func _maybe_gone(officer: Officer, her: Vector2, shows: Callable) -> void:
	if officer.phase == Officer.Phase.GONE or _seen(officer.at, her, shows):
		return
	if not shows.is_valid() and her == Vector2.INF and not officer.path.is_empty():
		return
	officer.phase = Officer.Phase.GONE
	_free_figure(officer)

# ------------------------------------------------------------------ figures ---

func _make_figure(officer: Officer) -> void:
	if not _city:
		return
	var figure := CordonOfficer.new()
	figure.position = officer.at
	officer.node = figure
	_city.add_entity(figure)

func _show(officer: Officer) -> void:
	var figure := officer.node
	if not figure or not is_instance_valid(figure):
		return
	var moved := figure.position.distance_to(officer.at)
	figure.position = officer.at
	figure.walk(officer.heading, moved)

func _free_figure(officer: Officer) -> void:
	if officer.node and is_instance_valid(officer.node):
		officer.node.queue_free()
	officer.node = null
