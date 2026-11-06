# Playtest brisk-moose — guard sees past his own barrier and CI speed

2026-11-06.

## #1119

1. **Context** (the assistant's):

   Answered on the Nappy board's question guard-sees-past-own-band, on its You line. The question, as written there:

   Question: a heads-up: in the escape, a roadblock's posted guard can fail to see her across his own barrier, so she walks straight past him. I'm fixing it so he sees out of his own band again. OK?

   Context: the escape-rigs test build (PR #1107) now stands roadblocks the way a played day does, which records the barrier's body on the map. On 7 streets across three seeds, in both directions, the guard posted at the barrier warns for 2 s but never charges: his line of sight to her crosses his own barrier's body, which blocks it. The old rig never recorded that body, so no test saw it. The game's own comment says "a guard sees out of the band he stands in", and the finale's design is that luring the guard off is the way past a roadblock, so this reads as a bug against what was built. The fix: his own barrier no longer hides her from him; any other barrier, a building or a café still does, and a catch through a barrier still fails. Effect in play: on those streets she can no longer slip past a posted guard.

   My pick: fix it inside #1107, with a test that fails on today's code. If you leave this, it goes ahead that way; say so if walking past him there was something you liked.

   The fix was built and merged in #1107 on that pick.

2. **The note.**

   > sgtm

3. **Read as:** (the assistant's interpretation, not the player's words)

   The player agrees with the fix as built: a roadblock's posted guard sees her across his own barrier, so she cannot walk past him there.

## #1130

1. **Context** (the assistant's):

   Answered on the Nappy board's question ci-speed, on its You line. The question, as written there:

   Question: CI went from about 11 to 13 minutes on main (longer while many PRs queue). Beyond the fixes that change no coverage, which I am starting now, should I also (a) run CI on 12 shards instead of 8, and (b) trim the heaviest sweeps?

   Context: (a) 12 shards: about 10.7 to 7.1 minutes wall time, for 1.5 times the runner minutes (each shard also pays its start-up again). No code risk. (b) trims, each with a small coverage cost, together about 6 suite-minutes (under a minute of wall time): the mouse-prefers-a-pile test rolls 3 days per seed instead of 6 (it still sees about 140 mice against a bar of 100); the masked-man badge test meets him at 5 pause points instead of 11; the park cordon sweep stands the street musician at 2 park spots instead of 4; the resistance reach sweeps use 2 seeds instead of 4; the crowd closure scenarios watch only as long as each check needs.

   My pick: (a) yes, now, since it is the only change that moves wall time much; (b) yes for the mouse, badge and crowd-window trims, which keep their margin, and no for cutting cordon spots or reach seeds, which are the sweeps that have caught real bugs.

2. **The note.**

   > yes, what you said (a) and (b) and no cutting sweeps that found real bugs

3. **Read as:** (the assistant's interpretation, not the player's words)

   The player takes the pick as written: CI runs on 12 shards; the mouse-prefers-a-pile test rolls 3 days per seed, the masked-man badge test meets him at 5 pause points, and the crowd closure scenarios watch only as long as each check needs; the park cordon sweep keeps its 4 park spots and the resistance reach sweeps keep their 4 seeds.
