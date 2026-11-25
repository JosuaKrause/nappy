class_name BadgeModel
extends EdgeBadges
## **Which dangers get a screen-edge badge, when it goes up and when it comes down.** The decision
## `DangerEdge` draws, made in one place that is handed plain data and can be stepped in a test with
## no scene, no camera and no frame timing: the warnings that are up and the live dangers
## (`Subject`) and where she is. `DangerEdge` builds those from the event source and the camera once
## a frame and draws what `drawn()` says (every badge up, soonest arrival first).
##
## **One path: a warning put up before its danger is placed** *(minty-dolphin #852: "Don't let
## legacy implementations prevent you from establishing a clean design")*. A warning with nothing in
## the world yet is announced for the whole of its warning, pointing at where the thing will come
## from (`PendingWarning`); the thing it warns of is then created where it pointed
## (`EventInstance.was_warned_of()`), and **keeps the badge until she can see it** *("Anyway a badge
## shouldn't disappear before the entity is visible")*, or until it is over or gone. Nothing in the
## world is measured: a danger that was not warned of first carries no badge, and one seen once
## carries none again.
##
## **The seam for the event manager's warning board.** Whatever collects the pending warnings and
## the live dangers (`EventManager`, through its `WarningBoard`) hands this model `Subject`s and reads
## `announcing()` / `drawn()` back; nothing here knows `EventInstance`, `PendingWarning`,
## `VisibleView` or a node.

## One thing the badge may have to say something about, as plain data. The event source's adapter
## fills the fields it has; a warning with nothing in the world yet is a `Subject` with `pending`
## set, a `place` and `left`.
class Subject extends RefCounted:
	## Identity across frames (the instance id); unused for a pending warning.
	var key := 0
	var position := Vector2.ZERO
	## Whether it deserves an arrow at all: its row announces its coming
	## (`EventDef.announces_its_coming()`, asked at her walk). That does not change while it is
	## handed over, so the adapter asks once.
	var announces := true
	## How fast it comes at her under its own steam (`EventDef.approach_speed()`): what its arrival is
	## reckoned at, for the order the badges are drawn in.
	var approach_speed := 0.0
	## How far from its centre its field reaches her (`EventDef.heard_within()`): the badge's gap is
	## measured to there.
	var heard_within := 0.0
	## Over and done with: ignored.
	var finished := false
	## It was created under a warning that already ran (`EventInstance.was_warned_of()`).
	var warned := false
	## Any of it is in sight (its point or what it draws).
	var shown := false
	var logged_name := ""
	## Handed back untouched on a badge, for the drawing; null where a suite sets none.
	var payload: EventDef = null
	## A warning not yet a thing: the place it will come from and the seconds its warning has left.
	var pending := false
	var left := 0.0


## One badge as the edge draws it: what the run log reads (`EdgeBadges.Badge`) and what only the
## model's sort and the drawing read, how long until it arrives, its row and where it points.
class Drawn extends EdgeBadges.Badge:
	var _arrives_in := 0.0
	var _row: EventDef = null
	var _points_at := Vector2.ZERO

	func _init(logged_name_: String, distance_: float, approach_: float, arrives_in_: float,
			row_: EventDef, points_at_: Vector2) -> void:
		super(logged_name_, distance_, approach_)
		_arrives_in = arrives_in_
		_row = row_
		_points_at = points_at_

	## Seconds until it reaches her at its approach; the order the badges are sorted in.
	func arrives_in() -> float:
		return _arrives_in

	## The row it announces, whose picture and colour the edge draws.
	func row() -> EventDef:
		return _row

	## The world point it points at.
	func points_at() -> Vector2:
		return _points_at

## What to put on the edge this frame, soonest arrival first.
var _coming: Array[Drawn] = []
## The live things created under a warning that she has seen, by `Subject.key`: their badge has done
## its job and does not come back. A key no longer handed over is dropped.
var _seen := {}

## One frame, her standing at `here`: takes down last frame's badges and puts up this frame's.
func step(here: Vector2, subjects: Array) -> void:
	_coming.clear()
	var handed := {}
	for subject: Subject in subjects:
		if not subject.announces:
			continue
		if subject.pending:
			_announce_the_warning(subject, here)
		elif subject.warned and not subject.finished:
			handed[subject.key] = true
			_keep_the_warning(subject, here)
	for key: int in _seen.keys():
		if not handed.has(key):
			_seen.erase(key)
	_coming.sort_custom(func(a: Drawn, b: Drawn) -> bool: return a.arrives_in() < b.arrives_in())

## A warning with nothing in the world yet is announced for the whole of its warning, on screen or
## off: it points at where the thing will come from, and there is nothing there to see yet. Sorted
## by when the thing will exist, which is the soonest it can arrive.
func _announce_the_warning(subject: Subject, here: Vector2) -> void:
	_coming.append(Drawn.new(subject.logged_name, subject.position.distance_to(here),
			subject.approach_speed, maxf(subject.left, 0.0), subject.payload, subject.position))

## **The thing a warning created keeps the warning's badge until she can see it**: created just out
## of sight, it points at where it is, until any of it comes into sight, which is the badge's job done
## by the thing itself; then it carries none again. Sorted by when it arrives at its own approach,
## measured to its field's edge.
func _keep_the_warning(subject: Subject, here: Vector2) -> void:
	if subject.shown:
		_seen[subject.key] = true
	if _seen.has(subject.key):
		return
	var distance := subject.position.distance_to(here)
	var gap := maxf(0.0, distance - subject.heard_within)
	_coming.append(Drawn.new(subject.logged_name, distance, subject.approach_speed,
			gap / maxf(subject.approach_speed, 1.0), subject.payload, subject.position))

## Whether any badge is up now.
func has_badges() -> bool:
	return not _coming.is_empty()

## Takes every badge down, ahead of the frame's new measurement.
func clear_badges() -> void:
	_coming.clear()

## What is on the edge right now, nearest arrival first, one entry per badge: the same objects
## `drawn()` answers, read as the run log reads them.
## Overrides EdgeBadges.announcing.
func announcing() -> Array[EdgeBadges.Badge]:
	var badges: Array[EdgeBadges.Badge] = []
	badges.assign(_coming)
	return badges

## What the edge draws right now, nearest arrival first: every badge up, with its row and where it
## points.
func drawn() -> Array[Drawn]:
	return _coming
