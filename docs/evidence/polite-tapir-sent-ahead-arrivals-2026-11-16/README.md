# The dog walker, the patrol and the convoy arriving ahead of her (polite-tapir, placement step 2)

**Claim.** Each of the three rows the director sends ahead of her arrives from off screen on the
street she walks: the dog walker down her sidewalk toward her, created at once with its own bark
still to run; the police patrol down the carriageway lane that drives toward her, created at once
out of the camera's view and driving into it; the military convoy warned of first (its screen-edge
badge alone for a second), then its trucks in the lane beside her, from behind her or from ahead
of her.

**Limits.** One seed and one walk per row, at a row forced with `--force`, so each picture shows
the row's own arrival and nothing about how often a day hands it out. The rigs walk north from the
doorstep up the arterial. `--invincible` holds the day still (the clock reads 3:30 throughout), so
nothing here shows a cost. The convoy is forced on day 2 to keep day 13's column and the region
doors out of the frame; the force bypasses its first day. The patrol's car first shows at the top edge,
driving in (`patrol-entering.png`, the top of frames 10 to 15). Whether a frame is not a
pop-in is held by `tests/test_no_pop_in.gd`, not by these pictures.

**Source.** Branch `feature-polite-tapir-sent-ahead` at `383011822`. The convoy run is marked
`-dirty` only because two stray `.uid` files of throwaway probes were deleted in the working tree;
no source file differed.

**Commands** (`tools/shot.sh`, burst frames at 12fps over 3s from the second given):

- `dog-walker.png`: `tools/shot.sh out.png 9 --seed 90210 --day 2 --spawn arterial --walk north
  --force dog_walker 4 --invincible --press snapshot_burst 3.5`; frames 10, 12, 13, 14, 17, 20.
- `patrol.png`, `patrol-entering.png`: `tools/shot.sh out.png 9 --seed 31337 --day 4 --spawn
  arterial --walk north --force police_patrol 4 --invincible --press snapshot_burst 3.5`; frames
  9, 11, 13, 15, 19, 25, and the top of frames 10 to 15.
- `convoy.png`: `tools/shot.sh out.png 11 --seed 31337 --day 2 --spawn arterial --walk north
  --force military_convoy 4 --invincible --press snapshot_burst 3.5 --press snapshot_burst 6.6`;
  the first burst's frames 2, 14, 30 (the badge at the bottom edge for the convoy coming from
  behind her), then the second burst's frames 8, 15, 30 (its truck driving in from the bottom and
  past her, and the next convoy's badge at the top edge, coming from ahead of her).

**Retained.** The selected frames as contact sheets at half size (quantized to 256 colours), each
burst's `burst.json` (its frame times), and `ahead-lines.txt`, the run log's `start`, `ahead` and
`cue` lines of the three runs, which say where each was created and from which end. The other
frames and the full logs stayed in scratch space.
