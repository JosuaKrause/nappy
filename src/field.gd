class_name Field
extends RefCounted
## **The arithmetic of a field**: what an emitter costs at a distance (`falloff()`), and how a moving
## one's reach stretches ahead of it (`eccentricity()`, `scale()`). Static and stateless, pure functions of
## their arguments and the shared balance numbers in `Tuning`, so the shape and the callers that draw it
## (`GroundShape`), price it (`EventDef`, `EventInstance`, `CrowdExcitement`) and check it (the tests) cannot
## disagree.

const FIELD_ECCENTRICITY_SPEED := 500.0

## Eccentricity of a moving emitter's field kernel, from its own speed: zero at a standstill, the plain disc
## every field always was, rising with speed and capped at `Tuning.FIELD_ECCENTRICITY_MAX` so nothing ever
## flattens to a line (the numbers and why they are what they are: `FIELD_ECCENTRICITY_SPEED`).
static func eccentricity(speed: float) -> float:
	return minf(Tuning.FIELD_ECCENTRICITY_MAX, speed / FIELD_ECCENTRICITY_SPEED)

## The moving field's growth over its resting disc: `L(e) = R / (1 − e)`, so a field at the
## catalogued radius `R` reaches `R · Field.scale(e)` dead ahead once it moves — the width the
## player asked to keep. *(2026-09-10, overturning M61's field record: "the stretching should
## retain the area so an unstretched car field should be the same width with shorter height" …
## "if anything the moving size should be bigger than the rest size since moving causes more
## excitement.")* `Field.scale(0)` is 1.0, the plain disc M61 always gave a standing emitter.
##
## The one place this conic's own scale is computed — `GroundShape.eccentric_distance()` and
## `GroundShape._eccentric_field_outline()` both go through it, so a future change to the growth
## curve cannot update one and miss the other.
static func scale(e: float) -> float:
	return 1.0 / (1.0 - e)

## Excitement contribution of a source of `intensity` at distance `d` — `d` is
## `GroundShape.field_distance()`/`eccentric_distance()` now, distance to a body's spine or to a
## moving emitter's own elliptical kernel rather than always the plain distance to a centre, but
## the arithmetic below is unchanged: whatever shape a field's `d` came from, `inner_radius` and
## `outer_radius` still mean *that* distance's own near and far edge.
##
## **The shape has a shoulder on it**, because the meter has to go substantially up from some way
## off rather than waiting for contact.
##
## `1 − t²`: full strength at the inner edge, three quarters of it at the midpoint, and zero only at
## the outer edge, where the contract says it must be. **The whole catalogue gets its teeth from the
## shape rather than from its radii** — thirty rows of hand-widened radii would be thirty chances to
## break the fairness contract.
##
## **The square is the one curve**: every row, the crowd and the debug layers drop by `t²`, and
## every number in `docs/EVENTS.md` was measured against it.
##
## **`(1−t)²` is the shape that looks equally reasonable and inverts the game.** It puts a quarter of
## the intensity at the midpoint of the band and six percent three quarters of the way out, so a café
## at 12/s sits under the 6.0/s walking decay across the whole outer 70% of its own field — and a
## `near` entry written at an event's outer radius reads `events 0.0`. An event you are not charged
## for until you touch it is not a thing to route around, it is a thing to bump into.
##
## **The contract is untouched and this is why.** `required_telegraph_time` is stated over
## *distance* — how far she has to walk to be outside the radius — and neither radius moved. What
## changed is what she pays while she is inside one, which the contract has never had an opinion
## about. `tests/test_events_catalogue.gd` re-checks the whole catalogue either way.
##
## See docs/MECHANICS.md.
static func falloff(d: float, intensity: float, inner_radius: float, outer_radius: float) -> float:
	if d <= inner_radius:
		return intensity
	if d >= outer_radius:
		return 0.0
	var t := (d - inner_radius) / (outer_radius - inner_radius)
	return intensity * (1.0 - t * t)
