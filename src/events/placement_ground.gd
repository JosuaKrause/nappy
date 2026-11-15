class_name PlacementGround
extends RefCounted
## **The four kinds of ground a unit of the day's locations is** (`PlacementUnit`): a street
## (its sidewalks and its carriageway), a junction box, an alley, a park or a square. What the
## day's bag fills are keyed by beside the view (`UnitFills.of()`), since a unit draws from one
## bag and a street's sidewalks and sections draw from it together. A value and nothing else.
##
## Not `Location.Kind`, the five kinds of location: a street's sidewalk and section locations are
## one ground here.

enum Kind { STREET, JUNCTION, ALLEY, OPEN }
