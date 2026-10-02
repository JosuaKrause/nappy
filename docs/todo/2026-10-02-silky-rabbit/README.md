priority: now

# silky-rabbit — Spread ground compositing across frames · filed 2026-10-02

The player asks to pick up [issue 446, split ground visuals creation into multiple frames](https://github.com/JosuaKrause/nappy/issues/446),
record it as a new todo and begin work. Their complete issue, pickup instruction and scope
correction are in [speckled-marten, spread ground compositing across frames](../../playtests/2026-10-02-speckled-marten.md).

> The compositing process of creating ground visuals can be smeared across multiple frames. That would improve stuttering 

On the assistant describing loading-time shared-sheet composition as the target, the player
clarifies:

> what are you talking about? we made a change so ground composition happens dynamically surrounding the player

> regions that are too far away are unloaded

The target is the existing nearby region preparation in `SceneryGround` and `SceneryResidency`.
It loads ground around the camera and releases regions beyond a wider retention boundary.
Individual ground regions are prepared atomically; the off-screen work queue's soft CPU
budget finishes an atomic job, and Godot's later draw preparation is outside that timer.
Spreading dynamic preparation across frames must cover this real played path.

The current contract is [M159, nearby scenery residency](../../decisions/2026-09-19-M159-4.md):
load before the ground enters view, retain scenery beyond a wider unload boundary, reconstruct
from current city state on revisits, preserve gameplay and seeded appearance, and prepare a
relocation destination before showing it. The shared runtime sheet's pixel contract remains
[M171, the ground](../../decisions/2026-09-20-M171-the-ground.md).

**Proposed, not asked for:** the `now` band reflects the player's instruction to start the
item. Divide off-screen region preparation into bounded steps, with pending-region ownership
and a complete-region handoff before visibility. The exact step size is an implementation
choice to measure and report. Changing the pixels, gameplay or residency distances is outside
this work.

The work is being implemented on this item's branch. Its todo stays until the implementation
PR records the finished work and removes it in the same diff.

The player also requests a before-and-after measurement and testing the stricter rule of
one section per frame. Their complete words and the plan they answer are in
[gentle-moose, compare ground preparation before and after](../../playtests/2026-10-02-gentle-moose.md).
The experiment compares the atomic nearby-region runtime with both a global one-section
limit and the proposed per-region limit. The runtime choice remains an implementation
proposal to assess against those results.
