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
## Nothing below writes to anything outside itself. It reads positions and meters, emits lines,
## and — for the dusk map — keeps one more list in memory: the trail she actually walked. It is
## never written to the log; `main.gd` hands it to `Telemetry.write_map` at dusk, the same way it
## already hands the day's route tree.
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
## for something slower than the traffic — which can only be the clock.
const IDLE_MIN_TIME := 2.0

## How far she must move before the trail gets another point — one tile, so the picture is one
## point per tile of ground actually covered rather than one per frame, which is what keeps it
## bounded and framerate-independent: a slow machine and a fast one produce the same trail. At
## `Tuning.WALK_SPEED` a 180-second day covers a few hundred tiles, which is the "a few hundred
## points" the picture is sized against.
const TRAIL_SAMPLE_DISTANCE := float(Tuning.TILE_SIZE)

## How long on the road stops being a crossing and starts being a walk down it.
##
## The carriageway is two tiles of a six-tile corridor, so crossing one costs about 0.7s at
## walking pace and a whole junction about two. Anything past this was not on its way to the
## other side — which means **the presence of a `road` entry is itself the finding**, and the
## reader does not have to judge a duration to see it.
const ROAD_LINGER := 2.5

## A packed pavement is a couple of hundred walkers, so walking into one is a thing that can
## happen several times a second. This is the floor on how often a *bump* may say anything; a
## horn is exempt, because a car that had to sound its horn at her is the whole question of
## whether the carriageway is a decision, and must never be dropped for being one of several.
const BUMP_QUIET_TIME := 1.5

## How close to the chalk mark counts as having found it. Generous on purpose — the question
## being answered is "did the player ever go near a contact", not "did they use it".
const CONTACT_SIGHT := 130.0

## How long movement input must be held while she goes nowhere before it counts as *blocked*
## rather than a footstep settling at a kerb. About a second — the same order as
## `TURN_COMMIT_TIME`'s read on "held long enough to be a decision" rather than a stumble.
const BLOCKED_HOLD_TIME := 1.0
## How far she may still drift and count as not moving — a few px of push-back off a wall or a
## body in the crowd, not a stall. Smaller than `NEAR_FLOOR`: this is noise in a stopped body,
## not a distance an event's own radius sets.
const BLOCKED_DRIFT := 6.0
## While the stall persists, how often to say so again rather than staying silent until she lets
## go. Same reasoning as `BUMP_QUIET_TIME`: a thing that keeps being true is one finding
## repeated, not a finding every frame.
const BLOCKED_REPORT_INTERVAL := 3.0

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

## The day's corridor, grown here so that a trace can say whether she was on a path or off it.
##
## Growing one touches no gameplay: `RouteTree.for_day` is a pure function of the city's seed, the
## day and what is shut, so this is the same tree anything else asking for today's would get, and
## `Telemetry.write_map` grows one the same way. The determinism invariant is safe because nothing
## here draws from a `day_rng()` stream.
var _tree: RouteTree
## `on` the corridor, `off` it, or `away` from the streets entirely — in a park, an alley or a
## plaza, which is neither. Held across a junction rather than answered there: a junction belongs to
## no street on purpose (`StreetNetwork`), so asking one gives `away` for a body-width of pavement
## and would put most of a day's corners in the wrong column.
var _path_state := ""
## When the current state began, for the transition line, and when it was last totalled, for the
## share. They are different numbers: one spans a stretch and the other spans a frame.
var _path_since := 0.0
var _path_last := 0.0
var _path_time := {}
## Which branches of the corridor the street she is on carries. See `_watch_the_branch`.
var _path_branches: Array[int] = []

## Where she actually went today, for the dusk map to draw against the corridor above. Each point
## is `(x, y, run_excess_ratio)` — a third component on the one trail rather than a second trail to
## keep in step with it, since running is a property of a stretch of the walk and not a separate
## picture. Sampled by distance (`TRAIL_SAMPLE_DISTANCE`), not by frame; see `_watch_the_trail`.
## Cleared in `start_day()`, same as everything else below it: a rewound day was not walked.
var _trail: Array[Vector3] = []
## The last point actually recorded, so the next one can be measured against it. `_trail` is not
## read back for this because `is_empty()` already has to be checked to write the first point at
## all, and a stray sentinel value would be one more thing to keep in sync with it.
var _trail_last := Vector2.ZERO

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

# Movement input held while she goes nowhere. `-1.0` means no hold is in progress.
var _blocked_since := -1.0
var _blocked_from := Vector2.ZERO
var _blocked_dir := Vector2.ZERO
var _blocked_last_report := -1000.0

# Encounters: instance id -> the distance at which it was last written down. Ids rather than
# references, so this can never keep a freed event alive.
var _near := {}

# Closures seen today, keyed by segment, and when the last one was seen.
var _seen_closures := {}
var _last_closure := ""
var _last_closure_at := -1000.0

# The resistance contact.
var _contact_seen := false

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
	_blocked_since = -1.0
	_blocked_last_report = -1000.0
	_near.clear()
	_chases.clear()
	_seen_closures.clear()
	_last_closure = ""
	_last_closure_at = -1000.0
	_contact_seen = false
	_mark = Stroller.Alert.NONE
	_mark_since = 0.0
	_mark_on_road = 0.0
	_mark_why = ""
	_badges.clear()
	_tree = RouteTree.for_day(_map, GameState.day)
	_path_time = {"on": 0.0, "off": 0.0, "away": 0.0}
	_path_state = ""
	_path_since = 0.0
	_path_last = 0.0
	_path_branches.clear()
	_trail.clear()
	_trail_last = Vector2.ZERO
	Telemetry.note("start", "doorstep %s, facing %s" % [
		TelemetryLog.tile(_map.world_to_tile(_player.global_position)),
		TelemetryLog.compass(_player.facing)])

## The end of the day, with what was around at the moment it ended. Called by `main.gd`
## before the calendar advances, so the outcome is written above the nerve it cost.
func day_finished(result: GameEnums.DayResult) -> void:
	# Above the outcome, because it is part of how the day got there.
	_flush_road(_player.global_position)
	_flush_corridor()
	var name: String = GameEnums.DayResult.keys()[result]
	if result == GameEnums.DayResult.WON:
		Telemetry.note("home", "WON, %.1fs to spare" % _day.time_remaining)
		return
	Telemetry.note("lost", "%s after %.1fs — %s | %s | near: %s" % [
		name.to_lower(), _day.time_total - _day.time_remaining,
		_day.failure_reason, _meters(), _nearest()])
	# The single most useful frame in a run, and the only one that is always worth the file: what
	# the street looked like at the moment the day ended.
	Telemetry.snapshot("lost-%s" % name.to_lower())

# ------------------------------------------------------------------- watching ---

func _process(delta: float) -> void:
	if not _day.is_running():
		return
	Telemetry.set_clock(_day.time_total - _day.time_remaining)
	var here := _player.global_position
	_watch_the_corridor(here)
	_watch_the_ground(here, delta)
	_watch_the_cues(delta)
	_watch_the_meters()
	_watch_running()
	_watch_idling(delta)
	_watch_blocked(here)
	_watch_direction(delta)
	_watch_what_is_near(here)
	_watch_the_chase(here, delta)
	_watch_closures(here)
	_watch_the_contact(here)
	_watch_the_trail(here)

## Whether she is walking the day's corridor.
##
## **It is the instrument for the claim that *going off the paths skips the events and is safer than
## going on them***, which without a measurement can only be argued about. The corridor is where the
## day put its friction and its set pieces, so *how much of the day she spent on it* is the number
## that says whether the placement is reaching her at all.
##
## A transition each way, plus the three totals at dusk, and the totals are the point: a transition
## count says how often she crossed the line and only the durations say which side she lived on.
##
## The third state is not padding. Time in a park, an alley or a plaza is not *off* the corridor in
## the sense the finding means — the corridor is made of streets, and the destination is not one —
## so folding it into `off` would credit every won day with a long safe stretch off the paths.
## **Timed off `Telemetry.clock()` rather than off `delta`**, and that is not a tidiness choice. The
## two are different clocks: the day's is what every other line in the log is stamped with, and the
## frame's keeps running through anything that leaves the day standing still. A rig day the log
## calls 11.9 seconds long has **23.5 seconds** of frames in it — so a share taken over deltas is a
## percentage of a number the reader cannot see, sitting one line above the one they can.
func _watch_the_corridor(here: Vector2) -> void:
	var now := Telemetry.clock()
	var state := _corridor_state(here)
	if state == "":
		_path_since = now
		return
	_watch_the_branch(here, state)
	if _path_state != "" and state != _path_state:
		Telemetry.note("path", "%s the corridor at %s, after %.1fs %s it" % [
			"onto" if state == "on" else ("off" if state == "off" else "away from"),
			TelemetryLog.tile(_map.world_to_tile(here)), now - _path_since, _path_state])
		_path_since = now
	if _path_state != "":
		_path_time[_path_state] += now - _path_last
	_path_state = state
	_path_last = now

## Changing from one branch of the corridor to another, which is leaving a path and entering a new
## one rather than leaving the corridor at all.
##
## **`on` / `off` cannot see this and that is why it is here**: two strands of the corridor both
## answer `on`, so a player who walks the beginning of one route and finishes on another produces a
## trace in which nothing happened. The tree's branch colours are the only thing that can tell them
## apart.
##
## **A switch is a *disjoint* colour set, not a different one.** Walking out of a bundle that
## carries A and B onto a street that carries only B is staying on B — it is the trunk separating,
## which is what a tree does — and calling that a switch would report one at every fork of the day.
## Sharing nothing is what a switch is.
##
## The memory is cleared when she leaves the tree, so this only ever reports a change she made
## *between* two strands rather than one she made by going round.
func _watch_the_branch(here: Vector2, state: String) -> void:
	if state != "on":
		_path_branches.clear()
		return
	var segment := StreetNetwork.segment_containing(_map.world_to_tile(here))
	if not segment:
		return
	var branches := _tree.branches_on(segment.key())
	if branches.is_empty() or branches == _path_branches:
		return
	if not _path_branches.is_empty() and not _shares_a_branch(branches, _path_branches):
		Telemetry.note("path", "switched routes at %s, branch %s -> %s" % [
			TelemetryLog.tile(_map.world_to_tile(here)), str(_path_branches), str(branches)])
	_path_branches = branches

static func _shares_a_branch(a: Array[int], b: Array[int]) -> bool:
	for colour in a:
		if b.has(colour):
			return true
	return false

## `on`, `off`, `away`, or "" for a tile that answers nothing yet — the opening frame, before any
## street has been stood on.
func _corridor_state(here: Vector2) -> String:
	var tile := _map.world_to_tile(here)
	var segment := StreetNetwork.segment_containing(tile)
	if segment:
		return "on" if _tree.is_on_the_tree(segment.key()) else "off"
	# A junction, or the doorstep notch: street ground that belongs to no segment. Hold whatever
	# she was doing rather than inventing a state for four tiles of tarmac.
	if _map.is_street(tile):
		return _path_state
	return "away"

## Crossing into the road, and arriving on or leaving calm ground. Both are transitions, so
## both are one line each rather than a state the reader has to infer from a gap.
##
## The road half is a transition *and* a duration, and it needs both. The step onto the road alone
## gives a player walking a mile down the middle of the carriageway exactly the entries of one
## crossing at every junction — five `cross` lines either way — and leaves "did they walk down the
## road" answerable only by comparing coordinates by hand, which is the sort of inference this
## format exists to make unnecessary.
func _watch_the_ground(here: Vector2, delta: float) -> void:
	var type := _map.tile_type_at_world(here)

	var road := Tile.is_road(type)
	if road:
		if not _was_road:
			_road_since = Telemetry.clock()
			_road_from = _map.world_to_tile(here)
			_carriageway = 0.0
			# **A crossing on the spine is not a zebra and the trace has to say which**, because the
			# two are different bargains: a zebra is a negotiation with a driver who can see you
			# and a signalled crossing is a wait with a known end. A line reading "at a zebra" on
			# the one street where traffic does not give way is a trace that would send the next
			# reader looking for the wrong bug.
			var where := "mid-block"
			if type == GameEnums.TileType.CROSSING:
				where = "at a signalled crossing" if _map.street_kind_at(
						CityMap.is_road_offset(CityMap.corridor_offset(_road_from.x)),
						_road_from) == GameEnums.StreetKind.MAIN else "at a zebra"
			Telemetry.note("cross", "stepped into the road at %s, %s"
					% [TelemetryLog.tile(_road_from), where])
		if type == GameEnums.TileType.ROAD:
			_carriageway += delta
	elif _was_road:
		_flush_road(here)
	_was_road = road

	# **Arriving on and leaving calm ground, and it may not live inside `_flush_road`.** That
	# function returns early unless she has just stepped off a road stretch longer than
	# `ROAD_LINGER`, so from in there a walk from a pavement into a park writes nothing at all and
	# `_was_calm` goes stale with it. `docs/TELEMETRY.md` has `calm` / `left` down as the entry that
	# answers *"same park every day?"*, which it can only do if every arrival counts.
	var calm := _city.is_calm_zone(here)
	if calm != _was_calm:
		var block := _map.block_at(here)
		var what := TelemetryLog.purpose(
				GameState.city_state.purpose_of(_map.block_plans, block))
		Telemetry.note("calm" if calm else "left", "%s %s %s, sleep %.0f" % [
			"entered" if calm else "left", what, TelemetryLog.tile(block),
			_baby.sleepiness])
	_was_calm = calm

## Writes down a stretch on the road, if it lasted longer than crossing one takes.
##
## Called when the player steps off — **and again when the day ends**, because a day that ends
## *while* she is in the carriageway is the most interesting case there is and nothing else would
## write it: a player killed by the traffic she was walking among never leaves the road, so without
## the second call there is no `road` entry at all.
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

## Where the day was spent, in one line, at the end of it.
##
## The transitions above say how often she crossed the line; this says which side she lived on,
## which is the half the corridor question is actually about. The share is taken over the time she
## was **on a street**, because the third state is a destination rather than a choice about routes —
## a won day is a long stretch in a park, and counting that as "off the corridor" would make every
## win look like an evasion.
func _flush_corridor() -> void:
	if _path_state != "":
		_path_time[_path_state] += Telemetry.clock() - _path_last
		_path_last = Telemetry.clock()
	var on: float = _path_time.get("on", 0.0)
	var off: float = _path_time.get("off", 0.0)
	var away: float = _path_time.get("away", 0.0)
	var streets := on + off
	Telemetry.note("path", "%.0f%% of her street time on the corridor (%.1fs on, %.1fs off, "
			% [100.0 * on / maxf(streets, 0.001), on, off]
			+ "%.1fs off the streets)" % away)

## What she was warned about, and for how long.
##
## Every other entry says what the world did; this is the only one that says what the **game told
## her about it**. Without it, *"the offscreen indicators show events far away"* and *"I get the
## exclamation marks after the fact"* are invisible to a trace and can only be found by a person
## looking at a screen — a cue is a claim about a moment, and a moment has to be written down.
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
			# is up on the pavement after a car has gone past is a cue outliving what it warns
			# about, with a number on it.
			Telemetry.note("cue", "the mark over her head: %s for %.1fs (%.1fs of it on the "
					% [Stroller.Alert.keys()[_mark].to_lower(),
					Telemetry.clock() - _mark_since, _mark_on_road]
					+ "road)%s" % _mark_why)
		if level != Stroller.Alert.NONE:
			_mark_since = Telemetry.clock()
			_mark_on_road = 0.0
			_mark_why = " | %s" % _what_raised_the_mark()
			# Only the doubled one, and only as it goes up. `NOW` is the one cue in the game that
			# gives an instruction, and every complaint about it — *"after the fact"*, *"there is no
			# way it can affect me"* — is about **when** it appears, which is a question a line of
			# text cannot settle and a picture can.
			if level == Stroller.Alert.NOW:
				Telemetry.snapshot("mark-now")
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
## Exactly two things can: a `hard_fail` event whose radius covers her, and a car closing on the
## lane she is standing in. **`_nearest()` answers a different question and answers it misleadingly
## here** — it will blame an ice cream van five hundred pixels away for a car's horn, which is the
## *"unattributable"* mark this entry exists to explain, reproduced in the log meant to settle it.
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

## Standing still, and what it bought.
##
## Standing still emits nothing else: no crossing, no turn, no contact, no event coming near. So
## without this entry the strongest move in the game — stopping in the middle of the street and
## waiting until everything is good — shows up in a trace as a **gap between two lines**, and a gap
## is exactly what a reader skips over. A day can be won that way and the log say nothing at all.
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

## Movement input held while she goes nowhere — the trace's own line for a player who is
## *stuck* rather than one who has stopped. `idle` already covers the legitimate stand-still:
## no direction held, and the `is_idle()` check it reads never sees an input at all. This is
## the other case, where the controls are being worked and nothing happens, which without a
## line of its own reads in an unwatched log exactly like a run that never left the doorstep —
## and gives a person pressing into an invisible blocker a trace of having done it.
##
## Read the same way `Stroller._physics_process` reads a direction, straight off `Input`,
## because nothing on the rig exposes "what is currently held" as gameplay state — this is a
## poll, the same one she makes, not a call into anything that decides things.
##
## The anchor resets whenever she actually moves past `BLOCKED_DRIFT`, so the held time is
## always "how long since she last made progress" rather than a clock that starts once at the
## first key and never lets go. A frame the tree is paused on never reaches this at all —
## `_process` returns before it while `_day.is_running()` is false — so a stand at the pause
## screen is not a hold either.
##
## Written on the frame the hold first crosses `BLOCKED_HOLD_TIME`, and at most every
## `BLOCKED_REPORT_INTERVAL` after that while it persists: the same throttle `_on_bumped` uses,
## for the same reason — a wall that is still there a second later is one finding continuing,
## not a new one.
func _watch_blocked(here: Vector2) -> void:
	if _player and _player.is_detained():
		# A capture holds input the same way a wall does — pressed, going nowhere — and without
		# this a `chatting_mother` conversation writes itself down twice, once as `chat` and once
		# as `blocked`, for the same five seconds. The anchor is cleared rather than merely
		# skipped, so a hold that started **during** the capture does not surface the instant it
		# ends and read as having been stuck the whole time it was actually a conversation.
		_blocked_since = -1.0
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO:
		_blocked_since = -1.0
		return
	var now := Telemetry.clock()
	if _blocked_since < 0.0 or here.distance_to(_blocked_from) > BLOCKED_DRIFT:
		_blocked_since = now
		_blocked_from = here
		_blocked_dir = input_dir
		return
	_blocked_dir = input_dir
	var held := now - _blocked_since
	if held < BLOCKED_HOLD_TIME or now - _blocked_last_report < BLOCKED_REPORT_INTERVAL:
		return
	_blocked_last_report = now
	Telemetry.note("blocked", "pressed %s for %.1fs at %s without moving" % [
		TelemetryLog.compass(_blocked_dir), held, TelemetryLog.tile(_map.world_to_tile(here))])

## Today the answer should always be "it made things worse". The day a threat follows her rather
## than sitting where it was placed, that stops being true, and this entry is how running gets
## judged.
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

## The one encounter in the game with a right answer, and whether she played it — the day-3 dog
## somebody dies to without being able to say why.
##
## Every other entry about it is about the **world**: an `ahead` line saying a dog was sited, `near`
## lines saying it got closer, a `lost` line saying she died. The question is about the **exchange**
## — how close it actually got, whether she ran, and which of the two ways a chase can end it ended
## in. Reconstructing that from four distances and a separate `run` span is exactly the inference
## the format exists to make unnecessary, and it is guesswork when the run span outlives the chase.
##
## One line per pursuit, written when it ends, which is the same rule as the `cue` and `idle` spans:
## the duration and the outcome are the finding, and neither exists until it is over.
func _watch_the_chase(here: Vector2, delta: float) -> void:
	var seen := {}
	for instance in _city.events.instances():
		# A pursuer that has not noticed her is not a chase, it is scenery with teeth. The span
		# starts the moment it takes an interest, which for a robbery is the whole finding.
		if not instance.def.pursues or instance.is_finished or instance.is_waiting():
			continue
		var id := instance.get_instance_id()
		seen[id] = true
		if not _chases.has(id):
			_chases[id] = {"since": Telemetry.clock(), "closest": INF, "ran": 0.0,
					"id": instance.def.id, "gave_up": false, "over": false}
			Telemetry.note("chase", "%s came for her at %s | %s" % [instance.def.id,
					TelemetryLog.tile(_map.world_to_tile(instance.global_position)), _meters()])
			# The one encounter in the game with a right answer, and the open question about it is
			# whether a dog that stops short and barks *reads* as "go now". A picture of the frame
			# it starts on is the only thing that can say.
			Telemetry.snapshot("chase-%s" % instance.def.id)
		var chase: Dictionary = _chases[id]
		if chase["over"]:
			continue
		chase["closest"] = minf(float(chase["closest"]),
				instance.global_position.distance_to(here))
		# Its own account of how it ended, read on the frame it breaks off. The entry is kept, and
		# kept closed, until the instance goes: a dog that has lost interest is still in the world
		# for as long as it takes to trot out of shot, and none of that is the chase.
		chase["gave_up"] = bool(chase["gave_up"]) or instance.gave_up
		if _player.run_excess_ratio() > 0.0:
			chase["ran"] = float(chase["ran"]) + delta
		if instance.is_leaving:
			chase["over"] = true
			_write_the_chase(chase)
	for id: int in _chases.keys():
		if seen.has(id):
			continue
		var chase: Dictionary = _chases[id]
		_chases.erase(id)
		if not chase["over"]:
			_write_the_chase(chase)

func _write_the_chase(chase: Dictionary) -> void:
	Telemetry.note("chase", "%s %s after %.1fs — closest %.0fpx, she ran %.1fs of it | %s" % [
		chase["id"], "gave up" if chase["gave_up"] else "stopped chasing",
		Telemetry.clock() - float(chase["since"]), chase["closest"], chase["ran"], _meters()])

## Live pursuits: instance id -> what has happened during it. Ids rather than references, for the
## same reason `_near` uses them — nothing here may keep a freed event alive.
var _chases := {}

## A barrier coming into view. Recorded from where it was seen, because "the player found out
## two junctions later" and "the player could see it from the corner" are different days, and
## which of the two a closure produces is what decides whether it is a decision or an ambush.
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

## Where she went, one point at a time — the answer to *"what did she actually do"* that neither
## the log nor the dawn map can give, since the log only holds a position at the moments something
## happened and the dawn map is drawn before she has taken a step.
##
## Sampled by **distance rather than by frame**, which is what keeps it bounded and
## framerate-independent: a slow frame and a fast one covering the same ground write the same
## trail. The alternative — a point every `_process` call — would make the picture a function of
## how long a machine took to render the day rather than of the day itself, and would grow without
## bound on a rig left running.
##
## The point carries `Stroller.run_excess_ratio()` as its third component rather than a second
## trail, because running is a property of a stretch of the one walk, not a separate walk of its
## own — the same reasoning `_watch_running` uses for the `run` entry, one attribute richer.
func _watch_the_trail(here: Vector2) -> void:
	if not _trail.is_empty() and here.distance_to(_trail_last) < TRAIL_SAMPLE_DISTANCE:
		return
	_trail.append(Vector3(here.x, here.y, _player.run_excess_ratio()))
	_trail_last = here

## The trail, for `main.gd` to hand to `Telemetry.write_map` at dusk alongside the route tree it
## already passes. Empty before a day has been walked — before `start_day()` and on the dawn map,
## which is the correct answer rather than a gap: there is no walk yet, and a picture that invented
## one would be worse than a picture with none.
func trail() -> Array[Vector3]:
	return _trail

# ------------------------------------------------------------------- signals ---

func _on_asleep() -> void:
	Telemetry.note("asleep", "asleep after %.1fs, %s" % [Telemetry.clock(), _meters()])

func _on_baby_state_changed(state: GameEnums.BabyState) -> void:
	if not _day.is_running():
		return
	if state == GameEnums.BabyState.AWAKE:
		Telemetry.note("woke", "woken on the way home, sleep back to %.0f | near: %s"
				% [_baby.sleepiness, _nearest()])

func _on_city_went_quiet() -> void:
	Telemetry.note("quiet", "the sabotage went through; every city-wide source is off")

## Walking into somebody. Reported by `Crowd` rather than watched from here, because the contact is
## a decision the game makes rather than a state to be noticed — but the *rate limiting* stays here,
## with the rest of what keeps the log readable.
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

## Where the excitement is coming from. The crowd is a couple of hundred agents and the events a
## couple of dozen, so naming them individually is hopeless — but which of the two is holding
## the meter up is the whole question, and it is one subtraction.
##
## `in` is the baby's own incoming rate, and it is here so that the breakdown always adds up. The
## two spatial sources alone print `crowd 0.0, events 0.0` for a meter climbing on an empty street
## — true, and it hides the player doing it to herself with the run button. Whatever `in` exceeds
## the two named terms by came from her: running, or standing in an alley.
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
