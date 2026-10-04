priority: now

# feathery-marmot — A task's target is near its mark, and touching it completes it · filed 2026-10-03

> "the arrow correctly points to the van but touching the van doesn't solve the task. also, the van
> should spawn close to the mark not across the city. lastly, the robber should be 2/3rds through
> the alley not pressed against the edge of it" · "this applies to almost all tasks"

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 3 (note #432 and the player's comment on it). The three asks are built ([the record](../../decisions/2026-10-03-feathery-marmot.md)). What is left
is how "near" is measured. On 2026-10-03, asked whether 576px straight-line ("one block + the
street + half a block") was near enough, the player answered (inbox #497): "576px and larger --
two/three blocks is okay *if* it's a straight line -- count along the path not as the crow flies".
**A task's target counts as near its mark by her walking distance from the mark, not the straight
line:** within 576px along her path, or up to three blocks along one straight run with no turn.
`_pick_near()` and `_nearest_to_the_mark()` in `src/resistance/resistance_director.gd` measure
`world.distance_to(mark)` today; the walk field from the mark gives the path distance. The
off-screen rule stays ("Keep off-screen", inbox #486).
