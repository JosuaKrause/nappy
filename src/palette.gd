class_name Palette
extends RefCounted
## The colours the *code* still decides.
##
## Since M12 the art is authored SVG under `assets/`, and a tree's green or a pram's navy
## lives in the file that draws it. What is left here is everything chosen at runtime: the
## light, the act cast, the excitement fields, the chalk, and the per-variant building
## colour that one asset set is multiplied by. A colour that no longer paints anything does
## not belong in this file — a constant that looks authoritative and controls nothing is
## worse than no constant at all.
##
## Act I is the warm, pleasant baseline. Later acts desaturate and cool this down, applied
## as a per-act tint function rather than a second set of constants.

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
# The ground itself is tiles now (assets/ground_tileset.tres). These are the *flat* colour
# of each surface, which is what a map has to draw when it cannot draw the art — see
# `Tile.ground_colour` and M17's route map.

const ASPHALT := Color("46464f")
const SIDEWALK := Color("8b8478")
const GRASS := Color("6d9159")
const ALLEY_FLOOR := Color("3c3a42")
const SQUARE_STONE := Color("9a9184")
const HOME_STOOP := Color("b8836a")
const SAND := Color("cbb083")
const FOREST_FLOOR := Color("4d6b45")
const QUIET_STONE := Color("7f8a86")
const COURTYARD_STONE := Color("9b9384")
## What calm ground looks like once it has been taken or burnt: churned, colourless.
const SPOILED_GROUND := Color("6b6357")

# ------------------------------------------------------------------ events ---

## The danger marks. **Two colours, and they are a scale rather than a sequence**: amber for
## something worth going round, deep red for something that ends the day.
##
## These used to paint the aura rings, which M22 deleted: a ring communicates a falloff radius,
## which is a number, where a mark over the thing communicates a threat.
##
## *(M39, playtest 10 finding 8: "I don't understand the difference between yellow and red warning
## indicators above entities".)* There were three, and they were the three *phases* of an event —
## amber telegraphing, red live, deep red lethal. Two things were wrong with that at once. A
## telegraph is almost always over before the event is on screen, so the amber was only ever seen on
## the two rows sited in front of the player and read as "near"; and `MARK_ACTIVE` and `MARK_LETHAL`
## were two reds a player is asked to tell apart on a 15px caret. Phase is carried by the **flash**
## now, which is what a flash is for, and the colour carries the only thing a colour is good at:
## how bad. See `EventInstance.mark_colour()`.
const MARK_COSTLY := Color("e8b64a")
const MARK_LETHAL := Color("8f2f38")

const CHALK := Color(0.92, 0.92, 0.88, 0.62)
const CHALK_DONE := Color(0.78, 0.88, 0.72, 0.9)
const HOME_ARROW := Color("8fb4d9")

# --------------------------------------------------------------- buildings ---
# One asset set covers every building: the near-white wall and roof tiles are multiplied by
# the variant's colour. These therefore still decide what a building looks like.

const _ROOFS: Array[Color] = [
	Color("c2a179"), Color("b08968"), Color("a8907a"),
	Color("cbb391"), Color("9d7f68"), Color("bda386"),
]

## Roof colour for a building variant index.
static func building_roof(variant: int) -> Color:
	return _ROOFS[posmod(variant, _ROOFS.size())]

## The visible front face is the roof colour in shade.
static func building_wall(variant: int) -> Color:
	return building_roof(variant).darkened(0.42)

## A burnt-out block keeps its own colour underneath, drained and darkened, so the corner is
## recognisably the corner it was — which is the whole point of a scar.
static func burnt(colour: Color) -> Color:
	return colour.lerp(Color("2e2a2c"), 0.72)

# --------------------------------------------------------------- the crowd ---
# Walkers and cars are drawn as a near-white body plus a full-colour trim overlay, the same
# split the buildings use, so ninety people are not one silhouette in one colour.

const COATS: Array[Color] = [
	Color("6b7a8c"), Color("7d6a5b"), Color("59636e"), Color("8a7d6b"),
	Color("6e5f6b"), Color("4f5b52"), Color("94806a"), Color("5c6a76"),
]

const CAR_PAINT: Array[Color] = [
	Color("8d9299"), Color("6d7a86"), Color("8a6f60"), Color("5f6b5c"),
	Color("9a9384"), Color("57606b"),
]

# ---------------------------------------------------------------- entities ---
# The rig, the props and the event bodies are sprites; their colours are in the SVGs. The
# shadow is not, because everything that stands on the ground draws the same one at its own
# size, tinted from here.

const SHADOW := Color(0.0, 0.0, 0.0, 0.22)
