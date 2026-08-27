# Playtest 06 — the difficulty landed, the cues did not

The sixth human playtest, and **the first one taken on M28–M31** — the density, the traffic
sides, the narrowed exclamation mark and act I's teeth. The handoff's one instruction to the
next session was *"play it"*, and this is that.

**Status. Open.** Nothing here is done. It was reported mid-session with the instruction to
*"take note of those but continue implementing the next item on the handoff first"*, so M21
(four-block calm zones) went first and these are queued behind it. The analysis below is a
first read off the code, not a measured one — where it says "probably", it has not been
checked against a run.

---

## The five things

In the order they were said. The last two arrived part-way through M21 — the fourth as a
question that answers itself, the fifth as a request.

| # | What was said | First read |
| --- | --- | --- |
| 1 | *"The offscreen indicators are odd — they show events far away, and if you walk towards them they sometimes disappear. Also they flicker a lot."* | All three symptoms are one bug: **"closing" is measured as relative speed, so her own walking triggers it** |
| 2 | ***"I like the difficulty now — it actually became harder."*** | M28 and M31 confirmed by a human. The first time any density or danger number in this game has been |
| 3 | *"I'm still unclear about cars. When I cross and I guess they honk at me, I get the flashing exclamation marks **after** the fact, at which point they're not useful — they should indicate imminent danger, not anything afterwards. Or they should be read and indicate when there is a big jump in excitement (but it doesn't seem like it is the case right now)."* | The hold outlives the danger: the mark is raised for `CAR_WARNING_HOLD` and nothing takes it down when she steps off the carriageway |
| 4 | *"What happens if we fail (die or stay awake) — do we repeat the same day? Is there a concept of retries? We shouldn't advance the day, that's for sure."* | Today a lost day costs a nerve **and** a day. Asked as a question and answered in the same sentence: a nerve should buy a **retry** |
| 5 | *"Can you add a visual for when the excitement bar is almost full (or various stages), and the same for when the sleep bar is fully full? Maybe we should look into the baby face visual, but having something above the player might be better (like a zzz above the stroller when the baby is fully asleep), and warnings when the excitement is about to be full."* | The two meters are only readable in the corner of the screen, and the game is played by looking at the pram |

Findings 1 and 3 are both about M22's vocabulary and both have the same shape — **a cue whose
condition is not the thing it claims to mean**. That is the mistake M30 fixed for one cue by
narrowing what it means; these two are the same mistake in the *timing* rather than in the
membership.

---

## Finding 2 first, because it closes something

> I like the difficulty now — it actually became harder.

Worth recording as its own finding rather than as a nice remark. Every difficulty number in
this game has been set off a probe or a scripted walk, and `CLAUDE.md`'s "Known-shaky ground"
has said **"no balance number has been felt by a human"** since M14. M28 quadrupled the density
to a stated target of one event per block, and M31 gave act I two lethal things. Both were
aimed at playtest 05's finding 5 — *"there is never any danger"* — and both are now confirmed
by the person who said it.

What it does **not** close: whether act I is now too hard, whether the nerve economy survives
early losses, and whether the arterial is crossable. Those want a trace, not a sentence. But
the direction is settled, and the next balance argument starts from "this is roughly right"
rather than from nothing.

---

## Finding 1 — the screen-edge badge is triggered by her own footsteps

> The offscreen indicators are odd — they show events far away, and if you walk towards them
> they sometimes disappear. Also they flicker a lot.

Three complaints, and the strong reading is that they are **one defect**. `DangerEdge._draw()`
decides an event is worth a badge if it is off-screen, lethal-or-faster-than-a-walk, and
*closing*:

```gdscript
var delta_frame := get_process_delta_time()
if delta_frame <= 0.0 or (previous - distance) / delta_frame < CLOSING_SPEED:
    continue
```

`distance` is the distance between the event and **the player**, and `previous` is that same
distance last frame. So the derivative it computes is the *relative* closing speed — and the
player walks at 92px/s against a `CLOSING_SPEED` threshold of 20. **Walking towards anything
lethal satisfies the test on its own**, whether or not the thing is coming.

That explains all three symptoms without needing a second cause:

- **"They show events far away."** There is no distance cap anywhere in the file. An event is
  eligible from the moment it streams in, which is `EVENT_STREAM_RADIUS` = 900px — most of two
  blocks, and about 42 on the badge's own metre scale. It is announced because she is walking
  in its direction, not because it is coming.
- **"If you walk towards them they sometimes disappear."** Two ways. Her heading drifts a few
  degrees off the event and the relative closing rate falls under 20px/s, so it drops out; or
  the event's own motion away from her cancels her approach. Either way the badge for something
  she is deliberately approaching is the least stable badge on the screen, which is the exact
  opposite of what a warning should do.
- **"They flicker a lot."** The test is an instantaneous frame-to-frame derivative against a
  hard threshold with **no hysteresis at all**. Anything hovering near 20px/s — which is
  everything, once her own gait and a slow mover are being subtracted from each other — toggles
  every frame.

**The fix is a change of question, not a change of threshold.** The cue means *this is coming
at you and you cannot outwalk it*, so the speed it should measure is the **event's** closing
speed with the player held still — how fast the gap would be shrinking if she stopped. Her own
velocity is already hers to control and does not need announcing at the edge of the screen.
There are three obvious pieces:

1. Measure the event's own approach: track its distance to the player's position *as of the
   previous frame*, or subtract the player's velocity from the relative rate.
2. Cap the range. A badge at 900px is not a route decision, it is scenery with a number on it.
   The honest bound is the reaction window the telegraph contract is stated over.
3. Hysteresis, so a badge that is up stays up until it is clearly not closing, and one that is
   down needs a clear margin to come up. The same shape as `EVENT_STREAM_HYSTERESIS`.

**Not yet checked:** whether a fourth thing is happening on top — `MOST_AT_ONCE` is 3 and the
list is sorted by distance, so at M28's density a nearer badge can silently evict a further one
mid-approach. That would also read as flicker and would not be fixed by any of the above.

---

## Finding 3 — the mark over her head outlives the car

> I'm still unclear about cars. When I cross and I guess they honk at me, I get the flashing
> exclamation marks **after** the fact, at which point they're not useful — they should indicate
> imminent danger, not anything afterwards.

`Crowd._physics_process()` raises the mark like this:

```gdscript
if closing:
    _player.warn(Stroller.Alert.SOON, Tuning.CAR_WARNING_HOLD)
```

`_horn()` only returns true while she is **on the carriageway** with a car behind her inside
`CAR_HORN_TIME` of travel, which is the right condition. What is wrong is what happens next:
`CAR_WARNING_HOLD` is **1.4 seconds**, and nothing lowers the mark early. She finishes the
crossing, steps over the kerb — the danger is over by construction, since a car only strikes on
the carriageway — and the mark stays up for over a second on the pavement, where there is
nothing to act on. That is the whole of *"after the fact"*.

The hold is not an accident: `Tuning` says it is *"long enough to survive the gap between two
cars in the same lane"*, and that is a real problem it solves. But the two cases are
distinguishable and the code does not distinguish them. **Stepping off the road should drop the
mark immediately; being on the road between two cars should keep it.** `Crowd` already computes
`on_the_road` every frame and has it in hand.

There is a second half worth stating separately, because it may be the larger one: the horn
also `startle()`s the car for `CAR_HORN_DURATION` (0.9s) at `CAR_HORN_INTENSITY` (18). So in
the second after a near miss the meter is climbing *and* the mark is up — and both are the tail
of something that has already happened. The player reads the pair as "the game is telling me
about the past", and they are right.

### And the alternative meaning that was offered

> Or they should be read and indicate when there is a big jump in excitement (but it doesn't
> seem like it is the case right now).

Recorded as an open design question rather than as a request, because it **contradicts a
decision taken in M30** and the contradiction is the interesting part. M30 narrowed the mark to
mean exactly one thing — *this will end your day* — on the grounds that a mark meaning "a number
is about to move faster" fired for fifteen of eighteen rows and the meter already says that
continuously and proportionally. "A big jump in excitement" is that rejected meaning, asked for
by name.

Two readings, and the next session has to pick one:

- **The player wants the mark to mean more.** Then M30 narrowed too far, and the honest fix is a
  *second* cue for a spike rather than widening this one back out — the vocabulary is short on
  purpose, and one symbol with two meanings is how it stops working.
- **The player wants the mark to mean something *now*.** Then this is finding 3's first half
  restated: the complaint is about the timing, the "big jump" is what they were looking at when
  they noticed, and fixing the hold fixes both sentences.

The second reading is the likelier one — the whole finding is about *after the fact* — but that
is an inference about intent and wants confirming before anything is built on it.

---

## Finding 4 — a lost day is spent as well as failed

> What happens if we fail (die or stay awake) — do we repeat the same day? Is there a concept
> of retries? We shouldn't advance the day, that's for sure.

**What happens today**, in `GameState.finish_day()`: a lost day costs a nerve *and* moves the
calendar on. There is no retry. A player who is run over on day 2 wakes up on day 3 with two
nerves, having never walked day 2.

That is a live open question rather than an oversight — `docs/TODO.md` has carried
*"does a lost day advancing the calendar feel right, or should it repeat the day? (Current:
advances, which makes Nerves the real resource)"* since M6 — and the answer has now been given:
**it should not advance.** So a nerve buys a **retry of the same day**, and the calendar only
moves when a day is won.

What that changes, stated so the consequence is chosen rather than discovered:

- **Nerves become retries, not a second currency.** Three nerves is three failed attempts
  across the whole run, spent wherever they are needed, and the fourteen days are fourteen days
  the player actually plays. That is a straightforwardly better shape: today a bad day 2 makes
  the run *shorter* as well as poorer, which punishes twice for one mistake and hides act I from
  a player who needed act I most.
- **A repeated day is the same day.** Everything about a day is deterministic from the seed and
  the day number, so a retry is the same city, the same closures and the same event plan — which
  is exactly what makes a retry worth having in a game about learning a route.
- **Three things are not derived from the seed and have to be decided**, because they depend on
  run history rather than on the day: the one-shots the run has consumed, the block arcs it has
  advanced, and — since M24 — the calm area she settled in "yesterday". The first two should
  stay spent; a fire that burnt a block down did happen. The third is the interesting one: on a
  retry, "yesterday" is the day before the one being retried, which is what it already means.
- **The run can no longer end by running out of days while nerves remain**, so the bad ending
  (nerves at zero) becomes the only way to lose, and the run length becomes a promise rather
  than a budget.

Small in code — `finish_day` stops incrementing `day` on a loss — and not small in what it
means, which is why it is written up here rather than done quietly.

---

## Finding 5 — the meters are in the corner and the game is played at the pram

> Can you add a visual for when the excitement bar is almost full (or various stages), and the
> same for when the sleep bar is fully full? Maybe we should look into the baby face visual, but
> having something above the player might be better — like a zzz above the stroller when the baby
> is fully asleep — and warnings when the excitement is about to be full.

This is the vocabulary in `docs/EVENTS.md` finally being asked for **in the other direction**.
Every cue it has says something about the *world* — an entity is dangerous, something is coming,
this spot is about to be bad. Nothing says anything about the **baby**, and the baby is the only
thing the player is trying to change. Two bars in the bottom-left corner of a game whose camera
is on the pram is asking a person to read a number about the thing they are looking at from
somewhere else on the screen.

Three things it asks for, and they are not the same request:

- **The baby is asleep** — a `zzz` over the stroller. Unambiguous, one state, no threshold to
  choose. It is also the state with the most consequence attached and the least on-screen
  presence: today the only thing that says "the return phase has begun" is the HUD's state line
  and the sleepiness bar sitting at 100.
- **Excitement is about to be a problem** — staged warnings approaching
  `EXCITEMENT_CALM_THRESHOLD` (35), where sleepiness *freezes*, and again approaching
  `EXCITEMENT_WAKE_THRESHOLD` (60), where a sleeping baby wakes. Two thresholds that already
  exist and are already the two moments the day turns.
- **A face rather than bars**, floated and then set aside in the same sentence — *"having
  something above the player might be better"*. `docs/TODO.md` has carried *"should there be a
  diegetic-only mode — a baby's face instead of two bars?"* as an open question since M2, and
  this is the player half-answering it: not instead of the bars, and not a face, but *at the
  pram*.

**Two things have to be got right or this becomes the rings again.** The standing decision in
`CLAUDE.md` is that a cue that marks everything says nothing, and a meter climbing continuously
is the easiest thing in the game to mark constantly:

- **Stages, not a gauge.** A second excitement bar drawn over her head is not a cue, it is the
  HUD moved. What earns its place is a small number of *states* — approaching the freeze,
  frozen, about to wake — each of which is a different instruction.
- **It must not collide with the exclamation mark.** That cue means *this will end your day* and
  M30 spent a whole milestone making it mean only that. A cue about the meter has to be
  distinguishable from it at a glance and must never occupy the same spot at the same time —
  which, given the exclamation mark sits at 54px over a 46px rig, is a layout problem as much as
  a design one.

Note the overlap with finding 3's second sentence — *"or they should be read and indicate when
there is a big jump in excitement"*. Read together, the two are the same wish arriving twice:
**the meter should be visible where the player is looking.** That is a much better answer to it
than widening the exclamation mark, and it is why M30's narrowing does not have to be undone.

---

## What this asks for

Nothing here is a milestone on its own. Both fixes are small, self-contained and in the
signalling code M22 and M30 already own:

- **The badge measures the wrong speed** — a rewrite of one condition in `src/ui/danger_edge.gd`,
  plus a range cap and hysteresis, plus a look at whether `MOST_AT_ONCE` is evicting badges
  mid-approach.
- **The mark outlives the car** — `Crowd` drops the warning when she leaves the carriageway.
- **A lost day is retried, not skipped** — `GameState.finish_day()` stops advancing the calendar
  on a loss, and the day summary says "again" rather than "tomorrow".
- **The baby gets a cue of her own** — a `zzz` over the stroller when she is asleep, and staged
  warnings as excitement approaches the two thresholds that already matter. New rows in the
  vocabulary in `docs/EVENTS.md`, which makes it a design decision rather than a drawing one.
- **Open question:** does the exclamation mark also want to mean "a spike, now"? Probably not —
  finding 5 is a better answer to the same wish, and M30 decided it the other way for reasons
  that still hold.

Neither has a test that could have caught it, and that is the pattern by now: `tests/test_danger.gd`
asserts *which* things are marked and cannot see *when*. A cue is a claim about a moment.
