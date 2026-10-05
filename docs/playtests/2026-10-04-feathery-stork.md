# Playtest feathery-stork — The lesson dog is not paid for, and day 3's bag holds two dogs

2026-10-04. One note captured in the session, #566, said in several parts while the review on
olive-badger (events on her route drawn from marble bags, PR #565) was being answered. Each of the
player's words is copied word for word, after what it answered.

## #566 — The day-3 lesson dog is a rigged bag of one, separate from what comes after

Said on 2026-10-04 after the assistant explained why olive-badger's route bag raised day 3's
charging dogs from 1.75 to 2.25 on average (12 seeds): the bag holds every route row at its
weight's share, and the lesson dog's own marble is taken out of the bag so it is not counted twice;
whether the old weighted roll under-delivered dogs was not confirmed.

> but the first dog is a rigged bag with only one entry that is separate from anything that comes after

Said on 2026-10-04 after the assistant laid out day 3's ordinary route bag (17 marbles: loose dog 6,
cat dash 5, cyclist 3, charging dog 3) and the counts: before the bag about 1.75 charging dogs on
day 3; PR #565 as built, where the lesson dog's marble is taken out of the ordinary bag, about 2.2;
the player's model (the lesson its own rigged bag of one, taking nothing), about 2.8; and asked
whether to lower the charging dog's day-3 weight or leave it out of day 3's ordinary bag.

> the lesson is not paid for. why would it be? that's not how the marble bag works

Said on 2026-10-04 after the assistant said that with the lesson free, day 3 averages about 2.8
charging dogs against 1.75 before, and that the knob is the charging dog's day-3 weight (3 of the 17
marbles).

> if we want to change the probability then we can change the bag -- I'd say we could do 2 dogs -- we don't need the charging dog that often and in 17 rolls there are two guaranteed ones

Asked on 2026-10-04, two questions. (1) "Day 3's route bag with 2 charging dogs holds 16 marbles:
loose dog 6, cat dash 5, cyclist 3, charging dog 2 (you said 'in 17 rolls there are two guaranteed
ones'). Measured over 120 day-3s, the lesson dog free plus 2 in the bag gives about 2.4 dogs a day
(main today: 1.9). Keep 16, or make it 17?" Options: "16 is fine (Recommended)"; "17, one more
cat"; "17, one more cyclist". (2) "Nested bags (a marble that is itself a bag): you said the bag
marble 'gets placed back in the outer bag' after it is drawn. Read literally, it goes back into the
same bag at once, so a bag marble that is the last one left would be drawn forever. As built, it
comes back with the outer bag's next fill, so it is drawn at most once per outer bag. Nothing uses
nested bags yet. Which?" Options: "Back with the next fill (Recommended)"; "Back in at once". The
first line below is the option the player picked for (1); the second line is the player's own
answer to (2).

> 16 is fine (Recommended)
> The inner bag becomes empty after n draws

## Routing

**#566** → built in olive-badger's pull request (PR #565), which files it: day 3's lesson dog is a
rigged bag of one in front of the route bag, taking nothing from it, and stays first at its delay;
day 3's ordinary route bag holds 2 charging dogs among 16 marbles (`Tuning.ROUTE_BAG_MARBLES_OF`);
a bag marble goes straight back into the bag it was drawn from, and its inner bag of n gives n
events and is then gone. The record is
[olive-badger](../decisions/2026-09-27-olive-badger.md).
