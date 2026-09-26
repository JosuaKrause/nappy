## M98 — Pressure in the empty acts · the return owes her patrols, built 2026-09-12

*(2026-09-12, on the list of open items: "M98, too" — the go-ahead, with the shape left to the
orchestrator.)* The last item of M98, patrols for acts III and IV built around encounter cost.
**The shape is the orchestrator's recommendation, not the player's design, and every number in
it is open to overturn.** Three agent commits on `feature/return-patrols`, reviewed here. When
`EventBus.return_phase_started` fires — `Baby` emits it on both paths to asleep, so nothing new
had to emit — `EventManager` forwards the day and `GameState.resistance_progress` to
`EventDirector.owe_the_return()`, which appends `Tuning.RETURN_PATROLS_PER_ACT[act - 1]`
(`[0, 0, 2, 3]`) copies of `police_patrol` at the day's own heat to the director's single owed
queue and switches its interval roll to `Tuning.RETURN_PATROL_INTERVAL` (9–16s) from
`AHEAD_INTERVAL` (11–26s) for the rest of the day; the pending wait is shortened with `minf`
rather than re-rolled, because an unconditional re-roll produced one seed (day 9, a 13.2s leg)
where the after-figure owed *fewer* encounters than before. Owed once per day (`_return_owed`),
so a baby that wakes and settles again owes no second batch; rows already owed stay owed when the
phase drops back to walking; `--force` days are left alone; `validate_return_patrols()` refuses a
malformed array or an interval not strictly inside `AHEAD_INTERVAL`'s. **The copy is a
`duplicate()` of the heated row with `spawn_mode = TOWARD_PLAYER`**, never a mutation of the
cached heated def, since that copy is shared with every ordinary `MAP` placement of the row for
the rest of the run. **A car is sited on the carriageway, not her pavement**:
`_toward_her_on_the_road()` is the road-aware sibling of `_toward_her()`, chosen in `due()` for a
`TOWARD_PLAYER` row whose `placement` names `ROAD`; it reads the corridor from
`CityMap.pavement_inward()`, picks the lane `CrowdLanes.road_lane()` says drives opposite her
along-corridor heading, snaps both ends of the line to that lane's centre at the ordinary
offscreen lead, and answers empty — retry later — where she is in a park, a square, a junction or
on a precinct, or either end fails `is_driveable_at()`. No `hard_fail` branch, since the patrol
never gains it at any heat. `EventInstance` needed nothing: a route-driven `ALONG_STREET` row
already draws and turns off its path.

**Measured after, on the same probe** (`tests/probes/m98_return_phase.gd`, now two identically
seeded directors per seed and day, the second told the return has started at the leg's start; six
seeds, days 2, 5, 9, 13): owed encounters per return leg act I 2.50 → 2.50, act II 2.17 → 2.17,
act III 1.83 → 2.50, act IV 2.17 → 2.83; return legs meeting nothing 2 of 24 before and after.
Acts I and II unchanged by construction; a modest rise in III and IV, which is the size the
constants were chosen for. Whether that reads as pressure or as punishment on the walk home is a
played question, in `REVIEW.md`. **Tests**: `tests/test_return_patrols.gd` — the owed count per
act, no double batch, `--force` untouched, the interval band before and after, the road-siting
geometry, empty in a park, the validation. **Rejected on the way**: an unconditional interval
re-roll (above); the director reading `GameState` itself rather than taking heat as an argument,
kept out so a rig can still drive it with no autoloads. **What this did not do**: touch the crowd
table, the budget, or any other row — the entry's own rule that the return's pressure is *met*,
never ambient.
