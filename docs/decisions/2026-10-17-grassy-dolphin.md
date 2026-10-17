# grassy-dolphin — The escape's fire stands on the second floor, and its steam costs 40 to 50 · 2026-10-17

[fluffy-kestrel](../playtests/2026-10-17-fluffy-kestrel.md), #741: "The fire in the house moved one
floor down from what it was before breaking the escape sequence left right left which existed
before. The steam should have a stronger impact." Asked how strong, the player (inbox #747): "steam
should be 40 to 50."

**The fire was never moved by a change.** Since M165 (commit 849c5334)
`InteriorEvents._place_the_fire()` put the fire
in the left shaft and rolled its floor between the two `InteriorScene.inner_floor_approaches()`:
the second floor's, which shuts the flight from 2 to 1 and makes the walk left (3 to 2), right (2 to
1), left (1 to the lobby), and the first floor's, which leaves only left then right. 976 of 2000
seeds rolled the second floor; seed 4242, the one every recorded escape uses, always did, so the
player had always seen left-right-left there. The player was told the fire would stand on the
second floor every time unless they objected, and did not object.

**Built (PR #752).** The fire always stands on the second floor's approach, with no roll; dropping
the draw moves nothing else (the mouse's draw is discarded and the vents are fixed).
`tests/test_interior.gd` checks over ten seeds that the fire is on that approach and, flooding
between the shafts' doors with the fire's reach removed, that the left flight from 3 to 2 is open,
the left flight from 2 to 1 shut, the right flight from 2 to 1 open and the left flight from 1 to
the lobby open; with the first floor's approach it fails.

**The steam was never weakened by a change either**; the player asked for more. Measured 30px from
a vent, where its body holds her as she waits for the gap, one blow cost 24.9 points awake and 13.7
asleep. `basement_steam`'s intensity goes from 14 to 25: one blow now costs 44.4 awake and 24.4
asleep there, inside 40 to 50, and a test holds it in that band. The pockets between two vents rise
from 43 and 47 to 77 and 84 of 100, still under the 100 the pocket test requires; intensity could go
to about 29 before a pocket reaches 100.

**Choices open to overturn:** the intensity alone was raised, keeping the pulse and the radii, as
the smallest change; "40 to 50" was read as awake, at the distance she waits at a vent.
