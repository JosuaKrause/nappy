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
