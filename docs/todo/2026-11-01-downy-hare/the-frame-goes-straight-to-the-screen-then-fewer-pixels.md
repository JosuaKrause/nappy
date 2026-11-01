**On the web build the frame goes straight to the screen, and then the page draws fewer pixels on a
phone**, in that order ([velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #700: "I
wouldn't go to hack the engine just yet. We can try the direct to screen first (if it's an in engine
setting), then the internal multiplier"). Direct to screen cannot show a frame on the web build in
this renderer, and `?dpr=<x>` caps the pixel ratio behind the debug gate (the
[M159-11 record](../../decisions/2026-09-19-M159-11.md)). What is open:

- **The pixel cap's default on mobile web is the player's**, chosen by eye and from phone frame
  records on the same seed and route, with `?dpr=` at the browser's own ratio and at lower values
  (the review item [polite-gull](../../review/2026-10-12-polite-gull.md)).
- **Whether to try direct to screen another way is the player's**: the record's untested second
  viewport, or nothing until `render` is shown still to be the phone's largest bucket after the cap.

*Not now:* patching the engine's web template (its `explicitSwapControl`, which forces the browser
glue's extra copy and a preserved drawing buffer). The player: "I wouldn't go to hack the engine
just yet". What would make it worth discussing again: `render` still the largest bucket on the phone
after the cap.
