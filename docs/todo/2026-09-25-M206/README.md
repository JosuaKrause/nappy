priority: later

## M206 — The title screen after a game over is the right way up · found 2026-09-25

> "also there is a bug when you lose with game over the title screen is sideways"

[PLAYTEST-140](../../playtests/PLAYTEST-140.md), statement 5. Seen on the phone.

Not reproduced off the phone. PR #378 re-applies the orientation as the title opens and closes a
startup race, and rules out the two suspects: on the web export, touch detection is the browser's
fixed `'ontouchstart' in window` and the window size is re-read from the canvas every frame, so the
per-frame orientation poll (`main._process()`, running through pauses) cannot stay wrong for more
than a frame. The player: "the only way to test this is to release it".

The player's phone, v0.18.0 ([PLAYTEST-144](../../playtests/PLAYTEST-144.md), statement 26, and
`docs/evidence/playtest-144-phone-v0.18.0-2026-09-26/after-the-restart.png`), captioned "This is
the screen when resetting": the still shows the city upright with no title after a held restart
from the day summary, where the player's other stills show the game turned for the phone. It is
one still, so how long that lasted is not known.
