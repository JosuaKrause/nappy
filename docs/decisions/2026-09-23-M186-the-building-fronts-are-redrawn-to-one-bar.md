## M186 — The building fronts are redrawn to one bar · built 2026-09-23

*([PLAYTEST-124](../playtests/PLAYTEST-124.md), statements 8 and 9: "the new standard door … pops
out. But that is probably because the other parts of the buildings (walls, windows, fire escapes,
etc) are not updated and look flat in comparison.")* An Opus agent redrew everything
`src/city/building.gd` builds a front from, the power station aside, to the bar of the accepted
doors and storefronts: brick in running bond and a weathered membrane roof, both neutral and white
where the district tint is multiplied in and seamless both ways; an untinted stone plinth; corner
and parapet overlays as a dark outline with translucent light and shade, so they read on any tint;
the three window styles in painted frames under the entrance door's stone lintels and sills, each
lit picture registering with its dark one; and the civic portico as a stone porch in the same
stone. **The standard entrance door was not redrawn**: with the rest of the front at its bar it no
longer stands out, and the player accepted the fronts as they are.

**The fire escape took five rounds, and the misreading is the lesson.** The first redraw was a
black-iron balcony with a diagonal flight hanging from it, one overlay over the bottom two rows.
The player's "Fire escapes don't reach a ground floor. They always end one floor above"
(statement 10) was read as a drawing fault and the flight was replaced by a ladder stowed upright
above the balcony; the player meant placement. With the diagram of statement 13 ("you start at the
bottom of the top floor then the same texture gets placed on each floor. on the ground floor you
only place the platform -- without a ladder") the first drawing came back (statement 14), stacked
once per floor: its balcony stands on each floor line from the top floor's down to the second's,
and the first floor's balcony, on the ground floor's top edge, is `fire_escape_platform_{a,b}.svg`,
the same drawing with the flight's paths and shadow removed (statement 16), since a crop would cut
the handrail and stringer where they leave the deck. Every flight runs the same way, always
(statement 15), so `b` is no longer mirrored and differs from `a` only in the pot. A front needs
three floors to carry one (statement 17).

**Then the pot and the second escape** (statements 19 and 20). Each balcony shows the pot or not
on its own, `FIRE_ESCAPE_POT_SHARE` (a third). A front of at least `SECOND_FIRE_ESCAPE_MIN_COLUMNS`
(seven) columns that carries one escape carries a second `SECOND_FIRE_ESCAPE_SHARE` (0.4) of the
time, `FIRE_ESCAPE_GAP_COLUMNS` (four) columns away centre to centre: 1.5 of the 48px picture's
widths between their edges is 72px, so the centres sit at least 3.75 columns apart, and both keep
off the corner columns. **No existing roll moved**: the first escape's presence and column are
drawn where they always were in the `front:` stream — rolled on every front of two rows or more
and dropped afterwards from one too short — and the pots and the second escape come from a stream
of their own, `escape:`. The entrance door keeps clear of every escape column, which on a front
with one escape leaves every door where it was; a two-row front, with no escape to avoid now, may
put its door in the column it used to skip.

**Open to overturn, chosen by the agents:** the pot share, the second escape's share and its
minimum width; the windows behind an escape stay drawn, as a real escape stands in front of them.
