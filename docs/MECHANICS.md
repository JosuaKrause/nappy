# Nappy — Mechanics & Tuning

All constants live in `src/autoload/tuning.gd` (autoload name `Tuning`) so they can be
balanced in one place. Values below are the design intent; the script is the source of truth.

## The two meters

### Sleepiness (0 → 100)

The win meter. Fills only under the right conditions.

| Condition | Rate (per second) |
| --- | --- |
| Walking, excitement below calm threshold | `+0.24` |
| Walking, in a **calm zone** | `+0.24 × 3.5` = `+0.84` |
| Running | `0` (never fills while running) |
| Idle / near-idle | `-0.6` (drains) |
| Excitement at or above `CALM_THRESHOLD` | `0` (frozen, never drains) |

**Key rule:** while `excitement >= CALM_THRESHOLD` (default `35`), sleepiness does not rise
at all. It does not drain either — the baby is just too interested in the world.

At `sleepiness = 100` the baby falls asleep and the day enters its **return phase**.

**Where a day is won.** These three numbers are pitched against the *day*, not against each
other, and they are what makes the walk the game:

- A whole day of undisturbed street walking reaches about **79** of 100. The street is real
  progress and can never be enough — so circling the starting block, which used to win a
  day outright, now cannot win one at all.
- A calm stretch clears the meter in about **119s**, and the walk out has already
  contributed. On the short 264s curfew day that leaves comfortably over a minute for
  getting there and getting home.
- Standing still drains faster than walking fills, so waiting is never a strategy — but it
  drains *slower* than a calm zone fills, so stopping to let something pass stays a move
  worth making.

The first two are asserted in terms of `day_length()` rather than as numbers
(`tests/test_meters.gd`), so lengthening the day cannot quietly make the street sufficient
again. `tests/test_balance.gd` then checks the same claim against a real city with that
day's crowd and events standing in it.

### Excitement (0 → 100)

The lose meter. Anything interesting in the world pushes it up.

Sources:

| Source | Contribution |
| --- | --- |
| Proximity to an active event | `intensity × falloff(distance)` per second |
| Proximity to a passer-by | `4.2 × falloff(distance)`, inner `22`, outer `88` |
| Proximity to a passing car | `5.4 × falloff(distance)`, inner `38`, outer `170` |
| Running | `+ (speed − walk_speed) / (run_speed − walk_speed) × 9.0` per second |
| Standing in an alley | `+3.0` per second (slow, constant dread) |
| Sudden events (cat dash) | one-shot impulse on trigger |

The crowd is the same kind of quantity as an event and is summed the same way, which is
what makes the **noise floor emergent**. There is no city-wide "background noise" number
anywhere; a street is loud in proportion to how busy it is, and a park is quiet because
nobody is in it. Both facts are visible on screen, which a constant never could be.

Excitement moves at the **net** rate, `incoming − decay`:

| Player state | Decay per second |
| --- | --- |
| Idle | `6.0` |
| Walking | `3.5` |
| Running | `0.5` |
| In a calm zone | decay × `1.6` |

Netting rather than "decay only when nothing is happening" is what makes the decay column
matter. Two consequences fall out of it, and both are wanted:

- **Standing still actively fights a loud event**, rather than merely not helping. Stopping
  is a real counterplay, paid for in drained sleepiness.
- **Sprinting past an event is far worse than walking past it** — running contributes
  excitement *and* drops decay to almost nothing, so the same event hits roughly three
  times as hard. Panic is punished twice.

It also sets a floor on what counts as an event: a source weaker than `3.5` cannot move
the meter on a walking player at all. That is deliberate — it is what lets an empty alley
apply constant *pressure* (`+3.0`) without ever being a threat on its own.

The crowd is pitched deliberately across that line. One person at arm's length is `4.2`,
just over the walking decay, so brushing past somebody costs — and the pavement is two
tiles wide, so *how close to pass* is a choice the player makes rather than a toll they
pay. One car is `5.4`, under the idle decay: no single car is dangerous. The danger is that
on a main road there is always another one, and the arterial's mean load sits between one
and three times the idle decay. Above three it fills the meter faster than the street can
be crossed, which is a street nobody can use rather than a route decision;
`tests/test_crowd.gd` holds both ends of that.

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

A telegraph the player cannot perceive is not a telegraph. **Every cue must be legible with
the sound off** — audio reinforces the warning, it never carries it (see docs/EVENTS.md,
"Audio is never the only channel"). `Tuning.validate_event()` checks the geometry and cannot
tell whether the player was actually warned, so that part is on the author.

The design contract: *from the moment an event becomes visible, the player must have enough
time to walk out of its outer radius at normal walking speed.* Event authoring must satisfy

```
telegraph_time × walk_speed >= escape_distance × margin
```

where `margin` is 2 for `hard_fail` events, and

```
escape_distance = outer_radius − inner_radius     for anything at or below walking pace
                = outer_radius                    for anything FASTER than walking
```

The split matters. A stationary event, or one slower than the player (a dog walker at
32 px/s), only has to be walked away from, so clearing the falloff band is enough. Something
faster than the player — a fire engine at 190 px/s — cannot be outwalked at all; it sweeps
its entire outer radius along the street, and the only escape is getting off its line. So
it must give enough warning to clear the *full* radius. That is why the fire engine's
telegraph is 4 seconds and not the 2.9 the band rule would have allowed.

`Tuning.validate_event()` asserts this on load, and `tests/test_events.gd` checks it over
the whole catalogue, so an unfair event fails loudly rather than quietly ruining a run.

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
