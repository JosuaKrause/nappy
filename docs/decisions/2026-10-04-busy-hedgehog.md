# busy-hedgehog — Returning to the page ignores input for half a second · built 2026-10-04

*([misty-toad](../playtests/2026-10-04-misty-toad.md), inbox #534: "When returning to the game all
inputs should be ignored for 500ms this is to prevent the game from immediately starting when
returning to the page. The player should see the day brief or pause screen".)*

**What was built** (PR #538). When the game gets focus back (`NOTIFICATION_APPLICATION_FOCUS_IN`,
`NOTIFICATION_APPLICATION_RESUMED`), `main.gd` disables the viewport's input for
`RETURN_INPUT_IGNORED_MSEC` (500ms), so no `_input()`, GUI or `_unhandled_input()` handler, the
touch controls' included, sees an event; a real-time timer that runs while the tree is paused
re-enables it. A gate in `main._input()` was not enough, since a child's `_input()` runs before its
parent's. On the web a second trigger arms the same window: `document`'s `visibilitychange` when
it turns visible, and `window`'s `focus`, through `JavaScriptBridge`. Arming again extends the
window. [M161](2026-09-19-M161-the-game-pauses-when-it-loses-focus-and-a-rig-can-say-not-to.md)'s
pause on focus loss is unchanged, so a return during play shows the pause screen and a return
during the day brief shows the day brief. Polled input is not dropped: a key held through the
return stays pressed; only events are.

`tests/test_main.gd` pushes real presses through the viewport: inside the window the pause screen
stays open and the day brief does not start, and the same press after it acts, for both
notifications.

**Not observed:** which engine notification the web build sends on a real tab return. An automated
desktop Chrome tab stays hidden and unfocused, so no real return could be produced; a dispatched
`focus` armed the window and a `visibilitychange` while hidden did not. The review item
[busy-hedgehog](../review/2026-10-04-busy-hedgehog.md) asks for a real return.

**Proposed, not asked for, and open to overturn:** the window timed on real time, since the tree is
paused behind the pause screen; the window also opening on a focus-in at boot, if the platform
sends one; nothing armed under `--no-focus-pause` or `--screenshot`, so a rig's presses are not
delayed; disabling the viewport's input rather than filtering events, so held keys stay held;
nothing on screen marking the 500ms.
