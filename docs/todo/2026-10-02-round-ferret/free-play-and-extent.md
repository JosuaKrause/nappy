# Explore the same scene with ordinary controls

The player asks for every scene to be playable with and without scripted movements so
they can experiment. A single saved recipe owns the layout, actors and initial state.
Select free play or scripted playback when launching it; do not require separately
maintained interactive and recording copies of a scene. Restarting either mode restores
that same setup.

In free play, ordinary movement controls and the normal gameplay camera work. Optional
scripted player input and camera moves do not run or lock out the player's input. The
world still simulates normally: traffic, guards, event triggers, signals and other actors
retain their real behavior. Scripted playback applies the recipe's planned actions for
repeatable tests and recording. The fixed starting state is shared; free play is expected
to diverge when the player takes a different action. Do not call that a failed playback
assertion or end the experiment at a recording script's deadline.

Let a recipe declare only the scene extent it needs. The player permits default texture
for the rest when they walk too far; do not force construction of a complete city for a
building-join test or a short shot. The player can cross the edge, explore the exterior,
and walk back into the ongoing scene. The edge is not an invisible wall, a teleport, a
restart, or the end of the run. Preserve normal gameplay collisions and consequences
within the authored scene.

**Proposed, not asked for:** use one documented plain ground fallback outside the scene,
without synthesizing surrounding streets, buildings or ambient encounters. Provide the
minimal ground/collision behavior needed to keep walking and returning reliable. This
exterior is visibly simple and outside the scene's claimed gameplay-valid extent; it
must not participate in a claimed city route or satisfy an authored reachability check.
Use the existing world/camera and coordinate conventions, and keep scripted actors'
required travel and the camera's required view inside the constructed extent. The
doorstep-to-city zoom recipe necessarily constructs its requested city-scale content.

The normal-scene validity result names its authored extent and required context. It
answers whether the components and arrangement could occur in the normal game; it does
not pretend that the default-texture exterior is a generated city. Explicit invalid
fixtures remain separately declared, irrespective of whether they run interactively
or under scripted input.
