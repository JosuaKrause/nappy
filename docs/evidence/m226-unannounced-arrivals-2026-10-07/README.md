# M226 — The loose dog and cat arrive without a badge

Two inspected gameplay stills from source revision `f345d40a`, fetched through
`refs/pull/597/head`, show the rows the player explicitly excludes from coming warnings.

- [Loose dog, frame 8](rig-213009-seed4242-v0.25.4-16-gf345d40a/frame-0008.png):
  the dog and trailing leash approach down her sidewalk, above the mother near the screen's
  horizontal center. The debug readout identifies `loose_dog`; no screen-edge badge announces it.
- [Cat, frame 36](rig-213021-seed4242-v0.25.4-16-gf345d40a/frame-0036.png): the cat crosses from
  the right above her, near the left edge of the debug readout. The readout identifies `cat_dash`;
  there is no cat warning badge.

Both runs use seed 4242, day 2, tap mode, invincibility, and a forced director row every three
seconds. These pictures show the arrival's appearance and absence of a badge at the selected
moment. They do not measure cost, prove every prior frame lacked a badge, or establish exact
spawn timing. The headless catalogue and badge checks establish those rules. The cat's debug
readout overlaps part of its path; the retained frame still shows its body.

Rerun from the repository root, choosing a fresh scratch directory:

```sh
capture_dir=$(mktemp -d)
tools/shot.sh "$capture_dir/loose-dog.png" 8 --no-save --invincible --seed 4242 --day 2 \
  --spawn arterial --walk north --force loose_dog 3 --press snapshot_burst 3.1
tools/shot.sh "$capture_dir/cat.png" 8 --no-save --invincible --seed 4242 --day 2 \
  --spawn arterial --walk north --force cat_dash 3 --press snapshot_burst 3.1
```

The original run folder names and complete burst timing sidecars are retained for ancestry.
Only the two relevant PNGs are retained; the sidecars also name unretained frames. Full bursts,
ordinary boot output, and the final automatic screenshots remain scratch evidence. Capture
hardware: macOS Apple M2, Godot 4.7.2, native Compatibility renderer. The window was covered;
the capture path drew the selected frames on demand. No image is edited or annotated.
