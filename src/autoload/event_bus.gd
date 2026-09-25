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

# ------------------------------------------------------------------- events ---
# `instance` is an `EventInstance`, left untyped: this autoload is loaded before the class is.

signal event_telegraphed(instance)
signal event_activated(instance)
signal hard_fail_triggered(reason: String)

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
## The blackout came and the masts went quiet with the power.
signal city_went_quiet()

# ------------------------------------------------------------------- escape ---
# The day-14 sequence has none of its own signals here otherwise: `FinaleController`'s own
# `section_started`/`section_lost`/`escaped` are enough for `main`, which holds the only reference
# to it. These three exist only for `VisitCounter` to answer "how far people get" past day 14 —
# see docs/TELEMETRY.md, "The page counts visits".

## The escape sequence has just begun — the fresh handover from a won day 14, never a resume of one
## already under way (`main._ready_escape()`'s own `_escape_resumed_from_disk` tells the two apart).
signal escape_begun()
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
