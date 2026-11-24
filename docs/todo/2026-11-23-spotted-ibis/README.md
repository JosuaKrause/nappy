priority: later

# spotted-ibis — No test holds that the day hands the run's remembered fence and its act to the map · filed 2026-11-23

**What is wrong.** `DayDirector` (`src/run/day_director.gd`, where it dresses the city for the day) hands the map the run's remembered fenced park and the act it was chosen in with `_city_map.set_fenced_park_state(_facts.fenced_park(), _facts.fenced_park_act(), calendar.current_act())`, and after the repaint remembers the first choice with `_facts.remember_fenced_park(...)`. `tests/test_day_director.gd`'s `_FakeMap.set_fenced_park_state()` ignores all three arguments (it only sets `handed_spent := true`), so a director that handed the map the wrong block, the wrong act or the current act in place of the remembered one would pass. A filing from a review, not from the player's words; the band, `later`, is the filer's proposal.

**Found by** pull request 1688's review.

**What a builder does.** Make the fake map record the three arguments, and add the cases: a run that remembers a fence and its act sees both arrive with today's act, and a run that remembers none sees the no-fence values arrive and the first choice remembered afterwards. A recording map is the plain way (**writing-tests**: mock every other real object).

**Shown fixed.** Breaking the argument order or handing `calendar.current_act()` for the remembered act in `day_director.gd` fails the new check.
