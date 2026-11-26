# The car-free start at day 1's door (grassy-beaver, PR #1802)

**Claim.** With the title dismissed and day 1 begun, the cars already in her view at the doorstep keep
driving until they leave the crowd's box and are then parked; no car comes in after them. A burst
started a few seconds later shows none.

**Limits.** One seed, one windowed run, her standing still at the door (`--invincible`). The title is
dismissed by a rig's `ui_accept` press, so this is the title's first-tick hold (cars in view keep
driving), not the no-title hold before the morning. It says nothing about the release on the fourth
street, or about the cars at lesson (5)'s zebra (the lessons PR). It is dated runtime evidence of one
build, not an approved reference.

**Source revision.** `fb4718e7f` plus the working-tree fixes of this PR's follow-up commit (`git log` names it).

**Command.** `RESOLUTION=1280x720 tools/shot.sh /private/tmp/gb-door.png 16 --seed 4242 --title --invincible
--press ui_accept 1.5 --press snapshot_burst 2 --press snapshot_burst 6 --press snapshot_burst 10`.

**Sheet.** `door-sheet.png`: one row per burst (first, second, third), four frames per row at about
0, 1, 2 and 3 s into the burst (frame times in the `burst-*.json` sidecars; the three bursts start
about 4 s apart). Row 1 shows the cars in view at the door driving on through the whole first burst
(three seconds, one still crossing in its last frame); rows 2 and 3, 4 and 8 s later, show no car
on the street, only walkers.

**Retained.** The sheet and the three sidecars; the 88 frames behind them stay in scratch space.
