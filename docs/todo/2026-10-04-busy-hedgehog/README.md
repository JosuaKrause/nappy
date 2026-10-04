priority: now

# busy-hedgehog — Returning to the page ignores input for half a second · filed 2026-10-04

[misty-toad, a return to the page waits half a second](../../playtests/2026-10-04-misty-toad.md)
files inbox #534 in [misty-toad](../../playtests/2026-10-04-misty-toad.md), band `now` as the player labelled it:

> When returning to the game all inputs should be ignored for 500ms this is to prevent the game from immediately starting when returning to the page. The player should see the day brief or pause screen

**Asked for:** for 500ms after the player returns to the game, every input is ignored, so the tap
or click that brings the page back does not also start the day or resume play; the player sees the
day brief or the pause screen first.

**What exists.** [M161](../../decisions/2026-09-19-M161-the-game-pauses-when-it-loses-focus-and-a-rig-can-say-not-to.md)
opens the pause screen when the game loses focus (`main.gd`'s `_notification()` on
`NOTIFICATION_APPLICATION_FOCUS_OUT` and `NOTIFICATION_APPLICATION_PAUSED`), and does nothing on
the title, the day summary or the ending, or while the pause screen is already open. Getting focus
back (`NOTIFICATION_APPLICATION_FOCUS_IN`, `NOTIFICATION_APPLICATION_RESUMED`) is not answered, so
the first press after coming back reaches whatever screen is up: it resumes from the pause screen
or starts the day from the day brief. M161's record notes that a real desktop focus change was
never observed by its agent.

**Proposed, not asked for:**

- "Returning" read as getting focus back (`FOCUS_IN`) or the app being resumed (`RESUMED`), on
  the web page, the desktop and the phone alike; the 500ms runs from that notification.
- Every input means every input event the game reads — touch, mouse, keys and the actions they
  press — swallowed at one place before any screen sees it, so no screen needs its own guard.
- A return during play shows the pause screen M161 already opened; a return during the day brief
  shows the day brief; on the title, the summary and the ending the same 500ms applies. Nothing on
  screen marks the 500ms.
