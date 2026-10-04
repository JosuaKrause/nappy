# feathery-bison — the pelican cyclist, review pictures

**What this shows:** the pelican that about one cyclist in 400 is drawn as *(minty-hedgehog,
statement 8: "One in ~400 bikers should be a pelican riding a bicycle instead. Needs to be svg
only")*, for the player to judge by eye. A picture cannot show the share, the seed or that the
pelican's field is the cyclist's; `tests/test_pelican.gd` holds those.

**What it does not show:** whether the drawing is approved. That is the player's review.

## The sheets

- `sheet-game-scale.png` — the kid and the pelican side by side, every view (front, front
  diagonal, side, back diagonal, back) in both pedal frames (`a`, `b`), each SVG rasterized at
  scale 1 by the engine's own SVG rasterizer (`Image.load_svg_from_string()`, the call the atlas
  bake makes) and enlarged 2× nearest-neighbour, which is the camera's zoom. Every cell sits on a
  shared baseline, so heights compare across views.
- `sheet-enlarged.png` — the pelican alone, rasterized at scale 6, for the joins and the outlines.

The background is a flat sidewalk grey, not the game's ground.

Rerun from the repository root, with Godot 4.7 at `$GODOT` and Python 3 with Pillow:

```sh
out=$(mktemp -d)
mkdir -p "$out/project" "$out/r"
printf 'config_version=5\n' > "$out/project/project.godot"
cp docs/evidence/feathery-bison-pelican-2026-10-03/render.gd "$out/project/"
"$GODOT" --headless --path "$out/project" --script render.gd -- 1 "$out/r" \
    "$PWD"/art/events/cyclist*.svg "$PWD"/art/events/pelican_cyclist*.svg
"$GODOT" --headless --path "$out/project" --script render.gd -- 6 "$out/r" \
    "$PWD"/art/events/pelican_cyclist*.svg
python3 docs/evidence/feathery-bison-pelican-2026-10-03/sheet.py "$out/r" "$out/game-scale.png" 1.0 2 cyclist,pelican_cyclist
python3 docs/evidence/feathery-bison-pelican-2026-10-03/sheet.py "$out/r" "$out/enlarged.png" 6.0 1 pelican_cyclist
```

## In the game

Two windowed runs on `f79babcf` (the build string reads `-dirty` only because this folder was not
yet committed), both with `--pelican`, so every cyclist sent is the pelican, and `--force cyclist 3`,
so one is sent every three seconds of walking. `--invincible` keeps the day running through a hit.

```sh
tools/shot.sh out.png 12 --seed 4242 --day 2 --spawn arterial --walk north \
    --force cyclist 3 --pelican --invincible --press snapshot_burst 6.5
tools/shot.sh out.png 12 --seed 4242 --day 2 --spawn arterial --walk 1s10e \
    --force cyclist 3 --pelican --invincible --press snapshot_burst 6.5
```

- `burst-side-west.gif` — the second run's burst (22 frames over 3.0s), cropped to the 460×240
  around her, frame durations from its own `burst-side-west.json`: pelicans riding west along the
  sidewalk past her, the side view mirrored for a westward heading, the two pedal frames
  alternating. `still-side-west-full-frame.png` is frame 11 of it uncropped, HUD and readout
  included.
- `still-front-south.png` — frame 2 of the first run's burst (`burst-front-south.json`), cropped
  around her and enlarged 2×: a pelican riding south at the camera in the front view, under the
  doubled red mark that says it is closing on her.

Retained: the cropped burst, two stills and both bursts' timing records. The other burst frames,
the run logs and the end-of-run screenshots stay out; they show the same scene and nothing the
claim needs.

The screen-edge badge is the cyclist's, before the rider exists and while a pelican is off
screen alike; the run log calls the rider `cyclist` throughout, since the row is the cyclist's.
