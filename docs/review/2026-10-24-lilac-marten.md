# lilac-marten — Which bag the escape's city is drawn from · 2026-11-25

**What to do.** Play the escape's city with each of the four bags a few times each, from the same
seed: `tools/run.sh --seed 4242 --start-escape city --escape-bag D` (and `A`, `B`, `C`; on the page,
`?debug=1&escape=1&escapebag=D`). `D`, the game's default, holds 14 army trucks, 12 explosions, 3 unmarked
vans, 2 roadblocks and 1 empty marble; `A` is the escape as it shipped (10, 8, 3, 2 and 9 empty, so
about half the streets stand nothing); `B` is the player's order with the freed marbles spread
over every row (13, 11, 4, 3, 1); `C` is `A` with two marbles drawn a street.

**Where to look.** How many of the streets on her walk have something on them as she comes to them,
and what: the vans, the roadblock guards, a convoy sent down the lane at her, an explosion's badge.
The bridge walk meets few trucks in every bag (the craters ahead and the sealed cross streets leave
a truck no lane), so what fills its streets is the vans, roadblocks and explosions.

**The question a run answers.** Is the escape full enough, and which bag is it: may the empty marble
be one (the player's order has empty rarest), and is `D`, which fills the city with trucks and
explosions that only wake the baby and leaves what takes her as it was, the right default, or does
the city want more vans and roadblocks (`B`, `C`), at the cost of more lost walks? The record
(`tools/decisions.sh lilac-marten striped-stork`) has the measured shares for each bag.

