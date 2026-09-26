## M33 — Playtest 07: the cost model was inverted, and running started to matter

See **[docs/playtests/PLAYTEST-07.md](../playtests/PLAYTEST-07.md)** for all nineteen findings, the traces that confirm
three of them, and the ten that are still open. Nine are done.

- [x] **The falloff has a shoulder** — finding 18, and the one change that answers it for the whole
      catalogue at once. `(1−t)²` → `1−t²`, so a field holds three quarters of its intensity at the
      midpoint of its band instead of a quarter. No radius moved, so the telegraph fairness
      contract — which is stated over *distance* — is untouched. The trace said it in as many
      words: every `near` entry written at an event's own outer radius read `events 0.0`
- [x] **The crowd paid the shape back in radius** — the same change put the arterial floor at
      18.4/s against a 3.5 walking decay, which is a main road that fills the meter in six seconds.
      A pedestrian's outer radius came in 88 → 55 and a car's 170 → 104, which restores the floor
      to within 3% while leaving the close pass at 4.2/s. What is defended is M27's character:
      **careless is expensive and careful is free**
- [x] **Standing still settles nothing** — finding 3. `EXCITEMENT_DECAY_IDLE` was 6.0, the
      *fastest* of the three rates, so a full meter cleared in seventeen seconds anywhere. The
      ordering is motion-shaped now: walking 3.5, running 0.5, standing 0.0. And there is an
      `idle` telemetry span, because the player asked whether it was captured and it was not —
      standing still emits no entry of any kind, so the strongest move in the game showed up in a
      trace as a seventy-four-second **gap between two lines**
- [x] **A contact resolves** — finding 5. Two defects, either enough on its own: the separation
      resolved to exactly `BUMP_RADIUS`, which is the radius that *releases* the contact, so a
      resolved pair sat on its own threshold; and a walker steers back to its lane centre, which is
      where she is standing. Hysteresis band plus a sidestep. The longest single contact goes from
      1.0s to **0.1s**, backed against a wall included
- [x] **People get out of the way** — finding 17. M19 and M27 measured eleven contacts down a lane
      centre against one on the midline and built the crowd on that ratio; a probe re-run on `main`
      says it is gone — thirteen against fifteen — and it cannot be tuned back, because a midline
      is 16px from two lane centres and `BUMP_RADIUS` is 14. That line was two pixels wide when
      M19 measured it. So the careful line is a **behaviour**: somebody who sees a pram coming
      steps aside, hurries across, or waits. Same-axis contacts go from eleven to nought-to-four.
      A bump also costs 18 rather than 26, because the authored content now carries the share the
      crowd was carrying alone
- [x] **Running is the answer to exactly one kind of thing** — and it is two decisions, not one.
      The shoulder broke the old one by accident: a fatter field makes time-in-field matter more,
      so running became a point or two *cheaper* than walking through the four widest events. Not
      "running works" but "running is a coin flip". `EXCITEMENT_FROM_RUNNING` 9 → 14 restores the
      ordering, and `tests/test_events.gd` asserts it row by row — it had only ever been measured
      and written into a document, which is how it broke silently.
      Then the player asked for the opposite: *"the run button is a trap shouldn't be an invariant
      — there should be legitimate cases where running is required."* So `EventDef.pursues`:
      something that comes after **her**, faster than a walk and slower than a run, lethal, and it
      gives up. Walking and running give **opposite outcomes** rather than the same outcome at two
      prices, which is why it had to be a mechanic. `Tuning.validate_pursuit()` is its contract and
      it is stated over `RUN_SPEED`, exactly as this file said M25's would have to be. Verified by
      rig: a player who walks directly away from the first frame is still caught (1.6px), and one
      who runs escapes with 240px to spare
- [x] **Day 1 teaches walking, day 3 teaches running** — *"on day 1 we only introduce arrow keys.
      On day 3 we introduce the running key (it is possible to run before but not required), and
      have an incident at the start to force running."* `charging_dog` is gated to
      `Tuning.RUN_TAUGHT_DAY`; `EventDirector` moves the first one to the head of the queue on that
      day so the lesson is not left to a weight of 1.4; and the HUD says *Hold SHIFT to run* on the
      frame the dog telegraphs rather than at dawn. **This is half of M26 arriving before M25**,
      and the ordering constraint M26 was written with is satisfied rather than broken: the forced
      run is behind the thing that makes running right, and not on day 1
- [x] **The mark is for a beat you can actually play against** — finding 2's cue half. The rule was
      `pulse_period > 0` and six of the ten rows available on day 1 have a pulse, so the caret was
      over most of an ordinary street: the deleted ring's own mistake in the shape M22 invented to
      replace it. It is a relationship now — the period has to be shorter than the walk across the
      field, which is exactly when a pass can be slipped between two beats. Day 1 goes from six
      marked rows to two, and both are the ones whose counterplay is *go now*
- [x] **There is a pause** — finding 12. `Esc` opens it, `Esc` closes it, `Q` quits. It quit
      outright for thirty-three milestones and has been under known-shaky ground since M6
- [x] **Solid things are solid** — findings 16, 13, 7 and 15, done as **M34**. `obstructs_radius`
      was a list of five rows out of thirty and is a rule now: anything that stands still is solid
      at half its silhouette. A parked van moved off the carriageway to the kerb, where it takes a
      pavement instead of standing in a lane the crowd drives through; a reversing lorry got the
      building it reverses into, and is turned to face out of it; `alley_robbery`'s inner radius
      moved 22 → 30, because a lethal radius and a solid body are the same mechanism and a body
      that reaches the kill radius switches the kill off. Day 1: events placed unchanged at ~39,
      pavement-blocking obstacles 12.2 → 17.2
- [x] **One picture per row** — findings 2, 11, 4 and 14, done as **M37**. See the section below
- [ ] **The last four.** The cat crosses the wrong axis (1); a four-block concrete plaza (8); a car
      turning has no diagonal (6); and the crowd's own anonymity, which is deliberately *not* the
      same rule — see the bottom of `docs/playtests/PLAYTEST-07.md`
