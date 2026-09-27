**Investigate reuse and lazy preparation of static scenery before it enters view.**

The player asks: "are all city renders done at the beginning of each day? can we do them lazily
instead whenever the player gets into x tiles from them (when the image is still off-screen)?"
They ask for this direction to be queued alongside the danger-prediction hypothesis. See
[Sunny lynx](../../playtests/2026-09-26-sunny-lynx.md).

Start by measuring the actual preparation stages. `City.build()` creates buildings once for a
run; daily dressing changes their static state. `GroundLayers.build_tile_set()` composes a shared
ground sheet at each repaint. Buildings retain drawing commands, rather than a rendered bitmap
per block. Do not design a scheduler around a per-block image cache that does not exist.

**Proposed, not yet a chosen implementation:** reuse unchanged compositions across days first,
then consider preparing remaining visual work within the camera view plus an off-screen tile
margin, under a measured per-frame budget. Choose the margin from viewport size, camera motion,
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
