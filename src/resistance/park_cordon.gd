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
##   sidewalk along the side of the park farthest from her (`_spawn_out_of_sight()`: everything
##   the policeman's figure draws wholly outside the camera's whole view, the test
##   `ResistanceDirector._drawing_shows()` answers, so nothing is seen to appear) and walk in to
##   the park's edge. Their arrival is the warning: nothing about them telegraphs under the cue
##   rules, since they walk and come toward nobody (`docs/EVENTS.md`, "What telegraphs"), so no
##   screen-edge badge goes up for them.
## - **They tape the edge one stretch at a time, working round it from where they arrived**, one
##   each way, so the open part of the edge shrinks to a last gap at the point of the edge nearest
##   where she stood when they started — the way out she is most likely to take. A stretch is one
##   tile of a side's edge, more or less; the tape stands on the park's own edge row, half a
##   barrier's depth in (`ParkClosure`'s fence line, the late park's fence, which it matches), and
##   **a taped stretch is solid** (`CordonTape`'s static body), so the last gap is the only way out.
##   An officer whose next stretch she is standing in waits beside it until she has stepped off it,
##   so the tape never goes up through her.
## - **Other officers walk the park's people out**: up to `Tuning.PARK_CLOSING_ESCORTS`, one to
##   each event standing in the park when it starts, who walks to them, sends them off
##   (`EventInstance.leave_for_a_completed_task()`, the ordinary departure) and walks out after
##   them. What the day planned in the park that has not streamed in yet is taken out of the day.
##   The crowd never walks a park, so it has no part in this.
## - **If the last gap is taped while she is inside the tape, the day ends**: she is shut in the
##   park, a hard fail of its own (`TRAPPED`, `DayController`'s sentence for it). Nothing else about
##   the cordon costs her anything: the officers are not pursuers, catch nobody and carry no field.
## - **The ground stays grass.** What took the park's calm is `CityMap.recompute_calm()` at the
##   touch, as before; the tape is what keeps her from settling the baby in it afterwards.
##
## **Timing.** The taping is paced so the last gap closes `Tuning.PARK_CLOSING_SECONDS` after the
## touch, whatever the walk in took, but never faster than `Tuning.PARK_CLOSING_STRETCH_MIN` a
## stretch — so a long walk in makes the closing later rather than the taping a sprint.
## Walking from the swing to the edge nearest it takes about two seconds on any park the generator
## builds, so walking, not only running, gets her out; `tests/test_park_cordon.gd` holds that
## with her walking out from the swing, and holds being shut in with her standing at it.
##
## **Deterministic from the moment she touched the swing**: nothing here draws a random number.

## The row whose drawing an officer is — the policeman on foot's (`art/events/policeman_*`) — asked
## of `shows` for where an officer may be placed, so nothing of him is seen to appear.
const OFFICER_ROW := "policeman_giving_chase"
## The hard fail being shut in the park sends, and the name the day's end and the page's counter
## give it (`DayController._HARD_FAIL_TEXT`, `main._hard_fail_cause_suffix()`).
const TRAPPED := "park_cordon"
## How far outside the tape the officers walk round it, off the park's own ground and on the
## sidewalk's edge, so they finish outside the cordon they made.
const OFFICER_OUTSIDE := 16.0
## How far apart the two tapers walk in, one behind the other.
const TAPER_SPACING := 18.0
## How near an escort comes to the person he walks out before sending them off.
const ESCORT_REACH := 20.0
## How far behind the person an escort walks once they are leaving.
const ESCORT_BEHIND := 16.0
## The steps a search for an out-of-sight place along a sidewalk takes, and how many it takes at
## most each way.
const SEARCH_STEP := Tuning.TILE_SIZE * 0.5
const SEARCH_STEPS := 80

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
	## A taper's stretches, in the order he tapes them, and which way he walks each.
	var stretches: Array[Stretch] = []
	var forward := true
	var next := 0
	## Whether he is standing beside a stretch she is in, waiting for her to step off it.
	var holding := false
	## An escort's person.
	var person: EventInstance = null
	var node: CordonOfficer = null

var _map: CityMap
var _city: City
## The park, as its block, and its calm ground in world space.
var park := Vector2i(-1, -1)
var area := Rect2()
## The rectangle the tape stands on: the park's ground, half a barrier's depth in. She is shut in
## when she is inside it as the last gap is taped.
var line := Rect2()
var stretches: Array[Stretch] = []
var officers: Array[Officer] = []
## Seconds since she touched the swing.
var elapsed := 0.0
## The moment the last gap was taped, and whether she was inside it then. Kept for the tests.
var closed_at := -1.0
var trapped := false
## The point of the line nearest her when the officers set out, where the last gap closes.
var last_gap := Vector2.INF
## The taping pace, set when the first taper reaches the edge.
var _tape_speed := 0.0
var _started := false

## Starts closing `block`'s park: the line, its stretches and which of them need tape. Nothing is
## placed until the first `tick()`, which knows where she is and what the camera sees.
func _init(map: CityMap, city: City, block: Vector2i) -> void:
	_map = map
	_city = city
	park = block
	var rect := ClosurePlanner.calm_area_rect(map, block)
	area = map.tile_rect_to_world(rect)
	var inset := Tuning.CLOSURE_BARRIER_DEPTH * 0.5
	line = area.grow(-inset)
	_cut_the_stretches(rect)

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
		_close(her)

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

# -------------------------------------------------------------- setting out ---

## The first frame: which way round each taper works, from the point of the line farthest from her
## to the point nearest her, and every officer placed just out of sight.
func _set_out(her: Vector2, shows: Callable) -> void:
	var from := her if her != Vector2.INF else area.get_center()
	var perimeter := _perimeter()
	var hers := _along(from)
	last_gap = _point_at(hers)
	var arrival := _boundary_at(fposmod(hers + perimeter * 0.5, perimeter))
	var meeting := _boundary_at(hers)
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
	_send_escorts(from, shows)
	Telemetry.note("contact", "the police set out to cordon the park at block %s: %d stretches, "
			% [park, _needed_count()] + "the last gap nearest her at %s" % last_gap)

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

## One escort to each person standing in the park, up to `Tuning.PARK_CLOSING_ESCORTS`, the rest
## sent off at once; what the day planned in the park that has not streamed in is taken out of it.
## A person is anything live in the park that stands or strolls there: not the playground (an
## ambient row with no figure), and not anything that came for her or drives (a pursuer, a car).
func _send_escorts(her: Vector2, shows: Callable) -> void:
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
		if sent >= Tuning.PARK_CLOSING_ESCORTS:
			_send_off(live)
			continue
		sent += 1
		var escort := Officer.new()
		escort.job = Officer.Job.ESCORT
		escort.phase = Officer.Phase.APPROACH
		escort.speed = Tuning.PARK_CLOSING_OFFICER_SPEED
		escort.person = live
		var at := _along(live.global_position)
		var stretch := stretches[_boundary_at(at)]
		var door := _outside(_point_at(at), stretch.outward)
		var spawn := _spawn_out_of_sight(door, stretch.outward, her, shows)
		var spawn_at: Vector2 = spawn[0]
		var kerb: Vector2 = spawn[2]
		escort.at = spawn_at
		escort.path = PackedVector2Array([kerb, door, live.global_position])
		officers.append(escort)
		_make_figure(escort)

## Whether a live event is one of the park's people, to be walked out.
func _walks_out(live: EventInstance) -> bool:
	if not live or not is_instance_valid(live) or live.is_finished or live.is_leaving:
		return false
	if not area.has_point(live.global_position):
		return false
	var def := live.def
	return def.kind != GameEnums.EventKind.AMBIENT and not def.pursues and not def.drives \
			and not def.warned_first and not def.arrives_chasing

## Sends one person in the park off on foot: the ordinary departure a finished task gives
## (`EventInstance.leave_for_a_completed_task()`, away from her, with no field and no cue, gone
## once out of her sight), or the manager's own retirement for one that cannot take it.
##
## **A row that stands where it was placed has no departure of its own** — `EventDef.
## departure_speed()` is zero for it, and `EventInstance._be_done()` then simply ends it, which in
## her view is a vanishing. So such a person is handed a copy of their own row that walks off at
## `Tuning.PARK_CLOSING_LEAVE_SPEED` (`EventDef.departs_at`, the field the warned neighbor runs
## by), the same picture and body, before being sent. The copy carries `shape` and `solid_parts`
## over by hand, since `Resource.duplicate()` does not (`ResistanceHappenings._maybe_raid()`'s
## patrol does the same). A hook on `EventInstance` for leaving on foot would replace this.
func _send_off(person: EventInstance) -> void:
	if not person or not is_instance_valid(person) or person.is_finished or person.is_leaving:
		return
	if person.def.departure_speed() <= 0.0:
		var walking: EventDef = person.def.duplicate()
		walking.shape = person.def.shape
		walking.solid_parts = person.def.solid_parts
		walking.departs_at = Tuning.PARK_CLOSING_LEAVE_SPEED
		person.def = walking
	person.leave_for_a_completed_task()
	if not person.is_leaving and _city and _city.events:
		_city.events.retire(person)

# ----------------------------------------------------------------- walking ---

func _move(officer: Officer, delta: float, her: Vector2, shows: Callable) -> void:
	match officer.phase:
		Officer.Phase.APPROACH:
			if officer.job == Officer.Job.ESCORT:
				_approach_the_person(officer, delta)
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
	var left := step
	while left > 0.0 and not officer.path.is_empty():
		var to := officer.path[0]
		var gap := officer.at.distance_to(to)
		if gap > 0.001:
			officer.heading = (to - officer.at) / gap
		if gap <= left:
			officer.at = to
			left -= gap
			officer.path.remove_at(0)
		else:
			officer.at += officer.heading * left
			left = 0.0
	return officer.path.is_empty()

## A taper at the edge: the taping pace is set the first time one gets there, so the last gap
## closes `Tuning.PARK_CLOSING_SECONDS` after the touch, never faster than
## `Tuning.PARK_CLOSING_STRETCH_MIN` a stretch.
func _reach_the_edge(officer: Officer) -> void:
	officer.phase = Officer.Phase.TAPING
	if _tape_speed <= 0.0:
		var longest := 0.0
		var most := 1
		for each in officers:
			if each.job != Officer.Job.TAPE:
				continue
			var length := 0.0
			for stretch in each.stretches:
				length += stretch.length()
			longest = maxf(longest, length)
			most = maxi(most, each.stretches.size())
		var left := maxf(Tuning.PARK_CLOSING_SECONDS - elapsed,
				Tuning.PARK_CLOSING_STRETCH_MIN * most)
		_tape_speed = longest / left
	if officer.stretches.is_empty():
		return
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
	if officer.next >= officer.stretches.size():
		return
	if not _walk_path(officer, _tape_speed * delta):
		return
	var stretch := officer.stretches[officer.next]
	if stretch.needed and not stretch.taped:
		officer.holding = _in_the_way(stretch, her)
		if officer.holding:
			return
		_tape_up(stretch)
	_plant_a_post(_end_of(officer, stretch))
	officer.next += 1
	if officer.next < officer.stretches.size():
		_begin_stretch(officer)

## Whether her body overlaps where a stretch's tape would stand.
static func _body_on(stretch: Stretch, her: Vector2) -> bool:
	if her == Vector2.INF:
		return false
	var on := Geometry2D.get_closest_point_to_segment(her, stretch.a, stretch.b)
	return on.distance_to(her) < Tuning.PLAYER_BODY_RADIUS + CordonTape.DEPTH * 0.5 + 2.0

func _in_the_way(stretch: Stretch, her: Vector2) -> bool:
	return _body_on(stretch, her)

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

func _approach_the_person(officer: Officer, delta: float) -> void:
	var person := officer.person
	if not person or not is_instance_valid(person) or person.is_finished:
		_leave(officer, Vector2.INF)
		return
	if officer.path.size() == 1:
		officer.path[0] = person.global_position
	_walk_path(officer, officer.speed * delta)
	if officer.at.distance_to(person.global_position) <= ESCORT_REACH:
		_send_off(person)
		officer.phase = Officer.Phase.ESCORTING
		officer.path = PackedVector2Array()

## Walks after the person he sent off, `ESCORT_BEHIND` behind, until they are gone; then leaves.
func _escort(officer: Officer, delta: float, her: Vector2, shows: Callable) -> void:
	var person := officer.person
	if not person or not is_instance_valid(person) or person.is_queued_for_deletion():
		officer.path = PackedVector2Array([officer.at + officer.heading * Tuning.OUT_OF_SIGHT * 2.0])
		officer.phase = Officer.Phase.LEAVING
		_maybe_gone(officer, her, shows)
		return
	var to := person.global_position
	var gap := officer.at.distance_to(to)
	if gap > 0.001:
		officer.heading = (to - officer.at) / gap
	var step := minf(maxf(gap - ESCORT_BEHIND, 0.0), Tuning.PARK_CLOSING_OFFICER_SPEED * 1.5 * delta)
	officer.at += officer.heading * step

## The last gap is taped: she is shut in if she is inside the line. Every officer then walks off.
func _close(her: Vector2) -> void:
	closed_at = elapsed
	trapped = her != Vector2.INF and line.has_point(her)
	if _city and _city.events:
		_city.events.take_away_within(area, ["playground"] as Array[String])
	for officer in officers:
		if officer.job == Officer.Job.TAPE:
			_leave(officer, her)
	if trapped:
		Telemetry.note("contact", "the last gap of the park's cordon is taped %.1fs after the swing, "
				% elapsed + "with her inside: she is shut in")
		EventBus.hard_fail_triggered.emit(TRAPPED)
	else:
		Telemetry.note("contact", "the park at block %s is cordoned off %.1fs after the swing, "
				% [park, elapsed] + "with her outside")

## Sends an officer off: out to the sidewalk and along it, away from her, past where she can see.
func _leave(officer: Officer, her: Vector2) -> void:
	officer.phase = Officer.Phase.LEAVING
	var outward := Vector2(_side_of(officer.at))
	var kerb := officer.at + outward * Tuning.TILE_SIZE
	var along := Vector2(absf(outward.y), absf(outward.x))
	if her != Vector2.INF and along.dot(kerb - her) < 0.0:
		along = -along
	officer.path = PackedVector2Array([kerb, kerb + along * Tuning.OUT_OF_SIGHT * 2.0])

## Which side of the park a point outside it is beside, as the way out.
func _side_of(point: Vector2) -> Vector2i:
	var centre := area.get_center()
	var offset := (point - centre) / (area.size * 0.5)
	if absf(offset.x) >= absf(offset.y):
		return Vector2i.RIGHT if offset.x > 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if offset.y > 0.0 else Vector2i.UP

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
