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
wrote each line, and the player ruled only on the cases it could not settle (curly-rabbit #1086,
#1100, #1102), which the builds that owned them applied. So a builder checks each
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
whether its fixed seed ever does needs a run; `test_route_rig.gd` says its checks hold on seeds 4
and 5 and fail on 1 to 3, and which checks are seed-bound needs a run; `test_events_placement.gd:194-200`'s
share floors (0.35 and 0.36) were measured on one city, and asserting the relationship over several
seeds may replace them; `test_ground_layers.gd:103-145` compares literal tables to the manifest,
and deriving the expected rotation from `GroundTiles` may replace them rather than deleting them;
`test_siting_judges_once.gd`'s `_test_the_director_drops_the_verdicts` may duplicate
`_test_a_dropped_verdict_is_judged_again`; `test_scene_recipe_task.gd`'s checks of the authored
scene-recipe files (`272-297`, `303-318`, `343-348`) exercise no game code and may belong in the
recipe validator; `test_walk_siting_spec.gd:90` greps `events_ahead.gd`'s text, a lint rather than
a test; `test_events_costs.gd:553` (`spoiled_days >= 10` of 13) may be seed-sensitive.

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

**`routes_closures_rig.gd`**

- `routes_closures_rig.gd:299`, `:313`, `:314` (in `case_closures_land_where_a_wall_belongs`) | "closures landed on a turning off the corridor" (> 0.5), "landed in one of them" (gap_share > 0.15), "most of the rim is still ordinary ground" (< 0.7) | restates a design decision | Share thresholds over a fixed seed set; the comments call 0.5 "a floor with room in it rather than a measurement" and the 0.15/0.7 band the quota's instruction. They go red when `CLOSURE_GAP_BIAS` or the quota is retuned, not when a wall stops landing off the corridor (the per-closure check on 288 holds that). | medium

**`test_barrier_stays.gd`**

- `test_barrier_stays.gd:192-214` (`_test_the_barrier_costs_nothing_while_he_walks_away`, whole function) and `:139` (`current_intensity() == 0.0`) | "the barrier costs nothing beside it on any leaving frame" / "nor after it, as a roadblock's band never does" | duplicate | `finale_rig.gd:525-592` (`_test_a_roadblock_band_costs_nothing`) walks the same roadblock through posted, warning, charging, walking away, gone and streamed back, and asserts `strongest == 0.0` on every frame including the leaving ones; its 531 check asserts the row's intensity is 0.0. The two suites test the same behavior of the same component (`excitement.contribution_at` on a roadblock band). | medium

**`test_bollards.gd`**

- `test_bollards.gd:46` | "and that circle is 4.8px" (`post.shape.radius == 12.0 * 0.4`) | restates a design decision | The literal radius restated; line 44 already asserts the body's circle equals the radius the shadow is drawn from, which is the relationship that matters. | high

**`test_car_views.gd`**

- test_car_views.gd:53-58 `_test_car_view_by_sector_matches_the_walker_convention` | "sector %d draws the %s view", "sector %d mirror matches the west-mirror convention" | duplicate + restates a table | See test_event_views.gd:171. | medium
- test_car_views.gd:65-72 `_test_body_and_trim_can_never_disagree`, `body_views.size() == 5` | "the car family has exactly five authored views, body and trim alike" | restates a design decision | The 5 literal; the has-key and distinct-region checks after it are the part with a reason. | medium

**`test_crowd_yields.gd`**

- `test_crowd_yields.gd:181` | `_test_a_row_hands_what_it_stands_as_to_its_move`, its `expected` table (police_patrol, fire_truck, market_stall true; charging_dog, policeman_giving_chase, busker false) | RESTATES | Each row's `stands_as` declaration written out again. The handing-over (a row's declaration reaches its move) is covered by any one row. | medium
- `test_crowd_yields.gd:196` and `:229` | `undeclared.is_empty()` ("every row says what it stands as" / "whether it parks") | DUPLICATE | `EventDef.validate()` (event_def.gd:1197 and :1201) refuses `UNDECLARED` for both fields, and `_test_catalogue_is_fair` (test_events_catalogue.gd:218) calls `validate()` on every row. The function's own comment says so. | high

**`test_generator.gd`**

- `test_generator.gd:286` | `Tuning.CITY_BLOCKS.x % 2 == 1 and .y % 2 == 1` ("the lattice is odd on both axes") and the `home_block == middle` check | RESTATES | Parity of a constant and the home being in the middle block are the design written out. The `home_to_nearest_calm() >= MIN_HOME_TO_PARK_TILES` check in the same loop is a floor and stays. | medium

**`test_give_way.gd`**

- test_give_way.gd:34-37 `_test_the_stop_line_is_a_setback_short` | "the line is the setback short of what it stops for" (`GiveWay.stop_line(100.0) == 100.0 - Tuning.CAR_STOP_LINE_SETBACK`) | cannot fail (tautology) | The assertion is the function's body retyped. The second check (`stop_line(1.0) < 0.0`) is a real edge case and is worth keeping. | medium

**`test_ground_layers.gd`**

- test_ground_layers.gd:114-145 `_test_directional_component_pairs_match_ground_tiles` (with `_check_directional_layers`) | "source %d has its GroundTiles direction and component rotation" | restates a design decision | A literal 22-row table (source id -> component, rotation) compared to the same table in `ground_layers.json`; it never reads `GroundTiles` for the direction it names, so it can go red only when the JSON or the table is edited, and every such edit is made together. If the intent is "the rotated component agrees with the tile's direction", derive the expected rotation from `GroundTiles`; otherwise delete. | medium
- test_ground_layers.gd:103-108 (in `_test_damage_pools_are_shared_without_changing_source_semantics`) | "damage source %d retains its authored severity and A/B gameplay slot" | restates a design decision | Hand-written severity pattern `[hairline, hairline, cracked, cracked, broken, broken]` per source compared to the manifest's `source_damage_types`; same table restated. | medium

**`test_home_block.gd`**

- `test_home_block.gd:157` | `_test_her_building_is_the_same_across_two_seeds` | DUPLICATE | `_test_every_home_block_building_is_the_same_across_two_seeds` (test_home_block.gd:188) compares floor count, variant, window pictures, scenery residency and roof furniture for all three home-block lots, her lot included. Only `columns()` and the "roof too shallow" explanation are extra. | medium
- `test_home_block.gd:145` | `short_rects.size() == 3` | RESTATES | The count of lots the home block carves into; the equality of the rect lists on the next line is the property. | medium

**`test_orientation.gd`**

- `test_orientation.gd:284` | `layers.size() == 8` ("every layer of screen furniture is built, and nothing extra") | RESTATES | A count of CanvasLayers that changes whenever a screen is added; the transform check that follows over `layers` is the property. | medium

**`test_regions.gd`**

- `test_regions.gd:525` (first check of `_test_wall_crossing_posts_four_guards`) | "a catalogue roadblock still posts two guards (%d)" | restates a design decision | `guard_sides.size() == 2` is the table; the per-wall counts in the loop (`street_walls.size() == per_wall * ...`, `total_guards == 4`) are derived from it and also restate "a wall stands three bodies / four guards" (546, 561). Would go red only on a design change to the crossing's make-up. | medium

**`test_resistance_arrow.gd`**

- `test_resistance_arrow.gd:217` and `:220` | `_test_the_arrow_moves_at_four_tiles_closer` / `_test_the_arrow_does_not_move_at_three_tiles_closer` | RESTATES | Two probes straddling the hysteresis constant (4 tiles) read back as `moves` true/false; they go red when the threshold is retuned, not when switching breaks. `_test_the_arrow_switches_as_another_target_becomes_closer` (test_resistance_arrow.gd:182) is the behaviour. | medium

**`test_resistance_reach_narrow.gd`**

- test_resistance_reach_narrow.gd:97-98 `_test_the_narrow_targets_are_reachable_on_their_day` | "day %d has a narrow resistance target" (`ResistanceSteps.narrow_target_on(day) != null` for days 9, 12, 14) | restates a design decision | Reads which days have a narrow target out of `ResistanceSteps` and then loops over the same three days; goes red only when the table is edited. The skip-branch `continue` it guards is the only thing it does. Medium-low; kept as a guard if the player prefers. | medium

**`test_resistance_replacement.gd`**

- `test_resistance_replacement.gd:100` | `t.check(true, "skipped: the test city has no two alleys close enough to test this")` | cannot fail | An always-true check on the branch where the setup found nothing, so the whole test silently passes on a seed/city where its precondition does not hold. Should fail (or the setup should pick a city that has the alleys). | high

**`test_route_lines.gd`**

- `test_route_lines.gd:34` (`_test_parse_layers_accepts_five_and_still_rejects_four`) | "5 ... is accepted on its own", "1,9,0" -> [1] etc. | duplicate | `DevFlags.parse_layers` is tested in `test_debug_layers.gd:136-146` (`_test_parse_layers_reads_a_comma_list`, `_..._drops_malformed_entries_without_crashing`, the same `"1,9,0" == [1]` case on line 144). The 5-accepted case is the only new one; fold it into that suite. | medium

**`test_route_rig.gd`**

- test_route_rig.gd:24-27 (`RUN_SEED` comment: "these checks hold on seeds 4 and 5 and fail on 1, 2 and 3") | the whole target-resolution and rig-walk group built by `_build_fixture(RUN_SEED)` | cannot fail (true by luck of the seed) | The suite's own comment says the ground the targets resolve to depends on the run seed and the checks fail on three of five seeds, so they hold on the seed picked, not on a property of the code. Not a deletion: say in the finding that a run on seeds 1-3 would show which checks are seed-dependent; I could not tell which ones from reading. | medium

**`test_route_tree.gd`**

- test_route_tree.gd:165 `_test_no_route_runs_along_the_main_road` | `on_the_spine >= 0` ("%d route tiles stood on the main road's own corridor") | cannot fail | A count can not be negative; the comment itself calls it "not a lower bound to defend ... reported". Delete the check (the per-tile `junction_at(tile) != (-1,-1)` assertion inside the loop is the real one, and `_test_a_route_crosses_a_carriageway_only_at_a_junction` carries the non-vacuity guard). | high

**`test_routes_lattice.gd`**

- `test_routes_lattice.gd:36` | `_test_the_lattice_is_the_lattice`: `junction_count() == CITY_BLOCKS + ONE`, `segments().size() == expected`, each segment `rect.size == (BLOCK_SIZE, STREET_WIDTH)` | RESTATES | The lattice's own definition computed a second time from the same constants (the same reason `test_generator.gd:148`'s comment gives for not restating `period()`/`block_rect()`). The per-street "every tile is walkable" check beside it is real. | high

**`test_scene_recipe_task.gd`**

- `test_scene_recipe_task.gd:272-297` (`_test_the_task_scenes_start_off_an_unread_mark`, whole function), `:303-318` (`_test_the_door_scenes_show_the_robber_a_done_task_sends`, whole function), `:343-348` (last check of `_test_an_authored_mast_carries_its_own_id`) | "%s starts off the mark" / "%s lists the street the robber starts on" / "the two-mast scene stands two masts under two ids" | restates a design decision | These load the authored `scene-recipes/*.json` files and assert facts about their contents (the start anchor is not the mark, an observation is at tick 1, `draft.include` is non-empty). No game code is exercised; they are red only when a recipe file is edited, and the second says in its own comment that the headless scene play (`tools/scene-recipes.sh`) answers the question and this "keeps either from being dropped". That is a lint of authored data, not a behavior. Could move into the recipe validator (`SceneRecipeRuntime.validate_runtime`) if the rule is wanted. | medium

**`test_seals.gd`**

- `test_seals.gd:397-401` | "disconnected alleys are sealed at about the configured rate", "...the exception now, not the rule" (`rate < ALLEY_MOUTH_SEAL_CHANCE + 0.15`, `rate < 0.5`) | restates a design decision / true by luck of the seed | A statistical upper bound on sampled seeds against a tuning chance. It goes red when the chance is retuned and passes by sample luck otherwise; neither side is a fairness or winnability floor. The `candidates > 0` guard (391) stays | medium

**`test_turns.gd`**

- `test_turns.gd:637` (`_test_a_red_light_still_holds_a_car_that_is_turning`; early returns at 639 and 642) | no check on the two early exits (`if not signals: return`, `if not signals.is_signalled(box): return`) | cannot fail (true by luck of the seed) | If the city has no signals, or the junction is not signalled, the test returns without a check, so it passes having tested nothing. A guard such as `t.check(signals != null and signals.is_signalled(box), ...)` is what it lacks; a run would show whether the standard seed always signals it. | medium

**`test_walker_views.gd`**

- `test_walker_views.gd:106-107`, `:148-151` | "sector %d mirror matches the west-mirror convention", "sector %d draws the %s view" (`EXPECTED_MIRRORED`, `EXPECTED_VIEW`) | restates a design decision | The test's own copy of the sector-to-view and mirror tables, compared to `WalkerLook`'s tables. Changing the art convention means editing both. The behavioural checks in this file (hysteresis, wrap, stopped walker keeps its view, placement resets view) stay | medium
- `test_walker_views.gd:162`, `:320`, `:323` | "exactly five authored views", "gait-b body %s is native 18x38" | restates a design decision | Counts and pixel sizes of authored art; the same facts the atlas suites (`test_atlas_library.gd` membership/regions) and the bake already enforce, and they go red only when an art spec is changed on purpose. Keep the checks that a gait-b entry exists and is baked (303-315) | medium
