# silver-osprey — A loose dog that cannot reach her is retired off screen · 2026-10-11


[sunny-hedgehog](../playtests/2026-09-27-sunny-hedgehog.md), statement 4:

> a loose dog that spawns behind me never arrives it stays offscreen indefinitely...

**A dog is sent ahead of her, so "behind" is a dog she has turned away from.** The director sends
the loose dog ([M176](2026-09-20-M176-the-loose-dog-is-loud-while-it-passes-and-three-more-rows-by-feel.md))
only down her line ahead of her. Standing, or walking away at 92 px/s, she is caught by the dog at
132 px/s, which reaches her and runs past, its nearest approach under 40px. **Running away at 168
px/s is the stall:** the dog never gains and runs its whole route out of sight, 10.7s when sent from
700px out, with nothing ending it sooner. A sweep of 664 trials on one seed, every sidewalk tile in
four directions, standing and walking away, found no dog that never ends; the stall is a long one.

**A row sent down her line without a warning is finished where it stands once it is more than
`Tuning.OUT_OF_SIGHT` (420px) from her and has not closed on her by at least 10 px/s for 2s**
(`EventInstance._give_up_what_cannot_reach_her()`); today that is the loose dog alone. A dog still
closing, however slowly, runs on and passes her, so a dog she walks away from, closing at 40 px/s
from 700px, is still unseen for about 8s before it arrives. The cyclist, at 165 px/s below her
run's 168, can be outrun the same way, but it telegraphs, so it is not covered and still runs its
route out unseen. It is not made faster, since it is not a pursuer.
`docs/EVENTS.md` says so. `tests/test_loose_dog_arrives.gd` holds a dog she runs from retired off
screen, and one she stands for or walks from arriving and passing; the retirement checks fail on
`main`. The burst, [silver-osprey-dog-arrives-2026-10-11](../evidence/silver-osprey-dog-arrives-2026-10-11/),
shows a dog sent while she walked south coming up behind her once she turned north and passing at 17px.

*Chosen where the entry was silent, open to overturn:* the 2s, the 10 px/s floor and the 0.5s
between looks. *The alternatives, the player's to choose:* a dog that always reaches her, rather
than one retired when it cannot; retiring the slow-closing dog too; and covering the cyclist.
The sweep found no dog that never ends, so what was fixed is a long unseen run, not an endless one.
