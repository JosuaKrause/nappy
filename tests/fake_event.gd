class_name FakeEvent
extends EventInstance
## A stand-in for a live event, handed to what asks a live event questions (the looks, made
## round it by `look_for()`) in place of the real one, so the check sets up no row, no body, no
## behaviours and no street. It answers what a look asks of its event, and what the suite set is
## all it answers: each answer is a field here, the quiet answer (false, zero, empty, facing
## east, nothing to point at) until a check sets it, to what the real event answers in the same
## situation (read off the real event once, the way a mock is made: a dog walker set up on open
## ground answers a pace of 32 and a route of two points, a waiting robber answers that it
## waits). The warning board (the mark over her head) asks a few more of it. A question neither
## asks is not here.
##
## **Never put in a tree**, and no step of it is real: its stride and its phase are what the
## suite writes, and a tick of it only runs the counters (its age, its clock, the ground
## covered). A node: the suite frees it, and with it what it was handed to answer with.

## Which way it faces, what `facing_now()` answers.
var heading := Vector2.RIGHT
## Whether its spread runs down the screen (`runs_vertically()`).
var vertical := false
## Whether it is telegraphing (`is_telegraphing()`), and whether it holds still through it
## (`is_telegraphing_still()`).
var telegraphing := false
var telegraphing_still := false
## Whether it ends the day (`ends_the_day()`), how far its row is heard (`heard_within()`), how
## fast it travels (`travel_velocity()`) and whether its guard is gone for good
## (`has_lost_its_guard()`): what the warning board asks of an event beside its core and its
## telegraph.
var lethal := false
var heard := 0.0
var travelling_at := Vector2.ZERO
var guard_lost := false
## Whether it waits for her (`is_waiting()`), is standing for its notice
## (`is_standing_for_its_notice()`) and is on its way out (`is_on_its_way_out()`), gone
## (`is_gone()`) or only its barrier (`is_only_its_barrier()`).
var waiting := false
var standing_for_its_notice := false
var on_its_way_out := false
var gone := false
var only_its_barrier := false
## Where she is from it, what `sight_line_to_her()` answers: nothing, the zero vector, when none
## is set.
var line_to_her := Vector2.ZERO
## How long it has existed, in seconds (`age()`), its clock (`clock()`), and how far along its
## route it has walked (`path_travelled()`).
var lived := 0.0
var ticked := 0.0
var travelled := 0.0
## The stride (`gait_phase()`, `gait_is_moving()`) and its own offset into an idle animation
## (`idle_offset()`).
var stride := 0.0
var striding := false
var idle_start := 0.0
## Where its body stands, `body_position()`; the origin until set.
var body_at := Vector2.ZERO
## The route it walks (`walks()`) and how fast it comes along one (`approach_speed()`).
var route := PackedVector2Array()
var approaching_at := 0.0
## Whether it moves along a route of its own (`moves()`) and whether it drives (`drives()`).
var travels := false
var is_a_car := false
## What its row says of its field: its peak (`peak()`), how long one beat of its pulse lasts
## (`pulses_every()`), how long its telegraph lasts (`telegraphs_for()`), how far its core
## reaches (`core_within()`) and the rate it emits now (`current_intensity()`).
var field_peak := 0.0
var pulse_length := 0.0
var telegraph_length := 0.0
var core := 0.0
var emitting := 0.0
## Whether she is inside its core (`core_reaches()`): what the suite sets, and each point the
## question was asked about, in order. How far a core reaches is `core_within()`; the answer is not
## worked out from it here.
var core_reached := false
var core_asked: Array[Vector2] = []
## How far its body stops her (`solid_reach()`), zero for a row with no body.
var solid_extent := 0.0
## The outline its row's ground is (`ground_shape()`), null for a row with no picture, and the
## box its drawing fills (`drawn_box()`) with the one its row occupies (`footprint()`).
var shape: GroundShape = null
var box := Rect2()
var footprint_box := Rect2()
## The axis its solid body lies along (`solid_axis()`), the axis its spread runs along
## (`spread_axis()`), the point an offset along that spread is (`spread_at()`, the origin for an
## offset not set) and whether a stopped vehicle shows its side (`stands_side_on()`).
var solid_direction := Vector2.RIGHT
var spread_direction := Vector2.RIGHT
var spread_points: Dictionary[float, Vector2] = {}
var side_on := false
## How far a victim has been walked (`how_long_its_victim_has_walked()`) and whether it is
## taking one (`is_taking_a_victim()`).
var victim_walked := 0.0
var taking_a_victim := false
## Whether its guard has his hand raised (`is_its_guard_warning()`), is inside
## (`is_its_guard_inside()`), whether a conversation holds it (`is_chatting()`), it has stopped
## her (`has_stopped_her()`), it pursues (`pursues()`), its boom is up (`is_raised()`), it is a
## silenced mast (`is_silenced()`) and the pelican (`is_drawn_as_a_pelican()`).
var guard_warning := false
var guard_inside := false
var chatting := false
var stopped_her := false
var pursuing := false
var raised := false
var silenced := false
var pelican := false
## Where a protest points its placards (`where_its_placards_point()`); nothing to point at until
## set.
var placards_point := Vector2.INF
## Its birds (`birds()`), the world map (`world_map()`), the rim around its picture (`rim()`)
## and what its field is as a source (`source()`, its caret set on it): what the suite hands in
## is what it answers.
var flock: Array[EventFlock.Bird] = []
var map: WorldMap = null
var rim_halo: EntityHalo = null
var excitement: FakeExcitement = FakeExcitement.new(self)
## What the look asked to have put beside it (`add_beside_it()`, `add_slices_beside_it()`): the
## nodes in order, freed with the fake, since no world takes them.
var added: Array[Node] = []

## The row it is a live event of (`row()`), set by `look_for()`.
var of_row: EventDef = null

## A fake that answers what `instance` answers now, each question read off it once: the two steps of
## making a mock for a check that must see the real event's own situation (an arrival the game
## creates somewhere, a trap in its place) and asks what a look made round it shows, with no live
## event kept for the look to read. **What the copy leaves out**: a spread's points
## (`spread_at()`, asked by offset: a row with a spread answers the origin), the barrier post and
## the stance `look_for()` never hands a look, and the view sector a look carries from frame to
## frame (so a posted guard's heading is not the game's). **A question the looks start asking
## must be copied here**, or a suite that measures an arrival under-measures it:
## `tests/test_fake_event.gd` fails while an answer the fake gives is neither copied nor named as
## left out.
static func answering_as(instance: EventInstance) -> FakeEvent:
	var fake := FakeEvent.new()
	fake.position = instance.global_position
	fake.of_row = instance.row()
	fake.heading = instance.facing_now()
	fake.vertical = instance.runs_vertically()
	fake.telegraphing = instance.is_telegraphing()
	fake.telegraphing_still = instance.is_telegraphing_still()
	fake.waiting = instance.is_waiting()
	fake.standing_for_its_notice = instance.is_standing_for_its_notice()
	fake.on_its_way_out = instance.is_on_its_way_out()
	fake.gone = instance.is_gone()
	fake.only_its_barrier = instance.is_only_its_barrier()
	fake.line_to_her = instance.sight_line_to_her()
	fake.lived = instance.age()
	fake.ticked = instance.clock()
	fake.travelled = instance.path_travelled()
	fake.stride = instance.gait_phase()
	fake.striding = instance.gait_is_moving()
	fake.idle_start = instance.idle_offset()
	fake.body_at = instance.body_position()
	fake.route = instance.walks()
	fake.approaching_at = instance.approach_speed()
	fake.travels = instance.moves()
	fake.is_a_car = instance.drives()
	fake.field_peak = instance.peak()
	fake.pulse_length = instance.pulses_every()
	fake.telegraph_length = instance.telegraphs_for()
	fake.core = instance.core_within()
	fake.lethal = instance.ends_the_day()
	fake.heard = instance.heard_within()
	fake.travelling_at = instance.travel_velocity()
	fake.guard_lost = instance.has_lost_its_guard()
	fake.solid_extent = instance.solid_reach()
	fake.emitting = instance.current_intensity()
	fake.shape = instance.ground_shape()
	fake.box = instance.drawn_box()
	fake.footprint_box = instance.footprint()
	fake.solid_direction = instance.solid_axis()
	fake.spread_direction = instance.spread_axis()
	fake.side_on = instance.stands_side_on()
	fake.victim_walked = instance.how_long_its_victim_has_walked()
	fake.taking_a_victim = instance.is_taking_a_victim()
	fake.guard_warning = instance.is_its_guard_warning()
	fake.guard_inside = instance.is_its_guard_inside()
	fake.chatting = instance.is_chatting()
	fake.stopped_her = instance.has_stopped_her()
	fake.pursuing = instance.pursues()
	fake.raised = instance.is_raised()
	fake.silenced = instance.is_silenced()
	fake.pelican = instance.is_drawn_as_a_pelican()
	fake.placards_point = instance.where_its_placards_point()
	fake.flock = instance.birds()
	fake.map = instance.world_map()
	fake.rim_halo = instance.rim()
	fake.excitement.caret = instance.source().caret_strength()
	return fake

## One tick of it: the clock and the age run on by `delta` and `moved` pixels of ground are
## covered. The stride is not turned by it: a check that walks the fake sets `stride` and
## `striding` to what a real event answers after that ground.
func tick(delta: float, moved: float) -> void:
	lived += delta
	ticked += delta
	travelled += moved

## A look of `row` made round this fake the way `EventInstance.setup()` makes the real event's
## (`EventLooks.for_row()`), drawing through `drawer`, which a test that reads pictures hands
## in, and asking `drawn_view` which part of the world is on the screen, which a test of the look's
## gate over what is off screen hands in (one that shows everything otherwise). It is facing the
## way this fake faces now.
func look_for(row: EventDef, drawer: EventDrawer = null, drawn_view: DrawnView = null) -> EventLook:
	var made := EventLooks.for_row(self, row.look(), row.body(), row.takes_a_victim_by(),
			drawer if drawer != null else EventDrawer.new(null), false,
			drawn_view if drawn_view != null else DrawnView.new(), null)
	made.face(heading)
	of_row = row
	return made

## Frees what the look asked to have put beside it, with the fake.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for node in added:
			if is_instance_valid(node) and node.get_parent() == null:
				node.free()
		added.clear()

## Overrides EventInstance.row.
func row() -> EventDef:
	return of_row

## Overrides EventInstance.facing_now.
func facing_now() -> Vector2:
	return heading

## Overrides EventInstance.runs_vertically.
func runs_vertically() -> bool:
	return vertical

## Overrides EventInstance.is_telegraphing.
func is_telegraphing() -> bool:
	return telegraphing

## Overrides EventInstance.is_telegraphing_still.
func is_telegraphing_still() -> bool:
	return telegraphing_still

## Overrides EventInstance.is_waiting.
func is_waiting() -> bool:
	return waiting

## Overrides EventInstance.is_standing_for_its_notice.
func is_standing_for_its_notice() -> bool:
	return standing_for_its_notice

## Overrides EventInstance.is_on_its_way_out.
func is_on_its_way_out() -> bool:
	return on_its_way_out

## Overrides EventInstance.is_gone.
func is_gone() -> bool:
	return gone

## Overrides EventInstance.is_only_its_barrier.
func is_only_its_barrier() -> bool:
	return only_its_barrier

## Overrides EventInstance.sight_line_to_her.
func sight_line_to_her() -> Vector2:
	return line_to_her

## Overrides EventInstance.age.
func age() -> float:
	return lived

## Overrides EventInstance.clock.
func clock() -> float:
	return ticked

## Overrides EventInstance.path_travelled.
func path_travelled() -> float:
	return travelled

## Overrides EventInstance.gait_phase.
func gait_phase() -> float:
	return stride

## Overrides EventInstance.gait_is_moving.
func gait_is_moving() -> bool:
	return striding

## Overrides EventInstance.idle_offset.
func idle_offset() -> float:
	return idle_start

## Overrides EventInstance.body_position.
func body_position() -> Vector2:
	return body_at

## Overrides EventInstance.walks.
func walks() -> PackedVector2Array:
	return route

## Overrides EventInstance.approach_speed.
func approach_speed() -> float:
	return approaching_at

## Overrides EventInstance.moves.
func moves() -> bool:
	return travels

## Overrides EventInstance.drives.
func drives() -> bool:
	return is_a_car

## Overrides EventInstance.peak.
func peak() -> float:
	return field_peak

## Overrides EventInstance.pulses_every.
func pulses_every() -> float:
	return pulse_length

## Overrides EventInstance.telegraphs_for.
func telegraphs_for() -> float:
	return telegraph_length

## Overrides EventInstance.core_within.
func core_within() -> float:
	return core

## Overrides EventInstance.ends_the_day.
func ends_the_day() -> bool:
	return lethal

## Overrides EventInstance.heard_within.
func heard_within() -> float:
	return heard

## Overrides EventInstance.travel_velocity.
func travel_velocity() -> Vector2:
	return travelling_at

## Overrides EventInstance.has_lost_its_guard.
func has_lost_its_guard() -> bool:
	return guard_lost

## Notes the point asked about and answers `core_reached`.
##
## Overrides EventInstance.core_reaches.
func core_reaches(point: Vector2) -> bool:
	core_asked.append(point)
	return core_reached

## Overrides EventInstance.solid_reach.
func solid_reach() -> float:
	return solid_extent

## Overrides EventInstance.current_intensity.
func current_intensity(_pulse_multiplier_override := -1.0) -> float:
	return emitting

## Overrides EventInstance.ground_shape.
func ground_shape() -> GroundShape:
	return shape

## Overrides EventInstance.drawn_box.
func drawn_box() -> Rect2:
	return box

## Overrides EventInstance.footprint.
func footprint() -> Rect2:
	return footprint_box

## Overrides EventInstance.solid_axis.
func solid_axis() -> Vector2:
	return solid_direction

## Overrides EventInstance.spread_axis.
func spread_axis() -> Vector2:
	return spread_direction

## Overrides EventInstance.spread_at.
func spread_at(offset: float) -> Vector2:
	return spread_points.get(offset, Vector2.ZERO)

## Overrides EventInstance.stands_side_on.
func stands_side_on() -> bool:
	return side_on

## Overrides EventInstance.how_long_its_victim_has_walked.
func how_long_its_victim_has_walked() -> float:
	return victim_walked

## Overrides EventInstance.is_taking_a_victim.
func is_taking_a_victim() -> bool:
	return taking_a_victim

## Overrides EventInstance.is_its_guard_warning.
func is_its_guard_warning() -> bool:
	return guard_warning

## Overrides EventInstance.is_its_guard_inside.
func is_its_guard_inside() -> bool:
	return guard_inside

## Overrides EventInstance.is_chatting.
func is_chatting() -> bool:
	return chatting

## Overrides EventInstance.has_stopped_her.
func has_stopped_her() -> bool:
	return stopped_her

## Overrides EventInstance.pursues.
func pursues() -> bool:
	return pursuing

## Overrides EventInstance.is_raised.
func is_raised() -> bool:
	return raised

## Overrides EventInstance.is_silenced.
func is_silenced() -> bool:
	return silenced

## Overrides EventInstance.is_drawn_as_a_pelican.
func is_drawn_as_a_pelican() -> bool:
	return pelican

## Overrides EventInstance.where_its_placards_point.
func where_its_placards_point() -> Vector2:
	return placards_point

## Overrides EventInstance.birds.
func birds() -> Array[EventFlock.Bird]:
	return flock

## Overrides EventInstance.world_map.
func world_map() -> WorldMap:
	return map

## Overrides EventInstance.rim.
func rim() -> EntityHalo:
	return rim_halo

## Overrides EventInstance.source.
func source() -> EventExcitement:
	return excitement

## Notes the node and frees it with the fake, as no world takes it.
##
## Overrides EventInstance.add_beside_it.
func add_beside_it(node: Node2D) -> void:
	added.append(node)

## Notes the nodes and frees them with the fake, as no world takes them.
##
## Overrides EventInstance.add_slices_beside_it.
func add_slices_beside_it(slices: Array[Node2D], _feet: PackedVector2Array) -> void:
	for slice in slices:
		added.append(slice)
