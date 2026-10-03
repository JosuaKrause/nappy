# Day 8's red arrow on the burnt building's door

**Claim.** On day 8, once the mark is read, the red arrow's tip stands on the door of the burnt
building, where the task's contact stands. The player, sandy-egret: *"or better to the door but
the acceptance radius centered at the door should have a large enough radius for half the
sidewalk to be covered"*.

**Still.** `day8-arrow-on-door-seed4242.png`: the burnt building is the narrow two-column front
right of the striped barrier, upper right. Its windows are black and broken, and its doorway is
boarded. The red chevron and its "task" label sit on that doorway. The doubled red mark over her
is the task's guard waking, which is the game's own cue.

**How it was taken.** Source revision `5e3eea5b` (branch `feature/building-burns`, PR #415) plus a
throwaway edit to `src/main.gd`, not committed. On day 8, right after `_resistance.start_day(...)`
in `_start_day()`, it called `_resistance._on_contact_completed(5)` (reading the day's mark). It
then set the start position to the walkable ground nearest 128px west and 32px south of the
contact, on the sidewalk. Then:

    tools/shot.sh out.png 4 --seed 4242 --day 8 --invincible --no-title --zoom 0.85

A `--day 8` start has no recorded scar, so this is the fallback: the shell, the scar and the burnt
building all come from `ResistanceDirector._burn_a_front_for_the_task()`, and the contact stands
on that building's door (`_ride_to_the_door()`).

**Limits.** A rig, not a walk: the mark was read by a call, not by her reaching it. The touch
radius is not visible in a still. `tests/test_resistance.gd` checks it: a touch from the near
half of the sidewalk in front of the door completes the task, and one from the far half or past
the sidewalk does not. The debug readout covers the right edge, as on every `shot.sh` still.
