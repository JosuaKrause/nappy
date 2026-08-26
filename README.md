# Nappy

A 2.5D top-down game about a mother pushing a stroller through a city, trying to get her
baby to sleep.

- **Engine:** Godot 4.7
- **Genre:** Roguelike / route-planning
- **Core loop:** Walk a route → keep the baby calm → fill the sleepiness meter → return home.

The city is fixed for a whole run, so the map is knowledge you earn and keep. The noise in
it is not.

> **Spoilers:** everything under `docs/` describes the game's full arc, including things a
> player should meet for the first time in play. This README deliberately does not.

## Documentation

| Doc | Contents |
| --- | --- |
| [CLAUDE.md](CLAUDE.md) | How to work on this repo: workflow, engine gotchas, invariants |
| [docs/DESIGN.md](docs/DESIGN.md) | Pillars, core loop, win/lose conditions |
| [docs/MECHANICS.md](docs/MECHANICS.md) | Meters, movement, tuning constants |
| [docs/CITY.md](docs/CITY.md) | City generation, tile types, calm zones |
| [docs/EVENTS.md](docs/EVENTS.md) | Event catalogue, telegraphing, scheduling |
| [docs/NARRATIVE.md](docs/NARRATIVE.md) | Act structure, side content, endings — **spoilers** |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Code layout, autoloads, signals |
| [docs/TELEMETRY.md](docs/TELEMETRY.md) | What a run writes down, and how to read it |
| [docs/TODO.md](docs/TODO.md) | Milestones and task tracking |
| [docs/HANDOFF.md](docs/HANDOFF.md) | **Start here** — current state and what to do next |
| [docs/PLAYTEST-01.md](docs/PLAYTEST-01.md) | First playtest: findings, analysis, current plan |
| [docs/PLAYTEST-02.md](docs/PLAYTEST-02.md) | Second playtest: twelve findings, planned as M18–M26 |

## Running

```sh
./tools/run.sh                     # play
./tools/run.sh --seed 12345        # a specific city
./tools/run.sh --day 9 --overview  # look at a later act from above
```

`godot` is not on `PATH` on macOS — the binary lives inside the app bundle, so
`tools/run.sh` finds it for you. Override with `GODOT=/path/to/Godot tools/run.sh`.
Or open the project folder in Godot 4.7 directly.

## Controls

| Input | Action |
| --- | --- |
| Arrow keys / WASD | Walk |
| Hold Shift | Run (raises excitement) |
| E | Interact |
| Space | Continue, on the between-days screen |
| Esc | Quit |

## Dev flags

Everything after `--` is passed to the game:

```sh
godot --path . -- --seed 12345 --day 9 --overview
```

| Flag | Effect |
| --- | --- |
| `--seed N` | Regenerate a specific city |
| `--day N` | Start on a later day, to look at a later act |
| `--day-length N` | Compress the day, for dusk and the timeout loss |
| `--meters S E` | Seed the two meters, to screenshot a UI state |
| `--spawn park\|alley\|square\|playground` | Drop the player on a tile type |
| `--spawn event[:id]` | Drop the player beside a live event |
| `--follow <event id>` | Park a camera on an event wherever it goes |
| `--overview` | Frame the whole city at once |
| `--screenshot out.png --after N` | Render for N **seconds**, save a PNG, quit |
| `--no-telemetry` | Do not write a run log |

## Run logs

Every run writes a plain-text trace of what happened, in order — what was shut, where the
player went, what came near, how the day ended. `./tools/telemetry.sh` prints the newest one
(`-f` follows a run in progress, `-l` lists them). [docs/TELEMETRY.md](docs/TELEMETRY.md)
says what the entries mean.

## Verifying a build

`.godot/` is gitignored, so a fresh clone needs an import pass before `class_name` types
resolve. `tools/check.sh` does the import and then boots the project headless, failing on
any script error:

```sh
./tools/check.sh
```
