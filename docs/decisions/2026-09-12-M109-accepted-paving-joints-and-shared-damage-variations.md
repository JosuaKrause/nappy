## M109 — Accepted paving joints and shared damage variations — 2026-09-12

PLAYTEST-65 asks for boundary joints on every rectangular floor and selects the sidewalk material
from PR #138. The registered sidewalk, quiet square, precinct, courtyard, alley and stoop copy
their existing interior joint pixels to the appropriate tile boundaries, preserving staggered
courses. The plaza already has complete joints and keeps its pixels. Matching authored SVGs
express the same closed slab layout. The player reviewed the main checkout and accepted the
family: “the tiles look good we can use them.” The paving and quiet-square review items close.

The paving recipe freezes immutable material inputs and records exact source-to-destination
pixel copies for each accepted 32×32 output, plus hashes and native/enlarged repeat reviews.
An intermediate agent input set was contaminated by edited runtime outputs and was discarded.
The final recipe recovers the reviewed arrangement from immutable originals; its frozen rebuild
is byte-identical and verifies against all seven installed tiles and the sidewalk/alley layer bases.
The separate layer assembly recipe freezes these final registered floors so regeneration cannot
restore incomplete boundary joints. Original material inputs remain separate for damage extraction.

Damage uses six shared variations per severity across road, sidewalk and alley. Existing source
IDs preserve their base and severity; city seed and cell select a stable common-pool variant.
Six sidewalk-origin stencils remove residual pale slab-grid pixels while retaining dark fissures
and green growth at crossings. A stale color variable in an intermediate cleanup clipped the
foreground and was corrected before integration. Runtime atlas strips review all nine
surface/severity combinations. Unwanted baked PR composites are removed from frozen runtime
targets too, while accepted original damage artwork remains available to reproduce the stencils.

The combined layer bundle rebuilds byte-for-byte and verifies every installed base, component
and source-ID contract. Root import/boot, focused ground-layers, visuals and presentation-mode
suites in PNG and SVG modes pass. Full-suite verification remains CI's merge-result gate.
