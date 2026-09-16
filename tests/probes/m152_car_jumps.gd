extends RefCounted
## Every frame-to-frame jump a car makes that it could not have driven, every reversal on the spot
## and what refused the arc that would have replaced it, and whether the player could see any of it
## — the probe for *"cars are super buggy now. when they turn in the final stretch the teleport a
## car length somewhere else"* (playtest 76, 2026-09-15) and for *"cars are still jumping around"*
## said of the same build a burst later.
##
## **A recycle is a teleport by construction and the design allows exactly one of them**: the one
## that happens where nobody is looking. So the question is never *did a car move further than it
## drove* — several do, every second, out at the entry band — it is **where the camera was when it
## did**. Every jump is classified and counted; only the ones inside the play viewport are
## defects.
##
## **And a defect does not have to clear the jump threshold to be one.** A car reversing where it
## stands moves nothing at all on the frame it does it, and what a player sees is the second after:
## the body sliding to the other lane's centre at `CrowdAgent.STEER_SPEED`, then back again when the
## next reversal fires. Three pixels a frame, under every threshold here, and from outside it is a
## car shaking its head. So the sway counter below is a first-class row rather than a footnote — see
## `_note_the_sway()`.
##
## What it measures, per physics frame of a rig day, for every car in the crowd:
##
## - the step it actually took, against `2 · CAR_SPEED.y · delta` — twice what the fastest car
##   could cover, so lane travel, the cross-steer and the separation pass's ordinary few pixels
##   are all comfortably under it and nothing but a placement clears it;
## - what the car was doing at the time — following an arc, landing one, caught in a pocket, given
##   a fresh lane by `_recycle()`, or none of those, which leaves the separation pass;
## - every reversal on the spot (`CrowdAgent._turn_round()`), **with the reason**: which of the
##   planner's two ways out fired, what state the car was in, and what refused each of the four
##   arcs it tried on that frame. `CrowdAgent.turn_refusals` and `turn_round_cause` are the
##   planner's own record and this is what reads them;
## - every episode of a car swaying across its lane without going anywhere;
## - whether either end of the jump was inside `Tuning.VIEW_HALF_EXTENT` (320 × 180 px, the
##   1280×720 viewport at the play zoom of 2) around the crowd field's centre, which is where the
##   camera is — `CrowdField.centre` is what `CrowdAgent._out_of_view()` measures against, and
##   `Tuning.OUT_OF_SIGHT` (420px) is the radius outside that box's own far corner (367px).
##
## The rig is a real generated city on a real day — closures planned, the day's events placed, so
## the hard seals and the pockets they make are the ones a player meets.
##
## **The focus walks to the day's barriers rather than wandering.** A car only ever turns because
## something is in its way (`_divert()` calls `_plan_a_turn()`, and nothing else does for a car),
## so the junctions at the mouth of a shut street are the only places in the city where turns and
## turnarounds are dense — a focus parked anywhere else watches straight traffic for a minute and
## reports nothing. Both kinds of barrier count: a road closure and a hard seal shut a street the
## same way as far as a car is concerned, and the burst the player photographed was at a
## `burst_water_main`, which is a seal rather than a closure. It walks between them at
## `Tuning.WALK_SPEED` rather than jumping, because a field whose centre teleports recycles the
## whole crowd at once and every one of those recycles would be scored against the frame the camera
## landed on.
##
## Run it with `tools/test.sh probes/m152_car_jumps.gd`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 60.0

## The cities and the days. Day 1 is the busiest road the game has (34 cars, act I) and day 13 the
## most closed (4 closures, act IV) — the two ends of the axis the defect is reported on. The
## fourth city is the seed of the burst the player took of a car shaking its head at a seal, with
## its own day and nothing else, so that the case is in the measurement rather than beside it.
static func rig_days() -> Array:
	return [
		[4242, [1, 13]],
		[24757, [1, 13]],
		[91117, [1, 13]],
		[3126506586, [1]],
	]
const SECONDS := 40.0

## How long the focus dwells on one barrier mouth before walking to the next, in seconds.
const DWELL_SECONDS := 6.0
## How far inside the map the focus is kept, in px, so the field is never half off the city.
const FOCUS_MARGIN := 420.0

## How far a car's along position may drift and still count as standing still, in px, and how many
## times its cross position has to reverse before the standing still is a defect. One reversal is a
## car settling onto its lane centre after a nudge; two is a car being sent the other way.
const SWAY_ALONG_TOLERANCE := 4.0
const SWAY_REVERSALS := 2
## And how far across it has to have swung for the episode to be worth a line. Half a lane: below
## that it is a body finding its own centre line, above it the car is visibly on the wrong side.
const SWAY_WIDTH := 16.0

## Anything above this in one frame is further than a car could have driven. Twice the fastest
## car's own step, so the cross-steer and a `nudge_back` of a few pixels never reach it.
static func _jump_threshold() -> float:
	return 2.0 * Tuning.CAR_SPEED.y * STEP

func run(t) -> void:
	var totals := {}
	var causes := {}
	var in_view_total := 0
	var cars_seen := 0
	var worst := []
	print("m152 car-jump probe — threshold %.2f px/frame (2 x CAR_SPEED.y x %.4fs), view box %s"
			% [_jump_threshold(), STEP, Tuning.VIEW_HALF_EXTENT])
	for rig: Array in rig_days():
		var city_seed: int = rig[0]
		var map := CityGenerator.generate(city_seed)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		for day: int in rig[1]:
			var result := _watch(city, map, city_seed, day)
			cars_seen += int(result["cars"])
			in_view_total += int(result["in_view"])
			var classes: Dictionary = result["classes"]
			for key: String in classes:
				totals[key] = int(totals.get(key, 0)) + int(classes[key])
			var day_causes: Dictionary = result["causes"]
			for key: String in day_causes:
				causes[key] = int(causes.get(key, 0)) + int(day_causes[key])
			if result["worst"] != "":
				worst.append(result["worst"])
		city.free()
	print("")
	print("TOTAL over %d rig days, %.0fs each: %d cars watched" % [_rig_day_count(), SECONDS,
			cars_seen])
	for key: String in _class_order():
		if totals.has(key):
			print("    %-14s %5d   %s" % [key, int(totals[key]),
					_tail(key, totals)])
	if not worst.is_empty():
		print("  worst in-view jump per rig day:")
		for line: String in worst:
			print("    %s" % line)
	_print_the_causes("why cars reversed on the spot, over every rig day", causes)
	print("PROBE m152 in-view jumps: %d" % in_view_total)
	print("PROBE m152 turn-rounds: %d (%d in view)"
			% [int(totals.get("turn-rounds", 0)), int(totals.get("turn-rounds/in-view", 0))])
	print("PROBE m152 sway episodes: %d (%d in view)"
			% [int(totals.get("sway", 0)), int(totals.get("sway/in-view", 0))])
	t.check(cars_seen > 0, "the rig days put cars on the road to watch (%d)" % cars_seen)

static func _rig_day_count() -> int:
	var count := 0
	for rig: Array in rig_days():
		count += (rig[1] as Array).size()
	return count

## How a counted row reads. `landings` counts every one that happened, jump or no jump, so it is
## the denominator the jump rows are read against; `turn-rounds` and `sway` are defects in their own
## right whether or not any frame of them cleared the threshold, and every other row counts jumps
## alone. All of them carry how many the camera was looking at.
static func _tail(key: String, counts: Dictionary) -> String:
	var seen := "(%d in view)" % int(counts.get(key + "/in-view", 0))
	if key == "landings":
		return "(every one, jump or not) " + seen
	return seen

## The classes a jump is put in, in the order a report reads them. `recycle` is the legal one and
## is only a defect when it happens in view; everything else is a defect wherever it happens, and
## is counted in view and out so the two can be told apart.
static func _class_order() -> Array[String]:
	return ["landings", "turn-rounds", "sway", "recycle", "turn-landed", "turn-arc",
			"turn-started", "pocket", "spacing"]

# ------------------------------------------------------------------------ rig ---

## One seed's day, watched frame by frame. Returns the jump counts by class, how many of them the
## camera was looking at, and the breakdown of why each reversal on the spot happened.
func _watch(city: City, map: CityMap, city_seed: int, day: int) -> Dictionary:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	var closures := RandomNumberGenerator.new()
	closures.seed = hash("m152-closures:%d:%d" % [city_seed, day])
	city.start_day(state, day, closures)
	var events := RandomNumberGenerator.new()
	events.seed = hash("m152-events:%d:%d" % [city_seed, day])
	var consumed: Array[String] = []
	city.events.start_day(day, events, consumed)

	var at := map.doorstep_world_position()
	var crowd_rng := RandomNumberGenerator.new()
	crowd_rng.seed = hash("m152-crowd:%d:%d" % [city_seed, day])
	city.crowd.start_day(day, crowd_rng, at)
	city.crowd.set_gates(city.region_plan().gates)

	var stops := _places_cars_turn(city, map, at)
	var extent := map.world_size()
	var focus := at
	var target := 0
	var dwell := 0.0

	var classes := {}
	var causes := {}
	var in_view := 0
	var worst_jump := 0.0
	var worst_line := ""
	var seen_ids := {}
	var before := {}
	var sway := {}
	var retreats: Array[String] = []
	var frames := int(round(SECONDS / STEP))
	for frame in frames:
		# Walk to the next junction a car has a reason to turn at, stand there a while, move on.
		var to: Vector2 = stops[target]
		if focus.distance_to(to) <= Tuning.WALK_SPEED * STEP:
			focus = to
			dwell += STEP
			if dwell >= DWELL_SECONDS:
				dwell = 0.0
				target = (target + 1) % stops.size()
		else:
			focus += focus.direction_to(to) * Tuning.WALK_SPEED * STEP
		focus.x = clampf(focus.x, FOCUS_MARGIN, extent.x - FOCUS_MARGIN)
		focus.y = clampf(focus.y, FOCUS_MARGIN, extent.y - FOCUS_MARGIN)

		before.clear()
		for agent: CrowdAgent in city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR:
				continue
			var id := agent.get_instance_id()
			seen_ids[id] = true
			# The numbers the planner reads, taken before the step rather than after it: a flip
			# reverses `_direction`, so `_distance_to_the_blockage()` asked afterwards answers about
			# the road the car has just turned to face rather than the one that stopped it.
			before[id] = [agent.position, agent.is_turning(), agent._cruise,
					agent._is_in_a_pocket(), agent._direction, agent._vertical,
					agent._speed, agent._room_to_stop_in(), agent._distance_to_the_blockage(),
					agent._blocked_in, agent.turned_on_this_approach]

		city.crowd.set_focus(focus)
		city.crowd.step(STEP)

		for agent: CrowdAgent in city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR:
				continue
			var was: Array = before.get(agent.get_instance_id(), [])
			if was.is_empty():
				continue
			var from: Vector2 = was[0]
			var moved := from.distance_to(agent.position)
			_note_the_sway(sway, agent, was, focus, classes)
			# Counted whether or not it jumped, because what the fix has to be judged on is the
			# *share* of landings that end in a teleport rather than the raw count of teleports —
			# see `_land_the_turn()`, which drops an arrival that finds its booked spot taken at
			# the back of the whole exit lane.
			if bool(was[1]) and not agent.is_turning():
				classes["landings"] = int(classes.get("landings", 0)) + 1
				if _on_screen(agent.position, focus):
					classes["landings/in-view"] = int(classes.get("landings/in-view", 0)) + 1
			# A car reversing on the spot with no arc at all: `_turn_round()`, which flips the
			# heading and swaps the lane in one frame. The player's *"instead of routing a turn
			# (or u turn) they just teleport"* is what this looks like from outside. A recycle
			# flips a direction too and is a different thing entirely, so it is excluded by the
			# same `_cruise` reading `_classify()` uses.
			if not bool(was[1]) and not agent.is_turning() and bool(was[5]) == agent._vertical \
					and not is_equal_approx(float(was[4]), agent._direction) \
					and is_equal_approx(float(was[2]), agent._cruise):
				classes["turn-rounds"] = int(classes.get("turn-rounds", 0)) + 1
				var seen := _on_screen(agent.position, focus)
				if seen:
					classes["turn-rounds/in-view"] = \
							int(classes.get("turn-rounds/in-view", 0)) + 1
				var why := _why_it_reversed(agent, was, seen)
				causes[why] = int(causes.get(why, 0)) + 1
			if moved <= _jump_threshold():
				continue
			var what := _classify(was, agent)
			if what == "turn-landed":
				retreats.append(_why_the_landing_retreated(city, agent, from, moved))
			classes[what] = int(classes.get(what, 0)) + 1
			# Either end on screen counts: a car that vanishes from in front of her and a car that
			# appears in front of her are the same defect seen from the two sides.
			if not (_on_screen(from, focus) or _on_screen(agent.position, focus)):
				continue
			in_view += 1
			classes[what + "/in-view"] = int(classes.get(what + "/in-view", 0)) + 1
			if moved > worst_jump:
				worst_jump = moved
				worst_line = ("seed %d day %d frame %d: %s jumped %.0fpx, %s -> %s, camera at "
						+ "%s (%.0fpx away)") % [city_seed, day, frame, what, moved, from,
						agent.position, focus, from.distance_to(focus)]

	print("")
	print("seed %d day %d: %d frames, %d cars, %d closures, %d watch points"
			% [city_seed, day, frames, seen_ids.size(), city.closures().size(), stops.size()])
	for key: String in _class_order():
		if classes.has(key):
			print("    %-14s %5d   %s" % [key, int(classes[key]),
					_tail(key, classes)])
	print("    in-view jumps: %d" % in_view)
	if worst_line != "":
		print("    worst: %s" % worst_line)
	for line: String in retreats:
		print("    retreat: %s" % line)
	_print_the_causes("why cars reversed on the spot", causes)

	return {"classes": classes, "in_view": in_view, "cars": seen_ids.size(),
			"worst": worst_line, "causes": causes}

## The places in this day's city a car actually has a reason to turn: the mouths of every shut
## street, closure or hard seal, which is where a lane runs into something and `_divert()` plans an
## arc. The doorstep is the fallback for a day that shut none, so the walk always has somewhere to
## go.
##
## **A seal is asked of the map rather than of the catalogue.** Which rows can shut a street is a
## property of the day's placements, and `CityMap.held_segments` is the answer the cars themselves
## read — so a watch point exists wherever a car is actually going to meet something, without this
## file carrying a list of row ids that would go stale the first time one was added.
func _places_cars_turn(city: City, map: CityMap, doorstep: Vector2) -> Array[Vector2]:
	var stops: Array[Vector2] = []
	var seen := {}
	for closure: RoadClosure in city.closures():
		for mouth: Vector2 in closure.mouth_centres(map):
			stops.append(mouth)
			seen[mouth.snapped(Vector2.ONE)] = true
	for key: Vector3i in map.held_segments:
		var segment := StreetNetwork.by_key(key)
		if segment == null:
			continue
		for at_a in [true, false]:
			var mouth := map.tile_rect_to_world(segment.mouth_rect(at_a)).get_center()
			if seen.has(mouth.snapped(Vector2.ONE)):
				continue
			seen[mouth.snapped(Vector2.ONE)] = true
			stops.append(mouth)
	if stops.is_empty():
		stops.append(doorstep)
	# **Nearest the doorstep first**, because the walk is the expensive part: a day has more shut
	# streets than forty seconds of walking can reach, and an arbitrary order spends most of the run
	# crossing the city. Sorted rather than sampled so the same day always watches the same places.
	stops.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_squared_to(doorstep) < b.distance_squared_to(doorstep))
	return stops

# ----------------------------------------------------------- the reversals ---

## Why one reversal on the spot happened, as a line a report can count identical copies of.
##
## Everything in it is read off the planner's own record — `CrowdAgent.turn_round_cause` for which
## of the two calls fired and `turn_refusals` for what each of the four candidate arcs met — plus
## the state the car was in on the frame before, which is where the question *should this have been
## an arc* is actually settled: a car stopped with its aim point reached has the road it needs and
## a car nose to a barrier does not.
func _why_it_reversed(agent: CrowdAgent, was: Array, in_view: bool) -> String:
	var cause: int = agent.turn_round_cause
	var line := "%-16s" % _cause_name(cause)
	if cause == CrowdAgent.TurnRoundCause.STOPPED_NO_ROOM:
		line += " arcs[%s]" % _refusal_names(agent.turn_refusals)
	line += " blocked_in=%d room=%s gap=%s speed=%s turned_before=%s %s" % [
			int(was[9]), _bucket(float(was[7])), _bucket(float(was[8])), _bucket(float(was[6])),
			"yes" if bool(was[10]) else "no", "in-view" if in_view else "off-camera"]
	return line

static func _cause_name(cause: int) -> String:
	match cause:
		CrowdAgent.TurnRoundCause.OFF_THE_STREET:
			return "off-the-street"
		CrowdAgent.TurnRoundCause.STOPPED_NO_ROOM:
			return "stopped-no-room"
	return "none"

## The four candidate slots as `near/far/box/street`, each named by what refused it.
static func _refusal_names(refusals: PackedInt32Array) -> String:
	var names := PackedStringArray()
	for slot in refusals.size():
		names.append(_refusal_name(refusals[slot]))
	return "/".join(names)

static func _refusal_name(refusal: int) -> String:
	match refusal:
		CrowdAgent.TurnRefusal.FITS:
			return "fits"
		CrowdAgent.TurnRefusal.NOT_TRIED:
			return "-"
		CrowdAgent.TurnRefusal.LANDING_TAKEN:
			return "landing-taken"
		CrowdAgent.TurnRefusal.OUT_OF_SIGHT:
			return "out-of-sight"
		CrowdAgent.TurnRefusal.PAST_THE_BLOCKAGE:
			return "past-blockage"
		CrowdAgent.TurnRefusal.TOO_TIGHT:
			return "too-tight"
		CrowdAgent.TurnRefusal.SWEEP_BLOCKED:
			return "sweep-blocked"
		CrowdAgent.TurnRefusal.EXIT_PLUGGED:
			return "exit-plugged"
	return "?"

## A distance or a speed as a coarse band, so that two reversals in the same state count as the
## same line instead of differing in the third decimal place.
static func _bucket(value: float) -> String:
	if value == INF:
		return "inf"
	if value < 1.0:
		return "0"
	if value < Tuning.CAR_STRIKE_HALF_LENGTH:
		return "<nose"
	if value < CarTurn.about_face_reach():
		return "<reach"
	if value < Tuning.CAR_GAP_MIN:
		return "<gap"
	return ">gap"

static func _print_the_causes(heading: String, causes: Dictionary) -> void:
	if causes.is_empty():
		return
	var lines: Array[String] = []
	for key: String in causes:
		lines.append(key)
	lines.sort_custom(func(a: String, b: String) -> bool:
		return int(causes[a]) > int(causes[b]))
	print("  %s:" % heading)
	for key: String in lines:
		print("    %5d  %s" % [int(causes[key]), key])

# ---------------------------------------------------------------- the sway ---

## A car that stands still and slides from one side of its carriageway to the other and back.
##
## **Nothing about it clears a jump threshold and it is the thing the player photographed.** A
## reversal on the spot swaps the lane a car belongs to without moving it, and the ordinary
## cross-steer then carries the body over at `CrowdAgent.STEER_SPEED` (90px/s, three pixels a
## frame); the next reversal sends it back. So what names the defect is the *shape* of the motion:
## the along coordinate pinned while the cross coordinate reverses more than once.
##
## An episode starts wherever a car's along position settles and ends as soon as it drives off it,
## which is what `SWAY_ALONG_TOLERANCE` decides. A car that recycles or changes axis starts a new
## one, since neither coordinate means the same thing afterwards.
func _note_the_sway(sway: Dictionary, agent: CrowdAgent, was: Array, focus: Vector2,
		classes: Dictionary) -> void:
	var id := agent.get_instance_id()
	var vertical: bool = agent._vertical
	var along := agent.position.y if vertical else agent.position.x
	var across := agent.position.x if vertical else agent.position.y
	var record: Array = sway.get(id, [])
	var fresh := record.is_empty() or bool(record[0]) != vertical \
			or not is_equal_approx(float(was[2]), agent._cruise) \
			or absf(along - float(record[1])) > SWAY_ALONG_TOLERANCE
	if fresh:
		# [axis, along it settled at, last cross, last cross step sign, reversals, lowest, highest]
		sway[id] = [vertical, along, across, 0.0, 0, across, across]
		return
	var step := across - float(record[2])
	var sign_now := signf(step) if absf(step) > 0.01 else float(record[3])
	var reversals := int(record[4])
	if sign_now != 0.0 and float(record[3]) != 0.0 and sign_now != float(record[3]):
		reversals += 1
		if reversals == SWAY_REVERSALS \
				and maxf(float(record[6]), across) - minf(float(record[5]), across) >= SWAY_WIDTH:
			classes["sway"] = int(classes.get("sway", 0)) + 1
			if _on_screen(agent.position, focus):
				classes["sway/in-view"] = int(classes.get("sway/in-view", 0)) + 1
	record[2] = across
	record[3] = sign_now
	record[4] = reversals
	record[5] = minf(float(record[5]), across)
	record[6] = maxf(float(record[6]), across)

# ------------------------------------------------------------- the landings ---

## What the exit lane looked like at the moment a landing was flung to the back of it.
##
## A landing only retreats when the spot it booked is taken, so the useful number is **which** car
## took it and from which side — a car that closed the gap from behind is one
## `Crowd._keep_room_for_the_turning()` was already braking for, and a car sitting *ahead* of the
## landing is one nothing in the lane's following rule ever touches, since that rule deliberately
## leaves alone everybody the landing is driving away from.
##
## Measured off `from`, the car's own position on the last frame of the arc, which is within a
## frame's travel of where the arc actually ends.
func _why_the_landing_retreated(city: City, landed: CrowdAgent, from: Vector2,
		moved: float) -> String:
	var key := landed.lane_key()
	var at := (from.y if landed._vertical else from.x) * landed._direction
	var nearest := INF
	for other: CrowdAgent in city.crowd.agents():
		if other == landed or other.kind != CrowdAgent.Kind.CAR or other.lane_key() != key:
			continue
		var offset := other.queue_position() - at
		if absf(offset) < absf(nearest):
			nearest = offset
	if nearest == INF:
		return "flung %.0fpx back into an exit lane with nobody else in it" % moved
	return "flung %.0fpx back; nearest car in the exit lane was %.0fpx %s the landing" \
			% [moved, absf(nearest), "ahead of" if nearest > 0.0 else "behind"]

## Whether a world point is inside the play viewport around the field's centre — 1280x720 design
## pixels at the play zoom of 2, which is `Tuning.VIEW_HALF_EXTENT` of world either way.
func _on_screen(at: Vector2, focus: Vector2) -> bool:
	var offset := at - focus
	return absf(offset.x) <= Tuning.VIEW_HALF_EXTENT.x \
			and absf(offset.y) <= Tuning.VIEW_HALF_EXTENT.y

## What this car was doing over the frame it jumped in.
##
## **`_cruise` is what names a recycle and nothing else does.** It is written only by
## `_choose_lane()` and `_take_the_placement()`, which is to say only by `setup()` and
## `_recycle()`; `_give_way()` moves `_speed` every frame and leaves this alone, so a car whose
## cruise changed between two frames is a car that was handed a fresh lane — a teleport by
## construction, and legal out of sight.
func _classify(was: Array, agent: CrowdAgent) -> String:
	var was_turning: bool = was[1]
	var was_cruise: float = was[2]
	var was_pocketed: bool = was[3]
	if not is_equal_approx(was_cruise, agent._cruise):
		return "recycle"
	if was_turning and not agent.is_turning():
		return "turn-landed"
	if was_turning and agent.is_turning():
		return "turn-arc"
	if agent.is_turning():
		return "turn-started"
	if was_pocketed or agent._is_in_a_pocket():
		return "pocket"
	return "spacing"
