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
- `mark-up-a-vs-b.png`: carrying with a danger mark up (`alert` on the left, the wider `alert_close`
  on the right), mother above and father below, the cue's two possible steps: A as built (34px) and
  B a wider step (56px). The step is the same on every facing, so one facing (east) shows it. B was
  drawn from a temporary local edit of `BABY_CUE_ASIDE`; no code carries it. Drawn by
  `mark-harness.gd.txt`.
