# The carried baby's zzz sits just over her head (inbox #778, 2026-10-18)

Carrying, `Stroller.baby_cue_lift()` is now `FIGURE_HEIGHT + (BABY_CUE_LIFT - PRAM_ART_HEIGHT)` =
52px above her feet (was 82px, a pram's height more). Every carrying sprite's opaque top, measured
from the baked atlas for both parents, all five views and all three gait frames, is 45px (mother)
or 46px (father) above the anchor, so 52px clears the tallest by 6px.

- `stills-before-after.png`: the carried parent asleep-baby cue on each of the eight facings, in
  order north, north-east, east, south-east, south, south-west, west, north-west. Top row main
  (`eb5506ed`), bottom row this change. Drawn by `stills-harness.gd.txt`, a throwaway scene script
  that instantiates eight carrying rigs; it is not part of the game.
- `turn-before-burst.png`, `turn-after-burst.png`: a carried walk west, south, east, north, west
  (smooth turns), 5 frames a second, cropped around her, rendered with `tools/trailer.sh --shot`
  from `turn-recipe.json` (the chase recipe without the guards; the first frames are the shot's
  fade in from black).
