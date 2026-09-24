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
- `rig-164957-seed1713581249-…/still-between-blows.png`: a still in the building's basement
  before any vent has blown, with two vents' grates in the floor and no cloud; the mouse's
  notice stands over the lower one, drawn over the grate as everything standing is.
  `tools/shot.sh … 2.4 --start-escape basement --invincible --no-save --press ui_accept 1.5`.
- `rig-165019-seed1219710399-…`: the whole run with its burst and the burst's MP4.
  `tools/shot.sh … 6 --start-escape basement --invincible --no-save --press ui_accept 1.5 --press
  snapshot_burst 2`.
- `burst-vent-frames.png`: the same crop from every third frame of that burst. The lower grate
  lies there alone, then blows, the cloud rising out of it in both frames; in the last frame the
  upper grate starts its own blow. Made by
  `../m100-two-frame-effects-2026-09-24/compose-burst-strip.py` with the box `600 20 900 320`,
  scale 1, every 3rd frame.

The escape is dark (the building's own lighting), so the in-game frames are dimmer than the
sheet's first two rows. Each frame only shows the build and moment it was taken from; none of
them has her standing on a grate, so *under her* is held by `tests/test_interior.gd` rather than
by a picture.

The earlier pass, a standing pipe, is in `../m100-vent-pipe-2026-09-24/` with its verdict.
