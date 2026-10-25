class_name CarLook
extends AgentLook
## A car's picture: five authored views of three layers, a body tinted per car, and its bob over its
## wheels. Its caret is the agent's (`CrowdAgent._draw_mark()`), and the redraw key carries the live
## heading as well as the sector, because the anchor and the shadow read it.

## Which authored view each of `EightDirection`'s eight sectors draws — identical to the walker's
## table, since the crowd car shares the same five projections and the same west-mirror convention
## (`docs/evidence/svg-vehicles-2026-09-10/facings.csv`, the `car` rows).
const VIEW_BY_SECTOR: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]

## The five authored views, keyed by name the way the walker's tables are. Three layers per view on
## one canvas and one anchor: the body, tinted per car; the trim, glass and lamps, untinted above it;
## and the wheels, untinted above both, which stay on the ground while the body and trim ride
## `bob()`. Front and back are 30x46, side is 52x30, the diagonals are 52x42.
const BODY_BY_VIEW := {
	"front": "crowd/car_front_body",
	"back": "crowd/car_back_body",
	"side": "crowd/car_side_body",
	"front_diagonal": "crowd/car_front_diagonal_body",
	"back_diagonal": "crowd/car_back_diagonal_body",
}

const TRIM_BY_VIEW := {
	"front": "crowd/car_front_trim",
	"back": "crowd/car_back_trim",
	"side": "crowd/car_side_trim",
	"front_diagonal": "crowd/car_front_diagonal_trim",
	"back_diagonal": "crowd/car_back_diagonal_trim",
}

const WHEELS_BY_VIEW := {
	"front": "crowd/car_front_wheels",
	"back": "crowd/car_back_wheels",
	"side": "crowd/car_side_wheels",
	"front_diagonal": "crowd/car_front_diagonal_wheels",
	"back_diagonal": "crowd/car_back_diagonal_wheels",
}

## The same hold as `WalkerLook.IDLE_SPEED`. `velocity()` is `heading()` — unit length, cardinal in a
## lane or the tangent of an arc mid-turn — times the actual speed, so a car braked to a stop reads
## as a zero heading rather than whatever axis it last pointed along. Well under
## `Tuning.CAR_STRIKE_MIN_SPEED` (20px/s, the floor below which a car cannot strike anybody) and far
## under `Tuning.CAR_SPEED.x` (130px/s), so only a car actually stopped (a light, a gate, a
## give-way) reads as idle.
const IDLE_SPEED := 5.0

## How finely the redraw key reads a car's live heading: each component of the unit vector to the
## nearest hundred-and-twenty-eighth. That is at most 1/256 of error per component, so the anchor it
## decides — `26·|heading.y| + 14·|heading.x|`, whose steepest term is the 26 — is held back by at
## most `(26 + 14) / 256`, about a sixth of a world pixel, and the shadow capsule's axis by about a
## quarter of a degree. Nothing a screen can show at any zoom the game uses is frozen waiting for a
## step.
##
## **A car in a lane costs nothing for it.** `heading()` there is exactly `(±1, 0)` or `(0, ±1)`,
## built from `_direction` rather than integrated from a float, so the key is the same value every
## tick and no redraw is asked for. Only the seconds a car is on an arc pay.
const HEADING_STEPS := 128.0

## The speed a car's bob reaches its full height at: a car in a turn and every car cruising down a
## lane bob fully, and only a car braking below it settles.
const BOB_FULL_SPEED := Tuning.CAR_TURN_SPEED

## How finely the redraw key reads a car's bob: a quarter of a world pixel, half a screen pixel at
## the camera's zoom. A car in a lane changes nothing else about its picture from one frame to the
## next, so this is the step it redraws on while it is moving, and a stopped one never does.
const BOB_STEPS_PER_PX := 4.0

## How much empty canvas each authored view leaves below its drawn content, in px — read off
## `facings.csv`'s alpha bounds (`docs/evidence/svg-vehicles-2026-09-10/facings.csv`, the `car`
## rows): the two diagonals draw to y40 of a 42-tall canvas and front and back to y44 of a 46-tall
## one, while the side view's content touches the bottom row. The anchor adds it back, so what lands
## on the ground line is the drawn corner rather than the empty edge above it.
const CANVAS_BOTTOM_MARGIN := {
	"front": 2.0,
	"back": 2.0,
	"side": 0.0,
	"front_diagonal": 2.0,
	"back_diagonal": 2.0,
}

## How much ground this car has covered, wrapped to one `WheelBob.WAVELENGTH`, which is the phase of
## the rise and fall its body rides over its wheels. Advanced by distance actually covered, once per
## tick, the way a walker's stride is.
var travelled := 0.0

## Adds the ground this tick covered. Called once per tick, never from the drawing, which a halo
## ring calls several times a frame.
func advance(delta: float) -> void:
	travelled = wrapf(travelled + _agent.velocity().length() * delta, 0.0, WheelBob.WAVELENGTH)

## The lift this car's body rides right now, the `bob()` `EntityHalo` asks every owner for:
## `WheelBob.lift()` over the ground it has covered, at full height from `BOB_FULL_SPEED` up and
## fading to nothing as it slows, so a car braking to a light settles onto its wheels rather than
## freezing mid-rise, and a stopped car sits still. `CrowdAgent._draw()` lifts the whole drawing by
## it and `draw_body()` draws the wheels and the shadow back down by it, which is what lets the
## halo's ring ride the same lift and trace the body where it is drawn.
func bob() -> float:
	return WheelBob.lift(travelled, _agent.velocity().length() / BOB_FULL_SPEED)

func carets() -> bool:
	return true

## Advances the sector from the car's velocity alone. There is no cross term the way a walker has
## one: `velocity()` is already the instantaneous line of travel, cardinal in a lane and the tangent
## of the arc mid-turn, so the sector runs through the diagonal for exactly the length of a turn and
## holds at whichever cardinal or diagonal it last pointed while the car is at or under
## `IDLE_SPEED`. A placement leaves the heading exactly on a lane axis, a sector centre 45 degrees
## clear of its neighbours and twice the hold's reach, so the ordinary update replaces the sector
## drawn before with no reset.
func sector() -> int:
	view = EightDirection.update(view, _agent.velocity(), IDLE_SPEED)
	return view

## One `velocity()` serves the bob and the sector, the value `bob()` and `sector()` would each have
## computed.
func picture(moving: Vector2) -> Vector3i:
	var third := roundi(WheelBob.lift(travelled, moving.length() / BOB_FULL_SPEED) * BOB_STEPS_PER_PX)
	view = EightDirection.update(view, moving, IDLE_SPEED)
	return Vector3i(view, 1 if flipped() else 0, third)

## The continuous half of the redraw key: the live heading, quantised. The picture's anchor reads
## the heading rather than the quantised view, because a turn is continuous and the eight views are
## not; keyed on the view alone, a car that has turned would keep the anchor it had at the last
## sector boundary and its picture would sit south of its own body for the rest of its run.
func heading_key() -> Vector2i:
	return Vector2i((_agent.heading() * HEADING_STEPS).round())

## A car's canvas is anchored south of its own position by `body_anchor()`'s reach, so both its
## overhangs are real and unequal: along a vertical lane the larger of its south reach and the
## rest of its canvas, along a horizontal one half its width. Only the cardinal views are asked,
## since a fresh entry never lands mid-turn.
func entry_clearance(vertical: bool) -> float:
	if vertical:
		var body := AtlasLibrary.native_size(region_of(BODY_BY_VIEW["front"]))
		var south_reach := Tuning.CAR_STRIKE_HALF_LENGTH + float(CANVAS_BOTTOM_MARGIN["front"])
		return maxf(south_reach, float(body.y) - south_reach)
	var side := AtlasLibrary.native_size(region_of(BODY_BY_VIEW["side"]))
	return float(side.x) * 0.5

func palette() -> Array:
	return Palette.CAR_PAINT

## Where a car's body texture is anchored for `Sprites.draw_standing`, which always bottom-centres a
## texture at the point it is given. Every one of the five views is a standing elevation whose
## bottom row is the car's **nearest ground contact**, so one registration rule holds for the whole
## family, stated over the heading rather than per view: the drawn content's bottom edge lands on the
## southernmost point of the car's body.
##
## That body is `Tuning.CAR_STRIKE_HALF_LENGTH` (26) by `CAR_STRIKE_HALF_WIDTH` (14), centred on the
## node and rotated onto the heading, so its southern reach is `26·|heading.y| + 14·|heading.x|` —
## 26 pointed along a vertical lane, 14 along a horizontal one, `(26 + 14)/sqrt(2)` ≈ 28.28 at
## exactly 45 degrees, and every value between while a car is on an arc.
##
## **Read off the live heading rather than off the quantised view, because a turn is continuous and
## the eight views are not.** `EightDirection` swaps the texture at a sector boundary; if the anchor
## swapped with it the body would jump the whole difference between two views' ground lines in one
## frame. The same arithmetic keeps the shadow capsule, the debug view's bounding box and the
## picture travelling together for the whole manoeuvre. A standing car's heading is exactly
## cardinal, so this is an exact value there. Because it is read off the heading, the redraw gate
## reads the heading too (`heading_key()`).
static func body_anchor(view_name: String, forward: Vector2) -> Vector2:
	var south_reach := Tuning.CAR_STRIKE_HALF_LENGTH * absf(forward.y) \
			+ Tuning.CAR_STRIKE_HALF_WIDTH * absf(forward.x)
	return Vector2(0.0, south_reach + float(CANVAS_BOTTOM_MARGIN[view_name]))

## Draws the body, trim and wheels onto `canvas`. **Both callers have already lifted the canvas by
## `bob()`**, so what stays on the ground, a car's wheels and its shadow, is drawn back down by the
## same amount here, and the body and the trim are drawn where the lift puts them. That split is the
## whole of the bob: the wheels never move, the paint and the glass above them rise and fall about a
## pixel. Reads `AtlasLibrary.region()`, which is null with an engine error the moment `crowd` is not
## acquired; `Crowd.start_day()` acquires it before an agent exists to draw and `Crowd.clear()`
## releases it once every agent is freed.
func draw_body(canvas: CanvasItem) -> void:
	var frame := sector()
	var flip := flipped()
	var forward := _agent.travel_axis()
	var grounded := Vector2(0.0, -bob())
	_agent.draw_shadow(canvas, grounded, forward)
	var view_name: String = VIEW_BY_SECTOR[frame]
	# The same heading the shadow above and the debug view's bounding box are drawn on, so the
	# picture cannot register against a car that is not there.
	var anchor := body_anchor(view_name, forward)
	var body := AtlasLibrary.region(region_of(BODY_BY_VIEW[view_name]))
	var trim := AtlasLibrary.region(region_of(TRIM_BY_VIEW[view_name]))
	var wheels := AtlasLibrary.region(region_of(WHEELS_BY_VIEW[view_name]))
	Sprites.draw_standing(canvas, body, anchor, Vector2.ZERO, flip, _agent.colour)
	Sprites.draw_standing(canvas, trim, anchor, Vector2.ZERO, flip)
	# Last: each tyre is drawn over the paint.
	Sprites.draw_standing(canvas, wheels, anchor + grounded, Vector2.ZERO, flip)
