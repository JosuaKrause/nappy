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

signal day_started(day: int)
signal day_ended(result: GameEnums.DayResult)
signal day_time_changed(remaining: float, total: float)
signal return_phase_started() ## Baby is asleep; walk home.
signal nerves_changed(nerves: int)
signal run_ended(ending: GameEnums.Ending)

# ------------------------------------------------------------------- events ---
# `instance` is an `EventInstance`, left untyped: this autoload is loaded before the class is.

signal event_telegraphed(instance)
signal event_activated(instance)
signal event_finished(instance)
signal hard_fail_triggered(reason: String)

## What is currently holding a floor under the whole city, by display name, or "" for nothing.
##
## A `city_wide` source has no position, so it is the one thing in the game that cannot be drawn
## *over*: there is nothing to put a mark above. Without this signal the loudspeaker masts hold a
## floor under the meter from day 5 with nothing on screen to say so, and a player watching
## excitement refuse to drain has no way at all to find out why.
signal city_wide_changed(what: String)

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
## Hold progress at a contact, 0..1.
signal resistance_hold_changed(progress: float)
## A patrol came past mid-handover.
signal resistance_seen()
## The sabotage went through and the masts went quiet.
signal city_went_quiet()
