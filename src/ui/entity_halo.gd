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
## a frame, with the *target* alpha and colour `ExcitementHalo` computed for it — this node eases
## its own drawn alpha and colour toward that target on its own `_process()`, so a caller never has
## to know about the fade.
##
## **Both channels ease at the same rate, and both ease toward a target rather than jumping.**
## *(2026-09-08, the player: "all changes should transition (hue and transparency) instead of
## immediately showing the actual value".)* `FADE_IN_SECONDS`/`FADE_OUT_SECONDS` below are the
## whole of it: a per-frame fraction of whichever duration applies moves both `_alpha` and
## `_colour` the same amount, so a burst brightens and reddens together and drains together rather
## than one channel snapping ahead of the other.
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

## How long a rim takes to reach a higher target from a lower one. *(2026-09-08, the player: "fade
## in and fade out smoothly using transparency. right now it's always abrupt".)* Felt rather than
## derived — expect to move once it has been looked at on screen.
const FADE_IN_SECONDS := 0.3

## How long a rim takes to drain to a lower target, longer than `FADE_IN_SECONDS` so a burst that
## expires all at once dims rather than switching off — a source dropped from the picked set, or
## whose points have just left `ExcitementHalo.WINDOW`, is told a target of zero and fades out
## rather than vanishing on the spot.
const FADE_OUT_SECONDS := 0.8

var _draw_body: Callable
var _bob: Callable

## What is actually drawn, eased toward `_target_alpha`/`_target_colour` every `_process()` frame
## rather than set directly — see `FADE_IN_SECONDS`/`FADE_OUT_SECONDS`.
var _alpha := 0.0
var _colour := Color.WHITE
var _target_alpha := 0.0
var _target_colour := Color.WHITE

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

## Sets the alpha and colour this rim is easing *toward* — see the class doc. `colour`'s own alpha
## is ignored, the same as before: `alpha` is the one channel that reaches the shader, so a caller
## never has to remember to zero both to turn a rim off.
func set_glow(alpha: float, colour: Color) -> void:
	_target_alpha = alpha
	_target_colour = colour

## Whether this rim has finished fading to nothing — told a target of zero and drawn at
## (approximately) zero. `CrowdAgent` is the one caller that needs this: it frees its halo child
## once the fade is over rather than the frame the target reaches zero, or a burst that just left
## `MAX_SOURCES` would cut off mid-fade instead of draining.
func is_faded_out() -> bool:
	return _target_alpha <= 0.0 and _alpha <= 0.001

## Eases the drawn alpha and colour toward their targets, one shared per-frame step size driving
## both — see the class doc for why neither channel may snap ahead of the other. **`move_toward`
## per channel, not `Color.lerp`**: a proportional lerp only ever closes a fraction of whatever gap
## remains, so it never actually arrives — after a full `FADE_IN_SECONDS` of stepping by 1/18th of
## the remaining distance each frame (at 60fps) a third of the original gap is still open. Moving a
## fixed distance per second, the way `_alpha` already does, is what makes "reaches its target in
## about the stated seconds" true rather than approximately true forever. Skipped once everything
## has already settled, so an entity with nothing to show does not pay for a redraw every frame.
func _process(delta: float) -> void:
	if is_equal_approx(_alpha, _target_alpha) and _colour.is_equal_approx(_target_colour):
		return
	var fading_in := _target_alpha > _alpha
	var duration := FADE_IN_SECONDS if fading_in else FADE_OUT_SECONDS
	# A channel spans 0..1, so covering the whole of it in `duration` seconds is a step of
	# `delta / duration` per frame -- the same shape `_alpha`'s own step takes, scaled to its own
	# 0..MAX_ALPHA range instead.
	var channel_step := delta / duration
	_alpha = move_toward(_alpha, _target_alpha, ExcitementHalo.MAX_ALPHA * channel_step)
	_colour.r = move_toward(_colour.r, _target_colour.r, channel_step)
	_colour.g = move_toward(_colour.g, _target_colour.g, channel_step)
	_colour.b = move_toward(_colour.b, _target_colour.b, channel_step)
	set_instance_shader_parameter("halo_colour", Color(_colour.r, _colour.g, _colour.b, _alpha))
	queue_redraw()

## Re-runs the owner's own body drawing at a ring of offsets around it, flattened to a silhouette
## by the shared shader. Skipped entirely at zero drawn alpha, which is what lets `CrowdAgent` leave
## this node built and simply never pay for a redraw between one startle and the next.
func _on_draw() -> void:
	if _alpha <= 0.0:
		return
	var bob: float = _bob.call()
	for i in HALO_OFFSETS:
		var angle := TAU * float(i) / float(HALO_OFFSETS)
		var offset := Vector2(cos(angle), sin(angle)) * HALO_MARGIN
		draw_set_transform(Vector2(0.0, bob) + offset, 0.0, Vector2.ONE)
		_draw_body.call(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
