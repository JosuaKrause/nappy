priority: now

## M204 — A trailer, rendered from the game by a script · asked for 2026-09-25

> "the trailer will be a set of paths in pre determined seeds with fixed events so we can
> reproduce it easily"

[PLAYTEST-139](../../playtests/PLAYTEST-139.md) holds the whole design, statements 1–10.

The cut's record is [M204, the trailer from saved scenes](../../decisions/2026-09-25-M204.md),
and the player's words on it are in
[olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md) (#579), where the 30s cap is
lifted ("no cap"). [Quiet-wombat](../../playtests/2026-10-07-quiet-wombat.md) requires the
[startup camera correction](start-the-camera-at-the-player.md) before any further trailer
improvements: it starts at the player instead of racing there from the origin. This reported
bug puts the entry in `now`; the separate [standalone screenshot
investigation](standalone-escape-screenshot.md) stays deferred until after the camera work.
