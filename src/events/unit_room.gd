class_name UnitRoom
extends RefCounted
## **What is left of a unit for its draw to speak for, counted and not yet tied to a place**
## (`MarbleDraw`). *(The player: "if the draw takes up the whole street you're done. if it takes an
## entire segment you need to do at least two more draws", and "if you draw a marble that is
## smaller than a segment you need to draw another one (with a filter to only include also small
## marbles)"; inbox #1466.)*
##
## A street counts its sections that are whole (the section and both its sidewalk locations open)
## and the open halves of the others (one sidewalk location each). Of the player's three sizes, the
## two a street draws are two answers (nothing a street draws takes the whole street,
## `EventDef.StreetShare`):
##
## - **A section** fits only while no section is half filled and one is whole, so a half-open
##   section admits small marbles until it is full; a section marble leaves the other two
##   sections, at least two more draws.
## - **A small marble**, the empty one among them, takes a half where one is left, else halves a
##   whole section.
##
## So a whole street draws three to six marbles. **Every other unit** (a junction box, an
## alley, a park or a square) **is all halves**: each of its open locations takes one marble,
## whatever the row.
##
## Read off the unit's open locations (`Location.is_open()`) when it is made, so a street a mast
## stands on, or a dawn phase has filled a sidewalk of, starts with what is left. Pure state, kept
## for one draw: no node. Model.

var _whole := 0
var _halves := 0

## A room of `whole` whole sections and `halves` open halves (`of()` works them out).
func _init(whole: int, halves: int) -> void:
	_whole = whole
	_halves = halves

## **The room of `unit` as it stands**, from its open locations.
static func of(unit: PlacementUnit) -> UnitRoom:
	var locations := unit.locations()
	var halves := 0
	if unit.kind() != PlacementGround.Kind.STREET:
		for location in locations:
			if location.is_open():
				halves += 1
		return UnitRoom.new(0, halves)
	var whole := 0
	for section in locations:
		if section.kind() != Location.Kind.SECTION:
			continue
		var open_halves := 0
		var sidewalks := 0
		for sidewalk in locations:
			if sidewalk.kind() == Location.Kind.SIDEWALK and section.shares_a_section_with(sidewalk):
				sidewalks += 1
				if sidewalk.is_open():
					open_halves += 1
		if section.is_open() and sidewalks > 0 and open_halves == sidewalks:
			whole += 1
		else:
			halves += open_halves
	return UnitRoom.new(whole, halves)

## Whether anything is left to draw for.
func is_open() -> bool:
	return _halves > 0 or _whole > 0

## **Whether a marble taking `share` fits what is left**: a section only while no section is half
## filled and one is whole, anything smaller while anything is left.
func fits(share: EventDef.StreetShare) -> bool:
	if share == EventDef.StreetShare.A_SECTION:
		return _halves == 0 and _whole > 0
	return is_open()

## **Takes `share` out of what is left**; the empty marble takes `A_LOCATION`. A section takes a
## whole one; anything smaller takes a half where one is left, else halves a whole section.
func take(share: EventDef.StreetShare) -> void:
	if share == EventDef.StreetShare.A_SECTION:
		_whole -= 1
	elif _halves > 0:
		_halves -= 1
	else:
		_whole -= 1
		_halves += 1
