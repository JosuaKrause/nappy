# The policeman on foot, source review

**The question:** does the policeman on foot (inbox #591, the torn poster's pursuer) read at game
scale as police and as a danger, and is he told apart at a glance from the alley robber, the
checkpoint guard and the crowd?

`review-sheet.png` shows every `art/events/policeman_*.svg` view beside the robber
(`art/events/robber_*.svg`) and the guard (`art/checkpoints/guard_*.svg`), each on the game's
sidewalk colour and on its asphalt colour, at game scale: the scale-1 raster doubled with bilinear
filtering, which is what the zoom-2 camera does to a baked atlas region. All three families share
one ground line per row and one world scale. Below that, the policeman alone at scale 4 for joins
and clipping. The soft ellipse under each figure stands in for the runtime's own drop shadow and is
an approximation of its size. A view with no file yet is an empty cell labelled as such.

These are source previews of a prepared asset, not a gameplay capture: no runtime code draws the
policeman.

## Rebuild

```
uv run python docs/evidence/policeman-on-foot-2026-10-05/review-sheet.py \
    --godot <Godot 4 executable> --out <new path>/review-sheet.png
```

`review-sheet.py` renders each SVG through `render.gd` (Godot's own
`Image.load_svg_from_string()`) in a throwaway project in a fresh temporary directory, then
composes the sheet with Pillow; `--help` gives its usage.
