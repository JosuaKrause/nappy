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
    city_renderer.gd      procedural 2.5D drawing
    tile.gd               TileType enum + per-tile metadata
  events/
    event_def.gd          Resource: authored event data
    event_instance.gd     runtime node: position, lifetime, telegraph, emission
    event_behaviour.gd    base class for scripted behaviour
    event_catalogue.gd    registry of all EventDefs
    event_scheduler.gd    builds a day's event set from seed + day
    behaviours/           per-event scripts
  ui/
    hud.gd
    meter_bar.gd
  dev/
    auto_screenshot.gd    render N frames, save a PNG, quit
  palette.gd              colours for the procedural rendering
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

Broad-phase: instances register in a simple uniform spatial hash keyed by
`outer_radius`-sized cells, so the per-frame cost stays flat as event counts grow in Act IV.

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
- Buildings: `StaticBody2D` whose collision is the whole lot, plus a `_draw()` that fills
  that same lot with a front wall (the southern `height` px) and a roof (the remainder).
  Fitting the mass inside the lot is what keeps extrusions off the street — a roof drawn
  *overhanging* northward would hide the player whenever she walked along that sidewalk.
  A taller building therefore shows more wall and less roof, which is what an oblique view
  of a taller building should look like.
- The player's `position` is the *feet*, and drawing is offset upward from there. This
  keeps y-sort and collision consistent.
- A single `Camera2D` on the player, with `position_smoothing_enabled` and a small
  look-ahead in the movement direction.

## Testing

`tests/` uses plain GDScript scenes run headless via `godot --headless --script`:

- `test_falloff.gd` — falloff math and the telegraph fairness contract for every EventDef.
- `test_generator.gd` — 500 seeds: connectivity, park count/spread, home-to-park distance.
- `test_scheduler.gd` — determinism, budget bounds, at-least-one-usable-calm-zone.

These are the three places a bug is invisible until it ruins a run, so they are the three
places with tests.
