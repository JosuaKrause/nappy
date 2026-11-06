# minty-quail — The events' members only their own class used become internal, the fairness helpers kept · 2026-11-06


minty-quail's `tests-own-class-members.md`, the underscore pass, for the event catalogue row
(`EventDef`), the scheduler, the event manager, the checkpoint controller, the event look and the
pursuer look: a public member only its own class and the tests use becomes internal and its tests
move to what the class does outward (curly-rabbit #1098), and one with no reader left is deleted
(curly-rabbit #1095).

**Built.** `EventDef.mean_emission_along_the_line` and `notice_on` are internal, the cost suite
deriving the first from `walk_through_cost()` and the tutorial dog's suite reading the day's notice.
The scheduler's `is_spoiled`, `place_masts`, `room_around` and `street_bag` are internal: the suites
read spoiled ground through `tests/spoiled_ground.gd` and the next day's masts off the day the
manager plans. The manager's `check_hard_fails` and `step_the_encounters` are internal, and
`walks_under_a_boom` is deleted from the manager and the checkpoint controller with the count
behind it, the suites counting the run log's walked-through line. The checkpoint controller's guard
probes are internal; the guard rig walks a real crossing, and the suites that hold a siting clear of
a door line state it from the body's public position, facing and reach (`tests/door_line.gd`). The
event look's mark decisions are internal, the caret read through `mark_rect()`; the pursuer look's
picture lists are internal, read off a recording drawer after `draw_body()`. Three checks that held
nothing went (curly-rabbit #1097): a bare mast placement the real-night check repeats, a room check
by the scheduler's own spacing, and an exact bag fill `MarbleBag`'s own suite holds. Comments,
docs and two skill sentences that named the renamed members name them as they are.

**Kept public**, each with its reason beside its line in the list: `EventDef.minimum_telegraph`,
`warning_time` and `EventScheduler.budget_for`, which the fairness and cost suites hold the
player's promises with; `EventDef.lunge_is_inside_the_catch`, since `validate()` refuses the case
with an engine error that fails a run; `EventDef.emission_at`, which `tools/cost_table.gd` reads;
`EventManager.planner`, a hand-in; `EventLook.mark_rect`, since the caret is drawn straight onto the
event and no recording drawer holds it.

**Open to overturn.** The pursuer-on-foot suite drives the manager through its own physics tick,
`events._physics_process(STEP)`, rather than awaited frames, which would make three of its loops
asynchronous.
