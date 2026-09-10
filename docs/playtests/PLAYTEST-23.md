# Playtest 23 — 2026-09-05

The first phone session on the rotated presentation, on `v0.1.1` at the live address, Android
Chrome, auto-rotate off so the device never leaves portrait. **Three findings and they are three
different rotations in one picture.**

---

## 1. The controls are rotated correctly

> "the controls are rotated correctly"

The one part that was tested is the one part that is right. `tests/test_orientation.gd` sends a
touch at the position the stick, RUN and pause are drawn at while rotated and asserts
`TouchControls` reads it back, and `TouchControls._draw` sets
`ScreenOrientation.rotation_transform()` for the whole call so the buttons are drawn where that
same transform puts them.

## 2. The game area is rotated 180° from the controls

> "the game area is rotated 180 from that"

So the world is upside down with respect to the buttons steering it. The world's half of the
rotation is `Stroller.set_screen_rotation()`, which sets `Camera2D.rotation` and clears
`ignore_rotation`; the controls' half is `TouchControls._draw`'s
`draw_set_transform_matrix(ScreenOrientation.rotation_transform())`. **Rotating a camera by +90°
and rotating a drawing by +90° move the picture in opposite directions** — a camera turning
clockwise swings the world counter-clockwise on screen — and 90 against −90 is the 180 the player
is reporting.

## 3. The text is not rotated at all

> "the text is not rotated at all"

> "controls are the only things that are rotated correctly"

The HUD — the clock, the two meters, the optional goal, the developer readout — lives on its own
`CanvasLayer` of `Control` nodes, which nothing in the change touched. It was known before the
release: the implementing agent named it, and it was published anyway as a "known limitation".
**It is not a limitation, it is the feature being half-built**: the whole claim of a rotated
presentation is that the screen reads sideways, and text that stays upright is the largest, most
readable thing on it saying otherwise.

## 4. Turning auto-rotate on stops the rotation but leaves the play area portrait-shaped

> "if I turn on auto rotate it behaves correctly (stops rotating in game) but the viewport is now
> higher than wide and the game is stretched vertically"

So the decision to stop rotating is taken and acted on — the world and the controls come back — and
**the shape of the play area does not follow it.** `project.godot` sets
`window/stretch/aspect="keep"`, which letterboxes rather than stretching, so a play area taller than
it is wide on a landscape screen means the rotated content box (`ScreenOrientation.ROTATED_SIZE`,
720×1280) is still in force after the rotation was switched off.

`main._apply_orientation()` sets `Window.content_scale_size`, the camera and the controls from one
boolean and is re-run on `size_changed`, so the three cannot disagree within a single call. That
narrows it to what happens *between* calls — which size the decision reads at the moment a browser
canvas is being resized, and whether anything re-applies the content box afterwards.

**And it does not recover.**

> "and if I then rotate back it stays like that"

So this is a latch rather than a transient: the state survives going back to the orientation that
produced it correctly the first time. That is the shape of a decision reading a value the decision
itself changed — `ScreenOrientation.wants_rotation()` is given `get_window().size`, and the feature
swaps `Window.content_scale_size` to 720×1280 as part of rotating. If those two are the same number
on a web build, the gate can never see landscape again once it has fired, and only a reload clears
it.

---

## What this says about how it was verified, which is the finding under the findings

**Every one of these is a picture, and no picture was ever looked at.** The change was accepted on
a test that asserts input mapping — true, and it is why finding 1 passes — and on two screenshots
the agent compared against its own independently computed transform, which cannot catch a sign
error the transform and the drawing share.

**The rotation was photographable and was never photographed.** Both halves of what
`ScreenOrientation.wants_rotation()` asks for are already reachable from a development machine:
`--touch` forces `TouchInput.available()` true in a debug build — it is how M60's on-screen stick
and `RUN` button were looked at — and a portrait window is what the other half wants. The one thing
in the way is that `tools/shot.sh` passes a hardcoded `--resolution 1280x720`, so every picture the
rig can take is of the landscape branch, which is the branch that was already correct.

So a feature whose entire content is what the screen looks like was one shell argument away from
being looked at, and that is the defect that produced the other three.
