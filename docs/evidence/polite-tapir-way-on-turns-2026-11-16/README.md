# A sent patrol turning a corner, and a sent convoy driving on (polite-tapir, placement step 2)

**Claim.** A police patrol the director sends ahead of her drives on past her from junction box to
junction box while she is within `Tuning.OUT_OF_SIGHT` (420px) of it, and where the street past a
box is no through road it turns the corner in that box onto the crossing street, as a quarter turn
of 16px radius driven as three straight pieces (`WayOn`). A military convoy the director sends is
warned of first, comes down the road at her from ahead of her, drives past her and on down the
street the same way, turns the corner where the street on is no through road, and is gone once it
is past 420px from her.

**Limits.**

- **`patrol-turning.png`, `convoy-leaving.png` and `convoy-turning.png` are taken with
  `--follow`**, a camera parked on
  the car wherever it goes, not her camera. She stands about 600px east of the box the patrol
  turns in, outside her own view (640 by 360 around her). So these frames show how the turn and the
  driving on look, and nothing about what she sees: the car is gone from the follow camera's last
  frames because it passed 420px from her and its departure ended it, out of her view, which is
  the rule (`EventDeparture.leave()`). Whether a sent row is ever gone in her view is held by
  `tests/test_sent_rows_keep_to_the_road.gd`, not by these pictures.
- **`patrol-passing-her.png` is her own camera**, the same walk without `--follow`: the patrol
  comes down the road at her from the east, passes her and drives on west out of her view, straight
  through the box west of her (its pink route line, `--layers 7`, runs on past the frame).
- The patrol turned north, toward her side of the street: the turn away from her (south) is tried
  first and was no through road there, so north was the way on.
- One seed and one walk per row, each row forced with `--force`, so nothing here says how often a
  day hands one out. `--invincible` holds the day still (the clock reads 3:00 throughout), so
  nothing here shows a cost. The convoy is forced on day 8, not its own days 13 and 14, to keep day
  13's column out of the follow camera, which follows the first convoy it finds.
- The rig walk is the doorstep's street, west and back: other walks tried for these pictures stood
  her against a sidewalk's café tables, chatting mothers or a lamp post, or stood her still beside a
  zebra the patrol then gave way short of, and none of those runs is kept.

**Source.** Branch `feature-polite-tapir-way-on` at `fb5b49b85` (the runs are marked `-dirty`
only for untracked throwaway probes under `tests/`; no source file differed).

**Commands** (`tools/shot.sh`, burst frames over 3s from each second given; frames are named by
their burst, first, second or third):

- `patrol-turning.png`: `tools/shot.sh out.png 30 --seed 31337 --day 8 --force police_patrol 8
  --walk 6.2w4e3.5w16.3p --follow police_patrol --layers 7 --invincible --press snapshot_burst 20
  --press snapshot_burst 23 --press snapshot_burst 26`; the second burst's frames 10 and 15, then
  the third's 1, 3, 5 and 7, each a 400 by 300 crop round the follow camera's centre: the patrol
  driving west into the box, swinging through the turn, and driving north out of it.
- `patrol-passing-her.png`: the same without `--follow` and with the bursts at 15, 18 and 21
  (`--walk 6.2w4e3.5w13.3p`, 27 seconds); the first burst's frames 1 and 18, the second's 12, the
  third's 12, at half size.
- `convoy-leaving.png`: `tools/shot.sh out.png 28 --seed 31337 --day 8 --force military_convoy 8
  --walk 6.2w4e3.5w14.3p --follow military_convoy --layers 7 --invincible --press snapshot_burst 12
  --press snapshot_burst 15 --press snapshot_burst 18`; the first burst's frames 1, 8 and 15, the
  second's 1, 8 and 15, the third's 1 and 10, each a 400 by 300 crop round the follow camera's
  centre: the truck passing her (she is at the top left of the first two), driving on west, and
  gone at the box where its route turns north. Its turn falls between the two frames taken from
  the third burst, so this sheet shows no truck turning.
- `convoy-turning.png`: the same run's frames, the first burst's 1 and 8, the second's 1 and 15,
  the third's 6, 7, 8 and 10, cropped the same way: the truck coming down the road from ahead of her
  and passing her (she is at the top left of the first two), driving on west, entering the box,
  swung part way round in it, driving north out of it, and gone.

**Retained.** The four contact sheets (quantized to 256 colours), each selected burst's
`burst.json` (its frame times, under `bursts/`), and `ahead-lines.txt`, the run log's `start`,
`ahead`, `cue` and `shot` lines of the three runs, which say where each row was created and from
which end. The other frames and the full logs stayed in scratch space.
