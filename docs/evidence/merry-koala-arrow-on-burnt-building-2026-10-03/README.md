# Day 8's red arrow on the burnt building

**Claim.** On day 8, once the mark is read, the red arrow's tip stands on the front wall of the
burnt building, not on the sidewalk in front of it, and on a run with no recorded `burnt_shell`
scar that building is burnt for the task the moment the mark is read.

**Still.** `day8-arrow-on-burnt-building-seed4242.png`: the red chevron and its "task" label sit on
the ground floor of the building with the black, broken, soot-streaked windows (upper middle), a
few pixels above its foot; the sidewalk in front of it is bare.

**How it was taken.** Source revision `766f1c1b` (branch `feature/building-burns`, PR #415) plus a
throwaway four-line edit to `src/main.gd`, not committed: right after
`_resistance.start_day(...)` in `_start_day()`, on day 8 it called
`_resistance._on_contact_completed(5)` (reading the day's mark) and set the start position to
`DevRig.nearest_walkable(map, rider + Vector2(-160, 32))`, five tiles west of the shell on the
sidewalk's kerb lane. Then:

    tools/shot.sh out.png 4 --seed 4242 --day 8 --invincible --zoom 0.7

A `--day 8` start has no recorded scar, so this is the fallback: the shell, the scar and the burnt
building all come from `ResistanceDirector._burn_a_front_for_the_task()`.

**Limits.** A rig, not a walk: the mark was read by a call, not by her reaching it. `--invincible`
keeps the clock still. `tools/run.sh --seed 4242 --day 8 --invincible --route mark,task` was tried
first and never moved past the start in its run log within the rig's wall-clock limit, so it gave
nothing to keep. The debug readout covers the right edge, as on every `shot.sh` still.
