# Shared components instead of copies that drift

- **The excitement source is copied.** `CrowdAgent` and `EventInstance` both carry 24 methods with
  the same names and no shared base (`contribution_at`, `expected_gross_at`,
  `_sample_expected_landed`, `accumulate_landed`, `_prune_landed_history`, `_walled_off_now`,
  `wall_grid`, `will_be_lethal`, `set_halo_strength`, ...), documented as "duck-typed with
  CrowdAgent's own copy"; the copies already differ (signatures, extra bookkeeping, the wall cache
  keyed on the two points in `EventInstance` and on the two points and `_map` in `CrowdAgent`, a
  pelican hook in one).
- **Placement has about 25 entry points in four classes**, with self-declared copies:
  `EventsAhead._where_the_sent_pursuer_starts` copies `ResistanceDirector._draw_arrival_position`
  without its in-view check; `EventsAhead._a_clear_run_at` equals `ResistanceDirector._a_clear_run`
  plus `_runs_through_the_boundary`; `send_a_pursuer` and `_send_at_her` repeat the same closures;
  `_his_walk_reaches_her` simulates a straight chase only because chasers do not path.
- **Movers do not see each other:** event figures pass through walkers and cars and back.

**Build:** an `ExcitementSource` component both compose, with only the field itself per type; one
`SpawnSiting` service with registered legality rules and a "reaches her" query on the map's one
`Navigator` (`WorldMap.navigator()`); a shared separation pass over every mover.

**Carry-overs, the orchestrating session's rather than the player's ask.** `CrowdView` (in
`src/crowd/`, simulation) reads the shared `DrawnView` and `ScreenOrientation`, which are view-layer;
a cleaner version hands the crowd the drawn box and the camera square as plain values, owned by `Main`
or `City`; the same holds for `CrowdTiming`, which reads `FrameRecord`'s statics, and for
`Crowd._meet_the_player()`, which finds her through the `player` group. And the comments in `src/events/` that name members the crowd's split moved
(`CrowdAgent.WALKER_VIEW_BY_SECTOR`, `_update_walker_view()`, `_advance_walker_gait()`,
`_walker_gait_frame()`, `CAR_CANVAS_BOTTOM_MARGIN`, `_car_body_anchor()`, and the crowd's redraw gate
named at `event_instance.gd:3907` as `CrowdAgent._redraw_if_the_picture_changed()`, now `_end_the_frame()`) are renamed to where those
members live (`WalkerLook`, `CarLook`) once both the crowd's split and the events step that owns
`src/events/` have merged.

**Carry-over from events-composed 4b (minty-quail-25), the builder's fork rather than the player's
ask:** `WorldContext` (`src/world/`, the world layer) holds fields typed `EventManager` and `Crowd`
(simulation) so it can hand the baby both answers to "how exciting is it here", a typed dependency
pointing up a layer. The `ExcitementSource` component above is what those fields are typed against
once it exists, both the manager and the crowd extending or composing it; the plainer alternative
the builder named is the world handed callables instead of the objects.

**Carry-overs from events-composed (minty-quail-26), the orchestrating session's rather than the
player's ask:** an event instance uses the red arrow's `ArrowField` (a view-side helper) as its
pathfinder, where the map's one `Navigator` is the shared one; a car's driving copies crowd traffic's
give-way (`EventCarDriving.room_to_its_line()`), the copy `LaneMover` takes; and the traffic signals
advance on every physics tick the crowd runs, behind the title screen too, while the day's clocks count
only the ticks the walk stepped (the 4c builder's fork: the crowd's tick in `src/crowd/crowd.gd`
decides it).

**Open question, the orchestrating session's carry-over from minty-quail-5 rather than the player's
ask:** whether the crowd's lane movement goes onto the map's one `Navigator`. It is not part of the
walker-and-car split, because a lane-following held step is a different motion model from the
navigator's swept step, so moving it cannot stay at test parity; it sits beside the separation pass,
which reaches the same movers.
