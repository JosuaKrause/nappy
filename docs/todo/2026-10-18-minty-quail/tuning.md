# Tuning holds shared balance numbers only

`src/autoload/tuning.gd` holds the balance constants, and every one that exactly one source file reads
still sits there. Count them with the rule below, not from a number written here.

**Build:** constants used by one owner move to it. Read **balance** before moving any number a player can
feel; nothing changes value.

## The rule

Only files under `src/` count toward ownership, and a comment is not a use. A constant moves to the one
`src/` file that reads it, and the tests and probes that read it name it through that file's class. A
constant stays in `Tuning` when a function or constant of `tuning.gd` itself reads it, because `Tuning` may
not depend on a file in a folder above it. A constant that only tests read has no owner and stays. Before a
move, grep the name inside `tuning.gd`: a doc comment naming it becomes `Owner.NAME`.

## Remaining work

Single-owner constants still in `tuning.gd`, by owner file, 50 in all (resistance 13, player 12,
day 7, routes 7, interior 5, finale 2, `src/` root 2, visuals 1, world 1):

- `src/day/day_controller.gd`: `FINALE_EXIT_REACH`
- `src/day/day_spec.gd`: `FINALE_BAG_EMPTY`, `FINALE_BAG_EXPLOSIONS`, `FINALE_BAG_ROADBLOCKS`, `FINALE_BAG_TRUCKS`, `FINALE_BAG_VANS`, `FINALE_SLOTS_PER_STREET`
- `src/field.gd`: `FIELD_ECCENTRICITY_SPEED`
- `src/finale/building_plan.gd`: `FINALE_STEAM_PERIODS`
- `src/finale/finale_planner.gd`: `FINALE_PARKS_PER_CHAIN`
- `src/interior/interior_scene.gd`: `EXCITEMENT_DECAY_BASEMENT_MULTIPLIER`, `FINALE_DISTANT_FLASH_MAX_SECONDS`, `FINALE_DISTANT_FLASH_MIN_SECONDS`, `FINALE_DISTANT_FLASH_SHAPE_B`, `FINALE_WINDOW_FLASH_SECONDS`
- `src/player/baby.gd`: `EXCITEMENT_DECAY_IDLE`, `EXCITEMENT_DECAY_RUNNING`, `EXCITEMENT_FROM_ALLEY`, `EXCITEMENT_FROM_RUNNING`, `EXCITEMENT_NEARLY_CRYING`, `EXCITEMENT_OVERFLOW_TO_CRY`, `EXCITEMENT_OVERFLOW_WINDOW`, `EXCITEMENT_STIR_MARGIN`, `SLEEPINESS_DRAIN_IDLE`, `SLEEPING_SENSITIVITY`, `WAKE_SLEEPINESS_PENALTY`
- `src/player/stroller.gd`: `CAMERA_EASE_SECONDS`
- `src/resistance/happenings.gd`: `COLUMN_BY`, `COLUMN_WITHIN`, `MARKET_GONE_BY`
- `src/resistance/park_cordon.gd`: `PARK_CLOSING_ESCORTS`, `PARK_CLOSING_LEAVE_SPEED`, `PARK_CLOSING_OFFICER_SPEED`, `PARK_CLOSING_SECONDS`, `PARK_CLOSING_STRETCH_MIN`, `PARK_CLOSING_WARNING`
- `src/resistance/resistance_director.gd`: `NEIGHBOR_WALK_HOME_SECONDS`
- `src/resistance/resistance_steps.gd`: `MAST_WITHIN_THE_NEXT`, `TASK_CONTACT_WITHIN_THE_NEXT`, `VAN_WITHIN_THE_NEXT`
- `src/routes/closure_planner.gd`: `CLOSURE_GAP_BIAS`, `CLOSURE_WALL_BIAS`, `GATEHOUSE_DAY_CLOSURE_SHARE`, `MIN_CALM_AREAS_REACHABLE`
- `src/routes/seal_planner.gd`: `ALLEY_MOUTH_SEAL_CHANCE`, `GATEHOUSE_DAY_SEAL_SHARE`, `SEAL_THINNING_FRACTION`
- `src/run_config.gd`: `FINALE_LENGTH_SECONDS`
- `src/visuals/ground_layers.gd`: `ROUTE_KERB_TINT_ALPHA`
- `src/world/give_way.gd`: `CAR_ZEBRA_WAIT_RADIUS`

Read by one `src/` file and kept because `tuning.gd` reads them: `SLEEPINESS_GAIN_WALKING`,
`DAY_LENGTH_SECONDS`, `OFFSCREEN_WARNING_MIN`, `PURSUIT_SHAKEN_OFF`, `CALM_ZONE_BLOCKS`,
`DEGRADATION_FIRST_DAY`, `SIGNAL_SIDE_GREEN_SECONDS` and `SIGNAL_AMBER_SECONDS`. They leave when the
function that reads them leaves `tuning.gd`.

Read by no `src/` file (only tests, or only `tuning.gd`'s own code): `SLEEPINESS_CALM_ZONE_MULTIPLIER`,
`FINALE_DISTANT_FLASH_MEAN_SECONDS`, `TELEGRAPH_TIME_DEFAULT`, `TELEGRAPH_HARD_FAIL_MARGIN`,
`CURFEW_DAY_LENGTH_SECONDS`, `SIGNAL_PROGRESSION_BLOCKS`, `CLOSURES_PER_ACT`, `CROWD_PEDESTRIANS_PER_ACT`,
`CROWD_CARS_PER_ACT` and `PURSUIT_MIN_MARGIN`.
