# tall-osprey: the robber's catch, measured

**Question.** The player's "the robber's capture zone is too big" (olive-koala, statement 1) is the
robber's catch, `alley_robbery`'s `inner_radius` (30px before). What size does a chase measured
against a rig say it should be, and, once the catch was smaller, how far out should his lunge be?

**Method.** `tests/probes/tall_osprey_catch.gd` walks the real `EventInstance` for `alley_robbery`
at 60 steps a second, over 200 seeds per cell (reaction time 0.15-0.75s and starting distance
170-230px drawn per seed), with the catch and the lunge (`EventDef.lunge_reach`) overridden per row
of the table, whatever the catalogue says. Rerun: `tools/test.sh probes/tall_osprey_catch.gd` on
PR #524's branch (`git fetch origin refs/pull/524/head`); first run on `ce4cb806` plus this branch;
Godot 4.7.2; headless; the result is deterministic per seed, and every row measured on an earlier
run of the branch came out identical on the last one.

Answers: `still` (stands in his field), `walk_away`, `run_at_notice` (runs the frame he notices
her), `turn_at_lunge` (walks in, runs `reaction` after he lunges), `turn_at_notice` (walks in, runs
`reaction` after he notices). Numbers are runs, of 200, that got away.

## The catch

**Result** (`results.txt`, first two blocks: `follows the catch`, where the stand-off is
`catch + 78`, and `held`, where `EventDef.lunge_reach` holds the lunge at 108px whatever the catch).
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

The catch alone barely moves the rig that turns after the lunge: holding the lunge at 108px at a 26px
catch is +2 (14 against 12), and nothing on the rig that turns after the notice (73 against 74,
within what 200 seeds separate).

**Chosen: 26px.** Smaller catches measure better but 26px is the floor the shared arrival
distance allows: `Tuning.TRAP_ARRIVAL_DISTANCE` (311px) is `catch + 38 * 7.5` over the tighter of the
two trap rows (the walk-away ceiling below), and the van guard's cone above and below her
(`arrival_cone()`) must stay over 10 degrees, which needs a start of at least about 310px, so a catch
under 25px has no start that satisfies both.

## The lunge (inbox #526)

Measured for the alley robber alone: his stand-off at 108, 112, 116, 120 and 130px, set as
`lunge_reach` = stand-off less 78; every other pursuer, the day-3 dog included, keeps
`Tuning.pursuit_standoff()` from its own catch. Same probe, same 200 seeds (`results.txt`, last three
blocks). Runs of 200 that got away; `still` and `walk_away` are 0/200 in every row and
`run_at_notice` is 200/200 in every row. Walk-in is the ground between his 140px notice and his
lunge, walked at `WALK_SPEED` (92px/s).

| catch | stand-off | walk-in notice to lunge | turn at lunge | turn at notice |
|---|---|---|---|---|
| 30 | 108 | 32px, 0.35s | 12 | 68 |
| 30 | 112 | 28px, 0.30s | 14 | 67 |
| 30 | 116 | 24px, 0.26s | 20 | 66 |
| 30 | 120 | 20px, 0.22s | 28 | 66 |
| 30 | 130 | 10px, 0.11s | 49 | 68 |
| 26 | 108 | 32px, 0.35s | 14 | 73 |
| 26 | 112 | 28px, 0.30s | 20 | 72 |
| **26** | **116 (built)** | 24px, 0.26s | **28** | 70 |
| 26 | 120 | 20px, 0.22s | 36 | 70 |
| 26 | 130 | 10px, 0.11s | 56 | 74 |
| 24 | 108 | 32px, 0.35s | 15 | 74 |
| 24 | 112 | 28px, 0.30s | 21 | 74 |
| 24 | 116 | 24px, 0.26s | 33 | 74 |
| 24 | 120 | 20px, 0.22s | 43 | 74 |
| 24 | 130 | 10px, 0.11s | 57 | 74 |

Moving the lunge out is what moves `turn_at_lunge` (14 to 28 to 36 to 56 at 26px of catch); the catch
alone barely does. The cost is the notice: the further out the lunge, the less of a walk-in his
notice is, down to 10px at 130px.

**Built: the 26px catch with the 116px lunge** (`lunge_reach` 38) on `alley_robbery` and
`robber_giving_chase` (the player, 2026-10-04: "116px, keep every rule"). It is the furthest lunge
every trap-row contract allows at that catch:

- **The lunge floor.** `robber_giving_chase` copies the alley robber's lunge and starts
  `Tuning.TRAP_ARRIVAL_DISTANCE` from her; standing still, he must lunge no sooner than
  `PURSUIT_MIN_NOTICE` (1.5s) after he appears, so the distance must be at least stand-off +
  130 x 1.5: 303px at 108, 311px at 116, 315px at 120, 325px at 130.
- **The walk-away ceiling** (M137, `docs/decisions/2026-09-13-M137.md`: "the furthest start a walker
  still loses from ... with half a second of the notice-plus-chase kept as margin"). A walker who
  leaves the moment he appears is closed on at 38px/s and must be caught with half a second of the
  8.0s notice-plus-chase to spare, so the distance may be at most catch + 38 x 7.5: 311px at the
  robber's 26px catch, 313px at the van guard's 28px.

At 116px both meet at 311px, and the distance is unchanged. **120px did not fit**: it needs 315px,
over the 311px ceiling. Built as an experiment (lunge 120, distance 315), `tools/test.sh resistance
events_pursuit` failed only that ceiling's check, once per trap row (spare 0.395s for the robber,
0.447s for the van guard); every walked check passed. The van guard's arrival cone is not the limit:
it grows with the distance (11.4 degrees at 311px, 14.3 at 315px, against the test's 10).

Walking the built trap row (`tests/test_resistance.gd`'s own rig, from straight above and below at
311px): the badge rises at 0.05s, he is on screen at 0.77s, standing still he lunges at 1.52s and
catches her at 2.20s; walking directly away he catches her at 7.50s.

The chalk mark's guard placement is stated over `pursues_within` (140px) and his catch, not the
stand-off, so it is unaffected: the guard stays outside his notice range of a touch at the mark.

**Limits.** One straight line, no corners; the real alley is met at other angles.
