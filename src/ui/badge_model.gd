class_name BadgeModel
extends RefCounted
## **Which dangers get a screen-edge badge, when it goes up and when it comes down.** The decision
## `DangerEdge` draws, made in one place that is handed plain data and can be stepped in a test with
## no scene, no camera and no frame timing: the live dangers and the warnings that are up
## (`Subject`), where she is, how long the frame was, and a `sees` Callable that answers "is this
## world point in sight, counting this many screen px past the edge as in sight". `DangerEdge`
## builds those from the event source and the camera once a frame and draws what `announcing()` says
## (the first `MOST_AT_ONCE` of `coming`, soonest arrival first).
##
## **The seam for the event manager's warning board.** Whatever collects the live dangers and the
## pending warnings (`EventManager`, or the `WarningBoard` split out of it) hands this model
## `Subject`s and a view and reads `coming` / `announcing()` back; nothing here knows `EventInstance`,
## `PendingWarning`, `VisibleView` or a node.
##
## The thresholds are the badge's: see each constant. The reasons for the rules (its own approach
## rather than the gap's, a margin on the screen edge for raising, and a badge kept until its danger is in sight) are written beside
## them below.

## How fast something has to be closing before it is worth an arrow, in px/s — **its own
## approach, with the player held still.** Anything slower she can simply walk away from, which
## is the same line `required_telegraph_time()` draws.
##
## **Not the rate the *gap* is shrinking.** That is her speed plus its speed, and she walks at 92
## against a threshold of 20 — so walking towards anything lethal raises its badge whether or not
## the thing is coming, and *"they show events far away"*, *"they disappear when you walk towards
## them"* and *"they flicker"* all fall out of that one line. Her own velocity is hers to control
## and does not need announcing at the edge of the screen.
const CLOSING_SPEED := 20.0
## The range cap, stated as time rather than as pixels: something is announced once it would
## reach her within this many seconds at its current approach.
##
## A distance would have to be wrong for something — a badge at 900px is scenery with a number
## on it for a dog, and is exactly what the cue exists for when it is a fire engine. Stated as a
## window it scales itself: at `fire_truck`'s 190px/s this is most of the stream radius, at a
## cyclist's pace about half of it, and a 60px/s mover has to be within 300px. It is the same
## quantity the fairness contract is written in — how long she has to get out of the way.
const LEAD_TIME := 5.0
## How fast the measured approach follows the raw frame-to-frame one, per second. A single
## frame's difference is mostly noise at these distances; this is the same smoothing the badge
## would otherwise need three of.
const SMOOTHING := 6.0
## How far out of sight something has to be before it is raised a badge, in screen px. A thing
## sitting on the boundary would otherwise trade places with its own badge every frame. **It only
## decides whether a badge goes up.** Once up, a badge stays up until its danger is in sight (the
## view proper, no margin) or leaves the world; the margin plays no part in keeping it. A charger's
## margin is 0 from the frame it runs, and a warned arrival's until it has been seen once, so each is
## raised from outside the view proper.
const SCREEN_MARGIN := 130.0
## At most this many at once. Three arrows is a warning; eight is wallpaper, and the day the
## edge of the screen becomes wallpaper is the day it stops being read.
const MOST_AT_ONCE := 3

## One thing the badge may have to say something about, as plain data. The event source's adapter
## fills the fields it has; a warning with nothing in the world yet is a `Subject` with `pending`
## set, a `place` and `left`.
class Subject extends RefCounted:
	## Identity across frames (the instance id); unused for a pending warning.
	var key := 0
	var position := Vector2.ZERO
	## The row's own facts the rule reads.
	var speed := 0.0
	var outer_radius := 0.0
	## Its speed while pursuing, where the row pursues.
	var chase_speed := 0.0
	var telegraphs := true
	## Whether there is a silhouette to put in the badge.
	var has_icon := true
	## Sited ahead of her across her line (`EventDef.SpawnMode.AHEAD_OF_PLAYER`).
	var ahead_of_player := false
	var pursues := false
	var hard_fail := false
	var mobile := false
	## Over and done with: ignored.
	var finished := false
	## It was created under a warning that already ran (`EventInstance.came_under_a_warning`).
	var warned := false
	## It is charging this frame (`EventInstance.has_charged()`).
	var charging := false
	## Any of it is in sight (its point or what it draws).
	var shown := false
	var logged_name := ""
	## Handed back untouched on a badge, for the drawing (the row).
	var payload: Variant = null
	## A warning not yet a thing: the place it will come from and the seconds its warning has left.
	var pending := false
	var left := 0.0

	## Whether something with these facts deserves an arrow at all: lethal always, and otherwise
	## only what she cannot outwalk (an event slower than a walk is one she can turn round and leave).
	## A thing that does not telegraph is outside the badge; one with no silhouette has nothing to
	## say; an `AHEAD_OF_PLAYER` crossing is sited close and gone in seconds and is its own moment,
	## except a pursuer, which is warned of first and then placed just out of sight to close in.
	## `TOWARD_PLAYER` falls through on purpose: a road, not an ambush.
	func worth_an_arrow(walk_speed: float) -> bool:
		if not telegraphs or not has_icon:
			return false
		if ahead_of_player and not pursues:
			return false
		if hard_fail:
			return true
		return mobile and speed > walk_speed

## What to put on the edge this frame, soonest arrival first:
## `[time_to_reach, distance, payload, world position, approach, logged name]`.
var coming: Array = []
## Per live subject: where it was last frame (`was`), its smoothed approach speed (`approach`),
## whether its badge is up (`up`), whether it has been in sight (`seen`), whether its charge has been
## met (`charged`), and the generation it was last touched on (`generation`). Keyed by `Subject.key` and mutated in
## place, so a subject that stops being handed over drops out the frame after.
var watch := {}
var _generation := 0

## How fast something at `was`, now at `now`, is closing on a player standing at `player`.
## Passing the same point for both distances is what "with the player held still" *means*.
static func approach_speed(was: Vector2, now: Vector2, player: Vector2, delta: float) -> float:
	if delta <= 0.0:
		return 0.0
	return (was.distance_to(player) - now.distance_to(player)) / delta

## Whether something closing at `approach` px/s with `gap` px of clear ground left is worth announcing.
static func announces(approach: float, gap: float) -> bool:
	return approach >= CLOSING_SPEED and gap <= approach * LEAD_TIME

## One frame. `here` is where she stands; `sees(point, margin_px)` is whether a world point is in
## sight with `margin_px` screen px past the edge counted as in sight; `walk_speed` is her walk
## (`Tuning.WALK_SPEED`). Replaces `coming`.
##
## **Two paths, and only the first is the design.** `_announce_the_warnings()` is the end state: a
## warning is put up before its danger is placed, the badge points at where it will come from, and
## nothing is measured. `_measure_dangers_in_the_world()` (with `watch`, `SMOOTHING`, `LEAD_TIME`,
## `CLOSING_SPEED`, `SCREEN_MARGIN`, `announces()`, `approach_speed()` and the `Subject` fields only it
## reads) badges dangers that are already in the world; the stairwell's masked man and the army truck
## still need it, and it goes, as a deletion, in the follow-up that places those two after their badge.
func step(delta: float, here: Vector2, subjects: Array, sees: Callable, walk_speed: float) -> void:
	coming.clear()
	if delta <= 0.0:
		return
	_measure_dangers_in_the_world(delta, here, subjects, sees, walk_speed)
	_announce_the_warnings(here, subjects, walk_speed)
	coming.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])

## A warning with nothing in the world yet is announced for the whole of its warning, on screen or
## off: it points at where the thing will come from, and there is nothing there to see yet. Sorted
## by when the thing will exist, which is the soonest it can arrive.
func _announce_the_warnings(here: Vector2, subjects: Array, walk_speed: float) -> void:
	for subject: Subject in subjects:
		if not subject.pending or not subject.worth_an_arrow(walk_speed):
			continue
		coming.append([maxf(subject.left, 0.0), subject.position.distance_to(here), subject.payload,
				subject.position, subject.speed, subject.logged_name])

## The in-the-world path: see `step()`.
func _measure_dangers_in_the_world(delta: float, here: Vector2, subjects: Array, sees: Callable,
		walk_speed: float) -> void:
	_generation += 1
	for subject: Subject in subjects:
		if not subject.pending and not subject.finished:
			_measure(subject, delta, here, sees, walk_speed)
	# Only the subjects alive this frame carry state forward; a key not touched above still reads an
	# earlier generation and is erased here, which also keeps a freshly streamed thing from
	# flashing an arrow on the frame it appears, and ends the badge of a danger that left the world.
	for key in watch.keys():
		if watch[key]["generation"] != _generation:
			watch.erase(key)

func _measure(subject: Subject, delta: float, here: Vector2, sees: Callable,
		walk_speed: float) -> void:
	var at := subject.position
	var state: Dictionary
	if watch.has(subject.key):
		state = watch[subject.key]
	else:
		# **A thing that arrives under its own warning keeps the badge it already had.** It is
		# created just out of sight, inside `SCREEN_MARGIN`, where a fresh thing would not raise
		# one; and it starts with no measured approach. Without this its badge would flicker off
		# for the frames before it comes into view. So it starts closing at its own speed (a
		# pursuer's at its pursuing speed), already raised, and the margin waits until it has been
		# seen once.
		var own_speed := subject.chase_speed if subject.pursues else subject.speed
		state = {"was": at, "approach": own_speed if subject.warned else 0.0,
				"up": subject.warned, "seen": not subject.warned}
		watch[subject.key] = state
	# The event's own approach: how much closer *it* got to where she is standing now. Both
	# distances are measured to the same point, so her own walking cancels out of it.
	var raw := approach_speed(state["was"], at, here, delta)
	var approach: float = lerpf(state["approach"], raw, clampf(delta * SMOOTHING, 0.0, 1.0))
	# **A charge is met at its true approach on its first moving frame** *(inbox #788 in minty-lemur,
	# the player, of the stairwell's masked man, whose only heads-up is this badge once he runs:
	# "Let's show that at least")*. The smoothing is there for a thing hovering near the threshold;
	# a charger setting off is a step from standing to its full speed, and smoothed it would reach
	# the badge's line about a tenth of a second after he ran.
	if not state.get("charged", false) and raw > 0.0 and subject.charging:
		approach = maxf(approach, raw)
		state["charged"] = true
		# **A charger is raised from outside the view proper, wherever it stands.** Fired once, on
		# the first frame a pursuer's charge is on and it is moving. Held to the margin band, a
		# charger that set off from inside the band was never raised (the masked man's start on the
		# stairs). Its margin is 0 until it has been in sight again.
		state["seen"] = false
	var distance := at.distance_to(here)
	# The gap to its *field*, not to its centre: an event reaches her when its outer radius
	# does, and for a fire engine that is a third of a block earlier.
	var gap := maxf(0.0, distance - subject.outer_radius)
	# **A badge, once up, stays up until the danger is in sight or gone** *(the player: "a badge
	# shouldn't disappear before the entity is visible")*: no timer ends it and neither does turning
	# away, slowing, or the approach test lapsing. It is raised only for what announces and is outside
	# the margin band (or the view proper, for a charger and a warned arrival). Coming into sight ends
	# it: that is the badge's job done by the thing itself. A danger that leaves the world is no longer
	# handed over, which prunes it below.
	if subject.shown:
		state["seen"] = true
		state["up"] = false
	elif subject.worth_an_arrow(walk_speed) and announces(approach, gap) \
			and not sees.call(at, SCREEN_MARGIN if state["seen"] else 0.0):
		state["up"] = true
	state["was"] = at
	state["approach"] = approach
	state["generation"] = _generation
	if state["up"]:
		# Sorted by *when it arrives* rather than by how near it is, because that is what
		# `MOST_AT_ONCE` is choosing between: the one worth keeping is the one that gets here first,
		# which a slow thing standing closer is not.
		coming.append([gap / maxf(approach, 1.0), distance, subject.payload, at, approach,
				subject.logged_name])

## What is on the edge right now: `{id, distance, approach}` per badge, nearest arrival first.
func announcing() -> Array[Dictionary]:
	var badges: Array[Dictionary] = []
	for i in mini(MOST_AT_ONCE, coming.size()):
		badges.append({
			"id": str(coming[i][5]),
			"distance": float(coming[i][1]),
			"approach": float(coming[i][4]),
		})
	return badges
