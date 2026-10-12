**Shadows are drawn from pictures baked into their own atlas page at build time**, not traced as
polygons every redraw ([velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #700: "We
should draw shadows in pictures (move it into it's own atlas at build time). We will want better
shadows anyway soon. The ellipse ones don't work well.").

**Why it costs.** `GroundShape.draw_shadow()` (`src/ground_shape.gd`) fills each shadow with
`draw_colored_polygon`, and Godot's canvas renderer cannot batch a polygon ("Polygon's can't be
batched, so always create a new batch", in its source), so every shadow is a draw call of its own
between the sprites around it. Turning shadow drawing off in a scratch copy on the desktop removed
about forty draw calls and a little of `draw`; on the phone the saving is not yet measured.

**What it keeps and what it replaces.** The M61 record ("One shape per object · the shape, the
shadow and the body") draws every shadow from the object's `GroundShape`; the shape stays the
source, and the bake draws it once into a picture on a shadow page that the object then draws as a
sprite, tilted and squashed by its transform as now. The crowd car's capsule
(`CrowdAgent._car_shadow_shape()`) is two ellipses' hull rather than one ellipse and gets its own
picture. **It is not M139's shadow pass**
([M139](../../decisions/2026-09-14-M139-one-atlas-for-the-crowd-built-the-shadow-pass-measured-and-rejected.md)):
that drew every agent's shadow from one canvas item spanning the field, which defeated the
per-agent culling and was measured slower and reverted; here each object still draws its own
shadow, as now, from a picture instead of a polygon. **It prepares [silver-egret](../2026-10-03-silver-egret/README.md), a shadow is where the object
meets the ground**, which changes the shapes themselves: the page is where those better shadows
land, so this item does not redesign any shadow, and silver-egret's pictures replace these when it
is built.

Evidence: the frame record's `draw_calls` and `draw`/`render` on the same seed and route before and
after, desktop native and the phone's web page, and a still comparing a stretch of street before and
after showing the shadows unchanged.
