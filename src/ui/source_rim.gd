class_name SourceRim
extends RefCounted
## **One source's rim, as `ExcitementHalo` lights it**: the outline of the body that is charging
## her, drawn by an `EntityHalo` its body builds (`build`), told a target strength and colour once a
## frame (`set_strength()`). The one lifetime every rim keeps, shared by the events and the crowd:
## built on the first nonzero target, never before, and given back on the spot once its fade is
## over — not the frame the target first reaches zero, or a source that just left
## `ExcitementHalo.MAX_SOURCES` would be cut off mid-fade instead of draining over
## `EntityHalo.FADE_OUT_SECONDS`. A rim held by every live source would take every block the web's
## renderer can read (`EntityHalo`'s class doc), so a rim exists only while it is lit or fading.
##
## Handed to the source it draws (`ExcitementSource.rim`) by the body that owns the picture.

## Builds the body's `EntityHalo`, already in the tree, and answers it.
var _build: Callable
var _halo: EntityHalo

func _init(build: Callable) -> void:
	_build = build

## The target this rim eases toward: `strength` (alpha) and `colour`. Zero fades it out and gives it
## back once the fade is over.
func set_strength(strength: float, colour: Color) -> void:
	if strength <= 0.0:
		if _halo:
			_halo.set_glow(0.0, colour)
			if _halo.is_faded_out():
				_let_go()
		return
	if not _halo:
		_halo = _build.call()
	_halo.set_glow(strength, colour)

## Whether this rim is held right now, lit or still fading — what `ExcitementHalo` counts against
## `EntityHalo.RIM_BUDGET`.
func is_held() -> bool:
	return _halo != null

## Gives the rim back on the spot, never through `queue_free()`: a rim keeps its block in the web
## renderer's instance buffer until the engine frees it (`EntityHalo.release()`). Asked by
## `ExcitementHalo` of a source whose body is queued for deletion.
func release() -> void:
	_let_go()

## Forgets the rim without giving it back, for one whose node went with a tree its body left.
func forget() -> void:
	_halo = null

## The rim's `EntityHalo`, or null while none is held.
func entity_halo() -> EntityHalo:
	return _halo

func _let_go() -> void:
	if _halo:
		EntityHalo.release(_halo)
		_halo = null
