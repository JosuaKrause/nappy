## M171, the contract closed — built 2026-09-20

The milestone's last item, pull request #257.

**Deleted.** `TextureAtlas`, `TextureResolver`, `AtlasPhaseTrace`, `main.gd`'s per-frame
`collect_ready()` pump and `_warm_the_pictures()`, the frame trace's `picture_loads` and
`atlases_collected` counters and the spike line's two, and `--svg` and `?svg=1` wherever they
were parsed, documented or tested. `_warm_the_halo_shader()` survives and both boot paths call
it. `sprites.gd`'s `resolve()` call was already a no-op, since every caller hands it an
`AtlasTexture` with an empty `resource_path`. The boot loses `[Main] 156 pictures warmed in
176–180 ms`; the nine resident pages take 14–18 ms, as before.

**The run log** writes one `texture` line per page, not per call: `atlas page '<group>' loaded
in the <moment>: <ms> ms, <W> x <H>` with the moment `startup`, `day brief`, `escape` or
`OUTSIDE`, and `atlas page '<group>' released after <s> s: <W> x <H>`. An `acquire()` of a
resident page and a release above the last write nothing. The spike line gained no replacement
counter: a page cannot arrive late, and a read outside a window is an engine error with its own
line. M159's atlas-measurement item is rewritten against these.

**The move.** Eleven families and the six identity images went to `art/` by `git mv`, in a
commit holding nothing else; `art/` carries a `.gdignore`, and 776 `.import` sidecars were
deleted. Region names did not change. What stays under `assets/` is what the engine loads: the
baked pages and `regions.json`, `membership.json` (its members rewritten to `art/…`),
`ground_tileset.tres`, the halo shader, and `assets/ground_layers.json` — the ground's
composition recipe, moved out of the illustrated tree because `GroundLayers` reads it at every
build, with the web preset's `include_filter` naming the new path. Nothing in the engine loads
an identity image; the application icon is the root's `icon.svg`. `README.md` points at
`art/logo.png` and the deploy copies `art/social-card.png`.

**The consumers' picture constants are baked region names** — `"events/cat_running"` — 368 of
them in four files, rewritten by a script asserting per-file counts. `AtlasLibrary.
region_name_for()` survives as the bake's rule. Every reference to an old family path moved;
the count outside history is nought.

**The audit is fatal, and a page outliving its group is caught three ways.** The player found
`assets/atlases/baked/head_indicators.png` on disk after that group was folded into `ui`
([PLAYTEST-110](../playtests/PLAYTEST-110.md)): the bake only ever wrote pages, `--check` compared
source hashes, and an imported folder exports whatever is in it. The bake now deletes a page no
group names, `--check` reports one by name as stale, and `tools/audit-pck.sh` reports one and
fails on it under `--fatal`, which `tools/export-web.sh` passes. A real export reports no
member and no unnamed page in the pack.

**A suite that was wrong about the SVG bake.** `tests/test_visuals.gd` run against a
`tools/bake-atlases.sh --svg` tree — which `tools/test.sh` cannot reach, since it re-bakes —
failed 27 checks, all the suite's: three of its rules are the illustrated transfer's
registration contract and are false of the authored vectors (an authored layer is a whole
opaque tile, `props/garbage_sack` leaves a pixel under its feet, `rig/pram_side` sits two
pixels left of centre). Those three are asked of the default bake only, and the suite prints a
line when they are not asked. `tests/probes/m108_event_vehicles_sheet.gd` had been broken since
#255 and takes a region name like its siblings.

**Evidence.** The escape interior is pixel-identical to `origin/main`; the day-12 street
differs only by a car, three walkers and the live readout, a different frame of a running
simulation.

**Frozen, not fixed.** Scripts under `docs/evidence/` that name a moved path or a deleted
class would fail if run and are left as records: `layered-ground-layout-2026-09-12/
layout_capture.gd`, `shared-damage-2026-09-12/damage_atlas_review.gd`,
`sidewalk-layout-review-2026-09-12/layout_capture.gd`, and `comic-identity-2026-09-12/
register-identity.py` with its `registration.json`.

**Open to overturn.** The identity images sit loose at `art/`'s root, as they did at
`assets/`'s, where `art/identity/` was the alternative; `membership.json` stays under
`assets/`.
