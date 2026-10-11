priority: now

# feathery-hare — The chalk mark stands one tile into its alley · filed 2026-10-10

[azure-puffin](../../playtests/2026-10-10-azure-puffin.md), point 3, inbox #664:

> let's move the chalk mark one tile into the alley so I actually have to enter the alley to
> activate it

Today a mark stands on the centre of an alley's mouth tile (`ResistanceDirector._alley_mouths()`),
16px in from the street, and is touched within `ContactPoint.REACH` (36px), so she reads it standing
up to 20px outside the alley. The player's earlier answer in
[quiet-yak](../../playtests/2026-10-03-quiet-yak.md) (inbox #486), "Mouth only (Recommended)" to
"Should a chalk mark only ever sit at an alley's mouth (its end), never mid-alley?", still holds
for where the mark is chosen: the mark keeps its mouth and moves one tile further in from it. The
work is [one-tile-in.md](one-tile-in.md).
