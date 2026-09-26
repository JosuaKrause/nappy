## M168 — The escape after playtest 94 · built 2026-09-19

[PLAYTEST-94](../playtests/PLAYTEST-94.md) findings 4 to 14 and [PLAYTEST-96](../playtests/PLAYTEST-96.md),
the player's own words there. Agent commits on `feature/m168-escape-after-playtest-94`, one per
item; stills, bursts and their run folders are `evidence/m168-escape-2026-09-19/`.

**Rubble, and the fire fixed to the left.** `InteriorMapPlan.rubble` is a tile rect the layout
declares as it lays the top floor: columns 8 and 9 of the hallway, both rows, east of her door
(column 7) and short of the right stair door (column 13). `is_walkable()` reads it first; nothing
scans for a place and nothing repairs one. A rect rather than a tile kind, because the ground is
not what changed. The fire's side was rolled by seed and is the constant left: on half of all
seeds the roll burned the one shaft the rubble leaves her. *"I like that rubble."*

**The masked man comes again.** A fresh instance starts at the foot of the right shaft
`Tuning.FINALE_PURSUER_RESPAWN_SECONDS` (6s) after the last one leaves its top, for as long as
she is in the building, each standing through its whole 3.6s telegraph. Measured: 11 men over one
clock, every gap 6.00s; the farthest door from any cell of his line is 168px, 1.82s at 92px/s. A
flood from her door with the rubble and the fire's blocking reach removed reaches the service
exit. **Open to overturn, chosen where the player said nothing:** the 6 seconds (a shaft is about
6s of running plus the telegraph, so the shaft is his two thirds of the time), the same shaft
every time, the gap counted from his leaving the top. **Rejected:** a second man on the other
shaft, which removes the choice the switching is for; one man pacing forever, which takes his
telegraph away. Found on the way: the building's events kept running unseen after she reached the
city, and `InteriorEvents.stand_down()` ends them.

**The steam.** She walked past a vent because it stood on the seam of a two-tile band and the lane
along the wall was free. All three stand on cells where the corridor is one tile wide
(`InteriorMapPlan.corridor_narrows`; two are the sketch's jogs, the third a pinch the band is laid
with), and each is a cell whose removal cuts the exit off. Periods 4, 4.5 and 5.5s against a 2s
blow (they were 6.5, 8 and 9.5): crossing a vent's reach takes 0.65s, so the shortest period
leaves 1.35s of margin, and as half-seconds the three are pairwise coprime. The worst pocket
between two vents is shut at both ends for 2.00s and costs 47 of the meter's 100.

**No danger mark at the city spawn.** Traced on seed 4242: an `abduction` van 143px from the
service exit whose 250px outer radius covered her, which is `EventManager`'s condition for the
flashing mark; on ten seeds a van did it on all ten and a hunting `roadblock` on two. M165 had
kept bodies off her tile; the mark is about the field. `EventScheduler._clearance_around_her()`
answers the whole `outer_radius` for anything `hard_fail`, in the candidate loop. Zero rows raise
the mark on the ten seeds.

**A lost section shows the brief.** `FinaleController` emits `section_lost` and restarts from the
brief's continue; `DaySummary.show_finale_brief()` shows the section's own hint line and the
unchanged nerve count. No sentence about the loss, since nothing was spent.

**The run log carries times.** Nothing opened a telemetry section in the escape and nothing
pushed a clock; `Telemetry.begin_finale()` and a mirror of the HUD's clock do. The building still
writes no gameplay entries of its own: it has no observer, and one is a milestone rather than a
fix.

**The window flashes.** Silent distant flashes between the loud explosions: no `EventInstance`,
no field, nothing on the meter. *"all windows always need to flash together"* — a half-hallway
subset was the orchestrator's idea, was seen by the player and was deleted. *"a biased random
distribution between 100ms and 5s between flashes where the mean is 1.3s and the rest of the curve
is smooth"* is a scaled Kumaraswamy draw, `t = MIN + (MAX − MIN) · sqrt(1 − (1 − u)^(1/B))` with
`B` 12.343 solved for the mean; a closed-form inverse keeps one draw per flash, so a seed replays
the same night. 4000 draws: mean 1.289s, none outside the bounds; 51 flashes a minute against 2.
**Open to overturn:** light without noise at all, where more explosions is one constant and a
louder building.

**The basement stair.** *"can we just replace it with a full gray texture with dark gray lines
every x pixels"* ([PLAYTEST-106](../playtests/PLAYTEST-106.md)), with a 32 by 32 example of one dark
row in four. `stair_down.svg` is a flat `#8b8e93` with a one-pixel `#4a4d52` line every four
pixels from the top row down, so stacked tiles keep the rhythm; the narrowing treads, the stepped
sides and the arrow are gone. The two grays are the orchestrator's pick. Still:
`evidence/m168-escape-2026-09-19/basement-stair-gray-lines.png`.

**The roadblock's guard.** *"the guard needs to be at the barrier from the beginning, standing.
only then does it make sense for it to start pursuing. 86px is huge why is that the fix for the
problem that the radius is too big?"* The 86px was never a fix for a radius being too big: the
lethal radius was 24px and was raised because `EventDef.validate()` refuses a lethal radius
inside the row's own solid reach (60px band plus her 14px), which made the barrier's size the
man's reach. Now `guard_standing.svg` is drawn on every roadblock, hunting or not; a hunting
copy's guard telegraphs where he stands and sets off from there; `body_stays_behind` leaves the
band drawn and solid where it was, so the street stays shut; and `lethal_radius` (28px,
`EventCatalogue.MASKED_MAN_REACH`, shared with the building's masked man) is what catches her,
measured from him. `inner_radius` stays 86 as the field's core, since the cost table is stated
against it, and no balance number moved. `validate()`'s body rule is stated over rows that stand
still. **Open to overturn:** he stands at the band's center where an end post was asked for,
because the instance becomes the man and an end post moves the field 60px on that frame.
**Rejected:** a separate guard row, which needs a third picture of the same man and has no
trigger. **Not captured:** a hunting one setting off; the nearest on seed 4242 is 834px south of
the spawn behind a van, and a test drives the sequence instead.
