# dappled-egret — The car crash's halo is painted behind its cars · 2026-10-11


[azure-koala](../playtests/2026-10-07-azure-koala.md), finding 2, inbox #601:

> car accident has halo drawn on top

**It was painter order, not an offset silhouette.** The crash's visible scene is `EventScenery`
layers built in `EventInstance._ready()`; its rim is an `EntityHalo` built later, when
`ExcitementHalo` first picks the crash. Both are `show_behind_parent` children of the instance, and
such siblings paint in tree order, so the rim added last painted over the cars as a flat blob,
against [M89](2026-09-07-M89-a-halo-says-what-is-costing-her.md)'s silhouette behind its picture.
The rim traces the same picture, so it was never displaced.

**`EventInstance._build_halo()` moves the rim to child index 0**, ahead of the scenery, for every
instance that has both (the burst main as well as the crash). What lights the halo and the crash's
collision shapes ([M118](2026-09-12-M118-a-car-crash-is-solid-only-where-the-cars-are.md)) are
unchanged. `tests/test_halo_behind.gd` checks the rim's index is below the scenery's on both street
axes, and fails without the move. The stills,
[halo-behind-2026-10-11](../evidence/halo-behind-2026-10-11/), on seed 4242, day 3, a forced crash,
with the rim lit for the capture only, show the blob before and the outline behind the cars after.

*Seen, not chosen:* the crash's side bystanders are part of its picture, so they now show their own
rim where the blob used to cover them.
