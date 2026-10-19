# downy-tapir — The escape's city draws its dangers from one marble bag · 2026-10-18



downy-tapir's second item. The player: "make escape winnable with minimal changes (fixing event
distribution in some cheap way)" (minty-lemur #794), and on the escape city's events: "nobody ever
asked for all four events on *every* street ... yes, a marble bag is absolutely needed with empty
events (nothing happening) as well. we need a fair mix", in the order "trucks > explosions > vans >
barriers > empty" (minty-lemur #785). Built inside `build_finale` as the named exception to
**orchestrating**'s "Code is designed by layer", which holds only until minty-quail's refactor
replaces this code (minty-lemur #798, #799).

**Before (PR #801).** Every open street of the escape city got one army truck, one unmarked van, one
roadblock with its guard and one explosion. A probe walking the shortest walk from the service exit
to each exit over 24 seeds got out on 0 of 48 walks (47 cried, 1 caught).

**Built.** Each open street has `Tuning.FINALE_SLOTS_PER_STREET` (1) slot, and each slot draws one
marble from one bag for the whole escape (`EventScheduler.escape_bag()`): 10 trucks, 8 explosions, 3
vans, 2 roadblocks and 1 empty marble (`FINALE_BAG_TRUCKS`, `_EXPLOSIONS`, `_VANS`, `_ROADBLOCKS`,
`_EMPTY`), the player's order kept strictly. A drawn danger the placement rules refuse is spent
unmet, and every placement rule the escape kept before still applies. The bag has its own stream
seeded from the plan's seed, so a restart after a loss draws the same city, as before. `build_finale`
takes the bag and the slot count as arguments, so the bag moves onto the day's scheduler unchanged
(minty-quail's `escape-placement.md`).

**How the numbers were chosen.** `tests/probes/escape_winnable.gd` runs the real city and events from
a straight escape boot into the city, ticked at 30Hz, and walks the shortest walk to each exit at
walking and at running pace from a sleeping baby, playing the lure at a roadblock. It stands in for
the baby's meter (fed the way `Baby` feeds it), collisions and the camera, and its walker never
settles the baby on calm ground or steps aside for a truck, so its results lean against her. The
chosen bag got out on 95 of 96 walks over two sets of 24 seeds (the baby woke on 4); a walk meets
about 8 dangers (about 3 trucks, 3 explosions, 1 van, 1 roadblock) and takes up to 130s of the 180s
clock. Rejected on the first seed set: the smallest bag the order allows (5, 4, 3, 2, 1), 44 of 48;
6, 5, 4, 3, 2, 45 of 48; two slots a street, 43 and 47 of 48 there but 42 and 43 on a fresh set. Both
exits were reachable on every seed at every mix. Running the whole walk cried on every walk at every
mix, an empty city included (running costs 14 meter points a second), so walking is the sensible
pace. The raw output is in `docs/evidence/winnable-escape-2026-10-19/`.

**Open to overturn.** One slot, with the vans and roadblocks (what ends the section) at the floor
the order allows; the empty marble as the empty string; the bag refilling when empty (one fill of 24
marbles is about a plan's 25 to 35 streets, drawn in the plan's open-street order). The alternative
for more climax, two slots with 12, 10, 3, 2, 1 (about 12 dangers a walk, the baby woken on 18 of 96,
out on 90 of 96), is one constant away and is asked in the review item `2026-10-18-downy-tapir`.

**Left for minty-quail.** A van at a narrow point can leave no safe walk: placement keeps a sidewalk
open past its body but not past its 54px lethal reach (3 of main's 48 walks, none of the chosen bag's
96). With nothing handed in, `build_finale` reads its defaults from `Tuning` rather than being handed
them by `FinalePlanner.plan()`. And `RouteRig` (`--route`) is not built on the escape boot, so the
probe stands in for the baby and collisions.
