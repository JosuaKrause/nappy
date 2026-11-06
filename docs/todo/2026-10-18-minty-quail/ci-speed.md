# CI on twelve shards, three sweeps trimmed

**The ask.** Asked whether CI, gone from about 11 to 13 minutes on main, should also run on 12
shards instead of 8 and have its heaviest sweeps trimmed, the player: "yes, what you said (a) and
(b) and no cutting sweeps that found real bugs" (brisk-moose #1130). The question and the pick it
accepted are in that playtest.

**Read as:** CI runs on 12 shards; the mouse-prefers-a-pile test rolls 3 days per seed instead of
6, the masked-man badge test meets him at 5 pause points instead of 11, and the crowd closure
scenarios watch only as long as each check needs. The park cordon sweep keeps its 4 park spots and
the resistance reach sweeps keep their 4 seeds, the sweeps that have caught real bugs.

**What is to be built.** The CI workflow's shard count goes from 8 to 12, and the three trims above
are made in their suites. The pull requests that build them delete this file when they land.
