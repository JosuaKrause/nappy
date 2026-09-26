## M90 — The controls do what the hand does · built 2026-09-07

Seven findings from [PLAYTEST-34.md](../playtests/PLAYTEST-34.md) and four more from
[PLAYTEST-35.md](../playtests/PLAYTEST-35.md), which arrived while this branch was still open and were built into
it rather than queued against it — **nothing merges carrying a defect that was already found**.

**Two root causes, and neither is visible in the diff that fixed it.**

**The joystick drag's reference point walked away with the camera.** `_on_tap()` converted the
chosen focus to world space **once**, into `_drag_origin_world`, and every later heading was measured
from that stale point — so as she walked, the camera carried the drawn ring away from the reference.
That is playtest 34's *"it moves a bit and then moves completely differently from what my movement
is"* exactly. The focus is stored in **design space** now and re-projected through
design->presented->world on every motion event. It also turned out to be the whole of a second
finding — *"the two joysticks are broken ... only the left joystick should be used as reference"* —
which was checked after this landed and needed nothing built.

**The pressed button was never a colour problem.** `ModeButton._ready()` sets
`mouse_filter = MOUSE_FILTER_IGNORE`, so a `Button` that ignores the mouse never enters its own
hover or pressed draw state: the near-white `Palette.BUTTON_PRESSED` M85 installed was correct and
had never once been selected. **The `IGNORE` is load-bearing** — it is playtest 29's fix for Godot's
GUI layer eating a raw touch before `_unhandled_input()` sees it, which is where all three screens
read their presses — so the look is driven from the screens' own raw reading through `catch_rect()`
instead.

**A third defect surfaced while fixing that one.** Buttons that fire on press close their screen in
the same input dispatch that sets the pressed fill, and **Godot draws no frame in between**, so the
flash was set and hidden without ever rendering. `DaySummary` had already found and fixed this for
its own touch path; the same two-`process_frame` shape now covers `TitleScreen` and `PauseScreen`.

**Numbers that moved:** `TAP_STOP_RADIUS` is `STOP_RADIUS / 2.0` (24 world px), because `STOP_RADIUS`
(48) was being compared in **world** space for `Mode.TAP` and in **design** space for the focus
rings — at zoom 2 that made the door round her twice the size of the drawn circle. Its centre then
moved up `Stroller.FIGURE_HEIGHT / 2.0` (23px), because everything in this game is feet-anchored and
the circle was covering 24px of pavement below her while her head sat outside it. Together those two
put the pram (34px away) outside the door, which is what *"if I click on the stroller it shouldn't
stop"* asked for — **and the docstring arguing the opposite went with them**, or the next reader
widens it back. `Palette.BUTTON_HOVER` became the midpoint of resting and pressed,
`(0.57, 0.54, 0.51, 0.92)`.

**Crossing the middle band re-targets the drag, overturning an M85 decision on the player's own
reasoning.** *Asked for a focus that sticks for the whole drag on 2026-09-07 (M85 recorded hysteresis
and a stickier focus as rejected, because the focus otherwise flipped as a pointer crossed the centre
line and snapped back and forth) · overturned on 2026-09-07, because "since there is a gap in the
middle that stops I think we should retarget to the other side when that happens".* **The stop band
is what makes it safe**: a pointer cannot cross the centre line without passing through `STOP_RADIUS`
either side of it, where she is stopped, so the crossing is a discrete event with a defined middle
rather than a continuous slide between two references. The re-pick happens on **leaving** the band,
not on crossing the bare line, and `nearer_focus()` ties only exactly on the centre line — 48px
inside either edge — so a pointer at the band's edge is already unambiguously on one side and cannot
oscillate. Sticky survives everywhere else.

**The two modes are named and not explained.** *(2026-09-07: "call the modes 'On-screen Controls'
and 'Tap to Go' no further explanations".)* Two earlier sentences in the same session asked to
simplify the captions and to stop mentioning stopping; the third is read as replacing both, being
later and strictly narrower. The `Tap to walk, double tap to run.` teaching line is a different
sentence and was left alone — and then **doubled in size, in all three places it appears**
*(2026-09-07: "can you double the size of the tutorial text?")*: the title body and pause body
16 -> 32, and `HUD`'s own `Teach` line 19 -> 38, which needed its fixed 520x30 rect grown to 1040x60
or the line would have clipped.
