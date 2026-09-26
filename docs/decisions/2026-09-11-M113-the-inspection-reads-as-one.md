## M113 — The inspection reads as one · built 2026-09-11

*(2026-09-10, playtest 55: "the checkpoint itself, 2s should be enough -- both the guard and the
player should disappear during the inspection, the camera should center on the hut (use a smooth
ease in out for non player caused camera movement if possible) after the inspection the player
and the guard should reappear".)* Six agent commits on `feature/inspection-reads-as-one`, reviewed
here, with M100's pram collision and M110's gate item alongside. **Two seconds, and both of them
gone.** `Tuning.CHECKPOINT_DETAIN_SECONDS` 6.0 → 2.0. For the hold she is hidden (`Stroller.
hide_for_inspection()`, with the pram's cue and the caret over her) and the checkpoint draws
nothing of itself — guard, body and halo ring, since `EntityHalo` re-traces the silhouette through
`_draw_body()` and bypasses `_draw()`, which is why the ring survived the first build and had to be
gated one level upstream through one named predicate, `is_suppressed_by_its_own_hold()`. Both
return when it ends, her on the far side so being let out reads as being let through. The vanish
and the camera focus are gated on `EventDef.redetains`, the flag already exclusive to the checkpoint
rows, rather than a new field, so `chatting_mother`, which shares the detain mechanism, is
untouched; `EventInstance` finds her through the `"player"` group the crowd and the HUD already use.
`CHECKPOINT_RELEASE_MARGIN` and the row's `detain_seconds` were re-checked against the shorter hold
and needed no change — the release arithmetic never depended on the duration. **The camera eases
onto the hut and back**: a focus target on her own `Camera2D`, smooth-stepped over
`Tuning.CAMERA_EASE_SECONDS` (0.5s, chosen rather than specified, so most of the hold is spent
settled on the hut), detached with `top_level` for the duration; the return eases toward her *live*
position each frame, so the teleport to the far side is followed rather than aimed at a stale
point. Tests drive the hold and assert both vanish, the halo with them, the camera's target and
its return.

**The bar itself holds her** (M110's remaining item, decided 2026-09-10: "attempting to do that
should just start a regular checkpoint inspection"). `checkpoint_gate` gained the hut's own
`detain_radius` (48px), `detain_seconds` and `redetains`, so stepping onto the boom's tiles while
it is up for a car starts an inspection with the vanish and the ease; its `inner_radius` moved
40 → 52, the least that keeps the detain inside the lethal radius and clears the physical stop
distance of its body plus hers. A test drives her at a raised gate's own tiles and asserts the
hold, beside M110's test that the boom's state has no bearing on the hut's.

**The pram's own collision** (M100). A second `CollisionShape2D` trailing her at the pram's drawn
offset, sized to the pram shape's existing 12px, computed once a frame before `move_and_slide()`
and shared with the drawing; disabled while she is carrying, since the escape scene has no pram.
Verified at the wiring level — the shape exists, tracks `facing`, is off for a carrying rig —
because `move_and_slide()` does not move a body in the suite's synchronous headless run, the same
trap the events suite's conversation test already documents.

**Walked on day 7**, seed 3045005721: a hold in progress and a release, in
`docs/evidence/m113-inspection-2026-09-11/`. Four windowed runs rather than the two the gate
names: walking from the doorstep wedged her against the checkpoint's own solid geometry before she
ever closed on the detain radius, and `--spawn event:checkpoint_hut` was the fix. **Unwalked**:
whether two seconds with both of them gone reads as an inspection, and whether the ease reads as
the camera's own movement rather than a cut.
