# A scene holds the home's streets for every spec: is that meant

The scene recipes' runtime (`SceneRecipeRuntime.install()`) holds every street round the home
block (`HeldStreets.Why.HOME`) for every walk spec before it makes the scene's ground. So the
walk spec's own home-street rule (`DaySpec.keeps_the_home_streets_clear()`), handed to
`EventScheduler.row_ground()`, changes nothing in a scene: handing it `false` instead fails no
check. On an escape scene, whose spec does not keep the home streets clear, the scene's ground
therefore differs from the escape walk's own, which offers the home's streets.

Whether that is intended is open. If it is, the rule handed to `row_ground()` in a scene is dead
and can go; if it is not, the install holds the home's streets only for the specs that keep them
clear, and the install suite gains the check that tells the two grounds apart (today its ground
check shows only that the home street is not offered, `tests/test_scene_recipe_install.gd`).
Found in the review of the install suite's pull request (minty-quail).
