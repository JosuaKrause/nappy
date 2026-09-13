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

## The shared damage over three grounds

Asked: from day 5 the crack and hole variations are one shared set laid over road, sidewalk and
alley alike — do they sit naturally over each, or does a crack carry pieces of another floor's
slab grid with it?

> Sits on all three

Closed as fine.

## The park and forest ground

Asked: a park or wooded calm area is a quiet soft base with sparse grass clumps arranged per
cell, stable under a seed — do the clumps give variety while the base stays quiet enough to keep
people and routes clear?

> Varied and quiet

Closed as fine.

## Café seating and roadworks on both axes

Asked, from [PLAYTEST-64](PLAYTEST-64.md)'s findings: does each café sitter face its own table,
the right-hand chair and the vertical arrangement included; does a north-south roadworks band
read as one narrow continuous barrier rather than blocks; and is a horizontal alley closed
across its short mouth?

> All three read right

Closed as fine.

## The street tree's bed under the pram

Asked: walking past a street tree with the stroller over its paving bed, does the bed stay
underneath her and the pram while the trunk and canopy keep their upright sorting?

> Sorts right

Closed as fine.

## The comic props at play size

Asked: do the inked trees in both shapes, the bollards and the rooftop equipment — water tank,
HVAC units, skylights, vent and ducts — fit the comic ground while staying readable at the size
they are drawn on screen?

> All read at play size

Closed as fine.

## Pushing and carrying, one woman

Asked, against [PLAYTEST-62](PLAYTEST-62.md)'s requirement: does the carrying mother of the
finale read as the same woman who pushes the stroller, across every direction and stride frame?

> Same woman

Closed as fine.

## Garbage sacks and litter on the late days

Asked: do the standalone sacks and the piles read as one material, and does the small ground
litter stay quiet and readable?

> Both read right

Closed as fine.

## The stroller identity mark

Asked: does the cream stroller stay clear against its navy plate at the smallest export size,
and does the redrawn symbol fit the wordmark it was kept beside?

> Reads at every size

Closed as fine.

## The car crash's gap

Asked, against `DECISIONS.md`, M118: a crash's body is two circles where the cars are drawn,
and walking the gap on either pavement costs a little over half the meter rather than the day;
`Tuning.CAR_ACCIDENT_GAPS_ARE_LETHAL` would make it kill. Do the bodies sit where the cars are
drawn on both axes, does the gap read as a price chosen once or as a wall untold, and should it
kill? The recommendation was to keep it a price.

> Bodies sit, gap is a fair price

Closed as fine; the switch stays off.

## What the phone sessions reached

Asked which of the review file's places recent play had reached — day 7's doors and roadblocks,
day 9 or 13's patrols and decay, the escape behind `--start-escape`, or only the first days on
the phone:

> Only the first days on the phone

So the day-7-and-later items, the escape items and the desktop-only debug items stay in
`REVIEW.md` unasked, and what follows is the act I of the live page under a thumb.

## The joystick scheme under a thumb

Asked, against `DECISIONS.md`, M85 and M88: the two focal rings at the 48px stop radius with a
knob for the locked-in heading, the undrawn stop band down the middle of the screen, a held
finger re-aiming, and tap-her-to-stop absent in this mode — does the ring read as *what is
locked in* or as furniture, does the band read as a deliberate stop or a dropped input, do the
band and the discs refuse ordinary aiming, and is tap-to-stop missed?

> Controls feel right. I will report if I find any new issues

Closed as fine, all four.

## The title screen, the restart and the upright phone

Asked, against `DECISIONS.md`, M88, M76 and M60: are two discs and two captions enough to pick
a scheme you have not played; has a stray tap after an ending ever started a run, or a
deliberate press after a restart been swallowed by the 0.35s window; and does a phone held
upright rotate once and correctly?

> All three fine

Closed as fine, all three.

## The crowd's walkers as drawn

Asked, against `DECISIONS.md`, M108, the crowd walkers and the walkers' stride: do the feet read
as walking at street scale and a stopped queue as standing, does the diagonal moment while a
walker steers across its lane read as turning or as a flicker, and does a stopped walker ever
face the wrong way?

> All read right

Closed as fine.

## The event people and animals, and their strides

Asked, against `DECISIONS.md`, M108, the event people and the event strides: does a figure seen
from behind still read as what it is, does the robber turning toward her read as a tell or a
glitch, do the café sitters facing one way read as a row, does the cyclist's pedal swap read as
pedalling, and is the busker's tempo right?

> I haven't noticed anything off. Looks good. I will report specific findings if I notice
> anything

Closed as fine, both items.

## How an answer is treated

Sent while the questions were being asked:

> Btw all answers and feels I give you might get overturned later after more playing but we
> shouldn't keep those items open until more play testing surfaces issues

> I will complain if I notice issues from restaurants etc but for now they look good and
> nothing stands out.

> Technically I played multiple days on the phone but I didn't skip ahead or did the ending

So an item that has been asked and answered closes on the answer, even though later play may
overturn it, and a later complaint reopens it as a new finding. An item that has not been asked
stays in `REVIEW.md` *(2026-09-13, on a first reading that closed forty unasked act I items:
"I didn't say you should close items that you didn't ask")*. The sessions reached several days
of act I on the phone, so the unasked act I items are askable next time; day 7 and later, act
III, the endings and the escape are not yet.

## The dog from day 4

Asked, against M96's open item: from day 4 the dog is map-placed off her heading but still
charges the moment it streams in, 900px away past the edge of the view, rather than waiting
inside its own field the way the robber does. Offered: make it wait (the recommendation), or
leave it charging from off screen.

> The waiting is good. But we can sprinkle the day 3 charging dog in every now and then, too.
> Since they always come from offsceeen the only difference now is that day 3 dog is guaranteed
> to happen and has a tutorial tip

Two decisions. From day 4 the dog waits in its field — a dog she can see is a dog she can route
around. And the day-3 shape — a charge from off screen along her heading — does not retire
after the lesson: it is sprinkled in now and then on later days, unguaranteed and without the
tip, so that the lesson's dog and the later dogs are the same animal with the guarantee and the
tip being the whole of the difference. Both go to M96 in `TODO.md`; the review item closes.

## A car turning round in a street

Asked, against M111's one open question: where a barrier leaves a car no junction to reach it
turns round in the street, and a half turn between two lanes 32px apart puts its corners 8px
over the kerb onto open pavement, every hard blocker still refused; refusing that too was
measured at 33 of 34 cars at a standstill inside ninety seconds. Accept the overhang, or build
a reverse gear? The recommendation was to accept it.

> Going over the curb is actually quite realistic. Let's keep doing that. What would be the
> purpose of reversing? It would make things more complicated. What happens if there is a car
> behind etc? Also, let's stop with questions for now. We will continue with that later

Decided: the overhang stays and no reverse gear is built. M111's section leaves `TODO.md` and
the decision goes to `DECISIONS.md` under M111. The other half of the review item — whether the
pause at a junction mouth reads as slowing rather than stalling — was not asked and stays in
`REVIEW.md`. The questions stop here; what remains waits for a later sitting.
