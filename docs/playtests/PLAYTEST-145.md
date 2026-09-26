# Playtest 145 — Measure the work in a crowded scene

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
