## M85 — One press, answered · built 2026-09-07

Eight findings from [PLAYTEST-33.md](../playtests/PLAYTEST-33.md), and one milestone because they are one
subject: **what a press does, and what the screens around a run say about it.**

**The two focal points moved a third of the way out and a third of the way down.** *(2026-09-07:
"Move the center of the focal points 1/3 towards the sides and 1/3 towards the bottom of the
screen.")* M83 put each the same distance from the top, the bottom and its own side, which made that
distance 360 in the 1280x720 design box. A third of the remaining gap is 120px, so `FOCUS_LEFT` is
`(240, 480)` and `FOCUS_RIGHT` is `(1040, 480)`.

**Both circles are drawn, and they show the state rather than only the place.** *(2026-09-07: "show
the control circles again on both sides so the user can see what is currently locked in.")* M83 drew
nothing and left *whether they can be found by feel* as the played question the next report would
answer; the answer was no. Each ring is `STOP_RADIUS` (48px) itself — the ring's edge **is** the
boundary between the two doors a press through it can open, rather than an aesthetic size — with a
knob offset by `_direction`, the one heading the whole scheme holds. Centred reads as stopped;
brighter and larger while `run` is held. **On a touch build only**: a mouse aims from her own world
position, so a circle would name a point that means nothing there.

**Primitives rather than an SVG, which is the cues rule's own exception and not a violation of it.**
A knob whose offset is a continuous function of the heading cannot be a static asset, the same call
`ModeButton`'s hold-progress sweep already makes: *"a fill that is not a drawing of anything is not a
picture."*

**A held pointer keeps re-aiming, and that is not the drag stick coming back.** *(2026-09-07:
"dragging the finger doesn't work anymore but should", and "although dragging a mouse should reaim
as well".)* The difference is the whole reason it is allowed: `_on_drag()` recomputes through
`set_direction()`, which **always normalises**, rather than pressing a partial vector for a thumb
short of some rim. M82 deleted the stick because partial deflection was the one input path that
could walk her at anything other than `Tuning.WALK_SPEED` (92px/s), and every pursuit lead time in
`src/autoload/tuning.gd` is computed against 92 as *the* walking speed;
`tests/test_touch.gd`'s `_test_no_input_path_presses_a_vector_shorter_than_one` still passes. *The
overlap was put to the player as a question rather than inferred, and they chose live re-aim at one
speed over the analog stick.*

**Only the drag's origin differs between a mouse and a finger**, which is the one difference the
scheme already had: a touch re-aims from the focus its opening press chose, a mouse from her own
position. Godot never sends `InputEventScreenDrag` for a mouse, so a held left button's motion is
read off `InputEventMouseMotion` with `button_mask` checked — a snapshot of every button down at
that motion, not only the one that opened the press.

**The middle of the screen is not a direction at all.** *(2026-09-07: "there should be a narrow band
in the middle of the screen (size of the stop circle) that stops the player. this is to prevent
moving the finger over the middle of the screen and quickly flicking back and forth.")*
`nearer_focus()` flips the instant a press crosses the centre line, so a drag wandering there swaps
a heading measured from `(240, 480)` for one measured from `(1040, 480)` — pointing somewhere
entirely different — and snaps back and forth while barely moving. **Hysteresis and a stickier focus
were the obvious answers and are recorded as rejected**: declaring the middle not-a-direction removes
the flip rather than damping it. The band is `STOP_RADIUS` either side of
`ScreenOrientation.DESIGN_SIZE.x / 2.0`, reading *"size of the stop circle"* as its **diameter** —
confirmed by the player rather than inferred *(2026-09-07: "the band doesn't get drawn and yes it's
the diameter in size")* — and it is **not drawn**, and it applies during a drag rather than only on
the opening press, since a drag wandering into the middle is the whole of what it is for.

**Tapping her to stop is gone on touch and kept on a mouse.** *(2026-09-07: "with that we can remove
tap the player to stop since it's the same area ... mouse click doesn't have the band and will keep
the click the player to stop behavior".)* "The same area" is literally true and the camera is what
makes it so: the camera sits on her, so her own screen position is the band's centre line. With a
drag it stops being harmless — a finger sweeping across the screen crosses her without meaning to.
**All three touch/mouse disagreements have one cause**: a mouse aims from her and a finger aims from
a focus. `set_direction()`'s fallback for a press exactly on `from` stays, since one test calls
straight in with an exact point.

**The movement lesson says two things and nothing else.** *(2026-09-07: "the movement tutorial
should just say 'Tap to walk' and 'Double tap to run'. no mention of tapping her or 'that way'.")*
Both `TitleScreen` and `PauseScreen` carried the two struck clauses in one sentence. **Stopping still
works and simply stops being taught** — the same way the keyboard still walks and runs with nothing
on screen naming a key.

**Pressed is bright, overturning the reasoning that was written beside the constant.**
*(2026-09-07: "buttons should light up white when pressed.")* `Palette.BUTTON_PRESSED` was
`(0.11, 0.09, 0.08, 0.95)` — *darker* than `BUTTON_FILL` — with a comment arguing darker is what
pressed reads as. It is now `(0.95, 0.93, 0.88, 0.95)`. **It reached three things, not two**: both
`ModeButton` symbols through `_apply_disc_style()`, `DaySummary`'s `force_pressed_look()` flash that
acknowledges a tap before the day it starts blocks the frame, and the pause button — which said
pressed with alpha (0.7 idle, 1.0 held) rather than a stylebox and therefore needed its own answer.
Going more opaque makes an icon solid, not bright, so a `draw_circle()` fill in the same colour sits
behind it.

**A tap on the ending screen no longer lands in the game, and the fix is a window rather than a
reorder.** *(2026-09-07: "tapping on the game over screen often goes directly back to the game
skipping the title screen.")* The route is `DaySummary` → `main._restart_run()` →
`reload_current_scene()` → the fresh title screen's `_ready()`, and that screen begins the run on any
press — up within a frame or two of the press that dismissed the ending. **"Often" rather than
always is the shape of a race**, and nothing about that sequence can be made to happen in a different
order, only made to ignore the frames right after it. `TitleScreen._restarted_at_msec` is a
`static var` on the class rather than a member on the node, because the node is the thing being
freed — the one place a fact survives the reload without adding an autoload to hold it. The window is
`TouchControls.DOUBLE_TAP_SECONDS` (0.35s) reused rather than a number invented here, since both ask
the same question of a press: is this the same gesture as the one just before it. It never fires on
an ordinary boot, since `_restarted_at_msec` starts at `-INF`.

**Every direction key begins a run, silently.** *(2026-09-07: "awsd and arrows should start the game
in addition to space.")* `WASD` and the arrows are bound to the four `move_*` actions, which the
title screen never read. The hint stays `tap to begin` and names no key, the same way nothing in the
game names one.
