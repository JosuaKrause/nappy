extends Node
## Global signal hub.
##
## Systems talk through here instead of holding references to each other, so an event type
## never needs to know the baby exists and the HUD never needs to know the city exists.

# ------------------------------------------------------------------- meters ---

signal sleepiness_changed(value: float)
signal excitement_changed(value: float)
signal baby_state_changed(state: GameEnums.BabyState)

# ---------------------------------------------------------------- day / run ---

## A run's very first frame with `GameState` settled — fresh (`resumed` false, always day 1) or
## picked back up from the save (`resumed` true, `day` whichever it was written on). `main._ready()`
## is the one emitter, for the ordinary boot and for a game reopened mid-escape alike. Read by
## `VisitCounter`, which is the only listener today — see docs/TELEMETRY.md, "The page counts
## visits".
signal run_begun(day: int, resumed: bool)
## A day begins — its first attempt or a retry — before anything is placed in it, so a listener
## clears yesterday's state first. `DayDirector.start_day()` and `main`'s recipe day are the emitters, and
## `main._start_section()` for each of the escape's two sections, a day of its own under its own
## number after the last (`DaySpec.number`).
signal day_started(day: int)
## Everything the day holds is placed: its closures, its calm, its plan, the resistance's contact and
## her on the doorstep — or an escape section's world and her at its start. `DayDirector.start_day()` and
## `main._start_section()` are the emitters; the run log writes the day's plan lines, its dawn map
## and her `start` line here (`RunSession`).
signal day_planned(day: int)
signal day_time_changed(remaining: float, total: float)
signal return_phase_started() ## Baby is asleep; walk home.
signal nerves_changed(nerves: int)
## One attempt at `day` is over: its `GameEnums.DayResult` (`WON` included), what ended it and when.
## `cause` is what filled the meter or struck her on a crying or hard-fail day, named by the game
## where the moment happened — `car` for the one hard fail that is not a catalogue row, otherwise
## the row's id hyphenated (`charging-dog`, `pelican` for a pelican rather than its row's
## `cyclist`), and for crying whichever of `crowd`, `traffic`, `self` or a row landed the most on
## her — and "" for a win or a timeout, whose result already says everything. `elapsed` is the
## day's clock at the instant it ended. The run log's `lost` line and the page's loss name both
## read `cause` from here, so the two name a lost day the same way.
##
## Emitted by `DayDirector.finish_day()` once the charges still running are closed and above the
## calendar move `GameState.calendar.finish_day()` makes a moment later, so a lost day's retry and a won
## day's next dawn are both still "day N" here. Fires once per attempt, as `day_started` does: a
## retry begins and ends this pair again for the day it repeats — an escape section's included,
## under its own number.
signal day_ended(day: int, result: GameEnums.DayResult, cause: String, elapsed: float)
## The held restart — the pause screen's or the day summary's own button — with the day it
## abandoned. `run_ended` below is the run finishing on its own terms; this is the player leaving
## one early.
signal run_restarted(day: int)
signal run_ended(ending: GameEnums.Ending)
## A fresh run's mode, the moment the title that chose it is dismissed — `hard` is the Hard Mode
## checkbox's answer — with `day`, the day already begun behind the title. Never for a resumed run,
## whose mode was chosen when it began. `main._on_title_start()` is the one emitter. Listen-only,
## for `VisitCounter` — see docs/TELEMETRY.md, "The page counts visits".
signal run_mode_chosen(hard: bool, day: int)
## A normal run spent its last nerve on `lost_day` and went back to its checkpoint, `day` — 1 for
## checkpoint zero, otherwise 4, 8 or 12 — with every nerve. Emitted by `GameState.calendar.finish_day()`
## once the checkpoint is restored. Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The
## page counts visits".
signal went_back_to_a_checkpoint(day: int, lost_day: int)
## `GameSave.write()`'s own moment a save was actually written — never a refused write (a dev or
## headless run, or a run that has already ended), which changes nothing. `result` is a
## `GameSave.Result` passed as `int`, for the same cross-script-enum reason `save_deleted` below
## passes its own: `PENDING` on the web while IndexedDB has not yet said whether it kept the save
## (`save_write_settled` follows), `CONFIRMED` or `FAILED` otherwise. Emitted by `GameSave` itself,
## which is what lets the save symbol answer a save that outlives the `main` that made it: a
## callable bound to `main` is dropped once a scene reload frees it, and a symbol never told would
## stay fully shown for good. Heard by `SaveIndicator`. `operation` is the write's own id from
## `GameSave._new_operation()`, larger for every change begun later, and carried again on its answer:
## only the newest change decides what the symbol shows, and an answer is tied to its change by it.
signal save_written(operation: int, result: int)
## The browser's answer to a write `save_written` announced as `PENDING`, with that write's
## `operation`: `kept` is whether IndexedDB kept the save. Emitted once per pending write, and only
## for those.
signal save_write_settled(operation: int, kept: bool)
## `GameSave.clear()`'s own moment a save file was actually deleted — never a refused deletion (a
## dev or headless run, or no file left to delete), which changes nothing. `result` is a
## `GameSave.Result` passed as `int`, since a cross-script enum is not the same type as itself as
## a parameter (the **godot** skill): `PENDING` on the web while IndexedDB has not yet said whether
## it dropped the file (`save_deletion_settled` follows), `CONFIRMED` or `FAILED` otherwise.
## Emitted by `GameSave` itself, so the deletion `GameState._end_run()` makes — an autoload with no
## way to reach `main`'s indicator — shows the save symbol exactly as the held restart's does.
## Heard by `SaveIndicator`, which outlives the `main` that raised it when the held restart reloads
## the scene. `operation` is the deletion's own id, drawn from the same sequence a write's is — see
## `save_written`.
signal save_deleted(operation: int, result: int)
## The browser's answer to a deletion `save_deleted` announced as `PENDING`, with that deletion's
## `operation`: `kept` is whether IndexedDB dropped the file. Emitted once per pending deletion, and
## only for those.
signal save_deletion_settled(operation: int, kept: bool)

# ------------------------------------------------------------------- events ---
# `instance` is an `EventInstance`, left untyped: this autoload is loaded before the class is.

signal event_telegraphed(instance)
signal event_activated(instance)
signal hard_fail_triggered(reason: String)
## `EventSpawner.summon_what_has_been_sighted()`'s own first frame an `aftermath.on_sight` row (only
## `burning_building` today) is actually on screen — fired once per plan whether or not the warning
## for the row it summons could be put up, since seeing the fire is what happened and an engine with
## no road off screen to wait on is a separate fact about the geometry. `id` is the seen row's own
## `def.id`.
## Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The page counts visits".
signal event_sighted(id: String)
## `EventManager.light_what_she_never_met()`'s own moment an `EventDef.on_her_way` row (only day 3's
## fire today) is lit off her path at dusk on a day she won without meeting it. `id` is the lit
## row's own `def.id`. Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The page counts
## visits".
signal event_lit_unmet(id: String)
# **A charge, counted on its own whatever the day does** *(inbox #764 in minty-lemur, the player: "Ending a day and
# a charging counter are not the same thing"; "Charging is independent of an ended day")*. Each
# signal below carries the charger's name, `EventInstance.charger_name()`: its row's own `def.id`,
# or `charging_dog_tutorial` for the day-3 lesson's dog. `VisitCounter` sends a counter of its own
# for every charger. Listen-only — see docs/TELEMETRY.md, "The page counts visits". Every charger's
# own sends go through its `ChargeRecord`, the one owner of "said once" and of a charge that began
# ending in exactly one of caught, cut short and ended.

## A charger's warning going up, the level below its charge, which `pursuit_began` is sent for: a
## waiting charger noticing her (`EventInstance.warns_by_radius()`), the masked man's raised hand,
## the raised hand of the man a vehicle lets out and of day 13's guard in her view — once per
## instance — and a checkpoint hut's or post's guard raising his hand from her crossing of its
## door's line (`CheckpointController.warn_at_the_doors()`, `door_guard`), each time he does.
signal pursuit_warned(id: String)
## `EventPursuit`'s own moment a pursuer comes for her: its charge, never its warning — a
## waiting charger when its warning has run with her still inside its radius, the man a vehicle lets out and day 13's guard in
## her view when their raised hand has been up its second, the masked man when he starts his run,
## and a pursuer whose telegraph is its approach (the day-3 dog) or that arrives charging from its
## first frame. Once per instance.
signal pursuit_began(id: String)
## A charge that caught her (`EventInstance.report_the_catch()`): a catch that ends the day, sent
## ahead of `hard_fail_triggered` and beside it, or a patrol car's man stopping her, which does not.
## Once per instance; the charge then sends no `pursuit_ended`.
signal pursuit_caught(id: String)
## A charge still running when the day, or the escape's section, ended some other way
## (`EventInstance.report_the_charge_cut_short()`): the meter at its cap, another thing's catch, her
## reaching home. Once per instance, and never beside `pursuit_caught` or `pursuit_ended`.
signal pursuit_cut_short(id: String)
## `EventInstance._be_done()`'s own moment a charge that had begun is over without catching her.
## `shaken_off` is `EventInstance.gave_up` — `EventPursuit`'s own record of whether she outran it
## (`Tuning.PURSUIT_SHAKEN_OFF`) rather than its `duration` simply running out. Never for a charge
## that caught her (`pursuit_caught`) or was cut short (`pursuit_cut_short`), so every charge ends in
## exactly one of the four.
signal pursuit_ended(id: String, shaken_off: bool)

# Encounters and bouts of running, for the page's counter — `EncounterWatch`, which `EventManager`
# asks once a physics frame, is the one emitter of all three. `day` is the day they happened on,
# carried rather than read from `GameState` because an influence that waited is sent as late as the
# next day's start. `name` is `EventInstance.logged_name()`: the row's own `def.id`, or `pelican`.
# Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The page counts visits".

## An encounter's instance properly on screen for the first time in that encounter — once per
## encounter.
signal encounter_seen(day: int, name: String)
## An encounter became meaningful — once per encounter at most. `seen` is whether it was seen in
## that encounter: a meaningful encounter is held until it is seen, and sent with `seen` false only
## once it is over without having been.
signal encounter_influenced(day: int, name: String, seen: bool)
## She began running after at least `Tuning.RUN_BOUT_GAP` of not running, or for the first time in
## the day.
signal run_bout_began(day: int)

# The pelican's own moments, the one rider in about four hundred drawn as a pelican
# (`EventInstance.is_pelican`). *(Inbox #527 in azure-tapir, the player: "I explicitly asked for specific pelican
# telemetry. when the pelican spawns, when it's on screen, and when it's hitting the player. it
# must appear as its own entry and it needs to be more granular than standard event telemetry".)*
# Each carries the pelican's own `EventInstance`, untyped for the reason the section above gives.
# Listen-only, for `VisitCounter` and the run log — see docs/TELEMETRY.md, "The page counts visits".

## `EventManager.spawn_warned()`'s own moment a pelican is created, its warning over.
signal pelican_spawned(instance)
## `EventSpawner.report_the_pelicans_in_view()`'s own first frame a pelican is on screen — once
## per pelican.
signal pelican_sighted(instance)
## The first share of the meter a pelican's field lands on her, heard through its source's
## first-landing callback (`EventSpawner._ride_as_a_pelican()`) — once per pelican. The cyclist's
## field reaches 90px and its lethal reach 33px, so a pelican that strikes her has almost always
## sent this first.
signal pelican_excited_her(instance)
## `EventManager._check_hard_fails()`'s own moment a pelican's lethal reach covers her, emitted
## just before the `hard_fail_triggered` that ends the day, so it is sent ahead of the loss.
signal pelican_struck_her(instance)

# ------------------------------------------------------------------- bodies ---
# Reported rather than logged where they happen: the crowd is a gameplay file and the telemetry
# stays out of the files that decide things.

## The player walked into somebody and shoved them aside.
signal crowd_bumped(at: Vector2)
## A car had to sound its horn at her standing in its lane.
signal car_near_miss(at: Vector2)

# --------------------------------------------------------------- resistance ---

signal resistance_progress_changed(value: int)
signal resistance_step_completed(step: int)
signal resistance_step_failed(step: int)
## A contact is on offer somewhere in the city today.
signal resistance_contact_available(step: int)
## `ResistanceDirector._track_sight_and_reposition()`'s own moment a chalk mark (never a perform
## step's own contact, which runs through the same tracking and never fires this) has actually been
## noticed — within `SEEN_DISTANCE` and on screen for `SEEN_DWELL_SECONDS`. `step` is the mark's own
## step index. Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The page counts visits".
signal resistance_mark_seen(step: int)
## `CheckpointController.check_detentions()`'s own catch — `chatting_mother`, or a checkpoint's
## hut or post — named by the catching row's own `def.id`; `VisitCounter` turns that into `chat` or
## `checkpoint`. Listen-only — see docs/TELEMETRY.md, "The page counts visits".
signal player_detained(id: String)
## `PosterWalls._tear()`'s own moment a sheet actually tears (never a tear that missed, which
## `state.tear()` already refuses). Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The
## page counts visits".
signal poster_torn()
## `EventManager.send_a_pursuer()`'s own moment a torn poster's pursuit marble sends a pursuer on
## foot after her, as his warning goes up — never a marble drawn while one is still on his way or
## after her, and nothing during the escape. Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The page counts visits".
signal poster_pursuit_sent()
## The blackout came and the masts went quiet with the power.
signal city_went_quiet()
## `Blackout.go_dark()`'s own moment the city goes dark, whether or not there was a mast to
## silence — unlike `city_went_quiet` above, this fires on every go-dark. Listen-only, for
## `VisitCounter` — see docs/TELEMETRY.md, "The page counts visits".
signal city_gone_dark()

# ------------------------------------------------------------------- escape ---
# The escape's own moments, emitted by `main` as its sections begin and end, beside the day's own
# `day_started` and `day_ended` each section sends as a day: what the page counts of "how far
# people get" past day 14 under the escape's own names (`VisitCounter`, docs/TELEMETRY.md, "The
# page counts visits"), and the world the run log watches each section in (`RunSession`).

## The escape sequence has just begun — the fresh handover from a won day 14, never a resume of one
## already under way (`main._ready()` tells the two apart: `RunFlow.Opening.ESCAPE_HANDED_OVER`
## against `ESCAPE_RESUMED`).
signal escape_begun()
## A section is about to be walked, the first time or again after a loss (`restarted`). `section`
## is a `DaySpec.Section` passed as `int` (a cross-script enum is not the same type as itself as a
## parameter, the **godot** skill); `world` is where it is walked — the building's
## `InteriorScene` or the `City` — and `events` the events walked among there, the building's
## `EventManager` or the city's.
signal escape_section_started(section: int, restarted: bool, world: Node, events: Node)
## The building section won — she is out of its service exit — and the city section is about to
## begin: once per won attempt at the *building* section, never repeated by a retry of the city
## section alone.
signal escape_city_entered()
## A section was lost — taken, the meter at 100, or the clock at zero — and is about to be offered
## again from its own start. `section` is a `DaySpec.Section` and `result` a `GameEnums.DayResult`,
## both as `int`. The page counts every one alike, as one sequence.
signal escape_lost(section: int, result: int)
## The tunnel or the bridge was reached, by `exit_kind` (a `CityEdge.Kind` as `int`). The run's
## own `run_ended` fires beside this, a moment later.
signal escape_out(exit_kind: int)

# --------------------------------------------------------------- presentation ---

## The player's own answer to the controls question, pressed on the title screen: `joystick` is
## whether it was one of the two joystick buttons, rather than the tap one. `by_key` is true when a
## key began the run rather than a button, which the title answers with the tap scheme;
## `VisitCounter` reports it as `controls-keys` rather than as that fallback. A plain fact rather
## than `ControlsMode`'s own enum, so what hears it needs nothing of the UI's.
signal controls_chosen(joystick: bool, by_key: bool)
