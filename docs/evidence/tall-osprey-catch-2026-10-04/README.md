# tall-osprey: the robber's catch, measured

**Question.** The player's "the robber's capture zone is too big" (olive-koala, statement 1) is the
robber's catch, `alley_robbery`'s `inner_radius` (30px before). What size does a chase measured
against a rig say it should be?

**Method.** `tests/probes/tall_osprey_catch.gd` walks the real `EventInstance` for `alley_robbery`
at 60 steps a second, over 200 seeds per cell (reaction time 0.15-0.75s and starting distance
170-230px drawn per seed), with the catch overridden per row of the table. Rerun:
`tools/test.sh probes/tall_osprey_catch.gd`. Source revision `e904eb17` plus this branch; Godot
4.7.2; headless; the result is deterministic per seed.

Answers: `still` (stands in his field), `walk_away`, `run_at_notice` (runs the frame he notices
her), `turn_at_lunge` (walks in, runs `reaction` after he lunges), `turn_at_notice` (walks in, runs
`reaction` after he notices). Numbers are runs, of 200, that got away.

**Result** (`results.txt`). Standing still and walking away are caught at every catch size tried
(0/200), and running at the notice gets away at every size (200/200): the lesson is untouched. The
rig that turns after he notices her gets away 68/200 at the old 30px and 74/200 at 26px, 76 at 24,
80 at 22, 85 at 18. `turn_at_lunge` is 12/200 at every size, because the stand-off is
`catch + 130 * PURSUIT_REACTION`: a smaller catch brings the lunge in by the same amount, so the
room between the lunge and the catch is 78px at any size.

**Chosen: 26px.** Smaller catches measure better but 26px is the floor the shared arrival
distance allows: `Tuning.TRAP_ARRIVAL_DISTANCE` is `catch + 38 * 7.5` over the tighter of the two
trap rows, and the van guard's cone above and below her (`arrival_cone()`) must stay over 10 degrees,
which needs a start of at least about 310px, so a catch under 25px has no start that satisfies both.

**Limits.** One straight line, no corners; the real alley is met at other angles. The held
stand-off (keep the lunge at 108px with a smaller catch) would widen the escape room and is not
built.
