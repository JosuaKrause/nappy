class_name PlacementGround
extends RefCounted
## **The four kinds of ground a unit of the day's locations is** (`PlacementUnit`): a street
## (its sidewalks and its carriageway), a junction box, an alley, a park or a square. What the
## declared table is keyed by beside the view and the act (`PlacementDensity`), what a unit's bag is
## made by beside its view (`UnitFills.bag_for()`, `of()`), since a unit draws from one
## bag and a street's sidewalks and sections draw from it together, and what a catalogue row may
## weigh itself on (`EventDraft.weighed_on()`). A value and nothing else.
##
## Not `Location.Kind`, the five kinds of location: a street's sidewalk and section locations are
## one ground here.

enum Kind { STREET, JUNCTION, ALLEY, OPEN }

## **Whether ground of `kind` has tiles of `type` for a row to stand on**: a street its sidewalk
## and its carriageway, a junction box those and its crossings, an alley its alley, a park or a
## square its own. What gives a row a marble in that ground's bags (`EventDef.weight_on()`).
static func holds(kind: Kind, type: GameEnums.TileType) -> bool:
	match kind:
		Kind.STREET:
			return type == GameEnums.TileType.SIDEWALK or type == GameEnums.TileType.ROAD
		Kind.JUNCTION:
			return type == GameEnums.TileType.SIDEWALK or type == GameEnums.TileType.ROAD \
					or type == GameEnums.TileType.CROSSING
		Kind.ALLEY:
			return type == GameEnums.TileType.ALLEY
		Kind.OPEN:
			return type == GameEnums.TileType.PARK or type == GameEnums.TileType.SQUARE
	return false
