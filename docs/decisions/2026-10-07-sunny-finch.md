# sunny-finch — The police car is solid in every state and lethal only in front while it drives · 2026-10-10


[Azure-koala](../playtests/2026-10-07-azure-koala.md), finding 8, inbox #601:

> police cars don't have a hitbox

Offered "solid in every state, lethal only in front while driving" (inbox #648 in
[leafy-puffin](../playtests/2026-10-10-leafy-puffin.md)), the player: "yes to the police car
hitbox". This replaces [M61](2026-09-10-M61-one-shape-per-object-the-shape-the-shadow-and-the-body.md)'s
listing of `police_patrol` among "the rows that obstruct nothing", the M226 amendment's reason for
no telegraph ("74px/s is slower than a walk and it never ends the day"), and `at_heat()`'s "The
non-lethal rung stays non-lethal … only the top one kills", which now reads "only the top one
hunts".

**The car is solid in every state.** Built in PR #660: a new `EventDef.drives`, set on
`police_patrol` and kept by every copy (the return leg's, a torn poster's, the raid's pacing car at
her door, the heated and the investigating ones), gives the car a body: a capsule
`GroundShape.segment(9, 12)`, 42px long and 24px wide, the side view's bumper to bumper and the end
view's flank to flank, along the car's heading and turning with it. The same shape is its shadow
(it was a 19px disc), and the picture is anchored as a crowd car's is, over the body.
`EventInstance._drive()` refuses any step or turn that would bring the body into her or the pram,
so the car stands for her rather than pushing her, and drives on only once she is out of its lane
or beyond its warning distance. **It never turns into her**: a turn on its route that would newly
put her in its path within its warning's reach (the strike lead and the 1.6s horn of travel) is
refused, and it stands facing away until she leaves its lane; the review of PR #660 found the
raid's pacing car at her door turning 180° in one frame and striking her from behind with 0.02s to
1.37s of warning. **A car that leaves turns away from her first**, and is finished only beyond
420px from her, so it never vanishes in her view (the investigating car had stood nose to her and
vanished beside her when its chase ended). *Open to overturn:* the crowd's walkers and cars still pass through
it, as they pass through every event body.

**It is lethal only in front of it while it drives.** The strike starts past the nose, as wide as
the body and her together (26px either side of its axis for her body, 20px for the pram), and
reaches `Tuning.PATROL_STRIKE_LEAD` (0.1s of travel, 7px at 74px/s) past where the body would touch
her, since a strike measured only at the touch never fires once the body stops her first. It counts
only while the car drives its route and she is on the carriageway; nothing strikes behind it,
beside it, while it stands, while it leaves, or while it comes over to investigate. **Its warning is
the crowd car's contract**: while it drives at her in its lane the exclamation mark goes up over her
1.6s of its travel before the strike (`Tuning.CAR_HORN_TIME`), more than the 1.39s to walk off the
carriageway, which `Tuning.validate_traffic()` holds on
boot; the doubled red caret shows over the
car whenever staying put would end the day; there is still no screen-edge badge, the car being
slower than a walk. `hard_fail` stays false and `obstructs_radius` 0, so its route role, every
planner and `docs/COSTS.md` are unchanged. A loss to it reads "The patrol car never slowed down.
You were in the road." **It gives way where the crowd's cars do** (`_room_to_its_line()`): off the
main road it stops 34px short of the paint of a zebra she waits at, and at a signalled junction
whose arm is not green it stops 34px short of the junction, carrying on once its nose is past the
line. For a zebra on the far side of a junction it holds at the junction's entry line, where a
red light stops it, decided before its nose reaches the box: from `CAR_JUNCTION_SIGHT` (200px)
short of it, with her waiting at either tile of that zebra (within `CAR_ZEBRA_WAIT_RADIUS` along
and half a street across), however far that is in a straight line; only a car whose nose is
already in the box, committed, stands short of the paint instead. The crowd's own cars have no such
rule (their zebra scan is a 200px circle) and need none, because the box rules see them standing
there; the patrol's body is not seen by them, so it never stands in a box; a car that will stop short of her neither warns her nor
shows the caret, so the zebra stays
"the safe way over" (`docs/MECHANICS.md`). *Open to overturn:* the strike needs her on the
carriageway; a car leaving at its route's end never strikes.

**The investigating car does not strike.** Built: it comes up to her and stops against her, and
strikes only while still patrolling its route. Asked whether it should be deadly in front too, the
player answered with a different car ([merry-stork](../playtests/2026-10-10-merry-stork.md)): "an
investigating police car should not leave the street. it should stop if close to her and a
policeman should emerge and pursue her". That is sandy-ferret's to build, with its pursuer on foot.

`tests/test_police_car.gd` walks her real rig side-on into a standing car (through it, 160px, with
the body off; stopped on its flank with it on), from behind and beside a driving car (solid, never
lethal), in front (lethal, with the warning first), sweeps 324 stands round a turning car without
its body ever coming into her, holds the raid's pacing car standing rather than turning into her
from 41px to 141px behind it, a leaving car never nearer than where it set off, and the car giving
way at a real zebra and a red side arm; the reversal, zebra and red-light tests fail with those
rules off. The doubled caret is drawn as high over the car's picture as over any other row, and the
run log names the patrol when its warning raises the mark. `tests/test_shapes.gd`'s guard that "every emitting segment
row … is stationary" now asks that a moving emitting segment's body lie inside its own core (21px
against 44px). The stills, her against the flank and the warning in front, are in
[police-car-2026-10-10](../evidence/police-car-2026-10-10/README.md).

**Two skills were wrong and are fixed in the same PR.** The events skill said the patrol "does not
telegraph its coming at all (slower than a walk, never ends the day)" and called "anything mobile"
an unconditional exemption; it now names the car's warning and lists four traps: the strike at the
touch, a car that stood for her pulling away into her, a car turning into her, and a car vanishing
beside her. The crowd-traffic skill's
traffic contract now says the patrol keeps it in place of a telegraph, and gives way as the crowd's
cars do.
