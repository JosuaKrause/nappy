# Day 13's guard at the roadblock she approaches, and day 7's route van

**Claim.** On day 13, after she reads the mark, the red arrow points at the live roadblock closest
to her on foot, and the task's waiting guard has been moved, unseen, into the band round that
roadblock, with a clear line to it, even though it is not the roadblock the task was placed at.

**The scene** (`day13-guard-follows.json`, a full-city scene recipe, run seed 11, city context seed
1917501, day 13): the mark at tile (92, 69), her start at (87, 70), and one authored roadblock,
`the_roadblock_she_approaches`, at world (2768, 2064) on the street north-west of the mark. She
walks to the mark, reads it, and walks west and north toward the authored roadblock. The task's own
roadblock is placed by the day's rules at tile (109, 72), 552px east of the mark, and its guard is
drawn there first. The camera is zoomed out to 0.5 so the roadblock and the guard fit in one frame.

**What the still shows** (`day13-guard-follows.png`, captured 5.4s in, `--invincible`): the red
arrow, labelled "task", on the authored roadblock with its two soldiers; her on the street below
it; the chalk mark's own guard, a hooded robber two-thirds into the mark's alley to the right; and,
at the top edge of the frame on the roadblock's own street, the task's waiting guard, 224px north
of the roadblock's body, inside its band (`ResistanceDirector._roadblock_guard_spot()`) and with a
clear line down the street to it. `run-log-excerpt.txt` is the run's contact and roll lines, in
order: the task's roadblock placed 552px from the mark, its guard drawn 202px from it, the arrow
moving to a closer target on foot, and the guard moving, unseen, 224px from the roadblock she
approaches. The times read 0.0 because `--invincible` stops the day's clock.

**Limits.** One seed and one walk. The still does not show the move itself, which happens off
screen by design; the run log and `tests/test_day13_guard.gd` are what hold that he moves only while
neither where he stands nor where he goes is in view. The zoomed camera is the evidence's choice:
a wider view also widens what counts as in her view, so the move waits longer than at the player's
own zoom.

**Reproduce**, from the branch's source (`calm-pelican` day-13 guard, captured at `ae42fbe7` plus
this folder):

```sh
./tools/scene-recipes.sh --recipe docs/evidence/day13-guard-2026-10-10/day13-guard-follows.json --output /tmp/day13-guard-check
./tools/shot.sh /tmp/day13-guard-follows.png 5.4 --recipe docs/evidence/day13-guard-2026-10-10/day13-guard-follows.json --recipe-mode scripted --no-save --invincible --player-view
```

## Day 7: the route van in her view

**Claim.** Day 7's second van, put on her route by the rigged bag her reading the mark makes, stands
on the street she is walking, ahead of her and out of her view when it is put there, and comes into
view as she keeps walking.

**Where it comes from.** `tests/probes/calm_pelican_day7_van_met.gd` walks 12 cities the way
`--route mark,task,calm,home` does, ticking what the event manager ticks for her walk. On seed 2024
it put the van at world (2736, 880), on the sidewalk west of her, 490px from her, while she
was walking home west; she had it in view 4s later. That run cannot be photographed: it is a
headless rig, and the route rig cannot take a still (`--route` refuses `--screenshot`, and a
recording of a whole route day runs far slower than the day).

**The still** (`day7-route-van.png`, 4.6s in, `--invincible`) is a scene recreating that moment:
`day7-route-van.json`, a full-city scene of city 2024 on day 7. It places the van exactly where the
probe's walk put it and starts her at tile (100, 24), where the probe's walk had her when the van was
put there, 480px east of it. She walks the way the probe's walk went on: a few steps west, south to
the sidewalk row, and west along it toward the van (`0.6w1.4s2.6w`).
It asserts that the van is clear of both views at the start and in her view by 4.6s. The still,
4.6s in, shows the van across the cross street on the very line of sidewalk she is walking: on that
walk her line was off the day's routes, where nothing refuses a van on her own sidewalk, and she
passes 32px from its feet, stepping round it. The scene does not run the rigged bag: the van is
authored where the bag's siting put it, so the still shows where it stands and what she sees, not
the draw.

```sh
./tools/scene-recipes.sh --recipe docs/evidence/day13-guard-2026-10-10/day7-route-van.json --output /tmp/day7-van-check
./tools/shot.sh /tmp/day7-route-van.png 4.6 --recipe docs/evidence/day13-guard-2026-10-10/day7-route-van.json --recipe-mode scripted --no-save --invincible --player-view
```
