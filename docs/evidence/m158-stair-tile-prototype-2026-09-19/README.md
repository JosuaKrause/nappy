# M158 stair-side tile prototype

This review keeps the proposed stair side as six prepared SVG sources, not as a TileSet source or
an `InteriorScene` binding. Each canvas is 32×32. The east-facing upper tile contains four 8px-wide
rectangles of heights 32, 24, 16 and 8px, anchored to its bottom edge; the lower tile reverses
that sequence from its top edge. The west-facing files mirror the complete east-facing geometry.

The upper tile exposes a gray diagonal side above its rectangles' stepped top edge, rather than
allowing those rectangles to consume it. The lower side remains beneath its top-anchored stepped
rectangles. The continuation tile is a 16×16 gray triangle at the top-right (top-left in the
mirrored source): its legs span two 8px steps and bridge the lower side into the next shifted
module without background art hiding the join. The width is a silent, overturnable choice: 8px is
the largest divisor of the 32px tile that gives four steps rather than only two.

`renders/stair-side-review.png` places upper, lower and continuation roles vertically. A second
east module is one tile east and one tile down; its mirrored counterpart is one tile west and one
tile down. Both sit on the live `stairwell_segment_backdrop.svg` and `stairwell_floor.svg`, but
those assets remain unchanged.

Rebuild all native and 3× source previews plus the composition from an empty absolute directory:

```sh
godot --headless --path . --script res://docs/evidence/m158-stair-tile-prototype-2026-09-19/render_review.gd -- --output-dir /absolute/empty/output
```

The script uses `Image.load_svg_from_string()` for each new source, its live backdrop and its live
floor source. It refuses an existing output directory so a review cannot silently mix old and new
renders.
