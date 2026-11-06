# minty-quail — The event and scheduling suites lose the checks that hold nothing · 2026-11-05

minty-quail's `tests-hold-nothing.md`, the audit's findings in the twenty event, scheduling, heat
and tutorial suites no other build owned, under the player's rule that a check whose setup only a
test can make, that reads a design decision back, that cannot fail, or that repeats another, is
removed (curly-rabbit #1097), and the player's rulings on three cases the audit could not settle:
the day-3 dog keeps "the measured half" and the rings check is to "remove" (curly-rabbit #1100),
and of the stairwell masked man "the only case that really counts is not running at all"
(curly-rabbit #1086).

**Built.** The checks the audit found holding nothing went from `test_acts`, `test_checkpoints`,
`test_danger`, `test_events_catalogue`, `test_events_costs`, `test_events_emission`,
`test_events_placement`, `test_events_pursuit`, `test_events_scenery`, `test_events_scheduler`,
`test_halo`, `test_heat`, `test_interior_masked_man`, `test_pelican`, `test_return_patrols`,
`test_siting_judges_once`, `test_texts_catalogue`, `test_tuning_fairness` and `test_tutorial_dog`;
the pull request's description has each suite's count before and after and what each difference
is. The rulings: the day-3 dog's measured chase timings stay and the half that typed its catalogue
row again goes; `_test_the_rings_are_gone` goes; the masked man's walker lines (caught) and runner
lines (through) stay, the late start pinned as caught at 16 ticks goes with the `run-late` pace
only it used in `tests/masked_man_meeting.gd`, and his closest approach is held to
`closest > MASKED_PURSUER_CATCH` rather than to 36.4 px, which the catalogue's comment on him no
longer quotes.

**Tightened.** `test_walk_siting_spec`'s source scan of the places that build a walk siting is the
only guard on two sitings no test can watch, so it stays, from `builds == 4` to `builds > 0`. The
heat suite's "the raid is still only on day 10" became a relation, heat the same hot and cold on
every day 1 to 14. The placement suite asserts the lethal reach on every `hard_fail` row, with a
guard that the rows exist.

**Settled by running.** `spoiled_days >= 10` of 13 is 13 of 13 on four cities, so it stays. The
placement suite's share floors (0.35 and 0.36) fail on two of four other cities, so they went and
the upper bound stays. `lethal_days >= 0` cannot become `> 0`: every lethal row placed on days 1 to
14 is a wall, and walls are exempt, so the whole lethal-field sweep checked nothing and went, the
`keeps_its_field_clear` unit cases staying. `_test_the_director_drops_the_verdicts` is not a
duplicate of `_test_a_dropped_verdict_is_judged_again`: one watches the director's wiring, the
other the siting's effect.

**Open to overturn.** With the share floors gone nothing asserts that the corridor weight lifts the
share; a relation would need a per-city measure of corridor ground. Removing the lethal-field sweep
rather than seeding a day where it can fail. The heat relation in place of a plain delete.
