# M108, eight-direction entity graphics — binding vehicle views

Every sheet below is rendered by `tests/probes/m108_event_vehicles_sheet.gd`
(`tools/test.sh probes/m108_event_vehicles_sheet.gd`), a headless rig that drives the actual runtime
selection — `EventInstance.setup()`, `_select_view()`, `EIGHT_VIEW_BY_SECTOR`, each family's own
`_BY_VIEW` table and `_draw_eight_view()`'s own `side_faces_west` mirror correction — rather than
assembling a source sheet from the file list by hand. Each row is one family, each column one of
`EightDirection`'s eight sectors in its own clockwise order starting from east: **E, SE, S, SW, W,
NW, N, NE**. Every picture is re-rendered from its selected SVG's own source text through
`Image.load_svg_from_string()`, at native scale in the `-native.png` sheet and 3x in the `-3x.png`
sheet — the same rasteriser `docs/evidence/svg-vehicles-2026-09-10/`'s own review sheets used.

- `vehicles-{native,3x}.png` — delivery van, fire engine, ice-cream van, reversing lorry. The first
  two are authored facing west (`side_faces_west = true`); the last two are authored facing east
  (`side_faces_west = false`). `delivery_van` and `ice_cream_van` are always sited facing due east
  in play (`AT_THE_KERB` never turns them) and `reversing_lorry` only ever reaches due east or west
  (`AGAINST_THE_BUILDING`), so every column past the `E`/`W` pair is shown here for completeness
  rather than because the row is ever seen at it.
- `vehicles-security-{native,3x}.png` — unmarked van (`abduction`, west-authored), army truck
  (`military_convoy`, west-authored) and the riot van (`night_raid`, west-authored too). All three
  rows now take the `side_faces_west` correction, so all three read the same way at `E`/`W` on this
  sheet — see `EventInstance.RIOT_VAN_BY_VIEW`'s own doc comment for why the riot van's side view
  mirrors on east like its siblings rather than on west as M56's original hand-written match had it.
- `police-car-{native,3x}.png` — `police_patrol`, east-authored, and the only family here whose
  diagonal views are ordinarily reachable in play: the row is mobile and turns corners along its own
  patrol route, where every other vehicle family above either never turns (`delivery_van`,
  `ice_cream_van`) or turns only between due east and due west (`reversing_lorry`). The light bar and
  markings are baked into each authored view rather than drawn separately.

**Not shown**: `moving_van`, whose own `_front`/`_back`/diagonal sources stay prepared and unbound —
the seal's own side/vertical axis choice never turns to a diagonal, and `moving_van_vertical.svg`
already serves the "across the street" projection as its own authored scene (ramp down, doors open)
rather than a generic end view — and `burnt_out_car`, outside this item's family list entirely, whose
own side/vertical axis choice is untouched.

**What a sheet cannot show**: the exact mirror per family per sector, checked against
`docs/evidence/svg-vehicles-2026-09-10/facings.csv`'s own `mirror_x` column rather than eyeballed, is
asserted directly in `tests/test_event_views.gd` — the same suite that pins the riot van's octant
table against M56's original hand-written `match`, with the side view's mirror corrected to match
`facings.csv` (independent of `EIGHT_VIEW_BY_SECTOR`, so a later change there cannot silently
change what a hunting night raid draws), the kerb-parked vans' and the reversing lorry's
axis-fixed view, and every front/back/diagonal picture's own ground contact within a few pixels of
its canvas's bottom edge.

Two `tools/shot.sh` captures, `--layers 2,3` (shadows and bounding boxes) on top of the ordinary
picture, seed 4242:

- `shot-delivery-van-layers.png` — `--day 1 --spawn event:delivery_van --walk 1w`, `--after 1.3`. A
  parked delivery van, its green bounding-box circle and blue shadow ellipse agreeing with the
  picture's own wheels.
- `shot-police-car-layers.png` — `--day 4 --spawn event:police_patrol --walk 1w`, `--after 1.3`. A
  patrolling police car, light bar visible, its own box and shadow under it.

The `--walk 1w` nudge in both is `_spawn_position()`'s own doing rather than a framing choice: it
stands her `outer_radius · 0.6` from the event, across the street, which for a wide-radius row can
land the event at the very edge of a 1280×720 frame; a one-second step toward it brings the vehicle
comfortably inside frame without moving far enough to reach or pass it.
