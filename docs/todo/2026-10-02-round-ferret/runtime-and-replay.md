# Run and record one recipe through the real game

**Proposed, not asked for:** give the dev-flag surface a recipe path, usable by the existing
run, screenshot, recording, and trailer tools. Add a recipe reference to the trailer shot
format. Validate arguments and recipe data before generating or recording, and document
how recipe values interact with command-line flags. Reject conflicting ownership of a
setting rather than silently ignoring one of its values. Keep the flag list in its
existing shared declaration and keep recipe runs away from the player's save.

The recipe's normal-scene or test-fixture classification remains explicit through each
entry point and in its output manifest. The trailer tool accepts only scenes validated
as possible gameplay. A test fixture cannot become a normal scene through a missing flag,
a default value, a successful render, or a reused cached setup. An isolated fixture's
limited validation result likewise cannot substitute for full-scene validation.

Recipes control the initial day and relevant progression state; player position, facing,
parent and meter state; named events and traffic/pedestrian actors, their placement and
routes; and the presence or absence of generated background activity. An omitted ambient
population policy has a documented deterministic default. Use actual event definitions,
actors, collision, traffic signals, and gameplay updates so a test exercises the code a
player runs and a trailer shows gameplay. An exact arrangement must not be overwritten
by the ordinary day's later scheduling or population pass.

Reuse the walking/input rig and camera controls for the action and framing portions of a
recipe. Let action timing and capture start use simulation ticks or a documented fixed
simulation clock. Setup completes before that clock and the recording begin: asset or
ground loading, window focus, wall-clock delays, and background machine load must not
advance the intended opening of the shot. Declare relevant random seeds and actor state,
including signal or animation phase where it affects the requested moment.

Distinguish construction requirements from observations during playback. A scene can
require a truck to start at its named crossing and then check that it is in the camera
at the capture tick. If an ordinary gameplay change prevents a promised moment, the
recording or test reports the unmet condition; it must not report success merely because
a video file exists. Keep checks inspectable and deterministic instead of claiming the
builder can automatically recognize every desired visual composition.

Reproduction is scoped to a recipe, game revision, assets, engine and rendering settings.
Record those inputs with the resolved setup and distinguish simulation-state replay from
frame equality. Use the existing movie-writer path for frame-locked capture. Pixel equality
on one configured renderer does not establish equality across platforms or future game
revisions. Generated videos remain under ignored build output, as the trailer decision
requires.
