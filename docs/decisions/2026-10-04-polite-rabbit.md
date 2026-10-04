# polite-rabbit — The robber catches her only by touching her · built 2026-10-04

*([freckled-goose](../playtests/2026-10-04-freckled-goose.md), inbox #544: "I just got killed by a
robber that was behind a wall. He couldn't reach me. But it was instant"; "Even then the distance
would not physically connect so counting it as caught would be unfair. Only if the Robert touches the
player should it end instantly".)*

**What was built** (PR #552). A pursuer's catch, `EventInstance.is_lethal_at()`, still tests its
reach first (the robber's 26px is unchanged), and for every row with `def.pursues` then needs a clear
line: `_clear_line_to()` steps tile by tile along the straight line from him to her and refuses any
tile `CityMap.is_walkable()` refuses, so even a corner clipped by a pixel blocks the catch. The lunge
does not ask for the line: it fires at the stand-off as before, and the chase slides round the wall
([M54](2026-08-31-M54-the-resistance-says-something-and-the-robber-stops-at-walls-not-started.md)).
Holding the lunge while a building stood between them was tried first and dropped: at an alley mouth
the line clears with her already inside the stand-off, and he lunged from 29 to 64px and caught her
0.03 to 0.37s later, against about 113px and 0.68 to 0.75s before, which breaks the stand-off and
reaction contract the **events** skill keeps. The rows: `charging_dog`, `alley_robbery`, `robber_giving_chase`, `van_guard_giving_chase`,
`door_guard`, and the hunting copies of `abduction`, `night_raid` and `roadblock`; `masked_pursuer`
runs indoors with no map and is unchanged. `tests/test_events_pursuit.gd` reproduces the catch
through an alley-mouth corner on seed 4242 (failing on the old code), shows the same distance still
catching in the open, the alley-mouth walk-past keeping the old lunge and catch timing, a chase round
the corner whose catch always has a clear line, fixed cases on a hand-built map pinning the line's
corner, edge and start handling, and a 400-segment sweep agreeing with a line sampled every 1/8px.
The **events** skill's pursuit trap now says a wall that holds the lunge back is the same trap, and
the sentences that said a pursuer backs off (the skill, `docs/EVENTS.md`, `Tuning.pursuit_standoff()`)
say it closes to its stand-off and lunges.
`docs/MECHANICS.md` ("Running that matters") and the robber's row in `docs/EVENTS.md` say so;
`docs/COSTS.md` does not change.

**Not built:** excitement behind a wall, whose scope (the robber's field or every source's) waits on
the player; that item stays in the entry.

**Proposed, not asked for, and open to overturn:** only pursuers need the clear line (the cyclist,
the reversing lorry, the cold abduction, the firefight, the car accident and the masked pursuer still
reach in a straight line); "behind a wall" means a tile `is_walkable()` refuses, which is a building
today, so barriers, gatehouses and closures do not block; the doubled red caret still projects a straight line, so it can show red
before he can come round a corner. **Open:** his 140px notice still works through buildings, which may
belong with the excitement item.
