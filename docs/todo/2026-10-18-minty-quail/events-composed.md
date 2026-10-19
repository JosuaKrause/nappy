# Events composed from behaviours on an explicit phase machine

`EventInstance` (`src/events/event_instance.gd`, 7,342 lines, 304 functions, about 105 fields) holds
sprite tables (about lines 1-1100), car driving and give-way (near 1913-2190), the chat and checkpoint
hold (2363-2433), pursuit (2437-2785), investigation (2796-2990), pathing (3160-3338), the abduction
(3442-3501), flocking (3533-3700), departure (3716-4153), the excitement field (4395-4940), and about
2,300 lines of drawing (about 5000-7342), including the band and far guard as nested nodes. `_process`
(near 2197-2333) runs exactly one movement branch chosen by flag combinations, so a row needing two
behaviours silently gets the first.

**Pursuit has no stored phase.** About 13 definition flags (`pursues`, `pursues_within`,
`pursues_within_after_first_day`, `sets_off_beside_her`, `stands_for_its_notice`, `charges_at_once`,
`charges_within`, `warns_for`, `notice_walk_speed`, `arrives_chasing`, `lunge_reach`, `lethal_radius`,
`quiet_until_noticed`; `event_def.gd` near 555-698 and 1069-1098) and about 18 instance booleans
(`_noticed_at`, `_lunged`, `_lunge_held`, `_notice_paused_for`, `_stands_for_this_notice`,
`_paths_to_her`, `_warned_on_its_line_for`, `_noticed_inside_its_charge`, `_outrun_for`, `gave_up`,
`_guard_spent`, `is_leaving`, `is_parked`, ...); the phase is re-derived each frame (`warns_by_radius`,
`_its_notice_is_a_warning`, `is_standing_for_its_notice`, `is_telegraphing`). Four charge triggers
coexist, two "pause the notice" mechanisms, and five warning implementations (the off-screen badge's
`PendingWarning`, the radius clock, the line charge, the stand, the door crossing in `EventManager`
near 2110-2557). This is why the charger radii and the day 9 crossing kept producing new holes one
path at a time (minty-lemur #788).

**Single-row flags:** `pastes_a_front`, `sets_off_beside_her`, `charges_at_once`, `charges_within`,
`notice_walk_speed`, `pursues_within_after_first_day`, `quiet_until_noticed`, `solid_once_it_starts`,
`field_from_its_centre`, `stop_excitement`, `spawns_on_sight`, `lifts_for_traffic`,
`body_stays_behind`, `scenery`, `spawn_mode_switches_after_day`, `lethal_radius`; `validate()` is
about 360 lines policing their combinations; `at_heat()` flips behaviour flags on a copy. **Behaviour
keyed on the drawing or the id:** 26 `def.look ==` branches (ROADBLOCK alone near 1561, 1662, 1682,
2344, 5080, 6455, 6464; UNMARKED_VAN, CHECKPOINT_POST, MOUSE, LOOSE_DOG, CYCLIST's pelican), and ids
(`"charging_dog"` with `RUN_TAUGHT_DAY` in `event_manager.gd` near 1042, `"loudspeaker"`/`MAST_ROW`,
`by_id("door_guard")`, and in `ResistanceDirector` `"roadblock"`, `"delivery_van"`,
`"robber_giving_chase"`, `"burnt_shell"`, `"homeless_yeller"`, and `by_id("alley_robbery")` eight
times, so the task guard *is* the robber row and moving him throws away his state).
**Two clocks:** instances, `ResistanceDirector` and `DayController` tick in `_process`, while
`EventManager` checks catches, hard fails and detentions in `_physics_process`, which already caused
a flicker (`event_instance.gd` near 2249). **Re-entrant `_process`:** `_drive` and `_timed` re-run
the whole frame and roll it back, which does not roll back any emit or spawn. **Upward coupling:** the
instance fetches the player and drives the camera (`hide_for_inspection`, `focus_camera_on`), fetches
the `ResistanceDirector` from a draw path, uses the red arrow's `ArrowField` as its pathfinder, and
copies crowd traffic's give-way (`_room_to_its_line`). **Streaming** carries hand-picked fields
(`Planned`: age, travelled, noticed_at, guard_spent, chaser_side; `resume()` restores three).

**How behaviour is captured in classes is the implementer's call.** Asked whether the design
encapsulates event types into classes, the player: "well leave that part vague -- the agent that will
implement it should make the call on how to best capture things -- the one class per event is not
necessarily the best option (some events have components that could best be represented as separate
classes) think about what the role of a class here is meant to be and whether composition is possible
(composition as in composing behavior)" (minty-lemur #797). **Read as:** the builder decides what a
class is for here, prefers composing behaviour, and may give a component of an event (a roadblock's
band, its far guard, a van's scene) a class of its own rather than one class per event type; the
design below is a direction, not a prescription, and the PR says which shape was chosen and why.

**A direction for the build:** an explicit `Phase` (waiting, warning, charging, caught, given up, leaving, parked, spent,
done) with one `transition()`, the pursuit settings grouped in a `PursuitSpec` with one trigger and
its radii; one `Warning` object (start, cancel-if, expire into an action) shared by events and doors,
with the door crossing in a `CheckpointController`; behaviour components (wait, warn, charge, follow a
route, pace, drive, flock, let out, hold, leave) composed per catalogue row, each saving and restoring
its own state for streaming; grouped sub-resources replace the single-row flags; looks only draw, in a
separate view; the day-3 lesson dog is its own row, the mast a role, the task guard his own row;
simulation in physics only, `_process` draws; movement proposed, validated, then committed; intents
emitted for the player and camera instead of calling them. `EventManager` splits into streaming,
spawning, the checkpoint controller and warnings.
