class_name EventSpawner
extends RefCounted
## **Everything that puts an event in the world goes through here** (`create()`), so a scar, a
## body's footprint and the bang outside can never be missed by whichever path made the event: a
## plan streamed in (`EventStreaming`), a row placed while she walks (`EventsAhead`), a row warned
## of first (`spawn_warned()`), a door's guard (`CheckpointController`), the resistance's own rows
## (`EventManager.spawn_extra()`), and what a finished row leaves behind (`successor_of()`). It also
## keeps what a creation depends on across the day: the rows summoned on sight and the run's pelican
## bag.
##
## Handed the world the events stand in (`EventWorld`) and the warning board a summoned row is
## warned on (`WarningBoard`), never fetching either.

## The world the events stand in, the run, the player and the live instances.
var world: EventWorld
## Where a row summoned on sight is warned of before it exists.
var _warnings: WarningBoard

func _init(the_world: EventWorld, warnings: WarningBoard) -> void:
	world = the_world
	_warnings = warnings

## Forgets the day: what has been summoned and sighted, and the pelicans not yet seen.
func clear() -> void:
	_sighted.clear()
	_sight_reported.clear()
	_unseen_pelicans.clear()

## Which planned events have already summoned the row their own `aftermath.on_sight` names, so a
## `burning_building` streamed out and back in — a fresh `EventInstance` every time, unlike the
## `EventPlan` it comes from, see `EventStreaming.stream_in()` — does not hand out a second fire engine. Keyed by
## `EventPlan` rather than by instance for exactly that reason, and cleared with the rest of the
## day in `clear()`.
var _sighted: Dictionary = {}

## Which planned events have already told `EventBus.event_sighted` they were seen — kept apart from
## `_sighted` above because that one only marks a *successful* summon and keeps retrying every frame
## until it gets one, while a sighting itself happens on the first on-screen frame regardless of
## whether the warning for the engine it summons can be put up. Keyed by `EventPlan`, cleared with the
## rest of the day in `clear()`.
var _sight_reported: Dictionary = {}

# --------------------------------------------------- the bodies in the street ---
# Every stationary solid body is recorded per tile for the day, so the crowd steers round it
# instead of walking and driving through it — *("yes every solid body should do that -- not
# necessarily force a turn around but at least avoid the solid")*. `CityMap.obstructed_tiles` is
# the record and says which bodies it deliberately leaves out; this is the whole of what fills it.
#
# **Two identities record the same footprint and both give it back.** A `EventPlan` records its body
# at dawn, because the crowd runs across the whole map and a body is a body whether or not the
# player has come near enough for it to exist yet; the `EventInstance` records the same tiles again
# while it is live, because a body placed later in the day — a successor left where a fire burnt
# out, the resistance's own robbery — has no plan behind it. The record counts rather than flags
# for exactly this reason, so neither release can open ground the other is still standing on.

## Records one body's footprint under `owner`, or nothing at all for anything the record leaves
## out, and answers the tiles it recorded (none for the latter). Safe to call for every plan and
## every instance: the deciding is all in `obstructed_footprint()`.
func record_the_body(owner: int, def: EventDef, at: Vector2, facing: Vector2) -> Array[Vector2i]:
	var tiles := obstructed_footprint(world.map(), def, at, facing)
	world.map().obstruct_tiles(owner, tiles)
	return tiles

## The tiles a row's own solid body stands on when it is sited at `at` looking `facing`, or an
## empty list for anything `CityMap.obstructed_tiles` deliberately leaves out — a mobile row, a
## door body, or a row with no body at all.
##
## **The placement and the axis are read back out of `EventInstance`'s own statics rather than
## worked out again here.** Where a body actually stands is not `EventPlan.position`: a stationary,
## unpinned body is shifted onto the middle of its pavement band, or onto the kerb beside its lane
## for a row that stands at its kerb (the roadblock), and a segment body lies along
## whichever axis the street it stands on gives it. Both are decided in exactly one place, and a
## second copy of that arithmetic would agree with it right up to the first time one of the two
## took an argument — which would leave the crowd avoiding ground no body is on and walking
## through the ground one is.
##
## **It is the row's pieces that are rasterised, never the one disc of `obstructs_radius`.** A row
## is solid where `EventDef.parts()` says it is, which is one piece at the origin carrying `shape`
## for every row that declares none — so a one-piece row records exactly the tiles it always did,
## and a row solid in parts records its pieces and leaves the ground between them open. That is the
## whole of what makes a crash two cars to the crowd rather than a wall: the pieces are a subset of
## `shape` (`EventDef.validate()` refuses one reaching past it), so the change only ever *removes*
## tiles from the record, and removing obstruction can only add reachable ground.
static func obstructed_footprint(map: WorldMap, def: EventDef, at: Vector2,
		facing: Vector2) -> Array[Vector2i]:
	var nothing: Array[Vector2i] = []
	if def == null or not def.stands_as_a_fixed_body():
		return nothing
	var placed := BodyStance.stands_at(map, def, at)
	# A hard seal's own body and a region wall's are recorded like any other, and that is what a
	# walker actually meets. The hold on their segment is a car's answer — a car cannot turn round
	# against a barrier, so it has to turn at the last junction, before it can see one — and it is
	# nobody else's: a walker walks the street up to the body and turns where it stands, so the
	# record has to say where the body is. It is also what keeps a crash walkable on its pavements,
	# since a row solid in parts records its pieces and the two cars are the only pieces there are.
	var axis := BodyStance.body_axis(map, def, placed, facing)
	# Which way round a piece's own offset is laid is `EventInstance.spread_at()`'s question, and
	# it is asked of the placed position for the same reason the axis is: a piece offset the wrong
	# way is a body recorded across the street from the car it belongs to.
	var spread_vertical := BodyStance.lies_vertically_at(map, placed)
	# The footprint the instance builds its physics body from
	# (`EventFootprints.solid_footprint_of()`), so the record and the body are one solid.
	return EventFootprints.solid_footprint_of(def, axis, spread_vertical).tiles(placed)

## Adds an event outside the day's plan and outside the streaming, at a path the caller chose.
## The director's cats arrive this way, and so does the resistance's robbery.
func spawn(def: EventDef, at: Vector2,
		path := PackedVector2Array()) -> EventInstance:
	var instance := create(def, at, path)
	world.take_in(instance)
	return instance

# ------------------------------------------------------------------------ the pelican ---
# *(minty-hedgehog, statement 8: "One in ~400 bikers should be a pelican riding a bicycle instead.
# Needs to be svg only".)* A picture and nothing else: the rider it is drawn for keeps the row's
# own def, field, lethal radius, speed and cost (`EventInstance.is_drawn_as_a_pelican()`).

## The run's pelican bag holds this many cyclists and one pelican, the player's own one in four
## hundred *(pebbly-ibis, inbox #575 in feathery-lynx: "have one shared biker/pelican marble bag
## with 399 bikers and 1 pelican and the same bag is used throughout the run")*.
const CYCLISTS_IN_THE_BAG := 399
const PELICANS_IN_THE_BAG := 1
## The stream the bag draws from, hashed with the run's seed: its own, so a cyclist drawing from it
## moves nothing any other stream decides.
const PELICAN_STREAM := "pelican-bag"

## What a rig makes `rolls_a_pelican()` answer: the bag's own marble, or every rider one or the
## other, the way `EventManager.stream_within()` lets one turn the streaming off.
enum PelicanRig { BAG, ALWAYS, NEVER }
var _pelican_rig := PelicanRig.BAG

## Makes `rolls_a_pelican()` answer as `rig` says: the bag's own marble, or every rider one or the
## other. `--pelican` is `PelicanRig.ALWAYS` (`SimulationBuilder`).
func rig_the_pelican(rig: PelicanRig) -> void:
	_pelican_rig = rig
## The run's bag, brought to where the run is by `_the_pelican_bag()`; a shared bag
## (`MarbleBag.shared()`) whose marbles are `true` for the pelican and `false` for a cyclist.
var _pelican_bag: MarbleBag = null
var _pelican_bag_seed := 0

## Whether the rider about to be warned of for `def` is drawn as the pelican. Asked once per rider,
## **as its warning goes up** (`EventsAhead._warn_down_her_line()`), and handed to `spawn_warned()` when the
## warning is over, which is what keeps a rider one thing for its whole ride — and what lets the run
## log call it `pelican` from its first line, the badge going up, rather than only from the frame it
## is created *(inbox #527 in azure-tapir, the player: "logs should be correctly identifying it from
## the beginning")*.
##
## **Only from `EventsAhead._warn_down_her_line()`**, the path every cyclist takes (a `TOWARD_PLAYER` row the
## director sends): the instance it ends in is never streamed out and made again, so it is never
## asked twice. A planned row's instance can be — only a scene recipe plans a cyclist — and is never
## a pelican. A warning that never finds a place to stand has still spent its roll, which the seed
## and her walk decide the same way.
##
## **One marble from the run's one pelican bag per cyclist** — 399 cyclists and 1 pelican, the same
## bag for every day of the run, so a full run meets at most one pelican. The run's seed and the
## order it sends its cyclists in decide which of them is the pelican, the same way they decide
## everything else the director sends. Nothing but a cyclist draws from it. The count drawn is kept
## in `world.run().pelican()` (saved, and set back to the day's dawn by a lost day), and the bag is
## rebuilt from it. `--pelican` (`PelicanRig.ALWAYS`, set by `SimulationBuilder`) answers yes for every one
## without changing what is drawn.
func rolls_a_pelican(def: EventDef) -> bool:
	if not def.may_be_drawn_as_a_pelican():
		return false
	var drew: bool = _the_pelican_bag().draw()
	world.run().pelican().count_a_draw()
	match _pelican_rig:
		PelicanRig.ALWAYS:
			return true
		PelicanRig.NEVER:
			return false
	return drew

## The run's pelican bag with `world.run().pelican().draws()` marbles already drawn, from the bag's own
## stream off the run's seed, so a save, a lost day's give-back and a retry all draw the cyclists
## the run would have drawn. Rebuilt whenever the run, or the count a save or a lost day put back,
## disagrees with the bag.
func _the_pelican_bag() -> MarbleBag:
	var seed_value := hash("%d:%s" % [world.run().header().run_seed(), PELICAN_STREAM])
	if _pelican_bag == null or _pelican_bag_seed != seed_value \
			or _pelican_bag.draws_made() != world.run().pelican().draws():
		var marbles := []
		marbles.resize(CYCLISTS_IN_THE_BAG)
		marbles.fill(false)
		for _i in PELICANS_IN_THE_BAG:
			marbles.append(true)
		_pelican_bag = MarbleBag.shared(marbles, seed_value)
		_pelican_bag_seed = seed_value
		_pelican_bag.skip(world.run().pelican().draws())
	return _pelican_bag

## Makes `instance` the pelican, as it is created: the picture
## (`EventInstance.be_drawn_as_the_pelican()`) and the pelican's own telemetry —
## `EventBus.pelican_spawned` now, a place on the list `report_the_pelicans_in_view()` watches until
## it is first on screen, and `EventBus.pelican_excited_her` on the first share of the meter its
## field lands (`ExcitementSource.when_it_first_lands()`), told once and read back by nothing here.
func _ride_as_a_pelican(instance: EventInstance) -> void:
	instance.be_drawn_as_the_pelican()
	_unseen_pelicans.append(instance)
	# The world's reports as a local, so the callback an instance's source keeps holds neither this
	# spawner nor the world.
	var reports := world.reports()
	var told_when_it_lands := func() -> void:
		reports.tell_pelican_excited_her(instance)
	instance.source().when_it_first_lands(told_when_it_lands)
	reports.tell_pelican_spawned(instance)

## Pelicans created and not yet on screen. Untyped, so a pelican freed before it was ever seen can
## be asked `is_instance_valid()` rather than read as a typed element. Empty on all but about one
## day in a run, so watching it costs nothing on the rest. Emptied by `clear()`.
var _unseen_pelicans: Array = []

## `EventBus.pelican_sighted` for each pelican on its first frame properly on screen — the same test
## an encounter's seen makes, `Tuning.ENCOUNTER_SEEN_SHARE` of its drawn box visible to her
## (`world.visible_view()`, `VisibleView`), so `pelican-seen` and `seen-pelican` answer the same question —
## and then never again for that pelican. Telemetry only: it decides nothing and changes nothing
## gameplay reads.
func report_the_pelicans_in_view() -> void:
	if _unseen_pelicans.is_empty():
		return
	var still_unseen: Array = []
	for pelican: Variant in _unseen_pelicans:
		if not is_instance_valid(pelican) or (pelican as EventInstance).is_gone():
			continue
		var instance := pelican as EventInstance
		var box := instance.drawn_box()
		var drawn := Rect2(box.position + instance.global_position, box.size)
		if world.visible_view().share_of(drawn) >= Tuning.ENCOUNTER_SEEN_SHARE:
			world.reports().tell_pelican_sighted(instance)
		else:
			still_unseen.append(instance)
	_unseen_pelicans = still_unseen

## Builds an instance, puts it in the world, and records any permanent mark it leaves.
## Everything that puts an event on the map goes through here, so a scar can never be
## missed by whichever path created the event.
func create(def: EventDef, at: Vector2, path := PackedVector2Array(), record_scar := true,
		facing := Vector2.RIGHT) -> EventInstance:
	show_the_bang(def)
	var instance := EventInstance.new(world.reports())
	instance.skip_draw = world.skip_drawing
	instance.timing = world.timing
	instance.atlas = world.atlas
	instance.drawer = world.drawer
	instance.trace = world.trace()
	var drawn_in := world.drawn_in()
	instance.setup(def, at, path, facing, world.map(), world.navigator(), world.where_she_is(),
			drawn_in)
	instance.signals = world.signals
	instance.points_at = world.where_protests_point
	drawn_in.add_entity(instance)
	# Its own copy of the footprint, given back when it streams out or finishes. A planned body has
	# already recorded the same tiles from its plan; a body placed later in the day has not, and
	# this is the one path every one of those comes through. See "the bodies in the street" above.
	record_the_body(instance.get_instance_id(), def, at, facing)
	if def.scar_id() != "" and record_scar:
		# A scar is where the city stopped being recomputable: it exists because of what
		# happened on an earlier day, so from day 4 onwards the map depends on run history.
		world.trace().note("scar", "%s left at %s by %s" % [
			def.scar_id(), RunTrace.tile(world.map().world_to_tile(instance.global_position)),
			def.id])
		world.run().add_scar(def.scar_id(), instance.global_position)
		_mark_the_block(def.scar_id(), instance.global_position)
	return instance

## An event that leaves a scar may also move the block it happened to along its arc — if the
## arc was waiting for exactly that cause. A fire in a block whose plan has no fire in it
## leaves the shell and changes nothing else, which is what keeps the city coherent.
##
## The block presents its new purpose *the next morning*, not immediately: `CityMap.repaint`
## runs at the start of a day, so the fire burns today and the street is ashes tomorrow.
func _mark_the_block(scar_id: String, at: Vector2) -> void:
	var cause: int = _CAUSES.get(scar_id, -1)
	if cause < 0:
		return
	if not world.city_map():
		return
	world.run().attempt_spend().block_arcs().apply_cause(world.city_map().plans_by_block(), world.city_map().block_at(at),
			cause as GameEnums.BlockCause, world.run().header().day())

## Which scars move a block along its arc. Keyed by scar id rather than by event id, because
## what matters to a block is what was left behind, not which siren left it.
const _CAUSES := {
	"burnt_shell": GameEnums.BlockCause.FIRE,
	"barricade": GameEnums.BlockCause.MILITARY,
}

## Retires one unplanned instance outside the day's own closures and events — the resistance
## director's own use, when a chalk mark moves and the guard standing over the old spot has to go
## with it: mark it finished and let `EventStreaming.retire_finished()`'s ordinary sweep free it, rather than
## freeing it here and risking a reference something else still holds this frame. Unlike a mast
## going quiet, the thing retired here really is leaving.
func retire(instance: EventInstance) -> void:
	if instance and is_instance_valid(instance) and not instance.is_gone():
		instance.end_now()

## **Moves one unplanned instance to `at` with everything it is in the middle of** — its phase, its
## notice and every behaviour's state (`EventInstance.move_to()`) — rather than retiring it and
## making it again: the resistance director's own use, when day 13's task guard follows her to the
## roadblock she is making for. Its body's footprint goes with it.
func move_extra(instance: EventInstance, at: Vector2) -> void:
	if not instance or not is_instance_valid(instance) or instance.is_gone():
		return
	world.map().release_obstruction(instance.get_instance_id())
	instance.move_to(at)
	record_the_body(instance.get_instance_id(), instance.def, instance.global_position,
			instance.facing_now())

## Creates `def` on `path`, for a row whose warning ran before it existed, placed where the warning
## pointed just out of sight. A non-pursuer is created with its telegraph already spent, since the
## warning was its telegraph: from its first frame it is what it is after it — lethal, for a
## `hard_fail` row, and at its own intensity for a loud one. **A pursuer is created with its
## telegraph still to run**, since a pursuer's telegraph is its approach, the sight of it closing
## that she is owed (`Tuning.PURSUIT_MIN_NOTICE`), and its warning was only the badge before it
## (`EventDef.warned_for()`, its `offscreen_notice`) — unless it `PursuitSpec.Start.ARRIVES_CHASING`
## (the resistance's sent robber and guard), which is created with its telegraph spent, chasing from
## its first frame.
##
## **`arrive_from_its_warning()` is told before `restore()`**, which reads it: a restore otherwise restores
## an instance streamed back in, and takes a pursuer that never waits to have begun its chase
## before it streamed out, so a pursuer created here would never report the chase it starts.
##
## `pelican` is the roll its warning made (`rolls_a_pelican()`), and makes a cyclist the pelican;
## it means nothing for any other row.
func spawn_warned(def: EventDef, path: PackedVector2Array, pelican := false) -> EventInstance:
	var instance := spawn(as_warned(def), path[0], path)
	instance.arrive_from_its_warning()
	if not def.pursues() or def.starts_by(PursuitSpec.Start.ARRIVES_CHASING):
		instance.restore(EventSave.aged(age_when_warned(def)))
	if pelican and def.may_be_drawn_as_a_pelican():
		_ride_as_a_pelican(instance)
	return instance

## How old a non-pursuer warned of before it exists — or sent down her line unannounced, the loose
## dog — is when it is created: its telegraph spent, and, for a mover that pulses (`loose_dog`), on
## to the point of its beat that has it reach her, walking into it from where it is created closest
## (`SpawnSiting.least_distance()`), at the loud of its beat. **Its warning's length does not
## decide which beat it meets her on**: the pulse runs on its age, so without this a warning cut to
## a second has it created at the loud of its beat and pass her at the quiet, which halves what a
## pass costs (`docs/COSTS.md`, `tests/probes/m174_pass.gd`, which creates it at this same age).
static func age_when_warned(def: EventDef) -> float:
	var spent := def.telegraphs_for()
	if def.pulses_every() <= 0.0 or not def.moves() or def.speed <= 0.0:
		return spent
	var flight := SpawnSiting.least_distance() / (def.speed + Tuning.WALK_SPEED)
	var beat := def.pulses_every()
	var loud_on_her := beat * 0.5 - flight
	return loud_on_her + ceilf((spent - loud_on_her) / beat - 0.001) * beat

## `def` as a row warned of before it exists (`EventDef.warns_before_it_exists()`): itself when it
## already is one — `cyclist`, the fire engine, the resistance's two pursuers — and
## otherwise its `EventDef.as_warned_first()` copy, which is how day 13's column of
## `military_convoy`, a row the day otherwise plans as a place, and `charging_dog` sent down her
## heading, a row that waits on a tile from the day after it teaches the run, are held to what a
## warning first owes.
static func as_warned(def: EventDef) -> EventDef:
	return def if def.warns_before_it_exists() else def.as_warned_first()

# ------------------------------------------------------- called in on sight ---
# The opposite of a successor: `successor_of()` hands the day something the moment a row is
# *done*; this hands it something the moment a row is first *seen*. `burning_building` is what
# it exists for — see `EventDef.aftermath.on_sight`.

## Whether a live instance whose def names an `aftermath.on_sight` has been seen yet, and if it just
## has, creates the row it names entering along its own street. Run every frame there is a
## player, as `EventsAhead.place_what_is_owed_ahead()` is.
func summon_what_has_been_sighted(plans: Array[EventPlan]) -> void:
	for plan in plans:
		if not plan.live or plan.calls_in() == "" or _sighted.get(plan, false):
			continue
		if not world.visible_view().sees(plan.live.global_position):
			continue
		# `VisitCounter`'s own "seen-fire" — the moment she could see it, whether or not the
		# engine's warning can be put up below: a summon that finds no road off screen to wait on
		# keeps retrying every frame, but she has already seen the fire either way. Reported once,
		# not once per retry.
		if not _sight_reported.get(plan, false):
			_sight_reported[plan] = true
			world.reports().tell_event_sighted(plan.row_id())
		if _summon_the_sighted_row(plan.row(), plan.live.global_position, plan):
			_sighted[plan] = true

## Warns of the row `source.aftermath.on_sight` names, coming along `at`'s own street to `at` — `at`
## is a sidewalk point (`burning_building` is placed `AT_THE_FRONT`), so the along-street
## axis is `CityMap.pavement_inward()` turned a quarter turn, the construction
## `EventDirector._onto_her_side()` uses for the same reason: it is the corridor's own axis, not
## whichever way she happens to be facing. Which end it comes from is a coin flip on the day's own
## stream. Returns false, and puts nothing up, when neither way along that axis has any road off
## screen to wait on.
##
## **Warned first, like everything else that arrives from off screen** (`_warnings.warn_first()`):
## the badge goes up the moment the fire is seen, with no engine in the world, pointing up the road
## it will come down, and once its second is up the engine is created on that road, on its way to
## the fire, just out of sight from her (`PendingWarning.on_its_route()`), and drives to the kerb
## (`_where_the_summoned_row_stops()`), where it parks. A warning withdrawn for want of road out of
## sight is summoned again (`PendingWarning.when_withdrawn()`).
func _summon_the_sighted_row(source: EventDef, at: Vector2,
		sighted_by: EventPlan = null) -> bool:
	var summoned := EventCatalogue.by_id(source.aftermath.on_sight)
	if not summoned:
		push_error("event '%s' summons unknown '%s' on sight" % [source.id, source.aftermath.on_sight])
		return false
	var inward := world.map().pavement_inward(world.map().world_to_tile(at))
	if inward == Vector2i.ZERO:
		return false
	var along := Vector2(inward.y, inward.x)
	var road_at := _where_the_summoned_row_stops(world.city_map(), at)
	var headings: Array[Vector2] = [along, -along]
	if world.run().calendar().day_rng(world.day(), "sighted:%s" % source.id).randf() < 0.5:
		headings.reverse()
	var her := world.player().global_position if world.player() else at
	for heading in headings:
		var reach := _road_left(road_at, heading)
		var travel := -heading
		var where := func(standing: Vector2) -> Vector2:
			return PendingWarning.on_its_route(summoned, standing, road_at, travel, reach, world.visible_view())
		var arrive := func(place: Vector2, _standing: Vector2) -> bool:
			spawn_warned(summoned, PackedVector2Array([place, road_at]))
			return true
		var warning := _warnings.warn_first(summoned, her, where, arrive)
		if warning:
			warning.when_withdrawn(func() -> void: _sighted.erase(sighted_by))
			return true
	return false

## How far the road runs from `from` along the axis-aligned `heading` before the map's edge, less
## half a tile — as far up its street as a summoned row may wait.
func _road_left(from: Vector2, heading: Vector2) -> float:
	var size := world.city_map().world_size()
	var room := INF
	if heading.x > 0.0:
		room = size.x - from.x
	elif heading.x < 0.0:
		room = from.x
	elif heading.y > 0.0:
		room = size.y - from.y
	elif heading.y < 0.0:
		room = from.y
	return room - Tuning.TILE_SIZE * 0.5

## Where a row summoned on sight comes to rest: the near kerb across from `at`, which is the
## sidewalk point the row that summoned it is standing on. `Vector2.INF` where `at` is not beside a
## carriageway at all, which is a point with no kerb to park at. `_summon_the_sighted_row()` sends
## the engine here.
##
## `CityMap.pavement_inward` points away from the carriageway, into the block she is walking beside,
## so the road is the other way; `burning_building`'s `AT_THE_FRONT` puts `at` on the sidewalk tile
## touching the building's front, the far tile of the two-tile band (`Tuning.SIDEWALK_WIDTH`) from
## the kerb, and the near edge of the carriageway is that many tiles further in `-inward`.
static func _where_the_summoned_row_stops(map: CityMap, at: Vector2) -> Vector2:
	var inward := map.pavement_inward(map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return Vector2.INF
	return at - Vector2(inward) * (Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE)

## **A row from outside the walls is shown by the world as it comes** (`EventDef.passes_walls()`,
## `WorldContext.bang_outside()`): every coming, planned or not, the first or a repeat.
func show_the_bang(def: EventDef) -> void:
	var drawn_in := world.drawn_in()
	if def.passes_walls() and drawn_in:
		drawn_in.bang_outside()

## An event that leaves something behind where it stopped — how a fire engine ends its run
## at a fire. The successor is placed at the finishing position, not at a planned tile, so
## the two are always consistent.
func successor_of(instance: EventInstance) -> EventInstance:
	if instance.leaves_behind() == "":
		return null
	var def := EventCatalogue.by_id(instance.leaves_behind())
	if not def:
		push_error("event '%s' spawns unknown '%s'"
				% [instance.row_id(), instance.leaves_behind()])
		return null
	return create(def, instance.global_position)
