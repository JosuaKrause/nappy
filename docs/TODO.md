# Nappy — TODO

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done

Each milestone is one git branch, merged to `main` when green.

**Where things stand:** M0–M15 are done and merged, and the game has now been played twice
by a human. The first playtest produced thirteen findings, planned as M11–M17 in
**[docs/PLAYTEST-01.md](PLAYTEST-01.md)**; the second produced six more, planned as M18–M21
in **[docs/PLAYTEST-02.md](PLAYTEST-02.md)**. Both are live plans and should be read before
picking anything up. Execution order is numeric: M16 and M17 finish before M18 starts.

M10 (polish) still stands but now sits *after* the playtest work — there is no point
polishing a loop that is about to be re-pitched.

`tools/test.sh` runs 7187 checks; `tools/check.sh` boots the project; `tools/run.sh` plays
it.

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

- **No spatial hash.** The budget tops out near 22 concurrent events; a linear scan is
  free and a hash would be more code with more ways to be wrong.
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
- [~] **M16 Route pressure** — a per-day pruned network with legible blockers, leaving at
      least two distinct routes to at least two distinct calm areas. Canal dropped to M21
- [ ] **M17 Route map** — the planning screen, rendering M15's block states

## M18–M21 — Playtest 02

See **[docs/PLAYTEST-02.md](PLAYTEST-02.md)** for the findings and the reasoning. Six
findings from the second human playtest, queued behind M16 and M17. Summary only here:

- [x] **M18 The park has to be worth it** — finding 1. Calm ground fills the meter in 24s
      instead of 119s (10x the street, not 3.5x), and the day itself is 180s instead of 330s
      — aimed at a minute of play with a grace of three. Pulled ahead of M16, because
      closures tuned against a day that was about to halve would have been tuned wrong
- [ ] **M19 Bodies on the street** — findings 2 and 3. Pedestrians and the player collide
      and displace each other, a car strike is a hard fail, pavement hazards (a café
      spilling out, a dog on a long lead) make one side of the street the wrong side, and
      cars stop for you at a zebra. The collision bump is a short-lived *source*, never a
      write to `Baby.excitement`
- [ ] **M20 Traffic that behaves** — finding 4. Cars follow, slow and overtake instead of
      driving through each other; 8-direction driving so they can turn; an overtake into
      oncoming traffic crashes, and the crash is a catalogue event with a real telegraph
- [ ] **M21 The city overhaul** — findings 5 and 6, plus the canal dropped out of M16.
      Calm zones of four blocks, so the lattice grows T-junctions and L-bends and can no
      longer be derived from a coordinate; main roads with traffic lights against side roads
      with zebras, where a main road is crossed rather than walked

## M10 — Polish · `feature/polish`

Not started. The game is complete without it; this is what would make it shippable.

- [ ] **Finish the visual channel — before audio, not after.** House rule: audio is never
      the only channel, so every cue that will become a sound must already work silently
      (docs/EVENTS.md, "Showing the danger"). Two gaps, in priority order:
  - [ ] **HUD band for `city_wide` sources.** The loudspeaker masts from day 5 and the
        curfew announcement have *no* on-screen presence at all — `EventAuraLayer` skips
        them (a field with no edge cannot be a ring) and nothing took over. The player
        sees excitement refusing to drain and nothing says why. Most misleading thing in
        the game right now.
  - [ ] **Screen-edge indicator for fast movers.** `fire_truck` and `military_convoy` are
        built around a long telegraph spent getting off that street, but at 190px/s most
        of that warning happens off-screen where the ring cannot be seen.
  - [ ] **Sound lines.** Concentric arcs thrown off a source on a pulse's rising edge —
        the visual form of a discrete noise. Would give the yeller, the dog and the
        reversing van a readable "that just happened" beat rather than only a swell.
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

- [~] **Is the balance right?** *(M14 pitched it against the day rather than against itself;
      M18 then re-pitched it against a **minute of play**: day 330s → 180s,
      `SLEEPINESS_GAIN_WALKING` 0.24 → 0.42, calm 3.5x → 10x, idle drain 0.6 → 1.0. A whole
      day of street walking reaches 76 of 100 and a calm stretch takes 24s.)* The open
      question is now the opposite one: with the meter this generous once calm ground is
      reached, is anything standing between the player and a won day? That is what M19 and
      M20 are for, and the next playtest should judge them together.
- [ ] **Is 14 days the right run length?** Act I is only 3 days, which may be too little
      time to learn a city before it starts changing.
- [ ] **How visible should the resistance be to a player ignoring it?** Right now: a chalk
      mark and one HUD line. Real risk that a player finishes a run never knowing the good
      ending existed. That might be correct, or it might be a bug.
- [ ] Should running ever be *required* (a forced chase), or always purely a player choice?
- [ ] Should there be a diegetic-only mode — a baby's face instead of two bars?
- [ ] Does a lost day advancing the calendar feel right, or should it repeat the day?
      *(Current: advances, which makes Nerves the real resource.)*
