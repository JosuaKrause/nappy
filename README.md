# Nappy

A 2.5D top-down game about a mother pushing a stroller through a city, trying to get her
baby to sleep — while the city around her slowly slides into authoritarianism and civil war.

- **Engine:** Godot 4.7
- **Genre:** Roguelike / route-planning / stealth-of-noise
- **Core loop:** Walk a route → keep the baby calm → fill the sleepiness meter → return home.

## Documentation

| Doc | Contents |
| --- | --- |
| [docs/DESIGN.md](docs/DESIGN.md) | Pillars, core loop, win/lose conditions |
| [docs/MECHANICS.md](docs/MECHANICS.md) | Meters, movement, tuning constants |
| [docs/CITY.md](docs/CITY.md) | City generation, tile types, calm zones |
| [docs/EVENTS.md](docs/EVENTS.md) | Event catalogue, telegraphing, scheduling |
| [docs/NARRATIVE.md](docs/NARRATIVE.md) | Act structure, resistance subquest, endings |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Code layout, autoloads, signals |
| [docs/TODO.md](docs/TODO.md) | Milestones and task tracking |

## Running

Open the project folder in Godot 4.7, or:

```sh
godot --path . 
```

## Controls

| Input | Action |
| --- | --- |
| Arrow keys / WASD | Walk |
| Hold Shift | Run (raises excitement) |
| E | Interact |
| Esc | Pause |

## Verifying a build

`.godot/` is gitignored, so a fresh clone needs an import pass before `class_name` types
resolve. `tools/check.sh` does the import and then boots the project headless, failing on
any script error:

```sh
./tools/check.sh
```
