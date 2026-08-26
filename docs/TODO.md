# Nappy — TODO

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done

Each milestone is one git branch, merged to `main` when green.

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
- [ ] Buildings taller than their lot depth would have no roof left to draw; `roof_depth()`
      clamps rather than warns. Make the generator enforce it instead (M3).

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

- [ ] `event_def.gd` Resource + `event_catalogue.gd`
- [ ] `event_instance.gd`: lifetime, telegraph phase, falloff contribution
- [ ] Spatial hash broad-phase
- [ ] `Tuning.validate_event()` fairness assertion
- [ ] Telegraph visuals: warning ring, icon, pre-audio
- [ ] `event_scheduler.gd`: budget, weights, one-shot consumption, determinism
- [ ] Park spoiling rules + "always one usable calm zone" validation
- [ ] `tests/test_falloff.gd`, `tests/test_scheduler.gd`

## M5 — Act I events · `feature/events-act1`

- [ ] `playground` (ambient), `busy_road` (ambient)
- [ ] `cat_dash` — the tutorial obstacle
- [ ] `dog_walker`, `delivery_van`
- [ ] `homeless_yeller` with pulsing intensity envelope
- [ ] `busker`, `construction` (emits **and** blocks)
- [ ] `fire_truck` one-shot: mobile siren + persistent burning building

## M6 — Day loop · `feature/day-loop`

- [ ] Home tile: start, and return-with-sleeping-baby goal
- [ ] Return phase after sleepiness hits 100
- [ ] Day timer / dusk light shift
- [ ] Win, cry-loss, timeout-loss, hard-fail-loss
- [ ] Nerves, run end at 0
- [ ] `day_summary.tscn` between days
- [ ] Persist run state across days

## M7 — Acts II–IV · `feature/acts`

- [ ] Per-act palette + ambient audio bed
- [ ] Act II: `police_patrol`, `poster_crew`, `loudspeaker`, `curfew_announce`, `checkpoint`
- [ ] Act III: `abduction` (hard fail), `empty_street`, `alley_robbery`, `night_raid`
- [ ] Act IV: `military_convoy` (leaves barricades), `protest`, `firefight`
- [ ] Persistent world scars (burnt building from day 3 stays)
- [ ] Checkpoint / barricade map post-processing + connectivity revalidation

## M8 — Resistance subquest · `feature/resistance`

- [ ] Chalk mark markers on alley walls
- [ ] Hold-to-interact
- [ ] The 6 subquest steps
- [ ] Robbery-vs-contact seeded alley roulette
- [ ] Seen-by-patrol penalty
- [ ] Timed step failure (contact lost permanently)
- [ ] Codex panel in the day summary

## M9 — Endings · `feature/endings`

- [ ] Bad ending (nerves 0)
- [ ] Neutral ending (day 14, resistance incomplete)
- [ ] Good ending (sabotage; zero ambient excitement floor on the last walk home)
- [ ] Epilogue screens

## M10 — Polish · `feature/polish`

- [ ] Audio: ambient beds, event cues, baby breathing/fussing
- [ ] Main menu, pause menu, settings
- [ ] Save/continue a run
- [ ] Accessibility: meter colourblind mode, telegraph time multiplier, reduced motion
- [ ] Controller support

---

## Open design questions

- [ ] Does a lost day advance the calendar, or repeat the same day? *(Current: advances —
      keeps the narrative moving and makes Nerves the real resource.)*
- [ ] Should the player see numeric meters, or only a stylised baby-face indicator?
      *(Current: bars, with a stretch goal of a diegetic-only mode.)*
- [ ] Is 14 days the right run length? Needs playtesting once M6 lands.
- [ ] Should running ever be *required* (a forced chase), or always purely a player choice?
- [ ] How visible should the resistance be to a player ignoring it? Risk: they finish a run
      never knowing the good ending existed.
