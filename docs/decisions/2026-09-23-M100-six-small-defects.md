## M100 — Six small defects · 2026-09-23

From M100's list, one commit each, no behaviour a player sees changed. The contact is placed
before `--spawn contact` reads it (`ResistanceDirector.start_day()` moved ahead of
`DevRig.spawn_position()` in `main`'s day start). The balance rig's camera runs in physics
process mode like the real one, so the engine's warning is gone. `Crowd.step()` and
`_physics_process()` share `_advance_the_world()`; `step()` now moves the agents before it rather
than in the middle, which is neutral because the signals' clock and the pockets read nothing an
agent's position changes. `CityMap.is_main_road(vertical, corridor)` is the one spelling of the
question, and the seven hand-written sites go through it. A local test shard is killed after
`SHARD_TIMEOUT_S` (600 s, about twice the slowest shard; `TEST_SHARD_TIMEOUT_S` overrides it) and
reported by name, so the "crashed or hung" message is reachable; `--serial` and `--shard I/N` stay
unbounded since they run far more than one shard's suites. `EventInstance.noticed_at()` is the
save half of `resume()`, and `EventManager` reads it rather than the private field.
