priority: next
after: 2026-10-18-minty-quail

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

**Read as:** how many streets close is drawn from a marble bag like the route events, in place of
a fixed quota, since the question was about the count of 120. Nothing about it is designed or built until
minty-quail (the refactor) is done; it is planned then, with the player.

**Open, for that planning:** whether the closures' kinds come from the bag too, in place of their
independent roll (the orchestrator's pick on the board, closures-bag, was both); what the bag holds; and how it sits with the closures' dawn phase.

*Proposed, not asked for:* the band `next`, after minty-quail, since the player tied the planning to
the refactor's end and named no band.
