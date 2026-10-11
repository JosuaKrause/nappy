# The fire truck has a body

Evidence for jolly-hare, give the truck its body (calm-kestrel, inbox #558: "the fire truck has no
collision at all -- I can walk through it without it being lethal"; answered "Lethal driving, solid
parked").

`blocked.json` is a scene recipe built from `scene-recipes/fire-truck.json` (seed 11, context city
1917501, day 3): she walks west along the sidewalk to the fire, stands still while the engine
drives in from the east and parks at the kerb across from it, then walks south off the sidewalk into
its flank. It passes `tools/scene-recipes.sh --recipe docs/evidence/truck-body-2026-10-11/blocked.json`
headlessly. Each still was taken with

```sh
tools/shot.sh blocked-<seconds>.png <seconds> --recipe docs/evidence/truck-body-2026-10-11/blocked.json \
    --recipe-mode scripted --player-view --no-save --invincible --layers 3
```

on the branch's own source (`--invincible` because standing in the engine's field for long enough
ends the day by crying, after the recipe's last second; `--layers 3` draws the bounding boxes: the
engine's body, the capsule its shadow is drawn from, and her own body and pram circles).

- `blocked-5.5.png` to `blocked-7.0.png`: the engine drives to its kerb; the capsule moves with its
  picture.
- `blocked-7.4.png`, `blocked-7.9.png`: the engine has parked; her pram rests against its flank and
  she is stopped there, with nothing ending the day.

`warned.json` is built from the same scene: she walks west along the sidewalk past the junction
toward the fire, and steps off the sidewalk into the engine's lane between it and the kerb across
from the fire, once it is already driving in from the east. It passes
`tools/scene-recipes.sh --recipe docs/evidence/truck-body-2026-10-11/warned.json` headlessly, and
`warned-5.85.png` was taken with

```sh
tools/shot.sh warned-5.85.png 5.85 --recipe docs/evidence/truck-body-2026-10-11/warned.json \
    --recipe-mode scripted --player-view --no-save --invincible
```

- `warned-5.85.png`: the engine drives along her lane toward her, the doubled red caret over it
  (staying put in its lane would end the day) and the exclamation mark over her (it is closing on
  her within its warning). She stands between it and its kerb, so its course reaches her; past the
  kerb, neither cue goes up (`tests/test_fire_truck_body.gd`). `--invincible` because the strike
  follows a moment later. The mark flashes four times a second, so a still taken at another moment
  can catch it off.

The `blocked-*` stills are a sequence of ordinary captures at five times, not one in-game burst: a scene recipe
refuses `--press`, which is the only way a rig starts the burst (`B`), so no burst can run inside a
recipe.

What the stills cannot show: the timings and the contracts, which `tests/test_fire_truck_body.gd`
asserts (lethal in front only while it drives, with the car's warning first, created where the game
creates it from all four sides, and nothing of it past the kerb it parks at; solid and harmless beside it, behind it and once parked; its parked
field priced from its centre; the parked body closes no street on a real city; the loss reads its
own line and cause).
