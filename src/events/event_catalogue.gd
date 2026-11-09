class_name EventCatalogue
extends RefCounted
## Every event in the game, defined in code: reviewable in a diff, validated on load, and
## assertable over the whole catalogue in a test. See docs/EVENTS.md for the catalogue table and
## the reasoning behind each row.

## The other answer to *prevents the player from walking past it*: **off**, and one line from being
## on. True makes the crash a `hard_fail` row, as a fire is, so the gaps end the day rather than
## costing more of it than she can carry. The built default is the expensive reading, because a
## wall that kills has no price to weigh and the verb of this game is *where do I walk*.
##
## Flipping it takes the row's `inner_radius` to `CAR_ACCIDENT_LETHAL_INNER_RADIUS` and its
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
## inside his one radius (`PursuitSpec.warns_for`, `EventInstance.warns_by_radius()`; inbox #788 in
## minty-lemur). If she leaves the radius the warning stops; if she stays, the charge starts. The
## measurement that keeps it fair is per row (`tests/probes/charger_warning.gd`): a walker who turns
## back the moment his warning starts is out of his radius before it runs out, and one who stands in
## it is caught.
const CHARGER_WARNING := 2.0
## How far past a door body's own solid edge the inspection starts (PLAYTEST-57).
##
## **Stated over the hut, never over her.** Her centre is stopped `obstructs_radius +
## Tuning.PLAYER_BODY_RADIUS` (32 + 14 = 46px) from a door body's centre, and further when the
## pram's own body is between, so a trigger stated as a radius from the hut's *centre* has to be
## larger than whatever she happens to be pushing. Measured from the hut's wall, one number covers
## every pram: 48px clears her own body's 14px stand-off and the widest the pram has reached ahead
## of her, and starts the inspection while she is still walking up. See `EventDef.detain_radius`.
const CHECKPOINT_DETAIN_REACH := 48.0
## Seconds a `checkpoint_hut`/`checkpoint_post` detention holds her. Short rather than heavier than
## `chatting_mother`'s 5s: a toll paid at every crossing of a region wall has to stay cheap to
## repeat, where a conversation is spent once. See `EventDef.detain_seconds`.
const CHECKPOINT_DETAIN_SECONDS := 2.0
## Seconds between two off-screen explosions inside the building. Section one is relatively minimal
## and an explosion is its only city-wide beat, so it is spaced like the director's own
## `EventDirector.AHEAD_INTERVAL` band: eight of them over a 180s clock flash the hallway windows
## more than once without the basement becoming a drum.
const FINALE_EXPLOSION_INTERVAL := 22.0
## How long after the masked man has finished his run before another one comes up the same shaft,
## in seconds: he respawns, forcing her to switch sides again.
##
## **Stated against what one run costs her.** A shaft is three floors of eight tiles (768px) and he
## runs it at `Tuning.HEAT_HUNTS_SPEED` (130px/s), so a run is about six seconds, and before it he
## stands at the foot with his hand raised until she comes within `masked_pursuer.notice.runs_within`
## of him. Six seconds of nothing between runs is long enough that stepping out of a door and
## straight back in is a real answer, short enough that waiting one out and strolling down is not.
## A first number, and the one to move if the shaft reads as either a corridor with a man in it or
## a corridor with a man near it.
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
## (`PursuitSpec.stop_excitement`; inbox #669 in coral-lark).
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
# `EventDef.obstructs_radius` is that a thing that stands still is solid at the width it is drawn,
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

## `mast.svg` is thinner than a person: a pole, not a body to edge past. Solid enough that she
## cannot walk through it; the field, not the pole, is what a route goes round.
const MAST_BODY := 6.0

static var _all: Array[EventDef] = []
## Derived rows, keyed `"<id>|<level>"`. See `heated()`.
static var _hot: Dictionary[String, EventDef] = {}
## The building's two derived rows, built once. See `building_fire()` and `explosion_outside()`.
static var _building_fire: EventDef = null
static var _explosion_outside: EventDef = null

## Every heat level a run can reach. Progress runs 0..`RESISTANCE_GOAL`; a task completed past the
## goal adds nothing, because full heat is the qualification rather than the last errand. A
## function rather than a `const`, because an autoload's constant is not available at parse time.
static func heat_levels() -> int:
	return Tuning.RESISTANCE_GOAL + 1

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
	if def.heat_response == EventDef.HeatResponse.NONE or level <= 0:
		return def
	var key := "%s|%d" % [def.id, level]
	if not _hot.has(key):
		_hot[key] = def.at_heat(level)
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
## A **derived copy, never a mutation**, for the reason `EventDef.at_heat()` gives. `shape` is
## carried across by hand because it is a plain `RefCounted` field, so `Resource.duplicate()` does
## not copy it; sharing the reference is safe, since a shape is never mutated in place.
static func without_its_aftermath(def: EventDef) -> EventDef:
	var variant: EventDef = def.duplicate()
	variant.shape = def.shape
	variant.aftermath = Aftermath.new()
	return variant

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
		var variant := without_its_aftermath(by_id("burning_building"))
		variant.solid(GroundShape.point(30.0))
		variant.intensity = 18.0
		variant.pulse_period = 3.0
		variant.draws_body_shadow = true
		variant.on_her_way = null
		# The building's own row, placed by its plan and nothing else: `SCRIPTED` on day 0, the day
		# nobody plays, like the escape's other rows, so no day's dawn reaches it and the rule that
		# a one-shot is sited from her walk does not apply to it.
		variant.kind = GameEnums.EventKind.SCRIPTED
		variant.scripted_day = 0
		_building_fire = variant
	return _building_fire

## **The explosion outside, as it reaches her inside the building**: `finale_explosion` without its
## crater, coming every `FINALE_EXPLOSION_INTERVAL` (`repeat_every`). Indoors there is nothing of
## it to see, so it is a beat: every window lights (`from_outside`, `WorldContext.bang_outside()`)
## and the row's own field (`intensity` for its `duration`) charges her wherever she stands. No
## wall stops it: the bang has already come through them. The building places it where she is each
## time it comes, with its notice over, since what the windows say is that it has already happened
## (`BuildingPlan`). Its id stays the row's.
static func explosion_outside() -> EventDef:
	if _explosion_outside == null:
		var variant := without_its_aftermath(by_id("finale_explosion"))
		variant.from_outside = true
		variant.repeat_every = FINALE_EXPLOSION_INTERVAL
		_explosion_outside = variant
	return _explosion_outside

static func by_id(id: String) -> EventDef:
	for def in all():
		if def.id == id:
			return def
	return null

## The row that plays `role` (`EventDef.Role`), the first in catalogue order, or null.
static func by_role(role: EventDef.Role) -> EventDef:
	for def in all():
		if def.role == role:
			return def
	return null

## The loudspeaker mast (`EventDef.Role.MAST`): what the masts' sites, the day's masts and the
## resistance's mast task are made of.
static func mast() -> EventDef:
	return by_role(EventDef.Role.MAST)

## **The day-3 lesson's own row for `row`**: for the charging dog, `charging_dog_tutorial`, the dog
## under an id of its own, which `EventDirector._teach_the_run()` hands out in place of the first
## dog it sends on `Tuning.RUN_TAUGHT_DAY`, so its GoatCounter counts (`seen-charging-dog-tutorial`,
## its `dog-tutorial-*` charges) are its own (inbox #849 in minty-dolphin); `row` itself for any
## other. A derived copy, built once: it shares the dog's picture and every number, and the day's
## roll never places it.
static func lesson_of(row: EventDef) -> EventDef:
	if row == null or row.id != "charging_dog":
		return row
	if _lesson_dog == null:
		_lesson_dog = _charging_dog()
		_lesson_dog.id = "charging_dog_tutorial"
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
		_task_guard = _alley_robbery()
		_task_guard.id = "task_guard"
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
	var def := EventDef.new()
	def.id = "neighbor"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.NEIGHBOR
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.act_tag = 1
	def.shape = GroundShape.point(9.0)
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 0.0
	def.inner_radius = 20.0
	def.outer_radius = 40.0
	def.telegraph_time = 0.5
	def.mobile = true
	def.speed = NEIGHBOR_WALK_SPEED
	return def

## An unhurried walk, half hers (`Tuning.WALK_SPEED`, 92px/s): somebody going to a shift, and
## somebody she can catch.
const NEIGHBOR_WALK_SPEED := 46.0

## How fast the neighbor goes once warned: a run, not a walk.
const NEIGHBOR_RUN_SPEED := 150.0

## The day-10 neighbor: the same row walking home from out in the city along a path the director
## gives it, who **stops at the door** (`stops_where_it_arrives`), walked home into the vans, which
## is the task lost, and who, warned first, runs (`departs_at`), which
## `EventInstance.leave_for_a_completed_task()` turns away from her. A copy rather than a second
## row, since it is the same person in the same picture.
##
## `shape` and `solid_parts` are carried across by hand, as every copy of a row does
## (`EventCatalogue.without_its_aftermath()`): `Resource.duplicate()` does not copy a plain
## `RefCounted` field.
static func neighbor_heading_home() -> EventDef:
	var row := by_id("neighbor")
	var def: EventDef = row.duplicate()
	def.shape = row.shape
	def.solid_parts = row.solid_parts
	def.stops_where_it_arrives = true
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.departs_at = NEIGHBOR_RUN_SPEED
	return def

## A permanent feature of the calmest ground in the city, and free: the swing frame it draws is
## `map.playgrounds`' own prop (`City._dress_blocks`), not this row.
##
## **Free because a one-block park otherwise has nowhere left to settle her.** `outer_radius`
## (150) reaches past half of a 256px park block, so a playground with any real cost denied
## nearly the whole lot rather than merely contesting its middle. `EventKind.AMBIENT` is exempt
## from spoiling a park (`EventScheduler.Planned.spoils()` passes over every playground), so a park
## is still contested on the days the scheduler spoils it, just never by its own swings.
##
## **The row stays rather than being deleted**: `tests/test_events.gd` looks it up by id and reads
## its `kind`, `EventInstance._field_distance()` names it as the row with no shape to fall back to,
## and the event and cost tables in `docs/EVENTS.md` carry a line for it.
static func _playground() -> EventDef:
	var def := EventDef.new()
	def.id = "playground"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.AMBIENT
	def.ambient_source = EventDef.AmbientSource.PLAYGROUND
	def.look = EventDef.Look.NONE  # The park's swing frame already draws it.
	def.stands_as = EventDef.StandsAs.NOTHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.intensity = 0.0  # Free. See the note above.
	# Kept at their size for the debug field overlay, which still draws a disc here, although
	# `Field.falloff` answers zero at every distance and nothing else reads them.
	def.inner_radius = 40.0
	def.outer_radius = 150.0
	def.telegraph_time = 0.0
	def.pulse_period = 9.0
	return def

## The tutorial obstacle: visible crouching before it bolts, sharp while it crosses, gone a second
## later. Small radius, so walking one lane wide of it is enough.
##
## **Two things make a cat happen at all.** It is `AHEAD_OF_PLAYER`, because a cat is not a place:
## sited on a road tile at dawn it runs its two seconds out somewhere across the city, alone; the
## director puts it across her line while she is walking. And it is `still_while_telegraphing`:
## `EventInstance` starts a mobile event moving when the telegraph does, which is wrong for a
## crouch, since the path is one street wide and at 240px/s the cat would finish its whole run
## *during* the telegraph, never reaching full intensity or drawing the running sprite.
##
## **That held-still telegraph is also why it needs its own siting distance** rather than the flat
## `AHEAD_LEAD_DISTANCE`: a cat sited two seconds of walking ahead and then held still for
## `telegraph_time` measures where she *was*, so it would cross behind her.
## `EventDef.ahead_of_player_lead()` prices the hold in as walking distance.
##
## **Intensity 17, a startle spike** (PLAYTEST-25 6). There is no `impulse` field: a sharp spike is
## a short `duration` at high `intensity`, and 1.8s is as short as a crossing this wide can be.
## **Its dash still projects under `Tuning.EXPECTED_IMPACT_POINTS` on a standing player**;
## `tests/test_danger.gd` holds this scenario by name, since the crouch is its own silhouette and
## needs no second cue. A bigger number crosses that line and would give the cat a caret, which is
## a design question left open.
static func _cat_dash() -> EventDef:
	var def := EventDef.new()
	def.id = "cat_dash"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.CAT
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.shape = GroundShape.point(7.0)
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.spawn_mode = EventDef.SpawnMode.AHEAD_OF_PLAYER
	# It does not telegraph its coming (PLAYTEST-145 20): no screen-edge badge, no warning first,
	# outside the telegraph contract (`EventDef.telegraphs`). It still holds before it dashes, which
	# is the cat's own behaviour, not a warning owed.
	def.telegraphs = false
	def.intensity = 17.0
	def.inner_radius = 30.0
	def.outer_radius = 120.0
	# Long enough to carry it the whole way across the street it starts at the edge of:
	# STREET_WIDTH tiles either side at 240px/s is 1.6s, and it must not expire mid-road.
	def.duration = 1.8
	# Faster than a walk, so the escape distance is the forward reach, not the plain radius:
	# `outer_radius · Field.scale(e)` at the cat's own speed (240px/s, e = 0.48, just under the
	# eccentricity cap): 120 * 1.92 / 92 = 2.51s, plus the row's margin.
	def.telegraph_time = 2.81
	def.mobile = true
	def.still_while_telegraphing = true
	def.speed = 240.0
	# Shared with the other things that happen *to* her rather than being the whole of the moments
	# she is owed: the director also has the cyclist and, from day 3, the dog.
	def.weight = 2.5
	# Deliberately low where the rest of the catalogue's caps are not. A cat is sited by the director
	# while she walks and `AHEAD_INTERVAL` spreads them 11-26s apart over a 210s day, so past this
	# there is nowhere left for one to happen and the day's moments go on cats it cannot fit.
	def.max_per_day = 8
	return def

## The cat's shape, softened, and placed rather than sited: a mouse that darts across an alley when
## she walks into range of it.
##
## **`MAP`, not `AHEAD_OF_PLAYER`.** `_cat_dash` needs the director because a road tile picked at
## dawn could be anywhere and she may never cross it; alleys are rare, and one she is routed through
## she is about to walk down. Placing it on the tile itself lets `EventScheduler._refuses_required_
## alleys` reach it: that check is stated over `def.placement == [ALLEY]` rather than over
## `alley_robbery`'s id, so a required alley (one the day's corridor runs down with no way round)
## never offers one; only an alley she chose to detour into can.
##
## **Acts and cap, derived from the cat's.** `first_day`, `last_day` and `act_tag` are left at their
## defaults (1, 0, 1), as `_cat_dash` leaves them: everyday background texture. The cap is half of
## the cat's 8; an `ALLEY` tile is scarcer than every `ROAD` and `CROSSING` tile a cat may cross,
## and `_refuses_required_alleys` narrows the pool further.
##
## **Lower intensity than the cat's 17, because it is a startle rather than a threat**: 9, roughly
## half, on the same 4:1 outer:inner ratio scaled down to the alley's smaller stage (60:15). The
## alley she is standing in is already worth `Baby.EXCITEMENT_FROM_ALLEY` (+3.0/s) of ambient dread,
## so the mouse only adds a spike on top of ground that is already tense.
##
## **No body, nothing lethal.** `shape` is set for the shadow alone (`solid()` is never called) and
## `hard_fail` stays `false`.
##
## **It waits for her rather than running the moment it exists.** `MAP` places it on its `ALLEY`
## tile at dawn, well outside `Tuning.EVENT_STREAM_RADIUS` (900px), so a row that started
## telegraphing on arrival would dash and finish off screen before she was anywhere near. The row
## sets `EventDef.notice` (150px) without `EventDef.pursuit`: `EventNoticeRun` holds it
## `is_waiting()`, emitting nothing above the ordinary field and not yet on the clock, until she is
## within 150px, and only then does the telegraph start and the path run. 150px is inside
## `VIEW_HALF_EXTENT.y` (180, the shorter axis, so this holds whichever way she faces) and past the
## field's own `outer_radius` (60px), so the telegraph is already on screen by the time she could
## feel it. `Tuning.validate_event()` is stated over `telegraph_time` against the field's geometry,
## not over when the clock starts, so it is unaffected.
##
## **The dash crosses the alley's own short axis by construction.** `EventInstance` reads
## `map.alley_rects` for the rect this instance landed in and lays its two-point path across the
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
	var def := EventDef.new()
	def.id = "alley_mouse"
	# It does not telegraph its coming (`EventDef.telegraphs`): 200px/s, but it dashes across its
	# alley rather than at her, and costs about an eighth of the meter to walk through; no badge,
	# outside the telegraph contract.
	def.telegraphs = false
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.MOUSE
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.path_mode = EventDef.PathMode.ACROSS_ITS_ALLEY
	def.shape = GroundShape.point(4.0)
	def.placement = [GameEnums.TileType.ALLEY]
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
	def.intensity = 21.0
	def.inner_radius = 15.0
	def.outer_radius = 60.0
	# `Tuning.required_telegraph_time(15, 60, false, 200)` is ~1.09s (outer_radius · Field.scale(e)
	# at e = min(0.5, 200/500) = 0.4, scale 1.667, over WALK_SPEED); this carries a margin of the
	# cat's shape.
	def.telegraph_time = 1.4
	# Comfortably past the ~0.32s the physical crossing takes at this speed over the alley's 64px
	# width (`ALLEY_WIDTH_TILES · Tuning.TILE_SIZE`), so `_has_expired()` never cuts the dash short.
	def.duration = 1.0
	def.mobile = true
	def.still_while_telegraphing = true
	def.speed = 200.0
	# Waits unclocked until she is this close (`EventDef.notice`): inside VIEW_HALF_EXTENT.y (180px)
	# with room to spare, past outer_radius (60px).
	def.notice = NoticeSpec.at(150.0)
	# Shared with `alley_robbery`'s own weight: the two rows draw from the same `ALLEY`-only pool
	# and neither should be favoured over the other when both are offered the same tile.
	def.weight = 1.5
	def.max_per_day = 4
	return def

## Stationary, loud, and *pulsing*: the intensity envelope means the counterplay is timing a pass
## between yells, a different skill from routing around a hazard.
##
## He **paces** (`EventDef.paces`), a design decision rather than polish: a stationary source is a
## fixed price on a fixed patch of sidewalk, a line you draw once and never think about again. A man
## walking up and down two hundred and fifty pixels of footway is a *timing* problem on top of a
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
## wide core in a fraction of a second, where raising `intensity` over the *whole* field buys more
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
## that would go quiet. So `intensity` is **20**, `outer_radius` **170**: `walk_through_cost()` is
## **33.6**, a 1.4-point margin under `WALL_WORTH_OF_COST`, and the reach stays wide enough that a
## beat still turns up with nowhere to leave from.
##
## **Whether he is a wall is a fact about where his beat runs, not about his field.** He charges
## over a sidewalk from either lane, so the way past him is never a lane; it is somewhere his beat
## passes that she can **leave** by. A junction box is one (she takes the crosswalk while he is at
## the far end of his loop) and a side route off the sidewalk's own side is the other, so he is
## friction and stays on the route. A beat that passes neither leaves her nothing but walking
## through him, and that placement is a wall. `path_length_tiles` (8) against a block of
## `Tuning.BLOCK_SIZE` (8) is why the first is the ordinary case: a beat runs into a junction unless
## a closure, a calm zone's absorbed corridor or the map's own margin cuts it short.
## `StreetInvalidation._a_pacing_beat_walls_a_sidewalk` decides it, per placement.
static func _homeless_yeller() -> EventDef:
	var def := EventDef.new()
	def.id = "homeless_yeller"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.YELLER
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.shape = GroundShape.point(9.0)
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 20.0
	def.inner_radius = 45.0
	def.outer_radius = 210.0
	def.telegraph_time = 2.6
	def.pulse_period = 5.0
	def.mobile = true
	def.paces = true
	# A third of a walking pace: something that shuffles reads as somebody who lives on this
	# sidewalk rather than somebody crossing it.
	def.speed = 30.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	# Eight tiles of footway, walked in about eight seconds each way: long enough that where he is
	# now is worth looking at, short enough that it is still *a place he is*.
	def.path_length_tiles = 8
	# `paces` never reaches the end of its own path and he carries no `duration`, so he leaves only
	# when the resistance hands him a note (`EventInstance.leave_for_a_completed_task()`); this is
	# that departure's speed, not his pacing shuffle. Faster than the shuffle, so the note visibly
	# changes what he is doing, and well under her `Tuning.WALK_SPEED` (92px/s), so following him
	# out is never the fast way home.
	def.departs_at = 60.0
	def.weight = 2.0
	def.max_per_day = 18
	return def

## Slow, and it owns the sidewalk it is on.
##
## **The intensity is the wall, and it has to beat the walking decay.** At 7 what it means along a
## line through the middle falls under the 6.0/s an ordinary street gives back, so walking *through*
## a dog walker beats walking around it. An obstacle cheaper to walk into than to avoid is not an
## obstacle; this row is for being worth turning round and crossing at the crosswalk for.
##
## **Not given an `obstructs_radius`**: a mobile static body wide enough to matter on a two-tile
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
## because the row sits off the corridor is the decision this row exists to be. So `intensity` is
## only as high as the `WALL` line allows; `walk_through_cost()` is **33.3**, a 1.7-point margin
## under the 35 line. Open to overturn: whether that trade is right, or whether the far reach should
## come down as `homeless_yeller`'s did.
static func _dog_walker() -> EventDef:
	var def := EventDef.new()
	def.id = "dog_walker"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.DOG_WALKER
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	# The walker's own point, not the dog's: the dog on its lead is a per-part shadow drawn at its
	# own literal radius, as the abduction's victim or the checkpoint hut's guard, since a two-body
	# composite has no single shape to be either of its bodies.
	def.shape = GroundShape.point(8.0)
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 33.0
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
	# that cannot be allowed to thin out: dog walkers and cafe frontages are what an ordinary street
	# is mostly made of, where a loose dog and an ice cream van are punctuation.
	def.weight = 4.5
	# **The dog-walker decision has to happen at least twice on day one**, the density target
	# stated as one row; a cap in single figures makes it a coin flip. Repeats are fine, and
	# `EVENT_SPACING_SAME` answers two of them thirty pixels apart.
	def.max_per_day = 26
	return def

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
## a kernel, so the radii are read off the body and the street: `inner_radius` is `shape.radius +
## PLAYER_BODY_RADIUS` (24 + 14 = 38), she is touching the tables; `outer_radius` is the sidewalk
## band's centre to the carriageway's centre line (`SIDEWALK_WIDTH·TILE_SIZE/2 +
## ROAD_WIDTH·TILE_SIZE/2` = 32 + 32 = 64), so it bills somebody at the tables and not somebody
## across the street, "across" beginning at the centre line.
static func _cafe_tables() -> EventDef:
	var def := EventDef.new()
	def.id = "cafe_tables"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.CAFE
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 12.0
	def.inner_radius = 38.0
	def.outer_radius = 64.0
	def.telegraph_time = 1.6
	def.pulse_period = 6.0
	# 24 does not clear `GroundShape.BAND_RADIUS`, so the body it derives stays a point: a cafe
	# frontage this narrow has no spine to be a capsule about.
	def.solid(GroundShape.band(24.0))
	# Raised with `dog_walker` and for the same reason — see the note there.
	def.weight = 4.0
	# Only what is inside `EVENT_STREAM_RADIUS` ever exists, a fraction of the map, so a cap in
	# single figures puts the expected number of cafes she *sees* in a day under one, and the day-1
	# event built to force a crossing is absent from most day ones.
	def.max_per_day = 24
	return def

## Parked at the kerb, hazards going, half unloaded. Constant and stationary: the plain obstacle the
## route planning is practised on.
##
## **A parked van belongs at the kerb**, and on a `ROAD` tile it is scenery twice over: it stands in
## a traffic lane the crowd knows nothing about and drives straight through. At the kerb it is on
## the sidewalk she is actually using and it takes it: `VEHICLE_BODY` is 22px, so 44px of van across
## a 64px footway, and the answer is the other side of the street.
##
## **Silent**: static blockages should not raise excitement. Its whole job is standing in the way,
## and `obstructs_radius` already prices that as a route cost. It is one of `SealPlanner`'s
## soft-seal candidates, placed on every real street off the day's route tree, so an ambient field
## would bill several hundred bodies a day for nothing she could see or avoid.
static func _delivery_van() -> EventDef:
	var def := EventDef.new()
	def.id = "delivery_van"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.DELIVERY_VAN
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.pavement_side = EventDef.Pavement.AT_THE_KERB
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 150.0
	def.telegraph_time = 1.3
	# Under `GroundShape.BAND_RADIUS`, so the stationary-vehicle segment rule still reduces it to a
	# point (see `GroundShape.band()`).
	def.solid(GroundShape.band(VEHICLE_BODY))
	def.weight = 2.0
	def.max_per_day = 18
	return def

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
## `tests/probes/m128_park_beats.gd` simulates one busker, alone, at `inner_radius`, starting at the
## calm threshold with an empty sleep meter, for `Tuning.DAY_LENGTH_SECONDS` (210s) plus a margin.
## The sweep's bare crossing is 19.2 (exactly `12.0 / 0.625`, the beat-mean zero); every intensity
## below it fills within 200s and every one at or above it never does, and 19.3 sits a tenth above
## the line so the choice is not on the exact edge.
##
## **The radii are 45/190, and the street-side answer is the intensity's problem, not theirs**: the
## street-side reach moves only because 19.3 is louder, not because the field is a different size.
## Quieter from the street is not what this number buys; the probe has the figures.
static func _busker() -> EventDef:
	var def := EventDef.new()
	def.id = "busker"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.BUSKER
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.first_day = 2
	def.placement = [GameEnums.TileType.PARK, GameEnums.TileType.SQUARE]
	# The lowest tenth, with a small margin above the sweep's own crossing, whose day never fills
	# a sleep meter standing at his own core (see the note above).
	def.intensity = 19.3
	def.inner_radius = 45.0
	def.outer_radius = 190.0
	def.telegraph_time = 1.7
	def.pulse_period = 7.0
	def.solid(GroundShape.point(PERSON_BODY))
	def.weight = 2.0
	# Kept the lowest of the act I caps on purpose: a busker is placed on PARK or SQUARE, the
	# only calm ground there is, and the calm ground the day keeps clear refuses every one that
	# would reach it.
	def.max_per_day = 10
	return def

## The widest body in Act I. It fills the sidewalk band it stands on, which makes it a **wall**
## although it is silent and cheap to walk past: a band with no lane left has no line along it,
## whatever the meter says. A street is sidewalk|road|sidewalk, so the road is always still there
## and it costs time and exposure, never the day.
##
## **Silent**: a hoarding is not a source but a thing to walk around, and `obstructs_radius`
## already prices the detour. It is one of `SealPlanner`'s soft-seal candidates, so it stands on
## every real street off the day's route tree; an ambient field would bill the meter for a wall of
## boards a street away with nothing to point at.
static func _construction() -> EventDef:
	var def := EventDef.new()
	def.id = "construction"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.ROADWORKS
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.first_day = 2
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 0.0
	def.inner_radius = 46.0
	def.outer_radius = 200.0
	def.telegraph_time = 1.8
	# `SIDEWALK_SPREAD_MAX`: the widest silhouette that reads as roadworks is 2px over the full
	# sidewalk band `EventInstance.setup()` centres it on.
	def.solid(GroundShape.band(SIDEWALK_SPREAD_MAX))
	def.weight = 1.5
	def.max_per_day = 15
	return def

## Audible from streets away, moving fast down an arterial road, and it parks at the fire
## `burning_building` calls it in for and stays there for the rest of the day. Long telegraph,
## because the point of the approach is that you hear it coming and have time to get off that
## street.
##
## Never scheduled directly: a SCRIPTED def with no day, created only once the fire has been seen
## (`EventDef.aftermath.on_sight`, `EventSpawner.summon_what_has_been_sighted()`), so the player
## encounters the burning building before the engine.
static func _fire_truck() -> EventDef:
	var def := EventDef.new()
	def.id = "fire_truck"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.FIRE_ENGINE
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	# **The body is the drawing's ground contact**: 58px long (`fire_engine.svg`, x 2 to 60, bumper
	# to bumper) and 26px wide (`fire_engine_front.svg`, x 4 to 30, flank to flank), a capsule laid
	# along its heading, the patrol car's own construction, which `vehicle` makes the body. It is
	# lethal only in front of it while it drives its route, and solid and harmless once it has
	# parked at the kerb (`is_parked` is not driving).
	def.shape = GroundShape.segment(16.0, 13.0)
	def.vehicle = VehicleSpec.new()
	# Its field stays a point's, priced from its centre: the body is not a reason for the street
	# beside the parked engine to cost more (`VehicleSpec.field_from_its_centre`).
	def.vehicle.field_from_its_centre = true
	def.intensity = 26.0
	def.inner_radius = 70.0
	def.outer_radius = 340.0
	# The engine's whole warning: the badge goes up alone the moment the fire is seen and the engine
	# is created just out of sight on its road when this is over (see
	# `EventSpawner._summon_the_sighted_row()`). A second, `Tuning.WARNING_ALONE_MAX`, the most a
	# badge is up with nothing in the world (inbox #569 in busy-quail); its field already covers her
	# where it is created, so that second is the whole of what the contract's flat
	# `Tuning.OFFSCREEN_WARNING_MIN` measures.
	def.telegraph_time = Tuning.WARNING_ALONE_MAX
	def.warned_first = true
	def.mobile = true
	def.speed = 190.0
	# And it stays at the fire once it gets there (`EventDef.stops_where_it_arrives`): the standing
	# field beside a fire she was led to, and the pair of them, is a street she is meant to turn
	# round rather than walk down.
	def.stops_where_it_arrives = true
	return def

## Act I's finale, and the day's own one-shot: a building alight on a sidewalk, with the engine
## called in the moment she first sees it (`aftermath.on_sight`).
##
## **It is on her way, because the day sites it from the walk she is taking.**
## `EventDef.on_her_way` leaves the plan without a position at dawn and
## `EventDirector.site_what_is_on_her_way()` puts it on a building face ahead of her heading once
## her direction for the day is clear: the fire comes first and is on her way guaranteed. A set
## piece sited anywhere in the city is a day-3 that can pass without a fire in it and without an
## engine.
##
## **The fire itself has no field and costs nothing to stand beside or walk through** (PLAYTEST-144
## 12): the challenge is the fire truck, not the fire. `intensity` is 0.0 and it carries no
## `obstructs_radius` (`EventDef.solid()`: a look that does not obstruct sets `shape` alone), so
## `FireLook._draw_fire()` paints the flames and smoke on the facade of the building it stands
## against rather than leaving a body on the sidewalk, and `draws_body_shadow` is off so nothing
## casts a shadow at the ground point. `inner_radius`/`outer_radius` (60/260) and the 2.2s telegraph
## keep the row's geometry inside the fairness contract (`Tuning.validate_event()`), which checks
## every row the same way whether or not the field emits (`(outer_radius - inner_radius) /
## WALK_SPEED` = 2.17s). The `burnt_shell` scar it leaves is the
## building it burned, drawn burnt from the next morning on. **The finale's own fire, inside the
## building on the last night, is a duplicate of this row with a field and a body**
## (`building_fire()`), because in there the fire is the hazard and there is no truck to call.
##
## **It always catches on a wall the city actually draws**, since the building itself is shown burnt
## afterwards (`CityFronts.mark_the_burnt_frontage()`, `Building.Condition.BURNT`).
## `AGAINST_THE_BUILDING` only sites against an east-or-west wall
## (`EventScheduler._wants_this_side()`'s default branch), never a wall `building.gd` draws a facade
## on: every building is extruded south from its lot's south edge. `AT_THE_FRONT`, "the one face of
## a building the city draws" (`EventDef.Pavement`), is therefore this row's placement choice. A
## proposal, open to overturn if a fire that can also catch on the un-drawn walls matters more than
## a burnt shell with a real facade behind it. **Never on the power station's front**
## (`EventScheduler._burns_its_front()`): its facade does not draw burnt, and its transformer yard
## has no wall to burn.
static func _burning_building() -> EventDef:
	var def := EventDef.new()
	def.id = "burning_building"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.ONE_SHOT
	def.look = EventDef.Look.BURNING_BUILDING
	def.stands_as = EventDef.StandsAs.NOTHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.first_day = 3
	def.last_day = 3
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.pavement_side = EventDef.Pavement.AT_THE_FRONT
	def.on_her_way = OnHerWay.new()
	def.intensity = 0.0
	def.inner_radius = 60.0
	def.outer_radius = 260.0
	def.telegraph_time = 2.2
	# A shape with no `obstructs_radius`: `EventDef.validate()` requires a shape wherever there is a
	# look to draw, but nothing stands here to be solid, and no shadow is drawn (`draws_body_shadow`).
	def.shape = GroundShape.point(30.0)
	def.draws_body_shadow = false
	def.aftermath.scar = "burnt_shell"
	def.aftermath.on_sight = "fire_truck"
	return def

## What is left the next morning, and every morning after, never repaired: the building the fire
## caught on, drawn burnt. The building carries it, not an object on the sidewalk in front of it:
## `CityFronts.mark_the_burnt_frontage()` turns the one `Building` behind the scar
## `Building.Condition.BURNT`, and `EventInstance` draws nothing for this row. Almost silent: a
## reminder rather than a hazard, on the same corner on day 12 as on day 4.
##
## **It has no body.** A body is half a silhouette (`docs/EVENTS.md`, "Solid things are solid"), and
## there is no silhouette on the sidewalk to be half of: the burnt shell is the lot, which the
## building's own collision already closes. The shape stays, with no `obstructs_radius`, because it
## is what the 2.5/s field is measured from: a band along the frontage rather than a point, so the
## smell of smoke runs the length of the burnt front.
##
## **Radii from the band.** Both lose the segment's own `half_length` (12, from `band(36)`) so the
## along-axis reach is the 30/90 the row is priced at: `inner_radius` 30 → 18, clamped to 24,
## `outer_radius` 90 → 78.
static func _burnt_shell() -> EventDef:
	var def := EventDef.new()
	def.id = "burnt_shell"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BURNT_SHELL
	def.stands_as = EventDef.StandsAs.NOTHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.intensity = 2.5
	def.inner_radius = 24.0
	def.outer_radius = 78.0
	def.telegraph_time = 0.7
	def.shape = GroundShape.band(36.0)
	def.draws_body_shadow = false
	return def

# ----------------------------------------- Act I: variety, and two with teeth ---
# **Act I has to escalate, and its danger is the neighborhood's own.** With every `hard_fail` row
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
## row is meeting it. It is not `EventDef.pursuit`: it does not adjust to her or stop at a
## stand-off; it is a straight line down the sidewalk that she answers by crossing the street or
## turning.
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
## (`EventDef.telegraphs`). The director sends it down her own sidewalk and it is created at once
## just out of sight there (`PendingWarning.down_her_line()`, `EventsAhead._send_down_her_line()`),
## its `telegraph_time` already spent, on the point of its beat that has it reach her at its loudest
## (`EventSpawner.age_when_warned()`), so a pass costs what it did under a warning. It is outside
## the telegraph contract rather than exempted from it.
static func _loose_dog() -> EventDef:
	var def := EventDef.new()
	def.id = "loose_dog"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.LOOSE_DOG
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.trails_a_lead = true
	def.shape = GroundShape.point(9.0)
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.spawn_mode = EventDef.SpawnMode.TOWARD_PLAYER
	def.intensity = 39.0
	def.inner_radius = 30.0
	def.outer_radius = 140.0
	# Spent before it is ever met (see above); it decides only where its beat starts.
	def.telegraph_time = Tuning.WARNING_ALONE_MAX
	def.telegraphs = false
	def.pulse_period = 2.2
	def.mobile = true
	def.speed = 132.0
	# The other half of day 1's wall pool; see `leaf_blower` for the measurement both numbers came
	# out of. Between them they are what "leaving the path should be lethal or very expensive" can
	# be built from on the one day the game has nothing lethal in it at all.
	def.weight = 3.0
	def.max_per_day = 24
	return def

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
## into a real segment), so the pair is identical: `inner_radius` = 24 + `PLAYER_BODY_RADIUS` (14)
## = 38, `outer_radius` = 64. The two rows differ in body and intensity, not in reach.
static func _market_stall() -> EventDef:
	var def := EventDef.new()
	def.id = "market_stall"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.STALL
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 14.0
	def.inner_radius = 38.0
	def.outer_radius = 64.0
	def.telegraph_time = 1.7
	def.pulse_period = 8.0
	def.solid(GroundShape.band(28.0))
	def.weight = 1.6
	def.max_per_day = 13
	return def

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
## **The core is the sidewalk it stands on.** `core_radius` is `Tuning.SIDEWALK_WIDTH *
## Tuning.TILE_SIZE` (64px), a sidewalk's own width: the smallest radius that holds the whole
## footway from anywhere on it, and from the kerb-side tile (the worst one) it stops short of the
## far kerb, so the thing closes one side of a street and never the street. A line past the core at
## `core_radius` costs what the same line past a busker costs.
##
## **`core_intensity` anchors `EventScheduler.WALL_WORTH_OF_COST`'s line**, re-derived against the
## 6.0/s walking decay with `tests/probes/m174_pass.gd`'s walk-past simulation (the source held
## still, since this row never paces). A pass at 0/20px of lateral offset, the ground a sidewalk
## offers once the body (11px) and her width are cleared, nets back to within a few percent of what
## it netted against a 3.5/s decay; the widest offset tested (40px) recovers most of it rather than
## all, the smaller of two costs weighed against raising a wall row's number further than the line
## needs. `walk_through_cost()` is the number re-derived against, comfortably past
## `EventScheduler.WALL_WORTH_OF_COST`, which that constant explains alongside `dog_walker`'s.
static func _leaf_blower() -> EventDef:
	var def := EventDef.new()
	def.id = "leaf_blower"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.LEAF_BLOWER
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.PARK,
			GameEnums.TileType.SQUARE]
	# The busker's field exactly (see `_busker()` for how 19.3 over 45/190 was measured).
	def.intensity = 19.3
	def.inner_radius = 45.0
	def.outer_radius = 190.0
	def.core_intensity = 35.0
	def.core_radius = float(Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE)
	def.telegraph_time = 1.8
	# Swept in bursts rather than held, so there is a rhythm to time a pass through, as
	# `homeless_yeller` has, at a scale that makes a whole corner of a park unusable.
	def.pulse_period = 4.0
	def.solid(GroundShape.point(PERSON_BODY))
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
	def.weight = 3.0
	def.max_per_day = 24
	return def

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
## **The telegraph contract is then paid in geometry, as the robber's is.** `EventDef.notice` is the
## wait: the birds stand there unclocked and quiet, and the clock starts when she comes inside the
## trigger rather than at dawn, four streets away. It is the shape `alley_mouse` and a `MAP`-placed
## `charging_dog` use, and it keeps "it must not be over before she arrives" true without siting the
## row on top of her.
##
## **The birds go up when she reaches them, which a clock cannot know.** They are on the ground for
## the whole telegraph by construction, so under the clock alone a walk straight in put them up
## about 84px past her. `EventNoticeRun` fires the burst at `flock_spread` plus her own body, the
## distance at which she is among the birds rather than near them, as a pursuer's lunge is fired by
## her reaching its stand-off.
##
## **`telegraph_time` is 1.7s and is the backstop rather than the wait.** It only decides a flock she
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
## - It must not be **deleted at the top of its climb**, which is what `EventDef.departs_at` is for.
## - The **birds** have to move, not just the event. Copies of one sprite at fixed offsets sharing a
##   single `rise` term go up in one movement and hang in the air for the whole burst.
##
## So it is `flock_size` birds, each with its own heading, speed, height and wingbeat, each an
## emitter in its own right (see `EventInstance`, "the flock"):
##
## - **The intensity is a total to be shared out**, so it buys eleven overlapping fields rather than
##   one: walking round the edge meets one bird, through the middle five. It is the third loudest
##   thing on an act I sidewalk at the centre and nearly free at the rim.
## - **`flock_spread` comes out of `outer_radius`, not on top of it.** A bird emits over
##   `outer_radius - flock_spread`, so the union of eleven moving fields is inside the one disc the
##   fairness contract was checked against. The telegraph is still measured against 168px.
## - **It fades as they climb.** `intensity_ramp` is the burst being loudest at the instant they go
##   up, which also earns it a caret for the whole burst rather than only the telegraph: a flock is
##   danger that changes over time, the one thing the mark is for.
static func _pigeon_flock() -> EventDef:
	var def := EventDef.new()
	def.id = "pigeon_flock"
	# It does not telegraph its coming (`EventDef.telegraphs`): the birds go up where she walks in
	# rather than coming at her, and they cannot end the day; no badge, outside the telegraph
	# contract.
	def.telegraphs = false
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.BIRDS
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	# A flock has no single body (each bird casts its own shadow at its own faded radius, see
	# `FlockLook._draw_birds`), so this is a nominal point at one bird's base radius (5.0, before the
	# height fade), carried only to satisfy "a row with a look has a shape". A flock never obstructs;
	# `EventDef.validate()` refuses one that tries.
	def.shape = GroundShape.point(5.0)
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE,
			GameEnums.TileType.PARK]
	def.spawn_mode = EventDef.SpawnMode.MAP
	# The wait: inside the 168px field, so the clock starts on ground she is already being charged
	# for, and more than twice the 62px wheel, so the flock is already counting by the time she is
	# near the birds. Its quiet notice (`NoticeSpec.quiet`) damps the wait and the telegraph by the
	# same fraction: birds on a sidewalk are nearly nothing, and a flock nobody has walked up to
	# must not be a place she cannot walk past.
	def.notice = NoticeSpec.at(150.0)
	def.notice.quiet = true
	def.intensity = 42.0
	def.inner_radius = 26.0
	def.outer_radius = 168.0
	# Eleven of them over a 62px wheel: enough that the middle is unmistakably a crowd of birds and
	# few enough that a player can see the gaps between them and aim at one.
	def.flock_size = 11
	def.flock_spread = 62.0
	def.intensity_ramp = 0.4
	def.duration = 4.0
	# On the ground the whole time, which makes this a thing to walk around rather than a thing that
	# happens. Over the 1.55s the contract asks of a 168px field, measured from the moment it
	# notices her (`EventDef.notice`). The backstop for a flock she passed without reaching; the
	# flush at the birds ends it for one she walked into.
	def.telegraph_time = 1.7
	# Faster than she can run, and up: they are gone in a second and a half and they are gone
	# *somewhere*.
	def.departs_at = 190.0
	def.weight = 1.5
	def.max_per_day = 5
	# **A flock is scenery, not a block** (PLAYTEST-71). Left unset, a 42-over-168px field crosses
	# `EventScheduler.WALL_WORTH_OF_COST` and `EventScheduler.role_for()` would call this a `WALL`, pulling it off
	# every route; `Role.SCENERY` answers `NONE` first, so it lands on a route corridor exactly as
	# it lands anywhere else.
	def.role = EventDef.Role.SCENERY
	return def

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
## badge with nothing in the world, pointing down her line, and when his `telegraph_time` is over he
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
## **`inner_radius` is 33px, not the 26 a bike's own width would suggest** (PLAYTEST-25 7). 26px sits
## *under* the 32px spacing between the two lanes of a two-tile sidewalk (`Tuning.TILE_SIZE`, a lane
## on its own tile centre), the same gap that let `chatting_mother`'s `detain_radius` be walked past
## on the far lane (see that row). Both are "it catches you" rows that caught nobody, and both are
## 33px or more: past the lane spacing and under `outer_radius`, so the far lane of her own sidewalk
## does not answer a bike coming down it for free.
##
## Day 2 rather than day 1 on purpose: day 1 may be easy as long as the difficulty then climbs, and
## day 2 is the day the streets acquire something that can take the day off you.
##
## About one rider in 400 is drawn as a pelican on the same bike (`EventSpawner.rolls_a_pelican()`),
## and nothing else about him changes: the pelican is a picture, never a row of its own.
static func _cyclist() -> EventDef:
	var def := EventDef.new()
	def.id = "cyclist"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.CYCLIST
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.may_be_a_pelican = true
	def.shape = GroundShape.point(12.0)
	def.first_day = 2
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.spawn_mode = EventDef.SpawnMode.TOWARD_PLAYER
	def.intensity = 18.0
	def.inner_radius = 33.0
	def.outer_radius = 90.0
	# His warning, run before he exists: the screen-edge badge goes up alone, with nothing in the
	# world, for `Tuning.WARNING_ALONE_MAX` (a second; inbox #569 in busy-quail), and he is created
	# just out of sight when it is over (`PendingWarning`). What the contract holds is the
	# badge-to-reach time, `EventDef.warning_time()`, against the flat
	# `Tuning.OFFSCREEN_WARNING_MIN`: this, plus 0.57s for him to close from where he is created
	# closest (180px) to his 33px reach at 257px/s with her
	# walking into him.
	def.telegraph_time = Tuning.WARNING_ALONE_MAX
	def.mobile = true
	def.speed = 165.0
	def.hard_fail = true
	def.weight = 1.5
	# Well under the ordinary act I rows, and the cap does different work than its number suggests:
	# `TOWARD_PLAYER` never puts it on a tile, so it cannot tile a street. What the cap bounds is how
	# many of the moments she is owed (`EventScheduler.MOMENTS_PER_DAY`) are cyclists rather than cats
	# and dogs, and `EventDirector.AHEAD_INTERVAL` (11-26s apart) throttles the rest: the director draws one
	# owed row at a time from a shared queue with the cat and the dog, so how many she can meet is
	# bounded by the day's length long before the cap is.
	def.max_per_day = 14
	return def

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
	var def := EventDef.new()
	def.id = "ice_cream_van"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.ICE_CREAM_VAN
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
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
	return def

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
	var def := EventDef.new()
	def.id = "reversing_lorry"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.LORRY
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
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
	# `lorry.svg` is 62px across, and 28 + her own 14 is inside the 46 that ends the day, so the
	# metal is solid and touching it is still fatal (`EventDef.validate()` makes that arithmetic a
	# rule).
	def.solid(GroundShape.point(28.0))
	def.hard_fail = true
	def.weight = 1.2
	# A lethal wall row, capped like `cyclist` for the same reason: the deep band off the corridor is
	# where the deadly end of the gradient lives, and a handful across 121 blocks cannot fill it.
	def.max_per_day = 12
	return def

## Another mother with a pram, on her own beat, with her own cost model: getting too close catches
## one up in a conversation that takes 5s and consumes 25% excitement; if the baby is already
## sleeping it is a pure time loss, if not it bears overstimulation risk (PLAYTEST-18 4).
##
## **A paced sidewalk fixture, like `homeless_yeller`**: she is *at* a place rather than passing
## through it, and pacing guarantees streaming actually meets her. Her ambient field is
## person-scale (`intensity` near a passer-by's `CrowdExcitement.PEDESTRIAN_INTENSITY`, 4.2) and its
## `outer_radius` is tight, so brushing past her without triggering a conversation costs about what
## an ordinary close pass does.
##
## **The conversation is a trigger rather than a field**: entering `detain_radius` of an instance
## that has not yet chatted locks the stroller's movement input for `detain_seconds`
## (`Stroller.detain()`), and the meter cost during that lock is priced entirely by
## `EventInstance.current_intensity()` reading the baby's state, never by anything authored here.
##
## **`detain_radius` is 48px, three quarters of the 64px sidewalk band** (PLAYTEST-25 4). The whole
## content of this row is that she catches you, so a radius the far lane clears by construction is
## a row with a free answer: 26px sat under the **32px** spacing between the two lanes of a
## sidewalk (`Tuning.TILE_SIZE`), and 33px, just past it, was still too small. 48px reaches from
## either lane of her own sidewalk to the frontage, so no line on her sidewalk walks past her, while
## the far sidewalk, 96px away centre to centre, still does. **`inner_radius` is 56** because
## `EventDef.validate()` requires the capture to sit strictly inside the inner radius (the chat's
## flat rate assumes she is inside it), so widening the capture widens the full-cost core with it,
## by a lane's width, which is small next to what the conversation costs. `outer_radius` is 70.
##
## `first_day` 1: act I is the social act, and `test_balance.gd` passes with her live on it, since
## she is `SIDEWALK`-only and never contests the calm ground the balance suite measures.
static func _chatting_mother() -> EventDef:
	var def := EventDef.new()
	def.id = "chatting_mother"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.CHATTING_MOTHER
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.shape = GroundShape.point(14.0)
	def.first_day = 1
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 4.5
	def.inner_radius = 56.0
	def.outer_radius = 70.0
	# (70-56)/92 = 0.15s required; not hard_fail, so no doubled margin. Generous rather than tight,
	# since the ambient field is nearly nothing next to what the conversation costs.
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
## a tile like `alley_robbery`, waiting inside its own field for her (`EventDef.from_day_after`);
## and `EventDirector` now and then still sends the day-3 shape itself (warned first from off
## screen, already noticing her, no tip), `EventDirector.CHARGING_DOG_SPRINKLE_CHANCE` of the time
## on a day it is eligible. One `EventDef` answers both, since neither changes what the row *is*,
## only whether she is routed into it or walks into it while going about her day.
static func _charging_dog() -> EventDef:
	var def := EventDef.new()
	def.id = "charging_dog"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.CHARGING_DOG
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.warning_picture = EventDef.WarningPicture.DOG_ALERT
	def.shape = GroundShape.point(13.0)
	def.first_day = Tuning.RUN_TAUGHT_DAY
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	# No `last_day`: the dog recurs after the teaching day rather than being spent by it. On
	# `RUN_TAUGHT_DAY` itself `spawn_mode` is `AHEAD_OF_PLAYER` and `EventDirector` puts it dead
	# ahead of her, because the lesson depends on it. Every day after, `spawn_mode_on()` answers
	# `MAP`: placed on a tile as `alley_robbery` is and met by routing into it. One `EventDef`
	# rather than a second row: a later dog needs its own `Look` and there is no spare silhouette
	# (`tests/test_events.gd` refuses two rows sharing one), and `spawn_mode_on()` is the
	# field that lets one row answer two days without ever mutating the shared resource.
	def.spawn_mode = EventDef.SpawnMode.AHEAD_OF_PLAYER
	# From the day after the lesson it is a place on the map that waits for her inside its one
	# radius, 130px, inside its 150px field (inbox #788 in minty-lemur). `EventDef.for_day()` hands
	# a placement past the switch a copy carrying it.
	def.from_day_after = DaySwitch.new()
	def.from_day_after.after_day = Tuning.RUN_TAUGHT_DAY
	def.from_day_after.spawn_mode = EventDef.SpawnMode.MAP
	def.from_day_after.notice = NoticeSpec.at(130.0)
	def.intensity = 12.0
	def.inner_radius = 26.0
	# Wider than the stand-off, a constraint rather than a taste: a pursuer holds its stand-off
	# through its whole telegraph, so a field narrower than that is a field it is never inside; the
	# dog would spend the entire warning emitting nothing at her, the `!` over her head would never
	# go up, and the trace would attribute the mark to "nothing in reach". `validate_pursuit`
	# refuses the arrangement.
	def.outer_radius = 150.0
	# The chase proper, once it can end the day: `Tuning.PURSUIT_TIME`, a long cap rather than an end
	# a walk can outlast. Running is what ends it, at `Tuning.PURSUIT_SHAKEN_OFF`'s rate.
	def.duration = Tuning.PURSUIT_TIME
	# Its approach, spent visibly closing once it is placed just out of sight: the gold timing's
	# on-screen part, which `tests/test_events_pursuit.gd` fails on if it moves. Comfortably over
	# `PURSUIT_MIN_NOTICE`: walking away from the day-3 dog, the lunge never fires (she keeps
	# opening the gap it closes to), so the chase starts when this runs out, and this and
	# `duration` are what catch a walker. The dog that waits for her past the teaching day does not
	# read it: it warns by radius (`EventInstance.warns_by_radius()`).
	def.telegraph_time = 4.5
	def.pursuit = PursuitSpec.at(130.0)
	# From day 4, once it notices her, it warns on the clock every charger that waits for her keeps
	# and stands in its alert pose rather than closing (woolly-penguin #748); the day-3 dog has no
	# wait, so its approach is still its telegraph (`EventInstance.is_standing_for_its_notice()`).
	def.pursuit.warns_for = CHARGER_WARNING
	def.pursuit.stands = true
	# Its badge alone, sent at her down her heading, before it is placed just out of sight
	# (`EventDef.warned_for()`): half a second, the gold timing's off-screen part (see
	# `EventDef.offscreen_notice`).
	def.offscreen_notice = 0.5
	# And it trots off rather than blinking out: a dog that gives up in front of her and then is not
	# there says the chase was never real.
	def.departs_at = 110.0
	def.hard_fail = true
	def.weight = 1.4
	# Rare on purpose: it is the one thing running answers, and a street with three of them would
	# turn the run button into a second walk speed.
	def.max_per_day = 3
	return def

# ------------------------------------------------------- Act II: notices (4-7) ---

## Mobile, unhurried, and it stops. Its field is not the danger; the danger is that you start
## planning around it.
##
## **A car, solid and lethal the way a car is** (`EventDef.vehicle`; inbox #648 in leafy-puffin):
## she walks round its body whether it drives or stands, and it ends the day only in front of it,
## while it drives its route, with her on the carriageway.
##
## **The patrol rung of the resistance's ladder.** `heat_response = PRESSES`: with
## `RunState.resistance.progress`, more of them and louder, and past
## `EventDef.HEAT_INVESTIGATES_LEVEL` it stops merely patrolling and starts investigating: it stops
## on its road once she is close and a policeman gets out and pursues her
## (`EventDef.investigates()`, `out_of_the_car()`), whose catch costs her and never ends the day by
## itself. The car never gains `hard_fail`, whatever the heat, and never strikes her while it
## stands for him; the unmarked van is the rung that hunts.
static func _police_patrol() -> EventDef:
	var def := EventDef.new()
	def.id = "police_patrol"
	# It does not telegraph its coming (`EventDef.telegraphs`): 74px/s is slower than a walk, and
	# its strike is a car's, warned the way a car warns (`EventDef.vehicle`) rather than with a
	# badge from off screen. Its copies (the return's down the road, the raid's pacing car and the
	# investigating one at heat) carry it with them.
	def.telegraphs = false
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.POLICE_CAR
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	# **The body is its drawn ground contact**: 42px long, the side view's body from bumper to
	# bumper (`police_car.svg`, x 2 to 44), and 24px wide, the end views' body from flank to flank
	# (`police_car_front.svg`, x 3 to 27), as a capsule laid along its heading, the datum its
	# shadow is drawn from. `vehicle` makes it the body as well.
	def.shape = GroundShape.segment(9.0, 12.0)
	def.vehicle = VehicleSpec.new()
	def.first_day = 4
	def.act_tag = 2
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 10.0
	def.inner_radius = 44.0
	def.outer_radius = 185.0
	# Slower than a walk, so the escape distance is the falloff band stretched forward by the
	# patrol's own eccentricity: `(outer_radius - inner_radius) · Field.scale(e)` at 74px/s
	# (e = 0.148) is 165px, 1.80s, plus the row's margin.
	def.telegraph_time = 1.97
	def.mobile = true
	def.speed = 74.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 40
	def.weight = 3.0
	def.max_per_day = 12
	def.heat_response = EventDef.HeatResponse.PRESSES
	# Past the threshold it stops for her and lets one man out (`HuntSpec.letting_out()`).
	def.hunts = HuntSpec.letting_out(1)
	return def

## Cosmetic dread. Barely moves the meter; it is here so the walls change.
##
## **`AGAINST_THE_BUILDING`, the way `reversing_lorry` stands.** A crew pastes posters at the wall
## it works on rather than in the middle of the sidewalk, and the placement answers the width rule
## as well as the picture: centred (the `ANY` default) an 11px body leaves under 28px on each side
## of the 64px band and is a wall by physical fit (`EventScheduler._closes_the_band_by_its_own_
## placement`); pinned to the frontage lane's tile centre, `TILE_SIZE * 0.5` from the wall, it
## spans 5-27px of the band and leaves 37px to the kerb, over the 28px she needs, so it stays
## friction. `_wants_this_side` narrows its `SIDEWALK` ground to north-south streets with a real
## building on the far side, as `reversing_lorry` does.
##
## **It is a sidewalk row only.** A square answers no `pavement_inward`, so there is no frontage
## lane on one for a crew to stand in; `poster_crew_square` is the square's own crew, at the column
## a square has instead of a wall.
##
## **It works on walls along the way she walks** (`EventDef.on_her_way`, `OnHerWay.at_a_front`;
## PLAYTEST-116). A crew placed anywhere in the city is a crew she never meets. So the day rolls
## and places its crews at dawn, by `pavement_side`, which keeps every other row the roll places
## where it was; `EventScheduler._hand_to_her_walk` then drops those positions, and her walk sites
## each crew, one at a time, on her branch of the day's routes, in front of a blank ground-floor
## cell and facing it, as day 3's fire is sited. Once in the world it stays, and `PosterWalls` has
## it paste its wall while it is in her view. Its field and cost are those of the dawn roll:
## making a crew charge the meter would change what the row is for.
static func _poster_crew() -> EventDef:
	var def := EventDef.new()
	def.id = "poster_crew"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.POSTER_CREW
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.first_day = 4
	def.act_tag = 2
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.pavement_side = EventDef.Pavement.AGAINST_THE_BUILDING
	def.on_her_way = OnHerWay.new()
	def.on_her_way.at_a_front = true
	def.intensity = 5.0
	def.inner_radius = 30.0
	def.outer_radius = 110.0
	def.telegraph_time = 1.0
	def.solid(GroundShape.point(PERSON_BODY))
	def.weight = 2.5
	def.max_per_day = 12
	return def

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
	var def := EventDef.new()
	def.id = "poster_crew_square"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.POSTER_CREW_SQUARE
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.first_day = 4
	def.act_tag = 2
	def.placement = [GameEnums.TileType.SQUARE]
	def.intensity = 5.0
	def.inner_radius = 30.0
	def.outer_radius = 110.0
	def.telegraph_time = 1.0
	def.solid(GroundShape.point(PERSON_BODY))
	def.weight = 0.03
	def.max_per_day = 1
	return def

## A mast on a street, with a field around it: six of them, planted by `MastSites` and placed every
## day from `Tuning.MAST_FIRST_DAY` by `EventScheduler._place_masts()` rather than by the ordinary
## catalogue roll. `scripted_day` stays 0, the seal pictures' own sentinel for "a planner places me
## directly, and `EventDef.available_on()` must never roll one" (see the seal table in
## `docs/EVENTS.md`). Its geometry is `homeless_yeller`'s (same inner and outer radius, same
## `falloff_power`), so walking straight past a speaking mast on its own sidewalk costs what walking
## past him does; `docs/COSTS.md` carries both rows and they agree by construction rather than by
## tuning.
static func _loudspeaker() -> EventDef:
	var def := EventDef.new()
	def.id = "loudspeaker"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.role = EventDef.Role.MAST
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.LOUDSPEAKER_MAST
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.act_tag = 2
	def.solid(GroundShape.point(MAST_BODY))
	def.intensity = 20.0
	def.inner_radius = 45.0
	def.outer_radius = 210.0
	def.telegraph_time = 3.0
	def.pulse_period = 22.0
	# `_place_masts()` places one at every site `MastSites.compute()` names, which is
	# `Tuning.MAST_COUNT` of them: not a roll's own cap, but the count of the city's sites, which is
	# what `tests/test_events.gd`'s `_test_scheduler_respects_placement_and_caps` reads it as. A day
	# can carry one more: the mast day 11 queued for her task (`EventManager.queue_a_mast()`), which
	# once she silenced it `_place_masts()` plans again from its scar on every later day.
	def.max_per_day = Tuning.MAST_COUNT
	return def

## What the masts carry on `EventScheduler.CURFEW_ANNOUNCE_DAY` instead of their ordinary broadcast:
## `EventScheduler._place_masts()` places one of these at every mast site that morning, alongside
## the mast's own `loudspeaker` instance, which keeps drawing the pole, the lamp and the arcs. This
## row is `Look.NONE` and adds only the field, as a park's own playground frame draws itself while
## `_playground()` merely prices it; the field has the shape of the mast's ordinary one.
## **Stronger than an ordinary broadcast**: intensity half again `_loudspeaker()`'s own.
static func _curfew_announce() -> EventDef:
	var def := EventDef.new()
	def.id = "curfew_announce"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.NONE
	def.stands_as = EventDef.StandsAs.NOTHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.act_tag = 2
	def.inner_radius = 45.0
	def.outer_radius = 210.0
	def.intensity = 30.0
	def.duration = 26.0
	def.telegraph_time = 2.0
	def.intensity_ramp = 0.2
	def.max_per_day = Tuning.MAST_COUNT
	return def

## Closes a street and is loud about it. The first event that takes a route away rather than making
## it expensive.
##
## **Named `roadblock`, not `checkpoint`.** The region door took that word (a hut, a gate and guards
## on the sidewalks you can pass at a price), and this row means the opposite: a street you cannot
## pass at all. Two rows drawing armed men across a street and meaning opposite things cannot share
## a name, any more than a silhouette.
##
## **Drawn as one continuous barrier, not a row of blocks** (PLAYTEST-55).
## `RoadblockLook._draw_roadblock()` repeats one segment capped by `EventPictures.ROADBLOCK_END`
## through `SpreadLook._draw_spread()`: the broadside `EventPictures.ROADBLOCK_SEGMENT`, or the
## end-on `EventPictures.ROADBLOCK_SEGMENT_VERTICAL` down a north-south column, the rail-with-caps
## construction `roadworks` reads as one thing. `art/events/checkpoint_block.svg` is the badge's own
## icon (`EventPictures.icon_for()`): a badge is read small, and the concrete-block silhouette is
## the clearest single frame of "a street being held".
##
## **Radii derived from the body, not carried across.** The field is a capsule about the body's own
## spine, so the along-axis reach from centre stays what it was and both radii lose the segment's
## own `half_length` (36, from `band(60)`): `outer_radius` 215 → 179. `inner_radius` is 86 and is
## bounded by nothing: it is where full strength ends and the falloff begins, and what the cost
## table is stated against.
##
## **`heat_response = HUNTS`, the rung `abduction` and `night_raid` climb**, and **two guards stand
## at the barrier from the moment it is placed**, one on each side of the band and clear of its
## picture. Cold they are drawings and nothing else: no field, no body and no cost of their own,
## all of which belong to the band. Once a heated copy notices her, **the guard on her side** sets
## off from his own post (the other cannot, being blocked) while the other stays standing at his:
## the instance becomes the man, and `PursuitSpec.leaves_its_body` pins the barrier's body and
## picture where it was built for the rest of the event's life. Nothing appears, nothing
## disappears, and the street he abandoned stays shut behind him.
##
## **His one radius is measured from the band's centre, and he charges on his warning's clock.** The
## radius stays on the band because it may not reach past the field, which is cored there. His post
## is nearer her than the centre, which costs her none of his warning: he charges once it has run
## with her still inside his radius, not at a distance from him
## (`EventInstance.warns_by_radius()`). His stand-off is measured from `lethal_reach()`, his 28px
## catch, the number `Tuning.validate_pursuit()` states the contract over.
##
## **The catch is a man's reach, not a barrier's.** `PursuitSpec.catch_reach` is 28px, read off
## `masked_pursuer`: the same fiction, the same distance at which a masked man takes the baby. It is
## separate from `inner_radius` because the field is a street being held, cored on the band, while
## what ends the day is a pair of arms. `EventDef.validate()` has nothing to say about the band's
## 60px body, as about any pursuer's: the man walks out of it before he can kill.
##
## **Intensity 0: the band costs nothing, manned or not, on a day and in the escape alike; the guard
## is the danger** (inbox #788 in minty-lemur). The band is concrete: it shuts the street with its
## 60px body and costs nothing to walk beside, while the guard posted at it warns her with his
## raised hand and catches her if she walks on into his charge. A region wall stands as hard seals
## of this row (`RegionPlanner._WALL_DEF_ID`), so a wall's bands cost nothing either; a door's own
## structures (`checkpoint_hut`, `checkpoint_gate`, `checkpoint_post`) keep their rates. The row
## keeps its radii: `outer_radius` is what the hunting guard's notice may not reach past and what the
## `SOON` mark over her is drawn out to. The resistance's checkpoint task ("Don't go around it this
## time. Go through") is priced by the body and by the guard.
##
## **`barrier_structure`, because one street being held is one source however many bodies hold it.**
## A region wall stands three of these a tile apart across a single street beside a region door's
## structures. The band adds nothing to that sum and keeps the flag so the boundary kit stays one
## source by one rule; see `EventDef.barrier_structure`.
##
## **The 179px cold field sits under the shared 180px trigger.** `EventDef.at_heat()` widens only
## the hunting copy's `outer_radius` to `maxf(outer_radius, EventDef.HEAT_HUNTS_WITHIN)`, the
## smallest fix that holds for every `HUNTS` row, so the cold field is what it was and only the
## moment the guard starts hunting reaches 180px. `tests/test_heat.gd`'s generic loop
## (`_test_a_hunts_row_wakes_up_at_its_own_threshold`) catches a row whose field sits under the
## trigger; this one is the row that found it.
static func _roadblock() -> EventDef:
	var def := EventDef.new()
	def.id = "roadblock"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.ROADBLOCK
	def.stands_as = EventDef.StandsAs.SOMETHING
	# `GOES_ON` and not `PARKS`: his guard leaves his post and gives chase, and `validate()` refuses
	# `PARKS` for a row that chases. The concrete band turns cars by its tiles.
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.has_a_spread = true
	def.first_day = 7
	def.act_tag = 2
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 0.0
	def.inner_radius = 86.0
	def.outer_radius = 179.0
	def.telegraph_time = 1.8
	def.solid(GroundShape.band(60.0))
	# **How his hunting copy pursues** (`EventDef.hunts`, `HuntSpec.pursuing()`, a catch that ends
	# the day): he catches at a man's reach, taken from `masked_pursuer` since the guard who leaves
	# this post and the masked man are the same figure, and warns at his post with his hand raised
	# (woolly-penguin #748) on the clock every charger that waits for her keeps.
	var chase := PursuitSpec.new()
	chase.catch_reach = MASKED_MAN_REACH
	chase.stands = true
	chase.warns_for = CHARGER_WARNING
	chase.leaves_its_body = true
	chase.warns_over_the_street = true
	def.hunts = HuntSpec.pursuing(chase)
	def.barrier_structure = true
	def.span_the_street()
	def.weight = 2.0
	def.max_per_day = 6
	def.heat_response = EventDef.HeatResponse.HUNTS
	return def

# --------------------------------------------------------- Act III: vans (8-11) ---


## An unmarked van idles first; that idling IS the telegraph, and it runs long because the inner
## radius ends the day. Getting close does not excite the baby; it takes you.
##
## **And it takes somebody else first.** While she is close enough to watch (`outer_radius`), it
## draws its own bystander walked to it and taken (`EventAbduction`). A scripted figure that belongs
## to the event, never a real `CrowdAgent`: the crowd is recycled as she moves, so a taken
## pedestrian could never be a lasting fact about the world. Drawing and telemetry only; nothing
## here changes `contribution_at()`, spawns a body, or reaches into the crowd.
##
## **`heat_response = HUNTS`, the lethal rung of the resistance's ladder, hunted on foot**
## (`EventDef.hunts`, letting men out). Below `EventDef.HEAT_HUNTS_LEVEL` it is untouched
## (population and intensity are `PRESSES`'s axes). At and above it, the derived copy stops idling
## for a stranger and hunts her with its men: it stays parked and solid, and once she is within
## `EventDef.HEAT_HUNTS_WITHIN` of it along a clear line it lets two men out at its door,
## `out_of_the_car()`'s hunting copy, whose catch ends the day (inbox #669 in coral-lark). The van
## keeps `hard_fail` throughout, so its own 54px still takes her once its telegraph is over, as the
## cold van's does. See `EventDef.at_heat()`.
static func _abduction() -> EventDef:
	var def := EventDef.new()
	def.id = "abduction"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.UNMARKED_VAN
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.abduction = AbductionSpec.new()
	def.first_day = 8
	def.act_tag = 3
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.CROSSING]
	def.intensity = 20.0
	def.inner_radius = 54.0
	def.outer_radius = 250.0
	def.duration = 34.0
	# hard_fail doubles the required margin: (250-54)/92 * 2 = 4.26s. It stays this long once the
	# van hunts: the hunting van is still a place she can walk out of, and its 54px takes her only
	# once this telegraph after its notice is over; its men carry their own notice.
	def.telegraph_time = 4.6
	# A van is a van: 22 + her own 14 leaves the 54 that takes her comfortably reachable, so the
	# body never shields her from the van's own reach. It keeps the body at every heat: hunting, it
	# stays parked and lets its men out (`EventDef.hunts`), so nothing about a moving wall applies.
	def.solid(GroundShape.point(VEHICLE_BODY))
	def.hard_fail = true
	def.weight = 2.0
	# The `hard_fail` caps rise with the rest, but by half as much: at one event per block the late
	# city should feel *occupied*, not landmined. Four unmarked vans across forty-nine blocks is one
	# every twelve; twelve would be a difficulty setting nobody asked for.
	def.max_per_day = 4
	def.heat_response = EventDef.HeatResponse.HUNTS
	def.hunts = HuntSpec.letting_out(2)
	return def

## **A man in an alley who is worth crossing the road for, and who comes after you if you do not.**
##
## **A tiny field on the argument that *the alley itself is the warning* goes nowhere**: a lethal
## radius of 26 inside a field of 42 does nothing until it does everything, which is fatal rather
## than merely dull. And a robber who never moves is avoidable by walking two tiles wide of him for
## ever.
##
## Three numbers for three sentences, in order:
##
## - **On sight.** 16 over a 200px field, so the far end of an alley is already expensive and the
##   meter is what tells you he is there, before he has noticed her at all.
## - **Getting close is day ending.** `hard_fail` inside 26px, and it has to be **reachable**: he
##   carries no body, because a pursuer with one is a moving wall, and because a body that reaches
##   the inner radius means the kill can never fire.
## - **Get close and he comes at you.** `EventDef.notice` 180, his one radius: inside that he
##   stands up, turns to face her and walks at her slowly, at 40px/s (`PursuitSpec.walk_speed`),
##   holding at his 116px stand-off, for his 2.0s warning (`PursuitSpec.warns_for`; inbox #788 in
##   minty-lemur), and if she is still inside his radius once it has run he lunges, and chases at
##   130px/s until she has shaken him off. **Turning round from his warning is an answer**: she
##   outwalks his slow walk, and once she is outside his radius he stops where he is and waits
##   there (inbox #764 in minty-lemur). Once he has lunged, walking away does not work and running
##   away does, which is `charging_dog`'s contract arriving in act III as a *place* rather than a
##   moment.
##
## The alley is the warning, and it is not the only one.
static func _alley_robbery() -> EventDef:
	var def := EventDef.new()
	def.id = "alley_robbery"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.ROBBER
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.warning_picture = EventDef.WarningPicture.ROBBER_ALERT
	def.shape = GroundShape.point(9.0)
	def.first_day = 8
	def.act_tag = 3
	def.placement = [GameEnums.TileType.ALLEY]
	def.intensity = 16.0
	def.inner_radius = 26.0
	# **The lunge is further out than the catch**: 38px + 130px/s × `PURSUIT_REACTION` = 116px,
	# while the catch is 26px. The stand-off is stated over `PursuitSpec.lunge_reach` rather than
	# the catch, so the room between his lunge and his catch is 116 − 26 = 90px rather than the 78
	# it would be if the lunge followed the catch (inbox #526 in azure-tapir: keep every rule at
	# 116px). The rule kept beside the 116px, that standing still he lunges no sooner than
	# `Tuning.PURSUIT_MIN_NOTICE` after he appears, is a standing robber's; the sent robber the
	# resistance's trap reads off this row arrives already chasing (`_robber_giving_chase()`), so
	# it has no closing-in for the floor to bound. Wider than the trigger, which is the contract
	# rather than a taste: he may not notice her from outside his own field, because the meter is
	# the only thing that says a stranger in an alley is worth crossing the road for. The twenty
	# pixels between this and his notice are the row's first sentence, **on sight**, with
	# somewhere to happen, and his slow walk is its second.
	def.outer_radius = 200.0
	# Read only by the pursuit contract's notice clause (`Tuning.validate_pursuit()`): no robber's
	# notice runs on it. One who notices her by sight warns for his `PursuitSpec.warns_for`
	# (`EventInstance.warns_by_radius()`), and day 13's guard set on her by the task has the task's
	# own second (`EventInstance.notice_her_at()`,
	# `ResistanceDirector._set_the_task_guard_on_her()`).
	def.telegraph_time = 1.8
	def.duration = Tuning.PURSUIT_TIME
	# The same speed as the charging dog, deliberately: a player who learned on day 3 what a thing
	# that comes after you moves like should not have to learn it again in act III.
	def.pursuit = PursuitSpec.at(130.0)
	def.pursuit.lunge_reach = 38.0
	# Outside his stand-off (116px) and inside his field, which leaves room for both halves of the
	# row: far enough out that his notice walk is seen, near enough that she has felt him before he
	# decides anything about her (inbox #761 in minty-lemur). 64px past his stand-off at the slow
	# walk below is about half a second of him walking for a walker coming in (64 / (40 + 92)) and
	# 1.6s for one who stops at the edge, and 180px is half the view's height; he notices her only
	# once his warning would stand in her view (`EventInstance._would_stand_in_her_view()`). 180px is
	# his one radius: he charges if she is still inside it once his warning has run
	# (`PursuitSpec.warns_for`, below).
	#
	# The trap: with a chase that ends at a *distance*, a trigger at or past that distance is a
	# pursuit that loses interest the instant it starts, and she can stroll away from him every
	# time. `Tuning.PURSUIT_SHAKEN_OFF` ends a chase at a rate instead, so no trigger distance can
	# reproduce it.
	def.notice = NoticeSpec.at(180.0)
	# **He walks at her slowly through his notice**, a man getting up off a wall rather than a man
	# already running: his chase is 130px/s, and closing at that from his trigger would be over in a
	# tenth of a second. At 40px/s, a little over the dog walker's 32px/s stroll, a stride beat
	# (`EventLook.gait_is_stepping()`, 17.5px of ground) lasts about 0.44s, near the 450ms the
	# walkers' two-frame pictures were reviewed at.
	def.pursuit.walk_speed = 40.0
	# **He charges once his warning has run with her still inside his radius**, on the clock every
	# charger that waits for her keeps (inbox #788 in minty-lemur), walking at her and holding at
	# his stand-off while he warns.
	def.pursuit.warns_for = CHARGER_WARNING
	# And he walks off when he has lost her, rather than being deleted where he stood.
	def.departs_at = 100.0
	def.hard_fail = true
	def.weight = 1.5
	def.max_per_day = 4
	return def

## **The robber a task sets on her: the alley robber, awake from his first frame, coming at her
## from off screen the moment she has done a task.** Every task but the van's, the roadblock's and
## the neighbor's sends him (`ResistanceDirector._sets_a_trap_on_her()`): the man shouting's note,
## the burnt building's door, the district door, a mast's foot, the swing and the last night's front
## door. Nothing places it but `ResistanceDirector._set_the_trap_on_her()`: `SCRIPTED` on day 0, the
## day nobody plays, so the roll, the stream and the bags never reach it; `EventDef.validate()`
## refuses a pursuer with no trigger on any other terms.
##
## **Warned first** (`warned_first`): the screen-edge badge is up alone, with nothing in the world,
## for the dog's half second (`offscreen_notice`), pointing where he will come from, and he is then
## created just off screen that way (`PendingWarning`), above or below her by preference.
## **And he arrives already chasing** (`PursuitSpec.Start.ARRIVES_CHASING`): no closing-in to a
## stand-off and no telegraph to spend (the proximity rule is only for standing robbers).
##
## **The same man, read off `_alley_robbery()` rather than copied beside it**: his body, his field
## (16 over 26–200px), his 130px/s, his 26px catch and the 116px lunge (`PursuitSpec.lunge_reach`),
## his `hard_fail` and the way he walks off once he has lost her. What differs is **no trigger**
## (`EventDef.notice` 0), so he is never `is_waiting()`, and his timing: the day-3 dog's badge and
## chase, read off `_charging_dog()`. His chase does not give up on a walker
## (`Tuning.PURSUIT_TIME`, a long cap); running for `Tuning.PURSUIT_SHAKEN_OFF` (0.35s) shakes him
## off, including while he is still offscreen.
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
## **His own look, `ROBBER_GIVING_CHASE`, drawing the alley robber's own pictures**, as `door_guard`
## draws a roadblock's guard: he never waits, so it is only ever the lunge, and the badge is the one
## view of it `ROBBER` does not already stand for.
static func _robber_giving_chase() -> EventDef:
	var alley := _alley_robbery()
	var def := EventDef.new()
	def.id = "robber_giving_chase"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.ROBBER_GIVING_CHASE
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.shape = alley.shape
	def.act_tag = 2
	def.intensity = alley.intensity
	def.inner_radius = alley.inner_radius
	def.outer_radius = alley.outer_radius
	# The day-3 dog's own timing, read off its row: its badge alone, its approach and its chase.
	var dog := _charging_dog()
	def.offscreen_notice = dog.offscreen_notice
	# No telegraph: he arrives already chasing.
	def.telegraph_time = 0.0
	def.duration = dog.duration
	def.warned_first = true
	def.pursuit = PursuitSpec.at(alley.pursuit.speed)
	def.pursuit.start = PursuitSpec.Start.ARRIVES_CHASING
	def.pursuit.lunge_reach = alley.pursuit.lunge_reach
	def.departs_at = alley.departs_at
	def.hard_fail = alley.hard_fail
	return def

## **The guard a task sets on her: the roadblock's own guard, awake from his first frame, coming at
## her from off screen the moment she hands the van's package over** (PLAYTEST-144 15). Nothing
## places it but `ResistanceDirector._set_the_trap_on_her()`, on the same terms as
## `robber_giving_chase`: warned first, then created just out of sight of her on walkable ground,
## `SCRIPTED` on day 0 so the roll, the stream and the bags never reach it.
##
## **The door guard, read off his row rather than copied**: his shape, his field (18 over a
## 28–120px band: `MASKED_MAN_REACH` inside `door_guard`'s own 120px), his `hard_fail`, and
## `Tuning.HEAT_HUNTS_SPEED` (130px/s), the figure `_alley_robbery()` hardcodes as the robber's own
## `PursuitSpec.speed`, so nothing about the chase differs from the robber row. What differs from
## `robber_giving_chase` is the picture, `EventDef.Look.VAN_GUARD_GIVING_CHASE`, drawn like
## `door_guard` and `masked_pursuer` (`guard_standing_*` then `guard_lunging_*`) but badged by the
## lunge's back view, the one picture of the man neither of theirs stands for; and the walk-off,
## copied from the robber row: `door_guard` never leaves his post, but this guard, like the robber,
## is a stranger in the street with nowhere to be once he has lost her, so he walks off at the
## robber's own 100px/s.
##
##
## **No trigger, and the robber row's own timing**: `EventDef.notice` stays 0.0, so he is never
## `is_waiting()`; he is warned first for the dog's half second, arrives already chasing
## (`PursuitSpec.Start.ARRIVES_CHASING`) and does not give up on a walker (`Tuning.PURSUIT_TIME`),
## identical to `robber_giving_chase`, since nothing about the timing is the picture's to change.
static func _van_guard_giving_chase() -> EventDef:
	var guard := _door_guard()
	var alley := _alley_robbery()
	var def := EventDef.new()
	def.id = "van_guard_giving_chase"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.VAN_GUARD_GIVING_CHASE
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.shape = guard.shape
	def.act_tag = 2
	def.intensity = guard.intensity
	def.inner_radius = guard.inner_radius
	def.outer_radius = guard.outer_radius
	# The day-3 dog's own timing, read off its row, as the robber's is.
	var dog := _charging_dog()
	def.offscreen_notice = dog.offscreen_notice
	# No telegraph: he arrives already chasing.
	def.telegraph_time = 0.0
	def.duration = dog.duration
	def.warned_first = true
	def.pursuit = PursuitSpec.at(guard.pursuit.speed)
	def.pursuit.start = PursuitSpec.Start.ARRIVES_CHASING
	def.departs_at = alley.departs_at
	def.hard_fail = guard.hard_fail
	return def

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
	var def := robber.duplicate() as EventDef
	# `duplicate()` copies only the exported fields; the shape is a plain one (`EventDef.at_heat()`
	# says why), shared since nothing mutates a shape in place.
	def.shape = robber.shape
	def.id = "policeman_giving_chase"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.POLICEMAN_GIVING_CHASE
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.noun = "policeman"
	def.noun_plural = "policemen"
	return def

## **The same pursuer from day 9, once guards are in the city** (inbox #591 in olive-hedgehog): the
## checkpoint guard's own drawing, `EventDef.Look.GUARDSMAN_GIVING_CHASE`, drawn as `door_guard` is
## drawn. Every number is the policeman's (the robber's) rather than the van guard's, since he
## replaces the policeman on the same errand and nothing about the chase is the picture's to
## change.
static func _guardsman_giving_chase() -> EventDef:
	var def := _policeman_giving_chase()
	def.id = "guardsman_giving_chase"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.GUARDSMAN_GIVING_CHASE
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.noun = "guardsman"
	def.noun_plural = "guardsmen"
	return def

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
## (`PursuitSpec.stop_excitement`, `OFFICER_STOP_EXCITEMENT`): when he reaches her he stops, his
## field lands a substantial cost on her, and he and every man his vehicle let out walk back to it.
## **Out of a hunting van his catch ends the day**, as the van's own hunt did (the unmarked van's
## men keep its lethality), and he walks back to it only once he has given up or run out his chase.
##
## **In view, so not the badge: he stands beside her with his hand raised, and then he charges**
## (inbox #764 in minty-lemur). He is not warned of before he exists and does not arrive chasing;
## he gets out with the sole purpose of charging her, beside her
## (`PursuitSpec.Start.SETS_OFF_BESIDE_HER`), so he charges whatever she does, and first shows that
## he is about to: he stands where he got out in his alert pose (`PursuitSpec.stands`) for
## `Tuning.WARNING_ALONE_MAX`, the second an off-screen charger's badge is up alone, his lunge never
## firing early, and then he chases under the pursuit contract (`Tuning.validate_pursuit()`, which
## `all()` holds this copy to on load). Every other number is his own row's.
##
## A derived copy rather than a catalogue row, as a heated row is: the same man, met another way.
static func out_of_the_car(spec: DaySpec, stops := true) -> EventDef:
	return _out_of(on_foot_on(spec), stops)

## The man `out_of_the_car()` describes, made from the pursuer on foot `on_foot`.
static func _out_of(on_foot: EventDef, stops: bool) -> EventDef:
	var key := on_foot.id + (":stops" if stops else ":hunts")
	if not _out_of_the_car.has(key):
		var def := on_foot.duplicate() as EventDef
		# The shape is a plain field `duplicate()` leaves behind; see `_policeman_giving_chase()`.
		def.shape = on_foot.shape
		def.warned_first = false
		def.offscreen_notice = Tuning.OFFSCREEN_NOTICE
		def.telegraph_time = Tuning.WARNING_ALONE_MAX
		def.pursuit = on_foot.pursuit.duplicate() as PursuitSpec
		def.pursuit.start = PursuitSpec.Start.SETS_OFF_BESIDE_HER
		def.pursuit.stands = true
		if stops:
			def.hard_fail = false
			def.pursuit.stop_excitement = OFFICER_STOP_EXCITEMENT
		_out_of_the_car[key] = def
	return _out_of_the_car[key]

## **Day 13's task guard, sent at her from out of her view**
## (`ResistanceDirector._set_the_task_guard_on_her()`): the robber a task sends
## (`_robber_giving_chase()`), the same man the waiting guard is drawn as, warned of by the
## screen-edge badge alone for `Tuning.WARNING_ALONE_MAX` rather than the day-3 dog's half second
## (a second on screen and a second off if they were not visible; inbox #764 in minty-lemur), then
## arriving charging. A derived copy, built once, under an id of its own, `task_guard_sent`, so
## GoatCounter tells him apart from the robber a task sends (inbox #849 in minty-dolphin); his
## charges count as the task guard's (`EventDef.counts_charges_as`).
static func task_guard_sent() -> EventDef:
	if _task_guard_sent == null:
		_task_guard_sent = _robber_giving_chase()
		_task_guard_sent.id = "task_guard_sent"
		_task_guard_sent.offscreen_notice = Tuning.WARNING_ALONE_MAX
		_task_guard_sent.counts_charges_as = "task_guard"
	return _task_guard_sent

static var _task_guard_sent: EventDef = null


## A building goes in the night. Enormous, static, and it closes the block.
##
## **`heat_response = HUNTS`, the same rung `abduction` climbs, but it hunts on foot**
## (`EventDef.hunts`, letting men out). Below `EventDef.HEAT_HUNTS_LEVEL` it is untouched: a closed
## block and nothing more. At and above it, the derived copy `investigates`: the van stays where it
## stands, and the moment she is within `EventDef.HEAT_HUNTS_WITHIN` (180px) of it along a clear
## line it lets two men out at its door on her side, who pursue her under the pursuit contract
## (`EventCatalogue.out_of_the_car()`'s hunting copy, a guardsman on day 10) and whose catch ends
## the day (inbox #669 in coral-lark). Men who give up or run out their chase walk back to the van,
## which stands over its block for the rest of the day. The van itself is never `hard_fail`, cold
## or hot. See `EventDef.at_heat()`.
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
## **Solid at every heat**: `obstructs_radius` 44, half its drawn width. The van never moves, so the
## rule that takes a pursuer's body away (a moving wall pins her) never reaches it, and its men get
## out beside that body (`EventInstance.door_for_its_officer()`).
static func _night_raid() -> EventDef:
	var def := EventDef.new()
	def.id = "night_raid"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 10
	def.look = EventDef.Look.RIOT_VAN
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.act_tag = 3
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 24.0
	def.inner_radius = 70.0
	def.outer_radius = 330.0
	def.telegraph_time = 3.0
	def.pulse_period = 6.0
	def.solid(GroundShape.point(44.0))
	def.heat_response = EventDef.HeatResponse.HUNTS
	def.hunts = HuntSpec.letting_out(2)
	return def

# ------------------------------------------------------------ Act IV: open (12+) ---

## An army truck down its street and off again, leaving nothing behind: nothing a convoy does
## during the walk closes a street (inbox #1183).
##
## **From day 13, the morning the army arrives** (PLAYTEST-122), with the column on the main road
## that day (`ResistanceHappenings`); day 12 is the parks.
static func _military_convoy() -> EventDef:
	var def := EventDef.new()
	def.id = "military_convoy"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.ARMY_TRUCK
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.shape = GroundShape.point(26.0)
	def.first_day = 13
	def.act_tag = 4
	def.placement = [GameEnums.TileType.ROAD]
	def.intensity = 22.0
	def.inner_radius = 76.0
	def.outer_radius = 300.0
	# As a place the day planned, faster than a walk, so the escape distance is the forward reach:
	# `outer_radius · Field.scale(e)` at 120px/s (e = 0.24) is 395px, 4.29s, plus the row's margin.
	# Day 13's column is this row warned first (`EventSpawner.as_warned()`): that copy's badge alone
	# is cut to `Tuning.WARNING_ALONE_MAX`, and it is held to the flat
	# `Tuning.OFFSCREEN_WARNING_MIN`.
	def.telegraph_time = 4.43
	def.mobile = true
	def.speed = 120.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 50
	def.weight = 2.0
	return def

## The widest hard seal: placed every morning from act IV on across a street off the day's route
## tree (`SealPlanner`'s `barricade_seal`, and the escape's `finale_barricade`).
##
## **Silent**: this is the widest hard seal in the game (`obstructs_radius` 62, the whole street),
## so its route cost is already the largest in the catalogue; an ambient field on top would bill
## nothing she could see past the wall itself.
static func _barricade() -> EventDef:
	var def := EventDef.new()
	def.id = "barricade"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BARRICADE
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.act_tag = 4
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(62.0))
	def.aftermath.scar = "barricade"
	return def

## Grows while it is there: `intensity_ramp` takes it to 1.9x over its duration. A protest you could
## have walked past when you saw it is not one you can walk past two minutes later.
##
## **Radii derived from the body.** The field is a capsule about the body's spine, so the radii are
## the along-axis reach less the segment's own `half_length` (31, from `band(55)`): `inner_radius`
## 39 and `outer_radius` 269. The 39px still clears the body's own 24px rounding, so neither clamps.
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
	var def := EventDef.new()
	def.id = "protest"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.PROTEST
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.stands_along_its_street = true
	def.first_day = 12
	def.act_tag = 4
	def.placement = [GameEnums.TileType.SQUARE, GameEnums.TileType.CROSSING]
	def.intensity = 19.5
	def.inner_radius = 39.0
	def.outer_radius = 269.0
	def.duration = 150.0
	def.telegraph_time = 2.6
	def.intensity_ramp = 1.9
	def.pulse_period = 8.0
	# The clearest case in the catalogue of the picture deciding a gameplay number: a body may not
	# claim ground the drawing does not (`SpreadLook._draw_spread`'s rule in the other direction),
	# so a protest drawn as one man obstructs one man's width however much of a square it is
	# supposed to fill. `RankLook._draw_protest` draws two ranks across exactly this width.
	#
	# Under the 39px inner radius on purpose: the loudest part of a protest is something you stand
	# in rather than bump into, and being stopped at the edge of it would take the choice of how
	# close to cut past away from the player.
	def.solid(GroundShape.band(55.0))
	def.weight = 2.5
	# A wall row, capped with the rest of them. Act IV only, so this is the late city's share of the
	# blocking events that make the ground off the paths expensive. A protester obstructs nothing
	# and pursues nothing, so this cap has no other cap to compete with, and this row's own cap is
	# what binds where the bags would draw more.
	def.max_per_day = 12
	return def

## The last thing in the catalogue and the worst. Static, extreme, lethal at the centre, and it
## shuts a district.
##
## **Radii derived from the body, and `inner_radius` here is the lethal one.** Both lose the
## segment's own `half_length` (6, from `band(30)`) so the along-axis reach, including the lethal
## one (a plain circle of `inner_radius` about the centre, not capsule-shaped), is unchanged:
## `inner_radius` 90 → 84, `outer_radius` 380 → 374. `(outer − inner)` is invariant under
## subtracting the same term from both, so the telegraph arithmetic is untouched.
static func _firefight() -> EventDef:
	var def := EventDef.new()
	def.id = "firefight"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 13
	def.look = EventDef.Look.FIREFIGHT
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.stands_along_its_street = true
	def.act_tag = 4
	def.placement = [GameEnums.TileType.CROSSING, GameEnums.TileType.SQUARE]
	def.intensity = 30.0
	def.inner_radius = 84.0
	def.outer_radius = 374.0
	# hard_fail: (374-84)/92 * 2 = 6.3s.
	def.telegraph_time = 6.5
	def.pulse_period = 2.5
	# The 30px band the two gunmen are drawn across (`RankLook._draw_firefight()` stands
	# them at 0.62 of it either side), and far inside the 84 that ends the day.
	def.solid(GroundShape.band(30.0))
	def.hard_fail = true
	return def

# --------------------------------------------------------------- seal pictures ---
# Every row below exists only as `SealPlanner` candidate material (`docs/DECISIONS.md`, "Eight
# seal pictures, so that no single barrier becomes the city's signature."). Each is `SCRIPTED` with
# `scripted_day = 0`, a day nobody plays, so `EventDef.available_on()` never rolls one and the
# ordinary scheduler never sites one, the shape `barricade` uses to keep out of the day's own bags.
# `SealPlanner._effective_first_day` reads `act_tag` instead, so `act_tag` is what gates the day a
# seal may use the row, not `first_day`.
#
# **Silent, like every other seal candidate**: each carries `intensity = 0.0`. Radii still have to
# satisfy `EventDef.validate()` even at zero intensity, so every row below copies `barricade`'s
# geometry (inner 40, outer 120, telegraph 0.9) rather than inventing one nothing reads.

## A hard seal: a tree down kerb to kerb, root plate at one end and crown at the other.
## `obstructs_radius` 96 is exactly half the 192px street, so `SealPlanner._hard_positions` places a
## single copy spanning it edge to edge, and `fallen_tree.svg` is authored wider than that so
## `SpreadLook._draw_spread` draws that one copy rather than repeating a tree across the street.
static func _fallen_tree() -> EventDef:
	var def := EventDef.new()
	def.id = "fallen_tree"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.FALLEN_TREE
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.act_tag = 1
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(96.0))
	return def

## A hard seal: two cars locked together across the carriageway, debris between them and an
## onlooker on each sidewalk. Same single-copy geometry as `fallen_tree`: one continuous scene
## rather than a repeated segment. Smoke puffs up off the wreck over two frames
## (`EventPictures.CAR_ACCIDENT_B` and its vertical sibling) that stand on the same contacts, so the
## parts below hold for both.
##
## **The one seal that is solid only in parts, and the one that emits** (PLAYTEST-63). `shape` is
## the whole-street band: what the picture is fitted to, what the field is stated over, and the disc
## every planner clears the street by. `solid_parts` puts a body under each car and leaves the debris
## and the two sidewalks open. The price of walking through one of those gaps is the field, not a
## wall: see `CAR_ACCIDENT_INTENSITY`, which overturns *a closure is silent* for this row alone
## (`docs/CITY.md`, "A closure is silent").
##
## **The field is stated over the band and not over the cars.** `inner_radius` is
## `GroundShape.BAND_RADIUS`, the band's own surface (a segment's field is priced from its spine),
## so everything inside the scene's footprint is charged at the full rate, gaps included, and the
## shoulder outside it is short: 72px, under half a street's width, so the crash is felt walking up
## to it rather than from down the street. A sealed street still has to be discoverable by walking
## into it, the reason closures are silent in the first place.
static func _car_accident() -> EventDef:
	var def := EventDef.new()
	def.id = "car_accident"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.CAR_ACCIDENT
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.act_tag = 1
	def.intensity = CAR_ACCIDENT_INTENSITY
	def.inner_radius = GroundShape.BAND_RADIUS
	def.outer_radius = 96.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(96.0))
	def.solid_parts = _car_accident_parts()
	if CAR_ACCIDENT_GAPS_ARE_LETHAL:
		# The other answer to *prevents*, off by default (see the constant). The lethal radius has to
		# clear the cars' own bodies with her 14px to spare or the kill can never fire
		# (`EventDef.validate()`), and the telegraph has to buy the walk out of the doubled margin.
		def.hard_fail = true
		def.inner_radius = CAR_ACCIDENT_LETHAL_INNER_RADIUS
		def.telegraph_time = 1.2
	return def

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
static func _car_accident_parts() -> Array[EventDef.SolidPart]:
	return [
		EventDef.part(-22.1, -11.5, GroundShape.point(14.0)),
		EventDef.part(5.8, 9.6, GroundShape.point(14.0)),
	] as Array[EventDef.SolidPart]

## Half of a soft seal: a skip at the kerb, facing `scaffolding` on the other sidewalk. Kerb-pinned
## like `delivery_van`, so `EventFootprints._centred_on_the_pavement_band` leaves it exactly where
## `SealPlanner._place_soft` puts it rather than spreading it across the whole band.
static func _skip() -> EventDef:
	var def := EventDef.new()
	def.id = "skip"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.SKIP
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.act_tag = 1
	def.pavement_side = EventDef.Pavement.AT_THE_KERB
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.point(VEHICLE_BODY))
	return def

## The other half of the same soft seal: boards over the far footway. `pavement_side` stays `ANY`
## so the auto-centring `construction` uses fills the whole 64px band.
static func _scaffolding() -> EventDef:
	var def := EventDef.new()
	def.id = "scaffolding"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.SCAFFOLDING
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.act_tag = 1
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(SIDEWALK_SPREAD_MAX))
	return def

## A hard seal: a crater with water across the asphalt and a municipal barrier at each kerb, "the
## one that explains why the road is out too" (`docs/DECISIONS.md`, "Eight seal pictures").
## Single-copy geometry, as `fallen_tree` and `car_accident`. The fountain surges and splashes over
## two frames (`EventPictures.BURST_MAIN_B` and its vertical sibling), so the water reads as water.
static func _burst_water_main() -> EventDef:
	var def := EventDef.new()
	def.id = "burst_water_main"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BURST_MAIN
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.act_tag = 1
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(96.0))
	# The crater is sunk into the road, not standing above it, so the body and the barriers keep
	# their ordinary geometry and only the shadow patch
	# is refused.
	def.draws_body_shadow = false
	return def

## A soft seal, both bodies the same row: a moving van with its ramp down on each sidewalk, the
## lorry-scale silhouette family ("reuses `Look.LORRY`, the biggest silhouette in act I",
## `docs/DECISIONS.md`, "Eight seal pictures") rather than the literal `Look.LORRY` value, since
## two rows may not share a look or a silhouette (`docs/EVENTS.md`, "the visual vocabulary";
## `tests/test_events.gd`'s `_test_no_two_rows_draw_the_same_picture` and
## `_test_every_look_carries_its_own_silhouette`). `moving_van.svg` is drawn at the scale of
## `lorry.svg` with its own picture: open doors and a ramp reaching the ground.
static func _moving_van() -> EventDef:
	var def := EventDef.new()
	def.id = "moving_van"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.MOVING_VAN
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.act_tag = 1
	def.pavement_side = EventDef.Pavement.AT_THE_KERB
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	# Over `GroundShape.BAND_RADIUS`, so it is the one stationary-vehicle row whose shape is a
	# segment rather than a point — see `EventInstance.solid_axis()`.
	def.solid(GroundShape.band(28.0))
	return def

## A hard seal, acts II-IV: a car burnt to the shell, `BURNT_SHELL`'s charred palette moved onto a
## vehicle body. Vehicle-scale `obstructs_radius`, so `SealPlanner._hard_positions` spaces four
## across a street's 192px as it spaces two `barricade` copies: a pile-up rather than one wide
## scene.
static func _burnt_out_car() -> EventDef:
	var def := EventDef.new()
	def.id = "burnt_out_car"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.BURNT_OUT_CAR
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.lies_across_its_street = true
	def.act_tag = 2
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(24.0))
	return def

## A hard seal, acts II-IV: rubble spilled frontage to frontage. Single-copy geometry like
## `fallen_tree`, but drawn with `SpreadLook._draw_spread`'s ordinary repeated-segment behaviour
## rather than one stretched picture: `collapsed_frontage.svg` is a small debris segment, styled
## beside `rubble.svg` (`_burnt_shell`'s picture) rather than sharing it, since a row may not draw
## another row's picture.
static func _collapsed_frontage() -> EventDef:
	var def := EventDef.new()
	def.id = "collapsed_frontage"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.COLLAPSED_FRONTAGE
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.act_tag = 2
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.band(96.0))
	return def

# ------------------------------------------------------ the region door's own structure ---
# Three bodies `RegionPlanner` stands at every open crossing of today's region wall, from
# `Tuning.REGION_WALL_FIRST_DAY`: a hut on each sidewalk and a gate over the road at a street door,
# a single guard at each mouth of an alley door. All three are `SCRIPTED`, `scripted_day 0`, like
# the seal pictures above: the ordinary catalogue roll never schedules one, and
# `RegionPlanner.plan_day` places each fresh every morning at the door geometry decides. See
# docs/CITY.md, "Regions and the wall", and docs/EVENTS.md, "Checkpoints".
#
# All three carry `barrier_structure`, as does the `roadblock` the wall stands as: a door is one
# thing to walk through however many bodies it is built from, and where a door and a wall meet at a
# corner their fields are one barrier rather than five. See `EventDef.barrier_structure`.

## The hut at a region door. Detains rather than blocking outright: the player walks to the hut,
## gets detained inside, and spawns on the other side.
##
## **The hold starts a reach past the hut's own wall**, not a radius from the middle of it:
## `detain_radius` is `CHECKPOINT_DETAIN_REACH` (48px) measured from the solid edge, so
## `EventDef.detain_distance()` comes out at 80px from the centre, and the guard steps out while she
## is still walking up rather than only once she is pressed against the hut. It sits inside
## `inner_radius` (84px) as every detainer's does, and the ambient field is a small `intensity` over
## a tight band, small enough that the real price stays the flat `Tuning.CHAT_EXCITEMENT` the
## detention charges through the ordinary chat mechanism, and standing still on its own pays nothing
## back (`EXCITEMENT_DECAY_IDLE`). **The field is not what makes this row expensive and must not
## be asked to be**: at 4.0 over an 84–98px band it means less along the line than the 6.0/s an
## ordinary street gives back, so `walk_through_cost()` reads it as free, and it is, because the
## price is the detention. `tests/test_events.gd` exempts the detainers from its catalogue-wide
## "nothing is cheaper to walk through than around" rule by name and holds them to charging their
## capture instead. The band stays 14px wide, which is what the telegraph is priced on; the disc
## moved out with the capture so the two keep the order `validate()` requires. `redetains` tells
## `EventManager` this instance is armed again once she is outside `detain_distance()`, in either
## direction, rather than spent after one conversation like `chatting_mother`.
##
## **4.0 rather than 6.0, for the reason the `roadblock` is silent.** A door is a hut on each
## sidewalk, a gate over the road and often a wall's roadblocks at the corner, and a hold is spent
## standing still where no decay is earned. `barrier_structure` already collapses all of them to
## the strongest at her position; this is that source's own rate when the hut is the strongest thing
## there. It changes nothing about what a detention costs, which is `Tuning.CHAT_EXCITEMENT` flat.
static func _checkpoint_hut() -> EventDef:
	var def := EventDef.new()
	def.id = "checkpoint_hut"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.CHECKPOINT_HUT
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.act_tag = 2
	def.intensity = 4.0
	def.inner_radius = 84.0
	def.outer_radius = 98.0
	def.telegraph_time = 1.0
	def.solid(GroundShape.point(32.0))
	def.detain_seconds = CHECKPOINT_DETAIN_SECONDS
	def.detain_radius = CHECKPOINT_DETAIN_REACH
	def.redetains = true
	def.barrier_structure = true
	return def

## The boom over the roadway between a door's two huts. **It never inspects her**: a lowered boom is
## a wall across the carriageway, and a raised one is ground she may walk under
## (`EventDef.SolidWhen.WHILE_LOWERED`), so its collision body follows the arm and the cars decide
## the arm (`Crowd._stop_for_gates()`: up once a car has waited at it `Crowd.GATE_STOP_SECONDS`,
## down the moment no car is within a length of it and she is not under it). The inspection is the
## two huts' alone, and a hut does not take her in from the carriageway this boom spans, so walking
## under a raised arm skips the toll: the unlawful crossing `EventManager` watches for and sets a
## `door_guard` on her for.
##
## No field of its own (a car passing under it costs her nothing whether or not she is near it):
## `intensity` 0 on radii that exist only because `validate()` wants a falloff band, `inner_radius`
## 84 and `outer_radius` 120, clear of `Tuning.required_telegraph_time()` at that core. Drawn raised
## or lowered from the shared `RegionPlanner.GateState` `Crowd` keeps current for the day's cars.
## Placed with `Planned.facing` set along the street's own axis, which tells the drawing a
## north-south road from an east-west one and is the door's own line for the walk-under check.
static func _checkpoint_gate() -> EventDef:
	var def := EventDef.new()
	def.id = "checkpoint_gate"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.CHECKPOINT_GATE
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.act_tag = 2
	def.intensity = 0.0
	def.inner_radius = 84.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.point(32.0))
	def.solid_when = EventDef.SolidWhen.WHILE_LOWERED
	def.barrier_structure = true
	return def

## The alley half of a door: a single guard where a through-alley crosses a region boundary,
## standing in for the hut and gate a full street gets; the alley is one lane wide, so one body
## covers its whole 64px mouth. Detains exactly like `checkpoint_hut`, with the same numbers and the
## same `redetains`, because the toll is the crossing itself, not the width of the street it stands
## on.
static func _checkpoint_post() -> EventDef:
	var def := EventDef.new()
	def.id = "checkpoint_post"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.CHECKPOINT_POST
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.hides_in_its_hold = true
	def.act_tag = 2
	def.intensity = 4.0
	def.inner_radius = 84.0
	def.outer_radius = 98.0
	def.telegraph_time = 1.0
	def.solid(GroundShape.point(32.0))
	def.detain_seconds = CHECKPOINT_DETAIN_SECONDS
	def.detain_radius = CHECKPOINT_DETAIN_REACH
	def.redetains = true
	def.barrier_structure = true
	return def

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
## since the field is the man. **`hard_fail` in its own right, not through `heat_response`**: a
## catch is a detention on every day a door stands and at every heat level, never a rung of the
## resistance's ladder. The field is `masked_pursuer`'s, 18 over a 28–120px band, the same figure
## coming at her.
##
## **He charges at once** (`PursuitSpec.Start.CHARGES_AT_ONCE`): his warning came before he was set
## on her. From the frame she crosses the door's line, the guard at the hut across the road from her
## raises his hand (`EventInstance.guard_warns_her`), or an alley post's guard; back across before
## `CheckpointController.CROSSING_WARNING` has run, nobody comes, and still across once it has, this
## man steps out of that hut or post and charges from his first frame (inbox #788 in minty-lemur).
## The answer is the warning, go back or go on running, which `tests/test_checkpoints.gd` walks.
static func _door_guard() -> EventDef:
	var def := EventDef.new()
	def.id = "door_guard"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.DOOR_GUARD
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.shape = GroundShape.point(9.0)
	def.act_tag = 3
	def.intensity = 18.0
	def.inner_radius = MASKED_MAN_REACH
	def.outer_radius = 120.0
	# No notice of his own: his warning was the hut guard's raised hand from her crossing
	# (`CheckpointController.warn_at_the_doors()`), and he charges the moment he is set on her
	# (`PursuitSpec.Start.CHARGES_AT_ONCE`).
	def.telegraph_time = 0.0
	def.duration = Tuning.PURSUIT_TIME
	def.pursuit = PursuitSpec.at(Tuning.HEAT_HUNTS_SPEED)
	def.pursuit.start = PursuitSpec.Start.CHARGES_AT_ONCE
	def.hard_fail = true
	return def

# ------------------------------------------------------------------ the finale ---
# Rows the escape places and nothing else does. Each is `SCRIPTED` with `scripted_day = 0`, the
# same gate the seal pictures and the checkpoint kit use: `EventDef.available_on()` asks
# `scripted_day == day` for a `SCRIPTED` row and no day of a fourteen-day run is day zero, so the
# ordinary scheduler can never roll one. `FinalePlanner` places them by id.

## The bang she hears and does not see: explosions happen off screen (but loud enough to cause
## excitement), leaving craters on the street.
##
## **It draws nothing at all**: there is no burst on the street, only the noise and the hole
## afterwards. `Look.NONE`, the fourth row in the catalogue with no picture, alongside the
## playground and the two loudspeaker sources, so it needs no shape either, and
## `tests/test_events.gd` names all four by id.
##
## **Off screen is bought with the streaming radius rather than with a rule.** A `MAP` placement
## comes into the world at `Tuning.EVENT_STREAM_RADIUS` (900px), where the camera at zoom 2 sees
## 640×360, so an explosion begins its telegraph roughly two and a half screens away, spends
## `telegraph_time` + `duration` (3.7s, about 340px of walking) getting to its bang, and is over
## while it is still well outside the view.
##
## **The radii are sized against that distance and not against taste.** `outer_radius` 520 reaches
## a screen and a half; `inner_radius` 300 puts the near half of that band at close to full
## strength, so a burst just beyond the screen edge (about 360px on the long axis) still lands
## roughly 22 of its 24 points per second on her. A narrower band would be an explosion she could
## be next to and not hear. `telegraph_time` is the contract's own minimum for that band,
## `(520 − 300) / WALK_SPEED` = 2.39s, with the ordinary margin on top.
##
## **Not lethal, and that is the tone rule rather than an omission** (`docs/NARRATIVE.md`: *the
## danger is always noise*). The thing that ends a section is being taken; an explosion wakes the
## baby.
static func _finale_explosion() -> EventDef:
	var def := EventDef.new()
	def.id = "finale_explosion"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.NONE
	def.stands_as = EventDef.StandsAs.NOTHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.act_tag = 4
	def.placement = [GameEnums.TileType.ROAD]
	def.intensity = 24.0
	def.inner_radius = 300.0
	def.outer_radius = 520.0
	def.telegraph_time = 2.5
	# Short and over: a sharp spike is a short `duration` at high `intensity`, since there is no
	# `impulse` field (`CLAUDE.md`, "Things deliberately not done").
	def.duration = 1.2
	def.aftermath.on_finish = "impact_crater"
	return def

## What is left in the road afterwards, and it stays there for the rest of the sequence: `duration`
## 0 is "lasts the whole day", so a crater is a fact about the street from the moment it is made.
##
## **Silent and solid**, like the seal pictures it sits beside: a hole in the road makes no noise,
## and its radii are `barricade`'s (inner 40, outer 120, telegraph 0.9) because `EventDef.validate()`
## wants a falloff band even at zero intensity.
##
## **The body is the picture.** `impact_crater_2x2.svg` is 64px across, so `point(32)` is exactly
## half of it and the ground she cannot walk on is the hole she can see. The 32px and 96px sources
## stay prepared and unbound: `aftermath.on_finish` names one row, a second crater row would need a
## second explosion row to leave it, and three sizes of the same hole would be three looks no reader
## could tell apart on the screen-edge badge.
##
## **No `aftermath.scar`.** A scar is how the *run* remembers a fire on day 3; the escape is the last
## thing that happens in a run, so a crater has nothing to persist into and recording one would only
## put an entry in `RunState.attempt_spend.scars` that no later day reads.
static func _impact_crater() -> EventDef:
	var def := EventDef.new()
	def.id = "impact_crater"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.IMPACT_CRATER
	def.stands_as = EventDef.StandsAs.NOTHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.act_tag = 4
	def.intensity = 0.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.solid(GroundShape.point(32.0))
	return def

## A masked man running up the stairwell: masked pursuers run up the stairs and can be avoided by
## going into a corridor and letting them pass.
##
## **Mobile, not `EventDef.pursuit`, and that is the whole counterplay.** A pursuer steers at her,
## so the only answer to one is speed; this runs a line (the shaft, bottom landing to top) and the
## answer to it is *not being on that line*, which in a building whose stairwell doors are a fade
## and a teleport means stepping through the nearest one and letting him go past. It is
## `loose_dog`'s contract indoors: a thing coming down the corridor you are in, answered by leaving
## the corridor.
##
## **Faster than a walk, so it cannot be out-walked**, which makes stepping aside the answer rather
## than a preference, and makes the telegraph contract ask for a long one: at 130px/s it prices the
## escape as the field's whole forward reach rather than its falloff band, so `outer_radius` 120 at
## `TELEGRAPH_HARD_FAIL_MARGIN` needs 3.53s and `telegraph_time` carries a little over it. That
## number is read only by the contract: he warns while she is in the stairwell and runs on a
## distance, with no clock (below).
##
## **No body**, like every other mobile row: a moving wall on a stairwell one tile wide would pin her
## against the shaft. What stops her walking into him is that it ends the section.
static func _masked_pursuer() -> EventDef:
	var def := EventDef.new()
	def.id = "masked_pursuer"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.MASKED_PURSUER
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.shape = GroundShape.point(9.0)
	def.act_tag = 4
	def.intensity = 18.0
	def.inner_radius = MASKED_MAN_REACH
	def.outer_radius = 120.0
	def.telegraph_time = 3.6
	def.mobile = true
	def.speed = Tuning.HEAT_HUNTS_SPEED
	# **He waits at the foot of the shaft until she is in it**, rather than running his line the
	# moment the section begins and being gone before she has come down a floor. `EventDef.notice`
	# without `EventDef.pursuit` stands unclocked until she is in range and then runs its ordinary
	# path, which is `alley_mouse`'s shape at a stairwell's scale. 900px is the shaft's own height
	# (three floors of eight tiles is 768px) with room over it, so he notices her the moment she is
	# anywhere in the same stairwell and never from the hallway two parts away.
	def.notice = NoticeSpec.at(900.0)
	# And the warning is spent standing, not approaching: a man already running when he first
	# becomes visible has given no notice at all.
	def.still_while_telegraphing = true
	# **He warns while she is in the stairwell, and runs the moment she is within this of him, with
	# no warning clock**: the one waiting charger outside the one-radius rule (inbox #788 in
	# minty-lemur: no delay), since his warning is off screen and a delay only lets a walker reach
	# the door. She has to run to the first floor's door (inbox #764 in minty-lemur) rather than walk
	# down to it and out to the other shaft without meeting him (inbox #782 in minty-lemur: a bigger
	# radius, and him not moved). No clock, so his `telegraph_time` above is read only by the
	# telegraph contract. 426px is measured on the escape as built
	# (`tests/probes/escape_stairwell_guard_trigger.gd`, stepped as the game steps, a 30Hz physics
	# tick that moves her, then steps him and checks the catch): coming down from the second floor's
	# door she meets it at the head of the second flight, and making for the first floor's door from
	# there a runner gets through on every line onto the flight, while a walker is caught holding
	# plain left from the row level with the flight's head tread or the row below it, or down-left
	# from the landing tile between the two flights. **A walker holding plain left from that landing
	# tile gets through**, and the margins are thin against his 23.5px catch
	# (`MASKED_PURSUER_CATCH`): a runner who walks until he runs, then runs, turning plain left at
	# row 11's centre, comes within 24.6px of him on the tick and clears it by 1.1px in the
	# hand-stepped probe, and clears it on the real body, which slides along walls, in
	# `tests/test_interior_masked_man.gd`; the walker down-left from the landing tile comes within
	# 22.7px, 0.8px inside; a runner who runs the whole way is 33px from him at the closest. In the
	# stairwell his warning is off screen, since the view reaches 180px from her and he starts about
	# 400px below; only the edge badge shows his charge, from the frame he runs (`DangerEdge`). The
	# player accepted both (inbox #782 in minty-lemur).
	# #782 in minty-lemur).
	def.notice.runs_within = 426.0
	def.hard_fail = true
	def.catch_reach = MASKED_PURSUER_CATCH
	# **One of him at a time, and there is always another**: a fresh one comes up the shaft this long
	# after the last has run out of the top of it, so every run waits, warns and runs exactly as the
	# first did (`EventManager`'s repeats).
	def.repeat_after = FINALE_PURSUER_RESPAWN_SECONDS
	return def

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
## **What makes that fair is the notice, and `EventDef.SolidWhen.ONCE_IT_STARTS` is what makes the
## notice worth anything.** A body from the instance's first frame would close ground she might be
## standing on, so the body goes down at the end of the telegraph and never around her (see that
## field, and `EventInstance._become_solid_once_it_starts()`).
##
## **One vent is a gate; the corridor is several of them on their own clocks.** The count, the
## periods and how long a blow lasts are `BuildingPlan.FINALE_STEAM_PERIODS` and
## `FINALE_STEAM_BLOWS_FOR`; the building sites them on the basement's narrows (`BuildingPlan`),
## each plan coming again on its own period (`EventScheduler.Planned.repeat_every`). What this row
## owns is one blow: notice, body, field, over. Its plume billows over two frames
## (`EventPictures.STEAM_B`) for the whole blow.
static func _basement_steam() -> EventDef:
	var def := EventDef.new()
	def.id = "basement_steam"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.STEAM
	def.stands_as = EventDef.StandsAs.NOTHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.solid(GroundShape.point(STEAM_VENT_BODY))
	def.solid_when = EventDef.SolidWhen.ONCE_IT_STARTS
	def.act_tag = 4
	# **25, so one blow costs 40 to 50 points awake** at the 30px a vent holds her out (inbox #747 in woolly-penguin):
	# 44 awake, 24 asleep. The pulse is kept, since it is what makes the blow swell and fall back
	# rather than hold flat. What bounds it from above is the pocket between two vents, shut at both
	# ends for 2s at most: the cost there scales with this, and
	# `_test_no_pocket_between_two_vents_outlasts_the_noise` keeps it under the meter (84 of 100 at
	# 25; 29 is the most the meter allows).
	def.intensity = 25.0
	def.inner_radius = 24.0
	def.outer_radius = 90.0
	# Well under a walk, so the escape distance is the falloff band: `(90 − 24) / WALK_SPEED` is
	# 0.72s. The body asks for far less than the field does (a step of `STEAM_VENT_BODY` plus her
	# own 14px is a third of a second), so the notice she is owed for the ground is paid several
	# times over by the notice she is owed for the noise.
	def.telegraph_time = 1.2
	def.pulse_period = 4.0
	def.duration = FINALE_STEAM_BLOWS_FOR
	return def
