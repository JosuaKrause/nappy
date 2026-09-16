extends RefCounted
## Every frame-to-frame jump a car makes that it could not have driven, and whether the player
## could see it happen — the bisection probe for *"cars are super buggy now. when they turn in the
## final stretch the teleport a car length somewhere else"* (playtest 76, 2026-09-15).
##
## **A recycle is a teleport by construction and the design allows exactly one of them**: the one
## that happens where nobody is looking. So the question is never *did a car move further than it
## drove* — several do, every second, out at the entry band — it is **where the camera was when it
## did**. Every jump is classified and counted; only the ones inside the play viewport are
## defects.
##
## What it measures, per physics frame of a rig day, for every car in the crowd:
##
## - the step it actually took, against `2 · CAR_SPEED.y · delta` — twice what the fastest car
##   could cover, so lane travel, the cross-steer and the separation pass's ordinary few pixels
##   are all comfortably under it and nothing but a placement clears it;
## - what the car was doing at the time — following an arc, landing one, caught in a pocket, given
##   a fresh lane by `_recycle()`, or none of those, which leaves the separation pass;
## - whether either end of the jump was inside `Tuning.VIEW_HALF_EXTENT` (320 × 180 px, the
##   1280×720 viewport at the play zoom of 2) around the crowd field's centre, which is where the
##   camera is — `CrowdField.centre` is what `CrowdAgent._out_of_view()` measures against, and
##   `Tuning.OUT_OF_SIGHT` (420px) is the radius outside that box's own far corner (367px).
##
## The rig is a real generated city on a real day — closures planned, the day's events placed, so
## the hard seals and the pockets they make are the ones a player meets.
##
## **The focus walks to the day's closures rather than wandering.** A car only ever turns because
## something is in its way (`_divert()` calls `_plan_a_turn()`, and nothing else does for a car),
## so the junctions at a closure's mouths are the only places in the city where turns and
## turnarounds are dense — a focus parked anywhere else watches straight traffic for a minute and
## reports nothing. It walks between them at `Tuning.WALK_SPEED` rather than jumping, because a
## field whose centre teleports recycles the whole crowd at once and every one of those recycles
## would be scored against the frame the camera landed on.
##
## Run it with `tools/test.sh probes/m152_car_jumps.gd`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 60.0

## The cities and the days. Day 1 is the busiest road the game has (34 cars, act I) and day 13 the
## most closed (4 closures, act IV) — the two ends of the axis the defect is reported on.
const SEEDS: Array[int] = [4242, 24757, 91117]
const DAYS: Array[int] = [1, 13]
const SECONDS := 40.0

## How long the focus dwells on one closure mouth before walking to the next, in seconds.
const DWELL_SECONDS := 6.0
## How far inside the map the focus is kept, in px, so the field is never half off the city.
const FOCUS_MARGIN := 420.0

## Anything above this in one frame is further than a car could have driven. Twice the fastest
## car's own step, so the cross-steer and a `nudge_back` of a few pixels never reach it.
static func _jump_threshold() -> float:
	return 2.0 * Tuning.CAR_SPEED.y * STEP

func run(t) -> void:
	var totals := {}
	var in_view_total := 0
	var cars_seen := 0
	var worst := []
	print("m152 car-jump probe — threshold %.2f px/frame (2 x CAR_SPEED.y x %.4fs), view box %s"
			% [_jump_threshold(), STEP, Tuning.VIEW_HALF_EXTENT])
	for city_seed in SEEDS:
		var map := CityGenerator.generate(city_seed)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		for day in DAYS:
			var result := _watch(city, map, city_seed, day)
			cars_seen += int(result["cars"])
			in_view_total += int(result["in_view"])
			var classes: Dictionary = result["classes"]
			for key: String in classes:
				totals[key] = int(totals.get(key, 0)) + int(classes[key])
			if result["worst"] != "":
				worst.append(result["worst"])
		city.free()
	print("")
	print("TOTAL over %d seeds x days %s, %.0fs each: %d cars watched"
			% [SEEDS.size(), DAYS, SECONDS, cars_seen])
	for key: String in _class_order():
		if totals.has(key):
			print("    %-14s %5d   %s" % [key, int(totals[key]),
					_tail(key, totals)])
	if not worst.is_empty():
		print("  worst in-view jump per rig day:")
		for line: String in worst:
			print("    %s" % line)
	print("PROBE m152 in-view jumps: %d" % in_view_total)
	t.check(cars_seen > 0, "the rig days put cars on the road to watch (%d)" % cars_seen)

## How a counted row reads. `landings` and `turn-rounds` count every one that happened, jump or
## no jump, so they are the denominators the jump rows are read against; every other row counts
## jumps alone and carries how many of them the camera was looking at.
static func _tail(key: String, counts: Dictionary) -> String:
	if key == "landings" or key == "turn-rounds":
		return "(every one, jump or not)"
	return "(%d in view)" % int(counts.get(key + "/in-view", 0))

## The classes a jump is put in, in the order a report reads them. `recycle` is the legal one and
## is only a defect when it happens in view; everything else is a defect wherever it happens, and
## is counted in view and out so the two can be told apart.
static func _class_order() -> Array[String]:
	return ["landings", "turn-rounds", "recycle", "turn-landed", "turn-arc", "turn-started",
			"pocket", "spacing"]

# ------------------------------------------------------------------------ rig ---

## One seed's day, watched frame by frame. Returns the jump counts by class and how many of them
## the camera was looking at.
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
	var in_view := 0
	var worst_jump := 0.0
	var worst_line := ""
	var seen_ids := {}
	var before := {}
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
			before[id] = [agent.position, agent.is_turning(), agent._cruise,
					agent._is_in_a_pocket(), agent._direction, agent._vertical]

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
			# Counted whether or not it jumped, because what the fix has to be judged on is the
			# *share* of landings that end in a teleport rather than the raw count of teleports —
			# see `_land_the_turn()`, which drops an arrival that finds its booked spot taken at
			# the back of the whole exit lane.
			if bool(was[1]) and not agent.is_turning():
				classes["landings"] = int(classes.get("landings", 0)) + 1
			# A car reversing on the spot with no arc at all: `_turn_round()`, which flips the
			# heading and swaps the lane in one frame. The player's *"instead of routing a turn
			# (or u turn) they just teleport"* is what this looks like from outside. A recycle
			# flips a direction too and is a different thing entirely, so it is excluded by the
			# same `_cruise` reading `_classify()` uses.
			if not bool(was[1]) and not agent.is_turning() and bool(was[5]) == agent._vertical \
					and not is_equal_approx(float(was[4]), agent._direction) \
					and is_equal_approx(float(was[2]), agent._cruise):
				classes["turn-rounds"] = int(classes.get("turn-rounds", 0)) + 1
				if _on_screen(agent.position, focus):
					classes["turn-rounds/in-view"] = \
							int(classes.get("turn-rounds/in-view", 0)) + 1
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

	return {"classes": classes, "in_view": in_view, "cars": seen_ids.size(),
			"worst": worst_line}

## The places in this day's city a car actually has a reason to turn: the mouths of every closure,
## which is where a lane runs into something and `_divert()` plans an arc. The doorstep is the
## fallback for a day that planned none, so the walk always has somewhere to go.
func _places_cars_turn(city: City, map: CityMap, doorstep: Vector2) -> Array[Vector2]:
	var stops: Array[Vector2] = []
	for closure: RoadClosure in city.closures():
		for mouth: Vector2 in closure.mouth_centres(map):
			stops.append(mouth)
	if stops.is_empty():
		stops.append(doorstep)
	return stops

## What the exit lane looked like at the moment a landing was flung to the back of it.
##
## `_land_the_turn()` only retreats when `_has_room_here()` says the spot it booked is taken, so
## the useful number is **which** car took it and from which side — a car that closed the gap from
## behind is one `Crowd._keep_room_for_the_turning()` was already braking for, and a car sitting
## *ahead* of the landing is one nothing in the lane's following rule ever touches, since that rule
## deliberately leaves alone everybody the landing is driving away from.
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
