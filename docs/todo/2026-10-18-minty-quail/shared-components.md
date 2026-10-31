# Shared components instead of copies that drift

What a crowd body and an event charge her is one `ExcitementSource` (`src/world/`) each composes, with
only its own field per type (`EventExcitement`, `CrowdExcitement`), answered per world by
`ExcitementSources` sets that `WorldContext` holds, the door rule stated once (minty-quail-27).

- **Placement has about 25 entry points in four classes**, with self-declared copies:
  `EventsAhead._where_the_sent_pursuer_starts` copies `ResistanceDirector._draw_arrival_position`
  without its in-view check; `EventsAhead._a_clear_run_at` equals `ResistanceDirector._a_clear_run`
  plus `_runs_through_the_boundary`; `send_a_pursuer` and `_send_at_her` repeat the same closures;
  `_his_walk_reaches_her` simulates a straight chase only because chasers do not path.
- **Movers do not see each other:** event figures pass through walkers and cars and back.

**Build:** one `SpawnSiting` service with registered legality rules and a "reaches her" query on the map's one
`Navigator` (`WorldMap.navigator()`); a shared separation pass over every mover. **Who gives way** (inbox #884): asked whether, when
event figures and the crowd meet, the crowd yields, everyone separates, or only cars stop, the player:
"(a) the crowd yields. a charging dog doesn't care but a pedestrian doesn't want to get overrun. same
applies to other events." **Read as:** walkers step aside or are pushed and cars stand for an event
figure, while every event figure keeps its course and timing.

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

**Carry-overs from events-composed (minty-quail-26), the orchestrating session's rather than the
player's ask:** an event instance uses the red arrow's `ArrowField` (`src/resistance/arrow_field.gd`,
the resistance's walking-distance field) as its pathfinder, a dependency on the resistance where the
map's one `Navigator` is the shared one; a car's driving copies crowd traffic's
give-way (`EventCarDriving.room_to_its_line()`), the copy `LaneMover` takes; movement proposed,
validated, then committed for every mover, as a car's frame is (minty-quail-17), built so far for the car
alone; and the city behind the title screen: on a day the street plays on there, so the traffic
signals, every event's age, phase and repeat timers, the shared broadcast clock and the street's
stocking advance on ticks no walk stepped, while the day's own clocks count only the ticks the walk
stepped. That stays (inbox #883): asked whether the day should keep playing on behind the title, freeze,
or start fresh, the player chose to keep it, "a little bit of variety is fine", since a seed-of-the-day
run is played whole, only day 1 is affected and it opens on a predictable scene, and "no events ever
spawn at the home block anyway". **Read as:** no reset when a day starts; the docs say the city runs on
behind the title.

**Open question, the orchestrating session's carry-over from minty-quail-5 rather than the player's
ask:** whether the crowd's lane movement goes onto the map's one `Navigator`. It is not part of the
walker-and-car split, because a lane-following held step is a different motion model from the
navigator's swept step, so moving it cannot stay at test parity; it sits beside the separation pass,
which reaches the same movers.
