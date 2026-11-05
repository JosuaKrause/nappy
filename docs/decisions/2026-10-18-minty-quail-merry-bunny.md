# minty-quail — The on-foot pursuer test steps the encounters through the event manager, and the wall shield's cull is swept with fake emitters (tests through public seams) · 2026-11-05

minty-quail's `tests-public-seams.md`: `tests/test_pursuer_on_foot.gd` and
`tests/test_wall_shield.gd`. Simulation: `src/events/event_manager.gd`.

**Built.** The event manager's tick calls two public steps of its own: `step_the_encounters(delta)`,
which tells the instances where she is, steps them and lets the officers out, in the tick's order,
and `check_hard_fails()`, the instant-loss check, which runs later in the tick after the ground
warnings, the door lines and the detentions. The pursuer test calls the two instead of the
manager's privates, since real manager ticks over its fifty-six whole encounters run past eight
minutes. The wall shield's cull test hands `DebugLayers.setup()` a fake event of chosen shape,
level and speed, moved over four thousand seeded samples, and asserts that `field_runs()` returns
exactly the outlines whose bounds meet the view; a cull made to drop moving emitters fails it.

**Choices, open to overturn.** Two public steps rather than one: folding the instant-loss check
into `step_the_encounters` would run it before the door lines and detentions, which can hold or
move her, and so change the game (the builder's call). A public step called by the manager's own
tick is a seam under record -47 (the orchestrator's call; the alternative, the test writing the
instances' public fields itself, is a hand copy of the manager).
