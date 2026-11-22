# The events' looks are handed the drawn view, as the crowd is

**What is wrong today.**

- **The crowd is handed the box and the events fetch it.** A crowd member asks `CrowdView` (what
  the crowd is handed of the screen; `main` builds `ScreenCrowdView` and the simulation's builder
  hands it on), a port that exists, in its own words, so that "neither the agent nor the crowd
  reaches for the viewport". An event's look asks the static `DrawnView.shows(event, reach)`
  (`EventLook._in_the_drawn_view()`, and `RoadblockLook._shows_its_nodes()` for the band a
  roadblock's guard leaves at his post), which goes from the event's own node to its viewport. That
  is the one place the simulation reaches a viewport: `rg -n "get_viewport\(\)" src/events
  src/crowd src/player src/resistance` finds nothing, because the reach is inside `DrawnView`. The
  simulation is a layer that is handed what it reads; the layer check passes this only because its
  fetch rules look for a group, an autoload, a stateful static and the tree's root, not for a
  viewport reached through a handed node.
- **The static keeps state the checks cannot see.** `DrawnView.box_of()` stores `[frame, box]` as
  meta on the viewport (`MEMO_META`). `tools/layer_map.py`'s own test for a harmless static is "a
  cache that depends on nothing a caller did"; this one depends on when in the frame its first
  caller asked, which `CrowdView`'s comment relies on ("the first agent asked in a frame sees the
  camera as it stands then"). Written as a `static var` it would have to be listed or fail in the
  simulation; written as engine meta it is listed nowhere, and the test runner's comparison of
  shared state between suites does not see it either.
- **A fake has nothing to be handed to** (inbox #1156 in gray-dolphin). `tests/test_drawn_view.gd`
  can hold an event's gate only by building a `SubViewport`, setting its canvas transform and
  waiting a real process frame after every move, because of the memo. Every other suite that puts
  an event in the tree has its redraws gated by the test runner's root viewport, which no test
  set. Row 5 of minty-quail's `event-interface.md` (the events' suites test one module each) is
  about to write the events' drawing suites round one real live event and a recording drawer; the
  gate should be something they hand in.
- **One fact, shared only by convention.** The crowd and the events see the same box because both
  happen to ask the same static about the same viewport.

**The design.** `DrawnView` (`src/world/drawn_view.gd`, world, one file, still naming only the
engine) becomes the object that derives the box once a process frame and is handed around.

- `DrawnView.new()` is a view with no screen: `has_screen()` is false, `shows()` answers true for
  everything (a rig has no screen to be off) and `box()` is empty.
- `DrawnView.on(anchor: Node) -> DrawnView` is the screen the anchor's viewport shows, read at each
  ask rather than held, as `ScreenCrowdView` reads its anchor's, so one made before the anchor is
  in the tree answers once it is; an anchor outside the tree is no screen.
- `box() -> Rect2`: the world the camera shows grown by `MARGIN`, by the same arithmetic and the
  same rule as today (worked out on the first ask of a process frame), the memo in the object's own
  two fields. `shows(item: Node2D, reach: Rect2) -> bool`: as today, true for an item outside the
  tree.
- The statics `shows()` and `box_of()` and `MEMO_META` go; no forwarder stays (minty-dolphin #852).
- A suite's stand-in extends `DrawnView` and overrides `has_screen()` and `box()`, each with its
  `## Overrides DrawnView.<method>.` line. `has_screen()` is what `shows()` asks first; if nothing
  else under `src/` comes to ask it, it is still the game's own question and not a test's.

**Who builds it and hands it.**

- `main._simulation_builder()` builds one, `DrawnView.on(self)`, a boot, and hands the same object
  two ways: to the builder (`SimulationBuilder.use_the_drawn_view()`, default `DrawnView.new()`),
  and to `ScreenCrowdView.new(self, drawn)`, whose `drawn_box()` returns `drawn.box()`. The second
  argument is required, so a forgotten one cannot mean a second memo; the nine suites and probes
  that build a `ScreenCrowdView` pass `DrawnView.on(anchor)`. `CrowdView`, the crowd and its
  agents do not change.
- `SimulationBuilder._new_events()` hands it to each world's events
  (`EventManager.use_drawn_view()`, kept by `EventWorld`); `EventWorld.surroundings()` puts it in
  what every live event is set up in (`EventSurroundings.shown_by(view)`, read back by
  `drawn_view()`, default `DrawnView.new()`).
- `EventInstance.setup()` hands it to its look with the row and the drawer
  (`EventLooks.for_row()`, `EventLook._init()`, and `RoadblockLook._init()` passing it up), since
  it is one more thing that never changes under a look. The two gates ask `_drawn_view.shows(...)`.

There is one viewport in the game (nothing under `src/` makes a `SubViewport`), so every event and
every crowd member is asked against the box it is asked against today.

**What changes for a rig, on purpose.** An event a suite puts in the tree and hands no drawn view
is always drawn, where today it is gated by the test runner's root viewport. That is the crowd's
rule already (an agent with no view is always drawn). The builder lists any suite whose
expectations moved and why.

**Tests.** `tests/test_drawn_view.gd` keeps one case on a real `SubViewport`, the box itself under
a zoom and a quarter turn (`DrawnView.on(screen)`). Its event cases (the cyclist walked in from off
screen, the wide burning front) hand a stand-in whose box the case moves, with no viewport and no
frame waited for the memo. Its crowd cases keep `ScreenCrowdView` over the `SubViewport`.
`tests/test_frame_record.gd`'s one look built by hand takes the new argument.

**Order, one pull request:** the class; `ScreenCrowdView` and `main`; the builder, the manager,
the world and the surroundings; the looks; the suites and probes. It answers the architecture
questions; question 3 (handed and fetched) is the point of it.

**What holds parity.** Nothing a player sees changes: the same box, the same margin, the same
once-a-frame rule, asked of the same viewport. Shown by `tests/probes/screen_reads_fingerprint.gd`
(it prints the crowd's drawn box for a spread of camera poses, zooms and the rotated presentation)
identical on base and branch; by `tests/test_drawn_view.gd`, which holds each gate to redrawing no
later than the first frame any of its drawing reaches the screen; by the full suite; and by one
short headless day's run log matching line for line, frame lines left out. No remeasure: the ask
loses a meta lookup and gains a field read.

**Cost.** Medium. About ten files under `src/` with a few lines each (`src/world/drawn_view.gd`,
`src/ui/screen_crowd_view.gd`, `src/main.gd`, `src/simulation_builder.gd`,
`src/events/event_manager.gd`, `event_world.gd`, `event_surroundings.gd`, `event_instance.gd`,
`views/event_looks.gd`, `views/event_look.gd`, `views/roadblock_look.gd`), one suite reworked, and
about ten one-line edits in suites and probes. No new file, no line in `tools/layer_map.py`, and
the rules hook's row for `src/world/drawn_view.gd` stands as it is. `CrowdView`'s and `DrawnView`'s
comments and the cues skill's `references/drawing-and-redraw-gates.md` say the box is handed.

**What it collides with, and when it runs.**

- **It follows minty-quail's `event-interface.md` row 4b (a row is written as its parts)**, whose
  look part (`LookSpec`) rewrote the same lines: the looks' constructors, `EventLooks.for_row()` and
  the look's line in `EventInstance.setup()`. What is left of row 4b (the composer's writes of the
  live event's behaviour slots, two unused members) touches none of them, so it can start.
- **It lands before row 5's drawing-suite group** (the events' suites test one module each), so
  those suites are written handing the stand-in rather than converted twice.
- misty-raven (the danger cues and the events do less work for what cannot matter) and
  polite-plover (attribute the remaining slow frames) measure the redraw gates' cost and may touch
  `EventLook.redraw_if_the_picture_changed()`: no conflict of meaning, either order.
