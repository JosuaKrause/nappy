priority: now
after: 2026-10-18-minty-quail

# grassy-beaver — A day one that teaches: hand-crafted, a park close by, thought bubbles, and the loss shown · filed 2026-10-24


**Why.** GoatCounter's read of 2026-10-19 to 2026-10-24 (`docs/stats/2026-10-24-goatcounter.md`):
10 fresh runs made 12 day-1 attempts and won 1, against 31% over the three weeks before, so new
players seem to stop on day 1; the one Reddit reply that reported playing said, in rough summary,
that from the starting block it could not tell which way led to calm ground. The player: "I agree
that we need a better day one experience but I don't think the "warm pavement" line is it", then
"we need a proper day one tutorial. we have a day 3 run tutorial which works well so I'm confident
we can pull it off for day 1, too", and "I deliberately don't focus on the pavement since the
pavement itself is an attempt to patch up issues from getting lost" (curly-moose #819). The day-3
run lesson is `docs/MECHANICS.md`'s "Nothing pursues before `RUN_TAUGHT_DAY`": the first pursuit of
day 3 moved to the head of the director's queue and one line said on the frame it telegraphs, once.

**What day 1 teaches.** The player listed (a) go to a park to get the baby sleeping, (b) avoid
objects that cause noise, (c) turn around at a dead end, (d) cross the street when one sidewalk is
blocked, (e) time the approach for moving obstacles, (f) not the same way every day (curly-moose
#819). Agreed after the research (the orchestrator's proposal; the player: "the rest sounds good",
curly-moose #819): **day 1 teaches (a), (b) and (d)**, as one sequence; (c) and (e) are day 2's
(`day-two.md`); (f) is learned on day 2 by construction.

**The research behind it** (an agent's survey of onboarding studies on 2026-10-24; the sources are
in the conversation's report, summarised here): in simple games tutorial text made a negligible
difference and players learned by trying; hints given at the moment they apply beat hints given up
front, and concrete beats abstract; a feature spread faintly over many kerbs does not stand out, and
a thing that starts moving catches the eye; landmarks at junctions cut navigation errors, distant
ones did not; players who blame their own mistake rate a game higher than players who blame the
game; guidance should fade as players improve.

**Not built, by the player's word:** a face over the pram or in place of the two bars ("I don't
want to add the face yet especially if also keeping the bars. I don't want the UI to be cluttered",
curly-moose #819); an NPC to follow (the chatting mother is already an obstacle, "so we don't need
two types with different purpose which makes it unclear whether approaching is good or not",
curly-moose #819); an opening shot on days 2 and on ("how would showing the park tell anything if
it's not placed anywhere via route?", curly-moose #819); a first-day line of text about the tinted
sidewalks.

**Text.** On-screen text only "when it becomes relevant otherwise players will forget and it will
make the intro a slog. we want to start right into the action" (curly-moose #819); the thought
bubbles (`thought-bubbles.md`) "might even make the text obsolete".

**Items:** `hand-crafted-day-one.md`, `thought-bubbles.md`, `the-loss-shown.md`,
`day-one-milestones.md`, `opening-shot.md` (an experiment), `junction-signs.md`, `day-two.md`.

*Proposed, not asked for:* built after minty-quail (one engine), since the director and the event
manager it orders are what the refactor is reshaping; the band `now`, since the player tied
cross-posting to day one being fixed (curly-moose #824). Open to the player's correction.
