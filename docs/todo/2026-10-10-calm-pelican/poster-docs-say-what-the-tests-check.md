# The poster docs and tests say what they check

**Low · from the re-review of PR #585 (merry-elk, more posters, from the first day they appear).**
- `docs/CITY.md` and `src/city/poster_walls.gd` say a poster is "in view along most of every
  route", but `tests/test_posters.gd` pools every cell of every route into one share (at least 45%),
  and the PR's own probe had a day-4 route passing 2 sheets. Reword both, or check each route.
- In `tests/test_posters.gd`, "reverting them fails the check" is false (`LAST_DAY_ROUTE_FLOOR`
  passes at the old rates), and the message "denser every act" is not what is checked (days
  non-decreasing, day 14 above twice day 4). Call the day-14 floor a guard, and drop "denser every
  act" or check it.
- `docs/EVENTS.md` says a poster crew "papers most of its wall"; a crew pastes two to four sheets of
  an eight-cell wall.
- `src/city/poster_walls.gd`'s header points at "`docs/TODO.md`'s M180", which does not exist;
  point at the poster paragraph in `docs/CITY.md`.
