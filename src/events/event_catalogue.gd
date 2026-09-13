class_name EventCatalogue
extends RefCounted
## Every event in the game, defined in code — reviewable in a diff, validated on load, and
## assertable over the whole catalogue in a test. See docs/EVENTS.md for the catalogue table and
## the reasoning behind each row.

# ------------------------------------------------------------------- bodies ---
# A body is **half the silhouette**, never a number chosen for how it plays: the rule in
# `EventDef.obstructs_radius` is that a thing that stands still is solid at the width it is drawn,
# and a body that disagrees with the art is a lie about where she can walk in one direction or the
# other. Two of them repeat often enough to be worth a name; the rest are written at the row that
# uses them, with the sprite they came from.

## `person.svg` is 18px across. A man you edge past on a pavement rather than walk through.
const PERSON_BODY := 11.0
## `vehicle.svg` is 48px across.
const VEHICLE_BODY := 22.0
## The widest a `_draw_spread`-style body (`EventInstance._draw_spread`, `_draw_cafe`) may be on a
## `SIDEWALK` tile before it draws past the pavement it stands on.
##
## A pavement is one piece of walkable ground, `Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE` (64px)
## across, not two lanes a body has to fit inside one of. `EventInstance.setup()` centres a
## stationary, unpinned (`pavement_side == ANY`) body on that whole band rather than leaving it at
## whichever lane tile the scheduler happened to choose, so the ground a row may fill is the full
## band and this is half of it. `tests/test_events.gd`,
## `_test_a_spread_body_fits_the_ground_it_stands_on`, checks it over the whole catalogue.
const SIDEWALK_SPREAD_MAX := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 0.5

static var _all: Array[EventDef] = []
## Derived rows, keyed `"<id>|<level>"`. See `heated()`.
static var _hot: Dictionary[String, EventDef] = {}

## Every heat level a run can reach. Progress runs 0..`RESISTANCE_GOAL`; a fifth completed task
## adds nothing, because full heat is the qualification rather than the last errand. A function
## rather than a `const`, because an autoload's constant is not available at parse time.
static func heat_levels() -> int:
	return Tuning.RESISTANCE_GOAL + 1

static func all() -> Array[EventDef]:
	if _all.is_empty():
		_all = _build()
		# **Every shape of every row, not only the cold one.** The fairness contracts are checked
		# once, on load, from data — so a row that got worse with the resistance and was validated
		# only at heat zero would have its contract stated about precisely the harmless version of
		# itself. The set of shapes is finite because progress is a bounded integer, which is what
		# makes checking all of them possible at all.
		for def in _all:
			for level in heat_levels():
				heated(def, level).validate()
	return _all

## This row at a resistance level, derived once per run and kept.
##
## The derivation itself is `EventDef.at_heat()`; this is the cache in front of it, because a day
## asks for the same heated row once per candidate placement and a duplicate per candidate would be
## thousands of `Resource`s per day.
static func heated(def: EventDef, level: int) -> EventDef:
	if def.heat_response == EventDef.HeatResponse.NONE or level <= 0:
		return def
	var key := "%s|%d" % [def.id, level]
	if not _hot.has(key):
		_hot[key] = def.at_heat(level)
	return _hot[key]

static func by_id(id: String) -> EventDef:
	for def in all():
		if def.id == id:
			return def
	return null

## Every def that may appear on this day, in catalogue order, in the shape `heat` puts them in.
static func available_on(day: int, heat: int = 0) -> Array[EventDef]:
	var found: Array[EventDef] = []
	for def in all():
		if def.available_on(day):
			found.append(heated(def, heat))
	return found

static func of_kind(kind: GameEnums.EventKind, day: int, heat: int = 0) -> Array[EventDef]:
	var found: Array[EventDef] = []
	for def in available_on(day, heat):
		if def.kind == kind:
			found.append(def)
	return found

static func _build() -> Array[EventDef]:
	return [
		# Act I - a nice neighbourhood.
		_playground(),
		_cat_dash(),
		_alley_mouse(),
		_dog_walker(),
		_cafe_tables(),
		_delivery_van(),
		_homeless_yeller(),
		_busker(),
		_construction(),
		_fire_truck(),
		_burning_building(),
		_burnt_shell(),

		# Act I - the neighbourhood with things in it, and two that can end the day.
		_loose_dog(),
		_market_stall(),
		_leaf_blower(),
		_pigeon_flock(),
		_cyclist(),
		_ice_cream_van(),
		_reversing_lorry(),
		_charging_dog(),
		_chatting_mother(),

		# Act II - notices.
		_police_patrol(),
		_poster_crew(),
		_loudspeaker(),
		_curfew_announce(),
		_roadblock(),
		_checkpoint_hut(),
		_checkpoint_gate(),
		_checkpoint_post(),

		# Act III - vans.
		_abduction(),
		_alley_robbery(),
		_night_raid(),

		# Act IV - open.
		_military_convoy(),
		_barricade(),
		_protest(),
		_firefight(),

		# Seal pictures - off the day's route tree, never rolled by the ordinary scheduler. See
		# SealPlanner and docs/DECISIONS.md, "Eight seal pictures".
		_fallen_tree(),
		_car_accident(),
		_skip(),
		_scaffolding(),
		_burst_water_main(),
		_moving_van(),
		_burnt_out_car(),
		_collapsed_frontage(),

		# The finale — never rolled by the ordinary scheduler, placed only by `FinalePlanner` and
		# `InteriorEvents`. See "the finale" below.
		_finale_explosion(),
		_impact_crater(),
		_masked_pursuer(),
		_basement_steam(),
	]

## The reason parks are not a free win. Permanent, wide, and sitting in the middle of the
## calmest ground in the city.
##
## **This is the one ambient row that lives on calm ground, and two different rates price it.**
## `PLAYGROUND` is on `Tile._CALM`, so the decay under it is
## `EXCITEMENT_DECAY_WALKING × EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` — **12.0/s** — and that is
## what it has to beat at the peak of its pulse to cost anything at all to stand in. A row under it
## at the peak never out-emits the ground it stands on at any distance or any phase of its beat, and
## standing in a playground would be a net *benefit*. At 15 it clears that by three.
##
## **The radius it denies is the other rate, and it is deliberately not this one.**
## `EventScheduler._denial_radius` asks `Tuning.CALM_ZONE_DENIAL_RATE` (7.7/s), which is fixed:
## which rows may deny park ground is a decision about parks rather than about how fast the pram
## settles, so the walking decay moving does not move it. At 15 the denial radius is 117px at the
## top of the beat and 86px at the middle, against a park block 256px across. It dominates the
## middle of a park and leaves the far side genuinely calm, and `tests/test_balance.gd` still finds
## a day winnable, because the ground is contested rather than removed.
##
## **The trap is that the two rates can drift apart under this row and nothing else would say so**:
## it is the only thing in the catalogue that stands on calm ground, so no other part of the balance
## goes wrong to point at it. Its pulse runs 0.25 to 1.0 of `intensity`, so what it charges swings
## across the ground's own decay over its nine seconds — the middle of a playground is expensive at
## the top of the beat and free at the bottom, which is a rhythm to walk through rather than a
## constant tax.
static func _playground() -> EventDef:
	var def := EventDef.new()
	def.id = "playground"
	def.display_name = "Playground"
	def.kind = GameEnums.EventKind.AMBIENT
	def.ambient_source = EventDef.AmbientSource.PLAYGROUND
	def.look = EventDef.Look.NONE  # The park's swing frame already draws it.
	# Above the decay on the ground it stands on (12.0/s), which is the whole of what an event on
	# calm ground has to clear to exist at all. See the note above.
	def.intensity = 15.0
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
## **Two things make a cat happen at all, and without either it is an event nobody meets.**
##
## It is `AHEAD_OF_PLAYER`, because a cat is not a place: sited on a road tile at dawn it runs its
## two seconds out somewhere across the city, alone. The director puts it across her line while she
## is walking, so it happens in front of her every time.
##
## And it is `still_while_telegraphing`. `EventInstance` starts a mobile event moving when the
## telegraph does, which is right for a siren approaching from three streets away and wrong for a
## crouch: the path is one street wide, so at 240px/s the cat finishes its whole run *during* the
## telegraph — never reaching full intensity, never drawing the running sprite.
##
## **That held-still telegraph is also why it needs its own siting distance rather than the flat
## `AHEAD_LEAD_DISTANCE` every other crossing row uses.** A cat sited two seconds of walking ahead
## and then held still for `telegraph_time` is still two seconds ahead when it finally moves —
## measuring where she *was*, not where the telegraph's own hold has let her get to — so by the
## time it crosses the middle of the road it is reliably behind her rather than in front.
## `EventDef.ahead_of_player_lead()` prices the hold in as walking distance instead, so the siting
## is where she will actually be when the cat is.
##
## **Intensity 17, not 15 — a startle spike, judged against the fixed baseline rather than the old
## one.** *(Playtest 25, finding 6: "dashing cat and dog (not pursuing) are basically useless right
## now -- they need a bigger impact.")* There is no `impulse` field and none is added: `CLAUDE.md`'s
## standing decision is that a sharp spike is a short `duration` at high `intensity`, and 1.8s is
## already as short as a crossing this wide can be. **Its dash still projects under
## `Tuning.EXPECTED_IMPACT_POINTS` on a standing player** — `tests/test_danger.gd` holds this
## scenario by name, on the reasoning that the crouch is its own silhouette and needs no second
## cue. A bigger number than this crosses that line and would give the cat a caret for the first
## time, which is a real design question and not one this item decides; left as an open fork
## rather than assumed.
## **Judged against what item 1 leaves behind, not what it started against**: the evidence that
## this row was ever "useless" is a `cat_dash` at the *old*, lower intensity finishing off a day
## whose baseline was already pinned near 100 by the barrier fields the earlier items just silenced
## — raising it while that was still true would have made it an instant loss on contact, which is
## not what was asked for.
static func _cat_dash() -> EventDef:
	var def := EventDef.new()
	def.id = "cat_dash"
	def.display_name = "Cat"
	def.look = EventDef.Look.CAT
	def.shape = GroundShape.point(7.0)
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.spawn_mode = EventDef.SpawnMode.AHEAD_OF_PLAYER
	def.intensity = 17.0
	def.inner_radius = 30.0
	def.outer_radius = 120.0
	# Long enough to carry it the whole way across the street it starts at the edge of:
	# STREET_WIDTH tiles either side at 240px/s is 1.6s, and it must not expire mid-road.
	def.duration = 1.8
	# Faster than a walk, so the escape distance is the forward reach, not the plain radius —
	# `outer_radius · Tuning.field_scale(e)` at the cat's own speed (240px/s, e = 0.48, just under
	# the eccentricity cap): 120 * 1.92 / 92 = 2.51s, plus the margin the row already carried.
	def.telegraph_time = 2.81
	def.mobile = true
	def.still_while_telegraphing = true
	def.speed = 240.0
	# Shared with the other things that happen *to* her rather than being the whole of that budget:
	# the director also has pigeons and, from day 3, the dog.
	def.weight = 2.5
	# Deliberately low where the rest of the catalogue's caps are not. A cat is sited by the director
	# while she walks and `AHEAD_INTERVAL` spreads them 11-26s apart over a 180s day, so past this
	# there is nowhere left for one to happen and the budget goes on cats the day cannot fit.
	def.max_per_day = 8
	return def

## The cat's shape, softened, and placed rather than sited: a mouse that darts across an alley
## when she walks into range of it.
##
## **`MAP`, not `AHEAD_OF_PLAYER`, and that is the one thing this row changes about the shape it
## borrows.** `_cat_dash` needs the director because a road tile picked at dawn could be anywhere
## in the city and she may never cross it; an `ALLEY` tile is not that — alleys are rare, and one
## she is routed through she is, by definition, about to walk down. Placing it the ordinary way,
## on the tile itself, is what lets `EventScheduler._refuses_required_alleys` reach it: that check
## is stated over `def.placement == [ALLEY]` rather than over `alley_robbery`'s own id precisely
## so "a future row sharing it inherits the same refusal without this function changing" — its own
## docstring's words — and this row is that future row. A required alley, one the day's corridor
## runs down with no way round, never offers one; only an alley she chose to detour into can. That
## was written for a lethal row with no telegraph; here it just means the mouse leans toward the
## alleys that were always optional ground, which costs it nothing since it is not a risk either
## way.
##
## **Acts and cap, derived from the cat's.** `first_day`, `last_day` and `act_tag` are left at
## their defaults (1, 0, 1) — exactly what `_cat_dash` leaves them at — so a mouse is everyday
## background texture for the same reason a cat is: neither is a thing the acts turn on. The cap
## is half of the cat's 8. The cat's own is sized against how many `AHEAD_INTERVAL` slots a 180s
## day has room for; an `ALLEY` tile is scarcer than every `ROAD` and `CROSSING` tile a cat may
## cross, and `_refuses_required_alleys` above narrows the pool further still, so a cap the day
## can actually spend has to sit well under the cat's rather than beside it.
##
## **Lower intensity than the cat's 17, because it is a startle rather than a threat** — 9, roughly
## half, on the same 4:1 outer:inner ratio the cat uses (120:30) scaled down to the alley's own
## smaller stage (60:15). The alley she is standing in is already worth `Tuning.EXCITEMENT_FROM_ALLEY`
## (+3.0/s) of ambient dread on its own; the mouse only has to add a spike on top of ground that is
## already tense, where the cat has to make the whole case for itself on an open street.
##
## **No body, nothing lethal.** `shape` is set for the shadow alone — `solid()` is never called —
## and `hard_fail` stays at its default `false`.
##
## **It waits for her rather than running the moment it exists.** `MAP` places it on its `ALLEY`
## tile at dawn, well outside `Tuning.EVENT_STREAM_RADIUS` (900px) — far past
## `Tuning.VIEW_HALF_EXTENT` — so a row that started telegraphing on arrival dashed and finished off
## screen before she was anywhere near the alley, which read as nothing happening at all: the review
## finding this field exists to answer. `pursues_within` is not only for a pursuer any more — see its
## own docstring — so this row sets it (150px) without `pursues`: `EventInstance._check_for_notice()`
## holds it `is_waiting()`, emitting nothing above the ordinary field and not yet on the clock, until
## she is within 150px, and only then does the telegraph start and the path run. 150px is inside
## `VIEW_HALF_EXTENT.y` (180, the shorter axis, so this holds whichever way she is facing) with room
## to spare, and past the field's own `outer_radius` (60px), so the telegraph is always already on
## screen by the time she could feel it. `EventDef.validate()`'s ordinary `Tuning.validate_event()`
## check is unaffected — it is stated over `telegraph_time` against the field's own geometry, not
## over when the clock starts — and still passes at the same numbers as before this field existed.
##
## **The dash crosses the alley's own short axis by construction, not by luck.** `EventInstance`
## reads `map.alley_rects` for the rect this instance landed in and lays its two-point path across
## whichever side of that rect is narrower — the width, since `ALLEY_WIDTH_TILES` (2) is always
## less than an alley's length. She can only ever be walking the long axis, so the dash is always
## across her path and never down it. See `EventInstance._alley_crossing_path()`.
##
## **The picture is `assets/events/mouse.svg`, one look, mirrored — not the prepared directional
## family (`mouse_{front,back}[_diagonal].svg`).** `_cat_dash` does not pick a picture by heading
## either: `_draw_cat` swaps crouched for running on the telegraph alone and mirrors east/west the
## same way `_draw_simple` does for everything else. The mouse does not even keep a second posture
## for its own telegraph — it is already small and already still — so it draws with `_draw_simple`
## exactly as `busker` or `delivery_van` do.
static func _alley_mouse() -> EventDef:
	var def := EventDef.new()
	def.id = "alley_mouse"
	def.display_name = "Mouse"
	def.look = EventDef.Look.MOUSE
	def.shape = GroundShape.point(4.0)
	def.placement = [GameEnums.TileType.ALLEY]
	# **Priced against the cat on each row's own ground, which is not the same ground.** *(2026-09-12:
	# "alley mouse is a bit above charging cat"; "consider that the mouse is in the alley but the cat
	# is usually not".)* A cat is met on an ordinary street, where 6.0/s is given back; a mouse is
	# only ever met in an alley, where 3.5/s is given back and the alley's own
	# `Tuning.EXCITEMENT_FROM_ALLEY` (+3.0/s) is being charged on top. So the alley hands this row
	# most of the gap for nothing, and 21.0 is what is left to buy: it walks to +19.9 in an alley
	# against the cat's +17.6 on a street.
	#
	# **A tiny radius is why the number is large rather than a mistake.** The field is 60px, so the
	# crossing is one and a third seconds — a spike is bought here in intensity, since there is no
	# `impulse` field and a short, loud disc is how this project writes one.
	#
	# The cost table in `docs/EVENTS.md` nets every row against the *same* walking decay, so this
	# row reads cheaper there than the cat does; the note under that table says why.
	def.intensity = 21.0
	def.inner_radius = 15.0
	def.outer_radius = 60.0
	# `Tuning.required_telegraph_time(15, 60, false, 200)` is ~1.09s (outer_radius · field_scale(e)
	# at e = min(0.5, 200/500) = 0.4, scale 1.667, over WALK_SPEED); this carries a margin the same
	# shape as the cat's own.
	def.telegraph_time = 1.4
	# Comfortably past the ~0.32s the physical crossing takes at this speed over the alley's 64px
	# width (`ALLEY_WIDTH_TILES · Tuning.TILE_SIZE`), so `_has_expired()` never cuts the dash short.
	def.duration = 1.0
	def.mobile = true
	def.still_while_telegraphing = true
	def.speed = 200.0
	# Waits unclocked until she is this close — inside VIEW_HALF_EXTENT.y (180px) with room to
	# spare, past outer_radius (60px) — rather than telegraphing from the moment a MAP placement
	# exists, off screen. See the row's own docstring and EventDef.pursues_within.
	def.pursues_within = 150.0
	# Shared with `alley_robbery`'s own weight: the two rows draw from the same `ALLEY`-only pool
	# and neither should be favoured over the other when both are offered the same tile.
	def.weight = 1.5
	def.max_per_day = 4
	return def

## Stationary, loud, and *pulsing* — the intensity envelope means the counterplay is timing
## a pass between yells, which is a different skill from routing around a hazard.
##
## He **paces**, which is what `EventDef.paces` is for, and it is a design decision rather than
## polish: a stationary source is a fixed price on a fixed patch of pavement, so the answer to it is
## a line you draw once and never think about again. A man walking up and down two hundred and fifty
## pixels of footway is a *timing* problem on top of a routing one — the same thing his pulse asks
## for, at a larger scale.
##
## **The cost of pacing is the body.** Anything mobile is exempt from *solid things are solid*,
## because a moving wall on a two-tile pavement pins her against a building. So what stops you
## walking through him is the meter alone, which is why he is 14 over 210px: he is one of the two
## rows on day 1 that a player is most likely to walk *into* rather than around, and a quiet one
## reads as a man who does nothing.
static func _homeless_yeller() -> EventDef:
	var def := EventDef.new()
	def.id = "homeless_yeller"
	def.display_name = "Man shouting"
	def.look = EventDef.Look.YELLER
	def.shape = GroundShape.point(9.0)
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
	def.max_per_day = 18
	return def

## Slow, and it owns the pavement it is on.
##
## **The intensity is the wall, and it has to beat the walking decay.** At 7 it does not: what it
## means along a line through the middle falls under the 6.0/s an ordinary street gives back, so
## walking *through* a dog walker beats walking around it. An obstacle that is cheaper to walk into
## than to avoid is not an obstacle, and what this row is for is being worth turning round and
## crossing at the zebra for.
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
	# The walker's own point, not the dog's — the dog on its lead is a per-part shadow drawn at
	# its own literal radius directly, the same as the abduction's victim or the checkpoint hut's
	# guard, since a two-body composite has no single shape to be either of its bodies.
	def.shape = GroundShape.point(8.0)
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
	# The heaviest weight in act I, and it goes **up** whenever rows are added around it. The density
	# is a fixed number of events, so every new type takes a share of it, and this is one of the two
	# that cannot be allowed to thin out: dog walkers and café frontages are what an ordinary street
	# is mostly made of, where a loose dog and an ice cream van are punctuation.
	def.weight = 4.5
	# **The dog-walker decision has to happen at least twice on day one**, which is the density
	# target stated as one row. A cap in single figures makes it a coin flip. Repeats are fine — the
	# objection is to two of them thirty pixels apart, and `EVENT_SPACING_SAME` is what answers that.
	def.max_per_day = 26
	def.cost = 2
	return def

## The pavement, taken. A café spilling out of its frontage: chairs, tables, conversation, and
## no way past on this side.
##
## **The first event available on day one that cannot be walked through**, and the thing that forces
## a crossing. `construction` does the same job from day 2 and is the loud version of it; this one is
## pleasant, which is worse: nothing about it looks like a hazard and it still costs the street.
## Stationary, so it can never pin the player the way a moving obstruction could.
##
## **Keeps a field, derived from the body rather than reused across it.** *"restaurants should only
## increase your excitement when you're actually close... but they should nonetheless"* — a café is
## a real source of chatter and not a piece of scenery, but 170px reached across the block and
## billed a player who was never near the tables, and the 90px stopgap that followed was still a
## circle standing in for a body: over-reaching across the frontage and under-reaching along it.
## Under M61's field — the Minkowski sum of the body and a kernel — the radii are read straight off
## the body and the street instead: `inner_radius` is `shape.radius + PLAYER_BODY_RADIUS` (24 + 14 =
## 38), she is touching the tables; `outer_radius` is the pavement band's own centre to the
## carriageway's centre line (`SIDEWALK_WIDTH·TILE_SIZE/2 + ROAD_WIDTH·TILE_SIZE/2` = 32 + 32 = 64),
## which is *"bill somebody at the tables and not somebody across the street"* with "across"
## beginning at the centre line.
static func _cafe_tables() -> EventDef:
	var def := EventDef.new()
	def.id = "cafe_tables"
	def.display_name = "Café tables"
	def.look = EventDef.Look.CAFE
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 12.0
	def.inner_radius = 38.0
	def.outer_radius = 64.0
	def.telegraph_time = 1.6
	def.pulse_period = 6.0
	# 24 does not clear `GroundShape.BAND_RADIUS`, so the body it derives stays a point — a café
	# frontage this narrow has no spine to be a capsule about.
	def.solid(GroundShape.band(24.0))
	# Raised with `dog_walker` and for the same reason — see the note there.
	def.weight = 4.0
	# Only what is inside `EVENT_STREAM_RADIUS` ever exists, which is a fraction of the map — so a
	# cap in single figures puts the expected number of cafés she *sees* in a day under one, and the
	# day-1 event built to force a crossing is absent from most day ones.
	def.max_per_day = 24
	def.cost = 2
	return def

## Parked at the kerb, hazards going, half unloaded. Constant and stationary — the plain
## obstacle the route planning is practised on.
##
## **A parked van belongs at the kerb**, and on a `ROAD` tile it is scenery twice over: it stands in
## a traffic lane the crowd knows nothing about and drives straight through, blocking a route nobody
## walks. At the kerb it is on the pavement she is actually using and it takes it — `VEHICLE_BODY` is
## 22px, so 44px of van across a 64px footway, and the answer is the other side of the street.
##
## **Silent.** *"static blockages in general shouldn't increase excitement"* — its whole job is
## standing in the way, and `obstructs_radius` already prices that as a route cost. It is one of
## `SealPlanner`'s soft-seal candidates, placed on every real street off the day's route tree, so an
## ambient field here used to bill several hundred bodies a day for nothing she could see or avoid.
static func _delivery_van() -> EventDef:
	var def := EventDef.new()
	def.id = "delivery_van"
	def.display_name = "Delivery van"
	def.look = EventDef.Look.DELIVERY_VAN
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.pavement_side = EventDef.Pavement.AT_THE_KERB
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 150.0
	def.telegraph_time = 1.3
	# Under `GroundShape.BAND_RADIUS`, so the stationary-vehicle segment rule still reduces it to
	# a point — see `GroundShape.band()`.
	def.solid(GroundShape.band(VEHICLE_BODY))
	def.weight = 2.0
	def.max_per_day = 18
	return def

## A park spoiler, and a pleasant one. Nothing about it is threatening; it is simply
## interesting, which is the whole problem.
##
## **It stands on calm ground, so the calm ground's decay is what its intensity has to beat**, the
## same way `playground`'s does — 12.0/s, `EXCITEMENT_DECAY_WALKING` times the calm multiplier. At
## 13.0 the core of it costs while she is inside `inner_radius`, and that is the whole claim: a
## busker whose peak sat under the ground it stands on would be a park *bonus* with a picture of a
## nuisance on it.
##
## **The number is the lowest one that clears both floors, and that is deliberate, because a louder
## busker denies more park.** `EventScheduler._denial_radius` is stated against the fixed
## `Tuning.CALM_ZONE_DENIAL_RATE` (7.7/s), so intensity is the only thing that moves how much calm
## ground one of these takes out of a lot 704px across — 137.6px of it at 13.0. The other floor is
## that crossing one has to stay worth routing around, which `tests/test_events.gd` reads off the
## cost table.
##
## **What the pulse does to that, because it is easy to read the number as steadier than it is:**
## `pulse_period` swings what it actually emits between a quarter and all of `intensity` every
## seven seconds, so the middle of a busker's field is dearer than the park at the top of the beat
## and cheaper at the bottom. Along a whole line through one it is the rim that decides, and the rim
## is under the park's own decay — a busker is a place to walk round, not a wall.
static func _busker() -> EventDef:
	var def := EventDef.new()
	def.id = "busker"
	def.display_name = "Busker"
	def.look = EventDef.Look.BUSKER
	def.first_day = 2
	def.placement = [GameEnums.TileType.PARK, GameEnums.TileType.SQUARE]
	# Above the 12.0/s a park gives back, which is what a row standing on calm ground has to clear
	# to cost anything at all. See the note above for why it is not higher.
	def.intensity = 13.0
	def.inner_radius = 45.0
	def.outer_radius = 190.0
	def.telegraph_time = 1.7
	def.pulse_period = 7.0
	def.solid(GroundShape.point(PERSON_BODY))
	def.weight = 2.0
	# Kept the lowest of the raised act I caps on purpose: a busker is placed on PARK or SQUARE,
	# which is the only calm ground there is, and `_ensure_one_usable_park` pays for every one
	# that lands on the block it ends up protecting.
	def.max_per_day = 10
	return def

## The only Act I event that is physically in the way. Blocking the sidewalk forces a
## reroute rather than merely inviting one — and since a street is sidewalk|road|sidewalk,
## the road is always still there, so it costs time and exposure, never the day.
##
## **Silent.** *"static blockages in general shouldn't increase excitement"* — a hoarding is not a
## source, it is a thing to walk around, and `obstructs_radius` already prices the detour. It is one
## of `SealPlanner`'s soft-seal candidates, so it stands on every real street off the day's route
## tree; an ambient field on it billed the meter for a wall of boards a street away with nothing to
## point at.
static func _construction() -> EventDef:
	var def := EventDef.new()
	def.id = "construction"
	def.display_name = "Roadworks"
	def.look = EventDef.Look.ROADWORKS
	def.first_day = 2
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 0.0
	def.inner_radius = 46.0
	def.outer_radius = 200.0
	def.telegraph_time = 1.8
	# `SIDEWALK_SPREAD_MAX`, capped from 34: the widest silhouette that reads as roadworks is 2px
	# over the full pavement band, `EventInstance.setup()` centres it on.
	def.solid(GroundShape.band(SIDEWALK_SPREAD_MAX))
	def.weight = 1.5
	def.max_per_day = 15
	def.cost = 2
	return def

## Audible from streets away, moving fast down an arterial road, and it stops at the fire
## `burning_building` calls it in for. Long telegraph, because the whole point of the approach
## is that you hear it coming and have time to get off that street.
##
## Never scheduled directly — a SCRIPTED def with no day, created only once the fire has been
## seen (`EventDef.spawns_on_sight`, `EventManager._summon_what_has_been_sighted()`). The engine
## used to be the day's own one-shot with the fire left behind wherever its route ended; the
## instruction reversed the two — *"the player should encounter the burning building before the
## fire truck ... the fire truck should spawn when the player sees the burning building not the
## other way around"* — so the radii, the speed and the telegraph below are unchanged from that
## row, and only where the def sits in the day (never scheduled, no place of its own) moved.
static func _fire_truck() -> EventDef:
	var def := EventDef.new()
	def.id = "fire_truck"
	def.display_name = "Fire engine"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.FIRE_ENGINE
	def.shape = GroundShape.point(26.0)
	def.intensity = 26.0
	def.inner_radius = 70.0
	def.outer_radius = 340.0
	# A truck at 190px/s outruns a walk, so the fairness rule demands the FULL forward reach of
	# clearance, not just the falloff band — and a field moving that fast reaches further ahead of
	# itself than its own catalogued radius: `outer_radius · Tuning.field_scale(e)` (e = 0.38) is
	# 548px, 5.96s, plus the margin the row already carried. Unchanged by where it is sited: the
	# contract is a property of this geometry and this speed, not of dawn placement versus a
	# runtime summons — see `EventManager._summon_the_sighted_row()` for the siting itself and
	# `tests/test_events.gd` for the worst-position check the new siting owes on top of it.
	def.telegraph_time = 6.27
	def.mobile = true
	def.speed = 190.0
	return def

## Act I's finale, and the day's own one-shot: placed in a building like every other set piece,
## rather than left behind by something that drove through it. `spawns_on_sight` is what calls
## the engine in the moment she first sees it.
##
## **The telegraph is no longer an arrival's warning; it is how long she has once it is in
## view.** A fire that was already burning when she turned the corner has no approach to
## telegraph — what would be damped is a thing that has already started — so the 2.2s below
## buys the same escape the ordinary contract always has
## (`(outer_radius - inner_radius) / WALK_SPEED` = 2.17s, `Tuning.validate_event()`), read now as
## the moment she notices rather than the moment it arrives. The pulse, the obstruction (30px,
## five flames) and the `burnt_shell` scar are unchanged: a place she finds still burns and still
## blocks the way through, whichever way she came upon it.
static func _burning_building() -> EventDef:
	var def := EventDef.new()
	def.id = "burning_building"
	def.display_name = "Burning building"
	def.kind = GameEnums.EventKind.ONE_SHOT
	def.look = EventDef.Look.BURNING_BUILDING
	def.first_day = 3
	def.last_day = 3
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.pavement_side = EventDef.Pavement.AGAINST_THE_BUILDING
	def.intensity = 18.0
	def.inner_radius = 60.0
	def.outer_radius = 260.0
	def.telegraph_time = 2.2
	def.pulse_period = 3.0
	# Five flames spanning ±31px, and you do not walk through a burning building. Not lethal by
	# decision — what ends a day is in act III — so the body is simply the fire.
	def.solid(GroundShape.point(30.0))
	def.scar_id = "burnt_shell"
	def.spawns_on_sight = "fire_truck"
	def.cost = 4
	return def

## What is left the next morning, and every morning after. Cordoned off, never repaired.
## Almost silent — it is a reminder rather than a hazard, and it is on the same corner on
## day 12 as it was on day 4.
##
## **Silent and solid are not the same claim**, and reading "not an obstacle" as "no body" is how a
## burnt-out building becomes a thing you can stand inside. What it costs the meter is 2.5/s and
## what it costs the route is a corner. `_draw_spread` draws the cordon at exactly the width of the
## body, so this number is also how wide it looks: at 36 it is a shell, where a person's 11 would
## draw a two-barrier sliver.
##
## **Radii derived from the body.** Both lose the segment's own `half_length` (12, from `band(36)`)
## so the along-axis reach is unchanged: `inner_radius` 30 → 18, `outer_radius` 90 → 78. 18 falls
## under the body's own 24px rounding, so it is clamped there — a field cannot start inside ground
## that is already solid.
static func _burnt_shell() -> EventDef:
	var def := EventDef.new()
	def.id = "burnt_shell"
	def.display_name = "Burnt-out building"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BURNT_SHELL
	def.intensity = 2.5
	def.inner_radius = 24.0
	def.outer_radius = 78.0
	def.telegraph_time = 0.7
	def.solid(GroundShape.band(36.0))
	return def

# ----------------------------------------- Act I: variety, and two with teeth ---
# **Act I has to escalate, and its danger is the neighbourhood's own.** With every `hard_fail` row
# starting on day 8 or later, half a run has nothing lethal in it but a car the player is never
# obliged to step in front of.
#
# The shape of that is a decision rather than a derivation, and it is taken **against a patrol**:
# act I is a nice neighbourhood, and a police patrol in it on day 2 tells a story the game tells in
# act II. So the two lethal rows are **a kid on a bike and a lorry reversing across a pavement** —
# what a person pushing a pram is actually frightened of — arriving on days 2 and 3.
#
# The rest is variety, and each row owes a silhouette of its own; see the note on `EventDef.Look`.

## The leash slipped, and the dog is running — down the pavement she is on, toward her.
##
## The counterpart to `dog_walker` and the reason both exist: that one is a *span* you decide
## whether to cross the street to avoid, this one is a *thing coming down the pavement* that you
## cannot out-walk. Faster than `WALK_SPEED`, so it earns a badge at the screen edge and the
## fairness contract makes it pay for the whole radius rather than the falloff band.
##
## `TOWARD_PLAYER`, sited by `EventDirector` on her own line when she gets close rather than on a
## street the day chose at dawn — a dog sited before the day knows where she walks is a dog she may
## never pass, and the whole content of the row is meeting it. It is not `pursues`: it does not
## adjust to her or stop at a stand-off, it is a straight line down the pavement that she answers by
## crossing the street or turning, the same way a real dog running loose does not know she is there.
##
## Not lethal, deliberately. Act I gets exactly two things that end the day and this is not one
## of them: a loose dog is loud and it is chaos, and the day it ruins is ruined through the
## meter, which is where most of the game lives. That decision is untouched by the intensity below.
##
## **Intensity 32, not 24 — the same startle-spike ask as `cat_dash`, judged the same way.**
## *(Playtest 25, finding 6.)* A real meeting already costs more than the walk-through table
## suggests, since the whole point of `TOWARD_PLAYER` is that she dodges rather than walks the
## line — but the player met it and called it inconsequential, so the number moves. No new field:
## it is the other half of day 1's wall pool alongside `leaf_blower`, and it stays comfortably over
## `Tuning.WALL_WORTH_OF_COST` before and after, so raising it changes nothing about which pool it
## is drawn from or how often it is placed.
static func _loose_dog() -> EventDef:
	var def := EventDef.new()
	def.id = "loose_dog"
	def.display_name = "Loose dog"
	def.look = EventDef.Look.LOOSE_DOG
	def.shape = GroundShape.point(9.0)
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.spawn_mode = EventDef.SpawnMode.TOWARD_PLAYER
	def.intensity = 32.0
	def.inner_radius = 30.0
	def.outer_radius = 140.0
	# Faster than a walk, so the escape distance is the forward reach: `outer_radius ·
	# Tuning.field_scale(e)` at 132px/s (e = 0.264) is 190px, 2.07s, plus the margin the row already
	# carried.
	def.telegraph_time = 2.25
	def.pulse_period = 2.2
	def.mobile = true
	def.speed = 132.0
	# The other half of day 1's wall pool; see `leaf_blower` for the measurement both numbers came
	# out of. Between them they are the whole of what *"leaving the path should be lethal or very
	# expensive"* can be built from on the one day the game has nothing lethal in it at all.
	def.weight = 3.0
	def.max_per_day = 24
	def.cost = 2
	return def

## A market trestle taking the pavement, and the second thing on day 1 that forces a crossing.
##
## **One obstacle repeated eighteen times is a rule, not a decision**, which is why day 1 needs a
## second one. This is louder and wider than `cafe_tables` and on the other side of pleasant: a café
## you squeeze past is a nuisance, a market is a crowd.
##
## **Keeps a field, derived from the body the same way `cafe_tables` is** — a market is a real
## crowd, not scenery, but the reach has to match the source. Its body's own rounding is the same
## 24px (`GroundShape.BAND_RADIUS`, since 28 clears it into a real segment), so the derivation gives
## the identical pair: `inner_radius` = 24 + `PLAYER_BODY_RADIUS` (14) = 38, `outer_radius` = the
## pavement band's centre to the carriageway's centre line = 64. See `cafe_tables` for the full
## derivation; the two rows differ in body and intensity, not in how far either field reaches.
static func _market_stall() -> EventDef:
	var def := EventDef.new()
	def.id = "market_stall"
	def.display_name = "Market stall"
	def.look = EventDef.Look.STALL
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 14.0
	def.inner_radius = 38.0
	def.outer_radius = 64.0
	def.telegraph_time = 1.7
	def.pulse_period = 8.0
	def.solid(GroundShape.band(28.0))
	def.weight = 1.6
	def.max_per_day = 13
	def.cost = 2
	return def

## The loudest thing in act I, and it is a man tidying a park.
##
## Deliberately allowed on `PARK`: a calm block with a leaf blower in it is calm ground she cannot
## use, which is what a spoiled park is made of — somewhere to walk to that turns out to be
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
	def.solid(GroundShape.point(PERSON_BODY))
	# **A wall row, and on day 1 it is half of the entire wall pool** — so its weight and its cap are
	# most of what *"leaving the path should be lethal or very expensive"* is built out of on the one
	# day with nothing lethal in it.
	#
	# **Which of the two binds is a different answer on different days**, and that is the part worth
	# carrying. A **cap** binds on the middle days, where the lethal wall rows are capped in single
	# figures across 121 blocks and the deep band has nothing deadly in it whatever the budget does.
	# A **weight** binds on day 1, where no cap is ever reached: a row is only *offered* as often as
	# its weight, so the wall share is fixed however high the ceiling goes. Raising a cap the day
	# never reaches is the other half of *a budget the catalogue cannot spend is not density*.
	#
	# At 3.0 and 24, measured over five seeds, day 1 places 29 walls and the cost per tile of street
	# runs **corridor 0.202 / rim 0.253 / deep 0.216** — the gradient the design asks for, *stray one
	# turning and it is expensive*. It costs about six placements a day, because the budget buys
	# dearer rows, and it makes a leaf blower as common a sight as a dog walker: the price of day 1
	# having exactly two rows a wall can be made of.
	def.weight = 3.0
	def.max_per_day = 24
	def.cost = 2
	return def

## Pigeons off the pavement all at once — on the ground in front of her, then up, then away.
##
## The second `AHEAD_OF_PLAYER` event, and the reason to have a second one is that the director
## had a single trick: every moment that happened *to* her was a cat. A flock is the cheapest
## possible version of the same idea and it is the one that makes the director read as a
## director rather than as a cat dispenser.
##
## **Four things have to be true for a flock to be an event at all**, and each of them is a way this
## row has been ineffective:
##
## - It must not be **over before she arrives**. Sited two seconds of walking ahead, a short
##   telegraph plus a short burst expires exactly as she reaches it. The telegraph is the flock *on
##   the pavement*, long enough to be seen from down the street and walked around, and the burst
##   outlasts her arrival rather than ending at it.
## - It must not be **quiet and small**: 42 over a 168px reach, in a game where a café is 12 over
##   170, is nothing. A flock going up in a pram's face is one of the loudest things that can happen
##   on an ordinary pavement.
## - It must not be **deleted at the top of its climb**, which is what `EventDef.departs_at` is for.
##   They fly off.
## - And the **birds** have to move, not just the event. Copies of one sprite at fixed offsets
##   sharing a single `rise` term go up in one movement and hang in the air for the whole burst,
##   which is what a player looks at and calls broken however correct the field is.
##
## So it is `flock_size` birds, each with its own heading, speed, height and wingbeat, each an
## emitter in its own right — see `EventInstance`, "the flock". The numbers here follow from that:
##
## - **The intensity is a total to be shared out**, so it buys eleven overlapping fields rather than
##   one. Walking round the edge meets one bird; walking through the middle meets five. It is the
##   third loudest thing on an act I pavement at the centre and nearly free at the rim, which is
##   what a thing worth *routing* around looks like.
## - **`flock_spread` comes out of `outer_radius`, not on top of it.** A bird emits over
##   `outer_radius - flock_spread`, so the union of eleven moving fields is inside the one disc the
##   fairness contract was checked against. The telegraph is still measured against 168px.
## - **It fades as they climb.** `intensity_ramp` is the burst being loudest at the instant they go
##   up, which is also what earns it a caret for the whole burst rather than only the telegraph: a
##   flock is danger that changes over time, which is the one thing the mark is for.
static func _pigeon_flock() -> EventDef:
	var def := EventDef.new()
	def.id = "pigeon_flock"
	def.display_name = "Pigeons"
	def.look = EventDef.Look.BIRDS
	# A flock has no single body — each bird casts its own shadow at its own faded radius (see
	# `EventInstance._draw_birds`) — so this is a nominal point at one bird's own base radius
	# (5.0, before the height fade), carried only to satisfy "a row with a look has a shape".
	# Chosen where the design was silent: nothing reads this row's own `shape` elsewhere, since
	# it never obstructs.
	def.shape = GroundShape.point(5.0)
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE,
			GameEnums.TileType.PARK]
	def.spawn_mode = EventDef.SpawnMode.AHEAD_OF_PLAYER
	def.intensity = 42.0
	def.inner_radius = 26.0
	def.outer_radius = 168.0
	# Eleven of them over a 62px wheel: enough that the middle is unmistakably a crowd of birds and
	# few enough that a player can see the gaps between them and aim at one.
	def.flock_size = 11
	def.flock_spread = 62.0
	def.intensity_ramp = 0.4
	def.duration = 4.0
	# On the ground the whole time, which is what makes this a thing to walk around rather than a
	# thing that happens. Over the 1.55s the contract asks of a 168px field.
	def.telegraph_time = 1.7
	# Faster than she can run, and up: they are gone in a second and a half and they are gone
	# *somewhere*.
	def.departs_at = 190.0
	def.weight = 1.5
	def.max_per_day = 5
	return def

## **The first thing in the game that can end your day, and it arrives on day 2.**
##
## A kid on a bike on the pavement she is walking, bell going, coming toward her. Everything about
## it is ordinary, which is the point: act I acquiring danger must not mean act I becoming sinister,
## it means act I being a real street. A pram and a bicycle at speed is what a person pushing one is
## actually frightened of.
##
## `TOWARD_PLAYER`: `EventDirector` sites it on her own line when she gets close, coming the other
## way, so she has to answer with a route decision — cross to the other side, or turn — rather than
## meeting it on a street the day chose at dawn, before it knew whether she would ever walk down it.
## It does not `pursue`: a bike does not chase, it rides straight through wherever she was standing.
##
## The fairness contract does the work — `hard_fail` doubles the margin and the speed means the
## whole radius counts, so the bell has to ring for (90/92) x 2 = 1.96s before it arrives. That is
## right: it is audible from down the street, she has two seconds and one step to make, and stepping
## off a pavement is a step. It is also why the field is this size — a field wider than
## `Tuning.min_offscreen_lead(speed + WALK_SPEED)` (231px at this row's 165px/s — 180 for the
## vertical axis plus 51 for 200ms of closing) would already be on her the moment it appeared on the
## axis and moment `EventDirector` sites it closest to; `EventDef.validate()` refuses that
## arrangement and 90 sits comfortably under it.
##
## **`hard_fail` has to survive its own telegraph, or the "ends your day" above is not true.**
## *(2026-09-07: "also a biker hit should be lethal.")* `EventInstance.is_lethal_at()` refuses the
## whole time an event `is_telegraphing()`, so `EventDirector._toward_her()` sites a `hard_fail` row
## at `Tuning.outlasting_telegraph_lead()` rather than the ordinary offscreen margin — for this row
## the telegraph term dominates on every heading: `(2.0 + 0.2) * 257` = 565px, against at most 371px
## from the offscreen margin alone.
##
## **The field stays this size rather than wider, because `outer_radius` and `telegraph_time` are
## one number under the doubled `hard_fail` margin: how long she is warned for and how far it can be
## felt from move together, at the fixed ratio `Tuning.TELEGRAPH_HARD_FAIL_MARGIN` sets against
## `WALK_SPEED`.** *(2026-09-07: "while biker is now too long notice" — the player reversing the
## caution this row was built with, that shortening the telegraph "buys the lethality back by taking
## the notice away". The complaint has flipped for this row: not too little warning, but watching it
## close from off screen for over three seconds. `EventInstance.is_lethal_at()` still refuses the
## whole telegraph, so the arrival still has to land after it ends — this row's siting is what keeps
## that true at any size, and it is why the field moved rather than only the telegraph.)*
##
## **`inner_radius` is 33px, not the 26 a bike's own width would suggest.** *(Playtest 25, finding
## 7: "biker currently is also basically inconsequential. when hit it should be dayending" — and the
## report was from the local desktop build, where dying otherwise demonstrably works, so the miss was
## the radius rather than the day loop.)* 26px sits *under* the 32px spacing between the two lanes of
## a two-tile pavement (`Tuning.TILE_SIZE`, a lane on its own tile centre), the same gap that let
## `chatting_mother`'s `detain_radius` be walked past on the far lane — see that row for the shared
## reasoning. Both are "it catches you" rows reported as catching nobody, and both move to the same
## 33px: past the lane spacing, under `outer_radius` with room to spare, so the far lane of her own
## pavement no longer answers a bike coming down it for free.
##
## Day 2 rather than day 1 on purpose. Day 1 is allowed to be easy as long as the difficulty then
## climbs, and this is the plainest possible way to say it climbed: day 2 is the day the streets
## acquire something that can take the day off you.
static func _cyclist() -> EventDef:
	var def := EventDef.new()
	def.id = "cyclist"
	def.display_name = "Cyclist"
	def.look = EventDef.Look.CYCLIST
	def.shape = GroundShape.point(12.0)
	def.first_day = 2
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.spawn_mode = EventDef.SpawnMode.TOWARD_PLAYER
	def.intensity = 18.0
	def.inner_radius = 33.0
	def.outer_radius = 90.0
	# hard_fail and faster than a walk, so the escape distance is the forward reach and the margin
	# is doubled: `outer_radius · Tuning.field_scale(e)` at 165px/s (e = 0.33) is 134px, * 2 / 92 =
	# 2.92s, plus the margin the row already carried.
	def.telegraph_time = 2.97
	def.mobile = true
	def.speed = 165.0
	def.hard_fail = true
	def.weight = 1.5
	# Well under the ordinary act I rows, and the cap now does different work than its number
	# suggests: `TOWARD_PLAYER` never puts it on a tile, so it cannot tile a street the way a `MAP`
	# row could. What the cap still bounds is how much of the day's budget — `cost` 3 each — goes to
	# cyclists rather than to cafés and construction, and `Tuning.AHEAD_INTERVAL` (11-26s apart)
	# throttles the rest: the director draws one owed row at a time from a shared queue with the
	# cat and the dog, so how many of fourteen she could ever actually meet is bounded by the day's
	# own length long before the cap is.
	def.max_per_day = 14
	def.cost = 3
	return def

## A jingle you can hear three streets away, and children arriving from everywhere.
##
## The `busker` argument, one size up and on day 2: nothing about it is threatening, it is
## simply interesting. Stationary, with the widest ordinary radius in act I — it is the act I
## answer to *"what makes a whole area unusable without anything being wrong"*.
##
## At the kerb, for the same reason as the delivery van: a van parked in a traffic lane is a van the
## crowd drives through, and an ice cream van is a thing children cross a road to reach rather than
## a thing standing in one.
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
	def.solid(GroundShape.point(24.0))
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
## **The yard it is backing into has to be there.** Sited on any pavement tile and drawn facing
## east, it is mostly a lorry parked in the middle of a footway pointing along it — which is a
## parked lorry, and a parked lorry is not a thing whose danger is *behind* it.
## `AGAINST_THE_BUILDING` gives it a wall to reverse into and turns it to face out of that wall, so
## the 62px silhouette has its box end buried in the frontage and its cab on the pavement. **The
## lesson the event teaches is the shape of the picture**: what you must not walk into is the gap
## between the metal and the wall.
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
	def.solid(GroundShape.point(28.0))
	def.hard_fail = true
	def.weight = 1.2
	# A lethal wall row, capped like `cyclist` and for the same reason: the deep band off the
	# corridor is where the deadly end of the gradient lives, and a handful across 121 blocks cannot
	# fill it.
	def.max_per_day = 12
	def.cost = 3
	return def

## Another mother with a pram, on her own beat — asked for by the player 2026-09-01, with her own
## cost model in the same sentence: *"getting too close one gets caught up in a conversation that
## takes 5s and consumes 25% excitement. if the baby is already sleeping it's a pure time loss if
## it's not it bears overstimulation risk."* The readings taken from that sentence are recorded in
## `docs/playtests/PLAYTEST-18.md` finding 4.
##
## **A paced pavement fixture, like `homeless_yeller`** — she is *at* a place rather than passing
## through it, and pacing is what guarantees streaming actually meets her rather than her running
## her whole beat unobserved. Her ambient field is person-scale (`intensity` near a passer-by's
## `Tuning.PEDESTRIAN_INTENSITY`, 4.2) and its `outer_radius` is tight, so brushing past her without
## triggering a conversation costs about what an ordinary close pass does — no more.
##
## **The conversation is the new mechanic, and it is a trigger rather than a field**: entering
## `detain_radius` of an instance that has not yet chatted locks the stroller's own movement input
## for `detain_seconds` (`Stroller.detain()`), and the meter cost during that lock is priced
## entirely by `EventInstance.current_intensity()` reading the baby's state, never by anything
## authored here.
##
## **`detain_radius` is 48px — three quarters of the 64px pavement band — and the far-lane rule is
## overturned, twice, by the player.** *(Playtest 25, finding 4: "the chatting lady has a way too
## small capture radius in should be much bigger. right now I can basically walk up to her without
## consequence." Then playtest 38, finding 2, on the branch with it at 33: "the radius of the chatty
## lady for capturing must be larger".)* The first number, 26px, sat *under* the **32px** spacing
## between the two lanes of a pavement (`Tuning.TILE_SIZE`, since a lane sits on its own tile
## centre), so the far lane could never trigger a conversation; the whole content of this row is
## that she catches you, and a radius the far lane clears by construction is a row with a free
## answer — which is exactly what got reported. 33px sat just past the lane spacing and was still
## reported as too small. 48px reaches from either lane of her own pavement to the frontage, so no
## line on her pavement walks past her, while the far pavement — 96px away centre to centre — still
## does. **`inner_radius` is 56 rather than 34 for one reason**: `EventDef.validate()` requires the
## capture to sit strictly inside the inner radius (the chat's flat rate assumes she is inside it),
## so widening the capture widens the full-cost core with it — by a lane's width, which is small
## next to what the conversation itself costs. `outer_radius` stays at 70.
##
## `first_day` 1: act I is the social act, and `test_balance.gd` still passes with her live on it —
## she is `SIDEWALK`-only, so she never contests the calm ground the balance suite measures.
static func _chatting_mother() -> EventDef:
	var def := EventDef.new()
	def.id = "chatting_mother"
	def.display_name = "Another mother"
	def.look = EventDef.Look.CHATTING_MOTHER
	def.shape = GroundShape.point(14.0)
	def.first_day = 1
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 4.5
	def.inner_radius = 56.0
	def.outer_radius = 70.0
	# (70-56)/92 = 0.15s required; not hard_fail, so no doubled margin. Generous rather than tight,
	# since this is the row whose whole point is that the ambient field is nearly nothing next to
	# what the conversation costs.
	def.telegraph_time = 1.0
	def.mobile = true
	def.paces = true
	# A pram's pace, slower than an ordinary walk and a touch slower than `dog_walker`'s 32.
	def.speed = 26.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 8
	def.weight = 2.0
	def.max_per_day = 2
	def.detain_seconds = 5.0
	def.detain_radius = 48.0
	return def

## **The one thing in the game you have to run from, and it arrives on day 3.**
##
## Everything else in the catalogue is something you route **around**, and against all of it running
## is strictly worse than walking — `EXCITEMENT_FROM_RUNNING` outweighs the shorter exposure every
## time, which `tests/test_events.gd` asserts row by row. That is the rule, and this is the
## exception it needs in order not to be a trap: a pursuer cannot be routed around, because it goes
## where she goes, so the only question it asks is *how fast*.
##
## The arithmetic is the design, and every number in it is doing one job:
##
## - **130px/s** sits between a walk (92) and a run (168), and sits there *symmetrically*: walking
##   loses 38px a second and running gains 38. So the two answers give opposite outcomes rather than
##   the same outcome at different costs — and they give them at the same rate, which is the version
##   of this a player can feel. **Asymmetry is the trap**: at 148 running gains only 20px a second,
##   so shaking it off takes longer than the chase lasts and the price of doing the right thing is
##   set by the clock instead of by the escape.
## - **It comes through its own telegraph, and stops short.** A pursuer that waits politely hands
##   her more ground in two seconds than the whole chase can take back, so the notice is the sight
##   of it closing — but the sight of it closing *onto her* is not notice at all.
##   `Tuning.pursuit_standoff()` is where it stops: 104px, six tenths of a second of its own speed
##   outside the radius that ends the day.
## - **A capped chase, and a break-off that pays for reacting early.** A run is fourteen points a
##   second, so the chase needs a cap — but the cap is not what prices the answer;
##   `Tuning.PURSUIT_SHAKEN_OFF` is. About 17 points given promptly: the most expensive moment in
##   act I and much cheaper than the day it buys.
## - **Intensity 12.** It is lethal; it does not also need to be the loudest thing in act I. Much
##   above this the correct play — run, at 14 points a second, for as long as it takes — costs more
##   than the meter has, and the day ends in crying with the dog still well behind her. What ends
##   the day here has to be the dog, not the noise.
##
## `RUN_TAUGHT_DAY` because that is the day act I stops being a nice neighbourhood — `cyclist` lands
## on day 2 and `reversing_lorry` on day 3 — and because two days of paying for the run button is
## what makes being made to press it read as the rules changing rather than as the rules finally
## arriving.
## `EventDirector` puts the first one in front of her early on that day; see `Tuning.RUN_TAUGHT_DAY`.
static func _charging_dog() -> EventDef:
	var def := EventDef.new()
	def.id = "charging_dog"
	def.display_name = "Charging dog"
	def.look = EventDef.Look.CHARGING_DOG
	def.shape = GroundShape.point(13.0)
	def.first_day = Tuning.RUN_TAUGHT_DAY
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	# No `last_day`: the dog recurs after the teaching day rather than being spent by it —
	# *"the tutorial dog may appear later but not as tutorial."* On `RUN_TAUGHT_DAY` itself
	# `spawn_mode` is `AHEAD_OF_PLAYER` and `EventDirector` puts it dead ahead of her, unavoidably,
	# because the lesson depends on it. Every day after, `spawn_mode_on()` answers `MAP` instead —
	# the same row, but placed on a tile the way `alley_robbery` is and met by routing into it
	# rather than appearing in front of whichever way she happens to be walking. One `EventDef`
	# rather than a second row: a later dog needs its own `Look` and there is no spare silhouette to
	# give it (`tests/test_events.gd` refuses two rows sharing one), and `spawn_mode_on()` is the
	# field that lets one row answer two days without ever mutating the shared resource.
	def.spawn_mode = EventDef.SpawnMode.AHEAD_OF_PLAYER
	def.spawn_mode_switches_after_day = Tuning.RUN_TAUGHT_DAY
	def.spawn_mode_after_first_day = EventDef.SpawnMode.MAP
	def.intensity = 12.0
	def.inner_radius = 26.0
	# Wider than the stand-off, and that is a constraint rather than a taste: a pursuer holds its
	# stand-off through its whole telegraph, so a field narrower than that is a field it is never
	# inside — the dog would spend the entire warning emitting nothing at her, the `!` over her head
	# would never go up, and the trace would attribute the mark it eventually raises to "nothing in
	# reach". `validate_pursuit` refuses the arrangement.
	def.outer_radius = 150.0
	# The chase proper, once it can end the day. `Tuning.PURSUIT_TIME` is the cap and the reason
	# for it is the price of running, not the fiction — `tests/test_events.gd` holds every pursuer
	# to this exact ceiling rather than `validate_pursuit`'s looser one, so this is not a lever a
	# further siting may reach for; `telegraph_time` below is.
	def.duration = Tuning.PURSUIT_TIME
	# Its whole notice, spent visibly closing. Comfortably over `PURSUIT_MIN_NOTICE`, and longer than
	# every other pursuer's own reasoning would suggest — see `offscreen_notice` below for why a
	# further siting needs a longer telegraph to spend it in.
	def.telegraph_time = 4.5
	def.pursues = true
	def.pursue_speed = 130.0
	# How far outside the view it starts. See `EventDef.offscreen_notice` for the reasoning behind
	# 0.5 — a playtest-measured notice, well up from the catalogue default. `telegraph_time` above is
	# what pays for the longer approach: closing the worst-case gap at the rate walking away still
	# loses by (`pursue_speed` - `WALK_SPEED` = 38px/s) takes about 7.0s, inside the 7.5s
	# `telegraph_time` + `duration` gives it.
	def.offscreen_notice = 0.5
	# And it trots off rather than blinking out — *nothing vanishes while you are looking at it*, and
	# a dog that gives up in front of her and then is not there says the chase was never real.
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
##
## **The non-lethal rung of the resistance's ladder.** `heat_response = PRESSES`: past
## `GameState.resistance_progress`, more of them and louder, and past `Tuning.HEAT_INVESTIGATES_LEVEL`
## it stops merely patrolling and starts investigating — see `EventDef.at_heat()`. It never gains
## `hard_fail`, whatever the heat; the van is the rung that kills.
static func _police_patrol() -> EventDef:
	var def := EventDef.new()
	def.id = "police_patrol"
	def.display_name = "Patrol"
	def.look = EventDef.Look.POLICE_CAR
	def.shape = GroundShape.point(19.0)
	def.first_day = 4
	def.act_tag = 2
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 10.0
	def.inner_radius = 44.0
	def.outer_radius = 185.0
	# Slower than a walk, so the escape distance is the falloff band stretched forward by the
	# patrol's own eccentricity: `(outer_radius - inner_radius) · Tuning.field_scale(e)` at 74px/s
	# (e = 0.148) is 165px, 1.80s, plus the margin the row already carried.
	def.telegraph_time = 1.97
	def.mobile = true
	def.speed = 74.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 40
	def.weight = 3.0
	def.max_per_day = 12
	def.heat_response = EventDef.HeatResponse.PRESSES
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
	def.solid(GroundShape.point(PERSON_BODY))
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
##
## **Named `roadblock`, not `checkpoint`.** M62's region door took the word — a hut, a gate and
## guards on the sidewalks you can pass at a price — and this row means the opposite: a street you
## cannot pass at all. Two rows drawing armed men across a street and meaning opposite things about
## whether you can get through cannot share a name, and one picture per row fails at the name
## exactly the way it fails at a shared silhouette.
##
## **Drawn as one continuous barrier, not a row of blocks.** *(2026-09-10, playtest 55: "the
## barrier itself also doesn't read as a continuous element. is it using the texture of the other
## orientation and concatenating that one?")* `EventInstance._draw_roadblock()` now reads
## `_draw_spread(ROADBLOCK_SEGMENT, ROADBLOCK_END)`, the same rail-with-caps construction
## `roadworks` already reads as one thing rather than a stack of blocks.
## `assets/events/checkpoint_block.svg` stays bound as the badge's own icon
## (`EventInstance.icon_for()`) — a badge is read small, and the concrete-block silhouette is still
## the clearest single frame of "a street being held"; only the drawn body changed.
##
## **Radii derived from the body, not carried across.** Under M61's field — a capsule about the
## body's own spine rather than a disc about its centre — the along-axis reach from centre has to
## stay what it was, so both radii lose the segment's own `half_length` (36, from `band(60)`):
## `inner_radius` 52 → 16, `outer_radius` 215 → 179, the raw inner falling under the body's own 24px
## rounding (`GroundShape.BAND_RADIUS`) and clamped there — a field cannot start inside the capsule
## that is already solid. That clamp is no longer where `inner_radius` ends up; see below.
##
## **`heat_response = HUNTS`, the lethal rung `abduction` and `night_raid` already climb.** A band
## cannot chase — the guards leave their post instead: the moment a heated copy stops
## `is_waiting()`, `_draw_roadblock()` swaps the barrier for `guard_standing.svg` (still
## telegraphing) and then `guard_lunging.svg` (actually giving chase), the same `is_waiting()`/
## `is_telegraphing()` switch `_draw_robber()` and `_draw_cat()` already read. **The band stays
## exactly as it is until then, and nothing is left behind once the guards go**: its own
## `heat_response` says nothing about that interval, and the smaller of the two rules available is
## to add none — the generic pursuer rule in `EventInstance._process()` already frees the band's own
## obstruction the same frame it stops waiting ("a moving pursuer with a body is a wall"), so no
## phantom barrier is left blocking a street its own guards have abandoned.
##
## **`inner_radius` raised from 24 to 86, for the reachability check rather than the M61 derivation
## above.** `EventDef.validate()` refuses a `hard_fail` body that reaches inside its own lethal
## radius: the band's `obstructs_radius` (60, `band(60)`'s own `reach()`) plus her 14px
## `Tuning.PLAYER_BODY_RADIUS` is 74, over the old 24 by 50px, so a hunting copy's kill could never
## fire. 86 leaves the same 12px margin `night_raid` carries (70 − 58). `outer_radius` and
## `telegraph_time` (1.8s) are unmoved **cold**: the narrower cold field this leaves (93px against
## the old 155) still clears `Tuning.required_telegraph_time()` with room to spare, and
## `Tuning.validate_pursuit()`'s own clauses hold at this radius against the shared
## `HEAT_HUNTS_SPEED`/`HEAT_HUNTS_WITHIN`/`PURSUIT_TIME` — see `tests/test_heat.gd`,
## `_test_the_roadblock_hunts_past_its_own_threshold`.
##
## **The 179px cold field sits under the shared 180px trigger, which the 24px `abduction` and
## `night_raid` never had to notice because their own fields (250/330) already cleared it.**
## `EventDef.at_heat()` widens only the hunting copy's `outer_radius` to `maxf(outer_radius,
## pursues_within)` — the smallest fix that holds for every `HUNTS` row rather than one that asks
## a row's cold field to carry a number that belongs to the ladder — so the roadblock's own 179px
## field is exactly what it was cold, and only the moment its guards start hunting reaches 180px.
## `tests/test_heat.gd`'s generic loop (`_test_a_hunts_row_wakes_up_at_its_own_threshold`) is what
## catches a row whose field sits under the trigger; this one is the row that found it.
static func _roadblock() -> EventDef:
	var def := EventDef.new()
	def.id = "roadblock"
	def.display_name = "Roadblock"
	def.look = EventDef.Look.ROADBLOCK
	def.first_day = 7
	def.act_tag = 2
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 13.0
	def.inner_radius = 86.0
	def.outer_radius = 179.0
	def.telegraph_time = 1.8
	def.solid(GroundShape.band(60.0))
	def.weight = 2.0
	def.max_per_day = 6
	def.cost = 2
	def.heat_response = EventDef.HeatResponse.HUNTS
	return def

# --------------------------------------------------------- Act III: vans (8-11) ---


## An unmarked van idles first — that idling IS the telegraph, and it runs long because
## the inner radius ends the day. Getting close does not excite the baby; it takes you.
##
## **And it takes somebody else first.** While she is close enough to watch (`outer_radius`), it
## draws its own bystander walked to it and taken — `EventInstance._update_the_take()`. A scripted
## figure that belongs to the event, never a real `CrowdAgent`: the crowd is a population of the
## field around the player rather than of the city, recycled as she moves, so a taken pedestrian
## could never be a lasting fact about the world either way. Drawing and telemetry only — nothing
## here changes `contribution_at()`, spawns a body, or reaches into the crowd.
##
## **`heat_response = HUNTS`, the lethal rung of the resistance's ladder.** Below
## `Tuning.HEAT_HUNTS_LEVEL` it is untouched — population and intensity are `PRESSES`'s axes, not
## this one's. At and above it, the derived copy stops idling for a stranger and starts hunting
## her instead: see `EventDef.at_heat()`. It keeps `hard_fail` throughout, because a pursuer is
## exempt from the rule that nothing else happens inside a lethal event's field.
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
	# hard_fail doubles the required margin: (250-54)/92 * 2 = 4.26s. It stays exactly this long
	# once the van hunts, too: a pursuer's telegraph buys the notice of it coming rather than an
	# escape distance (`Tuning.PURSUIT_MIN_NOTICE`, 1.5s), and 4.6s is comfortably over it.
	def.telegraph_time = 4.6
	# A van is a van: 22 + her own 14 leaves the 54 that takes her comfortably reachable, so the
	# body only ever stops her during the idling, which is the phase where it has not happened yet.
	# Once it hunts, `EventInstance` drops this body the moment it stops waiting — a moving wall on
	# a two-tile pavement pins her against a building, the same reason a pursuer never carries one.
	def.solid(GroundShape.point(VEHICLE_BODY))
	def.hard_fail = true
	def.weight = 2.0
	# The `hard_fail` caps rise with the rest, but by half as much: at one event per block the
	# late city should feel *occupied*, not landmined. Four unmarked vans across forty-nine
	# blocks is one every twelve; twelve of them would be a difficulty setting nobody asked for.
	def.max_per_day = 4
	def.cost = 3
	def.heat_response = EventDef.HeatResponse.HUNTS
	return def

## **A man in an alley who is worth crossing the road for, and who comes after you if you do not.**
##
## **A tiny field on the argument that *the alley itself is the warning* goes nowhere**: a lethal
## radius of 30 inside a field of 42 is a thing that does nothing at all until it does everything,
## which is the one row in the catalogue where that is fatal rather than merely dull. And a robber
## who never moves is avoidable by walking two tiles wide of him for ever.
##
## Three numbers for three sentences, in order:
##
## - **On sight.** 16 over a 200px field, so the far end of an alley is already expensive and the
##   meter is what tells you he is there. This is the *only* warning the design will give: a robbery
##   has no telegraph you could see coming, and it never did.
## - **Getting close is day ending.** `hard_fail` inside 30px, and it has to be **reachable**: he
##   carries no body, because a pursuer with one is a moving wall, and because a body that reaches
##   the inner radius means the kill can never fire.
## - **Get close and he comes at you.** `pursues_within` 140: inside that he stands up, takes 1.8s
##   of visibly coming — the notice `Tuning.PURSUIT_MIN_NOTICE` owes her — and then chases at
##   130px/s until she has shaken him off. Walking away does not work and running away does, which
##   is exactly `charging_dog`'s contract arriving in act III as a *place* rather than a moment.
##
## The alley is the warning, and it is not the only one.
static func _alley_robbery() -> EventDef:
	var def := EventDef.new()
	def.id = "alley_robbery"
	def.display_name = "Robbery"
	def.look = EventDef.Look.ROBBER
	def.shape = GroundShape.point(9.0)
	def.first_day = 8
	def.act_tag = 3
	def.placement = [GameEnums.TileType.ALLEY]
	def.intensity = 16.0
	def.inner_radius = 30.0
	# Wider than the trigger, and that is the contract rather than a taste: he may not notice her from
	# outside his own field, because the meter is the only thing that says a stranger in an alley is
	# worth crossing the road for. The sixty pixels between this and `pursues_within` are the row's
	# first sentence — **on sight** — with somewhere to happen.
	def.outer_radius = 200.0
	# From the moment he notices her, not from dawn. See `EventDef.pursues_within`.
	def.telegraph_time = 1.8
	def.duration = Tuning.PURSUIT_TIME
	def.pursues = true
	# The same speed as the charging dog, deliberately: a player who learned on day 3 what a thing
	# that comes after you moves like should not have to learn it again in act III.
	def.pursue_speed = 130.0
	# Outside his stand-off (108px) and inside his field, which is what leaves room for both halves of
	# the row: far enough out that the notice is not spent standing still, near enough that she has
	# felt him for a while before he decides anything about her.
	#
	# The trap, and the reason this is worth a comment rather than a number: with a chase that ends
	# at a *distance*, a trigger at or past that distance is a pursuit that loses interest the
	# instant it starts — she is already standing where it means "it has lost her", and she can
	# stroll away from him every time. `Tuning.PURSUIT_SHAKEN_OFF` ends a chase at a rate instead, so
	# no trigger distance can reproduce it.
	def.pursues_within = 140.0
	# And he walks off when he has lost her, rather than being deleted where he stood.
	def.departs_at = 100.0
	def.hard_fail = true
	def.weight = 1.5
	def.max_per_day = 4
	def.cost = 2
	return def

## A building goes in the night. Enormous, static, and it closes the block.
##
## **`heat_response = HUNTS`, the same rung `abduction` climbs.** Below `Tuning.HEAT_HUNTS_LEVEL`
## it is untouched, exactly as it stands here — a closed block and nothing more. At and above it,
## the derived copy pursues at `Tuning.HEAT_HUNTS_SPEED` (130px/s), notices her within
## `Tuning.HEAT_HUNTS_WITHIN` (180px), chases for `Tuning.PURSUIT_TIME`, and is `hard_fail` — which
## the cold row is not, so unlike `abduction` this row *gains* lethality at the threshold rather
## than keeping it: the van stops emptying the building and comes for her instead, the abduction's
## shape on a bigger vehicle. See `EventDef.at_heat()`.
##
## **It shares the patrol-and-van threshold rather than minting a third constant, and the calendar
## is why that is load-bearing.** The resistance's performs fall on days 5, 7, 9, 11 and 13, so on
## day 10 — the only day this row ever appears — the most progress anybody can hold is 3: sharing
## `HEAT_HUNTS_LEVEL` is what makes the raid hunt *only* a player who has done every task on time,
## and a player one task behind meets the cold raid instead. A row-specific threshold would break
## that sentence for no reason the row needs.
##
## **The body is reachable, and `EventDef.validate()` is the check that says so.** `obstructs_radius`
## 44 plus her own `PLAYER_BODY_RADIUS` 14 is 58, inside the 70 of `inner_radius`, so the lethal body
## sits where the kill can still fire — the same arithmetic every other hunting row clears.
## `EventInstance._process` drops the body the moment a pursuer stops waiting, generic to every
## `pursues` row and unchanged here: a heated raid is solid at the kerb and comes down the frame it
## starts hunting, same as `abduction`.
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
	def.solid(GroundShape.point(44.0))
	def.cost = 4
	def.heat_response = EventDef.HeatResponse.HUNTS
	return def

# ------------------------------------------------------------ Act IV: open (12+) ---

## Like the fire engine, but it does not leave a fire. It leaves a barricade, and the
## barricade is still there tomorrow.
static func _military_convoy() -> EventDef:
	var def := EventDef.new()
	def.id = "military_convoy"
	def.display_name = "Convoy"
	def.look = EventDef.Look.ARMY_TRUCK
	def.shape = GroundShape.point(26.0)
	def.first_day = 12
	def.act_tag = 4
	def.placement = [GameEnums.TileType.ROAD]
	def.intensity = 22.0
	def.inner_radius = 76.0
	def.outer_radius = 300.0
	# Faster than a walk, so the escape distance is the forward reach: `outer_radius ·
	# Tuning.field_scale(e)` at 120px/s (e = 0.24) is 395px, 4.29s, plus the margin the row already
	# carried.
	def.telegraph_time = 4.43
	def.mobile = true
	def.speed = 120.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 50
	def.spawns_on_finish = "barricade"
	def.weight = 2.0
	def.cost = 4
	return def

## Left where a convoy stopped, and left there for the rest of the run.
##
## **Silent.** *"static blockages in general shouldn't increase excitement"* — this is the widest
## hard seal in the game (`obstructs_radius` 62, the whole street), so its route cost is already
## the largest in the catalogue; an ambient field on top billed nothing she could see past the wall
## itself.
static func _barricade() -> EventDef:
	var def := EventDef.new()
	def.id = "barricade"
	def.display_name = "Barricade"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BARRICADE
	def.act_tag = 4
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(62.0))
	def.scar_id = "barricade"
	return def

## Grows while it is there — `intensity_ramp` takes it to 1.9x over its duration. A protest
## you could have walked past when you saw it is not one you can walk past two minutes later.
##
## **Radii derived from the body.** Under M61's field, both lose the segment's own `half_length`
## (31, from `band(55)`) so the along-axis reach from centre is unchanged: `inner_radius` 70 → 39,
## `outer_radius` 300 → 269 — the 39px still clears the body's own 24px rounding, so neither clamps.
static func _protest() -> EventDef:
	var def := EventDef.new()
	def.id = "protest"
	def.display_name = "Protest"
	def.look = EventDef.Look.PROTEST
	def.first_day = 12
	def.act_tag = 4
	def.placement = [GameEnums.TileType.SQUARE, GameEnums.TileType.CROSSING]
	def.intensity = 15.0
	def.inner_radius = 39.0
	def.outer_radius = 269.0
	def.duration = 150.0
	def.telegraph_time = 2.6
	def.intensity_ramp = 1.9
	def.pulse_period = 8.0
	# The clearest case in the catalogue of the picture deciding a gameplay number: a body may not
	# claim ground the drawing does not, which is `_draw_spread`'s rule in the other direction — so a
	# protest drawn as one man obstructs one man's width however much of a square it is supposed to
	# fill. `_draw_protest` draws two ranks across exactly this width.
	#
	# Under the 39px inner radius on purpose: the loudest part of a protest is still something you
	# stand in rather than bump into, and being stopped at the edge of it would take the choice of
	# how close to cut past away from the player.
	def.solid(GroundShape.band(55.0))
	def.weight = 2.5
	# A wall row, capped with the rest of them. Act IV only, so this is the late city's share of the
	# blocking events that make the ground off the paths expensive. A protester obstructs nothing
	# and pursues nothing, so this cap has nothing else's own cap to compete with — and late acts
	# leave enough of the day's budget unspent that this row's own cap is what actually binds.
	def.max_per_day = 12
	def.cost = 3
	return def

## The last thing in the catalogue and the worst. Static, extreme, lethal at the centre,
## and it shuts a district.
##
## **Radii derived from the body, and `inner_radius` here is the lethal one.** Both lose the
## segment's own `half_length` (6, from `band(30)`) so the along-axis reach — including the lethal
## one, which is a plain circle of `inner_radius` about the centre and not itself capsule-shaped —
## is unchanged: `inner_radius` 90 → 84, `outer_radius` 380 → 374. `(outer − inner)` is invariant
## under subtracting the same term from both, so the telegraph arithmetic below is untouched.
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
	def.inner_radius = 84.0
	def.outer_radius = 374.0
	# hard_fail: (374-84)/92 * 2 = 6.3s.
	def.telegraph_time = 6.5
	def.pulse_period = 2.5
	# The same five flames as a burning building, and far inside the 84 that ends the day.
	def.solid(GroundShape.band(30.0))
	def.hard_fail = true
	def.cost = 5
	return def

# --------------------------------------------------------------- seal pictures ---
# Every row below exists only as `SealPlanner` candidate material — `docs/DECISIONS.md`, "Eight
# seal pictures, so that no single barrier becomes the city's signature." Each is `SCRIPTED` with
# `scripted_day = 0`, a day nobody plays, so `EventDef.available_on()` never rolls one and the
# ordinary scheduler never sites one — the same shape `barricade` already uses to keep off the
# day's own budget. `SealPlanner._effective_first_day` reads `act_tag` instead, so `act_tag` here
# is what actually gates the day a seal may use the row, not `first_day`.
#
# **Silent, like every other seal candidate.** *"static blockages in general shouldn't increase
# excitement"* — each carries `intensity = 0.0`. Radii still have to satisfy `EventDef.validate()`
# even at zero intensity, so every row below copies `barricade`'s own geometry (inner 40, outer
# 120, telegraph 0.9) rather than inventing a new one nothing reads.

## A hard seal: a tree down kerb to kerb, root plate at one end and crown at the other — one of
## the player's own two examples for act I. `obstructs_radius` 96 is exactly half the 192px street,
## so `SealPlanner._hard_positions` places a single copy spanning it edge to edge, and
## `fallen_tree.svg` is authored wider than that so `_draw_spread` draws that one copy rather than
## repeating a tree several times across the street.
static func _fallen_tree() -> EventDef:
	var def := EventDef.new()
	def.id = "fallen_tree"
	def.display_name = "Fallen tree"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.FALLEN_TREE
	def.act_tag = 1
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(96.0))
	return def

## A hard seal: two cars locked together across the carriageway, debris between them and an
## onlooker on each pavement — the player's other own example. Same single-copy geometry as
## `fallen_tree`, for the same reason: one continuous scene rather than a repeated segment.
##
## **The one seal that is solid only in parts, and the one that emits.** *(2026-09-12: "a car crash
## right now has a full bounding box even though there are gaps in the sprite. the bounding box
## should only be the crashed cars but it should emanate an excitement field that prevents the
## player from walking past it".)* `shape` stays the whole-street band — it is what the picture is
## fitted to, what the field is stated over, and the disc every planner clears the street by — while
## `solid_parts` puts a body under each car and leaves the debris and the two pavements open. The
## price of walking through one of those gaps is the field, not a wall: see
## `Tuning.CAR_ACCIDENT_INTENSITY`, which is what overturns *a closure is silent* for this row alone
## (`docs/CITY.md`, "A closure is silent").
##
## **The field is stated over the band and not over the cars.** `inner_radius` is
## `GroundShape.BAND_RADIUS` — the band's own surface, since a segment's field is priced from its
## spine — so everything inside the scene's own footprint is charged at the full rate, gaps
## included, and the shoulder outside it is short: 72px, under half a street's width, so the crash
## is felt walking up to it rather than from down the street. A sealed street still has to be
## discoverable by walking into it, which is the reason closures are silent in the first place.
static func _car_accident() -> EventDef:
	var def := EventDef.new()
	def.id = "car_accident"
	def.display_name = "Car accident"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.CAR_ACCIDENT
	def.act_tag = 1
	def.intensity = Tuning.CAR_ACCIDENT_INTENSITY
	def.inner_radius = GroundShape.BAND_RADIUS
	def.outer_radius = 96.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(96.0))
	def.solid_parts = _car_accident_parts()
	if Tuning.CAR_ACCIDENT_GAPS_ARE_LETHAL:
		# The other answer to *prevents*, off by default — see the constant. The lethal radius has
		# to clear the cars' own bodies with her 14px to spare or the kill can never fire
		# (`EventDef.validate()`), and the telegraph has to buy the walk out of the doubled margin.
		def.hard_fail = true
		def.inner_radius = Tuning.CAR_ACCIDENT_LETHAL_INNER_RADIUS
		def.telegraph_time = 1.2
	return def

## Where the two cars stand, read off the two authored pictures at the scale
## `EventInstance._draw_wide_scene` fits each to the street — 192px of street over a 200px picture,
## so a pixel of art is 0.96px of ground and the picture's own centre is the scene's centre.
##
## `car_accident.svg` (north-south street): the cars are drawn at x 63–91 and 92–120, and
## `car_accident_shadow.svg` puts their ground contacts at 77 and 106, which agree — an end-on car
## is drawn directly above its own patch of road. That is −22.1px and +5.8px from the centre.
##
## `car_accident_vertical.svg` (east-west street): the cars are side views, so their drawn bodies
## sit **above** the road they stand on and only the shadow art says where that is — contacts at
## y 88 and 110, which is −11.5px and +9.6px from the centre.
##
## 14px of radius apiece: a car is drawn 28px wide, 26.9px of ground at this scale, and the round
## number is what makes the two bodies meet rather than leaving a one-pixel slot between them on the
## north-south picture. Debris and onlookers carry no body at all — they are what the gaps are.
static func _car_accident_parts() -> Array[EventDef.SolidPart]:
	return [
		EventDef.part(-22.1, -11.5, GroundShape.point(14.0)),
		EventDef.part(5.8, 9.6, GroundShape.point(14.0)),
	] as Array[EventDef.SolidPart]

## Half of a soft seal: a skip at the kerb, facing `scaffolding` on the other pavement. Kerb-pinned
## like `delivery_van`, so `EventInstance._centred_on_the_pavement_band` leaves it exactly where
## `SealPlanner._place_soft` puts it rather than spreading it across the whole band.
static func _skip() -> EventDef:
	var def := EventDef.new()
	def.id = "skip"
	def.display_name = "Skip"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.SKIP
	def.act_tag = 1
	def.pavement_side = EventDef.Pavement.AT_THE_KERB
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.point(VEHICLE_BODY))
	return def

## The other half of the same soft seal: boards over the far footway. `pavement_side` stays `ANY`
## so the auto-centring `construction` uses fills the whole 64px band, the same "boards over the
## far footway" reading the picture gives it.
static func _scaffolding() -> EventDef:
	var def := EventDef.new()
	def.id = "scaffolding"
	def.display_name = "Scaffolding"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.SCAFFOLDING
	def.act_tag = 1
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(SIDEWALK_SPREAD_MAX))
	return def

## A hard seal: a crater with water across the asphalt and a municipal barrier at each kerb — "the
## one that explains why the road is out too" (`docs/DECISIONS.md`, "Eight seal pictures").
## Single-copy geometry, same as
## `fallen_tree` and `car_accident`.
static func _burst_water_main() -> EventDef:
	var def := EventDef.new()
	def.id = "burst_water_main"
	def.display_name = "Burst water main"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BURST_MAIN
	def.act_tag = 1
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(96.0))
	return def

## A soft seal, both bodies the same row: a moving van with its ramp down on each pavement —
## "reuses `Look.LORRY`, the biggest silhouette in act I" (`docs/DECISIONS.md`, "Eight seal
## pictures"), read as the same
## lorry-scale silhouette family rather than the literal `Look.LORRY` enum value, since two rows
## may not share a look or a silhouette (`docs/EVENTS.md`, "the visual vocabulary";
## `tests/test_events.gd`'s `_test_no_two_rows_draw_the_same_picture` and
## `_test_every_look_carries_its_own_silhouette`). `moving_van.svg` is drawn at the same scale as
## `lorry.svg` with its own picture — open doors and a ramp reaching the ground.
static func _moving_van() -> EventDef:
	var def := EventDef.new()
	def.id = "moving_van"
	def.display_name = "Moving van"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.MOVING_VAN
	def.act_tag = 1
	def.pavement_side = EventDef.Pavement.AT_THE_KERB
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	# Over `GroundShape.BAND_RADIUS`, so it is the one stationary-vehicle row whose shape is a
	# segment rather than a point — see `EventInstance._solid_axis()`.
	def.solid(GroundShape.band(28.0))
	return def

## A hard seal, acts II-IV: a car burnt to the shell, `BURNT_SHELL`'s charred palette moved onto a
## vehicle body. Vehicle-scale `obstructs_radius`, so `SealPlanner._hard_positions` spaces four
## across a street's 192px the way it spaces two `barricade` copies — a pile-up rather than one
## wide scene, which is the reading `EventCatalogue._burnt_shell`'s own palette suggested without
## suggesting a single-scene width the way `fallen_tree` and `car_accident` have one.
static func _burnt_out_car() -> EventDef:
	var def := EventDef.new()
	def.id = "burnt_out_car"
	def.display_name = "Burnt-out car"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BURNT_OUT_CAR
	def.act_tag = 2
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(24.0))
	return def

## A hard seal, acts II-IV: rubble spilled frontage to frontage. Single-copy geometry like
## `fallen_tree`, but drawn with `_draw_spread`'s ordinary repeated-segment behaviour rather than
## one stretched picture — `collapsed_frontage.svg` is a small debris segment, styled beside
## `rubble.svg` (`_burnt_shell`'s own picture) rather than sharing it, since a row may not draw
## another row's picture.
static func _collapsed_frontage() -> EventDef:
	var def := EventDef.new()
	def.id = "collapsed_frontage"
	def.display_name = "Collapsed frontage"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.COLLAPSED_FRONTAGE
	def.act_tag = 2
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(96.0))
	return def

# ------------------------------------------------------ the region door's own structure ---
# Three bodies `RegionPlanner` stands at every open crossing of today's region wall, from
# `Tuning.REGION_WALL_FIRST_DAY` — a hut on each pavement and a gate over the road at a street
# door, a single guard at each mouth of an alley door. All three are `SCRIPTED`, `scripted_day 0`,
# like the seal pictures above: the ordinary catalogue roll never schedules one, and
# `RegionPlanner.plan_day` places each fresh every morning at the door geometry decides, not at a
# tile the scheduler chose. See docs/CITY.md, "Regions and the wall", and docs/EVENTS.md,
# "Checkpoints".

## The hut at a region door. Detains rather than blocking outright — M62's own words: *"the player
## walks to the hut gets detained inside and then spawns on the other side."*
##
## **The hold starts a reach past the hut's own wall**, not a radius from the middle of it:
## `detain_radius` is `Tuning.CHECKPOINT_DETAIN_REACH` (48px) measured from the solid edge, so
## `EventDef.detain_distance()` comes out at 80px from the centre, and the guard steps out while
## she is still walking up rather than only once she is pressed against the hut — which, with a
## pram in front of her, she never was. It sits inside `inner_radius` (84px) the way every
## detainer's does, and the ambient field is the milestone's own "a bit of excitement": a small
## `intensity` over a tight band, small enough that the real price stays the flat
## `Tuning.CHAT_EXCITEMENT` the detention charges through the ordinary chat mechanism, and standing
## still on its own pays nothing back (`EXCITEMENT_DECAY_IDLE`). **The field is not what makes this
## row expensive and must not be asked to be**: at 6.0 over an 84–98px band it means less along the
## line than the 6.0/s an ordinary street gives back, so `walk_through_cost()` reads it as free —
## and it is, because the price is the detention. `tests/test_events.gd` exempts the detainers from
## its catalogue-wide "nothing is cheaper to walk through than around" rule by name and for that
## reason, and holds them to charging their capture instead. The band stays 14px wide, which is what
## the telegraph is priced on; the disc moved out with the capture so the two keep the order
## `validate()` requires.
## `redetains` is what tells `EventManager` this instance is armed again once she is outside
## `detain_distance()`, in either direction, rather than spent after one conversation like
## `chatting_mother`.
static func _checkpoint_hut() -> EventDef:
	var def := EventDef.new()
	def.id = "checkpoint_hut"
	def.display_name = "Checkpoint hut"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.CHECKPOINT_HUT
	def.act_tag = 2
	def.intensity = 6.0
	def.inner_radius = 84.0
	def.outer_radius = 98.0
	def.telegraph_time = 1.0
	def.solid(GroundShape.point(32.0))
	def.detain_seconds = Tuning.CHECKPOINT_DETAIN_SECONDS
	def.detain_radius = Tuning.CHECKPOINT_DETAIN_REACH
	def.redetains = true
	return def

## The boom over the roadway between a door's two huts. No field of its own — a car passing under
## it costs her nothing whether or not she is anywhere near it — but it detains exactly like a hut
## now, *(2026-09-10, the player, on stepping onto the gate's own ground while the boom is up for a
## car: "attempting to do that should just start a regular checkpoint inspection".)* The toll was
## paid only at the hut before this; a raised bar read as a way past at the bar itself, since
## nothing stood on the gate's own tiles to catch her. `detain_radius` and `inner_radius` are the
## hut's own numbers, for the hut's own reasons — the same reach past the same 32px body, inside
## the same 84px disc. `outer_radius` (120px) is its own: it still comfortably clears
## `Tuning.required_telegraph_time()` at that `inner_radius`, and nothing about it ties to the
## field this row never had. Drawn raised or lowered from the shared
## `RegionPlanner.GateState` `Crowd` keeps current for the day's cars; see `docs/TODO.md`, M62,
## "cars need to slow down to a full stop." Placed with `Planned.facing` set along the street's own
## axis, which is both what tells the drawing a north-south road from an east-west one and what
## `EventManager`'s detention teleport reads back from a hut or a post at the same crossing.
static func _checkpoint_gate() -> EventDef:
	var def := EventDef.new()
	def.id = "checkpoint_gate"
	def.display_name = "Checkpoint gate"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.CHECKPOINT_GATE
	def.act_tag = 2
	def.intensity = 0.0
	def.inner_radius = 84.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.point(32.0))
	def.detain_seconds = Tuning.CHECKPOINT_DETAIN_SECONDS
	def.detain_radius = Tuning.CHECKPOINT_DETAIN_REACH
	def.redetains = true
	return def

## The alley half of a door: a single guard where a through-alley crosses a region boundary,
## standing in for the hut and gate a full street gets — the alley is one lane wide, so one body
## covers its whole 64px mouth. Detains exactly like `checkpoint_hut`, same numbers and the same
## `redetains`, because the toll is the crossing itself, not the width of the street it stands on.
static func _checkpoint_post() -> EventDef:
	var def := EventDef.new()
	def.id = "checkpoint_post"
	def.display_name = "Checkpoint guard"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.CHECKPOINT_POST
	def.act_tag = 2
	def.intensity = 6.0
	def.inner_radius = 84.0
	def.outer_radius = 98.0
	def.telegraph_time = 1.0
	def.solid(GroundShape.point(32.0))
	def.detain_seconds = Tuning.CHECKPOINT_DETAIN_SECONDS
	def.detain_radius = Tuning.CHECKPOINT_DETAIN_REACH
	def.redetains = true
	return def

# ------------------------------------------------------------------ the finale ---
# Two rows the escape places and nothing else does. Both are `SCRIPTED` with `scripted_day = 0`,
# the same gate the eight seal pictures and the checkpoint kit use: `EventDef.available_on()` asks
# `scripted_day == day` for a `SCRIPTED` row and no day of a fourteen-day run is day zero, so the
# ordinary scheduler can never roll either one. `FinalePlanner` places them by id.

## The bang she hears and does not see. *"Explosions happen off screen (but loud enough to cause
## excitement) leaving craters on the street."*
##
## **It draws nothing at all**, which is the whole of the brief: there is no burst on the street,
## only the noise and the hole afterwards. `Look.NONE` — the fourth row in the catalogue with no
## picture, alongside the playground and the two loudspeaker sources — so it needs no shape either,
## and `tests/test_events.gd` names all four by id.
##
## **Off screen is bought with the streaming radius rather than with a rule.** A `MAP` placement
## comes into the world at `Tuning.EVENT_STREAM_RADIUS` (900px), where the camera at zoom 2 sees
## 640×360 — so an explosion begins its telegraph roughly two and a half screens away, spends
## `telegraph_time` + `duration` (3.7s, about 340px of walking) getting to its bang, and is over
## while it is still well outside the view. Nothing has to site it "off screen": walking toward it
## takes longer than it lasts.
##
## **The radii are sized against that distance and not against taste.** `outer_radius` 520 reaches
## a screen and a half; `inner_radius` 300 puts the whole of the near half of that band at close to
## full strength, so a burst that goes off just beyond the screen edge (about 360px on the long
## axis) still lands roughly 22 of its 24 points per second on her. A narrower band would be an
## explosion she could be next to and not hear. `telegraph_time` is the contract's own minimum for
## that band — `(520 − 300) / WALK_SPEED` is 2.39s — with the ordinary margin on top.
##
## **Not lethal, and that is the tone rule rather than an omission** (`docs/NARRATIVE.md`: *the
## danger is always noise*). The thing that ends a section is being taken; an explosion wakes the
## baby.
static func _finale_explosion() -> EventDef:
	var def := EventDef.new()
	def.id = "finale_explosion"
	def.display_name = "Explosion"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.NONE
	def.act_tag = 4
	def.placement = [GameEnums.TileType.ROAD]
	def.intensity = 24.0
	def.inner_radius = 300.0
	def.outer_radius = 520.0
	def.telegraph_time = 2.5
	# Short and over: a sharp spike is a short `duration` at high `intensity`, since there is no
	# `impulse` field and none is wanted (`CLAUDE.md`, "Things deliberately not done").
	def.duration = 1.2
	def.spawns_on_finish = "impact_crater"
	return def

## What is left in the road afterwards, and it stays there for the rest of the sequence: `duration`
## 0 is "lasts the whole day", so a crater is a fact about the street from the moment it is made.
##
## **Silent and solid**, exactly like the eight seal pictures it sits beside — a hole in the road
## makes no noise, and its radii are `barricade`'s own (inner 40, outer 120, telegraph 0.9) because
## `EventDef.validate()` still wants a falloff band to exist even at zero intensity.
##
## **The body is the picture.** `impact_crater_2x2.svg` is 64px across, so `point(32)` is exactly
## half of it and the ground she cannot walk on is the hole she can see — *anything that stands
## still is solid at the width it is drawn*, read in the one direction a hole can be read in. The
## 32px and 96px sources stay prepared and unbound: `spawns_on_finish` names one row, a second
## crater row would need a second explosion row to leave it, and three sizes of the same hole would
## be three looks that no reader could tell apart on the screen-edge badge.
##
## **No `scar_id`.** A scar is how the *run* remembers a fire on day 3; the escape is the last
## thing that happens in a run, so a crater has nothing left to persist into and recording one
## would only put an entry in `GameState.scars` that no later day ever reads.
static func _impact_crater() -> EventDef:
	var def := EventDef.new()
	def.id = "impact_crater"
	def.display_name = "Crater"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.IMPACT_CRATER
	def.act_tag = 4
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.point(32.0))
	return def

## A masked man running up the stairwell. *"Some masked pursuers that run up the stairs that can be
## avoided by going into a corridor and letting them pass."*
##
## **Mobile, not `pursues`, and that is the whole counterplay.** A pursuer steers at her, so the
## only answer to one is speed; this runs a line — the shaft, bottom landing to top — and the
## answer to it is *not being on that line*, which in a building whose stairwell doors are a fade
## and a teleport means stepping through the nearest one and letting him go past. It is
## `loose_dog`'s contract indoors: a thing coming down the corridor you are in, answered by
## leaving the corridor.
##
## **Faster than a walk, so it cannot be out-walked**, which is what makes stepping aside the
## answer rather than a preference — and what makes the telegraph the long one: at 130px/s the
## contract prices the escape as the field's whole forward reach rather than its falloff band, so
## `outer_radius` 120 at `TELEGRAPH_HARD_FAIL_MARGIN` needs 3.53s and this carries a little over
## it. Three and a half seconds is also what the picture wants: she hears him a floor below.
##
## **No body**, like every other mobile row: a moving wall on a stairwell one tile wide would pin
## her against the shaft. What stops her walking into him is that it ends the section.
static func _masked_pursuer() -> EventDef:
	var def := EventDef.new()
	def.id = "masked_pursuer"
	def.display_name = "Masked man"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.MASKED_PURSUER
	def.shape = GroundShape.point(9.0)
	def.act_tag = 4
	def.intensity = 18.0
	def.inner_radius = 28.0
	def.outer_radius = 120.0
	def.telegraph_time = 3.6
	def.mobile = true
	def.speed = Tuning.HEAT_HUNTS_SPEED
	# **He waits at the foot of the shaft until she is in it**, rather than running his line the
	# moment the section begins and being gone before she has come down a floor. `pursues_within`
	# is the field's own name for that state and is wider than its name — a row that sets it
	# without `pursues` stands unclocked until she is in range and then runs its ordinary path,
	# which is exactly `alley_mouse`'s shape at a stairwell's scale. 900px is the shaft's own
	# height (three floors of eight tiles is 768px) with room over it, so he notices her the moment
	# she is anywhere in the same stairwell and never from the hallway two parts away.
	def.pursues_within = 900.0
	# And the notice is spent standing, not approaching: a man already running when he first
	# becomes visible has given no notice at all.
	def.still_while_telegraphing = true
	def.hard_fail = true
	return def

## Steam in the basement: *"maybe some steam in the basement etc."* A field on a corridor she has
## to walk down, which is the one kind of pressure a passage with no branches can carry.
##
## **It drifts, and that is what buys it out of the solidity rule rather than a number.** *Anything
## that stands still is solid at the width it is drawn* — and `steam.svg` is 32px across, so a
## standing vent would be a 16px body in a basement corridor two tiles (64px) wide, which leaves
## her 28px of pram and body a four-pixel lane to aim at. That is the "no line to walk" failure
## exactly, in the one place in the building where there is no second route to take instead. So it
## **paces** its own stretch of corridor, which takes the body away by the rule
## `EventDef.paces` states — *the price of pacing is the body* — and pays it back in intensity.
##
## **And it pulses on top of that**, so the counterplay is timing a pass between two vents rather
## than a fixed toll for the passage: the same thing `homeless_yeller`'s beat asks for, at the
## scale of a corridor rather than a street.
static func _basement_steam() -> EventDef:
	var def := EventDef.new()
	def.id = "basement_steam"
	def.display_name = "Steam"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.STEAM
	def.shape = GroundShape.point(10.0)
	def.act_tag = 4
	def.intensity = 14.0
	def.inner_radius = 24.0
	def.outer_radius = 90.0
	# Well under a walk, so the escape distance is the falloff band: `(90 − 24) / WALK_SPEED` is
	# 0.72s, and this carries the same kind of margin every other slow row in the catalogue does.
	def.telegraph_time = 1.2
	def.pulse_period = 4.0
	def.mobile = true
	def.paces = true
	# A drift rather than a walk — slower than anything else that moves in the game, because what
	# it is is air and not somebody going somewhere.
	def.speed = 18.0
	return def
