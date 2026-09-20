# What an event costs

Computed from the real catalogue (`EventCatalogue.all()`, catalogue order) and the real `Tuning` constants below — never a second copy of the falloff or the decay. Regenerate with `tools/cost-table.sh`; `tools/cost-table.sh --check` compares this file against a fresh run and names every row and column that moved, old → new, without writing anything.

Every figure is on quiet sidewalk (ground multiplier 1.0); other grounds are not in this version. The constants each figure below was computed under, one line each so a change to any of them shows here as this line moving:

- `Tuning.EXCITEMENT_DECAY_WALKING` = 6.0 points/s
- `Tuning.SLEEPING_SENSITIVITY` = 0.55
- `Tuning.WALK_SPEED` = 92.0 px/s
- `Tuning.WALL_WORTH_OF_COST` = 48.0 points

**Excluded from every table**: `curfew_announce` and `loudspeaker`, the two `city_wide` rows — they apply everywhere at once rather than falling away from a place, so there is no distance to put in a column and `walk_through_cost()` answers zero for both by construction.

**`Geometry and role`** is what a row's own data says, unconditionally: `role` is `EventScheduler._role_for()` at day 0 (a row's cold shape, before any resistance heat); `core_intensity`/`core_radius` are a dash where a row has no core; `pulse_trough` is `intensity * 0.25`, the low point of the pulse envelope `current_intensity()` uses, and a dash where a row does not pulse; `speed` is a pursuer's `pursue_speed` (almost always faster than its own cold `speed`, which is usually 0), a mobile row's own `speed`, and a dash for anything that does not move; `walk_through_cost()` is the field integrated along a straight line through the centre, less the walking decay over the same crossing.

**`Standing at a fixed distance — awake`/`Standing at a fixed distance — asleep`** are the net points a second standing still at a fixed distance from a row's centre: the field (`EventDef.emission_at()`, which is what `contribution_at()` charges) averaged over the row's own pulse, times the sleeping sensitivity where the baby is asleep, less the walking decay. A pure query on the row's own data — no instance, no notice or chase state — so every included row gets a real number here, pursuers and the three detainers (`chatting_mother`, `checkpoint_hut`, `checkpoint_post`) included, the same way `walk_through_cost()` already prices them: a detainer's real cost is `Tuning.CHAT_EXCITEMENT` over the hold rather than this field, so its figures here are notional, exactly as `docs/EVENTS.md` already says of its own column.

**`The pass — awake`/`The pass — asleep`** are the net points from one real pass at `Tuning.WALK_SPEED` — she and the row's own instance going different directions, the row moving exactly as the game moves it (pacing, mobile, or held still), averaged over 8 samples of its own pulse phase. `M174Pass.pass_net_averaged()` (`tests/probes/m174_pass.gd`) is the simulation, shared rather than duplicated — `tests/test_events.gd`'s own relationship test runs the identical code. Dashed for a pursuer (`pursues` or `pursues_within` set: alley_mouse, pigeon_flock, charging_dog, alley_robbery, masked_pursuer) — its notice and chase state is driven by where the player is, which the rig never tells it, so there is no pass to measure, the same reason `docs/EVENTS.md`'s own run-through column is empty for a pursuer. The 0px column is dashed for a row with a solid, still body (`obstructs_radius > 0.0`) — she cannot walk the same line as a thing she cannot walk through.

Deterministic: fixed row order, fixed decimals (one), a fixed 8-sample pulse average, no clock and no seed anywhere in the arithmetic — two runs on the same tree write the same bytes.
## Geometry and role

| id                   |      role | intensity | core_intensity | core_radius | inner_radius | outer_radius | falloff_power | pulse_period | pulse_trough |     speed | walk_through_cost |
| -------------------- | --------- | --------- | -------------- | ----------- | ------------ | ------------ | ------------- | ------------ | ------------ | --------- | ----------------- |
| playground           |      none |       0.0 |              — |           — |         40.0 |        150.0 |           2.0 |          9.0 |          0.0 |         — |             -19.6 |
| cat_dash             |      none |      17.0 |              — |           — |         30.0 |        120.0 |           2.0 |            — |            — |     240.0 |              17.6 |
| alley_mouse          |  friction |      21.0 |              — |           — |         15.0 |         60.0 |           2.0 |            — |            — |     200.0 |              12.7 |
| dog_walker           |  friction |      33.0 |              — |           — |         26.0 |        105.0 |           2.0 |          3.5 |          8.2 |      32.0 |              42.7 |
| cafe_tables          |      wall |      12.0 |              — |           — |         38.0 |         64.0 |           2.0 |          6.0 |          3.0 |         — |               6.1 |
| delivery_van         |      wall |       0.0 |              — |           — |         40.0 |        150.0 |           2.0 |            — |            — |         — |             -19.6 |
| homeless_yeller      |  friction |      20.0 |              — |           — |         45.0 |        210.0 |           2.0 |          5.0 |          5.0 |      30.0 |              40.0 |
| busker               |  friction |      19.3 |              — |           — |         45.0 |        190.0 |           2.0 |          7.0 |          4.8 |         — |              34.7 |
| construction         |      wall |       0.0 |              — |           — |         46.0 |        200.0 |           2.0 |            — |            — |         — |             -26.1 |
| fire_truck           |      wall |      26.0 |              — |           — |         70.0 |        340.0 |           2.0 |            — |            — |     190.0 |              97.0 |
| burning_building     | set_piece |      18.0 |              — |           — |         60.0 |        260.0 |           2.0 |          3.0 |          4.5 |         — |              41.7 |
| burnt_shell          |  friction |       2.5 |              — |           — |         24.0 |         78.0 |           2.0 |            — |            — |         — |              -6.9 |
| loose_dog            |      none |      39.0 |              — |           — |         30.0 |        140.0 |           2.0 |          2.2 |          9.8 |     132.0 |              69.3 |
| market_stall         |      wall |      14.0 |              — |           — |         38.0 |         64.0 |           2.0 |          8.0 |          3.5 |         — |               8.5 |
| leaf_blower          |      wall |      19.3 |           35.0 |        64.0 |         45.0 |        190.0 |           2.0 |          4.0 |          4.8 |         — |              52.9 |
| pigeon_flock         |      none |      42.0 |              — |           — |         26.0 |        168.0 |           2.0 |            — |            — |         — |              44.9 |
| cyclist              |      none |      18.0 |              — |           — |         33.0 |         90.0 |           2.0 |            — |            — |     165.0 |              16.0 |
| ice_cream_van        |      wall |      13.0 |              — |           — |         48.0 |        240.0 |           2.0 |         11.0 |          3.2 |         — |              18.4 |
| reversing_lorry      |      wall |      16.0 |              — |           — |         46.0 |        175.0 |           2.0 |          1.6 |          4.0 |         — |              23.1 |
| charging_dog         |      none |      12.0 |              — |           — |         26.0 |        150.0 |           2.0 |            — |            — |     130.0 |               8.8 |
| chatting_mother      |  friction |       4.5 |              — |           — |         56.0 |         70.0 |           2.0 |            — |            — |      26.0 |              -2.7 |
| police_patrol        |  friction |      10.0 |              — |           — |         44.0 |        185.0 |           2.0 |            — |            — |      74.0 |               5.9 |
| poster_crew          |  friction |       5.0 |              — |           — |         30.0 |        110.0 |           2.0 |            — |            — |         — |              -5.3 |
| poster_crew_square   |  friction |       5.0 |              — |           — |         30.0 |        110.0 |           2.0 |            — |            — |         — |              -5.3 |
| roadblock            |  friction |      13.0 |              — |           — |         86.0 |        179.0 |           2.0 |            — |            — |         — |              18.5 |
| checkpoint_hut       |  friction |       6.0 |              — |           — |         84.0 |         98.0 |           2.0 |            — |            — |         — |              -0.6 |
| checkpoint_gate      |  friction |       0.0 |              — |           — |         84.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| checkpoint_post      |  friction |       6.0 |              — |           — |         84.0 |         98.0 |           2.0 |            — |            — |         — |              -0.6 |
| abduction            |      wall |      20.0 |              — |           — |         54.0 |        250.0 |           2.0 |            — |            — |         — |              47.7 |
| alley_robbery        |      wall |      16.0 |              — |           — |         30.0 |        200.0 |           2.0 |            — |            — |     130.0 |              23.8 |
| night_raid           |      wall |      24.0 |              — |           — |         70.0 |        330.0 |           2.0 |          6.0 |          6.0 |         — |              83.9 |
| military_convoy      |      wall |      22.0 |              — |           — |         76.0 |        300.0 |           2.0 |            — |            — |     120.0 |              68.6 |
| barricade            |  friction |       0.0 |              — |           — |         40.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| protest              |  friction |      15.0 |              — |           — |         39.0 |        269.0 |           2.0 |          8.0 |          3.8 |         — |              27.6 |
| firefight            |      wall |      30.0 |              — |           — |         84.0 |        374.0 |           2.0 |          2.5 |          7.5 |         — |             132.1 |
| fallen_tree          |  friction |       0.0 |              — |           — |         40.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| car_accident         |      wall |      50.0 |              — |           — |         24.0 |         96.0 |           2.0 |            — |            — |         — |              65.7 |
| skip                 |  friction |       0.0 |              — |           — |         40.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| scaffolding          |  friction |       0.0 |              — |           — |         40.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| burst_water_main     |  friction |       0.0 |              — |           — |         40.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| moving_van           |  friction |       0.0 |              — |           — |         40.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| burnt_out_car        |  friction |       0.0 |              — |           — |         40.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| collapsed_frontage   |  friction |       0.0 |              — |           — |         40.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| finale_explosion     |      wall |      24.0 |              — |           — |        300.0 |        520.0 |           2.0 |            — |            — |         — |             165.2 |
| impact_crater        |  friction |       0.0 |              — |           — |         40.0 |        120.0 |           2.0 |            — |            — |         — |             -15.7 |
| masked_pursuer       |      wall |      18.0 |              — |           — |         28.0 |        120.0 |           2.0 |            — |            — |     130.0 |              19.3 |
| basement_steam       |  friction |      14.0 |              — |           — |         24.0 |         90.0 |           2.0 |          4.0 |          3.5 |         — |               9.0 |

## Standing at a fixed distance — awake

| id                   |       0px |      25px |      50px |      75px |     100px |     150px |     200px |     300px |     400px |     550px |
| -------------------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- |
| playground           |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| cat_dash             |      11.0 |      11.0 |      10.2 |       6.8 |       0.7 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| alley_mouse          |      15.0 |      14.0 |       2.3 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| dog_walker           |      14.6 |      14.6 |      12.7 |       6.7 |      -3.5 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| cafe_tables          |       1.5 |       1.5 |      -0.1 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| delivery_van         |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| homeless_yeller      |       6.5 |       6.5 |       6.5 |       6.1 |       5.1 |       1.4 |      -4.5 |      -6.0 |      -6.0 |      -6.0 |
| busker               |       6.1 |       6.1 |       6.0 |       5.5 |       4.3 |      -0.3 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| construction         |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| fire_truck           |      20.0 |      20.0 |      20.0 |      20.0 |      19.7 |      17.7 |      14.0 |       1.1 |      -6.0 |      -6.0 |
| burning_building     |       5.2 |       5.2 |       5.2 |       5.2 |       4.8 |       3.0 |      -0.3 |      -6.0 |      -6.0 |      -6.0 |
| burnt_shell          |      -3.5 |      -3.5 |      -4.1 |      -5.7 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| loose_dog            |      18.4 |      18.4 |      17.6 |      14.3 |       8.5 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| market_stall         |       2.8 |       2.8 |       0.9 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| leaf_blower          |      15.9 |      15.9 |      14.4 |       5.5 |       4.3 |      -0.3 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| pigeon_flock         |      34.7 |      32.0 |      24.6 |      13.1 |       5.1 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| cyclist              |      12.0 |      12.0 |      10.4 |       2.2 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| ice_cream_van        |       2.1 |       2.1 |       2.1 |       2.0 |       1.5 |      -0.2 |      -3.0 |      -6.0 |      -6.0 |      -6.0 |
| reversing_lorry      |       4.0 |       4.0 |       4.0 |       3.5 |       2.2 |      -2.5 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| charging_dog         |       6.0 |       6.0 |       5.6 |       4.1 |       1.7 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| chatting_mother      |      -1.5 |      -1.5 |      -1.5 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| police_patrol        |       4.0 |       4.0 |       4.0 |       3.5 |       2.4 |      -1.7 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| poster_crew          |      -1.0 |      -1.0 |      -1.3 |      -2.6 |      -4.8 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| poster_crew_square   |      -1.0 |      -1.0 |      -1.3 |      -2.6 |      -4.8 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| roadblock            |       7.0 |       7.0 |       7.0 |       7.0 |       6.7 |       0.8 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| checkpoint_hut       |       0.0 |       0.0 |       0.0 |       0.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| checkpoint_gate      |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| checkpoint_post      |       0.0 |       0.0 |       0.0 |       0.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| abduction            |      14.0 |      14.0 |      14.0 |      13.8 |      12.9 |       9.2 |       2.9 |      -6.0 |      -6.0 |      -6.0 |
| alley_robbery        |      10.0 |      10.0 |       9.8 |       8.9 |       7.3 |       2.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| night_raid           |       9.0 |       9.0 |       9.0 |       9.0 |       8.8 |       7.6 |       5.2 |      -2.7 |      -6.0 |      -6.0 |
| military_convoy      |      16.0 |      16.0 |      16.0 |      16.0 |      15.7 |      13.6 |       9.3 |      -6.0 |      -6.0 |      -6.0 |
| barricade            |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| protest              |       3.4 |       3.4 |       3.4 |       3.1 |       2.7 |       1.2 |      -1.2 |      -6.0 |      -6.0 |      -6.0 |
| firefight            |      12.8 |      12.8 |      12.8 |      12.8 |      12.7 |      11.8 |       9.8 |       2.3 |      -6.0 |      -6.0 |
| fallen_tree          |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| car_accident         |      44.0 |      44.0 |      37.5 |      18.9 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| skip                 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| scaffolding          |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| burst_water_main     |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| moving_van           |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| burnt_out_car        |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| collapsed_frontage   |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| finale_explosion     |      18.0 |      18.0 |      18.0 |      18.0 |      18.0 |      18.0 |      18.0 |      18.0 |      13.0 |      -6.0 |
| impact_crater        |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| masked_pursuer       |      12.0 |      12.0 |      11.0 |       7.3 |       1.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| basement_steam       |       2.8 |       2.7 |       1.4 |      -2.5 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |

## Standing at a fixed distance — asleep

| id                   |       0px |      25px |      50px |      75px |     100px |     150px |     200px |     300px |     400px |     550px |
| -------------------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- |
| playground           |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| cat_dash             |       3.4 |       3.4 |       2.9 |       1.0 |      -2.3 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| alley_mouse          |       5.6 |       5.0 |      -1.4 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| dog_walker           |       5.3 |       5.3 |       4.3 |       1.0 |      -4.6 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| cafe_tables          |      -1.9 |      -1.9 |      -2.8 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| delivery_van         |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| homeless_yeller      |       0.9 |       0.9 |       0.9 |       0.6 |       0.1 |      -1.9 |      -5.2 |      -6.0 |      -6.0 |      -6.0 |
| busker               |       0.6 |       0.6 |       0.6 |       0.4 |      -0.3 |      -2.8 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| construction         |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| fire_truck           |       8.3 |       8.3 |       8.3 |       8.3 |       8.1 |       7.0 |       5.0 |      -2.1 |      -6.0 |      -6.0 |
| burning_building     |       0.2 |       0.2 |       0.2 |       0.2 |      -0.1 |      -1.1 |      -2.8 |      -6.0 |      -6.0 |      -6.0 |
| burnt_shell          |      -4.6 |      -4.6 |      -4.9 |      -5.9 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| loose_dog            |       7.4 |       7.4 |       7.0 |       5.2 |       2.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| market_stall         |      -1.2 |      -1.2 |      -2.2 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| leaf_blower          |       6.0 |       6.0 |       5.2 |       0.4 |      -0.3 |      -2.8 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| pigeon_flock         |      16.4 |      14.9 |      10.8 |       4.5 |       0.1 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| cyclist              |       3.9 |       3.9 |       3.0 |      -1.5 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| ice_cream_van        |      -1.5 |      -1.5 |      -1.5 |      -1.6 |      -1.9 |      -2.8 |      -4.3 |      -6.0 |      -6.0 |      -6.0 |
| reversing_lorry      |      -0.5 |      -0.5 |      -0.5 |      -0.8 |      -1.5 |      -4.1 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| charging_dog         |       0.6 |       0.6 |       0.4 |      -0.4 |      -1.8 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| chatting_mother      |      -3.5 |      -3.5 |      -3.5 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| police_patrol        |      -0.5 |      -0.5 |      -0.5 |      -0.8 |      -1.4 |      -3.6 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| poster_crew          |      -3.2 |      -3.2 |      -3.4 |      -4.1 |      -5.4 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| poster_crew_square   |      -3.2 |      -3.2 |      -3.4 |      -4.1 |      -5.4 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| roadblock            |       1.2 |       1.2 |       1.2 |       1.2 |       1.0 |      -2.2 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| checkpoint_hut       |      -2.7 |      -2.7 |      -2.7 |      -2.7 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| checkpoint_gate      |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| checkpoint_post      |      -2.7 |      -2.7 |      -2.7 |      -2.7 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| abduction            |       5.0 |       5.0 |       5.0 |       4.9 |       4.4 |       2.4 |      -1.1 |      -6.0 |      -6.0 |      -6.0 |
| alley_robbery        |       2.8 |       2.8 |       2.7 |       2.2 |       1.3 |      -1.6 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| night_raid           |       2.2 |       2.2 |       2.2 |       2.2 |       2.1 |       1.5 |       0.2 |      -4.2 |      -6.0 |      -6.0 |
| military_convoy      |       6.1 |       6.1 |       6.1 |       6.1 |       6.0 |       4.8 |       2.4 |      -6.0 |      -6.0 |      -6.0 |
| barricade            |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| protest              |      -0.8 |      -0.8 |      -0.9 |      -1.0 |      -1.2 |      -2.0 |      -3.4 |      -6.0 |      -6.0 |      -6.0 |
| firefight            |       4.3 |       4.3 |       4.3 |       4.3 |       4.3 |       3.8 |       2.7 |      -1.4 |      -6.0 |      -6.0 |
| fallen_tree          |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| car_accident         |      21.5 |      21.5 |      17.9 |       7.7 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| skip                 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| scaffolding          |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| burst_water_main     |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| moving_van           |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| burnt_out_car        |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| collapsed_frontage   |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| finale_explosion     |       7.2 |       7.2 |       7.2 |       7.2 |       7.2 |       7.2 |       7.2 |       7.2 |       4.5 |      -6.0 |
| impact_crater        |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| masked_pursuer       |       3.9 |       3.9 |       3.3 |       1.3 |      -2.2 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |
| basement_steam       |      -1.2 |      -1.2 |      -1.9 |      -4.1 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |      -6.0 |

## The pass — awake

| id                   |       0px |      20px |      40px |      80px |     120px |
| -------------------- | --------- | --------- | --------- | --------- | --------- |
| playground           |     -19.5 |     -19.4 |     -18.9 |     -16.5 |     -11.7 |
| cat_dash             |      -0.9 |      -0.9 |      -0.9 |      -1.5 |       0.0 |
| alley_mouse          |         — |         — |         — |         — |         — |
| dog_walker           |      16.1 |      15.3 |      12.6 |       1.6 |       0.0 |
| cafe_tables          |         — |       0.5 |      -0.4 |       0.0 |       0.0 |
| delivery_van         |         — |     -19.4 |     -18.9 |     -16.5 |     -11.7 |
| homeless_yeller      |      11.1 |      11.0 |      10.3 |       7.3 |       2.2 |
| busker               |         — |      12.0 |      11.2 |       7.1 |      -0.1 |
| construction         |         — |     -25.9 |     -25.5 |     -23.9 |     -20.9 |
| fire_truck           |      31.6 |      31.5 |      31.2 |      29.5 |      26.4 |
| burning_building     |         — |      13.2 |      12.7 |      10.2 |       5.4 |
| burnt_shell          |         — |      -6.3 |      -5.9 |       0.0 |       0.0 |
| loose_dog            |      15.0 |      14.7 |      13.5 |       7.6 |      -0.0 |
| market_stall         |         — |       2.5 |       1.3 |       0.0 |       0.0 |
| leaf_blower          |         — |      22.6 |      18.7 |       7.1 |      -0.1 |
| pigeon_flock         |         — |         — |         — |         — |         — |
| cyclist              |       5.7 |       5.3 |       4.3 |      -0.5 |       0.0 |
| ice_cream_van        |         — |      -0.3 |      -0.7 |      -2.4 |      -5.5 |
| reversing_lorry      |         — |       5.6 |       4.9 |       1.6 |      -4.1 |
| charging_dog         |         — |         — |         — |         — |         — |
| chatting_mother      |      -2.1 |      -2.1 |      -1.9 |       0.0 |       0.0 |
| police_patrol        |       3.3 |       3.1 |       2.9 |       1.0 |      -1.9 |
| poster_crew          |         — |      -5.3 |      -5.5 |      -6.5 |       0.0 |
| poster_crew_square   |         — |      -5.3 |      -5.5 |      -6.5 |       0.0 |
| roadblock            |         — |      25.0 |      24.3 |      21.1 |      11.8 |
| checkpoint_hut       |         — |      -0.6 |      -0.7 |      -1.1 |       0.0 |
| checkpoint_gate      |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| checkpoint_post      |         — |      -0.6 |      -0.7 |      -1.1 |       0.0 |
| abduction            |         — |      47.3 |      46.0 |      40.2 |      29.5 |
| alley_robbery        |         — |         — |         — |         — |         — |
| night_raid           |         — |      36.2 |      35.5 |      32.7 |      27.2 |
| military_convoy      |      29.8 |      29.7 |      29.2 |      27.2 |      23.2 |
| barricade            |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| protest              |         — |      11.9 |      11.4 |       9.0 |       4.5 |
| firefight            |         — |      66.4 |      65.6 |      62.4 |      56.4 |
| fallen_tree          |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| car_accident         |         — |      90.2 |      78.1 |      15.8 |       0.0 |
| skip                 |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| scaffolding          |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| burst_water_main     |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| moving_van           |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| burnt_out_car        |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| collapsed_frontage   |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| finale_explosion     |     -58.9 |     -58.8 |     -59.0 |     -59.3 |     -59.8 |
| impact_crater        |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| masked_pursuer       |         — |         — |         — |         — |         — |
| basement_steam       |         — |     -11.5 |     -10.5 |      -5.3 |       0.0 |

## The pass — asleep

| id                   |       0px |      20px |      40px |      80px |     120px |
| -------------------- | --------- | --------- | --------- | --------- | --------- |
| playground           |     -19.5 |     -19.4 |     -18.9 |     -16.5 |     -11.7 |
| cat_dash             |      -2.5 |      -2.4 |      -2.4 |      -2.2 |       0.0 |
| alley_mouse          |         — |         — |         — |         — |         — |
| dog_walker           |       4.3 |       4.0 |       2.7 |      -2.0 |       0.0 |
| cafe_tables          |         — |      -3.3 |      -3.1 |       0.0 |       0.0 |
| delivery_van         |         — |     -19.4 |     -18.9 |     -16.5 |     -11.7 |
| homeless_yeller      |      -3.2 |      -3.2 |      -3.5 |      -4.6 |      -6.4 |
| busker               |         — |      -4.5 |      -4.8 |      -6.2 |      -8.7 |
| construction         |         — |     -25.9 |     -25.5 |     -23.9 |     -20.9 |
| fire_truck           |      10.9 |      10.8 |      10.7 |       9.9 |       8.4 |
| burning_building     |         — |      -7.9 |      -8.1 |      -9.0 |     -10.6 |
| burnt_shell          |         — |      -7.9 |      -7.2 |       0.0 |       0.0 |
| loose_dog            |       4.9 |       4.7 |       4.2 |       1.5 |      -1.8 |
| market_stall         |         — |      -2.2 |      -2.2 |       0.0 |       0.0 |
| leaf_blower          |         — |       1.3 |      -0.6 |      -6.2 |      -8.7 |
| pigeon_flock         |         — |         — |         — |         — |         — |
| cyclist              |       1.2 |       1.0 |       0.7 |      -1.1 |       0.0 |
| ice_cream_van        |         — |     -14.2 |     -14.3 |     -14.6 |     -15.2 |
| reversing_lorry      |         — |      -7.1 |      -7.3 |      -8.2 |      -9.8 |
| charging_dog         |         — |         — |         — |         — |         — |
| chatting_mother      |      -4.4 |      -4.2 |      -3.7 |       0.0 |       0.0 |
| police_patrol        |      -4.2 |      -4.3 |      -4.3 |      -4.9 |      -5.6 |
| poster_crew          |         — |      -9.3 |      -9.0 |      -8.0 |       0.0 |
| poster_crew_square   |         — |      -9.3 |      -9.0 |      -8.0 |       0.0 |
| roadblock            |         — |       3.3 |       3.1 |       2.2 |      -1.3 |
| checkpoint_hut       |         — |      -6.0 |      -5.7 |      -3.9 |       0.0 |
| checkpoint_gate      |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| checkpoint_post      |         — |      -6.0 |      -5.7 |      -3.9 |       0.0 |
| abduction            |         — |      11.4 |      10.8 |       8.2 |       3.3 |
| alley_robbery        |         — |         — |         — |         — |         — |
| night_raid           |         — |       0.6 |       0.3 |      -0.8 |      -3.1 |
| military_convoy      |       8.8 |       8.7 |       8.5 |       7.6 |       5.7 |
| barricade            |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| protest              |         — |      -9.2 |      -9.3 |     -10.1 |     -11.6 |
| firefight            |         — |      14.6 |      14.3 |      12.9 |      10.2 |
| fallen_tree          |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| car_accident         |         — |      44.1 |      37.9 |       5.6 |       0.0 |
| skip                 |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| scaffolding          |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| burst_water_main     |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| moving_van           |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| burnt_out_car        |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| collapsed_frontage   |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| finale_explosion     |     -62.3 |     -62.2 |     -62.3 |     -62.3 |     -62.4 |
| impact_crater        |         — |     -15.5 |     -14.7 |     -11.7 |       0.0 |
| masked_pursuer       |         — |         — |         — |         — |         — |
| basement_steam       |         — |     -11.5 |     -10.5 |      -5.3 |       0.0 |
