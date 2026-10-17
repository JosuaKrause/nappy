# grassy-dolphin — The escape's fire stands on the second floor, and its steam costs 40 to 50 · 2026-10-17

[fluffy-kestrel](../playtests/2026-10-17-fluffy-kestrel.md), #741: "The fire in the house moved one
floor down from what it was before breaking the escape sequence left right left which existed
before. The steam should have a stronger impact." Asked how strong, the player (inbox #747): "steam
should be 40 to 50."

**The fire was never moved by a change.** Since M165 (commit 849c5334)
`InteriorEvents._place_the_fire()` put the fire
in the left shaft and rolled its floor between the two `InteriorScene.inner_floor_approaches()`:
the second floor's, which shuts the left flight from 2 to 1 so the walk is always left (3 to 2) then
right (2 to 1), and the first floor's, which shuts only the last left flight, so she never needs to
cross over. 976 of 2000
seeds rolled the second floor; seed 4242, the one every recorded escape uses, always did, so the
player had always seen that walk there. The player was told the fire would stand on the
second floor every time unless they objected, and did not object.

**Built (PR #752).** The fire always stands on the second floor's approach, with no roll; dropping
the draw moves nothing else (the mouse's draw is discarded and the vents are fixed).
`tests/test_interior.gd` checks over ten seeds that the fire is on that approach and, flooding
between the shafts' doors with the fire's reach removed, that the left flight from 3 to 2 is open,
the left flight from 2 to 1 shut and the right flight from 2 to 1 open; with the first floor's
approach it fails. **The last leg is not forced:** from the first floor both shafts reach the lobby,
and the left one is the way off the masked man's shaft when he comes up the right one, so the
walk's final "left" is where he pushes her, not where the map forces her.

**The steam was never weakened by a change either**; the player asked for more. Measured 30px from
a vent, where its body holds her as she waits for the gap, one blow cost 24.9 points awake and 13.7
asleep. `basement_steam`'s intensity goes from 14 to 25: one blow now costs 44.4 awake and 24.4
asleep there, inside 40 to 50, and a test holds it in that band. The pockets between two vents rise
from 43 and 47 to 77 and 84 of 100, still under the 100 the pocket test requires; intensity could go
to about 29 before a pocket reaches 100.

**The whole basement walk, measured** (a rig driving the real vents through the corridor, steam
alone, from an empty meter, awake, over eleven arrival phases with the best of thirteen start
delays each; asleep costs about 0.55 of these): walked well-timed, the peak meter averages 24 and
never passes 61; caught by one blow at the first gate it averages 42 (max 73); at the second or third
gate 50 and 53, reaching 100 in one phase of eleven; caught at two gates 62 to 76, reaching 100 in
one phase; at all three 92, reaching 100 in two. So from an empty meter one mistake fails the section
only at a late gate in about one phase of eleven; the meter she brings down the stairs comes on top.

**Choices open to overturn:** the intensity alone was raised, keeping the pulse and the radii, as
the smallest change; "40 to 50" was read as awake, at the distance she waits at a vent.
