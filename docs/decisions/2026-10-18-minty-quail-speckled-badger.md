# minty-quail — The checkpoint suite puts its huts, gates and doors into play as plans (tests through public seams) · 2026-11-05


minty-quail's `tests-unseen-reads.md`, section 2.1's checkpoint row and section 2.2's checkpoint
site: `tests/test_checkpoints.gd` no longer writes the event manager's live list or an
`EventWorld` field. No `src/` change.

**Built.**
- Every hand-built hut, gate, alley post, door, chatting mother, heated roadblock guard,
  loudspeaker and robber is a `Planned` carrying its `facing`, `gate_state`, `age` and `route` where
  needed, handed to `EventManager.streaming.add()` and put into play by `stream_around()`, through
  one helper (`_door_instance()`, with `_planned_instance()` for a def built in the test). The
  street-door rig adds the planner's own `door_bodies` plans. The manager owns its events, so the
  hand `free()` calls and the suite's own atlas are gone.
- The suite's checks are the same in number and meaning; it passes shuffled and repeated.
- The baby's `WorldContext.excitement_sources` is still handed the manager's sources: `main.gd` and
  `City` make the same hand-in, so it is a seam, and the item's 2.2 verdict now says so.

**Open to overturn:** the manager is built over `WorldMap.open_ground()`, since the hand-built
instances never had a map and a bare `CityMap` is walled (it silenced the loudspeaker in the toll
test); `stream_radius` is `INF`, so a plan is not streamed out when a test leaves her far away, as
the old list never let go; the helper calls `stream_around()` itself, as `main.gd` and the day
director do, since the tests hold the instance before any tick; the guard rig no longer swaps in an
open-ground world of its own.
