# minty-quail — The run flow announces every walk by three signals, and the run log watches any spec the same way · 2026-11-09

**The ask.** "there really should be no separate code for escape", "the escape is just like a
normal day with some special settings" (inbox #785 in minty-lemur); to the design review's plan,
"One `start(spec)` for every kind of day, with the world built per spec by a builder handed in, one
day-started event, and the run log watching any spec the same way", the player: "agree on all
design review points. let's do it" (inbox #1268 in olive-ferret). The item is
`docs/todo/2026-10-18-minty-quail/one-start-for-every-spec.md`; this record is its second pull
request, the signals and the run log, after misty-sparrow (the start).

## What was built

- **The run flow (`RunFlow`) announces every walk by three signals, each carrying the spec.**
  `day_started(spec)` fires after the dawn photograph and before the world is stood, where
  `EventBus.day_started` fired; the HUD, the page counter and the readout's day line hear it.
  `world_stood(spec, world, restarted)` fires with the world (`DayWorld`) before anything is
  placed; the run log writes its header there and points its observer at the world.
  `day_planned(spec, world)` fires once the walk is placed; the run log's plan lines, dawn map and
  `start` line, the readout's routes, the route rig and the building walker hear it. An authored
  walk never sends it.
- **`DayDirector.start(spec, started, stood)` calls back what the run flow hands it** and sends
  nothing on the signal bus; its last branch on "is this a section" is gone.
- **Deleted, with no forwarders:** `EventBus.day_started`, `day_planned` and
  `escape_section_started`; on the run log's session (`RunSession`) `watch_day`, `watch_escape`,
  `watch_the_clock` and its casts of the world to the city or the building; on the observer
  `setup_escape`, `watch_building`, `watch_city` and `start_section`; `DayWorld.scene()` and the
  director's `restarted` parameter.
- **What replaces them:** `RunSession.watch(clock, resistance, edge)`, called once a boot by
  `main`; the observer's one `setup`, one per-walk `watch` and one `start(restarted)`;
  `DayWorld.map()`; `VisitCounter.listen_to_the_flow(flow)`; `HUD.use_the_day(spec)` in place of
  the HUD's three bus handlers.
- **Parity:** `tests/fixtures/observed_run_log.txt` is unchanged and matches line for line, and
  every GoatCounter name `tests/test_observers.gd` pins is unchanged.

## The builder's choices, each open to overturn

- **Three signals, not the design's two.** The escape's city goes dark while it is built
  (`Blackout.setup()`, inside `City.build()`), sending the page count `nappy-day-16-blackout`, and
  day 16's `began` count must come first, so the walk is announced before its world stands. The run
  log still needs the world before anything is placed (a day's header names the city's seed, which
  can differ from the run's), and an authored walk is watched too. The alternatives were to darken
  the escape city after the announcement, which is city code, or to announce authored walks as
  planned.
- **A section's header comes after its world is first built**, so lines written during that build
  (in the scripted run only the atlas's `texture` lines, which the fixture filters out) stand above
  it in a real log.
- **An authored escape section writes no `start` line**, as an authored day never did; it is still
  watched frame by frame. Its observer's per-walk reset (`TelemetryObserver.start()`, which records
  whether she starts on calm ground or a road) is skipped with it, so an authored walk that starts
  her on either may write a `calm` or `road` line on its first frame that she never walked into.
- **`tests/test_observers.gd` changed**, where the brief asked it to pass unchanged: its recording
  page counter is seated in the boot's sitting, so `main` hands it each boot's flow; on the bus alone
  it could no longer hear a walk begin. The fixture, the expected names and the check texts are
  unchanged.
- `main` connects the developer's listeners with `.unbind(1)`, so nothing under `src/dev/` changes;
  `restart_section_clock()` is called on days too, where it changes nothing.

## What is left

The item's third bullet, who builds the event manager and the crowd, with the third hand-ins pull
request.
