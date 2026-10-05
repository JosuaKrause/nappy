# olive-badger — What she meets on her route is drawn from a marble bag · built 2026-10-04

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 2: "events should use the marble bag
approach as well. that way we can control what the player sees on their route"; the bag's design in
[quiet-yak](../playtests/2026-10-03-quiet-yak.md), #505 to #508; the rigged bag, its sizes, nested bags
and the return patrols in [coral-bunny](../playtests/2026-10-04-coral-bunny.md), #561; the lesson dog
that is not paid for and day 3's two dogs in [feathery-stork](../playtests/2026-10-04-feathery-stork.md),
#566.)*

**What was built** (PR #565). `src/city/marble_bag.gd` is one generic bag that is a queue of bags:
ordinarily one, refilled when empty; a special bag goes in front and the interrupted one resumes with
what it had left, the poster pre-bag being the first such bag (poster tears draw exactly as before).
`rig()` makes the player's rigged bag: the ensured marble plus x-1 marbles taken out of the active bag,
leaving two bags of x and n-x+1 and creating nothing but the ensured marble. `rig_spaced()` is the
player's two-bag trick (a bag of N without the marble, then a bag holding it), built and tested and
used nowhere yet. A marble may itself be a bag (nested): drawing it draws from the inner bag, and the
bag marble goes straight back into the bag it was drawn from; its inner bag of n gives exactly n
events (the player, #566 in [feathery-stork](../playtests/2026-10-04-feathery-stork.md): "The inner bag becomes empty after n draws"), and the draw that empties it
takes the bag marble out for good, from every queued bag and the ordinary set, so no later fill
brings it back and a bag marble left last in its bag drains its inner bag and stops. A rig's x−1
are drawn, so one that reaches a bag marble draws from its inner bag and leaves the bag marble
where it is, and a rigged bag of x gives its ensured marble within x draws. Built and
tested, used nowhere on her route yet. `peek()` names the next marble without spending it, so a failed siting does not burn an event.

The dawn still decides how many events the day buys for her route, with the same weighted roll; the
route bag (`EventDirector`, `Tuning.ROUTE_BAG_MARBLES_PER_WEIGHT` = 2 marbles per unit of weight, on
its own stream) decides which row each is, for the rows the director sites (`AHEAD_OF_PLAYER`,
`TOWARD_PLAYER`). A row `Tuning.ROUTE_BAG_MARBLES_OF` names has the marbles it sets instead: day 3's
ordinary bag holds 2 charging dogs among 16 marbles (cat dash 5, loose dog 6, cyclist 3), set in the
bag rather than by the row's weight, which the dawn roll reads on every day (the player, #566 in [feathery-stork](../playtests/2026-10-04-feathery-stork.md): "if
we want to change the probability then we can change the bag -- I'd say we could do 2 dogs"; asked
whether 16 or 17, "16 is fine"). An ordinary row's `max_per_day` also caps what the director hands
out, its further marbles spent unmet; rigged marbles are exempt. After day 6's mark a man shouting is one of the next two events on her route
(`Tuning.TASK_CONTACT_WITHIN_THE_NEXT`), beyond where events are brought into the world and kept ahead
of her, beside the one feathery-marmot spawns near the mark. Day 11 keeps feathery-marmot's mast near
the mark, which the arrow points at, and rigs a second at x=2 onto her route, offered only ground
`MastSites._is_eligible()` accepts (off the home street, its field off a calm interior and off any
place a region door could stand, M180), the check the mast near the mark goes through. Each return patrol in
acts III and IV is a rigged bag of 2 (`Tuning.RETURN_PATROL_WITHIN_THE_NEXT`), a marble spent unmet at
its row's `max_per_day` counting against it so "within 2" holds: appended behind the queue before,
none of 120 landed over 48 return legs; now 66 do, and every leg meets one. Day 3's lesson dog is a
rigged bag of one put in front at dawn, and it takes nothing from the bag behind it (the player, #566 in [feathery-stork](../playtests/2026-10-04-feathery-stork.md):
"the first dog is a rigged bag with only one entry that is separate from anything that comes after" ·
"the lesson is not paid for. why would it be? that's not how the marble bag works"): the ordinary bag
keeps both its dog marbles, and the lesson stays the first event at its 6s delay.

**Measured** over 12 seeds and 9 days, a whole day of walking each (`tests/probes/olive_badger_route_mix.gd`):
the share of a day's route events that would have to change row to match the weights fell from 17.0%
to 10.4% on average (worst day 53% to 32%), and the longest run of one row from 2.79 to 2.56 on
average (worst 8 to 5); cat dash, loose dog and cyclist against their intended shares went from
+1.3%, −0.8% and −7.8% to −1.4%, −1.3% and −2.6%. Day 3's charging dogs, over 120 cities
(`tests/probes/olive_badger_day3_dogs.gd`): 2.29 met a day, the lesson and 1.29 after it, 40% of days
reaching the row's cap of 3, against 1.94 on `main` by the review's own probe on another seed set
(which measured 2.37 for this model). They rise from `main` because the old dawn roll bought dogs
below their weight's share (10.1% against 16.7%, the review measured) and left the dawn's other dogs
deep in a queue the pacing never drains; the bag holds them at its own share and hands them out from
the first marble.

**Proposed, not asked for, and open to overturn:** the rows the bag holds, and "any more the route
needs" read as the rigged places; two marbles per unit of weight; a rig moving owed events to the head
of the queue and topping it up; a rigged bag's other marbles taken from the next bag if the active one
runs short; "the inner bag becomes empty after n draws" read as an inner bag that never refills, even
one built with an ordinary set of its own; a drawn bag marble going straight back into its bag (the
player was offered back at once or back with the next outer fill and answered "The inner bag
becomes empty after n draws", which holds under both; back with the next fill is the alternative);
the day-3 rise in dogs against `main`; the day-13 roadblock
left unrigged, since a solid body on the branch she walks fights the walkability guarantees.
**Rejected:** the lesson dog's marble taken out of the ordinary bag so it is not counted twice, as first
built (3 dogs in a bag of 17, about 2.25 a day), which the player turned down in #566 ([feathery-stork](../playtests/2026-10-04-feathery-stork.md)); a day-3 bag of 5
then a bag of 1 with the dog, dropped by the player's "keep it first" (#561 in [coral-bunny](../playtests/2026-10-04-coral-bunny.md)); the route mast sited
under the dawn rules alone, where it could stand on the home street; the route mast's ground checked
against the mast-site rules tile by tile over the whole city, which froze the game for about 12s on
reading day 11's mark, replaced by asking only the tiles a siting is offered; a rig taking a bag
marble whole, which kept the rigged bag alive until its inner bag was spent and broke "within x".
**Not changed:** feathery-marmot's near-the-mark mast and the day-6 near-the-mark man shouting, which
must exist the moment she reads the mark, which a route marble cannot promise.
