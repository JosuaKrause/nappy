## M55 — Off the paths is the dangerous place · partly built

### The resistance half, built 2026-09-01 · `feature/the-mark-is-touched`

All six decided items, three commits, suite green. The hold went whole — `interact` out of
`project.godot`, `ContactPoint` touch-completes, and `hold_seconds`, `progress`, `DECAY_RATE`,
`resistance_hold_changed`, the HUD's holding line and the patrol watch (`SEEN_RADIUS`,
`_patrol_is_watching`, `was_seen`, `resistance_seen`) all deleted. The calendar became eleven
steps — five tasks × (mark, perform) on days 4/5 through 12/13 plus the day-14 finale — with
`grants_progress` false on a mark, so `RESISTANCE_GOAL` stays 4-of-5 over the performs. The shared
plumbing is `ContactPoint.ride(step, instance, offset)`: a perform contact follows an
`EventInstance` and draws nothing, so it is indistinguishable from the ordinary row it rides on.
The guard became a **distance**: `TRAP_FIRST_DAY` 4, the district exemption out, the robber stood
in the 66–176px band computed live from `alley_robbery`'s own radii plus `ContactPoint.REACH`
(never hardcoded), seeded from the day so the pattern is learnable. The brief carries the
resistance's words via `GameState.pending_resistance_brief`, read once and cleared by the day
summary; the first encounter's no-hint exemption cost nothing because a pickup grants no progress.

**Three choices the design was silent on, taken by the implementer and open to overturn:**

- The package task's "the pram is heavier" got a number the design never gave:
  `Tuning.RESISTANCE_PACKAGE_DECAY_MULTIPLIER` (0.5) layered onto `City.decay_multiplier()` via a
  `GameState.resistance_carrying_package` flag, reset on every fresh attempt at a day.
- The package rides a spawned `delivery_van` — the closest existing row to "a package she picks
  up"; the design named no row.
- The poster wall's deadline runs on `deadline_fraction` (0.55) against the day clock rather than
  the crew's own progress, because `poster_crew` never finishes on its own today; the generic
  rider-finished expiry exists and will bite the moment the row can finish.

**Left open by decision, and the code's current behaviour recorded:** whether a
picked-up-but-unperformed instruction expires at the end of its day — **the code waits**: an
incomplete perform step is re-offered every subsequent day, and the only expiries are the poster
deadline and the rider finishing, both inside one day. Moved to the open design questions.

Playtest 17, in full in **[docs/playtests/PLAYTEST-17.md](../playtests/PLAYTEST-17.md)**. Twelve findings, and everything
that is a change to the build is done and ticked below — the off-corridor cost, what goes between
two strands of corridor that run alongside each other, and the corners of the world. What is left is
the four resistance items, and drafting them turned up half of a second item already built and never
read back.

**The design work is finished and nothing in the resistance half is open any more.** The six drafts
went back, five were taken, and the four questions came back on **2026-09-01** with two answers that
changed their own questions — see "The answers" below. **The largest of them is that the hold is
gone**: every step in the subquest was `E` held for three to eight seconds, and the whole thing
becomes *touch it*. The cost moves out of the standing and into the approach, which is where the
player's own task design had already put it. What is left is a build.

**The one sentence is the player's own: *"leaving the path should be lethal or very expensive. right
now that is not the case… that is not as we planned."*** The design was agreed in M50 and the build
does not match it, so nothing here is a new decision — it is an admitted gap being closed, and the
project now has the instrument to say whether it closed.

- [x] **A log says whether anybody was playing it** *(finding 3)*. `run-` when a person is at the
      controls, `rig-` for a headless boot or anything driven by `--screenshot`, `--walk`, `--flee`
      or `--press`. The tool's old proxy — anything under 3kB is a boot — could not see a
      `shot.sh --walk 60`, which is a long busy entirely unplayed log
- [x] **The trace says whether she was on the corridor** *(finding 6)*. A `path` line each way and a
      share at dusk, in three states because a park is not "off the corridor". This is the
      instrument for the two findings below, and it went in first on purpose
- [x] **The word on the title screen has an outline** *(finding 4)*
- [x] **Evidence lives in `docs/evidence/`** *(finding 10)*, with the rule in `CLAUDE.md`. Three
      references the docs already carried were found to be dead
- [x] **Off the corridor has to cost what it was designed to cost** *(findings 1 and 12)*. **Closed
      from M50's own entry rather than given a second design** — see "What M50 still owes", which
      already carries the measurement (*day 1 is ~6× denser on the corridor than off it, and only
      16.2 of its 113.6 placements are walls at all*) and the reason (*the expensive rows have low
      `max_per_day`*, which is *"a budget the catalogue cannot spend is not density"* at the other
      end of the map).

      What playtest 17 adds is that **the gap is visible from outside** — a player read it off a
      telemetry map without being told what to look for — and that the observed effect is not merely
      "off-corridor is cheap" but that **the two are the wrong way round**: stepping off the paths
      is a step into quieter ground.

      **Built, and the measurement is the entry.** Cost per tile of street, five seeds, before and
      after:

      | | on corridor | rim (1 away) | deep (2+) |
      |---|---:|---:|---:|
      | day 1, before | **0.231** | 0.164 | 0.235 |
      | day 1, after | 0.202 | **0.253** | 0.216 |
      | day 5, before | **0.265** | 0.189 | 0.252 |
      | day 5, after | 0.211 | 0.263 | **0.263** |
      | day 9, before | 0.306 | 0.220 | **0.366** |
      | day 9, after | 0.261 | 0.286 | **0.388** |

      **The corridor is the cheapest ground on every day now, and it was the dearest on two of the
      three.** Lethal events off the corridor went from ~0 to 13.2 and 19.2 in the deep band on days
      5 and 9. Walls went from 13% of a day's placements to 24–28%.

      **Two levers, and which one binds is a different answer on different days — that is the part
      worth carrying.** The *cap* was binding on days 5 and 9: the lethal wall rows were capped at 4
      and 5 across 121 blocks, so the deep band had nothing deadly in it whatever the budget did.
      The *weight* binds on day 1, where the caps were never reached: a row is only offered as often
      as its weight, so walls were 13% of placements however high the ceiling went. Raising a cap
      the day never reaches is the other half of *"a budget the catalogue cannot spend is not
      density"*, and M50's entry named only the first half.

      Two costs, both accepted and both worth stating. A day places about six fewer events, because
      the budget now buys dearer rows. And a leaf blower is as common a sight as a dog walker, which
      is the price of day 1 having exactly **two** rows a wall can be made out of.

      **Day 1 is very costly and not deadly, and that is inside the design rather than short of
      it.** *(Confirmed 2026-09-01: "day 1 blocks can be non-lethal. the wording always allowed
      that.")* Day 1 has **no lethal rows at all** — M31 made act I's escalation a change of *kind*,
      0, 3, 4 lethal events over days 1–3 — so an off-corridor wall there is `loose_dog` or
      `leaf_blower` and the deadly end of the range starts on day 2.

      This side raised it as a shortfall; it is not one. *"It ranges from very costly to deadly"* is
      a **range**, and a day that spends only the cheap end of it is spending the range. Recorded so
      the next reader does not re-open it: **the escalation across the acts is where "deadly" comes
      from, and M31's teaching decision and M50's gradient were never in tension**
- [x] **Something between parallel strands of corridor** *(finding 2)*. Asked back because it
      overlapped `RouteTree`'s recorded instruction — *"the player can walk the beginning of path A
      and then switch to path B without noticing, and that is fine… the constraint is on the graph
      and never on spacing"* — and **answered on 2026-09-01**:

      > *"apply nuance here. sometimes put a blocker between (wall or event) and sometimes leave it
      > open -- this is not as important as going off the path completely."*
      > *"only directly adjacent paths (with a single street connecting both) counts for this case
      > obviously. everything further apart should just naturally be never connectable."*

      **The answer dissolves the contradiction instead of picking a side, and that is the part to
      carry.** Only *directly adjacent* strands — one street between them — are this rule's
      business. Anything wider apart is separated **by the map**, because once the item above is
      built the ground off the corridor is lethal or very costly, so two strands two streets apart
      already have something between them and nothing has to be placed. The old instruction is about
      the **tree** and stays exactly true; this is about a **placement** in one specific gap.

      So: *sometimes* a wall, *sometimes* an event, *sometimes* nothing — variety in what one gap is
      worth rather than a rule that closes them all. And it goes **after** the item above by the
      player's own ranking.

      **Built, and it is two weights on placements that already existed rather than a phase of its
      own.** `RouteTree.gaps()` is the question — a street off the tree with a strand of corridor
      crossing each of its two ends, at right angles, so that the two strands are parallel and one
      block apart. `Corridor.is_in_a_gap()` is that asked about a tile. Then
      `Tuning.CLOSURE_GAP_BIAS` aims the day's closure quota at one (the **impassable** half of
      *"wall or event"*), and `Tuning.EVENT_WALL_GAP_WEIGHT` offers a gap's pavement six times over
      to a very costly wall (the **costly** half).

      **A weight and not a per-gap roll, which is the decision worth writing down.** A roll reads
      more directly off the instruction — walk the gaps, roll three ways — and it needs a phase, a
      stream, a budget of its own and a share of the per-row caps, all of which are places the day's
      density can quietly move. A weight rides on the budget, the spacing and the caps unchanged and
      **cannot place more than the day can afford**. Measured over eight seeds, days 1/5/9: a day
      places 106.6 / 140.0 / 169.5 events before and 106.6 / 140.1 / 169.5 after, and walls are
      31% / 26–27% / 30% of them either way. Nothing moved except *where*.

      **What a day has, and what it does with it.** ~15 gaps, of which 7.9 / 8.2 / 8.5 end up
      carrying something — **about half, and about half left open**, which is the instruction rather
      than a compromise. Closures land in one 0.2 / 0.2 / 1.4 times, which is the quota talking: a
      day shuts one street in act I and four in act IV, so it can never shut fifteen.

      Cost per tile of street, eight seeds, before and after — the gap is now the dearest ground in
      the city and by a distance:

      | | on corridor | rim (not a gap) | **gap** | deep (2+) |
      |---|---:|---:|---:|---:|
      | day 1, before | 0.339 | 0.345 | — | 0.203 |
      | day 1, after | 0.343 | 0.318 | **0.547** | 0.188 |
      | day 5, before | 0.382 | 0.302 | — | 0.279 |
      | day 5, after | 0.385 | 0.257 | **0.595** | 0.262 |
      | day 9, before | 0.455 | 0.356 | — | 0.387 |
      | day 9, after | 0.445 | 0.322 | **0.670** | 0.368 |

      The *before* rows have no gap column because there was no such band: those streets are in the
      rim figure beside them, which is why the rim falls when they are taken out of it.

      **The correction this needed is the part to carry, and it was found by measuring rather than
      by thinking.** The first version multiplied the gap weight through the *whole* wall band. A
      gap is on the rim by construction, so a lethal row's weight there is 1 against
      `WALL_DEEP_WEIGHT` further out — and six times one beats four, which quietly made a gap **the
      best lethal ground in the city**. The deep band went from the dearest ground on day 9 to level
      with the corridor, and lethal placements in it fell 8.5 → 7.8 on day 5 and 16.8 → 15.6 on day
      9: M55's first item undone by its second, in one multiplication, with every test still green.
      Restricting the weight to the costly half fixed it and then some — lethal in the deep band
      comes out at **8.8 and 18.1**, above where it started, because the costly rows that left the
      rim were competing with it for the same budget. The gradient's own sentence is what says which
      half gets the weight: *stray one turning and it is expensive, stray further and it ends the
      day.*

      **The picture is the check, and it is the finding's own instrument.** The same day either side
      of the change is in `docs/evidence/`:
      [before](../evidence/archive/session-captures/2026-09-01/rig-2026-09-01T014558-seed4242-f604488-dirty-map-day01.png) and
      [after](../evidence/archive/session-captures/2026-09-01/rig-2026-09-01T014420-seed4242-f604488-dirty-map-day01.png), seed 4242, day 1.
      The yellow crosses gather onto the streets between the parallel purple strands and a good half
      of those streets are still bare. **Nothing was added to the map to show this**, deliberately:
      a gap that got a wall is a wall mark between two corridor lines and a gap that got nothing is
      a bare street between two corridor lines, so the picture already answered it. The vocabulary
      is short on purpose — *"don't draw the bundles white"* is the same decision one milestone
      earlier.

      **One thing this side could not do and is recording rather than papering over.** The table in
      the item above says *"cost per tile of street"* and does not say **which** tiles or **how** a
      placement's cost is attributed, and three plausible readings were tried against it without
      reproducing its numbers. The table here is a different measurement — cost of the placements in
      a band, over the street tiles of that band — so the two are comparable **in shape and not in
      value**, and the before/after columns are what carries the argument. The guard against the
      previous item is stated in that item's own numbers instead, which are unambiguous: placements
      a day, walls as a share of them, and lethal placements in the deep band. **A measurement whose
      formula is not written down is a measurement nobody can take twice**
- [x] **A switch between strands is a switch** *(finding 2's last clause: "make sure the log notes a
      path switch correctly if it happens — technically it's leaving a path and entering a new
      path")*. As first built, `path` could not see one: both strands answer `on`, so changing route
      appeared in the trace as nothing happening. It carries the branch colours now
- [x] **The corners of the world stop going diagonal** *(finding 11)*. Each band simply carries on:
      mountain stays mountain round the corner, sea stays sea. No new terrain and no corner feature
      — the player asked for the simpler thing, not a bigger one.

      **It is `City._border_source` and not `CityEdge`**, which this entry said until it was
      opened: `CityEdge` is the tunnel, the bridge and the road going into the dark, and the four
      bands are painted in `City`. Worth the correction rather than a silent fix — a to-do item
      that names the wrong file is a to-do item somebody starts by reading the wrong file.

      **One line, and the cause is worth more than the fix.** A corner belonged to *whichever side
      it was further out of*, ties to north or south. That reads as a sensible tie-break and it
      **is** the diagonal, spelled differently: the place where two distances are equal is a 45°
      line, so every corner had a stepped seam running out of it. North and south take the corners
      outright now and keep their own step, so a band runs the full width of the map and the east
      and west bands are what is left between them. The general shape: **a rule written as a
      comparison between two distances has a diagonal in it whether or not anybody drew one.**

      Checked by eye, which is this project's own policy for layout and colour, and the pictures
      are in `docs/evidence/`:
      [before](../evidence/archive/session-captures/2026-09-01/shot-2026-09-01-seed4242-d69631a-corner-nw-before.png) and
      [after](../evidence/archive/session-captures/2026-09-01/shot-2026-09-01-seed4242-d69631a-corner-nw-after.png) at the north-west
      corner, and [the south-east](../evidence/archive/session-captures/2026-09-01/shot-2026-09-01-seed4242-d69631a-corner-se-after.png)
      for the other pair of bands.

      **`--spawn corner:nw|ne|sw|se` is new and is half of why this was found by a player rather
      than here.** The border shipped in M41, was redesigned in M49 and there has never been a way
      to point a camera at the place where two of its bands meet — the same gap the `landmark` flag
      was added to close. It stands a couple of tiles inside the corner, on the pavement: the first
      shot taken with it was of the day ending, because `_nearest_walkable` will happily leave her
      on the boundary carriageway

### The resistance, which is three findings and one shape

*(Findings 7, 8 and 9. This is design work the player asked for by name — "let's think of more
tasks like this" — so it is drafted and put back rather than built.)*

**The shape, in the player's own terms: a resistance task is a thing that costs you meter or safety
on purpose, in exchange for progress on the optional path.** Every other cost in this game is
avoidable by routing; these are taken deliberately. That is what makes them affordable as an
optional path at all, and it is why *"pursuing the resistance should make the game harder"* is a
feature rather than a difficulty complaint.

#### The answers, 2026-09-01 — and one of them is a correction to the verb itself

The four questions at the bottom of this entry went back and came back with more than yes and no.
**The player's own words first, because three of the four are new design rather than an answer.**

> *(on "steps 1, 2 and 4 are the same alley hold three times")* **"not sure what you mean by 'same
> alley hold'? do you mean it is picking up instructions in an alley with a robber close by? let's
> keep them so the progression is (pick up instruction -> perform task the next day -> repeat) so I
> guess that would mean extend the list?"**
>
> *(on which drafts to build — all four offered were taken, plus)* **"let's also make sure the chalk
> mark is always guarded by a robber"**
>
> *(on this side's description of the existing steps)* **"'mark on an alley tile, hold interact for
> 3–6s,' this is incorrect in two ways: 1) there is no 'hold interact' button and 2) it should be
> instant when touching the mark. that should explain how the guard works"**
>
> *(on whether a task may cost a nerve)* **"how would that work? losing a nerve means repeating the
> day with the failed day erased. so no it cannot cost a nerve. but what should happen is that the
> more resistance tasks are completed the more dangerous the environment becomes. we need abduction
> vans that normally just abduct people but start trying to abduct the player if she is part of the
> resistance. and other dangers like this"**

Plus two straight answers: the **first mark moves to day 4** so the calendar fits, and the guard ramp
is **fixed both ways** — the trap starts at the first step rather than on day 8, and the
district-placed steps stop being exempt from it.

**The last answer is a milestone of its own and is written up as [M56](#m56--the-resistance-is-noticed--not-started).**
Nothing of it is dropped or narrowed; it is sequenced, because M55 already has five tasks and a new
verb in it.

##### The hold is gone, and that is the load-bearing change

**Every one of the six existing steps is `Input.is_action_pressed("interact")` held for 3–8
seconds** (`contact_point.gd:44`, `resistance_steps.gd:16`). That is the verb the whole subquest was
built on and it is being **removed**: touching the mark completes the pick-up, instantly.

**And "there is no interact button" is not a mistake about the code, which is what this side said
first and had to be corrected on.** *(2026-09-01: "why are you still talking about holding E? we
removed E early on in the development.")* The key is still bound — `E`, `project.godot:64`, added in
M0 and never touched since — but **the decision to delete it was taken in playtest 02 and was never
built**. `docs/playtests/PLAYTEST-02.md`, under *"Teach the controls; do not teach a key that exists once"*:

> **Delete the interact key.** The resistance contact is held with `E`, and `E` is used in **exactly
> one place in the entire game** — `contact_point.gd`, one line. A key that appears once is a key
> that has to be taught, and teaching it costs more than it is worth. Make the hold **automatic on
> proximity**: standing near the mark is the hold.

It is the first half of **M26**, which is still `[ ]` here. M26 waits on M25, M25 waited on *a
mechanic where running is the right answer*, and that shipped in **M33** — so the gate cleared
around twenty milestones ago and neither was picked up. **The player was remembering the decision;
the code is what is out of date.** M55 closes M26's first half as a side effect, and that is where
it should be ticked from.

**This is `CLAUDE.md`'s own rule missed for the second time in one entry** — *the first tool call of
a design task is a search, not a plan*. The alley-roulette correction three bullets down is the same
mistake found the same way. Both times the search that would have caught it was **grep the playtest
files for the noun**, and both times this side searched `src/` instead and treated what the code does
as what the project decided. **The code is evidence of what was built, never of what was agreed.**

Two things follow that are not just bookkeeping:

- **Playtest 02 went less far than the 2026-09-01 instruction, and the gap is the patrol.** It
  removed the *keypress* and kept the *hold* — "standing near the mark is the hold" — on the
  explicit argument that *"nothing is lost… the cost was always standing still in an alley while a
  patrol might pass, not the keypress."* Instant-on-touch removes the standing as well, so the thing
  playtest 02 named as the real cost goes too, and the guard's geometry is what replaces it. **That
  settles the patrol question below: delete it.** There is nothing left for a patrol to interrupt.
- **`E` lives in five places and the build has to take all five**: `project.godot:64` (the binding),
  `contact_point.gd:44` (the read), `tests/test_resistance.gd:98–108` (which presses it),
  `docs/MECHANICS.md:192` (which lists it in the controls) and `docs/ARCHITECTURE.md:57` ("a chalk
  mark, and hold-to-interact"). The last two are the ones a code-only change leaves lying.

What goes with the hold, listed because each is a thing somebody could otherwise put back by
accident:

- `ResistanceSteps.Step.hold_seconds`, and with it the only variation the six steps had besides
  *where* — 3.0, 6.0, 4.0, 3.0, 5.0, 8.0 seconds. The variation moves to the guard and to the task.
- `ContactPoint.progress`, `DECAY_RATE`, the progress arc in `_draw`,
  `EventBus.resistance_hold_changed`, and the HUD's `holding N%`.
- **And a recorded design becomes moot rather than wrong**: *"a reset rather than a deduction"* — a
  `police_patrol` inside `SEEN_RADIUS` resets the hold instead of taking a banked point, because
  *"taking away progress the player has already banked reads as a bug more than a consequence"*.
  With nothing banked there is nothing to reset.

  **It goes, and playtest 02 is what decides it rather than a preference.** This side first proposed
  keeping it as a *block* — a mark under a patrol's eye cannot be picked up until it has passed — on
  the grounds that waiting in an alley is the same sentence in a new grammar. Two things are wrong
  with that. Playtest 02's argument for automatic-on-proximity was that *the cost was always standing
  still in an alley while a patrol might pass*, and instant-on-touch removes the standing, so the
  patrol has nothing to interrupt: it would be an invisible refusal rather than a cost. And a blocked
  *hold* showed a bar that would not fill, where a blocked *touch* shows nothing at all — so keeping
  it would put a silent no-op on the one mechanic playtest 16 already failed to notice existed.
  `SEEN_RADIUS`, `_patrol_is_watching()`, `was_seen`, `EventBus.resistance_seen` and the HUD's
  `seen - wait for it to pass` all come out with the hold.

##### The guard, worked out from the numbers rather than chosen

*"Always guarded"* cannot mean what the trap does today. `ResistanceDirector._maybe_set_a_trap`
calls `spawn_extra(robbery, at)` — the robber is spawned **at** the contact, which is inside
`alley_robbery`'s 30px `hard_fail` radius, so at `TRAP_CHANCE` 1.0 every chalk mark in the game would
be a guaranteed lost day. What the finding actually liked was *"the robber **next to** the chalk
marking — that made it **hard**"*.

Three numbers on the row and one on the contact fix the band exactly, and this is where *"that should
explain how the guard works"* lands: **because the pick-up is instant, the guard cannot be priced in
standing time, so it has to be priced in geometry.**

| | |
|---|---:|
| `alley_robbery.inner_radius` — ends the day | 30 |
| `alley_robbery.pursues_within` — he stands up and comes | 140 |
| `alley_robbery.outer_radius` — his field, the meter cost | 200 |
| `ContactPoint.REACH` — how near she must get | 36 |

- Below **66** (`30 + 36`) touching the mark is death, always. Out of bounds.
- Above **176** (`140 + 36`) the pick-up can never wake him, from any direction. He is scenery.
- Between them, **which way she comes in decides whether he wakes**, because her distance to him is
  her distance to the mark plus or minus his offset. At ~120px, arriving from the far side she is
  156px from him when she touches the mark — *just* outside the trigger — and any lazier line trips
  it, buys her the 1.8s notice, and makes her run. That is the day-3 lesson arriving in act II
  because she chose to.
- The whole approach is inside his 200px field either way, so the meter is charged regardless. **The
  cost survives losing the hold**; only the risk moved from a clock to a bearing.

**So the alley roulette survives, on a different axis.** It was *whether* there is a robber (0.3,
seeded, learnable). It becomes *how near he stands* — a distance drawn in the 66–176 band from
`GameState.day_rng(day, "resistance")`, so 176 is a nuisance and 90 is nasty and the pattern is still
learnable across replays, which is the line this project has drawn between risk and a coin flip.
`docs/NARRATIVE.md` carries the name and needs the sentence under it changed, not removed.

##### The calendar, and why the day brief is now load-bearing

*"pick up instruction -> perform task the next day -> repeat"* is **two beats per task**, so the list
extends rather than replaces. The mark moves to **day 4** — which is where act II starts, so the
resistance opens on the day the city changes character — and the fourteen days come out exact:

| days | step | |
|---|---|---|
| 4 / 5 | mark → **A · give a note to a yeller** | act I row, so it works this early |
| 6 / 7 | mark → **E · carry the package home** | the existing step 3 is already called "A package" |
| 8 / 9 | mark → **D · walk through the checkpoint** | `checkpoint` is day 7+ |
| 10 / 11 | mark → **B · beat the poster crew to the wall** | keeps step 4's deadline, restated over a thing |
| 12 / 13 | mark → **C · stand in the protest** | `protest` is day 12+, so this is its only slot |
| 14 | **the last night** | the finale, unchanged, `needs_goal` |

Two consequences, and the first is the reason M54's day-brief item stopped being a convenience:

- **Miss the mark and there is no task tomorrow.** The brief is how she learns what the resistance
  wants, so *"during the day brief there should be instructions from the chalk marks"* is now the
  **mechanism** rather than a courtesy. The first mark keeps its absolute exemption — no hint — and
  that is free: `day_summary.gd:87` already gates the whole resistance line on
  `has_joined_resistance()`, which is `progress > 0`.
- **`RESISTANCE_GOAL` counts the perform half only**, so 4-of-5 keeps meaning exactly what it meant
  and the good ending's arithmetic does not move. This side's call, stated rather than asked.

**What is deliberately not decided here**: whether a picked-up-but-unperformed instruction expires
at the end of its day or waits. Step 4's `deadline_fraction` is the existing machinery for the first
answer and B's own design wants it. Left until the pairs are built and can be walked.

- [ ] **Give a note to a yeller** *(finding 7, and it comes fully specified)*. *"One task should be
      giving a note to a yeller. that is a risky move since the yeller causes the same level of
      excitement and there might be multiple candidates to test before finding the correct one."*
      Three clauses and each is load-bearing: approaching costs the meter, it costs it *whether or
      not this is the right man*, and there are several candidates so it is paid repeatedly
- [ ] **The day brief carries the chalk marks' words, and it is not a quest marker** *(finding 7's
      first half)*. This is the player **removing** a worry M54 recorded — telling her what the
      resistance wants next is not a marker on a map. M54's first bullet can proceed without the
      hedge it was written with
- [ ] **What guards a chalk mark is the point** *(finding 9)*. *"I did like the robber next to the
      chalk marking. that made it hard to actually get the chalk marking."* It happened by accident;
      it becomes deliberate. This is also the answer to M54's open item about siting the note
      dynamically — what should be near it is something that makes reaching it a decision.

      **Half of it is already built and this entry said it was not.** `ResistanceDirector.TRAP_CHANCE`
      puts an `alley_robbery` at an alley contact one time in three from day 8, seeded so the pattern
      is learnable, and `docs/NARRATIVE.md` calls it *"the alley roulette"*. So the work here is not
      *design a guard*, it is **two smaller things**: the trap starts on `TRAP_FIRST_DAY` 8 and the
      first chalk mark is day 5, so the three steps a player is most likely to reach have no guard at
      all; and the district-placed steps are exempt (`_step.district >= 0`), so half the subquest is
      outside the mechanism entirely.

      **Answered 2026-09-01: both, and the guard is now unconditional.** *"Let's also make sure the
      chalk mark is always guarded by a robber."* `TRAP_FIRST_DAY` goes to the first step's own day
      and the `_step.district >= 0` exemption comes out, so no mark is ever unguarded and no half of
      the subquest sits outside the mechanism. `TRAP_CHANCE` stops being a probability and becomes a
      **distance** — see "The guard, worked out from the numbers" above, which is where the arithmetic
      that makes *always* survivable is. `docs/NARRATIVE.md`'s "alley roulette" paragraph changes
      axis rather than being deleted
- [ ] **More tasks of that shape** — *drafted, put back, and answered.* **All four offered were
      taken**, so with the player's own yeller the set is five: A, E, D, B and C, one per pick-up/
      perform pair, on the calendar above. F (follow the van) is the one draft **not** taken and the
      reason is recorded with it. The counter-example below stands. Written after reading what the
      subquest already is — `docs/NARRATIVE.md`, "The resistance subquest", and
      `src/resistance/resistance_steps.gd` — because the first thing this asked for turned out to be
      half-answered there already

#### What the six steps already are, before anything is added to them

Worth stating first, because the brief reads differently once it is in view. **All six existing
steps are the same verb**: walk somewhere the routing game teaches you to avoid, then *stand still*
for three to eight seconds. The cost is the standing — an alley trickles, and standing is
`EXCITEMENT_DECAY_IDLE` rather than the walking decay, so the meter climbs while you hold. The
variation between them is *where* (alley, civic, industrial) and *how long*.

Two things already in there that the brief did not have to invent, and both should be reused rather
than re-designed:

- **The alley roulette** — from `TRAP_FIRST_DAY` 8, an alley-placed contact has a `TRAP_CHANCE` of
  0.3 of an `alley_robbery` waiting **at** it, seeded from the run and the day so that *the pattern
  is learnable*. `ResistanceDirector` is where it lives and `docs/NARRATIVE.md` has carried it since
  the subquest was written.

  **Which means finding 9 is a re-report and this file did not notice.** *"I did like the robber
  next to the chalk marking… pursuing the resistance should make the game harder"* is the mechanism
  above, and the analysis in `docs/playtests/PLAYTEST-17.md` says *"it happened by accident — the scheduler
  placed a robbery where the chalk mark was"* without looking. Both can be true — the trap starts on
  day 8 and a chalk mark is a day-5 step, so what the player met was probably the scheduler — but
  *the design was already on disk* and the item was written as though it were new. That is
  `CLAUDE.md`'s own rule, missed one milestone after it was written down: **the first tool call of a
  design task is a search, not a plan.** Corrected in the item below rather than quietly.
- **A reset rather than a deduction** — a `police_patrol` inside `SEEN_RADIUS` resets the hold
  instead of taking a banked point, because *"taking away progress the player has already banked
  reads as a bug more than a consequence"*. Any new task's failure mode should be this shape.

So what the brief is actually asking for is **a second verb**, not a seventh place to stand.

#### The pattern the yeller task establishes

Three clauses, and they are the test a drafted task has to pass:

1. **The cost is the approach**, not the destination. You pay to get *near* something loud.
2. **It is paid whether or not it worked.** A wrong candidate costs full price and returns nothing.
3. **There are several candidates**, so it is paid repeatedly and you cannot tell in advance which
   payment was wasted.

Note what clause 2 and 3 together add that nothing in the game has: **a cost with no route around
it and no way to price it in advance.** Every other decision in this game is legible before you
commit — that is the fairness contract — and this one deliberately is not, which is affordable
*only* because the whole path is optional. That is the line the drafts below must not cross:
uncertainty is the price of an optional reward, and it must never reach anything the run depends on.

#### Six drafts, cheapest to build first

Each says what it is, what it costs, where the uncertainty lives, what guards it, and what it needs
that does not exist yet. **A. is the player's own and is here for comparison rather than as a
proposal.**

- **A · Give a note to a yeller** *(the player's, finding 7)*. Several `homeless_yeller` rows are
  live; one is the contact. Approach and hold. **Cost:** the yeller's own field, paid per candidate.
  **Uncertainty:** which man. **Guard:** the man himself — he is +31 and the loudest ordinary row in
  act I. **Needs:** a contact that rides on an *event instance* rather than on a tile, which is the
  one piece of plumbing every draft below shares.
- **B · Read the wall before the poster crew reach it.** The chalk points at a stretch of frontage
  the `poster_crew` are working along; the message is under the next poster they paste. **Cost:** a
  clock — you have to cross the city rather than fold it into today's route — plus standing beside a
  paced, expensive row. **Uncertainty:** which of several walls, and how far along the crew already
  are. **Guard:** the crew. **Needs:** the shared plumbing, and a contact whose window closes when
  a specific instance passes a point, which is `deadline_fraction` stated over a thing instead of
  over the clock.
- **C · Stand in the protest.** The contact is *inside* a `protest` — a 110px wall of bodies, the
  densest thing in the city. **Cost:** the largest single field in the game, for the full hold.
  **Uncertainty:** none, deliberately. **Guard:** the protest. **Needs:** only the shared plumbing.
  This is the pattern at its purest and the cheapest of the six to build, and it is the one to build
  first if only one is taken.
- **D · Walk through the checkpoint.** Not round it — through. The one thing the whole routing game
  teaches you never to do. **Cost:** a `checkpoint`'s field taken head-on. **Uncertainty:** which of
  the day's checkpoints, and `police_patrol` already resets a hold, so being early is worse than
  being late. **Guard:** the patrol. **Needs:** the shared plumbing plus a hold that survives being
  *inside* an obstructing body, which today's holds have never had to.
- **E · Carry it home.** Picking the package up makes the pram heavier: `decay_multiplier` is
  reduced for the **rest of the day**. **Cost:** deferred and total rather than local — every street
  after this one is dearer, so it changes the afternoon's routing rather than one minute of it.
  **Uncertainty:** none; the price is known and enormous. **Guard:** the clock, since a day you
  cannot finish is a day you lose. **Needs:** a per-day modifier on `City.decay_multiplier`, which is
  a **new kind of thing** — every cost in this game is currently a field at a place. Flagged as the
  most interesting and the most dangerous of the six for exactly that reason.
- **F · Follow the van.** Stay within a radius of a moving `delivery_van` or `military_convoy` for a
  stretch. **Cost:** you walk where it goes, at its speed, and it goes down main roads. **Guard:**
  the carriageway. **Needs:** a *proximity-over-time* verb rather than a hold, which is the largest
  new mechanic in the list. Drafted for completeness and **not** recommended: it is the only one
  that would need the resistance to grow a second interaction model.

**And one counter-example, recorded because it is the way to get this wrong.** A contact in a
`burnt_shell` — the one row in the catalogue with a negative walk-through cost — is somewhere the
day is *cheap*. It reads like a resistance task and is the opposite of one: a step that does not
cost is a step that is not a decision, and the subquest's whole design intent is that joining it
costs the core resource.

**Taken: A, B, C, D and E. Not taken: F**, on its own drafted reasoning — it is the only one that
would make the resistance grow a second interaction model. It stays written down rather than
deleted, because a rejected option with its reason attached is a decision somebody can overturn.

**And every "hold" in the six bullets above is superseded**, by the answer at the top of this entry:
*"it should be instant when touching the mark."* It applies to the tasks as well as to the marks,
and it makes the whole subquest **one verb — get to a guarded place and touch it** — which is a
better design than the one the drafts were written against, not merely a simpler one. What each
draft becomes:

- **A** — touch the right yeller. A wrong one costs his field and returns nothing, which is the
  player's clause 2 with no timer needed.
- **B** — touch the wall before the crew paste over it. The deadline is the thing rather than the
  clock, exactly as drafted.
- **C** — reach the middle of the protest. The 110px of bodies is the cost, paid going in and coming
  out; standing in it was never what made it expensive.
- **D** — touch the far side of the checkpoint. A traversal is already instant at the moment it
  completes, so this draft loses nothing at all. Its "a hold that survives being inside an
  obstructing body" requirement simply evaporates.
- **E** — touch the package, then the rest of the day is the task. The only one whose cost was never
  in the contact.

#### The four questions, answered on 2026-09-01

**Kept with the answers under them**, because two of the four came back as something other than the
choice offered and a question whose answer changed the question is worth being able to read twice.

1. **Do these replace the six steps or extend them?** *Recommended: replace.* **Answered: extend,
   and for a reason the question did not anticipate** — *"let's keep them so the progression is
   (pick up instruction -> perform task the next day -> repeat)"*. So a task is **two** steps, the
   list roughly doubles, and `RESISTANCE_GOAL` survives untouched by counting the perform half only.
   The recommendation was arguing about which content to cut; the answer changed the unit.
2. **What does a wrong candidate cost — the meter only, or the day's clock too?** *Recommended: the
   meter only.* **Not contested, taken as read.** A wrong yeller costs his field and whatever the
   walking cost; nothing takes the day off you for guessing.
3. **Is the right candidate learnable on a replay?** *Recommended: yes, via
   `GameState.day_rng(day, "resistance")`.* **Not contested, taken as read** — and it gained a second
   job, since the guard's *distance* is now drawn from the same stream.
4. **May a task cost a nerve on purpose?** *Recommended: not yet.* **Answered: no, and here is what
   should happen instead** — *"losing a nerve means repeating the day with the failed day erased. so
   no it cannot cost a nerve."* Which is a better reason than the one this side gave: a nerve is not
   a resource you can spend, it is a **rewind**, so spending one deliberately is incoherent rather
   than merely dangerous. The replacement — the world getting more dangerous the further in you are
   — is **M56**.
