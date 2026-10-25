class_name WalkerLook
extends AgentLook
## A walker's picture: five authored views, each in two gait frames, a coat tinted per walker and
## the trim untinted above it.

## The five views, keyed by name rather than by sector — `VIEW_BY_SECTOR` does the sector-to-view
## lookup, so drawing never repeats an eight-way if-chain. All five share one 18x38 canvas and one
## (9, 38) feet anchor (`docs/evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md`); the body is tinted
## per walker and the trim is drawn untinted above it. Paths rather than `preload()`d textures: a
## picture baked into `assets/atlases/baked/crowd.png` is not also resident as its own resource, and
## `AgentLook.region_of()` turns one into the name `AtlasLibrary.region()` takes.
const BODY_BY_VIEW := {
	"front": "crowd/walker_front_body",
	"back": "crowd/walker_back_body",
	"side": "crowd/walker_side_body",
	"front_diagonal": "crowd/walker_front_diagonal_body",
	"back_diagonal": "crowd/walker_back_diagonal_body",
}

const TRIM_BY_VIEW := {
	"front": "crowd/walker_front_trim",
	"back": "crowd/walker_back_trim",
	"side": "crowd/walker_side_trim",
	"front_diagonal": "crowd/walker_front_diagonal_trim",
	"back_diagonal": "crowd/walker_back_diagonal_trim",
}

## The second gait frame, feet passing — the mother's own `_b` pose for each view. Only the legs and
## shoes differ from the tables above; the coat stays put in the three-quarter views and lifts a
## pixel in front, back and side. Separate `_b`-suffixed files beside the unsuffixed frame-a ones.
const BODY_BY_VIEW_B := {
	"front": "crowd/walker_front_body_b",
	"back": "crowd/walker_back_body_b",
	"side": "crowd/walker_side_body_b",
	"front_diagonal": "crowd/walker_front_diagonal_body_b",
	"back_diagonal": "crowd/walker_back_diagonal_body_b",
}

const TRIM_BY_VIEW_B := {
	"front": "crowd/walker_front_trim_b",
	"back": "crowd/walker_back_trim_b",
	"side": "crowd/walker_side_trim_b",
	"front_diagonal": "crowd/walker_front_diagonal_trim_b",
	"back_diagonal": "crowd/walker_back_diagonal_trim_b",
}

## Which authored view each of `EightDirection`'s eight sectors draws — N back, NE/NW
## back_diagonal, E/W side, SE/SW front_diagonal, S front, the same N/NE/E/SE/S coverage the
## mother/pram family uses. Sectors 3 (SW), 4 (W) and 5 (NW) mirror their partner
## (`EightDirection.is_mirrored()`).
const VIEW_BY_SECTOR: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]

## Radians of gait per pixel walked. `Stroller._physics_process()` advances `_walk_phase` at the
## identical rate, so the crowd and the player share one stride length per pixel covered, and
## `WalkerStrategy.stride_length()` reads it back to price a stride as a distance.
const GAIT_RATE := 0.09

## Below this speed a walker's heading is too close to zero to mean a facing, so it holds whatever
## it was last drawn as rather than chattering on the residual few px/s `WalkerStrategy._yield_factor()`
## and float noise leave in it. Well under `Tuning.PEDESTRIAN_SPEED`'s floor (46px/s), so only an
## actually-stopped walker (a give-way, a queue, a halt) reads as idle.
const IDLE_SPEED := 5.0

## The walker's stride, in the units `Stroller._walk_phase` uses: wrapped 0..TAU, advanced by distance
## actually covered rather than by time, so it stays in step at any speed the way the mother's own does.
var gait_phase := 0.0

## A placement starts the stride at rest, which keeps it deterministic for a given seed, the same
## reason `Stroller.reset_at()` zeroes `_walk_phase` for a new day.
func restart() -> void:
	gait_phase = 0.0

## Adds the ground this tick covered, `velocity()` being the along-lane speed the crowd already
## stops to zero at a give-way, a queue or a light. Not idempotent, so it runs once per tick rather
## than from the drawing, which a halo ring calls several times a frame.
func advance(delta: float) -> void:
	gait_phase = wrapf(gait_phase + _agent.velocity().length() * delta * GAIT_RATE, 0.0, TAU)

## Which of the two gait frames to draw: frame 1 (feet passing) for half of every stride while
## moving, frame 0 (the rest pose) otherwise — `Stroller._draw_mother()`'s own `stepping` test,
## read off `IDLE_SPEED`.
func gait_frame() -> int:
	return gait_frame_at(_agent.velocity())

## `gait_frame()` for a `velocity()` the caller already holds.
func gait_frame_at(along: Vector2) -> int:
	if along.length() <= IDLE_SPEED:
		return 0
	return 1 if sin(gait_phase * 2.0) > 0.0 else 0

## The walker's heading this frame: its along-lane velocity plus whatever its steering is doing
## across the lane right now, which swings a walker rounding a corner, or nudged aside by
## `step_aside()`, onto a diagonal view a moment before its lane assignment turns. The cross term is
## the steering target (`_lane_centre + _detour`) minus where the walker is, signed and capped at
## `LaneMover.STEER_SPEED`, the rate the mover steers at while it has not arrived. Zero once it has
## arrived with no detour running, which a stopped walker always has, since
## `WalkerStrategy._yield_factor()` zeroes the along term then.
func heading_now() -> Vector2:
	return heading_at(_agent.velocity())

## `heading_now()` for a `velocity()` the caller already holds.
func heading_at(along: Vector2) -> Vector2:
	var cross_gap := _agent._lane_centre + _agent._detour - _agent._cross()
	if is_zero_approx(cross_gap):
		return along
	var cross_speed := signf(cross_gap) * LaneMover.STEER_SPEED
	return along + (Vector2(cross_speed, 0.0) if _agent._vertical else Vector2(0.0, cross_speed))

## Advances the sector from the heading, held through the boundary and the idle speed. A placement
## leaves no cross-lane steering running, so the heading is exactly along the new lane axis, a
## sector centre 45 degrees clear of its neighbours and twice the hold's reach, and the ordinary
## test replaces the sector drawn before with no reset.
func sector() -> int:
	view = EightDirection.update(view, heading_now(), IDLE_SPEED)
	return view

## One `velocity()` serves the gait and the sector: the value `gait_frame()` and `heading_now()`
## would each have computed, since nothing between them moves it.
func picture(moving: Vector2) -> Vector3i:
	var third := gait_frame_at(moving)
	view = EightDirection.update(view, heading_at(moving), IDLE_SPEED)
	return Vector3i(view, 1 if flipped() else 0, third)

## A walker's canvas is anchored bottom-centre on its position, so its picture rises entirely north
## of it: it overhangs a north edge by its full canvas height and a south edge by nothing, and half
## its width either side. The larger of the two is kept for both edges of the axis, so one number
## clears whichever edge a placement is beside. `native_size()` answers from the region table with
## nothing acquired, which matters because a placement roll asks before `Crowd.start_day()` acquires.
func entry_clearance(vertical: bool) -> float:
	var walker := AtlasLibrary.native_size(region_of(BODY_BY_VIEW["front"]))
	return float(walker.y) if vertical else float(walker.x) * 0.5

func palette() -> Array:
	return Palette.COATS

func draw_body(canvas: CanvasItem) -> void:
	var frame := sector()
	var flip := flipped()
	_agent.draw_shadow(canvas, Vector2.ZERO, Vector2.RIGHT)
	var view_name: String = VIEW_BY_SECTOR[frame]
	# One lookup decides both layers, so the coat and the legs can never show two different
	# instants of the same stride.
	var stepping := gait_frame() == 1
	var body_paths: Dictionary = BODY_BY_VIEW_B if stepping else BODY_BY_VIEW
	var trim_paths: Dictionary = TRIM_BY_VIEW_B if stepping else TRIM_BY_VIEW
	var body := AtlasLibrary.region(region_of(body_paths[view_name]))
	var trim := AtlasLibrary.region(region_of(trim_paths[view_name]))
	# The body is tinted per agent; the trim above it draws at `Sprites.draw_standing()`'s default
	# `Color.WHITE`. Two separate baked regions, so tinting one never touches the other's pixels.
	Sprites.draw_standing(canvas, body, Vector2.ZERO, Vector2.ZERO, flip, _agent.colour)
	Sprites.draw_standing(canvas, trim, Vector2.ZERO, Vector2.ZERO, flip)
