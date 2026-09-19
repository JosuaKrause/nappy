# Playtest 79 — 2026-09-19

Said in conversation on 2026-09-19, the same day as [PLAYTEST-78](PLAYTEST-78.md), with no run
attached. One request.

## The game pauses when it loses focus

> "can we make the game pause on focus loss? and also an override to *not* stop the game or
> pause for agents trying to take a screenshot"

Nothing in `src/` reads a focus notification today, so a day keeps running — the clock, the
meter, the crowd — behind whatever window the player has switched to. The pause itself exists:
the `pause` action (`Esc`, and the pause button in the top right) opens the pause screen with
its continue button and held restart, and `get_tree().paused` stops the clock, the resistance
deadline and the telemetry observer behind it.

The second half is about the rigs. `tools/shot.sh` launches a windowed game with
`--screenshot <file> --after <seconds>`, and an agent's window usually opens behind whatever
the player is working in, so it never has focus or loses it at once; a game that pauses on
focus loss would hand every rig a still of the pause screen. So the override is a dev flag, and
a screenshot run carries it without being told to.

Two details the request left open, decided here and open to overturn: getting focus back does
not resume the day — the pause screen stays up until the player continues, the way it does
after `Esc` — and focus loss only pauses a day that is being played, so it does nothing on the
title, on the day summary, on the ending or while the pause screen is already up. Filed as M160
in `TODO.md`.

---
