## M161 — The game pauses when it loses focus, and a rig can say not to · built 2026-09-19

*(2026-09-19, [PLAYTEST-80](../playtests/PLAYTEST-80.md): "can we make the game pause on focus
loss? and also an override to *not* stop the game or pause for agents trying to take a
screenshot".)* Built by an agent on `feature/m161-focus-pause`.

**What was built.** `main.gd`'s `_notification()` answers `NOTIFICATION_APPLICATION_FOCUS_OUT`
(another application, window or browser tab takes focus) and `NOTIFICATION_APPLICATION_PAUSED`
(a phone sends the app away) by calling `_pause_on_focus_lost()`, which opens the pause screen
through the same `_pause.open()` the `pause` action uses — one pause, not a second kind. It
does nothing on the title, on the day summary or the ending (one `DaySummary` node), while the
pause screen is already open, or under `--start-escape`, where no pause screen is built.
Getting focus back is not answered at all, so the player continues when they are back.

**The override.** `DevFlags.no_focus_pause()` is true for `--no-focus-pause`, for `--screenshot`
— a rig's window opens without focus and would otherwise capture the pause screen, so
`tools/shot.sh` and every existing capture command work unchanged — and for `?nofocuspause=1`
on a debug web build. It is gated behind `DevFlags.enabled()` like `--invincible`, so a release
build's address bar cannot turn the pause off.

**Choices made where the design was silent, open to overturn.**

- **Unlike `Esc`, focus loss does not open over the day summary.** `Esc` there is the player
  asking for a second screen; focus loss is not a choice, and the summary is already waiting
  on the player. Playtest 80 decided this; the code comment carries the reasoning.
- **`NOTIFICATION_WM_WINDOW_FOCUS_OUT` is not read.** It is the per-`Window` notification a
  game with several windows of its own needs, and this one has a single window. **This rests
  on the engine's documentation, not on a captured run**: the agent's sandbox never gave its
  window focus, scripted or otherwise, so a real desktop focus change was not observed. The
  tests drive `main.notification(...)` directly. The played check is in `REVIEW.md`.
- **The flag's commit precedes the behaviour's**, the reverse of the entry's order, because
  `main.gd`'s member initializer calls `DevFlags.no_focus_pause()` and the other order leaves a
  commit that does not parse.

**Verified with** `tools/check.sh`, `tools/test.sh main pause invincible`, `tools/lint.sh`,
`tools/test_cli_help.sh`, and one `tools/shot.sh` still showing the day rather than the pause
screen from an unfocused window.
