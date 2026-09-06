# Playtest 29 — 2026-09-06

The fourth session on the released page and the third of the day, played on a phone and checked
against the local build, given as notes in one conversation. **Seven findings.** Five are things
that are wrong with what M82 and M76 built; two of those five are the project having overturned an
instruction without asking, and the player says so directly. The sixth is a change to how the hold
button reads. The seventh is a new design for how a direction is aimed on a touch device, and it is
the largest thing here.

**It opens with a rejection of a status report rather than of the build.** The end-of-session note
for M82 listed two things as "known and deliberate" — the pause button still drawn in code, and an
unreachable mouse branch on the continue and restart buttons. Neither had been agreed:

> "I did not approve any of this."

That sentence governs findings 1, 2 and 3 below. Each is an instruction that already existed and
was read as repealed by something else.

---

## 1. The buttons do not show on a desktop, and they should

> "I did another testrun. the mobile buttons don't show up on the local version."

> "next, I specifically said that now all controls are treated the same across platforms so the
> buttons should show in *every* environment."

`PauseScreen._refresh_buttons()` and `DaySummary._refresh_buttons()` are each one line —
`_buttons.visible = _touch` — where `_touch` is `TouchInput.available()`, which asks
`DisplayServer.is_touchscreen_available()`. A laptop answers false, so the continue and restart
pair is drawn on a phone and on nothing else.

**The reason written beside it is the one being overturned**: *"The continue/restart pair only
replaces a sentence where there is a thumb to press it with — a mouse-and-keyboard desktop keeps
`space`/`esc`/`r`, which already read as a control there and need no picture beside them."* That
was M76's split, taken while two control schemes existed and one of them was chosen by device.
M82 deleted the choice — there is one scheme now, a press sets a direction on every device — and
the player's instruction is that the screens follow: **the same buttons everywhere, because there
is one set of controls everywhere.**

**The pause button is in the same sentence.** `TouchControls._process()` sets
`visible = _touch and not paused`, so the one control the game draws during a day is also absent on
a laptop, where the same mouse click already walks her. "Every environment" reaches it too.

## 2. The buttons do not work at all

> "next, the buttons do *not* work at all. in the pause and day screen on mobile I have to click
> anything but the buttons. the buttons themselves do nothing. that is exactly the opposite of what
> I was requesting."

**Diagnosed and reproduced, not inferred.** `ModeButton` extends `Button`, and a `Control`'s
default `mouse_filter` is `MOUSE_FILTER_STOP`. Godot's GUI layer runs between `_input` and
`_unhandled_input`, and it consumes a raw `InputEventScreenTouch` that lands on a `STOP` control —
so the press never reaches `PauseScreen._unhandled_input()` or `DaySummary._unhandled_input()`,
which is where every one of this project's screens actually reads a press. The button's own
`pressed` signal is connected to nothing, by design. **The result is a button that eats the press
and does nothing with it, sitting on a screen where pressing anywhere else works.**

**The comment above `PauseScreen._handle_restart_touch()` states the opposite as fact** — *"a
`Button` consuming the emulated click would not stop the raw touch from reaching the catch-all
underneath it"* — and the raw touch is exactly what gets stopped. The emulated mouse click was the
part that was reasoned about; the real finger was not.

**Nothing in the suite could have caught it**, and that is the more useful half. Every touch test in
`tests/test_pause.gd` (which covers the day summary's buttons as well as the pause screen's) and
`tests/test_touch.gd` calls `_unhandled_input()`
directly with a synthetic event, which is the one path that skips the GUI layer entirely. The
defect lives precisely in the gap between the engine's dispatch and the function the tests call.
**A test that pushes a real event through `get_viewport().push_input(event, true)` is what would
have caught it, and is what this milestone owes.** (The second argument matters: without it the
viewport applies the window's own stretch transform to the position, and a headless window is not
1280×720, so an untransformed push lands somewhere else entirely and quietly passes.)

## 3. The buttons may not be drawn in code

> "neither should the buttons use draw commands -- I *explicitly* said that icons/symbols do *not*
> count as graphics."

**This is a re-report and it says so.** *(2026-09-06: "never draw in code -- at the very least use
svgs".)* `ModeButton` already obeys it: its disc is a `StyleBoxFlat` and its glyph is a preloaded
SVG under `assets/ui/`. **`TouchControls._draw_pause_button()` does not** — it draws a filled
circle, an arc for the rim and two rectangles for the bars, and M82's own record in `DECISIONS.md`
lists that as *"Not built as specified: the SVG-icon conversion the `cues` rule asks for"*, deferred
under `TODO.md`'s *"drawing work is deprioritised while the graphics overhaul is in flight"*.

**That deferral does not cover this and never did.** An icon or a symbol on a control is not
graphics work in the sense the overhaul defers; the deprioritisation is about the game's pictures.
So the pause button becomes an SVG asset like every other glyph, and the deferral stops being read
as licence to paint one in code.

## 4. The keyboard stays, but silently

> "in fact I said to remove the keyboard inputs altogether but I'm willing to compromise on letting
> them stay *silently*."

**M82 recorded the opposite reading and marked it as the one thing worth being told about**: *"The
keyboard is not a mode and stays. … If that reading is wrong it is the one thing here worth saying
so about, because it is a device rather than a scheme."* It was wrong. The instruction was to
delete the keyboard, and the compromise offered here is that the keys keep working while **nothing
on screen names one**.

What names one today, and goes:

- `PauseScreen._BODY_KEYBOARD` — *"Arrows or WASD to walk. / Hold Shift to run — it wakes her, so it
  is rarely worth it. / Walk to calm ground and stay moving; standing still settles nothing."* The
  third line is not about the keyboard and survives; the first two name keys.
- `PauseScreen._refresh_hint()`'s desktop hint — *"space or esc to carry on · r to start again"*,
  plus *"· q to quit"* where quitting is available at all.
- `DaySummary._hint_text()` — *"space to go on"*, *"space to try again"*, *"space to start again"*.
- `TitleScreen`'s own hint, wherever it names `space`.
- `hud.gd`'s teach lines, wherever they name a key.

`q to quit` goes with them. It is the one verb no button carries, so a desktop player is left with
the window's own close button — stated here rather than assumed, because it is the one thing this
finding costs.

## 5. The hold button fills itself, not a bar

> "also the hold button should fill up in its entirety while holding *not* have a separate bar."

Today `ModeButton._draw()` paints a 6px track 10px below the disc and fills it left to right as
`hold_progress` runs 0→1 — `RESTART_HOLD_SECONDS` is 1.0. The player wants the **disc itself** to
fill, and the separate bar gone. That also gives the row back the 16px of height the bar reserved in
`custom_minimum_size`.

## 6. Two focal points, and the direction is measured from the nearer one

> "now for something almost new. let's not make the directions in relation to the player but define
> two points equally apart from the border on each side (same distance from top/bottom/and its side)
> and use those as reference whichever is closer to the touch. tapping in their center or on the
> player should stop the player still. this is because right now the finger needs to reach over half
> the phone to be able to input an up or down direction. for now we don't need visuals to indicate
> those two reference points -- I think they will be fairly intuitive. will have to test it out
> though."

> "that two focal point mode should only exist for the touch enabled version *not* the mouse version
> where the direction uses the player as reference."

**The complaint is reach, and it is a one-handed complaint.** M82 measures the heading from her own
world position — `TouchControls.set_direction()` takes `heading_to(world_target, rig.global_position)`
— so *up* means pressing above her, wherever on the screen she happens to be. A thumb holding the
phone cannot get above a player standing near the top of the view without the other hand.

**The design is fully determined by the sentence.** Two reference points, each the same distance
from the top, from the bottom and from its own side. In the 1280×720 box every screen in this game
is authored against, "same distance from top and bottom" puts both at y = 360, and "same distance
from its own side" as well makes that distance 360 — so the points are **(360, 360)** and
**(920, 360)**, and each half of the screen is a full 360° dial around its own focus.

**A press picks the nearer focus and the direction is the heading from that focus to the press.**
A press within a stop radius of either focus stops her, and a press on her still stops her too —
both, not one instead of the other.

**Touch only.** With a mouse the direction stays measured from her, exactly as M82 built it. So
this is the one place the two devices deliberately differ, and the player drew that line
themselves.

**No drawing.** *"for now we don't need visuals to indicate those two reference points — I think
they will be fairly intuitive. will have to test it out though."* So the next report on this is
whether they can be felt without being seen, and that question is what the milestone is for rather
than something to be argued now.

## 7. The mouse branch on the buttons was flagged as unreachable, and finding 1 makes it reachable

The M82 note listed the continue and restart buttons' mouse-click handling as dead code, kept for
consistency, because the buttons only ever showed on a touch device. **Finding 1 shows them
everywhere**, so that branch is the desktop's only way to press them and it is live. Nothing to
build here beyond finding 1 — recorded so the "unreachable" note does not outlive the reason it was
true.

---

## What this asks of the next session

Nothing in findings 1–5 is a design question; each is an instruction that already existed. Finding
6 is a new design and it is specified above in full. **The thing that is not yet answered is
whether two unmarked focal points can be found by feel**, and that is a played question.
