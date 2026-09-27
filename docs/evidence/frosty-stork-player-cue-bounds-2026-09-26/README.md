# Player-cue bounds evidence

`source-before-after-8x.png` renders the edited zzz, fuss and cry SVGs through Godot's SVG parser
at eight times native size. The left column is the source before the canvas correction; the right
column is the current source. Each row shares the thin ground line: the right column applies
`Stroller._indicator_anchor()`'s 2px, 3px or 7px bottom compensation before it is placed, so it
shows the same visible world anchor while the restored stroke fits inside the source canvas.

`source-and-atlas-8x.png` compares the current source raster on the left with the same region cut
from the current baked `ui` atlas on the right. Both are rasterized at native size and enlarged
with nearest-neighbor sampling for inspection; their matching pixels show that the runtime page
keeps the corrected source bounds. The unchanged alert and double-alert sources were also audited:
their crisp rectangle outlines meet their canvas edges but do not extend beyond them.
