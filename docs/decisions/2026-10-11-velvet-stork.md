# velvet-stork — Day 13's guard walks round buildings to reach her · 2026-10-11


Found while building [bouncy-egret](2026-10-10-bouncy-egret.md), not reported by the player.
[calm-pelican-14](2026-10-10-calm-pelican-14.md) sets day 13's task guard on her the moment she
completes the task, wherever he stands, from the player's "as long as he starts pursuing when you
hit the task it's fine" ([curly-gecko](../playtests/2026-10-10-curly-gecko.md)). A guard at another
roadblock came straight at her with no pathing: on seed 4242 with bouncy-egret's halved closures,
from 1,778px away with a building between them, he stopped at 479px and never reached her.

**He walks the way to her round buildings.** `EventInstance.notice_her_at()`, which only day 13's
completed task calls, sets `_paths_to_her`. In `_chase()`, while he has no clear line to her, he
steps toward the farthest of the next six tiles he can see along a walk to her; with a clear line he
goes straight at her as before, through a barrier as any chase does. The walk is a sweep out from
her by `ArrowField`, the red arrow's own sliced sweep, over the ground she can walk (closures, soft
seals, standing bodies and posts blocked), laid out by `ArrowField.ground_for()`, which the red
arrow is to share (`tests/test_day13_guard.gd` checks the director's own copy matches it). It runs
500 tiles a frame, is used the moment it reaches his tile, and starts again once she has walked 2
tiles, or, while he is far, a quarter of his walk to her. On the debug desktop build, with her
walking away on seeds 4242, 90210 and 555, a sweep runs on 5% of his chase frames and a frame costs
about 0.09ms on average and at most 0.51ms; there is no web-build figure.
`tools/test.sh probes/velvet_stork_guard_path_cost.gd` reruns it. His notice, stand-off and
clear-line lunge are decided as before; only his step's direction changes.

**He reaches her if she waits, not always if she walks away.** He walks at 130 px/s against her 92,
so walking away she loses ground only slowly and his 30s chase can run out first; running still
shakes him off. Standing, she is reached in 19.5s from 1,778px on seed 4242 and 26.7s from 2,887px
on 90210, while from 3,521px on 555 his chase ends 173px short. `tests/test_day13_guard.gd` again
requires the guard parked at another roadblock to reach her standing stand-off within 30s on seed
4242 with the gatehouse-day closures, and a new check sets him on her with a building across his
straight line; both fail with the pathing off (nearest 479px and 147px against a 116px stand-off).
`docs/EVENTS.md`, `docs/NARRATIVE.md`, `docs/MECHANICS.md` and the director's comments say so. The
burst, [guard-path-2026-10-11](../evidence/guard-path-2026-10-11/), is forced by a capture-only patch
not on the branch that sets the alley robbery row on her; his appearing in her view is the patch's.

*Proposed at filing and built, open to the player's correction:* pathing for this guard only.
`tools/test.sh probes/velvet_stork_other_pursuers.gd` probes the others on seeds 4242, 90210 and
555: from clear-line starts 360px off, with her walking a 15–30 tile route, a straight chase reached
her stand-off in 178 of 180; from the sent robber's own day-13 starts with her standing, all 437
with a clear run reached her, and of the 5 from the no-clear-run fallback `docs/EVENTS.md` already
names, 4 did not, about one start in 110. They are unchanged.
*Chosen where the entry was silent, open to overturn:* where no clear line runs to her he walks
round what she has to walk round; he goes straight while he has a clear line and before the first
sweep reaches him; he faces the way he walks while pathing and faces her standing; the task's own
guard is pathed too when completion sets him on her; 500 tiles a frame, a refresh every 2 tiles of
her walk and a 6-tile lookahead.
