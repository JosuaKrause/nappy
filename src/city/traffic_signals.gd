class_name TrafficSignals
extends RefCounted
## Which arm of a signalled junction is being let through, and when.
##
## **A signal is a timing problem where a zebra is a gap-hunting one**, and that is the whole
## reason main roads have them. An ordinary street is crossed by watching for a gap and by
## traffic that gives way to somebody standing at the kerb; a main road is crossed by waiting for
## the light. One is a gamble that gets better the longer you look, the other is a wait with a
## known end — and having both is what makes *which street* a question worth asking.
##
## Two things follow from that and neither is decoration:
##
## - **Traffic on a main road does not give way at a zebra.** The paint is still there and it is
##   still where a person on that road is meant to be, but what stops the cars is the light. See
##   `CrowdAgent._crossing_ahead_somebody_is_waiting_at`.
## - **The clock is simulated, and it starts again with the day.** Running off wall time would
##   make a run irreproducible from its seed, and *not* resetting at dawn breaks the same thing
##   one step along: two attempts at the same day would find the same cars at different lights
##   and diverge on the first frame. What is learnable is not where a cycle happens to be but the
##   pattern — which junctions are signalled, how long a wait is, and that the greens run down the
##   spine as a wave. See `Crowd.start_day`.
##
## The greens run down the spine as a **wave**, and that is not a driver's convenience — it is what
## makes the spine a road rather than a car park. Arbitrary offsets stop a car at every junction it
## comes to: measured at act I density, two thirds of the traffic was stationary at any instant.
##
## **The wave runs one way.** Northbound traffic — the way the offsets count down — meets
## a green at 93% of junctions; southbound meets one at 51%, which is chance. That is not a bug to
## be fixed but an arithmetic fact about this geometry, and `Tuning.SIGNAL_PROGRESSION_BLOCKS`
## carries the derivation and the two alternatives that are worse.

## The four states of a junction, in cycle order. Amber belongs to the arm that is *losing* the
## green — it is a clearance period, so the crossing arm stays red through it.
enum Phase { MAIN_GREEN, MAIN_AMBER, SIDE_GREEN, SIDE_AMBER }

## Simulated seconds since the run began. Advanced by `City`, which is also what pauses it: the
## lights stop with everything else behind the pause screen.
var elapsed := 0.0

var _map: CityMap

func _init(map: CityMap) -> void:
	_map = map

func advance(delta: float) -> void:
	elapsed += delta

## Whether a junction has lights on it at all: one of the two corridors crossing there is a main
## road. Every junction on the spine is signalled and no other one is, which is what makes the
## lights a property of the street rather than a scattering of them.
func is_signalled(junction: Vector2i) -> bool:
	return junction.x == _map.main_road

## Which axis is the *main* arm of a junction — the one that gets the long green. Always the
## north-south one, because there is one main road and it runs north to south. Kept as a function
## rather than folded away because everything below reads better stated over an arm than over an
## axis, and because a city with a second spine would change this and nothing else.
func main_arm_is_vertical(_junction: Vector2i) -> bool:
	return true

func phase_of(junction: Vector2i) -> Phase:
	var main_green := Tuning.signal_main_green_seconds()
	var side_green := Tuning.SIGNAL_SIDE_GREEN_SECONDS
	var amber := Tuning.SIGNAL_AMBER_SECONDS
	var at := fposmod(elapsed + _offset(junction), Tuning.signal_cycle_seconds())
	if at < main_green:
		return Phase.MAIN_GREEN
	if at < main_green + amber:
		return Phase.MAIN_AMBER
	if at < main_green + amber + side_green:
		return Phase.SIDE_GREEN
	return Phase.SIDE_AMBER

## Whether one arm of a junction has green right now. Amber is not green: a car far enough out to
## stop must stop for it, which is what `stopping_for` decides.
func green_for(junction: Vector2i, vertical: bool) -> bool:
	var main := main_arm_is_vertical(junction) == vertical
	var phase := phase_of(junction)
	return phase == Phase.MAIN_GREEN if main else phase == Phase.SIDE_GREEN

## Whether the light is telling this arm to stop — red, or the amber that precedes its own red.
## Split out from `green_for` because a car and a person want opposite halves of it: a driver on
## amber may carry on if it cannot stop, and a person must never step out on one.
func amber_for(junction: Vector2i, vertical: bool) -> bool:
	var main := main_arm_is_vertical(junction) == vertical
	var phase := phase_of(junction)
	return phase == Phase.MAIN_AMBER if main else phase == Phase.SIDE_AMBER

## How far along the wave a junction sits: one junction's travelling time per junction down the
## spine. See `Tuning.SIGNAL_PROGRESSION_BLOCKS` for which direction that serves — one of them,
## not both — and what happens without it: two thirds of the traffic standing still, measured.
##
## The index is the one the main arm travels along, so the wave runs down the spine and the side
## streets take what they are given.
func _offset(junction: Vector2i) -> float:
	var along := junction.y if main_arm_is_vertical(junction) else junction.x
	return fposmod(float(along) * Tuning.signal_travel_seconds(),
			Tuning.signal_cycle_seconds())
