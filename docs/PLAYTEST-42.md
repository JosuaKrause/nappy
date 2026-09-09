# Playtest 42 — Illustrated animation and rendering resolution — 2026-09-08

> /Users/krause/Library/Application\ Support/Godot/app_userdata/Nappy/telemetry/2026-09-08/run-204805-seed2468684785-v0.7.0-43-g1131bba/asked/burst-15638553-002.mp4 this video shows how unnatural everything looks. the arms of the player are too long. the legs have two knees/bends each. the movement of the legs of players and npcs are not realistic. baby is drawn on top of the stroller. mustard lady's legs go out sideways. the scaling down becomes pixelated. -- the high resolution graphics don't fit the low resolution screen and it just looks noisy. one thing we can try is to increase the resolution that is drawn. the screen size can stay the same but the game shouldn't be zoomed in resulting in a lower effective resolution

> you can also inspect the images of the video you know where to find them

The whole source run is preserved in
[the evidence folder](evidence/run-204805-seed2468684785-v0.7.0-43-g1131bba/).
The [video](evidence/run-204805-seed2468684785-v0.7.0-43-g1131bba/asked/burst-15638553-002.mp4)
has its [original PNG sequence and timing record](evidence/run-204805-seed2468684785-v0.7.0-43-g1131bba/asked/burst-15638553-002/)
beside it. These are runtime defect evidence, not approved art references.

The arm reach, directional gait and pixelation findings re-report PLAYTEST-38. The extra visible
leg bends and baby layering add specific checks to that repair. Keep this recording and report
separate from the earlier still-image playtest. The proposed resolution experiment keeps the
window size while removing the zoom that reduces the visible world; it does not establish that
resolution alone fixes anatomy, gait or compositing.

## Clarification — preserve the current view

> I did not want to see more world -- I want higher resolution for the current view

The wider-world interpretation above was the assistant's mistake. The requested experiment
preserves the current framing, actor size, HUD size and window size while increasing the actual
rendered pixel count. Camera zoom reduction does not satisfy this request.
