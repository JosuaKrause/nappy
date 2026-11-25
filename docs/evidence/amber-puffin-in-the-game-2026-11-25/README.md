# The south water drawn in the game as one live tile of drifting Voronoi lines

Evidence for amber-puffin, the south water is a blue base with drifting Voronoi lines: the build
that brings the experiment into the game (the record `tools/decisions.sh amber-puffin`). The
south water's surfaces (`SceneryWater`) draw their cells from one live tile of the lines
(`SouthWaterTile`, eight cells of 48 world pixels a side, a texel a world pixel), which only the
tile's shader draws; every other water keeps its drawing.

## The claim and its limits

- **The look.** `waterfront-before.png` and `waterfront-after.png` are the last frame of the same
  windowed run on main and on the branch: seed 4242, day 1, standing on the south shore beside the
  bridge, the debug readout on (the right-hand column). `waterfront-before.gif` and
  `waterfront-after.gif` are a 3 s burst of each (35 to 36 frames at 12 fps, timed by the game's
  own burst), cropped to the 960x320 screen pixels from the bulkhead's foot down and left of the
  readout. They show the drawing and its motion at the desktop's scale; they are not timing
  evidence.
- **The sea wall stands in the water.** On main the bulkhead's picture paints its own strip of
  water at its foot. On the branch that strip is transparent but for a one-pixel contact shadow,
  and the water surfaces draw the south water beneath the bulkhead row, so `waterfront-after.png`
  shows the stone meeting the Voronoi water directly, with no band between them. The branch's
  first stills, taken before that change, showed the old strip as a dark band above the new water;
  they are in the pull request's history at `4265836c5`, superseded by these.
- **The bulkhead's transfer.** `bulkhead-foot.py` is the edit made to
  `art/illustrated/svg-transfer/tiles/bulkhead.png`: rows 18 to 31 (the painted water) fully
  transparent, row 17 (the painted waterline) black at alpha 102, rows 0 to 16 (the stone)
  untouched. It refuses any input but the transfer it was made for (sha-256 `ea0a6f8cacb48194`…);
  its output is sha-256 `8fc2aca3dd3e914e`…, the file committed. Run as
  `uv run python -I bulkhead-foot.py <the transfer at 342ceef4a> <output>`. The SVG, the source,
  was edited by hand to match: its water rect and ripples removed and a one-pixel black row at 40%
  opacity added at the foot of the stone.
- **The cost.** The game's `frame` entries (once a second: fps, worst frame, draw calls,
  primitives, the engine's worst process interval) from windowed `tools/shot.sh` runs on an Apple
  M2 under the Compatibility renderer, the first two seconds of each run left out. The frame's
  milliseconds are 1000 over the mean fps. The desktop's renderer is not bound by fill the way a
  phone's is, and no phone was measured.
- **Other agents' Godot runs were going on the machine throughout** (load average 4 to 5, one
  headless run at a full core). The first set ran all of main's runs and then all of the branch's,
  and the branch read slower on both walks, the one that never sees the water included; the
  second set alternated main and the branch run by run in an ABBA order, and there the difference
  disappeared into the spread between runs. The sequential set is kept as the failed trial that
  shows how far the machine drifted.

## What is kept

| file | what it is |
|---|---|
| `waterfront-before.png`, `waterfront-after.png` | the shore's last frame, main and the branch |
| `waterfront-before.gif`, `waterfront-after.gif` | a 3 s burst of the shore, main and the branch, cropped |
| `frames.tsv` | every measured run of both sets: walk, code, samples, mean fps, frame ms, mean worst frame, draws, primitives, process |
| `bulkhead-foot.py` | the edit that clears the water from the foot of the bulkhead's transfer |

The raw burst frames, the run logs and the full-size shots stay in scratch space: the GIFs are made
from the frames by the commands below, and `frames.tsv` holds every run's figures.

## The figures

Interleaved set, four runs of each walk on each side, the mean over runs:

| walk | code | mean fps | frame ms | worst frame ms | draws | primitives |
|---|---|---:|---:|---:|---:|---:|
| the waterfront | main | 161.9 | 6.18 | 15.4 | 287.0 | 4182 |
| the waterfront | branch | 175.5 | 5.70 | 14.9 | 287.9 | 4207 |
| M139's walk | main | 137.6 | 7.27 | 20.1 | 281.8 | 3894 |
| M139's walk | branch | 138.9 | 7.20 | 20.3 | 281.9 | 3917 |

A single run of the waterfront on main read anywhere from 5.38 to 7.39 ms, so no difference of the
size the tile costs on its own (the experiment's 0.21 ms on this machine) can be read off these
runs: the water drawn this way costs the desktop nothing these runs can measure. The draw calls
moved by about one a frame where the water is in view; the primitives by about twenty on both
walks, which these runs do not attribute.

## Reproduce

From a fresh clone, one engine at a time, with a display:

```sh
git fetch origin refs/pull/1755/head   # the pull request that adds this folder
before=342ceef4a                        # main the branch started from
after=438159b3f                         # the branch's source as measured (the cost)
# the after still and burst: 5ae6eff99, the branch with the sea wall standing in the water
for rev in "$before" "$after"; do
  dir="$(mktemp -d)/nappy"; git worktree add --detach "$dir" "$rev"
  (cd "$dir" && GODOT=/path/to/Godot ./tools/check.sh &&
   ./tools/shot.sh "$(mktemp -d)/water.png" 14 --seed 4242 --day 1 --spawn edge:s \
       --walk 0.1s7p --invincible --no-save &&
   ./tools/shot.sh "$(mktemp -d)/m139.png" 20 --seed 3265820891 --day 1 --walk 3s17e)
done
# each run prints its run.log; the frame entries are its "frame" lines
```

The bursts are the waterfront run with `--press snapshot_burst 6` added, its time 12 s; the GIFs:

```sh
ffmpeg -framerate 12 -i <burst>/frame-%04d.png -vf \
  "crop=960:320:0:400,split[a][b];[a]palettegen=max_colors=64[p];[b][p]paletteuse=dither=none" out.gif
```

## Source

- Main: `342ceef4a`, a clean checkout. The branch: the working tree that became `438159b3f`,
  committed after the runs with no change to its sources; sha-256 prefixes of the files the build
  changed, at that commit: `src/city/south_water_tile.gd` 2cc920031d52f4b4,
  `src/city/scenery_water.gd` 37c351fff86ec984, `src/city/scenery_ground.gd` e503e8b188fdc6a2,
  `assets/shaders/south_water.gdshader` 2c3231793c4cfc7f.
- The after still and burst: the working tree that became `5ae6eff99`, committed after the runs
  with no change to its sources; sha-256 prefixes at that commit: `src/city/scenery_ground.gd`
  6455dd810a6a7fa1, `src/city/scenery_water.gd` 99df304f159063b0, `src/city/ground_tiles.gd`
  6cd4382574aa5c24, `src/city/south_water_tile.gd` 479aabf7d5dd13b6, `art/tiles/bulkhead.svg`
  7546f947fb1acca1, `art/illustrated/svg-transfer/tiles/bulkhead.png` 8fc2aca3dd3e914e. The cost
  was not measured again: the change draws the water under one more row of cells per chunk, inside
  the same textured draw.
- Godot 4.7.2.stable.official.ed1daf0bf, Compatibility renderer, Apple M2, macOS 27.2.1, the window
  1280x720 at a scale of 2.
- Footprint: six files and this README, about 1.6 MB, most of it the two GIFs.
