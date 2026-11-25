# silver-egret — the swing frame on its feet, the riot and moving vans on their wheels · 2026-11-25

**The claim.** The night raid's riot van and the moving van cast one squashed oval per wheel pair
under a body read off their picture (`EventVehicleLook._wheel_shape()`), where before each cast one
oval as wide as the scene round it, wider than the van. The playground swing frame casts one oval
under each of its two A-frames (`Prop.shadow_outlines()`), where before one capsule lay under its
whole picture, and day 12's touch spot at its base is the size and place it was, both ovals inside
it. The spot has no mark of its own: it is found by its red arrow, as every red-arrow destination is
(the record silver-egret-sunny-magpie).

**What each file shows.**

- `vans-sheet.png`: the riot van at all eight sectors, east first and then clockwise, and the
  moving van side on and end on, each row before and after.
- `swing-sheet.png`: the swing frame before (the capsule), after (the two ovals), and after with
  day 12's touch spot traced round its base in red, a line the game does not draw.
- `ingame-swing.png`: the game, before (left) and after (right), at day 12's swing on the task's
  own stretch (`recipe-swing.json`, from `scene-recipes/task-12-swing.json`), with the one park
  tree that stands in front of the frame taken out of the recipe so the frame shows; the black
  beyond the playground's east edge is where the stretch ends.
- `ingame-swing-city.png`: the same swing on the whole city (`recipe-swing-city.json`), the tree
  in front of the frame as the player meets it.

**Limits.** The sheets are drawn by a probe, not the renderer: the pictures are re-rasterised from
their SVGs and the shadows filled on a plain ground, though the outlines come from the game's own
calls (`EventLook.shadow_outlines()`, `Prop.shadow_outlines()`) and the pictures stand where the
game stands them. The "before" rows are the ground shape's own outline, which is what the two vans
and the frame drew before. The in-game stills are single frames of one seed and one fixed camera,
on day 12 with no task offered (the red arrow is not drawn). No in-game still shows the vans; the
sheet does.

**How they were made**, the "before" stills with `src/` at `main` 342ceef4a and the "after" ones
and the sheets from this branch:

- the sheets: `tools/test.sh probes/silver_egret_shadow_sheet.gd` writes one PNG per row under the
  game's `user://silver-egret-shadow-sheet/`, and
  `python3 -I ../silver-egret-shadows-2026-11-25/compose_sheet.py <that folder> vans-sheet.png 0.5
  riot-van-before riot-van-after moving-van-before moving-van-after` (and `swing-sheet.png 1.0
  swing-frame-before swing-frame-after swing-frame-touch-spot`) labels and stacks them, quantised to
  256 colours;
- the in-game stills: `tools/scene-recipes.sh --recipe recipe-swing.json --screenshots` and the
  same with `recipe-swing-city.json` (seed 11, construction city 1917501, day 12, a fixed camera at
  zoom 2.5), once on `main` and once on the branch, each `recipe-swing*.png` cropped to the
  640 by 480 pixels round the frame and set side by side.
