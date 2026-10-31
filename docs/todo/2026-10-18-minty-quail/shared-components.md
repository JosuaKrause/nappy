# Shared components instead of copies that drift

- **Placement still has entry points that check their own copy of the rules**: the director's guard
  spots, roadblock ground, door, swing, mast and neighbor starts and `_pick_reachable`; `EventsAhead`'s
  officers' doors, down her line or along her heading, the mast and task rows; `EventSpawner`'s
  summoned stop; `ResistanceHappenings`' day-10 raid (`_maybe_raid()`, refusing a van or a row with
  the director's handed-in "would it show" check) and day-13 column (`send_the_column()` through
  `PendingWarning.in_its_lane()`, with its own lead distance). Each keeps its own candidate shape and asks `SpawnSiting`'s named rules instead
  (minty-quail-29 built the service and moved the sent pursuers onto it). Legal ground does not test
  the map's bounds, which only a scene recipe's exterior reaches (an off-map tile reads as an alley
  there); the poster's search tested them before minty-quail-29, the director's never did.
- **Movers do not see each other:** event figures pass through walkers and cars and back.

**Build:** a shared separation pass over every mover. **Who gives way** (inbox #884): asked whether, when
event figures and the crowd meet, the crowd yields, everyone separates, or only cars stop, the player:
"(a) the crowd yields. a charging dog doesn't care but a pedestrian doesn't want to get overrun. same
applies to other events." **Read as:** walkers step aside or are pushed and cars stand for an event
figure, while every event figure keeps its course and timing.

**Carry-overs, the orchestrating session's rather than the player's ask.** `CrowdView` (in
`src/crowd/`, simulation) reads the shared `DrawnView` and `ScreenOrientation`, which are view-layer;
a cleaner version hands the crowd the drawn box and the camera square as plain values, owned by `Main`
or `City`; the same holds for `CrowdTiming`, which reads `FrameRecord`'s statics, and for
`Crowd._meet_the_player()`, which finds her through the `player` group, and for `VisibleView`, which
sits on the world layer (minty-quail-29) but reads `TouchControls`, `HelpText`, `ControlsMode` and
`ScreenOrientation`, view classes, for the parts of the screen the controls cover. And the comments in `src/events/` that name members the crowd's split moved
(`CrowdAgent.WALKER_VIEW_BY_SECTOR`, `_update_walker_view()`, `_advance_walker_gait()`,
`_walker_gait_frame()`, `CAR_CANVAS_BOTTOM_MARGIN`, `_car_body_anchor()`, and the crowd's redraw gate
named at `event_instance.gd:3907` as `CrowdAgent._redraw_if_the_picture_changed()`, now `_end_the_frame()`) are renamed to where those
members live (`WalkerLook`, `CarLook`) once both the crowd's split and the events step that owns
`src/events/` have merged.

**Carry-overs from events-composed (minty-quail-26), the orchestrating session's rather than the
player's ask:** a car's driving copies crowd traffic's
give-way (`EventCarDriving.room_to_its_line()`), the copy `LaneMover` takes; movement proposed,
validated, then committed for every mover, as a car's frame is (minty-quail-17), built so far for the car
alone.

**Open question, the orchestrating session's carry-over from minty-quail-5 rather than the player's
ask:** whether the crowd's lane movement goes onto the map's one `Navigator`. It is not part of the
walker-and-car split, because a lane-following held step is a different motion model from the
navigator's swept step, so moving it cannot stay at test parity; it sits beside the separation pass,
which reaches the same movers.
