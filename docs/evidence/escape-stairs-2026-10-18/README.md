# The escape building's stairs, 2026-10-18 (inbox #782, #783)

Evidence for pull request #787: walking a flight at 45 degrees (inbox #783) and the stairwell
guard's trigger (inbox #782).

## Walking a flight at 45 degrees

**The claim.** On main, a sideways press on a flight tile already steered exactly 45 degrees, but
her body zigzagged between flat and about 80 degrees. The stair sides' square corners lie on two
lines 22.6px apart across the slope, and her body is 28px across. On this branch her body walks
every flight of both shafts at 45 degrees, down and up.

- `steering-before.txt`, `steering-after.txt`: what `tests/probes/escape_stairs_heading.gd`
  prints, with main's `src/interior/interior_scene.gd` and `src/player/stroller.gd` (at `5f7923b6`)
  copied over this branch's for the before, and this branch's own for the after. Three line types:
  - `STAIRS`: every walkable tile of both shafts and nine presses, with the steering and the way
    she moves in 0.1s from rest at the tile's centre.
  - `WALK`: every flight held down and up from the landing tiles beside its ends, with her body's
    heading over each 0.1s and the worst departure from 45 degrees on the flight.
  - `TRACE`: her centre every frame down the left shaft's first flight.

  Rerun: `tools/test.sh probes/escape_stairs_heading.gd`.
- `body-path-before-after.png`: the `TRACE` lines drawn over the shaft's cells, her 14px body
  every half second in blue, and on the right the cut stair sides. Made by
  `python3 body-path.py steering-before.txt steering-after.txt out.png` (Pillow), a picture of a
  headless walk, not a screenshot.
- `walk-before.mp4`, `walk-after.mp4`, with their bursts' timing in `walk-*-burst.json`, and the
  strip `walk-burst-before-after.png` (eight of each burst's 36 frames, cropped around her, made by
  `walk-burst-strip.py`). They are the game's own window: she is held right from the right shaft's
  top landing down its first flight. Both were captured with
  `tools/shot.sh out.png 6 --start-escape stairwell:right --press ui_accept 0.5 --walk 1p4e
  --invincible --press snapshot_burst 1.1`, then `tools/clip.sh <burst> <out.mp4>`. `--invincible`
  stages the shot; nothing here is about cost. The before was built from this branch at `a14a8616`
  with main's two files copied in (its build label reads `-dirty`). The camera follows her, so the
  difference shows in how she moves against the treads, and the path picture shows it more clearly.
- `stair-steering-before-after.png`: the steering of a right or left press on every tile of the
  left shaft, before and after landing tiles started turning a press onto the flight they step
  onto. It shows steering arrows, not her body's path.

## The stairwell guard's trigger

- `stairwell-guard-trigger-candidates.png`: the readings of "the end of the second stair" put to
  the player as a question. The player picked B, the first-floor landing of the right shaft.
