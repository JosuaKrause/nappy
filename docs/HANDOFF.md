# Handoff

**Last updated:** end of the M22 session.
**Read this first, then [PLAYTEST-04.md](PLAYTEST-04.md), then [TODO.md](TODO.md).**

---

## Where things are

`main` is green and playable. `./tools/test.sh` → **15744 checks, 0 failures** (~80s);
`./tools/check.sh` → OK; `./tools/run.sh` plays it; `./tools/telemetry.sh` says what the last
run actually did.

**Two milestones landed since this file last said anything, and they are both playtest 04's.**

**M27 moved the world to where the player is.** The emphasised finding — *"don't load
everything upfront"* — reads as a performance note and is not one: the game was already at
120fps with 530 agents, and what it actually said is that every population number was being
divided by the 99.2% of the city nobody is looking at. The crowd is a **field** that travels
with her, events are **planned across the whole city at dawn and instantiated near her**, the
cat is the first `AHEAD_OF_PLAYER` event, and traffic keeps a headway. Day 1 is 11–13 events
of which 3–4 are live at any moment. [PLAYTEST-04.md](PLAYTEST-04.md) has the measured table.

**M22 deleted the circles.** `EventAuraLayer` no longer exists and a test asserts it cannot
come back. What replaced it: a **caret over the entity** for danger that *changes over time*
and nothing else, breathing with current emission; a **badge at the screen edge** carrying the
thing's own silhouette for anything lethal or faster than a walk that is off-screen and
closing; the exclamation mark over the player generalised from traffic to events and given a
**second level** for danger already on her; and a **HUD line** for the `city_wide` sources that
had no on-screen presence at all. The vocabulary is in [EVENTS.md](EVENTS.md), "The visual
vocabulary", and the standing decision is in `CLAUDE.md` next to the invariants.

**The one thing to carry into the next session is unchanged and is now louder: nobody has
played any of it.** M19's street, M27's densities and M22's cues are all measured off probes
and screenshots. *"The arterial is for crossing"* is still a claim about a player rather than
about a rig — and M22 sharpened it into a number that wants a human verdict: **walking north up
the arterial from a standing start loses day 1 in fourteen seconds.** The entries that settle
these already exist: `crowd` for contacts and horns, `near` for what came within reach — which
should now be a great deal more than playtest 03's zero — `road` for time in the carriageway,
`ahead` for what the director put in front of her, `lost` for what was around when a day ended.
**Read a run before touching a constant.**

- **M0–M9 complete.** Full 14-day run, four-act escalation, resistance subquest, three
  endings. Documented in `docs/`.
- **M11–M15 complete.** Playtest 01's first five milestones: the quick wins, the SVG asset
  pipeline, the crowd as the noise floor, the M14 balance re-pitch, and block purposes with
  planned arcs.
- **M18 complete** *(taken out of order — see below)*. A day is 180s instead of 330s, aimed
  at **a minute of play with a grace of three**. Calm ground fills the meter in 24s instead
  of 119s: 10x the street rather than 3.5x, so a second in a park is worth ten on the
  pavement. Street gain went *up* (0.24 → 0.42), because M14's relationships are stated over
  `day_length()` and a 45% shorter day would otherwise have stopped making "real progress on
  the way" true.
- **M16 complete.** Road closures. Five kinds, 1–4 streets a day by act, barriers at both
  mouths so a shut street is readable from the junction, and the day-level invariant — at
  least two distinct routes to at least two distinct calm areas — checked by max flow on the
  junction graph before each closure is accepted.
- **M23 complete** *(taken out of order — it was the gate)*. A chronological run log in
  `user://telemetry/`, on by default, read with `./tools/telemetry.sh`. It records what the
  code cannot recompute: the random outcomes that branch a run, the seed the generator
  actually settled on, **the commit it ran on**, what the player did, what came near them,
  and how each day ended. **The gate is now open** — M19's balance half and M24 both have
  their data source.
- **M19 complete.** Bodies on the street, plus the event-density pass. Collision that
  displaces both parties, a lethal carriageway with its own stated fairness contract, traffic
  that gives way at a zebra, `cafe_tables` blocking a pavement from day 1, `dog_walker`
  re-pitched from −0.1 points to +21.6, and `budget_for()` measured rather than derived. The
  exclamation mark over the player came forward from M22 with it.
- **M27 complete** *(taken out of order and immediately)*. The crowd is a field around the
  player, events stream in and out of a radius around her, the cat became the first
  `AHEAD_OF_PLAYER` event, and cars queue instead of driving through each other. It took the
  half of **M20** that was worth having; the rest of M20 is **parked**, not queued. The three
  new invariants it left in `CLAUDE.md` — the day is planned whole and only instantiated near
  her, separation between bodies is positional, and `EVENT_STREAM_RADIUS` stays wider than the
  widest field in the catalogue — are the ones a later milestone is most likely to break.
- **M22 complete.** The rings are gone and the symbol vocabulary replaced them: caret, screen-
  edge badge, the player's exclamation mark at two levels, a HUD line for `city_wide`. Also
  fixed a silent tooling failure — `tools/shot.sh` never forwarded its dev flags, so a shot
  taken to look at one event was of the doorstep and nothing said so — and added `--walk`,
  without which a screenshot of a post-M27 world is a screenshot of almost nothing.

## The decisions that govern the next milestones

Taken at the end of the M16/M18 session and easy to miss, because they are decisions rather
than code. All of them are written up in `PLAYTEST-02.md` (decisions 9–14).

1. **The beginning is challenging too.** Not extremely difficult, but a player who never
   meets danger never learns to deal with it. The measurement below says act I and act II
   currently cost nothing at all, and "the early game teaches events are safe, then act III
   kills you" is the worst of both. **M19 has to make an act I street cost something.**
   *(Done, and then some: M19 gave the street bodies and M27 put three or four times as many
   of them where she is looking. Whether act I now costs too much is the open question, and it
   is the one a human has to answer — see the fourteen seconds above.)*
2. **Difficulty is self-selected through the extra quests.** The resistance is the dial. That
   is why the base game has to be hard on its own — the dial *adds* difficulty, it does not
   supply it. Consequence: "how visible should the resistance be" stopped being a curiosity.
   A player who never finds the dial is locked to the easiest setting and never told there
   was one.
3. **The act I/II numbers are set from data, not argument.** Build the mechanisms (M19), ship
   telemetry (M23), read real runs, then pitch. This made M23 a gate rather than a
   recommendation, which is why it went first. **The gate is open** — M19's balance half is
   now waiting on runs, not on code.
4. **Telemetry is an ordered log, not a metrics dump** — what happened, in what order,
   readable top to bottom with no tool. It records what the code *cannot* recompute, above all
   the **random outcomes that branch a run** (a one-shot that fired, a block arc that
   advanced, an alley trap that was set): those depend on run history, so no seed reproduces
   them. Anything derivable from the seed, `Tuning` or the catalogue stays out. *(Shipped in
   M23; [TELEMETRY.md](TELEMETRY.md) is the version to work from now.)*
5. **The resistance stays hidden and loses its key.** *(Closes an open question carried since
   M8.)* No marker, no quest log — wanting the difficulty dial and finding it are the same
   behaviour. But `E` appears in exactly one line of the game, so the hold becomes automatic
   on proximity: the cost was always standing still in an alley, never the keypress. M26.

## Read this before touching the event or signalling code

**The cost table has been regenerated and is now asserted by a test.** `docs/EVENTS.md`, "What
an event actually costs". Three rows are negative — `poster_crew`, `barricade`, `burnt_shell` —
and all three are deliberate scenery; `tests/test_events.gd` names exactly those three as
exemptions and requires everything else to cost more to walk through than to walk around. A
*fourth* negative event therefore has to be a decision rather than an oversight. The table is
only about events, and since M19 that is no longer the whole cost of a street: a contact with a
pedestrian is ~15.6 points and a car's horn ~8, and neither is in the catalogue. **M27 widened
that gap again**, and the street is now most of the day — a balance argument that reaches for
the cost table alone is answering a narrower question than it thinks.

**Running is still the wrong move against every event in the game.** `EXCITEMENT_FROM_RUNNING`
(9/s) plus the collapsed decay (3.5/s → 0.5/s) beats the shorter exposure in every single
case. The run button is a trap, and M19 did not change it — the lethal car is escaped by
stepping over a kerb, not by outrunning anything. This is why M25 is written as a mechanic to
build rather than a constant to tune.

**No circles, and the replacement has shipped.** *(M22 — this section used to say "has
started".)* The rings are deleted rather than restyled, `EventAuraLayer` is gone, and
`tests/test_danger.gd` asserts it cannot come back, because a comment in a deleted file cannot
stop the next person reaching for a ring when something new needs signalling. Two rules in the
replacement are the whole reason it is better, and both are easy to lose:

- **A cue that marks everything says nothing.** The caret is for danger that *changes over
  time* — telegraphing, lethal, pulsing, swelling — and **not** for whatever is loudest. A
  first pass used "louder than the walking decay", which sounds defensible and marked
  `poster_crew`, `barricade` and `burnt_shell`: the exact three rows the cost table calls
  scenery. That is the ring's own mistake in a new shape, and the test caught it.
- **The mark breathes** with current emission. Without it a pulsing event stops being something
  to time a pass through and becomes something that hurts at random.

The badge announces only what she cannot outwalk, and it **must carry a silhouette** — an arrow
that can only say "something" is an anxiety rather than a warning. Adding to this vocabulary is
a design decision, not a drawing one; read `docs/EVENTS.md`, "The visual vocabulary", first.

## Four playtests, and the order they left behind

All four are live plans: **[PLAYTEST-01.md](PLAYTEST-01.md)** (thirteen findings → M11–M17),
**[PLAYTEST-02.md](PLAYTEST-02.md)** (twelve → M18–M26), **[PLAYTEST-03.md](PLAYTEST-03.md)**
(the first read off a run log; it reorders rather than adds), and
**[PLAYTEST-04.md](PLAYTEST-04.md)** (seven findings; adds M27 and moved M22 and M21 to the
front). Read 04 before picking anything up; the summary here is not a substitute for it.

The queue is numeric except where something jumped it, and each jump had one practical reason:
**M18** because closure counts tuned against a day that was about to halve would have been
tuned wrong; **M23** because it was the gate on M19's balance half and on M24; **M27** because
playtest 04's emphasised finding turned out to be underneath three of the other six, and
because M21 and M22 are both judged against a street that now has traffic on it; **M22**
because the player asked for the circles a second time; and **M21**, next, because four-block
calm zones are the structural fix for twenty seconds of walking in a circle and traffic that
overtakes is not.

One piece of history worth keeping, because the file is now the only place it is legible:
**M22's exclamation mark was pulled forward into M19 and the rest of M22 was not** — a lethal
car has no telegraph phase to ring, and redesigning the signalling of eighteen events in a
session about physics was the wrong shape. M22 then generalised the cue rather than replacing
it.

## What to do next, in order

### First: play it, and read the trace

Not a milestone, and it comes before one. Three sessions in a row have changed what a street
costs — M19 gave it bodies, M27 put three or four times as many of them where she is looking,
M22 changed what she can see coming — and **decision 11 says those numbers get set from traces
rather than argued about**. A fifth playtest is the highest-value thing available, and the
questions are sharp enough to be answered off a log:

- **Is the arterial crossable?** Walking its length now loses day 1 in fourteen seconds, which
  is intended; crossing it at a zebra should be routine. `road` and `crowd` entries say which
  happened. If a player never works out that the arterial is for crossing, that is the finding.
- **Do bumps read as the player's fault?** The contact radius is under half a lane spacing, so
  a line exists to walk — eleven contacts down a lane centre against one on the midline. Whether
  a person finds it is a different question. Watch `crowd` bump lines against their counts.
- **Does anybody get run over, and does it feel fair when they do?** A `lost` line preceded by
  a `crowd` horn line is a fair death; one with no horn before it is a bug in M19's work.
- **Is a day a city or a gauntlet?** `near` entries per day, against playtest 03's zero — and
  `ahead` for what the director sited across her line.
- **Do the new cues get read?** M22's whole case is that a caret, a badge and an exclamation
  mark say more than a ring did. A `run` or `turn` following a badge is the evidence; nothing in
  a test can see it.

### Then M21 — the city overhaul, which has jumped M20

Four-block calm zones. Playtest 03 finding 2 is why it moved: the traced player spent twenty
seconds walking in a circle inside a courtyard, and **that is what the rules ask for** —
standing still drains sleepiness at 1.0/s, walking on calm ground fills it at 4.2/s, and a
calm block is a few tiles across. Progress-requires-motion plus small-calm-area is jointly
sufficient for a lap. M18's shorter stretch cut the number of laps and could not remove the
lap; no further balance pass will either. A four-block zone turns the lap into a route, which
is the game's actual verb.

### M17 — the route map

The planning screen, rendering the block states M15 introduced *and* the closures M16 adds.
`CityState.changed_on(block)` is already recorded for exactly this — shading "this is new" is
what makes the screen worth opening twice.

M16 raised the value of this: closures are legible at the junction and **not** before it. A
player two junctions away cannot know a street is shut, and the map is the only thing that
can tell them. That gap is stated as a gap in `docs/CITY.md` rather than papered over.

M23 raised it again, and gave it a test: the log's `closure` entries say where a barrier was
seen from, and a `turn` following one says whether it changed the plan. If closures read as
scenery in the traces, that is the argument for the map screen — and afterwards, the same two
entries are how to tell whether the map fixed it.

### Then the rest, per PLAYTEST-02.md

M18, M19, M22, M23 and M27 done; M21 pulled to the front above.
**M20 traffic that behaves** is **parked, not queued**: M27 shipped the half that mattered
(cars follow and queue; zero overlapping pairs a frame, down from 5.2), and what is left —
overtaking, eight-way driving, a crash as a catalogue event — is unasked-for by any playtest.
**M24 the city remembers where you went** (spoil the park you relied on yesterday) — the
`calm` entries it needs are being written now. **M25 patrols, and running that matters** — the
`run` entries are the measurement it will be judged by, and today they all say the same thing.
It also picks up playtest 03 finding 3, the walk home being a formality: patrols that were not
there on the way out are the return phase's own pressure.
**M26 teaching the controls** — delete the interact key, then teach walking and running,
ending in a scripted day-1 event that requires a short run. M26 must come after M25 for
correctness, not scheduling: forcing a run before running is ever the right answer teaches a
move that is never correct again.

M21 rewrites the lattice enumeration in `src/routes/street_network.gd`. The graph half of
that file — route counting, the invariant, the doorway exemptions — survives untouched and
matters *more* afterwards: with holes in the lattice, route redundancy stops being true by
construction and has to be checked by search, which is what that file is.

---

## Standing decisions

Taken in the M12a session and still governing everything after it. All four are recorded in
`PLAYTEST-01.md`; repeated here because they change the design.

1. **Assets are SVG.** Confirmed. Graphics get refined later — *"for now we need something
   workable"*, so do not gold-plate the art. Generating images or using freely-licensed
   assets is also acceptable.
2. **An ordinary street makes sleep progress, but never enough** to finish a day alone.
   A day must be unwinnable on street gain and comfortably winnable with one calm stretch.
3. **Finding 12 narrows the route choice, it does not remove it.** Not a single forced path
   — several viable routes and *several quiet destinations to choose between*. The day-level
   invariant to enforce in M16: at least two distinct routes to at least two distinct calm
   areas.
4. **The city is mutable day to day, by recontextualising areas.** *(Implemented in M15.)*
   The generator plans each block's *purpose arc* up front so blocks transition coherently.
   This **superseded the "`CityMap` is immutable for the run" invariant in `CLAUDE.md`** —
   replaced by: the street lattice and block boundaries are fixed; what a block *is* may
   change, only along its planned arc. Rendering reads block state, so `City.start_day()`
   repaints the ground and re-dresses the blocks every morning.

---

## Gotchas learned in M22

- **A threshold that sounds defensible can be the old mistake in a new shape.** "Mark anything
  louder than the walking decay" marked `poster_crew`, `barricade` and `burnt_shell` — the three
  rows the cost table already calls scenery, and a set the rings would have marked too. The rule
  that works is not about magnitude: mark danger that **changes over time**.
- **Deleting a thing does not delete the habit.** `tests/test_danger.gd` asserts `EventAuraLayer`
  cannot come back and that the whole catalogue is never marked at once, because the failure this
  standing decision exists to stop is somebody reaching for a ring the *next* time something
  needs signalling, and a comment in a deleted file cannot stop that.
- **An additive `warn()` beats a setter, and the reason is ordering.** The crowd and the events
  both look at the ground she is standing on in the same frame. With a setter, whichever ran
  second cleared what the first said — silently downgrading a lethal event to nothing because no
  car happened to be coming. `Stroller.warn()` raises the level and never lowers it.
- **Force a cue's condition on, look at it, and put it back.** The screen-edge badge needs
  something lethal off-screen and closing, which a six-second screenshot cannot be asked for.
  Forcing it found three defects no test could see: it collided with the excitement meter, the
  icon was squashed by a square box, and some badges had no silhouette at all. That last one is
  the point of the badge — an arrow that can only say "something" is an anxiety, not a warning.
- **`tools/shot.sh` was silently eating its own flags.** Every dev flag passed to it was dropped,
  so a screenshot taken to look at one specific event was of the doorstep, and nothing said so.
  It forwards them now and has `--walk`, which holds a direction down for the whole run —
  necessary since M27, because a screenshot of a standing player is a screenshot of almost
  nothing.
- **The suite count went down, and that is correct.** 15890 → **15744**: the aura-layer checks
  went with the layer. A drop in check count after a deletion is fine; a drop after anything else
  is a suite that stopped running.

## Gotchas learned in M27

- **A brake cannot open a gap that does not exist.** Two cars that start inside each other both
  choose zero speed and stay there. Separation between bodies is **positional** — now an
  invariant in `CLAUDE.md`, and the same shape as M19's player bump.
- **Recycling everybody onto the same pixel is a pile-up generator.** Re-entering agents placed
  on the exact edge coordinate produced eight overlapping pairs a frame on a road nobody could
  see, and once cars keep a headway the pile never sorts itself out. They enter in a band.
- **A lane has a capacity.** At the first density the arterial wanted 194px of spacing per car
  and had 118px of lane per car: it jammed solid and no controller helped. Car counts come from
  what a lane can carry.
- **A weight whose denominator changed is a trap.** `ARTERIAL_BUSYNESS` used to mean one
  street's share of sixteen corridors and now means its share of the three or four inside the
  field box, so the *same number* put half again as much traffic on the arterial — 0.6%
  crossable, 22s at the kerb. That is a wall, not a hazard. It went 5.5 → 5.0.
- **Code after an unconditional `return` never runs, and the tests are what find it.**
  `CrowdAgent`'s lateral recycle check was written after the along-axis one, so a player walking
  north left everybody on every east-west street she crossed behind forever, and the pavement in
  front of her would have drained over a minute of play.
- **A mobile event starts moving when its telegraph starts**, which is right for a fire engine —
  its telegraph *is* the approach — and was catastrophic for the cat: a one-street crossing at
  240px/s finished during its own 1.6s telegraph, so it never reached full intensity and
  `CAT_RUNNING` had never drawn a single frame in six milestones. A green suite, a passing
  fairness contract and a screenshot all had nothing to say about it.
- **Streaming has two floors on its radius and the larger wins.** Half the viewport diagonal, so
  nothing is seen to appear; and wider than the widest field in the catalogue, so an event is
  outside its own outer radius the moment it becomes visible. Without the second, streaming is a
  way of dropping events on people and the telegraph contract is a lie.
- **Rejected: making the arterial quieter to make it crossable.** It has to stay above the idle
  decay or standing still on the busiest street in the city becomes a strategy, which is the one
  thing the crowd exists to stop. The resolution is the zebra, which the generator puts at every
  junction.

## Gotchas learned in M19

- **A green suite and a screenshot both passed a collision that was catastrophically wrong.**
  A pedestrian slower than the player was pushed *further along their own line of travel*,
  which separates nobody at 92 against 60 — so she accumulated a wedge of pedestrians in front
  of her, all permanently in contact, all permanently startled, at 150 excitement per second.
  Nothing in the test suite could see it and the screenshot showed a normal street. Forty
  seconds of a scripted walk down a real pavement showed it immediately. A bumped body **steps
  aside** now.
- **The contact radius is set by the lane spacing, not by a body's width.** Pedestrian lanes
  are one tile apart, so the only line with no contact on it is the midline between two of
  them. At 18px there was no such line anywhere on a two-tile pavement: the same forty-second
  walk cost eleven bumps however carefully it was done, which is a toll rather than a decision.
  At 14px it costs two. That relationship is the assertion in `tests/test_crowd.gd`, not the
  number.
- **A contact has to startle once, not once per frame.** She walks faster than a pedestrian, so
  a person bumped from behind stays inside the radius for the better part of a second.
  `CrowdAgent.touching` is the hysteresis; without it one person cost what a crowd should.
- **The throwaway probe is the headless stand-in for playing a minute.** A
  `tests/test_zz_*.gd` that prints numbers and is deleted before committing found both of the
  above and set `budget_for()`. `CLAUDE.md` carries it next to the screenshot rule.
- **A budget is not a count, and the gap is about a third.** `_ensure_one_usable_park` strips
  whatever reaches the calmest block and `_ensure_the_city_is_still_walkable` drops
  obstructions that would seal the city, so a budget of 18 places 13 or 14 events. Density has
  to be measured from what a day *places*, over several seeds. Deriving it from the formula
  gets you a number that is a third too small and looks right.
- **`move_and_slide()` owns `velocity`.** Folding the collision deflection into it made
  `is_idle()` and `run_excess_ratio()` answer for the crowd rather than for the player;
  restoring `velocity` afterwards was worse, because it discards the slide's own correction
  and walking into a wall stops reading as idle. The deflection goes through its own
  `move_and_collide()`.
- **A cue over the player's head has to stay near the player's head.** At 68px the exclamation
  mark drifted far enough up the screen to read as belonging to whatever was standing behind
  her — which, for the one cue in the vocabulary that means *this is about you*, is the single
  thing it must not do. She is 46px tall; the mark sits at 54.
- **A dead comment survives a deleted feature and then lies about its neighbour.**
  `busy_road`'s doc comment outlived it by six milestones in `event_catalogue.gd`, ending up
  attached to `_dog_walker()` and describing arterial traffic noise. Deleted here.

## Gotchas learned in M23

- **`process_mode` is inherited, so one `PROCESS_MODE_ALWAYS` exempts a whole subtree.** Found
  by playtest 03, present since M6. `main.gd` sets it on itself so Esc quits while the summary
  has the tree paused; every descendant defaults to INHERIT, so the city, the player, the
  crowd, the events and the resistance director all inherited the exemption and
  `get_tree().paused = true` paused nothing for six milestones. The player kept walking behind
  the screen saying the day was over — and the **resistance deadline kept running out**, which
  could lose a run its good ending while somebody read a summary. Fixed with
  `main._pauses_with_the_game()`; a new node under `Main` needs that call and nothing warns
  you. Also in `CLAUDE.md`.
- **The format only gets tested by the first real question asked of it.** M23 shipped, and the
  first question put to it the next day — *did I walk down the road, and did a car go through
  me* — it could not answer. Road time was not recorded (only road entry, so walking a mile
  down the carriageway looked identical to crossing at each junction), and the crowd was
  invisible by design. Both are entries now. Reasoning about which fields would be useful is
  not a substitute for being asked something.
- **A stretch in progress when the day ends is never written down.** The `road` entry fired on
  *leaving* the road, so a player killed by the traffic they were walking among got no entry
  at all, having never left it. Anything accumulated over a span needs flushing at day end.
- **A green suite says nothing about whether a log is any good.** The observer passed every
  test and its first trace of a minute's actual walking had four defects in it: a `run` entry
  claiming a six-hundred-pixel event was "in reach", two instances of the same event that the
  log could not tell apart, a duplicated field, and — the bad one — a meter breakdown reading
  `crowd 0.0, events 0.0` while excitement climbed, because the player was doing it to
  themselves with the run button and nothing said so. This is the screenshot rule with a
  different output format, and it is now in `CLAUDE.md` next to it.
- **The breakdown has to add up or it lies by omission.** Printing the two spatial sources was
  true and useless. It prints the baby's whole incoming rate alongside them now, so whatever
  the remainder is — running, an alley — is visible as a remainder.
- **Hoisting a roll to print it is the dangerous edit.** `if rng.randf() > threshold` becoming
  `var roll := rng.randf()` is identical, and *nearly* the same edit that consumes an extra
  value and moves every event placed afterwards. `tests/test_telemetry.gd` plans all fourteen
  days twice, with the log off and on, and compares event ids and positions to the pixel.
- **Telemetry must be inert by default, not disabled by a flag.** The suite creates schedulers
  and city states directly; if the log were on by default it would write a file per check.
  `Telemetry` is dormant until `begin_run()`, which only `main.gd` calls — so the suite pays a
  boolean and the game gets a trace with no flag to remember. The observer is not even added
  to the tree when telemetry is off.
- **A roll that passes and then fails to place is invisible.** `_place_one_shots` can roll a
  one-shot in and then find nowhere to put it, in which case it is *not* consumed and gets
  rolled again tomorrow. From outside that is indistinguishable from a roll that failed, so it
  gets its own line.
- **`user://` is somewhere nobody can find.** On macOS it is inside `~/Library`, which Finder
  hides. The path is printed at the start of every run *and* `tools/telemetry.sh` exists, and
  it still took someone asking where the logs were. Neither was sufficient alone.
- **macOS ships bash 3.2, so no `mapfile`.** `tools/telemetry.sh` reads `ls -t` in a `while`
  loop instead, like the rest of `tools/`.

## Gotchas learned in M16

- **Check before accepting, not after placing.** The obvious shape for closures — place N,
  then drop them until the day is legal — has an order-dependent answer and a window in
  which the day is illegal. Testing each candidate against the invariant *before* accepting
  it costs the same and has neither problem. The reason it is affordable is the next point.
- **Counting distinct routes is a max flow, not a search for routes.** Two edge-disjoint
  paths is what "two distinct routes" means, and by Menger's theorem the count is also "how
  many streets it would take to cut this off". Two BFS augmentations over a 64-node junction
  graph — not a flood fill over ten thousand tiles — which is why it can run on every
  candidate closure of every day inside a test suite.
- **A doorway is not a route, and that has to be said out loud.** The first version of the
  brute-force cross-check closed every street in turn and asserted the area survived. It
  failed on three courtyards, correctly: a courtyard has one archway onto one street.
  Two routes has always meant two routes *to the door* — the same exemption the home has
  had since M3 — and the test now excludes access streets and carries a second test that
  states the consequence rather than leaving it implicit.
- **A cross-script enum is not the same type as itself.** `f(side: Side)` called from
  another script with a `StreetNetwork.Side` value fails to parse. Widen to `int`.
- **The crowd made the closure legible for free.** Agents divert at the junction rather than
  driving through a barrier, so the street with nobody on it is the street that is shut —
  which reads from a block away, further than the barrier does. That was a side effect of
  making the crowd respect closures, and it is better than the thing it fell out of.

## Gotchas learned in M18

- **Cutting the day tests the tests.** Every M14 balance claim is written as a relationship
  over `day_length()`, and halving the day is exactly the change those relationships exist
  to survive. They did: nothing needed its shape changed, and the one that pushed back —
  "a whole day of street walking still makes real progress" — pushed back correctly, which
  is why street gain went *up* while the day got shorter.
- **A shorter day is a faster suite.** `tests/test_balance.gd` steps a real `Baby` through
  fourteen days at 1/60s; it went from 94s to 27s for free.

## Gotchas learned in M15

- **A carved interior needs a way in.** Courtyards were sealed rects the first time and the
  connectivity check failed on *every seed*. The archway is now part of `BlockLayout`, and
  it is paved as an alley on purpose: reaching hidden calm costs a few seconds of somewhere
  you would rather not be.
- **Put arc invariants in the arc, not in the callers.** A commercial block could be planned
  to go dark on day 10 and then burn on day 3, because two independent rolls wrote their own
  `from_day`. `BlockPlan.then()` now clamps each step to at least the previous step's day.
  `tests/test_blocks.gd` found it on 13 of 24 seeds.
- **Protect the calm ground, not the block.** `_ensure_one_usable_park` matched events
  against the whole block lot. For a courtyard — four tiles inside a residential block —
  that stripped every event off streets the player was never going to settle on. It matches
  `BlockLayout.open_rect` now.
- **Calm ground must not read as a rooftop.** From above, the first quiet-square paving was
  the same warm beige as the building roofs. Since M14 finding calm ground is the whole
  game, so the tile is deliberately cooler than anything else in the palette. This will
  matter more in M17, where the map screen *is* the view.
- **`var x := SomeEnum.keys()[i]` will not parse.** The value is a Variant, and "inferred
  from a Variant value" is an error, not a warning. Annotate: `var x: String = ...`.

## Known slow: three suites are 70% of the ~80s

Per-suite timings are printed by `tools/test.sh`. As of M22: `test_generator.gd` 21.6s,
`test_balance.gd` 19.3s, `test_crowd.gd` 15.0s, everything else under 5s. `test_generator.gd`
generates 200 cities and runs a route-redundancy sweep that closes each street segment in turn
on the *tile* grid; `test_crowd.gd` is new weight from M19 and M27, and it walks real rigs down
real pavements, which is exactly the cost that buys the bugs a data-level test cannot see.

The generator sweep is now the obvious thing to speed up, and M16 has already written the
tool: `StreetNetwork.route_count()` answers the same question by max flow on the junction
graph in a fraction of the time. It has deliberately not been swapped in — the tile-level
sweep checks something the graph cannot, namely that the *tiles* agree with the lattice — but
if the suite needs to get faster, running the cheap check on all 200 seeds and the expensive
one on a handful would be honest.

## Gotchas learned in M14

- **Pitch balance numbers against the day, not against each other.** The old numbers were
  all mutually consistent and the day was still winnable by circling the block, because
  nothing tied the fill rate to `day_length()`. The two tests that matter now are written
  as `GAIN * day_length(day) < METER_MAX` and `METER_MAX / calm_gain < day_length * 0.6`,
  so lengthening the day cannot quietly make the street sufficient again.
- **Arithmetic is necessary and not sufficient.** Whether a park fills the meter depends on
  whether the crowd pushes it over the freeze threshold, which no data-level test can see.
  `tests/test_balance.gd` stands a real `Baby` in a real city with that day's crowd and
  events. It is what caught that the claim needed checking on all fourteen days, not one.
- **Check the short day.** A calm stretch of 139s looked fine against the 330s day and was a
  stopwatch race against the 264s curfew one. Every balance claim here is measured against
  `day_length(RUN_LENGTH_DAYS)`.

## Gotchas learned in M13

- **A runtime error in a test suite hangs the runner; it does not fail it.** `run_tests.gd`
  calls each suite synchronously and quits at the end, so an error aborts `_ready()` before
  the quit and the headless process sits there printing nothing. Deleting `busy_road` left
  three suites calling `by_id("busy_road").intensity`, and the symptom was a test run that
  produced *no output at all* for six minutes. No output means an error, not a slow suite.
- **A negative-width `Rect2` normalises** — already in `CLAUDE.md` from M12c, and it bit
  again here: it is the same helper the whole crowd draws through.
- **Moving a `Node2D` does not invalidate its draw list.** The transform is applied when the
  retained list is replayed, so 530 agents only need `queue_redraw()` when their *picture*
  changes — a turn, a flip — not when they move. That is the difference between 530 redraws
  a frame and a handful.
- **Give each agent its own RNG.** Seeded per agent from the day, not shared, so a turn
  taken at a junction cannot depend on the order agents happen to reach junctions in — which
  frame timing would otherwise decide, and determinism would be a lie.

## Gotchas learned in M12c

- **A negative-width `Rect2` does not flip `draw_texture_rect`** — it is normalised, so the
  sprite lands a full width sideways. It reads as art sliding off its own shadow rather than
  as a failed flip, which is how it was found. `Sprites.draw_standing()` mirrors the
  transform around the anchor instead, and is the only place that does.
- **A sprite cannot swing its own legs.** The mother's gait was a procedural stride and a
  bob; with the legs drawn into the art, both had to become a two-frame swap. The bob is
  baked into the second frame rather than added on top, or the two would compound.
- **Deleting the colours was part of the job.** Two thirds of `Palette` no longer painted
  anything once the art moved into SVG, and a constant that looks authoritative but controls
  nothing is a trap for whoever tries to retint the game next. What stayed is what the code
  still picks at runtime: light, act cast, aura, chalk, shadow, building variant.

## Gotchas learned in M12b

- **Edge overlays beat corner tiles.** The roof parapet is four edge tiles drawn on top of
  the roof fill, each transparent apart from its own band. A corner cell takes two of them
  and the parapet turns by itself — no corner tiles, and no combinatorial explosion when a
  roof is only one tile deep and a row has to be both its north and its south edge.
- **Multiply the colour, not the art.** Wall and roof fills are authored near-white and
  passed the variant colour as `draw_texture`'s modulate, so six roof colours cost one
  asset. Windows are drawn *after*, unmodulated: a lit window is the same warm colour
  whatever the building is painted.

## Gotchas learned in M12a

Beyond the ones already in `CLAUDE.md`:

- **`Sprite2D` with `centered = false` puts the node at the sprite's top-left.** Y-sorting
  then compares the wrong edge. Everything in this project is feet-anchored: put the node on
  the ground plane and use `offset` to draw upward.
- **A y-sort tie is broken by tree order.** The front door sits in the wall of the building
  above it at exactly the same `y`, so it has to be added to the tree *after* the buildings.
- **A tile cannot carry a line that falls on its own edge.** The road centre line sits on the
  seam between the two carriageway tiles, so it is authored as two halves that meet
  (`road_line_e`/`_w`, `road_line_n`/`_s`).

## How the asset pipeline is put together

- `assets/tiles/*.svg` — 17 ground tiles, 32×32, hand-editable. **There is no regeneration
  script**; they were emitted once and are now the source of truth.
- `assets/ground_tileset.tres` — one `TileSetAtlasSource` per tile. **Source ids are
  positional and `src/city/ground_tiles.gd` mirrors them by hand.** Adding a tile means
  appending to both, in the same order.
- `src/city/ground_tiles.gd` — the only place that decides which tile a cell gets.
- `assets/buildings/*.svg` — 11 building tiles, 32×32. `wall`/`roof` are fills (modulated);
  `wall_edge_*`, `wall_base`, `roof_edge_*`, `window_*` are alpha overlays drawn on top at
  full colour. No `TileSet` here: `Building._draw()` assembles them per lot, which keeps one
  node per building and lets a lot pick its own colour.
- `assets/rig/`, `assets/props/`, `assets/events/` — feet-anchored sprites, drawn through
  `Sprites.draw_standing()`: the node sits on the ground plane, the art rises from it.
  Anything whose size carries meaning (a fire's flames, a barrier's width) passes an
  explicit size rather than using the texture's own.

Run `./tools/check.sh` after touching assets; it does the import pass that generates
`.import` files.

---

## Working agreement

From `CLAUDE.md`, which is the fuller version:

- Feature branch per milestone, `--no-ff` merge to `main` when green.
- Run `check.sh`, `test.sh`, and a `shot.sh` screenshot before committing anything visual.
  A green `check.sh` says nothing about whether the game looks right.
- Commit the docs in the same commit as the code.
- Update **this file** at the end of each work session.
