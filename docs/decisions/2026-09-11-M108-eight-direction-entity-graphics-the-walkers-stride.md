## M108 — Eight-direction entity graphics · the walkers' stride, built 2026-09-11

*(2026-09-11, playtest 56: "can we do a similar one to what the player does?"; "the art should be
easy to adapt, right? using the player as reference?"; "all living things should have movement
animation".)* The walker half of the stride item. Four agent commits on `feature/walker-stride`,
reviewed here. **Art first, as SVG.** Ten new files, `assets/crowd/walker_{front,back,side,
front_diagonal,back_diagonal}_{body,trim}_b.svg`, beside the existing sources which serve as
frame a — additive rather than renaming, so nothing that pointed at a walker file moved. Each b
frame was derived by diffing the mother's own a and b for the same view: cardinal views shift the
coat and head up one pixel and redraw the legs and shoes crossing, the side view's near and far leg
by different amounts as the mother's are; the diagonal bodies are byte-identical to frame a and only
the trim's two leg paths change. The sheet under `docs/evidence/m108-walker-stride-2026-09-11/`,
rendered by `tests/probes/m108_walker_stride_sheet.gd`, shows all five views in both frames with no
drift above the waist. **The alternation** is the mother's: a gait phase per walker advanced by its
applied speed at the same 0.09 rate, frame a at or below `WALKER_IDLE_SPEED` (5px/s), otherwise a
and b by the sign of the doubled phase; one boolean picks both body and trim so they cannot
disagree; the redraw check folds the frame into what it compares. The phase resets on placement
and recycle, the mother's `reset_at()` precedent, taken because a stride that starts mid-cycle is
indistinguishable from one that starts at rest. **Evidence of motion is a burst**: a run folder
under the same evidence path with a short burst at a busy pavement; it shows a queued walker
holding the feet-passing pose beside a resting neighbour, and the README says plainly that one
walker's full flip was not caught in a six-second run without `--invincible`, which did not exist
on the branch's base. **Chosen where the design was silent**: the `_b` suffix; the mother's rate
and the idle threshold reused rather than new constants.
