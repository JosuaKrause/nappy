# Sunny lynx — Measure the work in a crowded scene

2026-09-26. Reported in conversation about the current mobile build.

## What the player said

> "can you investigate what the bottleneck is when a lot of entities are on screen? I think that is what makes the current mobile version stutter"

Asked which phone/browser and location reproduce it:

> "just find a crowded place with lots of entities / cars / people. it doesn't need to also stutter on the desktop. just measure what the contributions are each frame"

## Scope

This continues M159, a slow frame names the frame that was slow: measure subsystem time in a
crowded scene on the available desktop. Desktop stutter reproduction and phone access are not
prerequisites. The suspected link to current mobile stutter remains a hypothesis.

## Follow-up instructions

> "hold off on measurements right now"

> "can you write the plan down for now so you can continue later?"

## Resumption

> "read the brief from .claude/restart-prompt.md and continue -- yes, you can create a draft PR. you can also continue the investigation, probes, and measurements"

## Desktop observation and separate scenery animation

> "I see the stutter on the desktop, too, in the runs that you just did. ground animations should not be done by redrawing the ground! they should be separated out and the ground should not have the texture that is animating. that also brings me to the water at the south of the map which is currently frozen but would need the same treatment"

> "the same for things like the water fountain in the broken pipe texture or the smoke cloud from the car accident. separate the animated parts out and only animate the small bits not the entire texture"

> "write that down as a plan for now"

> "with the whole analysis"

## Animation implementation resumed

> "main updated again -- read your brief and let's start with the animation optimization"

> "pull the latest from the optimization branch"

## Static scenery guarantee and lazy preparation

> "yes, you can commit and push to the branch"

> "there is more on main to pull in btw"

> "you can do that too"

> "so basically what we should guarantee is that 1) if only a part of a sprite is animated we stencil it out and have the animation in a separate sprite 2) the city render image of the blocks must not be animated. it is always a still frame. so if animated components are necessary they are overlaid and composited dynamically. one question: are all city renders done at the beginning of each day? can we do them lazily instead whenever the player gets into x tiles from them (when the image is still off-screen)?"

> "when you're done can you add gifs in the PR description for review?"

> "I still see a warning about the pushing to github -- can you do it now?"

## Progress checkpoint and next directions

After the repeated redraw reduction and mixed whole-frame results are reported:

> "I mean it's good progress for now we can push that."

> "add your latest findings as well"

> "what is your next hypothesis?"

The assistant proposes auditing repeated danger prediction for identical inputs, and explains
that lazy scenery preparation targets preparation cost rather than an established walking hitch.

> "can you add a todo item for that"

> "for both items"

> "or how many items and directions you think is worth exploring"

The assistant files three exploratory directions: event-shape classification caching, reuse of
identical danger predictions, and reuse/lazy preparation of static visuals ahead of the camera.
These are proposals to measure, not claims that their mechanisms are chosen or their gains proven.

> "and mark the PR ready to review once everything is pushed"
