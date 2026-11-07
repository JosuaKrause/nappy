# After dawn: one reader of the walk's events, and no live reachability check

**The ask.** On the board's day-plan-after-dawn, "yes": the day's events after dawn get the same
one-object reader the dawn plan got, in a pull request of its own (inbox #1156 in gray-dolphin). On its design (draft
PR #1169): no consumer filters the raw list of plans itself, "that's what we have interface for";
one method on each placed event; "provide a consistent interface for events that can be used without
knowing details of the event. that applies to all aspects of events", with composition over
inheritance (inbox #1173 in gray-dolphin). The reader is named `WalkEvents`: "yes" (inbox #1173 in gray-dolphin).

Then, on why the placement check counts events that are over: "why would the live state influence
the route? the safe routes are established before the day starts. event placeholders are placed
alongside the routes. when the player walks they get filled in with non-blocking events from the
bag. a blocking event is never placed. and there is no reason to check whether a route is open
during game play because it cannot be closed to begin with" (inbox #1173 in gray-dolphin). Told that a few beats are
placed near her during the walk and some of them block: "we cannot move them to the dawn route since
they get placed close to the player. what we can do is replace already placed off-route blocking
events with them off screen. of course only replace events that were placed there, not things like
guard houses or district barriers. there should be no live reachability check. that's a hard no",
and "the off route events need to be route adjacent. anything deep wouldn't be reachable at all. I
agree on the rest" (inbox #1173 in gray-dolphin).

**Read as:**

- **No live reachability check anywhere.** Nothing placed during the walk may close a route, so
  nothing is checked live. The check that does it today goes: `EventScheduler.WalkSiting`'s
  reachability flood (`_still_leaves_a_park_reachable()`, `_what_already_blocks()`,
  `leaves_her_a_way()`).
- **A blocking beat placed near her takes the place of a blocking event the day placed**, swapped in
  out of her sight. The one it replaces is off the day's routes but route-adjacent, on a street
  touching a route. Only events the day's plan placed are replaced, never the region wall's bodies,
  the checkpoint huts, booms or posts, or a road closure.
- **Only day 13's task roadblock takes the swap.** It is the one walk-placed beat that closes a
  street. Day 3's fire and day 13's column barricade do not block her way: "day 3 file is
  non-blocking so it doesn't need the swap, no? the column barricade is also non blocking so none of
  the blocking rules apply anyway. it can be placed whenever" (inbox #1177 in gray-dolphin). *Read as:* "day 3 file"
  is day 3's fire. The column's barricade is a band along the middle of the roadway that she passes
  on the sidewalk, so it is placed wherever the column stops, with no reachability check. Day 3's fire
  and day 11's added mast are sited on her way like the bag's events, on ground that leaves the
  street passable. *The orchestrator's earlier proposal, agreed in inbox #1173, swapped the column's
  barricade too · narrowed on 2026-11-07 to the roadblock alone, because the barricade does not block
  (inbox #1177 in gray-dolphin).*
- **The task uses a roadblock the day already placed, and swaps one in only when none is close
  by.** Asked whether it should prefer a route-adjacent roadblock the day placed, since "Any roadblock
  answers the task" (docs/NARRATIVE.md, day 13's task) and the red arrow already chooses among the
  day's roadblocks: "yes only swap if you can't find one. but we could also place roadblocks route
  adjacent during dawn. swap only is needed if there is nothing close by" (inbox #1177 in gray-dolphin). *Read as:*
  dawn may place roadblocks route-adjacent, so one is usually close by; the swap is the fallback.
- **The resistance's reachability moves to dawn** (agreed): it offers only chalk marks, contacts and
  masts the day's plan leaves reachable, worked out once and handed in. **The park cordon's gap
  check stays** (agreed): it asks whether anything stands in day 12's last gap, not whether she can
  get somewhere.

*Proposed, not asked for (agreed with the rest):* the swapped-in roadblock's footprint is no wider than the
one it replaces, so it closes no more than dawn closed.

**What is in flight.** Draft #1169 holds its first commit, `Planned.is_door()`, and is being
redesigned to this plan: its description becomes the revised design before anything more is built.
The door-body fix and the spent-plans question it once held are moot once the reachability check
goes; its probe found that on day 13 the check accepts 54 of the 85 candidate sites that really cut
her off.

**Left open by the design, for the revised design to answer:** whether dawn places day 13's
roadblocks route-adjacent, what the task does when neither a roadblock nor a candidate to swap is
near her, and how a swapped-in roadblock looks to her.

**Measured** with the placement fingerprint and day 13 on the six probe seeds (4242, 90210, 1234567,
7, 31337, 2024), before and after.
