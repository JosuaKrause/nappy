# busy-hedgehog — Returning to the page ignores input for half a second · built 2026-10-04

*([misty-toad](../playtests/2026-10-04-misty-toad.md), inbox #534: "When returning to the game all
inputs should be ignored for 500ms this is to prevent the game from immediately starting when
returning to the page. The player should see the day brief or pause screen".)*

**What was built** (PR #538). When the game gets focus back (`NOTIFICATION_APPLICATION_FOCUS_IN`,
`NOTIFICATION_APPLICATION_RESUMED`), `main.gd` disables the viewport's input for
`RETURN_INPUT_IGNORED_MSEC` (500ms), so no `_input()`, GUI or `_unhandled_input()` handler, the
touch controls' included, sees an event; `main._process()`, which runs while the tree is paused,
reads the wall clock each frame and re-enables it on the first frame past the end, and leaving the
scene (`_exit_tree()`) or a fresh `_ready()` re-enables it too, so no path leaves input off. A
one-shot timer was tried first and could fire before the 500ms was up, leaving input off for good. A gate in `main._input()` was not enough, since a child's `_input()` runs before its
parent's. On the web a second trigger arms the same window: `document`'s `visibilitychange` when
it turns visible, and `window`'s `focus`, through `JavaScriptBridge`. A second trigger inside
the window does nothing unless the game has left again in between (below). [M161](2026-09-19-M161-the-game-pauses-when-it-loses-focus-and-a-rig-can-say-not-to.md)'s
pause on focus loss is unchanged, so a return during play shows the pause screen and a return
during the day brief shows the day brief. Polled input is not dropped: a key held through the
return stays pressed; only events are.

`tests/test_main.gd` pushes real presses through the viewport: inside the window the pause screen
stays open and the day brief does not start, and the same press after it acts, for both
notifications.

**Observed once natively:** bringing the macOS window to the front delivered
`NOTIFICATION_WM_WINDOW_FOCUS_IN` and `NOTIFICATION_APPLICATION_FOCUS_IN` in the same millisecond,
the window armed, and input came back 502ms later. **Not observed:** a real return on the web or the
phone, and so which engine notification the web build sends on a tab return. An automated desktop
Chrome tab stays hidden and unfocused, so no real return could be produced there; a dispatched
`focus` armed the window and a `visibilitychange` while hidden did not. The review item
[busy-hedgehog](../review/2026-10-04-busy-hedgehog.md) asks for a real return.

**The window opens only on a return** (PR #548): after the game has actually left, on a focus-out
or a pause notification, or on the web the page going hidden or the window blurring, and never on
the first focus at load. Arming at load dropped the browser check's first key press and failed the
v0.25.0 deploy before it published; a player's first tap within half a second of the page loading
was lost the same way. A departure is spent by the arming it allows.

**Proposed, not asked for, and open to overturn:** the window timed on real time, since the tree is
paused behind the pause screen; nothing armed in any rig run (`DevFlags.is_rig()`: `--screenshot`, `--walk`, `--flee`,
`--press`, `--tap`, `--route`, a recording, a scripted recipe) or under `--no-focus-pause`, so a
rig's presses are not delayed; disabling the viewport's input rather than filtering events, so held keys stay held;
nothing on screen marking the 500ms.
