# Playtest 33 — 2026-09-07

A session on the build M83 left, given as notes in one conversation. **Eleven findings and one
question.** Six are about the controls and the screens around them — the focal points M83 added but
drew nothing for, the drag that went with the deleted stick, the wording of the movement lesson, the
pressed look of a button, a tap on the ending screen that lands in the game, and the keys that begin
a run. Four are about where events arrive from, and they raise M77 to the front of the queue. One is
a lethality defect on the cyclist. The question is about `tools/release.sh`.

---

## 1. The focal points move outward and downward

> "Move the center of the focal points 1/3 towards the sides and 1/3 towards the bottom of the
> screen."

`TouchControls.FOCUS_LEFT` and `FOCUS_RIGHT` are the two fixed points a real touch aims from, at
`(360, 360)` and `(920, 360)` in the 1280x720 design box — M83 put each the same distance from the
top, the bottom and its own side, which made that distance 360 in every direction. A third of the
way further out and a third of the way further down is the same 120px in each case:

| | now | asked |
|---|---|---|
| `FOCUS_LEFT` | `(360, 360)` | `(240, 480)` |
| `FOCUS_RIGHT` | `(920, 360)` | `(1040, 480)` |

`STOP_RADIUS` (48px) is measured from these, so the two "tap the middle to stop" discs move with
them. Nothing else in the file is authored against either constant.

## 2. The control circles come back, on both sides

> "also, show the control circles again on both sides so the user can see what is currently locked
> in."

M83 drew nothing for the focal points and left *whether they can be found by feel* as the open
question the next report answers. This is that report, and the answer is that they should be drawn.
**What they show is the state, not just the place**: the direction currently locked in, so the
player can read what she is walking at without watching her.

## 3. Dragging the finger works again

> "dragging the finger doesn't work anymore but should."

M82 deleted the drag stick because partial deflection was the one input path in the game that could
walk her at anything other than `Tuning.WALK_SPEED` (92 px/s), and every pursuit lead time is
computed against 92 as *the* walking speed; `tests/test_touch.gd`'s
`_test_no_input_path_presses_a_vector_shorter_than_one` holds that rule. The overlap was put back to
the player as a question rather than inferred, and **the answer is the reading that keeps the rule**:

> Live re-aim, one speed — press and hold, and the direction updates continuously from the nearer
> focal point to wherever the finger currently is, locking in on lift. Always full `WALK_SPEED`;
> deflection distance means nothing. A double press that then drags holds `run` the same way.

So this is not the analog stick coming back. It is the press that already sets a direction being
allowed to keep setting it while the finger is still down.

## 4. The movement lesson says two things and nothing else

> "the movement tutorial should just say "Tap to walk" and "Double tap to run". no mention of
> tapping her or "that way"."

Three places carry the wording. `HUD._teach_the_day()` says `Tap to walk, double tap to run` on day
1, and `TitleScreen._BODY` and `PauseScreen._BODY` both open with
`Tap to walk that way, tap her to stop, double tap to run.` — the two clauses the player is
striking out are in the second sentence, on both screens.

## 5. A pressed button lights up white

> "buttons should light up white when pressed."

`Palette.BUTTON_PRESSED` is `Color(0.11, 0.09, 0.08, 0.95)` — **darker** than
`BUTTON_FILL` (`0.18, 0.15, 0.13`), with the comment beside it arguing that darker is the pressed
reading. That is the thing being overturned: pressed should be bright, not dim.

It reaches more than the two `ModeButton` symbols. `DaySummary._acknowledge_and_continue()` calls
`force_pressed_look()` for a press that landed anywhere on the screen, which is the flash a player
sees acknowledging their tap; the pause button in `TouchControls._draw_pause_button()` says the same
thing with alpha (0.7 idle, 1.0 held) rather than with a stylebox.

## 6. A tap on the ending screen lands in the game

> "tapping on the game over screen often goes directly back to the game skipping the title screen."

The route is `DaySummary` → `continued` → `main._on_summary_continued()` → `_restart_run()` →
`get_tree().call_deferred("reload_current_scene")` → the new scene's `_ready()` →
`main._open_the_title()`. The title screen then begins the run on any press
(`TitleScreen._unhandled_input()` reads `TouchInput.is_press(event)`), and it is up within a frame
or two of the press that dismissed the ending. **"Often" rather than always is the shape of a race**,
and the screen that opens has no guard of its own: `DaySummary` has `_continuing` to stop a fumbled
double tap starting the day twice, and nothing plays that role across the scene reload.

## 7. Every direction key begins a run

> "awsd and arrows should start the game in addition to space."

`TitleScreen._unhandled_input()` accepts `ui_accept` and a pointer press. `WASD` and the arrows are
bound to the four `move_*` actions, which the title screen does not read at all — so the keys that
walk her do not start her.

---

## 8. Events must arrive from off screen, and it goes to the front

> "we need to prioritize the "events must spawn offscreen" work item."

That item is M77, already written down from 2026-09-02 — *"the charging dog doesn't have an
offscreen indication it should start further away and appear first as offscreen indicator"* and
*"bikers / unleashed dogs all pop in in front of the player instead of starting off screen"*. It is
raised above M78 in the order.

## 9. The run lesson's dog has no room to be a lesson

> "the run tutorial spawns inside the visible area making the headsup way too short now (tap
> controls are slower than awsd and arrows)."

`EventDirector._crossing_ahead_of()` sites a pursuer at `Tuning.SIGHT_AHEAD` (200px) flat, and that
constant is explicitly *"the furthest ahead of her something may be sited and still be **on screen**
when it gets there"* — the camera sits on her at zoom 2 over a 1280x720 viewport, so the visible
world is 640x360 and the worst axis gives 180px plus about 32 of camera look-ahead.

**The parenthesis is the new fact and it is why this is worse than it was.** A press has to be
placed, and a direction change costs a tap rather than a key edge, so the same notice buys less
reaction than it did when the arrows were the only way in. The lesson's dog is `charging_dog`, on
`Tuning.RUN_TAUGHT_DAY`, sited `AHEAD_OF_PLAYER`.

**This overturns the caution M77 carries.** That entry says: *"`charging_dog` is deliberately
unavoidable on the day it teaches running, and a dog that starts further away is a dog with more
room to be walked around — which is the thing that placement was chosen to prevent."* The player has
now asked for the further siting with the short heads-up as the stated reason, so the trade is
theirs and it is taken. Unavoidability, if it is still wanted, has to come from somewhere other than
siting the dog too close to see coming.

## 10. Anything coming at her starts at least 200ms off screen, with a warning

> "events that go towards the player (biker / pursuing dog) should at least be 200ms off screen with
> a warning."

The unit is **time, not distance**, and it is measured at the closing speed rather than at the
event's own — she is usually walking into it. Against the two rows named:

| row | its speed | closing at `WALK_SPEED` | 200ms is |
|---|---|---|---|
| `cyclist` (`TOWARD_PLAYER`) | 165 px/s | 257 px/s | 51px |
| `charging_dog` (pursues) | 130 px/s | 222 px/s | 44px |

So the siting becomes *the distance to the view boundary along her heading, plus 200ms of closing
speed*, rather than one flat 200px cap on every axis. The boundary is not one number: the visible
world is 640x360, so it is 320px away sideways and 180px away vertically, and the flat constant is
sized for the worst axis.

**"With a warning" is the second half and it is what makes the first half fair.** `DangerEdge`
already draws a screen-edge badge for anything off screen worth one, and M77's own entry says the
second defect may be a consequence of the first — a thing sited inside the view has no offscreen
phase to be announced in. Something sited outside the view has one, and it must use it.

## 11. A biker hit is lethal

> "also a biker hit should be lethal."

`_cyclist()` already carries `hard_fail = true` with a 33px `inner_radius`, so the row is *declared*
lethal. **What makes it harmless in practice is the telegraph.** `EventInstance.is_lethal_at()`
returns false while `is_telegraphing()`, and the cyclist's `telegraph_time` is 3.3s — but sited at
`SIGHT_AHEAD` (200px) and closing at 257 px/s it reaches her in **0.78s**, so it is still inside its
own telegraph when it arrives and rides straight through her.

This is finding 10 seen from the other side: a row whose warning is longer than its approach has no
warning and no bite. Fixing the siting so the approach is genuinely longer than the telegraph is
what makes the declared lethality real, and the two should be checked together rather than one
patched around the other.

---

## The question: running `release.sh` twice

> "btw what happens when running release twice? it should block if main is on a current release"

**Answered in the session.** Today `tools/release.sh patch push` run twice from an unchanged `main`
cuts two tags from the **same commit** and publishes the same build twice. Every refusal the script
has is about the tree and the branch — dirty tree, not on `main`, `main` not level with
`origin/main` — plus a wait on the `test` check. **Nothing asks whether the commit about to be
tagged already carries a version tag.**

The asked-for behaviour is a refusal: if `origin/main`'s HEAD is already the current release, there
is nothing to publish and the script stops. It has to fire in the dry run too, because that is the
script's own stated contract — *"every refusal fires whether or not `push` was given, so the dry run
tells the truth about whether the real thing would work."*
