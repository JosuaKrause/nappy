priority: next
after: 2026-10-18-minty-quail
after: 2026-11-11-polite-tapir

# golden-newt — Road closures from a bag, planned after the refactor · filed 2026-11-09

**The ask.** Told that the street closures counted 120 before and 120 after a change, over 60
seed-days, the player asked "How do you control 120? It should be a bag, no?", and, while the
orchestrator was writing up dawn's phases on the board and had just asked whether road closures'
count and kinds come from a marble bag, "Let's not make any changes to the process yet. We will plan
after the refactor is done" (gentle-owl #1189).

**What the code does** (as the note's context gave it on 2026-11-07): the count of closures is a fixed
quota a day, not a bag: `Tuning.CLOSURES_PER_ACT` by act, of which `ClosurePlanner.closures_wanted()`
keeps `GATEHOUSE_DAY_CLOSURE_SHARE` from day 9, so 2 a day on days 9 to 14. Which streets close is a
seeded weighted shuffle of the candidates, and each closure's kind (roadworks, a crash, a cordon,
rubble, a fallen tree) an independent weighted roll (`ClosurePlanner._pick_kind`). The route events
are drawn from a marble bag (`docs/EVENTS.md`, "What she meets on her route is drawn from a marble
bag"). A builder re-reads this, since the refactor changes how dawn plans the day: the closures are one
of the city's fixed parts, with a phase of their own (`docs/EVENTS.md`, "The three views and the
placement order").

**Read as:** road closures are to come from a bag, as the route events do, in place of a fixed
quota. Nothing about it is designed or built until minty-quail and polite-tapir (the refactor) are done; it is planned
then, with the player.

**Open, for that planning:** what "a bag" means here: either the count of closures a day is drawn
from a bag as a number, or the closures are drawn like any event, from a view's bag, with the count
falling out of the draw, as placement by construction's bags work, the closures having a phase of
their own (gentle-owl #1185). Also whether the closures' kinds come from the bag in place of their
independent roll (the orchestrator's pick on the board, closures-bag, was the count and the kinds
both); what the bag holds; and how it sits with the closures' dawn phase.

*Proposed, not asked for:* the band `next`, after minty-quail and polite-tapir, since the player tied the planning to
the refactor's end and named no band.
