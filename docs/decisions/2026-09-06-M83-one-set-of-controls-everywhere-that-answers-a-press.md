## M83 — One set of controls, everywhere, that answers a press — 2026-09-06

**[PLAYTEST-29.md](../playtests/PLAYTEST-29.md), and it opens by rejecting a status report rather than the
build**: *"I did not approve any of this."* M82's own end-of-session note listed two things as known
and deliberate — the pause button still painted in `_draw()` primitives, and an unreachable
mouse-click branch on the continue and restart buttons. Neither had been agreed, and three of this
milestone's six items are instructions the project already had and read as repealed by something
else.

**The buttons did not work at all, and the cause was one default.** *(2026-09-06: "in the pause and
day screen on mobile I have to click anything but the buttons. the buttons themselves do nothing.
that is exactly the opposite of what I was requesting".)* `ModeButton` extends `Button`, whose
`mouse_filter` defaults to `MOUSE_FILTER_STOP`, and Godot's GUI layer — which runs between `_input`
and `_unhandled_input` — consumes a raw `InputEventScreenTouch` that lands on a `STOP` control.
`PauseScreen` and `DaySummary` read every press in `_unhandled_input()` and nowhere else, and the
button's own `pressed` signal is deliberately connected to nothing, so the press was swallowed and
discarded. `mouse_filter = MOUSE_FILTER_IGNORE` is the fix.

**Nothing in the suite could have caught it, and the reason generalises.** Every touch test in the
project called `_unhandled_input()` directly with a synthetic event, which is the one path that
skips the GUI layer entirely — so the defect lived precisely in the gap between the engine's
dispatch and the function the tests called. The four regression tests added here push a real event
through `get_viewport().push_input(event, true)` instead. **The second argument is load-bearing and
cost a wrong answer first**: without it the viewport applies the window's own stretch transform to
the event position, and a headless window is 64x64 rather than 1280x720, so the press lands far
from the button and the screen's catch-all fires — which reads exactly like the button working.
The fix was verified by reverting `mouse_filter` to `STOP` and watching those four checks fail.

**Every button now shows on every device**, the continue and restart pair and the pause button
alike. *(2026-09-06: "I specifically said that now all controls are treated the same across
platforms so the buttons should show in *every* environment".)* This overturns M76's own reason —
*"The continue/restart pair only replaces a sentence where there is a thumb to press it with"* —
which was taken while a device chose between two control schemes, and M82 deleted the choice.

**One consequence did not follow automatically, and the brief was wrong to say it would.** The
expectation was that the top-right corner ceasing to be an aiming surface on a desktop fell out of
`_on_touch()`'s existing `visible` gate. It did not: `TouchControls._input()`'s mouse branch called
`_on_tap()` directly and bypassed the corner check, so a desktop would have drawn a pause button
that could not be clicked. The touch and mouse paths are folded into one `_on_pointer()`, with
`_MOUSE_POINTER_INDEX` standing in for the touch index a mouse event carries none of — the same
device `PauseScreen._MOUSE_HOLD_INDEX` already used. **The `not _touch` gate on the mouse branch
stays**, because a real touch device emulates a click from every finger and dropping it double-fires.

**The keyboard stays and is never named on screen.** *(2026-09-06: "I said to remove the keyboard
inputs altogether but I'm willing to compromise on letting them stay *silently*", and then "never
should it be mentioned to the user".)* **M82 read this the other way and flagged the reading as the
one thing worth being told about** — *"The keyboard is not a mode and stays"* — and it was wrong.
Arrows, `WASD`, `Shift`, `Esc`, `space`, `R` and `Q` all keep working; every sentence naming one is
gone from the pause body, the pause and summary hints, the title screen and `hud.gd`'s three teach
lines, which now carry only their tap wording.

**`q to quit` went with them, and the pointer route is the window's own close button** *(2026-09-06,
asked whether quitting needed an in-game button once no key may be named, since "they should never
be required": **"no window close is fine"**)*. On the web build — the only one distributed —
`QuitOption.available()` is already false and there is no quit at all. Every other action already
had a pointer route.

**The pause button became an SVG asset, closing what M82 recorded below as "Not built as
specified".** *(2026-09-06: "neither should the buttons use draw commands -- I *explicitly* said
that icons/symbols do *not* count as graphics", closing the earlier "never draw in code -- at the
very least use svgs".)* M82 deferred the conversion under `TODO.md`'s *"drawing work is
deprioritised while the graphics overhaul is in flight"*; **that deferral never covered a control's
icon**, and reading it as cover is what this closes. `assets/ui/pause.svg` carries the disc, the rim
and the two bars in one asset, drawn with `draw_texture_rect()`.

**The baked scene text counted too.** Three `.tscn` files carried key names as their authored
default label text, overwritten at runtime but read by anyone opening the scene, and two also baked
"Arrows or WASD"/"Hold Shift" into their body labels. All five were cleared.

**The hold fills the disc rather than a bar beside it.** *(2026-09-06: "the hold button should fill
up in its entirety while holding *not* have a separate bar".)* A radial sweep from 12 o'clock
clockwise, drawn as a triangle fan through `draw_colored_polygon` at `Color(1, 1, 1, 0.4)`. **The
translucency is the whole design constraint**: a script `_draw()` on a `Button` paints *over* the
stylebox and the icon, so an opaque fill would hide the SVG glyph as the sweep passed across it.
The 16px the old bar reserved in `custom_minimum_size` came back.

**A touch aims from one of two fixed focal points; a mouse still aims from her.** *(2026-09-06:
"let's not make the directions in relation to the player but define two points equally apart from
the border on each side (same distance from top/bottom/and its side) and use those as reference
whichever is closer to the touch… this is because right now the finger needs to reach over half the
phone to be able to input an up or down direction", and "that two focal point mode should only
exist for the touch enabled version *not* the mouse version".)* **The geometry was arithmetic
rather than a choice**: same distance from top and bottom puts both at y = 360 in the 1280x720
design box, and the same distance from each one's own side makes that distance 360 — so
`FOCUS_LEFT` (360, 360) and `FOCUS_RIGHT` (920, 360), each a full 360° dial around its half of the
screen. A press takes the nearer; a press within `STOP_RADIUS` of either focus stops her, alongside
a press near her own position.

**The coordinate spaces cannot be mixed, and that is the one hard part.** "Which focus is nearer"
and "is this press on a focus" are asked in **design space**, where half the screen means half the
screen. The heading needs the focus in **world space**, so the chosen focus makes the same
design → presented → world trip a raw touch's position already takes, the other direction — a
design-space subtraction would ignore the camera and the zoom and, on a rotated portrait
presentation, point the wrong way outright. `set_direction()` gained an optional `from` parameter
defaulting to `Vector2.INF`, read as "her own world position", so every existing caller is unchanged.

**Three choices were made where the design was silent, and each is cheap to overturn.** The focus
stop door reuses `STOP_RADIUS` (48px) because no separate number was named and it is the file's one
"how close counts as stop" radius. `nearer_focus()` breaks a tie toward `FOCUS_LEFT`, which can only
happen exactly on the design box's centre line. The pause button's held/idle contrast is one overall
alpha (0.7 idle, 1.0 held) multiplying `assets/ui/pause.svg`, whose three shapes carry their own
relative opacities, because there is no `Button` here to tint an icon through.

**Two test bugs surfaced on the way and are worth the sentence.** With the buttons always visible,
an unpositioned restart button sitting at its pre-layout `(0, 0)` rect swallowed a `(0, 0)` test
tap in two existing tests. And a first draft of the rotation test silently exercised an unrotated
camera, because `Camera2D.ignore_rotation` defaults to `true`.

**Nothing is drawn for the two focal points.** *"for now we don't need visuals to indicate those two
reference points -- I think they will be fairly intuitive. will have to test it out though."*
Whether they can be found by feel is the played question this milestone leaves open.
