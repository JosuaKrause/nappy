class_name EdgeBadges
extends RefCounted
## **The screen-edge badges up this frame, as a reader that may not name the screen reads them.**
## The run log's observer (`TelemetryObserver`) writes when each badge goes up and comes down, and
## it is a sibling of the view the badges are drawn in, so it is handed this, never `DangerEdge`:
## `main` asks the edge for its badges (`DangerEdge.badges()`) and hands them to the run log's
## session (`RunSession.watch()`), which hands them to the observer.
##
## This base has none up, which is what a boot with no edge answers. `BadgeModel`, the decision the
## edge steps once a frame and draws, is the one that has badges; held as this, its holder can read
## what it announces and cannot step or clear it.

## **One badge as the run log reads it**: what the thing is called, how far it is and how fast it
## closes. Built with its three values, which it answers and nobody sets.
class Badge extends RefCounted:
	var _logged_name := ""
	var _distance := 0.0
	var _approach := 0.0

	func _init(logged_name_: String, distance_: float, approach_: float) -> void:
		_logged_name = logged_name_
		_distance = distance_
		_approach = approach_

	## The name the log calls the thing by (`EventInstance.logged_name()`).
	func logged_name() -> String:
		return _logged_name

	## How far the thing is from her, in px.
	func distance() -> float:
		return _distance

	## How fast it closes under its own steam, in px/s.
	func approach() -> float:
		return _approach

## What is on the edge right now, soonest arrival first, one entry per badge.
func announcing() -> Array[Badge]:
	return []
