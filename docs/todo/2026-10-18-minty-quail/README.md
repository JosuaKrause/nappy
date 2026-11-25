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
polite-tapir (`tools/decisions.sh polite-tapir`), and this entry's remeasure (step 1 below) comes after the last
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
early to injected fakes and public APIs (**writing-tests**, "A test reaches the game the way the game does"); nothing is remeasured per step. The player: "let's do remeasuring at the very end and not get blocked by it
during the refactor", "for the refactor test parity is enough" (inbox #813 in curly-moose).

1. **Remeasuring**, once, after the last item: GoatCounter's counts against `docs/stats/` (read after a release, since the live site counts
   released builds only; owed as an entry of its own, filed when this entry closes), and pictures of every behavior a step
   changed on purpose, those the remeasure could not stage being owed in the entry azure-yak, "The pictures the end remeasure could not stage". Each
   step's record lists what its change needs remeasured. Nothing is judged in the readings: a number that
   moved is listed for this remeasure, and no step waits on one.

**The entry's list is frozen** (inbox #1268 in olive-ferret). The design review found that items had been added
to this entry through three weeks with no stated end; shown "The entry has no stated end", the
player: "also good points". *Read as, the orchestrator's, open to the player's correction:* the
entry is done when the items in this folder are gone and the remeasure is taken, which comes after
the design review's items too; a defect found in a pull request of this entry is fixed in that pull request,
and anything else found from here on is filed as an entry of its own after this one, never as a new
item here. The scene recipes' test gaps, which add tests and, for two of them, a small hand-in
in `src/dev`, are the entry snowy-plover (the scene recipes' untested corners), which waits for
this one.

The PR that closes this entry rewrites **designing-classes**'s "Code is designed by layer",
whose layering paragraph and closing list of proposals refer to this entry, **rewrites its
paragraph "Two lists hold..."** (both lists are empty: no read of another class's field is
listed in `tools/field_reads.txt` and no file carries the opt-out line, so the paragraph
describes a conversion that is over), and **removes its exception for downy-tapir's minimal
escape fix**: "the exception only holds until the refactor -- I don't want a month from now hear
that the exception still stands" (minty-lemur #799). The escape city's placement runs on the
day's scheduler and that fix's `build_finale` is gone (minty-quail-8), so the exception covers
no code.
