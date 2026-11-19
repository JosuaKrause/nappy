# Playtest velvet-alpaca — The board answer corner-turner: the posted guard follows her round the corner

2026-11-18.

The player's answer on the Nappy board to the question corner-turner, the follow-up the entry
azure-squirrel (the posted guard that seemed to miss a straight walker) left open. The note opens with
the question as it stood on the board.

## #1534

1. **Context** (the assistant's):

   The player's answer on the Nappy board to the question corner-turner, asked by the orchestrator on 2026-11-18, as shown:

   - **Question:** when she walks straight past a posted roadblock guard and turns the next corner before he reaches her, may she get away, or does he follow her round it? (blocks a fix for this; nothing else waits)
   - **What you said:** luring the guard away is the way past a roadblock: "it should be in a way that luring away the guard is enough" (inbox #771 in minty-lemur). The docs say walking straight past his post meets his charge.
   - **What was found (azure-squirrel, the guard that seemed to miss):** he notices her about 150px away, warns for 2 seconds while she walks on, then runs at 130px/s against her 92px/s, catching her about 400px past his band. The misses were the test walking her into a building where the street ended; #1525 fixes the test, and every straight walk is caught on his street.
   - **The gap:** where his street ends sooner than that, she can turn the corner. His chase runs straight at her and does not find a way round buildings (only day 13's task guard does), so turning the next corner very likely gets her past without luring; no test walks that turn yet, which a fix would add.
   - **He follows her round the corner (my pick):** the roadblock guard's chase finds its way round buildings as day 13's guard's does. Walking straight past is caught wherever the street ends. Cost: a change to every roadblock's pursuit, checked against the fairness rules (his warning on screen, his give-up time).
   - **Leave it:** turning the next corner is a second way past a posted guard besides luring. Cost: the docs and your rule say luring is the way.
   - **Keep roadblocks away from street ends:** no posted band stands within his catch distance of a corner. Cost: fewer places a roadblock can stand.
   - **Changing later:** the guard's pursuit setting and its tests.

2. **The note.**

   > sure, your pick

3. **Read as:** (the assistant's interpretation, not the player's words)

   The orchestrator's pick, "He follows her round the corner": the posted roadblock guard's chase finds its way round buildings as day 13's task guard's does (ChaseWay), so a straight walker who turns the next corner before he reaches her is still caught; a fix adds a test that walks that turn, checked against the fairness rules (his warning on screen, his give-up time).
