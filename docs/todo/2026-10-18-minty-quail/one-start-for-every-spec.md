# One start for every spec: the days, an authored scene and the escape begin the same way

**The ask.** "there really should be no separate code for escape", "the escape is just like a
normal day with some special settings", "all should be implemented through the regular game
engine's means" (inbox #785 in minty-lemur). This entry's README has one controller start and finish a spec.
The design review found that the day director (`DayDirector`, the class that starts and ends a day)
finishes every spec, but that a spec is started in three places: `DayDirector.start_day()` for the
fourteen days, `DayDirector.start_authored_day()` for scene recipes, and the main scene's
`_start_section()` for the escape, which repeats the day's steps by hand, builds a second event
manager field by field, and has a run-log path and a start signal of its own. Shown that as "A day
is finished by one controller but started in three places. The escape's start is still hand-built
in the main scene, with its own run-log path. That is where the fuller escape and the explosions
would land next", the player: "can we improve this?", and to the plan below, as the orchestrator
summarised it ("One `start(spec)` for every kind of day, with the world built per spec by a builder
handed in, one day-started event, and the run log watching any spec the same way"): "agree on all
design review points. let's do it" (inbox #1268).

**Read as:** no code outside the spec's own settings asks whether the escape is being walked in
order to start it, and an escape start is testable without booting the whole game.

**Build**, the design review's shape, which the player approved ("I saw the review and approved
it", inbox #1268); the detail was worked out by the same review after the approval:

- **`DayDirector.start(spec, restarted)` is the only start.** Its steps: hand the spec to the
  clock; ask for the spec's world; dress the world for the day; plan the events (already one call
  for all three kinds of walk, `EventManager.start_day()`); start the resistance where the spec has
  tasks, or let an authored scene install itself; put her down and start the crowd at the spec's
  density; start the clock.
- **The root builds the world, behind a small interface the director is handed**: asked to stand a
  spec's world, it answers the scene, its map, its events, and its streets and crowd where it has
  them. The main scene implements it from what builds the world today.
- **New settings on the spec replace the branches on "is this a section"**: whether the baby starts
  asleep, whether the day runs the resistance, whether the dawn is photographed, and where she
  starts. The day planner's assert that streets close exactly when the spec is not an escape
  section goes with them.
- **What goes:** the main scene's `_start_section()` and `_plan_the_finale_city()` (the plan is the
  director's step, and the kerb tint follows the plan's walk for every spec);
  `DayDirector.start_authored_day()` (an authored scene is a spec plus the install step); the two
  world builders shrink to the two branches of the root's builder.
- **One signal each for "a day started" and "a day planned"**, on the run flow, carrying the spec
  and its world; `EventBus.day_started(day)`, `EventBus.day_planned(day)` and
  `escape_section_started` are deleted, and the HUD, the page counter and the run log read the day
  number off the spec.
- **The run log watches any spec the same way**, from that signal: the run log's session
  (`RunSession`) loses its escape-only entry points and its casts of the world to the city or the
  building. The recorded baseline `tests/fixtures/observed_run_log.txt` staying line for line
  identical is the proof.

**The pull requests:**

- **The start**: the day director, the run flow, the authored scene, the spec with its field reads,
  the main scene, the scene-recipe runtime's install path, and the day director's suite, which
  gains a building start on fakes.
- **The signals and the run log**: the signal bus, the page counter, `src/telemetry/`, the HUD and
  the run flow.
- **Who builds the event manager and the crowd**, with the third hand-ins pull request
  (`city-hand-ins.md`): the city scene stops building its own, and the building and the city get
  theirs from one factory (`standing-layer-breaks.md`, the city scene as builder).

The first two touch nothing under `src/events/` and run beside placement; the third touches the
event manager's setup and lands between two placement pull requests.
