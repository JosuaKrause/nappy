# Nappy — Mechanics & Tuning

All constants live in `src/autoload/tuning.gd` (autoload name `Tuning`) so they can be
balanced in one place. Values below are the design intent; the script is the source of truth.

## The two meters

### Sleepiness (0 → 100)

The win meter. Fills only under the right conditions.

| Condition | Rate (per second) |
| --- | --- |
| Walking, excitement below calm threshold | `+2.2` |
| Walking, in a **calm zone** | `+2.2 × 1.75` |
| Running | `0` (never fills while running) |
| Idle / near-idle | `-1.6` (drains) |
| Excitement at or above `CALM_THRESHOLD` | `0` (frozen, never drains) |

**Key rule:** while `excitement >= CALM_THRESHOLD` (default `35`), sleepiness does not rise
at all. It does not drain either — the baby is just too interested in the world.

At `sleepiness = 100` the baby falls asleep and the day enters its **return phase**.

### Excitement (0 → 100)

The lose meter. Anything interesting in the world pushes it up.

Sources:

| Source | Contribution |
| --- | --- |
| Proximity to an active event | `intensity × falloff(distance)` per second |
| Running | `+ (speed − walk_speed) / (run_speed − walk_speed) × 9.0` per second |
| Standing in an alley | `+3.0` per second (slow, constant dread) |
| Sudden events (cat dash) | one-shot impulse on trigger |

Decay (applies whenever total incoming stimulus is below the decay rate):

| Player state | Decay per second |
| --- | --- |
| Idle | `−6.0` |
| Walking | `−3.5` |
| Running | `−0.5` |
| In a calm zone | decay × `1.6` |

At `excitement = 100` → **crying** → day lost.

## Baby state machine

```
        ┌────────────────────────────────────────────┐
        │                                            │
   ┌────▼────┐  sleepiness = 100   ┌────────┐        │
   │  AWAKE  ├────────────────────▶│ ASLEEP │        │
   └────┬────┘                     └───┬────┘        │
        │                              │              │
        │ excitement = 100             │ excitement ≥ │
        │                              │ WAKE_THRESH  │
        ▼                              └──────────────┘
   ┌─────────┐                     (sleepiness drops to 50,
   │ CRYING  │  day lost            back to AWAKE)
   └─────────┘
```

While `ASLEEP`:

- Sleepiness is pinned at 100.
- Excitement still accumulates, but from a *lower* baseline — a sleeping baby is harder to
  disturb. Incoming excitement is multiplied by `SLEEPING_SENSITIVITY` (default `0.55`).
- If excitement crosses `WAKE_THRESHOLD` (default `60`), the baby wakes: sleepiness resets
  to `WAKE_SLEEPINESS_PENALTY` (default `50`) and the day continues.
- If excitement reaches 100 while asleep, the baby wakes *crying* → day lost.

This makes the walk home a real second act rather than a victory lap.

## Movement

| Property | Value |
| --- | --- |
| Walk speed | `92 px/s` |
| Run speed | `168 px/s` |
| Acceleration | `700 px/s²` |
| Friction (deceleration) | `900 px/s²` |
| Idle threshold | speed `< 12 px/s` counts as idle |

Controls: arrow keys or WASD to walk, hold **Shift** to run, **E** to interact,
**Esc** to pause.

The stroller faces the movement direction and lags slightly behind the mother, so the
player can read direction at a glance.

## Excitement falloff

Each active event has an `intensity`, an `inner_radius` and an `outer_radius`.

```
contribution(d) = intensity                              , d <= inner_radius
                = intensity × (1 − t)²                   , inner < d < outer
                = 0                                      , d >= outer_radius
   where t = (d − inner_radius) / (outer_radius − inner_radius)
```

The quadratic falloff means the "danger zone" is felt well before it becomes severe, which
is what makes crossing the street a meaningful counterplay.

## Telegraphing

Every event has a `telegraph_time` (default `2.5 s`, longer for big events) during which:

- The event is **visible** (sprite, warning ring, audio cue).
- It emits at most `TELEGRAPH_INTENSITY_FRACTION` (default `0.15`) of its full intensity.

The design contract: *from the moment an event becomes visible, the player must have enough
time to walk out of its outer radius at normal walking speed.* Event authoring must satisfy

```
telegraph_time × walk_speed >= outer_radius − inner_radius
```

`Tuning.validate_event()` asserts this in debug builds so unfair events fail loudly.

## Calm zones

Parks, quiet squares and courtyards are `CALM` tiles. Inside them:

- Sleepiness gain ×`1.75`
- Excitement decay ×`1.6`

But calm zones are contested — see `docs/CITY.md` (spoiling) and `docs/EVENTS.md`.

## Alleys

Alley tiles apply a constant `+3.0/s` excitement trickle. They are shortcuts, and they are
where the resistance meets. Both facts are the point: the fastest route and the story route
are the ones that cost you the baby's calm.

## Day timer

Each day runs for `DAY_LENGTH_SECONDS` (default `330 s`, ~5.5 minutes) of in-game dusk.
Running out is a day loss. The timer is shown as a light-level shift rather than a number,
with an explicit clock in the HUD corner.

## Nerves

The run-level health bar. Starts at 3. Every lost day costs one. At 0 the run ends with the
bad ending. Nerves never regenerate — this is what makes an early bad day matter.
