# breezy-gecko, her house is crafted: first drafts

**What this shows.** Three SVG drafts of her home block's front, each matched to the escape's
interiors in `art/interior/`, for the player to choose between before anything is installed.
Nothing in the game reads these files; they are review drafts under `docs/evidence/`, outside the
atlas bake.

**The question the sheet asks**: which front should her house get? Each row of
`question-sheet-v1.png` is one option, labelled with its letter, beside the same strip of the
escape's own pieces (a hallway wall with its windows and lamps, the lobby's double entrance door,
the hallway floor and a run of basement brick):

- **A, plaster**: `home_front_a_plaster.svg`, the hallways' plaster wall outside as inside.
- **B, brick**: `home_front_b_brick.svg`, the basement's brick with plaster bands, lintels and
  cornice.
- **C, brick under plaster**: `home_front_c_brick_under_plaster.svg`, basement brick on the ground
  floor and the flanking lots, plaster on the three floors above.

All three share the escape's square four-pane window (`hallway_wall_window.svg`), its double
entrance door (`entrance_door.svg`, unchanged, 42x44) under a stone hood, and an unlit sconce in
the shape of `wall_lamp.svg` either side of the door. Each SVG's own header comment states its
footprint and what it borrows from which interior file.

**Footprint.** Each draft is 256x192 at the game's own scale (one 32px cell per tile): the door's
building, 8 cells wide and 4 wall rows tall, over the two flanking lots (3 cells wide, one roof row
and one wall row each) and the 2-cell stoop between them. `today-seed4242-day1.png` is the same
block as the game draws it now, for comparison; it is a crop of one `tools/shot.sh` still (seed
4242, day 1, `--zoom 0.75 --walk 1n --invincible --no-save`, build `v0.29.2-278-gf82966ad`), so the
block is at 1.5 screen pixels per world pixel there and at 2 on the sheet.

**Limits.** The sheet shows source renders through the engine's SVG parser, not the game: no
day or night lighting, no shadows, no roofs or stoop as the game draws them (the drafts draw a
plain roof and steps as context), and the neighbor's boarded window (day 11 on) and the sealed
door (day 10 on) are not shown.

**How it was made**, from the repository root, with a fresh scratch directory each time:

```sh
E=docs/evidence/breezy-gecko-crafted-house-2026-11-07
OUT=$(mktemp -d)/renders
"${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}" --headless --path . --script $E/render.gd -- \
    --output-dir "$OUT" --scale 1 $E/home_front_*.svg art/interior/hallway_wall.svg \
    art/interior/hallway_wall_window.svg art/interior/wall_lamp.svg art/interior/hallway_floor.svg \
    art/interior/basement_wall_brick.svg art/interior/entrance_door.svg
uv run python -I $E/compose.py --renders "$OUT" --out "$(mktemp -d)/sheet.png"
```

Run `tools/check.sh` once first so the checkout is imported. `question-sheet-v1.png` is the
delivered sheet (sha256 `4986c1875fdce15e1739fbc6375241565d890c9e6b5a436a922247aa478e2686`) and is
never overwritten; a later attempt gets a new file name.
