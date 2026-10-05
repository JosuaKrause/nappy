priority: now
after: 2026-10-04-spry-llama
after: 2026-09-26-M226

# dappled-swan — What she can see leaves out the touch-control corners, everywhere · filed 2026-10-05

[feathery-lynx](../../playtests/2026-10-05-feathery-lynx.md) files inbox #581, said in a
conversation about spry-llama (the counter counts encounters: seen, influenced, and bouts of
running), as PR #578 was building it. The band `now` is the note's own, and the player agreed to
build it in "the next batch, alongside M226" (the pursuing dog keeps its day-3 timing, and the
other warnings fit it).

Said after the build reported its seen test, an encounter seen on the first frame 80% of the
instance's drawn box is inside the camera's view:

> when counting the 80% visibility for seen remove the area at the bottom left and right up to the top of the joystick circle and horizontal extent of the speed button -- use that everywhere where visibility is concerned -- for the other mode those rectangles *do* count

Asked "should the rest of the game switch to the new visible area in the next batch, alongside
M226?", with the rest of the game's visibility named (the off-screen warnings and where things are
placed just off screen, when a chalk mark counts as noticed, the fire's and the pelican's seen
events):

> if you mean by carving out the bottom rectangles to count as visible. yes, everything should follow this (and treat it depending on the input mode)

**Asked for:**

- **One visible area that everything asking "is it visible" uses**, "everywhere where visibility
  is concerned".
- **In the joystick mode it is the view less both bottom corners**: at the bottom left and right,
  each corner from the top of the joystick ring down and across the run button's whole width (the
  player's "speed button"). In the tap mode those corners count, so it is the whole view.
- It follows the input mode the player is in.

**What exists.** PR #578 (spry-llama) builds the area as one function,
`VisibleView.visible_share()` in `src/ui/visible_view.gd`: the share of a world rect inside the
view, less, in the joystick mode, two rects each running from the screen's side to the far edge of
that corner's run button and from the top of its joystick ring down, worked out from
`TouchControls`' own constants, since both bottom corners carry a ring and a run button; in the tap
mode the whole view. It is used for the counter's seen test only, and this entry waits on it
(`after: 2026-10-04-spry-llama`). The rest of the game asks one of two other tests, neither of
which knows the corners:

- `DangerEdge.is_on_screen(world_position, margin)`, a point against the screen rect in design
  space, rotation-aware, optionally grown by a margin in screen pixels;
- `EventManager._is_on_screen(world_position)`, a point against `Tuning.VIEW_HALF_EXTENT` (320 ×
  180 world px) around her, which ignores screen rotation.

The tests it covers, each an item of its own:

- **The off-screen warnings, and where things are placed just off screen**
  (`warnings-and-placement.md`). M226 rewrites those warnings (every off-screen warning shows the
  badge alone for at most a second, then places the thing just off screen), so this entry is
  ordered after it (`after: 2026-09-26-M226`).
- **A chalk mark counting as noticed** (`chalk-mark-noticed.md`).
- **The sightings: the fire's `seen-fire`, which also summons the fire truck, and the pelican's
  `pelican-seen`** (`the-sightings.md`).

**Proposed, not asked for:**

- **The poster crews' pasting counts as a visibility test too.** `PosterWalls._work_the_crews()`
  pastes a sheet "while it is inside her view", a point against `Tuning.VIEW_HALF_EXTENT`. It is
  listed under `the-sightings.md`; the alternative is leaving it a distance test.
- **What is drawn and loaded is not a visibility test.** The streaming of the ground and the
  scenery (`SceneryResidency.camera_view()`, `City._home_scenery_view()`) and the events brought
  into the world near her keep the whole view, since the corners are drawn under the controls.
- **Placing a thing in a covered corner counts as off screen**, as the area says; the alternative
  is keeping placement out of the corners as well, so nothing appears under the controls in sight
  of their edges.
- **One test, not two.** `EventManager._is_on_screen()` and `DangerEdge.is_on_screen()` both give
  way to `VisibleView`, which carries the screen's rotation the way `DangerEdge`'s does today, so a
  rotated touch layout covers its corners where they are drawn.
- **Built with M226 in one pull request** if both are picked up together; the `after:` line only
  keeps this one from being built before it.
