# M108, eight-direction entity graphics — binding live event people, animals and riders

Every sheet below is rendered by `tests/probes/m108_event_people_sheet.gd`
(`tools/test.sh probes/m108_event_people_sheet.gd`), a headless rig that drives the actual runtime
selection — `EventInstance.setup()`, `_select_view()`, `EIGHT_VIEW_BY_SECTOR` and each family's own
`_BY_VIEW` table — rather than assembling a source sheet from the file list by hand. Each row is one
family (or one state of a family that draws two), each column one of `EightDirection`'s eight
sectors in its own clockwise order starting from east: **E, SE, S, SW, W, NW, N, NE**. Every picture
is re-rendered from its selected SVG's own source text through `Image.load_svg_from_string()`, at
native scale in the `-native.png` sheet and 3x in the `-3x.png` sheet — the same rasteriser
`docs/evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md`'s own review sheets used.

- `people-{native,3x}.png` — dog-walker person, dog-walker's dog, yeller, busker, poster crew, café
  sitter, van victim, protester (plain pose), leaf blower. Every one of these reads its own fixed
  site facing (`_heading`, set once by `setup()` and never turned) — a stationary actor with no
  target keeps its authored default view, which is a full octant now rather than only an east/west
  mirror.
- `people-states-{native,3x}.png` — chatting mother walking and talking (paced travel selects the
  view; the state switches the whole picture), robber waiting and lunging. The waiting row faces
  her from the moment a caller has told the instance where she is
  (`EventInstance._robber_waiting_heading()`) — "a stationary actor whose action has a target faces
  that target" — before he has decided anything about her; the lunging row reads `_heading`
  directly, which `_chase()` already keeps pointed at her for the whole of the telegraph and the
  chase.
- `animals-rider-{native,3x}.png` — cat crouched, cat running, loose dog, charging dog, cyclist.
  Every one reads its own travel (`_heading`, set by `_advance_along_path()`/`_chase()` the same way
  a walker's is).
- `birds-{native,3x}.png` — a pigeon's raised and lowered wing phase. Each bird holds its own sector
  from its own `heading`, independent of every other bird in the flock — the two rows here replicate
  `_draw_birds()`'s own `bird.view_sector = EightDirection.update(bird.view_sector, bird.heading)`
  directly on eight synthetic headings, since a flock needs a canvas to draw at all.

**Not shown**: `mouse` (deliberately unbound — see `docs/GRAPHICS.md`'s row and
`EventCatalogue._alley_mouse()`'s own docstring) and `gunman` (its firing-axis composite only ever
reaches the side view, already live; see `docs/GRAPHICS.md`'s firefight row). The eight
`protester_point_*` poses are M65's own family, untouched by this item, and are not part of this
sheet.

**What a sheet cannot show**: every state transition the tables carry — crouched against running,
waiting against lunging, walking against talking, wings up against wings down — is asserted
directly in `tests/test_event_views.gd`, which also pins the selector wiring, the per-family table
completeness, the animal families' side-view reuse of their existing canonical source, the targeted
robber's facing (with and without a known player position) and the SVG fallback with no PNG transfer
yet registered.

Two `tools/shot.sh` captures, seed 4242, 1280×720:

- `gameplay-dog-walker.png` — `--day 1 --spawn event:dog_walker`, `--after 3`. The dog-walker
  composite (front view here) beside the mother and pram, with a café's tables and sitters visible
  at the lower right — the HUD's own `nearest` readout names the instance.
- `gameplay-busker.png` — `--day 2 --spawn event:busker`, `--after 2`. The busker, guitar and case
  visible, drawn from a diagonal view against a real street.

Neither capture happens to catch every family or every sector — a screenshot can only ever show the
moment it was taken, not the binding, which is what the rendered sheets and the suite are for. A
third attempt, `--day 8 --spawn event:alley_robbery`, sited her close enough to end the day on
arrival (a real day-8 alley robbery, working as designed) rather than showing the picture, and was
discarded rather than spent as one of the two captures.
