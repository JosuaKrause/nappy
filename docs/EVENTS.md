# Nappy — Events

An **event** is anything in the world that pushes the excitement meter. Events are data
(`EventDef` resources) plus an optional behaviour script.

## Where events are defined

Defs are constructed in code, in `src/events/event_catalogue.gd`, not saved as `.tres`
resources. They are reviewable in a diff, they can be validated on load, and the fairness
contract can be asserted over the whole catalogue in a test. Nothing here needs an editor
to tune, and a catalogue that lives in one file is easier to balance than forty resources.

## EventDef fields

| Field | Meaning |
| --- | --- |
| `id` | Unique string key |
| `display_name` | For the day summary / codex |
| `kind` | `RECURRING`, `ONE_SHOT`, `SCRIPTED`, `AMBIENT` |
| `first_day` | Earliest day it can appear (1-based) |
| `last_day` | Latest day it can appear (`0` = never expires) |
| `weight` | Relative likelihood when the scheduler picks recurring events |
| `max_per_day` | Cap on simultaneous instances |
| `placement` | Which tile types it may spawn on |
| `intensity` | Peak excitement per second at the centre |
| `inner_radius` / `outer_radius` | Falloff geometry (px) |
| `duration` | Seconds active (`0` = whole day) |
| `telegraph_time` | Seconds of visible warning before full intensity |
| `pulse_period` | Seconds per intensity cycle (`0` = constant) |
| `mobile` / `speed` | Whether it moves along a path, and how fast |
| `hard_fail` | Whether contact ends the day immediately |
| `look` | How the instance draws itself |
| `act_tag` | Narrative act it belongs to, for palette/audio |

There is no `impulse` field. A "sharp spike" is just a short `duration` at high `intensity`
— which is exactly what a cat crossing the road *is* — and expressing it that way keeps the
entire excitement model a pure query with nothing pushing values at the baby.

### Kinds

- **`AMBIENT`** — permanently present, part of the map (playground, busy road).
- **`RECURRING`** — can be rolled on any eligible day, possibly many times in a run.
- **`ONE_SHOT`** — fires on exactly one day in the run, then never again (fire truck).
- **`SCRIPTED`** — the scheduler is told exactly which day it fires (story beats).

## Scheduling

```
EventScheduler.build_day(day_index, run_seed):
    rng = RNG(hash(run_seed, day_index))
    1. add all AMBIENT events for the current act
    2. add SCRIPTED events whose day == day_index
    3. roll ONE_SHOT events not yet consumed this run, gated by first_day/last_day
    4. fill remaining budget with RECURRING events by weight
    5. apply park spoiling rules  (docs/CITY.md)
    6. validate: a path from home to at least one usable calm zone must exist
```

The **event budget** grows with the day index: `budget = 3 + floor(day_index × 1.4)`.
Each event costs budget equal to its `intensity` tier, so late days are not just "more cats".

## Catalogue

### Act I — Normal life (days 1–3)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `playground` | AMBIENT | 1 | Static aura in every park. Loud (kids). The reason parks are not free wins. |
| `busy_road` | AMBIENT | 1 | Thin, long aura along arterial roads. |
| `cat_dash` | RECURRING | 1 | A cat sprints across the street in front of the stroller. Short telegraph (it's visible crouching first), sharp impulse, tiny radius. The tutorial obstacle. |
| `dog_walker` | RECURRING | 1 | Slow mobile NPC, small aura, barks periodically. |
| `homeless_yeller` | RECURRING | 1 | Stationary. Periodic yell **pulses** — intensity oscillates, so you can time a pass. Large radius. |
| `delivery_van` | RECURRING | 1 | Parked, reversing beeper. Medium constant. |
| `busker` | RECURRING | 2 | Park spoiler. Medium aura, pleasant but stimulating. |
| `construction` | RECURRING | 2 | Blocks a sidewalk **and** emits. Forces a reroute, not just a detour. |
| `fire_truck` | ONE_SHOT | 3 | Sirens, mobile along roads at high speed, huge radius. Drives to a burning building that then becomes a static high-intensity source for the rest of the day. Long telegraph (you hear it far away). |

### Act II — Something is off (days 4–7)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `police_patrol` | RECURRING | 4 | Mobile, slow, medium aura. Occasionally stops and idles. |
| `poster_crew` | RECURRING | 4 | Static. Low intensity. Cosmetic dread — regime posters going up. |
| `loudspeaker` | SCRIPTED | 5 | Public address masts activate. City-wide low-level excitement floor while active. |
| `resistance_contact` | SCRIPTED | 5 | Alley meeting. See below. |
| `curfew_announce` | SCRIPTED | 6 | Shortens the day timer by 20%. |
| `checkpoint` | RECURRING | 7 | Blocks a street. Passing near it is high excitement. |

### Act III — Disappearances (days 8–11)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `abduction` | RECURRING | 8 | Masked men, an unmarked van, a person taken. Very high intensity, long telegraph (the van idles first). **Entering the inner radius is a `hard_fail`** — you are taken too. |
| `empty_street` | AMBIENT | 8 | Inverts an ambient: some streets become *quieter* as people stop going out. |
| `alley_robbery` | RECURRING | 8 | Only in alleys. No telegraph beyond the alley's own dread. `hard_fail` on contact. This is the risk that makes the resistance route cost something. |
| `night_raid` | SCRIPTED | 10 | A building is raided. Static, enormous, and it *moves the crowd* — bystander NPCs flee outward. |

### Act IV — Open conflict (days 12–14)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `military_convoy` | RECURRING | 12 | Like `fire_truck` but slower, larger, and it leaves `BARRICADE` tiles behind it. |
| `protest` | RECURRING | 12 | Large, mobile, grows over time. Spoils squares. |
| `firefight` | SCRIPTED | 13 | Static, extreme, `hard_fail` inner radius. Closes a district. |
| `sabotage_run` | SCRIPTED | 14 | The good-ending finale route. |

## The emission model

An event never pushes a value at the baby. Each frame the baby asks the world for the total
stimulus at its position, and the world sums `contribution_at()` over the live instances:

```gdscript
func contribution_at(world_position: Vector2) -> float:
    return Tuning.falloff(global_position.distance_to(world_position),
            current_intensity(), def.inner_radius, def.outer_radius)
```

Because it is a pure query there is no ordering to get wrong, events compose by simple
addition, and an instance can be tested without a scene.

The lookup is a **linear scan**, not a spatial hash. The budget formula tops out around 22
concurrent events on the last day; 22 distance checks per physics frame is nothing, and a
hash would be more code with more ways to be subtly wrong. Revisit if an act ever wants
hundreds of sources at once.

## Telegraph contract

Every event must satisfy, at authoring time:

```
telegraph_time × WALK_SPEED >= outer_radius − inner_radius
```

i.e. *a player walking at normal pace, standing at the edge of the danger zone the instant
the event becomes visible, can get clear before it hurts.* `hard_fail` events get double
that margin. This is asserted in `Tuning.validate_event()`; a violation is a bug, not a
difficulty setting, and `tests/test_events.gd` checks the whole catalogue.

**`AMBIENT` events are exempt**, and have to be: they are permanent features of a fixed
map, so there is no moment at which they appear and nothing to warn about. The player
learns where the playgrounds are on day 1 and that knowledge holds for the whole run, which
is the point of a city that does not change.

## Showing the danger

Each live event's field is drawn on an aura layer between the ground and the y-sorted
entities — so a field never paints over a roof, and a building genuinely hides the field
behind it. The fill and ring track what the event is *currently* emitting, so a pulsing
event visibly breathes and the player can time a pass through it. Telegraphing events are
amber and flash; active ones are red; hard-fail ones are darker red.

## Keeping a day winnable

Two rules run after a day is planned:

- **At least one park is left unspoiled.** Whichever park has the fewest events reaching it
  has them removed. Ambient events do not count as spoiling — a playground makes a park
  *contested*, which is the design, and stripping one out every day would be absurd.

## Pulsing events

`homeless_yeller` and `protest` use an intensity envelope rather than a constant:

```
intensity(t) = base × (0.25 + 0.75 × pulse(t))
```

with a visible/audible tell on the rising edge. This rewards the player for *waiting and
watching* rather than just avoiding — a different skill from pure pathing.

## Adding a new event

1. Create `src/events/defs/<id>.tres` (an `EventDef`).
2. If it needs behaviour, add `src/events/behaviours/<id>.gd` extending `EventBehaviour`.
3. Register it in `src/events/event_catalogue.gd`.
4. Run the project — `Tuning.validate_event()` will reject unfair geometry on load.
