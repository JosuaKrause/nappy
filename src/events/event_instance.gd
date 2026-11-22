class_name EventInstance
extends Node2D
## One live event in the world: its lifetime, its telegraph phase and its excitement field. What
## it does is its behaviours' (`src/events/behaviours/`); how it looks is its look's
## (`src/events/views/`), which is handed its row and its drawer, asks it and reads some of its
## public state, and draws it.
##
## The excitement model is entirely a *query*, asked of the source it composes (`source()`, an
## `EventExcitement`) over the field it states here (`field_at()`). Nothing pushes a value at the
## baby, so there is no ordering to get wrong, events compose by simple addition, and the whole
## thing is testable without a scene.

## Fraction of full intensity an event emits while still telegraphing.
const TELEGRAPH_INTENSITY_FRACTION := 0.15

var _def: EventDef
## Waypoints for a mobile event, in world space. Empty for a stationary one.
var _path: PackedVector2Array = PackedVector2Array()

## How long it has existed, in seconds: its own clock, asked through `age()`. Its own tick advances
## it and settles once its notice clock has been held; `restore()` sets it and settles the phase
## against the new age.
var _age := 0.0
## Whether this was created where a warning pointed, once that warning was over
## (`EventManager.spawn_warned()`), rather than simply appearing. `DangerEdge` asks it
## (`was_warned_of()`) to carry the warning's badge on to the thing itself until it comes into
## view, and `restore()` reads it to tell a fresh instance from one streamed back in.
var _came_under_a_warning := false

## **Tells it that it was created where a warning pointed**, once that warning was over
## (`EventManager.spawn_warned()`), before `restore()` reads it: a restore otherwise restores an
## instance streamed back in.
func arrive_from_its_warning() -> void:
	_came_under_a_warning = true

## **Makes its route one worked out as it goes** (`WayOn`): at the end of its route it is given a
## further leg while she could be watching it (`EventRouteWalk`), and once it is over it leaves by legs
## of the same, held to her sight (`EventDeparture`). Told by whoever sends it ahead of her, after
## `setup()` (`EventsAhead`), and never keyed on its row: every copy of a row the director sends carries
## `EventDef.is_sent_ahead()`, day 13's column and the escape's trucks among them, and those end their
## routes where they end.
func go_on_by(way_on: WayOn) -> void:
	if _composed.route() != null:
		_composed.route().go_on_by(way_on)
	_composed.departure().go_on_by(way_on)

## **What this event does**, composed per catalogue row (`EventBehaviours.compose()`): each an
## `EventBehaviour` owning its own state, ticked in this order. The composer hands them back as
## one value at setup, which answers for each by name (null for a behaviour the row is not
## composed of); an event not yet set up holds the empty one.
var _composed: EventBehaviours = EventBehaviours.new()
## **The figure its behaviours move** (`Figure`): what changes about it — its place, heading, way
## covered, clocks and phase — as its behaviours may ask it and tell it, handed to each as it is
## composed.
var _figure := Figure.new(self)

## The behaviours this event is composed of, each by name (`EventBehaviours`): for the suites that
## hold one behaviour's own state through the event it is composed into. The game asks each of
## them through the event's own methods.
func behaviours() -> EventBehaviours:
	return _composed

## **Where this event is in its life, stored and changed in one place** (`transition()`), so every
## question about it — is it waiting, warning, done — reads one value rather than re-deriving the
## phase from a dozen flags each frame. Every row has one, a pursuer or not.
enum Phase {
	## A row that waits for her (`EventDef.waits_for_her()`) has not noticed her: standing
	## there, at full strength unless its notice is quiet, not lethal, not moving.
	WAITING,
	## Its telegraph or notice is running: a row's own telegraph from the frame it exists, or for a
	## row that waits, its warning from the frame it noticed her (`chase_age() < notice_time()`).
	WARNING,
	## Happening at full strength: a pursuer charging her, a crossing cat running, a flock up.
	ACTIVE,
	## The man a vehicle let out has reached her and stands with her through his stop
	## (`PursuitSpec.stop_excitement()`).
	STOPPED,
	## Over and getting out of shot: it emits nothing, cannot end the day and carries no cue.
	LEAVING,
	## A row that stops where it arrives has stopped there
	## (`RouteSpec.parks_where_it_arrives()`):
	## still the same event, standing still, for the rest of the day.
	PARKED,
	## Its guard has gone for good and only his barrier stands, solid and silent
	## (`PursuitSpec.leaves_its_body_standing()`). It waits for nothing.
	SPENT,
	## Gone: finished where it stood, or out of sight at the end of its departure.
	DONE,
}

## Where it is in its life — see `Phase`. Changed only by `transition()`. Public
## because suites read it: no game file outside this one does, so the CI list of test-only
## members (`tools/test_only_members.txt`) holds it among those only their own file uses.
var phase := Phase.WARNING
## Whether its telegraph or notice ended into `Phase.ACTIVE` — run out, or cut short by a lunge, a
## flush or the masked man's run. A row that left, parked or stopped before that is still within
## its telegraph's clock (`is_telegraphing()`).
var _telegraph_ended := false

## **The one place its phase changes**, and with it what every phase change owes: the field it
## answers is a function of the phase, so the contribution cache is let go. A row that is done stops
## showing its scenery on the next drawn frame, when its look asks `is_gone()`.
func transition(to: Phase) -> void:
	if phase == to:
		return
	if phase == Phase.WARNING and to == Phase.ACTIVE:
		_telegraph_ended = true
	phase = to
	_excitement.invalidate_contribution()
	# **Parked while it stands for good, and only then** (`MoveProposal.has_parked()`): a row
	# that parks has once it stops where it arrives, and nothing leaving or gone stands anywhere
	# for good.
	if to == Phase.PARKED:
		_move.be_parked(_body.parks())
	elif to == Phase.LEAVING or to == Phase.DONE:
		_move.be_parked(false)

## How long it has existed, in seconds: its own clock (`_age`).
func age() -> float:
	return _age

## **A telegraph or notice that has run its time is over**: asked wherever the notice clock or
## the age moves, so the stored phase is never behind the clock.
func _settle_the_notice() -> void:
	if phase == Phase.WARNING and chase_age() >= notice_time():
		transition(Phase.ACTIVE)

## Whether this cyclist is drawn as the pelican (`EventPictures.PELICAN_BY_VIEW`) rather than the
## kid. Set once, by `EventManager` as it creates the rider, and never changed afterwards, so a
## rider is one or the other for its whole ride. **The picture is all it changes**: the def, the
## field, the lethal radius, the speed and the cost are the row's own either way, and nothing reads
## it but the drawing and the telemetry (`logged_name()` and the pelican's own `EventBus` signals).
## Meaningless on any look but `CYCLIST`. See `FigureLook._rider_pictures()`.
var _is_pelican := false

## **Tells it that it is the pelican**, as its spawner makes it (`EventSpawner.rolls_a_pelican()`
## rolls it after the rider is made): the picture it is drawn as (`is_drawn_as_a_pelican()`) and the
## name the run log calls it by (`logged_name()`).
func be_drawn_as_the_pelican() -> void:
	_is_pelican = true

## What every run log line and every GoatCounter event calls a pelican, in place of its row's own
## `cyclist` (inbox #527 in azure-tapir).
const PELICAN_NAME := "pelican"

## This event as a thing that charges the baby (`EventExcitement`): its present rate at a point,
## its ledger of what it has landed, its projection and its caret's strength.
var _excitement := EventExcitement.new(self)

## The box, in this node's own space, that what this instance draws roughly fills
## (`EventFootprints.drawn_box_of()`), with the run its own street gives a spread. Worked out once,
## on first asking, from what `setup()` decided.
func drawn_box() -> Rect2:
	if not _drawn_box_known:
		_drawn_box_known = true
		_drawn_box = EventFootprints.drawn_box_of(_def, _body.runs_vertically())
	return _drawn_box

var _drawn_box := Rect2()
var _drawn_box_known := false

## Whether this pursuer is coming for her right now: its chase has begun (`EventBus.pursuit_began`'s
## own moment) and it has neither given up nor left. Telemetry only — `EncounterWatch` counts a
## chase as an influence.
func is_chasing() -> bool:
	return _def.pursues() and _charge.began and not is_gone() and not is_on_its_way_out() \
			and not is_waiting()

## Whether this charger's charge has begun and is still running: `EventBus.pursuit_began` sent for
## it (a pursuer's charge, the masked man's run up his shaft) and it has neither left, finished nor
## had its charge end; true for the whole charge. Read by `DangerEdge` and handed to `BadgeModel` as
## `Subject.charging`; on a charger's first moving frame the model meets the charge at its true
## approach rather than its smoothed one and raises its badge from outside the view proper, so it is
## up from the frame he runs.
func has_charged() -> bool:
	return _charge.began and not _charge.ended and not is_gone() and not is_on_its_way_out() \
			and not is_waiting()

## The name the run log and the page's counter call this instance by: `PELICAN_NAME` for a pelican,
## otherwise the row's own `id()`. Telemetry only — nothing that decides anything reads it.
func logged_name() -> String:
	return named_for_the_log(_def.id(), _is_pelican)

## `logged_name()` for a row id and a pelican choice that may not have an instance yet — a warning
## still up (`PendingWarning.logged_name()`).
static func named_for_the_log(id: String, pelican: bool) -> String:
	return PELICAN_NAME if pelican else id

## A mast that has been reached and silenced — `EventStreaming.silence_mast()`/`silence_all_masts()`
## `silence()` it rather than `end_now()`, since a silenced mast still stands, with no arcs and
## no field, and `is_gone()` means *this has left*. Harmless on every row but a mast: nothing
## else ever silences one. See `current_intensity()` and `FigureLook._draw_mast()`.
var _silenced := false

## **Silences it**: a mast reached for the rest of the day (`EventStreaming.silence_mast()`). Its field
## is gone at once, so the contribution its source keeps is let go with it, as every phase change
## lets it go (`transition()`): the present rate would otherwise go on answering the pre-silence
## contribution for the rest of the tick.
func silence() -> void:
	_silenced = true
	_excitement.invalidate_contribution()

## What it is set up in (`EventSurroundings`), handed to `setup()`: asked for the pieces below once,
## there. Open ground and nothing else until it is set up.
var _surroundings := EventSurroundings.new()

## **Where she is** (`WhereSheIs`): this event's own handle on the word `EventManager` tells once a
## physics tick, made in `setup()` from the one it is handed and handed on to its behaviours and its
## excitement source, so all of them ask one object. Nowhere until it is set up, and for an event
## nobody names one for (a rig that steps it directly).
var _where := WhereSheIs.nowhere()

## The shared boom state a `checkpoint_gate` draws raised or lowered from — `GateState`, handed to `setup()` by `EventStreaming.stream_in()` from `EventPlan.gate()`. `null` for
## every look but `CHECKPOINT_GATE`, and read as lowered while it is: a gate that has not been wired
## to `Crowd` yet (or a data-level rig with no crowd at all) draws exactly the safe default.
var _gate_state: GateState = null

## Facing, for art with a front and a back. Only a mobile event ever changes it.
var _heading := Vector2.RIGHT

var _path_travelled := 0.0
var _telegraph_announced := false
var _activation_announced := false

## One gait phase per instance, advanced by the distance actually covered this frame — the
## mother's and the walker's own 0.09-per-px rate (`GAIT_RATE`), pinned again here rather than
## shared because neither exposes it as a constant reachable from this file. Reset in `setup()`
## and `restore()` so a stride never starts mid-cycle — see `_advance_gait()`.
var _gait_phase := 0.0
## Whether this instance actually covered ground on its most recent step (`step()`) — the gate that
## makes a stopped figure (a queue, a give-way, a waiting robber, a chatting mother, a stationary
## yeller, the dog walker's own stop) hold frame a rather than whatever `_gait_phase` last landed
## on. See `_advance_gait()` and `EventLook.gait_is_stepping()`.
var _gait_moving := false
## A deterministic 0..1 drawn once, in `setup()`, from this instance's own siting position — the
## same position-hash approach `EventFlock._roll()` uses, since the day's own RNG is not reachable
## from here and streaming an instance out and back in must not draw twice from it. Offsets the café
## sitters' and the busker's own idle timer (`EventLook.idle_is_stepping()`) so two of either kind
## placed on the same day do not lean or strum in lockstep.
var _idle_phase_offset := 0.0

## **The map of the world this instance stands in** (`WorldMap`), handed in by the manager that makes
## it: the questions about the ground that are not about moving over it — where a body stands on a
## pavement, which way a spread lies, which alley a mouse crosses, whether a wall keeps this field
## from her. The city's map outdoors, the
## building's indoors, and open ground (`WorldMap.open_ground()`) for a data rig that names none,
## where every street question answers "no street" and nothing is walled.
var _map: WorldMap
## **The world this instance is drawn in** (`WorldContext`), handed in by `setup()` as the manager
## makes it: what it adds what it draws beside itself to (`add_beside_it()`, `add_slices_beside_it()`:
## its band, the far guard walking off, the slices of a long picture). Null for a rig that draws it in
## no world.
var _drawn_in: WorldContext
## **How this figure moves, and what it sees along**: every step, walk, way round and way out, and
## every notice, lunge and catch line, go through it (`Navigator`), asked as `_mover`. Handed in by
## `setup()` — `EventManager` hands every figure its world's own — or, for a rig that hands none, one
## over `_map`: on open ground a rig that walks a straight line on purpose gets exactly the
## unclamped movement it asks for.
var _navigator: Navigator
## What this figure walks as (`mover_for()`): a figure on foot or a car, at its body's radius.
var _mover: Mover
## What this figure sees along: the layers `_mover` names, less street ground, which is where a car
## may drive and not what it can see. A car that investigates notices her in an alley mouth or on
## a square as a figure would.
var _sight: Mover
## **What it is on the ground** (`EventBody`): its collision body, the tiles that body is recorded
## on, the axis it lies along on its street, the side a vehicle standing still shows. Made in
## `setup()`, asked for every answer about its body, and told what happens to it.
var _body: EventBody

## The rim `ExcitementHalo` lights on this event (`Rim`), handed to its source: its own body's,
## or the band's while a guard walks away from his barrier.
var _rim := Rim.new(self)

## `reports` is where it says what happened to it (`EventReports`): its world's, which
## `EventSpawner.create()` hands in; one made by hand is handed none and reports to nobody.
func _init(reports: EventReports = null) -> void:
	_reports = reports if reports else EventReports.new()
	_charge = ChargeRecord.new(Callable(self, &"_charger_name"), _reports)
	_excitement.use_rim(_rim)

## Where it says what happened to it: its world's, or a silent one of its own (`_init()`).
var _reports: EventReports

## This event's own simulation clock, in seconds, advanced by `delta` in `step()` while the
## event is still live. `excitement.landed()` is measured against this rather than the wall clock so
## that a paused game does not empty the halo, and so a rig can measure the window on simulated
## time by advancing this directly instead of waiting on the wall clock. Frozen once `is_gone()`
## — see `step()` — so a spent instance's history simply stops moving rather than continuing
## to drain toward zero after nothing more can land on it.
var _clock := 0.0

## **The one setup call**, with everything else the event is handed.
##
## `face` is where a *stationary* event was sited looking. A mobile one overwrites it from the
## direction it is travelling on its first step, which is why the default is harmless.
##
## `surroundings` is what it is set up in (`EventSurroundings`): its map and navigator, where she is
## (the event hears it through a handle of its own, `WhereSheIs.handle_for_an_event()`, that hears
## the word told so far, whatever made it, and hands that to its behaviours and its excitement
## source; nowhere where none was handed), the world it is drawn in, its drawer, its timing sink, its
## trace, the car's lights and where a protest points. None, and it is set up on open ground with
## nothing handed.
##
## `gate` is the boom state a street door's boom shares with the crowd (`GateState`),
## the one hand-in that belongs to the plan and not to the world, so it comes last, and only
## streaming passes one.
func setup(definition: EventDef, at: Vector2, route: PackedVector2Array = PackedVector2Array(),
		face := Vector2.RIGHT, surroundings: EventSurroundings = null,
		gate: GateState = null) -> void:
	_surroundings = surroundings if surroundings else EventSurroundings.new()
	_timing = _surroundings.timing()
	_gate_state = gate
	_drawn_in = _surroundings.world_drawn_in()
	_def = definition
	_path = route
	_where = _surroundings.where_she_is().handle_for_an_event()
	_excitement.use_row_and_where_she_is(definition, _where)
	_map = _surroundings.map()
	_navigator = _surroundings.navigator()
	_mover = mover_for(definition)
	_composed = EventBehaviours.compose(definition, _where, _figure, _map, _navigator, _mover,
			_surroundings.trace(), _surroundings.lights(), _move)
	_move.use_body_radius(_mover.radius)
	_sight = Mover.of(_mover.blocked_by & ~Mover.STREETS)
	# A pursuer whose row walks round buildings to her (the roadblock's posted guard) holds his way
	# from the start; it sweeps nothing until he is after her (`EventPursuit`).
	if definition.walks_round_buildings():
		_chase_way = _navigator.way_to(_mover, _sight)
	var start := BodyStance.stands_at(_map, definition, at)
	position = start
	_heading = face
	look = EventLooks.for_row(self, definition.look(), definition.body(),
			definition.takes_a_victim_by(), _surroundings.drawer(), not _surroundings.draws(),
			_composed.barrier_post())
	look.face(face)
	if look is SpreadLook:
		(look as SpreadLook).letting_go_of_the_slices.connect(_release_rims_on_slices)
	_body = EventBody.new(definition, definition.body(), _map, _where, self, position, face,
			BodyStance.lies_vertically_at(_map, position), _gate_state)
	# What its figure is to a walker that meets it standing: walked round as an object or a vehicle,
	# walked through as a person or an animal (`EventBody.is_walked_round()`).
	_move.be_walked_round(_body.is_walked_round())
	# Whether it has parked, for a crowd car behind it in its lane (`EventBody.parks()`): a figure
	# that never moves has parked from the start; one that drives to where it stops parks once it is
	# there (`transition()`).
	_move.be_parked(_body.has_parked_from_the_start())
	# A stride never starts mid-cycle — the mother's own `reset_at()` precedent.
	_gait_phase = 0.0
	_gait_moving = false
	_idle_phase_offset = _position_roll(101)
	# A row that waits has not noticed her yet; any other is in its telegraph from now, or past a
	# telegraph of no length.
	if definition.waits_for_her():
		_notice.stop()
		phase = Phase.WAITING
	else:
		_notice.start(0.0)
		phase = Phase.WARNING
		_settle_the_notice()
	if definition.route().kind() == RouteSpec.Kind.ACROSS_ITS_ALLEY:
		# Placed on the map with no route at all, so its own dash is built here, from the alley it
		# actually landed in rather than a flat offset, and cut to the ground it fits on.
		_path = _navigator.trim(_alley_crossing_path(_map, position), _mover)

## The alley (`WorldMap.alley_at()`) that `at` falls inside, in **world** space, or an empty
## `Rect2` when it is not inside any — open ground, the building, or a placement that has fallen
## off the lattice. `corridor_offset` cannot answer this the way `BodyStance.lies_vertically_at()`
## does: an alley is cut into the middle of a block rather than laid on the periodic street
## pattern that function reads, so its own tiles are never on a corridor at all.
static func _alley_rect_at(map: WorldMap, at: Vector2) -> Rect2:
	var rect := map.alley_at(map.world_to_tile(at))
	return map.tile_rect_to_world(rect) if rect.has_area() else Rect2()

## A two-point dash across the **short** side of the alley `at` sits in, for `alley_mouse` — see
## `EventCatalogue._alley_mouse()`. `_alley_rect_at` gives the alley's own rect rather than a
## direction guessed from the street lattice, so the choice of axis is exact: `ALLEY_WIDTH_TILES`
## (2) is always the narrower side of a real alley, and she can only be walking the longer one, so
## crossing the narrower side is crossing her path by construction rather than by luck.
##
## Falls back to a short fixed dash along local X where no alley holds it — `_alley_rect_at`
## returning empty — which a city's `MAP` placement never lets happen: on open ground, and in the
## building, whose basement mouse crosses its corridor this way.
static func _alley_crossing_path(map: WorldMap, at: Vector2) -> PackedVector2Array:
	var rect := _alley_rect_at(map, at)
	if rect.size == Vector2.ZERO:
		return PackedVector2Array([at - Vector2(32.0, 0.0), at + Vector2(32.0, 0.0)])
	if rect.size.y > rect.size.x:
		# Narrower in X: a vertical alley, walked along Y, crossed along X.
		return PackedVector2Array([Vector2(rect.position.x, at.y),
				Vector2(rect.position.x + rect.size.x, at.y)])
	# Narrower in Y, or square (never happens at `ALLEY_WIDTH_TILES` 2 against a block-length
	# alley, but ties go the same way `BodyStance.lies_vertically_at()` ties do): a horizontal alley, walked
	# along X, crossed along Y.
	return PackedVector2Array([Vector2(at.x, rect.position.y),
			Vector2(at.x, rect.position.y + rect.size.y)])

func _ready() -> void:
	# Stepped on the physics tick (`EventManager` steps it), so it is drawn interpolated between two
	# ticks as she is, and moves as smoothly as she does. Placed here, so drawn from where it stands
	# rather than gliding in from the origin.
	reset_physics_interpolation()
	_reports.tell_event_telegraphed(self)
	_telegraph_announced = true
	# `BodySpec.SolidWhen.ONCE_IT_STARTS` is the one row shape that does not put its body down here
	# — see its own doc, and `_become_solid_once_it_starts()` below, which is where it goes down.
	_body.come_into_the_world(_heading)
	# A car's body is its `shape` (`EventDef.drives()`), put down here like any other unless she is
	# already where it would stand, in which case `_become_solid_once_it_starts()` puts it down the
	# first frame she is not — a body never goes down around her.
	if _composed.car() and _composed.car().gap_to_her(position, _heading) >= 0.0:
		_body.go_down(_heading)
	if _composed.flock():
		_composed.flock().build()
	look.build_nodes()

## Where its body stands, which is where the street is still shut: `global_position`, or where a
## barrier's guard left it (`EventBarrierPost.body_position()`), so a caller never has to ask which
## case it is holding.
func body_position() -> Vector2:
	var post := _composed.barrier_post()
	return post.body_position() if post else global_position

## **Whether a waiting charger would raise his warning in her view**: the whole of his warning
## picture (`warning_rect()`) inside the camera's view this frame (`WhereSheIs.view()`; inbox #788
## in minty-lemur). Every charger that waits for her and pursues notices her only then, on a day as in
## the escape, so his warning never starts off the screen, and his warning's clock starts from
## there. The view is the camera's own, look-ahead and trailing included. Always true for any other
## row, and for an instance nobody has handed a view (an empty view, a rig that steps it
## directly), where the notice is the radius alone.
func _would_stand_in_her_view() -> bool:
	var view := _where.view()
	if not _def.pursues() or not warns_by_radius() or not view.has_area():
		return true
	return view.encloses(warning_rect())

## The world rect his warning picture fills, at the widest and tallest of its views, standing on his
## feet: a roadblock's guard at the post on her side of the band
## (`EventFootprints.warning_guard_rect()`), anyone else where he stands.
func warning_rect() -> Rect2:
	if _composed.barrier_post():
		return EventFootprints.warning_guard_rect(_body.runs_vertically(), body_position(),
				_where.at())
	var size := EventFootprints.warning_picture_size(_def.look())
	return Rect2(global_position - Vector2(size.x * 0.5, size.y), size)

## How far a figure's body reaches round its feet when the row's own shape is the solid it stands
## at rather than the figure — a guard at his band — in px: the alley robber's own, a man on foot.
const FIGURE_RADIUS := 9.0

## **What a row walks as** (`Mover`): a car that drives as a vehicle, kept to the street and passing
## a soft seal's pavement; anything else as a figure on foot, stopped by everything that stops her.
## Its radius is the row's own shape where that shape is the thing that moves — a dog, a bike, a
## car — and a man's (`FIGURE_RADIUS`) where the shape is a solid he stands at.
static func mover_for(row: EventDef) -> Mover:
	var radius := FIGURE_RADIUS
	var shape := row.ground_shape()
	if shape != null and (not row.has_a_body() or row.drives()):
		radius = shape.reach()
	return Mover.vehicle(radius) if row.drives() else Mover.on_foot(radius)

## Where each of this instance's solid pieces stands, in world space, with its ground shape and the
## axis its spine lies along as it heads now (`EventBody.standing_pieces()`).
func standing_pieces() -> Array[StandingPiece]:
	return _body.standing_pieces(global_position, _heading)

## Built by its rim the first time `ExcitementHalo` picks this instance, never in
## `_ready()`: a day has dozens of events live at once, and a rim each would take every block the
## web's renderer can read — see `EntityHalo`'s class doc. `EntityHalo` gets the look's own
## `EventLook.draw_body` and `EventLook.current_bob` so its ring rides the same lift
## `EventLook.draw()` gives the body.
func _build_halo() -> EntityHalo:
	var halo := EntityHalo.new(look.draw_body, look.current_bob)
	var holder := _rim_holder()
	holder.add_child(halo)
	halo.position = global_position - holder.global_position
	# **First child, so first of the behind-parent drawers.** The rim and the visible scene's layers
	# (`EventScenery`) both opt into `show_behind_parent`, and siblings that do are painted in
	# tree order, so a rim after the scenery, which `_ready()` builds long before any pick, would
	# paint over the pictures it is meant to outline.
	holder.move_child(halo, 0)
	return halo

## What the rim stands behind: this node, or what the look names instead (`EventLook.rim_holder()`,
## the first slice of a long picture drawn in slices, so the rim is behind the whole picture as it
## is behind a picture drawn on this node).
func _rim_holder() -> Node2D:
	var holder := look.rim_holder()
	return holder if holder != null else self

## Whether this instance is solid right now (`EventBody.is_solid()`). True from `_ready()` for
## anything with a body, false once a pursuer that had a body stops waiting — see `_tick()` —
## false through the notice of a `BodySpec.SolidWhen.ONCE_IT_STARTS` row, which is what that setting is for,
## and false while a boom (`BodySpec.SolidWhen.WHILE_LOWERED`) stands raised (`is_raised()`).
func is_solid() -> bool:
	return _body.is_solid()

## Whether this boom's arm is up right now — `GateState.is_boom_up()`, which only `Crowd`
## writes. `false` with no gate handed to `setup()`, the same safe default the drawing reads: a gate
## that has not been wired to the cars is a lowered one.
func is_raised() -> bool:
	return _gate_state != null and _gate_state.is_boom_up()

## The body of a `BodySpec.SolidWhen.ONCE_IT_STARTS` row, put down the frame its notice ends — **unless she is
## standing in it** (`EventBody.come_down_clear_of_her()`), in which case the vent goes on emitting
## at full rate and stays passable until she is out of the footprint — and a car's body, held back
## from `_ready()` while she stood where it would stand, put down the first frame she does not.
func _become_solid_once_it_starts() -> void:
	var car := _composed.car()
	if car and not _body.is_in_place() and car.gap_to_her(position, _heading) >= 0.0:
		_body.go_down(_heading)
		return
	if not _body.waits_to_come_down():
		return
	if is_gone() or is_on_its_way_out() or is_waiting() or is_telegraphing():
		return
	_body.come_down_clear_of_her(global_position, _heading)

# -------------------------------------------------------------------- a car ---
# `EventDef.drives()`: a body that moves and never into her, and a strike ahead of its nose while it
# drives — `EventCarDriving`, which answers for the car below.

## **The end of its route, reached or cut short** (`EventRouteWalk`), acted on only for a committed
## pose. A figure's step is checked as each part of it is taken (the navigator's swept step), so the
## pose it reached the end on is already the one it keeps, and it is done there at once. A car's step
## is checked once its whole tick is proposed (`EventCarDriving.check()`), which may take the pose
## back: while that step is open the end is kept (`_ends_its_route_on_commit`) and acted on once the
## step is committed (`_commit_the_step()`), never if the pose that reached it is taken back.
func _end_its_route(may_park := true) -> void:
	if _composed.car() != null and _move.is_mid_step():
		_ends_its_route_on_commit = true
		_may_park_on_commit = _may_park_on_commit and may_park
		return
	_be_done(may_park)

## The end of its route reached during an open car step (`_end_its_route()`), with whether it may
## park there, acted on once the step is committed.
var _ends_its_route_on_commit := false
var _may_park_on_commit := true

## Where this event charges its time to the frame record, from its surroundings
## (`EventSurroundings.timing()`), kept as a member of its own. With the record off, `_process()`
## pays a member read and one `is_on()` call, and its body stays in `_process()` itself: a static
## read and a call into a second function for it would cost every player more, once per live event a
## frame (docs/evidence/m159-frame-record-2026-10-04/).
var _timing := FrameTiming.new()

## **A drawn frame only redraws.** What the event does is stepped on the physics tick by its manager
## (`step()`); here it takes the draw layer its warning puts it on (`_take_the_layer_it_warns_on()`),
## and its look asks for a redraw if the picture changed, moves its drawing nodes and hides what a
## finished event leaves (`EventLook.redraw_if_the_picture_changed()`), all from the state the last
## tick left, so the tick writes no drawing property. Timed under the record's events, as the step
## is.
func _process(_delta: float) -> void:
	if look == null:
		return
	_take_the_layer_it_warns_on()
	if _timing.is_on():
		var outer := _timing.enter(FrameTiming.EVENTS)
		look.redraw_if_the_picture_changed()
		_timing.leave(outer)
		return
	look.redraw_if_the_picture_changed()

## Whether a hand holds it still, so its manager does not step it: a scene recipe that walks it
## itself (`SceneRecipeRuntime`). Its drawing goes on.
var _held_by_hand := false

## Whether a hand holds it still (`hold_by_hand()`): its manager does not step it.
func is_held_by_hand() -> bool:
	return _held_by_hand

## Takes it into the hand that walks it (`is_held_by_hand()`): its manager stops stepping it, and the
## hand walks it on (`walk_on_by_hand()`). A scene recipe's held event, once it is leaving.
func hold_by_hand() -> void:
	_held_by_hand = true

## **Walks it on by hand by `delta` seconds**, for the hand that holds it (`is_held_by_hand()`, a scene
## recipe's held event, `SceneRecipeRuntime`): the straight walk away along its heading at its
## departure's own pace (`EventDeparture.speed()`), its stride advancing by the ground covered, as
## the departure's plain branch walks it (`EventDeparture.leave()`), with no removal and no
## manager's step. Its move stands where it now does (`MoveProposal.place()`), since the crowd's
## separation pass reads the move, not the node.
func walk_on_by_hand(delta: float) -> void:
	var step := _composed.departure().speed() * delta
	position += _heading * step
	_move.place(position)
	_path_travelled += step
	_advance_gait(step)

## **One physics tick of the event**, which its manager runs in a fixed order
## (`EventManager._step_them()`), **proposed, checked, then committed** (`MoveProposal`, the world's
## shape for every mover's step): the step is opened at the pose it stands at
## (`_propose_the_step()`), the tick works out where it goes, and the step is closed
## (`_commit_the_step()`), checked by its checker and committed. A figure's checker is the
## navigator, which every step of its walk, chase and departure goes through as it is taken, so its
## proposal arrives at the close already checked; a car that drives is checked there by its own
## checks (`EventCarDriving.check()`), which take the step back where it would bring the body into
## her. Nothing once it is finished.
func step(delta: float) -> void:
	if is_gone():
		return
	_propose_the_step()
	_tick(delta)
	_commit_the_step()

## Its move this tick (`MoveProposal`), its own, on its map's list of moves (`WorldMap.moves`) while
## it is in the world: one that keeps its course rather than giving way (`MoveProposal.yields`),
## reaching as far round its centre as it walks or drives through the navigator (`mover_for()`).
## Outside a step it stands where the event does: it joins there (`_enter_tree()`), and a move to
## other ground (`move_to()`) puts it there too.
var _move := MoveProposal.new()

## Opens the step at the pose it stands at; a car notes what its check will hold the step to.
func _propose_the_step() -> void:
	_move.propose(position)
	_ends_its_route_on_commit = false
	_may_park_on_commit = true
	if _composed.car() != null:
		_composed.car().note_the_pose()

## **Closes the step**: the pose the tick proposed is checked (a car's own checks; a figure's were
## made as each part was taken), committed, and only then is what the tick decided on it acted on —
## the end of a car's route reached on a pose it keeps (`_end_its_route()`) — and a car's body laid
## along its heading.
func _commit_the_step() -> void:
	_move.step_to(position)
	var ends := _ends_its_route_on_commit
	_ends_its_route_on_commit = false
	if _composed.car() != null and not _composed.car().check(ends):
		ends = false
	var at := _move.commit()
	if position != at:
		position = at
	if _composed.car() == null or is_gone():
		return
	if ends:
		_be_done(_may_park_on_commit)
	_composed.car().turn_the_body()

## What it does in one tick, run by `step()`.
func _tick(delta: float) -> void:
	_clock += delta
	_age += delta
	_hold_the_notice_clock(delta)
	_settle_the_notice()
	if _composed.barrier_post():
		_composed.barrier_post().walk_the_far_guard_off(delta)
	# The gait phase advances by whatever this tick actually adds to `_path_travelled` below,
	# whichever behaviour does the adding or none of them — see `_advance_gait()`, called once at
	# every exit from this function.
	var _travelled_before := _path_travelled

	if not _activation_announced and not is_telegraphing():
		_activation_announced = true
		_reports.tell_event_activated(self)

	if is_on_its_way_out():
		_composed.departure().leave(delta)
		for behaviour in _composed.in_tick_order():
			behaviour.step_leaving(delta)
		_advance_gait(_path_travelled - _travelled_before)
		var post := _composed.barrier_post()
		if post and post.has_left_its_body() and not is_gone():
			# He walks off and the barrier does not go with him: its body stays where it was built
			# through the departure as through the chase (its picture is its own node).
			post.keep_the_body()
		return

	if is_chatting():
		# The one thing that runs while she is otherwise frozen (`EventHold.step()`): her own controls
		# are locked by `Stroller.detain()`, and here only the hold's clock runs.
		_composed.hold().step(delta)
		# Frozen, so no distance is covered — `_advance_gait(0.0)` marks the frame stopped rather
		# than leaving `_gait_moving` at whatever it read the tick before the conversation started.
		_advance_gait(0.0)
		return

	# What it does, in the order it was composed (`EventBehaviours.compose()`): each behaviour
	# decides for itself whether this tick is one it acts on.
	for behaviour in _composed.in_tick_order():
		if behaviour.steps_each_tick:
			behaviour.step(delta)

	# A car that drives keeps its body through a chase (`EventDef.drives()`): cars that drive
	# are the only bodies that move, and `EventCarDriving` is what keeps them off her.
	if _body.is_in_place() and pursues() and not drives() and not is_waiting():
		# **Anything that stands still is solid at the width it is drawn, and nothing else is.**
		# The pursuit's own note on its step says why a moving pursuer may not keep a body
		# (`EventPursuit`): giving a pursuer one would let a moving wall pin her against a
		# building on a two-tile pavement.
		# A hunting `abduction` or raid never gets here: it lets its men out
		# (`EventDef.investigates()`) and stays parked, solid, while its men come after her.
		#
		# **`PursuitSpec.leaves_its_body_standing()` is the other case, and it is not an exception to that rule.** The
		# body still stops moving with the pursuer; it stops moving at all. A barrier built across
		# a road is not the bulk of the man who was standing at it, so he walks out of it and it
		# stays where it was built — the street he abandoned stays shut. Nothing is pinned, because
		# nothing follows her.
		if _composed.barrier_post():
			_composed.barrier_post().leave_the_body()
		else:
			_body.drop()

	_become_solid_once_it_starts()
	# A boom's body follows its arm (`EventBody.follow_the_arm()`), once a step.
	_body.follow_the_arm()

	_advance_gait(_path_travelled - _travelled_before)
	if _has_expired():
		_be_done()
	var post := _composed.barrier_post()
	if post and post.has_left_its_body() and not _guard_spent:
		# The body is a child of a node that is walking away, so it is re-pinned on every frame he
		# moves. The band's picture is its own node (`RoadblockLook.RoadblockBand`), which stands at
		# the body and needs no redraw for it. A spent guard moves nothing, so there is nothing to
		# re-pin.
		post.keep_the_body()

## **A pursuer that warns over the street is drawn on the warning layer for the whole of its
## warning** (`PursuitSpec.is_drawn_over_the_street()`, `DrawLayer.Layer.WARNING`): the roadblock's guard,
## from the frame he steps out to his post with his hand raised until he charges, over every figure
## on the street, under the city's overhead layer. Once he charges he sorts with the street again,
## on the entity layer at his own feet. Taken on the drawn frame (`_process()`), from the phase the
## last tick left: a look never writes the event, and the tick writes no drawing property.
func _take_the_layer_it_warns_on() -> void:
	if not _def.pursues() or not _def.pursuit().is_drawn_over_the_street():
		return
	DrawLayer.draw_on(self, DrawLayer.Layer.WARNING if is_standing_for_its_notice()
			else DrawLayer.Layer.ENTITIES)

# ------------------------------------------------------------------- the hold ---

## Whether a conversation or a door's hold is running right now (`EventHold`). Freezes pacing (see
## `_tick()`) and switches a mother's posture from strolling to talking
## (`FigureLook._draw_chatting_mother`).
func is_chatting() -> bool:
	return _composed.hold() != null and _composed.hold().is_running()

## Whether the guard this instance draws is inside with her for its own hold right now — he is the
## one taking her in, so he is not also standing in the street, see
## `Stroller.hide_for_inspection()`. `HoldSpec.detains_again()` is the flag only `checkpoint_hut` and
## `checkpoint_post` carry (the boom, `checkpoint_gate`, blocks rather than inspects), so
## `chatting_mother`, which holds her by the same mechanism without it, keeps her ordinary
## talking posture for the whole of her own conversation instead.
func is_its_guard_inside() -> bool:
	return _def.detains_again() and is_chatting()

## Whether this instance has ever held her (`EventHold.has_held()`). `CheckpointController` does
## not start a second hold on a row that has held her and does not `detains_again()`.
func has_chatted() -> bool:
	return _composed.hold() != null and _composed.hold().has_held()

## Starts a hold, the frame `CheckpointController.check_detentions()` decides she has come within
## `_def.detain_distance()` of an instance that may take her (`EventHold.start()`).
func start_chat() -> void:
	if _composed.hold():
		_composed.hold().start()

## Whether the chase ended because she shook it off rather than because the clock ran out. Read by
## the telemetry, which is the only thing that can tell the two apart from outside.
var _gave_up := false
## **Its notice's clock** (`Warning`, read against `age`): started when it exists for a row with no
## wait, and when it notices her for one that waits (`EventDef.waits_for_her()`); stopped while
## it waits. `chase_age()` is its elapsed time, and a stream-out carries its start (`save()`).
var _notice := Warning.new()
## Its charge as it is counted — its warning, its start and the one way it ended — and the one
## owner of the rule that a charge that began ends in exactly one way (`ChargeRecord`). A row with
## no wait (`is_waiting()` never true) starts chasing on its very first `EventPursuit` call rather than
## on a notice, so whether it has begun is the record's `began`.
var _charge: ChargeRecord
## **A checkpoint hut's guard raising his hand**: true while a crossing of this hut's door is
## warning her and this hut is the one across the road from her, or this alley post's
## (`CheckpointController.warn_at_the_doors()`, which sets it every frame, through
## `raise_its_guards_hand()`); once the crossing's warning has run with her still across, this hut's
## guard comes out and charges at once (`PursuitSpec.Start.CHARGES_AT_ONCE`). Drawn with
## `guard_alert_front` beside the hut instead of `guard_standing`
## (`CheckpointLook._draw_checkpoint_hut()`, asking `is_its_guard_warning()`).
var _guard_warns_her := false

## **Whether this instance has a charging counter**: every pursuer, and a row that waits for her
## and runs its own line at her once she is near (`NoticeSpec.runs_within()`, the masked man in the
## escape's stairwell). Telemetry only.
func counts_a_charge() -> bool:
	return _def.pursues() or _def.runs_its_own_line()

## The name a charge is counted under (`EventBus.pursuit_warned`, `pursuit_began`, `pursuit_caught`,
## `pursuit_ended`): the row's `EventDef.charges_counted_as()` where it sets one (the task guard
## sent from out of her view counts as `task_guard`), otherwise the row's own `id()` — the day-3
## lesson's dog is `charging_dog_tutorial` by its own row. Telemetry only.
func _charger_name() -> String:
	return _def.charges_counted_as() if _def.charges_counted_as() != "" else _def.id()

## **Its charge caught her**, said once: by `EventManager.check_hard_fails()` when its catch ends
## the day, ahead of `hard_fail_triggered`, and by a patrol car's man the frame he stops her
## (`EventOfficer`), whose catch does not. Telemetry only: it sends
## `EventBus.pursuit_caught` and keeps `_be_done()` from also sending `pursuit_ended`, so a charge
## ends in exactly one of caught, shaken off, outlasted and cut short, whatever the day does (inbox
## #764 in minty-lemur). Nothing for a row with no charging counter (`counts_a_charge()`) or a
## charge that has not begun.
func report_the_catch() -> void:
	if counts_a_charge():
		_charge.catch()

## **Its charge was cut short**: the day, or the escape's section, ended some other way while it
## was still charging — the meter reached its cap, another thing caught her, she reached home.
## Sends `EventBus.pursuit_cut_short` once, so that charge too ends in exactly one counted way.
## Asked by `EventManager.end_the_charges_still_running()` as a walk ends.
## Telemetry only.
func report_the_charge_cut_short() -> void:
	if counts_a_charge() and not is_gone():
		_charge.cut_short()

## Sends `EventBus.pursuit_warned` once for this instance: its warning has gone up. Never for one
## that charges at once (the checkpoint guard): his warning was the hut's or the post's guard's
## raised hand, counted where it went up (`CheckpointController`), so a crossing counts one warning
## at an alley's door as at a boom.
func _report_the_warning() -> void:
	if counts_a_charge() and not _def.starts_by(PursuitSpec.Start.CHARGES_AT_ONCE):
		_charge.warn()

## **Whether its notice is a warning she is shown, standing**, rather than its approach: one that
## warns by radius, the man a vehicle lets out (`PursuitSpec.Start.SETS_OFF_BESIDE_HER`), day 13's
## guard raising his warning in her view. Its charge, and so its `-chased`, comes only when that
## ends; a pursuer whose telegraph is its approach (the day-3 dog) has come for her from its first
## frame.
func _its_notice_is_a_warning() -> bool:
	return warns_by_radius() or _def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) \
			or _stands_for_this_notice

# ------------------------------------------------------------ the investigation ---

## A car that stood for its man is quiet until it has left her (`EventInvestigation`).
func is_quiet_for_its_man() -> bool:
	var investigation := _composed.investigation()
	return investigation != null and investigation.is_quiet_for_its_man()

## How many men this vehicle has stopped for and still owes (`EventInvestigation`). Read by
## `EventsAhead.let_the_officers_out()`.
func officers_owed() -> int:
	return _composed.investigation().officers_owed() if _composed.investigation() else 0

## Hands the vehicle one man `EventManager` put down at its door, so it stands until he is back
## (`EventInvestigation.let_out()`), and starts his trail at that door with this vehicle as the one
## he walks back to (`EventOfficer.let_out_of()`).
func let_out(officer: EventInstance) -> void:
	if _composed.investigation():
		_composed.investigation().let_out(officer)
		officer.walk_back_to(self)

## Starts this man's trail back to `vehicle`, the one that let him out
## (`EventOfficer.let_out_of()`); nothing for an event that is no man on foot.
func walk_back_to(vehicle: EventInstance) -> void:
	if _composed.on_foot():
		_composed.on_foot().let_out_of(vehicle)

## **One of its men has stopped her: every man it let out walks back to it** (inbox #669 in
## coral-lark), so a vehicle that let out more than one man whose catch is a stop costs her once,
## not once a man. Every man this vehicle let out (`EventInvestigation.its_officers()`) but
## `stopped_by`, the one who stopped her and stands with her through his stop first, is over and
## walks back. Asked by that man's figure the frame he stops her (`Figure.stopped_her()`).
func call_back_its_officers(stopped_by: EventInstance) -> void:
	if _composed.investigation():
		for officer in _composed.investigation().its_officers():
			if officer != stopped_by:
				officer._be_done()

## Where a man gets out: beside the body's flank on her side, clear of it by his own reach, `along`
## px from its middle along its length — `side` 1 for her side, -1 for the other.
func door_for_its_officer(row: EventDef, side := 1.0, along := 0.0) -> Vector2:
	var across := _heading.orthogonal()
	var her := _where.at()
	if her != Vector2.INF and (her - global_position).dot(across) < 0.0:
		across = -across
	var reach := _def.ground_shape().rounding_radius() + (row.ground_shape().reach() if row.ground_shape() else 0.0) + 1.0
	return global_position + across * side * reach + _heading * along

# ------------------------------------------------------------------- the stop ---

## Whether this man has reached her and stopped her (`EventOfficer`, `PursuitSpec.stop_excitement()`).
func has_stopped_her() -> bool:
	return _composed.on_foot() != null and _composed.on_foot().has_stopped_her()

## **Ends this chase from outside it**, in the state `EventPursuit` leaves a pursuer she has outrun:
## `_gave_up` set and `_be_done()` called, so the same departure, drawing and "gave up" line as an
## ordinary shake-off. A checkpoint hut's hold has done what the chase was for, whatever the chase
## was doing, a telegraph still running included
## (`CheckpointController._end_the_guard_for_a_hold()`). A second call, or one on anything finished
## or leaving, is a no-op.
func give_up_the_chase() -> void:
	if is_gone() or is_on_its_way_out():
		return
	_gave_up = true
	_be_done()

## **Notices her now, wherever she is**: a waiting pursuer set on her by what she did rather than
## by what it saw — day 13's waiting guard the moment she has done the roadblock's task
## (`ResistanceDirector._set_the_task_guard_on_her()`). It is
## `EventPursuit`'s notice without its range and its clear line: the clock starts, he turns to her,
## and from then on he is an ordinary pursuer, closing only to his stand-off while his notice runs
## and lunging only along a clear line; noticed inside his stand-off, his lunge is held
## (`EventPursuit.was_set_on_her()`). A guard already warning her by sight is set on her the same
## way, since she could walk out of his warning and he would never come. Nothing for a row that does
## not pursue, a pursuer already charging, leaving or done, or a `her` of `Vector2.INF`. **A row
## that left before it ever noticed her still answers `is_waiting()`**, and the task guard is moved
## with his state rather than made again (`EventManager.move_extra()`), so the leaving guard is
## refused here: a man walking off is never turned back into a warning.
##
## `her` is the order's own point: the heading, the notice clock and the pursuit's set-on-her take
## it, and **it tells the event nothing about where she is**, which stays the manager's word
## (`WhereSheIs`), so a rig with nobody in the world leaves him hearing nowhere.
##
## `notice` replaces the row's `telegraphs_for()` for this notice when it is not negative, and `stand`
## has him stand still in his warning for it (`is_standing_for_its_notice()`): in her view, day
## 13's guard raises his warning for a second and then charges. From
## here he walks round buildings toward her (`_chase_way`), since he may start a city away, and he
## no longer warns by radius (`warns_by_radius()`, `_set_on_her`).
func notice_her_at(her: Vector2, notice := -1.0, stand := false) -> void:
	if _composed.pursuit() == null:
		return
	if not (is_waiting() or (is_telegraphing() and warns_by_radius())) or her == Vector2.INF \
			or is_gone() or is_on_its_way_out():
		return
	# A warning of his own already under way gives way to the one the task sets: the lunge it held
	# back (`EventPursuit.was_set_on_her()`) and the notice it held still start again from here.
	if stand:
		_charge.warned = false
	if _chase_way == null:
		_chase_way = _navigator.way_to(_mover, _sight)
	_set_on_her = true
	_notice_time = notice
	_stands_for_this_notice = stand
	_notice_her()
	var toward := her - global_position
	if toward.length() >= 1.0:
		_heading = toward.normalized()
	_composed.pursuit().was_set_on_her(her)

# ------------------------------------------------------------- the way round to her ---

## The way he walks to her round buildings rather than straight at her (`ChaseWay`, made by
## `Navigator.way_to()`), or null for a pursuer who chases straight. Two pursuers have one: the
## roadblock's posted guard, from `setup()`, since his row asks for it
## (`EventDef.walks_round_buildings()`), so a walker who turns the next corner past his post is
## caught as a straight walker is; and day 13's task guard, from `notice_her_at()`, which only the
## done task calls, for the waiting guard it sets on her from wherever he stands — at another
## roadblock, a city away, with blocks between them. Every other pursuer starts within sight of her
## or just off screen with a straight run at her, so it keeps the straight line its step through the
## navigator slides along walls (`EventPursuit`, `Navigator.step()`). *Proposed, not asked for:* the
## way round is for these two guards alone.
var _chase_way: ChaseWay
## Whether `notice_her_at()` set it on her, by what she did rather than by what it saw (day 13's
## task guard): a pursuer set on her so keeps a timed notice rather than warning by radius
## (`warns_by_radius()`), whether or not it has a way round.
var _set_on_her := false
## The notice `notice_her_at()` was given, in seconds, or negative for the row's own
## `telegraphs_for()` (`notice_time()`).
var _notice_time := -1.0
## Whether `notice_her_at()` asked it to stand still with its warning up for that notice
## (`is_standing_for_its_notice()`), as day 13's task guard does in her view.
var _stands_for_this_notice := false

## How far along its route this instance has got, so streaming it out and back in can restore it
## instead of rewinding it. See `EventStreaming.stream_in`.
func path_travelled() -> float:
	return _path_travelled

## How fast and which way this thing is actually travelling, in px/s.
##
## Asked by `WarningBoard.warn_about_the_ground_she_is_on`, which has to know whether a lethal
## thing is coming *at her* rather than merely near her — walking orthogonally away from a cyclist
## must take the mark down, because there is no way it can reach her.
##
## Zero while a pursuer is telegraphing, and that is the interesting case rather than an omission:
## it is holding its stand-off, so it is not closing, and a mark that said otherwise would be
## warning her about a thing that is deliberately waiting.
func travel_velocity() -> Vector2:
	if is_gone() or is_on_its_way_out():
		return Vector2.ZERO
	# **A parked row is not travelling, whatever its speed says.** The screen-edge badge reads this
	# as a closing speed, and an engine standing at a kerb is not closing on anybody.
	if has_parked():
		return Vector2.ZERO
	if _def.pursues():
		if is_waiting() or is_telegraphing():
			return Vector2.ZERO
		return _heading * _def.chase_speed()
	if _def.moves() and _def.speed() > 0.0 and _path.size() > 1 and not is_telegraphing_still():
		return _heading * _def.speed()
	return Vector2.ZERO

## `travel_velocity()`'s own answer, except for a pursuer that has been noticed and is holding
## its telegraph's stand-off: the caret's projection asks where this is *going*, which is
## `PursuitSpec.speed()` toward her the instant it has decided to come, not the moment its lunge is
## allowed to fire. `travel_velocity()` itself has to stay zero there — the exclamation mark's
## "it is not closing" reads that answer literally, and a mark that said otherwise would warn her
## about a thing that is deliberately holding still — so this is a second query for the caret
## alone rather than a change to the first one.
##
## **A waiting pursuer still has no course.** `is_waiting()` means nobody has been noticed yet, so
## there is nothing here to project toward; only the moment it decides changes the answer, exactly
## as `travel_velocity()` already has it.
func caret_velocity() -> Vector2:
	if is_gone() or is_on_its_way_out():
		return Vector2.ZERO
	if _def.pursues():
		if is_waiting():
			return Vector2.ZERO
		return _heading * _def.chase_speed()
	return travel_velocity()

## Which way this instance was sited facing (`setup()`'s own `face`), unmoved for anything
## stationary that never turns. A door body's own facing is the street's along-axis rather than
## the direction it is drawn — `RegionPlanner` sites every `checkpoint_hut`/`checkpoint_gate`/
## `checkpoint_post` at a crossing facing the same way — so `EventManager`'s detention teleport can
## read this back as which side of the crossing she is on, whichever of the three bodies actually
## detained her.
func facing_now() -> Vector2:
	return _heading

## Where on its own clock it noticed her, held time counted back in, or `INF` for a row that waits
## and has not noticed her (and for a row with no wait) — what `save()` carries.
func _noticed_at() -> float:
	return _notice.started_at() if _def.waits_for_her() else INF

## Noticing her: its notice's clock starts now and it is warning (`Phase.WARNING`), or already past
## a notice of no length.
func _notice_her() -> void:
	_notice.start(_age)
	transition(Phase.WARNING)
	_settle_the_notice()

## **What it is in the middle of**, as one value a plan carries while this event is out of the world
## (`EventStreaming.stream_out()`): its age, the distance it has walked, where on its clock it noticed
## her, and every behaviour's own state keyed by its class.
func save() -> EventSave:
	var states := {}
	for behaviour in _composed.in_tick_order():
		var state := behaviour.save()
		if not state.is_empty():
			var script: Script = behaviour.get_script()
			states[script.get_global_name()] = state
	return EventSave.new(_age, _path_travelled, _noticed_at(), states)

## Puts an instance back where a previous incarnation of the same plan had got to. Restores the
## age as well as the distance, so the telegraph, the pulse phase and the duration all continue
## rather than starting again — an event that streams in and out must not become immortal by
## being visited twice. The save's notice restores one it had made, so a row streamed out after it
## had noticed her does not come back standing where the day planted it; its behaviours' state
## comes back after the age, the distance and the notice, and a row composed of a behaviour the
## save does not name keeps it fresh. A save of age 0 puts back no moment, only the behaviours.
func restore(saved: EventSave) -> void:
	_restore_the_moment(saved)
	for behaviour in _composed.in_tick_order():
		var script: Script = behaviour.get_script()
		var state := saved.state_of(script.get_global_name())
		if not state.is_empty():
			behaviour.restore(state)

func _restore_the_moment(saved: EventSave) -> void:
	if saved.age() <= 0.0:
		return
	_age = saved.age()
	_settle_the_notice()
	_path_travelled = saved.travelled()
	if _def.waits_for_her() and saved.noticed_at() != INF:
		_notice.start(saved.noticed_at())
		transition(Phase.WARNING)
		_settle_the_notice()
	# A pursuer streamed back in still waiting is the one case that has not begun chasing yet; every
	# other, a row with no wait included, was chasing before it streamed out. **A row created where
	# its warning pointed is not streamed back in**: `EventSpawner.spawn_warned()` sets
	# `arrive_from_its_warning()` before restoring only to spend a telegraph the warning already ran.
	_charge.began = not _came_under_a_warning and not is_waiting()
	# A warning it had already given before it streamed out is not reported again.
	_charge.warned = saved.noticed_at() != INF
	# A stride never starts mid-cycle, the same reason `setup()` resets it — a restored instance is
	# a fresh object, so this is normally already true, but the rule is stated at both entry points
	# rather than left to rely on that.
	_gait_phase = 0.0
	_gait_moving = false
	if _def.moves() and _path.size() > 1:
		_composed.route().advance(0.0)
	# Put back where it was, not slid there from wherever it was made.
	reset_physics_interpolation()

## **Stands it at `at`, keeping everything it is in the middle of**: its phase, its notice, every
## behaviour's state. What setup reads off the ground it stands on is read again for the new ground
## (the axis of a spread, which side a parked vehicle shows, its idle phase), and its field is asked
## afresh. `EventManager.move_extra()` is the caller, which records its body again.
func move_to(at: Vector2) -> void:
	var stands := BodyStance.stands_at(_map, _def, at)
	global_position = stands
	_move.place(position)
	_body.land_at(stands, _heading, BodyStance.lies_vertically_at(_map, stands))
	_idle_phase_offset = _position_roll(101)
	_excitement.invalidate_contribution()
	reset_physics_interpolation()
	queue_redraw()

# ------------------------------------------------------------------- the take ---

## Whether the van's take of a bystander is running right now (`EventAbduction`), for
## `EventVehicleLook._draw_abduction` and for a test to drive by hand.
func is_taking_a_victim() -> bool:
	return _composed.abduction() != null and _composed.abduction().is_taking()

## How long the victim of the van's take has been walking to it, in seconds, while the take runs
## (`EventAbduction.walked_for()`): what the van's look places and strides the victim by. Nothing,
## 0, for a row with no take and between takes, as an event without a part answers that part's
## questions.
func how_long_its_victim_has_walked() -> float:
	return _composed.abduction().walked_for() if is_taking_a_victim() else 0.0

# ------------------------------------------------------------------ the flock ---

## The radius one bird emits over (`EventFlock.bird_outer()`), or 0 without a flock: the outer ring
## `field_rings()` gives a flock, the exact radius `_flock_contribution_at()` sums over.
func _flock_outer_radius() -> float:
	return _composed.flock().bird_outer() if _composed.flock() else 0.0

## Each live bird's own ground-plane offset from this instance's origin — empty for anything
## without a flock. What `DebugLayers` draws one pair of radii per bird from.
func flock_offsets() -> Array[Vector2]:
	if _composed.flock() == null:
		return [] as Array[Vector2]
	return _composed.flock().offsets()

## Each live bird's own `heading * speed`, parallel to `flock_offsets()`.
func flock_velocities() -> Array[Vector2]:
	if _composed.flock() == null:
		return [] as Array[Vector2]
	return _composed.flock().velocities()

## Its birds (`EventFlock.birds`), or none for a row that is one body.
func birds() -> Array[EventFlock.Bird]:
	return _composed.flock().birds if _composed.flock() else _NO_BIRDS

static var _NO_BIRDS: Array[EventFlock.Bird] = []

# --------------------------------------------------------------- going away ---
# **Nothing vanishes while you are looking at it.** An event that ends by `end_now()` wherever it
# happens to be standing ends, for the two shortest-lived rows in the game, directly in front of
# her: the cat's route is one street wide and ends in the open, and the pigeons hang in the air for
# a fifth of a second. The end of an event is a **departure**, not a deletion.
#
# What is deliberately *not* here: a fade. A thing that fades out is still a thing that disappears,
# and it disappears in a way nothing in the world could explain. The cat runs on, the flock climbs
# away, the dog that lost interest trots off — and each of them is gone because it left.

## The end of an event: it leaves if it has anywhere to go, and stops existing if it has not.
##
## Three things never leave, and each would break something that reads the finishing position. An
## event with an `aftermath.leaves_behind()` stops **where the thing it leaves belongs** — the escape's
## explosion leaves its crater where it went off, not two streets past it. Anything with no departure
## speed has no way to go anywhere; a café that closes is simply over. And a row with
## `EventDef.route().parks_where_it_arrives()` **parks**: the fire engine is sent to the near kerb
## across from the building (`EventSpawner._where_the_summoned_row_stops()`) and stays there for the
## rest of the day, because a standing field beside a fire she was led to is the cost that makes the
## pair a street to turn round on rather than one to hurry past.
##
## **Parking is not being over.** It still emits, it still carries its cue, and it can still end a
## day that has a way to be ended by it — `is_on_its_way_out()` would take all three away, which is why this
## is a third branch rather than a flag on the departure.
##
## Everything else that runs out of route drives on and is gone.
func _be_done(may_park := true) -> void:
	if phase == Phase.DONE or phase == Phase.LEAVING or phase == Phase.PARKED \
			or phase == Phase.SPENT:
		return
	if counts_a_charge():
		# `VisitCounter`'s own "-shaken"/"-outlasted" — a charge that had begun is over without
		# catching her, `_gave_up` telling which of the two ways. A charge that caught or was cut
		# short already ended, so the record says nothing (`ChargeRecord`).
		_charge.end(_gave_up)
	if _def.parks_where_it_arrives() and may_park:
		transition(Phase.PARKED)
		# The gait is driven by distance covered, so the distance has to stop here or a parked
		# engine bobs for ever at the kerb. Clamped to the route's own length rather than left
		# where the last step put it, so `path_travelled()` still answers "the whole route" for a
		# streaming restore.
		_path_travelled = _composed.route().length()
		queue_redraw()
		return
	if (_composed.departure().speed() <= 0.0 or _def.leaves_behind() != ""):
		end_now()
		return
	transition(Phase.LEAVING)
	_composed.departure().begin()

## Ends this instance early because a resistance step's contact rode on it and she has just
## completed the step — called by `ResistanceDirector._on_contact_completed()` on the instance
## the step was actually reached through (`_rider` after retargeting), never on the seeded one if
## she reached a look-alike first. It is the same departure everything else in the game leaves
## by: no field while leaving, walking away, gone once out of sight — so a finished task reads as
## the world answering rather than as text on the HUD.
##
## **Unlike a departure `_be_done()` reaches on its own** — a route run out, a duration expired —
## this one has no route left to finish, so the heading is always turned away from her, overriding
## `_be_done()`'s "something on a route carries on the way it was going": a paced fixture stopped
## mid-beat is heading in whichever direction its beat happened to be walking, which is toward her
## exactly as often as away.
##
## **And she is standing right next to him when it starts**, unlike everything else that leaves —
## so the departure is held to her sight: its six-second backstop does not pop him out of
## existence mid-screen while she is still nearby (`EventDeparture`).
##
## **A row that parks where its route runs out leaves anyway when asked** — the warned neighbor,
## whose ordinary end is standing at the door (`RouteSpec.parks_where_it_arrives()`) and who runs
## instead: this departure is the task's answer, not the route's.
func leave_for_a_completed_task() -> void:
	if is_gone() or is_on_its_way_out() or has_parked():
		return
	_be_done(false)
	if not is_on_its_way_out():
		return
	_composed.departure().for_a_completed_task()

## **Leaves down a way chosen for it** (`EventDeparture.along()`): day 12's park people, walked out
## through the cordon's last gap rather than through the tape. Answers whether it is now leaving
## along the way.
func leave_along(way: PackedVector2Array, speed := 0.0, avoid := Rect2i()) -> bool:
	return _composed.departure().along(way, speed, avoid)

## What is left of the way `leave_along()` set, in order (`EventDeparture.way_left()`).
func way_left() -> PackedVector2Array:
	return _composed.departure().way_left()

## True once the guard who set off from a barrier is gone for good, and this instance is only the
## barrier: solid and silent, for as long as the roadblock would have stood
## had he never set off. He does not come back for her, and **the guard who stayed at the other
## post walks off with him** (`RoadblockFarGuard`), so the band stands unmanned: nothing
## notices or chases from this instance again. (A choice open to overturn; the alternative is that
## the one who chased walks back to his post and the barrier is armed again.)
var _guard_spent: bool:
	get:
		return phase == Phase.SPENT

func _has_expired() -> bool:
	if is_waiting():
		# It has not happened yet, and it is not going to until she walks up to it.
		return false
	# **A vehicle waits for its men**: a hunting van's `duration` runs from its notice, and a van
	# gone from the kerb would leave a man walking back to nothing. It may leave only once every
	# man it let out is back in.
	if _composed.investigation() and not _composed.investigation().all_back():
		return false
	return _def.lasts_for() > 0.0 and chase_age() >= notice_time() + _def.lasts_for()

## **Ends it now**, from outside as well as from its own step: it leaves as an event that is over does
## (`transition()` into `Phase.DONE`), and its manager frees it in its ordinary sweep
## (`EventStreaming.retire_finished()`). The resistance's guard over a chalk mark that has moved is
## ended so (`EventSpawner.retire()`).
func end_now() -> void:
	transition(Phase.DONE)

# ------------------------------------------------------------------ emission ---

## True while the event is visible but has not yet reached full strength: `Phase.WARNING`, ended
## when its clock has run (`_settle_the_notice()`) or, for a pursuer that comes for her through its
## telegraph (the day-3 dog), when she walks up to its stand-off first (`EventPursuit`). **A
## telegraph is a promise about the encounter's clock, not its phase**: a row that leaves,
## parks, stops or is done before that answers true until the clock runs out — the day-3 dog
## shaken off at 2s into its 4.5s telegraph is still telegraphing as it trots away, to the mark,
## the alert and its pictures.
func is_telegraphing() -> bool:
	if phase == Phase.WARNING:
		return true
	if phase == Phase.ACTIVE or phase == Phase.WAITING or _telegraph_ended or is_waiting():
		return false
	return chase_age() < notice_time()

## True while a pursuer that noticed her stands for its notice in its alert pose rather than closing
## on her (`PursuitSpec.stands_for_its_notice()`): the dog that waited, the hunting roadblock's guard, the
## man a vehicle lets out, and day 13's guard set on her in her view (`notice_her_at()`). **Asked of
## the def the instance was handed**, so the day-3 dog — the same row, sent down her heading with no
## trigger to have waited behind — is false here and spends its telegraph coming, which is the
## lesson; and false for anything that has not noticed her yet or has lunged.
func is_standing_for_its_notice() -> bool:
	var stands := _def.pursues() and _def.pursuit().stands_for_its_notice()
	return (stands or _stands_for_this_notice) and is_telegraphing() \
			and (_def.waits_for_her() or _def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER))

## **Holds a row that crouches before its run `seconds` longer** — a crossing whose run a solid cut
## short (`EventDef.crouch_for_a_run()`), so it still reaches the middle when she does. Its telegraph
## only grows, so the fairness contract it was validated under still holds.
func hold_still_longer(seconds: float) -> void:
	if seconds > 0.0 and _def.holds_still():
		_notice_time = notice_time() + seconds

## How long this instance's notice runs once it has noticed her: a charger that warns by radius
## warns for its row's `PursuitSpec.warns_for()` (`warns_by_radius()`); anything else for its row's
## `telegraphs_for()`, the notice a task gave it when it set it on her (`notice_her_at()`), or a
## crossing's crouch held longer (`hold_still_longer()`).
func notice_time() -> float:
	if _notice_time >= 0.0:
		return _notice_time
	if warns_by_radius() and _def.pursues() and _def.pursuit().warns_for() > 0.0:
		return _def.pursuit().warns_for()
	return _def.telegraphs_for()

## True for a row that waits (`EventDef.waits_for_her()`) and has not noticed her: its notice's
## clock is not running. That is `Phase.WAITING`, and it stays true of such a row that leaves or is
## gone without ever having noticed her, and of a barrier whose guard has gone for good
## (`Phase.SPENT`), which waits for nothing. Waiting, it emits at full strength unless its notice is
## quiet, it is not lethal, and it does not move.
func is_waiting() -> bool:
	return _def.waits_for_her() and not _notice.is_running()

## How long this has been *happening*, which is not always how long it has existed.
##
## For everything in the catalogue but one it is the age. For a pursuer that waits, the clock starts
## when it notices her — a telegraph spent at dawn, four streets away, is not a notice, and
## `telegraphs_for()` and `duration` are both promises about the encounter rather than about the day.
##
## It is the notice's own clock (`_notice`, a `Warning` read against `age`), less whatever held it:
## a held lunge with her inside its stand-off, a waiting charger behind a wall at its warning's last
## moment, the masked man's wait. Zero for a row that waits and has not noticed her.
func chase_age() -> float:
	return _notice.elapsed(_age)

## **Whether this pursuer warns by radius rather than by a clock**: one that waited for her and
## noticed her by sight (`EventDef.waits_for_her()` on the def it was handed) — the dog that
## waited, the alley robber and every guard drawn from his row, the hunting roadblock's guard
## (inbox #788 in minty-lemur). **One radius, and a warning on a clock inside it**: from the
## frame it notices her inside `EventDef.notice_within()` it warns for its row's
## `PursuitSpec.warns_for()` (`notice_time()`); back outside the radius before that, the
## warning stops and it waits again (`EventPursuit`), its clock reset; still inside when it
## runs out, it charges.
##
## **Not one set on her by what she did** (`notice_her_at()`, day 13's task guard, `_set_on_her`):
## he is sent after her from wherever he stands, often a city away, so a radius he has to be inside
## would leave him nothing to do; he keeps his timed notice. Nor one with no trigger — the day-3 dog
## and everything sent at her from off screen, whose approach or badge is the warning — nor one that
## sets off beside her, whose notice is a clock by construction.
func warns_by_radius() -> bool:
	return _def.waits_for_her() and (_def.pursues() or _def.runs_its_own_line()) \
			and not _def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) and not _set_on_her

## **The stand-off a pursuer closes to and holds**, `PursuitSpec.standoff()` over
## `EventDef.standoff_reach()`: the distance a pursuer that comes for her through its telegraph
## lunges from (the day-3 dog's gold timing is spent at it), and where one that walks at her through
## its warning (the robber) stops. A charger that waits for her charges on its warning's clock, not
## on this distance (`warns_by_radius()`).
func charge_radius() -> float:
	return PursuitSpec.standoff(_def.chase_speed(), _def.standoff_reach())

## **Holds the notice clock for this tick** (`_notice.hold()`), run straight after `age`
## advances and before the phase is settled, so a frame whose notice is held is never seen as
## the charge starting. Every notice runs, a waiting charger's warning included
## (`notice_time()`), held only: while a held lunge has her inside its stand-off
## (`EventPursuit.pause_a_held_notice()`); at a waiting charger's last moment while a wall stands
## between them, since **his charge needs a clear line** (inbox #650 in mossy-beaver), so he goes
## on warning until the line clears or she leaves his radius; and for every tick of a row that runs
## its own line (`EventNoticeRun`, the masked man), whose run comes only from her coming
## within `NoticeSpec.runs_within()`. A held clock is what a stream-out carries (`save()`),
## so it comes back exactly as far run.
func _hold_the_notice_clock(delta: float) -> void:
	if _telegraph_ended or is_waiting():
		return
	if _def.runs_its_own_line() and chase_age() - delta < _def.telegraphs_for():
		_notice.hold(delta)
		return
	var her := _where.at()
	if warns_by_radius() and _def.pursues() and her != Vector2.INF \
			and chase_age() >= notice_time() and chase_age() - delta < notice_time() \
			and not clear_line_to(her):
		_notice.hold(delta)
		return
	if _composed.pursuit():
		_composed.pursuit().pause_a_held_notice(delta)

## Current peak intensity at the centre: its row's peak through its swell and its pulse
## (`EventDef.peak_through()`), after this phase's damping (`_notice_damping()`).
##
## `pulse_multiplier_override` (`< 0.0` means "not given") replaces the instant's own
## `0.25 + 0.75 × pulse(age)` reading (the row's `beat`) — the only caller that ever passes one is
## `caret_intensity_over_horizon()`, asking for the pulse's own mean over
## `Tuning.EXPECTED_IMPACT_HORIZON` instead of the beat this instant happens to be on.
func current_intensity(pulse_multiplier_override := -1.0) -> float:
	if is_gone() or is_on_its_way_out():
		# On the way out it is scenery. Emitting while it goes would mean the excitement of an
		# event trailing after her for as long as it took the thing to get off screen.
		return 0.0
	if _silenced:
		# A silenced mast still stands, but its field is gone — unlike `is_gone()`, which means
		# the thing itself has left. See the field's own doc.
		return 0.0
	if is_quiet_for_its_man():
		return 0.0
	if has_stopped_her():
		# **The stop** (`PursuitSpec.stop_excitement()`): from twice its mean rate to nothing over
		# `Tuning.OFFICER_STOP_SECONDS`, so its whole lands that many points on her standing
		# beside him — at the centre of his own field, which is where his catch puts her. A short sharp
		# spike rather than a field she strolls out of, and his field, so walking away takes some
		# of it off. Nothing after it: he is walking back by then (`_tick()`).
		var stopped := _composed.on_foot().stopped_for()
		var into := clampf(stopped / Tuning.OFFICER_STOP_SECONDS, 0.0, 1.0)
		return 2.0 * _def.pursuit().stop_excitement() / Tuning.OFFICER_STOP_SECONDS * (1.0 - into)
	if is_chatting():
		# A flat rate for the whole conversation rather than a falloff: she is inside `inner radius`
		# by construction (`detain_distance() < inner radius`), so there is no distance to shape.
		# Gated on whether the baby is awake (`WhereSheIs.baby_is_awake()`), read and never
		# written: `chatting_mother`'s conversation is the one row whose contribution differs by the
		# baby's own state, and the read happening here keeps excitement a pure query. It is what
		# makes "asleep, it is a pure time loss" true of the meter and not only of the words:
		# nothing here scales through `Baby.SLEEPING_SENSITIVITY`, it emits exactly zero.
		return (Tuning.CHAT_EXCITEMENT / _def.detains_for()) if _where.baby_is_awake() else 0.0
	# The swell is measured on `chase_age()` rather than `age`, so a ramp measures the burst rather
	# than the wait in front of it: for everything without a trigger the two are the same number,
	# and for a row that stood on a pavement half the morning before she came near, `age` would
	# hand the first instant of the burst the multiplier the *end* of it is meant to have. The
	# pulse beats on `age` rather than `chase_age()` on purpose: a pulse is the thing's own rhythm,
	# which is running whether or not anybody has walked up to it.
	return _def.peak_through(_age, chase_age() - notice_time(), pulse_multiplier_override) \
			* _notice_damping()

## The pulse envelope's own mean over `[age, age + Tuning.EXPECTED_IMPACT_HORIZON]`, closed-form
## rather than stepped: the projection wants one scalar to hold across its whole sampling loop, not
## a second loop just to average a cosine.
##
## **Mean rather than instant, and from this instant's own phase.** `homeless_yeller`'s pulse (5s)
## and `busker`'s (7s) both turn over inside the horizon (5s), so freezing "as it stands now" would
## read anywhere from a quarter to the full peak depending on which beat the caret is asked on,
## while the halo reads back whatever the walk actually crossed. The mean answers "if this keeps
## pulsing, what does the *whole* of the next five seconds average to".
##
## **Exactly `0.625` (the envelope's own mean) whenever the horizon is an exact multiple of the
## period, whatever the phase** — `homeless_yeller`'s 5s pulse against the 5s horizon is exactly
## this case, since a cosine integrated over any whole number of its own periods is exactly zero
## however it is entered. `busker`'s 7s pulse against the same 5s horizon is the case that genuinely
## depends on phase, which is the one the closed form below has to get right rather than the one a
## quick sanity check would be tempted to hard-code.
static func _pulse_mean_multiplier(age: float, horizon: float, period: float) -> float:
	var w := TAU / period
	var mean_cos := (sin(w * (age + horizon)) - sin(w * age)) / (w * horizon)
	return 0.625 - 0.375 * mean_cos

## The multiplier the phase this instance is in puts on its row's peak, and the one place the
## three answers live — `caret_intensity_over_horizon()` divides by exactly this rather than
## repeating the conditions, so the caret's projection and the meter can never disagree about which
## phase damps.
##
## **The damping says *this has not started yet*, and for a waiting row that is a claim about the
## thing rather than about its clock.** A pursuer that waits has been standing there since she came
## round the corner — what has not started is the lunge, not the man — so its notice is the one
## telegraph in the game that does not quieten what it is warning about. A quiet notice
## (`NoticeSpec.is_quiet()`) is the opposite case and it is a real one: birds pecking on a pavement
## are nearly nothing until they go up, so both their wait and their notice damp like an ordinary
## telegraph. Its row says which (`EventDef.warns_quietly()`).
func _notice_damping() -> float:
	if is_waiting():
		return TELEGRAPH_INTENSITY_FRACTION if _def.warns_quietly() else 1.0
	if is_telegraphing() and _def.warns_quietly():
		return TELEGRAPH_INTENSITY_FRACTION
	return 1.0

## `current_intensity()` with the telegraph's own damping undone — the rate this row will
## actually carry once it is live, which is what the caret's own projection has to sum rather
## than the fraction a telegraph is reading right now. Everything else `current_intensity()`
## accounts for — the ramp, the pulse, chatting — still applies; only the final multiplier is
## skipped, by dividing it back out of the same call rather than a second copy of the ramp and
## pulse logic above it.
##
## Only the projection reads this (`ExcitementSource.expected_gross_at()`). Every caller of the
## present rate — the halo, the exclamation mark, the meter itself — wants what a source is
## actually doing right now, damped or not, because it is asking about the present rather than
## about the course this thing is on. Without this, a `cyclist` ridden straight at a standing
## player through its own 2s telegraph reads at `TELEGRAPH_INTENSITY_FRACTION` (15%) the whole
## time, and the projection under-counts the approach by the same fraction.
##
## **And a pulse is projected at its own mean over the horizon, not at this instant's beat** — see
## `_pulse_mean_multiplier()`'s own doc for why a frozen instant could read anywhere from a quarter
## to the full peak of a row whose pulse turns over inside `Tuning.EXPECTED_IMPACT_HORIZON`.
func caret_intensity_over_horizon() -> float:
	var pulse_override := -1.0
	var period := _def.pulses_every()
	if period > 0.0:
		pulse_override = _pulse_mean_multiplier(_age, Tuning.EXPECTED_IMPACT_HORIZON, period)
	return current_intensity(pulse_override) / _notice_damping()

## **This event's field at a point**, with no question about what stands between: what its source
## charges on open ground (`EventExcitement`), and what the caret's projection asks before it asks
## about walls at the two bodies' own projected places.
##
## `intensity_override` (`< 0.0` means "not given") replaces `current_intensity()`: the projection
## passes `caret_intensity_over_horizon()`, the row's live rate, in place of whatever a telegraph has
## it damped to. `velocity_override` (`Vector2.INF` means "not given") replaces `travel_velocity()`
## for the kernel: the projection translates the sample point by `caret_velocity()`, and the ellipse
## that point is measured against has to be oriented by that same velocity — a pursuer holding its
## stand-off is still, and about to lunge.
func field_at(world_position: Vector2, intensity_override: float,
		velocity_override: Vector2) -> float:
	if is_gone():
		return 0.0
	if is_on_its_way_out():
		# A leaving event emits nothing, a guard walking away from his barrier included: a
		# roadblock's band has no field strength of its own (`EventCatalogue._roadblock()`).
		return 0.0
	var intensity := intensity_override if intensity_override >= 0.0 else current_intensity()
	if not birds().is_empty():
		return _flock_contribution_at(world_position, intensity)
	var velocity := velocity_override if velocity_override != Vector2.INF else travel_velocity()
	# `EventDef.emission_at_distance()` rather than `Field.falloff` direct, so the one row with a
	# two-part field is charged for both parts here and not only in the cost table — and so that a
	# row shaping its own drop-off (`FieldSpec.falling_off()`) is felt as the shape it is priced at.
	# The peak handed over is this phase's, so the telegraph and the pulse damp the core and the
	# field together; an uncored row is charged its plain falloff.
	return _def.emission_at_distance(_field_distance(world_position, velocity), intensity)

## The distance `field_at()` prices this row's field at — `GroundShape.field_distance()`
## over this row's own shape (D1's `body ⊕ disc` stationary, D2's `point ⊕ ellipse` moving), or the
## same kernel with no body at all for the handful of emitting rows with no shape (`playground`,
## whose look is drawn by the park itself rather than by `EventInstance`).
func _field_distance(world_position: Vector2, velocity: Vector2) -> float:
	return field_distance_from(global_position, field_shape(), solid_axis(), world_position,
			velocity)

## `_field_distance()` with its datum handed in — where the field stands, its shape (null for a
## point) and the axis its body lies along: the kernel the caret's projection prices every sample
## with too, its datum read once before it samples (`EventExcitement._begin_the_projection()`),
## since nothing about it moves while the projection runs.
func field_distance_from(centre: Vector2, shape: GroundShape, axis: Vector2,
		world_position: Vector2, velocity: Vector2) -> float:
	if shape != null:
		return shape.field_distance(centre, axis, velocity, world_position)
	return GroundShape.eccentric_distance(centre, velocity, world_position)

## The datum this row's field is priced from (`field_distance_from()`) and drawn from (`DebugLayers`):
## its row's (`EventDef.datum()`), its shape or none — a point at its centre.
func field_shape() -> GroundShape:
	return _def.datum()

## Its row's ground shape (`EventDef.ground_shape()`), or null for a row with no picture: the
## outline its shadow is drawn over (`DebugLayers`).
func ground_shape() -> GroundShape:
	return _def.ground_shape()

## Everything the row can put on the screen about its feet, caret included
## (`EventFootprints.footprint_of()`). Asked by the look, which merges the run its street gives a
## spread into it.
func footprint() -> Rect2:
	return EventFootprints.footprint_of(_def)

## Whether it moves along a route of its own (`EventDef.moves()`).
func moves() -> bool:
	return _def.moves()

## How fast it comes at her under its own steam, in px/s: its chase speed for a pursuer, otherwise
## its route's speed (`EventDef.approach_speed()`). What a figure's bob follows.
func approach_speed() -> float:
	return _def.approach_speed()

## The peak rate of its field at its centre, or 0 for a row with no field (`EventDef.peak()`): what
## the share it emits now is measured against.
func peak() -> float:
	return _def.peak()

## How many seconds one beat of its field's pulse lasts, or 0 for a row that does not pulse
## (`EventDef.pulses_every()`).
func pulses_every() -> float:
	return _def.pulses_every()

## Its notice radius, or 0 for a row with no wait (`EventDef.notice_within()`).
func notice_within() -> float:
	return _def.notice_within()

## A flock is its birds, summed.
##
## The same shape as `WorldContext.excitement_sources_at` one level down: nothing is pushed anywhere, the
## sources compose by plain addition, and there is no ordering to get wrong. Each bird carries an
## equal share of the event's intensity over a radius that leaves room for the wheel, so the middle
## of the flock — where four or five fields overlap — comes out at about what the event says it is
## and the edge of it at a fraction. That gradient is the whole reason to do it this way: the price
## of a flock should depend on whether you walked through it or round it, and one disc centred on
## nothing in particular cannot say that.
##
## **Each bird is its own point kernel**, eccentric by its own `heading * speed` rather than the
## instance's own `travel_velocity()` (always zero for a flock — it does not move along a route
## of its own and is no pursuer) — a cheap read off `Bird`, already carried for the wheel, so a bird
## diving toward her costs more than one peeling away exactly as any other moving point in the
## game does. The bodies stay points either way: a flock's own field was never a capsule, and
## eleven of them is not where the general capsule-and-ellipse sum earns its cost.
func _flock_contribution_at(world_position: Vector2, intensity := -1.0) -> float:
	var total_intensity := intensity if intensity >= 0.0 else current_intensity()
	var share := total_intensity / float(birds().size())
	var outer := _composed.flock().bird_outer()
	var total := 0.0
	for bird in birds():
		total += _def.bird_emission_at(_bird_distance(bird, world_position), share, outer)
	return total

## The distance a bird's own kernel prices `world_position` at: eccentric about where the bird is by
## its own `heading * speed`. The one place a bird's datum is worked out, for the flock's field
## (`_flock_contribution_at()`) and its reach (`field_reaches()`) alike.
func _bird_distance(bird: EventFlock.Bird, world_position: Vector2) -> float:
	return GroundShape.eccentric_distance(global_position + bird.at(), bird.heading() * bird.speed,
			world_position)

## True when a point is inside the radius that ends the day, for a hard-fail event that is
## no longer merely telegraphing.
##
## **Measured from this node, at `_def.lethal_reach()`** — which is the field's own core for almost
## every row and a separate, smaller number for one whose killer is not what the field is drawn
## around. A roadblock is that row: the node is the man once he leaves the post, and what he
## reaches with is a pair of arms rather than the width of the barrier he left standing.
##
## **A pursuer catches her only by touching her**, so its catch also needs a clear line to her (the
## strict one, `_navigator.clear_line()` with no own tiles): within reach across a building's
## corner is not a catch (freckled-goose #544). The reach is unchanged; nothing may stand between
## them. Every other lethal row keeps the straight-line distance.
##
## **Cars that drive are the only rows lethal whose row does not end the day** (`ends_the_day()`
## is false; `EventDef.drives()`): one strikes her in front of its nose while it drives its
## route and she is on the carriageway, and nowhere else — not behind it, not beside it, not
## while it stands (`EventCarDriving._is_driving()`). A body touching her is not enough, and not
## needed: the strike reaches `EventCarDriving.PATROL_STRIKE_LEAD` of its travel past the touch,
## so a car driving its nose into her strikes her rather than standing for her
## (`EventCarDriving`). Its telegraph is not asked: its warning is a car's,
## `EventCarDriving.closes_on()`, not a field coming up to strength.
func is_lethal_at(world_position: Vector2) -> bool:
	if _composed.car():
		return _composed.car().strikes(world_position)
	# The row's own flag first: it is the one most rows fail, and the two calls after it are pure.
	if not _def.ends_the_day() or is_gone() or is_on_its_way_out() or is_waiting() or is_telegraphing():
		return false
	if global_position.distance_to(world_position) > _def.lethal_reach():
		return false
	return not _def.pursues() or _navigator.clear_line(global_position, world_position, _sight)

## **Whether this car's own course strikes `point` before the horizon is out**, her position held
## fixed (`EventCarDriving.will_strike()`): the doubled caret's question for a car that drives,
## which its source asks in place of a projection of its field. False for anything that does not
## drive.
func will_strike(point: Vector2) -> bool:
	return _composed.car() != null and _composed.car().will_strike(point)

## **The way from it to her where it can see her**: from its node to where she is, when something
## has told it where she is and nothing built stands between them (`clear_line_to()`, the line its
## notice asks), or `Vector2.ZERO` otherwise, standing on her included. What a waiting robber's look
## turns him toward before he has noticed her (`EventLook.robber_waiting_heading()`).
func sight_line_to_her() -> Vector2:
	var her := _where.at()
	if her == Vector2.INF:
		return Vector2.ZERO
	var toward := her - global_position
	if toward.length_squared() <= 0.0001 or not clear_line_to(her):
		return Vector2.ZERO
	return toward

## Whether the straight line from this node to `world_position` crosses only ground this figure
## may enter, street ground or not (`Navigator.clear_line()`, as `_sight`) — the question its notice
## and its lunge ask in `EventPursuit`, since he can neither see nor go for her through a wall, a
## barrier or a café. A catch asks the strict line instead, since a catch across one is a man
## reaching through it (`is_lethal_at()`).
## `WorldMap.clear_line()` walks it, the one walk every caller asks, so a line that clips a
## building's corner by a pixel is blocked however short it is; a guard sees out of the band he
## stands in, and her own tile never hides her. True on open ground, which is every data-level rig
## built without a map, exactly as a step through the navigator is (`Navigator.step()`).
##
## **Seeing out of his own band is not reaching through it.** The line a guard notices her along and
## lunges along does not ask the tiles of his own body (`EventBody.tiles_at()`, where the body
## stands), because he steps out to his post on her side and she may stand on the band's far side;
## the catch above asks every body, his own included, and every other body's tile stops either
## question.
func clear_line_to(world_position: Vector2) -> bool:
	return _navigator.clear_line(global_position, world_position, _sight,
			_body.tiles_at(body_position(), _heading))


## Whether it is holding still through its telegraph — a crouching cat is not walking.
func is_telegraphing_still() -> bool:
	return _def.holds_still() and is_telegraphing()

# ------------------------------------------------------------------- the gait ---
# The event half of "every living thing that moves has a stride" — the walker's own two-frame
# alternation (`WalkerLook.advance()`/`gait_frame_at()`): the stride is kept here, by the ground the
# event covers, and read by whichever look draws a second frame (`EventLook.gait_is_stepping()`).

## The mother's and the walker's own rate, in radians of gait phase per pixel walked. Pinned again
## here rather than shared: neither `Stroller` nor `CrowdAgent` exposes it as a constant reachable
## from this file, and a cross-file literal agreement is worth restating rather than importing.
const GAIT_RATE := 0.09

## Advances `_gait_phase` by `moved` (px covered this tick, positive or exactly zero — `_tick()`
## passes `_path_travelled`'s own delta, which is never negative) and records whether anything moved
## at all, which is the "stopped" gate `EventLook.gait_is_stepping()` reads. Called once per tick, at
## every exit from `_tick()`, the same "add the distance once, however the caller reached this
## point" shape `WalkerLook.advance()` has — asking `EventLook.draw_body()` to do it would double
## the addition once per halo ring, exactly the trap that function's own doc names.
func _advance_gait(moved: float) -> void:
	_gait_moving = moved > 0.0
	_gait_phase = wrapf(_gait_phase + moved * GAIT_RATE, 0.0, TAU)

## A deterministic 0..1 from this instance's own siting position, an index and a salt — the same
## hash `EventFlock._roll()` already uses for a flock's own scatter, generalised to one index (0) since
## nothing outside a flock needs more than one draw. No global RNG is reachable from here, and
## streaming an instance out and back in must not draw from one twice; a hash of where the day
## placed it answers the same way every time the same plan places the same instance.
func _position_roll(salt: int) -> float:
	var mixed := int(position.x) * 73856093 + int(position.y) * 19349663 + salt * 2971215073
	return float(absi(mixed) % 4096) / 4096.0

# ------------------------------------------------------------------ the halo ---
# The ring itself is `EntityHalo`'s, shared with `CrowdAgent` — see that class for the offsets, the
# shared material, and why a `canvas_item` shader on this entity's own sprite could not bloom
# outward on its own.

## The ground-plane direction a spread-shaped shadow sweeps along — local Y when the street this
## instance stands on is east-west, local X otherwise (`EventBody.spread_axis()`). The same axis
## `spread_at()` already lays the drawn body along.
func spread_axis() -> Vector2:
	return _body.spread_axis()

## The ground-plane direction this instance's own solid body's spine lies along
## (`BodyStance.solid_axis_of()`): its heading for a car that drives, its street's axis for a
## spread, the side it shows for a stationary vehicle. Read by its body, its field, its behaviours,
## its look's shadow and `DebugLayers`, so a segment is turned one way everywhere
## (`EventBody.solid_axis()`).
func solid_axis() -> Vector2:
	return _body.solid_axis(_heading)

## **This event's rim** (`SourceRim`), as `ExcitementHalo` lights it once a frame. Its own body's
## rim, with two rules of an event's own on top of the lifetime every rim keeps:
##
## - **A finished event refuses a lit rim**, since it still sits among the live instances for one
##   more frame than its field (already zero) would otherwise buy it.
## - **While a guard walks away from his barrier any rim is the barrier's**, on the band
##   (`RoadblockLook.RoadblockBand`'s own, `band`) and not on the man, who is costing her nothing.
##   **An instance never holds two rims at once** (`ExcitementHalo` counts one block per source
##   against `EntityHalo.RIM_BUDGET`): the man's is given back on the spot as the band's is built,
##   and the band's on the spot as the instance's own is wanted again once the barrier stands alone.
class Rim extends SourceRim:
	var _event: EventInstance
	## The band's rim, built when a departing guard's barrier becomes the thing costing her.
	var band: SourceRim

	func _init(event: EventInstance) -> void:
		super(event._build_halo)
		_event = event
		band = SourceRim.new(event._build_band_halo)

	## Overrides SourceRim.set_strength.
	func set_strength(strength: float, colour: Color) -> void:
		if _event._the_band_carries_the_rim():
			_let_go()
			band.set_strength(strength, colour)
			return
		if band.is_held() and strength > 0.0 and not _event.is_gone():
			band.release()
		else:
			band.set_strength(0.0, colour)
		super.set_strength(0.0 if _event.is_gone() else strength, colour)

	## Overrides SourceRim.is_held.
	func is_held() -> bool:
		return super.is_held() or band.is_held()

	## Overrides SourceRim.release.
	func release() -> void:
		_let_go()
		band.release()

	## Gives back the rims that stand behind a slice of the look (`SpreadLook.Slice`), on the spot,
	## when the look is about to let go of its slices (`SpreadLook.letting_go_of_the_slices`).
	func release_on_slices() -> void:
		if _halo != null and _halo.get_parent() is SpreadLook.Slice:
			_let_go()
		var banded := band.entity_halo()
		if banded != null and banded.get_parent() is SpreadLook.Slice:
			band.release()

## Whether the band carries this event's rim: a guard has left the barrier he stood at and the band
## still stands.
func _the_band_carries_the_rim() -> bool:
	var post := _composed.barrier_post()
	return is_on_its_way_out() and post != null and post.has_left_its_body() \
			and look.band_node() != null and not is_gone()

## The band's rim, behind the band's first slice, drawn before every other part of the band, as a
## rim is behind the picture it outlines (`_rim_holder()`).
func _build_band_halo() -> EntityHalo:
	var halo := EntityHalo.new(_draw_the_band_for_the_halo, func() -> float: return 0.0)
	var holder := (look as RoadblockLook).band_rim_holder()
	holder.add_child(halo)
	halo.position = look.band_node().global_position - holder.global_position
	return halo

func _draw_the_band_for_the_halo(canvas: CanvasItem) -> void:
	look.draw_the_band(canvas, Vector2.ZERO)

func _release_rims_on_slices() -> void:
	_rim.release_on_slices()

## The rim lit around this instance's own picture, or null: the canvas a look draws no shadow on.
func rim() -> EntityHalo:
	return _rim.entity_halo()

# ------------------------------------------------------------------ the look ---

## How this instance looks (`EventLooks.for_row()`, handed its row's look part, its body part and its
## drawer in `setup()`): it draws the instance from what it asks it and, in the family looks, from
## some of its public state, decides when it is drawn again, and holds the drawing nodes a long
## picture is drawn in.
## Public because suites read it: no game file outside this one does, so the CI list of test-only
## members (`tools/test_only_members.txt`) holds it among those only their own file uses.
var look: EventLook

func _draw() -> void:
	look.draw()

## Builds the drawing nodes again when the instance comes back into the tree after leaving it,
## which took them with it.
func _enter_tree() -> void:
	if _map:
		_map.moves.join(_move, position)
	if look:
		look.enter_tree()

## **Takes it out of the world now**: its move leaves the map's list at once and the node is freed
## at the end of the frame. Every place that frees an event goes through here, because the node
## leaves the tree only at the frame's end and a move left on the list until then is a figure
## standing where the event last was (a mover leaves the list on going, minty-quail-34).
func take_out() -> void:
	if _map:
		_map.moves.leave(_move)
	queue_free()

func _exit_tree() -> void:
	if _map:
		_map.moves.leave(_move)
	_rim.band.forget()
	if look:
		look.release_nodes()

## Adds `node` to the world this instance is drawn in, on the entity layer
## (`WorldContext.add_entity()`), or beside it in its own parent where no world draws it — a rig that
## stands it under a bare node.
func add_beside_it(node: Node2D) -> void:
	if _is_drawn_in_a_world():
		_drawn_in.add_entity(node)
	else:
		get_parent().add_child(node)

## Puts `slices` of a long picture into the world at their `feet`, each ahead of this instance in the
## tree so that at a tie of feet its caret is drawn over its own picture (`DrawLayer.add_slices()`),
## or beside it where no world draws it (`DrawLayer.add_slices_beside()`).
func add_slices_beside_it(slices: Array[Node2D], feet: PackedVector2Array) -> void:
	if _is_drawn_in_a_world():
		DrawLayer.add_slices(_drawn_in, slices, feet, DrawLayer.Layer.ENTITIES, self)
	else:
		DrawLayer.add_slices_beside(self, slices, feet)

## Whether a world draws this instance and is still standing.
func _is_drawn_in_a_world() -> bool:
	return _drawn_in != null and is_instance_valid(_drawn_in)

## A point `offset` along whichever axis this instance spreads on (`EventBody.spread_at()`) — local
## X by default, local Y on an east-west street. See `BodyStance.lies_vertically_at()`.
func spread_at(offset: float) -> Vector2:
	return _body.spread_at(offset)

## Whether its spread runs down the screen rather than across it (`EventBody.runs_vertically()`,
## decided from the street it landed on by `BodyStance.lies_vertically_at()`).
func runs_vertically() -> bool:
	return _body.runs_vertically()

## Whether a stationary vehicle shows its side rather than its end (`EventBody.stands_side_on()`).
func stands_side_on() -> bool:
	return _body.stands_side_on()

## The stride's phase, in radians of `GAIT_RATE` per pixel walked (`_advance_gait()`).
func gait_phase() -> float:
	return _gait_phase

## Whether the last tick covered any ground.
func gait_is_moving() -> bool:
	return _gait_moving

## Seconds this instance has been stepped, the idle animations' clock.
func clock() -> float:
	return _clock

## This instance's own offset into an idle animation's period, 0..1, so two of a kind do not swap
## in lockstep.
func idle_offset() -> float:
	return _idle_phase_offset

## The map it stands on.
func world_map() -> WorldMap:
	return _map

# ------------------------------------------------- the figure its behaviours move ---

## **What a behaviour may ask of its event, and tell it.** The event's place, heading, the way it
## has covered, its clocks and its phase are its own; this is the narrow view it builds over them
## (`_figure`) and hands each behaviour it is composed of (`EventBehaviours.compose()`), as
## `LaneMover.Lane` is a lane mover's view of itself. A behaviour asks it questions and tells it
## what happened, and never reads or writes the event's fields; what never changes under a
## behaviour (its settings, the map, the navigator, what it walks as, where she is, the run log the
## event writes to, the behaviours beside it) it is handed instead. **The stored phase changes only in `transition()`**, which a
## behaviour asks for with `begin()`; the notice clock and the charge record stay the event's, and
## are told what happened. An inner class, because it is the event's own view of itself.
class Figure:
	extends RefCounted
	var _of: EventInstance

	func _init(event: EventInstance) -> void:
		_of = event

	# ------------------------------------------------------------------ questions ---

	## Where it stands, in world space.
	func place() -> Vector2:
		return _of.global_position

	## Which way it faces.
	func heading() -> Vector2:
		return _of._heading

	## How far along its way it has come, in px: its route's distance, folded or not.
	func travelled() -> float:
		return _of._path_travelled

	## How long it has existed, in seconds: its own clock.
	func age() -> float:
		return _of._age

	## How long it has been happening (`EventInstance.chase_age()`).
	func chase_age() -> float:
		return _of.chase_age()

	## How long its notice runs once it has noticed her (`EventInstance.notice_time()`).
	func notice_time() -> float:
		return _of.notice_time()

	## The route it walks, in world space; empty, or one point, for one that stands.
	func walks() -> PackedVector2Array:
		return _of._path

	## Whether it waits for her and has not noticed her (`EventInstance.is_waiting()`).
	func is_waiting() -> bool:
		return _of.is_waiting()

	## Whether its telegraph or notice is still running (`EventInstance.is_telegraphing()`).
	func is_telegraphing() -> bool:
		return _of.is_telegraphing()

	## Whether it holds still through a telegraph that is still running
	## (`EventInstance.is_telegraphing_still()`).
	func is_telegraphing_still() -> bool:
		return _of.is_telegraphing_still()

	## Whether its telegraph or notice ended into `Phase.ACTIVE`: run out, or cut short by a lunge,
	## a flush or the masked man's run.
	func notice_has_run() -> bool:
		return _of._telegraph_ended

	## Whether it is over and only getting out of shot (`Phase.LEAVING`).
	func is_on_its_way_out() -> bool:
		return _of.is_on_its_way_out()

	## Whether it has stopped where its route ended, for the rest of the day (`Phase.PARKED`).
	func has_parked() -> bool:
		return _of.has_parked()

	## Whether its guard is gone for good and it is only its barrier (`Phase.SPENT`).
	func is_only_its_barrier() -> bool:
		return _of._guard_spent

	## Whether it is gone (`Phase.DONE`).
	func is_gone() -> bool:
		return _of.is_gone()

	## Whether its field reaches `point` (`EventInstance.field_reaches()`).
	func field_reaches(point: Vector2) -> bool:
		return _of.field_reaches(point)

	## Where its body stands, which is where the street is still shut: where it stands, or where a
	## barrier's guard left it (`EventInstance.body_position()`).
	func body_place() -> Vector2:
		return _of.body_position()

	## Which way its spread runs (`EventBody.runs_vertically()`): down the screen, or across it.
	func runs_vertically() -> bool:
		return _of._body.runs_vertically()

	## The direction its solid body's spine lies along as it heads now (`EventBody.solid_axis()`).
	func solid_axis() -> Vector2:
		return _of._body.solid_axis(_of._heading)

	## Whether the straight line from where it stands to `point` is one it sees along
	## (`EventInstance.clear_line_to()`): what a pursuer's notice, lunge and stop ask.
	func clear_line_to(point: Vector2) -> bool:
		return _of.clear_line_to(point)

	## Whether a waiting charger's warning would stand whole in her view
	## (`EventInstance._would_stand_in_her_view()`).
	func would_stand_in_her_view() -> bool:
		return _of._would_stand_in_her_view()

	## Whether it warns by radius rather than by a clock (`EventInstance.warns_by_radius()`).
	func warns_by_radius() -> bool:
		return _of.warns_by_radius()

	## Whether its notice is a warning she is shown, standing, rather than its approach
	## (`EventInstance._its_notice_is_a_warning()`).
	func notice_is_a_warning() -> bool:
		return _of._its_notice_is_a_warning()

	## Whether it stands for its notice in its alert pose rather than closing on her
	## (`EventInstance.is_standing_for_its_notice()`).
	func is_standing_for_its_notice() -> bool:
		return _of.is_standing_for_its_notice()

	## The stand-off a pursuer closes to and holds (`EventInstance.charge_radius()`).
	func charge_radius() -> float:
		return _of.charge_radius()

	## The way it walks round buildings to her (`ChaseWay`): the posted roadblock guard's from the
	## start, day 13's task guard's once she was set on him from wherever he stood
	## (`EventInstance.notice_her_at()`); null for a pursuer who chases straight.
	func way_round_to_her() -> ChaseWay:
		return _of._chase_way

	## Where its stride is (`EventInstance.gait_phase()`), which a step taken back puts back.
	func gait_phase() -> float:
		return _of._gait_phase

	# ------------------------------------------------------------- what happened ---

	## It turned to face `heading`.
	func turn_to(heading: Vector2) -> void:
		_of._heading = heading

	## It covered `distance` px more of its way, the distance its stride bobs on.
	func walk_on(distance: float) -> void:
		_of._path_travelled += distance

	## Its route goes on by `leg`, whose first point is where the route ends: the points after the
	## first are added to it, and the distance it has travelled carries on down them.
	func walk_further(leg: PackedVector2Array) -> void:
		for i in range(1, leg.size()):
			_of._path.append(leg[i])

	## It stepped by `delta` in world space.
	func step_by(delta: Vector2) -> void:
		_of.position += delta

	## It arrived at `at`, where a walk or its route brought it.
	func arrive_at(at: Vector2) -> void:
		_of.global_position = at

	## It asks for `phase` (`EventInstance.transition()`, the one place the phase changes).
	func begin(phase: EventInstance.Phase) -> void:
		_of.transition(phase)

	## It is over (`EventInstance._be_done()`): it leaves, parks where `may_park` lets it, or is
	## gone where it has nowhere to go.
	func be_done(may_park := true) -> void:
		_of._be_done(may_park)

	## Its route ran out, or was cut short where it stands (`EventInstance._end_its_route()`): over
	## at once, or for a car once its step is committed.
	func end_its_route() -> void:
		_of._end_its_route()

	## It noticed her: its notice's clock starts now and it is warning.
	func notice_her() -> void:
		_of._notice_her()

	## Its warning went up, counted once for a row with a charging counter.
	func warning_went_up() -> void:
		_of._report_the_warning()

	## Its charge began, for its counter (`EventBus.pursuit_began`), said once however often told.
	func charge_began() -> void:
		_of._charge.begin()

	## Its charge, and the warning before it, were said and ended before it streamed out: none of it
	## is said again (`ChargeRecord.count_as_over()`).
	func charge_ended() -> void:
		_of._charge.count_as_over()

	## She shook it off: its chase is over because she outran it (`has_given_up()`), and it is
	## done (`EventInstance._be_done()`).
	func give_up() -> void:
		_of._gave_up = true
		_of._be_done()

	## Its notice's clock is held for `delta` seconds of its age: that much of it does not count.
	func hold_the_notice(delta: float) -> void:
		_of._notice.hold(delta)

	## Its man reached her and stopped her (`Phase.STOPPED`): his catch is counted
	## (`EventInstance.report_the_catch()`), and the vehicle that let him out (`vehicle`, null for
	## none) calls back the other men it let out (`EventInstance.call_back_its_officers()`).
	func stopped_her(vehicle: EventInstance) -> void:
		_of.transition(EventInstance.Phase.STOPPED)
		_of.report_the_catch()
		if vehicle != null:
			vehicle.call_back_its_officers(_of)

	## Its guard is gone for good, and it is only its barrier (`Phase.SPENT`): its notice is over.
	func be_only_its_barrier() -> void:
		_of.transition(EventInstance.Phase.SPENT)
		_of._notice.stop()

	## Its body is held at `at`, in world space, where its guard left it, wherever it moves itself
	## (`EventBody.pin_at()`); nothing for a row with no body.
	func pin_its_body_at(at: Vector2) -> void:
		_of._body.pin_at(at)

	## Its body is under its own feet again, and moves with it (`EventBody.unpin()`); nothing for a
	## row with no body.
	func unpin_its_body() -> void:
		_of._body.unpin()

	## Its body is turned to `angle`, in radians, as a car's spine follows its heading
	## (`EventBody.turn_to()`); nothing before its body is down.
	func turn_its_body_to(angle: float) -> void:
		_of._body.turn_to(angle)

	## Its step was taken back: it faces `heading`, has covered `travelled` px of its way and its
	## stride is at `gait_phase` again, and it stood still this tick.
	func take_back_its_step(heading: Vector2, travelled: float, gait_phase: float) -> void:
		_of._heading = heading
		_of._path_travelled = travelled
		_of._gait_phase = gait_phase
		_of._gait_moving = false

	## It is drawn from where it now stands at once, not slid there between two ticks.
	func appear_where_it_stands() -> void:
		_of.reset_physics_interpolation()

	## She left its notice while it warned: its notice's clock stops and it waits for her again.
	func wait_for_her_again() -> void:
		_of._notice.stop()
		_of.transition(EventInstance.Phase.WAITING)

# --------------------------------------------------------- what a caller asks ---
# The questions a caller outside the events asks a live event, so it never reaches through it to
# its row or its behaviours. Each answers for the row where the question is the row's.

## The row this is a live one of, for the caller that passes the row on (the badge's drawing);
## a caller asking something of it asks this event instead.
func row() -> EventDef:
	return _def

## The id of the row this is a live one of (`EventDef.id()`), which the run log's chase
## lines and the poster walls name it by. `logged_name()` is the name a log line calls the
## thing she met.
func row_id() -> String:
	return _def.id()

## The id of the row it leaves where it ends (`EventDef.leaves_behind()`), or "" for a row that
## leaves nothing.
func leaves_behind() -> String:
	return _def.leaves_behind()

## Whether it is over and gone (`Phase.DONE`).
func is_gone() -> bool:
	return phase == Phase.DONE

## Whether it has stopped being an event and is only getting out of shot (`Phase.LEAVING`). It
## emits nothing, it cannot end the day, and it carries no cue: whatever it was, it is over. **The
## one exception is a guard walking away from his barrier** (`PursuitSpec.leaves_its_body_standing()`): the walk
## ends with the instance still there as the barrier (`EventBarrierPost.stand_as_the_barrier()`, `Phase.SPENT`). The
## barrier costs nothing while he goes, as a roadblock's band never costs anything
## (`EventCatalogue._roadblock()`'s `intensity` 0).
func is_on_its_way_out() -> bool:
	return phase == Phase.LEAVING

## Whether it has stopped where its route ended, for the rest of the day (`Phase.PARKED`): day 10's
## neighbor home before she reached them. A row whose route parks where it arrives parks at the
## end of its route; unlike `is_on_its_way_out()` this is not an ending: it is still the same event,
## standing still. See `_be_done()`.
func has_parked() -> bool:
	return phase == Phase.PARKED

## Whether it was created where a warning pointed, once that warning was over
## (`arrive_from_its_warning()`): the badge it had carries on until it comes into view.
func was_warned_of() -> bool:
	return _came_under_a_warning

## Whether it comes after her (its row's `pursuit`).
func pursues() -> bool:
	return _def.pursues()

## Whether it hunts for her (`EventDef.hunts_for_her()`): at the heat that hunts it stops being a place
## and starts being a hunter, the roadblock's guard or a van that lets out men who pursue her.
func hunts_for_her() -> bool:
	return _def.hunts_for_her()

## **Forgets how long she has been running from it** (`EventPursuit.forget_her_run()`), so its
## chase does not give up because she ran; nothing for an event with no pursuit. A scene recipe's
## relentless pursuer, every tick.
func forget_her_run() -> void:
	if _composed.pursuit() != null:
		_composed.pursuit().forget_her_run()

## **Whether, leaving, it walks straight away from her** at its departure's pace, the departure's
## plain branch (`EventDeparture.leave()`) that `walk_on_by_hand()` reproduces: not a walk down a
## way it was given (`EventDeparture.walks_a_way()`), a man walking back to the vehicle that let
## him out (`EventOfficer.walks_back()`), nor a guard who has left his barrier standing
## (`EventBarrierPost.has_left_its_body()`).
func walks_straight_away() -> bool:
	var man := _composed.on_foot()
	var post := _composed.barrier_post()
	return not (_composed.departure().walks_a_way() or (man != null and man.walks_back()) \
			or (post != null and post.has_left_its_body()))

## Whether it is a car that drives (its row's `vehicle`), whose strike is its driving's.
func drives() -> bool:
	return _def.drives()

## Whether it is a permanent feature of a fixed map that never appears (`EventDef.is_ambient()`).
func is_ambient() -> bool:
	return _def.is_ambient()

## Whether it was sent at her (`EventDef.was_sent_at_her()`): it comes after her, or the caller that
## sent it warned of it first.
func was_sent_at_her() -> bool:
	return _def.was_sent_at_her()

## What it leaves at (`EventDef.departure_speed()`): its own speed if it had one, 0 for a thing that
## stands where it was placed and has no departure of its own.
func departure_speed() -> float:
	return _def.departure_speed()

## How long its row's telegraph lasts, in seconds.
func telegraphs_for() -> float:
	return _def.telegraphs_for()

## Whether walking into its reach ends her day (`EventDef.ends_the_day()`); a car's strike is not
## this, it is its driving's (`closes_on()`).
func ends_the_day() -> bool:
	return _def.ends_the_day()

## How far from its centre its core reaches (`EventDef.core_within()`): the radius inside which
## she is in it, and where the gap to her is measured from.
func core_within() -> float:
	return _def.core_within()

## How far from its centre its row is heard (`EventDef.heard_within()`): the outer edge of its
## field as a disc, which the mark over her head keeps the whole of while it telegraphs.
func heard_within() -> float:
	return _def.heard_within()

## **Whether its guard is gone for good**, leaving only a barrier that waits for nobody
## (`EventBarrierPost.is_spent()`): the guard has set off from it for good, or is on his way out
## having left his body, which `is_only_its_barrier()` does not yet say. False for anything with no
## barrier.
func has_lost_its_guard() -> bool:
	return _composed.barrier_post() != null and _composed.barrier_post().is_spent()

## **Whether this car is closing on `point` with the mark over her head**
## (`EventCarDriving.closes_on()`): false for anything that does not drive.
func closes_on(point: Vector2) -> bool:
	return _composed.car() != null and _composed.car().closes_on(point)

## **Whether its field reaches `point`**, in the shape the field is priced in: the distance
## `field_at()` prices (`_field_distance()`, a stationary body's capsule about its spine, a mover's
## ellipse stretched ahead of it) against how far its row is heard (`EventDef.heard_within()`), so
## the answer is the edge of the field the meter is charged from and not a disc about the centre.
## A flock is its birds: it reaches `point` where any one bird's own point kernel does, over
## `Flock.bird_outer()`. Geometry only: what the field is worth now (a telegraph's damping, a
## finished event's zero) is `field_at()`'s.
func field_reaches(point: Vector2) -> bool:
	if not birds().is_empty():
		for bird in birds():
			if _bird_distance(bird, point) <= _composed.flock().bird_outer():
				return true
		return false
	return _field_distance(point, travel_velocity()) <= _def.heard_within()

## **The two rings of its field**, as the debug view's fields layer draws them (`DebugLayers`): its
## core (`x`, `EventDef.core_within()`) and its outer edge (`y`), which is how far its row is
## heard (`EventDef.heard_within()`) and, for a flock with birds, how far one bird is heard
## (`_flock_outer_radius()`), the radius `field_reaches()` and the flock's own field sum over. A
## value, so the layer asks it once per event per redraw and allocates nothing.
func field_rings() -> Vector2:
	var outer := _flock_outer_radius() if not birds().is_empty() else _def.heard_within()
	return Vector2(_def.core_within(), outer)

## Whether its chase ended because she shook it off rather than because the clock ran out
## (`_gave_up`).
func has_given_up() -> bool:
	return _gave_up

## Whether it holds her when she comes to it (`EventDef.detains_her()`): a chatting mother's
## conversation, a door's hut or post.
func detains_her() -> bool:
	return _def.detains_her()

## How far from its centre her own centre has to come for a hold to begin
## (`EventDef.detain_distance()`).
func detain_distance() -> float:
	return _def.detain_distance()

## How long a hold of hers lasts, in seconds (`EventDef.detains_for()`).
func detains_for() -> float:
	return _def.detains_for()

## Whether it is a door's hut or post, armed again once she has been let out and has walked away
## (`EventDef.detains_again()`).
func detains_again() -> bool:
	return _def.detains_again()

## Whether it is a door's boom, solid only while lowered (`EventDef.is_a_boom()`).
func is_a_boom() -> bool:
	return _def.is_a_boom()

## How far round its centre its body stops her (`EventDef.solid_reach()`): where her centre comes
## to rest against it, which is the reach a door's guard steps out at and she is set down past.
func solid_reach() -> float:
	return _def.solid_reach()

## **Whether it is a place that ends her day and stays where it stands**: not gone, its row ends the
## day (`EventDef.ends_the_day()`) and does not move (`EventDef.moves()`). A guard over a mark, an
## idling van, a reversing lorry: a hazard a route can go round once and stay clear of, where a
## mover is somewhere else by the time the route gets there.
func is_a_standing_lethal_place() -> bool:
	return not is_gone() and _def.ends_the_day() and not _def.moves()

## How far from its centre entering it ends her day (`EventDef.lethal_reach()`), or 0 for one that
## does not.
func lethal_reach() -> float:
	return _def.lethal_reach()

## Whether its body is one the map records for the whole day (`EventDef.stands_as_a_fixed_body()`):
## standing, solid, and no door's.
func stands_as_a_fixed_body() -> bool:
	return _def.stands_as_a_fixed_body()

## **Whether `point` is inside its core**: within its row's core (`EventDef.core_within()`) of where
## it stands, a disc about its centre and not the shape its field is priced in (`field_reaches()`).
## Day 6's note is delivered the moment she is inside the man's core.
func core_reaches(point: Vector2) -> bool:
	return global_position.distance_to(point) <= _def.core_within()

## Whether several of it count as the strongest one only (`EventDef.counts_as_one_barrier()`): the
## pieces of a street being held.
func counts_as_one_barrier() -> bool:
	return _def.counts_as_one_barrier()

## This event as a thing that charges the baby (`EventExcitement`).
func source() -> EventExcitement:
	return _excitement

## Tells it that the hand of its guard goes up (`on`) or comes down: a hut's guard raising his hand
## at her while a crossing of its door is warning her (`is_its_guard_warning()`).
func raise_its_guards_hand(on: bool) -> void:
	_guard_warns_her = on

## Whether its guard has his hand raised at her (`raise_its_guards_hand()`).
func is_its_guard_warning() -> bool:
	return _guard_warns_her

## Whether it is a mast that has been reached and silenced (`silence()`): it still stands, with no
## arcs and no field.
func is_silenced() -> bool:
	return _silenced

## Whether this cyclist is the pelican rather than the kid (`be_drawn_as_the_pelican()`): the one
## picture it changes, for a look to choose its two pedal frames by.
func is_drawn_as_a_pelican() -> bool:
	return _is_pelican

## Where a protest points its placards: what its surroundings ask
## (`EventSurroundings.where_protests_point()`), or `Vector2.INF`, nothing to point at, when it was
## handed nothing.
func where_its_placards_point() -> Vector2:
	return _surroundings.where_protests_point()

## The route it walks, in world space; empty, or one point, for one that stands (`_path`), as a
## plan's `walks()` answers.
func walks() -> PackedVector2Array:
	return _path

## The beat it paces (`RouteSpec.paces_a_beat()`), in world space: its route for one that walks to
## and fro along it, empty for everything else, which has no beat to stand beside.
func beat() -> PackedVector2Array:
	return _path if _def.paces_a_beat() else PackedVector2Array()

## Whether its guard is gone for good and it is only its barrier (`Phase.SPENT`), solid and silent.
func is_only_its_barrier() -> bool:
	return phase == Phase.SPENT

## **Where it stands now, for the plan it is the live event of** (`EventPlan.enter_the_world()`):
## a handle that answers whether it is still there, where, which way it faces and whether it is
## over, so the plan asks these without naming the event. Made new on each call.
func standing() -> WhereItStands:
	return Standing.new(self)

## The event's own `WhereItStands`: its answers are the event's. An inner class, because it is the
## event's own view of itself for its plan.
class Standing:
	extends WhereItStands
	var _of: EventInstance

	func _init(event: EventInstance) -> void:
		_of = event

	## Overrides WhereItStands.is_there.
	func is_there() -> bool:
		return is_instance_valid(_of)

	## Overrides WhereItStands.at.
	func at() -> Vector2:
		return _of.global_position

	## Overrides WhereItStands.facing.
	func facing() -> Vector2:
		return _of.facing_now()

	## Overrides WhereItStands.is_gone.
	func is_gone() -> bool:
		return _of.is_gone()

	## Overrides WhereItStands.field_reaches.
	func field_reaches(point: Vector2) -> bool:
		return _of.field_reaches(point)
