class_name EventCarDriving
extends EventBehaviour
## **A car that drives** (`EventDef.vehicle`): a body that moves and never into her, standing for
## her, giving way where the crowd's cars do, and a strike ahead of its nose while it drives. See
## `VehicleSpec` for why the body and the strike are separate things.
##
## **Its frame is proposed, checked, then committed or taken back** (`begin_frame()`,
## `end_frame()`): the event runs its ordinary tick once between the two, and whatever part of it
## would have brought the body into her or her pram — the step along its route, the chase, the
## departure and a turn onto a new heading alike — is taken back, so the car stands where it was,
## facing the way it faced, until she moves. It stops rather than pushes: a car that shoved her
## could shove her into a wall, which is the pin the mobile exemption from solidity exists to
## prevent. **What the tick decided on the pose it would have ended on goes with it**: the end of
## its route, reached or cut short (`EventRouteWalk`), is acted on — parking, leaving — only once
## that pose is the one it keeps (`end_its_route()`), so a last step taken back never parks it
## short of its kerb.
##
## **Positional, never a force**, the crowd's own rule for bodies (the **crowd-traffic** skill): the
## pose the frame would end on is checked, rather than a brake asked to want something, because a
## brake arrives a frame late and a car a frame late is inside her.
##
## **A pose that leaves her no nearer is always allowed**, so a car she walked up against drives on
## along its flank or away from her rather than wedging for good: only a pose both nearer than
## `DRIVEN_CLEARANCE` and nearer than it already was is refused — the same "an agent already
## standing where it may not be is left alone" the crowd's own guard keeps.
##
## **Driving its nose into her on the carriageway is the strike, not a stop.** The step is still
## taken back — the body never goes into her — but a car that was driving its route does not stand
## for her then: it is still driving, and with her inside the strike area (`_in_front()`, which
## reaches `Tuning.PATROL_STRIKE_LEAD` past the touch for exactly this) `strikes()` ends the day.
## What it stands for is the rest — a flank or a corner turned into her, a pram poking over the
## kerb, a car leaving.
##
## **No strike without its full warning, unless she steps into a moving car's path.** Three more
## refusals keep every other way of putting her in front of it out:
##
## - **A turn that newly puts her in front of it** within its warning's reach is refused, and the car
##   stands instead: a pacing car reversing at the end of its beat would otherwise turn a woman
##   standing behind a car driving away from her into one standing in front of it, struck with none
##   of the warning she is owed (minty-hedgehog).
## - **A car that has stood drives on only once she is out of its way**: on its route it goes on
##   standing while she is in its lane within its warning, so it never pulls away into her.
## - **It gives way where the crowd's cars do** (`room_to_its_line()`): short of a zebra she is
##   waiting at on a street whose traffic gives way, and at a red light. A step past that line is
##   refused and the car stands, so the zebra stays the safe way over and the light the main road's
##   contract.
##
## **The give-way is a copy of the crowd's cars'** (`CarStrategy`'s stop lines, `Crowd`'s junction
## holds), kept in step by hand: shared-components' `LaneMover` is where the two become one.
##
## **It saves nothing across a stream-out**: whether it stands is decided again every frame, and a
## car comes into the world standing, streamed back in as when it is first made.

## How near the car's body may be moved to her and her pram, in px. Above zero so the car stops a
## hair short of the contact her own collision already rests at rather than on it.
const DRIVEN_CLEARANCE := 0.5

## Whether the car is standing: its last frame's movement was taken back — it would have put the
## body into her, turned her into its path, or crossed a stop line it gives way at — or, on its
## route, she is still in its lane within its warning. **A car is made standing**, so it drives
## off only once she is out of its way: created just out of sight on a north-south street, the fire
## engine is nearer her than its warning reaches, and driving from its first frame it struck her
## inside the time it takes to walk off the road. A standing car is not driving, so it neither
## warns nor strikes.
var _standing := true

## True between `begin_frame()` and `end_frame()`, while the tick it proposes runs.
var _proposing := false
## The pose and what was known of her when the frame began, to check the proposal against and to
## put back if it is refused.
var _at := Vector2.ZERO
var _heading_was := Vector2.ZERO
var _travelled := 0.0
var _gait_phase := 0.0
var _was := INF
var _line := INF
var _left := INF
var _warning := 0.0
var _known := false
var _ahead_before := false
var _was_leaving := false
## The end of its route, reached or cut short this frame (`end_its_route()`), acted on only if the
## frame is kept; with whether it may park there.
var _ends_its_route := false
var _may_park := true

func _init() -> void:
	steps_each_tick = false

## Whether the car is standing — see `_standing`.
func is_standing() -> bool:
	return _standing

## Stands it for her: a car that stood for its men, say (`EventInvestigation`), pulls away only
## once she is out of its way.
func stand() -> void:
	_standing = true

## Opens the frame: what it is checked against when it ends.
func begin_frame() -> void:
	_at = event.position
	_heading_was = event._heading
	_travelled = event._path_travelled
	_gait_phase = event._gait_phase
	_was = gap_to_her(_at, _heading_was)
	_line = room_to_its_line(_at, _heading_was)
	# Never further than the end of a route it stops at (`route_left()`): it never stands for her,
	# nor turns onto her, where it cannot reach her.
	_left = route_left(_travelled)
	_warning = short_of_its_stop(Tuning.PATROL_STRIKE_LEAD + Tuning.CAR_HORN_TIME, _left)
	_known = event.player_at != Vector2.INF
	_ahead_before = _known and meets_her(_at, _heading_was, event.player_at, _warning)
	_was_leaving = event.is_leaving
	_ends_its_route = false
	_may_park = true
	_proposing = true

## **The end of its route, reached or cut short by something solid** (`EventRouteWalk`): while a
## frame is open it is kept until the frame is (`end_frame()`), so a car never parks or leaves on
## a pose it never reached. Answers whether it was kept; outside a frame the event acts on it at
## once.
func end_its_route(may_park := true) -> bool:
	if not _proposing:
		return false
	_ends_its_route = true
	_may_park = _may_park and may_park
	return true

## Closes the frame: commits the pose the tick proposed, or takes it back.
func end_frame() -> void:
	_proposing = false
	if event.is_finished:
		_standing = false
		return
	var on_its_route := drives_its_route() and not _ends_its_route
	var now := gap_to_her(event.position, event._heading)
	var into_her := now < DRIVEN_CLEARANCE and now < _was - 0.001
	var in_its_way := _standing and on_its_route and _ahead_before
	var turns_onto_her := on_its_route and _known and not _ahead_before \
			and not event._heading.is_equal_approx(_heading_was) \
			and meets_her(event.position, event._heading, event.player_at, _warning)
	var past_its_line := on_its_route and _line < INF \
			and (event.position - _at).dot(_heading_was) > maxf(_line, 0.0) + 0.001
	if into_her or in_its_way or turns_onto_her or past_its_line:
		var departing: Vector2 = event._heading
		event.position = _at
		event._heading = _heading_was
		# A departure that began this frame keeps the way it is leaving in, whatever else the frame
		# did — the chase's last step into her is what is taken back, not the turn away from her,
		# which `_be_done()` made where the car stands and which brings it no nearer.
		if event.is_leaving and not _was_leaving \
				and gap_to_her(_at, departing) >= minf(_was, DRIVEN_CLEARANCE) - 0.001:
			event._heading = departing
		event._path_travelled = _travelled
		event._gait_phase = _gait_phase
		event._gait_moving = false
		var strikes_her := into_her and on_its_route and not _standing and not turns_onto_her \
				and not past_its_line and meets_her(_at, _heading_was, event.player_at,
						short_of_its_stop(Tuning.PATROL_STRIKE_LEAD, _left))
		_standing = not strikes_her
		# The end it reached on the pose taken back is taken back with it.
		_ends_its_route = false
		event._redraw_if_the_picture_changed()
	else:
		_standing = false
	if _ends_its_route:
		_ends_its_route = false
		event._be_done(_may_park)
		event._redraw_if_the_picture_changed()
	turn_the_body()

## **Whether it strikes her at `her` now**: driving, with her in front of its nose on the carriageway
## within `Tuning.PATROL_STRIKE_LEAD` of its travel past the touch, short of the end of a route it
## stops at. What `EventInstance.is_lethal_at()` answers for a car.
func strikes(her: Vector2) -> bool:
	return is_driving() and meets_her(event.global_position, event._heading, her,
			short_of_its_stop(Tuning.PATROL_STRIKE_LEAD, route_left(event._path_travelled)))

## **Whether it will strike her if she stays where she is**: driving now, and her in front of its
## nose on the carriageway from some point of its next `Tuning.EXPECTED_IMPACT_HORIZON` straight
## ahead, only as far as the line it gives way at and the end of a route it stops at. What
## `EventInstance.will_be_lethal()` answers for a car.
func will_strike(her: Vector2) -> bool:
	if not is_driving():
		return false
	var speed: float = event.def.speed
	var horizon := speed * Tuning.EXPECTED_IMPACT_HORIZON
	var line := room_to_its_line(event.global_position, event._heading)
	if line < INF:
		horizon = minf(horizon, maxf(line, 0.0))
	var left := route_left(event._path_travelled)
	horizon = minf(horizon, left)
	var steps := ceili(horizon / (speed * 0.25))
	for i in steps + 1:
		var ahead := minf(float(i) * speed * 0.25, horizon)
		if meets_her(event.global_position + event._heading * ahead, event._heading, her,
				short_of_its_stop(Tuning.PATROL_STRIKE_LEAD, left - ahead)):
			return true
	return false

## **How far the car's centre may still go before the line it gives way at**, the crowd car's own
## two lines: `INF` when there is none ahead, or once its nose is past it (the crowd's commit rule —
## a car that has reached the paint clears it rather than stopping on it).
##
## - **A red light**, at a signalled junction ahead whose arm is not green
##   (`TrafficSignals.green_for()`; amber is not green, as it is not for a crowd car): the nose stops
##   `Tuning.CAR_STOP_LINE_SETBACK` short of the junction box, where `Crowd.give_way_at_junctions()`
##   holds the crowd's cars.
## - **A zebra she is waiting at**, on a street whose traffic gives way (not the main road, whose
##   crossings the light keeps), within `Tuning.CAR_ZEBRA_SIGHT` ahead, her within half a street of
##   the car's line and `Tuning.CAR_ZEBRA_WAIT_RADIUS` along of the paint: the centre stops
##   `CAR_STOP_LINE_SETBACK` short of the paint's near edge, `CarStrategy._distance_to_stop_line()`'s
##   own arithmetic — **unless the zebra is on the far side of the junction box ahead**, where that
##   line would stand it inside the box: then it holds at the box's entry line, as at a red light,
##   and that is decided from `Tuning.CAR_JUNCTION_SIGHT` short of the box, wherever she waits along
##   that zebra, rather than from the zebra's own sight circle.
##
## Only on its route and along a street's own axis, which is every route a patrol drives, and only
## on a map laid out on the street lattice (`WorldMap.has_street_lattice()`).
func room_to_its_line(at: Vector2, heading: Vector2) -> float:
	if not event._map.has_street_lattice() or not drives_its_route():
		return INF
	var vertical := absf(heading.y) > absf(heading.x)
	if absf(heading.y if vertical else heading.x) < 0.99:
		return INF
	var direction := signf(heading.y if vertical else heading.x)
	var along := at.y if vertical else at.x
	var cross := at.x if vertical else at.y
	var tile := float(Tuning.TILE_SIZE)
	var nose := event.def.shape.reach()
	var room := INF
	# The junction box this car is coming to, as `LaneMover.junction_ahead()` finds it: the crossing
	# street's whole corridor, its zebras included. `to_the_box` is from the nose to its near edge.
	var along_tile := floori(along / tile)
	var index := CityMap.junction_index(along_tile)
	if CityMap.corridor_offset(along_tile) < 0 and direction > 0.0:
		index += 1
	var low := float(index * CityMap.period()) * tile
	var near := low if direction > 0.0 else low + float(Tuning.STREET_WIDTH) * tile
	var to_the_box := (near - along) * direction - nose
	var box_line := to_the_box - Tuning.CAR_STOP_LINE_SETBACK
	# The red light.
	if event.signals != null:
		var corridor := CityMap.junction_index(floori(cross / tile))
		var junction := Vector2i(corridor, index) if vertical else Vector2i(index, corridor)
		if to_the_box >= 0.0 and to_the_box <= Tuning.CAR_JUNCTION_SIGHT \
				and event.signals.is_signalled(junction) \
				and not event.signals.green_for(junction, vertical):
			room = minf(room, box_line)
	var gives_way := event.player_at != Vector2.INF \
			and event._map.street_kind_at(vertical, event._map.world_to_tile(at)) \
					!= GameEnums.StreetKind.MAIN \
			and absf((event.player_at.x if vertical else event.player_at.y) - cross) \
					<= Tuning.STREET_WIDTH * tile * 0.5
	# **The zebra on the far side of the box ahead is decided at the box's entry line**, wherever
	# she is along it rather than within a sight circle: decided any later, the nose is already in
	# the box and the car would stand there, short of that zebra — and nothing enters a box it
	# cannot leave (the **crowd-traffic** skill), least of all a car the crossing traffic cannot see.
	# So from `CAR_JUNCTION_SIGHT` out, with her waiting at either tile of that zebra, it holds at the
	# box's entry line, where a red light stops it.
	if gives_way and to_the_box >= 0.0 and to_the_box <= Tuning.CAR_JUNCTION_SIGHT:
		var her_along := event.player_at.y if vertical else event.player_at.x
		var first := index * CityMap.period() \
				+ (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH if direction > 0.0 else 0)
		var lane_index := floori(cross / tile)
		for k in Tuning.SIDEWALK_WIDTH:
			var zebra := Vector2i(lane_index, first + k) if vertical \
					else Vector2i(first + k, lane_index)
			if event._map.is_crossing(zebra) \
					and absf(her_along - float(first + k) * tile) <= Tuning.CAR_ZEBRA_WAIT_RADIUS:
				room = minf(room, box_line)
				break
	# The zebra she is waiting at.
	if gives_way and at.distance_to(event.player_at) <= Tuning.CAR_ZEBRA_SIGHT:
		var waiting_along := event.player_at.y if vertical else event.player_at.x
		var step := Vector2i(0, int(direction)) if vertical else Vector2i(int(direction), 0)
		var here := event._map.world_to_tile(at)
		var run_start := -1
		for k in range(0, ceili(Tuning.CAR_ZEBRA_SIGHT / tile) + 1):
			var at_tile := here + step * k
			var along_index: int = at_tile.y if vertical else at_tile.x
			if not event._map.is_crossing(at_tile):
				run_start = -1
				continue
			if run_start < 0:
				run_start = along_index
			if absf(waiting_along - float(along_index) * tile) > Tuning.CAR_ZEBRA_WAIT_RADIUS:
				continue
			var edge := float(run_start + (0 if direction > 0.0 else 1)) * tile
			var to_the_paint := (edge - along) * direction
			# **Nothing enters a box it cannot leave** (the **crowd-traffic** skill). A zebra on the
			# far side of the box ahead would stand the car inside the box, where the crossing
			# traffic — which cannot see a patrol car's body — drives through it; so it holds at the
			# box's entry line instead, where a red light stops it. A car whose nose is already in
			# the box has committed, and stands short of the paint.
			if to_the_box >= 0.0 and (edge - near) * direction > 0.5:
				room = minf(room, box_line)
			elif to_the_paint - nose >= 0.0:
				room = minf(room, to_the_paint - Tuning.CAR_STOP_LINE_SETBACK)
			break
	return room

## `seconds` of the car's travel past the touch, cut to what it can cover before the line it gives
## way at (`room_to_its_line()`) and before the end of a route it stops at (`route_left()`): a
## car that will stand at a red light or a zebra short of her, or park short of her, neither warns
## her nor reads as lethal to her, since it never reaches her.
func short_of_its_line(seconds: float) -> float:
	var cut := short_of_its_stop(seconds, route_left(event._path_travelled))
	var line := room_to_its_line(event.global_position, event._heading)
	if line == INF or event.def.speed <= 0.0:
		return cut
	return minf(cut, Tuning.PATROL_STRIKE_LEAD + maxf(line, 0.0) / event.def.speed)

## **How far a car that stops where it arrives (`EventDef.stops_where_it_arrives`, the fire engine
## at its kerb) has still to go along its route** once it has `travelled`, in px; `INF` for every
## other row, which drives on past the end of its route as it leaves. The kerb is a place it stops,
## like a line it gives way at, but with nothing past it: where it parks it is not driving, so its
## warning, its strike and its standing for her end at the touch it would make there, without
## `Tuning.PATROL_STRIKE_LEAD` past it. Uncut, an engine parking 7-17px short of her ended the day,
## and one created with her past its kerb stood off screen for as long as she stayed there.
func route_left(travelled: float) -> float:
	if not event.def.stops_where_it_arrives or event.def.paces or event.path.size() < 2:
		return INF
	return maxf(event.route.length() - travelled, 0.0)

## `seconds` of the car's travel cut to the `left` px of a route it stops at (`route_left()`).
func short_of_its_stop(seconds: float, left: float) -> float:
	if left == INF or event.def.speed <= 0.0:
		return seconds
	return minf(seconds, left / event.def.speed)

## Lays a car's body along its heading, which `_build_obstruction()` read once. A capsule turns; a
## point would not need to.
func turn_the_body() -> void:
	if event._obstruction == null or event.def.shape == null or event.def.shape.half_length <= 0.0:
		return
	var angle := event._solid_axis().angle() - PI * 0.5
	for child in event._obstruction.get_children():
		var collision := child as CollisionShape2D
		if collision and not is_equal_approx(collision.rotation, angle):
			collision.rotation = angle

## How far apart the car's body would be from her and from her pram with the car at `at` facing
## `heading`: the smaller gap, negative where they would overlap, `INF` for anything that does not
## drive or with nobody told where she is.
func gap_to_her(at: Vector2, heading: Vector2) -> float:
	if event.def.shape == null or event.player_at == Vector2.INF:
		return INF
	var gap := _gap_to(at, heading, event.player_at, Tuning.PLAYER_BODY_RADIUS)
	if event.pram_at != Vector2.INF:
		gap = minf(gap, _gap_to(at, heading, event.pram_at, Stroller.PRAM_BODY_RADIUS))
	return gap

func _gap_to(at: Vector2, heading: Vector2, centre: Vector2, radius: float) -> float:
	var local := (centre - at).rotated(-heading.angle())
	return event.def.shape.distance_to_spine(local) - event.def.shape.radius - radius

## Whether this car is driving right now: the one state its warning and its strike are live in. On
## its route (`drives_its_route()`) and not standing (`is_standing()`).
func is_driving() -> bool:
	return drives_its_route() and not _standing

## Whether the car is on its route rather than in any other state: not standing still through a
## telegraph or parked, not leaving — it is over, and nothing that is over ends the day — and **not
## stopped to investigate**: the heated copy that has noticed her stands where it stopped while the
## man it let out pursues her (`EventDef.investigates`, `EventInvestigation`), and a standing car
## strikes nobody. Once he is back in it drives its route again, and is a car on it like any other.
func drives_its_route() -> bool:
	if event.is_finished or event.is_leaving or event.is_parked:
		return false
	if not event.def.mobile or event.path.size() < 2 or event.is_telegraphing_still():
		return false
	if event.def.pursuit != null and not event.is_waiting():
		return false
	if event.investigation and not event.investigation.runs_its_route():
		return false
	return event.def.speed >= Tuning.CAR_STRIKE_MIN_SPEED

## Whether a circle of `radius` at `centre` is in front of a car at `at` facing `heading`, within
## `seconds` of its travel past the point its body would touch it: past the nose (`shape`'s spine
## ends `half_length` ahead of its centre), across no wider than the body and the circle together —
## the ground the body sweeps — and no further ahead than the touch plus that travel. **Nothing
## behind it and nothing beside it**: a circle level with the body's flank is outside, whatever the
## car is doing. *(leafy-puffin, inbox #648: "lethal only in front while driving".)*
func _in_front(at: Vector2, heading: Vector2, centre: Vector2, radius: float,
		seconds: float) -> bool:
	var local := (centre - at).rotated(-heading.angle())
	var nose := event.def.shape.half_length
	if local.x <= nose or absf(local.y) > event.def.shape.radius + radius:
		return false
	return local.x <= nose + event.def.shape.radius + radius + event.def.speed * seconds

## Whether her body or her pram, with her at `her`, is in front of a car at `at` facing `heading`
## within `seconds` of its travel past the touch, **with her on the carriageway** — the crowd car's
## own condition (`Crowd._strike()`): the kerb is the edge she chose to step over, so a pram poking
## over it from the sidewalk is a car stopping for her, not a strike.
func meets_her(at: Vector2, heading: Vector2, her: Vector2, seconds: float) -> bool:
	if not _on_the_carriageway(her):
		return false
	if _in_front(at, heading, her, Tuning.PLAYER_BODY_RADIUS, seconds):
		return true
	if event.pram_at == Vector2.INF or event.player_at == Vector2.INF:
		return false
	return _in_front(at, heading, her + (event.pram_at - event.player_at),
			Stroller.PRAM_BODY_RADIUS, seconds)

## Whether `at` is on the carriageway: a road or a crossing tile (`WorldMap.is_carriageway()`),
## anywhere on open ground, as `_clear_line_to()` is.
func _on_the_carriageway(at: Vector2) -> bool:
	return event._map.is_carriageway(event._map.world_to_tile(at))

## **The car's warning, a horn said with the mark over her head**: true while it drives at her where
## she stands on the carriageway, within `Tuning.CAR_HORN_TIME` of its travel of the strike — so the
## warning comes that long before the strike whatever the car's speed, the crowd car's contract
## (`Tuning.validate_traffic()`, which holds it against walking off the carriageway with the
## doubled margin). `EventManager._warn_about_the_ground_she_is_on()` raises the mark from it. Not
## while a line it gives way at, or the end of a route it parks at, stands between them
## (`short_of_its_line()`): it will stop there.
func closes_on(her: Vector2) -> bool:
	return is_driving() and meets_her(event.global_position, event._heading, her,
			short_of_its_line(Tuning.PATROL_STRIKE_LEAD + Tuning.CAR_HORN_TIME))
