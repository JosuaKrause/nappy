priority: now
fable-only: true

# minty-quail — One engine: the codebase refactored by layer, the escape a day spec · filed 2026-10-18


**The ask.** Told that the escape's building runs its events through its own runner and its city
places them through its own pipeline, the player: "there really should be no separate code for
escape", "unify the codebase", "having a separate way of placing events is okay but other things like
movement code or goatcounter etc should not", corrected to "no the *building* escape may keep its own
way of placing events *NOT* the city escape", then "all should be implemented through the regular
game engine's means" (minty-lemur #785). Asked to look at the codebase critically: "no, I want you to
have a critical look at the codebase", with the lens "separation of concerns, composability,
cohesion, coupling, architecture layering" (minty-lemur #785); then "file the findings as a refactor
ticket. be precise about it", to be done after downy-tapir ("then full refactor"), and "use
dependency injection to allow for more modular and testable code" (minty-lemur #794).

**Read as:** the escape is a day with special settings, run by the day's own code; only *what* the
building places and *where* is its own, and even that is expressed through the day's machinery. The
review below applies the five principles to the whole codebase, not only the escape.

**Nothing else is worked on until this entry is done** (inbox #1210 in gentle-owl): work built on the code before
the refactor is done twice. Work on how the project is worked on (a skill, `CLAUDE.md`, a rule, a
hook, a general project script, or anything else of that kind) is the exception and goes first
(inbox #1305). *Read as, open to the player's correction:* a pull request another entry
already has stays open as a draft and resumes after this entry closes.

## The review this entry files

A read-only review of `main` at v0.29.0 in four slices (the escape against the day; the events
system; the world and everything that moves; cross-cutting structure), by four review agents on
2026-10-18. Its findings, each with its place in the code, are the items in this folder. File and
line references are to v0.29.0; a builder re-reads them, since line numbers move.

## The layering the code is moved to

Each layer depends only on the ones below it; a lower layer never calls a higher one.

1. **Data and configuration:** the catalogue, balance numbers owned by the code that uses them, and
   one immutable run configuration resolved once at boot (dev flags included).
2. **Domain model:** pure state with no nodes and no I/O: the map and its one interface (`WorldMap`
   and its records, which the city's map and the building's both extend), plans, the run's
   sub-states. The map interface is the model's, the player's "let's use the improvement for B"
   (inbox #904 in freckled-moose): kept in the world, six model files would name a higher layer.
3. **World:** one navigator, passability, line of sight, adding an entity on a draw layer, one draw
   layer contract, and the scene nodes that draw the world's own ground and furniture.
4. **Simulation:** actors and events composed from shared parts; they report what happens as domain
   events and never call the UI, the run log, GoatCounter or dev code.
5. **Run flow:** a run is a sequence of day specs (fourteen days, the building, the city); one
   controller starts and finishes a spec.
6. **Observers and the view, siblings at one level** (the player's "let's make A siblings",
   inbox #904 in freckled-moose): the observers are GoatCounter (`VisitCounter`), the run log (`Telemetry`), the
   save and the debug readouts; the view is the screen's own furniture, the HUD, the screens, the
   badges, the halo and the controls. Both subscribe to domain events, nothing below calls them
   inline, and neither names the other.
7. **The composition root:** the main scene, which builds every layer and hands each what it needs,
   and the developer's rigs that drive the game from outside.

`tools/layer_map.py` is the list the check holds the code to; where this list and that file differ,
the file is what CI enforces and this list is corrected.

**Dependency injection throughout** (minty-lemur #794): a component receives what it depends on (its
map, navigator, configuration, clock, event sink) through its setup or constructor rather than
fetching it from an autoload, a scene-tree group or a static. Tests then hand it fakes instead of
patching statics or reaching into private fields. Every item below applies it to what it extracts.

**No legacy shape is kept** (minty-dolphin #852): the player, "Don't let legacy implementations
prevent you from establishing a clean design". Read as: an old path, a forwarder kept for an old
name so callers or tests need not change, or a rule that holds only "in practice" is replaced, not
kept beside the new design.

**The parts end up independent; sequential now is fine** (minty-dolphin #845): asked "why one PR at
a time? no way to partition work?", the player, "okay, let's do the refactor in a way that things
will ultimately be independent but it's okay if it needs to be sequential right now". Read as: the
refactor leaves its parts independent of each other, so later work on them can be split across
parallel agents; items that touch the same code now run one after another, and items already
independent run in parallel.

## Order

Each step leaves the game working and is its own PR, reviewed on its own. **A step is done at test
parity**: every existing test passes, changed only as far as the code it reaches moved, or converted
early to injected fakes and public APIs (`tests-public-seams.md`); nothing is remeasured per step. The player: "let's do remeasuring at the very end and not get blocked by it
during the refactor", "for the refactor test parity is enough" (inbox #813 in curly-moose).

1. `comments.md`: in whichever PR touches the code.
2. `tests-public-seams.md`: the rule the tests are written under (dependency injection, public
   APIs, real frames) and the places a test still reaches past it, with `tests-unseen-reads.md` for
   what its count cannot see. `tests-own-class-members.md` holds the
   members whose names collide with another class's.
3. **The rest goes module by module, in tracks that run in parallel** (inbox #1268 in olive-ferret). The design
   review found that the order converted the tests before the event code they read, so the largest
   group of suites would be mocked against fields and redone; shown its suggestion to go module by
   module, the player: "yeah module by module makes sense and can be parallelized". Within a
   module: its dead code (`dead-code-sweep.md`), its standing layer breaks
   (`standing-layer-breaks.md`), its interface and field reads with the receivers typed
   (`field-reads.md`), then its suites (`tests-one-module.md`). The player approved going
   module by module in parallel; the tracks are the design review's worked-out detail:
   - **Placement:** `placement-by-construction.md`'s
     steps with `scheduler-breakup.md` interleaved. Nothing else changes where events go until it
     is done (inbox #1185 in gentle-owl).
   - **Run flow:** `one-start-for-every-spec.md`'s start, then its signals and run log, then who
     builds the events and the crowd together with `city-hand-ins.md`'s third pull request.
   - **The modules that do not wait for the events:** telemetry; the player and the baby; the atlas
     and the scenery; the crowd; the city map. The city scene and the run's parts follow the third
     hand-ins pull request.
   - **Tools:** `baseline-measurements.md`, the field-read check made to see every read
     (`field-reads.md`), and then `typed-everywhere.md`: code is typed wherever the language can
     type it, the tests included (its scripted rewrite of the suites' runner is the orchestrator's
     proposal, marked so there). `method-without-parentheses.md`, a typed receiver's method named
     without its parentheses being reported, is the orchestrator's proposal; its first way, the naming
     rule for every conversion, helps only if it is written before the passes outside the events
     convert a yes-or-no field.
   - **The events' interface** (`event-interface.md`: a body, a hold on her, a lethal field, a
     pursuit and the rest as parts an event has, and every caller asking through methods). Its
     first steps, the callers outside the events folder and the live event's own behaviours and
     looks, run beside the placement track; the dawn, the event manager's parts, the resistance
     and the scene recipes follow placement and the scheduler's breakup; then a row written as its
     parts, and the events' suites (`re-derived-cases.md` closes with the scheduler's breakup);
     `system-map.md` once the redesign is complete.
4. **Remeasuring**, once, after the last item: winnability across seeds, route costs, the cost
   table, GoatCounter's names and counts against `docs/stats/`, the run log for the same run against
   one from before the refactor, and pictures of every behavior a step changed on purpose. Each
   step's record lists what its change needs remeasured. That includes the crowd tick, measured
   about 4.5% slower once the walker and the car share a mover base the crowd member extends
   (minty-quail-16), where the player chose "let's eat the cost for now and think about optimizing
   later" (minty-dolphin #852): the step measures it again and says whether optimizing it is
   worth an entry of its own. It also reruns `tests/probes/placement_rows.gd` on main and on the
   refactor's head, and turns the script that compares the two into a `tools/` entry point, since
   it is then a manual sequence done a second time (woolly-finch 23): the record grassy-magpie
   states its rule and carries the output of its first run. Before it does, both probes are settled
   on `DayPlanner`'s planning: `placement_rows.gd` plans each day's closures, region wall and seals
   and hands the seals and the wall's bodies in as standing since placement step 3c, which moved
   main's own route-adjacent walls from 30.54 to 19.41 a city a day, and
   `tests/probes/placement_view_mix.gd`, which `VIEW_SHARES` is measured with, still plans no
   closures or seals.

   **The "before" is captured while the old tree can still be measured** (inbox #1268 in olive-ferret). The design
   review found that no baseline commit is named, that no winnability or route-cost numbers from
   before the refactor are stored, and that a probe asks only what every tree has, so once the
   events' fields are behind methods no probe runs on both the old tree and the new; the player,
   shown that capturing them blocks nothing: "sure". *Read as, with the specifics proposed by the
   orchestrator and open to the player's correction:* the baseline is `v0.29.0`, the tree this
   entry's review read. `baseline-measurements.md` captures the before-numbers into
   `docs/evidence/` now, and takes one background reading of winnability and frame time when
   placement closes and one after the events' field-read conversion, so the end remeasure can say
   which half moved a number. None of it blocks a step or changes the player's "remeasuring at the
   very end" (inbox #813 in curly-moose): a reading is recorded, not judged.

**The entry's list is frozen** (inbox #1268 in olive-ferret). The design review found that items had been added
to this entry through three weeks with no stated end; shown "The entry has no stated end", the
player: "also good points". *Read as, the orchestrator's, open to the player's correction:* the
entry is done when the items in this folder are gone, the standing breaks are each decided, and the
remeasure is taken; a defect found in a pull request of this entry is fixed in that pull request,
and anything else found from here on is filed as an entry of its own after this one, never as a new
item here. The open test gaps `tests-public-seams.md` lists add tests and refactor nothing: they
move to such an entry when this one closes.

The PR that closes this entry rewrites **designing-classes**'s "Code is designed by layer", whose
layering paragraph and closing list of proposals refer to this entry, and **removes its exception for downy-tapir's minimal
escape fix**: "the exception only holds until the refactor -- I don't want a month from now hear that
the exception still stands" (minty-lemur #799). The escape city's placement runs on the day's
scheduler and that fix's `build_finale` is gone (minty-quail-8), so the exception covers no code.
