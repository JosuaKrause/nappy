# Playtest 63 — 2026-09-12

## The excitement decay is too low

> the decay for excitement is too low anywhere -- except for the main street and maybe alleys
> there excitement should go visibly down when no excitement source is around -- prioritize this
> fix

A design instruction rather than a run report, given while the M110 solid-bodies, M102 finale
and M108 stride branches were being closed. The player asks for it to go ahead of the rest of the
queue.

What it asks, read literally:

- Everywhere the baby is walked, excitement should fall **visibly** while nothing is emitting at
  her — not merely net-negative on paper, but at a rate the bar shows.
- **The main street is the exception**: it stays the ground that is bad at letting her recover.
- **Alleys are a "maybe"** — the player has not decided whether an alley is quiet ground that
  should recover or pressured ground like the main road.

What it does not say: whether *standing still* should recover. Today standing settles nothing
(`EXCITEMENT_DECAY_IDLE` is zero, from playtest 07 finding 3: what settles a baby is being pushed),
and the player's sentence is about the ground, not the pram. That, the alley, and what a single
passer-by at arm's length should cost once the decay outruns them are the three questions the
queue entry for this finding carries; the entry is M117 in `TODO.md`.

The three were put to the player the same day with a recommendation each — standing still stays
at zero, an alley keeps today's absolute rate through a multiplier of its own, a lone passer-by
stops costing on their own while the crowd's numbers stay — and answered:

> None — build as recommended

### Two rows the raised decay made nearly free

Building it turned up two rows the change made cheap enough to be worth asking about, and both
went back to the player with their numbers. At the new walking decay of 6.0/s, walking a straight
line through a **busker** costs +2.9 against the +13.3 it cost before, and above a decay of about
6.7/s it would be free outright; an **alley mouse** costs +1.0 against +4.2. Neither row's own
design had changed — the ground under both had.

> busker should be adjusted. alley mouse can be nearly free

Then, revising the second half of it:

> alley mouse is a bit above charging cat

Read as the `cat_dash` row's cost, which is +17.6 walking on the table as it then stood. And then,
on how the two are to be compared at all:

> consider that the mouse is in the alley but the cat is usually not

Which is the correction that decided the number: a cat is met on an ordinary street and a mouse
only ever in an alley, where the ground gives back 3.5/s instead of 6.0 and the alley's own +3.0/s
dread is already being charged — so the alley hands that row most of the gap before its own
intensity is touched at all. The record, with both rows' before and after on their own ground, is
in `DECISIONS.md` under M117.

## A car crash is solid where its picture is empty

> a car crash right now has a full bounding box even though there are gaps in the sprite. the
> bounding box should only be the crashed cars but it should emanate an excitement field that
> prevents the player from walking past it

The accident is a hard seal drawn as one scene — two cars locked together across the carriageway,
debris between them, an onlooker on each pavement — and its body is one band kerb to kerb,
which is what every hard seal's body is today. The player asks for the body to be the two cars
only, and for the scene to emit an excitement field strong enough that the gaps are not a way
through. This overturns, for the accident, the rule that a closure is silent. The entry is M118
in `TODO.md`.

## Everything this round goes first

> this round's feedbacks should all be prioritized since I'm actively testing the changes as they
> come in

## Seen in the console

An engine error, once per frame while a flock was in view, from `GroundShape.draw_shadow` under
`_draw_birds`:

```
ERROR: Invalid polygon data, triangulation failed.
   at: canvas_item_add_polygon (servers/rendering/renderer_canvas_cull.cpp:1770)
```

A bird's contact shadow fades to a zero radius as it climbs, and at zero every outline sample is
the same point. Fixed the same day: a shadow narrower than a pixel is skipped.
