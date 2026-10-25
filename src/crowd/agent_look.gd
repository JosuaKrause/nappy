class_name AgentLook
extends RefCounted
## How a crowd member looks: the picture it is drawn in, the state that picture keeps, and what the
## redraw gate reads of it. `WalkerLook` and `CarLook` answer for their kind, and `CrowdAgent.kind`
## installs one beside the kind's `LaneStrategy`, so the agent never asks which kind it is to draw.
##
## **A look reads the agent and never writes it.** It holds the state only the picture has (the
## sector last drawn, a walker's stride, a car's travelled ground) and reads the agent's lane state,
## `velocity()` and `heading()` for the rest.
##
## **The sector is `EightDirection`'s own indexing**, clockwise from east, held through the
## boundary by `EightDirection.update()`'s hysteresis. Asking for it twice from the same starting
## sector and the same heading answers the same way, so the drawing and every halo ring atop it may
## ask again; what is not idempotent (a stride, a travelled distance) is advanced by `advance()`,
## once per tick, and never by the drawing.

## The agent this look belongs to.
var _agent: CrowdAgent

## The sector currently drawn, as `EightDirection` indexes it. Starts facing south.
var view := 2

func _init(agent: CrowdAgent) -> void:
	_agent = agent

## A `StringName` for a path in one of the tables below: they hold plain `String`s because a `const`
## `Dictionary` cannot hold a `StringName` literal the type checker keeps, and this is the one
## conversion between that and what `AtlasLibrary.region()` and `native_size()` take.
static func region_of(name: String) -> StringName:
	return StringName(name)

## Starts the look's own state afresh for a placement.
func restart() -> void:
	pass

## Advances what the picture keeps by the ground this tick covered. Called once per tick by the
## mover's strategy, never from the drawing.
func advance(_delta: float) -> void:
	pass

## The sector this look draws in now, advanced from the agent's heading first.
func sector() -> int:
	return view

## Whether the picture is mirrored for the sector drawn.
func flipped() -> bool:
	return EightDirection.is_mirrored(view)

## The quantised half of the redraw key — the sector, the mirror (0 or 1) and a third term, the
## gait frame for a walker and the body's bob for a car — advancing the sector from `moving`, the
## agent's `velocity()` that the caller already holds.
func picture(_moving: Vector2) -> Vector3i:
	return Vector3i(view, 1 if flipped() else 0, 0)

## The continuous half of the redraw key. Zero when nothing the look draws reads the live heading.
func heading_key() -> Vector2i:
	return Vector2i.ZERO

## The lift the body rides right now, in px.
func bob() -> float:
	return 0.0

## Whether this look is marked by a caret when the agent is a danger, which is the redraw gate's
## second reason to redraw.
func carets() -> bool:
	return false

## How far the picture reaches past `_along()` along the agent's axis, which a placement leaves
## inside the map.
func entry_clearance(_vertical: bool) -> float:
	return 0.0

## The palette the agent's coat or paint is rolled from.
func palette() -> Array:
	return []

## Draws the body onto `canvas`. `EntityHalo` calls it once per ring offset to trace the
## silhouette, and the ordinary frame once at the agent itself.
func draw_body(_canvas: CanvasItem) -> void:
	pass
