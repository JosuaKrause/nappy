# feathery-marmot — a task's target is near its mark, and the robber two-thirds in, 2026-10-03

Three stills from `tools/shot.sh`, each with `--spawn contact --invincible --no-title --no-save`.
`--spawn contact` stands her 76px from the day's chalk mark (70px east and 30px south of it);
`--invincible` freezes the clock and the meter so the shot is not racing a day loss. The source
revision is the build line in each frame's top-right corner. Each caption's distances are the run's
own `run.log` lines. A task is placed out of her view when she reads the mark, so a still cannot
show both at the moment of reading: the two task stills pull the camera back with `--zoom 0.45`,
and the zoom widens the view the placement keeps the task out of as well, which can only push a
task further out, never nearer.

## `seed555555-day6-mouth-mark-robber-two-thirds-in.png` — a mark at the mouth, the robber two-thirds in

`tools/shot.sh out.png 1.5 --seed 555555 --day 6 --spawn contact --invincible --no-title --no-save
--zoom 0.75`. `--spawn contact` stands her beside the dawn mark without the relocation running,
and the dawn draw is itself made only from alley mouths, so the mark shown is the one the day
drew: `step 1 on offer at (55,64)`, the east end tile of an east-west through-alley, not yet read
(the plain circle and cross, at the top right of the alley). She is on the sidewalk outside that
mouth. The alley is 256px long, so two-thirds through it from the mark's end is 155px from the
mark: `chalk mark guarded (two-thirds in): robber 155px away`. He is the hooded figure at the left
of the alley, waiting. That is under the 176px his trigger and the touch reach together need, so
reading the mark from this end may wake him: "Two-thirds wins" (inbox #471 in [quiet-yak](../../playtests/2026-10-03-quiet-yak.md)).

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

## `seed90210-day11-queued-mast-arrow-and-mark-on-its-foot.png` — the mast queued near her, the arrow and the touch point on its foot

`tools/shot.sh out.png 7.5 --seed 90210 --day 11 --spawn contact --walk 0.7@293@0.3p2.8s3.2e2p
--invincible --no-title --no-save --zoom 0.75`, at the head the PR's review fixes landed on: a step
onto the mark at (135,97), then 2.8 seconds south and 3.2 east toward the task. No live mast stood
where her paths reach the 576px circle round her, so one was queued and the scheduler generated it:
`a mast is generated at (148,112) for the task, 635px from the mark`. It is at the bottom of the
frame, its broadcast arcs over it, on the sidewalk in front of the building; the red arrow's tip is
on its foot, and the touch point's chalk mark (`chalk_mark.svg`, which every task with no body
draws where it is touched) is drawn on the foot too.

## Not shown

Days 9, 12 and 14. Their places are fixed (a district door's gatehouse, the one swing park, the
station's door) and stand 1,388–4,866px from where their marks were read in the runs tried, too far
for a timed `--walk` to reach, and a `--route` run cannot take a screenshot (it quits on arrival).
Day 14 cannot be started with the goal met from the command line at all. The playable scenes the
busy-raven entry asks for are what will show those three. The swing's touch area, the ellipse at
its base, is the shadow the frame already casts there, so it is drawn in any still of the swing.
