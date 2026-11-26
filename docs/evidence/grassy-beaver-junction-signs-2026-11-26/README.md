# grassy-beaver: the park signs at junctions, 2026-11-26

**Claim**: the four park sign pictures read as a park sign pointing a way, distinct from the closed
park plate and the barrier's closed sign, at the game's scale and enlarged; and on day 1 the first
sign stands on the corner of the junction where the tutorial route leaves the doorstep's street.

**Limits**: the source sheets are the SVGs rendered alone on a flat sidewalk grey, not in a scene.
The day-1 frame is one seed (4431) standing at the door, with the debug readout on; it shows a sign
pointing straight on (left), not one pointing down a turn.

**Source revision**: the branch feature-grassy-beaver-junction-signs, on main at ad3d74480.

- `park-signs-source_x1.png`, `park-signs-source_x3.png`: left to right, `art/props/park_sign_up`,
  `_down`, `_left`, `_right`, then `art/closures/park_sign` (the closed park plate),
  `art/closures/sign_closed` (the barrier's sign) and `art/props/signal_head`, at 1× and 3×. Made by
  `render-sources.gd` from an imported checkout (`tools/check.sh` first):
  `godot --headless --path . --script docs/evidence/grassy-beaver-junction-signs-2026-11-26/render-sources.gd -- <out-prefix> <svg>...`
- `day1-seed4431-first-sign.png`: `tools/shot.sh <out> 2 --seed 4431 --day 1 --invincible`, 1280×720;
  the sign is at the left edge, on the north-west corner of the junction west of her door.
  `day1-seed4431-first-sign-zoom.png` is its left edge, 240×160 from (0, 160), enlarged 3× with
  `sips`.
