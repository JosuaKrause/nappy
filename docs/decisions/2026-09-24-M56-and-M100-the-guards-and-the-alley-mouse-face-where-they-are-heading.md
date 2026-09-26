## M56 and M100 — The guards and the alley mouse face where they are heading · built 2026-09-24

*([PLAYTEST-128](../playtests/PLAYTEST-128.md): "Directional guards (M56) … Yes, hook those up." and,
on the mouse, "The code comment is positive, the queue is normative.")* The masked pursuer and
the heated roadblock's guard read `GUARD_STANDING_BY_VIEW` and `GUARD_LUNGING_BY_VIEW`, the
eight-view `guard_{standing,lunging}_*` art under `art/checkpoints/`, through `_draw_eight_view()`
by their travel heading; the alley mouse reads `MOUSE_BY_VIEW` and its `_B` gait frames the same
way. The masked pursuer in the escape's building turns too, since `InteriorEvents` draws through
the same `EventInstance`. The stationary checkpoint guards keep their one picture.
`_draw_eight_view()` takes `draw_shadow`, so the roadblock's guard keeps its own small shadow
rather than gaining a second one. The view and stride tests cover the new families. Evidence:
`evidence/m56-guard-turn-2026-09-24/` (a still of the masked pursuer mid-climb, since every burst
pressed early in the escape landed before he appeared) and `evidence/m100-mouse-turn-2026-09-24/`
(a burst).

**Open to overturn, chosen by the agent:** the turning guards read the `_side.svg` drawings as
their side view, since the unsuffixed `guard_standing.svg` and `guard_lunging.svg` are different
drawings that stay with the stationary kit. **Not captured:** a heated roadblock guard chasing
her, since heat takes several days' play and no flag forces it; it is in `REVIEW.md`.
