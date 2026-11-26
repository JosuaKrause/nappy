class_name ChalkMarkWatcher
extends HintWatcher
## **The chalk mark**: when today's mark first comes into her view, the bubble hints that she can
## go into the alley to reach it (minty-dolphin #868; "when the mark becomes visible to the player
## for the first time it causes a thought bubble", gentle-owl #1234). Once a walk; a few times in
## all, as every lesson's bubble (`HintLedger`).
##
## The mark is the resistance's (`ResistanceDirector.mark_on_offer()`), which stands after the city's
## simulation is built, so the watcher is handed a narrow reader of it: `where`, which takes nothing
## and answers where today's mark is, or `Vector2.INF` for none. `main` binds it.

var _view: VisibleView
var _where: Callable
var _shown := false

func _init(view: VisibleView, where: Callable) -> void:
	_view = view
	_where = where

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.CHALK_MARK

## Overrides HintWatcher.begin_walk.
func begin_walk(_route: TutorialRoute) -> void:
	_shown = false

## Overrides HintWatcher.asks.
func asks(_frame: HintFrame) -> bool:
	if _shown:
		return false
	var mark: Vector2 = _where.call()
	return mark != Vector2.INF and _view.sees(mark)

## Overrides HintWatcher.shown.
func shown() -> void:
	_shown = true
