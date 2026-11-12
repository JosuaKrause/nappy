# minty-quail — The developer's rigs are typed · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell ("it should be made working",
inbox #1268 in olive-ferret), and code is typed where it can be ("we type when we can", inbox #1280 in
olive-ferret): `field-reads.md` with `typed-everywhere.md`, one pass per module. This pass is the developer's rigs
under `src/dev/`: the auto-screenshot, the debug layers, the debug readout and the dev flags. Its search is none: it
types and deletes lines and converts no read.

## What was built

- **Four files parse without their file-level opt-out line**: `src/dev/auto_screenshot.gd` (`untyped_declaration`),
  `debug_layers.gd` (all three), `debug_readout.gd` (`unsafe_method_access`) and `dev_flags.gd`
  (`untyped_declaration`, `unsafe_method_access`); none after.
- **Typing**: the auto-screenshot's press-then-release loops as `bool`; the dev flags read a scene recipe's nested
  `setup` and `progression` dictionaries through a typed `Dictionary` name before `.get()`, defaults unchanged, and
  loop their rig flags as `String`; the readout reads the day phase's and the tile type's enum keys into a `String`
  before lowering them; the debug layers loop their outline pairs as `Array`, read the props as the `Array[Node2D]`
  `City.props()` answers (the city frees its old props and clears the list in one place, so no freed prop is in it),
  and read collision nodes and shapes through a cast to the class each branch has just tested with `is`.
- **The debug layers take an `EventManager`.** Their event source (`_events` and `setup()`'s parameter) was a `Node`
  they duck-typed; every game caller hands an `EventManager` (`DebugReadout.show_the_world()` already takes one, and
  `main._event_source()` answers the city's or the building's manager), and the two doc comments no longer call it
  duck-typed. The one stand-in that handed a bare `Node`, `_Source` in `tests/test_wall_shield.gd`, extends
  `FakeEventManager` and says it overrides `EventManager.instances`, as a fake extends the class it stands in for
  (writing-tests) and as the telemetry pass did for its observer's source; it is the one file outside the list this
  pass changes, the builder's choice over keeping `unsafe_method_access` on the file.
- **Left, no read converted**: the rigs' event reads (`def`, `is_finished`, `age`, `excitement`, `pursuit` and the
  rest), for row 3c of `event-interface.md`; the other fields the list below names, each for its own module's pass.

## Fields read and written, by class

`tools/field_answers.py` on the four files, as it prints them at 43f37d479, each named method read in its class.

Fields of classes under `src/` that `src/dev/auto_screenshot.gd`, `src/dev/debug_layers.gd`, `src/dev/debug_readout.gd`, `src/dev/dev_flags.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `Baby`: `excitement` read (`src/dev/debug_readout.gd`:455): `excitement_level()` (7 calls); `last_decay` read (`src/dev/debug_readout.gd`:291,292): no method; `last_incoming` read (`src/dev/debug_readout.gd`:290,292): `last_frame_incoming()` (1 call); `sleepiness` read (`src/dev/debug_readout.gd`:455): `sleepiness_level()` (6 calls)
- `CrowdAgent`: `excitement` read (`src/dev/debug_layers.gd`:212,213,217): `mood()` (6 calls)
- `DayController`: `phase` read (`src/dev/debug_readout.gd`:277): no method; of it alone, `is_running()` returns `phase != GameEnums.DayPhase.OVER` (10 calls, +6 own); `time_remaining` read (`src/dev/debug_readout.gd`:279): `seconds_left()` (5 calls)
- `DaySpec`: `closes_streets` read (`src/dev/debug_readout.gd`:174): `closes_the_streets()` (4 calls); `number` read (`src/dev/debug_readout.gd`:272): `day_number()` (12 calls); `section` read (`src/dev/debug_readout.gd`:272): `section_kind()` (12 calls); `title` read (`src/dev/debug_readout.gd`:273): no method
- `EventDef`: `inner_radius` read (`src/dev/debug_layers.gd`:184,197): `core_within()` (1 call); `outer_radius` read (`src/dev/debug_layers.gd`:184): `heard_within()` (4 calls); `pursuit` read (`src/dev/auto_screenshot.gd`:406): no method; `shape` read (`src/dev/debug_layers.gd`:404): `ground_shape()` (10 calls)
- `EventInstance`: `age` read (`src/dev/debug_readout.gd`:364): on its view, `EventInstance.Figure.age()` (13 calls), a view no public method hands out; `def` read (`src/dev/auto_screenshot.gd`:406; `src/dev/debug_layers.gd`:174,184,197,404; `src/dev/debug_readout.gd`:362,364): `row()` (2 calls); `def.hard_fail` read (`src/dev/debug_layers.gd`:174): `ends_the_day()` (1 call); `def.id` read (`src/dev/debug_readout.gd`:362): `row_id()` (11 calls); `def.telegraph_time` read (`src/dev/debug_readout.gd`:364): `telegraphs_for()` (1 call); `excitement` read (`src/dev/debug_layers.gd`:176): `source()` (16 calls); `is_finished` read (`src/dev/debug_layers.gd`:172,402): `is_gone()` (20 calls, +1 own)
- `FrameGraph`: `text_colour` written (`src/dev/debug_readout.gd`:234): no method
- `GroundShape`: `half_length` read (`src/dev/debug_layers.gd`:183): `spine_half_length()` (2 calls)
- `LaneMover`: `kind` read through `CrowdAgent` (`src/dev/debug_layers.gd`:203,406,453): on its view, `lane().kind()` (8 calls); `shape` read through `CrowdAgent` (`src/dev/debug_layers.gd`:407): on its view, `lane().shape()` (4 calls)
- `Prop`: `shape` read (`src/dev/debug_layers.gd`:413): no method
- `RunConfig`: `active_args` read (`src/dev/auto_screenshot.gd`:171): `dev_flag_words()` (1 call); `debug_build` read (`src/dev/debug_readout.gd`:104): `is_debug_build()` (3 calls); `layers_override` read (`src/dev/debug_readout.gd`:107): no method; `player_view_requested` read (`src/dev/debug_readout.gd`:108): no method; `readout_requested` read (`src/dev/debug_readout.gd`:105,108): `asks_for_the_readout()` (1 call); `recording` read (`src/dev/auto_screenshot.gd`:174): no method; `screenshot_path` read (`src/dev/auto_screenshot.gd`:173): no method; `skip_words` read (`src/dev/debug_readout.gd`:106): no method; `spikes_requested` read (`src/dev/debug_readout.gd`:109): no method
- `RunHeader`: `day` read (`src/dev/debug_readout.gd`:272): no method; `run_seed` read (`src/dev/debug_readout.gd`:271): no method
- `Stroller`: `carrying` read (`src/dev/debug_layers.gd`:417): no method; `pram_shape` read (`src/dev/debug_layers.gd`:418): no method; `shape` read (`src/dev/debug_layers.gd`:414): no method


## Verified

At parity: `tools/check.sh` boots clean before and after the merge of main; the field-read check against `origin/main`
passes with `tools/field_reads.txt` unchanged; the typing census and the layer check pass; the rigs' suites and the
building's, which stands the debug layers up over the building, pass; CI is green.
