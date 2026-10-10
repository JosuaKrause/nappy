# A place marble that cannot be sited never blocks the route events behind it

**Medium · from the re-review of PR #565 (olive-badger, what she meets on her route is drawn from a
marble bag).** `EventDirector.due()` (`src/events/event_director.gd`) returns
`_place_on_her_route(next, …)`, whose `if not sited: _next_in = 1.0; return []` branch leaves a
place marble (day 6's man shouting, day 11's second mast) at the head of the queue and retries it
every second. Until it finds a spot, no cat, cyclist, loose dog or return patrol comes, and each
retry reruns the full-branch search the `ON_HER_WAY_LOOK` comment warns about. Refusal is ordinary:
she is off the day's routes, or walking home within about 900px of where the branch ends.

The case, day 11: she reads the mark and the mast's rigged bag of 2 goes in front; the baby falls
asleep and the return's patrol bag goes in front, its second marble taken from the mast's bag, so
it can be the mast; if the mast comes up near home, the patrols never come.

Fix: when a place marble is drawn, spend its queue slot and add an unplaced plan to the on-her-way
list, sited on its own cadence as the day-3 fire is — or let a failed siting step aside for the next
marble; say which in the PR. Test: a place marble that cannot be sited, and later route events and a
return patrol still come.

**Low, same area:** `MarbleBag._take()` (`src/city/marble_bag.gd`) refills an empty queue at most
once (`if filled or _ordinary.is_empty(): break`) while its comment says one more bag may be filled
after the first, so `rig(ensured, size)` with `size - 1` above the ordinary set gives a smaller
rigged bag than asked. No route rig hits it today. Count fills, or make both comments say one fill.
