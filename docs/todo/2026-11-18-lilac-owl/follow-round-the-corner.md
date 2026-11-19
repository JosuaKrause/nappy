# The posted guard's chase finds its way round the corner

The posted roadblock guard's pursuit follows her round buildings, as the day-13 task guard's does
(`ChaseWay`), so a walker who goes straight past his post and turns the next corner before he reaches
her is caught as a straight walker is (the entry's README has the player's answer and the reading).

What a fix owes:

- A test that walks that turn: straight past a posted band on a street that ends within his catch
  distance, then round the corner, and he catches her. The escape roadblock rig
  (`tests/escape_roadblock_rig.gd`) and the probe `probes/escape_roadblock_cost.gd` walk posted and
  lure walks today; a lure walk still gets past on every street.
- The fairness rules the events skill gives a pursuer kept: his warning on screen before he charges,
  his give-up time, and a lure still drawing him off his post.
- `docs/EVENTS.md` and `docs/MECHANICS.md` say he follows her round a corner, in place of the
  sentences saying nothing checks that walk.
