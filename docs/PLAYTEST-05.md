# Playtest 05 — the street reads wrong, and nothing is dangerous yet

The fifth human playtest, taken after M22 and M27 landed and **before the milestones the last
two playtests actually asked for**. The player said so up front: *"I played again (even though
the main requested changes haven't landed yet)"* — so this is not a verdict on the calm areas
(M21) or on the map (M17), neither of which exists yet.

**Status.** Finding 6 is **done — M28**, and it is the only one that is. The rest are unchanged
and unstarted; see the status line under each heading.

---

## The five things

In the order they were said.

| # | What was said | First read |
| --- | --- | --- |
| 1 | *"The cars stop at weird positions for the zebra crossing. Sometimes half a block away, sometimes **on** the crosswalk."* | Nothing anchors a car's stop to the stop line — it brakes where it happens to be |
| 2 | *"The cars are not consistently driving on the right side."* | Real and derivable from the code: the two axes drive on opposite sides |
| 3 | *"Sometimes I get yellow exclamation marks on top of my head without any indication where from, and it doesn't actually have an effect on gameplay — I can just keep doing what I was doing."* | The cue fires for things that are neither lethal nor attributable to a visible entity |
| 4 | *"I was able to go to the same park on day one and two — this shouldn't be possible."* | M24, queued and unstarted. The player has now asked for it, which is what moves a milestone |
| 5 | ***"Day two doesn't feel more difficult than day one. Having day one relatively easy is okay *if* the difficulty increases. But right now there is never *any* danger."*** | Correct by construction, and measurable: day 2 is day 1 plus one event, and **nothing lethal exists before day 8** |
| 6 | ***"I want one event *per* block. The dog walker decision should happen meaningfully — I want to have to make that decision at least twice on day one. Also the same with a restaurant — I never saw one."*** *(and, asked about repetition: "it's fine if the same event happens multiple times")* | A stated density target: **~4× the current plan**, blocked by the per-type caps rather than by the budget |

Findings 3 and 5 are the same complaint arriving from two directions, and 5 is the emphasised
one: the mark over her head means nothing partly because there is nothing for it to mean yet.
Finding 6 is the number that finding 5 was missing, given afterwards and deliberately concrete.

---

## Finding 1 — a car stops where it noticed, not where the line is

> **Done — M29.** A car now brakes toward the **stop line** — `CAR_STOP_LINE_SETBACK` before the
> paint, measured to its centre so its nose ends up clear — on a gentle approach rate that keeps
> the easing visible from the kerb, with `CAR_BRAKE` held in reserve. A car too close to stop
> commits and clears the crossing instead. Two things the fix turned up that the analysis below
> did not predict: shaping the approach with `CAR_BRAKE` makes the onset of braking and the
> commit point the *same instant*, so no car ever stops; and the crossing scan sampled world
> points every 32px, which aliases exactly when a car is stopped at the line, so it lost sight
> of the zebra and pulled away with somebody on it.

> The cars stop at weird positions for the zebra crossing. Sometimes half a block away,
> sometimes *on* the crosswalk.

**What the code does today.** `CrowdAgent._give_way()` asks
`_somebody_is_waiting_to_cross()`, which scans forward up to `CAR_ZEBRA_SIGHT` (200px, ~6
tiles) for a `CROSSING` tile with the player within `CAR_ZEBRA_WAIT_RADIUS` (56px) of it along
the street. If there is one, the wanted speed becomes **0** and the car brakes at `CAR_BRAKE`
(320px/s²) *from wherever it is standing*.

So the stop position is not a position at all — it is wherever the braking curve happens to
run out:

- **Half a block away.** `Tuning` states the relationship deliberately —
  `CAR_ZEBRA_SIGHT > CAR_SPEED.y² / (2·CAR_BRAKE)`, *"a car always has room to stop for a zebra
  it can see, so giving way is never a screech."* That guarantees room **with margin**, and the
  margin is exactly the gap the player is describing. The rule was written to prevent a screech
  and it has no opinion about where the car ends up.
- **On the crosswalk.** There is no rule saying *do not stop on the crossing*, and no
  commit-point rule saying *if I am too close to stop before it, clear it instead*. A player
  who arrives at the kerb while a car is already on the paint gets a car parked on the paint.

**Why it is worse than it sounds.** The zebra is one of two things standing in for a telegraph
in the traffic fairness contract (`CLAUDE.md`, "The traffic fairness contract"): *the painted
carriageway, which is permanent and learnable*. A car halted on the paint is scenery by
`CAR_STRIKE_MIN_SPEED` — it cannot run anybody over — but it is **unreadable** scenery: it
occupies the one place the game has told the player is the safe way across, and it gives way
by stopping somewhere that does not look like giving way.

**What a fix has to decide, and it is a design question, not a number.** Where is the stop
line? Giving way has to stay *visible from the kerb* — that is why the braking starts at
`CAR_ZEBRA_SIGHT` rather than at the line, and that reason survives. What is missing is a
target: brake **towards a point** a fixed distance before the crossing rather than towards
zero speed, plus a commit rule for a car already too close to stop cleanly. Both are
`CrowdAgent._give_way()` and neither touches the meter.

---

## Finding 2 — the two axes drive on different sides

> **Done — M29, and the derivation below was exactly right.** `road_direction()` takes the axis
> now and has an inverse, `road_lane()`, so the two can never drift; the city drives on the
> right on both axes. The test nobody had written exists: for both axes and both directions,
> the lane a car is in is the one on its own right, checked against the rule *and* against every
> live car in a real day. The pedestrians were checked too — see the note at the end.

> The cars are not consistently driving on the right side.

**This one falls out of reading `CrowdLanes`, and it is the strongest lead in this document.**
It has not been confirmed against a run, so confirm it first — but the derivation is short:

```
ROAD_OFFSETS  = [2, 3]                     # the two carriageway lanes, across the corridor
road_direction(offset) = +1 if offset == 3 else -1   # +1 runs along the axis
lane_centre(index, offset) — larger offset = larger coordinate on the cross axis
```

- **A horizontal corridor.** Along-axis is `x` (+1 = east), cross-axis is `y` (larger offset =
  further **south**). So eastbound traffic runs in the southern lane. Facing east, south is on
  your right. **Right-hand traffic. Correct.**
- **A vertical corridor.** Along-axis is `y` (+1 = south), cross-axis is `x` (larger offset =
  further **east**). So southbound traffic runs in the eastern lane. Facing south, east is on
  your left. **Left-hand traffic.**

One convention per axis, and the two conventions are opposite. It is invisible to every test
in the suite because nothing asserts a *side* — the tests assert separation, headway, capacity
and noise, all of which are true either way — and it is invisible in a still screenshot,
because a stopped frame does not say which way a car is pointing. It shows up the moment a
human watches a junction, which is what happened.

The comment in `CrowdLanes` — *"traffic on 3 runs the positive way along the axis and traffic
on 2 runs the negative way, **which is the convention the whole crowd drives on**"* — is
consistent with itself and is the bug: it is a convention stated over the *offset*, when the
thing that has to be consistent is the **side of the road relative to travel**, which flips
with the axis. Fixing it means `road_direction()` needs to know the axis, and the test that
should exist is the one nobody wrote: *for both axes, the lane a car is in is on its own right*.

**Check the pedestrians too, while in there.** The same mirroring logic covers
`SIDEWALK_OFFSETS` and `nearest_sidewalk()`, and walkers have no side convention at all — if
they are also mirrored, it will read as the same wrongness at half the speed.

*(**Checked in M29: they are not mirrored, they are unordered**, which is a different thing and
not this bug. A walker picks any of the four pavement lanes and either direction, so there is no
convention to be inconsistent about. Giving them one was deliberately not done in the same
milestone: it is a design change with a measured cost, since M19's contact numbers — eleven
bumps down a lane centre against one on the midline — are what the pavement is balanced on and
they assume somebody may be coming the other way in any lane.)*

---

## Finding 3 — a mark over her head that points at nothing and costs nothing

> **Done — M30, and the design question below was answered "this will end your day".** The mark
> is raised only by a `hard_fail` event and by a car closing on her; everything else is left to
> the meter, which already says it continuously and proportionally. And the traffic pays for its
> own warning now: a car sounding its horn draws the same doubled lethal caret a `hard_fail`
> event does, breathing with the horn's decay. The shape moved to `Sprites.draw_caret()`.
>
> The accepted cost is stated rather than hidden: acts I and II contain nothing lethal, so the
> mark is nearly silent before day 8. That is the cue being honest about finding 5 rather than
> covering for it.
>
> One thing the analysis missed and the fix exposed: the caret was a **private method on
> `EventInstance`**, so "the entity carries its own cue" silently meant "the *event* entity
> does". A vocabulary written as one class's private method has an invisible edge, and the one
> lethal thing that is not in the catalogue fell off it.

> Sometimes I get yellow exclamation marks on top of my head without any indication where
> from — remember the main indicator should be the entity itself — and it doesn't actually
> have an effect on gameplay, I can just keep doing what I was doing.

This is the cue `CLAUDE.md` calls the load-bearing one: *every other cue says a thing exists;
that one says the fairness contract is now about you and the clock has started, which is the
difference between information and instruction.* Both halves of the complaint say it is not
currently doing that job.

### Half one: it is not attributable

Two systems raise it, and they have different problems.

- **Traffic** (`Crowd._process`, via `_horn()`). Raised whenever she is standing on the
  carriageway with a car closing. **Cars carry no entity-side cue at all** — the caret is drawn
  by `EventInstance`, and a car is not an event. So the traffic case is the mark over her head
  and *nothing else anywhere*: the vocabulary's first row, "the entity itself carries most of
  it", is not paying for this one. The horn is meant to, and the horn is currently silent in a
  game with no audio, which is the *"audio is never the only channel"* rule failing in the one
  place the contract depends on it.
- **Events** (`EventManager._warn_about_the_ground_she_is_on`). Raised when a telegraphing
  event's **`outer_radius`** covers her. Those radii go up to 340px, so the entity responsible
  can easily be off-screen — and the screen-edge badge deliberately only announces what is
  *lethal or faster than a walk*, so for an ordinary telegraphing event there is nothing at the
  edge either. She is told the clock has started and given no way to find the clock.

### Half two: it promises a consequence that mostly does not exist

`Stroller.Alert.SOON` is raised for **any** telegraphing event whose radius covers her,
lethal or not. For a `hard_fail` event that is a real instruction: stay and the day ends. For
the other fifteen-odd it means *a number is about to move faster*, and the meter already says
that continuously and proportionally. So "I can just keep doing what I was doing" is not a
misreading by the player — **it is accurate for most of the events that raise it.**

The caret over an entity got this exactly right and the mark over the player did not. The
caret's rule is *danger that changes over time* — telegraphing, lethal, pulsing, swelling —
arrived at after a first pass keyed on loudness marked three rows of scenery and a test caught
it. The player-mark's rule is *any telegraph that reaches her*, which is the same mistake in
the same shape: **a cue that marks everything says nothing**, and this is the one cue in the
game that cannot afford it.

The `EventManager` doc comment already argues the boundary — *"what is deliberately not warned
about: a loud event she is merely near… a mark that fires for ordinary noise is a mark nobody
reads by day three"* — and then draws the line at the telegraph rather than at the
consequence. The player read it by day one.

**What a fix has to decide.** Which is it: the mark means *this will end your day* (raise it
only for `hard_fail`, and let the meter speak for everything else), or the mark means *this
spot is about to get expensive* (keep the current trigger, and then it needs to be worth
obeying — which is a mechanic, not a threshold). Those are different games and the choice is
the design decision. What is not in question is that the traffic case needs an entity-side cue,
because *how dangerous a thing is has to be visible from looking at the thing.*

---

## Finding 4 — the same park twice

> **Done — M24**, and the shape of the fix is the one predicted below: the day reads where she
> settled and spoils *that* block, and the usable-park rule then guarantees a different one.
> Measured over five seeds and a whole run, the chance that the quietest calm block today is the
> same as yesterday's goes from **28% of days to zero**.
>
> One thing the analysis got wrong, and it matters: *"the telemetry already records the raw
> material… M24 was always going to read those."* It must not, and it does not. A gameplay rule
> that reads a trace is the telemetry invariant broken in the loudest possible way — the game
> would play differently with `--no-telemetry`. `GameState.settled_in` is its own record,
> written by `DayController` when the baby goes under. Where a trace and a rule want the same
> fact, the rule keeps its own copy.

> I was able to go to the same park on day one and two — this shouldn't be possible.

**This is M24, and it is queued and unstarted**: *"the city remembers where you went — spoil
the park you relied on yesterday."* So the honest answer is that the game does not have the
mechanism yet. What this finding changes is its priority: it is no longer a designer's idea
about replayability, it is a player noticing that **the game's only verb stopped being a
decision on day two.**

Worth being precise about why it is not merely "unbuilt". The machinery is closer than it
looks and points the wrong way today:

- **M15 gave every block a planned purpose arc**, so a park *can* be requisitioned, go dark or
  burn — but only along the arc the generator planned at dawn of the run, which knows nothing
  about where the player actually went.
- **`_ensure_one_usable_park` guarantees at least one unspoiled park every day.** That
  guarantee is right and must survive; it is what keeps a day winnable. But it says *at least
  one*, and nothing anywhere says *not the one she used yesterday*.
- **The telemetry already records the raw material.** The `calm` entries say where she settled
  and for how long. M24 was always going to read those; the handoff has said so since M23.

So the shape of the fix is: the day's plan reads yesterday's `calm` outcome and spoils *that*
block, and `_ensure_one_usable_park` then guarantees a different one. The invariant that has to
be checked at the same time is the M16 one — **two distinct routes to two distinct calm areas**
— because spoiling the good park is exactly the move that could leave the day with one.

---

## Finding 5 — nothing is dangerous, and the numbers say so

> Day two doesn't feel more difficult than day one. Having day one relatively easy is okay
> *if* the difficulty increases. But right now there is never *any* danger.

**The player is right by construction, and two facts in the code say it outright.**

**Fact one: day 2 is day 1 plus one event.** `EventScheduler.budget_for()` is
`17 + floori(day * 1.9)` — day 1 is 18, day 2 is 20 — and about a third of a budget is spent on
events the day then throws away (`_ensure_one_usable_park` strips whatever reaches the calmest
block, `_ensure_the_city_is_still_walkable` drops sealing obstructions). So day 2 places
roughly **one more event than day 1**, across a 104×104 city, of which M27 streams only three
or four into existence around her at any moment. That is not an escalation a human can feel; it
is not really an escalation at all.

**Fact two: acts are four days long, and nothing lethal exists in the first two.**
`ACT_START_DAYS = [1, 4, 8, 12]`, so days 1–3 are the same act, and the catalogue's `first_day`
values cluster on act boundaries (two events at day 2, one at day 3, two at day 4, two at day
8, two at day 12). Day 1 → day 2 unlocks `busker` and `construction`. Neither is a hazard.

And the sharper version of the same fact: **every `hard_fail` event in the catalogue starts on
day 8 or later** — `abduction` (day 8), `alley_robbery` (day 8), `firefight` (day 12). Before
day 8 the *only* lethal thing in the game is a car, which lives on the carriageway, which the
player is never obliged to step onto. So *"there is never any danger"* is not an impression: for
the first seven days of a fourteen-day run it is **a description of the catalogue.**

That is also why finding 3 lands the way it does. The exclamation mark is the cue that says
*the contract is now about you* — and in act I there is essentially nothing it could truthfully
be about, so every time it fires it teaches that it means nothing.

### What this does and does not say about the balance work

It does **not** say the meters are wrong. Excitement arithmetic, the walking decay and the calm
gain were re-pitched in M14 against the day and M19/M27 gave the street real cost — M22's own
measurement is that walking north up the arterial loses day 1 in fourteen seconds. **The street
is expensive. It is not dangerous.** Those are different axes, and this finding is about the
second one:

- **Expensive** = the meter moves, you lose ground, you re-plan. The street has this now.
- **Dangerous** = something can take the day away from you, and you can see it coming and act.
  Before day 8 the catalogue has one source of this and it is optional to approach.

**Decision 9 from playtest 02 is the thing being cashed in here** — *"the beginning is
challenging too: a player who never meets danger never learns to deal with it"* — and it has now
been asked for twice more, by a human, in the terms the decision was written in. The handoff
already flagged the risk in the opposite direction (*"whether act I now costs too much is the
open question"*); the answer coming back is that cost is not the axis that was missing.

**What a fix has to decide.** Not a constant. Three candidate shapes, none of them free:

1. **Move something lethal earlier**, with its telegraph intact. The fairness contract already
   makes this safe to attempt — `validate_event()` refuses an unfair one on load — but "act I
   has an abduction in it" is a narrative decision as much as a difficulty one.
2. **Make the existing act I hazards actually hazardous** — the carriageway is lethal and
   avoidable; something that *comes to her* is the M25 shape (patrols, and running that
   matters), which is queued and is explicitly written as a mechanic to build rather than a
   number to tune.
3. **Escalate within an act, not only between them.** `budget_for()` and four-day acts mean the
   step from day 1 to day 2 is invisible. If difficulty is supposed to be felt day over day,
   something other than event count has to move.

Whichever it is, it is a milestone and not a tuning pass, and the measurement to judge it by
already exists: `near` entries per day and `lost` lines, read against these two facts.

---

## Finding 6 — the density target, stated as a number

> **Done — M28.** Day 1 places **50 events across 49 blocks** (against 13), about eleven live
> around her at once (against 1.8) and **3.3 on screen** while she walks (against ~1). A café is
> seen three times on a short errand where it used to be seen not at all. The caps moved first
> and the budget followed: `budget_for` is `69 + day × 6.2`, and the day-1 pool's caps went from
> summing to 18 to summing to 76. Everything below is the analysis it was built from, and all of
> it held up except one number — the attrition on day 1 turned out to be near zero rather than a
> third, because the caps were binding and the budget was not. The measured table is now in
> docs/EVENTS.md. Two things it needed that this document predicted: a **spacing rule** at
> placement, and a rule keeping **lethal fields uncluttered**.

> I want one event **per block**. The dog walker decision should happen meaningfully — I want
> to have to make that decision at least twice on day one. That's the density I'm talking
> about. Also the same with a restaurant — I never saw one.

This is the answer to the question finding 5 leaves open, and it is worth taking literally,
because it is checkable arithmetic rather than a feeling. **This is a specification for the
next session, not a suggestion.**

### What "one per block" actually means

The city is `CITY_BLOCKS = 7×7` = **49 blocks**, on a 14-tile period (8 of block, 6 of street),
so 104×104 tiles, 3328px square.

| | today | one per block |
| --- | --- | --- |
| Planned per day (`budget_for(1)` = 18, avg cost ~1.5) | ~12 planned, **~13 placed** after attrition | **49 placed** |
| Live at once (inside `EVENT_STREAM_RADIUS` = 900px) | **3–4** | **~12** |
| Walking distance between events on her route | one every ~1300px, ~14s | **one every ~450px, ~5s** |

The live number is the one that matters, and it is the one M27 made computable: a 900px radius
covers ~2.5M px² of an 11.1M px² city, which is **~23% of the map** or about 12–13 block-areas.
So "one per block" is not 49 things on screen — it is **about a dozen instantiated at any
moment**, three to four times what a street carries today. Over a 180s day at `WALK_SPEED`
(92px/s) she covers ~16,500px, which is ~37 block-lengths of travel: at one per block she meets
something every five seconds or so of walking.

### Why the budget alone will not get there

`CLAUDE.md`'s own recipe says it — *"a budget the catalogue cannot spend is not density"* — and
this is the case it was written about. The day-1 recurring pool and its `max_per_day` caps:

| id | weight | max_per_day | cost |
| --- | --- | --- | --- |
| `cat_dash` | 3.0 | 5 | 1 |
| `dog_walker` | 3.0 | 3 | 2 |
| `cafe_tables` | 2.5 | 3 | 2 |
| `homeless_yeller` | 2.0 | 3 | 1 |
| `delivery_van` | 2.0 | 3 | 1 |
| `playground` | 1 | 1 | 1 |

**Sum of `max_per_day` = 18.** That is a hard ceiling on how many events day 1 can contain no
matter what `budget_for()` returns — and 18 is a third of 49. Raising the budget to 100 places
the same 18 events.

**Repeats are explicitly fine.** Asked directly, the player's answer was *"it's fine if the same
event (e.g. dogwalker) happens multiple times"* — so eight dog walkers in a day is not a problem
to design around, and **new catalogue rows are not a prerequisite for the density.** That
settles what would otherwise have been the expensive half of this milestone. It leaves two
things to change and one to watch:

1. **`max_per_day` across the day-1 pool**, several times over. This is the binding constraint
   and it is the first thing to move.
2. **`budget_for()`**, measured against what a day actually *places* over several seeds, per
   the recipe — roughly 70–100 for day 1 depending on the cost mix, against 18 today. Do not
   derive it; the attrition from `_ensure_one_usable_park` and
   `_ensure_the_city_is_still_walkable` is about a third and is what makes derivation wrong.
3. **Watch the clustering, because `max_per_day` was quietly doing that job too.**
   `_place_one()` picks a uniformly random tile of an allowed type and there is **no minimum
   separation between events anywhere in the scheduler** — the cap of 3 is the only reason two
   dog walkers have never landed on the same stretch of pavement. At four times the density
   that becomes likely rather than possible, and two of the same thing thirty pixels apart
   reads as a bug even when repetition itself is fine. If it shows up in a probe, the fix is a
   spacing rule at placement, not a cap on the type: the player's objection was never to
   seeing a dog walker twice, it is to the *decision* not arriving.

New event types remain worth having on their own merits — the vocabulary of act I is thin, and
finding 5 wants something in it that is actually dangerous — but that is a separate argument
from this one, and it no longer blocks the density.

### Why she never saw a café, and it is the same arithmetic

`cafe_tables` is the restaurant — *"a café spilling out of its frontage: chairs, tables,
conversation, and no way past on this side"*, the one day-1 event that cannot be walked
through. At `max_per_day = 3` there are **three of them on a 49-block city**, and M27 only ever
instantiates the ~23% of the map near her. Expected number of cafés she can even see in a day:
**under one.** The event that M19 built specifically to *"force me to cross the street"* on day
one is, in practice, absent from most day ones.

`dog_walker` is the same: three on the whole map, so "make that decision twice" is currently a
coin flip she loses. The ask translates directly — **at least two `dog_walker` and at least one
`cafe_tables` within reach of her actual route on day 1** — and that is a testable statement,
not a vibe. It wants a probe suite that walks a rig a real day's distance and counts encounters,
which is the same shape as the throwaway probes M19 and M27 were set from.

*(One ambiguity to resolve with the player next session: whether "a restaurant" means
`cafe_tables` — which exists and is simply too rare — or a **new** frontage type they expected
and did not find. The arithmetic above answers the first reading; the second is a catalogue
addition.)*

### The three things that get harder at this density, and must be checked

None of these is a reason not to do it. They are the places it will break quietly.

- **The telegraph fairness contract composes badly when fields overlap.** At one per block,
  outer radii will routinely overlap — `cafe_tables` alone is 170px against a 448px block
  period. Walking out of one event's radius may mean walking into another's.
  `validate_event()` checks each event in isolation and cannot see this; the contract is stated
  per event and the player experiences the sum.
- **Attrition will bite harder, and it is a guarantee, not a bug.**
  `_ensure_one_usable_park` strips everything reaching the calmest block. At four times the
  density it will strip four times as much, and *"at least one usable park"* has to keep
  holding — it is what makes a day winnable.
- **The cost table stops describing a street.** *"What an event actually costs"* in
  `docs/EVENTS.md` prices walking through one event against walking around it. At a dozen live
  at once, going around one is going through another, and the table's question stops being the
  one the player is answering. It will need regenerating and probably re-framing.

---

## What this changes about the queue

Nothing is reordered here — that is a decision for whoever picks it up — but five notes:

- **Findings 1 and 2 are both `src/crowd/`, and both are cheap.** Neither touches the meter,
  the catalogue or the day plan. Finding 2 in particular is a wrong constant convention with a
  missing test, and it undermines every subsequent judgement about traffic: a player who cannot
  predict which side a car comes from cannot learn a street, which is what the fixed city is
  for.
- **Finding 3 lands on M22's own work and should be settled before more cues are added to the
  vocabulary.** The `--walk` screenshot rig plus forcing a condition on (the technique in
  `CLAUDE.md`) is how to look at it; a run trace will not show the mark at all, since the
  telemetry has no entry for a cue being raised. **That may itself be the gap**: there is no
  way to ask a log "what was she warned about, and did she change what she was doing" — which
  is exactly the question this finding asks and cannot currently answer.
- **Finding 4 is M24, and this is the second time the game's only verb has been reported as
  not being a decision.** Playtest 03 found the calm area was a lap rather than a route (M21);
  this one finds the *choice of which calm area* is not a choice either. M21 and M24 are the
  same complaint at two scales, which is an argument for taking them near each other.
- **Finding 5 is the one that should set the order.** M21 makes a calm area worth walking to
  and M17 makes the route plannable, but neither puts anything at risk on the way — and *"there
  is never any danger"* is a statement about acts I and II, which is where a new player spends
  half the run. It is closest to **M25** (patrols, and running that matters), which was already
  the milestone written to make a threat that follows rather than a place that hurts.
- **Finding 6 is the next session's work.** Caps and budget together, measured with a probe
  rather than derived — and the three checks above are how it stays legal. Repeats being
  acceptable makes it a smaller change than it first looked: no new catalogue rows are required
  to reach the target. It is the density half of finding 5; the danger half (nothing
  lethal before day 8) is separate and is not fixed by placing more café tables.
  *(**Done — M28.** All three checks were real. The park guarantee held, but the **test** of it
  did not: it measured the whole block lot where the scheduler has protected only the calm
  ground since M15, which was invisible at thirteen events a day and false on nine days out of
  fourteen at fifty. The cost table survived as a way to price a row and stopped being a
  description of a street. And the overlap check turned into a placement rule. The danger half
  is still open and is still not fixed by café tables.)*
