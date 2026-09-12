# M102 — the south-edge doors as indents, and the stairs as steps

PLAYTEST-60's verdict on the M112 escape interior graphics: the south-edge doors should be plain
indents in the wall rather than door fronts, and a stair flight's tread surface should be vertical
lines rather than diagonal 45° strokes. This folder shows the two redrawn families at native and
3× scale, one still of each in the running building, and one composite showing the door indents
next to a plain stretch of skirting for scale.

## Door indents (`open_threshold.svg`, `apartment_threshold.svg`)

- `open_threshold-1x.png`, `open_threshold-3x.png` — the open passage indent alone, floor colour
  visible at its back, no frame or door-shaped opening. 28×16.
- `apartment_threshold-1x.png`, `apartment_threshold-3x.png` — the same indent with a brown bar
  across its mouth, the bar being the whole of what says the apartment is locked. 28×16.
- `thresholds-in-context-composite.png` — three `hallway_floor_edge_s.svg` floor tiles side by
  side (unchanged, read-only reference for the palette) with a plain stretch of skirting, an open
  indent, and a locked indent pasted on at their runtime bottom-centre anchor, so the two new
  drawings can be judged against the skirting they interrupt rather than in isolation.
- `hallway-floor2-runtime.png` — `tools/shot.sh --start-escape floor:2`, a full hallway at day 1
  in the running building. Five locked recesses with their brown bars are visible along the south
  edge; the upright sprite at the player's back is the stairwell door (`DOOR_TEXTURE`), a
  different, unrelated asset that stays a standing feet-anchored sprite rather than a threshold.

## Stair steps (`stair_flight_run_e.svg`, `stair_flight_run_w.svg`, `stair_flight_short_e.svg`)

- `stair_flight_run_e-1x.png`, `stair_flight_run_e-3x.png` — the four-tile east-descending flight
  deck, 160×160, six vertical tread lines clipped to the tread body, thickening from 3px to 5px
  toward the bottom landing.
- `stair_flight_run_w-1x.png`, `stair_flight_run_w-3x.png` — the mirrored west-descending deck,
  160×160, same tread count and thickening progression toward its own bottom landing.
- `stair_flight_short_e-1x.png`, `stair_flight_short_e-3x.png` — the three-tile basement entry
  deck, 96×96, four vertical tread lines with the same thickening.
- `stairwell-left-runtime.png` — `tools/shot.sh --start-escape stairwell:left`, the top landing
  and first flight of the left stairwell in the running building. The treads read as vertical
  bars crossing the diagonal deck behind the foreground handrail; the deck outline, the rails and
  the landing platforms are the same sources as before this pass, unedited.

## What did not change

Both families keep their outline, canvas size, and origin/anchor exactly as before: no constant
in `src/interior/interior_scene.gd` moved, and no walking cell, collision shape or door behaviour
was touched. The replaced pre-edit sources are archived under
`docs/evidence/archive/rejected-graphics/escape-interior-doors-as-fronts-2026-09-12/` and
`docs/evidence/archive/rejected-graphics/escape-interior-diagonal-treads-2026-09-12/`, each with
its own README quoting the playtest verdict that superseded it.
