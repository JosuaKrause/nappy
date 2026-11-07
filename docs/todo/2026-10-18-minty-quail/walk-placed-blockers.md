# After dawn: one reader of the walk's events, and no live reachability check

**The ask.** On the board's day-plan-after-dawn, "yes": the day's events after dawn get the same
one-object reader the dawn plan got, in a pull request of its own (inbox #1156 in gray-dolphin). On its design (draft
PR #1169): no consumer filters the raw list of plans itself, "that's what we have interface for";
one method on each placed event; "provide a consistent interface for events that can be used without
knowing details of the event. that applies to all aspects of events", with composition over
inheritance (inbox #1173 in gray-dolphin). The reader is named `WalkEvents`: "yes" (inbox #1173 in gray-dolphin).

**No live reachability check anywhere.** "the safe routes are established before the day starts.
event placeholders are placed alongside the routes. when the player walks they get filled in with
non-blocking events from the bag. a blocking event is never placed. and there is no reason to check
whether a route is open during game play because it cannot be closed to begin with", and "there
should be no live reachability check. that's a hard no" (inbox #1173 in gray-dolphin).

*Asked for as a beat placed during the walk only where she can still get away: M181's day 13 column,
whose rear truck "leaves a permanent barricade where it stops, out of her sight and only where home
and a calm area stay reachable" (record M181, the resistance has a reason, and a task is one day:
slice two) · overturned on 2026-11-07 to no live reachability check at all, because the day's safe
routes are fixed at dawn and nothing placed during the walk closes one (inbox #1173 in gray-dolphin, inbox #1177 in gray-dolphin).*
The build rewrites `docs/EVENTS.md`'s `military_convoy` row, which places the barricade "at the first
such point whose barricade still leaves her a way home and to a calm area
(`EventScheduler.WalkSiting.leaves_her_a_way()`)", and deletes `WalkSiting`'s reachability flood
(`_still_leaves_a_park_reachable()`, `_what_already_blocks()`, `leaves_her_a_way()`).

**What counts as blocking.** Told day 13's task roadblock leaves a sidewalk tile open: "even if she
can technically walk through it everything about it tells the player to not do that. so let's not
assume that a player would use it", then "unless there is a gap with a full sidewalk" (inbox #1179 in gray-dolphin).
*Read as:* a body counts as blocking her way unless it leaves a gap at least a full sidewalk wide
(`Tuning.SIDEWALK_WIDTH`, 2 tiles) for her to pass.

**So nothing placed during the walk takes a swap.** The builder of #1169 measured both beats against
that rule: the column's barricade at every stop sampled and the task roadblock at every site sampled
keep the far sidewalk fully open, so neither blocks.

- **Day 13's task roadblock** is placed near her, out of her sight, under dawn's own placement rules,
  with no reachability check. A roadblock the day already placed close by answers the task first:
  "yes only swap if you can't find one. but we could also place roadblocks route adjacent during
  dawn. swap only is needed if there is nothing close by" (inbox #1177 in gray-dolphin), since "Any roadblock answers
  the task" (docs/NARRATIVE.md, day 13's task).
- **Day 13's column barricade** stands where the column stops: "the column barricade is also non
  blocking so none of the blocking rules apply anyway. it can be placed whenever" (inbox #1177 in gray-dolphin).
- **Day 3's fire and day 11's added mast** are sited on her way like the bag's events: "day 3 file
  is non-blocking so it doesn't need the swap, no?" (inbox #1177 in gray-dolphin; *read as* day 3's fire).
- **The resistance's reachability moves to dawn** (the orchestrator's proposal, agreed: "I agree on
  the rest", inbox #1173 in gray-dolphin): it offers only chalk marks, contacts and masts the day's plan leaves
  reachable, worked out once and handed in. The guarantee is record M188's (a resistance target can
  always be reached); only where it is worked out moves. **The park cordon's gap check stays**
  (agreed in the same words): it asks whether anything stands in day 12's last gap, not whether she
  can get somewhere.

**The swap stays as the rule for a beat that would block**, for any future beat placed near her that
leaves no full sidewalk: "replace already placed off-route blocking events with them off screen. of
course only replace events that were placed there, not things like guard houses or district
barriers", the one replaced being route-adjacent: "the off route events need to be route adjacent.
anything deep wouldn't be reachable at all" (inbox #1173 in gray-dolphin). *Proposed, not asked for (agreed with the
rest):* the swapped-in body's footprint is no wider than the one it replaces.

**What is in flight.** Draft #1169 holds `Planned.is_door()` and is being redesigned to this plan;
its description becomes the revised design before anything more is built, and it deletes the
covering-set path no catalogue row reaches (`dead-code-sweep.md`).

**Measured** with the placement fingerprint and day 13 on the six probe seeds (4242, 90210, 1234567,
7, 31337, 2024), before and after.
