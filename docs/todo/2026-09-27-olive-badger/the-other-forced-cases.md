# Day 7's van gets a second instance on her route, from a rigged bag

**Day 7's van gets a second instance, drawn on her route from a rigged bag of 2.** Today the
resistance director places it at the moment she reads the mark, spawned live on the 576px circle
round where she read it. That one stays as it is; the rigged bag adds a second van on the branch of
the day's routes she is walking, placed the way day 6's man shouting and day 11's second mast are
(`docs/EVENTS.md`, "The bag is a queue of bags, and a bag can be rigged": `MarbleBag.rig()` through
`EventDirector.rig_her_route()`, sited by `EventScheduler.WalkSiting.ahead_of()`).

The player's answers. Asked whether day 7's van, day 10's neighbor and day 13's roadblock should
each get a second, route-drawn instance and with how many marbles (inbox #586 in
[olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md)):

> each olive badger rigged bag should be 2 or 3. use your own judgement on how soon the events should happen

That follows the player's earlier "for the other cases find reasonable values of x. if you need
guaranteed spacing use the day 3 trick otherwise just do the rigged bag directly" and "maybe let's
make the other rigged bags smaller, too" (#561 in
[coral-bunny](../../playtests/2026-10-04-coral-bunny.md)). Asked, with the context, whether that
meant all three or the van alone, and told that rigging the roadblock would overturn the
[olive-badger](../../decisions/2026-09-27-olive-badger.md) record's "the day-13 roadblock left
unrigged" (inbox #650 in [mossy-beaver](../../playtests/2026-10-10-mossy-beaver.md)):

> yeah let's not rig the roadblock let's place one properly and guide to that -- just make sure it's closeby
>
> day 10's neighbor had its own route anyway, no? I guess that leaves only the van?

So **the roadblock stays unrigged**, and the record's choice stands; its placement close by and the
arrow guiding to it are filed with day 13's arrow, calm-pelican's
[the-arrow-and-the-day-13-guard](../2026-10-10-calm-pelican/the-arrow-and-the-day-13-guard.md).
**The neighbor gets none**, read as the player's "I guess that leaves only the van?" and open to
correction: day 10's neighbor is a scripted walker sent home along his own way from the mark, which
the filer takes to be the route the player means, so a second, route-drawn one adds nothing.

*Proposed, not asked for:* **the size, x=2** (the orchestrator's judgement, which the player's "use
your own judgement" asked for, inside their "2 or 3"). It is one `Tuning` constant beside
`Tuning.TASK_CONTACT_WITHIN_THE_NEXT` and `Tuning.MAST_WITHIN_THE_NEXT`, with a test that the van's
marble is among the next 2 handed out on her route after the mark and that the van is then put on
her route. `docs/EVENTS.md`'s list of the rigs that stand gains it.
