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
goes straight at her as before. The walk is a sweep out from her by `ArrowField`, the red arrow's
own sliced sweep, used read-only over the ground she can walk (closures, soft seals, standing bodies
and posts blocked), 500 tiles a frame, used the moment it reaches his tile and started again once
she has walked 2 tiles; his chase frame costs 0.18ms on average and 0.89ms at worst on seed 4242.
His notice, stand-off and clear-line lunge are decided as before; only his step's direction changes.
`tests/test_day13_guard.gd` again requires the guard parked at another roadblock to reach her
stand-off within 30s on seed 4242 with the gatehouse-day closures (about 19.5s from 1,778px), and a
new check sets him on her with a building across his straight line; both fail with the pathing off
(nearest 479px and 147px against a 116px stand-off). `docs/EVENTS.md`, `docs/NARRATIVE.md`,
`docs/MECHANICS.md` and the director's comment say so. The burst,
[guard-path-2026-10-11](../evidence/guard-path-2026-10-11/), is forced by a capture-only patch not on
the branch that sets the alley robbery row on her; his appearing in her view is the patch's.

*Proposed at filing and built, open to the player's correction:* pathing for this guard only. A
probe of the other pursuers on foot, a straight chase from 360px with a clear line while she walks a
15–30 tile route on three seeds, reached her stand-off in 178 of 180 trials, so they are unchanged.
*Chosen where the entry was silent, open to overturn:* he walks her ground, so he goes round
barriers rather than through them; he goes straight while he has a clear line and before the first
sweep reaches him; he faces the way he walks while pathing and faces her standing; the task's own
guard is pathed too when completion sets him on her; 500 tiles a frame, a refresh every 2 tiles of
her walk and a 6-tile lookahead.
