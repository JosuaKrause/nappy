# Playtest 68 — 2026-09-13

The review questions, asked one at a time and answered from the phone sessions of
[PLAYTEST-67](PLAYTEST-67.md) and from memory, as that report asked: *"ask me a couple of
questions (one at a time) for things that need a human eye. I might be able to answer them. Go
one by one through the questions file."* Each section is one item from `REVIEW.md`, the context
it was asked with, and the player's answer; the item leaves `REVIEW.md` in the same commit.

## The building shadows

Asked: every building casts a one-tile shade to its south and west, flat black at 22% opacity
(`Tuning.BUILDING_SHADOW_ALPHA`), the corner under its south-eastern edge cut on the diagonal,
joined buildings shading as one — does an alley now read as more obvious, and is the strength
right, visible without reading as a second ground material? Offered: fine as is; too strong;
too faint; or the shade not doing its job, with darkening the ground's own colour as the
alternative to black laid over it.

> Alleys read, strength right

Closed as fine. The record is `DECISIONS.md`, M122.

## The burst water main without a shadow

Asked: it draws no body shadow at all now, on the player's word, while its two barriers and the
crater stand as they did and every other event body casts a shape-derived shadow — does the
scene still sit on the road, or does it look pasted on beside things that are grounded?

> Sits fine on the road

Closed as fine; no shadow stays the rule for it. Same record.

## Excitement decay on three kinds of ground

Asked: with the walking decay raised (`DECISIONS.md`, M117), a quiet back street nets about 3.8
points a second downward with the day's crowd on it, the main road's pavement still does not let
her recover, and a park clears a full meter in 8.3 seconds — does a quiet street read as
*recovery*, does the main road still read as ground that does not, and does the park read as a
switch rather than a place? The recommendation offered if the park felt like a switch was to
slow the park and leave the street.

> All three read right

Closed as fine: the street recovers, the main road does not, the park is a place. Nothing moves.

## The playground and the busker on calm ground

Asked: both pulse between a quarter and all of their intensity, nine seconds a beat for the
playground and seven for the busker, and calm ground gives back 12 points a second against
their 15 and 13 at the peak, so the middle of either is expensive at the top of the beat and
free at the bottom; the busker's denial radius was raised from 100px to 138px under M117 and the
playground left alone so it would not deny more park. Does a park with one of these in it still
feel contested, and is a busker still worth walking round? The recommendation offered if
neither felt contested was to raise both peaks rather than the radii.

> Playground should be free since otherwise small parks really have no way of ever getting to
> sleep. The busker is a bit intense. We should nerf it a bit but keep it so the baby cannot fall
> asleep in the park with it. But on a street with a busker closeby should cause less excitement

Neither option offered; the player's own design instead, and it overturns M117's *"raising
`playground` to restore its old margin"* reasoning from the other side — the playground is not
raised and not kept, it stops costing. Three instructions in it: the playground row costs
nothing, because a one-block park with one in it has no ground left to settle the baby on; the
busker comes down *a bit*, and the floor on how far is that the baby still cannot fall asleep in
a park that has one; and a busker's reach onto the street beside its lot is what comes down
most, so walking past a park is cheaper than walking into it. M128 in `TODO.md`.
