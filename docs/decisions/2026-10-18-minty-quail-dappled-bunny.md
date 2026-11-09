# minty-quail — Field reads outside the city, events and routes are converted behind methods (minty-quail, field-reads) · 2026-11-08

The second pull request of `field-reads`' conversion (the first area was the events and the
city): it converts the reads of every owner class that lives outside `src/city/`, `src/events/`,
`src/routes/` and `src/dev/`, so that one object asks another through a method and never reads or
writes its field (designing-classes, "Fields are not API"; inbox #1173 in gray-dolphin). Nothing
behaves differently: the run log of the observers' baseline is unchanged, and the suites for every
touched file pass.

## What was converted

145 lines of `tools/field_reads.txt` are gone, by the owner class read:

| Owner class | Lines converted | Of its lines |
|---|---|---|
| WorldMap | 16 | 43 |
| RunConfig | 14 | 35 |
| CarTurn | 13 | 13 |
| MoveProposal | 11 | 19 |
| AttemptSpendState | 8 | 12 |
| DayEnd | 8 | 19 |
| CrowdField | 7 | 7 |
| DaySpec | 7 | 54 |
| SummaryModel | 7 | 7 |
| WalkField | 6 | 6 |
| Baby | 5 | 16 |
| CrowdAgent | 5 | 9 |
| GroundShape | 5 | 20 |
| ScreenCover | 5 | 5 |
| DayController | 4 | 16 |
| Mover | 4 | 6 |
| FrameTiming | 3 | 6 |
| Sitting | 3 | 3 |
| Stroller | 3 | 12 |
| FrameTraceBuffer | 2 | 2 |
| WalkerDoorHold | 2 | 2 |
| BadgeModel, CrowdExcitement, ExcitementSource, Footprint, ModeButton, ParkCordon, ResistanceHappenings | 1 each | |

## The names chosen, and why

A method is named for what the caller wants out of the object, not `get_x()`, and cannot share the
field's name in GDScript, so where the field stays (a test writes it, or a fenced file still reads
it) the method says the question: `Baby.is_awake()` and `is_asleep()` in place of
`state == AWAKE`, `DayEnd.sends_the_run_back()` and `ends_the_run()`, `Mover.layers_blocked()`,
`CarTurn.exits_vertically()`, `WorldMap.size_in_tiles()`, `WalkField.swept_for()` (the whole
"was this field swept from exactly these targets" question, which the resistance director used to
work out from the field's anchors), `AttemptSpendState.has_scar()`, `scar_position()`,
`scar_positions()` and `record_scar()` (the scar list's one rule, "no second scar within a pixel",
moved from `RunState.add_scar()` to the list's owner), `FrameTraceBuffer.is_full()` and
`drop_one()`. A part an object holds (`CrowdAgent.mood()`, `AttemptSpendState.block_arcs()`) is
handed out through a method so that the chain `agent.mood().startle(...)` is two method calls.
`RunConfig` answers each flag as a question (`is_headless()`, `refuses_saving()`,
`forces_touch()`).

A field went underscore-private where nothing outside its class reads it any more
(`FrameTraceBuffer`'s count and drops, `Footprint`'s pieces, `ParkCordon`'s trace,
`RunConfig`'s web-debug flag, `Sitting`'s record path), and stayed public where a test, or a file
this change does not touch, still reads it.

A test that read a field this change left with no reader in `src/` reads the new method instead
(`tools/check_test_only_members.py` would fail it as a test-only member), in `crowd_rig`,
`test_summary_model`, `test_run_config`, `test_presentation_mode`, `test_badge_model` and the
other suites that named it. One assertion changed meaning: `test_badge_model`'s check that the
single badge's seconds-left sorted first now checks that it is the one badge on the edge,
because the seconds are internal to the model and sorting is checked by the test that follows it.

## Skipped, and why

- **The fence** (placement is being rewritten, and the third hand-ins pull request is to come):
  every line whose owner or reader file is under `src/events/`, `src/routes/` or `src/dev/`, a
  `scene_recipe*` file, `event_director.gd`, `tuning.gd`, `day_director.gd`, `main.gd`,
  `day_planner.gd`, `run_session.gd`, the event manager and `EventWorld`, the scenery residency,
  the blackout. A field those files still read stays public for them, so some groups above are
  converted in part (`DaySpec`, `RunConfig`, `MoveProposal`, `WorldMap`).
- **`LaneMover` (63 lines) and `LaneStrategy` (7)**: the car and walker strategies are written as
  the mover's inner halves and read its underscore fields (`_map`, `_lane`, `_junction`, `_speed`)
  and its callables (`gap_ahead`, `pockets`) directly. A method per field would be a second copy
  of the class's insides; the fork is whether a strategy is handed a narrow interface (the lane
  state it may read) instead.
- **`RunState`, `RunHeader`, `RunCalendar`, `ResistanceRunState`, `RunFacts`, `SettledState`
  (about 75 lines)**: `RunState` states that its parts are its API (`run.header.day`, and "nothing
  forwards to a part"), and a read through a part is two field reads, the part and then its field.
  Converting it is the design question whether a run's parts become methods and what the part
  objects' own questions are named.
- **`InteriorMapPlan` (24)**: a plan whose tiles, doors and decals tests read 72 times and a
  builder writes; converted with the plan's builder.
- **`BlockedLayer` (5)**: `CityMap` and `WorldMap` wrap its dictionaries in property setters, so a
  method per field is the property redesigned.
- **`atlas` (about 16 lines across `CrowdAgent`, `HelpText`, `ModeButton`, `CordonTape`,
  `CordonOfficer`, `ContactPoint`)**: an atlas is injected by `node.atlas = atlas` in the owner,
  the city and 40 test lines; it is one design (a `use_atlas()` on each, or a node handed its
  atlas at construction), not six.
- **Writes onto configured nodes** (`CordonTape.length`/`across`/`piece`, `ContactPoint.reach`,
  `by_crossing`, `touch_ellipse`, the resistance director's own setup of them): converted with a
  setup method per node, with the atlas.
- **Residue of a half-converted group**: `WorldMap`'s other fields (`separation`, `moves`,
  `day_record_version`, `obstruction_version`, `obstructed_tiles`, `world`), `Stroller`'s, `Baby`'s,
  `GroundShape`'s and `DayController`'s other fields.
