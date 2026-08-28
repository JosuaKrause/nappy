class_name EventCatalogue
extends RefCounted
## Every event in the game, defined in code. See docs/EVENTS.md for the full catalogue and
## the reasoning behind each one.
##
## M4 carries three events, chosen to exercise the whole system rather than to populate a
## day: a permanent ambient field, a short mobile burst, and a stationary pulsing source.
## M5 fills in the rest of Act I.

# ------------------------------------------------------------------- bodies ---
# *(M34.)* A body is **half the silhouette**, never a number chosen for how it plays: the rule
# in `EventDef.obstructs_radius` is that a thing that stands still is solid at the width it is
# drawn, and a body that disagrees with the art is a lie about where she can walk in one
# direction or the other. Two of them repeat often enough to be worth a name; the rest are
# written at the row that uses them, with the sprite they came from.

## `person.svg` is 18px across. A man you edge past on a pavement rather than walk through.
const PERSON_BODY := 11.0
## `vehicle.svg` is 48px across.
const VEHICLE_BODY := 22.0

static var _all: Array[EventDef] = []

static func all() -> Array[EventDef]:
	if _all.is_empty():
		_all = _build()
		for def in _all:
			def.validate()
	return _all

static func by_id(id: String) -> EventDef:
	for def in all():
		if def.id == id:
			return def
	return null

## Every def that may appear on this day, in catalogue order.
static func available_on(day: int) -> Array[EventDef]:
	var found: Array[EventDef] = []
	for def in all():
		if def.available_on(day):
			found.append(def)
	return found

static func of_kind(kind: GameEnums.EventKind, day: int) -> Array[EventDef]:
	var found: Array[EventDef] = []
	for def in available_on(day):
		if def.kind == kind:
			found.append(def)
	return found

static func _build() -> Array[EventDef]:
	return [
		# Act I - a nice neighbourhood.
		_playground(),
		_cat_dash(),
		_dog_walker(),
		_cafe_tables(),
		_delivery_van(),
		_homeless_yeller(),
		_busker(),
		_construction(),
		_fire_truck(),
		_burning_building(),
		_burnt_shell(),

		# Act I, M31 - the neighbourhood with things in it, and two that can end the day.
		_loose_dog(),
		_market_stall(),
		_leaf_blower(),
		_pigeon_flock(),
		_cyclist(),
		_ice_cream_van(),
		_reversing_lorry(),
		_charging_dog(),

		# Act II - notices.
		_police_patrol(),
		_poster_crew(),
		_loudspeaker(),
		_curfew_announce(),
		_checkpoint(),

		# Act III - vans.
		_abduction(),
		_alley_robbery(),
		_night_raid(),

		# Act IV - open.
		_military_convoy(),
		_barricade(),
		_protest(),
		_firefight(),
	]

## The reason parks are not a free win. Permanent, wide, and sitting in the middle of the
## calmest ground in the city.
static func _playground() -> EventDef:
	var def := EventDef.new()
	def.id = "playground"
	def.display_name = "Playground"
	def.kind = GameEnums.EventKind.AMBIENT
	def.ambient_source = EventDef.AmbientSource.PLAYGROUND
	def.look = EventDef.Look.NONE  # The park's swing frame already draws it.
	def.intensity = 7.0
	# Sized so it dominates the middle of a park but leaves the far side genuinely calm —
	# a park block is 256px across, so a 200px reach would have swallowed the whole thing
	# and made every park useless rather than merely contested.
	def.inner_radius = 40.0
	def.outer_radius = 150.0
	def.telegraph_time = 0.0
	def.pulse_period = 9.0
	return def

## The tutorial obstacle: visible crouching before it bolts, sharp while it crosses, gone
## a second later. Small radius, so walking one lane wide of it is enough.
##
## **Playtest 04 found it doing nothing at all, for two separate reasons, and M27 fixed both.**
##
## It was placed on a road tile somewhere in the city at dawn and it ran its two and a half
## seconds out there, alone. *"The cat is ineffective since it happens when it spawns."* A cat
## is not a place, it is a moment — so it is the first `AHEAD_OF_PLAYER` event: the director
## puts it across her line while she is walking, and it happens in front of her every time.
##
## And it had never once been seen to bolt. `EventInstance` starts a mobile event moving when
## the telegraph does, which is right for a siren approaching from three streets away and wrong
## for a crouch: the path is one street wide, so at 240px/s the cat finished its whole run
## *during* the telegraph. It never reached full intensity and the running sprite never drew.
## `still_while_telegraphing` is the fix, and the duration now covers the crossing it makes
## afterwards rather than expiring half way over.
static func _cat_dash() -> EventDef:
	var def := EventDef.new()
	def.id = "cat_dash"
	def.display_name = "Cat"
	def.look = EventDef.Look.CAT
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.spawn_mode = EventDef.SpawnMode.AHEAD_OF_PLAYER
	def.intensity = 15.0
	def.inner_radius = 30.0
	def.outer_radius = 120.0
	# Long enough to carry it the whole way across the street it starts at the edge of:
	# STREET_WIDTH tiles either side at 240px/s is 1.6s, and it must not expire mid-road.
	def.duration = 1.8
	def.telegraph_time = 1.6
	def.mobile = true
	def.still_while_telegraphing = true
	def.speed = 240.0
	# Lowered in M31, because the cat stopped being the only thing that happens *to* her: the
	# director now has pigeons too, and two tricks at 3.0 each would have doubled what it spends.
	def.weight = 2.5
	# The one cap M28 did *not* multiply. A cat is sited by the director while she walks, and
	# `AHEAD_INTERVAL` spreads them 11-26s apart over a 180s day, so a seventh has nowhere to
	# happen: raising it would spend budget on cats the day cannot fit.
	def.max_per_day = 6
	return def

## Stationary, loud, and *pulsing* — the intensity envelope means the counterplay is timing
## a pass between yells, which is a different skill from routing around a hazard.
##
## He is also the man playtest 07 walked up to and walked *through*: *"there was a person right
## on the home block but walking up to them didn't do anything"*, and *"I can walk over the
## robber and he doesn't do anything"*. Both are this row — the traces have nineteen `near
## homeless_yeller` entries and never reach the day an actual robber exists.
##
## **And he is the man who killed playtest 09's third attempt at day 1 by standing still.** *"Who is
## the person killing me? It didn't move and it took a long time to have any effect. If it's the
## homeless person it needs to walk up and down the sidewalk."* Both halves are here.
##
## He **paces** now — a beat rather than a journey, which is what `EventDef.paces` is for. That is a
## design change and not a polish one: a stationary source is a fixed price on a fixed patch of
## pavement, so the answer to it is a line you draw once and never think about again. A man walking
## up and down two hundred and fifty pixels of footway is a *timing* problem on top of a routing
## one, which is the same thing his pulse already asks for at a smaller scale.
##
## The cost of pacing is the body. M34 gave him `PERSON_BODY` for the "walk over the robber"
## complaint and the invariant takes it straight back off: **anything mobile is exempt**, because a
## moving wall on a two-tile pavement pins her against a building. That is the `dog_walker` decision
## and it has not changed. What stops you walking through him is the meter, and 14 over 210px is a
## real wall — it was 10, which is where *"it took a long time to have any effect"* came from.
static func _homeless_yeller() -> EventDef:
	var def := EventDef.new()
	def.id = "homeless_yeller"
	def.display_name = "Man shouting"
	def.look = EventDef.Look.YELLER
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 14.0
	def.inner_radius = 45.0
	def.outer_radius = 210.0
	def.telegraph_time = 2.6
	def.pulse_period = 5.0
	def.mobile = true
	def.paces = true
	# A third of a walking pace: he is not going anywhere, and something that shuffles reads as
	# somebody who lives on this pavement rather than somebody crossing it.
	def.speed = 30.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	# Eight tiles of footway, walked in about eight seconds each way. Long enough that where he is
	# now is worth looking at, short enough that it is still *a place he is*.
	def.path_length_tiles = 8
	def.weight = 2.0
	def.max_per_day = 14
	return def

## Slow, and it owns the pavement it is on.
##
## This was the clearest measured failure in the whole catalogue: at intensity 7 walking
## *through* a dog walker beat walking around it by 0.1 of a point, because the 3.5/s walking
## decay outran what it emitted. An obstacle that is cheaper to walk into than to avoid is not
## an obstacle. Playtest 02, finding 3, asked for the opposite — *"dog walkers that are a fast
## loss if I get too close; if I see one ahead I might have to turn around and cross at the
## zebra"* — so the intensity is now the wall.
##
## Deliberately **not** given an `obstructs_radius`: a mobile static body wide enough to matter
## on a two-tile pavement can pin the player against a building, and being pinned by something
## that walks toward you is a different game from being priced out of a street. The lead is
## drawn (see `EventInstance._draw_dog_walker`) so the span it owns is visible; what stops you
## walking through it is the meter, and it is slower than walking, so it can always be left.
static func _dog_walker() -> EventDef:
	var def := EventDef.new()
	def.id = "dog_walker"
	def.display_name = "Dog walker"
	def.look = EventDef.Look.DOG_WALKER
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 26.0
	def.inner_radius = 26.0
	def.outer_radius = 105.0
	def.telegraph_time = 1.4
	def.pulse_period = 3.5
	def.mobile = true
	def.speed = 32.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 30
	# The heaviest weight in act I, and M31 *raised* it while adding seven rows around it. The
	# density is a fixed number of events, so every new type takes a share of it — and the two
	# rows playtest 05 named by name are the two that cannot be allowed to thin out. Dog walkers
	# and café frontages are what an ordinary street is mostly made of; a loose dog and an ice
	# cream van are punctuation.
	def.weight = 4.5
	# Playtest 05, finding 6, in the player's own words: *"the dog walker decision should happen
	# meaningfully — I want to have to make that decision at least twice on day one."* Three on a
	# forty-nine-block city made that a coin flip she lost. Repeats are explicitly fine.
	def.max_per_day = 20
	def.cost = 2
	return def

## The pavement, taken. A café spilling out of its frontage: chairs, tables, conversation, and
## no way past on this side.
##
## The act I half of playtest 02's finding 3 — *"there should be things that force me to cross
## the street"* — and the first event in the game that is available on **day one** and cannot
## be walked through. `construction` does the same job from day 2 and is the loud version of
## it; this one is pleasant, which is worse: nothing about it looks like a hazard and it still
## costs the street. Stationary, so it can never pin the player the way a moving obstruction
## could.
static func _cafe_tables() -> EventDef:
	var def := EventDef.new()
	def.id = "cafe_tables"
	def.display_name = "Café tables"
	def.look = EventDef.Look.CAFE
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 12.0
	def.inner_radius = 40.0
	def.outer_radius = 170.0
	def.telegraph_time = 1.6
	def.pulse_period = 6.0
	def.obstructs_radius = 24.0
	# Raised with `dog_walker` and for the same reason — see the note there.
	def.weight = 4.0
	# *"Also the same with a restaurant — I never saw one."* At three on a forty-nine-block city,
	# with only the ~23% of the map near her ever instantiated, the expected number of cafés she
	# could see in a day was under one — so the day-1 event built to force a crossing was in
	# practice absent from most day ones.
	def.max_per_day = 18
	def.cost = 2
	return def

## Parked at the kerb, hazards going, half unloaded. Constant and stationary — the plain
## obstacle the route planning is practised on.
##
## **It was the thing playtest 07 called scenery**: *"there is also a car obstacle on the road
## that is basically a still car standing on the road doing nothing"*, and it was doing nothing
## for two reasons at once. It had no body, so she walked through it; and it was placed on a
## `ROAD` tile, where it stood in a traffic lane that the crowd knows nothing about and drove
## straight through, blocking a route nobody takes on foot anyway.
##
## Both halves are the same fix: a parked van belongs **at the kerb**. There it is on the
## pavement she is actually walking down, it takes that pavement — 48px of van across a 64px
## footway, so the answer is the other side of the street — and no car drives through it.
static func _delivery_van() -> EventDef:
	var def := EventDef.new()
	def.id = "delivery_van"
	def.display_name = "Delivery van"
	def.look = EventDef.Look.DELIVERY_VAN
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.pavement_side = EventDef.Pavement.AT_THE_KERB
	def.intensity = 8.0
	def.inner_radius = 40.0
	def.outer_radius = 150.0
	def.telegraph_time = 1.3
	def.obstructs_radius = VEHICLE_BODY
	def.weight = 2.0
	def.max_per_day = 14
	return def

## A park spoiler, and a pleasant one. Nothing about it is threatening; it is simply
## interesting, which is the whole problem.
static func _busker() -> EventDef:
	var def := EventDef.new()
	def.id = "busker"
	def.display_name = "Busker"
	def.look = EventDef.Look.BUSKER
	def.first_day = 2
	def.placement = [GameEnums.TileType.PARK, GameEnums.TileType.SQUARE]
	def.intensity = 9.0
	def.inner_radius = 45.0
	def.outer_radius = 190.0
	def.telegraph_time = 1.7
	def.pulse_period = 7.0
	def.obstructs_radius = PERSON_BODY
	def.weight = 2.0
	# Kept the lowest of the raised act I caps on purpose: a busker is placed on PARK or SQUARE,
	# which is the only calm ground there is, and `_ensure_one_usable_park` pays for every one
	# that lands on the block it ends up protecting.
	def.max_per_day = 8
	return def

## The only Act I event that is physically in the way. Blocking the sidewalk forces a
## reroute rather than merely inviting one — and since a street is sidewalk|road|sidewalk,
## the road is always still there, so it costs time and exposure, never the day.
static func _construction() -> EventDef:
	var def := EventDef.new()
	def.id = "construction"
	def.display_name = "Roadworks"
	def.look = EventDef.Look.ROADWORKS
	def.first_day = 2
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 11.0
	def.inner_radius = 46.0
	def.outer_radius = 200.0
	def.telegraph_time = 1.8
	def.obstructs_radius = 34.0
	def.weight = 1.5
	def.max_per_day = 12
	def.cost = 2
	return def

## The Act I finale. Audible from streets away, moving fast down an arterial road, and it
## leaves a fire burning where it stops. Long telegraph, because the whole point is that
## you hear it coming and have time to get off that street.
static func _fire_truck() -> EventDef:
	var def := EventDef.new()
	def.id = "fire_truck"
	def.display_name = "Fire engine"
	def.kind = GameEnums.EventKind.ONE_SHOT
	def.look = EventDef.Look.FIRE_ENGINE
	def.first_day = 3
	def.last_day = 3
	def.placement = [GameEnums.TileType.ROAD]
	def.intensity = 26.0
	def.inner_radius = 70.0
	def.outer_radius = 340.0
	# A truck at 190px/s outruns a walk, so the fairness rule demands the FULL radius of
	# clearance, not just the falloff band: 340/92 = 3.7s.
	def.telegraph_time = 4.0
	def.mobile = true
	def.speed = 190.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 60
	def.spawns_on_finish = "burning_building"
	def.cost = 4
	return def

## Never scheduled directly — a SCRIPTED def with no day, spawned only where the fire
## engine stops. Burns for the rest of the day.
static func _burning_building() -> EventDef:
	var def := EventDef.new()
	def.id = "burning_building"
	def.display_name = "Burning building"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BURNING_BUILDING
	def.intensity = 18.0
	def.inner_radius = 60.0
	def.outer_radius = 260.0
	def.telegraph_time = 2.2
	def.pulse_period = 3.0
	# Five flames spanning ±31px, and you do not walk through a burning building. Not lethal by
	# decision — what ends a day is in act III — so the body is simply the fire.
	def.obstructs_radius = 30.0
	def.scar_id = "burnt_shell"
	return def

## What is left the next morning, and every morning after. Cordoned off, never repaired.
## Almost silent — it is a reminder rather than a hazard, and it is on the same corner on
## day 12 as it was on day 4.
##
## *(M34.)* "Not an obstacle" used to mean it had no body either, which is how a burnt-out
## building came to be a thing you could stand inside — playtest 07 named it in the list of
## things it could walk over. It is silent **and** solid now, and the two were never the same
## claim: what it costs the meter is 2.5/s and what it costs the route is a corner.
## `_draw_spread` draws the cordon at exactly the width of the body, so this number is also how
## wide it looks; at 36 it is a shell rather than the two-barrier sliver 11px was drawing.
static func _burnt_shell() -> EventDef:
	var def := EventDef.new()
	def.id = "burnt_shell"
	def.display_name = "Burnt-out building"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BURNT_SHELL
	def.intensity = 2.5
	def.inner_radius = 30.0
	def.outer_radius = 90.0
	def.telegraph_time = 0.7
	def.obstructs_radius = 36.0
	return def

# ------------------------------------------- Act I, M31: variety, and two with teeth ---
# Playtest 05, finding 5: *"day two doesn't feel more difficult than day one. Having day one
# relatively easy is okay if the difficulty increases. But right now there is never any
# danger."* True by construction — every `hard_fail` event started on day 8 or later, so for
# half a run the only lethal thing in the game was a car the player is never obliged to step in
# front of.
#
# The shape of the fix was a decision rather than a derivation, and it was taken against a
# patrol: *"patrol shouldn't be there for act I"*. Act I is a nice neighbourhood, and a police
# patrol in it on day 2 tells a story the game tells in act II. So the danger comes from the
# neighbourhood itself — **a kid on a bike and a lorry reversing across a pavement**, which are
# what a person pushing a pram is actually frightened of, and which arrive on days 2 and 3.
#
# The rest is variety, asked for in the same breath: *"try to come up with more variety. we
# need more events/entities in general."* Seven rows, five of them on day 1, each with its own
# silhouette — see the note on `EventDef.Look`.

## The leash slipped. *(The player's own idea: "a dog where the owner drops the leash and it
## starts running".)*
##
## The counterpart to `dog_walker` and the reason both exist: that one is a *span* you decide
## whether to cross the street to avoid, this one is a *thing coming down the pavement* that you
## cannot out-walk. Faster than `WALK_SPEED`, so it earns a badge at the screen edge and the
## fairness contract makes it pay for the whole radius rather than the falloff band.
##
## Not lethal, deliberately. Act I gets exactly two things that end the day and this is not one
## of them: a loose dog is loud and it is chaos, and the day it ruins is ruined through the
## meter, which is where most of the game lives.
static func _loose_dog() -> EventDef:
	var def := EventDef.new()
	def.id = "loose_dog"
	def.display_name = "Loose dog"
	def.look = EventDef.Look.LOOSE_DOG
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 24.0
	def.inner_radius = 30.0
	def.outer_radius = 140.0
	# Faster than a walk, so the escape distance is the whole radius: 140/92 = 1.52s.
	def.telegraph_time = 1.7
	def.pulse_period = 2.2
	def.mobile = true
	def.speed = 132.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 24
	def.weight = 1.2
	def.max_per_day = 8
	def.cost = 2
	return def

## A market trestle taking the pavement, and the second thing on day 1 that forces a crossing.
##
## `cafe_tables` has been the only one since M19, and M28 made it common — but one obstacle
## repeated eighteen times is a rule, not a decision. This one is louder and wider and it is on
## the other side of pleasant: a café you squeeze past is a nuisance, a market is a crowd.
static func _market_stall() -> EventDef:
	var def := EventDef.new()
	def.id = "market_stall"
	def.display_name = "Market stall"
	def.look = EventDef.Look.STALL
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 14.0
	def.inner_radius = 44.0
	def.outer_radius = 185.0
	def.telegraph_time = 1.7
	def.pulse_period = 8.0
	def.obstructs_radius = 28.0
	def.weight = 1.6
	def.max_per_day = 10
	def.cost = 2
	return def

## The loudest thing in act I, and it is a man tidying a park.
##
## Deliberately allowed on `PARK`: a calm block with a leaf blower in it is calm ground she
## cannot use, which is the shape M24 needs more of — somewhere to walk to that turns out to be
## occupied. Pitched above `busker` because a two-stroke engine is not a violin.
static func _leaf_blower() -> EventDef:
	var def := EventDef.new()
	def.id = "leaf_blower"
	def.display_name = "Leaf blower"
	def.look = EventDef.Look.LEAF_BLOWER
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.PARK,
			GameEnums.TileType.SQUARE]
	def.intensity = 20.0
	def.inner_radius = 40.0
	def.outer_radius = 200.0
	def.telegraph_time = 1.8
	# Swept in bursts rather than held, so there is a rhythm to time a pass through — the same
	# counterplay `homeless_yeller` has, at a scale that makes a whole corner of a park unusable.
	def.pulse_period = 4.0
	def.obstructs_radius = PERSON_BODY
	def.weight = 1.2
	def.max_per_day = 8
	def.cost = 2
	return def

## Pigeons off the pavement all at once — on the ground in front of her, then up, then away.
##
## The second `AHEAD_OF_PLAYER` event, and the reason to have a second one is that the director
## had a single trick: every moment that happened *to* her was a cat. A flock is the cheapest
## possible version of the same idea and it is the one that makes the director read as a
## director rather than as a cat dispenser.
##
## **It did nothing at all for two milestones and was reported twice.** *(Playtest 07, finding 9:
## "birds just disappear if I get close and do nothing." Playtest 08, finding 2: "pigeons are also
## completely ineffective.")* Three separate reasons, and the numbers here are two of them:
##
## - It was **over before she arrived**. Sited two seconds of walking ahead with a 0.9s telegraph
##   and a 2.4s burst, it expired as she reached it. The telegraph is the flock *on the pavement*
##   now, which is long enough to be seen from down the street and to be walked around, and the
##   burst outlasts her arrival instead of ending at it.
## - It was **quiet and small**: 17 over a 110px reach, in a game where a café is 12 over 170. A
##   flock going up in a pram's face is one of the loudest things that can happen on an ordinary
##   pavement, and it is now priced like it.
## - And it was **deleted at the top of its climb**, which is `EventDef.departs_at` and the reason
##   that field exists. They fly off.
static func _pigeon_flock() -> EventDef:
	var def := EventDef.new()
	def.id = "pigeon_flock"
	def.display_name = "Pigeons"
	def.look = EventDef.Look.BIRDS
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE,
			GameEnums.TileType.PARK]
	def.spawn_mode = EventDef.SpawnMode.AHEAD_OF_PLAYER
	def.intensity = 20.0
	def.inner_radius = 34.0
	def.outer_radius = 140.0
	def.duration = 3.0
	# On the ground the whole time, which is what makes this a thing to walk around rather than a
	# thing that happens. Well over the 1.2s the contract asks of a 140px field.
	def.telegraph_time = 1.6
	# Faster than she can run, and up: they are gone in a second and a half and they are gone
	# *somewhere*.
	def.departs_at = 190.0
	def.weight = 1.5
	def.max_per_day = 5
	return def

## **The first thing in the game that can end your day, and it arrives on day 2.**
##
## A kid on a bike on the pavement, bell going. Everything about it is ordinary, which is the
## point: the answer to *"there is never any danger"* should not be that act I becomes sinister,
## it should be that act I is a real street. A pram and a bicycle at speed is what a person
## pushing one is actually frightened of.
##
## The fairness contract does the work and it is expensive here — `hard_fail` doubles the margin
## and the speed means the whole radius counts, so the bell has to ring for (145/92) x 2 = 3.15s
## before it arrives. That is right: it is audible from down the street, she has three seconds
## and one step to make, and stepping off a pavement is a step. It is also why the radius is
## small — a wider one would need a bell you could hear across the district.
##
## Day 2 rather than day 1 on purpose. *"Having day one relatively easy is okay if the
## difficulty increases"* — so the escalation the player could not feel is now the plainest
## possible thing: the day the streets acquire something that can take the day off you.
static func _cyclist() -> EventDef:
	var def := EventDef.new()
	def.id = "cyclist"
	def.display_name = "Cyclist"
	def.look = EventDef.Look.CYCLIST
	def.first_day = 2
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 18.0
	def.inner_radius = 26.0
	def.outer_radius = 145.0
	# hard_fail and faster than a walk: 145/92 * 2 = 3.15s.
	def.telegraph_time = 3.3
	def.mobile = true
	def.speed = 165.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 26
	def.hard_fail = true
	def.weight = 1.5
	# Half the cap of the ordinary act I rows, and a third of `dog_walker`'s. At one event per
	# block a lethal thing at full density would be a minefield rather than a street — and M28's
	# rule that nothing else shares a lethal field means each one also quietly empties 145px of
	# pavement around it.
	def.max_per_day = 5
	def.cost = 3
	return def

## A jingle you can hear three streets away, and children arriving from everywhere.
##
## The `busker` argument, one size up and on day 2: nothing about it is threatening, it is
## simply interesting. Stationary, with the widest ordinary radius in act I — it is the act I
## answer to *"what makes a whole area unusable without anything being wrong"*.
##
## At the kerb since M34, for the same reason as the delivery van: a van parked in a traffic lane
## is a van the crowd drives through, and an ice cream van is a thing children cross a road to
## reach rather than a thing standing in one.
static func _ice_cream_van() -> EventDef:
	var def := EventDef.new()
	def.id = "ice_cream_van"
	def.display_name = "Ice cream van"
	def.look = EventDef.Look.ICE_CREAM_VAN
	def.first_day = 2
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.pavement_side = EventDef.Pavement.AT_THE_KERB
	def.intensity = 13.0
	def.inner_radius = 48.0
	def.outer_radius = 240.0
	def.telegraph_time = 2.2
	# The jingle is a loop, so the meter cost comes and goes on the same period it does.
	def.pulse_period = 11.0
	# `ice_cream_van.svg` is 50px across.
	def.obstructs_radius = 24.0
	def.weight = 1.5
	def.max_per_day = 5
	def.cost = 2
	return def

## A box lorry reversing across the pavement into a yard, beeper going. Act I's second lethal
## thing, and the one that teaches a different lesson from the cyclist.
##
## The cyclist is *coming down the street at you* and the answer is to get off the pavement. The
## lorry is **stationary and the danger is behind it** — the answer is not to walk into the gap
## it is backing into, which is a thing you have to look at the world to know. Static, so it can
## never chase anybody, and the beeper runs long because a hard fail owes double.
##
## Day 3, which puts one new lethal thing on each of the first act's last two days.
##
## **The yard it is backing into has to be there.** *(M34, playtest 07 finding 15: "the backing
## out lorry does not connect to the building making it hard to visually read".)* It was sited on
## any pavement tile at all and drawn facing east, so most of them were a lorry parked in the
## middle of a footway pointing along it — which is a parked lorry, and a parked lorry is not a
## thing whose danger is *behind* it. `AGAINST_THE_BUILDING` gives it a wall to reverse into and
## turns it to face out of that wall, so the 62px silhouette has its box end buried in the
## frontage and its cab on the pavement. The lesson the event teaches is the shape of the
## picture: what you must not walk into is the gap between the metal and the wall.
static func _reversing_lorry() -> EventDef:
	var def := EventDef.new()
	def.id = "reversing_lorry"
	def.display_name = "Reversing lorry"
	def.look = EventDef.Look.LORRY
	def.first_day = 3
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.pavement_side = EventDef.Pavement.AGAINST_THE_BUILDING
	def.intensity = 16.0
	def.inner_radius = 46.0
	def.outer_radius = 175.0
	# hard_fail, stationary: (175-46)/92 * 2 = 2.80s.
	def.telegraph_time = 3.0
	# The beeper. Steady enough to locate, slow enough to be a countdown rather than a wall.
	def.pulse_period = 1.6
	# `lorry.svg` is 62px across, and 28 + her own 14 is inside the 46 that ends the day — so the
	# metal is solid and touching it is still fatal. See `EventDef.validate()`, which is where
	# that arithmetic is a rule rather than a coincidence.
	def.obstructs_radius = 28.0
	def.hard_fail = true
	def.weight = 1.2
	def.max_per_day = 4
	def.cost = 3
	return def

## **The one thing in the game you have to run from, and it arrives on day 3.**
##
## *(Playtest 07: "the run button is a trap shouldn't be an invariant — there should be legitimate
## cases where running is required." And, in the same breath, when: "can we make it so those cases
## only start appearing on day 3", with "an incident at the start to force running".)*
##
## Everything in the catalogue until now is something you route **around**, and against all of it
## running is strictly worse than walking — `EXCITEMENT_FROM_RUNNING` outweighs the shorter
## exposure every time, which `tests/test_events.gd` asserts row by row. That was a deliberate trap
## and it is still the rule; this is the exception the rule was waiting for. A pursuer cannot be
## routed around, because it goes where she goes, so the only question it asks is *how fast*.
##
## The arithmetic is the design, and every number in it is doing one job:
##
## - **130px/s** sits between a walk (92) and a run (168), and sits there *symmetrically*: walking
##   loses 38px a second and running gains 38. So the two answers give opposite outcomes rather than
##   the same outcome at different costs — and they give them at the same rate, which is the version
##   of this a player can feel. It was 148 until M35, where the second half of the contract was
##   written down: at 148 running gains only 20px a second, so shaking it off takes longer than the
##   chase lasts and the price of doing the right thing is set by the clock instead of by the escape.
## - **It comes through its own telegraph, and stops short.** A pursuer that waits politely hands
##   her more ground in two seconds than the whole chase can take back, so the notice is the sight
##   of it closing — but the sight of it closing *onto her*, which is what playtest 08 was killed
##   by, is not notice at all. `Tuning.pursuit_standoff()` is where it stops: 104px, six tenths of a
##   second of its own speed outside the radius that ends the day.
## - **Three seconds, or until she has shaken it off.** A run is fourteen points a second, so the
##   chase has a cap; `Tuning.PURSUIT_BREAK_OFF` is what makes reacting *early* worth anything, and
##   the whole encounter costs about 35 points either way — the most expensive moment in act I and
##   much cheaper than the day it buys.
## - **Intensity 12, not 22.** It is lethal; it does not also need to be the loudest thing in act I.
##   At 22 the correct play — run, at 14 points a second, for as long as it takes — cost more than
##   the meter had, and playtest 08's trace has her doing exactly that and losing the day to
##   excitement with the dog still 87px behind her. What ends the day here is the dog, not the noise.
##
## Day 3 because that is the day act I stops being a nice neighbourhood — `cyclist` lands on day 2
## and `reversing_lorry` on day 3 — and because two days of paying for the run button is what makes
## being made to press it read as the rules changing rather than as the rules finally arriving.
## `EventDirector` puts the first one in front of her early on that day; see `Tuning.RUN_TAUGHT_DAY`.
static func _charging_dog() -> EventDef:
	var def := EventDef.new()
	def.id = "charging_dog"
	def.display_name = "Charging dog"
	def.look = EventDef.Look.CHARGING_DOG
	def.first_day = Tuning.RUN_TAUGHT_DAY
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.spawn_mode = EventDef.SpawnMode.AHEAD_OF_PLAYER
	def.intensity = 12.0
	def.inner_radius = 26.0
	def.outer_radius = 150.0
	# The chase proper, once it can end the day. `Tuning.PURSUIT_TIME` is the cap and the reason
	# for it is the price of running, not the fiction.
	def.duration = Tuning.PURSUIT_TIME
	# Its whole notice, spent visibly closing. Comfortably over `PURSUIT_MIN_NOTICE`, because this
	# is the first time the game asks for a key it has spent two days punishing.
	def.telegraph_time = 2.4
	def.pursues = true
	def.pursue_speed = 130.0
	# And it trots off rather than blinking out, which is the other half of M35: a dog that gives up
	# in front of her and then is not there says the chase was never real.
	def.departs_at = 110.0
	def.hard_fail = true
	def.weight = 1.4
	# Rare on purpose. It is the one thing running answers, and a street with three of them on it
	# would turn the run button from an answer into a second walk speed.
	def.max_per_day = 3
	def.cost = 3
	return def

# ------------------------------------------------------- Act II: notices (4-7) ---

## Mobile, unhurried, and it stops. Not dangerous yet — the danger is that you start
## planning around it, which is the point.
static func _police_patrol() -> EventDef:
	var def := EventDef.new()
	def.id = "police_patrol"
	def.display_name = "Patrol"
	def.look = EventDef.Look.POLICE_CAR
	def.first_day = 4
	def.act_tag = 2
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 10.0
	def.inner_radius = 44.0
	def.outer_radius = 185.0
	def.telegraph_time = 1.7
	def.mobile = true
	def.speed = 74.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 40
	def.weight = 3.0
	def.max_per_day = 12
	return def

## Cosmetic dread. Barely moves the meter; it is here so the walls change.
static func _poster_crew() -> EventDef:
	var def := EventDef.new()
	def.id = "poster_crew"
	def.display_name = "Poster crew"
	def.look = EventDef.Look.POSTER_CREW
	def.first_day = 4
	def.act_tag = 2
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 5.0
	def.inner_radius = 30.0
	def.outer_radius = 110.0
	def.telegraph_time = 1.0
	def.obstructs_radius = PERSON_BODY
	def.weight = 2.5
	def.max_per_day = 12
	return def

## The masts switch on and there is nowhere in the city they do not reach. City-wide, so
## it has no edge to route around — the first event in the game the player cannot walk
## away from. Pitched under the walking decay: like the arterial, it does not raise the
## meter, it stops you clearing it.
static func _loudspeaker() -> EventDef:
	var def := EventDef.new()
	def.id = "loudspeaker"
	def.display_name = "Public address"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 5
	def.look = EventDef.Look.NONE
	def.act_tag = 2
	def.city_wide = true
	def.intensity = 2.4
	def.telegraph_time = 3.0
	def.pulse_period = 22.0
	def.cost = 0
	return def

## The curfew announcement itself. The mechanical bite is in Tuning.day_length, which
## shortens every day from 6 onward; this is the moment you are told.
static func _curfew_announce() -> EventDef:
	var def := EventDef.new()
	def.id = "curfew_announce"
	def.display_name = "Curfew announcement"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 6
	def.look = EventDef.Look.NONE
	def.act_tag = 2
	def.city_wide = true
	def.intensity = 6.0
	def.duration = 26.0
	def.telegraph_time = 2.0
	def.intensity_ramp = 0.2
	def.cost = 0
	return def

## Closes a street and is loud about it. The first event that takes a route away rather
## than making it expensive.
static func _checkpoint() -> EventDef:
	var def := EventDef.new()
	def.id = "checkpoint"
	def.display_name = "Checkpoint"
	def.look = EventDef.Look.CHECKPOINT
	def.first_day = 7
	def.act_tag = 2
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 13.0
	def.inner_radius = 52.0
	def.outer_radius = 215.0
	def.telegraph_time = 1.8
	def.obstructs_radius = 60.0
	def.weight = 2.0
	def.max_per_day = 6
	def.cost = 2
	return def

# --------------------------------------------------------- Act III: vans (8-11) ---


## An unmarked van idles first — that idling IS the telegraph, and it runs long because
## the inner radius ends the day. Getting close does not excite the baby; it takes you.
static func _abduction() -> EventDef:
	var def := EventDef.new()
	def.id = "abduction"
	def.display_name = "Unmarked van"
	def.look = EventDef.Look.UNMARKED_VAN
	def.first_day = 8
	def.act_tag = 3
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.CROSSING]
	def.intensity = 20.0
	def.inner_radius = 54.0
	def.outer_radius = 250.0
	def.duration = 34.0
	# hard_fail doubles the required margin: (250-54)/92 * 2 = 4.26s.
	def.telegraph_time = 4.6
	# A van is a van: 22 + her own 14 leaves the 54 that takes her comfortably reachable, so the
	# body only ever stops her during the idling, which is the phase where it has not happened yet.
	def.obstructs_radius = VEHICLE_BODY
	def.hard_fail = true
	def.weight = 2.0
	# The `hard_fail` caps rise with the rest, but by half as much: at one event per block the
	# late city should feel *occupied*, not landmined. Four unmarked vans across forty-nine
	# blocks is one every twelve; twelve of them would be a difficulty setting nobody asked for.
	def.max_per_day = 4
	def.cost = 3
	return def

## **A man in an alley who is worth crossing the road for, and who comes after you if you do not.**
##
## *(M36, playtest 09: "a robber should increase excitement on sight and getting close to them
## should be day ending", and, in the next breath, "if you get close they should start moving
## towards you".)*
##
## It was a 42px field: alleys only, deliberately tiny, on the argument that *the alley itself is the
## warning*. That argument was fine as far as it went and it went nowhere — a lethal radius of 30
## inside a field of 42 is a thing that does nothing at all until it does everything, which is
## playtest 07's whole complaint about the catalogue arriving at the one row where it is fatal. And
## it never moved, so it was avoidable by walking two tiles wide of it for ever.
##
## The three numbers are the three sentences the player used, in order:
##
## - **On sight.** 16 over a 200px field, so the far end of an alley is already expensive and the
##   meter is what tells you he is there. This is the *only* warning the design will give: a robbery
##   has no telegraph you could see coming, and it never did.
## - **Getting close is day ending.** Unchanged — `hard_fail` inside 30px — except that it can now
##   actually be reached. The `PERSON_BODY` M34 gave him comes back off, because a pursuer with a
##   body is a moving wall and the M19 `dog_walker` decision says no.
## - **Get close and he comes at you.** `pursues_within` 140: inside that he stands up, takes 1.8s
##   of visibly coming — the notice `Tuning.PURSUIT_MIN_NOTICE` owes her — and then chases at
##   130px/s until she has shaken him off. Walking away does not work and running away does, which
##   is exactly `charging_dog`'s contract arriving in act III as a *place* rather than a moment.
##
## The alley is still the warning; it is just no longer the only one.
static func _alley_robbery() -> EventDef:
	var def := EventDef.new()
	def.id = "alley_robbery"
	def.display_name = "Robbery"
	def.look = EventDef.Look.ROBBER
	def.first_day = 8
	def.act_tag = 3
	def.placement = [GameEnums.TileType.ALLEY]
	def.intensity = 16.0
	def.inner_radius = 30.0
	def.outer_radius = 200.0
	# From the moment he notices her, not from dawn. See `EventDef.pursues_within`.
	def.telegraph_time = 1.8
	def.duration = Tuning.PURSUIT_TIME
	def.pursues = true
	# The same speed as the charging dog, deliberately: a player who learned on day 3 what a thing
	# that comes after you moves like should not have to learn it again in act III.
	def.pursue_speed = 130.0
	# Inside `Tuning.PURSUIT_BREAK_OFF`, and that is a contract rather than a taste. A trigger at or
	# beyond the break-off is a pursuit that loses interest the moment it starts, because she is
	# already standing at the distance that means it has lost her — so walking away would work, and
	# walking away is the one thing that must not. Measured first, then written into
	# `validate_pursuit`: at 170 the rig strolled away from him every time.
	def.pursues_within = 140.0
	# And he walks off when he has lost her, rather than being deleted where he stood.
	def.departs_at = 100.0
	def.hard_fail = true
	def.weight = 1.5
	def.max_per_day = 4
	def.cost = 2
	return def

## A building goes in the night. Enormous, static, and it closes the block.
static func _night_raid() -> EventDef:
	var def := EventDef.new()
	def.id = "night_raid"
	def.display_name = "Raid"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 10
	def.look = EventDef.Look.RIOT_VAN
	def.act_tag = 3
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 24.0
	def.inner_radius = 70.0
	def.outer_radius = 330.0
	def.telegraph_time = 3.0
	def.pulse_period = 6.0
	def.obstructs_radius = 44.0
	def.cost = 4
	return def

# ------------------------------------------------------------ Act IV: open (12+) ---

## Like the fire engine, but it does not leave a fire. It leaves a barricade, and the
## barricade is still there tomorrow.
static func _military_convoy() -> EventDef:
	var def := EventDef.new()
	def.id = "military_convoy"
	def.display_name = "Convoy"
	def.look = EventDef.Look.ARMY_TRUCK
	def.first_day = 12
	def.act_tag = 4
	def.placement = [GameEnums.TileType.ROAD]
	def.intensity = 22.0
	def.inner_radius = 76.0
	def.outer_radius = 300.0
	def.telegraph_time = 3.4
	def.mobile = true
	def.speed = 120.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 50
	def.spawns_on_finish = "barricade"
	def.weight = 2.0
	def.cost = 4
	return def

## Left where a convoy stopped, and left there for the rest of the run.
static func _barricade() -> EventDef:
	var def := EventDef.new()
	def.id = "barricade"
	def.display_name = "Barricade"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BARRICADE
	def.act_tag = 4
	def.intensity = 6.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.obstructs_radius = 62.0
	def.scar_id = "barricade"
	return def

## Grows while it is there — `intensity_ramp` takes it to 1.9x over its duration. A protest
## you could have walked past when you saw it is not one you can walk past two minutes later.
static func _protest() -> EventDef:
	var def := EventDef.new()
	def.id = "protest"
	def.display_name = "Protest"
	def.look = EventDef.Look.PROTEST
	def.first_day = 12
	def.act_tag = 4
	def.placement = [GameEnums.TileType.SQUARE, GameEnums.TileType.CROSSING]
	def.intensity = 15.0
	def.inner_radius = 70.0
	def.outer_radius = 300.0
	def.duration = 150.0
	def.telegraph_time = 2.6
	def.intensity_ramp = 1.9
	def.pulse_period = 8.0
	# *(M37.)* One person's worth until there was a picture of more than one person. This was the
	# clearest case in the catalogue of art deciding a gameplay number: the body may not claim
	# ground the picture does not, which is `_draw_spread`'s rule in the other direction, so a
	# protest that fills a square obstructed 11px because `Look.PERSON` drew one man with no
	# placard. `_draw_protest` draws two ranks across exactly this width now.
	#
	# Under the 70px inner radius on purpose: the loudest part of a protest is still something you
	# stand in rather than bump into, and being stopped at the edge of it would take the choice of
	# how close to cut past away from the player.
	def.obstructs_radius = 55.0
	def.weight = 2.5
	def.max_per_day = 3
	def.cost = 3
	return def

## The last thing in the catalogue and the worst. Static, extreme, lethal at the centre,
## and it shuts a district.
static func _firefight() -> EventDef:
	var def := EventDef.new()
	def.id = "firefight"
	def.display_name = "Firefight"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 13
	def.look = EventDef.Look.FIREFIGHT
	def.act_tag = 4
	def.placement = [GameEnums.TileType.CROSSING, GameEnums.TileType.SQUARE]
	def.intensity = 30.0
	def.inner_radius = 90.0
	def.outer_radius = 380.0
	# hard_fail: (380-90)/92 * 2 = 6.3s.
	def.telegraph_time = 6.5
	def.pulse_period = 2.5
	# The same five flames as a burning building, and far inside the 90 that ends the day.
	def.obstructs_radius = 30.0
	def.hard_fail = true
	def.cost = 5
	return def
