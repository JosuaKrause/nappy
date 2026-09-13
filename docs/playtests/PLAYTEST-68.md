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
