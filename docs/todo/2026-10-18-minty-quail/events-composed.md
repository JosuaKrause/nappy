# Events composed from behaviours on an explicit phase machine

What an event does is a list of behaviours (`src/events/behaviours/`) that
`EventBehaviours.compose()` builds per catalogue row, each saving and restoring its own state for
streaming, with a row's settings grouped into the sub-resources its behaviours read (`PursuitSpec`,
`OnHerWay`, `Aftermath`, `VehicleSpec`, `AbductionSpec`, `EventDef.solid_when`, `EventDef.Role`). A
car's driving is a behaviour (`EventCarDriving`), whose frame is proposed, checked and then
committed, and a roadblock's band and posts are one (`EventBarrierPost`, with `RoadblockFarGuard`).
`EventInstance` (`src/events/event_instance.gd`) holds, besides that list, the excitement field and
the lifecycle of its drawing nodes; how it is drawn is its look's (`src/events/views/`, picked per
row by `EventLooks.for_row()`, reading its public state), and every picture is named in
`EventPictures` (minty-quail-19). The manager steps its instances on the physics tick in a fixed
order, and each is drawn interpolated between ticks by its look, which reads on its own drawn frame
what the last tick left (minty-quail-21). `EventManager` is the face the rest of the game talks
to and hands its work to `EventStreaming`, `EventSpawner`, `WarningBoard`, `EventsAhead` and
`CheckpointController`, all working over one `EventWorld`; it is handed the player and the run,
and the doors' holds and releases come back to it as intents it carries out on her
(minty-quail-24). Every walk (a day, the escape's city, its building) starts through one
`start_day(spec, rng, consumed, focus)`, planned by `DayPlanner` on the walk's own streams, with
`FinalePlanner` the escape's route alone; the manager answers the baby's excitement, which
`WorldContext` hands her with the crowd's; the building's grates are drawn by a view
(`SteamGrates`); and `WalkSiting` reads the spec's home-street rule (minty-quail-25). The four ways a charge starts (a warning's clock running out, a lunge at the
stand-off, the masked man's run distance, a start at once) are branches inside `EventPursuit` and
`EventNoticeRun` rather than parts a row is composed of.

**What is still keyed on a row's flags, picture or id** (every `def.look` comparison under `src/`
outside `src/events/views/`, found by search): `at_heat()` flips behaviour flags (`investigates`,
`hard_fail`) on a copy; `def.look ==` decides behaviour for CYCLIST's pelican
(`EventSpawner.rolls_a_pelican()` and `spawn_warned()`); whether a row is a spread is a list of pictures
(`EventDef.has_a_spread`); on `EventInstance` it decides whether the alley post's hold hides it
(`is_suppressed_by_its_own_hold()` on CHECKPOINT_POST), the loose dog's lead in its footprint
(`footprint_of()` on LOOSE_DOG), whether a rank draws and stands along its street like a spread
(`drawn_box()` and the solid body's axis, `_solid_axis()`, on PROTEST and FIREFIGHT), a warning
picture's size (`_warning_picture_size()` on CHARGING_DOG and ROBBER) and which way a stationary
vehicle shows (`_stationary_vehicle_uses_side()` on BURNT_OUT_CAR); `EventSpawner._body_axis()`
repeats the rank test for siting; `EventsAhead`'s `GUARDSMAN_GIVING_CHASE` tests choose only the
run log's wording ("a guardsman" or "a policeman"). **Two clocks:**
`ResistanceDirector` and `DayController` tick in `_process`, once per drawn frame, while the events
step and their catches, hard fails and detentions are checked on the physics tick. **Every clock is
to be frame-locked** (minty-dolphin #866): the player, "actually we should make all clocks in the game
frame locked. otherwise someone with a faster computer could get lower times over someone with many
lag frames", and "if we build a "seed of the day" later and let people compete on a leaderboard the
timing needs to be fair". Read back as "every clock that makes a time the player sees or decides an
outcome counts the fixed 30-per-second physics ticks, never wall-clock time; on a lagging machine the
game slows down instead of the clock running on", the player: "yes, that's what I meant -- also lag
frames where nothing happens (I don't think we have those) shouldn't count"; read back again as a
tick counting only when the walk's simulation actually stepped on it (not paused, no screen up, no
load hold, the catch-up ticks after a hitch counting), "that works". **Read as:** the clocks this
reaches are the day countdown, the resistance clocks and any other clock under `src/events/`,
`src/resistance/` and `src/day/` that makes a shown time or decides an outcome. *Proposed, not asked
for:* the traffic signals' cycle and the encounter watch counted in ticks too (the signals are
`src/city/`'s, under **crowd-traffic**'s green wave); a test that one long drawn frame advances no
clock beyond the ticks that ran; and the escape's hundredths label showing the tick clock advanced by
the physics interpolation fraction, so it looks as it does now. The run's play time already counts ticks (minty-quail-23). **The tick still
sets a drawing property:** a pursuer that warns over the street is put on the warning draw layer
from its tick (`EventInstance._take_the_layer_it_warns_on()`, `DrawLayer.draw_on()`), since a look
never writes the event. **Upward coupling:** the instance uses the red arrow's `ArrowField` as its
pathfinder, and a car's driving copies crowd traffic's give-way (`EventCarDriving.room_to_its_line()`), the copy
shared-components' `LaneMover` takes. `--route` from the building section waits at the city's
brief.

**How behaviour is captured in classes is the implementer's call.** Asked whether the design
encapsulates event types into classes, the player: "well leave that part vague -- the agent that will
implement it should make the call on how to best capture things -- the one class per event is not
necessarily the best option (some events have components that could best be represented as separate
classes) think about what the role of a class here is meant to be and whether composition is possible
(composition as in composing behavior)" (minty-lemur #797). **Read as:** the builder decides what a
class is for here, prefers composing behaviour, and may give a component of an event (a roadblock's
band, its far guard, a van's scene) a class of its own rather than one class per event type; the
design below is a direction, not a prescription, and the PR says which shape was chosen and why.

**A direction for the build:** the pelican's behaviour keyed by data; the picture-size geometry
siting reads (`box_of()`, `footprint_of()`, `solid_footprint_of()`, `drawn_box()`, `_solid_axis()`,
`EventSpawner._body_axis()`, `_warning_picture_size()`, `warning_guard_rect()`, the guard post's
offset and heading, `_stationary_vehicle_uses_side()`) and the alley post's hiding leave
`EventInstance` and the spawner for a class of their own the spawner and siting read; movement proposed, validated, then committed for every mover,
as a car's frame is.
