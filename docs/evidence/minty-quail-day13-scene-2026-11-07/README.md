# Day 13's scene after the redraft (minty-quail, #1169)

**What it shows.** `scene-recipes/task-13-roadblock.json`, redrafted in #1169. The task's
roadblock is no longer the one the director used to add on the 576px circle's edge. It is an
authored roadblock that stands as one the day placed, on the side street off her route: tile
(73,65), 615px from the chalk mark. The stretch now includes that side street.

- `task-13-roadblock-start.png`: a tenth of a second in. She starts 5 tiles west of the unread
  mark, on her street, with the mark's alley north of her.
- `task-13-roadblock-at-capture.png`: at the recipe's `capture_at` (7.6s). She has read the mark
  and walks west along her street. The red arrow points up the side street at the roadblock, and
  its guard stands beyond it, on the far side from the way she comes. The task's line reads "Walk
  up to the roadblock".
- `task-13-roadblock-capture.json`: the capture run's manifest. It holds the observations every
  scene run checks, and all of them pass.

**Limits.** These stills show the scene's composition, the roadblock's place and the arrow at two
moments. They do not show:
- the walk into the band, which the headless run's observations hold (`task` done at tick 300);
- the day's own placement: a scene plans no day of its own, so the roadblock is authored.

**Provenance.**
- Source revision `ffb9754f7` (branch `feature-minty-quail-day-events-after-dawn`).
- Command: `tools/scene-recipes.sh --recipe scene-recipes/task-13-roadblock.json --screenshots
  --output <scratch>`, which runs `tools/shot.sh` at the defaults (1280x720) and the recipe's own
  seed (11) and city context (1917501).
- Kept: the two stills, and the capture manifest for the second.
- Left in scratch: the logs and the start still's manifest, which add nothing to what the stills
  show.
