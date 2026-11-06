# minty-quail — The run log and the page counter are handed in, kept under the sitting, not reached through autoloads · 2026-11-06

minty-quail's `tests-unseen-reads.md` kept `Telemetry.begin_memory_log()` because the observer and
the gameplay classes called the `Telemetry` autoload by name, so no test could hand them a log, and
`tests-isolated.md` kept `t.gives_back_observers()` because the `Telemetry` and `VisitCounter`
autoloads held the observers' count of a run, which no suite could hold. Both rested on the rule of
dependency injection throughout (minty-lemur #794) and the player's ruling that a member only tests
read goes where it can (curly-rabbit #1095).

**Built.** Neither is an autoload any more. `Telemetry` (`class_name Telemetry`, still
`src/autoload/telemetry.gd`) and `VisitCounter` (`class_name VisitCounter`) are children of the
`Sitting`, which `main` makes on the sitting's first boot and finds there after, the save's pattern,
so the log a run is writing and the counter's count outlive every scene reload exactly as long as
before. `main` hands the log to `RunSession`, which hands it to the `TelemetryObserver` it makes;
the save, `--route`'s two walkers, `--quit-when-still` and `DevRig`'s spawn refusal write through
the session's `RunTrace` (the last through `city.trace`); `FrameTrace` takes the log's `is_active`;
the atlas library, which reached `/root/Telemetry` by node path, holds `trace_note`, a `Callable`
`main` hands it each boot, and `GroundLayers` writes its `ground composed` line through the library
it builds from, which removes the listed layer break of `GroundLayers` naming `Telemetry`.
`VisitCounter` is handed the game's `EventBus` and the page's outbox by `main` instead of fetching
the bus in `_ready()`. The log's directory moved from `begin_run()`'s third parameter to its
constructor; a log made over `""` keeps its runs in memory, which is how a suite gets one.
`begin_memory_log()` is deleted; `main.use_run_log()` is added beside `use_save()` as a hand-in.
`t.gives_back_observers()` and its 30 declarations, `SharedState.OBSERVER_FIELDS` with
`observers()` and `put_back_observers()`, the boot helpers' `hold_observers()` and
`give_back_observers()`, and the runner's `_reset_globals()` are deleted: a boot's observers are its
sitting's, freed with it. 17 files under `src/` changed.

**Measured.** At test parity: every suite the change reaches passes, run by name and once shuffled
(`--shuffle 7`), with no `ERROR:` line; `./tools/check.sh` boots with the atlas page and composed
ground lines in its run log as before; the observers suite's baseline log matches line for line,
since the memory log's header keeps its wording. A memory log's header names no time and no version,
so opening one makes no `git` call. Nothing is remeasured for the game: no line, kind or event name
changed.

**Rejected.** Keeping the autoload as the game's default log with only the tests' callers
converted, which the brief allowed: the counter would still have heard every bus signal a booted
suite emits, so the declaration could not have gone. Renaming the class `RunLog`: every doc calls
the run log `Telemetry`, and the rename would have been a diff over all of them with no change in
meaning. A trace parameter on `GroundLayers.build_tile_set()`: its caller is in `src/city/city.gd`,
another build's file, and the atlas library it is handed already carries the page lines beside
which its line sits. A `RunTrace` on `AtlasLibrary`: the library is on the data layer, below the
model layer `RunTrace` is on, so it holds a `Callable`.

**Open to overturn.** A log over `""` is a mode of the directory value only suites hand; the game
never makes one. `SceneryWater`'s suite checks the surface handed no library makes one, and watches
the page lines of a surface handed a library of the test's own, since a library a node makes for
itself writes nowhere.
