# Day 13: the waiting guard at the roadblock she approaches

**Claim.** On day 13, after she reads the mark, the red arrow points at the live roadblock closest
to her on foot, and the task's waiting guard has been moved, unseen, into the band round that
roadblock, even though it is not the roadblock the task was placed at.

**The scene** (`day13-guard-follows.json`, a full-city scene recipe, run seed 11, city context seed
1917501, day 13): the mark at tile (92, 69), her start at (87, 70), and one authored roadblock,
`the_roadblock_she_approaches`, at world (2768, 2064) on the street north-west of the mark. She
walks to the mark, reads it, and walks west and north toward the authored roadblock. The task's own
roadblock is placed by the day's rules at tile (109, 72), 552px east of the mark, and its guard is
drawn there first. The camera is zoomed out to 0.5 so the roadblock and the guard fit in one frame.

**What the still shows** (`day13-guard-follows.png`, captured 5.4s in, `--invincible`): the red
arrow, labelled "task", on the authored roadblock with its two soldiers; her on the sidewalk below
it; and two hooded robbers in the alley to the right. The lower of the two, level with the
roadblock, is the chalk mark's own guard, two-thirds into the mark's alley at tile (92, 64). The
upper one is the task's waiting guard, 204px from the roadblock's body, inside the band
`ResistanceDirector._maybe_set_a_trap()` draws for the task. `run-log-excerpt.txt` is the run's
contact and roll lines, in order: the task's roadblock placed 552px from the mark, its guard drawn
170px from it, the arrow moving to a closer target on foot, and the guard moving, unseen, 204px from
the roadblock she approaches. The times read 0.0 because `--invincible` stops the day's clock.

**Limits.** One seed and one walk. The still does not show the move itself, which happens off
screen by design; the run log and `tests/test_day13_guard.gd` are what hold that he moves only while
neither where he stands nor where he goes is in view. The zoomed camera is the evidence's choice:
a wider view also widens what counts as in her view, so the move waits longer than at the player's
own zoom.

**Reproduce**, from the branch's source (`calm-pelican` day-13 guard, first captured at
`0bc9d9b2` plus this folder):

```sh
./tools/scene-recipes.sh --recipe docs/evidence/day13-guard-2026-10-10/day13-guard-follows.json --output /tmp/day13-guard-check
./tools/shot.sh /tmp/day13-guard-follows.png 5.4 --recipe docs/evidence/day13-guard-2026-10-10/day13-guard-follows.json --recipe-mode scripted --no-save --invincible --player-view
```

**Day 7's second van has no still.** The route van is sited by her walk on the day's routes, which
a scene recipe does not run (a scene's day has no placement context for her walk), and the route
rig (`--route`) refuses `--screenshot`. Its runs tried here did not give one either: with
`--invincible` no `--press snapshot` was written, and of the five runs with and without it (seeds
4242, 7, 90210 and 1234567) none brought the van into her view before the day ended or she reached
her target; on seed 1234567 the log shows the van put on her route 2126px ahead of her on the walk
home. `tests/test_day7_van.gd` holds the van being put on her route and brought into the world by
her walk, in three cities.
