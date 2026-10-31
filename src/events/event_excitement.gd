class_name EventExcitement
extends ExcitementSource
## **An event as a thing that charges the baby** (`ExcitementSource`), composed into its
## `EventInstance` as `excitement`: what is an event's own and nothing else — its field
## (`EventInstance.field_at()`, the row's falloff over its shape, damped by its phase), the walls it
## does not pass, the course its projection runs on, whether that course is lethal, and what its
## caret is keyed on.
##
## **Its caret measures her from the instance's own `player_at`**, which `EventManager` tells it
## once a physics tick for the chase and the leaving check and `ExcitementHalo` tells it again once
## a drawn frame (`set_player_at()`): one point, so the caret and the event's behaviours can never
## disagree about where she stands.

## Open ground, the walls a field from outside meets.
static var _NO_WALLS := WorldMap.open_ground()

var _event: EventInstance

## The rate the projection carries, worked out once before it samples
## (`EventInstance.caret_intensity_over_horizon()`).
var _live_intensity := 0.0

## The field's datum, read once before the projection samples, since nothing about it moves while it
## does: its row, where it stands, its shape and the axis its body lies along
## (`EventInstance.field_shape()`, `solid_axis()`), and whether a sample can be priced off them directly (`_direct`) — not for a
## flock, whose birds are each their own field, nor for a rate or a course `EventInstance.field_at()`
## would not take as given, which it then answers in full.
var _def: EventDef = null
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
func clock() -> float:
	return _event.clock()

## The halo's word on where she is reaches the instance too, where its behaviours and its look
## read it.
func set_player_at(at: Vector2, velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
		sensitivity: float = 1.0) -> void:
	super(at, velocity, decay_rate, sensitivity)
	_event.player_at = at

## The instance's own `player_at`, which its manager tells it on the physics tick as well as the
## halo once a drawn frame: the one point its behaviours, its look and its caret all read.
func _her_at() -> Vector2:
	return _event.player_at

func _contribution_stamp() -> float:
	return _event.age

## **A source beyond `EventDef.silent_beyond()` of the point answers zero before anything else is
## asked** — its intensity, its velocity, its shape — since its field is zero there by construction.
## Not for a flock or anything leaving: a flock's birds and a guard's band stand away from the node.
func _field(at: Vector2) -> float:
	if not _event.is_leaving and _event.birds().is_empty():
		var reach := _event.def.silent_beyond()
		if _event.global_position.distance_squared_to(at) > reach * reach:
			return 0.0
	return _event.field_at(at, -1.0, Vector2.INF)

## The map the event stands on, its buildings outdoors and the building's walls indoors — open
## ground for a row no wall stops (`EventDef.from_outside`), so the debug view's fields layer cuts
## its outline exactly where the meter does.
func wall_grid() -> WorldMap:
	return _NO_WALLS if _event.def.from_outside else _event.world_map()

## Nothing finished or leaving projects anything.
func _projects() -> bool:
	return not (_event.is_finished or _event.is_leaving)

## **The row's live course** (`EventInstance.caret_velocity()`), because the caret asks what this
## thing is on its way to doing rather than what a telegraph has it doing: a pursuer holding its
## stand-off is still, and about to lunge.
func _projection_velocity() -> Vector2:
	return _event.caret_velocity()

func _projection_reach() -> float:
	return _event.def.field_reach()

## **The row's live rate** (`EventInstance.caret_intensity_over_horizon()`): its telegraph's damping
## undone, its pulse at the horizon's mean. And the field's datum, so that each sample is the kernel
## `EventInstance.field_at()` ends in (`EventInstance.field_distance_from()`, then the row's
## `EventDef.emission_at_distance()`) without asking again, twenty times over, what does not change
## between them. **The same number `field_at()` answers**: the projection runs only on a source that
## projects (`_projects()`: neither finished nor leaving, which is all `field_at()` checks before
## the kernel), and `_direct` holds only where `field_at()` would take the rate and the course as
## given and reach the kernel.
func _begin_the_projection(velocity: Vector2) -> void:
	_live_intensity = _event.caret_intensity_over_horizon()
	_flock = not _event.birds().is_empty()
	_def = _event.def
	_from = _event.global_position
	_shape = _event.field_shape()
	_axis = _event.solid_axis()
	_direct = not _flock and _live_intensity >= 0.0 and velocity != Vector2.INF

## Every input the samples read, by value, mutable definition and shape fields included: age alone
## cannot cover a retirement, silence, external movement or changed player state. Empty for a flock,
## whose every bird has its own mutable geometry and is sampled afresh.
func _projection_key(player_position: Vector2, velocity: Vector2) -> Array:
	if _flock:
		return []
	var def := _def
	return [_from, player_position, player_velocity, velocity,
		_live_intensity, def.intensity, def.inner_radius, def.outer_radius,
		def.falloff_power, def.core_intensity, def.core_radius, _axis,
		def.shape.kind if def.shape else -1,
		def.shape.half_length if def.shape else 0.0,
		def.shape.half_extents if def.shape else Vector2.ZERO]

## The field at the translated point, at the live rate, its ellipse oriented by the source's own
## velocity rather than the pair's relative heading.
func _projected_field(sample: Vector2, velocity: Vector2) -> float:
	if not _direct:
		return _event.field_at(sample, _live_intensity, velocity)
	return _def.emission_at_distance(
			_event.field_distance_from(_from, _shape, _axis, sample, velocity), _live_intensity)

## Whether this event's own course puts her inside the radius that ends the day before the horizon
## is out, her position held fixed: `EventInstance.is_lethal_at()`'s straight-line reach,
## `def.lethal_reach()`, asked at every step of the projection.
##
## **Without the clear-line test**: a pursuer projected straight at her can read red while a
## building still stands between them; whether it should ask is open to overturn (the polite-rabbit
## record says why it does not). **Without the telegraph gate**: a `cyclist` ridden straight at her
## through its telegraph reads red, or the doubled caret would come only in its last fraction of a
## second. Waiting, finished or leaving refuses it: there is no course to be lethal on.
##
## **A car that drives asks its own strike along its own course** (`EventCarDriving.will_strike()`).
func will_be_lethal(player_position: Vector2) -> bool:
	if _event.car:
		return _event.car.will_strike(player_position)
	if _event.is_finished or _event.is_leaving or _event.is_waiting() \
			or not _event.def.hard_fail:
		return false
	var velocity := _event.caret_velocity()
	var reach := _event.def.lethal_reach()
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
## `player_at` is written by the manager on its physics tick and by the halo once a drawn frame,
## while the look asks on the event's own drawn frame. Keyed on age alone, the first to ask would
## fix the answer for the whole tick.
func _caret_key() -> Variant:
	return [_event.age, _event.player_at]

## A permanent feature of a fixed map never appears, so there is no moment to mark — the reason the
## fairness contract exempts an `AMBIENT` row — and nothing finished or leaving is marked.
func _may_mark() -> bool:
	return not (_event.is_finished or _event.is_leaving
			or _event.def.kind == GameEnums.EventKind.AMBIENT)
