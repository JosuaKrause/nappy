class_name Crowd
extends Node
## The city's own traffic: everyone who is not the player and not an event.
##
## This is where the noise floor comes from. Before it, a day could be won by circling the
## starting block, because an empty street was as quiet as a park; the city was decoration.
## Now a street is loud in proportion to how busy it is, a park is quiet because nobody is
## in it, and the player can see exactly why in both cases. Nothing in here is a
## city-wide constant — the floor is emergent, and it is standing right in front of you.
##
## Lookup is a linear scan, as it is for events. The population is an order of magnitude
## larger (around 120 rather than 22) and it is still one distance check each, once per
## physics frame, for the single query the baby makes.
##
## **Since M27 the crowd lives in a box that travels with the player** rather than being spread
## across the whole map — see `CrowdField` for why, and `Tuning.CROWD_PEDESTRIANS_PER_ACT` for
## what it did to the numbers.

## The traffic's name on the mark over the player's head, so it can take its own down again and
## nobody else's. See `Stroller.stand_down()`.
const WARNING_SOURCE := &"traffic"

var _agents: Array[CrowdAgent] = []
var _city: City
var _map: CityMap
var _player: Stroller
## The patch of city being simulated. Held here, moved onto the player every physics frame, and
## read by every agent when it recycles.
var _field: CrowdField
## A day only ends once, so a second car cannot claim the same run.
var _struck := false

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map
	_field = CrowdField.new(map, map.tile_rect_to_world(
			Rect2i(Vector2i.ZERO, map.size)).get_center())

## Clears yesterday's crowd and populates today's. The population is fixed for the day and
## comes from the act, not the day: the streets thin out as the occupation settles in, and
## act III's empty city is told here rather than announced anywhere.
##
## `focus` is where the day's crowd is built around — the doorstep, in a real run. It defaults
## to the middle of the map, which is what a rig with no player wants and, more to the point, is
## somewhere: leaving the field wherever the last caller put it makes a day's crowd depend on
## the order the tests before it ran in, and a field parked off the map builds the whole
## population on one pixel.
func start_day(day: int, rng: RandomNumberGenerator, focus := Vector2.INF) -> void:
	clear()
	_struck = false
	_field.centre = focus if focus != Vector2.INF else _map.tile_rect_to_world(
			Rect2i(Vector2i.ZERO, _map.size)).get_center()
	var act := Tuning.act_for_day(day)
	_populate(CrowdAgent.Kind.WALKER, Tuning.crowd_pedestrians(act), rng)
	_populate(CrowdAgent.Kind.CAR, Tuning.crowd_cars(act), rng)

## Where the simulated patch of city is centred. `Crowd` moves it onto the player itself; this
## exists so `main` can put it on the doorstep before the player is standing there.
func set_focus(at: Vector2) -> void:
	_field.centre = at

func field() -> CrowdField:
	return _field

func clear() -> void:
	for agent in _agents:
		agent.queue_free()
	_agents.clear()

## Agents alternate axes rather than rolling for one, so a crowd is never accidentally all
## north-south on a day when the coin came up that way.
func _populate(kind: CrowdAgent.Kind, count: int, rng: RandomNumberGenerator) -> void:
	for i in count:
		var agent := CrowdAgent.new()
		agent.setup(kind, _map, _field, rng.randi(), 0.0 if i % 2 == 0 else 1.0)
		_city.add_entity(agent)
		_agents.append(agent)

# ----------------------------------------------------------------- traffic ---
# Playtest 04: *"cars still bump into each other."* Until M27 a car knew about the player and
# about zebras and about nothing else on the road, so two cars in the same lane at different
# speeds simply passed through one another — which, at M27's density, stops being an
# occasional glitch and becomes what the road looks like.
#
# The decision is one pass over the crowd here rather than a probe per car, for the same reason
# `pedestrian_ahead` is written here: the agents are already being walked once a frame, and a
# per-car search would be the same work done fifty times over.

## Tells every car how much clear road it has in front of it, and pulls apart any two that have
## ended up in the same piece of it.
##
## Cars are bucketed by the lane they are in, and a lane is sorted by how far along it each car
## is. That makes the whole thing one sort per lane rather than a comparison of every car
## against every other — which matters less for the frames than for the shape: "the car in
## front" is a property of a queue, and a queue is what a lane is.
##
## **The separation is positional, like the player's bump and for the same reason.** A brake is
## a *tendency*: it keeps a gap that already exists and it cannot open one that does not, so two
## cars that start inside each other both choose zero and stay there forever. Recycling puts a
## car into a lane at a point it cannot see, so that case is not hypothetical — it was most of
## the overlap the M27 probe measured. Resolving the queue from the front backwards fixes a
## whole chain in one pass, and the correction is a few pixels except in the case it exists for.
func space_out_the_traffic() -> void:
	var lanes := {}
	for agent in _agents:
		if agent.kind != CrowdAgent.Kind.CAR:
			continue
		agent.gap_ahead = INF
		var key := agent.lane_key()
		if not lanes.has(key):
			lanes[key] = [] as Array[CrowdAgent]
		lanes[key].append(agent)

	for key: String in lanes:
		var queue: Array[CrowdAgent] = lanes[key]
		if queue.size() < 2:
			continue
		queue.sort_custom(func(a: CrowdAgent, b: CrowdAgent) -> bool:
			return a.queue_position() < b.queue_position())
		# Front to back, so a car pushed back is pushed against a neighbour that has not been
		# placed yet rather than one that has.
		for i in range(queue.size() - 2, -1, -1):
			var gap := queue[i + 1].queue_position() - queue[i].queue_position()
			if gap < Tuning.CAR_GAP_MIN:
				queue[i].nudge_back(Tuning.CAR_GAP_MIN - gap)
				gap = Tuning.CAR_GAP_MIN
			queue[i].gap_ahead = gap

# ----------------------------------------------------------------- contact ---
# Playtest 02, findings 2 and 3. Until M19 the crowd was a field with a picture attached: you
# could walk through a person, through a car, through a queue at a bus stop, and the only
# thing that happened was that a number moved. That is why the route was never a decision —
# every pavement was identical and none of them could hurt you.
#
# All three mechanisms live here rather than in `CrowdAgent` because all three are about the
# *player*, and an agent has no business knowing the player exists. One linear scan, the same
# shape and cost as the `total_excitement_at` the baby already runs every physics frame.

func _physics_process(_delta: float) -> void:
	# Before the player check, because traffic has to queue whether or not anybody is watching:
	# a car driving through another one at the far end of the street is still the thing playtest
	# 04 saw, and a test rig has no player in it.
	space_out_the_traffic()
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Stroller
		if not _player:
			return
	var here := _player.global_position
	_field.centre = here
	var on_the_road := Tile.is_road(_map.tile_type_at_world(here))
	var shove := Vector2.ZERO
	var closing := false

	# Where she is actually going, for the people about to be in the way of it. Zero while she is
	# standing still, which is right: nobody steps around somebody who is not coming.
	var going := _player.velocity
	if going.length() <= Tuning.IDLE_SPEED_THRESHOLD:
		going = Vector2.ZERO

	for agent in _agents:
		if agent.kind == CrowdAgent.Kind.WALKER:
			_make_way(agent, here, going)
			shove += _bump(agent, here)
			continue
		agent.pedestrian_ahead = Vector2.INF
		if agent.global_position.distance_to(here) > Tuning.CAR_ZEBRA_SIGHT:
			continue
		agent.pedestrian_ahead = here
		if not on_the_road:
			continue
		if _strike(agent, here):
			return
		closing = _horn(agent, here) or closing

	if shove != Vector2.ZERO:
		_player.shove(shove.normalized() * Tuning.BUMP_SHOVE_SPEED)
	# The exclamation mark says *the fairness contract is now about you and the clock has
	# started* — the load-bearing cue of M22's vocabulary, built here because M19 is what
	# creates the danger it warns about. See docs/EVENTS.md, "The visual vocabulary".
	#
	# `SOON` rather than `NOW`: standing in the carriageway with a car coming is a spot that is
	# about to be bad, and the whole contract is that there is time to walk off it. The mark is
	# raised for the rest of the hold rather than for this frame, so it survives the gap between
	# two cars in the same lane instead of strobing.
	#
	# And it comes down the instant she is off the carriageway. *(Playtest 06, finding 3: "when I
	# cross and they honk at me, I get the flashing exclamation marks **after** the fact, at which
	# point they're not useful.")* The hold is doing a real job and is not the bug — a car cannot
	# strike her on the pavement at all, so the two cases the hold could not tell apart are
	# *between two cars* and *over the kerb*, and the kerb is a fact this loop already has in
	# hand. Only the warning the traffic itself raised is taken down; see `Stroller.stand_down`.
	if closing:
		_player.warn(Stroller.Alert.SOON, Tuning.CAR_WARNING_HOLD, WARNING_SOURCE)
	elif not on_the_road:
		_player.stand_down(WARNING_SOURCE)

## Somebody standing in the way of where she is going moves over. *(Playtest 07, finding 17.)*
##
## The counterpart to `_bump`, and the reason the pair of them is the whole answer: a bump is what
## happens when this fails. See `Tuning.CROWD_YIELD_DISTANCE` for why a *behaviour* replaced the
## two-pixel line the crowd's "careful is free" half used to rest on.
##
## Three things keep it from being a crowd that simply evaporates in front of her:
##
## - **Only people actually in the way.** Ahead of her, within a lane's width of her line, and
##   inside a second of walking. Somebody on the far side of the pavement carries on.
## - **Only a lane, and never into the road.** `CrowdAgent.step_aside` clamps to the footway.
## - **Only if she gives them time.** The notice distance is fixed and their steering is not, so a
##   run arrives before they have cleared — which is one more thing running is bad at, and it did
##   not need a new rule to say so.
func _make_way(agent: CrowdAgent, here: Vector2, velocity: Vector2) -> void:
	if velocity == Vector2.ZERO:
		return
	var offset := agent.global_position - here
	var going := velocity.normalized()
	if offset.dot(going) <= 0.0 or offset.length() > Tuning.CROWD_YIELD_DISTANCE:
		return

	# **Closest approach, not current distance from her line.** The first version asked whether a
	# walker was already within a lane's width of her path, which is the right question for
	# somebody walking the same pavement and a useless one for somebody crossing it: at 60px/s
	# they enter that window a third of a second before the contact, and a probe said nine of
	# every twelve contacts are exactly that walker. Predicting where the two of them will be is
	# the only notice that arrives in time to be acted on.
	var relative := agent.velocity() - velocity
	var speed_squared := relative.length_squared()
	if speed_squared < 1.0:
		return
	var closest := clampf(-offset.dot(relative) / speed_squared, 0.0, Tuning.CROWD_YIELD_LEAD)
	if (offset + relative * closest).length() > Tuning.CROWD_YIELD_LATERAL:
		return

	# Whichever side of her line they are on **now**, so nobody crosses in front of her to get out
	# of the way — and so somebody already most of the way across carries on rather than reversing
	# into her. `CrowdAgent.step_aside` reads that as a sidestep or as hurrying-or-waiting
	# depending on which of its own axes the direction lands on.
	var side := Vector2(-going.y, going.x)
	var lateral := offset.dot(side)
	# **Except for somebody already standing on her line**, who has no side to be on. Told to
	# get out of the way sideways, half of them read it as "wait" and stop dead in front of her —
	# which is the one outcome worse than carrying on. Pointed along their own travel instead,
	# they always read it as "hurry", which is the only move that clears her.
	var away := side if lateral >= 0.0 else -side
	if absf(lateral) < Tuning.BUMP_CLEAR_RADIUS:
		away = agent.heading()
	agent.step_aside(away, Tuning.BUMP_STEP_ASIDE, Tuning.BUMP_STEP_ASIDE_TIME)

## Displaces a pedestrian the player has walked into, startles them, and returns the share of
## the separation she takes herself.
##
## The separation is positional rather than a force, so two bodies can never end up inside
## each other however fast she is going — and the agent recovers on its own, because it steers
## back to its lane centre at `STEER_SPEED` like it does after any other displacement.
##
## Two things here were found by walking a rig down a real pavement and reading the meter,
## and neither is visible to a data-level test:
##
## - **Somebody bumped along their own line of travel steps aside.** Pushing them straight
##   down it separates nobody: she walks at 92 and they walk at 60, so a person bumped from
##   behind is ploughed along the pavement in front of her indefinitely. The first version did
##   that and a forty-second walk arrived at the far end pushing a wedge of pedestrians and
##   taking 150 excitement per second.
## - **A contact startles once, not once per frame.** `touching` is the hysteresis. Otherwise
##   one person held in contact for half a second costs what walking through a crowd should.
## - **And a contact has to be able to end.** *(Playtest 07, finding 5.)* Both halves of that
##   sentence were broken and each on its own is enough to trap her:
##
##   The separation resolved to exactly `BUMP_RADIUS`, which is the same number `touching` is
##   released at — so a resolved pair sits on its own threshold, crosses it every other frame, and
##   fires a fresh jolt each time. The hysteresis existed and was one number wide. It is a band
##   now: pushed apart to `BUMP_CLEAR_RADIUS`, released past it.
##
##   And a walker steers back to its lane centre. If she is *standing on* that centre it comes
##   straight back into her, so the contact resolves and re-forms for as long as she is there. The
##   fix is the thing a person actually does: `step_aside`, which moves the walker's steering
##   target a lane over for a couple of seconds. Still positional, still nothing pushed at the
##   player — only what the walker is aiming for changed.
func _bump(agent: CrowdAgent, here: Vector2) -> Vector2:
	var away := agent.global_position - here
	var distance := away.length()
	# Released at the wider radius, so a pair that has just been pushed apart is unambiguously
	# apart rather than sitting on the boundary.
	if distance >= Tuning.BUMP_CLEAR_RADIUS:
		agent.touching = false
		return Vector2.ZERO
	if distance >= Tuning.BUMP_RADIUS and not agent.touching:
		# Inside the release band but never actually touched: this is somebody she is walking
		# alongside, not somebody she walked into.
		return Vector2.ZERO

	# Exactly on top of each other: pick a side rather than dividing by zero.
	var direction := away / distance if distance > 0.01 else Vector2.RIGHT
	var forward := agent.heading()
	if absf(direction.dot(forward)) > 0.5:
		var side := Vector2(-forward.y, forward.x)
		direction = side if side.dot(away) >= 0.0 else -side

	# To the clear radius rather than to the contact radius. The difference is the whole of
	# whether the contact is over on the next frame.
	var overlap := Tuning.BUMP_CLEAR_RADIUS - distance
	agent.global_position += direction * overlap * (1.0 - Tuning.BUMP_PLAYER_SHARE)
	if not agent.touching:
		agent.touching = true
		agent.startle(Tuning.BUMP_INTENSITY, Tuning.BUMP_DURATION,
				Tuning.BUMP_INNER_RADIUS, Tuning.BUMP_OUTER_RADIUS)
		EventBus.crowd_bumped.emit(here)
	# Whichever way they were pushed, keep going that way: the walker's own steering is what
	# would otherwise undo the separation the instant it is made.
	agent.step_aside(direction, Tuning.BUMP_STEP_ASIDE, Tuning.BUMP_STEP_ASIDE_TIME)
	return -direction * overlap

## A car strike, which ends the day.
##
## Two things keep it fair, and both are geometry rather than a warning: the box is the car
## the player can see, and it only counts while she is standing on the carriageway. The kerb
## is the edge she chose to step over — the same shape of contract the alley robbery has,
## where the alley is the warning. See `Tuning.validate_traffic()`.
func _strike(agent: CrowdAgent, here: Vector2) -> bool:
	if _struck or agent.speed() < Tuning.CAR_STRIKE_MIN_SPEED:
		return false
	var forward := agent.heading()
	var offset := here - agent.global_position
	if absf(offset.dot(forward)) > Tuning.CAR_STRIKE_HALF_LENGTH:
		return false
	if absf(offset.dot(Vector2(-forward.y, forward.x))) > Tuning.CAR_STRIKE_HALF_WIDTH:
		return false
	_struck = true
	EventBus.hard_fail_triggered.emit("car_strike")
	return true

## The horn, sounded at somebody standing in the lane this car is about to occupy. Returns
## true while the car is closing, which is what puts the mark over the player's head.
func _horn(agent: CrowdAgent, here: Vector2) -> bool:
	var forward := agent.heading()
	var offset := here - agent.global_position
	var ahead := offset.dot(forward)
	if ahead <= 0.0 or ahead > agent.speed() * Tuning.CAR_HORN_TIME:
		return false
	if absf(offset.dot(Vector2(-forward.y, forward.x))) > Tuning.CAR_STRIKE_HALF_WIDTH * 2.0:
		return false
	if not agent.is_startled():
		EventBus.car_near_miss.emit(here)
	agent.startle(Tuning.CAR_HORN_INTENSITY, Tuning.CAR_HORN_DURATION,
			Tuning.CAR_HORN_INNER_RADIUS, Tuning.CAR_HORN_OUTER_RADIUS)
	return true

# ------------------------------------------------------------ WorldContext ---

## Summed excitement per second from everyone within earshot.
func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for agent in _agents:
		total += agent.contribution_at(world_position)
	return total

func agent_count() -> int:
	return _agents.size()

func agents() -> Array[CrowdAgent]:
	return _agents
