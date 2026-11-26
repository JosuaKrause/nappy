class_name WalkWideWatcher
extends HintWatcher
## **Walk wide of the noise**: a source of excitement ahead of her that would put the amber caret
## over itself for her (`ExcitementSource.caret_strength()`, the very answer the caret draws, so
## the bubble and the caret never disagree). Armed again once nothing ahead carries one. The amber
## caret alone: the doubled red one (`caret_strength()` 2, a cyclist or a car whose line reaches
## her) says *this ends your day*, which a bubble about walking wide of a noise does not answer.

## How far ahead, in pixels, a source is looked at.
const AHEAD_PIXELS := 8.0 * Tuning.TILE_SIZE
## How closely it lies along her heading: the cosine of the angle between the two.
const AHEAD_COSINE := 0.3

## `ExcitementSource.caret_strength()`'s answer for the amber caret.
const AMBER := 1

var _sets: Array[ExcitementSources] = []
var _armed := true

func _init(sets: Array[ExcitementSources]) -> void:
	_sets = sets

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.WALK_WIDE

## Overrides HintWatcher.begin_walk.
func begin_walk(_route: TutorialRoute) -> void:
	_armed = true

## Overrides HintWatcher.asks.
func asks(frame: HintFrame) -> bool:
	var marked := _a_marked_source_ahead(frame)
	if not marked:
		_armed = true
	return marked and _armed

## Overrides HintWatcher.shown.
func shown() -> void:
	_armed = false

func _a_marked_source_ahead(frame: HintFrame) -> bool:
	var found: Array = []
	for sources in _sets:
		sources.every_source(found)
	for entry: ExcitementSource in found:
		var to_it := entry.body().global_position - frame.position()
		var distance := to_it.length()
		if distance > AHEAD_PIXELS or distance < 1.0:
			continue
		if to_it.normalized().dot(frame.heading()) < AHEAD_COSINE:
			continue
		if entry.caret_strength() == AMBER:
			return true
	return false
