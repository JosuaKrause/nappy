priority: now

# polite-swan — A run button beside each joystick focal point · filed 2026-10-03

> "for joystick mode a dedicated run button (one on each side next to the joystick) would make
> running much more precise and easier. the button should not trigger when moving the finger over it
> from navigation and holding the button and navigating should work correctly. also the double tap
> should still work since mouse only navigation would otherwise break."

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 5 (note #434). **In joystick mode, a run button sits beside each of the two focal
points** (`FOCUS_LEFT` (240,480) and `FOCUS_RIGHT` (1040,480) in `src/ui/touch_controls.gd`). It does
not press when a steering finger slides onto it; holding it while steering with the other hand works;
and the double press that latches running stays, for mouse-only play.

**What it collides with.** PLAYTEST-28 (2026-09-06) removed the held RUN circle at (1150, 500) when
running became a double press ("double press keeps running"), and `touch_controls.gd` still says the
held `RUN` circle is deleted. This brings a button back and keeps the double press, so nothing is
overturned; the PR quotes PLAYTEST-28.

**Proposed, not asked for:** running lasts while the button is held, rather than a press latching
it as the double press does.
