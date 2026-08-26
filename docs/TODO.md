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
- [ ] `busy_road` is 14 separate instances. Fine for a linear scan, but a single
      polyline-shaped source would be tidier and cheaper.
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
- [x] `tests/test_acts.gd` (243 checks) — act gating, the arterial handover, city-wide
      sources, protest growth, scar persistence, walkability under closures
- [ ] Per-act ambient audio bed — no audio in the project yet (M10)

### Notes

- `busy_road` has `last_day = 7` and `quiet_road` `first_day = 8`, and a test asserts every
  day has **exactly one** arterial band. Overlapping them would silently double the noise
  on the main roads.
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
