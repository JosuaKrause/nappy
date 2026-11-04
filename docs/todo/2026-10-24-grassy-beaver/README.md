priority: now
after: 2026-10-18-minty-quail
after: 2026-10-24-lilac-marten
after: 2026-10-18-snowy-goose

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
curly-moose #819): **day 1 teaches (a), (b) and (d)**, as one sequence; (c) is day 2's ("dead end in day 2
sounds good as well", curly-moose #819, in `day-two.md`); where (e) goes is open there; (f) is
learned on day 2 by construction. On day 1's car losses the player: "traffic crossings are already
only where cars are stopped -- the issue comes from players who just run across the street"
(curly-moose #832), which `day-two.md` takes up.

**The research behind it** (an agent's survey of onboarding studies on 2026-10-24; the sources are
in the conversation's report, summarised here): in simple games tutorial text made a negligible
difference and players learned by trying; hints given at the moment they apply beat hints given up
front, and concrete beats abstract; a feature spread faintly over many kerbs does not stand out, and
a thing that starts moving catches the eye; landmarks at junctions cut navigation errors, distant
ones did not; players who blame their own mistake rate a game higher than players who blame the
game; guidance should fade as players improve.

**Set aside or not yet** (each with why, and what would bring it back, in the record
`docs/decisions/2026-10-24-leafy-lark.md`, with four ideas left undecided). **Not yet:** a face over
the pram or in place of the two bars ("I don't want to add the face yet especially if also keeping
the bars. I don't want the UI to be cluttered", curly-moose #819). **Dropped on the orchestrator's
proposal, which the player accepted with "the rest sounds good":** an NPC to follow, after the
player had said "following NPC let's explore that" and then "we already have a fellow mother but
she's an obstacle. so we don't need two types with different purpose which makes it unclear whether
approaching is good or not" (curly-moose #819). **Set aside by the player:** an opening shot on days 2
and on ("how would showing the park tell anything if it's not placed anywhere via route?",
curly-moose #819); a first-day line of text about the tinted sidewalks.

**Text.** On-screen text only "when it becomes relevant otherwise players will forget and it will
make the intro a slog. we want to start right into the action" (curly-moose #819); the thought
bubbles (`thought-bubbles.md`) "might even make the text obsolete".

**Items:** `hand-crafted-day-one.md`, `car-free-start.md`, `thought-bubbles.md`,
`the-loss-shown.md`, `opening-shot.md` (an experiment), `junction-signs.md`, `day-two.md`. The
GoatCounter events measuring day one are their own entry, filed ahead of this one so a window
before the change exists ([tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #927: "yes, split").

**After the escape.** The player: "the task is clear refactor then escape then tutorial"
(minty-dolphin #852), and earlier "the escape and day one fixes can go after the refactor"
(minty-dolphin #830). **Read as:** this entry waits for minty-quail (the refactor) and for the
escape's fixes, lilac-marten (its fuller escape, with that entry's other two items) and snowy-goose
(explosions in the escape city), which its `after:` lines say.

*Proposed, not asked for:* the band `now`, since the player tied cross-posting to day one being
fixed (curly-moose #824); waiting for lilac-marten's charger timing and total time as well as its
fuller escape, since they are one entry. Open to the player's correction.
