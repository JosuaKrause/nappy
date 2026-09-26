## M60 — One rotation, applied once · built 2026-09-05

Playtest 23, the first phone session on the deployed build, found the rotated presentation was
**three different rotations in one picture** — *"controls are the only things that are rotated
correctly"*. Four symptoms, one root: the rotation was implemented three separate times and two of
them disagreed.

- **The world sat 180° from the controls.** `Stroller.set_screen_rotation()` turned the world by
  setting `Camera2D.rotation` to +90°; `TouchControls._draw` turned the buttons by applying a +90°
  transform to its draw call. **A camera turning one way swings the world the other way on screen**,
  so two +90°s landed 180° apart.
- **The text was not rotated at all** — the HUD, pause screen, summary and title are `Control` nodes
  under `CanvasLayer`s and nothing had touched them. It was published as a known limitation, which
  it was not: upright text is the largest thing on the screen and it was saying the screen is not
  sideways.
- **Auto-rotate latched a portrait content box** and never recovered, because `_apply_orientation()`
  ran only at startup and on `size_changed`, and a signal arriving with a stale size or not at all
  left the wrong box in force until a reload.

**The fix was to stop having three implementations rather than to reconcile them.** One transform,
`ScreenOrientation.rotation_transform()`, applied to every `CanvasLayer` through `apply_to_layer()`,
with each layer's children pinned to the fixed 1280x720 design box by `pin_to_design_box()` so a
`Control` cannot size itself against the swapped viewport. The camera stopped being a second
implementation and `TouchControls`' own draw transform was deleted. **And the decision is re-asked
every frame rather than on a signal** — `main._process()` compares `wants_rotation()` against the
applied state and reapplies on change — because a missed or early `size_changed` is exactly what the
latch was made of. It cost a vector comparison.

**The device's own orientation is never touched**, on instruction: *(2026-09-05: "don't try to
**change** landscape/portrait mode — work with what you have")*. Two levers were rejected on that
ground rather than on cost, and are cheap to pick up if the chosen one disappoints: writing the PWA
manifest would give an installed web app a real lock, and moving `screen.orientation.lock` onto the
first tap after a fullscreen request — it is called from `DOMContentLoaded` today, outside the
gesture it requires, so it is refused every time — would give one to Chrome for Android. Each
*changes* the device's mode, and a phone whose owner turned auto-rotate off has said what they want.

**What the tests can and cannot prove, which is why this is not finished until somebody looks.**
`tests/test_orientation.gd` proves the input remap by construction: a touch sent at the exact screen
position a design-space point maps to, while rotated, is read back by `TouchControls` as that same
point — which closes the failure where the controls draw correctly and the remap silently disagrees.
**It cannot catch a sign error the transform and the drawing share**, and that is how three of the
four symptoms shipped in the first place. `tools/shot.sh` now takes a resolution so the rotated
branch can be photographed at all; before that every picture a rig could take was of the landscape
branch, which was already correct.
