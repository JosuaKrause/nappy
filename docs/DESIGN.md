# Nappy — Design Document

## Logline

You are a mother with a baby in a stroller. The baby will not sleep. You walk the city
until it does, then walk home. Over the days, the city stops being a nice place to walk.

## Design pillars

1. **The route is the puzzle.** The player's only real verb is "where do I walk". All
   tension comes from choosing a path through a known city full of partially-known noise.
2. **Knowledge compounds across days.** The city layout is fixed for the whole run. Day 1
   teaches you the map; day 9 you are running a memorised route through a warzone.
3. **The city tells the story, not cutscenes.** Escalation is expressed as new event types
   appearing in the same familiar streets.
4. **Quiet is a resource.** Parks and calm streets are the "safe tiles", but they are
   contested — random events can spoil them, so there is no single memorised safe answer.

## Core loop

```
        ┌──────────────────────────────────────────────────┐
        │                    ONE DAY                       │
        │                                                  │
   Home ├─▶ walk the streets ─▶ avoid excitement ─▶ ...    │
        │        ▲                     │                   │
        │        │                     ▼                   │
        │        └── redirect ◀── obstacle telegraphed      │
        │                              │                   │
        │                              ▼                   │
        │                    sleepiness reaches 100        │
        │                              │                   │
        │                              ▼                   │
        │              carry the sleeping baby home        │
        │              (excitement can still wake it)      │
        └──────────────────────────┬───────────────────────┘
                                   ▼
                          day summary → next day
                       (world escalates one notch)
```

A **run** is a full game session of `RUN_LENGTH_DAYS` days (default 14).
A **day** is one level: leave home, get the baby asleep, return home.

## Win / lose

### Day-level

| Outcome | Condition |
| --- | --- |
| **Day won** | Baby reaches `sleepiness = 100`, then the stroller returns to the home tile with the baby still asleep. |
| **Day lost** | `excitement` reaches 100 → the baby starts crying and cannot fall asleep this day. |
| **Day lost** | A hard-fail event fires (e.g. alley robbery, being abducted). |
| **Day lost** | The day timer runs out (dusk). |

Losing a day is not losing the run. It costs one point of **Nerves** (start of run: 3).

### Run-level

| Ending | Condition |
| --- | --- |
| **Bad ending** | Nerves hit 0 — the mother breaks, leaves the city, nothing changes. |
| **Neutral ending** | Survive all `RUN_LENGTH_DAYS` days without joining the resistance. The regime consolidates; you and the baby endure. |
| **Good ending** | Reach `RESISTANCE_GOAL` resistance progress before the final day, then complete the final-day sabotage route. |

## The central tension

Sleepiness only rises while the baby is *calm and moving*. That means:

- **Standing still is not safe.** Idling calms the baby fast but drains sleepiness.
- **Running is not safe.** It covers ground but pumps excitement.
- **The only productive state is a normal walking pace on a quiet street**, which is exactly
  the state an obstacle interrupts.

So every event forces the same decision: *push through and eat the excitement, or stop /
detour and eat the lost time*. That decision is the game.

## Difficulty curve

Difficulty rises on three independent axes so later days feel different, not just harder:

| Axis | Day 1 | Day 14 |
| --- | --- | --- |
| Event density | sparse, cosmetic | dense, overlapping |
| Event severity | small radius, short | huge radius, moving, persistent |
| Map access | whole city walkable | checkpoints and barricades close routes |

## Non-goals

- No combat. The player never fights.
- No inventory or upgrades. Skill is map knowledge and timing.
- No dialogue trees. Resistance interactions are one-button, positional.
