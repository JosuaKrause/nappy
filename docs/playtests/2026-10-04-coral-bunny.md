# Playtest coral-bunny — Rigged marble bags, nested bags, and the return patrols

2026-10-04. One note captured in the session, #561, said in several parts while olive-badger (events
on her route drawn from marble bags) was being built. Each of the player's words is copied word for
word, after what it answered.

## #561 — A rigged bag: x marbles, the ensured one plus x-1 drawn from the active bag

Said on 2026-10-04 while olive-badger (events placed on her route drawn from marble bags; a queue of bags; after the day-6 mark "a bag of three marbles, one homeless_yeller and two drawn from the route's ordinary bag") was being built, and right after azure-beaver's "the marble bag should be rigged" for the task scenes.

> also when creating a new / rigged marble bag -- let's say you want to spawn in a yeller next: create a new marble bag with x holdings place the ensured item in the bag fill the remaining x-1 items by *drawing* from the currently active bag. x defines how soon we want to get the guaranteed event -- with the yeller I'd say x=4

Said on 2026-10-04 right after the rigged-bag rule above (x marbles: the ensured one plus x-1 drawn from the currently active bag).

> you will be left with two initialized bags: 1 with x elements and one with n-x+1 elements where n is the number of elements that were previously in the already loaded bag

Said on 2026-10-04 after the assistant listed candidates for rigged bags: (1) day 6's man shouting after the mark (being built, x=4); (2) day 11's mast, which feathery-marmot queues as the next event when no live mast is near the mark; (3) day 3's first pursuit that teaches running, a charging dog; (4) task targets riding on a street event: day 7's van, day 10's neighbor, day 13's roadblock; (5) the azure-beaver scenes; (6) the pelican, one cyclist in about 400 (a plain bag rather than a rigged one). Not candidates: the off-screen trap robber after a target, the day-3 fire.

> day 11 is going to be a x=3. day 3 have a 5 bag then a 1 bag with the dog. for the other cases find reasonable values of x. if you need guaranteed spacing use the day 3 trick otherwise just do the rigged bag directly
> another technique, for spacing things out, is a nested bag. a marble in a bag is itself a bag. when its drawn the bag marble gets drawn from and produces the actual event then the bag marble gets placed bag in the outer bag. this makes it very unlikely that two events from the inner bag happen right after each other

Asked on 2026-10-04, two questions. (1) "Day 3: today the run lesson's charging dog is the FIRST route event, fired about 6s into the walk (LESSON_DELAY). Your rule (a bag of 5, then a bag of 1 with the dog) makes it the sixth, about 60–130s in, so day 3 opens on five other events before the lesson. Which?" Options: "Dog sixth, as you said"; "Dog first, keep 6s (Recommended)"; "Dog in the first 3". The first line below is the player's own answer. (2) "Day 11: today the mast target is the nearest live mast at the 576px circle round the mark, or one put up there at once, so the red arrow has a target the moment she reads the mark (feathery-marmot: 'spawn close to the mark'). A rigged bag of x=3 hands it out only at the next route interval (11–26s of walking) and sites it on her route ahead, 900–2370px along, so for up to a minute there is no target. Which?" Options: "Keep near the mark (Recommended)"; "Rigged bag x=3". The second line below is the player's own answer.

> keep it first, then -- I didn't realize they were that sparse -- then maybe let's make the other rigged bags smaller, too
> let it point to the closest one first. the red arrow (in general) might switch if another closest one comes close (eg if the player chooses to ignore the task the red arrow keeps jumping to the closest ones on the other route) -- closest here always means path closeness not crow closeness

Said on 2026-10-04 after the assistant reported olive-badger's finding: the return patrols in acts III and IV are appended at the back of the director's route queue, behind about 19 entries she never reaches, so they in effect never land.

> The return patrols in acts III and IV are added at the back of the route queue -- the marble bag approach will properly fix this

Said on 2026-10-04 right after "The return patrols in acts III and IV are added at the back of the route queue -- the marble bag approach will properly fix this", when the assistant said the agent would make them marbles in the route bags, in their intended proportion or as a rigged bag where one must come soon after something.

> they will need rigged bags

## Routing

**#561** → built in the pull request that files it (olive-badger, PR #565): the generic bag as a
queue of bags with the rigged bag (x marbles: the ensured one plus x-1 drawn from the active bag,
leaving x and n-x+1), the spaced rig and nested bags; day 6's man shouting at x=2, day 11's second
mast at x=2 beside the near-the-mark mast, the day-3 dog kept first, the return patrols as rigged
bags of 2. What is left of "for the other cases find reasonable values of x" stays in
[olive-badger](../todo/2026-09-27-olive-badger/README.md). The arrow pointing at the closest instance
by path is [#562](https://github.com/JosuaKrause/nappy/issues/562), filed separately.
