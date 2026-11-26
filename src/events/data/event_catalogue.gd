class_name EventCatalogue
extends RefCounted
## Every event in the game, defined in code: reviewable in a diff, validated on load, and
## assertable over the whole catalogue in a test. See docs/EVENTS.md for the catalogue table and
## the reasoning behind each row.

## The id of the burnt-shell row, and the `run.attempt_spend().scars()` id day 3's fire leaves
## (`_burning_building()`'s own `aftermath.scar_id()`): read by `EventDef.burns_its_front()` and by
## `CityFronts.mark_the_burnt_frontage()`, which turns the building behind the scar burnt.
const BURNT_SHELL_ID := "burnt_shell"

## The other answer to *prevents the player from walking past it*: **off**, and one line from being
## on. True makes the crash a row that ends the day (`ends_the_day()`), as a fire is, so the gaps end the day rather than
## costing more of it than she can carry. The built default is the expensive reading, because a
## wall that kills has no price to weigh and the verb of this game is *where do I walk*.
##
## Flipping it takes the row's inner radius to `CAR_ACCIDENT_LETHAL_INNER_RADIUS` and its
## telegraph to the doubled hard-fail margin; `EventCatalogue._car_accident()` is the only reader
## of either.
const CAR_ACCIDENT_GAPS_ARE_LETHAL := false
## What a car crash emits, per second at the middle of its own band: the one seal that makes any
## noise at all, and the one place *a closure is silent* (`docs/CITY.md`) does not hold. Its body
## is the two cars only (`EventCatalogue._car_accident_parts`), so the picture's own gaps are
## walkable ground and this is what stands in the way instead.
##
## **Set by the walk, not derived.** `tests/probes/m118_crash_gap.gd` walks the sidewalk gap and the
## gap beside the cars at `Tuning.WALK_SPEED` across several seeds and reports the **cheapest**
## line through them, since a guarantee about a price is a guarantee about the price she can get. At
## this number that line costs a little over 54 of the hundred-point meter, against the
## `Tuning.METER_MAX / 2` line `tests/crowd_rig.gd` draws between *expensive* and *fatal*,
## deliberately on the fatal side, so a meter that is not fresh cannot carry it.
## `tests/test_seals.gd` asserts that walk rather than this number.
##
## **What it buys is the meter, not the day**: the pram's nearly-crying cue is the turn-back signal,
## and a fresh meter can still force the pass at the price of the rest of the day.
## `CAR_ACCIDENT_GAPS_ARE_LETHAL` is the other reading, left switchable.
const CAR_ACCIDENT_INTENSITY := 50.0
## The radius that would end the day under `CAR_ACCIDENT_GAPS_ARE_LETHAL`, measured from the scene's
## own centre. Above the cars' own 36.1px reach plus her 14px body, so she can reach the thing that
## kills (`EventDef.validate()` refuses a lethal row whose body holds her outside its own inner
## radius), and inside the 96px band so the gaps either side of the cars are what it covers.
const CAR_ACCIDENT_LETHAL_INNER_RADIUS := 56.0
## **How long a charger that waits for her warns before he charges**, in seconds, while she stays
## inside his one radius (`PursuitSpec.warns_for()`, `EventInstance.warns_by_radius()`; inbox #788 in
## minty-lemur), and how long a door's guard warns once she has crossed its line
## (`CheckpointController`). If she leaves the radius the warning stops; if she stays, the charge
## starts. Shorter than the 2s the player found too long (curly-moose #803), and as short as the
## radii it is played with allow: the measurement that keeps it fair is per row
## (`tests/probes/charger_warning.gd`): a walker who turns back the moment his warning starts is out
## of his radius before it runs out, and so is one he first sees just outside his stand-off, deep
## inside his radius; one who stands in it is caught. The run plays it through `ChargerTiming`, so
## `--chargers` can try another.
const CHARGER_WARNING := 1.75
## **How far every charger notices her against the radius its row is written with**: a factor on
## every written notice radius (`ChargerTiming.notice()`), the waiting dog's 130px, the alley
## robber's 180px (and every man drawn as him), the hunting roadblock's guard's and the hunting
## vans' `EventDef.HEAT_HUNTS_WITHIN` and the investigating patrol's
## `EventDef.HEAT_INVESTIGATE_WITHIN`, since the player found 180px way too small for a charger to
## notice her within, in general (curly-moose #803). Played with `CHARGER_WARNING`, and as wide as
## that warning lets it be: the warning still runs out with her out of his radius in every walk
## `tests/probes/charger_warning.gd` takes. The run plays it through `ChargerTiming`, so
## `--chargers` can try another.
const CHARGER_REACH := 1.25
## How far past a door body's own solid edge the inspection starts (PLAYTEST-57).
##
## **Stated over the hut, never over her.** Her centre is stopped `obstructs_within() +
## Tuning.PLAYER_BODY_RADIUS` (32 + 14 = 46px) from a door body's centre, and further when the
## pram's own body is between, so a trigger stated as a radius from the hut's *centre* has to be
## larger than whatever she happens to be pushing. Measured from the hut's wall, one number covers
## every pram: 48px clears her own body's 14px stand-off and the widest the pram has reached ahead
## of her, and starts the inspection while she is still walking up. See `HoldSpec.past_its_edge()`.
const CHECKPOINT_DETAIN_REACH := 48.0
## Seconds a `checkpoint_hut`/`checkpoint_post` detention holds her. Short rather than heavier than
## `chatting_mother`'s 5s: a toll paid at every crossing of a region wall has to stay cheap to
## repeat, where a conversation is spent once. See `HoldSpec.detains_for()`.
const CHECKPOINT_DETAIN_SECONDS := 2.0
## Seconds between two off-screen explosions inside the building. Section one is relatively minimal
## and an explosion is its only city-wide beat, so it is spaced like the director's own
## `EventDirector.AHEAD_INTERVAL` band: eight of them over a 180s clock flash the hallway windows
## more than once without the basement becoming a drum.
const FINALE_EXPLOSION_INTERVAL := 22.0
## **How far the escape city's explosion is heard**, in px: its field's outer radius
## (`_finale_explosion()`).
const FINALE_EXPLOSION_HEARD_WITHIN := 520.0
## **How long the escape city's explosion's bang lasts**, in seconds: a sharp spike is a short
## `duration` at high peak, since there is no `impulse` field (`CLAUDE.md`, "Things deliberately
## not done"). What `FINALE_EXPLOSION_SET_OFF_WITHIN` is set against.
const FINALE_EXPLOSION_SECONDS := 1.2
## **How near she comes to an escape city's explosion before its place sets it off**, in px
## (`_finale_explosion()`, `SetOffWatch`): its field's reach and as far again as she runs while
## its badge is up (`Tuning.WARNING_ALONE_MAX`) and its bang lasts (`FINALE_EXPLOSION_SECONDS`),
## about 890px. **Heading straight at one, at a walk or a run, she hears none of its bang**, and so
## a runner is still out of its sight when its badge runs out (the view reaches about 400px ahead
## of her), and the badge never comes down without its bang. Its bang reaches her only where she
## comes at it from the side or turns toward it while it bangs.
const FINALE_EXPLOSION_SET_OFF_WITHIN := FINALE_EXPLOSION_HEARD_WITHIN \
		+ (Tuning.WARNING_ALONE_MAX + FINALE_EXPLOSION_SECONDS) * Tuning.RUN_SPEED
## **How far the escape city's explosion is felt as a shake of her view**, in px: half as far again as
## it is set off (`FINALE_EXPLOSION_SET_OFF_WITHIN`, about 1335px), so that one going off out of her
## sight shakes the view, a third of the full shake where it goes off furthest, without its noise
## reaching her (`FINALE_EXPLOSION_HEARD_WITHIN`). Open to the player (minty-lemur #785).
const FINALE_EXPLOSION_FELT_WITHIN := FINALE_EXPLOSION_SET_OFF_WITHIN * 1.5
## How long after the masked man has finished his run before another one comes up the same shaft,
## in seconds: he respawns, forcing her to switch sides again.
##
## **Stated against what one run costs her.** A shaft is three floors of eight tiles (768px) and he
## runs it at `Tuning.HEAT_HUNTS_SPEED` (130px/s), so a run is about six seconds, and the next is not
## in the world until she is within the masked man's `EventDef.sets_off_within()` of the foot of
## the shaft again. Six seconds of nothing between runs is long enough that
## stepping out of a door and straight back in is a real answer, short enough that waiting one
## out and strolling down is not. A first number, and the one to move if the shaft reads as
## either a corridor with a man in it or a corridor with a man near it.
const FINALE_PURSUER_RESPAWN_SECONDS := 6.0
## How long one vent blows, in seconds, once its notice is over: the *on* half of the on/off split,
## against the periods above.
##
## **Short against every period**, so a vent's corridor is open for longer than it is shut (the
## shortest period leaves twice as long open again). A gap she can walk through is what she is
## waiting for, and `BuildingPlan.FINALE_STEAM_PERIODS` states the floor under that gap. A vent
## closes a corridor with no way round it, so the pocket between two of them is shut at both ends
## only for as long as the shorter of the two overlaps, which is bounded by this.
const FINALE_STEAM_BLOWS_FOR := 2.0
## **What it costs when the man an investigating car let out reaches her**, in points of the
## excitement meter, landed on her standing beside him: he stops her, and his own field charges this
## over `Tuning.OFFICER_STOP_SECONDS`, fading, before he walks back to his car
## (`PursuitSpec.stop_excitement()`; inbox #669 in coral-lark).
##
## **Substantial, and never the end of a day on its own**: nearly four contacts' worth (eleven
## points each, `Crowd.BUMP_INTENSITY`) and well over a conversation's 25 (`Tuning.CHAT_EXCITEMENT`),
## so being reached is a thing she pays for rather than a bump; and under `Tuning.METER_MAX` with
## the rest of the encounter (the car is quiet from its stop until it has left her,
## `EventInstance.is_quiet_for_its_man()`), so from a calm meter it never ends the day. Only a meter
## already high enough to carry her to the cap and past `Baby.EXCITEMENT_OVERFLOW_TO_CRY` does. It
## is his field, spent in a second at its full width, so walking away the instant he reaches her
## takes little of it off; a sleeping baby takes `Baby.SLEEPING_SENSITIVITY` of it, as of
## everything.
const OFFICER_STOP_EXCITEMENT := 40.0

# ------------------------------------------------------------------- bodies ---
# A body is **half the silhouette**, never a number chosen for how it plays: the rule in
# `BodySpec` is that a thing that stands still is solid at the width it is drawn,
# and a body that disagrees with the art is a lie about where she can walk. Two repeat often
# enough to be worth a name; the rest are written at the row that uses them, with the sprite they
# came from.

## `person.svg` is 18px across. A man you edge past on a sidewalk rather than walk through.
const PERSON_BODY := 11.0
## `vehicle.svg` is 48px across.
const VEHICLE_BODY := 22.0
## `steam.svg` is 32px across. Half the silhouette, as every other body here; what makes a vent a
## **gate** rather than a lane to thread is where it stands: on a cell where the basement corridor
## is one tile (32px) wide, her centre is held 30px out and the walls leave it 16px either side of
## the middle, so there is no line past a vent that is blowing, which is the whole of the timing
## puzzle.
const STEAM_VENT_BODY := 16.0
## How close a masked man gets before he has the baby. One number for both of them: the man on the
## escape's stairs (`masked_pursuer`) and the guard who leaves a `roadblock` are the same figure,
## and a reach is a property of a person rather than of where he stands. Stated here rather than at
## either row, so the two cannot drift apart.
const MASKED_MAN_REACH := 28.0
## How close the masked man on the escape's stairs gets before he has the baby, inside the field he
## shares with the roadblock's guard (`MASKED_MAN_REACH`): narrower, so a runner who walks until he
## runs, then runs, clears him on the tightest line onto the second flight (inbox #865 in
## minty-dolphin).
const MASKED_PURSUER_CATCH := 23.5
## The widest a `SpreadLook._draw_spread`-style body (`SpreadLook._draw_spread`,
## `RankLook._draw_cafe`) may be on a `SIDEWALK` tile before it draws past the sidewalk it stands on.
##
## A sidewalk is one piece of walkable ground, `Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE` (64px)
## across, not two lanes a body has to fit inside one of. `EventInstance.setup()` centres a
## stationary, unpinned (`pavement_side == ANY`) body on that whole band, so the ground a row may
## fill is the full band and this is half of it. `tests/test_events.gd`,
## `_test_a_spread_body_fits_the_ground_it_stands_on`, checks it over the whole catalogue.
const SIDEWALK_SPREAD_MAX := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 0.5

## **How far the roadblock's band reaches either way across its street from the kerb it stands on**
## (`EventDef.stands_at_its_kerb()`): half of one sidewalk and the road, 64px, so the band covers
## its own sidewalk and the road, 128px of the 192px street, and stops at the far kerb, leaving the
## far sidewalk whole ("okay let's use the one sidewalk has to be open and match the roadblocks size
## to one sidewalk + road", inbox #1465 in spry-plover). Its picture is drawn at the same width.
const ROADBLOCK_REACH := (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH) * Tuning.TILE_SIZE * 0.5

## `mast.svg` is thinner than a person: a pole, not a body to edge past. Solid enough that she
## cannot walk through it; the field, not the pole, is what a route goes round.
const MAST_BODY := 6.0

## **How this run plays every charger's warning and notice** (`ChargerTiming`): the shipped timing
## unless the run asked for another (`use_charger_timing()`). Every row the catalogue builds reads
## it, so the rows below are built from it.
static var _chargers: ChargerTiming = ChargerTiming.of(CHARGER_WARNING, CHARGER_REACH)

static var _all: Array[EventDef] = []
## Derived rows, keyed `"<id>|<level>"`. See `heated()`.
static var _hot: Dictionary[String, EventDef] = {}
## The building's two derived rows, built once. See `building_fire()` and `explosion_outside()`.
static var _building_fire: EventDef = null
static var _explosion_outside: EventDef = null

## **The charger timing the game ships**: every charger warns for `CHARGER_WARNING` and notices her
## within `CHARGER_REACH` times the radius its row is written with.
static func shipped_charger_timing() -> ChargerTiming:
	return ChargerTiming.of(CHARGER_WARNING, CHARGER_REACH)

## **How this run plays every charger's warning and notice**: what the rows are built from, and what
## a door's crossing warns for (`EventManager` hands `CheckpointController` its `warning()`).
static func charger_timing() -> ChargerTiming:
	return _chargers

## **Builds every row from `timing` from now on**: the composition root hands it the run's own at
## boot (`main.configure()`, `RunConfig.charger_timing()`), before anything is built from a row.
## A timing that plays every charger as the one in use changes nothing, the timing held included;
## another forgets every row and derived copy, so the next ask builds and validates them again.
static func use_charger_timing(timing: ChargerTiming) -> void:
	if timing.same_as(_chargers):
		return
	_chargers = timing
	_all = []
	_hot = {}
	_building_fire = null
	_explosion_outside = null
	_lesson_dog = null
	_task_guard = null
	_task_guard_sent = null
	_out_of_the_car = {}

## Every heat level a run can reach. Progress runs 0..`RESISTANCE_GOAL`; a task completed past the
## goal adds nothing, because full heat is the qualification rather than the last errand. A
## function rather than a `const`, because an autoload's constant is not available at parse time.
static func heat_levels() -> int:
	return Tuning.RESISTANCE_GOAL + 1

## Every row, built and validated once, in catalogue order: what `tools/cost_table.gd` walks, its
## table's fixed row order being this one. The game asks per day (`available_on()`, `of_kind()`,
## `by_id()`), and so does a suite (`CatalogueRows.every()`).
static func all() -> Array[EventDef]:
	if _all.is_empty():
		_all = _build()
		# **Every shape of every row, not only the cold one.** The fairness contracts are checked once,
		# on load, from data, so a row validated only at heat zero would have its contract stated about
		# the harmless version of itself. The shapes are finite because progress is a bounded integer.
		for def in _all:
			for level in heat_levels():
				heated(def, level).validate()
		# And the man an investigating vehicle lets out, a copy of the day's pursuer on foot whose
		# notice is the sight of him (the patrol car's, whose catch is a stop, and a hunting van's,
		# whose catch ends the day), validated for the same reason.
		for on_foot_id: String in ["policeman_giving_chase", "guardsman_giving_chase"]:
			_out_of(by_id(on_foot_id), true).validate()
			_out_of(by_id(on_foot_id), false).validate()
		escape_roadblock().validate()
		# The rows of its own a row is met as on its one occasion: the day-3 lesson's dog and day
		# 13's task guard, waiting and sent.
		lesson_of(by_id("charging_dog")).validate()
		task_guard().validate()
		task_guard_sent().validate()
		building_fire().validate()
		explosion_outside().validate()
	return _all

## This row at a resistance level, derived once per run and kept: the cache in front of
## `EventDef.at_heat()`, because a day asks for the same heated row once per candidate placement.
static func heated(def: EventDef, level: int) -> EventDef:
	if not def.answers_to_heat() or level <= 0:
		return def
	var key := "%s|%d" % [def.id(), level]
	if not _hot.has(key):
		_hot[key] = def.at_heat(level, _chargers)
	return _hot[key]

## **The roadblock the escape stands on its streets**: the row at full heat, its guards hunting,
## exactly as a day's at full resistance progress (inbox #771 in minty-lemur: luring away the guard
## is enough). Its band costs nothing and, once the guard on her side has left his post for good,
## the guard at the far post walks off too, as on every day (`_roadblock()`, `RoadblockFarGuard`).
static func escape_roadblock() -> EventDef:
	return heated(by_id("roadblock"), Tuning.RESISTANCE_GOAL)

## **A row with the marks it leaves on a run taken off it**: the scar it records, the row it spawns
## when it finishes and the row it calls in when it is first seen. What the escape's rows are made
## of where those marks mean nothing: the building's fire whose fire engine has no street to come down, the explosion whose
## crater has no road to stand in indoors.
##
## A **derived copy, never a mutation**, for the reason `EventDef.at_heat()` gives. Its body is the
## row's own value, shared: a body is never changed in place.
static func without_its_aftermath(def: EventDef) -> EventDef:
	var draft := def.redraft()
	draft.aftermath(Aftermath.none())
	return draft.build()

## **The fire in the building's stairwell**: `burning_building` without its aftermath, and the whole
## hazard again. Outdoors the fire costs nothing and stands nothing on the sidewalk (the fire engine
## it calls in is the danger); neither belongs in a stairwell. So this one costs the meter while it
## burns and closes the shaft it stands in: a 30px body (five flames spanning ±31px) that casts its
## shadow, 18 over the row's 60–260px field, and a 3s pulse, so it breathes between a quarter of
## that and all of it (11.25/s on average) and its flames roar and die back with it. The building
## places it (`BuildingPlan`), not her walk, so it is a scripted row on no day rather than a one-shot. Its id stays the row's, being the same fire to
## everything that counts or logs it.
static func building_fire() -> EventDef:
	if _building_fire == null:
		var fire := without_its_aftermath(by_id("burning_building"))
		var draft := fire.redraft()
		draft.body(BodySpec.solid(GroundShape.point(30.0)).unmet().parked())
		draft.field(fire.field().at_peak(18.0).pulsing_every(3.0))
		draft.look(fire.look().casting_a_shadow())
		draft.not_sited_from_her_walk()
		# The building's own row, placed by its plan and nothing else: `SCRIPTED` on day 0, the day
		# nobody plays, like the escape's other rows, so no day's dawn reaches it and the rule that
		# a one-shot is sited from her walk does not apply to it.
		draft.scripted_on(0, 1)
		_building_fire = draft.build()
	return _building_fire

## **The explosion outside, as it reaches her inside the building**: `finale_explosion` without its
## crater, coming every `FINALE_EXPLOSION_INTERVAL` (`repeat_every`). Indoors there is nothing of
## it to see, so it is a beat: every window lights (the field passes through walls, `FieldSpec.through_walls()`, `WorldContext.bang_outside()`)
## and the row's own field (peak for its `duration`) charges her wherever she stands. No
## wall stops it: the bang has already come through them. The building places it where she is each
## time it comes, with its notice over, since what the windows say is that it has already happened
## (`BuildingPlan`). Its id stays the row's.
static func explosion_outside() -> EventDef:
	if _explosion_outside == null:
		var bang := without_its_aftermath(by_id("finale_explosion"))
		var draft := bang.redraft()
		draft.field(bang.field().through_walls())
		# Placed where she stands each time it comes, with its notice over, rather than set off by a
		# place under a badge as it is on the escape's streets: the windows say it has happened. Its
		# telegraph is never seen, and is the default's, which holds the contract for its band.
		draft.warning(WarningSpec.lasting(WarningSpec.DEFAULT_SECONDS))
		draft.set_off_within(0.0)
		draft.comes_again(FINALE_EXPLOSION_INTERVAL, bang.comes_again_after())
		_explosion_outside = draft.build()
	return _explosion_outside

static func by_id(id: String) -> EventDef:
	for def in all():
		if def.id() == id:
			return def
	return null

## The loudspeaker mast (the first row that is one, in catalogue order): what the masts' sites,
## the day's masts and the resistance's mast task are made of.
static func mast() -> EventDef:
	for def in all():
		if def.is_a_mast():
			return def
	return null

## **The day-3 lesson's own row for `row`**: for the charging dog, `charging_dog_tutorial`, the dog
## under an id of its own, which `EventDirector._teach_the_run()` hands out in place of the first
## dog it sends on `Tuning.RUN_TAUGHT_DAY`, so its GoatCounter counts (`seen-charging-dog-tutorial`,
## its `dog-tutorial-*` charges) are its own (inbox #849 in minty-dolphin); `row` itself for any
## other. A derived copy, built once: it shares the dog's picture and every number, and the day's
## roll never places it.
static func lesson_of(row: EventDef) -> EventDef:
	if row == null or row.id() != "charging_dog":
		return row
	if _lesson_dog == null:
		var draft := _charging_dog().redraft()
		draft.known_as("charging_dog_tutorial")
		_lesson_dog = draft.build()
	return _lesson_dog

static var _lesson_dog: EventDef = null

## **The alley robber who guards a chalk mark**: the alley robbery row itself, standing in the
## mark's alley (`ResistanceDirector._maybe_set_a_trap()`).
static func mark_guard() -> EventDef:
	return by_id("alley_robbery")

## **The guard a door sets on her when she walks under its raised boom**, the row
## `CheckpointController` is handed to send (`_door_guard()`).
static func door_guard() -> EventDef:
	return by_id("door_guard")

## **Day 13's task guard: the alley robber, waiting in a band round the roadblock**
## (`ResistanceDirector._maybe_set_a_trap()`), moved with her target (`EventManager.move_extra()`)
## and set on her when the roadblock's task is done. Every number and the picture are the alley
## robber's; the id, `task_guard`, is his own, so GoatCounter's seen, lost-day and charge counts
## tell him apart from the robber in an alley. A derived copy, built once, as the catalogue's rows
## are never placed by the day's roll.
static func task_guard() -> EventDef:
	if _task_guard == null:
		var draft := _alley_robbery().redraft()
		draft.known_as("task_guard")
		_task_guard = draft.build()
	return _task_guard

static var _task_guard: EventDef = null

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
		if def.is_of_kind(kind):
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
		_poster_crew_square(),
		_loudspeaker(),
		_curfew_announce(),
		_roadblock(),
		_checkpoint_hut(),
		_checkpoint_gate(),
		_checkpoint_post(),
		_door_guard(),

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

		# The story's own figure — never rolled by the ordinary scheduler, placed only by the
		# resistance (`ResistanceHappenings`, `ResistanceDirector`). See "the neighbor" below.
		_neighbor(),

		# The robber a handed-over task sets on her — never rolled by the ordinary scheduler,
		# spawned only by `ResistanceDirector` at the handover. See `_robber_giving_chase()`.
		_robber_giving_chase(),

		# The guard the van's task sets on her — same terms, never rolled by the ordinary
		# scheduler, spawned only by `ResistanceDirector` at the handover. See
		# `_van_guard_giving_chase()`.
		_van_guard_giving_chase(),

		# The pursuer on foot a torn poster sends: never rolled by the ordinary scheduler and never in
		# the day's queue, sent only by `EventManager.send_a_pursuer()`. A policeman through day 8, a
		# guardsman from day 9 (see `on_foot_on()`).
		_policeman_giving_chase(),
		_guardsman_giving_chase(),

		# The finale — never rolled by the ordinary scheduler, placed only by `FinalePlanner` and
		# the building (`BuildingPlan`). See "the finale" below.
		_finale_explosion(),
		_impact_crater(),
		_masked_pursuer(),
		_basement_steam(),
	]

# -------------------------------------------------------------- the neighbor ---

## The neighbor down the hall, who works at the power station: a figure in work clothes
## (steel-blue coveralls with a reflective band and a dark work cap), the same person day 10's red
## arrow finds and the wanted notice's `neighbor_slot` draws. Scenery rather than a cost: silent,
## bodiless, never rolled (`scripted_day` 0, the seal pictures' own sentinel).
##
## **Two walks, one figure.** On the mornings before day 10 the neighbor leaves her building as she
## does and walks off along her street (`ResistanceHappenings`), at this row's own walking pace,
## and leaves once the route runs out; nothing points at them. On day 10 the director spawns
## `neighbor_heading_home()`, the same figure walking home from out in the city.
##
## **Mobile, so bodiless** (`docs/EVENTS.md`, "Solid things are solid": a moving body pins her),
## and slower than her own walk, so she overtakes rather than follows. The field is a formality the
## fairness contract asks of every row: intensity 0, radii drawn tight round the figure.
static func _neighbor() -> EventDef:
	var row := EventDraft.new("neighbor")
	row.scripted_on(0, 1)
	row.look(LookSpec.of(EventDef.Look.NEIGHBOR))
	row.body(BodySpec.footprint(GroundShape.point(9.0)).walked_through().going_on())
	row.ground([GameEnums.TileType.SIDEWALK])
	row.field(FieldSpec.of(0.0, 20.0, 40.0))
	row.warning(WarningSpec.lasting(0.5))
	row.route(RouteSpec.at(NEIGHBOR_WALK_SPEED))
	return row.build()

## An unhurried walk, half hers (`Tuning.WALK_SPEED`, 92px/s): somebody going to a shift, and
## somebody she can catch.
const NEIGHBOR_WALK_SPEED := 46.0

## How fast the neighbor goes once warned: a run, not a walk.
const NEIGHBOR_RUN_SPEED := 150.0

## The day-10 neighbor: the same row walking home from out in the city along a path the director
## gives it, who **stops at the door** (its route parks where it arrives), walked home into the
## vans, which is the task lost, and who, warned first, runs (`departs_at`), which
## `EventInstance.leave_for_a_completed_task()` turns away from her. A copy rather than a second
## row, since it is the same person in the same picture.
static func neighbor_heading_home() -> EventDef:
	var row := by_id("neighbor")
	var draft := row.redraft()
	draft.body(row.body().parked())
	draft.route(row.route().parking_where_it_arrives())
	draft.leaves_at(NEIGHBOR_RUN_SPEED)
	return draft.build()

## A permanent feature of the calmest ground in the city, and free: the swing frame it draws is
## `map.playground_rects()`' own prop (`City._dress_blocks`), not this row.
##
## **Free because a one-block park otherwise has nowhere left to settle her.** outer radius
## (150) reaches past half of a 256px park block, so a playground with any real cost denied
## nearly the whole lot rather than merely contesting its middle. `EventKind.AMBIENT` is exempt
## from spoiling a park (`EventPlan.spoils()` passes over every playground), so a park
## is still contested on the days the scheduler spoils it, just never by its own swings.
##
## **The row stays rather than being deleted**: `tests/test_events.gd` looks it up by id and reads
## its `kind`, `EventInstance._field_distance()` names it as the row with no shape to fall back to,
## and the event and cost tables in `docs/EVENTS.md` carry a line for it.
static func _playground() -> EventDef:
	var row := EventDraft.new("playground")
	row.ambient(EventDef.AmbientSource.PLAYGROUND)
	row.look(LookSpec.none())  # The park's swing frame already draws it.
	row.body(BodySpec.none().unmet().parked())
	# Kept at their size for the debug field overlay, which still draws a disc here, although
	# `Field.falloff` answers zero at every distance and nothing else reads them.
	# Free. See the note above.
	row.field(FieldSpec.of(0.0, 40.0, 150.0).pulsing_every(9.0))
	row.warning(WarningSpec.lasting(0.0))
	return row.build()

## The tutorial obstacle: visible crouching before it bolts, sharp while it crosses, gone a second
## later. Small radius, so walking one lane wide of it is enough.
##
## **Two things make a cat happen at all.** It is `AHEAD_OF_PLAYER`, because a cat is not a place:
## sited on a road tile at dawn it runs its two seconds out somewhere across the city, alone; the
## director puts it across her line while she is walking. And it holds still through its telegraph (`WarningSpec.holds_still()`):
## `EventInstance` starts a mobile event moving when the telegraph does, which is wrong for a
## crouch, since the path is one street wide and at 240px/s the cat would finish its whole run
## *during* the telegraph, never reaching full intensity or drawing the running sprite.
##
## **That held-still telegraph is also why it needs its own siting distance** rather than the flat
## `AHEAD_LEAD_DISTANCE`: a cat sited two seconds of walking ahead and then held still for
## its telegraph (`telegraphs_for()`) measures where she *was*, so it would cross behind her.
## `EventDef.ahead_of_player_lead()` prices the hold in as walking distance.
##
## **Intensity 17, a startle spike** (PLAYTEST-25 6). There is no `impulse` field: a sharp spike is
## a short `duration` at high peak, and 1.8s is as short as a crossing this wide can be.
## **Its dash still projects under `Tuning.EXPECTED_IMPACT_POINTS` on a standing player**;
## `tests/test_danger.gd` holds this scenario by name, since the crouch is its own silhouette and
## needs no second cue. A bigger number crosses that line and would give the cat a caret, which is
## a design question left open.
static func _cat_dash() -> EventDef:
	var row := EventDraft.new("cat_dash")
	row.look(LookSpec.of(EventDef.Look.CAT))
	row.body(BodySpec.footprint(GroundShape.point(7.0)).walked_through().going_on())
	row.ground([GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING])
	row.sited(EventDef.SpawnMode.AHEAD_OF_PLAYER)
	# It does not telegraph its coming (PLAYTEST-145 20): no screen-edge badge, no warning first,
	# outside the telegraph contract (`WarningSpec.unannounced()`). It still holds before it dashes, which
	# is the cat's own behaviour, not a warning owed.
	row.warning(WarningSpec.lasting(2.81).holding_still().unannounced())
	row.field(FieldSpec.of(17.0, 30.0, 120.0))
	# Long enough to carry it the whole way across the street it starts at the edge of:
	# STREET_WIDTH tiles either side at 240px/s is 1.6s, and it must not expire mid-road.
	row.lasts(1.8)
	# Faster than a walk, so the escape distance is the forward reach, not the plain radius:
	# `outer radius · Field.scale(e)` at the cat's own speed (240px/s, e = 0.48, just under the
	# eccentricity cap): 120 * 1.92 / 92 = 2.51s, plus the row's margin.
	row.route(RouteSpec.at(240.0))
	# Shared with the other things that happen *to* her rather than being the whole of the moments
	# she is owed: the director also has the cyclist and, from day 3, the dog.
	# Deliberately low where the rest of the catalogue's caps are not. A cat is sited by the director
	# while she walks and `AHEAD_INTERVAL` spreads them 11-26s apart over a 210s day, so past this
	# there is nowhere left for one to happen and the day's moments go on cats it cannot fit.
	row.drawn(2.5, 8)
	return row.build()

## The cat's shape, softened, and placed rather than sited: a mouse that darts across an alley when
## she walks into range of it.
##
## **`MAP`, not `AHEAD_OF_PLAYER`.** `_cat_dash` needs the director because a road tile picked at
## dawn could be anywhere and she may never cross it; alleys are rare, and one she is routed through
## she is about to walk down. Placing it on the tile itself lets `EventScheduler._refuses_required_
## alleys` reach it: that check is stated over `def.ground_kinds() == [ALLEY]` rather than over
## `alley_robbery`'s id, so a required alley (one the day's corridor runs down with no way round)
## never offers one; only an alley she chose to detour into can.
##
## **Days and cap, derived from the cat's.** The first and last day are left at their defaults (1,
## and none), as `_cat_dash` leaves them: everyday background texture. The cap is half of
## the cat's 8; an `ALLEY` tile is scarcer than every `ROAD` and `CROSSING` tile a cat may cross,
## and `EventDef.stands_only_in_alleys()` narrows the pool further.
##
## **Lower intensity than the cat's 17, because it is a startle rather than a threat**: 9, roughly
## half, on the same 4:1 outer:inner ratio scaled down to the alley's smaller stage (60:15). The
## alley she is standing in is already worth `Baby.EXCITEMENT_FROM_ALLEY` (+3.0/s) of ambient dread,
## so the mouse only adds a spike on top of ground that is already tense.
##
## **No body, nothing lethal.** Its body is a footprint, for the shadow alone (`BodySpec.footprint()`), and
## it never ends the day (`ends_the_day()` is false).
##
## **It waits for her rather than running the moment it exists.** `MAP` places it on its `ALLEY`
## tile at dawn, well outside `Tuning.EVENT_STREAM_RADIUS` (900px), so a row that started
## telegraphing on arrival would dash and finish off screen before she was anywhere near. The row
## has a `EventDef.notice_within()` of 150px and does not pursue (`EventDef.pursues()`):
## `EventNoticeRun` holds it `is_waiting()`, emitting nothing above the ordinary field and not
## yet on the clock, until she is within 150px, and only then does the telegraph start and the
## path run. 150px is inside `VIEW_HALF_EXTENT.y` (180, the shorter axis, so this holds
## whichever way she faces) and past the field's own outer radius (60px), so the telegraph is
## already on screen by the time she could feel it. `Tuning.validate_event()` is stated over the
## row's telegraph (`telegraphs_for()`) against the field's geometry, not over when the clock
## starts, so it is unaffected.
##
## **The dash crosses the alley's own short axis by construction.** `EventInstance` reads
## `map.alley_lots()` for the rect this instance landed in and lays its two-point path across the
## narrower side (`ALLEY_WIDTH_TILES` (2) is always less than an alley's length). She can only be
## walking the long axis, so the dash is always across her path. See
## `EventInstance._alley_crossing_path()`.
##
## **The picture turns to face the crossing's own heading.** `EventLook.draw_body()` reads
## `EventPictures.MOUSE_BY_VIEW`/`EventPictures.MOUSE_BY_VIEW_B` through
## `EventLook._draw_eight_view()`, as every other moving family does. `art/events/
## mouse_{front,back}[_diagonal].svg` supply the four turned views and `mouse.svg` is the `"side"`
## one; the `_b` siblings are the dash's second frame (the tail curls differently), alternated by
## `EventLook.gait_is_stepping()`. The mouse keeps no second posture for its telegraph, so only the
## dash picks a heading; `_cat_dash`'s crouch/running swap is a different axis, posture rather
## than facing.
static func _alley_mouse() -> EventDef:
	var row := EventDraft.new("alley_mouse")
	# It does not telegraph its coming (`WarningSpec.unannounced()`): 200px/s, but it dashes across its
	# alley rather than at her, and costs about an eighth of the meter to walk through; no badge,
	# outside the telegraph contract.
	row.warning(WarningSpec.lasting(1.4).holding_still().unannounced())
	row.look(LookSpec.of(EventDef.Look.MOUSE))
	row.body(BodySpec.footprint(GroundShape.point(4.0)).walked_through().going_on())
	row.ground([GameEnums.TileType.ALLEY])
	# **Priced against the cat on each row's own ground, which is not the same ground.** A cat is
	# met on an ordinary street, where 6.0/s is given back; a mouse is only met in an alley, where
	# 3.5/s is given back and the alley's own `Baby.EXCITEMENT_FROM_ALLEY` (+3.0/s) is charged on
	# top. So the alley hands this row most of the gap, and 21.0 is what is left to buy: it walks to
	# +19.9 in an alley against the cat's +17.6 on a street.
	#
	# **A tiny radius is why the number is large.** The field is 60px, so the crossing is one and a
	# third seconds; a spike is bought in intensity, since there is no `impulse` field.
	#
	# The cost table in `docs/EVENTS.md` nets every row against the *same* walking decay, so this
	# row reads cheaper there than the cat does; the note under that table says why.
	row.field(FieldSpec.of(21.0, 15.0, 60.0))
	# `Tuning.required_telegraph_time(15, 60, false, 200)` is ~1.09s (outer radius · Field.scale(e)
	# at e = min(0.5, 200/500) = 0.4, scale 1.667, over WALK_SPEED); this carries a margin of the
	# cat's shape.
	# Comfortably past the ~0.32s the physical crossing takes at this speed over the alley's 64px
	# width (`ALLEY_WIDTH_TILES · Tuning.TILE_SIZE`), so `_has_expired()` never cuts the dash short.
	row.lasts(1.0)
	row.route(RouteSpec.at(200.0, RouteSpec.Kind.ACROSS_ITS_ALLEY))
	# Waits unclocked until she is this close (`EventDef.notice_within()`): inside
	# VIEW_HALF_EXTENT.y (180px) with room to spare, past outer radius (60px).
	row.notice(NoticeSpec.at(150.0))
	# Shared with `alley_robbery`'s own weight: the two rows draw from the same `ALLEY`-only pool
	# and neither should be favoured over the other when both are offered the same tile.
	row.drawn(1.5, 4)
	# Rather stands beside a sack pile: `RuledLocationGround` weighs an alley location beside a pile
	# five times over and offers the mouse its tiles beside the pile first.
	row.drawn_to_sack_piles()
	return row.build()

## Stationary, loud, and *pulsing*: the intensity envelope means the counterplay is timing a pass
## between yells, a different skill from routing around a hazard.
##
## He **paces** (`RouteSpec.pacing()`), a design decision rather than polish: a stationary source is
## a fixed price on a fixed patch of sidewalk, a line you draw once and never think about again. A
## man walking up and down two hundred and fifty pixels of footway is a *timing* problem on top of a
## routing one, as his pulse is at a larger scale.
##
## **The cost of pacing is the body.** Anything mobile is exempt from *solid things are solid*, since a
## moving wall on a two-tile sidewalk pins her against a building, so
## what stops you walking through him is the meter alone: he is one of the two rows on day 1 a
## player is most likely to walk *into* rather than around, and a quiet one reads as a man who does
## nothing.
##
## **The pass, not standing beside him, is the measure.** `tests/probes/m174_pass.gd` walks a real
## `EventInstance` of this row past a straight line at `Tuning.WALK_SPEED`, offset by a few fixed
## lateral distances, the two moving in opposite directions as a pass on a sidewalk does, averaged
## over his own pulse. At a field of 20/s over 170px, against `Tuning.EXCITEMENT_DECAY_WALKING`
## (6.0), a pass at 0/20/40px nets **+9.6, +9.4, +8.6/s** awake; that script prints the whole table
## and is the one to re-run whenever this changes.
##
## **A louder core close in answers the wrong question**: a body walking a real pass crosses even a
## wide core in a fraction of a second, where raising peak over the *whole* field buys more
## pass per point of `walk_through_cost()`.
##
## **Two ceilings bound him.** `EventScheduler.WALL_WORTH_OF_COST` (35) is the first: an intensity
## high enough to restore the whole pass costs past it and turns him into a `WALL`, which would
## pull him **off** the corridor his placement rule keeps him on. The second is
## `StreetInvalidation._a_pacing_beat_walls_a_sidewalk`: shrinking his reach far enough to buy back the
## pass inside the cost ceiling also shrinks the ground his placement is weighed against, until
## every beat the scheduler draws for him lands somewhere its own junction or side route already
## reaches, and the geometry that makes a truncated beat a wall stops happening.
## `tests/test_events.gd`'s `_test_a_pacing_row_on_the_routes_sidewalk_can_be_left` is the check
## that would go quiet. So peak is **20**, outer radius **170**: `walk_through_cost()` is
## **33.6**, a 1.4-point margin under `WALL_WORTH_OF_COST`, and the reach stays wide enough that a
## beat still turns up with nowhere to leave from.
##
## **Whether he is a wall is a fact about where his beat runs, not about his field.** He charges
## over a sidewalk from either lane, so the way past him is never a lane; it is somewhere his beat
## passes that she can **leave** by. A junction box is one (she takes the crosswalk while he is at
## the far end of his loop) and a side route off the sidewalk's own side is the other, so he is
## friction and stays on the route. A beat that passes neither leaves her nothing but walking
## through him, and that placement is a wall. His beat of eight tiles against a block of
## `Tuning.BLOCK_SIZE` (8) is why the first is the ordinary case: a beat runs into a junction unless
## a closure, a calm zone's absorbed corridor or the map's own margin cuts it short.
## `StreetInvalidation._a_pacing_beat_walls_a_sidewalk` decides it, per placement.
static func _homeless_yeller() -> EventDef:
	var row := EventDraft.new("homeless_yeller")
	row.look(LookSpec.of(EventDef.Look.YELLER))
	row.body(BodySpec.footprint(GroundShape.point(9.0)).walked_through().going_on())
	row.ground([GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE])
	row.field(FieldSpec.of(20.0, 45.0, 210.0).pulsing_every(5.0))
	row.warning(WarningSpec.lasting(2.6))
	# A third of a walking pace: something that shuffles reads as somebody who lives on this
	# sidewalk rather than somebody crossing it.
	# Eight tiles of footway, walked in about eight seconds each way: long enough that where he is
	# now is worth looking at, short enough that it is still *a place he is*.
	row.route(RouteSpec.at(30.0, RouteSpec.Kind.ALONG_STREET).up_to_tiles(8).pacing())
	# His pacing route never reaches the end of its path and he carries no `duration`, so he leaves
	# only when the resistance hands him a note (`EventInstance.leave_for_a_completed_task()`); this
	# is that departure's speed, not his pacing shuffle. Faster than the shuffle, so the note
	# visibly changes what he is doing, and well under her `Tuning.WALK_SPEED` (92px/s), so
	# following him out is never the fast way home.
	row.leaves_at(60.0)
	row.drawn(2.0, 18)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - open ground, 0.0042: rare on open ground, where the street musician is nine tenths of
	#   what stands: its share there against his.
	row.weighed_on(PlacementGround.Kind.OPEN, 0.0042)
	return row.build()

## Slow, and it owns the sidewalk it is on.
##
## **The intensity is the wall, and it has to beat the walking decay.** At 7 what it means along a
## line through the middle falls under the 6.0/s an ordinary street gives back, so walking *through*
## a dog walker beats walking around it. An obstacle cheaper to walk into than to avoid is not an
## obstacle; this row is for being worth turning round and crossing at the crosswalk for.
##
## **Not given a solid body**: a mobile static body wide enough to matter on a two-tile
## sidewalk can pin the player against a building, a different game from being priced out of a
## street. The lead is drawn (`FigureLook._draw_dog_walker`) so the span it owns is visible; what
## stops you walking through it is the meter, and it is slower than walking, so it can always be
## left.
##
## **The pass, not standing beside it, is the measure.** `tests/probes/m174_pass.gd` walks a real
## instance of this row past her at `Tuning.WALK_SPEED`. At the intensity of **27.5** (field 26),
## against `Tuning.EXCITEMENT_DECAY_WALKING` (6.0), a pass at 0/20/40px nets **+11.7 / +11.1 /
## +9.0/s** awake.
##
## **Restoring the pass fully is not available**: the intensity that would costs past
## `EventScheduler.WALL_WORTH_OF_COST` (35) on `walk_through_cost()`, and that constant fixes the
## line **because** `dog_walker` has to stay `friction`: a dog-walker decision she cannot reach
## because the row sits off the corridor is the decision this row exists to be. So peak is
## only as high as the `WALL` line allows; `walk_through_cost()` is **33.3**, a 1.7-point margin
## under the 35 line. Open to overturn: whether that trade is right, or whether the far reach should
## come down as `homeless_yeller`'s did.
static func _dog_walker() -> EventDef:
	var row := EventDraft.new("dog_walker")
	row.look(LookSpec.of(EventDef.Look.DOG_WALKER))
	row.body(BodySpec.footprint(GroundShape.point(8.0)).walked_through().going_on())
	# The walker's own point, not the dog's: the dog on its lead is a per-part shadow drawn at its
	# own literal radius, as the abduction's victim or the checkpoint hut's guard, since a two-body
	# composite has no single shape to be either of its bodies.
	row.ground([GameEnums.TileType.SIDEWALK])
	row.field(FieldSpec.of(33.0, 26.0, 105.0).pulsing_every(3.5))
	row.warning(WarningSpec.lasting(1.4))
	row.route(RouteSpec.at(32.0, RouteSpec.Kind.ALONG_STREET).up_to_tiles(30))
	# **Sent ahead of her on an ordinary day** (`EventDraft.sent_ahead()`; inbox #1460 in silky-lemur, "the same for
	# the dog walker"): the director creates it at once just out of sight down her own sidewalk,
	# walking toward her, as the loose dog comes, so the dog-walker decision is one she always meets.
	row.sent_ahead(SentAhead.at_once())
	# The heaviest weight in act I, and it goes **up** whenever rows are added around it. The density
	# is a fixed number of events, so every new type takes a share of it, and this is one of the two
	# that cannot be allowed to thin out: dog walkers and cafe frontages are what an ordinary street
	# is mostly made of, where a loose dog and an ice cream van are punctuation.
	# **The dog-walker decision has to happen at least twice on day one**, the density target
	# stated as one row; a cap in single figures makes it a coin flip. Repeats are fine, and
	# `EVENT_SPACING_SAME` answers two of them thirty pixels apart.
	row.drawn(4.5, 26)
	return row.build()

## The sidewalk, taken. A cafe spilling out of its frontage: chairs, tables, conversation, and no
## way past on this side.
##
## **The first event available on day one that cannot be walked through**, and a **wall** for
## exactly that reason rather than for what it costs: the body is 24px and the field bills anybody
## within 56px of it, so no lane of the 64px sidewalk it stands on is left free and
## `EventScheduler.role_for` answers `WALL` on 6.1 points of walk-through cost. `construction`
## does the same job from day 2 and is the loud version; this one is pleasant, which is worse:
## nothing about it looks like a hazard and it still costs the street. Stationary, so it can never
## pin the player the way a moving obstruction could.
##
## **Keeps a field, derived from the body.** A cafe is a real source of chatter, but it should
## raise excitement only when she is actually close. The field is the Minkowski sum of the body and
## a kernel, so the radii are read off the body and the street: inner radius is the body shape's radius +
## PLAYER_BODY_RADIUS` (24 + 14 = 38), she is touching the tables; outer radius is the sidewalk
## band's centre to the carriageway's centre line (`SIDEWALK_WIDTH·TILE_SIZE/2 +
## ROAD_WIDTH·TILE_SIZE/2` = 32 + 32 = 64), so it bills somebody at the tables and not somebody
## across the street, "across" beginning at the centre line.
static func _cafe_tables() -> EventDef:
	var row := EventDraft.new("cafe_tables")
	row.look(LookSpec.of(EventDef.Look.CAFE))
	row.body(BodySpec.solid(GroundShape.band(24.0)).walked_round().parked().as_a_spread())
	row.ground([GameEnums.TileType.SIDEWALK])
	row.field(FieldSpec.of(12.0, 38.0, 64.0).pulsing_every(6.0))
	row.warning(WarningSpec.lasting(1.6))
	# 24 does not clear `GroundShape.BAND_RADIUS`, so the body it derives stays a point: a cafe
	# frontage this narrow has no spine to be a capsule about.
	# Raised with `dog_walker` and for the same reason — see the note there.
	# Only what is inside `EVENT_STREAM_RADIUS` ever exists, a fraction of the map, so a cap in
	# single figures puts the expected number of cafes she *sees* in a day under one, and the day-1
	# event built to force a crossing is absent from most day ones.
	row.drawn(4.0, 24)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a junction box, 0: a box's ground never takes it, though its tiles lie there.
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.0)
	return row.build()

## Parked at the kerb, hazards going, half unloaded. Constant and stationary: the plain obstacle the
## route planning is practised on.
##
## **A parked van belongs at the kerb**, and on a `ROAD` tile it is scenery twice over: it stands in
## a traffic lane the crowd knows nothing about and drives straight through. At the kerb it is on
## the sidewalk she is actually using and it takes it: `VEHICLE_BODY` is 22px, so 44px of van across
## a 64px footway, and the answer is the other side of the street.
##
## **Silent**: static blockages should not raise excitement. Its whole job is standing in the way,
## and the body's reach (`obstructs_within()`) already prices that as a route cost. It is one of `SealPlanner`'s
## soft-seal candidates, placed on every real street off the day's route tree, so an ambient field
## would bill several hundred bodies a day for nothing she could see or avoid.
static func _delivery_van() -> EventDef:
	var row := EventDraft.new("delivery_van")
	row.look(LookSpec.of(EventDef.Look.DELIVERY_VAN))
	row.body(BodySpec.solid(GroundShape.band(VEHICLE_BODY)).walked_round().parked())
	row.ground([GameEnums.TileType.SIDEWALK])
	row.in_the_lane(EventDef.Pavement.AT_THE_KERB)
	row.field(FieldSpec.of(0.0, 40.0, 150.0))
	row.warning(WarningSpec.lasting(1.3))
	# Under `GroundShape.BAND_RADIUS`, so the stationary-vehicle segment rule still reduces it to a
	# point (see `GroundShape.band()`).
	row.drawn(2.0, 18)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a junction box, 0: a box's ground never takes it, though its tiles lie there.
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.0)
	return row.build()

## A park spoiler, and a pleasant one. Nothing about it is threatening; it is simply interesting,
## which is the whole problem.
##
## **The question is not "does the meter come down" but "can a whole day's worth of dipping below
## `EXCITEMENT_CALM_THRESHOLD` add up to a full sleep meter".** `Baby._update_sleepiness()` only
## fills while excitement is under the threshold, at the rate the calm ground's own lot size sets
## (`Tuning.sleepiness_calm_multiplier()`, 42x for a one-block park), and is otherwise frozen while
## awake, never given back. A dip lasting a few tenths of a second, repeated every seven-second
## beat, is worth far more over a whole day than a beat that merely "averages flat" suggests; the
## floor is a net sleep gain slow enough to never reach 100% in the allotted time.
##
## **19.3 is the lowest tenth, measured with `Baby`'s own real update functions rather than a rate,
## at which a whole day never fills the sleep meter standing at his own core.**
## `tests/probes/m128_park_beats.gd` simulates one busker, alone, at inner radius, starting at the
## calm threshold with an empty sleep meter, for `Tuning.DAY_LENGTH_SECONDS` (210s) plus a margin.
## The sweep's bare crossing is 19.2 (exactly `12.0 / 0.625`, the beat-mean zero); every intensity
## below it fills within 200s and every one at or above it never does, and 19.3 sits a tenth above
## the line so the choice is not on the exact edge.
##
## **The radii are 45/190, and the street-side answer is the intensity's problem, not theirs**: the
## street-side reach moves only because 19.3 is louder, not because the field is a different size.
## Quieter from the street is not what this number buys; the probe has the figures.
static func _busker() -> EventDef:
	var row := EventDraft.new("busker")
	row.look(LookSpec.of(EventDef.Look.BUSKER))
	row.body(BodySpec.solid(GroundShape.point(PERSON_BODY)).walked_through().parked())
	row.from_day(2)
	row.ground([GameEnums.TileType.PARK, GameEnums.TileType.SQUARE])
	# The lowest tenth, with a small margin above the sweep's own crossing, whose day never fills
	# a sleep meter standing at his own core (see the note above).
	row.field(FieldSpec.of(19.3, 45.0, 190.0).pulsing_every(7.0))
	row.warning(WarningSpec.lasting(1.7))
	# Kept the lowest of the act I caps on purpose: a busker is placed on PARK or SQUARE, the
	# only calm ground there is, and the calm ground the day keeps clear refuses every one that
	# would reach it.
	row.drawn(2.0, 10)
	return row.build()

## The widest body in Act I. It fills the sidewalk band it stands on, which makes it a **wall**
## although it is silent and cheap to walk past: a band with no lane left has no line along it,
## whatever the meter says. A street is sidewalk|road|sidewalk, so the road is always still there
## and it costs time and exposure, never the day.
##
## **Silent**: a hoarding is not a source but a thing to walk around, and `obstructs_within()`
## already prices the detour. It is one of `SealPlanner`'s soft-seal candidates, so it stands on
## every real street off the day's route tree; an ambient field would bill the meter for a wall of
## boards a street away with nothing to point at.
static func _construction() -> EventDef:
	var row := EventDraft.new("construction")
	row.look(LookSpec.of(EventDef.Look.ROADWORKS))
	row.body(BodySpec.solid(GroundShape.band(SIDEWALK_SPREAD_MAX))
			.walked_round()
			.parked()
			.as_a_spread())
	row.from_day(2)
	row.ground([GameEnums.TileType.SIDEWALK])
	row.field(FieldSpec.of(0.0, 46.0, 200.0))
	row.warning(WarningSpec.lasting(1.8))
	# `SIDEWALK_SPREAD_MAX`: the widest silhouette that reads as roadworks is 2px over the full
	# sidewalk band `EventInstance.setup()` centres it on.
	row.drawn(1.5, 15)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a junction box, 0: a box's ground never takes it, though its tiles lie there.
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.0)
	return row.build()

## Audible from streets away, moving fast down an arterial road, and it parks at the fire
## `burning_building` calls it in for and stays there for the rest of the day. Long telegraph,
## because the point of the approach is that you hear it coming and have time to get off that
## street.
##
## Never scheduled directly: a SCRIPTED def with no day, created only once the fire has been seen
## (`EventDef.calls_in()`, `EventSpawner.summon_what_has_been_sighted()`), so the player
## encounters the burning building before the engine.
static func _fire_truck() -> EventDef:
	var row := EventDraft.new("fire_truck")
	row.scripted_on(0, 1)
	row.look(LookSpec.of(EventDef.Look.FIRE_ENGINE))
	row.body(BodySpec.footprint(GroundShape.segment(16.0, 13.0)).walked_round().parked())
	# **The body is the drawing's ground contact**: 58px long (`fire_engine.svg`, x 2 to 60, bumper
	# to bumper) and 26px wide (`fire_engine_front.svg`, x 4 to 30, flank to flank), a capsule laid
	# along its heading, the patrol car's own construction, which `vehicle` makes the body. It is
	# lethal only in front of it while it drives its route, and solid and harmless once it has
	# parked at the kerb (`has_parked()` is not driving).
	row.vehicle(VehicleSpec.driving())
	# Its field stays a point's, priced from its centre: the body is not a reason for the street
	# beside the parked engine to cost more (`FieldSpec.from_its_centre()`).
	row.field(FieldSpec.of(26.0, 70.0, 340.0).from_its_centre())
	# The engine's whole warning: the badge goes up alone the moment the fire is seen and the engine
	# is created just out of sight on its road when this is over (see
	# `EventSpawner._summon_the_sighted_row()`). A second, `Tuning.WARNING_ALONE_MAX`, the most a
	# badge is up with nothing in the world (inbox #569 in busy-quail); its field already covers her
	# where it is created, so that second is the whole of what the contract's flat
	# `Tuning.OFFSCREEN_WARNING_MIN` measures.
	row.warning(WarningSpec.lasting(Tuning.WARNING_ALONE_MAX).warned_first())
	# And it stays at the fire once it gets there (`RouteSpec.parking_where_it_arrives()`): the
	# standing field beside a fire she was led to, and the pair of them, is a street she is meant to
	# turn round rather than walk down.
	row.route(RouteSpec.at(190.0).parking_where_it_arrives())
	return row.build()

## Act I's finale, and the day's own one-shot: a building alight on a sidewalk, with the engine
## called in the moment she first sees it (`aftermath.calls_in()`).
##
## **It is on her way, because the day sites it from the walk she is taking.**
## `EventDef.is_sited_from_her_walk()` leaves the plan without a position at dawn and
## `EventDirector.site_what_is_on_her_way()` puts it on a building face ahead of her heading once
## her direction for the day is clear: the fire comes first and is on her way guaranteed. A set
## piece sited anywhere in the city is a day-3 that can pass without a fire in it and without an
## engine.
##
## **The fire itself has no field and costs nothing to stand beside or walk through** (PLAYTEST-144
## 12): the challenge is the fire truck, not the fire. peak is 0.0 and it carries no
## solid body (`BodySpec.footprint()`: a look that does not obstruct is a shape alone), so
## `FireLook._draw_fire()` paints the flames and smoke on the facade of the building it stands
## against rather than leaving a body on the sidewalk, and its look casts no shadow, so nothing
## is put down at the ground point. inner radius/outer radius (60/260) and the 2.2s telegraph
## keep the row's geometry inside the fairness contract (`Tuning.validate_event()`), which checks
## every row the same way whether or not the field emits (`(outer radius - inner radius) /
## WALK_SPEED` = 2.17s). The `burnt_shell` scar it leaves is the
## building it burned, drawn burnt from the next morning on. **The finale's own fire, inside the
## building on the last night, is a copy of this row with a field and a body**
## (`building_fire()`), because in there the fire is the hazard and there is no truck to call.
##
## **It always catches on a wall the city actually draws**, since the building itself is shown burnt
## afterwards (`CityFronts.mark_the_burnt_frontage()`, `Building.Condition.BURNT`).
## `AGAINST_THE_BUILDING` only sites against an east-or-west wall
## (`RowGround._wants_this_side()`'s default branch), never a wall `building.gd` draws a facade
## on: every building is extruded south from its lot's south edge. `AT_THE_FRONT`, "the one face of
## a building the city draws" (`EventDef.Pavement`), is therefore this row's placement choice. A
## proposal, open to overturn if a fire that can also catch on the un-drawn walls matters more than
## a burnt shell with a real facade behind it. **Never on the power station's front**
## (`EventDef.burns_its_front()`): its facade does not draw burnt, and its transformer yard
## has no wall to burn.
static func _burning_building() -> EventDef:
	var row := EventDraft.new("burning_building")
	row.one_shot()
	row.look(LookSpec.of(EventDef.Look.BURNING_BUILDING).casting_no_shadow())
	# A footprint, no solid body: `EventDef.validate()` requires a shape wherever there is a
	# look to draw, but nothing stands here to be solid.
	row.body(BodySpec.footprint(GroundShape.point(30.0)).unmet().parked())
	row.from_day(3)
	row.until_day(3)
	row.ground([GameEnums.TileType.SIDEWALK])
	row.in_the_lane(EventDef.Pavement.AT_THE_FRONT)
	row.sited_from_her_walk(false)
	row.field(FieldSpec.of(0.0, 60.0, 260.0))
	row.warning(WarningSpec.lasting(2.2))
	row.aftermath(Aftermath.none().scarring(BURNT_SHELL_ID).calling_in("fire_truck"))
	return row.build()

## What is left the next morning, and every morning after, never repaired: the building the fire
## caught on, drawn burnt. The building carries it, not an object on the sidewalk in front of it:
## `CityFronts.mark_the_burnt_frontage()` turns the one `Building` behind the scar
## `Building.Condition.BURNT`, and `EventInstance` draws nothing for this row. Almost silent: a
## reminder rather than a hazard, on the same corner on day 12 as on day 4.
##
## **It has no body.** A body is half a silhouette (`docs/EVENTS.md`, "Solid things are solid"), and
## there is no silhouette on the sidewalk to be half of: the burnt shell is the lot, which the
## building's own collision already closes. The shape stays, as a footprint with no solid body, because it
## is what the 2.5/s field is measured from: a band along the frontage rather than a point, so the
## smell of smoke runs the length of the burnt front.
##
## **Radii from the band.** Both lose the segment's own `half_length` (12, from `band(36)`) so the
## along-axis reach is the 30/90 the row is priced at: inner radius 30 → 18, clamped to 24,
## outer radius 90 → 78.
static func _burnt_shell() -> EventDef:
	var row := EventDraft.new(BURNT_SHELL_ID)
	row.scripted_on(0, 1)
	row.look(LookSpec.of(EventDef.Look.BURNT_SHELL).casting_no_shadow())
	row.body(BodySpec.footprint(GroundShape.band(36.0)).unmet().parked().as_a_spread())
	row.field(FieldSpec.of(2.5, 24.0, 78.0))
	row.warning(WarningSpec.lasting(0.7))
	return row.build()

# ----------------------------------------- Act I: variety, and two with teeth ---
# **Act I has to escalate, and its danger is the neighborhood's own.** With every row that ends the day
# starting on day 8 or later, half a run would have nothing lethal in it but a car the player is
# never obliged to step in front of. The shape of that is a decision taken **against a patrol**:
# act I is a nice neighborhood, and a police patrol on day 2 tells a story the game tells in act II.
# So the two lethal rows are **a kid on a bike and a lorry reversing across a sidewalk**, what a
# person pushing a pram is actually frightened of, arriving on days 2 and 3. The rest is variety,
# and each row owes a silhouette of its own (see `EventDef.Look`).

## The leash slipped, and the dog is running, down the sidewalk she is on, toward her.
##
## The counterpart to `dog_walker` and the reason both exist: that one is a *span* you decide
## whether to cross the street to avoid, this one is a *thing coming down the sidewalk* that you
## cannot out-walk. Faster than `WALK_SPEED`, so the fairness contract makes it pay for the whole
## radius rather than the falloff band.
##
## `TOWARD_PLAYER`, sited by `EventDirector` on her own line when she gets close, since a dog sited
## before the day knows where she walks is a dog she may never pass, and the whole content of the
## row is meeting it. It is not a pursuer (`EventDef.pursues()`): it does not adjust to her or
## stop at a stand-off; it is a straight line down the sidewalk that she answers by crossing the
## street or turning.
##
## Not lethal, deliberately. Act I gets exactly two things that end the day and this is not one of
## them: a loose dog is chaos, and the day it ruins is ruined through the meter, where most of the
## game lives.
##
## **Intensity 39** (PLAYTEST-25 6), for the reason `dog_walker` and `homeless_yeller` are what they
## are: what matters is walking past, and it should not be free. `tests/probes/m174_pass.gd` walks a
## real instance past her at `Tuning.WALK_SPEED`, moving as it charges; what the pass nets at each
## offset is this row's line in `docs/COSTS.md`. **`TOWARD_PLAYER` never earns a `WALL` role**
## (`EventScheduler.role_for` answers `NONE` for anything the director sites), so nothing here
## trades against `EventScheduler.WALL_WORTH_OF_COST`. **But running still has to lose to it**,
## `tests/test_events.gd`'s catalogue-wide rule: at 42/s the shorter, faster crossing running buys
## costs less than walking it, which nothing but `car_accident` may do. 39/s is the loudest this
## field gets before that flips.
##
## **It is loud while it passes her, because its warning is over before it exists.** A telegraph
## damps a row to `EventInstance.TELEGRAPH_INTENSITY_FRACTION` (0.15) because *this has not started
## yet*, and a dog met inside its own telegraph is behind her before it is ever at 39. Its telegraph
## is its screen-edge warning instead, run with nothing in the world (`PendingWarning`), and the dog
## is created just out of sight with it spent, at its own intensity.
##
## **It does not telegraph its coming** (PLAYTEST-145 20): no screen-edge badge and no warning first
## (`WarningSpec.unannounced()`). The director sends it down her own sidewalk and it is created at once
## just out of sight there (`PendingWarning.down_her_line()`, `EventsAhead._send_down_her_line()`),
## its telegraph (`telegraphs_for()`) already spent, on the point of its beat that has it reach her at its loudest
## (`EventSpawner.age_when_warned()`), so a pass costs what it did under a warning. It is outside
## the telegraph contract rather than exempted from it.
static func _loose_dog() -> EventDef:
	var row := EventDraft.new("loose_dog")
	row.look(LookSpec.of(EventDef.Look.LOOSE_DOG).trailing_a_lead())
	row.body(BodySpec.footprint(GroundShape.point(9.0)).walked_through().going_on())
	row.ground([GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE])
	row.sited(EventDef.SpawnMode.TOWARD_PLAYER)
	row.field(FieldSpec.of(39.0, 30.0, 140.0).pulsing_every(2.2))
	# Spent before it is ever met (see above); it decides only where its beat starts.
	row.warning(WarningSpec.lasting(Tuning.WARNING_ALONE_MAX).unannounced())
	row.route(RouteSpec.at(132.0))
	# The other half of day 1's wall pool; see `leaf_blower` for the measurement both numbers came
	# out of. Between them they are what "leaving the path should be lethal or very expensive" can
	# be built from on the one day the game has nothing lethal in it at all.
	row.drawn(3.0, 24)
	return row.build()

## A market trestle taking the sidewalk, and the second thing on day 1 she has to walk round.
##
## **One obstacle repeated eighteen times is a rule, not a decision**, which is why day 1 needs a
## second one. This is louder and wider than `cafe_tables`: a cafe you squeeze past is a nuisance,
## a market is a crowd.
##
## **The row the passability reading of a wall was written from**: 28px of body denying 58px of a
## 64px sidewalk leaves no lane a stroller fits along, on 8.5 points of walk-through cost. See
## `EventScheduler._takes_a_whole_sidewalk`.
##
## **Keeps a field, derived from the body as `cafe_tables`' is** (see there for the full
## derivation). Its body's rounding is the same 24px (`GroundShape.BAND_RADIUS`, since 28 clears it
## into a real segment), so the pair is identical: inner radius = 24 + `PLAYER_BODY_RADIUS` (14)
## = 38, outer radius = 64. The two rows differ in body and intensity, not in reach.
static func _market_stall() -> EventDef:
	var row := EventDraft.new("market_stall")
	row.look(LookSpec.of(EventDef.Look.STALL))
	row.body(BodySpec.solid(GroundShape.band(28.0)).walked_round().parked().as_a_spread())
	row.ground([GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE])
	row.field(FieldSpec.of(14.0, 38.0, 64.0).pulsing_every(8.0))
	row.warning(WarningSpec.lasting(1.7))
	row.drawn(1.6, 13)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a junction box, 0: a box's ground never takes it, though its tiles lie there.
	# - open ground, 0.00098: rare on open ground (its share there against the street
	#   musician's), and moved by the scaling pass.
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.0)
	row.weighed_on(PlacementGround.Kind.OPEN, 0.00098)
	return row.build()

## The loudest thing in act I, and it is a man tidying a park.
##
## Allowed on `PARK`: a calm block with a leaf blower in it is calm ground she cannot use, which is
## what a spoiled park is made of.
##
## **A field with two parts, answering two questions.** Walking past a leaf blower should be like a
## wall, but staying away from it should only prevent sleeping in a calm area, like the busker.
## Away from it the row **is** the busker, number for number, so several spaced across a park keep
## it awake and a walk one street over pays a price rather than meeting a wall. Close in, the core
## carries the wall.
##
## **The core is the sidewalk it stands on.** core reach is `Tuning.SIDEWALK_WIDTH *
## Tuning.TILE_SIZE` (64px), a sidewalk's own width: the smallest radius that holds the whole
## footway from anywhere on it, and from the kerb-side tile (the worst one) it stops short of the
## far kerb, so the thing closes one side of a street and never the street. A line past the core at
## core reach costs what the same line past a busker costs.
##
## **core rate anchors `EventScheduler.WALL_WORTH_OF_COST`'s line**, re-derived against the
## 6.0/s walking decay with `tests/probes/m174_pass.gd`'s walk-past simulation (the source held
## still, since this row never paces). A pass at 0/20px of lateral offset, the ground a sidewalk
## offers once the body (11px) and her width are cleared, nets back to within a few percent of what
## it netted against a 3.5/s decay; the widest offset tested (40px) recovers most of it rather than
## all, the smaller of two costs weighed against raising a wall row's number further than the line
## needs. `walk_through_cost()` is the number re-derived against, comfortably past
## `EventScheduler.WALL_WORTH_OF_COST`, which that constant explains alongside `dog_walker`'s.
static func _leaf_blower() -> EventDef:
	var row := EventDraft.new("leaf_blower")
	row.look(LookSpec.of(EventDef.Look.LEAF_BLOWER))
	row.body(BodySpec.solid(GroundShape.point(PERSON_BODY)).walked_through().parked())
	row.ground([GameEnums.TileType.SIDEWALK, GameEnums.TileType.PARK,
			GameEnums.TileType.SQUARE])
	# The busker's field exactly (see `_busker()` for how 19.3 over 45/190 was measured).
	# Swept in bursts rather than held, so there is a rhythm to time a pass through, as
	# `homeless_yeller` has, at a scale that makes a whole corner of a park unusable.
	row.field(FieldSpec.of(19.3, 45.0, 190.0)
			.with_a_core(35.0, float(Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE))
			.pulsing_every(4.0))
	row.warning(WarningSpec.lasting(1.8))
	# **A wall row, and on day 1 it is half of the entire wall pool**, so its weight and its cap are
	# most of what "leaving the path should be lethal or very expensive" is built out of on the one
	# day with nothing lethal in it.
	#
	# **Which of the two binds differs by day.** A **cap** binds on the middle days, where the lethal
	# wall rows are capped in single figures across 121 blocks. A **weight** binds on day 1, where
	# no cap is ever reached: a row is only *offered* as often as its weight, so the wall share is
	# fixed however high the ceiling goes. Raising a cap the day never reaches is the other half of
	# *a share the catalogue cannot fill is not density*.
	#
	# At 3.0 and 24, over five seeds, day 1 places 29 walls and the cost per tile of street runs
	# **corridor 0.202 / rim 0.253 / deep 0.216**, the gradient the design asks for: stray one
	# turning and it is expensive. It makes a leaf blower as common a sight as a dog walker: the
	# price of day 1 having exactly two rows a wall can be made of.
	row.drawn(3.0, 24)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - open ground, 0.0006: rare on open ground (its share there against the street
	#   musician's), and moved by the scaling pass.
	# - a junction box, 0.3: set by the scaling pass: its share of a junction box's events was
	#   off by more than a factor of two.
	row.weighed_on(PlacementGround.Kind.OPEN, 0.0006)
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.3)
	return row.build()

## Pigeons off the sidewalk all at once: standing on the ground long before she is near, then up as
## she walks into them, then away.
##
## **A place rather than a moment, because a flock has to exist before it is seen** (PLAYTEST-69).
## A row the director sites is created a reaction window in front of her
## (`Tuning.AHEAD_LEAD_DISTANCE`, 184px, inside the 320px half-view on a sideways heading), which a
## cat can afford. Eleven birds cannot: a flock is a *patch of sidewalk*, and one that was not there
## a second ago is not one anybody can plan around. On a tile they are pecking about from the moment
## the day streams them in at `Tuning.EVENT_STREAM_RADIUS` (900px), so what she sees from down the
## street is the thing she is deciding about.
##
## **The telegraph contract is then paid in geometry, as the robber's is.**
## Its waiting for her (`EventDef.waits_for_her()`) is the wait: the birds stand there unclocked
## and quiet, and the clock starts when she comes inside the trigger rather than at dawn, four
## streets away. It is the shape `alley_mouse` and a `MAP`-placed `charging_dog` use, and it
## keeps "it must not be over before she arrives" true without siting the row on top of her.
##
## **The birds go up when she reaches them, which a clock cannot know.** They are on the ground for
## the whole telegraph by construction, so under the clock alone a walk straight in put them up
## about 84px past her. `EventNoticeRun` fires the burst at the flock's spread plus her own body,
## the distance at which she is among the birds rather than near them, as a pursuer's lunge is fired
## by her reaching its stand-off.
##
## **Its telegraph (`telegraphs_for()`) is 1.7s and is the backstop rather than the wait.** It only decides a flock she
## came near and never reached (80px off the middle, say); shortening it would put *those* birds up
## sooner. `Tuning.validate_event()` asks 1.55s of this geometry and the number clears it.
##
## **Intensity 42, and walking into them is meant to be dear** (PLAYTEST-117 25): flushing at the
## birds charges the burst while she is *among* them, so the straight line through the middle costs
## several times what a late flush did. The answer to a flock is to stop short and let it leave,
## which costs nothing, or to go round its wide quiet rim.
##
## **The number is set by walking a real instance and cannot be derived.** The rate is shared out
## between eleven birds that fly up and away from her while she crosses, and the flush is geometric,
## so neither `walk_through_cost()` nor `docs/COSTS.md` prices this row (the table dashes its pass
## columns for that reason). **The instance has to be in the tree**: a bare `EventInstance.new()`
## never gets `_ready()`, so `EventFlock.build()` never runs, its birds stay empty and
## `contribution_at()` falls back to the modelled ring on this def, which reads far higher than
## eleven birds charge. `tests/test_events.gd` walks it in the tree, and that is the figure the
## intensity was set against.
##
## **The rim is where the cut lands.** A line 80px off the middle never comes inside the birds, so
## the flush never fires there and skirting a flock is net recovery. A narrower field or a shorter
## burst would change what the row *is* rather than what it charges.
##
## **Four things have to be true for a flock to be an event at all:**
##
## - It must not be **over before she arrives**: the telegraph is the flock on the sidewalk about
##   to go, and the burst outlasts her arrival.
## - It must not be **quiet and small**. A flock going up in a pram's face is one of the loudest
##   things on an ordinary sidewalk, measured by what walking through one costs: the intensity is
##   shared between eleven birds, so the middle is several overlapping fields and the rim is one.
##   `docs/COSTS.md` carries the rate; the line through it is measured by walking, in
##   `tests/test_events.gd`.
## - It must not be **deleted at the top of its climb**, which is what
##   `EventDef.departure_speed()` is for.
## - The **birds** have to move, not just the event. Copies of one sprite at fixed offsets sharing a
##   single `rise` term go up in one movement and hang in the air for the whole burst.
##
## So it is eleven birds, each with its own heading, speed, height and wingbeat, each an
## emitter in its own right (see `EventInstance`, "the flock"):
##
## - **The intensity is a total to be shared out**, so it buys eleven overlapping fields rather than
##   one: walking round the edge meets one bird, through the middle five. It is the third loudest
##   thing on an act I sidewalk at the centre and nearly free at the rim.
## - **The spread comes out of the outer radius, not on top of it.** A bird emits over
##   the outer radius less the spread, so the union of eleven moving fields is inside the one disc
##   the fairness contract was checked against. The telegraph is still measured against 168px.
## - **It fades as they climb.** swell is the burst being loudest at the instant they go
##   up, which also earns it a caret for the whole burst rather than only the telegraph: a flock is
##   danger that changes over time, the one thing the mark is for.
static func _pigeon_flock() -> EventDef:
	var row := EventDraft.new("pigeon_flock")
	# It does not telegraph its coming (`WarningSpec.unannounced()`): the birds go up where she walks in
	# rather than coming at her, and they cannot end the day; no badge, outside the telegraph
	# contract.
	row.warning(WarningSpec.lasting(1.7).unannounced())
	row.look(LookSpec.of(EventDef.Look.BIRDS))
	row.body(BodySpec.footprint(GroundShape.point(5.0)).walked_through().going_on())
	# A flock has no single body (each bird casts its own shadow at its own faded radius, see
	# `FlockLook._draw_birds`), so this is a nominal point at one bird's base radius (5.0, before the
	# height fade), carried only to satisfy "a row with a look has a shape". A flock never obstructs;
	# `EventDef.validate()` refuses one that tries.
	row.ground([GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE,
			GameEnums.TileType.PARK])
	row.sited(EventDef.SpawnMode.MAP)
	# The wait: inside the 168px field, so the clock starts on ground she is already being charged
	# for, and more than twice the 62px wheel, so the flock is already counting by the time she is
	# near the birds. Its quiet notice (`NoticeSpec.is_quiet()`) damps the wait and the telegraph by the
	# same fraction: birds on a sidewalk are nearly nothing, and a flock nobody has walked up to
	# must not be a place she cannot walk past.
	row.notice(NoticeSpec.at(150.0).quietly())
	row.field(FieldSpec.of(42.0, 26.0, 168.0).swelling_by(0.4))
	# Eleven of them over a 62px wheel: enough that the middle is unmistakably a crowd of birds and
	# few enough that a player can see the gaps between them and aim at one.
	row.flock(FlockSpec.of(11, 62.0))
	row.lasts(4.0)
	# On the ground the whole time, which makes this a thing to walk around rather than a thing that
	# happens. Over the 1.55s the contract asks of a 168px field, measured from the moment it
	# notices her (`EventDef.notice_within()`). The backstop for a flock she passed without
	# reaching; the flush at the birds ends it for one she walked into. Faster than she can run,
	# and up: they are gone in a second and a half and they are gone *somewhere*.
	row.leaves_at(190.0)
	row.drawn(1.5, 5)
	# **A flock is scenery, not a block** (PLAYTEST-71). Left unset, a 42-over-168px field crosses
	# `EventScheduler.WALL_WORTH_OF_COST` and `EventScheduler.role_for()` would call this a `WALL`, pulling it off
	# every route; `Role.SCENERY` answers `NONE` first, so it lands on a route corridor exactly as
	# it lands anywhere else.
	row.plays(EventDef.Role.SCENERY)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - open ground, 0.0038: rare on open ground (its share there against the street
	#   musician's), and moved by the scaling pass.
	row.weighed_on(PlacementGround.Kind.OPEN, 0.0038)
	return row.build()

## **The first thing in the game that can end your day, and it arrives on day 2.**
##
## A kid on a bike on the sidewalk she is walking, bell going, coming toward her. Everything about
## it is ordinary, which is the point: act I acquiring danger must not mean act I becoming sinister,
## it means act I being a real street.
## actually frightened of.
##
## `TOWARD_PLAYER`: `EventDirector` sites it on her own line when she gets close, coming the other
## way, so she has to answer with a route decision (cross to the other side, or turn) rather than
## meeting it on a street the day chose at dawn. It does not `pursue`: a bike does not chase, it
## rides straight through wherever she was standing.
##
## **He is warned of before he exists** (PLAYTEST-145). The director's siting puts up a screen-edge
## badge with nothing in the world, pointing down her line, and when his telegraph (`telegraphs_for()`) is over he
## is created just out of sight there on a sidewalk (`PendingWarning.down_her_line()`), with that
## telegraph spent, so he is lethal from his first frame; `EventInstance.is_lethal_at()` refusing a
## running telegraph never lets him ride through her harmless.
##
## The fairness contract does the work: from the badge to his reach, walking into him, she is owed
## the flat `Tuning.OFFSCREEN_WARNING_MIN` (1.0s) every warning from off screen is owed, which
## `EventDef.warning_time()` measures. `EventDef.validate()` also refuses a field that reaches where
## he is created closest, `SpawnSiting.least_distance()` (180px, the view's short axis); 90 sits far
## under it.
##
## **inner radius is 33px, not the 26 a bike's own width would suggest** (PLAYTEST-25 7). 26px sits
## *under* the 32px spacing between the two lanes of a two-tile sidewalk (`Tuning.TILE_SIZE`, a lane
## on its own tile centre), the same gap that let `chatting_mother`'s hold reach (`HoldSpec.past_its_edge()`) be walked past
## on the far lane (see that row). Both are "it catches you" rows that caught nobody, and both are
## 33px or more: past the lane spacing and under outer radius, so the far lane of her own sidewalk
## does not answer a bike coming down it for free.
##
## Day 2 rather than day 1 on purpose: day 1 may be easy as long as the difficulty then climbs, and
## day 2 is the day the streets acquire something that can take the day off you.
##
## About one rider in 400 is drawn as a pelican on the same bike (`EventSpawner.rolls_a_pelican()`),
## and nothing else about him changes: the pelican is a picture, never a row of its own.
static func _cyclist() -> EventDef:
	var row := EventDraft.new("cyclist")
	row.look(LookSpec.of(EventDef.Look.CYCLIST).maybe_a_pelican())
	row.body(BodySpec.footprint(GroundShape.point(12.0)).walked_through().going_on())
	row.from_day(2)
	row.ground([GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE])
	row.sited(EventDef.SpawnMode.TOWARD_PLAYER)
	row.field(FieldSpec.of(18.0, 33.0, 90.0))
	# His warning, run before he exists: the screen-edge badge goes up alone, with nothing in the
	# world, for `Tuning.WARNING_ALONE_MAX` (a second; inbox #569 in busy-quail), and he is created
	# just out of sight when it is over (`PendingWarning`). What the contract holds is the
	# badge-to-reach time, `EventDef.warning_time()`, against the flat
	# `Tuning.OFFSCREEN_WARNING_MIN`: this, plus 0.57s for him to close from where he is created
	# closest (180px) to his 33px reach at 257px/s with her
	# walking into him.
	row.warning(WarningSpec.lasting(Tuning.WARNING_ALONE_MAX))
	row.route(RouteSpec.at(165.0))
	row.lethal(LethalSpec.at_its_core())
	# Well under the ordinary act I rows, and the cap does different work than its number suggests:
	# `TOWARD_PLAYER` never puts it on a tile, so it cannot tile a street. What the cap bounds is how
	# many of the moments she is owed (`PlacementDensity.moments_on()`) are cyclists rather than cats
	# and dogs, and `EventDirector.AHEAD_INTERVAL` (11-26s apart) throttles the rest: the director draws one
	# owed row at a time from a shared queue with the cat and the dog, so how many she can meet is
	# bounded by the day's length long before the cap is.
	row.drawn(1.5, 14)
	return row.build()

## A jingle you can hear three streets away, and children arriving from everywhere.
##
## The `busker` argument, one size up and on day 2: nothing about it is threatening, it is simply
## interesting. Stationary, with the widest ordinary radius in act I, it is the act I answer to
## *what makes a whole area unusable without anything being wrong*.
##
## At the kerb, for the same reason as the delivery van: a van parked in a traffic lane is a van the
## crowd drives through, and an ice cream van is a thing children cross a road to reach rather than
## a thing standing in one.
##
## **A wall by passability, unlike the van**: its field charges over 189px against the van's 22, so
## there is no lane of a sidewalk left free beside it and `EventScheduler.role_for` keeps it off
## the route's own side of the street.
static func _ice_cream_van() -> EventDef:
	var row := EventDraft.new("ice_cream_van")
	row.look(LookSpec.of(EventDef.Look.ICE_CREAM_VAN))
	row.body(BodySpec.solid(GroundShape.point(24.0)).walked_round().parked())
	row.from_day(2)
	row.ground([GameEnums.TileType.SIDEWALK])
	row.in_the_lane(EventDef.Pavement.AT_THE_KERB)
	# The jingle is a loop, so the meter cost comes and goes on the same period it does.
	row.field(FieldSpec.of(13.0, 48.0, 240.0).pulsing_every(11.0))
	row.warning(WarningSpec.lasting(2.2))
	# `ice_cream_van.svg` is 50px across.
	row.drawn(1.5, 5)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a junction box, 0: a box's ground never takes it, though its tiles lie there.
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.0)
	return row.build()

## A box lorry reversing across the sidewalk into a yard, beeper going. Act I's second lethal thing,
## and the one that teaches a different lesson from the cyclist.
##
## The cyclist is *coming down the street at you* and the answer is to get off the sidewalk. The
## lorry is **stationary and the danger is behind it**: the answer is not to walk into the gap it
## is backing into, which you have to look at the world to know. Static, so it can never chase
## anybody, and the beeper runs long because a hard fail owes double.
##
## Day 3, which puts one new lethal thing on each of the first act's last two days.
##
## **The yard it is backing into has to be there.** Sited on any sidewalk tile it is mostly a lorry
## parked in the middle of a footway, and a parked lorry is not a thing whose danger is *behind* it.
## `AGAINST_THE_BUILDING` gives it a wall to reverse into and turns it to face out of that wall, so
## the 62px silhouette has its box end buried in the frontage and its cab on the sidewalk. **The
## lesson is the shape of the picture**: what you must not walk into is the gap between the metal
## and the wall.
static func _reversing_lorry() -> EventDef:
	var row := EventDraft.new("reversing_lorry")
	row.look(LookSpec.of(EventDef.Look.LORRY))
	row.body(BodySpec.solid(GroundShape.point(28.0)).walked_round().parked())
	row.from_day(3)
	row.ground([GameEnums.TileType.SIDEWALK])
	row.in_the_lane(EventDef.Pavement.AGAINST_THE_BUILDING)
	# The beeper. Steady enough to locate, slow enough to be a countdown rather than a wall.
	row.field(FieldSpec.of(16.0, 46.0, 175.0).pulsing_every(1.6))
	# Ends the day, stationary: (175-46)/92 * 2 = 2.80s.
	row.warning(WarningSpec.lasting(3.0))
	# `lorry.svg` is 62px across, and 28 + her own 14 is inside the 46 that ends the day, so the
	# metal is solid and touching it is still fatal (`EventDef.validate()` makes that arithmetic a
	# rule).
	row.lethal(LethalSpec.at_its_core())
	# A lethal wall row, capped like `cyclist` for the same reason: the deep band off the corridor is
	# where the deadly end of the gradient lives, and a handful across 121 blocks cannot fill it.
	row.drawn(1.2, 12)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a junction box, 0: a box's ground never takes it, though its tiles lie there.
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.0)
	return row.build()

## Another mother with a pram, on her own beat, with her own cost model: getting too close catches
## one up in a conversation that takes 5s and consumes 25% excitement; if the baby is already
## sleeping it is a pure time loss, if not it bears overstimulation risk (PLAYTEST-18 4).
##
## **A paced sidewalk fixture, like `homeless_yeller`**: she is *at* a place rather than passing
## through it, and pacing guarantees streaming actually meets her. Her ambient field is
## person-scale (peak near a passer-by's `CrowdExcitement.PEDESTRIAN_INTENSITY`, 4.2) and its
## outer radius is tight, so brushing past her without triggering a conversation costs about what
## an ordinary close pass does.
##
## **The conversation is a trigger rather than a field**: entering its hold's reach (`HoldSpec.past_its_edge()`) of an instance
## that has not yet chatted locks the stroller's movement input for its hold's seconds (`HoldSpec.detains_for()`)
## (`Stroller.detain()`), and the meter cost during that lock is priced entirely by
## `EventInstance.current_intensity()` reading the baby's state, never by anything authored here.
##
## **Its hold's reach (`HoldSpec.past_its_edge()`) is 48px, three quarters of the 64px sidewalk band** (PLAYTEST-25 4). The whole
## content of this row is that she catches you, so a radius the far lane clears by construction is
## a row with a free answer: 26px sat under the **32px** spacing between the two lanes of a
## sidewalk (`Tuning.TILE_SIZE`), and 33px, just past it, was still too small. 48px reaches from
## either lane of her own sidewalk to the frontage, so no line on her sidewalk walks past her, while
## the far sidewalk, 96px away centre to centre, still does. **inner radius is 56** because
## `EventDef.validate()` requires the capture to sit strictly inside the inner radius (the chat's
## flat rate assumes she is inside it), so widening the capture widens the full-cost core with it,
## by a lane's width, which is small next to what the conversation costs. outer radius is 70.
##
## `first_day` 1: act I is the social act, and `test_balance.gd` passes with her live on it, since
## she is `SIDEWALK`-only and never contests the calm ground the balance suite measures.
static func _chatting_mother() -> EventDef:
	var row := EventDraft.new("chatting_mother")
	row.look(LookSpec.of(EventDef.Look.CHATTING_MOTHER))
	row.body(BodySpec.footprint(GroundShape.point(14.0)).walked_through().going_on())
	row.from_day(1)
	row.ground([GameEnums.TileType.SIDEWALK])
	row.field(FieldSpec.of(4.5, 56.0, 70.0))
	# (70-56)/92 = 0.15s required; it does not end the day, so no doubled margin. Generous rather than tight,
	# since the ambient field is nearly nothing next to what the conversation costs.
	row.warning(WarningSpec.lasting(1.0))
	# A pram's pace, slower than an ordinary walk and a touch slower than `dog_walker`'s 32.
	row.route(RouteSpec.at(26.0, RouteSpec.Kind.ALONG_STREET).up_to_tiles(8).pacing())
	row.drawn(2.0, 2)
	row.hold(HoldSpec.for_seconds(5.0).from(48.0))
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a street, 0.29: set by the scaling pass: its share of a street's events was off by more
	#   than a factor of two.
	# - a junction box, 0.1: set by the scaling pass: its share of a junction box's events was
	#   off by more than a factor of two.
	row.weighed_on(PlacementGround.Kind.STREET, 0.29)
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.1)
	return row.build()

## **The one thing in the game you have to run from, and it arrives on day 3.**
##
## Everything else in the catalogue is something you route **around**, and against all of it running
## is strictly worse than walking (`EXCITEMENT_FROM_RUNNING` outweighs the shorter exposure every
## time, which `tests/test_events.gd` asserts row by row). This is the exception: a pursuer cannot
## be routed around, because it goes where she goes, so the only question it asks is *how fast*.
##
## Every number in it is doing one job:
##
## - **130px/s** sits between a walk (92) and a run (168), *symmetrically*: walking loses 38px a
##   second and running gains 38, so the two answers give opposite outcomes at the same rate, the
##   version a player can feel. **Asymmetry is the trap**: at 148 running gains only 20px a second,
##   so shaking it off takes longer than the chase lasts and the price of doing the right thing is
##   set by the clock instead of by the escape.
## - **It comes through its own telegraph, and stops short.** A pursuer that waits politely hands
##   her more ground in two seconds than the whole chase can take back, so the notice is the sight
##   of it closing, but the sight of it closing *onto her* is not notice at all.
##   `PursuitSpec.standoff()` is where it stops: 104px, six tenths of a second of its own speed
##   outside the radius that ends the day.
## - **A capped chase, and a break-off that pays for reacting early.** A run is fourteen points a
##   second, so the chase needs a cap, but `Tuning.PURSUIT_SHAKEN_OFF` is what prices the answer:
##   about 17 points given promptly, the most expensive moment in act I and much cheaper than the
##   day it buys.
## - **Intensity 12.** It is lethal; it does not also need to be the loudest thing in act I. Much
##   above this the correct play (run, at 14 points a second, for as long as it takes) costs more
##   than the meter has. What ends the day here has to be the dog, not the noise.
##
## `RUN_TAUGHT_DAY` because that is the day act I stops being a nice neighborhood (`cyclist` on
## day 2, `reversing_lorry` on day 3), and two days of paying for the run button is what makes being
## made to press it read as the rules arriving. `EventDirector` puts the first one in front of her
## early on that day; see `Tuning.RUN_TAUGHT_DAY`.
##
## **The lesson does not retire, and it does not stay a lesson either** (PLAYTEST-68). Past
## `RUN_TAUGHT_DAY` this row is two already-authored shapes at once: `EventScheduler` places it on
## a tile like `alley_robbery`, waiting inside its own field for her (`EventDef.spawn_mode_on()`);
## and `EventDirector` now and then still sends the day-3 shape itself (warned first from off
## screen, already noticing her, no tip), `EventDirector.CHARGING_DOG_SPRINKLE_CHANCE` of the time
## on a day it is eligible. One `EventDef` answers both, since neither changes what the row *is*,
## only whether she is routed into it or walks into it while going about her day.
static func _charging_dog() -> EventDef:
	var row := EventDraft.new("charging_dog")
	row.look(LookSpec.of(EventDef.Look.CHARGING_DOG)
			.warning_as(LookSpec.WarningPicture.DOG_ALERT))
	row.body(BodySpec.footprint(GroundShape.point(13.0)).walked_through().going_on())
	row.from_day(Tuning.RUN_TAUGHT_DAY)
	row.ground([GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE])
	# No `last_day`: the dog recurs after the teaching day rather than being spent by it. On
	# `RUN_TAUGHT_DAY` itself `spawn_mode` is `AHEAD_OF_PLAYER` and `EventDirector` puts it dead
	# ahead of her, because the lesson depends on it. Every day after, `spawn_mode_on()` answers
	# `MAP`: placed on a tile as `alley_robbery` is and met by routing into it. One `EventDef`
	# rather than a second row: a later dog needs its own `Look` and there is no spare silhouette
	# (`tests/test_events.gd` refuses two rows sharing one), and `spawn_mode_on()` is the
	# field that lets one row answer two days without ever mutating the shared resource.
	row.sited(EventDef.SpawnMode.AHEAD_OF_PLAYER)
	# From the day after the lesson it is a place on the map that waits for her inside its one
	# radius, written 130px and drawn at the run's charger reach (`ChargerTiming.notice()`, 162.5px
	# as shipped), inside its field (inbox #788 in minty-lemur; curly-moose #803).
	# `EventDef.for_day()` hands a placement past the switch a copy carrying it.
	row.switching_after(Tuning.RUN_TAUGHT_DAY, EventDef.SpawnMode.MAP,
			NoticeSpec.at(_chargers.notice(130.0)))
	# Wider than the stand-off, a constraint rather than a taste: a pursuer holds its stand-off
	# through its whole telegraph, so a field narrower than that is a field it is never inside; the
	# dog would spend the entire warning emitting nothing at her, the `!` over her head would never
	# go up, and the trace would attribute the mark to "nothing in reach". `validate_pursuit`
	# refuses the arrangement. Twenty pixels past its notice, so the meter says it is there before
	# it has noticed her, growing with the notice (`ChargerTiming.field_reach()`: 182.5px as
	# shipped).
	row.field(FieldSpec.of(12.0, 26.0, _chargers.field_reach(150.0, 130.0)))
	# The chase proper, once it can end the day: `Tuning.PURSUIT_TIME`, a long cap rather than an end
	# a walk can outlast. Running is what ends it, at `Tuning.PURSUIT_SHAKEN_OFF`'s rate.
	row.lasts(Tuning.PURSUIT_TIME)
	# Its approach, spent visibly closing once it is placed just out of sight: the gold timing's
	# on-screen part, which `tests/test_events_pursuit.gd` fails on if it moves. Comfortably over
	# `PURSUIT_MIN_NOTICE`: walking away from the day-3 dog, the lunge never fires (she keeps
	# opening the gap it closes to), so the chase starts when this runs out, and this and
	# `duration` are what catch a walker. The dog that waits for her past the teaching day does not
	# read it: it warns by radius (`EventInstance.warns_by_radius()`).
	row.warning(WarningSpec.lasting(4.5).badged_for(0.5))
	# From day 4, once it notices her, it warns on the clock every charger that waits for her keeps
	# and stands in its alert pose rather than closing (woolly-penguin #748); the day-3 dog has no
	# wait, so its approach is still its telegraph (`EventInstance.is_standing_for_its_notice()`).
	row.pursuit(PursuitSpec.at(130.0).warning_for(_chargers.warning()).standing())
	# Its badge alone, sent at her down her heading, before it is placed just out of sight
	# (`EventDef.warned_for()`): half a second, the gold timing's off-screen part, and the reason it is
	# half a second is on `WarningSpec`'s badge notice (`_badge_notice`).
	# And it trots off rather than blinking out: a dog that gives up in front of her and then is not
	# there says the chase was never real.
	row.leaves_at(110.0)
	row.lethal(LethalSpec.at_its_core())
	# Rare on purpose: it is the one thing running answers, and a street with three of them would
	# turn the run button into a second walk speed.
	row.drawn(1.4, 3)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a street, 0.22: set by the scaling pass: its share of a street's events was off by more
	#   than a factor of two.
	# - a junction box, 0.29: set by the scaling pass: its share of a junction box's events was
	#   off by more than a factor of two.
	# - open ground, 0.0015: rare on open ground (its share there against the street
	#   musician's), and moved by the scaling pass.
	row.weighed_on(PlacementGround.Kind.STREET, 0.22)
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.29)
	row.weighed_on(PlacementGround.Kind.OPEN, 0.0015)
	return row.build()

# ------------------------------------------------------- Act II: notices (4-7) ---

## Mobile, unhurried, and it stops. Its field is not the danger; the danger is that you start
## planning around it.
##
## **A car, solid and lethal the way a car is** (`EventDef.drives()`; inbox #648 in leafy-puffin):
## she walks round its body whether it drives or stands, and it ends the day only in front of it,
## while it drives its route, with her on the carriageway.
##
## **The patrol rung of the resistance's ladder.** Its hunt is `HuntSpec.pressing()`: with
## `RunState.resistance().progress()`, more of them and louder, and past
## `EventDef.HEAT_INVESTIGATES_LEVEL` it stops merely patrolling and starts investigating: it stops
## on its road once she is close and a policeman gets out and pursues her
## (`EventDef.investigates()`, `out_of_the_car()`), whose catch costs her and never ends the day by
## itself. The car never ends the day, whatever the heat, and never strikes her while it
## stands for him; the unmarked van is the rung that hunts.
static func _police_patrol() -> EventDef:
	var row := EventDraft.new("police_patrol")
	# It does not telegraph its coming (`WarningSpec.unannounced()`): 74px/s is slower than a walk, and
	# its strike is a car's, warned the way a car warns (`EventDef.drives()`) rather than with a
	# badge from off screen. Its copies (the one the director sends ahead of her, the raid's pacing
	# car and the investigating one at heat) carry it with them.
	row.warning(WarningSpec.lasting(1.97).unannounced())
	row.look(LookSpec.of(EventDef.Look.POLICE_CAR))
	row.body(BodySpec.footprint(GroundShape.segment(9.0, 12.0)).walked_round().going_on())
	# **The body is its drawn ground contact**: 42px long, the side view's body from bumper to
	# bumper (`police_car.svg`, x 2 to 44), and 24px wide, the end views' body from flank to flank
	# (`police_car_front.svg`, x 3 to 27), as a capsule laid along its heading, the datum its
	# shadow is drawn from. `vehicle` makes it the body as well.
	row.vehicle(VehicleSpec.driving())
	row.from_day(4)
	row.ground([GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING])
	row.field(FieldSpec.of(10.0, 44.0, 185.0))
	# Slower than a walk, so the escape distance is the falloff band stretched forward by the
	# patrol's own eccentricity: `(outer radius - inner radius) · Field.scale(e)` at 74px/s
	# (e = 0.148) is 165px, 1.80s, plus the row's margin.
	row.route(RouteSpec.at(74.0, RouteSpec.Kind.ALONG_STREET).up_to_tiles(40))
	# **Sent ahead of her on an ordinary day** (`EventDraft.sent_ahead()`; inbox #1460 in silky-lemur, "just spawn in
	# the car just ahead of the player? then you guarantee an encounter"): created at once down the
	# carriageway lane that drives toward her, the return leg's patrols among them.
	row.sent_ahead(SentAhead.at_once())
	row.drawn(3.0, 12)
	# Past the threshold it stops for her and lets one man out (`HuntSpec.pressing()`, the patrol
	# rung, which investigates and never hunts).
	row.hunt(HuntSpec.pressing())
	return row.build()

## Cosmetic dread. Barely moves the meter; it is here so the walls change.
##
## **`AGAINST_THE_BUILDING`, the way `reversing_lorry` stands.** A crew pastes posters at the wall
## it works on rather than in the middle of the sidewalk, and the placement answers the width rule
## as well as the picture: centred (the `ANY` default) an 11px body leaves under 28px on each side
## of the 64px band and is a wall by physical fit (`EventScheduler._closes_the_band_by_its_own_
## placement`); pinned to the frontage lane's tile centre, `TILE_SIZE * 0.5` from the wall, it
## spans 5-27px of the band and leaves 37px to the kerb, over the 28px she needs, so it stays
## friction. `RowGround._wants_this_side()` narrows its `SIDEWALK` ground to north-south streets with a real
## building on the far side, as `reversing_lorry` does.
##
## **It is a sidewalk row only.** A square answers no `pavement_inward`, so there is no frontage
## lane on one for a crew to stand in; `poster_crew_square` is the square's own crew, at the column
## a square has instead of a wall.
##
## **It works on walls along the way she walks** (`EventDef.is_sited_from_her_walk()`,
## `OnHerWay.pastes_a_front()`; PLAYTEST-116). A crew placed anywhere in the city is a crew she
## never meets. So a unit that draws a crew hands it to her walk with no position
## (`MarbleDraw.draw()`), and her walk sites each crew, one at a time, on her branch of the
## day's routes, in front of a blank ground-floor cell and facing it, as day 3's fire is sited.
## Once in the world it stays, and `PosterWalls` has it paste its wall while it is in her view.
## Its field and cost are those of any recurring row: making a crew charge the meter would
## change what the row is for.
static func _poster_crew() -> EventDef:
	var row := EventDraft.new("poster_crew")
	row.look(LookSpec.of(EventDef.Look.POSTER_CREW))
	row.body(BodySpec.solid(GroundShape.point(PERSON_BODY)).walked_through().parked())
	row.from_day(4)
	row.ground([GameEnums.TileType.SIDEWALK])
	row.in_the_lane(EventDef.Pavement.AGAINST_THE_BUILDING)
	row.sited_from_her_walk(true)
	row.field(FieldSpec.of(5.0, 30.0, 110.0))
	row.warning(WarningSpec.lasting(1.0))
	row.drawn(2.5, 12)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a junction box, 0: a box's ground never takes it, though its tiles lie there.
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.0)
	return row.build()

## The same crew, on a square, at a free-standing advertising column (PLAYTEST-107).
##
## **Every number here is `poster_crew`'s on purpose, bar the two that are the split.** The field
## (5.0 over 30-110px), the telegraph, the 11px point body, the first day and the act tag are the
## sidewalk row's, because this is the same event on different ground and a second set of numbers
## would be a second design decision nobody took. What is *not* copied is the sidewalk side: a
## square has no frontage lane to pin a body against.
##
## **The density is split off the sidewalk row rather than added to the catalogue**, and it was
## measured. Planning twelve seeds by one day per act with one row owning both grounds put about one
## poster crew in a hundred on a square (squares being a rare kind of tile), so this row takes one
## percent of the weight and the sidewalk row keeps the rest. The cap is 1 because a hundredth of
## 12 rounds to nothing and a cap of nothing is a deleted row; it never binds, since the roll
## offers this row well under one placement a day. **A square crew is a rare sight**; what the
## split changes is which row draws it, not how often the city does.
static func _poster_crew_square() -> EventDef:
	var row := EventDraft.new("poster_crew_square")
	row.look(LookSpec.of(EventDef.Look.POSTER_CREW_SQUARE))
	row.body(BodySpec.solid(GroundShape.point(PERSON_BODY)).walked_through().parked())
	row.from_day(4)
	row.ground([GameEnums.TileType.SQUARE])
	row.field(FieldSpec.of(5.0, 30.0, 110.0))
	row.warning(WarningSpec.lasting(1.0))
	row.drawn(0.03, 1)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - open ground, 0.39: set by the scaling pass: its share of open ground's events was off by
	#   more than a factor of two.
	row.weighed_on(PlacementGround.Kind.OPEN, 0.39)
	return row.build()

## A mast on a street, with a field around it: six of them, planted by `MastSites` and placed every
## day from `Tuning.MAST_FIRST_DAY` by `DawnMasts` rather than by the ordinary
## catalogue roll. `scripted_day` stays 0, the seal pictures' own sentinel for "a planner places me
## directly, and `EventDef.available_on()` must never roll one" (see the seal table in
## `docs/EVENTS.md`). Its geometry is `homeless_yeller`'s (same inner and outer radius, same
## falloff), so walking straight past a speaking mast on its own sidewalk costs what walking
## past him does; `docs/COSTS.md` carries both rows and they agree by construction rather than by
## tuning.
static func _loudspeaker() -> EventDef:
	var row := EventDraft.new("loudspeaker")
	row.plays(EventDef.Role.MAST)
	row.scripted_on(0, 2)
	row.look(LookSpec.of(EventDef.Look.LOUDSPEAKER_MAST))
	row.body(BodySpec.solid(GroundShape.point(MAST_BODY)).walked_round().parked())
	row.field(FieldSpec.of(20.0, 45.0, 210.0).pulsing_every(22.0))
	row.warning(WarningSpec.lasting(3.0))
	# `DawnMasts` places one at every site `MastSites.compute()` names, which is
	# `Tuning.MAST_COUNT` of them: not a roll's own cap, but the count of the city's sites, which is
	# what `tests/test_events.gd`'s `_test_scheduler_respects_placement_and_caps` reads it as. A day
	# can carry one more: the mast day 11 queued for her task (`EventManager.queue_a_mast()`), which
	# once she silenced it `DawnMasts` plans again from its scar on every later day.
	row.drawn(1.0, Tuning.MAST_COUNT)
	return row.build()

## What the masts carry on `DawnMasts.CURFEW_ANNOUNCE_DAY` on top of their ordinary broadcast:
## `DawnMasts` places one of these at every mast site that morning, alongside
## the mast's own `loudspeaker` instance, which keeps drawing the pole, the lamp and the arcs. This
## row is `Look.NONE` and adds only the field, as a park's own playground frame draws itself while
## `_playground()` merely prices it; the field has the shape of the mast's ordinary one.
## **Stronger than an ordinary broadcast**: intensity half again `_loudspeaker()`'s own.
static func _curfew_announce() -> EventDef:
	var row := EventDraft.new("curfew_announce")
	row.scripted_on(0, 2)
	row.look(LookSpec.none())
	row.body(BodySpec.none().unmet().parked())
	row.field(FieldSpec.of(30.0, 45.0, 210.0).swelling_by(0.2))
	row.lasts(26.0)
	row.warning(WarningSpec.lasting(2.0))
	row.drawn(1.0, Tuning.MAST_COUNT)
	return row.build()

## Holds a street: a concrete band across its own sidewalk and the road, with a guard posted at
## it, so the one way past is the far sidewalk, under the guard's eye.
##
## **Named `roadblock`, not `checkpoint`.** The region door took that word (a hut, a gate and guards
## on the sidewalks you can pass at a price), and this row means something else: a barrier you walk
## round on the far side, never through. Two rows drawing armed men across a street and meaning
## different things cannot share a name, any more than a silhouette.
##
## **Drawn as one continuous barrier, not a row of blocks** (PLAYTEST-55).
## `RoadblockLook._draw_roadblock()` repeats one segment capped by `EventPictures.ROADBLOCK_END`
## through `SpreadLook._draw_spread()`: the broadside `EventPictures.ROADBLOCK_SEGMENT`, or the
## end-on `EventPictures.ROADBLOCK_SEGMENT_VERTICAL` down a north-south column, the rail-with-caps
## construction `roadworks` reads as one thing. `art/events/checkpoint_block.svg` is the badge's own
## icon (`EventPictures.icon_for()`): a badge is read small, and the concrete-block silhouette is
## the clearest single frame of "a street being held".
##
## **Its band covers its own sidewalk and the road, and leaves the far sidewalk whole** ("okay let's
## use the one sidewalk has to be open and match the roadblocks size to one sidewalk + road", inbox
## #1465 in spry-plover). It is placed on a carriageway lane and its body stands on the kerb beside
## that lane (`EventDef.stands_at_its_kerb()`, `CityMap.kerb_beside()`), from where its band
## reaches `ROADBLOCK_REACH` (64px) either way across the street: to the frontage on its own side
## and to the far kerb. So a roadblock on one of her routes' streets leaves her the far sidewalk to
## pass on (`OneSidewalkOpenRule`), baiting the guard away if he hunts.
##
## **Radii measured from the body's spine.** The field is a capsule about the band, so
## outer radius (179) is how far it reaches from the band along the street, the way she comes at
## it. inner radius is 86 and is bounded by nothing: it is where full strength ends and the
## falloff begins, and what the cost table is stated against.
##
## **The `HUNTS` rung `abduction` and `night_raid` climb** (a `HuntSpec` that is not `pressing()`), and **two guards stand
## at the barrier from the moment it is placed**, one on each side of the band and clear of its
## picture. Cold they are drawings and nothing else: no field, no body and no cost of their own,
## all of which belong to the band. Once a heated copy notices her, **the guard on her side** sets
## off from his own post (the other cannot, being blocked) while the other stays standing at his:
## the instance becomes the man, and `PursuitSpec.leaves_its_body_standing()` pins the barrier's body and
## picture where it was built for the rest of the event's life. Nothing appears, nothing
## disappears, and the sidewalk and road he abandoned stay shut behind him.
##
## **His one radius is measured from the band's centre, and he charges on his warning's clock.** The
## radius stays on the band because it may not reach past the field, which is cored there. His post
## is nearer her than the centre, which costs her none of his warning: he charges once it has run
## with her still inside his radius, not at a distance from him
## (`EventInstance.warns_by_radius()`). His stand-off is measured from `lethal_reach()`, his 28px
## catch, the number `Tuning.validate_pursuit()` states the contract over.
##
## **He follows her round a corner.** Once he is after her, where no clear line runs to her he walks
## the way to her round buildings (`PursuitSpec.walks_round_buildings()`, `ChaseWay`), so walking
## straight past his post and turning the next corner is caught as a straight walk is, and luring
## him off stays the way past *(inbox #1534 in velvet-alpaca, "sure, your pick", the pick being that
## he follows her round the corner; inbox #771 in minty-lemur: "it should be in a way that luring
## away the guard is enough")*.
##
## **The catch is a man's reach, not a barrier's.** His catch (the hunt's `LethalSpec.within(MASKED_MAN_REACH)`) is 28px, read off
## `masked_pursuer`: the same fiction, the same distance at which a masked man takes the baby. It is
## separate from inner radius because the field is a street being held, cored on the band, while
## what ends the day is a pair of arms. `EventDef.validate()` has nothing to say about the band's
## body, as about any pursuer's: the man walks out of it before he can kill.
##
## **Intensity 0: the band costs nothing, manned or not, on a day and in the escape alike; the guard
## is the danger** (inbox #788 in minty-lemur). The band is concrete: it shuts its own sidewalk and
## the road with its body and costs nothing to walk beside, while the guard posted at it warns her with his
## raised hand and catches her if she walks on into his charge. A region wall stands as hard seals
## of this row (`RegionPlanner._WALL_DEF_ID`), so a wall's bands cost nothing either; a door's own
## structures (`checkpoint_hut`, `checkpoint_gate`, `checkpoint_post`) keep their rates. The row
## keeps its radii: outer radius is what the hunting guard's notice may not reach past and what the
## `SOON` mark over her is drawn out to. The resistance's checkpoint task ("Don't go around it this
## time. Go through") is priced by the body and by the guard.
##
## **It counts as one barrier (`FieldSpec.as_one_barrier()`), because one street being held is one source however many bodies hold it.**
## A region wall stands three of these a tile apart across a single street beside a region door's
## structures. The band adds nothing to that sum and keeps the flag so the boundary kit stays one
## source by one rule; see `FieldSpec.as_one_barrier()`.
##
## **The 179px cold field sits under the shared hunting trigger**, `EventDef.HEAT_HUNTS_WITHIN` at
## the run's charger reach (225px as shipped). `EventDef.at_heat()` widens only the hunting copy's
## outer radius to `maxf(heard_within(), notice_within())`, the smallest fix that holds for every
## `HUNTS` row, so the cold field is what it was and only the moment the guard starts hunting
## reaches the trigger. `tests/test_heat.gd`'s generic loop
## (`_test_a_hunts_row_wakes_up_at_its_own_threshold`) catches a row whose field sits under the
## trigger; this one is the row that found it.
static func _roadblock() -> EventDef:
	var row := EventDraft.new("roadblock")
	row.look(LookSpec.of(EventDef.Look.ROADBLOCK))
	row.body(BodySpec.solid(GroundShape.band(ROADBLOCK_REACH))
			.walked_round()
			.going_on()
			.as_a_spread())
	# `GOES_ON` and not `PARKS`: his guard leaves his post and gives chase, and `validate()` refuses
	# `PARKS` for a row that chases. The concrete band turns cars by its tiles.
	row.from_day(7)
	row.ground([GameEnums.TileType.ROAD])
	row.field(FieldSpec.of(0.0, 86.0, 179.0).as_one_barrier())
	row.warning(WarningSpec.lasting(1.8))
	# **How his hunting copy pursues** (`HuntSpec.pursuing()`, a catch that ends
	# the day): he catches at a man's reach, taken from `masked_pursuer` since the guard who leaves
	# this post and the masked man are the same figure, and warns at his post with his hand raised
	# (woolly-penguin #748) on the clock every charger that waits for her keeps.
	var chase := PursuitSpec.at(0.0).standing() \
			.warning_for(_chargers.warning()).leaving_its_body().over_the_street().round_buildings()
	row.hunt(HuntSpec.pursuing(chase, LethalSpec.within(MASKED_MAN_REACH)))
	row.spanning_the_street()
	row.drawn(2.0, 6)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a junction box, 0: a box's ground never takes it, though its tiles lie there.
	row.weighed_on(PlacementGround.Kind.JUNCTION, 0.0)
	return row.build()

# --------------------------------------------------------- Act III: vans (8-11) ---


## An unmarked van idles first; that idling IS the telegraph, and it runs long because the inner
## radius ends the day. Getting close does not excite the baby; it takes you.
##
## **And it takes somebody else first.** While she is close enough to watch (outer radius), it
## draws its own bystander walked to it and taken (`EventAbduction`). A scripted figure that belongs
## to the event, never a real `CrowdAgent`: the crowd is recycled as she moves, so a taken
## pedestrian could never be a lasting fact about the world. Drawing and telemetry only; nothing
## here changes `contribution_at()`, spawns a body, or reaches into the crowd.
##
## **The `HUNTS` rung, the lethal rung of the resistance's ladder, hunted on foot**
## (`HuntSpec.letting_out()`). Below `EventDef.HEAT_HUNTS_LEVEL` it is untouched
## (population and intensity are `PRESSES`'s axes). At and above it, the derived copy stops idling
## for a stranger and hunts her with its men: it stays parked and solid, and once she is within
## `EventDef.HEAT_HUNTS_WITHIN` of it along a clear line it lets two men out at its door,
## `out_of_the_car()`'s hunting copy, whose catch ends the day (inbox #669 in coral-lark). The van
## keeps ending the day throughout, so its own 54px still takes her once its telegraph is over, as the
## cold van's does. See `EventDef.at_heat()`.
static func _abduction() -> EventDef:
	var row := EventDraft.new("abduction")
	row.look(LookSpec.of(EventDef.Look.UNMARKED_VAN))
	row.body(BodySpec.solid(GroundShape.point(VEHICLE_BODY)).walked_round().parked())
	row.abduction(AbductionSpec.standard())
	row.from_day(8)
	row.ground([GameEnums.TileType.SIDEWALK, GameEnums.TileType.CROSSING])
	row.field(FieldSpec.of(20.0, 54.0, 250.0))
	row.lasts(34.0)
	# Ending the day doubles the required margin: (250-54)/92 * 2 = 4.26s. It stays this long once the
	# van hunts: the hunting van is still a place she can walk out of, and its 54px takes her only
	# once this telegraph after its notice is over; its men carry their own notice.
	row.warning(WarningSpec.lasting(4.6))
	# A van is a van: 22 + her own 14 leaves the 54 that takes her comfortably reachable, so the
	# body never shields her from the van's own reach. It keeps the body at every heat: hunting, it
	# stays parked and lets its men out (`EventDef.investigates()`), so nothing about a
	# moving wall applies.
	row.lethal(LethalSpec.at_its_core())
	# The caps on the rows that end the day rise with the rest, but by half as much: at one event per block the late
	# city should feel *occupied*, not landmined. Four unmarked vans across forty-nine blocks is one
	# every twelve; twelve would be a difficulty setting nobody asked for.
	row.drawn(2.0, 4)
	row.hunt(HuntSpec.letting_out(2))
	return row.build()

## **A man in an alley who is worth crossing the road for, and who comes after you if you do not.**
##
## **A tiny field on the argument that *the alley itself is the warning* goes nowhere**: a lethal
## radius of 26 inside a field of 42 does nothing until it does everything, which is fatal rather
## than merely dull. And a robber who never moves is avoidable by walking two tiles wide of him for
## ever.
##
## Three numbers for three sentences, in order:
##
## - **On sight.** 16 over a field twenty pixels past his notice (245px as shipped), so the far end
##   of an alley is already expensive and the meter is what tells you he is there, before he has
##   noticed her at all.
## - **Getting close is day ending.** Ending the day inside 26px, and it has to be **reachable**: he
##   carries no body, because a pursuer with one is a moving wall, and because a body that reaches
##   the inner radius means the kill can never fire.
## - **Get close and he comes at you.** `EventDef.notice_within()`, his one radius, 180px at the
##   run's charger reach (225px as shipped): inside that he stands up, turns to face her and walks
##   at her slowly, at 40px/s (`PursuitSpec.walk_speed()`), holding at his 116px stand-off, for his
##   warning (`CHARGER_WARNING`, `PursuitSpec.warns_for()`; inbox #788 in minty-lemur), and if she
##   is still inside his radius once it has run he lunges, and chases at 130px/s until she has
##   shaken him off. **Turning round from his warning is an answer**: she outwalks his slow walk,
##   and once she is outside his radius he stops where he is and waits there (inbox #764 in
##   minty-lemur). Once he has lunged, walking away does not work and running away does, which is
##   `charging_dog`'s contract arriving in act III as a *place* rather than a moment.
##
## The alley is the warning, and it is not the only one.
static func _alley_robbery() -> EventDef:
	var row := EventDraft.new("alley_robbery")
	row.look(LookSpec.of(EventDef.Look.ROBBER)
			.warning_as(LookSpec.WarningPicture.ROBBER_ALERT))
	row.body(BodySpec.footprint(GroundShape.point(9.0)).walked_through().going_on())
	row.from_day(8)
	row.ground([GameEnums.TileType.ALLEY])
	# **The lunge is further out than the catch**: 38px + 130px/s × `PURSUIT_REACTION` = 116px,
	# while the catch is 26px. The stand-off is stated over `PursuitSpec.lunge_reach()` rather than
	# the catch, so the room between his lunge and his catch is 116 − 26 = 90px rather than the 78
	# it would be if the lunge followed the catch (inbox #526 in azure-tapir: keep every rule at
	# 116px). The rule kept beside the 116px, that standing still he lunges no sooner than
	# `Tuning.PURSUIT_MIN_NOTICE` after he appears, is a standing robber's; the sent robber the
	# resistance's trap reads off this row arrives already chasing (`_robber_giving_chase()`), so
	# it has no closing-in for the floor to bound. Wider than the trigger, which is the contract
	# rather than a taste: he may not notice her from outside his own field, because the meter is
	# the only thing that says a stranger in an alley is worth crossing the road for. The twenty
	# pixels between this and his notice are the row's first sentence, **on sight**, with
	# somewhere to happen, and his slow walk is its second; they grow with his notice
	# (`ChargerTiming.field_reach()`).
	var written := _robber_field()
	row.field(written.reaching(_chargers.field_reach(written.heard_within(), 180.0)))
	# Read only by the pursuit contract's notice clause (`Tuning.validate_pursuit()`): no robber's
	# notice runs on it. One who notices her by sight warns for his `PursuitSpec.warns_for()`
	# (`EventInstance.warns_by_radius()`), and day 13's guard set on her by the task has the task's
	# own second (`EventInstance.notice_her_at()`,
	# `ResistanceDirector._set_the_task_guard_on_her()`).
	row.warning(WarningSpec.lasting(1.8))
	row.lasts(Tuning.PURSUIT_TIME)
	# The same speed as the charging dog, deliberately: a player who learned on day 3 what a thing
	# that comes after you moves like should not have to learn it again in act III.
	row.pursuit(PursuitSpec.at(130.0).lunging_from(38.0)
			# **He walks at her slowly through his notice**, a man getting up off a wall rather than
			# a man already running: his chase is 130px/s, and closing at that from his trigger would
			# be over in a tenth of a second. At 40px/s, a little over the dog walker's 32px/s
			# stroll, a stride beat (`EventLook.gait_is_stepping()`, 17.5px of ground) lasts about
			# 0.44s, near the 450ms the walkers' two-frame pictures were reviewed at.
			.walking_at(40.0)
			# **He charges once his warning has run with her still inside his radius**, on the
			# clock every charger that waits for her keeps (inbox #788 in minty-lemur), walking at
			# her and holding at his stand-off while he warns.
			.warning_for(_chargers.warning()))
	# Outside his stand-off (116px) and inside his field, which leaves room for both halves of the
	# row: far enough out that his notice walk is seen, near enough that she has felt him before he
	# decides anything about her (inbox #761 in minty-lemur). Written 180px and drawn at the run's
	# charger reach (`ChargerTiming.notice()`, 225px as shipped), as every charger's is
	# (curly-moose #803): 109px past his stand-off at the slow walk below is under a second of him
	# walking for a walker coming in (109 / (40 + 92)) and 2.7s for one who stops at the edge; he
	# notices her only once his warning would stand in her view
	# (`EventInstance._would_stand_in_her_view()`). That is his one radius: he charges if she is
	# still inside it once his warning has run (`PursuitSpec.warns_for()`, below). The resistance
	# sites a chalk mark's guard and day 13's task guard, who are this row, from the radius drawn
	# (`ResistanceDirector._guard_position()`).
	#
	# The trap: with a chase that ends at a *distance*, a trigger at or past that distance is a
	# pursuit that loses interest the instant it starts, and she can stroll away from him every
	# time. `Tuning.PURSUIT_SHAKEN_OFF` ends a chase at a rate instead, so no trigger distance can
	# reproduce it.
	row.notice(NoticeSpec.at(_chargers.notice(180.0)))
	# And he walks off when he has lost her, rather than being deleted where he stood.
	row.leaves_at(100.0)
	row.lethal(LethalSpec.at_its_core())
	row.drawn(1.5, 4)
	return row.build()

## **The robber a task sets on her: the alley robber, awake from his first frame, coming at her
## from off screen the moment she has done a task.** Every task but the van's, the roadblock's and
## the neighbor's sends him (`ResistanceDirector._sets_a_trap_on_her()`): the man shouting's note,
## the burnt building's door, the district door, a mast's foot, the swing and the last night's front
## door. Nothing places it but `ResistanceDirector._set_the_trap_on_her()`: `SCRIPTED` on day 0, the
## day nobody plays, so the roll, the stream and the bags never reach it; `EventDef.validate()`
## refuses a pursuer with no trigger on any other terms.
##
## **Warned first** (`WarningSpec.warned_first()`): the screen-edge badge is up alone, with nothing in the world,
## for the dog's half second (`WarningSpec.badged_for()`), pointing where he will come from, and he is then
## created just off screen that way (`PendingWarning`), above or below her by preference.
## **And he arrives already chasing** (`PursuitSpec.Start.ARRIVES_CHASING`): no closing-in to a
## stand-off and no telegraph to spend (the proximity rule is only for standing robbers).
##
## **The same man, read off `_alley_robbery()` rather than copied beside it**: his body, his field
## (16 over 26–200px), his 130px/s, his 26px catch and the 116px lunge (`PursuitSpec.lunge_reach()`),
## his catch that ends the day and the way he walks off once he has lost her. What differs is **no trigger**
## (`EventDef.notice_within()` 0), so he is never `is_waiting()`, and his timing: the day-3
## dog's badge and chase, read off `_charging_dog()`. His chase does not give up on a walker
## (`Tuning.PURSUIT_TIME`, a long cap); running for `Tuning.PURSUIT_SHAKEN_OFF` (0.35s) shakes
## him off, including while he is still offscreen.
##
## What that leaves her, from just off screen above her (`tests/probes/m207_warning_lead.gd`'s gold
## timing, counted from the badge): standing still he catches her at about 1.8s, walking into him at
## about 1.3s, walking straight away at about 5.0s (about 8.9s from beside her, where the view is
## wide); running away the moment she is warned, he gives up within a second. After the note, the man
## she just left also keeps shouting, and charging her, for
## `ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS` (2.5s) after the handover, so his field is
## still live while the robber comes whichever way she answers. Whether shouting-plus-chasing at
## once is more than a walker should answer is
## `docs/review/2026-09-25-hand-a-note-to-the-man.md`'s question, not settled here.
##
## **The alley robber's field as written**: 16 over a 26 to 200px field, around his written 180px
## notice. The waiting robber draws its outer edge at the run's charger reach
## (`ChargerTiming.field_reach()`); every man sent at her charging keeps it as written.
static func _robber_field() -> FieldSpec:
	return FieldSpec.of(16.0, 26.0, 200.0)

## **His own look, `ROBBER_GIVING_CHASE`, drawing the alley robber's own pictures**, as `door_guard`
## draws a roadblock's guard: he never waits, so it is only ever the lunge, and the badge is the one
## view of it `ROBBER` does not already stand for.
static func _robber_giving_chase() -> EventDef:
	var alley := _alley_robbery()
	var row := EventDraft.new("robber_giving_chase")
	row.scripted_on(0, 2)
	row.look(LookSpec.of(EventDef.Look.ROBBER_GIVING_CHASE))
	row.body(BodySpec.footprint(alley.ground_shape()).walked_through().going_on())
	# The waiting robber's field as written, never as the run's charger reach draws it: the twenty
	# pixels it keeps past his notice are for a man who waits for her, and this one arrives already
	# charging, with no notice to feel him before. The charger timing moves notices and warnings
	# (curly-moose #803); his cost moves only on the player's word (inbox #1278 in olive-ferret).
	row.field(_robber_field())
	# The day-3 dog's own timing, read off its row: its badge alone, its approach and its chase.
	var dog := _charging_dog()
	row.warning(WarningSpec.lasting(0.0)
			.warned_first()
			.badged_for(dog.warning().badge_notice()))
	# No telegraph: he arrives already chasing.
	row.lasts(dog.lasts_for())
	row.pursuit(PursuitSpec.at(alley.pursuit().speed()).starting_by(PursuitSpec.Start.ARRIVES_CHASING)
			.lunging_from(alley.pursuit().lunge_reach()))
	row.leaves_at(alley.departure_speed())
	row.lethal(alley.lethal())
	return row.build()

## **The guard a task sets on her: the roadblock's own guard, awake from his first frame, coming at
## her from off screen the moment she hands the van's package over** (PLAYTEST-144 15). Nothing
## places it but `ResistanceDirector._set_the_trap_on_her()`, on the same terms as
## `robber_giving_chase`: warned first, then created just out of sight of her on walkable ground,
## `SCRIPTED` on day 0 so the roll, the stream and the bags never reach it.
##
## **The door guard, read off his row rather than copied**: his shape, his field (18 over a
## 28–120px band: `MASKED_MAN_REACH` inside `door_guard`'s own 120px), his catch that ends the day, and
## `Tuning.HEAT_HUNTS_SPEED` (130px/s), the figure `_alley_robbery()` hardcodes as the robber's own
## `PursuitSpec.speed()`, so nothing about the chase differs from the robber row. What differs from
## `robber_giving_chase` is the picture, `EventDef.Look.VAN_GUARD_GIVING_CHASE`, drawn like
## `door_guard` and `masked_pursuer` (`guard_standing_*` then `guard_lunging_*`) but badged by the
## lunge's back view, the one picture of the man neither of theirs stands for; and the walk-off,
## copied from the robber row: `door_guard` never leaves his post, but this guard, like the robber,
## is a stranger in the street with nowhere to be once he has lost her, so he walks off at the
## robber's own 100px/s.
##
##
## **No trigger, and the robber row's own timing**: `EventDef.notice_within()` stays 0.0, so he
## is never `is_waiting()`; he is warned first for the dog's half second, arrives already
## chasing (`PursuitSpec.Start.ARRIVES_CHASING`) and does not give up on a walker
## (`Tuning.PURSUIT_TIME`), identical to `robber_giving_chase`, since nothing about the timing
## is the picture's to change.
static func _van_guard_giving_chase() -> EventDef:
	var guard := _door_guard()
	var alley := _alley_robbery()
	var row := EventDraft.new("van_guard_giving_chase")
	row.scripted_on(0, 2)
	row.look(LookSpec.of(EventDef.Look.VAN_GUARD_GIVING_CHASE))
	row.body(BodySpec.footprint(guard.ground_shape()).walked_through().going_on())
	row.field(guard.field())
	# The day-3 dog's own timing, read off its row, as the robber's is.
	var dog := _charging_dog()
	row.warning(WarningSpec.lasting(0.0)
			.warned_first()
			.badged_for(dog.warning().badge_notice()))
	# No telegraph: he arrives already chasing.
	row.lasts(dog.lasts_for())
	row.pursuit(PursuitSpec.at(guard.pursuit().speed()).starting_by(PursuitSpec.Start.ARRIVES_CHASING))
	row.leaves_at(alley.departure_speed())
	row.lethal(guard.lethal())
	return row.build()

# ------------------------------------------------------- the pursuer on foot ---

## **A torn poster's pursuer: a policeman on foot, coming at her from off screen the moment the
## tear draws its pursuit marble** (inbox #591 in olive-hedgehog). Nothing places it but
## `EventManager.send_a_pursuer()`: `SCRIPTED` on day 0, the day nobody plays, so the roll, the
## day's queue, its stream and its bags never reach it.
##
## **The robber a task sends, in a policeman's coat**: every number read off
## `_robber_giving_chase()` (his field, his 130px/s, his 26px catch and 116px lunge, the dog's
## half-second badge, arriving already chasing with no closing in, a chase that does not give up on
## a walker within `Tuning.PURSUIT_TIME` and that running shakes off). **His catch ends the day**
## (merry-stork). What differs is the picture, `EventDef.Look.POLICEMAN_GIVING_CHASE`
## (`art/events/policeman_*`, the robber's set one for one), and his line when he catches her.
##
## **Through day 8 only**: from day 9 the same pursuit is a guardsman (`_guardsman_giving_chase()`,
## `on_foot_on()`).
static func _policeman_giving_chase() -> EventDef:
	var robber := _robber_giving_chase()
	var draft := robber.redraft()
	draft.body(robber.body().walked_through().going_on())
	draft.known_as("policeman_giving_chase")
	draft.look(LookSpec.of(EventDef.Look.POLICEMAN_GIVING_CHASE))
	draft.counted_as("policeman", "policemen")
	return draft.build()

## **The same pursuer from day 9, once guards are in the city** (inbox #591 in olive-hedgehog): the
## checkpoint guard's own drawing, `EventDef.Look.GUARDSMAN_GIVING_CHASE`, drawn as `door_guard` is
## drawn. Every number is the policeman's (the robber's) rather than the van guard's, since he
## replaces the policeman on the same errand and nothing about the chase is the picture's to
## change.
static func _guardsman_giving_chase() -> EventDef:
	var policeman := _policeman_giving_chase()
	var draft := policeman.redraft()
	draft.known_as("guardsman_giving_chase")
	draft.look(LookSpec.of(EventDef.Look.GUARDSMAN_GIVING_CHASE))
	draft.body(policeman.body().walked_through().going_on())
	draft.counted_as("guardsman", "guardsmen")
	return draft.build()

## The pursuer on foot on the walk `spec` describes: the policeman until the region wall stands, the
## guardsman once it does (`DaySpec.region_wall_stands()`, from day 9 on a day's, never in the
## escape).
static func on_foot_on(spec: DaySpec) -> EventDef:
	return by_id("guardsman_giving_chase" if spec.region_wall_stands()
			else "policeman_giving_chase")

## Derived copies of the pursuer on foot, as he gets out of a vehicle, keyed by his row's id and
## whether his catch is a stop. See `out_of_the_car()`.
static var _out_of_the_car: Dictionary[String, EventDef] = {}

## **The man an investigating vehicle lets out** (`EventDef.investigates()`): the patrol car's one,
## the hunting raid's and unmarked van's two. The day's pursuer on foot (`on_foot_on()`, a policeman
## through day 8, a guardsman from day 9), his own row, getting out at the vehicle's door in her
## view (merry-stork; inbox #669 in coral-lark).
##
## **Out of the patrol car (`stops`), his catch is a stop, not the end of the day**
## (`PursuitSpec.stop_excitement()`, `OFFICER_STOP_EXCITEMENT`): when he reaches her he stops, his
## field lands a substantial cost on her, and he and every man his vehicle let out walk back to it.
## **Out of a hunting van his catch ends the day**, as the van's own hunt did (the unmarked van's
## men keep its lethality), and he walks back to it only once he has given up or run out his chase.
##
## **In view, so not the badge: he stands beside her with his hand raised, and then he charges**
## (inbox #764 in minty-lemur). He is not warned of before he exists and does not arrive chasing;
## he gets out with the sole purpose of charging her, beside her
## (`PursuitSpec.Start.SETS_OFF_BESIDE_HER`), so he charges whatever she does, and first shows that
## he is about to: he stands where he got out in his alert pose (`PursuitSpec.stands_for_its_notice()`) for
## `Tuning.WARNING_ALONE_MAX`, the second an off-screen charger's badge is up alone, his lunge never
## firing early, and then he chases under the pursuit contract (`Tuning.validate_pursuit()`, which
## `all()` holds this copy to on load). Every other number is his own row's.
##
## A derived copy rather than a catalogue row, as a heated row is: the same man, met another way.
static func out_of_the_car(spec: DaySpec, stops := true) -> EventDef:
	return _out_of(on_foot_on(spec), stops)

## The man `out_of_the_car()` describes, made from the pursuer on foot `on_foot`.
static func _out_of(on_foot: EventDef, stops: bool) -> EventDef:
	var key := on_foot.id() + (":stops" if stops else ":hunts")
	if not _out_of_the_car.has(key):
		var draft := on_foot.redraft()
		draft.warning(WarningSpec.lasting(Tuning.WARNING_ALONE_MAX))
		var chase := on_foot.pursuit().starting_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER).standing()
		if stops:
			draft.lethal(LethalSpec.none())
			chase = chase.stopping_her_for(OFFICER_STOP_EXCITEMENT)
		draft.pursuit(chase)
		_out_of_the_car[key] = draft.build()
	return _out_of_the_car[key]

## **Day 13's task guard, sent at her from out of her view**
## (`ResistanceDirector._set_the_task_guard_on_her()`): the robber a task sends
## (`_robber_giving_chase()`), the same man the waiting guard is drawn as, warned of by the
## screen-edge badge alone for `Tuning.WARNING_ALONE_MAX` rather than the day-3 dog's half second
## (a second on screen and a second off if they were not visible; inbox #764 in minty-lemur), then
## arriving charging. A derived copy, built once, under an id of its own, `task_guard_sent`, so
## GoatCounter tells him apart from the robber a task sends (inbox #849 in minty-dolphin); his
## charges count as the task guard's (`EventDef.charges_counted_as()`).
static func task_guard_sent() -> EventDef:
	if _task_guard_sent == null:
		var sent := _robber_giving_chase()
		var draft := sent.redraft()
		draft.known_as("task_guard_sent")
		draft.warning(sent.warning().badged_for(Tuning.WARNING_ALONE_MAX))
		draft.charges_counted_as("task_guard")
		_task_guard_sent = draft.build()
	return _task_guard_sent

static var _task_guard_sent: EventDef = null


## A building goes in the night. Enormous, static, and it closes the block.
##
## **The `HUNTS` rung `abduction` climbs, but it hunts on foot** (`HuntSpec.letting_out()`). Below
## `EventDef.HEAT_HUNTS_LEVEL` it is untouched: a closed block and nothing more. At and above it,
## the derived copy `investigates`: the van stays where it stands, and the moment she is within
## `EventDef.HEAT_HUNTS_WITHIN` (at the run's charger reach, 225px as shipped) of it along a clear
## line it lets two men out at its door on her side, who pursue her under the pursuit contract
## (`EventCatalogue.out_of_the_car()`'s hunting copy, a guardsman on day 10) and whose catch ends
## the day (inbox #669 in coral-lark). Men who give up or run out their chase walk back to the van,
## which stands over its block for the rest of the day. The van itself never ends the day, cold or
## hot. See `EventDef.at_heat()`.
##
## **It shares the patrol-and-van threshold rather than minting a third constant, and the calendar
## is why that is load-bearing.** The resistance's tasks before it fall on days 6 to 9, so on day
## 10, the only day this row ever appears, the most progress anybody can hold is four, which is
## `HEAT_HUNTS_LEVEL`: sharing it makes the raid hunt *only* a player who has done every task on
## time, and a player one task behind meets the cold raid instead.
##
## **The raid at her own building is this row as well**, spawned by `ResistanceHappenings` on the
## far sidewalk of her street and always cold (`ResistanceHappenings._maybe_raid()`).
##
## **Solid at every heat**: `obstructs_within()` 44, half its drawn width. The van never moves, so the
## rule that takes a pursuer's body away (a moving wall pins her) never reaches it, and its men get
## out beside that body (`EventInstance.where_its_officer_may_get_out()`).
static func _night_raid() -> EventDef:
	var row := EventDraft.new("night_raid")
	row.scripted_on(10, 3)
	row.look(LookSpec.of(EventDef.Look.RIOT_VAN))
	row.body(BodySpec.solid(GroundShape.point(44.0)).walked_round().parked())
	row.ground([GameEnums.TileType.SIDEWALK])
	row.field(FieldSpec.of(24.0, 70.0, 330.0).pulsing_every(6.0))
	row.warning(WarningSpec.lasting(3.0))
	row.hunt(HuntSpec.letting_out(2))
	return row.build()

# ------------------------------------------------------------ Act IV: open (12+) ---

## An army truck down its street and off again, leaving nothing behind: nothing a convoy does
## during the walk closes a street (inbox #1183 in gentle-owl).
##
## **From day 13, the morning the army arrives** (PLAYTEST-122), with the column on the main road
## that day (`ResistanceHappenings`); day 12 is the parks.
static func _military_convoy() -> EventDef:
	var row := EventDraft.new("military_convoy")
	row.look(LookSpec.of(EventDef.Look.ARMY_TRUCK))
	row.body(BodySpec.footprint(GroundShape.point(26.0)).walked_round().going_on())
	row.from_day(13)
	row.ground([GameEnums.TileType.ROAD])
	row.field(FieldSpec.of(22.0, 76.0, 300.0))
	# As a place the day planned, faster than a walk, so the escape distance is the forward reach:
	# `outer radius · Field.scale(e)` at 120px/s (e = 0.24) is 395px, 4.29s, plus the row's margin.
	# Day 13's column is this row warned first (`EventSpawner.as_warned()`): that copy's badge alone
	# is cut to `Tuning.WARNING_ALONE_MAX`, and it is held to the flat
	# `Tuning.OFFSCREEN_WARNING_MIN`.
	row.warning(WarningSpec.lasting(4.43))
	row.route(RouteSpec.at(120.0, RouteSpec.Kind.ALONG_STREET).up_to_tiles(50))
	# **Sent ahead of her on an ordinary day** (`EventDraft.sent_ahead()`; inbox #1460 in
	# silky-lemur, "the same for [...] the convoy"; "just spawn in the car just ahead of the
	# player"): warned of first, its badge alone for a second, then created in the lane beside
	# her just out of sight up the road ahead of her, as day 13's column is. The escape's trucks
	# are this row too, handed to the director by its plan (`DaySpec.hands_the_director()`).
	row.sent_ahead(SentAhead.warned_first())
	row.drawn(2.0, 1)
	return row.build()

## The widest hard seal: placed every morning from act IV on across a street off the day's route
## tree (`SealPlanner`'s `barricade_seal`, and the escape's `finale_barricade`).
##
## **Silent**: this is the widest hard seal in the game (`obstructs_within()` 62, the whole street),
## so its route cost is already the largest in the catalogue; an ambient field on top would bill
## nothing she could see past the wall itself.
static func _barricade() -> EventDef:
	var row := EventDraft.new("barricade")
	row.scripted_on(0, 4)
	row.look(LookSpec.of(EventDef.Look.BARRICADE))
	row.body(BodySpec.solid(GroundShape.band(62.0)).walked_round().parked().as_a_spread())
	row.field(FieldSpec.of(0.0, 40.0, 120.0))
	row.warning(WarningSpec.lasting(0.9))
	row.aftermath(Aftermath.none().scarring("barricade"))
	return row.build()

## Grows while it is there: swell takes it to 1.9x over its duration. A protest you could
## have walked past when you saw it is not one you can walk past two minutes later.
##
## **Radii derived from the body.** The field is a capsule about the body's spine, so the radii are
## the along-axis reach less the segment's own `half_length` (31, from `band(55)`): inner radius
## 39 and outer radius 269. The 39px still clears the body's own 24px rounding, so neither clamps.
##
## **Intensity 19.5, because the walking decay takes more off this row than off any other.** A wide
## field at a moderate rate loses far more of its price to a decay netted off over the whole
## crossing than a narrow fierce one does (the **balance** skill's own example, and this is the row
## it is stated about). 19.5 is as loud as it can be made while staying under the wall line below.
##
## **19.9 is where it stops, and the margin is thin on purpose.** At that rate
## `walk_through_cost()` crosses `EventScheduler.WALL_WORTH_OF_COST` and `EventScheduler.role_for`
## reclassifies the row as a `WALL`, which would pull it off every route the day carries; a protest
## is where a resistance task sends her ("Stand where they're standing", `ResistanceSteps`), so a
## protest off the corridor is a task she cannot reach. `docs/COSTS.md` carries where it actually
## sits; `tests/test_events.gd` holds the relationship rather than the number.
static func _protest() -> EventDef:
	var row := EventDraft.new("protest")
	row.look(LookSpec.of(EventDef.Look.PROTEST))
	row.body(BodySpec.solid(GroundShape.band(55.0))
			.walked_through()
			.parked()
			.along_its_street())
	row.from_day(12)
	row.ground([GameEnums.TileType.SQUARE, GameEnums.TileType.CROSSING])
	row.field(FieldSpec.of(19.5, 39.0, 269.0).pulsing_every(8.0).swelling_by(1.9))
	row.lasts(150.0)
	row.warning(WarningSpec.lasting(2.6))
	# The clearest case in the catalogue of the picture deciding a gameplay number: a body may not
	# claim ground the drawing does not (`SpreadLook._draw_spread`'s rule in the other direction),
	# so a protest drawn as one man obstructs one man's width however much of a square it is
	# supposed to fill. `RankLook._draw_protest` draws two ranks across exactly this width.
	#
	# Under the 39px inner radius on purpose: the loudest part of a protest is something you stand
	# in rather than bump into, and being stopped at the edge of it would take the choice of how
	# close to cut past away from the player.
	# A wall row, capped with the rest of them. Act IV only, so this is the late city's share of the
	# blocking events that make the ground off the paths expensive. A protester obstructs nothing
	# and pursues nothing, so this cap has no other cap to compete with, and this row's own cap is
	# what binds where the bags would draw more.
	row.drawn(2.5, 12)
	# **Its weight on a kind of ground** (`EventDraft.weighed_on()`; `docs/EVENTS.md`, "The
	# density, and why it is a declared table"):
	# - a junction box, 2.8: set by the scaling pass: its share of a junction box's events was
	#   off by more than a factor of two.
	# - open ground, 0.074: rare on open ground, where the street musician is nine tenths of
	#   what stands: its share there against his.
	row.weighed_on(PlacementGround.Kind.JUNCTION, 2.8)
	row.weighed_on(PlacementGround.Kind.OPEN, 0.074)
	return row.build()

## The last thing in the catalogue and the worst. Static, extreme, lethal at the centre, and it
## shuts a district.
##
## **Radii derived from the body, and inner radius here is the lethal one.** Both lose the
## segment's own `half_length` (6, from `band(30)`) so the along-axis reach, including the lethal
## one (a plain circle of inner radius about the centre, not capsule-shaped), is unchanged:
## inner radius 90 → 84, outer radius 380 → 374. `(outer − inner)` is invariant under
## subtracting the same term from both, so the telegraph arithmetic is untouched.
static func _firefight() -> EventDef:
	var row := EventDraft.new("firefight")
	row.scripted_on(13, 4)
	row.look(LookSpec.of(EventDef.Look.FIREFIGHT))
	row.body(BodySpec.solid(GroundShape.band(30.0))
			.walked_through()
			.parked()
			.along_its_street())
	row.ground([GameEnums.TileType.CROSSING, GameEnums.TileType.SQUARE])
	row.field(FieldSpec.of(30.0, 84.0, 374.0).pulsing_every(2.5))
	# Ends the day: (374-84)/92 * 2 = 6.3s.
	row.warning(WarningSpec.lasting(6.5))
	# The 30px band the two gunmen are drawn across (`RankLook._draw_firefight()` stands
	# them at 0.62 of it either side), and far inside the 84 that ends the day.
	row.lethal(LethalSpec.at_its_core())
	return row.build()

# --------------------------------------------------------------- seal pictures ---
# Every row below exists only as `SealPlanner` candidate material (`docs/DECISIONS.md`, "Eight
# seal pictures, so that no single barrier becomes the city's signature."). Each is `SCRIPTED` on
# day 0, a day nobody plays, so `EventDef.available_on()` never rolls one and the
# ordinary scheduler never sites one, the shape `barricade` uses to keep out of the day's own bags.
# `EventDef.own_first_day()` reads the act each is scripted with instead, so the act is what gates
# the day a seal may use the row.
#
# **Silent, like every other seal candidate**: each carries `intensity = 0.0`. Radii still have to
# satisfy `EventDef.validate()` even at zero intensity, so every row below copies `barricade`'s
# geometry (inner 40, outer 120, telegraph 0.9) rather than inventing one nothing reads.

## A hard seal: a tree down kerb to kerb, root plate at one end and crown at the other.
## `obstructs_within()` 96 is exactly half the 192px street, so `SealPlanner._hard_positions` places a
## single copy spanning it edge to edge, and `fallen_tree.svg` is authored wider than that so
## `SpreadLook._draw_spread` draws that one copy rather than repeating a tree across the street.
static func _fallen_tree() -> EventDef:
	var row := EventDraft.new("fallen_tree")
	row.scripted_on(0, 1)
	row.look(LookSpec.of(EventDef.Look.FALLEN_TREE))
	row.body(BodySpec.solid(GroundShape.band(96.0)).walked_round().parked().as_a_spread())
	row.field(FieldSpec.of(0.0, 40.0, 120.0))
	row.warning(WarningSpec.lasting(0.9))
	return row.build()

## A hard seal: two cars locked together across the carriageway, debris between them and an
## onlooker on each sidewalk. Same single-copy geometry as `fallen_tree`: one continuous scene
## rather than a repeated segment. Smoke puffs up off the wreck over two frames
## (`EventPictures.CAR_ACCIDENT_B` and its vertical sibling) that stand on the same contacts, so the
## parts below hold for both.
##
## **The one seal that is solid only in parts, and the one that emits** (PLAYTEST-63). Its shape is
## the whole-street band: what the picture is fitted to, what the field is stated over, and the disc
## every planner clears the street by. `BodySpec.in_pieces()` puts a body under each car and leaves the debris
## and the two sidewalks open. The price of walking through one of those gaps is the field, not a
## wall: see `CAR_ACCIDENT_INTENSITY`, which overturns *a closure is silent* for this row alone
## (`docs/CITY.md`, "A closure is silent").
##
## **The field is stated over the band and not over the cars.** inner radius is
## `GroundShape.BAND_RADIUS`, the band's own surface (a segment's field is priced from its spine),
## so everything inside the scene's footprint is charged at the full rate, gaps included, and the
## shoulder outside it is short: 72px, under half a street's width, so the crash is felt walking up
## to it rather than from down the street. A sealed street still has to be discoverable by walking
## into it, the reason closures are silent in the first place.
static func _car_accident() -> EventDef:
	var row := EventDraft.new("car_accident")
	row.scripted_on(0, 1)
	row.look(LookSpec.of(EventDef.Look.CAR_ACCIDENT))
	row.body(BodySpec.solid(GroundShape.band(96.0))
			.in_pieces(_car_accident_parts())
			.walked_round()
			.parked()
			.as_a_spread())
	var gaps := FieldSpec.of(CAR_ACCIDENT_INTENSITY, GroundShape.BAND_RADIUS, 96.0)
	row.field(gaps)
	row.warning(WarningSpec.lasting(0.9))
	if CAR_ACCIDENT_GAPS_ARE_LETHAL:
		# The other answer to *prevents*, off by default (see the constant). The lethal radius has to
		# clear the cars' own bodies with her 14px to spare or the kill can never fire
		# (`EventDef.validate()`), and the telegraph has to buy the walk out of the doubled margin.
		row.lethal(LethalSpec.at_its_core())
		row.field(gaps.holding_to(CAR_ACCIDENT_LETHAL_INNER_RADIUS))
		row.warning(WarningSpec.lasting(1.2))
	return row.build()

## Where the two cars stand, read off the two authored pictures at the scale
## `SpreadLook._draw_wide_scene` fits each to the street: 192px of street over a 200px picture, so a
## pixel of art is 0.96px of ground and the picture's centre is the scene's centre.
##
## `car_accident.svg` (north-south street): the cars are drawn at x 63–91 and 92–120, and
## `car_accident_shadow.svg` puts their ground contacts at 77 and 106, which agree (an end-on car is
## drawn directly above its own patch of road). That is −22.1px and +5.8px from the centre.
##
## `car_accident_vertical.svg` (east-west street): the cars are side views, so their drawn bodies sit
## **above** the road they stand on and only the shadow art says where that is: contacts at y 88 and
## 110, which is −11.5px and +9.6px from the centre.
##
## 14px of radius apiece: a car is drawn 28px wide, 26.9px of ground at this scale, and the round
## number makes the two bodies meet rather than leaving a one-pixel slot between them on the
## north-south picture. Debris and onlookers carry no body: they are what the gaps are.
static func _car_accident_parts() -> Array[BodyPiece]:
	return [
		BodyPiece.at(-22.1, -11.5, GroundShape.point(14.0)),
		BodyPiece.at(5.8, 9.6, GroundShape.point(14.0)),
	] as Array[BodyPiece]

## Half of a soft seal: a skip at the kerb, facing `scaffolding` on the other sidewalk. Kerb-pinned
## like `delivery_van`, so `BodyStance._centred_on_the_pavement_band` leaves it exactly where
## `SealPlanner._place_soft` puts it rather than spreading it across the whole band.
static func _skip() -> EventDef:
	var row := EventDraft.new("skip")
	row.scripted_on(0, 1)
	row.look(LookSpec.of(EventDef.Look.SKIP))
	row.body(BodySpec.solid(GroundShape.point(VEHICLE_BODY)).walked_round().parked())
	row.in_the_lane(EventDef.Pavement.AT_THE_KERB)
	row.field(FieldSpec.of(0.0, 40.0, 120.0))
	row.warning(WarningSpec.lasting(0.9))
	return row.build()

## The other half of the same soft seal: boards over the far footway. `pavement_side` stays `ANY`
## so the auto-centring `construction` uses fills the whole 64px band.
static func _scaffolding() -> EventDef:
	var row := EventDraft.new("scaffolding")
	row.scripted_on(0, 1)
	row.look(LookSpec.of(EventDef.Look.SCAFFOLDING))
	row.body(BodySpec.solid(GroundShape.band(SIDEWALK_SPREAD_MAX))
			.walked_round()
			.parked()
			.as_a_spread())
	row.field(FieldSpec.of(0.0, 40.0, 120.0))
	row.warning(WarningSpec.lasting(0.9))
	return row.build()

## A hard seal: a crater with water across the asphalt and a municipal barrier at each kerb, "the
## one that explains why the road is out too" (`docs/DECISIONS.md`, "Eight seal pictures").
## Single-copy geometry, as `fallen_tree` and `car_accident`. The fountain surges and splashes over
## two frames (`EventPictures.BURST_MAIN_B` and its vertical sibling), so the water reads as water.
static func _burst_water_main() -> EventDef:
	var row := EventDraft.new("burst_water_main")
	row.scripted_on(0, 1)
	# The crater is sunk into the road, not standing above it, so the body and the barriers keep
	# their ordinary geometry and only the shadow patch is refused (its look casts none).
	row.look(LookSpec.of(EventDef.Look.BURST_MAIN).casting_no_shadow())
	row.body(BodySpec.solid(GroundShape.band(96.0)).walked_round().parked().as_a_spread())
	row.field(FieldSpec.of(0.0, 40.0, 120.0))
	row.warning(WarningSpec.lasting(0.9))
	return row.build()

## A soft seal, both bodies the same row: a moving van with its ramp down on each sidewalk, the
## lorry-scale silhouette family ("reuses `Look.LORRY`, the biggest silhouette in act I",
## `docs/DECISIONS.md`, "Eight seal pictures") rather than the literal `Look.LORRY` value, since
## two rows may not share a look or a silhouette (`docs/EVENTS.md`, "the visual vocabulary";
## `tests/test_events.gd`'s `_test_no_two_rows_draw_the_same_picture` and
## `_test_every_look_carries_its_own_silhouette`). `moving_van.svg` is drawn at the scale of
## `lorry.svg` with its own picture: open doors and a ramp reaching the ground.
static func _moving_van() -> EventDef:
	var row := EventDraft.new("moving_van")
	row.scripted_on(0, 1)
	row.look(LookSpec.of(EventDef.Look.MOVING_VAN))
	row.body(BodySpec.solid(GroundShape.band(28.0)).walked_round().parked())
	row.in_the_lane(EventDef.Pavement.AT_THE_KERB)
	row.field(FieldSpec.of(0.0, 40.0, 120.0))
	row.warning(WarningSpec.lasting(0.9))
	# Over `GroundShape.BAND_RADIUS`, so it is the one stationary-vehicle row whose shape is a
	# segment rather than a point — see `EventInstance.solid_axis()`.
	return row.build()

## A hard seal, acts II-IV: a car burnt to the shell, `BURNT_SHELL`'s charred palette moved onto a
## vehicle body. Vehicle-scale `obstructs_within()`, so `SealPlanner._hard_positions` spaces four
## across a street's 192px as it spaces two `barricade` copies: a pile-up rather than one wide
## scene.
static func _burnt_out_car() -> EventDef:
	var row := EventDraft.new("burnt_out_car")
	row.scripted_on(0, 2)
	row.look(LookSpec.of(EventDef.Look.BURNT_OUT_CAR))
	row.body(BodySpec.solid(GroundShape.band(24.0))
			.walked_round()
			.parked()
			.across_its_street())
	row.field(FieldSpec.of(0.0, 40.0, 120.0))
	row.warning(WarningSpec.lasting(0.9))
	return row.build()

## A hard seal, acts II-IV: rubble spilled frontage to frontage. Single-copy geometry like
## `fallen_tree`, but drawn with `SpreadLook._draw_spread`'s ordinary repeated-segment behaviour
## rather than one stretched picture: `collapsed_frontage.svg` is a small debris segment, styled
## beside `rubble.svg` (`_burnt_shell`'s picture) rather than sharing it, since a row may not draw
## another row's picture.
static func _collapsed_frontage() -> EventDef:
	var row := EventDraft.new("collapsed_frontage")
	row.scripted_on(0, 2)
	row.look(LookSpec.of(EventDef.Look.COLLAPSED_FRONTAGE))
	row.body(BodySpec.solid(GroundShape.band(96.0)).walked_round().parked().as_a_spread())
	row.field(FieldSpec.of(0.0, 40.0, 120.0))
	row.warning(WarningSpec.lasting(0.9))
	return row.build()

# ------------------------------------------------------ the region door's own structure ---
# Three bodies `RegionPlanner` stands at every open crossing of today's region wall, from
# `Tuning.REGION_WALL_FIRST_DAY`: a hut on each sidewalk and a gate over the road at a street door,
# a single guard at each mouth of an alley door. All three are `SCRIPTED`, `scripted_day 0`, like
# the seal pictures above: the ordinary catalogue roll never schedules one, and
# `RegionPlanner.plan_day` places each fresh every morning at the door geometry decides. See
# docs/CITY.md, "Regions and the wall", and docs/EVENTS.md, "Checkpoints".
#
# All three count as one barrier (`FieldSpec.as_one_barrier()`), as does the `roadblock` the wall stands as: a door is one
# thing to walk through however many bodies it is built from, and where a door and a wall meet at a
# corner their fields are one barrier rather than five. See `FieldSpec.as_one_barrier()`.

## The hut at a region door. Detains rather than blocking outright: the player walks to the hut,
## gets detained inside, and spawns on the other side.
##
## **The hold starts a reach past the hut's own wall**, not a radius from the middle of it:
## The hold's reach (`HoldSpec.past_its_edge()`) is `CHECKPOINT_DETAIN_REACH` (48px), measured from the solid edge, so
## `EventDef.detain_distance()` comes out at 80px from the centre, and the guard steps out while she
## is still walking up rather than only once she is pressed against the hut. It sits inside
## inner radius (84px) as every detainer's does, and the ambient field is a small peak over
## a tight band, small enough that the real price stays the flat `Tuning.CHAT_EXCITEMENT` the
## detention charges through the ordinary chat mechanism, and standing still on its own pays nothing
## back (`EXCITEMENT_DECAY_IDLE`). **The field is not what makes this row expensive and must not
## be asked to be**: at 4.0 over an 84–98px band it means less along the line than the 6.0/s an
## ordinary street gives back, so `walk_through_cost()` reads it as free, and it is, because the
## price is the detention. `tests/test_events.gd` exempts the detainers from its catalogue-wide
## "nothing is cheaper to walk through than around" rule by name and holds them to charging their
## capture instead. The band stays 14px wide, which is what the telegraph is priced on; the disc
## moved out with the capture so the two keep the order `validate()` requires. `HoldSpec.detains_again()` tells
## `EventManager` this instance is armed again once she is outside `detain_distance()`, in either
## direction, rather than spent after one conversation like `chatting_mother`.
##
## **4.0 rather than 6.0, for the reason the `roadblock` is silent.** A door is a hut on each
## sidewalk, a gate over the road and often a wall's roadblocks at the corner, and a hold is spent
## standing still where no decay is earned. Being one barrier already collapses all of them to
## the strongest at her position; this is that source's own rate when the hut is the strongest thing
## there. It changes nothing about what a detention costs, which is `Tuning.CHAT_EXCITEMENT` flat.
static func _checkpoint_hut() -> EventDef:
	var row := EventDraft.new("checkpoint_hut")
	row.scripted_on(0, 2)
	row.look(LookSpec.of(EventDef.Look.CHECKPOINT_HUT))
	row.body(BodySpec.solid(GroundShape.point(32.0)).walked_round().parked())
	row.field(FieldSpec.of(4.0, 84.0, 98.0).as_one_barrier())
	row.warning(WarningSpec.lasting(1.0))
	row.hold(HoldSpec.for_seconds(CHECKPOINT_DETAIN_SECONDS)
			.from(CHECKPOINT_DETAIN_REACH)
			.again())
	return row.build()

## The boom over the roadway between a door's two huts. **It never inspects her**: a lowered boom is
## a wall across the carriageway, and a raised one is ground she may walk under
## (`BodySpec.SolidWhen.WHILE_LOWERED`), so its collision body follows the arm and the cars decide
## the arm (`Crowd._stop_for_gates()`: up once a car has waited at it `Crowd.GATE_STOP_SECONDS`,
## down the moment no car is within a length of it and she is not under it). The inspection is the
## two huts' alone, and a hut does not take her in from the carriageway this boom spans, so walking
## under a raised arm skips the toll: the unlawful crossing `EventManager` watches for and sets a
## `door_guard` on her for.
##
## No field of its own (a car passing under it costs her nothing whether or not she is near it):
## peak 0 on radii that exist only because `validate()` wants a falloff band, inner radius
## 84 and outer radius 120, clear of `Tuning.required_telegraph_time()` at that core. Drawn raised
## or lowered from the shared `GateState` `Crowd` keeps current for the day's cars.
## Placed with the plan's facing set (`EventPlan.face()`) along the street's own axis, which tells the drawing a
## north-south road from an east-west one and is the door's own line for the walk-under check.
static func _checkpoint_gate() -> EventDef:
	var row := EventDraft.new("checkpoint_gate")
	row.scripted_on(0, 2)
	row.look(LookSpec.of(EventDef.Look.CHECKPOINT_GATE))
	row.body(BodySpec.solid(GroundShape.point(32.0))
			.while_lowered()
			.walked_round()
			.parked())
	row.field(FieldSpec.of(0.0, 84.0, 120.0).as_one_barrier())
	row.warning(WarningSpec.lasting(0.9))
	return row.build()

## The alley half of a door: a single guard where a through-alley crosses a region boundary,
## standing in for the hut and gate a full street gets; the alley is one lane wide, so one body
## covers its whole 64px mouth. Detains exactly like `checkpoint_hut`, with the same numbers and the
## same `HoldSpec.detains_again()`, because the toll is the crossing itself, not the width of the street it stands
## on.
static func _checkpoint_post() -> EventDef:
	var row := EventDraft.new("checkpoint_post")
	row.scripted_on(0, 2)
	row.look(LookSpec.of(EventDef.Look.CHECKPOINT_POST).hiding_in_its_hold())
	row.body(BodySpec.solid(GroundShape.point(32.0)).walked_through().parked())
	row.field(FieldSpec.of(4.0, 84.0, 98.0).as_one_barrier())
	row.warning(WarningSpec.lasting(1.0))
	row.hold(HoldSpec.for_seconds(CHECKPOINT_DETAIN_SECONDS)
			.from(CHECKPOINT_DETAIN_REACH)
			.again())
	return row.build()

## The guard a door sets on her when she walks across its line and stays. Not
## going through the checkpoint is a clear unlawful thing, independent of the resistance: one guard
## is enough. Nothing places it but `CheckpointController._set_a_guard_on_her()`: `SCRIPTED` on day 0
## like the rest of the door's kit, so the ordinary roll never reaches it, stepping out of the wall
## of the door's hut across the road from her on the side she crossed to. The guards drawn at the
## huts stay at their posts, so the door stays manned.
##
## **The roadblock's hunting guard is the pursuer copied**, and so is the man: the same eight-view
## `guard_standing_*`/`guard_lunging_*` pictures, `Tuning.HEAT_HUNTS_SPEED` (130px/s, between her
## walk and her run by the pursuit contract's own margin), no notice of his own, a chase of
## `Tuning.PURSUIT_TIME`, and `MASKED_MAN_REACH` (28px) as the catch, the core of his own field here
## since the field is the man. **Ending the day in its own right, not through its hunt**: a
## catch is a detention on every day a door stands and at every heat level, never a rung of the
## resistance's ladder. The field is `masked_pursuer`'s, 18 over a 28–120px band, the same figure
## coming at her.
##
## **He charges at once** (`PursuitSpec.Start.CHARGES_AT_ONCE`): his warning came before he was set
## on her. From the frame she crosses the door's line, the guard at the hut across the road from her
## raises his hand (`EventInstance.is_its_guard_warning()` is then true), or an alley post's guard;
## back across before his warning (`ChargerTiming.warning()`) has run, nobody comes, and still
## across once it has, this man steps out of that hut or post and charges from his first frame
## (inbox #788 in minty-lemur). The answer is the warning, go back or go on running, which
## `tests/test_checkpoints.gd` walks.
static func _door_guard() -> EventDef:
	var row := EventDraft.new("door_guard")
	row.scripted_on(0, 3)
	row.look(LookSpec.of(EventDef.Look.DOOR_GUARD))
	row.body(BodySpec.footprint(GroundShape.point(9.0)).walked_through().going_on())
	row.field(FieldSpec.of(18.0, MASKED_MAN_REACH, 120.0))
	# No notice of his own: his warning was the hut guard's raised hand from her crossing
	# (`CheckpointController.warn_at_the_doors()`), and he charges the moment he is set on her
	# (`PursuitSpec.Start.CHARGES_AT_ONCE`).
	row.warning(WarningSpec.lasting(0.0))
	row.lasts(Tuning.PURSUIT_TIME)
	row.pursuit(PursuitSpec.at(Tuning.HEAT_HUNTS_SPEED).starting_by(PursuitSpec.Start.CHARGES_AT_ONCE))
	row.lethal(LethalSpec.at_its_core())
	return row.build()

# ------------------------------------------------------------------ the finale ---
# Rows the escape places and nothing else does. Each is `SCRIPTED` with `scripted_day = 0`, the
# same gate the seal pictures and the checkpoint kit use: `EventDef.available_on()` asks
# `scripted_day == day` for a `SCRIPTED` row and no day of a fourteen-day run is day zero, so the
# ordinary scheduler can never roll one. `FinalePlanner` places them by id.

## The bang she hears and does not see: explosions happen off screen (but loud enough to cause
## excitement), leaving craters on the street.
##
## **Off screen, announced by its badge** *(minty-lemur #785: explosions have to happen off-screen
## with a warning sign showing the explosion; craters already there when she walks towards them)*.
## A place sets it off (`EventDraft.set_off_within()`, `SetOffWatch`): the plan the escape's bag put
## on the road is not in the world until she comes within `FINALE_EXPLOSION_SET_OFF_WITHIN` of it,
## far enough out that heading straight at it, walking or running, she hears none of its bang. Then its screen-edge badge goes up, the mushroom cloud
## (`EventDef.Look.EXPLOSION`, drawn only in the badge, `LookSpec.drawn_only_in_its_badge()`),
## pointing at the place, for `Tuning.WARNING_ALONE_MAX`; and once that has run it goes off there,
## its telegraph spent, only while everything it puts on the screen there is out of her sight, the
## crater it leaves included (`EventFootprints.footprint_of()`), so no bang and no crater is ever
## in her view. It comes all at once (`EventDef.comes_all_at_once()`): walking into the place does
## not set it off at once (`EventDef.may_be_set_off_at_once()`), since the badge is the whole of
## its notice, and the badge goes up only where it cannot come down without its bang
## (`SetOffWatch`). The badge stays on it until it is over (`BadgeModel`).
##
## **The crater comes as it goes off** (`Aftermath.then()`, `EventStreaming.set_off()`), at its
## place on the tick its out-of-sight check passed, so a crater she walks toward is standing before
## she can see it.
##
## **The sky lights up as it goes off** (`LookSpec.flashing_as_it_goes_off()`, `BlastLight`), and
## the screen shakes a little by how loud it lands where she is.
##
## **The radii are sized against the screen and not against taste.** Outer radius 520 reaches
## a screen and a half; inner radius 300 puts the near half of that band at close to full
## strength, so a burst just beyond the screen edge (about 360px on the long axis) still lands
## roughly 22 of its 24 points per second on her. A narrower band would be an explosion she could
## be next to and not hear. Its fairness is its badge's (`EventDef.warning_time()`): the flat
## second a warning first owes (`Tuning.OFFSCREEN_WARNING_MIN`), since it stands still and is heard
## where it goes off.
##
## **Not lethal, and that is the tone rule rather than an omission** (`docs/NARRATIVE.md`: *the
## danger is always noise*). The thing that ends a section is being taken; an explosion wakes the
## baby.
static func _finale_explosion() -> EventDef:
	var row := EventDraft.new("finale_explosion")
	row.scripted_on(0, 4)
	row.look(LookSpec.of(EventDef.Look.EXPLOSION).drawn_only_in_its_badge().casting_no_shadow()
			.flashing_as_it_goes_off())
	row.body(BodySpec.none().unmet().parked())
	row.ground([GameEnums.TileType.ROAD])
	row.field(FieldSpec.of(24.0, 300.0, FINALE_EXPLOSION_HEARD_WITHIN))
	row.warning(WarningSpec.lasting(Tuning.WARNING_ALONE_MAX).warned_first())
	row.set_off_within(FINALE_EXPLOSION_SET_OFF_WITHIN)
	row.lasts(FINALE_EXPLOSION_SECONDS)
	row.aftermath(Aftermath.none().then("impact_crater"))
	return row.build()

## What is left in the road afterwards, and it stays there for the rest of the sequence: `duration`
## 0 is "lasts the whole day", so a crater is a fact about the street from the moment it is made.
##
## **Silent and solid**, like the seal pictures it sits beside: a hole in the road makes no noise,
## and its radii are `barricade`'s (inner 40, outer 120, telegraph 0.9) because `EventDef.validate()`
## wants a falloff band even at zero intensity.
##
## **The body is the picture.** `impact_crater_2x2.svg` is 64px across, so `point(32)` is exactly
## half of it and the ground she cannot walk on is the hole she can see. The 32px and 96px sources
## stay prepared and unbound: `aftermath.leaves_behind()` names one row, a second crater row would need a
## second explosion row to leave it, and three sizes of the same hole would be three looks no reader
## could tell apart on the screen-edge badge.
##
## **No `aftermath.scar_id()`.** A scar is how the *run* remembers a fire on day 3; the escape is the last
## thing that happens in a run, so a crater has nothing to persist into and recording one would only
## put an entry in `RunState.attempt_spend().scars()` that no later day reads.
static func _impact_crater() -> EventDef:
	var row := EventDraft.new("impact_crater")
	row.scripted_on(0, 4)
	row.look(LookSpec.of(EventDef.Look.IMPACT_CRATER))
	row.body(BodySpec.solid(GroundShape.point(32.0)).unmet().parked())
	row.field(FieldSpec.of(0.0, 40.0, 120.0))
	row.warning(WarningSpec.lasting(0.9))
	return row.build()

## A masked man running up the stairwell: masked pursuers run up the stairs and can be avoided by
## going into a corridor and letting them pass.
##
## **Mobile, not a pursuer (`EventDef.pursues()`), and that is the whole counterplay.** A
## pursuer steers at her, so the only answer to one is speed; this runs a line (the shaft,
## bottom landing to top) and the answer to it is *not being on that line*, which in a building
## whose stairwell doors are a fade and a teleport means stepping through the nearest one and
## letting him go past. It is `loose_dog`'s contract indoors: a thing coming down the corridor
## you are in, answered by leaving the corridor.
##
## **Placed when he should appear, warned first** *(minty-dolphin #852: "Stair guard could as well
## be placed when it should appear instead of when entering"; "The stair guard can become a charger
## that is triggered by a location if necessary")*: a place on the stairwell sets him off
## (`EventDraft.set_off_within()`), and until she reaches it he is not in the world. Walking into
## it, she sets him off at once (`EventDef.as_set_off_at_once()`): his badge goes up, pointing at
## the foot of the shaft he comes from, and he comes into the world there on the same tick, running
## (`SetOffWatch`). Already inside it when he may come, or arriving in it through a door, his badge
## is up alone for his own warning first, `Tuning.WARNING_ALONE_MAX`, so he never runs at her with
## no warning at all (inbox #788 in minty-lemur). Faster than a walk, so it cannot be out-walked,
## which makes stepping aside the answer rather than a preference.
##
## **No body**, like every other mobile row: a moving wall on a stairwell one tile wide would pin her
## against the shaft. What stops her walking into him is that it ends the section.
static func _masked_pursuer() -> EventDef:
	var row := EventDraft.new("masked_pursuer")
	row.scripted_on(0, 4)
	row.look(LookSpec.of(EventDef.Look.MASKED_PURSUER))
	row.body(BodySpec.footprint(GroundShape.point(9.0)).walked_through().going_on())
	row.field(FieldSpec.of(18.0, MASKED_MAN_REACH, 120.0))
	row.warning(WarningSpec.lasting(Tuning.WARNING_ALONE_MAX).warned_first())
	row.route(RouteSpec.at(Tuning.HEAT_HUNTS_SPEED))
	# **He comes the moment she is within this of the foot of his shaft**, rather than running his
	# line the moment the section begins and being gone before she has come down a floor. She has
	# to run to the first floor's door (inbox #764 in minty-lemur) rather than walk down to it and
	# out to the other shaft without meeting him (inbox #782 in minty-lemur: a bigger radius, and
	# him not moved). 426px is measured on the escape as built
	# (`tests/probes/escape_stairwell_guard_trigger.gd`, stepped as the game steps, a 30Hz physics
	# tick that moves her, then steps him and checks the catch): coming down from the second floor's
	# door she reaches it at the head of the second flight, and making for the first floor's door
	# from there a runner gets through on every line onto the flight, while a walker is caught
	# holding plain left from the row level with the flight's head tread or the row below it, or
	# down-left from the landing tile between the two flights. **A walker holding plain left from
	# that landing tile gets through**, and the margins are thin against his 23.5px catch
	# (`MASKED_PURSUER_CATCH`): a runner who walks until he runs, then runs, turning plain left at
	# row 11's centre, comes within 24.6px of him on the tick and clears it by 1.1px in the
	# hand-stepped probe, and clears it on the real body, which slides along walls, in
	# `tests/test_interior_masked_man.gd`; the walker down-left from the landing tile comes within
	# 22.7px, 0.8px inside; a runner who runs the whole way is 33px from him at the closest. In the
	# stairwell the foot of his shaft is off screen, since the view reaches 180px from her and the
	# foot is 426px below; his badge is what shows him coming, from the tick he is set off
	# (`DangerEdge`). The player accepted both (inbox #782 in minty-lemur).
	row.set_off_within(426.0)
	row.lethal(LethalSpec.within(MASKED_PURSUER_CATCH))
	# **One of him at a time, and there is always another**: a fresh one may come up the shaft this
	# long after the last has run out of the top of it, set off by the same place as the first
	# (`EventManager`'s repeats).
	row.comes_again(0.0, FINALE_PURSUER_RESPAWN_SECONDS)
	return row.build()

## Steam in the basement. A vent that blows on a timer, the one kind of pressure a passage with no
## branches can carry.
##
## **It stands still and it closes the corridor, and both halves are the point.** Steam does not
## move, so this row is a place rather than a beat: several fixed locations that fully block the
## path and turn off and on at different intervals, so it becomes a timing puzzle. *Anything that
## stands still is solid at the width it is drawn* applies like anything else: `STEAM_VENT_BODY` is
## half of `steam.svg`, and standing in the middle of a two-tile corridor it is already a gate with
## no lane beside it.
##
## **What makes that fair is the notice, and `BodySpec.SolidWhen.ONCE_IT_STARTS` is what makes the
## notice worth anything.** A body from the instance's first frame would close ground she might be
## standing on, so the body goes down at the end of the telegraph and never around her (see that
## field, and `EventInstance._become_solid_once_it_starts()`).
##
## **One vent is a gate; the corridor is several of them on their own clocks.** The count, the
## periods and how long a blow lasts are `BuildingPlan.FINALE_STEAM_PERIODS` and
## `FINALE_STEAM_BLOWS_FOR`; the building sites them on the basement's narrows (`BuildingPlan`),
## each plan coming again on its own period (`EventPlan.comes_again_every()`). What this row
## owns is one blow: notice, body, field, over. Its plume billows over two frames
## (`EventPictures.STEAM_B`) for the whole blow.
static func _basement_steam() -> EventDef:
	var row := EventDraft.new("basement_steam")
	row.scripted_on(0, 4)
	row.look(LookSpec.of(EventDef.Look.STEAM))
	row.body(BodySpec.solid(GroundShape.point(STEAM_VENT_BODY))
			.once_it_starts()
			.unmet()
			.parked())
	# **25, so one blow costs 40 to 50 points awake** at the 30px a vent holds her out (inbox #747 in woolly-penguin):
	# 44 awake, 24 asleep. The pulse is kept, since it is what makes the blow swell and fall back
	# rather than hold flat. What bounds it from above is the pocket between two vents, shut at both
	# ends for 2s at most: the cost there scales with this, and
	# `_test_no_pocket_between_two_vents_outlasts_the_noise` keeps it under the meter (84 of 100 at
	# 25; 29 is the most the meter allows).
	row.field(FieldSpec.of(25.0, 24.0, 90.0).pulsing_every(4.0))
	# Well under a walk, so the escape distance is the falloff band: `(90 − 24) / WALK_SPEED` is
	# 0.72s. The body asks for far less than the field does (a step of `STEAM_VENT_BODY` plus her
	# own 14px is a third of a second), so the notice she is owed for the ground is paid several
	# times over by the notice she is owed for the noise.
	row.warning(WarningSpec.lasting(1.2))
	row.lasts(FINALE_STEAM_BLOWS_FOR)
	return row.build()
