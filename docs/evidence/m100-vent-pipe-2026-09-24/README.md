# M100: the basement vent's pipe is there between blows (2026-09-24)

A pass at `docs/TODO.md`'s M100 item "The basement vent's pipe vanishes between blows": the pipe as
its own picture, stood at every vent for the whole section, with the two steam frames drawing only
the cloud over its mouth. The three SVGs of this pass are in `svg/`.

**Verdict: rejected in review, 2026-09-24.** The pipe stands in the middle of a one-tile corridor
that she walks through between blows, so it cannot be solid where it stands. Asked whether she
walks through a standing pipe, over a floor grate, or past a pipe against the wall, the player
chose *"Let's make it a vent" · "Floor grate"*. The grate that replaced it is in
`../m100-vent-grate-2026-09-24/`.

- `review-sheet.png`: the vent between blows (the pipe alone) and blowing in each of its two
  frames (the pipe with the cloud over it, stacked in the order the game draws them). It is
  rendered from the SVGs through Godot's own SVG rasterizer on the basement floor tile, at 4x and
  at 2x (play size under the game's 2x camera). Made by `render-svgs.gd` (run with `--help` for its
  usage) and `compose-sheet.py` (run with `uv run python`, the render directory and the output
  path).
- `rig-152935-seed1169072229-…/still-between-blows.png`: a still in the building's basement
  before any vent has blown, with two vents' pipes standing in the corridor and no cloud.
  `tools/shot.sh … 2.4 --start-escape basement --invincible --no-save --press ui_accept 1.5`.
- `rig-152953-seed968136079-…`: the whole run with its burst and the burst's MP4.
  `tools/shot.sh … 6 --start-escape basement --invincible --no-save --press ui_accept 1.5 --press
  snapshot_burst 2`.
- `burst-vent-frames.png`: the same crop from every third frame of that burst. The lower vent
  stands as a pipe alone, then blows, with the cloud rising out of its mouth in both frames. In the
  last frame the upper vent starts its own blow. Made by
  `../m100-two-frame-effects-2026-09-24/compose-burst-strip.py` with the box `600 20 900 320`,
  scale 1, every 3rd frame.

The escape is dark (the building's own lighting), so the in-game frames are dimmer than the
sheet. Each frame only shows the build and moment it was taken from.
