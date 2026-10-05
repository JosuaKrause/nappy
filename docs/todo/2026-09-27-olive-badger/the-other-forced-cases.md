**Day 7's van, day 10's neighbor and day 13's roadblock each get a second instance, drawn on her
route from a rigged bag of 2 or 3.** Each is placed today by the resistance director at the moment
she reads the mark rather than drawn on her route: day 7's van and day 13's roadblock spawn live at
the 576px circle, and day 10's neighbor is a scripted walker sent home. That one stays as it is;
the rigged bag adds a second instance of the same thing on the branch of the day's routes she is
walking, placed the way day 6's man shouting and day 11's second mast are (`docs/EVENTS.md`, "The
bag is a queue of bags, and a bag can be rigged": `MarbleBag.rig()` through
`EventDirector.rig_her_route()`, sited by `EventScheduler.WalkSiting.ahead_of()`).

The player's answer, asked whether each should get a second, route-drawn instance and with how many
marbles (inbox #586 in [olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md)):

> each olive badger rigged bag should be 2 or 3. use your own judgement on how soon the events should happen

That follows the player's earlier "for the other cases find reasonable values of x. if you need
guaranteed spacing use the day 3 trick otherwise just do the rigged bag directly" and "maybe let's
make the other rigged bags smaller, too" (#561 in
[coral-bunny](../../playtests/2026-10-04-coral-bunny.md)).

**It replaces a choice the record made.** The olive-badger record
([2026-09-27-olive-badger](../../decisions/2026-09-27-olive-badger.md)) lists among its choices "the
day-13 roadblock left unrigged, since a solid body on the branch she walks fights the walkability
guarantees". The player's "each olive badger rigged bag" covers the roadblock too, so it is rigged,
and the roadblock on her route keeps every walkability guarantee in **city**: it is checked before
it is accepted, never repaired afterwards, the day stays winnable and the route-redundancy
guarantee holds with it on the street.

*Proposed, not asked for* (the orchestrator's judgement, which the player's "use your own judgement"
asked for): **day 7's van x=2**, **day 10's neighbor x=3** and **day 13's roadblock x=3**. Each
size is one `Tuning` constant beside `Tuning.TASK_CONTACT_WITHIN_THE_NEXT` and
`Tuning.MAST_WITHIN_THE_NEXT`, with a test that the instance comes within that many events placed on
her route after the mark. `docs/EVENTS.md`'s list of the rigs that stand gains the three.
