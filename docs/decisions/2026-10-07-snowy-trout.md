# snowy-trout — Day 12's walk home after the park did not softlock again · 2026-10-11


[azure-koala](../playtests/2026-10-07-azure-koala.md), finding 9, inbox #601:

> day 12 after closing the park and walking back with sleeping baby softlocks the game

**It did not reproduce, and no game code changed.** The report was written against the park's old
closing by mud rings, which [plush-marten](2026-10-10-plush-marten.md)'s police cordon has replaced,
so no ground is repainted on day 12 any more. On the cordon, the route rig (`tools/run.sh --day 12
--invincible`) touched the swing, had the park taped with her outside and walked her home to a won
day on seeds 4242, 11 and 13 with the baby settled elsewhere (`--route mark,task,calm,home`), and on
seeds 4242, 11, 13, 7 and 99 with the baby asleep from dawn (`--meters 100 0 --route
mark,task,home`).

**`tests/test_park_return.gd` pins the part the rig never reached**: the summary and the next
morning. On seeds 4242, 11 and 13 it boots the real `Main` at day 12 and carries each case through
`Main._on_day_finished()` and `Main._on_summary_continued()`: asleep in the park and out through the
last gap, and settled outside with the park taped behind her, each win at home and leave the summary
into a running day 13 (walking, the baby awake, no cordon left, her at her door, the clock running);
shut in with the baby asleep, the day is lost to the cordon and the summary replays day 12 with the
baby awake and no old cordon. *Chosen where the item was silent:* the suite moves her by setting her
position, so the tape's solidity stays with the rig and `tests/test_park_cordon.gd`; it gives `Main`
its seed through a scratch save. [The review item](../review/2026-10-07-snowy-trout.md) asks the
player to play the sequence again.
