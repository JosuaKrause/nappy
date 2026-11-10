class_name EventExcitement
extends ExcitementSource
## **An event as a thing that charges the baby** (`ExcitementSource`), composed into its
## `EventInstance` as `excitement`: what is an event's own and nothing else — its field
## (`EventInstance.field_at()`, the row's falloff over its shape, damped by its phase), the walls it
## does not pass, the course its projection runs on, whether that course is lethal, and what its
## caret is keyed on.
##
## **Handed its row and where she is as its instance is set up** (`use_row_and_where_she_is()`),
## since neither changes under it: what its field is (how far it is silent beyond, whether it
## passes walls, how far it reaches, whether it ends the day and within what, whether it is a car
## or ambient) it asks the row, and its instance only what changes — its phase, its age, where it
## stands, its present rate and course, its birds and its car's strike.
##
## **Its caret measures her from where its instance hears she is** (`WhereSheIs.at()`), the handle
## `EventManager` tells once a physics tick for the chase and the leaving check and `ExcitementHalo`
## tells again once a drawn frame (`set_player_at()`): one point, so the caret and the event's
## behaviours can never disagree about where she stands.

## Open ground, the walls a field from outside meets.
static var _NO_WALLS := WorldMap.open_ground()

var _event: EventInstance
## The row its instance is a live one of, handed in as the instance is set up
## (`use_row_and_where_she_is()`); none until then.
var _row: EventDef = null
## Where she is, as its instance hears it (`WhereSheIs`), handed in with the row; nowhere until
## then.
var _where := WhereSheIs.nowhere()

## The rate the projection carries, worked out once before it samples
## (`EventInstance.caret_intensity_over_horizon()`).
var _live_intensity := 0.0

## The field's datum, read once before the projection samples, since nothing about it moves while it
## does: where it stands, the shape its row prices it from (`EventDef.datum()`) and the axis its
## body lies along (`EventInstance.solid_axis()`), and whether a sample can be priced off them
## directly (`_direct`) — not for a flock, whose birds are each their own field, nor for a rate or
## a course `EventInstance.field_at()` would not take as given, which it then answers in full.
var _from := Vector2.ZERO
var _shape: GroundShape = null
var _axis := Vector2.ZERO
var _flock := false
var _direct := false

func _init(event: EventInstance) -> void:
	super(event)
	_event = event
	# The field changes only with the event's own age, which moves only in its own step; a change
	# made from outside that step (a phase changed by its manager, a mast silenced) invalidates it.
	_caches_contribution = true

## The event's own clock, which stops once it is finished, so a spent instance's window simply
## stops moving rather than draining after nothing more can land.
##
## Overrides ExcitementSource.clock.
func clock() -> float:
	return _event.clock()

## Hands it its instance's row and where she is as its instance hears it (`EventInstance.setup()`),
## so the caret, the instance's behaviours and its look ask one object.
func use_row_and_where_she_is(row: EventDef, where: WhereSheIs) -> void:
	_row = row
	_where = where

## The halo's word on where she is reaches its instance's handle too (`WhereSheIs.see_her_at()`),
## where its behaviours and its look ask it, until the manager's next word; no other event hears it.
##
## Overrides ExcitementSource.set_player_at.
func set_player_at(at: Vector2, velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
		sensitivity: float = 1.0) -> void:
	super(at, velocity, decay_rate, sensitivity)
	_where.see_her_at(at)

## Where its instance hears she is, which its manager tells on the physics tick as well as the halo
## once a drawn frame: the one point its behaviours, its look and its caret all read.
##
## Overrides ExcitementSource._her_at.
func _her_at() -> Vector2:
	return _where.at()

## Overrides ExcitementSource._contribution_stamp.
func _contribution_stamp() -> float:
	return _event.age

## **A source beyond `EventDef.silent_beyond()` of the point answers zero before anything else is
## asked** — its intensity, its velocity, its shape — since its field is zero there by construction.
## Not for a flock or anything leaving: a flock's birds and a guard's band stand away from the node.
##
## Overrides ExcitementSource._field.
func _field(at: Vector2) -> float:
	if not _event.is_on_its_way_out() and _event.birds().is_empty():
		var reach := _row.silent_beyond()
		if _event.global_position.distance_squared_to(at) > reach * reach:
			return 0.0
	return _event.field_at(at, -1.0, Vector2.INF)

## The map the event stands on, its buildings outdoors and the building's walls indoors — open
## ground for a row no wall stops (`EventDef.passes_walls()`), so the debug view's fields layer cuts
## its outline exactly where the meter does.
##
## Overrides ExcitementSource.wall_grid.
func wall_grid() -> WorldMap:
	return _NO_WALLS if _row.passes_walls() else _event.world_map()

## Nothing finished or leaving projects anything.
##
## Overrides ExcitementSource._projects.
func _projects() -> bool:
	return not (_event.is_gone() or _event.is_on_its_way_out())

## **The row's live course** (`EventInstance.caret_velocity()`), because the caret asks what this
## thing is on its way to doing rather than what a telegraph has it doing: a pursuer holding its
## stand-off is still, and about to lunge.
##
## Overrides ExcitementSource._projection_velocity.
func _projection_velocity() -> Vector2:
	return _event.caret_velocity()

## Overrides ExcitementSource._projection_reach.
func _projection_reach() -> float:
	return _row.field_reach()

## **The row's live rate** (`EventInstance.caret_intensity_over_horizon()`): its telegraph's damping
## undone, its pulse at the horizon's mean. And the field's datum, so that each sample is the kernel
## `EventInstance.field_at()` ends in (`EventInstance.field_distance_from()`, then the row's
## `EventDef.emission_at_distance()`) without asking again, twenty times over, what does not change
## between them. **The same number `field_at()` answers**: the projection runs only on a source that
## projects (`_projects()`: neither finished nor leaving, which is all `field_at()` checks before
## the kernel), and `_direct` holds only where `field_at()` would take the rate and the course as
## given and reach the kernel.
##
## Overrides ExcitementSource._begin_the_projection.
func _begin_the_projection(velocity: Vector2) -> void:
	_live_intensity = _event.caret_intensity_over_horizon()
	_flock = not _event.birds().is_empty()
	_from = _event.global_position
	_shape = _row.datum()
	_axis = _event.solid_axis()
	_direct = not _flock and _live_intensity >= 0.0 and velocity != Vector2.INF

## Every input the samples read, by value, mutable definition and shape fields included: age alone
## cannot cover a retirement, silence, external movement or changed player state, and a rig may
## change its row's settings in place, so they are copied from the row rather than asked of it.
## Empty for a flock, whose every bird has its own mutable geometry and is sampled afresh.
##
## Overrides ExcitementSource._projection_key.
func _projection_key(player_position: Vector2, velocity: Vector2) -> Array:
	if _flock:
		return []
	var row := _row
	return [_from, player_position, player_velocity, velocity,
		_live_intensity, row.intensity, row.inner_radius, row.outer_radius,
		row.falloff_power, row.core_intensity, row.core_radius, _axis,
		row.shape.kind if row.shape else -1,
		row.shape.half_length if row.shape else 0.0,
		row.shape.half_extents if row.shape else Vector2.ZERO]

## The field at the translated point, at the live rate, its ellipse oriented by the source's own
## velocity rather than the pair's relative heading.
##
## Overrides ExcitementSource._projected_field.
func _projected_field(sample: Vector2, velocity: Vector2) -> float:
	if not _direct:
		return _event.field_at(sample, _live_intensity, velocity)
	return _row.emission_at_distance(
			_event.field_distance_from(_from, _shape, _axis, sample, velocity), _live_intensity)

## Whether this event's own course puts her inside the radius that ends the day before the horizon
## is out, her position held fixed: `EventInstance.is_lethal_at()`'s straight-line reach,
## `EventDef.lethal_reach()`, asked at every step of the projection.
##
## **Without the clear-line test**: a pursuer projected straight at her can read red while a
## building still stands between them; whether it should ask is open to overturn (the polite-rabbit
## record says why it does not). **Without the telegraph gate**: a `cyclist` ridden straight at her
## through its telegraph reads red, or the doubled caret would come only in its last fraction of a
## second. Waiting, finished or leaving refuses it: there is no course to be lethal on.
##
## **A car that drives asks its own strike along its own course** (`EventCarDriving.will_strike()`).
##
## Overrides ExcitementSource.will_be_lethal.
func will_be_lethal(player_position: Vector2) -> bool:
	if _row.drives():
		return _event.will_strike(player_position)
	if _event.is_gone() or _event.is_on_its_way_out() or _event.is_waiting() \
			or not _row.ends_the_day():
		return false
	var velocity := _event.caret_velocity()
	var reach := _row.lethal_reach()
	var at := _event.global_position
	if velocity.is_zero_approx():
		return at.distance_to(player_position) <= reach
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	for i in steps + 1:
		var future_at := at + velocity * (float(i) * dt)
		if future_at.distance_to(player_position) <= reach:
			return true
	return false

## **Keyed on where she is as well as on the age, and the pair is load-bearing.** The answer is a
## projection of this event's course against her position, and the two do not move together:
## where she is is told by the manager on its physics tick and by the halo once a drawn frame,
## while the look asks on the event's own drawn frame. Keyed on age alone, the first to ask would
## fix the answer for the whole tick.
##
## Overrides ExcitementSource._caret_key.
func _caret_key() -> Variant:
	return [_event.age, _where.at()]

## A permanent feature of a fixed map never appears, so there is no moment to mark — the reason the
## fairness contract exempts an `AMBIENT` row — and nothing finished or leaving is marked.
##
## Overrides ExcitementSource._may_mark.
func _may_mark() -> bool:
	return not (_event.is_gone() or _event.is_on_its_way_out() or _row.is_ambient())
