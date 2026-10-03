# M108 — Eight-direction entity graphics: cars bob on their wheels

Evidence for the wheel split and the bob. What each file may be said to prove is stated beside it.

## The split, source against source

[wheels-split-3x.png](wheels-split-3x.png) is rendered by
[render-wheels-sheet.gd](render-wheels-sheet.gd) (`--help` for its usage) from the SVG sources
through Godot's own `Image.load_svg_from_string()`, at 3x over neutral ground. One row per view:
the five crowd-car views, then the police car, fire engine, unmarked van, riot van, army truck and
lorry, each in the order side, front, back, front diagonal, back diagonal. Five cells per row:

1. the picture before the split — a crowd car's tinted body under its old trim; an event
   vehicle's one file;
2. the body layer (a crowd car's tinted body with its new trim);
3. the wheels layer;
4. the split drawn at rest;
5. the split with the body lifted by one world pixel over wheels that stay put — the top of the
   bob.

The "before" sources are the tree's own at `origin/main` 6b08cf8f, read with `git show`.
[wheels-split-differences.txt](wheels-split-differences.txt) is what the script printed: at native
scale every view drawn at rest differs from its unsplit picture by at most 3/255 in any channel,
and on no pixel by more than 8/255 — compositing rounding, not a changed drawing. The end views of
the 34x50 fire engine, vans, army truck and lorry draw their wheels under the body, the rest over
it, which is the order each tyre had when it was part of one picture.

## The bob, in the running game

`rig-231714-seed4242-v0.15.1-36-g5dcf316b-dirty/` retains the relevant moving-to-stopped
segment from this capture:

```sh
tools/shot.sh /tmp/m108_burst2.png 8 --seed 4242 --spawn signal --zoom 3 \
    --press snapshot_burst 3 --invincible --no-save
```

`--zoom 3` is three times the normal camera, so one world pixel is six screen pixels. The
contiguous selection in `asked/burst-7184578-001/` keeps frames 13 through 28 with their
original elapsed times in `burst.json`. Its selection metadata names the original duration
and the selected interval; playback ends at the original frame-29 boundary. Frames 13–24
show the car moving west and frames 25–28 show it stopped at the light. Its halo traces the
body and wheels; this invincible rig does not establish a meter cost.
Earlier approach frames and the extended stationary tail add no evidence to this comparison.
The plan map, routine run log and full-length MP4 are omitted. To view the retained segment,
run `tools/clip.sh` on the burst folder with a fresh scratch MP4 output path.
[burst-car-frames-13-24.png](burst-car-frames-13-24.png) crops frames 13 to 24 around it, two to a
row. What the frames show: the car moving, its wheels and shadow drawn with the body, the halo
tracing body and wheels together, and the car standing still once it has stopped. What they do not
establish on their own: the one-pixel rise, since the car is also steering several pixels across onto
its lane centre over the same frames and the two cannot be told apart by eye; `tests/test_car_views.gd` and `tests/test_event_views.gd` pin it.
