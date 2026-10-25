# Events composed from behaviours on an explicit phase machine

`EventInstance` (`src/events/event_instance.gd`) still holds, in one class, the sprite tables, car
driving and give-way, the chat and checkpoint hold, pursuit, investigation, pathing, the abduction,
flocking, departure, the excitement field and about 2,300 lines of drawing, including the band and
far guard as nested nodes. `_process` runs exactly one movement branch chosen by flag combinations,
so a row needing two behaviours silently gets the first. What is already built toward this item — the
stored `Phase` with one `transition()`, the pursuit settings in `PursuitSpec`, `NoticeSpec` and
`DaySwitch`, one `Warning` clock for an event's notice, a door crossing and the badge, and the doors
in `CheckpointController` — is minty-quail-10's.

**The pursuit rules are still instance methods.** The phase is stored, but its transitions are
made from inside `_chase()`, `_check_for_notice()`, `_warn_on_its_line()`, `_investigate()` and
the flock's flush, and the four ways a charge starts (a warning's clock running out, a lunge at the
stand-off, the masked man's run distance, a start at once) are still branches there rather than
parts a row is composed of.

**Single-row flags:** `pastes_a_front`, `solid_once_it_starts`, `field_from_its_centre`,
`stop_excitement`, `spawns_on_sight`, `lifts_for_traffic`, `body_stays_behind`,
`warns_over_the_street`, `scenery`; `validate()` polices their combinations; `at_heat()` flips
behaviour flags (`investigates`, `hard_fail`) on a copy. **Behaviour keyed on the drawing or the
id:** `def.look ==` branches decide behaviour for ROADBLOCK (its band, its posts, its far guard),
UNMARKED_VAN (the take), CHECKPOINT_POST, MOUSE (its dash), LOOSE_DOG and CYCLIST's pelican, and
ids decide it for `"charging_dog"` with `RUN_TAUGHT_DAY` in `EventManager._create()`,
`"loudspeaker"`/`MAST_ROW`, `by_id("door_guard")`, and in `ResistanceDirector` `"roadblock"`,
`"delivery_van"`, `"robber_giving_chase"`, `"burnt_shell"`, `"homeless_yeller"`, and
`by_id("alley_robbery")` eight times, so the task guard *is* the robber row and moving him throws
away his state. **Two clocks:** instances, `ResistanceDirector` and `DayController` tick in
`_process`, while `EventManager` checks catches, hard fails and detentions in `_physics_process`,
which already caused a flicker (the chat's comment in `EventInstance._process()`). **Re-entrant
`_process`:** `_drive` and `_timed` re-run the whole frame and roll it back, which does not roll back
any emit or spawn. **Upward coupling:** the manager fetches the player (`EventManager._find_player()`
from the `player` group), the instance fetches the `ResistanceDirector` from a draw path, uses the
red arrow's `ArrowField` as its pathfinder, and copies crowd traffic's give-way
(`_room_to_its_line`). **Streaming** carries hand-picked fields (`Planned`: age, travelled,
noticed_at, guard_spent, chaser_side; `resume()` restores the age, the distance and the notice).
**Events held by the scene:** `City` and `InteriorScene` each sum their
events for the baby rather than the manager answering it, and `BuildingPlan.lay_the_grates()`, a
placement class, builds the grates' sprite nodes through `EventInstance.steam_grate()`. **The
escape planned beside the day:** `FinalePlanner` (routes, layer 2) runs the seal planner and the
scheduler, the escape's planning half where a day's is `EventManager.start_day`, and
`EventManager.start_planned()` is a second entry point that hosts its result; once the manager is
split, the escape is planned inside `start_day(spec)`. `WalkSiting` (after-dawn siting) always reads
the day's home-street rule, and `--route` from the building section waits at the city's brief.

**How behaviour is captured in classes is the implementer's call.** Asked whether the design
encapsulates event types into classes, the player: "well leave that part vague -- the agent that will
implement it should make the call on how to best capture things -- the one class per event is not
necessarily the best option (some events have components that could best be represented as separate
classes) think about what the role of a class here is meant to be and whether composition is possible
(composition as in composing behavior)" (minty-lemur #797). **Read as:** the builder decides what a
class is for here, prefers composing behaviour, and may give a component of an event (a roadblock's
band, its far guard, a van's scene) a class of its own rather than one class per event type; the
design below is a direction, not a prescription, and the PR says which shape was chosen and why.

**A direction for the build:** behaviour components (wait, warn, charge, follow a route, pace,
drive, flock, let out, hold, leave) composed per catalogue row over the stored phase, each saving and
restoring its own state for streaming; grouped sub-resources replace the remaining single-row flags;
looks only draw, in a separate view; the day-3 lesson dog marked by the director that sends it and
the task guard moved with his saved state, both keeping their row ids so GoatCounter's names and the
loss causes do not change (minty-quail-10), and the mast a role; simulation in physics only,
`_process` draws; movement proposed, validated, then committed; intents emitted for the player and
camera instead of calling them. `EventManager` splits into streaming, spawning, the checkpoint
controller and warnings.
