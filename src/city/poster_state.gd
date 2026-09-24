class_name PosterState
extends RefCounted
## What is pasted on the city's walls this run, and how many tears she has made. Run-scoped, owned
## by `GameState.posters`, and a fact about the run rather than about the seed: a crew pastes where
## her walk sites it and a sheet tears where she pushes, so neither can be recomputed.
##
## **Keyed by the sidewalk tile in front of a wall cell**, because every blank ground-floor column
## of a front has exactly one — `PosterWalls` reads a building's blank cells and names each by the
## tile a crew stands on to paste it and she stands on to tear it.
##
## A cell holds at most two sheets, and the second only ever for the look of it: `under` is the
## older sheet a new one was pasted over **with an offset large enough to read as deliberate**
## (PLAYTEST-123, statement 31), and `side` says which way the pair is shifted. A sheet pasted
## exactly over the old one replaces it and leaves no `under` (statements 32 and 33).
##
## **A lost day gives the walls back, like everything else an attempt spends.** `photograph()` is
## taken where `GameState` photographs the rest of the run and `give_back()` is called where it gives
## the rest back, so a crew that pasted and a sheet she tore on a lost day did not happen, and the
## retry's own dawn pastes the same sheets again from the same stream.

## A cell's sheet with no tear.
const INTACT := -1
## No sheet under the top one.
const NONE := -1

## `Vector2i` front tile -> `{"kind", "tear", "under", "under_tear", "side"}`.
var cells: Dictionary = {}
## The last day whose dawn pasting is on the walls, so a day started twice — a retry, or a run
## resumed from a save — pastes its dawn exactly once, and a run started on a later day under
## `--day` catches up on every dawn before it.
var pasted_through := 0
## How many tears she has made this run: how far into the marble bag the next tear draws. See
## `MarbleBag.skip()`.
var tears := 0

var _dawn: Dictionary = {}

func reset() -> void:
	cells.clear()
	pasted_through = 0
	tears = 0
	_dawn = {}

## Whether the top sheet on `tile` is there and not torn.
func has_intact_sheet(tile: Vector2i) -> bool:
	var cell: Dictionary = cells.get(tile, {})
	return not cell.is_empty() and int(cell["tear"]) == INTACT

## Whether the top sheet on `tile` is torn.
func is_torn(tile: Vector2i) -> bool:
	var cell: Dictionary = cells.get(tile, {})
	return not cell.is_empty() and int(cell["tear"]) != INTACT

## Pastes a new `kind` on `tile`. Over an older sheet, `offset` keeps the old top sheet showing
## beneath the new one, shifted `side` (+1 or -1); otherwise the new sheet covers the old exactly
## and replaces it. Whatever was under the old sheet is covered for good either way.
func paste(tile: Vector2i, kind: int, offset: bool, side: int) -> void:
	var old: Dictionary = cells.get(tile, {})
	var cell := {"kind": kind, "tear": INTACT, "under": NONE, "under_tear": INTACT, "side": side}
	if offset and not old.is_empty():
		cell["under"] = int(old["kind"])
		cell["under_tear"] = int(old["tear"])
	cells[tile] = cell

## Tears the top sheet on `tile` the `tear`th way. Answers whether there was an intact sheet to tear.
func tear(tile: Vector2i, tear_index: int) -> bool:
	if not has_intact_sheet(tile):
		return false
	cells[tile]["tear"] = tear_index
	return true

## Photographs the walls as the attempt about to be played found them. See the class note.
func photograph() -> void:
	_dawn = _as_data()

## Puts the walls back where the photograph found them.
func give_back() -> void:
	if _dawn.is_empty():
		reset()
		return
	_from_data(_dawn)

## Everything a save carries, the photograph included, as plain JSON-safe values.
func to_data() -> Dictionary:
	var data := _as_data()
	data["dawn"] = _dawn.duplicate(true)
	return data

## The other half of `to_data()`. JSON has no integer type, so every number is cast.
func restore(data: Dictionary) -> void:
	_from_data(data)
	var dawn: Variant = data.get("dawn", {})
	_dawn = _normalised(dawn) if dawn is Dictionary and not (dawn as Dictionary).is_empty() else {}

func _as_data() -> Dictionary:
	var rows: Array = []
	for tile: Vector2i in cells:
		var cell: Dictionary = cells[tile]
		rows.append({"x": tile.x, "y": tile.y, "k": int(cell["kind"]), "t": int(cell["tear"]),
				"u": int(cell["under"]), "ut": int(cell["under_tear"]), "s": int(cell["side"])})
	return {"cells": rows, "pasted_through": pasted_through, "tears": tears}

func _from_data(data: Dictionary) -> void:
	cells.clear()
	for raw: Dictionary in data.get("cells", []):
		cells[Vector2i(int(raw["x"]), int(raw["y"]))] = {"kind": int(raw["k"]),
				"tear": int(raw["t"]), "under": int(raw["u"]), "under_tear": int(raw["ut"]),
				"side": int(raw["s"])}
	pasted_through = int(data.get("pasted_through", 0))
	tears = int(data.get("tears", 0))

## A photograph read back from JSON, cast to the shape `_as_data()` writes, so a save written and
## read back compares equal to the one it came from.
static func _normalised(raw: Dictionary) -> Dictionary:
	var through := PosterState.new()
	through._from_data(raw)
	return through._as_data()
