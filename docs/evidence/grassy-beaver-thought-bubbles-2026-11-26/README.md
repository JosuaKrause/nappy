# The thought bubbles in play, day 1

**Claim.** The bubble goes up over her in the game: the way to the park at the start, the
tutorial route when she walks off it, the zebra crossing when she stands on the carriageway away
from one. Four frames of each burst (the 1st, 10th, 20th and 30th of 36) and its `burst.json`
are kept.

**Limits.** The walk-wide-of-the-noise bubble is not captured: no noise source with a caret stood on
the walks. These are a rig's walks under `--invincible`, so the run log's clock does not move; the
bubbles' timing is read from `burst.json`. The icons are the simple set
(`HintKind.ICON_SET_SUFFIX`).

**Source.** `origin/main` at f6a6236ab plus the branch's changes, windowed, seed 4242, day 1.

- `way_to_park/`: `tools/shot.sh out.png 14 --seed 4242 --invincible --walk 4@90@6@180@ --press snapshot_burst 4`
- `back_to_route/`: `tools/shot.sh out.png 16 --seed 4242 --invincible --walk 3@90@6@0@ --press snapshot_burst 8`, north off the route
- `use_zebra/`: `tools/shot.sh out.png 14 --seed 4242 --invincible --walk 1@180@ --press snapshot_burst 5`, south into the carriageway
