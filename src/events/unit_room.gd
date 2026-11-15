class_name UnitRoom
extends RefCounted
## **What is left of a unit for its draw to speak for, counted and not yet tied to a place**
## (`MarbleDraw`). *(The player: "if the draw takes up the whole street you're done. if it takes an
## entire segment you need to do at least two more draws", and "if you draw a marble that is
## smaller than a segment you need to draw another one (with a filter to only include also small
## marbles)"; inbox #1466.)*
##
## A street counts its sections that are whole (the section and both its sidewalk locations open)
## and the open halves of the others (one sidewalk location each). A marble taking a section fits
## only while no section is half filled, so a half-open section admits small marbles until it is
## full; a section marble leaves the other two sections, at least two more draws; a marble taking
## a side (`EventDef.StreetShare.A_SIDE`, a row that travels a sidewalk) fits only an untouched
## street, as its first marble, and leaves each section a half, three more draws. A small marble,
## the empty one among them, takes a half where one is left, else halves a whole section. So a
## whole street draws three to six marbles, or four after a side. **Every other unit** (a junction
## box, an alley, a park or a square) **is all halves**: each of its open locations takes one
## marble, whatever the row.
##
## Read off the unit's open locations (`Location.is_open()`) when it is made, so a street a mast
## stands on, or a dawn phase has filled a sidewalk of, starts with what is left. Pure state, kept
## for one draw: no node. Model.

var _whole := 0
var _halves := 0
var _untouched := false

## A room of `whole` whole sections and `halves` open halves, `untouched` while nothing is taken
## of a street all of whose sections are whole (`of()` works the three out).
func _init(whole: int, halves: int, untouched: bool) -> void:
	_whole = whole
	_halves = halves
	_untouched = untouched

## **The room of `unit` as it stands**, from its open locations.
static func of(unit: PlacementUnit) -> UnitRoom:
	var locations := unit.locations()
	var halves := 0
	if unit.kind() != PlacementUnit.Kind.STREET:
		for location in locations:
			if location.is_open():
				halves += 1
		return UnitRoom.new(0, halves, false)
	var whole := 0
	var sections := 0
	for section in locations:
		if section.kind() != Location.Kind.SECTION:
			continue
		sections += 1
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
	return UnitRoom.new(whole, halves, sections > 0 and whole == sections)

## Whether anything is left to draw for.
func is_open() -> bool:
	return _halves > 0 or _whole > 0

## **Whether a marble taking `share` fits what is left**: a side only an untouched street, a
## section only while no section is half filled and one is whole, anything smaller while anything
## is left.
func fits(share: EventDef.StreetShare) -> bool:
	match share:
		EventDef.StreetShare.A_SIDE:
			return _untouched
		EventDef.StreetShare.A_SECTION:
			return _halves == 0 and _whole > 0
		_:
			return is_open()

## **Takes `share` out of what is left**; the empty marble takes `A_LOCATION`. A side leaves each
## whole section a half; a section takes a whole one; anything smaller takes a half where one is
## left, else halves a whole section.
func take(share: EventDef.StreetShare) -> void:
	_untouched = false
	match share:
		EventDef.StreetShare.A_SIDE:
			_halves = _whole
			_whole = 0
		EventDef.StreetShare.A_SECTION:
			_whole -= 1
		_:
			if _halves > 0:
				_halves -= 1
			else:
				_whole -= 1
				_halves += 1
