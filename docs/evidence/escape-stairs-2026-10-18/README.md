# The escape building's stairs, 2026-10-18 (inbox #782, #783)

Evidence for pull request #787: walking a flight at 45 degrees (inbox #783) and the stairwell
guard's trigger (inbox #782).

## Walking a flight at 45 degrees

**The claim.** On main, a sideways press on a flight tile already steered exactly 45 degrees, but
her body zigzagged between flat and about 80 degrees. The stair sides' square corners lie on two
lines 22.6px apart across the slope, and her body is 28px across. On this branch her body walks
every flight of both shafts at 45 degrees, down and up. Off a stair, a landing included, a press
is left as it is.

- `steering-before.txt`, `steering-after-2.txt`: what `tests/probes/escape_stairs_heading.gd`
  prints, with main's `src/interior/interior_scene.gd` and `src/player/stroller.gd` (at `5f7923b6`)
  copied over this branch's for the before, and this branch's own for the after. Three line types:
  - `STAIRS`: every walkable tile of both shafts and nine presses, with the steering and the way
    she moves in 0.1s from rest at the tile's centre.
  - `WALK`: every flight held down and up from the landing tiles beside its ends, with her body's
    heading over each 0.1s and the worst departure from 45 degrees on the flight.
  - `TRACE`: her centre every frame down the left shaft's first flight.

  Rerun: `tools/test.sh probes/escape_stairs_heading.gd`.
- `body-path-before-after-2.png`: the `TRACE` lines drawn over the shaft's cells, her 14px body
  every half second in blue, and on the right the cut stair sides. Made by
  `python3 body-path.py steering-before.txt steering-after-2.txt out.png` (Pillow), a picture of a
  headless walk, not a screenshot.
- `walk-before.mp4`, `walk-after-2.mp4`, with their bursts' timing in `walk-before-burst.json` and
  `walk-after-burst-2.json`, and the strip `walk-burst-before-after-2.png` (eight of each burst's 36 frames, cropped around her, made by
  `walk-burst-strip.py`). They are the game's own window: she is held right from the right shaft's
  top landing down its first flight. Both were captured with
  `tools/shot.sh out.png 6 --start-escape stairwell:right --press ui_accept 0.5 --walk 1p4e
  --invincible --press snapshot_burst 1.1`, then `tools/clip.sh <burst> <out.mp4>`. `--invincible`
  stages the shot; nothing here is about cost. The before was built from this branch at `a14a8616`
  with main's two files copied in, and the after from `4bd68db5` with this change in the working
  tree (both build labels read `-dirty`). The camera follows her, so the
  difference shows in how she moves against the treads, and the path picture shows it more clearly.

## The stairwell guard's trigger

**The claim.** The masked man at the foot of the right shaft starts his run on the frame she first
stands on that shaft's first-floor landing, whichever way she comes to it. From there, the first
floor's door is her way out at a walk.

- `stairwell-guard-trigger-candidates.png`: the readings of "the end of the second stair" put to
  the player as a question. The player picked B, the first-floor landing of the right shaft.
- `guard-trigger.txt`: what `tests/probes/escape_stairwell_guard_trigger.gd` prints, on three
  seeds, for four ways to the landing, at a walk and at a run. Each line gives where she stood
  when he ran (in local tile units), how far she was from him, and whether she got through the
  first floor's door. The `late` lines walk on down for that many seconds first, then run back.
  The first block is this branch. The second is the alternative that was not built, measured with
  `TRIGGER_RADIUS=343`: no landing, and a 343px charge distance, the smallest circle that leaves no
  way to the door without setting him off. Rerun:
  `tools/test.sh probes/escape_stairwell_guard_trigger.gd`, and again with `TRIGGER_RADIUS=343` in
  the environment. The seeds agree line for line.
- `guard-trigger.png`: those charge points over the right shaft's lower cells, with the landing on
  the left and the circle on the right. Made by
  `python3 guard-trigger.py guard-trigger.txt out.png` (Pillow).
- `guard-charge.mp4`, its timing in `guard-charge-burst.json`, and `guard-charge-strip.png` (six
  of its frames). The game's own window: she is held down the right shaft's first two flights onto
  the first-floor landing, and then up into its door. The readout's `nearest` line turns from
  `telegraph` to `active` as she steps onto the landing (frame 14). The screen-edge badge comes up
  while he is still out of view, and he comes into view on his flight. Captured from this branch at
  `4d88c52c` with the item's change in the working tree (its build label reads `-dirty`), with
  `tools/shot.sh out.png 11 --start-escape stairwell:right --press ui_accept 0.5 --walk
  1p3.5e4.3@225@0.3p1.2n --invincible --press snapshot_burst 7.2`, then
  `tools/clip.sh <burst> <out.mp4>`. `--invincible` stages the shot and also keeps the clock at
  3:00. She steps through the door after the burst ends.
