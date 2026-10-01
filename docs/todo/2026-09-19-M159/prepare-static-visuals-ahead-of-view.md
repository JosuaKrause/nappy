**Investigate lazy preparation and unloading of static scenery around the camera.**

The player asks: "are all city renders done at the beginning of each day? can we do them lazily
instead whenever the player gets into x tiles from them (when the image is still off-screen)?"
They ask for this direction to be queued alongside the danger-prediction hypothesis. See
[Sunny lynx](../../playtests/2026-09-26-sunny-lynx.md).

Start by measuring the actual preparation stages. `City.build()` creates buildings once for a
run; daily dressing changes their static state. `GroundLayers.build_tile_set()` composes a shared
ground sheet at each repaint. Buildings retain drawing commands, rather than a rendered bitmap
per block. Do not design a scheduler around a per-block image cache that does not exist.

The player prioritizes lazy preparation and unloading in
[gentle-swan, investigate lazy scenery preparation and unloading](../../playtests/2026-09-30-gentle-swan.md):
"my hypothesis is that the player rarely sees all tiles that get prepared so it's a lot of wasted
memory and time. we can even unload scenery if it goes out of view too far". They question reuse
across days because the scenery changes. Measure that hypothesis; cross-day composition reuse
is not a prerequisite or the first implementation step.

Boot uses the same nearby-only policy: "the boot paint should only be for the block around home"
and "lazily create distant ones as the player comes near". Investigate the home block as the
initial prepared area. Measure the actual initial viewport and artwork overhang; if a literal
single block cannot fill it, report that boundary question explicitly rather than silently
preparing the whole city or accepting missing scenery.

**Proposed, not yet a chosen implementation:** prepare visual work within the camera view plus an
off-screen tile margin, under a measured per-frame budget, and release map-specific visual work
outside a larger retention margin. The separate margins avoid repeated rebuilds at a boundary.
Choose the margin from viewport size, camera motion,
maximum approach speed, artwork overhang and preparation cost; a building's ground origin alone
does not say when its roof becomes visible. Prepare the initial view and handle camera relocation
without blank scenery, pop-in or a burst of work on first visibility. Record the chosen policy.

Keep city data, collisions, routes, event placement and gameplay state ready independently of
visual preparation. Preserve deterministic artwork and RNG use regardless of approach order.
Static block visuals stay still; moving parts remain separate overlays. Track invalidation for
daily condition changes, posters, blackout, repaint and restart rather than reusing stale visuals.

Preserve the runtime composition choice from Playtest 108 and the atlas warmup rationale in
M147, every picture loaded before it is needed. Deferring visual composition is not permission to
move disk loads or shader compilation into the first visible frame, or to bake every ground
variant offline. Search those records before selecting a mechanism.

Compare day-start latency, warm-play frame median/tails/max, memory and actual visual preparation
work on identical routes and camera conditions. Include a fast approach, return to a cached area,
day transition and camera relocation. Accept only a measured benefit without in-play hitches or
missing/stale scenery; keep native CPU results distinct from phone/browser/GPU confirmation.

Measure prepared, visible and ever-seen cells/buildings separately for each sampled route; a
synthetic route is not evidence of what players usually visit. Attribute shared texture bytes,
map-specific nodes/cells and retained drawing separately. Count or memory proxies must not be
reported as measured GPU allocation or actual reclaimed bytes. Check what the renderer already
avoids off-screen before attributing savings to a new scheduler. Examine release/recreation
costs, a fast reversal through the retention boundary, overnight changes in an unloaded area,
and camera jumps. Keep atlas residency and gameplay simulation independent of visual eviction.
