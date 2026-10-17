# teal-trout — the chargers' rest and alert poses, first review sheet

The poses asked for in [teal-trout](../../todo/2026-10-11-teal-trout/README.md) (every charger is
neutral, then warns, then charges), drawn as SVG and laid side by side before anything is wired
into the game. These sheets show the **front and side** views only; the back and both diagonals
are on the next sheets, [teal-trout-views-2026-10-17](../teal-trout-views-2026-10-17/README.md).

Each sheet has two blocks on the sidewalk ground colour (`Palette.SIDEWALK`, `#8b8478`): on top
at **game scale** (1x, the SVG's own pixel size), below **enlarged six times**. In each block the
columns are, left to right:

| Column | Dog (`dog-v1.png`) | Robber (`robber-v1.png`) | Guard (`guard-v1.png`) |
|---|---|---|---|
| **neutral** | `charging_dog_resting` — **new**: sitting on the ground, ears soft, back smooth, jaw shut, tail lying down | `robber_waiting` — today's: hood up, hands in his coat | `guard_standing` — today's: at his post, arms down |
| **alert** | `charging_dog_alert` — **new**: four stiff straight legs, head high, ears pricked, hackles up, teeth shown with the jaw shut | `robber_alert` — **new**: both hands out of the coat, held low and open, feet set | `guard_alert` — **new**: square-on, one hand raised palm out at head height |
| **charge** | `charging_dog` — today's gallop, frame a | `robber_lunging` — today's | `guard_lunging` — today's |

The dog's rows are side then front (its side picture is its main one); the robber's and the
guard's are front then side. The charging dog today waits in the charge column's picture, frame a
of its gallop, which is the "looks like it's flying" the player saw; the neutral column is what
would replace it. The open red jaw is kept for the charge alone, so the alert shows teeth but not
the bite. None of the alerts carries a mark, a ring or a colour from the danger cues: the pose is
the whole of the change.

The guard's alert is the one picture for both the hunting roadblock's guard and the door guard,
as the entry proposes; the door guard's neutral is the hut guards already at their posts.

## How the sheets are made

`render-sheet.gd` loads each SVG through the engine's own parser (`Image.load_svg_from_string`)
at each scale and stands every picture on one ground line per row, centred in its column, the
way a standing sprite is grounded at its bottom centre. A sheet's spec (`dog-v1.json` and the
others) lists its rows and scales. To rerun, from the repository root with any Godot 4.7 project
as `--path` (a scratch one with only a `project.godot` is enough), writing to a fresh file:

```sh
godot --headless --path <scratch project> \
  --script docs/evidence/teal-trout-poses-2026-10-11/render-sheet.gd -- \
  --repo "$PWD" --spec docs/evidence/teal-trout-poses-2026-10-11/dog-v1.json \
  --output <scratch dir>/dog.png
```

A delivered sheet is never overwritten; a revision is a new file with the next version number.
