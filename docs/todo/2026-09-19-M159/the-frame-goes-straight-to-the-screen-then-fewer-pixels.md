**On the web build the frame goes straight to the screen, and then the page draws fewer pixels on a
phone**, in that order ([velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #700: "I
wouldn't go to hack the engine just yet. We can try the direct to screen first (if it's an in engine
setting), then the internal multiplier").

**Why.** On both phone records the `render` bucket is the largest in nearly every frame, and most
of it lies outside the engine's own measured canvas render (`render_cpu_usec`): the copies of the
whole frame to the screen and any wait on the GPU, which grow with the number of pixels. Two
full-screen copies happen each frame on the web: the engine's from its render target to the screen,
then the browser glue's to the canvas.

**First, direct to screen.** It is an engine setting, not a patch:
`RenderingServer.viewport_set_render_direct_to_screen()` on the root viewport, on the web build
only, which removes the engine's own copy. The native build's screenshot and telemetry paths read
the viewport's texture and keep it. Check the page's orientation changes and letterbox by eye, and
measure with a phone frame record before and after on the same seed and route.

**Then the internal multiplier.** The canvas is the window's size times the phone's device pixel
ratio. A cap on that ratio on mobile web, chosen with a `?dpr=` page parameter for testing, draws a
fraction of the pixels; the world art is pixel art drawn at twice its size, so it stays sharp while
text softens. The player compares by eye and with two frame records before a default is set; the
value is the player's.

*Not now:* patching the engine's web template (its `explicitSwapControl`, which forces the browser
glue's extra copy and a preserved drawing buffer). The player: "I wouldn't go to hack the engine
just yet". What would make it worth discussing again: `render` still the largest bucket on the phone
after both steps above.
