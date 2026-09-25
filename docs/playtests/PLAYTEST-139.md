# Playtest 139 — A trailer, recorded from the game itself

2026-09-25. Said in conversation.

## What the player said

> "I've been thinking of making a trailer like video. we can use recordings from a frame locked
> game. the trailer will be a set of paths in pre determined seeds with fixed events so we can
> reproduce it easily. for this we need to be able to record a video (one image per frame on a
> scripted godot and ffmpeg afterwards then delete the raw images). we need to be careful not to
> directly check in either the images or the video so it should be possible to run by me and I
> can generate the video myself. so the setting scripts need to produce the same output every
> time. what would you choose to show?"

The orchestrator offered eight shots over 60–75s: her stoop at dawn, the day's routes on the
overview or dusk map, a detour around a leaf blower, a crossing, a pursuer announced by the badge,
the resistance's handover, a region wall, and the escape; and asked about length, on-screen text,
sound and framing.

> "2. I would show a choice in action. going down the wrong path then turning around and going
> another. we shouldn't show something that will never be visible.
> I would mostly focus on early dangers, up to say the charging dog. then after the title shows a
> few fades to black with short 1s segments of army trucks driving besides her. her walking
> towards a gatehouse. her running with her baby in the arm from pursuing guards. then in the end
> a zoom out from her doorstep to show the full buzzling city (to give a hint of the scale). those
> three 1s segments are the only spoilers for later times. I think 30s should be max. shots should
> randomly alternate between man/woman with the 3 1s scenes her (trucks), him (gatehouse), her
> (running from guards). we can put some on-screen texts. same resolution as the game. we can
> record the game audio so if it ever gets made it will just work."

## The statements

1. **The trailer is rendered from the game, frame-locked, by a script the player runs**: one
   image per frame from a scripted Godot, joined by ffmpeg, the raw images deleted afterwards.
   Neither the images nor the video is checked in; what is checked in produces the same output
   every time — fixed seeds, fixed events, fixed paths.
2. **The route decision is shown in action**: she goes down the wrong path, turns around, and
   takes another. Replaces the orchestrator's overview shot.
3. **Nothing is shown that a player never sees** — no overview, dusk map or debug view.
4. **Before the title, early dangers only, up to the charging dog.**
5. **After the title, three 1s segments, each through a fade to black**, the only spoilers of
   later days: army trucks driving beside her (the mother); him (the father) walking towards a
   gatehouse; her running with the baby in her arms from pursuing guards.
6. **It ends on a zoom out from her doorstep to the whole bustling city**, a hint of its scale.
7. **30s at most.**
8. **The other shots alternate between the mother and the father**, chosen at random but fixed,
   so the render repeats.
9. **Some on-screen text** is allowed.
10. **The game's own resolution**, and **the game's audio is recorded**, so the trailer has sound
    as soon as the game does.

## Then, on the route rig

> "the automated walking rig -- can we add an option to record there, too? so I can create videos
> of those runs and review them"

> "for you a number is enough to judge them but I want to also be able to see some runs myself"

11. **A `--route` rig run can be recorded as a video** the same way, for the player to review;
    nothing it produces is checked in. Queued as M208, built with the trailer's recording.
