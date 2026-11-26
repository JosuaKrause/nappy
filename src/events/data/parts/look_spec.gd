class_name LookSpec
extends RefCounted
## **How a row is drawn and what its drawing owes**, as one value: its picture, the warning picture
## it stands in while it warns, whether a shadow is put down under its body, whether it trails a
## slack lead, whether its own hold hides the whole of it, whether a rider of it may be the run's
## pelican, and which sides of its band a guard stands on. A row holds one (`EventDef.look()`);
## nothing changes it once it exists (a refinement returns a new value), so a row's copies share it
## by reference. `none()` is a row with no picture of its own.
##
## **One look per row, and every look is a thing rather than a category.** A picture names one
## look (`EventDef.Look`); the looks (`EventLooks.for_row()`) are handed this value and ask the live
## event the rest, since what a picture needs of its body, its field or its route is the event's to
## answer.

## The pictures a row standing in its warning is drawn in, whose largest decides whether its warning
## would stand in her view (`EventFootprints.warning_picture_size()`).
enum WarningPicture {
	## The guard's raised hand: every pursuer drawn standing in a warning that is not one of these.
	GUARD_ALERT,
	## The charging dog's alert.
	DOG_ALERT,
	## The alley robber's two alert frames.
	ROBBER_ALERT,
}

## The picture the row is drawn as, which is the silhouette its badge carries. Every visible row
## states its own; `tests/test_events_catalogue.gd` names the two that are legitimately invisible.
var _picture := EventDef.Look.NONE

## The picture a row standing in its warning is drawn in.
var _warning_picture := WarningPicture.GUARD_ALERT

## Whether a shadow is put down under its body. `true` for every row but three: `burst_water_main`
## is a crater sunk into the road, and `burning_building` and `burnt_shell` are drawn on the
## building they stand against. **The body and the collision are untouched**; this governs the
## shadow patch alone.
var _casts_a_shadow := true

## **Whether it trails a slack lead behind it**: the loose dog, whose lead reaches
## `EventFootprints.LOOSE_LEAD_REACH` behind it, which everything it can put on the screen includes
## (`EventFootprints.footprint_of()`).
var _drags_a_lead := false

## **Whether its own hold hides the whole of it**: `checkpoint_post`, one guard at an alley mouth
## and nothing else, who goes in with her (`EventFootprints.hidden_by_its_hold()`). A hut or a
## gate is a structure, drawn through its hold.
var _vanishes_into_its_hold := false

## **Whether a rider on it may be drawn as the pelican** (`EventSpawner.rolls_a_pelican()`): the
## cyclist, about one in 400 drawn as a pelican on the same bike. Only the picture changes.
var _may_be_a_pelican := false

## Which side or sides of a `Look.ROADBLOCK` band `RoadblockLook._draw_roadblock()` posts a standing
## guard on: `-1`/`+1` in `guard_post_offset()`'s own reading of `side`, the same sign
## `_guard_side_toward()` and `EventBarrierPost.chaser_side()` use. `[-1, 1]` (both) is every row's
## default: the catalogue `roadblock` and every wall body inherit it unless something overrides it.
##
## **Two overrides, both the region wall's own.** A wall crossing stands three bodies (sidewalk,
## road, sidewalk), and a guard on both sides of all three would draw six
## (PLAYTEST-135 8): `SealPlanner.place_hard_on()` redrafts the middle one with the sides
## emptied, so the tarmac between the sidewalks draws none. A walled alley's two mouths would each
## draw two guards, one standing inside an alley she can never reach, so
## `RegionPlanner._alley_mouth_wall_body()` sets the one-element array naming the mouth's own
## street-facing side (`_alley_mouth_street_side()`).
##
## **Carried on the row, set on the placement**: nothing decides *which* side is which, so an
## override is a value written on a redraft at placement. What reads the sides is the
## roadblock's look when it draws the band and the barrier post when its guards leave (the side the
## far guard walks off from, which posts still have a man).
var _guard_sides: Array[int] = [-1, 1]

## **Whether the sky lights up as it goes off**: the escape city's explosion, a bright flash over the
## whole screen the moment its telegraph is over, wherever it is (`BlastLight`; minty-lemur #785).
## The light is all it changes: the field, the cost and the crater are the row's own either way.
var _flashes := false

## **Whether its picture is drawn only in its screen-edge badge, never in the world**: the escape
## city's explosion, whose mushroom of smoke the badge carries for a thing only ever heard on the
## street. The row states it, as it states its flash, so nothing asks which picture a row has to
## know whether that picture stands on the street.
var _only_in_its_badge := false

## A row with no picture of its own: nothing is drawn for it.
static func none() -> LookSpec:
	return LookSpec.new()

## A row drawn as `picture`, casting a shadow, standing in the guard's raised hand while it warns,
## trailing no lead, drawn through its hold, ridden by no pelican, posting a guard on both sides.
static func of(picture: EventDef.Look) -> LookSpec:
	var spec := LookSpec.new()
	spec._picture = picture
	return spec

## The same look, standing in `picture` while it warns.
func warning_as(picture: WarningPicture) -> LookSpec:
	var spec := _copy()
	spec._warning_picture = picture
	return spec

## The same look with no shadow put down under its body.
func casting_no_shadow() -> LookSpec:
	var spec := _copy()
	spec._casts_a_shadow = false
	return spec

## The same look with a shadow put down under its body: a copy of a row that casts none, drawn where
## its shadow is wanted.
func casting_a_shadow() -> LookSpec:
	var spec := _copy()
	spec._casts_a_shadow = true
	return spec

## The same look trailing a slack lead behind it.
func trailing_a_lead() -> LookSpec:
	var spec := _copy()
	spec._drags_a_lead = true
	return spec

## The same look, its whole figure hidden while its hold has it.
func hiding_in_its_hold() -> LookSpec:
	var spec := _copy()
	spec._vanishes_into_its_hold = true
	return spec

## The same look, a rider of it drawn as the pelican about one time in 400.
func maybe_a_pelican() -> LookSpec:
	var spec := _copy()
	spec._may_be_a_pelican = true
	return spec

## The same look, the sky lighting up as it goes off.
func flashing_as_it_goes_off() -> LookSpec:
	var spec := _copy()
	spec._flashes = true
	return spec

## The same look, its picture drawn only in its screen-edge badge and nothing of it in the world.
func drawn_only_in_its_badge() -> LookSpec:
	var spec := _copy()
	spec._only_in_its_badge = true
	return spec

## The same look posting a guard on `sides` of its band (`-1`/`+1`), and on none for an empty list.
func guarded_on(sides: Array[int]) -> LookSpec:
	var spec := _copy()
	spec._guard_sides = sides.duplicate()
	return spec

## The picture it is drawn as, which is the silhouette its badge carries
## (`EventPictures.icon_for()`).
func picture() -> EventDef.Look:
	return _picture

## **Whether anything of it is drawn in the world**: not for a row with no picture
## (`EventDef.Look.NONE`), nor for one whose picture is drawn only in its screen-edge badge
## (`drawn_only_in_its_badge()`, the escape city's explosion). What a row puts on the street is
## measured only where this holds (`EventFootprints.box_of()`), so a badge's picture is never
## taken for a thing standing there, and only such a row owes a shape and, standing still, a body.
func is_drawn_in_the_world() -> bool:
	return _picture != EventDef.Look.NONE and not _only_in_its_badge

## The picture it stands in while it warns, whose largest decides whether its warning would stand
## in her view.
func warning_picture() -> WarningPicture:
	return _warning_picture

## Whether a shadow is put down under its body.
func casts_a_shadow() -> bool:
	return _casts_a_shadow

## Whether it drags a slack lead behind it: the loose dog.
func drags_a_lead() -> bool:
	return _drags_a_lead

## Whether its own hold hides the whole of it: one guard at an alley mouth.
func vanishes_into_its_hold() -> bool:
	return _vanishes_into_its_hold

## Whether a rider of it may be the run's one pelican: the cyclist, which is the only row that
## draws from the run's pelican bag.
func may_be_drawn_as_a_pelican() -> bool:
	return _may_be_a_pelican

## Whether the sky lights up as it goes off: the escape city's explosion.
func flashes_as_it_goes_off() -> bool:
	return _flashes

## The sides of its band a guard stands on, `-1`/`+1` (a copy: nothing changes the look's own).
func guard_sides() -> Array[int]:
	return _guard_sides.duplicate()

func _copy() -> LookSpec:
	var spec := LookSpec.new()
	spec._picture = _picture
	spec._warning_picture = _warning_picture
	spec._casts_a_shadow = _casts_a_shadow
	spec._drags_a_lead = _drags_a_lead
	spec._vanishes_into_its_hold = _vanishes_into_its_hold
	spec._may_be_a_pelican = _may_be_a_pelican
	spec._guard_sides = _guard_sides.duplicate()
	spec._flashes = _flashes
	spec._only_in_its_badge = _only_in_its_badge
	return spec
