# Events composed from behaviours on an explicit phase machine

What an event does is a list of behaviours (`src/events/behaviours/`) that
`EventBehaviours.compose()` builds per catalogue row, each saving and restoring its own state for
streaming, with a row's settings grouped into the sub-resources its behaviours read (`PursuitSpec`,
`OnHerWay`, `Aftermath`, `VehicleSpec`, `AbductionSpec`, `EventDef.solid_when`, `EventDef.Role`). A
car's driving is a behaviour (`EventCarDriving`), whose frame is proposed, checked and then
committed, and a roadblock's band and posts are one (`EventBarrierPost`, with `RoadblockFarGuard`).
`EventInstance` (`src/events/event_instance.gd`) holds, besides that list, the sprite tables, the
excitement field and the drawing, including the band and far guard as nested nodes. The four ways a
charge starts (a warning's clock running out, a lunge at the stand-off, the masked man's run
distance, a start at once) are branches inside `EventPursuit` and `EventNoticeRun` rather than parts
a row is composed of.

**What is still keyed on a row's flags, picture or id:** `at_heat()` flips behaviour flags
(`investigates`, `hard_fail`) on a copy; `def.look ==` decides what is drawn for CHECKPOINT_POST,
LOOSE_DOG and the robber's heading, and decides behaviour for CYCLIST's pelican (PR 4);
`CheckpointController` sends its guard by `by_id("door_guard")`. **Two clocks:** instances,
`ResistanceDirector` and `DayController` tick in `_process`, while `EventManager` checks catches,
hard fails and detentions in `_physics_process`,
so a door's hold ending on a drawn frame would show her at the place she went in until the next
physics tick, which is why its release has to show her on the physics frame that moves her.
**Upward coupling:** the manager fetches the player (`EventManager._find_player()`
from the `player` group), `CheckpointController` drives her and the camera directly
(`hide_for_inspection`, `focus_camera_on`, `teleport_to`, `show_after_inspection`,
`release_camera_focus`), the instance fetches the `ResistanceDirector` from a draw path, uses the
red arrow's `ArrowField` as its pathfinder, and a car's driving copies crowd traffic's give-way
(`EventCarDriving.room_to_its_line()`), the copy shared-components' `LaneMover` takes. **Events held by the scene:** `City` and `InteriorScene` each sum their
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

**A direction for the build:** looks only draw, in a separate view, and the pelican's behaviour
keyed by data; simulation in physics only, `_process` draws; movement proposed, validated, then
committed for every mover, as a car's frame is; intents emitted for the player and camera instead of
calling them. `EventManager` splits into streaming, spawning and warnings.
