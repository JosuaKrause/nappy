priority: now

# velvet-stork — Day 13's guard reaches her from across the city · filed 2026-10-11

Found while building [bouncy-egret](../../decisions/2026-10-10-bouncy-egret.md), not reported by the
player. [calm-pelican-14](../../decisions/2026-10-10-calm-pelican-14.md) sets day 13's task guard on
her the moment she completes the task, wherever he stands, from the player's "as long as he starts
pursuing when you hit the task it's fine" (curly-gecko). A guard left at another roadblock comes
straight at her with no pathing: on seed 4242 with bouncy-egret's halved closures, from 1,778px away
with a building between them, he stops at 479px and never reaches her, so
`tests/test_day13_guard.gd` now also accepts a guard who closed in and whose line to her is
blocked. The work is [reach-her.md](reach-her.md).
