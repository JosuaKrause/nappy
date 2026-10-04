# tall-osprey — The robber's catch is 26px and his lunge 116px · 2026-10-04

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 1: "the robber's capture zone is
too big." Asked which zone, the player chose the catch, 2026-09-27.)* Built in PR #524.

**What is built.** `alley_robbery`'s catch (`inner_radius`, where he ends the day) is **26px**; his
140px notice (`pursues_within`) and 200px field are unchanged. His lunge (the stand-off from which
he closes in) is **116px**, set by `EventDef.lunge_reach` = 38 over the 78px pursuit allowance, so
90px lie between his lunge and his catch. `robber_giving_chase` reads the same row; every other
pursuer, the day-3 dog included, keeps its stand-off measured from its own catch.
`Tuning.TRAP_ARRIVAL_DISTANCE` stays 311px, where two rules meet for him: M137's walk-away margin
(a walker who leaves at once is caught with half a second of chase to spare, at most
26 + 38 × 7.5 = 311px) and the lunge floor (standing still, he lunges no sooner than 1.5s after he
appears, at least 116 + 130 × 1.5 = 311px). The chalk mark's guard floor, catch plus a contact's
reach, is 62px; the "Two-thirds wins" placement is unchanged.

**The player's choices** (inbox #526 in [azure-tapir](../playtests/2026-10-04-azure-tapir.md), 2026-10-04): keep the lunge out while only the catch shrinks
("Keep the stand-off at 108px"); then, shown a longer lunge measured, "yes measure", and picked
120px; then, shown that 120px needs a 315px arrival distance against M137's 311px ceiling,
"116px, keep every rule". The notice times the question that
offered 120px quoted (0.35s at 108px, 0.22s at 120px, 0.11s at 130px) counted only her walk from his
notice to his lunge; measured with him closing on her, they are about half that (0.15s, 0.10s and
0.05s), and 0.12s at the 116px built.

**Measured** (`tests/probes/tall_osprey_catch.gd`, 200 seeded chases per row, evidence in
[tall-osprey-catch-2026-10-04](../evidence/tall-osprey-catch-2026-10-04/README.md)). Standing
still and walking away are caught and running at his notice gets away in every row. A rig that
runs only once he lunges gets away 12 of 200 before (30px catch, 108px lunge) and 28 of 200 as
built; 120px would have given 36, 130px 56. He closes on her while he notices her, so walking in,
his notice lasts about 0.12s before the lunge at 116px (0.15s at 108px, 0.05s at 130px), and about
0.20s if she stands at the edge of it.

**Rejected:** a catch under 26px, which the van guard's arrival cone (over 10° in
`tests/test_resistance.gd`) cannot hold with the shared arrival distance; a 120px lunge, which
breaks M137's half second at 315px (built as an experiment, only that check failed, 0.395s to
spare); a longer trap notice, which reopens PLAYTEST-140's long warning; a 120px lunge for the
alley robber alone, which would part the trap copy from his row.

**Open to overturn:** 26px as the floor the arrival distance allows. At 116px the lunge floor sits
exactly on 311px (walked, he lunges at 1.52s), so a longer lunge or a smaller catch breaks a trap
contract unless the arrival distance and M137's margin are revisited together.
