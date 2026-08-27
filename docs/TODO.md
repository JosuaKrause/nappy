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

**Playtest 04 set the order that stands now.** M27 and M22 are done. **M21 is next**
(four-block calm zones), then M17 behind it. M20 is **absorbed into M27**: cars follow and queue
now, and what is left of it — eight-way driving, overtaking, a crash as a catalogue event — is
unasked-for and no longer urgent.

**What M27 leaves open.** Nobody has played it. The densities in `docs/PLAYTEST-04.md` came off
a probe, and *"the arterial is for crossing"* is still a claim about a player rather than about
a rig. Read a run before touching a constant: `crowd` for contacts and horns, `near` for what
came within reach — which should now be a great deal more than playtest 03's zero — `road` for
time in the carriageway, `ahead` for what the director put in front of her, and `lost` for what
was around when a day ended.

M10 (polish) still stands but now sits *after* the playtest work — there is no point
polishing a loop that is about to be re-pitched.

`tools/test.sh` runs 15744 checks (~80s); `tools/check.sh` boots the project; `tools/run.sh`
plays it; `tools/telemetry.sh` reads back what the last run did.

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
      accepted. Canal dropped to M21
- [ ] **M17 Route map** — the planning screen, rendering M15's block states

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
      overtaking, eight-way driving and the crash event, none of which any playtest has asked
      for, so this is **parked** rather than queued
- [ ] **M21 The city overhaul** — findings 5 and 6, plus the canal dropped out of M16, **plus
      playtest 03 finding 2**. Calm zones of four blocks, so the lattice grows T-junctions and
      L-bends and can no longer be derived from a coordinate; main roads with traffic lights
      against side roads with zebras, where a main road is crossed rather than walked.
      **Raised above M20**: the four-block calm zone is the structural answer to twenty seconds
      of walking in a circle. That circling is not a length problem — progress requires motion
      and a calm block is a few tiles across, which is jointly sufficient for a lap, which is
      why M18's shorter stretch did not remove it and no further balance pass will
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
- [ ] **M24 The city remembers where you went** — finding 11. Record the calm zone the player
      settled in and bias the next day's spoiling event toward it, so the options narrow *at
      the player* rather than at random. Kept from feeling like a punishment for playing well
      by two things already in place: it spoils with an avoidable, visible event rather than
      removing the ground, and M16's route invariant still guarantees two calm areas with two
      routes each
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
  - [ ] **The entities themselves.** `homeless_yeller`, `busker` and `poster_crew` all draw
        the same `person.svg`, as does a crowd walker. The vocabulary's first row — *the thing
        itself reads as what it is* — is currently being covered for by the caret over two of
        them, which is the wrong way round. First thing to fix when the art gets a pass.
- [ ] **Audio**, once the above is done and judged on its own: per-act ambient beds,
      per-event cues, the baby's breathing and fussing as the diegetic version of the
      meters. Additive by design — the game must already be fully playable muted.
- [ ] Main menu, pause menu (Esc quits outright today), settings
- [ ] Save/continue a run — `GameState` is already shaped for it (seed + day + a few
      arrays), so this is serialisation, not design
- [ ] Accessibility: colourblind-safe meters, a telegraph-time multiplier, reduced motion
- [ ] Controller support
- [ ] The `--spawn`/`--follow`/`--day` dev flags should be gated behind a debug build
- [ ] `_first_event_position` and friends live in `main.gd`; a `DevFlags` helper would keep
      the boot scene about booting

---

## Open design questions

These need a human playing the game, not more code.

- [ ] **Is the nerve economy right?** Three nerves, fourteen days, and a lost day advances
      the calendar. Never tested against a game that threatens from day one, which decision 9
      now says it should. If act I genuinely bites, early losses become normal and a run may
      be decided before act III arrives. The run log's `nerve` entries say where they went —
      which day, which act — so this is waiting on runs now rather than on code.
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
- [ ] Should there be a diegetic-only mode — a baby's face instead of two bars?
- [ ] Does a lost day advancing the calendar feel right, or should it repeat the day?
      *(Current: advances, which makes Nerves the real resource.)*
