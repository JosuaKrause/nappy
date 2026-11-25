# A scene in free play past its whole duration

`tests/scene_recipe_lifecycle.gd` checks that free play has no capture deadline, and nothing checks
what a scene in free play does once its whole duration has passed, since no recipe a suite plays
is run past its end. Two routes reach it, and the builder picks: the scene counts physics ticks, so
a suite authors a short duration and passes real ticks beyond it (`PhysicsTicks.pass_ticks()`, as
the suite already does), with no hand-in; or the scene is handed a clock, a hand-in in `src/dev`
whose default is the engine's, which would be a second clock beside the tick count.
