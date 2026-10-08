# Playtest tall-wombat — Restore the window gap and correct trailer fades and audio

2026-10-08.

## #624 — Window gap, animation sequence, audio and fades

The assistant supplies `build/trailer/trailer-glass-alarm-final-v2.mp4` and asks whether the
full movie is ready to approve for PR #580, specifically the left-half window position, the
deep notes at the dog run and army scenes, and music through the ending. The independent PR
review is still required. The player has the original full-resolution A/B/C PNGs in
`build/trailer/player-frames/` to identify the poses.

> what is the progression of the frames A then C? let's try A then B or B then C. also why did you move her down now? can you not change one axis without changing the other? the window frame should have a gap then the bottom of the baby starts. I have't looked at the rest yet

The assistant confirms that the renderer requests A-B-A-B but will verify the actual displayed
poses. The rendered baby is clipped at the lower opening; the earlier request is a visible
gap of about one brick-height beneath the baby. Horizontal placement in the left window half
stays fixed while the gap is corrected. A/B is the first requested pair, and B/C is an allowed
alternative experiment. The player continues:

> the fade out / in should happen in both cases -- right now only a fade out happens without a fade in
>
> and neither parts of the audio are fixed
>
> also, the title card should *not* fade
>
> and no fade in the beginning
>
> but a fade out at the end of the video

The two audio defects are the inaudible deep event notes and music ending before the picture.
The main title card is the Nappy card after the dog scene; the apartment window is the intro
slide. The movie has no opening fade-in, the title card has no fades, and the ending fades out.

The assistant asks whether "both cases" means both A-to-B/B-to-A window-animation changes or
the gameplay-scene transitions. The player answers:

> fade in/out I was talking about was the transition between scenes. this has nothing to do with the player or animation frame choices

It also asks whether the mother's previously requested one-second fade remains while the
background and text start immediately, or whether she too is fully visible on the first
frame. The options are "Keep only the mother’s fade-in" and "Everything visible immediately".
The player selects:

> Keep only the mother’s fade-in

Scene transitions fade out and in, the video opens immediately, the title card has neither
fade, and the ending fades out. The mother's own one-second appearance remains. Frame
selection is separate from the transition rule. No movie or audio approval is given.

The player makes the independence explicit:

> the mother fade in and screen transition fades over black are completely different and independent things
