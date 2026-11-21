class_name FieldSpec
extends Resource
## **The noise a row adds: the field of excitement the baby is charged for, as one value.** Its
## peak rate at the centre, the two radii it falls away between, the louder core a few rows carry,
## the curve of the drop, how it beats or swells, whether it reaches through walls, whether several
## of it count as one barrier, and whether it is priced from a point. A row holds one
## (`EventDef.field()`); nothing changes it once it exists (a refinement returns a new value), so a
## row's copies share it by reference and a cache over it (the distance beyond which it is silent)
## is worked out once, when the value is made.
##
## **The maths of the field is here and nowhere else**: `emission_at_distance()` is the price of
## every point of ground in the game (the cost table's integral, the placement rules, an event's
## `ExcitementSource.contribution_at()`, which is what the baby is actually charged). What spans
## parts stays the row's: where the datum lies (the body's shape unless the field is priced from its
## centre), a flock's sum over its birds, the price of walking through it.

## Peak excitement per second at the centre.
var _peak := 0.0
## Where the field starts to fall, in px: the core of the field.
var _inner := 0.0
## Where it has fallen to nothing, in px.
var _outer := 0.0

## **A louder inner part of the same field**, for a row that has to be one thing to walk past and
## another to stand a street away from: the rate out to `_inner`, which has fallen to nothing at
## `_core_reach`, on the same curve the field uses. Both zero means no core, which is every row but
## the leaf blower. `emission_at_distance()` answers **the larger of the two**, so a core adds
## rather than replaces: past `_core_reach` the row is its plain field. **A flock has no core**, and
## `EventDef.validate()` refuses one: a flock's field is already a sum over bodies rather than one
## disc.
var _core_rate := 0.0
var _core_reach := 0.0

## **The exponent on the drop between the two radii**: `peak * (1 - t ** falloff)`. 2.0 is the
## curve the whole catalogue is measured at (three quarters of the peak still there at the midpoint
## of the band); a power under 1 drops fast and tails long, over 2 holds near full and then falls
## off a cliff. **Nothing sets it**; a row that does owes the same fairness contract, which is
## stated over distance and does not care.
var _falloff := 2.0

## Seconds per cycle of its beat, for a row that pulses rather than holds. 0 is constant.
var _pulse := 0.0

## The multiplier its peak reaches at the end of the row's duration. 1.0 holds steady; above 1.0
## swells (a protest gathering), below 1.0 fades.
var _swell := 1.0

## **Something outside the walls of the world she is in**, which reaches her through them: what
## lands on her from it ignores every wall between, where every other field stops at the middle of
## one (`WorldMap.wall_between()`). The explosion outside the building.
var _passes_walls := false

## Whether several of it count as the strongest one only: the pieces of a street being held (the
## region boundary's own structures), whose fields do not add up. **It is a flag rather than a list
## of ids**, so the rule is a property of the row and a renamed or added row cannot silently fall
## out of a table elsewhere. `EventSources.sources_at()` is the one place that takes the maximum, and
## the halo, the caret and the meter all read that same answer (`ExcitementSource.is_outranked()`).
var _one_barrier := false

## **Its field is priced from its centre, a point, rather than from its body.** The body is the
## datum by default (`GroundShape.field_distance()`: a standing capsule's field is a stadium about
## its spine). Set on `fire_truck` alone, whose field `docs/COSTS.md` prices as a point's: the body
## it is given to be solid is not a reason for the street beside a parked engine to cost more, and
## the 340px the fire's siting check closes about its kerb (`WalkSiting`) is then the whole of its
## field.
var _from_its_centre := false

## A straight-line distance from the centre beyond which the field is exactly zero (not counting the
## body's own reach), worked out when the value is made.
var _silent := 0.0

# ------------------------------------------------------------ making one ---

## A field peaking at `peak` per second at its centre, holding out to `inner` and fallen to
## nothing at `outer`, on the catalogue's own curve.
static func of(peak: float, inner: float, outer: float) -> FieldSpec:
	var spec := FieldSpec.new()
	spec._peak = peak
	spec._inner = inner
	spec._outer = outer
	return spec._made()

## The same field with a louder core: `rate` per second out to its inner radius, fallen to nothing
## at `reach`.
func with_a_core(rate: float, reach: float) -> FieldSpec:
	var spec := _copy()
	spec._core_rate = rate
	spec._core_reach = reach
	return spec._made()

## The same field with `power` as the exponent on its drop.
func falling_off(power: float) -> FieldSpec:
	var spec := _copy()
	spec._falloff = power
	return spec._made()

## The same field beating once every `seconds`.
func pulsing_every(seconds: float) -> FieldSpec:
	var spec := _copy()
	spec._pulse = seconds
	return spec._made()

## The same field whose peak reaches `multiplier` times itself by the end of the row's duration.
func swelling_by(multiplier: float) -> FieldSpec:
	var spec := _copy()
	spec._swell = multiplier
	return spec._made()

## The same field reaching her through every wall.
func through_walls() -> FieldSpec:
	var spec := _copy()
	spec._passes_walls = true
	return spec._made()

## The same field counted as one barrier with the others of its kind.
func as_one_barrier() -> FieldSpec:
	var spec := _copy()
	spec._one_barrier = true
	return spec._made()

## The same field priced from its centre rather than its body.
func from_its_centre() -> FieldSpec:
	var spec := _copy()
	spec._from_its_centre = true
	return spec._made()

## The same field at another peak rate: the copy the resistance's heat makes of a pressing row.
func at_peak(rate: float) -> FieldSpec:
	var spec := _copy()
	spec._peak = rate
	return spec._made()

## The same field reaching out to `outer`: the copy the resistance's heat makes of a hunting row,
## widened to where it notices her.
func reaching(outer: float) -> FieldSpec:
	var spec := _copy()
	spec._outer = outer
	return spec._made()

# -------------------------------------------------------------- asking one ---

## Whether it is a field at all (a peak above zero): a silent body bills nothing round it, so
## standing clear of it is standing clear of its body.
func has_a_field() -> bool:
	return _peak > 0.0

## The peak rate at its centre, before a swell, a pulse or a phase moves it, or 0 for a row with no
## field: what the share it emits now is measured against.
func peak() -> float:
	return _peak

## How far from its centre its core reaches (its inner radius): the span a dog walker's dog is led
## ahead at is a share of it.
func core_within() -> float:
	return _inner

## How far from its centre it reaches her at all (its outer radius): where the badge measures the
## gap to.
func heard_within() -> float:
	return _outer

## The rate of the louder core, or 0 for a field with none.
func core_rate() -> float:
	return _core_rate

## Where the louder core has fallen to nothing, or 0 for a field with none.
func core_reach() -> float:
	return _core_reach

## The exponent on the drop between its two radii.
func falloff() -> float:
	return _falloff

## How many seconds one beat of its pulse lasts, or 0 for a field that does not pulse.
func pulses_every() -> float:
	return _pulse

## Whether what it lands on her ignores every wall between, where every other field stops at one.
func passes_walls() -> bool:
	return _passes_walls

## Whether several of it count as the strongest one only.
func counts_as_one_barrier() -> bool:
	return _one_barrier

## Whether it is priced from its centre rather than from the body it stands in.
func is_priced_from_its_centre() -> bool:
	return _from_its_centre

## **The peak of the field at its centre**, before a phase damps it: its peak, swelled toward its
## multiplier over `lasts` (the row's duration) and beating with its pulse. `into_its_burst` is how
## long its burst has been running, which the swell is measured on; `age` is its own clock, which
## the pulse beats on, since a pulse is the thing's own rhythm whether or not anybody has walked up
## to it.
##
## The pulse's reading is `0.25 + 0.75 × (0.5 − 0.5·cos(phase))`, so a pulsing field is never
## entirely silent between beats; `beat` (`< 0.0` means "not given") replaces that reading with a
## multiplier the caller worked out, the caret's mean over its horizon
## (`EventInstance.caret_intensity_over_horizon()`). A field that neither swells nor pulses answers
## its peak.
func peak_through(age: float, into_its_burst: float, lasts: float, beat := -1.0) -> float:
	var value := _peak
	if not is_equal_approx(_swell, 1.0) and lasts > 0.0:
		var through := clampf(into_its_burst / lasts, 0.0, 1.0)
		value *= lerpf(1.0, _swell, through)
	if _pulse > 0.0:
		if beat >= 0.0:
			value *= beat
		else:
			var phase := TAU * age / _pulse
			value *= 0.25 + 0.75 * (0.5 - 0.5 * cos(phase))
	return value

## What the field gives at a distance from its centre: the field, and the core over the top of it
## where there is one. **Every price in the game goes through here.**
##
## `at_intensity` is the peak the *caller* is carrying rather than the catalogued one (an
## instance's `current_intensity()`, after the telegraph damping and the pulse envelope). **The core
## is scaled by the same fraction**, so a two-part field damps as one thing. A field with no core is
## `Field.falloff` on its own curve, bit for bit: the fraction is applied to the peak handed in
## rather than divided back out of it. `tests/test_events.gd` walks the whole catalogue at 16px
## steps and holds that.
func emission_at_distance(at_distance: float, at_intensity: float = -1.0) -> float:
	var peak := _peak if at_intensity < 0.0 else at_intensity
	var field := Field.falloff(at_distance, peak, _inner, _outer, _falloff)
	if _core_rate <= 0.0:
		return field
	var core := _core_rate
	if at_intensity >= 0.0 and _peak > 0.0:
		core *= at_intensity / _peak
	return maxf(field, Field.falloff(at_distance, core, _inner, _core_reach, _falloff))

## What one of a flock's birds emits at `at_distance` from the bird, carrying `share` of the peak
## over a field that ends at `outer`: its own core edge and its own drop-off. Each bird is its own
## point, so a flock is priced as the sum of these, by the row and by its live event alike.
func bird_emission_at(at_distance: float, share: float, outer: float) -> float:
	return Field.falloff(at_distance, share, _inner, outer, _falloff)

## How far from the centre the field still emits more than `rate`, over both parts of it: the field
## itself, and the core where it has one (a cored row's loud part can outlive its quiet one).
func reach_above(rate: float) -> float:
	return maxf(_band_crossing(_peak, _inner, _outer, rate, _falloff),
			_band_crossing(_core_rate, _inner, _core_reach, rate, _falloff))

## A straight-line distance from the centre beyond which the field is exactly zero, whatever its
## rate, speed, heading or the way its body lies, not counting that body's own reach, so an event's
## source (`EventExcitement._field()`) can answer zero for a far source without working the field
## out.
##
## **Why it is safe.** `emission_at_distance()` is zero once the field distance it is handed is past
## every radius it reads: the two radii and, with a core, the core's reach. The field distance is
## never shorter than the straight distance less the body's own `reach()`, shrunk by at most
## `1 − Tuning.FIELD_ECCENTRICITY_MAX` for a moving source's forward stretch
## (`GroundShape.eccentric_distance()`). The extra pixel swallows the last bit a rotation can round.
##
## **Not the row's `field_reach()`**, which is the field's own extent for the planners; this is the
## looser figure nothing can be past and still charge her.
func silent_beyond() -> float:
	return _silent

# ---------------------------------------------------------------- inside ---

## Where one falloff band crosses `rate`, or zero if it is never above it: `Field.falloff`'s
## `1 − t^power` inverted for the `t` at which it equals `rate`, with the field's own power.
static func _band_crossing(rate_at_centre: float, inner: float, outer: float, rate: float,
		power: float) -> float:
	if rate_at_centre <= rate or outer <= inner:
		return 0.0
	var left := 1.0 - rate / rate_at_centre
	# `sqrt` at the default rather than `pow(x, 0.5)`, as `Field.falloff` writes its own default
	# out: the two may differ in the last bit, and every catalogued radius was measured here.
	var t := sqrt(left) if is_equal_approx(power, 2.0) else pow(left, 1.0 / power)
	return inner + t * (outer - inner)

## This value with what is worked out from its settings worked out.
func _made() -> FieldSpec:
	var level := maxf(_inner, _outer)
	if _core_rate > 0.0:
		level = maxf(level, _core_reach)
	_silent = (level + 1.0) / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
	return self

func _copy() -> FieldSpec:
	var spec := FieldSpec.new()
	spec._peak = _peak
	spec._inner = _inner
	spec._outer = _outer
	spec._core_rate = _core_rate
	spec._core_reach = _core_reach
	spec._falloff = _falloff
	spec._pulse = _pulse
	spec._swell = _swell
	spec._passes_walls = _passes_walls
	spec._one_barrier = _one_barrier
	spec._from_its_centre = _from_its_centre
	return spec
