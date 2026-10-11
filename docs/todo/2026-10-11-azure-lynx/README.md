priority: next

# azure-lynx — Day 7's route van is met less often than it was · filed 2026-10-11

Found while building [sandy-magpie](../../decisions/2026-10-10-sandy-magpie.md), not reported by the
player. Day 7's route van, sited on the street she is walking by `WalkSiting.ahead_on_her_street()`
([olive-badger-2](../../decisions/2026-09-27-olive-badger-2.md)), was in her view on 8 of the 12
walks of `tests/probes/calm_pelican_day7_van_met.gd` when it was built; on `main` it is in view on 3. Nothing says which change since lowered it.

Find the change (bisect the probe over the merges since olive-badger-2; bouncy-egret's halved
closures and the route and siting changes since are candidates), say why the van is now missed, and
bring it back to being met as often as olive-badger-2 built it, with a regression like
`tests/test_day6_yeller_met.gd` that fails on a lower rate.

*Proposed, not asked for:* the band `next`, as sandy-magpie had.
