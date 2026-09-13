# M120 evidence — the map edge

Three runs, all seed 3265820891 (playtest 66's own seed), day 1, `--invincible`. Each folder is a
whole copied run: `run.log`, `maps/day01-attempt1.png`, and — for the burst — its `asked/burst-*`
sequence with `burst.json`. `screenshot.png` is the single frame `tools/shot.sh` was asked to save
for that run; for the burst it is the last frame of the 10-second window, taken after the burst
itself had already finished.

## `item1-before-southeast-corner/`

The unpatched tree (`v0.9.0-6-gabc57a9a-dirty`, before this branch's first commit). `--spawn
corner:se --walk 2@135@` — spawns a couple of tiles inside the south-east corner, then walks two
seconds south-east so the camera is pushed to the true corner tile (159,159) while still facing
into it. The grass band stops short of the window's right edge and black shows beyond it: the
camera's look-ahead (`Stroller.CAMERA_LOOK_AHEAD`, added to the view after `Camera2D.limit_*`
already clamped `position`) reaches past what `City._paint_outside_the_map` painted.

## `item1-after-southeast-corner/`

The same seed, spawn and walk script, after `City.camera_bounds()` reserves that look-ahead from
the clamp itself (this branch's first commit). The grass reaches the window's right edge with no
gap, at the same corner and the same facing.

## `item2-burst-southwest-edge/`

After both commits. `--spawn corner:sw --press snapshot_burst 5` at tile (1,158), the south-west
corner's own pavement, five seconds of the crowd's ordinary traffic. Across all 36 frames nobody
is ever standing on the grass or the water band to the west — every walker and car already on
screen at frame 1 stays on the carriageway or the sidewalk, and every one that appears over the
five seconds does too. This is the shape *"entry is where exit is"* asks for: a burst posed to
*show* an entry from outside the map would need to catch the rare six-miss recycle in the act,
which neither this capture nor the diagnostic runs behind it managed to line up in the time
available — see the M120 commit for the seeded, hand-driven repro that does isolate it directly
against `CrowdAgent._recycle()`.
