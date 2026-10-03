# feathery-marmot — a task's target is near its mark, and the robber two-thirds in, 2026-10-03

Three stills from `tools/shot.sh`, each with `--spawn contact --invincible --no-title --no-save`.
`--spawn contact` stands her 76px from the day's chalk mark (70px east and 30px south of it);
`--invincible` freezes the clock and the meter so the shot is not racing a day loss. The source
revision is the build line in each frame's top-right corner. Each caption's distances are the run's
own `run.log` lines. A task is placed out of her view when she reads the mark, so a still cannot
show both at the moment of reading: the two task stills pull the camera back with `--zoom 0.45`,
and the zoom widens the view the placement keeps the task out of as well, which can only push a
task further out, never nearer.

## `seed555555-day6-robber-two-thirds-in.png` — the robber two-thirds through the alley

`tools/shot.sh out.png 1.5 --seed 555555 --day 6 --spawn contact --invincible --no-title --no-save
--zoom 0.75`. The mark is at (67,53) in an east-west through-alley running from column 62 to 69,
not yet read (the plain circle and cross, left of her); she is at its east mouth. The alley is 256px
long and the mark 80px in from its east edge, so two-thirds through it is 91px past the mark:
`chalk mark guarded (two-thirds in): robber 91px away`. He is the hooded figure in the alley's west
half, in the waiting posture. This is the alley `docs/evidence/m213-robber-at-the-far-end-2026-09-27/`
photographed with him on the far end tile, (62,53); a one-block alley is too short for two-thirds
and 176px from the mark both, and two-thirds wins (inbox #471), so reading the mark from this end
may wake him.

## `seed555555-day7-van-near-the-mark.png` — the van near the mark it was read at

`tools/shot.sh out.png 4.2 --seed 555555 --day 7 --spawn contact --walk 0.7@293@0.3p2.4n2p
--invincible --no-title --no-save --zoom 0.45`: a step onto the mark, then north for 2.4 seconds.
The read mark (crossed through, green) is in the alley at the bottom of the frame, at (122,92); `step 4
stands 536px from the mark it was read at` — the van, at the top left, with the red arrow's tip on
it. The hooded figure behind her is the mark's robber, woken as she read it.

## `seed90210-day11-mast-near-the-mark.png` — the mast near the mark

`tools/shot.sh out.png 3.5 --seed 90210 --day 11 --spawn contact --walk 0.7@293@3p --invincible
--no-title --no-save --zoom 0.45`. The read mark is under her at (51,79); `step 12 stands 256px
from the mark it was read at` — the mast's foot across the main road to the east, its broadcast
waves drawn, the red arrow pointing at it.

## Not shown

A task with nothing that qualifies within 576px of its mark is placed at the nearest place that
does: on day 11 that is the nearest live mast (816px on seed 4242 day 11 here, 1377px and 3948px in
the route rig's sweep), since six masts stand across a whole city.
