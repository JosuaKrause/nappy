priority: now

# merry-elk — More posters, from the first day they appear · filed 2026-10-04

[busy-quail](../../playtests/2026-10-04-busy-quail.md) files inbox #563, from playing:

> the poster density should be higher -- on the first day with posters it's very hard to find one -- increase the probability throughout -- even the end doesn't have many posters

**Asked for:** more posters on every day that has them, the first such day most of all.

**What exists.** Posters and their tears come from `src/city/poster_state.gd` and
`src/city/poster_walls.gd`, drawn through the marble bag (`src/city/marble_bag.gd`, PLAYTEST-125);
the bag is being generalised by olive-badger (PR #565), so this waits for it.
