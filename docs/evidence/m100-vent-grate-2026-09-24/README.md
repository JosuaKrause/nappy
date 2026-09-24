# M100: the basement vent is a floor grate (2026-09-24)

`docs/TODO.md`'s M100 item "The basement vent's pipe vanishes between blows", as the player
settled it: *"Let's make it a vent" · "Floor grate"*. The vent is `art/events/steam_grate.svg`, an
iron grate in the floor seen from above, lying at every vent for the whole section at floor level
under her; the two steam frames (`steam.svg`, `steam_b.svg`) draw only the cloud, rising out of
the grate while it blows.

- `review-sheet.png`: the vent between blows (the grate alone) and blowing in each of its two
  frames (the grate, then the cloud over it, in the order the game draws them), on the basement
  floor tile. Rendered from the SVGs through Godot's own SVG rasterizer at 4x, at 2x (play size
  under the game's 2x camera), and at 2x multiplied by the basement's lighting
  (`Palette.ESCAPE_BASEMENT_GLOOM`, the colour the building's `modulate` takes in the basement).
  Made by `../m100-vent-pipe-2026-09-24/render-svgs.gd` (run with `--help` for its usage; pass
  `art/events/steam_grate.svg art/events/steam.svg art/events/steam_b.svg
  art/interior/basement_floor.svg`) and `compose-sheet.py` (run with `uv run python`, the render
  directory and the output path).

The earlier pass, a standing pipe, is in `../m100-vent-pipe-2026-09-24/` with its verdict.
