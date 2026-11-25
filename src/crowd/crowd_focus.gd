class_name CrowdFocus
extends RefCounted
## Where the crowd's patch of simulated streets stands: the one question the crowd asks about the
## centre of what it simulates, so that the patch follows whoever the implementation names and the
## crowd knows nothing of who that is. The game's answer is her (`StrollerFocus`); a check hands
## one that answers a fixed point it sets (`tests/fake_crowd_focus.gd`).
##
## **Asked once a tick**, at the point of the tick where the patch is moved (`Crowd.step()` and the
## live tick alike), so the patch follows the source on every tick the crowd takes, whichever half
## of the tick is run. Handed in by `Crowd.use_focus()`.
## This base answers the map's corner: an implementation overrides `where()`.

## Where the patch is centred now, in world pixels.
func where() -> Vector2:
	return Vector2.ZERO
