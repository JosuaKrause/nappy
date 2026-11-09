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

**Nothing else is worked on until this entry is done** (inbox #1210): work built on the code before
the refactor is done twice. *Read as, open to the player's correction:* a pull request another entry
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
2. **Domain model:** pure state with no nodes and no I/O: the map, plans, the run's sub-states.
3. **World:** one map interface (passability, line of sight, paths, tile conversions, adding an
   entity on a draw layer) that the city and the building both implement; one navigator; one draw
   layer contract.
4. **Simulation:** actors and events composed from shared parts; they report what happens as domain
   events and never call the UI, the run log, GoatCounter or dev code.
5. **Run flow:** a run is a sequence of day specs (fourteen days, the building, the city); one
   controller starts and finishes a spec.
6. **Observers:** the UI, GoatCounter (`VisitCounter`), the run log (`Telemetry`), the save and debug
   readouts subscribe to domain events; nothing calls them inline.

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
3. The redesign of derived state and hand-ins (inbox #1156, #1159 in gray-dolphin). The player's
   order (test-isolation-plan) is the hand-ins, then the conversion, then the cache; the rest of this
   order is the filer's proposal: `city-hand-ins.md`'s third pull request, then `tests-one-module.md`,
   `re-derived-cases.md` and `field-reads.md`; `dead-code-sweep.md` module by module beside them;
   `system-map.md` once the redesign is complete. `placement-by-construction.md` comes before any
   other change to where events go, since work on today's placement would be done twice (inbox #1185).
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

The PR that closes this entry rewrites **designing-classes**'s "Code is designed by layer", whose
proposal paragraph refers to this entry, and **removes its exception for downy-tapir's minimal
escape fix**: "the exception only holds until the refactor -- I don't want a month from now hear that
the exception still stands" (minty-lemur #799). The escape city's placement runs on the day's
scheduler and that fix's `build_finale` is gone (minty-quail-8), so the exception covers no code.
