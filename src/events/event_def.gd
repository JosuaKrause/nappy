class_name EventDef
extends Resource
## Authored data for one kind of event. See docs/EVENTS.md.
##
## Defs are constructed in code by `EventCatalogue` rather than saved as .tres files: they
## are reviewable in a diff, they can be validated on load, and the fairness contract can be
## asserted over the whole catalogue in a test. Nothing here needs an editor to tune.

## How the instance is drawn. Data rather than a script per event, since most events differ
## only in their numbers.
##
## **One look per row, and every look is a thing rather than a category.** Names like `ANIMAL`,
## `EventPictures.PERSON`, `VEHICLE`, `OBJECT` and `FIRE` do the damage all by themselves: a
## category is something you can always put one more row into, and then a man shouting, a busker, a
## poster crew, a protest and the robbery that ends the day are one `person.svg`, while a delivery
## van, a fire engine, a police car, a riot van, an army truck and the unmarked van that takes the
## baby are one van.
##
## That is not a missing art pass, it is the first row of the visual vocabulary failing — *the
## entity itself carries most of it* — and the cost lands on the player as *"not sure what that
## person was supposed to be"* and *"who is the person killing me?"*. It lands on this side too: a
## complaint about the man who shouts and a complaint about the robber are indistinguishable when
## the two draw the same man.
##
## So a look is the name of one picture, and `tests/test_events.gd` holds both halves of the rule:
## **no two rows share a look**, and **no two looks share a silhouette**. There is deliberately no
## generic left to reach for — the cost of adding an event is a drawing.
enum Look {
	NONE,     ## Invisible — something else already draws it (a park's playground frame).
	# ---- act I ----
	CAT,          ## Crouched, then stretched out flat. The crouch is the telegraph.
	MOUSE,        ## A single side-on silhouette, mirrored east and west. No crouch of its own —
	              ## it is already still, being small, and the dash is the whole event.
	YELLER,       ## A long coat, a raised arm, a beard. One shape where a passer-by is two.
	DOG_WALKER,   ## A person, a dog, and the taut lead between them.
	CAFE,         ## Tables across the pavement, with people at them.
	DELIVERY_VAN, ## Shutter up, hazards on. The plain van the others used to borrow.
	BUSKER,       ## The guitar and the open case.
	ROADWORKS,    ## Municipal barriers, repeated across what they close.
	FIRE_ENGINE,  ## The longest silhouette in the game, and the only red one.
	BURNING_BUILDING, ## Flames that scale with what it is emitting.
	BURNT_SHELL,  ## Charred brick and window holes with nothing behind them.
	LOOSE_DOG,    ## A dog running with the lead still trailing behind it.
	STALL,        ## A market trestle, repeated across the pavement it takes.
	LEAF_BLOWER,  ## A groundskeeper and the nozzle that makes the noise.
	BIRDS,        ## A flock going up all at once.
	CYCLIST,      ## A kid on a bike, leaning into it. Act I's first lethal thing.
	ICE_CREAM_VAN,
	LORRY,        ## A box lorry: the biggest silhouette in act I, and a wall.
	CHARGING_DOG, ## Stretched out flat and coming at you. The one thing running is for.
	CHATTING_MOTHER, ## Another mother with a pram, palette-shifted. Strolling, then talking.
	# ---- acts II-IV ----
	POLICE_CAR,   ## Low and pale where everything else in act II is a tall dark box.
	POSTER_CREW,  ## The poster is the event; the man holding it is scenery.
	POSTER_CREW_SQUARE, ## The same crew at a free-standing advertising column, which is what a
	                    ## square has instead of a wall. Its own look rather than a second row
	                    ## sharing `POSTER_CREW`: two rows that draw the same man are one
	                    ## milestone spent fixing the wrong one, and the column is the whole
	                    ## difference a player can see between the two.
	ROADBLOCK,    ## Poured concrete and a hazard stripe. A street being *held*.
	UNMARKED_VAN, ## No windows, no livery, a door standing open. The one with a hole in it.
	ROBBER,       ## Two postures — waiting in the hood, and coming.
	RIOT_VAN,     ## The same dark box as the unmarked van, with mesh over every window.
	ARMY_TRUCK,   ## Olive, and the only canvas back in the game.
	BARRICADE,    ## Whatever was on the street, stacked by somebody.
	PROTEST,      ## A rank of placards, as wide as the ground it takes.
	FIREFIGHT,    ## People behind cover, not a building on fire.
	# ---- seal pictures (off the day's route tree; see SealPlanner) ----
	FALLEN_TREE,  ## A trunk down kerb to kerb, roots at one end and crown at the other.
	CAR_ACCIDENT, ## Two cars locked together, glass and an onlooker on each pavement.
	SKIP,         ## A skip at the kerb. Half of a soft seal.
	SCAFFOLDING,  ## Poles and boards closing the footway. The other half of a soft seal.
	BURST_MAIN,   ## A crater, water across the asphalt, a barrier at each kerb.
	MOVING_VAN, ## A lorry at the kerb with its ramp down.
	BURNT_OUT_CAR, ## A car burnt to the shell, `BURNT_SHELL`'s charred palette at vehicle scale.
	COLLAPSED_FRONTAGE, ## A frontage spilled into the street, brick and a fallen beam.
	# ---- the region door's own structure (see RegionPlanner) ----
	CHECKPOINT_HUT,  ## The guard's hut at a region door, doorway facing the carriageway.
	CHECKPOINT_GATE, ## The boom over the roadway between a door's two huts.
	CHECKPOINT_POST, ## A single guard where a through-alley crosses a region boundary.
	# ---- the finale ----
	IMPACT_CRATER,   ## A hole in the road where an off-screen burst landed. Ground, not an object:
	                 ## the only look in the catalogue drawn flat and centred rather than standing
	                 ## on its own feet, and the only one with no shadow, because it *is* a shadow.
	MASKED_PURSUER,  ## A masked man on foot, coming. The same two postures a roadblock's guards
	                 ## take when they leave the post, on a body that was never a barrier.
	STEAM,           ## A vent letting go. Nobody is in it and it is still somewhere to wait out.
	LOUDSPEAKER_MAST, ## A pole and horns, standing on a street. `loudspeaker` and
	                  ## `curfew_announce` are two things the same mast does, not two masts — see
	                  ## `FigureLook._draw_mast()` for the lamp that says whether it is live and
	                  ## the arcs that say it is speaking right now.
	# ---- the story's own figure ----
	NEIGHBOR,         ## The neighbor down the hall, in work clothes: steel-blue coveralls with a
	                  ## reflective band and a dark work cap — the face on the wanted notice.
	# ---- the region door's own guard, off his post ----
	DOOR_GUARD,       ## The guard a door sets on her when she stays across its line — the
	                  ## same man in the same two postures as `MASKED_PURSUER` and a heated
	                  ## roadblock's guard, badged by his side view.
	# ---- the resistance's own robber, sent after her ----
	ROBBER_GIVING_CHASE, ## The man a handed-over task sets on her — the alley robber himself, only
	                     ## ever drawn coming (he never waits), badged by his side view, since
	                     ## `ROBBER`'s badge is already the front of the lunge.
	# ---- the resistance's own guard, sent after her from the van ----
	VAN_GUARD_GIVING_CHASE, ## The guard the van's task sets on her — the same man as `DOOR_GUARD`
	                        ## and `MASKED_PURSUER`, only ever drawn coming, badged by his back
	                        ## view, the one picture of him neither of theirs already stands for.
	# ---- the pursuer on foot a torn poster sends, or an investigating car lets out ----
	POLICEMAN_GIVING_CHASE, ## A policeman on foot, through day 8: a peaked cap and a baton, the
	                        ## robber's two postures one for one — waiting while his notice runs,
	                        ## lunging once he chases — badged by the lunge's own silhouette.
	GUARDSMAN_GIVING_CHASE, ## The same pursuer from day 9, once guards are in the city: the
	                        ## checkpoint guard's own drawing, standing then lunging as
	                        ## `DOOR_GUARD` is drawn, badged by the lunge's front diagonal, the
	                        ## one picture of the guard no other look already stands for.
}

## Where AMBIENT instances come from. Ambient events are features of the map, not rolls.
enum AmbientSource {
	NONE,
	PLAYGROUND,  ## One per playground.
}

## How the scheduler builds a mobile event's route.
enum PathMode {
	NONE,
	CROSS_STREET,  ## Straight across the traffic, like a cat bolting.
	ALONG_STREET,  ## Down the corridor it starts on.
	## **Across the alley it landed in**, built by the instance itself from the alley it stands in
	## (`EventInstance._alley_crossing_path()`), cut to the ground it fits on: `alley_mouse`, placed
	## on the map with no route of its own (`EventScheduler._build_placement`'s default case).
	ACROSS_ITS_ALLEY,
}

## Where an instance comes from.
enum SpawnMode {
	## Placed on a tile when the day is planned, and streamed into the world when the player
	## comes near it. Almost everything: an event that is *somewhere* is half of what makes a
	## route a decision, because it can be routed around.
	MAP,
	## Placed in front of the player, while she walks, by `EventDirector`. For the small number
	## of events whose whole content is *the moment it happens to you* — a cat bolting out of a
	## doorway is nothing at all if it does it two blocks away and you arrive at an empty road.
	## The day still budgets it: the scheduler counts one instead of placing one.
	AHEAD_OF_PLAYER,
	## Sited on her own line, ahead of her, by `EventDirector` — the same way `AHEAD_OF_PLAYER` is
	## — but travelling *down* that line toward her rather than crossing it: a bike on the pavement
	## she is walking, coming the other way. Neither of the other two answers this. `MAP` sites it
	## at dawn, before the day knows where she goes, which is a route she may never walk down; a
	## crossing `AHEAD_OF_PLAYER` row is gone in three seconds and asks her to react, not to plan.
	## This one is a road she has to answer with a route decision — cross to the other side, or
	## turn — which is why it does not stop or steer for her the way a pursuer does: it is traffic,
	## not an ambush.
	TOWARD_PLAYER,
}

@export var id := ""
@export var display_name := ""
@export var kind := GameEnums.EventKind.RECURRING
## **Whether this row draws itself as a spread** — segments or a whole scene fitted across
## `obstructs_radius`, laid along whichever axis `EventInstance._spread_is_vertical()` picks for the
## street it stands on: `SpreadLook._draw_spread` for `construction`, `burnt_shell`,
## `market_stall`, `roadblock`, `barricade`, `scaffolding` and `collapsed_frontage`,
## `RankLook._draw_cafe` for `cafe_tables`, and `SpreadLook._draw_wide_scene` for the three seal pictures
## wide enough to span the whole street (the fallen tree, the crash, the burst main), each with an
## authored east-west asset (`EventPictures.wide_scene_texture`). A protest and a firefight also fill
## `obstructs_radius`-worth of ground, but stand along their street without being a spread
## (`stands_along_its_street`), so a corner costs them nothing.
##
## **This is the test `EventScheduler._open_ground_for` asks before it will offer a corner as a
## site**: a junction has no single street for the spread's axis or
## `EventInstance._centred_on_the_pavement_band` to answer about, so only a row that asks either
## question has anything to lose by standing on one. Row data, set by each row that is one, and kept
## by every copy (`duplicate()`, `at_heat()`).
@export var has_a_spread := false

## No default worth having: it was `OBJECT` — a category, so a row that never chose was drawn as
## roadworks and looked deliberate. Every visible row states its own picture, and
## `tests/test_events.gd` names the three that are legitimately invisible.
@export var look := Look.NONE
@export var ambient_source := AmbientSource.NONE

## **Whether this row stands along its street like a spread without being drawn as one**: a protest's
## rank of placards and a firefight's cover, which fill `obstructs_radius`-worth of ground laid along
## the street they stand on. Their drawn box and their solid body's spine follow the street's axis as
## a spread's do (`EventFootprints.drawn_box_of()`, `EventFootprints.solid_axis_of()`); they never ask
## `has_a_spread`'s corner question, so a corner costs them nothing.
@export var stands_along_its_street := false

## **Whether a stationary vehicle lies across its street rather than along it**: the burnt-out car,
## left broadside across the carriageway, where the moving van stands along the kerb. Decides which
## view it shows on a street (`EventFootprints.stands_side_on()`) and so which way its body lies.
@export var lies_across_its_street := false

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

@export var warning_picture := WarningPicture.GUARD_ALERT

## **Whether it trails a slack lead behind it**: the loose dog, whose lead reaches
## `EventFootprints.LOOSE_LEAD_REACH` behind it, which everything it can put on the screen includes
## (`EventFootprints.footprint_of()`).
@export var trails_a_lead := false

## **Whether its own hold hides the whole of it**: `checkpoint_post`, one guard at an alley mouth and
## nothing else, who goes in with her (`EventFootprints.hidden_by_its_hold()`). A hut or a gate is a
## structure, drawn through its hold.
@export var hides_in_its_hold := false

## **Whether a rider on it may be drawn as the pelican** (`EventSpawner.rolls_a_pelican()`): the
## cyclist, about one in 400 drawn as a pelican on the same bike. Only the picture changes.
@export var may_be_a_pelican := false

## What the run log calls one of it and several of it, for a pursuer on foot whose line names him
## ("a policeman", "two guardsmen"): `EventsAhead`'s poster-tear and vehicle notes. Empty for any
## other row.
@export var noun := ""
@export var noun_plural := ""

## This row's own ground shape — the datum its shadow and its solid body (when it has one) are
## both derived from. A plain `var` rather than `@export`: `GroundShape` is a `RefCounted`, not a
## `Resource`, so it cannot export. `null` for every row whose `look` is `NONE` — nothing draws it,
## so nothing needs a shape — and set by every other row. See `solid()` below for the obstructing
## case, and `docs/EVENTS.md`, "Solid things are solid".
var shape: GroundShape = null

## Sets `shape` and derives `obstructs_radius` from it in the one call that keeps them from
## disagreeing: **the body is the shape, always**, so `obstructs_radius` becomes `shape.reach()`
## rather than a second number chosen to match it. Every obstructing row calls this instead of
## setting `obstructs_radius` by hand; a row with a look that does not obstruct sets `shape` alone.
func solid(new_shape: GroundShape) -> void:
	shape = new_shape
	obstructs_radius = new_shape.reach()
	# `parts()` caches a one-piece default built from `shape`; replacing the shape has to drop it,
	# or a row re-shaped after the first draw would keep colliding as the shape it used to be.
	_default_parts = []

## One solid piece of a row's body: where it sits along the scene's own spread axis, and the
## `GroundShape` it collides and casts its shadow as there.
##
## **Almost every row is one piece at the origin**, which is what `parts()` answers for anything
## that declares none, so `shape` is the body exactly as it always was. The list exists for the one
## scene whose picture leaves real ground open inside its own span: a crash is two cars with debris
## between them and an onlooker on each pavement, and a body spanning the whole street is a wall
## where the picture shows a way through. *(2026-09-12: "the bounding box should only be the crashed
## cars but it should emanate an excitement field that prevents the player from walking past it".)*
##
## **The pieces are a subset of `shape`, never more than it.** `validate()` refuses a part reaching
## past the row's own `shape.reach()`, so `obstructs_radius` stays an upper bound on every body this
## row actually puts down — which is what lets every planner go on reading that one disc without
## knowing parts exist, and makes the change monotone in the safe direction: taking obstruction away
## can only add reachable ground.
##
## **Two offsets, because a wide scene has two authored pictures.**
## `EventPictures.wide_scene_texture` picks a composition per street axis rather than rotating one,
## so where the cars sit across the street is a fact about the picture in use. `along` is read off
## the north-south asset and `along_vertical` off its `_vertical` sibling, both at the scale
## `SpreadLook._draw_wide_scene` fits the picture to the street.
class SolidPart extends RefCounted:
	## Offset along the spread axis, in px from the scene's own centre, on a north-south street.
	var along := 0.0
	## The same, off the `_vertical` picture, on an east-west street.
	var along_vertical := 0.0
	var shape: GroundShape = null

	## The offset the instance places this piece at, given its own `_spread_vertical`.
	func offset_for(vertical: bool) -> float:
		return along_vertical if vertical else along

	## The furthest this piece reaches from the scene's own centre, on the worse of the two axes —
	## what `EventDef.solid_reach()` maximises and what `validate()` holds inside `shape.reach()`.
	func reach() -> float:
		return maxf(absf(along), absf(along_vertical)) + shape.reach()

static func part(along: float, along_vertical: float, part_shape: GroundShape) -> SolidPart:
	var made := SolidPart.new()
	made.along = along
	made.along_vertical = along_vertical
	made.shape = part_shape
	return made

## The pieces this row's body is made of, in the scene's own frame. Empty on the row itself means
## **one piece at the origin**, which is every row but the crash — see `SolidPart`.
##
## A plain `var` for the same reason `shape` is one: `SolidPart` is a `RefCounted` rather than a
## `Resource`, so it cannot export, and `at_heat()`'s `duplicate()` shares the list the way it
## already shares `shape`. Neither is ever mutated in place.
var solid_parts: Array[SolidPart] = []

## `solid_parts` with the default filled in: the declared pieces, or one piece at the origin
## carrying `shape`. The one form `EventInstance` builds its bodies, its shadows and its per-tile
## record from, so a row that declares nothing cannot take a different path from one that does.
##
## The default is built once per def rather than per call: `EventLook._draw_body_shadow()` asks this
## on every `EventLook.draw()` of every visible event, and a fresh `SolidPart` and array per frame
## per entity is a cost for nothing. `shape` is never mutated in place and `solid()` drops the cache
## when it replaces one, so the cached piece cannot go stale.
func parts() -> Array[SolidPart]:
	if not solid_parts.is_empty():
		return solid_parts
	if _default_parts.is_empty():
		_default_parts = [part(0.0, 0.0, shape)] as Array[SolidPart]
	return _default_parts

var _default_parts: Array[SolidPart] = []

## The furthest any actual body of this row reaches from its own centre — `obstructs_radius` for
## every row that is one piece, and less for one that is several.
##
## **This is the "where is she stopped" reading of a body, and `obstructs_radius` is the "how much
## ground does this close" one.** The two are the same number for all but the crash, which closes a
## whole street and is solid only where its two cars are. Anything asking where her centre comes to
## rest — `validate()`'s lethal-radius check below — asks this; anything clearing or spacing ground
## asks `obstructs_radius` and stays conservative by doing so.
func solid_reach() -> float:
	# A row with a `shape` and no `obstructs_radius` draws a shadow and stops nothing — a mobile
	# one, or something with no body by design — so the reach of what she is stopped by is zero,
	# whatever its picture is wide.
	if shape == null or obstructs_radius <= 0.0:
		return 0.0
	var furthest := 0.0
	for piece in parts():
		furthest = maxf(furthest, piece.reach())
	return furthest

## Whether `EventLook._draw_body_shadow()` puts anything down for this row at all. `true` for
## every row but three. `burst_water_main`'s picture is a crater sunk into the road rather than an
## object standing on it — a shadow under a hole would read as a mound. `burning_building` and
## `burnt_shell` are drawn on the building they stand against, so nothing stands on the sidewalk to
## cast one. **The body and the collision are untouched**: this governs the shadow patch alone, the
## same way `IMPACT_CRATER` is "the only look with no shadow, because it *is* a shadow" without
## needing a body of its own to turn off.
@export var draws_body_shadow := true

## Day gating, 1-based and inclusive. `last_day = 0` means it never expires.
@export var first_day := 1
@export var last_day := 0
## For SCRIPTED events: the exact day it fires.
@export var scripted_day := 0

## Relative likelihood when filling the recurring budget, and what one costs of it.
@export var weight := 1.0
@export var cost := 1
@export var max_per_day := 1

## Tile types an instance may be placed on.
@export var placement: Array[int] = []

## Peak excitement per second at the centre.
@export var intensity := 6.0
@export var inner_radius := 40.0
@export var outer_radius := 150.0

## **A louder inner part of the same field**, for a row that has to be one thing to walk past and
## another thing to stand a street away from. Both zero means there is no core, which is every row
## but the leaf blower.
##
## `core_intensity` is the rate out to `inner_radius` and `core_radius` is where it has fallen to
## nothing, on the same curve the field itself uses — so a core is `Tuning.falloff` over the
## shorter band and `emission_at()` answers **the larger of the two**. That is what makes it add
## rather than replace: inside `core_radius` the row is as loud as the core says, and past it the
## row is its plain field with nothing about it changed, which is what lets the same row price
## walking past it as a wall and standing away from it as a hum.
##
## **A flock has no core**, and `validate()` refuses one: a flock's field is already a sum over
## bodies rather than one disc, and a second shape over the top of it would price ground neither
## the sum nor the disc describes.
@export var core_intensity := 0.0
@export var core_radius := 0.0

## **The exponent on the drop between the two radii**, so a row may shape its own falloff where its
## radii cannot say what it needs: `intensity * (1 - t ** falloff_power)`. 2.0 is the curve the
## whole catalogue is measured at — three quarters of the intensity still there at the midpoint of
## the band — a power under 1 drops fast and tails long, and a power over 2 holds near full and then
## falls off a cliff.
##
## **Nothing sets it.** It is here so that the shape of a field is a decision a row may take rather
## than a change to `Tuning.falloff` that moves all thirty of them; a row that does take it owes the
## same fairness contract, which is stated over distance and does not care.
@export var falloff_power := 2.0
## **Something outside the walls of the world she is in**, which reaches her through them: what
## lands on her from it ignores every wall between, where every other field stops at the middle of
## one (`WorldMap.wall_between()`, plaid-wombat, inbox #554), and every time it comes the world
## shows it the one way a thing outside can be seen from in there (`WorldContext.bang_outside()`: the
## building lights every window). The explosion outside the building, whose charge stands where she
## is (`EventCatalogue.explosion_outside()`).
@export var from_outside := false

## **A planned row that comes again**, on its plan's own clock (`EventManager`): seconds from one of
## its instances coming to the next coming, kept on the clock whatever the last one did. 0 for a row
## that comes once. A plan may carry its own (`EventScheduler.Planned.repeat_every`), as each of the
## basement's vents keeps its own period.
@export var repeat_every := 0.0
## Seconds from one of a planned row's instances being done — finished, or leaving the end of its
## route — to the next coming: the masked man, another of whom comes up the shaft this long after
## the last has run out of the top of it. 0 for a row that does not wait on its last one.
@export var repeat_after := 0.0

## Seconds at full strength. 0 means it lasts the whole day.
@export var duration := 0.0
## Seconds of visible warning before full intensity, during which it emits only
## TELEGRAPH_INTENSITY_FRACTION of `intensity`.
@export var telegraph_time := 2.5
## Seconds per intensity cycle, for events that pulse rather than hold. 0 is constant.
@export var pulse_period := 0.0

@export var spawn_mode := SpawnMode.MAP

## **How the row is sited and noticed from the day after its first appearance**, or null for a
## row that is the same every day — see `DaySwitch`. `charging_dog` is the one row that carries
## it. Read through `spawn_mode_on()` and `notice_on()`, never by hand.
@export var from_day_after: DaySwitch = null

## Which `SpawnMode` this row is sited in on `day`: `spawn_mode` through `from_day_after.after_day`,
## the switch's own past it. Every reader that sites an event by its day asks this.
func spawn_mode_on(day: int) -> SpawnMode:
	if from_day_after and day > from_day_after.after_day:
		return from_day_after.spawn_mode
	return spawn_mode

## How this row notices her on `day`: `notice` through `from_day_after.after_day`, the switch's own
## past it. An instance reads `notice` off the def it was handed, so a placement past the switch is
## handed a copy carrying this (`EventScheduler._for_day()`); a director-sited row keeps its own.
func notice_on(day: int) -> NoticeSpec:
	if from_day_after and day > from_day_after.after_day:
		return from_day_after.notice
	return notice

## **Where her walk sites this row**, or null for a row the dawn places — see `OnHerWay`.
@export var on_her_way: OnHerWay = null

## Seconds of notice this row gives from off screen before it can be seen — `Tuning.OFFSCREEN_NOTICE`
## (0.2) unless a row overrides it. Two readings, by how the row arrives:
##
## - **A pursuer warned of before it exists** (`charging_dog` sent at her on the day it teaches the
##   run, the resistance's own `robber_giving_chase` and `van_guard_giving_chase`): its badge, up
##   alone with nothing in the world, before it is placed just out of sight
##   (`warned_for()`). Its `telegraph_time` is then the approach she watches.
## - **A row created at once from off screen** (the patrol a torn poster or the return sends down
##   the road, `EventDirector._toward_her_on_the_road()`): seconds of closing beyond the edge of the
##   view where it is created (`Tuning.offscreen_lead()`).
##
## A non-pursuer warned of before it exists (`cyclist`, the fire engine, day 13's
## column) does not read it: its badge is its `telegraph_time` (`warned_for()`), and it is placed just
## out of sight.
##
## **`charging_dog` sets this to 0.5**, its day-3 timing: it used to be the half second it closed off
## screen under its badge, sized from playtest 20's measured chases (1.5s the shortest that ended in
## evasion, 0.8-0.9s the two that killed her) *(2026-09-07: "pursuing dog is still too short
## notice")*, and is now the half second its badge is up alone before it is placed, which M226 keeps
## rather than lengthens *(PLAYTEST-145: "the pursuit dog timing from the day 3 lesson is the correct
## timing")*. The resistance's two pursuers read the dog's own, fitted to it.
@export var offscreen_notice := Tuning.OFFSCREEN_NOTICE

## Whether this row, whatever its `spawn_mode`, only ever enters the world under a warning that runs
## before it exists (`EventManager.warn_first()`): the fire engine, which the fire summons, the
## resistance's own `robber_giving_chase` and `van_guard_giving_chase`, and the copies
## `as_warned_first()` makes of a row that is otherwise placed some other way — day 13's column of
## `military_convoy`, and `charging_dog` sent at her down her heading — which
## `EventSpawner.as_warned()` makes of any row that comes through a warning first. Read by
## `warns_before_it_exists()`, and so by the fairness contract, which holds such a row to the flat
## `Tuning.OFFSCREEN_WARNING_MIN` rather than to a floor worked out from its field and speed, and its
## badge alone to `Tuning.WARNING_ALONE_MAX`.
@export var warned_first := false

## Whether this row telegraphs its coming. *(PLAYTEST-145: "telegraphing is for things that go fast
## *and* are dangerous" · "go fast and towards the player" · "loose dog, cat don't need
## telegraphing"; inbox #598: "the telegraphing rule was about heavy penalty not *only* lethal".)* A
## thing telegraphs only if it goes fast, comes toward her, and carries a heavy penalty — it can end
## the day or hit her hard. **One that does not is outside the screen-edge badge and warning-first
## placement, rather than exempted from them**: nothing announces its coming before she can see it,
## and it is met as it comes. False on `loose_dog` and `cat_dash` (the player's own), `alley_mouse`
## (across its alley, not at her), `pigeon_flock` (goes up where she walks in) and `police_patrol`
## (slower than a walk; it ends the day only as a car does, warned as a car is — see `vehicle`). **The telegraph contract still holds its in-world
## telegraph** — the cat's crouch, the mouse's and the flock's wait, the patrol's approach — as it
## holds a standing row's (a lorry backing in, a firefight, a raid). Only the loose dog, met with its
## telegraph already spent, has none for the contract to hold (`validate()`).
@export var telegraphs := true

## Moves along a path at `speed` px/s. The scheduler builds the path.
@export var mobile := false
@export var speed := 0.0
@export var path_mode := PathMode.NONE
## Route length for ALONG_STREET, in tiles.
@export var path_length_tiles := 24

## Walks its route and turns round at the ends, for ever.
##
## The difference between a **journey** and a **beat**, and it is the difference between two kinds
## of event. A dog walker is going somewhere: its route is thirty tiles, it is gone at the end of
## them, and what it costs you is the stretch of pavement it happens to own while you are there. A
## man shouting is not going anywhere — he is *at* a place — and without this the only way to say
## so is to make him stationary, which reads from the street as "it didn't move".
##
## A paced event never reaches the end of its path, so it never departs and never expires: it is a
## fixture that moves, which is exactly what it looks like from the street.
@export var paces := false
## Holds still until the telegraph is over, then goes.
##
## The default is to move from the first frame, which is right for anything whose telegraph is
## *the approach*: a fire engine is warning you by being audible three streets away, and it has
## to cover those three streets to arrive.
##
## It is wrong for anything whose telegraph is a *posture*. The cat crouches and then bolts,
## and a crouch that is already travelling at 240px/s is not a crouch. Worse, it makes the cat
## silent: its path is one street wide, so at full speed the whole run is over by the time the
## telegraph ends — it never reaches full intensity, and the running sprite never draws once.
@export var still_while_telegraphing := false

## How fast it removes itself from the scene when it is over, in px/s.
##
## **Nothing vanishes while you are looking at it.** Ending an event by deleting it where it stands
## puts the deletion directly in front of her for the two shortest-lived rows in the game — a dog
## that should at least run offscreen first, and a flock that hangs in the air for a fifth of a
## second and is then not there, which is most of what makes pigeons read as ineffective.
##
## Anything **mobile** already has somewhere to go and leaves at its own `speed`, which costs no
## data. This field is for the rest: a flock that has to fly off, a dog that has lost interest and
## trots away. Zero means it simply ends, which is right for anything that was a *place* rather
## than a moment — a café does not walk home.
@export var departs_at := 0.0

## How many individual creatures this event is, rather than one thing drawn several times.
## 0 for everything that is one body.
##
## **A flock may not be one sprite drawn seven times at fixed offsets.** Deriving the offsets from
## the instance's own position keeps them from boiling, which is the right trick for a *static*
## picture and the wrong one for a moving one: the seven birds can then only ever move together,
## and the animation collapses to a single `rise` term that ramps at the end of the telegraph and
## sits there — the flock goes up in one movement and hangs motionless for the three seconds that
## are supposed to be the event.
##
## With this set, `EventInstance` gives every bird its own position, its own heading, its own speed,
## its own height and its own wingbeat, and steps them one at a time. There is nothing generic about
## the field — it is the number of bodies — and nothing else in the catalogue wants it yet. It is a
## field rather than a script per event for the reason the whole of `EventDef` is: a flock differs
## from a bird by a number.
@export var flock_size := 0
## How far from the middle a flock spreads, in px. Its `outer_radius` is the field it emits over;
## this is the ground it stands on and the air it wheels in, and it is deliberately much smaller —
## a flock she can see the shape of is a flock she can walk round.
@export var flock_spread := 0.0

## What it leaves at, which is its own speed if it had one. See `EventInstance._be_done`.
func departure_speed() -> float:
	if departs_at > 0.0:
		return departs_at
	return speed if mobile else 0.0

## **How it comes after her**, or null for a row that does not pursue — see `PursuitSpec`.
##
## Pursuit is the mechanic that makes running ever the right move: running costs more than walking
## against everything that merely emits, so the only way it can be right is if the alternative is
## losing the day. A pursuer is lethal, faster than a walk and slower than a run, so walking away
## does not work and running does. One kind is a cost rather than the end of the day: the man an
## investigating patrol car lets out, whose catch is a stop (`PursuitSpec.stop_excitement`).
@export var pursuit: PursuitSpec = null

## **How it notices her**, or null for a row with no wait — see `NoticeSpec`. A row with none is a
## moment from the frame it exists (`charging_dog` sited ahead of her on the day it teaches the
## run); a row with one is a place that becomes a moment when she walks up to it, which is a
## different thing from both an obstacle and an ambush. Read off the def an instance was handed:
## a row whose notice changes by day says so with `from_day_after` (`notice_on()`).
@export var notice: NoticeSpec = null

## **How this row hunts her once the resistance has heated it** (`HuntSpec`): a vehicle that lets
## men out, or a man who pursues her himself. Authored on the cold row of every `PRESSES` and `HUNTS`
## row; `at_heat()` attaches it to the copy (`hunting`) at and past its rung's threshold. Null for a
## row that answers to nothing.
@export var hunts: HuntSpec = null

## **The hunting behaviour this copy carries**: the row's `hunts`, attached by `at_heat()` at and past
## its rung's threshold, or null — on every cold row, and on a heated copy below its threshold.
@export var hunting: HuntSpec = null

## Whether this copy is a vehicle that stops for her and lets men out (`hunting` with
## `HuntSpec.lets_out`), which `EventInvestigation` runs.
##
## **A vehicle that investigates: once it notices her it stops and lets men out on foot, who pursue
## her; the vehicle itself never chases.** *(merry-stork, the player: "an investigating police car
## should not leave the street. it should stop if close to her and a policeman should emerge and
## pursue her"; inbox #669 in coral-lark, on the night raid's van: "Van stops, men get out (Recommended)", and on
## the unmarked van: "Same as the police".)* Heated copies carry it, each made by `at_heat()`, with
## a `notice` it notices her within — along a clear line, as every notice is
## (`EventInvestigation`):
##
## - **`police_patrol`'s heated copy past `Tuning.HEAT_INVESTIGATES_LEVEL`**, a car that drives: it
##   drives its route until it notices her, and stops on its route at once — **never inside a
##   junction box**: noticed with its body in one, it drives on until the body is clear of it and
##   stops there, since nothing stands in a box it cannot leave (sunny-finch). It lets one man out;
##   once he is back in, the car drives on along its route as a patrol does, and the end of its
##   route is where it leaves. Its man's catch costs her and never ends the day by itself
##   (`PursuitSpec.stop_excitement`).
## - **`night_raid`'s and `abduction`'s hunting copies**, vans that stand at the kerb: they stop
##   nowhere, since they never move, and let two men out, whose catch ends the day; men who give up
##   walk back, and the van stands where it stood, as its cold row does. No vehicle chases her like a
##   running man (azure-koala, finding 7: "police cars chasing the player behave like running
##   people"; inbox #664: "I was chased by police cars still which is just silly"); the van keeps
##   whatever `hard_fail` it has cold.
##
## **It is not a pursuer**, so `validate()` refuses the two together: the vehicle stands, as a car
## stands for her, while its men — `EventCatalogue.out_of_the_car()`, a policeman through day 8 and
## a guardsman from day 9, put down at its door on her side by `EventManager` — pursue her under the
## pursuit contract, and walk back to it when they are done. While a car stands for them it is not
## driving, so it neither warns nor strikes.
func investigates() -> bool:
	return hunting != null and hunting.lets_out > 0

## How many men this copy lets out once it stops for her (`HuntSpec.lets_out`), or 0.
func lets_out() -> int:
	return hunting.lets_out if hunting else 0

## Its notice radius, or 0 for a row with no wait: the number every "how close before it notices"
## rule reads.
func notice_within() -> float:
	return notice.within if notice else 0.0

## Its chase speed, or 0 for a row that does not pursue.
func chase_speed() -> float:
	return pursuit.speed if pursuit else 0.0

## Whether its pursuer, cold or hunting, leaves its body standing when he sets off
## (`PursuitSpec.leaves_its_body`): the roadblock's, whose cold row carries it on its hunt.
func leaves_its_body() -> bool:
	var chase := pursuit
	if chase == null and hunts != null:
		chase = hunts.pursuit
	return chase != null and chase.leaves_its_body

## Whether it pursues with a chase that begins in `start`'s way.
func starts_by(start: PursuitSpec.Start) -> bool:
	return pursuit != null and pursuit.start == start

## How this row answers to the resistance.
##
## **The city gets worse the further into the subquest you are**, and this is the whole of how a row
## says so. `RunState.resistance.progress` is an integer 0..`Tuning.RESISTANCE_GOAL`, and
## `at_heat()` below turns a level into a **derived copy** of the row with its numbers moved — so
## nothing downstream of the day's plan has to know that heat exists at all. An `EventInstance`
## holds whichever copy the day handed it and reads `intensity`, `pursuit` and the rest exactly as
## it always has.
##
## **It is a field rather than a switch somebody sets per placement**, which is the same rule the
## blocking role follows: `EventScheduler._role_for` derives a role from the def, so no two
## placements of one row can disagree about what it is. Heat that could be set by hand would be a
## difficulty dial hidden inside the placement code.
##
## **And the set of shapes is finite on purpose.** Progress is an integer with a known ceiling, so
## every heated shape of every row exists at boot and `EventCatalogue.all()` validates all of them.
## A def that *mutated* mid-run would be checked by `validate()` in the shape it booted in — the
## harmless one — and the fairness contract would simply not be stated about the dangerous one.
enum HeatResponse {
	## Answers to nothing. Everything in act I, and the default: a cat does not care who you know.
	NONE,
	## **More of them, and more expensive to stand near, and past a threshold it investigates**
	## (its `hunts`: it stops near her and a man on foot gets out and pursues her).
	## The rung that does not hunt: it never gains `hard_fail`, whatever the heat, and the man it
	## lets out costs her when he reaches her rather than ending the day (`PursuitSpec.stop_excitement`). (The
	## patrol that carries it strikes as a car does at every heat — `vehicle` — which is not a rung.)
	PRESSES,
	## **It stops being a place and starts being a hunter.** The lethal rung: `roadblock`'s guard
	## hunts her himself, and the two vans on it — `abduction` and `night_raid` — hunt on foot
	## (their `hunts` let men out), whose catch ends the day.
	HUNTS,
}

@export var heat_response := HeatResponse.NONE

## Radius of solid obstruction, in px. 0 for events you can walk through. Scaffolding does
## not politely step aside, and being *forced* to reroute is a different pressure from
## choosing to.
##
## **This is `shape.reach()`, not a second number chosen to match it.** The body is `shape` — a
## `GroundShape`, the same datum the shadow is drawn from — and this field is what every planner
## still reads: the disc bound the reachability and sealing guarantees are stated over, which holds
## for a capsule shape too, since every point of a capsule of a given reach lies inside the disc of
## the same reach. `solid(shape)` sets both together; `validate()` refuses the two disagreeing.
##
## **It is the ground this row closes, which is not always the ground it is solid on.** A row
## carrying `solid_parts` puts its bodies down inside this disc and leaves the rest of it open —
## the crash, whose picture is two cars with gaps between and beside them — so *has a body* and
## *closes ground* have come apart for exactly one row and `solid_reach()` is the first of the two.
## Every planner here reads this one: they clear, space and refuse ground, and an upper bound is the
## conservative answer for all three.
##
## **Anything that stands still is solid at the width it is drawn.** It is a rule rather than a
## list, because the moment it is a list a delivery van is scenery and a man standing in a courtyard
## can be walked through. And the number is not a balance value: it is half of the silhouette,
## because `SpreadLook._draw_spread` draws a blocking object at exactly the width it obstructs, and
## anything else is a lie about where she can walk.
##
## Four things are exempt and each for its own reason:
##
## - **Anything mobile.** A moving wall on a two-tile pavement pins her against a building, which
##   is a different game from being priced out of a street. See `dog_walker`, where the decision
##   is written up at length.
## - **`AHEAD_OF_PLAYER`**, which `validate()` refuses outright: nothing checks that a thing sited
##   out of where she happens to be walking leaves a route to a park.
## - **Anything with no silhouette** — a city-wide source, a playground the park already draws.
## - **A flock**, which `validate()` also refuses outright. `flock_size` bodies wheeling inside
##   `flock_spread` have no one silhouette to be half of — each bird is an 18px picture with
##   pavement between it and the next — and walking into them is the whole event: a body would
##   stop her at the rim and delete the thing it was drawn from. `solid_parts` is how a row with
##   several bodies declares them, and a flock's are neither still nor in one place.
##
## And one constraint rather than an exemption, which is `validate()`'s job below: a `hard_fail`
## event's body has to fit *inside* its lethal radius with her own body to spare.
@export var obstructs_radius := 0.0

## **When the row's body is solid to her.** Almost every body is a place, solid from its first frame
## for the whole of its life; two rows are solid only part of the time, and a row is one or the
## other, never both.
enum SolidWhen {
	## From the instance's first frame: every body but the two below.
	ALWAYS,
	## **The body arrives when the notice ends rather than with the instance.**
	##
	## **For a row that turns on where she is already standing.** Every other solid row is a *place*:
	## it is on its tile before she gets near it, so a body from the first frame is the honest picture
	## and she can never be inside one. A vent on a timer is the opposite — the ground it closes is
	## ground she may be walking down at the moment it fires — and a body that appears around her is
	## not something a telegraph can be an answer to, however long the telegraph is.
	##
	## So the notice runs with no body at all and the body goes down at the end of it, and
	## `EventInstance` withholds it for as long as she is still inside the footprint: **a vent never
	## turns on with her in it.** That is a precondition rather than a repair — nothing is placed and
	## then moved — and it fails in the safe direction, since withholding obstruction can only leave
	## more ground reachable. It costs her the full field meanwhile, so standing in a vent to keep it
	## open is the most expensive way through it rather than a way past it.
	##
	## **A planner's own record does not know about this**, and cannot: `EventManager` rasterises a
	## row's body into `CityMap.obstructed_tiles` from the *plan*, before any instance exists, so a
	## row solid this way reads as solid to the crowd and to route-clearing for the whole of its
	## life. Set it on something placed where there is no lattice to clear, or accept that the ground
	## is reserved the whole time.
	ONCE_IT_STARTS,
	## **A boom** — a bar across a door's carriageway that the cars raise and lower
	## (`Crowd._stop_for_gates()`, through the `RegionPlanner.GateState` its instance carries), and
	## that is solid to her **only while it is down**. `checkpoint_gate` is the one row that sets it.
	##
	## *(2026-09-24, the player: "Boom shouldn't inspect her. It should block her." · "I didn't say it
	## should stay solid when it's open".)* So it never detains: a lowered boom is a wall across the
	## road and a raised one is ground she may walk under, at the price of the car that raised it and of
	## the guard a walked crossing sets on her (`CheckpointController._set_a_guard_on_her()`). The
	## inspection is the huts' alone, and a hut never takes her in from the carriageway its own door's
	## boom spans — that ground is the boom's.
	##
	## Read in three more places, each because a boom is a door body that does not detain:
	## `EventSpawner.obstructed_footprint()` keeps it out of the crowd's per-tile record the way it
	## keeps the huts out (the cars' answer to it is the gate hold), `EventDirector` keeps the door's
	## clear ground around it, and `EventInstance` lets its collision body follow the arm.
	WHILE_LOWERED,
}

@export var solid_when := SolidWhen.ALWAYS

## **A car that drives**, or null for anything else — see `VehicleSpec`: `police_patrol` and every
## copy of it, and `fire_truck`.
@export var vehicle: VehicleSpec = null

## Which lane of a two-tile pavement an event wants.
##
## Almost nothing cares, and `ANY` is the honest default: a café spills out of whichever frontage
## it has and a shouting man stands where he likes. Two things do care, and in both cases the lane
## is what makes sense of the thing — a parked van belongs at the kerb rather than *in a traffic
## lane*, and a lorry reversing into a yard has to be backing into a building.
enum Pavement {
	ANY,
	## Against the kerb, with the carriageway on the other side of it. Where a vehicle parks.
	AT_THE_KERB,
	## Against the frontage, with a building wall behind it. Where a lorry backs in.
	AGAINST_THE_BUILDING,
	## The frontage lane of an east-west street's north sidewalk, in front of the south face of the
	## lot behind it — the one face of a building the city draws. Where a fire catches, so the
	## building it burns is the one drawn burnt afterwards (`burning_building`'s own
	## `pavement_side`), and where a poster crew pastes (`EventScheduler.WalkSiting` asks it for a
	## row whose `OnHerWay.at_a_front` is set).
	AT_THE_FRONT,
}

@export var pavement_side := Pavement.ANY

## Whether this row **stops where its route ends and stays there for the rest of the day**, instead
## of driving on out of sight the way everything else that runs out of route does.
##
## The fire engine is the only row that carries it, and the flag says what it means rather than
## borrowing a mechanism that means something else: an `aftermath.on_finish` would also keep it where it
## arrived, by finishing it and leaving a successor behind, but what it leaves would be a second row
## standing in for the first and nothing about that arrangement says *parks*.
##
## **It is a decision about cost, not about motion.** *(2026-09-20, the player, asked whether the
## engine parks at the fire for the rest of the day, for twenty seconds, or passes through: "option
## A -- a fire engine has a high cost"; "you're not supposed to go past it".)* A standing 26/s field
## out to 340px beside a fire she was led to is the wall the day puts across the street she is on,
## and the answer it asks for is to turn round or go another way. The pair is why a site is only
## accepted where the home and a calm area she has not used stay reachable outside both fields —
## see `EventScheduler.WalkSiting`.
##
## Three things in `EventInstance` read it and all three would be wrong left alone: `_be_done()`
## neither finishes nor leaves such a row, `EventRouteWalk.advance()` stops adding to the distance it
## has covered (a gait is driven by distance, so a parked engine would bob for ever), and
## `travel_velocity()` answers zero (the screen-edge badge reads that as a closing speed, and a
## parked thing is not closing).
@export var stops_where_it_arrives := false

## Seconds the player's movement input is locked for, on first contact within `detain_distance()`.
## `0.0` means never — the default, and true of every row but `chatting_mother`.
##
## **The one mechanic in the catalogue that takes the controls away rather than costing a meter.**
## Everything else that stops her is a choice — walk into it or do not — and this is the exception,
## which is why `validate()` refuses it on anything `hard_fail` or with a `pursuit`: a thing
## that can also kill her or chase her has no business also deciding she cannot move. See
## `Stroller.detain()` for the lock itself, which runs out through the ordinary friction rather
## than stopping her dead.
@export var detain_seconds := 0.0
## How close she has to come **to this row's own solid edge** before a conversation starts, in px.
## `detain_distance()` is the same reach as a distance between centres, which is the form every
## caller actually wants.
##
## **Stated over the body rather than over her**, and that is the whole of why it is a reach past
## `obstructs_radius` rather than a radius from the middle. A radius from the middle has to be
## bigger than whatever she pushes in front of her, so it silently switches the mechanic off the
## day that changes: *(PLAYTEST-57: "the checkpoint should activate when I get close. with the new
## stroller hitbox I cannot reach the checkpoint entrance".)* Her centre stops
## `obstructs_radius + PLAYER_BODY_RADIUS` from a body, or further with the pram between her and
## it, and a reach measured from the edge is the same reach whichever of those it is.
##
## Checked by `validate()` against `inner_radius`, over `detain_distance()`: the capture has to
## sit strictly inside the field she is already fully charged for, so "she is captured" and "she
## is outside the ambient field" can never both be true of the same instant. `chatting_mother`
## carries no body at all — nothing mobile may — so her 48px is a radius from her centre either
## way, and it is chosen against the **32px** spacing between the two lanes of a pavement
## (`Tuning.TILE_SIZE`, since a lane sits on its tile centre): under that, the far lane of a
## two-tile pavement is never inside it, whatever `paces` does, and distance stays the counterplay
## it is everywhere else in the catalogue.
@export var detain_radius := 0.0

## How close her own centre has to come to this instance's centre for the conversation to start —
## `detain_radius` past the solid edge she cannot walk through. The one form
## `CheckpointController.check_detentions()` and `CheckpointController.release_finished_holds()`
## both measure, so the trigger and the distance the release has to clear can never be derived
## differently.
func detain_distance() -> float:
	return obstructs_radius + detain_radius

## Whether an instance is armed again once she has been released and has moved outside
## `detain_distance()`, rather than spent for good after its first conversation like
## `chatting_mother`.
## `false` is the default and is right for almost every detainer: a toll booth she can pass again
## either way, which is the checkpoint's whole point, needs the opposite — *"it works in both
## directions with the same cost each time"* — so `checkpoint_hut` and `checkpoint_post` are the
## only two rows that set it. `CheckpointController.check_detentions()` is what reads it.
@export var redetains := false

## Whether this row is one of the region boundary's own structures — a street being held, however
## many bodies it takes to hold it. **Several of them charge the meter as one source, the strongest
## at her position, never their sum.** *(2026-09-20, the player: "since two gates can be adjacent
## to each other their influence shouldn't add up" · "otherwise going into a hut at a corner with
## two huts double counts the influence".)*
##
## Four rows carry it and they are the whole boundary kit: `checkpoint_hut`, `checkpoint_gate` and
## `checkpoint_post` — a door — and `roadblock`, which is both the body the region *wall* stands as
## and the catalogue's own street closure. A wall is three bodies a tile apart across one street
## and a door is three more; at a corner where the two meet, ground inside five of them at once
## exists, and summed that is one barrier read five times.
##
## **It is a flag rather than a list of ids** so the rule is a property of the row and not a table
## somewhere else that a renamed or added row silently falls out of — `RegionPlanner` already
## carries one id as a string and says in the same breath that whoever renames it updates that
## string too, which is the shape this avoids.
##
## **The maximum is taken over every flagged instance at once, not per cluster.** There is no
## grouping to get wrong and nothing to tune: two barriers far enough apart not to overlap already
## contribute nothing to each other's ground, so the answer only differs from the sum exactly where
## the player said it should. `EventManager.excitement_sources_at()` is the one place that does it,
## and the halo, the caret and the meter all read that same answer — see
## `EventInstance.outranked_by_a_stronger_barrier`.
@export var barrier_structure := false

## Entering the lethal radius ends the day immediately.
@export var hard_fail := false

## How close a row with no pursuit has to come to end the day when that is not its field's own
## core, in px, or 0 for its `inner_radius`: the masked man on the escape's stairs catches inside
## the core his field shares with the roadblock's guard. `lethal_reach()` reads it.
@export var catch_reach := 0.0

## **The distance that ends the day**: a pursuer's `PursuitSpec.catch_reach` where it sets one (a
## roadblock's guard catches at a man's reach, not at his band's core), the row's own `catch_reach`
## where it sets one, the field's own core otherwise. Every caller asks this, so none has to know
## which kind of row it holds.
func lethal_reach() -> float:
	if pursuit and pursuit.catch_reach > 0.0:
		return pursuit.catch_reach
	if catch_reach > 0.0:
		return catch_reach
	return inner_radius

## What `Tuning.pursuit_standoff()` is stated over for this row: its `PursuitSpec.lunge_reach`
## where it sets one, the catch (`lethal_reach()`) otherwise.
func standoff_reach() -> float:
	if pursuit and pursuit.lunge_reach > 0.0:
		return pursuit.lunge_reach
	return lethal_reach()

## Whether its lunge is measured from inside its own catch, which would leave her less than
## `Tuning.PURSUIT_REACTION` of the pursuer's approach between its lunge and the moment it takes
## her: the contract `Tuning.pursuit_standoff()` keeps. `validate()` refuses it; a predicate so
## a test can ask without raising the error.
func lunge_is_inside_the_catch() -> bool:
	return pursuit != null and pursuit.lunge_reach > 0.0 and pursuit.lunge_reach < lethal_reach()

## Which side or sides of a `Look.ROADBLOCK` band `RoadblockLook._draw_roadblock()` posts a standing
## guard on — `-1`/`+1` in `guard_post_offset()`'s own reading of `side`, the same sign
## `_guard_side_toward()` and `EventBarrierPost.chaser_side()` use. `[-1, 1]` (both) is every row's
## own default: the catalogue `roadblock` and every wall body inherit it unless something here
## overrides it.
##
## **Two overrides today, both the region wall's own.** *(2026-09-25, PLAYTEST-135, statement 8:
## "maybe four? one on each sidewalk. would that cover everything?")* A wall crossing stands three
## bodies — sidewalk, road, sidewalk — and posting a guard on both sides of all three would draw
## six; `SealPlanner.place_hard_on()` duplicates the middle one with `guard_sides` emptied, so the
## tarmac between the two sidewalks draws none while both sidewalk bodies keep the default pair.
## *(Same day, on a walled alley's own two mouths: "one guard in alleys on each end.")* Each mouth
## drew two, one of them standing inside an alley walled at both ends where she can never reach —
## `RegionPlanner._alley_mouth_wall_body()` sets this to the one-element array naming the mouth's
## own street-facing side (`_alley_mouth_street_side()`) instead.
##
## **Carried on the def, set on the placement, read only at draw time.** Nothing here decides
## *which* side is which — an empty array draws nothing at all regardless — so both overrides above
## are a value set on a fresh duplicate at placement, with no change to
## `RoadblockLook._draw_roadblock()` itself.
@export var guard_sides: Array[int] = [-1, 1]

## **A part one row plays in a system beside the catalogue**, which that system finds it by rather
## than by its id: a renamed or derived row keeps its role.
enum Role {
	NONE,
	## Exempt from the cost rule's wall and friction placement — `EventScheduler._role_for` answers
	## `NONE` for it before the cost check ever runs, so `_copies_of` neither pulls it off the
	## corridor nor weights it onto one: it lands on whatever tile the roll picks, the way an
	## ambient event or a scar does. `pigeon_flock` is the row it exists for — *"flocks are basically
	## free already — don't count it as block, just count is scenery"* — because a 42-over-168px
	## field crosses `Tuning.WALL_WORTH_OF_COST` and would otherwise be pulled off every route like
	## any other expensive row.
	SCENERY,
	## **The loudspeaker mast**, which the masts' sites (`MastSites`), the day's masts and the
	## resistance's mast task find by this role (`EventCatalogue.mast()`). The curfew announcement
	## shares a mast's foot and is not one.
	MAST,
}

@export var role := Role.NONE

## **It takes a bystander first**, or null for a row that takes nobody — see `AbductionSpec`:
## `abduction`, the unmarked van.
@export var abduction: AbductionSpec = null

## The name its charges are counted under when it is not its own id (`EventInstance.
## charger_name()`): `task_guard` for the task guard sent from out of her view, whose charges are
## the task guard's. `""` for every other row.
@export var counts_charges_as := ""

## Intensity multiplier reached at the end of `duration`. 1.0 holds steady; above 1.0
## swells (a protest gathering), below 1.0 fades.
@export var intensity_ramp := 1.0

## **The rows this one brings after it** — see `Aftermath`; empty for a row that brings none.
@export var aftermath := Aftermath.new()

## Which act the row belongs to, narratively. No game code reads it — `first_day` is what
## actually decides when a row can appear — but `tests/test_acts.gd` asserts every row's
## `act_tag` against the act its `first_day` falls in, so it stays consistent with the
## calendar even though nothing at runtime depends on it. It is where a per-act palette or a
## per-act sound would key off.
@export var act_tag := 1

## What this row does to a route that meets it, in the words `docs/CITY.md` fixes.
##
## **No row in the catalogue is `IMPASSABLE`**, and that is a statement about the vocabulary rather
## than a gap in it: impassable means *stops passage without killing*, which in this game is a
## closure taking a whole street. An event with a body takes part of a pavement, so it is walked
## round at a price — `costly`, like the dog walker with no body beside it. It would be easy to
## read `obstructs_radius > 0.0` as impassable and it is the same mistake the **events** skill
## warns about on the other side: if a rule tests `obstructs_radius > 0`, ask whether it means
## *has a body* or *closes ground*.
func effect() -> GameEnums.BlockerEffect:
	return GameEnums.BlockerEffect.LETHAL if hard_fail else GameEnums.BlockerEffect.COSTLY

## This row as it is at a given resistance level, which is `self` for almost everything.
##
## `level` is `RunState.resistance.progress`, clamped here rather than by the caller — it can reach
## five over the five tasks while `Tuning.RESISTANCE_GOAL` is the four that qualify, and full heat is
## the qualification rather than the last errand.
##
## **A derived copy, never a mutation.** The catalogue's own rows are shared by every day of the run
## and validated once at boot; a row that changed shape underneath them would be a fairness contract
## checked about a thing that no longer exists. `EventCatalogue.at_heat()` caches these, so a level
## costs one duplicate per row per run rather than one per placement.
func at_heat(level: int) -> EventDef:
	if heat_response == HeatResponse.NONE or level <= 0:
		return self
	var through := clampf(float(level) / float(Tuning.RESISTANCE_GOAL), 0.0, 1.0)
	var hot := duplicate() as EventDef
	# `Resource.duplicate()` only copies properties with storage usage, and a plain `var` typed as
	# a `RefCounted` (not a `Resource`) does not get that usage — it cannot round-trip through a
	# `.tres`, so Godot excludes it. `shape` is never mutated in place, so sharing the reference
	# with the original is exactly as safe as `duplicate()`'s own shallow copy of anything else.
	# `solid_parts` is the same kind of field and needs the same hand — a heated row that lost its
	# parts would quietly go back to one body spanning its whole shape.
	hot.shape = shape
	hot.solid_parts = solid_parts
	var hunts_from := Tuning.HEAT_HUNTS_LEVEL
	var notices_within := Tuning.HEAT_HUNTS_WITHIN
	if heat_response == HeatResponse.PRESSES:
		# More of them, and more expensive to be near. Population is the axis that changes the
		# *route* — this row's whole design is that you start planning around it — and intensity
		# is what makes one of them worth planning around in the first place. Below its own
		# threshold a `HUNTS` row is untouched: population and intensity are this rung's axes, and
		# that rung answers a different question — not *how much does it cost to be near*, but *can
		# I still be near it at all*.
		hot.max_per_day = maxi(max_per_day,
				roundi(max_per_day * lerpf(1.0, Tuning.HEAT_PRESSES_POPULATION, through)))
		hot.intensity = intensity * lerpf(1.0, Tuning.HEAT_PRESSES_INTENSITY, through)
		hunts_from = Tuning.HEAT_INVESTIGATES_LEVEL
		notices_within = Tuning.HEAT_INVESTIGATE_WITHIN
	if hunts == null or level < hunts_from:
		return hot
	# **At its rung's threshold the copy takes the row's hunt** (`hunts`, `HuntSpec`) and notices her
	# at the rung's own distance: a vehicle stops on its road, or stands where it is, and lets its men
	# out (`investigates()`), keeping its cold row's `hard_fail` — a patrol car kills only as a car
	# does, in front of it while it drives its route (`vehicle`), and a van as it did cold; or a man
	# pursues her himself.
	hot.hunting = hunts
	hot.notice = NoticeSpec.at(notices_within)
	if hunts.pursuit != null:
		# He hunts as the row says, at the ladder's own speed.
		hot.pursuit = hunts.pursuit.duplicate() as PursuitSpec
		hot.pursuit.speed = Tuning.HEAT_HUNTS_SPEED
		# The shared trigger is authored once, against the widest cold field in the catalogue
		# (`abduction`'s 250px) — a row whose own `outer_radius` sits under it would notice her from
		# outside its own field, which `Tuning.validate_pursuit()` refuses. Widening only the
		# hunting copy holds the contract for every hunt that pursues without asking a row's author
		# to pad its cold field past a constant that belongs to the ladder rather than to the row;
		# the cold shape, and everything measured from it (`required_telegraph_time()`, the cost
		# table), is untouched.
		hot.outer_radius = maxf(outer_radius, notices_within)
		# For a pursuer `duration` is the length of the chase, not the length of the idle — see
		# `notice` above. Cold, this row simply sits for `duration` seconds and is done.
		hot.duration = Tuning.PURSUIT_TIME
	# A hunt whose own catch ends the day says so (`HuntSpec.ends_the_day`, the roadblock's guard):
	# a pursuer is exempt from the rule that nothing else happens inside a lethal event's field
	# (`EventScheduler._keeps_its_field_clear`), so the copy is lethal rather than losing it to stay
	# inside that rule.
	if hunts.ends_the_day:
		hot.hard_fail = true
	return hot

func available_on(day: int) -> bool:
	if kind == GameEnums.EventKind.SCRIPTED:
		return scripted_day == day
	if day < first_day:
		return false
	return last_day == 0 or day <= last_day

## Checks the telegraph fairness contract from docs/EVENTS.md.
##
## AMBIENT events are exempt, and have to be: they are permanent features of a fixed map,
## so there is no moment they appear and nothing to warn about. The player learns where the
## playgrounds are on day 1 and that knowledge holds for the rest of the run — which is the
## whole point of a city that does not change.
func validate() -> bool:
	# **A row that comes again comes from a plan**: a repeat is kept on its plan's clock, and only a
	# `MAP` row has a plan to keep it on.
	if repeat_every < 0.0 or repeat_after < 0.0:
		push_error("event '%s' repeats after a negative wait" % id)
		return false
	if (repeat_every > 0.0 or repeat_after > 0.0) and spawn_mode != SpawnMode.MAP:
		push_error("event '%s' repeats but is not MAP-sited: only a plan can bring it again" % id)
		return false
	# **The body is the shape, always.** A row that draws something has a shape to draw it from,
	# and a row whose shape claims a reach has to claim the same one `obstructs_radius` does — the
	# two are one datum read two ways, not two numbers that happen to agree today.
	if look != Look.NONE and shape == null:
		push_error("event '%s' has a look but no shape to draw its shadow and body from" % id)
		return false
	if obstructs_radius > 0.0 and (shape == null or not is_equal_approx(shape.reach(), obstructs_radius)):
		push_error(("event '%s' obstructs %.1fpx but its shape reaches %.1fpx: the body and the "
				% [id, obstructs_radius, shape.reach() if shape else -1.0])
				+ "picture would disagree about where she can walk")
		return false
	# **A row solid in parts is solid inside its own shape and nowhere else.** Every planner reads
	# `obstructs_radius` — the disc bound — and none of them knows a part list exists, so a piece
	# reaching past it would be ground nothing ever cleared. Held the other way round it is the one
	# direction that is always safe: pieces inside the shape can only ever *remove* obstruction from
	# what the planners already allowed for, and removing obstruction can only add reachable ground.
	for piece in solid_parts:
		if piece.shape == null:
			push_error("event '%s' has a solid part with no shape" % id)
			return false
		if piece.reach() > obstructs_radius + 0.001:
			push_error(("event '%s' has a solid part reaching %.1fpx, past the %.1fpx its own shape "
					% [id, piece.reach(), obstructs_radius])
					+ "claims: nothing cleared the ground it would stand on")
			return false
	# **A core is two numbers that only mean anything together**, and each way of half-setting them
	# is a row that reads as having a core and has not got one: a rate with nowhere to fall to, a
	# band with nothing in it, a core no louder than the field it is drawn over, or one reaching
	# past the field's own edge — which would put the row's loudest ground outside the radius every
	# fairness rule is stated over. Checked before the ambient and city-wide returns below, since
	# those rows have a field too.
	if falloff_power <= 0.0:
		push_error("event '%s' has a falloff power of %.2f: a field has to fall away from its own "
				% [id, falloff_power] + "centre")
		return false
	if (core_intensity > 0.0) != (core_radius > 0.0):
		push_error(("event '%s' sets half a core (%.1f/s over %.0fpx): a core is a rate and a band "
				% [id, core_intensity, core_radius]) + "and neither means anything alone")
		return false
	if core_intensity > 0.0:
		if core_intensity <= intensity:
			push_error(("event '%s' has a %.1f/s core inside a %.1f/s field: a core quieter than "
					% [id, core_intensity, intensity])
					+ "what it sits in is never the larger of the two and changes nothing")
			return false
		if core_radius <= inner_radius or core_radius > outer_radius:
			push_error(("event '%s' has a core falling to nothing at %.0fpx, outside its own "
					% [id, core_radius])
					+ "field's %.0f–%.0fpx band" % [inner_radius, outer_radius])
			return false
		if flock_size > 0:
			push_error("event '%s' is %d bodies wheeling and has a core: a flock's field is a sum "
					% [id, flock_size] + "over bodies, and one disc over the top of it prices "
					+ "ground neither shape describes")
			return false
	if kind == GameEnums.EventKind.AMBIENT:
		return true
	# Neither `AHEAD_OF_PLAYER` nor `TOWARD_PLAYER` has a tile, so `_ensure_the_city_is_still_
	# walkable` never sees either and cannot check that what it blocks leaves a route to a park.
	# Anything that stands in the way therefore has to be sited on the map, where the day can
	# reason about it. A transient one that merely *emits* is fine, and so is a lethal one — it
	# appears in front of her and is gone shortly after, so it can never seal a street.
	if spawn_mode != SpawnMode.MAP and obstructs_radius > 0.0:
		push_error("event '%s' is director-sited and obstructs %.0fpx: nothing checks "
				% [id, obstructs_radius] + "that it leaves a route to a park")
		return false
	# The same argument again, over the day the row switches to instead of the day it starts on —
	# `spawn_mode_on()` is what every placement asks, so a row director-sited only after
	# `from_day_after` has exactly the same unchecked-route problem on that side.
	if from_day_after and from_day_after.spawn_mode != SpawnMode.MAP and obstructs_radius > 0.0:
		push_error(("event '%s' is director-sited from day %d onward and obstructs %.0fpx: "
				% [id, from_day_after.after_day + 1, obstructs_radius])
				+ "nothing checks that it leaves a route to a park")
		return false
	# **A row sited from her walk is a `MAP` row that stands still, or it is nothing.** Only
	# `EventScheduler._place_one_shots` and `_hand_to_her_walk` read the flag, and only
	# `EventDirector` sites what they leave unplaced — so on any other kind it is a decision that
	# silently did not happen. The two
	# geometric halves are load-bearing rather than tidiness: the siting is a tile with the
	# corridor's own questions asked of it, which a director-sited row never has, and a thing that
	# moves has no one place for its scar to be recorded at.
	if on_her_way:
		if kind != GameEnums.EventKind.ONE_SHOT and kind != GameEnums.EventKind.RECURRING:
			push_error("event '%s' is sited from her walk and is neither a one-shot nor " % id
					+ "recurring: nothing but EventScheduler._place_one_shots and "
					+ "_hand_to_her_walk leaves a plan for her walk to site")
			return false
		if spawn_mode != SpawnMode.MAP:
			push_error("event '%s' is sited from her walk and is director-sited besides: it is " % id
					+ "a place chosen late, not a moment with no place at all")
			return false
		if mobile:
			push_error("event '%s' is sited from her walk and moves: a row that may be re-sited " % id
					+ "until it is real needs one place to stop being re-sited at")
			return false
	# A flock is several bodies wheeling inside one disc, so there is no silhouette for a body to
	# be half of — and being walked into is the event. See `obstructs_radius` above.
	if flock_size > 0 and obstructs_radius > 0.0:
		push_error("event '%s' is %d bodies wheeling and obstructs %.0fpx: a flock has no one "
				% [id, flock_size, obstructs_radius]
				+ "silhouette to be solid at, and being walked into is what it is for")
		return false
	# The same shape: a row that stops where it arrives has to have somewhere to arrive, and
	# `_be_done()` cannot both hold it where it is and hand its place to a successor.
	if stops_where_it_arrives:
		if not mobile:
			push_error("event '%s' stops where it arrives and does not move: there is no route " % id
					+ "for it to run out of")
			return false
		if aftermath.on_finish != "":
			push_error("event '%s' stops where it arrives and spawns '%s' when it finishes: it "
					% [id, aftermath.on_finish] + "does one or the other, never both")
			return false
	# **A pursuer awake from its first frame is never the scheduler's to place.** With no notice its
	# telegraph and its chase are clocked from the moment it exists, so a `MAP` row would spend both
	# wherever the stream put it, off screen, before she could meet it. Only a row something sets on
	# her at a moment of its own may have that shape — `SCRIPTED` on day 0, the day nobody plays
	# (`door_guard`, `robber_giving_chase`, `van_guard_giving_chase`). Asked of both days a row can
	# answer, so `charging_dog`, notice-less only while the director sites it, is allowed.
	if pursuit and not (kind == GameEnums.EventKind.SCRIPTED and scripted_day == 0):
		var awake_on_the_map := spawn_mode == SpawnMode.MAP and notice == null
		if from_day_after and from_day_after.spawn_mode == SpawnMode.MAP \
				and from_day_after.notice == null:
			awake_on_the_map = true
		if awake_on_the_map:
			push_error(("event '%s' is placed on the map and pursues from the moment it exists: " % id)
					+ "its notice and its chase would run out wherever the stream put it — only a "
					+ "row nothing but a director sets on her (SCRIPTED, day 0) may have no notice")
			return false
	for each_notice: NoticeSpec in [notice, from_day_after.notice if from_day_after else null]:
		if each_notice and each_notice.within <= 0.0:
			push_error("event '%s' notices her at %.0fpx: a notice needs a distance" % [id,
					each_notice.within])
			return false
	# **A row that answers to the resistance says how it hunts** (`hunts`), and only such a row does:
	# a vehicle that lets men out or a man who pursues, never both and never neither; the patrol
	# rung never pursues and never kills, and only a hunt that pursues ends the day by its own catch.
	if (heat_response == HeatResponse.NONE) != (hunts == null):
		push_error("event '%s' answers to the resistance exactly when it says how it hunts (hunts)"
				% id)
		return false
	if hunts != null and (hunts.lets_out > 0) == (hunts.pursuit != null):
		push_error("event '%s' hunts either by letting men out or by pursuing her, one of the two"
				% id)
		return false
	if hunts != null and hunts.ends_the_day and hunts.pursuit == null:
		push_error("event '%s' hunts by letting men out, whose catch is their own row's" % id)
		return false
	if heat_response == HeatResponse.PRESSES and (hard_fail or hunts.pursuit != null):
		push_error("event '%s' presses but would end the day or chase her itself" % id)
		return false
	var waits_on_some_day := notice != null \
			or (from_day_after != null and from_day_after.notice != null)
	if pursuit:
		# Standing for a notice is a decision about a pursuer that takes one: it waits for her,
		# or it sets off beside her.
		if pursuit.stands and not waits_on_some_day \
				and pursuit.start != PursuitSpec.Start.SETS_OFF_BESIDE_HER:
			push_error("event '%s' stands for a notice it never takes: it neither waits for her nor "
					% id + "sets off beside her")
			return false
		# A notice walk is a walk at her through a notice it took by waiting, slower than its chase.
		if pursuit.walk_speed > 0.0 and (pursuit.stands or not waits_on_some_day
				or pursuit.walk_speed >= pursuit.speed):
			push_error("event '%s' walks %.0fpx/s through a notice it never walks: it must wait for "
					% [id, pursuit.walk_speed] + "her, not stand, and walk slower than its "
					+ "%.0fpx/s chase" % pursuit.speed)
			return false
	# The same shape again, both ways round. Holding a body back through the notice means nothing
	# on a row that has no body, and a row with no notice has nothing to hold it back through — its
	# body would go down on the first frame anyway, which is what the flag exists to stop.
	if solid_when == SolidWhen.ONCE_IT_STARTS and obstructs_radius <= 0.0:
		push_error("event '%s' waits for its own notice to become solid and has no body" % id)
		return false
	if solid_when == SolidWhen.ONCE_IT_STARTS and telegraph_time <= 0.0:
		push_error("event '%s' waits for a notice it does not have before it becomes solid" % id)
		return false
	# A `TOWARD_PLAYER` row is created at least `PendingWarning.least_distance()` from her when it is
	# warned of first — just out of sight, never nearer than the view's half height, whatever she is
	# facing and in either control scheme — and at least `Tuning.min_offscreen_lead()` at its own
	# closing speed and notice when it is created at once (a patrol down the road). So a row whose own
	# field reaches that far would be created already on her on the one heading and moment the
	# director cannot avoid, which is the one thing "she gets close and it arrives" cannot mean.
	if spawn_mode == SpawnMode.TOWARD_PLAYER:
		var floor_lead := PendingWarning.least_distance() if comes_down_her_line() \
				else Tuning.min_offscreen_lead(speed + Tuning.WALK_SPEED, offscreen_notice)
		if outer_radius >= floor_lead:
			push_error("event '%s' comes toward the player with a %.0fpx field, at or past the "
					% [id, outer_radius] + "%.0fpx it is created at on the worst axis: it would arrive "
					% floor_lead + "already inside its own reach there")
			return false
	# **A lethal radius and a solid body are the same mechanism**, and putting both on one event
	# is a way of turning the first one off. She is stopped with her centre `obstructs_radius +
	# PLAYER_BODY_RADIUS` from his, so if that reaches the inner radius the kill can never fire
	# however carelessly she walks into it — a silent difficulty setting, and exactly the shape of
	# the "walk over the robber" complaint rather than a fix for it. Under it, the body is only
	# ever felt during the telegraph, which is the phase where the event is not lethal yet and
	# walking through a wall of metal would be the visible lie.
	#
	# **Stated over `solid_reach()` rather than `obstructs_radius`**, because this one is about
	# where her centre actually comes to rest: a row solid only in parts leaves ground inside its
	# own disc that she can walk onto, so the disc bound would refuse an arrangement that in fact
	# lets the kill fire. The two numbers are the same for every row that is one piece.
	#
	# **And it is a rule about a thing that stands still, which is why a pursuer is outside it
	# rather than excepted from it.** The inference only holds while the body and the thing that
	# kills are the same point: a pursuer's is not, because it comes to her — every one of them
	# either drops its body the frame it starts hunting or, with `PursuitSpec.leaves_its_body`, walks out of
	# a body it leaves standing. Either way the kill fires from ground the body does not cover, so
	# there is nothing here to check. `tests/test_heat.gd` holds that pair, so the exemption cannot
	# quietly become a loophole for a pursuer that kept its body and carried it along.
	if hard_fail and pursuit == null and solid_reach() > 0.0 \
			and solid_reach() + Tuning.PLAYER_BODY_RADIUS >= lethal_reach():
		push_error("event '%s' is lethal inside %.0fpx and solid to %.0fpx: with her own %.0fpx "
				% [id, lethal_reach(), solid_reach(), Tuning.PLAYER_BODY_RADIUS]
				+ "she is stopped before she can ever reach it")
		return false
	# A catch out in the falloff band is a catch she can take while the thing is still quiet. The
	# core is the shell at full strength, so a reach inside it is a reach she can hear coming.
	if lethal_reach() > inner_radius:
		push_error("event '%s' catches at %.0fpx, outside the %.0fpx core of its own field"
				% [id, lethal_reach(), inner_radius])
		return false
	# A conversation is a cost, never a threat: it takes her controls rather than her body or her
	# distance, and a row that could also kill or chase her would be able to do both at once.
	if detain_seconds > 0.0:
		if hard_fail or pursuit:
			push_error("event '%s' detains and is also %s: a conversation may not also be a threat"
					% [id, "hard_fail" if hard_fail else "a pursuer"])
			return false
		if not (detain_distance() < inner_radius and inner_radius <= outer_radius):
			push_error(("event '%s' detains at %.0fpx (%.0fpx past a %.0fpx body), which does not "
					% [id, detain_distance(), detain_radius, obstructs_radius])
					+ ("sit inside its own field (inner %.0f <= outer %.0f)"
					% [inner_radius, outer_radius]))
			return false
	# **A car that drives is a body that moves and a strike that is not the body** — see `vehicle`.
	# Each half-set version is a row the rules cannot read: a car with no route stands for ever and
	# its strike never fires, a car with no shape has no body to be, one that also obstructs would be
	# a moving closure every planner reads as standing ground, and one that is also `hard_fail` would
	# kill twice over, once by its whole field's core from behind and beside it.
	# A vehicle that investigates notices her (`notice`) and lets men out: one that also
	# pursued would be the vehicle chasing her like a running man, one with no reach never notices,
	# and one with no body has no door to let them out of.
	if investigates() and (pursuit or notice == null or shape == null):
		push_error("event '%s' investigates but is not a vehicle with a reach to notice her in, a "
				% id + "body to let men out of and men to let out, that stays where it is")
		return false
	# A stop is a pursuer's catch made a cost: a row that also ended the day would do both at once,
	# and one at or over the whole meter would end a calm day by itself, which is what it is not.
	if pursuit and pursuit.stop_excitement > 0.0 and (hard_fail \
			or pursuit.stop_excitement >= Tuning.METER_MAX):
		push_error("event '%s' stops her for %.0f points but is not a pursuer whose catch is only "
				% [id, pursuit.stop_excitement] + "a cost under the whole meter")
		return false
	if vehicle:
		if not mobile or speed < Tuning.CAR_STRIKE_MIN_SPEED or shape == null:
			push_error("event '%s' drives but has no route, speed (%.0f) or shape to drive with"
					% [id, speed])
			return false
		if obstructs_radius > 0.0 or hard_fail:
			push_error("event '%s' drives and is also %s: a car closes no ground and kills only "
					% [id, "an obstruction" if obstructs_radius > 0.0 else "hard_fail"]
					+ "in front of it")
			return false
		# Its warning is the crowd car's contract, `CAR_HORN_TIME` of its own travel ahead of the
		# strike whatever its speed, so `Tuning.validate_traffic()`'s check on boot is its check:
		# nothing about one row's numbers can break it.
	# *(busy-quail, inbox #569: "1s warning should be enough".)* A badge up alone is up for at most
	# `Tuning.WARNING_ALONE_MAX`, whatever the row.
	if warns_before_it_exists() and warned_for() > Tuning.WARNING_ALONE_MAX + 0.001:
		push_error("event '%s' is warned of %.2fs before it exists, longer than the %.2fs a badge may be "
				% [id, warned_for(), Tuning.WARNING_ALONE_MAX] + "up alone")
		return false
	if lunge_is_inside_the_catch():
		push_error("Unfair pursuit '%s': its lunge is measured from %.0fpx, inside its own %.0fpx catch"
				% [id, pursuit.lunge_reach, lethal_reach()])
		return false
	# A row that runs its own line once she is near is a mobile row that does not pursue and notices
	# her from further than it runs.
	if notice and notice.runs_within > 0.0 \
			and (pursuit or not mobile or notice.within <= notice.runs_within):
		push_error("event '%s' runs within %.0fpx but is not a mobile row that waits for her "
				% [id, notice.runs_within] + "from further than that")
		return false
	if starts_by(PursuitSpec.Start.CHARGES_AT_ONCE) and notice:
		push_error("event '%s' charges at once but waits for her as well" % id)
		return false
	if starts_by(PursuitSpec.Start.ARRIVES_CHASING) \
			and not (warns_before_it_exists() and warned_for() > 0.0):
		push_error("event '%s' arrives chasing but is not a pursuer warned of first" % id)
		return false
	if pursuit and not Tuning.validate_pursuit(id, pursuit.speed, duration, lethal_reach(),
			telegraph_time, notice_within(), outer_radius, standoff_reach(),
			pursuit.start == PursuitSpec.Start.ARRIVES_CHASING
					or pursuit.start == PursuitSpec.Start.CHARGES_AT_ONCE,
			pursuit.start == PursuitSpec.Start.SETS_OFF_BESIDE_HER):
		return false
	# The notice after the day switch is a second shape of the same contract that nothing else
	# exercises: `EventCatalogue.all()` validates every heat shape, but the day axis is orthogonal.
	if pursuit and from_day_after and from_day_after.notice \
			and not Tuning.validate_pursuit(id, pursuit.speed, duration, lethal_reach(), telegraph_time,
					from_day_after.notice.within, outer_radius, standoff_reach()):
		return false
	# **A pursuer that waits for her warns on a clock** (`PursuitSpec.warns_for`) inside its one
	# radius.
	if pursuit and pursuit.start == PursuitSpec.Start.NOTICES and waits_on_some_day \
			and pursuit.warns_for < Tuning.OFFSCREEN_WARNING_MIN:
		push_error("event '%s' waits for her but warns for %.1fs, less than the %.1fs heads-up"
				% [id, pursuit.warns_for, Tuning.OFFSCREEN_WARNING_MIN])
		return false
	if pursuit:
		# A pursuer has no line to be walked out of — it follows — so the ordinary escape-distance
		# rule says nothing about it and `validate_pursuit` is the contract instead. What its
		# telegraph has to buy is the moment of *noticing*, which is checked there.
		return true
	# A thing that does not telegraph its coming loses only the coming's telegraph — the badge and
	# warning first. Its in-world telegraph, where it has one, is still held by the contract: a flock
	# or a mouse standing until she walks in owes it like the lorry does. The one row with none is
	# the loose dog, sent down her line and met with its telegraph already spent
	# (`EventsAhead._send_down_her_line()`), which has no in-world telegraph to hold.
	if not telegraphs and comes_down_her_line():
		return true
	if warns_before_it_exists():
		return Tuning.validate_warning(id, warning_time(), minimum_telegraph())
	return Tuning.validate_event(id, warning_time(), inner_radius, outer_radius, hard_fail,
			speed if mobile else 0.0)

## Shortest warning this row may fairly give — held against `warning_time()`.
##
## **A row warned of before it exists (`warns_before_it_exists()`) is owed
## `Tuning.OFFSCREEN_WARNING_MIN`**, a flat second to react, whatever its field and its speed — the
## cyclist, the fire engine and day 13's column alike. *(PLAYTEST-145: "I don't like
## that the warning is tied to the size of the field or the speed" · "1s is time needed to react to
## something"; busy-quail, inbox #569: "1s warning should be enough -- there is enough screen space
## to cross".)* Its place follows her until it exists, so walking during the badge does not take her
## out of its field, and a floor worked out from the walk out of that field would buy nothing. Every
## other row is owed the time to walk out of its own field, `Tuning.required_telegraph_time()`.
##
## A pursuer's is a different quantity and is stated in `Tuning.PURSUIT_MIN_NOTICE`: the ordinary
## rule buys the time to walk out of a *field*, and there is no walking out of something that
## follows. What its telegraph buys is the time to see it coming and change what you are doing. One
## that sets off beside her is owed the badge's heads-up instead, `Tuning.OFFSCREEN_WARNING_MIN`.
func minimum_telegraph() -> float:
	if warns_before_it_exists() and pursuit == null:
		return Tuning.OFFSCREEN_WARNING_MIN
	# Warned before it was set on her, at the door: it owes none of its own.
	if starts_by(PursuitSpec.Start.CHARGES_AT_ONCE):
		return 0.0
	if starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER):
		return Tuning.OFFSCREEN_WARNING_MIN
	if pursuit:
		return Tuning.PURSUIT_MIN_NOTICE
	return Tuning.required_telegraph_time(inner_radius, outer_radius, hard_fail,
			speed if mobile else 0.0)

## How far ahead of her line `EventDirector` has to site a crossing `AHEAD_OF_PLAYER` row so it
## actually reaches the middle of its run at the moment she reaches it, rather than at whatever
## moment `Tuning.AHEAD_LEAD_DISTANCE` — a flat two seconds of walking — happens to land it.
##
## That flat lead is right for anything that starts moving the instant it is sited. It is wrong for
## anything `still_while_telegraphing`: the whole telegraph is spent held in place, so the crossing
## itself only starts once it is over, and a fixed lead measures where she is *now* rather than
## where the extra `telegraph_time` of walking puts her — which is why a cat sited two seconds
## ahead was reliably crossing behind her by the time it moved at all. Predicting **how long until
## it is at the middle of its own run** and pricing that in walking distance is the same idea
## `AHEAD_LEAD_DISTANCE` already is, generalised to a row whose approach is not its whole telegraph.
func ahead_of_player_lead() -> float:
	if not mobile or speed <= 0.0:
		return Tuning.AHEAD_LEAD_DISTANCE
	var half_crossing := float(Tuning.STREET_WIDTH) * Tuning.TILE_SIZE
	var time_to_middle := half_crossing / speed
	if still_while_telegraphing:
		time_to_middle += telegraph_time
	return maxf(Tuning.AHEAD_LEAD_DISTANCE, time_to_middle * Tuning.WALK_SPEED)

## **How much longer a crossing that holds still crouches when its run is shorter than the one its
## lead was timed for** (`ahead_of_player_lead()`, a half crossing of `Tuning.STREET_WIDTH` tiles):
## a run of `run` px, cut where a solid stands nearer, reaches the middle sooner by the run it lost,
## so it holds that much longer and still reaches the middle when she does. Zero for a run as long
## as the timed one, and for a row that does not hold still, which has no crouch to lengthen.
func crouch_for_a_run(run: float) -> float:
	if not mobile or speed <= 0.0 or not still_while_telegraphing:
		return 0.0
	return maxf(0.0, (float(Tuning.STREET_WIDTH) * Tuning.TILE_SIZE - run) / speed)

## **The nearest to her line a crossing that holds still may crouch**, in px, so she walking on is
## outside its field (`outer_radius`) for the whole crouch. A run that starts `run` px off her line
## reaches the middle when she does (`crouch_for_a_run()`), so as it runs she is still
## `WALK_SPEED * run / speed` short of the middle and `run * sqrt(1 + (WALK_SPEED / speed)²)` from
## the crouch, the nearest she comes to it before it runs; this is that distance held at the field's
## edge. Zero for a row that does not hold still.
func nearest_crouch() -> float:
	if not mobile or speed <= 0.0 or not still_while_telegraphing:
		return 0.0
	return outer_radius / sqrt(1.0 + pow(Tuning.WALK_SPEED / speed, 2.0))

## Seconds from the moment this row becomes visible to the earliest it can reach her, on the worst
## heading the game can give it — what the fairness contract holds against `minimum_telegraph()`.
##
## **For a row in the world while it telegraphs, that is `telegraph_time`**: it is seen when it
## appears, and nothing it does inside the telegraph can end the day or charge her at full strength.
##
## **For a row warned of before it exists** (`warns_before_it_exists()`) **it is its badge to its
## reach**: its badge alone (`warned_for()`), with nothing in the world, plus the time the thing then
## takes to reach her from where it is created. Created closest — `PendingWarning.least_distance()`,
## just out of sight on the view's short axis — and reaching her with her walking into it: at its
## lethal reach for a `hard_fail` row, which is when it can end the day, and at its field's forward
## reach for any other, which is when it charges her. A field that already covers her where it is
## created adds nothing.
func warning_time() -> float:
	if not warns_before_it_exists():
		return telegraph_time
	var closing := speed + Tuning.WALK_SPEED
	var reach := lethal_reach() if hard_fail else field_reach()
	var created_at := PendingWarning.least_distance()
	return warned_for() + maxf(0.0, created_at - reach) / closing

## How long this row's badge is up alone, with nothing in the world, before it is placed just out of
## sight (`PendingWarning`) — for a row warned of before it exists. A pursuer's is its
## `offscreen_notice`, since its `telegraph_time` is the approach she then watches; anything else's is
## its `telegraph_time`, run before it exists and spent when it is created. `validate()` holds it to
## `Tuning.WARNING_ALONE_MAX`.
func warned_for() -> float:
	return offscreen_notice if pursuit else telegraph_time

## Whether this row is warned of before it exists rather than created at once: its screen-edge
## badge goes up with nothing in the world, and its instance is created where the badge points once
## `warned_for()` is over — see `PendingWarning`. Two kinds are: a `TOWARD_PLAYER` row on foot that
## `telegraphs` (`cyclist`), which the director warns of down her line, and a row flagged
## `warned_first` (the fire engine, the resistance's two pursuers, and the copies of day 13's column
## and of `charging_dog` sent down her heading), which the caller that sends it warns of. A
## road-going `TOWARD_PLAYER` copy (`police_patrol`'s return leg) is created at once instead —
## see docs/EVENTS.md, "Everything arrives from off screen", for why it is not warned first.
func warns_before_it_exists() -> bool:
	return warned_first or (comes_down_her_line() and telegraphs)

## Whether the director sends this row down her own line on foot — a `TOWARD_PLAYER` row whose
## ground is not the road (`cyclist`, `loose_dog`): created just out of sight on her sidewalk
## (`PendingWarning.down_her_line()`), under a warning first when it `telegraphs`, at once when it
## does not.
func comes_down_her_line() -> bool:
	return spawn_mode == SpawnMode.TOWARD_PLAYER and not placement.has(GameEnums.TileType.ROAD)

## A copy of this row that enters the world only under a warning that runs first
## (`warned_first`), for a row warned of that is otherwise placed some other way — day 13's column of
## `military_convoy`, whose ordinary row is a `MAP` place the day plans at dawn, and `charging_dog`
## sent at her down her heading, whose ordinary row waits on a tile from the day after it teaches the
## run (`EventSpawner.as_warned()`). Its badge alone is its own, at most
## `Tuning.WARNING_ALONE_MAX`: a non-pursuer's `telegraph_time` is cut to it (the column's 4.43s,
## which the planned convoy keeps in the world), and a pursuer keeps its `offscreen_notice`. The copy
## is validated as it is made, so it is held to the flat minimum a warning first owes.
func as_warned_first() -> EventDef:
	var variant: EventDef = duplicate()
	# `shape` and `solid_parts` are carried across by hand, as every copy of a row does (see
	# `at_heat()`) — a copy that lost its parts would quietly go back to one body spanning its
	# whole shape.
	variant.shape = shape
	variant.solid_parts = solid_parts
	variant.warned_first = true
	if not pursuit:
		variant.telegraph_time = minf(telegraph_time, Tuning.WARNING_ALONE_MAX)
	variant.validate()
	return variant

## The field's own furthest reach from this row's centre — what every "how far" rule needs instead
## of `outer_radius` alone now that a segment's field is a capsule rather than a disc, and now that
## a moving point's own forward reach outgrows its resting radius:
## `EventScheduler._keeps_its_field_clear`'s clearance, the streaming rect, and
## `EventInstance.expected_gross_at()`'s early-out. `half_length + outer_radius` for a segment (the
## along-axis reach, which is exactly the old flat `outer_radius` a row's radii were derived
## *against* — see the catalogue's own docstrings) whose field is priced from that segment. This
## figure does not grow with speed, so for the patrol car, a segment that drives, it is the reach
## of its field standing.
## A row whose field is priced from its centre (`VehicleSpec.field_from_its_centre`, the fire engine) is a
## point for it, whatever its body. Otherwise `outer_radius ·
## Tuning.field_scale(e)`, `e` from whichever speed the row's own motion actually uses —
## its chase speed for a pursuer, `speed` for an ordinary mobile row, zero (the plain disc) for
## anything standing still. A row cannot be both: `EventInstance.travel_velocity()` picks the chase
## speed whenever the row pursues and never reads `speed` for the same instance.
##
## **Not `is_lethal_at()`'s business.** Lethal is contact, not noise: a circle of `lethal_reach()`
## about the centre, with no eccentricity, and for a pursuer only where the straight line to her
## crosses no building — see docs/EVENTS.md, "Solid things are solid", and
## `EventInstance.is_lethal_at()`.
func field_reach() -> float:
	if shape != null and shape.kind == GroundShape.Kind.SEGMENT \
			and not (vehicle and vehicle.field_from_its_centre):
		return shape.half_length + outer_radius
	var moving_speed := pursuit.speed if pursuit else (speed if mobile else 0.0)
	return outer_radius * Tuning.field_scale(Tuning.field_eccentricity(moving_speed))

# ------------------------------------------------------------ what a row costs ---
# The integral behind the cost table in `docs/EVENTS.md` and behind the assertion that nothing is
# cheaper to walk through than around.
#
# **It lives here rather than in `tests/test_events.gd`, because the game asks it too**: the danger
# caret is raised by what a row costs rather than by whether its danger changes over time, and a
# second copy of a number the visual vocabulary depends on is how a fire engine ends up drawn as a
# delivery van — two tables of which picture a look means, disagreeing.

## What walking straight through the middle of one costs, in points of a hundred-point meter:
## the field integrated along the line, less the walking decay over the same time.
##
## Cached, because `EventLook.wants_a_mark()` asks it on every `EventLook.draw()` and the answer is
## a property of the def rather than of the moment.
func walk_through_cost() -> float:
	if _cost_cache == INF:
		_cost_cache = (mean_emission_along_the_line() - Tuning.EXCITEMENT_DECAY_WALKING) \
				* (outer_radius * 2.0 / Tuning.WALK_SPEED)
	return _cost_cache

var _cost_cache := INF

## Mean emission along a straight line through the centre. The only property of a field that either
## the walking or the running comparison depends on: both integrate this line and differ only in how
## long the crossing takes.
func mean_emission_along_the_line() -> float:
	var span := outer_radius * 2.0
	var steps := 2000
	var total := 0.0
	for i in steps:
		total += emission_at(Vector2(-outer_radius + span * (i + 0.5) / steps, 0.0))
	return total / steps

## What a row emits at a point, from its data alone.
##
## One disc for almost everything, and it is the assumption the whole table rests on: all of
## `intensity` is at the centre and it falls away from there.
##
## **That assumption is false for a flock.** A flock is `flock_size` birds sharing the same
## intensity between them and wheeling inside `flock_spread`, so the same number buys a field that is
## tighter and, crucially, *quieter along a line through it* — the disc model reads `pigeon_flock`
## substantially higher than a real instance costs when it is walked through and integrated, and
## priced as a disc it breaks the running rule on a row that in fact keeps it. The birds are placed
## evenly round the wheel at its mean reach rather than where they happen to be: they move, and what
## a row costs is the average over where they might be, not over one frame.
##
## **This is still the def's own model and not the instance's**, and the two answer different
## questions: this one is a line through a flock at full strength, and what an instance charges
## depends on when the birds left the ground, which is decided by where she is rather than by
## anything on the def. `tests/test_events.gd` walks the instance for the part this cannot see.
func emission_at(at: Vector2) -> float:
	if flock_size <= 0:
		return emission_at_distance(at.length())
	var share := intensity / float(flock_size)
	var outer := maxf(inner_radius + 1.0, outer_radius - flock_spread)
	var total := 0.0
	for i in flock_size:
		var angle := TAU * float(i) / float(flock_size)
		var bird := Vector2(cos(angle), sin(angle)) * flock_spread * 0.65
		total += Tuning.falloff(bird.distance_to(at), share, inner_radius, outer, falloff_power)
	return total

## What a row emits at a distance from its centre — the field, and the core over the top of it
## where there is one. **Every price in the game goes through here**: the cost table's integral,
## the placement rules that read it, and `EventInstance.contribution_at()`, which is what the baby
## is actually charged.
##
## `at_intensity` is the peak the *caller* is carrying rather than the row's catalogued one — an
## instance's `current_intensity()`, after the telegraph damping and the pulse envelope. **The core
## is scaled by the same fraction**, so a two-part field damps as one thing: a leaf blower at a
## quarter of its beat is a quarter of a wall and a quarter of a busker, not a full wall inside a
## quiet field. Left out, it is the row's own peak, which is what a cost integrated from the
## catalogue wants.
##
## A row with no core is `Tuning.falloff` on its own field and nothing else, bit for bit — the
## fraction is applied to the peak that is handed in rather than divided back out of it, so nothing
## uncored moves by so much as a last bit. `tests/test_events.gd` walks the whole catalogue at 16px
## steps and holds that.
func emission_at_distance(at_distance: float, at_intensity: float = -1.0) -> float:
	var peak := intensity if at_intensity < 0.0 else at_intensity
	var field := Tuning.falloff(at_distance, peak, inner_radius, outer_radius, falloff_power)
	if core_intensity <= 0.0:
		return field
	var core := core_intensity
	if at_intensity >= 0.0 and intensity > 0.0:
		core *= at_intensity / intensity
	return maxf(field, Tuning.falloff(at_distance, core, inner_radius, core_radius, falloff_power))

## A straight-line distance from a live instance's node beyond which its field is exactly zero,
## whatever its intensity, speed, heading or the way its shape lies — so
## `EventInstance.contribution_at()` can answer zero for a far source without working the field
## out, which is most of the catalogue most of the time.
##
## **Why it is safe.** `emission_at_distance()` is zero once the field distance it is handed is
## past every radius it reads: `inner_radius`, `outer_radius` and, with a core, `core_radius`. The
## field distance is never shorter than the straight distance less the body's own `shape.reach()`
## (a body's spine lies inside that disc), shrunk by at most `1 − Tuning.FIELD_ECCENTRICITY_MAX`
## for a moving source's forward stretch (`GroundShape.eccentric_distance()`). The extra pixel
## swallows the last bit a rotation can round. A flock and a guard walking away from his barrier
## centre their fields elsewhere, so the instance does not ask this for them.
##
## **Not `field_reach()`**, which is the field's own extent for the planners and leaves out the
## inner radius, a core, a rectangle's corners and the stretch of a row that does not move; this
## one is the looser figure nothing can be past and still charge her. Worked out on every call
## rather than kept, since a row's radii and shape are plain fields a rig may change after an
## instance has read them.
func silent_beyond() -> float:
	var level := maxf(inner_radius, outer_radius)
	if core_intensity > 0.0:
		level = maxf(level, core_radius)
	var body := shape.reach() if shape != null else 0.0
	return body + (level + 1.0) / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
