# Shared components instead of copies that drift

- **The park cordon still checks its own copy of the placement rules**: `ParkCordon`'s officer
  placements, and the `shows` callable `ResistanceHappenings.tick()` keeps for them alone; every other
  placement asks `SpawnSiting`'s named rules (minty-quail-29, minty-quail-30).

**Open question, the orchestrating session's carry-over from minty-quail-5 rather than the player's
ask:** whether the crowd's lane movement goes onto the map's one `Navigator`. It is not part of the
walker-and-car split, because a lane-following held step is a different motion model from the
navigator's swept step, so moving it cannot stay at test parity; it sits beside the separation pass,
which reaches the same movers.
