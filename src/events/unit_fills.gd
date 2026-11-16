class_name UnitFills
extends RefCounted
## **The day's bag fills, one for each view and kind of ground**, worked out the first time a unit
## draws and kept for the day (`UnitDraw`). A fill is a marble -> how many of it (`ViewBag`), a
## marble a row's id or `ViewBag.EMPTY`.
##
## A unit's fill is the one of its view, whatever its ground: `EventScheduler.view_fills()`, the
## rows each as many times as their weight in the view and empty marbles enough for the view's
## share of locations holding an event. The ground is asked so that a fill can come to depend on
## it without a change to any caller. Model: no node.

var _rows := {}
var _day := 1
var _spec: DaySpec
## View -> its fill, once worked out.
var _fills := {}
var _worked_out := false

## `rows` the rows a unit draws today (id -> EventDef, as the day and its heat give them); `day`
## the day; `spec` the day's spec (its share of the walls, `DaySpec.wall_row_share`).
func _init(rows: Dictionary, day: int, spec: DaySpec) -> void:
	_rows = rows
	_day = day
	_spec = spec

## **The fill a unit in `view` on `ground` draws from**, `ViewBag.EMPTY` among its marbles; the
## empty marble alone for a view no fill was worked out for.
func of(view: PlacementView.View, _ground: PlacementGround.Kind) -> Dictionary:
	if not _worked_out:
		_fills = EventScheduler.view_fills(_rows, _day, _spec)
		_worked_out = true
	var fill: Dictionary = _fills.get(view, {ViewBag.EMPTY: 1})
	return fill
