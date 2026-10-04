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
marmot as is" (#498); "I wouldn't frame it that way -- create a circle around the current player
position with the radius of the desired distance -- then follow the path until it reaches the edge
of the circle" and "no need to special case straight runs or anything like that" (#500); "no
events are dynamically created as you walk around -- if there is a mast queued up that will be the
next event to be generated" (#503).)*

**Built (PR #480).**

**Every arrow and every touch is on the item itself.** `red_arrow_target()` is the contact's own
position; the random stand point beside the item (`_reachable_offset()`), which M181 slice two
(PR #336) and M222 put on walkable ground beside a mast, a swing tile or the station's pavement, is
gone. M222 said "the touch point stays beside it where she can reach it"; that sentence is what
"No! Never besides the item!" overturns. What counts as touching, by item:

| Day | The arrow ends on | The task completes when |
|---|---|---|
| 7 van | the van | her centre is within 72px of it (its 22px body + her 14px + the 36px reach), from any side |
| 8 burnt building | its door on the facade | she is within `DOOR_REACH` (50.6px) of it |
| 9 district door | one of its two gatehouses, drawn once by the day's RNG | she actually crosses that door, either way, let through or walking through (`EventManager.door_crossed`); never by proximity |
| 11 mast | the mast's foot | she is within 56px of it (6px pole + 14 + 36) |
| 12 swing | the frame's base | her body overlaps a ground ellipse at the base, `ResistanceDirector.swing_base()`, the extent of the shadow the frame casts there (`Prop._playground_frame_shape()`): 28px across each way and 17px deep for `swing_frame.svg`'s 56 by 34, so what she touches is what she sees |
| 13 roadblock | no arrow (any roadblock) | she is within 110px of its band's centre (60px body + 14 + 36) |
| 14 station door | the door point on the facade | she is within `DOOR_REACH`, as day 8 |

Every door follows sandy-egret's rule as merry-koala built it, `DOOR_REACH` centred on the door. On
the two-tile station door that reaches both pavement tiles in front of it but not their two far
outer corners, 57.7px out; the player's answer is to keep the one rule ("use my word on the radii").
A guard's band follows each contact's own reach.

**A task's target is placed where her path first reaches a circle round her, out of her view.** The
man shouting (day 6), the van (7), day 8's burnt building when the run had no day-3 fire, and a
roadblock (13) stand where one of her paths from where she read the mark first reaches the edge of
a circle of `NEAR_THE_MARK`, 576px (one block, the street beside it and half a block), round her:
the director walks tile by tile over the day's open ground, going on only from tiles inside the
circle, and draws among the pool's tiles at or past its edge (`_follow_the_paths_to_the_edge()`),
off her screen, so nothing is seen to appear (`docs/EVENTS.md`); the nearest qualifying tile is
used when none stands on the edge. Day 9's district door, day 10's neighbor, day 12's swing park,
day 14's station door and a burnt building a real day-3 fire recorded keep their places. The
straight-line draw within 576px it replaces put tasks across a block's buildings from her; with it
switched back the test fails on 9 of 15 days.

**Day 11 queues a mast near her** when no live mast stands where her paths reach in that circle:
the director offers the sidewalk and square on its edge, out of her view, that a site would be
offered on (`MastSites._is_eligible()`), and the scheduler generates the mast there as the next
event, through its own acceptance (`EventManager.queue_a_mast()` → `WalkSiting.among()` →
`EventScheduler._best_of()`): `_room_around()`'s spacing, so never inside a lethal row's field, the
region doors' clear ground, the calm she has not used and the route junctions and sidewalks the day
keeps open. Where it refuses every tile, the nearest live mast is the task's. She silences it like
the others; day 14's sabotage puts it out with them; silenced, it leaves a scar from which
`EventScheduler._place_masts()` plants it again on later days, under the same holds, closures and
door clearance a site is planned under, and one never silenced is not planned again ("Only if
silenced"). This overturns, for day 11, M180's "`_place_masts()` plants a `loudspeaker` plan at
each from `Tuning.MAST_FIRST_DAY` (day 5), the same sites every day", with the player's agreement;
`Tuning.MAST_COUNT` and `MastSites` are unchanged, and the six-site rule itself is to be discussed
again.

**A chalk mark sits only at an alley's mouth**, at dawn and on every relocation: an end tile of a
through-alley, or the street end of a courtyard passage. Its robber stands two-thirds of the way
through from that end, 155px in a one-block alley, which replaces M213's "on the far end tile, or up
to three tiles in" (PLAYTEST-142: "always place the [robber] at the other end of the alley"); in
every one-block alley that is closer than M213's 176px floor, the player's "Two-thirds wins". He
never stands within 66px of the mark, his 30px catch and her 36px reach, which a mouth mark never
comes near.

**The route rig** (`src/dev/route_rig.gd`) tries the tiles straight across from a door before the
diagonals, and aims at open ground beside a contact that stands on a body.

**Open to overturn:** the circle's 576px radius ("576px and larger"); the swing ellipse taken as the
extent of the shadow the frame casts; the 66px floor.

**The queue entry is closed by this PR:** `docs/todo/2026-10-03-feathery-marmot/` held only "near"
measured along her path, which the circle answers (#500), so it is deleted here.

**Verified.** The resistance suite and the route rig's suite pass, and every new test was seen to
fail with its change switched off: any-side touch, mouths only, two-thirds, the added mast, the
arrow on each item, day 9 completing only on crossing that door in either direction and never at
the gatehouse or under the boom, day 9 completing when she is let through the named door after the
inspection and not another door's, the queued mast refused inside a lethal row's field, day 14's
sabotage putting out the queued mast, the circle's edge, and the swing ellipse spanning the frame's
shadow. The route rig, `--route mark,task
--invincible` on days 6, 7, 8, 9, 11 and 12 over seeds 4242, 90210 and 1234567, completed every
task but day 6 on seed 4242, where it aimed at where the pacing man had been and stopped 61px from
him. Stills are in `docs/evidence/feathery-marmot-task-targets-2026-10-03/`; the mast still was
taken before its arrow moved onto the foot. Each day's target is to be verified in a playable scene
once those exist (inbox #498, #499).
