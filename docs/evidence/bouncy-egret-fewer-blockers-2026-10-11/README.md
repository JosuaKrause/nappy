# bouncy-egret, fewer hard blockers from the gatehouse day: before and after

**Claim.** On the same seed and day, the branch stands fewer blockers off the day's route tree than
`main` does. Both stills frame the same stretch around the doorstep. In this frame, `main`'s soft
seals (market stall pairs on the upper-left street, cafe tables lower left) are missing on the
branch, and the debug readout's event total for the whole day falls from 527 to 373. The tree, the
route overlay (layer 5) and the region wall's posts on the right edge are the same in both.

**Limits.** Each still is one frame of one seed and one day. It shows what stands near the
doorstep, not the whole city. The per-day counts over several seeds come from the probe
(`tools/test.sh probes/bouncy_egret_blockers.gd`). Both runs are `--invincible`, so the clock and
the meter stand still.

**Source and command.** Branch `feature/bouncy-egret-fewer-blockers` at 047f988d.
The "before" still was taken on that revision with `main`'s own `src/routes/seal_planner.gd`,
`src/routes/closure_planner.gd`, `src/events/event_scheduler.gd` and `src/city/recipe_city_builder.gd`
checked out over it. The "after" still was taken on the revision as committed. Both runs used:

    RESOLUTION=1280x720 tools/shot.sh <out>.png 3 --seed 4242 --day 10 --invincible --zoom 0.5 --layers 5

**Retained.** The two stills only. The runs' logs and telemetry folders were scratch.
