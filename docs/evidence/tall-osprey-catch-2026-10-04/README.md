# tall-osprey: the robber's catch, measured

**Question.** The player's "the robber's capture zone is too big" (olive-koala, statement 1) is the
robber's catch, `alley_robbery`'s `inner_radius` (30px before). What size does a chase measured
against a rig say it should be?

**Method.** `tests/probes/tall_osprey_catch.gd` walks the real `EventInstance` for `alley_robbery`
at 60 steps a second, over 200 seeds per cell (reaction time 0.15-0.75s and starting distance
170-230px drawn per seed), with the catch overridden per row of the table. Rerun:
`tools/test.sh probes/tall_osprey_catch.gd`. Source revision `ce4cb806` plus this branch; Godot
4.7.2; headless; the result is deterministic per seed.

Answers: `still` (stands in his field), `walk_away`, `run_at_notice` (runs the frame he notices
her), `turn_at_lunge` (walks in, runs `reaction` after he lunges), `turn_at_notice` (walks in, runs
`reaction` after he notices). Numbers are runs, of 200, that got away.

**Result** (`results.txt`, two blocks: `follows the catch`, where the stand-off is
`catch + 78`, and `held`, where `EventDef.lunge_reach` keeps the lunge at 108px whatever the catch).
Standing still and walking away are caught at every catch size in both blocks (0/200), and running at
the notice gets away at every size (200/200): the lesson is untouched. Runs of 200 that got away:

| catch | follows: `turn_at_lunge` | follows: `turn_at_notice` | held 108px: `turn_at_lunge` | held 108px: `turn_at_notice` |
|---|---|---|---|---|
| 30 (before) | 12 | 68 | 12 | 68 |
| 28 | 12 | 70 | 13 | 68 |
| 26 | 12 | 74 | 14 | 73 |
| 24 | 12 | 76 | 15 | 74 |
| 22 | 12 | 80 | 20 | 78 |
| 20 | 12 | 80 | 23 | 80 |
| 18 | 12 | 85 | 28 | 82 |
| 16 | 12 | 85 | 31 | 85 |

Holding the lunge at 108px at 26px of catch (82px of room between lunge and catch, instead of 78)
shows up as +2 on the rig that turns after the lunge (14 against 12) and nowhere on the rig that
turns after the notice (73 against 74, within what the 200 seeds separate): the extra four pixels are
worth about 0.03s of his 130px/s. The held stand-off helps visibly only at catches the arrival
distance does not allow (22px and under).

**Chosen: 26px.** Smaller catches measure better but 26px is the floor the shared arrival
distance allows: `Tuning.TRAP_ARRIVAL_DISTANCE` is `catch + 38 * 7.5` over the tighter of the two
trap rows, and the van guard's cone above and below her (`arrival_cone()`) must stay over 10 degrees,
which needs a start of at least about 310px, so a catch under 25px has no start that satisfies both.

**The lunge stays at 108px** (the player's choice of 2026-10-04): `alley_robbery` and
`robber_giving_chase` set `lunge_reach` 30, every other pursuer keeps the lunge measured from its
catch.

**Limits.** One straight line, no corners; the real alley is met at other angles.

## Moving the robber's lunge out (inbox #526, the player's second ask)

Measured for the alley robber alone: his stand-off at 108 (today's), 120 and 130px, set as
`lunge_reach` = stand-off less 78; every other pursuer, the day-3 dog included, keeps
`Tuning.pursuit_standoff()` from its own catch. Same probe, same 200 seeds (`results.txt`, last three
blocks). Runs of 200 that got away; `still` and `walk_away` are 0/200 in every row and
`run_at_notice` is 200/200 in every row. Walk-in is the ground between his 140px notice and his
lunge, walked at `WALK_SPEED` (92px/s).

| catch | stand-off | walk-in notice to lunge | turn at lunge | turn at notice |
|---|---|---|---|---|
| 30 | 108 | 32px, 0.35s | 12 | 68 |
| 30 | 120 | 20px, 0.22s | 28 | 66 |
| 30 | 130 | 10px, 0.11s | 49 | 68 |
| 26 | 108 (built, default) | 32px, 0.35s | 14 | 73 |
| 26 | 120 | 20px, 0.22s | 36 | 70 |
| 26 | 130 | 10px, 0.11s | 56 | 74 |
| 24 | 108 | 32px, 0.35s | 15 | 74 |
| 24 | 120 | 20px, 0.22s | 43 | 74 |
| 24 | 130 | 10px, 0.11s | 57 | 74 |

Moving the lunge out is what moves `turn_at_lunge` (14 to 36 to 56 at 26px of catch); the catch
alone barely does. The cost is the notice: at 130px the lunge is 10px inside his notice, so he
notices and lunges within about a tenth of a second of walking in, and the notice is no longer a
walk-in at all.

Contracts at the cost: `Tuning.validate_pursuit` still passes (lunge inside 140px notice and 200px
field). Trying 130px in the catalogue and running `tools/test.sh resistance events_pursuit
events_costs tutorial_dog` fails six checks, all about the no-trigger trap row (`robber_giving_chase`
copies the alley robber): `Tuning.TRAP_ARRIVAL_DISTANCE` (311px) must be at least stand-off plus
130 x 1.5 = 325px so that standing still he lunges no sooner than 1.5s after he appears (he lunged at
1.42s), and the arrival cone would need re-measuring; 120px needs 315px, also over 311. The chalk
mark's guard placement is stated over `pursues_within` (140px) and his catch, not the stand-off, so it
is unaffected: no guard test failed, and the guard stays outside his notice range of a touch at the
mark. 108px is built as the default; 120 or 130 also needs the arrival distance raised past the van
guard's cone floor.
