**A fence carried into the next days keeps two calm areas on the route tree**
([2026-09-26-brisk-heron](../../playtests/2026-09-26-brisk-heron.md), statements 2–5: "plan the
fix but we need to focus on other tasks right now"; built after M223, the open PRs'
conversion and M225). PR #374's post-merge review
(https://github.com/JosuaKrause/nappy/pull/374#pullrequestreview-5327317363) found that on
days 10–11 `ClosurePlanner.calm_to_shut()` runs after `CityMap.repaint()` has reset
`fenced_park`, so it counts the fenced area as open and its ground as walkable, and the tree
can keep one calm area against `MIN_CALM_AREAS_REACHABLE` (2); seed 14965, day 10, is one.
The plan: the carried fence is known (excluded, its ground blocked) before `calm_to_shut()`
judges anything, with a regression carrying a day-9 fence into days 10–11 across seeds
14040+37·i that fails before the fix; M24's sentence in `EVENTS.md` restored word for word
("Nothing lethal or mobile is ever chosen for this, and nothing whose body would close the
lot", which that PR rewrote without *mobile*), and `CITY.md`'s spoiler bullet and the word
"spoiling" restored; the rejected broad post (`art/closures/barrier_post.svg`, reached only
through a dead `ClosureMarker.POST` path) leaving the atlas for the rejected-graphics
archive; and the stale lines the review names in `CITY.md`, `ParkClosure`'s class doc, the
zero-cost probe's doc and the evidence README fixed. Branch `fix/spent-park-followup` holds
only an unrun start of that regression in `tests/test_spent_park.gd`. With it,
`CITY.md` states that a day's path ends in an available calm area ("a path should end in an
available calm zone"), which is why the tree refuses a branch ending at a used area; the
night escape's repaint dropping a fence chosen on day 13 or 14 stays ("night escape doesn't
need a fence in a park"); M129's queue title and record stop saying the park "is closed",
and the "Amber otter" records in `DECISIONS.md` are renamed after M129.
