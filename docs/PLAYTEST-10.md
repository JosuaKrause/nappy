# Playtest 10 — the cue that meant nothing, and the day that was not the same day

The tenth human playtest, taken on `70793df*` (M37 merged, M38 in the working tree), and reported
as a numbered list of fourteen after the session rather than mid-run. Five runs, in
`run-2026-08-28T2236…` through `run-2026-08-28T2325…`.

Six are defects, four are design instructions, two are questions about the tooling, one is a
request to discuss a change to the city, and one is a stated confusion about the visual
vocabulary that turns out to be the same finding as two of the others.

---

## The one sentence

**The danger marks and the danger have come apart, and a retried day is not the same day.**

Three of the fourteen — 1, 8 and 9 — are one finding with three faces: there is no mark over the
man who keeps ending day 1, there are two colours of mark that the player cannot tell the meaning
of, and the marked set does not correlate with how dangerous a thing is. That is the aura ring's
own epitaph arriving at the vocabulary M22 built to replace it — *a cue that marks everything says
nothing* was the rule, and the rule it turned into is **a cue that marks the wrong things says
something false**.

And underneath findings 5 and 13 is the other one: the game's one *tutorial* — the day-3 dog that
teaches the run key — cannot be relied on to happen, and when it happens it cannot be answered.
`docs/TODO.md` says of a retry that *"the retry is the same day. Everything about one is
deterministic from the seed and the day number"*. The trace shows two consecutive attempts at day
3 with different event lists.

---

## The findings, as reported

| # | What the player said | Kind |
|---|---|---|
| 1 | "there is no danger indicator over the homeless person" | bug |
| 2 | "playground doesn't increase excitement" | bug |
| 3 | "when walking downwards the zzz is still left of the stroller while walking in any other direction it has the correct position" | bug |
| 4 | "the yellow person in the park I think correctly increased excitement but didn't approach when I came close" | bug |
| 5 | "the tutorial dog on day 3 only appeared once (I died) then it didn't appear again" | bug |
| 6 | "from pause space should also let you continue" | design |
| 7 | "in the pause screen the day and nerves should show prominently as well" | design |
| 8 | "I don't understand the difference between yellow and red warning indicators above entities it looks like it's red further away?" | design |
| 9 | "in general I would kind of expect for more dangerous entities to have danger indicators but it feels like some dangerous ones don't have indicators and some really benign ones do have indicators" | design |
| 10 | "maybe we could make home always be the center of the map? that would allow always exploring in all directions. we would definitely need an odd number of blocks for this. might be something worth discussing the trade-offs" | discuss |
| 11 | "when I'm walking orthogonally away from the biker the double !! shouldn't show anymore since there is no way it can affect me (the danger has been avoided)" | bug |
| 12 | "would it make sense to create screenshots for reference in addition to normal telemetry? doesn't have to be a fixed frequency but could try to heuristically capture key instances" | tooling |
| 13 | "the running tutorial dog is impossible to escape at the moment" | bug |
| 14 | "the latest transcript is a longer play session — is there a mechanism to delete old outdated sessions? (maybe include the abbreviated commit hash in the file name too so we can quickly delete sessions from old commits)" | tooling |

Plus one clarification sent while the analysis was running: *"oh I see the long session actually got
split into multiple files"* — which is finding 14's real shape and is dealt with under it.

---

## What the traces already said

Five runs, **no day won in any of them**, all five ending at zero nerves on day 3 or day 4. That is
not one of the fourteen findings and it is recorded here anyway, because it is the loudest thing in
the logs and the last human verdict on the difficulty is playtest 06's *"I like the difficulty now"*,
five milestones and a solid catalogue ago. See "The thing nobody reported" at the bottom.

### Finding 5 is in the log twice over

`run-…seed3228044049`, day 3, two consecutive attempts:

```
day 3 …
   0.0  plan     events: busker, cafe_tables x11, cat_dash x5, charging_dog x3, construction x4,
                 delivery_van x7, dog_walker x7, fire_truck, homeless_yeller x2, ice_cream_van x6,
                 leaf_blower x3, loose_dog, market_stall x5, pigeon_flock x4, playground x2,
                 reversing_lorry
   7.2  lost     lost_crying … | near: fire_truck 145px
   7.2  nerve    spent a nerve on day 3 (act 1); 2 left — day 3 again

day 3 …
   0.0  plan     events: busker x3, cafe_tables x9, cat_dash x4, charging_dog x2, construction x5,
                 cyclist x3, delivery_van x8, dog_walker x6, homeless_yeller x8, ice_cream_van,
                 leaf_blower x3, market_stall x7, pigeon_flock, playground x2, reversing_lorry
```

Different day. `homeless_yeller` goes from 2 to 8, `ice_cream_van` from 6 to 1, `cyclist` from none
to three, `loose_dog` disappears, `charging_dog` goes from three to two. The line that says why is
the one that is *missing* from the second plan: **`fire_truck`**, a one-shot the first attempt
consumed.

`EventScheduler.build_day` runs six phases off one RNG in sequence:

```gdscript
planned.append_array(_place_ambient(day, map))
planned.append_array(_place_scars(day, scars))
_place_scripted(day, rng, map, planned)
_place_one_shots(day, rng, map, consumed_one_shots, planned)
_spoil_the_park_she_used(day, rng, map, planned, settled_yesterday)
_fill_with_recurring(day, rng, map, planned)
```

and `_place_one_shots` skips a consumed one-shot with a `continue` **before** it draws its
`rng.randf()`. So the second attempt's `_fill_with_recurring` starts one value earlier in the
stream and everything after it moves. `_place_scars` compounds it: a scar the first attempt left
behind is one more plan for `_room_around` to reject placements against, and every rejection is a
re-roll.

Measured over five seeds on day 3: **five out of five retries produce a different day**, and on one
of them the number of `charging_dog` plans changes.

### And on the third attempt the dog never came at all

Same run, third attempt at day 3:

```
   0.0  start    doorstep (38,14), facing south
   2.5  crowd    walked into somebody at (38,14) | exc 7, in 8.3/s (crowd 26.3, events 0.0)
   6.1  crowd    walked into somebody at (38,14) | exc 34, in 12.1/s (crowd 30.1, events 0.0)
   6.2  freeze   sleep stopped filling | exc 35, in 29.4/s (crowd 29.3, events 0.0)
   7.9  crowd    walked into somebody at (38,14) (+1 in the last 1.8s) | exc 53
  25.2  lost     lost_crying after 25.2s
```

Three contacts on the **same tile as the doorstep** in eight seconds. `EventDirector.due()` only
runs its clock while she is going somewhere (`speed >= AHEAD_MIN_SPEED`), which is a good rule for a
cat and is the second reason the lesson can silently not happen: a player pinned at the door is a
player who is never taught the control.

So finding 5 has three independent causes, and the third is the one that matters most: **the
tutorial is a weighted roll.** `EventDirector._teach_the_run` says so in as many words — *"if the
day happened not to buy one, there is nothing to teach and nothing happens"* — and the probe finds
whole day 3s with `charging_dog x0`.

### Finding 13 is in the log, with the numbers on it

Same run, the second attempt:

```
   9.0  freeze   sleep stopped filling | … | near: charging_dog 105px
   9.6  cue      the mark over her head: soon for 2.2s (0.7s of it on the road) | charging_dog 146px
   9.9  run      ran 1.7s, exc 20 -> 55, nearest when it started: charging_dog 104px
  10.7  near     charging_dog at (53,4), 82px
  11.5  run      ran 0.6s, exc 60 -> 75, nearest when it started: charging_dog 71px
  12.0  run      ran 0.4s, exc 77 -> 89, nearest when it started: charging_dog 63px
  12.4  lost     lost_crying after 12.4s
```

She did the thing the HUD asked. She started running at exactly the stand-off, 104px, and **the dog
closed to 82, then 71, then 63 while she ran.** She lost the day to the meter, not to the dog.

The probe walks the encounter forward at 1/240s, with her walking towards it when it lunges — which
is what the director's siting guarantees, since it is sited in front of her and forward is where she
was going:

| reacts after | closest approach | outcome |
|---|---|---|
| 0.00s | 69px | escaped at 2.99s — **42 points of running** |
| 0.15s | 36px | survives, never breaks off |
| 0.30s | 26px | **caught at 0.35s** |
| 0.45s+ | 25px | **caught at 0.35s** |

**The window is about two tenths of a second, and a perfect answer only just fits inside the
chase.** The player's word for that is "impossible" and it is the right word.

---

## The analysis

### A. The mark says nothing about the danger (1, 8, 9)

These are one finding. `EventInstance.wants_a_mark()` raises the caret for **danger that changes
over time** — lethal, telegraphing, swelling, or pulsing fast enough to be timed — which was M22's
rule and M33's refinement of it, and both were right about the thing they were fixing. Neither is a
statement about *how bad it is*.

Ranked by what walking straight through the middle costs, with what the build marks today:

| row | cost | marked today? |
|---|---|---|
| firefight | 155.8 | yes (lethal) |
| **fire_truck** | **115.4** | **no** |
| night_raid | 101.8 | yes (pulse) |
| pigeon_flock | 97.3 | yes (swells) |
| **military_convoy** | **84.9** | **no** |
| abduction | 61.2 | yes (lethal) |
| burning_building | 55.8 | yes (pulse) |
| protest | 49.9 | yes (swells) |
| leaf_blower | 48.5 | yes (pulse) |
| loose_dog | 43.2 | yes (pulse) |
| **dog_walker** | **36.4** | **no** |
| alley_robbery | 34.6 | yes (lethal) |
| reversing_lorry | 32.5 | yes (lethal) |
| **ice_cream_van** | **31.4** | **no** |
| **homeless_yeller** | **31.1** | **no** ← finding 1 |
| cyclist | 30.1 | yes (lethal) |
| **checkpoint** | **29.0** | **no** |
| **market_stall** | **27.8** | **no** |
| construction | 20.3 | no |
| cat_dash | 20.1 | no |
| cafe_tables | 20.0 | no |
| charging_dog | 16.9 | yes (lethal) |
| police_patrol | 15.8 | no |
| busker | 13.2 | no |
| delivery_van | 8.2 | no |
| barricade | 3.0 | no |
| poster_crew | 0.6 | no |
| burnt_shell | −3.1 | no |

**A fire engine has no mark and a burning building does.** The most expensive ordinary row in act I
— the dog walker, at 36 points, the row two playtests have been about — has no mark, and the leaf
blower next to it has one because its beat is 4.0s rather than 8.0s. That is finding 9 in one table,
and the player is simply right.

Finding 1 is the same table at the row they named: `homeless_yeller` pulses every 5.0s and the walk
across its field takes 4.6s, so `can_be_timed()` is false by four tenths of a second, and the man
who ends day 1 in three separate traces carries nothing over his head.

Finding 8 is the *colour* half, and its cause is streaming. `mark_colour()` is amber while
telegraphing and red once live — but `EVENT_STREAM_RADIUS` is 900px and no telegraph in the
catalogue is longer than 4s, so **almost every event finishes telegraphing before it is on screen**.
The only amber carets a player ever sees belong to the two `AHEAD_OF_PLAYER` rows, which appear
184px in front of her. So in practice **amber means "near" and red means "far"** — which is what the
player observed, with the sign flipped, and the honest reading of their sentence is *this colour
carries no information I can use*.

The fix is one rule with a test: **the mark is raised by what a thing costs, and the colour is how
bad it is.** Amber for *worth going round*, doubled deep red for *ends your day*, and the flash for
*it has not started yet* — which is the one thing the old amber was for and the one thing a colour
was the wrong channel for. The threshold is a taste call and it is stated rather than derived: a
quarter of the meter, 25 points, which happens to fall in the 7.5-point gap between `market_stall`
(27.8) and `construction` (20.3) rather than slicing a cluster.

What is kept, because it was right: the mark **breathes** with current emission (`mark_swell`), so a
pulsing event is still a thing to time; the whole catalogue is never marked at once; and scenery — a
notice board, a barricade, a burnt-out shell — carries nothing.

What is given up, and it is a real cost: **the cat loses its caret.** A crouching cat is 20 points
and does not clear the bar. The crouch is its own silhouette and M37's first rule says the entity
carries it, so this is the vocabulary being consistent rather than an oversight — but it is the one
place the new rule is worse than the old one, and it is written down here so that it is a decision.

The invariant that replaces the list, and the reason it cannot rot: **if A is marked and B is not,
then A costs more than B.** `tests/test_danger.gd` asserts it over the whole catalogue, so a new row
cannot be given a mark by having a fast pulse, and a row whose intensity is raised cannot silently
lose one.

### B. The playground is the calmest ground in the city (2)

The playground's own comment says it is *"the reason parks are not a free win"*. It is a net
**benefit** to stand on, and has been for twenty milestones.

- `PLAYGROUND` is on `Tile._CALM`, so the excitement decay there is
  `EXCITEMENT_DECAY_WALKING × EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` = **7.7/s**.
- The playground emits **7.0/s at the very peak of its pulse**, and the pulse envelope is 0.25–1.0,
  so its *average* is 4.4/s.
- 7.0 < 7.7. **It never out-emits the ground it is standing on**, at any phase of its beat, at any
  distance. Its denial radius — the distance at which calm ground stops being usable, the arithmetic
  `EventScheduler._denial_radius` exists to do — is its own **inner radius, 40px of 150**.

For comparison, on the same ground: a busker denies 100px, the man shouting 156px, a leaf blower
165px.

It was not always wrong. The playground was written in M5 when `SLEEPINESS_CALM_ZONE_MULTIPLIER` was
3.5 and the calm decay was 1.5/s, so 7.0 was nearly five times it. **M18 raised the multiplier to 10
and M38 to 12, and nobody re-ran the arithmetic on the one ambient row that lives on calm ground.**
Playtest 08 did exactly this sum for the busker and `_denial_radius` carries the warning in its own
docstring — *"getting this wrong is how one busker was ever thought to spoil a park"* — one function
away from the row it was already true of.

The fix is a number, and the number is set from what it should deny rather than by taste: a park
block is 256px across and the row's stated intent is *"dominates the middle of a park but leaves the
far side genuinely calm"*, so it wants a denial radius near 100px, and that is intensity ~15.

### C. A pursuit priced at the pursuer's speed, played at the encounter's (13)

`Tuning.pursuit_standoff()` is `inner + pursue_speed × PURSUIT_REACTION` = 26 + 130 × 0.6 = **104px**,
and its docstring says exactly what it is buying: *"she is owed `PURSUIT_REACTION` seconds of the
thing's own approach between the moment it is allowed to end her day and the moment it can."*

**The thing's own approach is not the approach.** At the instant of the lunge she is walking
*towards* it at 92px/s, because it is sited in front of her, it holds the stand-off by backing off,
and nothing has told her to stop. The gap therefore closes at `pursue_speed + WALK_SPEED` = **222px/s**,
not 130 — so the 78px of stand-off is 0.35s of reaction, not 0.6.

And the turn is not free. Reversing from +92 to −168 at `ACCELERATION` takes 0.371s, during which
the dog gains 48px and she gives back 14: **34px of the stand-off is spent on the about-turn
itself**, before any reaction at all. 78 − 34 = 44px = 0.2s. That is the window the table above
measured, and it is why every reaction of 0.3s or worse is caught at 0.35s.

This is M35's own lesson arriving one level down, and M35 wrote the sentence that catches it:
*"when a contract is about a moving encounter, state it over distance and check it by walking, not
by asserting the numbers it was written from."* M35 restated the contract as a distance and then
computed that distance from **one** of the two speeds in the encounter.

It is also why M35's measurement did not catch it. `--flee` triggers on `event_telegraphed`, so the
rig turns and runs 2.4 seconds *before* the lunge — an answer no player can give, because nothing
says when the telegraph ends. The 21–24 points M35 recorded is the price of an answer given before
the question.

The fix is to state the stand-off over the encounter:

```
standoff = inner + (pursue_speed + WALK_SPEED) × PURSUIT_REACTION + turn_cost(pursue_speed)
```

and the contract is then boxed in by three things at once, which is why the reaction cannot simply
be doubled:

- **Walking must still lose inside the chase**: `(pursue_speed − WALK_SPEED) × chase ≥ standoff − inner`.
  At 130px/s that is 38px/s of authority, so every extra pixel of stand-off costs 1/38 s of chase.
- **Running must still break off inside the chase**: the same 38px/s in the other direction.
- **And it has to be on screen.** The visible world is 640×360 at zoom 2, so a stand-off much past
  ~200px puts a dog that is telegraphing *off the top of the screen* when she walks north or south,
  and the whole content of the telegraph is the sight of it.

Solving those together gives `PURSUIT_REACTION` ≈ 0.45 at a stand-off near 160px and a chase near
3.6s — which is a real answer (0.45s of dithering **plus** a free turn, against 0.2s of nothing
today) and still fits on the screen. Anything more generous needs a slower pursuer, and a slower
pursuer needs a longer chase for walking to lose, and a longer chase is priced at 14 points a second.

### …and the player says that is not the finding *(correction, same session)*

Everything above is arithmetically correct and it is **not what was being reported**. Told what had
been built, the player said:

> *"the dog now moves backwards before charging — that doesn't make any sense"*
> *"the charging start earlier was fine — it was enough time to react properly"*
> *"the issue was that the dog kept following for too long"*

So finding 13 is about the **break-off**, not the notice, and the trace agrees with the player
rather than with the probe. Read the five lines quoted above once more and notice what is not in
them: she reacted, she ran, and she **died to the meter with the dog still 63px away**. Not one of
those lines is about a reaction window. That is M35's own failure repeating — the price of the right
answer set by how long the chase lasts instead of by how well it is played — and this analysis
walked straight past it because the probe it built could measure a window and could not measure a
toll.

And the stand-off's *backing off*, which M35 introduced deliberately and argued for at length, has
now been watched by a human and reads as nonsense. **A player's account of what a thing looks like
outranks a derivation about what it means.**

**What was built instead.** Everything the section above derived was reverted — `PURSUIT_REACTION`
back to 0.6, the stand-off back to `inner + pursue_speed x PURSUIT_REACTION` = 104px, the chase back
to 3.0s — and the break-off was restated as a **rate**: `Tuning.PURSUIT_SHAKEN_OFF` ends a chase
after 0.8s of the gap opening. Because a pursuer is faster than a walk and slower than a run by
construction, only running can open the gap, so *walking away can never end a chase* and *running
away always ends one* become facts rather than two inequalities pulling on the same three numbers.
Measured on a rig that accelerates: the answer costs **0.86s of running, 12 points**, where it cost
about 35; every wrong answer still costs the day.

**Two things stay open and are recorded rather than hidden.** The window to answer at the lunge
itself is 0.1-0.2s, for the reason this section derived correctly; a player answers during the
telegraph instead, where the dog is visible and closing for two and a half seconds. And the dog
still **backs off** through its telegraph, because the lunge is fired by a clock rather than by
proximity. Both are the first entries in the next plan.

**The lesson this section is now an example of**, and it belongs here rather than in the fix: a
probe that reproduces the numbers is not evidence that it reproduces the complaint. This one
measured a two-tenths-of-a-second window, which was real, and the player had never been talking
about it.

### D. A cue about a moment, again (11)

`EventManager._warn_about_the_ground_she_is_on` raises the doubled `!!` for any live `hard_fail`
event whose **outer radius** covers her. A cyclist is lethal inside 26px and reaches 145, so the
mark is up across a disc more than five times the area that can hurt her, and it stays up while the
bike rides away.

This is playtest 06's finding 3 — *"I get the flashing exclamation marks after the fact"* — at the
half M32 did not fix. M32 fixed the traffic half by giving `Stroller.warn()` a source and letting
the traffic take its own mark down; the events half kept "inside the outer radius" and nobody
checked what that meant for something that moves.

The rule the player states is the right one: *there is no way it can affect me*. So `NOW` becomes
two conditions rather than one — she is within a step of the radius that ends the day, **and** the
gap is actually closing at the speeds in play.

Note that this deliberately uses the **relative** closing rate, where M32 made the screen-edge badge
use the event's own approach with the player held still. The two cues have different jobs and the
difference is the reason: the badge says *a thing exists and is coming*, so her own walking must not
raise it; the `!!` says *the contract is now about you*, which is a statement about the pair of them.

### E. The yellow person in the park (4)

*"the yellow person in the park I think correctly increased excitement but didn't approach when I
came close."*

There is no act I row that approaches. The yellow figure in a park is `busker` (day 2+) or
`leaf_blower`, and the only two things in the game that come after her are `charging_dog` (day 3,
sited in front of her, never in a park) and `alley_robbery` (day 8, alleys only). The player is
reporting an expectation the build has taught them — M36 gave the robber `pursues_within` — and
correctly noticing that nothing else honours it.

This is a **design question, not a defect**, and the honest answer is to say so: act I's danger is
its own neighbourhood, and a busker who chases prams is a different game. What is worth taking from
it is that findings 4, 8, 9 and 1 are all the same complaint from four sides — *I cannot tell what
any of these things are going to do to me*. The mark work in A is the answer to all four, and
nothing new pursues.

### F. The pause screen (6, 7)

Both are plainly right and neither is deep. `space` is the key the title screen and the day summary
already use for *carry on*, and the pause is the one screen that does not take it. And a pause with
the run's state on it is what a pause is for: the day and the nerves are in the HUD behind a screen
that covers the HUD.

### G. Home at the centre of the map (10)

The player asked to discuss rather than to build, so this is a recommendation and not a change.

**The city is already 7×7 blocks — odd — and `_place_home` already sorts candidate blocks by
distance to the centre.** What stops the home being central is the second rule: it takes the first
central candidate that is at least `MIN_HOME_TO_PARK_TILES` (30) from calm ground. The centre of a
7×7 city is rarely 30 tiles of walking from every park, so the home is pushed outward until it is.

So the two rules are in direct competition, and they are competing for the same thing — **the walk
out has to be long enough to matter**:

| | home at the centre | home where it is |
|---|---|---|
| exploring | every direction is a real option; the map is learned as a wheel | one or two directions are the map, the rest is a wall |
| the walk out | shorter to the nearest calm ground, in every direction | the 30-tile guarantee is what makes the day a journey |
| route decisions | more of them, and more symmetric | fewer, and one is usually obviously right |
| the return phase | shorter and safer from anywhere | the walk home is already a formality (playtest 03) |
| M24's "somewhere else today" | much stronger — there are four ways to go | weaker; the alternatives are often behind you |

The trade the player is asking for is real and I think it is worth taking, but **not by moving the
home** — by making the *city* bigger so that a central home is still a long walk from a park. At 7×7
with a 30-tile guarantee the two cannot both hold; at 9×9 they can, and 9 is odd. That is a
generation change with a measurable acceptance test (`MIN_HOME_TO_PARK_TILES` satisfied from a
block within one of the centre, over 200 seeds) and it touches nothing else, because every guarantee
in the generator is already stated over the lattice rather than over its size.

**Recommendation: defer it, and do it as its own milestone**, because it invalidates every measured
density number in `docs/PLAYTEST-04.md` — the crowd is a field around the player and the events are
one per block, so a 9×9 city is 65% more blocks, 65% more events per day, and a completely re-measured
budget. It is not a change to make in a milestone that is also moving the danger cues and the pursuit
contract.

### H. Screenshots alongside the trace (12)

Worth doing, and the design constraint is the one telemetry already has: **it must not touch
gameplay.** A capture must be a read of the viewport after the frame is drawn, on a fixed small
budget, from `TelemetryObserver` rather than from anything that decides something.

"Heuristically capture key instances" is the right instinct and the right heuristic is the one the
log already uses: capture on the entries that are *about a moment* — a day lost, a nerve spent, a
hard fail, a chase starting and ending, a cue raised on something lethal. Those are exactly the
lines a reader stops on, and a PNG next to the line answers the question the line cannot: *what did
that look like.* Rate-limited, capped per day, and named after the entry so the log and the images
are one artefact.

### I. Old sessions (14)

Two halves. The player's follow-up — *"oh I see the long session actually got split into multiple
files"* — is the first: M38 made a finished run go back to the title and `R` restart from the pause,
and `_restart_run()` reloads the scene, so `_ready` runs again and `Telemetry.begin_run()` opens a
**new log**. Five files for one sitting is five runs, correctly. What is missing is any way to see
that from the outside.

The second half is the request: the commit in the filename, and a way to delete what is stale. The
commit is already *in* every log, on line 1, which is no help at all when the question is asked of a
directory listing. `Telemetry.KEEP_LOGS` prunes to 50 by age, which cannot tell a two-line boot trace
from a twenty-minute session or a current commit from one six milestones back.

---

## The thing nobody reported

**Five runs, no day won, every one over by day 4.** Nineteen days were lost across the session and
seventeen of them to `lost_crying`. The `in …/s` breakdown on the losing line says where it came
from:

```
 exc 100, in 39.4/s (crowd 39.4, events 0.0)   day 2
 exc 100, in 47.5/s (crowd 44.4, events 3.1)   day 2
 exc 100, in 28.8/s (crowd 28.8, events 0.0)   day 2
 exc 100, in 28.0/s (crowd 28.0, events 0.0)   day 4
 exc 100, in 23.3/s (crowd 23.3, events 0.0)   day 2
```

**The crowd is supplying nearly all of it**, which is playtest 07's finding 17 — *"the only thing
that really kills my runs are just pedestrians"* — arriving again after the milestone that was meant
to answer it. M33 lowered `BUMP_INTENSITY` 26 → 18 and made people step aside, and the traces still
have three contacts on the doorstep tile inside eight seconds.

This is **not** in the fourteen and is not being fixed here. It is recorded because the last human
verdict on the difficulty is playtest 06's, and this session is evidence that it no longer holds —
and because two of the fourteen (5 and 13) are downstream of it: a player pinned at her own front
door never triggers the day-3 lesson, and a player who arrives at the dog with the meter already at
48 cannot afford the run even when she gives the right answer.

It should be the next milestone after this one, measured rather than argued, and the numbers to take
first are the ones `CLAUDE.md`'s crowd recipe names: contacts in forty seconds down a lane centre
against the midline, and the mean wait at an arterial kerb.

---

## What this becomes

M39, in `docs/TODO.md`. Eleven of the fourteen are work, two are answered in writing (4, 10), and
one — the difficulty — is deliberately left as the milestone after.
