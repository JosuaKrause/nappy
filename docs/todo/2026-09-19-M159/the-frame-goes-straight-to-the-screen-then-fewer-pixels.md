**On the web build the frame goes straight to the screen, and then the page draws fewer pixels on a
phone**, in that order ([velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #700: "I
wouldn't go to hack the engine just yet. We can try the direct to screen first (if it's an in engine
setting), then the internal multiplier"). Both switches exist behind the debug gate, `?direct=1` and
`?dpr=<x>` (the [M159-11 record](../../decisions/2026-09-19-M159-11.md)); what is open:

- **Direct to screen draws a black page** in a desktop Chrome web debug export, the game running and
  the console clean. Find why, and whether the phone's browser does the same; once it draws, it goes
  on by default on the web if the phone's frame records show `render` falling. Check orientation
  changes and letterbox by eye then.
- **The pixel cap's default is the player's**, chosen by eye and from two phone frame records on the
  same seed and route, with `?dpr=` at the browser's own ratio and at lower values (the review item
  [polite-gull](../../review/2026-10-12-polite-gull.md)).

*Not now:* patching the engine's web template (its `explicitSwapControl`, which forces the browser
glue's extra copy and a preserved drawing buffer). The player: "I wouldn't go to hack the engine
just yet". What would make it worth discussing again: `render` still the largest bucket on the phone
after both steps above.
