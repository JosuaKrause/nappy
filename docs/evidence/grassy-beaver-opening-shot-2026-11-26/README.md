# The opening shot, day 1's camera on the park and the way home

**Claim.** On day 1's first attempt, pressing the title's button cuts the view to the tutorial park,
rests there, follows the tutorial route back at one pace to her door and hands the view to her own
camera; the walking line then shows, and the crowd has no car near her door when the view arrives.
**Limits.** One seed (4242), one machine, a windowed run at 1280x720 under load (a burst holds fewer
than 36 frames when the run is slow: the frame counts are in each `burst-*.json`). The three bursts
are runs of the same seed, so the crowd's walkers differ between them; each sheet shows six
frames evenly spaced over its burst. A `--walk` that holds a direction from the run's start does not
move her, since play's start releases the rig's held press; a script that stands first (`8p10s`) presses
once play has begun. Whether the shot reads is the player's run (`docs/review/`).

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
- `burst-d-first-step-sheet.png`: her camera after the hand-back, the line up, and her first steps
  south into the street once play has begun. Command, burst from 7 seconds, a walk that stands 8 seconds
  and then walks south 10:
  `tools/shot.sh out.png 16 --seed 4242 --title --invincible --tap 640 480 --walk 8p10s --press snapshot_burst 7`
- `right-order-arrival-sheet.png` and `wrong-order-arrival-sheet.png`: the same command (burst from
  5.5 seconds, no `--walk`), with the cars held after the crowd's box has moved to the park (the order
  built) and held before it (the order the design had; the run was made with the two lines of
  `Main._play_the_opening_shot()` swapped, which the code no longer has). The last frames show the
  street at her door: none with the order built, a car at the bottom of the view with the other. One
  seed and one run's timing: it shows that a car stays, not how often.
  `tools/shot.sh out.png 12 --seed 4242 --title --invincible --tap 640 480 --press snapshot_burst 5.5`

Kept: each burst's contact sheet and its `burst.json`, the wrong order's run included. The full frames stay in scratch space.
