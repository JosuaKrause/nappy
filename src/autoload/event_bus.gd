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
# `instance` is an EventInstance; left untyped until M4 defines the class.

signal event_telegraphed(instance)
signal event_activated(instance)
signal event_finished(instance)
signal hard_fail_triggered(reason: String)

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
