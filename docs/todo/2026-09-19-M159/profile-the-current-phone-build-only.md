**Profile the current phone build only after that baseline.** The player reports the
released v0.18.0 "a bit stuttery" on a phone ([PLAYTEST-138](../../playtests/PLAYTEST-138.md)). Divide CPU time between the
baby's every-physics-tick crowd contribution sweep, the halo's rendered-frame contribution
sweep, event streaming/director work, crowd movement/traffic and debug presentation. Do not
use `--invincible`: it skips the baby's source sweep and suppresses the meter behavior being
measured. Measure the conservative contribution rejection on that device, including its
effect on the baby and halo callers, before considering caching or lower tick rates. The player's phone is
Chrome on a Pixel 8 Pro, where the stutter is steady rather than at particular moments
([PLAYTEST-140](../../playtests/PLAYTEST-140.md)).
Native median improvements do not establish phone performance or uniformly better frame tails.

[snowy-ibis, mobile ground-stepping feedback](../../playtests/2026-10-02-snowy-ibis.md)
reports no visible removal of stutter from per-region stepping.
[sunny-chipmunk, the player's clarification](../../playtests/2026-10-03-sunny-chipmunk.md)
asks for more optimization work in `now` and consideration of other approaches.
The baseline remains a comparison prerequisite, not a reason to defer identifying
candidate costs. Do not assume the latest report uses the earlier named device.
