class_name WheelBob
extends RefCounted
## The rise and fall a vehicle's body rides while its wheels stay on the ground, shared by the
## crowd's cars and the catalogue's moving vehicles so the two roll the same way.
##
## *(2026-09-11, the player: "cars could bop up and down while the wheels stay in the same
## place".)* Each vehicle view is drawn as a body and a separate wheels picture on one canvas and
## one anchor; the owner lifts the body by `lift()` and draws the wheels where they were. **Driven
## by ground covered, not by time**, the same rule the walkers' stride and the events' own bob
## follow: the phase is the distance travelled, so a faster vehicle bobs faster and one that has
## stopped has nothing advancing it.
##
## Kept stateless and static, like `EightDirection`: the distance is the caller's own state, and
## each caller already keeps one.

## How far the body rises at the top of the bob, in world px — about a pixel, which the camera's
## own zoom draws as two.
const HEIGHT := 1.0

## How much ground one rise and fall takes, in world px: two tiles, which is two to three bobs a
## second at a crowd car's cruising speed and a slow sway at a reversing lorry's.
const WAVELENGTH := 64.0

## The body's vertical offset for a vehicle that has covered `travelled` px, scaled by
## `amplitude` (0..1) — negative, since up is negative on this screen, and zero at the start of
## every wavelength, so a vehicle placed at distance zero starts at rest. A smooth sine rather than
## the walkers' `abs(sin())` step: a body on springs sways, it does not land.
static func lift(travelled: float, amplitude: float = 1.0) -> float:
	var phase := TAU * travelled / WAVELENGTH
	return -HEIGHT * clampf(amplitude, 0.0, 1.0) * 0.5 * (1.0 - cos(phase))
