## M100 — Small, real, and nobody's · a mouse in the alley, built 2026-09-11

*(2026-09-10: "we can reuse the mouse for alleyways as well.")* Two agent commits on
`feature/mouse-in-the-alley`, reviewed here. **The row**: `alley_mouse`, named the way
`alley_robbery` is, placed on `ALLEY` tiles as a map placement rather than sited by the director
the way `cat_dash` is — an alley is ground she is routed through, where a road tile picked at dawn
might never be crossed — which also puts it under the scheduler's required-alley refusal for
free, so it never stands in an alley she has no way round. The cat's shape at half its numbers:
intensity 9 over a 15/60px field, cap 4 a day, weight shared with the robber's since both draw
from the alley pool, a 1.4s telegraph against a required 1.09s, a 1.0s duration over a crossing
that takes a third of that, no body, nothing lethal. **The dash is across the alley by
construction**: `EventInstance._alley_crossing_path()` reads the alley rect the instance landed in
and lays a two-point path across its narrower side, since she can only be walking the long axis.
`PathMode.CROSS_STREET` was rejected because its axis comes from the corridor offset, which
answers nothing for an alley cut mid-block. One picture, `mouse.svg`, mirrored, as the cat is
drawn; the directional family stays unbound.

**The review finding, and what it added to the machinery.** As first delivered the mouse was
never seen: a map placement's clock runs from the frame it streams in, at the 900px stream
radius, so telegraph and dash were over before she was within the view's 180px short half-extent.
The fix reuses the robber's waiting state — `is_waiting()`, `_noticed_at`, the telegraph counted
from the notice — which already keyed off `pursues_within` rather than `pursues`; the one thing
not general was that only `_chase()` ever set the notice, so `_check_for_notice()` now does it for
a non-pursuing row, which then runs its own path. `pursues_within` 150px: inside the short
half-extent with margin and past the row's own 60px field, so the telegraph is on screen before
the field is felt. **Rejected**: making the mouse `pursues` with a pursue speed, which drags in a
stand-off, a lunge and the pursuit speed band for a row that never follows her. A test holds both
halves: still and unclocked with her 400px past the trigger for five seconds, then noticing,
telegraphing from the notice and crossing the narrow axis. **Chosen where the design was silent**:
the notice check duplicates four lines of `_chase()` rather than refactoring proven pursuit code;
the dash direction is rect start to rect end rather than a coin flip, since no RNG reaches
`setup()` and it is not a fairness matter. Measured: walking through costs about 4 points,
running through about 15.
