**The marble bag keeps a queue of bags.** The player, on the overall design of a generic marble bag
class ([quiet-yak](../../playtests/2026-10-03-quiet-yak.md), #505 to #508):

> we should have a queue of marble bags -- normally it's just one and once its empty a new bag is
> created but for special events we can create a new bag with the desired distribution and then
> the current bag gets queue to be used again once the new bag is empty -- that's just a note on
> the overall design of a generic marble bag class

So the generic bag is a queue of bags: ordinarily one, refilled in its own proportions when it runs
empty; a special moment pushes a bag with its own distribution in front, and the interrupted bag
resumes, with what it had left, once the special one is empty. Asked about the type, the player
first said "so marble bags are list[set[T]]", then, told that a set cannot hold the same marble
twice, "right, list[list[T]]", and then "or list[dict[T, int]] if T is hashable -- whichever design
works best here -- you got the picture". The inner bag is a list of marbles or counts per kind, the
builder's choice. The bag that exists today is `src/city/marble_bag.gd` (PLAYTEST-125).

**Day 11's queued mast is one of the things this simplifies.** Feathery-marmot queues a mast near
her as the next event generated when none stands in reach of day 11's mark; the player said "this
will be simplified once we adopt marble bags for events as well" (#504). With events drawn from
bags, that mast is a special bag of one pushed in front of the route's bag.

**Proposed, not asked for:** that the "a yeller in the next three" bag in this entry's other item
is built as the same kind of special bag pushed in front, since the player's description of the
queue fits it.
