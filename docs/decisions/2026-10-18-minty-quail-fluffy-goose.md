# minty-quail — A row is written through a draft (row 4b) · 2026-11-22

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus; this
is its ninth pull request, "a row is written through a draft", built as #1629 by Sonnet agents one part per turn (the
source, the tests, the checks and loose ends, the docs), with a measuring agent for the parity.

**What was built.** `EventDraft` (`src/events/event_draft.gd`, data) is the one way a row is made: one statement per
setting and per part, then `build()`, which does not validate. `EventDef` extends `RefCounted`, is built from a draft,
keeps it and is never changed after; `redraft()` copies the kept draft (the design's fork F4), so the heated shape, the
copy for a later day, the copy sent ahead and the one warned first are each a redraft with the parts they differ in
written over it, and so are the catalogue's derived rows and the five copies outside it (the seal planner's three,
through a public `SealPlanner.sealed_draft()`; the director's ground copy; the raid's pacing patrol). Every part extends
`RefCounted`; every `@export`, the eight `use_<part>()` writers and the other writers on the row are gone. The catalogue
is rewritten by `convert_catalogue_draft.py`, kept with the design. The row's own settings stay fields for one more pull
request, written only from the draft. The tests build their rows with a draft; three that wrote a shared or live row get
rows of their own (a test dawn handed a row, `game_dawn.with_row()`; a planner stand-in in the escape-stairwell probe).
The docs and the events skill say how a row is written now; the skill's "Adding a row" changed, which the player was
told on the board.

**A check that became unwritable, and one held elsewhere.** A deep copy that loses the body cannot be made (a row is not a
`Resource` and has no deep copy), which the test says where its source scan stays. The excitement source's check that a
cached rate goes stale until invalidated is held by `tests/test_masts.gd` (silencing a mast answers zero in the same
tick, not the cache), which fails with the invalidation deleted; the check in `test_excitement_source.gd` that stood in for it held nothing and is gone.
`test_acts` holds what the game reads: a scripted row's first day is not after the day it fires on; a non-scripted row's
act has no reader, which row 4b's line in `event-interface.md` leaves to the next step.

**The event names, deleted with `display_name`.** `Texts.EVENT_NAMES` held a display name per row, read by nothing but
the catalogue's own writes of `display_name`, which nothing read (event-interface section 7, point 6). Kept here, since
they are written text: `neighbor` "Neighbor", `playground` "Playground", `cat_dash` "Cat", `alley_mouse` "Mouse",
`homeless_yeller` "Man shouting", `dog_walker` "Dog walker", `cafe_tables` "Café tables", `delivery_van` "Delivery van",
`busker` "Busker", `construction` "Roadworks", `fire_truck` "Fire engine", `burning_building` "Burning building",
`burnt_shell` "Burnt-out building", `loose_dog` "Loose dog", `market_stall` "Market stall", `leaf_blower` "Leaf blower",
`pigeon_flock` "Pigeons", `cyclist` "Cyclist", `ice_cream_van` "Ice cream van", `reversing_lorry` "Reversing lorry",
`chatting_mother` "Another mother", `charging_dog` "Charging dog", `police_patrol` "Patrol", `poster_crew` "Poster
crew", `poster_crew_square` "Poster crew", `loudspeaker` "Loudspeaker mast", `curfew_announce` "Curfew announcement",
`roadblock` "Roadblock", `abduction` "Unmarked van", `alley_robbery` "Robbery", `robber_giving_chase` "Robber giving
chase", `van_guard_giving_chase` "Van guard giving chase", `policeman_giving_chase` "Policeman giving chase",
`guardsman_giving_chase` "Guardsman giving chase", `night_raid` "Raid", `military_convoy` "Convoy", `barricade`
"Barricade", `protest` "Protest", `firefight` "Firefight", `fallen_tree` "Fallen tree", `car_accident` "Car accident",
`skip` "Skip", `scaffolding` "Scaffolding", `burst_water_main` "Burst water main", `moving_van` "Moving van",
`burnt_out_car` "Burnt-out car", `collapsed_frontage` "Collapsed frontage", `checkpoint_hut` "Checkpoint hut",
`checkpoint_gate` "Checkpoint gate", `checkpoint_post` "Checkpoint guard", `door_guard` "Guard giving chase",
`finale_explosion` "Explosion", `impact_crater` "Crater", `masked_pursuer` "Masked man", `basement_steam` "Steam".

**Measured.** On main and the branch, every probe prints the same but timings, except the 55 `display_name` lines and
the hashes and counts that follow from them: the row fingerprint over every row, every copy and the planners' 239 plans
(their full lines compared, not only the hashes), the look, excitement and placement fingerprints, `placement_rows.gd`,
`escape_density.gd`, `curly_stork_piece_layout.gd`; no cost figure moved. With the row keeping its draft, the row
fingerprint also prints the kept draft's lines; every other line matches.

**Open to overturn:** the design's forks; the writers `hunting(spec)` and `not_sited_from_her_walk()`;
`SealPlanner.sealed_draft()` public and `alley_mouth_wall()` handed the sealed row; the test dawn's `with_row()`; the
tutorial dog's day switch after the last day.
