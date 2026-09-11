# Playtest 56 — 2026-09-11

A design conversation rather than a played session, held while M108, eight-direction entity
graphics, and M111, cars follow their turns, were being built in parallel. No run, no seed.

## The crowd walkers do not walk

Asked whether the crowd walkers have a walking animation, the answer was no: a crowd walker is one
static picture per facing that slides along its lane, with no gait frame pair and no bob — the
crowd agent's own comment says *"the crowd never bobs — only an `EventInstance` rides a stride's
worth of lift"* — while the mother alternates two frames per view, mid-stride and feet passing,
driven by her walk phase.

> can we do a similar one to what the player does?

So the crowd walkers get the mother's stride: a second gait frame per view, authored as SVG first
under the SVG-first rule, and the same alternation the stroller already runs.

On whether the art is a large job:

> the art should be easy to adapt, right? using the player as reference?

It is. The mother's b frame differs from her a frame only in the two leg and shoe paths, redrawn
with the feet passing, and a one-pixel lift of the whole figure for the bob; the walker's trim
layer already carries its legs and shoes as the same two paths in the same style, so a walker b
frame is those two paths redrawn and the coat body unchanged.

## Every living thing moves when it moves

> also, all living things should have movement animation

This widens the instruction from the crowd walkers to every living thing the game draws: the
event people, the animals and the cyclist as well. Read as *while moving* — a thing that stands
still keeps its single frame, so the busker, the café sitters and a posted guard are unchanged
until they move — and the pigeons already alternate two wing phases, which is a movement
animation. The first draft of this listed the yeller among the standing ones and the player
caught it:

> the yeller walks around, too, no?

He does — `homeless_yeller` paces eight tiles of pavement, walking up and down for ever — so he
strides like the rest. Filed under M108, eight-direction entity graphics, as one item after the walker
binding, walkers first because their art derives from the mother's, then the event people and the
animals, each needing its own second frame for every view before any code. Reading *movement* as
*while moving* is the orchestrator's, open to overturn if an idle animation was meant too.

## Cars bob on their wheels

> cars could bop up and down while the wheels stay in the same place

A moving car's body rises and falls a pixel while its wheels stay put on the ground. Today a crowd
car is two layers, a tintable paint body and one trim layer holding windows, tyres and lights
together, so the wheels cannot stay still while the trim moves; the wheels come out into a layer
of their own, SVG first. Filed under M108 beside the stride item, crowd cars first and the event
vehicles that move the same way.

Confirmed when the split was proposed:

> yeah we can extract the wheels and make them separate svgs
