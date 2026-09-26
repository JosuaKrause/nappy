## M109 — Forest ground and runtime damage assets — 2026-09-12

PLAYTEST-65 re-reports noisy grass and provides a running-game screenshot from seed 3339657913.
The screenshot matches `forest.png`, source 17, rather than park grass, source 12. Both files
are unchanged by the sidewalk selection; the omission is in the layer binding. Forest now uses
the same soft, rotationally averaged grass base and sparse clump atlas as parks. Its source ID,
calm behavior, tree placement and other gameplay properties remain unchanged.

`docs/evidence/grass-runtime-2026-09-12/` boots the actual Main scene without overriding the
texture mode and records the live Ground node's atlas and cells. In the shared checkout, the
reported seed loads 256×32 park and forest atlases and selects varied cells around the reported
location. The photographed player cell (42,26) is precinct paving; the wooded cells to its west
are source 17. The root import/boot and runtime probe pass, and its ground-only crop shows the
soft forest surface. The complete player's run is retained under the dated session-capture
archive, including its screenshot, day map and run log.

The player also points out that baked crack-and-floor PNGs no longer belong in runtime assets.
All eighteen road, sidewalk and alley baked damage PNGs and their import sidecars are removed.
The accepted source drawings from 83a60d1522574714ce038dff3a607a536d800614 remain frozen inputs
to the stencils; redundant PR composites are deleted without a new archive, as explicitly asked.
Transparent components and authored SVG fallbacks remain. Import/boot, focused ground/visual
checks and lint pass with the baked family absent.
