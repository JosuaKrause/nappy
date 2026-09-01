# Playtest 17

Reported on 2026-08-31 and 2026-09-01, in five messages, during the session that built M52's calm
shapes. Not a played run: the player was reading **this session's own telemetry map** — seed 8000,
day 1, on `feature/the-calm-has-a-shape` at `7367ab0` — plus answers carried over from playtest 16's
build. The map is in the repo at
[evidence/run-2026-08-31T205921-seed8000-7367ab0-dirty-map-day01.png](evidence/run-2026-08-31T205921-seed8000-7367ab0-dirty-map-day01.png),
which is finding 10's rule applied to finding 1 on the way in.

**The wording below is the player's, verbatim.** Everything under a *"What this side reads into it"*
heading is this side's analysis and is kept apart from it on purpose.

**Twelve findings, in four groups.**

- **Three are about the day's corridor** and they are one sentence between them: *the corridor is
  the dangerous place and the rest of the map is the safe one*, which is upside down. One is a
  re-report of an item M50 left open with its own measurement, one is the player's own unprompted
  clarification of it — *"leaving the path should be lethal or very expensive… that is not as we
  planned"* — and the third is new, and is a rule about the shape of the corridor rather than about
  what is on it.
- **Three are about the resistance**, and they are the first design work anybody has asked for on
  it since it was built. One is a correction of what this side proposed, one is a task with a real
  risk in it, and one is a verdict on something that already happened by accident and should be
  made deliberate.
- **Two are about the telemetry** and both are about being able to trust it later: whose run a log
  is, and whether she was on the corridor at the time.
- **Four are small and specific**: the title lettering blending into the wall behind it, a diagonal
  seam where two edges of the world meet, a status check on playtest 16's finding 9 (answer: not
  started), and a process rule about where evidence lives.

---

## 1. Off the paths is the safe way round

> "looking at this map it appears that going off the paths let's me skip events and is safer than
> going on the path"

Sent with the day-1 telemetry map named above.

**What this side reads into it.** This is a **re-report**, and the entry it re-reports already
carries the measurement — `docs/TODO.md`, M50, "What this does not close":

> *"Blocking events all over" off the paths is not true yet, and it is a catalogue question. The
> gradient is built — very costly at the rim, deadly beyond it, with M28's clearance rule exempted
> off the corridor — but day 1 is still ~6× denser on the corridor than off it, and only 16.2 of
> its 113.6 placements are walls at all, because the expensive rows have low `max_per_day`. That is
> "a budget the catalogue cannot spend is not density" at the other end of the map, and raising
> those caps is a balance change that wants its own measurement.*

So the design is right and unbuilt, and the reason it is unbuilt is named: **the catalogue cannot
spend the budget.** Per `CLAUDE.md` — *"when a finding turns out to be a re-report, say so in the
entry and close it from the older one rather than writing a second design for it"* — this finding
does not get a second design. It gets M50's, and what it adds is the **evidence that the gap is
visible from outside**: it is no longer a number in a to-do, it is the thing a player concludes
from looking at a map of the day.

It also raises the stake, because it is not merely that off-corridor is *cheap*. The player's word
is **safer**, and a route-planning game whose one verb is *where do I walk* cannot have the answer
be "not where the day put anything".

## 2. Parallel paths need something between them

> "also if two paths go parallel add some blocking events between them"

**What this side reads into it.** New, and it is a rule about the corridor's own **shape** rather
than about what is placed on it — which makes it a `RouteTree` question, not a catalogue one. Two
strands of corridor running down neighbouring streets with nothing between them are not two routes
a player chooses between; they are one wide easy region, and the choice they were supposed to
create is not there. Something between them is what makes picking one of them a decision.

It is the same sentence as finding 1 from the inside: finding 1 says the corridor must be worth
more than the ground beside it, and this says two strands of corridor must be worth *different*
things from each other.

**Asked, because it overlapped `RouteTree`'s recorded instruction rather than merely extending it,
and answered on 2026-09-01:**

> "apply nuance here. sometimes put a blocker between (wall or event) and sometimes leave it open --
> this is not as important as going off the path completely. however, make sure the log notes a path
> switch correctly if it happens (technically it's leaving a path and entering a new path)"

> "only directly adjacent paths (with a single street connecting both) counts for this case
> obviously. everything further apart should just naturally be never connectable."

Three things settled, and the third one settles the contradiction rather than choosing a side:

- **Sometimes, not always.** *Wall or event* — either of the two costed words — and sometimes
  nothing at all. So this is not a rule that closes every gap; it is variety in what a gap between
  two strands is worth.
- **It ranks below finding 1.** *"Not as important as going off the path completely"*, which is the
  ordering for M55: the off-corridor cost first, this after it.
- **Only directly adjacent**, meaning a single street between the two strands. Everything further
  apart *"should just naturally be never connectable"* — which is the answer to the old instruction
  as well: once off-corridor ground costs what M50 designed it to cost, two strands that are not
  adjacent are separated **by the map** rather than by anything placed between them, and no rule
  about spacing is needed for them. The old sentence stands where it was about, which is the tree.

**And one thing was asked for that is not about the gap at all**: a switch from one strand to
another has to appear in the log, *"technically it's leaving a path and entering a new path"*. As
built, finding 6's `path` entry cannot see it — both strands answer `on` — so the trace calls a
route change no change at all.

**Done in M55**, both halves. The trace carries the branch colours, so a switch is a switch; and a
*gap* — one street with a strand of corridor crossing each of its two ends — is aimed at by the
day's closure quota and by a very costly wall, which leaves about half of the fifteen a day has
open. The measurement, and the one correction it needed, are in `docs/TODO.md` under M55; the design
is `docs/CITY.md`, "Two strands side by side, and the street between them".

## 3. Telemetry logs have to say whose run they are

> "one thing -- can you make telemetry logs be distinguishable whether they are from real playtests
> or your tests? otherwise it looks like a lot of plays happened when they were just regular tests.
> this skew statistics and muddies inferences we can do"

**What this side reads into it.** Exact and cheap, and the harm is the one named: the folder had
**163 runs** in it at the time of writing and almost all of them are `tools/shot.sh` and
`tools/check.sh` from this side. Anything counted over that folder — how often a day is lost, what
a run reaches, which events get met — is counted mostly over three-second screenshots taken at the
doorstep.

## 4. The title lettering blends into the wall behind it

> "another minor thing -- the start screen nappy can we make it have a black outline? right now the
> color blends in with the home entrance and apartment wall"

> "the outline I'm talking about is for the *font* of the *text* "nappy" from the title screen --
> _nothing else_!"

**What this side reads into it.** The word **Nappy** on the title screen — the 64pt label — set in a
warm colour over a doorway and brick of about the same value. A black outline on that label and
nothing else.

The second quote is a correction of this side, and it is recorded because the misreading is worth
more than the fix: *"the start screen nappy"* was read as the pram, on the reasoning that the game
is named after the thing she pushes, and an outline was put round the mother and the pram instead —
a change to a sprite everywhere in the game, from a sentence about one label on one screen. The
player's reply was *"not sure how you could interpret this in any other way"*, and they are right.
**The title screen has exactly one thing on it called "nappy", and it is the word.**

## 5. The bike, the fire engine and the rest still never arrive

> "checking in if you started the fix for bikes etal yet -- the bike still goes off in a completely
> unrelated direction and the most I ever see is the offscreen indicator. same with the fire truck"

**The answer is no, it is not started.** It is playtest 16's finding 9, recorded in `a05cec7` and
planned as part of M54, and the queue the player set put M52 and M53 in front of it.

**What this side reads into it.** Two things it adds to finding 9. The **fire engine** is named for
the first time, which matters because it is the most expensive row in the game (+115) and was not
in finding 9's list of three — so whatever is wrong is not specific to the small fast rows. And
*"the most I ever see is the offscreen indicator"* is a sharper statement of the defect than
finding 9's: the screen-edge badge is doing its job, announcing a thing that is lethal or fast and
closing, and then the thing it announced never arrives. A cue that is always followed by nothing
teaches the player to ignore it, which costs more than the missed encounter.

## 6. The telemetry should say whether she is on a path

> "make the telemetry record whether the player is on a path or not"

**What this side reads into it.** This is the instrument for finding 1, and it is asked for in the
right order: the corridor exists (`RouteTree`), the map draws it, and nothing in a *trace* has ever
said whether she was on it. Without it, "off the paths is safer" can be argued about and not
measured — and `docs/TELEMETRY.md`'s own rule is that an entry has to answer a question that is
open in `docs/TODO.md`, which this one does by name.

## 7. The resistance instructions are not a quest marker — and the first task

> "btw giving instructions on what to do next in the resistance plot is not a quest marker. that
> said, one task should be giving a note to a yeller. that is a risky move since the yeller causes
> the same level of excitement and there might be multiple candidates to test before finding the
> correct one"

**What this side reads into it.** The first half is a **correction of this side's own worry**. M54
recorded the day-brief instruction with an anxiety attached to it — that it edges toward the quest
marker the project rejected — and the player is saying plainly that it does not. Telling her what
the resistance wants next is not a marker on a map.

The second half is a **task design, in full, with its own risk model**, and it is worth taking
apart because every clause is doing work:

- The task is *give a note to a yeller*.
- The risk is that a yeller is **loud** — *"causes the same level of excitement"* — so the approach
  is paid for in the meter, and it is paid whether or not this is the right man.
- The uncertainty is that there are **several candidates** and only one is correct, so the cost is
  paid repeatedly, and the player cannot tell in advance which approach is the wasted one.

That is a genuinely different shape from anything in the game: every other cost is *avoidable by
routing*, and this one is a cost you take **on purpose**, several times, for progress. It is also
why it works — the resistance is optional, so its price has to be something a player chooses.

## 8. More tasks with a risk and a reward

> "let's think of more tasks like this that have a risk but reward you with resistance progress"

**What this side reads into it.** A design brief rather than a fix, and the pattern is stated in
the sentence: **a resistance task is a thing that costs you meter or safety on purpose, in exchange
for progress on the optional path.** Finding 7 is the worked example and finding 9 is the same idea
arriving from the other direction. It wants a list drafted and put back to the player rather than
built.

## 9. The robber beside the chalk mark was good

> "I did like the robber next to the chalk marking. that made it hard to actually get the chalk
> marking. pursuing the resistance should make the game harder like this"

**What this side reads into it.** A verdict, and it closes something. Playtest 16 reported the
resistance as invisible; this says the one moment of it that landed was the moment it was
**guarded**. That happened by accident — the scheduler placed a robbery where the chalk mark was —
and the finding is that it should be deliberate: *pursuing the resistance should make the game
harder*.

It is also the answer to a question M54 has open. The resistance note is to be *"placed dynamically
alongside a route"*, and what was unsaid is what should be near it. This says: something that makes
reaching it a decision.

## 10. Evidence lives in the repo

> "when referencing an image or log make sure to copy the files into the repo so the reference
> doesn't get lost when cleaning up. make sure all current references are in the repo so I can
> clean up the log folder"

**What this side reads into it.** A process rule, and it is the same rule as *"notes belong in the
repo"* applied to the things notes point at. `user://telemetry/` is a scratch directory the player
has to be able to empty; a finding whose evidence was only in there stops being checkable the
moment they do.

**Checked while writing this, and the cost is already paid**: of the three telemetry files the docs
currently reference, **none is still on disk**, against 163 runs that are. They are listed in
[evidence/README.md](evidence/README.md). They cannot be regenerated, because a run log records
what a *player* did and is not a function of the seed — replaying it gives a different run. The
numbers the docs quote from them stand; the files behind the numbers are gone.

## 11. The corners of the world go diagonal

> "at the corner of the map the mountain and sea textures should just continue not become diagonal
> (diagonal doesn't really make sense in this context)"

**What this side reads into it.** About the ring outside the lattice — M41's edge of the world, and
playtest 14's brief for what is out there: *"in the south there needs to be a bulkhead first then
water — no buildings — in the east and west there needs to be a fence, then grass and forest — in
the north there needs to be a mountainside."* Those are four **bands**, each running along one side,
and a band has to do something where two of them meet. Whatever `CityEdge` currently does there
reads as a diagonal seam, and the player's instruction is that there should not be one: each
texture simply carries on.

Worth noting what it is *not* asking for: no new terrain, no corner feature. It is the simpler
answer — the mountain keeps being mountain round the corner and the sea keeps being sea.

**Done in M55**, and it is `City._border_source` rather than `CityEdge`. A corner belonged to
whichever side it was further out of, and *further out of* is a comparison between two distances,
so the tie ran down a 45° line — the diagonal was the tie-break rather than a decision anybody
took. North and south own the corners now, so each band runs the full width of the map. Pictures
either side of it are in [evidence/README.md](evidence/README.md), taken with the `--spawn corner`
flag this needed and did not have.

## 12. Leaving the path is supposed to be lethal, and it is the opposite

> "also just to clarify the comment about leaving the path -- leaving the path should be lethal or
> very expensive. right now that is not the case, though. so the event density from the path gets
> *less dangerous* right now when leaving the path. that is not as we planned"

**What this side reads into it.** A clarification of finding 1, given unprompted, and it removes the
last bit of room the reading had. Three things are pinned by it:

- **The intended cost is *lethal or very expensive*, not merely "denser".** That is M50's own words
  — *"areas that outside the paths should have blocking events all over — we don't want the player
  to step in those areas and it ranges from very costly to deadly"* — restated, so the design is
  confirmed rather than revised.
- **The observed cost is the reverse**, and the mechanism is named exactly: the *density* is on the
  corridor, so stepping off it is a step into quieter ground. The bug is not that off-corridor is
  insufficiently lethal in isolation; it is that the two are the wrong way round relative to each
  other.
- ***"That is not as we planned"*** — so this is a build that does not match a design already
  agreed, which is the shape M50's own entry admits to. It is not a new decision to take.

**And one clarification came back on the fix rather than on the finding.** This side reported day 1
as still falling short, because day 1 has no lethal rows in it at all and so can only ever be *very
costly*:

> "day 1 blocks can be non-lethal. the wording always allowed that"

Which is correct and closes it: *"it ranges from very costly to deadly"* is a **range**, and a day
spending only its cheap end is spending the range. M31's decision that act I escalates by *kind* —
0, 3, 4 lethal events across days 1–3 — and M50's gradient were never in tension, and the note this
side wrote as an open shortfall was not one.

---

## One thing this side noticed on the same map, which is not a finding

Kept separate because the player did not report it. In the map above, the apartment complex at
block (5, 1) draws its four absorbed streets in **`DEAD_END_MARK`** — the teal cross inside the
green outline at the top of the picture. That is correct by construction (a complex's absorbed
streets are `built_over`, which is what the legend colours) and it is **wrong as a sentence**: a
complex is not a dead end, and the one picture whose whole job is to say what the day did now uses
one colour for two things. See `docs/TODO.md`, M52.
