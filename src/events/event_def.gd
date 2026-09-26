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
## `PERSON`, `VEHICLE`, `OBJECT` and `FIRE` do the damage all by themselves: a category is
## something you can always put one more row into, and then a man shouting, a busker, a poster
## crew, a protest and the robbery that ends the day are one `person.svg`, while a delivery van, a
## fire engine, a police car, a riot van, an army truck and the unmarked van that takes the baby
## are one van.
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
	                  ## `EventInstance._draw_mast()` for the lamp that says whether it is live and
	                  ## the arcs that say it is speaking right now.
	# ---- the story's own figure ----
	NEIGHBOR,         ## The neighbor down the hall, in work clothes: steel-blue coveralls with a
	                  ## reflective band and a dark work cap — the face on the wanted notice.
	# ---- the region door's own guard, off his post ----
	DOOR_GUARD,       ## The guard a door sets on her when she walks under its raised boom — the
	                  ## same man in the same two postures as `MASKED_PURSUER` and a heated
	                  ## roadblock's guard, badged by his side view.
	# ---- the resistance's own robber, sent after her ----
	ROBBER_GIVING_CHASE, ## The man a handed-over task sets on her — the alley robber himself, only
	                     ## ever drawn coming (he never waits), badged by his side view, since
	                     ## `ROBBER`'s badge is already the front of the lunge.
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
## No default worth having: it was `OBJECT` — a category, so a row that never chose was drawn as
## roadworks and looked deliberate. Every visible row states its own picture, and
## `tests/test_events.gd` names the three that are legitimately invisible.
@export var look := Look.NONE
@export var ambient_source := AmbientSource.NONE

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
## `EventInstance._wide_scene_texture` picks a composition per street axis rather than rotating one,
## so where the cars sit across the street is a fact about the picture in use. `along` is read off
## the north-south asset and `along_vertical` off its `_vertical` sibling, both at the scale
## `EventInstance._draw_wide_scene` fits the picture to the street.
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
## The default is built once per def rather than per call: `_draw_body_shadow()` asks this on every
## `_draw()` of every visible event, and a fresh `SolidPart` and array per frame per entity is a
## cost for nothing. `shape` is never mutated in place and `solid()` drops the cache when it
## replaces one, so the cached piece cannot go stale.
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

## Whether `EventInstance._draw_body_shadow()` puts anything down for this row at all. `true` for
## every row but `burst_water_main`, whose picture is a crater sunk into the road rather than an
## object standing on it — a shadow under a hole would read as a mound. **The body and the
## collision are untouched**: this governs the shadow patch alone, the same way `IMPACT_CRATER`
## is "the only look with no shadow, because it *is* a shadow" without needing a body of its own to
## turn off.
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

## Seconds at full strength. 0 means it lasts the whole day.
@export var duration := 0.0
## Seconds of visible warning before full intensity, during which it emits only
## TELEGRAPH_INTENSITY_FRACTION of `intensity`.
@export var telegraph_time := 2.5
## Seconds per intensity cycle, for events that pulse rather than hold. 0 is constant.
@export var pulse_period := 0.0

@export var spawn_mode := SpawnMode.MAP

## Day after which this row's siting changes from `spawn_mode` to `spawn_mode_after_first_day` — 0
## (the default) means it never does, so `spawn_mode` alone answers for every day a row recurs,
## which is right for almost everything. `spawn_mode_on()` below is the one place anything reads
## which of the two applies.
##
## **Not a way to mutate `spawn_mode` at runtime.** The catalogue's defs are shared by every day of
## the run and validated once at boot, so a field a day could set on the shared resource would
## persist across a replay in the same process — the same reason `at_heat()` returns a duplicate
## rather than editing `self`. This is the day axis instead of the heat axis, so it is a second
## field and a query, not a mutation.
##
## `charging_dog` is the row that needs it: `Tuning.RUN_TAUGHT_DAY` sites it dead ahead of her,
## unavoidably, because the run lesson depends on it, and every day after — *"the tutorial dog may
## appear later but not as tutorial"* — the same row recurs but is no longer the lesson.
##
## **Shared with `pursues_within_on()` below.** A row whose siting and whose trigger both change
## after its own first appearance changes them on the same day, or the two could disagree about
## which day is which — see that function.
@export var spawn_mode_switches_after_day := 0
## What `spawn_mode_on()` answers once `day` is past `spawn_mode_switches_after_day`. Unread while
## that is 0.
@export var spawn_mode_after_first_day := SpawnMode.MAP

## Which `SpawnMode` this row is sited in on a given day — `spawn_mode` itself for every day up to
## and including `spawn_mode_switches_after_day`, `spawn_mode_after_first_day` for every day past
## it. Every reader that sites an event by its day — `EventScheduler._place_one()`,
## `EventScheduler._role_for()`, `EventDirector.start_day()` — asks this rather than `spawn_mode`
## directly, so the two can never disagree about which day is which.
func spawn_mode_on(day: int) -> SpawnMode:
	if spawn_mode_switches_after_day > 0 and day > spawn_mode_switches_after_day:
		return spawn_mode_after_first_day
	return spawn_mode

## Whether the day budgets this row but leaves *where* it stands to the walk she takes.
##
## A `MAP` row in every other respect — it is a place, on a tile, with a body and a field, and the
## whole plan is stated against the day's corridor exactly as it would have been at dawn. What
## moves is the moment: a one-shot is planned with no position (`EventScheduler._place_one_shots`),
## a recurring row is rolled and placed at dawn exactly as any other and then handed to her walk
## with that position dropped (`EventScheduler._hand_to_her_walk`), and
## `EventDirector.site_what_is_on_her_way()` puts it on a building face ahead of her once her
## direction for the day is clear, off screen and far enough that she meets it rather than watches
## it appear. Until it has been in the world it may be moved again, so a day she turns round is
## still a day it is on her way.
##
## **This is not `AHEAD_OF_PLAYER`**, and the difference is the whole reason it is a second field
## rather than a fourth `SpawnMode`. A director-sited row has no tile at all, may not obstruct, and
## is never asked the corridor's questions; this one is asked all of them, just later than dawn.
##
## Two rows carry it: day 3's fire, a one-shot, and `poster_crew`, recurring. **Only a one-shot is
## spent where it becomes real and lit at dusk if she never met it** — both are about the set
## piece a run owes, and a crew is not one.
@export var sited_on_her_way := false

## Whether her walk sites this row on the sidewalk in front of a blank ground-floor cell of a
## building's front, facing the wall, rather than on the side `pavement_side` names —
## `poster_crew`, which pastes the wall it stands at (`PosterWalls`). Only read with
## `sited_on_her_way`: the dawn roll still places the row by `pavement_side`, so the day's own
## stream is spent exactly as it always was, and only the walk's siting reads this.
@export var pastes_a_front := false

## Seconds of closing this row needs beyond the screen edge before `EventDirector` will site it —
## `Tuning.OFFSCREEN_NOTICE` (0.2) unless a row overrides it. Only `AHEAD_OF_PLAYER` (`pursues`) and
## `TOWARD_PLAYER` rows read this; a `MAP` row is placed at dawn and never asks.
##
## **Per-row because two rows needed to move in opposite directions on the same day.**
## *(2026-09-07: "pursuing dog is still too short notice", "while biker is now too long notice".)*
## `charging_dog` sets this to 0.5: at its 130px/s pursuing (222px/s closing against `WALK_SPEED`),
## the default 0.2 buys only 44px of approach — playtest 20 measured a 1.5s chase as the shortest
## one that ended in evasion and 0.8-0.9s as the two that killed her, so 0.5 is sized to close from
## its worst-case siting to `Tuning.pursuit_standoff()` (104px) in under a second at the combined
## closing speed she usually gives it, well clear of the 0.8-0.9s that failed.
##
## **A further siting needs a longer `telegraph_time` to spend it in**, or a player who only walks
## can outlast the row's own budget before it ever gets to catch her — `duration` stays at
## `Tuning.PURSUIT_TIME` (`tests/test_events_costs.gd` holds every pursuer but `robber_giving_chase`
## to that exact ceiling), so the room has to come from the telegraph instead. See that field on the same row for the arithmetic.
## `cyclist` is left at the default: its own notice is bought back a different way, in
## `outer_radius` and `telegraph_time` — see the reasoning on that row.
@export var offscreen_notice := Tuning.OFFSCREEN_NOTICE

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

## Comes after **her**, rather than along a path.
##
## This is the mechanic that has to exist before running can ever be the right move, and the reason
## it is a mechanic rather than a number: running is worse than walking against everything that
## merely *emits*, because `EXCITEMENT_FROM_RUNNING` outweighs the shorter exposure every time.
## The only way it can be right is if the alternative is losing the day — so a pursuer is lethal,
## it is faster than a walk, and it is slower than a run. Those three together mean walking away
## does not work and running away does, which is the whole lesson.
##
## Its fairness contract is `Tuning.validate_pursuit()`, and it is stated over `RUN_SPEED`: a
## pursuit that cannot be outrun is not a lesson about running.
@export var pursues := false
## How fast it comes. Must sit strictly between `WALK_SPEED` and `RUN_SPEED`.
@export var pursue_speed := 0.0

## How close she has to come before it takes an interest. 0 means *immediately*.
##
## A pursuer with no trigger is a **moment**: `charging_dog` is sited in front of her by the
## director and the chase is the whole of it. A pursuer with one is a **place** that becomes a
## moment — a man in an alley who is standing there, who is worth avoiding from the far end of it,
## and who comes after you if you walk up to him. That is a different thing from both an obstacle
## and an ambush.
##
## Three states rather than two, and the middle one is the load-bearing one: **waiting** (standing
## there, emitting at full strength, not lethal and not moving), **noticing** (`telegraph_time` of
## visibly coming, the
## notice the fairness contract owes), then the chase. `telegraph_time` and `duration` are both
## measured from the moment it notices, not from the moment it was put in the world — a robbery
## that spends its telegraph at dawn, four streets away, has no notice left in it at all.
##
## **The name is older than the field's own reach.** `is_waiting()`, `chase_age()`,
## `current_intensity()`'s undamped notice and `_has_expired()` all read this rather than
## `pursues`, so a row that sets it without `pursues` gets the same waiting state — standing
## unclocked until she is within range, then a telegraph that is not quietened either — without the
## chase that follows for a pursuer. `alley_mouse` is the first: `EventInstance._check_for_notice()`
## is `_chase()`'s own trigger check, folded out so a `MAP`-placed row that is not a pursuer can use
## it to wait for her before it runs its ordinary path, rather than a `MAP` row's arrival at dawn —
## however far outside `Tuning.VIEW_HALF_EXTENT` that turns out to be — starting its clock instead.
##
## **This is the value an instance's own `is_waiting()`, `_chase()` and `_check_for_notice()` read
## — whichever `EventDef` it was actually handed.** For a row whose trigger changes by day, that is
## `pursues_within_on()` below, not this field directly; see that function for how the two stay in
## step with what an instance sees.
@export var pursues_within := 0.0

## Whether this pursuer **sets off beside her** — spawned already inside its own stand-off
## (`Tuning.pursuit_standoff()`), rather than sited or noticing her outside it the way every other
## pursuer is. `door_guard` is the one row: he steps out of a hut a few strides from where she has
## just walked under the boom.
##
## **Its notice cannot be the approach, so it is the ground held.** An ordinary pursuer spends its
## telegraph closing to the stand-off, holding it, and lunging the moment she comes inside it —
## which, from a hut's width away, is a lunge on its first frame and a catch with no notice at all.
## So through the telegraph this one never lunges early and never backs off: it holds its ground
## while she is nearer than the stand-off and follows at the stand-off once she is further, and the
## chase starts when the notice has run its whole length. Walking away still loses — at the end of
## the notice he is at the stand-off and faster than her walk — and running still wins. The price
## is the trap a stand-off exists to avoid, and it is taken knowingly: a player who walks *into*
## him during his notice is caught when it ends, having been shown him standing there for all of
## it. `EventInstance._chase()` reads it.
@export var sets_off_beside_her := false
## What `pursues_within_on()` answers once `day` is past `spawn_mode_switches_after_day`. Unread
## while that is 0.
@export var pursues_within_after_first_day := 0.0

## Whether the thing is **harmless until it notices her**, so its waiting and its notice both emit
## `Tuning.TELEGRAPH_INTENSITY_FRACTION` of `intensity` the way an ordinary telegraph does.
##
## `false` is the default and is right for a row whose waiting state is the threatening one: a man
## standing in an alley has started, what has not started is the lunge, and damping him would be
## saying the wrong thing about the loudest reason to cross the road. `pigeon_flock` is the
## opposite shape — birds pecking on a pavement are nearly nothing, and the event *is* them going
## up — so without this a flock would charge her its full 42/s for as long as it stood there
## unnoticed, which is a place she can never walk past rather than one she can walk around.
##
## Read only where `pursues_within` is set, since there is no waiting state without a trigger;
## `validate()` refuses the pair the other way round, where the flag could never be read.
@export var quiet_until_noticed := false

## `pursues_within` on a given day — `pursues_within` itself through `spawn_mode_switches_after_day`,
## `pursues_within_after_first_day` past it. The same day-keyed switch `spawn_mode_on()` reads, so a
## row that changes both its siting and its trigger on one day cannot have the two disagree about
## which day that is.
##
## **Derived the way `spawn_mode_on()` is, and read the same way `at_heat()`'s derived copy is:
## never a mutation of the shared resource.** Nothing calls this and then edits `self.pursues_within`
## — an instance's own `is_waiting()` reads `pursues_within` off whichever `EventDef` it was handed,
## so a day answer that has to change what an instance sees is a placement handing it a *different*
## def, the way a heated copy is a different def from the cold one. `EventScheduler._for_day()` is
## where a `MAP` placement past the switch gets that copy; a director-sited encounter — day 3's own
## `AHEAD_OF_PLAYER` dog, or the same shape sprinkled in on a later day by `EventDirector` — is handed
## the row exactly as authored, `pursues_within` still 0.0, because both are met already noticing
## her rather than waiting to be routed into.
##
## `charging_dog` is the row that needs it: from day 4 the row is `MAP`-placed and met by routing
## into it like `alley_robbery`, so *"the tutorial dog may appear later but not as tutorial"* means
## it has to wait inside its own field for her rather than announce itself the moment it streams in
## from `Tuning.EVENT_STREAM_RADIUS` away.
func pursues_within_on(day: int) -> float:
	if spawn_mode_switches_after_day > 0 and day > spawn_mode_switches_after_day:
		return pursues_within_after_first_day
	return pursues_within

## How this row answers to the resistance.
##
## **The city gets worse the further into the subquest you are**, and this is the whole of how a row
## says so. `GameState.resistance_progress` is an integer 0..`Tuning.RESISTANCE_GOAL`, and
## `at_heat()` below turns a level into a **derived copy** of the row with its numbers moved — so
## nothing downstream of the day's plan has to know that heat exists at all. An `EventInstance`
## holds whichever copy the day handed it and reads `intensity`, `pursues` and the rest exactly as
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
	## **More of them, and more expensive to stand near, and past a threshold it comes over.**
	## The non-lethal rung: it never gains `hard_fail`, whatever the heat.
	PRESSES,
	## **It stops being a place and starts being a hunter.** The lethal rung.
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
## list, because the moment it is a list a delivery van is scenery and a man standing in a
## courtyard can be walked through. And the number is not a balance value: it is half of the
## silhouette, because `_draw_spread` draws a blocking object at exactly the width it obstructs,
## and anything else is a lie about where she can walk.
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

## Whether the body arrives when the notice ends rather than with the instance.
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
## row carrying this flag reads as solid to the crowd and to route-clearing for the whole of its
## life. Set it on something placed where there is no lattice to clear, or accept that the ground
## is reserved the whole time.
@export var solid_once_it_starts := false

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
	## lot behind it — the one face of a building the city draws. Where a poster crew pastes. Never
	## a row's own `pavement_side`: `EventScheduler.WalkSiting` asks it for a row that
	## `pastes_a_front`.
	AT_THE_FRONT,
}

@export var pavement_side := Pavement.ANY

## Event id to spawn where this one ends. How a military convoy leaves a barricade behind it.
@export var spawns_on_finish := ""

## Whether this row **stops where its route ends and stays there for the rest of the day**, instead
## of driving on out of sight the way everything else that runs out of route does.
##
## The fire engine is the only row that carries it, and the flag says what it means rather than
## borrowing a mechanism that means something else: a `spawns_on_finish` would also keep it where it
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
## neither finishes nor leaves such a row, `_advance_along_path()` stops adding to the distance it
## has covered (a gait is driven by distance, so a parked engine would bob for ever), and
## `travel_velocity()` answers zero (the screen-edge badge reads that as a closing speed, and a
## parked thing is not closing).
@export var stops_where_it_arrives := false

## Event id to spawn the moment this one is first seen. The opposite direction from
## `spawns_on_finish` above: that names what a row leaves behind when it is done; this names
## what arrives once she has found it. How the burning building calls in the fire engine —
## `EventManager` owns the trigger, since it already owns the successor mechanism and her
## position; see `EventManager._summon_what_has_been_sighted()`.
@export var spawns_on_sight := ""

## Seconds the player's movement input is locked for, on first contact within `detain_distance()`.
## `0.0` means never — the default, and true of every row but `chatting_mother`.
##
## **The one mechanic in the catalogue that takes the controls away rather than costing a meter.**
## Everything else that stops her is a choice — walk into it or do not — and this is the exception,
## which is why `validate()` refuses it on anything `hard_fail` or `pursues`: a thing that can also
## kill her or chase her has no business also deciding she cannot move. See `Stroller.detain()` for
## the lock itself, which runs out through the ordinary friction rather than stopping her dead.
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
## `EventManager._check_detentions()` and `_release_finished_door_detentions()` both measure, so
## the trigger and the distance the release has to clear can never be derived differently.
func detain_distance() -> float:
	return obstructs_radius + detain_radius

## Whether an instance is armed again once she has been released and has moved outside
## `detain_distance()`, rather than spent for good after its first conversation like
## `chatting_mother`.
## `false` is the default and is right for almost every detainer: a toll booth she can pass again
## either way, which is the checkpoint's whole point, needs the opposite — *"it works in both
## directions with the same cost each time"* — so `checkpoint_hut` and `checkpoint_post` are the
## only two rows that set it. `EventManager._check_detentions()` is what reads it.
@export var redetains := false

## Whether this row is a **boom** — a bar across a door's carriageway that the cars raise and lower
## (`Crowd._stop_for_gates()`, through the `RegionPlanner.GateState` its instance carries), and
## that is solid to her **only while it is down**. `checkpoint_gate` is the one row that sets it.
##
## *(2026-09-24, the player: "Boom shouldn't inspect her. It should block her." · "I didn't say it
## should stay solid when it's open".)* So it never detains: a lowered boom is a wall across the
## road and a raised one is ground she may walk under, at the price of the car that raised it and of
## the guard a walked crossing sets on her (`EventManager._set_a_guard_on_her()`). The inspection is
## the huts' alone, and a hut never takes her in from the carriageway its own door's
## boom spans — that ground is the boom's.
##
## Read in three more places, each because a boom is a door body that does not detain:
## `EventManager.obstructed_footprint()` keeps it out of the crowd's per-tile record the way it
## keeps the huts out (the cars' answer to it is the gate hold), `EventDirector` keeps the door's
## clear ground around it, and `EventInstance` lets its collision body follow the arm.
@export var lifts_for_traffic := false

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

## How close the thing that ends the day has to get, in px, when that is **not** the field's own
## core. `0.0`, the default and true of almost every row, means `inner_radius` — the two are one
## number for anything whose noise and whose reach are the same object.
##
## **It exists for a row whose killer is not the thing the field is drawn around.** A roadblock's
## field is a street being held: a wide band of shouting, cored on the barrier. What takes the
## baby is a man, at a man's reach, and he walks out of that band to do it — so sizing the catch
## off the field would price a person's arms at the width of a barricade. `lethal_reach()` is what
## every caller asks; `inner_radius` stays the field's own, so moving one never silently moves the
## other.
##
## Must sit inside the core when it is set: a kill that fired out in the falloff band would be one
## she could take while the thing is still quiet, and the core is the shell that is at full
## strength and therefore unmistakable.
@export var lethal_radius := 0.0

## The distance that ends the day — `lethal_radius` where a row sets one, the field's own core
## otherwise. The form every caller wants, so no call site has to know which kind of row it holds.
func lethal_reach() -> float:
	return lethal_radius if lethal_radius > 0.0 else inner_radius

## Whether this row's body is a **fixture of the street** that a pursuer leaves standing, rather
## than the pursuer's own bulk.
##
## Ordinarily a pursuer's obstruction comes down the frame it stops waiting — *"a moving pursuer
## with a body is a wall"*, and a van that kept one would pin her against a building. A roadblock
## is the other case: the barrier is built across the road and the man who leaves it does not take
## it with him, so the street he abandoned stays shut behind him. `EventInstance` pins the body at
## the place it was left instead of freeing it, and draws the barrier there too, so the picture and
## the physical street agree for the whole of the event's life.
##
## Only meaningful on a row that can pursue, which `validate()` requires: a fixture that never
## chases has nothing to leave its body behind *from*.
@export var body_stays_behind := false

## Which side or sides of a `Look.ROADBLOCK` band `_draw_roadblock()` posts a standing guard on —
## `-1`/`+1` in `_guard_post_offset()`'s own reading of `side`, the same sign `_guard_side_toward()`
## and `_chaser_side` use. `[-1, 1]` (both) is every row's own default: the catalogue `roadblock`
## and every wall body inherit it unless something here overrides it.
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
## are a value set on a fresh duplicate at placement, with no change to `_draw_roadblock()` itself.
@export var guard_sides: Array[int] = [-1, 1]

## Exempt from the cost rule's wall and friction placement — `EventScheduler._role_for` answers
## `NONE` for it before the cost check ever runs, so `_copies_of` neither pulls it off the
## corridor nor weights it onto one: it lands on whatever tile the roll picks, the way an
## ambient event or a scar does. `pigeon_flock` is the row it exists for — *"flocks are basically
## free already — don't count it as block, just count is scenery"* — because a 42-over-168px
## field crosses `Tuning.WALL_WORTH_OF_COST` and would otherwise be pulled off every route like
## any other expensive row.
@export var scenery := false

## Intensity multiplier reached at the end of `duration`. 1.0 holds steady; above 1.0
## swells (a protest gathering), below 1.0 fades.
@export var intensity_ramp := 1.0

## Event id to leave permanently at this event's position for the rest of the RUN. A fire
## leaves a burnt-out shell; the shell is still there on day 12.
@export var scar_id := ""

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
## `level` is `GameState.resistance_progress`, clamped here rather than by the caller — it can reach
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
	match heat_response:
		HeatResponse.PRESSES:
			# More of them, and more expensive to be near. Population is the axis that changes the
			# *route* — this row's whole design is that you start planning around it — and intensity
			# is what makes one of them worth planning around in the first place.
			hot.max_per_day = maxi(max_per_day,
					roundi(max_per_day * lerpf(1.0, Tuning.HEAT_PRESSES_POPULATION, through)))
			hot.intensity = intensity * lerpf(1.0, Tuning.HEAT_PRESSES_INTENSITY, through)
			if level >= Tuning.HEAT_INVESTIGATES_LEVEL:
				# **It runs its route until it notices her, and then it comes over.** No field says
				# so: a pursuer that is also `mobile` with a path patrols it while it waits, which
				# `EventInstance._process` reads off the two flags it already has.
				hot.pursues = true
				hot.pursue_speed = Tuning.HEAT_INVESTIGATE_SPEED
				hot.pursues_within = Tuning.HEAT_INVESTIGATE_WITHIN
				# For a pursuer `duration` is the length of the chase, measured from the moment it
				# notices her rather than from dawn. Cold, this row has none and simply drives to
				# the end of its route.
				hot.duration = Tuning.HEAT_INVESTIGATE_SECONDS
			# The non-lethal rung stays non-lethal at every level. Stated rather than assumed,
			# because the whole instruction this milestone came from is that the ladder has two
			# rungs and only the top one kills.
			hot.hard_fail = false
		HeatResponse.HUNTS:
			# Below its own threshold a `HUNTS` row is untouched. Population and intensity are
			# `PRESSES`'s axes — "more of them, more expensive" — and this rung answers a
			# different question: not *how much does it cost to be near*, but *can I still be
			# near it at all*.
			if level >= Tuning.HEAT_HUNTS_LEVEL:
				hot.pursues = true
				hot.pursue_speed = Tuning.HEAT_HUNTS_SPEED
				hot.pursues_within = Tuning.HEAT_HUNTS_WITHIN
				# The shared trigger is authored once, against the widest cold field in the
				# catalogue (`abduction`'s 250px) — a row whose own `outer_radius` sits under it
				# would notice her from outside its own field, which `Tuning.validate_pursuit()`
				# refuses. Widening only the hunting copy holds the contract for every `HUNTS` row
				# without asking a row's author to pad its cold field past a constant that belongs
				# to the ladder rather than to the row; the cold shape, and everything measured
				# from it (`required_telegraph_time()`, the cost table), is untouched.
				hot.outer_radius = maxf(outer_radius, hot.pursues_within)
				# For a pursuer `duration` is the length of the chase, not the length of the idle
				# — see `pursues_within` above. Cold, this row simply sits for `duration` seconds
				# and is done.
				hot.duration = Tuning.PURSUIT_TIME
				# Stated explicitly rather than left to the copy, the way `PRESSES` states the
				# opposite above: a pursuer is exempt from the rule that nothing else happens
				# inside a lethal event's field (`EventScheduler._keeps_its_field_clear`), so this
				# rung stays `hard_fail` rather than losing it to stay inside that rule.
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
	# `spawn_mode_switches_after_day` has exactly the same unchecked-route problem on that side.
	if spawn_mode_switches_after_day > 0 and spawn_mode_after_first_day != SpawnMode.MAP \
			and obstructs_radius > 0.0:
		push_error(("event '%s' is director-sited from day %d onward and obstructs %.0fpx: "
				% [id, spawn_mode_switches_after_day + 1, obstructs_radius])
				+ "nothing checks that it leaves a route to a park")
		return false
	# **A row sited from her walk is a `MAP` row that stands still, or it is nothing.** Only
	# `EventScheduler._place_one_shots` and `_hand_to_her_walk` read the flag, and only
	# `EventDirector` sites what they leave unplaced — so on any other kind it is a decision that
	# silently did not happen. The two
	# geometric halves are load-bearing rather than tidiness: the siting is a tile with the
	# corridor's own questions asked of it, which a director-sited row never has, and a thing that
	# moves has no one place for its scar to be recorded at.
	if sited_on_her_way:
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
	if pastes_a_front and not sited_on_her_way:
		push_error("event '%s' pastes a front and is not sited from her walk: only the walk's " % id
				+ "siting reads it")
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
		if spawns_on_finish != "":
			push_error("event '%s' stops where it arrives and spawns '%s' when it finishes: it "
					% [id, spawns_on_finish] + "does one or the other, never both")
			return false
	# **A pursuer awake from its first frame is never the scheduler's to place.** With no trigger
	# (`pursues_within` 0) its telegraph and its chase are clocked from the moment it exists, so a
	# `MAP` row the day planned would spend both wherever the stream put it in the world — up to
	# `Tuning.EVENT_STREAM_RADIUS` away, off screen, before she could ever meet it. Only a row
	# something sets on her at a moment of its own may have that shape, and the catalogue's own
	# sentinel for such a row is `SCRIPTED` on day 0, the day nobody plays: `available_on()` then
	# never offers it to the roll, the stream or the budget. `door_guard` (set on her by a door)
	# and `robber_giving_chase` (set on her by a handed-over task) are the two. Asked of both days a
	# row can answer — `spawn_mode_on()`'s switch — so `charging_dog`, trigger-less only while the
	# director sites it and waiting once it is placed, is the shape this allows rather than refuses.
	if pursues and not (kind == GameEnums.EventKind.SCRIPTED and scripted_day == 0):
		var awake_on_the_map := spawn_mode == SpawnMode.MAP and pursues_within <= 0.0
		if spawn_mode_switches_after_day > 0 and spawn_mode_after_first_day == SpawnMode.MAP \
				and pursues_within_after_first_day <= 0.0:
			awake_on_the_map = true
		if awake_on_the_map:
			push_error(("event '%s' is placed on the map and pursues from the moment it exists: " % id)
					+ "its notice and its chase would run out wherever the stream put it — only a "
					+ "row nothing but a director sets on her (SCRIPTED, day 0) may have no trigger")
			return false
	# The same shape: a stand-off rule for something that never chases is a decision nothing reads.
	if sets_off_beside_her and not pursues:
		push_error("event '%s' sets off beside her but never pursues" % id)
		return false
	# A flag nothing can read is a decision that silently did not happen: without a trigger there is
	# no waiting state for `quiet_until_noticed` to quieten.
	if quiet_until_noticed and pursues_within <= 0.0:
		push_error("event '%s' is quiet until noticed but has no trigger to be noticed at" % id)
		return false
	# The same shape again, both ways round. Holding a body back through the notice means nothing
	# on a row that has no body, and a row with no notice has nothing to hold it back through — its
	# body would go down on the first frame anyway, which is what the flag exists to stop.
	if solid_once_it_starts and obstructs_radius <= 0.0:
		push_error("event '%s' waits for its own notice to become solid and has no body" % id)
		return false
	if solid_once_it_starts and telegraph_time <= 0.0:
		push_error("event '%s' waits for a notice it does not have before it becomes solid" % id)
		return false
	# `EventDirector` sites a `TOWARD_PLAYER` row at least `Tuning.offscreen_lead(heading,
	# closing_speed, offscreen_notice)` in front of her, which is never less than
	# `Tuning.min_offscreen_lead()` at the row's own closing speed (its `speed` plus `WALK_SPEED`,
	# since she is usually walking into it) and its own notice, whatever she is facing — so a row
	# whose own field reaches that far would appear already inside its own outer radius on the one
	# heading and moment the director cannot avoid, which is the one thing "she gets close and it
	# arrives" cannot mean.
	if spawn_mode == SpawnMode.TOWARD_PLAYER:
		var floor_lead := Tuning.min_offscreen_lead(speed + Tuning.WALK_SPEED, offscreen_notice)
		if outer_radius >= floor_lead:
			push_error("event '%s' comes toward the player with a %.0fpx field, at or past the "
					% [id, outer_radius] + "%.0fpx it is sited at on the worst axis: it would arrive "
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
	# either drops its body the frame it starts hunting or, with `body_stays_behind`, walks out of
	# a body it leaves standing. Either way the kill fires from ground the body does not cover, so
	# there is nothing here to check. `tests/test_heat.gd` holds that pair, so the exemption cannot
	# quietly become a loophole for a pursuer that kept its body and carried it along.
	if hard_fail and not pursues and solid_reach() > 0.0 \
			and solid_reach() + Tuning.PLAYER_BODY_RADIUS >= lethal_reach():
		push_error("event '%s' is lethal inside %.0fpx and solid to %.0fpx: with her own %.0fpx "
				% [id, lethal_reach(), solid_reach(), Tuning.PLAYER_BODY_RADIUS]
				+ "she is stopped before she can ever reach it")
		return false
	# A catch out in the falloff band is a catch she can take while the thing is still quiet. The
	# core is the shell at full strength, so a reach inside it is a reach she can hear coming.
	if lethal_radius > 0.0 and lethal_radius > inner_radius:
		push_error("event '%s' catches at %.0fpx, outside the %.0fpx core of its own field"
				% [id, lethal_radius, inner_radius])
		return false
	# A body left behind has to be left behind *by* somebody: a fixture that never chases has
	# nothing to walk out of its own barrier.
	if body_stays_behind and not pursues and heat_response != HeatResponse.HUNTS:
		push_error("event '%s' leaves its body behind but never pursues, so nothing ever leaves it"
				% id)
		return false
	# A conversation is a cost, never a threat: it takes her controls rather than her body or her
	# distance, and a row that could also kill or chase her would be able to do both at once.
	if detain_seconds > 0.0:
		if hard_fail or pursues:
			push_error("event '%s' detains and is also %s: a conversation may not also be a threat"
					% [id, "hard_fail" if hard_fail else "a pursuer"])
			return false
		if not (detain_distance() < inner_radius and inner_radius <= outer_radius):
			push_error(("event '%s' detains at %.0fpx (%.0fpx past a %.0fpx body), which does not "
					% [id, detain_distance(), detain_radius, obstructs_radius])
					+ ("sit inside its own field (inner %.0f <= outer %.0f)"
					% [inner_radius, outer_radius]))
			return false
	if pursues and not Tuning.validate_pursuit(id, pursue_speed, duration, lethal_reach(),
			telegraph_time, pursues_within, outer_radius):
		return false
	# The day-switched trigger is a second shape of the same contract and nothing else exercises
	# it: `EventCatalogue.all()` validates every *heat* shape of every row, but the day axis is
	# orthogonal to heat, so `pursues_within_after_first_day` would otherwise go unchecked until a
	# run actually reached the day that reads it.
	if pursues and pursues_within_after_first_day > 0.0 \
			and not Tuning.validate_pursuit(id, pursue_speed, duration, lethal_reach(), telegraph_time,
					pursues_within_after_first_day, outer_radius):
		return false
	if pursues:
		# A pursuer has no line to be walked out of — it follows — so the ordinary escape-distance
		# rule says nothing about it and `validate_pursuit` is the contract instead. What its
		# telegraph has to buy is the moment of *noticing*, which is checked there.
		return true
	return Tuning.validate_event(id, telegraph_time, inner_radius, outer_radius, hard_fail,
			speed if mobile else 0.0)

## Shortest telegraph this geometry may fairly have.
##
## A pursuer's is a different quantity and is stated in `Tuning.PURSUIT_MIN_NOTICE`: the ordinary
## rule buys the time to walk out of a *field*, and there is no walking out of something that
## follows. What its telegraph buys is the time to see it coming and change what you are doing.
func minimum_telegraph() -> float:
	if pursues:
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

## How far down her own line `EventDirector._toward_her()` sites this `TOWARD_PLAYER` row, along
## `heading`. **The one place that answer lives**, because two things that are not the director ask
## it: `EventDef.validate()` needs the floor under it, and the pass measurement behind
## `docs/COSTS.md` has to spawn the row where the game spawns it or it is pricing a meeting that
## never happens.
##
## `closing_speed` is the row's own `speed` plus `WALK_SPEED`, since she is usually walking into it.
##
## **Every such row is sited so that its telegraph is over before it arrives, and what "arrives"
## means is the only thing that differs between them.** A row that arrives inside its own telegraph
## has spent its entire encounter on the warning: `EventInstance.is_lethal_at()` refuses the whole
## telegraph, so a lethal one rides through her unable to fire, and `_notice_damping()` holds a loud
## one at `Tuning.TELEGRAPH_INTENSITY_FRACTION` (0.15), so a loud one is past her before it is ever
## at its own intensity. Same defect, one at the kill and one at the meter.
##
## So `Tuning.outlasting_telegraph_lead()` gets the row's own arrival distance as its margin: zero
## for `hard_fail`, where arriving is touching her, and `field_reach()` for anything else, where
## arriving is its field reaching her. A lethal row's siting is unchanged by that reading — it was
## always zero — and a loud one now goes loud a notice before she is inside it rather than a notice
## before it is on top of her.
func toward_player_lead(heading: Vector2) -> float:
	return Tuning.outlasting_telegraph_lead(heading, speed + Tuning.WALK_SPEED, telegraph_time,
			offscreen_notice, 0.0 if hard_fail else field_reach())

## `toward_player_lead()` with no heading to ask about: the least it can be on any heading, which is
## the closest the director could ever site this row and so the cheapest version of the meeting.
## What `tests/probes/m174_pass.gd` measures the pass against, for the same reason
## `Tuning.min_offscreen_lead()` exists — a figure in `docs/COSTS.md` may not depend on which way a
## particular walk happened to be going.
func min_toward_player_lead() -> float:
	return Tuning.min_outlasting_telegraph_lead(speed + Tuning.WALK_SPEED, telegraph_time,
			offscreen_notice, 0.0 if hard_fail else field_reach())

## The field's own furthest reach from this row's centre — what every "how far" rule needs instead
## of `outer_radius` alone now that a segment's field is a capsule rather than a disc, and now that
## a moving point's own forward reach outgrows its resting radius:
## `EventScheduler._keeps_its_field_clear`'s clearance, the streaming rect, and
## `EventInstance.expected_gross_at()`'s early-out. `half_length + outer_radius` for a segment (the
## along-axis reach, which is exactly the old flat `outer_radius` a row's radii were derived
## *against* — see the catalogue's own docstrings; every emitting segment row is stationary, so its
## own eccentricity is always zero and this figure never grows). Otherwise `outer_radius ·
## Tuning.field_scale(e)`, `e` from whichever speed the row's own motion actually uses —
## `pursue_speed` for a pursuer, `speed` for an ordinary mobile row, zero (the plain disc) for
## anything standing still. A row cannot be both: `EventInstance.travel_velocity()` picks
## `pursue_speed` whenever `pursues` is set and never reads `speed` for the same instance.
##
## **Not `is_lethal_at()`'s business.** Lethal is contact, not noise, and stays a plain circle of
## `inner_radius` about the centre — see docs/EVENTS.md, "Solid things are solid", and
## `EventInstance.is_lethal_at()`, unchanged by this milestone.
func field_reach() -> float:
	if shape != null and shape.kind == GroundShape.Kind.SEGMENT:
		return shape.half_length + outer_radius
	var moving_speed := pursue_speed if pursues else (speed if mobile else 0.0)
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
## Cached, because `EventInstance.wants_a_mark()` asks it on every `_draw()` and the answer is a
## property of the def rather than of the moment.
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
