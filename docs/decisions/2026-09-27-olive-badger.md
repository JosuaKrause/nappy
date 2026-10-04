# olive-badger — What she meets on her route is drawn from a marble bag · built 2026-10-04

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 2: "events should use the marble bag
approach as well. that way we can control what the player sees on their route"; the bag's design in
[quiet-yak](../playtests/2026-10-03-quiet-yak.md), #505 to #508; the rigged bag, its sizes, nested bags
and the return patrols in [coral-bunny](../playtests/2026-10-04-coral-bunny.md), #561.)*

**What was built** (PR #565). `src/city/marble_bag.gd` is one generic bag that is a queue of bags:
ordinarily one, refilled when empty; a special bag goes in front and the interrupted one resumes with
what it had left, the poster pre-bag being the first such bag (poster tears draw exactly as before).
`rig()` makes the player's rigged bag: the ensured marble plus x-1 marbles taken out of the active bag,
leaving two bags of x and n-x+1 and creating nothing but the ensured marble. `rig_spaced()` is the
player's two-bag trick (a bag of N without the marble, then a bag holding it) and a marble may itself
be a bag (nested), handed out at most once per outer fill; both are built and tested and used nowhere
yet. `peek()` names the next marble without spending it, so a failed siting does not burn an event.

The dawn still decides how many events the day buys for her route, with the same weighted roll; the
route bag (`EventDirector`, `Tuning.ROUTE_BAG_MARBLES_PER_WEIGHT` = 2 marbles per unit of weight, on
its own stream) decides which row each is, for the rows the director sites (`AHEAD_OF_PLAYER`,
`TOWARD_PLAYER`). After day 6's mark a man shouting is one of the next two events on her route
(`Tuning.TASK_CONTACT_WITHIN_THE_NEXT`), beyond where events are brought into the world and kept ahead
of her, beside the one feathery-marmot spawns near the mark. Day 11 keeps feathery-marmot's mast near
the mark, which the arrow points at, and rigs a second at x=2 onto her route. Each return patrol in
acts III and IV is a rigged bag of 2 (`Tuning.RETURN_PATROL_WITHIN_THE_NEXT`): appended behind the queue
before, none of 120 landed over 48 return legs; now 66 do, and every leg meets one. Day 3's lesson dog
stays the first event at its 6s delay.

**Measured** over 12 seeds and 9 days (`tests/probes/olive_badger_route_mix.gd`): the share of a day's
route events that would have to change row to match the weights fell from 17% to 11% on average (worst
day 53% to 32%), and the longest run of one row from 8 to 4. Day 3's charging dogs rose from 1.75 to
2.25 on average, because the bag now holds dogs at their weight's share.

**Proposed, not asked for, and open to overturn:** the rows the bag holds, and "any more the route
needs" read as the rigged places; two marbles per unit of weight; a rig moving owed events to the head
of the queue and topping it up; a rigged bag's other marbles taken from the next bag if the active one
runs short; a nested marble returned with the next outer fill; the route mast placed under the dawn
rules without `MastSites._is_eligible()`, so it may stand on the home street; the day-3 rise in dogs.
**Not changed:** feathery-marmot's near-the-mark mast and the day-6 near-the-mark man shouting, which
must exist the moment she reads the mark, which a route marble cannot promise.
