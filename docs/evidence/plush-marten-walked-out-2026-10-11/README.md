# plush-marten — the park's people walked out through the last gap

Evidence for the review of PR #677, finding 4 (the park's people and their escort walked through
the tape and through buildings), 2026-10-11.

**Claim:** a busker standing in day 12's park when the cordon starts is walked out by an officer
who comes in from out of her sight, through the last gap, and both leave the park through that gap
— the busker first, the officer behind him — before it is taped, then walk off along the sidewalk.

**Run.** One run of day 12's swing scene, recorded with Godot's own movie writer (60fps, 1280x720,
`--player-view --no-focus-pause --no-save`, not `--invincible`), with the game's code as committed
at `b2b7d9ee`. The scene is `scene-recipes/task-12-swing.json` (run
seed 11, city seed 1917501, day 12) on the whole city (`{"scope":"full"}`, its stretch, context,
actors, posters and route bag dropped), with a busker added at (1232, 3824), in the park's
north-west by the playground, and the walk `1.95w0.7n0.7s5.71w3.13s0.35e0.4p0.5S0.8E25p`: she
reaches the swing about 12.9s in, runs from the robber the swing sends, and stands in the park's
south-east. The scratch recipe is not committed.

**Limit: the busker is not placed by the game's own rules.** Ordinary placement keeps a day's calm
ground clear, so the recipe runtime refuses a busker in a park; for this run a scratch,
uncommitted edit to `src/dev/scene_recipe_runtime.gd` installed it where the recipe put it, and was
removed before anything was committed. Everything after the busker stands there is the game's own
code. `tests/test_park_cordon.gd` holds the same walk-out headlessly with a busker spawned by
`EventManager.spawn_extra()`.

Command, from the repository:

    Godot --path . --resolution 1280x720 --write-movie <dir>/movie.avi --fixed-fps 60 -- \
        --recipe <scratch recipe> --recipe-mode scripted --player-view --no-focus-pause --no-save

The run log: "1 officers come to walk the park's people out, 0 more sent off on their own, through
the last gap", "the last gap at (1100.0, 3887.428), closing 12.0s after the swing", then "the last
gap of the park's cordon is taped 12.2s after the swing, with her inside: she is shut in".

- `walked-out-sheet.png`: frames 1150 to 1470, 40 frames (0.67s) apart, each scaled to 640x360.
  The officer reaches the busker at the playground, the busker walks west with the officer behind
  him, both cross the park's west edge where it is still open, and walk north up the sidewalk. The
  south side is taped all along; the west side's tape is going up from the south behind them.
- `escort-with-the-busker.png` (frame 1270): the officer beside the busker at the playground,
  walking him out.
- `out-through-the-gap.png` (frame 1390): the busker and the officer just outside the west edge, on
  the sidewalk; a taping officer below them on the west side.

The rest of the movie (the walk to the swing and the day's end) is left in scratch space.
