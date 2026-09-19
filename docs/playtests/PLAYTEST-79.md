# Playtest 79 — 2026-09-19

Said in conversation on 2026-09-19, the same day as [PLAYTEST-78](PLAYTEST-78.md), with no run
attached. Two requests, both asked to wait for the next session: *"let's not immediately start
working on the focus loss. that's for next session"*, and the second opened with *"also for next
session"*.

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

## A game can be resumed

> "also for next session: we need to be able to resume a previous game. saving should be
> implicit (on focus loss or game quit) and it should bring you back to that exact state but
> paused. in the browser it should be handled via local storage so refreshing or opening again
> the page doesn't lose progress"

> "there is no need for manual save state management since you can just hold restart to clear
> the game"

What is asked for, as statements:

- **Saving is implicit.** It happens when the game loses focus and when it quits; there is no
  save button, no slot and no menu. Focus loss is the same moment M160 pauses on, so the two
  share a trigger.
- **Resuming brings back that exact state, paused.** Opening the game again lands on the
  moment it was left, behind the pause screen, and continuing goes on from there.
- **In the browser it survives a refresh and a reopened page**, through the browser's own
  storage.
- **Clearing a save is the held restart that already exists** — the disc on the pause screen
  and the day summary that starts the run over — so nothing new is drawn for it.

What the code holds today. Nothing is written to disk about a run: `GameState` (the run's
seed, day, nerves, resistance progress, scars, consumed one-shot events, where she settled each
day, the run's clock) lives in memory, and the city and each day's plan are functions of the
seed and the day, so they need no saving. What is *not* a function of the seed is the moment
inside a day: her position and heading, the meter and the sleepiness, the day's clock, every
event instance's phase and position, pursuits in progress, the resistance errand's state, and
the crowd, which is a field of some two hundred walkers and a few dozen cars recycled around
her. *That exact state* covers all of it, and how much of the crowd has to come back exactly —
as opposed to being re-seeded around her the way it is when a day starts — is the question to
put to the player before building, with what each answer costs. A Godot web build's `user://`
is kept in the browser's IndexedDB rather than in `localStorage`; both survive a refresh, and
which one is used is an implementation detail unless the player means something by the name.
Filed as M161 in `TODO.md`.

---
