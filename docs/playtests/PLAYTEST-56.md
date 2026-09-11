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
under the SVG-first rule, and the same alternation the stroller already runs. Filed under M108,
eight-direction entity graphics, as its own item after the walker binding, since the binding is
being built at the time of asking and this needs new source art before any code.
