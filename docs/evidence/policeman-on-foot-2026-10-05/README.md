# The policeman on foot, source review

**The question:** does the policeman on foot (drawn for the pursuer on foot a torn poster is to
send, inbox #591) read at game scale as police and as a danger, and is he told apart at a glance
from the alley robber, the checkpoint guard, the neighbor and the crowd?

`review-sheet.png` shows all seventeen `art/events/policeman_*.svg` pictures beside the robber
(`art/events/robber_*.svg`), the guard (`art/checkpoints/guard_*.svg`) and the neighbor
(`art/events/neighbor_*.svg`, the other blue figure with a dark cap: steel-blue coveralls with a
yellow reflective band and a soft work cap, where the policeman is navy in a peaked cap), each on the game's
sidewalk colour and on its asphalt colour, at game scale: the scale-1 raster doubled with bilinear
filtering, which is what the zoom-2 camera does to a baked atlas region. All four families share
one ground line per row and one world scale. Below that, the policeman alone at scale 4 for joins
and clipping. The soft ellipse under each figure stands in for the runtime's own drop shadow and is
an approximation of its size. The robber's set has no unsuffixed stride frame, so neither does
the policeman's, and the neighbor has no unsuffixed picture at all; those cells are empty.

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
