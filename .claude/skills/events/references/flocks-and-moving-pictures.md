# Flocks, and pictures that move

Read this before touching `EventDef.flock_size`, `EventFlock`, a look that moves, or a picture only
part of which is animated.

## A thing made of several bodies has to be made of several bodies

`EventDef.flock_size`, and three things about it are worth copying:

- **The excitement stays a pure query, one level down.** `Baby` sums what each
  source answers from `contribution_at()`; a flock sums over its birds. That is what makes the middle of a flock cost more than
  the rim, which is a *route* decision where one disc could only ever be a price.
- **The birds are held inside `flock_spread`, and `flock_spread` comes out of `outer_radius`.** A
  bird emits over `outer_radius - flock_spread`, so the union of the moving fields is inside the
  one disc `validate_event` checked. A moving emitter is only legal while that is true.
- **`lerp` cannot turn a vector round.** Interpolating a unit vector toward its opposite runs down
  the same line to zero and back out the way it came, so normalising gives the heading it started
  with. Rotate by a bounded angle (`EventFlock._steer`), and steer from *half way out*, because a
  turn costs ground.

## A moving thing has to look like it is moving

A bob driven by **distance covered** rather than by time, so what shows is the movement itself: a
stopped thing is still and a fast thing bobs faster. A sprite cannot swing its own legs, so a bob is
what there is.

## A partially animated scene has separate pixel owners

When only part of an event picture moves, the stationary scene stays in retained static layers and
the moving pixels live in separately registered layers. The owner's picture key stays stable when
only those details swap. Static art may overlap a moving crop where it supplies the background a
phase uncovers or foreground occlusion that belongs above it; the rule forbids duplicate moving
pixels, not overlap between the layers' rectangles or opaque pixels. Preserve source painter order,
orientation, halo and badge sources, collision and the authored clock. Compare every composited
phase with the complete source rather than treating a difference mask or a crop rectangle as proof
of correct separation.
