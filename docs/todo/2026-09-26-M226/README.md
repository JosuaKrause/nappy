priority: later

## M226 — The pursuing dog keeps its day-3 timing, and the other warnings fit it · asked for 2026-09-26

> "I meant the pursuing dog *not* the loose dog. the loose dog can stay as short as it wants since
> it is not lethal and relatively low impact. the pursuit dog timing from the day 3 lesson is the
> correct timing. other timings should be adjusted to fit that. and the new system should be made
> to work to retain that timing for the pursuing dog" · "we can defer this change to a later PR
> though"

> "the 2.9 is not important. what is important is the timing breakdown for the pursuing dog
> during the tutorial -- this is the gold timing with warning time and onscreen pursuing time seen
> as correct"

[PLAYTEST-145](../../playtests/PLAYTEST-145.md), statements 10–16. Builds on M207's warning first (the
badge goes up with nothing in the world, the thing spawns just off screen where it points), which
PR #372 builds for the cyclist, `loose_dog`, the fire truck and the day-13 column but not for
`charging_dog`. On `Tuning.RUN_TAUGHT_DAY` (day 3, the lesson that teaches running) the dog is sited
dead ahead of her 0.5s of closing outside the view (`offscreen_notice`), spends its 4.5s
`telegraph_time` visibly closing at its stand-off, then chases at 130px/s for `Tuning.PURSUIT_TIME`
(3s); `tests/test_events_pursuit.gd` holds that "Walking has to lose, or the mechanic teaches
nothing."

Replaces the orchestrator's proposal on PR #372 of a 2.9s badge before the dog's 4.5s approach,
which would have lengthened the day-3 timing the player calls correct.
