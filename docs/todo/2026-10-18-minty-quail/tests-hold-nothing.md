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
record, where it does not hold. Keeping the four kinds out from now on is **verify**'s testing policy and the CI check of
test-only members (record minty-quail-gentle-hare).

**The player's rulings on the cases the audit could not settle that are still open** (curly-rabbit #1100):

- The day-3 dog's chase test (`test_events_pursuit.gd`, `_test_the_day_3_dog_keeps_its_gold_timing`):
  "the measured half" stays, the chase timed on real frames as she walks into the dog and the
  warning being the half-second badge; the half that types the dog's catalogue row again (the
  half-second badge, the 4.5 s approach, 130 px/s) goes.
- The danger test's check that the old warning rings stay deleted (`test_danger.gd`,
  `_test_the_rings_are_gone`): "remove".

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

**`test_barrier_stays.gd`**

- `test_barrier_stays.gd:192-214` (`_test_the_barrier_costs_nothing_while_he_walks_away`, whole function) and `:139` (`current_intensity() == 0.0`) | "the barrier costs nothing beside it on any leaving frame" / "nor after it, as a roadblock's band never does" | duplicate | `finale_rig.gd:525-592` (`_test_a_roadblock_band_costs_nothing`) walks the same roadblock through posted, warning, charging, walking away, gone and streamed back, and asserts `strongest == 0.0` on every frame including the leaving ones; its 531 check asserts the row's intensity is 0.0. The two suites test the same behavior of the same component (`excitement.contribution_at` on a roadblock band). | medium

**`test_bollards.gd`**

- `test_bollards.gd:46` | "and that circle is 4.8px" (`post.shape.radius == 12.0 * 0.4`) | restates a design decision | The literal radius restated; line 44 already asserts the body's circle equals the radius the shadow is drawn from, which is the relationship that matters. | high

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

**`test_generator.gd`**

- `test_generator.gd:286` | `Tuning.CITY_BLOCKS.x % 2 == 1 and .y % 2 == 1` ("the lattice is odd on both axes") and the `home_block == middle` check | RESTATES | Parity of a constant and the home being in the middle block are the design written out. The `home_to_nearest_calm() >= MIN_HOME_TO_PARK_TILES` check in the same loop is a floor and stays. | medium

**`test_give_way.gd`**

- test_give_way.gd:34-37 `_test_the_stop_line_is_a_setback_short` | "the line is the setback short of what it stops for" (`GiveWay.stop_line(100.0) == 100.0 - Tuning.CAR_STOP_LINE_SETBACK`) | cannot fail (tautology) | The assertion is the function's body retyped. The second check (`stop_line(1.0) < 0.0`) is a real edge case and is worth keeping. | medium

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

**`test_orientation.gd`**

- `test_orientation.gd:284` | `layers.size() == 8` ("every layer of screen furniture is built, and nothing extra") | RESTATES | A count of CanvasLayers that changes whenever a screen is added; the transform check that follows over `layers` is the property. | medium

**`test_pelican.gd`**

- test_pelican.gd:212-229 `_test_the_pelican_never_becomes_a_png` | "every pelican picture has its SVG under art/", "and none has an illustrated PNG beside it" | restates a design decision | Looks on disk for files to decide the art format; red only when someone converts the art on purpose (the illustrated-png and svg-art skills own that rule). It exercises no code. | medium

**`test_regions.gd`**

- `test_regions.gd:525` (first check of `_test_wall_crossing_posts_four_guards`) | "a catalogue roadblock still posts two guards (%d)" | restates a design decision | `guard_sides.size() == 2` is the table; the per-wall counts in the loop (`street_walls.size() == per_wall * ...`, `total_guards == 4`) are derived from it and also restate "a wall stands three bodies / four guards" (546, 561). Would go red only on a design change to the crossing's make-up. | medium

**`test_resistance_arrow.gd`**

- `test_resistance_arrow.gd:217` and `:220` | `_test_the_arrow_moves_at_four_tiles_closer` / `_test_the_arrow_does_not_move_at_three_tiles_closer` | RESTATES | Two probes straddling the hysteresis constant (4 tiles) read back as `moves` true/false; they go red when the threshold is retuned, not when switching breaks. `_test_the_arrow_switches_as_another_target_becomes_closer` (test_resistance_arrow.gd:182) is the behaviour. | medium

**`test_resistance_reach_narrow.gd`**

- test_resistance_reach_narrow.gd:97-98 `_test_the_narrow_targets_are_reachable_on_their_day` | "day %d has a narrow resistance target" (`ResistanceSteps.narrow_target_on(day) != null` for days 9, 12, 14) | restates a design decision | Reads which days have a narrow target out of `ResistanceSteps` and then loops over the same three days; goes red only when the table is edited. The skip-branch `continue` it guards is the only thing it does. Medium-low; kept as a guard if the player prefers. | medium

**`test_resistance_replacement.gd`**

- `test_resistance_replacement.gd:100` | `t.check(true, "skipped: the test city has no two alleys close enough to test this")` | cannot fail | An always-true check on the branch where the setup found nothing, so the whole test silently passes on a seed/city where its precondition does not hold. Should fail (or the setup should pick a city that has the alleys). | high

**`test_return_patrols.gd`**

- `test_return_patrols.gd:117-126` (`_test_owed_count_per_act`, whole function) | "day %d (act %d) owes %d return patrol(s)" | restates a design decision | `owed() == EventDirector.RETURN_PATROLS_PER_ACT[act - 1]` reads the table back to itself (the doc comment states `[0, 0, 2, 3]`). `test_tuning_fairness.gd:84-88` already guards the table's shape. The behaviour this table drives is checked by the walking tests below (`_test_each_patrol_comes_within_its_rigged_bag` 229, `_test_a_marble_spent_unmet...` 258). | high
- `test_return_patrols.gd:140` | "the one batch is the whole of act IV's count" | restates a design decision | `once == RETURN_PATROLS_PER_ACT[3]`: the same table read back. The no-second-batch check above it (137) is the real one. | medium

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

**`test_siting_judges_once.gd`**

- test_siting_judges_once.gd:134 `_test_one_judgement_per_candidate` | "there were placements to ask (asked == 27)" | cannot fail | `asked` is incremented once per iteration of a loop of fixed size (3 ids x 9 pool sizes), so the check restates the loop bounds and goes red only when the test's own loop is edited. Replace with nothing, or with the useful guard the next line already gives (`refused < asked`). | medium

**`test_texts_catalogue.gd`**

- `test_texts_catalogue.gd:265` | `Texts.TITLE_NAME == "Nappy"` ("the title's name is the catalogue's") | RESTATES | A constant compared with its own literal. Always the table read back. The next checks (a brief for every day) are a completeness guard and stay. | high

**`test_tuning_fairness.gd`**

- `test_tuning_fairness.gd:84` | `RETURN_PATROLS_PER_ACT.size() == 4` and `count >= 0` per entry | RESTATES | A table's length and its entries being non-negative; goes red when an act is added or a count is edited. The interval ordering checks below it (ordered, shorter than `AHEAD_INTERVAL`) are orderings of constants and stay. | medium

**`test_turns.gd`**

- `test_turns.gd:637` (`_test_a_red_light_still_holds_a_car_that_is_turning`; early returns at 639 and 642) | no check on the two early exits (`if not signals: return`, `if not signals.is_signalled(box): return`) | cannot fail (true by luck of the seed) | If the city has no signals, or the junction is not signalled, the test returns without a check, so it passes having tested nothing. A guard such as `t.check(signals != null and signals.is_signalled(box), ...)` is what it lacks; a run would show whether the standard seed always signals it. | medium

**`test_tutorial_dog.gd`**

- `test_tutorial_dog.gd:40` | `_test_spawn_mode_switches_after_the_teaching_day` (`spawn_mode_on(RUN_TAUGHT_DAY)` AHEAD, `+1` MAP, `+11` MAP) | DUPLICATE / RESTATES | The day switch is held at the scheduler by `_test_day_4_is_a_map_placement` (test_tutorial_dog.gd:101: every `charging_dog` plan past the teaching day has a position) and at the director by `_test_day_3_is_still_sited_on_her_heading` / `_test_day_4_is_never_owed_to_the_director`. The direct-on-the-def version is the field read back, and its `+11` line is the same table again. | medium

**`test_walk_siting_spec.gd`**

- test_walk_siting_spec.gd:90-107 `_test_every_place_that_builds_a_siting_copies_the_rule` | "EventsAhead builds a WalkSiting in four places (%d)", "each copies holds_the_home_streets", "each hands it a verdict store" | restates a design decision | Greps the source text of `events_ahead.gd` for `WalkSiting.new(` and a copy line within 5 lines; `builds == 4` goes red when a fifth siting is added legitimately, and the string match goes red on a rename while the behaviour is intact. The comment says the first two sitings cannot be observed otherwise; if so this is a lint, and the same text-scan family as test_auto_screenshot's source scan. Keep only if the player wants source-text guards. | medium

**`test_walker_views.gd`**

- `test_walker_views.gd:106-107`, `:148-151` | "sector %d mirror matches the west-mirror convention", "sector %d draws the %s view" (`EXPECTED_MIRRORED`, `EXPECTED_VIEW`) | restates a design decision | The test's own copy of the sector-to-view and mirror tables, compared to `WalkerLook`'s tables. Changing the art convention means editing both. The behavioural checks in this file (hysteresis, wrap, stopped walker keeps its view, placement resets view) stay | medium
- `test_walker_views.gd:162`, `:320`, `:323` | "exactly five authored views", "gait-b body %s is native 18x38" | restates a design decision | Counts and pixel sizes of authored art; the same facts the atlas suites (`test_atlas_library.gd` membership/regions) and the bake already enforce, and they go red only when an art spec is changed on purpose. Keep the checks that a gait-b entry exists and is baked (303-315) | medium
