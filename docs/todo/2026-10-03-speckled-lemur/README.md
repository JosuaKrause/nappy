priority: later

# speckled-lemur — A quiet square has a statue or a fountain · filed 2026-10-03

> "the parks with concrete flooring need some variety. maybe statues or fountains in the center"

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 11 (note #447; the player, asked which ground: "the calm areas with concrete flooring
-- I don't know how you call them"). **A quiet square has a statue or a fountain at its centre.** The
quiet square (`QUIET_SQUARE`) is "Paved and empty. Calm without being green." in `docs/CITY.md`'s
purpose table and "Paved, benched, empty" in `GameEnums`; both sentences change.

**It blocks her at its footing** (asked whether it is solid or decoration, the player answered
"fountain and statue should block at their footing"): its base is a solid ground shape and she walks
round it, while what stands above the base is drawn over her. A solid object on calm ground touches
the route decision, so it is checked before it is accepted, under the **city** skill's guarantees
(the square stays crossable, and no route the day needs is closed).

**Proposed, not asked for:** one statue or fountain per quiet square, at its centre; which of the two
is drawn per square by the city's seed.
