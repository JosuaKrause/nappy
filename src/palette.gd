class_name Palette
extends RefCounted
## Colours for the procedural 2.5D rendering.
##
## Act I is the warm, pleasant baseline. Later acts desaturate and cool this down; that
## transformation lands in M7 (see docs/NARRATIVE.md) and will be applied as a per-act
## tint function rather than a second set of constants.

const OUTLINE := Color("221f28")

## Daylight over the whole city canvas, from midday to dusk. Act tinting multiplies into
## this in M7.
const LIGHT_MIDDAY := Color(1.0, 1.0, 1.0)
const LIGHT_DUSK := Color(0.52, 0.54, 0.74)

## Per-act cast over the whole city, multiplied into the daylight. The escalation in
## docs/NARRATIVE.md is told by the streets, and this is the quietest part of that telling:
## the same corner, four times, getting colder.
const _ACT_TINT: Array[Color] = [
	Color(1.02, 0.99, 0.93),  ## I   - warm afternoon
	Color(0.96, 0.95, 0.93),  ## II  - drained, a notch off
	Color(0.82, 0.86, 0.95),  ## III - cold and overcast; the streets are empty
	Color(0.88, 0.79, 0.75),  ## IV  - smoke
]

static func act_tint(act: int) -> Color:
	return _ACT_TINT[clampi(act - 1, 0, _ACT_TINT.size() - 1)]

# ------------------------------------------------------------------ ground ---

const ASPHALT := Color("46464f")
const ROAD_MARKING := Color("b9b087")
const SIDEWALK := Color("8b8478")
const SIDEWALK_SEAM := Color("7a7469")
## The sidewalk/road kerb has to read against both surfaces, so it is lighter than either.
const KERB := Color("a49b8c")
const GRASS := Color("6d9159")
const ALLEY_FLOOR := Color("3c3a42")
const SQUARE_STONE := Color("9a9184")
const HOME_STOOP := Color("b8836a")
const HOME_DOOR := Color("5c3a30")
const SAND := Color("cbb083")

const TREE_TRUNK := Color("5b4433")
const TREE_CANOPY := Color("4f7a44")
const TREE_HIGHLIGHT := Color("649256")
const PLAYGROUND_FRAME := Color("c05f4a")
const CROSSING_STRIPE := Color("cfc7ae")

# ------------------------------------------------------------------ events ---

const CAT_FUR := Color("58524d")
const NPC_COAT := Color("6b7a8c")
## Excitement fields: amber while telegraphing, red once the event is at full strength.
const AURA_TELEGRAPH := Color("e8b64a")
const AURA_ACTIVE := Color("d2543f")
const AURA_LETHAL := Color("8f2f38")

const FIRE_OUTER := Color("d1622c")
const FIRE_INNER := Color("f0c04a")

const CHALK := Color(0.92, 0.92, 0.88, 0.62)
const CHALK_DONE := Color(0.78, 0.88, 0.72, 0.9)

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
