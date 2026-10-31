# Shared components instead of copies that drift

- **The park cordon still checks its own copy of the placement rules**: `ParkCordon`'s officer
  placements, and the `shows` callable `ResistanceHappenings.tick()` keeps for them alone; every other
  placement asks `SpawnSiting`'s named rules (minty-quail-29, minty-quail-30).
- **Movers do not see each other:** event figures pass through walkers and cars and back.

**Build:** a shared separation pass over every mover. **Who gives way** (inbox #884): asked whether, when
event figures and the crowd meet, the crowd yields, everyone separates, or only cars stop, the player:
"(a) the crowd yields. a charging dog doesn't care but a pedestrian doesn't want to get overrun. same
applies to other events." **Read as:** walkers step aside or are pushed and cars stand for an event
figure, while every event figure keeps its course and timing.

**Carry-over from events-composed (minty-quail-26), the orchestrating session's rather than the
player's ask:** movement proposed, validated, then committed for every mover, as a car's frame is
(minty-quail-17), built so far for the car alone.

**Open question, the orchestrating session's carry-over from minty-quail-5 rather than the player's
ask:** whether the crowd's lane movement goes onto the map's one `Navigator`. It is not part of the
walker-and-car split, because a lane-following held step is a different motion model from the
navigator's swept step, so moving it cannot stay at test parity; it sits beside the separation pass,
which reaches the same movers.
