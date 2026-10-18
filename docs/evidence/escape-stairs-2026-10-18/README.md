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

## The stairwell guard's charge distance

**The claim.** The masked man at the foot of the right shaft runs once she is within 426px of him.
Coming down from the second floor, she meets that at the head of the second flight. From there, a
walker making for the first floor's door is caught when she takes the flight holding plain left
from the row level with its head tread or the row below, or down-left from the landing tile between
the two flights; a walker who holds plain left from that landing tile gets through. A runner gets
through on every line. The margins are thin: on the tightest runner's line (walking until he runs, then
running, turning plain left at row 11's centre) he is drawn about 25px from her centre (24.6px at
60, 120 and 150fps; `FRAMES_PER_TICK=4` or `5` in the environment steps the probe at the last two),
inside the 28px catch, and she clears it on the tick at 28.6px, by 0.6px; she is caught
if she starts running 0.3s after he does. In the stairwell his warning is off screen, and only the
edge badge shows his charge once he runs.

- `stairwell-guard-trigger-candidates.png`: the readings of "the end of the second stair" that were
  put to the player as a question.
- `guard-trigger-3.txt`: what `tests/probes/escape_stairwell_guard_trigger.gd` prints at the
  game's rhythm (a 30Hz physics tick for her, the catch and where he is told she is, and him moving
  on two 60fps frames between ticks), for the claim above, plain left from the landing tile between
  the two flights (`turn-9-left`) included. Each line ends `closest <c>px drawn, <k>px on a tick (the catch is 28px)`: the nearest he is
  drawn to her centre, then the nearest on a physics tick, the only moment the catch is checked
  (`guard-trigger-2.txt`'s lines end `closest <c>px`). The building is
  not seeded, so one seed is printed. Rerun: `tools/test.sh probes/escape_stairwell_guard_trigger.gd`.
- `guard-trigger-2.txt`: what the probe printed with her and him stepped together at 60Hz, on three
  seeds, before it was changed to the game's rhythm; the window it gives (420 to 432px) is that
  stepping's, and `guard-trigger-2.png` draws it. Each line gives the way she came, her pace,
  where she stood when he ran (in local tile units), how far she was from him, whether she got
  through the first floor's door, and how near he came. The first block is 426px; the next three are
  `CHARGES_WITHIN=420`, `432` and `440`. The seeds agree line for line.
- `guard-trigger-2.png`: the walkers' charge points over the right shaft's lower cells, with the
  426px circle round where he waits. Made by
  `python3 guard-trigger-2.py guard-trigger-2.txt out.png` (Pillow).
- `guard-charge-2.mp4`, its timing in `guard-charge-burst-2.json`, and `guard-charge-strip-2.png`
  (six of its frames). This is the game's own window: she walks down the right shaft's first flight
  and the landing, starts down the second flight, and runs. The readout's `nearest` line turns from
  `telegraph` to `active` between frames 13 and 17. He comes into view on his flight, and she runs
  on down and out through the first floor's door after the burst ends. Captured from `4f21c548`
  with this change in the working tree (its build label reads `-dirty`), with
  `tools/shot.sh out.png 11 --start-escape stairwell:right --press ui_accept 0.5 --walk
  1p3.5e0.4s0.4w3W1.2N --invincible --press snapshot_burst 4.6`, then
  `tools/clip.sh <burst> <out.mp4>`. `--invincible` stages the shot and also keeps the clock at
  3:00.

## The doors under her

**The claim.** Every door picture in the building is drawn under her. Before this, the stairwell
doors, the thresholds and the emergency exit stood in her y-sorted layer, so a door whose foot was
lower than hers was drawn over her.

- `doors-before-after.png`: two stills of her stepping onto an apartment's threshold on the second
  floor, cropped round her feet. The before is from `9454b831`, the after from this change. Both
  were captured with `tools/shot.sh out.png 3 --start-escape floor:2 --press ui_accept 0.5 --walk
  1p0.6s --invincible`. The two differ in light because the hallway's windows flash at their own
  moments.
