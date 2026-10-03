# Saved scene screenshots

The accepted whole-city view is `recipe-city-active/trailer-city.png`, source `a23858a4`.
At captured physics tick 150, the population manifest reports 2,396 production agents,
348 cars, and 274 moving cars: NW 85, NE 47, SW 87, SE 55. Each quadrant also has moving
walkers. This recipe explicitly expands the simulation field to the complete map at the
ordinary field's area density. Its headless assertions pass; the corresponding population
test independently checks actual displacement in every quadrant. The complete original
telemetry run is retained inside that output folder. This still establishes whole-city
framing and distributed subjects; the runtime checks establish their movement.

The `recipe-reviewed-stills/` captures use source `8941448c`, Godot 4.7.2 and the same
1280×720 Compatibility renderer. Their complete original telemetry runs are retained below
`telemetry/`. They show the father approaching the gatehouse from its visible front and the
authored tutorial-complete state, keeping onboarding text out of the composition. The city
still establishes the clean zoom framing; wider crowd activity is not established by this run.
The action manifests and capture manifests retain their distinct simulation endpoints.

Source: `7d92cf1666beb4746a8ed389e14e2f3815775080`, reachable through PR #457.
Godot 4.7.2 stable, macOS Apple M2, Compatibility OpenGL, 1280×720. The capture commands use
`--player-view`, `--no-save`, the saved scripted recipe and its own `capture_at` time.
The retained telemetry folders are the complete original runs; the tool output retains each
headless action manifest, capture manifest, log and PNG.

Reproduce from that revision with `tools/scene-recipes.sh --screenshots --output /tmp/new-scenes`.
Fetch `refs/pull/457/head` first when the commit is absent from a fresh clone. No video is made.

Every headless scene completed its observations. Stills establish composition, not motion.
The chase capture records tick 42, carrying, speed 168 and an active pursuing guard; its same-tick
observation matches the captured player's position exactly. The frame uses the normal contact
stride. The three trucks use the production army-column formation. The choice scene uses a
leaf blower as an authored obstacle; that obstacle is an implementation choice, while the
turnaround and alternate route are the requested action. The final zoom begins at the mother's
doorstep and presents the complete city with ordinary background events and crowd enabled.

The first gatehouse frame hides the father behind the hut. It is retained as the original
capture and is not accepted as the final composition. Other retained frames show the requested
parents, real game views and the hall/yard facade difference. The tutorial text is the ordinary
game's own hint, visible with this run's control preference.
