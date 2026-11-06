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
wrote each line, and the player has ruled only on the four cases next. So a builder checks each
finding against the suite before acting on it, removes it if it holds, tightens it where the line
says so (a sweep guard that cannot fail becomes one that can), and keeps it, saying why in its
record, where it does not hold. Keeping the four kinds out from now on is `tests-kept-out.md`.

**The player's rulings on the four cases the audit could not settle** (curly-rabbit #1100, #1102):

- The day-3 dog's chase test (`test_events_pursuit.gd`, `_test_the_day_3_dog_keeps_its_gold_timing`):
  "the measured half" stays, the chase timed on real frames as she walks into the dog and the
  warning being the half-second badge; the half that types the dog's catalogue row again (the
  half-second badge, the 4.5 s approach, 130 px/s) goes.
- The danger test's check that the old warning rings stay deleted (`test_danger.gd`,
  `_test_the_rings_are_gone`): "remove".
- The pause screen's wording checks (`test_pause.gd`): of the pick to remove the wording checks and
  keep the ones that a hint is or is not shown, "agreed".
- The visit counter's table of the chargers' GoatCounter names (`test_visit_counter.gd`,
  `_test_every_charger_has_its_own_counter`): told it does not touch the live service (a recording
  counter lists the names and nothing is sent) and that the names are what the GoatCounter
  dashboards count, "let's keep the table" (curly-rabbit #1102).

**The stairwell masked man** (curly-rabbit #1086): "the only case that really counts is not running
at all. running 0.3s late and still succeeding is actually good". Record minty-quail-breezy-pelican
left the two pins below open to overturn on this answer. **Read as:** in
`test_interior_masked_man.gd`, the checks that she is caught when she does not run (the walker
lines) and gets through when she runs stay; the late start pinned as caught at 16 ticks goes, and
his closest approach pinned to 36.4 px is tightened to the contract the same condition already
holds, `closest > MASKED_PURSUER_CATCH`, as the finding below says.

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

**`test_acts.gd`**

- `test_acts.gd:330` and `:335` | "act %d has its own cast", "act III is cooler than act I" | restates a design decision | Palette tints per act are colour/look, which verify's policy says is checked by eye ("Not tested: layout, colour"). Goes red only when the palette is retuned. Line 330 (all four tints distinct) is the milder case | medium

**`test_baby_world.gd`**

- `test_baby_world.gd:40` (`_test_a_baby_answers_for_the_world_she_is_handed`, checks at 44 and 46) | "set_world() is the world she then reads" / "and a null world is a world taken away" | cannot fail | Sets a world on a `Baby` and asserts `world()` hands back the value the test just set; a plain setter/getter pair. The real handing (`main` calling `_baby.set_world(map.world)`) is already checked from a boot by `_test_the_escape_hands_her_the_building_then_the_city` (line 50) and `_test_an_ordinary_boot_hands_her_the_city` (line 143). | high

**`test_barrier_stays.gd`**

- `test_barrier_stays.gd:192-214` (`_test_the_barrier_costs_nothing_while_he_walks_away`, whole function) and `:139` (`current_intensity() == 0.0`) | "the barrier costs nothing beside it on any leaving frame" / "nor after it, as a roadblock's band never does" | duplicate | `finale_rig.gd:525-592` (`_test_a_roadblock_band_costs_nothing`) walks the same roadblock through posted, warning, charging, walking away, gone and streamed back, and asserts `strongest == 0.0` on every frame including the leaving ones; its 531 check asserts the row's intensity is 0.0. The two suites test the same behavior of the same component (`excitement.contribution_at` on a roadblock band). | medium

**`test_blackout.gd`**

- test_blackout.gd:280-283 `_test_the_dark_spine_is_crossed_on_the_horn` | "the horn %.2fs covers the spine's %.0fpx of carriageway doubled" (`CAR_HORN_TIME >= required_horn_time()`) | duplicate | Exactly the first check of `_test_the_traffic_contract_is_fair` in tests/crowd_rig.gd:514. It builds no city, darkens nothing and reads nothing about the blackout, so it cannot fail for any blackout reason. The whole function is the finding; delete it. | high
- test_blackout.gd:370 and 374 `_test_the_building_is_dark_too` | `stairs.r > stairs.g * 2.0` and `hallway.get_luminance() < 0.6` | restates a design decision | Colour numbers read back from `Palette` ("not tested, checked by eye: colour"); they go red when the palette is retuned, not when lighting selection breaks. The part-by-part equality checks (`== Palette.ESCAPE_GLOOM`, `== ESCAPE_EMERGENCY_RED`, basement darker than hallway, flash lifts hallway but not stairs) are the real ones. | medium

**`test_bollards.gd`**

- `test_bollards.gd:46` | "and that circle is 4.8px" (`post.shape.radius == 12.0 * 0.4`) | restates a design decision | The literal radius restated; line 44 already asserts the body's circle equals the radius the shadow is drawn from, which is the relationship that matters. | high

**`test_burst_capture.gd`**

- `test_burst_capture.gd:302-303` | "the frame cap ends a sequence at its thirty-sixth frame, and a thirty-seventh is never drawn in" | restates a design decision | `_frames_until_the_end(2.9) == ["frame_cap", 36]` and the helper's `frame-0037.png` hard-code `BurstRecorder.MAX_FRAMES` (36) as literals, while the helper's loop uses `MAX_FRAMES`. Red only when the cap is retuned. Compare against `MAX_FRAMES` and `MAX_FRAMES + 1`. | medium

**`test_car_views.gd`**

- test_car_views.gd:53-58 `_test_car_view_by_sector_matches_the_walker_convention` | "sector %d draws the %s view", "sector %d mirror matches the west-mirror convention" | duplicate + restates a table | See test_event_views.gd:171. | medium
- test_car_views.gd:65-72 `_test_body_and_trim_can_never_disagree`, `body_views.size() == 5` | "the car family has exactly five authored views, body and trim alike" | restates a design decision | The 5 literal; the has-key and distinct-region checks after it are the part with a reason. | medium

**`test_checkpoints.gd`**

- `test_checkpoints.gd:1784` (in `_test_the_boom_never_inspects_her`) | "checkpoint_gate carries no detention of its own" (`not gate.def.redetains and gate.def.detain_seconds <= 0.0`) | restates a design decision | Table row read back; the behaviour (a boom body never starts a hold, lines 1798-1802) is asserted right after it. | medium
- `test_checkpoints.gd:1677` | "chatting_mother does not redetain" (`not def.redetains`) | restates a design decision | Same shape; the one-conversation behaviour is checked on 1684-1693. | medium

**`test_crowd_yields.gd`**

- `test_crowd_yields.gd:181` | `_test_a_row_hands_what_it_stands_as_to_its_move`, its `expected` table (police_patrol, fire_truck, market_stall true; charging_dog, policeman_giving_chase, busker false) | RESTATES | Each row's `stands_as` declaration written out again. The handing-over (a row's declaration reaches its move) is covered by any one row. | medium
- `test_crowd_yields.gd:196` and `:229` | `undeclared.is_empty()` ("every row says what it stands as" / "whether it parks") | DUPLICATE | `EventDef.validate()` (event_def.gd:1197 and :1201) refuses `UNDECLARED` for both fields, and `_test_catalogue_is_fair` (test_events_catalogue.gd:218) calls `validate()` on every row. The function's own comment says so. | high

**`test_danger.gd`**

- `test_danger.gd:55` | `_test_the_rings_are_gone` (`ResourceLoader.exists(event_aura_layer.gd)` false, `ClassDB.class_exists("EventAuraLayer")` false, `City` has no `add_aura_layer`) | RESTATES | A standing decision (no rings) turned into a check that three deleted names stay deleted. It goes red only when someone re-adds those exact names, and passes if they draw a ring under any other name. The comment states it is deliberate, so the player may want to keep it; listed because it holds no behaviour. | medium

**`test_day_controller.gd`**

- test_day_controller.gd:204-212 `_test_an_escape_section_reads_its_clock_to_the_hundredth` | "escape section %d's clock reads to the hundredth", "a day's clock does not", "nor does a DayController handed no spec" | restates a design decision | Reads the `clock_hundredths` flag of three `DaySpec`s back; the behaviour the flag is for (the escape clock emitting every frame) is covered by `_test_the_escape_clock_moves_every_frame` (:114) and `_test_a_drawn_frame_shows_the_escape_clock_between_ticks` (:153). | medium

**`test_day_loop.gd`**

- `test_day_loop.gd:303-306` | "resistance progress never goes negative" | unreachable setup | Already dropped by PR #1096 (setup is `RunState.penalise_resistance`, called by no game path). Listed so the owning build does not lose it | high
- `test_day_loop.gd:371-372` and `:386-388` | "nothing is remembered yet on day 1" / "and tomorrow is the day that reads it" (`run.calendar.settled_yesterday()`) | unreachable setup (dead API) | `RunCalendar.settled_yesterday()` (run_calendar.gd:66) has no caller in `src/`; the game reads `settled_this_act()` instead. The test asserts a function no game path calls, and its message ("the day that reads it") is false. The neighbouring checks on `run.settled.settled_in` (373, 383) hold the real behaviour and stay. Searched `rg settled_yesterday src` and found only the definition | high

**`test_event_behaviours.gd`**

- `test_event_behaviours.gd:54` (`_test_a_row_is_composed_of_what_its_data_says`) | "a pursuer chases and has a man's stop...", "a mother holds her and does not chase", "the unmarked van takes a bystander..." | restates a design decision | Asserts which behaviour objects each catalogue row's data produces (`robber.pursuit != null`, `mother.hold != null`, ...). That is the catalogue table read back through the constructor; every behaviour round-trip test below it would go red if a row lost its behaviour. | medium

**`test_event_views.gd`**

- test_event_views.gd:171-176 `_test_eight_view_by_sector_matches_convention` | "sector %d names the %s view", "sector %d mirrors according to the west convention" | duplicate + restates a table | Same two assertions as test_car_views.gd:53-58 (`CarLook.VIEW_BY_SECTOR` vs `EXPECTED_VIEW`, `EightDirection.is_mirrored` vs `EXPECTED_MIRRORED`); `EightDirection.is_mirrored` is tested twice, and each is a table compared to its retyped copy. `_test_select_view_holds_and_mirrors` (:181) tests the behaviour. | medium
- test_event_views.gd:434-440 `_test_family_dictionaries_are_complete` first check | "%s carries exactly five authored views" (`by_view.size() == 5`) | restates a design decision | The literal 5 is the view count restated; the per-view `has(view) and != null` check beneath it is the real completeness check. | medium
- test_event_views.gd:442-455 `_test_animal_side_view_reuses_the_canonical_source`, `_test_vehicle_side_view_reuses_the_canonical_source` | "%s's side view is the same picture as its existing canonical source" | restates a design decision | `ANIMAL_SIDE_REUSE`/`VEHICLE_SIDE_REUSE` are the test's own copy of which constant each family reuses; red only if someone repoints a picture on purpose. | medium
- test_event_views.gd:961-978 `_test_riot_van_reproduces_its_octant_table_with_the_corrected_side_mirror` | "sector %d draws the same texture the hand-written match once did" | restates a design decision | A literal transcription of the van's table (`RIOT_VAN_OCTANT_TEXTURE`, `RIOT_VAN_OCTANT_MIRROR`); `_test_vehicle_views_match_facings_csv_per_sector` makes the same per-sector texture-and-mirror check from `facings.csv` for the other vehicles. Medium because the comment frames it as protection against edits to the shared table, which is a "you changed a table" failure. | medium

**`test_events_catalogue.gd`**

- `test_events_catalogue.gd:104` | `_test_what_a_picture_once_decided_is_row_data` ("%s is set on %s and nothing else", the dog/robber `warning_picture` line, the policeman/guardsman `noun`/`noun_plural` line) | RESTATES | Lists which catalogue rows carry which flag, which warning picture and which noun strings. It is the catalogue table copied into the test; it goes red only when a row is edited on purpose, and then the test is edited with it. Nothing it names can break without the row being changed. | high
- `test_events_catalogue.gd:315` | `quiet == ["alley_mouse", "cat_dash", "loose_dog", "pigeon_flock", "police_patrol"]` ("these are the rows that do not telegraph, every other row does") | RESTATES | A list of which rows have `telegraphs == false`, written out. The relation worth keeping is the lines above it (a non-telegraphing row still clears the in-world contract; the fire engine keeps its badge); the exact membership list only changes when a row's flag is edited. | medium
- `test_events_catalogue.gd:807` | `several == 1` ("exactly one row in the catalogue is solid in parts ... a second is a decision") | RESTATES | The message says it: it goes red only when someone adds a second multi-part row, a decision, not a break. The per-row `parts().size() == 1` and `solid_reach == obstructs_radius` checks beside it are the relation and stay. | medium
- `test_events_catalogue.gd:864` | `_test_the_street_fire_costs_nothing_but_the_indoor_one_still_does` (`street.intensity <= 0.0`, `obstructs_radius <= 0.0`, `indoors.intensity > 0.0`, `indoors.pulse_period > 0.0`, `draws_body_shadow`) | RESTATES | Reads the `burning_building` row's fields and its `building_fire()` copy back. Same shape as the row-data test above; the comment cites a player statement but no shipped defect (contrast the next function, `_test_a_row_drawn_on_a_building_stands_nothing_on_the_sidewalk`, which names the invisible-body-in-front-of-the-burnt-building bug and stays). | medium

**`test_events_costs.gd`**

- `test_events_costs.gd:454` | "and the rest are checked (%d)" (`lethal_days >= 0`) | cannot fail | `lethal_days` is a counter that only counts up from 0, so `>= 0` is always true. The comment above it says the line guards against a day with no lethal rows (vacuous sweep); it should be `> 0`, as the line before it does for `exempt`. Fix is to make it `> 0`, not delete (the guard is wanted) | high
- `test_events_costs.gd:179` | "and there is exactly one of them (%d): a second is a decision somebody takes" (`_RUNNING_IS_CHEAPER.size() == 1`) | restates a design decision | Goes red only when somebody adds a second running-exemption row, i.e. a number/table was changed on purpose; it does not say the contract broke. It checks the test's own whitelist constant against a literal | medium
- `test_events_costs.gd:372` and `:375` | "day 1 averages enough dog walkers ... / cafés" (`>= seeds.size() * 7`, `* 5`) | restates a design decision | Density quotas for two rows (the balance skill's domain); red only when density tuning moves, not when a route got worse. The relation to a floor the player needs ("meet two on a route") is in the message only | medium

**`test_events_emission.gd`**

- `test_events_emission.gd:134` (`_test_no_other_rows_field_moved`, checks at 143 and 146) | "'%s' emits what a plain field emits at %.0fpx" / "damps to what a plain field damps to" | cannot fail (restates the implementation) | `EventDef.emission_at_distance()` (`event_def.gd:1789`) returns `Field.falloff(...)` verbatim when `core_intensity <= 0`; the test compares it to the same `Field.falloff` call, so it is the function's body restated, a refactor-era pin ("adding a second part may not have moved the first"). The falloff itself is covered in the field tests. | medium

**`test_events_placement.gd`**

- test_events_placement.gd:194-200 `_test_the_day_is_placed_by_role` | `share > 0.35`, `narrow_share > 0.36` ("corridor weight still shows through the three rules") | restates a design decision / true by luck of the seed | The floors are the measured 36.92% and 38.20% of one city on five days, and the doc comment says "the sample is one city, so any change to the corridor reshuffles it ... re-measure". They go red when the sample reshuffles, not when the weighting (`EVENT_CORRIDOR_WEIGHT`) breaks. Where the fix is to tighten rather than delete: assert the relationship the weight is for (on-corridor share of friction beats the share of ground that is corridor, about a third) over several seeds instead of a measured floor. | medium
- test_events_placement.gd:977 `_test_a_flock_is_scenery` | "the flock def is marked scenery" (`def.role == SCENERY`) | restates a design decision | Reads a catalogue field back; the behavior is the next check (`plan.role == NONE` for every placed flock, line 991), which fails if the exemption breaks. | medium
- test_events_placement.gd:1007 `_test_a_lethal_rows_line_reach_is_its_whole_field` | "the reversing lorry is a lethal row" (`lorry.hard_fail`) | restates a design decision | Pins a catalogue flag; if the lorry stops being lethal the function's second check is then about a non-lethal row and says nothing. Better: pick the lethal rows from the catalogue (`def.hard_fail`) and assert the reach on each. | medium

**`test_events_pursuit.gd`**

- test_events_pursuit.gd:260 and :262 (`_test_the_robbers_lunge_is_further_out_than_his_catch`) | "'%s' catches at 26px" / "'%s' lunges from 116px" | restates a design decision | `close_to(def.lethal_reach(), 26.0)` and `close_to(standoff, 116.0)` go red only when the catalogue's numbers are changed; the reason these numbers matter is already asserted in the same function by `lunge_is_inside_the_catch()` (264) and the predicate cases at 276-280. Keep 264-280, drop the two literals. | medium
- test_events_pursuit.gd:718-724, :729-730 (`_test_the_day_3_dog_keeps_its_gold_timing`) | "the day-3 dog's badge alone is half a second", "its approach is 4.5s", "at 130px/s", and the per-answer chase table 0.35/0.60/2.05/3.95 | restates a design decision | Literal restatement of `charging_dog`'s row (`offscreen_notice`, `telegraph_time`, `chase_speed()`) and of the walked timings. The docstring cites the player calling this timing gold (PLAYTEST-145), so this may be wanted as a deliberate freeze; flagged because it fails on "you changed a number", not on a broken contract. If kept, say so in the verify skill's list of deliberate freezes. The walked checks `met["caught"]` and "running escapes" (741, 747) are the part that tests the thing. | medium
- test_events_pursuit.gd:908-910 (`_test_a_paced_event_walks_a_beat`) | "the man shouting walks a beat", "and has no body, because a moving wall pins her" | restates a design decision | `def.paces and def.mobile` and `def.obstructs_radius <= 0.0` read the `homeless_yeller` row back; the behaviour (beat walked, not finished, not leaving) is asserted below at 916-927. | medium

**`test_events_scenery.gd`**

- test_events_scenery.gd:134 `_test_a_flock_is_birds_rather_than_one_bird_drawn_often` | `rim >= 0.0 and contribution_at(outer_radius + 80) == 0.0` | cannot fail (first half) | A source's contribution at a point cannot be negative, so `rim >= 0.0` is always true; only the `== 0.0` half asserts anything. Tighten to the second half alone. | high
- test_events_scenery.gd:96 | "a flock is more than one body" (`flock_size > 1 and flock_spread > 0.0`) | restates a design decision | Reads two catalogue numbers back; the movement and containment checks right after it fail if the flock is one body. | medium
- test_events_scenery.gd:316 `_test_a_crouching_event_holds_still_until_it_bolts` | "the cat crouches rather than creeping" (`def.still_while_telegraphing`) | restates a design decision | A catalogue flag read back; the next checks (position unchanged during telegraph, bolts after) are the behavior and fail without it. | medium

**`test_events_scheduler.gd`**

- `test_events_scheduler.gd:560` | "day %d: the game's spec keeps %.2f of the walls" (`spec.wall_row_share == 1.0 if day < REGION_WALL_FIRST_DAY else GATEHOUSE_DAY_WALL_ROW_SHARE`) | restates a design decision | Reads the `DaySpec` table back against the two constants it is built from; the behavioural relation is the next checks (the thinned day is the full day minus walls; share within tolerance), which stay | medium

**`test_fire_truck_body.gd`**

- `test_fire_truck_body.gd:89` | `_test_the_row_is_a_car_with_the_engines_body` (`reach()*2 == 58.0`, `radius*2 == 26.0`, `telegraph_time > 0 and warned_first`, `obstructs_radius == 0.0 and not hard_fail`) | RESTATES | Pixel dimensions of the engine's body and the row's flags, with the SVG coordinates they were copied from in the message. Red only when the row or the art is edited on purpose. `reach() < inner_radius` in the same function is a relation and stays. | high
- `test_fire_truck_body.gd:513` | `_test_a_loss_to_it_names_its_own_cause` (`Texts.HARD_FAIL_TEXT["fire_truck"]` contains "fire engine", differs from the patrol's and the car's; `hard_fail_suffix == "fire-truck"`) | RESTATES | Table lookups in `Texts` and `LossCause` read back; the three strings are not behaviour. | medium

**`test_frame_graph.gd`**

- `test_frame_graph.gd:80` | `_test_a_bars_class_is_fixed_when_it_is_pushed` | CANNOT-FAIL | The comment concedes it: "With the lines fixed the answer could not change anyway". A graph that classed at draw time would give the same `classes()` answers because `classify()` depends on fixed lines only, so the test passes with either implementation. It names a player report but pins nothing that could differ. | medium

**`test_generator.gd`**

- `test_generator.gd:286` | `Tuning.CITY_BLOCKS.x % 2 == 1 and .y % 2 == 1` ("the lattice is odd on both axes") and the `home_block == middle` check | RESTATES | Parity of a constant and the home being in the middle block are the design written out. The `home_to_nearest_calm() >= MIN_HOME_TO_PARK_TILES` check in the same loop is a floor and stays. | medium

**`test_give_way.gd`**

- test_give_way.gd:34-37 `_test_the_stop_line_is_a_setback_short` | "the line is the setback short of what it stops for" (`GiveWay.stop_line(100.0) == 100.0 - Tuning.CAR_STOP_LINE_SETBACK`) | cannot fail (tautology) | The assertion is the function's body retyped. The second check (`stop_line(1.0) < 0.0`) is a real edge case and is worth keeping. | medium

**`test_ground_floor.gd`**

- `test_ground_floor.gd:828` and `:844` (inside `_test_roof_extension_rows_reads_back_per_column` and `_test_extension_is_seamless_reads_back_per_column`) | "column %d: extension_rows() reads roof_extension_rows back exactly" / "extension_is_seamless() reads roof_extension_seamless back exactly" | cannot fail | Assert an accessor returns the field the test just wrote by hand. The out-of-range checks next to them (830-831, 846-847) are real; the per-column read-back loops are not. | medium

**`test_ground_layers.gd`**

- test_ground_layers.gd:114-145 `_test_directional_component_pairs_match_ground_tiles` (with `_check_directional_layers`) | "source %d has its GroundTiles direction and component rotation" | restates a design decision | A literal 22-row table (source id -> component, rotation) compared to the same table in `ground_layers.json`; it never reads `GroundTiles` for the direction it names, so it can go red only when the JSON or the table is edited, and every such edit is made together. If the intent is "the rotated component agrees with the tile's direction", derive the expected rotation from `GroundTiles`; otherwise delete. | medium
- test_ground_layers.gd:103-108 (in `_test_damage_pools_are_shared_without_changing_source_semantics`) | "damage source %d retains its authored severity and A/B gameplay slot" | restates a design decision | Hand-written severity pattern `[hairline, hairline, cracked, cracked, broken, broken]` per source compared to the manifest's `source_damage_types`; same table restated. | medium

**`test_halo.gd`**

- `test_halo.gd:809-813` (inside `_test_the_rims_mirrored_copies_land_on_the_ring`) | "clearing a canvas's transform puts it back to identity" | cannot fail | The test calls `Sprites.set_base_transform(canvas, IDENTITY)` and then asserts `Sprites.base_transform_of(canvas) == IDENTITY`: a value read back after the test wrote it. The 809-810 check (an untouched canvas mirrors about its own anchor) is related and also trivial, but the mirrored-origin checks above it carry the real property. | high
- `test_halo.gd:792-793` | "the ring is the whole of `HALO_OFFSETS` (%d) rather than a subset" | cannot fail | `trace_offsets()` is `for i in HALO_OFFSETS: ring.append(...)`, so `ring.size() == HALO_OFFSETS` is the loop bound. The distinct-landing check (816) and the `HALO_MARGIN` check cover the ring. | medium
- `test_halo.gd:822-826` | "every copy sits exactly HALO_MARGIN out from the bobbing body" | cannot fail | `trace_offsets()` builds each offset as `(0, bob) + unit * HALO_MARGIN`, and the check subtracts `(0, bob)` and measures the length. It is the function's definition applied to its own output, with no mirrored transform involved. | medium
- `test_halo.gd:397-401` | "fifteen points is already solid" / "well past LOW_EMPHASIS_POINTS stays solid" | restates a design decision | `magnitude_for(15.0) == MAX_ALPHA` hard-codes the value of `LOW_EMPHASIS_POINTS` (15.0, `excitement_halo.gd:105`) as a literal. The check on `forty` and the `one < five < fifteen` ordering carry the property; the `fifteen` equality goes red when the constant is retuned. Replace the literal with `LOW_EMPHASIS_POINTS`. | medium

**`test_heat.gd`**

- `test_heat.gd:145-146` and `:150-151` | "the raid is scripted for day 10", "the raid still only ever appears on day 10" (`available_on(10)`) | restates a design decision | The catalogue row's day (and `SCRIPTED` kind) read back; moving the raid day edits the catalogue and this test. Other suites (`test_resistance_placement_kinds.gd:857-883` "only on day 10") hold the behaviour (raid arrives only on day 10) | medium

**`test_home_block.gd`**

- `test_home_block.gd:157` | `_test_her_building_is_the_same_across_two_seeds` | DUPLICATE | `_test_every_home_block_building_is_the_same_across_two_seeds` (test_home_block.gd:188) compares floor count, variant, window pictures, scenery residency and roof furniture for all three home-block lots, her lot included. Only `columns()` and the "roof too shallow" explanation are extra. | medium
- `test_home_block.gd:145` | `short_rects.size() == 3` | RESTATES | The count of lots the home block carves into; the equality of the rect lists on the next line is the property. | medium

**`test_interior_masked_man.gd`**

- test_interior_masked_man.gd:167-171 (inside `_test_she_has_to_run_to_the_first_floor_door`) | "he comes %.1fpx from her centre on the tick (%.1fpx pinned)" (`absf(closest - _TIGHTEST_RUNNER_CLOSEST) < 0.5`, with `_TIGHTEST_RUNNER_CLOSEST := 36.4`) | restates a design decision | A measured figure of the escape's geometry pinned to half a pixel; it goes red on any stairwell, speed or collision tweak even when the margin is still fair. The part that holds the contract is the other half of the same condition, `closest > EventCatalogue.MASKED_PURSUER_CATCH`. Tighten to that inequality (optionally with a minimum margin) and drop the literal. | medium

**`test_loss_cause.gd`**

- test_loss_cause.gd:_test_a_day_lost_to_the_pelican_names_the_pelican, third check "a car is still a car" | `hard_fail_suffix("car_strike") == "car"` | duplicate | Same call, same value as the first check of `_test_hard_fail_cause_suffix` (:21) and again in `_test_the_cause_by_result` (`car_strike` -> "car"). | medium

**`test_main.gd`**

- `test_main.gd:1138` | "the window is 500ms" (`ReturnWindow.IGNORED_MSEC == 500`) | restates a design decision | Reads the constant back against its literal. The behaviour is checked on the next lines (a press inside the window is ignored, the same press after it counts), which uses the constant, so a retune moves both and breaks nothing the player feels. | high

**`test_orientation.gd`**

- `test_orientation.gd:284` | `layers.size() == 8` ("every layer of screen furniture is built, and nothing extra") | RESTATES | A count of CanvasLayers that changes whenever a screen is added; the transform check that follows over `layers` is the property. | medium

**`test_pause.gd`**

- `test_pause.gd:1504-1505` (`_test_the_pause_body_names_the_run_button_in_the_joystick_scheme`, first check) | "tap scheme: the body says double tap to run" | duplicate | `body.line.begins_with("Tap to walk, double tap to run.")` on a freshly opened pause screen is already asserted at 903-904 (`_test_the_pause_hint_and_body_match_the_platform`). Only the joystick-scheme check (1509) is new. | high
- `test_pause.gd:1070` (`_test_a_touch_away_from_restart_still_carries_on`, whole function) | "a touch nowhere near the restart button still carries on" | duplicate | `_test_a_tap_advances_every_screen` (1388-1401) pushes a touch at (0,0), also away from the restart button, onto an open pause and asserts `resumed == 1` and the screen closed. The only difference is the touch position. | medium
- `test_pause.gd:1266-1270` (end of `_test_the_summary_restart_button_is_a_hold`) | "a touch away from the restart button still continues" | duplicate | Same behaviour as `_test_a_tap_advances_every_screen` summary half (1405-1414); only the touch position differs. | medium
- `test_pause.gd:629-640, 647-654, 897-906, 895, 911, 1188, 1195, 1200` | hint/body/caption wording: "press a button to begin", "Tap to walk", "no key is named", "On-screen Controls", "Tap to Go", `hint.text == ""` (five times, pause and summary) | restates a design decision | These assert the literal wording of screen text and that a hint is blank, repeated on three screens. They go red only when the copy is edited. The copy is the player's call (playtest 29 finding 4 and 34 finding 10) but nothing about route choice breaks if the sentence changes; the "no key is named" negatives are the part that carries a rule. Consider keeping the negatives and dropping the positive literals. | medium
- `test_pause.gd:857-867` (`_test_the_title_names_a_version`, the project-setting and commit checks) | "the baked setting TitleScreen falls back to actually exists" / "in the same vMAJOR.MINOR.PATCH shape" / "the commit is git's own answer" / "it is an abbreviated hash" | restates a design decision | `baked != ""`, `begins_with("v")` and `baked_commit != ""` read `project.godot`'s `application/config/*` values, which no code under test writes (the export script bakes them), so they hold or fail with the checked-in settings and not with the code. `commit == BuildInfo.source_commit()` is `commit_text()`'s own definition when git answers. The `commit.length() >= 7` check also depends on running inside a git checkout. The label-equals-`source_version()` check (854) stays. | medium

**`test_pelican.gd`**

- test_pelican.gd:212-229 `_test_the_pelican_never_becomes_a_png` | "every pelican picture has its SVG under art/", "and none has an illustrated PNG beside it" | restates a design decision | Looks on disk for files to decide the art format; red only when someone converts the art on purpose (the illustrated-png and svg-art skills own that rule). It exercises no code. | medium

**`test_performance.gd`**

- `test_performance.gd:100-104` | "draw calls / objects / primitives read without error", "process/physics time reads in milliseconds" (`>= 0`) | cannot fail | `FrameCost.draw_calls()` etc. return engine `Performance` monitors, which are non-negative by type; they pass with the monitor stubbed to 0, and under `--headless` they read 0. The comment says "without error", which a thrown error (SCRIPT ERROR) already reports. Line 105 (`not line(0.0).is_empty()`) is weak for the same reason but ties to the line format; keep 105 | medium

**`test_player_presentation.gd`**

- `test_player_presentation.gd:34` | "the presentation is the run stream's equal two-way draw" | cannot fail (tautology) | Re-derives the expected value with the very same call the code under test makes (`run_rng("player-presentation").randi_range(0, 1) == 1`, `game_state.gd:86`); it can only differ if the stream name is changed in one place. The replay and retain-the-choice checks on lines 41 and 43, and the both-families guard on line 44, are the property. | medium

**`test_police_car.gd`**

- test_police_car.gd:93-109 `_test_the_patrol_is_a_car_at_every_heat` | "police_patrol drives...", "its body is a capsule laid along its heading", "it closes no ground and is no hard fail", "heat %d's patrol is the same car", "a duplicated patrol ... still drives" | restates a design decision | Reads the catalogue row's fields back (`vehicle != null`, `shape.kind == SEGMENT`, `obstructs_radius == 0`, `hard_fail == false`); red only if the row is edited. What the row means is tested by the behaviour tests that follow (stops at her side, solid beside her, lethal in front). | medium
- test_police_car.gd:683-697 `_test_its_caret_stands_over_its_picture` | "its caret clears the picture's bottom by %.1fpx, as on any row" | restates a design decision | `usual` re-derives the caret placement formula from `MARK_HEIGHT`, `MARK_WIDTH`, the swell and `10.0`/`0.55`/`0.45`; a change to the shared caret formula turns it red though nothing about the police car broke. Cues are checked by eye per the testing policy. | medium

**`test_pursuer_on_foot.gd`**

- `test_pursuer_on_foot.gd:124`, `:138`, `:139` (in `_test_the_two_rows_are_the_task_robbers_chase_in_a_uniform`) | "'%s' draws its own look", "'%s' ends the day when he catches her", reach equal | restates a design decision | `def.look == looks[id]` and `def.hard_fail` restate table entries. The relationship checks beside them (`chase_speed`, `offscreen_notice`, `duration` equal to the robber's) stay. | medium
- `test_pursuer_on_foot.gd:363` (`_test_his_catch_ends_the_day_with_its_own_line`, 365) | "'%s' is a hard fail" | restates a design decision | `EventCatalogue.by_id(id).hard_fail` against true; the loss line check on 367 is the behaviour. | medium
- `test_pursuer_on_foot.gd:790` | "'%s' hunts on foot, with two men" (`cold.hunts.lets_out == 2`) | restates a design decision | Count of men per van restated from the row; `_test_a_hunting_van_waits_for_its_men` (833, `officers_owed() == 2`) and the stops-and-lets-men-out test (906) already run the behaviour. | medium

**`test_regions.gd`**

- `test_regions.gd:525` (first check of `_test_wall_crossing_posts_four_guards`) | "a catalogue roadblock still posts two guards (%d)" | restates a design decision | `guard_sides.size() == 2` is the table; the per-wall counts in the loop (`street_walls.size() == per_wall * ...`, `total_guards == 4`) are derived from it and also restate "a wall stands three bodies / four guards" (546, 561). Would go red only on a design change to the crossing's make-up. | medium

**`test_resistance_arrow.gd`**

- `test_resistance_arrow.gd:217` and `:220` | `_test_the_arrow_moves_at_four_tiles_closer` / `_test_the_arrow_does_not_move_at_three_tiles_closer` | RESTATES | Two probes straddling the hysteresis constant (4 tiles) read back as `moves` true/false; they go red when the threshold is retuned, not when switching breaks. `_test_the_arrow_switches_as_another_target_becomes_closer` (test_resistance_arrow.gd:182) is the behaviour. | medium

**`test_resistance_placement_kinds.gd`**

- `test_resistance_placement_kinds.gd:1057-1058` | "the convoys start on day 13" (`convoy.first_day == ResistanceHappenings.COLUMN_DAY`) | cannot fail in practice / restates | Compares a catalogue field with the constant it is assigned from; red only if one is edited without the other, which is a table read back to itself. The behaviour (a column comes on day 13, `1093`) is separately asserted | medium
- `test_resistance_placement_kinds.gd:968-969` | "seed %d: on the third floor" (`neighbor_window_row() == 3`) | restates a design decision | A literal floor number; the contract is that the boarded cell is stable across days and reload (972, 982), which stay | medium

**`test_resistance_reach_narrow.gd`**

- test_resistance_reach_narrow.gd:97-98 `_test_the_narrow_targets_are_reachable_on_their_day` | "day %d has a narrow resistance target" (`ResistanceSteps.narrow_target_on(day) != null` for days 9, 12, 14) | restates a design decision | Reads which days have a narrow target out of `ResistanceSteps` and then loops over the same three days; goes red only when the table is edited. The skip-branch `continue` it guards is the only thing it does. Medium-low; kept as a guard if the player prefers. | medium

**`test_resistance_replacement.gd`**

- `test_resistance_replacement.gd:100` | `t.check(true, "skipped: the test city has no two alleys close enough to test this")` | cannot fail | An always-true check on the branch where the setup found nothing, so the whole test silently passes on a seed/city where its precondition does not hold. Should fail (or the setup should pick a city that has the alleys). | high

**`test_resistance_steps.gd`**

- test_resistance_steps.gd:92-95 (in `_test_day_eights_mark_is_about_as_long_as_the_shortest_other_mark`) | `"burnt building" in day8`, `"stroller" in day8` | restates a design decision | Substring checks on authored copy; they go red when the wording is edited, not when the text stops saying where to go. The length relationship and one-sentence checks are the part with a reason. | medium
- test_resistance_steps.gd:165-170 `_test_the_chalk_mark_pictures_are_baked_on_decoration` | "%s is a baked region", "%s is on the '%s' group" | duplicate | Same region-exists-on-group sweep that test_atlas_leaf_consumers.gd's `_check_regions` makes for every other consumer; the chalk mark could go into that pattern, and the suite is not about atlas membership. | medium

**`test_return_patrols.gd`**

- `test_return_patrols.gd:117-126` (`_test_owed_count_per_act`, whole function) | "day %d (act %d) owes %d return patrol(s)" | restates a design decision | `owed() == EventDirector.RETURN_PATROLS_PER_ACT[act - 1]` reads the table back to itself (the doc comment states `[0, 0, 2, 3]`). `test_tuning_fairness.gd:84-88` already guards the table's shape. The behaviour this table drives is checked by the walking tests below (`_test_each_patrol_comes_within_its_rigged_bag` 229, `_test_a_marble_spent_unmet...` 258). | high
- `test_return_patrols.gd:140` | "the one batch is the whole of act IV's count" | restates a design decision | `once == RETURN_PATROLS_PER_ACT[3]`: the same table read back. The no-second-batch check above it (137) is the real one. | medium

**`test_route_bag.gd`**

- `test_route_bag.gd:133` (`_test_a_spaced_rig_comes_after_its_bag_and_no_sooner`, whole function) | "seed %d: bags of %d, 1 and %d", "the dog is drawn sixth and not before", "...hold the ordinary set exactly" | unreachable setup | `MarbleBag.rig_spaced()` (`src/city/marble_bag.gd:204`) has no caller anywhere in `src/` (only this test and a sentence in `docs/EVENTS.md`); the game rigs only through `MarbleBag.rig()` (`event_director.gd:325, 501, 863`). Game path looked for: `EventDirector.rig_her_route()` and the day 3 lesson, both call `rig()`. Either `rig_spaced` is dead code (remove both) or something should call it. | high

**`test_route_lines.gd`**

- `test_route_lines.gd:34` (`_test_parse_layers_accepts_five_and_still_rejects_four`) | "5 ... is accepted on its own", "1,9,0" -> [1] etc. | duplicate | `DevFlags.parse_layers` is tested in `test_debug_layers.gd:136-146` (`_test_parse_layers_reads_a_comma_list`, `_..._drops_malformed_entries_without_crashing`, the same `"1,9,0" == [1]` case on line 144). The 5-accepted case is the only new one; fold it into that suite. | medium

**`test_route_rig.gd`**

- test_route_rig.gd:24-27 (`RUN_SEED` comment: "these checks hold on seeds 4 and 5 and fail on 1, 2 and 3") | the whole target-resolution and rig-walk group built by `_build_fixture(RUN_SEED)` | cannot fail (true by luck of the seed) | The suite's own comment says the ground the targets resolve to depends on the run seed and the checks fail on three of five seeds, so they hold on the seed picked, not on a property of the code. Not a deletion: say in the finding that a run on seeds 1-3 would show which checks are seed-dependent; I could not tell which ones from reading. | medium

**`test_route_tree.gd`**

- test_route_tree.gd:165 `_test_no_route_runs_along_the_main_road` | `on_the_spine >= 0` ("%d route tiles stood on the main road's own corridor") | cannot fail | A count can not be negative; the comment itself calls it "not a lower bound to defend ... reported". Delete the check (the per-tile `junction_at(tile) != (-1,-1)` assertion inside the loop is the real one, and `_test_a_route_crosses_a_carriageway_only_at_a_junction` carries the non-vacuity guard). | high

**`test_routes_lattice.gd`**

- `test_routes_lattice.gd:36` | `_test_the_lattice_is_the_lattice`: `junction_count() == CITY_BLOCKS + ONE`, `segments().size() == expected`, each segment `rect.size == (BLOCK_SIZE, STREET_WIDTH)` | RESTATES | The lattice's own definition computed a second time from the same constants (the same reason `test_generator.gd:148`'s comment gives for not restating `period()`/`block_rect()`). The per-street "every tile is walkable" check beside it is real. | high

**`test_run_checkpoints.gd`**

- `test_run_checkpoints.gd:516` | `_test_parse_nerves_accepts_one_to_five_and_refuses_the_rest` | RESTATES | The accepted range of a dev flag written out; no game path reads it. | medium

**`test_run_state.gd`**

- test_run_state.gd:138 | "and the list holds the seven parts" (`run.run_parts.parts().size() == 7`) | restates a design decision | The count of the registered parts is the declaration list restated; adding a part means editing the constant and this literal in lockstep. The line above it (`unregistered_in(...).is_empty()`) already catches a part left off the list, and the sweep at 164+ iterates `parts()`. | high

**`test_save.gd`**

- `test_save.gd:1760` | `_test_a_desktop_save_shows_the_symbol_confirmed_at_once` ("a desktop save is answered at once and the symbol is already showing") | DUPLICATE | `_test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once` (test_save.gd:1316) does the same `_save.write` into an `Indicator` + `Showing` and asserts `indicator.is_showing() and timeline.pending == 0` ("that one change is already answered"); the `not struck` line is also in `_test_a_save_answered_at_once_shows_for_a_second_then_fades` (test_save.gd:1470). | high
- `test_save.gd:1732` | `_test_a_stray_answer_shows_nothing` (answer for a save never begun / second answer ignored) | DUPLICATE | `_test_an_answer_to_a_change_the_symbol_never_began_is_ignored` (test_save.gd:1408) holds the same behaviour of the same component through the bus; this one is the model-level copy. | medium
- test_save.gd:729 | "the resume dict this all hangs off of is the one asserted" (`t.check(resume["day_under_way"], ...)`) | cannot fail | `resume` is a dictionary the test built two lines above as `{"day_under_way": true}` and never passes to anything; it asserts back the literal it just wrote. Delete the check (and the `resume` local). | high
- test_save.gd:711-730 `_test_day_under_way_load_costs_one_nerve` (whole function) | "exactly one nerve is spent", "the same day is offered again", "the resistance work the attempt did is given back" | duplicate | No save, file or `GameSave` call is involved at all: it calls `run.calendar.finish_day(LOST_HARD_FAIL)` and reads the result, which `tests/test_day_loop.gd:226` ("losing costs a nerve", `:227` day stays) and `tests/test_run_checkpoints.gd:142` already pin; the resistance give-back is `tests/test_run_state.gd` territory. The save-specific half (a day under way is charged through the file) is held by `_test_a_day_under_way_gives_back_the_fire_it_lit` (741). | medium
- test_save.gd:911 | "and so the second load does not spend a second nerve" | cannot fail | The comment says nothing in the test calls `finish_day()` on the second load, so `nerves == 4` holds if `try_resume` restores nothing at all, or restores the 4 the file carries (the dawn was saved at 4 two lines before). The real property (the caller does not charge again) lives in `main`, not here. Either drop the check or make it observable: have `main`'s resume path (`tests/test_save_wiring.gd`) assert it. | medium
- test_save.gd:874-883 `_test_summary_load_costs_nothing` (the `day == 8 and nerves == 4` check at 881) | "nothing about the run changes on a load this function never spends a nerve on" | cannot fail | The run already stands at day 8, nerves 4 before the save is written; the load restores exactly those values, and nothing in the test could change them (the docstring says so: "nothing here ever touches them"). It passes with `try_resume` restoring nothing. The `day_under_way == false` check at 880 is the only live one. | medium
- test_save.gd:1760-1772 `_test_a_desktop_save_shows_the_symbol_confirmed_at_once` (whole function) | "a desktop save is answered at once and the symbol is already showing" | duplicate | Same setup and same assertions as `_test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once` at 1316-1339 (lines 1332-1333: `indicator.is_showing() and timeline.pending == 0`), and the plain-picture half as `_test_a_deletion_raises_and_settles_the_symbol` (1158). | medium
- test_save.gd:1748-1758 `_test_a_refused_save_leaves_the_symbol_dark` (whole function) | "a refused save leaves the symbol dark" | duplicate | `_test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once` (1321-1324) already writes under the headless runner with the bus listened to and asserts REFUSED and nothing announced; a symbol that hears no announcement is dark by construction. The extra `timeline.is_idle()` check follows from that. | medium

**`test_save_wiring.gd`**

- `test_save_wiring.gd:657-658` | "and that one change is already answered" (`parked.indicator.is_showing() and timeline.pending == 0`) | duplicate | `timeline.pending == 0` is asserted at 652 (together with `not is_idle()`), and `begun == 1` at 656; `indicator.is_showing()` is the same state as `not timeline.is_idle()`. | medium

**`test_scene_recipe_task.gd`**

- `test_scene_recipe_task.gd:272-297` (`_test_the_task_scenes_start_off_an_unread_mark`, whole function), `:303-318` (`_test_the_door_scenes_show_the_robber_a_done_task_sends`, whole function), `:343-348` (last check of `_test_an_authored_mast_carries_its_own_id`) | "%s starts off the mark" / "%s lists the street the robber starts on" / "the two-mast scene stands two masts under two ids" | restates a design decision | These load the authored `scene-recipes/*.json` files and assert facts about their contents (the start anchor is not the mark, an observation is at tick 1, `draft.include` is non-empty). No game code is exercised; they are red only when a recipe file is edited, and the second says in its own comment that the headless scene play (`tools/scene-recipes.sh`) answers the question and this "keeps either from being dropped". That is a lint of authored data, not a behavior. Could move into the recipe validator (`SceneRecipeRuntime.validate_runtime`) if the rule is wanted. | medium

**`test_scenery_animation.gd`**

- `test_scenery_animation.gd:150` | "the rotor display is centered in the generated housing's circular opening" (`VENT_ROTOR_RECT.get_center()` vs `Vector2(29, 22)`) | restates a design decision | Pixel coordinates of an art registration restated; red only when the art is redrawn, and the picture is a look question (checked by eye). Line 148 (runtime crop equals the authored viewBox) is the real contract and stays | medium

**`test_seals.gd`**

- `test_seals.gd:397-401` | "disconnected alleys are sealed at about the configured rate", "...the exception now, not the rule" (`rate < ALLEY_MOUTH_SEAL_CHANCE + 0.15`, `rate < 0.5`) | restates a design decision / true by luck of the seed | A statistical upper bound on sampled seeds against a tuning chance. It goes red when the chance is retuned and passes by sample luck otherwise; neither side is a fairness or winnability floor. The `candidates > 0` guard (391) stays | medium

**`test_siting_judges_once.gd`**

- test_siting_judges_once.gd:134 `_test_one_judgement_per_candidate` | "there were placements to ask (asked == 27)" | cannot fail | `asked` is incremented once per iteration of a loop of fixed size (3 ids x 9 pool sizes), so the check restates the loop bounds and goes red only when the test's own loop is edited. Replace with nothing, or with the useful guard the next line already gives (`refused < asked`). | medium

**`test_stroller.gd`**

- test_stroller.gd:136-137 (in `_test_live_draw_selection`) | "pram mirror matches direction %d" | duplicate / cannot fail as labelled | The assertion `rig.pose(1.0).mirrored == mirrored[direction]` is identical to the one on the line above ("mother mirror matches"); the pram assertion pins nothing the mother one does not. | high
- test_stroller.gd:_test_live_draw_selection (:113-142) | "mother draw selects the authored texture for direction %d", "pram draw selects ..." | restates a design decision | The test's three arrays (`mother_first_frames`, `pram_textures`, `mirrored`) are `Stroller`'s own direction-to-picture tables retyped; they go red only when a table is edited, never when the selection logic breaks differently from the table. `_test_all_eight_facings` and `_test_boundary_hysteresis` already cover which view the selector picks. | medium
- test_stroller.gd:_test_north_diagonal_contact_adjustment (:220-279) | "north-east receives the full two-pixel contact correction", "north diagonal correction peaks at its measured bound", and the per-facing `.y == PRAM_*_DISTANCE * OBLIQUE_Y` checks | restates a design decision | Recomputes the presentation offset formula from the same constants (`PRAM_NORTH_DISTANCE`, `OBLIQUE_Y`, `PRAM_NORTH_DIAGONAL_CONTACT_ADJUSTMENT`); it goes red on a visual-review retune, not on a broken contact. The continuity test above it (`_test_pram_offset_stays_continuous...`) is the relationship version. | medium

**`test_summary_model.gd`**

- `test_summary_model.gd:30` | `_test_a_won_days_summary_names_the_coming_day` (title "She fell asleep after 1:24.", body `"Day 5 of %d\n\nNerves left: ***"`, `model.brief == Texts.DAY_BRIEF.get(5)`) | RESTATES | Compares built strings with the literal strings `Texts` and the model's format write; it goes red only when the wording is edited. The behaviour worth holding is that the clock, the nerves and the day come from the run; one check with the pieces compared against `Texts` templates would do. Same shape for the exact body strings in `:57`, `:75`, `:132`. | medium
- `test_summary_model.gd:132` | `_test_the_standing_line_is_the_pause_screens` (`"Day 7 of %d     ·     Nerves left: ***"`) | RESTATES | A format string compared with its own literal; test_pause.gd:291 `_test_the_pause_says_where_the_run_stands` reads the same line through the screen. | medium

**`test_telemetry.gd`**

- `test_telemetry.gd:233` | "no repository here, and the log says so rather than guessing" (`t.check(true, ...)`) | cannot fail | A literal `true` inside the `version == "unknown"` branch; asserts nothing. Line 230 (`version != ""`) already covers that branch's only claim. Would be a plain `return` | high

**`test_texts_catalogue.gd`**

- `test_texts_catalogue.gd:265` | `Texts.TITLE_NAME == "Nappy"` ("the title's name is the catalogue's") | RESTATES | A constant compared with its own literal. Always the table read back. The next checks (a brief for every day) are a completeness guard and stay. | high

**`test_touch.gd`**

- `test_touch.gd:806` | `is_equal_approx(TouchControls.DEAD_ZONE_RADIUS, 16.0)` ("the dead zone is 16 design px") and the `16.0 * 1.01` line after it | RESTATES | Pins the number itself (the message quotes the player's "we can try 16px"). The relation checks in the same function (tighter than the ring, 1.01 of the radius steers, tap-stop covers it) are the property. | high
- `test_touch.gd:238` | `PAUSE_CATCH_RADIUS >= old_catch` ("never less than the 46px it caught at before the margin") | RESTATES | The literal 46.0 is a historical number kept as a floor. The 5% margin check next to it is the real contract. | medium
- `test_touch.gd:1289` | `_test_round_button_margins_and_unchanged_dead_zones` (pause press and release share the catch at 1.051 / catch_ratio +- 0.01; "a press 1% beyond the dead zone still steers") | DUPLICATE | The pause button's catch boundary is already held by `_test_every_catch_is_at_least_five_percent_past...` (test_touch.gd:234) and the dead-zone boundary by `_test_the_dead_zone_is_tighter...` (test_touch.gd:795, the `16.0 * 1.01` line). The only new content is the rotated variant. | medium
- `test_touch.gd:328` | `_test_is_double_tap_needs_both_windows` | DUPLICATE | `_test_a_close_quick_second_tap_runs_and_a_far_or_late_one_does_not` (test_touch.gd:481) drives the same three cases (soon+close, close+late, soon+far) through real clicks, so the pure function is covered through the path the game uses. | medium
- `test_touch.gd:940` | `_test_a_touch_near_her_own_position_no_longer_stops_her` | DUPLICATE | Asserts a press steers from `FOCUS_LEFT`; `_test_a_touch_aims_from_the_steering_focus_not_from_her` (test_touch.gd:840) already holds "the direction does not depend on where she is". What remains is the removal of a deleted feature (the world-space door). | medium
- `test_touch.gd:1277` | `_test_a_rig_word_names_the_side` (`from_word` / `side_from_word` for "joystick", "joystick-left", "tap", "") | RESTATES | A word-to-enum table for a dev rig flag, written out. | medium

**`test_tuning_fairness.gd`**

- `test_tuning_fairness.gd:84` | `RETURN_PATROLS_PER_ACT.size() == 4` and `count >= 0` per entry | RESTATES | A table's length and its entries being non-negative; goes red when an act is added or a count is edited. The interval ordering checks below it (ordered, shorter than `AHEAD_INTERVAL`) are orderings of constants and stay. | medium

**`test_turns.gd`**

- `test_turns.gd:637` (`_test_a_red_light_still_holds_a_car_that_is_turning`; early returns at 639 and 642) | no check on the two early exits (`if not signals: return`, `if not signals.is_signalled(box): return`) | cannot fail (true by luck of the seed) | If the city has no signals, or the junction is not signalled, the test returns without a check, so it passes having tested nothing. A guard such as `t.check(signals != null and signals.is_signalled(box), ...)` is what it lacks; a run would show whether the standard seed always signals it. | medium

**`test_tutorial_dog.gd`**

- `test_tutorial_dog.gd:40` | `_test_spawn_mode_switches_after_the_teaching_day` (`spawn_mode_on(RUN_TAUGHT_DAY)` AHEAD, `+1` MAP, `+11` MAP) | DUPLICATE / RESTATES | The day switch is held at the scheduler by `_test_day_4_is_a_map_placement` (test_tutorial_dog.gd:101: every `charging_dog` plan past the teaching day has a position) and at the director by `_test_day_3_is_still_sited_on_her_heading` / `_test_day_4_is_never_owed_to_the_director`. The direct-on-the-def version is the field read back, and its `+11` line is the same table again. | medium

**`test_visit_counter.gd`**

- `test_visit_counter.gd:664` (`_test_every_charger_has_its_own_counter`, loop check at 673) | "'%s' is counted as '%s'" over a name table | restates a design decision | The row-id to counter-name table restated. It does pin the GoatCounter series names (the event names are what the player's dashboards read, and the comment cites the player's request), so it may be wanted; flagging because the same names are asserted again in the charger tests that follow. | medium

**`test_walk_siting_spec.gd`**

- test_walk_siting_spec.gd:90-107 `_test_every_place_that_builds_a_siting_copies_the_rule` | "EventsAhead builds a WalkSiting in four places (%d)", "each copies holds_the_home_streets", "each hands it a verdict store" | restates a design decision | Greps the source text of `events_ahead.gd` for `WalkSiting.new(` and a copy line within 5 lines; `builds == 4` goes red when a fifth siting is added legitimately, and the string match goes red on a rename while the behaviour is intact. The comment says the first two sitings cannot be observed otherwise; if so this is a lint, and the same text-scan family as test_auto_screenshot's source scan. Keep only if the player wants source-text guards. | medium

**`test_walker_views.gd`**

- `test_walker_views.gd:106-107`, `:148-151` | "sector %d mirror matches the west-mirror convention", "sector %d draws the %s view" (`EXPECTED_MIRRORED`, `EXPECTED_VIEW`) | restates a design decision | The test's own copy of the sector-to-view and mirror tables, compared to `WalkerLook`'s tables. Changing the art convention means editing both. The behavioural checks in this file (hysteresis, wrap, stopped walker keeps its view, placement resets view) stay | medium
- `test_walker_views.gd:162`, `:320`, `:323` | "exactly five authored views", "gait-b body %s is native 18x38" | restates a design decision | Counts and pixel sizes of authored art; the same facts the atlas suites (`test_atlas_library.gd` membership/regions) and the bake already enforce, and they go red only when an art spec is changed on purpose. Keep the checks that a gait-b entry exists and is baked (303-315) | medium

**`test_web_display.gd`**

- test_web_display.gd:_test_apply_asks_nothing_off_a_page (about :36-41) | "a native build is capped by nothing" (`WebDisplay.apply(config)` then `dpr_cap(config) == 0.0`) | cannot fail | `apply()` is called and its effect is never observed; the assertion only re-asks `dpr_cap` on a native config, which `_test_the_cap_is_read_from_the_query`'s last check ("no cap off a page, whatever the query") already asserts. It would pass with `apply()` stubbed to do anything at all. | high
