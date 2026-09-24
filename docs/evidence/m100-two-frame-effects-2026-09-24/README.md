# M100 — water, smoke and steam over two frames (2026-09-24)

Playtest 128: "splashing water (from the main break) or puffs of smoke (from the car crash) or
steam (from the escape) should have (at least) a two frame animation to convey what they are
better".

- `review-sheet.png` — every frame pair from its SVG through Godot's own SVG rasterizer, at 4x and
  at native size, on asphalt grey (the seals) or basement grey (the steam). The cells are fitted
  per row and do not share a world scale across rows. Made by `render-svgs.gd` (renders the SVGs
  named after `--` into `/tmp/tfe/out`) and `compose-sheet.py` (run with `uv run python`).
- `burst-car-accident-frames.png`, `burst-water-main-frames.png`,
  `burst-basement-steam-frames.png` — the same crop out of every few frames of each gameplay
  burst, enlarged, made by `compose-burst-strip.py`. They show the frames alternating in play at
  the normal camera scale; what a frame proves is limited to the build and moment it records.
- The three `rig-*` folders are the whole runs, each with its burst and the burst's MP4:
  - `rig-084807-seed4242-…` — `tools/shot.sh … 6 --seed 4242 --spawn event:car_accident
    --invincible --no-save --press snapshot_burst 2`
  - `rig-084844-seed4242-…` — the same with `--spawn event:burst_water_main`
  - `rig-084929-seed1265437254-…` — `tools/shot.sh … 9 --start-escape basement --invincible
    --no-save --press ui_accept 1.5 --press snapshot_burst 5`; the steam instance is one blow, so
    the vent's frames between blows show no vent at all.
