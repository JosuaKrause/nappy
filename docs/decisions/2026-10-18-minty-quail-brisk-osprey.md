# minty-quail — The scheduler's verdicts are held by a store each walk siting is handed, and no static is left in it (hidden statics) · 2026-11-05

minty-quail's `hidden-statics.md`, its last open part, which closes the item; and
`tests/test_siting_judges_once.gd` of `tests-public-seams.md`. The domain model:
`src/events/event_scheduler.gd`.

**Built.** The verdicts the scheduler's placement loop keeps, so it judges each candidate once, are
held by an `EventScheduler.Verdicts`, a small store with `of()`, `keep()` and `forget()`. Every
`WalkSiting` is handed one where it is built: the four the events ahead build and the two the
resistance happenings build each hand a store of their own, since a siting drops its verdicts before
every ask outside a director's look and a shared store would keep nothing. The static judgement
counter is gone, and so is the walk siting's public count of looks begun. The judge-once suite
hands a counting store through the same constructor, and a store that keeps nothing as the reference
a kept verdict must agree with, and sees the director's looks through its spy siting's
`begin_look()`; `test_walk_siting_spec` reads in the events ahead's source that each of its four
sitings is handed a store of its own, since two of them cannot be observed from outside. Placement
fingerprints over the same seeds are unchanged.

**Where the item leaves the statics.** The street lattice is a `StreetNetwork` each `CityMap` holds;
the torn posters a `PosterArt` that `main` keeps and hands down; what outlives a scene reload (the
controls choice, the held-restart stamp, the save symbol's home, the frame record, the checkpoint
carry, the ground recipe, the save) one `Sitting` that `main` parks across the reload; the run
configuration `main`; the drawing state what it describes; the atlas library an instance the
`Sitting` holds over a region table read once per process. The statics left (`rg -n '^\s*static var'
src` lists them) are constants or pure memos built once and never written by a caller: the `Mover`
filters and `Mover._shared`, `CityMap`'s tile tables, `EntityHalo._shared_material`, the baked
atlas region table `AtlasTable._baked`, the event catalogue's tables and derived rows, the warning
sizes `EventFootprints` reads off the baked pictures and their guard, `ResistanceSteps._all`, the
empty bird list and open walls.

**Choices, open to overturn.** A verdict store rather than a bare counter, since a counter alone
cannot show that a kept verdict answers what judging every try answers without a test-only door; a
required constructor parameter that every game caller fills, rather than a default only a test
overrides (the builder's and the orchestrator's calls). `WalkSiting.offers_worked_out` is still a
public counter only the judge-once suite reads, which wants the offer handed in.
