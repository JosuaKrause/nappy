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
## - **They walk round what the day stands in their way**, as every figure does: each officer's
##   walk is laid round the day's bodies on the map's blocked record before he sets off
##   (`_lay()`, over the navigator's way round), and walked through the navigator he was handed
##   (`Navigator.walk()`), so a band on the park's sidewalk or a figure in the park stops him as it
##   stops her. Laying the walk first is what keeps the close on time: the close is timed and each
##   taper paced over the walk he will take, detours included.
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
## How near the person he walks out an escort's way up to them ends, tile centre to them, where
## their own body takes the ground they stand on: a tile and a half, so the tiles beside theirs,
## corners included, all qualify and the nearest by the way wins.
const BESIDE := Tuning.TILE_SIZE * 1.5
## How far from where his way up to them was laid the person may have gone before an escort lays
## it again.
const REAIM := Tuning.TILE_SIZE * 0.5
## How many tiles round a point a walk is laid through `_standing_point()` looks for ground an
## officer may stand on, when the point itself is under a body.
const STANDING_SEARCH := 3
## How much longer a taper's way round a body outside the park may be than the way along the
## park's own edge row before he takes the edge row: a solid that cuts the sidewalk and the street
## from the park's edge outward, a burst water main's band, leaves no way round outside it short of
## the next block.
const EDGE_ROW_SLACK := Tuning.TILE_SIZE * 4.0
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
	## The tiles his walks never enter: the park's, for a taper, who works round it from outside;
	## none for an escort, who goes in for his person.
	var avoid := Rect2i()
	var speed := 0.0
	## How long a waiting escort stands before he sets off.
	var wait := 0.0
	## A taper's stretches, in the order he tapes them, and which way he walks each.
	var stretches: Array[Stretch] = []
	## A taper's walk along each of his stretches, laid at set-out round the day's bodies
	## (`_lay_the_round()`): the walk from the end of the one before to the end of this one.
	var legs: Array[PackedVector2Array] = []
	## Which of his stretches he tapes at the end of each leg, by index into `stretches`: its own,
	## or none where a later leg of his still steps on its tiles (`_lay_the_round()`).
	var due: Array[PackedInt32Array] = []
	var forward := true
	var next := 0
	## Whether he is standing beside a stretch, waiting for her or the park's people to be clear.
	var holding := false
	## A taper's pace along the edge, set at the start of each leg (`_pace()`), and the most it may
	## be: his whole round at `Tuning.PARK_CLOSING_STRETCH_MIN` a stretch, set when he reaches it.
	var tape_speed := 0.0
	var top_speed := INF
	## An escort's person, and where they stood when his way up to them was laid (`Vector2.INF`
	## while he is still on his way in to the gap).
	var person: EventInstance = null
	var aim := Vector2.INF
	var node: CordonOfficer = null

var _map: CityMap
var _city: City
## The map's navigator, handed in: what every officer's walk is laid by and walked through.
var _navigator: Navigator
## What an officer walks as: a figure on foot (`Mover.on_foot()`), stopped by everything that stops
## her, with no reach ahead of him. His walks keep to tile-centre ways and to the park's edge, where
## a reach would only stop him short of a point beside a solid that his feet can stand on.
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
## The tiles the way out steps on crossing the park's edge, from inside the last gap to outside it.
var _exit_crossing := {}
## The park's people sent off down `_exit`, still walking out.
var _leaving: Array[EventInstance] = []
var _started := false
## How many times an officer met something his walk was not laid round, and had the rest of it
## laid again from where he stood: something solid put down after he set out. Kept for the tests.
var relaid := 0
## Where the cordon writes its own account for the run log; the happenings' trace, handed on as it is
## built.
var trace := RunTrace.new()

## Starts closing `block`'s park: the line, its stretches and which of them need tape. Nothing is
## placed until the first `tick()`, which knows where she is and what the camera sees. `blocked` is
## the day's obstruction the last gap is checked under (`ResistanceDirector`'s `_reach_blocked`).
## `navigator` is the map's (`WorldMap.navigator()`), which the officers walk through.
func _init(map: CityMap, navigator: Navigator, city: City, block: Vector2i,
		blocked: Dictionary = {}) -> void:
	_map = map
	_navigator = navigator
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
		officer.avoid = _rect
		officer.at = spawn_at
		var behind := spawn_at + away * TAPER_SPACING
		if officer == second and _stands(_map.world_to_tile(behind), _rect):
			officer.at = behind
		officer.path = _lay(officer.at, PackedVector2Array([kerb, door]), _rect)
		officer.legs = _lay_the_round(officer)
		officers.append(officer)
		_make_figure(officer)
	_exit = _way_out_through_the_gap(her, shows)
	_exit_crossing = _tiles_along(_exit[0], _exit.slice(1, 2))
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
## would be in the camera's whole view and his feet are on ground he may stand on today, off the
## park's — the nearer of the two ways. Answers `[spawn, direction from the sidewalk point to it,
## the sidewalk point]`.
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
			if not _stands(_map.world_to_tile(at), _rect) or _seen(at, her, shows):
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

## A taper's whole walk round the edge, from where he reaches it: his legs (`_lay_the_round()`) one
## after the other — the walk `_begin_stretch()` hands him a stretch at a time.
func _round_path(officer: Officer) -> PackedVector2Array:
	var points := PackedVector2Array([_edge_reached_at(officer)])
	for leg in officer.legs:
		points.append_array(leg)
	return points

## Where a taper reaches the edge: the end of his walk in.
func _edge_reached_at(officer: Officer) -> Vector2:
	return officer.path[officer.path.size() - 1] if not officer.path.is_empty() else officer.at

## **A taper's walk round the edge, laid at set-out**, one leg a stretch: beside each of his
## stretches in turn, `OFFICER_OUTSIDE` out from the line, and round the outside of every corner
## between two of them, each leg laid round the day's bodies off the park's ground (`_lay()`).
func _lay_the_round(officer: Officer) -> Array[PackedVector2Array]:
	var legs: Array[PackedVector2Array] = []
	var at := _edge_reached_at(officer)
	# Where the straight walk stands, which the corners are measured from; `at` is where the laid
	# walk does, which differs only where a body put a point somewhere else.
	var beside := at
	for stretch in officer.stretches:
		var straight := PackedVector2Array()
		var on_the_line := _start_of(officer, stretch)
		var start := _outside(on_the_line, stretch.outward)
		if beside.distance_to(start) > 1.0:
			# He is beside the corner on the side he has just finished: round it by its outside, out
			# from the corner by both sides' offsets at once.
			straight.append(beside + (start - on_the_line))
			straight.append(start)
		beside = _outside(_end_of(officer, stretch), stretch.outward)
		straight.append(beside)
		var leg := _lay(at, straight, _rect)
		legs.append(leg)
		at = leg[leg.size() - 1]
	officer.due = _when_each_is_taped(officer, legs)
	return legs

## **Which stretches a taper tapes at the end of each leg**: each at the end of its own, unless a
## later leg steps on one of its tiles — a way round a body by the park's edge row, which enters
## the row where the stretch before it ends — and then at the end of the last leg that does, since
## tape is solid and he could not step on it once it is up. Still one gap: the stretches go up in
## his order, several at once.
func _when_each_is_taped(officer: Officer, legs: Array[PackedVector2Array]) -> Array[PackedInt32Array]:
	var stepped_on: Array[Dictionary] = []
	var at := _edge_reached_at(officer)
	for leg in legs:
		var tiles := {_map.world_to_tile(at): true}
		for point in leg:
			tiles[_map.world_to_tile(point)] = true
		stepped_on.append(tiles)
		at = leg[leg.size() - 1]
	var due: Array[PackedInt32Array] = []
	for j in legs.size():
		due.append(PackedInt32Array())
	var last_due := 0
	for k in officer.stretches.size():
		var when := maxi(k, last_due)
		for j in range(k + 1, legs.size()):
			for tile in officer.stretches[k].tiles:
				if stepped_on[j].has(tile):
					when = maxi(when, j)
		due[when].append(k)
		last_due = when
	return due

# ---------------------------------------------------------------- laying walks ---

## **A walk laid round the day's bodies before it is walked**: through `points` from `from`, each
## leg kept straight where the navigator takes the whole of it, and where it does not, the
## navigator's way round to the point (`Navigator.path()`), never entering a tile of `avoid`. A
## point on ground an officer may not stand on gives way to the nearest ground he may
## (`_standing_point()`). Every officer's walk is laid by this before he walks it, so what the
## close is timed and paced over is the walk he takes.
##
## **A taper kept off the park may still cut along its edge row** (`avoid` less its outer ring of
## tiles) where the way round outside is more than `EDGE_ROW_SLACK` longer or there is none: ahead
## of him the edge is not taped yet, so he steps in by it and out again.
##
## `settle` false keeps every point where it is, for the rest of a walk already laid.
func _lay(from: Vector2, points: PackedVector2Array, avoid: Rect2i,
		settle := true) -> PackedVector2Array:
	var laid := PackedVector2Array()
	var at := from
	var inner := avoid.grow(-1) if avoid.has_area() else avoid
	for point in points:
		var to := point
		if settle:
			to = _standing_point(point, avoid)
			if to == point and not _stands(_map.world_to_tile(point), avoid):
				to = _standing_point(point, inner)
		var way := PackedVector2Array()
		if not _walks_whole(at, to):
			way = _navigator.path(at, to, _officer_walks, avoid)
			if inner != avoid:
				var by_the_edge := _navigator.path(at, to, _officer_walks, inner)
				if not by_the_edge.is_empty() and (way.is_empty() or _length_of(way)
						> _length_of(by_the_edge) + EDGE_ROW_SLACK):
					way = by_the_edge
		if way.is_empty():
			way.append(to)
		laid.append_array(way)
		at = to
	return laid

## Whether an officer walks the whole straight line from `from` to `to`.
func _walks_whole(from: Vector2, to: Vector2) -> bool:
	var leg := to - from
	return _navigator.step(from, leg, _officer_walks) == leg

## `point` where an officer may stand on it, otherwise the middle of the nearest tile within
## `STANDING_SEARCH` of it that he may stand on, off `avoid`; `point` itself where none is.
func _standing_point(point: Vector2, avoid: Rect2i) -> Vector2:
	var tile := _map.world_to_tile(point)
	if _stands(tile, avoid):
		return point
	var best := point
	var nearest := INF
	for dy in range(-STANDING_SEARCH, STANDING_SEARCH + 1):
		for dx in range(-STANDING_SEARCH, STANDING_SEARCH + 1):
			var near := tile + Vector2i(dx, dy)
			var centre := _map.tile_to_world(near)
			if centre.distance_to(point) < nearest and _stands(near, avoid):
				nearest = centre.distance_to(point)
				best = centre
	return best

## Whether an officer may stand on `tile` today, off `avoid`.
func _stands(tile: Vector2i, avoid: Rect2i) -> bool:
	return _map.in_bounds(tile) and _map.passable(tile, _officer_walks) \
			and not avoid.has_point(tile)

## **An escort's way up to his person**: straight where he walks the whole of it, otherwise the
## navigator's way round to beside them (`BESIDE`, since their own body takes the ground they stand
## on) and on toward them as far as the ground lets him (`Navigator.trim()`).
func _way_up_to(from: Vector2, to: Vector2) -> PackedVector2Array:
	if _walks_whole(from, to):
		return PackedVector2Array([to])
	var way := _navigator.path(from, to, _officer_walks, Rect2i(), BESIDE)
	if not way.is_empty() and way[way.size() - 1] == to:
		return way
	var last := way[way.size() - 1] if not way.is_empty() else from
	var toward := _navigator.trim(PackedVector2Array([last, to]), _officer_walks)
	if toward.size() > 1:
		way.append(toward[1])
	elif way.is_empty():
		way.append(from)
	return way

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
		escort.path = _lay(escort.at, _way_in(), escort.avoid)
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
## Each step goes through the navigator (`Navigator.walk()`), down a walk laid round the day's
## bodies (`_lay()`), so it is taken whole. **Something solid put down after the walk was laid** —
## nothing on the day's plan, which is on the record before he sets out — cuts the step short; the
## rest of the walk is then laid again from where he stands and walked on in the same frame, so he
## goes round it rather than standing at it.
func _walk_path_for(officer: Officer, step: float) -> float:
	var walked := _navigator.walk(officer.at, officer.path, step, _officer_walks)
	_take_the_walk(officer, walked)
	if not officer.path.is_empty() and walked.travelled < step - 0.001:
		relaid += 1
		officer.path = _lay(officer.at, officer.path, officer.avoid, false)
		walked = _navigator.walk(officer.at, officer.path, step - walked.travelled,
				_officer_walks)
		_take_the_walk(officer, walked)
	return walked.left if officer.path.is_empty() else -1.0

## Puts an officer where a walk ended, facing the way it last went, with the points it did not
## reach left to walk.
func _take_the_walk(officer: Officer, walked: Navigator.Walked) -> void:
	officer.at = walked.at
	officer.path = walked.points
	if walked.toward != Vector2.ZERO:
		officer.heading = walked.toward

## A taper at the edge: his pace round it is set so his last stretch is taped at `deadline`,
## counting the corners and the ways round bodies he walks — so the two finish together and the
## last gap closes then — never faster than `Tuning.PARK_CLOSING_STRETCH_MIN` a stretch.
func _reach_the_edge(officer: Officer) -> void:
	officer.phase = Officer.Phase.TAPING
	if officer.stretches.is_empty():
		return
	officer.top_speed = _length_of(_round_path(officer)) \
			/ (Tuning.PARK_CLOSING_STRETCH_MIN * officer.stretches.size())
	_plant_a_post(_start_of(officer, officer.stretches[0]))
	_begin_stretch(officer)

## Sets a taper's pace for the rest of his round at the start of each leg (`_reach_the_edge()`'s
## rule): the same pace all the way round while nothing holds him, and a quicker one after he has
## waited at a stretch, so the wait is made up rather than added to the close — up to his top
## speed, past which the close comes late.
func _pace(officer: Officer) -> void:
	var rest := PackedVector2Array([officer.at])
	for j in range(officer.next, officer.legs.size()):
		rest.append_array(officer.legs[j])
	var left := deadline - elapsed
	var wanted := _length_of(rest) / left if left > 0.0 else INF
	officer.tape_speed = minf(wanted, officer.top_speed)

func _start_of(officer: Officer, stretch: Stretch) -> Vector2:
	return stretch.a if officer.forward else stretch.b

func _end_of(officer: Officer, stretch: Stretch) -> Vector2:
	return stretch.b if officer.forward else stretch.a

## Hands the officer the walk along his next stretch, laid at set-out (`_lay_the_round()`), and
## his pace for the rest of the round.
func _begin_stretch(officer: Officer) -> void:
	_pace(officer)
	officer.path = officer.legs[officer.next].duplicate()

func _tape(officer: Officer, delta: float, her: Vector2) -> void:
	var left := officer.tape_speed * delta
	while officer.next < officer.stretches.size():
		left = _walk_path_for(officer, left)
		if left < 0.0:
			return
		for k in officer.due[officer.next]:
			var stretch := officer.stretches[k]
			if stretch.needed and not stretch.taped:
				officer.holding = _in_the_way(stretch, her) \
						or (_on_the_way_out(stretch) and _still_to_come_out()) \
						or _another_steps_on(stretch, officer)
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

## Whether a stretch's tape would stand on the way out: it is the last gap, or its tiles take
## ground the way out crosses the edge on (`_exit_crossing`) — tape is solid, so on that ground it
## would shut the gap to anyone still to come out through it.
func _on_the_way_out(stretch: Stretch) -> bool:
	if gap.has(stretch):
		return true
	for tile in stretch.tiles:
		if _exit_crossing.has(tile):
			return true
	return false

## Whether another officer still has to step on one of a stretch's tiles on the walk he is on — a
## taper cutting along the park's edge row round a body — so taping it now would shut it in front
## of him. The tile he stands on is not counted, since anyone may walk off a solid he stands in.
func _another_steps_on(stretch: Stretch, officer: Officer) -> bool:
	for other in officers:
		if other == officer or other.phase == Officer.Phase.GONE or other.path.is_empty():
			continue
		var ahead := _tiles_along(other.at, other.path)
		for tile in stretch.tiles:
			if ahead.has(tile):
				return true
	return false

## The tiles a walk from `from` down `points` crosses, the one it starts on left out.
func _tiles_along(from: Vector2, points: PackedVector2Array) -> Dictionary:
	var crossed := {}
	var at := from
	for point in points:
		var steps := maxi(1, ceili(at.distance_to(point) / (Tuning.TILE_SIZE * 0.25)))
		for i in range(1, steps + 1):
			crossed[_map.world_to_tile(at.lerp(point, float(i) / steps))] = true
		at = point
	crossed.erase(_map.world_to_tile(from))
	return crossed

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
	stretch.node = tape
	# A tile-long stretch is one slice of the park's edge, standing at its own feet: the middle of a
	# broadside stretch, the near end of an end-on one (`DrawLayer.slice_feet()`).
	var slices: Array[Node2D] = [tape]
	DrawLayer.add_slices(_city, slices, DrawLayer.slice_feet(stretch.a, stretch.b, 1))

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

## An escort on his way in, along the way out from its far end and through the gap, then up to
## his person (`_way_up_to()`, laid again whenever they have moved off where it was laid for), whom
## he sends off once he reaches them or the end of his way up to them.
func _approach_the_person(officer: Officer, delta: float, her: Vector2) -> void:
	var person := officer.person
	if not person or not is_instance_valid(person) or person.is_finished:
		_leave(officer)
		return
	# Someone who set off on their own before he reached them is turned onto the way out at once,
	# and he walks out behind them from where he is.
	var already := person.is_leaving and not _leaving.has(person)
	if not already:
		var there := person.global_position
		if officer.aim != Vector2.INF and officer.aim.distance_to(there) > REAIM:
			officer.aim = there
			officer.path = _way_up_to(officer.at, there)
		_walk_path(officer, officer.speed * delta)
		if officer.path.is_empty() and officer.aim == Vector2.INF:
			officer.aim = there
			officer.path = _way_up_to(officer.at, there)
	var beside := officer.aim != Vector2.INF and officer.path.is_empty()
	if already or beside or officer.at.distance_to(person.global_position) <= ESCORT_REACH:
		_send_off(person)
		officer.phase = Officer.Phase.ESCORTING
		officer.path = _lay(officer.at, _way_out_from(officer.at), officer.avoid)

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
	officer.path = _lay(officer.at, _way_out_from(officer.at), officer.avoid)

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
