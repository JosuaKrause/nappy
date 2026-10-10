# The police car is solid and lethal only in front of it while it drives

Evidence for sunny-finch, settle and build the hitbox (azure-koala, finding 8: "police cars don't
have a hitbox"; leafy-puffin, inbox #648: "yes to the police car hitbox").

Both stills come from the scene recipes beside them: seed 11, context city 1917501, day 5, a
`police_patrol` placed mid-block on the east-west carriageway at world (2000, 2768), driving east
at 74px/s, clear of the junctions' zebras and lights, with no crowd and no other events. Each was
taken with

```sh
tools/shot.sh <still>.png <capture_at> --recipe docs/evidence/police-car-2026-10-10/<scene>.json \
    --recipe-mode scripted --player-view --no-save --invincible [--layers 3]
```

on the branch's own source, the window covered, so each frame was drawn on demand. Both recipes
pass `tools/scene-recipes.sh --recipe <scene>.json` headlessly.

- `against-the-flank.png` (`against-the-flank.json`, 2.0s, `--layers 3`): she waits on the
  sidewalk, then walks south into the car as it passes. The bounding-box layer draws the car's body
  — the capsule its shadow is drawn from, centred under its picture — and her own body and pram
  circles: her pram rests against the car's flank, stopped there while the car drives on, and
  nothing strikes her. The recipe's observations hold her at y 2734 at tick 60, the patrol within
  40px of her and moving. No patrol state parks at a kerb; the car is stood against while it drives
  past.
- `in-front.png` (`in-front.json`, 1.75s): she stands in its lane ahead of it, facing it. The
  amber exclamation mark over her is the car's warning, up `Tuning.CAR_HORN_TIME` of its travel
  before the strike, and the doubled red caret over the car, which stands over its picture as it
  does over any other, says staying put ends the day. Played on for longer, the same scene ends the
  day at tick 57 (1.9s), the car's strike, which is why the recipe stops at 1.8s.

What the stills cannot show: the timings, which `tests/test_police_car.gd` asserts (the warning
lasts the horn time and is longer than walking off the carriageway; the strike fires before the
car would stand for her; the car never comes into her from any side; it never reverses onto her;
it gives way at a zebra and a red light; it leaves without vanishing beside her).
