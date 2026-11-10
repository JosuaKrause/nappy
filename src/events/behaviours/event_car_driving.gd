class_name EventCarDriving
extends EventBehaviour
## **A car that drives** (`EventDef.vehicle`): a body that moves and never into her, standing for
## her, giving way where the crowd's cars do, and a strike ahead of its nose while it drives. See
## `VehicleSpec` for why the body and the strike are separate things.
##
## **It is the check on its event's step** (`EventInstance.step()`, which proposes, checks, then
## commits every mover's step, `MoveProposal`, the event's move it is handed): `note_the_pose()` as
## the step is proposed, the event's ordinary tick, then `check()` on the pose the tick proposes,
## which takes back whatever part of it would have brought the body into her or her pram — the step
## along its route, the chase, the departure and a turn onto a new heading alike — so the car stands
## where it was, facing the way it faced, until she moves. It stops rather than pushes: a car that shoved her could shove her into a
## wall, which is the pin the mobile exemption from solidity exists to prevent. **What the tick
## decided on the pose it would have ended on goes with it**: the end of its route, reached or cut
## short (`EventRouteWalk`), is acted on — parking, leaving — only once that pose is committed
## (`EventInstance._end_its_route()`, which keeps it while a car's step is open, and which `check()`
## drops with a pose it takes back), so a last step taken back never parks it short of its kerb.
##
## **It is handed what never changes under it** as its event is set up: the figure it moves
## (`EventInstance.Figure`), where she is, its row (its body's shape, its speed, whether it parks
## where it arrives, paces or pursues), the map it drives on, its route walk, the vehicle's
## investigation and the event's move. What changes it asks its figure, the lights it stops at
## included (`Figure.lights()`), which its manager tells its event after it is set up.
##
## **Positional, never a force**, the crowd's own rule for bodies (the **crowd-traffic** skill): the
## pose the step would end on is checked, rather than a brake asked to want something, because a
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
## reaches `PATROL_STRIKE_LEAD` past the touch for exactly this) `strikes()` ends the day.
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
## - **It gives way where the crowd's cars do** (`_room_to_its_line()`): short of a zebra she is
##   waiting at on a street whose traffic gives way, and at a red light. A step past that line is
##   refused and the car stands, so the zebra stays the safe way over and the light the main road's
##   contract.
##
## **The give-way is the crowd's cars' own** (`GiveWay`, the world's street rules): the junction
## box, the red light, the zebra and its exemption for the main road are asked of it, and what is
## the event car's alone stays here, the refusal of a step past the line.
##
## **It saves nothing across a stream-out**: whether it stands is decided again every step, and a
## car comes into the world standing, streamed back in as when it is first made.

## How far past the touch a patrol car's strike reaches ahead of its nose, in seconds of its own
## travel (`EventDef.vehicle`): a tenth of a second, 7px at the patrol's 74px/s. The strike has to
## reach past the point where the car's body would first touch her, because the car never moves its
## body into her — a step that would is refused — and a strike stated over the touch alone could
## then never fire: a lethal reach a body stops her short of, which `EventDef.validate()` refuses for
## a standing thing for the same reason. Seconds rather than pixels so a frame's step at any speed
## the car drives at, down to ten frames a second, lands inside it.
const PATROL_STRIKE_LEAD := 0.1

## How near the car's body may be moved to her and her pram, in px. Above zero so the car stops a
## hair short of the contact her own collision already rests at rather than on it.
const DRIVEN_CLEARANCE := 0.5

## Whether the car is standing: its last step's movement was taken back — it would have put the
## body into her, turned her into its path, or crossed a stop line it gives way at — or, on its
## route, she is still in its lane within its warning. **A car is made standing**, so it drives
## off only once she is out of its way: created just out of sight on a north-south street, the fire
## engine is nearer her than its warning reaches, and driving from its first frame it struck her
## inside the time it takes to walk off the road. A standing car is not driving, so it neither
## warns nor strikes.
var _standing := true

## The heading and what was known of her when the step was proposed, to check the proposal against
## and to put back if it is refused; the pose itself is the step's (`MoveProposal.from`).
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

## Its row: its body's `shape`, its `speed`, whether it parks where it arrives or paces a beat,
## whether it moves and whether it pursues.
var _row: EventDef
## The map it drives on: the street lattice its give-way is laid on, the zebras, the carriageway.
var _map: WorldMap
## Its route walk (`EventRouteWalk`), which says how long its route is; null for a row that does
## not move.
var _route: EventRouteWalk
## The vehicle's investigation (`EventInvestigation`), which stops it for her; null for a car that
## does not investigate.
var _investigation: EventInvestigation
## Its event's move this tick (`MoveProposal`): the pose the step began at, and the one the tick
## proposes, which `check()` takes back where it refuses it.
var _move: MoveProposal

## Handed, as its event is set up, the figure it moves, where she is, its row, the map, its route
## walk (or none), the vehicle's investigation (or none) and its event's move.
func _init(figure: EventInstance.Figure, where: WhereSheIs, row: EventDef, map: WorldMap,
		route: EventRouteWalk, investigation: EventInvestigation, move: MoveProposal) -> void:
	steps_each_tick = false
	_figure = figure
	_where = where
	_row = row
	_map = map
	_route = route
	_investigation = investigation
	_move = move

## Stands it for her: a car that stood for its men, say (`EventInvestigation`), pulls away only
## once she is out of its way.
func stand() -> void:
	_standing = true

## Notes, as its event's step is proposed at the pose it stands at (`MoveProposal.stands_at()`),
## what the step will be checked against.
func note_the_pose() -> void:
	var at := _move.stands_at()
	_heading_was = _figure.heading()
	_travelled = _figure.travelled()
	_gait_phase = _figure.gait_phase()
	_was = gap_to_her(at, _heading_was)
	_line = _room_to_its_line(at, _heading_was)
	# Never further than the end of a route it stops at (`route_left()`): it never stands for her,
	# nor turns onto her, where it cannot reach her.
	_left = route_left(_travelled)
	_warning = short_of_its_stop(PATROL_STRIKE_LEAD + Tuning.CAR_HORN_TIME, _left)
	_known = _where.at() != Vector2.INF
	_ahead_before = _known and meets_her(at, _heading_was, _where.at(), _warning)
	_was_leaving = _figure.is_on_its_way_out()

## **Checks the pose its event's tick proposed** (`MoveProposal.steps_to()`, the event's own
## position by now), and takes it back where it is refused: the step to where it began
## (`MoveProposal.stands_at()`), with the heading, the distance travelled and the stride it began
## with (`Figure.take_back_its_step()`). `ends_its_route` is whether the tick reached the end of
## its route on the proposed pose. Answers whether the pose is kept; one taken back takes that end
## with it, and the event drops it. A finished event is not checked, and stands no longer.
func check(ends_its_route: bool) -> bool:
	if _figure.is_gone():
		_standing = false
		return true
	var at := _move.stands_at()
	var to := _move.steps_to()
	var departing := _figure.heading()
	var on_its_route := drives_its_route() and not ends_its_route
	var now := gap_to_her(to, departing)
	var into_her := now < DRIVEN_CLEARANCE and now < _was - 0.001
	var in_its_way := _standing and on_its_route and _ahead_before
	var turns_onto_her := on_its_route and _known and not _ahead_before \
			and not departing.is_equal_approx(_heading_was) \
			and meets_her(to, departing, _where.at(), _warning)
	var past_its_line := on_its_route and _line < INF \
			and (to - at).dot(_heading_was) > maxf(_line, 0.0) + 0.001
	if not (into_her or in_its_way or turns_onto_her or past_its_line):
		_standing = false
		return true
	_move.step_to(at)
	var facing := _heading_was
	# A departure that began this step keeps the way it is leaving in, whatever else the step did —
	# the chase's last step into her is what is taken back, not the turn away from her, which
	# `_be_done()` made where the car stands and which brings it no nearer.
	if _figure.is_on_its_way_out() and not _was_leaving \
			and gap_to_her(at, departing) >= minf(_was, DRIVEN_CLEARANCE) - 0.001:
		facing = departing
	_figure.take_back_its_step(facing, _travelled, _gait_phase)
	var strikes_her := into_her and on_its_route and not _standing and not turns_onto_her \
			and not past_its_line and meets_her(at, _heading_was, _where.at(),
					short_of_its_stop(PATROL_STRIKE_LEAD, _left))
	_standing = not strikes_her
	return false

## **Whether it strikes her at `her` now**: driving, with her in front of its nose on the carriageway
## within `PATROL_STRIKE_LEAD` of its travel past the touch, short of the end of a route it
## stops at. What `EventInstance.is_lethal_at()` answers for a car.
func strikes(her: Vector2) -> bool:
	return _is_driving() and meets_her(_figure.place(), _figure.heading(), her,
			short_of_its_stop(PATROL_STRIKE_LEAD, route_left(_figure.travelled())))

## **Whether it will strike her if she stays where she is**: driving now, and her in front of its
## nose on the carriageway from some point of its next `Tuning.EXPECTED_IMPACT_HORIZON` straight
## ahead, only as far as the line it gives way at and the end of a route it stops at. What
## `EventExcitement.will_be_lethal()` answers for a car.
func will_strike(her: Vector2) -> bool:
	if not _is_driving():
		return false
	var speed: float = _row.speed
	var at := _figure.place()
	var heading := _figure.heading()
	var horizon := speed * Tuning.EXPECTED_IMPACT_HORIZON
	var line := _room_to_its_line(at, heading)
	if line < INF:
		horizon = minf(horizon, maxf(line, 0.0))
	var left := route_left(_figure.travelled())
	horizon = minf(horizon, left)
	var steps := ceili(horizon / (speed * 0.25))
	for i in steps + 1:
		var ahead := minf(float(i) * speed * 0.25, horizon)
		if meets_her(at + heading * ahead, heading, her,
				short_of_its_stop(PATROL_STRIKE_LEAD, left - ahead)):
			return true
	return false

## **How far the car's centre may still go before the line it gives way at**, the crowd car's own
## two lines: `INF` when there is none ahead, or once its nose is past it (the crowd's commit rule —
## a car that has reached the paint clears it rather than stopping on it).
##
## - **A red light**, at a signalled junction ahead whose arm is not green
##   (`TrafficSignals.green_for()`; amber is not green, as it is not for a crowd car): the nose stops
##   `Tuning.CAR_STOP_LINE_SETBACK` short of the junction box, where `Crowd._give_way_at_junctions()`
##   holds the crowd's cars.
## - **A zebra she is waiting at**, on a street whose traffic gives way (not the main road, whose
##   crossings the light keeps), within `Tuning.CAR_ZEBRA_SIGHT` ahead, her within half a street of
##   the car's line and `GiveWay.CAR_ZEBRA_WAIT_RADIUS` along of the paint: the centre stops
##   `CAR_STOP_LINE_SETBACK` short of the paint's near edge (`GiveWay.stop_line()`, the crowd car's
##   own line) — **unless the zebra is on the far side of the junction box ahead**, where that
##   line would stand it inside the box: then it holds at the box's entry line, as at a red light,
##   and that is decided from `Tuning.CAR_JUNCTION_SIGHT` short of the box, wherever she waits along
##   that zebra, rather than from the zebra's own sight circle.
##
## Only on its route and along a street's own axis, which is every route a patrol drives, and only
## on a map laid out on the street lattice (`WorldMap.has_street_lattice()`).
func _room_to_its_line(at: Vector2, heading: Vector2) -> float:
	if not _map.has_street_lattice() or not drives_its_route():
		return INF
	var vertical := absf(heading.y) > absf(heading.x)
	if absf(heading.y if vertical else heading.x) < 0.99:
		return INF
	var direction := signf(heading.y if vertical else heading.x)
	var along := at.y if vertical else at.x
	var cross := at.x if vertical else at.y
	var nose := _row.shape.reach()
	var room := INF
	# The junction box this car is coming to: the crossing street's whole corridor, its zebras
	# included. `to_the_box` is from the nose to its near edge.
	var index := GiveWay.box_index(along, direction)
	var near := GiveWay.box_near_edge(index, direction)
	var to_the_box := GiveWay.distance_to_box(along, direction, nose)
	var box_line := GiveWay.stop_line(to_the_box)
	var within_sight_of_the_box := to_the_box >= 0.0 and to_the_box <= Tuning.CAR_JUNCTION_SIGHT
	# The red light.
	if within_sight_of_the_box:
		var corridor := CityMap.junction_index(floori(cross / float(Tuning.TILE_SIZE)))
		if GiveWay.is_red(_figure.lights(), GiveWay.junction_at(index, corridor, vertical), vertical):
			room = minf(room, box_line)
	var gives_way := GiveWay.owes_her_way(_map, vertical, at, _where.at())
	# **The zebra on the far side of the box ahead is decided at the box's entry line**, wherever
	# she is along it rather than within a sight circle: decided any later, the nose is already in
	# the box and the car would stand there, short of that zebra — and nothing enters a box it
	# cannot leave (the **crowd-traffic** skill), least of all a car the crossing traffic cannot see.
	# So from `CAR_JUNCTION_SIGHT` out, with her waiting at either tile of that zebra, it holds at the
	# box's entry line, where a red light stops it.
	if gives_way and within_sight_of_the_box \
			and GiveWay.waits_past_the_box(_map, index, direction, cross, vertical,
					_where.at()):
		room = minf(room, box_line)
	# The zebra she is waiting at.
	if gives_way and at.distance_to(_where.at()) <= Tuning.CAR_ZEBRA_SIGHT:
		var edge := GiveWay.zebra_edge_ahead(_map, at, vertical, direction, _where.at())
		if edge < INF:
			var to_the_paint := (edge - along) * direction
			# A zebra on the far side of the box ahead would stand the car inside the box, where the
			# crossing traffic — which cannot see a patrol car's body — drives through it; so it holds
			# at the box's entry line instead. A car whose nose is already in the box has committed,
			# and stands short of the paint.
			if to_the_box >= 0.0 and GiveWay.lies_past_the_box(edge, near, direction):
				room = minf(room, box_line)
			elif to_the_paint - nose >= 0.0:
				room = minf(room, GiveWay.stop_line(to_the_paint))
	return room

## `seconds` of the car's travel past the touch, cut to what it can cover before the line it gives
## way at (`_room_to_its_line()`) and before the end of a route it stops at (`route_left()`): a
## car that will stand at a red light or a zebra short of her, or park short of her, neither warns
## her nor reads as lethal to her, since it never reaches her.
func short_of_its_line(seconds: float) -> float:
	var cut := short_of_its_stop(seconds, route_left(_figure.travelled()))
	var line := _room_to_its_line(_figure.place(), _figure.heading())
	if line == INF or _row.speed <= 0.0:
		return cut
	return minf(cut, PATROL_STRIKE_LEAD + maxf(line, 0.0) / _row.speed)

## **How far a car that stops where it arrives (`EventDef.stops_where_it_arrives`, the fire engine
## at its kerb) has still to go along its route** once it has `travelled`, in px; `INF` for every
## other row, which drives on past the end of its route as it leaves. The kerb is a place it stops,
## like a line it gives way at, but with nothing past it: where it parks it is not driving, so its
## warning, its strike and its standing for her end at the touch it would make there, without
## `PATROL_STRIKE_LEAD` past it. Uncut, an engine parking 7-17px short of her ended the day,
## and one created with her past its kerb stood off screen for as long as she stayed there.
func route_left(travelled: float) -> float:
	if not _row.stops_where_it_arrives or _row.paces or _figure.walks().size() < 2:
		return INF
	return maxf(_route.length() - travelled, 0.0)

## `seconds` of the car's travel cut to the `left` px of a route it stops at (`route_left()`).
func short_of_its_stop(seconds: float, left: float) -> float:
	if left == INF or _row.speed <= 0.0:
		return seconds
	return minf(seconds, left / _row.speed)

## Lays a car's body along its heading, which `_build_obstruction()` read once
## (`Figure.turn_its_body_to()`, which turns nothing before the body is down). A capsule turns; a
## point would not need to.
func turn_the_body() -> void:
	if _row.shape == null or _row.shape.half_length <= 0.0:
		return
	_figure.turn_its_body_to(_figure.solid_axis().angle() - PI * 0.5)

## How far apart the car's body would be from her and from her pram with the car at `at` facing
## `heading`: the smaller gap, negative where they would overlap, `INF` for anything that does not
## drive or with nobody told where she is.
func gap_to_her(at: Vector2, heading: Vector2) -> float:
	if _row.shape == null or _where.at() == Vector2.INF:
		return INF
	var gap := _gap_to(at, heading, _where.at(), Tuning.PLAYER_BODY_RADIUS)
	if _where.pram_at() != Vector2.INF:
		gap = minf(gap, _gap_to(at, heading, _where.pram_at(), Stroller.PRAM_BODY_RADIUS))
	return gap

func _gap_to(at: Vector2, heading: Vector2, centre: Vector2, radius: float) -> float:
	var local := (centre - at).rotated(-heading.angle())
	return _row.shape.distance_to_spine(local) - _row.shape.radius - radius

## Whether this car is driving right now: the one state its warning and its strike are live in. On
## its route (`drives_its_route()`) and not standing (`_standing`).
func _is_driving() -> bool:
	return drives_its_route() and not _standing

## Whether the car is on its route rather than in any other state: not standing still through a
## telegraph or parked, not leaving — it is over, and nothing that is over ends the day — and **not
## stopped to investigate**: the heated copy that has noticed her stands where it stopped while the
## man it let out pursues her (`EventDef.investigates()`, `EventInvestigation`), and a standing car
## strikes nobody. Once he is back in it drives its route again, and is a car on it like any other.
func drives_its_route() -> bool:
	if _figure.is_gone() or _figure.is_on_its_way_out() or _figure.has_parked():
		return false
	if not _row.mobile or _figure.walks().size() < 2 or _figure.is_telegraphing_still():
		return false
	if _row.pursuit != null and not _figure.is_waiting():
		return false
	if _investigation != null and not _investigation.runs_its_route():
		return false
	return _row.speed >= Tuning.CAR_STRIKE_MIN_SPEED

## Whether a circle of `radius` at `centre` is in front of a car at `at` facing `heading`, within
## `seconds` of its travel past the point its body would touch it: past the nose (`shape`'s spine
## ends `half_length` ahead of its centre), across no wider than the body and the circle together —
## the ground the body sweeps — and no further ahead than the touch plus that travel. **Nothing
## behind it and nothing beside it**: a circle level with the body's flank is outside, whatever the
## car is doing. *(leafy-puffin, inbox #648: "lethal only in front while driving".)*
func _in_front(at: Vector2, heading: Vector2, centre: Vector2, radius: float,
		seconds: float) -> bool:
	var local := (centre - at).rotated(-heading.angle())
	var nose := _row.shape.half_length
	if local.x <= nose or absf(local.y) > _row.shape.radius + radius:
		return false
	return local.x <= nose + _row.shape.radius + radius + _row.speed * seconds

## Whether her body or her pram, with her at `her`, is in front of a car at `at` facing `heading`
## within `seconds` of its travel past the touch, **with her on the carriageway** — the crowd car's
## own condition (`Crowd._strike()`): the kerb is the edge she chose to step over, so a pram poking
## over it from the sidewalk is a car stopping for her, not a strike.
func meets_her(at: Vector2, heading: Vector2, her: Vector2, seconds: float) -> bool:
	if not _on_the_carriageway(her):
		return false
	if _in_front(at, heading, her, Tuning.PLAYER_BODY_RADIUS, seconds):
		return true
	if _where.pram_at() == Vector2.INF or _where.at() == Vector2.INF:
		return false
	return _in_front(at, heading, her + (_where.pram_at() - _where.at()),
			Stroller.PRAM_BODY_RADIUS, seconds)

## Whether `at` is on the carriageway: a road or a crossing tile (`WorldMap.is_carriageway()`),
## anywhere on open ground, as `clear_line_to()` is.
func _on_the_carriageway(at: Vector2) -> bool:
	return _map.is_carriageway(_map.world_to_tile(at))

## **The car's warning, a horn said with the mark over her head**: true while it drives at her where
## she stands on the carriageway, within `Tuning.CAR_HORN_TIME` of its travel of the strike — so the
## warning comes that long before the strike whatever the car's speed, the crowd car's contract
## (`tests/test_tuning_fairness.gd`'s traffic check, which holds it against walking off the carriageway with the
## doubled margin). `WarningBoard.warn_about_the_ground_she_is_on()` raises the mark from it. Not
## while a line it gives way at, or the end of a route it parks at, stands between them
## (`short_of_its_line()`): it will stop there.
func closes_on(her: Vector2) -> bool:
	return _is_driving() and meets_her(_figure.place(), _figure.heading(), her,
			short_of_its_line(PATROL_STRIKE_LEAD + Tuning.CAR_HORN_TIME))
