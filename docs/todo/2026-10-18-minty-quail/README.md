priority: now

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

**Nothing else is worked on until the refactor is done** (inbox #1210 in gentle-owl): work built on the code before
the refactor is done twice. Work on how the project is worked on (a skill, `CLAUDE.md`, a rule, a
hook, a general project script, or anything else of that kind) is the exception and goes first
(inbox #1305 in grassy-trout). *Read as, open to the player's correction:* a pull request another entry
already has stays open as a draft and resumes after the refactor closes.

**The design review's items are polite-tapir** (the refactor's design review: placement drawn as she walks, the
event scheduler broken up, one start for every kind of day, the standing layer breaks, the baseline measurements),
an entry of their own that carries `fable-only: true` where this entry does not (inbox #1387 in mossy-bunny).
*Read as, the filer's, open to the player's correction:* the review was of the refactor's design ("have a fable
agent review the design of the refactor", inbox #1265 in olive-ferret), so its items are the refactor's work, the
refactor is this entry and polite-tapir, and the rule above (inbox #1210 in gentle-owl) covers both; the two are
worked side by side, their items interleaved as each item says; neither waits for the other to start, and this entry's remeasure
(step 4 below) comes after the last item of both.

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
   layer contract, the scene nodes that draw the world's own ground and furniture, the ground's
   picture builder, and the halo a body draws round itself with its rim.
4. **Simulation:** actors and events composed from shared parts; they report what happens as domain
   events and never call the UI, the run log, GoatCounter or dev code.
5. **Run flow:** a run is a sequence of day specs (fourteen days, the building, the city); one
   controller starts and finishes a spec.
6. **Observers and the view, siblings at one level** (the player's "let's make A siblings",
   inbox #904 in freckled-moose): the observers are GoatCounter (`VisitCounter`), the run log (`Telemetry`), the
   save and the debug readouts; the view is the screen's own furniture, the HUD, the screens, the
   badges, the halo's lighting and the controls. Both subscribe to domain events, nothing below calls them
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
   module: its dead code (`dead-code-sweep.md`), its standing layer breaks (the design review's,
   below), its interface and field reads, its receivers typed with them or by a typing pass ahead
   of them (`field-reads.md`), then its suites (`tests-one-module.md`), typed already but for two
   files (`typed-everywhere.md`). The player approved going
   module by module in parallel; the tracks are the design review's worked-out detail:
   - **The design review's tracks are the entry polite-tapir** (placement drawn as she walks with
     the event scheduler's breakup interleaved, one start for every kind of day, the standing layer
     breaks, the baseline readings); its README gives their order and where each meets the items
     here.
   - **Run flow:** `city-hand-ins.md`'s third pull request, which settles who builds the events and
     the crowd together with the design review's one start for every kind of day.
   - **The modules that do not wait for the events:** telemetry; the atlas and the scenery; the
     crowd; the city map. The city scene and the conversion of the run's parts (`field-reads.md`,
     "A run's parts") follow the third hand-ins pull request. **Every file under `src/` is typed
     but those `field-reads.md` lists, each with what it waits for, under "What is left of the
     typing".** The view (`src/ui/`), the building (`src/interior/`, `src/finale/`), the run's
     parts, the routes, the resistance and the developer's rigs (`src/dev/`) are typed ahead of
     their conversion, and what is left of them is their reads of other classes' fields, which the
     records of their typing list by class: among them the building's
     write of `WorldMap.world`, which goes with the map interface's world half (the design
     review's standing breaks), the reads through the run's parts, which wait with those parts,
     and the developer's rigs' reads of an event, row 3c of `event-interface.md`.
   - **Tools:** `typed-everywhere.md`: code is
     typed wherever the language can type it, the tests included.
     `method-without-parentheses.md`, a typed receiver's method named without its parentheses
     being reported, is the orchestrator's proposal and waits for no other item.
   - **The events' interface** (`event-interface.md`: a body, a hold on her, a lethal field, a
     pursuit and the rest as parts an event has, and every caller asking through methods). Its
     first steps, the callers outside the events folder and the live event's own behaviours and
     looks, run beside the placement track; the dawn, the event manager's parts, the resistance
     and the scene recipes follow placement and the scheduler's breakup; then a row written as its
     parts, and the events' suites (what is left of `re-derived-cases.md`, the scene recipes' own ground scans, closes with
     polite-tapir's placement or after it);
     `system-map.md` once the redesign is complete.
4. **Remeasuring**, once, after the last item: winnability across seeds, route costs, the cost
   table, GoatCounter's names and counts against `docs/stats/`, the run log for the same run against
   one from before the refactor, and pictures of every behavior a step changed on purpose. Each
   step's record lists what its change needs remeasured. That includes the crowd tick, measured
   about 4.5% slower once the walker and the car share a mover base the crowd member extends
   (minty-quail-16), where the player chose "let's eat the cost for now and think about optimizing
   later" (minty-dolphin #852): the step measures it again and says whether optimizing it is
   worth an entry of its own. It also reruns `tests/probes/placement_rows.gd` on main and on the
   refactor's head and compares the two with `tools/compare-placement-rows.py`, which applies the
   rule the record grassy-magpie states (that record carries the output of the hand-run script it
   replaced, with that step's own list). Before it does, the tool is made to refuse a log line of
   a day outside 1 to 14, which it reads today though `placement_rows.gd` cannot print one, and both
   probes are settled
   on `DayPlanner`'s planning: `placement_rows.gd` plans each day's closures, region wall and seals
   and hands the seals and the wall's bodies in as standing since placement step 3c, which moved
   main's own route-adjacent walls from 30.54 to 19.41 a city a day, and
   `tests/probes/placement_view_mix.gd`, which `VIEW_SHARES` is measured with, still plans no
   closures or seals.

   The "before" it compares with is the design review's baseline readings, on `v0.29.0`
   (polite-tapir's `baseline-measurements.md`).

**The entry's list is frozen** (inbox #1268 in olive-ferret). The design review found that items had been added
to this entry through three weeks with no stated end; shown "The entry has no stated end", the
player: "also good points". *Read as, the orchestrator's, open to the player's correction:* the
entry is done when the items in this folder are gone and the remeasure is taken, which comes after
the design review's items too, the decision on each standing break among them; a defect found in a pull request of this entry is fixed in that pull request,
and anything else found from here on is filed as an entry of its own after this one, never as a new
item here. `tests-public-seams.md`'s open list holds two kinds: test gaps, which add tests and
refactor nothing and move to such an entry when this one closes; and members the game does not
need, `PlanBuilder._cross_street_path` (which no catalogue row uses) and those only tests read
(`EventsAhead.walk_siting()`, `WalkSiting.offers_worked_out`, `RouteLines.routes()`,
`TouchControls._FOCUS_KNOB_OFFSET` and `_FOCUS_KNOB_RADIUS`), whose removal or game
reader is a change to `src/`, a refactor rather than a test gap.

The PR that closes this entry rewrites **designing-classes**'s "Code is designed by layer", whose
layering paragraph and closing list of proposals refer to this entry, and **removes its exception for downy-tapir's minimal
escape fix**: "the exception only holds until the refactor -- I don't want a month from now hear that
the exception still stands" (minty-lemur #799). The escape city's placement runs on the day's
scheduler and that fix's `build_finale` is gone (minty-quail-8), so the exception covers no code.
