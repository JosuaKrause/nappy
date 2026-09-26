## M109 — The complete generated catalogue uses comic drawings — 2026-09-12

The PLAYTEST-64 correction was applied to all 95 existing PNG assets: 59 outdoor tiles,
25 mother/stroller views and frames, seven garbage/litter props and four identity/export
images. The player then said "yes I like the new versions", followed by "of the tiles".
Tile appearance is approved; this does not approve the other families or authorize a PR merge.
The remaining visual checks are in REVIEW, including moving across terrain joins.

The mother and stroller were redrawn as one directional family. Review rejected wide,
childlike poses whose uniform canvas fit made the mother shrink when turning. The selected
adult proportions and compact poses keep every mother frame at 46 pixels of visible height,
with widths of 19–24 pixels; stroller views remain 30 pixels tall. Generated silhouettes and
transparent gaps replace SVG-alpha stamping while native canvases and bottom anchors stay fixed.
Background correction replaces neutral-color erasure so gray and cream artwork survives.
The selected atlases, source inputs, exact prompts, measurements and byte-reproducible
registration are in `docs/evidence/comic-rig-2026-09-12/`.

The integrated root checkout passed import/boot, 190,888 focused checks across visuals,
stroller, presentation mode, orientation, event views, blocks and city decay, and 497 forced-SVG
visual checks. These were partial runs; CI owns the full suite. Static comparison sheets cover
the new art, but the rig assembly is approximate and does not establish live hand-to-handle
contact or gait quality. The two earlier gameplay captures show the initial tile candidate,
not this final redraw. All files are in the player's main checkout and the PR remains open.
