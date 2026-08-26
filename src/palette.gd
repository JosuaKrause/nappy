class_name Palette
extends RefCounted
## Colours for the procedural 2.5D rendering.
##
## Act I is the warm, pleasant baseline. Later acts desaturate and cool this down; that
## transformation lands in M7 (see docs/NARRATIVE.md) and will be applied as a per-act
## tint function rather than a second set of constants.

const OUTLINE := Color("221f28")

# ------------------------------------------------------------------ ground ---

const ASPHALT := Color("46464f")
const ROAD_MARKING := Color("b9b087")
const SIDEWALK := Color("8b8478")
const SIDEWALK_SEAM := Color("7a7469")
const GRASS := Color("6d9159")
const ALLEY_FLOOR := Color("3c3a42")
const SQUARE_STONE := Color("9a9184")

# --------------------------------------------------------------- buildings ---

const _ROOFS: Array[Color] = [
	Color("c2a179"), Color("b08968"), Color("a8907a"),
	Color("cbb391"), Color("9d7f68"), Color("bda386"),
]

const WINDOW_DARK := Color("3b3a46")
const WINDOW_LIT := Color("e8c887")

## Roof colour for a building variant index.
static func building_roof(variant: int) -> Color:
	return _ROOFS[posmod(variant, _ROOFS.size())]

## The visible front face is the roof colour in shade.
static func building_wall(variant: int) -> Color:
	return building_roof(variant).darkened(0.42)

# ---------------------------------------------------------------- the rig ---

const COAT := Color("b0574f")
const COAT_SHADE := Color("8e433d")
const TROUSERS := Color("46506b")
const SKIN := Color("d9a878")
const HAIR := Color("3a2b26")
const SHOE := Color("2f2a2c")

const PRAM_BODY := Color("3f4a5c")
const PRAM_HOOD := Color("d8ccb4")
const PRAM_TRIM := Color("2b3341")
const PRAM_WHEEL := Color("26232a")

const SHADOW := Color(0.0, 0.0, 0.0, 0.22)
