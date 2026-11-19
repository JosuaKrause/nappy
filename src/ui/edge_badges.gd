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

## What is on the edge right now, soonest arrival first, one entry per badge, each carrying at
## least `id` (the name the log calls the thing by, `EventInstance.logged_name()`), `distance`
## (px from her) and `approach` (how fast it closes under its own steam, px/s).
func announcing() -> Array[Dictionary]:
	return []
