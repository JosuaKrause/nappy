class_name CarEntryHold
extends RefCounted
## Whether the crowd's cars are being let back into the city: while held, a car that would be
## recycled (re-entered at the edge of the crowd's box, out of view) is parked instead
## (`Crowd`), so no car arrives from outside the box. One object shared by the crowd and every
## agent it makes, since an agent recycles itself and asks for itself (`LaneMover._recycle()`),
## the way it shares the day's `TrafficIndex`. Not held until the crowd says so.

var _held := false

## Holds new cars.
func hold() -> void:
	_held = true

## Lets cars in again.
func release() -> void:
	_held = false

## Whether new cars are held.
func holds() -> bool:
	return _held
