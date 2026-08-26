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

- [ ] `stroller.tscn` CharacterBody2D, walk/run, acceleration & friction
- [ ] Procedural 2.5D drawing of mother + stroller, feet-anchored
- [ ] Facing direction, stroller trails behind the mother
- [ ] `Camera2D` follow with smoothing + movement look-ahead
- [ ] Debug scene: flat ground + a few boxes to walk around
- [ ] Y-sorting verified (walk behind and in front of a building)

## M2 — Baby meters · `feature/baby-meters`

- [ ] `baby.gd`: sleepiness + excitement, all rates from `Tuning`
- [ ] Baby state machine AWAKE / ASLEEP / CRYING
- [ ] Calm-threshold freeze rule
- [ ] Running → excitement, idle → sleepiness drain
- [ ] Wake-up rule + sleepiness penalty
- [ ] `hud.tscn`: two meter bars, baby state indicator, day clock, nerves
- [ ] Debug overlay: live rates, current stimulus sources

## M3 — City generation · `feature/city-generation`

- [ ] `tile.gd` TileType enum + metadata table
- [ ] `city_generator.gd`: street grid, districts, alleys, parks, home
- [ ] Connectivity flood-fill + regeneration on failure
- [ ] Generation guarantees (park count, spread, home distance, dual routes)
- [ ] `city_renderer.gd`: procedural 2.5D buildings, ground, props
- [ ] Building collision bodies
- [ ] Calm zone + alley effects wired into `baby.gd`
- [ ] `tests/test_generator.gd` over 500 seeds

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
