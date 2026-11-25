# A scene in free play past its whole duration

`tests/scene_recipe_lifecycle.gd` checks that free play has no capture deadline, and nothing checks
what a scene in free play does once its whole duration has passed, since a suite cannot make a
scene's duration pass without waiting it out. The test wants a clock the scene is handed, a hand-in
in `src/dev` whose default is the engine's, so a suite hands in a clock past the end.
