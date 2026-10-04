**Split the frame record's `draw` column without changing what is drawn**
([jolly-trout](../../playtests/2026-10-04-jolly-trout.md), #541: "Can we get more granular mobile
measurements or would that break up things that are currently drawn together into separate draws?
We wouldn't want that I guess"; then "Yes and let's start work on it to go into the next release",
and "Yeah a patch release for after 25"). It ships in a patch release after v0.25.0.

The phone's frame record ([m159-phone-frame-record-2026-10-04](../../evidence/m159-phone-frame-record-2026-10-04/README.md))
has `draw`, from the end of the process step to `RenderingServer.frame_post_draw`, as the largest
share, and most of it is not explained by the counters the record keeps. Add to the record, only
while it is on (`--frame-record`, `?framerecord=1`):

- a mark at `RenderingServer.frame_pre_draw`, so `draw` splits into the time before it (the
  frame's `_draw()` calls and the engine's scene preparation) and after it (the renderer's own work
  and any GPU wait);
- a per-frame count of the game's own `_draw()` calls, by kind (the crowd, the halos, scenery, the
  danger badges, and the rest), as counts rather than times, since the page's clock steps in 100µs;
- the engine's measured render CPU time for the viewport, if the web build reports it, and say
  plainly if it does not.

Nothing drawn may change: no new canvas item, layer, material or draw call, which `draw_calls`
before and after on the same seed shows. Timing each `_draw()` call separately is not done. Measure
the record's own added cost with it on and confirm it costs nothing with it off, update
`docs/TELEMETRY.md`'s column table, and say in the pull request what a desktop or headless run
already shows in the new columns. The player then records one more run on the phone.
