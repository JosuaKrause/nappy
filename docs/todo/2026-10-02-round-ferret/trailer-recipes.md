# Construct the trailer's described scenes

The player explicitly asks for these recipes in addition to the power-plant join test.
[PLAYTEST-139](../../playtests/PLAYTEST-139.md) holds their trailer descriptions, and
[brisk-ibis, required trailer scenes](../../playtests/2026-10-02-brisk-ibis.md) connects them
to this builder. Build all the scenes below with the standard components and actual
gameplay behavior, using normal-scene validation. Each has an individually runnable
recipe and is referenced by the existing trailer shot list so the player can render
one shot or the sequence. Each also launches without scripted movement for free-play
experimentation. Scene extent need only cover the planned setup and action; free play
shows default texture when the player walks beyond it. The closing zoom needs enough
constructed city to deliver its explicitly requested whole-city view.

The opening shows a route choice in action: the parent goes down the wrong path,
turns around and takes another. The obstacle and alternative must be legible in the
ordinary player view, and the scripted movement must actually make the turn and detour.
Do not substitute an overview, dusk map, or debug view for this action.

Before the title, show early dangers only, up to the charging dog. Construct the desired
encounters directly and give the dog its actual warning and charge behavior. Pin the
timing needed to see the encounter rather than only guaranteeing that the actor exists
somewhere in the city. Keep the title as the transition into the later-day glimpses.

After the title, construct the three specified one-second scenes, each through a fade
to black: army trucks driving beside the mother; the father walking toward a gatehouse;
and the mother visibly running with the baby in her arms from pursuing guards. These
are the only later-day spoilers. The trucks must be in the shot, the father must approach
the gatehouse, and the escape must visibly show carrying, running and pursuing guards.
Use their real motion and progression rules. The existing trailer notes about a missing
truck and a mother who does not visibly run are acceptance failures to address here.

End with a zoom out from the parent's doorstep to the whole bustling city. Retain the
active city during the move so its scale and life are visible. The other shots alternate
between mother and father, with the initial random choice fixed for repeatability; the
three one-second shots keep their specified mother/father/mother assignments.

The sequence is at most thirty seconds, at the game's resolution, with the game's audio
recorded through the existing movie-writer and ffmpeg tools. On-screen text is allowed;
the current captions and title styling remain drafts for the player to judge. The player
can render the result locally; generated frames and videos are not checked in.

For each recipe, assert the required setup and observable action at its capture window,
then provide a visual preview in the project's established review format. A still can
show a join or composition; motion needs a burst or recorded playback. Passing an actor
count or generating a video file is not evidence that the described action is visible.
The repeated-render and load checks are in examples-and-verification.md. Final editorial
approval remains [M204, the trailer cut](../2026-09-25-M204/README.md); these recipes supply
the actual described scenes, not a replacement trailer concept.
