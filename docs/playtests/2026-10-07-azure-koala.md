# Playtest azure-koala — Ten bugs from playing

2026-10-07.

## #601 — Lots of bugs

The player's note on [issue #601](https://github.com/JosuaKrause/nappy/issues/601),
labelled `queue_now`:

> - burnt building task is not at the door of the building
> - car accident has halo drawn on top
> - bollards on the pedestrian zone do not block the player
> - the guard pursuer makes his barrier jump up and down and then dissappear
> - police cars can disappear outright
> - red arrow tasks show a chalk mark at their destination
> - police cars chasing the player behave like running people (instead of... cars) but are at least no lethal. pursuing police should rather use the police sprite instead
> - police cars don't have a hitbox
> - day 12 after closing the park and walking back with sleeping baby softlocks the game
> - police car's shadow makes it look floating

## Filing

The ten bullets above are findings 1–10 in their original order. All are in the note's `now` band.

| Finding | Queue owner |
|---|---|
| 1, burnt-building door | [teal-moose, task at the door](../todo/2026-10-07-teal-moose/README.md) |
| 2, crash halo | [dappled-egret, halo behind the cars](../todo/2026-10-07-dappled-egret/README.md) |
| 3, bollards | [tall-walrus, bollard collision](../todo/2026-10-07-tall-walrus/README.md) |
| 4, guard's barrier | [spotted-wombat, steady barrier](../todo/2026-10-07-spotted-wombat/README.md) |
| 5, disappearing police car | [feathery-quail, patrol disappearance](../todo/2026-10-07-feathery-quail/README.md) |
| 6, destination chalk | [snowy-kestrel, destination picture](../todo/2026-10-07-snowy-kestrel/README.md) |
| 7, police pursuit picture | [sandy-ferret, pursuit on foot](../todo/2026-10-05-sandy-ferret/README.md), a re-report |
| 8, police hitbox | [sunny-finch, police collision](../todo/2026-10-07-sunny-finch/README.md) |
| 9, day-12 softlock | [snowy-trout, return after the park](../todo/2026-10-07-snowy-trout/README.md) |
| 10, floating police shadow | [silver-egret, shadows at ground contact](../todo/2026-10-03-silver-egret/README.md), a re-report |

Finding 10 answers the police-shadow part of
`docs/review/2026-09-11-look-at-a-parked-delivery-van.md` negatively. Its van-facing and
police-marking questions remain unanswered. The collision policies and reproduction details
left unspecified by the note stay open in their queue items.
