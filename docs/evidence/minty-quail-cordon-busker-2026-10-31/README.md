# minty-quail — day 12's tape waits for a busker still standing for his escort

Evidence for the review of PR #891 (minty-quail, shared-components C2a), finding 3, 2026-10-31.

**Claim:** with a busker standing in the east edge row of day 12's park when the cordon starts, the
game's code before the fix tapes the east edge's stretch straight through him before his escort has
walked him out; with the fix the officer about to tape that stretch waits beside it, and the east
edge goes up behind him once he has been walked away.

**Run.** Three stills from runs of day 12's swing scene, each taken with
`tools/shot.sh` (1280x720, `--player-view --no-save`, `--recipe-mode scripted`, not
`--invincible`). The scene is `scene-recipes/task-12-swing.json` (run seed 11, city seed 1917501,
day 12) on the whole city (`{"scope":"full"}`, its stretch, context, actors, posters and route bag
dropped), with a busker at (1328, 3904): the middle of the park's east edge row, half a tile in
from the park's edge, whose tape line runs at x = 1332. The walk is
`1.95w0.7n0.7s5.71w3.13s0.35e0.4p0.5S0.8E25p`: she reaches the swing 12.6s in, by the run log, and
stands near it. `scratch-recipe.json` is that recipe as run.

- **Before**, the game's code at `4fc93a75` (main's cordon code; the probe commit of this PR, which
  changes nothing in play).
- **After**, the game's code at `a00d21c4` (this PR's head when the stills were taken, with the fix
  from `5f7cab25`).

Command, from each checkout:

    tools/shot.sh <out>.png <seconds> --recipe scratch-recipe.json --recipe-mode scripted \
        --player-view --no-save --recipe-manifest <out>.json

**Limit: the busker is not placed by the game's own rules.** Ordinary placement keeps a day's calm
ground clear, so the recipe runtime refuses a busker in a park. For these runs a scratch,
uncommitted edit to `src/dev/scene_recipe_runtime.gd` installed a busker row where the recipe put
it (`EventScheduler.Planned.new(def, at)` in place of the ordinary placement), and a scratch print
in `ParkCordon` wrote when each stretch went up; both were removed before anything was committed.
Everything after the busker stands there is the game's own code. `tests/test_park_cordon_seeds.gd`
holds the same case headlessly, a busker in each edge row on every seed it sweeps, with a check
that no tape goes up through him.

**When the east edge went up**, by the scratch print, in seconds after the cordon set out: before,
the stretch over him (1332, 3887 to 3921) at 4.0s, with the stretches either side at 3.8s and 4.5s;
after, the same stretch at 8.5s, its neighbours at 8.3s and 8.8s. In both runs the last gap was
taped 13.5s after the swing with her still inside, by the run log.

- `before-tape-through-him.png`, 17.4s into the run, 4.8s after the swing: the east edge's tape
  runs down through the busker (outlined in orange), who has not been walked out yet; two
  officers stand on the edge, one above him and one below.
- `after-the-taper-waits.png`, the same moment on the fixed code: no tape on the east edge beside
  him, only a post just below him; two officers stand on the edge, one at his shoulder and one
  below.
- `after-taped-behind-him.png`, 21.2s into the run on the fixed code: his escort has reached him
  and the two stand inside the park, west of the east edge, whose tape is now up where he stood.

The stills are of one seed and one spot; the measured change over every seed and edge row the
sweep covers is in PR #891's description.
