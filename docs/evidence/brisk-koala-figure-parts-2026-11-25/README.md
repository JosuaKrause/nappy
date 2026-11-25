# brisk-koala: figures whose idle frame moves part of them keep their still pixels still

**Claim.** The busker's strum, a café sitter's lean, a poster crew's brush and a firefight's muzzle
flashes redraw only what moves: the owner's picture, a café's slice and table, a firefight's
gunmen and shadow and every static span are not drawn again for a swap or a flash. The look is
unchanged within raster rounding. Whole-frame time on days 1 and 4 is unchanged within the noise
of the runs, so the work removed is measured on its own, by counting redraws.

**Limits.** The parity sheets cover the eleven split pictures, and three game stills cover the busker and the café (`ingame/`, below); the firefight's flashes are drawn
by the same calls in the same order as before (each now on its gunman's slice front, a child drawn
straight after the slice) and have no still of their own, since day 13 is the one day it is sited.
The frame-record runs are days 1 and 4 on one seed and one walk, and measure the figure split at
`161195c1d`, before the firefight's flashes moved: no firefight is sited on either day.

## In the game

`ingame/`: stills of the running game on `main` (`c051a7de8`, left) and on the branch (right) at the
same seed, day and spawn, each cropped about the event and doubled with no smoothing. Each is
`tools/shot.sh <out> 3 --seed <s> --day 2 --spawn event:<row> --invincible --no-save`, 1280x720,
three seconds in; the branch at the commit that adds this folder.

- `busker-square-east.png`: seed 1, `event:busker`, a busker on a square facing east.
- `cafe-ew-street.png`: seed 1, `event:cafe_tables`, a café on an east–west street.
- `cafe-ns-street.png`: seed 2, `event:cafe_tables`, a café on a north–south street.

Each pair is the same picture but for which idle frame the still landed on: the parts stand on the
figure's feet, each sitter is under its table, and the shadow is under the figure. A still shows
neither the swap nor its timing; the counts below do. **Not in a game still:** a busker facing
west, which the game never sites (he stands on a park or a square, which has no sidewalk side to
turn him, so `PlanBuilder.build()` leaves him facing east), and a poster crew seen from behind,
sited from her walk (`WalkSiting`), which neither `--spawn event:poster_crew` (it refuses a row sited
from her walk), a scene recipe (its placement takes no poster crew) nor the seed-67 walk on day 4
put on screen. The mirror and the back view are held by `tests/test_scenery_animation.gd` and the
parity sheets.

## Files

- `layers.json`: the reviewed extraction record of `tools/split-scenes.py --metadata-output`.
- `parity/`: `SCENERY_COMPARISON_OUTPUT=<dir> ./tools/test.sh probes/scenery_animation_art.gd`,
  the figure stems kept: each composite of the parts against its complete source, original left,
  composite right, both frames; at most one alpha level and about two premultiplied levels apart.
  Source revision `161195c1d`.
- `results/idle-redraws-main-c051a7de8.txt`, `results/idle-redraws-branch.txt`: the
  `IDLE_REDRAWS` lines of `./tools/test.sh probes/brisk_koala_idle_redraws.gd`, run on `main`
  at `c051a7de8` (the probe file copied into a checkout of it) and on this branch at the commit that
  adds them. Ten seconds of each event's own clock, the mast one broadcast cycle (22 s); the counts
  follow the event's clock, so they are the same on every run.
- `run.sh`, `analyse.py`: the alternating frame-record harness of m159-offscreen-2026-10-11 on
  days 1 and 4, hashing the files this work changes. `results/runs.tsv` is what it recorded per
  run (revision, start, the 1-minute load average, other Godot processes running),
  `results/per-run.tsv` and `results/conditions.txt` what `analyse.py` printed from the 24
  frame records (`run.sh /tmp/brisk-koala-frames 3 main=c051a7de8 branch=161195c1d`). The gzipped
  records themselves stay in scratch space.

## Redraws removed (`_draw()` calls of the event's canvases, and the pictures they laid)

| Case | `main` | branch |
|---|---|---|
| Busker, either view (10 s) | event 40, 40 pictures | event 0; moving layer 40, 40 textures |
| Poster crew, back view (10 s) | event 25, 25 pictures | event 0; moving layers 50, 50 textures |
| Poster crew, front view (10 s) | event 25, 25 pictures | nothing |
| Café, either street (10 s) | event 6, slices 12, 24 pictures | event, slices and tables 0; moving layers 12, 12 textures |
| Firefight (10 s) | event 600, slices 1200, 1200 pictures | event and slices 0; fronts 1200, flashes only |
| Burning building (10 s) | event 600, 3600 pictures | the same: not split |
| Loudspeaker mast (22 s) | event 2, 5 pictures | the same: not split |

The busker's and the crew's moving layers draw once a swap where the whole figure and its shadow
did; the crew's front view, whose two frames are one picture, stops redrawing at all. A café's
lean redraws one small layer per table instead of every table, sitter and the shadow. The
firefight stops laying both gunmen on every frame and keeps only its two flashes, which are two
circles each.

**Not split, by the counts above.** A street fire's flames all change height on every frame, so the
event's canvas redraws every frame whatever is split; its smoke is the only part that holds still
between swaps, one picture in six on open ground, and the fire is one instance on day 3. A mast's
lamp redraws the mast twice a broadcast cycle, five pictures in 22 seconds.

## Whole frame (medians of three runs, microseconds per frame; `results/conditions.txt`)

| Condition | frame median, `main` → branch | `_draw()` calls of events and scenery per frame |
|---|---|---|
| headless day 1 | 7266 → 7234 | 0.5 → 0.4 |
| headless day 4 | 7407 → 7389 | 0.4 → 0.3 |
| windowed day 1 | 3452 → 3493 | 0.4 → 0.2 |
| windowed day 4 | 3669 → 3635 | 0.4 → 0.2 |

Every difference in frame time is inside the range of one revision's own three runs, so the change
is not visible in a whole frame on these days; the redraw counts above are where it shows. The
windowed renderer's draw calls stay within two of each other (`conditions.txt`). The 1-minute load
average was between 2.0 and 4.1 at the start of every run, no other Godot process was running at
any start, and `main` and the branch alternated run by run.

Native macOS, Apple M2, Godot 4.7.2.
