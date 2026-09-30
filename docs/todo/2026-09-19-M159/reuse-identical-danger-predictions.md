**Investigate and remove repeated identical danger predictions.**

The player asks for the next hypothesis after the scenery-animation work, then asks "can you
add a todo item for that". The hypothesis is repeated future-threat calculations across halo
selection, redraw decisions and warnings. It is a candidate for reducing steady CPU work,
not an established cause of every remaining hitch. See
[Sunny lynx](../../playtests/2026-09-26-sunny-lynx.md) and the
[crowded-scene measurement report](../../evidence/m159-entity-performance-2026-09-26/README.md).

**Proposed, not yet a chosen implementation:** identify queries with identical inputs and share
their results within the frame. Read every caller before choosing a cache boundary: source
positions, velocities, age/phase, prediction horizon, player state and simulation updates can
change within a frame. A shared frame number alone does not prove the answers are interchangeable.
Reuse only demonstrably equivalent results; invalidate on relevant state changes. The
[classification-cache record](../../decisions/2026-09-19-M159.md) measures the separate work of
deriving event shape from its look; measure prediction reuse independently.

Retain deterministic equivalence checks for threat selection, projection results, warning timing,
halos and meter contributions, including phase transitions, movement and removal. Do not lower
query cadence, skip visible warnings or change gameplay to make the measurements smaller.

Measure the current branch first, with active/visible populations and duplicate-call counts.
Then retain repeated alternating before/after runs on the same crowded route, collector and equal
active windows, including profiler-disabled comparisons. Report reduced query work separately
from frame median/tail/max changes and diagnostic overhead. Native CPU gains do not establish
phone, browser or GPU improvements. Keep this work separate from lazy visual preparation and
from small-part scenery separation.
