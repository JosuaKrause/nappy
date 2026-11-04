class_name Offscreen
extends RefCounted
## **How far out of her view something sent at her starts**: the distance to the edge of the visible box along a
## heading (`boundary()`), and that plus the notice a row owes (`lead()`), each with the least it can be for any
## heading (`min_boundary()`, `min_lead()`) for the checks that have no heading to ask about. Static and
## stateless, pure functions of their arguments and the view's size and the default notice in `Tuning`.

## Distance from her to the edge of the view along `heading` — a ray to the edge of the
## `Tuning.VIEW_HALF_EXTENT` box, the same arithmetic `DangerEdge._distance_to_edge` already draws the
## screen-edge badge with, from her rather than from the camera. A thing created at once from off
## screen — a patrol down the road — is at least this far out, so it starts genuinely off screen
## whichever way she is walking rather than only on the one axis a flat number happened to cover. A
## thing warned of first is placed by what she can see instead (`VisibleView.clear_of_sight()`),
## which is the camera's view and the controls' corners.
static func boundary(heading: Vector2) -> float:
	var reach := INF
	if not is_zero_approx(heading.x):
		reach = minf(reach, Tuning.VIEW_HALF_EXTENT.x / absf(heading.x))
	if not is_zero_approx(heading.y):
		reach = minf(reach, Tuning.VIEW_HALF_EXTENT.y / absf(heading.y))
	return reach

## The least `boundary()` can be for any heading — the vertical axis, since 180 is
## smaller than the 320 the horizontal one gives — and the floor under where anything warned of
## first is placed (`SpawnSiting.least_distance()`), which a covered corner of the joystick scheme
## would otherwise bring nearer on a shallow way down to one side. What a fairness check needs when it
## has no particular heading to ask about: `EventDef.validate()` checks a row's own geometry against the
## worst case the director could ever site it in, not the case a given walk happens to produce.
static func min_boundary() -> float:
	return Tuning.VIEW_HALF_EXTENT.y

## How far out along `heading` something that travels toward her and is created at once starts — a
## patrol the director sends down the road: outside the view (`boundary()`) and `notice`
## seconds further still, at `closing_speed`. Something warned of before it exists is placed just
## out of sight instead (`SpawnSiting.just_out_of_sight()`).
##
## **`closing_speed` is the row's own speed plus `WALK_SPEED`, not the row's speed alone** — she is
## usually walking into it, so the gap between the siting and the boundary closes at both speeds
## together. At the default 200ms of `notice`, that is 51px of margin for `cyclist` (165px/s) and
## 44px for `charging_dog` (130px/s pursuing) — neither number is authored anywhere else, this
## function is where a row's own notice turns into pixels, per heading.
static func lead(heading: Vector2, closing_speed: float, notice: float = Tuning.OFFSCREEN_NOTICE) -> float:
	return boundary(heading) + closing_speed * notice

## The least `lead()` can be for a row closing at `closing_speed` and giving `notice`
## seconds of it, whichever way she is heading — `min_boundary()` plus the same margin.
## What `EventDef.validate()` needs for the same reason `min_boundary()` does: a per-row
## floor that does not depend on a heading nothing at validation time has chosen yet.
static func min_lead(closing_speed: float, notice: float = Tuning.OFFSCREEN_NOTICE) -> float:
	return min_boundary() + closing_speed * notice
