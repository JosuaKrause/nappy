**Profile the current phone build only after that baseline.** Divide CPU time between the
baby's every-physics-tick crowd contribution sweep, the halo's rendered-frame contribution
sweep, event streaming/director work, crowd movement/traffic and debug presentation. Do not
use `--invincible`: it skips the baby's source sweep and suppresses the meter behavior being
measured. Measure the conservative contribution rejection on that device, including its
effect on the baby and halo callers, before considering caching or lower tick rates. The player's phone is
Chrome on a Pixel 8 Pro, where the stutter is steady rather than at particular moments
([PLAYTEST-140](../../playtests/PLAYTEST-140.md)).
