# frosty-stork — The baby indicator canvases retain their complete outlines · 2026-09-26

The player reported icons cut off at their edges, identified the bottom of the triple-wave symbol
in `ui.png`, and explicitly requested a separate PR ([Merry hare](../playtests/2026-09-26-merry-hare.md)).
The SVG canvas clipped the authored outlines before atlas packing; increasing the player's
collision bounds or changing the camera could not restore those missing pixels.

The sleep, fuss and cry sources gain transparent canvas space. Their paths, stroke widths,
colors and native scale remain unchanged. The sleep canvas changes from 28×24 to 32×28,
fuss from 22×20 to 26×25, and cry from 24×26 to 28×35. Each source translates its artwork by
(2,2). The bottom-center draw anchor adds 2, 3 or 7 pixels respectively, so the source point
(x,y) keeps exactly its previous world coordinates: horizontal size grows by four while x gains
two; vertical size grows by the translation plus the compensated bottom space. Newly recovered
strokes extend beyond the previously clipped boundary without moving the original geometry.

The initial four-pixel uniform-padding idea was rejected: the reflected half of the crying
wave reaches y=27, and its 3.5px outline half-width extends to y=30.5, past the 26px canvas by
4.5px. The fuss wave similarly extends to y=21 past its 20px canvas. Tailored margins leave
clear alpha space around each rasterized outline. This padding choice is an implementation
detail open to revision; the player asked for complete icons, not particular dimensions.
The single and double exclamation marks are audited and unchanged: their crisp rectangles
reach their canvas boundary without extending beyond it.

[The comparison sheets](../evidence/frosty-stork-player-cue-bounds-2026-09-26/README.md) show
aligned source coordinates before/after and matching native source/baked-atlas pixels enlarged
for inspection. A bounded live capture booted but did not retain its seeded baby meters, so it
showed no cue and is not used as appearance evidence. Registration is established by the shared
draw-offset calculation; the source/atlas sheets are not presented as live gameplay captures.

Import/boot, XML/doc lint and whitespace checks pass. Focused stroller and atlas-library suites
pass 503 checks; the danger suite passes 129, with its existing Camera2D process warning. These
are partial local runs; full-suite CI is the PR gate. No gameplay threshold, cue timing, camera,
collision or atlas membership changes. The completed correction leaves the queue; native-scale
legibility remains a human review item. No merge or release is authorized.
