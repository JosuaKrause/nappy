# feathery-marmot — Targets near the mark, arrows on the item, touching from any side · built 2026-10-03

*([minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md), statement 3, note #432: "the arrow
correctly points to the van but touching the van doesn't solve the task. also, the van should spawn
close to the mark not across the city. lastly, the robber should be 2/3rds through the alley not
pressed against the edge of it" · "this applies to almost all tasks". On 2026-10-03, in
conversation, captured as inbox notes: the short alley, "Two-thirds wins" (#471); "the red arrows
should point to the actual item -- however, the radius of acceptance should be big enough to be
possible to do" (#484); "Add a mast near the mark" (#485); "Mouth only", "Keep off-screen", and
"The 6 masts rule is stupid anyway. It doesn't come from me. And it actually makes it harder to
encounter masts. We need to discuss this again but not now. Now just add a new mast close by"
(#486); "No! Never besides the item! Where does that come from? This doesn't make any sense"
(#487); "So what? The center doesn't need to get touched. Make the radius big enough" (#488);
"Cross at this district door" / "Should trigger on the action not on a proximity test" (#489);
"Not the drawn swing. Place an ellipse at its base. That's the area to touch" (#492); "No, with
every door do what you did with the burnt building. The arrow goes on the door. The radios is big
enough to touch it from the pavement" (#493); "The gate crossing task should point the arrow on the
gatehouse and crossing should be the test no proximity" (#494); "No it should choose one" (#495);
"Only if silenced" (#497); "for now let's just use my word on the radii and we merge feathery
marmot as is" (#498).)*

**Built (PR #480).**

**Every arrow and every touch is on the item itself.** `red_arrow_target()` is the contact's own
position; the random stand point beside the item (`_reachable_offset()`), which M181 slice two
(PR #336) and M222 put on walkable ground beside a mast, a swing tile or the station's pavement, is
gone. What counts as touching, by item:

| Day | The arrow ends on | The task completes when |
|---|---|---|
| 7 van | the van | her centre is within 72px of it (its 22px body + her 14px + the 36px reach), from any side |
| 8 burnt building | its door on the facade | she is within `DOOR_REACH` (50.6px) of it |
| 9 district door | one of its two gatehouses, drawn once by the day's RNG | she actually crosses that door, either way, let through or walking through (`EventManager.door_crossed`); never by proximity |
| 11 mast | the mast's foot | she is within 56px of it (6px pole + 14 + 36) |
| 12 swing | the frame's base | her body overlaps a ground ellipse at the base, `SWING_BASE`, 22px across each way (the legs meet the ground over 44px in `swing_frame.svg`) and 8.8px deep (the 0.4 squash every ground shadow uses) |
| 13 roadblock | no arrow (any roadblock) | she is within 110px of its band's centre (60px body + 14 + 36) |
| 14 station door | the door point on the facade | she is within `DOOR_REACH`, as day 8 |

Every door follows sandy-egret's rule as merry-koala built it, `DOOR_REACH` centred on the door. On
the two-tile station door that reaches both pavement tiles in front of it but not their two far
outer corners, 57.7px out; the player's answer is to keep the one rule ("use my word on the radii").
A guard's band follows each contact's own reach.

**A task's target is placed near its mark, out of her view.** The man shouting (day 6), the van (7),
day 8's burnt building when the run had no day-3 fire, and a roadblock (13) are drawn within
`NEAR_THE_MARK`, 576px in a straight line (one block, the street beside it and half a block), and
off her screen when she reads the mark, so nothing is seen to appear (`docs/EVENTS.md`); the nearest
qualifying tile is used when none is in range. In practice they land 450–570px away. Day 9's
district door, day 10's neighbor, day 12's swing park, day 14's station door and a burnt building a
real day-3 fire recorded keep their places. Measuring "near" along her path rather than in a straight
line is what the entry still holds.

**Day 11 puts up a mast near the mark** when none of the six stands within 576px of it
(`EventManager.add_mast()`), out of her view, on ground a regular site would be offered on, with the
day's doors kept clear. She silences it like the others; day 14's sabotage counts it; silenced, it
leaves a scar from which `EventScheduler._place_masts()` plants it again on later days, and one never
silenced is not planned again. This overturns M180's "six sites, the same every day" for day 11,
with the player's agreement; `Tuning.MAST_COUNT` and `MastSites` are unchanged, and the six-site
rule itself is to be discussed again.

**A chalk mark sits only at an alley's mouth**, at dawn and on every relocation: an end tile of a
through-alley, or the street end of a courtyard passage. Its robber stands two-thirds of the way
through from that end, 155px in a one-block alley, which replaces M213's "on the far end tile, or up
to three tiles in" (PLAYTEST-142: "always place the [robber] at the other end of the alley"); in
every one-block alley that is closer than M213's 176px floor, the player's "Two-thirds wins". He
never stands within 66px of the mark, his 30px catch and her 36px reach, which a mouth mark never
comes near.

**The route rig** (`src/dev/route_rig.gd`) tries the tiles straight across from a door before the
diagonals, and aims at open ground beside a contact that stands on a body.

**Open to overturn:** 576px straight-line as "near" until the entry's path measure lands; the swing
ellipse's 8.8px depth, which the art does not give; the 66px floor.

**Verified.** The resistance suite and the route rig's suite pass, and every new test was seen to
fail with its change switched off: any-side touch, mouths only, two-thirds, the added mast, the
arrow on each item, day 9 completing only on crossing that door in either direction and never at
the gatehouse or under the boom, and the swing ellipse. The route rig, `--route mark,task
--invincible` on days 6, 7, 8, 9, 11 and 12 over seeds 4242, 90210 and 1234567, completed every
task but day 6 on seed 4242, where it aimed at where the pacing man had been and stopped 61px from
him. Stills are in `docs/evidence/feathery-marmot-task-targets-2026-10-03/`; the mast still was
taken before its arrow moved onto the foot. Each day's target is to be verified in a playable scene
once those exist (inbox #498, #499).
