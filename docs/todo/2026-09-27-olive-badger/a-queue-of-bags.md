**The marble bag keeps a queue of bags.** The player, on the overall design of a generic marble bag
class ([quiet-yak](../../playtests/2026-10-03-quiet-yak.md), #505 to #508):

> we should have a queue of marble bags -- normally it's just one and once its empty a new bag is
> created but for special events we can create a new bag with the desired distribution and then
> the current bag gets queue to be used again once the new bag is empty -- that's just a note on
> the overall design of a generic marble bag class

So the generic bag is a queue of bags: ordinarily one, and a new bag is created once it is empty;
a special event creates a bag with the desired distribution, and the current bag is queued to be
used again once the new bag is empty. Asked about the type, the player
first said "so marble bags are list[set[T]]", then, told that a set cannot hold the same marble
twice, "right, list[list[T]]", and then "or list[dict[T, int]] if T is hashable -- whichever design
works best here -- you got the picture". The inner bag is a list of marbles or counts per kind, the
builder's choice. The bag that exists today is `src/city/marble_bag.gd` (PLAYTEST-125).

**Day 11's queued mast is to be simplified by the bags.** Feathery-marmot queues a mast near her as
the next event generated when none stands in reach of day 11's mark; the player said "this will be
simplified once we adopt marble bags for events as well" (#504). How is not said.

**Proposed, not asked for:** that the new bag is refilled in the same proportions as the one before
it, and that the queued bag resumes with the marbles it had left; that day 11's mast becomes a
special bag of one in front of the route's bag, which would take the bags past this entry's scope
(events placed on her route only), so it is a question for the player before it is built; and that
the "a yeller in the next three" bag in this entry's other item is the same kind of special bag.
