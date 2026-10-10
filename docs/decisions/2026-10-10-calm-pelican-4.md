# calm-pelican — The resistance places and removes against the whole view · 2026-10-10

From the re-review of PR #597 (M226 + dappled-swan): #597 gave the resistance director one "can she
see it" test, the visible area, which in joystick mode leaves out the two bottom corners under the
touch controls. Right for noticing a chalk mark, it also decided where a relocated mark, a waiting
robber and the task targets may be placed and when they may vanish, against the player's "off
screen is not the same as visible -- the corners get removed for visible not for off screen" and "I
don't want any pop in" (inbox #598 in [olive-hedgehog](../playtests/2026-10-05-olive-hedgehog.md)):
in joystick mode a mark and its robber could be created inside her camera's view, under a control.

**Built in PR #641.** `EventManager.on_screen(point)` answers whether a point is anywhere in the
camera's view, covered corners included (`_visible.view.has_point()`, the rectangle
`PendingWarning.seen_from()` places against). `ResistanceDirector.set_sight(sees, on_screen)` takes
both answers in one call: the visible area is asked only by the mark's notice dwell, and the whole
view by everything that places or removes — relocation, the waiting robber and guard, the task
targets, the trap starts, day 10's raid and taking the neighbor away. `docs/MECHANICS.md` and
`docs/NARRATIVE.md` say "on her screen" means the whole view. A joystick-mode test makes each alley
mouth in turn the only relocation candidate with the mark under the covered corner and asserts it
is refused, and keeps the taken neighbor while under the corner; with the old single test it fails
260 of 270 checks.

**Chosen where the item was silent, open to overturn:** one setter with two required answers, so no
caller can wire one and forget the other; the trap starts and the raid moved to the whole view too
(the trap starts were already outside it, so only the raid changes: in joystick mode it waits until
none of its points is under a covered corner).
