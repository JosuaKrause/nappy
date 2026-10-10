priority: next

# sandy-magpie — Day 6's second man shouting is rarely met · filed 2026-10-10


Found building day 7's route van ([olive-badger-2](../../decisions/2026-09-27-olive-badger-2.md)),
not from a playtest. The player's ask behind day 6's rigged bag is that she is "guaranteed to
encounter a yeller in the next three events" ([olive-koala](../../playtests/2026-09-27-olive-koala.md),
statement 2). `tests/probes/calm_pelican_day7_van_met.gd`, walking 12 cities the way
`--route mark,task,calm,home` does, found day 6's second man shouting, sited by the route band of
`WalkSiting.ahead_of()`, in her view on only 3 of the 12 walks, where day 7's van, sited on the
street she is walking by `WalkSiting.ahead_on_her_street()`, is in view on 8.

Measure why the other nine miss (never placed, placed on a branch she leaves, or placed too far
ahead before home), and make the rigged man shouting one she meets, the way the van now is.

*Proposed, not asked for:* the band `next`, since the player named none.
