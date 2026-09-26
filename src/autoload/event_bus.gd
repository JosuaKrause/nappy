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
signal day_started(day: int)
signal day_time_changed(remaining: float, total: float)
signal return_phase_started() ## Baby is asleep; walk home.
signal nerves_changed(nerves: int)
## One attempt at `day` is over, with the same `GameEnums.DayResult` the run log's own `lost` line
## names — `WON` included. Emitted by `main._on_day_finished()` above the calendar move
## `GameState.finish_day()` makes a moment later, so a lost day's retry and a won day's next dawn
## are both still "day N" here. Fires once per attempt, same as `day_started` above: a nerve-bought
## retry begins and ends this pair again for the day it repeats.
signal day_ended(day: int, result: GameEnums.DayResult)
## The held restart — the pause screen's or the day summary's own button — with the day it
## abandoned. `run_ended` below is the run finishing on its own terms; this is the player leaving
## one early.
signal run_restarted(day: int)
signal run_ended(ending: GameEnums.Ending)
## `main._on_day_finished()`'s own answer to *what* ended a crying or hard-fail day, fired
## immediately before `day_ended` above so `VisitCounter` can send `nappy-day-N-<cause>` beside the
## `nappy-day-N-lost-*` that already exists. `cause` is already the full suffix —
## `instant-car`, `instant-charging-dog`, `noise-homeless-yeller`, `noise-crowd`, `noise-self`, and
## so on — built where the moment happened rather than re-derived here, since `VisitCounter` only
## ever listens. Never fired for `WON` or `LOST_TIMEOUT`, which the existing `lost-timeout` name
## already says everything about. Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The
## page counts visits".
signal day_lost_to(day: int, cause: String)

# ------------------------------------------------------------------- events ---
# `instance` is an `EventInstance`, left untyped: this autoload is loaded before the class is.

signal event_telegraphed(instance)
signal event_activated(instance)
signal hard_fail_triggered(reason: String)
## `EventManager._summon_what_has_been_sighted()`'s own first frame a `spawns_on_sight` row (only
## `burning_building` today) is actually on screen — fired once per plan whether or not the row it
## summons could be placed, since seeing the fire is what happened and a truck with nowhere to
## enter from is a separate fact about the geometry. `id` is the seen row's own `def.id`.
## Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The page counts visits".
signal event_sighted(id: String)
## `EventManager.light_what_she_never_met()`'s own moment a `sited_on_her_way` row (only day 3's
## fire today) is lit off her path at dusk on a day she won without meeting it. `id` is the lit
## row's own `def.id`. Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The page counts
## visits".
signal event_lit_unmet(id: String)
## `EventInstance._chase()`'s own moment a pursuer stops merely waiting and turns to come for
## her — see `EventDef.pursues_within`. `id` is the pursuer's own `def.id`; `VisitCounter` only
## names `charging_dog`'s. Listen-only — see docs/TELEMETRY.md, "The page counts visits".
signal pursuit_began(id: String)
## `EventInstance._be_done()`'s own moment a pursuit that had actually noticed her is over without
## catching her. `shaken_off` is `EventInstance.gave_up` — `_chase()`'s own record of whether she
## outran it (`Tuning.PURSUIT_SHAKEN_OFF`) rather than its `duration` simply running out. A catch
## ends the day through `hard_fail_triggered` instead and never reaches `_be_done()`, so the two
## never both fire for the same chase. Listen-only — see docs/TELEMETRY.md, "The page counts
## visits".
signal pursuit_ended(id: String, shaken_off: bool)

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
## `EventManager._check_detentions()`'s own catch — `chatting_mother`, or a checkpoint's hut or
## post — named by the catching row's own `def.id`; `VisitCounter` turns that into `chat` or
## `checkpoint`. Listen-only — see docs/TELEMETRY.md, "The page counts visits".
signal player_detained(id: String)
## `PosterWalls._tear()`'s own moment a sheet actually tears (never a tear that missed, which
## `state.tear()` already refuses). Listen-only, for `VisitCounter` — see docs/TELEMETRY.md, "The
## page counts visits".
signal poster_torn()
## The blackout came and the masts went quiet with the power.
signal city_went_quiet()
## `Blackout.go_dark()`'s own moment the city goes dark, whether or not there was a mast to
## silence — unlike `city_went_quiet` above, this fires on every go-dark. Listen-only, for
## `VisitCounter` — see docs/TELEMETRY.md, "The page counts visits".
signal city_gone_dark()

# ------------------------------------------------------------------- escape ---
# The day-14 sequence has none of its own signals here otherwise: `FinaleController`'s own
# `section_started`/`section_lost`/`escaped` are enough for `main`, which holds the only reference
# to it. These three exist only for `VisitCounter` to answer "how far people get" past day 14 —
# see docs/TELEMETRY.md, "The page counts visits".

## The escape sequence has just begun — the fresh handover from a won day 14, never a resume of one
## already under way (`main._ready_escape()`'s own `_escape_resumed_from_disk` tells the two apart).
signal escape_begun()
## `main._on_escape_exit_requested()`'s own moment the building is behind her and the city section
## begins — once per attempt at the *building* section, never repeated by a retry of the city
## section alone (`FinaleController.restart_section()`, not `enter_city()`). Listen-only, for
## `VisitCounter` — see docs/TELEMETRY.md, "The page counts visits".
signal escape_city_entered()
## Either section was lost — taken, the meter at 100, or the clock at zero — and is about to be
## offered again from its own brief. No section named: the escape is one sequence as far as this
## signal is concerned.
signal escape_lost()
## The tunnel or the bridge was reached. The run's own `run_ended` fires beside this, with `GOOD`.
signal escape_out()

# --------------------------------------------------------------- presentation ---

## The player's own answer to the controls question, pressed on the title screen — a
## `ControlsMode.Mode` passed as `int`, the same cross-script-enum reason `FinaleController`
## passes its own enums as `int` (see the **godot** skill).
signal controls_chosen(mode: int)
