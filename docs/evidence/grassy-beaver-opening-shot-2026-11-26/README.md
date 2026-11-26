# The opening shot, day 1's camera on the park and the way home

**Claim.** On day 1's first attempt, pressing the title's button cuts the view to the tutorial park,
rests there, follows the tutorial route back at one pace to her door and hands the view to her own
camera; the walking line then shows, and the crowd has no car near her door when the view arrives.
**Limits.** One seed (4242), one machine, a windowed run at 1280x720 under load (a burst holds fewer
than 36 frames when the run is slow: the frame counts are in each `burst-*.json`). The three bursts
are three runs of the same seed, so the crowd's walkers differ between them; each sheet shows six
frames evenly spaced over its burst. Her first step is not in the frames: the rig's `--walk` script
does not move her until play has begun, and the burst of the hand-back ends before a step is seen.
Whether the shot reads is the player's run (`docs/review/`).

**Source.** Revision `feature-grassy-beaver-opening-shot` at the commit this folder was added in.
**Command** (three runs, the burst starting at 0.3, 3.4 and 6.3 seconds; the tap presses the
title's button at the run's start, `--walk 20e` only on the third):

```
tools/shot.sh out.png 14 --seed 4242 --title --invincible --tap 640 480 --press snapshot_burst <start>
```

- `burst-a-sheet.png`: the title pressed, the cut to the park (trees), the rest, the camera starting
  back along the route.
- `burst-b-sheet.png`: the camera in the middle of the way back, streets and a crowd of walkers.
- `burst-c-sheet.png`: the camera arriving at her door (no car in the street at arrival), then her
  camera, the HUD and the line *Tap to walk, double tap to run*.

Kept: each burst's contact sheet and its `burst.json`. The full frames stay in scratch space.
