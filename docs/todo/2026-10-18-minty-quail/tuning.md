# Tuning holds shared balance numbers only

`src/autoload/tuning.gd` holds 261 constants, 141 of them used by exactly one file.

**Build:** constants used by one owner move to it. Read **balance** before moving any number a player can
feel; nothing changes value.

## Remaining work: part B2 onward

The rule: a constant moves to the one source file that reads it, and the tests that read it name it
through that file's class. A constant that a function or another constant of `tuning.gd` reads stays,
because `Tuning` may not depend on a file in a folder above it. A constant only a test reads has no source
owner and stays until the test is reconsidered. Before moving, grep the name inside `tuning.gd` itself: a
doc comment naming it becomes `Owner.NAME`, a function or constant using it keeps it in `Tuning`.

Single-owner constants still in `tuning.gd`, by owner file (the crowd's and the city's are done):

- `src/day/day_controller.gd`: `FINALE_EXIT_REACH`
- `src/day/day_spec.gd`: `FINALE_BAG_EMPTY`, `FINALE_BAG_EXPLOSIONS`, `FINALE_BAG_ROADBLOCKS`, `FINALE_BAG_TRUCKS`, `FINALE_BAG_VANS`, `FINALE_SLOTS_PER_STREET`
- `src/events/checkpoint_controller.gd`: `CHECKPOINT_RELEASE_MARGIN`
- `src/events/encounter_watch.gd`: `ENCOUNTER_GAP`, `ENCOUNTER_INFLUENCE_POINTS`
- `src/events/event_catalogue.gd`: `CAR_ACCIDENT_GAPS_ARE_LETHAL`, `CAR_ACCIDENT_INTENSITY`, `CAR_ACCIDENT_LETHAL_INNER_RADIUS`, `CHARGER_WARNING`, `CHECKPOINT_DETAIN_REACH`, `FINALE_PURSUER_RESPAWN_SECONDS`, `FINALE_STEAM_BLOWS_FOR`, `OFFICER_STOP_EXCITEMENT`
- `src/events/event_def.gd`: `HEAT_PRESSES_INTENSITY`, `HEAT_PRESSES_POPULATION`
- `src/events/event_director.gd`: `RETURN_PATROLS_PER_ACT`, `RETURN_PATROL_WITHIN_THE_NEXT`, `ROUTE_BAG_MARBLES_OF`, `ROUTE_BAG_MARBLES_PER_WEIGHT`
- `src/events/event_scheduler.gd`: `CALM_ZONE_DENIAL_RATE`, `EVENT_CORRIDOR_WEIGHT`, `EVENT_PRECINCT_WEIGHT`, `EVENT_SPACING_ANY`, `EVENT_SPACING_SAME`, `EVENT_WALL_GAP_WEIGHT`, `EVENT_WALL_RIM_WEIGHT`, `GATEHOUSE_DAY_WALL_ROW_SHARE`, `OBSTRUCTION_A_PARK_CAN_HOLD`, `SPOILERS_TO_DENY_A_PARK`, `WALL_DEEP_WEIGHT`
- `src/events/mast_sites.gd`: `MAST_CALM_INTERIOR_MARGIN`, `MAST_HOME_STREET_MARGIN`
- `src/events/warning_board.gd`: `LETHAL_MARK_LEAD`
- `src/field.gd`: `FIELD_ECCENTRICITY_SPEED`
- `src/finale/finale_planner.gd`: `FINALE_PARKS_PER_CHAIN`
- `src/interior/interior_scene.gd`: `EXCITEMENT_DECAY_BASEMENT_MULTIPLIER`, `FINALE_DISTANT_FLASH_MAX_SECONDS`, `FINALE_DISTANT_FLASH_MIN_SECONDS`, `FINALE_DISTANT_FLASH_SHAPE_B`, `FINALE_WINDOW_FLASH_SECONDS`
- `src/player/baby.gd`: `EXCITEMENT_DECAY_RUNNING`, `EXCITEMENT_FROM_RUNNING`, `EXCITEMENT_NEARLY_CRYING`, `EXCITEMENT_OVERFLOW_TO_CRY`, `EXCITEMENT_OVERFLOW_WINDOW`, `EXCITEMENT_STIR_MARGIN`, `WAKE_SLEEPINESS_PENALTY`
- `src/player/stroller.gd`: `CAMERA_EASE_SECONDS`
- `src/resistance/happenings.gd`: `COLUMN_BY`, `COLUMN_WITHIN`, `MARKET_GONE_BY`
- `src/resistance/park_cordon.gd`: `PARK_CLOSING_ESCORTS`, `PARK_CLOSING_LEAVE_SPEED`, `PARK_CLOSING_OFFICER_SPEED`, `PARK_CLOSING_SECONDS`, `PARK_CLOSING_STRETCH_MIN`, `PARK_CLOSING_WARNING`
- `src/resistance/resistance_director.gd`: `NEIGHBOR_WALK_HOME_SECONDS`
- `src/resistance/resistance_steps.gd`: `MAST_WITHIN_THE_NEXT`, `VAN_WITHIN_THE_NEXT`
- `src/routes/closure_planner.gd`: `CLOSURE_GAP_BIAS`, `CLOSURE_WALL_BIAS`, `GATEHOUSE_DAY_CLOSURE_SHARE`
- `src/routes/seal_planner.gd`: `GATEHOUSE_DAY_SEAL_SHARE`, `SEAL_THINNING_FRACTION`
- `src/run_config.gd`: `FINALE_LENGTH_SECONDS`

Read by one source file but kept in `Tuning` because a function or constant of `tuning.gd` reads them:
`CALM_ZONE_BLOCKS` and `DEGRADATION_FIRST_DAY` (city) and `CROWD_PEDESTRIANS_PER_ACT` (crowd); and the three signal
timings `SIGNAL_PROGRESSION_BLOCKS`, `SIGNAL_AMBER_SECONDS` and `SIGNAL_SIDE_GREEN_SECONDS` (city), which
`signal_cycle_seconds()` and `signal_main_green_seconds()` read. They leave when those functions do, with
the owner of the signal cycle.

Read by tests only: `FINALE_DISTANT_FLASH_MEAN_SECONDS` (`tests/test_interior.gd`) and
`SLEEPINESS_CALM_ZONE_MULTIPLIER` (`tests/test_meters.gd`, also read by `sleepiness_calm_multiplier()`).
Read by no file outside `tuning.gd`: `CLOSURES_PER_ACT`, `CROWD_CARS_PER_ACT`, `CURFEW_DAY_LENGTH_SECONDS`,
`PURSUIT_MIN_MARGIN`, `TELEGRAPH_HARD_FAIL_MARGIN` and `TELEGRAPH_TIME_DEFAULT`, which only `tuning.gd`'s
own functions read or nobody does.
