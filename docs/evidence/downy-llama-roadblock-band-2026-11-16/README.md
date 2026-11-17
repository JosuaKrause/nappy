# downy-llama: the open roadblock's band, before and after · 2026-11-16

**The claim.** On a street, the catalogue roadblock's concrete band covers its own sidewalk and the
road and stops at the far kerb, leaving the far sidewalk whole, where before it stood centred on its
carriageway lane and left about 20px of its own sidewalk and 52px of the far one. The picture is
drawn at the width the body collides at.

**Limits.** One roadblock, on one north-south street, on one day of one city; a still, since nothing
in the band moves. The guards and the green outlines are context: the outlines are the debug layer's
bounding boxes (the band's capsule and her rig), not something a player sees. That the band is solid
exactly to the far kerb on every lane of both axes is held by `tests/test_events_catalogue.gd`
(`_test_a_roadblock_covers_its_own_sidewalk_and_the_road`), not by these pictures.

**The frames.**

| File | Revision | What it shows |
|---|---|---|
| `before.png` | `54a42b0da` (main) | the band centred on its lane, a gap on each sidewalk |
| `after.png` | `16a32164f` (feature-downy-llama) | the band from the frontage on its side to the far kerb |
| `before-bodies.png` | `54a42b0da` | the same frame with the bounding-box layer on |
| `after-bodies.png` | `16a32164f` | the same, after |

Both trees carried only the untracked measurement probe (`tests/probes/downy_llama_route_roadblocks.gd`)
beyond their commit, which is why the run folders' names end in `-dirty`; the probe draws nothing.
`16a32164f` is on the pull request's branch: from a fresh clone, fetch it with
`git fetch origin refs/pull/<PR>/head` and check out the full commit ID.

**How they were made.** Seed 4242, day 8, with her standing on the doorstep, where a roadblock
stands at tile (88, 68), 58px from her; 4.0s after the day starts, 1280x720, `--invincible`, and the
bounding-box layer (`--layers 3`) for the `-bodies` frames. Each frame is cropped to the 420x300
around the band. The run logs record the seed, the day, the wait, the size and `invincible`; the
command line itself was not kept, so this is the line the logs reconstruct, run from each revision's
checkout:

    tools/shot.sh <scratch>/before-d8-4242.png 4 --seed 4242 --day 8 --invincible
    tools/shot.sh <scratch>/before-layers.png 4 --seed 4242 --day 8 --invincible --layers 3

The run folders under `user://telemetry/2026-11-16/` were `rig-214417-seed4242-v0.29.2-493-g54a42b0da-dirty`
(before) and `rig-214446-seed4242-v0.29.2-496-g16a32164f-dirty` and
`rig-214404-seed4242-v0.29.2-496-g16a32164f-dirty` (after, plain and with the layer); only the crops
are kept, since a frame is the whole claim and the logs add nothing to it.

**The measurements** of what the change does to the day's placements are in the record,
`docs/decisions/2026-11-16-downy-llama.md`, with the probes that took them; `measurements.txt` beside
this file holds their compact output, main against the branch.
