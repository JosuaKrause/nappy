# Nappy — TODO

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done

Each milestone is one git branch, merged to `main` when green.

**Where things stand:** M0–M16, M18, M19, M22, M23 and M27 are done and merged, and the game has
now been played four times by a human. The first playtest produced thirteen findings, planned
as M11–M17 in **[docs/PLAYTEST-01.md](PLAYTEST-01.md)**; the second produced twelve, planned as
M18–M26 in **[docs/PLAYTEST-02.md](PLAYTEST-02.md)**; the third, in
**[docs/PLAYTEST-03.md](PLAYTEST-03.md)**, is the first read off a run log and reorders some
of what the second one planned rather than adding milestones; the fourth, in
**[docs/PLAYTEST-04.md](PLAYTEST-04.md)**, adds one milestone and puts two that were already
queued at the front of the queue. All four are live plans and should be read before picking
anything up.

Execution order is numeric, with several exceptions already taken. **M18 was pulled ahead of
M16**, because closure counts tuned against a day that was about to halve would have been
tuned wrong. **M23 was pulled ahead of M17**, because it is the gate on M19's balance half and
on M24. **M27 was taken out of order and immediately**, because playtest 04's emphasised
finding — *"don't load everything upfront"* — turned out to be what was underneath three of the
other six, and because M21 and M22 both get judged against a street that now has traffic on it.

**Playtest 05 has landed and all six of its findings are done** — M28, M29, M30, M24 and M31.
Six findings in **[docs/PLAYTEST-05.md](PLAYTEST-05.md)**: two
traffic defects (cars stop at arbitrary points for a zebra; the two axes drive on opposite
sides of the road), M22's exclamation mark firing unattributably and without consequence, the
same park being usable on day 1 and day 2 (M24), **"day two doesn't feel more difficult than
day one… there is never *any* danger"** (M31), and a stated density target: **one event per
block** (M28) — day 1 now places ~49 events across 49 blocks and 3.3 are on screen at any
moment, and the thing it confirmed is that the binding constraint was the **per-type caps, not
the budget**. **Read it before picking up anything below**: the write-ups carry what each
analysis got right and what it got wrong, which is the half that is not in the diffs.

**M21's calm-zone half has landed.** One or two four-block calm zones per city, 22 tiles square,
with the streets between their blocks absorbed — so the lattice has holes in it, route
redundancy stopped being true by construction, and a stretch of calm is a route rather than a
lap. The other two halves of M21 (main roads with lights; the canal) are deliberately still
open; see the entry below.

**Playtest 06 has landed and all five of its things are done (M32).** In
**[docs/PLAYTEST-06.md](PLAYTEST-06.md)**, the first playtest ever taken on M28–M31: **the
difficulty is now right** — the first balance number in this game ever confirmed by a human —
plus two cues whose *condition was not the thing they claimed to mean*, a lost day that should be
**retried rather than skipped**, and the vocabulary asked for in the other direction: something
at the pram that says how the **baby** is. The one sentence to carry out of it is that M30
narrowed *which* things a cue is raised for and never looked at **when**: a cue is a claim about
a moment, and nothing in `tests/test_danger.gd` can see a moment.

**Playtest 07 has landed and M33 is its first half.** Nineteen things in
**[docs/PLAYTEST-07.md](PLAYTEST-07.md)**, reported as a running commentary rather than as a list,
and the one sentence under them is that **every cost in the game is paid on contact and almost
nothing else in it is real**. Nine are done; ten are queued behind them and listed there.

**Playtest 08 has landed and all five of its things are done (M35).** In
**[docs/PLAYTEST-08.md](PLAYTEST-08.md)**, taken on M34, and the run it came from ended on **day 3**
— the shortest any playtest has produced. Three of the five are one sentence, and it is playtest
07's own surviving a milestone meant to answer it: *a thing exists, and being near it changes
nothing.* The park spoiler denied three percent of a park, the pigeons were over before she arrived,
and the things that move stopped existing in front of her instead of going anywhere. The fourth is
the day-3 running lesson, which killed the run twice and whose fairness contract **passed every line
of itself while it was doing it** — because the contract was stated in speeds and durations and a
pursuit is played out in distances. The fifth is a number: five nerves.

**Playtest 09 has landed and all four of its things are done (M36).** In
**[docs/PLAYTEST-09.md](PLAYTEST-09.md)**, four sentences reported mid-session, and the one under
them is that **two things in the build had been doing nothing at all for milestones and both looked
finished from the outside**: `Esc` had never once opened the pause it shipped with in M33, and the
man shouting was killing day 1 by standing still. Plus two design instructions — a man who paces,
and a robber who is worth crossing the road for and comes after you if you do not. The lesson to
carry is about the *rig* rather than either bug: nothing in the suite or in a screenshot has ever
pressed a key, so neither could have caught the first one. `--press` exists now.

**Playtest 07 is down to four.** M37 closed findings 2, 11, 4 and 14 — one picture per row (and a
test that keeps it one), a café with people at it, buildings that sort against nothing, and a baby
cue that stops dodging a mark that is not there. What is left is the cat's axis (1), a four-block
concrete plaza (8) and a car turning with no diagonal (6).

**M38 is a batch of reports rather than a playtest**, and the sentence under all of them is the one
this project keeps rediscovering: *a thing that ships and looks finished is not a thing that works.*
The birds started their flying animation and then hung motionless in the air for the whole of the
event, three milestones after two separate playtests said they were ineffective; the cat's art faced
west while every other sprite in the game faces east, so the flip drew it running backwards; a car
turning into an occupied lane teleported the other one hundreds of pixels backwards while the queue
stayed legal on every frame; and a finished run had **no key on it at all** — the ending offered
`Esc`, `Esc` opened the pause, and the pause offered `Esc` and `Q`. Done: eleven birds that each fly
and each emit, a mirrored cat, a turn that looks before it commits, a title screen with the street
running behind it, `R` to start again, and calm ground 20% faster. See the entries under M38 below.

**M38 and M39 are both merged**, and the pursuit half of M39 is the second answer rather than the
first: the session's own analysis read finding 13 as a reaction-window problem, measured a real
two-tenths-of-a-second window, and built for it — while the player had been talking about the
break-off the whole time. *A probe that reproduces the numbers is not evidence that it reproduces
the complaint.* All of it was reverted and replaced with `Tuning.PURSUIT_SHAKEN_OFF`, which ends a
chase at a **rate**. Two things about the day-3 dog are still open and are written down in M43.

**Playtest 10 landed as M39.** Fourteen findings in
**[docs/PLAYTEST-10.md](PLAYTEST-10.md)**, off a session of five runs in which **no day was won**.
The sentence under them is that *the danger marks and the danger have come apart*: three of the
fourteen are one finding — a fire engine carries no caret and a burning building does — and the rule
underneath is M22's, which asks whether a danger *changes over time* and never asked how bad it is.
Under two more is the other one: **a retried day is not the same day**, which `docs/TODO.md` has
claimed since M32 and five seeds out of five disprove. And a thing nobody reported is in every
losing line of the trace — the crowd is supplying nearly all of the excitement that ends a day,
which is playtest 07's finding 17 arriving again after the milestone that answered it. That is
**the milestone after M39**, measured rather than argued.

**Playtest 11 has landed and is M41, M42 and M43.** Nine findings plus a design for the edge of
the map, in **[docs/PLAYTEST-11.md](PLAYTEST-11.md)**. The sentence under it: *several things in this
city are placed without asking what they are in the way of* — an event on the home block, a closure
beside a park, a busker in a courtyard she can walk round, a car turning into a junction another car
is already in. Underneath three more is a larger one: **the city has no hierarchy.** Every street is
the same street, the home sits wherever two competing generator rules leave it, and the map stops at
an invisible wall. That splits into a **spine and an edge you can walk off** (M41, which also closes
M21's open half), a **9×9 city with the home in the middle** (M42), and the rest (M43).

**M41 is done, and playtest 12 landed in the middle of it.** The city has a hierarchy now: one
main road running north to south, signalled at every junction and bad ground to recover on; two
retail precincts of three blocks each, one along the southern shore; ordinary streets everywhere
else; junctions that ration their own box; a lattice grown to 11×11; and a boundary with frontages
on the far side of it and a tunnel, a bridge and a road running out of the map. Nine findings in
**[docs/PLAYTEST-12.md](PLAYTEST-12.md)**, taken on the branch while it was half-built, and the
sentence under them is *a hierarchy is only a hierarchy if there is one of the top thing* — the
first build put a main road on each axis and a precinct in every corridor, which is three kinds of
street and no hierarchy among them.

**M41 is merged.** It landed at `c4e18d2` after the session that built it, and the suite is
122119 checks green on it.

**M43 is merged half done, on purpose, and it produced a milestone.** Three of its seven are built
(nothing on the home block, the diagonal `zzz`, a dog that does not reverse), two were **answered
by measuring rather than by building** — the busker's arithmetic is already right at every size of
calm area, and a closure cannot change a route in this city at all — and the closure half turned
into **M45**, on a design taken in that session: a closure's job is *direction, not distance*, and
the grid has to stop being a full grid before anything can point anywhere.

It is on `main` unfinished because **what is left of it cannot be done at a keyboard**: the pursuit
cool-off and dying at high excitement on a quiet street both need a *played run*, and holding five
green changes on a branch until somebody has time to play the game is how a branch goes stale. The
branch stays open for the two findings; the work that is done is on `main` where the next
screenshot and the next playtest will be taken against it.

**Playtest 13 has landed and it overrides that order.** Eight findings in
**[docs/PLAYTEST-13.md](PLAYTEST-13.md)**, off one run that ended on day 4 with a bad ending, and
the sentence under it is *the crowd is supplying almost all of the difficulty and every authored
system in the game is being judged through it* — reported this time by a person, in the plainest
possible words: **"just walking around now increases excitement — this is bad."** The trace has
her standing still for three seconds on an ordinary pavement outside her own front door and
gaining eight points, and a day lost in 29.4s reading `crowd 24.6, events 0.0`.

**So the crowd milestone exists, it is `M46`, and it is next.** The note below said to re-read the
traces before assuming it survived M41. The traces were re-read; it survived. It has now been
found by playtest 07, by playtest 10 and by a human sentence, and deferred three times.

**And the process finding is the one to read first.** The player opened by saying they could not
comment on much *"since you didn't actually finish your work"*, and closed with:
*"don't tell me to playtest again unless all the things we discussed have been implemented — there
is otherwise not really any point in playtesting since it will just surface the already mentioned
things again."* M43 was merged half done on the argument that what was left needed a played run.
This is what that bought: five nerves spent rediscovering things already written down.
**A playtest is a scarce resource. Do not spend one on a build known to be incomplete.**

**The order from here is: the tooling (findings 4 and 5), then M46, then M47, then the rest of
M43, then M48, then M40 — and only then a playtest.** The tooling goes first because M46 and M47
both want exactly the two things it provides: a picture of the grid, and a screenshot on demand
with a line in the trace beside it. M45 is absorbed into **M47**, because the permanent
restrictions it needs and the bigger calm areas playtest 13 asked for are the same mechanism —
`absent_segments`, and what a lot is.

**What that leaves.** M46, M47, M43's last two, M48, M40, a playtest, and then M25's other half —
patrols, which is unaffected by M31 and is now specifically the answer for **acts III and IV**,
where the streets are deliberately empty and the threat should follow rather than sit. *M25's
first half shipped in M33*: running that matters exists now, as a mechanic with a fairness contract
stated over `RUN_SPEED`, which is what that entry always said it would have to be.

**Playtest 04 set the order that stands now.** M27 and M22 are done. **M21 is next**
(four-block calm zones). M20 is **absorbed into M27**: cars follow and queue now, and what is
left of it — eight-way driving, overtaking, a crash as a catalogue event — is unasked-for and no
longer urgent. **M17, the route map, is backlogged by decision** — *"let's not do that for now,
we might revisit later"* — so it is no longer the thing behind M21.

**What M27 leaves open.** Nobody has played it. The densities in `docs/PLAYTEST-04.md` came off
a probe, and *"the arterial is for crossing"* is still a claim about a player rather than about
a rig. Read a run before touching a constant: `crowd` for contacts and horns, `near` for what
came within reach — which should now be a great deal more than playtest 03's zero — `road` for
time in the carriageway, `ahead` for what the director put in front of her, and `lost` for what
was around when a day ended.

**M50's steps 0, 1 and 2 are done and step 3 is what is left.** Step 0 — `RouteTree` grows the
day's corridor by the player's algorithm, and the telemetry map draws it, which is what turns *"is
anything guiding her"* from an impression formed while playing into a picture written every
morning. Step 1 — the city has permanent structure in it, four to eight dead ends and one or two
big buildings, placed against a reference tree. **Step 2 is placement by role**: a closure is a
**wall** placed off the corridor (the `CLOSURE_ROUTE_BIAS` inversion), a lethal event is a wall
too, a costly one is **friction** weighted onto the corridor, and a one-shot is a **set piece**
offered at every site of a covering set with exactly one of them happening. The tooling that draws
the roles on the map is done with them — colour is the role, shape is the effect, a white pip is
whether she reached it, and there is a **dusk** picture now, because that last one cannot mean
anything at dawn. **What is left is step 3, placeholders**, plus the resistance note's alley as a
set piece.

**Step 2 also gained an item after it shipped**, and it is a strengthening rather than a fix:
*"areas that outside the paths should have blocking events all over — we don't want the player to
step in those areas and it ranges from very costly to deadly."* What shipped biases walls onto the
**rim**; what is asked for is that the ground off the paths be **closed**, on a gradient. It
collides with M28's rule that nothing else happens inside a lethal event's field, and with how few
lethal rows the catalogue has — both named in the entry, neither resolved, plus the one question
that has to go back.

**And read step 3's own opening before touching it**, because the thing it is for was misread here
first: *"the role of budget is to provide variety in encounters and make sure to not spam the same
event over and over again"* — a variety ledger, not a density cap. The count of sites is the
density; the budget decides what fills them, and the point of resolving late is that **variety gets
measured over the encounters that happen rather than over a city she never saw.**

Read the M50 entry before picking any of it up: the things that went wrong there are worth more
than the things that went right, and two of them are the same shape — **a test that was true by
luck**. The retry guarantee broke and the suite stayed green because seed 4242 happened to
generate a different city; a crowd test asserted the wrong predicate for eleven milestones and
failed on a few frames of timing.

**Playtest 15 landed in the middle of it and is `M51`, and six of its seven are done** — the
cul-de-sac the crowd walked through, the spine's zebra, the police car's flank, the game-over
heading, the title colour and the car that vanished on the bridge. The seventh is half-open by
evidence rather than by neglect; see the entry.

**And the three corrections that came out of the player reading the first telemetry map are the
ones to read first**, because none of them was a bug report and all three were the session having
asked the wrong question. The picture drew bundles white and a precinct blue, where the ground was
already saying both; a big building closed four streets where what was wanted joins two blocks; and
the park rule *deleted* events off calm she had not used, where the answer was **"just don't place
events there"** — which keeps every unvisited area clean and raises the density, because a repair
spends the budget twice.

**Playtest 15 has landed, mid-M50, and it is `M51`.** Seven things in
**[docs/PLAYTEST-15.md](PLAYTEST-15.md)** plus a re-report that belongs to playtest 14's finding 7.
The sentence under it is *the city is drawing things it does not mean*: a cul-de-sac is a wall on
the graph and nothing on the pavement, the spine has a zebra painted under a traffic light —
two contradictory promises about who gives way, on the one street where getting it wrong ends the
day — a police car drives north showing its flank, and a car reaches the bridge and blinks out.
Two of the seven are about the frame rather than the game, and one is a report the player is not
sure about and is recorded as exactly that.

**Playtest 16 landed live and is `M53`, queued by the player *after* M52's traffic lights.** Three
findings and one complaint: **the crowd travels a lattice that is not the city** — onto a bridge
with no footway, off a bulkhead into the sea, through crossroads whose arms are grass, vanishing
each time where somebody is looking at it. Underneath two of the three is a missing rule: a
junction is drawn wherever two corridors cross, whether or not its arms are streets. None of it is
news to this file, and that is the part to read: M41 has carried the T-junction item unbuilt for
twelve milestones and M51 finding 1 was the same defect on a cul-de-sac. **A finding that arrives
twice from a player after being written down once by the project is a to-do that was filed and not
read.**

**So the running order is `M52` then `M53`**, on the player's instruction, and the third of M52's
three items is the one M53 waits on.

**And the next three are asked for and written down: `M52`.** *"2x2 courtyard and rectangular calm
zones, calm zone rate adjustments, traffic light placements."* Recorded in the player's own words,
with this side's reading kept separate from it and four questions that have to go back before any
of it is built — see the entry. Nothing is started.

M10 (polish) still stands but now sits *after* the playtest work — there is no point
polishing a loop that is about to be re-pitched.

`tools/test.sh` runs 202075 checks (~200s, and `tools/test.sh crowd balance` runs one suite in
seconds); `tools/check.sh` boots the project; `tools/run.sh` plays it; `tools/telemetry.sh` reads
back what the last run did.

---

## M0 — Project setup · `feature/project-setup`

- [x] Git repo, `.gitignore`
- [x] Design docs (DESIGN, MECHANICS, CITY, EVENTS, NARRATIVE, ARCHITECTURE)
- [x] `project.godot` with input map (arrows/WASD, shift, E, Esc)
- [x] Placeholder icon
- [x] `Tuning`, `EventBus`, `GameState` autoload stubs

## M1 — Movement & camera · `feature/core-movement`

- [x] `stroller.tscn` CharacterBody2D, walk/run, acceleration & friction
- [x] Procedural 2.5D drawing of mother + stroller, feet-anchored
- [x] Facing direction, stroller leads in the direction of travel
- [x] `Camera2D` follow with smoothing + movement look-ahead
- [x] Debug scene: 3x3 street grid matching the constants M3's generator will use
- [x] Y-sorting verified (player draws over a wall she is standing in front of)
- [x] `tools/shot.sh` — render a frame to PNG, since a headless boot never calls `_draw()`

### Deferred out of M1

- [ ] The pram has no collision of its own — only the mother's feet do, so the pram clips
      into walls when she hugs a corner. Options: a second body that trails her, or a
      capsule that rotates with `facing`. Not worth solving before the city exists.
- [x] Buildings taller than their lot depth would have no roof left to draw; `roof_depth()`
      clamps rather than warns. *(M12b: heights are whole tiles now, and the clamp is exact
      — the wall never takes the last row.)*

## M2 — Baby meters · `feature/baby-meters`

- [x] `baby.gd`: sleepiness + excitement, all rates from `Tuning`
- [x] Baby state machine AWAKE / ASLEEP / CRYING
- [x] Calm-threshold freeze rule
- [x] Running → excitement, idle → sleepiness drain
- [x] Wake-up rule + sleepiness penalty
- [x] `WorldContext` — the only three questions the baby may ask the world
- [x] `hud.tscn`: two meter bars with threshold markers, state + "not settling" hint,
      run header with nerves
- [x] Debug overlay: live incoming/decay/net breakdown
- [x] `tests/` harness + `tests/test_meters.gd` (57 checks)
- [ ] Day clock in the HUD — deferred to M6, which introduces the timer

### Deferred out of M2

- [ ] The HUD shows raw numbers. docs/TODO.md open questions asks whether a diegetic-only
      mode (baby face, no bars) should ship alongside. Revisit after M6 playtesting.

## M3 — City generation · `feature/city-generation`

- [x] `tile.gd` TileType metadata (walkable / calm / alley / road / colour)
- [x] `city_map.gd`: tile grid, layout maths, BFS distances
- [x] `city_generator.gd`: street grid, districts, alleys, plazas, parks, home
- [x] Carving as rect subtraction, so holes compose without special cases
- [x] Connectivity flood-fill + retry on failure
- [x] Generation guarantees (park count, spread, home distance, exact building coverage)
- [x] `city.gd`: procedural 2.5D buildings, ground, kerbs, crossings, park props
- [x] Building collision bodies + a boundary wall around the map
- [x] Calm zone + alley effects wired through `WorldContext` into `baby.gd`
- [x] `tests/test_generator.gd` over 200 seeds, plus a route-redundancy sweep
- [x] Dev flags: `--seed`, `--overview`, `--spawn park|alley|square|playground`

### Deferred out of M3

- [ ] Park trees are placed by rejection sampling and clump. Poisson-disc or a simple
      minimum-spacing check would spread them without much work.
- [ ] Districts affect building height and alley chance but nothing else yet. `INDUSTRIAL`
      and `CIVIC` should read differently at a glance before Act II makes them narrative.
- [ ] The generator is deterministic per seed but `generate()` retries with `seed + 1`,
      so a run's city is not strictly `run_seed` — it is the first nearby seed that passes.
      Fine, but worth remembering when reproducing a bug from a seed.

## M4 — Event system · `feature/event-system`

- [x] `event_def.gd` + `event_catalogue.gd` (defined in code, not `.tres`)
- [x] `event_instance.gd`: lifetime, telegraph phase, pulse envelope, path following,
      falloff contribution, hard-fail gating
- [x] `event_manager.gd`: live instances, retirement, `total_excitement_at`
- [x] `Tuning.validate_event()` asserted over the whole catalogue in a test
- [x] Telegraph visuals: `event_aura_layer.gd` under the entities, amber-and-flashing while
      telegraphing, red once active, tracking the pulse so the field breathes
- [x] `event_scheduler.gd`: budget, weights, one-shot spreading and consumption, determinism
- [x] "Always one usable calm zone" rule
- [x] `tests/test_events.gd` (149 checks)
- [x] Dev flags: `--day N`, `--spawn event`; `tools/shot.sh` now waits in seconds
- [~] Three representative events only (ambient / mobile burst / stationary pulse).
      M5 fills in the rest of Act I.
- [ ] Audio cues — no audio in the project yet; lands in M10

### Decisions taken during M4

- **No spatial hash.** The budget topped out near 22 concurrent events; a linear scan is
  free and a hash would be more code with more ways to be wrong. *(M19's density pass took
  that to ~25, and the decision is unchanged — the crowd has been doing 530 linear distance
  checks a frame since M13 and is not the bottleneck either.)*
- **No `impulse` field.** A sharp spike is a short `duration` at high `intensity`, which
  keeps the whole excitement model a pure query with nothing pushed at the baby.
- **Ambient events are exempt from the telegraph contract.** They never "appear", so there
  is nothing to warn about; the player learns them on day 1 of a fixed city.

## M5 — Act I events · `feature/events-act1`

- [x] `playground` (ambient), `busy_road` (ambient, sampled along two arterials)
- [x] `cat_dash` — the tutorial obstacle
- [x] `dog_walker` (mobile, slower than walking), `delivery_van`
- [x] `homeless_yeller` with pulsing intensity envelope
- [x] `busker`, `construction` (emits **and** physically blocks)
- [x] `fire_truck` one-shot: mobile siren that leaves a `burning_building` behind it
- [x] Supporting features: `PathMode` (cross-street / along-street), `obstructs_radius`,
      `spawns_on_finish`, `AmbientSource.MAIN_ROAD`, fire rendering
- [x] Fairness contract strengthened: an event faster than walking must be clearable
      across its **whole** radius, not just its falloff band
- [x] `tests/test_event_manager.gd` — integration against a real generated city
- [x] Dev flag: `--follow <event id>`, `--spawn event:<id>`

### Deferred out of M5

- [ ] The `burning_building` spawns exactly where the engine stopped, which is in the road
      rather than in a building. Nudging it to the nearest `BUILDING` tile would read much
      better and is a few lines.
- [x] `busy_road` is 14 separate instances. Fine for a linear scan, but a single
      polyline-shaped source would be tidier and cheaper. *(M13: retired entirely — the
      crowd is the arterial noise now.)*
- [ ] No audio, so every "you hear it coming" telegraph is currently visual only (M10).

## M6 — Day loop · `feature/day-loop`

- [x] Home tile: start, and return-with-sleeping-baby goal
- [x] Return phase after sleepiness hits 100, and reverting to walking if she is woken
- [x] Day timer, HUD clock, and dusk as a `CanvasModulate` over the city canvas
- [x] Win, cry-loss, timeout-loss, hard-fail-loss — each with its own text
- [x] Nerves, run end at 0, ending selection
- [x] `day_summary.tscn` between days, and the ending screen
- [x] Run state persists across days in memory; the city is built once and reused
- [x] `tests/test_day_loop.gd` (35 checks) — phases, all four outcomes, nerves, endings
- [x] Dev flag: `--day-length N`
- [ ] Save/continue a run to disk — M10

### Notes

- The tree is **paused** while the summary is up, so a day restart is just
  `events.start_day()` + reposition + `baby.reset()`; the city is never rebuilt.
- A day ends exactly once. `_end()` is a no-op after the first call, so a cry arriving on
  the same frame as dusk cannot spend two nerves — there is a test for it.
- The summary is reached from the timeout path in dev by `--day-length 10`. Winning needs
  the player to actually walk, so it is covered by tests rather than by a screenshot.

## M7 — Acts II–IV · `feature/acts`

- [x] Per-act colour cast, multiplied into the daylight
- [x] Act II: `police_patrol`, `poster_crew`, `loudspeaker`, `curfew_announce`, `checkpoint`
- [x] Act III: `quiet_road`, `abduction` (hard fail), `alley_robbery` (hard fail), `night_raid`
- [x] Act IV: `military_convoy` (leaves a barricade), `barricade`, `protest`, `firefight`
- [x] Persistent world scars — `scar_id` + `GameState.scars`; the burnt-out shell from
      day 3 is on the same corner on day 12
- [x] Street closures as obstructing events, revalidated so a park stays reachable
- [x] New mechanics: `city_wide` (no falloff), `intensity_ramp` (a protest swells),
      `scar_id`
- [x] `tests/test_acts.gd` — act gating, city-wide
      sources, protest growth, scar persistence, walkability under closures
- [ ] Per-act ambient audio bed — no audio in the project yet (M10)

### Notes

- ~~`busy_road` has `last_day = 7` and `quiet_road` `first_day = 8`~~ — both retired in
  M13. The handover they encoded is now `Tuning.CROWD_*_PER_ACT`, and the thing that would
  have silently doubled the noise on the main roads was keeping them *alongside* the crowd.
- `alley_robbery` is not exempt from the fairness contract — its radius is small enough
  (22/42px) that half a second satisfies it. The honest framing is that the alley is the
  warning.
- Passing an untyped `Array` into a parameter typed `Array[T]` leaks the arguments at
  shutdown ("N ObjectDB instances were leaked"). `tests/test_acts.gd` carries a note.

## M8 — Resistance subquest · `feature/resistance`

- [x] Chalk marks, drawn under everything that stands on them. No marker, no quest log.
- [x] Hold-to-interact with decay when you let go or walk away
- [x] All 6 steps, as a data table
- [x] Robbery-vs-contact alley roulette, seeded from run seed + day
- [x] Seen-by-patrol resets the hold *(changed from the planned progress penalty — see
      docs/NARRATIVE.md for why)*
- [x] Timed step failure (contact lost permanently for the run)
- [x] Resistance tally in the day summary; one terse HUD line otherwise
- [x] The good ending needs the goal **and** the day-14 sabotage
- [x] `tests/test_resistance.gd` (66 checks)
- [x] Dev flag: `--spawn contact`

### Notes

- `GameState.day_rng()` takes a `stream` now. Without it the events and the resistance
  would both start from the same day seed and their first rolls would move together.
- Building the step table with `set(key, value)` from a Dictionary silently DROPPED every
  `Array[int]` placement list — `set()` does not report a type mismatch — so three of the
  six steps had nowhere to go, with no error anywhere. It is an explicit factory now.

## M9 — Endings · `feature/endings`

- [x] Bad ending (nerves 0)
- [x] Neutral ending (day 14, sabotage not done)
- [x] Good ending (goal reached **and** day-14 sabotage completed)
- [x] Epilogue screens
- [x] The good ending's mechanical reward: **silence**. Completing the day-14 sabotage
      retires every city-wide source, so the last walk home is made without the floor the
      masts have held under the meter since day 5 — the easiest conditions in the game,
      and the only moment the HUD says anything out loud.

## M11–M17 — Playtest 01

See **[docs/PLAYTEST-01.md](PLAYTEST-01.md)** for the findings, the analysis and the
sequencing. Summary only here:

- [x] **M11 Playtest fixes** — home arrow, three graphics glitches, day-start position,
      spoiler-free README
- [x] **M12 Asset pipeline** — real asset files and tiles instead of `_draw()`. Gates M13,
      M15, M16, M17, so it goes first
  - [x] **M12a** ground: `assets/tiles/*.svg` + a `TileSet` + a `TileMapLayer`
  - [x] **M12b** buildings: `assets/buildings/*.svg`, assembled per lot; heights quantised
        to whole tiles
  - [x] **M12c** the rig, props and events: `assets/rig/`, `assets/props/`,
        `assets/events/`, plus `Sprites` for the feet-anchored draw rule
- [x] **M13 Density and life** — pedestrians and traffic as real agents; the crowd becomes
      the noise floor. `busy_road` / `quiet_road` retired: the arterial is loud because
      there are cars on it, and act III's empty city is empty pavement rather than a
      smaller number
- [x] **M14 Balance** — a day cannot be won without reaching calm ground. Street gain
      0.24/s (79 of 100 over a whole day), calm 3.5x, idle drain 0.6/s. Asserted against
      `day_length()` in `tests/test_meters.gd` and against a real city in
      `tests/test_balance.gd`
- [x] **M15 Block purposes** — four calm purposes (park, forest, quiet square, courtyard),
      three degraded ones (requisitioned, boarded up, burnt out), per-block arcs planned at
      generation, and the run-scoped `CityState`. Supersedes the "CityMap is immutable"
      invariant with "the lattice is fixed; what a block *is* is not", and keeps the half
      that is absolute: no purpose change moves a walkable tile
- [x] **M16 Route pressure** — a per-day pruned network with legible blockers, leaving at
      least two distinct routes to at least two distinct calm areas. Five kinds of closure,
      sealed at both mouths so a shut street is readable from the junction; the invariant
      checked by unit-capacity max flow on the junction graph before each closure is
      accepted. Canal dropped to M21. *(The invariant was weakened on 2026-08-31 to two calm
      areas still **reachable** — the two-routes half was never a hard rule. The max flow and
      the check-before-accepting are unchanged; see M50 and `docs/CITY.md`, "The invariant".)*
- [~] **M17 Route map** — the planning screen, rendering M15's block states. **Backlogged, by
      decision, at the end of the M29 session**: *"in case you have it still in your notes about
      showing a brief map at the start let's not do that for now — we might revisit later but
      for now let's put it in the backlog."* Nothing about the analysis below is withdrawn and
      the gap it closes is real — a player two junctions away still cannot know a street is
      shut, and `docs/CITY.md` states that as a gap rather than papering over it. It is simply
      not what the game needs next. M21 and the playtest-05 findings come first

## M18–M26 — Playtest 02

See **[docs/PLAYTEST-02.md](PLAYTEST-02.md)** for the findings and the reasoning. Six
findings from the second human playtest, queued behind M16 and M17. Summary only here:

- [x] **M18 The park has to be worth it** — finding 1. Calm ground fills the meter in 24s
      instead of 119s (10x the street, not 3.5x), and the day itself is 180s instead of 330s
      — aimed at a minute of play with a grace of three. Pulled ahead of M16, because
      closures tuned against a day that was about to halve would have been tuned wrong
- [x] **M19 Bodies on the street** — findings 2 and 3, **plus playtest 03 finding 1**.
      Pedestrians and the player collide and displace each other; a car strike is a hard fail
      with its own stated fairness contract (`Tuning.validate_traffic`); traffic gives way at a
      zebra somebody is waiting at; `cafe_tables` blocks a pavement from day 1 and `dog_walker`
      was re-pitched from −0.1 points to +21.6, so it owns the pavement instead of rewarding a
      player for ploughing into it. The collision bump is a short-lived *source on the person
      she walked into*, never a write to `Baby.excitement`.
      **Carried the event-density pass**: day 1 goes from 4 non-ambient events across
      forty-nine blocks to 13, day 14 from 22 to 25, with the number **measured** from what a
      day places rather than derived from the budget — a third of the budget is spent on events
      the day then throws away. See docs/MECHANICS.md, "The street has physics".
      **Two things were pulled in and one was left out**, all three deliberately:
      the exclamation mark over the player came forward from M22, because a lethal car has no
      telegraph phase to ring and it is the cue that makes the contract an instruction; the
      cost table in docs/EVENTS.md was regenerated and is now asserted by a test; and the
      *balance* half is still open, because setting it needs a human playing, which is what
      decision 11 says and what M23 exists for
- [~] **M20 Traffic that behaves** — finding 4. Cars follow, slow and overtake instead of
      driving through each other; 8-direction driving so they can turn; an overtake into
      oncoming traffic crashes, and the crash is a catalogue event with a real telegraph.
      **The half that mattered shipped in M27**: playtest 04 said *"cars still bump into each
      other"* and it is now measurably false — a minute of act I traffic has zero frames with
      one car inside another, down from 5.2 overlapping pairs per frame. What remains is
      overtaking, eight-way driving and the crash event — **asked for by name in this very
      finding**, and **parked with the player's agreement** on 2026-08-31: *"yes, I asked for cars
      overtaking each other and car crashes — not something we need to implement right now but
      something to discuss at a later time."* So it is parked as a **conversation that is owed**,
      not as a thing nobody wanted. The status line said *"none of which any playtest has asked
      for"* for twenty-odd milestones, which is how a parked request becomes an abandoned one
- [~] **M21 The city overhaul** — findings 5 and 6, plus the canal dropped out of M16, **plus
      playtest 03 finding 2**. Calm zones of four blocks, so the lattice grows T-junctions and
      can no longer be derived from a coordinate; main roads with traffic lights against side
      roads with zebras, where a main road is crossed rather than walked.
      **Raised above M20**: the four-block calm zone is the structural answer to twenty seconds
      of walking in a circle. That circling is not a length problem — progress requires motion
      and a calm block is a few tiles across, which is jointly sufficient for a lap, which is
      why M18's shorter stretch did not remove it and no further balance pass will.
      **The calm-zone half is done**: one or two 2×2 zones per city, 22 tiles square,
      crossed corner to corner in 10.8s against a full meter's 23.8 — so a stretch of calm is two
      or three traverses of somewhere with sides to it rather than six laps of a lawn. The
      lattice has holes in it, four T-junctions round each zone and a junction in the middle that
      nothing reaches, and **route redundancy stopped being true by construction** and is checked
      by search. Measured against `main` over 24 seeds and four walks each: placed per day 40.1
      → 40.1, live around her 4.87 → 4.79, on screen 2.74 → 2.75, met on a 40s walk 2.91 → 2.85,
      so playtest 06's *"I like the difficulty now"* survives it.
      **Two halves are not done and are deliberately left**: *main roads with lights against side
      roads with zebras* (finding 6), which decision 3 has largely been answered another way —
      *"a main road is crossed, not walked"* is enforced by M19's lethal carriageway and M27's
      density, and walking the arterial's length loses day 1 in fourteen seconds — and the
      **canal**, which is still the one feature that would move a walkable tile. Neither is
      blocking anything; both want a playtest of the zones first
- [x] **M22 Danger you can read** — findings 7 and 8. **Delete the aura circles.** How
      dangerous a thing is becomes visible from the thing itself; the rest is a small symbol
      vocabulary — above an entity when it needs one, at the screen edge when it is
      off-screen and closing, and above the *player*: **a flashing exclamation mark when they
      are standing in a soon-to-be danger zone** ("this spot is about to be bad, move"), plus
      a "too close" cue for danger already on them. The exclamation mark is the cue that
      turns the telegraph contract from information into instruction. Absorbs the "screen-edge indicator for fast movers" item from M10
      below. **The exclamation mark shipped early, in M19**, for the reason this entry gave:
      a lethal car arriving from off-screen is a breach of the telegraph fairness contract, not
      a polish item, and it has no telegraph phase to ring.
      **Done, after playtest 04 asked for it a second time** (*"I still see circles"*). The
      rings are deleted; `EventAuraLayer` no longer exists and a test asserts it cannot come
      back. What replaced it: a **caret over the entity**, shown for danger that *changes over
      time* and nothing else — lethal, telegraphing, pulsing, swelling — because a cue that
      marks a notice board as hard as an abduction is what the rings were; a **badge at the
      screen edge** carrying the thing's own silhouette, for anything lethal or faster than a
      walk that is off-screen and closing, which closes the `fire_truck` gap the ring could
      never cover; the exclamation mark over the player generalised to events and given its
      **second level** for danger already on her; and a **HUD line** for `city_wide` sources,
      which had no on-screen presence at all and were the most misleading thing in the game.
      The one thing the ring did well survives: the caret *breathes* with current emission, so
      a pulsing event is still something to time a pass through
- [x] **M23 Telemetry** — finding 10. A chronological plain-text log per run, in
      `user://telemetry/` and readable with `./tools/telemetry.sh`. Records what the code
      cannot recompute — the random outcomes that branch a run, the seed the generator
      actually settled on, the commit it ran on, what the player did, what came near them,
      and how each day ended. Full format and the entry table in
      [docs/TELEMETRY.md](TELEMETRY.md). **The gate is now open**: M19's balance half and M24
      both have their data source. On by default; `--no-telemetry` turns it off
- [x] **M24 The city remembers where you went** — finding 11, and playtest 05 asked for it
      again by name. Done: see the M28+ section below
- [ ] **M25 Patrols, and running that matters** — findings 9 and 12, **plus playtest 03
      finding 3**: the walk home is a formality — 26s, five crossings, zero encounters, 42% of
      the day left over. Patrols that were not there on the way out are the shape of the
      return phase's own pressure, which is why it is filed here rather than as a milestone.
      Patrols to put pressure
      back into the streets acts III and IV deliberately emptied, built around **encounter
      cost** rather than ambient emission. The prerequisite is structural: running is
      currently the wrong move against *every* event in the catalogue, so a patrol needs a
      mechanic running escapes (something that pursues, a lethal radius that grows, a window
      that shuts) and a fairness contract stated over `RUN_SPEED` rather than `WALK_SPEED`
- [ ] **M26 Teaching the controls, and one less control to teach** — two halves.
      **Delete the interact key:** `E` appears in exactly one line of the game
      (`contact_point.gd`), so the resistance hold becomes automatic on proximity. Nothing is
      lost — the cost was always standing still in an alley while a patrol might pass, not
      the keypress — and a player who wanders down an alley now discovers the difficulty dial
      by walking near it. **Teach the two that remain:** arrows/WASD at the start of day 1,
      then shift, then a scripted day-1-only event that requires a short run after the first
      block. **Comes after M25, for correctness not scheduling**: forcing a run before running
      is ever the right answer teaches a move that is never correct again

## M27 — Playtest 04

See **[docs/PLAYTEST-04.md](PLAYTEST-04.md)** for the seven findings, the measurements and the
reasoning. Two of the seven were milestones already queued (M22, M21) and are unchanged; one
was the summary of the rest. The other four are one milestone:

- [x] **M27 The world near you** — findings 1, 4, 5 and 6, and the emphasised one is finding 5:
      *"don't load everything upfront — only load / spawn things in the surrounding few blocks
      of the player when needed; consistency is not that important, nobody can run after cars
      anyway to confirm they are still there off screen."* It reads as a performance note and
      is not one — the game was already at 120fps with 530 agents. It is that **the population
      was being spent on the 99.2% of the city nobody is looking at**, which is why 110 cars
      read as a street you could ignore.
  - [x] **The crowd is a field.** A `CROWD_FIELD_RADIUS` box that travels with the player;
        agents recycle into a band outside the edge they will come back in through, and the
        `Tuning` populations became populations of the field. Measured, not converted: the
        table in PLAYTEST-04 is the record, and the two numbers that decide it are how often
        there is a gap to cross the arterial (one time in twenty, at act I) and the ratio
        between walking a lane centre and holding the midline (eleven contacts against one)
  - [x] **Events stream.** The day is still planned across the whole city — every guarantee is
        a property of the plan — and a plan becomes a node when the player is within
        `EVENT_STREAM_RADIUS`. Picks up playtest 03's finding 1 from the other side: a
        twenty-second event planted across the city at dawn is over before anybody could reach
        it, and that day's trace had **zero** `near` entries. An event that waits is an event
        she meets
  - [x] **The cat happens to you.** `EventDef.SpawnMode.AHEAD_OF_PLAYER` and `EventDirector`:
        the day budgets it at the usual cost and the director sites it across her line while
        she walks. Also fixed the six-milestone-old bug underneath the complaint — a mobile
        event starts moving when its telegraph does, so the cat finished its whole crossing
        *during* the crouch and the running sprite had never drawn
  - [x] **Traffic queues.** `CAR_HEADWAY_TIME` and `CAR_GAP_MIN`, and the separation is
        positional rather than a brake, because a brake cannot open a gap that does not exist.
        Takes the useful half of M20 with it
  - [ ] **Nobody has played it.** The whole thing is measured off a probe

## M28+ — Playtest 05

See **[docs/PLAYTEST-05.md](PLAYTEST-05.md)** for the six findings. One is done:

- [x] **M28 One event per block** — finding 6, taken first because the handoff named it and
      because it is a number rather than an argument: *"I want one event per block. The dog
      walker decision should happen meaningfully — I want to have to make that decision at least
      twice on day one. Also the same with a restaurant — I never saw one."* Day 1 goes from 13
      placed to **50 across 49 blocks**, from 1.8 live around her to ~11, and from ~1 on screen
      to **3.3**. **The caps moved first and the budget followed**: the day-1 pool's `max_per_day`
      values summed to 18, so no budget alone could ever have reached 49 — three dog walkers
      became twenty and three cafés eighteen. Repeats being fine meant no new catalogue rows.
      Two rules had to be invented to replace what the caps were quietly doing: a **spacing rule**
      at placement (`EVENT_SPACING_SAME` between two of a kind, `EVENT_SPACING_ANY` between any
      two), and **nothing else happens inside a lethal event's field**, which is playtest 05's
      "the contract composes badly when fields overlap" turned into something enforceable.
      It also caught a test that had been asserting more than the design promised since M15
- [x] **M29 Which side of the road** — findings 1 and 2, taken together because they are both
      `src/crowd/` and neither touches the meter. **Finding 2 was exactly as derived**: the
      driving convention was stated over the lane *offset*, and the side of the road that lands
      on flips with the axis, so the city drove on the right east-west and on the left
      north-south. `road_direction()` takes the axis now and has an inverse, `road_lane()`, and
      the test nobody had written asserts the real rule — for both axes and both directions,
      the lane a car is in is the one on its own right, checked against every live car in a real
      day. **Finding 1** is a car giving way *at a place*: it brakes toward a stop line a
      setback before the paint, on a gentle approach rate that keeps the easing visible from the
      kerb, and commits to clearing the crossing if it is already too close to stop. Two bugs
      turned up on the way that no analysis predicted — shaping the approach with `CAR_BRAKE`
      makes the onset of braking and the commit point the same instant so no car ever stops, and
      the crossing scan sampled world points every 32px, which aliases exactly when a car is
      stopped at the line, so it lost sight of the zebra and pulled away with somebody on it.
      Also fixed a rig bug that had been silently spoiling the give-way test since M27: the
      crowd is a field around the player and the rig has no player, so two of the three cars it
      measured were recycled on the first frame
- [x] **M30 The mark means one thing** — finding 3, settled the way the write-up said it had to
      be settled: as a **design decision**, not a threshold. The mark means *this will end your
      day*, so only a `hard_fail` event and a closing car raise it; everything else is left to
      the meter, which already says it continuously and proportionally. And the traffic carries
      its own cue at last — a car sounding its horn draws the same doubled lethal caret a
      `hard_fail` event does, breathing with the horn's decay, because the vocabulary's first
      row is *the entity itself carries most of it* and a car was carrying nothing. The accepted
      cost is stated rather than hidden: acts I and II have nothing lethal in them, so the mark
      is nearly silent before day 8 — which is the cue being honest about finding 5 rather than
      covering for it. The thing nobody had noticed: the caret was a **private method on
      `EventInstance`**, so "the entity carries its own cue" silently meant "the *event* entity
      does", and the one lethal thing outside the catalogue fell off that edge
- [x] **M24 The city remembers where you went** — finding 4, and playtest 02's finding 11. The
      calm block the baby actually fell asleep in is remembered and the next day plans one loud
      thing into it; the usable-park rule is told to protect a different one, or the two halves
      fight and it strips the very event that was the point. Measured over five seeds and a whole
      run: the chance the quietest calm block today is yesterday's goes from **28% of days to
      zero**. Kept from being a punishment for playing well by three things — it spoils with an
      avoidable, visible event rather than removing the ground, nothing lethal, obstructing or
      mobile is ever chosen for it, and it is one ordinary event from the same day's pool.
      **It does not read the telemetry**, which is what the write-up assumed it would: a rule
      that reads a trace would make the game play differently with `--no-telemetry`
- [x] **M31 Act I has teeth, and more to look at** — finding 5, the emphasised one, plus the
      request that came with it: *"try to come up with more variety, we need more
      events/entities in general."* Seven new rows, five of them on day 1, each with its own
      silhouette rather than another `person.svg`. **The shape was chosen against the obvious
      one**: a patrol was ruled out by the player — *"patrol shouldn't be there for act I"* —
      so the danger is the neighbourhood's own, a **cyclist** from day 2 and a **reversing
      lorry** from day 3, both `hard_fail` with the doubled telegraph the contract demands and
      teaching opposite lessons (one comes at you, one is static with the danger behind it).
      Lethal events per day now run **0, 3, 4** over days 1–3, so the escalation is a change of
      *kind* rather than of count and a person can feel it on day 2.
      Two bugs came out of it that no test could see: a re-streamed event was rebuilt from the
      tile the day chose at dawn, so a **dog walker teleported back to the top of its street**
      every time the player left its radius and returned; and an `EventInstance` had no gait at
      all, so a thing moving at 32px/s read as parked. Both were reported as *"dog walkers are
      not moving?"* and neither was the movement

## M32 — Playtest 06: the cues mean now

See **[docs/PLAYTEST-06.md](PLAYTEST-06.md)**. The first playtest taken on M28–M31, reported
part-way through M21 with the instruction to *"take note of those but continue implementing the
next item on the handoff first"*. **All five are done.** Three were small fixes in code M22, M30
and M6 already owned; one added a row to the vocabulary; and the four of them together are one
sentence — *a cue is a claim about a moment*, which is the axis M30 had not looked along.

- [x] **The difficulty is right.** *"I like the difficulty now — it actually became harder."*
      Not a task; recorded because it is the **first balance number in this game ever confirmed
      by a human**, and `CLAUDE.md`'s "no balance number has been felt by a human" has been true
      since M14
- [x] **The screen-edge badge measures the wrong speed** — *"they show events far away, and if
      you walk towards them they sometimes disappear; also they flicker a lot."* Two of the three
      symptoms were one defect: `DangerEdge` tested the *relative* closing rate against a 20px/s
      threshold and she walks at 92, so **walking towards anything lethal raised its badge**. It
      measures the event's own approach with the player held still now; the range cap is a
      *window* (`LEAD_TIME` seconds of its own approach, so the same 800px is a fire engine and
      not a dawdler); a raised badge is held; and the list is sorted by **arrival** rather than
      by distance, which is what `MOST_AT_ONCE` should be choosing between.
      **The flicker had a second cause the analysis did not predict**: a thing on the screen
      boundary trades places with its own badge every frame, which needed hysteresis on the
      *edge* — a margin outside the view before one may be raised — and no amount of it on the
      closing rate would have helped. Also caught by a trace: the director's `AHEAD_OF_PLAYER`
      events were eligible, so a cat whose entire content is that it is *not* announced was
      raising and dropping a badge inside a tenth of a second
- [x] **The exclamation mark outlives the car** — *"I get the flashing exclamation marks after
      the fact, at which point they're not useful."* `CAR_WARNING_HOLD` is 1.4s and nothing
      lowered the mark when she stepped off the carriageway, where a car cannot reach her at all.
      The hold has a real job — surviving the gap between two cars in one lane — so it is a
      second condition rather than a shorter hold: `Stroller.warn()` takes a **source** and
      `stand_down()` lets that source, and only that source, lower its own mark. A trace of a
      minute of day 3 now shows every span at 0.3–0.7s and **all of it on the road**
- [x] **A lost day is retried, not skipped** — finding 4, and it closes an open design question
      carried since M6. `GameState.finish_day()` no longer advances the calendar on a loss, the
      summary says *"You try day 3 again"*, and the attempt's `settled_in` record is forgotten
      with it — otherwise M24 would spoil a park the winning attempt never went to, and the
      record is written once a day. The run can no longer end by running out of days while
      nerves remain
- [x] **The meters are in the corner and the game is played at the pram** — finding 5, and the
      only one that adds to the vocabulary rather than fixing something in it. Four states over
      the pram — asleep, stirring, not settling, nearly crying — as *states with an instruction*
      rather than a gauge, in the vocabulary's own colours and its own motifs, anchored to the
      pram and stepped aside when the pram is on her own axis so it can never share a column
      with the exclamation mark. `Baby.Cue`, `Stroller._draw_baby_cue()`, three new sprites
- [x] **And the log can see a cue at last.** Not a finding: the gap playtest 05 named and
      playtest 06 walked straight into. Both cue defects were invisible to a trace, because
      every entry said what the *world* did and none said what the game **told her about it**.
      A `cue` entry per span, written when the span ends so the duration is on the line

## M33 — Playtest 07: the cost model was inverted, and running started to matter

See **[docs/PLAYTEST-07.md](PLAYTEST-07.md)** for all nineteen findings, the traces that confirm
three of them, and the ten that are still open. Nine are done.

- [x] **The falloff has a shoulder** — finding 18, and the one change that answers it for the whole
      catalogue at once. `(1−t)²` → `1−t²`, so a field holds three quarters of its intensity at the
      midpoint of its band instead of a quarter. No radius moved, so the telegraph fairness
      contract — which is stated over *distance* — is untouched. The trace said it in as many
      words: every `near` entry written at an event's own outer radius read `events 0.0`
- [x] **The crowd paid the shape back in radius** — the same change put the arterial floor at
      18.4/s against a 3.5 walking decay, which is a main road that fills the meter in six seconds.
      A pedestrian's outer radius came in 88 → 55 and a car's 170 → 104, which restores the floor
      to within 3% while leaving the close pass at 4.2/s. What is defended is M27's character:
      **careless is expensive and careful is free**
- [x] **Standing still settles nothing** — finding 3. `EXCITEMENT_DECAY_IDLE` was 6.0, the
      *fastest* of the three rates, so a full meter cleared in seventeen seconds anywhere. The
      ordering is motion-shaped now: walking 3.5, running 0.5, standing 0.0. And there is an
      `idle` telemetry span, because the player asked whether it was captured and it was not —
      standing still emits no entry of any kind, so the strongest move in the game showed up in a
      trace as a seventy-four-second **gap between two lines**
- [x] **A contact resolves** — finding 5. Two defects, either enough on its own: the separation
      resolved to exactly `BUMP_RADIUS`, which is the radius that *releases* the contact, so a
      resolved pair sat on its own threshold; and a walker steers back to its lane centre, which is
      where she is standing. Hysteresis band plus a sidestep. The longest single contact goes from
      1.0s to **0.1s**, backed against a wall included
- [x] **People get out of the way** — finding 17. M19 and M27 measured eleven contacts down a lane
      centre against one on the midline and built the crowd on that ratio; a probe re-run on `main`
      says it is gone — thirteen against fifteen — and it cannot be tuned back, because a midline
      is 16px from two lane centres and `BUMP_RADIUS` is 14. That line was two pixels wide when
      M19 measured it. So the careful line is a **behaviour**: somebody who sees a pram coming
      steps aside, hurries across, or waits. Same-axis contacts go from eleven to nought-to-four.
      A bump also costs 18 rather than 26, because the authored content now carries the share the
      crowd was carrying alone
- [x] **Running is the answer to exactly one kind of thing** — and it is two decisions, not one.
      The shoulder broke the old one by accident: a fatter field makes time-in-field matter more,
      so running became a point or two *cheaper* than walking through the four widest events. Not
      "running works" but "running is a coin flip". `EXCITEMENT_FROM_RUNNING` 9 → 14 restores the
      ordering, and `tests/test_events.gd` asserts it row by row — it had only ever been measured
      and written into a document, which is how it broke silently.
      Then the player asked for the opposite: *"the run button is a trap shouldn't be an invariant
      — there should be legitimate cases where running is required."* So `EventDef.pursues`:
      something that comes after **her**, faster than a walk and slower than a run, lethal, and it
      gives up. Walking and running give **opposite outcomes** rather than the same outcome at two
      prices, which is why it had to be a mechanic. `Tuning.validate_pursuit()` is its contract and
      it is stated over `RUN_SPEED`, exactly as this file said M25's would have to be. Verified by
      rig: a player who walks directly away from the first frame is still caught (1.6px), and one
      who runs escapes with 240px to spare
- [x] **Day 1 teaches walking, day 3 teaches running** — *"on day 1 we only introduce arrow keys.
      On day 3 we introduce the running key (it is possible to run before but not required), and
      have an incident at the start to force running."* `charging_dog` is gated to
      `Tuning.RUN_TAUGHT_DAY`; `EventDirector` moves the first one to the head of the queue on that
      day so the lesson is not left to a weight of 1.4; and the HUD says *Hold SHIFT to run* on the
      frame the dog telegraphs rather than at dawn. **This is half of M26 arriving before M25**,
      and the ordering constraint M26 was written with is satisfied rather than broken: the forced
      run is behind the thing that makes running right, and not on day 1
- [x] **The mark is for a beat you can actually play against** — finding 2's cue half. The rule was
      `pulse_period > 0` and six of the ten rows available on day 1 have a pulse, so the caret was
      over most of an ordinary street: the deleted ring's own mistake in the shape M22 invented to
      replace it. It is a relationship now — the period has to be shorter than the walk across the
      field, which is exactly when a pass can be slipped between two beats. Day 1 goes from six
      marked rows to two, and both are the ones whose counterplay is *go now*
- [x] **There is a pause** — finding 12. `Esc` opens it, `Esc` closes it, `Q` quits. It quit
      outright for thirty-three milestones and has been under known-shaky ground since M6
- [x] **Solid things are solid** — findings 16, 13, 7 and 15, done as **M34**. `obstructs_radius`
      was a list of five rows out of thirty and is a rule now: anything that stands still is solid
      at half its silhouette. A parked van moved off the carriageway to the kerb, where it takes a
      pavement instead of standing in a lane the crowd drives through; a reversing lorry got the
      building it reverses into, and is turned to face out of it; `alley_robbery`'s inner radius
      moved 22 → 30, because a lethal radius and a solid body are the same mechanism and a body
      that reaches the kill radius switches the kill off. Day 1: events placed unchanged at ~39,
      pavement-blocking obstacles 12.2 → 17.2
- [x] **One picture per row** — findings 2, 11, 4 and 14, done as **M37**. See the section below
- [ ] **The last four.** The cat crosses the wrong axis (1); a four-block concrete plaza (8); a car
      turning has no diagonal (6); and the crowd's own anonymity, which is deliberately *not* the
      same rule — see the bottom of `docs/PLAYTEST-07.md`

## M35 — Playtest 08: nothing vanishes, and the dog gives you a chance

See **[docs/PLAYTEST-08.md](PLAYTEST-08.md)**. Five things, all done.

- [x] **The spoiler covers the park rather than standing in it** — finding 1, which is playtest 07's
      finding 10 asked a second time. M24 placed **one** event and nobody did the arithmetic: what
      denies calm ground is out-emitting a decay the calm multiplier has raised to 7.7/s, so a
      busker at intensity 9 has a *useful* radius of 100px in a lot 704px across — three percent of
      a four-block zone. It is a crowd now, on a grid sized by `_denial_radius()` and capped by
      `Tuning.SPOILERS_TO_DENY_A_PARK`, with **each cell rolling its own def** so a spoiled park is a
      busker and a leaf blower and a market stall rather than nine copies of one sprite. Calm ground
      denied goes from 8–12% to **91%** of a courtyard and **99%** of a four-block zone, over five
      seeds and twenty lots. *"I can walk over the robber"* is the same finding from close up and not
      a regression of M34 — a probe confirms the body stops her at 25px exactly; what it does not do
      is cost her anything once she is there
- [x] **Nothing vanishes while you are looking at it** — findings 2 and 3, which are one rule.
      *"Things that move disappear on screen; they should at least run offscreen before despawning"*
      and *"pigeons are also completely ineffective"* — and playtest 07's *"birds just disappear"*, a
      milestone earlier. An event that is over now **leaves**: it stops emitting, it cannot end the
      day, it carries no cue, and it moves until it is past `Tuning.OUT_OF_SIGHT` before it is
      deleted. Anything mobile leaves at its own speed and needed no data; `EventDef.departs_at` is
      for a flock, which has to fly, and a pursuer that has lost interest. Two things never leave and
      both would break something that reads the finishing position — an event with a
      `spawns_on_finish`, and anything that was a place rather than a moment
- [x] **The pigeons are a thing to walk around** — the other half of finding 2. They sit on the
      pavement for their whole telegraph (a flock already in the air is a flock she has walked past),
      the burst outlasts her arrival instead of ending at it, and 20 over 140px moves the row from
      +22.9 to **+34.9** — between a reversing lorry and a dog walker, which is what a flock going up
      in a pram's face should be worth
- [x] **The dog gives her room to answer** — finding 4, and the one that ended the run. Two changes
      and they are the same change twice, the contract restated as **geometry**:
      `Tuning.pursuit_standoff()`, which the telegraph is spent closing to and *holding* — backing
      off if she walks into it, because she will, since it is sited in front of her and forward is
      where she was going — and a **break-off**, so the chase ends when it is beaten rather than when
      the clock says so. Without the second one the price of the right answer was
      forty points whether she reacted on the first frame or the last, and the trace has her running,
      doing exactly what the HUD asked, and losing to the meter with the dog 87px behind her. The dog
      also came down 148 → 130px/s (symmetric: walking loses 38px a second, running gains 38) and
      intensity 22 → 12, because it is lethal and does not also need to be the loudest thing in act I.
      Measured on a rig: walking loses either way, running costs **21–24 points**, and reacting
      sooner costs less
- [x] **And the log can see a chase** — the question the finding actually asked. Two `chase` entries
      per pursuit, carrying how close it got, how much of it she spent running, and whether it gave
      up or merely stopped. The old trace had an event being sited, four distances and a death, all
      of them about the **world**, while the question is about the **exchange**. `--flee` is the
      other half: a rig that can only hold a direction can only ever demonstrate the wrong answer
- [x] **Five nerves** — *"we need more nerves let's try 5?"* Three was the number from M6, when a
      lost day also advanced the calendar and a nerve cost a day of the fourteen as well as a life.
      M32 took that half away and left the number

## M36 — Playtest 09: the key that did nothing, and the man who did nothing

See **[docs/PLAYTEST-09.md](PLAYTEST-09.md)**. Four things, all done.

- [x] **`Esc` works** — and it had never worked. The guard read `visible` on a `CanvasLayer`, which
      is true from the moment the node is in the tree; the question it meant to ask is `is_showing()`.
      It opens **over** the between-days summary now as well, because `PauseScreen` puts back the
      paused state it found rather than assuming one — the first version refused there on the correct
      grounds that two things fighting over `get_tree().paused` is how a pause stops meaning
      anything, and the answer is to not fight. `tests/test_pause.gd` holds the trap itself as an
      assertion: *a fresh summary is not showing, and its own `visible` is true anyway*
- [x] **`--press <action> <seconds>`, so a rig can press a key** — the actual lesson. Neither the
      suite nor a screenshot could have caught the pause, because nothing in either has ever pressed
      one. Its own first version used `Input.action_press()`, which sets the polled state and nothing
      else: fine for `--walk`, useless for anything answered in `_unhandled_input`, and it produced a
      screenshot of the game carrying on — which looks exactly like the bug it was written to check
- [x] **The man shouting paces** — *"it didn't move and it took a long time to have any effect"*.
      `EventDef.paces`: a **beat** rather than a journey, so it walks its route, turns round at the
      ends, and neither departs nor expires, because it is a fixture that moves. Intensity 10 → 14
      (+17.7 → +31.2 in the cost table) and the body M34 gave him comes off, because anything mobile
      is exempt from "solid things are solid" — M19's `dog_walker` decision, unchanged
- [x] **The robber is a place that becomes a chase** — *"a robber should increase excitement on sight
      and getting close to them should be day ending"*, and *"if you get close they should start
      moving towards you"*. `EventDef.pursues_within`: three states rather than two, with the clock
      starting when it **notices** her and its notice **not** damping what it emits. 16 over 200px,
      lethal inside 30, 130px/s from 140. Standing, walking past and walking *away* all end the day;
      running shakes him off in ~1.5s for 21 points.
      **And a trap found by measuring:** while the chase ended at a *distance*, a trigger at or past
      that distance was a pursuit that lost interest the instant it started — at 170 against 170 the
      rig strolled away from him every time. A break-off stated as a rate cannot reproduce it
- [x] **And a scar could be tidied away by the usable-park rule** — exposed rather than caused by the
      above. `_ensure_one_usable_park` strips the spoilers off the least-disturbed calm block, and a
      burnt-out shell that had been on that corner since day 3 was one of them. Scars are exempt now,
      for the same reason ambient events are: a permanent feature of the map is not today's noise

## M37 — Playtest 07 again: one picture per row

See **[docs/PLAYTEST-07.md](PLAYTEST-07.md)**. Four of the six that were left, and they are all
"what you can actually see".

- [x] **One picture per row, and no two rows share one** — finding 2, and the fix is bigger than
      the finding because the finding was a symptom. `EventDef.Look` opened with five
      **categories** — `PERSON`, `VEHICLE`, `OBJECT`, `ANIMAL`, `FIRE` — and a category is a thing
      you can always put one more row into, so sixteen of the twenty-eight visible rows drew five
      pictures between them: five people on one man, six vehicles on one van.
      **It had already cost two findings and neither looked like an art problem.** M34 spent a
      milestone fixing `alley_robbery` for a complaint about `homeless_yeller`, because a player can
      only say *"the robber"*; playtest 09 then asked *"who is the person killing me?"*. And a third
      had gone unreported — `DangerEdge` kept its **own** table of which picture a look meant, so
      the screen-edge badge, whose entire content is *what* is coming, drew a delivery van for a
      fire engine and for the unmarked van that takes the baby.
      So it is a rule with a test rather than fifteen drawings: no two rows share a look, no two
      looks share a silhouette, `EventInstance.icon_for()` is the one table, and `look` has no
      default worth having. **The cost of adding an event is a drawing.** Same move as M34's
      `obstructs_radius`, on the other half of the vocabulary
- [x] **The robber has two postures** — `is_waiting()` picks between them. M36 gave that row three
      states and the screen showed one, so *a man is standing there* and *he has seen you* looked
      identical. The `cat_crouched` / `cat_running` rule, at the row where reading it wrong ends
      the run
- [x] **The protest is a crowd, and its body followed its picture** — the catalogue said of that
      row *"one person's worth, because one person is what it draws… the art is the fix"*, and it
      is 55px now, two ranks drawn across exactly the ground it takes. The clearest case in the
      game of art deciding a gameplay number. Measured over five seeds: events placed per day is
      **identical**, day for day, and so are protests placed
- [x] **The café has people at it** — finding 11. The tables were what obstructs and the
      conversation was what it emits, and only the first was drawn
- [x] **Buildings sort against nothing** — finding 4, diagnosed in M34. The fix is not the one the
      diagnosis pointed at: the comparison is **meaningless**, not merely wrong. Buildings tile
      their lots exactly and no lot tile is walkable, both asserted since M3, so nothing can ever
      legitimately stand behind a building. `Buildings` is a y-sorted layer under `Entities`.
      `building.gd` had claimed the opposite in a comment for twenty-two milestones
- [x] **The zzz stops dodging nothing** — finding 14. The baby's cue steps out of the exclamation
      mark's column, and that column is only occupied when there is a mark in it; unconditional, it
      put the zzz a body's width to one side of the pram on the commonest picture in the game.
      Playtest 06's own lesson again — *a cue is a claim about a moment* — reaching a player for
      the reason M32's two did: nothing in `tests/test_danger.gd` can see a `_draw()`. It is
      `Stroller.baby_cue_aside()` now, and the suite asks it

## M38 — Things that shipped and did not work · `feature/nothing-freezes`

Not a playtest: five reports and two design instructions, delivered in one sitting. What they have
in common is that every one of them had passed a green suite, a screenshot, or both — see the note
at the top.

- [x] **The birds are eleven birds** — *"they start the flying animation but then freeze. Turn them
      into individual entities and let each fly and make them dangerous."* A flock was one sprite
      drawn seven times at offsets derived from the instance's own position, sharing a single `rise`
      term that reached 1.0 at the end of the telegraph and then held — so the flock went up in one
      movement and hung motionless for the whole burst. `EventDef.flock_size` gives each bird its
      own heading, speed, height and wingbeat, **and its own contribution**, so the middle of a
      flock stacks five fields and the rim stacks one: +35 walked through the centre, +8 eighty
      pixels off it, nothing at the rim. It is the only row in the game that is more than one
      source, which is why `tests/test_events.gd` had to learn to price one — left as a disc the
      row read +97 and broke the running rule it in fact keeps. Two traps, both in `CLAUDE.md`:
      `flock_spread` comes out of `outer_radius` or the fairness contract is about a different
      disc, and `lerp` cannot turn a vector round
- [x] **The cat faces the way it is going** — *"the cat graphic is flipped horizontally."* Both cat
      SVGs were drawn facing **west** while every other sprite with a front faces east, and
      `_heading_is_west()` mirrors the art — so a cat bolting west was drawn running east and a cat
      bolting east was drawn running west. The convention was never written down anywhere; it is
      inferable from `dog.svg`, which is drawn ahead of the walker on a taut lead and only reads
      right facing east. The art was wrong, not the flip
- [x] **A car looks before it turns** — *"when a car turns into an occupied lane the other car just
      disappears."* `_divert()` chose an arm out of the tile map alone, so a car diverting round a
      closure materialised inside whatever was in that lane, and the M27 positional resolve then
      moved a body — front to back, compounding, up to 134px in one frame, on screen. `TrafficIndex`
      is the look; `claim()` closes two placements in the same frame; `_join_the_back_of_the_queue()`
      is the guarantee behind the six re-rolls. Measured at a closure over 90s: 1627 corrections and
      a worst of 134px, down to 146 and 66px. The queue was legal on every frame either way, which
      is why the test that has always been here passes both
- [x] **Calm ground is 20% faster** — `SLEEPINESS_CALM_ZONE_MULTIPLIER` 10 → 12, so the meter fills
      in 20s rather than 24. Every milestone since M28 has made the walk *out* harder and left the
      reward at the end of it the same length. Unfelt; it is in the known-shaky list
- [x] **A finished run has a key on it** — *"the lost screen doesn't allow for restarting the game.
      You can just cycle between pause screen and loss screen at that point."* The ending said
      `esc to quit`, `Esc` opened the pause, and the pause offered `Esc` and `Q`. `space` on the
      ending now goes back to the title, and `R` on the pause starts the run again from anywhere
- [x] **A title screen, with the game running behind it** — *"start on the pause screen, or create a
      game open screen"*, then *"just use the home and street in front without player and let act I
      events play out."* Not a menu and not a still: the doorstep of a real, planned first day, with
      the traffic driving and the events playing out on it and nobody pushing a pram through them.
      It needed the `process_mode` split used deliberately for the first time — the city on `ALWAYS`
      and the day paused, with the player pinned back to `PAUSABLE` because she is a child of the
      city — and `Stroller.stand_aside()`, which takes her out of the `player` group and with it
      every way the world can touch her
- [x] **`--press` can press a key, and can press more than one** — `Q` has quit from the pause
      screen since M33 and `R` restarts now, and neither is an input action, so the rig that exists
      because *nothing in the suite or a screenshot has ever pressed a key* could not press either
      of them. `--press key:r 3.5`, and the flag may be repeated

## M39 — Playtest 10: the cue that meant nothing, and the day that was not the same day · `feature/marks-that-mean-danger`

See **[docs/PLAYTEST-10.md](PLAYTEST-10.md)**. Fourteen findings, reported as a list after a session
of five runs in which **no day was won**. Eleven are work; two are answered in writing; one — the
difficulty — is deliberately the milestone after this one.

The sentence under it: **the danger marks and the danger have come apart, and a retried day is not
the same day.**

- [x] **The mark is raised by what a thing costs** — findings 1, 8 and 9, which are one finding with
      three faces. `wants_a_mark()` asks whether the danger *changes over time*, which is a true
      statement about a thing and not a statement about how bad it is: a fire engine (+115) carries
      no caret and a burning building (+56) does, the most expensive ordinary row in act I
      (`dog_walker`, +36) carries none and the leaf blower beside it does, and the man who ends day
      1 in three separate traces (`homeless_yeller`, +31) misses `can_be_timed()` by four tenths of
      a second. The colour half is streaming: `EVENT_STREAM_RADIUS` is 900px and no telegraph is
      longer than 4s, so amber is only ever seen on the two `AHEAD_OF_PLAYER` rows and therefore
      means *near* rather than *not yet*. New rule, with the invariant a test can hold: **if A is
      marked and B is not, A costs more than B**; amber for *go round it*, doubled deep red for
      *ends your day*, and the flash — not a colour — for *it has not started*. Accepted cost,
      written down as a decision: the crouching cat (+20) loses its caret
- [x] **The playground is the calmest ground in the city** — finding 2, and it has been true for
      twenty milestones. `PLAYGROUND` is calm ground, so the decay on it is 7.7/s, and the row emits
      **7.0/s at the peak of its pulse**: it has never once out-emitted the ground it stands on, and
      its denial radius is its own inner radius, 40px of 150. It was right in M5, when the calm
      multiplier was 3.5 and the decay 1.5/s; M18 took it to 10 and M38 to 12. Playtest 08 did this
      exact sum for the busker one function away, in `_denial_radius`, which carries the warning in
      its own docstring
- [x] **The dog follows for too long** — finding 13, *"the running tutorial dog is impossible to
      escape"*, and **the analysis in this session was wrong**. It read the finding as a *reaction
      window* — `pursuit_standoff()` buys `PURSUIT_REACTION` seconds of the dog's 130px/s while she
      is walking into it at 92, so the real window is 0.2s — and built the fix for that. The player's
      own account: *"the charging start earlier was fine — it was enough time to react properly"*,
      *"the issue was that the dog kept following for too long"*, and *"the dog now moves backwards
      before charging — that doesn't make any sense"*.
      The trace agrees with the player: she reacted, she ran, and she **died to the meter with the
      dog 63px away**. It is the **break-off**, which is M35's failure repeating. The work built on
      the wrong reading is in the tree, uncommitted, and `docs/HANDOFF.md` lists every constant to
      re-decide.
      **What was built instead**: `Tuning.PURSUIT_SHAKEN_OFF`, which ends a chase after 0.8s of the
      gap **opening** rather than after a fixed gap has been reached. Because a pursuer is faster
      than a walk and slower than a run by construction, only running can open the gap — so "walking
      away can never end a chase" and "running away always ends one" stop being two inequalities that
      fight over the same three numbers and become facts. The reaction, the stand-off (104px) and the
      chase (3.0s) all go back to what a player said was already right. Measured: the answer costs
      **0.86s of running, 12 points**, against 35 before.
      **Two things found on the way are kept**: a pursuer must stand off inside its own
      `outer_radius` (found by a rig — the dog was holding 174px out with a 150px field, so the phase
      that is supposed to *be* the warning emitted nothing and the `!` never went up), and
      `tests/test_events.gd` has a rig that **accelerates**, which the three that passed while the
      encounter was unplayable did not.
      **Still open, and written down rather than hidden**: the window to answer at the lunge itself
      is 0.1–0.2s, because she is walking into the thing. A player answers during the telegraph
      instead. Widening it means a wider stand-off, and a wider stand-off is the reversing dog
- [x] **A retried day is the same day, and the day-3 lesson always happens** — finding 5. Three
      independent causes and the third is the one that matters. `_place_one_shots` skips a consumed
      one-shot *before* drawing its `randf()`, so attempt 2 starts a value earlier in the stream and
      every later placement moves — five seeds out of five produce a different day 3, and one of
      them changes how many `charging_dog`s exist. `_place_scars` compounds it through
      `_room_around`. And **the tutorial is a weighted roll**: `_teach_the_run` says outright that
      if the day did not buy one, nothing happens, and whole day 3s with `charging_dog x0` exist.
      Also the director's clock only runs while she is moving, and the third attempt in the trace
      never left the doorstep
- [x] **The `!!` comes down when the danger has been avoided** — finding 11. The doubled mark is
      raised for any lethal event whose **outer** radius covers her, so a cyclist lethal inside 26px
      raises it across 145 and keeps it up while the bike rides away. Playtest 06's finding 3 at the
      half M32 did not fix — it gave the traffic a `stand_down()` and left the events on "inside the
      radius". Two conditions now: within a step of what ends the day, **and** closing. Deliberately
      the *relative* rate, where the screen-edge badge deliberately uses the thing's own — the two
      cues say different sentences and the difference is the reason
- [x] **The zzz over the pram** — finding 3, and the other half of M37's own fix
- [x] **`space` carries on, and the pause says which day and how many nerves** — findings 6 and 7
- [x] **Screenshots beside the trace** — finding 12. On the entries that are already *about a
      moment* — a day lost, a nerve, a hard fail, a chase — rate-limited, capped per day, named
      after the entry. In `TelemetryObserver`, because telemetry never touches gameplay
- [x] **Logs you can throw away** — finding 14, plus the follow-up that explains it: a run restart
      reloads the scene, so one sitting is several logs and that is correct. The commit goes in the
      **filename**, `tools/telemetry.sh` grows a prune, and the listing says which are stale
- [x] **The yellow person that did not approach** — finding 4, answered in writing rather than
      built: nothing in act I pursues, and a busker who chases prams is a different game. It is
      recorded because it is findings 1/8/9 from a fourth side — *I cannot tell what any of these
      things are going to do to me*
- [x] **Home at the centre** — finding 10, answered in writing. The city is already odd (7×7) and
      `_place_home` already sorts by distance to the centre; what pushes the home out is
      `MIN_HOME_TO_PARK_TILES`. The two rules compete for the same thing and at 7×7 both cannot
      hold. The recommendation is to take the trade **by growing the city to 9×9**, as its own
      milestone, because it re-measures every density number in `docs/PLAYTEST-04.md`

### And the thing nobody reported

- [ ] **The crowd is winning.** Nineteen days lost in the session, seventeen to `lost_crying`, and
      the breakdown on the losing line reads `crowd 39.4, events 0.0` / `crowd 44.4, events 3.1` /
      `crowd 28.8, events 0.0`. That is playtest 07's finding 17 after the milestone that answered
      it, and two of the fourteen are downstream of it. **The next milestone**, measured rather than
      argued — not this one

### And the tooling that is getting in the way

- [x] **The test suite takes too long to run.** Done as **M44**; it was 8.4 minutes and is 96
      seconds. Not one of the four things this entry proposed turned out to be where the time was —
      see the milestone for what measuring found instead.

## M40 — Documentation you can read, and history you can retrieve · `feature/timeless-docs`

Asked for directly: *"adopt a timeless documenting style. Things should be stated as what they are,
not where they came from. Keep a dedicated file for ideas that were rejected, decisions that were
made (and which options were rejected), and changes that happened."* And: *"especially for
docstrings make sure to document the why and the edge cases; don't restate the full
implementation."* And: *"we don't want to lose history/information — we just want to make the
current state more accessible and the history retrievable on demand instead of always in context."*

**The problem, stated plainly.** This project writes history into the thing itself. A docstring
opens with *"(M39, playtest 10 finding 13: …)"*, a constant's comment is three paragraphs about the
two numbers it used to be, and `CLAUDE.md` is 900 lines in which the rules and the archaeology are
interleaved. That was a deliberate bet — the reasoning is not recoverable from a diff — and it has
paid off repeatedly. What it costs is that **reading the current state means reading every past
state first**, and every reader of every file pays it whether or not they need it.

The fix is not to delete any of it. It is to **split by question**: *what is this and why is it like
this* stays with the code; *what was tried, what was rejected, and when it changed* moves to one
file that is read on demand.

- [ ] **`docs/DECISIONS.md`, the retrievable half.** One file, three kinds of entry, each dated and
      each linking to the milestone and the playtest that produced it: **decisions taken** with the
      options that were rejected and why; **ideas rejected** outright; and **changes that happened**,
      with the measurement that justified them. It is the destination for everything the restyle
      lifts out, so nothing is lost — the test is that every fact removed from a docstring can be
      found by searching this file for the symbol name
- [ ] **Restyle every docstring.** Say what the thing is, why it is that way, and what the edge cases
      are. Do **not** restate the implementation — the code is right there — and do not narrate the
      milestones it passed through. Where a number was tuned against something, keep the
      *relationship* (*"above the 7.7/s decay on the ground it stands on"*) and move the story of how
      it got there. `Tuning.PURSUIT_SHAKEN_OFF` and `Tuning.pursuit_standoff()` are the worked
      examples of what an edge-case docstring should read like
- [ ] **Revisit all documentation, not the code alone.** `CLAUDE.md`, `README.md`, and every file in
      `docs/` — `ARCHITECTURE`, `CITY`, `DESIGN`, `EVENTS`, `MECHANICS`, `NARRATIVE`, `TELEMETRY`,
      `TODO`, `HANDOFF`. The playtest files are already history and stay as they are; they are the
      primary source `DECISIONS.md` cites
- [ ] **`CLAUDE.md` becomes rules, and the rules get subfiles.** Working preferences, invariants and
      recipes stay; the war stories under each move out. Anything too long for one file becomes a
      rule file of its own rather than a longer `CLAUDE.md`
- [ ] **And notes live in the repo, not in a session's memory.** Anything worth remembering about how
      to work on this project goes in `CLAUDE.md` or a rule/skill file beside it — a note that exists
      only in an assistant's memory is a note that gets lost

## M41 — The shape of the city: a spine, and an edge you can walk to · `feature/the-shape-of-the-city`

See **[docs/PLAYTEST-11.md](PLAYTEST-11.md)**, section C, and **[docs/PLAYTEST-12.md](PLAYTEST-12.md)**,
which is this milestone played while it was still on the branch. Three entries that are one
milestone, because they are the same sentence: **the city has no hierarchy.** Every street is the
same street, the arterials differ only by how many cars are on them, and the map stops at an
invisible wall.

This also closes the half of **M21** left open by decision — *main roads with lights* — and replaces
the earlier "cliff, fences, harbour" sketch with the design the player gave, which is better for the
reason they gave: *"that way it's not an artificial end but an emergent end."*

**All of it is done.** What follows is what each part turned out to be; the corrections marked
*(playtest 12)* are the ones a person found in it the same day.

- [x] **Three kinds of street, told apart at a glance.** A main road — dark asphalt, an unbroken
      double centre line, doubled clearway markings on its kerbs, signalled at every junction and
      **it does not give way to anybody** — against a retail precinct, which is brick from frontage
      to frontage with no kerb and no cars in it, against the ordinary street that is everything
      else. *(Playtest 12, findings 1, 2 and 7: there is **one** main road and it runs north to
      south, and there are **two** precincts of three blocks each, one along the southern shore.
      The first build made one of each per axis, which is three kinds of street and no hierarchy
      among them.)*
      **A wider main road was tried on paper and rejected**, and the reasoning is in `docs/CITY.md`:
      the corridor cross-section is uniform by construction, a 1-tile pavement is the width M1
      found unwalkable, and doubling a carriageway restates the traffic fairness contract for every
      street at once
- [x] **And the ground is a rate, not a category** — *(playtest 12, finding 8)*, the change that
      makes a route a **recovery rate**: calm 2.2, precinct 1.5, ordinary street 1.0, main road 0.6.
      `WorldContext` grows a fourth question, which generalises the half of `is_calm_zone` that was
      never a threshold. It is the first time since M14 that the ground has done anything except be
      calm or not, and it is what makes a precinct worth walking to although it is loud
- [x] **Traffic lights.** The cycle is **derived** from the block spacing rather than authored —
      `2 × SIGNAL_PROGRESSION_BLOCKS` junction-to-junction travelling times — which is what lets a
      green wave run both ways down the same street. Without a progression two thirds of the traffic
      stands still at any instant, measured. **The "both ways" half of that is wrong and M46
      measured it: the wave serves one direction and cannot serve two on this geometry.** The side
      street's green is the fairness contract
      (`Tuning.validate_signals`), because she crosses a main road while the main road is red; the
      amber is a clearance period, not a warning. *(Playtest 12, finding 4: the four heads at a
      junction are now two drawings — face-on for the arms running up and down the screen, edge-on
      for the ones running across it, so what you can see of the lamp is which street it means.)*
- [x] **A tunnel north, a bridge south, and the main road running out east and west**, plus a ring
      of frontages one block deep outside the whole boundary — and **the camera may see past the
      map**, which it could not, and which is why the edge would have gone on looking like a wall
      however much was built out there. The lattice already ended in T-junctions and nobody could
      see it: the outermost corridor is a whole street and every interior street runs into it and
      stops. No walkable tile moved
- [x] **Cars do not enter a junction they cannot leave.** Measured before: **3,776 overlapping
      crossing-axis pairs in ninety seconds of the arterial, one in half of all frames, the deepest
      39px into a 40px footprint** — with every assertion about the traffic passing throughout,
      because each car's own *lane* was legal. Four clauses, all load-bearing, in `CLAUDE.md`. The
      one that decides whether a grid queues or seizes is *nothing enters a box it cannot leave*
- [x] **And a car that does enter an occupied box is an accident** — built as the M19 mechanism
      rather than as a catalogue row: it **startles the cars it happened to**, so it is loud where
      it happened and composes by addition like every other body. Deliberate: with the box rationed
      it happens under one frame in twenty of the busiest street in the city, and an event nobody
      meets in a run is a silhouette and a fairness contract spent on decoration
- [x] **11×11.** *(Playtest 12, finding 9.)* The first resize taken for room rather than for a rule.
      The act I caps went up with it — a budget the catalogue cannot spend is not density (M28) —
      and the suite went from 96s to ~160s, which is the price of 49% more city
- [x] **Judged by eye.** Screenshots of all three kinds of street, a signalled junction across the
      cycle, the promenade, and all three exits. Two things were only visible that way: the tunnel
      opening into the void beyond the frontages, and the four identical signal heads at a junction
- [x] **And every route guarantee re-measured, not assumed.** Nothing moved a walkable tile, which
      is why `tests/test_blocks.gd` and `tests/test_routes.gd` are the measurement rather than a
      hope: a precinct is paving where pavement was, a main road is paint, and an exit is the last
      stretch of a street that was already there

### What playtest 12 changed on top of that

- [x] **One main road, north to south** — finding 2
- [x] **Two precincts of three blocks, one on the shore** — findings 1 and 7, and they are retail:
      `PRECINCT_BUSYNESS` for the foot traffic, `EVENT_PRECINCT_WEIGHT` for the cafés and stalls
- [x] **Walkers use the whole width of a precinct** — finding 1's *"people seem to not go in the
      middle"*, which was right and was not a steering bug: the middle two offsets are the
      carriageway on every other street, so nothing had ever been placed there
- [x] **The spine carries forty cars** — finding 3. It was not that thirty was too few; it was that
      there were two main roads and the weighting split between them. One spine is blocked 81% of
      the time
- [x] **Calm areas: one per day of the longest act, plus one** — finding 5, and the spoiler
      remembers the whole **act** rather than the night before, resetting when the act turns. One
      night's memory makes day 2 a fresh decision and day 3 the same decision as day 1
- [x] **Calm ground fills the meter 20% faster again** — finding 6, `SLEEPINESS_CALM_ZONE_MULTIPLIER`
      12 → 14

### The old plan, for what it said

- [ ] **Two kinds of street, told apart at a glance.** A main road — wide, fast, heavily trafficked,
      signalled — against an ordinary or pedestrianised street that is slow, crowded and has no cars
      in it. The point is not decoration: with one kind of street the route decision is only *which
      way*, and with two it is also *which kind*, which is the trade the whole game is made of. It
      needs a visual difference that reads without a legend
- [ ] **Traffic lights.** A signalled crossing is a **timing** problem where a zebra is a gap-hunting
      one, and it is the honest counterpart to *"the arterial has a safe gap about one time in
      twenty"*. Re-measure the mean wait at a kerb afterwards; that number is the whole of whether an
      arterial is crossable
- [ ] **A tunnel north, a bridge south, and the main road running out east and west.** One of each,
      carrying the spine off the map. **Walkable, and fatal when a car comes** — not a special case,
      just the traffic fairness contract on a stretch of carriageway with no pavement beside it. The
      player walks out of the world rather than being stopped by a wall
- [ ] **T-intersections everywhere else on the edge.** The lattice currently runs into the boundary
      and stops. A T says the street turns rather than being cut off
- [ ] **Cars do not enter a junction they cannot leave.** M38 made a car turning into an occupied
      *lane* look first (`TrafficIndex`); the **junction box** was never modelled, so two cars on
      crossing arms both see a clear lane ahead and both enter, and the positional resolve then does
      the only thing it can — move a body. Same shape as M38's fix, plus the thing a junction needs
      that a lane does not: a **priority rule.** Right-before-left, which settles the symmetric case
      without a negotiation; lights override it where they exist
- [ ] **And a car that does enter an occupied box is an accident**, which is an event, not a
      collision to be resolved away. Deliberate, and worth building rather than losing
- [ ] **Judged by eye.** A headless run never calls `_draw()`. Screenshots of both kinds of street,
      a signalled crossing, all four edges, and a junction under load, on several seeds
- [ ] **And every route guarantee is re-measured, not assumed.** Three walkable exits move the
      walkable set, which `tests/test_blocks.gd` asserts is identical tile for tile across every seed
      and block arc. A route that leaves through a tunnel must not count as a route to a calm area

## M42 — A city with a middle · `feature/a-city-with-a-middle`

Playtest 11, finding 4, asked as a question in playtest 10 and as an instruction now: *"let's make
the home be the center (with an odd number of rows/cols blocks) mandatory. I spawn too often at the
edge leaving only a few ways into the rest of the city."*

**The diagnosis is that two existing rules compete for the same thing.** The city is already odd at
7×7 and `_place_home` already sorts candidate blocks by distance to the centre; what walks the home
outward is `MIN_HOME_TO_PARK_TILES` = 30, and the centre of a 7×7 city is rarely 30 tiles from every
park. Both rules are about the same thing — the walk out has to be long enough to matter — and at
7×7 they cannot both hold.

- [x] **9×9.** Odd, and large enough that a central home is still a long walk from calm ground.
      Acceptance test: `MIN_HOME_TO_PARK_TILES` satisfied from a block within one of the centre, over
      200 seeds
- [x] **Re-measure every density number in `docs/PLAYTEST-04.md`.** 65% more blocks, one event per
      block since M28, and a crowd that is a field around the player since M27 — so placed per day,
      live inside the stream radius, on screen at once, and met on a route all move, and the budget
      with them. This is why it is a milestone and not a constant
- [ ] **And check what a wheel does to the return phase**, which playtest 03 already called a
      formality. Four ways out is four ways back

**Measured, ten seeds** (`docs/CITY.md`, "The home", carries the table). Home offset from centre
1.97 blocks → **0.00**, central in 4/10 → **10/10**, calm areas lying in 2.9 of 4 directions → **3.7
of 4**, and directions with real city behind them 3.4 of 4 → **4.0 of 4**. The 30-tile guarantee got
*better* rather than worse — 32.0 tiles at 9/10 seeds → 39.4 at 10/10 — because the clearance rule
replaced the walk-outward rule. Events per block on day 1: 0.97 → **0.94**, which is the number that
had to not move, and `budget_for()` is stated per block now so it cannot drift on the next resize.

**One thing this changed and did not measure**, recorded in `docs/CITY.md`: the crowd is a field of
fixed population in a fixed-size box clamped to the city, so a doorstep at the boundary had the same
agents spread over fewer streets. A central doorstep should therefore be *thinner* per street, which
is the opposite direction from the open difficulty question — and it wants the crowd milestone's own
measurements rather than an assumption.

## M43 — Things that are in the way of nothing · `feature/in-the-way-of-nothing`

Playtest 11's remaining findings. See **[docs/PLAYTEST-11.md](PLAYTEST-11.md)**. The sentence under
the first three: **several things in this city are placed without asking what they are in the way
of** — which is `CLAUDE.md`'s first rule failing at *placement* rather than at design.

**Where it stands: three done, two answered by measuring rather than by building, and the two that
needed a played run have now had one.** Playtest 13 answered both — the cool-off is the wrong
*quantity* rather than the wrong constant, and dying at high excitement on a quiet street is the
crowd milestone — and added one more to this milestone, the day-4 dog. What follows is the plan
with what each part turned out to be.

- [x] **Nothing is placed on the home block** — finding 1. It is `ClosurePlanner`'s exemption
      applied to the other thing in the game that occupies ground, and it is stated over the
      **street segment** rather than a radius, because a segment is the unit the player can see the
      shape of and it ends at the junction where the choice is made. Measured before the change,
      eight seeds over days 1, 3, 7 and 14: **0.47 events a day** stood on the street outside the
      front door — one morning in two — and it is 0.00 after, with events placed per day unchanged
      at 155.9. The share was exactly the share of the pavement that street is (0.30% of both),
      which is placement being uniform and is why it needed a rule rather than a weighting
- [x] **The diagonal zzz comes back down** — finding 9, and see the entry further down
- [x] **The dog stands its ground** — finding 3's first half, and see the entry further down. What
      it left open is the number, and that is the decision below
- [ ] **A closure has to change a route** — finding 2, *"road blocks next to parks are pointless"*.
      The route-redundancy invariant is used as a **floor** (the day stays winnable two ways) and
      never as a **filter**: a closure that does not lengthen the best route to any calm area by a
      real margin is legal, invisible and pointless. Measure what fraction of today's closures do
      nothing before choosing the margin

      **Measured, and the filter is not the answer — there is nothing to filter to.** Ten seeds,
      fourteen days, 350 closures, each measured against the set accepted before it:

      | what it changed | share |
      |---|---|
      | streets on the best route to the nearest calm area | **+0 for 100%** (1 closure of 350 added one) |
      | streets on the best route to *any* calm area | **+0 for 97%** |
      | tiles actually walked from the door to the nearest calm ground | **+0 for 99%** (the worst four added 1, 2, 6 and 6) |

      Then the question the filter would have to answer: **of every street in three whole cities,
      how many would lengthen the walk at all if they were the day's only closure? Eight of 768** —
      and three of those eight seal the city off entirely, which the invariant already refuses. A
      *run* of consecutive streets is no better: 11 of 534 four-street runs move the number.

      The cause is structural rather than a bug, and it is the city that moved. A Manhattan lattice
      has many equal-length staircases between any two points, so removing one street almost never
      lengthens anything — and the city now has **8.9 calm areas** with the nearest **38.8 tiles**
      from the door, so there is always another destination in another direction. M16 built closures
      for a 7x7 city with far fewer parks in it. **A closure cannot change a route while there are
      nine destinations and a full grid**, and no margin, filter or run length fixes that.

      **Deferred to M45, with the design taken.** The answer is not a filter and not a margin: it
      is that the question was wrong. A closure's job is **direction, not distance** — see M45
- [ ] **A busker in a courtyard denies the courtyard** — finding 5, *"I can still walk around (and
      over him) while the sleepiness meter goes up"*. Two halves and both are arithmetic. **Around:**
      what denies calm ground is out-emitting the 7.7/s decay the calm multiplier has already raised,
      which is what `EventScheduler._denial_radius()` exists to compute — this is the third row to be
      caught by that sum (the busker in playtest 08, the playground in playtest 10). The suspicion is
      that a courtyard, the smallest calm area, gets a spoiler grid of one. **Over:** anything mobile
      is exempt from *solid things are solid*, and `EventDef.paces` made the pacing man mobile. Both
      need measuring before either is moved

      **Measured, and both halves come back negative on `main`.** Eight seeds, three days, every
      calm area spoiled in turn, counting a tile as denied when what the day emits there beats the
      calm decay:

      | calm area | denied | things in it | of them solid |
      |---|---|---|---|
      | courtyard, 16 tiles | **100%** | 1.0 | 1.0 |
      | one block, 64 tiles | **100%** | 3.4 | 3.1 |
      | four-block zone, 484 tiles | **98%** | 9.9 | 9.7 |

      So the suspicion is wrong in the most useful way: **a courtyard does get a grid of one, and
      one is the right number** — a busker's denial radius is 100px and a 16-tile courtyard is 128px
      across, so one of him covers it. M35's crowd and M41's act-long memory closed the "around"
      half between them. And the "over" half is a case of *check which event a complaint is about*
      (the M34 lesson): the **busker has a body** (`PERSON_BODY`) and does not pace. The only row in
      the catalogue that paces is `homeless_yeller`, which is mobile **by decision** — playtest 09
      asked for it by name, and mobile things have no body since M19. What is left of this finding
      is therefore not arithmetic at all: it is whether a *paced* man in a park should be walkable
      through, which is the `dog_walker` bargain and is already in the known-shaky list
- [x] **The dog stands its ground, and lunges on proximity rather than on a clock** — finding 3,
      *"it should be still"*. It reverses because it reaches its stand-off in a third of a second and
      then has two more seconds of telegraph to spend while she walks into it. *Standing still* alone
      is the thing M35 rejected and was right to: she then reaches it **before** the clock lets it
      fire, and it kills her from a standing start. Firing the lunge when she comes inside the
      stand-off — or when the telegraph runs out, whichever is first — gives both: it never reverses,
      and the chase always starts at the stand-off, which is the whole content of the contract.
      **`PURSUIT_MIN_NOTICE` has to be re-decided with it**: a player who walks straight in then gets
      about 1.2s of visible dog against a 1.5s floor that was authored rather than derived. Siting it
      further out is capped by the screen — 360px tall, so past ~180px a dog telegraphing north or
      south of her is off the top of it

      **Built, and it does what was asked: the reversing is gone and every lunge starts at the
      stand-off.** Walked on a rig, four ways of meeting it, sited at 184px against a 104px
      stand-off:

      | she | notice | lunges at | reverses |
      |---|---|---|---|
      | walks straight in | **0.38s** | 100px | 0.0px |
      | stands still | 0.63s | 102px | 0.0px |
      | walks away | 2.42s (the clock, not her) | 103px | 0.0px |
      | runs away at once | never lunges | — | it gives up at 1.5s |

      **And the estimate above was three times too generous, which is the part that matters.** The
      notice is not 1.2s, it is **0.38s**, and the arithmetic says it cannot be much more: she is
      walking *into* it at 92px/s while it comes at 130, so the 80px between where the director
      sites it and where it stops close at 222px/s. Siting it at the screen's own cap
      (`SIGHT_AHEAD`, 200px) buys 0.43s. Nothing reaches the 1.5s floor from that geometry.

      The floor still **passes on load**, because `validate_pursuit` reads `telegraph_time` off the
      def and the def still says 2.4 — which is M35's lesson arriving for the third time: *a
      fairness contract stated in seconds is not stated at all*, and the encounter changed while
      every line about it stayed true.

      **Decided: buy back what the geometry can, and leave the floor alone.** A pursuer is sited at
      `Tuning.SIGHT_AHEAD` (200px) now rather than at the clamp that produced 184 — the cat's
      reaction window was never a chase's, and everything between the siting and the stand-off is
      the whole of the notice a pursuit has left to give. It buys **0.38s → 0.43s**, and it is all
      that is available: the visible world is 360px tall and a dog telegraphing off the top of the
      screen has no telegraph at all.

      **Still open, and written down rather than quietly closed:** `PURSUIT_MIN_NOTICE` is 1.5s and
      the walk pays 0.43s, so the constant is a statement about `telegraph_time` and not about the
      encounter. What makes that survivable rather than a lie is that the *contract* was never the
      floor — it is `pursuit_standoff()`, which every lunge now starts at, so she is owed
      `PURSUIT_REACTION` from the moment it can touch her whatever she did to get there. The next
      person to touch this should state the notice **over the walk** and assert it with a rig, and
      the two ways to widen it both cost something: a narrower stand-off spends the reaction window
      at the lunge, and there is no more screen
- [ ] **And the cool-off is played, not re-derived** — finding 6. `Tuning.PURSUIT_SHAKEN_OFF` landed
      in M39, after this report was taken: 0.8s of the gap opening, and the measured price of the
      answer went from ~35 points to **12**. If it still reads as slow it is one constant

      **Played, and it is not one constant — it is the wrong quantity.** *(Playtest 13, finding 6:
      "the dog doesn't stop fast enough on day 3 — we talked about this! when running the pursuit
      should stop quickly — it **only** should keep going if the player doesn't run.")* Two chases
      in the trace lasted **5.4s**, nearly twice `PURSUIT_TIME`, while she was running for most of
      them; the first turned a meter reading 9 into a meter reading 95 and ended the day.

      | day | chase lasted | she ran | it cost |
      |---|---:|---:|---|
      | 3, attempt 1 | **5.4s** | 3.2s | exc 9 → 95, lost the day |
      | 3, attempt 4 | **5.4s** | 2.1s | exc 16 → 66 |

      The cause is that `_outrun_for` needs **0.8 continuous seconds** of the gap opening and any
      frame that does not open it resets the timer to zero. A real player does not hold a key down
      for a clean 0.8s: she ran in four separate bursts — 1.2s, 0.5s, 1.4s, 0.4s — and every gap
      between them put the counter back. Worse, the first `(WALK_SPEED + RUN_SPEED) / ACCELERATION`
      of every burst is spent turning round, during which the gap is still **closing**, so a 1.2s
      burst can contain well under 0.8s of opening.

      **So the break-off condition becomes *she is running away from it*, read directly.** M39's
      rate framing was the right fix for a different complaint and its guarantee still holds —
      *only running can open the gap*, so walking cannot fake it — but it buys that guarantee by
      measuring the **consequence** of running rather than running itself, and the consequence is
      polluted by acceleration, by diagonals and by a player who lets go of shift. Reading the
      state gives the same guarantee with none of the noise, and makes the player's sentence true.

      Two things must not be lost with it, both already written down: the chase may not end before
      it has been a threat (`PURSUIT_MIN_NOTICE` is the floor), and **walking away must never work
      at any distance** — the M36 trap, where a trigger sitting at the break-off distance let a rig
      stroll away from a robber every time
- [ ] **The tutorial dog is not a tutorial after day 3** — playtest 13, finding 8, *"I had a
      tutorial pursuing dog on day 4 — that should not happen"*. `charging_dog` is `first_day 3`
      with `spawn_mode = AHEAD_OF_PLAYER` and no last day, so the scheduler goes on placing it
      (three on day 4 of the trace) and the director goes on siting it in front of her, in the
      identical presentation to the day-3 lesson: `ahead charging_dog comes at her from 200px in
      front of her`. `_ensure_the_run_is_taught()` is correctly gated to `RUN_TAUGHT_DAY`; the row
      underneath it is gated to nothing.

      **Decided: it recurs, but is not sited ahead of her.** `AHEAD_OF_PLAYER` is for *"the small
      number whose entire content is the moment it happens to you"*, and after day 3 that is
      exactly what a charging dog stops being — the lesson is over and the row becomes a hazard
      with a place. `alley_robbery` is the shape: `pursues_within`, a thing that is *somewhere*,
      that can be seen and priced and routed around, and that becomes a chase if she walks up to
      it. Two constraints: a `MAP`-placed pursuer needs a `pursues_within` or it can never trigger
      at all, and `validate_pursuit`'s third clause puts that trigger inside `PURSUIT_BREAK_OFF`;
      and **day 3 keeps the placement it has**, because the lesson depends on being unavoidable
- [ ] **Dying at high excitement on a quiet street** — finding 8, and read the trace before touching
      anything.

      **Playtest 13's trace is that read, and the answer is the first of the three suspects: this
      finding *is* the crowd milestone.** The losing line is
      `lost_crying after 29.4s … exc 100, in 24.6/s (crowd 24.6, events 0.0)`, with the nearest
      catalogue row 272px away and out of range — playtest 10's own shape, one milestone later. It
      is **M46**, and this entry closes into it rather than being answered here. The other two
      suspects stay open and are cheap to check while M46 is being measured: whether the pram's
      `EXCITEMENT_NEARLY_CRYING` cue is shown and not read, and whether one contact at 90 is a
      cliff — at 22–34 points a second a single bump above ~89 ends the day on an empty street, and
      the trace has fifteen bumps in four days.

      What the entry said before the read, kept because the reasoning still holds and is now
      M46's: the strongest suspect is the **recovery**, and it is a rule taken on purpose —
      `EXCITEMENT_DECAY_IDLE` is 0.0, so above the calm threshold the only way down is walking
      somewhere quieter at 3.5/s — on a quiet street the meter sits where it is and any small source
      is a net climb with no floor under it. Three things to measure first: what the `lost` line's own
      `crowd X, events Y` breakdown says (if it reads like playtest 10's, this finding *is* the crowd
      milestone); whether the pram's `EXCITEMENT_NEARLY_CRYING` cue is being shown and not read; and
      whether **one contact at 90 is a cliff** — a pedestrian contact is ~10.8 points, so above 89 a
      single bump on an empty street ends the day. The first of the three is what the trace
      answered
- [x] **The diagonal zzz comes back down** — finding 9. `baby_cue_lift()` caught the diagonals
      because both cues asked *which axis is she mostly facing*, and that answer puts a diagonal on
      the vertical side of the line. It is one question now — `Stroller._pram_shares_her_column()`
      — and it is asked as **geometry**: `pram_offset` carries `facing.x` at full `PRAM_DISTANCE`,
      so the pram is 24px to one side on a diagonal and 34 on a due east or west, and only a due
      north or south leaves it in her column. That is six of the eight facings both cues have
      nothing to do on, where the axis test said four.

      It is a distance rather than `absf(facing.x) > absf(facing.y)` for a second reason worth
      keeping: `_turn_toward` rotates by an angle and normalises, so on a diagonal the two
      components are equal only to within float noise, and a strict comparison between them would
      have let the cue flicker between two positions while she walked in a straight line. This cue
      has been adjusted in M32, M37, M39 and now M43, and each of the last three was a facing the
      previous fix had not been asked about — so `tests/test_danger.gd` holds **all eight** now

### The two decisions this milestone could not take on its own

Both were taken in the session, and the first of them turned into a milestone of its own.

**~~What a closure is for.~~ Taken, and it is M45.** The measurement said no filter, margin or run
length can make a single closed street change a route, and the answer to that is not a better
closure — it is that *lengthening the route was never the job*. See **M45**.

**~~What notice a lethal thing owes when you walk into it.~~ Taken: site it at the screen edge.**
`SIGHT_AHEAD` rather than the 184px clamp, which buys 0.38s → 0.43s and is everything the geometry
has. The floor was deliberately left where it is; see the entry above for what that leaves open,
and the standing instruction that comes with it — a notice has to be **stated over the walk** and
asserted by a rig, or it will go on passing while the encounter changes underneath it.

## M44 — A suite you can run · `feature/a-suite-you-can-run`

**8.4 minutes to 96 seconds, with one check more than it started with.** The suite is the thing this
project checks most often, and at eight minutes it had stopped being run after each change and
started being run at the end — which tells you *that* something broke rather than *what*. M42's
larger lattice is what surfaced it: 7×7 to 9×9 took the suite from ~110s to 8.4 minutes, four times
the cost for 65% more city, and everything below was already there and already growing.

**The entry that asked for this proposed four things and every one of them was wrong**, which is the
part worth carrying. It guessed at cached maps, smaller seed sweeps, a fast/slow split and duplicated
per-day checks; the four suites it named as 90% of the cost were the right suites for the wrong
reason. Half an hour of a throwaway probe found something else entirely, and none of it cost a check.
**Time a thing before you speed it up** is a rule this project already applies to balance constants,
and it applies to its own tooling the same way.

- [x] **A rig that steps the parts is not running the whole** — 240 of the 495 seconds, inside a
      single test. `test_balance`'s day on the arterial walked the crowd by hand (`for agent in
      crowd.agents(): agent._process(step)`) and skipped the frame around them, so nothing ever
      rebuilt `TrafficIndex` — and `claim()` is written to be thrown away once a frame, so every
      recycle stayed. **64,796 cars in nineteen lanes after three thousand frames**, each one scanned
      six times per recycle, growing quadratically for the rest of the day. `Crowd.step()` is the
      whole frame and is what a rig calls now: 3.94 ms/frame at frame three thousand → **1.09**.

      **And it was not only slow, it was wrong**, which is why this is not a speed fix.
      `test_balance` and most of `test_crowd` were measuring a road with no separation pass on it
      while claiming to measure the real world. `tests/test_crowd.gd` now asserts the index holds
      exactly one entry per car, so the pathology cannot come back quietly — it never could have
      been seen otherwise, because a lane full of cars that left an hour ago is still a legal lane
- [x] **A cache whose lifetime is not stated is recomputed** — `EventScheduler._place_one` filtered
      every sidewalk tile in the city (five thousand of them, twice over) to find where an event may
      stand, and `_fill_with_recurring` asks that question **once per attempt** — over four hundred
      times on a fourteenth day. Nothing it depends on can move inside one `build_day`: the grid is
      repainted at dawn and the day's closures are already down. `_ground_for()` computes it once per
      distinct *question* — placement types plus side of the street, which most of the catalogue
      answers identically — threaded through the day rather than kept on the map, because a cache
      with a shorter life than its invalidation rule is the next bug. **`build_day` 515 → 71 ms**
- [x] **A `Vector2i`-keyed dictionary hashes a Variant per lookup** — `walk_distances` was the
      most-run arithmetic in the project (twice per generation attempt, once per day planned) and it
      asked a Dictionary about fifty thousand times what the tile grid answers by index.
      `CityMap.walk_field()` is the same sweep over a flat `PackedInt32Array`, with `blocked` painted
      into the grid before it starts rather than asked about per neighbour, and the four steps
      written out because the loop's own bounds test costs more than the arithmetic it guards.
      **16.3 → 4.5 ms.** `calm_tiles` and `count_walkable` lost their per-tile calls to the same
      pair of lookup tables — **8.9 → 0.6 ms**
- [x] **`CityGenerator.validate` does its cheap checks first** — it runs on every attempt, a third
      of them fail, and it opened with the two full sweeps of the map. A rejection that can be seen
      by counting calm blocks must not walk eleven thousand tiles twice first, and now does not walk
      them at all. Which reason comes back when several are true changes; whether a map is accepted
      does not. **`validate` on a map that passes 57.5 → 10.5 ms, and `generate` — 1.65 attempts of
      it, on average — 124.7 → 46.2 ms**
- [x] **`tools/test.sh crowd balance`** — the inner loop is now seconds. A filtered run prints
      `PARTIAL RUN` under its count, because a partial pass that reads like a green build is worse
      than no filter at all

| suite | before | after |
| --- | ---: | ---: |
| `test_balance.gd` | 255.1s | **25.6s** |
| `test_events.gd` | 74.6s | 12.7s |
| `test_crowd.gd` | 69.2s | 25.3s |
| `test_generator.gd` | 42.5s | 15.7s |
| `test_full_run.gd` | 18.8s | 4.4s |
| `test_telemetry.gd` | 12.6s | 2.1s |
| everything else, together | 22.2s | 10.3s |
| **whole suite** | **495s** | **96s** |

**What was deliberately not done.** No check was cut and no seed sweep shortened — every number
above is the same work done differently, which is why the count went *up* by one rather than down.
No map is cached across suites: a `CityMap` is mutable by design (a block arc repaints it, a day
closes streets on it) and sharing one between suites buys about seven seconds in exchange for a test
whose result depends on what ran before it. And `Crowd.step()` is the whole crowd frame minus the
player half — `_bump`, `_make_way`, `_strike`, `_horn` — which a rig with a stationary player would
also now be able to run. Whether `test_balance` *should* run it is a real question about what that
suite measures, and it is a design question rather than a speed one.

## M45 — A grid with fewer ways through, and closures that point · `feature/closures-that-point`

Not started. Taken as a design instruction in the M43 session, in answer to the measurement in
M43's closure entry above — read that first, because it is what makes this a milestone rather than
a tuning pass.

**The one sentence: a closure was being asked to lengthen a route, and lengthening a route is not
what it is for.** What it is for is *direction* — stopping a player from committing to a way that
cannot win today — and the reason it cannot even do that at the moment is that the city has no
shape to work with: 8 streets of 768 could lengthen the walk if closed alone, 11 of 534 four-street
runs, because a Manhattan lattice has many equal-length staircases and there are 8.9 calm areas
scattered across it.

The design, as given:

> *"In the beginning the player has a lot of freedom to find calm areas. As the game goes on the
> choices go down making it harder to find the calm areas. That causes an issue that later the
> player might walk into the wrong direction first making them not find the last remaining calm
> area in the time given. Closures can come in two ways: 1) a permanent restriction in the city's
> grid — we should have impassable blocks that are not technically a closure but just the city's
> layout, e.g. a cul-de-sac or a scrapyard, a city feature that naturally breaks up the grid; 2) an
> existing road gets closed later in the game for one or more days. 1) is to reduce the total
> number of valid paths making the graph less open. 2) is to guide the player to remaining calm
> zones — those closures should be placed to prevent the player from walking in a wrong,
> unwinnable direction. The goal is to guide/nudge the player to go into the right direction. This
> can be hard (full closure) or soft (multiple events forcing the player to turn around)."*

### The three parts

- [ ] **A city that is not a full grid, permanently.** Impassable blocks that are the *layout*
      rather than an event: a cul-de-sac, a scrapyard, a depot. They are what makes every route
      question downstream answerable at all — with a full lattice, no closure, cut or run of
      closures can change a route, which is measured rather than argued.

      **The mechanism already exists and should be reused rather than reinvented.** M21's calm
      zones absorb the streets between their own blocks: `CityMap.absent_segments` is the set of
      streets this city does not have, and `blocked_segments()` merges it with today's closures for
      **every** route search in the game. A permanent restriction is more absent segments plus
      ground that is not walkable — the same shape, decided at generation, fixed for the run.

      Four things it has to keep true, and each already has a test that will say so: route
      redundancy on day 0 (`StreetNetwork.route_count() >= 2` to two distinct calm areas — the
      thing M21 made true by search rather than by construction); no purpose change may move a
      walkable tile (`tests/test_blocks.gd`); the home's doorstep street stays reachable; and the
      crowd's lanes have to stop at whatever the new edge is, which is the M41 boundary problem one
      scale in — the lattice already ends in T-junctions at the map edge, and a cul-de-sac is that
      shape happening inside the city
- [ ] **A closure that points.** The acceptance test changes from *"does this lengthen the best
      route"*, which nothing can satisfy, to *"does this stop her committing to a direction that
      cannot win today"*. The information to do it already exists at dawn: `build_day` knows which
      calm areas are spoiled and `_ensure_one_usable_park` knows which one is protected, so the
      day knows which way is a wasted journey before the player takes a step.

      The trap to avoid, and it is the whole difficulty of this part: **a nudge that removes the
      decision is worse than a closure that does nothing.** The game's one verb is *where do I
      walk*; a day that fences her into the only right answer has taken the verb away. So this is a
      barrier on the way to somewhere unusable, not a corridor to somewhere usable, and the
      two-distinct-routes invariant stays exactly where it is
- [ ] **And a soft version, which is events rather than barriers.** *"Multiple events forcing the
      player to turn around."* The pieces are all there — `obstructs_radius` since M34, the spacing
      rules since M28, the density since M41 — and what is missing is the **intent**: nothing in
      `EventScheduler` has ever placed events in order to say *not this way*. Worth building second
      and measuring against the hard version, because a soft nudge she can push through is the one
      that keeps the decision hers

### The open question underneath it

**How fast should the choices narrow, and does `MIN_CALM_BLOCKS` survive it?** The narrowing is
half-built already and by a different mechanism: since M41 the park spoiler remembers **the whole
act** and resets when the act turns, so choice narrows within an act and is handed back at the
boundary. This design wants it to narrow across the *run*. `MIN_CALM_BLOCKS` is currently sized as
one per day of the longest act plus one, precisely so that the spoiler can never leave her with
nowhere to go — that sizing is playtest 12 finding 5 and it is the thing this would push against.
Decide it with a measurement, not an argument: the number that matters is how far the *last*
remaining calm area is from the door on the last day of an act, against the 180s she has.

**Absorbed into M47.** The two halves that are still open here — permanent restrictions and
closures that point — need the same machinery as playtest 13's bigger calm areas, and building
`absent_segments` twice is how the second one goes quietly wrong. The design above stands
unchanged and is the second half of M47; read it there.

## M46 — The crowd is not the game · `feature/the-crowd-is-not-the-game`

**Done.** Playtest 13's finding 1 — *"just walking around now increases excitement — this is
bad"* — which is playtest 07's finding 17 and playtest 10's *"the thing nobody reported"*, found
for the third time and said out loud for the first. See
**[docs/PLAYTEST-13.md](PLAYTEST-13.md)**.

**What it came to, in one paragraph.** Almost every item was answered by measuring rather than by
arguing, and four of them came back the opposite of what the item predicted. The crowd was not too
loud: an ordinary footway is **net recovery to walk**, and what is expensive is **standing**, which
is `EXCITEMENT_DECAY_IDLE` being 0 and stays that way for two measured reasons. The careful line was
not gone, it was **four pixels wide** — widened to twenty by moving the pavement's lanes apart, not
by shrinking the body — and that closed the separate problem that contacts and noise had been
pricing the same choice in opposite directions. The main road was quiet because a weighting could
not cross a split something upstream had already made, and it is a soft block now at about a third
of the meter to cross. And the green wave, which the docs had said served both directions since M41,
**serves one and arithmetically cannot serve two**. The population was honest, the box was not, and
the cost table did not move at all.

**The one sentence: the crowd is supplying almost all of the difficulty, and every authored system
in the game is being judged through it.** A day was lost in 29.4s reading `crowd 24.6, events
0.0`, with the nearest catalogue row out of range; the freeze threshold is reached within ten
seconds of the doorstep on **all five** attempts that got that far; and standing still for three
seconds on an ordinary pavement is worth eight points.

**What this must not become.** The noise floor is emergent, never a constant — that is an
invariant and it stays. *"The crowd is expensive to be careless in and free to be careful in"* is
the ratio the whole design rests on, and the finding is that **the careful line has stopped
existing**, not that the crowd is loud. M33 already measured the line away (eleven contacts down a
lane centre against one on the midline became thirteen against fifteen) and answered with a
behaviour — people step aside. Fifteen contacts in four days says the behaviour is not carrying it.

- [x] **Measure before touching anything, and measure the four things separately.** Playtest 04's
      recipe, re-run on `main`: contacts in forty seconds walked down a lane centre *against*
      forty seconds holding the midline, the mean crowd contribution at a standing point on
      ordinary / precinct / main-road pavement over a real minute, and the share of a losing day's
      excitement that came from the crowd. The ratio is the finding, not either number

      **Measured, and one of the four came back the opposite of what was feared.** Five seeds,
      act I, focused on the point being measured:

      | | value | against a 3.5/s walking decay |
      |---|---:|---|
      | ordinary corridors, standing | mean **5.82**, median 5.62 | **44 of 55 beat the decay** |
      | main road, standing | mean 11.90 | all five |
      | precinct, standing | 5.75 | net +0.50 after its 1.5x ground |
      | contacts, 40s down a lane centre | **73** | |
      | contacts, 40s on the midline | **5** | |

      So a typical ordinary street is **+2.1/s while walking and +5.8/s while standing** — 100
      points in 48 seconds of pavement with nothing authored anywhere near her, which is finding 1
      exactly. But **the careful line is not gone**: 73 against 5 is a ratio of **14.6:1**, better
      than the 11:1 M19 built the crowd on. `CLAUDE.md` has said since M33 that the ratio was
      measured away (13 against 15) and it is wrong — M41's crowd changes brought it back and
      nobody re-measured. **The finding is that the careful line is invisible, not that it is
      absent**: nothing tells a player that walking sixteen pixels to one side costs fourteen times
      less
- [x] **And the one test pinning the floor was measuring an empty street.** Found while measuring
      the above, and it is M44's lesson in the place it does the most damage.
      `_test_a_busy_street_never_lets_the_meter_fall` called `start_day(1, rng)` with **no focus**,
      which parks the crowd field on the map centre, and then measured at `quietest_pavement` —
      whichever north-south corridor the city made quietest, **1968px from that centre on seed
      4242**. Measured: **zero agents within 400px.** So *"a back street is somewhere she can
      recover"* was 0.00 against a decay of 3.50, and *"the arterial is a different place"* was
      7.58 against 0.00. **Three of that test's four checks were passing against a road with
      nobody on it**, and the fourth — the ceiling — was passing only because focusing the field
      is what pushes the arterial from 7.58 to 11.55, which is already over it.

      The crowd is a population of the box around the player, so **a floor is only a floor where
      she is standing**. `_floor_on()` focuses it
- [x] **The main road is the quietest thing in the city, and it is two defects** — finding 7's
      first half, done. `CrowdLanes.busyness` still weighted the middle corridor of *each* axis at
      `ARTERIAL_BUSYNESS` while `CityMap.main_road` is one vertical corridor, so the phantom
      east-west arterial held **14.6 cars against the spine's 11.2**. And underneath it,
      `_choose_lane` picked the axis 50/50 **before** the corridor, so no weight could ever put
      more than half the traffic on one north-south street.

      Both fixed: the spine holds **15.4 cars** and crossing it costs **~35 of the 100 meter**,
      worst of eight crossings — which is finding 7's *second* half arriving for free, because a
      third of the meter to cross is precisely the **soft block** that was asked for.

      Three things came with it. `CROWD_CARS_PER_ACT` went **40 → 34** (act II 30 → 26), because
      the concentrated spine put junction contention over the rate `test_crowd` allows: the car
      number is a capacity number now, and the honest answer to *"the main road is too quiet"* was
      fewer cars for the second time. The arterial ceiling is **stated over the crossing** rather
      than over the standing floor — a proxy that came apart the moment the spine got its traffic,
      and M35's *state it over the walk* arriving in the crowd's half of the game. And a car handed
      a corridor whose visible stretch is all precinct re-rolled its position eight times, found
      bollards every time, and was placed among them anyway: **a retry is not a guarantee, one
      scale out**, so `CrowdAgent.setup` re-picks the street rather than only the spot on it
- [x] **`EXCITEMENT_DECAY_IDLE` is 0.0 and there is no floor under her on ordinary ground.** M33
      set it there for a good reason — *what settles a baby is being pushed* — and the consequence
      nobody priced is that a stationary pram on a pavement is a pure climb at whatever the crowd
      is doing. Decide whether "standing still settles nothing" should mean "standing still is
      worse than walking", which is what it currently means.

      **Decided: it stays 0.0, and the question was pointing at the wrong number.** Two measured
      reasons, and the second is the one that was nearly missed.

      **It is not the lever for the case that matters.** The place the game *makes* her stand
      still is the kerb of the main road, waiting for the side street's green — and main-road
      ground is `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER`, 0.6. So even handing idle the whole
      walking rate would give back 2.1/s of a 5.9/s bill. The number that decides what a wait
      costs is the crowd's, not the decay's.

      **And removing the zero re-opens what it was built to close, by a route that is easy to
      miss.** Sleepiness is **frozen, not drained**, above `EXCITEMENT_CALM_THRESHOLD` — see
      `Baby._update_sleepiness` — and that is exactly the state somebody would stop in. So above
      the threshold standing still already costs nothing on the other meter, and any non-zero
      idle decay makes waiting it out strictly better than walking on every ground quieter than
      the decay: every back street and every park. `SLEEPINESS_DRAIN_IDLE` looks like the guard
      and is not, because it is switched off precisely when the exploit would be used.

      *Standing still is worse than walking* is the right sentence for a game whose only verb is
      *where do I walk*. What it must not be is the game's answer to something the game made her
      do, which is the next item
- [x] **Waiting for the main road's light costs a third of the meter, and up to all of it.**
      Found by measuring the item above rather than arguing it. Twenty arrivals spread across the
      cycle, at a signalled junction on the spine, five seeds:

      | | value |
      |---|---:|
      | cycle | 17.1s = 8.1 main green + 2.0 amber + **5.0 side green** + 2.0 amber |
      | mean wait for the crossing arm | **5.7s** |
      | worst wait | **12.0s** |
      | mean cost of the wait | **33.4** of a 100 meter |
      | worst cost of the wait | **133.0** |

      So obeying the light is worth a third of the day's tolerance on average and can end the day
      by itself, and this is *before* the crossing, which the item above measured at up to 35
      more. That is not a soft block, it is a toll gate with a queue, and she has no choice about
      any of it: `Tuning.validate_signals` guarantees she can only cross on the side green.

      **And the diagnosis it was written with is wrong, which the measuring found and the
      arguing did not.** The suspect was *what she is standing next to*: a queue held at the stop
      line is worth what the same cars are worth streaming past, because `contribution_at` never
      looks at how fast a car is going. But **she waits while the main road has green**. The
      traffic beside her is moving by construction, and the queue is on the side street she is
      not standing on.

      **What is actually expensive is standing, and it is not specially expensive here.** The
      spine's junction kerb reads **5.9/s** during a wait — an ordinary pavement reads 4.5–5.1.
      So this is the item above's other half arriving with a bill: `EXCITEMENT_DECAY_IDLE` is 0,
      any six-second stop anywhere costs a quarter of the meter, and the spine is the one place
      the game *makes* her take one.

      Three candidates, all measured, all rejected, because two of them buy the wait with the
      thing finding 7 just fixed and the third buys it with the road itself:

      | | wait | worst | arterial floor | jaywalk | spine stopped |
      |---|---:|---:|---:|---:|---:|
      | today | 33.9 | 133.0 | 11.98 | 26.1 | 41% |
      | a stopped car idles at 0.35 | 32.9 | 122.6 | **8.55** | **11.0** | 41% |
      | `CAR_OUTER_RADIUS` 104 → 64 | 23.2 | — | **7.62** | **11.0** | 41% |
      | side green 5.0 → 8.0 | **15.3** | **56.3** | 11.98 | 26.1 | **63%** |

      - **The idling fraction does nothing for the wait** — 33.9 to 32.9 — for the reason above,
        and its real effect is to halve the arterial floor and the cost of jaywalking. That is
        M41's *"a car waiting at a light beside you is louder for longer than one going past"*
        answered at last, and it turns out to be an answer to a different question.
      - **A narrower car field does not make a careful line**, which is the surprise. The profile
        across an ordinary footway stays flat at every radius tried — 3.31 / 3.74 / 3.39 at 64 —
        because **the flatness is the pedestrians**, who are 3.3 of the 4.5 and whose spacing is
        arithmetic no radius can change. All it buys is the same halving of the spine.
      - **A longer side green works and the road pays for it.** It halves the wait and the worst
        case, and it takes the spine from two fifths stopped to two thirds.

      So the mean is left alone on purpose: **33 points to cross the spine is the soft block
      finding 7 asked for**, and every lever that lowers it lowers the crossing with it. What is
      wrong is the *worst* case — 133 for one unlucky arrival, which she cannot see coming — and
      the thing underneath it is the next item
- [x] **The main road is two fifths stopped, and that is where its noise comes from.** Measured
      while pricing the wait, over three seeds and thirty seconds of act I: the cars on the spine
      average **49 px/s of a 158 cruise, with 41% of them stationary**. `CLAUDE.md` says to
      measure exactly this alongside the floor *"or a road that reads as busy in a screenshot is
      a car park in motion"*, and nobody had.

      **The diagnosis this item was written with is wrong, and measuring it found a five-milestone
      error in the design record.** It is worth reading as an example of how confident a wrong
      cause can sound: the drift argument below is arithmetically correct and explains nothing.

      **The speed spread is real and is not the mechanism.** `CAR_SPEED` is 130–185 against a wave
      tuned for 157.5, so a slow car does drift 0.6s per junction. But it needs **13 junctions** to
      drift out of an 8.07s green band and a car lives **3.8 junctions** on the spine before it
      recycles — and measured over three seeds, the **fast** half stopped more often than the slow
      half (4.25 against 3.00, 4.29 against 3.00, 2.44 against 2.38). Both proposed shapes — a car
      holding the progression speed, a narrower range on the spine — treat the drift, so both were
      dropped.

      **What is actually wrong is that the wave only ever served one direction.** M41's note said
      both did, "because the cycle is an even multiple of the junction-to-junction travelling
      time", and that is the condition upside down. With offsets `j·travel`, a car passing
      junctions `j0 + d·h` at `t0 + h·travel` sees phase `t0 + j0·travel + h·travel·(1 + d)`: going
      *with* the wave the `h` term vanishes and the phase never moves, going *against* it the phase
      advances `2·travel` per junction, which is constant only if the cycle **divides** `2·travel`
      — true at `blocks = 1` and nowhere else. Measured on the signals alone with no traffic in
      them, twenty departures spread across a cycle:

      | | arrivals meeting a green |
      |---|---:|
      | with the wave | **93%** |
      | against it | **51%** |

      and 51% is the main green's share of the cycle, which is to say chance. `tests/test_crowd.gd`
      had asserted `cycle / travel` is an even multiple since M41 — **true, and not the property
      the sentence beside it claimed**, so it pinned nothing. It walks a car down the platoon now.

      **It cannot be fixed, and that is a fact about the geometry rather than a setting.** A
      two-way wave needs `cycle = 2·travel` = 5.7s; the side green plus its two ambers is 9.0s
      before the main road gets a second, and widening `travel` instead means a spine cruise under
      100px/s, barely above a walk. No offset does better on average either: `θ = travel` buys one
      direction a perfect run and leaves the other at chance (72% overall), while the
      symmetric-looking `θ = cycle/2` puts **both** directions on a three-phase sweep at 47% each.
      The asymmetry is the good answer, not a compromise.

      **So the light is the floor and density is what sits on top of it.** Dropping
      `CROWD_CARS_PER_ACT[0]` to 12 for one probe — a third of the traffic — took the spine to 79
      px/s and 33% stopped, so density is worth about ten points and more than half the stops, and
      the irreducible remainder is the main arm being red 53% of the cycle. The cars stay: the same
      probe took the arterial floor 9.95 → 7.40 and the crossing 29.7 → 19.0, which is finding 7
      undone to answer finding 1.

      **What did move it is a snapshot being read as a fact.** `Crowd._can_clear_the_box` compared
      a static `gap_ahead` against the room a car needs beyond a junction, so a car queued behind a
      leader that was *already accelerating away* refused to enter, stopped, and made the jam the
      rule exists to prevent. Crediting the leader's speed for one `CAR_HEADWAY_TIME` — the horizon
      the car-following rule already trusts it for — is the whole change:

      | | before | after |
      |---|---:|---:|
      | mean speed on the spine | 44.6 px/s | **53.6** |
      | stationary at any instant | 43% | **39%** |
      | stops per car per life | 3.28 | **2.05** |
      | junctions crossed per life | 3.9 | **4.1** |
      | arterial floor | 9.95–13.17 | 9.17–11.09 |
      | worst crossing of the spine | 29.7 | **30.2** |

      So the road moves half again as fast for a third fewer stops, and the two numbers the
      previous items fought for — the floor and the ~33 points to cross — do not move. The noise
      floor did not have to be bought back with `CROWD_CARS_PER_ACT`, which the item expected it
      would.

      **The half that had to be walked back is the instructive one.** Crediting the leader's speed
      *unconditionally* put **238 overlapping crossing-axis pairs in 3,600 frames** against a
      tolerance of 180 — `tests/test_crowd.gd` caught it on the first run — because it let a car
      follow its leader straight *into* the box. The credit is only sound once the leader is past
      the far side, where its speed answers "will the last 66px have opened up by the time I get
      there", a question about road this car is not yet on. **Ask what the number you are
      crediting is a fact about**: a leader inside the box is the obstacle, not evidence about the
      road beyond it
- [x] **A contact is 22–34 points a second and there were fifteen of them in four days.** Either
      the cost or the frequency is wrong and the trace cannot say which. `BUMP_RADIUS` is 14 and
      the M33 note says the careful line was two pixels wide when M19 measured it — so widening
      the *street* rather than narrowing the *body* may be the honest answer, and that is a
      question for `CrowdLanes.SIDEWALK_OFFSETS` and `_make_way`

      **Neither is wrong, and the question was asking about the wrong axis: what is wrong is the
      *place*.** Measured over three seeds, forty-second walks, with the whole frame run — the
      crowd stepped **and** the player half of `Crowd._physics_process`, so `_make_way` is in it:

      | | value |
      |---|---:|
      | one contact | **10.8 points** — 18.0/s fading linearly over 1.2s |
      | contacts, 40s down an **ordinary** footway | 2.7, whichever line is taken |
      | contacts, 40s down an **arterial** lane centre | **15.3** |
      | the same, on the arterial midline | **0.0** |

      **The cost is right.** 10.8 is a tenth of the meter, and `tests/test_crowd.gd` already pins
      the shape it has to keep — one is survivable, four freeze the meter, ten lose the day. The
      *22–34 points a second* in the trace is the instantaneous rate with the field underneath it,
      not what a contact costs.

      **The frequency is right too, and an ordinary street turned out not to be the problem at
      all.** Every line across an ordinary footway is **net recovery** while walking: the crowd
      charges 55–87 points over forty seconds and the walking decay pays back 140, so the net runs
      −53 to −85 at every offset from the frontage to the kerb. That is worth holding against the
      standing numbers three items up — 5.82/s on the same ground — because the gap between them is
      the whole of `EXCITEMENT_DECAY_IDLE` being 0 and of `_make_way` only running for somebody who
      is moving. **Walking an ordinary pavement is free; standing on one is not.**

      **So the contact question is an arterial question, and there the careful line was four pixels
      wide.** A contact fires inside `BUMP_RADIUS` of a lane centre, the lanes sat a tile apart, and
      `TILE_SIZE − 2 × BUMP_RADIUS` is 32 − 28 = **4**. That is not a line a player can aim at, it
      is one she is occasionally on — with **165 points of a hundred** riding on it, which is the
      M46 headline (*the careful line is invisible*) arriving with a number and a cause.

      **Fixed by widening the street, which is what the item guessed and is the honest direction.**
      `CrowdLanes.SIDEWALK_LANE_SPREAD` pushes the two lanes of a footway 8px apart toward its own
      edges, so the clear line goes **4px → 20px** while the lanes stay 8px inside the pavement.
      Nothing about a contact changed: `BUMP_RADIUS` is what makes one mean *walking into
      somebody*, and narrowing it would have bought the same line by making a contact require a
      near-perfect overlap.

      | | before | after |
      |---|---:|---:|
      | clear line between two lanes | 4px | **20px** |
      | arterial lane centre, 40s | 13.7 contacts | 15.3 |
      | arterial midline, 40s | 0.0 | **0.0** |
      | field over 40s at an ordinary midline | 74 | **56** |

      Two things came with it. The careless line stayed careless, which it had to — the crowd is
      only a decision if walking down the middle of it still costs. And the field got **quieter in
      the middle of the pavement** as well, because the walkers are further from it, so for the
      first time the two halves of the crowd want the *same* line: the item below found them
      wanting opposite ones, and that is what this closes. `tests/test_crowd.gd` holds the band
      against `PLAYER_BODY_RADIUS` — it has to be aimable, not merely non-empty — and holds the
      spread under half a tile, because `CrowdAgent._pavement_band` measures the footway from the
      **tile** centres and nothing else in the suite would notice somebody walking in a shopfront.

      Open, and it is the half a geometry change cannot reach: **nothing yet says the channel is
      there.** It is now wide enough to find by walking down the middle of a pavement, which is
      what most people do — but that is a claim about a player and no rig can settle it
- [x] **`CROWD_PEDESTRIANS_PER_ACT[0]` is 200 and it is a population of the field, not the city.**
      It has not been re-measured since the field's box last moved. Measure what is actually
      within a screen of her, not what the constant says.

      **Taken out of order, and on purpose: the two decisions above cannot be made until it is
      known whether the population is the lever.** It is not, and that is the finding.

      Measured over five seeds, act I, thirty seconds standing on each of eight corridors:

      | | value |
      |---|---:|
      | walkers in the box, every sample | **200.0** of 200 |
      | cars in the box, every sample | **34.0** of 34 |
      | walkers on a 1280×720 screen | **67.6** |
      | cars on a 1280×720 screen | **10.2** |
      | walkers within 200px of her | 9.4 |

      So **the constant is honest**: the box is 1600×1600 and never spills, the screen is 36% of
      it, and 34% of the population is on it. Nothing is hiding. And it must not come down —
      the same population is what put 15.4 cars on the spine and made crossing it cost a third
      of the meter two items ago, so cutting it undoes finding 7 to answer finding 1.

      **What the measurement actually found is where the floor comes from, and it is geometry
      rather than population.** The floor across a footway, same five seeds, in lane units —
      0 is against the frontage, 1 is the kerb:

      | | frontage 0.0 | midline 0.5 | kerb 1.0 |
      |---|---:|---:|---:|
      | mean over 20 ordinary standing points | **4.30** | **4.96** | **4.76** |

      **It is flat, and the midline — the careful line — is the loudest of the three.** Both
      halves fall out of arithmetic that nobody has re-checked since the corridor was last
      resized:

      - **A car's field is 208px across and a corridor is 192px.** Every tile of both footways
        is inside `CAR_OUTER_RADIUS` of a carriageway lane — the frontage lane is 64px from the
        nearer one. There is no line on an ordinary street that is out of the traffic's earshot,
        which is why the profile barely tilts.
      - **A walker's field is 110px across and a footway is 64px.** Lanes are 32px apart and
        `PEDESTRIAN_INNER_RADIUS` is 22, so the midline is 16px from two lane centres and inside
        the **full-intensity core** of both. `Tuning.PEDESTRIAN_INTENSITY`'s own comment says
        *"walking wide of them does not [cost] — the pavement is two tiles, so how close to pass
        is a real choice"*, and there is nowhere on a footway to be wide.

      This is the M46 headline finding — *the careful line is invisible* — arriving with a
      cause, and the cause is not that nothing tells her about it. **The careful line exists for
      contacts and does not exist for the field**, and the two want opposite lines: the midline
      is the only line with no head-on contact on it (`BUMP_RADIUS` 14 against a 16px half-lane)
      and it is the worst line for the ambient noise. A player who finds one has found the other
      one's punishment.

      **Closed by the contact item above, and by one change rather than two.**
      `CrowdLanes.SIDEWALK_LANE_SPREAD` moves the two lanes of a footway 48px apart, which widens
      the contact-free line from 4px to 20px **and** puts the midline 24px from each walker —
      outside `PEDESTRIAN_INNER_RADIUS` rather than inside it. The ordinary midline's field falls
      74 → 56 per forty seconds. The two halves of the crowd want the same line now
- [x] **The crowd bunches against the boundary wall, where the comment says it thins.** Found
      while measuring the above. `CrowdField.corridor_range` clamps to the city and says so:
      *"that is also why the crowd thins out honestly in the corner of the map instead of
      bunching against the wall — there are simply fewer streets to put anybody on"*. The
      population does not clamp with it, so fewer streets and the same two hundred people is
      **more people per street**, which is the opposite of what the comment claims.

      Measured, five seeds, walkers on screen against how much of the box is inside the city:

      | corridor | box in city | walkers on screen | mean floor |
      |---|---:|---:|---:|
      | 0 (against the west wall) | 53% | 67.0 | **7.50** |
      | 1 | 81% | **78.3** | 7.90 |
      | 3, 6, 8 (ordinary, mid-map) | 100% | 66–70 | 3.91–5.89 |
      | 5 (the spine) | 100% | 69.9 | 11.58 |
      | 11 (against the east wall) | 59% | 55.3 | 6.80 |

      **The count on screen is flat while the city on screen is halved**, so the density per
      street at the wall is about double and the outer corridors read as **1.6× an ordinary
      middle one** — loud enough that on two of five seeds a corridor beside the wall beat the
      main road.

      **Fixed on the box rather than on the population, which is what made it nine lines.** The
      first design was the obvious one — fewer agents live where there is less street — and it
      is the wrong one twice over: it needs a live count that varies, and a live count that
      varies has to sleep somebody, which is *"nothing vanishes while you are looking at it"*
      asking for a whole waking-and-sleeping protocol that only ever runs off-screen. Instead
      `CrowdField` **grows the box near the wall** until the amount of *city* in it is what a box
      mid-map holds: `contains`, `along_bounds` and `corridor_range` all read `radius`, so every
      one of them follows, and no agent is created, destroyed or hidden. Growing is always the
      safe direction — the only floor under `CROWD_FIELD_RADIUS` is that nothing may be seen to
      appear.

      Solved by iterating rather than in closed form, and that was a decision: the exact answer
      is a quadratic whose terms depend on which of the four sides are against a wall **and**
      which of them clip while it grows, which is four cases to get wrong. Scaling by the square
      root of the shortfall lands within a pixel in three passes.

      | | before | after |
      |---|---:|---:|
      | radius against the west wall | 800 | **1108** |
      | walkers per screen of city, at the wall | **105** | **64** |
      | the same, three blocks in | 58 | 58 |
      | mean floor, outer corridors (5 seeds) | 7.50 / 6.80 | **3.12 / 4.52** |

      So the wall now reads as an ordinary street rather than as a busy one, and the two
      corridors against it come in slightly *under* an ordinary middle corridor — an error in the
      safe direction, and the honest reason is that keeping the box's **area** constant does not
      keep its split between north-south and east-west street length constant. Held by
      `tests/test_crowd.gd`, "the crowd does not bunch against the wall", as two checks rather
      than one: the geometry, which is the mechanism and is free, and the density, which is what
      the player feels and is the half that could pass while the other fails
- [x] **Re-measure the whole cost table afterwards** — `docs/EVENTS.md`, "What an event actually
      costs" — because if the crowd's share moves, every authored row's share moves with it, and
      the table is the fastest way to see what a balance change did to the catalogue

      **Regenerated from `EventDef.walk_through_cost()` and compared row for row: identical, all
      thirty-one of them.** That is the result rather than the absence of one — it says M46 was a
      milestone about the *street* and not about the catalogue, and it is worth doing precisely
      because nothing would have told us otherwise. Nothing in the milestone touched an intensity,
      a radius, `Tuning.falloff` or a decay.

      What moved is the ground the rows stand on, and `docs/EVENTS.md` carries it above the table
      now: an ordinary footway is **net recovery** to walk (55–87 points of crowd over forty
      seconds against a decay paying back 140), the middle of a pavement went 74 → 56, and
      crossing the main road costs ~30 with ~33 more for the wait — between a `dog_walker` and a
      `loose_dog`, and neither is in the table because neither is an event

## M47 — A city with places in it · `feature/a-city-with-places`

Not started. Playtest 13's finding 2 and the second half of finding 7, **plus the whole of M45**,
which is absorbed here because it is the same machinery. See **[docs/PLAYTEST-13.md](PLAYTEST-13.md)**
and the M45 entry above, which is still the design for the closure half.

**The one sentence: the count of calm areas is right and their density is not, and the answer is
area rather than count.** The city went 7×7 → 11×11 across M42 and M41 — 49 blocks to 121 — while
the calm areas stayed at eight. The equation playtest 12 asked to keep was about *count*; what a
player experiences is *density*, and the two came apart when the map grew.

The decision taken on the finding, quoted, because it is not what the analysis expected:

> *"make more calm areas take up multiple blocks — I said a long time ago that an inner courtyard
> (surrounded by buildings) should have a footprint of 2x2 blocks (apartment complex) — this never
> got implemented. not all calm areas have to take up multiple blocks but add more that do. also,
> add calm varieties that take up 2x1 non-square shapes"*

- [ ] **Calm ground is never at the edge of the map and never beside the main road** — the second
      lever on density, taken in the same session and **cheaper than everything below it**, because
      it is a placement rule rather than new geometry. *"Another way to get density is to make a
      rule to not have a calm area at the edge of the map or next to the main road."*

      **Today a single calm block has neither rule.** `_assign_purposes` constrains it three ways
      — unclaimed, no open-calm neighbour across a street, `_too_near_the_home` — so a quiet square
      can sit in the outermost block column against the boundary wall, or directly across the road
      from the spine. A 2×2 zone has half of one: `_zone_fits` refuses a footprint that would
      **absorb** a stretch of the arterial, which is about swallowing the street rather than about
      being beside it.

      **Measured on the lattice, for a single calm area, with the home clearance already applied:**

      | eligible blocks | count |
      |---|---:|
      | today (121 minus the 5×5 home clearance) | **96** |
      | + no calm in the outer ring of blocks | 56 |
      | + no calm in the two block-columns beside the spine | **48** |

      So it halves the field for the same 5–7 open calm areas, and **the count the player asked to
      keep does not move**. Two things about that table are worth carrying:

      - **The two halves are wildly unequal and the density argument is almost all the edge rule.**
        The outer ring is 40 blocks; the spine's two columns add only **8** on top, because the
        main road runs down the middle where `_too_near_the_home` has already taken a 5×5 out. So
        *"not beside the main road"* has to be justified on **design** rather than on density —
        where it is stronger: `decay_multiplier` is 0.6 on the spine, so a park you can hear it
        from is not calm ground, and if calm never sits beside it then **crossing it always leads
        somewhere worth crossing for**, which is what makes it a soft block rather than a wall.
      - **It recovers half the loss, not all of it.** At 7×7 the eligible field was ~24 blocks for
        the same 5–7 areas. This lever and the bigger calm areas below are complementary — one
        shrinks the field, the other enlarges each destination — and neither is sufficient alone.

      Three things to get right when building it. State both rules over a **footprint**, like
      `_too_near_the_home` and `_zone_fits` already do, so single blocks and zones obey one rule
      rather than two that drift. State the spine rule over **`map.main_road`**, never over
      `CrowdLanes.arterial_index` — `_zone_fits` currently uses the latter and so carries the same
      M41 defect as `CrowdLanes.busyness()` (see M46), protecting a horizontal arterial the city no
      longer has; adding a third copy of a fact that already has two, one of them wrong, is the
      `DangerEdge` mistake M37 found. And **decide courtyards separately**: a courtyard is *hidden*
      calm you have to know about, it is cut from `remaining` with only the neighbour rule on it,
      and an argument can be made either way for one against the boundary.

      Then **measure the room before committing**, because this is where it goes quietly wrong:
      48 blocks must hold 5–7 non-adjacent calm areas, 1–2 four-block zones needing a wholly
      unclaimed 2×2, and up to 3 courtyards — and `generate()` retries with `seed + 1`, so a rule
      that is too tight shows up as a slower generator rather than as an error.

      **The spine half is expendable and that is a decision, not a fallback.** *"The not next to
      main road rule is not that important, you can remove it if it loses too much freedom."* So
      the edge rule is the one that must land; if the measurement above says the field is too
      tight, the spine rule is what comes out, and it comes out **before** `MIN_CALM_BLOCKS` or the
      non-adjacency rule are touched — those two are what the player asked for by name
- [ ] **And no two calm areas are directly next to each other — including courtyards.** *"Also
      don't place calm areas directly next to each other."* Half of this is already true and half
      of it is a real gap, which is why it is its own item.

      `_has_open_calm_neighbour` tests `_OPEN_CALM` only — park, forest, quiet square — and
      `_cut_courtyards` runs **after** the open calm is placed. So a courtyard is correctly refused
      beside a park, and **two courtyards may sit directly across a street from each other**, with
      nothing in the generator able to see it: the open-calm pass cannot, because no courtyard
      exists yet, and the courtyard pass does not look for its own kind. The trace's day 1 planned
      **three** courtyards, so this is reachable rather than theoretical.

      Two things to decide while fixing it, and neither is obvious. **Whether a courtyard counts as
      calm for spreading purposes at all** — it is *hidden* calm, cut into a residential block, and
      the argument that two of them across a street are one awkward area is weaker than for two
      parks. And **whether diagonal counts**: `_has_open_calm_neighbour` walks the four edges and
      skips the corners, so two calm blocks meeting at a junction are legal today. That is
      probably right — they are a junction apart rather than a street apart — but it is currently
      an accident of the loop bounds rather than a decision, and it should become one either way
- [ ] **The 2×2 inner courtyard — an apartment complex.** Asked for *"a long time ago"* and never
      built. What exists is `COURTYARD_SIZE_TILES`, a 4-tile court carved inside **one**
      residential block. What is wanted is four blocks of buildings with a shared court in the
      middle of them, which is neither that nor M21's open four-block zone. **The mechanism is
      M21's** — absorb the streets between four blocks — with frontages around the outside
      instead of open ground, so it is a calm area you have to find a way *into*
- [ ] **Calm areas that are not square.** `CALM_ZONE_BLOCKS` is one integer and everything
      downstream is that integer squared — the tile rect, which segments are absorbed, which
      junctions survive. It becomes a `Vector2i`, and `CityMap.anchor_of()` and `lot_rect()` are
      where it is felt. A 2×1 is the case to build first because it is the one that breaks every
      piece of arithmetic that assumed a square
- [ ] **More of them are multi-block, and not all of them.** *"Not all calm areas have to take up
      multiple blocks but add more that do."* `MIN_CALM_ZONES` / `MAX_CALM_ZONES` are 1 and 2 and
      were sized for a 49-block city. Re-derive against 121, and keep single-block calm in the
      mix — *which* calm area to head for stays a real question only while a small quiet square
      close by competes with a big park further out
- [ ] **The main road as a soft block.** Finding 7's second half: *"think of the main road as a
      soft block to guide the player — they will avoid crossing it until it becomes necessary."*
      This is M45's *"a city that is not a full grid, permanently"* achieved without removing a
      walkable tile: the spine is already a line down the middle of the map with a hierarchy and a
      picture, and making it genuinely expensive to cross splits the city into two halves with a
      toll between them. **Build it before the cul-de-sacs**, because it costs no geometry and
      nothing downstream has to be re-proved
- [ ] **Then the rest of M45** — permanent impassable blocks, and closures placed to say *not this
      way today*. The design is in the M45 entry above and is unchanged. The trap it names is the
      one to keep in front of you: **a nudge that removes the decision is worse than a closure
      that does nothing**, because the game's one verb is *where do I walk*
- [ ] **Re-check `MIN_CALM_BLOCKS` and `MIN_HOME_TO_PARK_TILES` at the end, not the start.** Both
      are stated in a lattice that is about to change what a calm area *is*. `calm_areas_needed()`
      derives the floor from the act lengths and must go on doing so

## M48 — Things drawn where they stand · `feature/drawn-where-they-stand`

Not started. Playtest 13's finding 3 — *"random gray barriers placed half on the street and half
on the sidewalk — no clue what they are supposed to be but they raise excitement for some
reason?"* — which is `construction`, and which is wrong in three separate ways that are each a
rule rather than a row.

- [ ] **A body on a pavement has to fit on the pavement.** `construction` has `obstructs_radius
      34`, so `_draw_spread` draws it 68px wide; a sidewalk is `SIDEWALK_WIDTH * TILE_SIZE` = 64px
      and an event stands at a tile centre, 16px from one edge and 48px from the other. **It
      overhangs by 18px whichever lane it lands in.** This is M34's rule (*a body is half the
      silhouette*) meeting ground it was never checked against, and every `_draw_spread` row can
      break the same way — `market_stall`, `checkpoint`, `barricade`, `burnt_shell`,
      `cafe_tables`. It wants a test over the catalogue, in the shape of M34's own
- [ ] **A spread is always drawn east–west, whatever street it is on.** `_draw_spread` spreads
      along local x and nothing ever rotates an `EventInstance` — there is no orientation anywhere
      in the file. So the barrier that hangs into the carriageway on a north–south street lies
      *along* the kerb on an east–west one, parallel to the traffic, blocking a pavement it is not
      across. **A barrier's entire content is which way it faces**
- [ ] **And it does not say what it is.** The sprite is blue-grey (`#6b7a8c`, `#4e5a68`) with no
      hazard marking on it. M37's rule — one picture per row, no two rows sharing one — passes
      here and the row still says nothing, which is the rule's own limit: *how dangerous a thing
      is has to be visible from looking at the thing*, and municipal barriers are red-and-white
      for exactly that reason

## M49 — A city that says what it is · `feature/run-and-it-backs-off`

Playtest 14, taken **before** M47 because four of its six are small and two of them are things a
player has now asked for twice. See **[docs/PLAYTEST-14.md](PLAYTEST-14.md)**.

**The one sentence: nothing here is about balance — five of the six are the city failing to say
what it is**, and the sixth is a mechanic that was answering a question about geometry when the
player was asking one about themselves.

**Merged to `main` unfinished, deliberately, and this is the third time** — see M43 and M47. What
is merged is the first round of playtest 14, finished and green: the dog, the border built to its
brief, the moving spine, calm areas that are not diagonal, and calm areas she has not visited
staying clean. What is **not** started is the whole second round, recorded below under *"Recorded
and not started"* — the traffic lights, the calm-ground multipliers, the fence drawn from the
camera's angle, and the four faults on the borders.

The reason to merge rather than hold: the first round contains the process fix in `CLAUDE.md` and
the design record in `docs/CITY.md`, and both of those are rules the *next* piece of work has to be
done under. A branch is the wrong place for a rule about how to work. The rest of M49 continues on
a branch of its own.

- [x] **The pursuing dog does not stop.** *"It's a very simple rule — when I run the dog backs down
      almost immediately."* Third report of this encounter. `PURSUIT_SHAKEN_OFF` counted seconds of
      the **gap opening**, and a run opens it at 38px/s against the day-3 dog — a fifth of a pixel
      a frame — so a corner, a kerb, a pedestrian or the 0.37s about-turn reset the timer and the
      dog chased somebody who was visibly sprinting. Confirmed off a trace first: `run  ran 1.3s,
      exc 57 -> 98`, escaped and lost the day doing it.

      It is a fact about **her** now. Measured with a rig that accelerates: **0.35s of running for
      5 points**, against 1.2s for 17 — which is also the answer to *"or make running less
      costly"*, without moving `EXCITEMENT_FROM_RUNNING`, which is the whole of why running is
      wrong against everything that does not follow her. The contract is untouched: it rests on
      the speed clauses, so walking still cannot end a chase and running always can
- [x] **The border is just black.** M41 built the ring of frontages and opened the camera onto it
      and neither put anything on the floor out there. Each outside tile clamps to the nearest tile
      *in* the map and takes its picture, so the edge continues outward and the spine's four exits
      get their road for free. `CityMap` is untouched — this paints the tilemap only
- [x] **The main road is always in the same place.** It was the middle corridor on **every seed
      ever generated**. Rolled from the city's street stream now, three corridors clear of either
      boundary so both halves are worth being in. Four places still derived it from the constant —
      the M46 defect exactly, *a fact about a city answered from an axis length*
- [ ] **Junctions are four-way where an arm dead-ends.** **Not reproduced.** Two candidates checked
      and correct: an absorbed street's T-junctions already carry no crossing on the missing arm
      (measured, two seeds), and a boundary junction's outward crossing is right rather than wrong
      — it is how somebody on the outer pavement gets over the road she is meeting. It read as a
      dead end because there was nothing beyond it, which is the item above and is fixed. **Needs a
      location from the player**, or a third candidate
- [ ] **Courtyards are still one block.** Asked for twice now. This is the M47 entry *"The 2×2
      inner courtyard — an apartment complex"* unchanged: M21's mechanism — absorb the streets
      between four blocks — with frontages around the outside instead of open ground, so it is a
      calm area you have to find a way **into**. The largest remaining piece of M47
- [x] **The 0.2s window at the lunge — offered and declined.** *"The pursuing dog is fixed now,
      the additional change you suggested is not needed."* The measured gap is real and stays
      recorded on `Tuning.pursuit_standoff`; what it no longer carries is a claim that anybody
      wants it closed. **Do not reopen without a player asking**
- [x] **The border, as briefed rather than as complained about.** Specific tiles per side: south a
      bulkhead then water and **no buildings**, east and west a fence then grass then forest, north
      scree then mountainside. The only things that cross are the **tunnel** — the carriageway
      carries on and darkens a step per tile until it is gone — and the **bridge**. M41's east and
      west road exits are deleted with it: they made sense as gaps in a ring of frontages and make
      none in a wood, and they were never on a main road anyway
- [x] **The fence is rotated the wrong way.** It is drawn running north-south now, the axis it is
      used on, and symmetric about its own centre line so one tile serves both sides
- [x] **Calm areas must not be diagonal from each other either.** *"We said they should not be next
      to each other — this includes the entire surrounding."* `_has_open_calm_neighbour` walked the
      four edges and skipped the corners, so two could meet at a crossroads. It is the whole ring
      now. This closes the M47 open question that called the diagonal case *"an accident of the
      loop bounds rather than a decision"*
- [ ] **A calm area she has never visited was already spoiled, and that can end a run a day
      early.** The most serious finding here, because it is an unwinnable-day bug. `MIN_CALM_BLOCKS`
      is derived as *an act's worth plus one* on the assumption that only **going** to an area
      burns it — which is what `_spoil_the_parks_she_used` does. But `_ensure_one_usable_park`
      protects exactly **one**, and ordinary placement can drop a busker or a market stall into any
      of the rest, so the pool falls below the derivation through no decision she made.

      **Make the guarantee match the derivation: every calm area she has not used this act stays
      clean.** Spoiling stays the answer to *returning* and nothing else. Then check what it costs
      the catalogue — parks are one of the few places several rows can go
- [ ] **Nothing guides her toward the calm, and hard/soft diversions were summarised away on day
      one.** *"I still don't feel the game guiding me to calm zones via obstacles — also tell me you
      have a note about hard and soft diversions."* The current logic is stated in `docs/CITY.md`,
      "Guiding her to the calm": the city **permits** routes to calm and **protects** them from
      becoming impossible, and never suggests one — closures are drawn at random from whatever
      keeps the two-routes invariant, so one is as likely to be behind her as across her route.

      **The design has now been given in full and is written up in `docs/CITY.md`, "Diversions —
      the design". Read it there rather than here.** In one paragraph: hard and soft mean
      **permanent** and **per-day**, not severity; hard blockers are pruned lattice edges
      (cul-de-sacs, big buildings) and soft ones are the day's placements (closures, fallen tree,
      restaurants); soft splits into **lethal**, **mild/benign**, and **road closures**, which are
      not lethal but prevent full access. **Hard and lethal form the paths; benign go on the path.**
      The main road paces the run — she exhausts her own side before she is forced across. Sealing
      a section is fine, because there is no calm in it.

      **Presentation is not the problem and must not be touched.** *"How they are presented is
      already solved. The issue is that they are not placed properly."*

      **And nothing in the invariants forbids it** — checked rather than assumed.
      `_park_is_reachable` requires **one** reachable calm area, not a connected city, so a sealed
      quarter is already legal; `ClosurePlanner`'s two-routes rule is about reaching calm, not
      about connectivity. This is a **placement** milestone end to end: no new blocker kinds, no
      new cues, no change to what a closure is.

      **All five opening questions are answered** and the answers are in `docs/CITY.md`, "How the
      corridor is built": the target is **every available calm area**, one **corridor** each, and
      the day's plan is a **tree** rooted at the doorstep; overlaps are wanted, and a **chokepoint**
      is a guaranteed placement; there is **no budget**, only the tree, and **placeholders** that
      resolve when she arrives; one-shots **bind late**. What is left is the build, in this order:

      1. **Hard blockers do not exist and have to be built first.** *"Cul-de-sacs and big buildings
         don't exist yet — but we need them to implement proper hard blockers."* This is the only
         piece that is **once per run** rather than per day, everything else is placed relative to
         what it leaves, and it has to work for every calm area the run will ever use. It is a
         `CityGenerator` change and it is the gate on the rest
      2. **The tree**, per day: doorstep to every available calm area, corridors and chokepoints
         computed and available to whatever places things
      3. **Placement by role** against the tree — walls out of hard blockers and lethal rows,
         friction inside the corridors, set pieces on candidate sets that every corridor touches
      4. **Placeholders**, so nothing is spent on ground she never reaches
      5. **The two invariant decisions** in `docs/CITY.md` — edge-disjointness versus chokepoints,
         and late binding versus the retried day. Neither is a coding problem and both block 3
- [ ] **Restate the main-road pacing question, which was not understood.** *(Asked badly the first
      time: "what paces the main-road crossing?")* What is meant: the design says she takes routes
      on **her side** of the spine until they are exhausted and is only then forced across. The
      question is **what makes that happen** — is it simply that calm areas exist on both sides and
      `_spoil_the_parks_she_used` burns the near ones over an act, so the far side becomes the only
      thing left? Or does something have to actively withhold the far side early on, and steer her
      across late? The first needs no new code and falls out of what exists; the second is a
      mechanism nobody has designed. **The answer decides whether the arc is emergent or authored**
- [ ] **Day 3 carries act I's whole payload, and the run lesson is the thing it crowds out.**
      *(Raised by the player: "does the fire truck conflict with the run tutorial? Should we move
      the run tutorial one day earlier to disentangle?")* **It conflicts, and it is three rows
      rather than two.** Everything in act I that is not day 1 or 2 arrives at once on day 3:

      | row | what it is | |
      |---|---|---|
      | `fire_truck` | `first_day = 3, last_day = 3` — the **only one-shot in act I**, and a set piece | mobile 190px/s, 340px radius, leaves a `burning_building` for the rest of the day |
      | `charging_dog` | `first_day = RUN_TAUGHT_DAY` — **the run lesson** | `hard_fail`, `AHEAD_OF_PLAYER`, pursues |
      | `reversing_lorry` | new that day as well | `hard_fail` |

      So the last day of act I introduces **two new lethal rows and the only set piece**, on the
      day it also teaches a key the game has spent two days punishing. And the two headline
      encounters teach **opposite answers**: the dog is the one thing in the game running beats,
      the fire engine is a thing to be off the road for. A player who learns "run" from day 3 has
      learnt it next to the one row where it is least relevant.

      **Day 2 is not empty, and the premise for moving there was that it is.** *("Day 2 might be a
      good option since it doesn't introduce anything else I think?")* Measured off the catalogue,
      **day 2 is the busiest introduction day in act I**: `busker`, `construction`, `cyclist` and
      `ice_cream_van` — four rows, and `cyclist` is **lethal**. Day 3 introduces three. So moving
      the lesson to day 2 does not give it a quiet day; it gives it a day with four other new
      things and an existing lethal row on it.

      That does not sink the move — **the argument was never about counts**. It is that day 3's two
      headline rows teach opposite answers, and that a set piece needs room. But it changes what
      the options are, so all three are worth having:

      | | | |
      |---|---|---|
      | **A. run lesson → day 2** | act I reads walk → run → set piece | day 2 gains a 5th new row and a 2nd lethal one; `cyclist` already teaches *fast things kill* |
      | **B. `reversing_lorry` → day 4** | day 3 keeps the lesson and the set piece, minus one lethal row | the two opposite lessons still share a day |
      | **C. `fire_truck` → day 2** | day 3 becomes purely the run lesson; the set piece gets its own day | act I loses its day-3 finale, which is where a one-shot naturally wants to be |

      **Decided: A.** *("Let's do A", 2026-08-31, taken with the corrected premise in front of
      it — day 2 is the busiest day in act I, not an empty one.)* It is the only option that
      separates the two opposite lessons *and* leaves the set piece where a finale belongs, and
      `cyclist` on day 2 is arguably the right neighbour for a running lesson rather than the wrong
      one. **Not implemented** — the change is `Tuning.RUN_TAUGHT_DAY` 3 → 2 plus the docs that
      state it, and it is the one code change queued out of this whole conversation.

      Three things to check rather than assume when it is made, because this is the most-reported
      encounter in the project and playtest 08 explicitly liked where it sits (*"I like the running
      tutorial on day 3"*):
      - `RUN_TAUGHT_DAY` gates **everything that pursues**, so moving it moves the robber's first
        possible day too — check act I is not made harder by a constant that was only meant to move
        a tutorial
      - `charging_dog` is `first_day = RUN_TAUGHT_DAY` **by reference**, so it follows for free;
        `reversing_lorry` is a literal `3` and would then be the only new lethal row on day 3
      - the day-2 difficulty was tuned without a `hard_fail` row on it

      And `docs/MECHANICS.md`, `docs/EVENTS.md` and `CLAUDE.md` all state *"day 1 teaches the arrow
      keys and day 3 teaches the run"* in prose. All three move with the constant, in the same
      commit, or the docs start lying about the day the game teaches its second verb

### Recorded and not started — the second round of playtest 14

Written down before anything is built, on the player's instruction (*"write those down — no fixes
yet"*) and under the `CLAUDE.md` rule the first round produced.

- [ ] **Traffic lights stand against the building instead of the kerb.** *"The traffic lights go to
      the side of the road not the building — they always stay close to the road."* A head belongs
      on the carriageway side of the footway and should stay there whatever the pavement is doing.
      M41 built them on the principle that *where it stands is what says which road it is talking
      about*, so a head against a shopfront has stopped pointing at anything
- [ ] **Calm ground is worth more, and a small calm area worth more still.** *"x1.5 the sleepiness
      effect of calm zones and double it for 1x1 calm zones."*
      `Tuning.SLEEPINESS_CALM_ZONE_MULTIPLIER` is 12. **Two readings, and they differ for the
      multi-block case** — (A) 18 for a zone and 24 for a single block, or (B) 18 and 36. A unless
      corrected. The design is the good part either way: a four-block zone is more than one lap
      wide and a single block is not, so the small ones have always been the weaker choice for
      reasons unrelated to what they are for. Re-check `docs/MECHANICS.md`'s "more than one lap"
      margin afterwards — M38's entry warns this is the constant that decides whether a day is
      winnable once the park is reached
- [ ] **The fence is drawn in elevation and turned on its side.** *"It just looks like a fence from
      the front but rotated sideways, which doesn't make sense."* Both attempts have been a side
      view — palings with a rail across them. The game looks straight down, where a fence is a thin
      line with post-heads and a shadow. Rotating an elevation does not make it a top-down drawing
- [ ] **The eastern border, four faults in one screenshot.**
      `run-2026-08-30T233248-seed3225216943-834423d-dirty-069s-asked.png`, seed 3225216943, day 2,
      tile (152,103):
      **a)** a calm area sits directly against the border, although M47 shipped *"calm ground is
      never at the edge"* — check `_zone_fits` and the single-block calm placement separately,
      they are different code paths;
      **b)** a road runs into the border and stops in the grass instead of teeing into the boundary
      corridor;
      **c)** people walk out onto the border as if it were pavement and vanish there — *"nobody
      should be walking there since it is not a walkable area, they need to turn like the cars on a
      t-junction"*, and the player is right: **`CrowdAgent._blocked_ahead` returns `false` for a
      tile out of bounds**, so the one wall that should stop them is the one it reports as clear.
      Every agent already runs the divert (`_process` calls it for walkers and cars alike), so the
      fix is likely to be *out of bounds is blocked* and nothing else — which would take **b)**
      with it. Check it against the **spine exits**, which are the one place a car is meant to
      leave the map. The first note here blamed M46 growing the crowd's box; that is how far they
      get, not why they are out there;
      **d)** the fence again
- [ ] **The same faults on the north and south borders.** *"Same issue with other borders."*
      Whatever fixes the east has to be stated over **a border** rather than over one side of the
      map: the first border pass wrote four sides four times, which is one bug per side waiting to
      happen, and this is it happening

## M50 — The city points somewhere · `feature/the-city-points-somewhere`

**The plan for the diversion design.** The design itself is `docs/CITY.md`, "Diversions — the
design"; this is only *how*. Nothing here is started.

**The one sentence: the corridor already exists in the code and nothing is allowed to see it.**
`ClosurePlanner._streets_on_a_route` computes, today, the set of streets on a near-shortest way
from the door to some calm ground — distances from home, distances to each calm area's access
streets, and a street counts if the best route through it is within `CLOSURE_ROUTE_SLACK` of the
best route overall. **That is a corridor.** It is private, it is thrown away every time it is
computed, it is unioned across all calm areas so the individual paths are lost, and the only thing
it is used for is weighting *which street to close*. So this milestone is much less about inventing
a structure than about **promoting one that is already there** and letting everything place against
it.

And one thing found by reading it, now decided: **closures are currently biased
`CLOSURE_ROUTE_BIAS = 5.0` toward streets that are on a route, and that flips.** *"A road block
becomes guidance and is not a hindrance. It flips its role."* Today a closure is placed where it
will be **met**, which degrades the good ways; under the design it is a **wall**, placed off the
tree to prune the ways that lead nowhere she should go. The purpose changes with it: a closure
used to exist to make a route harder, and now exists to make a route **obvious**.

Two consequences worth having in mind while building, because they run opposite ways. Closures stop
being a threat to winnability almost by construction — a wall sited off the tree cannot cut the
tree — which takes pressure off the two-routes check from the closure side. And the old sanity rule
inverts: *"a closure nobody would have walked is pointless"* was right when a closure was an
obstacle, and is exactly backwards for one that is a signpost.

### Step 0 — the tree, and it is a tree on purpose

**A tree, not a bundle of shortest paths.** *"Don't take the strictly shortest path. Aim for paths
that share prefixes. The paths to some calm zones might not be optimal or short but that is
okay."* This is the instruction that decides the whole structure, and it is why the day's plan was
called a **tree** from the first sentence of the design rather than a set of routes.

`_streets_on_a_route` is exactly the wrong primitive for it: it keeps every street within
`CLOSURE_ROUTE_SLACK` of the **best route to that area**, computed per area and then unioned — which
is the definition of *independent* shortest paths. Run it on a day with five calm areas and you get
five rays fanning out of the doorstep sharing almost nothing, which is a star, and a star has no
bundles, no chokepoints, and a fan-out equal to the number of destinations. Everything the placement
depends on comes from the sharing.

**The construction is probes and colours, grown from the calm areas back toward the door.**
*(The player's algorithm. It replaces a greedy Steiner attachment proposed here first, which was
worse: it needed a global cost function, it made the trunk point at whatever calm happened to be
nearest home on every seed, and it had nothing to say about the second route.)*

- [x] **Two probes at each calm area, walking in random directions.** Not one probe from home —
      the growth runs **backwards**, from every destination toward the doorstep, and the trunk is
      what is left where they have all come together
- [x] **A path carries the colour of its origin**, and both probes from one calm area carry the
      same colour
- [x] **Same colours may not merge.** The two probes from one area can never become one path, so
      where a second route exists at all the area is reached **two genuinely distinct ways**. It is
      an offer rather than a guarantee — see below
- [x] **Different colours merge, and the colours add up.** A probe that touches a differently
      coloured path joins it, and the joined path carries the **union** of both colour sets. Which
      is the elegant half: once the `A`+`B` path exists, `A`'s other probe is locked out of it by
      the rule above, so the guarantee maintains itself as the tree grows and nothing has to police
      it
- [x] **"Touch" means *merge*, not *be near*.** Non-mergeable paths may run **directly adjacent** —
      *"the player can walk the beginning of path A and then switch to path B without noticing"*,
      and that is fine, because both go to the same place. Optionally they can be separated with a
      road block, *"but that is not a hard requirement"*. So the constraint is on the graph, never
      on spacing, and any implementation that enforces a distance between paths has misread it

**The five details, answered:**

1. **A probe stops on either** — reaching the doorstep, or merging. A probe that gets home unmerged
   is a direct route and is finished.
2. **A step is a segment on the `StreetNetwork` junction graph.** Not tiles: a corridor is a set of
   segment keys everywhere else in this design, and tile-walking would produce something no other
   part can consume.
3. **Loop-erased random walk.** Wilson's algorithm — walk randomly, delete loops as they close —
   rather than a drift toward home. It is the standard tool for exactly this shape and it gives
   variety without wandering.
4. **Probes go out sequentially, and the second one is optional.** *"No swapping — if we send out
   the probes sequentially we can check if there is another path left, via a shortest path
   algorithm that avoids path A. Having two distinct paths is really a niceness to the user. If we
   cannot construct a path B at all, let's not try."* So: grow probe 1, then ask whether a route to
   that area exists **avoiding probe 1's segments**. If it does, that is probe 2. If it does not,
   the area has one way in and the day is fine.
5. **Hard blockers are placed against a tree, not before one.** *"First construct an example tree
   from the initial map, then place the hard blockers — that way we can't block off regions
   entirely. Then when a day starts we construct a tree for real."* So generation runs: lay the
   city → grow a **reference tree** → place hard blockers that leave it intact → and only then does
   each day grow its own tree on what is left.

### Dropping the swap removes every hard case at once

The swap was proposed to rescue a probe that could not merge, and it carried three problems: it
could ping-pong with no decreasing quantity so nothing guaranteed termination; it was undefined
against a **merged** path, where re-designating a tail carrying `{A, B, C}` would silently re-route
`B` and `C` and could collapse *their* second routes; and it could not fix a pocket anyway. **All
three are gone** — sequential probes with an existence check have no collision to resolve, so there
is nothing to ping-pong, nothing to re-designate, and a pocket is simply an area with one way in.

**What it costs is a guarantee, and that is a deliberate trade.** *"Having two distinct paths is
really a niceness to the user."* So a second route is an **offer the day makes when the map allows
it**, not a promise. This is the right way round — the alternative was a construction bending
itself to preserve a property nobody had asked to be absolute — but it has to be taken with the
consequence below open-eyed, not discovered later.

**The consequence: winnability loses one of its two protections.** `MIN_CALM_AREAS_WITH_TWO_ROUTES`
existed so that no single closure could cut every route to the calm. Under this design that
protection comes instead from **where a wall is placed** — off the tree, by construction — so the
redundancy is no longer the backstop, the placement is. That is coherent, and it means one bug in
wall placement is now the whole distance between a normal day and an unwinnable one. *(Taken
2026-08-31: the constant is `MIN_CALM_AREAS_REACHABLE` and asks for reachability. The count of
areas deliberately stayed at two — see "The two invariant decisions" below.)*

- [x] **Keep a reachability check as the last line.** `_ensure_the_city_is_still_walkable` /
      `_park_is_reachable` already asks only that *some* calm area is reachable, which is exactly
      the weakened guarantee and costs one BFS. **It was not deleted when
      `MIN_CALM_AREAS_WITH_TWO_ROUTES` went** *(2026-08-31)*, and neither was the closure planner's
      own check — it asks for reachability now instead of for two routes. Two independent
      mechanisms rather than one, cheaply, which is the difference between a placement bug being a
      bad day and being an unwinnable one

**And this makes step 1's gate much weaker, which is a gift.** *(Taken 2026-08-31.)* Hard blockers
no longer have to leave two edge-disjoint routes to every calm area — only **reachability**.
Cul-de-sacs and dead ends were always the point of hard blockers and the old gate fought them; a
`route_count >= 2` requirement would have refused most of the interesting ones.
`CityGenerator._the_calm_survives` uses `route_count >= 1` now, over every calm area rather than
over a count, because a hard blocker holds for the whole run: a day can be bad, a run cannot be
dead.

**Decided: B is the shortest remaining path.** The same computation that answers *does a second
route exist* also is the route — no second walk.

The reason is not simplicity, and it is worth keeping because it points the other way from the
usual instinct: **a shorter B puts less of the map in play.** *"The shortest path also reduces the
overall number of available blocks, which makes the area more approachable — the player feels less
lost."* A wandering B would be more interesting per street and would spread the day's ground over
more of the city, and being spread thin is the thing that reads as *lost*. The tree is a way of
saying *here is where today happens*, and a tight second route says it more clearly than a scenic
one.

**The known risk, recorded rather than designed away: B may run alongside A.** A shortest path
avoiding A's segments is often the next street over. That is **not a correctness problem** — the
design already blesses it explicitly, *"non-mergeable paths can be directly adjacent… the player
can walk the beginning of path A and then switch to path B without noticing"* — so what is at
stake is only whether the pair **reads** as two options or as one thick one. A map question, for
the first day this can be drawn, and the answer if it reads badly is a separating road block, which
the design already offers as optional
- [x] **`RouteTree`, in `src/routes/`.** Built from `map`, the day's closed set and the available
      calm areas. It holds, per calm area, the **branch** that reaches it; over the whole day, the
      **bundles** — edges carried by two or more branches — and the **fan-out**, meaning the
      smallest set of sites touching every route, which is what a set piece needs
- [x] **Leave `_streets_on_a_route` alone for now.** It is not `RouteTree`'s constructor and
      swapping it would change what closures do as a side effect of a refactor. `RouteTree` lands
      beside it; the two converge in step 2, where what a closure is *for* is being decided anyway.
      `StreetNetwork.junction_distances` is the piece that genuinely is shared

**Built, and here is what it came out as.** `src/routes/route_tree.gd` and
`tests/test_route_tree.gd`, measured with a throwaway probe over 32 planned days (8 seeds × days
1, 5, 9, 14) and deleted before committing, per the rule in `CLAUDE.md`:

| | |
|---|---|
| calm areas per day / branches grown | 7.6 / 7.5 |
| areas offered a second route | **241 of 241** that the map allowed one to |
| streets on the tree per day | 68.9, of which **50% carry more than one area** |
| probe 1 length vs the shortest way | **13.2 streets vs 4.4** |
| probe 2 length | 6.6 streets |
| fan-out | 2–6 sites against ~15 routes |

Three things in it are worth carrying, and the first two are corrections to what was written here
before anything was built.

**The fan-out covers *routes*, not branches — and covering branches is the design's own warning
arriving through the back door.** The item above said "touching every branch", which reads as the
obvious meaning of *"make sure all routes touch at least one of them"* and is not it: a branch
counts as covered when **either** of its routes is, and measured that way nine days out of 32 came
back with a **single** street. That street is on route one of every area and route two of none, so
a fire engine placed there is met by a player who takes the first way out of everywhere and missed
entirely by one who takes the second. It is *"the tile she must cross"* — which this design names
as its first draft's mistake — restated as a bug. Covering routes gets the right answer for
nothing, because the two routes of one area share no street by construction, so **no single site
can ever cover both** and the *"at least two places"* arithmetic falls out rather than being
enforced.

**A tail is everything hanging off a stretch, not the stretch that was just walked.** The
same-colour rule is enforced by asking whether a junction's way home already carries this area's
colour, and the first version marked only the junctions the probe had walked. That under-reports
transitively — a junction upstream of a merge keeps a tail that does not mention the colour — so
an area's second probe merged at it and then ran straight back down into the streets its first
probe had spent. **The two routes shared ground while every explicit check in the construction
said they could not.** `RouteTree._resettle_the_tails` recomputes the lot from the doorstep
outwards after each adoption, which is O(the tree) a dozen times a day and is the version whose
correctness can be read off the definition.

**And one measurement is a question rather than a result: probe 1 is three times the shortest
way.** 13.2 streets against 4.4, and the corridor is about a quarter of the lattice. That is not
a bug — *"the paths to some calm zones might not be optimal or short but that is okay"* is
explicit, and detail 3's random walk is what produces the variety the design wants. But detail 3
also claims Wilson's *"gives variety without wandering"*, and on a 12×12 junction graph it
measurably wanders; and the reason given for making probe **B** the shortest — *"reduces the
overall number of available blocks, which makes the area more approachable — the player feels less
lost"* — is an argument that points the same way at probe A. **This is a question for the player
and not a number to quietly bias**, and the map picture below is what it should be asked against.

**Asked, and decided 2026-08-31: leave it.** *"Let's try it like this for now and keep the other
options as potential improvements in the future if playtesting shows issues with the design."* So
the wander ships, and the two answers that were on the table are recorded here rather than
discarded.

**What they are not is pre-approved, and the earlier wording of this paragraph implied they were.**
*(2026-08-31, the player: "I want to make very clear that saying 'I'm feeling lost' is not an
endorsement of those ideas and doesn't count as approval. The most it does is bringing those items
back to discussion.")* It said the thing that would make one of them right is a playtest sentence
about feeling lost — which reads as a **trigger**: hear the sentence, apply the fix. It is not one.
A complaint says the design has a problem; it says nothing about which of these two is the answer,
or whether the answer is either of them. **A parked option comes back as a question, never as a
plan.** The same holds for every other option parked anywhere in this file against a future
sentence:

- **Cap the wander, keep the walk.** Re-roll a probe whose route exceeds some multiple of the
  shortest way. One constant, still deterministic, and detail 3 stays literally true — it is still
  a loop-erased random walk, it is just rejected when it rambles. The first thing to reach for.
- **Bias the walk toward home.** Weight each step by whether it closes the distance. Tighter, and
  it is the *"drift toward home"* detail 3 rules out by name, so it would be an overturn rather
  than a tuning. Only if the tight map turns out to be worth more than the variety.

**And the knob this creates has to be watched, because it cuts against winnability.** Sharing is
what makes placement cheap, and it is also what makes **one closure decide the day** — a trunk that
every branch runs up is a bridge, and cutting it takes all the calm with it. The design already
bounds this: *"you have to account for things to be potentially in one of two places at the very
least, in the ideal case where there are exactly two distinct paths."* So the rule is **maximise
sharing subject to at least two genuinely distinct paths surviving**, and the tree is never allowed
to become a single trunk. That is the same quantity as the invariant decision below, approached
from the other side, and the two should be settled together

### Step 1 — hard blockers exist *(once per run, and it gates everything)*

*"Cul-de-sacs and big buildings don't exist yet — but we need them to implement proper hard
blockers."*

- [x] **A cul-de-sac is an `absent_segment` with a dead end at one end.** The mechanism is already
      built and proven: M21's calm zones absorb the streets between their blocks, `absent_segments`
      is the set of lattice edges this city does not have, and `blocked_segments()` merges it with
      the day's closures. What is new is **choosing** them for a reason rather than as a
      side effect of a zone. Note the M21 rule that comes with it: an absorbed street is still
      *ground* — so a cul-de-sac must be a street that genuinely stops, not a park to walk through
- [x] **A big building is a block whose lot is solid**, removing the streets around it from the
      lattice. This is a `BlockPurpose` and an arc, per the "Add a block purpose" recipe
- [x] **They are placed against a tree, not before one**, in `CityGenerator`, from the city RNG —
      so they hold still for the whole run and are what the player learns. Grow a **reference
      tree** on the finished lattice first, then place blockers that leave it intact, *"that way we
      can't block off regions entirely"*. The gate is **reachability**, for every calm area the run
      will ever use including act IV ones — not two routes, which a cul-de-sac would fail by
      definition. The reference tree is the readable sanity check beside it, not the check itself
- [x] **`CityGenerator.validate()` gains the new condition** and it runs on every seed, like the
      rest. `tests/test_blocks.gd` already asserts the walkable set is identical tile-for-tile
      across every block arc — hard blockers must not move a walkable tile after generation

**Dead ends are built. What they came out as, and the three things worth carrying:**

**The gate stayed the strong one while dead ends were built, and the plan above is why that needed
a decision.** *"The gate is reachability — not two routes, which a cul-de-sac would fail by
definition"* is written just above, and it is a **weakening of a guarantee three other things rest
on**: `MIN_CALM_AREAS_WITH_TWO_ROUTES`, `ClosurePlanner`'s day-level invariant, and
`tests/test_routes.gd`'s *"an open city has two routes to everywhere calm"* all assumed the
generator hands them a city where it holds. Taking that as a **side effect of adding dead ends**
is the exact shape of overturn `CLAUDE.md` has a rule about, so the gate kept demanding two routes
until the invariant itself was restated — which happened on 2026-08-31 and is where the gate moved
with it. And the fear turned out to be unfounded either way: with candidates already off the
reference tree, **99% of them pass either gate**, and a city gets **5.9 dead ends against a rolled
4–8**.

**A dead end is a claim on the lattice paid for on the tiles, and calm ground beside one breaks
it.** Found by building it: `tests/test_routes.gd` failed with *"the way in (5, 11, 0) is a real
street"*, because a dead end had been placed on one of a four-block zone's eight ways in. The
graph said the street was gone; the player walks on tiles, and a street with a park down one side
is one you walk into and step **sideways** out of. It is M21's *"an absorbed street is calm ground,
not a closure"* read backwards, and the fix is a candidate filter: nothing beside calm.

**And `absent_segments` stopped being the zone set, which broke a test's sentence rather than its
assertion.** `tests/test_generator.gd` asserted *"no zone swallowed a stretch of the arterial"*
over every absent segment, which was the same set right up until dead ends joined it.
`CityMap.dead_ends` is the split, and it is worth having for its own sake — the two are absent for
opposite reasons and the telemetry map needs to draw them differently. The general shape is one
this project already has a name for: **an identity standing in for the property.**

**The picture had to be fixed too**, and that is a note about tooling rather than about walls: the
first version left a dead end showing through as ordinary building, which is a dark slab inside a
dark street and is invisible. A hard blocker nobody can find in the one picture built to check
placements might as well not have been placed. It has its own colour now.

**Big buildings are built too, and the interesting part is what they exposed rather than what they
are.** One or two per city: **two neighbouring blocks joined into one mass**, twenty-two tiles
long, with the one street between them built over and every other street around them left alone.
Chosen late and converted rather than assigned with the other purposes, because the choice needs
the reference tree, the tree needs the calm areas and those need the block layouts — by the time it
can be decided the blocks have already been carved. Three things came out of it:

- **The first version took the whole ring, and the player corrected it.** *(2026-08-31: "why do big
  buildings close off four streets each? a big building just connects two blocks… we can add a
  building type with all four roads closed but that's a different building type. but I want one
  that just connects two blocks (closes one road)".)* A block with all four of its streets built
  over is an **island in the lattice** — one roll of the dice removing four streets — where what
  was asked for is a landmark that removes one. The four-sided kind is recorded below as a type of
  its own and is not built.
- **A candidate list is a snapshot; a placement is a change.** The pool was enumerated once and
  the first big building's streets were news to the second one's check, so two of them shared a
  street and drew two buildings on the same tiles. It is re-checked at placement now. The same
  shape as M38's *"two placements in the same frame cannot see each other"*, one scale out.
- **And a density floor failed for a reason that had nothing to do with hard blockers.** Day 1
  planned 93 events against a floor of 96 on two seeds of eight, and the cause was neither lost
  ground nor the walkability cull (which drops nothing): it was
  `EventScheduler._ensure_one_usable_park` **stripping twenty-one events** — the spoilers of every
  calm area she has not used, removed *after* the fill has spent its budget. So the day plans to
  target and then falls short of it, and the budget has never accounted for the strip. `69 → 76`
  per block, agreed with the player, puts a typical day 1 at **121–125 placed — which is the
  stated one-per-block target it had been sitting 12 under** — and the worst seed at 102. It
  lifts days 1–7 and leaves day 14 alone, because day 14 is bound by the catalogue's caps rather
  than by the budget.

**And a defect was found on the way past it that is not M50's to fix.**
`_ensure_one_usable_park` returns early if **any** calm area happens to come out clean — and the
rule written underneath that early return is playtest 14's, *"every calm area she has not used
this act stays clean, not just one of them"*. So the newer, stronger guarantee only fires on days
where the older one already failed, which is a coin flip: on seed 4242 it strips 21 events and on
seed 90210 it strips none. That is the **old rule silently defeating the new one written under
it**, and it is why the density shortfall looked like a hard-blocker problem — a big building
moves enough placements to tip the coin. Worth its own item; see "Open design questions".

- [ ] **A building type that closes all four of its streets.** *(2026-08-31, recorded rather than
      built: "we can add a building type with all four roads closed but that's a different building
      type".)* It is what the first version of the big building accidentally was, and the code for
      it is in this branch's history — a block whose lot is solid with its whole ring taken and the
      four corner junctions kept. What makes it a different type rather than a bigger one is what
      it does to the lattice: a landmark that joins two blocks removes one street and leaves the
      grid around it, and this removes four and makes an island. So it needs its own name, its own
      count, and its own answer to *how many of these can a city take before the corridor has
      nowhere to run* — none of which the two-block one has to answer

### Step 2 — placement by role

- [x] **`EventScheduler.build_day` takes the `RouteTree`.** The phase list stays and gains the tree
      as an input; each placement phase gets a **role** and asks the tree a different question —
      walls for segments just *outside* a corridor, friction for segments *inside* one, set pieces
      for a covering set. Keep `_stream(base, salt)` per phase; a phase whose consumption changes
      needs its own stream, which is M39's rule and this changes several

      **Built, and the role turned out to be a property of the *row* rather than of the phase.**
      The item above says "each placement phase gets a role", and written that way it is wrong in
      the one case that matters: the recurring fill is a single phase and it places both the walls
      and the friction, because what decides which a thing is is whether it ends the day.
      `EventScheduler._role_for` is four lines and no row in the catalogue carries a role field.
      *(The phase salts did not have to move for the same reason — no phase changed how much it
      draws, only which tiles the array it draws from contains.)*

      Four things worth carrying:

      - **The mechanism is the precinct weight, not a new one.** A tile is offered to the roll
        several times over, so the roll, the spacing and the room measurement all keep working
        unchanged and nothing new can refuse a placement. **One thing is a rule and not a weight**
        — a wall is never inside the corridor — and that one is safe to state absolutely only
        because the rest of the city stays available to it.
      - **`Corridor` is the translation, and it had to exist.** `RouteTree` is segment keys and a
        placement is a **tile**, and sixteen rows of the catalogue stand on alley, park, square or
        courtyard ground where `segment_containing` returns null. A classification written over
        segments alone would have made `alley_robbery` unplaceable while the whole suite passed. A
        block interior answers for the four streets around it; a junction for the streets that meet
        at it.
      - **Measured, and the two numbers that had to *not* move did not.** Placed per day is
        identical (111 / 145 / 175 / 201 over six seeds), and so is the count of lethal rows —
        which was the real risk, since a `hard_fail` placement must clear its whole outer radius of
        everything else with no fallback, and refusing it a quarter of the city could have quietly
        stopped placing it. What moved is where: costly rows on the corridor 34% → 64% on day 1,
        lethal rows on the rim 63% → 80% on day 5. The table is in `docs/EVENTS.md`.
      - **And it cost the suite time, which is worth writing down because the first version cost
        twice as much.** Every `build_day` now grows a tree, and `tests/test_events.gd` plans a lot
        of days. The first version also keyed the *whole ground scan* by role, so two passes over
        every sidewalk in the city ran three times a day instead of once — 44s → 88s. The role only
        ever re-weights tiles the scan already accepted, so it is a second pass over a list already
        in memory (`_open_ground_for`), and `Corridor` caches its answer per lattice cell rather
        than allocating an array per tile. 88 → 68s, of which about ten is the new test itself
- [x] **`ClosurePlanner` places closures as walls, off the tree.** `CLOSURE_ROUTE_BIAS` inverts:
      the weight goes to segments that are *not* on a branch, and preferentially to those leading
      away from calm. Keep the `_invariant_holds` check on each candidate — a wall off the tree
      should never fail it, so a failure means the tree and the wall disagree about where she is
      going, which is worth an assertion rather than a silent skip

      **Built, and it was taken first rather than second.** The bullet above it needs the tree
      threaded from `City` into the scheduler, and doing that while closures were still biased
      *onto* the corridor would have left a commit in which friction is aimed at a route that a
      closure is aimed at cutting. The order is one commit's worth of difference and the transient
      is the kind of thing that gets shipped.

      Three things came out of it:

      - **The tree is excluded rather than weighted against, and that is what the rest of the
        milestone rests on.** A wall across the route is not a worse wall, it is the opposite of
        one — so `City.start_day` grows the corridor *before* the closures and every street on it
        is refused, which is what makes it still walkable when the barriers go up. It is also why
        `RouteTree.for_day` stopped taking the day's closures: a tree grown against them would be
        grown against decisions taken by consulting it.
      - **The rim is the unit both halves of step 2 needed**, and it is one method. `RouteTree.rim()`
        is the off-tree streets meeting an on-tree one at a junction, which is exactly *the turning
        she can see from the corridor*. A wall further out is legal and bounds less; a wall in the
        far corner of the map is the scenery the old bias existed to avoid, so the constant
        survived the inversion at the same strength with a different thing to measure against.
      - **The assertion asked for is a test rather than an `assert`.** A failing `assert` aborts a
        headless suite, which in this project prints nothing at all and looks exactly like a hang
        (`CLAUDE.md`). So the planner writes a `plan` line and skips, and `tests/test_routes.gd`
        proves the branch is dead by trying **every** off-corridor street of every day on four
        seeds rather than the one or two a day happens to reach.

      And one defect the first version of the test had, which is the same shape as several already
      in this file: it grew its own tree to check the planner's answer against, and grew it
      **before** `map.repaint(state)`. Which blocks are calm is what a tree grows from, so it was
      comparing against a corridor for yesterday's city — 26 failures that were all the test being
      wrong. A tree is a fact about a *repainted* map, and nothing in the type says so
- [x] **Set pieces get a covering set.** Candidate sites such that every corridor touches at least
      one — *not* a single site on her chosen route. `fire_truck` first, then the resistance
      note's alley. **A bundle is not a guarantee**: two distinct paths means at least two sites,
      and any code that assumes one is wrong

      **Built for the catalogue's one-shots, which is `fire_truck` and nothing else.** The day
      plans the row at **every** site and the placements share a `set_piece_group`; the first one
      to enter the world spends the rest, in `EventManager._stream_in`. That hook is where an
      event becomes real — it is where the scar is recorded and the block moves along its arc — so
      the alternatives have to stop being possible on the same frame rather than when it finishes.

      **The resistance note's alley is not done**, and it is deliberately left: `ResistanceDirector`
      places a contact rather than an event, on its own schedule and with its own expiry, so it is
      a second caller of this idea rather than a second row of the same one. It is written down as
      a to-do below rather than folded in silently.

      What it moved that was not obvious: **three counts came apart that used to be one.**
      `max_per_day` is a cap on *instances*, and the number of offers is not one — so a one-shot is
      exempt from the cap assertion in `tests/test_events.gd` and the real count moved to
      `tests/test_event_manager.gd`, where an instance actually exists. And *"the retry has one
      fewer of a spent one-shot"* became *"none"*, because the whole group goes with it. Both
      tests failed on the first run and both were the test being narrower than the sentence it
      was written from.

      **And a third thing it broke, which took a second commit and is the one worth reading.** With
      the offers spacing the rest of the day around all of them, *"a retried day is the same day"*
      stopped being true — the day after a set piece fires has two to six long routes' worth of
      ground freed rather than one, so the fill lands differently: `leaf_blower` seven to five and
      eight kinds moving, on seed 4242. It surfaced a commit late and by luck, because the calm-area
      fix below changed which city seed 4242 generates; the suite had been green on the old one.

      Two answers were tried and the first was wrong in an instructive way. **Placing the set piece
      after the fill** makes the fill identical by construction — and it cannot find its own sites:
      a fire engine's route is 1920px long and `_room_around` refuses anything within 64px of
      anything, so on a map with 120 events already on it every candidate on every covering site is
      illegal and only the fallback places. The rule that shipped is the other one: **an offer takes
      up no room**, because it is not in the world and only one of the group ever will be. That
      makes the fill *identical* between attempts rather than merely close, which is stronger than
      M39 could promise with a single one-shot — and it is the direction step 3 is going anyway,
      *"budget is not really used up if the player doesn't see it."*

- [ ] **Off the corridor is not merely unweighted, it is closed.** *(2026-08-31, and it is the
      player's own sentence: "also make sure that areas that outside the paths should have blocking
      events all over — we don't want the player to step in those areas and it ranges from very
      costly to deadly.")*

      **This is a stronger instruction than what step 2 built, and the difference is the point.**
      What shipped weights walls onto the **rim** — the off-tree streets meeting an on-tree one at a
      junction, *the turning she can see from the corridor* — and leaves everything beyond the rim
      to whatever the fill happens to drop there. Measured, that put lethal rows on the rim 63% →
      80% on day 5, which is a bias. The sentence above is not a bias: **the ground off the paths is
      somewhere she must not go**, and it is priced so, from *very costly* at the edge to *deadly*
      further in.

      Recorded before it is built, with the two things it collides with named rather than resolved,
      because both are invariants somebody would have to move on purpose:

      - **A lethal row has to keep its whole `outer_radius` clear of every other event, with no
        fallback** — M28's rule, and the reason it exists is that the telegraph contract is stated
        per event while the player experiences the sum. "Deadly all over" and "nothing else happens
        inside a lethal event's field" are in direct tension, and the second one is what stops an
        abduction being walked into out of somebody else's field.
      - **The catalogue has few lethal rows and they have caps.** Saturating the off-corridor
        ground is a question about `max_per_day` and about how many silhouettes exist before it is
        a question about placement, which is `CLAUDE.md`'s *"a budget the catalogue cannot spend is
        not density"* arriving at the other end of the map.

      And one question that has to go back, because both answers are defensible and only the player
      knows which was wanted: **what is the gradient over?** Distance from the corridor is the
      obvious reading — the rim is very costly and the deep interior is deadly — but *"we don't want
      the player to step in those areas"* would also be served by a hard edge, and the two make very
      different cities to walk into by accident

- [ ] **The resistance note's alley is a set piece too.** *(Split out of the item above rather
      than left implied.)* `ResistanceDirector` chooses where a chalk mark goes, and it has exactly
      the fire engine's problem — an authored thing placed somewhere she may never walk, with a
      run's good ending resting on it. What makes it a separate item rather than the same one is
      that a contact is not an `EventScheduler.Planned`: it has its own schedule, its own expiry
      and no streaming, so the mutual-exclusion mechanism above does not simply apply to it

### Step 3 — placeholders

**What the budget is for was misread here, and the player corrected it before anything was
built.** *(2026-08-31: "I think you are misunderstanding the role of budget. It is to provide
variety in encounters and make sure to not spam the same event over and over again. The amount of
placeholders is almost one per block sometimes multiple per block.")*

The misreading is worth keeping because it is what the three bullets below were about to be built
from. This side read the budget as a **density cap** — a pot of ground the day is allowed to
occupy — and from there the quote *"budget is not really used up if the player doesn't see it"*
can only mean *charge the pot late so the far side of the city is free*, which is order-dependent,
empties out a day the longer she walks, and contradicts the third bullet. The whole question that
went back to the player was built on that reading, and it was the wrong question.

**The budget is a variety ledger.** The count of *sites* is the density and it is roughly one per
block; the budget, the `max_per_day` caps and the weighted pick decide **what fills them**, so that
what she meets is a city rather than nine dog walkers. Which makes the quote mean something quite
different and quite simple: **variety should be measured over the encounters that happen, not over
the whole map.** Fix all ~121 rows at dawn and the twenty she actually walks past can be nine dog
walkers by chance, with the catalogue's caps perfectly satisfied across a city she never saw.

So a placeholder is a **site with a pool**, not an absence:

- [ ] **A `Planned` carries a pool of interchangeable rows**, chosen at dawn, and resolves to one
      of them when she comes within `EVENT_STREAM_RADIUS` — which is already the "she is about to
      be able to see this" boundary. It keeps a **provisional** `def` from the moment it is
      planned, so the day is fully legal at dawn exactly as it is today: every guarantee, every
      spacing rule and both culls run against a concrete row and none of them has to learn about
      pools. Resolution may only *swap* within the pool
- [ ] **The pool is what is interchangeable at that site**, and it is built from what already
      decides placements: the same **role** (so a wall never resolves to friction and the lethal
      spacing rule cannot be broken after the fact), ground that includes the tile, and the same
      `spawn_mode`. The chosen row is re-checked against the day's room and spacing before it is
      taken, which is the same check the provisional row passed — and the provisional row is the
      fallback, so a resolution can never fail
- [ ] **The caps become caps on what she meets.** Resolution prefers a row she has met least today,
      which is the whole of *"do not spam the same event over and over again"*, and a row already
      at its `max_per_day` **in encounters** is not offered
- [ ] **Resolution draws from the placeholder's own stream** — `_stream(base, salt)` keyed by the
      placeholder's identity, never from a stream shared with the rest of the day. Otherwise where
      she walked moves everything planned after it, which is M39's defect with a longer fuse
- [ ] **The test's sentence has to move with the correction, and this is the half that changes.**
      It read *"resolve every placeholder and require the result to match planning it with the
      player walking a different way"*, and under a variety ledger that is false by design: the
      ledger is consumed by encounters, so two walks legitimately meet different rows. What must be
      identical is **the offer** — the sites, the roles, the pools, the paths — which is the M39
      property and the one `docs/CITY.md` states: *"determinism is a property of the offer, never
      of what she did with it."* So: plan a day, walk it two ways, require the plan identical
      placement for placement and require both walks to respect the caps

### The two invariant decisions, which blocked step 2 — both taken 2026-08-31

**And the first of them should never have been a question.** *"I already clarified that the two
routes guarantee is not a hard rule — is that not in your notes?"* It was: step 0 above says *"a
second route is an offer, not a promise"* and *"what it costs is a guarantee, and that is a
deliberate trade"*, `RouteTree`'s own class comment says it, and `docs/CITY.md` carries the
player's *"having two distinct paths is really a niceness to the user"* and *"sealing off a
section of the map is allowed, and it is the point."* The decision was recorded correctly and
then re-opened from this stale heading, which is a smaller version of the failure `CLAUDE.md`'s
overturn rule is about: **a decision that is written down in one place and contradicted by a
to-do list in another is a decision that will be asked again.**

- [x] **Restate the two-routes guarantee.** Done. `MIN_CALM_AREAS_WITH_TWO_ROUTES` is
      `MIN_CALM_AREAS_REACHABLE`, the day-level check asks for one path rather than two, and the
      generator gate is reachability — which is what M50 step 1 deliberately left alone until
      somebody moved it on purpose.

      Two things were kept rather than swept along with it, because the weakening had to be
      deliberate on both sides. **The count of areas did not move**: two, because one of them may
      be the one the day just spoiled, and one reachable area is the unwinnable day the constant
      has existed to prevent since M16. And **the sentence edge-disjointness was standing in for
      is now asserted directly** — by Menger it meant *no single street is a cut*, so
      `tests/test_routes.gd` says that about the **city** rather than about each area: no one
      street cuts off all the calm. The per-area version is false by construction now, because a
      dead end is allowed to take one of an area's ways in
- [x] **`_ensure_one_usable_park` versus the tree.** Answered from the other end on 2026-08-31 and
      it never needed the tree: the guarantee is stated over **where she has been**, not over where
      today's corridor goes, and it is enforced at placement now rather than by a strip. See the
      closed item under "Open design questions"

### What this does not touch

Presentation, in any form. *"How they are presented is already solved. The issue is that they are
not placed properly."* No new cue, no new silhouette, no change to what a closure is, no change to
`City.total_excitement_at`. If this milestone finds itself drawing something, it has gone wrong.

## M51 — The city draws what it means · `feature/draws-what-it-means`

Playtest 15, in full in **[docs/PLAYTEST-15.md](PLAYTEST-15.md)**. Seven findings, and they split
into three that are the city lying about its own rules, two about the frame around the game, one
art bug and one report the player is not certain of.

**Nothing here is a balance change**, which is worth saying up front: every one of them is a place
where what is drawn and what is true have come apart, and the fix is to make the drawing agree
rather than to move a number.

- [x] **A cul-de-sac stops the crowd too** — finding 1, *"cars and people go through
      cul-de-sacs"*. Dead ends are `absent_segments`, which every route search takes through
      `CityMap.blocked_segments()`; the crowd is the one thing that travels the lattice without
      asking. Be precise about what is being fixed: a car that drives *down* a dead end and turns
      round is right, a car that drives out of the end that was built over is not, and neither is
      one that never diverts because the street it is aiming at is gone from the graph but not
      from its own view of the map. `CrowdAgent._divert` and `CrowdLanes` are where to look, and
      M38's rule applies — *a placement is not a separation* — so a recycled car must not be
      **placed** on a street that is not there either

      **And the answer was none of the things above.** The crowd never needed `blocked_segments()`:
      a dead end is a street with its far end **built over**, so the tiles already say so, and
      `_blocked_ahead` already reads tiles. What it could not do was *see* the wall. It was a
      single probe fired seven tiles ahead — right for *is there something coming up*, and it looks
      straight **past** a two-tile plug into the open road behind it. An agent that entered the
      street from the junction beside the wall therefore never saw it at all. **M29's invariant
      exactly**, in the one scan it had not reached: *sampling a tile grid by stepping world points
      aliases, and it aliases where it matters.*

      Four things worth carrying:

      - **The rig had to stand in the right place before it could see anything.** The first probe
        built the crowd field at the doorstep and reported **zero** agents in a wall on three
        seeds. The crowd is a population of the box around the player, so a dead end the box never
        contains is a wall nothing was ever going to reach. Standing the field at a dead end gave
        850 / 2091 / 821 frames of 2400 with somebody inside one, and 8 at once. A clean
        measurement of the wrong place looks exactly like a clean build.
      - **Walking the tiles is *cheaper* than the probe, once it is cached by tile.** The answer
        depends on the agent's tile, its axis and its direction, over a map that is fixed for the
        day, and an agent covers a tile in about twenty frames — so seven lookups per tile beats
        one probe per frame. `test_crowd` went 48.7s → 42.4s and `test_balance` 37.9 → 27.2 while
        gaining a correctness fix. The intermediate version, which added the near check *beside*
        the probe rather than replacing both, cost +28%.
      - **A car that turns round changes lane.** `_direction = -_direction` on its own left it
        driving the wrong way down its own queue, and `space_out_the_traffic` then had to resolve
        a head-on overlap the only way it can — by moving a body. `_turn_round()` is the one place
        that now happens.
      - **And a test that had been true by luck for eleven milestones failed for a reason that had
        nothing to do with this.** *"No car is standing in a precinct"* asked `street_kind_at`
        about the **precinct's** axis, and a precinct span covers the junctions between its blocks
        — so a car crossing it on a north-south street is legal and was being counted. Sixteen do
        in the forty-five seconds that test runs; the assertion passed only because none of them
        was inside a junction on the frame it sampled, and a few frames of timing change broke it.
        It asks whether the car is on ground **no** axis lets it drive on now
- [x] **The main road has dotted lines, not a zebra** — finding 2, and the design half outranks
      the art half. *"The main road shouldn't have zebra crossings (since they have traffic
      lights) it should be two dotted lines demarking the pedestrian safe zone."* A zebra means
      *traffic gives way to you* and on the spine it does not — what stops the traffic is the
      light, which is `Tuning.validate_signals`' whole contract — so the paint has been
      contradicting the rule at every junction of the one street where getting it wrong ends the
      day. Four places have to agree, per `CLAUDE.md`'s street-hierarchy recipe: `GroundTiles`,
      `CityGenerator`'s tile choice, whatever `CrowdAgent`'s crossing scan reads (it walks
      **tiles** and looks for `CROSSING`, which is the M29 invariant — so a new tile type or a
      changed one has to keep that question answerable), and the traffic's give-way rule, which
      must **not** start giving way on the spine

      **Built, and three of those four places needed nothing.** The tile type is unchanged, which
      is the whole shape of the fix: M41 had already considered painting the crossing away and
      rejected it — *"a walker crossing a side street would then be standing on open carriageway,
      and the one thing a zebra is for is saying where a person on a road is meant to be"* — and
      the player is not asking for that either. They are asking for **different paint**. So
      `GroundTiles._crossing_variant` picks four new tiles when either corridor is the spine and
      every rule that reads `CROSSING` goes on meaning what it meant: the crossing scan, the
      give-way rule (which already exempted `MAIN`), and where an event may stand.

      The one thing that did have to move is the **trace**, which said *"at a zebra"* on a street
      that has none — a line that would send the next reader looking for the wrong bug, on the one
      street where the difference between a negotiation and a wait is the difference between a day
      and a day lost.

      Two dotted lines per crossing and two crossings per junction, so a spine crossroads has four
      dashed rows across it: the lines run the way she is crossing, one at each edge of the
      two-tile band, which is what `% SIDEWALK_WIDTH` is asking in that function. Photographed once
      and played by nobody
- [x] **The police car has a rear view** — finding 3, *"the police car only has a sideview even
      when driving vertically"*. An art gap in the crowd rather than in the catalogue

      **It is in the catalogue, not the crowd**, and it is three rows rather than one. The crowd's
      own cars have had an end-on view since M12 — `car_end_body.svg`, with the note that at that
      angle the front and the back of a car are the same shape — and every vehicle in the
      *catalogue* was one side-on sprite mirrored east and west. `police_patrol`, `fire_truck` and
      `military_convoy` are the three mobile ones, so all three got one: answering the complaint
      and leaving the other two would be this file's own warning about the border brief.

      Each keeps its **own** end-on picture rather than borrowing the crowd's generic car. That is
      M37's rule and it bites hardest here — the whole content of a vehicle row is *which* vehicle
      it is, and a police car that becomes a saloon the moment it turns north is the one silhouette
      the screen-edge badge exists to show, gone at the moment it starts coming towards her. The
      badge itself keeps the **side** view: an icon is read at 40px against a row of other icons,
      and a vehicle end-on is a box at any size
- [x] **Say GAME OVER on the game over screen, in big letters** — finding 5. *"In addition to
      everything else that is already there"*, so the ending text, the reason and the keys all
      stay; this adds a heading

      **It is not the same word for all three endings, and that is a decision rather than the
      request being trimmed.** The screen the complaint came off is the `BAD` one, where the nerves
      ran out, and `GAME OVER` is what that is; stamping it over a run somebody *won* would be
      telling them they lost. `THE END` is the same size, the same weight and the same job on the
      other two. Say so if that reads wrong — it is one line of a dictionary.

      **And a dev flag came with it, because there was no way to look at the thing being changed.**
      An ending is at the far end of fourteen days or five spent nerves, so `--ending
      bad|neutral|good` puts the last screen of a run on screen at boot. It is the same argument
      `--press` was built on: nothing in the suite or in a screenshot had ever reached that screen.
- [x] **Change the colour of the title on the title screen** — finding 6. `Palette.TITLE_TEXT`, a
      brighter version of the doorstep the screen is standing in front of. It was the same warm
      off-white as the line under it and the controls below that, so the screen was four labels in
      one colour and the name of the game was only the biggest of them. Deliberately **not** one of
      the danger colours, for the reason the signal lamps are not: a title in `MARK_COSTLY` is a
      game named after a warning
- [x] **A car on the bridge drives off the map instead of vanishing** — finding 7. This is M35's
      *"nothing vanishes while you are looking at it"* arriving at the crowd, which has never had
      it: `Crowd` recycles a car when it leaves the corridor box and the box is smaller than the
      map, so the three holes in the boundary — the bridge, the tunnel, the road out — are exactly
      where a recycle is visible. The rule to state is the events' one: past `Tuning.OUT_OF_SIGHT`
      before it is taken

      **Built, and the interesting half is who is *not* allowed to.** Outside the map is water,
      forest and mountainside — painted ground with no road on it — so letting every agent overrun
      the boundary would drive cars into the sea at every corridor. `City._paint_outside_the_map`
      lays carriageway out there at the spine's own width and nowhere else, and that is exactly the
      condition: a **car**, on the **main road**, going **north or south**. Everybody else keeps
      the tile of slack they had. `CrowdField.along_bounds` is clamped to the map, so the second
      thing that had to move is the box test — asking it about a car on the deck of the bridge
      recycles the car on the deck of the bridge
- [~] **Did the day counter reset mid-run?** — finding 4, and it is recorded with the player's own
      doubt: *"maybe I died fully without noticing."* Read it **with** finding 5 rather than
      instead of it — if a run can end and restart without the player noticing it has, that is the
      game-over screen's complaint arriving from the other side, and fixing the screen may be the
      whole of it. What to check first is whether the ending path can reach the title screen and
      begin a new run without the ending screen having been readable

      **Checked, and there is no path that resets the counter inside a run.** `GameState.day` moves
      in exactly two places: `finish_day` increments it on a win, and `start_run` sets it to 1.
      `start_run` is only reached through `_restart_run`, which **reloads the scene** — so a day
      counter that reads 1 again is a new run and nothing else. The player's own alternative is the
      only explanation the code allows.

      **Left half-open rather than closed, because that is not the same as saying nothing
      happened.** What it says is that the run ended, and *"I can swear the counter reset"* is then
      a report that the ending was unreadable — three screens deep, in the fiction's own voice,
      dismissed with the same key as everything else. Finding 5 is the fix and this is the evidence
      for it. Reopen it if the counter is ever seen to move with nerves still on the HUD

## M53 — A junction is made of the streets that meet at it · not started, queued after M52's lights

**Ordered by the player: *"queue those fixes after the traffic light fix."*** So M52's third item
goes first and this follows it, which is the right way round for a reason worth writing down — the
lights are a decision about **which junctions are junctions at all**, and three of the four items
below are about what a junction is made of. Building them against a lattice that is about to be
re-asked the same question would be doing the work twice.


Playtest 16, in full in **[docs/PLAYTEST-16.md](PLAYTEST-16.md)**. Four findings; the first three
are one complaint: **the crowd travels a lattice that is not the city.** It walks onto a bridge with no
footway, off a bulkhead into the sea, and through crossroads whose arms are grass — and in every
case it then vanishes where somebody is looking at it. Underneath the first two is one missing
rule: the lattice draws a full crossroads wherever two corridors cross, whether or not the arms of
it are streets.

**Neither of these is news to the repo, which is the part worth noticing.** M41 has carried
*"T-intersections everywhere else on the edge — the lattice currently runs into the boundary and
stops"* as an unbuilt item for twelve milestones, and M51 finding 1 was this exact defect on a
cul-de-sac, fixed there for the crowd's *view* of the wall and not for the junction that should
never have been drawn. A finding that arrives twice from a player after being written down once by
the project is a to-do that was filed and not read.

- [ ] **Cars and people still go off the map** — finding 1, and *"still"* is the word to read.
      M51's fix was deliberately narrow: overrunning the boundary is for **a car on the main road
      going north or south**, because outside the map is water, forest and mountainside. Everybody
      else keeps "the tile of slack they had", and this report is that the slack is visible at an
      edge with nothing beyond it, for people as well as cars. Two candidate causes and they want
      different fixes — the agent is **recycled on screen** (M35's *"nothing vanishes while you are
      looking at it"*, which has never reached the crowd away from the three holes in the border),
      or the **junction should not be there**, which is finding 2
- [ ] **A junction between two precinct arms is still asphalt with zebras on it.** A precinct is
      laid `SIDEWALK` frontage to frontage by `CityGenerator._street_tile`; the junction between two
      of them was never included, so a pedestrianised stretch has a road crossing in the middle of
      it
- [ ] **A junction whose arm is not a street has three arms, not four.** The shore, a park, a calm
      zone's absorbed corridor — `CityMap.absent_segments` and the map edge already say which arms
      exist. Nothing that draws a junction asks
- [ ] **Only cars go over the bridge** — finding 3, and it is M51 finding 7's own sentence read
      back. A bridge is *"a stretch of carriageway with no pavement beside it"*, which is the whole
      design and is why she may walk onto it and be run over rather than be stopped by a wall. The
      **overrun permission** was narrowed to a car on the spine and the **lane** was not, so a
      walker's lanes still run the length of a corridor that at the boundary is a bridge. Note what
      is not being asked for: the bridge is not to be made safe
- [ ] **And the crowd has to agree with the drawing**, which is M51 finding 1's lesson arriving
      where it was pointing: a T-junction the paint knows about and `CrowdAgent._divert` does not is
      the same bug in the other direction
- [ ] **Calm areas at the edge of the map** — finding 4, *"which should be impossible"*, and it is
      **not this milestone's to build**. The rule is already written down, unbuilt, in M47: *"make a
      rule to not have a calm area at the edge of the map or next to the main road"*, with the
      measurement (96 eligible blocks → 56 with the edge rule → 48 with the spine rule) and the
      three things to get right already beside it. Recorded here so the finding is not lost, and
      **closed from M47** rather than re-designed. It is the third item in one session that this
      file had filed and not read

## M52 — The calm has a shape, and the lights have a reason · not started

**Asked for on 2026-08-31, in the player's own words and in this order:**

> *"The next steps after M50 are 1) 2x2 courtyard and rectangular calm zones 2) calm zone rate
> adjustments 3) traffic light placements."*

**That is the whole of what was said, and it is written down before anything is read into it**, per
the rule at the top of `CLAUDE.md`: a finding summarised on the way in has already lost the part
that was hard to work out. What follows is *this side's reading* of each, kept separate from the
sentence above, together with the questions that have to go back — because all three are single
clauses about systems that currently answer them with a constant, and a reading is not an
instruction.

**Where each of the three stands today**, so the questions below are asked with the work done up to
the fork:

1. **Calm zones are square and there is one size of them.** `Tuning.CALM_ZONE_BLOCKS` is `2`, and
   every piece of arithmetic that follows — the tile rect, which segments are absorbed, which
   junctions survive — is written in terms of it (`CityGenerator._zone_fits`, `_absorb_the_zone`,
   `CityMap.lot_rect`). A city gets one or two zones and the rest of its calm is single-block. A
   **courtyard** is a different thing again: `BlockPurpose.COURTYARD`, the court inside one
   residential block, and it has never been a zone.
2. **A calm area's rates do not depend on what kind of calm it is.**
   `SLEEPINESS_CALM_ZONE_MULTIPLIER` (14.0) and `EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` (2.2) are
   asked of the *ground*, through `Baby`'s four questions, and every calm tile answers the same —
   a 22-tile zone and an eight-tile courtyard fill the meter at the same rate.
3. **Lights are on the spine and nowhere else.** `TrafficSignals.is_signalled` is
   `junction.x == _map.main_road`, one line, and M41's note beside it says that is deliberate:
   *"every junction on the spine is signalled and no other one is, which is what makes the lights a
   property of the street rather than a scattering of them."* Anything that moves it is moving that
   sentence, so it wants to be moved on purpose.

**And two of the four questions below were answered on disk before they were asked, which is the
thing to read first.** *(Found while recording playtest 16's finding 4.)* **M47 already holds item
1, unbuilt, in the player's own earlier words:**

> *"Make more calm areas take up multiple blocks — I said a long time ago that an inner courtyard
> (surrounded by buildings) should have a footprint of 2x2 blocks (apartment complex) — this never
> got implemented. Not all calm areas have to take up multiple blocks but add more that do. Also,
> add calm varieties that take up 2x1 non-square shapes."*

So *"2x2 courtyard"* is an **inner courtyard surrounded by buildings, an apartment complex, four
blocks**; *"rectangular"* is **2x1**; and the answer to *how many* is *"not all of them, but more
than now"*. The two questions this side had drafted are struck below rather than deleted, because
what they cost is the point: **the answer to "what exactly did you mean" was already on disk, and
asking again is what a to-do that was filed and not read costs.** It is the third such item in one
session, after M41's T-junctions and M51's cul-de-sac, and the M47 entry that answers it also
carries playtest 16's finding 4 — *"a calm area at the edge of the map should be impossible"* —
which is likewise recorded there and likewise never built.

**Build item 1 as M47's entry**, not as a fresh design. What is genuinely new in M52 is items 2 and
3.

**The questions that are still open**, and neither is a detail — each changes what gets written:

- [x] ~~A "2x2 courtyard": a courtyard lot four blocks across, or four blocks with a shared
      court?~~ Answered by M47: an **inner courtyard surrounded by buildings**, an apartment
      complex, 2x2 blocks.
- [x] ~~"Rectangular": which rectangles, and how many per city?~~ Answered by M47: **2x1**, and
      *"not all calm areas have to take up multiple blocks but add more that do"*.
- [ ] **"Rate adjustments": is the rate a property of the *kind* of calm, of its *size*, or a
      number that moves for all calm at once?** Per-kind is the one that reaches `Baby`'s
      interface, and M41's rule applies — a fifth question that is a special case of one of the
      four is what that rule exists to stop, so this wants to generalise `decay_multiplier` rather
      than sit beside it.
- [ ] **"Traffic light placements": what decides where a light goes, now that it is not just the
      spine?** And what it is *for* — M41 states the signals' fairness contract over the side
      street's green, and lights on an ordinary junction would put that contract on streets the
      player crosses casually all day.

## Tooling for the diversion work · `feature/a-map-that-shows-the-plan`

Asked for alongside the diversion design, and it goes **first** for the reason the playtest-13
tooling did: the thing being built is a *placement*, and a placement is exactly what a trace in
words cannot show. Without this the only way to check that a corridor points anywhere is to play
the day and form an impression.

- [x] **Draw the corridor on the telemetry map.** `TelemetryMap` already writes a
      `<stem>-map-day<NN>.png` per day with the home, the calm areas, the spine, the precincts and
      the closures. Add the day's **corridor** — the routes from the doorstep to the calm areas
      that are still worth reaching — as a drawn path over the grid. This is the picture that
      answers *"is anything guiding her"*, which is the open question the whole milestone exists
      for, and it cannot be answered from a log line. **Built**: violet, junction centre to junction
      centre so it reads as a path. And it immediately earned itself — the first picture shows the
      trunk wandering west, north and back east before it arrives anywhere, which is the
      13.2-against-4.4 measurement above as something a person can look at
- [x] **And then it was read by the player, which changed three things about it.** *(2026-08-31,
      the first time anybody looked at one.)* Two were about the picture and the third was about the
      city; all three are in `docs/TELEMETRY.md` and the code, and the shape they share is worth the
      line: **a debug picture that decorates is a debug picture that lies.**
      - *"Marks disappearing is a problem"* — the corridor was drawn under four other marks and
        over one, so a stroke could simply not be there. It is **mixed into the ground** now rather
        than laid over it, which is also what *"keep the violet lines transparent"* asks for.
      - *"Don't draw the bundles white — don't make a distinction between path and bundle."* Gone.
        What goes with it is a diagnostic — a picture with no sharing in it is a star — and it is
        asserted in `tests/test_route_tree.gd` instead of being visible.
      - *"Why blue? Why not just take the sidewalk colour"* — the precinct mark is **deleted**. A
        precinct is laid `SIDEWALK` from frontage to frontage, so the ground pass already draws it
        as the one corridor with no asphalt stripe down it, and the blue line was an overlay
        repeating a fact the picture had
- [x] **Mark every placed event with its categorisation.** Not just *where* — **what kind**, in the
      vocabulary in `docs/CITY.md`, "The words for it": its **effect** (lethal / impassable /
      costly) and its **role** (wall / friction / set piece). A wall drawn on the corridor instead
      of beside it is the central defect this milestone can have, and it is one glance to see and
      invisible in every other tool. Distinguish placed-and-live from placed-and-never-reached, and
      keep it legible at 640px

      **Built: colour is the role, shape is the effect, a white pip is whether she reached it.** No
      row carries an effect the vocabulary did not already have — `EventDef.effect()` and
      `Planned.role` both existed by the end of step 2 — so this is a legend rather than a model,
      and `tests/test_telemetry.gd` asserts the legend *is* the drawing. Three things came out of
      building it, and two of them were found only by opening the PNG:

      - **"Distinguish placed-and-live from placed-and-never-reached" needs a second picture, and
        the second picture is the more useful half.** At dawn nothing has been reached, so the flag
        can only mean something at dusk — `-map-day<NN>-dusk.png`, written from `_on_day_finished`
        before `end_day()`. What the pair says that neither says alone: the dawn map shows a wall in
        the wrong place, and only the dusk one shows **a corridor with nothing on it ever met**.
      - **The first version faded what she never reached, and that is the picture whispering the
        thing it exists to shout.** A wall in the far corner of a map she never walked into is
        still a wall in the wrong place, and it is exactly the placement no trace can report. Drawn
        as a pip instead, every mark stays at full strength — and the pips turn out to be a **trail
        of where she actually went**, laid over the corridor the day planned for her, which is a
        second question answered for nothing.
      - **A faint mark can still be the loudest thing in a picture if it is the wrong shape.** A
        routed event draws a band along the ground it covers; at the mark's own strength, on a day
        with 175 placements, those bands read as *corridor* — thin coloured lines down the middle of
        streets, which is what the violet is. Dropping them was wrong too (a van that sweeps a whole
        street would be drawn as a point). 0.18 makes it a shadow you find when you look for it. The
        shape to carry: **a mark that can be mistaken for the one thing it has to be compared
        against is worse than no mark.**

Both obey the telemetry invariant — no RNG, nothing that changes a placement, no cost when
telemetry is off — and both are dev tooling under the same eventual debug-build gate.

## Tooling for playtest 13 · `feature/a-picture-of-the-city`

Findings 4 and 5. Small, asked for by name, and **built first**, because M46 and M47 both want
exactly what they provide. Neither is a game feature; both go with the dev flags and under the
same eventual debug-build gate.

- [x] **Render the whole city grid to a picture in the telemetry folder** — finding 4. Not
      `--overview`, which is a dev flag on a run somebody has to take and which photographs the
      *rendered* city: this is the grid itself, one small square per tile coloured by tile type,
      written beside the log every run without anybody doing anything. Everything needed exists —
      `Tile` decides the colour, `CityMap` holds the grid, `Telemetry` owns the directory and the
      naming. Mark what a trace cannot say in words: the home, the calm areas, the main road, the
      precincts, the day's closures. It must obey the telemetry invariant — **no RNG, nothing that
      changes a placement** — and it must cost nothing when telemetry is off
- [x] **A key that takes a screenshot and writes a note** — finding 5. `Telemetry.snapshot()`
      exists and is heuristic; what is missing is the player saying *look at this*. Its own key, it
      **bypasses `SHOTS_PER_DAY`** (a person asking is not a heuristic firing), and it writes a
      `note` alongside so the picture has a line in the trace to sit next to — position, day,
      meters, and what is near her. Note the M36/M38 lesson before wiring it: nothing in the suite
      or a screenshot has ever pressed a key, and a bare key is not an action — `--press key:<x>`
      is how it gets tested at all

**Both built, and it is `TelemetryMap` plus twelve lines in `main.gd`.** `P` (or `F9`, two
bindings because a bare F-key is the convention and is also what macOS hands to the volume control
unless a setting is changed) writes `<stem>-<clock>s-asked.png` and a `shot` entry; every day
writes `<stem>-map-day<NN>.png`, 640px square and about 5kB.

**Three things were found by building it, and two of them are the reason it has tests.**

- **A float colour does not survive `FORMAT_RGB8`.** The marks were authored as
  `Color(1.0, 0.25, 0.35)` and read back a fraction off, so the test that asked *is this mark in
  the picture* failed against the constant it had just drawn with. They are hex now, like
  everything in `Palette`, and the ground colours never had the problem because `Palette` already
  was.
- **`snapshot_now` guarded the note and the picture together, and the suite is the configuration
  that keeps the note.** `begin_memory_log()` produces a log with no path, which is a real state
  rather than an edge case, and one guard covering both halves made the entry vanish along with
  the PNG it could not write. They are guarded separately.
- **The home crosshair was built and taken back out.** It reached a block either way to make a
  few tiles of stoop findable in a 160-tile map — and it is the only red in a picture with no
  other red in it, so it was already the first thing the eye lands on. It was covering two streets
  to buy nothing. *(Reported directly: "the home cross hair is not needed — home was easily
  findable with just the red dot from before.")*

And the first two maps it drew already show M47's own finding without anybody measuring anything:
calm areas hard against the map edge, and one directly beside the spine.

## M10 — Polish · `feature/polish`

Not started. The game is complete without it; this is what would make it shippable.

- [~] **Finish the visual channel — before audio, not after.** House rule: audio is never
      the only channel, so every cue that will become a sound must already work silently
      (docs/EVENTS.md, "Showing the danger"). Two of the three gaps closed in M22:
  - [x] **HUD line for `city_wide` sources.** *(M22.)* The loudspeaker masts from day 5 and
        the curfew announcement had *no* on-screen presence at all — the aura layer skipped
        them, correctly, since a field with no edge cannot be a ring, and nothing took over.
        The player saw excitement refusing to drain and nothing said why. `EventBus` now
        announces what is holding the floor and the HUD says so.
  - [x] **Screen-edge indicator for fast movers.** *(M22.)* `fire_truck` and `military_convoy`
        are built around a long telegraph spent getting off that street, and at 190px/s most
        of that warning happened off-screen where the ring could not be seen. `DangerEdge`.
  - [ ] **Sound lines.** Concentric arcs thrown off a source on a pulse's rising edge —
        the visual form of a discrete noise. Would give the yeller, the dog and the
        reversing van a readable "that just happened" beat rather than only a swell.
  - [x] **The entities themselves.** *(M37.)* Every visible catalogue row draws something of
        its own, and it is a rule with a test rather than an art to-do: no two rows share a
        look, no two looks share a silhouette. The crowd is deliberately still anonymous — that
        is the opposite rule and it is what an authored event stands out from.
- [ ] **Audio**, once the above is done and judged on its own: per-act ambient beds,
      per-event cues, the baby's breathing and fussing as the diegetic version of the
      meters. Additive by design — the game must already be fully playable muted.
- [ ] Main menu and settings. The pause screen exists (M33, working since M36) and there is a
      **title screen** as of M38 — but it is a title, three lines of controls and two keys, with the
      street outside the home running behind it. No options, no seed box, no load game
- [ ] Save/continue a run — `GameState` is already shaped for it (seed + day + a few
      arrays), so this is serialisation, not design
- [ ] Accessibility: colourblind-safe meters, a telegraph-time multiplier, reduced motion
- [ ] Controller support
- [ ] The `--spawn`/`--follow`/`--day` dev flags should be gated behind a debug build
- [ ] `_first_event_position` and friends live in `main.gd`; a `DevFlags` helper would keep
      the boot scene about booting

---

## Audit of the feedback record · not started

Every human turn in this project's session history was read back against what is on disk, looking
for two things: feedback that was never properly recorded, and feedback that was **silently
overturned**. The recording discipline came out well — the two known failures (the border brief and
hard/soft diversions) are the ones already written up under M49, and almost everything else is in a
`PLAYTEST-NN.md` table in the player's own words. What follows is what the audit added, and it is
mostly the *second* category. It is the evidence behind the new `CLAUDE.md` rule, *"Never silently
overturn a decision the player took"*.

- [x] **M20's parking says no playtest asked for it, and playtest 02 did.** *(Resolved
      2026-08-31: the request is real, it stays parked, and it is a discussion that is owed rather
      than a dead item. Status line corrected.)* The entry above
      (`M20 Traffic that behaves`) parks eight-way driving, overtaking and the crash event as
      *"none of which any playtest has asked for"*. Playtest 02 finding 4 is the player asking for
      all three: *"faster cars should either slow down or when the opposite lane is clear overtake
      the slower car. this requires cars to be able to drive in 8 directions as well. if overtaking
      hits an oncoming car a crash should happen which is a very exciting event so the player has
      to clear the area fast."* It is recorded correctly in `docs/PLAYTEST-02.md`; only the status
      line is false. **Fix the line, then ask whether it stays parked** — parked with the player's
      agreement is a fine place for it to be, and that is not what it currently is
- [x] **The east and west spine exits were deleted, and three places still describe them.**
      *(Resolved 2026-08-31: **"east/west is a hard no. There is only one main road and it is from
      north to south."** The deletion stands, and it is now a decision rather than an inference.
      `docs/CITY.md` and `city_generator.gd` corrected; the generator's east-west calm guard is
      left in place with a note that it has outlived its stated reason.)* M49
      removed them, reasoning that playtest 12's *"there should be no east to west [main roads] at
      all"* took them with it. But the exits are their own brief, given separately: *"the side to
      side mainroad just going towards east west in one space. the player should be able to walk
      into those which would be certain death once a car comes. that way it's not an artificial end
      but an emergent end."* Two instructions in tension, resolved without asking. Either answer is
      defensible; taking it unilaterally is not. **Ask, then make the repo agree with itself** —
      `docs/CITY.md` "The edge of the world" still lists *"the road simply carrying on east and
      west"*, and `src/city/city_generator.gd:330` still protects *"the corridor the east and west
      city exits open onto"* and says *"it stays a constant because the exits do"*
- [ ] **The pending calm-ground multiplier is planned against a stale base.** The playtest-14 entry
      *"Calm ground is worth more"* reads `SLEEPINESS_CALM_ZONE_MULTIPLIER` as **12** and derives
      18 and 24 from *"x1.5 … and double it for 1x1"*. It has been **14** since M46 took it 12 → 14
      for playtest 12 finding 6. Applied to the real value the instruction gives **21**, not 18.
      `docs/PLAYTEST-14.md` carries the same stale reading, and `CLAUDE.md`'s known-shaky-ground
      note still describes the M38 10 → 12 move as the current state. Correct all three before the
      number is moved — this is the constant M38's own entry warns decides whether a day is
      winnable once the park is reached
- [x] **The routing brief was never captured, and reconstructing it from the record failed.**
      *(Resolved 2026-08-31 by the player restating it; `docs/CITY.md`, "Diversions — the design".)*
      Worth keeping for the shape of the failure. Playtest 14 recorded *"no note anywhere"*; an
      audit then found playtest 01 finding 12, which is about blockers and route pruning, and read
      it as the missing design. **It is not** — hard/soft there was inferred to mean *impassable
      vs. expensive*, where the player means **permanent vs. per-day**, and the real brief has a
      severity axis underneath it that nothing in the record hints at. Two lessons, and the second
      is the expensive one: **a finding marked done is never re-read**, so summarising one on the
      way in leaves a checkmark rather than a gap. And **a plausible reconstruction is worse than a
      blank**, because it gets built. The one thing that produced the actual design was asking
- [ ] **A bug reported inside a design finding was fixed and never closed out.** Playtest 12
      finding 1 is tagged *design + bug* and carries *"(also people seems to not go in the middle)"*.
      The design half drove M41; the bug half is fixed — `CrowdLanes.PRECINCT_OFFSETS` is six lanes
      across the whole width — but nothing anywhere connects the fix to the report. Bookkeeping
      rather than lost work, and the shape is worth watching: **a finding with two halves gets
      closed when the louder half is done**

## Open design questions

These need a human playing the game, not more code.

- [x] **`_ensure_one_usable_park`'s early return defeated the rule written underneath it — and the
      fix was to stop repairing and start refusing.** *(Found in M50 while chasing a density floor
      that had nothing to do with hard blockers; answered by the player on 2026-08-31.)*

      The function collected, per calm area, the events whose fields reach it, and **returned as
      soon as any one area came out clean** — so playtest 14's stronger rule, *"every calm area she
      has not used this act stays clean, not just one of them"*, only ran on the days the older one
      had already failed. Measured over 64 planned days: the early return fires on 25–75% of them,
      and on a raw day **6.4 to 7.6 of the seven-to-nine unvisited areas are spoiled**. So the real
      promise was *one of the nine is clean and you cannot tell which*.

      Four ways to price that were measured and put to the player, and every one of them was the
      wrong question: *"why are 7-9 unvisited calm areas spoiled? Just don't place events there!"*
      The whole framing was a repair — plan the day, then delete what landed badly — where the rule
      belongs at **placement**. `EventScheduler._calm_to_leave_alone` is the fix and it is four
      lines: the calm ground of every area she has not settled in this act is refused to
      `_place_one`, and the events that would have gone there go somewhere else.

      It is better on both axes at once, which is why the options were worth throwing away. Every
      unvisited area is clean on **64 days of 64**, and the density went **up** rather than down,
      because the budget is no longer spent on events that were about to be deleted: day 1 goes
      118.4 → **124.6** placed and day 14 204.9 → **223.4**. `_ensure_one_usable_park` stays as the
      last line for the one case placement cannot answer — she has settled in every area there is,
      so nothing was protected — and `tests/test_events.gd` holds the new rule over a whole run.

      The shape to carry, because this project already has the rule and did not apply it here:
      **check before accepting rather than repairing afterwards.** `CLAUDE.md` says it about
      closures, and the argument is identical — a repair spends the budget twice, makes the day's
      density depend on how many placements happened to land badly, and leaves the guarantee
      running only when something else has already failed.

- [~] **Is the nerve economy right?** **Half answered by playtest 08: three was too few**, and the
      evidence is a run that ended on day 3 with two nerves spent on the same charging dog. It is
      five since M35. M32 had already changed the shape of the question rather than answering it — a
      lost day no longer advances the calendar, so a nerve is an *attempt* rather than a day thrown
      away — and what is still open is the other side of it: with five attempts and a retry costing
      only time, is a lost day a punishment at all? The run log's `nerve` entries say where they
      went, and also say which day is being played again. Note that five was **asked for, not
      derived**, and the thing that made three too few was a defect (the day-3 dog) rather than a
      difficulty: if act I now reads as fair, five may be generous.
- [~] **Is the balance right?** *(M14 pitched it against the day rather than against itself;
      M18 then re-pitched it against a **minute of play**: day 330s → 180s,
      `SLEEPINESS_GAIN_WALKING` 0.24 → 0.42, calm 3.5x → 10x, idle drain 0.6 → 1.0. A whole
      day of street walking reaches 76 of 100 and a calm stretch takes 24s.)* The open
      question is now the opposite one: with the meter this generous once calm ground is
      reached, is anything standing between the player and a won day? **Playtest 03 answered
      that with a trace: no.** Day 1 was won in 103.9s of 180 with zero `near` entries — the
      player crossed the city and came back without encountering a single event.
      **M19 put things there and the question is now whether it put too many.** A day-1 map
      carries 13 non-ambient events instead of 4, walking into somebody costs ~15.6 points, and
      the carriageway ends the day. A scripted walking probe says a quiet pavement is close to
      break-even on excitement and the arterial is not survivable to walk the length of — which
      is the intent, but "the arterial is for crossing" is a claim about a player, not about a
      probe. Needs a run and a trace, not more arithmetic.
- [ ] **Is 14 days the right run length?** Act I is only 3 days, which may be too little
      time to learn a city before it starts changing.
- [x] **How visible should the resistance be to a player ignoring it?** *Resolved by playtest
      02, decision 14: as visible as it is now — a chalk mark and one HUD line, no marker, no
      quest log.* The resistance is the difficulty dial (decision 10), and **wanting the dial
      and finding the dial are the same behaviour**: a player who wants to be challenged
      explores, and exploring is what finds a chalk mark on an alley wall. Carried open since
      M8; closed by leaving it alone. What *does* change is the key — see M26. The run log's
      `contact` entries record whether a player ever went near one, because "nobody ever finds
      it" would falsify the reasoning.
- [x] **Should running ever be *required* (a forced chase), or always purely a player
      choice?** *Answered by playtest 02, finding 9: yes, for some entities.* The measurement
      that came with it is the surprising part — running is currently the wrong move against
      **every** event in the catalogue, because `EXCITEMENT_FROM_RUNNING` plus the collapsed
      decay (3.5/s → 0.5/s) outweighs the shorter exposure every time. The run button is a
      trap. Making running necessary is therefore a mechanic to build (M25), not a number to
      change.
- [~] Should there be a diegetic-only mode — a baby's face instead of two bars? **Half answered
      by playtest 06, finding 5, and built in M32**: not instead of the bars and not a face, but
      *at the pram* — four states with an instruction each. What is still open is whether the
      bars could now be turned off entirely, which is a question for somebody playing with them
      hidden rather than for more code.
- [x] Does a lost day advancing the calendar feel right, or should it repeat the day?
      **Answered by playtest 06, finding 4, and built in M32: it repeats the day.** *"We
      shouldn't advance the day, that's for sure."* So a nerve buys a **retry of the same day** — the same city,
      the same closures, the same event plan, because all of those are deterministic from the
      seed and the day number — and the calendar only moves when a day is won. Nerves stop being
      a second currency and become three failed attempts spread over the run. Carried open since
      M6; closed by being asked out loud. See [PLAYTEST-06.md](PLAYTEST-06.md) for what it does
      to the one-shots, the block arcs and the endings
