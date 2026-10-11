# sandy-magpie — Day 6's rigged man shouting is sited on her street · 2026-10-11


Found building day 7's route van ([olive-badger-2](2026-09-27-olive-badger-2.md)), not from a
playtest. The player's ask behind day 6's rigged bag is that she is "guaranteed to encounter a
yeller in the next three events" ([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 2).

**He was sited by the route band and missed her.** On the 12 walks of
`tests/probes/calm_pelican_day7_van_met.gd` (the way `--route mark,task,calm,home` walks), day 6's
second man shouting was in her view on 1. On 6, `WalkSiting.ahead_of()`'s route band found no tile
(she was off the day's routes, or no tile on the branch) until she was home; on 5 it sited him
1,260–1,490px ahead on a branch she then left, the nearest she came 540–900px.

**`WalkSiting.ahead_of()` hands the man shouting to `ahead_on_her_street()`**, as day 7's van is
sited, so he stands on the street she is walking. On the probe he is now in her view on 9 of 12
walks, sited and unseen on 3 where she turns off, never unsited. `docs/EVENTS.md`'s day-6 rig says
so. `tests/test_day6_yeller_met.gd` walks 5 seeds and needs him seen on 4; on the old siting he was
seen on none. `tools/test.sh probes/calm_pelican_day7_van_met.gd` reruns the probe. The still,
[yeller-met-2026-10-11](../evidence/yeller-met-2026-10-11/), on seed 4242, day 6, was saved by a
capture-only patch to the route rig, not committed; the game code in it is the branch's.

*Chosen where the entry was silent, open to overturn:* the row is picked by its id inside
`ahead_of()`, so any man shouting a bag hands her is sited this way, rather than by a field on the
row; the 3 walks where she turns off are left. **Found on the way:** day 7's van is in her view on 3
of the probe's 12 walks on `main`, not the 8 it was built at; that is queued as
[azure-lynx](../todo/2026-10-11-azure-lynx/README.md), day 7's route van is met less often than it
was.
