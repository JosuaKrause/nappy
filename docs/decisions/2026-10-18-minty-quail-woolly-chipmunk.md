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
the save, `--route`'s two walkers and `--quit-when-still`'s watch are handed the session's
`RunTrace` by `main`, and `DevRig`'s spawn refusal writes through `city.trace`; `FrameTrace` takes
the log's `is_active`; the atlas library, which reached `/root/Telemetry` by node path, holds
`trace_note`, a `Callable` `main` hands it each boot, and `GroundLayers` writes its `ground composed`
line through the library it builds from, which removes the listed layer break of `GroundLayers`
naming `Telemetry`. `VisitCounter` is handed the game's `EventBus` and the page's outbox by `main`
instead of fetching the bus in `_ready()`. The log's directory moved from `begin_run()`'s third
parameter to its constructor. `begin_memory_log()` is deleted; `main.use_run_log()` is added beside
`use_save()` as a hand-in. `t.gives_back_observers()` and its 30 declarations,
`SharedState.OBSERVER_FIELDS` with `observers()` and `put_back_observers()`, the boot helpers'
`hold_observers()` and `give_back_observers()`, and the runner's `_reset_globals()` are deleted: a
boot's observers are its sitting's, freed with it. 17 files under `src/` changed.

**How the queue bullet's ask was answered: tests hand fakes, and no memory mode stands in for one.**
The bullet asked that the log be handed to the classes that write into it, which "would let"
`begin_memory_log()` go, so that a test hands a fake (inbox #1095 in curly-rabbit). The first build
of this PR replaced the method with a log made over no folder (`Telemetry.new("")`) that kept its
runs in memory, a mode only suites used; review found that to be the same test-only path behind a
constructor value, and the orchestrator ruled, under the player's rules that no test builds a real
object it does not test (inbox #1159 in gray-dolphin) and that a member only tests use goes (inbox #1095 in
curly-rabbit), that the mode goes. A suite that reads what was logged hands a recording fake: a
`RunTrace.recording()` where only a trace's or a library's lines are read (the atlas page watch,
the route rig, the dev rig), or `tests/recording_log.gd`, a `Telemetry` subclass with the same note
surface that keeps each note as `"<clock> <kind> <text>"` and writes nothing, where the observer, a
`RunSession` or a boot is handed a run log (the observers, pelican, police car, burst capture, save
wiring, main, atlas loading and escape suites). `tests/test_telemetry.gd` is the one suite that
builds the real log, over a scratch folder of its own, and tests how a note is written; the run
log's own checks the invincible and burst suites made (the day header's `invincible`, a headless
burst refused, a day or the run cutting a burst short) moved into it. The observers suite's
baseline splits the same way: it pins which notes and sections the observers hand the run log, in
the recording log's shape, and its fixture was rewritten from the old one by a mechanical
transform (each note's clock, kind and text kept, each section header turned into the call that
writes it, the blank lines and the opening header dropped), which the suite then matched line for
line, so the two say the same thing.

**Two checks that could not fail now can.** `main` handed `--quit-when-still`'s watch no trace in
the first build, so its `still` line went nowhere; `main` hands it the session's, and
`tests/test_main.gd` boots with the flag and a recording log, writes a line through the watch's
trace and finds it in the boot's log, which proves `main` hands the watch the trace. The
route rig suite's check that the rig never walks under a checkpoint boom counted `checkpoint` lines
from a city whose events wrote nowhere, on `main` as here; its rig and the city's events now write
into one recording trace. Measured by hand, not committed: with her walked under the boom through
the door watch partway through the rig's run, the check fails with one walk under, where on `main`
the same walk would have left the count at nought. Emptying the planner's boom ground alone did not
put the rig under the boom: a hut still held her on the way, and the check stayed at nought.

**Measured.** At test parity: every suite the change reaches passes, run by name and once shuffled
(`--shuffle 7`), with no `ERROR:` line; `./tools/check.sh` boots with the atlas page and composed
ground lines in its run log as before. Nothing is remeasured for the game: no line, kind or event
name changed.

**Rejected.** Keeping the autoload as the game's default log with only the tests' callers
converted, which the brief allowed: the counter would still have heard every bus signal a booted
suite emits, so the declaration could not have gone. Renaming the class `RunLog`: every doc calls
the run log `Telemetry`, and the rename would have been a diff over all of them with no change in
meaning. A trace parameter on `GroundLayers.build_tile_set()`: its caller is in `src/city/city.gd`,
another build's file, and the atlas library it is handed already carries the page lines beside
which its line sits. A `RunTrace` on `AtlasLibrary`: the library is on the data layer, below the
model layer `RunTrace` is on, so it holds a `Callable`. A log over no folder kept in memory for the
suites: the ruling above.

**Open to overturn.** The recording log extends the real one, since the observer and
`main.use_run_log()` are typed against it, so it carries the real log's picture schedule and burst
recorder unused. `tests/test_telemetry.gd` still drives the observer on the real log, as it did.
`SceneryWater`'s suite checks the surface handed no library makes one, and watches the page lines
of a surface handed a library of the test's own, since a library a node makes for itself writes
nowhere.
