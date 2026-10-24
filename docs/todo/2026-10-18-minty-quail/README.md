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

## Order

Each step leaves the game working and is its own PR, reviewed on its own. **A step is done at test
parity**: every existing test passes, changed only as far as the code it reaches moved, or converted
early to injected fakes and public APIs (`tests-public-seams.md`); nothing is remeasured per step. The player: "let's do remeasuring at the very end and not get blocked by it
during the refactor", "for the refactor test parity is enough" (inbox #813 in curly-moose).

1. `world-passability.md`: what is left of the world layer's passability.
2. `events-composed.md` and `shared-components.md`.
3. `main-and-state.md` and `tuning.md`, alongside the extractions they serve.
4. `comments.md` and `likely-bugs.md`: in whichever PR touches the code.
5. `tests-public-seams.md`: the tests rewritten with dependency injection and through public APIs.
6. **Remeasuring**, once, after the last item: winnability across seeds, route costs, the cost
   table, GoatCounter's names and counts against `docs/stats/`, the run log for the same run against
   one from before the refactor, and pictures of every behavior a step changed on purpose. Each
   step's record lists what its change needs remeasured.

The PR that closes this entry rewrites **orchestrating**'s "Code is designed by layer", whose
proposal paragraph refers to this entry, and **removes its exception for downy-tapir's minimal
escape fix**: "the exception only holds until the refactor -- I don't want a month from now hear that
the exception still stands" (minty-lemur #799). The escape city's placement runs on the day's
scheduler and that fix's `build_finale` is gone (minty-quail-8), so the exception covers no code.
