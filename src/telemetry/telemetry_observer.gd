class_name TelemetryObserver
extends Node
## Watches the player and writes down what happened to them.
##
## The other half of the log is written by the systems that make the decisions — a one-shot
## that fired, a block that moved along its arc, an alley that was a trap. Those are single
## lines at the point of the roll. This is everything that has no such point: where the player
## went, when they turned back, when they ran, what came near, when sleep froze.
##
## It lives in one node on purpose. The alternative is a telemetry branch in `_physics_process`
## of every gameplay class, and the invariant that matters most here — **telemetry must not
## touch gameplay** — is much easier to keep when the telemetry is not in the gameplay files.
## Nothing below writes to anything. It reads positions and meters and emits lines.
##
## It is only added to the tree when a run is being traced, so when telemetry is off this
## costs nothing at all rather than costing a disabled check per frame.

## How far off the committed heading counts as doubling back rather than turning a corner.
## A lap of a block is four ninety-degree turns and must not read as four reversals.
const TURN_ANGLE := deg_to_rad(120.0)
## How long a heading must be held before a reversal of it is worth recording, and how long
## the reversal must last. Together they ignore a stumble at a kerb.
const TURN_COMMIT_TIME := 1.0
const TURN_HOLD_TIME := 0.4
## How fast the committed heading follows a gradual change of direction. Slow enough that a
## deliberate about-turn still registers, fast enough that walking a curve never does.
const TURN_FOLLOW_RATE := 1.5

## How close to a barrier counts as having seen it. A street is six tiles wide, so this is
## roughly "standing at the junction it is visible from", which is where a closure is meant
## to become a decision.
const CLOSURE_SIGHT := 200.0
## A turn this soon after seeing a barrier is recorded as being about the barrier. It is the
## difference between "closures are a decision" and "closures are scenery", and it is the
## only thing in this file that joins two entries together.
const CLOSURE_TURN_WINDOW := 6.0

## An encounter is logged when something comes within its own outer radius — the distance at
## which it starts to reach the meter, so the threshold is the event's rather than a number
## invented here. It is logged again each time the distance falls to this fraction of the
## last entry, which is what turns "it was near" into "it was closing".
const NEAR_CLOSER_FRACTION := 0.55
## Below this there is nothing left to say; the next thing that happens is a hard fail or it
## passes. Stops a slow pass through a wide radius writing a column of lines.
const NEAR_FLOOR := 26.0

## Ignore a run shorter than this: it is a fumbled key, not a decision.
const RUN_MIN_TIME := 0.25

## And how long standing still stops being a pause at a kerb and starts being a plan.
##
## Two seconds is roughly what waiting for one car to pass costs, so anything past it was waiting
## for something slower than the traffic — which since playtest 07 can only be the clock.
const IDLE_MIN_TIME := 2.0

## How long on the road stops being a crossing and starts being a walk down it.
##
## The carriageway is two tiles of a six-tile corridor, so crossing one costs about 0.7s at
## walking pace and a whole junction about two. Anything past this was not on its way to the
## other side — which means **the presence of a `road` entry is itself the finding**, and the
## reader does not have to judge a duration to see it.
const ROAD_LINGER := 2.5

## A packed pavement is four hundred walkers, and since M19 walking into one is a thing that
## can happen several times a second. This is the floor on how often a *bump* may say anything;
## a horn is exempt, because a car that had to sound its horn at her is the whole question M19
## exists to answer and must never be dropped for being one of several.
const BUMP_QUIET_TIME := 1.5

## How close to the chalk mark counts as having found it. Generous on purpose — the question
## being answered is "did the player ever go near a contact", not "did they use it".
const CONTACT_SIGHT := 130.0

var _city: City
var _map: CityMap
var _player: Stroller
var _baby: Baby
var _day: DayController
var _resistance: ResistanceDirector
## The screen-edge badges. Optional: everything else here is reachable from the world, and this
## one lives in a `CanvasLayer` that `main` owns.
var _edge: DangerEdge

# Tile and ground state, so a transition can be spotted.
var _was_calm := false
var _was_road := false
var _was_frozen := false

# Time spent on the road surface without leaving it, and where that stretch began.
var _road_since := 0.0
var _road_from := Vector2i.ZERO
var _carriageway := 0.0

# When a bump was last written down, and how many have gone unwritten since.
var _last_bump := -1000.0
var _bumps_dropped := 0

# Doubling back.
var _committed := Vector2.ZERO
var _committed_for := 0.0
var _against := 0.0

# Running.
var _running := false
var _run_started := 0.0
var _run_excitement := 0.0
var _run_nearest := ""

# Standing still, and what the meters did while she did.
var _idling := false
var _idle_since := 0.0
var _idle_excitement := 0.0
var _idle_sleepiness := 0.0

# Encounters: instance id -> the distance at which it was last written down. Ids rather than
# references, so this can never keep a freed event alive.
var _near := {}

# Closures seen today, keyed by segment, and when the last one was seen.
var _seen_closures := {}
var _last_closure := ""
var _last_closure_at := -1000.0

# The resistance contact.
var _contact_seen := false
var _hold_started := false

# The cues. What was up over her head, since when, and how much of that she spent on the road;
# and which edge badges are up, each with the clock reading it went up at.
var _mark := Stroller.Alert.NONE
var _mark_since := 0.0
var _mark_on_road := 0.0
var _mark_why := ""
var _badges := {}

func setup(city: City, player: Stroller, baby: Baby, day: DayController,
		resistance: ResistanceDirector, edge: DangerEdge = null) -> void:
	_city = city
	_map = city.map
	_player = player
	_baby = baby
	_day = day
	_resistance = resistance
	_edge = edge
	EventBus.return_phase_started.connect(_on_asleep)
	EventBus.baby_state_changed.connect(_on_baby_state_changed)
	EventBus.resistance_seen.connect(_on_resistance_seen)
	EventBus.resistance_hold_changed.connect(_on_hold_changed)
	EventBus.city_went_quiet.connect(_on_city_went_quiet)
	EventBus.crowd_bumped.connect(_on_bumped)
	EventBus.car_near_miss.connect(_on_near_miss)

## Clears yesterday. Called after the day's plan has been written, so the `start` line is the
## first thing under the header that the player is responsible for.
func start_day() -> void:
	_was_calm = _city.is_calm_zone(_player.global_position)
	_was_road = Tile.is_road(_map.tile_type_at_world(_player.global_position))
	_was_frozen = false
	_road_since = 0.0
	_road_from = _map.world_to_tile(_player.global_position)
	_carriageway = 0.0
	_last_bump = -1000.0
	_bumps_dropped = 0
	_committed = Vector2.ZERO
	_committed_for = 0.0
	_against = 0.0
	_running = false
	_near.clear()
	_seen_closures.clear()
	_last_closure = ""
	_last_closure_at = -1000.0
	_contact_seen = false
	_hold_started = false
	_mark = Stroller.Alert.NONE
	_mark_since = 0.0
	_mark_on_road = 0.0
	_mark_why = ""
	_badges.clear()
	Telemetry.note("start", "doorstep %s, facing %s" % [
		TelemetryLog.tile(_map.world_to_tile(_player.global_position)),
		TelemetryLog.compass(_player.facing)])

## The end of the day, with what was around at the moment it ended. Called by `main.gd`
## before the calendar advances, so the outcome is written above the nerve it cost.
func day_finished(result: GameEnums.DayResult) -> void:
	# Above the outcome, because it is part of how the day got there.
	_flush_road(_player.global_position)
	var name: String = GameEnums.DayResult.keys()[result]
	if result == GameEnums.DayResult.WON:
		Telemetry.note("home", "WON, %.1fs to spare" % _day.time_remaining)
		return
	Telemetry.note("lost", "%s after %.1fs — %s | %s | near: %s" % [
		name.to_lower(), _day.time_total - _day.time_remaining,
		_day.failure_reason, _meters(), _nearest()])

# ------------------------------------------------------------------- watching ---

func _process(delta: float) -> void:
	if not _day.is_running():
		return
	Telemetry.set_clock(_day.time_total - _day.time_remaining)
	var here := _player.global_position
	_watch_the_ground(here, delta)
	_watch_the_cues(delta)
	_watch_the_meters()
	_watch_running()
	_watch_idling(delta)
	_watch_direction(delta)
	_watch_what_is_near(here)
	_watch_closures(here)
	_watch_the_contact(here)

## Crossing into the road, and arriving on or leaving calm ground. Both are transitions, so
## both are one line each rather than a state the reader has to infer from a gap.
##
## The road half is a transition *and* a duration. The first version logged only the step onto
## the road, and a player walking a mile down the middle of the carriageway produced exactly
## the same entries as one crossing at every junction — five `cross` lines either way. The
## question "did they walk down the road" could only be answered by comparing coordinates by
## hand, which is the sort of inference this format exists to make unnecessary.
func _watch_the_ground(here: Vector2, delta: float) -> void:
	var type := _map.tile_type_at_world(here)

	var road := Tile.is_road(type)
	if road:
		if not _was_road:
			_road_since = Telemetry.clock()
			_road_from = _map.world_to_tile(here)
			_carriageway = 0.0
			Telemetry.note("cross", "stepped into the road at %s, %s" % [
				TelemetryLog.tile(_road_from),
				"at a zebra" if type == GameEnums.TileType.CROSSING else "mid-block"])
		if type == GameEnums.TileType.ROAD:
			_carriageway += delta
	elif _was_road:
		_flush_road(here)
	_was_road = road

## Writes down a stretch on the road, if it lasted longer than crossing one takes.
##
## Called when the player steps off — and again when the day ends, because a day that ends
## *while* she is in the carriageway is the most interesting case there is and the first
## version silently dropped it: a player killed by the traffic they were walking among got no
## `road` entry at all, having never left it.
func _flush_road(here: Vector2) -> void:
	if not _was_road:
		return
	var stayed := Telemetry.clock() - _road_since
	if stayed < ROAD_LINGER:
		return
	Telemetry.note("road", "%.1fs on the road (%.1fs of it carriageway), %s -> %s" % [
		stayed, _carriageway, TelemetryLog.tile(_road_from),
		TelemetryLog.tile(_map.world_to_tile(here))])
	_was_road = false

	var calm := _city.is_calm_zone(here)
	if calm != _was_calm:
		var block := _map.block_at(here)
		var what := TelemetryLog.purpose(
				GameState.city_state.purpose_of(_map.block_plans, block))
		Telemetry.note("calm" if calm else "left", "%s %s %s, sleep %.0f" % [
			"entered" if calm else "left", what, TelemetryLog.tile(block),
			_baby.sleepiness])
	_was_calm = calm

## What she was warned about, and for how long. *(Playtest 06.)*
##
## The gap playtest 05 named and 06 walked straight into: every other entry says what the world
## did, and nothing said what the **game told her about it** — so *"the offscreen indicators show
## events far away"* and *"I get the exclamation marks after the fact"* were both invisible to a
## trace and could only be found by a person looking at a screen. A cue is a claim about a
## moment, and until now nothing wrote the moment down.
##
## Two spans, and both are written when they **end**, carrying how long they lasted: a cue that
## is up too long is the whole complaint, and a duration is the only form of it that can be read.
## The `turn` or `run` entry between the two lines is the other half — whether she did anything
## about it.
func _watch_the_cues(delta: float) -> void:
	var level := _player.alert_level()
	if level != Stroller.Alert.NONE and Tile.is_road(
			_map.tile_type_at_world(_player.global_position)):
		_mark_on_road += delta
	if level != _mark:
		if _mark != Stroller.Alert.NONE:
			# How much of it she spent somewhere the danger could actually reach her. A mark that
			# is up on the pavement after a car has gone past is finding 3, with a number on it.
			Telemetry.note("cue", "the mark over her head: %s for %.1fs (%.1fs of it on the "
					% [Stroller.Alert.keys()[_mark].to_lower(),
					Telemetry.clock() - _mark_since, _mark_on_road]
					+ "road)%s" % _mark_why)
		if level != Stroller.Alert.NONE:
			_mark_since = Telemetry.clock()
			_mark_on_road = 0.0
			_mark_why = " | %s" % _what_raised_the_mark()
		_mark = level

	if not _edge:
		return
	var up := {}
	for badge in _edge.announcing():
		var id: String = badge["id"]
		up[id] = true
		if _badges.has(id):
			continue
		_badges[id] = Telemetry.clock()
		Telemetry.note("cue", "edge badge: %s at %.0fpx, closing %.0fpx/s"
				% [id, badge["distance"], badge["approach"]])
	for id: String in _badges.keys():
		if up.has(id):
			continue
		# Where the thing is *now* is the whole of *"if you walk towards them they sometimes
		# disappear"*: a badge that ends with the thing closer than it was either came into view
		# — which is the badge's job being done — or was dropped while it was still coming, and
		# only the distance tells the two apart.
		Telemetry.note("cue", "edge badge gone: %s after %.1fs, %s"
				% [id, Telemetry.clock() - _badges[id], _where_is(id)])
		_badges.erase(id)

## How far the nearest live instance of `id` is now, or that there is none left.
func _where_is(id: String) -> String:
	var best := INF
	for instance in _city.events.instances():
		if instance.def.id == id and not instance.is_finished:
			best = minf(best, instance.global_position.distance_to(_player.global_position))
	return "now %.0fpx away" % best if best < INF else "no longer in the world"

## What put the mark over her head, rather than what merely happened to be nearest.
##
## Since M30 exactly two things can: a `hard_fail` event whose radius covers her, and a car
## closing on the lane she is standing in. `_nearest()` answers a different question and answers
## it misleadingly here — the first version of this entry blamed an ice cream van 513px away for
## a car's horn, which is precisely the *"unattributable"* complaint playtest 05 made about the
## mark itself, reproduced in the log that was meant to settle it.
func _what_raised_the_mark() -> String:
	var here := _player.global_position
	for instance in _city.events.instances():
		if instance.is_finished or instance.def.city_wide or not instance.def.hard_fail:
			continue
		var distance := instance.global_position.distance_to(here)
		if distance <= instance.def.outer_radius:
			return "%s %.0fpx" % [instance.def.id, distance]
	if Tile.is_road(_map.tile_type_at_world(here)):
		return "a car, and she is in the road"
	return "nothing in reach"

## Freezing is the invisible failure: the meter simply stops and nothing on screen says why.
## A result code alone never distinguishes a day lost to noise from a day lost to the clock,
## which is the entire reason this entry exists.
func _watch_the_meters() -> void:
	var frozen := _baby.state != GameEnums.BabyState.ASLEEP \
			and _baby.excitement >= Tuning.EXCITEMENT_CALM_THRESHOLD
	if frozen == _was_frozen:
		return
	_was_frozen = frozen
	if frozen:
		Telemetry.note("freeze", "sleep stopped filling | %s | near: %s"
				% [_meters(), _nearest()])
	else:
		Telemetry.note("thaw", "settling again | %s" % _meters())

## Standing still, and what it bought. *(Playtest 07, finding 3: "not walking at all shouldn't
## reduce excitement either — otherwise I can just stop in the middle of the street and wait until
## everything is good. Is that info captured in the telemetry as well?")*
##
## It was not, and that is the whole reason the entry exists. Standing still emits nothing: no
## crossing, no turn, no contact, no event coming near. So the strongest move in the game showed
## up in a trace as a **gap between two lines** — a day-2 run in the playtest 07 logs has a
## seventy-four-second one — and a gap is exactly what a reader skips over. Two runs were being
## won by waiting and the log said nothing at all.
##
## Written when the stand *ends*, like the `cue` spans and for the same reason: the duration is
## the complaint. It carries what the meters did across it, because that is the question — a stand
## that clears thirty points of excitement is an exploit and a stand at a kerb waiting for a gap
## in the traffic is play, and only the numbers on either end tell them apart.
func _watch_idling(_delta: float) -> void:
	var idle := _player.is_idle()
	if idle == _idling:
		return
	_idling = idle
	if idle:
		_idle_since = Telemetry.clock()
		_idle_excitement = _baby.excitement
		_idle_sleepiness = _baby.sleepiness
		return
	var duration := Telemetry.clock() - _idle_since
	if duration < IDLE_MIN_TIME:
		return
	Telemetry.note("idle", "stood still %.1fs on %s, exc %.0f -> %.0f, sleep %.0f -> %.0f" % [
		duration, TelemetryLog.tile_type(_map.tile_type_at_world(_player.global_position)),
		_idle_excitement, _baby.excitement, _idle_sleepiness, _baby.sleepiness])

## Today the answer should always be "it made things worse". When that stops being true, M25
## has landed and this entry is how it will be judged.
func _watch_running() -> void:
	var running := _player.run_excess_ratio() > 0.0
	if running == _running:
		return
	_running = running
	if running:
		_run_started = Telemetry.clock()
		_run_excitement = _baby.excitement
		_run_nearest = _nearest()
		return
	var duration := Telemetry.clock() - _run_started
	if duration < RUN_MIN_TIME:
		return
	Telemetry.note("run", "ran %.1fs, exc %.0f -> %.0f, nearest when it started: %s" % [
		duration, _run_excitement, _baby.excitement, _run_nearest])

## Doubling back. Not every turn — a lap of a block is four corners and no decision, whereas
## walking back the way you came means something in front of you changed the plan.
func _watch_direction(delta: float) -> void:
	if _player.is_idle():
		return
	var heading := _player.velocity.normalized()
	if _committed == Vector2.ZERO:
		_committed = heading
		return

	if absf(_committed.angle_to(heading)) < TURN_ANGLE:
		_committed_for += delta
		_committed = _committed.lerp(heading, clampf(delta * TURN_FOLLOW_RATE, 0.0, 1.0))
		if _committed != Vector2.ZERO:
			_committed = _committed.normalized()
		_against = 0.0
		return

	_against += delta
	if _against < TURN_HOLD_TIME or _committed_for < TURN_COMMIT_TIME:
		return
	Telemetry.note("turn", "doubled back %s%s" % [
		TelemetryLog.compass(heading), _because_of_a_closure()])
	_committed = heading
	_committed_for = 0.0
	_against = 0.0

## The one place two entries are joined up. A turn just after a barrier came into view is the
## measurement behind "are closures a decision or scenery", and it cannot be recovered by
## reading two independent lines because the reader would have to guess the window.
func _because_of_a_closure() -> String:
	if _last_closure == "" or Telemetry.clock() - _last_closure_at > CLOSURE_TURN_WINDOW:
		return ""
	return ", %.1fs after seeing the %s" % [
		Telemetry.clock() - _last_closure_at, _last_closure]

## What came within reach, and whether it kept coming. The threshold is the event's own outer
## radius — the distance at which it starts to reach the meter — so nothing here invents a
## number about what "near" means.
func _watch_what_is_near(here: Vector2) -> void:
	var live := {}
	for instance in _city.events.instances():
		# A field with no edge cannot be approached, so "near" is meaningless for it. What a
		# city-wide source is doing to the meter shows up in every `freeze` line instead.
		if instance.def.city_wide or instance.is_finished:
			continue
		var id := instance.get_instance_id()
		var distance := instance.global_position.distance_to(here)
		if distance > instance.def.outer_radius:
			continue
		live[id] = true
		var last: float = _near.get(id, INF)
		if distance > last * NEAR_CLOSER_FRACTION and last != INF:
			continue
		if last <= NEAR_FLOOR:
			continue
		_near[id] = distance
		# The position is what tells two instances of the same event apart. Three dog walkers
		# are out on a normal day, and "the same one kept following the route" and "three
		# different ones" are the same two lines without it.
		Telemetry.note("near", "%s%s at %s, %.0fpx, %s" % [
			instance.def.id, " (telegraph)" if instance.is_telegraphing() else "",
			TelemetryLog.tile(_map.world_to_tile(instance.global_position)),
			distance, _meters()])
	for id: int in _near.keys():
		if not live.has(id):
			_near.erase(id)

## A barrier coming into view. Recorded from where it was seen, because "the player found out
## two junctions later" and "the player could see it from the corner" are different days and
## the map screen M17 adds exists to change which one this is.
func _watch_closures(here: Vector2) -> void:
	for closure in _city.closures():
		var key := closure.segment.key()
		if _seen_closures.has(key):
			continue
		for mouth in closure.mouth_centres(_map):
			if mouth.distance_to(here) > CLOSURE_SIGHT:
				continue
			_seen_closures[key] = true
			_last_closure = RoadClosure.display_name(closure.kind).to_lower()
			_last_closure_at = Telemetry.clock()
			Telemetry.note("closure", "saw the %s on %s%s from %s" % [
				_last_closure, "h" if closure.segment.horizontal else "v",
				TelemetryLog.tile(closure.segment.a),
				TelemetryLog.tile(_map.world_to_tile(here))])
			break

## Whether the player ever went near a chalk mark. "Nobody ever finds it" is the thing that
## would falsify the standing decision to leave the resistance unmarked, so it has to be
## measurable — and finding one is not the same as using one, hence two separate entries.
func _watch_the_contact(here: Vector2) -> void:
	if _contact_seen:
		return
	var at := _resistance.contact_position()
	if at == Vector2.INF or at.distance_to(here) > CONTACT_SIGHT:
		return
	_contact_seen = true
	Telemetry.note("contact", "walked within %.0fpx of the chalk mark at %s"
			% [at.distance_to(here), TelemetryLog.tile(_map.world_to_tile(at))])

# ------------------------------------------------------------------- signals ---

func _on_asleep() -> void:
	Telemetry.note("asleep", "asleep after %.1fs, %s" % [Telemetry.clock(), _meters()])

func _on_baby_state_changed(state: GameEnums.BabyState) -> void:
	if not _day.is_running():
		return
	if state == GameEnums.BabyState.AWAKE:
		Telemetry.note("woke", "woken on the way home, sleep back to %.0f | near: %s"
				% [_baby.sleepiness, _nearest()])

func _on_resistance_seen() -> void:
	Telemetry.note("contact", "a patrol came past mid-handover; the hold reset")

func _on_hold_changed(progress: float) -> void:
	if _hold_started or progress <= 0.0:
		return
	_hold_started = true
	Telemetry.note("contact", "started the hold")

func _on_city_went_quiet() -> void:
	Telemetry.note("quiet", "the sabotage went through; every city-wide source is off")

## Walking into somebody. Reported by `Crowd` rather than watched from here, because since M19
## the contact is a decision the game makes rather than a state to be noticed — but the *rate
## limiting* stays here, with the rest of what keeps the log readable.
##
## The dropped count is printed rather than silently swallowed: "she bumped somebody at 0:14"
## and "she ploughed through fourteen people between 0:12 and 0:14" are very different days,
## and without the number they are the same line.
func _on_bumped(at: Vector2) -> void:
	if not _day.is_running():
		return
	if Telemetry.clock() - _last_bump < BUMP_QUIET_TIME:
		_bumps_dropped += 1
		return
	var also := "" if _bumps_dropped == 0 else " (+%d in the last %.1fs)" % [
		_bumps_dropped, Telemetry.clock() - _last_bump]
	_last_bump = Telemetry.clock()
	_bumps_dropped = 0
	Telemetry.note("crowd", "walked into somebody at %s%s | %s" % [
		TelemetryLog.tile(_map.world_to_tile(at)), also, _meters()])

## A car sounding its horn at her standing in its lane. Never rate-limited: this is the entry
## that says whether the carriageway is a decision or a place people wander into, and it is the
## last thing written before a `lost` line when it is not.
func _on_near_miss(at: Vector2) -> void:
	if not _day.is_running():
		return
	Telemetry.note("crowd", "a car sounded its horn at her in the road at %s | %s" % [
		TelemetryLog.tile(_map.world_to_tile(at)), _meters()])

# ------------------------------------------------------------------ readouts ---

## Where the excitement is coming from. The crowd is five hundred agents and the events are a
## couple of dozen, so naming them individually is hopeless — but which of the two is holding
## the meter up is the whole question, and it is one subtraction.
##
## `in` is the baby's own incoming rate, and it is here so that the breakdown always adds up.
## The first version printed only the two spatial sources, and a meter climbing on an empty
## street read as `crowd 0.0, events 0.0` — which is true, and hid the fact that the player
## was doing it to themselves with the run button. Whatever `in` exceeds the two named terms
## by came from the player: running, or standing in an alley.
func _meters() -> String:
	var here := _player.global_position
	var from_events := _city.events.total_excitement_at(here) if _city.events else 0.0
	var from_crowd := _city.crowd.total_excitement_at(here) if _city.crowd else 0.0
	return "exc %.0f, in %.1f/s (crowd %.1f, events %.1f), sleep %.0f" % [
		_baby.excitement, _baby.last_incoming, from_crowd, from_events, _baby.sleepiness]

## The closest live event and how far off it is, for the lines where "what was around when
## this happened" is the answer being looked for. Says how far, never "in reach" — the nearest
## event in the city may be six hundred pixels away and part of no story at all.
func _nearest() -> String:
	var closest: EventInstance = null
	var best := INF
	for instance in _city.events.instances():
		if instance.def.city_wide or instance.is_finished:
			continue
		var distance := instance.global_position.distance_to(_player.global_position)
		if distance < best:
			best = distance
			closest = instance
	if not closest:
		return "nothing live"
	return "%s %.0fpx%s" % [closest.def.id, best,
			"" if best <= closest.def.outer_radius else " (out of range)"]
