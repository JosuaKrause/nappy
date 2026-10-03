# Playtest silver-puffin — Resume the next measured optimization

2026-09-29. Reported in conversation about the optimization follow-ups.

The queue contains event-shape classification caching, sharing identical danger predictions,
reuse/lazy preparation of static scenery, and the remaining partial-animation audit under M159,
a slow frame names the frame that was slow. The separate-scenery checkpoint and the player's
request to queue further worthwhile directions are recorded in
[Sunny lynx](2026-09-26-sunny-lynx.md).

> "there were more optimization ideas. let's start working on the next one."

The assistant selects event-shape classification caching as the next bounded investigation.
The retained native profile measures repeated `has_a_spread()` classification at roughly 760
calls per frame and 0.6 ms self time. The selected cache mechanism is the assistant's proposal:
audit all inputs and mutations, preserve behavior, and retain controlled repeated before/after
measurements. The player's request resumes implementation of the next optimization; it makes
no choice about a specific cache mechanism and no claim about phone performance.
