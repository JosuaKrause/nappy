# minty-quail — The run's parts and the run log's session are typed · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell ("it should be made working",
inbox #1268 in olive-ferret), and code is typed where it can be ("we type when we can", inbox #1280 in
olive-ferret): `field-reads.md` with `typed-everywhere.md`, one pass per module. This pass is the run's parts
(`src/run/`) and the run log's session (`src/telemetry/run_session.gd`). Its search is none: it types and deletes
lines and converts no read; the parts' vars are renamed later, by `field-reads.md`'s "A run's parts".

## What was built

- **Six files parse without their file-level opt-out line**: `src/run/run_state.gd` and `resistance_run_state.gd`
  (`untyped_declaration`), `run_calendar.gd`, `run_facts.gd` and `attempt_spend_state.gd` (`unsafe_method_access`),
  and `src/telemetry/run_session.gd` (`unsafe_property_access`, `unsafe_method_access`); none after. No method is
  added, no var renamed, and no other file changes.
- **Typing**: `RunState.snapshot_is_complete()` loops over the registry's save keys as `String`, every part writing
  its keys as string literals; `RunCalendar._end_run()` reads the ending's enum key into a `String` before
  lowering it, the run log's `ending` line unchanged; `AttemptSpendState.record_scar()` reads a scar's position
  `as Vector2`, what every writer stores; `RunFacts.restore()` reads the fenced park through a typed `Dictionary`
  local inside its `is Dictionary` guard; `RunSession.setup()` types its bus as the `event_bus.gd` script through a
  preload, as `src/autoload/visit_counter.gd` does, both callers (`main.gd` and `tests/test_burst_capture.gd`) handing
  it the `EventBus` autoload.
- **A save's numbers stay untyped on the way in.** `ResistanceRunState._to_int_array()`, part of `restore()`, keeps
  its loop variable `Variant`: the save is JSON, so step numbers come back as floats in an untyped array, and
  `int(value)` converts each into the typed `Array[int]` the function builds, as before.
- **Left**, every read already listed in `tools/field_reads.txt`: the run's parts (`RunState.header`, the fields of
  `RunHeader`, `ResistanceRunState`, `RunCalendar`, `RunFacts.escape_section`, `SettledState.settled_in`), for "A run's
  parts", the whole-part `reset()`, `give_back()` and `restore()` the tool names answering no single-field write and
  `RunCalendar.choose_mode()` not answering `RunState.start_run()`'s two writes at parity (it clears the checkpoint
  only in hard mode and writes a run-log line); `City.map`, `City.crowd` and `Crowd.sources`, read by the session, for
  the city's and the crowd's passes; `DaySpec`'s fields, `ResistanceSteps.Step.index` and `RunConfig`'s two flags, for
  their modules' passes.

## Fields read and written, by class

`tools/field_answers.py` on the six files, as it prints them at 5bccdc196, each named method read in its class.

Fields of classes under `src/` that `src/run/run_state.gd`, `src/run/run_calendar.gd`, `src/run/run_facts.gd`, `src/run/attempt_spend_state.gd`, `src/run/resistance_run_state.gd`, `src/telemetry/run_session.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `City`: `crowd` read (`src/telemetry/run_session.gd`:154): no method; `map` read (`src/telemetry/run_session.gd`:146,153,181,184,208): no method
- `Crowd`: `sources` read (`src/telemetry/run_session.gd`:154): no method
- `DaySpec`: `a_loss_gives_back_the_attempt` read (`src/run/run_calendar.gd`:202,224): no method; `a_win_gives_a_nerve_back` read (`src/run/run_calendar.gd`:237): no method; `a_win_leads_into` read (`src/run/run_calendar.gd`:229): no method; `title` read (`src/telemetry/run_session.gd`:143): no method
- `ResistanceRunState`: `carrying_package` written (`src/run/run_calendar.gd`:103): `reset()` does `carrying_package = false` (3 calls), `give_back()` does `carrying_package = _dawn_carrying_package` (1 call), `restore()` does `carrying_package = bool(data["…"])` (3 calls); `completed_steps` read (`src/run/run_state.gd`:113,128,130): no method; `failed_steps` read (`src/run/run_state.gd`:138,140): no method; `progress` read (`src/run/run_calendar.gd`:293,309,325,342,345,346; `src/run/run_state.gd`:103,117,133): no method; `progress` written (`src/run/run_state.gd`:132): `reset()` does `progress = 0` (3 calls), `give_back()` does `progress = _dawn_progress` (1 call), `restore()` does `progress = int(data["…"])` (3 calls); `sabotage_done` read (`src/run/run_calendar.gd`:310,325): no method
- `ResistanceSteps.Step`: `index` read (`src/run/run_state.gd`:113): no method
- `RunCalendar`: `checkpoint` written (`src/run/run_state.gd`:93): `choose_mode()` does `checkpoint = {}` (2 calls); `hard_mode` written (`src/run/run_state.gd`:92): `choose_mode()` does `hard_mode = hard` (2 calls)
- `RunConfig`: `no_telemetry` read (`src/telemetry/run_session.gd`:78): no method; `spikes_requested` read (`src/telemetry/run_session.gd`:128): no method
- `RunFacts`: `escape_section` written (`src/run/run_calendar.gd`:303): `reset()` does `escape_section = 0` (3 calls), `restore()` does `escape_section = int(data.get("…", 0))` (3 calls)
- `RunHeader`: `day` read (`src/run/run_calendar.gd`:76,78,87,89,145,148,214,215,225,281,295,296,308,317,320,353; `src/run/run_state.gd`:98,110): no method; `day` written (`src/run/run_calendar.gd`:242): `reset()` does `day = 1` (3 calls), `restore()` does `day = int(data["…"])` (3 calls); `ending` written (`src/run/run_calendar.gd`:299): `reset()` does `ending = GameEnums.Ending.NONE` (3 calls), `restore()` does `ending = int(data["…"]) as GameEnums.Ending` (3 calls); `nerves` read (`src/run/run_calendar.gd`:136,201,214,215,217,218,254,256,292): no method; `nerves` written (`src/run/run_calendar.gd`:200,255,291): `reset()` does `nerves = Tuning.STARTING_NERVES` (3 calls), `restore()` does `nerves = int(data["…"])` (3 calls); `play_ticks` read (`src/run/run_calendar.gd`:284): no method; `play_ticks` written (`src/run/run_calendar.gd`:290): `reset()` does `play_ticks = 0` (3 calls), `restore()` does `play_ticks = roundi(float(data["…"]) * Engine.physics_ticks_per_second)` (3 calls); `player_is_male` written (`src/run/run_state.gd`:88): `restore()` does `player_is_male = bool(data["…"])` (3 calls); `run_seed` read (`src/run/run_calendar.gd`:355; `src/run/run_state.gd`:94,149; `src/telemetry/run_session.gd`:143,145): no method; `run_seed` written (`src/run/run_state.gd`:87): `restore()` does `run_seed = int(data["…"])` (3 calls)
- `RunState`: `header` read (`src/telemetry/run_session.gd`:143,145): no method
- `SettledState`: `settled_in` read (`src/run/run_calendar.gd`:79,87,225): no method; `settled_in` written (`src/run/run_calendar.gd`:89): `restore()` does `settled_in[int(raw["…"])] = Vector2i(int(raw["…"]), int(raw["…"]))` (3 calls)


## Verified

At parity: `tools/check.sh` boots clean; the field-read check against `origin/main` sees no new read; the typing census
and the layer check pass; the run's suites pass, and so does the whole suite, run once locally since `RunState` reaches
most suites; CI is green.
