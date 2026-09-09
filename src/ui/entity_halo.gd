class_name EntityHalo
extends Node2D
## The rim of redrawn offsets that turns a source's own silhouette into "this is charging you
## right now, and here is how much" — shared by `EventInstance` and `CrowdAgent` rather than
## living on either. *(2026-09-07, the player: "at the very least if something has a caret it
## needs a halo as well".)* A honking car and a bumped walker already draw a caret the same way an
## event does, so the class that draws the rim cannot belong to one of them without the other
## going without.
##
## Built by its owner with two callables: `draw_body(canvas: CanvasItem)` re-runs the owner's own
## body-drawing at whatever offset the ring asks for, and `bob() -> float` reads the owner's
## current vertical bob, so a walking or pacing entity's rim rides the same lift the body itself
## does rather than sliding off it. `set_glow()` is the only thing an owner calls afterwards, once
## a frame, with the alpha and colour `ExcitementHalo` computed for it — everything else here is
## the drawing.
##
## **Only the ordinary SVG body is traced.** `CrowdAgent`'s illustrated `walker_visual`
## presentation draws itself as a separate child node with its own `_draw()`, so a `draw_body`
## callback bound to `_draw_body()` never touches it and never should — tracing an illustrated
## presentation is a design question nobody has asked yet.
##
## **`show_behind_parent`** places the rim behind the entity, the crowd and the player the same
## way each entity's own shadow is placed, so it stays a hint rather than a wall. **The shared
## `ShaderMaterial`** is one resource for every rim in the game rather than a copy per instance,
## because the shader itself carries no state of its own to duplicate — see
## `assets/shaders/excitement_halo.gdshader` for why the per-instance colour and strength travel
## through `set_instance_shader_parameter()` rather than through the material or `modulate`: a
## fragment function that writes `COLOR` is not re-multiplied by a node's own `modulate`
## afterward, so `instance uniform` is the only channel that reaches one value per rim on one
## shared material.

## How many directions the ring redraws the body in. Checked against a leaf blower's own concave
## silhouette (the arm breaks the body's own outline) at 8 first, which already read as a smooth
## rim rather than a facetted one at this scale. 12 is kept anyway, in the middle of the "eight to
## sixteen" range this cue was asked to land in — the offsets are a fixed 4px translation
## regardless of the body they redraw, so a long straight run (a barricade's segments, a protest's
## rank of placards) is the shape most likely to show a gap between two adjacent copies. The extra
## four cost nothing at the handful of instances this ever runs for (`ExcitementHalo.MAX_SOURCES`,
## 8).
const HALO_OFFSETS := 12

## How far past the body's own edge each offset copy sits, in world px. *(2026-09-07, the player:
## "the halo should not extend more than a few pixels beyond the object's outline.")*
const HALO_MARGIN := 4.0

var _draw_body: Callable
var _bob: Callable
var _glow_alpha := 0.0

## One `ShaderMaterial`, shared by every `EntityHalo` rather than built per instance.
static var _shared_material: ShaderMaterial

func _init(draw_body: Callable, bob: Callable) -> void:
	_draw_body = draw_body
	_bob = bob
	name = "Halo"
	show_behind_parent = true
	material = _halo_material()
	draw.connect(_on_draw)

static func _halo_material() -> ShaderMaterial:
	if not _shared_material:
		_shared_material = ShaderMaterial.new()
		_shared_material.shader = preload("res://assets/shaders/excitement_halo.gdshader")
	return _shared_material

## Sets how bright this rim reads and what colour it is, and queues the redraw that shows it.
## `colour`'s own alpha is ignored — `alpha` is what reaches the shader, so a caller never has to
## remember to zero both to turn a rim off.
func set_glow(alpha: float, colour: Color) -> void:
	_glow_alpha = alpha
	set_instance_shader_parameter("halo_colour", Color(colour.r, colour.g, colour.b, alpha))
	queue_redraw()

## Re-runs the owner's own body drawing at a ring of offsets around it, flattened to a silhouette
## by the shared shader. Skipped entirely at zero glow, which is what lets `CrowdAgent` leave this
## node built and simply never pay for a redraw between one startle and the next.
func _on_draw() -> void:
	if _glow_alpha <= 0.0:
		return
	var bob: float = _bob.call()
	for i in HALO_OFFSETS:
		var angle := TAU * float(i) / float(HALO_OFFSETS)
		var offset := Vector2(cos(angle), sin(angle)) * HALO_MARGIN
		draw_set_transform(Vector2(0.0, bob) + offset, 0.0, Vector2.ONE)
		_draw_body.call(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
