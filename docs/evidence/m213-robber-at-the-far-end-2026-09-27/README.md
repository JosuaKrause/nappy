# M213 — the chalk mark's robber stands at the far end of its alley, 2026-09-27

Three stills, `tools/shot.sh <name>.png <seconds> --seed <seed> --day 6 --spawn contact
--invincible --no-title --no-save --zoom 0.75`. `--spawn contact` stands her 76px from the
day's chalk mark (70px east and 30px south of it); `--invincible` only freezes the clock and the
meter so the shot is not racing a day loss; `--zoom 0.75` pulls the camera back so the whole alley is in frame. Each
caption's distances are the run's own `run.log` lines.

## `seed4242-day6.png` — before she reads it

1.5 seconds in, standing still. The mark is on the top tile of a north-south through-alley,
(122,146), not yet touched (the plain circle and cross, beside her). The run drew its guard at the
far end: `chalk mark guarded (far end): robber 200px away`, standing at (122,152), 183px from her.
He is the hooded figure with his glow at the bottom of the alley, in the waiting posture: asleep,
since she is outside his 140px `pursues_within`.

## `seed4242-day6-read.png` — reading it, and he stays asleep

The same run, with `--walk 0.4@290@0.35e7p` (a step west-northwest onto the mark, a step east so the
pram no longer covers it, then standing), 7 seconds in. `step 1 completed` is in the log and the
mark now shows `chalk_mark_touched.svg`, the green crossed-through picture, at the top of the alley.
The robber is still at the far end in his waiting posture. The log has no notice or chase line for
him.

## `seed555555-day6.png` — an alley too short to put him past his range of the mark

1.5 seconds in. The mark is at (67,53) in an east-west through-alley running from column 62 to 69,
not yet touched (the plain circle and cross, left of her). It is five tiles from the alley's west
end: `chalk mark guarded (far end): robber 160px away`, less than `pursues_within` (140px) plus
`ContactPoint.REACH` (36px). So he stands on the far end tile itself, (62,53), the hooded figure at
the left of the alley, asleep. She is at its east mouth, the mark's own end; a read from this side
is at least 164px from him.
