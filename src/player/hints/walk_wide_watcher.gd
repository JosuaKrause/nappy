class_name WalkWideWatcher
extends HintWatcher
## **Walk wide of the noise**: a source of excitement ahead of her that would put the amber caret
## over itself for her (`ExcitementSource.caret_strength()`, the very answer the caret draws, so
## the bubble and the caret never disagree). Armed again once nothing ahead carries one.

## How far ahead, in pixels, a source is looked at.
const AHEAD_PIXELS := 8.0 * Tuning.TILE_SIZE
## How closely it lies along her heading: the cosine of the angle between the two.
const AHEAD_COSINE := 0.3

var _sets: Array[ExcitementSources] = []
var _armed := true

func _init(sets: Array[ExcitementSources]) -> void:
	_sets = sets

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.WALK_WIDE

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
		if entry.caret_strength() > 0:
			return true
	return false
