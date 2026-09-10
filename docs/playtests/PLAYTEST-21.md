# Playtest 21 — 2026-09-03

A brief testrun on `main` at the head of the session that built M48 and designed M64. One finding
about how the city feels, and a design instruction attached to it that corrects what M64's entry
had written down.

**Nothing of M64 is built.** No street is sealed, no seal picture exists, and the corridor policy is
still M50's gradient. So this is a verdict on the game as it stands, not on the milestone that is
about to change it.

---

## 1. The city feels empty

> "I did a brief testrun -- the city feels way empty now"

*"Now"* is the word that matters and it is not attributed here, because two things landed recently
that could each produce it and nothing in the run distinguishes them:

- **M69 stopped closures being placed beside calm areas.** `ClosurePlanner` refuses every access
  street of every calm area outright, a measured mean of **33.4 of 264 lattice streets a day**. The
  handoff named this exact risk when the milestone merged: *"the risk nobody has looked at is the
  opposite one, that closures now cluster away from the places she actually walks and stop being met
  at all."* If the streets she actually walks are disproportionately calm-area access streets, this
  removes closures from precisely where she is.
- **M50's gradient makes the corridor the cheapest ground in the city, by design.** Costly rows are
  biased *off* the corridor, so a player who walks the route the day planned meets the least of
  everything. M69's own record carries the measurement that shows how strong the effect is: the share
  of costly rows landing on the corridor **nearly halved** when an intermediate version priced street
  tiles by grid depth instead of by street.

**The second is the likelier one and the instruction below is aimed at it**, but neither is measured
against this run. What would settle it is a dusk map of the run: it draws the walk over the plan, so
*how much did she actually meet* and *where was it relative to the corridor* are both readable off
one picture.

## 2. What the density should be, on and off the path

> "remember we wanted full blocks off-path which can be hard or one normal event on both sides of
> the street. and a normal density of events on the path so we need to change the side of the street
> every now and then"

Two halves, and they are about different ground.

**Off the path, the unit is a full block, not a street.** *"Full blocks off-path."* M64's entry had
recorded the sealing as *every street off the tree*, which is a street-level unit — a block with one
side on the corridor would get its other three sealed individually. A block-level unit says the thing
that closes is a whole block's worth of frontage, so the off-path city reads as solid rather than as
a scatter of blocked segments.

**And a sealed street is either kind.** *"Which can be hard or one normal event on both sides of the
street."* This is the hard/soft distinction M64 already carries, restated as the player's own choice
of words: a hard seal spans the street, and the soft one is a single ordinary event on each pavement
— which is exactly the *"restaurant on one side and yeller on the other"* mechanism from
2026-09-02.

**On the path, the density is normal — not low.** *"A normal density of events on the path so we need
to change the side of the street every now and then."* **This is the half that is new, and it is the
one that contradicts what is built.** M50's gradient makes the corridor the *cheapest* ground; this
says the corridor carries an ordinary event load, frequent enough that changing pavement is a regular
occurrence rather than a rarity. So M64 does not merely replace *dear* with *closed* off the path —
it also replaces *cheapest* with *normal* on it.

**What varies is therefore off-path versus on-path, not cheap versus dear.** The corridor stops being
a discount and becomes an ordinary street that happens to be the one that goes somewhere.
