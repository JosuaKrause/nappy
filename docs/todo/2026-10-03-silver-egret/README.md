priority: now

# silver-egret — A shadow is where the object meets the ground · filed 2026-10-03

> "currently shadows are oval below objects. for most objects the oval spans the entire visual
> bounding box. this does not read as shadow. for example, the shadow of a car goes all the way above
> the roof of the car. it should only be where the wheels would reasonably be."

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 1 (note #423). **A shadow sits where the object meets the ground, not across its
whole picture**: a car's only where its wheels would be, never above its roof. The player gave two
ways and chose neither: "either we keep the oval for shadows and adjust their number and extent to
what makes them look reasonable or we draw a custom shadow for each object that resembles what we
would expect a shadow of that object to look like".

**What it collides with.** The M61 record ("One shape per object · the shape, the shadow and the
body", built 2026-09-10) draws every shadow from the object's `GroundShape`
(`src/ground_shape.gd`, `shadow_outline()`/`draw_shadow()`): "A point shadow is the same
`2r × 0.8r` ellipse … under a Y scale of 0.4". The first way keeps that rule and changes the shapes'
extent (and how many ovals an object casts); the second overturns it, and its PR quotes M61. The
crowd car's capsule is `CrowdAgent._car_shadow_shape()`; the M139 record on the crowd's shadow pass
is the cost to read before per-object pictures for walkers and cars.

**This answers half a review item.** `docs/review/2026-09-10-every-shadow-is-drawn-from-a.md`
asked how the shape-drawn shadows read in play; the shadow half is answered by this note and leaves
it, and the capsule half (a thinner body she can lean through) stays.

**Proposed, not asked for:** start with the first way on the objects where it reads worst (cars,
then the tall props), shown on a review sheet; "adjust their number" is read as how many ovals an
object casts (one per wheel pair), the other reading being how many objects cast one.

**Re-report from playing:** [azure-koala](../../playtests/2026-10-07-azure-koala.md), finding 10,
files inbox #601 in [azure-koala](../../playtests/2026-10-07-azure-koala.md) with the player's `queue_now` label, setting this entry's band to `now`:

> police car's shadow makes it look floating

This is the police-car case of the ground-contact request above. It answers the police-shadow
question in `docs/review/2026-09-11-look-at-a-parked-delivery-van.md` negatively; that review
keeps its unanswered van-facing and police-marking questions. Check the police car in its
diagonal views and both ride frames, with [M108, cars on their
wheels](../../decisions/2026-09-23-M108-eight-direction-entity-graphics-the-audit-and-cars-bob-on-their-wheels.md)
as the registration record. The two shadow approaches remain unchosen.
