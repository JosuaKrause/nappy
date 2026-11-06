# Tests that hold nothing: the audit's findings, removed by the builds that own their files

**The ask.** Told that a check went because no game path lowers resistance progress (its setup
called a function only that test called), the player: "that was a completely pointless test to
begin with", "good that it's gone", then "can we audit tests for those kind of useless ones and
remove them?", and, quoting back the four kinds the audit looks for, "let's make sure those tests
also won't enter the codebase again" (curly-rabbit #1097). The four kinds, in the orchestrator's
words that the player quoted back: a state only the test can create (input the game does not control, such as a corrupted save
on disk or a browser's answer, does not count, since it can really happen); a design decision read
back, a check that goes red only because a number changed, not because what the number is for
broke; a check that cannot fail, that would pass with the code deleted or checks a value it just
set itself; and a duplicate of the same behavior another suite already tests.

**Read as:** the checks of those four kinds are removed. **The findings below are the audit's, not
the player's:** seven read-only agents of the orchestrator's read every suite on 2026-11-05 and
wrote each line, and the player ruled on the cases the audit could not settle (curly-rabbit #1086, #1100, #1102), and the builds
that own those suites applied each ruling. So a builder checks each
finding against the suite before acting on it, removes it if it holds, tightens it where the line
says so (a sweep guard that cannot fail becomes one that can), and keeps it, saying why in its
record, where it does not hold. Keeping the four kinds out from now on is **verify**'s testing policy and the CI check of
test-only members (record minty-quail-gentle-hare).

**Who removes what.** A suite in a remaining build's file list in `tests-unseen-reads.md`, or in
`tests-own-class-members.md`'s pass, has its findings removed by that build, in the same commit as
its other changes, so no file is rewritten twice. Suites no build lists get removal builds of their
own, split by owner when they are briefed; the save, run, telemetry and screen suites are among
them, since their build is done. A line number is `main`'s at the audit; the builder re-reads it,
and a finding whose check is already gone is skipped.

**Open, for the builder to settle by running it, not by reading:** `test_turns.gd:637`, the red
light test, returns with no check if the city has no signals or the junction is not signalled, and
whether its fixed seed ever does needs a run.

**Kept on purpose, not findings:** guards that a sweep was not vacuous, orderings between two
constants, checks that pin a bug that shipped, the run log's `Telemetry.begin_memory_log()` setup
(kept with its reason in `tests-unseen-reads.md`), and the atlas library's accounting, which
`tests-unseen-reads.md` says what is left of.

## The findings, by suite

Each line: where | the check | its kind | why | the audit's confidence.

**`crowd_rig.gd`**

- `crowd_rig.gd:1132-1137` | "there are exactly two precincts in all (%d)", "a precinct is %d blocks long" | duplicate / restates a design decision | Generator facts about the city (precinct count, `PRECINCT_BLOCKS` length), which the city-generator suites own; this rig only needs "a precinct to build a field around", and the next lines take the last span anyway. Suite to compare: the city generator suites (`tests/test_city_*` / `test_routes_*`, not in my group); I did not verify the other suite's line | medium
- crowd_rig.gd:121-134 `_test_walkers_follow_the_selected_presentation` | `not agent.has_node("ModularWalker")` (x2, walker and car) and `walkers > 0 and cars > 0` | cannot fail | `rg ModularWalker src tests` finds only these two lines: no node of that name exists anywhere in `src/`, so the "not has_node" assertions are true with or without the crowd code. The whole function (leftover of a removed presentation mode) holds nothing; the closing both-kinds guard only guards those dead checks. Delete the function. | high
- crowd_rig.gd:2098-2100 `_test_the_arterial_is_the_busiest_street` | "a street's character is stable, not rolled afresh on every question" (`busyness(map,true,arterial) == busyness(map,true,arterial)`) | cannot fail | Compares the same call with the same arguments to itself; passes unless the function is nondeterministic, and it reads no state a roll could change between the two calls. Delete the check (the other two halves of the function are real). | high
- crowd_rig.gd:731-732 `_test_a_bump_costs_and_one_of_them_is_survivable` | "a contact outruns the walking decay, so it is a spike and not a ripple" | duplicate | Same assertion (`Crowd.BUMP_INTENSITY > Tuning.EXCITEMENT_DECAY_WALKING`) as crowd_rig.gd:345-347 in `_test_a_close_pass_costs_and_a_wide_one_does_not`, in the same rig. Keep one. | high
- crowd_rig.gd:2165-2168 `_test_nothing_walks_into_a_hard_blocker` | "and it never happens on any frame (frames_with_one == 0)" | duplicate | `worst == 0` (line 2165) and `frames_with_one == 0` are the same statement over the same loop: the worst count is zero exactly when no frame had one. The second check can never differ from the first. | high

**`finale_rig.gd`**

- `finale_rig.gd:2174-2182` (`_test_finale_entities_stop_when_the_tree_pauses`, whole function) | "the section's clock processes while the tree is running" ... "nor anything in the finale city" | cannot fail | The test sets `process_mode = PROCESS_MODE_PAUSABLE` on the `DayController`, `InteriorScene` and `City` itself (lines 2162, 2166, 2171), then asserts `can_process()` follows `get_tree().paused`. That is Godot's own rule applied to a mode the test just wrote. It would pass with `main._pauses_with_the_game()` (the call that is meant to set the mode, `main.gd:1776`) deleted. The real wiring is only reached by the booted pause tests in this rig (`_test_the_escape_pauses_the_same_way_a_day_does`), which pause a booted `main`. To keep the intent, boot `main` and ask `can_process()` of its nodes; otherwise delete. | high
- `finale_rig.gd:1369-1373` (first check of `_test_the_game_draws_the_escape_from_tunings_bag`) | "the city section's spec holds Tuning's bag and slots" | restates a design decision | Compares `spec.bag` to a dictionary built from the very `DaySpec.FINALE_BAG_*` constants `_city_spec()` is built from, and `slots_per_street` to `FINALE_SLOTS_PER_STREET`. A table read back to itself: red only when a bag count is edited, in which case the test must be edited too. The placement-for-placement comparison below it (1374-1390) is the real check and stays. | high
- `finale_rig.gd:1302-1303` | "and it holds empty marbles" / "and every open street has a slot to draw for" (`FINALE_BAG_EMPTY > 0`, `FINALE_SLOTS_PER_STREET > 0`) | restates a design decision | Two constants compared to zero. The ordering above them (1297-1301) is the player's frequency order and stays; these two say the table has a nonzero entry. The empty-bag and slot-count behaviour is exercised by `_test_every_slot_of_every_street_draws_one_marble` (1323-1360). | medium
- `finale_rig.gd:2358-2359` | "titled with the section's own words ('%s')" (`title_label.text == "Escape the building"`) | duplicate | Identical assertion to the check two lines above it (2356-2357, same `title_label.text == "Escape the building"`). | high
- `finale_rig.gd:2413-2420` (`_test_without_a_route_the_briefs_wait_for_a_person`, whole function) | "with no --route the city's brief waits for a person" | duplicate | Boots a whole `main` on the city section and checks the brief is showing with the title "Escape the city". `_test_each_section_opens_on_its_brief_and_a_loss_on_its_outcome` (1798-1801, section CITY) and `_test_pause_does_not_open_over_a_section_brief_or_the_epilogue` (2277) boot the same state without `--route` and assert the same two facts. Its own comment calls it a parity check. | medium
- `finale_rig.gd:1961-1963` (`_test_the_two_sections_are_named_for_the_player`, the two title checks) | "the building's brief is titled 'Escape the building'" / "'Escape the city'" | duplicate | The same two literals are asserted through the booted brief at 2356, 2418 and 2457. The `number == RUN_LENGTH_DAYS + 1` relation (1964) is not duplicated and stays. | medium
- `finale_rig.gd:605-606` | "a day's hunting roadblock and the escape's are the same row" | duplicate | Same `heated(roadblock, RESISTANCE_GOAL) == escape_roadblock()` assertion as `finale_rig.gd:528`. | medium
- `finale_rig.gd:1703-1704` | "the burst names the crater it leaves" / "and draws nothing itself" | duplicate | `burst.aftermath.on_finish == crater.id` is restated catalogue data, and the wiring half of the same test (1739-1744, a burst run to its end leaves exactly one solid crater) fails if the link is wrong. `look == NONE` is the row read back. | medium
- `finale_rig.gd:2006-2011` (`_test_the_city_word_boots_the_second_section`, whole function) | "'city' is the second section ..." / "a bare flag is still her own door" / "as is anything this does not recognise" | restates a design decision | Three lines of the `escape_part_for()` mapping read back (`"city" -> "city"`, `"" -> "hallway_third"`). The behaviour the mapping exists for is `_test_every_part_word_reaches_its_own_walkable_position` (2015) and the boot tests. Red only when the table is edited. | medium

**`test_barrier_stays.gd`**

- `test_barrier_stays.gd:192-214` (`_test_the_barrier_costs_nothing_while_he_walks_away`, whole function) and `:139` (`current_intensity() == 0.0`) | "the barrier costs nothing beside it on any leaving frame" / "nor after it, as a roadblock's band never does" | duplicate | `finale_rig.gd:525-592` (`_test_a_roadblock_band_costs_nothing`) walks the same roadblock through posted, warning, charging, walking away, gone and streamed back, and asserts `strongest == 0.0` on every frame including the leaving ones; its 531 check asserts the row's intensity is 0.0. The two suites test the same behavior of the same component (`excitement.contribution_at` on a roadblock band). | medium

**`test_route_rig.gd`**

- The rig suite's seed claim, run (record minty-quail-brisk-llama): on seeds 1, 2, 3 and 5 only seed 2 fails, and only two checks, both in `_test_body_clearance_keeps_her_off_the_frontage_beside_a_kerbed_van` ("crosses none of any body's clearance", "no step of the plan past the van..."). Open: why the dev route rig's plan crosses a body's clearance on seed 2, a planner gap in a dev tool or a check that holds by luck.

**`test_route_tree.gd`**

- test_route_tree.gd:165 `_test_no_route_runs_along_the_main_road` | `on_the_spine >= 0` ("%d route tiles stood on the main road's own corridor") | cannot fail | A count can not be negative; the comment itself calls it "not a lower bound to defend ... reported". Delete the check (the per-tile `junction_at(tile) != (-1,-1)` assertion inside the loop is the real one, and `_test_a_route_crosses_a_carriageway_only_at_a_junction` carries the non-vacuity guard). | high

**`test_routes_lattice.gd`**

- `test_routes_lattice.gd:36` | `_test_the_lattice_is_the_lattice`: `junction_count() == CITY_BLOCKS + ONE`, `segments().size() == expected`, each segment `rect.size == (BLOCK_SIZE, STREET_WIDTH)` | RESTATES | The lattice's own definition computed a second time from the same constants (the same reason `test_generator.gd:148`'s comment gives for not restating `period()`/`block_rect()`). The per-street "every tile is walkable" check beside it is real. | high

**`test_seals.gd`**

- `test_seals.gd:397-401` | "disconnected alleys are sealed at about the configured rate", "...the exception now, not the rule" (`rate < ALLEY_MOUTH_SEAL_CHANCE + 0.15`, `rate < 0.5`) | restates a design decision / true by luck of the seed | A statistical upper bound on sampled seeds against a tuning chance. It goes red when the chance is retuned and passes by sample luck otherwise; neither side is a fairness or winnability floor. The `candidates > 0` guard (391) stays | medium

**`test_turns.gd`**

- `test_turns.gd:637` (`_test_a_red_light_still_holds_a_car_that_is_turning`; early returns at 639 and 642) | no check on the two early exits (`if not signals: return`, `if not signals.is_signalled(box): return`) | cannot fail (true by luck of the seed) | If the city has no signals, or the junction is not signalled, the test returns without a check, so it passes having tested nothing. A guard such as `t.check(signals != null and signals.is_signalled(box), ...)` is what it lacks; a run would show whether the standard seed always signals it. | medium
