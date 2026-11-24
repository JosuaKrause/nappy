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

**The design review's items are closed.** The player had the refactor's design reviewed ("have a fable
agent review the design of the refactor", inbox #1265 in olive-ferret); its records are the ones named
polite-tapir (`tools/decisions.sh polite-tapir`), and this entry's remeasure (step 4 below) comes after the last
item here.

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
   APIs, real frames) and the places a test still reaches past it, with `tests-unseen-reads.md`
   for what its count cannot see. `tests-own-class-members.md` holds the members only their own
   class and the tests use, which become internal.
3. **The rest goes module by module, in
   tracks that run in parallel** (inbox #1268 in olive-ferret). The design review found that the
   order converted the tests before the event code they read, so the largest group of suites
   would be mocked against fields and redone; shown its suggestion to go module by module, the
   player: "yeah module by module makes sense and can be parallelized". Within a module: its
   dead code (`dead-code-sweep.md`), its interface and field reads, its receivers typed with
   them (`tools/check_field_reads.py` holds both, its list `tools/field_reads.txt` empty), then
   its suites, one module each and all typed. The player approved going module by module in
   parallel; the tracks are the design review's worked-out detail:
   - **The design review's tracks are closed**, their records the ones named polite-tapir; the
     baseline readings are listed under step 4.
   - **The modules that do not wait for the events:** telemetry; the atlas and the scenery; the
     crowd; the city map. The city scene waits for no other item. **Every file under `src/` is typed and
     no read of another class's field is listed under it**: `tools/check_field_reads.py` fails a
     new read, and `tools/field_reads.txt` is empty. What the check cannot see is stated in its
     `--help`.
   - **The city scene's lane still to come**, from
     `.claude/briefs/designs/minty-quail-city-scene-pass.md` (C7): `City.run`, `trace` and `atlas`
     become private (three renames in `city.gd`); `tests/test_atlas_boot.gd`'s sweep
     (`node.get("atlas")` over every node of a booted `main`) then asks the city's library through
     its method, since a private field leaves the city out of the loop silently while its holder
     count still passes on `Prop` and `PosterWalls`.
   - **The events' interface is built**: a body, a hold on her, a lethal field, a pursuit and the
     rest are parts an event has, and every caller asks through methods (`docs/EVENTS.md`
     describes it; its records are listed by `tools/decisions.sh minty-quail`). What is left of
     its track is `re-derived-cases.md`, a scene's walk working out its route tree and locations
     again, and `system-map.md` once the redesign is complete.
4. **Remeasuring**, once, after the last item: winnability across seeds, route costs, the cost
   table, GoatCounter's names and counts against `docs/stats/`, the run log for the same run against
   one from before the refactor, and pictures of every behavior a step changed on purpose. Each
   step's record lists what its change needs remeasured. That includes the crowd tick, measured
   about 4.5% slower once the walker and the car share a mover base the crowd member extends
   (minty-quail-16), where the player chose "let's eat the cost for now and think about optimizing
   later" (minty-dolphin #852): the step measures it again and says whether optimizing it is
   worth an entry of its own. It measures streaming's tick (`EventStreaming.stream_around()`, the events' loop with
   the most turns) again too: row 3a's plan questions cost it about 60 µs a tick (record minty-quail-cozy-stork) and
   streaming's own table of state per plan about 25 to 50 µs more (#1598's measurement, on its pull request), and the
   step says whether a cheaper lookup is worth an entry of its own. It also reruns `tests/probes/placement_rows.gd` on main and on the
   refactor's head and compares the two with `tools/compare-placement-rows.py`, which applies the
   rule the record grassy-magpie states (that record carries the output of the hand-run script it
   replaced, with that step's own list). The tool refuses a log line of a day outside 1 to
   14, and both probes plan a day the way `DayPlanner` does: each day's closures, holds, region wall and seals,
   the seals and the wall's bodies handed in as standing (the record minty-quail-tiny-magpie; placement step 3c
   moved main's own route-adjacent walls from 30.54 to 19.41 a city a day).

   **One more thing is done before the remeasure runs** (pull request 1683's review found it): both placement
   probes, `tests/probes/placement_rows.gd` and `tests/probes/placement_view_mix.gd`, plan with the heated roadblock
   row, `EventCatalogue.heated(EventCatalogue.by_id(guarded), progress)`, as `DayPlanner` does, where they hand the
   plain `EventCatalogue.by_id(guarded)`; they refresh the street trees (`refresh_street_trees()`) after the day's seals
   are planned, as the game's own path does, which neither does; and they hold their shared planning block once, in a
   helper both use (under `tests/probes/`), where each carries a copy.

   The "before" it compares with is the design review's baseline readings in
   `docs/evidence/minty-quail-baseline-2026-11-09/`: a first column of `v0.29.0` beside a mid-refactor `main`
   (the record minty-quail-mossy-raven), a third column with placement closed (the record polite-tapir-velvet-heron), and a
   fourth after the events' field-read conversion (the record polite-tapir-crisp-heron). Nothing is judged in the
   readings: a number that moved is listed here for this remeasure, and no step waits on one. Four
   lists of numbers are left for it:

   - **What moved after the events' field-read conversion** (the fourth column against the third, the record
     polite-tapir-crisp-heron): dawn planning (a copy of today's `placement_rows.gd` with the third column's
     timers, set against the third column's own copy) inside `build_day()` 51.6 s to 44.1 s, inside
     `draw_every_unit()` 345.6 to 334.3, the whole probe 568.6 to 505.2; the crowd tick's mean whole-mode
     median about 2,466 µs to 2,351 µs; the frame profile's callback interval with `--invincible` 4.9 ms to 4.0
     profiled and 7.5 to 6.3 with the profiler off; `test_acts`'s checks 349 to 45 (its sweep holds scripted rows
     only) and `test_finale`'s 9,464 to 9,463; the unmodified frame-profile launcher's six runs all rejected by
     the analyzer (an 8.3 ms callback interval), not looked into.
   - **The escape's mix and walks** (placement by construction's switch of the escape city's walk to the unit draw, the record
     polite-tapir-coral-badger;
     `tests/probes/escape_winnable.gd`, 24 seeds): main before the switch planned 0.66 dangers a street and 34%
     of streets with none (trucks 167, explosions 193, vans 91, roadblocks 44), and walked out to the tunnel on 13
     walks and to the bridge on 10; after it, 0.66 and 34% (181, 178, 89, 46), 12 and 10.
   - **Streaming's loop over every plan**: `EventStreaming.stream_around()`, which row 3b's design asked to be
     measured and which was not (the record minty-quail-gray-koala; the paragraph above says what this step
     measures of it).
   - **The events' interface's timing readings**: the design asked each of 2a's and 2b's pull
     requests to time five probes, main and the branch side by side in two worktrees run at the
     same time, the totals over a probe's configurations compared, since one configuration alone
     moves between rounds (the record minty-quail-brisk-lark):
     `tests/probes/m159_tick_sweep_events_cost.gd` (the baby's sweep and the events' physics
     step), `excitement_fingerprint.gd` (its `XF_COST` line, the halo's frame),
     `calm_pelican_fields_layer_cost.gd`, `m159_crowd_tick_cost.gd` (the control) and
     `look_fingerprint.gd` (its `LK_COST` line). Four of 2a's seven pull requests hold theirs in
     their records (minty-quail-velvet-owl, -olive-finch, -tiny-alpaca and -tawny-swan); 2a's last
     three (-striped-hawk, -striped-magpie and -silver-marmot) and 2b's six took none. Owed is one
     reading of the probes from the merge of -tawny-swan to the merge of -calm-egret, and of
     `LK_COST` from the merge of -polite-newt, the probe's own, to -calm-egret. It holds other
     tracks' merges too, so what it shows is listed and judged by no step (the player: "get the
     clean design first no matter the cost", inbox #1278 in olive-ferret).

**The entry's list is frozen** (inbox #1268 in olive-ferret). The design review found that items had been added
to this entry through three weeks with no stated end; shown "The entry has no stated end", the
player: "also good points". *Read as, the orchestrator's, open to the player's correction:* the
entry is done when the items in this folder are gone and the remeasure is taken, which comes after
the design review's items too; a defect found in a pull request of this entry is fixed in that pull request,
and anything else found from here on is filed as an entry of its own after this one, never as a new
item here. `tests-public-seams.md`'s open list holds test gaps, which add tests and
refactor nothing and move to such an entry when this one closes.

The PR that closes this entry rewrites **designing-classes**'s "Code is designed by layer",
whose layering paragraph and closing list of proposals refer to this entry, **rewrites its
paragraph "Two lists hold..."** (both lists are empty: no read of another class's field is
listed in `tools/field_reads.txt` and no file carries the opt-out line, so the paragraph
describes a conversion that is over), and **removes its exception for downy-tapir's minimal
escape fix**: "the exception only holds until the refactor -- I don't want a month from now hear
that the exception still stands" (minty-lemur #799). The escape city's placement runs on the
day's scheduler and that fix's `build_finale` is gone (minty-quail-8), so the exception covers
no code.
