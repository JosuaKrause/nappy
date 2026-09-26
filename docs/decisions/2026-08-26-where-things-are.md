## Where things are

`main` is green and playable. `./tools/test.sh` → **175380 checks, 0 failures** (~200s);
`./tools/check.sh` → OK; `./tools/run.sh` plays it; `./tools/telemetry.sh` says what the last
run actually did.

**M50 is done except for step 3.** The day's corridor exists (`RouteTree`), the telemetry map draws
it *and* what was placed against it, the city has permanent structure — dead ends and big buildings
that join two blocks — and the day is **placed by role**: walls off the tree, friction on it, set
pieces offered at every site of a covering set with one of them happening. Off the corridor is a
**range** now rather than a bias, very costly at the rim and deadly beyond it. What is left is
**placeholders** (step 3, rewritten after the player's budget correction and not started), the
resistance note's alley as a set piece, and the catalogue-caps half of *"blocking events all over"*.
**Three invariant decisions are taken** *(2026-08-31)*: the two-routes guarantee is reachability,
the park rule refuses ground at placement rather than stripping events afterwards, and M28's lethal
clearance rule is exempted off the corridor. See `docs/TODO.md`, M50.

**M51 and M52 are done, M53 and M54 are the queue.** M51 is playtest 15 — the cul-de-sac the crowd
walked through, the spine's zebra, the police car's flank, the game-over heading, the title colour,
the bridge. M52 is the calm rate curve (`1 / sqrt(blocks)`, 21× / 29.7× / 42×) and the signal heads
moved to the kerb they were always documented as standing on; its remaining item is the calm
**shapes**, which is M47's entry. M53 and M54 are playtest 16, and the pick-up block at the top of
this file is the order.

*(The count went 202075 → 175380 in that session, and the drop is one assertion narrowing on
purpose: `_test_nothing_happens_inside_a_lethal_field` no longer walks every other placement past a
lethal **wall**, because a wall is exempt from that rule now. It still checks every lethal set piece
and asserts that a run places both kinds, so the exemption cannot become a way of asserting
nothing.)*

*(The count went 135308 → 202075 in that session. Most of it is one new test —
`test_calm_she_has_not_used_is_left_alone` walks three seeds through a whole run and asks the
question of every plan against every unused calm area — and the rest is that a day now places 5–9%
more events, so every per-event assertion runs more often.)*

**The count went 74540 → 122119 on M41, and it is the lattice rather than the milestone.** The
jump is +64% and it wanted checking rather than asserting, because a count that moves by that much
without a deletion or a new rule is usually a suite that started doing something else. Measured by
putting `CITY_BLOCKS` back to 9×9 with all of M41's code in place: **74362**, against `main`'s
74540 — the same suite asserting the same things about a smaller city. So M41's own new
assertions (the signal contract, the junction box, the ground rate, the boundary) are worth about
nothing on the count and the whole of it is 49% more city being asserted over per block, per
street and per seed. Two things came out of that measurement worth keeping: the run at 9×9 fails
three checks in `test_telemetry.gd` (*"the retry has 5 `delivery_van` where the day had 7"*), so
the retry-determinism assertion now has a **city size** in it — M41's act I caps went up with the
lattice and a smaller city cannot spend them — and the ~161s is the honest new cost of the inner
loop, which M44 had just brought down to 96s.

**The counts for M42 and M44 were never written down here** — that is the two milestones of
staleness this file opens by admitting — so the 74540 above is `main` as M44 left it and there is
no M42 figure to compare against.

**The check count went 46394 → 46498, and all of it is M37 asserting the new rule.** Two of those
checks run over the whole catalogue — one row per look, one silhouette per look — plus the baby
cue's four answers, which are a test at all only because the decision was pulled out of `_draw()`
and given a name. Nothing was removed and no plan moved: the density probe returns the same numbers
day for day against `main`.

**The count before that went 46563 → 46394, and almost all of the drop is one row changing shape.**
`homeless_yeller` is mobile now, so it needs an `ALONG_STREET` route and `_place_one` re-rolls when
one cannot be built — mostly on `SQUARE` tiles, where a corridor axis is not meaningful. Several
suites assert per *placed* plan over fourteen days, so a handful fewer men shouting is a couple of
hundred fewer checks about the same days. Events placed per day is unchanged over five seeds, which
is the number that says it is the same city. M36 added ~35 of its own: the pause, the paced beat,
the waiting pursuer, and the pursuit walk-through now running over the whole catalogue rather than
over one row.

**The count before that went 46522 → 46563.** M35 added forty-one: the three answers to a pursuit walked
rather than asserted, the leaving rule and its out-of-sight and backstop halves, and the two new
distance clauses on `validate_pursuit` running over the catalogue on load. Nothing was removed —
the spoiler crowd changes what is in one lot rather than how many events a day places, which the
probe confirms at 40.0 and 76.0 unchanged.

**The count before that went 46607 → 46522, and the drop is the same shape as the one before it.** M34 added
about 250 checks — the solidity rule over the whole catalogue, the lethal-body constraint, the two
placement rules asserted over fourteen days, and the pram's own radius against the scene it is
authored in — and removed about 330, all from one place: `delivery_van` and `ice_cream_van` want
the kerb lane now, so they are offered half as many candidate tiles and land slightly less often,
and several suites assert per placed plan. Events placed per day is unchanged over five seeds, so
this is the same suite asserting the same things about the same days.

**The count before that went 47085 → 46607, and that drop wants its own explanation.** M33 added ~50 checks —
the pursuit contract, the caret's timeable rule, the motion-shaped decay ordering, the running
ordering row by row — and removed ~530, all from one place: `_along_street_path` now refuses a
route that would *finish* jammed against the city wall, so fewer along-street routes are placed
and the per-route assertions run fewer times. That is a suite asserting the same things about a
smaller set, not a suite that stopped running. Before that it went 47062 → 47085 on M32, which is
the milestone where the whole point is
about *when* a cue fires, and almost none of that is assertable. What is assertable was made so
on purpose — the badge's two questions are **static functions** (`approach_speed`, `announces`)
so a test can ask them without a viewport, and the rest is a rig walked at a parked fire engine
and then a fire engine driven at a parked rig. Before that it went 31768 → 47062 on M21's own
tests, which loop over every street of every zone of every seed. A count that moves with what is
being asserted is doing that; a count that drops after anything but a deletion is a suite that
stopped running.

**M37 landed in this session and playtest 07 is down to three open findings**, none of them large.
The four it closed are the entry above; what is worth carrying forward is in "Gotchas learned in
M37" below, and the one to read first is the first: a category in an enum is a list waiting to
happen, which is M34's lesson arriving a second time from a direction that looked like art.

**M34, M33, M35 and M36 landed in the sessions before it**, and between them they are the rest of
playtests 07, 08 and 09.

**M32 closed playtest 06.** The five things it fixed are the entry further up; what is worth
carrying forward is in "Gotchas learned in M32" below.

**M21 landed in the session before it, and playtest 06 opened in the middle of it.**

**M21 made the calm big enough to walk in.** A calm **area** is now either one block or a
four-block **zone**, and every city has one or two zones. What that meant in practice was less
about parks than about the lattice: `block_plans`, `block_layouts` and `calm_blocks` are keyed by
the block that *anchors a lot*, so a zone is one entry with four blocks of ground and everything
counting calm areas counts it once; `CityMap.absent_segments` says which streets this city does
not have; and `CityMap.blocked_segments()` merges that with today's closures for every route
search in the game. **Measured against `main` over 24 seeds and four walks each, the density
playtest 06 had just approved is unchanged**: placed per day 40.1 → 40.1, live around her 4.87 →
4.79, on screen 2.74 → 2.75, met on a 40s walk 2.91 → 2.85.

**Five milestones landed in the session before it, all of them playtest 05's.**

**M28 put one event on every block.** Day 1 goes from 13 placed to **50 across 49 blocks**, from
1.8 live around her to ~11, and from about one on screen to **3.3**. The finding that matters
for next time: `budget_for()` was never the constraint. The day-1 pool's `max_per_day` values
summed to 18, so a budget of a hundred placed the same thirteen events — *"a budget the
catalogue cannot spend is not density"*, hit for real. Caps first, budget second, both measured.
Raising the caps took away the two jobs they were quietly doing, so both became rules:
`EVENT_SPACING_SAME`/`EVENT_SPACING_ANY` at placement, and **nothing else happens inside a
lethal event's field**.

**M29 made the traffic readable.** The city drove on the right east-west and on the left
north-south, because the convention was stated over the lane *offset* and the side that lands on
flips with the axis. And a car giving way now brakes toward a **stop line** instead of toward
zero speed, so it stops at the zebra rather than half a block short of it or on top of it.

**M30 made the mark over her head mean one thing:** *this will end your day*. Only a `hard_fail`
event and a closing car raise it. And the traffic finally carries its own cue — a car sounding
its horn draws the doubled lethal caret, because the caret was a private method on
`EventInstance` and "the entity carries its own cue" had silently meant "the *event* entity
does".

**M24 ended the same park twice.** The calm block she settled in is remembered and tomorrow puts
something loud in it; measured over a whole run, the repeat rate goes from **28% of days to
zero**.

**M31 gave act I teeth and six new things to look at.** Lethal events per day now run **0, 3, 4**
over days 1–3 — a **cyclist** from day 2 and a **reversing lorry** from day 3, both with the
doubled telegraph — so the escalation is a change of *kind* rather than of count. Plus
`loose_dog`, `market_stall`, `leaf_blower`, `pigeon_flock` and `ice_cream_van`, each with its own
silhouette. It also fixed the two things underneath *"dog walkers are not moving?"*: a
re-streamed event was **rewound to where the day put it at dawn**, and an `EventInstance` had no
gait at all.

**Two milestones before that, both playtest 04's.**

**M27 moved the world to where the player is.** The emphasised finding — *"don't load
everything upfront"* — reads as a performance note and is not one: the game was already at
120fps with 530 agents, and what it actually said is that every population number was being
divided by the 99.2% of the city nobody is looking at. The crowd is a **field** that travels
with her, events are **planned across the whole city at dawn and instantiated near her**, the
cat is the first `AHEAD_OF_PLAYER` event, and traffic keeps a headway. Day 1 is 11–13 events
of which 3–4 are live at any moment. [PLAYTEST-04.md](../playtests/PLAYTEST-04.md) has the measured table.

**M22 deleted the circles.** `EventAuraLayer` no longer exists and a test asserts it cannot
come back. What replaced it: a **caret over the entity** for danger that *changes over time*
and nothing else, breathing with current emission; a **badge at the screen edge** carrying the
thing's own silhouette for anything lethal or faster than a walk that is off-screen and
closing; the exclamation mark over the player generalised from traffic to events and given a
**second level** for danger already on her; and a **HUD line** for the `city_wide` sources that
had no on-screen presence at all. The vocabulary is in [EVENTS.md](../EVENTS.md), "The visual
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
- **M28 complete.** One event per block: 50 on day 1 across 49 blocks, ~11 live around her,
  3.3 on screen. The caps were the wall, not the budget. Left two new placement rules behind —
  spacing between events, and nothing inside a lethal event's field.
- **M29 complete.** The city drives on the right on **both** axes, and a car giving way brakes
  toward a stop line instead of toward zero speed.
- **M30 complete.** The mark over her head means *this will end your day* and nothing else, and
  a car sounding its horn carries the doubled lethal caret of its own.
- **M24 complete** *(playtest 05 asked for it by name)*. The park she settled in yesterday gets
  something loud in it today; the repeat rate goes from 28% of days to zero. It keeps its own
  record rather than reading the telemetry.
- **M31 complete.** Act I has two lethal things — a cyclist from day 2, a reversing lorry from
  day 3 — so lethal-per-day runs 0, 3, 4 over days 1–3 and the escalation is a change of kind.
  Plus five more act I rows for variety, each with its own silhouette. Fixed the streaming
  rewind and gave mobile events a gait.
- **M32 complete.** Playtest 06's five: the badge measures the thing's own approach (plus a
  window, a hold, a screen-edge margin and a sort by arrival); the mark over her head comes down
  at the kerb, via a source rather than a setter; a lost day is **retried** and the calendar only
  moves on a win; the pram carries the baby's four states; and the log has a `cue` entry, so the
  next cue defect is visible to a trace rather than only to a person.
- **M21 half complete.** Four-block calm zones: 22 tiles square, 10.8s corner to corner against
  a full meter's 23.8, one or two per city, never taking a stretch of the arterial and never
  beside other calm. The lattice grew holes and route redundancy stopped being true by
  construction. **The other two halves — main roads with lights, and the canal — are open by
  decision**, not forgotten; see `TODO.md`.
- **M33 complete.** Playtest 07's first nine: the falloff grew a shoulder, the crowd paid it back
  in radius, standing still settles nothing, a contact resolves and costs less, running started to
  matter, the run is taught on the day it does, and there is a pause.
- **M37 complete.** Playtest 07's finding 2 and three more, and one rule: **one picture per row,
  and no two rows share one.** `EventDef.Look`'s five categories were drawing sixteen of the
  twenty-eight visible rows; fourteen new silhouettes, a single icon table the screen-edge badge
  reads, and a test for both halves. Plus a café with people at it, a protest whose body followed
  its picture (11 → 55px, density unchanged), buildings that sort against nothing, and a baby cue
  that stops dodging a mark that is not there. Fifteen of playtest 07's nineteen are closed
- **M34 complete.** Playtest 07's next four, and one rule: anything that stands still is solid at
  half its silhouette. Two thirds of the catalogue has a body now where five rows did; a parked van
  is at the kerb rather than in a traffic lane; a reversing lorry has a building to reverse into;
  and a lethal event's body has to fit inside its own kill radius, which moved `alley_robbery`'s.
  Density unchanged, pavement-blocking obstacles up 41% on day 1.
