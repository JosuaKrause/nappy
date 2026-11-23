# The gap between two route events' ends is held, and two checks pull request 1662 weakened are tightened

**What is wrong.** No suite holds the plan's gap between two route events' ends. Stubbing `EventPlan._ends()`
(`src/events/event_plan.gd`) to the body alone passes every suite, the scheduler's included (pull request
1662's review). With that change, pull request 1662 left two checks slightly weaker:

- `tests/test_day_locations.gd`'s section-order check no longer ties a section's number to its index in the
  order, so a reordering that keeps the sections distinct passes.
- `tests/test_marble_draw.gd`'s "the cafe moved off that section" passes trivially for a cafe that stands on
  another street.

**What a test holds.** In `tests/test_event_spacing.gd`, one hand-computed case of a route event next to
another route event, in both orders, with the gap worked out by hand from the two ends. The two weaker checks
hold what they did before: the section's number equals its index, and the cafe's new section is a different
section of the same street.

**Shown fixed.** With `_ends()` stubbed to the body alone the new case fails in both orders, and each tightened
check fails on the case it now lets pass (a reordering of the sections, a cafe moved to another street).
