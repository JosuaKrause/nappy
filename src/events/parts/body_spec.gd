class_name BodySpec
extends RefCounted
## **What a row is on the ground, as one value**: the ground shape its shadow and its solid body are
## both derived from, whether it is solid (and so closes ground), the pieces it is solid in, when
## it is solid, what a crowd walker takes it for while it stands, whether it parks once it stands,
## and how it lies on the street it stands on. A row holds one (`EventDef.body()`); nothing
## changes it once it exists (a refinement returns a new value), so a row's copies share it by
## reference, and the live body (`EventBody`) is handed it.
##
## **The body is the shape.** A solid body's reach is its shape's (`obstructs_within()`), never a
## second number chosen to match it, so a body whose radius disagrees with its shape cannot be
## written. A footprint is a shape with nothing solid under it: a row with a look but no body, and a
## car that drives, whose body is laid along its heading and closes no ground
## (`VehicleSpec`). See `docs/EVENTS.md`, "Solid things are solid".
##
## **Anything that stands still is solid at the width it is drawn.** A rule rather than a list, or a
## delivery van becomes scenery. The reach is half the silhouette, not a balance value, because
## `SpreadLook._draw_spread` draws a blocking object at exactly the width it obstructs. Four
## things are exempt, each for its own reason: anything mobile (a moving wall on a two-tile
## sidewalk pins her against a building), anything director-sited (`EventDef.validate()` refuses
## it: nothing checks that a thing sited out of where she happens to be walking leaves a route to a
## park), anything with no silhouette (a city-wide source, a playground the park already draws),
## and a flock (`validate()` refuses it: several bodies wheeling inside one disc have no one
## silhouette to be half of). And one constraint rather than an exemption: a lethal row's body has
## to fit inside its lethal radius with her own body to spare.

## **The narrowest half-run a drawn body is given**, in px: a body smaller than this is still drawn
## and footprinted at this width (`drawn_width()`), so the one statement of the floor is here.
const NARROWEST_HALF_RUN := 11.0

## **How a row's body and its picture lie on the street it stands on**, the one choice a body makes
## between them (`lies()`): a body lies one way, so two cannot be written.
enum Lie {
	## As it faces: nothing said.
	AS_IT_FACES,
	## Drawn as a spread across its street (`as_a_spread()`): segments or a whole scene fitted across
	## the body's reach, laid along whichever axis `BodyStance.lies_vertically_at()` picks for the
	## street it stands on (`SpreadLook._draw_spread`, `RankLook._draw_cafe`, and
	## `SpreadLook._draw_wide_scene` for the three seal pictures wide enough to span the street, each
	## with an authored east-west asset, `EventPictures.wide_scene_texture`). A junction has no
	## single street for the spread's axis, so `RowGround.tiles_for()` offers a spread no corner.
	SPREAD,
	## Along its street without being drawn as a spread (`along_its_street()`): a protest's rank of
	## placards and a firefight's cover. Their drawn box and their solid body's spine follow the
	## street's axis (`EventFootprints.drawn_box_of()`, `BodyStance.solid_axis_of()`); they never
	## ask the spread's corner question.
	ALONG,
	## Across its street (`across_its_street()`): a stationary vehicle left broadside across the
	## carriageway, the burnt-out car, where the moving van stands along the kerb. Decides which
	## view it shows on a street (`BodyStance.stands_side_on()`) and so which way its body lies.
	ACROSS,
}

## **When the row's body is solid to her.** Almost every body is a place, solid from its first frame
## for the whole of its life; two rows are solid only part of the time, and a row is one or the
## other, never both.
enum SolidWhen {
	## From the instance's first frame: every body but the two below.
	ALWAYS,
	## **The body arrives when the notice ends rather than with the instance**
	## (`once_it_starts()`), for a row that turns on where she is already standing. Every other solid
	## row is a *place*, on its tile before she gets near it. A vent on a timer closes ground she may
	## be walking down at the moment it fires, and a body that appears around her is not something a
	## telegraph can answer.
	##
	## So the notice runs with no body and the body goes down at the end of it, and the live event's
	## body (`EventBody.come_down_clear_of_her()`) withholds it for as long as she is still inside
	## the footprint: **a vent never turns on with her in it.** Nothing is placed and then moved,
	## and withholding obstruction can only leave more ground reachable. Standing in a vent to keep
	## it open costs the full field, so it is the most expensive way through rather than a way past.
	##
	## **A planner's own record does not know about this**: `EventManager` rasterises a row's body
	## into `CityMap.obstructed_tiles` from the *plan*, before any instance exists, so a row solid
	## this way reads as solid to the crowd and to route-clearing for the whole of its life. Use it
	## on something placed where there is no lattice to clear, or accept that the ground is reserved
	## the whole time.
	ONCE_IT_STARTS,
	## **A boom** (`while_lowered()`): a bar across a door's carriageway that the cars raise and
	## lower (`Crowd._stop_for_gates()`, through the `GateState` its instance carries), and that is
	## solid to her **only while it is down**. `checkpoint_gate` is the one row that is one.
	##
	## It never detains: a lowered boom is a wall across the road and a raised one is ground she
	## may walk under, at the price of the car that raised it and of the guard a walked crossing
	## sets on her (`CheckpointController._set_a_guard_on_her()`). The inspection is the huts'
	## alone, and a hut never takes her in from the carriageway its own door's boom spans.
	##
	## Read in three more places, each because a boom is a door body that does not detain:
	## `EventSpawner.obstructed_footprint()` keeps it out of the crowd's per-tile record as it keeps
	## the huts out (the cars' answer to it is the gate hold), `EventDirector` keeps the door's clear
	## ground around it, and the live event's body lets its collision body follow the arm
	## (`EventBody.follow_the_arm()`).
	WHILE_LOWERED,
}

## **What the row's figure is to a crowd walker that meets it standing still** (inbox #905 in
## freckled-moose): a walker may walk through a person or an animal standing still, and walks round
## an object or a vehicle. A figure under way is given way to whatever it is, and a crowd car stands
## for any figure in its lane once it has moved; this is only the walker's question about a figure
## that stands (`MoveProposal.stood_round_a_body()`, which `EventInstance.setup()` sets from it).
##
## Every row declares it, and `EventDef.validate()` refuses one that does not: a default would have
## walkers walk through a parked van, or round an invisible point, without anybody deciding either.
enum StandsAs {
	## Not declared: refused by `EventDef.validate()`.
	UNDECLARED,
	## A person or an animal (`walked_through()`: a street musician, a policeman, a dog, a flock of
	## pigeons): walked through while it stands, and given way to only while it moves.
	SOMEBODY,
	## An object or a vehicle (`walked_round()`: a cafe's tables, a stall, a van, a mast, the patrol
	## car, the fire engine): walked round while it stands, as it is while it moves. One with a solid
	## body is walked round by its tiles already (`CityMap.obstructed_tiles`); this also keeps a
	## walker out of one that has none, a vehicle that drives.
	SOMETHING,
	## Nothing a walker meets on the ground (`unmet()`): no picture of its own (`Look.NONE`), or a
	## picture on a wall or flat on the ground (the fire on a facade, a burnt frontage, a crater, a
	## steam vent). Walked through like a person while it stands; none of these moves.
	NOTHING,
}

## **Whether the row's figure, once it stands, stands there for good** (inbox #909 in
## freckled-moose): what tells a crowd car behind it in its lane to turn round, as it does at a
## blocked street, rather than wait. Behind a figure that has parked a car turns round; behind one
## that is only stopping (the patrol car at a red light or while its man is out, a dog standing for
## its notice) it waits.
##
## The row says whether its figure parks; the instance says when it has (`EventInstance` sets
## `MoveProposal.has_parked()` from this and its phase): a figure that never moves has parked from the
## start, and one that drives to where it stops (`EventDef.parks_where_it_arrives()`) has parked once
## it is there. Every row declares it, and `EventDef.validate()` refuses one that does not, and one
## whose declaration its motion contradicts: a row that stops where it arrives parks, and a row that
## moves any other way, chases her or wheels as a flock does not.
enum WhenItStops {
	## Not declared: refused by `EventDef.validate()`.
	UNDECLARED,
	## It goes on (`going_on()`): a stand is a pause, and a car behind it waits for it to move (the
	## patrol car, a dog, a cyclist, a pursuer, the column's trucks, anything that leaves or chases
	## her).
	GOES_ON,
	## It parks (`parked()`): once it stands it stays for the rest of its time in the world, and a
	## car behind it turns round (the fire engine at its fire, a van set up for the day, a stall, a
	## barricade).
	PARKS,
}

## The ground shape its shadow and its solid body are both derived from, or null for a row with no
## picture. A plain `var`, since `GroundShape` is a `RefCounted` and cannot export; nothing
## changes a shape in place, so a value shares it.
var _shape: GroundShape = null
## Whether anything stops her here: a footprint has a shape and no body.
var _solid := false
## The pieces its body is declared in, in the scene's own frame; empty means one piece at the origin
## (`BodyPiece`).
var _pieces: Array[BodyPiece] = []
var _solid_when := SolidWhen.ALWAYS
var _stands_as := StandsAs.UNDECLARED
var _when_it_stops := WhenItStops.UNDECLARED
var _lie := Lie.AS_IT_FACES
## The pieces its body is made of with the default filled in: the declared ones, or one piece at
## the origin carrying the shape, none for a body with no shape. Worked out once when the value is
## made, since `EventLook._draw_body_shadow()` asks on every draw of every visible event.
var _laid: Array[BodyPiece] = []

# ------------------------------------------------------------ making one ---

## A row with nothing on the ground: no shape, nothing solid. It still says what a walker takes it
## for and whether it parks, like every body.
static func none() -> BodySpec:
	return BodySpec.new()._made()

## A shape drawn and cast as a shadow, with nothing solid under it: a row with a look that stops
## nobody, a car that drives.
static func footprint(shape: GroundShape) -> BodySpec:
	var spec := BodySpec.new()
	spec._shape = shape
	return spec._made()

## A solid body of `shape`: she is stopped by it, and its reach is the shape's.
static func solid(shape: GroundShape) -> BodySpec:
	var spec := BodySpec.new()
	spec._shape = shape
	spec._solid = true
	return spec._made()

## The same body standing as `shape`, every other thing it says kept (solid stays solid, a footprint a
## footprint): what a copy placed where the ground is another width does (a seal's hard body, an
## alley's mouth wall), and a row of a different shape.
func reshaped(shape: GroundShape) -> BodySpec:
	var spec := _copy()
	spec._shape = shape
	return spec._made()

## The same body solid in `pieces` only, inside its own shape and nowhere else.
func in_pieces(pieces: Array[BodyPiece]) -> BodySpec:
	var spec := _copy()
	spec._pieces = pieces
	return spec._made()

## The same body, solid once its notice ends rather than from its first frame.
func once_it_starts() -> BodySpec:
	var spec := _copy()
	spec._solid_when = SolidWhen.ONCE_IT_STARTS
	return spec._made()

## The same body, a boom's: solid only while it is lowered.
func while_lowered() -> BodySpec:
	var spec := _copy()
	spec._solid_when = SolidWhen.WHILE_LOWERED
	return spec._made()

## The same body, somebody a walker walks through while it stands.
func walked_through() -> BodySpec:
	var spec := _copy()
	spec._stands_as = StandsAs.SOMEBODY
	return spec._made()

## The same body, something a walker walks round while it stands.
func walked_round() -> BodySpec:
	var spec := _copy()
	spec._stands_as = StandsAs.SOMETHING
	return spec._made()

## The same body, nothing a walker meets on the ground.
func unmet() -> BodySpec:
	var spec := _copy()
	spec._stands_as = StandsAs.NOTHING
	return spec._made()

## The same body, parked once it stands.
func parked() -> BodySpec:
	var spec := _copy()
	spec._when_it_stops = WhenItStops.PARKS
	return spec._made()

## The same body, going on once it stands.
func going_on() -> BodySpec:
	var spec := _copy()
	spec._when_it_stops = WhenItStops.GOES_ON
	return spec._made()

## The same body, drawn as a spread across its street.
func as_a_spread() -> BodySpec:
	var spec := _copy()
	spec._lie = Lie.SPREAD
	return spec._made()

## The same body, standing along its street without being drawn as a spread.
func along_its_street() -> BodySpec:
	var spec := _copy()
	spec._lie = Lie.ALONG
	return spec._made()

## The same body, lying across its street.
func across_its_street() -> BodySpec:
	var spec := _copy()
	spec._lie = Lie.ACROSS
	return spec._made()

# -------------------------------------------------------------- questions ---

## Whether it has a body at all: something she is stopped by, rather than a figure she walks up to
## or a picture flat on the ground.
func has_a_body() -> bool:
	return obstructs_within() > 0.0

## Its ground shape: the datum its shadow and its solid body are both derived from, or null for a
## row with no picture.
func ground_shape() -> GroundShape:
	return _shape

## How far round its position its body stops her: its shape's reach when it is solid, 0 for a row
## that stops nothing. **It is the ground this row closes, which is not always the ground it is
## solid on**: a row solid in pieces puts its bodies down inside this disc and leaves the rest open
## (the crash), so *has a body* and *closes ground* differ for exactly one row and
## `solid_reach()` is the first of the two. Every planner reads this one: they clear, space and
## refuse ground, and an upper bound is the conservative answer.
func obstructs_within() -> float:
	return _shape.reach() if _solid and _shape != null else 0.0

## The furthest any actual body of this row reaches from its own centre: `obstructs_within()` for
## every one-piece row, less for a row of several. **This is the "where is she stopped" reading of a
## body, and `obstructs_within()` is the "how much ground does this close" one.** Anything asking
## where her centre comes to rest (`EventDef.validate()`'s lethal-radius check) asks this; anything
## clearing or spacing ground asks `obstructs_within()`.
func solid_reach() -> float:
	if _shape == null or obstructs_within() <= 0.0:
		return 0.0
	var furthest := 0.0
	for piece in _laid:
		furthest = maxf(furthest, piece.reach())
	return furthest

## Whether it says it is solid and has no shape to be solid as, a body that would stop nobody while
## claiming to (`solid()` is handed a shape, which GDScript cannot refuse to be null);
## `EventDef.validate()` refuses it.
func is_solid_with_no_shape() -> bool:
	return _solid and _shape == null

## The pieces its body is made of, in the scene's own frame: the declared ones, or one piece at the
## origin carrying its shape. The one form a live event's body (`EventBody`), its shadow and
## `BodyStance`'s layout of a body (`pieces_laid_out()`) are built from.
func pieces() -> Array[BodyPiece]:
	return _laid

## The pieces it declared, none for a body that is one piece at the origin.
func declared_pieces() -> Array[BodyPiece]:
	return _pieces

## When its body is solid to her: from its first frame, once it starts, or while a boom's arm is
## down.
func solid_from() -> SolidWhen:
	return _solid_when

## Whether it is a door's boom, solid only while lowered.
func is_a_boom() -> bool:
	return _solid_when == SolidWhen.WHILE_LOWERED

## Whether a crowd walker goes round its figure while it stands still, as round an object or a
## vehicle, rather than through it, as through a person or an animal.
func is_walked_round() -> bool:
	return _stands_as == StandsAs.SOMETHING

## Whether it says what a walker takes it for (every row does; `EventDef.validate()` asks).
func says_what_it_stands_as() -> bool:
	return _stands_as != StandsAs.UNDECLARED

## Whether its figure, once it stands, stands there for good: a crowd car behind it turns round
## rather than waits.
func parks() -> bool:
	return _when_it_stops == WhenItStops.PARKS

## Whether it says whether it parks (every row does; `EventDef.validate()` asks).
func says_whether_it_parks() -> bool:
	return _when_it_stops != WhenItStops.UNDECLARED

## How it lies on its street: as a spread across it, along it, across it, or as it faces.
func lies() -> Lie:
	return _lie

## **How wide its body's picture is drawn along its run, in px**: twice its reach, **floored at**
## `NARROWEST_HALF_RUN` a side. The one statement of the floor: the footprints and the spread's
## drawing ask it rather than each holding the number.
func drawn_width() -> float:
	return maxf(NARROWEST_HALF_RUN, obstructs_within()) * 2.0

# ---------------------------------------------------------------- private ---

## Fills what is derived, once, when the value is made.
func _made() -> BodySpec:
	if not _pieces.is_empty():
		_laid = _pieces
	elif _shape != null:
		_laid = [BodyPiece.at(0.0, 0.0, _shape)] as Array[BodyPiece]
	else:
		_laid = []
	return self

func _copy() -> BodySpec:
	var spec := BodySpec.new()
	spec._shape = _shape
	spec._solid = _solid
	spec._pieces = _pieces
	spec._solid_when = _solid_when
	spec._stands_as = _stands_as
	spec._when_it_stops = _when_it_stops
	spec._lie = _lie
	return spec