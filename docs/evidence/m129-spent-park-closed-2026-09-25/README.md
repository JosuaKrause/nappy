# M129 — a spent park is closed

`poles-*` is the current visual proposal: square upright poles with two collars, broad feet,
and narrow end-on rails mounted on the poles' inward side. Each run's sign is one composite
plate and support, centered on the run. It draws after the overlapping rail surfaces so those
surfaces cannot cover the white bar. These images establish rendering, not player approval.

The game permits one physically fenced calm area, once per run in act III or later. Other used
areas keep their event spoiling and route exclusion. The pictures inspect the fence's projection,
corners and short entrance, not that policy or the outcome of a played day. The player's design
is in PLAYTEST-140, statements 8–10; visual feedback is recorded in `docs/DECISIONS.md`.

## Current runtime pictures

- `poles-corners-1x.png`: NW and NE above SW and SE, each a separate 320×240 crop at play zoom 2,
  with an 8px gutter between cells. This montage is not a single small park photographed whole.
- `poles-corners-3x.png`: the same pixels enlarged three times with nearest-neighbor sampling.
- `poles-side-{1x,3x}.png`: the side supports and midpoint mounted sign, at play zoom and enlarged.
- `poles-overview-fitted.png`: the entire fenced calm zone at fitted camera zoom 0.8654,
  for its overall silhouette; this is not normal play scale.
- `poles-archway-{1x,3x}.png`: the one-tile end-on entrance at block (9, 8), at play zoom 2
  and enlarged three times. The closed plate remains unobscured.
- `poles-capture.log`: the fixture's seed, day, chosen area and camera scales.

## Capture setup

A bounded scratch scene builds the real `City` with seed 14040 and day 9. It hands over the
nearest calm area whose fence has all four joined sides, block (5, 1), as used via
`CityMap.set_spent_calm()`, and supplies no previously fenced area plus act III through
`set_fenced_park_state()`. `City.start_day()` and the real closure planner choose and draw it.
Its ground rectangle is (2432, 640), size 704×704 world pixels.

The archway is a separate rendering fixture: the script calls `ParkClosure.fence()` for block
(9, 8) and passes that single run through `City._spawn_closure()`. This exercises the actual
runtime drawing path without claiming that a day selects two fenced areas. A plain `Camera2D`
uses play zoom for detail views and fitted zoom for the overview; its interpolation is reset
between views. The scene has no player, HUD, crowd, event manager or day outcome.

The Godot invocation carries `--no-save --no-telemetry`, so these are fixture captures with a
separate stdout log, not a telemetry run folder. The engine renders the current atlas assets;
no asset is substituted or hidden. No existing dev flag provides this used-park handover.

## Other review material

`upright-*` uses the same fixture. Its rail is centered on a narrow support, with no inward
mounting offset, and its corner montage has no gutters. Its `1x` and `3x` sizes mean play zoom
and enlarged pixels; its overview is fitted. The files are retained review evidence, not
approved visual references.

`before-*`, `attempt3-*`, `draft-*` and `fence-draft/` are also retained review material.
The draft SVGs are unbound and are not runtime assets. The decisions and visual feedback for
those pictures belong to `docs/DECISIONS.md`; the current proposal is the `poles-*` set above.
