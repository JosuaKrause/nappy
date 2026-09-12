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
