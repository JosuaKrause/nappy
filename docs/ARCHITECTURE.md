# Nappy — Architecture

Godot 4.7, GDScript. 2D scene tree with y-sorting for the 2.5D look.

## Directory layout

```
project.godot
icon.svg
docs/                     design documentation (this folder)
scenes/
  main.tscn               root: boots GameState, holds World + HUD
  world/city.tscn         generated city container
  player/stroller.tscn    the mother + stroller CharacterBody2D
  ui/hud.tscn             meters, clock, nerves
  ui/day_summary.tscn     between-day screen
src/
  autoload/
    tuning.gd             all balance constants           (autoload: Tuning)
    event_bus.gd          global signals                  (autoload: EventBus)
    game_state.gd         run/day/nerves/resistance       (autoload: GameState)
  player/
    stroller.gd           movement, input, speed state
    baby.gd               the two meters + baby state machine
  city/
    city_map.gd           tile data, queries (is_calm, is_alley, walkable)
    city_generator.gd     seeded generation
    city.gd               the scene: ground, buildings, props, boundary
    building.gd           one lot, assembled from 32px facade and roof tiles
    ground_tiles.gd       which ground tile a cell gets
    tile.gd               TileType enum + per-tile metadata
  events/
    event_def.gd          authored event data
    event_instance.gd     runtime node: position, lifetime, telegraph, emission
    event_catalogue.gd    every event, defined in code
    event_scheduler.gd    builds a day's event set from seed + day
    event_manager.gd      owns the live instances; answers total_excitement_at
    event_aura_layer.gd   draws the excitement fields under the entity layer
  ui/
    hud.gd
    meter_bar.gd
  dev/
    auto_screenshot.gd    render N frames, save a PNG, quit
  palette.gd              colours the code still chooses; the art's own are in the SVGs
  sprites.gd              feet-anchored draw helpers (standing sprite, contact shadow)
assets/
  tiles/                  ground tiles, 32x32 SVG
  buildings/              facade and roof tiles, 32x32 SVG
  rig/                    the mother and the pram, per direction
  props/                  trees, the swing frame, the door, the shadow
  events/                 one body per EventDef.Look
  ground_tileset.tres     one TileSetAtlasSource per ground tile
  game_enums.gd           shared enums (see below)
tools/
  check.sh                import + headless boot, fails on any script error
  shot.sh                 render the game to a PNG
```

### `GameEnums`

An autoload's name cannot also be a `class_name`, so the enums that signals and exports
need to annotate (`BabyState`, `DayResult`, `Ending`, `EventKind`, `TileType`, `District`)
live in `src/game_enums.gd` rather than on `GameState`.

### Verifying visuals

A headless run never calls `_draw()`, so `tools/check.sh` passing says nothing about
whether the game renders correctly. `tools/shot.sh out.png [frames]` runs the game
windowed, saves the viewport after N frames and quits.

## Autoloads

### `Tuning`
Pure constants + `validate_event()`. No state. Everything balance-related lives here so a
designer touches one file.

### `EventBus`
Global signal hub. Decouples systems that should not know about each other.

```gdscript
signal excitement_changed(value: float)
signal sleepiness_changed(value: float)
signal baby_state_changed(state: Baby.State)
signal day_started(day: int)
signal day_ended(result: GameState.DayResult)
signal event_telegraphed(instance: EventInstance)
signal event_activated(instance: EventInstance)
signal event_finished(instance: EventInstance)
signal hard_fail_triggered(reason: String)
signal resistance_progress_changed(value: int)
```

### `GameState`
The run. Owns `run_seed`, `day`, `nerves`, `resistance_progress`, `consumed_one_shots`.
Handles day transitions and ending selection. Serialisable for save/continue.

## WorldContext

`Baby` never learns what a tile or an event is. It asks a `WorldContext` three questions —
`is_calm_zone()`, `is_alley()`, `total_excitement_at()` — and that is the entire surface
between the meters and the world. The debug world answers with hand-placed test data; M3's
generated city and M4's event manager answer for real. Adding an event type therefore never
touches the meter code, and the meters can be unit-tested against a fake world.

## Excitement aggregation

`Baby` does not know about event types. Each frame it asks the world for total stimulus:

```gdscript
# EventManager keeps a list of active EventInstances
func total_excitement_at(pos: Vector2) -> float:
    var sum := 0.0
    for inst in _active:
        sum += inst.contribution_at(pos)
    return sum
```

`EventInstance.contribution_at()` implements the falloff from `docs/MECHANICS.md` and
applies the telegraph fraction if the instance is still in its telegraph phase. Adding an
event type never requires touching `Baby`.

The scan is linear. An earlier draft of this document called for a uniform spatial hash;
the budget formula tops out near 22 concurrent events, so that would have been more code
and more ways to be wrong in exchange for nothing measurable. Revisit if an act ever wants
hundreds of sources.

## Determinism

Two independent RNG streams, both derived from `run_seed`:

- `RNG_CITY = RNG(run_seed)` — used once, at run start, for layout.
- `RNG_DAY = RNG(hash(run_seed, day_index))` — re-created every day for event selection.

Nothing gameplay-relevant may use the global `randi()`. A day replayed with the same seed
and day index produces the identical event set — required for the "learn the run" design.

Cosmetic-only randomness (leaf flutter, NPC idle animation) may use the global RNG, and is
kept strictly out of anything that touches the meters.

## Rendering / 2.5D

- `city.tscn` root has `y_sort_enabled = true`; so do the prop containers.
- Ground: a `TileMapLayer` fed by `GroundTiles`, which is the only place that decides which
  tile a cell gets. Source ids in `assets/ground_tileset.tres` are positional and
  `ground_tiles.gd` mirrors them by hand — adding a tile means appending to both, in order.
- Buildings: `StaticBody2D` whose collision is the whole lot, plus a `_draw()` that
  assembles that same lot out of 32px tiles — a front wall (the southern `height` px) and a
  roof (the remainder). Fitting the mass inside the lot is what keeps extrusions off the
  street — a roof drawn *overhanging* northward would hide the player whenever she walked
  along that sidewalk. A taller building therefore shows more wall and less roof, which is
  what an oblique view of a taller building should look like.
- Building heights are quantised to whole tiles, because a tiled facade cannot honour a
  float height without stretching a tile. `Building` clamps the requested height itself, so
  a caller cannot ask for a wall that eats the roof.
- Fills are authored near-white and drawn with the variant colour as `draw_texture`'s
  modulate; windows, plinth and parapets are overlays drawn at full colour on top. One set
  of assets therefore covers every building colour.
- The player's `position` is the *feet*, and drawing is offset upward from there. This
  keeps y-sort and collision consistent. `Sprites.draw_standing()` is the single place that
  rule is written down; everything that stands on the ground goes through it, along with
  `Sprites.draw_shadow()` for the contact shadow.
- A single `Camera2D` on the player, with `position_smoothing_enabled` and a small
  look-ahead in the movement direction.

## Testing

`tools/test.sh` runs `tests/tests.tscn` headless. It is run as a *scene*, not via
`--script`: `--script` replaces the main loop, which skips the autoloads, and every test
needs `Tuning`. The runner loads every `tests/test_*.gd`, calls its `run(t)`, and exits
non-zero on any failure.

- `test_meters.gd` — falloff shape, the telegraph fairness contract, and every meter rule
  in docs/MECHANICS.md, driven at a fixed timestep against a fake world. *(done)*
- `test_generator.gd` — 200 seeds: connectivity, park count/spread, home-to-park distance,
  exact building coverage, and route redundancy under street closures. *(done)*
- `test_events.gd` — catalogue fairness, the emission model (telegraph damping, pulse
  envelope, duration, paths, hard-fail gating), and scheduler determinism, placement,
  one-shot consumption and the usable-park rule.
- `test_event_manager.gd` — the manager against a real generated city: retirement,
  successors, summed excitement. Wiring bugs live here and are invisible to data tests.
- `test_acts.gd` — act gating, the arterial handover, city-wide sources, protest growth,
  scar persistence, and walkability under accumulated street closures.
- `test_day_loop.gd` — the two phases, all four day outcomes, nerves, ending selection.
- `test_resistance.gd` — the step table, the hold (driven through simulated input), the
  seeded alley roulette, the expiring step, and the sabotage silencing the city.
- `test_full_run.gd` — three seeds played through all 14 days with the real City,
  EventManager and ResistanceDirector, with time actually advancing. This is the check
  that catches "day 12 throws", which no amount of unit coverage does.

These are the places a bug is invisible until it ruins a run, so they are the places with
tests. Anything a screenshot would catch is checked with `tools/shot.sh` instead.
