class_name EventDef
extends RefCounted
## Authored data for one kind of event. See docs/EVENTS.md.
##
## Defs are constructed in code by `EventCatalogue` rather than saved as .tres files: they
## are reviewable in a diff, they can be validated on load, and the fairness contract can be
## asserted over the whole catalogue in a test. Nothing here needs an editor to tune.

## The progress at which a `HUNTS` row stops being a place and starts being a hunter. Its own
## number rather than the patrol's `HEAT_INVESTIGATES_LEVEL`, so the two rungs of the ladder land in
## different moments and each reads as its own step. `Tuning.RESISTANCE_GOAL - 1` is one task's worth
## of progress left before the goal.
const HEAT_HUNTS_LEVEL := Tuning.RESISTANCE_GOAL - 1
## How close she has to come before it takes an interest, in px. Strictly between
## `PursuitSpec.standoff(Tuning.HEAT_HUNTS_SPEED, 54)` (132px, against the van's own inner radius) and its
## 250px field: under the stand-off the whole notice is spent standing still, over the field it
## decides about her before she can feel it.
const HEAT_HUNTS_WITHIN := 180.0
## The progress at which a pressing row stops merely running its route and starts investigating:
## stopping near her and letting a pursuer on foot out (`EventDef.investigates()`, read off its
## `HuntSpec`). As close to half way through `Tuning.RESISTANCE_GOAL` as a whole task lets it land
## (`roundi(5 / 2.0)`): the first half of the subquest is the city being denser, the second is it
## being interested.
const HEAT_INVESTIGATES_LEVEL := 3
## How close she has to come, along a clear line, before an investigating car stops and its
## policeman gets out, in px. **Inside the patrol's own 185px outer radius**, so it decides about her
## only once she can feel it, and wider than the man's stand-off (116px), so he usually gets out with
## room to hold his ground and give the notice he owes her (`PursuitSpec.Start.SETS_OFF_BESIDE_HER`
## covers him when she is nearer).
const HEAT_INVESTIGATE_WITHIN := 150.0
## What the intensity of a pressing row is multiplied by at full heat: the patrol's 10/s at the
## centre becomes 13.5/s. The smaller of the two multipliers, since an intensity rise is the one the
## player feels without seeing anything change.
const HEAT_PRESSES_INTENSITY := 1.35
## What the population of a pressing row is multiplied by at full heat: its cap and its weight in the
## day's bags (`UnitFills`, `DawnMoments`, `EventDirector`). `police_patrol` is capped at twelve a day cold, so
## nineteen hot, and drawn 1.6 times as often: on an 11x11 lattice a patrol on one block in six rather
## than one in ten.
##
## **Population is the axis that changes a route rather than a meter.** More patrols is more ground
## to plan around, and it costs nothing in fairness because each individual patrol is exactly the
## event it was.
const HEAT_PRESSES_POPULATION := 1.6

## How the instance is drawn. Data rather than a script per event, since most events differ
## only in their numbers.
##
## **One look per row, and every look is a thing rather than a category.** A category is something
## one more row can always be put into, until a man shouting, a street musician, a poster crew, a
## protest and the robbery that ends the day are one `person.svg`, and a delivery van, a fire engine,
## a police car and the unmarked van that takes the baby are one van. The entity itself carries most
## of the visual vocabulary, so a shared picture makes a complaint about one row indistinguishable
## from a complaint about another.
##
## A look is the name of one picture, and `tests/test_events.gd` holds both halves of the rule:
## **no two rows share a look**, and **no two looks share a silhouette**. There is no generic look
## to reach for, so adding an event costs a drawing.
enum Look {
	NONE,     ## Invisible — something else already draws it (a park's playground frame).
	# ---- act I ----
	CAT,          ## Crouched, then stretched out flat. The crouch is the telegraph.
	MOUSE,        ## A single side-on silhouette, mirrored east and west. No crouch of its own —
	              ## it is already still, being small, and the dash is the whole event.
	YELLER,       ## A long coat, a raised arm, a beard. One shape where a passer-by is two.
	DOG_WALKER,   ## A person, a dog, and the taut lead between them.
	CAFE,         ## Tables across the pavement, with people at them.
	DELIVERY_VAN, ## Shutter up, hazards on. The plain van.
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
	                    ## square has instead of a wall. Its own look, since two rows that draw
	                    ## the same man are one look.
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

## Where an instance comes from.
enum SpawnMode {
	## Placed on a tile when the day is planned, and streamed into the world when the player
	## comes near it. Almost everything: an event that is *somewhere* is half of what makes a
	## route a decision, because it can be routed around.
	MAP,
	## Placed in front of the player, while she walks, by `EventDirector`. For the few events whose
	## whole content is *the moment it happens to you*: a cat bolting out of a doorway is nothing if
	## it does it two blocks away. The day owes it rather than placing it: the scheduler counts the
	## day's moments (`PlacementDensity.moments_on()`) instead of putting one on a tile.
	AHEAD_OF_PLAYER,
	## Sited on her own line, ahead of her, by `EventDirector` like `AHEAD_OF_PLAYER`, but
	## travelling *down* that line toward her rather than crossing it: a bike on the sidewalk she is
	## walking, coming the other way. `MAP` sites it at dawn, before the day knows where she goes;
	## a crossing `AHEAD_OF_PLAYER` row is gone in three seconds and asks her to react, not to plan.
	## This one is a road she answers with a route decision (cross, or turn), which is why it does
	## not stop or steer for her the way a pursuer does: it is traffic, not an ambush.
	TOWARD_PLAYER,
}

## A row built from `draft`'s settings and parts, which `EventDraft.build()` hands it: the one
## way a row is made. A part is a value nothing changes, so the row holds the draft's by
## reference, and a copy of the row is a `redraft()`.
func _init(draft: EventDraft) -> void:
	_draft = draft
	_id = draft.drafted_id()
	_kind = draft.drafted_kind()
	_ambient_source = draft.drafted_ambient_source()
	_noun = draft.drafted_noun()
	_noun_plural = draft.drafted_noun_plural()
	_first_day = draft.drafted_first_day()
	_last_day = draft.drafted_last_day()
	_scripted_day = draft.drafted_scripted_day()
	_act_tag = draft.drafted_act()
	_weight = draft.drafted_weight()
	_max_per_day = draft.drafted_most_per_day()
	_ground_weights = draft.drafted_ground_weights()
	_placement = draft.drafted_ground()
	_repeat_every = draft.drafted_repeat_every()
	_repeat_after = draft.drafted_repeat_after()
	_duration = draft.drafted_duration()
	_spawn_mode = draft.drafted_spawn_mode()
	_from_day_after = draft.drafted_switch()
	_on_her_way = draft.drafted_her_walk()
	_sent_ahead = draft.drafted_sent_ahead()
	_departs_at = draft.drafted_departs_at()
	_pavement_side = draft.drafted_lane()
	_spans_the_street = draft.drafted_spans_the_street()
	_drawn_to_sack_piles = draft.drafted_is_drawn_to_sack_piles()
	_role = draft.drafted_role()
	_counts_charges_as = draft.drafted_charges_counted_as()
	_look = draft.drafted_look()
	_body = draft.drafted_body()
	_field = draft.drafted_field()
	_warning = draft.drafted_warning()
	_route = draft.drafted_route()
	_flock = draft.drafted_flock()
	_hold = draft.drafted_hold()
	_lethal = draft.drafted_lethal()
	_pursuit = draft.drafted_pursuit()
	_notice = draft.drafted_notice()
	_hunts = draft.drafted_hunt()
	_hunting = draft.drafted_hunting()
	_vehicle = draft.drafted_vehicle()
	_abduction = draft.drafted_abduction()
	_aftermath = draft.drafted_aftermath()

## **A new draft holding every setting and part of this row**: how every copy of a row is made.
## The row keeps the draft it was built from (`_draft`), so a copy is a copy of that draft: one
## list of settings (`EventDraft.copy()`) and none to keep in step here. The copy changes the parts
## it differs in on the draft and builds it again (`draft.field(def.field().at_peak(rate))`); the
## parts it keeps are the row's own values, shared, which nothing changes. A row is never changed
## after it is built.
func redraft() -> EventDraft:
	return _draft.copy()

## The draft this row was built from: `EventDraft.build()` hands it a copy no other draft shares.
var _draft: EventDraft

## The row's name, the key the catalogue, a plan, a save and the run log know it by.
var _id: String

func id() -> String:
	return _id

var _kind: GameEnums.EventKind

## Whether it is a row of `kind`: what the catalogue picks the day's rows of one kind by.
func is_of_kind(kind: GameEnums.EventKind) -> bool:
	return _kind == kind

## **How it is drawn** (`LookSpec`): its picture, the picture it warns in, whether it casts a
## shadow, whether it trails a lead, whether its hold hides all of it, whether a rider of it may be
## the pelican and the sides its guards stand on. Written by the draft (`EventDraft.look()`); asked
## through `look()` and the questions below. Every visible row states its own picture;
## `tests/test_events.gd` names the three that are legitimately invisible.
## `LookSpec.none()` is a row with no picture.
var _look: LookSpec

## How it is drawn, for the code inside the events folder that runs one look (`LookSpec`).
func look() -> LookSpec:
	return _look

var _ambient_source: AmbientSource

## What makes an ambient row's instances (`AmbientSource`): `NONE` for any other row.
func ambient_source() -> AmbientSource:
	return _ambient_source

## What the run log calls one of it and several of it, for a pursuer on foot whose line names him
## ("a policeman", "two guardsmen"): `EventsAhead`'s poster-tear and vehicle notes. Empty for any
## other row.
var _noun: String
var _noun_plural: String

## What the run log calls `count` of it: `_noun` for one, `_noun_plural` for more.
func noun_for(count: int) -> String:
	return _noun if count == 1 else _noun_plural

## **What it is on the ground**: its shape, whether it is solid and in which pieces, when it is solid,
## what a crowd walker takes it for, whether it parks and how it lies on its street, as one value
## (`BodySpec`). Written by the draft (`EventDraft.body()`); asked through `body()` and the
## questions below that forward to it. A row that says nothing has none: no shape, nothing solid,
## and not yet saying what it stands as or whether it parks, which `validate()` refuses.
var _body: BodySpec

## Its body (`BodySpec`), for the code in the events folder that runs one ability: a copy that
## changes it asks it for a new value (`draft.body(def.body().reshaped(shape))`).
func body() -> BodySpec:
	return _body

## Its ground shape: the datum its shadow and its solid body are both derived from, or null for a
## row with no picture.
func ground_shape() -> GroundShape:
	return _body.ground_shape()

## Whether it has a body at all (`BodySpec.has_a_body()`): something she is stopped by, rather than
## a figure she walks up to or a picture flat on the ground.
func has_a_body() -> bool:
	return _body.has_a_body()

## The furthest any actual body of this row reaches from its own centre (`BodySpec.solid_reach()`):
## where her centre comes to rest, which is less than `obstructs_within()` for a row solid in pieces.
func solid_reach() -> float:
	return _body.solid_reach()

## Whether it moves along a route of its own (`RouteSpec.moves()`).
func moves() -> bool:
	return _route.moves()

## How fast it moves along its route, in px/s, or 0 for a row that stays where it is placed
## (`RouteSpec.speed()`).
func speed() -> float:
	return _route.speed()

## Day gating, 1-based and inclusive. `last_day = 0` means it never expires.
var _first_day: int
var _last_day: int
## For SCRIPTED events: the exact day it fires.
var _scripted_day: int

## Relative likelihood: how often the row is drawn against the others, in a unit's bag (before
## the view's own weight for its role and the row's weight on the unit's ground, `UnitFills`), in
## the moments (`DawnMoments`) and in her route's bag (`EventDirector`). Read through
## `drawn_as_often()`.
var _weight: float

## **How often the row is drawn against the others**, its `_weight`: in a unit's bag, before the
## view's own weight for its role and the row's weight on the unit's ground (`UnitFills`).
func drawn_as_often() -> float:
	return _weight

## **How many times its `_weight` the row weighs on each kind of ground it is set for**
## (`PlacementGround.Kind` -> times), set by the catalogue (`EventDraft.weighed_on()`). A copy of
## the row keeps it, since a copy is a draft started from the row (`redraft()`) and the draft
## carries it.
var _ground_weights: Dictionary

## **How many times its `_weight` the row weighs on `ground`** (`UnitFills`): what the catalogue
## set (`EventDraft.weighed_on()`), else one where the row's `_placement` holds a tile of that
## ground (`PlacementGround.holds()`), else nothing.
func weight_on(ground: PlacementGround.Kind) -> float:
	if _ground_weights.has(ground):
		var times: float = _ground_weights[ground]
		return times
	return 1.0 if _stands_on_ground(ground) else 0.0

## Whether the row's `_placement` holds a tile of `ground` (`PlacementGround.holds()`).
func _stands_on_ground(ground: PlacementGround.Kind) -> bool:
	for type in _placement:
		if PlacementGround.holds(ground, type as GameEnums.TileType):
			return true
	return false

## **Whether the row is weighed on ground none of its `_placement` tiles lies on**, which
## `validate()` refuses: a weight there would read as a row drawn on that ground and draw nothing.
## Public so a test can ask it of a bad row, as `is_a_one_shot_off_her_way()` is, since
## `validate()`'s refusal is a `push_error`, which fails the whole run.
func is_weighed_on_ground_it_cannot_stand_on() -> bool:
	for ground: int in _ground_weights:
		if not _stands_on_ground(ground as PlacementGround.Kind):
			return true
	return false

## **The most of the row a day stands** (`_max_per_day`) where something counts it across the day:
## the moments the dawn owes her (`DawnMoments`), the director's marbles and the rows of a scene
## recipe that no unit draws (`SceneRecipeRuntime`). A unit's draw counts nothing across the day;
## it holds one of a row in the unit (`MarbleDraw`).
func most_in_a_day() -> int:
	return _max_per_day
var _max_per_day: int

## Tile types an instance may be placed on.
var _placement: Array[int]

## **The noise it adds**: the field of excitement the baby is charged for, as one value (`FieldSpec`).
## Written by the draft (`EventDraft.field()`); asked through `field()` and the questions below that
## forward to it. A row that says nothing has the catalogue's plain field.
var _field: FieldSpec

## Its field (`FieldSpec`), for the code in the events folder that runs one ability: a copy that
## changes it asks it for a new value (`draft.field(def.field().at_peak(rate))`).
func field() -> FieldSpec:
	return _field

## **A planned row that comes again**, on its plan's own clock (`EventManager`): seconds from one
## of its instances coming to the next coming, kept on the clock whatever the last one did. 0 for a
## row that comes once. A plan may carry its own (`EventPlan.comes_again_every()`), as each of
## the basement's vents keeps its own period.
var _repeat_every: float
## Seconds from one of a planned row's instances being done — finished, or leaving the end of its
## route — to the next coming: the masked man, another of whom comes up the shaft this long after
## the last has run out of the top of it. 0 for a row that does not wait on its last one.
var _repeat_after: float

var _duration: float

## Seconds it lasts at full strength: 0 for a row that lasts the whole day. For a pursuer, the
## length of the chase, counted from the moment it notices her.
func lasts_for() -> float:
	return _duration

var _spawn_mode: SpawnMode

## **How the row is sited and noticed from the day after its first appearance**, or null for a row
## that is the same every day (see `DaySwitch`). `charging_dog` is the one row that carries it. Read
## through `spawn_mode_on()` and `_notice_on()`, never by hand.
var _from_day_after: DaySwitch

## Which `SpawnMode` this row is sited in on `day`: its own spawn mode through the day
## switch's `after_day()`, the switch's own past it. Every reader that sites an event by its
## day asks this.
func spawn_mode_on(day: int) -> SpawnMode:
	if _from_day_after and day > _from_day_after.after_day():
		return _from_day_after.spawn_mode()
	return _spawn_mode

## Whether `day` is past the day this row's siting switches (`_from_day_after`): false for
## a row with no switch. `charging_dog` is sprinkled into the route only once its first
## siting has switched.
func is_past_its_switch_on(day: int) -> bool:
	return _from_day_after != null and day > _from_day_after.after_day()

## How this row notices her on `day`: its own notice settings through the day switch's
## `after_day()`, the switch's own past it. An instance asks the def it was handed
## (`waits_for_her()`, `notice_within()`), so a placement past the switch is handed a copy
## carrying this (`for_day()`); a director-sited row keeps its own.
func _notice_on(day: int) -> NoticeSpec:
	if _from_day_after and day > _from_day_after.after_day():
		return _from_day_after.notice()
	return _notice

## A `MAP` placement's own answer to `_notice_on(day)`: a derived copy, since the catalogue's rows
## are shared by every day of the run and a placement past the switch cannot set the shared
## row's notice. An instance asks the def it was handed. This row itself for every
## row whose notice does not change by day.
func for_day(day: int) -> EventDef:
	var that_day := _notice_on(day)
	if that_day == _notice:
		return self
	var draft := redraft()
	draft.notice(that_day)
	return draft.build()

## **Where her walk sites this row**, or null for a row the dawn places — see `OnHerWay`.
var _on_her_way: OnHerWay

## **How the director sends this row ahead of her on an ordinary day**, or null for a row it does
## not send (`SentAhead`): the dog walker, the police patrol and the military convoy. A row with one
## is drawn by no unit (`is_drawn_by_units()`), is a marble of her route's bag (`EventDirector`) and
## counts among the moments the dawn owes her (`DawnMoments`). Whatever else places the row (the
## escape's bag, a scene recipe, a happening) reads none of it. Written by the draft
## (`EventDraft.sent_ahead()`).
var _sent_ahead: SentAhead

## Whether the director sends it ahead of her on an ordinary day (`EventDraft.sent_ahead()`).
func is_sent_ahead() -> bool:
	return _sent_ahead != null

## Whether the director warns of it first in the lane of the road beside her when it sends it
## ahead of her (`SentAhead.is_warned_first()`, a row of the road, `keeps_to_the_carriageway()`):
## the convoy.
func is_warned_in_its_lane() -> bool:
	return _sent_ahead != null and _sent_ahead.is_warned_first() and keeps_to_the_carriageway()

## **Whether it keeps to the carriageway as it goes**: a row of the road (`_placement` names
## `ROAD`), the patrol and the convoy, whose route worked out as it goes drives from junction
## box to junction box (`WayOn`). Any other walks.
func keeps_to_the_carriageway() -> bool:
	return _placement.has(GameEnums.TileType.ROAD)

## **The copy the director sends** (`EventDraft.sent_ahead()`): one created at once comes
## `TOWARD_PLAYER`, down her sidewalk on foot (the dog walker) or down the carriageway beside her
## (the patrol), with no badge (`telegraphs_its_coming()` false: a row the director creates at once
## just out of sight is met as it comes, which the rule gives both anyway, each slower than a walk
## and neither lethal, PLAYTEST-145 18-23); one warned of first is its `as_warned_first()` copy,
## still `MAP`, since its 300px field is wider than a `TOWARD_PLAYER` row may be (the convoy).
## Validated as it is made.
## Itself for a row the director does not send.
func as_sent_ahead() -> EventDef:
	if _sent_ahead == null:
		return self
	if _sent_ahead.is_warned_first():
		return as_warned_first()
	var draft := redraft()
	draft.sited(SpawnMode.TOWARD_PLAYER)
	draft.warning(_warning.unannounced())
	var variant := draft.build()
	variant.validate()
	return variant

## **How the row warns of its coming** (`WarningSpec`): the seconds of telegraph it gives, whether it
## holds still through them, whether its coming is announced at the screen edge, whether it is warned
## of before it exists, and the notice its badge gives from off screen. Written by the draft
## (`EventDraft.warning()`); asked through `warning()` and the questions below.
## The default is a telegraph of `WarningSpec.DEFAULT_SECONDS`, announced.
##
## Two readings of the notice, by how the row arrives:
##
## - **A pursuer warned of before it exists** (`charging_dog` sent at her on the day it teaches the
##   run, the resistance's own `robber_giving_chase` and `van_guard_giving_chase`): its badge, up
##   alone with nothing in the world, before it is placed just out of sight (`warned_for()`). Its
##   telegraph is then the approach she watches.
## - **A row created at once from off screen** (the patrol the director sends ahead of her down
##   the road, `EventDirector._toward_her_on_the_road()`): seconds of closing beyond the edge of the
##   view it is never created nearer than (`nearest_it_is_created()`, `Offscreen.min_lead()`).
##
## A non-pursuer warned of before it exists (`cyclist`, the fire engine, day 13's column) does not
## read it: its badge is its telegraph (`warned_for()`). Nothing but the part's own factory and the
## row's copies write it.
var _warning: WarningSpec

## How the row warns of its coming, for the code inside the events folder that runs it
## (`WarningSpec`).
func warning() -> WarningSpec:
	return _warning

## **How the row travels** (`RouteSpec`): whether it moves along a route of its own, how fast, how
## the route is built and how long, whether it paces a beat on it, and whether it stops where it
## arrives. Written by the draft (`EventDraft.route()`); asked through the questions below.
## `RouteSpec.none()` stays where it is placed, which is every row that does not move.
var _route: RouteSpec

## How the row travels, for the code inside the events folder that walks it (`RouteSpec`).
func route() -> RouteSpec:
	return _route

## How fast it removes itself from the scene when it is over, in px/s.
##
## **Nothing vanishes while you are looking at it.** Anything **mobile** leaves at its own route
## speed. This field is for the rest: a flock that has to fly off, a dog that has lost interest and
## trots away. Zero means it simply ends, which is right for a *place* rather than a moment: a cafe
## does not walk home.
var _departs_at: float

## **How many creatures the row is and how far they spread** (`FlockSpec`): a row that is several
## bodies rather than one thing drawn several times. Written by the draft (`EventDraft.flock()`);
## `FlockSpec.none()` is every row that is one body.
var _flock: FlockSpec

## How many creatures the row is and how far they spread, for the code inside the events folder that
## wheels them (`FlockSpec`).
func flock() -> FlockSpec:
	return _flock

## What it leaves at, which is its own speed if it had one. See `EventInstance._be_done`.
func departure_speed() -> float:
	if _departs_at > 0.0:
		return _departs_at
	return _route.speed()

## **How it comes after her**, or null for a row that does not pursue (see `PursuitSpec`).
##
## Pursuit is what makes running ever the right move: running costs more than walking against
## everything that merely emits, so it is right only if the alternative is losing the day. A pursuer
## is lethal, faster than a walk and slower than a run. One kind is a cost rather than the end of the
## day: the man an investigating patrol car lets out, whose catch is a stop
## (`PursuitSpec.stop_excitement()`).
var _pursuit: PursuitSpec

## How it comes after her (`PursuitSpec`), or null for a row that does not pursue (`pursues()`
## says which): for the code in the events folder that runs the chase and its warning.
func pursuit() -> PursuitSpec:
	return _pursuit

## **How it notices her**, or null for a row with no wait (see `NoticeSpec`). A row with none is a
## moment from the frame it exists (`charging_dog` sited ahead of her on the day it teaches the
## run); a row with one is a place that becomes a moment when she walks up to it. Read off the def
## an instance was handed; a row whose notice changes by day says so with `_from_day_after`
## (`_notice_on()`).
var _notice: NoticeSpec

## How it notices her (`NoticeSpec`), or null for a row with no wait (`waits_for_her()` says
## which): for the code in the events folder that runs the wait.
func notice() -> NoticeSpec:
	return _notice

## **How this row hunts her once the resistance has heated it** (`HuntSpec`): a vehicle that lets
## men out, or a man who pursues her himself. Authored on the cold row of every `PRESSES` and `HUNTS`
## row; `at_heat()` attaches it to the copy (`_hunting`) at and past its rung's threshold. Null
## for a row that answers to nothing.
var _hunts: HuntSpec

## **The hunting behaviour this copy carries**: the row's `_hunts`, attached by `at_heat()` at and
## past its rung's threshold, or null on every cold row and on a heated copy below its threshold.
var _hunting: HuntSpec

## Whether this copy is a vehicle that stops for her and lets men out (`_hunting` with
## `HuntSpec.lets_out()`), which `EventInvestigation` runs.
##
## **A vehicle that investigates: once it notices her it stops and lets men out on foot, who pursue
## her; the vehicle itself never chases** (merry-stork). Heated copies carry it, each made by
## `at_heat()`, with a `_notice` it notices her within, along a clear line as every notice is
## (`EventInvestigation`):
##
## - **`police_patrol`'s heated copy past `HEAT_INVESTIGATES_LEVEL`**, a car that drives: it drives
##   its route until it notices her, and stops on its route at once, **never inside a junction
##   box**: noticed with its body in one, it drives on until the body is clear of it and stops
##   there. It lets one man out; once he is back in, the car drives on along its route as a patrol
##   does, and the end of its route is where it leaves. Its man's catch costs her and never ends
##   the day by itself (`PursuitSpec.stop_excitement()`).
## - **`night_raid`'s and `abduction`'s hunting copies**, vans that stand at the kerb: they stop
##   nowhere, since they never move, and let two men out, whose catch ends the day; men who give up
##   walk back, and the van stands where it stood. No vehicle chases her like a running man; the van
##   keeps whatever catch it has cold.
##
## **It is not a pursuer**, so `validate()` refuses the two together: the vehicle stands, as a car
## stands for her, while its men (`EventCatalogue.out_of_the_car()`, a policeman through day 8 and
## a guardsman from day 9, put down at its door on her side by `EventManager`) pursue her under the
## pursuit contract and walk back to it when they are done. While a car stands for them it is not
## driving, so it neither warns nor strikes.
func investigates() -> bool:
	return _hunting != null and _hunting.lets_out() > 0

## How many men this copy lets out once it stops for her (`HuntSpec.lets_out()`), or 0.
func lets_out() -> int:
	return _hunting.lets_out() if _hunting else 0

## How far round its position its body stops her (`BodySpec.obstructs_within()`), or 0 for a row that stops
## nothing: what the walked-sidewalk rule reads of a body (`RouteSidewalkRule`).
func obstructs_within() -> float:
	return _body.obstructs_within()

## **Whether this row is a one-shot not sited from her walk**, which `validate()` refuses: a one-shot
## is a set piece, which has to be met wherever she goes, so one without `_on_her_way` would
## stand in one place and be met only if she walked there. Public so a test can ask it of a bad
## row, since `validate()`'s refusal is a `push_error`, which fails the whole run.
func is_a_one_shot_off_her_way() -> bool:
	return _kind == GameEnums.EventKind.ONE_SHOT and _on_her_way == null

## **Whether a unit's draw can draw the row on `day`** (`DawnDraw`, and a scene recipe's
## placement, which lays a row as the day does): a recurring row placed on the map, so one a day's
## dawn gives a marble in its view's bag. The moments' rows (director-sited), the rows the director
## sends ahead of her (`is_sent_ahead()`) and the one-shots are not, and neither is the row the
## roadblock phase stands that day, `beside_the_routes` (its id, `""` for none: the phase's alone,
## `ResistanceSteps.guarded_row_on()`).
func is_drawn_by_units(day: int, beside_the_routes: String) -> bool:
	return _kind == GameEnums.EventKind.RECURRING and spawn_mode_on(day) == SpawnMode.MAP \
			and not is_sent_ahead() and (beside_the_routes == "" or _id != beside_the_routes)

## **Whether a recurring row the day draws is handed to her walk to site** (`_on_her_way`, the
## sidewalk poster crew): a unit draws it like any other and hands it on with no position for
## the walk to put on her way (`MarbleDraw.draw()`). Asked too by the park
## spoilers, which offer none such, since a park it spoiled would be left empty.
func is_handed_to_her_walk() -> bool:
	return _on_her_way != null and _kind == GameEnums.EventKind.RECURRING

## Whether her walk places the row rather than the dawn or a unit's draw (`_on_her_way`).
func is_sited_from_her_walk() -> bool:
	return _on_her_way != null

## Whether her walk stands it at a building's front it pastes (`OnHerWay.pastes_a_front()`).
func stands_at_a_front() -> bool:
	return _on_her_way != null and _on_her_way.pastes_a_front()

## Whether it is the set piece a run owes: a one-shot her walk places.
func is_a_set_piece_on_her_way() -> bool:
	return _on_her_way != null and _kind == GameEnums.EventKind.ONE_SHOT

## Whether it is a loudspeaker mast (`Role.MAST`).
func is_a_mast() -> bool:
	return _role == Role.MAST

## Whether it is scenery (`Role.SCENERY`): a row that is part of the street's furniture, never a
## wall or a piece of friction the day places for its cost.
func is_scenery() -> bool:
	return _role == Role.SCENERY

## Whether it is a one-shot (`GameEnums.EventKind.ONE_SHOT`): a set piece a day owes once.
func is_a_one_shot() -> bool:
	return _kind == GameEnums.EventKind.ONE_SHOT

## Whether the row stands on a tile of `type` (`_placement`).
func stands_on(type: GameEnums.TileType) -> bool:
	return _placement.has(type)

## The kinds of tile the row stands on (`_placement`), as a copy, so nothing writes the row through
## it.
func ground_kinds() -> Array[int]:
	var kinds: Array[int] = []
	kinds.assign(_placement)
	return kinds

## The lane of the sidewalk the row wants (`_pavement_side`).
func sidewalk_lane() -> Pavement:
	return _pavement_side

## Whether the row draws itself as a spread laid along its street's axis (`BodySpec.Lie.SPREAD`), so a
## corner, which belongs to two streets at once, is no ground for it.
func lies_as_a_spread() -> bool:
	return _body.lies() == BodySpec.Lie.SPREAD

## Whether it leaves the building it stands against burnt: its scar is the burnt shell's
## (`EventCatalogue.BURNT_SHELL_ID`), so the front it catches on has to be one that can be drawn
## burnt.
func burns_its_front() -> bool:
	return _aftermath.leaves_the_scar(EventCatalogue.BURNT_SHELL_ID)

## The id of the row it calls in the moment it is first seen (`Aftermath.calls_in()`), or "" for a row
## that calls none: the burning building calls the fire engine in.
func calls_in() -> String:
	return _aftermath.calls_in()

## Seconds after one of its instances ends that the next comes, or 0 for a row that does not come
## again on a clock (`_repeat_after`). A plan made of it starts from this.
func comes_again_after() -> float:
	return _repeat_after

## **The first day the row may be used as a seal**, which ordinary availability (`available_on()`)
## cannot say for a `SCRIPTED` row: its `_scripted_day` is a day nobody plays, `barricade`'s own is
## 0, so the ordinary scheduler never rolls it, on purpose. A `SCRIPTED` row's own day is the
## first day of its act (`_act_tag`, the act the row belongs to narratively), the smallest way to
## give it a day at all. Every other row's is its `_first_day`.
func own_first_day() -> int:
	if _kind == GameEnums.EventKind.SCRIPTED:
		var index := clampi(_act_tag - 1, 0, Tuning.ACT_START_DAYS.size() - 1)
		return Tuning.ACT_START_DAYS[index]
	return _first_day

## Its notice radius, or 0 for a row with no wait: the number every "how close before it notices"
## rule reads.
func notice_within() -> float:
	return _notice.within() if _notice else 0.0

## Its chase speed, or 0 for a row that does not pursue.
func chase_speed() -> float:
	return _pursuit.speed() if _pursuit else 0.0

## Whether its pursuer, cold or hunting, leaves its body standing when he sets off
## (`PursuitSpec.leaves_its_body_standing()`): the roadblock's, whose cold row carries it on its hunt.
func leaves_its_body() -> bool:
	var chase := _pursuit
	if chase == null and _hunts != null:
		chase = _hunts.pursuit()
	return chase != null and chase.leaves_its_body_standing()

## Whether its pursuer walks round buildings toward her once he is after her
## (`PursuitSpec.walks_round_buildings()`): the roadblock's hunting copy, whose posted guard follows
## her round a corner. False for a row that does not pursue.
func walks_round_buildings() -> bool:
	return _pursuit != null and _pursuit.walks_round_buildings()

## Whether it pursues with a chase that begins in `start`'s way.
func starts_by(start: PursuitSpec.Start) -> bool:
	return _pursuit != null and _pursuit.start() == start

## How this row answers to the resistance.
##
## **The city gets worse the further into the subquest you are**, and this is the whole of how a row
## says so. `RunState.resistance().progress()` is an integer 0..`Tuning.RESISTANCE_GOAL`, and
## `at_heat()` below turns a level into a **derived copy** of the row with its numbers moved, so
## nothing downstream of the day's plan has to know that heat exists: an `EventInstance` asks
## its peak, `pursues()` and the rest of whichever copy the day handed it.
##
## **It is a field rather than a switch set per placement**, as the blocking role is:
## `EventScheduler.role_for` derives a role from the def, so no two placements of one row can
## disagree about what it is, and heat is no difficulty dial hidden inside the placement code.
##
## **The set of shapes is finite on purpose.** Progress has a known ceiling, so every heated shape
## of every row exists at boot and `EventCatalogue.all()` validates all of them. A def that mutated
## mid-run would be checked in the shape it booted in, and the fairness contract would not be
## stated about the dangerous one.
##
## **A row answers to heat exactly when it says how it hunts** (`_hunts`, a `HuntSpec` that
## carries its rung): `HuntSpec.pressing()` is the rung of more of them, more expensive to stand
## near, that investigates past a threshold and never ends the day, and `HuntSpec.letting_out()`
## and `HuntSpec.pursuing()` are the lethal rung. A row without one answers to nothing:
## everything in act I, a cat does not care who you know.
func answers_to_heat() -> bool:
	return _hunts != null

## Whether, at the heat that hunts, it stops being a place and starts being a hunter, the lethal
## rung (`HuntSpec.presses()` false): `roadblock`'s guard and the two vans.
func hunts_for_her() -> bool:
	return _hunts != null and not _hunts.presses()

## **A car that drives**, or null for anything else — see `VehicleSpec`: `police_patrol` and every
## copy of it, and `fire_truck`.
var _vehicle: VehicleSpec

## Which lane of a two-tile sidewalk an event wants. Almost nothing cares, and `ANY` is the default.
## Two things do, because the lane makes sense of the thing: a parked van belongs at the kerb rather
## than *in a traffic lane*, and a lorry reversing into a yard has to be backing into a building.
enum Pavement {
	ANY,
	## Against the kerb, with the carriageway on the other side of it. Where a vehicle parks.
	AT_THE_KERB,
	## Against the frontage, with a building wall behind it. Where a lorry backs in.
	AGAINST_THE_BUILDING,
	## The frontage lane of an east-west street's north sidewalk, in front of the south face of the
	## lot behind it, the one face of a building the city draws. Where a fire catches, so the
	## building it burns is the one drawn burnt afterwards (`burning_building`'s own
	## `_pavement_side`), and where a poster crew pastes (`SitedGround` asks it for a
	## row whose `OnHerWay.pastes_a_front()` is set).
	AT_THE_FRONT,
}

var _pavement_side: Pavement

## **What the row holds her for when she comes to it** (`HoldSpec`): the seconds her controls are
## taken, how far past its own solid edge she has to come, and whether it takes her again. Written
## by the draft (`EventDraft.hold()`); asked through the questions below.
## `HoldSpec.none()` holds nobody, which is every row but `chatting_mother` and a door's hut and post.
##
## **The one mechanic in the catalogue that takes the controls away rather than costing a meter.**
## Everything else that stops her is a choice, which is why `validate()` refuses it on anything
## that ends the day or has a `_pursuit`. See `Stroller.detain()` for the lock itself, which
## runs out through the ordinary friction rather than stopping her dead.
##
## **The reach is stated over the body rather than over her** (`detain_distance()`): a radius from the
## middle has to be bigger than whatever she pushes in front of her, so it silently switches the
## mechanic off the day that changes (PLAYTEST-57). Checked by `validate()` against `core_within()`:
## the capture has to sit strictly inside the field she is already fully charged for.
## `chatting_mother` carries no body (nothing mobile may), so her 48px is a radius from her centre,
## chosen against the **32px** spacing between the two lanes of a sidewalk (`Tuning.TILE_SIZE`):
## under that, the far lane of a two-tile sidewalk is never inside it, whatever a pacing route does,
## and distance stays the counterplay.
var _hold: HoldSpec

## What the row holds her for, for the code inside the events folder that runs a hold (`HoldSpec`).
func hold() -> HoldSpec:
	return _hold

## How close her own centre has to come to this instance's centre for the conversation to start:
## the hold's reach past the solid edge she cannot walk through. The one form
## `CheckpointController.check_detentions()` and `CheckpointController._release_finished_holds()`
## both measure.
func detain_distance() -> float:
	return obstructs_within() + _hold.past_its_edge()

## Whether a placement of this row takes a whole section of its street rather than one sidewalk
## location (inbox #1185 in gentle-owl: "events that span the street get placed in a section (eg roadblock in the
## middle of the street)"). `roadblock` alone today. Read through `spans_the_street()`.
var _spans_the_street: bool

## Whether the row stands by a garbage-sack pile when the ground lets it (`is_drawn_to_sack_piles()`):
## the alley mouse alone. Read through that method.
var _drawn_to_sack_piles: bool

## **Whether this row would rather stand beside a garbage-sack pile** (`GarbageSacks.alley_pile_tiles()`):
## where the location it is drawn at reaches a pile, the location weighs more (`LocationGround.scale()`)
## and the row is offered the tiles beside the pile first. Whether it is *drawn at all* is its weight's
## question, never this one's.
func is_drawn_to_sack_piles() -> bool:
	return _drawn_to_sack_piles

## **Whether this row takes a whole section of a street** when it is placed, its two sidewalk
## locations with it (`DayLocations.assign()`), rather than one sidewalk location.
func spans_the_street() -> bool:
	return _spans_the_street

## **How much of a street a row takes up when a street draws it** (`UnitRoom`, `MarbleDraw`), of
## the player's three sizes (inbox #1466 in silky-lemur: a marble that takes the whole street ends its draw, one
## that takes a segment leaves at least two more draws, and one smaller than a segment is followed
## by another small one): one sidewalk location or one whole section. Nothing a street draws **on a
## day** takes the whole street: the rows that would, the police patrol and the military convoy, are
## sent ahead of her by the director (`is_sent_ahead()`) and drawn by no unit; the escape's truck
## takes a section.
enum StreetShare { A_LOCATION, A_SECTION }

## **What the row takes of a street**, read off its ground, never set: a section where it stands on
## the carriageway (it spans the street), else one sidewalk location, whatever its path along it. A
## row a street draws takes a section only while the street has that much room left (`UnitRoom`).
func takes_of_a_street() -> StreetShare:
	if not _placement.has(GameEnums.TileType.ROAD):
		return StreetShare.A_LOCATION
	return StreetShare.A_SECTION

## **Whether its catch ends the day, and where it is measured from** (`LethalSpec`): entering the
## lethal radius ends the day immediately. Written by the draft (`EventDraft.lethal()`); asked
## through `ends_the_day()` and `lethal_reach()`. `LethalSpec.none()` is a row that cannot end
## her day.
var _lethal: LethalSpec

## The row's catch, for the code inside the events folder that runs it (`LethalSpec`).
func lethal() -> LethalSpec:
	return _lethal

## **The distance that ends the day**: the catch's own reach where it sets one (a roadblock's guard
## catches at a man's reach, not at his band's core), the field's own core otherwise. Every caller
## asks this, so none has to know which kind of row it holds.
func lethal_reach() -> float:
	return _lethal.reach_from(core_within())

## What `PursuitSpec.standoff()` is stated over for this row: its `PursuitSpec.lunge_reach()`
## where it sets one, the catch (`lethal_reach()`) otherwise.
func standoff_reach() -> float:
	if _pursuit and _pursuit.lunge_reach() > 0.0:
		return _pursuit.lunge_reach()
	return lethal_reach()

## Whether its lunge is measured from inside its own catch, which would leave her less than
## `PursuitSpec.PURSUIT_REACTION` of the pursuer's approach between its lunge and the moment it takes
## her: the contract `PursuitSpec.standoff()` keeps. `validate()` refuses it; a predicate so
## a test can ask without raising the error.
func lunge_is_inside_the_catch() -> bool:
	return _pursuit != null and _pursuit.lunge_reach() > 0.0 and _pursuit.lunge_reach() < lethal_reach()

## **A part one row plays in a system beside the catalogue**, which that system finds it by rather
## than by its id: a renamed or derived row keeps its role.
enum Role {
	NONE,
	## Exempt from the cost rule's wall and friction placement: `EventScheduler.role_for` answers
	## `NONE` for it before the cost check runs, so `RowGround._times_for_role()` neither pulls it off the corridor
	## nor weights it onto one, and it lands on whatever tile the roll picks, as an ambient event or
	## a scar does. `pigeon_flock` is the row it exists for: a 42-over-168px field crosses
	## `EventScheduler.WALL_WORTH_OF_COST` and would otherwise be pulled off every route like any
	## other expensive row, though flocks are scenery.
	SCENERY,
	## **The loudspeaker mast**, which the masts' sites (`MastSites`), the day's masts and the
	## resistance's mast task find by this role (`EventCatalogue.mast()`). The curfew announcement
	## shares a mast's foot and is not one.
	MAST,
}

var _role: Role

## **It takes a bystander first**, or null for a row that takes nobody — see `AbductionSpec`:
## `_abduction`, the unmarked van.
var _abduction: AbductionSpec

## How it takes a victim (`AbductionSpec`), or null for a row that takes nobody: what the van's look
## draws the walk and the standing place from.
func takes_a_victim_by() -> AbductionSpec:
	return _abduction

## The name its charges are counted under when it is not its own id
## (`EventInstance._charger_name()`): `task_guard` for the task guard sent from out of her view,
## whose charges are the task guard's. `""` for every other row.
var _counts_charges_as: String

## The name its charges are counted under when it is not its own id, or `""` for a row counted
## under its own.
func charges_counted_as() -> String:
	return _counts_charges_as

## **The rows this one brings after it** — see `Aftermath`; empty for a row that brings none.
var _aftermath: Aftermath

## Which act a **scripted** row belongs to, narratively (`EventDraft.scripted_on()` writes it): the
## one thing it is read for is `own_first_day()`, the first day of its act. A row of any other kind
## says no act, and nothing asks it one: `_first_day` decides when such a row can appear.
## `tests/test_acts.gd` holds a scripted row's own first day against the day it fires on.
var _act_tag: int

## This row as it is at a given resistance level, which is `self` for almost everything.
##
## `level` is `RunState.resistance().progress()`, clamped here rather than by the caller: it can reach
## five over the five tasks while `Tuning.RESISTANCE_GOAL` is the four that qualify, and full heat is
## the qualification rather than the last errand.
##
## **A derived copy, never a mutation.** The catalogue's rows are shared by every day of the run and
## validated once at boot. `EventCatalogue.at_heat()` caches these, so a level costs one copy
## per row per run rather than one per placement.
func at_heat(level: int) -> EventDef:
	if not answers_to_heat() or level <= 0:
		return self
	var through := clampf(float(level) / float(Tuning.RESISTANCE_GOAL), 0.0, 1.0)
	var hot := redraft()
	var hunts_from := HEAT_HUNTS_LEVEL
	var notices_within := HEAT_HUNTS_WITHIN
	if _hunts.presses():
		# More of them, and more expensive to be near. Population is the axis that changes the
		# *route*, and intensity is what makes one of them worth planning around. Below its own
		# threshold a `HUNTS` row is untouched: that rung answers a different question, not *how much
		# does it cost to be near* but *can I still be near it at all*.
		var most := maxi(_max_per_day,
				roundi(_max_per_day * lerpf(1.0, HEAT_PRESSES_POPULATION, through)))
		# And as many more marbles in the day's bags: a cap a draw rarely reaches would raise no
		# population, so the row's weight, which sets how often a unit draws it, rises with it.
		hot.drawn(_weight * lerpf(1.0, HEAT_PRESSES_POPULATION, through), most)
		hot.field(_field.at_peak(peak() * lerpf(1.0, HEAT_PRESSES_INTENSITY, through)))
		hunts_from = HEAT_INVESTIGATES_LEVEL
		notices_within = HEAT_INVESTIGATE_WITHIN
	if level < hunts_from:
		return hot.build()
	# **At its rung's threshold the copy takes the row's hunt** (`_hunts`, `HuntSpec`) and
	# notices her at the rung's own distance: a vehicle stops on its road, or stands where it
	# is, and lets its men out (`investigates()`), keeping its cold row's catch; or a man
	# pursues her himself.
	hot.hunting(_hunts)
	hot.notice(NoticeSpec.at(notices_within))
	if _hunts.pursuit() != null:
		# He hunts as the row says, at the ladder's own speed.
		hot.pursuit(_hunts.pursuit().at_speed(Tuning.HEAT_HUNTS_SPEED))
		# The shared trigger is authored once, against the widest cold field in the catalogue
		# (`abduction`'s 250px); a row whose own field reaches less far would notice her from
		# outside its own field, which `Tuning.validate_pursuit()` refuses. Widening only the hunting
		# copy keeps the cold shape, and everything measured from it (`required_telegraph_time()`,
		# the cost table), untouched.
		hot.field(hot.drafted_field().reaching(maxf(heard_within(), notices_within)))
		# For a pursuer `_duration` is the length of the chase, not the length of the idle (see
		# `_notice`). Cold, this row simply sits for `_duration` seconds and is done.
		hot.lasts(Tuning.PURSUIT_TIME)
	# A hunt whose own catch ends the day (`HuntSpec.ends_the_day()`, the roadblock's guard) gives the
	# copy that catch: a pursuer is exempt from the rule that nothing else happens inside a lethal
	# event's field (`EventPlan.keeps_its_field_clear()`).
	if _hunts.ends_the_day():
		hot.lethal(_hunts.catch())
	return hot.build()

func available_on(day: int) -> bool:
	if _kind == GameEnums.EventKind.SCRIPTED:
		return _scripted_day == day
	if day < _first_day:
		return false
	return _last_day == 0 or day <= _last_day

## Checks the telegraph fairness contract from docs/EVENTS.md.
##
## AMBIENT events are exempt: they are permanent features of a fixed map, so there is no moment they
## appear and nothing to warn about.
func validate() -> bool:
	# **A row that comes again comes from a plan**: a repeat is kept on its plan's clock, and only a
	# `MAP` row has a plan.
	# `MAP` row has a plan to keep it on.
	if _repeat_every < 0.0 or _repeat_after < 0.0:
		push_error("event '%s' repeats after a negative wait" % _id)
		return false
	if (_repeat_every > 0.0 or _repeat_after > 0.0) and _spawn_mode != SpawnMode.MAP:
		push_error("event '%s' repeats but is not MAP-sited: only a plan can bring it again" % _id)
		return false
	if not _body.says_what_it_stands_as():
		push_error(("event '%s' does not say what it stands as (`walked_through()`, `walked_round()` "
				% _id) + "or `unmet()` on its body): a person or an animal, an object or a vehicle, "
				+ "or nothing on the ground")
		return false
	if not _body.says_whether_it_parks():
		push_error(("event '%s' does not say whether it parks once it stands (`parked()` or "
				% _id) + "`going_on()` on its body)")
		return false
	# **The declaration has to agree with how the row moves**: a car turns round behind a parked
	# figure, so a figure that will move again must never read as parked, and one that will not must
	# never be waited for.
	if _route.parks_where_it_arrives() and not _body.parks():
		push_error("event '%s' stops where it arrives and says it goes on: it parks there" % _id)
		return false
	if _body.parks():
		if _route.moves() and not _route.parks_where_it_arrives():
			push_error("event '%s' parks and moves without stopping where it arrives: it has no " % _id
					+ "stand to park at")
			return false
		if _pursuit != null or _flock.is_a_flock():
			push_error("event '%s' parks and chases her or wheels as a flock: it moves again" % _id)
			return false
	# **The body is the shape.** A row that draws something has a shape to draw it from. A solid
	# body's reach is its shape's (`BodySpec.obstructs_within()`), so the two cannot disagree and
	# the body and the picture cannot disagree about where she can walk.
	if _look.picture() != Look.NONE and ground_shape() == null:
		push_error("event '%s' has a look but no shape to draw its shadow and body from" % _id)
		return false
	if _body.is_solid_with_no_shape():
		push_error("event '%s' says its body is solid but has no shape to be solid as" % _id)
		return false
	# **A row solid in pieces is solid inside its own shape and nowhere else.** Every planner reads
	# `obstructs_within()`, the disc bound, and none knows a piece list exists, so a piece reaching
	# past it would be ground nothing ever cleared. Pieces inside the shape can only remove
	# obstruction, which can only add reachable ground. (A piece has a shape by construction:
	# `BodyPiece.at()` takes it.)
	for piece in _body.declared_pieces():
		if piece.reach() > obstructs_within() + 0.001:
			push_error(("event '%s' has a solid part reaching %.1fpx, past the %.1fpx its own shape "
					% [_id, piece.reach(), obstructs_within()])
					+ "claims: nothing cleared the ground it would stand on")
			return false
	# **A core has to be louder than its field and fall to nothing inside it**: a core no louder than
	# the field, a band with nothing in it, or one reaching past the field's own edge (outside the
	# radius every fairness rule is stated over) is a row that reads as having a core and has not
	# got one. Checked before the ambient and city-wide returns, since those rows have a field too.
	if falloff() <= 0.0:
		push_error("event '%s' has a falloff power of %.2f: a field has to fall away from its own "
				% [_id, falloff()] + "centre")
		return false
	if core_rate() > 0.0:
		if core_rate() <= peak():
			push_error(("event '%s' has a %.1f/s core inside a %.1f/s field: a core quieter than "
					% [_id, core_rate(), peak()])
					+ "what it sits in is never the larger of the two and changes nothing")
			return false
		if core_reach() <= core_within() or core_reach() > heard_within():
			push_error(("event '%s' has a core falling to nothing at %.0fpx, outside its own "
					% [_id, core_reach()])
					+ "field's %.0f–%.0fpx band" % [core_within(), heard_within()])
			return false
		if _flock.is_a_flock():
			push_error("event '%s' is %d bodies wheeling and has a core: a flock's field is a sum "
					% [_id, _flock.count()] + "over bodies, and one disc over the top of it prices "
					+ "ground neither shape describes")
			return false
	if _kind == GameEnums.EventKind.AMBIENT:
		return true
	# Neither `AHEAD_OF_PLAYER` nor `TOWARD_PLAYER` has a tile, so the day's route rules
	# (`StreetInvalidation`) cannot check that what it blocks leaves a route to a park. Anything that stands in
	# the way is sited on the map; a transient one that merely *emits* is fine, and so is a lethal
	# one, which appears in front of her and is gone shortly after.
	if _spawn_mode != SpawnMode.MAP and obstructs_within() > 0.0:
		push_error("event '%s' is director-sited and obstructs %.0fpx: nothing checks "
				% [_id, obstructs_within()] + "that it leaves a route to a park")
		return false
	# The same, over the day the row switches to: `spawn_mode_on()` is what every placement asks.
	if _from_day_after and _from_day_after.spawn_mode() != SpawnMode.MAP and obstructs_within() > 0.0:
		push_error(("event '%s' is director-sited from day %d onward and obstructs %.0fpx: "
				% [_id, _from_day_after.after_day() + 1, obstructs_within()])
				+ "nothing checks that it leaves a route to a park")
		return false
	# **A one-shot she has to meet is sited on her way.** A one-shot is a set piece, which has to be
	# met: something she must meet exists wherever she goes, since she can take either way
	# (M50-the-city-points-somewhere). Sited from her walk it is (`_on_her_way`); placed at dawn it
	# would stand in one location and be met only if she walked there, so it is refused until the
	# walk's draw can carry it, a rigged marble on the next location she comes to (placement by
	# construction's walk draws).
	if is_a_one_shot_off_her_way():
		push_error("event '%s' is a one-shot not sited from her walk: a set piece has to be met " % _id
				+ "wherever she goes, and one placed at dawn is met only if she walks there")
		return false
	# **A row is weighed only on ground it can stand on** (`EventDraft.weighed_on()`): a weight on
	# ground none of its tiles lies on would read as a row drawn there and draw nothing.
	if is_weighed_on_ground_it_cannot_stand_on():
		push_error("event '%s' is weighed on a kind of ground none of its placement tiles lies on"
				% _id)
		return false
	# **A row sited from her walk is a `MAP` row that stands still, or it is nothing.** Only
	# `DawnOneShots` and a unit's draw (`MarbleDraw`) leave a plan unplaced
	# for it, and only `EventDirector` sites what they leave. The siting is a tile with the
	# corridor's own questions asked of it, which a director-sited row never has, and a thing that
	# moves has no one place for its scar to be recorded at.
	if _on_her_way:
		if _kind != GameEnums.EventKind.ONE_SHOT and _kind != GameEnums.EventKind.RECURRING:
			push_error("event '%s' is sited from her walk and is neither a one-shot nor " % _id
					+ "recurring: nothing but DawnOneShots and "
					+ "MarbleDraw leaves a plan for her walk to site")
			return false
		if _spawn_mode != SpawnMode.MAP:
			push_error("event '%s' is sited from her walk and is director-sited besides: it is " % _id
					+ "a place chosen late, not a moment with no place at all")
			return false
		if _route.moves():
			push_error("event '%s' is sited from her walk and moves: a row that may be re-sited " % _id
					+ "until it is real needs one place to stop being re-sited at")
			return false
	# A flock is several bodies wheeling inside one disc, with no silhouette for a body to be half
	# of, and being walked into is the event. See `BodySpec`.
	if _flock.is_a_flock() and obstructs_within() > 0.0:
		push_error("event '%s' is %d bodies wheeling and obstructs %.0fpx: a flock has no one "
				% [_id, _flock.count(), obstructs_within()]
				+ "silhouette to be solid at, and being walked into is what it is for")
		return false
	# A row that stops where it arrives (it has a route to run out of:
	# `RouteSpec.parking_where_it_arrives()` asks one) cannot also hand its place to a successor:
	# `_be_done()` cannot do both.
	if _route.parks_where_it_arrives():
		if _aftermath.leaves_behind() != "":
			push_error("event '%s' stops where it arrives and spawns '%s' when it finishes: it "
					% [_id, _aftermath.leaves_behind()] + "does one or the other, never both")
			return false
	# **A pursuer awake from its first frame is never the scheduler's to place.** With no notice its
	# telegraph and its chase are clocked from the moment it exists, so a `MAP` row would spend both
	# wherever the stream put it, off screen. Only a row something sets on her at a moment of its own
	# may have that shape: `SCRIPTED` on day 0, the day nobody plays (`door_guard`,
	# `robber_giving_chase`, `van_guard_giving_chase`). Asked of both days a row can answer, so
	# `charging_dog`, notice-less only while the director sites it, is allowed.
	if _pursuit and not (_kind == GameEnums.EventKind.SCRIPTED and _scripted_day == 0):
		var awake_on_the_map := _spawn_mode == SpawnMode.MAP and _notice == null
		if _from_day_after and _from_day_after.spawn_mode() == SpawnMode.MAP \
				and _from_day_after.notice() == null:
			awake_on_the_map = true
		if awake_on_the_map:
			push_error(("event '%s' is placed on the map and pursues from the moment it exists: " % _id)
					+ "its notice and its chase would run out wherever the stream put it — only a "
					+ "row nothing but a director sets on her (SCRIPTED, day 0) may have no notice")
			return false
	for each_notice: NoticeSpec in [_notice, _from_day_after.notice() if _from_day_after else null]:
		if each_notice and each_notice.within() <= 0.0:
			push_error("event '%s' notices her at %.0fpx: a notice needs a distance" % [_id,
					each_notice.within()])
			return false
	# **A row that answers to the resistance says how it hunts** (`_hunts`), and a `HuntSpec` is
	# built either letting men out or pursuing, never both and never neither, with its rung and
	# its catch beside it: the patrol rung never pursues, and only a hunt that pursues ends the
	# day by its own catch. What no construction rules out is the patrol rung on a row that ends
	# the day itself. A hunt does exactly one of the two: `HuntSpec.new()` builds neither, which
	# no factory does.
	if _hunts != null and (_hunts.lets_out() > 0) == (_hunts.pursuit() != null):
		push_error("event '%s' hunts neither by letting men out nor by pursuing, or both" % _id)
		return false
	if _hunts != null and _hunts.presses() and ends_the_day():
		push_error("event '%s' presses but would end the day or chase her itself" % _id)
		return false
	var waits_on_some_day := _notice != null \
			or (_from_day_after != null and _from_day_after.notice() != null)
	if _pursuit:
		# Standing for a notice is a decision about a pursuer that takes one.
		if _pursuit.stands_for_its_notice() and not waits_on_some_day \
				and _pursuit.start() != PursuitSpec.Start.SETS_OFF_BESIDE_HER:
			push_error("event '%s' stands for a notice it never takes: it neither waits for her nor "
					% _id + "sets off beside her")
			return false
		# A notice walk is a walk at her through a notice it took by waiting, slower than its chase.
		if _pursuit.walk_speed() > 0.0 and (_pursuit.stands_for_its_notice() or not waits_on_some_day
				or _pursuit.walk_speed() >= _pursuit.speed()):
			push_error("event '%s' walks %.0fpx/s through a notice it never walks: it must wait for "
					% [_id, _pursuit.walk_speed()] + "her, not stand, and walk slower than its "
					+ "%.0fpx/s chase" % _pursuit.speed())
			return false
	# Holding a body back through the notice means nothing on a row with no body, and a row with no
	# notice has nothing to hold it back through.
	if _body.solid_from() == BodySpec.SolidWhen.ONCE_IT_STARTS and obstructs_within() <= 0.0:
		push_error("event '%s' waits for its own notice to become solid and has no body" % _id)
		return false
	if _body.solid_from() == BodySpec.SolidWhen.ONCE_IT_STARTS and telegraphs_for() <= 0.0:
		push_error("event '%s' waits for a notice it does not have before it becomes solid" % _id)
		return false
	# A `TOWARD_PLAYER` row is created no nearer her than `nearest_it_is_created()`. So a row whose
	# own field reaches that far would be created already on her on the one heading and moment the
	# director cannot avoid.
	if _spawn_mode == SpawnMode.TOWARD_PLAYER:
		var floor_lead := nearest_it_is_created()
		if heard_within() >= floor_lead:
			push_error("event '%s' comes toward the player with a %.0fpx field, at or past the "
					% [_id, heard_within()] + "%.0fpx it is created at on the worst axis: it would arrive "
					% floor_lead + "already inside its own reach there")
			return false
	# **A lethal radius and a solid body are the same mechanism**, and putting both on one event is a
	# way of turning the first one off. She is stopped with her centre `obstructs_within() +
	# PLAYER_BODY_RADIUS` from his, so if that reaches the inner radius the kill can never fire,
	# a silent difficulty setting. Under it, the body is only ever felt during the telegraph, the
	# phase where the event is not lethal yet.
	#
	# **Stated over `solid_reach()` rather than `obstructs_within()`**, because this is about where her
	# centre actually comes to rest: a row solid only in parts leaves ground inside its own disc that
	# she can walk onto. The two numbers are the same for every row that is one piece.
	#
	# **A pursuer is outside the rule rather than excepted from it**: the inference holds only while
	# the body and the thing that kills are the same point, and a pursuer's is not, because it comes
	# to her. Every one either drops its body the frame it starts hunting or, with
	# `PursuitSpec.leaves_its_body_standing()`, walks out of a body it leaves standing. `tests/test_heat.gd`
	# holds that pair, so the exemption cannot become a loophole for a pursuer that kept its body
	# and carried it along.
	if ends_the_day() and _pursuit == null and solid_reach() > 0.0 \
			and solid_reach() + Tuning.PLAYER_BODY_RADIUS >= lethal_reach():
		push_error("event '%s' is lethal inside %.0fpx and solid to %.0fpx: with her own %.0fpx "
				% [_id, lethal_reach(), solid_reach(), Tuning.PLAYER_BODY_RADIUS]
				+ "she is stopped before she can ever reach it")
		return false
		# A catch out in the falloff band is a catch she can take while the thing is still quiet; the
		# core is the shell at full strength.
	if lethal_reach() > core_within():
		push_error("event '%s' catches at %.0fpx, outside the %.0fpx core of its own field"
				% [_id, lethal_reach(), core_within()])
		return false
		# A conversation is a cost, never a threat: it takes her controls rather than her body, and a
		# row that could also kill or chase her would do both at once.
	if detains_her():
		if ends_the_day() or _pursuit:
			push_error("event '%s' detains and is also %s: a conversation may not also be a threat"
					% [_id, "a place that ends the day" if ends_the_day() else "a pursuer"])
			return false
		if not (detain_distance() < core_within() and core_within() <= heard_within()):
			push_error(("event '%s' detains at %.0fpx (%.0fpx past a %.0fpx body), which does not "
					% [_id, detain_distance(), _hold.past_its_edge(), obstructs_within()])
					+ ("sit inside its own field (inner %.0f <= outer %.0f)"
					% [core_within(), heard_within()]))
			return false
		# **A car that drives is a body that moves and a strike that is not the body** (see
		# `_vehicle`). Each half-set version is a row the rules cannot read: a car with no route
		# stands for ever, a car with no shape has no body, one that also obstructs would be a
		# moving closure every planner reads as standing ground, and one that also ends the day
		# would kill twice over. A vehicle that investigates notices her (`_notice`) and lets
		# men out: one that also pursued would be the vehicle chasing her like a running man,
		# one with no reach never notices, and one with no body has no door to let them out of.
	if investigates() and (_pursuit or _notice == null or ground_shape() == null):
		push_error("event '%s' investigates but is not a vehicle with a reach to notice her in, a "
				% _id + "body to let men out of and men to let out, that stays where it is")
		return false
		# A stop is a pursuer's catch made a cost: a row that also ended the day would do both at
		# once, and one at or over the whole meter would end a calm day by itself.
	if _pursuit and _pursuit.stop_excitement() > 0.0 and (ends_the_day() \
			or _pursuit.stop_excitement() >= Tuning.METER_MAX):
		push_error("event '%s' stops her for %.0f points but is not a pursuer whose catch is only "
				% [_id, _pursuit.stop_excitement()] + "a cost under the whole meter")
		return false
	if _vehicle:
		if not _route.moves() or _route.speed() < Tuning.CAR_STRIKE_MIN_SPEED \
				or ground_shape() == null:
			push_error("event '%s' drives but has no route, speed (%.0f) or shape to drive with"
					% [_id, _route.speed()])
			return false
		if obstructs_within() > 0.0 or ends_the_day():
			push_error("event '%s' drives and is also %s: a car closes no ground and kills only "
					% [_id, "an obstruction" if obstructs_within() > 0.0 else "a place that ends the day"]
					+ "in front of it")
			return false
			# Its warning is the crowd car's contract, `CAR_HORN_TIME` of its own travel ahead of the
			# strike whatever its speed, so `tests/test_tuning_fairness.gd`'s traffic check is its
			# check.
		# A badge up alone is up for at most `Tuning.WARNING_ALONE_MAX`, whatever the row (inbox #569
		# in busy-quail).
	if warns_before_it_exists() and warned_for() > Tuning.WARNING_ALONE_MAX + 0.001:
		push_error("event '%s' is warned of %.2fs before it exists, longer than the %.2fs a badge may be "
				% [_id, warned_for(), Tuning.WARNING_ALONE_MAX] + "up alone")
		return false
	if lunge_is_inside_the_catch():
		push_error("Unfair pursuit '%s': its lunge is measured from %.0fpx, inside its own %.0fpx catch"
				% [_id, _pursuit.lunge_reach(), lethal_reach()])
		return false
	# A row that runs its own line once she is near is a mobile row that does not pursue and notices
	# her from further than it runs.
	if _notice and _notice.runs_within() > 0.0 \
			and (_pursuit or not _route.moves() or _notice.within() <= _notice.runs_within()):
		push_error("event '%s' runs within %.0fpx but is not a mobile row that waits for her "
				% [_id, _notice.runs_within()] + "from further than that")
		return false
	if starts_by(PursuitSpec.Start.CHARGES_AT_ONCE) and _notice:
		push_error("event '%s' charges at once but waits for her as well" % _id)
		return false
	if starts_by(PursuitSpec.Start.ARRIVES_CHASING) \
			and not (warns_before_it_exists() and warned_for() > 0.0):
		push_error("event '%s' arrives chasing but is not a pursuer warned of first" % _id)
		return false
	if _pursuit and not Tuning.validate_pursuit(_id, _pursuit.speed(), _duration, lethal_reach(),
			telegraphs_for(), notice_within(), heard_within(), standoff_reach(),
			_pursuit.start() == PursuitSpec.Start.ARRIVES_CHASING
					or _pursuit.start() == PursuitSpec.Start.CHARGES_AT_ONCE,
			_pursuit.start() == PursuitSpec.Start.SETS_OFF_BESIDE_HER):
		return false
		# The notice after the day switch is a second shape of the same contract:
		# `EventCatalogue.all()` validates every heat shape, but the day axis is orthogonal.
	if _pursuit and _from_day_after and _from_day_after.notice() \
			and not Tuning.validate_pursuit(_id, _pursuit.speed(), _duration, lethal_reach(), telegraphs_for(),
					_from_day_after.notice().within(), heard_within(), standoff_reach()):
		return false
	# **A pursuer that waits for her warns on a clock** (`PursuitSpec.warns_for()`) inside its one
	# radius.
	if _pursuit and _pursuit.start() == PursuitSpec.Start.NOTICES and waits_on_some_day \
			and _pursuit.warns_for() < Tuning.OFFSCREEN_WARNING_MIN:
		push_error("event '%s' waits for her but warns for %.1fs, less than the %.1fs heads-up"
				% [_id, _pursuit.warns_for(), Tuning.OFFSCREEN_WARNING_MIN])
		return false
	if _pursuit:
		# A pursuer has no line to be walked out of, so the ordinary escape-distance rule says nothing
		# about it and `validate_pursuit` is the contract: what its telegraph buys is the moment of
		# *noticing*.
		return true
	# A thing that does not telegraph its coming loses only the coming's telegraph (the badge and
	# warning first). Its in-world telegraph, where it has one, is still held by the contract. The
	# rows with none are those sent down her line at once, the loose dog and the dog walker the
	# director sends ahead of her: each is created just out of sight, outside its own field (held
	# above), with its telegraph already spent (`EventsAhead._send_down_her_line()`).
	if not telegraphs_its_coming() and comes_down_her_line():
		return true
	if warns_before_it_exists():
		return Tuning.validate_warning(_id, warning_time(), minimum_telegraph())
	return Tuning.validate_event(_id, warning_time(), core_within(), heard_within(), ends_the_day(),
			_route.speed())

## Shortest warning this row may fairly give, held against `warning_time()`.
##
## **A row warned of before it exists (`warns_before_it_exists()`) is owed
## `Tuning.OFFSCREEN_WARNING_MIN`**, a flat second to react, whatever its field and its speed (the
## cyclist, the fire engine and day 13's column alike; PLAYTEST-145). Its place follows her until it
## exists, so walking during the badge does not take her out of its field. Every other row is owed
## the time to walk out of its own field, `Tuning.required_telegraph_time()`.
##
## A pursuer's is a different quantity, `Tuning.PURSUIT_MIN_NOTICE`: there is no walking out of
## something that follows, so its telegraph buys the time to see it coming and change what you are
## doing. One that sets off beside her is owed the badge's heads-up instead,
## `Tuning.OFFSCREEN_WARNING_MIN`.
func minimum_telegraph() -> float:
	if warns_before_it_exists() and _pursuit == null:
		return Tuning.OFFSCREEN_WARNING_MIN
	# Warned before it was set on her, at the door: it owes none of its own.
	if starts_by(PursuitSpec.Start.CHARGES_AT_ONCE):
		return 0.0
	if starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER):
		return Tuning.OFFSCREEN_WARNING_MIN
	if _pursuit:
		return Tuning.PURSUIT_MIN_NOTICE
	return Tuning.required_telegraph_time(core_within(), heard_within(), ends_the_day(),
			_route.speed())

## How far ahead of her line `EventDirector` has to site a crossing `AHEAD_OF_PLAYER` row so it
## reaches the middle of its run at the moment she reaches it, rather than at whatever moment
## `Tuning.AHEAD_LEAD_DISTANCE`, a flat two seconds of walking, happens to land it.
##
## That flat lead is right for anything that starts moving the instant it is sited. For anything
## a row that holds still through its telegraph the crossing only starts once the telegraph is over, so the lead
## prices the time until the row is at the middle of its own run in walking distance.
func ahead_of_player_lead() -> float:
	if not _route.moves() or _route.speed() <= 0.0:
		return Tuning.AHEAD_LEAD_DISTANCE
	var half_crossing := float(Tuning.STREET_WIDTH) * Tuning.TILE_SIZE
	var time_to_middle := half_crossing / _route.speed()
	if _warning.holds_still():
		time_to_middle += telegraphs_for()
	return maxf(Tuning.AHEAD_LEAD_DISTANCE, time_to_middle * Tuning.WALK_SPEED)

## **How much longer a crossing that holds still crouches when its run is shorter than the one its
## lead was timed for** (`ahead_of_player_lead()`, a half crossing of `Tuning.STREET_WIDTH` tiles):
## a run of `run` px, cut where a solid stands nearer, reaches the middle sooner by the run it lost,
## so it holds that much longer and still reaches the middle when she does. Zero for a run as long
## as the timed one, and for a row that does not hold still.
func crouch_for_a_run(run: float) -> float:
	if not _route.moves() or _route.speed() <= 0.0 or not holds_still():
		return 0.0
	return maxf(0.0, (float(Tuning.STREET_WIDTH) * Tuning.TILE_SIZE - run) / _route.speed())

## **The nearest to her line a crossing that holds still may crouch**, in px, so she walking on is
## outside its field (`heard_within()`) for the whole crouch. A run that starts `run` px off her line
## reaches the middle when she does (`crouch_for_a_run()`), so she is `WALK_SPEED * run / speed`
## short of the middle as it runs, and `run * sqrt(1 + (WALK_SPEED / speed)²)` from the crouch at
## her nearest; this is that distance held at the field's edge. Zero for a row that does not hold
## still.
func nearest_crouch() -> float:
	if not _route.moves() or _route.speed() <= 0.0 or not holds_still():
		return 0.0
	return heard_within() / sqrt(1.0 + pow(Tuning.WALK_SPEED / _route.speed(), 2.0))

## Seconds from the moment this row becomes visible to the earliest it can reach her, on the worst
## heading the game can give it: what the fairness contract holds against `minimum_telegraph()`.
##
## **For a row in the world while it telegraphs, that is `telegraphs_for()`**: it is seen when it
## appears, and nothing it does inside the telegraph can end the day or charge her at full strength.
##
## **For a row warned of before it exists** (`warns_before_it_exists()`) **it is its badge to its
## reach**: its badge alone (`warned_for()`) plus the time the thing then takes to reach her from
## where it is created. Created closest (`SpawnSiting.least_distance()`, just out of sight on the
## view's short axis) and reaching her with her walking into it: at its lethal reach for a
## row that ends the day, and at its field's forward reach for any other. A field that already covers her
## where it is created adds nothing.
func warning_time() -> float:
	if not warns_before_it_exists():
		return telegraphs_for()
	var closing := _route.speed() + Tuning.WALK_SPEED
	var reach := lethal_reach() if ends_the_day() else field_reach()
	var created_at := SpawnSiting.least_distance()
	return warned_for() + maxf(0.0, created_at - reach) / closing

## How long this row's badge is up alone, with nothing in the world, before it is placed just out of
## sight (`PendingWarning`), for a row warned of before it exists. A pursuer's is its
## notice (`WarningSpec.badge_notice()`), since its telegraph is the approach she then watches; anything
## else's is its telegraph. `validate()` holds it to `Tuning.WARNING_ALONE_MAX`.
func warned_for() -> float:
	return _warning.badge_notice() if _pursuit else telegraphs_for()

## Whether it holds still through its telegraph (`WarningSpec.holds_still()`): a crouching cat is
## not walking.
func holds_still() -> bool:
	return _warning.holds_still()

## Whether it waits for her (`_notice`): a place until she comes within its notice of it, its
## telegraph and duration measured from that moment rather than from its birth.
func waits_for_her() -> bool:
	return _notice != null

## Whether it runs its own line once she comes close (`NoticeSpec.runs_within()`), rather than
## ending its notice on a clock: the masked man on the escape's stairs.
func runs_its_own_line() -> bool:
	return _notice != null and _notice.runs_within() > 0.0

## **Whether its warning emits only a telegraph's share of its peak**: its telegraph, and its wait
## where it has one. True for a row that does not wait and for one whose wait is quiet
## (`NoticeSpec.is_quiet()`, birds pecking on a pavement); false for one whose waiting is itself
## the threat, which emits at full strength through its wait and its notice alike.
func warns_quietly() -> bool:
	return _notice == null or _notice.is_quiet()

## Whether this row is warned of before it exists rather than created at once: its screen-edge
## badge goes up with nothing in the world, and its instance is created where the badge points once
## `warned_for()` is over (see `PendingWarning`). Two kinds are: a `TOWARD_PLAYER` row on foot that
## `telegraphs_its_coming()` (`cyclist`), which the director warns of down her line, and a row
## warned first (`WarningSpec.warned_first()`), which the caller that sends it warns of. A
## road-going `TOWARD_PLAYER` copy
## (the patrol the director sends ahead of her) is created at once instead; see docs/EVENTS.md, "Everything
## arrives from off screen".
func warns_before_it_exists() -> bool:
	return _warning.is_warned_first() or (comes_down_her_line() and telegraphs_its_coming())

## **The nearest to her this row is ever created arriving from off screen**: just out of sight,
## never nearer than `SpawnSiting.least_distance()` (the view's half height), whatever she is facing
## and in either control scheme; and a row created at once down a lane of the road (the patrol the
## director sends, `PendingWarning.in_its_lane()`) never nearer than `Offscreen.min_lead()` at its
## own closing speed and notice either, since nothing warns of it first and the camera may be led
## away from it. `validate()` holds a `TOWARD_PLAYER` row's field short of it.
func nearest_it_is_created() -> float:
	var out_of_sight := SpawnSiting.least_distance()
	if _spawn_mode == SpawnMode.TOWARD_PLAYER and not comes_down_her_line() \
			and not warns_before_it_exists():
		return maxf(out_of_sight, Offscreen.min_lead(
				_route.speed() + Tuning.WALK_SPEED, _warning.badge_notice()))
	return out_of_sight

## Whether the director sends this row down her own line on foot: a `TOWARD_PLAYER` row whose
## ground is not the road (`cyclist`, `loose_dog`), created just out of sight on her sidewalk
## (`PendingWarning.down_her_line()`), under a warning first when it `telegraphs_its_coming()`, at once when it
## does not.
func comes_down_her_line() -> bool:
	return comes_toward_her() and not keeps_to_the_carriageway()

## Whether the director sends it toward her, on whatever ground (`_spawn_mode` `TOWARD_PLAYER`):
## down her sidewalk on foot (`comes_down_her_line()` answers for that half) or down the carriageway
## beside her (`keeps_to_the_carriageway()`).
func comes_toward_her() -> bool:
	return _spawn_mode == SpawnMode.TOWARD_PLAYER

## Whether the row's own siting is on the map (`_spawn_mode` `MAP`), before any switch by day:
## `spawn_mode_on()` answers for a day.
func is_placed_on_the_map() -> bool:
	return _spawn_mode == SpawnMode.MAP

## **How old an instance of this row is at `point` of its beat** (0 at the beat's start, short of 1
## at its end), its telegraph spent: what a row the director sends ahead of her down her line is
## created at, the point drawn (`EventDirector.age_it_is_sent_at()`). Its telegraph alone for a row
## that does not pulse.
func age_at_a_point_of_its_beat(point: float) -> float:
	return telegraphs_for() + point * maxf(pulses_every(), 0.0)

## A copy of this row that enters the world only under a warning that runs first
## (`WarningSpec.warned_first()`),
## for a row otherwise placed some other way: day 13's column of `military_convoy` (a `MAP` place
## planned at dawn) and `charging_dog` sent at her down her heading (`EventSpawner.as_warned()`).
## Its badge alone is at most `Tuning.WARNING_ALONE_MAX`: a non-pursuer's telegraph is cut to
## it, and a pursuer keeps its badge notice (`WarningSpec.badge_notice()`). The copy is validated as it is made, so it is
## held to the flat minimum a warning first owes.
func as_warned_first() -> EventDef:
	var draft := redraft()
	var warned := _warning.warned_first()
	if not _pursuit:
		warned = warned.cut_to(Tuning.WARNING_ALONE_MAX)
	draft.warning(warned)
	var variant := draft.build()
	variant.validate()
	return variant

## The field's own furthest reach from this row's centre: what every "how far" rule needs instead
## of `heard_within()` alone, since a segment's field is a capsule and a moving point's forward reach
## outgrows its resting radius (`EventPlan.keeps_its_field_clear()`'s clearance, the streaming rect,
## `ExcitementSource.expected_gross_at()`'s early-out).
##
## The spine half-length plus `heard_within()` for a segment its field is priced from
## (`datum()`); this does not grow with speed, so for the patrol car it is the reach of its
## field standing. A row whose field is priced from its centre (`FieldSpec.from_its_centre()`,
## the fire engine) is a point, whatever its body. Otherwise `heard_within() * Field.scale(e)`,
## `e` from whichever speed the row's own motion uses: its chase speed for a pursuer, its
## route's speed for an ordinary moving row, zero (the plain disc) for anything standing still.
##
## **Not `is_lethal_at()`'s business.** Lethal is contact, not noise: a circle of `lethal_reach()`
## about the centre, with no eccentricity, and for a pursuer only where the straight line to her
## crosses no building (docs/EVENTS.md, "Solid things are solid", and
## `EventInstance.is_lethal_at()`).
func field_reach() -> float:
	var priced_from := datum()
	if priced_from != null and priced_from.is_segment():
		return priced_from.spine_half_length() + heard_within()
	var moving_speed := _pursuit.speed() if _pursuit else _route.speed()
	return heard_within() * Field.scale(Field.eccentricity(moving_speed))

# ------------------------------------------------------------ what a row costs ---
# The integral behind the cost table in `docs/EVENTS.md` and behind the assertion that nothing is
# cheaper to walk through than around. **It lives here rather than in `tests/test_events.gd`,
# because the game asks it too**: the danger caret is raised by what a row costs, and a second copy
# of that number would be a second table of which picture a look means.

## What walking straight through the middle of one costs, in points of a hundred-point meter: the
## field integrated along the line, less the walking decay over the same time. Cached, because
## `EventLook._wants_a_mark()` asks it on every `EventLook.draw()`.
func walk_through_cost() -> float:
	if _cost_cache == INF:
		_cost_cache = (_mean_emission_along_the_line() - Tuning.EXCITEMENT_DECAY_WALKING) \
				* (heard_within() * 2.0 / Tuning.WALK_SPEED)
	return _cost_cache

var _cost_cache := INF

## Mean emission along a straight line through the centre. The only property of a field that either
## the walking or the running comparison depends on: both integrate this line and differ only in how
## long the crossing takes.
func _mean_emission_along_the_line() -> float:
	var span := heard_within() * 2.0
	var steps := 2000
	var total := 0.0
	for i in steps:
		total += emission_at(Vector2(-heard_within() + span * (i + 0.5) / steps, 0.0))
	return total / steps

## What a row emits at a point, from its data alone.
##
## One disc for almost everything: all of its peak is at the centre and falls away from there.
##
## **That is false for a flock.** A flock is `flock().count()` birds sharing the intensity between
## them and wheeling inside `flock().spread()`, so the field is tighter and *quieter along a line
## through it*; priced as a disc, `pigeon_flock` reads substantially higher than a real instance
## costs. The birds are placed evenly round the wheel at its mean reach, since what a row costs is
## the average over where they might be.
##
## **This is the def's own model and not the instance's**: this one is a line through a flock at
## full strength, and what an instance charges depends on when the birds left the ground.
## `tests/test_events.gd` walks the instance for the part this cannot see.
func emission_at(at: Vector2) -> float:
	if not _flock.is_a_flock():
		return emission_at_distance(at.length())
	var share := peak() / float(_flock.count())
	var outer := maxf(core_within() + 1.0, heard_within() - _flock.spread())
	var total := 0.0
	for i in _flock.count():
		var angle := TAU * float(i) / float(_flock.count())
		var bird := Vector2(cos(angle), sin(angle)) * _flock.spread() * 0.65
		total += bird_emission_at(bird.distance_to(at), share, outer)
	return total

## What a row emits at a distance from its centre (`FieldSpec.emission_at_distance()`): **every price in
## the game goes through here**: the cost table's integral, the placement rules that read it, and an
## event's `ExcitementSource.contribution_at()`, which is what the baby is actually charged.
## `at_intensity` is the peak the *caller* is carrying rather than the catalogued one.
func emission_at_distance(at_distance: float, at_intensity: float = -1.0) -> float:
	return _field.emission_at_distance(at_distance, at_intensity)

## Whether the row is a stationary solid body the pavement does not pin to an edge
## (`_pavement_side` `ANY`) and that does not span the street: the body a pavement band's middle is
## where it stands (`BodyStance.stands_at()`). A row that spans the street stands at its kerb
## instead (`stands_at_its_kerb()`); the two never both hold.
func stands_on_its_band_middle() -> bool:
	return _is_an_unpinned_standing_body() and not _spans_the_street

## Whether the row's body stands on the kerb beside the carriageway lane it is placed in rather
## than on the lane (`CityMap.kerb_beside()`): a stationary solid body that spans the street
## (`spans_the_street()`) and that `_pavement_side` does not pin, the roadblock. From the kerb its
## band reaches across its own sidewalk and the road and stops at the far kerb, so the far sidewalk
## stays whole. A region wall's bodies are pinned (`SealPlanner.sealed_variant()`) and stand where
## they are put. Read by `EventPlan.stands_without_a_map()`, the one place that moves a body there.
func stands_at_its_kerb() -> bool:
	return _is_an_unpinned_standing_body() and _spans_the_street

## A stationary solid body that `_pavement_side` does not pin to an edge: the bodies that are moved
## from where they are placed to where they stand, onto a band's middle or onto a kerb.
func _is_an_unpinned_standing_body() -> bool:
	return not _route.moves() and obstructs_within() > 0.0 and _pavement_side == Pavement.ANY

## Whether the row stands in alleys and on no other ground: the robber and the mouse. Such a row is
## refused an alley the day's routes run down (`RowGround.offers_for_role()`) and has no marble on
## the route (`UnitFills`), since that alley is ground she has no way around
## rather than one she may choose to detour into. Stated over the ground the row lists rather than
## its id, so a row that shares the shape inherits the refusal.
func stands_only_in_alleys() -> bool:
	return _placement.size() == 1 and _placement[0] == GameEnums.TileType.ALLEY

## Whether the row carries a field at all (a peak above zero): a silent body bills nothing round it,
## so standing clear of it is standing clear of its body.
func has_a_field() -> bool:
	return _field.has_a_field()

## **The peak of its field at its centre**, before a phase damps it (`FieldSpec.peak_through()`): its
## peak, swelled toward the field's multiplier over its `_duration` and beating with its pulse.
## `into_its_burst` is how long its burst has been running (`EventInstance.current_intensity()` hands
## its notice's run less its telegraph), which the swell is measured on; `age` is its own clock,
## which the pulse beats on; `beat` (`< 0.0` means "not given") replaces the pulse's reading with a
## multiplier the caller worked out (`EventInstance.caret_intensity_over_horizon()`).
func peak_through(age: float, into_its_burst: float, beat := -1.0) -> float:
	return _field.peak_through(age, into_its_burst, _duration, beat)

## How many seconds one beat of its pulse lasts, or 0 for a row that does not pulse.
func pulses_every() -> float:
	return _field.pulses_every()

## The peak rate of its field at its centre, before a swell, a pulse or a phase moves it, or 0 for a
## row with no field: what the share it emits now is measured against.
func peak() -> float:
	return _field.peak()

## The rate of its field's louder core, or 0 for a row with none.
func core_rate() -> float:
	return _field.core_rate()

## Where its field's louder core has fallen to nothing, or 0 for a row with none.
func core_reach() -> float:
	return _field.core_reach()

## The exponent on the drop of its field between its two radii.
func falloff() -> float:
	return _field.falloff()

## **The shape its field is priced from** (`EventInstance.field_shape()`), and the reach a long
## body gives it (`field_reach()`): its body's shape, or none — a point at its centre — for a row whose
## field is priced from its centre (`FieldSpec.from_its_centre()`, the fire engine) or that has no
## shape.
func datum() -> GroundShape:
	return null if _field.is_priced_from_its_centre() else ground_shape()

## Whether what its field lands on her ignores every wall between, where every other field stops at
## one: the explosion outside the building.
func passes_walls() -> bool:
	return _field.passes_walls()

## What one of its flock's birds emits at `at_distance` from the bird, carrying `share` of the
## peak over a field that ends at `outer` (`FieldSpec.bird_emission_at()`). Each bird is its own
## point, so a flock is priced as the sum of these, by the row (`emission_at()`) and by its live
## event alike.
func bird_emission_at(at_distance: float, share: float, outer: float) -> float:
	return _field.bird_emission_at(at_distance, share, outer)

## A straight-line distance from a live instance's node beyond which its field is exactly zero,
## whatever its intensity, speed, heading or the way its shape lies, so an event's source
## (`EventExcitement._field()`) can answer zero for a far source without working the field out: the
## field's own (`FieldSpec.silent_beyond()`, worked out once) and the body's reach round it. A flock
## and a guard walking away from his barrier centre their fields elsewhere, so the instance does not
## ask this for them.
##
## **Not `field_reach()`**, which is the field's own extent for the planners; this is the looser
## figure nothing can be past and still charge her. The body's reach is asked on every call, since
## it is one read of the row's shape, which is never changed once the row is built.
func silent_beyond() -> float:
	var body := ground_shape().reach() if ground_shape() != null else 0.0
	return body + _field.silent_beyond()

## The same exemptions asked of the **def** alone, for the one caller that has no placement to ask
## about: `EventScheduler.role_for()` decides a role before any tile is chosen. Everything a
## placement adds is the caller's own question, asked by
## `EventPlan.counts_against_the_line()`: *is it actually standing anywhere*, and *is
## it a region door* (`EventPlan.is_door()`), since what makes a door a door is `RegionPlanner`
## standing it at one rather than any field on the def. No row the catalogue places is a door.
##
## **A row the day sites from her own walk is a sixth kind outside the line, and the only one
## exempt because closing the way is the point** (PLAYTEST-119 24). Day 3's fire is put on the
## branch she is walking so that the street she is on stops being a way through, and the engine
## parks across from it for the rest of the day, so asking whether a line survives along that
## sidewalk would refuse every site the design exists to make. Nothing physical closes it: the fire
## has no body (PLAYTEST-144 12), and the engine it calls parks on the carriageway, so the street's
## way through is the engine's field, a cost and not a closure. A one-shot carrying this flag is
## never placed at dawn (`DawnOneShots` plans it with no position), so nothing
## else in the day is judged differently because of it.
## **A recurring row carrying it is not exempt**: a poster crew closes nothing, and it is drawn at a
## location and judged as any other before it is handed to her walk with no position
## (`MarbleDraw.draw()`).
func has_a_line_to_avoid() -> bool:
	if _role == EventDef.Role.SCENERY or _pursuit != null:
		return false
	if is_a_set_piece_on_her_way():
		return false
	if _route.moves() and not _route.paces_a_beat():
		return false
	return line_reach() > 0.0

## The line a stroller needs across a sidewalk, measured between the two lanes of one:
## `SIDEWALK_WIDTH` (2) tiles means the far lane's centre is one tile (32px) from the near one, and
## a free tile is a line because a tile is wider than the 28px stroller (`2 * PLAYER_BODY_RADIUS`).
const _THE_FAR_LANE := float((Tuning.SIDEWALK_WIDTH - 1) * Tuning.TILE_SIZE)

## Whether the row's reach (`line_reach()`) is at least the far lane's, so the lane she would use
## to get past is itself billed.
func reaches_the_far_lane() -> bool:
	return line_reach() >= _THE_FAR_LANE

## How far a row denies ground: **the disc it charges for**, `obstructs_within()` wherever it has a
## body, the larger of the two where both apply. A row that neither charges nor obstructs (the
## `playground` ambient, at intensity 0) is not something a line has to avoid.
##
## **Charging for is not the same as being heard on.** A walk through ground where a row emits less
## than `Tuning.EXCITEMENT_DECAY_WALKING` nets the meter *down*, so it is ground a route does not
## have to be planned around and the placement rules in `EventScheduler` have no business refusing a
## placement over it. The disc is therefore where the emission crosses
## that rate, not `heard_within()`, where it stops reaching at all; the same distinction
## `DawnSpoilers._denial_radius()` makes about calm ground, at a different rate and with a
## different zero. A row quieter than the rate everywhere denies **nothing** here, where it still
## denies its own inner disc to a pram trying to settle.
##
## **A lethal row keeps its whole `heard_within()`**: nothing about being quiet at the rim makes
## walking into it survivable.
##
## The plain disc rather than `field_reach()`'s forward-stretched ellipse, which differs only for a
## mobile row and only ahead of it. A flock would need its own answer, since its intensity is shared
## between bodies and the closed form below reads it far too wide; `pigeon_flock` is `Role.SCENERY`
## and `EventPlan.counts_against_the_line()` is done with it before this is asked.
func line_reach() -> float:
	if ends_the_day():
		return maxf(heard_within(), obstructs_within())
	return maxf(reach_above(Tuning.EXCITEMENT_DECAY_WALKING), obstructs_within())

## How far from the centre a row still emits more than `rate`, over both parts of its field
## (`FieldSpec.reach_above()`): the field itself, and the core where it has one.
func reach_above(rate: float) -> float:
	return _field.reach_above(rate)

# --------------------------------------------------------- what a caller asks ---
# The questions a caller outside the events asks a row, each answered from the row's own settings,
# so the caller never reads one to work the answer out itself.

## **Whether its coming gets a badge at the screen edge**, for her walking at `walk_speed`: lethal
## always, and otherwise only what she cannot outwalk (a thing slower than a walk is one she can
## turn round and leave). A thing that does not telegraph its coming (`telegraphs_its_coming()`) is outside the
## badge.
func announces_its_coming(walk_speed: float) -> bool:
	if not telegraphs_its_coming():
		return false
	if ends_the_day():
		return true
	return _route.moves() and _route.speed() > walk_speed

## How fast it comes at her under its own steam: its chase speed for a pursuer, otherwise its
## route's speed (`RouteSpec.speed()`). What the badge starts a thing that arrives under its warning
## closing at.
func approach_speed() -> float:
	return chase_speed() if _pursuit != null else _route.speed()

## How far from its centre its field reaches her at all: where the badge measures the gap to.
func heard_within() -> float:
	return _field.heard_within()

## How far from its centre its core reaches: the span a dog walker's dog is led ahead at is a share
## of it.
func core_within() -> float:
	return _field.core_within()

## Whether walking into its reach ends her day (`LethalSpec.ends_the_day()`): a place that ends the
## day. A car's strike is its driving's (`EventCarDriving`), not this.
func ends_the_day() -> bool:
	return _lethal.ends_the_day()

## Whether it is a permanent feature of a fixed map (`GameEnums.EventKind.AMBIENT`), which never
## appears: the fairness contract exempts it, and nothing marks it.
func is_ambient() -> bool:
	return _kind == GameEnums.EventKind.AMBIENT

## Whether it is a car that drives (`_vehicle`), whose strike is its driving's.
func drives() -> bool:
	return _vehicle != null

## Whether it comes after her (`_pursuit`), however its chase starts.
func pursues() -> bool:
	return _pursuit != null

## Whether it stops where its route ends and stands there for the rest of the day
## (`RouteSpec.parking_where_it_arrives()`): day 10's neighbor home before she reached them.
func parks_where_it_arrives() -> bool:
	return _route.parks_where_it_arrives()

## Whether it was sent at her: it comes after her (`_pursuit`, however its chase starts), or the
## caller that sends it warns of it first (`WarningSpec.warned_first()`). The park cordon walks out everyone in
## the closed park but such a row, a car and the ambient ground.
func was_sent_at_her() -> bool:
	return _pursuit != null or _warning.is_warned_first()

## Whether it paces a beat (`RouteSpec.pacing()`): it walks its route to and fro and neither departs
## nor expires, where an ordinary mover walks its way once.
func paces_a_beat() -> bool:
	return _route.paces_a_beat()

## The id of the row it leaves where it ends (`Aftermath.leaves_behind()`), or "" for a row that leaves
## nothing: the escape's explosion leaves its crater in the road.
func leaves_behind() -> String:
	return _aftermath.leaves_behind()

## The id of the scar it leaves on the run where it happens (`Aftermath.scar_id()`), or "" for a row that
## leaves none: the burning building's burnt shell, the roadblock's barricade.
func scar_id() -> String:
	return _aftermath.scar_id()

## The picture it is drawn as, which is the silhouette its badge carries
## (`EventPictures.icon_for()`; `LookSpec.picture()`).
func picture() -> Look:
	return _look.picture()

## Whether it is a flock of bodies wheeling over one place (`FlockSpec.is_a_flock()`).
func is_a_flock() -> bool:
	return _flock.is_a_flock()

## Whether it holds her when she comes to it (`HoldSpec.detains_her()`): a chatting mother's conversation,
## a door's hut or post. What the crowd's walkers are held at.
func detains_her() -> bool:
	return _hold.detains_her()

## How long a hold of hers lasts, in seconds (`HoldSpec.detains_for()`), or 0 for a row that holds nobody.
func detains_for() -> float:
	return _hold.detains_for()

## Whether it is a door's hut or post: armed again once she has been let out and has walked away,
## where a chatting mother's conversation is spent for good (`HoldSpec.again()`).
func detains_again() -> bool:
	return _hold.detains_again()

## Whether it is a door's boom, solid only while lowered (`BodySpec.is_a_boom()`).
func is_a_boom() -> bool:
	return _body.is_a_boom()

## **Whether its body is recorded on the ground for the whole day**: a standing body that stops her
## (a `ground_shape()` and `has_a_body()`), that does not move (`moves()`), since a mover is
## somewhere else by the time a route gets there (a moving wall pins her, so the catalogue exempts
## anything mobile from being solid at all), and is no door's: a hut or a post that holds her
## (`detains_her()`) or the boom (`is_a_boom()`), a crossing the day keeps open, answered for a
## walker by `WalkerDoorHold` at a hut or a post and for a car by `Crowd._stop_for_gates()` at the
## boom, which detains nobody, so it is named by its own flag rather than by its hold. The rows whose
## ground the map's record of blocked tiles holds (`EventSpawner.obstructed_footprint()` asks it),
## and the bodies the route rig keeps clear of before they are streamed in.
func stands_as_a_fixed_body() -> bool:
	return ground_shape() != null and has_a_body() and not moves() and not detains_her() \
			and not is_a_boom()

## Whether several of it count as the strongest one only: the pieces of a street being held, whose
## fields do not add up (`FieldSpec.as_one_barrier()`).
func counts_as_one_barrier() -> bool:
	return _field.counts_as_one_barrier()

## How long its telegraph lasts, in seconds (`WarningSpec.telegraphs_for()`).
func telegraphs_for() -> float:
	return _warning.telegraphs_for()

## Whether its coming is announced: the screen-edge badge and warning-first placement are for a thing
## that telegraphs its coming (`WarningSpec.telegraphs_its_coming()`).
func telegraphs_its_coming() -> bool:
	return _warning.telegraphs_its_coming()

## Seconds from one of its instances coming to the next, kept on its own clock, or 0 for a row that
## does not come again on a clock (`_repeat_every`). A plan made of it starts from this.
func comes_again_every() -> float:
	return _repeat_every
