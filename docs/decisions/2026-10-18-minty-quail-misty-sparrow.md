# minty-quail — Every spec starts through the day director: the days, an authored scene and both escape sections (minty-quail, one start for every spec) · 2026-11-09

**The ask.** "there really should be no separate code for escape", "the escape is just like a
normal day with some special settings" (inbox #785 in minty-lemur); shown the design review's finding that a day
is finished by one controller but started in three places, the player: "can we improve this?", and
to the plan, "agree on all design review points. let's do it" (inbox #1268 in olive-ferret). The item is
`docs/todo/2026-10-18-minty-quail/one-start-for-every-spec.md`; this record is its first pull
request, the start.

## What was built

- **`DayDirector.start(spec, restarted)` is the only start**, for a day, an authored scene's day
  and both escape sections (`DayDirector` is the class that starts and ends a day). Its order: the
  spec goes to the clock, the dawn is photographed where the spec says so, and the day's start is
  announced; the world is stood and the city dressed; the events are planned
  (`EventManager.start_day()`); the resistance starts, or the authored scene installs itself; the
  events are streamed round her start and the crowd starts; she and the baby are put down and the
  clock starts; the day's plan is announced.
- **The world comes from a source the director is handed** (`DayWorldSource`, one method,
  `stand(spec)`), which answers a `DayWorld`: the scene and its events, her and the baby, where she
  starts and which way she faces, the city with its streets and crowd where there is one, the
  world's own random stream, and what the walk is won at in it: the map her front door is on and
  the ways out of the city, which the director hands on to the spec and the day's clock, so a
  source only stands a world and writes into nothing. The main scene implements it; the director fetches nothing from the
  tree, a group or an autoload for its world.
- **Settings on the spec replace the branches on "is this a section"**, each read through a
  method: where she starts (her doorstep, the flat, the service exit), whether the dawn is
  photographed, whether the day runs the resistance, whether the baby starts asleep, and three the
  start needed beyond those: whether the day spends the one-shots, which of the run's streams its events are planned on, and
  whether it shuts the calm she has spent. The day planner's assert pairing closed streets with
  "not a section" is gone.
- **Gone, with no forwarder kept:** the main scene's own start of a section and its own planning of
  the escape city, and the director's separate start of an authored day. The two world builders in
  the main scene only build.
- **The director's suite tests the start on fakes**, with no city generated: a day's start in
  order, the city section, the building section, an authored scene, and one check per setting.
- **The run log's recorded baseline is line for line identical.**

## What is left of the item

The one remaining branch on "is this a section" in the start is the signal the run log's escape
path listens for, sent for sections only; the item's second pull request (one signal each for a
day started and a day planned, the run log watching any spec the same way) removes it. Who builds
the event manager and the crowd is the third.

## Choices the builder made where the design was silent, open to the player's overturn

- **`DayWorld` carries her and the baby**, since a section's boot has no player until its world is
  built, and **the building's own random stream**, without which every building's basement would
  change.
- **The day's clock is set up in two calls**: once with the run (`DayController.setup(run)`), and
  per walk with what the walk is won at (`use_the_walk(home_map, player)`), since the director is
  never handed the run.
- **A world answers no home map off a walk home**, so falling asleep in the escape city spends no
  park.
- **The new files are in `src/day/`**, whose folder is in the flow layer, so the layer map gained
  no line.
- **No authored walk announces that the day is planned.** The authored escape used to announce it
  before its scene installed; its clock now starts once, before the install.
- **A restart of the city section dresses the city again**, as a day's retry does; before, it only
  planned again. The street trees are refreshed after the escape city's plan too, which changes
  nothing today because no escape seal takes a tree pit.
- **An authored scene of the escape** (a scene recipe, a developer's tool) changes in two ways:
  the signal that an escape section started is sent after the scene installs, so the run log's
  start line records where the install put her and not the service exit; and since no authored
  walk announces that the day is planned, the developer's route rig does not start for an authored
  escape.
- **An authored scene's day goes through the handover of the calm areas already used this act and
  the fenced park**, which its separate start never did. It changes nothing today: a scene recipe
  boots a fresh run that has neither.
- **The developer's start flags** (`--spawn`, `--meters`, `--start-escape <part>`) apply on the
  boot's first walk, and `--spawn` and `--meters` only from her doorstep.
- **The run's facts record which escape section is walked on every walk**, so a day records none.
- **Hiding the HUD** moved to the section's brief.
- **Console output:** an escape section prints the "day started" line a day prints, and the
  finale's own line no longer carries its time and seed.
